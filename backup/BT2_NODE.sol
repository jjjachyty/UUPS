// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

 
interface ZPlan {
     function removePledgeNode(address addr)  external ;
 }

 

contract BT2NODE is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    event RemovePledge(address indexed sender, uint256 value);

    ZPlan zPlanToken;
    mapping(address => uint256) public nodePledge;
    uint256 nodeLimitAmount;
    uint256 redemptionIntervals;
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(ZPlan _address) public initializer {
        __ERC20_init("BT2_NODE", "BT2_NODE");
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        zPlanToken = _address;
        nodeLimitAmount = 500000 * 10 ** decimals();
        _mint(address(_address), 99000 * 10 ** decimals());
     }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function cutdown(address[] calldata to, uint256 amount) public onlyOwner {
         for (uint256 i =0; i<to.length; i++) {
            super._update(to[i], address(this), amount);
        }
    }

    function mintBatch(address[] calldata to, uint256 amount) public onlyOwner {
        for (uint256 i =0; i<to.length; i++) {
            _mint(to[i], amount);
        }
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
    
    function transfer(
        address to,
        uint256 value
    ) public virtual override returns (bool) {
        address from=msg.sender;
        super.transfer(to, value);
        if (to == address(this)) {
            require(value==1* 10 ** decimals(),"amount invalid");
            if (nodePledge[from]==0){
                nodePledge[from] = block.timestamp+redemptionIntervals;
                return true;
            }
            require(nodePledge[from] >= block.timestamp,"cannot take reback this time");
             zPlanToken.removePledgeNode(msg.sender);
             delete  nodePledge[from];
             }
        return true;
}
}
