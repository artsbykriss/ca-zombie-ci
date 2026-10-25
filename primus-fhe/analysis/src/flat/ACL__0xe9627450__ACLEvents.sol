// SPDX-License-Identifier: BSD-3-Clause-Clear
// ===== THIRD-PARTY NOTICE — DO NOT EDIT BY HAND =====
//
// Portions derived from zama-ai/fhevm. Copyright © 2025 ZAMA. All rights reserved.
// Modifications Copyright © 2026 Primus Labs.
// Full license terms: see the BSD-3-Clause-Clear notice included in this source distribution.
//
// ===== END THIRD-PARTY NOTICE =====
pragma solidity ^0.8.24;

contract ACLEvents {
    /// @notice Emitted when a handle is allowed.
    event Allowed(address indexed caller, address indexed account, bytes32 handle);

    /// @notice Emitted when a list of handles is allowed for public decryption.
    event AllowedForDecryption(address indexed caller, bytes32[] handlesList);
}
