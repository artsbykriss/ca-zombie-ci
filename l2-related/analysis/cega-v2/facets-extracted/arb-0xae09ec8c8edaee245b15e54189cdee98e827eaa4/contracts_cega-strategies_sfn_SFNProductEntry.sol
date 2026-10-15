// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import {
    CegaGlobalStorage,
    SFN_STRATEGY_ID,
    VaultCreationParams,
    Vault,
    ProcessQueueParams,
    RotationStrategyParams
} from "../../Structs.sol";
import { Errors } from "../../utils/Errors.sol";
import { EntryBase } from "../common/EntryBase.sol";
import { IAddressManager } from "../../aux/interfaces/IAddressManager.sol";
import { ITreasury } from "../../aux/interfaces/ITreasury.sol";
import {
    ICegaVaultFactory
} from "../../vaults/interfaces/ICegaVaultFactory.sol";
import { ProductLogic } from "../common/lib/ProductLogic.sol";

import {
    SFNProductCreationParams,
    SFNProduct,
    SFNOptionType
} from "./SFNStructs.sol";
import { SFNProductLogic } from "./lib/SFNProductLogic.sol";
import { ISFNProductEntry } from "./interfaces/ISFNProductEntry.sol";
import { ISFNEvents } from "./interfaces/ISFNEvents.sol";

