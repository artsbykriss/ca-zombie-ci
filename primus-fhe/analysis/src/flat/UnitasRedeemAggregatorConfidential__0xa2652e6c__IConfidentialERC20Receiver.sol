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

/// @dev Callback interface for contracts that want to react to an incoming confidential transfer.
interface IConfidentialERC20Receiver {
    /**
     * @dev Invoked when a confidential transfer reaches this contract. Returns an encrypted boolean
     * signaling whether the transfer is accepted. A `false` result asks the token to refund the sender.
     *
     * WARNING: never refund manually and also return false — that would refund twice.
     */
    function onConfidentialTransferReceived(
        address operator,
        address from,
        ve_uint64 amount,
        bytes calldata data
    ) external returns (ve_bool);
}
