//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract NewTokenDAPP is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    struct RankingInfo {
        address account;
        uint256 amount;
    }

    ERC20Upgradeable token0;
    ERC20Upgradeable token1;
    mapping(address => address) public relationship;
    mapping(address => uint256) public rewards;

    RankingInfo[] public ranking;
    mapping(address => uint256) public rankingIndex;

    uint256 swapRate;
    uint256 parentRewardRate;

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        //TEST_AJS 0x4d67D4324cef36C2d6c4dc17e33b38beD1CCd7Cc FIST_PRD
        token0 = ERC20Upgradeable(
            address(0x4d67D4324cef36C2d6c4dc17e33b38beD1CCd7Cc)
        );
        //TEST_ADH 0xA61cA8d36b29B8920dD9aB3E61BAFf23eB5463eE
        token1 = ERC20Upgradeable(
            address(0xA61cA8d36b29B8920dD9aB3E61BAFf23eB5463eE)
        ); //newtoken
        swapRate = 10 * 10**4; //10 =>100
        parentRewardRate = 10 * 10**4; //10%
    }

    receive() external payable {}

    function setRate(uint256 _swapRate, uint256 _parentRewardRate)
        public
        onlyOwner
    {
        swapRate = _swapRate;
        parentRewardRate = _parentRewardRate;
    }

    function setTokens(ERC20Upgradeable _token0, ERC20Upgradeable _token1)
        public
        onlyOwner
    {
        token0 = _token0;
        token1 = _token1;
    }
    //私募兑换
    function ido(uint256 amount) public {
        address sender = _msgSender();
        uint256 swapAmount = amount.mul(swapRate).div(10**4);
        token0.transferFrom(sender, address(this), amount);

        uint256 rewadAmount = swapAmount.mul(parentRewardRate).div(10**4);
        uint256 parentLength = rewardParent(sender, rewadAmount);
        if (parentLength > 0) {
            token1.transfer(sender, swapAmount.sub(rewadAmount));
        } else {
            token1.transfer(sender, swapAmount);
        }
        uint256 index = rankingIndex[sender];
        RankingInfo memory item = ranking[index];
        if (item.amount > 0) {
            ranking[index].amount = item.amount.add(swapAmount);
        } else {
            ranking.push(RankingInfo(sender, swapAmount));
            rankingIndex[sender] = ranking.length - 1;
        }
    }

    function rewardParent(address account, uint256 amount)
        private
        returns (uint256)
    {
        address[] memory parents = new address[](10);
        uint256 count;
        for (uint256 index = 0; index < 10; index++) {
            address parentAddress = relationship[account];
            parents[index] = parentAddress;
            account = parentAddress;
            count++;
        }
        uint256 eachRewardAmount = amount.div(count);
        for (uint256 index = 0; index < count; index++) {
            rewards[parents[index]] = rewards[parents[index]].add(
                eachRewardAmount
            );
        }
        return count;
    }
    //绑定关系
    function bind(address parentAddress) public {
        address sender = _msgSender();
        require(ranking[rankingIndex[sender]].amount > 0, "parent must be IDO");
        require(relationship[address(sender)] == address(0), "You're bound");
        relationship[sender] = parentAddress;
    }
    //领取奖励
    function takeReward() public {
        address sender = _msgSender();
        require(rewards[sender] > 0, "no rewards");
        token1.transfer(sender, rewards[sender]);
        delete rewards[sender];
    }
}
