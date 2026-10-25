// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";

interface IB2Stake {
    function submit() external payable;
    function withdraw() external;
    function requestWithdrawals(uint256 amount) external;
    function poolClaim() external;
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function owner() external view returns (address);
}

/// @notice Probe the third Hive/B2 contract that custodies native BTC:
///         0x796e...cCAac2 (impl 0x0619e227...) holding 139.47 BTC.
contract HiveB2Test is Test {
    address constant B2STAKE = 0x796e4D53067FF374B89b2Ac101ce0c1f72ccaAc2;
    IB2Stake constant B = IB2Stake(0x796e4D53067FF374B89b2Ac101ce0c1f72ccaAc2);
    address constant P1 = 0xA3eb53ddA8181Ae48FDfE16Ed3d7F37859F7f97b; // impl 0xedd2be4a
    address constant P2 = 0x8208bd314b6d730845E0F1427bC5a150EdE9baE7; // impl 0xeada73c2
    address constant B2TOKEN = 0x783c3f003f172c6Ac5AC700218a357d2D66Ee2a2;
    address constant ATTACKER = address(0xA11CE);

    function setUp() public {
        string memory rpc = vm.envOr("BSQUARED_RPC_URL", string("https://rpc.bsquared.network"));
        vm.createSelectFork(rpc);
    }

    function test_b2stake_state() public {
        console2.log("B2STAKE bal (wei)", B2STAKE.balance);
        console2.log("B2STAKE totalSupply", B.totalSupply());
        console2.log("B2STAKE owner", B.owner());
        console2.log("P1 bal", P1.balance);
        console2.log("P2 bal", P2.balance);
        (bool okP1, bytes memory r1) = P1.staticcall(abi.encodeWithSignature("totalSupply()"));
        console2.log("P1 totalSupply ok", okP1);
        if (okP1 && r1.length >= 32) console2.log("P1 totalSupply", uint256(bytes32(r1)));
        (bool okP2, bytes memory r2) = P2.staticcall(abi.encodeWithSignature("totalSupply()"));
        console2.log("P2 totalSupply ok", okP2);
        if (okP2 && r2.length >= 32) console2.log("P2 totalSupply", uint256(bytes32(r2)));
        console2.log("B2 bal of B2STAKE", IERC20like(B2TOKEN).balanceOf(B2STAKE));
    }

    function test_probe_b2stake_permissionless() public {
        uint256 b0 = B2STAKE.balance;
        // 1. withdraw() with no request
        vm.prank(ATTACKER);
        (bool ok1,) = B2STAKE.call(abi.encodeWithSignature("withdraw()"));
        console2.log("withdraw() ok (expect false)", ok1);
        console2.log("   balDelta", int256(B2STAKE.balance) - int256(b0));

        // 2. requestWithdrawals(huge) with no balance
        vm.prank(ATTACKER);
        (bool ok2,) = B2STAKE.call(abi.encodeWithSignature("requestWithdrawals(uint256)", uint256(100 ether)));
        console2.log("requestWithdrawals(100e18) ok (expect false)", ok2);
        console2.log("   balDelta", int256(B2STAKE.balance) - int256(b0));

        // 3. poolClaim()
        vm.prank(ATTACKER);
        (bool ok3,) = B2STAKE.call(abi.encodeWithSignature("poolClaim()"));
        console2.log("poolClaim() ok", ok3);
        console2.log("   balDelta", int256(B2STAKE.balance) - int256(b0));

        // 4. owner-only
        vm.prank(ATTACKER);
        (bool ok4,) = B2STAKE.call(abi.encodeWithSignature("uploadMerkleRoot(bytes32)", bytes32(uint256(1))));
        console2.log("uploadMerkleRoot ok (expect false)", ok4);
        vm.prank(ATTACKER);
        (bool ok5,) = B2STAKE.call(
            abi.encodeWithSignature("upgradeToAndCall(address,bytes)", ATTACKER, bytes(""))
        );
        console2.log("upgradeToAndCall ok (expect false)", ok5);
        vm.prank(ATTACKER);
        (bool ok6,) = B2STAKE.call(abi.encodeWithSignature("transferOwnership(address)", ATTACKER));
        console2.log("transferOwnership ok (expect false)", ok6);

        console2.log("aggregate balDelta", int256(B2STAKE.balance) - int256(b0));
        assertEq(B2STAKE.balance, b0, "E-U: B2STAKE native balance dropped");
        assertEq(ATTACKER.balance, 0, "E-U: attacker gained native BTC");
    }

    // attacker deposits then tries to withdraw more than deposited
    function test_b2stake_deposit_withdraw_bounded() public {
        vm.deal(ATTACKER, 1 ether);
        uint256 start = ATTACKER.balance;
        vm.prank(ATTACKER);
        (bool okD,) = B2STAKE.call{value: 0.01 ether}(abi.encodeWithSignature("submit()"));
        console2.log("submit ok", okD);
        console2.log("attacker bal after submit", ATTACKER.balance);
        // immediate withdraw (no request / not matured)
        vm.prank(ATTACKER);
        (bool okW,) = B2STAKE.call(abi.encodeWithSignature("withdraw()"));
        console2.log("immediate withdraw ok", okW);
        console2.log("attacker bal after withdraw", ATTACKER.balance);
        assertLe(ATTACKER.balance, start, "E-U: b2stake profit");
    }
}

interface IERC20like {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}
