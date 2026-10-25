// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

import {State} from "./State.sol";
import {IUpgradeController} from "./upgrade/IUpgradeController.sol";

/**
 * @title NullmaskEventMigration
 * @notice One-shot UUPS migration contract to re-emit legacy Shielded* events in the new format.
 * @dev Deployed as a UUPS implementation upgrade so events emit from the proxy address.
 *      The protocol is paused while this implementation is active (no deposit/transfer/withdraw).
 *      After migration, upgrade back to the latest Nullmask implementation.
 *
 *      Legacy events used (noteNullifier1, noteNullifier2) and had no noteFeeChangeCommitment.
 *      New events use a single nullifiersHash (computed client-side as poseidon2_2)
 *      and include noteFeeChangeCommitment (set to bytes32(0) for migrated events).
 */
contract NullmaskEventMigration is State, Initializable, UUPSUpgradeable {
    error NotAdmin(address caller);
    error UpgradeNotAuthorized(address caller);

    modifier onlyAdmin() {
        if (!IUpgradeController(upgradeController).canUpgrade(msg.sender, address(0)))
            revert NotAdmin(msg.sender);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // ---- New-format events (mirrors Nullmask.sol) ----

    event ShieldedTransfer(
        bytes32 indexed txNullifier,
        bytes32 nullifiersHash,
        bytes32 noteOutCommitment,
        bytes32 noteChangeCommitment,
        bytes32 noteFeeChangeCommitment,
        uint256 fee,
        address feeTokenAddress
    );

    event ShieldedWithdrawal(
        bytes32 indexed txNullifier,
        bytes32 nullifiersHash,
        bytes32 noteChangeCommitment,
        bytes32 noteFeeChangeCommitment,
        address recipientAddress,
        uint256 amount,
        address tokenAddress,
        uint256 fee,
        address feeTokenAddress
    );

    event ShieldedSwap(
        bytes32 indexed txNullifier,
        bytes32 nullifiersHash,
        bytes32 noteOutCommitment,
        bytes32 noteChangeCommitment,
        bytes32 noteFeeChangeCommitment,
        uint256 amountIn,
        address tokenIn,
        uint256 amountOut,
        address tokenOut,
        uint256 fee,
        address feeTokenAddress
    );

    // ---- Batch re-emit functions ----

    struct TransferData {
        bytes32 txNullifier;
        bytes32 nullifiersHash;
        bytes32 noteOutCommitment;
        bytes32 noteChangeCommitment;
        uint256 fee;
        address feeTokenAddress;
    }

    function reemitShieldedTransfers(TransferData[] calldata data) external onlyAdmin {
        for (uint256 i; i < data.length;) {
            emit ShieldedTransfer(
                data[i].txNullifier,
                data[i].nullifiersHash,
                data[i].noteOutCommitment,
                data[i].noteChangeCommitment,
                bytes32(0),
                data[i].fee,
                data[i].feeTokenAddress
            );
            unchecked { ++i; }
        }
    }

    struct WithdrawalData {
        bytes32 txNullifier;
        bytes32 nullifiersHash;
        bytes32 noteChangeCommitment;
        address recipientAddress;
        uint256 amount;
        address tokenAddress;
        uint256 fee;
        address feeTokenAddress;
    }

    function reemitShieldedWithdrawals(WithdrawalData[] calldata data) external onlyAdmin {
        for (uint256 i; i < data.length;) {
            emit ShieldedWithdrawal(
                data[i].txNullifier,
                data[i].nullifiersHash,
                data[i].noteChangeCommitment,
                bytes32(0),
                data[i].recipientAddress,
                data[i].amount,
                data[i].tokenAddress,
                data[i].fee,
                data[i].feeTokenAddress
            );
            unchecked { ++i; }
        }
    }

    struct SwapData {
        bytes32 txNullifier;
        bytes32 nullifiersHash;
        bytes32 noteOutCommitment;
        bytes32 noteChangeCommitment;
        uint256 amountIn;
        address tokenIn;
        uint256 amountOut;
        address tokenOut;
        uint256 fee;
        address feeTokenAddress;
    }

    function reemitShieldedSwaps(SwapData[] calldata data) external onlyAdmin {
        for (uint256 i; i < data.length;) {
            emit ShieldedSwap(
                data[i].txNullifier,
                data[i].nullifiersHash,
                data[i].noteOutCommitment,
                data[i].noteChangeCommitment,
                bytes32(0),
                data[i].amountIn,
                data[i].tokenIn,
                data[i].amountOut,
                data[i].tokenOut,
                data[i].fee,
                data[i].feeTokenAddress
            );
            unchecked { ++i; }
        }
    }

    // ---- UUPS ----

    function _authorizeUpgrade(address newImpl) internal view override {
        if (!IUpgradeController(upgradeController).canUpgrade(msg.sender, newImpl))
            revert UpgradeNotAuthorized(msg.sender);
    }
}
