// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// 2026-11 escalation — Papertrade (HyperEVM 999) contract-set-2 re-verification.
// READ-ONLY, no fork, no network at test time. Three independent checks:
//
//  E1  The CURRENT Exchange implementation (0x0A44049d…, 23,959 B, keccak 0x1fcb8043…, read live
//      at block 50,278,754) contains the BBO-mid selector 0xc0182669 exactly once and contains
//      NEITHER reference-price selector (getMarkPrice 0xa066fae9, getOraclePrice 0x2af78bd1) NOR
//      any PUSH2 of the mark/oracle/BBO precompile addresses (0x0806 / 0x0807 / 0x080e). It thus
//      cannot compare the mid to an independent price => no deviation breaker is possible on the
//      open/close path. The bytecode is embedded in poc/data/exchange_impl_0x0a44.hex.
//  E2  The live PriceOracle implementation (0x3997ffc8…, unchanged since 2026-10-15) still returns
//      exactly floor((bid+ask)/2) and accepts an arbitrarily displaced uncrossed book (+1,018 bp).
//  E3  Economics at the live per-instrument OI caps: even a full-cap sweep of one side of one
//      market is net <= ~$4.2k against the live HL book-move cost; the LP bankroll ($4.947M) needs
//      $4.3B of notional at 15 bp. Numbers are from escalation_snapshot.json / escalation_econ.json
//      at block 50,278,754 (BTC mid 77,316.5; ETH mid 2,280.45).

import {Test} from "forge-std/Test.sol";

contract MockBBO {
    fallback() external {
        assembly {
            mstore(0x00, sload(0))
            mstore(0x20, sload(1))
            return(0x00, 0x40)
        }
    }
}

