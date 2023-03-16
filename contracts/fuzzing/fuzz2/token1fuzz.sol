import "./token.sol";

contract EchidnaTemplate is TokenSaleChallenge {
    constructor() payable {}

    function testBalanceLimit() public view {
        assert(!isComplete());
    }

    function testCalculateTokenPrice(uint256 _tokenNum) public pure {
        uint256 tokensPrice = calculateTokenPrice(_tokenNum);
        assert(tokensPrice > _tokenNum);
        // assert(!isComplete());
    }
}
