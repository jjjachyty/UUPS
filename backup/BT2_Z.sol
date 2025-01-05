// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

 
interface ZPlan {
    function getPledgeReceiptRelation(address addr)  external returns (uint256);
    function removePledgeReceiptRelation(address addr)  external ;
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
    event ApplyRemovePledge(address indexed sender, uint256 value);

    ZPlan zPlanToken;
    uint256 redemptionIntervals;
    mapping(address => redemption) public redemptionRelation;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(ZPlan _address) public initializer {
        __ERC20_init("Z", "Z");
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        zPlanToken = _address;
        _mint(address(_address), 990000 * 10 ** decimals());
        redemptionIntervals =12*60*60;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function setZPlanToken(address addr) public onlyOwner {
        zPlanToken = ZPlan(addr);
    }
    
    function setRedemptionIntervals(uint256 _unxitime) public onlyOwner {
        redemptionIntervals = _unxitime;
    }
    

    function getRedemptionRelation(address _addr) public view returns (redemption memory){
        return redemptionRelation[_addr];
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
            require(pledgeValue/10000==value,"transfer amount error");

            redemption memory item = redemptionRelation[msg.sender];
            if (item.time > 0 ){
                if (item.time <= block.timestamp) {
                    zPlanToken.removePledgeReceiptRelation(msg.sender);
                    delete redemptionRelation[msg.sender];
                    return true;
                }
                    revert("cannot redemption on this time");
            }

            
            redemptionRelation[msg.sender] = redemption(
                block.timestamp + redemptionIntervals,
                pledgeValue
            );

            emit ApplyRemovePledge(msg.sender, pledgeValue);
        }
        return true;
    }
}
