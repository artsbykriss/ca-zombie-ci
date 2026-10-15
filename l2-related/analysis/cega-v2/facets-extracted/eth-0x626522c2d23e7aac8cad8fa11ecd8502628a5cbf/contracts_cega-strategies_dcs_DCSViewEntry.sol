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
    ProductMetadata,
    DCS_STRATEGY_ID
} from "../../Structs.sol";
import { DCSProduct, DCSVault } from "./DCSStructs.sol";
import { DCSVaultLogic } from "./lib/DCSVaultLogic.sol";
import { DCSLogic } from "./lib/DCSLogic.sol";
import { IDCSViewEntry } from "./interfaces/IDCSViewEntry.sol";
import { IAddressManager } from "../../aux/interfaces/IAddressManager.sol";
import { VaultLogic } from "../common/lib/VaultLogic.sol";
import { Errors } from "../../utils/Errors.sol";
import { EntryBase } from "../common/EntryBase.sol";

contract DCSViewEntry is EntryBase, IDCSViewEntry {
    // CONSTRUCTOR

    constructor(IAddressManager _addressManager) EntryBase(_addressManager) {}

    // FUNCTIONS

    function dcsGetProduct(
        uint32 productId
    )
        external
        view
        onlyValidProductStrategy(DCS_STRATEGY_ID, productId)
        returns (DCSProduct memory)
    {
        CegaGlobalStorage storage cgs = getStorage();
        return cgs.dcsProducts[productId];
    }

    function dcsGetProductDepositAsset(
        uint32 productId
    )
        external
        view
        onlyValidProductStrategy(DCS_STRATEGY_ID, productId)
        returns (address)
    {
        return
            DCSLogic.dcsGetProductDepositAsset(
                getStorage().dcsProducts[productId]
            );
    }

    function dcsCalculateVaultFinalPayoff(
        address vaultAddress
    )
        external
        view
        onlyValidVaultStrategy(DCS_STRATEGY_ID, vaultAddress)
        returns (uint128)
    {
        CegaGlobalStorage storage cgs = getStorage();
        return
            DCSLogic.calculateVaultFinalPayoff(
                cgs,
                addressManager,
                vaultAddress
            );
    }

    function dcsGetVault(
        address vaultAddress
    )
        external
        view
        onlyValidVaultStrategy(DCS_STRATEGY_ID, vaultAddress)
        returns (DCSVault memory)
    {
        CegaGlobalStorage storage cgs = getStorage();
        return cgs.dcsVaults[vaultAddress];
    }

    function dcsCalculateLateFee(
        address vaultAddress
    )
        external
        view
        onlyValidVaultStrategy(DCS_STRATEGY_ID, vaultAddress)
        returns (uint128)
    {
        CegaGlobalStorage storage cgs = getStorage();
        return DCSVaultLogic.calculateLateFee(cgs, vaultAddress);
    }

    function dcsGetCouponPayment(
        address vaultAddress
    )
        external
        view
        onlyValidVaultStrategy(DCS_STRATEGY_ID, vaultAddress)
        returns (uint128)
    {
        CegaGlobalStorage storage cgs = getStorage();
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];

        uint40 endDate = vault.tradeStartDate + dcsProduct.tenorInSeconds;

        return DCSVaultLogic.getCurrentYield(cgs, vaultAddress, endDate);
    }

    function dcsGetVaultSettlementAsset(
        address vaultAddress
    )
        external
        view
        onlyValidVaultStrategy(DCS_STRATEGY_ID, vaultAddress)
        returns (address)
    {
        CegaGlobalStorage storage cgs = getStorage();
        return DCSLogic.getVaultSettlementAsset(cgs, vaultAddress);
    }
}
