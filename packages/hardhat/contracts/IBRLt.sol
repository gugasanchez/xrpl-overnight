//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBRLt {
    function balanceOf(address) external returns (uint);

    function name() external returns (string memory);

    function symbol() external returns (string memory);

    function decimals() external returns (uint);

    function totalSupply() external returns (uint);

    function transfer(address to, uint256 value) external returns (bool);

    function privilegedTransfer(address, address, uint) external returns (bool);
}