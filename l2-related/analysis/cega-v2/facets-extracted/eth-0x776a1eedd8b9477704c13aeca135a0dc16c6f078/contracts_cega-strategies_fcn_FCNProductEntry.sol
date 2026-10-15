// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { CegaStorage } from "../../storage/CegaStorage.sol";
import {
    CegaGlobalStorage,
    DepositQueue,
    WithdrawalQueue,
    Withdrawer,
    Vault,
    VaultStatus,
    FCN_STRATEGY_ID,
    ProductMetadata,
    RemoveFromDepositQueueParams,
    ProcessQueueParams,
    RotationStrategyParams
} from "../../Structs.sol";
import {
    FCNProductCreationParams,
    FCNProduct,
    FCNVault,
    FCNVaultCreationParams,
    FCNOptionBarrier,
    FCNVaultBarrierData
} from "./FCNStructs.sol";
import { ITreasury } from "../../aux/interfaces/ITreasury.sol";

import { IFCNProductEntry } from "./interfaces/IFCNProductEntry.sol";
import { IFCNEvents } from "./interfaces/IFCNEvents.sol";
import { IAddressManager } from "../../aux/interfaces/IAddressManager.sol";
import { EntryBase } from "../common/EntryBase.sol";
import { Errors } from "../../utils/Errors.sol";
import {
    ICegaVaultFactory
} from "../../vaults/interfaces/ICegaVaultFactory.sol";
import { ProductLogic } from "../common/lib/ProductLogic.sol";
import { VaultLogic } from "../common/lib/VaultLogic.sol";
import { FCNProductLogic } from "./lib/FCNProductLogic.sol";
import { FCNVaultLogic } from "./lib/FCNVaultLogic.sol";
import { IOracleEntry } from "../../oracle-entry/interfaces/IOracleEntry.sol";

