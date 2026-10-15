// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { IConfigurationEntry } from "./interfaces/IConfigurationEntry.sol";
import { EntryBase } from "./EntryBase.sol";
import { CegaStorage, CegaGlobalStorage } from "../../storage/CegaStorage.sol";
import { VaultStatus } from "../../Structs.sol";
import { IAddressManager } from "../../aux/interfaces/IAddressManager.sol";
import { Errors } from "../../utils/Errors.sol";
import { VaultLogic } from "./lib/VaultLogic.sol";
import { ICommonEvents } from "./interfaces/ICommonEvents.sol";

contract ConfigurationEntry is ICommonEvents, IConfigurationEntry, EntryBase {
    // CONSTRUCTOR

    constructor(IAddressManager _addressManager) EntryBase(_addressManager) {}

    // FUNCTIONS

    function setManagementFee(
        address vaultAddress,
        uint16 value
    ) external onlyTraderAdmin onlyValidVault(vaultAddress) onlyIfNotPaused {
        require(value <= MAX_BPS, Errors.VALUE_TOO_LARGE);

        CegaGlobalStorage storage cgs = getStorage();
        cgs.vaults[vaultAddress].managementFeeBps = value;

        emit ManagementFeeUpdated(vaultAddress, value);
    }

    function setYieldFee(
        address vaultAddress,
        uint16 value
    ) external onlyTraderAdmin onlyValidVault(vaultAddress) onlyIfNotPaused {
        require(value <= MAX_BPS, Errors.VALUE_TOO_LARGE);

        CegaGlobalStorage storage cgs = getStorage();
        cgs.vaults[vaultAddress].yieldFeeBps = value;

        emit YieldFeeUpdated(vaultAddress, value);
    }

    function setProductName(
        uint32 productId,
        string calldata name
    ) external onlyTraderAdmin onlyIfNotPaused {
        CegaGlobalStorage storage cgs = getStorage();
        cgs.productMetadata[productId].name = name;

        emit ProductNameUpdated(productId, name);
    }

    function setTradeWinnerNftImage(
        uint32 productId,
        string calldata imageUrl
    ) external onlyTraderAdmin onlyIfNotPaused {
        CegaGlobalStorage storage cgs = getStorage();
        cgs.productMetadata[productId].tradeWinnerNftImage = imageUrl;

        emit TradeWinnerNftImageUpdated(productId, imageUrl);
    }

    function setIsDefaulted(
        address vaultAddress,
        bool newState
    ) external onlyValidVault(vaultAddress) onlyCegaAdmin {
        CegaGlobalStorage storage cgs = getStorage();
        VaultLogic.setIsDefaulted(cgs, vaultAddress, newState);
    }

    function setBondAllowList(
        address receiver,
        bool value
    ) external onlyCegaAdmin {
        CegaGlobalStorage storage cgs = getStorage();

        cgs.bondAllowList[receiver] = value;

        emit BondAllowListUpdated(receiver, value);
    }

    function overrideOraclePrice(
        address vaultAddress,
        address asset,
        uint40 timestamp,
        uint128 newPrice
    ) external onlyCegaAdmin onlyValidVault(vaultAddress) {
        CegaGlobalStorage storage cgs = getStorage();
        require(newPrice != 0, Errors.VALUE_IS_ZERO);
        require(timestamp != 0, Errors.VALUE_IS_ZERO);

        VaultLogic.overrideOraclePrice(
            cgs,
            vaultAddress,
            asset,
            timestamp,
            newPrice
        );
    }

    function openVaultDeposits(
        address vaultAddress
    ) external onlyTraderAdmin onlyIfNotPaused {
        CegaGlobalStorage storage cgs = getStorage();
        VaultLogic.openVaultDeposits(cgs, vaultAddress);
    }

    function bulkOpenVaultDeposits(
        address[] calldata vaultAddresses
    ) external onlyTraderAdmin onlyIfNotPaused {
        CegaGlobalStorage storage cgs = getStorage();
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            VaultLogic.openVaultDeposits(cgs, vaultAddresses[i]);
        }
    }

    function setVaultStatus(
        address vaultAddress,
        VaultStatus _vaultStatus
    ) external onlyCegaAdmin {
        CegaGlobalStorage storage cgs = getStorage();
        VaultLogic.setVaultStatus(cgs, vaultAddress, _vaultStatus);
    }

    function setIsProtocolPaused(bool value) external onlyCegaAdmin {
        CegaGlobalStorage storage cgs = getStorage();
        cgs.protocolPauseConfig = value ? 1 : 0;
    }
}
