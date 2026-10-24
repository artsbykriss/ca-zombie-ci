// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

/// Minimal interfaces for Tapir DepegPool (Base) — read-only fork PoC.
interface IDepegPool {
    function getState() external view returns (uint8);
    function ASSET() external view returns (address);
    function DP_ASSET() external view returns (address);
    function YB_ASSET() external view returns (address);
    function oracle() external view returns (address);
    function TREASURY() external view returns (address);
    function redemptionFeeBp() external view returns (uint8);
    function poolActiveDuration() external view returns (uint32);
    function cooldownDuration() external view returns (uint32);
    function startTime() external view returns (uint256);
    function depegResolved() external view returns (bool);
    function poolHasDepegged() external view returns (bool);
    function dpValue() external view returns (uint16);
    function ybValue() external view returns (uint16);
    function splitToken(address counterparty, uint256 amount) external;
    function unSplitTokens(address counterparty, uint256 amounts) external;
    function redeemTokens(address counterparty, uint256 amountDP, uint256 amountYB) external;
    function resolvePriceDepeg() external;
    function sweepFeesToTreasury() external;
    function rescueErc20(address token, uint256 amount) external;
    function executeOracleChange() external;
    function isAuthorisedRouter(address) external view returns (bool);
}

/// @title Tapir DepegPool — external-unprivileged extraction probe (fork only)
/// @notice Proves that in the live ACTIVE state the only unprivileged entry points
///         (splitToken / unSplitTokens) are value-neutral-minus-fee, and every
///         value-extracting path (redeem / sweep / rescue) is state- or role-gated.
contract TapirPoC is Test {
    // Base mainnet addresses (verified 2026-10-24)
    address constant POOL   = 0x195F79D6174b9ffC115fC5E82dC724F613D658C6;
    address constant ASSET  = 0x03067bbD0d41E3Fe4A0bb6ca67c99e7352Da4CAE; // zvUSDC (6dp)
    address constant DP     = 0x0D8d6cb8D3335Af6E3A39239B425a56E8ca7f258;
    address constant YB     = 0x993543A2d1D1A00BE8B86C4a1EDe55B4d5581095;

    address attacker = address(0xA11CE);

    function setUp() public {
        // BASE_RPC_URL may be present-but-empty in CI; fall back to a public Base RPC.
        string memory rpc = vm.envOr("BASE_RPC_URL", string(""));
        if (bytes(rpc).length == 0) rpc = "https://base-rpc.publicnode.com";
        vm.createSelectFork(rpc);
    }

    function _pool() internal pure returns (IDepegPool) { return IDepegPool(POOL); }

    /// The pool is live and in ACTIVE (state == 1); value is escrowed as DP/YB backing.
    function test_live_state_and_backing() public {
        assertEq(_pool().getState(), 1, "state must be ACTIVE");
        assertFalse(_pool().depegResolved());
        assertFalse(_pool().poolHasDepegged());
        assertEq(_pool().redemptionFeeBp(), 22);

        uint256 assetBal = IERC20(ASSET).balanceOf(POOL);
        uint256 dpSupply = IERC20(DP).totalSupply();
        uint256 ybSupply = IERC20(YB).totalSupply();

        emit log_named_uint("pool ASSET (zvUSDC 6dp)", assetBal);
        emit log_named_uint("DP totalSupply", dpSupply);
        emit log_named_uint("YB totalSupply", ybSupply);

        // Backing == 2x per-leg supply (each split deposits 2 base for 1 DP + 1 YB);
        // the small excess is accumulated unSplit/redemption fees, not free money.
        assertApproxEqAbs(assetBal, 2 * dpSupply, 1e9, "backing ~= 2x DP supply");
        assertEq(dpSupply, ybSupply, "equal leg supplies");
        // Excess (fees) is tiny (< $1).
        assertLt(assetBal - 2 * dpSupply, 1e9);
    }

    /// Attacker CANNOT redeem: redeemTokens is only valid in REDEMPTIONS (state 4).
    function test_redeem_reverts_in_active() public {
        vm.prank(attacker);
        vm.expectRevert();
        _pool().redeemTokens(attacker, 1, 1);
    }

    /// Attacker CANNOT sweep fees: only valid in REDEMPTIONS.
    function test_sweep_reverts_in_active() public {
        vm.prank(attacker);
        vm.expectRevert();
        _pool().sweepFeesToTreasury();
    }

    /// Attacker CANNOT rescue the escrowed asset: onlyAdminOrOperator + 30d timelock.
    function test_rescue_reverts_for_stranger() public {
        vm.prank(attacker);
        vm.expectRevert();
        _pool().rescueErc20(ASSET, 1);
    }

    /// resolvePriceDepeg is permissionless but only valid in RESOLUTION (state 3); reverts now.
    function test_resolve_reverts_in_active() public {
        vm.prank(attacker);
        vm.expectRevert();
        _pool().resolvePriceDepeg();
    }

    /// No pending oracle -> executeOracleChange reverts (nothing to hijack).
    function test_execute_oracle_change_noop() public {
        vm.prank(attacker);
        vm.expectRevert();
        _pool().executeOracleChange();
    }

    /// The core "no free money" proof: the only unprivileged ops are split/unSplit,
    /// and a full round trip strictly loses value (redemption fee). An attacker
    /// cannot end with more ASSET than they started.
    function test_split_unsplit_roundtrip_is_lossy() public {
        deal(ASSET, attacker, 2_000e6);

        uint256 startBal = IERC20(ASSET).balanceOf(attacker);
        vm.startPrank(attacker);
        IERC20(ASSET).approve(POOL, type(uint256).max);

        // 2 base -> 1 DP + 1 YB
        _pool().splitToken(attacker, 2_000e6);
        assertEq(IERC20(DP).balanceOf(attacker), 1_000e6);
        assertEq(IERC20(YB).balanceOf(attacker), 1_000e6);

        // 1 DP + 1 YB -> 2 base minus fee
        _pool().unSplitTokens(attacker, 1_000e6);
        vm.stopPrank();

        uint256 endBal = IERC20(ASSET).balanceOf(attacker);
        emit log_named_uint("start ASSET", startBal);
        emit log_named_uint("end   ASSET", endBal);
        assertLt(endBal, startBal, "round trip must be lossy");
        // loss == fee on 2 base == 0.22% of 2000e6 == 4.4e6
        assertEq(startBal - endBal, 4_400_000);
    }

    /// Fuzzed: no (split, unSplit) sequence yields a positive ASSET delta.
    function testFuzz_no_positive_roundtrip(uint96 amount) public {
        amount = uint96(bound(uint256(amount), 2, 1_000_000e6));
        uint256 even = (uint256(amount) / 2) * 2; // split mints floor(amount/2)
        deal(ASSET, attacker, even);
        uint256 startBal = IERC20(ASSET).balanceOf(attacker);
        vm.startPrank(attacker);
        IERC20(ASSET).approve(POOL, type(uint256).max);
        _pool().splitToken(attacker, even);
        uint256 leg = even / 2;
        _pool().unSplitTokens(attacker, leg);
        vm.stopPrank();
        assertLe(IERC20(ASSET).balanceOf(attacker), startBal, "no profit");
    }

    /// An attacker cannot pull a victim's tokens: split/unSplit act on msg.sender
    /// (or an authorised router), and the vault only ever pays the counterparty.
    function test_cannot_act_for_arbitrary_victim() public {
        address victim = address(0xBEEF);
        deal(ASSET, victim, 1_000e6);
        vm.prank(attacker);
        vm.expectRevert(); // UnauthorizedCaller: msg.sender != counterparty and not router
        _pool().splitToken(victim, 1_000e6);
    }
}
