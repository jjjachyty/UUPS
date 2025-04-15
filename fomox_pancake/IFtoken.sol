// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IFtoken {
    function processCommunityLeaderFee(
        address seller, 
        uint256 leaderFee, 
        uint256 totalFees, 
        uint256 feeUSDTReceived
    ) external;
}
