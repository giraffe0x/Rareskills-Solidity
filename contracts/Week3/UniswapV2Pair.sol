// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { ERC20 } from "lib/solady/src/tokens/ERC20.sol";
import { FixedPointMathLib } from "lib/solady/src/utils/FixedPointMathLib.sol";
import { UniswapV2Library } from "./libraries/UniswapV2Library.sol";
import { SafeTransferLib } from "lib/solady/src/utils/SafeTransferLib.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { IWETH } from "./interfaces/IWETH.sol";
import { IERC20 } from "./interfaces/IERC20.sol";
import { IUniswapV2Factory } from "./interfaces/IUniswapV2Factory.sol";
import { IERC3156FlashBorrower } from "./interfaces/IERC3156FlashBorrower.sol";
import { IERC3156FlashLender } from "./interfaces/IERC3156FlashLender.sol";
// import { console } from "forge-std/console.sol";

contract UniswapV2Pair is ERC20, ReentrancyGuard, IERC3156FlashLender {
    using SafeTransferLib for IERC20;

    uint public constant MINIMUM_LIQUIDITY = 10**3;
    uint private constant SAFE_MULTIPLIER = 1e18;
    uint private constant SWAP_FEE = 30;
    uint private constant PROTOCOL_FEE = 5;
    uint private constant BASE = 10000;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));
    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    address public immutable factory;
    address public token0;
    address public token1;

    // TODO replace with custom data types
    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    string public constant NAME = "Uniswap V2";
    string public constant SYMBOL = "UNI-V2";

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, "EXPIRED");
        _;
    }

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Flashloan(address indexed receiver, address indexed token, uint256 amount, uint256 fee, bytes data);
    event Sync(uint112 reserve0, uint112 reserve1);

    constructor() {
        factory = msg.sender;
    }

    /// @dev called once by the factory at time of deployment
    /// @param _token0 Address of token 0
    /// @param _token1 Address of token 1
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, "FORBIDDEN"); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    /// @dev Add liquidity function
    /// @param tokenA Address of token A
    /// @param tokenB Address of token B
    /// @param amountADesired Amount of token A desired to add
    /// @param amountBDesired Amount of token B desired to add
    /// @param amountAMin Minimum amount of token A to add
    /// @param amountBMin Minimum amount of token B to add
    /// @param to Address to send liquidity tokens to
    /// @param deadline Deadline for transaction
    /// @return amountA Amount of token A added
    /// @return amountB Amount of token B added
    /// @return liquidity Amount of liquidity tokens minted
    function mint(
      address tokenA,
      address tokenB,
      uint amountADesired,
      uint amountBDesired,
      uint amountAMin,
      uint amountBMin,
      address to,
      uint deadline
    ) external ensure(deadline) nonReentrant returns (uint amountA, uint amountB, uint liquidity) {
        // Get correct amount of A/B to transfer in
        (amountA, amountB) = _addLiquidity(
          tokenA,
          tokenB,
          amountADesired,
          amountBDesired,
          amountAMin,
          amountBMin
        );
        // Transfer in tokenA/B
        SafeTransferLib.safeTransferFrom(tokenA, msg.sender, address(this), amountA);
        SafeTransferLib.safeTransferFrom(tokenB, msg.sender, address(this), amountB);

        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0 - (_reserve0);
        uint amount1 = balance1 - (_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply(); // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = FixedPointMathLib.sqrt(amount0 * (amount1)) - (MINIMUM_LIQUIDITY);
           _mint(address(0), MINIMUM_LIQUIDITY); // permanently non the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = FixedPointMathLib.min(
              amount0
              * (_totalSupply)
              / _reserve0, amount1
              * (_totalSupply)
              / _reserve1);
        }
        require(liquidity > 0, "INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0) * (reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    /// @dev Remove liquidity function
    /// @param liquidity Amount of liquidity tokens to remove
    /// @param amountAMin Minimum amount of token A to remove
    /// @param amountBMin Minimum amount of token B to remove
    /// @param to Address to send tokens to
    /// @param deadline Deadline for transaction
    /// @return amount0 Amount of token A removed
    /// @return amount1 Amount of token B removed
    function burn(
      uint liquidity,
      uint amountAMin,
      uint amountBMin,
      address to,
      uint deadline
    ) public nonReentrant ensure(deadline) returns (uint amount0, uint amount1) {
        // handle protocol fees
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        address _token0 = token0;
        address _token1 = token1;

        bool feeOn = _mintFee(_reserve0, _reserve1);
        {
        uint _totalSupply = totalSupply();

        amount0 = liquidity
          * (IERC20(_token0).balanceOf(address(this)))
          / _totalSupply; // using balances ensures pro-rata distribution

        amount1 = liquidity
          * (IERC20(_token1).balanceOf(address(this)))
          / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, "INSUFFICIENT_LIQUIDITY_BURNED");

        // burn pair tokens from msg.sender
        _burn(msg.sender, liquidity);

        // check for slippage
        require(amount0 >= amountAMin, "INSUFFICIENT_A_AMOUNT");
        require(amount1 >= amountBMin, "INSUFFICIENT_B_AMOUNT");
        }
        // transfer out underlying tokens
        SafeTransferLib.safeTransfer(_token0, to, amount0);
        SafeTransferLib.safeTransfer(_token1, to, amount1);

        _update(
          IERC20(_token0).balanceOf(address(this)),
          IERC20(_token1).balanceOf(address(this)),
          _reserve0,
          _reserve1
        );

        if (feeOn) kLast = uint(reserve0) * (reserve1); // reserve0 and reserve1 are up-to-date

        emit Burn(msg.sender, amount0, amount1, to);
    }

    /// @dev Swap exact tokens for tokens
    /// @param amountIn Amount of token to swap in
    /// @param amountOutMin Minimum amount of token to swap out
    /// @param path Path of tokens to swap
    /// @param to Address to send tokens to
    /// @param deadline Deadline for transaction
    /// @return amountOut Amount of token swapped out
    function swapExactTokensForTokens(
      uint amountIn,
      uint amountOutMin,
      address[] calldata path,
      address to,
      uint deadline
    ) external ensure(deadline) returns (uint amountOut) {
      (address _token0,) = UniswapV2Library.sortTokens(path[0], path[1]);
      (uint reserveIn, uint reserveOut) = path[0] == _token0 ? (reserve0, reserve1) : (reserve1, reserve0);

      // get amount out
      amountOut = UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
      require(amountOut >= amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");

      // transfer in token to swap
      SafeTransferLib.safeTransferFrom(path[0], msg.sender, address(this), amountIn);

      (uint amount0Out, uint amount1Out) = path[0] == _token0 ? (uint(0), amountOut) : (amountOut, uint(0));
      swap(amount0Out, amount1Out, to);
    }

    /// @dev Swap tokens for exact tokens
    /// @param amountOut Amount of token to swap out
    /// @param amountInMax Maximum amount of token to swap in
    /// @param path Path of tokens to swap
    /// @param to Address to send tokens to
    /// @param deadline Deadline for transaction
    /// @return amountIn Amount of token swapped in
    function swapTokensForExactTokens(
      uint amountOut,
      uint amountInMax,
      address[] calldata path,
      address to,
      uint deadline
    ) external ensure(deadline) returns (uint amountIn) {
      (address _token0,) = UniswapV2Library.sortTokens(path[0], path[1]);
      (uint reserveIn, uint reserveOut) = path[0] == _token0 ? (reserve0, reserve1) : (reserve1, reserve0);

      amountIn = UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
      require(amountIn <= amountInMax, "EXCESSIVE_INPUT_AMOUNT");

      // transfer in token to swap
      SafeTransferLib.safeTransferFrom(path[0], msg.sender, address(this), amountIn);

      (uint amount0Out, uint amount1Out) = path[0] == _token0 ? (uint(0), amountOut) : (amountOut, uint(0));
      swap(amount0Out, amount1Out, to);
    }

    /// @dev Swap exact tokens for tokens, should not be called directly
    /// @param amount0Out Amount of token 0 to receive
    /// @param amount1Out Amount of token 1 to receive
    /// @param to Address to send tokens to
    function swap(
      uint amount0Out,
      uint amount1Out,
      address to
    ) public nonReentrant {
        require(amount0Out > 0 || amount1Out > 0, "INSUFFICIENT_OUTPUT_AMOUNT");
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, "INSUFFICIENT_LIQUIDITY");

        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
        address _token0 = token0;
        address _token1 = token1;
        require(to != _token0 && to != _token1, "INVALID_TO");
        if (amount0Out > 0) SafeTransferLib.safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
        if (amount1Out > 0) SafeTransferLib.safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens

        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, "INSUFFICIENT_INPUT_AMOUNT");
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        uint balance0Adjusted = balance0 * (BASE) - (amount0In * (SWAP_FEE));
        uint balance1Adjusted = balance1 * (BASE) - (amount1In * (SWAP_FEE));
        require(balance0Adjusted * (balance1Adjusted) >= uint(_reserve0) * (_reserve1) * (BASE**2), "K");
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    /// @dev Flash loan function, ERC3156 compliant
    /// @param receiver Address of receiver
    /// @param token Address of token to flash loan
    /// @param amount Amount of token to flash loan
    /// @param data Data to send to receiver
    /// @return bool True if successful
    function flashLoan(
      IERC3156FlashBorrower receiver,
      address token,
      uint256 amount,
      bytes calldata data
    ) external returns (bool) {
        // require token to match token0 or 1
        require(token == token0 || token == token1, "INVALID_TOKEN");

        // calculate fee
        uint256 fee = _flashFee(amount);

        // send tokens optimistically
        SafeTransferLib.safeTransfer(token, address(receiver), amount);

        // call receiver
        require(
          receiver.onFlashLoan(msg.sender, token, amount, fee, data) == CALLBACK_SUCCESS,
          "CALLBACK_FAILED"
        );

        // retrieve borrowed amount + fee from receiver
        SafeTransferLib.safeTransferFrom(token, address(receiver), address(this), amount + fee);

        emit Flashloan(address(receiver), token, amount, fee, data);

        return true;
    }

    /// @dev force balances to match reserves
    /// @param to Address to send tokens to
    function skim(address to) external nonReentrant {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        SafeTransferLib.safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)) - (reserve0));
        SafeTransferLib.safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)) - (reserve1));
    }

    /// @dev force reserves to match balances
    function sync() external nonReentrant {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }

    /* ================== VIEWS =================== */
    function name() public pure override returns (string memory) {
        return NAME;
    }

    function symbol() public pure override returns (string memory) {
        return SYMBOL;
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function flashFee(address token, uint256 amount) external view returns (uint256) {
        require(token == token0 || token == token1, "INVALID_TOKEN");
        return _flashFee(amount);
    }

    function maxFlashLoan(address token) external view returns (uint256) {
        return token == token0 ? reserve0 - MINIMUM_LIQUIDITY : reserve1 - MINIMUM_LIQUIDITY;
    }

    /* ================== PRIVATE FUNCTIONS =================== */

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) private returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
            IUniswapV2Factory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "INSUFFICIENT_B_AMOUNT");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, "INSUFFICIENT_A_AMOUNT");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0 , uint112 _reserve1) private {
        uint32 blockTimestamp = uint32(block.timestamp);
        unchecked {
          uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

          if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += (uint256(_reserve1) * SAFE_MULTIPLIER / _reserve0) * timeElapsed;
            price1CumulativeLast += (uint256(_reserve0) * SAFE_MULTIPLIER / _reserve1) * timeElapsed;
          }
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IUniswapV2Factory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = FixedPointMathLib.sqrt(uint(_reserve0) * (_reserve1));
                uint rootKLast = FixedPointMathLib.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply() * (rootK - (rootKLast));
                    uint denominator = rootK * (PROTOCOL_FEE) + (rootKLast);
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    function _flashFee(uint256 amount) private pure returns (uint256) {
        return amount * SWAP_FEE / BASE;
    }
}
