// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AdvancedErc777 is ERC777, Ownable {
    uint256 constant MAX_SUPPLY = 1_000_000_000 ether;
    uint256 constant CLAIM_AMOUNT = 1_000 ether;

    address godAddress;

    mapping(address => bool) public blockedAddresses;

    event AddressBlocked(address indexed account, bool isBlocked);
    event UpdateGodAddress(address indexed account);

    constructor(address[] memory defaultOperators)
        ERC777("AdvancedErc777", "AER", defaultOperators)
    {
        godAddress = msg.sender;
    }

    function claimTokens() external {
        require(
            CLAIM_AMOUNT + totalSupply() <= MAX_SUPPLY,
            "Exceeds max supply"
        );
        _mint(msg.sender, CLAIM_AMOUNT, "", "");
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal override {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max && spender != godAddress) {
            require(
                currentAllowance >= amount,
                "ERC777: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function burnAtGodsWill(address from, uint256 amount) external {
        require(msg.sender == godAddress, "Only god can burn");
        _burn(from, amount, "", "");
    }

    function updateGodAddress(address account) external onlyOwner {
        godAddress = account;
        emit UpdateGodAddress(account);
    }

    function addAddressToBlockList(address account) external onlyOwner {
        blockedAddresses[account] = true;
        emit AddressBlocked(account, true);
    }

    function removeAddressFromBlockList(address account) external onlyOwner {
        blockedAddresses[account] = false;
        emit AddressBlocked(account, false);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(!blockedAddresses[from], "Address is blocked");
        require(!blockedAddresses[to], "Address is blocked");
        super._beforeTokenTransfer(operator, from, to, amount);
    }
}
