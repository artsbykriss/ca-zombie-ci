// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

library Withdraw {
    struct Data {
        /// Recipient address on destination chain
        bytes32 destinationAddress;
        // Destination chain endpoint ID
        uint32 destinationEndpointId;
        /// Address of token to withdraw
        address token;
        /// Amount of tokens in withdrawn (normalized to gwei)
        uint256 amount;
        /// Amount of tokens charged on the withdraw (normalized to gwei)
        uint128 fee;
        /// Message index for the initial withdraw request
        uint64 messageIdx;
        /// Timestamp of the withdraw initiated
        uint64 initiatedAt;
        /// Signature of the EIP712 InitiateWithdrawMessage
        bytes signature;
    }
}
