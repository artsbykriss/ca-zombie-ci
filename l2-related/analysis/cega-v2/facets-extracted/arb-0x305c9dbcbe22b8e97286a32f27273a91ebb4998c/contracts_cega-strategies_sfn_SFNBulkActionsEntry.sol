// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { CegaGlobalStorage, CegaStorage } from "../../storage/CegaStorage.sol";
import {
    MMNFTMetadata,
    VaultStatus,
    Vault,
    SFN_STRATEGY_ID,
    AddToDepositQueueParams,
    ProcessQueueParams
} from "../../Structs.sol";
import { ProductLogic } from "../common/lib/ProductLogic.sol";
import { Errors } from "../../utils/Errors.sol";
import { Transfers } from "../../utils/Transfers.sol";
import { EntryBase } from "../common/EntryBase.sol";
import { IAddressManager } from "../../aux/interfaces/IAddressManager.sol";
import { ITradeWinnerNFT } from "../../aux/interfaces/ITradeWinnerNFT.sol";
import { ITreasury } from "../../aux/interfaces/ITreasury.sol";
import { IACLManager } from "../../aux/interfaces/IACLManager.sol";
import { IOracleEntry } from "../../oracle-entry/interfaces/IOracleEntry.sol";

import { SFNProduct, SFNEndAuctionParams } from "./SFNStructs.sol";
import { SFNProductLogic } from "./lib/SFNProductLogic.sol";
import { SFNVaultLogic } from "./lib/SFNVaultLogic.sol";
import { ISFNBulkActionsEntry } from "./interfaces/ISFNBulkActionsEntry.sol";

