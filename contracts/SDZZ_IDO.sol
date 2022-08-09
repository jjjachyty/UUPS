// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface NFT {
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;
}

contract SDZZIDO is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    ERC20Upgradeable private _usdtToken;
    ERC20Upgradeable private _sdzzToken;
    NFT private _nft;
    mapping(address => address) relationship;
    mapping(address => address[]) userInvites;
    mapping(uint256 => uint256) nftCount;
    mapping(address => uint256) idoAmount;
    mapping(address => mapping(uint256 => uint256)) nftTakeInfo;

    // uint256 rewardOfSecond;

    /// @custom:oz-upgrades-unsafe-allow constructor
    // constructor() {
    //     _disableInitializers();
    // }

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        // PRD 0x55d398326f99059fF775485246999027B3197955 TEST 0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684
        _usdtToken = ERC20Upgradeable(
            0x55d398326f99059fF775485246999027B3197955
        );
        _nft = NFT(owner()); //
        // rewardOfSecond = (120000.mul(10**18)).div(31536000);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function setNFT(address nftAddress) public onlyOwner {
        _nft = NFT(nftAddress);
    }

    function ido(uint256 amount, address parent) public {
        address sender = _msgSender();
        uint256 inviteFee = amount.mul(5).div(100);

        if (parent != address(0x0) && relationship[sender] == address(0x0)) {
            relationship[sender] = parent;
            userInvites[parent].push(sender);
            uint256 len = userInvites[parent].length;
            uint256 inviteAmount;
            for (uint256 index = 0; index < len; index++) {
                inviteAmount += idoAmount[userInvites[parent][index]];
            }
            //
            if (inviteAmount > 3000 * 10**18) {
                _nft.mint(sender, 0, 1, "");
                nftCount[0]++;
            }
            _usdtToken.transferFrom(sender, parent, inviteFee);
        }

        require(amount > 0 && amount.mod(100 * 10**18) == 0, "invaild amount");
        uint256 coefficient = amount.div(100 * 10**18);
       
        _usdtToken.transferFrom(sender, address(this), amount.sub(inviteFee));

        _sdzzToken.transferFrom(
            owner(),
            sender,
            coefficient.mul(10000 * 10 * 18)
        );
        idoAmount[sender] += amount;
    }
}
