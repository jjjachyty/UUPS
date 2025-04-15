// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../IPoolBase.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MockUniswapV2Pair.sol";


contract MockUniswapV2Factory {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;
    
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS');
        
        // 创建一个新的模拟交易对
        pair = address(new MockUniswapV2Pair(token0, token1));
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // 兼容性考虑
        allPairs.push(pair);
        
         
        emit PairCreated(token0, token1, pair, allPairs.length);
        return pair;
    }
    
    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }
}

 
