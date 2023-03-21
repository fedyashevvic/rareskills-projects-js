import "./dex.sol";

contract EchidnaTemplate {
    Dex dex;
    SwappableToken token1;
    SwappableToken token2;

    constructor() {
        dex = new Dex();
        token1 = new SwappableToken(address(dex), "1", "1", 110 ether);
        token2 = new SwappableToken(address(dex), "2", "2", 110 ether);

        dex.setTokens(address(token1), address(token2));

        // cover enough allowance
        dex.approve(address(dex), 10000000000 ether);

        dex.addLiquidity(address(token1), 100 ether);
        dex.addLiquidity(address(token2), 100 ether);

        require(token1.balanceOf(address(dex)) == 100 ether);
        require(token2.balanceOf(address(dex)) == 100 ether);

        require(token1.balanceOf(address(this)) == 10 ether);
        require(token2.balanceOf(address(this)) == 10 ether);

        dex.renounceOwnership();
    }

    function testSwap(bool isFrom, uint256 amount) public {
        SwappableToken from = isFrom ? token1 : token2;
        SwappableToken to = isFrom ? token2 : token1;
        amount = amount < from.balanceOf(address(this))
            ? amount
            : (amount % (from.balanceOf(address(this))));
        dex.swap(address(from), address(to), amount);
        assert(dex.balanceOf(address(token1), address(dex)) < 75 ether);
        assert(dex.balanceOf(address(token2), address(dex)) < 75 ether);
    }

    function testDexLiquidity() public view {
        assert(token1.balanceOf(address(dex)) == 100 ether);
    }
}
