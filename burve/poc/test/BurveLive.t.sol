// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import {IERC20Like, IERC4626Like, IBurveDiamond} from "../src/IBurve.sol";

/// Burve (Berachain, chain 80094) — ZH4-PASS4 / P4-02.
///
/// The live $32k target is the *multi* "Omni-Pool" SimplexDiamond. Sherlock 2025-04-burve
/// H-5 ("fee capture by timing a deposit with range re-entry + price manipulation") targets a
/// DIFFERENT product: `src/single/Burve.sol`, a Kodiak UniV3 LP wrapper with immutable ranges and
/// `collectAndCalcCompound()`. These tests (a) pin the live target's identity/state and (b) test the
/// H-5 fee-sniping *class* against the live multi to show it is closed there.
contract BurveLiveTest is Test {
    address constant DIAMOND = 0xa1beD164c12CD9479A1049f97BDe5b3D6EC21089;
    address constant USDC = 0x549943e04f40284185054145c6E4e9568C1D3241; // 6 dec
    address constant USDT = 0x779Ded0c9e1022225f8E0630b35a9b54bE713736; // USD₮0, 6 dec
    address constant MEAD = 0xEDB5180661F56077292C92Ab40B1AC57A279a396; // 18 dec
    address constant MEAD_VAULT = 0x82576213872683791B9f779cf788a6D478651C78; // NoopVault (H-7 surface)

    uint16 constant CID = 3; // {token0=USDC.e, token1=USD₮0}

    IBurveDiamond dia;
    address attacker;
    address whale;

    function setUp() public {
        string memory rpc = vm.envOr("BERA_RPC_URL", string("https://berachain-rpc.publicnode.com"));
        vm.createSelectFork(rpc);
        dia = IBurveDiamond(DIAMOND);
        attacker = vm.addr(0xA11CE1234567890);
        whale = vm.addr(0xB0B1234567890);
    }

    /* ------------------------------------------------------------------ */
    /* 1. Live-state pin: identity of the $32k target                      */
    /* ------------------------------------------------------------------ */

    function test_liveState() public {
        assertGt(DIAMOND.code.length, 0, "diamond has code");
        address[] memory toks = dia.getTokens();
        emit log_named_uint("numTokens", toks.length);
        emit log_named_uint("numVertices", dia.getNumVertices());
        (uint128 edgeFee, uint128 protocolTake) = dia.getSimplexFees();
        emit log_named_uint("defaultEdgeFeeX128", edgeFee);
        emit log_named_uint("protocolTakeX128", protocolTake);
        emit log_named_address("owner", dia.owner());
        assertEq(dia.getNumVertices(), uint8(toks.length), "vertices == tokens");
        assertEq(toks.length, 9, "9 tokens");

        for (uint8 i = 0; i < toks.length; ++i) {
            (address active, ) = dia.viewVaults(toks[i]);
            emit log_named_address("vault", active);
            (bool ok, bytes memory ret) = toks[i].staticcall(abi.encodeWithSelector(IERC20Like.decimals.selector));
            assertTrue(ok, "decimals()");
            emit log_named_uint("  token decimals", abi.decode(ret, (uint8)));
        }
    }

    /// The live target is NOT the single-Burve product that H-5 concerns:
    /// it has no `queryTVL()` (0x3a2aabcc) nor `getInfo()` (0x5a9b0b89).
    function test_liveTargetIsNotSingleBurve() public {
        (bool ok1, ) = DIAMOND.staticcall(hex"3a2aabcc");
        (bool ok2, ) = DIAMOND.staticcall(hex"5a9b0b89");
        assertFalse(ok1, "diamond must NOT answer queryTVL() (single-Burve selector)");
        assertFalse(ok2, "diamond must NOT answer getInfo() (single-Burve selector)");
    }

    /* ------------------------------------------------------------------ */
    /* 2. H-5 class on the LIVE multi: no capture of PRE-EXISTING fees      */
    /* ------------------------------------------------------------------ */

    /// Generate fees, THEN deposit: a fresh depositor must not receive any of the already-earned
    /// fees (earnings == 0), and a deposit->immediate-withdraw round trip must be a net loss.
    function test_h5_feeSniping_afterFees_isZeroCapture() public {
        deal(USDC, whale, 5_000_000e6);
        vm.prank(whale);
        IERC20Like(USDC).approve(DIAMOND, type(uint256).max);

        // Generate real fees in cid 3.
        vm.prank(whale);
        dia.swap(whale, USDC, USDT, int256(500e6), 0, CID);

        (uint256[16] memory epv0, , ) = dia.getClosureFees(CID);
        emit log_named_uint("cid3 epv[USDC] after fee-generating swap", epv0[0]);
        assertGt(epv0[0], 0, "fees were generated");

        // Attacker deposits single-sided right after the fees exist.
        uint128 value = 1e20; // nominal; ~100 USDC.e
        deal(USDC, attacker, 100_000e6);
        vm.startPrank(attacker);
        IERC20Like(USDC).approve(DIAMOND, type(uint256).max);
        uint256 balBefore = IERC20Like(USDC).balanceOf(attacker);
        dia.addValueSingle(attacker, CID, value, 0, USDC, 0);

        // Must NOT have captured any pre-existing fees.
        (, , uint256[16] memory earn, ) = dia.queryValue(attacker, CID);
        emit log_named_uint("attacker earnings[USDC] right after deposit", earn[0]);
        emit log_named_uint("attacker earnings[USDt0] right after deposit", earn[1]);
        assertEq(earn[0], 0, "no captured USDC.e fees");
        assertEq(earn[1], 0, "no captured USDt0 fees");

        // Immediate exit is a net loss (entry + exit tax + rounding).
        dia.removeValueSingle(attacker, CID, value, 0, USDC, 0);
        vm.stopPrank();
        uint256 balAfter = IERC20Like(USDC).balanceOf(attacker);
        emit log_named_uint("attacker USDC.e before", balBefore);
        emit log_named_uint("attacker USDC.e after", balAfter);
        assertLe(balAfter, balBefore, "round trip is not profitable");
    }

    /* ------------------------------------------------------------------ */
    /* 3. H-5 class on the LIVE multi: self-funded fee injection can't win */
    /* ------------------------------------------------------------------ */

    /// The H-5 recipe maps to "inject a fee windfall and take a disproportionate share". On the
    /// live multi an attacker can inject fees only by paying them; net token value must not increase.
    function test_h5_selfFundedFeeInjection_notProfitable() public {
        deal(USDC, attacker, 1_000_000e6);
        vm.startPrank(attacker);
        IERC20Like(USDC).approve(DIAMOND, type(uint256).max);
        IERC20Like(USDT).approve(DIAMOND, type(uint256).max);

        uint256 startUsdc = IERC20Like(USDC).balanceOf(attacker);
        uint256 startUsdt = IERC20Like(USDT).balanceOf(attacker);

        // 1. deposit a large single-sided position
        dia.addValueSingle(attacker, CID, 1e21, 0, USDC, 0);
        // 2. attacker performs the "windfall" swap (pays the pool fee)
        dia.swap(attacker, USDC, USDT, int256(500e6), 0, CID);
        // 3. withdraw single-sided
        dia.removeValueSingle(attacker, CID, 1e21, 0, USDC, 0);
        vm.stopPrank();

        uint256 endUsdc = IERC20Like(USDC).balanceOf(attacker);
        uint256 endUsdt = IERC20Like(USDT).balanceOf(attacker);
        emit log_named_uint("start USDC.e+USDt0", startUsdc + startUsdt);
        emit log_named_uint("end   USDC.e+USDt0", endUsdc + endUsdt);
        // both legs are ~$1; sum is a fair value proxy
        assertLe(endUsdc + endUsdt, startUsdc + startUsdt, "fee injection is not profitable");
    }

    /* ------------------------------------------------------------------ */
    /* 4. H-7 surface: NoopVault donation does not enrich the donor        */
    /* ------------------------------------------------------------------ */

    function test_noopVaultDonation_attackerLoses() public {
        IERC4626Like v = IERC4626Like(MEAD_VAULT);
        uint256 diaShares = v.balanceOf(DIAMOND);
        uint256 diaRedeemableBefore = v.convertToAssets(diaShares);
        emit log_named_uint("Diamond MEAD-vault shares", diaShares);
        emit log_named_uint("Diamond redeemable before", diaRedeemableBefore);

        deal(MEAD, attacker, 1_000e18);
        uint256 attackerBefore = IERC20Like(MEAD).balanceOf(attacker);
        vm.prank(attacker);
        IERC20Like(MEAD).transfer(MEAD_VAULT, 100e18); // donate, get no shares

        uint256 attackerAfter = IERC20Like(MEAD).balanceOf(attacker);
        uint256 diaRedeemableAfter = v.convertToAssets(v.balanceOf(DIAMOND));
        emit log_named_uint("Diamond redeemable after", diaRedeemableAfter);

        assertEq(v.balanceOf(attacker), 0, "donor got no shares");
        assertLt(attackerAfter, attackerBefore, "donor lost the donation");
        assertGe(diaRedeemableAfter, diaRedeemableBefore, "donation accrues to existing holders");
    }
}
