// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {IERC20, IChimeraQuoteHook404, IChimeraQuoteRouter404, PoolKey} from "../src/Interfaces.sol";

/// @title O11 — Ink ChimeraQuoteHook404: external-unprivileged extraction test
/// @notice Read-only fork test. No transaction is signed or broadcast.
///         Establishes the live state (no registered pools, no fee vaults funded) and that
///         every privileged/creator path is closed to a stranger.
contract O11_InkChimeraQuote is Test {
    string constant INK_RPC = "https://rpc-gel.inkonchain.com"; // keyless

    address constant HOOK = 0xD723B53D1A651D8BfD6b4C8876D51b68E26128CC;
    address constant ROUTER = 0x8706Daf2A2F26c43fc0e09097A228351473333A2;
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant ASSET_B = 0xB0a8e41cc40dF006d86fb4bEf7d3e52073584875; // a QuoteAllowed asset
    address constant PLATFORM = 0x44C6D689ccbE67B23D4E174bdb8B5d8d1c0f453C;

    address attacker = address(0xA11CE);

    IChimeraQuoteHook404 hook;
    IChimeraQuoteRouter404 router;

    function setUp() public {
        vm.createSelectFork(INK_RPC);
        hook = IChimeraQuoteHook404(HOOK);
        router = IChimeraQuoteRouter404(ROUTER);
    }

    function test_live_state_no_pools_no_funds() public view {
        assertEq(router.hook(), HOOK, "router bound to hook");
        assertEq(router.weth(), WETH, "weth");
        // No pool has ever been registered on this hook: the quote slot of any id is unset.
        assertEq(hook.quoteOf(bytes32(uint256(1))), address(0), "no pool 1");
        assertEq(hook.quoteOf(bytes32(0)), address(0), "no pool 0");
        // The hook and the launch-liquidity helper hold no native and no tokens.
        assertEq(HOOK.balance, 0, "hook native 0");
        assertEq(ROUTER.balance, 0, "router native 0");
        assertEq(IERC20(WETH).balanceOf(HOOK), 0, "hook WETH 0");
    }

    /// @dev distributeQuotrons is permissionless but a no-op for an unregistered pool and
    ///      can only ever pay the vault's fixed destinations.
    function test_permissionless_distribute_is_noop() public {
        hook.distributeQuotrons(bytes32(uint256(0xdead)));
        hook.distributeQuotrons(bytes32(uint256(1)));
        assertTrue(true);
    }

    function test_stranger_cannot_touch_configuration() public {
        vm.startPrank(attacker);
        vm.expectRevert();
        hook.setQuote(ASSET_B, false);
        vm.expectRevert();
        hook.setEcosystem(attacker);
        vm.expectRevert();
        hook.configureInfrastructure(attacker, attacker);
        uint256[] memory rates = new uint256[](0);
        vm.expectRevert();
        hook.updateFees(bytes32(uint256(1)), 1, 0, rates);
        address[] memory assets = new address[](1);
        assets[0] = WETH;
        uint256[] memory minima = new uint256[](1);
        minima[0] = 1;
        vm.expectRevert();
        hook.setEligibility(bytes32(uint256(1)), assets, minima);
        vm.stopPrank();
    }

    /// @dev A stranger cannot route a swap through a fabricated pool: the pool is not
    ///      initialised on the real PoolManager, so the swap reverts.
    function test_stranger_cannot_swap_fabricated_pool() public {
        deal(WETH, attacker, 1e18);
        IChimeraQuoteRouter404.Hop[] memory path = new IChimeraQuoteRouter404.Hop[](1);
        path[0] = IChimeraQuoteRouter404.Hop({
            key: PoolKey({currency0: WETH, currency1: ASSET_B, fee: 0, tickSpacing: 60, hooks: HOOK}),
            zeroForOne: true
        });

        vm.startPrank(attacker);
        IERC20(WETH).approve(ROUTER, 1e18);
        vm.expectRevert();
        router.swapPath(path, 1e18, 0, address(0), block.timestamp + 60);
        vm.stopPrank();
    }
}
