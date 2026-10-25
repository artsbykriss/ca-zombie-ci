// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";

interface IStaking {
    function depositBTC() external payable;
    function withdraw(uint256 pid) external;
    function unstake(uint256 pid, uint256 amount) external;
    function claim(uint256 pid) external;
    function stakingBalance(uint256 pid, address u) external returns (uint256);
    function poolLength() external view returns (uint256);
    function vault() external view returns (address);
    function paused() external view returns (bool);
    function withdrawPaused() external view returns (bool);
}

/// @notice Time-warp / maturity tests: can a user (or attacker) pull more native BTC
///         out of the staking contract 0xd5B5...46e or vault 0xe677...a8F3 than deposited?
contract HiveWarpTest is Test {
    IStaking constant S = IStaking(0xd5B5f1CA0fa5636ac54b0a0007BA374A1513346e);
    address constant VAULT_ADDR = 0xe677F4B6104726D76DeBc681d7a862CE269aA8F3;

    function setUp() public {
        string memory rpc = vm.envOr("BSQUARED_RPC_URL", string("https://rpc.bsquared.network"));
        vm.createSelectFork(rpc);
    }

    function _deposit(address a, uint256 amt) internal returns (bool) {
        vm.deal(a, 2 ether);
        vm.prank(a);
        (bool ok,) = address(S).call{value: amt}(abi.encodeWithSignature("depositBTC()"));
        return ok;
    }

    // deposit -> warp -> withdraw (no unstake)
    function test_warp_then_withdraw_no_unstake() public {
        address a = address(0xB0B1);
        uint256 start = 2 ether;
        uint256 dep = 0.01 ether;
        require(_deposit(a, dep), "deposit");
        uint256 sb = address(S).balance;
        uint256 vb = VAULT_ADDR.balance;
        vm.roll(block.number + 1_000_000);
        vm.prank(a);
        (bool okW,) = address(S).call(abi.encodeWithSignature("withdraw(uint256)", uint256(0)));
        console2.log("warp1M withdraw(0) ok", okW);
        console2.log("a.bal", a.balance);
        console2.log("start-deposited", start - dep);
        console2.log("staking delta", int256(address(S).balance) - int256(sb));
        console2.log("vault delta", int256(VAULT_ADDR.balance) - int256(vb));
        assertLe(a.balance, start - dep + dep, "profit");
    }

    // deposit -> unstake -> warp -> withdraw
    function test_warp_unstake_then_withdraw() public {
        address a = address(0xB0B2);
        uint256 dep = 0.01 ether;
        require(_deposit(a, dep), "deposit");
        vm.prank(a);
        (bool okU, bytes memory rU) = address(S).call(
            abi.encodeWithSignature("unstake(uint256,uint256)", uint256(0), dep)
        );
        console2.log("unstake ok", okU);
        if (!okU) console2.logBytes(rU);
        uint256 sb = address(S).balance;
        uint256 vb = VAULT_ADDR.balance;
        vm.roll(block.number + 1_000_000);
        vm.prank(a);
        (bool okW,) = address(S).call(abi.encodeWithSignature("withdraw(uint256)", uint256(0)));
        console2.log("withdraw after unstake+warp ok", okW);
        console2.log("a.bal", a.balance);
        console2.log("expected if only own funds", 2 ether - dep);
        console2.log("staking delta", int256(address(S).balance) - int256(sb));
        console2.log("vault delta", int256(VAULT_ADDR.balance) - int256(vb));
        assertLe(a.balance, 2 ether, "profit");
    }

    // attacker: deposit tiny, request huge unstake, warp, withdraw
    function test_attacker_over_unstake() public {
        address a = address(0xB0B3);
        uint256 dep = 0.001 ether;
        require(_deposit(a, dep), "deposit");
        vm.prank(a);
        (bool okU, bytes memory rU) = address(S).call(
            abi.encodeWithSignature("unstake(uint256,uint256)", uint256(0), uint256(100 ether))
        );
        console2.log("unstake(100 ether) ok", okU);
        if (!okU) console2.logBytes(rU);
        uint256 sb = address(S).balance;
        uint256 vb = VAULT_ADDR.balance;
        vm.roll(block.number + 1_000_000);
        vm.prank(a);
        (bool okW,) = address(S).call(abi.encodeWithSignature("withdraw(uint256)", uint256(0)));
        console2.log("withdraw ok", okW);
        console2.log("a.bal", a.balance);
        console2.log("staking delta", int256(address(S).balance) - int256(sb));
        console2.log("vault delta", int256(VAULT_ADDR.balance) - int256(vb));
        assertLe(a.balance, 2 ether, "E-U: over-withdraw");
    }

    // fe92e060 (permissionless withdraw-by-sid) after a real deposit + warp
    function test_fe92e060_after_deposit() public {
        address a = address(0xB0B4);
        require(_deposit(a, 0.01 ether), "deposit");
        uint256 sb = address(S).balance;
        uint256 vb = VAULT_ADDR.balance;
        vm.roll(block.number + 1_000_000);
        vm.prank(a);
        (bool ok,) = address(S).call(abi.encodeWithSelector(bytes4(0xfe92e060), uint256(0)));
        console2.log("fe92e060 ok", ok);
        console2.log("a.bal", a.balance);
        console2.log("staking delta", int256(address(S).balance) - int256(sb));
        console2.log("vault delta", int256(VAULT_ADDR.balance) - int256(vb));
        assertLe(a.balance, 2 ether, "E-U: fe92e060 drain");
    }
}
