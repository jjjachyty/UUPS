// contract/MyTokenV1.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";


contract NBBV3Token is
     ERC20,
     Ownable
 {
    using SafeMath for uint256;
    using Address for address;
    ERC20 private _usdtToken;

    address public orePoolAddress;
    address public swapUSDTAddress;

     constructor() ERC20("NBB.ETM", "NBB") {
        _mint(msg.sender, 100000000000 * 10**decimals());
        _usdtToken = ERC20(0x55d398326f99059fF775485246999027B3197955);
        orePoolAddress = 0x780CCa97BC771483CD935A676aA3e5257BF19625;
        swapUSDTAddress = 0x99729ff9c50e41346366BF0a33371Ea123A968d5;
    }

    event Buy(address from, address to, uint256 amount);
    event Sell(address from, address to, uint256 amount);

    //hash 对对碰
    event HashGame(address, uint256, address, uint256);
    function setSwapAddress(address _swapUSDTAddress,address _orePoolAddress) public onlyOwner{
        swapUSDTAddress = _swapUSDTAddress;
        orePoolAddress = _orePoolAddress;
    }
    function hashGame(
        address token,
        uint256 gameType,
        uint256 amount
    ) public {
        address spender = _msgSender();
        if (token == address(this)) {
            super._transfer(spender, orePoolAddress, amount);
        } else {
            ERC20(token).transferFrom(spender, orePoolAddress, amount);
        }
        emit HashGame(spender, gameType, token, amount);
    }

    function swap(uint256 usdtAmount,uint256 nbbAmount) public {
        address spender = _msgSender();
        if (usdtAmount > 0){
        _usdtToken.transferFrom(spender, swapUSDTAddress, usdtAmount);
            emit  Buy(spender,swapUSDTAddress,usdtAmount);
        }else{
            super._transfer(spender,orePoolAddress,nbbAmount);
            emit Sell(spender,orePoolAddress,nbbAmount);
        }
    }
}
