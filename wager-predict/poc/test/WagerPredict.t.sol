// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
}

/// @title Wager Predict (BSC) — read-only fork PoC.
/// Verifies: (a) USDW mint is role-gated / deposit is par-backed; (b) SpotEngine LMSR buy->sell
/// round trips are loss-making (no fixed-point overshoot); (c) all settlement/graduation/redemption
/// entry points revert for an unprivileged stranger; (d) the Vault's un-claimed LP fee buffer can be
/// captured by the first LP to deposit (small, permissionless). Fork-only; no mainnet txs.
contract WagerPredictTest is Test {
    address constant SPOT   = 0x76b91e83f2A12dc52E33f856eeA300E5B3A62c0c;
    address constant VAULT  = 0x88d163d40D6BFe0Ad2b17f4a90A03053fEbf3014;
    address constant USDW   = 0xe5eBE2AE0a036C955bfF58291826C50F7d670D43;
    address constant USDC   = 0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d; // Binance-Peg USDC, 18dp
    address constant REG    = 0x2D7E1000da132C46f20C7ba4f39F1BEF74F7adb4;
    address constant FEE    = 0x186DCA432CE9f9B5618fcBb7231a6bE3FcEAe454; // FeeRouter (FEE_SOURCE_ROLE)
    address constant RES    = 0xdfc40D309C0D8f4Cc42863991C8e606eD330e1E8; // ResolutionModule (RESOLUTION_ROLE)
    address constant GRADMGR= 0xB6F097da776338D5367251B6BC333Ef6F4029dD3; // LmsrAsMaker (GRADUATION_ROLE)
    address constant DEPREC = 0x255E92b8e79800349f137d5b8EA70c0B658fd397; // backing EOA (depositRecipient)
    address constant ABNBUSDC = 0x00901a076785e0906d1028c7d6372d247bec7d61;

    address attacker = address(0xA11CE);

    function setUp() public {
        string memory url = vm.envOr("BSC_RPC_URL", string("https://bsc-rpc.publicnode.com"));
        vm.createSelectFork(url);
        vm.label(SPOT,"SpotEngine"); vm.label(VAULT,"Vault"); vm.label(USDW,"USDW");
        vm.label(attacker,"attacker");
    }

    // ---- helpers -------------------------------------------------------------
    function _depositUsdw(uint256 usdcAmt) internal returns (uint256 usdwOut) {
        uint256 before = IERC20(USDW).balanceOf(attacker);
        deal(USDC, attacker, usdcAmt);
        vm.startPrank(attacker);
        IERC20(USDC).approve(USDW, type(uint256).max);
        (bool ok,) = USDW.call(abi.encodeWithSignature("deposit(address,uint256)", USDC, usdcAmt));
        require(ok, "deposit failed");
        vm.stopPrank();
        usdwOut = IERC20(USDW).balanceOf(attacker) - before;
    }

    function _buy(uint256 id, uint8 side, uint256 usdcIn) internal returns (uint256 shares) {
        vm.prank(attacker);
        (bool ok, bytes memory r) = SPOT.call(abi.encodeWithSignature("buyShares(uint256,uint8,uint256,uint256)", id, side, usdcIn, uint256(0)));
        require(ok, "buy failed");
        shares = abi.decode(r,(uint256));
    }

    function _sell(uint256 id, uint8 side, uint256 sharesIn) internal returns (uint256 netOut) {
        vm.prank(attacker);
        (bool ok, bytes memory r) = SPOT.call(abi.encodeWithSignature("sellShares(uint256,uint8,uint256,uint256)", id, side, sharesIn, uint256(0)));
        require(ok, "sell failed");
        netOut = abi.decode(r,(uint256));
    }

    // ---- 1. live state snapshot ---------------------------------------------
    function test_snapshot() public view {
        console2.log("block.timestamp", block.timestamp);
        console2.log("SpotEngine USDW", IERC20(USDW).balanceOf(SPOT));
        console2.log("Vault USDW", IERC20(VAULT).balanceOf(VAULT));
        console2.log("USDW totalSupply", IERC20(USDW).totalSupply());
        console2.log("backing aBnbUSDC", IERC20(ABNBUSDC).balanceOf(DEPREC));
        console2.log("Vault feeBuffer", _u(VAULT,"feeBuffer()(uint256)"));
    }

    function _u(address to, string memory sig) internal view returns (uint256 v) {
        (bool ok, bytes memory r) = to.staticcall(abi.encodeWithSignature(sig));
        if (ok && r.length==32) v = abi.decode(r,(uint256));
    }

    // ---- 2. USDW: deposit is par-backed, mint/process are role-gated ---------
    function test_usdw_deposit_par_and_mint_gated() public {
        // deposit 100 USDC (18dp) -> ~100 USDW (6dp) at par (oracle within +-50bps of $1)
        uint256 out = _depositUsdw(100e18);
        console2.log("USDW minted for 100 USDC", out);
        assertApproxEqAbs(out, 100e6, 1e6, "deposit not ~par");
        assertLe(out, 100e6, "deposit minted MORE than par (oracle leak)");

        // unprivileged mint reverts (ISSUER_ROLE unassigned)
        vm.prank(attacker);
        (bool ok1,) = USDW.call(abi.encodeWithSignature("mint(address,uint256)", attacker, 1e18));
        assertFalse(ok1, "stranger mint must revert");

        // unprivileged burn / lockTokens revert
        vm.prank(attacker);
        (bool ok2,) = USDW.call(abi.encodeWithSignature("burn(address,uint256)", attacker, 1));
        assertFalse(ok2, "stranger burn must revert");
        vm.prank(attacker);
        (bool ok3,) = USDW.call(abi.encodeWithSignature("lockTokens(address,uint256)", attacker, 1));
        assertFalse(ok3, "stranger lockTokens must revert");

        // redemption process is OPERATOR_ROLE gated
        vm.prank(attacker);
        (bool ok4,) = USDW.call(abi.encodeWithSignature("process(uint256,uint256)", 1, 0));
        assertFalse(ok4, "stranger process must revert");
    }

    // ---- 3. SpotEngine buy->sell is loss-making (no rounding overshoot) ------
    function test_spot_roundTrip_loss() public {
        uint256 u0 = _depositUsdw(1000e18);      // ~1000 USDW
        vm.prank(attacker);
        IERC20(USDW).approve(SPOT, type(uint256).max);

        uint256 balBefore = IERC20(USDW).balanceOf(attacker);
        uint256 shares = _buy(1, 0, 100e6);       // buy 100 USDW of YES on market 1
        console2.log("shares bought", shares);
        uint256 netOut = _sell(1, 0, shares);     // sell them straight back
        console2.log("usdcIn 100e6  netOut", netOut);
        uint256 balAfter = IERC20(USDW).balanceOf(attacker);

        console2.log("round-trip PnL (USDW 6dp)", int256(balAfter) - int256(balBefore));
        assertLt(balAfter, balBefore, "round trip must lose (fees ~2% each way)");
        assertLe(netOut, 100e6, "sell returned more than buy cost");
    }

    function testFuzz_spot_roundTrip_noProfit(uint256 usdcIn, uint8 side) public {
        usdcIn = bound(usdcIn, 1e6, 5000e6);
        side = side % 2;
        _depositUsdw(20000e18);
        vm.prank(attacker);
        IERC20(USDW).approve(SPOT, type(uint256).max);

        uint256 before = IERC20(USDW).balanceOf(attacker);
        uint256 shares = _buy(1, side, usdcIn);
        uint256 netOut = _sell(1, side, shares);
        uint256 afterBal = IERC20(USDW).balanceOf(attacker);
        assertLe(afterBal, before, "LMSR round trip produced a profit");
        assertLe(netOut, usdcIn, "sell returned more than buy cost");
    }

    // ---- 4. every settlement/graduation/redemption entry reverts for stranger
    function test_stranger_settlement_gated() public {
        // resolveMarket (RESOLUTION_ROLE)
        vm.prank(attacker);
        (bool a,) = SPOT.call(abi.encodeWithSignature("resolveMarket(uint256,uint8)", 1, 0));
        assertFalse(a, "stranger resolveMarket must revert");
        // resolveVoidMarket (RESOLUTION_ROLE)
        vm.prank(attacker);
        (bool b,) = SPOT.call(abi.encodeWithSignature("resolveVoidMarket(uint256)", 1));
        assertFalse(b, "stranger resolveVoidMarket must revert");
        // exitForGraduation (GRADUATION_ROLE)
        vm.prank(attacker);
        (bool c,) = SPOT.call(abi.encodeWithSignature("exitForGraduation(uint256)", 1));
        assertFalse(c, "stranger exitForGraduation must revert");
        // consumeMigratedShares (GRADUATION_ROLE)
        vm.prank(attacker);
        (bool d,) = SPOT.call(abi.encodeWithSignature("consumeMigratedShares(uint256,address)", 1, attacker));
        assertFalse(d, "stranger consumeMigratedShares must revert");
        // initializeMarket / haltMarket (registry only)
        vm.prank(attacker);
        (bool e,) = SPOT.call(abi.encodeWithSignature("initializeMarket(uint256,uint256,uint64,uint256)", 999, 1e21, uint64(block.timestamp+1 days), 0));
        assertFalse(e, "stranger initializeMarket must revert");
        vm.prank(attacker);
        (bool f,) = SPOT.call(abi.encodeWithSignature("haltMarket(uint256)", 1));
        assertFalse(f, "stranger haltMarket must revert");
        // setInsuranceFund (governance)
        vm.prank(attacker);
        (bool g,) = SPOT.call(abi.encodeWithSignature("setInsuranceFund(address)", attacker));
        assertFalse(g, "stranger setInsuranceFund must revert");
        // resolution module propose (permissionlessResolution=false -> RESOLVER/GOV only)
        vm.prank(attacker);
        (bool h,) = RES.call(abi.encodeWithSignature("propose(uint256,uint8)", 1, 1));
        assertFalse(h, "stranger propose must revert (permissionlessResolution=false)");
        // migrate / claimMigratedShares on the graduation manager
        vm.prank(attacker);
        (bool i,) = GRADMGR.call(abi.encodeWithSignature("migrate(uint256)", 1));
        assertFalse(i, "stranger migrate must revert (not graduated)");
        vm.prank(attacker);
        (bool j,) = GRADMGR.call(abi.encodeWithSignature("claimMigratedShares(uint256)", 1));
        assertFalse(j, "stranger claimMigratedShares must revert (not migrated)");
    }

    function test_stranger_claimUnsettled_reverts() public {
        vm.prank(attacker);
        (bool ok,) = SPOT.call(abi.encodeWithSignature("claimWinnings(uint256)", 1));
        assertFalse(ok, "claimWinnings on unsettled market must revert");
    }

    // ---- 5. cannot drain a settled position of another user -------------------
    function test_cannot_claim_other_position() public {
        // attacker buys; a *second* stranger tries to claim attacker's winnings -> impossible:
        // claimWinnings is caller-scoped. We assert the engine has no transfer-out path for others
        // by checking a stranger's sell of zero-held shares reverts.
        _depositUsdw(1000e18);
        vm.prank(attacker);
        IERC20(USDW).approve(SPOT, type(uint256).max);
        _buy(1, 0, 50e6);

        address other = address(0xB0B);
        vm.prank(other);
        (bool ok,) = SPOT.call(abi.encodeWithSignature("sellShares(uint256,uint8,uint256,uint256)", 1, 0, 1e18, 0));
        assertFalse(ok, "stranger selling shares they do not hold must revert");
    }

    // ---- 6. Vault LP fee-buffer capture by first LP (small, permissionless) ---
    function test_vault_feeBuffer_capture() public {
        uint256 buffered = _u(VAULT, "feeBuffer()(uint256)");
        console2.log("Vault feeBuffer before", buffered);
        if (buffered == 0) { console2.log("no buffer to capture; skipping"); return; }

        _depositUsdw(100e18);
        vm.prank(attacker);
        IERC20(USDW).approve(VAULT, type(uint256).max);
        vm.prank(attacker);
        (bool okd, bytes memory rd) = VAULT.call(abi.encodeWithSignature("deposit(uint256,uint8)", 10e6, uint8(0)));
        require(okd, "vault deposit failed");
        uint256 id = abi.decode(rd,(uint256));

        // simulate a real trade routing the LP slice: FeeRouter (FEE_SOURCE_ROLE) calls notifyFee
        uint256 lpAmt = 1e6;
        deal(USDW, FEE, lpAmt);
        vm.prank(FEE);
        IERC20(USDW).approve(VAULT, type(uint256).max);
        vm.prank(FEE);
        (bool okn,) = VAULT.call(abi.encodeWithSignature("notifyFee(uint256)", lpAmt));
        require(okn, "notifyFee failed");

        uint256 beforeFees = IERC20(USDW).balanceOf(attacker);
        vm.prank(attacker);
        (bool okc, bytes memory rc) = VAULT.call(abi.encodeWithSignature("claimFees(uint256)", id));
        require(okc, "claimFees failed");
        uint256 fees = abi.decode(rc,(uint256));
        uint256 afterFees = IERC20(USDW).balanceOf(attacker);
        console2.log("fees claimed", fees);
        console2.log("buffered captured", buffered);
        assertEq(afterFees - beforeFees, fees, "claim mismatch");
        assertGe(fees, buffered, "did not capture the whole prior buffer");
    }

    // ---- 7. backing EOA is unreachable (no allowance to any protocol contract)
    function test_backing_not_drainable() public view {
        assertEq(IERC20(ABNBUSDC).allowance(DEPREC, SPOT), 0);
        assertEq(IERC20(ABNBUSDC).allowance(DEPREC, VAULT), 0);
        assertEq(IERC20(ABNBUSDC).allowance(DEPREC, USDW), 0);
        assertEq(IERC20(ABNBUSDC).allowance(DEPREC, RES), 0);
        // the USDW contract holds no USDW itself (nothing to rescue)
        assertEq(IERC20(USDW).balanceOf(USDW), 0);
    }
}
