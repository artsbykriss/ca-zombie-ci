// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.29;

import {ERC20} from "@tokenized-strategy/BaseStrategy.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {FixedPointMathLib} from "solady/src/utils/FixedPointMathLib.sol";

import {RISExStrategy} from "src/extensions/RISExStrategy.sol";

import {IRISExAdapter} from "risex-adapter/interfaces/IRISExAdapter.sol";
import {IRISExLiquidationStrategy} from "src/interfaces/IRISExLiquidationStrategy.sol";
import {MarginMode, Position} from "src/interfaces/RISExTypes.sol";

/**
 * @title RISExLiquidationStrategy
 * @author RiseX Team
 * @notice Yearn V3 TokenizedStrategy for xlpUSD liquidation operations
 * @dev Handles liquidation takeovers and OTC transfers between vaults via adapter.
 *
 * Key features:
 * - Takes over liquidated positions at zero price (HF <= 0.67)
 * - Implements acceptance limits (per-position, per-market daily, global daily)
 * - Can OTC transfer positions to MM adapter via adapter
 * - Daily rebalancing target: 5% of combined TVL
 * - Epoch-based withdrawal protection to prevent rapid depletion
 *
 * Required roles on RISEx (configured via adapter's AccessManager):
 * - XLP_ROLE: For crossTakeover and isolatedTakeover
 * - OTC_VAULT_ROLE: For vault-to-vault OTC transfers
 * - WHITELISTED: For any perps interactions
 */
