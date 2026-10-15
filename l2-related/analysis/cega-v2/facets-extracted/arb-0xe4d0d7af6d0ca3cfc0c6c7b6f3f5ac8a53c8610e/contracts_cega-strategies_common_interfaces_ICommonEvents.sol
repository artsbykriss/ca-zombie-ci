// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import {
    VaultStatus,
    OldVaultStatus,
    RotationStrategy
} from "../../../Structs.sol";

interface ICommonEvents {
    event DepositQueued(
        uint32 indexed productId,
        address sender,
        address receiver,
        uint128 amount
    );

    event DepositRemoved(
        uint32 indexed productId,
        address depositor,
        uint128 amount
    );

    event DepositProcessed(
        address indexed vaultAddress,
        address receiver,
        uint128 amount
    );

    event WithdrawalQueued(
        address indexed vaultAddress,
        uint256 sharesAmount,
        address owner,
        uint32 nextProductId,
        bool withProxy
    );

    event WithdrawalProcessed(
        address indexed vaultAddress,
        uint256 sharesAmount,
        address owner,
        uint32 nextProductId
    );

    event CommonVaultStatusUpdated(
        address indexed vaultAddress,
        VaultStatus vaultStatus
    );

    event VaultDefaultUpdated(address indexed vaultAddress, bool value);

    event OraclePriceOverriden(
        address indexed vaultAddress,
        address indexed asset,
        uint256 timestamp,
        uint256 newPrice
    );

    event ManagementFeeUpdated(address indexed vaultAddress, uint16 value);

    event YieldFeeUpdated(address indexed vaultAddress, uint16 value);

    event ProductNameUpdated(uint32 indexed productId, string name);

    event TradeWinnerNftImageUpdated(uint32 indexed productId, string imageUrl);

    event UserRotationStrategySet(
        address indexed user,
        uint32 indexed productId,
        RotationStrategy rotationStrategy
    );

    event UserAssetsRotated(
        address indexed vaultAddress,
        address indexed user,
        uint128 amount,
        RotationStrategy rotationStrategy
    );

    event UserAddedIntoVaultRotationList(
        address indexed user,
        address indexed vaultAddress
    );

    // Legacy event, left for compatibility

    event VaultStatusUpdated(
        address indexed vaultAddress,
        OldVaultStatus vaultStatus
    );

    event BondAllowListUpdated(address indexed receiver, bool value);
}
