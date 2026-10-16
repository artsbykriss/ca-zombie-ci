// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFangRedeem {
    function redeemFang(uint256 amount) external returns (uint256); // Redeem Fang tokens for a reward
}
