// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import {IERC20, IGambitVault, IPancakePair, IGmxMigrator} from "../src/IGambit.sol";

/// @title Gambit Vault (BSC) — USDG redemption accounting, fork verification
/// @notice Read-only research. All state changes happen on a local fork; nothing is broadcast.
contract GambitTest is Test {
    address constant VAULT = 0xc73A8DcAc88498FD4b4B1b2AaA37b0a2614Ff67B;
    address constant USDG  = 0x85E76cbf4893c1fbcB34dCF1239A91CE2A4CF5a7;
    address constant USDT  = 0x55d398326f99059fF775485246999027B3197955;
    address constant USDC  = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    address constant BUSD  = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address constant WBNB  = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address constant BTCB  = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
    address constant ETH   = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;

    address constant PAIR_WBNB = 0x66B59a36008Ba346DeAc6969A2e752EE0f865710;
    address constant PAIR_BUSD = 0x7Fea0c6022D81EE17146324E4F55f6A02E138Dab;
    address constant PAIR_GMT  = 0xa41e57459f09a126F358E118b693789d088eA8A0;
    address constant PAIR_AUTO = 0x0523FD5C53ea5419B4DAF656BC1b157dDFE3ce50;

    address constant MIGRATOR1 = 0xDEF2af818514c1Ca1A9bBe2a4D45E28f260063f9;
    address constant MIGRATOR2 = 0x0472F402EA8E301D7595545884Ad4C420E9865d6;
    address constant HOLDER    = 0xBa24118472D0a65d7364e5CA8e87f61BB9e70026;

    uint256 constant PIN = 131443197;

    IGambitVault vault;
    IERC20 usdg;
    IERC20 usdt;

    function setUp() public {
        string memory rpc = vm.envOr("BSC_RPC_URL", string(""));
        if (bytes(rpc).length == 0) rpc = "https://bsc-rpc.publicnode.com";
        vm.createSelectFork(rpc, PIN);
        vault = IGambitVault(VAULT);
        usdg = IERC20(USDG);
        usdt = IERC20(USDT);
    }

    function _usd(address token, uint256 amount) internal view returns (uint256) {
        uint256 p = vault.getMaxPrice(token); // 1e30 == $1
        uint8 dec = IERC20(token).decimals();
        // returns USD with 18 decimals
        return amount * p / (10 ** dec) / 1e12;
    }

    function test_live_state_and_face_capacity() public {
        assertEq(usdg.totalSupply(), 291306948166519382786286, "USDG supply");
        assertEq(usdt.balanceOf(VAULT), 75188018739410340393152, "vault USDT");
        assertEq(IERC20(WBNB).balanceOf(VAULT), 34781854744088709854, "vault WBNB");

        // The defect: 1000 USDG redeems for 1000 USDT at face, regardless of backing.
        assertEq(vault.getRedemptionAmount(USDT, 1000e18), 1000e18, "face redemption");
        assertEq(vault.getRedemptionAmount(USDC, 1000e18), 1000e18, "face redemption USDC");
        assertEq(vault.getRedemptionAmount(BUSD, 1000e18), 1000e18, "face redemption BUSD");

        uint256 face = vault.poolAmounts(USDT) + vault.poolAmounts(USDC) + vault.poolAmounts(BUSD);

        uint256 poolUsd =
            _usd(USDT, vault.poolAmounts(USDT)) +
            _usd(USDC, vault.poolAmounts(USDC)) +
            _usd(BUSD, vault.poolAmounts(BUSD)) +
            _usd(WBNB, vault.poolAmounts(WBNB)) +
            _usd(BTCB, vault.poolAmounts(BTCB)) +
            _usd(ETH,  vault.poolAmounts(ETH));

        emit log_named_decimal_uint("at-face capacity (USDG units)", face, 18);
        emit log_named_decimal_uint("LP pool value USD", poolUsd, 18);
        emit log_named_decimal_uint("LP backing per USDG", poolUsd * 1e18 / usdg.totalSupply(), 18);

        assertApproxEqRel(face, 75372.778789717413879406e18, 1e12, "capacity");
        assertLt(poolUsd * 1e18 / usdg.totalSupply(), 0.75e18, "backing < 0.75");
    }

    function test_mint_redeem_round_trip_is_negative() public {
        address attacker = address(0xA11CE);
        deal(USDT, attacker, 10_000e18);

        vm.startPrank(attacker);
        usdt.transfer(VAULT, 10_000e18);
        uint256 minted = vault.buyUSDG(USDT, attacker);
        usdg.transfer(VAULT, minted);
        uint256 out = vault.sellUSDG(USDT, attacker);
        vm.stopPrank();

        emit log_named_decimal_uint("USDT in", 10_000e18, 18);
        emit log_named_decimal_uint("USDG minted", minted, 18);
        emit log_named_decimal_uint("USDT out", out, 18);
        emit log_named_decimal_uint("round-trip loss", 10_000e18 - out, 18);

        assertLt(out, 10_000e18, "mint->redeem must lose money");
        assertApproxEqRel(10_000e18 - out, 2e18, 0.02e18, "~2 USDT loss per 10k");
    }

    function test_face_capacity_and_pool_exhaustion() public {
        address attacker = address(0xB0B);
        uint256 face = vault.poolAmounts(USDT) + vault.poolAmounts(USDC) + vault.poolAmounts(BUSD);
        deal(USDG, attacker, face + 10e18);

        vm.startPrank(attacker);
        // Redeem the entire stable capacity, token by token.
        uint256 outUsdt;
        {
            uint256 amt = vault.poolAmounts(USDT);
            usdg.transfer(VAULT, amt);
            outUsdt = vault.sellUSDG(USDT, attacker);
        }
        uint256 outUsdc;
        {
            uint256 amt = vault.poolAmounts(USDC);
            usdg.transfer(VAULT, amt);
            outUsdc = vault.sellUSDG(USDC, attacker);
        }
        uint256 outBusd;
        {
            uint256 amt = vault.poolAmounts(BUSD);
            usdg.transfer(VAULT, amt);
            outBusd = vault.sellUSDG(BUSD, attacker);
        }
        vm.stopPrank();

        emit log_named_decimal_uint("USDT out at capacity", outUsdt, 18);
        emit log_named_decimal_uint("USDC out at capacity", outUsdc, 18);
        emit log_named_decimal_uint("BUSD out at capacity", outBusd, 18);
        emit log_named_decimal_uint("total face out", outUsdt + outUsdc + outBusd, 18);

        assertGt(outUsdt, 74_968e18, "USDT capacity");
        assertEq(vault.poolAmounts(USDT), 0, "USDT pool drained");
        assertEq(vault.poolAmounts(USDC), 0, "USDC pool drained");

        // One more USDG cannot be redeemed into USDT.
        vm.startPrank(attacker);
        usdg.transfer(VAULT, 1e18);
        vm.expectRevert("Vault: poolAmount exceeded");
        vault.sellUSDG(USDT, attacker);
        vm.stopPrank();
    }

    function test_97pct_of_supply_is_locked_in_migrators() public {
        uint256 b1 = usdg.balanceOf(MIGRATOR1);
        uint256 b2 = usdg.balanceOf(MIGRATOR2);
        emit log_named_decimal_uint("migrator1 USDG", b1, 18);
        emit log_named_decimal_uint("migrator2 USDG", b2, 18);
        emit log_named_decimal_uint("locked share (bps)", (b1 + b2) * 10_000 / usdg.totalSupply(), 0);

        assertEq(b1, 200827298608986964667666);
        assertEq(b2, 83966248058249170453541);
        assertGt((b1 + b2) * 10_000 / usdg.totalSupply(), 9700, ">97% locked");

        // USDG is not a migratable token, and the migrator has no withdraw().
        assertFalse(IGmxMigrator(MIGRATOR1).whitelistedTokens(USDG));
        assertFalse(IGmxMigrator(MIGRATOR2).whitelistedTokens(USDG));
        assertTrue(IGmxMigrator(MIGRATOR2).isMigrationActive());
        assertEq(IGmxMigrator(MIGRATOR2).minAuthorizations(), 2);

        vm.prank(address(0xA11CE));
        vm.expectRevert("GmxMigrator: token not whitelisted");
        IGmxMigrator(MIGRATOR2).migrate(USDG, 1e18);

        (bool ok,) = MIGRATOR2.call(abi.encodeWithSignature("withdraw()"));
        assertFalse(ok, "no public withdraw");
    }

    function test_holder_self_redemption_is_the_only_user_path() public {
        uint256 bal = usdg.balanceOf(HOLDER);
        assertGt(bal, 1_397e18);
        vm.startPrank(HOLDER);
        usdg.transfer(VAULT, bal);
        uint256 out = vault.sellUSDG(USDT, HOLDER);
        vm.stopPrank();
        emit log_named_decimal_uint("holder USDG", bal, 18);
        emit log_named_decimal_uint("holder USDT out", out, 18);
        assertGt(out, 1_390e18);
    }

    function test_dex_pairs_are_dust_and_cannot_absorb_size() public {
        // Pair 1: USDG/WBNB
        (uint112 r0, uint112 r1,) = IPancakePair(PAIR_WBNB).getReserves();
        assertEq(IPancakePair(PAIR_WBNB).token0(), USDG);
        uint256 x = r0; // USDG
        uint256 y = r1; // WBNB
        uint256 k = x * y;

        // Buy 10% of the USDG reserve; average price must be >= $0.99 (no real venue).
        uint256 buy = x / 10;
        uint256 dx = k / (x - buy) - y; // WBNB in
        uint256 costUsd = _usd(WBNB, dx);
        uint256 avg = costUsd * 1e18 / buy;

        emit log_named_decimal_uint("pair USDG reserve", x, 18);
        emit log_named_decimal_uint("pair WBNB reserve", y, 18);
        emit log_named_decimal_uint("cost of 10% of USDG reserve USD", costUsd, 18);
        emit log_named_decimal_uint("average price USD/USDG", avg, 18);

        assertLt(x, 30e18, "WBNB pair is dust");
        assertGt(avg, 0.98e18, "buying 10% already costs ~face");

        // Total USDG sitting in the four known pairs.
        uint256 pairTotal;
        address[4] memory pairs = [PAIR_WBNB, PAIR_BUSD, PAIR_GMT, PAIR_AUTO];
        for (uint256 i; i < 4; i++) {
            (uint112 a, uint112 b,) = IPancakePair(pairs[i]).getReserves();
            pairTotal += IPancakePair(pairs[i]).token0() == USDG ? a : b;
        }
        emit log_named_decimal_uint("USDG in all known pairs", pairTotal, 18);
        assertLt(pairTotal, 1_100e18);
    }
}
