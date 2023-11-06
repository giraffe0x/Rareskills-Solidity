// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IUniswapV2Pair } from  "./interfaces/IUniswapV2Pair.sol";
import { UniswapV2Pair} from "./UniswapV2Pair.sol";

contract UniswapV2Factory {
    address public feeTo;
    address public feeToSetter;

    bytes private constant PAIR_BYTECODE = type(UniswapV2Pair).creationCode;

    mapping(address => bool) public pairExists;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = pairFor(token0, token1);
        require(!pairExists[pair], "UniswapV2: PAIR_EXISTS");

        IUniswapV2Pair(pair).initialize(token0, token1);
        pairExists[pair] = true;
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, "UniswapV2: FORBIDDEN");
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, "UniswapV2: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }

    function pairFor(
      address tokenA,
      address tokenB
    ) public view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
                hex"ff",
                address(this),
                keccak256(abi.encodePacked(token0, token1)), // salt
                PAIR_BYTECODE
            )))));
    }

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "ZERO_ADDRESS");
    }
}
