// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockUniswapV2Router02 {
    address public immutable WETH;
    address public factory;
    address public immutable usdtAddress;
    uint256 private swapExactETHForTokensAmount;
    
    constructor(address _usdtAddress) {
        WETH = address(this);
        factory = address(this);
        usdtAddress = _usdtAddress;
        swapExactETHForTokensAmount = 0;
    }
    
    function setSwapExactETHForTokensAmount(uint256 amount) external {
        swapExactETHForTokensAmount = amount;
    }
    
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts) {
        amounts = new uint256[](2);
        amounts[0] = msg.value;
        amounts[1] = swapExactETHForTokensAmount;
        
        // 转USDT到接收者
        IERC20(usdtAddress).transfer(to, swapExactETHForTokensAmount);
        return amounts;
    }
    
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {
        amounts = new uint256[](2);
        amounts[0] = amountIn;
        amounts[1] = amountIn * 2; // 模拟交换倍率
        
        // 转代币到接收者
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        IERC20(path[1]).transfer(to, amounts[1]);
        
        return amounts;
    }

    function setFactory(address _factory) external {
        factory = _factory;
    }

    function setPair(address _pair) external {
        // 模拟创建交易对的返回值
        // 这在实际Router中是调用factory.createPair
    }

    function setTokenToUsdtRate(uint256 tokenAmount, uint256 usdtAmount) external {
        // 设置模拟兑换率
    }

    function setUsdtToTokenRate(uint256 usdtAmount, uint256 tokenAmount) external {
        // 设置模拟兑换率
    }

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts) {
        amounts = new uint256[](2);
        amounts[0] = amountIn;
        // 这里应该根据设置的兑换率返回，简化处理
        amounts[1] = amountIn * 10; // 假设1 Token = 10 USDT
        return amounts;
    }

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts) {
        amounts = new uint256[](2);
        amounts[1] = amountOut;
        // 这里应该根据设置的兑换率返回，简化处理
        amounts[0] = amountOut / 10; // 假设10 USDT = 1 Token
        return amounts;
    }
}
