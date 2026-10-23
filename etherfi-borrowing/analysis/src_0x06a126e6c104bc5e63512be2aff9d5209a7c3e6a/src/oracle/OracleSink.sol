// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { OAppCoreUpgradeable } from "@layerzerolabs/oapp-evm-upgradeable/contracts/oapp/OAppCoreUpgradeable.sol";
import { OAppReceiverUpgradeable, Origin } from "@layerzerolabs/oapp-evm-upgradeable/contracts/oapp/OAppReceiverUpgradeable.sol";

import { IOracleSink } from "../interfaces/IOracleSink.sol";
import { UpgradeableProxy } from "../utils/UpgradeableProxy.sol";

/**
 * @title OracleSink
 * @author ether.fi
 * @notice Destination-chain LayerZero receiver. Stores the latest relayed
 *         per-token USD price (6 decimals) and exposes it to the OP-side
 *         {PriceProvider} in two ways:
 *           1. Directly (no adapter) via {price}, read through PriceProvider's
 *              calldata branch. Freshness is enforced here against the
 *              source-chain read time using a per-token {maxStaleness}.
 *           2. Through a per-token Chainlink-shaped adapter over
 *              {latestRoundData}, read via PriceProvider's `isChainlinkType` branch.
 * @dev The relay stamps each message with the source-chain time it read the price
 *      ({srcTimestamp}) and that value is the freshness signal here: {price} reverts
 *      once the source read is older than {maxStaleness}, regardless of when the
 *      LayerZero message was actually delivered. This closes the window where a
 *      delayed/backlogged message could otherwise present a stale price as fresh.
 *      The relay-delivery time ({PricePoint.updatedAt}) is still recorded for
 *      observability but no longer gates reads.
 */
