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
    function claimPaused() external view returns (bool);
    function hasRole(bytes32 role, address account) external view returns (bool);
    function ADMIN_ROLE() external view returns (bytes32);
    function UPGRADE_ROLE() external view returns (bytes32);
}

interface IVault {
    function strategies(uint256 pid) external view returns (address);
    function paused() external view returns (bool);
    function transferToStaking(uint256 amount) external;
    function withdraw(uint256 pid, uint256 amount, address user) external;
}

/// @notice Read-only fork verification of the Hive Protocol (BSquared 223) BTC-staking surface.
/// Verifies whether an EXTERNAL UNPRIVILEGED attacker can move native BTC out of the
/// staking contract 0xd5B5...46e (2,918.95 BTC) or vault 0xe677...a8F3 (418.29 BTC).
contract HiveForkTest is Test {
    IStaking constant S = IStaking(0xd5B5f1CA0fa5636ac54b0a0007BA374A1513346e);
    address constant VAULT_ADDR = 0xe677F4B6104726D76DeBc681d7a862CE269aA8F3;
    IVault constant VAULT = IVault(0xe677F4B6104726D76DeBc681d7a862CE269aA8F3);
    address constant B2 = 0x783c3f003f172c6Ac5AC700218a357d2D66Ee2a2;
    address constant STRATMGR = 0xcf38C660e0E99BED4c4aC8817922A0a3A996700B;
    address constant ATTACKER = address(0xA11CE);

    function setUp() public {
        string memory rpc = vm.envOr("BSQUARED_RPC_URL", string("https://rpc.bsquared.network"));
        vm.createSelectFork(rpc);
    }

    // ------------------------------------------------------------------ state
    function test_state() public {
        console2.log("== Hive state ==");
        console2.log("block", block.number);
        console2.log("staking bal (wei)", address(S).balance);
        console2.log("vault   bal (wei)", VAULT_ADDR.balance);
        console2.log("poolLength", S.poolLength());
        console2.log("paused", S.paused());
        console2.log("withdrawPaused", S.withdrawPaused());
        console2.log("claimPaused", S.claimPaused());
        console2.log("ADMIN_ROLE", uint256(S.ADMIN_ROLE()));
        console2.log("UPGRADE_ROLE", uint256(S.UPGRADE_ROLE()));
        assertEq(S.vault(), VAULT_ADDR, "vault() mismatch");
    }

    function test_roles() public {
        address[10] memory cands = [
            0xd5B5f1CA0fa5636ac54b0a0007BA374A1513346e,
            0xe677F4B6104726D76DeBc681d7a862CE269aA8F3,
            0xcf38C660e0E99BED4c4aC8817922A0a3A996700B,
            0xA3eb53ddA8181Ae48FDfE16Ed3d7F37859F7f97b,
            0x796e4D53067FF374B89b2Ac101ce0c1f72ccaAc2,
            0x8208bd314b6d730845E0F1427bC5a150EdE9baE7,
            0x59b1cDe6D056d8B8E36Ac6055a9d46d071a6C036,
            0x41b3C11d65bA8B625d0116E6f512C5e605f946f7,
            0x6a7C2f1272a9703092D13Df23742a65e18DD1D06,
            0x7b40779fb681054df2b2F29b527CEB5eeca9d3fd
        ];
        for (uint256 i = 0; i < cands.length; i++) {
            console2.log("cand", cands[i]);
            console2.log("   ADMIN", S.hasRole(S.ADMIN_ROLE(), cands[i]));
            console2.log("   UPGRADE", S.hasRole(S.UPGRADE_ROLE(), cands[i]));
        }
    }

    // ------------------------------------------- E-U probe: non-staker withdraw
    function test_withdraw_nonstaker_no_free_money() public {
        address a = address(0xBEEF0001);
        vm.deal(a, 0);
        uint256 sb = address(S).balance;
        uint256 vb = VAULT_ADDR.balance;
        vm.prank(a);
        (bool ok, bytes memory ret) =
            address(S).call(abi.encodeWithSignature("withdraw(uint256)", uint256(0)));
        console2.log("non-staker withdraw(0) ok", ok);
        if (!ok) console2.logBytes(ret);
        console2.log("attacker gain", a.balance);
        console2.log("staking delta", int256(address(S).balance) - int256(sb));
        console2.log("vault delta", int256(VAULT_ADDR.balance) - int256(vb));
        assertEq(a.balance, 0, "E-U: non-staker got free BTC");
        assertEq(address(S).balance, sb, "E-U: staking balance dropped");
        assertEq(VAULT_ADDR.balance, vb, "E-U: vault balance dropped");
    }

    // ------------------------------------------- deposit -> withdraw: payout source
    function test_deposit_then_withdraw_payout_source() public {
        address a = address(0xBEEF0002);
        vm.deal(a, 1 ether);
        uint256 start = a.balance;

        vm.prank(a);
        (bool okD,) = address(S).call{value: 0.01 ether}(abi.encodeWithSignature("depositBTC()"));
        console2.log("depositBTC ok", okD);
        uint256 sb1 = address(S).balance;
        uint256 vb1 = VAULT_ADDR.balance;
        console2.log("after deposit staking", sb1);
        console2.log("after deposit vault", vb1);

        vm.prank(a);
        (bool okW, bytes memory retW) =
            address(S).call(abi.encodeWithSignature("withdraw(uint256)", uint256(0)));
        console2.log("withdraw(0) ok", okW);
        if (!okW) console2.logBytes(retW);
        console2.log("a.bal final", a.balance);
        console2.log("start bal", start);
        console2.log("staking delta", int256(address(S).balance) - int256(sb1));
        console2.log("vault delta", int256(VAULT_ADDR.balance) - int256(vb1));
        assertLe(a.balance, start, "E-U: roundtrip yielded profit");
    }

    // ------------------------------------------- deposit -> unstake -> withdraw
    function test_deposit_unstake_then_withdraw() public {
        address a = address(0xBEEF0003);
        vm.deal(a, 1 ether);
        uint256 start = a.balance;
        vm.prank(a);
        (bool okD,) = address(S).call{value: 0.01 ether}(abi.encodeWithSignature("depositBTC()"));
        console2.log("deposit ok", okD);
        vm.prank(a);
        (bool okU, bytes memory rU) = address(S).call(
            abi.encodeWithSignature("unstake(uint256,uint256)", uint256(0), uint256(0.01 ether))
        );
        console2.log("unstake ok", okU);
        if (!okU) console2.logBytes(rU);
        vm.prank(a);
        (bool okW, bytes memory rW) =
            address(S).call(abi.encodeWithSignature("withdraw(uint256)", uint256(0)));
        console2.log("withdraw ok", okW);
        if (!okW) console2.logBytes(rW);
        console2.log("a.bal after", a.balance);
        console2.log("start", start);
        assertLe(a.balance, start, "E-U: unstake+withdraw profit");
    }

    // ------------------------------------------- cross-user withdraw
    function test_cross_user_withdraw() public {
        address a = address(0xBEEF0004);
        address b = address(0xBEEF0005);
        vm.deal(a, 1 ether);
        vm.deal(b, 0);
        vm.prank(a);
        (bool okD,) = address(S).call{value: 0.01 ether}(abi.encodeWithSignature("depositBTC()"));
        console2.log("A deposit ok", okD);
        vm.prank(b);
        (bool okW,) = address(S).call(abi.encodeWithSignature("withdraw(uint256)", uint256(0)));
        console2.log("B withdraw(0) ok", okW);
        console2.log("B bal", b.balance);
        assertEq(b.balance, 0, "E-U: cross-user extraction");
    }

    // ------------------------------------------- systematic permissionless probe
    function test_probe_all_permissionless_surface() public {
        uint256 sb0 = address(S).balance;
        uint256 vb0 = VAULT_ADDR.balance;
        _probe("fe92e060", abi.encodeWithSelector(bytes4(0xfe92e060), uint256(0)));
        _probe("75c717ef", abi.encodeWithSelector(bytes4(0x75c717ef), uint256(0), ATTACKER, uint256(1 ether)));
        _probe("fb2d64b1", abi.encodeWithSelector(bytes4(0xfb2d64b1), uint256(0), ATTACKER));
        _probe("514c25c3", abi.encodeWithSelector(bytes4(0x514c25c3), uint256(0), ATTACKER));
        _probe("eb24f085", abi.encodeWithSelector(bytes4(0xeb24f085), uint256(0), ATTACKER));
        _probe("5742e15e", abi.encodeWithSelector(bytes4(0x5742e15e), uint256(0), ATTACKER));
        _probe("51118695", abi.encodeWithSelector(bytes4(0x51118695), uint256(0), ATTACKER));
        _probe("6711a456", abi.encodeWithSelector(bytes4(0x6711a456), uint256(0), ATTACKER));
        _probe("9da20636", abi.encodeWithSelector(bytes4(0x9da20636), uint256(1)));
        _probe("6ad8e6ee", abi.encodeWithSelector(bytes4(0x6ad8e6ee)));
        _probe("cd7a5110", abi.encodeWithSelector(bytes4(0xcd7a5110)));
        _probe("10e6589f", abi.encodeWithSelector(bytes4(0x10e6589f), ATTACKER));
        _probe("46beae1e", abi.encodeWithSelector(bytes4(0x46beae1e), ATTACKER));
        _probe("43d0fc0b", abi.encodeWithSelector(bytes4(0x43d0fc0b), ATTACKER));
        _probe("5b42eba9", abi.encodeWithSelector(bytes4(0x5b42eba9), ATTACKER));
        _probe("59732b97", abi.encodeWithSelector(bytes4(0x59732b97), uint256(0), uint256(1)));
        _probe("632be1bd", abi.encodeWithSelector(bytes4(0x632be1bd), uint256(0), uint256(1)));
        _probe("6688f078", abi.encodeWithSelector(bytes4(0x6688f078), uint256(0), uint256(1)));
        _probe("db421d7a", abi.encodeWithSelector(bytes4(0xdb421d7a), uint256(0), ATTACKER, uint256(0)));
        _probe("4c9cfd76", abi.encodeWithSelector(bytes4(0x4c9cfd76), uint256(0), ATTACKER));
        _probe("5e57f47c", abi.encodeWithSelector(bytes4(0x5e57f47c), uint256(0), ATTACKER));
        _probe("c3b21a7d", abi.encodeWithSelector(bytes4(0xc3b21a7d), uint256(0), ATTACKER));
        _probe("a421424e", abi.encodeWithSelector(bytes4(0xa421424e), uint256(0), ATTACKER));
        _probe("e751d8f1", abi.encodeWithSelector(bytes4(0xe751d8f1), uint256(0), ATTACKER));
        _probe("f19c1330", abi.encodeWithSelector(bytes4(0xf19c1330), uint256(1)));
        _probe("pauseClaim", abi.encodeWithSignature("pauseClaim()"));
        _probe("pauseWithdraw", abi.encodeWithSignature("pauseWithdraw()"));
        _probe("setVault", abi.encodeWithSignature("setVault(address)", ATTACKER));
        _probe("setB2", abi.encodeWithSignature("setB2(address)", ATTACKER));
        _probe("setB2PerBlock", abi.encodeWithSignature("setB2PerBlock(uint256)", uint256(1)));
        _probe("setStartBlock", abi.encodeWithSignature("setStartBlock(uint256)", uint256(1)));
        _probe("setEndBlock", abi.encodeWithSignature("setEndBlock(uint256)", uint256(999999999)));
        _probe("grantRole", abi.encodeWithSignature("grantRole(bytes32,address)", bytes32(0), ATTACKER));
        _probe("upgradeToAndCall", abi.encodeWithSignature("upgradeToAndCall(address,bytes)", ATTACKER, bytes("")));
        console2.log("== aggregate ==");
        console2.log("staking delta", int256(address(S).balance) - int256(sb0));
        console2.log("vault delta", int256(VAULT_ADDR.balance) - int256(vb0));
        assertEq(address(S).balance, sb0, "E-U: staking balance dropped during probe");
        assertEq(VAULT_ADDR.balance, vb0, "E-U: vault balance dropped during probe");
    }

    function _probe(string memory name, bytes memory data) internal {
        uint256 sb = address(S).balance;
        uint256 vb = VAULT_ADDR.balance;
        vm.prank(ATTACKER);
        (bool ok,) = address(S).call(data);
        console2.log(name, ok);
        console2.log("   stakingDelta", int256(address(S).balance) - int256(sb));
        console2.log("   vaultDelta", int256(VAULT_ADDR.balance) - int256(vb));
    }

    // ------------------------------------------- direct vault call (should be gated)
    function test_vault_functions_permissionless_revert() public {
        vm.prank(ATTACKER);
        (bool ok, bytes memory ret) = address(VAULT).call(
            abi.encodeWithSignature("withdraw(uint256,uint256,address)", uint256(0), uint256(1 ether), ATTACKER)
        );
        console2.log("vault.withdraw ok (expect false)", ok);
        if (!ok) console2.logBytes(ret);
        assertFalse(ok, "vault.withdraw was permissionless");

        vm.prank(ATTACKER);
        (bool ok2, bytes memory ret2) = address(VAULT).call(
            abi.encodeWithSignature("transferToStaking(uint256)", uint256(1 ether))
        );
        console2.log("vault.transferToStaking ok (expect false)", ok2);
        if (!ok2) console2.logBytes(ret2);
        assertFalse(ok2, "vault.transferToStaking was permissionless");
    }

    // ------------------------------------------- B2 reward claim
    function test_claim_path() public {
        address a = address(0xBEEF0006);
        vm.deal(a, 1 ether);
        uint256 b2before = IERC20like(B2).balanceOf(a);
        vm.prank(a);
        (bool okD,) = address(S).call{value: 0.01 ether}(abi.encodeWithSignature("depositBTC()"));
        console2.log("deposit ok", okD);
        vm.prank(a);
        (bool okC, bytes memory retC) =
            address(S).call(abi.encodeWithSignature("claim(uint256)", uint256(0)));
        console2.log("claim ok", okC);
        if (!okC) console2.logBytes(retC);
        console2.log("B2 before", b2before);
        console2.log("B2 after", IERC20like(B2).balanceOf(a));
    }

    function test_staking_balance_and_user_struct() public {
        address a = address(0xBEEF0008);
        vm.deal(a, 1 ether);
        vm.prank(a);
        (bool okD,) = address(S).call{value: 0.01 ether}(abi.encodeWithSignature("depositBTC()"));
        console2.log("deposit ok", okD);
        (bool okS, bytes memory sb) =
            address(S).call(abi.encodeWithSignature("stakingBalance(uint256,address)", uint256(0), a));
        console2.log("stakingBalance ok", okS);
        if (sb.length >= 32) console2.log("stakingBalance", uint256(bytes32(_slice32(sb, 0))));
        (bool okU, bytes memory ub) =
            address(S).call(abi.encodeWithSignature("user(uint256,address)", uint256(0), a));
        console2.log("user ok", okU);
        console2.log("user retlen", ub.length);
        if (ub.length >= 160) {
            console2.log("user.amount", uint256(bytes32(_slice32(ub, 0))));
            console2.log("user.debt", uint256(bytes32(_slice32(ub, 32))));
        }
    }

    function _slice32(bytes memory b, uint256 off) internal pure returns (bytes32 out) {
        assembly { out := mload(add(add(b, 32), off)) }
    }
}

interface IERC20like {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}
