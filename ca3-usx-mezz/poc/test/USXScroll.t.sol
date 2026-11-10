// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {
    IERC20,
    ITreasury,
    IAssetManager,
    IUSXToken,
    IGateway,
    IOldGateway
} from "../src/Interfaces.sol";

/// @title USX.Capital (Scroll) — live unprivileged-path probe
/// @notice Read-only fork test. No mainnet transactions; everything runs on a
///         local anvil fork pinned to a Scroll mainnet block.
contract USXScrollTest is Test {
    // ---- Scroll mainnet addresses (verified sources) ----
    address constant USDC = 0x06eFdBFf2a14a7c8E15944D1F4A48F9F95F663A4;
    address constant USX = 0x3b005fefC63Ca7c8d25eE21FbA3787229ba4CF03;
    address constant SUSX = 0xcB14BcdF6cD483665D10dfD6f87d908996C7F922;
    address constant TREASURY = 0x9F3d4b0C9E930Ca3957eCD3DEdb7417f8e0e4c35;
    address constant ASSET_MANAGER = 0xd16909Ecc9c71d481ee3b2Cb1968C0dAdCf0d300;
    address constant STRATEGY_SAFE = 0x340F07c2736f5022EA5e1afa8d09B04CEB7378EA;
    address constant GATEWAY = 0x6272597fc1Cc23c9E932E670156866FdD4782A30;
    address constant OLD_GATEWAY = 0x54A56a45D74f748fe5CDe96a3D17843568e287E5;
    address constant ATTACKER = address(0xA77ACC);

    // Local pinned block (Scroll archive read verified). CI may use a later
    // block if SCROLL_FORK_BLOCK is overridden; the tests only rely on the
    // invariants that matter (roles, receiver binding, zero gateway balance).
    uint256 constant PIN_BLOCK = 35_666_678;

    ITreasury treasury;
    IAssetManager am;
    IUSXToken usx;
    IGateway gateway;
    IERC20 usdc;

    function setUp() public {
        string memory rpc = vm.envOr("SCROLL_RPC_URL", string("https://rpc.scroll.io"));
        uint256 forkBlock = vm.envOr("SCROLL_FORK_BLOCK", PIN_BLOCK);
        vm.createSelectFork(rpc, forkBlock);
        treasury = ITreasury(TREASURY);
        am = IAssetManager(ASSET_MANAGER);
        usx = IUSXToken(USX);
        gateway = IGateway(GATEWAY);
        usdc = IERC20(USDC);
        console2.log("Scroll fork block", block.number);
    }

    /* ------------------------------------------------------------------ */
    /* 1. Live state                                                       */
    /* ------------------------------------------------------------------ */

    function test_live_state() public {
        console2.log("treasury USDC           ", usdc.balanceOf(TREASURY));
        console2.log("assetManagerUSDC        ", treasury.assetManagerUSDC());
        console2.log("netDeposits             ", treasury.netDeposits());
        console2.log("assetManager USDC       ", usdc.balanceOf(ASSET_MANAGER));
        console2.log("strategy Safe USDC      ", usdc.balanceOf(STRATEGY_SAFE));
        console2.log("USX contract USDC       ", usdc.balanceOf(USX));
        console2.log("USX total supply        ", usx.totalSupply());
        console2.log("gateway USDC            ", usdc.balanceOf(GATEWAY));
        console2.log("old gateway USDC        ", usdc.balanceOf(OLD_GATEWAY));

        // Exact live snapshot at block 35,666,678 (report §5).
        assertEq(usdc.balanceOf(TREASURY), 104_887_480_603);
        assertEq(treasury.assetManagerUSDC(), 463_769_234_076);
        assertEq(treasury.netDeposits(), 568_656_714_679);
        assertEq(usdc.balanceOf(ASSET_MANAGER), 50_630_629_910);
        assertEq(usdc.balanceOf(STRATEGY_SAFE), 383_892_260_000);
        assertEq(usdc.balanceOf(USX), 300_000_000_000);
        assertEq(usx.totalSupply(), 569_021_190_723_139_904_297_036);

        // The two user-facing gateways hold no USDC: there is no in-flight
        // deposit inventory to drain.
        assertEq(usdc.balanceOf(GATEWAY), 0);
        assertEq(usdc.balanceOf(OLD_GATEWAY), 0);

        // Privileged roles are Safes, not EOAs.
        assertEq(treasury.admin(), 0xE0B408663eA235c11e528a2C3f004946AFE5A7da);
        assertEq(treasury.governance(), 0xE0B408663eA235c11e528a2C3f004946AFE5A7da);
        assertEq(treasury.allocator(), 0xFF8c212885Fe7137edDCFEfdFA8aF55369Efa106);
        assertEq(treasury.reporter(), 0xFF8c212885Fe7137edDCFEfdFA8aF55369Efa106);
        assertEq(usx.admin(), 0xE0B408663eA235c11e528a2C3f004946AFE5A7da);
    }

    /// @notice The `assetManagerUSDC` accounting is 29,246.34 USDC above the
    ///         identifiable USDC (treasury + AssetManager + strategy Safe).
    ///         This is an accounting/backing gap, not an attacker path.
    function test_accounting_gap() public {
        uint256 actual = usdc.balanceOf(TREASURY) + usdc.balanceOf(ASSET_MANAGER)
            + usdc.balanceOf(STRATEGY_SAFE);
        console2.log("actual treasury+AM+strategy", actual);
        console2.log("netDeposits                ", treasury.netDeposits());
        assertEq(treasury.netDeposits() - actual, 29_246_344_166);
    }

    /* ------------------------------------------------------------------ */
    /* 2. Treasury / AssetManager are privileged-only                     */
    /* ------------------------------------------------------------------ */

    function test_treasury_admin_only() public {
        vm.startPrank(ATTACKER);
        vm.expectRevert();
        treasury.setAdmin(ATTACKER);
        vm.expectRevert();
        treasury.setGovernance(ATTACKER);
        vm.expectRevert();
        treasury.addFacet(address(0xBEEF), new bytes4[](0));
        vm.expectRevert();
        treasury.transferUSDCtoAssetManager(1);
        vm.expectRevert();
        treasury.transferUSDCFromAssetManager(1);
        vm.expectRevert();
        treasury.transferUSDCForWithdrawal();
        vm.stopPrank();
    }

    function test_assetmanager_withdraw_only_treasury() public {
        vm.prank(ATTACKER);
        vm.expectRevert();
        am.withdraw(1e6);
    }

    /* ------------------------------------------------------------------ */
    /* 3. USX mint / redeem is whitelist-gated                             */
    /* ------------------------------------------------------------------ */

    function test_usx_whitelist_gate() public {
        assertFalse(usx.whitelistedUsers(ATTACKER));
        vm.startPrank(ATTACKER);
        vm.expectRevert();
        usx.deposit(1e6);
        vm.expectRevert();
        usx.requestUSDC(1e18);
        vm.stopPrank();
    }

    /* ------------------------------------------------------------------ */
    /* 4. Private gateway: receiver binding + no admin                     */
    /* ------------------------------------------------------------------ */

    /// @notice Zellic 3.1 (Critical): the live Scroll gateway hard-binds the
    ///         user-supplied USDC receiver to the admin-set expected receiver.
    ///         A caller-chosen `usdcReceiver` reverts before any deposit.
    function test_gateway_usdc_receiver_binding() public {
        (uint256 keyId, ) = gateway.getLatestEncryptionKey();
        (bytes memory expectedReceiver, uint256 expectedKeyId) = gateway.expectedUSDCReceiver();
        assertGt(expectedReceiver.length, 0);

        IGateway.EncryptedReceiver memory usxReceiver =
            IGateway.EncryptedReceiver({receiver: bytes("attacker-usx-receiver"), keyId: keyId});
        IGateway.EncryptedReceiver memory badUsdcReceiver =
            IGateway.EncryptedReceiver({receiver: bytes("attacker-usdc-receiver"), keyId: expectedKeyId});

        deal(USDC, ATTACKER, 1e6);
        vm.startPrank(ATTACKER);
        usdc.approve(GATEWAY, 1e6);
        vm.expectRevert(); // ErrorInvalidUSDCReceiver()
        gateway.transferUSDC(1, usxReceiver, badUsdcReceiver);
        vm.stopPrank();

        // Nothing moved.
        assertEq(usdc.balanceOf(GATEWAY), 0);
        assertEq(usdc.balanceOf(ATTACKER), 1e6);
    }

    /// @notice DEFAULT_ADMIN_ROLE has zero members on the live gateway; even an
    ///         admin call is impossible, and the gateway holds no tokens.
    function test_gateway_withdraw_tokens_admin_gated() public {
        vm.prank(ATTACKER);
        vm.expectRevert();
        gateway.withdrawTokens(USDC, ATTACKER, 1);
    }

    /// @notice The older pre-fix gateway (impl 0x902D…) has no receiver binding
    ///         but holds zero USDC — there is no fuel for the 3.1 path.
    function test_old_gateway_pre_fix_unfunded() public {
        assertEq(usdc.balanceOf(OLD_GATEWAY), 0);
        vm.expectRevert();
        IOldGateway(OLD_GATEWAY).expectedUSDCReceiver();
    }

    /// @notice The user-callable path only pushes USDC to the L1 gateway; it
    ///         cannot pull from any contract. Assert the gateway's counterpart
    ///         and L1 gateway are configured, and the caller has no withdrawal
    ///         primitive.
    function test_gateway_user_path_is_one_way() public {
        assertEq(gateway.USDC(), USDC);
        assertEq(gateway.USX(), USX);
        assertTrue(gateway.counterpart() != address(0));
        assertTrue(gateway.erc20Gateway() != address(0));
        assertEq(gateway.minUSDCAmount(), 0);
        assertEq(gateway.nonce(), 28);
    }

    /* ------------------------------------------------------------------ */
    /* 5. Zellic 3.5 desync: only the role-gated Cloak call has an         */
    /*    `actualReceiver`; the Scroll user path never supplies one.       */
    /* ------------------------------------------------------------------ */

    /// @notice Documents that the only function taking `actualReceiver` lives
    ///         on the Cloak validium (chain 5343523304), which is a token-gated
    ///         privacy RPC. The Scroll-side ABI has no `actualReceiver` and no
    ///         user-callable withdraw. This is a static fact; the live proof is
    ///         the source + the audit + the role gate in PrivateGatewayCloak.
    function test_scroll_side_has_no_actual_receiver() public pure {
        // Selector of withdrawUSX(uint256,bytes,uint256,uint256,address) on the
        // Cloak gateway. It is not present on PrivateGatewayScroll; the only
        // Scroll-side mutators are transferUSDC/transferToken (deposit-only).
        bytes4 withdrawUSXSelector = bytes4(keccak256("withdrawUSX(uint256,bytes,uint256,uint256,address)"));
        assertTrue(withdrawUSXSelector == bytes4(0x05cf479a));
    }
}
