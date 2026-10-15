// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../PriceOracle.sol";
import "../CToken.sol";
import "../CErc20.sol";

/**
 * @title ISupraSValueFeedStorage
 * @notice Minimal subset of the Supra SValueFeedStorage ABI consumed by the
 *         adapter. Supra writes prices to this contract via an off-chain
 *         keeper that periodically submits signed proofs to the `SupraOraclePull`
 *         verifier; once verified, prices are stored here and exposed via
 *         `getSvalue`.
 *
 *         IMPORTANT: `time` is reported in MILLISECONDS (Unix epoch * 1000),
 *         not seconds, so it must be divided by 1000 before comparing with
 *         `block.timestamp`.
 *
 *         `decimals` varies per pair (commonly 8 for USD-quoted assets, 18
 *         for native-token-quoted assets).
 *
 *         `price` is the raw price scaled by `10**decimals`.
 */
interface ISupraSValueFeedStorage {
    struct PriceData {
        uint256 round;
        uint256 decimals;
        uint256 time;
        uint256 price;
    }

    function getSvalue(uint256 _pairIndex) external view returns (PriceData memory);
}

/**
 * @title SupraPriceOracleAdapter
 * @notice Compound-compatible `PriceOracle` that fetches prices exclusively from
 *         the Supra SValueFeed push oracle deployed on IOTA EVM. Each market is
 *         routed to a single Supra `pairIndex` (configurable per underlying
 *         asset), with a per-asset staleness threshold.
 *
 *         The adapter is intentionally minimal:
 *         - No fallback. If Supra has not refreshed the configured pair within
 *           `maxStaleSec`, the call reverts. Compound then blocks risky
 *           operations rather than transacting on stale data.
 *         - Per-asset config is required: `getUnderlyingPrice` reverts for any
 *           cToken whose underlying has not been registered.
 *         - The owner may set a `underlyingOverride` to re-route a market to a
 *           different asset (e.g. for dIOTANative-style markets that do not
 *           expose `.underlying()` directly, or for migrations).
 *
 *         Decimals normalisation:
 *           Supra returns `price` scaled by `10 ** supraDec`. Compound expects
 *           a mantissa scaled by `10 ** (36 - underlyingDec)`. The adapter
 *           rescales as: `price * 10 ** (36 - underlyingDec - supraDec)` when
 *           the exponent is non-negative, otherwise the inverse division. For
 *           the assets in use on IOTA EVM (WETH/wIOTA 18 dec, USDC.e 6 dec)
 *           combined with Supra's 8 or 18 decimal feeds, the exponent is
 *           always >= 0.
 */
