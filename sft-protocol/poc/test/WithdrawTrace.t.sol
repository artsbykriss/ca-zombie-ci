// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";

contract WithdrawTraceTest is Test {
    address constant POOL = 0x147122D1EBdA76E4910ccdC53aEb6a58605Eb58E;
    address constant HOLDER = 0x561c6C878872BfbDA3A946BBf99b16247000c5d1;

    function setUp() public {
        vm.createSelectFork(vm.envOr("FIL_RPC_URL", string("https://filecoin.drpc.org")), 6_457_969);
    }

    function test_trace_failing_withdraw() public {
        vm.prank(HOLDER);
        (bool ok, bytes memory ret) = POOL.call(abi.encodeWithSelector(bytes4(0x2e1a7d4d), uint256(1e13)));
        emit log_named_string("ok", ok ? "yes" : "no");
        emit log_named_bytes("ret", ret);
    }
}
