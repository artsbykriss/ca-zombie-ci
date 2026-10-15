// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";

/// Identify which storage slot gates withdraw() and feeds getUtilizationRate().
contract SlotProbeTest is Test {
    address constant POOL = 0x147122D1EBdA76E4910ccdC53aEb6a58605Eb58E;
    address constant HOLDER = 0x561c6C878872BfbDA3A946BBf99b16247000c5d1;

    function setUp() public {
        vm.createSelectFork(vm.envOr("FIL_RPC_URL", string("https://filecoin.drpc.org")), 6_457_969);
    }

    function util() internal returns (uint256) {
        (bool ok, bytes memory r) = POOL.staticcall(abi.encodeWithSignature("getUtilizationRate()"));
        return ok ? abi.decode(r, (uint256)) : type(uint256).max;
    }

    function tryWithdraw() internal returns (string memory) {
        vm.prank(HOLDER);
        (bool ok, bytes memory ret) = POOL.call(abi.encodeWithSelector(bytes4(0x2e1a7d4d), uint256(1e13)));
        if (ok) return "OK";
        if (ret.length >= 68) {
            bytes memory s = new bytes(ret.length - 68);
            for (uint i = 0; i < s.length; i++) s[i] = ret[i + 68];
            return string(s);
        }
        return vm.toString(ret);
    }

    function test_slots() public {
        emit log_named_uint("baseline util", util());
        emit log_named_string("baseline withdraw", tryWithdraw());

        uint256[9] memory slots = [uint256(2), 3, 165, 166, 167, 176, 179, 181, 54];
        for (uint i = 0; i < slots.length; i++) {
            uint256 s = slots[i];
            bytes32 orig = vm.load(POOL, bytes32(s));
            vm.store(POOL, bytes32(s), bytes32(0));
            emit log_named_uint(string.concat("slot ", vm.toString(s), " ->0: util"), util());
            emit log_named_string(string.concat("slot ", vm.toString(s), " ->0: withdraw"), tryWithdraw());
            vm.store(POOL, bytes32(s), orig);
        }
    }
}
