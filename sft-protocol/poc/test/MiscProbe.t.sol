// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";

/// Probe the newer proxy 0xc28Fb206 (impl 0x89B9Dbff, holds ~2000 SFT + 0.37 FIL)
/// and the reward pool's payable deposit()/withdraw() as a fresh attacker.
contract MiscProbeTest is Test {
    address constant NEWPROXY = 0xc28Fb2061df04c3AFFEAd841863e97C4ad12Ea94;
    address constant REWARD = 0xE86D3dBd8233F1BFA22679cB57FaB3428E9654f7;
    address attacker = address(0xA11CE);

    function setUp() public {
        vm.createSelectFork(vm.envOr("FIL_RPC_URL", string("https://filecoin.drpc.org")), 6_457_969);
        vm.deal(attacker, 100 ether);
    }

    function probe(address t, bytes memory data, string memory label) internal {
        (bool ok, bytes memory ret) = t.staticcall(data);
        if (!ok) {
            emit log_named_string(string.concat(label, " (revert)"), vm.toString(ret));
        } else if (ret.length == 32) {
            emit log_named_uint(label, abi.decode(ret, (uint256)));
        } else if (ret.length >= 64) {
            // try string
            emit log_named_bytes(label, ret);
        } else {
            emit log_named_bytes(label, ret);
        }
    }

    function test_new_proxy() public {
        probe(NEWPROXY, abi.encodeWithSignature("owner()"), "NEW.owner");
        probe(NEWPROXY, abi.encodeWithSignature("sftToken()"), "NEW.sftToken");
        probe(NEWPROXY, abi.encodeWithSignature("name()"), "NEW.name");
        probe(NEWPROXY, abi.encodeWithSignature("totalSupply()"), "NEW.totalSupply");
        probe(NEWPROXY, abi.encodeWithSignature("paused()"), "NEW.paused");
        probe(NEWPROXY, abi.encodeWithSignature("rewardContract()"), "NEW.rewardContract");
        probe(NEWPROXY, abi.encodeWithSignature("redeemPool()"), "NEW.redeemPool");
        // impl slot
        emit log_named_bytes("NEW impl slot", abi.encode(vm.load(NEWPROXY, 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc)));
        emit log_named_uint("NEW FIL balance", NEWPROXY.balance);
    }

    function test_reward_deposit_roundtrip() public {
        // fresh attacker deposits 1 FIL into the reward pool
        vm.startPrank(attacker);
        (bool okDep, bytes memory r1) = REWARD.call{value: 1 ether}(abi.encodeWithSelector(bytes4(0xd0e30db0)));
        emit log_named_string("reward.deposit{1 FIL} ok", okDep ? "yes" : "no");
        emit log_named_bytes("  ret", r1);
        emit log_named_int("  attacker FIL delta", int(attacker.balance) - int(100 ether));
        (bool okW, bytes memory r2) = REWARD.call(abi.encodeWithSelector(bytes4(0x2e1a7d4d), uint256(1e18)));
        emit log_named_string("reward.withdraw(1e18) ok", okW ? "yes" : "no");
        emit log_named_bytes("  ret", r2);
        emit log_named_int("  attacker FIL delta", int(attacker.balance) - int(100 ether));
        vm.stopPrank();
    }
}
