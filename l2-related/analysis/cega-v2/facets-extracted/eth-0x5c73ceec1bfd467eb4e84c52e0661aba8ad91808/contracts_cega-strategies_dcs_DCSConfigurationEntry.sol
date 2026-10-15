// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import {
    ReentrancyGuard
} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { CegaStorage } from "../../storage/CegaStorage.sol";
import {
    CegaGlobalStorage,
    DepositQueue,
    ProductMetadata,
    DCS_STRATEGY_ID
} from "../../Structs.sol";
import { DCSProduct } from "./DCSStructs.sol";
import { IAddressManager } from "../../aux/interfaces/IAddressManager.sol";
import { IACLManager } from "../../aux/interfaces/IACLManager.sol";
import { IDCSEvents } from "./interfaces/IDCSEvents.sol";
import {
    IDCSConfigurationEntry
} from "./interfaces/IDCSConfigurationEntry.sol";
import { Errors } from "../../utils/Errors.sol";
import { EntryBase } from "../common/EntryBase.sol";

contract DCSConfigurationEntry is
    EntryBase,
    IDCSEvents,
    IDCSConfigurationEntry
{
    // CONSTANTS

    constructor(IAddressManager _addressManager) EntryBase(_addressManager) {}

    // FUNCTIONS

    /**
     * @notice Sets the late fee bps amount for this DCS product
     * @param lateFeeBps is the new lateFeeBps
     * @param productId id of the DCS product
     */
    function dcsSetLateFeeBps(
        uint16 lateFeeBps,
        uint32 productId
    )
        external
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidProductStrategy(DCS_STRATEGY_ID, productId)
    {
        require(lateFeeBps > 0, Errors.VALUE_IS_ZERO);
        DCSProduct storage dcsProduct = getStorage().dcsProducts[productId];
        dcsProduct.lateFeeBps = lateFeeBps;
        emit DCSLateFeeBpsUpdated(productId, lateFeeBps);
    }

    /**
     * @notice Sets the min deposit amount for the product
     * @param minDepositAmount is the minimum units of underlying for a user to deposit
     */
    function dcsSetMinDepositAmount(
        uint128 minDepositAmount,
        uint32 productId
    )
        external
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidProductStrategy(DCS_STRATEGY_ID, productId)
    {
        require(minDepositAmount != 0, Errors.VALUE_IS_ZERO);
        DCSProduct storage dcsProduct = getStorage().dcsProducts[productId];
        dcsProduct.minDepositAmount = minDepositAmount;
        emit DCSMinDepositAmountUpdated(productId, minDepositAmount);
    }

    /**
     * @notice Sets the min withdrawal amount for the product
     * @param minWithdrawalAmount is the minimum units of vault shares for a user to withdraw
     */
    function dcsSetMinWithdrawalAmount(
        uint128 minWithdrawalAmount,
        uint32 productId
    )
        external
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidProductStrategy(DCS_STRATEGY_ID, productId)
    {
        require(minWithdrawalAmount != 0, Errors.VALUE_IS_ZERO);
        DCSProduct storage dcsProduct = getStorage().dcsProducts[productId];
        dcsProduct.minWithdrawalAmount = minWithdrawalAmount;
        emit DCSMinWithdrawalAmountUpdated(productId, minWithdrawalAmount);
    }

    /**
     * @notice Toggles whether the product is open or closed for deposits
     * @param isDepositQueueOpen is a boolean for whether the deposit queue is accepting deposits
     */
    function dcsSetIsDepositQueueOpen(
        bool isDepositQueueOpen,
        uint32 productId
    )
        external
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidProductStrategy(DCS_STRATEGY_ID, productId)
    {
        CegaGlobalStorage storage cgs = getStorage();
        DCSProduct storage dcsProduct = cgs.dcsProducts[productId];
        dcsProduct.isDepositQueueOpen = isDepositQueueOpen;
        emit DCSIsDepositQueueOpenUpdated(productId, isDepositQueueOpen);
    }

    function dcsSetHoursToStartLateFees(
        uint32 productId,
        uint8 hoursToStartLateFees
    )
        external
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidProductStrategy(DCS_STRATEGY_ID, productId)
    {
        require(hoursToStartLateFees != 0, Errors.VALUE_IS_ZERO);

        DCSProduct storage dcsProduct = getStorage().dcsProducts[productId];
        dcsProduct.hoursToStartLateFees = hoursToStartLateFees;

        emit DCSHoursToStartLateFeesUpdated(productId, hoursToStartLateFees);
    }

    function dcsSetHoursToStartAuctionDefault(
        uint32 productId,
        uint8 hoursToStartAuctionDefault
    )
        external
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidProductStrategy(DCS_STRATEGY_ID, productId)
    {
        require(hoursToStartAuctionDefault != 0, Errors.VALUE_IS_ZERO);

        DCSProduct storage dcsProduct = getStorage().dcsProducts[productId];
        dcsProduct.hoursToStartAuctionDefault = hoursToStartAuctionDefault;

        emit DCSHoursToStartAuctionDefaultUpdated(
            productId,
            hoursToStartAuctionDefault
        );
    }

    function dcsSetHoursToStartSettlementDefault(
        uint32 productId,
        uint8 hoursToStartSettlementDefault
    )
        external
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidProductStrategy(DCS_STRATEGY_ID, productId)
    {
        require(hoursToStartSettlementDefault != 0, Errors.VALUE_IS_ZERO);

        DCSProduct storage dcsProduct = getStorage().dcsProducts[productId];
        dcsProduct
            .hoursToStartSettlementDefault = hoursToStartSettlementDefault;

        emit DCSHoursToStartSettlementDefaultUpdated(
            productId,
            hoursToStartSettlementDefault
        );
    }

    /**
     * @notice Sets the maximum deposit limit for the product
     * @param maxUnderlyingAmountLimit is the deposit limit for the product
     */
    function dcsSetMaxUnderlyingAmount(
        uint128 maxUnderlyingAmountLimit,
        uint32 productId
    )
        external
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidProductStrategy(DCS_STRATEGY_ID, productId)
    {
        CegaGlobalStorage storage cgs = getStorage();
        DCSProduct storage dcsProduct = cgs.dcsProducts[productId];
        DepositQueue storage depositQueue = cgs.depositQueues[productId];
        require(
            depositQueue.queuedDepositsTotalAmount +
                dcsProduct.sumVaultUnderlyingAmounts <=
                maxUnderlyingAmountLimit,
            Errors.VALUE_TOO_SMALL
        );
        dcsProduct.maxUnderlyingAmountLimit = maxUnderlyingAmountLimit;
        emit DCSMaxUnderlyingAmountLimitUpdated(
            productId,
            maxUnderlyingAmountLimit
        );
    }

    function dcsSetDisputePeriodInHours(
        uint32 productId,
        uint8 disputePeriodInHours
    )
        external
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidProductStrategy(DCS_STRATEGY_ID, productId)
    {
        require(disputePeriodInHours > 0, Errors.VALUE_TOO_SMALL);

        DCSProduct storage dcsProduct = getStorage().dcsProducts[productId];
        dcsProduct.disputePeriodInHours = disputePeriodInHours;

        emit DCSDisputePeriodInHoursUpdated(productId, disputePeriodInHours);
    }

    /**
     * @notice Sets dispute grace period for the product
     * @param productId ID of the product
     * @param disputeGraceDelayInHours Dispute period in hours
     */
    function dcsSetDisputeGraceDelayInHours(
        uint32 productId,
        uint8 disputeGraceDelayInHours
    )
        external
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidProductStrategy(DCS_STRATEGY_ID, productId)
    {
        DCSProduct storage dcsProduct = getStorage().dcsProducts[productId];
        dcsProduct.disputeGraceDelayInHours = disputeGraceDelayInHours;

        emit DCSDisputeGraceDelayInHoursUpdated(
            productId,
            disputeGraceDelayInHours
        );
    }
}
