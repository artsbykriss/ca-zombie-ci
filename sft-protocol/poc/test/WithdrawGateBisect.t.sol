// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";

/// Bisect the exact FIL-balance gate of pool.withdraw() by topping up the pool on the fork.
contract WithdrawGateBisectTest is Test {
    address constant POOL = 0x147122D1EBdA76E4910ccdC53aEb6a58605Eb58E;
    address constant HOLDER = 0x561c6C878872BfbDA3A946BBf99b16247000c5d1;

    function setUp() public {
        vm.createSelectFork(vm.envOr("FIL_RPC_URL", string("https://filecoin.drpc.org")), 6_457_969);
    }

    function _tryWithdrawAt(uint256 poolBalance) internal returns (bool ok, string memory reason) {
        vm.deal(POOL, poolBalance);
        vm.prank(HOLDER);
        bytes memory ret;
        (ok, ret) = POOL.call(abi.encodeWithSelector(bytes4(0x2e1a7d4d), uint256(1e13)));
        reason = "OK";
        if (!ok) {
            if (ret.length >= 68) {
                bytes memory s = new bytes(ret.length - 68);
                for (uint i = 0; i < s.length; i++) s[i] = ret[i + 68];
                reason = string(s);
            } else reason = vm.toString(ret);
        }
    }

    function test_bisect() public {
        (bool okT, bytes memory sup) = POOL.staticcall(abi.encodeWithSignature("totalPooledFIL()"));
        uint256 tpf = okT ? abi.decode(sup, (uint256)) : 0;
        emit log_named_uint("totalPooledFIL", tpf);

        uint256[6] memory balances = [
            uint256(234478e18), 500000e18, 1000000e18, 5000000e18, 50000000e18, 500000000e18
        ];
        for (uint i = 0; i < balances.length; i++) {
            vm.deal(POOL, balances[i]);
            emit log_named_uint("dealt pool FIL (wei)", POOL.balance);
            (bool ok, string memory reason) = _tryWithdrawAt(balances[i]);
            emit log_named_string(string.concat("balance ", vm.toString(balances[i] / 1e18), " FIL -> withdraw(1e13)"), reason);
            if (ok) {
                emit log_named_string("  SUCCESS at", vm.toString(balances[i]));
                break;
            }
        }
    }

    /// Is the gate on a different contract's balance (redeem/mint pool, reward pool)?
    function test_other_balances() public {
        address MINT = 0xcdAfc875eed0f346D5D2584fc6C37B539459C445;
        address REWARD = 0xE86D3dBd8233F1BFA22679cB57FaB3428E9654f7;

        vm.deal(MINT, 100e18);
        (bool ok1, string memory r1) = _tryWithdrawAt(53.79e18);
        emit log_named_string("mint=100 FIL -> withdraw(1e13)", r1);

        vm.deal(MINT, 0);
        vm.deal(REWARD, 5000e18);
        (bool ok2, string memory r2) = _tryWithdrawAt(53.79e18);
        emit log_named_string("reward=5000 FIL -> withdraw(1e13)", r2);

        vm.deal(MINT, 100e18);
        vm.deal(REWARD, 5000e18);
        (bool ok3, string memory r3) = _tryWithdrawAt(53.79e18);
        emit log_named_string("both topped -> withdraw(1e13)", r3);
    }
}
