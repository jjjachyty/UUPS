// // SPDX-License-Identifier: MIT
// // Compatible with OpenZeppelin Contracts ^5.0.0
// pragma solidity ^0.8.20;

// import "@openzeppelin/contracts@5.0.2/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts@5.0.2/token/ERC721/extensions/ERC721URIStorage.sol";
// import "@openzeppelin/contracts@5.0.2/access/Ownable.sol";

// contract PizzaSpace is ERC721, ERC721URIStorage, Ownable {
//     using Strings for uint256;
//     uint256 private _nextTokenId;
//     string NFTBaseURI;

//     constructor(string memory url)
//         ERC721("PizzaSpace", "PizzaSpace")
//         Ownable(msg.sender)
//     {
//              NFTBaseURI = url;
//              safeMint(msg.sender);
//     }

//     function safeMint(address to) public onlyOwner {
//         uint256 tokenId = _nextTokenId++;
//         _safeMint(to, tokenId);
//     }

//     function safeMintBatch(uint256 _count) public onlyOwner {
//         for (uint256 i=0; i<_count; i++) {
//         _safeMint(msg.sender, _nextTokenId++);
//          }
//     }
 
//     function setBaseURI(string memory uri) public onlyOwner {
//         NFTBaseURI = uri;
//     }

//     // The following functions are overrides required by Solidity.

//     function tokenURI(uint256 tokenId)
//         public
//         view
//         override(ERC721, ERC721URIStorage)
//         returns (string memory)
//     {
//         uint256 seq = tokenId % 10;
//         return string.concat(NFTBaseURI, string.concat(seq.toString(),".json"));
//      }

//     function supportsInterface(bytes4 interfaceId)
//         public
//         view
//         override(ERC721, ERC721URIStorage)
//         returns (bool)
//     {
//         return super.supportsInterface(interfaceId);
//     }
// }
