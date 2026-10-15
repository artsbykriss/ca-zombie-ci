// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { VaultStatus } from "../../../Structs.sol";

interface IConfigurationEntry {
    // FUNCTIONS

    function setManagementFee(address vaultAddress, uint16 value) external;

    function setYieldFee(address vaultAddress, uint16 value) external;

    function setProductName(uint32 productId, string calldata name) external;

    function setTradeWinnerNftImage(
        uint32 productId,
        string calldata imageUrl
    ) external;

    function setIsDefaulted(address vaultAddress, bool newState) external;

    function setBondAllowList(address receiver, bool value) external;

    /**
     * @notice Opens a vault for deposits.
     * @param vaultAddress The address of the vault to open.
     */
    function openVaultDeposits(address vaultAddress) external;

    /**
     * @notice Opens batch of vaults for deposits
     * @param vaultAddresses Aaddresses of vaults to open
     */
    function bulkOpenVaultDeposits(address[] calldata vaultAddresses) external;

    /**
     * @notice Sets the status of a vault.
     * @param vaultAddress The address of the vault.
     * @param _vaultStatus The new status to set for the vault.
     */
    function setVaultStatus(
        address vaultAddress,
        VaultStatus _vaultStatus
    ) external;

    /**
     * @notice Overrides the oracle price for a specific timestamp in a vault.
     * @param vaultAddress The address of the vault.
     * @param timestamp The timestamp for which to override the price.
     * @param newPrice The new price to set.
     */
    function overrideOraclePrice(
        address vaultAddress,
        address asset,
        uint40 timestamp,
        uint128 newPrice
    ) external;

    /**
     * @notice Set if the whole protocol is paused
     * @param value The boolean value
     */
    function setIsProtocolPaused(bool value) external;
}
