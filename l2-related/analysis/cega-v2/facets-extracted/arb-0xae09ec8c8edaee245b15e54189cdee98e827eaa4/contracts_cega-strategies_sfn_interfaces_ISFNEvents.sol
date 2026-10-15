// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { VaultCreationParams } from "../../../Structs.sol";
import { ICommonEvents } from "../../common/interfaces/ICommonEvents.sol";

interface ISFNEvents is ICommonEvents {
    event SFNProductCreated(uint32 indexed productId);

    event SFNVaultCreated(
        uint32 indexed productId,
        address indexed vaultAddress,
        VaultCreationParams creationParams
    );

    event SFNAuctionEnded(
        address indexed vaultAddress,
        address indexed auctionWinner,
        uint40 tradeStartDate,
        uint16 lendingAprBps,
        uint16 maxAprBps,
        uint128[] initialSpotPrices
    );

    event SFNTradeStarted(
        address indexed vaultAddress,
        address auctionWinner,
        uint128 notionalAmount,
        uint128 yieldAmount
    );

    event SFNLateFeePaid(address indexed vaultAddress, uint128 feeAmount);

    event SFNIsKnockedOutUpdated(
        address indexed vaultAddress,
        bool isKnockedOut
    );

    event SFNVaultFeesCollected(
        address indexed vaultAddress,
        uint128 totalFees,
        uint128 managementFee,
        uint128 yieldFee
    );

    event SFNVaultRolledOver(address indexed vaultAddress);

    event SFNMinDepositAmountUpdated(
        uint32 indexed productId,
        uint128 minDepositAmount
    );

    event SFNMinWithdrawalAmountUpdated(
        uint32 indexed productId,
        uint128 minWithdrawalAmount
    );

    event SFNMaxUnderlyingAmountLimitUpdated(
        uint32 indexed productId,
        uint128 maxUnderlyingAmountLimit
    );

    event SFNIsDepositQueueOpenUpdated(
        uint32 indexed productId,
        bool isDepositQueueOpen
    );

    event SFNLateFeeBpsUpdated(uint32 indexed productId, uint16 lateFeeBps);

    event SFNHoursToStartLateFeesUpdated(
        uint32 indexed productId,
        uint8 hoursToStartLateFees
    );

    event SFNHoursToStartAuctionDefaultUpdated(
        uint32 indexed productId,
        uint8 hoursToStartAuctionDefault
    );

    event SFNHoursToStartSettlementDefaultUpdated(
        uint32 indexed productId,
        uint8 hoursToStartSettlementDefault
    );

    event SFNDisputePeriodInHoursUpdated(
        uint32 indexed productId,
        uint8 disputePeriodInHours
    );

    event SFNDisputeGraceDelayInHoursUpdated(
        uint32 indexed productId,
        uint8 disputeGraceDelayInHours
    );

    event SFNDisputeProcessed(
        address indexed vaultAddress,
        uint40 timestamp,
        bool isDisputeAccepted,
        uint128[] newPrices
    );

    event SFNDisputeSubmitted(address indexed vaultAddress, uint40 timestamp);
}
