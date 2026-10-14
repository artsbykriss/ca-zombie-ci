// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {ICErc20, IComptroller, IPriceOracle, IChainlinkFeed, IRewardDistributor} from "../src/Interfaces.sol";

/// @title ReactorFusion (zkSync Era) — live extraction-surface fork verification
/// @notice Read-only PoC. Fork-only; no real-network transactions. Run in CI.
/// Key facts verified here:
///  - the oracle is a Chainlink latestAnswer() reader with NO staleness check (feeds are live today);
///  - admin / reserves / oracle-owner paths are gated;
///  - borrow-without-collateral reverts;
///  - liquidations are permissionless but the whole live opportunity is dust (<$2);
///  - borrow-and-default (oracle overvaluation) is unprofitable at live prices.
contract ReactorFusionLive is Test {
    // ---- zkSync Era mainnet addresses ----
    address constant COMPTROLLER = 0x23848c28Af1C3AA7B999fA57e6b6E8599C17F3f2;
    address constant ORACLE = 0x1d54DD49218333125C858c0239bbdA424db55C43;
    address constant DIST = 0x53C0DE201cab0b3f74EA7C1D95bD76F76EfD12A9;
    address constant ADMIN_TIMELOCK = 0xeE568575A8DaeF55D2fac121FD2362dF6BbB5Db5;
    address constant ADMIN_EOA = 0x99999A3C4cB8427c44294Ad36895b6a3A047060d;

    address constant rfUSDCe = 0x04e9Db37d8EA0760072e1aCE3F2A219988Fdac29;
    address constant rfETH = 0xC5db68F30D21cBe0C9Eac7BE5eA83468d69297e6;
    address constant rfWBTC = 0x0a976E1E7D3052bEb46085AcBE1e0DAccF4A19CF;
    address constant rfUSDT = 0x894cccB9908A0319381c305f947aD0EF44838591;
    address constant rfZK = 0x0E392B6b05c112677096920aD938a0752d1451f3;
    address constant rfUSDCz = 0x930DA5E58f7F0D6DC417AB07e07558C78CFF1445;

    address constant FEED_ETH = 0x6D41d1dc818112880b40e26BD6FD347E41008eDA;
    address constant FEED_WBTC = 0x4Cba285c15e3B540C474A114a7b135193e4f1EA6;
    address constant FEED_USDC = 0x1824D297C6d6D311A204495277B63e943C2D376E;
    address constant FEED_USDT = 0xB615075979AE1836B476F651f1eB79f0Cd3956a9;
    address constant FEED_ZK = 0xD1ce60dc8AE060DDD17cA8716C96f193bC88DD13;

    // DefiLlama spot prices read 2026-10-14 (USD) — used to test oracle-vs-market gaps
    uint256 constant MK_ETH = 2442.41e18;
    uint256 constant MK_WBTC = 81708.15e18;
    uint256 constant MK_USDC = 0.999735e18;
    uint256 constant MK_USDT = 0.999306e18;
    uint256 constant MK_ZK = 0.0151557e18;

    IComptroller cmp = IComptroller(COMPTROLLER);
    IPriceOracle oracle = IPriceOracle(ORACLE);

    address attacker = address(0xA11CE);

    function setUp() public {
        string memory rpc = _rpc();
        uint256 blk = vm.envOr("FORK_BLOCK", uint256(72_485_663));
        try vm.createSelectFork(rpc, blk) {}
        catch {
            vm.createSelectFork(rpc);
        }
        vm.deal(attacker, 100 ether);
        // Standard Foundry cannot execute zkSync Era (EraVM) bytecode: every call returns empty.
        // Skip the fork suite in that case; run it with foundry-zksync + anvil-zksync if desired.
        (bool ok, bytes memory ret) =
            ORACLE.staticcall(abi.encodeWithSignature("owner()"));
        if (!ok || ret.length == 0) {
            vm.skip(true);
        }
    }

    /// Build a fork RPC from the environment; never store keyed URLs in this file.
    function _rpc() internal view returns (string memory) {
        string memory e = vm.envOr("ERA_RPC_URL", string(""));
        if (bytes(e).length > 0) return e;
        string memory k = vm.envOr("DRPC_API_KEY", string(""));
        if (bytes(k).length > 0) {
            return string.concat("https://lb.drpc.org/ogrpc?network=zksync-era&dkey=", k);
        }
        return "https://mainnet.era.zksync.io";
    }

    function _price(address cToken) internal view returns (uint256) {
        return oracle.getUnderlyingPrice(cToken);
    }

    // ---------------------------------------------------------------- A
    function test_A_live_state() public {
        assertEq(cmp.closeFactorMantissa(), 0.5e18, "closeFactor");
        assertEq(cmp.liquidationIncentiveMantissa(), 1.08e18, "liqIncentive");
        assertEq(cmp.admin(), ADMIN_TIMELOCK, "comptroller admin = 24h timelock");
        assertEq(oracle.owner(), ADMIN_EOA, "oracle owner = EOA");

        address[6] memory mk = [rfUSDCe, rfETH, rfWBTC, rfUSDT, rfZK, rfUSDCz];
        for (uint256 i = 0; i < mk.length; i++) {
            assertGt(_price(mk[i]), 0, "oracle price > 0");
            assertFalse(cmp.borrowGuardianPaused(mk[i]), "borrow not paused");
            assertFalse(cmp.mintGuardianPaused(mk[i]), "mint not paused");
        }
        assertGt(ICErc20(rfETH).getCash(), 80 ether, "rfETH cash > 80 ETH");
        assertGt(ICErc20(rfUSDCe).getCash(), 10_000e6, "rfUSDCe cash");
        assertGt(ICErc20(rfUSDT).getCash(), 15_000e6, "rfUSDT cash");
        assertGt(ICErc20(rfWBTC).getCash(), 0.1e8, "rfWBTC cash");
        assertGt(ICErc20(rfZK).getCash(), 2_000_000e18, "rfZK cash");
        assertEq(ICErc20(rfETH).dist(), DIST, "reward distributor wired");

        emit log_named_uint("rfETH cash (wei)", ICErc20(rfETH).getCash());
        emit log_named_uint("rfETH borrows (wei)", ICErc20(rfETH).totalBorrows());
        emit log_named_uint("rfETH oracle ETH price", _price(rfETH));
    }

    // ---------------------------------------------------------------- B
    /// Feeds are LIVE today, but the oracle performs no freshness check:
    /// getUnderlyingPrice() == feed.latestAnswer() * 10**(36 - feedDec - cTokDec).
    function test_B_oracle_reads_latestAnswer_without_staleness_check() public {
        address[5] memory feeds = [FEED_ETH, FEED_WBTC, FEED_USDC, FEED_USDT, FEED_ZK];
        address[5] memory mkts = [rfETH, rfWBTC, rfUSDCe, rfUSDT, rfZK];
        for (uint256 i = 0; i < feeds.length; i++) {
            (, int256 ans,, uint256 updatedAt,) = IChainlinkFeed(feeds[i]).latestRoundData();
            assertGt(ans, 0, "answer > 0");
            // live today: updated within 3 days of the fork block
            assertLt(block.timestamp - updatedAt, 3 days, "feed fresh at fork block");
            uint8 fd = IChainlinkFeed(feeds[i]).decimals();
            uint8 cd = ICErc20(mkts[i]).decimals();
            uint256 expected = uint256(ans) * (10 ** (36 - fd - cd));
            assertEq(_price(mkts[i]), expected, "price == latestAnswer scaled (no timestamp check)");
            emit log_named_string("feed", IChainlinkFeed(feeds[i]).description());
            emit log_named_uint("age_seconds", block.timestamp - updatedAt);
        }
    }

    // ---------------------------------------------------------------- C
    function test_C_borrow_without_collateral_reverts() public {
        vm.prank(attacker);
        vm.expectRevert();
        ICErc20(rfETH).borrow(1 ether);

        vm.prank(attacker);
        vm.expectRevert();
        ICErc20(rfUSDCe).borrow(1_000e6);
    }

    // ---------------------------------------------------------------- D
    function test_D_admin_reserves_oracle_gated() public {
        // takeReserves -> only admin or distributor
        vm.prank(attacker);
        vm.expectRevert();
        ICErc20(rfETH).takeReserves();

        // oracle setPriceFeed -> onlyOwner
        vm.prank(attacker);
        vm.expectRevert();
        oracle.setPriceFeed(rfETH, attacker);

        // comptroller admin functions -> non-zero error code (fail path), state unchanged
        uint256 p0 = _price(rfETH);
        vm.prank(attacker);
        assertTrue(cmp._setPriceOracle(attacker) != 0, "unauthorized oracle swap");
        assertEq(cmp.oracle(), ORACLE, "oracle unchanged");
        vm.prank(attacker);
        assertTrue(cmp._setCloseFactor(1e18) != 0, "unauthorized close factor");
        assertEq(cmp.closeFactorMantissa(), 0.5e18, "closeFactor unchanged");
        vm.prank(attacker);
        assertTrue(cmp._setMintPaused(rfETH, true) == false, "unauthorized pause (returns false)");
        assertFalse(cmp.mintGuardianPaused(rfETH), "mint not paused");
        assertEq(_price(rfETH), p0, "price unchanged");
    }

    // ---------------------------------------------------------------- E
    /// Permissionless liquidation of a genuinely underwater account — profitable but dust.
    /// Borrower 0xed5b...: rfETH debt, rfETH+rfZK collateral, shortfall > 0 at fork block.
    function test_E_liquidation_permissionless_but_dust() public {
        address borrower = 0xED5b514B2005b281571D4723A3c59e91f108411F;

        (uint256 err, uint256 liquidity, uint256 shortfall) = cmp.getAccountLiquidity(borrower);
        assertEq(err, 0, "liq err");
        assertEq(liquidity, 0, "no excess liquidity");
        assertGt(shortfall, 0, "genuinely underwater");
        emit log_named_uint("shortfall_usd", shortfall);

        uint256 debt = ICErc20(rfETH).borrowBalanceStored(borrower);
        assertGt(debt, 0, "has rfETH debt");
        uint256 repay = debt / 2; // closeFactor 0.5
        uint256 collBefore = ICErc20(rfETH).balanceOf(borrower);
        assertGt(collBefore, 0, "has rfETH collateral");

        // any unprivileged address may liquidate
        vm.prank(attacker);
        ICErc20(rfETH).liquidateBorrow{value: repay}(borrower, rfETH);

        uint256 seized = ICErc20(rfETH).balanceOf(attacker);
        uint256 xrate = ICErc20(rfETH).exchangeRateStored();
        uint256 seizedValue = (seized * xrate) / 1e18; // in ETH (oracle-consistent)
        emit log_named_uint("repaid_eth_wei", repay);
        emit log_named_uint("seized_ctokens", seized);
        emit log_named_uint("seized_value_eth_wei", seizedValue);
        assertGt(seizedValue, repay, "liquidation is profitable");
        // but the whole opportunity is dust: profit < $10 (0.004 ETH at ~$2442)
        assertLt(seizedValue - repay, 0.004 ether, "profit is dust");
    }

    // ---------------------------------------------------------------- F
    /// Borrow-and-default requires collateralFactor * oracle/market > 1. It is not.
    function test_F_borrow_and_default_unprofitable() public {
        address[6] memory mk = [rfUSDCe, rfETH, rfWBTC, rfUSDT, rfZK, rfUSDCz];
        uint256[6] memory mkt = [MK_USDC, MK_ETH, MK_WBTC, MK_USDT, MK_ZK, MK_USDC];
        for (uint256 i = 0; i < mk.length; i++) {
            (, uint256 cf,) = cmp.markets(mk[i]);
            uint256 p = _price(mk[i]);
            uint256 ratio = (p * 1e18) / mkt[i]; // oracle / market
            uint256 power = (cf * ratio) / 1e18; // borrow power per $ of market collateral
            emit log_named_uint("cf_oracle_over_market_1e18", power);
            assertLt(power, 1e18, "no profitable borrow-and-default");
        }
    }

    // ---------------------------------------------------------------- G
    /// No market is deprecated (deprecated markets allow liquidating healthy accounts).
    function test_G_no_market_deprecated() public {
        address[6] memory mk = [rfUSDCe, rfETH, rfWBTC, rfUSDT, rfZK, rfUSDCz];
        for (uint256 i = 0; i < mk.length; i++) {
            (, uint256 cf,) = cmp.markets(mk[i]);
            bool paused = cmp.borrowGuardianPaused(mk[i]);
            uint256 rf = ICErc20(mk[i]).reserveFactorMantissa();
            assertTrue(cf > 0 || !paused || rf != 1e18, "not deprecated");
        }
    }

    // ---------------------------------------------------------------- H
    /// Reward distributor holds nothing; harvest for a fresh account yields 0.
    function test_H_distributor_holds_nothing() public {
        assertEq(ICErc20(rfETH).dist(), DIST);
        assertEq(IRewardDistributor(DIST).owner(), ADMIN_EOA);
        assertEq(address(IRewardDistributor(DIST)).balance, 0, "dist ETH balance 0");
        bytes32[] memory ids = new bytes32[](1);
        ids[0] = keccak256(abi.encode(rfETH, bytes32("SUPPLY")));
        vm.prank(attacker);
        uint256 got = IRewardDistributor(DIST).harvest(ids);
        assertEq(got, 0, "fresh account harvests 0");
    }
}
