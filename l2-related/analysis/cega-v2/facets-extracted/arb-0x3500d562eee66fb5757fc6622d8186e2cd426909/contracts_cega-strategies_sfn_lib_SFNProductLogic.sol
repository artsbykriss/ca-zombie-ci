// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { SFNProduct } from "../SFNStructs.sol";
import {
    CegaGlobalStorage,
    Vault,
    AddToDepositQueueParams,
    RemoveFromDepositQueueParams
} from "../../../Structs.sol";
import { ProductLogic } from "../../common/lib/ProductLogic.sol";
import { IAddressManager } from "../../../aux/interfaces/IAddressManager.sol";
import { ITreasury } from "../../../aux/interfaces/ITreasury.sol";

library SFNProductLogic {
    function sfnProcessDepositQueueHook(
        CegaGlobalStorage storage cgs,
        uint32 productId,
        uint128 totalDepositsAmount
    ) internal {
        cgs
            .sfnProducts[productId]
            .sumVaultUnderlyingAmounts += totalDepositsAmount;
    }

    function sfnAddToWithdrawalQueueHook(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        uint128 assetAmount
    ) internal {
        cgs
            .sfnProducts[cgs.vaults[vaultAddress].productId]
            .sumVaultUnderlyingAmounts -= assetAmount;
    }

    function addToDepositQueue(
        CegaGlobalStorage storage cgs,
        address treasury,
        uint32 productId,
        uint128 amount,
        address receiver
    ) internal {
        SFNProduct storage sfnProduct = cgs.sfnProducts[productId];
        ProductLogic.addToDepositQueue(
            cgs,
            treasury,
            AddToDepositQueueParams({
                productId: productId,
                amount: amount,
                receiver: receiver,
                depositAsset: sfnProduct.underlyingAsset,
                isDepositQueueOpen: sfnProduct.isDepositQueueOpen,
                minDepositAmount: sfnProduct.minDepositAmount,
                sumVaultUnderlyingAmounts: sfnProduct.sumVaultUnderlyingAmounts,
                maxUnderlyingAmountLimit: sfnProduct.maxUnderlyingAmountLimit
            })
        );
    }

    function removeFromDepositQueue(
        CegaGlobalStorage storage cgs,
        ITreasury treasury,
        uint32 productId,
        uint128 amount
    ) internal {
        SFNProduct storage sfnProduct = cgs.sfnProducts[productId];
        ProductLogic.removeFromDepositQueue(
            cgs,
            treasury,
            RemoveFromDepositQueueParams({
                productId: productId,
                amount: amount,
                depositor: msg.sender,
                depositAsset: sfnProduct.underlyingAsset,
                minDepositAmount: sfnProduct.minDepositAmount
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
        SFNProduct storage sfnProduct = cgs.sfnProducts[vaultData.productId];
        ProductLogic.withdrawOrAddToWithdrawalQueue(
            cgs,
            treasury,
            addressManager,
            vaultAddress,
            sharesAmount,
            nextProductId,
            useProxy,
            sfnProduct.minWithdrawalAmount,
            sfnProduct.underlyingAsset,
            sfnAddToWithdrawalQueueHook
        );
    }

    /**
     * @dev Retrieves the deposit asset for a given FCN product.
     * @param sfnProduct The FCN product.
     * @return The address of the deposit asset.
     */
    function sfnGetProductDepositAsset(
        SFNProduct storage sfnProduct
    ) internal view returns (address) {
        return sfnProduct.underlyingAsset;
    }
}
