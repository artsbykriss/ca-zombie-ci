// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";

/// Determine the exact relation between storage slot 2 and the withdraw gate.
contract SlotGateTest is Test {
    address constant POOL = 0x147122D1EBdA76E4910ccdC53aEb6a58605Eb58E;
    address constant HOLDER = 0x561c6C878872BfbDA3A946BBf99b16247000c5d1;

    function setUp() public {
        vm.createSelectFork(vm.envOr("FIL_RPC_URL", string("https://filecoin.drpc.org")), 6_457_969);
    }

    function tryW() internal returns (string memory) {
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

    function test_relation() public {
        bytes32 orig = vm.load(POOL, bytes32(uint256(2)));
        emit log_named_uint("orig slot2", uint256(orig));
        emit log_named_uint("pool balance", POOL.balance);

        // 1) slot2 = 0, drain pool balance
        vm.store(POOL, bytes32(uint256(2)), bytes32(0));
        vm.deal(POOL, 1);
        emit log_named_string("slot2=0 bal=1wei withdraw", tryW());

        vm.deal(POOL, 0);
        emit log_named_string("slot2=0 bal=0 withdraw", tryW());

        vm.deal(POOL, 53.79e18);

        // 2) vary slot2 with natural balance
        uint256[6] memory vals = [uint256(1e13), 53e18, 53.79e18, 54e18, 100e18, 1000e18];
        for (uint i = 0; i < vals.length; i++) {
            vm.store(POOL, bytes32(uint256(2)), bytes32(vals[i]));
            emit log_named_string(string.concat("slot2=", vm.toString(vals[i] / 1e18), " withdraw(1e13)"), tryW());
        }

        // 3) large slot2 + large balance
        vm.store(POOL, bytes32(uint256(2)), bytes32(uint256(185868e18)));
        vm.deal(POOL, 500000e18);
        emit log_named_string("slot2=185868 bal=500000 withdraw", tryW());

        // restore
        vm.store(POOL, bytes32(uint256(2)), orig);
        vm.deal(POOL, 53786226135433597936);
        emit log_named_string("restored withdraw", tryW());
    }
}
