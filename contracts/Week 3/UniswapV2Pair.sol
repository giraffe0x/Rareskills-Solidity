// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { ERC20 } from "lib/solady/src/tokens/ERC20.sol";
import { FixedPointMathLib } from "lib/solady/src/utils/FixedPointMathLib.sol";
import { UniswapV2Library } from "./libraries/UniswapV2Library.sol";
import { SafeTransferLib } from "lib/solady/src/utils/SafeTransferLib.sol";

import { IWETH } from "./interfaces/IWETH.sol";
import { IERC20 } from "./interfaces/IERC20.sol";
import { IUniswapV2Factory } from "./interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Callee } from  "./interfaces/IUniswapV2Callee.sol";
import { IUniswapV2Pair } from "./interfaces/IUniswapV2Pair.sol";

// import { console } from "forge-std/console.sol";

contract UniswapV2Pair is ERC20 {
    // using UQ112x112 for uint224;
    using SafeTransferLib for IERC20;

    uint public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));

    address public immutable factory;
    address public immutable WETH;
    address public token0;
    address public token1;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    string internal _name = "Pair";
    string internal _symbol = "Pair";

    uint private unlocked = 2;
    modifier lock() {
        require(unlocked == 2, "LOCKED");
        unlocked = 1;
        _;
        unlocked = 2;
    }

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, "EXPIRED");
        _;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
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
    event Sync(uint112 reserve0, uint112 reserve1);

    constructor(address _weth) {
        factory = msg.sender;
        WETH = _weth;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, "FORBIDDEN"); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0 , uint112 _reserve1) private {
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        unchecked {
          uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

          if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
              // * never overflows, and + overflow is desired
              price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
              price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
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
                    uint denominator = rootK * (5) + (rootKLast);
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    function mint(
      address tokenA,
      address tokenB,
      uint amountADesired,
      uint amountBDesired,
      uint amountAMin,
      uint amountBMin,
      address to,
      uint deadline) external ensure(deadline) lock returns (uint amountA, uint amountB, uint liquidity) {
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
           _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
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

    function burn(
      uint liquidity,
      uint amountAMin,
      uint amountBMin,
      address to,
      uint deadline
    ) public lock ensure(deadline) returns (uint amount0, uint amount1) {
        require(balanceOf(msg.sender) >= liquidity, "INSUFFICIENT_LIQUIDITY");

        // handle protocol fees
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        address _token0 = token0;
        address _token1 = token1;
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply();
        amount0 = liquidity * (balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity * (balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, "INSUFFICIENT_LIQUIDITY_BURNED");

        // burn pair tokens from msg.sender
        _burn(msg.sender, liquidity);

        // check for slippage
        require(amount0 >= amountAMin, "INSUFFICIENT_A_AMOUNT");
        require(amount1 >= amountBMin, "INSUFFICIENT_B_AMOUNT");

        // transfer out underlying tokens
        SafeTransferLib.safeTransfer(_token0, to, amount0);
        SafeTransferLib.safeTransfer(_token1, to, amount1);

        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0) * (reserve1); // reserve0 and reserve1 are up-to-date

        emit Burn(msg.sender, amount0, amount1, to);
    }

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
      swap(amount0Out, amount1Out, to, new bytes(0));
    }

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
      swap(amount0Out, amount1Out, to, new bytes(0));
    }

    function swap(
      uint amount0Out,
      uint amount1Out,
      address to,
      bytes memory data
    ) public lock {
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
        if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, "INSUFFICIENT_INPUT_AMOUNT");
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        uint balance0Adjusted = balance0 * (1000) - (amount0In * (3));
        uint balance1Adjusted = balance1 * (1000) - (amount1In * (3));
        require(balance0Adjusted * (balance1Adjusted) >= uint(_reserve0) * (_reserve1) * (1000**2), "K");
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        SafeTransferLib.safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)) - (reserve0));
        SafeTransferLib.safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)) - (reserve1));
    }

    // force reserves to match balances
    function sync() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
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
}
