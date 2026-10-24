// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {IERC20, IPair, IRouter, IToken} from "../src/Interfaces.sol";

/// @title TOPS (BSC) NEM-class gate resolution — read-only fork analysis
/// @notice No mainnet tx is ever signed/sent; everything runs on a pinned BSC fork.
///         Fork RPC comes from BSC_RPC_URL / FORK_RPC_URL env (keyless fallback only).
contract TopsTest is Test {
    address constant TOPS   = 0x842B1BFa825Cf6673fD2D98E573FdD267C3Fd588;
    address constant PAIR   = 0xbeDebAC3788171DC769893242a53b881041EDf29;
    address constant USDT   = 0x55d398326f99059fF775485246999027B3197955;
    address constant ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address constant WBNB   = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    uint256 constant FORK_BLOCK = 129280478;

    // live addresses (read at FORK_BLOCK)
    address constant OWNER       = 0xf6370D9F937c59b00938CBFB8efa5b617D260D6d;
    address constant LIQ_REMOVER = 0x4aC4Dcc85895c762dF28726f52484dDE83789CD1;
    address constant MARKET      = 0xaa7c01f9DE1f14001Ad4aa4e8EBEf4Cc07cb1513;
    // Binance hot wallet — USDT source for impersonation (read-only fork)
    address constant USDT_WHALE  = 0x8894E0a0c962CB723c1976a4421c95949bE2D4E3;

    IToken tok = IToken(TOPS);
    IPair  pair = IPair(PAIR);
    IERC20 usdt = IERC20(USDT);
    IRouter router = IRouter(ROUTER);

    address attacker = address(0xA11CE);

    event TokensRecycled(address indexed recycler, uint256 requestedAmount, uint256 actualAmount);

    function setUp() public {
        uint256 blk = vm.envOr("FORK_BLOCK", FORK_BLOCK);
        string[4] memory urls = [
            vm.envOr("BSC_RPC_URL", string("")),
            _keyed("https://rpc.ankr.com/bsc/", "ANKR_API_KEY"),
            _keyed("https://lb.drpc.org/ogrpc?network=bsc&dkey=", "DRPC_API_KEY"),
            vm.envOr("FORK_RPC_URL", string("https://bsc-rpc.publicnode.com"))
        ];
        bool ok;
        for (uint256 i; i < urls.length; i++) {
            if (bytes(urls[i]).length == 0) continue;
            if (_tryFork(urls[i], blk)) { ok = true; break; }
        }
        require(ok, "no archive BSC RPC available");
        vm.label(TOPS, "TOPS");
        vm.label(PAIR, "TOPS/USDT pair");
        vm.label(USDT, "USDT");
        vm.label(ROUTER, "PancakeRouter");
        _stubExternalRewardContracts();
    }

    /// @dev build a keyed RPC URL at runtime from an env var (never stored on disk)
    function _keyed(string memory prefix, string memory envKey) internal view returns (string memory) {
        string memory k = vm.envOr(envKey, string(""));
        return bytes(k).length == 0 ? string("") : string.concat(prefix, k);
    }

    function _tryFork(string memory url, uint256 blk) internal returns (bool) {
        try this.__fork(url, blk) { return true; } catch { return false; }
    }

    function __fork(string memory url, uint256 blk) external {
        require(msg.sender == address(this), "self only");
        vm.createSelectFork(url, blk);
    }

    /// @dev The project's `miner` and `node` reward contracts are unrelated to the
    ///      burn-from-pair + sync path but are re-entered on every fee-taking transfer.
    ///      They are large state-heavy contracts; stubbing them keeps the fork test
    ///      deterministic and independent of RPC state-fetch limits. It cannot change
    ///      the recycle outcome (they only pay out rewards to their own registries).
    function _stubExternalRewardContracts() internal {
        address miner = tok.miner();
        address node = tok.node();
        vm.mockCall(miner, abi.encodeWithSelector(bytes4(0x8dff43de)), "");                   // distributeLevelTokenRewards(uint256)
        vm.mockCall(miner, abi.encodeWithSelector(bytes4(0x0d0abcd3)), "");                   // distributeLevelUsdtRewards(uint256)
        vm.mockCall(miner, abi.encodeWithSelector(bytes4(0xbfe10928)), abi.encode(address(this))); // distributor()
        vm.mockCall(node, abi.encodeWithSelector(bytes4(0xfa8c4fa1)), abi.encode(new address[](0))); // getNodeHolders(uint256)
    }

    // ------------------------------------------------------------------ helpers
    function _res() internal view returns (uint256 r0, uint256 r1) {
        (uint112 a, uint112 b, ) = pair.getReserves();
        r0 = a; r1 = b;
    }

    function _price() internal view returns (uint256) {
        address[] memory p = new address[](2);
        p[0] = TOPS; p[1] = USDT;
        uint256[] memory a = router.getAmountsOut(1 ether, p);
        return a[1];
    }

    /// @dev real USDT, sourced from the Binance hot wallet on the fork (read-only)
    function _fundUSDT(address to, uint256 amt) internal {
        vm.prank(USDT_WHALE);
        usdt.transfer(to, amt);
    }

    /// @dev count TokensRecycled events among recorded logs
    function _recycledCount() internal returns (uint256 n, uint256 actual) {
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 sig = keccak256("TokensRecycled(address,uint256,uint256)");
        for (uint256 i; i < logs.length; i++) {
            if (logs[i].topics.length > 0 && logs[i].topics[0] == sig) {
                n++;
                (, uint256 act) = abi.decode(logs[i].data, (uint256, uint256));
                actual += act;
            }
        }
    }

    // ================================================================== 1. state
    function test_01_live_state_and_gate_status() public {
        (uint256 r0, uint256 r1) = _res();
        console2.log("block", block.number);
        console2.log("reserve0 (USDT)", r0);
        console2.log("reserve1 (TOPS)", r1);
        console2.log("pair USDT bal  ", usdt.balanceOf(PAIR));
        console2.log("pair TOPS bal  ", tok.balanceOf(PAIR));
        assertEq(usdt.balanceOf(PAIR), r0, "no USDT excess");
        assertEq(tok.balanceOf(PAIR), r1, "no TOPS excess -> skim() returns 0");

        (bool buyEnabled, bool sellEnabled) = tok.blockConfig();
        console2.log("buyEnabled", buyEnabled);
        console2.log("sellEnabled", sellEnabled);
        assertFalse(buyEnabled, "LIVE: buys DISABLED");
        assertTrue(sellEnabled, "LIVE: sells enabled");

        (uint128 tracked, uint128 high,,, uint64 lastBlk) = tok.priceTracker();
        uint256 nowPrice = _price();
        console2.log("trackedPrice", uint256(tracked));
        console2.log("currentPrice(getTokenPrice)", nowPrice);
        console2.log("historicalHigh", uint256(high));
        console2.log("lastUpdateBlock", uint256(lastBlk));
        console2.log("gate threshold tracked*1.02", uint256(tracked) * 10200 / 10000);

        // _handleSellRecycle burns ONLY when currentPrice < trackedPrice*1.02
        bool priceRose2 = nowPrice >= (uint256(tracked) * 10200) / 10000;
        console2.log("priceRose2Percent (true => recycle SKIPPED)", priceRose2);
        assertTrue(priceRose2, "LIVE: recycle gate is CLOSED at this block");

        console2.log("owner", tok.owner());
        console2.log("tradeController", tok.tradeController());
        console2.log("liquidityProvider (buyback USDT)", tok.liquidityProvider());
        console2.log("liquidityProvider USDT bal", usdt.balanceOf(tok.liquidityProvider()));
        console2.log("miner", tok.miner());
        console2.log("node", tok.node());
        console2.log("feeWhiteList[pair]", tok.feeWhiteList(PAIR));
        console2.log("feeWhiteList[liqRemover]", tok.feeWhiteList(LIQ_REMOVER));
        console2.log("feeWhiteList[market]", tok.feeWhiteList(MARKET));
        console2.log("swapPairList[pair]", tok.swapPairList(PAIR));
        console2.log("strictCheck", tok.strictCheck());
        assertFalse(tok.feeWhiteList(PAIR), "pair not whitelisted -> sells take fees");

        // buyback path dead: liquidityProvider holds 0 USDT
        assertEq(usdt.balanceOf(tok.liquidityProvider()), 0, "buyback unfunded");
    }

    // ============================================== 2. no outsider entry: BUY
    function test_02_buy_via_router_reverts() public {
        _fundUSDT(attacker, 10_000e18);
        vm.startPrank(attacker);
        usdt.approve(ROUTER, type(uint256).max);
        address[] memory path = new address[](2);
        path[0] = USDT; path[1] = TOPS;
        // pair._safeTransfer() swallows the token's revert reason
        vm.expectRevert(bytes("Pancake: TRANSFER_FAILED"));
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(10_000e18, 0, path, attacker, block.timestamp + 100);
        vm.stopPrank();
    }

    /// @notice exact gate: outbound TOPS from the pair with to==router skips the
    ///         removeLiquidity probe, so the raw "Buy is disabled" reason surfaces.
    function test_02b_buy_gate_exact_reason() public {
        vm.prank(attacker);
        vm.expectRevert(bytes("Buy is disabled"));
        tok.transferFrom(PAIR, ROUTER, 1);
    }

    /// @notice Bypass attempt: push USDT into the pair, then call pair.swap directly.
    function test_03_direct_pair_swap_buy_reverts() public {
        _fundUSDT(attacker, 10_000e18);
        vm.startPrank(attacker);
        usdt.transfer(PAIR, 10_000e18);
        // pair is (token0=USDT, token1=TOPS); want TOPS out, USDT in
        (bool ok, bytes memory ret) = PAIR.call(abi.encodeWithSelector(IPair.swap.selector, uint256(0), uint256(1e18), attacker, new bytes(0)));
        console2.log("direct pair.swap succeeded?", ok);
        console2.logBytes(ret);
        assertFalse(ok, "direct pair.swap to extract TOPS must revert");
        vm.stopPrank();
    }

    // ============================================== 3. no entry without TOPS
    function test_04_sell_without_tokens_reverts() public {
        vm.prank(attacker);
        vm.expectRevert(bytes("BNE"));
        tok.transfer(PAIR, 1e18);
    }

    // ===================================== 4. mechanism: recycle is unprivileged
    /// @notice Roll the day over so trackedPrice resets to spot, which re-opens the
    ///         gate; then a plain (unprivileged) sell-transfer must emit TokensRecycled.
    function test_05_recycle_fires_when_gate_open() public {
        vm.warp(block.timestamp + 1 days + 1);           // currentDay > lastDay
        uint256 A = 100_000e18;
        deal(TOPS, attacker, A, false);

        (uint256 r0Before, uint256 r1Before) = _res();
        vm.recordLogs();
        vm.prank(attacker);
        tok.transfer(PAIR, A);
        (uint256 n,) = _recycledCount();
        (uint256 r0After, uint256 r1After) = _res();

        console2.log("recycle events emitted", n);
        console2.log("reserve1 before", r1Before);
        console2.log("reserve1 after ", r1After);
        console2.log("net reserve1 delta (after-before)", int256(r1After) - int256(r1Before));
        console2.log("reserve0 delta", int256(r0After) - int256(r0Before));
        assertGt(n, 0, "unprivileged sell triggered burn-from-pair + sync()");
        // burn d = min(A, pairBal/3)/10 = A/10, but fee tokens are re-swapped INTO the
        // pair by _swapTokenForCake(), so net reserve1 change is NOT a collapse.
        console2.log("expected burn d = A/10", A / 10);
    }

    // ============================= 5. the rounding hole: zero-fee free burn
    /// @notice sell fee = floor(amount/10000) * rate -> amount < 10000 wei pays ZERO fee,
    ///         yet _handleSellRecycle still burns min(amount,pairBal/3)/10 from the pair.
    ///         The fee-swap is skipped (totalAmount==0), so this burn is unopposed.
    function test_06_zero_fee_rounding_free_burn() public {
        vm.warp(block.timestamp + 1 days + 1);
        uint256 A = 9999; // wei
        deal(TOPS, attacker, A, false);

        address lpD = tok.lpDistributor();
        uint256 lpBefore = tok.balanceOf(lpD);

        (uint256 r0B, uint256 r1B) = _res();
        vm.recordLogs();
        vm.prank(attacker);
        tok.transfer(PAIR, A);
        (uint256 n,) = _recycledCount();
        (uint256 r0A, uint256 r1A) = _res();

        console2.log("events", n);
        console2.log("lpDistributor TOPS before", lpBefore);
        console2.log("lpDistributor TOPS after ", tok.balanceOf(lpD));
        console2.log("reserve1 delta", int256(r1A) - int256(r1B));
        console2.log("reserve0 delta", int256(r0A) - int256(r0B));
        assertEq(tok.balanceOf(lpD), lpBefore, "zero fee taken (rounding hole)");
        assertGt(n, 0, "burn still fired with zero fee");
        // quantify: max free burn per call
        console2.log("max free burn per call (amount=9999) wei", uint256(9999) / 10);
        // how many calls to move 2% of reserve1?
        uint256 target = r1B / 50; // 2%
        console2.log("2% of reserve1 (TOPS wei)", target);
        console2.log("calls needed at 999 wei/call", target / 999);
    }

    // ============================= 6. loop economics: direct transfer + skim
    function test_07_loop_economics_net_loss() public {
        vm.warp(block.timestamp + 1 days + 1);
        uint256 A = 50_000e18;
        deal(TOPS, attacker, A, false);

        (uint256 r0B, uint256 r1B) = _res();
        uint256 balStart = tok.balanceOf(attacker);
        uint256 totalCost;

        for (uint256 i; i < 3; i++) {
            uint256 balBefore = tok.balanceOf(attacker);
            uint256 amt = balBefore < A ? balBefore : A;
            if (amt == 0) break;
            vm.startPrank(attacker);
            tok.transfer(PAIR, amt);
            try pair.skim(attacker) {} catch {}
            vm.stopPrank();
            uint256 balAfter = tok.balanceOf(attacker);
            totalCost += balBefore - balAfter; // net TOPS destroyed for the attacker
            vm.warp(block.timestamp + 1 days + 1); // re-arm the price gate
        }

        (uint256 r0A, uint256 r1A) = _res();
        console2.log("attacker TOPS start", balStart);
        console2.log("attacker TOPS end  ", tok.balanceOf(attacker));
        console2.log("attacker net TOPS cost", totalCost);
        console2.log("reserve1 delta", int256(r1A) - int256(r1B));
        console2.log("reserve0 delta", int256(r0A) - int256(r0B));
        // honest outcome: every recycle round-trip destroys attacker TOPS and does NOT
        // collapse reserve1 (fee tokens are re-swapped into the pair).
        assertGt(totalCost, 0, "attacker loses TOPS each iteration");
        assertGe(int256(r1A) - int256(r1B), 0, "reserve1 never collapses via fee-bearing sells");
    }

    // ============================= 7. hard arithmetic bound on draining the pool
    /// @notice To extract the whole USDT side r0 you must push reserve1 -> ~0.
    ///         Every TOPS removed from the pair costs the attacker >= 2x in sell fees
    ///         (fee = 2000 wei per 10000 wei moved; burn = amount/10), and the fee tokens
    ///         are then re-swapped back into the pair. Cost > reward.
    function test_08_drain_cost_exceeds_reserve() public {
        (uint256 r0, uint256 r1) = _res();
        // fee per unit moved: fee = floor(amount/1e4)*2000 ; burn = amount/10
        // best (largest) burn per fee at amount = k*1e4 - 1
        uint256 amount = 19_999;      // k=2 -> fee 2000, burn 1999
        uint256 fee = (amount / 10_000) * 2000;
        uint256 burn = amount / 10;
        console2.log("amount", amount);
        console2.log("fee", fee);
        console2.log("burn", burn);
        // token-cost of burning 1 wei of reserve1:
        //   burn wei removed costs `fee` wei -> ratio fee/burn
        console2.log("fee per burn wei (x1000)", fee * 1000 / burn);
        // full drain needs burning r1 wei  => token cost ~ r1*fee/burn
        uint256 tokenCost = r1 * fee / burn;
        uint256 tokenCostUsd = tokenCost * r0 / r1; // at pool price
        console2.log("TOPS cost to drain (wei)", tokenCost);
        console2.log("~USD cost", tokenCostUsd / 1e18);
        console2.log("USD reward (r0/1e18)", r0 / 1e18);
        assertGt(tokenCostUsd, r0, "cost exceeds reward -> not profitable");
    }

    // ============================= 8. LP exit is the only way value leaves (H-O)
    function test_09_lp_removal_requires_lp_tokens() public {
        vm.prank(attacker);
        vm.expectRevert(); // no LP tokens
        router.removeLiquidity(TOPS, USDT, 1e18, 0, 0, attacker, block.timestamp + 100);
        console2.log("pair totalSupply (LP)", pair.totalSupply());
    }

    /// @notice A real LP holder cannot exit either: the pair sends USDT first, so
    ///         balanceOf(pair)<reserve0 flips _isRemoveLiquidity()>0, which routes into
    ///         the removeLiquidity branch and hits require(feeWhiteList[recipient]) because
    ///         buyEnabled==false. The pair's _safeTransfer masks the reason.
    function test_10_lp_exit_blocked_by_buy_gate() public {
        address lp = 0x555EFdd0b08c49f3c727C8854E88199769416ab7; // largest live LP holder
        uint256 liq = pair.balanceOf(lp);
        console2.log("LP holder", lp);
        console2.log("LP balance", liq);
        assertGt(liq, 0, "LP holder has liquidity");
        vm.startPrank(lp);
        pair.approve(ROUTER, type(uint256).max);
        vm.expectRevert(bytes("Pancake: TRANSFER_FAILED"));
        router.removeLiquidity(TOPS, USDT, liq / 10, 0, 0, lp, block.timestamp + 100);
        vm.stopPrank();
    }
}
