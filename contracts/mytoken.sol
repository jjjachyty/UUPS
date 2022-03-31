// contract/MyTokenV1.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";


contract MyTokenV1 is Initializable, ERC20Upgradeable, UUPSUpgradeable, OwnableUpgradeable {
  using SafeMathUpgradeable for uint256;

   uint256 value1;
   uint256 constant value2 = 2;

    function initialize() initializer public {
      __ERC20_init("MyToken", "MTK");
      __Ownable_init();
      __UUPSUpgradeable_init();

      _mint(msg.sender, 1000 * 10 ** decimals());
      value1 = 1;
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
      _transfer(_msgSender(), to, amount.mul(10).div(100));
      return true;
    }

}