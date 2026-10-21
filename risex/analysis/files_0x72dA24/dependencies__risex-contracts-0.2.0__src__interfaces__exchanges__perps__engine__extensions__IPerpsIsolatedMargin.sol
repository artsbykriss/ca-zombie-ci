// SPDX-License-Identifier: MIT
pragma solidity >=0.8.29;

/// @title IPerpsIsolatedMargin
/// @notice Interface for isolated margin functions
interface IPerpsIsolatedMargin {
    /*//////////////////////////////////////////////////////////////////////////
                                    STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Request parameters to update isolated position margin balance
    struct UpdateIsolatedPositionMarginBalanceParams {
        uint16 marketId;
        int256 amount;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when update isolated position margin balance amount is zero
    error UpdateIsolatedPositionMarginBalanceZeroAmount();

    /// @notice Thrown when updating isolated position margin balance in cross mode
    error UpdateIsolatedPositionMarginBalanceInCross();

    /// @notice Thrown when updating isolated position margin balance with no open position
    error UpdateIsolatedPositionMarginBalanceNotOpen();

    /// @notice Thrown when free cross USDC is insufficient
    error UpdateIsolatedPositionMarginBalanceInsufficientFreeCrossUsdc(uint256 available, uint256 required);

    /// @notice Thrown when free isolated margin balance is insufficient
    error UpdateIsolatedPositionMarginBalanceInsufficientFreeIsolatedMarginBalance(uint256 available, uint256 required);

    /*//////////////////////////////////////////////////////////////////////////
                                    EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Emitted when an account updates isolated position margin balance in a market
    event UpdateIsolatedPositionMarginBalance(
        address indexed account, uint16 indexed marketId, uint256 oldBalance, uint256 newBalance
    );

    /*//////////////////////////////////////////////////////////////////////////
                                    FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns total isolated margin usage
    function getTotalIsolatedMarginUsage(
        address account
    ) external view returns (uint256);

    /// @notice Returns active isolated markets bitmap for an account
    function getActiveIsolatedMarkets(
        address account
    ) external view returns (uint256[] memory);

    /// @notice Update isolated position margin balance
    function updateIsolatedPositionMarginBalance(
        UpdateIsolatedPositionMarginBalanceParams calldata params
    ) external;
}
