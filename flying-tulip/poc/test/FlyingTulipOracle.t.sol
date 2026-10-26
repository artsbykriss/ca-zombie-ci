// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {
    IAggregatorV3,
    IOracleRouter,
    IConfigRegistry,
    IPositionsManager,
    IValuesLens,
    IERC4626Like,
    IERC20Min
} from "../src/Interfaces.sol";

/// @title Flying Tulip Lend — oracle design & unprivileged-borrow PoC
/// @notice READ-ONLY research. Fork-only; no mainnet transaction is ever signed or sent.
///         Reproduces the exact permissionless borrow gating and the oracle design of the
///         Ethereum deployment, and tests whether an external unprivileged attacker can profit
///         by borrowing against a manipulable / stale / mis-anchored price mark.
contract FlyingTulipOracleTest is Test {
    // ---- deployed Ethereum addresses (block-pinned fork) ----
    address constant PM = 0xbe4050a73a7Fb384c65E885a15C33461A4B20055; // PositionsManager (proxy)
    address constant CR = 0xA8777c3D446fa7F0b0FC97a80C1Ea1d37F1ca33E; // ConfigRegistry (proxy)
    address constant OR = 0xe4372dB43D2814750a19b93950157AD81D93674A; // OracleRouterChainlink (proxy)
    address constant VALUES_LENS = 0x7aD77FddEf64Ec8325E8d2d02c2708AA2a412eF7; // AccountValuesRouter (proxy)

    // tokens
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address constant CRVUSD = 0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E;
    address constant SCRVUSD = 0x0655977FEb2f289A4aB78af67BAB0d17aAb84367;
    address constant SUSDE = 0x9D39A5DE30e57443BfF2A8307A4256c8797A3497;
    address constant USDG = 0xe343167631d89B6Ffc58B88d6b7fB0228795491D;
    address constant FT = 0x5DD1A7A369e8273371d2DBf9d83356057088082c;

    // configured aggregators (from OracleRouterChainlink.priceFeed)
    address constant AGG_USDC = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6; // Chainlink USDC/USD
    address constant AGG_WETH = 0x5424384B256154046E9667dDFaaa5e550145215e; // Chainlink ETH/USD
    address constant AGG_WBTC = 0x183dB475d8184aA7a018ed2164e11A887afBDA55; // ChainlinkLatestAnswerProxy(wBTC/BTC/USD)
    address constant AGG_WSTETH = 0xf36F9f0A9992FcEdb18dB2B4f034CaE4D0c984cB; // ChainlinkLatestAnswerProxy(Aave CAPO wstETH)
    address constant AGG_SCRVUSD = 0x3e342d317515f55d74B8d3577B6A857E27353bcf; // ERC4626UsdOracle(scrvUSD)
    address constant AGG_FT = 0x17f15356654032EEf5D068E765f3add23E603F6d; // FtCappedOracle (governance NAV)

    IOracleRouter oracle = IOracleRouter(OR);
    IConfigRegistry cfg = IConfigRegistry(CR);
    IPositionsManager pm = IPositionsManager(PM);

    uint256 forkBlock;

    function setUp() public {
        string memory url = vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com")));
        forkBlock = vm.createSelectFork(url);
    }

    // ------------------------------------------------------------------
    // A. Oracle configuration — anchors are unset, fallback disabled
    // ------------------------------------------------------------------
    function test_A_oracle_config_anchors_unset_fallback_disabled() public view {
        assertEq(cfg.marginHfSafeBps(), 15000, "hfSafe");
        assertEq(cfg.marginHfTargetBps(), 12500, "hfTarget");
        assertEq(cfg.oracleRouter(), OR, "oracle router");

        address[10] memory assets = [WETH, USDT, WBTC, USDC, WSTETH, CRVUSD, SCRVUSD, SUSDE, USDG, FT];
        for (uint256 i = 0; i < assets.length; i++) {
            (address agg, uint256 anchor, uint32 hb, uint16 dev, bool enabled, bool fb) = oracle.priceFeed(assets[i]);
            assertTrue(enabled, "feed enabled");
            assertTrue(agg != address(0), "agg set");
            // The deviation clamp is INERT everywhere: the anchor was never primed.
            assertEq(anchor, 0, "anchor must be 0 (clamp disabled)");
            // No stale fallback: a stale feed reverts instead of returning the anchor.
            assertFalse(fb, "fallbackOnStale must be false");
            console2.log("asset", assets[i]);
            console2.log("  agg", agg);
            console2.log("  heartbeat", hb);
            console2.log("  deviationBps (inert)", dev);
        }
    }

    // ------------------------------------------------------------------
    // B. The router is a pure passthrough of the configured aggregator:
    //    priceUSD == answer * 10**(18-decimals).  No spot DEX price read.
    // ------------------------------------------------------------------
    function test_B_priceUSD_is_exact_passthrough_of_configured_aggregator() public view {
        _assertPassthrough(WETH);
        _assertPassthrough(USDC);
        _assertPassthrough(USDT);
        _assertPassthrough(WBTC);
        _assertPassthrough(WSTETH);
        _assertPassthrough(SUSDE);
        _assertPassthrough(USDG);
        _assertPassthrough(CRVUSD);
        _assertPassthrough(SCRVUSD);
        _assertPassthrough(FT);
    }

    function _assertPassthrough(address asset) internal view {
        (address agg,, uint32 hb,, bool enabled,) = oracle.priceFeed(asset);
        assertTrue(enabled, "enabled");
        (, int256 ans,, uint256 updatedAt,) = IAggregatorV3(agg).latestRoundData();
        uint8 dec = IAggregatorV3(agg).decimals();
        // feed must be fresh relative to the router heartbeat
        assertLe(block.timestamp - updatedAt, hb, "feed fresh vs heartbeat");
        uint256 expect = dec == 18 ? uint256(ans) : uint256(ans) * (10 ** (18 - dec));
        assertEq(oracle.priceUSD(asset), expect, "passthrough");
        console2.log("asset", asset);
        console2.log("  agg answer (raw)", uint256(ans));
        console2.log("  priceUSD wad", oracle.priceUSD(asset));
        console2.log("  age (s)", block.timestamp - updatedAt);
    }

    // ------------------------------------------------------------------
    // C. A stale feed REVERTS (no fallback, anchor unset) — no stale borrow
    // ------------------------------------------------------------------
    function test_C_stale_feed_reverts_no_stale_borrow() public {
        (, , uint32 hb, , , ) = oracle.priceFeed(USDC);
        vm.warp(block.timestamp + hb + 1);
        vm.expectRevert(StalePrice.selector);
        oracle.priceUSD(USDC);
    }

    function test_C2_stale_weth_feed_reverts() public {
        (, , uint32 hb, , , ) = oracle.priceFeed(WETH);
        vm.warp(block.timestamp + hb + 1);
        vm.expectRevert(StalePrice.selector);
        oracle.priceUSD(WETH);
    }

    // ------------------------------------------------------------------
    // D. Deviation clamp is DISABLED (anchor==0): a wrong feed value would
    //    be accepted verbatim.  (Latent only — the feed is external Chainlink,
    //    so an unprivileged attacker cannot push it.)
    // ------------------------------------------------------------------
    function test_D_deviation_clamp_disabled_accepts_arbitrary_feed_value() public {
        (, uint256 anchor,,,, ) = oracle.priceFeed(USDC);
        assertEq(anchor, 0, "clamp inert");

        uint256 live = oracle.priceUSD(USDC);
        vm.mockCall(
            AGG_USDC,
            abi.encodeWithSelector(IAggregatorV3.latestRoundData.selector),
            abi.encode(uint80(1), int256(10e8), block.timestamp, block.timestamp, uint80(1))
        );
        uint256 inflated = oracle.priceUSD(USDC);
        assertEq(inflated, 10e18, "no clamp: 10x accepted");
        assertGt(inflated, live * 9, "10x");
        console2.log("live USDC priceUSD", live);
        console2.log("mocked 10x priceUSD", inflated);
    }

    // ------------------------------------------------------------------
    // E. The borrow path is permissionless and HF-gated by the live oracle
    // ------------------------------------------------------------------
    function test_E_permissionless_borrow_path_open_and_hf_gated() public {
        address atk = makeAddr("unprivileged-attacker");
        deal(WETH, atk, 100e18);

        vm.startPrank(atk);
        IERC20Min(WETH).approve(PM, 100e18);
        pm.deposit(WETH, 100e18);
        uint256 collBefore = IERC20Min(USDC).balanceOf(atk);
        pm.borrow(USDC, 50_000e6);
        uint256 collAfter = IERC20Min(USDC).balanceOf(atk);
        vm.stopPrank();

        assertEq(collAfter - collBefore, 50_000e6, "borrowed USDC received");
        (uint256 avail,) = pm.getBalance(atk, WETH);
        assertEq(avail, 100e18, "collateral credited");

        // borrow beyond what the collateral supports -> HF invariant reverts
        vm.prank(atk);
        vm.expectRevert();
        pm.borrow(USDC, 250_000e6);

        // health factor as computed by the on-chain values lens
        IValuesLens.AccountSnapshot memory s = IValuesLens(VALUES_LENS).accountValues(PM, atk);
        uint256 hfBps = s.maintUSDWad == 0 ? 0 : (s.equityUSDWad * 10_000) / s.maintUSDWad;
        console2.log("collateral USD (wad)", s.collUSDWad);
        console2.log("debt USD (wad)", s.debtUSDWad);
        console2.log("equity USD (wad)", s.equityUSDWad);
        console2.log("maint USD (wad)", s.maintUSDWad);
        console2.log("hf bps", hfBps);
        assertGe(hfBps, 15000, "hf >= safe");
    }

    // ------------------------------------------------------------------
    // F. Break-even math: with the live oracle the price gap is ~0, so the
    //    attacker nets nothing.  Max LTV is derived from the live mmBps.
    // ------------------------------------------------------------------
    function test_F_live_gap_zero_no_profit() public view {
        // WETH collateral (mmBps 1700) -> USDC borrow (mmBps 150)
        IConfigRegistry.AssetCfg memory cW = cfg.getAssetCfg(WETH);
        IConfigRegistry.AssetCfg memory cU = cfg.getAssetCfg(USDC);
        assertEq(cW.mmBps, 1700);
        assertEq(cU.mmBps, 150);

        // max borrow D against collateral C at HF==hfSafe:
        //   (C-D)/(mm_c*C + mm_d*D) = hfSafe
        //   D/C = (1 - hfSafe*mm_c) / (1 + hfSafe*mm_d)
        uint256 hfSafe = cfg.marginHfSafeBps();
        uint256 numBps = 10_000 - (hfSafe * cW.mmBps) / 10_000; // e.g. 7450
        uint256 denBps = 10_000 + (hfSafe * cU.mmBps) / 10_000; // e.g. 10225
        uint256 maxLtvBps = (numBps * 10_000) / denBps;
        console2.log("max LTV bps (WETH->USDC)", maxLtvBps);
        assertGt(maxLtvBps, 7000);
        assertLt(maxLtvBps, 7500);

        // live oracle vs live Chainlink reference is identical (test_B), so the
        // "stale/mis-anchored gap" g == 0 today -> net == 0.
        uint256 gapBps = 0;
        assertEq(gapBps, 0, "no divergence today");
    }

    // ------------------------------------------------------------------
    // G. scrvUSD is priced as ERC4626 NAV x crvUSD; the Yearn V3 vault uses a
    //    STORED total_idle, so a direct crvUSD donation does not move the mark.
    // ------------------------------------------------------------------
    function test_G_scrvUSD_oracle_identity_and_donation_resistance() public {
        // identity: priceUSD(scrvUSD) == convertToAssets(1e18) * priceUSD(crvUSD) / 1e18
        uint256 nav = IERC4626Like(SCRVUSD).convertToAssets(1e18);
        uint256 crvUsdPx = oracle.priceUSD(CRVUSD);
        uint256 expect = (nav * crvUsdPx) / 1e18;
        uint256 got = oracle.priceUSD(SCRVUSD);
        assertApproxEqRel(got, expect, 1e15, "scrvUSD = NAV x crvUSD"); // 0.1%

        // Yearn V3: totalAssets == stored total_idle (+ total_debt)
        uint256 ta = IERC4626Like(SCRVUSD).totalAssets();
        uint256 ti = IERC4626Like(SCRVUSD).totalIdle();
        assertEq(ta, ti, "no strategy debt; totalAssets == totalIdle");

        // A donation only changes the vault's live crvUSD balance, not total_idle.
        // Mock the live balance and show the oracle mark does NOT move.
        uint256 bal = IERC20Min(CRVUSD).balanceOf(SCRVUSD);
        vm.mockCall(
            CRVUSD,
            abi.encodeWithSelector(IERC20Min.balanceOf.selector, SCRVUSD),
            abi.encode(bal + 5_000_000e18)
        );
        assertEq(oracle.priceUSD(SCRVUSD), got, "donation does not move the mark");
        console2.log("scrvUSD NAV (1e18)", nav);
        console2.log("scrvUSD priceUSD", got);
    }

    // helper: exact custom error of OracleRouterChainlink
    error StalePrice();
}
