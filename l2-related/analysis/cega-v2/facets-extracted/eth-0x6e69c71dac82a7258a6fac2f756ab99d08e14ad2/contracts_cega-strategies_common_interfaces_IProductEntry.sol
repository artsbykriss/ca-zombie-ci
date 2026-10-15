// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { RotationStrategyParams } from "../../../Structs.sol";

interface IProductEntry {
    function setUserRotationStrategies(
        RotationStrategyParams[] calldata rotationStrategyParams,
        address[] calldata vaultAddresses
    ) external;

    function addToDepositQueue(
        uint32 productId,
        uint128 amount,
        address receiver
    ) external payable;

    function addToDepositQueueAndSetRotationStrategies(
        uint32 productId,
        uint128 amount,
        address receiver,
        RotationStrategyParams[] calldata rotationStrategyParams
    ) external payable;

    function removeFromDepositQueue(uint32 productId, uint128 amount) external;

    function addToWithdrawalQueue(
        address vaultAddress,
        uint128 sharesAmount,
        uint32 nextProductId
    ) external;

    function addToWithdrawalQueueWithProxy(
        address vaultAddress,
        uint128 sharesAmount
    ) external;
}
