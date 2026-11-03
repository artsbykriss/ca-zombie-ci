// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// AP-13746 APX V2 offline clearing: admin clears leftover positions and limit orders on behalf of users.
// Normally a position/order can only be closed/cancelled by its holder; this interface opens a door under
// admin privilege to bulk-handle unclaimed leftovers during decommissioning. Funds are always returned to
// the real holder of the position/order (not the caller).
interface IOfflineClear {

    // Admin-triggered close: registers a CLOSE price request per tradeHash; a normal PRICE_FEEDER feed then
    // settles it via the existing closeTradeCallback. Nonexistent positions (margin==0) are silently skipped.
    event AdminCloseTradeRequested(address indexed operator, bytes32 indexed tradeHash, address indexed user);
    // Admin-triggered cancel: cancels a limit order and refunds the principal to its owner. Nonexistent
    // orders are silently skipped.
    event AdminCancelLimitOrder(address indexed operator, bytes32 indexed orderHash);

    function closeTradeByAdmin(bytes32[] calldata tradeHashes) external;

    function cancelLimitOrderByAdmin(bytes32[] calldata orderHashes) external;
}
