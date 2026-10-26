// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2025 Flying Tulip Inc. All rights reserved.
pragma solidity ^0.8.30;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IAccountValuesLens, AccountSnapshot} from "./interfaces/IAccountValuesLens.sol";
import {IConfigRegistry} from "./interfaces/IConfigRegistry.sol";
import {IIRM} from "./interfaces/IIRM.sol";
import {IPositionsManager} from "./interfaces/IPositionsManager.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {
    Ownable2StepUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {RiskLib} from "./utils/RiskLib.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IOracleUSD} from "@ft-common/interfaces/IOracleUSD.sol";
import {Constants} from "./utils/Constants.sol";

contract LendingLens is Initializable, UUPSUpgradeable, Ownable2StepUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    IPositionsManager public pm;

    uint256 internal constant RAY = 1e27;

    function initialize(address _pm, address initialOwner) external initializer {
        require(_pm != address(0), "LendingLens: PM zero");
        require(initialOwner != address(0), "LendingLens: owner zero");
        __UUPSUpgradeable_init();
        pm = IPositionsManager(_pm);
        __Ownable_init(initialOwner);
        __Ownable2Step_init();
    }

    // UUPS upgrade authorization: gated by the lens' own owner
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function cfg() public view returns (IConfigRegistry) {
        return pm.config();
    }

    /*//////////////////////////////////////////////////////////////
                     POSITIONS MANAGER PASSTHROUGH VIEWS
    //////////////////////////////////////////////////////////////*/

    function config() external view returns (IConfigRegistry) {
        return pm.config();
    }

    function engines(address m) external view returns (bool) {
        return pm.engines(m);
    }

    function valuesLens() external view returns (IAccountValuesLens) {
        return pm.valuesLens();
    }

    function withdrawPaused(address asset) external view returns (bool) {
        return pm.withdrawPaused(asset);
    }

    function depositPaused(address asset) external view returns (bool) {
        return pm.depositPaused(asset);
    }

    function borrowPaused(address asset) external view returns (bool) {
        return pm.borrowPaused(asset);
    }

    function supplyCap(address asset) external view returns (uint256) {
        return pm.supplyCap(asset);
    }

    function borrowCap(address asset) external view returns (uint256) {
        return pm.borrowCap(asset);
    }

    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return pm.DOMAIN_SEPARATOR();
    }

    function DOMAIN_CHAIN_ID() external view returns (uint256) {
        return pm.DOMAIN_CHAIN_ID();
    }

    function metaModules(address module) external view returns (bool) {
        return pm.metaModules(module);
    }

    function noncesTyped(address user, bytes32 typehash) external view returns (uint256) {
        return pm.noncesTyped(user, typehash);
    }

    function engineHeld(
        address user,
        address engine,
        address asset
    )
        external
        view
        returns (uint256)
    {
        return pm.engineHeld(user, engine, asset);
    }

    function collateral(
        address user,
        address asset
    )
        external
        view
        returns (
            uint256 avail,
            uint256 hold,
            uint40 lastT,
            uint32 lastSettledEpoch,
            uint256 openSupplyTime
        )
    {
        return pm.collateral(user, asset);
    }

    function debt(address user, address asset) external view returns (uint256 principal) {
        uint256 shares = pm.debtShares(user, asset);
        if (shares == 0) return 0;
        uint256 assetTotalShares = pm.totalDebtShares(asset);
        if (assetTotalShares == 0) return 0;
        uint256 borrowsNow = _previewBorrows(asset);
        if (borrowsNow == 0) return 0;
        principal = Math.mulDiv(shares, borrowsNow, assetTotalShares, Math.Rounding.Ceil);
    }

    function debtShares(address user, address asset) external view returns (uint256 shares) {
        return pm.debtShares(user, asset);
    }

    function totalDebtShares(address asset) external view returns (uint256 shares) {
        return pm.totalDebtShares(asset);
    }

    function epochs(
        address asset,
        uint32 epochId
    )
        external
        view
        returns (
            uint40 t_end,
            uint256 S_end,
            uint256 rateRay,
            uint256 X_end,
            uint256 interest,
            uint256 supplyTime
        )
    {
        return pm.epochs(asset, epochId);
    }

    function astate(address asset)
        external
        view
        returns (
            uint256 borrowIndexWad,
            uint256 cash,
            uint256 borrows,
            uint256 totalSupplied,
            uint256 reserves,
            uint256 totalSuppliedTime,
            uint40 lastAccrual,
            uint32 epoch
        )
    {
        return pm.astate(asset);
    }

    function getBalance(
        address user,
        address token
    )
        external
        view
        returns (uint256 avail, uint256 hold)
    {
        return pm.getBalance(user, token);
    }

    function userCollateralAssets(address user) external view returns (address[] memory) {
        return pm.userCollateralAssets(user);
    }

    function userDebtAssets(address user) external view returns (address[] memory) {
        return pm.userDebtAssets(user);
    }

    function borrowAllowance(
        address user,
        address delegate,
        address asset
    )
        external
        view
        returns (uint256)
    {
        return pm.borrowAllowance(user, delegate, asset);
    }

    function FT() external view returns (address) {
        return pm.FT();
    }

    /*//////////////////////////////////////////////////////////////
                            ORACLE VIEWS
    //////////////////////////////////////////////////////////////*/

    function pricesUSD(address[] calldata assets) external view returns (uint256[] memory pxWad) {
        uint256 n = assets.length;
        pxWad = new uint256[](n);
        address oracleRouter = pm.config().oracleRouter();
        for (uint256 i = 0; i < n; ++i) {
            pxWad[i] = IOracleUSD(oracleRouter).priceUSD(assets[i]); // USD WAD
        }
    }

    /*//////////////////////////////////////////////////////////////
                          CONFIG REGISTRY VIEWS
    //////////////////////////////////////////////////////////////*/

    function assetCfg(address asset)
        external
        view
        returns (address irm, uint16 mmBps, bool enabled, bool borrowable, bool isCollateral)
    {
        IConfigRegistry.AssetCfg memory a = cfg().getAssetCfg(asset);
        return (a.irm, a.mmBps, a.enabled, a.borrowable, a.collateral);
    }

    function globalRisk() external view returns (address oracleRouter, uint16 hfTargetBps) {
        IConfigRegistry registry = pm.config();
        oracleRouter = registry.oracleRouter();
        hfTargetBps = registry.marginHfTargetBps();
    }

    /*//////////////////////////////////////////////////////////////
                             IRM (JUMP) VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @notice Sample borrow APRs for a given IRM at provided utilization points (WAD).
    /// @dev Works with fixed Jump IRMs (Stable/Major/LongTail) via the IIRM interface.
    function irmSampleAPR(
        address irm,
        uint256[] calldata utilWad
    )
        external
        view
        returns (uint256[] memory aprWad)
    {
        IIRM model = IIRM(irm);
        uint256 n = utilWad.length;
        aprWad = new uint256[](n);
        for (uint256 i = 0; i < n; ++i) {
            uint256 u = utilWad[i] > Constants.WAD ? Constants.WAD : utilWad[i];
            aprWad[i] = model.borrowAPR(address(0), u);
        }
    }

    /*//////////////////////////////////////////////////////////////
                        POSITIONS MANAGER — USERS
    //////////////////////////////////////////////////////////////*/
    function lens() public view returns (IAccountValuesLens) {
        return pm.valuesLens();
    }

    /// @notice Portfolio-level view: effective collateral, debt and HF for `user`.
    function userOverview(address user)
        external
        view
        returns (uint256 equityUSDWad, uint256 maintUSDWad, uint16 hfBps)
    {
        (equityUSDWad, maintUSDWad,) = accountValues(user);
        hfBps = RiskLib.hfBps(equityUSDWad, maintUSDWad);
    }

    /// @notice Per-asset balances for a user; returns (avail, hold, previewTotal) arrays aligned with `assets`.
    function userBalances(
        address user,
        address[] calldata assets
    )
        external
        view
        returns (uint256[] memory avail, uint256[] memory hold, uint256[] memory previewTotal)
    {
        uint256 n = assets.length;
        avail = new uint256[](n);
        hold = new uint256[](n);
        previewTotal = new uint256[](n);
        for (uint256 i = 0; i < n; ++i) {
            (avail[i], hold[i]) = pm.getBalance(user, assets[i]);
            previewTotal[i] = avail[i] + hold[i];
        }
    }

    /// @notice Collateral assets including FT preview as an additional synthetic entry if nonzero.
    /// Behavior:
    ///  - If the FT token is already in the user's collateral set, its row is included exactly once
    ///    with `avail = ledgerAvail + pendingPreview` and `hold = ledgerHold`.
    ///  - If the FT token is not in the collateral set but is nonzero (ledger or pending), an FT row
    ///    is appended at the end with the same semantics.
    function userCollateralWithFT(address user)
        external
        view
        returns (address[] memory assetsOut, uint256[] memory avail, uint256[] memory hold)
    {
        address[] memory base = pm.userCollateralAssets(user);
        uint256 m = base.length;

        address ft = pm.FT();
        uint256 ftAvailLedger;
        uint256 ftHoldLedger;
        uint256 ftPending;
        bool includeFT;
        if (ft != address(0)) {
            (ftAvailLedger, ftHoldLedger) = pm.getBalance(user, ft);
            ftPending = previewFTClaimTotal(user);
            includeFT = (ftAvailLedger + ftHoldLedger + ftPending) > 0;
        }

        bool ftInBase = false;
        if (includeFT) {
            for (uint256 i = 0; i < m; ++i) {
                if (base[i] == ft) {
                    ftInBase = true;
                    break;
                }
            }
        }

        uint256 outLen = includeFT ? (ftInBase ? m : m + 1) : m;
        assetsOut = new address[](outLen);
        avail = new uint256[](outLen);
        hold = new uint256[](outLen);

        for (uint256 i = 0; i < m; ++i) {
            address a = base[i];
            assetsOut[i] = a;
            if (includeFT && a == ft) {
                // Replace FT row with ledger + pending preview
                avail[i] = ftAvailLedger + ftPending;
                hold[i] = ftHoldLedger;
            } else {
                (avail[i], hold[i]) = pm.getBalance(user, a);
            }
        }

        if (includeFT && !ftInBase) {
            assetsOut[m] = ft;
            avail[m] = ftAvailLedger + ftPending;
            hold[m] = ftHoldLedger;
        }
    }

    /// @notice Combined portfolio view: collateral (with FT preview), debts, and aggregate risk.
    /// Returns:
    ///  - collAssets, collAvail, collHold (includes FT appended if nonzero; FT avail includes pending preview)
    ///  - debtAssets, debtUnitsNow (accrued principal via preview)
    ///  - equityUSDWad, maintUSDWad, hfBps (aggregate)
    function userPortfolio(address user)
        external
        view
        returns (
            address[] memory collAssets,
            uint256[] memory collAvail,
            uint256[] memory collHold,
            address[] memory debtAssets,
            uint256[] memory debtUnitsNow,
            uint256 equityUSDWad,
            uint256 maintUSDWad,
            uint16 hfBps
        )
    {
        // Collateral + FT preview
        (collAssets, collAvail, collHold) = this.userCollateralWithFT(user);

        // Debts (preview accrued principal)
        debtAssets = pm.userDebtAssets(user);
        uint256 n = debtAssets.length;
        debtUnitsNow = new uint256[](n);
        for (uint256 i = 0; i < n; ++i) {
            debtUnitsNow[i] = this.previewUserDebtUnits(user, debtAssets[i]);
        }

        // Aggregates
        (equityUSDWad, maintUSDWad,) = accountValues(user);
        hfBps = RiskLib.hfBps(equityUSDWad, maintUSDWad);
    }

    /*//////////////////////////////////////////////////////////////
                    POSITIONS MANAGER — ASSET STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Preview the current borrow index for `asset` as of now (view-only).
    function previewBorrowIndexWad(address asset) public view returns (uint256 idxNow) {
        return _previewBorrowIndexWad(asset);
    }

    function _previewBorrowIndexWad(address asset) internal view virtual returns (uint256) {
        return pm.valuesLens().previewBorrowIndexWad(address(pm), asset);
    }

    function accountValues(address user)
        public
        view
        returns (uint256 equityUSDWad, uint256 maintUSDWad, uint256 pnlAdjCollUSDWad)
    {
        AccountSnapshot memory s = pm.valuesLens().accountValues(address(pm), user);
        equityUSDWad = s.equityUSDWad;
        maintUSDWad = s.maintUSDWad;
        pnlAdjCollUSDWad = s.pnlAdjCollUSDWad;
    }

    /// @notice Returns a compact view of an asset's state & live utilization.
    function assetState(address asset)
        external
        view
        returns (uint256 cash, uint256 borrows, uint256 reserves, uint256 utilWad)
    {
        uint256 storedBorrows;
        (, cash, storedBorrows,, reserves,,,) = pm.astate(asset);
        borrows = _previewBorrows(asset);
        /// `reserves` is the sum of the stored reserves and the interest accrued since the last accrual.
        reserves += (borrows - storedBorrows);
        uint256 denom = cash + borrows;
        utilWad = denom == 0 ? 0 : (borrows * Constants.WAD) / denom;
    }

    /// @notice Preview a user's accrued debt units for `asset`.
    function previewUserDebtUnits(
        address user,
        address asset
    )
        public
        view
        returns (uint256 unitsNow)
    {
        uint256 shares = pm.debtShares(user, asset);
        if (shares == 0) return 0;

        uint256 assetTotalShares = pm.totalDebtShares(asset);
        if (assetTotalShares == 0) return 0;

        uint256 borrowsNow = _previewBorrows(asset);
        if (borrowsNow == 0) return 0;

        return Math.mulDiv(shares, borrowsNow, assetTotalShares, Math.Rounding.Ceil);
    }

    function _previewBorrows(address asset) internal view returns (uint256 borrowsNow) {
        (, uint256 cash, uint256 borrows,,,, uint256 lastAccrual,) = pm.astate(asset);
        if (borrows == 0) return 0;

        if (lastAccrual == 0 || block.timestamp == lastAccrual) return borrows;

        uint256 denom = cash + borrows;
        if (denom == 0) return borrows;

        IConfigRegistry.AssetCfg memory c = cfg().getAssetCfg(asset);
        uint256 utilWad = Math.mulDiv(borrows, Constants.WAD, denom);
        uint256 aprWad = IIRM(c.irm).borrowAPR(asset, utilWad);
        uint256 dt = block.timestamp - lastAccrual;
        uint256 interestWad = Math.mulDiv(aprWad, dt, 365 days);
        uint256 interestUnits = Math.mulDiv(borrows, interestWad, Constants.WAD, Math.Rounding.Ceil);
        return borrows + interestUnits;
    }

    function _assetEpoch(address asset) internal view returns (uint32 epoch) {
        (,,,,,,, epoch) = pm.astate(asset);
    }

    /// @notice Preview how much FT a user can claim for `asset` mirroring PositionsManager._settleUser.
    function previewFTClaimFor(address user, address asset) public view returns (uint256 ftAmount) {
        (
            uint256 avail,
            uint256 hold,
            uint40 lastT,
            uint32 lastSettledEpoch,
            uint256 openSupplyTime
        ) = pm.collateral(user, asset);

        uint256 principal = avail + hold;
        uint32 curr = _assetEpoch(asset);
        if (curr == lastSettledEpoch) return 0;

        uint32 openEpoch = lastSettledEpoch + 1;

        (uint40 baseT,,, uint256 X_base,,) = pm.epochs(asset, lastSettledEpoch);
        (uint40 openEndT,, uint256 rateRay,,,) = pm.epochs(asset, openEpoch);
        (,,, uint256 X_now,,) = pm.epochs(asset, curr);

        // Convert any banked supply-time for the epoch that was open when the user last checkpointed.
        if (openSupplyTime != 0 && rateRay != 0) {
            ftAmount = Math.mulDiv(openSupplyTime, rateRay, RAY);
        }

        // Clamp lastT for safety (e.g. users who never interacted)
        uint40 userLastT = lastT;
        if (userLastT < baseT) userLastT = baseT;
        if (userLastT > openEndT) userLastT = openEndT;

        // X(lastT) = X_end[userSettled] + (lastT - t_end[userSettled]) * rate(openEpoch)
        uint256 X_at_lastT = X_base + (uint256(userLastT - baseT) * rateRay);

        if (principal > 0 && X_now > X_at_lastT) {
            ftAmount += Math.mulDiv(principal, X_now - X_at_lastT, RAY);
        }

        // Mirror PositionsManager._settleUser safety cap: never preview more than currently unallocated FT backing.
        // Note: claim-order dependence across multiple assets/users still exists; this is a best-effort bound.
        address ft = pm.FT();
        if (ftAmount > 0 && ft != address(0)) {
            uint256 cash;
            uint256 borrows;
            uint256 totalSupplied;
            (, cash, borrows, totalSupplied,,,,) = pm.astate(ft);
            uint256 backing = cash + borrows;
            uint256 unallocated = backing > totalSupplied ? backing - totalSupplied : 0;
            if (ftAmount > unallocated) ftAmount = unallocated;
        }
    }

    function previewFTClaimTotal(address user) public view returns (uint256 total) {
        address[] memory coll = pm.userCollateralAssets(user);
        uint256 n = coll.length;
        for (uint256 i = 0; i < n; ++i) {
            total += previewFTClaimFor(user, coll[i]);
        }

        address ft = pm.FT();
        if (total > 0 && ft != address(0)) {
            uint256 cash;
            uint256 borrows;
            uint256 totalSupplied;
            (, cash, borrows, totalSupplied,,,,) = pm.astate(ft);
            uint256 backing = cash + borrows;
            uint256 unallocated = backing > totalSupplied ? backing - totalSupplied : 0;
            if (total > unallocated) total = unallocated;
        }
    }

    /// @notice Price & decimals helper for front ends.
    function priceAndDecimals(address asset)
        external
        view
        returns (uint256 pxUSDWad, uint8 decimals_)
    {
        pxUSDWad = IOracleUSD(pm.config().oracleRouter()).priceUSD(asset);
        decimals_ = IERC20Metadata(asset).decimals();
    }

    function _canWithdraw(address user, address asset, uint256 amt) internal view returns (bool) {
        if (amt == 0) return false;
        (uint256 avail,) = pm.getBalance(user, asset);
        if (avail < amt) return false;
        if (pm.withdrawPaused(asset)) return false;

        uint256 cash;
        (, cash,,,,,,) = pm.astate(asset);
        if (cash < amt) return false;

        IConfigRegistry registry = pm.config();

        (uint256 equityUSDWad, uint256 maintUSDWad, uint256 pnlAdjCollUSDWad) = accountValues(user);

        uint16 minHf = registry.marginHfSafeBps();
        uint256 minEquity = registry.marginMinEquityUSDWad();
        if (maintUSDWad == 0) return true;

        // If the asset is not counted as collateral, withdrawing it does not change HF.
        if (!registry.getAssetCfg(asset).collateral) {
            if (RiskLib.hfBps(equityUSDWad, maintUSDWad) < minHf) return false;
            return
                !(minEquity != 0 && pm.userDebtAssets(user).length != 0 && equityUSDWad < minEquity);
        }

        uint256 px = IOracleUSD(registry.oracleRouter()).priceUSD(asset);
        uint8 dec = IERC20Metadata(asset).decimals();
        uint256 scale = 10 ** uint256(dec);
        uint256 BPS = Constants.BPS;

        // Mirror AccountValuesRouter rounding for the withdrawn asset's contribution.
        uint256 valueUSD_old = Math.mulDiv(avail, px, scale); // floor
        uint256 valueUSD_new = Math.mulDiv(avail - amt, px, scale); // floor

        uint256 rawDebtUSDWad = pnlAdjCollUSDWad - equityUSDWad;
        uint256 pnlAdjCollUSDWadNew = pnlAdjCollUSDWad - (valueUSD_old - valueUSD_new);
        uint256 newEquityUSDWad =
            pnlAdjCollUSDWadNew > rawDebtUSDWad ? pnlAdjCollUSDWadNew - rawDebtUSDWad : 0;

        uint16 mmBps = registry.getAssetCfg(asset).mmBps;
        uint256 maintOld = Math.mulDiv(valueUSD_old, mmBps, BPS); // floor
        uint256 maintNew = Math.mulDiv(valueUSD_new, mmBps, BPS); // floor
        uint256 newMaintUSDWad = maintUSDWad - (maintOld - maintNew);

        if (RiskLib.hfBps(newEquityUSDWad, newMaintUSDWad) < minHf) return false;
        return
            !(minEquity != 0 && pm.userDebtAssets(user).length != 0 && newEquityUSDWad < minEquity);
    }

    function canWithdraw(address user, address asset, uint256 amt) external view returns (bool) {
        return _canWithdraw(user, asset, amt);
    }

    function previewMaxWithdraw(
        address user,
        address asset
    )
        external
        view
        returns (uint256 maxUnits)
    {
        (uint256 avail,) = pm.getBalance(user, asset);
        if (avail == 0) return 0;

        uint256 cash;
        (, cash,,,,,,) = pm.astate(asset);
        if (cash == 0) return 0;
        if (pm.withdrawPaused(asset)) return 0;
        uint256 hi = cash < avail ? cash : avail;
        if (hi == 0) return 0;
        if (_canWithdraw(user, asset, hi)) return hi;
        if (!_canWithdraw(user, asset, 1)) return 0;

        uint256 lo = 0;
        uint256 upper = hi;
        while (lo < upper) {
            uint256 mid = (lo + upper + 1) / 2;
            if (_canWithdraw(user, asset, mid)) {
                lo = mid;
            } else {
                upper = mid - 1;
            }
        }
        return lo;
    }
}
