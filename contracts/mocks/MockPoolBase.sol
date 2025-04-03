// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../IPoolBase.sol";
import "hardhat/console.sol";

contract MockPoolBase is IPoolBase {
    address public fomoxAddress;
    uint256 private totalAmount;
    uint256 private poolLength;
    uint256 private processedCount;
    mapping(address => uint256) private userAmounts;
    
    function setFomoxAddress(address _fomoxAddress) external {
        fomoxAddress = _fomoxAddress;
    }
    
    function setTotalAmount(uint256 _totalAmount) external {
        totalAmount = _totalAmount;
    }
    
    function setPoolLength(uint256 _poolLength) external {
        poolLength = _poolLength;
    }
    
    function setProcessedCount(uint256 _processedCount) external {
        processedCount = _processedCount;
    }
    
    function setUserAmount(address user, uint256 amount) external {
        userAmounts[user] = amount;
    }
    
  
    
    // IPoolBase 接口实现
    function deposit(address user, uint256 usdtAmount, uint256 bnbAmount) external override {
        userAmounts[user] += usdtAmount;
        totalAmount += usdtAmount;
    }
    
    function getUserAmount(address user) external view override returns (uint256) {
        return userAmounts[user];
    }
    
    function getTotalAmount() external view   returns (uint256) {
        return totalAmount;
    }
    
    function getPoolLength() external view override returns (uint256) {
        return poolLength;
    }
    
    function getPoolAt() external view override returns (Pool memory) {
        return Pool({
            addr: address(this),
            usdtAmount: 100 * 10**18,
            bnbAmount: 1 * 10**18
        });
    }
    
    function processOrder(address to) external override returns (bool) {
        console.log("processOrder", processedCount, poolLength);
        processedCount++;
        return true;
    }
    
    function removeOrder() external override {
        if (totalAmount >= 100 * 10**18) {
            totalAmount -= 100 * 10**18;
        }
    }
    
    function clearUserDeposit(address user) external override {
        userAmounts[user] = 0;
    }
    
    function getProcessedCount() external view override returns (uint256) {
        return processedCount;
    }
}