contract SFNBulkActionsEntry is ISFNBulkActionsEntry, EntryBase {
    using SafeCast for uint256;

    // IMMUTABLE

    ITreasury private immutable treasury;

    // CONSTRUCTOR

    constructor(
        IAddressManager _addressManager,
        ITreasury _treasury
    ) EntryBase(_addressManager) {
        treasury = _treasury;
    }

    // FUNCTIONS

    function sfnBulkProcessDepositQueues(
        address[] calldata vaultAddresses,
        uint256 maxProcessCount
    )
        external
        nonReentrant
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidVaultsStrategy(SFN_STRATEGY_ID, vaultAddresses)
    {
        CegaGlobalStorage storage cgs = getStorage();

        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            uint32 productId = cgs.vaults[vaultAddresses[i]].productId;
            SFNProduct storage sfnProduct = cgs.sfnProducts[productId];

            maxProcessCount -= ProductLogic.processDepositQueue(
                cgs,
                ProcessQueueParams({
                    productId: productId,
                    vaultAddress: vaultAddresses[i],
                    depositAsset: SFNProductLogic.sfnGetProductDepositAsset(
                        sfnProduct
                    ),
                    maxProcessCount: maxProcessCount,
                    sumVaultUnderlyingAmounts: sfnProduct
                        .sumVaultUnderlyingAmounts
                }),
                SFNProductLogic.sfnProcessDepositQueueHook
            );

            if (maxProcessCount == 0) {
                return;
            }
        }
    }

    function sfnBulkProcessWithdrawalQueues(
        address[] calldata vaultAddresses,
        uint256 maxProcessCount
    )
        external
        nonReentrant
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidVaultsStrategy(SFN_STRATEGY_ID, vaultAddresses)
    {
        CegaGlobalStorage storage cgs = getStorage();
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            Vault storage vaultData = cgs.vaults[vaultAddresses[i]];
            SFNProduct storage sfnProduct = cgs.sfnProducts[
                vaultData.productId
            ];
            address settlementAsset = sfnProduct.underlyingAsset;

            maxProcessCount -= ProductLogic.processWithdrawalQueue(
                cgs,
                treasury,
                addressManager,
                vaultAddresses[i],
                maxProcessCount,
                settlementAsset,
                SFNProductLogic.sfnAddToWithdrawalQueueHook
            );

            if (maxProcessCount == 0) {
                return;
            }
        }
    }

    function sfnBulkEndAuctions(
        SFNEndAuctionParams[] calldata params
    ) external nonReentrant onlyTraderAdmin onlyIfNotPaused {
        CegaGlobalStorage storage cgs = getStorage();
        for (uint256 i = 0; i < params.length; i++) {
            require(
                cgs.strategyOfProduct[
                    cgs.vaults[params[i].vaultAddress].productId
                ] == SFN_STRATEGY_ID,
                Errors.INVALID_VAULT
            );
            SFNVaultLogic.endAuction(cgs, addressManager, params[i]);
        }
    }

    function sfnBulkStartTrades(
        address[] calldata vaultAddresses
    )
        external
        payable
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultsStrategy(SFN_STRATEGY_ID, vaultAddresses)
    {
        CegaGlobalStorage storage cgs = getStorage();

        MMNFTMetadata[] memory nftMetadatas = new MMNFTMetadata[](
            vaultAddresses.length
        );
        uint256 totalNativeValueReceived;
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            uint256 nativeValueReceived;
            (nativeValueReceived, nftMetadatas[i]) = SFNVaultLogic.startTrade(
                cgs,
                vaultAddresses[i],
                address(0),
                treasury,
                addressManager
            );
            totalNativeValueReceived += nativeValueReceived;
        }

        uint256[] memory tokenIds = ITradeWinnerNFT(
            addressManager.getTradeWinnerNFT()
        ).mintBatch(msg.sender, nftMetadatas);
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            cgs.vaults[vaultAddresses[i]].auctionWinnerTokenId = tokenIds[i]
                .toUint64();
        }

        Transfers.receiveNativeValue(totalNativeValueReceived);
    }

    function sfnBulkCheckBarriers(
        address[] calldata vaultAddresses,
        uint16 maxObservations
    )
        external
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultsStrategy(SFN_STRATEGY_ID, vaultAddresses)
    {
        CegaGlobalStorage storage cgs = getStorage();
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            (, uint16 observationsDone) = SFNVaultLogic.checkBarriers(
                cgs,
                addressManager,
                vaultAddresses[i],
                maxObservations
            );
            maxObservations -= observationsDone;
            if (maxObservations == 0) {
                return;
            }
        }
    }

    function sfnBulkCheckTradesExpiry(
        address[] calldata vaultAddresses
    )
        external
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultsStrategy(SFN_STRATEGY_ID, vaultAddresses)
    {
        CegaGlobalStorage storage cgs = getStorage();
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            SFNVaultLogic.checkTradeExpiry(
                cgs,
                addressManager,
                vaultAddresses[i]
            );
        }
    }

    function sfnBulkSettleVaults(
        address[] calldata vaultAddresses
    )
        external
        payable
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultsStrategy(SFN_STRATEGY_ID, vaultAddresses)
    {
        CegaGlobalStorage storage cgs = getStorage();
        uint256 totalNativeValueReceived;
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            totalNativeValueReceived += SFNVaultLogic.settleVault(
                cgs,
                addressManager,
                treasury,
                vaultAddresses[i]
            );
        }

        Transfers.receiveNativeValue(totalNativeValueReceived);
    }

    function sfnBulkCollectFees(
        address[] calldata vaultAddresses
    )
        external
        nonReentrant
        onlyIfNotPaused
        onlyTraderAdmin
        onlyValidVaultsStrategy(SFN_STRATEGY_ID, vaultAddresses)
    {
        CegaGlobalStorage storage cgs = getStorage();
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            SFNVaultLogic.collectVaultFees(
                cgs,
                treasury,
                addressManager,
                vaultAddresses[i]
            );
        }
    }

    function sfnBulkRolloverVaults(
        address[] calldata vaultAddresses
    )
        external
        nonReentrant
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidVaultsStrategy(SFN_STRATEGY_ID, vaultAddresses)
    {
        CegaGlobalStorage storage cgs = getStorage();
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            SFNVaultLogic.rolloverVault(cgs, vaultAddresses[i]);
        }
    }

    function sfnBulkCheckSettlementDefault(
        address[] calldata vaultAddresses
    )
        external
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultsStrategy(SFN_STRATEGY_ID, vaultAddresses)
    {
        CegaGlobalStorage storage cgs = getStorage();
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            SFNVaultLogic.checkSettlementDefault(cgs, vaultAddresses[i]);
        }
    }

    function sfnBulkCheckAuctionDefault(
        address[] calldata vaultAddresses
    )
        external
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultsStrategy(SFN_STRATEGY_ID, vaultAddresses)
    {
        CegaGlobalStorage storage cgs = getStorage();
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            SFNVaultLogic.checkAuctionDefault(cgs, vaultAddresses[i]);
        }
    }
}
