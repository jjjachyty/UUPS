// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract YESTOKEN is ERC20 {
    using SafeMath for uint256;
    using Address for address;

    address adminAccount = 0x25B290a307D6737703427CE58A1E140A635B66F8;
    address freeAccount = 0x454f025687a1b13A6e135778f0A84F8aa0971E5b;
    uint256 feeRate = 3;
    
    constructor() ERC20("yes token", "yes") {
        _mint(adminAccount, 810000000 * 10 ** decimals());
    }
    
   function _transfer(address owner , address to, uint256 amount) override internal{
       uint256 fee = amount.mul(100).div(feeRate);
       super._transfer(owner,freeAccount,fee);
       super._transfer(owner,to,amount.sub(fee));
    }
}