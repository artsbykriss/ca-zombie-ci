// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";

/// Debug: find the exact gate on lending-pool withdraw() for a real rSFT holder.
contract WithdrawGateTest is Test {
    address constant POOL = 0x147122D1EBdA76E4910ccdC53aEb6a58605Eb58E;
    address constant HOLDER = 0x561c6C878872BfbDA3A946BBf99b16247000c5d1; // ~355 rSFT
    address constant BIG = 0x5d302EbE6D1F3ad1621CFD5ab6c4EcEc4569c4a8; // ~100,081 rSFT

    function setUp() public {
        string memory rpc = vm.envOr("FIL_RPC_URL", string("https://filecoin.drpc.org"));
        vm.createSelectFork(rpc, 6_457_969);
    }

    function _tryWithdraw(address who, uint256 amount) internal {
        uint256 before = who.balance;
        vm.prank(who);
        (bool ok, bytes memory ret) = POOL.call(abi.encodeWithSelector(bytes4(0x2e1a7d4d), amount));
        string memory reason = "";
        if (!ok) {
            if (ret.length >= 68) {
                bytes memory strBytes = new bytes(ret.length - 68);
                for (uint i = 0; i < strBytes.length; i++) strBytes[i] = ret[i + 68];
                reason = string(strBytes);
            } else {
                reason = vm.toString(ret);
            }
        }
        emit log_named_string(
            string.concat("withdraw(", vm.toString(amount), ") ok/reason"),
            ok ? "OK" : reason
        );
        emit log_named_int("  payout", int(who.balance) - int(before));
    }

    function test_gate_amounts() public {
        emit log_named_uint("pool FIL", POOL.balance);
        _tryWithdraw(HOLDER, 1e13);   // 0.00001 FIL (historical amount)
        _tryWithdraw(HOLDER, 1e15);   // 0.001 FIL
        _tryWithdraw(HOLDER, 1e17);   // 0.1 FIL
        _tryWithdraw(HOLDER, 1e18);   // 1 FIL
        _tryWithdraw(HOLDER, 50e18);  // 50 FIL
        _tryWithdraw(BIG, 1e13);
        _tryWithdraw(BIG, 1e18);
    }
}
