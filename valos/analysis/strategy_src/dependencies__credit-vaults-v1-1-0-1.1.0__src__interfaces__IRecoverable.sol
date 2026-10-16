// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

/// @notice Interface for recoverable tokens
interface IRecoverable {
    /// @notice Recovers tokens from the contract
    /// @param token The address of the token to recover
    /// @param to The address to send the recovered tokens to
    /// @param amount The amount of tokens to recover
    function recoverTokens(address token, address to, uint256 amount) external;
}
