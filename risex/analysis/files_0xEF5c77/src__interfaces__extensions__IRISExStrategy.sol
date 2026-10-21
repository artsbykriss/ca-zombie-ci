// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.29;

import {IEpochWithdrawalProtection} from "src/interfaces/extensions/IEpochWithdrawalProtection.sol";

/// @title IRISExStrategy
/// @notice Shared interface for RISEx strategy contracts
/// @dev Defines events, errors, and external API common to both the
///      perpetual trading strategy and the liquidation strategy.
interface IRISExStrategy is IEpochWithdrawalProtection {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when assets are deployed to RISEx as collateral
    /// @param amount Amount deployed (6 decimals)
    event DepositedToRISEx(uint256 amount);

    /// @notice Emitted when assets are withdrawn from RISEx collateral
    /// @param amount Amount withdrawn (6 decimals)
    event WithdrawnFromRISEx(uint256 amount);

    /// @notice Emitted when a depositor's whitelist status changes
    /// @param depositor The depositor address
    /// @param allowed Whether the depositor is now whitelisted
    event DepositorWhitelistUpdated(address indexed depositor, bool allowed);

    /// @notice Emitted when the EIP-1271 signer is updated
    /// @param oldSigner Previous signer address
    /// @param newSigner New signer address
    event SignerUpdated(address indexed oldSigner, address indexed newSigner);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when a zero address is provided where non-zero is required
    error ZeroAddress();

    /// @notice Thrown when withdrawals are blocked because live assets are below recorded (stale loss)
    error StaleLoss();

    /// @notice Thrown when an EIP-712 signature is invalid
    error InvalidSignature();

    /// @notice Thrown when signer is not set
    error SignerNotSet();

    /// @notice Thrown when a signed action has expired
    error ExpiredSignature();

    /// @notice Thrown when the provided nonce doesn't match the expected value
    error InvalidNonce();

    /*//////////////////////////////////////////////////////////////
                           VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the strategy's total account equity
    /// @dev Equity = collateral + unrealized PnL from all positions
    /// @return Total account equity in 6 decimals (can be negative)
    function getAccountEquity() external view returns (int256);

    /// @notice Get the strategy's withdrawable amount from RISEx
    /// @dev Amount that can be withdrawn considering margin requirements
    /// @return Withdrawable amount in 6 decimals
    function getWithdrawableAmount() external view returns (uint256);

    /// @notice Get the strategy's collateral balance in RISEx for the asset token
    /// @return Collateral balance in 6 decimals
    function getCollateralBalance() external view returns (int256);

    /*//////////////////////////////////////////////////////////////
                        MANAGEMENT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Update the max epoch withdrawal percentage
    /// @param newBps New max withdrawal in basis points (e.g., 2000 = 20%)
    function setMaxEpochOutflowBps(uint16 newBps) external;

    /// @notice Set whitelist status for a depositor
    /// @param depositor The address to whitelist/remove
    /// @param allowed True to whitelist, false to remove
    function setWhitelistedDepositor(address depositor, bool allowed) external;

    /// @notice Set the EIP-1271 signer address (session key)
    /// @dev When set to address(0), signed actions and isValidSignature are disabled
    /// @param newSigner The new signer address
    function setSigner(address newSigner) external;

    /// @notice Check if an address is whitelisted for deposits
    /// @param depositor The address to check
    /// @return True if whitelisted
    function whitelistedDepositor(
        address depositor
    ) external view returns (bool);

    /// @notice Get the current EIP-1271 signer
    /// @return The signer address (address(0) means signer not configured)
    function getSigner() external view returns (address);

    /// @notice Get the current EIP-712 nonce (for replay protection)
    /// @return The next nonce to use in signed actions
    function getNonce() external view returns (uint256);
}
