// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
}

/// @dev PEAKDEFI fund (v32 modular proxy chain). Signatures taken from the
/// verified IPeakDeFiFund interface (ProtectionStaking source, 0xead98f44)
/// and heimdall decompilation of the live implementation 0xa1dff47e.
interface IPeakFund {
    // ---- views ----
    function isInitialized() external view returns (bool);
    function owner() external view returns (address);
    function proxyAdmin() external view returns (address);
    function proxyImplementation() external view returns (address);
    function cyclePhase() external view returns (bool); // true = manage, false = sell
    function cycleNumber() external view returns (uint256);
    function startTimeOfCyclePhase() external view returns (uint256);
    function startTimeOfLastManagementPhase() external view returns (uint256);
    function totalFundsInUSDC() external view returns (uint256);
    function totalSharesAtLastManagePhaseStart() external view returns (uint256);
    function totalFundsAtManagePhaseStart() external view returns (uint256);
    function totalFundsAtManagePhaseEnd() external view returns (uint256);
    function totalLostFundAmount() external view returns (uint256);
    function totalCommissionLeft() external view returns (uint256);
    function peakReferralTotalCommissionLeft() external view returns (uint256);
    function peakManagerStakeRequired() external view returns (uint256);
    function isPermissioned() external view returns (bool);
    function devFundingAccount() external view returns (address);
    function devFundingRate() external view returns (uint256);
    function nextVersion() external view returns (address);
    function previousVersion() external view returns (address);
    function shareTokenAddr() external view returns (address);
    function controlTokenAddr() external view returns (address);
    function getPhaseLengths() external view returns (uint256[2] memory);
    function NEXT_PHASE_REWARD() external view returns (uint256);
    function isKyberToken(address) external view returns (bool);
    function isCompoundToken(address) external view returns (bool);
    function peakReferralCommissionBalanceOf(address) external returns (uint256);
    function peakReferralCommissionOfAt(address, uint256) external returns (uint256);
    function commissionBalanceOf(address) external returns (uint256, uint256);
    function commissionOfAt(address, uint256) external returns (uint256, uint256);

    // ---- state-changing (permissionless candidates) ----
    function nextPhase() external;
    function depositUSDC(uint256, address) external;
    function withdrawUSDC(uint256) external;
    function withdrawToken(address, uint256) external;
    function peakReferralRedeemCommission() external;
    function peakReferralRedeemCommissionForCycle(uint256) external;
    function redeemCommission(bool) external;
    function redeemCommissionForCycle(bool, uint256) external;
    function registerWithUSDC() external;
    function burnDeadman(address) external;
    function sellLeftoverToken(address, bytes calldata) external;

    // ---- privileged-looking (expected no-op / gated) ----
    function initOwner() external;
    function changeProxyAdmin(address) external;
    function developerInitiateUpgrade(address) external;
    function migrateOwnedContractsToNextVersion() external;
    function transferAssetToNextVersion(address) external;
    function changeDeveloperFeeAccount(address) external;
    function changeDeveloperFeeRate(uint256) external;
    function listKyberToken(address) external;
    function listCompoundToken(address) external;
    function transferOwnership(address) external;
    function renounceOwnership() external;
}

interface IPeakStaking {
    function initialized() external view returns (bool);
    function mintedPeakTokens() external view returns (uint256);
    function PEAK_MINT_CAP() external view returns (uint256);
    function peakToken() external view returns (address);
    function peakReward() external view returns (address);
    function userStakeAmount(address) external view returns (uint256);
    function getInterestAmount(uint256 stakeAmount, uint256 stakeTimeInDays) external view returns (uint256);
    function stake(uint256 stakeAmount, uint256 stakeTimeInDays, address referrer) external returns (uint256);
    function withdraw(uint256 stakeIdx) external;
}
