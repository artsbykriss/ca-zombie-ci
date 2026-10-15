// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { CegaStorage } from "../../storage/CegaStorage.sol";
import { CegaGlobalStorage } from "../../Structs.sol";
import { IAddressManager } from "../../aux/interfaces/IAddressManager.sol";
import { IACLManager } from "../../aux/interfaces/IACLManager.sol";
import { Errors } from "../../utils/Errors.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract EntryBase is ReentrancyGuard, CegaStorage {
    // CONSTANTS & IMMUTABLE

    uint256 internal constant MAX_BPS = 1e4;

    IAddressManager internal immutable addressManager;

    // MODIFIERS

    modifier onlyCegaAdmin() {
        require(
            IACLManager(addressManager.getACLManager()).isCegaAdmin(msg.sender),
            Errors.NOT_CEGA_ADMIN
        );
        _;
    }

    modifier onlyTraderAdmin() {
        require(
            IACLManager(addressManager.getACLManager()).isTraderAdmin(
                msg.sender
            ),
            Errors.NOT_TRADER_ADMIN
        );
        _;
    }

    modifier onlyValidVault(address vaultAddress) {
        CegaGlobalStorage storage cgs = getStorage();
        require(cgs.vaults[vaultAddress].productId != 0, Errors.INVALID_VAULT);
        _;
    }

    modifier onlyIfNotPaused() {
        CegaGlobalStorage storage cgs = getStorage();
        require(cgs.protocolPauseConfig == 0, Errors.PROTOCOL_PAUSED);
        _;
    }

    modifier onlyValidProductStrategy(uint32 strategyId, uint32 productId) {
        CegaGlobalStorage storage cgs = getStorage();
        require(
            cgs.strategyOfProduct[productId] == strategyId,
            Errors.WRONG_STRATEGY
        );
        _;
    }

    modifier onlyValidVaultStrategy(uint32 strategyId, address vaultAddress) {
        CegaGlobalStorage storage cgs = getStorage();

        require(
            cgs.strategyOfProduct[cgs.vaults[vaultAddress].productId] ==
                strategyId,
            Errors.INVALID_VAULT
        );
        _;
    }

    modifier onlyValidVaultsStrategy(
        uint32 strategyId,
        address[] calldata vaultAddresses
    ) {
        CegaGlobalStorage storage cgs = getStorage();

        for (uint256 index = 0; index < vaultAddresses.length; index++) {
            require(
                cgs.strategyOfProduct[
                    cgs.vaults[vaultAddresses[index]].productId
                ] == strategyId,
                Errors.INVALID_VAULT
            );
        }
        _;
    }

    // CONSTRUCTOR

    constructor(IAddressManager _addressManager) {
        addressManager = _addressManager;
    }
}