contract OracleSink is IOracleSink, UpgradeableProxy, OAppReceiverUpgradeable {
    /// @custom:storage-location erc7201:etherfi.storage.OracleSink
    struct OracleSinkStorage {
        /// @notice Latest stored price per token
        mapping(address token => PricePoint) latest;
        /// @notice Max age (seconds) of a relayed price before {price} reverts (0 = disabled)
        mapping(address token => uint64) maxStaleness;
    }

    // keccak256(abi.encode(uint256(keccak256("etherfi.storage.OracleSink")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant OracleSinkStorageLocation = 0x3e8ab8ffffa6cdbcb3cadbd9bce96c661061ed9516d20cf2ac88617c984e9200;

    /// @notice Matches {PriceProvider}.DECIMALS — kept here for the
    ///         Chainlink-shaped `decimals()` accessor.
    uint8 public constant DECIMALS = 6;

    /// @notice Role required to configure per-token staleness windows
    bytes32 public constant ORACLE_SINK_ADMIN_ROLE = keccak256("ORACLE_SINK_ADMIN_ROLE");

    /// @notice Thrown when constructor or initializer receives a zero address
    error InvalidAddress();

    /**
     * @dev Constructor fixes the LZ endpoint for this sink (one per chain).
     * @param _lzEndpoint LayerZero endpoint on the destination chain
     */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address _lzEndpoint) OAppCoreUpgradeable(_lzEndpoint) {
        if (_lzEndpoint == address(0)) revert InvalidAddress();
        _disableInitializers();
    }

    /**
     * @notice Initializer
     * @param _roleRegistry RoleRegistry contract
     * @param _delegate LayerZero delegate / OApp owner (e.g. protocol multisig)
     */
    function initialize(address _roleRegistry, address _delegate) external initializer {
        if (_roleRegistry == address(0) || _delegate == address(0)) revert InvalidAddress();
        __UpgradeableProxy_init(_roleRegistry);
        __Ownable_init(_delegate);
        __OAppReceiver_init(_delegate);
    }

    /**
     * @notice Raw read of the latest stored price and its source read time, with no freshness or pause gate.
     * @dev Reverts {PriceNotSet} if `token` never received a relayed price. Use {price} for a
     *      freshness-checked read; this accessor is for off-chain inspection/monitoring. Returns the
     *      source-chain read time ({PricePoint.srcUpdatedAt}), the same basis {price} measures
     *      staleness against, not the delivery time. Note this is the time the relay read the price
     *      on the source chain, not the time the underlying feed produced it.
     * @param token Token to query
     * @return Normalised USD price ({DECIMALS} precision, 6)
     * @return Source-chain timestamp the relay stamped when it read the price
     */
    function getPrice(address token) external view returns (uint256, uint64) {
        PricePoint memory p = _getStorage().latest[token];
        if (p.updatedAt == 0) revert PriceNotSet();
        return (p.price, p.srcUpdatedAt);
    }

    /**
     * @notice Latest price for `token`, reverting unless it is both set and fresh.
     * @dev The freshness-checked read consumed by {PriceProviderV2}'s calldata branch. Reverts when
     *      `token` has no price ({PriceNotSet}) or when the price is stale ({PriceStale}). Staleness is
     *      measured against the source-chain read time via the per-token {maxStaleness}, so a delayed
     *      LayerZero message cannot present a stale price as fresh. Fail-closed: an unconfigured (0)
     *      staleness window serves no price.
     *
     *      Not gated by {whenNotPaused}: reads stay available while the sink is paused so a pause never
     *      freezes liquidations across every sink-priced asset. Pause gates only the write paths
     *      ({_lzReceive}, and {IPriceRelay.poke} on the source), so a paused sink stops ingesting new
     *      prices but keeps serving the last fresh one until it ages out. To fail-close a single
     *      compromised feed, use {clearPrice} + {setMaxStaleness}(token, 0) rather than a global pause.
     * @param token Token to query
     * @return Normalised USD price (6 decimals)
     */
    function price(address token) external view returns (uint256) {
        OracleSinkStorage storage $ = _getStorage();
        PricePoint memory p = $.latest[token];
        if (p.updatedAt == 0) revert PriceNotSet();

        // Fail-closed: an unconfigured staleness window (0) serves no price, matching the rest of
        // cash-v3 ("zero means blocked") and PriceProviderV2's MaxStalenessCannotBeZero guard.
        uint64 maxStaleness_ = $.maxStaleness[token];
        if (maxStaleness_ == 0) revert PriceStale();
        // Measure age from the source-chain read time, not the delivery time, so a delayed
        // LayerZero message cannot serve a stale price as fresh for a full maxStaleness window.
        if (block.timestamp > uint256(p.srcUpdatedAt) + maxStaleness_) revert PriceStale();

        return p.price;
    }

    /**
     * @notice Clears the stored price for `token`, so reads revert {PriceNotSet} until a fresh update lands.
     * @dev Restricted to {ORACLE_SINK_ADMIN_ROLE}; the destination-side counterpart to
     *      {IPriceRelay.unsubscribe}. A relay message already in flight can still repopulate the entry,
     *      so pair this with {setMaxStaleness}(token, 0) when delisting to keep reads fail-closed.
     * @param token Token whose stored price is cleared
     */
    function clearPrice(address token) external onlyRole(ORACLE_SINK_ADMIN_ROLE) {
        if (token == address(0)) revert InvalidToken();
        delete _getStorage().latest[token];
        emit PriceCleared(token);
    }

    /**
     * @notice Sets the max age (seconds) of a price before {price}/{latestRoundData} treat it as stale.
     * @dev Restricted to {ORACLE_SINK_ADMIN_ROLE}. Fail-closed: while 0 (unconfigured) {price} reverts
     *      {PriceStale}, so a token must be given a non-zero window before it can be consumed.
     *
     *      Sizing: the window starts at the relay's read time, and the Chainlink answer it read may
     *      already be up to the source-side feed `maxStaleness` old, so worst-case data age served
     *      here is the sum of the two windows. Set this window to the total age budget minus the
     *      source feed's bound, but above the pathway's worst-case delivery latency so an in-transit
     *      message does not expire on arrival.
     * @param token Token to configure
     * @param maxStaleness_ Max age in seconds; 0 leaves the token fail-closed (no price served)
     */
    function setMaxStaleness(address token, uint64 maxStaleness_) external onlyRole(ORACLE_SINK_ADMIN_ROLE) {
        if (token == address(0)) revert InvalidToken();
        _getStorage().maxStaleness[token] = maxStaleness_;
        emit MaxStalenessSet(token, maxStaleness_);
    }

    /**
     * @notice Returns the configured max staleness window (seconds) for `token` (0 = fail-closed).
     * @param token Token to query
     * @return Configured window in seconds
     */
    function maxStaleness(address token) external view returns (uint64) {
        return _getStorage().maxStaleness[token];
    }

    /**
     * @notice Chainlink AggregatorV3-style accessor for `token`, consumed by {PriceProviderV2}'s
     *         `isChainlinkType` branch.
     * @dev Reverts when `token` has no price ({PriceNotSet}). Reports the source-chain read time as
     *      `startedAt`/`updatedAt` so a consumer's own staleness check measures source age, not delivery
     *      time. `roundId`/`answeredInRound` are always 0 (single-feed semantics). Not gated by
     *      {whenNotPaused} for the same reason as {price}: a pause must not freeze reads, so it gates
     *      only the write paths. Note this accessor does not itself apply {maxStaleness}; the consumer's
     *      own staleness check does.
     * @param token Token to query
     * @return roundId Always 0
     * @return answer USD price (6 decimals) as int256
     * @return startedAt Source-chain read time
     * @return updatedAt Source-chain read time
     * @return answeredInRound Always 0
     */
    function latestRoundData(address token) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) {
        PricePoint memory p = _getStorage().latest[token];
        if (p.updatedAt == 0) revert PriceNotSet();
        // Report the source-chain read time so a Chainlink-shaped consumer's own staleness
        // check measures source age rather than delivery time.
        return (0, int256(p.price), p.srcUpdatedAt, p.srcUpdatedAt, 0);
    }

    /**
     * @notice Decimal precision of all prices exposed by this sink.
     * @return Always 6 (matches {PriceProviderV2}.DECIMALS)
     */
    function decimals() external pure returns (uint8) {
        return DECIMALS;
    }

    /**
     * @dev LayerZero callback. Decodes the relay payload and stores the
     *      per-token updates. The peer/origin authentication ("only the mainnet
     *      {PriceRelay} can write here") is already enforced upstream in
     *      {OAppReceiverUpgradeable.lzReceive} via the `OnlyPeer` check, so this
     *      function trusts `_message` once invoked.
     *
     *      Payload schema (must match {PriceRelay.poke}):
     *      `abi.encode(address[] tokens, uint256[] prices, uint64 srcTimestamp)`.
     *      `updatedAt` is stamped with the destination-chain `block.timestamp`
     *      (the time the price became readable here) so the OP-side
     *      {PriceProvider} staleness check measures local arrival, not source time.
     *
     *      LayerZero V2 execution is unordered and a verified message can be (re)executed
     *      by anyone, so messages can arrive out of send-order. The relay-stamped
     *      `srcTimestamp` is therefore enforced as a strictly-increasing per-token sequence:
     *      an update whose `srcTimestamp` is not newer than the stored one is skipped, so a
     *      stale (older or replayed) price can never overwrite a newer one.
     * @param _message Encoded relay payload
     */
    function _lzReceive(Origin calldata, bytes32, bytes calldata _message, address, bytes calldata) internal virtual override whenNotPaused {
        (address[] memory tokens, uint256[] memory prices, uint64 srcTimestamp) = abi.decode(_message, (address[], uint256[], uint64));

        OracleSinkStorage storage $ = _getStorage();
        uint64 nowTs = uint64(block.timestamp);
        uint256 len = tokens.length;
        for (uint256 i = 0; i < len;) {
            // Reject out-of-order / replayed-late updates: only accept a strictly newer source time.
            if (srcTimestamp > $.latest[tokens[i]].srcUpdatedAt) {
                $.latest[tokens[i]] = PricePoint(prices[i], nowTs, srcTimestamp);
                emit PriceUpdated(tokens[i], prices[i], nowTs, srcTimestamp);
            }
            unchecked {
                ++i;
            }
        }
    }

    function _getStorage() private pure returns (OracleSinkStorage storage $) {
        assembly {
            $.slot := OracleSinkStorageLocation
        }
    }
}
