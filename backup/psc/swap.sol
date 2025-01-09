// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {ERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

interface MintContract {
    function addPower(address _target, uint256 _amount) external;
}

contract SwapContract is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    //挖矿合约
    MintContract _mintContract;

    address public _token;
    address public _usdt;

    address public _address5;
    address public _address10;
    address public _address35;

    address public _zero;

    uint256 public _hourFee;
    uint256 public _lastSellTime;
    //代币=xU
    uint256 public _price;
    //价格更新时间
    uint256 public _updateTimes;

    //历史价格
    HisPrice[] public _hisPrice;

    struct HisPrice {
        uint256 time;
        uint256 price;
    }

    event AddPower(address _target, uint256 _power);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        _hourFee = 100 * 10 ** 14; //1%
        //挖矿合约
        _mintContract = MintContract(
            0x9Ae3c0dFF91a4BdB046E51486c1CcD847235Df86
        );

        _token = 0x3e81AE5448ED9fd785467FDe13AC3127775E8d00;
        _usdt = 0x55d398326f99059fF775485246999027B3197955;

        _address5 = 0x7bA9d04660896C2fd21eb2DaA417E35FA6fd3058;
        _address10 = 0x48f5FC6ef301234B1d48003e87519A6F451B1caA;
        _address35 = 0x8151A4add170253DbA18F44D5149999007Ac4b73;

        _zero = 0x000000000000000000000000000000000000dEaD;

        _price = 10 ** 18;
        _updateTimes = 1 hours;
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function sell(address _target, uint256 _amount) public {
        ERC20Upgradeable token = ERC20Upgradeable(_token);
        ERC20Upgradeable usdt = ERC20Upgradeable(_usdt);
        token.transferFrom(_target, address(this), _amount);
        //最多销毁到210w枚
        if (token.balanceOf(_zero) < 207900000 * 10 ** 18) {
            token.transfer(_zero, _amount / 2);
        }
        token.transfer(_address5, _amount / 20);
        token.transfer(_address10, _amount / 10);
        token.transfer(_address35, (_amount * 35) / 100);

        uint256 uAmount = (_amount * _price) / 10 ** 18;
        require(usdt.balanceOf(address(this)) >= uAmount, "no balance");
        usdt.transfer(_target, (uAmount * 45) / 100);
        //usdt.transfer(msg.sender, uAmount * 55 / 100);
        //复投算力
        try _mintContract.addPower(_target, (uAmount * 55) / 100) {} catch {}
        emit AddPower(_target, (uAmount * 55) / 100);
        uint256 burn = (_amount * 55) / 100;
        token.transfer(_zero, burn);

        if ((block.timestamp - _lastSellTime) > _updateTimes) {
            _lastSellTime = block.timestamp;
            HisPrice memory info = HisPrice(block.timestamp, _price);
            _hisPrice.push(info);
            _price = (_price * (10 ** 18 + _hourFee)) / 10 ** 18;
        }
    }

    function setUpdateTimes(uint256 _time) external onlyOwner {
        _updateTimes = _time;
    }

    //更新时间
    function update() external {
        require(
            (block.timestamp - _lastSellTime) > _updateTimes,
            "time no come"
        );
        _lastSellTime = block.timestamp;
        HisPrice memory info = HisPrice(block.timestamp, _price);
        _hisPrice.push(info);
        _price = (_price * (10 ** 18 + _hourFee)) / 10 ** 18;
    }

    //修改挖矿合约地址
    function setMintContractAddress(address _target) external onlyOwner {
        _mintContract = MintContract(_target);
    }

    //设置每日代币价格涨幅 万分比
    function setFee(uint256 fee) external onlyOwner {
        _hourFee = fee * 10 ** 14;
    }

    //修改token地址
    function setToken(address _target) external onlyOwner {
        _token = _target;
    }

    //修改u地址
    function setUsdt(address _target) external onlyOwner {
        _usdt = _target;
    }

    //修改5费率地址
    function setAddress5(address _target) external onlyOwner {
        _address5 = _target;
    }

    //修改10费率地址
    function setAddress10(address _target) external onlyOwner {
        _address10 = _target;
    }

    //修改35费率地址
    function setAddress35(address _target) external onlyOwner {
        _address35 = _target;
    }

    //查询当前价格（精度6）
    function getPrice() external view returns (uint256) {
        return _price;
    }

    //管理员设定价格
    function setPrice(uint256 price) external onlyOwner {
        HisPrice memory info = HisPrice(block.timestamp, _price);
        _hisPrice.push(info);
        _price = price;
    }

    //代币提现
    function withdraw(
        address _tokens,
        address _target,
        uint256 _amount
    ) external onlyOwner {
        require(
            ERC20Upgradeable(_tokens).balanceOf(address(this)) >= _amount,
            "no balance"
        );
        ERC20Upgradeable(_tokens).transfer(_target, _amount);
    }

    //领取主链币余额
    function claimBalance() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    //获取历史价格
    function getHisPrice() external view returns (HisPrice[] memory) {
        return _hisPrice;
    }
}
