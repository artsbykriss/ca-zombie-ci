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
import {IConfidentialERC20} from "../../token/interfaces/IConfidentialERC20.sol";

/// @dev Interface for a converter that shields an ERC-20 token into a {IConfidentialERC20} token.
interface IConfidentialERC20Converter is IConfidentialERC20 {
    /// @dev Emitted when an unshield request is opened for `receiver`.
    event UnshieldRequested(address indexed receiver, bytes32 indexed unshieldRequestId, ve_uint64 amount);

    /// @dev Emitted once an unshield request is settled and the cleartext amount is known.
    event UnshieldFinalized(
        address indexed receiver,
        bytes32 indexed unshieldRequestId,
        ve_uint64 encryptedAmount,
        uint64 cleartextAmount
    );

    /**
     * @dev Shields `amount` of the underlying token into confidential form and credits `to`.
     *
     * Returns the encrypted amount credited.
     */
    function shield(address to, uint256 amount) external payable returns (ve_uint64);

    /**
     * @dev Opens an unshield of an encrypted input taken from `from` and destined to `to`. Caller must be
     * `from` or an operator for `from`.
     *
     * Returns the unshield request id, which is guaranteed to be non-zero.
     */
    function unshield(address from, address to, uve_uint64 calldata encryptedAmount) external payable returns (bytes32);

    /// @dev Address of the underlying ERC-20 token being converted.
    function underlying() external view returns (address);

    /// @dev Settles an open unshield request `unshieldRequestId` with its `cleartextAmount` and a `decryptionProof`.
    function finalizeUnshield(
        bytes32 unshieldRequestId,
        uint64 cleartextAmount,
        bytes calldata decryptionProof
    ) external;

    /**
     * @dev Returns `true` if the unshield request `unshieldRequestId` has been settled (the underlying tokens have
     * been released and the request record deleted). Returns `false` if the request is still pending.
     *
     * NOTE: Also returns `false` for non-existent request ids — callers that track request creation externally
     * (e.g. by holding the request id returned from {unshield}) can still rely on this.
     */
    function isUnshieldSettled(bytes32 unshieldRequestId) external view returns (bool);

    /**
     * @dev Conversion rate between underlying and confidential units. A `rate` of 1000 means 1000 underlying
     * units correspond to a single confidential unit.
     */
    function rate() external view returns (uint256);
}
