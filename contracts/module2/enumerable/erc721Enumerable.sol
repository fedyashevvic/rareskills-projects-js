// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract NFTEnumerable is ERC721Enumerable {
    uint256 public constant NFT_TO_MINT = 20;

    constructor() ERC721("NFTEnumerable", "NFTE") {
        for (uint256 i = 0; i < NFT_TO_MINT; i++) {
            uint256 tokenId = totalSupply() + 1;
            _mint(msg.sender, tokenId);
        }
    }
}
