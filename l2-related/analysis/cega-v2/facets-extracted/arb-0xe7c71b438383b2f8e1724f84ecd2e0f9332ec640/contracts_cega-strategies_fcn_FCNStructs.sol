// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { IOracleEntry } from "../../oracle-entry/interfaces/IOracleEntry.sol";

struct FCNProductCreationParams {
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
    bool isBondOption;
    uint24 observationIntervalInSeconds;
    FCNOptionBarrier[] optionBarriers;
}

struct FCNProduct {
    uint128 minDepositAmount;
    uint128 minWithdrawalAmount;
    uint128 maxUnderlyingAmountLimit;
    uint128 sumVaultUnderlyingAmounts;
    address underlyingAsset;
    uint64 leverage;
    uint40 tenorInSeconds;
    uint8 hoursToStartLateFees;
    uint8 hoursToStartAuctionDefault;
    uint8 hoursToStartSettlementDefault;
    uint8 disputePeriodInHours;
    uint8 disputeGraceDelayInHours;
    uint16 lateFeeBps;
    bool isDepositQueueOpen;
    bool isBondOption;
    uint24 observationIntervalInSeconds;
    FCNOptionBarrier[] optionBarriers;
    address[] vaults;
}

struct FCNVaultCreationParams {
    string tokenName;
    string tokenSymbol;
    uint16 yieldFeeBps;
    uint16 managementFeeBps;
}

struct FCNVaultBarrierData {
    uint128 initialSpotPrice;
    IOracleEntry.DataSource dataSource;
}

struct FCNVault {
    uint128 notional;
    uint128 totalYield;
    uint16 aprBps;
    bool isKnockedIn;
    uint16 observationsDone;
    uint96 buffer; // buffer if we need to add any more data
    FCNVaultBarrierData[] barrierData;
}

struct FCNOptionBarrier {
    uint16 barrierBps;
    FCNOptionBarrierType barrierType;
    address asset;
    uint8 exponent;
}

enum FCNOptionBarrierType {
    None,
    KnockIn
}

enum FCNVaultStatus {
    DepositsClosed,
    DepositsOpen,
    PreAuction,
    Auctioned,
    Traded,
    AwaitingSettlement,
    Settled,
    FeesCollected,
    WithdrawalQueueProcessed,
    Zombie
}
