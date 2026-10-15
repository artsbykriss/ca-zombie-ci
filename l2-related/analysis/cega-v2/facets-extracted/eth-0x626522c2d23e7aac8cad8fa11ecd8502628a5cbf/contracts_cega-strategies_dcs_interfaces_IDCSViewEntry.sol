// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { Withdrawer } from "../../../Structs.sol";
import { DCSProduct, DCSVault } from "../DCSStructs.sol";

interface IDCSViewEntry {
    /**
     * @dev Retrieves detailed information about a specific DCS product.
     * @param productId The product ID.
     * @return DCSProduct Struct containing detailed information about the product.
     */
    function dcsGetProduct(
        uint32 productId
    ) external view returns (DCSProduct memory);

    /**
     * @dev Retrieves the deposit asset address for a specific product.
     * @param productId The product ID.
     * @return address Address of the deposit asset.
     */
    function dcsGetProductDepositAsset(
        uint32 productId
    ) external view returns (address);

    /**
     * @dev Calculates the final payoff for a specific vault.
     * @param vaultAddress The vault address.
     * @return uint128 The calculated final payoff amount.
     */
    function dcsCalculateVaultFinalPayoff(
        address vaultAddress
    ) external view returns (uint128);

    /**
     * @notice Retrieves the details of a specific vault.
     * @param vaultAddress The address of the vault to retrieve.
     * @return A struct containing details of the vault.
     */
    function dcsGetVault(
        address vaultAddress
    ) external view returns (DCSVault memory);

    /**
     * @notice Calculates the late fee for a specific vault.
     * @param vaultAddress The address of the vault.
     * @return The calculated late fee.
     */
    function dcsCalculateLateFee(
        address vaultAddress
    ) external view returns (uint128);

    /**
     * @notice Retrieves the coupon payment for a specific vault.
     * @param vaultAddress The address of the vault.
     * @return The amount of the coupon payment.
     */
    function dcsGetCouponPayment(
        address vaultAddress
    ) external view returns (uint128);

    /**
     * @notice Retrieves the settlement asset for a specific vault.
     * @param vaultAddress The address of the vault.
     * @return The address of the settlement asset.
     */
    function dcsGetVaultSettlementAsset(
        address vaultAddress
    ) external view returns (address);
}
