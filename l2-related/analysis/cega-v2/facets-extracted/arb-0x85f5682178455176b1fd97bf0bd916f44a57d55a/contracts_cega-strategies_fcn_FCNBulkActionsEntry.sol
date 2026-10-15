// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { CegaGlobalStorage, CegaStorage } from "../../storage/CegaStorage.sol";
import {
    MMNFTMetadata,
    VaultStatus,
    Vault,
    FCN_STRATEGY_ID,
    AddToDepositQueueParams,
    ProcessQueueParams
} from "../../Structs.sol";
import { ProductLogic } from "../common/lib/ProductLogic.sol";
import { IAddressManager } from "../../aux/interfaces/IAddressManager.sol";
import { ITradeWinnerNFT } from "../../aux/interfaces/ITradeWinnerNFT.sol";
import { ITreasury } from "../../aux/interfaces/ITreasury.sol";
import { IACLManager } from "../../aux/interfaces/IACLManager.sol";
import { IOracleEntry } from "../../oracle-entry/interfaces/IOracleEntry.sol";
import { Errors } from "../../utils/Errors.sol";
import { Transfers } from "../../utils/Transfers.sol";
import { EntryBase } from "../common/EntryBase.sol";
import { FCNProduct, FCNOptionBarrier } from "./FCNStructs.sol";
import { FCNProductLogic } from "./lib/FCNProductLogic.sol";
import { FCNVaultLogic } from "./lib/FCNVaultLogic.sol";
import { IFCNBulkActionsEntry } from "./interfaces/IFCNBulkActionsEntry.sol";

