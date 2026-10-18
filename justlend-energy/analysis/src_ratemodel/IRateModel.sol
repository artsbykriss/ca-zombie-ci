// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IRateModel {
    function getRentalRate(uint256 supply, uint256 borrows) external view returns (uint256);
}