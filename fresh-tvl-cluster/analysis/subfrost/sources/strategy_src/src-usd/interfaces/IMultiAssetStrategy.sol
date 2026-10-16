// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IMultiAssetStrategy
/// @notice A yield strategy for a MULTI-asset custody vault (`VaultImpl`), which
///         holds several ERC20s under one contract and names each by the same
///         `assetId` a Bitcoin-side burn uses.
///
/// @dev Deliberately NOT `IStrategy`, and not an extension of it.
///
///      `IStrategy` is single-asset (`deposit(uint256)`) and is still
///      implemented by `SubfrostVault` and `EthStakingStrategy`; widening it
///      would force both of them to change for no benefit. The substantive
///      reason is that a single-asset signature cannot say WHICH token a call
///      is about, so one strategy serving one vault holding both USDC and USDT
///      would have to infer it. The superseded `StablecoinStrategy` inferred it
///      from `msg.sender`, which is exactly why it needed a separate strategy
///      instance — and a separate vault — per asset.
///
///      Every mutating method is expected to be callable ONLY by the wired
///      vault. The vault is the custody boundary; a strategy that let anyone
///      else withdraw would move that boundary to whoever asked.
interface IMultiAssetStrategy {
    /// @notice The ERC20 this strategy accepts and pays out for `assetId`.
    function asset(uint8 assetId) external view returns (address);

    /// @notice Value currently attributable to `assetId`, in that asset's own
    ///         base units.
    ///
    /// @dev A strategy backing several assets with ONE pooled position must
    ///      attribute it, not report the whole position for each id — the vault
    ///      reads this per asset, so reporting the full position twice would
    ///      double-count the backing.
    function totalAssets(uint8 assetId) external view returns (uint256);

    /// @notice Pull `amount` of `assetId` from the vault and deploy it.
    /// @dev The vault approves first; the strategy pulls.
    function deposit(uint8 assetId, uint256 amount) external;

    /// @notice Return `amount` of `assetId` to the vault.
    /// @return actualAmount What was ACTUALLY delivered, which may differ from
    ///         the request in either direction (fees, slippage, rounding). The
    ///         vault must account against this, never against the request.
    function withdraw(uint8 assetId, uint256 amount) external returns (uint256 actualAmount);

    /// @notice Return everything attributable to `assetId` to the vault,
    ///         leaving any other asset's backing invested.
    function withdrawAll(uint8 assetId) external returns (uint256 amount);

    /// @notice Whether the strategy is accepting deposits.
    /// @dev The vault checks this before an automatic sweep, so pausing here is
    ///      a kill-switch that degrades the vault to plain custody rather than
    ///      blocking user deposits.
    function isActive() external view returns (bool);
}
