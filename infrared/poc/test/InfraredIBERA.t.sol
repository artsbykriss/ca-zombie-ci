// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {IInfraredBERA, IWithdrawor, IReceivor} from "../src/IIBERA.sol";

// Custom errors reproduced from the deployed implementation (selectors verified on-chain).
error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);
error Unauthorized(address sender);
error NotPauser();
error InvalidShares();
error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);
error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

/// @title Infrared iBERA (Berachain) unprivileged-extraction PoC
/// @notice READ-ONLY mainnet research: every test runs against an anvil fork of Berachain.
///         No transaction is ever signed or sent to a real network.
/// @dev Target: iBERA ERC1967Proxy 0x9b6761bf… → impl 0xc0654903c7d76f7fe63f9ad2f01618c3b55d9dcf
///      (Etherscan-verified contract name `InfraredBERAV2_1`, byte-identical to the public
///       repo github.com/infrared-dao/contracts master src/staking/InfraredBERAV2_1.sol).
contract InfraredIBERATest is Test {
    // ---- live addresses (Berachain 80094) ----
    address constant PROXY = 0x9b6761bf2397Bb5a6624a856cC84A3A14Dcd3fe5;
    address constant IMPL = 0xC0654903c7d76F7FE63f9AD2F01618c3b55D9DcF;
    address constant WITHDRAWOR = 0x8c0E122960dc2E97dc0059c07d6901Dce72818E1;
    address constant RECEIVOR = 0xf6a4A6aCECd5311327AE3866624486b6179fEF97;
    address constant DEPOSITOR = 0x04CddC538ea65908106416986aDaeCeFD4CAB7D7;
    address constant INFRARED = 0xb71b3DaEA39012Fb0f2B14D2a9C86da9292fC126;
    address constant RATE_PROVIDER = 0x776fD57Bbeb752BDeEB200310faFAe9A155C50a0;
    address constant GOV_ADMIN = 0x182a31A27A0D39d735b31e80534CFE1fCd92c38f;
    address constant KEEPER_1 = 0x242D55c9404E0Ed1fD37dB1f00D60437820fe4f0;
    address constant KEEPER_2 = 0x0C224f0F468675aD6299f7A93D23a829964a2369;

    uint256 constant FORK_BLOCK = 27_827_865; // 0x1a89e99
    bytes32 constant IMPL_CODEHASH =
        0xf1c00f0e9ba3431a2d3c4634d775eecf2b16e7359b88f9e217632da415bd766f;

    IInfraredBERA ibera;
    address attacker;
    bytes32 GOV;
    bytes32 KEEP;
    bytes32 ADMIN;
    bytes32 PAUSER;

    function setUp() public {
        vm.createSelectFork(
            vm.envOr("BERA_RPC_URL", string("https://rpc.berachain.com")), FORK_BLOCK
        );
        ibera = IInfraredBERA(PROXY);
        attacker = makeAddr("freshAttacker");
        // cache role ids: any external call between expectRevert and the target call
        // would consume the cheatcode, so read them up front.
        GOV = ibera.GOVERNANCE_ROLE();
        KEEP = ibera.KEEPER_ROLE();
        ADMIN = ibera.DEFAULT_ADMIN_ROLE();
        PAUSER = ibera.PAUSER_ROLE();
    }

    function _unauthorized(bytes32 role) internal view returns (bytes memory) {
        return abi.encodeWithSelector(
            AccessControlUnauthorizedAccount.selector, attacker, role
        );
    }

    /* ------------------------------------------------------------------ */
    /* 1. Live state / code identity                                      */
    /* ------------------------------------------------------------------ */

    function test_A_stateSnapshotAndCodeIdentity() public view {
        assertEq(ibera.name(), "Infrared BERA");
        assertEq(ibera.symbol(), "iBERA");
        assertEq(ibera.decimals(), 18);
        assertEq(ibera.asset(), address(0)); // native BERA
        assertEq(ibera.currentImplementation(), IMPL);
        assertEq(ibera.implementation(), IMPL);

        // pinned bytecode identity: exactly the deployed implementation
        assertEq(keccak256(IMPL.code), IMPL_CODEHASH, "impl bytecode changed");

        // EIP-1967 slots: UUPS -> no ProxyAdmin (admin slot must be zero)
        bytes32 implSlot = vm.load(
            PROXY, 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
        );
        bytes32 adminSlot = vm.load(
            PROXY, 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
        );
        assertEq(implSlot, bytes32(uint256(uint160(IMPL))));
        assertEq(adminSlot, bytes32(0), "proxy unexpectedly has an admin");

        // accounting: assets (deposits) are native BERA staked via the CL, not held here
        assertGt(ibera.totalAssets(), 84_000_000e18);
        assertEq(ibera.totalAssets(), ibera.deposits());
        assertEq(PROXY.balance, 0, "proxy holds native BERA");
        assertEq(ibera.withdrawalsEnabled(), true);
        assertEq(ibera.paused(), false);
        assertEq(ibera.burnFee(), 0.01 ether);
        assertEq(ibera.feeDivisorShareholders(), 4);
        assertEq(ibera.infrared(), INFRARED);
        assertEq(ibera.depositor(), DEPOSITOR);
        assertEq(ibera.withdrawor(), WITHDRAWOR);
        assertEq(ibera.receivor(), RECEIVOR);
        assertEq(ibera.rateProvider(), RATE_PROVIDER);
    }

    function test_B_roleHoldersAreProtocolMultisigAndKeepersOnly() public view {
        assertTrue(ibera.hasRole(ibera.DEFAULT_ADMIN_ROLE(), GOV_ADMIN));
        assertTrue(ibera.hasRole(ibera.GOVERNANCE_ROLE(), GOV_ADMIN));
        assertTrue(ibera.hasRole(ibera.KEEPER_ROLE(), KEEPER_1));
        assertTrue(ibera.hasRole(ibera.KEEPER_ROLE(), KEEPER_2));
        assertEq(ibera.DEFAULT_ADMIN_ROLE(), bytes32(0));

        // nobody holds PAUSER_ROLE; pause() therefore requires GOVERNANCE_ROLE
        assertFalse(ibera.hasRole(ibera.PAUSER_ROLE(), GOV_ADMIN));
        assertFalse(ibera.hasRole(ibera.PAUSER_ROLE(), KEEPER_1));

        // the attacker holds nothing
        assertFalse(ibera.hasRole(ibera.DEFAULT_ADMIN_ROLE(), attacker));
        assertFalse(ibera.hasRole(ibera.GOVERNANCE_ROLE(), attacker));
        assertFalse(ibera.hasRole(ibera.KEEPER_ROLE(), attacker));
        assertFalse(ibera.hasRole(ibera.PAUSER_ROLE(), attacker));
        assertFalse(ibera.governor(attacker));
        assertFalse(ibera.keeper(attacker));
    }

    /* ------------------------------------------------------------------ */
    /* 2. Mint is the *only* permissionless share creation, and it is     */
    /*    fully backed by msg.value (no unbacked mint path).              */
    /* ------------------------------------------------------------------ */

    function test_C_mint_with_zero_value_reverts() public {
        vm.prank(attacker);
        vm.expectRevert(InvalidShares.selector);
        ibera.mint(attacker);
    }

    function test_D_mint_is_backed_by_msgvalue_never_mints_free_shares() public {
        (uint256 sweepAmt,) = IReceivor(RECEIVOR).distribution();
        uint256 d0 = ibera.deposits();
        uint256 ts0 = ibera.totalSupply();
        uint256 bal0 = ibera.balanceOf(attacker);
        uint256 depBal0 = DEPOSITOR.balance;

        vm.deal(attacker, 100 ether);
        uint256 attBalAfterDeal = attacker.balance;
        vm.prank(attacker);
        uint256 shares = ibera.mint{value: 1 ether}(attacker);

        // shares strictly pro-rata: never more than the pre-existing rate
        uint256 fairMax = (ts0 * 1 ether) / d0;
        assertGt(shares, 0);
        assertLe(shares, fairMax, "minter received more than pro-rata shares");
        assertEq(ibera.balanceOf(attacker) - bal0, shares);
        // the deposited BERA is escrowed into the CL deposit queue
        assertEq(ibera.deposits(), d0 + sweepAmt + 1 ether);
        assertEq(DEPOSITOR.balance, depBal0 + sweepAmt + 1 ether);
        // attacker cannot mint to a *different* receiver and keep the value: the
        // shares always go to `receiver`, and they always cost msg.value.
        assertEq(attacker.balance, attBalAfterDeal - 1 ether);
    }

    /* ------------------------------------------------------------------ */
    /* 3. Burn is self-scoped: it burns the caller's own iBERA            */
    /* ------------------------------------------------------------------ */

    function test_E_burn_without_balance_reverts() public {
        vm.prank(attacker);
        vm.expectRevert(
            abi.encodeWithSelector(ERC20InsufficientBalance.selector, attacker, 0, 0.99 ether)
        );
        ibera.burn(attacker, 1 ether);
    }

    function test_F_burn_below_min_exit_fee_reverts() public {
        // shares == burnFee => netShares == 0 => InvalidShares
        vm.prank(attacker);
        vm.expectRevert(InvalidShares.selector);
        ibera.burn(attacker, 0.01 ether);
    }

    function test_G_burn_cannot_redirect_someone_elses_shares() public {
        // attacker has no iBERA; pointing the receiver anywhere still reverts on its own balance
        vm.prank(attacker);
        vm.expectRevert(
            abi.encodeWithSelector(ERC20InsufficientBalance.selector, attacker, 0, 0.99 ether)
        );
        ibera.burn(attacker, 1 ether); // receiver == attacker
        vm.prank(attacker);
        vm.expectRevert(
            abi.encodeWithSelector(ERC20InsufficientBalance.selector, attacker, 0, 0.99 ether)
        );
        ibera.burn(address(0xBEEF), 1 ether); // receiver == third party
    }

    /* ------------------------------------------------------------------ */
    /* 4. Every privileged / value-moving entry point is gated            */
    /* ------------------------------------------------------------------ */

    function test_H_accessControlSetters_are_governor_gated() public {
        vm.startPrank(attacker);
        vm.expectRevert(_unauthorized(GOV));
        ibera.setWithdrawalsEnabled(false);
        vm.expectRevert(_unauthorized(GOV));
        ibera.updateBurnFee(0);
        vm.expectRevert(_unauthorized(GOV));
        ibera.updateRateProvider(attacker);
        vm.expectRevert(_unauthorized(GOV));
        ibera.setFeeDivisorShareholders(1);
        vm.expectRevert(_unauthorized(GOV));
        ibera.updateProofTimestampBuffer(1);
        vm.expectRevert(_unauthorized(GOV));
        ibera.setDepositSignature(hex"00", hex"00");
        vm.expectRevert(_unauthorized(GOV));
        ibera.claimExitFees(attacker);
        vm.expectRevert(_unauthorized(GOV));
        ibera.unpause();
        vm.stopPrank();
    }

    function test_I_pause_requires_pauser_or_governance() public {
        vm.prank(attacker);
        vm.expectRevert(NotPauser.selector);
        ibera.pause();
    }

    function test_J_grantRole_is_gated() public {
        // OZ AccessControl: the admin of every role defaults to DEFAULT_ADMIN_ROLE
        vm.startPrank(attacker);
        vm.expectRevert(_unauthorized(ADMIN));
        ibera.grantRole(GOV, attacker);
        vm.expectRevert(_unauthorized(ADMIN));
        ibera.grantRole(KEEP, attacker);
        vm.expectRevert(_unauthorized(ADMIN));
        ibera.grantRole(ADMIN, attacker);
        vm.expectRevert(_unauthorized(ADMIN));
        ibera.grantRole(PAUSER, attacker);
        vm.expectRevert(_unauthorized(ADMIN));
        ibera.revokeRole(GOV, GOV_ADMIN);
        vm.stopPrank();
        // roles unchanged
        assertFalse(ibera.hasRole(GOV, attacker));
        assertTrue(ibera.hasRole(GOV, GOV_ADMIN));
    }

    function test_K_upgrade_is_gated_and_initialize_is_gone() public {
        vm.prank(attacker);
        vm.expectRevert(_unauthorized(GOV));
        ibera.upgradeToAndCall(attacker, "");

        // no `initialize()` on the deployed revision: proxy and impl both reject it
        (bool okProxy,) = PROXY.call(hex"8129fc1c");
        (bool okImpl,) = IMPL.call(hex"8129fc1c");
        assertFalse(okProxy, "proxy has a callable initialize()");
        assertFalse(okImpl, "impl has a callable initialize()");
        // and the impl cannot be hijacked directly either
        (bool okImpl2,) = IMPL.call(hex"8129fc1c");
        assertFalse(okImpl2);
    }

    function test_L_internalValueFunctions_are_gated() public {
        vm.startPrank(attacker);
        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, attacker));
        ibera.collect();
        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, attacker));
        ibera.sweep();
        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, attacker));
        ibera.register(hex"00112233", 1);
        vm.stopPrank();

        // registerViaProofs is onlyKeeper (raw call: must revert)
        (bool ok,) = PROXY.call(
            abi.encodeWithSelector(
                bytes4(0x31bf59ee),
                bytes32(0),
                bytes(""),
                new bytes32[](0),
                new bytes32[](0),
                uint256(0),
                bytes32(0),
                uint256(0)
            )
        );
        assertFalse(ok, "registerViaProofs was callable");
    }

    function test_M_erc20_transferFrom_needs_allowance() public {
        // the proxy itself holds iBERA (accumulated exit fees); nobody can pull them
        uint256 proxyBal = ibera.balanceOf(PROXY);
        assertGt(proxyBal, 0);
        assertEq(ibera.allowance(PROXY, attacker), 0);
        vm.prank(attacker);
        vm.expectRevert(
            abi.encodeWithSelector(ERC20InsufficientAllowance.selector, attacker, 0, 1 ether)
        );
        ibera.transferFrom(PROXY, attacker, 1 ether);
        // a random third party's balance is likewise unreachable
        vm.prank(attacker);
        vm.expectRevert(
            abi.encodeWithSelector(ERC20InsufficientAllowance.selector, attacker, 0, 1 ether)
        );
        ibera.transferFrom(KEEPER_1, attacker, 1 ether);
    }

    /* ------------------------------------------------------------------ */
    /* 5. Withdrawor / receivor are gated too                             */
    /* ------------------------------------------------------------------ */

    function test_N_withdrawor_is_gated() public {
        IWithdrawor w = IWithdrawor(WITHDRAWOR);
        vm.startPrank(attacker);
        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, attacker));
        w.queue(attacker, 1 ether);
        vm.expectRevert(
            abi.encodeWithSelector(
                AccessControlUnauthorizedAccount.selector, attacker, ibera.KEEPER_ROLE()
            )
        );
        w.process(1);
        // claim: ticket 1 belongs to somebody else
        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, attacker));
        w.claim(1);
        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, attacker));
        w.claimBatch(new uint256[](0), KEEPER_1);
        vm.stopPrank();
    }

    /* ------------------------------------------------------------------ */
    /* 6. The two permissionless non-ERC20 entry points are harmless       */
    /* ------------------------------------------------------------------ */

    function test_O_compound_is_permissionless_but_pays_the_caller_nothing() public {
        uint256 attBalBefore = attacker.balance;
        uint256 attSharesBefore = ibera.balanceOf(attacker);
        uint256 supplyBefore = ibera.totalSupply();

        vm.prank(attacker);
        ibera.compound(); // succeeds, sweeps receivor yield into `deposits`

        assertEq(attacker.balance, attBalBefore, "compound paid the caller");
        assertEq(ibera.balanceOf(attacker), attSharesBefore, "compound minted to the caller");
        // yield is added to deposits without minting shares (pro-rata to ALL holders)
        assertEq(ibera.totalSupply(), supplyBefore);
    }

    function test_P_receivor_sweep_is_permissionless_but_pays_the_caller_nothing() public {
        uint256 attBalBefore = attacker.balance;
        uint256 attSharesBefore = ibera.balanceOf(attacker);
        vm.prank(attacker);
        IReceivor(RECEIVOR).sweep(); // no auth check on the receivor
        assertEq(attacker.balance, attBalBefore, "sweep paid the caller");
        assertEq(ibera.balanceOf(attacker), attSharesBefore, "sweep minted to the caller");
    }
}
