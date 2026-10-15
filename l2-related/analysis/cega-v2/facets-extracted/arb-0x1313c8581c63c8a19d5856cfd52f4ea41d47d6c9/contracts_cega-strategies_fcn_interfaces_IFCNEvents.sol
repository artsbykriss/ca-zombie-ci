// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { ICommonEvents } from "../../common/interfaces/ICommonEvents.sol";
import { FCNVaultCreationParams } from "../FCNStructs.sol";

interface IFCNEvents is ICommonEvents {
    event FCNProductCreated(uint32 indexed productId);

    event FCNVaultCreated(
        uint32 indexed productId,
        address indexed vaultAddress,
        FCNVaultCreationParams creationParams
    );

    event FCNLateFeeBpsUpdated(uint32 indexed productId, uint16 lateFeeBps);

    event FCNMinDepositAmountUpdated(
        uint32 indexed productId,
        uint128 minDepositAmount
    );

    event FCNMinWithdrawalAmountUpdated(
        uint32 indexed productId,
        uint128 minWithdrawalAmount
    );

    event FCNIsDepositQueueOpenUpdated(
        uint32 indexed productId,
        bool isDepositQueueOpen
    );

    event FCNMaxUnderlyingAmountLimitUpdated(
        uint32 indexed productId,
        uint128 maxUnderlyingAmountLimit
    );

    event FCNDisputePeriodInHoursUpdated(
        uint32 indexed productId,
        uint8 disputePeriodInHours
    );

    event FCNDisputeGraceDelayInHoursUpdated(
        uint32 indexed productId,
        uint8 disputeGraceDelayInHours
    );

    event FCNHoursToStartLateFeesUpdated(
        uint32 indexed productId,
        uint8 hoursToStartLateFees
    );

    event FCNHoursToStartAuctionDefaultUpdated(
        uint32 indexed productId,
        uint8 hoursToStartAuctionDefault
    );

    event FCNHoursToStartSettlementDefaultUpdated(
        uint32 indexed productId,
        uint8 hoursToStartSettlementDefault
    );

    event FCNAuctionEnded(
        address indexed vaultAddress,
        address indexed auctionWinner,
        uint40 tradeStartDate,
        uint16 aprBps,
        uint128[] initialSpotPrices
    );

    event FCNTradeStarted(
        address indexed vaultAddress,
        address auctionWinner,
        uint128 notionalAmount,
        uint128 yieldAmount
    );

    event FCNIsKnockedInUpdated(address indexed vaultAddress, bool isKnockedIn);

    event FCNLateFeePaid(address indexed vaultAddress, uint128 feeAmount);

    event FCNBondRepaid(address indexed vaultAddress, uint128 amount);

    event FCNVaultRolledOver(address indexed vaultAddress);

    event FCNVaultFeesCollected(
        address indexed vaultAddress,
        uint128 totalFees,
        uint128 managementFee,
        uint128 yieldFee
    );

    event FCNDisputeProcessed(
        address indexed vaultAddress,
        bool isDisputeAccepted,
        uint8 barrierIndex,
        uint40 timestamp,
        uint128 newPrice
    );

    event FCNDisputeSubmitted(
        address indexed vaultAddress,
        uint8 barrierIndex,
        uint40 timestamp
    );

    event FCNProductIsBondOptionUpdated(
        uint32 indexed productId,
        bool isBondOption
    );

    // Legacy event, left for compatibility

    event FCNBondAllowListUpdated(address indexed receiver, bool value);

    event FCNDaysToStartLateFeesUpdated(
        uint32 indexed productId,
        uint8 daysToStartLateFees
    );

    event FCNDaysToStartAuctionDefaultUpdated(
        uint32 indexed productId,
        uint8 daysToStartAuctionDefault
    );

    event FCNDaysToStartSettlementDefaultUpdated(
        uint32 indexed productId,
        uint8 daysToStartSettlementDefault
    );
}
