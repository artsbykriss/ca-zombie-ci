// SPDX-License-Identifier: MIT
pragma solidity >=0.8.29;

import { LibBit } from "solady/src/utils/LibBit.sol";

import { IOrdersManager } from "src/interfaces/order-book/IOrdersManager.sol";

import { WideOrderId } from "src/libraries/types/WideOrderId.sol";

/// @notice A 40-bit packed resting order identifier encoding owner, side, and open-order slot.
/// @dev Bit layout (LSB to MSB):
///      ┌──────┬──────────────────────┬───────────┐
///      │ S(1) │     ownerKey (32)    │  slot(7)  │
///      └──────┴──────────────────────┴───────────┘
///        [0]     [32:1]                [39:33]
///      The rest bit is NOT stored here; it is inserted at bit 0 when widening to WideOrderId.
type RestingOrderId is uint40;

/// @title LibRestingOrderId
/// @notice Encoding and decoding utilities for the RestingOrderId packed type
library LibRestingOrderId {
    /// @notice Thrown when the bitmap is full (all 128 slots occupied)
    error OpenOrdersOverflow();

    /// @dev Bit mask for the 7-bit slot field
    uint40 private constant SLOT_MASK = 0x7F;

    /// @notice Encodes a resting order ID by finding the first free slot in the bitmap
    /// @dev Scans the inverted bitmap for the first zero bit (free slot) via LibBit.ffs,
    ///      then packs side, userId, and the slot into a 40-bit ID.
    ///      Reverts if all 128 slots are occupied.
    /// @param userId The 32-bit owner key
    /// @param side The order side (Buy or Sell)
    /// @param bitmap The 128-bit open-order bitmap (bit i set = slot i occupied)
    /// @return The packed RestingOrderId
    function encode(
        uint32 userId,
        IOrdersManager.OrderSide side,
        uint128 bitmap
    ) internal pure returns (RestingOrderId) {
        uint256 slot = LibBit.ffs(~uint256(bitmap) & type(uint128).max);
        require(slot < 128, OpenOrdersOverflow());
        return encodeWithSlot(userId, side, slot);
    }

    /// @notice Packs a resting order ID from a known slot index (no bitmap scan)
    /// @dev Used when the slot is already known (e.g., reconstructing from a bitmap iteration).
    /// @param userId The 32-bit owner key
    /// @param side The order side (Buy or Sell)
    /// @param slot The 0-indexed slot (0-127)
    /// @return The packed RestingOrderId
    function encodeWithSlot(
        uint32 userId,
        IOrdersManager.OrderSide side,
        uint256 slot
    ) internal pure returns (RestingOrderId) {
        return RestingOrderId.wrap(
            // forge-lint: disable-next-line(unsafe-typecast)
            uint40(uint8(side)) | uint40(userId) << 1 | (uint40(slot) & SLOT_MASK) << 33
        );
    }

    /// @notice Extracts the 32-bit owner key from a resting order ID
    /// @param self The packed resting order ID
    /// @return The owner key (userId)
    function getOwner(
        RestingOrderId self
    ) internal pure returns (uint32) {
        // forge-lint: disable-next-line(unsafe-typecast)
        return uint32(RestingOrderId.unwrap(self) >> 1);
    }

    /// @notice Extracts the order side from a resting order ID
    /// @param self The packed resting order ID
    /// @return The order side (Buy or Sell)
    function getSide(
        RestingOrderId self
    ) internal pure returns (IOrdersManager.OrderSide) {
        // forge-lint: disable-next-line(unsafe-typecast)
        return IOrdersManager.OrderSide(uint8(RestingOrderId.unwrap(self) & 1));
    }

    /// @notice Widens the 40-bit resting order ID to a WideOrderId
    /// @dev Inserts the rest bit at bit 0 by shifting left 1 and setting bit 0 = 1.
    /// @param self The packed resting order ID
    /// @return The WideOrderId representation (with rest bit set)
    function toWideOrderId(
        RestingOrderId self
    ) internal pure returns (WideOrderId) {
        return WideOrderId.wrap(uint56(RestingOrderId.unwrap(self)) << 1 | 1);
    }

    /// @notice Extracts the 7-bit open-order slot index from a resting order ID
    /// @param self The packed resting order ID
    /// @return The slot index (0-127)
    function getOpenOrderIndex(
        RestingOrderId self
    ) internal pure returns (uint8) {
        // forge-lint: disable-next-line(unsafe-typecast)
        return uint8(RestingOrderId.unwrap(self) >> 33);
    }
}

using LibRestingOrderId for RestingOrderId global;
