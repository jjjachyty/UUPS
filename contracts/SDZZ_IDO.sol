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

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);
}

contract SDZZIDO is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    ERC20Upgradeable public _usdtToken;
    ERC20Upgradeable public _sdzzToken;
    NFT public _nft;
    mapping(address => address) public relationship;
    mapping(address => address[]) public userInvites;
    mapping(uint256 => uint256) public nftCount;
    mapping(address => uint256) public idoAmount;
    uint256 public rewardNFTAmount;
    uint256 public idoUintAmount;
    uint256 public idoUintReawrdAmount;
    uint256 public inviteFeeRate;//5%
    address public idoReceiveAddress;

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
        _sdzzToken = ERC20Upgradeable(
            0xbC10307c9472410AF315000C612952928ACDaAc0
        );
        //TEST 0xE12beab8eeFb79BDC00d490ea1E1F4F61C913C0A PRD_TEST 0xf38642409aB2C3400A4631054D1e39bc8074E0D6
        _nft = NFT(0xf38642409aB2C3400A4631054D1e39bc8074E0D6); //
        // rewardOfSecond = (120000.mul(10**18)).div(31536000);
        rewardNFTAmount = 3000 * 10**18; //3000U
        idoUintAmount= 100 * 10**18;//100U一份
        idoUintReawrdAmount = 10000 * 10 ** 18;
        inviteFeeRate = 500;
        idoReceiveAddress = owner();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function setUSDT(address account) public onlyOwner {
        _usdtToken = ERC20Upgradeable(account);
    }
    function setIDOReceiveAddress(address account) public onlyOwner {
        idoReceiveAddress = account;
    }
    
    function setIDOUintReawrdAmount(uint256 amount) public onlyOwner {
        idoUintReawrdAmount = amount;
    }

    function setIDOUintAmount(uint256 amount) public onlyOwner {
        idoUintAmount = amount;
    }

    function setRewardNFTAmount(uint256 amount) public onlyOwner {
        rewardNFTAmount = amount;
    }

    function setInviteFeeRate(uint256 rate) public onlyOwner {
        inviteFeeRate = rate;
    }

    function setSDZZ(address account) public onlyOwner {
        _sdzzToken = ERC20Upgradeable(account);
    }

    function removeRelationship(address account) public onlyOwner {
        address parent =  relationship[account];

       relationship[account]= address(0x0);
       address[] memory invites = userInvites[parent];
       for (uint256 index = 0; index < userInvites[parent].length; index++) {
          if (invites[index] == account){
            delete userInvites[parent][index];
          }
       }
    }

    function setNFT(address nftAddress) public onlyOwner {
        _nft = NFT(nftAddress);
    }

    function getUserInvites(address account) public view returns (address[]  memory data) {
        address[] memory invites = userInvites[account];
        uint256 len = invites.length;
        data = new address[](len);
        for (uint256 index = 0; index < len; index++) {
                data[index] = invites[index];
        }
        return data;
    }
    
    event IDO(address owner,uint256 amount,address parent);

    function ido(uint256 coefficient, address parent) public {
        address sender = _msgSender();
        uint256 amount = coefficient.mul(idoUintAmount); 

        require(amount > 0 && amount.mod(idoUintAmount) == 0, "invaild amount");
        
            uint256 inviteFee = amount.mul(inviteFeeRate).div(10**4);

        if (parent != address(0x0) && relationship[sender] == address(0x0)) {

            relationship[sender] = parent;
            userInvites[parent].push(sender);
            uint256 len = userInvites[parent].length;

            if (nftCount[0] < 501) {
                uint256 inviteAmount;
                for (uint256 index = 0; index < len; index++) {
                    inviteAmount += idoAmount[userInvites[parent][index]];
                }
                uint256 count = inviteAmount.div(rewardNFTAmount);
                uint256 mintCount = count.sub(_nft.balanceOf(parent, 0));
                if (mintCount > 0) {
                    _nft.mint(parent, 0, 1, "");
                    nftCount[0]++;
                }
            }
            _usdtToken.transferFrom(sender, parent, inviteFee);
        }


        _usdtToken.transferFrom(sender, idoReceiveAddress, amount.sub(inviteFee));

        _sdzzToken.transferFrom(
            owner(),
            sender,
            coefficient.mul(idoUintReawrdAmount)
        );
        idoAmount[sender] += amount;

        emit IDO(sender,amount,parent);
    }
}
