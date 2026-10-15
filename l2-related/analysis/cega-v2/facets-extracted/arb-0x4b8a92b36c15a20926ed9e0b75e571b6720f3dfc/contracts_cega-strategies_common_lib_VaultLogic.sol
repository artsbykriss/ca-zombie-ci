// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import {
    IERC20Metadata,
    IERC20
} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { CegaGlobalStorage, Vault, VaultStatus } from "../../../Structs.sol";
import { ICommonEvents } from "../interfaces/ICommonEvents.sol";
import { Errors } from "../../../utils/Errors.sol";
import {
    IOracleEntry
} from "../../../oracle-entry/interfaces/IOracleEntry.sol";

library VaultLogic {
    using SafeCast for uint256;

    // CONSTANTS

    uint128 internal constant DAYS_IN_YEAR = 365;
    uint128 internal constant HOURS_IN_DAY = 24;

    uint128 internal constant BPS_DECIMALS = 1e4;

    uint8 internal constant VAULT_DECIMALS = 18;

    uint8 internal constant NATIVE_ASSET_DECIMALS = 18;

    // FUNCTIONS

    /**
     * @notice Retrieves the decimals for a given asset.
     * @param asset The address of the asset.
     * @return uint8 The number of decimals of the asset.
     */
    function getAssetDecimals(address asset) internal view returns (uint8) {
        return
            asset == address(0)
                ? NATIVE_ASSET_DECIMALS
                : IERC20Metadata(asset).decimals();
    }

    /**
     * @notice Retrieves the total assets of a given vault.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     * @return uint128 The total assets of the vault.
     */
    function totalAssets(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) internal view returns (uint128) {
        return cgs.vaults[vaultAddress].totalAssets;
    }

    /**
     * @notice Converts share amount to equivalent asset amount.
     * @param _totalSupply The total supply of shares in the vault.
     * @param _totalAssets The total assets held in the vault.
     * @param _shares The number of shares to convert.
     * @return uint128 The equivalent asset amount.
     */
    function convertToAssets(
        uint256 _totalSupply,
        uint128 _totalAssets,
        uint256 _shares
    ) internal pure returns (uint128) {
        // assumption: all assets we support have <= 18 decimals
        return ((_shares * _totalAssets) / _totalSupply).toUint128();
    }

    /**
     * @notice Converts share amount to equivalent asset amount for a specific vault.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     * @param shares The number of shares to convert.
     * @return uint128 The equivalent asset amount.
     */
    function convertToAssets(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        uint256 shares
    ) internal view returns (uint128) {
        uint256 _totalSupply = IERC20(vaultAddress).totalSupply();

        if (_totalSupply == 0) return 0;
        // assumption: all assets we support have <= 18 decimals
        // shares and _totalSupply have 18 decimals
        return
            ((shares * totalAssets(cgs, vaultAddress)) / _totalSupply)
                .toUint128();
    }

    /**
     * @notice Converts asset amount to equivalent share amount.
     * @param _totalSupply The total supply of shares in the vault.
     * @param _totalAssets The total assets held in the vault.
     * @param _depositAssetDecimals The decimals of the deposit asset.
     * @param assets The amount of assets to convert.
     * @return uint256 The equivalent share amount.
     */
    function convertToShares(
        uint256 _totalSupply,
        uint128 _totalAssets,
        uint8 _depositAssetDecimals,
        uint128 assets
    ) internal pure returns (uint256) {
        if (_totalAssets == 0 || _totalSupply == 0) {
            return assets * 10 ** (VAULT_DECIMALS - _depositAssetDecimals);
        } else {
            // _totalSupply has 18 decimals, assets and _totalAssets have the same decimals
            return (_totalSupply * assets) / (_totalAssets);
        }
    }

    /**
     * @notice Checks if withdrawals are possible for a given vault.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     * @return bool True if withdrawals are possible, false otherwise.
     */
    function isWithdrawalPossible(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) internal view returns (bool) {
        Vault storage vault = cgs.vaults[vaultAddress];

        VaultStatus vaultStatus = vault.vaultStatus;
        if (
            vaultStatus == VaultStatus.FeesCollected ||
            vaultStatus == VaultStatus.WithdrawalQueueProcessed ||
            vaultStatus == VaultStatus.Zombie
        ) {
            return true;
        }

        return (vaultStatus == VaultStatus.Auctioned && vault.isDefaulted);
    }

    /**
     * @notice Determines if a vault has defaulted based on the current date and product parameters.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     * @return bool True if the vault has defaulted, false otherwise.
     */
    function getIsAuctionDefaulted(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        uint8 hoursToStartAuctionDefault
    ) internal view returns (bool) {
        Vault storage vault = cgs.vaults[vaultAddress];
        if (vault.vaultStatus != VaultStatus.Auctioned) {
            return false;
        }
        uint40 startDate = cgs.vaults[vaultAddress].tradeStartDate;
        uint40 hoursLate = getHoursLate(startDate);
        return hoursLate >= hoursToStartAuctionDefault;
    }

    /**
     * @notice Calculates the number of hours that have passed since a given start date.
     * @param startDate The start date.
     * @return uint40 The number of hours that have passed.
     */
    function getHoursLate(uint40 startDate) internal view returns (uint40) {
        uint40 currentTime = block.timestamp.toUint40();
        if (currentTime < startDate) {
            return 0;
        } else {
            return (currentTime - startDate) / 1 hours;
        }
    }

    /**
     * @notice Calculates the coupon payment for a given set of parameters.
     * @param underlyingAmount The amount of underlying asset.
     * @param tradeStartDate The start date of the trade.
     * @param aprBps The annual percentage rate in basis points.
     * @param endDate The end date for the coupon payment calculation.
     * @return uint128 The calculated coupon payment.
     */
    function calculateAmountFromApr(
        uint128 underlyingAmount,
        uint40 tradeStartDate,
        uint256 aprBps,
        uint40 endDate
    ) internal pure returns (uint128) {
        uint40 couponSeconds = endDate - tradeStartDate;
        return
            ((uint256(underlyingAmount) * couponSeconds * aprBps) /
                (DAYS_IN_YEAR * BPS_DECIMALS * 1 days)).toUint128();
    }

    /**
     * @notice Calculates the late fee based on the coupon, start date, and late fee parameters.
     * @param coupon The coupon amount.
     * @param startDate The start date of the period.
     * @param lateFeeBps The late fee in basis points.
     * @param hoursToStartLateFees The number of days to start charging late fees.
     * @param hoursToStartAuctionDefault The number of days to start auction default.
     * @return uint128 The calculated late fee.
     */
    function calculateLateFee(
        uint128 coupon,
        uint40 startDate,
        uint16 lateFeeBps,
        uint8 hoursToStartLateFees,
        uint8 hoursToStartAuctionDefault
    ) internal view returns (uint128) {
        uint40 hoursLate = getHoursLate(startDate);
        if (hoursLate < hoursToStartLateFees) {
            return 0;
        } else {
            if (hoursLate >= hoursToStartAuctionDefault) {
                hoursLate = hoursToStartAuctionDefault;
            }

            uint40 daysLate = hoursLate / 24;

            return
                (coupon * daysLate * lateFeeBps) /
                (BPS_DECIMALS);
        }
    }

    function calculateFees(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        uint64 tenorInSeconds,
        uint128 underlyingAmount,
        uint128 totalYield
    ) internal view returns (uint128, uint128, uint128) {
        Vault storage vault = cgs.vaults[vaultAddress];

        uint128 managementFee = (underlyingAmount *
            tenorInSeconds *
            vault.managementFeeBps) / (DAYS_IN_YEAR * 1 days * BPS_DECIMALS);
        uint128 yieldFee = (totalYield * vault.yieldFeeBps) / BPS_DECIMALS;
        uint128 totalFee = managementFee + yieldFee;

        return (totalFee, managementFee, yieldFee);
    }

    /**
     * @notice Sets the status of a vault in the global storage.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     * @param status The new status to be set for the vault.
     */
    function setVaultStatus(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        VaultStatus status
    ) internal {
        cgs.vaults[vaultAddress].vaultStatus = status;

        emit ICommonEvents.CommonVaultStatusUpdated(vaultAddress, status);
    }

    function setIsDefaulted(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        bool value
    ) internal {
        Vault storage vault = cgs.vaults[vaultAddress];

        vault.isDefaulted = value;

        emit ICommonEvents.VaultDefaultUpdated(vaultAddress, value);
    }

    /**
     * @notice Opens a vault for deposits.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     */
    function openVaultDeposits(
        CegaGlobalStorage storage cgs,
        address vaultAddress
    ) internal {
        require(
            cgs.vaults[vaultAddress].vaultStatus == VaultStatus.DepositsClosed,
            Errors.INVALID_VAULT_STATUS
        );
        setVaultStatus(cgs, vaultAddress, VaultStatus.DepositsOpen);
    }

    function getAssetCode(address asset) internal pure returns (bytes32) {
        return keccak256(abi.encode(asset));
    }

    /**
     * @notice Overrides the oracle price for a specific vault and timestamp.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     * @param timestamp The timestamp for which the price is overridden.
     * @param newPrice The new price to override.
     */
    function overrideOraclePrice(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        address asset,
        uint40 timestamp,
        uint128 newPrice
    ) internal {
        require(newPrice != 0, Errors.INVALID_PRICE);

        cgs.oraclePriceOverride[vaultAddress][getAssetCode(asset)][
            timestamp
        ] = newPrice;

        emit ICommonEvents.OraclePriceOverriden(
            vaultAddress,
            asset,
            timestamp,
            newPrice
        );
    }

    function getSingleSpotPriceAt(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        IOracleEntry oracleEntry,
        address asset,
        IOracleEntry.DataSource dataSource,
        uint40 priceTimestamp
    ) internal view returns (uint128) {
        uint128 priceOverride = cgs.oraclePriceOverride[vaultAddress][
            VaultLogic.getAssetCode(asset)
        ][priceTimestamp];

        if (priceOverride > 0) {
            return priceOverride;
        }

        return oracleEntry.getSinglePrice(asset, priceTimestamp, dataSource);
    }
}
