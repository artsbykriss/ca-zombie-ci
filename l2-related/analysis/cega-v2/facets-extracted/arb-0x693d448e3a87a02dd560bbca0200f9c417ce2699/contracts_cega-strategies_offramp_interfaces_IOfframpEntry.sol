// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.24;

import { OfframpOrder, OfframpOrderData } from "../../../Structs.sol";

interface IOfframpEntry {
    // EVENTS

    /**
     * @notice Emitted when offramp fee is updated
     * @param offrampFeeBps New fee BPS value
     */
    event OfframpFeeBpsUpdated(uint16 offrampFeeBps);

    /**
     * @notice Emitted when order gets cancelled
     * @param maker Maker of the order
     * @param orderHash Hash of the order
     */
    event OrderCancelled(address indexed maker, bytes32 indexed orderHash);

    /**
     * @notice Emitted when order gets filled
     * @param maker Maker of the order
     * @param taker Taker of the order
     * @param orderHash Hash of the order
     * @param makerAsset Asset transferred from maker to taker
     * @param takerAsset Asset transferred from taker to maker
     * @return makingAmount Actual amount transferred from maker to taker
     * @return takingAmount Actual amount transferred from taker to maker
     */
    event OrderFilled(
        address indexed maker,
        address indexed taker,
        bytes32 indexed orderHash,
        address makerAsset,
        address takerAsset,
        uint256 makingAmount,
        uint256 takingAmount
    );

    // FUNCTIONS

    /**
     * @notice Returns order hash, hashed with limit order protocol contract EIP712
     * @param order Order
     * @return orderHash Hash of the order
     */
    function hashOrder(
        OfframpOrder calldata order
    ) external view returns (bytes32 orderHash);

    /**
     * @notice Gets offramp fee BPS
     * @return Offramp fee BPS
     */
    function getOfframpFeeBps() external view returns (uint16);

    /**
     * @notice Gets execution data for order
     * @param maker Maker of the order
     * @param orderHash Hash of the order
     * @return Offramp order data
     */
    function getOrderData(
        address maker,
        bytes32 orderHash
    ) external view returns (OfframpOrderData memory);

    /**
     * @notice Updates offramp fee (only cega admin)
     * @param offrampFeeBps New offramp fee BPS
     */
    function setOfframpFeeBps(uint16 offrampFeeBps) external;

    /**
     * @notice Cancels order's quote
     * @param orderHash Hash of the order to cancel
     */
    function cancelOrder(bytes32 orderHash) external;

    /**
     * @notice Fills order's quote, fully or partially (whichever is possible).
     * @param order Order quote to fill
     * @param makerSig Maker's signature for order
     * @param swapMakingAmount Making amount to fill
     * @return swapTakingAmount Actual amount transferred from taker to maker
     * @return orderHash Hash of the filled order
     */
    function fillOrder(
        OfframpOrder calldata order,
        bytes calldata makerSig,
        uint256 swapMakingAmount
    ) external payable returns (uint256 swapTakingAmount, bytes32 orderHash);
}
