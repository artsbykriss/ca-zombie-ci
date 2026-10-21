// SPDX-License-Identifier: MIT
pragma solidity >=0.8.29;

import { IOrdersManager } from "src/interfaces/order-book/IOrdersManager.sol";

import { LibTransientOrderBookCache } from "src/libraries/order-book/LibTransientOrderBookCache.sol";
import { WideOrderId } from "src/libraries/types/WideOrderId.sol";

/// @notice A 56-bit packed ephemeral order identifier encoding owner, side, and a transient nonce.
/// @dev Bit layout (LSB to MSB):
///      ┌──────┬──────────────────────┬──────────────┐
///      │ S(1) │     ownerKey (32)    │  nonce(20)   │
///      └──────┴──────────────────────┴──────────────┘
///        [0]     [32:1]                [52:33]
///      The rest bit is NOT stored here; it is inserted at bit 0 when widening to WideOrderId.
///      Bits [55:53] are unused.
type EphemeralOrderId is uint56;

/// @title LibEphemeralOrderId
/// @notice Encoding and decoding utilities for the EphemeralOrderId packed type
library LibEphemeralOrderId {
    /// @dev Bit mask for the 20-bit nonce field
    uint56 private constant NONCE_MASK = 0xFFFFF;

    /// @notice Encodes an ephemeral order ID, incrementing the transient nonce for the given market
    /// @dev The nonce is auto-incremented per marketId via transient storage.
    /// @param userId The 32-bit owner key
    /// @param side The order side (Buy or Sell)
    /// @param marketId The market ID (used to scope the transient nonce counter)
    /// @return The packed EphemeralOrderId
    function encode(
        uint32 userId,
        IOrdersManager.OrderSide side,
        uint16 marketId
    ) internal returns (EphemeralOrderId) {
        uint32 nonce = LibTransientOrderBookCache.nextNonce(marketId);
        return EphemeralOrderId.wrap(
            // forge-lint: disable-next-line(unsafe-typecast)
            uint56(uint8(side)) | uint56(userId) << 1 | (uint56(nonce) & NONCE_MASK) << 33
        );
    }

    /// @notice Extracts the 32-bit owner key from an ephemeral order ID
    /// @param self The packed ephemeral order ID
    /// @return The owner key (userId)
    function getOwner(
        EphemeralOrderId self
    ) internal pure returns (uint32) {
        // forge-lint: disable-next-line(unsafe-typecast)
        return uint32(EphemeralOrderId.unwrap(self) >> 1);
    }

    /// @notice Extracts the order side from an ephemeral order ID
    /// @param self The packed ephemeral order ID
    /// @return The order side (Buy or Sell)
    function getSide(
        EphemeralOrderId self
    ) internal pure returns (IOrdersManager.OrderSide) {
        // forge-lint: disable-next-line(unsafe-typecast)
        return IOrdersManager.OrderSide(uint8(EphemeralOrderId.unwrap(self) & 1));
    }

    /// @notice Widens the ephemeral order ID to a WideOrderId
    /// @dev Inserts the rest bit at bit 0 by shifting left 1 (bit 0 = 0, marking ephemeral).
    /// @param self The packed ephemeral order ID
    /// @return The WideOrderId representation (with rest bit clear)
    function toWideOrderId(
        EphemeralOrderId self
    ) internal pure returns (WideOrderId) {
        return WideOrderId.wrap(EphemeralOrderId.unwrap(self) << 1);
    }

    /// @notice Extracts the 20-bit nonce from an ephemeral order ID
    /// @param self The packed ephemeral order ID
    /// @return The nonce value
    function getNonce(
        EphemeralOrderId self
    ) internal pure returns (uint32) {
        // forge-lint: disable-next-line(unsafe-typecast)
        return uint32((EphemeralOrderId.unwrap(self) >> 33) & NONCE_MASK);
    }
}

using LibEphemeralOrderId for EphemeralOrderId global;
