// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { CegaGlobalStorage } from "../../storage/CegaStorage.sol";
import { EntryBase } from "../common/EntryBase.sol";
import { IAddressManager } from "../../aux/interfaces/IAddressManager.sol";

import { SFN_STRATEGY_ID, Vault } from "../../Structs.sol";
import { SFNProduct, SFNVault } from "./SFNStructs.sol";
import { ISFNViewEntry } from "./interfaces/ISFNViewEntry.sol";
import { SFNVaultLogic } from "./lib/SFNVaultLogic.sol";
import { VaultLogic } from "../common/lib/VaultLogic.sol";

contract SFNViewEntry is ISFNViewEntry, EntryBase {
    // CONSTRUCTOR

    constructor(IAddressManager _addressManager) EntryBase(_addressManager) {}

    // FUNCTIONS

    function sfnGetProduct(
        uint32 productId
    )
        external
        view
        onlyValidProductStrategy(SFN_STRATEGY_ID, productId)
        returns (SFNProduct memory)
    {
        CegaGlobalStorage storage cgs = getStorage();
        return cgs.sfnProducts[productId];
    }

    function sfnGetProductDepositAsset(
        uint32 productId
    )
        external
        view
        onlyValidProductStrategy(SFN_STRATEGY_ID, productId)
        returns (address)
    {
        return getStorage().sfnProducts[productId].underlyingAsset;
    }

    function sfnGetVault(
        address vaultAddress
    )
        external
        view
        onlyValidVaultStrategy(SFN_STRATEGY_ID, vaultAddress)
        returns (SFNVault memory)
    {
        CegaGlobalStorage storage cgs = getStorage();
        return cgs.sfnVaults[vaultAddress];
    }

    function sfnCalculateVaultFinalPayoff(
        address vaultAddress
    )
        external
        view
        onlyValidVaultStrategy(SFN_STRATEGY_ID, vaultAddress)
        returns (uint128)
    {
        CegaGlobalStorage storage cgs = getStorage();
        return
            SFNVaultLogic.calculateVaultFinalPayoff(
                cgs,
                addressManager,
                vaultAddress
            );
    }

    function sfnGetCouponPayment(
        address vaultAddress
    )
        external
        view
        onlyValidVaultStrategy(SFN_STRATEGY_ID, vaultAddress)
        returns (uint128)
    {
        CegaGlobalStorage storage cgs = getStorage();

        return SFNVaultLogic.getVaultCouponPayment(cgs, vaultAddress);
    }

    function sfnCalculateVaultSettlementAmount(
        address vaultAddress
    )
        external
        view
        onlyValidVaultStrategy(SFN_STRATEGY_ID, vaultAddress)
        returns (uint128)
    {
        CegaGlobalStorage storage cgs = getStorage();
        return
            SFNVaultLogic.calculateVaultSettlementAmount(
                cgs,
                addressManager,
                vaultAddress
            );
    }

    function sfnCalculateLateFee(
        address vaultAddress
    )
        external
        view
        onlyValidVaultStrategy(SFN_STRATEGY_ID, vaultAddress)
        returns (uint128)
    {
        CegaGlobalStorage storage cgs = getStorage();
        return SFNVaultLogic.calculateLateFee(cgs, vaultAddress);
    }
}
