// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.29;

/// @notice OrderRequest.flags bit constants
/// @dev Mirrors the adapter connector's flags layout
library OrderFlags {
    uint32 constant POST_ONLY = 1 << 0;
    uint32 constant REDUCE_ONLY = 1 << 1;
}

/// @notice Margin mode for RISEx positions
enum MarginMode {
    Cross,
    Isolated
}

/// @notice Position data structure from RISEx (new field order)
/// @dev Returned by adapter.getPosition() as abi-encoded bytes.
///      Field order: size, quoteAmount, lastFundingPayment, leverage, marginMode, isolatedUsdcBalance
struct Position {
    int128 size;
    int128 quoteAmount;
    int128 lastFundingPayment;
    uint16 leverage;
    MarginMode marginMode;
    int128 isolatedUsdcBalance;
}
