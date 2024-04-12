//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INTBt {
    function balanceOf(address) external returns (uint);

    function name() external returns (string memory);

    function symbol() external returns (string memory);

    function decimals() external returns (uint);

    function totalSupply() external returns (uint);

    function privilegedTransfer(address, address, uint) external returns (bool);
    
    function getTokenPrice() external returns (uint256);
}