// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

abstract contract ZPlan is ERC20Upgradeable {
    function getPledgeReceiptRelation(
        address addr
    ) public view virtual returns (uint256);
    function removePledgeReceiptRelation(address addr)public virtual;
}

struct redemption {
    uint256 time;
    uint256 value;
}

contract Z is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    ZPlan zPlanToken;
    mapping(address => redemption) redemptionRelation;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
        __ERC20_init("Z", "Z");
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function setZPlanToken(address addr) public onlyOwner {
        zPlanToken = ZPlan(addr);
    }

    function transfer(
        address to,
        uint256 value
    ) public virtual override returns (bool) {
        super.transfer(to, value);
        if (to == address(this)) {
            //赎回
            uint256 pledgeValue = zPlanToken.getPledgeReceiptRelation(
                msg.sender
            );

            require(pledgeValue > 0,"no pleadge");
            require(pledgeValue/5000==value,"transfer amount error");

            redemption memory item = redemptionRelation[msg.sender];
            if (item.time <= block.timestamp) {
                zPlanToken.removePledgeReceiptRelation(msg.sender);
                return true;
            }

            
            redemptionRelation[msg.sender] = redemption(
                block.timestamp * 24 * 60 * 60,
                pledgeValue
            );
        }
        return true;
    }
}
