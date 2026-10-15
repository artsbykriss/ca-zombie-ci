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
    AddToDepositQueueParams,
    ProcessQueueParams
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

import { IFCNVaultEntry } from "./interfaces/IFCNVaultEntry.sol";
import { IFCNEvents } from "./interfaces/IFCNEvents.sol";
import { IAddressManager } from "../../aux/interfaces/IAddressManager.sol";
import { IACLManager } from "../../aux/interfaces/IACLManager.sol";

import { EntryBase } from "../common/EntryBase.sol";
import { Errors } from "../../utils/Errors.sol";
import { CegaVault } from "../../vaults/CegaVault.sol";
import { ProductLogic } from "../common/lib/ProductLogic.sol";
import { VaultLogic } from "../common/lib/VaultLogic.sol";

import { FCNVaultLogic } from "./lib/FCNVaultLogic.sol";
import { IOracleEntry } from "../../oracle-entry/interfaces/IOracleEntry.sol";

import { Transfers } from "../../utils/Transfers.sol";

contract FCNVaultEntry is IFCNEvents, IFCNVaultEntry, EntryBase {
    ITreasury private immutable treasury;

    // CONSTRUCTOR

    constructor(
        IAddressManager _addressManager,
        ITreasury _treasury
    ) EntryBase(_addressManager) {
        treasury = _treasury;
    }

    // FUNCTIONS

    /**
     * Once the winner of an auction is determined, this function sets the vault state so it is ready
     * to start the trade.
     *
     * @param vaultAddress address of the vault
     * @param auctionWinner address of the winner
     * @param tradeStartDate when the trade starts
     * @param aprBps the apr of the vault
     * @param dataSources the list of data sources for the barriers
     */
    function fcnEndAuction(
        address vaultAddress,
        address auctionWinner,
        uint40 tradeStartDate,
        uint16 aprBps,
        IOracleEntry.DataSource[] calldata dataSources
    )
        external
        nonReentrant
        onlyValidVaultStrategy(FCN_STRATEGY_ID, vaultAddress)
        onlyTraderAdmin
        onlyIfNotPaused
    {
        CegaGlobalStorage storage cgs = getStorage();
        FCNVaultLogic.endAuction(
            cgs,
            addressManager,
            vaultAddress,
            auctionWinner,
            tradeStartDate,
            aprBps,
            dataSources
        );
    }

    /**
     *
     * @param vaultAddress address of the vault to start trading
     */
    function fcnStartTrade(
        address vaultAddress
    )
        external
        payable
        nonReentrant
        onlyValidVaultStrategy(FCN_STRATEGY_ID, vaultAddress)
        onlyIfNotPaused
    {
        CegaGlobalStorage storage cgs = getStorage();
        (uint256 nativeValueReceived, ) = FCNVaultLogic.startTrade(
            cgs,
            vaultAddress,
            addressManager.getTradeWinnerNFT(),
            treasury,
            addressManager
        );
        Transfers.receiveNativeValue(nativeValueReceived);
    }

    /**
     * @notice Checks barriers, doing up to given number of observations
     * @param vaultAddress Address of the vault to check barriers for
     * @param maxObservations Maximal number of observations to do
     */
    function fcnCheckBarriers(
        address vaultAddress,
        uint16 maxObservations
    )
        external
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultStrategy(FCN_STRATEGY_ID, vaultAddress)
    {
        CegaGlobalStorage storage cgs = getStorage();
        FCNVaultLogic.checkBarriers(
            cgs,
            addressManager,
            vaultAddress,
            maxObservations
        );
    }

    /**
     * @notice Checks trade expiry for a given vault (and does remaining barriers check)
     * @param vaultAddress Address of the vault to check expiry
     */
    function fcnCheckTradeExpiry(
        address vaultAddress
    )
        external
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultStrategy(FCN_STRATEGY_ID, vaultAddress)
    {
        CegaGlobalStorage storage cgs = getStorage();
        FCNVaultLogic.checkTradeExpiry(cgs, addressManager, vaultAddress);
    }

    /**
     * @notice Repays bond for a given vault (partially or fully)
     * @param vaultAddress Address of the vault to repay for
     * @param amount Amount to repay
     */
    function fcnRepayBond(
        address vaultAddress,
        uint128 amount
    )
        external
        payable
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultStrategy(FCN_STRATEGY_ID, vaultAddress)
    {
        CegaGlobalStorage storage cgs = getStorage();
        uint256 nativeValueReceived = FCNVaultLogic.repayBond(
            cgs,
            treasury,
            vaultAddress,
            amount
        );
        Transfers.receiveNativeValue(nativeValueReceived);
    }

    /**
     * @notice Settles vault after trade expiry
     * @param vaultAddress Address of the vault to settle
     */
    function fcnSettleVault(
        address vaultAddress
    )
        external
        payable
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultStrategy(FCN_STRATEGY_ID, vaultAddress)
    {
        CegaGlobalStorage storage cgs = getStorage();
        uint256 nativeValueReceived = FCNVaultLogic.settleVault(
            cgs,
            addressManager,
            treasury,
            vaultAddress
        );
        Transfers.receiveNativeValue(nativeValueReceived);
    }

    function fcnCollectVaultFees(
        address vaultAddress
    )
        external
        onlyTraderAdmin
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultStrategy(FCN_STRATEGY_ID, vaultAddress)
    {
        CegaGlobalStorage storage cgs = getStorage();

        FCNVaultLogic.collectVaultFees(
            cgs,
            treasury,
            addressManager,
            vaultAddress
        );
    }

    function fcnRolloverVault(
        address vaultAddress
    )
        external
        onlyTraderAdmin
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultStrategy(FCN_STRATEGY_ID, vaultAddress)
    {
        CegaGlobalStorage storage cgs = getStorage();
        FCNVaultLogic.rolloverVault(cgs, vaultAddress);
    }

    function fcnCheckSettlementDefault(
        address vaultAddress
    )
        external
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultStrategy(FCN_STRATEGY_ID, vaultAddress)
    {
        CegaGlobalStorage storage cgs = getStorage();
        FCNVaultLogic.checkSettlementDefault(cgs, vaultAddress);
    }

    function fcnCheckAuctionDefault(
        address vaultAddress
    )
        external
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultStrategy(FCN_STRATEGY_ID, vaultAddress)
    {
        CegaGlobalStorage storage cgs = getStorage();

        FCNVaultLogic.checkAuctionDefault(cgs, vaultAddress);
    }

    function fcnSubmitDispute(
        address vaultAddress,
        uint8 barrierIndex,
        uint40 timestamp
    )
        external
        onlyValidVaultStrategy(FCN_STRATEGY_ID, vaultAddress)
        onlyIfNotPaused
    {
        CegaGlobalStorage storage cgs = getStorage();

        FCNVaultLogic.disputeVault(
            cgs,
            vaultAddress,
            barrierIndex,
            timestamp,
            addressManager
        );
    }

    function fcnProcessTradeDispute(
        address vaultAddress,
        uint8 barrierIndex,
        uint40 timestamp,
        uint128 newPrice
    )
        external
        onlyCegaAdmin
        onlyValidVaultStrategy(FCN_STRATEGY_ID, vaultAddress)
        onlyIfNotPaused
    {
        CegaGlobalStorage storage cgs = getStorage();

        FCNVaultLogic.processDispute(
            cgs,
            addressManager,
            vaultAddress,
            barrierIndex,
            timestamp,
            newPrice
        );
    }
}
