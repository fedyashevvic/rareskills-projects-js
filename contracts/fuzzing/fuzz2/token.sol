// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

contract TokenSaleChallenge {
    mapping(address => uint256) public balanceOf;
    uint256 constant PRICE_PER_TOKEN = 1 ether;

    constructor() payable {
        require(msg.value == 1 ether);
    }

    function isComplete() public view returns (bool) {
        return address(this).balance < 1 ether;
    }

    function calculateTokenPrice(
        uint256 numTokens
    ) public pure returns (uint256) {
        return numTokens * PRICE_PER_TOKEN;
    }

    function buy(uint256 numTokens) public payable {
        require(msg.value == calculateTokenPrice(numTokens));

        balanceOf[msg.sender] += numTokens;
    }

    function sell(uint256 numTokens) public {
        require(balanceOf[msg.sender] >= numTokens);

        balanceOf[msg.sender] -= numTokens;
        msg.sender.transfer(numTokens * PRICE_PER_TOKEN);
    }
}
