// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.29;

import {IRISExStrategy} from "src/interfaces/extensions/IRISExStrategy.sol";

/// @title IRISExMarketMakingStrategy
/// @notice Interface for the RISEx perpetual trading strategy
/// @dev Extends IRISExStrategy with order placement, margin management,
///      and deposit cap functionality specific to the MM strategy.
interface IRISExMarketMakingStrategy is IRISExStrategy {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the withdrawal buffer threshold changes
    /// @param oldBuffer Previous buffer in basis points
    /// @param newBuffer New buffer in basis points
    event WithdrawalBufferUpdated(uint256 oldBuffer, uint256 newBuffer);

    /// @notice Emitted when the position limit threshold changes
    /// @param oldLimit Previous limit in basis points
    /// @param newLimit New limit in basis points
    event PositionLimitUpdated(uint256 oldLimit, uint256 newLimit);

    /// @notice Emitted when the deposit cap changes
    /// @param oldCap Previous cap (6 decimals)
    /// @param newCap New cap (6 decimals)
    event DepositCapUpdated(uint256 oldCap, uint256 newCap);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when an invalid buffer value is provided
    error InvalidBuffer();

    /*//////////////////////////////////////////////////////////////
                           VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get current margin ratio (withdrawable / equity)
    /// @return Margin ratio in basis points (0 if equity <= 0)
    function getMarginRatio() external view returns (uint256);

    /// @notice Check if the strategy has open positions
    /// @return True if positions are affecting margin
    function hasOpenPositions() external view returns (bool);

    /// @notice Get the deposit cap
    /// @return Maximum total assets allowed (0 = unlimited, 6 decimals)
    function getDepositCap() external view returns (uint128);

    /// @notice Get the withdrawal buffer threshold
    /// @return Buffer in basis points
    function getWithdrawalBufferBps() external view returns (uint16);

    /// @notice Get the position limit threshold
    /// @return Limit in basis points
    function getPositionLimitBps() external view returns (uint16);

    /*//////////////////////////////////////////////////////////////
                        MANAGEMENT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Update the withdrawal buffer threshold
    /// @dev Must be <= BPS_DENOMINATOR (10,000)
    /// @param newBufferBps New buffer in basis points
    function setWithdrawalBufferBps(uint16 newBufferBps) external;

    /// @notice Update the position limit threshold
    /// @dev Must be <= BPS_DENOMINATOR (10,000)
    /// @param newLimitBps New limit in basis points
    function setPositionLimitBps(uint16 newLimitBps) external;

    /// @notice Update the deposit cap
    /// @param newCap New deposit cap (0 = unlimited, 6 decimals)
    function setDepositCap(uint128 newCap) external;
}
