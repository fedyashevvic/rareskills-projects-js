// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFT is ERC721 {
    uint256 private _totalSupply;
    uint256 public constant NFT_PER_MINT = 10;

    constructor() ERC721("NFT", "NFT") {}

    function claim() public {
        for (uint256 i = 0; i < NFT_PER_MINT; i++) {
            _mint(_msgSender(), _totalSupply + i);
        }
        _totalSupply += NFT_PER_MINT;
    }
}
