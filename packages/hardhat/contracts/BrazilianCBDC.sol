// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/access/Ownable.sol";

contract BrazilianCBDC is ERC20, ERC20Burnable, Ownable {

    mapping(address => bool) public privilegedAccounts; //Financial institutions and banks;

    constructor() ERC20("Brazilian CBDC", "BRLt") Ownable(){
        privilegedAccounts[msg.sender] = true;
    }

    function decimals() public view virtual override returns (uint8) {
        return 2;
    }

    // Modifier to restrict access only to privileged accounts
    modifier onlyPrivileged() {
        require(privilegedAccounts[msg.sender], "Access denied: account is not privileged.");
        _;
    }

    // Function to add an address to the list of privileged accounts
    function addPrivilegedAccount(address account) public onlyOwner {
        privilegedAccounts[account] = true;
    }

    // Function to remove an address from the list of privileged accounts
    function removePrivilegedAccount(address account) public onlyOwner {
        privilegedAccounts[account] = false;
    }

    // Function to transfer tokens from any account without the need for approval
    function privilegedTransfer(address from, address to, uint256 amount) public onlyPrivileged returns(bool) {
        _transfer(from, to, amount);
        return true;
    }

    // Function to mint tokens for a user
    function mintUser(address user, uint256 amount) public onlyPrivileged returns (bool){
        _mint(user, amount);
        return true;
    }

    // Function to burn tokens from a user
    function burnUser(address user, uint256 amount) public onlyPrivileged returns (bool){
        _burn(user, amount);
        return true;
    }
}