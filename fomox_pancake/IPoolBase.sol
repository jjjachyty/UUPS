// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IPoolBase {
    struct Pool {
        address addr; // 池子地址
        uint256 usdtAmount; // 池子USDT金额
        uint256 bnbAmount; // 池子BNB总金额
    }
    
    function deposit(address user, uint256 usdtAmount, uint256 bnbAmount) external;
    function getUserAmount(address user) external view returns (uint256);
    function getTotalAmount() external view returns (uint256);
    function getPoolLength() external view returns (uint256);
    function getProcessedCount() external view returns (uint256);
    function getPoolAt( ) external view returns (Pool memory);
    function processOrder( address to) external returns (bool);
    function removeOrder() external;
    function clearUserDeposit(address user) external;
    function getInSwap() external view returns (bool);
  }
interface IFtoken {
    function processRewards(address seller, uint256 fee,uint256 techFee) external;
    function processCommunityLeaderFee(
        address seller, 
        uint256 fee
    ) external;
}

interface IFoMox {
    function isCommunityLeader(address leader) external view returns (bool);
    function communityLeaderOf(address user) external view returns (address);
    function checkIsExemptFromTransferRestrictions(
        address addr
    ) external view returns (bool);
    function referrers(address user) external view returns (address);
    function getDirectReferralPercent() external view returns (uint256);
    function getIndirectReferralPercent() external view returns (uint256);
    function getMaxReferralLevels() external view returns (uint256);
    function getBuyReferralPercent() external view returns (uint256);
    function getCommunityRewardAddress() external view returns (address);
    function checkAddressEffect(address addr) external view returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function calculateMaxBuyAmount() external view returns (uint256);
}
 