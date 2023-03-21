import "./token.sol";

contract EchidnaTemplate is TokenSaleChallenge {
    constructor() payable {}

    function testBalanceLimit() public view {
        require(
            balanceOf[msg.sender] >=
                44541774174296702224905687452235019678655469500116331996461770142052444139
        );
        assert(!isComplete());
    }

    // function testCalculateTokenPrice(uint256 _tokenNum) public pure {
    //     uint256 tokensPrice = calculateTokenPrice(_tokenNum);
    //     assert(tokensPrice > _tokenNum);
    //     // assert(!isComplete());
    // }
}
