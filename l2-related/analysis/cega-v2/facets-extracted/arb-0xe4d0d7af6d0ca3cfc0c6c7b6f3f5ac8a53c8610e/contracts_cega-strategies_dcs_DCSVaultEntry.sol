// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { IERC20, ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { IDCSEvents } from "./interfaces/IDCSEvents.sol";
import { IDCSVaultEntry } from "./interfaces/IDCSVaultEntry.sol";

import { CegaVault } from "../../vaults/CegaVault.sol";
import { IOracleEntry } from "../../oracle-entry/interfaces/IOracleEntry.sol";
import { CegaStorage } from "../../storage/CegaStorage.sol";
import {
    CegaGlobalStorage,
    Vault,
    VaultStatus,
    MMNFTMetadata,
    DCS_STRATEGY_ID,
    VaultCreationParams
} from "../../Structs.sol";
import {
    DCSProduct,
    DCSVault,
    DCSOptionType,
    SettlementStatus
} from "./DCSStructs.sol";
import { IAddressManager } from "../../aux/interfaces/IAddressManager.sol";
import { ITradeWinnerNFT } from "../../aux/interfaces/ITradeWinnerNFT.sol";
import { IACLManager } from "../../aux/interfaces/IACLManager.sol";
import { IOracleEntry } from "../../oracle-entry/interfaces/IOracleEntry.sol";
import { ITreasury } from "../../aux/interfaces/ITreasury.sol";
import { ISwapManager } from "../../swaps/interfaces/ISwapManager.sol";

import { DCSVaultLogic } from "./lib/DCSVaultLogic.sol";
import { DCSLogic } from "./lib/DCSLogic.sol";
import { VaultLogic } from "../common/lib/VaultLogic.sol";

import { Transfers } from "../../utils/Transfers.sol";
import { Errors } from "../../utils/Errors.sol";
import { EntryBase } from "../common/EntryBase.sol";

contract DCSVaultEntry is EntryBase, IDCSEvents, IDCSVaultEntry {
    using Transfers for address;

    uint128 private constant BPS_DECIMALS = 1e4;

    // CONSTANTS

    ITreasury private immutable treasury;

    // CONSTRUCTOR

    constructor(
        IAddressManager _addressManager,
        ITreasury _treasury
    ) EntryBase(_addressManager) {
        treasury = _treasury;
    }

    // MUTATIVE FUNCTIONS

    function dcsCreateVault(
        uint32 _productId,
        VaultCreationParams calldata creationParams
    )
        external
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidProductStrategy(DCS_STRATEGY_ID, _productId)
        returns (address vaultAddress)
    {
        CegaGlobalStorage storage cgs = getStorage();
        require(_productId <= cgs.productIdCounter, Errors.VALUE_TOO_LARGE);
        DCSProduct storage product = cgs.dcsProducts[_productId];

        CegaVault vaultContract = new CegaVault(
            addressManager,
            creationParams.tokenName,
            creationParams.tokenSymbol
        );
        address newVaultAddress = address(vaultContract);
        product.vaults.push(newVaultAddress);

        Vault storage vault = cgs.vaults[newVaultAddress];
        vault.productId = _productId;
        vault.yieldFeeBps = creationParams.yieldFeeBps;
        vault.managementFeeBps = creationParams.managementFeeBps;

        cgs.dcsVaults[newVaultAddress].isPayoffInDepositAsset = true;

        emit DCSVaultCreated(_productId, newVaultAddress, creationParams);

        return newVaultAddress;
    }

    /**
     * Once the winner of an auction is determined, this function sets the vault state so it is ready
     * to start the trade.
     *
     * @param vaultAddress address of the vault
     * @param auctionWinner address of the winner
     * @param tradeStartDate when the trade starts
     * @param aprBps the apr of the vault
     */
    function dcsEndAuction(
        address vaultAddress,
        address auctionWinner,
        uint40 tradeStartDate,
        uint16 aprBps,
        IOracleEntry.DataSource dataSource
    )
        external
        nonReentrant
        onlyValidVaultStrategy(DCS_STRATEGY_ID, vaultAddress)
        onlyTraderAdmin
        onlyIfNotPaused
    {
        CegaGlobalStorage storage cgs = getStorage();
        DCSLogic.endAuction(
            cgs,
            addressManager,
            vaultAddress,
            auctionWinner,
            tradeStartDate,
            aprBps,
            dataSource
        );
    }

    /**
     *
     * @param vaultAddress address of the vault to start trading
     */
    function dcsStartTrade(
        address vaultAddress
    )
        external
        payable
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultStrategy(DCS_STRATEGY_ID, vaultAddress)
    {
        CegaGlobalStorage storage cgs = getStorage();
        (uint256 nativeValueReceived, ) = DCSLogic.startTrade(
            cgs,
            vaultAddress,
            addressManager.getTradeWinnerNFT(),
            treasury,
            addressManager
        );
        Transfers.receiveNativeValue(nativeValueReceived);
    }

    function dcsSettleVault(
        address vaultAddress
    ) external payable nonReentrant onlyIfNotPaused {
        CegaGlobalStorage storage cgs = getStorage();
        uint256 nativeValueReceived = DCSLogic.settleVault(
            cgs,
            vaultAddress,
            treasury,
            addressManager
        );
        Transfers.receiveNativeValue(nativeValueReceived);
    }

    function dcsSwapAndSettleVault(
        address vaultAddress,
        ISwapManager.SwapProtocol swapProtocol,
        ISwapManager.SwapData calldata swapData
    )
        external
        payable
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultStrategy(DCS_STRATEGY_ID, vaultAddress)
    {
        CegaGlobalStorage storage cgs = getStorage();
        uint256 nativeValueReceived = DCSLogic.swapAndSettleVault(
            cgs,
            vaultAddress,
            swapProtocol,
            swapData,
            treasury,
            addressManager
        );
        Transfers.receiveNativeValue(nativeValueReceived);
    }

    function dcsCheckAuctionDefault(
        address vaultAddress
    )
        external
        nonReentrant
        onlyIfNotPaused
        onlyValidVaultStrategy(DCS_STRATEGY_ID, vaultAddress)
    {
        CegaGlobalStorage storage cgs = getStorage();
        DCSLogic.checkAuctionDefault(cgs, vaultAddress);
    }

    function dcsRolloverVault(
        address vaultAddress,
        uint256 maxProcessCount
    )
        external
        nonReentrant
        onlyTraderAdmin
        onlyIfNotPaused
        onlyValidVaultStrategy(DCS_STRATEGY_ID, vaultAddress)
        returns (uint256 processCount)
    {
        CegaGlobalStorage storage cgs = getStorage();
        return
            DCSVaultLogic.rolloverVault(
                cgs,
                addressManager,
                treasury,
                vaultAddress,
                maxProcessCount
            );
    }

    function dcsSetIsPayoffInDepositAsset(
        address vaultAddress,
        bool newState
    )
        external
        onlyCegaAdmin
        onlyValidVaultStrategy(DCS_STRATEGY_ID, vaultAddress)
    {
        CegaGlobalStorage storage cgs = getStorage();
        cgs.dcsVaults[vaultAddress].isPayoffInDepositAsset = newState;

        emit DCSIsPayoffInDepositAssetUpdated(vaultAddress, newState);
    }
}