contract FCNBulkActionsEntry is IFCNBulkActionsEntry, EntryBase {
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

    function fcnBulkProcessDepositQueues(
        address[] calldata vaultAddresses,
        uint256 maxProcessCount
    )
        external
        nonReentrant
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidVaultsStrategy(FCN_STRATEGY_ID, vaultAddresses)
    {
        CegaGlobalStorage storage cgs = getStorage();

        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            uint32 productId = cgs.vaults[vaultAddresses[i]].productId;
            FCNProduct storage fcnProduct = cgs.fcnProducts[productId];

            maxProcessCount -= ProductLogic.processDepositQueue(
                cgs,
                ProcessQueueParams({
                    productId: productId,
                    vaultAddress: vaultAddresses[i],
                    depositAsset: FCNProductLogic.fcnGetProductDepositAsset(
                        fcnProduct
                    ),
                    maxProcessCount: maxProcessCount,
                    sumVaultUnderlyingAmounts: fcnProduct
                        .sumVaultUnderlyingAmounts
                }),
                FCNProductLogic.fcnProcessDepositQueueHook
            );

            if (maxProcessCount == 0) {
                return;
            }
        }
    }

    function fcnBulkProcessWithdrawalQueues(
        address[] calldata vaultAddresses,
        uint256 maxProcessCount
    )
        external
        nonReentrant
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidVaultsStrategy(FCN_STRATEGY_ID, vaultAddresses)
    {
        CegaGlobalStorage storage cgs = getStorage();
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            Vault storage vaultData = cgs.vaults[vaultAddresses[i]];
            FCNProduct storage fcnProduct = cgs.fcnProducts[
                vaultData.productId
            ];
            address settlementAsset = fcnProduct.underlyingAsset;

            maxProcessCount -= ProductLogic.processWithdrawalQueue(
                cgs,
                treasury,
                addressManager,
                vaultAddresses[i],
                maxProcessCount,
                settlementAsset,
                FCNProductLogic.fcnAddToWithdrawalQueueHook
            );

            if (maxProcessCount == 0) {
                return;
            }
        }
    }

    function fcnBulkEndAuctions(
        address[] calldata vaultAddresses,
        address[] calldata auctionWinners,
        uint40[] calldata tradeStartDates,
        uint16[] calldata aprBps,
        IOracleEntry.DataSource[][] calldata dataSources
    )
        external
        nonReentrant
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidVaultsStrategy(FCN_STRATEGY_ID, vaultAddresses)
    {
        require(
            vaultAddresses.length == auctionWinners.length &&
                vaultAddresses.length == tradeStartDates.length &&
                vaultAddresses.length == aprBps.length &&
                vaultAddresses.length == dataSources.length,
            Errors.INVALID_ARRAY_LENGTH
        );

        CegaGlobalStorage storage cgs = getStorage();
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            FCNVaultLogic.endAuction(
                cgs,
                addressManager,
                vaultAddresses[i],
                auctionWinners[i],
                tradeStartDates[i],
                aprBps[i],
                dataSources[i]
            );
        }
    }

    function fcnBulkStartTrades(
        address[] calldata vaultAddresses
    )
        external
        payable
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultsStrategy(FCN_STRATEGY_ID, vaultAddresses)
    {
        CegaGlobalStorage storage cgs = getStorage();

        MMNFTMetadata[] memory nftMetadatas = new MMNFTMetadata[](
            vaultAddresses.length
        );
        uint256 totalNativeValueReceived;
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            uint256 nativeValueReceived;
            (nativeValueReceived, nftMetadatas[i]) = FCNVaultLogic.startTrade(
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

    function fcnBulkCheckBarriers(
        address[] calldata vaultAddresses,
        uint16 maxObservations
    )
        external
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultsStrategy(FCN_STRATEGY_ID, vaultAddresses)
    {
        CegaGlobalStorage storage cgs = getStorage();
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            (, uint16 observationsDone) = FCNVaultLogic.checkBarriers(
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

    function fcnBulkCheckTradesExpiry(
        address[] calldata vaultAddresses
    )
        external
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultsStrategy(FCN_STRATEGY_ID, vaultAddresses)
    {
        CegaGlobalStorage storage cgs = getStorage();
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            FCNVaultLogic.checkTradeExpiry(
                cgs,
                addressManager,
                vaultAddresses[i]
            );
        }
    }

    function fcnBulkRepayBonds(
        address[] calldata vaultAddresses,
        uint128[] calldata amounts
    )
        external
        payable
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultsStrategy(FCN_STRATEGY_ID, vaultAddresses)
    {
        require(
            vaultAddresses.length == amounts.length,
            Errors.INVALID_ARRAY_LENGTH
        );

        CegaGlobalStorage storage cgs = getStorage();
        uint256 totalNativeValueReceived;
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            totalNativeValueReceived += FCNVaultLogic.repayBond(
                cgs,
                treasury,
                vaultAddresses[i],
                amounts[i]
            );
        }

        Transfers.receiveNativeValue(totalNativeValueReceived);
    }

    function fcnBulkSettleVaults(
        address[] calldata vaultAddresses
    )
        external
        payable
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultsStrategy(FCN_STRATEGY_ID, vaultAddresses)
    {
        CegaGlobalStorage storage cgs = getStorage();
        uint256 totalNativeValueReceived;
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            totalNativeValueReceived += FCNVaultLogic.settleVault(
                cgs,
                addressManager,
                treasury,
                vaultAddresses[i]
            );
        }

        Transfers.receiveNativeValue(totalNativeValueReceived);
    }

    function fcnBulkCollectFees(
        address[] calldata vaultAddresses
    )
        external
        nonReentrant
        onlyIfNotPaused
        onlyTraderAdmin
        onlyValidVaultsStrategy(FCN_STRATEGY_ID, vaultAddresses)
    {
        CegaGlobalStorage storage cgs = getStorage();
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            FCNVaultLogic.collectVaultFees(
                cgs,
                treasury,
                addressManager,
                vaultAddresses[i]
            );
        }
    }

    function fcnBulkRolloverVaults(
        address[] calldata vaultAddresses
    )
        external
        nonReentrant
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidVaultsStrategy(FCN_STRATEGY_ID, vaultAddresses)
    {
        CegaGlobalStorage storage cgs = getStorage();
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            FCNVaultLogic.rolloverVault(cgs, vaultAddresses[i]);
        }
    }

    function fcnBulkCheckSettlementDefault(
        address[] calldata vaultAddresses
    )
        external
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultsStrategy(FCN_STRATEGY_ID, vaultAddresses)
    {
        CegaGlobalStorage storage cgs = getStorage();
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            FCNVaultLogic.checkSettlementDefault(cgs, vaultAddresses[i]);
        }
    }

    function fcnBulkCheckAuctionDefault(
        address[] calldata vaultAddresses
    )
        external
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultsStrategy(FCN_STRATEGY_ID, vaultAddresses)
    {
        CegaGlobalStorage storage cgs = getStorage();
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            FCNVaultLogic.checkAuctionDefault(cgs, vaultAddresses[i]);
        }
    }
}
