// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { EntryBase } from "./EntryBase.sol";
import { IProductEntry } from "./interfaces/IProductEntry.sol";
import {
    Vault,
    DCS_STRATEGY_ID,
    FCN_STRATEGY_ID,
    SFN_STRATEGY_ID,
    RotationStrategyParams
} from "../../Structs.sol";
import { CegaStorage, CegaGlobalStorage } from "../../storage/CegaStorage.sol";
import { Errors } from "../../utils/Errors.sol";
import { ProductLogic } from "./lib/ProductLogic.sol";
import { DCSLogic } from "../dcs/lib/DCSLogic.sol";
import { FCNProductLogic } from "../fcn/lib/FCNProductLogic.sol";
import { SFNProductLogic } from "../sfn/lib/SFNProductLogic.sol";
import { ITreasury } from "../../aux/interfaces/ITreasury.sol";
import { IAddressManager } from "../../aux/interfaces/IAddressManager.sol";

contract ProductEntry is IProductEntry, CegaStorage, EntryBase {
    // IMMUTABLE

    ITreasury internal immutable treasury;

    // CONSTRUCTOR

    constructor(
        IAddressManager _addressManager,
        ITreasury _treasury
    ) EntryBase(_addressManager) {
        treasury = _treasury;
    }

    // FUNCTIONS

    function setUserRotationStrategies(
        RotationStrategyParams[] calldata rotationStrategyParams,
        address[] calldata vaultAddresses
    ) external onlyIfNotPaused {
        CegaGlobalStorage storage cgs = getStorage();
        for (uint256 i = 0; i < rotationStrategyParams.length; i++) {
            ProductLogic.setUserRotationStrategy(
                cgs,
                msg.sender,
                rotationStrategyParams[i]
            );
        }

        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            ProductLogic.addUserIntoVaultRotationList(
                cgs,
                msg.sender,
                vaultAddresses[i]
            );
        }
    }

    function addToDepositQueue(
        uint32 productId,
        uint128 amount,
        address receiver
    ) external payable onlyIfNotPaused {
        RotationStrategyParams[] memory rotationStrategyParams;
        _addToDepositQueue(productId, amount, receiver, rotationStrategyParams);
    }

    function addToDepositQueueAndSetRotationStrategies(
        uint32 productId,
        uint128 amount,
        address receiver,
        RotationStrategyParams[] calldata rotationStrategyParams
    ) external payable onlyIfNotPaused {
        _addToDepositQueue(productId, amount, receiver, rotationStrategyParams);
    }

    function removeFromDepositQueue(
        uint32 productId,
        uint128 amount
    ) external onlyIfNotPaused {
        CegaGlobalStorage storage cgs = getStorage();

        uint32 strategy = cgs.strategyOfProduct[productId];
        if (strategy == DCS_STRATEGY_ID) {
            DCSLogic.removeFromDepositQueue(cgs, treasury, productId, amount);
        } else if (strategy == FCN_STRATEGY_ID) {
            FCNProductLogic.removeFromDepositQueue(
                cgs,
                treasury,
                productId,
                amount
            );
        } else if (strategy == SFN_STRATEGY_ID) {
            SFNProductLogic.removeFromDepositQueue(
                cgs,
                treasury,
                productId,
                amount
            );
        } else {
            revert(Errors.WRONG_STRATEGY);
        }
    }

    function addToWithdrawalQueue(
        address vaultAddress,
        uint128 sharesAmount,
        uint32 nextProductId
    ) external onlyIfNotPaused {
        CegaGlobalStorage storage cgs = getStorage();

        Vault storage vault = cgs.vaults[vaultAddress];
        uint32 strategy = cgs.strategyOfProduct[vault.productId];
        if (strategy == DCS_STRATEGY_ID) {
            DCSLogic.addToWithdrawalQueue(
                cgs,
                addressManager,
                treasury,
                vaultAddress,
                sharesAmount,
                nextProductId,
                false
            );
        } else if (strategy == FCN_STRATEGY_ID) {
            FCNProductLogic.addToWithdrawalQueue(
                cgs,
                addressManager,
                treasury,
                vaultAddress,
                sharesAmount,
                nextProductId,
                false
            );
        } else if (strategy == SFN_STRATEGY_ID) {
            SFNProductLogic.addToWithdrawalQueue(
                cgs,
                addressManager,
                treasury,
                vaultAddress,
                sharesAmount,
                nextProductId,
                false
            );
        } else {
            revert(Errors.WRONG_STRATEGY);
        }
    }

    function addToWithdrawalQueueWithProxy(
        address vaultAddress,
        uint128 sharesAmount
    ) external onlyIfNotPaused {
        CegaGlobalStorage storage cgs = getStorage();

        Vault storage vault = cgs.vaults[vaultAddress];
        uint32 strategy = cgs.strategyOfProduct[vault.productId];
        if (strategy == DCS_STRATEGY_ID) {
            DCSLogic.addToWithdrawalQueue(
                cgs,
                addressManager,
                treasury,
                vaultAddress,
                sharesAmount,
                0,
                true
            );
        } else if (strategy == FCN_STRATEGY_ID) {
            FCNProductLogic.addToWithdrawalQueue(
                cgs,
                addressManager,
                treasury,
                vaultAddress,
                sharesAmount,
                0,
                true
            );
        } else if (strategy == SFN_STRATEGY_ID) {
            SFNProductLogic.addToWithdrawalQueue(
                cgs,
                addressManager,
                treasury,
                vaultAddress,
                sharesAmount,
                0,
                true
            );
        } else {
            revert(Errors.WRONG_STRATEGY);
        }
    }

    // INTERNAL FUNCTIONS

    function _addToDepositQueue(
        uint32 productId,
        uint128 amount,
        address receiver,
        RotationStrategyParams[] memory rotationStrategyParams
    ) internal {
        CegaGlobalStorage storage cgs = getStorage();

        uint32 strategy = cgs.strategyOfProduct[productId];

        if (strategy == DCS_STRATEGY_ID) {
            DCSLogic.addToDepositQueue(
                cgs,
                addressManager,
                address(treasury),
                productId,
                amount,
                receiver,
                rotationStrategyParams
            );
        } else if (strategy == FCN_STRATEGY_ID) {
            FCNProductLogic.addToDepositQueue(
                cgs,
                addressManager,
                address(treasury),
                productId,
                amount,
                receiver,
                rotationStrategyParams
            );
        } else if (strategy == SFN_STRATEGY_ID) {
            SFNProductLogic.addToDepositQueue(
                cgs,
                addressManager,
                address(treasury),
                productId,
                amount,
                receiver,
                rotationStrategyParams
            );
        } else {
            revert(Errors.WRONG_STRATEGY);
        }
    }
}
