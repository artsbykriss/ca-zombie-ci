// SPDX-License-Identifier: MIT
pragma solidity >=0.8.29;

import { IOrdersManager } from "src/interfaces/order-book/IOrdersManager.sol";
import { EphemeralOrderId } from "src/libraries/types/EphemeralOrderId.sol";
import { RestingOrderId } from "src/libraries/types/RestingOrderId.sol";

/// @notice A 56-bit unified order identifier that can represent either a resting or ephemeral order.
/// @dev Layout (LSB to MSB):
///      ┌─────────┬──────┬──────────────────────┬─────────────────────┐
///      │ rest(1) │ S(1) │     ownerKey (32)    │  slot/nonce (20-7)  │
///      └─────────┴──────┴──────────────────────┴─────────────────────┘
///        [0]       [1]     [33:2]                [40:34] or [53:34]
///      The rest bit (bit 0) distinguishes resting (1) from ephemeral (0) orders.
///      Neither RestingOrderId nor EphemeralOrderId stores the rest bit;
///      it is inserted/removed during conversion.
type WideOrderId is uint56;

/// @title LibWideOrderId
/// @notice Conversion and field extraction utilities for the WideOrderId unified type
library LibWideOrderId {
    /// @notice Thrown when converting to RestingOrderId but rest bit is 0
    error NotRestingOrder();

    /// @notice Thrown when converting to EphemeralOrderId but rest bit is 1
    error NotEphemeralOrder();

    /// @dev The rest bit (bit 0)
    uint56 private constant REST_BIT = 0x01;

    /// @notice Extracts the 32-bit owner key from a wide order ID
    /// @dev Works for both resting and ephemeral variants — bits [33:2] are always ownerKey
    /// @param self The wide order ID
    /// @return The owner key (userId)
    function getOwner(
        WideOrderId self
    ) internal pure returns (uint32) {
        // forge-lint: disable-next-line(unsafe-typecast)
        return uint32(WideOrderId.unwrap(self) >> 2);
    }

    /// @notice Extracts the order side from a wide order ID
    /// @dev Works for both resting and ephemeral variants — bit [1] is always the side bit
    /// @param self The wide order ID
    /// @return The order side (Buy or Sell)
    function getSide(
        WideOrderId self
    ) internal pure returns (IOrdersManager.OrderSide) {
        // forge-lint: disable-next-line(unsafe-typecast)
        return IOrdersManager.OrderSide(uint8((WideOrderId.unwrap(self) >> 1) & 1));
    }

    /// @notice Checks whether this wide order ID represents a resting order
    /// @param self The wide order ID
    /// @return True if the rest bit (bit 0) is set
    function isRestingOrder(
        WideOrderId self
    ) internal pure returns (bool) {
        return WideOrderId.unwrap(self) & REST_BIT != 0;
    }

    /// @notice Converts to a RestingOrderId, reverting if the rest bit is not set
    /// @dev Removes the rest bit by shifting right 1, yielding the compact 40-bit layout.
    /// @param self The wide order ID
    /// @return The RestingOrderId (rest bit removed, 40-bit compact layout)
    function toRestingOrderId(
        WideOrderId self
    ) internal pure returns (RestingOrderId) {
        require(WideOrderId.unwrap(self) & REST_BIT != 0, NotRestingOrder());
        // forge-lint: disable-next-line(unsafe-typecast)
        return RestingOrderId.wrap(uint40(WideOrderId.unwrap(self) >> 1));
    }

    /// @notice Converts to an EphemeralOrderId, reverting if the rest bit is set
    /// @dev Removes the rest bit by shifting right 1, yielding the compact layout.
    /// @param self The wide order ID
    /// @return The EphemeralOrderId (rest bit removed, compact layout)
    function toEphemeralOrderId(
        WideOrderId self
    ) internal pure returns (EphemeralOrderId) {
        require(WideOrderId.unwrap(self) & REST_BIT == 0, NotEphemeralOrder());
        // forge-lint: disable-next-line(unsafe-typecast)
        return EphemeralOrderId.wrap(uint56(WideOrderId.unwrap(self) >> 1));
    }
}

using LibWideOrderId for WideOrderId global;
