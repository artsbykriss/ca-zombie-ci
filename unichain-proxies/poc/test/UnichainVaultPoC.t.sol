// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

/// Unichain ImmutableProxy family (ZH4-PASS6 O8) — external-unprivileged extraction probe.
/// Fork-only, read-only against the live chain (no tx is ever signed/broadcast).
///
/// Findings proven here:
///  1. Every named ImmutableProxy clone is a `Proxy` (ERC-1167-style minimal proxy) that
///     delegatecalls one of 3 impls: 0x3fd339 (Vault, verified), 0x9f70b0c8, 0x204d732e.
///  2. Every impl bakes `portal` (immutable) = its deployer; all value-moving entry points
///     (withdraw/refund/recover/fundFor) are `onlyPortal` and revert `NotPortalCaller` for a
///     stranger. Proven for ALL 3 impl families.
///  3. The clones are currently EMPTY (the "~$130k" in the recon is a stale Blockscout
///     /token-balances artifact; live balanceOf == 0). Even when funded, only the portal can
///     move the money, and the portal pays a hash-bound recipient (creator / prover claimant).
///  4. Redirecting `reward.prover` changes the intentHash -> a different (empty) vault.

struct TokenAmount { address token; uint256 amount; }
struct Reward {
    uint64 deadline;
    address creator;
    address prover;
    uint256 nativeAmount;
    TokenAmount[] tokens;
}

interface IVault {
    function withdraw(Reward calldata reward, address claimant) external;
    function refund(Reward calldata reward, address refundee) external;
    function recover(address refundee, address token) external;
    function fundFor(Reward calldata reward, address funder, address permit) external payable returns (bool);
}

interface IPortal {
    function getIntentHash(uint64 destination, bytes memory route, Reward calldata reward)
        external pure returns (bytes32 intentHash, bytes32 routeHash, bytes32 rewardHash);
}

