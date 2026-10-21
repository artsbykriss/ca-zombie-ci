// SPDX-License-Identifier: MIT
pragma solidity >=0.8.29;

/// @title IPerpsCrossMargin
/// @notice Interface for cross margin functions
interface IPerpsCrossMargin {
    /// @notice Returns total projected realized PnL from deferred settlements across all active markets
    /// @dev This is the amount that would be materialized into quote-token collateral if pending
    ///      settlements were pumped now. It excludes unrealized PnL, isolated margin usage, and
    ///      cross funding fee (queried separately via getTotalCrossFundingFee).
    function getProjectedRealizedPnl(
        address account
    ) external view returns (int256);

    /// @notice Returns projected realized PnL and total cross funding fee in a single call
    /// @dev Merges getProjectedRealizedPnl and getTotalCrossFundingFee into one pass over all
    ///      active markets, saving a full market iteration.
    function getProjectedRealizedPnlAndFunding(
        address account
    ) external view returns (int256 pnl, int256 funding);

    /// @notice Returns total cross initial margin
    function getTotalCrossInitialMargin(
        address account
    ) external view returns (uint256);

    /// @notice Returns total cross unsettled USDC
    function getTotalCrossUnsettledUsdc(
        address account
    ) external view returns (int256);

    /// @notice Returns total cross funding fee
    function getTotalCrossFundingFee(
        address account
    ) external view returns (int256);

    /// @notice Returns projected cross margin balance
    /// @dev `totalTokenBalanceInUSDC` is expected to already include projected realized PnL and
    ///      projected cross funding fee, as returned by CollateralManager.getTotalTokenBalanceInUSDC.
    function getCrossMarginBalance(
        int256 totalTokenBalanceInUSDC,
        address account
    ) external view returns (int256);

    /// @notice Returns projected free cross margin balance
    /// @dev `totalTokenBalanceInUSDC` is expected to already include projected realized PnL and
    ///      projected cross funding fee, as returned by CollateralManager.getTotalTokenBalanceInUSDC.
    function getFreeCrossMarginBalance(
        int256 totalTokenBalanceInUSDC,
        address account
    ) external view returns (uint256);

    /// @notice Returns total cross maintenance margin
    function getTotalCrossMaintenanceMargin(
        address account
    ) external view returns (uint256);

    /// @notice Returns active cross markets bitmap for an account
    function getActiveCrossMarkets(
        address account
    ) external view returns (uint256[] memory);
}
