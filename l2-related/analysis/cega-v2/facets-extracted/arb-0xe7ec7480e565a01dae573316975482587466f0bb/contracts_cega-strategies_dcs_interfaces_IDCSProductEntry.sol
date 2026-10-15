// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import {
    Withdrawer,
    VaultStatus,
    RotationStrategyParams
} from "../../../Structs.sol";
import { DCSProductCreationParams, DCSProduct } from "../DCSStructs.sol";
import {
    IOracleEntry
} from "../../../oracle-entry/interfaces/IOracleEntry.sol";

interface IDCSProductEntry {
    // FUNCTIONS

    /**
     * @dev Creates a new DCS product with the given parameters.
     * @param creationParams The parameters required for creating a new DCS product.
     * @return uint32 The ID of the newly created product.
     */
    function dcsCreateProduct(
        DCSProductCreationParams calldata creationParams
    ) external returns (uint32);

    /**
     * @dev Adds an amount to the deposit queue for a specified product.
     * @param productId The ID of the product for which the deposit is being made.
     * @param amount The amount to be deposited.
     * @param receiver The address that will receive the deposit.
     */
    function dcsAddToDepositQueue(
        uint32 productId,
        uint128 amount,
        address receiver
    ) external payable;

    function dcsAddToDepositQueueAndSetRotationStrategies(
        uint32 productId,
        uint128 amount,
        address receiver,
        RotationStrategyParams[] memory rotationStrategyParams
    ) external payable;

    function dcsRemoveFromDepositQueue(
        uint32 productId,
        uint128 amount
    ) external;

    /**
     * @dev Processes the deposit queue for a specific vault, up to a maximum count of deposits.
     * @param vault The address of the vault for which to process deposits.
     * @param maxProcessCount The maximum number of deposits to process.
     */
    function dcsProcessDepositQueue(
        address vault,
        uint256 maxProcessCount
    ) external;

    /**
     * @dev Adds a request to the withdrawal queue for a specific vault.
     * @param vault The address of the vault.
     * @param sharesAmount The amount of shares to withdraw.
     * @param nextProductId The product ID for the next investment cycle, if applicable.
     */
    function dcsAddToWithdrawalQueue(
        address vault,
        uint128 sharesAmount,
        uint32 nextProductId
    ) external;

    /**
     * @dev Adds a request to the withdrawal queue with proxy for a specific vault.
     * @param vaultAddress The address of the vault.
     * @param sharesAmount The amount of shares to withdraw.
     */
    function dcsAddToWithdrawalQueueWithProxy(
        address vaultAddress,
        uint128 sharesAmount
    ) external;

    /**
     * @dev Processes the withdrawal queue for a specific vault, up to a maximum count of withdrawals.
     * @param vault The address of the vault for which to process withdrawals.
     * @param maxProcessCount The maximum number of withdrawals to process.
     */
    function dcsProcessWithdrawalQueue(
        address vault,
        uint256 maxProcessCount
    ) external;

    /**
     * @dev Checks and handles trade expiry for a specific vault.
     * @param vaultAddress The address of the vault to check for trade expiry.
     */
    function dcsCheckTradeExpiry(address vaultAddress) external;

    /**
     * @dev Checks and handles settlement default for a specific vault.
     * @param vaultAddress The address of the vault to check for settlement default.
     */
    function dcsCheckSettlementDefault(address vaultAddress) external;

    /**
     * @dev Collects fees from a specific vault.
     * @param vaultAddress The address of the vault from which to collect fees.
     */
    function dcsCollectVaultFees(address vaultAddress) external;

    /**
     * @dev Submits a dispute for a specific vault.
     * @param vaultAddress The address of the vault for which to submit a dispute.
     */
    function dcsSubmitDispute(address vaultAddress) external;

    /**
     * @dev Processes a trade dispute for a specific vault, potentially adjusting the price.
     * @param vaultAddress The address of the vault for which to process the dispute.
     * @param newPrice The new price to be considered in resolving the dispute.
     */
    function dcsProcessTradeDispute(
        address vaultAddress,
        uint128 newPrice
    ) external;
}
