// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2025 Flying Tulip Inc. All rights reserved.
pragma solidity ^0.8.30;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {
    Ownable2StepUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {Constants} from "../utils/Constants.sol";

/**
 * OracleRouter (Chainlink passthrough, resilient)
 *
 * - priceUSD(asset) -> USD WAD (1e18) using asset's Chainlink feed
 * - exchangeRate(st, base) -> base per st (WAD) using pair feed (or optional price-ratio fallback)
 * - snapshot(...) -> captures priceUSD() (and optional pairs) for MEV-resistant RFQ fills
 *
 * Safety:
 * - Per-asset heartbeat (staleness) checks
 * - Per-asset deviation caps vs lastGoodPrice (bps); falls back to lastGoodPrice instead of reverting
 * - Similar guards for exchangeRate pairs
 *
 * Notes:
 * - Feeds must be configured to return USD (8 decimals typical). If your feed is non-USD quoted,
 *   add a quote conversion hook or configure the correct USD feed.
 * - For pairs: if no dedicated pair feed, you can enable price-ratio fallback.
 */
interface AggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function decimals() external view returns (uint8);
}

contract OracleRouterChainlink is Initializable, UUPSUpgradeable, Ownable2StepUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    // Custom errors
    error NotGuardian();
    error PriceFeedDisabled();
    error AggregatorZeroAddress();
    error NegativePrice();
    error StalePrice();

    /*//////////////////////////////////////////////////////////////
                               ADMIN
    //////////////////////////////////////////////////////////////*/

    address public guardian;

    modifier onlyGuardianOrOwner() {
        _onlyGuardianOrOwner();
        _;
    }

    function _onlyGuardianOrOwner() internal view {
        if (msg.sender != guardian && msg.sender != owner()) revert NotGuardian();
    }

    event OwnerSet(address indexed o);
    event GuardianSet(address indexed g);

    function initialize(address _owner) external initializer {
        __UUPSUpgradeable_init();
        __Ownable_init(_owner);
        __Ownable2Step_init();
        guardian = _owner;
        emit OwnerSet(_owner);
        emit GuardianSet(_owner);
    }

    function setOwner(address o) external onlyOwner {
        transferOwnership(o);
        emit OwnerSet(o);
    }

    function setGuardian(address g) external onlyOwner {
        guardian = g;
        emit GuardianSet(g);
    }
    // UUPS upgrade authorization: owner-gated
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /*//////////////////////////////////////////////////////////////
                           PRICE FEEDS (USD)
    //////////////////////////////////////////////////////////////*/

    struct Feed {
        AggregatorV3Interface agg; // Chainlink aggregator
        uint256 lastGoodPriceWad; // stored anchor (WAD)
        uint32 heartbeat; // max staleness (seconds)
        uint16 deviationBps; // optional clamp vs lastGood (0 = disabled)
        bool enabled;
        bool fallbackOnStale; // if true, clamp to anchor on staleness when anchor != 0
    }

    mapping(address => Feed) public priceFeed;

    event PriceFeedSet(address indexed asset, address indexed agg, uint32 heartbeat, bool enabled);
    event PriceDeviationSet(address indexed asset, uint16 deviationBps);
    event PriceAnchorSet(address indexed asset, uint256 lastGoodPriceWad);
    event StaleFallbackSet(address indexed asset, bool enabled);

    function setPriceFeed(
        address asset,
        address agg,
        uint32 heartbeat,
        bool enabled
    )
        external
        onlyOwner
    {
        Feed storage f = priceFeed[asset];
        f.agg = AggregatorV3Interface(agg);
        f.heartbeat = heartbeat;
        f.enabled = enabled;
        emit PriceFeedSet(asset, agg, heartbeat, enabled);
    }

    function setPriceDeviation(address asset, uint16 deviationBps) external onlyOwner {
        priceFeed[asset].deviationBps = deviationBps;
        emit PriceDeviationSet(asset, deviationBps);
    }

    function setStaleFallback(address asset, bool enabled) external onlyOwner {
        priceFeed[asset].fallbackOnStale = enabled;
        emit StaleFallbackSet(asset, enabled);
    }

    // Set anchor from current feed (guardian/owner)
    function primeLastGoodPrice(address asset) external onlyGuardianOrOwner {
        Feed storage f = priceFeed[asset];
        if (!f.enabled) revert PriceFeedDisabled();
        uint256 px = _readChainlinkWad(f.agg, f.heartbeat);
        f.lastGoodPriceWad = px;
        emit PriceAnchorSet(asset, px);
    }

    // Emergency/manual anchor set
    function setLastGoodPrice(address asset, uint256 priceWad) external onlyGuardianOrOwner {
        priceFeed[asset].lastGoodPriceWad = priceWad;
        emit PriceAnchorSet(asset, priceWad);
    }

    /*//////////////////////////////////////////////////////////////
                           CORE: priceUSD / exchangeRate
    //////////////////////////////////////////////////////////////*/

    function priceUSD(address asset) public view returns (uint256 pxWad) {
        Feed storage f = priceFeed[asset];
        if (!f.enabled) revert PriceFeedDisabled();
        AggregatorV3Interface agg = f.agg;
        if (address(agg) == address(0)) revert AggregatorZeroAddress();

        (uint80 roundId, int256 ans,, uint256 updatedAt, uint80 answeredInRound) =
            agg.latestRoundData();
        if (ans <= 0) revert NegativePrice();
        if (answeredInRound < roundId || updatedAt == 0) revert StalePrice();

        // scale to 1e18
        uint256 u = uint256(ans);
        uint8 aggDecimals = agg.decimals();
        uint256 px = aggDecimals == 18
            ? u
            : (aggDecimals < 18 ? u * (10 ** (18 - aggDecimals)) : u / (10 ** (aggDecimals - 18)));

        // Staleness check with optional fallback to anchor
        if (block.timestamp - updatedAt > f.heartbeat) {
            uint256 anchorWad = f.lastGoodPriceWad;
            if (f.fallbackOnStale && anchorWad != 0) {
                return anchorWad;
            }
            revert StalePrice();
        }

        uint16 devBps = f.deviationBps;
        uint256 anchor = f.lastGoodPriceWad;
        if (devBps == 0 || anchor == 0) return px;
        uint256 diff = px > anchor ? (px - anchor) : (anchor - px);
        if (diff * Constants.BPS > anchor * devBps) {
            return anchor; // clamp to last good
        }
        return px;
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL HELPERS
    //////////////////////////////////////////////////////////////*/

    function _readChainlinkWad(
        AggregatorV3Interface agg,
        uint32 heartbeat
    )
        internal
        view
        returns (uint256)
    {
        if (address(agg) == address(0)) revert AggregatorZeroAddress();
        (uint80 roundId, int256 ans,, uint256 updatedAt, uint80 answeredInRound) =
            agg.latestRoundData();
        if (ans <= 0) revert NegativePrice();
        if (answeredInRound < roundId || updatedAt == 0) revert StalePrice();
        if (block.timestamp - updatedAt > heartbeat) revert StalePrice();

        // scale to 1e18
        uint256 u = uint256(ans);
        uint8 aggDecimals = agg.decimals();
        if (aggDecimals == 18) return u;
        if (aggDecimals < 18) {
            return u * (10 ** (18 - aggDecimals));
        } else {
            return u / (10 ** (aggDecimals - 18));
        }
    }

    /*//////////////////////////////////////////////////////////////
                          GUARDIAN CONTROLS
    //////////////////////////////////////////////////////////////*/

    // Quickly disable a feed (price or ER) if suspected compromise
    function disablePrice(address asset) external onlyGuardianOrOwner {
        Feed storage f = priceFeed[asset];
        f.enabled = false;
        emit PriceFeedSet(asset, address(f.agg), f.heartbeat, false);
    }
}
