// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

/// @title Z3-H12 Arcus Perps (Robinhood Chain, 4663) — fork verification suite
/// @notice READ-ONLY fork tests. No mainnet transactions are sent. All checks are
///         performed against a local fork of Robinhood Chain current state via the
///         public RPC (overridable with RH_RPC).
///         Purpose: verify the negative E-U conclusions of the deep dive:
///           1. share price = f(stored signer-pushed NAV, totalSupply) exactly;
///           2. USDG donations to the pToken cannot move the NAV or the price;
///           3. fulfilled claims are consumed (no double claim);
///           4. signed NAV-update payloads are single-use / time-bound (replay blocked);
///           5. empty pToken initial price is fixed ($100/share) -> no first-depositor inflation;
///           6. vault custody / reservedAssets sanity.
contract ArcusForkTest is Test {
    // --- addresses (Robinhood Chain, chain id 4663) ---
    address constant PT_BTC3X = 0x4472C69d299382F8847ebCE4FC6Ed8e295510E3e; // Arcus BTC (3x Long)
    address constant PT_TEST3 = 0x122408C1399E51C41B096402fea46e20E762A950; // empty pTEST3 (TA=0, TS=0)
    address constant USDG = 0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168;     // Global Dollar (6dp)
    address constant FACTORY = 0x9c3663FA9ab976E67B42939486EC4966Cb41a0BB;
    address constant MANAGER = 0xB7410dc44e2715161E9914272e2D55D7c5061FAa;
    address constant USER_F6C1 = 0xF6C1dCA6220983E07930A1a6298f4D00692E3089;

    // ERC-7201 namespaced storage (pToken impl 0x1815A37B6027Ae8066720d873A508F25fC151AC5)
    uint256 constant SLOT_BASE = 0xd9fd031555da3bce2baaa52849713cb138dd684400ec2ca4d5930be5a6752a00;
    uint256 constant SLOT_TA = SLOT_BASE + 0x0a; // totalAssets * 1000
    uint256 constant SLOT_SCALE = SLOT_BASE + 0x06; // 1000
    uint256 constant SLOT_VS = SLOT_BASE + 0x07; // 1e7 (virtual shares wei)
    uint256 constant SLOT_VA = SLOT_BASE + 0x08; // 1 (virtual assets in scaled domain)
    uint256 constant SLOT_SUPPLY = 0x52c63247e1f47db19d5ce0460030c497f067ca4cebf71ba98eeadabe20bace02; // OZ ERC20 totalSupply

    // real, already-used signed NAV-update payload (deposit fulfill, block 88864767, Oct 14 2026)
    string constant AC6AC9A0_PAYLOAD =
        "0xac6ac9a000000000000000000000000000000000000000000000000000000000"
        "0000afe60000000000000000000000004472c69d299382f8847ebce4fc6ed8e2"
        "95510e3e00000000000000000000000000000000000000000000000000000000"
        "0000000000000000000000000000000000000000000000000000000000000000"
        "0000000100000000000000000000000000000000000000000000000000000000"
        "0000afe600000000000000000000000000000000000000000000000000000000"
        "0025d29a00000000000000000000000000000000000000000000000000000000"
        "0000017f00000000000000000000000000000000000000000000000000000000"
        "0000031c00000000000000000000000000000000000000000000000000000347"
        "3a90a7c000000000000000000000000000000000000000000000000000005555"
        "e2cf6b490000000000000000000000000000000000000000000000000000589d"
        "1d60130900000000000000000000000000000000000000000000000000000000"
        "6ad0397e00000000000000000000000000000000000000000000000000000000"
        "6ad0398500000000000000000000000000000000000000000000000000000000"
        "000001e000000000000000000000000000000000000000000000000000000000"
        "0000022000000000000000000000000000000000000000000000000000000000"
        "00000001000000000000000000000000c70352b9a07be0e6afdce63ac05c540e"
        "7d8fe45a00000000000000000000000000000000000000000000000000000000"
        "0000000100000000000000000000000000000000000000000000000000000000"
        "0000002000000000000000000000000000000000000000000000000000000000"
        "00000041c887d066b0eccb9dec5ef70cda101ef5e89d4736cd3f53804e54836c"
        "669f061774ae93a9dfef831fb276a9e5db98b940668da22e44ba0747bbdda523"
        "757574681b000000000000000000000000000000000000000000000000000000"
        "00000000";

    // real historical claim: deposit(3604460120, 0xf6c1.., 0xf6c1..) at block 88864900 (consumed)
    bytes constant HISTORICAL_CLAIM =
        hex"2e2d298400000000000000000000000000000000000000000000000000000000d6d7b258000000000000000000000000f6c1dca6220983e07930a1a6298f4d00692e3089000000000000000000000000f6c1dca6220983e07930a1a6298f4d00692e3089";

    function setUp() public {
        string memory rpc = vm.envOr("RH_RPC", string("https://rpc.mainnet.chain.robinhood.com"));
        vm.createSelectFork(rpc);
    }

    // ---------- helpers ----------
    function totalAssetsStored(address p) internal view returns (uint256 v) {
        v = uint256(vm.load(p, bytes32(SLOT_TA)));
    }

    function supplySlot(address p) internal view returns (uint256 v) {
        v = uint256(vm.load(p, bytes32(SLOT_SUPPLY)));
    }

    function callUint(address to, bytes memory data) internal view returns (uint256 v) {
        (bool ok, bytes memory ret) = to.staticcall(data);
        require(ok && ret.length >= 32, "call failed");
        v = abi.decode(ret, (uint256));
    }

    function convShares(address p, uint256 assets) internal view returns (uint256) {
        return callUint(p, abi.encodeWithSelector(bytes4(0xc6e6f592), assets));
    }

    function convAssets(address p, uint256 shares) internal view returns (uint256) {
        return callUint(p, abi.encodeWithSelector(bytes4(0x07a2d13a), shares));
    }

    // ---------- 1. exact share-price formula ----------
    function test_price_formula_matches_storage() public {
        uint256 ta = totalAssetsStored(PT_BTC3X); // NAV * 1000
        uint256 supply = supplySlot(PT_BTC3X);
        uint256 vs = uint256(vm.load(PT_BTC3X, bytes32(SLOT_VS))); // 1e7
        uint256 va = uint256(vm.load(PT_BTC3X, bytes32(SLOT_VA))); // 1
        uint256 scale = uint256(vm.load(PT_BTC3X, bytes32(SLOT_SCALE))); // 1000
        assertEq(vs, 1e7, "virtual shares constant");
        assertEq(va, 1, "virtual assets constant");
        assertEq(scale, 1000, "NAV scale");

        // convertToShares(assets) = assets * (supply + vs) * scale / (ta + va)
        uint256 expectedShares = (1_000_000 * (supply + vs) * scale) / (ta + va);
        assertEq(convShares(PT_BTC3X, 1_000_000), expectedShares, "convertToShares formula");
        // convertToAssets(shares) = shares * (ta + va) / (supply + vs) / scale
        uint256 expectedAssets = (1e18 * (ta + va)) / (supply + vs) / scale;
        assertEq(convAssets(PT_BTC3X, 1e18), expectedAssets, "convertToAssets formula");

        emit log_named_uint("NAV (6dp)", ta / scale);
        emit log_named_uint("totalSupply", supply);
        emit log_named_uint("price per share (6dp)", expectedAssets);
    }

    // ---------- 2. USDG donation cannot move NAV / price ----------
    function test_donation_cannot_move_nav() public {
        uint256 taBefore = totalAssetsStored(PT_BTC3X);
        uint256 sharesBefore = convShares(PT_BTC3X, 1_000_000);
        // donate USDG straight into the pToken (impersonate a holder via deal, fallback to vm.store on balance slot)
        uint256 bal = IERC20(USDG).balanceOf(PT_BTC3X);
        deal(USDG, PT_BTC3X, bal + 1_000_000e6);
        assertEq(IERC20(USDG).balanceOf(PT_BTC3X), bal + 1_000_000e6, "donation applied");
        assertEq(totalAssetsStored(PT_BTC3X), taBefore, "stored NAV unchanged by donation");
        assertEq(convShares(PT_BTC3X, 1_000_000), sharesBefore, "price unchanged by donation");
    }

    // ---------- 3. fulfilled claim already consumed (no double claim) ----------
    function test_no_double_claim() public {
        vm.prank(USER_F6C1);
        (bool ok, bytes memory ret) = PT_BTC3X.call(HISTORICAL_CLAIM);
        assertFalse(ok, "historical claim must revert");
        assertEq(bytes4(ret), bytes4(0x6565c4ec), "claimable-exceeded error");
        // and claimableDepositRequest(343, user) is 0
        uint256 claimable = callUint(PT_BTC3X, abi.encodeWithSelector(bytes4(0x995ea21a), uint256(343), USER_F6C1));
        assertEq(claimable, 0, "claimable consumed");
    }

    // ---------- 4. signed NAV payload replay is blocked (single-use / time-bound) ----------
    function test_nav_payload_replay_blocked() public {
        bytes memory payload = vm.parseBytes(AC6AC9A0_PAYLOAD);
        // from an unprivileged attacker
        vm.prank(address(0x1111111111111111111111111111111111111111));
        (bool ok1, bytes memory ret1) = PT_BTC3X.call(payload);
        assertFalse(ok1, "attacker replay must revert");
        assertEq(bytes4(ret1), bytes4(0x3ac328da), "epoch/state error (attacker)");
        // from the real manager EOA
        vm.prank(MANAGER);
        (bool ok2, bytes memory ret2) = PT_BTC3X.call(payload);
        assertFalse(ok2, "manager replay must revert");
        assertEq(bytes4(ret2), bytes4(0x3ac328da), "epoch/state error (manager)");
    }

    // ---------- 5. empty pToken: initial price fixed at $100/share (no inflation attack) ----------
    function test_empty_token_initial_price() public {
        uint256 ta = totalAssetsStored(PT_TEST3);
        uint256 supply = supplySlot(PT_TEST3);
        assertEq(ta, 0, "empty token NAV");
        assertEq(supply, 0, "empty token supply");
        // convertToShares(1 USDG) = 1e6 * (0+1e7) * 1000 / (0+1) = 1e16
        assertEq(convShares(PT_TEST3, 1e6), 1e16, "empty-token shares per 1 USDG");
        // convertToAssets(1e18 shares) = 1e18 * 1 / 1e7 / 1000 = 1e8 = $100
        assertEq(convAssets(PT_TEST3, 1e18), 1e8, "empty-token initial price");
        // price is independent of first deposit size: shares scale linearly with assets
        assertEq(convShares(PT_TEST3, 1e8), 1e18, "first deposit $100 -> 1 share");
    }

    // ---------- 6. custody sanity ----------
    function test_vault_custody_and_reserved() public {
        uint256 vaultUsdg = IERC20(USDG).balanceOf(PT_BTC3X);
        uint256 reserved = callUint(PT_BTC3X, abi.encodeWithSelector(bytes4(0x3d302d06))); // reservedAssets()
        emit log_named_uint("pToken USDG balance (6dp)", vaultUsdg);
        emit log_named_uint("reservedAssets (6dp)", reserved);
        // the pToken keeps only working balance; NAV includes the perp account off-contract
        assertGt(vaultUsdg, 0, "vault holds some working USDG");
    }

    // ---------- 7. deposit requests are allowlist-gated per controller ----------
    function test_deposit_request_gate() public {
        address fresh = address(0x2222222222222222222222222222222222222222);
        // factory per-address flag: fresh address not registered, known depositor registered
        assertEq(callUint(FACTORY, abi.encodeWithSelector(bytes4(0x57d41c64), fresh)), 0, "fresh flag");
        assertEq(callUint(FACTORY, abi.encodeWithSelector(bytes4(0x57d41c64), USER_F6C1)), 1, "depositor flag");

        // fresh address: requestDeposit must revert (even funded + approved)
        deal(USDG, fresh, 10e6);
        vm.startPrank(fresh);
        IERC20(USDG).approve(PT_BTC3X, 5e6);
        (bool okFresh,) = PT_BTC3X.call(abi.encodeWithSelector(bytes4(0x85b77f45), uint256(5e6), fresh, fresh));
        vm.stopPrank();
        assertFalse(okFresh, "fresh address must be blocked from requestDeposit");

        // allowlisted depositor: requestDeposit succeeds on the fork (escrowed in the pToken)
        deal(USDG, USER_F6C1, 10e6);
        vm.startPrank(USER_F6C1);
        IERC20(USDG).approve(PT_BTC3X, 5e6);
        (bool okKnown,) = PT_BTC3X.call(abi.encodeWithSelector(bytes4(0x85b77f45), uint256(5e6), USER_F6C1, USER_F6C1));
        vm.stopPrank();
        assertTrue(okKnown, "allowlisted depositor can requestDeposit");
        assertEq(IERC20(USDG).balanceOf(PT_BTC3X), 25_064_520 + 5e6, "deposit escrowed in pToken");
    }
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function totalSupply() external view returns (uint256);
}
