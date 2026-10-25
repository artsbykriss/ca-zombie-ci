// SPDX-License-Identifier: BSD-3-Clause-Clear
// ===== THIRD-PARTY NOTICE — DO NOT EDIT BY HAND =====
//
// Portions derived from zama-ai. Copyright © 2025 ZAMA. All rights reserved.
// Modifications Copyright © 2026 Primus Labs.
// Full license terms: see the BSD-3-Clause-Clear notice included in this source distribution.
//
// ===== END THIRD-PARTY NOTICE =====
pragma solidity ^0.8.27;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/// @title IVaultAggregatorConfidentia
/// @notice Interface defining the errors, events, and view functions for Confidential DeFi Gateway aggregators.
interface IVaultAggregatorConfidentia {
    /// @notice Thrown when dispatch is attempted before the minimum aggregate age.
    /// @param aggregateId The aggregate being dispatched.
    /// @param elapsed Seconds elapsed since aggregate creation.
    /// @param required Required minimum age in seconds.
    error AggregateTooYoung(uint256 aggregateId, uint256 elapsed, uint256 required);

    /// @notice Thrown when a token converter reports a zero rate.
    error InvalidTokenRate();

    /// @notice Thrown when the route asset does not match the expected vault asset.
    /// @param actualAsset The asset token provided by the route.
    /// @param expectedAsset Token address expected for this route.
    error RouteAssetMismatch(address actualAsset, address expectedAsset);

    /// @notice Thrown when the route share token does not match the expected vault share token.
    /// @param actualShare The share token provided by the route.
    /// @param expectedShare Token address expected for this route.
    error RouteShareMismatch(address actualShare, address expectedShare);

    /// @notice Thrown when the received asset value is below the the acceptable threshold after route execution.
    /// @param aggregateId The identifier of the aggregate that failed the slippage check.
    /// @param actual The observed value of the assets after the route execution.
    /// @param minimum The minimum acceptable value based on the deposited amount and the aggregate's max slippage tolerance.
    error SlippageExceeded(uint256 aggregateId, uint256 actual, uint256 minimum);

    /// @notice Thrown when maxSlippageBps exceeds 10 000 (100 %).
    error InvalidMaxSlippageBps();

    /// @notice Thrown when `minAggregateAge` exceeds the configured upper bound.
    error InvalidMinAggregateAge();

    /// @notice Thrown when `callbackDeadline` exceeds the configured upper bound.
    error InvalidCallbackDeadline();

    /// @notice Emitted when the minimum aggregate age is updated.
    /// @param minAggregateAge New minimum aggregate age in seconds.
    event MinAggregateAgeSet(uint256 minAggregateAge);

    /// @notice Emitted when the callback deadline is updated.
    /// @param callbackDeadline New callback deadline in seconds from dispatch time.
    event CallbackDeadlineSet(uint256 callbackDeadline);

    /// @notice Emitted when the maximum slippage tolerance is updated.
    /// @param maxSlippageBps New maximum slippage in basis points.
    event MaxSlippageBpsSet(uint16 maxSlippageBps);

    /// @notice Returns the configured ERC4626 vault.
    function vault() external view returns (IERC4626);

    /// @notice Returns the minimum aggregate age required before dispatch.
    function minAggregateAge() external view returns (uint256);

    /// @notice Returns the callback deadline for dispatched aggregatees (seconds from dispatch time).
    function callbackDeadline() external view returns (uint256);

    /// @notice Returns the creation timestamp for a aggregate.
    function aggregateCreatedAt(uint256 aggregateId) external view returns (uint256);

    /// @notice Returns the dispatch timestamp for a aggregate.
    function aggregateDispatchedAt(uint256 aggregateId) external view returns (uint256);

    /// @notice Returns the slippage tolerance frozen when a aggregate was opened.
    function aggregateMaxSlippageBps(uint256 aggregateId) external view returns (uint16);

    /// @notice Returns the maximum slippage tolerance in basis points.
    function maxSlippageBps() external view returns (uint16);

    /// @notice Returns the minimum aggregate age frozen when the aggregate was opened.
    function aggregateMinAggregateAge(uint256 aggregateId) external view returns (uint256);

    /// @notice Returns the callback deadline frozen when the aggregate was opened.
    function aggregateCallbackDeadline(uint256 aggregateId) external view returns (uint256);
}
