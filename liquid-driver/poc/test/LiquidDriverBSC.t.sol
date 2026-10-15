// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import {IERC20, IMiniChefV2} from "../src/Interfaces.sol";

/// Liquid Driver (BSC) — live extraction tests, fork of BSC mainnet.
contract LiquidDriverBSCTest is Test {
    address constant MINICHEF_BSC = 0xD46db083De31c64AF3F680f139A31fF37bac004f;
    address constant ATTACKER = 0x00000000000000000000000000000000DeaDBeef;

    function _rpc(string memory name, string memory fb) internal view returns (string memory) {
        string memory v = vm.envOr(name, string(""));
        if (bytes(v).length == 0) return fb;
        return v;
    }

    function setUp() public {
        string memory rpc = _rpc("BSC_RPC_URL", "https://bsc-rpc.publicnode.com");
        vm.createSelectFork(rpc);
    }

    function test_bsc_minichef_empty_and_gated() public {
        IMiniChefV2 mini = IMiniChefV2(MINICHEF_BSC);
        uint256 pl = mini.poolLength();
        console.log("BSC MiniChef poolLength:", pl);
        for (uint256 pid = 0; pid < pl; pid++) {
            address lp = mini.lpToken(pid);
            address st = mini.strategies(pid);
            uint256 chefBal = lp == address(0) ? 0 : IERC20(lp).balanceOf(MINICHEF_BSC);
            uint256 stratBal = st == address(0) ? 0 : IERC20(lp).balanceOf(st);
            console.log("pid", pid, "chefBal", chefBal);
            console.log("   lp", lp, "stratBal", stratBal);
            uint256 before = lp == address(0) ? 0 : IERC20(lp).balanceOf(ATTACKER);
            vm.prank(ATTACKER);
            (bool ok,) = MINICHEF_BSC.call(
                abi.encodeWithSignature("withdraw(uint256,uint256,address)", pid, uint256(1), ATTACKER));
            assertFalse(ok, "foreign withdraw reverts");
            assertEq(lp == address(0) ? 0 : IERC20(lp).balanceOf(ATTACKER), before, "no LP gained");
        }
    }

    function test_bsc_attack_surface() public {
        // attacker cannot set params on the BSC MiniChef
        vm.prank(ATTACKER);
        (bool ok1,) = MINICHEF_BSC.call(abi.encodeWithSignature("setLqdrPerSecond(uint256)", uint256(1e18)));
        vm.prank(ATTACKER);
        (bool ok2,) = MINICHEF_BSC.call(abi.encodeWithSignature("initialize(address,address,address)", ATTACKER, ATTACKER, ATTACKER));
        vm.prank(ATTACKER);
        (bool ok3,) = MINICHEF_BSC.call(abi.encodeWithSignature("upgradeTo(address)", ATTACKER));
        assertFalse(ok1, "setLqdrPerSecond gated");
        assertFalse(ok2, "already initialized");
        assertFalse(ok3, "upgrade gated");
        console.log("setLqdrPerSecond ok?", ok1, "initialize ok?", ok2);
        console.log("upgradeTo ok?", ok3);
        // read the actual LQDR token used by the BSC MiniChef
        (bool okL, bytes memory retL) = MINICHEF_BSC.staticcall(abi.encodeWithSignature("LQDR()"));
        if (okL && retL.length == 32) {
            address lqdr = abi.decode(retL, (address));
            console.log("BSC MiniChef LQDR token:", lqdr, "balance:", IERC20(lqdr).balanceOf(MINICHEF_BSC));
        }
    }
}
