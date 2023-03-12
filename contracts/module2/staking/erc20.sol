// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20, Ownable {
    address private stakingContract;

    constructor() ERC20("Token", "FT") {}

    modifier onlyStakingContract() {
        require(
            _msgSender() == stakingContract,
            "Only staking contract can call this function"
        );
        _;
    }

    function mint(address _to, uint256 _amount) external onlyStakingContract {
        _mint(_to, _amount);
    }

    function setStakingAddress(address _stakingContract) external onlyOwner {
        stakingContract = _stakingContract;
    }
}
