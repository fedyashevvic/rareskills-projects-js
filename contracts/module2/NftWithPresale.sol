// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NftWithPresale is ERC721, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_NFT_SUPPLY = 10;
    uint256 public constant MAX_NFT_PER_MINT = 1;
    uint256 public constant PRICE = 0.01 ether;
    uint256 public constant PRESALE_PRICE = 0.005 ether;
    uint256 private _totalSupply;

    // royalty info
    address private royaltyAddress;
    uint256 private constant ROYALTY_SIZE = 750; // 7.5%
    uint256 private constant ROYALTY_DENOMINATOR = 10000;

    uint16 private constant MAX_INT = 0xffff;
    uint16[1] arr = [MAX_INT];

    string private _baseTokenURI;

    bytes32 public immutable merkleRoot;

    constructor(
        string memory baseTokenURI_,
        address _royaltyAddress,
        bytes32 _merkleRoot
    ) ERC721("NftWithPresale", "NWP") {
        require(_royaltyAddress != address(0), "Royalty address is zero");
        _baseTokenURI = baseTokenURI_;
        royaltyAddress = _royaltyAddress;
        merkleRoot = _merkleRoot;
    }

    function claimTicketOrBlockTransaction(uint16 ticketNumber) internal {
        require(ticketNumber < MAX_NFT_SUPPLY, "Ticket doesn't exist");
        uint16 storageOffset = 0;
        uint16 offsetWithin16 = ticketNumber % 16;
        uint16 storedBit = (arr[storageOffset] >> offsetWithin16) & uint16(1);
        require(storedBit == 1, "already taken");

        arr[storageOffset] =
            arr[storageOffset] &
            ~(uint16(1) << offsetWithin16);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function mint() public payable {
        require(
            totalSupply() + MAX_NFT_PER_MINT <= MAX_NFT_SUPPLY,
            "Exceeds MAX_NFT_SUPPLY"
        );

        require(PRICE == msg.value, "Ether value sent is not correct");

        _safeMint(_msgSender(), totalSupply());
        _totalSupply += MAX_NFT_PER_MINT;
    }

    function presale(
        uint16 ticketNumber,
        bytes32[] calldata merkleProof
    ) public payable {
        require(
            totalSupply() + MAX_NFT_PER_MINT <= MAX_NFT_SUPPLY,
            "Exceeds MAX_NFT_SUPPLY"
        );
        require(PRESALE_PRICE == msg.value, "Ether value sent is not correct");

        verifyMerkleProof(merkleProof, ticketNumber, _msgSender());
        claimTicketOrBlockTransaction(ticketNumber);

        _safeMint(_msgSender(), totalSupply());
        _totalSupply += MAX_NFT_PER_MINT;
    }

    function verifyMerkleProof(
        bytes32[] calldata merkleProof,
        uint16 ticketNumber,
        address caller
    ) public view {
        require(
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(caller, ticketNumber))
            ),
            "Invalid merkle proof"
        );
    }

    /**
     * @dev See {ERC-2981: NFT Royalty Standard}.
     */
    function royaltyInfo(
        uint256,
        uint256 _salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
        uint256 amount = (_salePrice * ROYALTY_SIZE) / ROYALTY_DENOMINATOR;
        return (royaltyAddress, amount);
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        return
            string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }
}
