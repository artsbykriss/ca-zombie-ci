// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title IOracleSink
 * @author ether.fi
 * @notice Destination-chain LayerZero receiver that exposes relayed prices in a
 *         Chainlink-compatible shape so the existing {PriceProvider} can read them
 *         via its standard `isChainlinkType` config branch.
 */
interface IOracleSink {
    /**
     * @notice Per-token latest relayed price
     * @param price Normalised USD price with {DECIMALS} precision (6)
     * @param updatedAt Block timestamp (on this chain) when the update was received
     * @param srcUpdatedAt Source-chain timestamp the relay stamped when it read the price;
     *        used to reject out-of-order / replayed-late updates so a stale price can never
     *        overwrite a newer one. Packs into the same slot as `updatedAt`.
     */
    struct PricePoint {
        uint256 price;
        uint64 updatedAt;
        uint64 srcUpdatedAt;
    }

    /// @notice Emitted when a relayed price update is stored
    /// @param srcTimestamp Source-chain timestamp the relay stamped when it read the price. Included so
    ///        off-chain consumers can order updates by source time (multiple relayed messages for the
    ///        same token can be executed in one destination transaction, so `updatedAt` alone is ambiguous).
    event PriceUpdated(address indexed token, uint256 price, uint64 updatedAt, uint64 srcTimestamp);
    /// @notice Emitted when the per-token max staleness window is configured
    event MaxStalenessSet(address indexed token, uint64 maxStaleness);
    /// @notice Emitted when a stored price is cleared by an admin
    event PriceCleared(address indexed token);

    /// @notice Thrown when a token has never received a relayed price
    error PriceNotSet();
    /// @notice Thrown when the last relayed price for a token is older than its max staleness window
    error PriceStale();
    /// @notice Thrown when a zero address is supplied where it is not allowed
    error InvalidToken();

    /**
     * @notice Returns the latest relayed price for `token` in {DECIMALS} precision
     * @param token Token to query
     * @return price Normalised USD price (6 decimals)
     * @return srcUpdatedAt Source-chain timestamp the relay stamped when it read the price (the
     *         same basis {price} measures staleness against, not the delivery time)
     */
    function getPrice(address token) external view returns (uint256 price, uint64 srcUpdatedAt);

    /**
     * @notice Returns the latest relayed price for `token` as a single value, reverting if stale.
     * @dev Designed for direct consumption by {PriceProvider} via its calldata branch:
     *      configure `isChainlinkType = false`, `dataType = Uint256`, `oraclePriceDecimals = 6`,
     *      `oracle = address(thisSink)` and
     *      `priceFunctionCalldata = abi.encodeWithSelector(IOracleSink.price.selector, token)`.
     *      Freshness is enforced here against the source-chain read time ({PricePoint.srcUpdatedAt}),
     *      not the relay-delivery time, so a message that was delayed in transit cannot present a
     *      stale price as fresh. No per-token Chainlink adapter is required. Fail-closed: a non-zero
     *      {maxStaleness} for the token must be set first, otherwise {price} reverts {PriceStale}.
     * @param token Token to query
     * @return Normalised USD price (6 decimals)
     */
    function price(address token) external view returns (uint256);

    /**
     * @notice Clears the stored price for `token`, reverting future {price}/{latestRoundData} reads
     *         to {PriceNotSet} until a fresh update arrives.
     * @dev Admin-gated. Intended as the destination-side counterpart to {IPriceRelay.unsubscribe}:
     *      unsubscribing on the source chain stops future relays but does not erase the last value
     *      here. Note a relay message already in flight can still repopulate the entry, so pair this
     *      with {setMaxStaleness}(token, 0) when delisting to keep reads fail-closed.
     * @param token Token whose stored price should be cleared
     */
    function clearPrice(address token) external;

    /**
     * @notice Sets the maximum age (in seconds) of a relayed price before {price} reverts.
     * @dev Admin-gated. Fail-closed: while the window is 0 (unconfigured) {price} reverts
     *      {PriceStale}, so a token must be given a non-zero window before it can be consumed.
     *      The window is measured from the relay's source-chain read time, and the feed the relay
     *      read may itself already be up to the source-side staleness bound old, so the two windows
     *      compound; see {OracleSink.setMaxStaleness} for the sizing rule.
     * @param token Token to configure
     * @param maxStaleness Max age in seconds; 0 leaves the token fail-closed (no price served)
     */
    function setMaxStaleness(address token, uint64 maxStaleness) external;

    /**
     * @notice Returns the configured max staleness window (seconds) for `token` (0 = fail-closed)
     * @param token Token to query
     */
    function maxStaleness(address token) external view returns (uint64);

    /**
     * @notice Chainlink AggregatorV3-style accessor consumed by {PriceProvider}
     * @dev `token` is supplied by the caller because a single sink serves many tokens.
     *      `roundId` and `answeredInRound` are always 0 (single-feed semantics).
     * @param token Token to query
     * @return roundId Always 0
     * @return answer USD price (6 decimals) as int256
     * @return startedAt Same as `updatedAt`
     * @return updatedAt Source-chain timestamp the relay stamped when it read the price, so a
     *         Chainlink-shaped consumer's own staleness check measures source age, not delivery time
     * @return answeredInRound Always 0
     */
    function latestRoundData(address token) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    /**
     * @notice Decimal precision of all prices exposed by this sink
     * @return Always 6 (matches {PriceProvider}.DECIMALS)
     */
    function decimals() external pure returns (uint8);
}
