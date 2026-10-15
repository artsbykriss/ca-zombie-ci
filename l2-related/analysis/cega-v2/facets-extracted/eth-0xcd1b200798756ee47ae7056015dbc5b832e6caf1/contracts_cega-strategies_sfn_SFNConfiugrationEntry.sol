// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import {
    CegaGlobalStorage,
    DepositQueue,
    SFN_STRATEGY_ID
} from "../../Structs.sol";
import { EntryBase } from "../common/EntryBase.sol";
import { IAddressManager } from "../../aux/interfaces/IAddressManager.sol";
import { Errors } from "../../utils/Errors.sol";

import { SFNProduct } from "./SFNStructs.sol";
import {
    ISFNConfigurationEntry
} from "./interfaces/ISFNConfigurationEntry.sol";
import { ISFNEvents } from "./interfaces/ISFNEvents.sol";

contract SFNConfigurationEntry is
    ISFNConfigurationEntry,
    ISFNEvents,
    EntryBase
{
    // CONSTRUCTOR

    constructor(IAddressManager _addressManager) EntryBase(_addressManager) {}

    // FUNCTIONS

    /**
     * @notice Sets the min deposit amount for the product
     * @param productId ID of the product
     * @param minDepositAmount is the minimum units of underlying for a user to deposit
     */
    function sfnSetMinDepositAmount(
        uint32 productId,
        uint128 minDepositAmount
    )
        external
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidProductStrategy(SFN_STRATEGY_ID, productId)
    {
        require(minDepositAmount != 0, Errors.VALUE_IS_ZERO);
        SFNProduct storage sfnProduct = getStorage().sfnProducts[productId];
        sfnProduct.minDepositAmount = minDepositAmount;
        emit SFNMinDepositAmountUpdated(productId, minDepositAmount);
    }

    /**
     * @notice Sets the min withdrawal amount for the product
     * @param productId ID of the product
     * @param minWithdrawalAmount is the minimum units of vault shares for a user to withdraw
     */
    function sfnSetMinWithdrawalAmount(
        uint32 productId,
        uint128 minWithdrawalAmount
    )
        external
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidProductStrategy(SFN_STRATEGY_ID, productId)
    {
        require(minWithdrawalAmount != 0, Errors.VALUE_IS_ZERO);
        SFNProduct storage sfnProduct = getStorage().sfnProducts[productId];
        sfnProduct.minWithdrawalAmount = minWithdrawalAmount;
        emit SFNMinWithdrawalAmountUpdated(productId, minWithdrawalAmount);
    }

    /**
     * @notice Sets the maximum deposit limit for the product
     * @param productId ID of the product
     * @param maxUnderlyingAmountLimit is the deposit limit for the product

     */
    function sfnSetMaxUnderlyingAmountLimit(
        uint32 productId,
        uint128 maxUnderlyingAmountLimit
    )
        external
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidProductStrategy(SFN_STRATEGY_ID, productId)
    {
        CegaGlobalStorage storage cgs = getStorage();
        SFNProduct storage sfnProduct = cgs.sfnProducts[productId];
        DepositQueue storage depositQueue = cgs.depositQueues[productId];
        require(
            depositQueue.queuedDepositsTotalAmount +
                sfnProduct.sumVaultUnderlyingAmounts <=
                maxUnderlyingAmountLimit,
            Errors.VALUE_TOO_SMALL
        );
        sfnProduct.maxUnderlyingAmountLimit = maxUnderlyingAmountLimit;
        emit SFNMaxUnderlyingAmountLimitUpdated(
            productId,
            maxUnderlyingAmountLimit
        );
    }

    /**
     * @notice Toggles whether the product is open or closed for deposits
     * @param productId ID of the product
     * @param isDepositQueueOpen is a boolean for whether the deposit queue is accepting deposits
     */
    function sfnSetIsDepositQueueOpen(
        uint32 productId,
        bool isDepositQueueOpen
    )
        external
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidProductStrategy(SFN_STRATEGY_ID, productId)
    {
        CegaGlobalStorage storage cgs = getStorage();
        SFNProduct storage sfnProduct = cgs.sfnProducts[productId];
        sfnProduct.isDepositQueueOpen = isDepositQueueOpen;
        emit SFNIsDepositQueueOpenUpdated(productId, isDepositQueueOpen);
    }

    /**
     * @notice Sets the late fee bps amount for this SFN product
     * @param productId id of the SFN product
     * @param lateFeeBps is the new lateFeeBps
     */
    function sfnSetLateFeeBps(
        uint32 productId,
        uint16 lateFeeBps
    )
        external
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidProductStrategy(SFN_STRATEGY_ID, productId)
    {
        require(lateFeeBps > 0, Errors.VALUE_IS_ZERO);
        SFNProduct storage sfnProduct = getStorage().sfnProducts[productId];
        sfnProduct.lateFeeBps = lateFeeBps;
        emit SFNLateFeeBpsUpdated(productId, lateFeeBps);
    }

    /**
     * @notice Sets hours to start late fees for product
     * @param productId ID of the product
     * @param hoursToStartLateFees Hours to start late fees
     */
    function sfnSetHoursToStartLateFees(
        uint32 productId,
        uint8 hoursToStartLateFees
    )
        external
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidProductStrategy(SFN_STRATEGY_ID, productId)
    {
        require(hoursToStartLateFees != 0, Errors.VALUE_IS_ZERO);

        SFNProduct storage sfnProduct = getStorage().sfnProducts[productId];
        sfnProduct.hoursToStartLateFees = hoursToStartLateFees;

        emit SFNHoursToStartLateFeesUpdated(productId, hoursToStartLateFees);
    }

    /**
     * @notice Sets hours to start auction default for product
     * @param productId ID of the product
     * @param hoursToStartAuctionDefault Hours to start auction default
     */
    function sfnSetHoursToStartAuctionDefault(
        uint32 productId,
        uint8 hoursToStartAuctionDefault
    )
        external
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidProductStrategy(SFN_STRATEGY_ID, productId)
    {
        require(hoursToStartAuctionDefault != 0, Errors.VALUE_IS_ZERO);

        SFNProduct storage sfnProduct = getStorage().sfnProducts[productId];
        sfnProduct.hoursToStartAuctionDefault = hoursToStartAuctionDefault;

        emit SFNHoursToStartAuctionDefaultUpdated(
            productId,
            hoursToStartAuctionDefault
        );
    }

    /**
     * @notice Sets hours to start settlement default for product
     * @param productId ID of the product
     * @param hoursToStartSettlementDefault Hours to start settlement default
     */
    function sfnSetHoursToStartSettlementDefault(
        uint32 productId,
        uint8 hoursToStartSettlementDefault
    )
        external
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidProductStrategy(SFN_STRATEGY_ID, productId)
    {
        require(hoursToStartSettlementDefault != 0, Errors.VALUE_IS_ZERO);

        SFNProduct storage sfnProduct = getStorage().sfnProducts[productId];
        sfnProduct
            .hoursToStartSettlementDefault = hoursToStartSettlementDefault;

        emit SFNHoursToStartSettlementDefaultUpdated(
            productId,
            hoursToStartSettlementDefault
        );
    }

    /**
     * @notice Sets dispute period for the product
     * @param productId ID of the product
     * @param disputePeriodInHours Dispute period in hours
     */
    function sfnSetDisputePeriodInHours(
        uint32 productId,
        uint8 disputePeriodInHours
    )
        external
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidProductStrategy(SFN_STRATEGY_ID, productId)
    {
        require(disputePeriodInHours != 0, Errors.VALUE_IS_ZERO);

        SFNProduct storage sfnProduct = getStorage().sfnProducts[productId];
        sfnProduct.disputePeriodInHours = disputePeriodInHours;

        emit SFNDisputePeriodInHoursUpdated(productId, disputePeriodInHours);
    }

    /**
     * @notice Sets dispute grace period for the product
     * @param productId ID of the product
     * @param disputeGraceDelayInHours Dispute period in hours
     */
    function sfnSetDisputeGraceDelayInHours(
        uint32 productId,
        uint8 disputeGraceDelayInHours
    )
        external
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidProductStrategy(SFN_STRATEGY_ID, productId)
    {
        SFNProduct storage sfnProduct = getStorage().sfnProducts[productId];
        sfnProduct.disputeGraceDelayInHours = disputeGraceDelayInHours;

        emit SFNDisputeGraceDelayInHoursUpdated(
            productId,
            disputeGraceDelayInHours
        );
    }
}
