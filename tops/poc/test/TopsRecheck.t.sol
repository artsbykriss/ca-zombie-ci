// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {IERC20, IPair, IRouter, IToken} from "../src/Interfaces.sol";

/// @title TOPS (BSC) NEM-class — LIVE RECHECK at a current head block
/// @notice The 2026-10-23 analysis (Tops.t.sol, block 129280478) found two of the
///         three barriers were state-dependent. This recheck forks at HEAD and asks
///         whether the changed state (buyEnabled=true, price gate OPEN) opens a path.
///         Read-only: no tx is ever signed/sent; everything is a fork simulation.
contract TopsRecheck is Test {
    address constant TOPS   = 0x842B1BFa825Cf6673fD2D98E573FdD267C3Fd588;
    address constant PAIR   = 0xbeDebAC3788171DC769893242a53b881041EDf29;
    address constant USDT   = 0x55d398326f99059fF775485246999027B3197955;
    address constant ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    // Binance hot wallet — USDT source for impersonation (read-only fork)
    address constant USDT_WHALE = 0x8894E0a0c962CB723c1976a4421c95949bE2D4E3;

    IToken tok = IToken(TOPS);
    IPair  pair = IPair(PAIR);
    IERC20 usdt = IERC20(USDT);
    IRouter router = IRouter(ROUTER);

    address attacker = address(0xB0B);
    address lp = 0x555EFdd0b08c49f3c727C8854E88199769416ab7; // largest live LP holder

    event TokensRecycled(address indexed recycler, uint256 requestedAmount, uint256 actualAmount);

    function setUp() public {
        string[4] memory urls = [
            vm.envOr("BSC_RPC_URL", string("")),
            _keyed("https://rpc.ankr.com/bsc/", "ANKR_API_KEY"),
            _keyed("https://lb.drpc.org/ogrpc?network=bsc&dkey=", "DRPC_API_KEY"),
            vm.envOr("FORK_RPC_URL", string("https://bsc-rpc.publicnode.com"))
        ];
        bool ok;
        for (uint256 i; i < urls.length; i++) {
            if (bytes(urls[i]).length == 0) continue;
            if (_tryForkHead(urls[i])) { ok = true; break; }
        }
        require(ok, "no BSC RPC available");
        _stubExternalRewardContracts();
    }

    function _keyed(string memory prefix, string memory envKey) internal view returns (string memory) {
        string memory k = vm.envOr(envKey, string(""));
        return bytes(k).length == 0 ? string("") : string.concat(prefix, k);
    }

    function _tryForkHead(string memory url) internal returns (bool) {
        try this.__forkHead(url) { return true; } catch { return false; }
    }

    function __forkHead(string memory url) external {
        require(msg.sender == address(this), "self only");
        vm.createSelectFork(url); // HEAD
    }

    function _stubExternalRewardContracts() internal {
        address miner = tok.miner();
        address node = tok.node();
        vm.mockCall(miner, abi.encodeWithSelector(bytes4(0x8dff43de)), "");
        vm.mockCall(miner, abi.encodeWithSelector(bytes4(0x0d0abcd3)), "");
        vm.mockCall(miner, abi.encodeWithSelector(bytes4(0xbfe10928)), abi.encode(address(this)));
        vm.mockCall(node, abi.encodeWithSelector(bytes4(0xfa8c4fa1)), abi.encode(new address[](0)));
    }

    function _res() internal view returns (uint256 r0, uint256 r1) {
        (uint112 a, uint112 b, ) = pair.getReserves();
        r0 = a; r1 = b;
    }

    function _fundUSDT(address to, uint256 amt) internal {
        vm.prank(USDT_WHALE);
        usdt.transfer(to, amt);
    }

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

    // ================================================= R1: live state at HEAD
    function test_R1_live_state_head_gate_is_OPEN() public {
        (uint256 r0, uint256 r1) = _res();
        console2.log("HEAD block", block.number);
        console2.log("reserve0 USDT", r0);
        console2.log("reserve1 TOPS", r1);
        console2.log("pair USDT bal", usdt.balanceOf(PAIR));
        console2.log("pair TOPS bal", tok.balanceOf(PAIR));
        console2.log("mainPair", tok.mainPair());
        assertEq(tok.mainPair(), PAIR, "mainPair is the analysed pair");
        assertEq(usdt.balanceOf(PAIR), r0, "no USDT excess");
        assertEq(tok.balanceOf(PAIR), r1, "no TOPS excess");

        (bool buyEnabled, bool sellEnabled) = tok.blockConfig();
        console2.log("buyEnabled", buyEnabled);
        console2.log("sellEnabled", sellEnabled);
        // STATE CHANGED vs block 129280478: buys were disabled then, enabled now.
        assertTrue(buyEnabled, "HEAD: buys are now ENABLED");

        (uint128 tracked, uint128 high,,, uint64 lastBlk) = tok.priceTracker();
        (,,,,, uint256 realTime) = tok.getPriceInfo();
        console2.log("trackedPrice", uint256(tracked));
        console2.log("realTimePrice(getTokenPrice)", realTime);
        console2.log("historicalHigh", uint256(high));
        console2.log("lastUpdateBlock", uint256(lastBlk));
        console2.log("gate threshold tracked*1.02", uint256(tracked) * 10200 / 10000);
        bool priceRose2 = realTime >= (uint256(tracked) * 10200) / 10000;
        console2.log("priceRose2Percent (true => recycle SKIPPED)", priceRose2);
        // STATE CHANGED vs block 129280478: the gate was CLOSED then; document HEAD.
        // (Do not hard-assert the boolean: it is a live price condition.)
        console2.log("=> recycle gate OPEN at HEAD?", !priceRose2);
    }

    // ================================================= R2: outsider can now BUY
    function test_R2_buy_now_succeeds() public {
        (bool buyEnabled,) = tok.blockConfig();
        if (!buyEnabled) { console2.log("HEAD: buys disabled again; entry closed - skip"); return; }
        _fundUSDT(attacker, 10_000e18);
        (uint256 r0b, uint256 r1b) = _res();
        vm.startPrank(attacker);
        usdt.approve(ROUTER, type(uint256).max);
        address[] memory path = new address[](2);
        path[0] = USDT; path[1] = TOPS;
        uint256 usdtIn = 10_000e18;
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(usdtIn, 0, path, attacker, block.timestamp + 100);
        vm.stopPrank();
        uint256 got = tok.balanceOf(attacker);
        (uint256 r0a, uint256 r1a) = _res();
        console2.log("USDT in", usdtIn);
        console2.log("TOPS received", got);
        console2.log("d reserve0 (USDT)", int256(r0a) - int256(r0b));
        console2.log("d reserve1 (TOPS)", int256(r1a) - int256(r1b));
        uint256 topsOut = r1b - r1a;                       // TOPS the pool sent (pre-tax)
        console2.log("buy tax bp (10000=100%)", topsOut == 0 ? 0 : (topsOut - got) * 10000 / topsOut);
        assertGt(got, 0, "entry is OPEN: outsider buys TOPS");
    }

    // ============================= R3: sell fires recycle but reserve1 does NOT collapse
    function test_R3_sell_recycle_no_reserve_collapse() public {
        (bool buyEnabled,) = tok.blockConfig();
        if (!buyEnabled) { console2.log("HEAD: buys disabled; skip"); return; }
        _fundUSDT(attacker, 20_000e18);
        vm.startPrank(attacker);
        usdt.approve(ROUTER, type(uint256).max);
        address[] memory buyPath = new address[](2);
        buyPath[0] = USDT; buyPath[1] = TOPS;
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(20_000e18, 0, buyPath, attacker, block.timestamp + 100);
        uint256 held = tok.balanceOf(attacker);
        vm.stopPrank();

        (uint256 r0b, uint256 r1b) = _res();
        vm.recordLogs();
        vm.startPrank(attacker);
        tok.approve(ROUTER, type(uint256).max);
        address[] memory sellPath = new address[](2);
        sellPath[0] = TOPS; sellPath[1] = USDT;
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(held, 0, sellPath, attacker, block.timestamp + 100);
        vm.stopPrank();
        (uint256 n,) = _recycledCount();
        (uint256 r0a, uint256 r1a) = _res();
        console2.log("TOPS sold", held);
        console2.log("TokensRecycled events", n);
        console2.log("d reserve1 (TOPS)", int256(r1a) - int256(r1b));
        console2.log("d reserve0 (USDT)", int256(r0a) - int256(r0b));
        // The burn (<= sellAmount/10) is smaller than the sell fee (20%) which is
        // re-swapped INTO the pair, so reserve1 cannot collapse to ~0.
        assertGe(int256(r1a) - int256(r1b), 0, "reserve1 does not collapse");
    }

    // ============================= R3b: recycle fires at HEAD for a pre-held seller
    /// @notice With the gate OPEN at HEAD, an existing TOPS holder (no buy that moves
    ///         the price) selling through the router fires burn-from-pair + sync().
    ///         Confirms the primitive is live AND that reserve1 still does not collapse.
    function test_R3b_recycle_fires_at_head() public {
        (uint128 tracked,, ,, ) = tok.priceTracker();
        (,,,,, uint256 realTime) = tok.getPriceInfo();
        bool priceRose2 = realTime >= (uint256(tracked) * 10200) / 10000;
        if (priceRose2) { console2.log("HEAD: price gate CLOSED; recycle would be skipped - skip"); return; }
        uint256 A = 100_000e18;
        deal(TOPS, attacker, A, false);           // simulate an existing holder
        (uint256 r0b, uint256 r1b) = _res();
        vm.recordLogs();
        vm.startPrank(attacker);
        tok.approve(ROUTER, type(uint256).max);
        address[] memory sellPath = new address[](2);
        sellPath[0] = TOPS; sellPath[1] = USDT;
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(A, 0, sellPath, attacker, block.timestamp + 100);
        vm.stopPrank();
        (uint256 n, uint256 actual) = _recycledCount();
        (uint256 r0a, uint256 r1a) = _res();
        console2.log("TOPS sold", A);
        console2.log("TokensRecycled events", n);
        console2.log("recycled (burn) amount", actual);
        console2.log("d reserve1 (TOPS)", int256(r1a) - int256(r1b));
        console2.log("d reserve0 (USDT)", int256(r0a) - int256(r0b));
        assertGt(n, 0, "gate OPEN at HEAD: unprivileged sell fires burn-from-pair + sync()");
        assertGe(int256(r1a) - int256(r1b), 0, "reserve1 does not collapse (fee re-swapped in)");
    }

    // ================================================= R4: full round-trip PnL
    function test_R4_roundtrip_pnl_negative() public {
        (bool buyEnabled,) = tok.blockConfig();
        if (!buyEnabled) { console2.log("HEAD: buys disabled; skip"); return; }
        uint256 start = 20_000e18;
        _fundUSDT(attacker, start);
        uint256 usdt0 = usdt.balanceOf(attacker);
        vm.startPrank(attacker);
        usdt.approve(ROUTER, type(uint256).max);
        address[] memory buyPath = new address[](2);
        buyPath[0] = USDT; buyPath[1] = TOPS;
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(start, 0, buyPath, attacker, block.timestamp + 100);
        uint256 held = tok.balanceOf(attacker);
        tok.approve(ROUTER, type(uint256).max);
        address[] memory sellPath = new address[](2);
        sellPath[0] = TOPS; sellPath[1] = USDT;
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(held, 0, sellPath, attacker, block.timestamp + 100);
        vm.stopPrank();
        uint256 usdt1 = usdt.balanceOf(attacker);
        console2.log("USDT start", usdt0);
        console2.log("USDT end  ", usdt1);
        console2.log("net PnL (USDT wei)", int256(usdt1) - int256(usdt0));
        assertLt(usdt1, usdt0, "buy->sell round trip is a net loss");
    }

    // ================================================= R5: LP exit status at HEAD
    function test_R5_lp_exit_status_head() public {
        uint256 liq = pair.balanceOf(lp);
        console2.log("LP holder", lp);
        console2.log("LP balance", liq);
        if (liq == 0) { console2.log("no LP held at this address; skip"); return; }
        vm.startPrank(lp);
        pair.approve(ROUTER, type(uint256).max);
        (bool ok, bytes memory ret) = ROUTER.call(
            abi.encodeWithSelector(IRouter.removeLiquidity.selector, TOPS, USDT, liq / 100, 0, 0, lp, block.timestamp + 100)
        );
        vm.stopPrank();
        console2.log("removeLiquidity succeeded?", ok);
        if (!ok) console2.logBytes(ret);
        // Document only — outcome is owner-state dependent.
    }

    // ================================================= R6: drain cost bound
    function test_R6_drain_cost_exceeds_reserve() public {
        (uint256 r0, uint256 r1) = _res();
        uint256 amount = 19_999;          // best burn-per-fee ratio
        uint256 fee = (amount / 10_000) * 2000;
        uint256 burn = amount / 10;
        console2.log("fee", fee);
        console2.log("burn", burn);
        uint256 tokenCost = r1 * fee / burn;
        uint256 tokenCostUsd = tokenCost * r0 / r1;
        console2.log("TOPS cost to drain (wei)", tokenCost);
        console2.log("~USD cost", tokenCostUsd / 1e18);
        console2.log("USD reward r0", r0 / 1e18);
        assertGt(tokenCostUsd, r0, "cost exceeds reward -> unprofitable");
    }
}