contract UnichainImmutableProxyPoC is Test {
    // --- Unichain (130) constants, read live 2026-10-25 ---
    address constant USDC = 0x078D782b760474a361dDA0AF3839290b0EF57AD6;

    // impls
    address constant IMPL_MAIN = 0x3fd339E58769a56D08dcd2683F9012E881287476; // Vault (verified)
    address constant IMPL_9F70 = 0x9f70b0c839fe2D7190a09AE87ED658B6d1Cba4F9; // unverified variant
    address constant IMPL_204D = 0x204D732E8d2f71D756eF5De79Dc6589721b53420; // unverified variant

    // embedded `portal` immutables (confirmed statically in the runtime bytecode)
    address constant PORTAL_MAIN = 0x399Dbd5DF04f83103F77A58cBa2B7c4d3cdede97;
    address constant PORTAL_9F70 = 0xEC000064576f9C95a8623Bc0eff3db6d296ea6df;
    address constant PORTAL_204D = 0xEC000769A73b70e16f361a442292500b3BCf4A85;

    // one representative clone per impl family
    address constant CLONE_MAIN = 0x966107c49c98d49fD4Fb5CaBec1F326Cfd7Dcb60;
    address constant CLONE_9F70 = 0x86dd8FE8AFB0b60A58eb96C9c18d6ab60568Ea28;
    address constant CLONE_204D = 0x03f3D736B586aa36318Ac2b6bda58e5e74C8D4CE;

    address constant ATTACKER = address(0xA11CE);
    address constant CLAIMANT = address(0xB0B);

    error NotPortalCaller(address caller);

    function setUp() public {
        string memory rpc = vm.envOr("UNICHAIN_RPC_URL", string(""));
        if (bytes(rpc).length == 0) rpc = "https://mainnet.unichain.org";
        vm.createSelectFork(rpc);
    }

    function _reward(address prover) internal pure returns (Reward memory r) {
        TokenAmount[] memory t = new TokenAmount[](1);
        t[0] = TokenAmount(USDC, 10_000e6);
        r = Reward({deadline: 0, creator: address(0), prover: prover, nativeAmount: 0, tokens: t});
    }

    // ---- 1. clones are minimal proxies delegatecalling the expected impls ----
    function test_clones_are_immutable_proxies() public {
        address[3] memory clones = [CLONE_MAIN, CLONE_9F70, CLONE_204D];
        address[3] memory impls = [IMPL_MAIN, IMPL_9F70, IMPL_204D];
        for (uint256 i; i < 3; ++i) {
            bytes memory code = clones[i].code;
            assertGt(code.length, 0, "clone has code");
            // runtime = PUSH32 <impl> GAS DELEGATECALL ...; impl (20B) sits at byte offset 33
            address embedded;
            assembly {
                embedded := shr(96, mload(add(add(code, 0x20), 33)))
            }
            assertEq(embedded, impls[i], "clone embeds expected impl");
            assertGt(impls[i].code.length, 0, "impl has code");
        }
    }

    // ---- 2. all 3 impl families revert NotPortalCaller for a stranger ----
    function _assertStrangerReverts(address clone) internal {
        Reward memory r = _reward(address(0xdead));

        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(NotPortalCaller.selector, ATTACKER));
        IVault(clone).withdraw(r, ATTACKER);

        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(NotPortalCaller.selector, ATTACKER));
        IVault(clone).refund(r, ATTACKER);

        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(NotPortalCaller.selector, ATTACKER));
        IVault(clone).recover(ATTACKER, USDC);

        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(NotPortalCaller.selector, ATTACKER));
        IVault(clone).fundFor(r, ATTACKER, address(0));
    }

    function test_guard_main_impl() public { _assertStrangerReverts(CLONE_MAIN); }
    function test_guard_9f70_impl() public { _assertStrangerReverts(CLONE_9F70); }
    function test_guard_204d_impl() public { _assertStrangerReverts(CLONE_204D); }

    // ---- 3. clones are empty now (recon's ~$130k is a stale-index artifact) ----
    function test_clones_currently_empty() public {
        address[3] memory clones = [CLONE_MAIN, CLONE_9F70, CLONE_204D];
        for (uint256 i; i < 3; ++i) {
            emit log_named_uint("USDC balance", IERC20(USDC).balanceOf(clones[i]));
            assertEq(IERC20(USDC).balanceOf(clones[i]), 0, "clone USDC == 0");
            assertEq(clones[i].balance, 0, "clone native == 0");
        }
    }

    // ---- 4. even when funded, only the portal moves funds; stranger cannot ----
    function test_only_portal_can_move_funds() public {
        uint256 amt = 5_000e6;
        deal(USDC, CLONE_MAIN, amt);
        assertEq(IERC20(USDC).balanceOf(CLONE_MAIN), amt);

        Reward memory r = _reward(PORTAL_MAIN);

        // stranger cannot touch the now-funded vault
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(NotPortalCaller.selector, ATTACKER));
        IVault(CLONE_MAIN).withdraw(r, ATTACKER);
        assertEq(IERC20(USDC).balanceOf(ATTACKER), 0);

        // the embedded portal can, and funds go to the recipient the portal chooses
        vm.prank(PORTAL_MAIN);
        IVault(CLONE_MAIN).withdraw(r, CLAIMANT);
        assertEq(IERC20(USDC).balanceOf(CLAIMANT), amt);
        assertEq(IERC20(USDC).balanceOf(CLONE_MAIN), 0);
    }

    // ---- 5. redirecting reward.prover changes the intentHash -> a different vault ----
    function test_tampered_reward_yields_different_vault() public {
        bytes memory route = abi.encode(address(0x1234), uint256(1));
        (bytes32 h1,,) = IPortal(PORTAL_MAIN).getIntentHash(8453, route, _reward(PORTAL_MAIN));
        (bytes32 h2,,) = IPortal(PORTAL_MAIN).getIntentHash(8453, route, _reward(ATTACKER));
        emit log_named_bytes32("honest intentHash", h1);
        emit log_named_bytes32("tampered intentHash", h2);
        assertTrue(h1 != h2, "tampering reward.prover changes intentHash -> different (empty) vault");
    }
}
