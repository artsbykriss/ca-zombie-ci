// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import {
    FCNProductCreationParams,
    FCNVaultCreationParams
} from "../FCNStructs.sol";

interface IFCNProductEntry {
    function fcnCreateProduct(
        FCNProductCreationParams calldata creationParams
    ) external returns (uint32);

    function fcnCreateVault(
        uint32 productId,
        FCNVaultCreationParams calldata creationParams
    ) external returns (address vaultAddress);

    function fcnAddToDepositQueue(
        uint32 productId,
        uint128 amount,
        address receiver
    ) external payable;

    function fcnRemoveFromDepositQueue(
        uint32 productId,
        uint128 amount
    ) external;

    function fcnProcessDepositQueue(
        address vaultAddress,
        uint256 maxProcessCount
    ) external;

    function fcnAddToWithdrawalQueue(
        address vaultAddress,
        uint128 sharesAmount,
        uint32 nextProductId
    ) external;

    function fcnAddToWithdrawalQueueWithProxy(
        address vaultAddress,
        uint128 sharesAmount
    ) external;

    function fcnProcessWithdrawalQueue(
        address vaultAddress,
        uint256 maxProcessCount
    ) external;
}
