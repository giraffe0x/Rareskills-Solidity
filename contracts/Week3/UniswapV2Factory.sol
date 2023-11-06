// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IUniswapV2Pair } from  "./interfaces/IUniswapV2Pair.sol";
import { UniswapV2Pair } from "./UniswapV2Pair.sol";

contract UniswapV2Factory {
    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        UniswapV2Pair _pair = new UniswapV2Pair{salt: salt}();
        pair = address(_pair);
        IUniswapV2Pair(pair).initialize(token0, token1);

        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
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

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    // function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
    //     require(tokenA != tokenB, "IDENTICAL_ADDRESSES");
    //     (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    //     require(token0 != address(0), "ZERO_ADDRESS");
    // }
       // calculates the CREATE2 address for a pair without making any external calls

}