contract SupraPriceOracleAdapter is PriceOracle, Ownable {
    /// @notice Supra SValueFeedStorage instance (push oracle).
    ISupraSValueFeedStorage public supraStorage;

    struct AssetConfig {
        /// @notice True once `setAssetConfig` has been called for this asset.
        ///         Required because `pairIndex == 0` is a valid Supra pair
        ///         (BTC/USDT) and can't be used as a sentinel for "unset".
        bool    isSet;
        /// @notice Index into Supra's pair table for this asset.
        uint64  pairIndex;
        /// @notice Maximum age (in seconds) the Supra observation may have
        ///         before the adapter rejects it as stale.
        uint32  maxStaleSec;
    }

    /// @notice Per-underlying-asset Supra config.
    mapping(address => AssetConfig) public configs;

    /// @notice Optional override mapping a cToken to a custom asset address.
    ///         When set (non-zero), the adapter looks up Supra config under
    ///         this override rather than `CErc20(cToken).underlying()`.
    mapping(address => address) public underlyingOverride;

    event SupraStorageUpdated(address indexed oldStorage, address indexed newStorage);
    event AssetConfigSet(address indexed asset, uint64 indexed pairIndex, uint32 maxStaleSec);
    event AssetConfigUnset(address indexed asset);
    event UnderlyingOverrideSet(address indexed cToken, address indexed asset);

    constructor(address supraStorage_, address owner_) {
        require(supraStorage_ != address(0), "SupraOracle: zero storage");
        require(owner_        != address(0), "SupraOracle: zero owner");

        supraStorage = ISupraSValueFeedStorage(supraStorage_);
        emit SupraStorageUpdated(address(0), supraStorage_);

        if (owner_ != _msgSender()) {
            _transferOwnership(owner_);
        }
    }

    // ---------------------------------------------------------------------
    // PriceOracle interface
    // ---------------------------------------------------------------------

    /**
     * @notice Returns the underlying asset price for `cToken` as a Compound
     *         mantissa (scaled by `10 ** (36 - underlyingDecimals)`).
     * @dev    Reverts if the underlying is not configured, if Supra reports a
     *         zero price, or if the observation is older than `maxStaleSec`.
     */
    function getUnderlyingPrice(CToken cToken) external view override returns (uint256) {
        address asset = _assetFor(cToken);

        AssetConfig memory cfg = configs[asset];
        require(cfg.isSet, "SupraOracle: asset not configured");

        ISupraSValueFeedStorage.PriceData memory data =
            supraStorage.getSvalue(uint256(cfg.pairIndex));
        require(data.price > 0,                                            "SupraOracle: zero price");
        require(data.time > 0,                                             "SupraOracle: never updated");

        // Supra `time` is in milliseconds; convert to seconds.
        uint256 tsSec = data.time / 1000;
        require(block.timestamp <= tsSec + uint256(cfg.maxStaleSec),       "SupraOracle: stale price");

        uint8 underlyingDec = IERC20Metadata(asset).decimals();
        uint256 totalDec    = uint256(underlyingDec) + data.decimals;

        if (totalDec <= 36) {
            return data.price * (10 ** (36 - totalDec));
        }
        return data.price / (10 ** (totalDec - 36));
    }

    // ---------------------------------------------------------------------
    // Diagnostic views
    // ---------------------------------------------------------------------

    /// @notice Returns the asset address the adapter would price for `cToken`
    ///         (the override if set, otherwise `CErc20(cToken).underlying()`).
    function assetForCToken(CToken cToken) external view returns (address) {
        return _assetFor(cToken);
    }

    /// @notice Returns `(pairIndex, maxStaleSec, configured)` for `asset`.
    function getAssetConfig(address asset)
        external
        view
        returns (uint64 pairIndex, uint32 maxStaleSec, bool isSet)
    {
        AssetConfig memory cfg = configs[asset];
        return (cfg.pairIndex, cfg.maxStaleSec, cfg.isSet);
    }

    // ---------------------------------------------------------------------
    // Owner-only setters
    // ---------------------------------------------------------------------

    function setSupraStorage(address newSupraStorage) external onlyOwner {
        require(newSupraStorage != address(0), "SupraOracle: zero storage");
        address old = address(supraStorage);
        supraStorage = ISupraSValueFeedStorage(newSupraStorage);
        emit SupraStorageUpdated(old, newSupraStorage);
    }

    function setAssetConfig(address asset, uint64 pairIndex, uint32 maxStaleSec)
        public
        onlyOwner
    {
        require(asset != address(0),  "SupraOracle: zero asset");
        require(maxStaleSec > 0,      "SupraOracle: zero stale window");
        configs[asset] = AssetConfig({ isSet: true, pairIndex: pairIndex, maxStaleSec: maxStaleSec });
        emit AssetConfigSet(asset, pairIndex, maxStaleSec);
    }

    function setAssetConfigs(
        address[] calldata assets,
        uint64[]  calldata pairIndices,
        uint32[]  calldata maxStaleSecs
    ) external onlyOwner {
        require(assets.length == pairIndices.length, "SupraOracle: length mismatch");
        require(assets.length == maxStaleSecs.length, "SupraOracle: length mismatch");
        for (uint256 i = 0; i < assets.length; i++) {
            setAssetConfig(assets[i], pairIndices[i], maxStaleSecs[i]);
        }
    }

    function unsetAssetConfig(address asset) external onlyOwner {
        require(asset != address(0), "SupraOracle: zero asset");
        delete configs[asset];
        emit AssetConfigUnset(asset);
    }

    function setUnderlyingOverride(address cToken, address asset) external onlyOwner {
        require(cToken != address(0), "SupraOracle: zero cToken");
        underlyingOverride[cToken] = asset;
        emit UnderlyingOverrideSet(cToken, asset);
    }

    // ---------------------------------------------------------------------
    // Internal
    // ---------------------------------------------------------------------

    function _assetFor(CToken cToken) internal view returns (address) {
        address asset = underlyingOverride[address(cToken)];
        if (asset == address(0)) {
            asset = CErc20(address(cToken)).underlying();
        }
        return asset;
    }
}
