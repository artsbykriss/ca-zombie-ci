// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

enum DCSOptionType {
    BuyLow,
    SellHigh
}

enum SettlementStatus {
    NotAuctioned,
    Auctioned,
    InitialPremiumPaid,
    AwaitingSettlement,
    Settled,
    Defaulted
}

struct DCSProductCreationParams {
    uint128 maxUnderlyingAmountLimit;
    uint128 minDepositAmount;
    uint128 minWithdrawalAmount;
    address quoteAssetAddress;
    address baseAssetAddress;
    DCSOptionType dcsOptionType;
    uint8 hoursToStartLateFees;
    uint8 hoursToStartAuctionDefault;
    uint8 hoursToStartSettlementDefault;
    uint16 lateFeeBps;
    uint16 strikeBarrierBps;
    uint40 tenorInSeconds;
    uint8 disputePeriodInHours;
    uint8 disputeGraceDelayInHours;
    string name;
    string tradeWinnerNftImage;
}

struct DCSProduct {
    uint128 maxUnderlyingAmountLimit;
    uint128 minDepositAmount;
    uint128 minWithdrawalAmount;
    uint128 sumVaultUnderlyingAmounts; //revisit later
    address quoteAssetAddress; // should be immutable
    uint40 tenorInSeconds;
    uint16 lateFeeBps;
    uint8 hoursToStartLateFees;
    address baseAssetAddress; // should be immutable
    uint16 strikeBarrierBps;
    uint8 hoursToStartAuctionDefault;
    uint8 hoursToStartSettlementDefault;
    uint8 disputePeriodInHours;
    DCSOptionType dcsOptionType;
    bool isDepositQueueOpen;
    address[] vaults;
    uint8 disputeGraceDelayInHours;
}

struct DCSVault {
    uint128 initialSpotPrice;
    uint128 strikePrice;
    uint128 totalYield;
    uint16 aprBps;
    SettlementStatus settlementStatus; // DEPRECATED
    bool isPayoffInDepositAsset;
}
