// SPDX-License-Identifier: MIT
pragma solidity >=0.8.29;

import { LibTransient } from "solady/src/utils/LibTransient.sol";

/// @title LibTransientOrderBookCache
/// @notice Transient storage cache for per-market ephemeral order nonces.
/// @dev Maintains a monotonically increasing nonce per marketId within a single transaction.
///      Nonces auto-reset across transactions (transient storage property).
///      Slot layout: NONCE_BASE_SLOT + uint256(marketId) -> uint256 counter
library LibTransientOrderBookCache {
    using LibTransient for LibTransient.TUint256;

    /// @dev keccak256("orderBook.transient.cache.nonce")
    uint256 private constant NONCE_BASE_SLOT = 0xf62dcec28967078c11ded705129f354ea2960beac31390f865957b3c24aa2e14;

    /// @notice Returns the current nonce for a market and increments it
    /// @dev Uses transient storage so the counter resets each transaction.
    ///      Supports multicall by keying on marketId.
    /// @param marketId The market ID to scope the nonce
    /// @return nonce The nonce value before incrementing
    function nextNonce(
        uint16 marketId
    ) internal returns (uint32 nonce) {
        // forge-lint: disable-next-line(unsafe-typecast)
        nonce = uint32(LibTransient.tUint256(NONCE_BASE_SLOT + uint256(marketId)).inc() - 1);
    }
}
