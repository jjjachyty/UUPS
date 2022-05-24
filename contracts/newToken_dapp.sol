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

    ERC20Upgradeable token0;
    ERC20Upgradeable token1;
    mapping(address => address) relationship;

    uint256 swapDottyFist;
    event Swap(address fromToken,address toToken,uint256 amount);

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        token0 = ERC20Upgradeable(
            address(0x6FeB928fe58daa9541Bb1c158dCc55Bc916B4898)
        ); //fist
        token1 = ERC20Upgradeable(
            address(0x13C51701F770E2ABAd626594365976259d312aF6)
        ); //newtoken

        refTokens[address(token0)][address(token1)] = 10000;

    }

    receive() external payable {}
    function bind(address )
}
