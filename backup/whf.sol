// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WHF is ERC20, Ownable {
    constructor()
        ERC20("world heartfuture", "WHF")
        Ownable(msg.sender)
    {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }

    function decimals() override public view virtual returns (uint8) {
        return 8;
    }
}