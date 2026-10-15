// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";

/// When did pool withdrawals break? Probe at several historical blocks.
contract WithdrawHistoryTest is Test {
    address constant POOL = 0x147122D1EBdA76E4910ccdC53aEb6a58605Eb58E;
    address constant HOLDER = 0x561c6C878872BfbDA3A946BBf99b16247000c5d1;

    function _probe(uint256 blk) internal {
        try vm.createSelectFork(vm.envOr("FIL_RPC_URL", string("https://filecoin.drpc.org")), blk) {
            uint256 poolFil = POOL.balance;
            (bool okT, bytes memory sup) = POOL.staticcall(abi.encodeWithSignature("totalPooledFIL()"));
            uint256 tpf = okT ? abi.decode(sup, (uint256)) : 0;
            vm.prank(HOLDER);
            (bool ok, bytes memory ret) = POOL.call(abi.encodeWithSelector(bytes4(0x2e1a7d4d), uint256(1e13)));
            string memory reason = "OK";
            if (!ok) {
                if (ret.length >= 68) {
                    bytes memory s = new bytes(ret.length - 68);
                    for (uint i = 0; i < s.length; i++) s[i] = ret[i + 68];
                    reason = string(s);
                } else reason = vm.toString(ret);
            }
            emit log_named_uint("block", blk);
            emit log_named_uint("  pool FIL", poolFil);
            emit log_named_uint("  totalPooledFIL", tpf);
            emit log_named_string("  withdraw(1e13)", reason);
        } catch {
            emit log_named_uint("block", blk);
            emit log_named_string("  fork failed", "no archive state");
        }
    }

    function test_history() public {
        _probe(5_472_904);
        _probe(6_026_753);
        _probe(6_200_000);
        _probe(6_457_969);
    }
}
