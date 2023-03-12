// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract GameContract {
    IERC721Enumerable public immutable nftContract;

    constructor(address _nftContract) {
        require(
            IERC721Enumerable(_nftContract).supportsInterface(
                type(IERC721).interfaceId
            ),
            "Invalid ERC721 token"
        );
        nftContract = IERC721Enumerable(_nftContract);
    }

    function isPrime(uint256 _number) internal pure returns (bool) {
        if (_number == 0 || _number == 1) {
            return false;
        }

        for (uint256 i = 2; i <= _number / 2; ++i) {
            if (_number % i == 0) {
                return false;
            }
        }
        return true;
    }

    function getUserPrimeNfts(
        address _user
    ) external view returns (uint256[] memory) {
        uint256 userBalance = nftContract.balanceOf(_user);
        uint256 primeNftsCount = 0;
        for (uint256 i = 0; i < userBalance; i++) {
            uint256 tokenIdByIndex = nftContract.tokenOfOwnerByIndex(_user, i);
            if (isPrime(tokenIdByIndex)) {
                primeNftsCount++;
            }
        }

        uint256 primeNftsIndex = 0;
        uint256[] memory primeNfts = new uint256[](primeNftsCount);
        for (uint256 i = 0; i < nftContract.balanceOf(_user); i++) {
            uint256 tokenIdByIndex = nftContract.tokenOfOwnerByIndex(_user, i);
            if (isPrime(tokenIdByIndex)) {
                primeNfts[primeNftsIndex] = tokenIdByIndex;
                primeNftsIndex++;
            }
        }
        return primeNfts;
    }
}
