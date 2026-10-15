// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { CegaGlobalStorage, CegaStorage } from "../../storage/CegaStorage.sol";
import {
    MMNFTMetadata,
    VaultStatus,
    DCS_STRATEGY_ID,
    AddToDepositQueueParams,
    ProcessQueueParams
} from "../../Structs.sol";
import { DCSLogic } from "./lib/DCSLogic.sol";
import { DCSVaultLogic } from "./lib/DCSVaultLogic.sol";
import { DCSProduct } from "./DCSStructs.sol";
import { ProductLogic } from "../common/lib/ProductLogic.sol";
import { VaultLogic } from "../common/lib/VaultLogic.sol";

import { IAddressManager } from "../../aux/interfaces/IAddressManager.sol";
import { ITradeWinnerNFT } from "../../aux/interfaces/ITradeWinnerNFT.sol";
import { ITreasury } from "../../aux/interfaces/ITreasury.sol";
import { IACLManager } from "../../aux/interfaces/IACLManager.sol";
import { IOracleEntry } from "../../oracle-entry/interfaces/IOracleEntry.sol";
import { IDCSBulkActionsEntry } from "./interfaces/IDCSBulkActionsEntry.sol";
import { Errors } from "../../utils/Errors.sol";
import { Transfers } from "../../utils/Transfers.sol";
import { EntryBase } from "../common/EntryBase.sol";

contract DCSBulkActionsEntry is IDCSBulkActionsEntry, EntryBase {
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

    function dcsBulkEndAuctions(
        address[] calldata vaultAddresses,
        address[] calldata auctionWinners,
        uint40[] calldata tradeStartDates,
        uint16[] calldata aprBps,
        IOracleEntry.DataSource[] calldata dataSources
    )
        external
        nonReentrant
        onlyValidVaultsStrategy(DCS_STRATEGY_ID, vaultAddresses)
        onlyTraderAdmin
        onlyIfNotPaused
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
            DCSLogic.endAuction(
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

    function dcsBulkStartTrades(
        address[] calldata vaultAddresses
    )
        external
        payable
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultsStrategy(DCS_STRATEGY_ID, vaultAddresses)
    {
        CegaGlobalStorage storage cgs = getStorage();

        MMNFTMetadata[] memory nftMetadatas = new MMNFTMetadata[](
            vaultAddresses.length
        );
        uint256 totalNativeValueReceived;
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            uint256 nativeValueReceived;
            (nativeValueReceived, nftMetadatas[i]) = DCSLogic.startTrade(
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

    function dcsBulkProcessDepositQueues(
        address[] calldata vaultAddresses,
        uint256 maxProcessCount
    )
        external
        nonReentrant
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidVaultsStrategy(DCS_STRATEGY_ID, vaultAddresses)
    {
        CegaGlobalStorage storage cgs = getStorage();

        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            uint32 productId = cgs.vaults[vaultAddresses[i]].productId;
            DCSProduct storage dcsProduct = cgs.dcsProducts[productId];

            maxProcessCount -= ProductLogic.processDepositQueue(
                cgs,
                ProcessQueueParams({
                    productId: productId,
                    vaultAddress: vaultAddresses[i],
                    depositAsset: DCSLogic.dcsGetProductDepositAsset(
                        dcsProduct
                    ),
                    maxProcessCount: maxProcessCount,
                    sumVaultUnderlyingAmounts: dcsProduct
                        .sumVaultUnderlyingAmounts
                }),
                DCSLogic.dcsProcessDepositQueueHook
            );

            if (maxProcessCount == 0) {
                return;
            }
        }
    }

    function dcsBulkProcessWithdrawalQueues(
        address[] calldata vaultAddresses,
        uint256 maxProcessCount
    )
        external
        nonReentrant
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidVaultsStrategy(DCS_STRATEGY_ID, vaultAddresses)
    {
        CegaGlobalStorage storage cgs = getStorage();

        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            address settlementAsset = DCSLogic.getVaultSettlementAsset(
                cgs,
                vaultAddresses[i]
            );
            maxProcessCount -= ProductLogic.processWithdrawalQueue(
                cgs,
                treasury,
                addressManager,
                vaultAddresses[i],
                maxProcessCount,
                settlementAsset,
                DCSLogic.dcsAddToWithdrawalQueueHook
            );

            if (maxProcessCount == 0) {
                return;
            }
        }
    }

    function dcsBulkRolloverVaults(
        address[] calldata vaultAddresses,
        uint256 maxProcessCount
    )
        external
        nonReentrant
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidVaultsStrategy(DCS_STRATEGY_ID, vaultAddresses)
    {
        CegaGlobalStorage storage cgs = getStorage();
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            maxProcessCount -= DCSVaultLogic.rolloverVault(
                cgs,
                addressManager,
                treasury,
                vaultAddresses[i],
                maxProcessCount
            );

            if (maxProcessCount == 0) {
                return;
            }
        }
    }

    function dcsBulkCheckTradesExpiry(
        address[] calldata vaultAddresses
    )
        external
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultsStrategy(DCS_STRATEGY_ID, vaultAddresses)
    {
        CegaGlobalStorage storage cgs = getStorage();
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            DCSLogic.checkTradeExpiry(cgs, addressManager, vaultAddresses[i]);
        }
    }

    function dcsBulkCheckAuctionDefault(
        address[] calldata vaultAddresses
    )
        external
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultsStrategy(DCS_STRATEGY_ID, vaultAddresses)
    {
        CegaGlobalStorage storage cgs = getStorage();
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            DCSLogic.checkAuctionDefault(cgs, vaultAddresses[i]);
        }
    }

    function dcsBulkCheckSettlementDefault(
        address[] calldata vaultAddresses
    )
        external
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultsStrategy(DCS_STRATEGY_ID, vaultAddresses)
    {
        CegaGlobalStorage storage cgs = getStorage();
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            DCSLogic.checkSettlementDefault(cgs, vaultAddresses[i]);
        }
    }

    function dcsBulkSettleVaults(
        address[] calldata vaultAddresses
    )
        external
        payable
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultsStrategy(DCS_STRATEGY_ID, vaultAddresses)
    {
        CegaGlobalStorage storage cgs = getStorage();

        uint256 totalNativeValueReceived;
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            totalNativeValueReceived += DCSLogic.settleVault(
                cgs,
                vaultAddresses[i],
                treasury,
                addressManager
            );
        }

        Transfers.receiveNativeValue(totalNativeValueReceived);
    }

    function dcsBulkCollectFees(
        address[] calldata vaultAddresses
    )
        external
        onlyTraderAdmin
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultsStrategy(DCS_STRATEGY_ID, vaultAddresses)
    {
        CegaGlobalStorage storage cgs = getStorage();
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            DCSLogic.collectVaultFees(
                cgs,
                treasury,
                addressManager,
                vaultAddresses[i]
            );
        }
    }
}
