// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { CegaStorage } from "../../../storage/CegaStorage.sol";
import { Errors } from "../../../utils/Errors.sol";
import { Transfers } from "../../../utils/Transfers.sol";
import {
    CegaGlobalStorage,
    Vault,
    VaultStatus,
    DepositQueue,
    WithdrawalQueue,
    Withdrawer,
    MMNFTMetadata,
    AddToDepositQueueParams,
    RemoveFromDepositQueueParams,
    ProcessQueueParams
} from "../../../Structs.sol";
import { VaultLogic } from "./VaultLogic.sol";
import { ICegaVault } from "../../../vaults/interfaces/ICegaVault.sol";
import { ITreasury } from "../../../aux/interfaces/ITreasury.sol";
import { IAddressManager } from "../../../aux/interfaces/IAddressManager.sol";
import { IWrappingProxy } from "../../../proxies/interfaces/IWrappingProxy.sol";
import {
    IRedepositManager
} from "../../../aux/interfaces/IRedepositManager.sol";
import { ICommonEvents } from "../interfaces/ICommonEvents.sol";

library ProductLogic {
    using Transfers for address;
    using SafeCast for uint256;

    function addToDepositQueue(
        CegaGlobalStorage storage cgs,
        address treasury,
        AddToDepositQueueParams memory params
    ) internal {
        require(params.isDepositQueueOpen, Errors.DEPOSIT_QUEUE_NOT_OPEN);
        require(
            params.amount >= params.minDepositAmount,
            Errors.VALUE_TOO_SMALL
        );

        DepositQueue storage depositQueue = cgs.depositQueues[params.productId];

        uint128 _queuedDepositsTotalAmount = depositQueue
            .queuedDepositsTotalAmount + params.amount;
        depositQueue.queuedDepositsTotalAmount = _queuedDepositsTotalAmount;
        require(
            params.sumVaultUnderlyingAmounts + _queuedDepositsTotalAmount <=
                params.maxUnderlyingAmountLimit,
            Errors.MAX_DEPOSIT_LIMIT_REACHED
        );

        uint128 currentQueuedAmount = depositQueue.amounts[params.receiver];
        if (currentQueuedAmount == 0) {
            bool exists = depositQueue.depositorExists[params.receiver];
            if (!exists) {
                depositQueue.depositors.push(params.receiver);
                depositQueue.depositorExists[params.receiver] = true;
            }
        }
        depositQueue.amounts[params.receiver] =
            currentQueuedAmount +
            params.amount;

        params.depositAsset.receiveTo(treasury, params.amount);

        emit ICommonEvents.DepositQueued(
            params.productId,
            msg.sender,
            params.receiver,
            params.amount
        );
    }

    function removeFromDepositQueue(
        CegaGlobalStorage storage cgs,
        ITreasury treasury,
        RemoveFromDepositQueueParams memory params
    ) internal {
        DepositQueue storage depositQueue = cgs.depositQueues[params.productId];

        uint128 queuedAmount = depositQueue.amounts[params.depositor];
        require(queuedAmount > 0, Errors.VALUE_IS_ZERO);

        if (params.amount == 0) {
            params.amount = queuedAmount;
        }

        require(
            params.amount == queuedAmount ||
                queuedAmount - params.amount >= params.minDepositAmount,
            Errors.VALUE_TOO_SMALL
        );

        depositQueue.amounts[params.depositor] = queuedAmount - params.amount;
        depositQueue.queuedDepositsTotalAmount -= params.amount;

        treasury.withdraw(
            params.depositAsset,
            params.depositor,
            params.amount,
            false
        );

        emit ICommonEvents.DepositRemoved(
            params.productId,
            params.depositor,
            params.amount
        );
    }

    function processDepositQueue(
        CegaGlobalStorage storage cgs,
        ProcessQueueParams memory params,
        function(
            CegaGlobalStorage storage,
            uint32,
            uint128
        ) processDepositQueueHook
    ) internal returns (uint256 processCount) {
        Vault storage vaultData = cgs.vaults[params.vaultAddress];
        uint256 totalSupply = ICegaVault(params.vaultAddress).totalSupply();
        uint128 totalAssets = VaultLogic.totalAssets(cgs, params.vaultAddress);

        require(
            vaultData.vaultStatus == VaultStatus.DepositsOpen,
            Errors.INVALID_VAULT_STATUS
        );
        require(
            !(totalAssets == 0 && totalSupply > 0),
            Errors.VAULT_IN_ZOMBIE_STATE
        );

        DepositQueue storage queue = cgs.depositQueues[params.productId];
        uint256 queueLength = queue.depositors.length;
        uint256 index = queue.processedIndex;
        processCount = params.maxProcessCount == 0
            ? queueLength - index
            : Math.min(queueLength - index, params.maxProcessCount);

        uint128 totalDepositsAmount;

        for (uint256 i = 0; i < processCount; i++) {
            address depositor = queue.depositors[index + i];
            uint128 depositAmount = queue.amounts[depositor];
            delete queue.depositorExists[depositor];

            if (depositAmount > 0) {
                totalDepositsAmount += depositAmount;

                uint256 sharesAmount = VaultLogic.convertToShares(
                    totalSupply,
                    totalAssets,
                    VaultLogic.getAssetDecimals(params.depositAsset),
                    depositAmount
                );
                ICegaVault(params.vaultAddress).mint(depositor, sharesAmount);

                delete queue.amounts[depositor];

                emit ICommonEvents.DepositProcessed(
                    params.vaultAddress,
                    depositor,
                    depositAmount
                );
            }
        }
        queue.processedIndex += processCount.toUint128();

        queue.queuedDepositsTotalAmount -= totalDepositsAmount;

        processDepositQueueHook(cgs, params.productId, totalDepositsAmount);

        vaultData.totalAssets = totalAssets + totalDepositsAmount;

        if (processCount + index == queueLength) {
            VaultLogic.setVaultStatus(
                cgs,
                params.vaultAddress,
                VaultStatus.PreAuction
            );
        }
    }

    /**
     * @dev Processes the withdrawal queue for a specific vault.
     * @param cgs The Cega global storage.
     * @param treasury The treasury contract.
     * @param addressManager The address manager.
     * @param vaultAddress The address of the vault.
     * @param maxProcessCount The maximum number of withdrawals to process.
     * @return processCount The number of processed withdrawals.
     */
    function processWithdrawalQueue(
        CegaGlobalStorage storage cgs,
        ITreasury treasury,
        IAddressManager addressManager,
        address vaultAddress,
        uint256 maxProcessCount,
        address settlementAsset,
        function(CegaGlobalStorage storage, address, uint128)
            internal postWithdrawalHook
    ) internal returns (uint256 processCount) {
        require(
            VaultLogic.isWithdrawalPossible(cgs, vaultAddress),
            Errors.INVALID_VAULT_STATUS
        );

        Vault storage vaultData = cgs.vaults[vaultAddress];

        uint128 totalAssets = vaultData.totalAssets;
        uint256 totalSupply = ICegaVault(vaultAddress).totalSupply();
        address wrappingProxy = addressManager.getAssetWrappingProxy(
            settlementAsset
        );

        WithdrawalQueue storage queue = cgs.withdrawalQueues[vaultAddress];
        uint256 queueLength = queue.withdrawers.length;
        uint256 index = queue.processedIndex;
        processCount = maxProcessCount == 0
            ? queueLength - index
            : Math.min(queueLength - index, maxProcessCount);
        uint256 totalSharesWithdrawn;
        uint128 totalAssetsWithdrawn;
        uint256 sharesAmount;

        for (uint256 i = 0; i < processCount; i++) {
            Withdrawer memory withdrawer = queue.withdrawers[index + i];
            sharesAmount = queue.amounts[withdrawer.account][
                withdrawer.nextProductId
            ];
            delete queue.amounts[withdrawer.account][withdrawer.nextProductId];
            uint128 assetAmount = processWithdrawal(
                withdrawer.account,
                sharesAmount,
                withdrawer.nextProductId,
                queue.withdrawingWithProxy[withdrawer.account],
                treasury,
                addressManager,
                vaultAddress,
                settlementAsset,
                totalAssets,
                totalSupply,
                wrappingProxy
            );
            totalSharesWithdrawn += sharesAmount;
            totalAssetsWithdrawn += assetAmount;
        }

        ICegaVault(vaultAddress).burn(vaultAddress, totalSharesWithdrawn);
        queue.queuedWithdrawalSharesAmount -= totalSharesWithdrawn.toUint128();
        queue.processedIndex += processCount.toUint128();
        vaultData.totalAssets -= totalAssetsWithdrawn;

        postWithdrawalHook(cgs, vaultAddress, totalAssetsWithdrawn);

        if (index + processCount == queueLength) {
            VaultLogic.setVaultStatus(
                cgs,
                vaultAddress,
                VaultStatus.WithdrawalQueueProcessed
            );
        }
    }

    /**
     * @dev Adds a request to the withdrawal queue for a specific vault or withdraw instatly if possible.
     * @param cgs The Cega global storage.
     * @param vaultAddress The address of the vault.
     * @param sharesAmount The amount of shares to withdraw.
     * @param nextProductId The product ID for the next investment cycle, if applicable.
     * @param useProxy Whether to use a proxy for withdrawal.
     */
    function withdrawOrAddToWithdrawalQueue(
        CegaGlobalStorage storage cgs,
        ITreasury treasury,
        IAddressManager addressManager,
        address vaultAddress,
        uint128 sharesAmount,
        uint32 nextProductId,
        bool useProxy,
        uint128 minWithdrawalAmount,
        address settlementAsset,
        function(CegaGlobalStorage storage, address, uint128)
            internal postWithdrawalHook
    ) internal {
        require(sharesAmount >= minWithdrawalAmount, Errors.VALUE_TOO_SMALL);
        uint256 sharesBalance = ICegaVault(vaultAddress).balanceOf(msg.sender);
        require(
            sharesBalance >= sharesAmount &&
                (sharesBalance - sharesAmount == 0 ||
                    sharesBalance - sharesAmount >= minWithdrawalAmount),
            Errors.REMAINING_VALUE_TOO_SMALL
        );

        require(nextProductId == 0 || !useProxy, Errors.NO_PROXY_FOR_REDEPOSIT);

        if (VaultLogic.isWithdrawalPossible(cgs, vaultAddress)) {
            withdrawInstantly(
                cgs,
                treasury,
                addressManager,
                vaultAddress,
                sharesAmount,
                nextProductId,
                useProxy,
                settlementAsset,
                postWithdrawalHook
            );
        } else {
            addToWithdrawalQueue(
                cgs,
                vaultAddress,
                sharesAmount,
                nextProductId,
                useProxy
            );
        }
    }

    function withdrawInstantly(
        CegaGlobalStorage storage cgs,
        ITreasury treasury,
        IAddressManager addressManager,
        address vaultAddress,
        uint128 sharesAmount,
        uint32 nextProductId,
        bool useProxy,
        address settlementAsset,
        function(CegaGlobalStorage storage, address, uint128)
            internal postWithdrawalHook
    ) internal {
        Vault storage vaultData = cgs.vaults[vaultAddress];
        uint128 totalAssets = vaultData.totalAssets;
        uint256 totalSupply = ICegaVault(vaultAddress).totalSupply();
        address wrappingProxy = addressManager.getAssetWrappingProxy(
            settlementAsset
        );

        ICegaVault(vaultAddress).burn(msg.sender, sharesAmount);
        uint128 assetAmount = processWithdrawal(
            msg.sender,
            sharesAmount,
            nextProductId,
            useProxy,
            treasury,
            addressManager,
            vaultAddress,
            settlementAsset,
            totalAssets,
            totalSupply,
            wrappingProxy
        );

        vaultData.totalAssets -= assetAmount;

        postWithdrawalHook(cgs, vaultAddress, assetAmount);
    }

    function addToWithdrawalQueue(
        CegaGlobalStorage storage cgs,
        address vaultAddress,
        uint128 sharesAmount,
        uint32 nextProductId,
        bool useProxy
    ) internal {
        ICegaVault(vaultAddress).transferFrom(
            msg.sender,
            vaultAddress,
            sharesAmount
        );

        WithdrawalQueue storage queue = cgs.withdrawalQueues[vaultAddress];
        uint256 currentQueuedAmount = queue.amounts[msg.sender][nextProductId];
        if (currentQueuedAmount == 0) {
            queue.withdrawers.push(
                Withdrawer({
                    account: msg.sender,
                    nextProductId: nextProductId
                })
            );
        }
        queue.amounts[msg.sender][nextProductId] =
            currentQueuedAmount +
            sharesAmount;
        queue.withdrawingWithProxy[msg.sender] = useProxy;

        queue.queuedWithdrawalSharesAmount += sharesAmount;

        emit ICommonEvents.WithdrawalQueued(
            vaultAddress,
            sharesAmount,
            msg.sender,
            nextProductId,
            useProxy
        );
    }

    function processWithdrawal(
        address account,
        uint256 sharesAmount,
        uint32 nextProductId,
        bool withdrawingWithProxy,
        ITreasury treasury,
        IAddressManager addressManager,
        address vaultAddress,
        address settlementAsset,
        uint128 totalAssets,
        uint256 totalSupply,
        address wrappingProxy
    ) private returns (uint128 assetAmount) {
        assetAmount = VaultLogic.convertToAssets(
            totalSupply,
            totalAssets,
            sharesAmount
        );

        if (nextProductId == 0) {
            if (wrappingProxy != address(0) && withdrawingWithProxy) {
                treasury.withdraw(
                    settlementAsset,
                    wrappingProxy,
                    assetAmount,
                    true
                );
                IWrappingProxy(wrappingProxy).unwrapAndTransfer(
                    account,
                    assetAmount
                );
            } else {
                treasury.withdraw(settlementAsset, account, assetAmount, false);
            }
        } else {
            redeposit(
                treasury,
                addressManager,
                settlementAsset,
                assetAmount,
                account,
                nextProductId
            );
        }

        emit ICommonEvents.WithdrawalProcessed(
            vaultAddress,
            sharesAmount,
            account,
            nextProductId
        );
    }

    function redeposit(
        ITreasury treasury,
        IAddressManager addressManager,
        address asset,
        uint128 amount,
        address owner,
        uint32 nextProductId
    ) private {
        address redepositManager = addressManager.getRedepositManager();
        // TODO add code for redeposit
        IRedepositManager(redepositManager).redeposit(
            treasury,
            nextProductId,
            asset,
            amount,
            owner
        );
    }
}
