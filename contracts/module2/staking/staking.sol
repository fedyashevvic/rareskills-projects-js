// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IToken is IERC20 {
    function mint(address, uint256) external;
}

pragma solidity ^0.8.7;

contract Staking is Ownable, IERC721Receiver {
    uint256 public constant SECONDS_IN_DAY = 24 * 60 * 60;
    uint256 public constant DIVIDER = 1000;
    uint256 public constant baseYield = 10 ether;

    address public immutable nftAddress;
    address public immutable tokenAddress;

    bool public paused;

    struct Staker {
        uint128 tokensStaked;
        uint128 lastCheckpoint;
    }

    mapping(address => Staker) public _stakers;
    mapping(uint256 => address) private _ownerOfToken;

    event Deposit(address indexed staker, uint256[] tokenIds);
    event Withdraw(address indexed staker, uint256[] tokenIds);
    event Claim(address indexed staker, uint256 tokensAmount);

    constructor(address _nftAddress, address _tokenAddress) {
        require(_nftAddress != address(0), "NFT address is zero");
        require(_tokenAddress != address(0), "Token address is zero");
        nftAddress = _nftAddress;
        tokenAddress = _tokenAddress;
    }

    function deposit(uint256[] memory tokenIds) public {
        Staker storage user = _stakers[_msgSender()];

        _claim(_msgSender());

        for (uint256 i; i < tokenIds.length; i++) {
            IERC721(nftAddress).safeTransferFrom(
                _msgSender(),
                address(this),
                tokenIds[i]
            );

            _ownerOfToken[tokenIds[i]] = _msgSender();
        }

        user.tokensStaked = user.tokensStaked + uint128(tokenIds.length);

        emit Deposit(_msgSender(), tokenIds);
    }

    function withdraw(uint256[] memory tokenIds) public {
        Staker storage user = _stakers[_msgSender()];
        for (uint256 i; i < tokenIds.length; i++) {
            require(
                _ownerOfToken[tokenIds[i]] == _msgSender(),
                "Not the owner OR Token not staked"
            );
            _ownerOfToken[tokenIds[i]] = address(0);
            IERC721(nftAddress).transferFrom(
                address(this),
                _msgSender(),
                tokenIds[i]
            );
        }

        user.tokensStaked = user.tokensStaked - uint128(tokenIds.length);
        emit Withdraw(_msgSender(), tokenIds);
    }

    function claim() external {
        _claim(_msgSender());
    }

    function _claim(address staker) internal {
        Staker storage user = _stakers[staker];
        uint256 accumulatedAmount = ((((block.timestamp - user.lastCheckpoint) *
            baseYield) * user.tokensStaked) / SECONDS_IN_DAY);
        user.lastCheckpoint = uint128(block.timestamp);
        IToken(tokenAddress).mint(staker, accumulatedAmount);
        emit Claim(staker, accumulatedAmount);
    }

    function getAccumulatedAmount(
        address staker
    ) external view returns (uint256) {
        Staker memory user = _stakers[staker];
        return ((((block.timestamp - user.lastCheckpoint) * baseYield) *
            user.tokensStaked) / SECONDS_IN_DAY);
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return _ownerOfToken[tokenId];
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }
}
