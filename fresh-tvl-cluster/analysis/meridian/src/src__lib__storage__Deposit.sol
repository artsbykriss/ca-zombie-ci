// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

library Deposit {
    struct Data {
        /// Address of token to deposit
        address token;
        /// Amount of tokens to be deposited (normalized to gwei)
        uint256 amount;
        /// Amount of tokens charged on the deposit (normalized to gwei)
        uint128 fee;
    }
}
