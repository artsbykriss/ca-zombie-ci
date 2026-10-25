// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.24;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {AccessControl} from "../access/AccessControl.sol";
import {IPriceOracle} from "./interfaces/IPriceOracle.sol";
import {Constants} from "../libraries/Constants.sol";
import {MathLib} from "../libraries/MathLib.sol";
import {AddressLib} from "../libraries/AddressLib.sol";
import {Errors} from "../libraries/Errors.sol";

interface IAggregatorV3 {
    function decimals() external view returns (uint8);

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
}

/// @title PriceOracle
/// @notice Chainlink-backed oracle for USDW mint/burn quotes with staleness checks and depeg policy
contract PriceOracle is AccessControl, IPriceOracle {
    using AddressLib for address;

    mapping(address asset => OracleConfig config) private _oracleConfigs;

    /// @notice Sequencer uptime feed (L2); zero disables the check.
    address public sequencerUptimeFeed;

    uint256[69] private __gap;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address administrator_) external initializer {
        administrator_.requireNonZeroContract();
        __AccessControl_init(administrator_);
        emit AdministratorSet(address(0), administrator_);
    }

    /// @inheritdoc IPriceOracle
    function isPriceFresh(address asset) public view override returns (bool isFresh) {
        OracleConfig memory cfg = _oracleConfigs[asset];
        if (cfg.aggregator == address(0) || !_isSequencerUp()) return false;

        (uint256 priceWad_, uint256 updatedAt) = _readChainlinkRound(cfg.aggregator);
        if (priceWad_ == 0 || updatedAt == 0) return false;

        return block.timestamp - updatedAt <= _maxStaleness(cfg.maxStaleness);
    }

    /// @inheritdoc IPriceOracle
    function getOracleConfig(address asset) external view override returns (OracleConfig memory config) {
        config = _oracleConfigs[asset];
    }

    /// @inheritdoc IPriceOracle
    function quoteUsdwMint(address stable, uint256 backingAmount) external view override returns (uint256 usdwOut) {
        (uint256 priceWad_, OracleConfig memory cfg) = _readUsdwPrice(stable);
        uint8 backingDecimals = IERC20Metadata(stable).decimals();
        uint256 par = MathLib.scaleDecimals(backingAmount, backingDecimals, Constants.USDW_TOKEN_DECIMALS);
        if (par == 0) revert Errors.ZeroAmount();
        return _quoteParWithDepeg(stable, priceWad_, cfg, par, true);
    }

    /// @inheritdoc IPriceOracle
    function quoteUsdwBurn(address stable, uint256 usdwAmount) external view override returns (uint256 payoutOut) {
        (uint256 priceWad_, OracleConfig memory cfg) = _readUsdwPrice(stable);
        uint8 payoutDecimals = IERC20Metadata(stable).decimals();
        uint256 par = MathLib.scaleDecimals(usdwAmount, Constants.USDW_TOKEN_DECIMALS, payoutDecimals);
        if (par == 0) revert Errors.ZeroAmount();
        return _quoteParWithDepeg(stable, priceWad_, cfg, par, false);
    }

    /// @inheritdoc IPriceOracle
    function setOracleConfig(address asset, OracleConfig calldata config) external override onlyAdministrator whenNotPaused {
        asset.requireNonZero();
        config.aggregator.requireNonZeroContract();

        if (config.maxStaleness > 0 && config.maxStaleness > Constants.MAX_ORACLE_STALENESS) {
            revert Errors.InvalidTimestamp(config.maxStaleness);
        }
        if (_softDepegThresholdBps(config) > _hardDepegThresholdBps(config)) {
            revert Errors.DepegThresholdOrderInvalid();
        }

        _oracleConfigs[asset] = config;
        emit OracleConfigUpdated(asset, config.aggregator);
    }

    /// @inheritdoc IPriceOracle
    function setSequencerUptimeFeed(address sequencerUptimeFeed_) external override onlyAdministrator {
        sequencerUptimeFeed_.requireNonZeroContract();
        sequencerUptimeFeed = sequencerUptimeFeed_;
        emit SequencerUptimeFeedSet(sequencerUptimeFeed_);
    }

    function _readUsdwPrice(address stable)
        internal
        view
        returns (uint256 priceWad_, OracleConfig memory cfg)
    {
        stable.requireNonZeroContract();
        cfg = _oracleConfigs[stable];
        if (cfg.aggregator == address(0)) revert Errors.OracleNotConfigured();
        if (!_isSequencerUp()) revert Errors.SequencerDown();

        uint256 updatedAt;
        (priceWad_, updatedAt) = _readChainlinkRound(cfg.aggregator);
        if (updatedAt == 0 || priceWad_ == 0) revert Errors.StalePrice(stable, 0);

        uint256 age = block.timestamp - updatedAt;
        if (age > _maxStaleness(cfg.maxStaleness)) revert Errors.StalePrice(stable, age);
    }

    function _quoteParWithDepeg(
        address stable,
        uint256 priceWad_,
        OracleConfig memory cfg,
        uint256 par,
        bool isMint
    ) internal pure returns (uint256 quoted) {
        uint256 deviationBps = _deviationBps(priceWad_);
        if (deviationBps > _hardDepegThresholdBps(cfg)) {
            revert Errors.DepegRejected(stable, priceWad_, deviationBps);
        }
        if (deviationBps <= _softDepegThresholdBps(cfg)) {
            return par;
        }

        if (isMint) {
            uint256 cappedPrice = priceWad_ < Constants.PRECISION ? priceWad_ : Constants.PRECISION;
            return MathLib.mulDiv18(par, cappedPrice);
        }

        uint256 flooredPrice = priceWad_ > Constants.PRECISION ? priceWad_ : Constants.PRECISION;
        return (par * Constants.PRECISION) / flooredPrice;
    }

    function _readChainlinkRound(address aggregator)
        internal
        view
        returns (uint256 priceWad_, uint256 updatedAt)
    {
        IAggregatorV3 feed = IAggregatorV3(aggregator);
        (, int256 answer,, uint256 feedUpdatedAt,) = feed.latestRoundData();
        updatedAt = feedUpdatedAt;
        if (answer <= 0) return (0, updatedAt);
        priceWad_ = MathLib.scaleDecimals(uint256(answer), feed.decimals(), Constants.PRICE_WAD_DECIMALS);
    }

    function _maxStaleness(uint256 configured) internal pure returns (uint256) {
        return configured == 0 ? Constants.MAX_ORACLE_STALENESS : configured;
    }

    function _softDepegThresholdBps(OracleConfig memory cfg) internal pure returns (uint256) {
        return cfg.softDepegThresholdBps == 0 ? Constants.DEPEG_SOFT_THRESHOLD_BPS : cfg.softDepegThresholdBps;
    }

    function _hardDepegThresholdBps(OracleConfig memory cfg) internal pure returns (uint256) {
        return cfg.hardDepegThresholdBps == 0 ? Constants.DEPEG_HARD_THRESHOLD_BPS : cfg.hardDepegThresholdBps;
    }

    function _deviationBps(uint256 priceWad_) internal pure returns (uint256 deviationBps) {
        uint256 diff = priceWad_ > Constants.PRECISION ? priceWad_ - Constants.PRECISION : Constants.PRECISION - priceWad_;
        deviationBps = (diff * Constants.DEPEG_BPS_SCALE) / Constants.PRECISION;
    }

    function _isSequencerUp() internal view returns (bool) {
        address feed = sequencerUptimeFeed;
        if (feed == address(0)) return true;

        (, int256 answer, uint256 startedAt,,) = IAggregatorV3(feed).latestRoundData();
        if (answer == 1 || startedAt == 0) return false;

        return block.timestamp - startedAt >= Constants.MIN_SEQUENCER_UPTIME;
    }
}
