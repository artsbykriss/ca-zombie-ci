// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import {
    ReentrancyGuard
} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { CegaStorage } from "../../storage/CegaStorage.sol";
import {
    CegaGlobalStorage,
    DepositQueue,
    FCN_STRATEGY_ID
} from "../../Structs.sol";
import { FCNProduct } from "./FCNStructs.sol";
import { EntryBase } from "../common/EntryBase.sol";
import { IAddressManager } from "../../aux/interfaces/IAddressManager.sol";
import {
    IFCNConfigurationEntry
} from "./interfaces/IFCNConfigurationEntry.sol";
import { IFCNEvents } from "./interfaces/IFCNEvents.sol";
import { Errors } from "../../utils/Errors.sol";
import { FCNProduct, FCNOptionBarrier } from "./FCNStructs.sol";

contract FCNConfigurationEntry is
    IFCNConfigurationEntry,
    IFCNEvents,
    EntryBase
{
    // CONSTRUCTOR

    constructor(IAddressManager _addressManager) EntryBase(_addressManager) {}

    // FUNCTIONS

    /**
     * @notice Sets the late fee bps amount for this FCN product
     * @param productId id of the FCN product
     * @param lateFeeBps is the new lateFeeBps
     */
    function fcnSetLateFeeBps(
        uint32 productId,
        uint16 lateFeeBps
    )
        external
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidProductStrategy(FCN_STRATEGY_ID, productId)
    {
        require(lateFeeBps > 0, Errors.VALUE_IS_ZERO);
        FCNProduct storage fcnProduct = getStorage().fcnProducts[productId];
        fcnProduct.lateFeeBps = lateFeeBps;
        emit FCNLateFeeBpsUpdated(productId, lateFeeBps);
    }

    /**
     * @notice Sets the min deposit amount for the product
     * @param productId ID of the product
     * @param minDepositAmount is the minimum units of underlying for a user to deposit
     */
    function fcnSetMinDepositAmount(
        uint32 productId,
        uint128 minDepositAmount
    )
        external
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidProductStrategy(FCN_STRATEGY_ID, productId)
    {
        require(minDepositAmount != 0, Errors.VALUE_IS_ZERO);
        FCNProduct storage fcnProduct = getStorage().fcnProducts[productId];
        fcnProduct.minDepositAmount = minDepositAmount;
        emit FCNMinDepositAmountUpdated(productId, minDepositAmount);
    }

    /**
     * @notice Sets the min withdrawal amount for the product
     * @param productId ID of the product
     * @param minWithdrawalAmount is the minimum units of vault shares for a user to withdraw
     */
    function fcnSetMinWithdrawalAmount(
        uint32 productId,
        uint128 minWithdrawalAmount
    )
        external
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidProductStrategy(FCN_STRATEGY_ID, productId)
    {
        require(minWithdrawalAmount != 0, Errors.VALUE_IS_ZERO);
        FCNProduct storage fcnProduct = getStorage().fcnProducts[productId];
        fcnProduct.minWithdrawalAmount = minWithdrawalAmount;
        emit FCNMinWithdrawalAmountUpdated(productId, minWithdrawalAmount);
    }

    /**
     * @notice Toggles whether the product is open or closed for deposits
     * @param productId ID of the product
     * @param isDepositQueueOpen is a boolean for whether the deposit queue is accepting deposits
     */
    function fcnSetIsDepositQueueOpen(
        uint32 productId,
        bool isDepositQueueOpen
    )
        external
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidProductStrategy(FCN_STRATEGY_ID, productId)
    {
        CegaGlobalStorage storage cgs = getStorage();
        FCNProduct storage fcnProduct = cgs.fcnProducts[productId];
        fcnProduct.isDepositQueueOpen = isDepositQueueOpen;
        emit FCNIsDepositQueueOpenUpdated(productId, isDepositQueueOpen);
    }

    /**
     * @notice Sets days to start late fees for product
     * @param productId ID of the product
     * @param hoursToStartLateFees Days to start late fees
     */
    function fcnSetHoursToStartLateFees(
        uint32 productId,
        uint8 hoursToStartLateFees
    )
        external
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidProductStrategy(FCN_STRATEGY_ID, productId)
    {
        require(hoursToStartLateFees != 0, Errors.VALUE_IS_ZERO);

        FCNProduct storage fcnProduct = getStorage().fcnProducts[productId];
        fcnProduct.hoursToStartLateFees = hoursToStartLateFees;

        emit FCNHoursToStartLateFeesUpdated(productId, hoursToStartLateFees);
    }

    /**
     * @notice Sets days to start auction default for product
     * @param productId ID of the product
     * @param hoursToStartAuctionDefault Days to start auction default
     */
    function fcnSetHoursToStartAuctionDefault(
        uint32 productId,
        uint8 hoursToStartAuctionDefault
    )
        external
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidProductStrategy(FCN_STRATEGY_ID, productId)
    {
        require(hoursToStartAuctionDefault != 0, Errors.VALUE_IS_ZERO);

        FCNProduct storage fcnProduct = getStorage().fcnProducts[productId];
        fcnProduct.hoursToStartAuctionDefault = hoursToStartAuctionDefault;

        emit FCNHoursToStartAuctionDefaultUpdated(
            productId,
            hoursToStartAuctionDefault
        );
    }

    /**
     * @notice Sets days to start settlement default for product
     * @param productId ID of the product
     * @param hoursToStartSettlementDefault Days to start settlement default
     */
    function fcnSetHoursToStartSettlementDefault(
        uint32 productId,
        uint8 hoursToStartSettlementDefault
    )
        external
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidProductStrategy(FCN_STRATEGY_ID, productId)
    {
        require(hoursToStartSettlementDefault != 0, Errors.VALUE_IS_ZERO);

        FCNProduct storage fcnProduct = getStorage().fcnProducts[productId];
        fcnProduct
            .hoursToStartSettlementDefault = hoursToStartSettlementDefault;

        emit FCNHoursToStartSettlementDefaultUpdated(
            productId,
            hoursToStartSettlementDefault
        );
    }

    /**
     * @notice Sets the maximum deposit limit for the product
     * @param productId ID of the product
     * @param maxUnderlyingAmountLimit is the deposit limit for the product

     */
    function fcnSetMaxUnderlyingAmountLimit(
        uint32 productId,
        uint128 maxUnderlyingAmountLimit
    )
        external
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidProductStrategy(FCN_STRATEGY_ID, productId)
    {
        CegaGlobalStorage storage cgs = getStorage();
        FCNProduct storage fcnProduct = cgs.fcnProducts[productId];
        DepositQueue storage depositQueue = cgs.depositQueues[productId];
        require(
            depositQueue.queuedDepositsTotalAmount +
                fcnProduct.sumVaultUnderlyingAmounts <=
                maxUnderlyingAmountLimit,
            Errors.VALUE_TOO_SMALL
        );
        fcnProduct.maxUnderlyingAmountLimit = maxUnderlyingAmountLimit;
        emit FCNMaxUnderlyingAmountLimitUpdated(
            productId,
            maxUnderlyingAmountLimit
        );
    }

    /**
     * @notice Sets dispute period for the product
     * @param productId ID of the product
     * @param disputePeriodInHours Dispute period in hours
     */
    function fcnSetDisputePeriodInHours(
        uint32 productId,
        uint8 disputePeriodInHours
    )
        external
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidProductStrategy(FCN_STRATEGY_ID, productId)
    {
        require(disputePeriodInHours != 0, Errors.VALUE_IS_ZERO);

        FCNProduct storage fcnProduct = getStorage().fcnProducts[productId];
        fcnProduct.disputePeriodInHours = disputePeriodInHours;

        emit FCNDisputePeriodInHoursUpdated(productId, disputePeriodInHours);
    }

    /**
     * @notice Sets dispute grace period for the product
     * @param productId ID of the product
     * @param disputeGraceDelayInHours Dispute period in hours
     */
    function fcnSetDisputeGraceDelayInHours(
        uint32 productId,
        uint8 disputeGraceDelayInHours
    )
        external
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidProductStrategy(FCN_STRATEGY_ID, productId)
    {
        FCNProduct storage fcnProduct = getStorage().fcnProducts[productId];
        fcnProduct.disputeGraceDelayInHours = disputeGraceDelayInHours;

        emit FCNDisputeGraceDelayInHoursUpdated(
            productId,
            disputeGraceDelayInHours
        );
    }
}
