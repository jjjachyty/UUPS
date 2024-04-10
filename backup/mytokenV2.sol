// contract/MyTokenV1.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract MyTokenV2 is Initializable, ERC20Upgradeable, UUPSUpgradeable, OwnableUpgradeable {
  using SafeMathUpgradeable for uint256;
   uint256 value1;
   uint256 constant value2 = 3;

    function initialize() initializer public {
      __ERC20_init("MyTokenV2", "MTK2");
      __Ownable_init();
      __UUPSUpgradeable_init();

      _mint(msg.sender, 100 * 10 ** decimals());
      value1 = 2;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function getValue1() public view returns (uint256){
      return value1;
    }
    function getValue2() public pure returns (uint256){
      return value2;
    }
    function setValue1(uint256 v1) public{
       value1 = v1;
    }
    function transfer(address to, uint256 amount) public override returns (bool){
      _transfer(_msgSender(), to, amount.mul(50).div(100));
      return true;
    }
}