// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MockFoMox {
    address public communityRewardAddress;
    uint256 public directReferralPercent;
    uint256 public indirectReferralPercent;
    uint256 public maxReferralLevels;
    uint256 public buyReferralPercent;
    bool public checkAddressEffectValue;

    mapping(address => bool) public isExemptFromTransferRestrictions;
    
    uint256 private maxBuyAmount;
    
    function isCommunityLeader(address leader) external pure returns (bool) {
        return true;
    }
    
    function communityLeaderOf(address user) external pure returns (address) {
        return address(0);
    }
    
    function referrers(address user) external pure returns (address) {
        return address(0);
    }
    
    function setCommunityRewardAddress(address _address) external {
        communityRewardAddress = _address;
    }
    
    function setDirectReferralPercent(uint256 _percent) external {
        directReferralPercent = _percent;
    }
    
    function setIndirectReferralPercent(uint256 _percent) external {
        indirectReferralPercent = _percent;
    }
    
    function setMaxReferralLevels(uint256 _levels) external {
        maxReferralLevels = _levels;
    }
    
    function setBuyReferralPercent(uint256 _percent) external {
        buyReferralPercent = _percent;
    }
    
    function getDirectReferralPercent() external view returns (uint256) {
        return directReferralPercent;
    }
    
    function getIndirectReferralPercent() external view returns (uint256) {
        return indirectReferralPercent;
    }
    
    function getBuyReferralPercent() external view returns (uint256) {
        return buyReferralPercent;
    }
    
    function getMaxReferralLevels() external view returns (uint256) {
        return maxReferralLevels;
    }
    
    function getCommunityRewardAddress() external view returns (address) {
        return communityRewardAddress;
    }
    
    function checkAddressEffect(address addr) external view returns (bool) {
        return checkAddressEffectValue;
    }
    
    function setCheckAddressEffect(bool _value) external {
        checkAddressEffectValue = _value;
    }
    
    function setMaxBuyAmount(uint256 _amount) external {
        maxBuyAmount = _amount;
    }
    
    function calculateMaxBuyAmount() external view returns (uint256) {
        return maxBuyAmount;
    }
    
    
    function mockProcessCommunityLeaderFee(
        address fToken,
        address seller,
        uint256 leaderFee,
        uint256 totalFees,
        uint256 feeUSDTReceived
    ) external {
        // 通过接口调用FToken合约的processCommunityLeaderFee方法
        bytes memory callData = abi.encodeWithSignature(
            "processCommunityLeaderFee(address,uint256,uint256,uint256)",
            seller,
            leaderFee,
            totalFees,
            feeUSDTReceived
        );
        (bool success, ) = fToken.call(callData);
        require(success, "Call failed");
    }
    
    function mockProcessOrder(address poolAddress, address to) external {
        // 调用FoPool合约的processOrder方法
        (bool success, ) = poolAddress.call(
            abi.encodeWithSignature("processOrder(address)", to)
        );
        require(success, "Call failed");
    }
    
    function mockClearUserDeposit(address poolAddress, address user) external {
        // 调用FoPool合约的clearUserDeposit方法
        (bool success, ) = poolAddress.call(
            abi.encodeWithSignature("clearUserDeposit(address)", user)
        );
        require(success, "Call failed");
    }
    
    function mockRemoveOrder(address poolAddress) external {
        // 调用FoPool合约的removeOrder方法
        (bool success, ) = poolAddress.call(
            abi.encodeWithSignature("removeOrder()")
        );
        require(success, "Call failed");
    }

    function mockDeposit(
        address poolAddress,
        address user,
        uint256 usdtAmount,
        uint256 bnbAmount
    ) external {
        // 调用Pool合约的deposit方法
        bytes memory callData = abi.encodeWithSignature(
            "deposit(address,uint256,uint256)",
            user,
            usdtAmount,
            bnbAmount
        );
        (bool success, ) = poolAddress.call(callData);
        require(success, "Call failed");
    }
}