contract EscalationTest is Test {
    address constant ORACLE = 0xa9B4c7b7Ca5835652d81E25739c870D49F39cC2e;
    address constant BBO_PRECOMPILE = 0x000000000000000000000000000000000000080e;
    bytes32 constant ORACLE_IMPL_KECCAK =
        0x75f094dab1fb771fc5ed5953a02be453a5d35dc4878b53a9e6a11c7d9e4e679c;
    bytes32 constant EXCHANGE_IMPL_KECCAK =
        0x1fcb80437ee76e0a495223b0aef8aecf74a4742b9fb7df18752354cd7e2877e0;

    bytes ORACLE_IMPL;
    bytes EXCHANGE_IMPL;

    function setUp() public {
        ORACLE_IMPL = vm.parseBytes(vm.trim(vm.readFile("data/oracle_impl.hex")));
        EXCHANGE_IMPL = vm.parseBytes(vm.trim(vm.readFile("data/exchange_impl_0x0a44.hex")));
        vm.etch(ORACLE, ORACLE_IMPL);
        MockBBO m = new MockBBO();
        vm.etch(BBO_PRECOMPILE, address(m).code);
    }

    // ---------- E1: current Exchange bytecode ----------

    function _count4(bytes memory hay, bytes4 needle) internal pure returns (uint256 c) {
        for (uint256 i = 0; i + 4 <= hay.length; i++) {
            if (hay[i] == needle[0] && hay[i + 1] == needle[1] &&
                hay[i + 2] == needle[2] && hay[i + 3] == needle[3]) c++;
        }
    }

    function _count3(bytes memory hay, bytes3 needle) internal pure returns (uint256 c) {
        for (uint256 i = 0; i + 3 <= hay.length; i++) {
            if (hay[i] == needle[0] && hay[i + 1] == needle[1] && hay[i + 2] == needle[2]) c++;
        }
    }

    function test_E1_exchange_impl_hash_and_no_reference_price() public view {
        assertEq(EXCHANGE_IMPL.length, 23959, "exchange impl length != live 23,959 B");
        assertEq(keccak256(EXCHANGE_IMPL), EXCHANGE_IMPL_KECCAK, "exchange impl hash != live");
        // the mid is the ONLY price the trade path can read
        assertEq(_count4(EXCHANGE_IMPL, 0xc0182669), 1, "BBO-mid selector missing/duplicated");
        // no independent reference price, hence no deviation breaker of any kind
        assertEq(_count4(EXCHANGE_IMPL, 0xa066fae9), 0, "getMarkPrice selector present");
        assertEq(_count4(EXCHANGE_IMPL, 0x2af78bd1), 0, "getOraclePrice selector present");
        assertEq(_count3(EXCHANGE_IMPL, 0x610806), 0, "mark-price precompile 0x0806 pushed");
        assertEq(_count3(EXCHANGE_IMPL, 0x610807), 0, "oracle-price precompile 0x0807 pushed");
        assertEq(_count3(EXCHANGE_IMPL, 0x61080e), 0, "BBO precompile 0x080e pushed directly");
        // the open/close entries are present (gated to authorizedExecutor, not to users)
        assertEq(_count4(EXCHANGE_IMPL, 0xec6783f0), 1, "open entry missing");
        assertEq(_count4(EXCHANGE_IMPL, 0x2792e706), 1, "close entry missing");
    }

    // ---------- E2: oracle mid + displaced book ----------

    function _setBook(uint64 bid, uint64 ask) internal {
        vm.store(BBO_PRECOMPILE, bytes32(uint256(0)), bytes32(uint256(bid)));
        vm.store(BBO_PRECOMPILE, bytes32(uint256(1)), bytes32(uint256(ask)));
    }

    function _getMid(uint32 asset) internal view returns (bool ok, uint256 mid) {
        (bool s, bytes memory r) = ORACLE.staticcall(abi.encodeWithSelector(0xc0182669, asset));
        ok = s;
        if (s && r.length >= 32) mid = abi.decode(r, (uint256));
    }

    function test_E2_oracle_hash_unchanged() public view {
        assertEq(ORACLE_IMPL.length, 2475, "oracle impl length != live 2,475 B");
        assertEq(keccak256(ORACLE_IMPL), ORACLE_IMPL_KECCAK, "oracle impl hash != live");
    }

    function test_E2_mid_is_half_sum_and_displaced_book_accepted() public {
        // ETH raw scale 100: natural mid 2,280.45; mocked +1,018 bp displaced book
        _setBook(228000, 233000); // mid = 230,500 raw = 2,305.00 (+107.6 bp)
        (bool ok, uint256 mid) = _getMid(1);
        assertTrue(ok, "uncrossed displaced book must be accepted");
        assertEq(mid, 230500, "mid must be exactly (bid+ask)/2");
        // +10% displacement still accepted (no clamp / no TWAP / no lookback)
        _setBook(228000, 250800);
        (ok, mid) = _getMid(1);
        assertTrue(ok, "10% displaced book must be accepted");
        assertEq(mid, (uint256(228000) + 250800) / 2);
    }

    // ---------- E3: full-cap sweep economics ----------

    struct CapRow {
        string name;
        uint256 notionalUsd;
        uint256 payout10;
        uint256 cost10;
        uint256 payout15;
        uint256 cost15;
    }

    function _rows() internal pure returns (CapRow[] memory r) {
        r = new CapRow[](4);
        r[0] = CapRow("BTC long", 49_705_629, 36_004, 51_883, 57_522, 83_476);
        r[1] = CapRow("BTC short", 14_911_801, 10_801, 61_192, 17_257, 99_408);
        r[2] = CapRow("ETH long", 33_939_081, 22_939, 18_691, 37_397, 35_121);
        r[3] = CapRow("ETH short", 15_650_559, 10_578, 29_438, 17_245, 46_534);
    }

    function test_E3_full_cap_sweep_15bp_max_net_below_5k() public pure {
        CapRow[] memory r = _rows();
        int256 best = type(int256).min;
        uint256 positives = 0;
        for (uint256 i = 0; i < r.length; i++) {
            int256 n15 = int256(r[i].payout15) - int256(r[i].cost15);
            if (n15 > 0) positives++;
            if (n15 > best) best = n15;
        }
        // 3 of 4 full-cap 15 bp sweeps are negative; the best (ETH long) nets +$2.3k
        assertEq(positives, 1, "expected exactly one marginally positive 15 bp full-cap sweep");
        assertLt(best, 5_000, "a 15 bp full-cap sweep nets more than $5k");
    }

    function test_E3_best_full_cap_net_below_5k() public pure {
        CapRow[] memory r = _rows();
        int256 best = type(int256).min;
        for (uint256 i = 0; i < r.length; i++) {
            int256 n10 = int256(r[i].payout10) - int256(r[i].cost10);
            int256 n15 = int256(r[i].payout15) - int256(r[i].cost15);
            if (n10 > best) best = n10;
            if (n15 > best) best = n15;
        }
        // the best single-market full-cap sweep nets < $5k, i.e. < 0.11% of the $4.947M bankroll
        assertLt(best, 5_000, "a full-cap sweep nets more than $5k");
    }

    function test_E3_bankroll_needs_billions_of_notional() public pure {
        // payout per $1 of notional at 15 bp: BTC 1,157 / 1e6, ETH 1,102 / 1e6
        uint256 bankroll = 4_947_295;
        uint256 btcNotional = bankroll * 1e6 / 1_157;
        uint256 ethNotional = bankroll * 1e6 / 1_102;
        assertGt(btcNotional, 4_000_000_000, "BTC bankroll drain needs < $4B notional");
        assertGt(ethNotional, 4_000_000_000, "ETH bankroll drain needs < $4B notional");
    }
}
