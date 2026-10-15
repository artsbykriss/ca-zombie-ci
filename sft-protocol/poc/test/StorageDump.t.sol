// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";

/// Dump the lending pool's storage slots (read-only) to locate accounting variables.
contract StorageDumpTest is Test {
    address constant POOL = 0x147122D1EBdA76E4910ccdC53aEb6a58605Eb58E;

    function setUp() public {
        vm.createSelectFork(vm.envOr("FIL_RPC_URL", string("https://filecoin.drpc.org")), 6_457_969);
    }

    function test_dump() public {
        uint256 rSftSupply = 234477718487329089234903;
        uint256 poolBal = 53786226135433597936;
        for (uint256 i = 0; i < 200; i++) {
            bytes32 v = vm.load(POOL, bytes32(i));
            uint256 u = uint256(v);
            if (u == 0) continue;
            string memory tag = "";
            if (u == rSftSupply) tag = " <== rSFT supply / totalPooledFIL";
            if (u == poolBal) tag = " <== actual FIL balance";
            if (u == 9500) tag = " <== borrowThreshold?";
            if (u == 6000) tag = " <== ltv?";
            if (u == 5000) tag = " <== slope1?";
            if (u == 9999) tag = " <== utilization?";
            if (u == 1733895600) tag = " <== startTime";
            emit log_named_uint(string.concat("slot ", vm.toString(i), tag), u);
            if (u < type(uint160).max) {
                emit log_named_address("   addr view", address(uint160(u)));
            }
        }
    }
}
