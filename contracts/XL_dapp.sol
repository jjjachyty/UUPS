//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract XLTokenDAPP is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    struct RankingInfo {
        address account;
        uint256 amount;
    }

    ERC20Upgradeable token0;
    ERC20Upgradeable token1;
    mapping(address => address) public relationship;
    // mapping(address => uint256[10]) public relationinfos;
    mapping(address => uint256) public rewards; //TODO:

    RankingInfo[] public ranking;
    mapping(address => uint256) public rankingIndex;

    uint256 swapRate;
    uint256 parentRewardRate;
    uint256 totalIDOCount;
    uint256 totalIDOAmount;
    mapping(address => uint256[10]) public relationinfos;
    address receiveAddress;
    uint256 public endTime;

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        //TEST_AJS 0x4d67D4324cef36C2d6c4dc17e33b38beD1CCd7Cc FIST_PRD 0xC9882dEF23bc42D53895b8361D0b1EDC7570Bc6A
        token0 = ERC20Upgradeable(
            address(0xC9882dEF23bc42D53895b8361D0b1EDC7570Bc6A)
        );
        //TEST_ADH 0xA61cA8d36b29B8920dD9aB3E61BAFf23eB5463eE XL_PRD 0xF3953F7fd3618B0cD0046C69A8D1FC8987510749
        token1 = ERC20Upgradeable(
            address(0xF3953F7fd3618B0cD0046C69A8D1FC8987510749)
        ); //newtoken
        swapRate = 10 * 10**4; //10 =>100
        parentRewardRate = 1000; //10%
        receiveAddress = 0xD08faF8c348E14B356778A7c9117769523083DDd;
        endTime = 1654466766; //15 days later
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

    function setEndTime(uint256 t) public onlyOwner {
        endTime = t;
    }

    function setReceiveAddress(address account) public onlyOwner {
        receiveAddress = account;
    }

    function takeFist() public onlyOwner {
        token0.transfer(_msgSender(), token0.balanceOf(address(this)));
    }

    //私募兑换
    function ido(uint256 amount) public {
        address sender = _msgSender();
        uint256 swapAmount = amount.mul(swapRate).mul(10**12).div(10**4); //to xl 6=>18
        token0.transferFrom(sender, receiveAddress, amount);

        uint256 rewardAmount = swapAmount.mul(parentRewardRate).div(10**4);
        uint256 parentLength = rewardParent(sender, rewardAmount);
        uint256 newSwapAmount = swapAmount;
        if (parentLength > 0) {
            newSwapAmount = swapAmount.sub(rewardAmount);
        }

        // rewards[sender] = rewards[sender].add(newSwapAmount);

        uint256 index = rankingIndex[sender];
        RankingInfo memory item;
        if (ranking.length > 0) {
            item = ranking[index];
        }
        if (item.account == sender && item.amount > 0) {
            ranking[index].amount = item.amount.add(newSwapAmount);
        } else {
            ranking.push(RankingInfo(sender, newSwapAmount));
            rankingIndex[sender] = ranking.length - 1;
        }
        totalIDOCount++;
        totalIDOAmount = totalIDOAmount.add(amount);
    }

    function rewardParent(address account, uint256 amount)
        public
        returns (uint256)
    {
        address[] memory parents = new address[](10);
        uint256 count;
        for (uint256 index = 0; index < 10; index++) {
            address parentAddress = relationship[account];
            if (parentAddress != address(0)) {
                parents[count] = parentAddress;
                account = parentAddress;
                count++;
            }
        }
        if (count > 0) {
            uint256 eachRewardAmount = amount.div(count);
            for (uint256 index = 0; index < count; index++) {
                uint256 _index = rankingIndex[parents[index]];
                ranking[_index].amount = ranking[_index].amount.add(
                    eachRewardAmount
                );
            }
        }

        return count;
    }

    //绑定关系
    function bind(address parentAddress) public {
        address sender = _msgSender();
        require(sender != parentAddress, "can not bind youerself");
        require(relationship[address(sender)] == address(0), "You're bound");
        require(
            ranking.length > 0 && ranking[rankingIndex[sender]].amount > 0,
            "parent must be IDO"
        );
        relationship[sender] = parentAddress;
        address rangeAddress = parentAddress;
        for (uint256 index = 0; index < 10; index++) {
            if (rangeAddress == address(0)) {
                break;
            }
            relationinfos[rangeAddress][index]++;
            rangeAddress = relationship[rangeAddress];
        }
    }

    //领取奖励
    function takeReward() public {
        address sender = _msgSender();
        require(block.timestamp > endTime, "can not take reward at this time");
        RankingInfo memory item = ranking[rankingIndex[sender]];
        if (item.amount > 0) {
            token1.transfer(sender, item.amount);
            ranking[rankingIndex[sender]].amount = 0;
        }
    }

    function getReward(address account) public view returns (RankingInfo memory) {
        return ranking[rankingIndex[account]];
    }

    //获取所有私募地址和金额 map js  自行排序
    function getRanking() public view returns (RankingInfo[] memory) {
        return ranking;
    }

    //获取统计信息 ido次数 ido金额 ido地址数量
    function getStatistics()
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (totalIDOCount, totalIDOAmount, ranking.length);
    }

    //获取用户邀请数据 0-9 代表1级 2级...
    function getAccountRelStatistics(address account)
        public
        view
        returns (uint256[10] memory)
    {
        return relationinfos[account];
    }
}
