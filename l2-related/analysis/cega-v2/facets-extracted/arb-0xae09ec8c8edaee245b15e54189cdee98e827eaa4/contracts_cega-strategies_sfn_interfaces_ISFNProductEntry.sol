// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { VaultCreationParams } from "../../../Structs.sol";
import { SFNProductCreationParams } from "../SFNStructs.sol";

interface ISFNProductEntry {
    function sfnCreateProduct(
        SFNProductCreationParams calldata creationParams
    ) external returns (uint32);

    function sfnCreateVault(
        uint32 productId,
        VaultCreationParams calldata creationParams
    ) external returns (address vaultAddress);

    function sfnAddToDepositQueue(
        uint32 productId,
        uint128 amount,
        address receiver
    ) external payable;

    function sfnRemoveFromDepositQueue(
        uint32 productId,
        uint128 amount
    ) external;

    function sfnProcessDepositQueue(
        address vaultAddress,
        uint256 maxProcessCount
    ) external;

    function sfnAddToWithdrawalQueue(
        address vaultAddress,
        uint128 sharesAmount,
        uint32 nextProductId
    ) external;

    function sfnAddToWithdrawalQueueWithProxy(
        address vaultAddress,
        uint128 sharesAmount
    ) external;

    function sfnProcessWithdrawalQueue(
        address vaultAddress,
        uint256 maxProcessCount
    ) external;
}