contract RISExLiquidationStrategy is RISExStrategy, IRISExLiquidationStrategy {
    using SafeCast for uint256;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice EIP-712 typehash for transferToMM
    bytes32 public constant TRANSFER_TO_MM_TYPEHASH =
        keccak256(
            "TransferToMM(uint16 marketId,uint128 size,uint128 price,uint256 deadline,uint256 nonce)"
        );

    /// @notice Seconds per day for daily reset calculation
    uint256 public constant SECONDS_PER_DAY = 86400;

    /// @notice Default global daily cap (50% of TVL)
    uint16 public constant DEFAULT_GLOBAL_DAILY_CAP_BPS = 5000;

    /// @notice Default per-market daily cap (20% of TVL)
    uint16 public constant DEFAULT_MARKET_DAILY_CAP_BPS = 2000;

    /// @notice Default position cap ($25k for alts)
    uint128 public constant DEFAULT_POSITION_CAP = 25_000e6;

    /*//////////////////////////////////////////////////////////////
                               STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev Per-market limit configuration
    mapping(uint16 marketId => MarketLimitConfig) private s_marketLimitConfig;

    /// @dev Per-market daily tracking
    mapping(uint16 marketId => MarketDailyData) private s_marketDailyData;

    /// @dev MM adapter address (the RISEx account identity for OTC transfers)
    address private s_mmAdapter;

    /// @dev Global daily cap in BPS (% of TVL)
    uint16 private s_globalDailyCapBps;

    /// @dev Default market daily cap for markets without specific cap
    uint16 private s_defaultMarketDailyCapBps;

    /// @dev Timestamp of last daily reset (aligned to 00:00 UTC)
    uint32 private s_lastResetTimestamp;

    /// @dev Default position cap for markets without specific cap (6 decimals)
    uint128 private s_defaultPositionCap;

    /// @dev Global exposure accumulated today (6 decimals)
    uint128 private s_dailyGlobalExposure;

    /// @dev When true, all takeover cap checks are skipped (position, market daily, global daily)
    bool private s_capsDisabled;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @param asset_ The underlying asset (USDC)
    /// @param name_ Strategy name for the tokenized vault
    /// @param adapter_ RISEx Adapter address
    constructor(
        address asset_,
        string memory name_,
        address adapter_
    ) RISExStrategy(asset_, name_, adapter_) {
        s_globalDailyCapBps = DEFAULT_GLOBAL_DAILY_CAP_BPS;
        s_defaultMarketDailyCapBps = DEFAULT_MARKET_DAILY_CAP_BPS;
        s_defaultPositionCap = DEFAULT_POSITION_CAP;
        s_lastResetTimestamp = _currentDayStart();
    }

    /*//////////////////////////////////////////////////////////////
                    REQUIRED STRATEGY OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @dev Free funds from RISEx collateral via adapter.
    ///      Reverts during stale-loss windows to prevent first-exiter advantage.
    function _freeFunds(uint256 amount) internal override {
        (uint256 idle, ) = _requireNoStaleLoss();

        uint256 withdrawable = getWithdrawableAmount();
        uint256 epochLimit = _getEpochWithdrawalLimit(idle);
        uint256 maxAvailable = withdrawable < epochLimit
            ? withdrawable
            : epochLimit;
        uint256 toWithdraw = amount > maxAvailable ? maxAvailable : amount;

        if (toWithdraw > 0) {
            _recordWithdrawal(toWithdraw.toUint128());

            uint256 freed = i_adapter.freeCollateral(
                address(asset),
                toWithdraw
            );

            if (freed < toWithdraw) {
                _correctWithdrawalOvercount((toWithdraw - freed).toUint128());
            }

            emit WithdrawnFromRISEx(freed);
        }
    }

    /*//////////////////////////////////////////////////////////////
                         OPTIONAL OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @notice Maximum depositable amount (whitelist only)
    function availableDepositLimit(
        address owner
    ) public view override returns (uint256) {
        if (!whitelistedDepositor(owner)) {
            return 0;
        }
        return type(uint256).max;
    }

    /// @notice Maximum withdrawable amount
    /// @dev Returns 0 during stale-loss windows (live < recorded) — report() must run first.
    function availableWithdrawLimit(
        address
    ) public view override returns (uint256) {
        (uint256 liveAssets, uint256 idle, ) = _getLiveTotalAssets();

        if (liveAssets < TokenizedStrategy.totalAssets()) return 0;

        uint256 withdrawable = getWithdrawableAmount();
        uint256 bufferLimit = idle + withdrawable;
        uint256 epochLimit = _getEpochWithdrawalLimit(idle);

        return bufferLimit < epochLimit ? bufferLimit : epochLimit;
    }

    /*//////////////////////////////////////////////////////////////
                        ACCEPTANCE LIMIT CHECKS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRISExLiquidationStrategy
    function canAcceptTakeover(
        uint16 marketId,
        uint256 notional
    ) external view {
        (
            uint256 marketExposure,
            uint256 globalExposure
        ) = _getEffectiveExposures(marketId);
        (uint256 cachedTotalAssets, , ) = _getLiveTotalAssets();
        _requireTakeoverWithinLimits(
            marketId,
            notional,
            marketExposure,
            globalExposure,
            cachedTotalAssets
        );
    }

    /// @inheritdoc IRISExLiquidationStrategy
    function canAcceptCrossTakeover(
        address account
    )
        external
        view
        returns (
            bool canAccept,
            string memory reason,
            uint16[] memory marketIds,
            uint256[] memory notionals,
            uint256 totalNotional
        )
    {
        try this.previewCrossTakeover(account) returns (
            uint16[] memory ids,
            uint256[] memory nots,
            uint256 total
        ) {
            return (true, "", ids, nots, total);
        } catch Error(string memory err) {
            return (false, err, new uint16[](0), new uint256[](0), 0);
        } catch (bytes memory) {
            return (
                false,
                "Takeover rejected",
                new uint16[](0),
                new uint256[](0),
                0
            );
        }
    }

    /// @inheritdoc IRISExLiquidationStrategy
    function previewCrossTakeover(
        address account
    )
        public
        view
        returns (
            uint16[] memory marketIds,
            uint256[] memory notionals,
            uint256 totalNotional
        )
    {
        return _previewCrossTakeover(account);
    }

    /*//////////////////////////////////////////////////////////////
                           TAKEOVER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRISExLiquidationStrategy
    function executeCrossTakeover(address account) external onlyKeepers {
        resetDailyCountersIfNeeded();

        (
            uint16[] memory marketIds,
            uint256[] memory notionals,
            uint256 totalNotional
        ) = _previewCrossTakeover(account);

        uint256 length = marketIds.length;
        for (uint256 i; i < length; ++i) {
            _updateDailyExposure(marketIds[i], notionals[i]);
        }

        i_adapter.executeCrossTakeover(account);

        emit TakeoverExecuted(account, marketIds, totalNotional);
    }

    /// @inheritdoc IRISExLiquidationStrategy
    function executeIsolatedTakeover(
        address account,
        uint16 marketId
    ) external onlyKeepers {
        resetDailyCountersIfNeeded();

        Position memory pos = abi.decode(
            i_adapter.getPosition(marketId, account),
            (Position)
        );
        uint256 notional = _getLivePositionNotional(marketId, pos.size);
        (uint256 cachedTotalAssets, , ) = _getLiveTotalAssets();
        (
            uint256 marketExposure,
            uint256 globalExposure
        ) = _getEffectiveExposures(marketId);
        _requireTakeoverWithinLimits(
            marketId,
            notional,
            marketExposure,
            globalExposure,
            cachedTotalAssets
        );

        _updateDailyExposure(marketId, notional);

        i_adapter.executeIsolatedTakeover(account, marketId);

        emit IsolatedTakeoverExecuted(account, marketId, notional);
    }

    /*//////////////////////////////////////////////////////////////
                       POSITION MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRISExLiquidationStrategy
    function transferToMM(
        uint16 marketId,
        uint128 size,
        uint128 price,
        uint256 deadline,
        bytes calldata signature
    ) external onlyKeepers {
        uint256 nonce = getNonce();
        _verifySigner(
            keccak256(
                abi.encode(
                    TRANSFER_TO_MM_TYPEHASH,
                    marketId,
                    size,
                    price,
                    deadline,
                    nonce
                )
            ),
            deadline,
            nonce,
            signature
        );

        require(s_mmAdapter != address(0), MMAdapterNotSet());

        Position memory pos = abi.decode(
            i_adapter.getPosition(marketId, address(i_adapter)),
            (Position)
        );
        require(pos.size != 0, NoPositionToTransfer(marketId));

        IRISExAdapter.Side ourSide = pos.size > 0
            ? IRISExAdapter.Side.Sell
            : IRISExAdapter.Side.Buy;

        IRISExAdapter.OtcRequest memory request = IRISExAdapter.OtcRequest({
            marketId: marketId,
            mmVault: s_mmAdapter,
            side: ourSide,
            size: size,
            price: price,
            flags: 0,
            extraData: ""
        });
        i_adapter.transferToMM(request);

        emit PositionTransferredToMM(marketId, size, price);
    }

    /*//////////////////////////////////////////////////////////////
                           VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRISExLiquidationStrategy
    function isCapsDisabled() external view returns (bool) {
        return s_capsDisabled;
    }

    /// @inheritdoc IRISExLiquidationStrategy
    function getPosition(
        uint16 marketId
    ) public view returns (Position memory pos) {
        return
            abi.decode(
                i_adapter.getPosition(marketId, address(i_adapter)),
                (Position)
            );
    }

    /// @inheritdoc IRISExLiquidationStrategy
    function hasPosition(uint16 marketId) public view returns (bool) {
        return i_adapter.hasPosition(marketId, address(i_adapter));
    }

    /// @inheritdoc IRISExLiquidationStrategy
    function getMarketPositionCap(
        uint16 marketId
    ) public view returns (uint256) {
        uint256 cap = s_marketLimitConfig[marketId].positionCap;
        return cap > 0 ? cap : s_defaultPositionCap;
    }

    /// @inheritdoc IRISExLiquidationStrategy
    function getMarketDailyCap(uint16 marketId) public view returns (uint256) {
        (uint256 totalAssets, , ) = _getLiveTotalAssets();
        return _getMarketDailyCap(marketId, totalAssets);
    }

    /// @inheritdoc IRISExLiquidationStrategy
    function getGlobalDailyCap() public view returns (uint256) {
        (uint256 totalAssets, , ) = _getLiveTotalAssets();
        return _getGlobalDailyCap(totalAssets);
    }

    /// @inheritdoc IRISExLiquidationStrategy
    function canQueryEquity() external view returns (bool) {
        getAccountEquity();
        return true;
    }

    /// @inheritdoc IRISExLiquidationStrategy
    function getMmAdapter() external view returns (address) {
        return s_mmAdapter;
    }

    /// @inheritdoc IRISExLiquidationStrategy
    function getGlobalDailyCapBps() external view returns (uint16) {
        return s_globalDailyCapBps;
    }

    /// @inheritdoc IRISExLiquidationStrategy
    function getDefaultMarketDailyCapBps() external view returns (uint16) {
        return s_defaultMarketDailyCapBps;
    }

    /// @inheritdoc IRISExLiquidationStrategy
    function getLastResetTimestamp() external view returns (uint32) {
        return s_lastResetTimestamp;
    }

    /// @inheritdoc IRISExLiquidationStrategy
    function getDefaultPositionCap() external view returns (uint128) {
        return s_defaultPositionCap;
    }

    /// @inheritdoc IRISExLiquidationStrategy
    function getDailyGlobalExposure() external view returns (uint128) {
        return s_dailyGlobalExposure;
    }

    /// @inheritdoc IRISExLiquidationStrategy
    function getMarketLimitConfig(
        uint16 marketId
    ) external view returns (uint128 positionCap, uint16 dailyCapBps) {
        MarketLimitConfig storage $ = s_marketLimitConfig[marketId];
        return ($.positionCap, $.dailyCapBps);
    }

    /// @inheritdoc IRISExLiquidationStrategy
    function getMarketDailyData(
        uint16 marketId
    ) external view returns (uint128 exposure, uint32 lastResetTimestamp) {
        MarketDailyData storage $ = s_marketDailyData[marketId];
        return ($.exposure, $.lastResetTimestamp);
    }

    /*//////////////////////////////////////////////////////////////
                        MANAGEMENT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRISExLiquidationStrategy
    function setCapsDisabled(bool disabled) external onlyManagement {
        s_capsDisabled = disabled;
        emit CapsDisabledUpdated(disabled);
    }

    /// @inheritdoc IRISExLiquidationStrategy
    function setMarketPositionCap(
        uint16 marketId,
        uint128 cap
    ) external onlyManagement {
        uint128 oldCap = s_marketLimitConfig[marketId].positionCap;
        s_marketLimitConfig[marketId].positionCap = cap;
        emit MarketPositionCapUpdated(marketId, oldCap, cap);
    }

    /// @inheritdoc IRISExLiquidationStrategy
    function setMarketDailyCapBps(
        uint16 marketId,
        uint16 capBps
    ) external onlyManagement {
        require(capBps <= BPS_DENOMINATOR, InvalidCapBps());
        uint16 oldCapBps = s_marketLimitConfig[marketId].dailyCapBps;
        s_marketLimitConfig[marketId].dailyCapBps = capBps;
        emit MarketDailyCapUpdated(marketId, oldCapBps, capBps);
    }

    /// @inheritdoc IRISExLiquidationStrategy
    function setGlobalDailyCapBps(uint16 capBps) external onlyManagement {
        require(capBps <= BPS_DENOMINATOR, InvalidCapBps());
        uint16 oldCapBps = s_globalDailyCapBps;
        s_globalDailyCapBps = capBps;
        emit GlobalDailyCapUpdated(oldCapBps, capBps);
    }

    /// @inheritdoc IRISExLiquidationStrategy
    function setDefaultPositionCap(uint128 cap) external onlyManagement {
        uint128 oldCap = s_defaultPositionCap;
        s_defaultPositionCap = cap;
        emit DefaultPositionCapUpdated(oldCap, cap);
    }

    /// @inheritdoc IRISExLiquidationStrategy
    function setDefaultMarketDailyCapBps(
        uint16 capBps
    ) external onlyManagement {
        require(capBps <= BPS_DENOMINATOR, InvalidCapBps());
        uint16 oldCapBps = s_defaultMarketDailyCapBps;
        s_defaultMarketDailyCapBps = capBps;
        emit DefaultMarketDailyCapUpdated(oldCapBps, capBps);
    }

    /// @inheritdoc IRISExLiquidationStrategy
    function setMMAdapter(address newMmAdapter) external onlyManagement {
        require(
            newMmAdapter != address(this),
            StrategyAddressNotAllowed(newMmAdapter)
        );
        address oldAdapter = s_mmAdapter;
        s_mmAdapter = newMmAdapter;
        emit MMAdapterUpdated(oldAdapter, newMmAdapter);
    }

    /// @inheritdoc IRISExLiquidationStrategy
    function resetDailyCountersIfNeeded() public {
        uint32 today = _currentDayStart();

        if (today > s_lastResetTimestamp) {
            s_lastResetTimestamp = today;
            s_dailyGlobalExposure = 0;
            emit DailyCountersReset(today);
        }
    }

    /// @inheritdoc IRISExLiquidationStrategy
    function resetMarketDailyExposure(uint16 marketId) external onlyKeepers {
        s_marketDailyData[marketId].exposure = 0;
    }

    /*//////////////////////////////////////////////////////////////
                         INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Current UTC day start as uint32 (safe until year 2106)
    function _currentDayStart() private view returns (uint32) {
        return uint32((block.timestamp / SECONDS_PER_DAY) * SECONDS_PER_DAY);
    }

    /// @dev Get effective exposures considering potential daily reset
    function _getEffectiveExposures(
        uint16 marketId
    ) internal view returns (uint256 market, uint256 global) {
        uint32 today = _currentDayStart();

        uint256 effectiveGlobal = today > s_lastResetTimestamp
            ? 0
            : s_dailyGlobalExposure;

        MarketDailyData storage $ = s_marketDailyData[marketId];
        uint256 effectiveMarket = today > $.lastResetTimestamp ? 0 : $.exposure;

        return (effectiveMarket, effectiveGlobal);
    }

    /// @dev Get effective market exposure considering potential daily reset
    function _getEffectiveMarketExposure(
        uint16 marketId
    ) internal view returns (uint256) {
        MarketDailyData storage $ = s_marketDailyData[marketId];
        if (_currentDayStart() > $.lastResetTimestamp) {
            return 0;
        }
        return $.exposure;
    }

    /// @dev Get effective global exposure considering potential daily reset
    function _getEffectiveGlobalExposure() internal view returns (uint256) {
        if (_currentDayStart() > s_lastResetTimestamp) {
            return 0;
        }
        return s_dailyGlobalExposure;
    }

    /// @dev Get market daily cap in absolute terms
    function _getMarketDailyCap(
        uint16 marketId,
        uint256 totalAssets
    ) internal view returns (uint256) {
        uint256 capBps = s_marketLimitConfig[marketId].dailyCapBps;
        if (capBps == 0) capBps = s_defaultMarketDailyCapBps;
        return (totalAssets * capBps) / BPS_DENOMINATOR;
    }

    /// @dev Get global daily cap in absolute terms
    function _getGlobalDailyCap(
        uint256 totalAssets
    ) internal view returns (uint256) {
        return (totalAssets * s_globalDailyCapBps) / BPS_DENOMINATOR;
    }

    /// @dev Update daily exposure counters after takeover (lazy reset per-market)
    function _updateDailyExposure(uint16 marketId, uint256 notional) internal {
        uint32 today = _currentDayStart();
        MarketDailyData storage $ = s_marketDailyData[marketId];
        if (today > $.lastResetTimestamp) {
            $.exposure = 0;
            $.lastResetTimestamp = today;
        }

        $.exposure += notional.toUint128();
        s_dailyGlobalExposure += notional.toUint128();
    }

    /// @dev Require takeover is within all limits (position, market daily, global daily)
    function _requireTakeoverWithinLimits(
        uint16 marketId,
        uint256 notional,
        uint256 marketExposure,
        uint256 globalExposure,
        uint256 cachedTotalAssets
    ) internal view {
        if (s_capsDisabled) return;

        uint256 positionCap = getMarketPositionCap(marketId);
        require(
            notional <= positionCap,
            TakeoverExceedsPositionCap(marketId, notional, positionCap)
        );

        uint256 marketCap = _getMarketDailyCap(marketId, cachedTotalAssets);
        uint256 projectedMarketExposure = marketExposure + notional;
        require(
            projectedMarketExposure <= marketCap,
            TakeoverExceedsMarketDailyCap(
                marketId,
                projectedMarketExposure,
                marketCap
            )
        );

        uint256 globalCap = _getGlobalDailyCap(cachedTotalAssets);
        uint256 projectedGlobalExposure = globalExposure + notional;
        require(
            projectedGlobalExposure <= globalCap,
            TakeoverExceedsGlobalDailyCap(projectedGlobalExposure, globalCap)
        );
    }

    /// @dev Preview cross-margin takeover with limit checks
    function _previewCrossTakeover(
        address account
    )
        internal
        view
        returns (
            uint16[] memory marketIds,
            uint256[] memory notionals,
            uint256 totalNotional
        )
    {
        marketIds = i_adapter.getActiveMarketIds(account);
        uint256 length = marketIds.length;
        notionals = new uint256[](length);

        CrossTakeoverPreviewState memory preview;
        preview.projectedGlobalExposure = _getEffectiveGlobalExposure();
        (uint256 cachedTotalAssets, , ) = _getLiveTotalAssets();

        for (uint256 i; i < length; ++i) {
            uint256 notional = _previewCrossMarket(
                account,
                marketIds[i],
                preview.projectedGlobalExposure,
                cachedTotalAssets
            );
            if (notional == 0) continue;

            marketIds[preview.marketCount] = marketIds[i];
            notionals[preview.marketCount] = notional;
            preview.totalNotional += notional;
            preview.projectedGlobalExposure += notional;
            ++preview.marketCount;
        }

        uint256 marketCount = preview.marketCount;
        totalNotional = preview.totalNotional;

        assembly ("memory-safe") {
            mstore(marketIds, marketCount)
            mstore(notionals, marketCount)
        }
    }

    /// @dev Get live position notional from mark price
    function _getLivePositionNotional(
        uint16 marketId,
        int128 size
    ) internal view returns (uint256) {
        uint256 sizeAbs = FixedPointMathLib.abs(int256(size));
        if (sizeAbs == 0) return 0;

        uint256 markPrice = i_adapter.getMarkPrice(marketId);
        uint256 notional18 = sizeAbs.mulWad(markPrice);
        uint256 notional = notional18 / RISEX_DECIMALS_ADJUSTMENT;

        // Round up to 1 for non-zero positions so dust doesn't skip cap accounting
        if (notional == 0) notional = 1;
        return notional;
    }

    /// @dev Preview a single cross-margin market for takeover
    function _previewCrossMarket(
        address account,
        uint16 marketId,
        uint256 projectedGlobalExposure,
        uint256 cachedTotalAssets
    ) internal view returns (uint256 notional) {
        Position memory pos = abi.decode(
            i_adapter.getPosition(marketId, account),
            (Position)
        );

        if (pos.size == 0 || pos.marginMode != MarginMode.Cross) {
            return 0;
        }

        notional = _getLivePositionNotional(marketId, pos.size);
        _requireTakeoverWithinLimits(
            marketId,
            notional,
            _getEffectiveMarketExposure(marketId),
            projectedGlobalExposure,
            cachedTotalAssets
        );
    }
}