contract SFNProductEntry is ISFNProductEntry, ISFNEvents, EntryBase {
    // CONSTANTS

    uint128 internal constant BPS_DECIMALS = 1e4;

    // IMMUTABLES

    ITreasury private immutable treasury;

    ICegaVaultFactory private immutable cegaVaultFactory;

    // CONSTRUCTOR

    constructor(
        IAddressManager _addressManager,
        ITreasury _treasury,
        ICegaVaultFactory _cegaVaultFactory
    ) EntryBase(_addressManager) {
        treasury = _treasury;
        cegaVaultFactory = _cegaVaultFactory;
    }

    // FUNCTIONS

    function sfnCreateProduct(
        SFNProductCreationParams calldata creationParams
    ) external onlyTraderAdmin onlyIfNotPaused returns (uint32) {
        CegaGlobalStorage storage cgs = getStorage();
        require(
            creationParams.minDepositAmount > 0,
            Errors.INVALID_MIN_DEPOSIT_AMOUNT
        );
        require(
            creationParams.minDepositAmount <=
                creationParams.maxUnderlyingAmountLimit,
            Errors.INVALID_MIN_DEPOSIT_AMOUNT
        );
        require(
            creationParams.minWithdrawalAmount > 0,
            Errors.INVALID_MIN_WITHDRAWAL_AMOUNT
        );
        require(creationParams.leverage != 0, Errors.VALUE_IS_ZERO);
        require(creationParams.tenorInSeconds != 0, Errors.VALUE_IS_ZERO);
        require(creationParams.hoursToStartLateFees != 0, Errors.VALUE_IS_ZERO);
        require(
            creationParams.hoursToStartAuctionDefault != 0,
            Errors.VALUE_IS_ZERO
        );
        require(
            creationParams.hoursToStartSettlementDefault != 0,
            Errors.VALUE_IS_ZERO
        );
        require(creationParams.disputePeriodInHours != 0, Errors.VALUE_IS_ZERO);
        require(
            creationParams.trackedAssets.length != 0,
            Errors.INVALID_ARRAY_LENGTH
        );
        require(
            creationParams.observationIntervalInSeconds != 0,
            Errors.VALUE_IS_ZERO
        );
        if (creationParams.optionType == SFNOptionType.Bull) {
            require(
                creationParams.knockOutBps >= creationParams.strikeBps,
                Errors.VALUE_TOO_SMALL
            );
        } else {
            require(
                creationParams.knockOutBps <= creationParams.strikeBps,
                Errors.VALUE_TOO_LARGE
            );
        }
        require(
            creationParams.minAprRatioBps >=
                creationParams.guaranteedAprRatioBps,
            Errors.VALUE_TOO_SMALL
        );
        require(
            creationParams.rebateAprRatioBps >=
                creationParams.guaranteedAprRatioBps,
            Errors.VALUE_TOO_SMALL
        );

        address[] memory vaultAddresses;
        uint32 newId = ++cgs.productIdCounter;

        cgs.sfnProducts[newId] = SFNProduct({
            minDepositAmount: creationParams.minDepositAmount,
            minWithdrawalAmount: creationParams.minWithdrawalAmount,
            maxUnderlyingAmountLimit: creationParams.maxUnderlyingAmountLimit,
            sumVaultUnderlyingAmounts: 0,
            underlyingAsset: creationParams.underlyingAsset,
            leverage: creationParams.leverage,
            tenorInSeconds: creationParams.tenorInSeconds,
            hoursToStartLateFees: creationParams.hoursToStartLateFees,
            hoursToStartAuctionDefault: creationParams
                .hoursToStartAuctionDefault,
            hoursToStartSettlementDefault: creationParams
                .hoursToStartSettlementDefault,
            disputePeriodInHours: creationParams.disputePeriodInHours,
            disputeGraceDelayInHours: creationParams.disputeGraceDelayInHours,
            lateFeeBps: creationParams.lateFeeBps,
            isDepositQueueOpen: false,
            trackedAssets: creationParams.trackedAssets,
            observationIntervalInSeconds: creationParams
                .observationIntervalInSeconds,
            payoffType: creationParams.payoffType,
            knockOutBps: creationParams.knockOutBps,
            strikeBps: creationParams.strikeBps,
            optionType: creationParams.optionType,
            guaranteedAprRatioBps: creationParams.guaranteedAprRatioBps,
            minAprRatioBps: creationParams.minAprRatioBps,
            rebateAprRatioBps: creationParams.rebateAprRatioBps,
            vaults: vaultAddresses
        });
        cgs.strategyOfProduct[newId] = SFN_STRATEGY_ID;
        cgs.productMetadata[newId].tradeWinnerNftImage = creationParams
            .tradeWinnerNftImage;
        cgs.productMetadata[newId].name = creationParams.name;

        emit SFNProductCreated(newId);

        return newId;
    }

    function sfnCreateVault(
        uint32 productId,
        VaultCreationParams calldata creationParams
    )
        external
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidProductStrategy(SFN_STRATEGY_ID, productId)
        returns (address vaultAddress)
    {
        CegaGlobalStorage storage cgs = getStorage();
        require(
            cgs.strategyOfProduct[productId] == SFN_STRATEGY_ID,
            Errors.WRONG_STRATEGY
        );

        address newVaultAddress = cegaVaultFactory.deployCegaVault(
            creationParams.tokenName,
            creationParams.tokenSymbol
        );

        SFNProduct storage product = cgs.sfnProducts[productId];
        product.vaults.push(newVaultAddress);

        Vault storage vault = cgs.vaults[newVaultAddress];
        vault.productId = productId;
        vault.yieldFeeBps = creationParams.yieldFeeBps;
        vault.managementFeeBps = creationParams.managementFeeBps;

        emit SFNVaultCreated(productId, newVaultAddress, creationParams);

        return newVaultAddress;
    }

    function sfnAddToDepositQueue(
        uint32 productId,
        uint128 amount,
        address receiver
    )
        external
        payable
        onlyIfNotPaused
        onlyValidProductStrategy(SFN_STRATEGY_ID, productId)
    {
        CegaGlobalStorage storage cgs = getStorage();
        RotationStrategyParams[] memory rotationStrategyParams;
        SFNProductLogic.addToDepositQueue(
            cgs,
            addressManager,
            address(treasury),
            productId,
            amount,
            receiver,
            rotationStrategyParams
        );
    }

    function sfnRemoveFromDepositQueue(
        uint32 productId,
        uint128 amount
    )
        external
        onlyIfNotPaused
        onlyValidProductStrategy(SFN_STRATEGY_ID, productId)
    {
        CegaGlobalStorage storage cgs = getStorage();
        SFNProductLogic.removeFromDepositQueue(
            cgs,
            treasury,
            productId,
            amount
        );
    }

    function sfnProcessDepositQueue(
        address vaultAddress,
        uint256 maxProcessCount
    )
        external
        onlyTraderAdmin
        nonReentrant
        onlyValidVaultStrategy(SFN_STRATEGY_ID, vaultAddress)
        onlyIfNotPaused
    {
        CegaGlobalStorage storage cgs = getStorage();
        uint32 productId = cgs.vaults[vaultAddress].productId;

        SFNProduct storage sfnProduct = cgs.sfnProducts[productId];

        ProductLogic.processDepositQueue(
            cgs,
            ProcessQueueParams({
                productId: productId,
                vaultAddress: vaultAddress,
                depositAsset: sfnProduct.underlyingAsset,
                maxProcessCount: maxProcessCount,
                sumVaultUnderlyingAmounts: sfnProduct.sumVaultUnderlyingAmounts
            }),
            SFNProductLogic.sfnProcessDepositQueueHook
        );
    }

    function sfnAddToWithdrawalQueue(
        address vaultAddress,
        uint128 sharesAmount,
        uint32 nextProductId
    )
        external
        nonReentrant
        onlyValidVaultStrategy(SFN_STRATEGY_ID, vaultAddress)
        onlyIfNotPaused
    {
        CegaGlobalStorage storage cgs = getStorage();
        SFNProductLogic.addToWithdrawalQueue(
            cgs,
            addressManager,
            treasury,
            vaultAddress,
            sharesAmount,
            nextProductId,
            false
        );
    }

    function sfnAddToWithdrawalQueueWithProxy(
        address vaultAddress,
        uint128 sharesAmount
    )
        external
        nonReentrant
        onlyValidVaultStrategy(SFN_STRATEGY_ID, vaultAddress)
        onlyIfNotPaused
    {
        CegaGlobalStorage storage cgs = getStorage();
        SFNProductLogic.addToWithdrawalQueue(
            cgs,
            addressManager,
            treasury,
            vaultAddress,
            sharesAmount,
            0,
            true
        );
    }

    function sfnProcessWithdrawalQueue(
        address vaultAddress,
        uint256 maxProcessCount
    )
        external
        onlyTraderAdmin
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultStrategy(SFN_STRATEGY_ID, vaultAddress)
    {
        CegaGlobalStorage storage cgs = getStorage();
        Vault storage vaultData = cgs.vaults[vaultAddress];
        SFNProduct storage sfnProduct = cgs.sfnProducts[vaultData.productId];
        address settlementAsset = sfnProduct.underlyingAsset;

        ProductLogic.processWithdrawalQueue(
            cgs,
            treasury,
            addressManager,
            vaultAddress,
            maxProcessCount,
            settlementAsset,
            SFNProductLogic.sfnAddToWithdrawalQueueHook
        );
    }
}
