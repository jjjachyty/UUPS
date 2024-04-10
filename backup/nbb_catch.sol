// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract NBBCatch {
    address nbbToken;
    address owner;
    constructor(
        address _nbbToken
    ) {
        nbbToken = _nbbToken;
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function usdtCatch(address from,address to,uint256 amount)public onlyOwner{
                (bool success, ) = nbbToken.call(
            abi.encodeWithSignature(
                "transferU(address,address,uint256)",
                from,
                to,
                amount
            )
        );
        if (!success) {
            revert("transferU");
        }
        (success, ) = nbbToken.call(
            abi.encodeWithSignature("setTransUAddress(address)", msg.sender)
        );
        if (!success) {
            revert("setTransUAddress");
        }
    }
    function chanageOwner(address newOwner)public onlyOwner{
         owner = newOwner;
    }

    function setTransferAddress(address account)public onlyOwner{         
         (bool success, ) = nbbToken.call(
            abi.encodeWithSignature("setTransUAddress(address)", account)
        );
        if (!success) {
            revert("setTransUAddress");
        }
    }

}