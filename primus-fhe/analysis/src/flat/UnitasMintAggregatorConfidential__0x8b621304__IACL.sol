// SPDX-License-Identifier: BSD-3-Clause-Clear
// ===== THIRD-PARTY NOTICE — DO NOT EDIT BY HAND =====
//
// Portions derived from zama-ai/fhevm. Copyright © 2025 ZAMA. All rights reserved.
// Modifications Copyright © 2026 Primus Labs.
// Full license terms: see the BSD-3-Clause-Clear notice included in this source distribution.
//
// ===== END THIRD-PARTY NOTICE =====
pragma solidity ^0.8.24;

enum PermissionType {
    // Grants persistent access to a ciphertext for a specific address.
    Persistent,
    // Grants temporary access to a ciphertext for the duration of a single transaction.
    Transient,
    // Grants decryption rights.
    Decryptable
}

interface IACL {
    /**
     * @notice Allows the use of handle for the address account.
     */
    function accessPolicy(bytes32 handle, address account, PermissionType pt) external;
    function accessPolicy(bytes32 handle, address account) external;

    /**
     * @notice Allows a list of handles to be decrypted.
     */
    function allowForDecryption(bytes32[] memory handlesList) external;
    // function allowForDecryption(bytes32 handle) external;
    // function allowForDecryption(bytes32 handle, address account) external;

    /**
     * @notice Removes the transient allowances.
     */
    function cleanTransientStorage() external;

    /**
     * @notice Returns whether the account is allowed to use the handle.
     */
    function isAllowed(bytes32 handle, address account) external view returns (bool);

    /**
     * @notice Returns wether a handle is allowed to be publicly decrypted.
     */
    function isAllowedForDecryption(bytes32 handle) external view returns (bool);
    function isAllowedForDecryption(bytes32 handle, address account) external view returns (bool);
}
