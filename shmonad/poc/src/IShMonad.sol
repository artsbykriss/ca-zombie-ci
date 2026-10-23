// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

/// @dev Minimal read/write interface for the deployed shMonad proxy (Monad chain 143).
/// Only the selectors exercised by the PoC are declared.
interface IShMonad {
    function deposit(uint256 assets, address receiver) external payable returns (uint256);
    function previewDeposit(uint256 assets) external view returns (uint256);
    function previewMint(uint256 shares) external view returns (uint256);
    function mint(uint256 shares, address receiver) external payable returns (uint256);
    function previewRedeem(uint256 shares) external view returns (uint256);
    function previewRedeemDetailed(uint256 shares) external view returns (uint256, uint256, uint256);
    function previewUnstake(uint256 shares) external view returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);
    function convertToShares(uint256 assets) external view returns (uint256);
    function totalAssets() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256);
    function requestUnstake(uint256 shares) external returns (uint64);
    function sendValidatorRewards(uint64 validatorId, uint256 feeRate) external payable;
    function boostYield(address yieldOriginator) external payable;

    function balanceOfCommitted(uint64 policyId, address account) external view returns (uint256);
    function createPolicy(uint48 escrowDuration) external returns (uint64);
    function commit(uint64 policyId, address commitRecipient, uint256 shares) external;
    function agentWithdrawFromCommitted(
        uint64 policyId,
        address from,
        address to,
        uint256 amount,
        uint256 fromReleaseAmount,
        bool amountSpecifiedInUnderlying
    )
        external;

    function depositToZeroYieldTranche(uint256 assets, address receiver) external payable;
    function convertZeroYieldTrancheToShares(uint256 assets, address receiver) external returns (uint256);
    function balanceOfZeroYieldTranche(address account) external view returns (uint256);

    // privileged surface (expected to revert for a fresh unprivileged caller)
    function setClosedStatus(bool closed) external;
    function setFrozenStatus(bool frozen) external;
    function addValidator(uint64 validatorId) external returns (address);
    function upgradeCoinbaseBeaconImplementation(address newImplementation) external;

    function globalLiabilities() external view returns (uint128, uint128, uint128);
    function getWorkingCapital() external view returns (uint128, uint128);
    function getGlobalRevenue(int256 nDelta) external view returns (uint120, uint120);
    function getGlobalStatus(int256 nDelta) external view returns (bool, bool);
    function getAdminValues() external view returns (uint64, uint16, uint16, uint16, uint16, uint128);
    function isValidatorActive(uint64 validatorId) external view returns (bool);
    function getValidatorData(uint64 validatorId) external view returns (uint64, uint64, bool, bool, bool, bool, address);
    function getAtomicPoolUtilization() external view returns (uint256, uint256, uint256, uint256);
    function getCurrentUnstakeFeeRateRay() external view returns (uint256);
}
