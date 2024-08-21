// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.24;

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";

contract PizzaSpaceClub is
    Initializable,
    ERC721Upgradeable,
    OwnableUpgradeable,
    ERC721BurnableUpgradeable,
    UUPSUpgradeable
{
    string NFTBaseURI;
    mapping(address => bool) senderAllowlist;
    uint256 private _nextTokenId;
    using Strings for uint256;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC721_init("Pizza Space Club", "Pizza Space Club");
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        NFTBaseURI = "https://btwgswap.github.io/nft/pizzaspaceclub/";
        _nextTokenId=665500;
        safeMint(msg.sender);
        senderAllowlist[0xdc8B1f859bD9aFd93159DEcF75eaDD5f871aE6ee]=true;
    }

    function _baseURI() internal view override returns (string memory) {
        return NFTBaseURI;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
    }

    function setNextId(uint256 _id) public onlyOwner{
        _nextTokenId = _id;
    }

    function safeMintBatch(uint256 _count) public onlyOwner {
        for (uint256 i = 0; i < _count; i++) {
            _safeMint(msg.sender, _nextTokenId++);
        }
    }

    function setBaseURI(string memory uri) public onlyOwner {
        NFTBaseURI = uri;
    }

    function setSenderAllowlist(address addr, bool flag) public onlyOwner {
        senderAllowlist[addr] = flag;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721Upgradeable) returns (string memory) {
        uint256 seq = tokenId % 5;
        return
            string.concat(NFTBaseURI, string.concat(seq.toString(), ".json"));
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        if (msg.sender == tx.origin) {
            require(senderAllowlist[msg.sender], "Sender not in Allowlist");
        }
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        // Setting an "auth" arguments enables the `_isAuthorized` check which verifies that the token exists
        // (from != 0). Therefore, it is not needed to verify that the return value is not 0 here.
        address previousOwner = _update(to, tokenId, _msgSender());
        if (previousOwner != from) {
            revert ERC721IncorrectOwner(from, tokenId, previousOwner);
        }
    }
}
