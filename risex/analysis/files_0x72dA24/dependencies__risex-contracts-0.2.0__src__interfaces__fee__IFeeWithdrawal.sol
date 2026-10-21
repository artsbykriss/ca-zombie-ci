// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import { Currency } from "src/libraries/types/Currency.sol";

/// @title IFeeWithdrawal
/// @notice Interface for contracts that hold tokens and can transfer trading fees
interface IFeeWithdrawal {
    /// @notice Emitted when the fee manager address is updated
    event FeeManagerUpdated(address indexed oldFeeManager, address indexed newFeeManager);

    /// @notice Transfers trading fees to a recipient
    /// @dev Only callable by the registered FeeManager contract
    /// @param token The token to transfer
    /// @param amount The amount to transfer (in token decimals)
    /// @param to The recipient address
    function transferTradingFees(
        Currency token,
        uint256 amount,
        address to
    ) external;

    /// @notice Sets the FeeManager address that is exclusively allowed to call transferTradingFees
    /// @dev Only callable by the AccessManager authority (restricted)
    /// @param feeManager The FeeManager contract address
    function setFeeManager(
        address feeManager
    ) external;
}
