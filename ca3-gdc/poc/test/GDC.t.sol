// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {
    IERC20Like, IPairLike, IRouterLike, IFactoryLike, IGDCToken, IGDCMain, IGDCReserveDistributor
} from "../src/Interfaces.sol";

/// @title GDC (BSC) residual-value verification
/// @notice Read-only fork tests. No mainnet transactions. All state is a local Anvil fork.
///         Purpose: measure what an unprivileged attacker can still extract from the
///         GDC/WBNB pair after the 2026-11-09 exploit, and to test the corpus claim that
///         "44.08 WBNB (~$30k) is still live".
contract GDCResidualTest is Test {
    // --- live BSC addresses (verified) ---
    address constant TOKEN = 0x39a90d082e19bD2AC30DA6964D3d2FDa50077777;
    address constant PAIR = 0xe3349Ca6AC1656e02B20b8d5a4C095e28255eb0A;
    address constant MAIN = 0x8955Be303f033a837f7C3c407e0B2b3f9bC4fD5C;
    address constant DIST = 0x3cf55c7c22C6555139c818aB7a7a89aFf70F8360;
    address constant REFERRALS = 0xD3Ba7d944544d3416131663919580e039294130E;
    address constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address constant ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    // --- pinned fork blocks ---
    // Latest block at analysis time (2026-11-10). Reserves read from two independent RPCs.
    uint256 constant FORK_LATEST = 132_680_921;
    // Block immediately before the documented 2026-11-09 exploit tx
    // 0x1427d8e6f543710413886a1624e08f0b1cff8e62e9aa3e00eb04a61b86c30872
    uint256 constant FORK_PRE_EXPLOIT = 132_546_182;
    // Block of that exploit tx (both sides of the reserve change).
    uint256 constant FORK_POST_EXPLOIT = 132_546_183;
    // Block immediately before the observed 2026-11-10 copy-cat drain
    // 0x0f7bb6a7d12c9d25eb1fbee4f280acaf9fafd0ba4bab58e48a66f6cef9c002ce
    uint256 constant FORK_BEFORE_COPYCAT = 132_672_605;

    // --- measured constants ---
    uint256 constant BNB_USD_E18 = 687.72e18; // DefiLlama, 2026-11-10T~11:20Z
    uint256 constant BSC_GAS_PRICE = 50_000_000; // 0.05 gwei, eth_gasPrice at analysis time
    uint256 constant EXPLOIT_GAS_USED = 1_003_754; // 2026-11-10 copy-cat tx gasUsed

    // Live reserves at FORK_LATEST (raw wei, 18 decimals both sides)
    uint256 constant R0_LATEST = 12_316_971_177_631_596_075_223; // 12,316.971177 GDC
    uint256 constant R1_LATEST = 32_856_030_398_949; // 0.000032856030398949 WBNB  <-- $0.0226

    /// Archive RPC (needed for the pinned/historical blocks) > ANKR key > plain BSC RPC > keyless public.
    function _rpc() internal view returns (string memory) {
        string memory a = vm.envOr("BSC_ARCHIVE_RPC_URL", string(""));
        if (bytes(a).length > 0) return a;
        string memory k = vm.envOr("ANKR_API_KEY", string(""));
        if (bytes(k).length > 0) return string.concat("https://rpc.ankr.com/bsc/", k);
        string memory b = vm.envOr("BSC_RPC_URL", string(""));
        if (bytes(b).length > 0) return b;
        return "https://bsc-dataseed.binance.org";
    }

    function _haveArchive() internal view returns (bool) {
        return bytes(vm.envOr("BSC_ARCHIVE_RPC_URL", string(""))).length > 0
            || bytes(vm.envOr("ANKR_API_KEY", string(""))).length > 0;
    }

    function _historicalEnabled() internal view returns (bool) {
        return vm.envOr("RUN_HISTORICAL", uint256(0)) != 0 && _haveArchive();
    }

    /// Pinned fork when an archive RPC is available, otherwise the node's latest block.
    function _forkLatest() internal {
        if (_haveArchive()) {
            vm.createSelectFork(_rpc(), FORK_LATEST);
        } else {
            vm.createSelectFork(_rpc());
        }
    }

    function _pairPath(address a, address b) internal pure returns (address[] memory p) {
        p = new address[](2);
        p[0] = a;
        p[1] = b;
    }

    // ------------------------------------------------------------------
    // 1. Live state: the residual is dust, not $30k
    // ------------------------------------------------------------------
    function test_01_liveResidualIsDust() public {
        _forkLatest();

        (uint112 r0, uint112 r1, uint32 ts) = IPairLike(PAIR).getReserves();
        uint256 wbnbBal = IERC20Like(WBNB).balanceOf(PAIR);
        uint256 gdcBal = IERC20Like(TOKEN).balanceOf(PAIR);

        if (_haveArchive()) {
            assertEq(uint256(r0), R0_LATEST, "GDC reserve changed");
            assertEq(uint256(r1), R1_LATEST, "WBNB reserve changed");
        }
        // In every case the WBNB side must be dust (< 0.0001 WBNB).
        assertLt(uint256(r1), 1e14, "WBNB reserve is not dust");
        assertEq(wbnbBal, uint256(r1), "pair WBNB balance != reserve");
        assertEq(gdcBal, uint256(r0), "pair GDC balance != reserve");
        assertEq(IERC20Like(WBNB).decimals(), 18);
        assertEq(IERC20Like(TOKEN).decimals(), 18);

        uint256 wbnbUsdE18 = wbnbBal * BNB_USD_E18 / 1e18;
        // "44.08 WBNB (~$30k)" claim would be 44.08e18 wei; the real value is 1.6e6x smaller.
        assertLt(wbnbBal, 44.08e18 / 1_000_000, "pair holds more than the dust bound");

        console2.log("=== GDC/WBNB live residual @ block", FORK_LATEST);
        console2.log("GDC reserve (18dp)        :", uint256(r0));
        console2.log("WBNB reserve (wei)        :", wbnbBal);
        console2.log("WBNB reserve (decimal)    :", wbnbBal);
        console2.log("WBNB reserve USD e18      :", wbnbUsdE18);
        console2.log("blockTimestampLast        :", uint256(ts));

        // max sell = 10% of the 12,316.97 GDC reserve
        uint256 maxSell = IGDCToken(TOKEN).maxSellAmount();
        assertEq(maxSell, uint256(r0) / 10);
        console2.log("maxSellAmount (wei)       :", maxSell);
        console2.log("currentStage              :", IGDCToken(TOKEN).currentStage());
        console2.log("reserveDistributor        :", IGDCToken(TOKEN).reserveDistributor());
        console2.log("companyAccount            :", IGDCToken(TOKEN).companyAccount());
        console2.log("rewardAccount             :", IGDCToken(TOKEN).rewardAccount());
        console2.log("depositContract (Main)    :", IGDCToken(TOKEN).depositContract());
    }

    // ------------------------------------------------------------------
    // 2. Hard arithmetic ceiling: the whole pair is worth < the gas of the exploit
    // ------------------------------------------------------------------
    function test_02_wholePairWorthLessThanExploitGas() public {
        _forkLatest();

        uint256 ceilingWei = IERC20Like(WBNB).balanceOf(PAIR);
        uint256 gasCostWei = EXPLOIT_GAS_USED * BSC_GAS_PRICE;
        uint256 breakEvenGas = ceilingWei / BSC_GAS_PRICE;

        // The single strongest result: even a 100%-effective drain (zero acquisition cost,
        // zero flash fee) cannot pay for the gas of the very transaction that performs it.
        assertGt(gasCostWei, ceilingWei, "gas does not exceed the entire pool");
        // 657,120 gas: less than the 1,003,754 gas the real (copy-cat) tx consumed.
        assertLt(breakEvenGas, EXPLOIT_GAS_USED, "break-even gas unexpectedly high");

        console2.log("=== economic ceiling");
        console2.log("pool WBNB (wei)           :", ceilingWei);
        console2.log("pool WBNB USD e18         :", ceilingWei * BNB_USD_E18 / 1e18);
        console2.log("observed exploit gasUsed  :", EXPLOIT_GAS_USED);
        console2.log("gas price (wei)           :", BSC_GAS_PRICE);
        console2.log("gas cost (wei)            :", gasCostWei);
        console2.log("gas cost USD e18          :", gasCostWei * BNB_USD_E18 / 1e18);
        console2.log("break-even gas (all pool) :", breakEvenGas);
    }

    // ------------------------------------------------------------------
    // 3. Execute the real sell path with the 10% cap; measure gross + net
    // ------------------------------------------------------------------
    function test_03_sellMaxAmountNetNegative() public {
        _forkLatest();

        address attacker = address(0xBEEF);
        uint256 amount = IGDCToken(TOKEN).maxSellAmount();
        uint256 poolWbnbBefore = IERC20Like(WBNB).balanceOf(PAIR);

        // Simulate ANY acquisition route (the acquisition gate is irrelevant at this size):
        // write the balance directly. Slot 0 is ERC20._balances.
        vm.store(TOKEN, keccak256(abi.encode(attacker, uint256(0))), bytes32(amount));
        assertEq(IERC20Like(TOKEN).balanceOf(attacker), amount, "deal failed");

        vm.prank(attacker, attacker);
        IGDCToken(TOKEN).approve(ROUTER, type(uint256).max);

        uint256 bnbBefore = attacker.balance;
        vm.txGasPrice(BSC_GAS_PRICE);
        uint256 gasBefore = gasleft();

        vm.prank(attacker, attacker);
        IRouterLike(ROUTER).swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount, 0, _pairPath(TOKEN, WBNB), attacker, block.timestamp
        );

        uint256 gasUsed = gasBefore - gasleft();
        uint256 bnbOut = attacker.balance - bnbBefore;
        uint256 gasCost = gasUsed * BSC_GAS_PRICE;

        // The attacker can never take more than the pair held when the tx started.
        assertLe(bnbOut, poolWbnbBefore, "impossible: out > pool");
        // And the observed execution is a net loss.
        assertLt(bnbOut, gasCost, "unexpectedly profitable");

        console2.log("=== 10% cap sell (real path, latest block)");
        console2.log("amount in (wei)           :", amount);
        console2.log("BNB gross out (wei)       :", bnbOut);
        console2.log("gas used                  :", gasUsed);
        console2.log("gas cost (wei)            :", gasCost);
        console2.log("net (wei, negative)       :", int256(bnbOut) - int256(gasCost));
        console2.log("pool WBNB before (wei)    :", poolWbnbBefore);
        console2.log("pool WBNB after  (wei)    :", IERC20Like(WBNB).balanceOf(PAIR));
    }

    // ------------------------------------------------------------------
    // 4. Acquisition route: buying from the pair is blocked
    // ------------------------------------------------------------------
    function test_04_buyFromPairReverts() public {
        _forkLatest();

        address buyer = address(0xCAFE);
        vm.deal(buyer, 1 ether);

        // BuyingProhibited() -- selector 0xa2f4f5a1? we only assert a revert.
        vm.prank(buyer, buyer);
        vm.expectRevert();
        IRouterLike(ROUTER).swapExactETHForTokensSupportingFeeOnTransferTokens{value: 0.001 ether}(
            0, _pairPath(WBNB, TOKEN), buyer, block.timestamp
        );

        // The only whitelisted recipient is the protocol's own deposit contract.
        assertTrue(IGDCToken(TOKEN).transferWhitelist(MAIN), "Main not whitelisted");
        assertFalse(IGDCToken(TOKEN).transferWhitelist(buyer), "buyer unexpectedly whitelisted");
    }

    function test_05_buyToMainLandsInProtocolNotAttacker() public {
        _forkLatest();

        address buyer = address(0xCAFE);
        vm.deal(buyer, 1 ether);
        uint256 mainBefore = IERC20Like(TOKEN).balanceOf(MAIN);

        vm.prank(buyer, buyer);
        IRouterLike(ROUTER).swapExactETHForTokensSupportingFeeOnTransferTokens{value: 0.001 ether}(
            0, _pairPath(WBNB, TOKEN), MAIN, block.timestamp
        );

        assertGt(IERC20Like(TOKEN).balanceOf(MAIN), mainBefore, "no GDC reached Main");
        assertEq(IERC20Like(TOKEN).balanceOf(buyer), 0, "buyer got GDC");

        console2.log("GDC bought into Main (wei):", IERC20Like(TOKEN).balanceOf(MAIN) - mainBefore);
        console2.log("buyer GDC (wei)          :", IERC20Like(TOKEN).balanceOf(buyer));
    }

    // ------------------------------------------------------------------
    // 6. Historical: the 2026-11-09 exploit was real and drained 51.2256 WBNB;
    //    it left 0.0000806 WBNB -- not 44.08 WBNB.
    // ------------------------------------------------------------------
    function test_06_historicalPreExploitReserves() public {
        if (!_historicalEnabled()) {
            vm.skip(true);
            return;
        }
        vm.createSelectFork(_rpc(), FORK_PRE_EXPLOIT);
        (uint112 r0, uint112 r1,) = IPairLike(PAIR).getReserves();
        assertEq(uint256(r0), 642_611_624_985_035_009_025_331_617, "pre r0");
        assertEq(uint256(r1), 51_225_608_092_426_095_503, "pre r1");
        console2.log("pre-exploit GDC  (wei)    :", uint256(r0));
        console2.log("pre-exploit WBNB (wei)    :", uint256(r1));
        console2.log("pre-exploit WBNB USD e18  :", uint256(r1) * BNB_USD_E18 / 1e18);
    }

    function test_07_historicalPostExploitReserves() public {
        if (!_historicalEnabled()) {
            vm.skip(true);
            return;
        }
        vm.createSelectFork(_rpc(), FORK_POST_EXPLOIT);
        (uint112 r0, uint112 r1,) = IPairLike(PAIR).getReserves();
        assertEq(uint256(r0), 12_314_309_785_469_112_019_672, "post r0");
        assertEq(uint256(r1), 80_638_219_041_498, "post r1"); // 0.0000806382 WBNB
        assertLt(uint256(r1), 1e14, "post-exploit WBNB is not dust");
        console2.log("post-exploit GDC  (wei)   :", uint256(r0));
        console2.log("post-exploit WBNB (wei)   :", uint256(r1));
    }

    // ------------------------------------------------------------------
    // 7. Replay the 2026-11-10 copy-cat drain (path still executes, loses money)
    // ------------------------------------------------------------------
    function test_08_replayCopycatDrainLosesMoney() public {
        if (!_historicalEnabled()) {
            vm.skip(true);
            return;
        }
        vm.createSelectFork(_rpc(), FORK_BEFORE_COPYCAT);

        address atk = 0x77Aabf4517f962d772C64c33e2F75D246670aB0A;
        uint256 amount = 1_100e18;
        assertEq(IERC20Like(TOKEN).balanceOf(atk), 11_777.14e18, "attacker GDC balance mismatch");
        uint256 poolWbnbBefore = IERC20Like(WBNB).balanceOf(PAIR);
        assertEq(poolWbnbBefore, 44_080_303_063_849, "pre-copycat pool");

        vm.prank(atk, atk);
        IGDCToken(TOKEN).approve(ROUTER, type(uint256).max);

        uint256 bnbBefore = atk.balance;
        vm.txGasPrice(BSC_GAS_PRICE);
        uint256 gasBefore = gasleft();

        vm.prank(atk, atk);
        IRouterLike(ROUTER).swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount, 0, _pairPath(TOKEN, WBNB), atk, block.timestamp
        );

        uint256 gasUsed = gasBefore - gasleft();
        uint256 bnbOut = atk.balance - bnbBefore;

        // Reproduces the on-chain result: ~1.137e12 wei out for ~1M gas.
        assertLt(bnbOut, 2_000_000_000_000, "copycat out larger than on-chain");
        assertLt(bnbOut, gasUsed * BSC_GAS_PRICE, "copycat profitable?");

        console2.log("=== replay of 2026-11-10 copy-cat");
        console2.log("BNB out (wei)             :", bnbOut);
        console2.log("gas used                  :", gasUsed);
        console2.log("net (wei)                 :", int256(bnbOut) - int256(gasUsed * BSC_GAS_PRICE));
        console2.log("pool WBNB after (wei)     :", IERC20Like(WBNB).balanceOf(PAIR));
    }

    // ------------------------------------------------------------------
    // 8. Nominal vs realizable: the whole GDC float is a paper number
    // ------------------------------------------------------------------
    function test_09_nominalVsRealizable() public {
        _forkLatest();

        uint256 supply = IGDCToken(TOKEN).totalSupply();
        (uint112 r0, uint112 r1,) = IPairLike(PAIR).getReserves();
        // price = WBNB/GDC in 1e18 fixed point
        uint256 priceE18 = uint256(r1) * 1e18 / uint256(r0);
        uint256 nominalUsdE18 = supply * priceE18 / 1e18 * BNB_USD_E18 / 1e18;
        uint256 realizableUsdE18 = uint256(r1) * BNB_USD_E18 / 1e18;

        assertLt(realizableUsdE18, 1e17, "realizable >= $0.10");

        console2.log("totalSupply (wei)         :", supply);
        console2.log("price wei per GDC (e18)   :", priceE18);
        console2.log("nominal USD e18           :", nominalUsdE18);
        console2.log("realizable USD e18        :", realizableUsdE18);
        console2.log("distributor GDC (wei)     :", IERC20Like(TOKEN).balanceOf(DIST));
        console2.log("Main GDC (wei)            :", IERC20Like(TOKEN).balanceOf(MAIN));
        console2.log("Main pendingReserveDiv    :", IGDCMain(MAIN).pendingReserveDividend());
        console2.log("Main distributionRemaining:", IGDCMain(MAIN).distributionRemaining());
        console2.log("reserveDistributor        :", IGDCToken(TOKEN).reserveDistributor());
        console2.log("LP totalSupply (wei)      :", IPairLike(PAIR).totalSupply());
        console2.log("LP burned to DEAD (wei)   :", IPairLike(PAIR).balanceOf(address(0xdead)));
    }

    // ------------------------------------------------------------------
    // 10. Alternate-path checks: no second pair, no direct distributor abuse,
    //     no skim value, no same-block cap bypass
    // ------------------------------------------------------------------
    function test_10_onlyOnePairAndNoSkimValue() public {
        _forkLatest();

        address factory = IRouterLike(ROUTER).factory();
        assertEq(IFactoryLike(factory).getPair(TOKEN, WBNB), PAIR, "canonical pair mismatch");
        assertEq(IGDCToken(TOKEN).pair(), PAIR, "token.pair mismatch");

        // skim() would send balance-reserve; both are equal (0 excess). Anyway, the token's
        // _transfer rejects ANY pair->non-whitelisted transfer (BuyingProhibited), so even a
        // zero-value skim reverts. Neither skim nor sync can create value.
        (, uint112 r1Before,) = IPairLike(PAIR).getReserves();
        address thief = address(0xDEADBEEF);
        uint256 before = IERC20Like(WBNB).balanceOf(thief);
        vm.expectRevert();
        IPairLike(PAIR).skim(thief);
        assertEq(IERC20Like(WBNB).balanceOf(thief), before, "skim produced WBNB");
        (, uint112 r1After,) = IPairLike(PAIR).getReserves();
        assertEq(uint256(r1After), uint256(r1Before), "skim changed reserves");
        console2.log("skim WBNB out (wei)       :", IERC20Like(WBNB).balanceOf(thief) - before);
    }

    function test_11_directDistributeIsControllerOnly() public {
        _forkLatest();
        vm.prank(address(0xBEEF), address(0xBEEF));
        vm.expectRevert();
        IGDCReserveDistributor(DIST).distribute(1e18);
    }

    function test_12_sameBlockSecondSellReverts() public {
        _forkLatest();

        address attacker = address(0xBEEF);
        uint256 amount = IGDCToken(TOKEN).maxSellAmount();
        // 2x the cap, so the second sell fails on the block guard, not on balance.
        vm.store(TOKEN, keccak256(abi.encode(attacker, uint256(0))), bytes32(amount * 2));
        vm.prank(attacker, attacker);
        IGDCToken(TOKEN).approve(ROUTER, type(uint256).max);

        vm.prank(attacker, attacker);
        IRouterLike(ROUTER).swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount, 0, _pairPath(TOKEN, WBNB), attacker, block.timestamp
        );

        // Same block, same tx.origin -> SameBlockTrade()
        vm.prank(attacker, attacker);
        vm.expectRevert();
        IRouterLike(ROUTER).swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount, 0, _pairPath(TOKEN, WBNB), attacker, block.timestamp
        );
    }

    function test_13_repeatSellNextBlockDiminishing() public {
        _forkLatest();

        address attacker = address(0xBEEF);
        uint256 amount = IGDCToken(TOKEN).maxSellAmount();
        vm.store(TOKEN, keccak256(abi.encode(attacker, uint256(0))), bytes32(amount * 2));
        vm.prank(attacker, attacker);
        IGDCToken(TOKEN).approve(ROUTER, type(uint256).max);

        uint256 b0 = attacker.balance;
        vm.prank(attacker, attacker);
        IRouterLike(ROUTER).swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount, 0, _pairPath(TOKEN, WBNB), attacker, block.timestamp
        );
        uint256 out1 = attacker.balance - b0;

        vm.warp(block.timestamp + 31); // clear the 30s TRADE_COOLDOWN
        vm.roll(block.number + 1);     // and the same-block trade guard
        uint256 b1 = attacker.balance;
        vm.prank(attacker, attacker);
        IRouterLike(ROUTER).swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount, 0, _pairPath(TOKEN, WBNB), attacker, block.timestamp
        );
        uint256 out2 = attacker.balance - b1;

        assertLt(out2, out1, "second sell not smaller");
        console2.log("sell #1 out (wei)         :", out1);
        console2.log("sell #2 out (wei)         :", out2);
        console2.log("pool WBNB after 2 (wei)   :", IERC20Like(WBNB).balanceOf(PAIR));
    }
}
