// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";

/// @title SYMMIO-IOTA (L2-25) — adversarial gate tests on a pinned IOTA EVM fork.
/// @notice Read-only research PoC. No mainnet transactions. Fork simulation only.
/// All assertions are "the gate holds / the attacker gains nothing" style, plus
/// live-state pins. The diamond holds ~2,069 USDT (all owner/role-gated).
contract SymmioIotaTest is Test {
    address constant DIAMOND = 0xc258535aaF6ad3cEd5D2E03e2B66C35262488309;
    address constant USDT = 0xC1B8045A6ef2934Cf0f78B0dbD489969Fa9Be7E4;
    address constant PARTYB_CTR = 0x10b682bf5b380c900BF4507c07e7365873A2293C; // SymmioPartyB proxy (TRUSTED/MANAGER-gated)
    address constant ADMIN_EOA = 0x9BC9CA7e6A8F013f40617c4585508A988DB7C1c7; // diamond roles + PartyB TRUSTED
    address constant PARTYA_2 = 0x1072d1DF72759f5F24314E58e2949d9D187925Cd;
    address constant PARTYA_3 = 0x0E47F832F2331EFeB2EE69B294d2b513d868b0bd;
    address constant OWNER_TIMELOCK = 0xe639B85B77F5D31d37C52AD1F026C6508f48DC61;
    address constant ATTACKER = address(0xA11CE);

    uint256 constant FORK_BLOCK = 13_020_955;

    function setUp() public {
        vm.createSelectFork(
            vm.envOr("IOTA_RPC_URL", string("https://json-rpc.evm.iotaledger.net")),
            FORK_BLOCK
        );
        vm.deal(ATTACKER, 100 ether);
    }

    // ---------------------------------------------------------------- helpers

    function _diamondCall(bytes memory data) internal returns (bool ok, bytes memory ret) {
        vm.prank(ATTACKER);
        return DIAMOND.call(data);
    }

    function _hasRole(address who, bytes32 role) internal view returns (bool) {
        (bool ok, bytes memory ret) = DIAMOND.staticcall(
            abi.encodeWithSignature("hasRole(address,bytes32)", who, role)
        );
        require(ok, "hasRole failed");
        return abi.decode(ret, (bool));
    }

    // ------------------------------------------------------------ live state

    /// @notice Pins the live state relied upon by the verdict.
    function test_state_pins() public view {
        // Collateral is real bridged USDT (LayerZero OFT), 6 decimals.
        (bool ok, bytes memory ret) = USDT.staticcall(abi.encodeWithSignature("balanceOf(address)", DIAMOND));
        assertTrue(ok);
        assertEq(abi.decode(ret, (uint256)), 2_069_000_001, "diamond USDT balance");

        // No bridge transactions ever created -> bridge path moot.
        (ok, ret) = DIAMOND.staticcall(abi.encodeWithSignature("getNextBridgeTransactionId()"));
        assertEq(abi.decode(ret, (uint256)), 0, "next bridge tx id");

        // All three PartyAs have zero open positions (dormant since May-2025).
        address[3] memory aas = [ADMIN_EOA, PARTYA_2, PARTYA_3];
        for (uint256 i = 0; i < 3; i++) {
            (ok, ret) = DIAMOND.staticcall(abi.encodeWithSignature("partyAPositionsCount(address)", aas[i]));
            assertEq(abi.decode(ret, (uint256)), 0, "partyA open positions");
            (ok, ret) = DIAMOND.staticcall(abi.encodeWithSignature("isPartyALiquidated(address)", aas[i]));
            assertEq(abi.decode(ret, (bool)), false, "partyA liquidated");
        }

        // No one is liquidatable: no positions, positive balances.
        (ok, ret) = DIAMOND.staticcall(abi.encodeWithSignature("allocatedBalanceOfPartyA(address)", ADMIN_EOA));
        assertEq(abi.decode(ret, (uint256)), 21_860_313_000_000_000_000, "partyA1 allocated");

        // PartyB contract holds the big internal balance (1,909.99 USDT, 18 dec).
        (ok, ret) = DIAMOND.staticcall(abi.encodeWithSignature("balanceOf(address)", PARTYB_CTR));
        assertEq(abi.decode(ret, (uint256)), 1_909_992_811_175_999_993_252, "partyB internal balance");

        // Attacker holds no roles anywhere.
        assertFalse(_hasRole(ATTACKER, keccak256("DEFAULT_ADMIN_ROLE")));
        assertFalse(_hasRole(ATTACKER, keccak256("LIQUIDATOR_ROLE")));
        assertFalse(_hasRole(ATTACKER, keccak256("SETTER_ROLE")));
        assertFalse(_hasRole(ATTACKER, keccak256("PARTY_B_MANAGER_ROLE")));
        // Owner is a TimelockController, not the attacker.
        assertEq(OWNER_TIMELOCK.code.length > 0, true);
    }

    // ------------------------------------------------------- value gates (E-U)

    /// @notice A fresh attacker cannot withdraw anything: balance is zero.
    function test_attacker_withdraw_reverts() public {
        vm.prank(ATTACKER);
        (bool ok,) = DIAMOND.call(abi.encodeWithSignature("withdraw(uint256)", 1e6));
        assertFalse(ok, "withdraw must revert for a zero-balance caller");
    }

    /// @notice withdrawTo(user, amount) only ever moves the *caller's* balance.
    function test_attacker_withdrawTo_reverts() public {
        vm.prank(ATTACKER);
        (bool ok,) = DIAMOND.call(abi.encodeWithSignature("withdrawTo(address,uint256)", ATTACKER, 1e6));
        assertFalse(ok, "withdrawTo must revert for a zero-balance caller");
    }

    /// @notice allocate() is self-scoped and cannot touch others' funds.
    function test_attacker_allocate_reverts() public {
        vm.prank(ATTACKER);
        (bool ok,) = DIAMOND.call(abi.encodeWithSignature("allocate(uint256)", 1e6));
        assertFalse(ok, "allocate must revert for a zero-balance caller");
    }

    /// @notice Liquidations are LIQUIDATOR_ROLE-gated in this deployment.
    function test_attacker_liquidatePartyA_reverts_role_gate() public {
        bytes memory sig = abi.encode(
            bytes(""),
            uint256(0),
            bytes(""),
            int256(0),
            int256(0),
            new uint256[](0),
            new uint256[](0),
            bytes(""),
            // SchnorrSign {uint256 signature, address owner, address nonce}
            abi.encode(uint256(0), address(0), address(0))
        );
        (bool ok,) = _diamondCall(
            abi.encodeWithSignature(
                "liquidatePartyA(address,(bytes,uint256,bytes,int256,int256,uint256[],uint256[],bytes,(uint256,address,address)))",
                ADMIN_EOA,
                sig
            )
        );
        assertFalse(ok, "liquidatePartyA must be role-gated");
    }

    /// @notice settleUpnl is onlyPartyB + Muon-signature-bound.
    function test_attacker_settleUpnl_reverts_partyB_gate() public {
        bytes memory settlementSig = abi.encode(
            bytes(""),
            uint256(0),
            new uint256[](0), // QuoteSettlementData[]
            new int256[](0),
            int256(0),
            bytes(""),
            abi.encode(uint256(0), address(0), address(0))
        );
        (bool ok,) = _diamondCall(
            abi.encodeWithSignature(
                "settleUpnl((bytes,uint256,(uint256,uint256,uint8)[],int256[],int256,bytes,(uint256,address,address)),uint256[],address)",
                settlementSig,
                new uint256[](0),
                ADMIN_EOA
            )
        );
        assertFalse(ok, "settleUpnl must be PartyB-gated");
    }

    /// @notice Ownership (and thus every admin path) sits behind a timelock.
    function test_attacker_transferOwnership_reverts() public {
        (bool ok,) = _diamondCall(abi.encodeWithSignature("transferOwnership(address)", ATTACKER));
        assertFalse(ok, "transferOwnership must be owner-gated");
    }

    /// @notice The SymmioPartyB multicall is TRUSTED/MANAGER-gated: a fresh attacker
    ///         cannot make the PartyB contract move its 1,909.99 USDT internal balance.
    function test_partyB_call_from_attacker_reverts() public {
        bytes[] memory calls = new bytes[](1);
        calls[0] = abi.encodeWithSignature("withdraw(uint256)", 1_909_992_811_175_999_993_252);
        vm.prank(ATTACKER);
        (bool ok,) = PARTYB_CTR.call(abi.encodeWithSignature("_call(bytes[])", calls));
        assertFalse(ok, "PartyB _call must be role-gated");
    }

    /// @notice withdrawERC20 is MANAGER-gated.
    function test_partyB_withdrawERC20_from_attacker_reverts() public {
        vm.prank(ATTACKER);
        (bool ok,) = PARTYB_CTR.call(
            abi.encodeWithSignature("withdrawERC20(address,uint256)", USDT, 1e6)
        );
        assertFalse(ok, "PartyB withdrawERC20 must be role-gated");
    }

    // ------------------------------------------------- accounting sanity check

    /// @notice A fresh attacker's deposit/withdraw round trip is exactly neutral
    ///         (no share/rounding edge to exploit for profit).
    function test_roundtrip_deposit_withdraw_no_gain() public {
        deal(USDT, ATTACKER, 10e6);

        uint256 balBefore = IERC20Min(USDT).balanceOf(ATTACKER);
        uint256 diamondBefore = IERC20Min(USDT).balanceOf(DIAMOND);

        vm.startPrank(ATTACKER);
        IERC20Min(USDT).approve(DIAMOND, type(uint256).max);
        (bool ok,) = DIAMOND.call(abi.encodeWithSignature("deposit(uint256)", 10e6));
        assertTrue(ok, "deposit");
        vm.stopPrank();

        (bool ok2, bytes memory ret) = DIAMOND.staticcall(
            abi.encodeWithSignature("balanceOf(address)", ATTACKER)
        );
        assertTrue(ok2);
        assertEq(abi.decode(ret, (uint256)), 10e18, "internal 18-dec balance");

        // Withdrawals are subject to the 12h deallocateCooldown (anti-flash-deposit guard).
        vm.warp(block.timestamp + 43_200 + 1);
        vm.prank(ATTACKER);
        // withdraw() takes the raw collateral amount (6 dec) and debits the 18-dec internal balance.
        (ok,) = DIAMOND.call(abi.encodeWithSignature("withdraw(uint256)", 10e6));
        assertTrue(ok, "withdraw");

        uint256 balAfter = IERC20Min(USDT).balanceOf(ATTACKER);
        assertEq(balAfter, balBefore, "no gain from round trip");
        assertEq(IERC20Min(USDT).balanceOf(DIAMOND), diamondBefore, "diamond untouched");
    }

    /// @notice deallocate requires a valid Muon upnl signature; a dummy one reverts.
    function test_deallocate_requires_muon_sig() public {
        deal(USDT, ATTACKER, 10e6);
        vm.startPrank(ATTACKER);
        IERC20Min(USDT).approve(DIAMOND, type(uint256).max);
        (bool ok,) = DIAMOND.call(abi.encodeWithSignature("deposit(uint256)", 10e6));
        assertTrue(ok);
        ok;
        (ok,) = DIAMOND.call(abi.encodeWithSignature("allocate(uint256)", 10e6));
        assertTrue(ok, "allocate");
        bytes memory dummySig = abi.encode(
            bytes(""),
            uint256(0),
            int256(0),
            bytes(""),
            abi.encode(uint256(0), address(0), address(0))
        );
        (ok,) = DIAMOND.call(
            abi.encodeWithSignature(
                "deallocate(uint256,(bytes,uint256,int256,bytes,(uint256,address,address)))",
                10e18,
                dummySig
            )
        );
        assertFalse(ok, "deallocate must require a valid upnl signature");
        vm.stopPrank();
    }
}

interface IERC20Min {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
}
