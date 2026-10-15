// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { IOracleEntry } from "../../oracle-entry/interfaces/IOracleEntry.sol";

enum SFNPayoffType {
    Average,
    BestOf,
    WorstOf
}

enum SFNOptionType {
    Bull,
    Bear
}

struct SFNProductCreationParams {
    uint128 minDepositAmount;
    uint128 minWithdrawalAmount;
    uint128 maxUnderlyingAmountLimit;
    address underlyingAsset;
    uint64 leverage;
    uint40 tenorInSeconds;
    uint8 hoursToStartLateFees;
    uint8 hoursToStartAuctionDefault;
    uint8 hoursToStartSettlementDefault;
    uint8 disputePeriodInHours;
    uint8 disputeGraceDelayInHours;
    uint16 lateFeeBps;
    string name;
    string tradeWinnerNftImage;
    uint24 observationIntervalInSeconds;
    address[] trackedAssets;
    SFNPayoffType payoffType;
    uint24 knockOutBps;
    uint24 strikeBps;
    SFNOptionType optionType;
    uint24 guaranteedAprRatioBps;
    uint24 minAprRatioBps;
    uint24 rebateAprRatioBps;
}

struct SFNProduct {
    uint128 minDepositAmount;
    uint128 minWithdrawalAmount;
    uint128 maxUnderlyingAmountLimit;
    uint128 sumVaultUnderlyingAmounts;
    address underlyingAsset;
    uint40 tenorInSeconds;
    uint8 hoursToStartLateFees;
    uint8 hoursToStartAuctionDefault;
    uint8 hoursToStartSettlementDefault;
    uint8 disputePeriodInHours;
    uint8 disputeGraceDelayInHours;
    uint16 lateFeeBps;
    uint64 leverage;
    uint24 observationIntervalInSeconds;
    uint24 knockOutBps;
    uint24 strikeBps;
    uint24 guaranteedAprRatioBps;
    uint24 minAprRatioBps;
    uint24 rebateAprRatioBps;
    SFNPayoffType payoffType;
    SFNOptionType optionType;
    bool isDepositQueueOpen;
    address[] trackedAssets;
    address[] vaults;
}

struct SFNTrackedAssetsData {
    uint128 initialSpotPrice;
    IOracleEntry.DataSource dataSource;
}

struct SFNVault {
    uint128 notional;
    uint128 totalYield;
    uint24 maxAprBps;
    uint24 lendingAprBps;
    bool isKnockedOut;
    uint16 observationsDone;
    uint96 buffer; // buffer if we need to add any more data
    SFNTrackedAssetsData[] trackedAssetsData;
}

struct SFNSpecificMMNFTMetadata {
    uint24 lendingAprBps;
    uint24 maxAprBps;
}

/**
 * @param vaultAddress address of the vault
 * @param auctionWinner address of the winner
 * @param tradeStartDate when the trade starts
 * @param lendingAprBps the lending APR provided by MM
 * @param maxAprBps the maximum possible apr on settlement
 * @param dataSources the list of data sources for the barriers
 */
struct SFNEndAuctionParams {
    address vaultAddress;
    address auctionWinner;
    uint40 tradeStartDate;
    uint16 lendingAprBps;
    uint16 maxAprBps;
    IOracleEntry.DataSource[] dataSources;
}
