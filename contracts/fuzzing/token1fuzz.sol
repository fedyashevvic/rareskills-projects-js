import "./token1.sol";

contract EchidnaTemplate is TokenWhaleChallenge {
    constructor() TokenWhaleChallenge(msg.sender) {}

    function testBalanceLimit() public view {
        assert(!isComplete());
    }
}
