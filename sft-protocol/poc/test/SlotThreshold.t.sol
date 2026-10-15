// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";

contract SlotThresholdTest is Test {
    address constant POOL = 0x147122D1EBdA76E4910ccdC53aEb6a58605Eb58E;
    address constant HOLDER = 0x561c6C878872BfbDA3A946BBf99b16247000c5d1;

    function setUp() public {
        vm.createSelectFork(vm.envOr("FIL_RPC_URL", string("https://filecoin.drpc.org")), 6_457_969);
    }

    function tryW() internal returns (bool ok, string memory reason) {
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

    function test_threshold() public {
        uint256[8] memory vals = [uint256(0), 1, 1000, 1e13, 1e15, 1e17, 1e18, 1e19];
        for (uint i = 0; i < vals.length; i++) {
            vm.store(POOL, bytes32(uint256(2)), bytes32(vals[i]));
            (bool ok, string memory r) = tryW();
            emit log_named_string(string.concat("slot2=", vm.toString(vals[i]), " ->"), r);
        }
    }

    function test_payout_when_slot2_zero() public {
        vm.store(POOL, bytes32(uint256(2)), bytes32(0));
        uint256 hBefore = HOLDER.balance;
        uint256 pBefore = POOL.balance;
        (bool okSup, bytes memory sup) = POOL.staticcall(abi.encodeWithSignature("balanceOf(address)", HOLDER));
        uint256 rBefore = okSup ? abi.decode(sup, (uint256)) : 0;
        (bool ok, string memory r) = tryW();
        emit log_named_string("withdraw", r);
        emit log_named_int("holder FIL delta", int(HOLDER.balance) - int(hBefore));
        emit log_named_int("pool FIL delta", int(POOL.balance) - int(pBefore));
        (okSup, sup) = POOL.staticcall(abi.encodeWithSignature("balanceOf(address)", HOLDER));
        uint256 rAfter = okSup ? abi.decode(sup, (uint256)) : 0;
        emit log_named_int("holder rSFT delta", int(rAfter) - int(rBefore));
    }
}
