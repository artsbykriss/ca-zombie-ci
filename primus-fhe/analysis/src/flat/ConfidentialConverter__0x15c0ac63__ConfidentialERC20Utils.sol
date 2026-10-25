// SPDX-License-Identifier: MIT
// ===== THIRD-PARTY NOTICE — DO NOT EDIT BY HAND =====
//
// Portions derived from OpenZeppelin Confidential Contracts. Copyright (c) OpenZeppelin.
// Modifications Copyright (c) 2026 Primus Labs.
// Full license terms: see the MIT notice included in this source distribution.
//
// ===== END THIRD-PARTY NOTICE =====
pragma solidity ^0.8.27;

import "@primuslabs/fhe-contracts/contracts/lib/FHE.sol";

import {IConfidentialERC20Receiver} from "../token/interfaces/IConfidentialERC20Receiver.sol";
import {ConfidentialERC20Upgradeable} from "../token/ConfidentialERC20Upgradeable.sol";

/// @dev Shared helpers for {ConfidentialERC20Upgradeable}.
library ConfidentialERC20Utils {
    /**
     * @dev Runs the receiver callback on transfer target `to`. Meant to be called after any
     * transfer-with-callback on a {ConfidentialERC20Upgradeable}.
     *
     * The callback is skipped when `to` is an EOA (no code). A contract recipient must implement
     * {IConfidentialERC20Receiver-onConfidentialTransferReceived} and return a `ve_bool`; when that
     * result is `false`, the caller should refund `from`.
     */
    function checkOnTransferReceived(
        address operator,
        address from,
        address to,
        ve_uint64 amount,
        bytes calldata data
    ) internal returns (ve_bool) {
        if (to.code.length > 0) {
            try IConfidentialERC20Receiver(to).onConfidentialTransferReceived(operator, from, amount, data) returns (
                ve_bool retval
            ) {
                return retval;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ConfidentialERC20Upgradeable.ConfidentialERC20InvalidReceiver(to);
                } else {
                    assembly ("memory-safe") {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return FHE.asVEBool(true);
        }
    }
}
