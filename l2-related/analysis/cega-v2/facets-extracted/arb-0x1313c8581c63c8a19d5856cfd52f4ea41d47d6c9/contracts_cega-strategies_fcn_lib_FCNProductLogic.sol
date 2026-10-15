// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import {
    FCNProductCreationParams,
    FCNProduct,
    FCNVaultCreationParams,
    FCNOptionBarrier
} from "../FCNStructs.sol";
import {
    CegaGlobalStorage,
    Vault,
    AddToDepositQueueParams,
    RemoveFromDepositQueueParams,
    RotationStrategyParams
} from "../../../Structs.sol";
import { ProductLogic } from "../../common/lib/ProductLogic.sol";
import { IAddressManager } from "../../../aux/interfaces/IAddressManager.sol";
import { ITreasury } from "../../../aux/interfaces/ITreasury.sol";

library FCNProductLogic {
    /**
     * @dev Retrieves the deposit asset for a given FCN product.
     * @param fcnProduct The FCN product.
     * @return The address of the deposit asset.
     */
    function fcnGetProductDepositAsset(
        FCNProduct storage fcnProduct
    ) internal view returns (address) {
        return fcnProduct.underlyingAsset;
    }

    function fcnProcessDepositQueueHook(
        CegaGlobalStorage storage cgs,
        uint32 productId,
        uint128 totalDepositsAmount
    ) internal {
        cgs
            .fcnProducts[productId]
            .sumVaultUnderlyingAmounts += totalDepositsAmount;
    }

    function fcnAddToWithdrawalQueueHook(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        uint128 assetAmount
    ) internal {
        cgs
            .fcnProducts[cgs.vaults[vaultAddress].productId]
            .sumVaultUnderlyingAmounts -= assetAmount;
    }

    function addToDepositQueue(
        CegaGlobalStorage storage cgs,
        IAddressManager addressManager,
        address treasury,
        uint32 productId,
        uint128 amount,
        address receiver,
        RotationStrategyParams[] memory rotationStrategyParams
    ) internal {
        FCNProduct storage fcnProduct = cgs.fcnProducts[productId];
        ProductLogic.addToDepositQueue(
            cgs,
            addressManager,
            treasury,
            AddToDepositQueueParams({
                productId: productId,
                amount: amount,
                receiver: receiver,
                depositAsset: fcnProduct.underlyingAsset,
                isDepositQueueOpen: fcnProduct.isDepositQueueOpen,
                minDepositAmount: fcnProduct.minDepositAmount,
                sumVaultUnderlyingAmounts: fcnProduct.sumVaultUnderlyingAmounts,
                maxUnderlyingAmountLimit: fcnProduct.maxUnderlyingAmountLimit,
                rotationStrategyParams: rotationStrategyParams
            })
        );
    }

    function removeFromDepositQueue(
        CegaGlobalStorage storage cgs,
        ITreasury treasury,
        uint32 productId,
        uint128 amount
    ) internal {
        FCNProduct storage fcnProduct = cgs.fcnProducts[productId];
        ProductLogic.removeFromDepositQueue(
            cgs,
            treasury,
            RemoveFromDepositQueueParams({
                productId: productId,
                amount: amount,
                depositor: msg.sender,
                depositAsset: fcnProduct.underlyingAsset,
                minDepositAmount: fcnProduct.minDepositAmount
            })
        );
    }

    function addToWithdrawalQueue(
        CegaGlobalStorage storage cgs,
        IAddressManager addressManager,
        ITreasury treasury,
        address vaultAddress,
        uint128 sharesAmount,
        uint32 nextProductId,
        bool useProxy
    ) internal {
        Vault storage vaultData = cgs.vaults[vaultAddress];
        FCNProduct storage fcnProduct = cgs.fcnProducts[vaultData.productId];
        ProductLogic.withdrawOrAddToWithdrawalQueue(
            cgs,
            treasury,
            addressManager,
            vaultAddress,
            sharesAmount,
            nextProductId,
            useProxy,
            fcnProduct.minWithdrawalAmount,
            fcnProduct.underlyingAsset,
            FCNProductLogic.fcnAddToWithdrawalQueueHook
        );
    }
}
