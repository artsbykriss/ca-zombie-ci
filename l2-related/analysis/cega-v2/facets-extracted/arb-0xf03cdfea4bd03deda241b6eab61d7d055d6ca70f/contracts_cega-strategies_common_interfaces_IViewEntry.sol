// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import {
    Vault,
    Withdrawer,
    ProductMetadata,
    RotationStrategy
} from "../../../Structs.sol";

interface IViewEntry {
    function getVaultUsersWithRotations(
        address vaultAddress
    ) external view returns (address[] memory);

    function getUserRotationStrategy(
        address user,
        uint32 productId
    ) external view returns (RotationStrategy memory);

    function getIsUserAddedToVaultRotationList(
        address user,
        address vaultAddress
    ) external view returns (bool);

    function getOraclePriceOverride(
        address vaultAddress,
        uint40 timestamp
    ) external view returns (uint128);

    function getVault(
        address vaultAddress
    ) external view returns (Vault memory);

    function getVaultProductId(address vault) external view returns (uint32);

    function getIsAuctionDefaulted(
        address vaultAddress
    ) external view returns (bool);

    function getHoursLate(address vaultAddress) external view returns (uint256);

    function totalAssets(address vaultAddress) external view returns (uint256);

    function convertToAssets(
        address vaultAddress,
        uint256 shares
    ) external view returns (uint128);

    function convertToShares(
        address vaultAddress,
        uint128 assets
    ) external view returns (uint256);

    /**
     * @dev Gets the withdrawal queue for a specific vault, including withdrawers and their amounts.
     * @param vaultAddress The vault address.
     * @return withdrawers Array of withdrawer data.
     * @return amounts Array of withdrawal amounts.
     * @return withProxy Array indicating if withdrawals are with proxy.
     * @return totalAmount Total amount in the withdrawal queue.
     */
    function getWithdrawalQueue(
        address vaultAddress
    )
        external
        view
        returns (
            Withdrawer[] memory withdrawers,
            uint256[] memory amounts,
            bool[] memory withProxy,
            uint256 totalAmount
        );

    /**
     * @dev Checks if withdrawal is possible for a specific vault.
     * @param vaultAddress The vault address.
     * @return bool True if withdrawal is possible, false otherwise.
     */
    function isWithdrawalPossible(
        address vaultAddress
    ) external view returns (bool);

    function getStrategyOfProduct(
        uint32 productId
    ) external view returns (uint32);

    function getProductDepositAsset(
        uint32 productId
    ) external view returns (address);

    function getLatestProductId() external view returns (uint32);

    function getProductMetadata(
        uint32 productId
    ) external view returns (ProductMetadata memory);

    function getIsProtocolPaused() external view returns (bool);

    /**
     * @dev Gets the deposit queue for a specific product, including depositors and their amounts.
     * @param productId The product ID.
     * @return depositors Array of depositor addresses.
     * @return amounts Array of deposit amounts.
     * @return totalAmount Total amount in the deposit queue.
     */
    function getDepositQueue(
        uint32 productId
    )
        external
        view
        returns (
            address[] memory depositors,
            uint128[] memory amounts,
            uint128 totalAmount
        );

    function getBondAllowList(address receiver) external view returns (bool);

    function calculateVaultFinalPayoff(
        address vaultAddress
    ) external view returns (uint128);

    function getVaultSettlementAsset(
        address vaultAddress
    ) external view returns (address);

    function calculateLateFee(
        address vaultAddress
    ) external view returns (uint128);

    function getCouponPayment(
        address vaultAddress
    ) external view returns (uint128);

    function calculateVaultSettlementAmount(
        address vaultAddress
    ) external view returns (uint128);
}
