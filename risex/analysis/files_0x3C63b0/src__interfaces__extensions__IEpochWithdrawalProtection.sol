// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.29;

/// @title IEpochWithdrawalProtection
/// @notice Interface for epoch-based withdrawal protection
/// @dev Defines events, errors, and external API for withdrawal limits between harvests.
interface IEpochWithdrawalProtection {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a new epoch starts (at harvest)
    /// @param epochStartAssets Total assets at epoch start
    /// @param previousWithdrawals Withdrawals from the previous epoch
    event EpochReset(uint256 epochStartAssets, uint256 previousWithdrawals);

    /// @notice Emitted when max epoch outflow is updated
    /// @param oldBps Previous outflow in basis points
    /// @param newBps New outflow in basis points
    event MaxEpochOutflowUpdated(uint256 oldBps, uint256 newBps);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to set invalid BPS value
    error InvalidEpochOutflowBps();

    /*//////////////////////////////////////////////////////////////
                           VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Assets at epoch start (set during harvest, 6 decimals)
    function epochStartAssets() external view returns (uint128);

    /// @notice Cumulative _freeFunds withdrawals this epoch (6 decimals)
    function epochWithdrawals() external view returns (uint128);

    /// @notice Idle balance at epoch start (6 decimals)
    function epochStartIdle() external view returns (uint128);

    /// @notice Timestamp of last epoch reset (harvest)
    function epochStartTime() external view returns (uint32);

    /// @notice Maximum net outflow per epoch in basis points
    function maxEpochOutflowBps() external view returns (uint16);

    /// @notice Get max withdrawable amount for this epoch
    /// @return Max withdrawable in asset decimals
    function getEpochMaxWithdrawable() external view returns (uint256);

    /// @notice Get remaining withdrawal capacity for this epoch (idle-aware)
    /// @param currentIdle Current idle balance of the strategy
    /// @return Remaining capacity in asset decimals
    function getEpochWithdrawalCapacity(
        uint256 currentIdle
    ) external view returns (uint256);

    /// @notice Get current epoch duration
    /// @return Seconds since epoch started
    function getEpochDuration() external view returns (uint256);
}
