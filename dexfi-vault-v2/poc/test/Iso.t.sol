// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/Interfaces.sol";

contract IsoTest is Test {
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant V3 = 0xE205B423935FA14626b095205C7ADa44DaEB935f;
    address constant V1 = 0x2AeCe2BE0651baE5e2EF49426060B814E245829c;
    address a = address(0xA11CE);

    function setUp() public {
        string memory rpc = vm.envOr("BASE_RPC_URL", string(""));
        if (bytes(rpc).length == 0) rpc = "https://mainnet.base.org";
        vm.createSelectFork(rpc);
    }

    function _rt(address v, uint256 dep, uint256 donate) internal {
        deal(WETH, a, 1000 ether);
        vm.startPrank(a);
        IERC20(WETH).approve(v, type(uint256).max);
        uint256 sh = IDexFiVault(v).deposit(dep, a, 0);
        if (donate > 0) IERC20(WETH).transfer(v, donate);
        uint256 b0 = IERC20(WETH).balanceOf(a);
        uint256 bal = IDexFiVault(v).balanceOf(a);
        uint256 out = IDexFiVault(v).withdraw(bal, a, 0);
        vm.stopPrank();
        emit log_named_string("vault", v == V3 ? "V3" : "V1");
        emit log_named_uint("dep", dep);
        emit log_named_uint("donate", donate);
        emit log_named_uint("shares", sh);
        emit log_named_uint("out", out);
        emit log_named_int("net vs (dep+donate)", int256(IERC20(WETH).balanceOf(a)) - int256(b0) - int256(donate));
    }

    function test_V3_plain_roundtrip() public { _rt(V3, 0.05 ether, 0); }
    function test_V3_donate_capture() public { _rt(V3, 0.05 ether, 5 ether); }
    function test_V1_plain_roundtrip() public { _rt(V1, 0.01 ether, 0); }
}
