// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {
    IERC20Metadata,
    IERC20
} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { CegaStorage } from "../../storage/CegaStorage.sol";
import {
    CegaGlobalStorage,
    DepositQueue,
    WithdrawalQueue,
    Withdrawer,
    Vault,
    VaultStatus,
    DCS_STRATEGY_ID,
    ProductMetadata,
    ProcessQueueParams,
    RotationStrategyParams
} from "../../Structs.sol";
import {
    DCSOptionType,
    DCSProductCreationParams,
    DCSProduct,
    DCSVault
} from "./DCSStructs.sol";
import { ProductLogic } from "../common/lib/ProductLogic.sol";

import { Transfers } from "../../utils/Transfers.sol";
import { DCSVaultLogic } from "./lib/DCSVaultLogic.sol";
import { DCSLogic } from "./lib/DCSLogic.sol";
import { IDCSEvents } from "./interfaces/IDCSEvents.sol";
import { IDCSProductEntry } from "./interfaces/IDCSProductEntry.sol";
import { ICegaVault } from "../../vaults/interfaces/ICegaVault.sol";
import { ITreasury } from "../../aux/interfaces/ITreasury.sol";
import { IAddressManager } from "../../aux/interfaces/IAddressManager.sol";
import { IACLManager } from "../../aux/interfaces/IACLManager.sol";
import { IOracleEntry } from "../../oracle-entry/interfaces/IOracleEntry.sol";
import { Errors } from "../../utils/Errors.sol";
import { EntryBase } from "../common/EntryBase.sol";

