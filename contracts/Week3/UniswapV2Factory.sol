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

    /// @dev Create a new pair for two tokens.
    /// @param tokenA The first token of the pair.
    /// @param tokenB The second token of the pair.
    /// @return pair The address of the new pair.
    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, "IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "PAIR_EXISTS"); // single check is sufficient
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        UniswapV2Pair _pair = new UniswapV2Pair{salt: salt}();
        pair = address(_pair);
        IUniswapV2Pair(pair).initialize(token0, token1);

        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    /// @dev Set the feeTo address.
    /// @param _feeTo The new feeTo address.
    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, "FORBIDDEN");
        feeTo = _feeTo;
    }

    /// @dev Set the feeToSetter address.
    /// @param _feeToSetter The new feeToSetter address.
    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, "FORBIDDEN");
        feeToSetter = _feeToSetter;
    }

    /// @dev Get the length of allPairs.
    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }
}
