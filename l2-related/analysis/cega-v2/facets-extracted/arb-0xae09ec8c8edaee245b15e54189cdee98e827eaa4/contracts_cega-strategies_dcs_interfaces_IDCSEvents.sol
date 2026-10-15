// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { ICommonEvents } from "../../common/interfaces/ICommonEvents.sol";
import { VaultCreationParams } from "../../../Structs.sol";
import { SettlementStatus } from "../DCSStructs.sol";

interface IDCSEvents is ICommonEvents {
    event DCSProductCreated(uint32 indexed productId);

    event DCSVaultFeesCollected(
        address indexed vaultAddress,
        uint128 totalFees,
        uint128 managementFee,
        uint128 yieldFee
    );

    event DCSVaultCreated(
        uint32 indexed productId,
        address indexed vaultAddress,
        VaultCreationParams params
    );

    event DCSAuctionEnded(
        address indexed vaultAddress,
        address indexed auctionWinner,
        uint40 tradeStartDate,
        uint16 aprBps,
        uint128 initialSpotPrice,
        uint128 strikePrice
    );

    event DCSTradeStarted(
        address indexed vaultAddress,
        address auctionWinner,
        uint128 notionalAmount,
        uint128 yieldAmount
    );

    event DCSLateFeePaid(address indexed vaultAddress, uint128 feeAmount);

    event DCSVaultSettled(
        address indexed vaultAddress,
        address settler,
        uint128 depositedAmount,
        uint128 withdrawnAmount
    );

    event DCSVaultRolledOver(address indexed vaultAddress);

    event DCSIsPayoffInDepositAssetUpdated(
        address indexed vaultAddress,
        bool isPayoffInDepositAsset
    );

    event DCSLateFeeBpsUpdated(uint32 indexed productId, uint16 lateFeeBps);

    event DCSMinDepositAmountUpdated(
        uint32 indexed productId,
        uint128 minDepositAmount
    );

    event DCSMinWithdrawalAmountUpdated(
        uint32 indexed productId,
        uint128 minWithdrawalAmount
    );

    event DCSIsDepositQueueOpenUpdated(
        uint32 indexed productId,
        bool isDepositQueueOpen
    );

    event DCSMaxUnderlyingAmountLimitUpdated(
        uint32 indexed productId,
        uint128 maxUnderlyingAmountLimit
    );

    event DCSManagementFeeUpdated(address indexed vaultAddress, uint16 value);

    event DCSYieldFeeUpdated(address indexed vaultAddress, uint16 value);

    event DCSDisputeSubmitted(address indexed vaultAddress);

    event DCSDisputeProcessed(
        address indexed vaultAddress,
        bool isDisputeAccepted,
        uint40 timestamp,
        uint128 newPrice
    );

    event DCSDisputePeriodInHoursUpdated(
        uint32 indexed productId,
        uint8 disputePeriodInHours
    );

    event DCSDisputeGraceDelayInHoursUpdated(
        uint32 indexed productId,
        uint8 disputeGraceDelayInHours
    );

    event DCSHoursToStartLateFeesUpdated(
        uint32 indexed productId,
        uint8 hoursToStartLateFees
    );

    event DCSHoursToStartAuctionDefaultUpdated(
        uint32 indexed productId,
        uint8 hoursToStartAuctionDefault
    );

    event DCSHoursToStartSettlementDefaultUpdated(
        uint32 indexed productId,
        uint8 hoursToStartSettlementDefault
    );

    // Legacy events, left for compatibility

    event VaultCreated(
        uint32 indexed productId,
        address indexed vaultAddress,
        string _tokenSymbol,
        string _tokenName
    );

    event DCSSettlementStatusUpdated(
        address indexed vaultAddress,
        SettlementStatus settlementStatus
    );

    event DCSDaysToStartLateFeesUpdated(
        uint32 indexed productId,
        uint8 daysToStartLateFees
    );

    event DCSDaysToStartAuctionDefaultUpdated(
        uint32 indexed productId,
        uint8 daysToStartAuctionDefault
    );

    event DCSDaysToStartSettlementDefaultUpdated(
        uint32 indexed productId,
        uint8 daysToStartSettlementDefault
    );
}