contract FCNProductEntry is IFCNProductEntry, IFCNEvents, EntryBase {
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

    /**
     * @notice Created new FCN product
     * @param creationParams New product params as `FCNProductCreationParams` struct
     * @return _ New product ID
     */
    function fcnCreateProduct(
        FCNProductCreationParams calldata creationParams
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
            creationParams.observationIntervalInSeconds != 0,
            Errors.VALUE_IS_ZERO
        );

        address[] memory vaultAddresses;
        uint32 newId = ++cgs.productIdCounter;

        cgs.fcnProducts[newId] = FCNProduct({
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
            vaults: vaultAddresses,
            optionBarriers: creationParams.optionBarriers,
            isBondOption: creationParams.isBondOption,
            observationIntervalInSeconds: creationParams
                .observationIntervalInSeconds
        });
        cgs.strategyOfProduct[newId] = FCN_STRATEGY_ID;
        cgs.productMetadata[newId].tradeWinnerNftImage = creationParams
            .tradeWinnerNftImage;
        cgs.productMetadata[newId].name = creationParams.name;

        emit FCNProductCreated(newId);

        return newId;
    }

    /**
     * @notice Creates new FCN vault
     * @param productId ID of the product for which vault is being created
     * @param creationParams Vault creation params
     * @return vaultAddress New vault address
     */
    function fcnCreateVault(
        uint32 productId,
        FCNVaultCreationParams calldata creationParams
    )
        external
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidProductStrategy(FCN_STRATEGY_ID, productId)
        returns (address vaultAddress)
    {
        CegaGlobalStorage storage cgs = getStorage();
        require(
            cgs.strategyOfProduct[productId] == FCN_STRATEGY_ID,
            Errors.WRONG_STRATEGY
        );

        address newVaultAddress = cegaVaultFactory.deployCegaVault(
            creationParams.tokenName,
            creationParams.tokenSymbol
        );

        FCNProduct storage product = cgs.fcnProducts[productId];
        product.vaults.push(newVaultAddress);

        Vault storage vault = cgs.vaults[newVaultAddress];
        vault.productId = productId;
        vault.yieldFeeBps = creationParams.yieldFeeBps;
        vault.managementFeeBps = creationParams.managementFeeBps;

        emit FCNVaultCreated(productId, newVaultAddress, creationParams);

        return newVaultAddress;
    }

    function fcnAddToDepositQueue(
        uint32 productId,
        uint128 amount,
        address receiver
    )
        external
        payable
        onlyIfNotPaused
        onlyValidProductStrategy(FCN_STRATEGY_ID, productId)
    {
        CegaGlobalStorage storage cgs = getStorage();
        RotationStrategyParams[] memory rotationStrategyParams;
        FCNProductLogic.addToDepositQueue(
            cgs,
            addressManager,
            address(treasury),
            productId,
            amount,
            receiver,
            rotationStrategyParams
        );
    }

    function fcnRemoveFromDepositQueue(
        uint32 productId,
        uint128 amount
    )
        external
        onlyIfNotPaused
        onlyValidProductStrategy(FCN_STRATEGY_ID, productId)
    {
        CegaGlobalStorage storage cgs = getStorage();
        FCNProductLogic.removeFromDepositQueue(
            cgs,
            treasury,
            productId,
            amount
        );
    }

    function fcnProcessDepositQueue(
        address vaultAddress,
        uint256 maxProcessCount
    )
        external
        onlyTraderAdmin
        nonReentrant
        onlyValidVaultStrategy(FCN_STRATEGY_ID, vaultAddress)
        onlyIfNotPaused
    {
        CegaGlobalStorage storage cgs = getStorage();
        uint32 productId = cgs.vaults[vaultAddress].productId;

        FCNProduct storage fcnProduct = cgs.fcnProducts[productId];

        ProductLogic.processDepositQueue(
            cgs,
            ProcessQueueParams({
                productId: productId,
                vaultAddress: vaultAddress,
                depositAsset: fcnProduct.underlyingAsset,
                maxProcessCount: maxProcessCount,
                sumVaultUnderlyingAmounts: fcnProduct.sumVaultUnderlyingAmounts
            }),
            FCNProductLogic.fcnProcessDepositQueueHook
        );
    }

    function fcnAddToWithdrawalQueue(
        address vaultAddress,
        uint128 sharesAmount,
        uint32 nextProductId
    )
        external
        nonReentrant
        onlyValidVaultStrategy(FCN_STRATEGY_ID, vaultAddress)
        onlyIfNotPaused
    {
        CegaGlobalStorage storage cgs = getStorage();
        FCNProductLogic.addToWithdrawalQueue(
            cgs,
            addressManager,
            treasury,
            vaultAddress,
            sharesAmount,
            nextProductId,
            false
        );
    }

    function fcnAddToWithdrawalQueueWithProxy(
        address vaultAddress,
        uint128 sharesAmount
    )
        external
        nonReentrant
        onlyValidVaultStrategy(FCN_STRATEGY_ID, vaultAddress)
        onlyIfNotPaused
    {
        CegaGlobalStorage storage cgs = getStorage();
        FCNProductLogic.addToWithdrawalQueue(
            cgs,
            addressManager,
            treasury,
            vaultAddress,
            sharesAmount,
            0,
            true
        );
    }

    function fcnProcessWithdrawalQueue(
        address vaultAddress,
        uint256 maxProcessCount
    )
        external
        onlyTraderAdmin
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultStrategy(FCN_STRATEGY_ID, vaultAddress)
    {
        CegaGlobalStorage storage cgs = getStorage();
        Vault storage vaultData = cgs.vaults[vaultAddress];
        FCNProduct storage fcnProduct = cgs.fcnProducts[vaultData.productId];
        address settlementAsset = fcnProduct.underlyingAsset;

        ProductLogic.processWithdrawalQueue(
            cgs,
            treasury,
            addressManager,
            vaultAddress,
            maxProcessCount,
            settlementAsset,
            FCNProductLogic.fcnAddToWithdrawalQueueHook
        );
    }
}
