// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MockUniswapV2Pair {
    address public token0;
    address public token1;
    uint256 private reserve0;
    uint256 private reserve1;
    uint32 private blockTimestampLast;
    
    constructor(address _token0,address _token) {
        token0 = _token0;
        token1 = _token;
        reserve0 = 0;
        reserve1 = 0;
        blockTimestampLast = uint32(block.timestamp);
    }
    
    function setReserves(uint256 _reserve0, uint256 _reserve1) external {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
        blockTimestampLast = uint32(block.timestamp);
    }
    
    function getReserves() external view returns (uint112, uint112, uint32) {
        return (uint112(reserve0), uint112(reserve1), blockTimestampLast);
    }
}
