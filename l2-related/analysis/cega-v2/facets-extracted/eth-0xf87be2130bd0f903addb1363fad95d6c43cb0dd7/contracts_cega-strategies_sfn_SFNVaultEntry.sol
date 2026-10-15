// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import {
    CegaGlobalStorage,
    SFN_STRATEGY_ID,
    VaultCreationParams,
    Vault,
    ProcessQueueParams
} from "../../Structs.sol";
import { Errors } from "../../utils/Errors.sol";
import { EntryBase } from "../common/EntryBase.sol";
import { IAddressManager } from "../../aux/interfaces/IAddressManager.sol";
import { ITreasury } from "../../aux/interfaces/ITreasury.sol";
import { ProductLogic } from "../common/lib/ProductLogic.sol";
import { IOracleEntry } from "../../oracle-entry/interfaces/IOracleEntry.sol";
import { Transfers } from "../../utils/Transfers.sol";

import {
    SFNProductCreationParams,
    SFNProduct,
    SFNOptionType,
    SFNEndAuctionParams
} from "./SFNStructs.sol";
import { SFNProductLogic } from "./lib/SFNProductLogic.sol";
import { SFNVaultLogic } from "./lib/SFNVaultLogic.sol";
import { ISFNVaultEntry } from "./interfaces/ISFNVaultEntry.sol";
import { ISFNEvents } from "./interfaces/ISFNEvents.sol";

contract SFNVaultEntry is ISFNVaultEntry, ISFNEvents, EntryBase {
    // CONSTANTS

    uint128 internal constant BPS_DECIMALS = 1e4;

    // IMMUTABLES

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
     * @param params End auction params struct
     */
    function sfnEndAuction(
        SFNEndAuctionParams calldata params
    )
        external
        nonReentrant
        onlyValidVaultStrategy(SFN_STRATEGY_ID, params.vaultAddress)
        onlyTraderAdmin
        onlyIfNotPaused
    {
        CegaGlobalStorage storage cgs = getStorage();
        SFNVaultLogic.endAuction(cgs, addressManager, params);
    }

    /**
     *
     * @param vaultAddress address of the vault to start trading
     */
    function sfnStartTrade(
        address vaultAddress
    )
        external
        payable
        nonReentrant
        onlyValidVaultStrategy(SFN_STRATEGY_ID, vaultAddress)
        onlyIfNotPaused
    {
        CegaGlobalStorage storage cgs = getStorage();
        (uint256 nativeValueReceived, ) = SFNVaultLogic.startTrade(
            cgs,
            vaultAddress,
            addressManager.getTradeWinnerNFT(),
            treasury,
            addressManager
        );
        Transfers.receiveNativeValue(nativeValueReceived);
    }

    function sfnCheckBarriers(
        address vaultAddress,
        uint16 maxObservations
    )
        external
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultStrategy(SFN_STRATEGY_ID, vaultAddress)
    {
        CegaGlobalStorage storage cgs = getStorage();
        SFNVaultLogic.checkBarriers(
            cgs,
            addressManager,
            vaultAddress,
            maxObservations
        );
    }

    function sfnCheckTradeExpiry(
        address vaultAddress
    )
        external
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultStrategy(SFN_STRATEGY_ID, vaultAddress)
    {
        CegaGlobalStorage storage cgs = getStorage();
        SFNVaultLogic.checkTradeExpiry(cgs, addressManager, vaultAddress);
    }

    function sfnCollectVaultFees(
        address vaultAddress
    )
        external
        onlyTraderAdmin
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultStrategy(SFN_STRATEGY_ID, vaultAddress)
    {
        CegaGlobalStorage storage cgs = getStorage();
        SFNVaultLogic.collectVaultFees(
            cgs,
            treasury,
            addressManager,
            vaultAddress
        );
    }

    function sfnRolloverVault(
        address vaultAddress
    )
        external
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultStrategy(SFN_STRATEGY_ID, vaultAddress)
        onlyTraderAdmin
    {
        CegaGlobalStorage storage cgs = getStorage();
        SFNVaultLogic.rolloverVault(cgs, vaultAddress);
    }

    function sfnSubmitDispute(
        address vaultAddress,
        uint40 timestamp
    )
        external
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultStrategy(SFN_STRATEGY_ID, vaultAddress)
    {
        CegaGlobalStorage storage cgs = getStorage();
        SFNVaultLogic.disputeVault(
            cgs,
            addressManager,
            vaultAddress,
            timestamp
        );
    }

    function sfnProcessTradeDispute(
        address vaultAddress,
        uint40 timestamp,
        bool accept,
        uint128[] calldata newPrices
    )
        external
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultStrategy(SFN_STRATEGY_ID, vaultAddress)
        onlyTraderAdmin
    {
        CegaGlobalStorage storage cgs = getStorage();
        SFNVaultLogic.processDispute(
            cgs,
            addressManager,
            vaultAddress,
            timestamp,
            accept,
            newPrices
        );
    }

    function sfnCheckSettlementDefault(
        address vaultAddress
    )
        external
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultStrategy(SFN_STRATEGY_ID, vaultAddress)
    {
        CegaGlobalStorage storage cgs = getStorage();
        SFNVaultLogic.checkSettlementDefault(cgs, vaultAddress);
    }

    function sfnCheckAuctionDefault(
        address vaultAddress
    )
        external
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultStrategy(SFN_STRATEGY_ID, vaultAddress)
    {
        CegaGlobalStorage storage cgs = getStorage();

        SFNVaultLogic.checkAuctionDefault(cgs, vaultAddress);
    }

    /**
     * @notice Settles vault after trade expiry
     * @param vaultAddress Address of the vault to settle
     */
    function sfnSettleVault(
        address vaultAddress
    )
        external
        payable
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultStrategy(SFN_STRATEGY_ID, vaultAddress)
    {
        CegaGlobalStorage storage cgs = getStorage();
        uint256 nativeValueReceived = SFNVaultLogic.settleVault(
            cgs,
            addressManager,
            treasury,
            vaultAddress
        );
        Transfers.receiveNativeValue(nativeValueReceived);
    }
}
