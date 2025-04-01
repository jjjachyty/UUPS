// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MockFToken {
    address public fomoxAddress;
    
    function setFomoxAddress(address _fomoxAddress) external {
        fomoxAddress = _fomoxAddress;
    }
    
    function processCommunityLeaderFee(address seller, uint256 leaderFee, uint256 totalFees, uint256 feeUSDTReceived) external {
        // 模拟处理社区长费用
    }
}