contract DCSProductEntry is EntryBase, IDCSEvents, IDCSProductEntry {
    using Transfers for address;

    // CONSTANTS
    uint128 private constant BPS_DECIMALS = 1e4;

    ITreasury private immutable treasury;

    // CONSTRUCTOR

    constructor(
        IAddressManager _addressManager,
        ITreasury _treasury
    ) EntryBase(_addressManager) {
        treasury = _treasury;
    }

    // MUTATIVE FUNCTIONS

    function dcsCreateProduct(
        DCSProductCreationParams calldata creationParams
    ) external onlyTraderAdmin onlyIfNotPaused returns (uint32) {
        CegaGlobalStorage storage cgs = getStorage();
        require(
            creationParams.quoteAssetAddress != creationParams.baseAssetAddress,
            Errors.INVALID_QUOTE_OR_BASE_ASSETS
        );
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

        address[] memory vaultAddresses;
        uint32 newId = ++cgs.productIdCounter;

        cgs.dcsProducts[newId] = DCSProduct({
            dcsOptionType: creationParams.dcsOptionType,
            isDepositQueueOpen: false,
            quoteAssetAddress: creationParams.quoteAssetAddress,
            baseAssetAddress: creationParams.baseAssetAddress,
            maxUnderlyingAmountLimit: creationParams.maxUnderlyingAmountLimit,
            minDepositAmount: creationParams.minDepositAmount,
            minWithdrawalAmount: creationParams.minWithdrawalAmount,
            sumVaultUnderlyingAmounts: 0,
            vaults: vaultAddresses,
            hoursToStartLateFees: creationParams.hoursToStartLateFees,
            hoursToStartAuctionDefault: creationParams
                .hoursToStartAuctionDefault,
            hoursToStartSettlementDefault: creationParams
                .hoursToStartSettlementDefault,
            lateFeeBps: creationParams.lateFeeBps,
            strikeBarrierBps: creationParams.strikeBarrierBps,
            tenorInSeconds: creationParams.tenorInSeconds,
            disputePeriodInHours: creationParams.disputePeriodInHours,
            disputeGraceDelayInHours: creationParams.disputeGraceDelayInHours
        });
        cgs.strategyOfProduct[newId] = DCS_STRATEGY_ID;

        cgs.productMetadata[newId].tradeWinnerNftImage = creationParams
            .tradeWinnerNftImage;
        cgs.productMetadata[newId].name = creationParams.name;
        emit DCSProductCreated(newId);

        return newId;
    }

    function dcsAddToDepositQueue(
        uint32 productId,
        uint128 amount,
        address receiver
    )
        external
        payable
        onlyIfNotPaused
        onlyValidProductStrategy(DCS_STRATEGY_ID, productId)
    {
        CegaGlobalStorage storage cgs = getStorage();
        RotationStrategyParams[] memory rotationStrategyParams;
        DCSLogic.addToDepositQueue(
            cgs,
            addressManager,
            address(treasury),
            productId,
            amount,
            receiver,
            rotationStrategyParams
        );
    }

    function dcsAddToDepositQueueAndSetRotationStrategies(
        uint32 productId,
        uint128 amount,
        address receiver,
        RotationStrategyParams[] memory rotationStrategyParams
    )
        external
        payable
        onlyIfNotPaused
        onlyValidProductStrategy(DCS_STRATEGY_ID, productId)
    {
        CegaGlobalStorage storage cgs = getStorage();
        DCSLogic.addToDepositQueue(
            cgs,
            addressManager,
            address(treasury),
            productId,
            amount,
            receiver,
            rotationStrategyParams
        );
    }

    function dcsRemoveFromDepositQueue(
        uint32 productId,
        uint128 amount
    )
        external
        onlyIfNotPaused
        onlyValidProductStrategy(DCS_STRATEGY_ID, productId)
    {
        CegaGlobalStorage storage cgs = getStorage();
        DCSLogic.removeFromDepositQueue(cgs, treasury, productId, amount);
    }

    function dcsProcessDepositQueue(
        address vaultAddress,
        uint256 maxProcessCount
    )
        external
        onlyTraderAdmin
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultStrategy(DCS_STRATEGY_ID, vaultAddress)
    {
        CegaGlobalStorage storage cgs = getStorage();
        uint32 productId = cgs.vaults[vaultAddress].productId;

        DCSProduct storage dcsProduct = cgs.dcsProducts[productId];

        ProductLogic.processDepositQueue(
            cgs,
            ProcessQueueParams({
                productId: productId,
                vaultAddress: vaultAddress,
                depositAsset: DCSLogic.dcsGetProductDepositAsset(dcsProduct),
                maxProcessCount: maxProcessCount,
                sumVaultUnderlyingAmounts: dcsProduct.sumVaultUnderlyingAmounts
            }),
            DCSLogic.dcsProcessDepositQueueHook
        );
    }

    function dcsAddToWithdrawalQueue(
        address vaultAddress,
        uint128 sharesAmount,
        uint32 nextProductId
    )
        external
        nonReentrant
        onlyValidVaultStrategy(DCS_STRATEGY_ID, vaultAddress)
        onlyIfNotPaused
    {
        CegaGlobalStorage storage cgs = getStorage();
        DCSLogic.addToWithdrawalQueue(
            cgs,
            addressManager,
            treasury,
            vaultAddress,
            sharesAmount,
            nextProductId,
            false
        );
    }

    function dcsAddToWithdrawalQueueWithProxy(
        address vaultAddress,
        uint128 sharesAmount
    )
        external
        nonReentrant
        onlyValidVaultStrategy(DCS_STRATEGY_ID, vaultAddress)
        onlyIfNotPaused
    {
        CegaGlobalStorage storage cgs = getStorage();
        DCSLogic.addToWithdrawalQueue(
            cgs,
            addressManager,
            treasury,
            vaultAddress,
            sharesAmount,
            0,
            true
        );
    }

    function dcsProcessWithdrawalQueue(
        address vaultAddress,
        uint256 maxProcessCount
    )
        external
        onlyTraderAdmin
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultStrategy(DCS_STRATEGY_ID, vaultAddress)
    {
        CegaGlobalStorage storage cgs = getStorage();
        address settlementAsset = DCSLogic.getVaultSettlementAsset(
            cgs,
            vaultAddress
        );
        ProductLogic.processWithdrawalQueue(
            cgs,
            treasury,
            addressManager,
            vaultAddress,
            maxProcessCount,
            settlementAsset,
            DCSLogic.dcsAddToWithdrawalQueueHook
        );
    }

    function dcsCheckTradeExpiry(
        address vaultAddress
    )
        external
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultStrategy(DCS_STRATEGY_ID, vaultAddress)
    {
        CegaGlobalStorage storage cgs = getStorage();
        DCSLogic.checkTradeExpiry(cgs, addressManager, vaultAddress);
    }

    function dcsCheckSettlementDefault(
        address vaultAddress
    )
        external
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultStrategy(DCS_STRATEGY_ID, vaultAddress)
    {
        CegaGlobalStorage storage cgs = getStorage();
        DCSLogic.checkSettlementDefault(cgs, vaultAddress);
    }

    function dcsCollectVaultFees(
        address vaultAddress
    )
        external
        onlyTraderAdmin
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultStrategy(DCS_STRATEGY_ID, vaultAddress)
    {
        CegaGlobalStorage storage cgs = getStorage();

        DCSLogic.collectVaultFees(cgs, treasury, addressManager, vaultAddress);
    }

    function dcsSubmitDispute(
        address vaultAddress
    )
        external
        onlyValidVaultStrategy(DCS_STRATEGY_ID, vaultAddress)
        onlyIfNotPaused
    {
        CegaGlobalStorage storage cgs = getStorage();

        DCSVaultLogic.disputeVault(
            cgs,
            vaultAddress,
            addressManager.getTradeWinnerNFT(),
            IACLManager(addressManager.getACLManager())
        );
    }

    function dcsProcessTradeDispute(
        address vaultAddress,
        uint128 newPrice
    )
        external
        onlyCegaAdmin
        onlyValidVaultStrategy(DCS_STRATEGY_ID, vaultAddress)
        onlyIfNotPaused
    {
        CegaGlobalStorage storage cgs = getStorage();

        DCSVaultLogic.processDispute(cgs, vaultAddress, newPrice);
    }
}
