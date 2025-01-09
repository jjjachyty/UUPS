pragma solidity ^0.8.13;
// SPDX-License-Identifier: MIT
 
import {ERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
contract NFT is  Initializable, ERC1155Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    
    string public _uri; 
 
    mapping(uint256 => uint256) public _nftPrice;
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC1155_init("https://moccasin-rival-sturgeon-357.mypinata.cloud/ipfs/QmY4rhwM5VeBiU3nApV42WPbYhmbfCquuj1U1cWcthpC1c/{id}.json");
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
    }

     function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    //管理员mint
    function mintAdmin(uint256 id, uint256 amount, address _target) public onlyOwner{
        _mint(_target, id, amount, "");
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

 

    //合成
    function conflate(uint256 id) external {
        require(id > 0 && id < 5, "id error");
        burn(msg.sender, id, 3);
        _mint(msg.sender, id + 1, 1, "");
    }
 
    function setURI(string memory URI) public onlyOwner {
        _setURI(URI);
    }

    //转账
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        virtual
        override
    {
        super.safeTransferFrom(from, to, id, amount, data);
    }

    //批量转账
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        virtual
        override
    {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }


    //销毁
    function burn(address account, uint256 id, uint256 value) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _burn(account, id, value);
    }
 
    //批量销毁
    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _burnBatch(account, ids, values);
    }

    //代币提现
    function withdraw(address _token, address _target, uint256 _amount) external onlyOwner {
        require(IERC20(_token).balanceOf(address(this)) >= _amount, "no balance");
		IERC20(_token).transfer(_target, _amount);
    }
}