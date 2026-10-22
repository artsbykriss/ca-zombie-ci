// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

/// @notice Fork verification of the Kuru (Monad, chain 143) custody gates.
/// Read-only against a local anvil fork of the PUBLIC, keyless RPC https://rpc.monad.xyz.
/// No mainnet transaction is ever signed or sent.
contract KuruGatesTest is Test {
    // ---- live addresses (Monad mainnet) ----
    address constant ACCOUNT_CORE  = 0x264123a9B96Cc1193944cC25C188f1bD3dFa670e; // EIP-1967 proxy -> 0xb52debad718730ee0a4c12c28e70d346dbcc9e5b
    address constant MARGIN_ACCT   = 0x2A68ba1833cDf93fa9Da1EEbd7F46242aD8E90c5; // EIP-1967 proxy -> 0x351525073afa933720329756716fcf7d741e7ff0
    address constant FORWARDER     = 0x974E61BBa9C4704E8Bcc1923fdC3527B41323FAA; // ERC2771 trusted forwarder (proxy)
    address constant NATIVE        = address(0); // Kuru convention: address(0) == native MON
    address constant ATTACKER      = 0x1111111111111111111111111111111111111111;
    address constant RECIPIENT     = 0x000000000000000000000000000000000000dEaD;
    // Account #26 owner (holds the largest native MON balance in AccountCore at scouting time).
    address constant ACCT26_OWNER  = 0x9DabA38229F593d90f99062bb18ed41f57b16CE8;

    // ---- error selectors (confirmed on-chain) ----
    bytes4 constant UNAUTHORIZED          = 0x82b42900; // Unauthorized()
    bytes4 constant ACCOUNT_NOT_FOUND     = 0xfaba8ebe; // AccountNotFound()
    bytes4 constant INSUFFICIENT_BALANCE  = 0xf4d678b8; // InsufficientBalance()

    // AccountCore function selectors
    bytes4 constant SEL_WITHDRAW_AC       = 0x67f3e6c3; // withdraw(uint40,address,uint256,address)
    bytes4 constant SEL_SET_AUTHORITY     = 0x7a9e5e4b; // setAuthority(address)
    bytes4 constant SEL_SET_WDAUTH        = 0x0cd09628; // setWithdrawalAuthority(address)
    bytes4 constant SEL_CREATE_SUB        = 0xfd8e8fb2; // createSubaccount(address,uint40)
    bytes4 constant SEL_GET_BAL           = 0xcfeb0a00; // getBalance(uint40,address)
    bytes4 constant SEL_ROOT_ID_OF        = 0xcb035e87; // rootAccountIdOf(address)
    // MarginAccount function selectors
    bytes4 constant SEL_WITHDRAW_MA       = 0x00f714ce; // withdraw(uint256,address)
    bytes4 constant SEL_BATCH_MAX         = 0x0f163fa8; // batchWithdrawMaxTokens(address[])
    // KuruForwarder
    bytes4 constant SEL_VERIFY_MARGIN_REQ = 0x10012a15; // verifyMarginAccountRequest(...)

    uint256 forkBlock;

    function setUp() public {
        // The Monad fork is provided by `eth_rpc_url = "https://rpc.monad.xyz"` in foundry.toml
        // (Foundry instantiates the Monad EVM from that RPC for the whole test run). No secret,
        // keyless public endpoint. Read-only.
        forkBlock = block.number;
        emit log_named_uint("fork block", forkBlock);
        emit log_named_uint("chainid", block.chainid);
        require(ACCOUNT_CORE.code.length > 0, "no AccountCore code on fork");
        require(MARGIN_ACCT.code.length > 0, "no MarginAccount code on fork");
    }

    // ---------- helpers ----------
    function _u40(uint256 v) internal pure returns (bytes memory) { return abi.encodePacked(bytes32(v)); }
    function _u256(uint256 v) internal pure returns (bytes memory) { return abi.encodePacked(bytes32(v)); }
    function _addr(address a) internal pure returns (bytes memory) { return abi.encodePacked(bytes32(uint256(uint160(a)))); }

    function _acWithdrawData(uint40 id, address token, uint256 amount, address to) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(SEL_WITHDRAW_AC, id, token, amount, to);
    }

    function _nativeBalanceOf(address who) internal view returns (uint256) {
        (bool ok, bytes memory d) = ACCOUNT_CORE.staticcall(abi.encodeWithSelector(SEL_GET_BAL, uint40(26), NATIVE));
        require(ok, "getBalance failed");
        return abi.decode(d, (uint256));
    }

    // =====================================================================
    // AccountCore
    // =====================================================================

    /// A fresh, unprivileged caller cannot withdraw from ANY account id, incl. a funded one.
    function test_AccountCore_attacker_withdraw_reverts_Unauthorized() public {
        uint256 acBalBefore = ACCOUNT_CORE.balance;
        vm.prank(ATTACKER);
        (bool ok, bytes memory ret) = ACCOUNT_CORE.call(_acWithdrawData(26, NATIVE, 1 ether, ATTACKER));
        assertFalse(ok, "attacker withdraw must revert");
        assertEq(bytes4(ret), UNAUTHORIZED, "expected Unauthorized()");
        // and account id 0 (unregistered) -> AccountNotFound
        vm.prank(ATTACKER);
        (bool ok2, bytes memory ret2) = ACCOUNT_CORE.call(_acWithdrawData(0, NATIVE, 1 ether, ATTACKER));
        assertFalse(ok2);
        assertEq(bytes4(ret2), ACCOUNT_NOT_FOUND, "expected AccountNotFound()");
        assertEq(ACCOUNT_CORE.balance, acBalBefore, "no value moved");
    }

    /// The legitimate owner CAN withdraw (same calldata) -> proves the gate is auth, not a dead path.
    function test_AccountCore_owner_withdraw_succeeds() public {
        uint256 amt = 1 ether;
        if (_nativeBalanceOf(ACCT26_OWNER) == 0) { emit log("acct26 empty on this fork; skipping"); return; }
        uint256 recipientBefore = RECIPIENT.balance;
        vm.prank(ACCT26_OWNER);
        (bool ok, bytes memory ret) = ACCOUNT_CORE.call(_acWithdrawData(26, NATIVE, amt, RECIPIENT));
        assertTrue(ok, string(abi.encodePacked("owner withdraw failed: ", ret)));
        assertEq(RECIPIENT.balance, recipientBefore + amt, "owner withdrawal paid out");
    }

    function test_AccountCore_admin_setters_revert_Unauthorized() public {
        vm.startPrank(ATTACKER);
        (bool ok, bytes memory r) = ACCOUNT_CORE.call(abi.encodeWithSelector(SEL_SET_AUTHORITY, ATTACKER));
        assertFalse(ok); assertEq(bytes4(r), UNAUTHORIZED);
        (ok, r) = ACCOUNT_CORE.call(abi.encodeWithSelector(SEL_SET_WDAUTH, ATTACKER));
        assertFalse(ok); assertEq(bytes4(r), UNAUTHORIZED);
        vm.stopPrank();
    }

    /// createSubaccount is permissionless ONLY for the caller's own root account.
    function test_AccountCore_createSubaccount_forOther_reverts() public {
        vm.prank(ATTACKER);
        (bool ok, bytes memory r) = ACCOUNT_CORE.call(abi.encodeWithSelector(SEL_CREATE_SUB, ACCT26_OWNER, uint40(0)));
        assertFalse(ok, "must not create subaccount for another owner");
        assertEq(bytes4(r), UNAUTHORIZED);
        // own root account is allowed (registers an empty account; moves no value)
        uint256 balBefore = ACCOUNT_CORE.balance;
        vm.prank(ATTACKER);
        (bool ok2,) = ACCOUNT_CORE.call(abi.encodeWithSelector(SEL_CREATE_SUB, ATTACKER, uint40(0)));
        assertTrue(ok2, "self createSubaccount allowed");
        assertEq(ACCOUNT_CORE.balance, balBefore, "createSubaccount moves no value");
    }

    /// fulfillApprovedWithdrawal: only the configured withdrawal authority + owner EIP-712 sig.
    function test_AccountCore_fulfillApprovedWithdrawal_attacker_reverts() public {
        // ApprovedWithdrawal(account,token,recipient,amount,nonce,deadline,authorityEpoch) + bytes sig
        bytes memory tuple = abi.encode(ACCT26_OWNER, NATIVE, ATTACKER, uint256(1 ether), uint256(0), uint256(type(uint256).max), uint64(0));
        bytes memory data = abi.encodePacked(bytes4(0x0a3c83c3), tuple, _u256(7 * 32), _u256(0));
        uint256 balBefore = ACCOUNT_CORE.balance;
        vm.prank(ATTACKER);
        (bool ok,) = ACCOUNT_CORE.call(data);
        assertFalse(ok, "attacker cannot fulfil approved withdrawal");
        assertEq(ACCOUNT_CORE.balance, balBefore);
    }

    // =====================================================================
    // MarginAccount (legacy custody)
    // =====================================================================

    function test_MarginAccount_attacker_withdraw_reverts() public {
        uint256 balBefore = MARGIN_ACCT.balance;
        vm.prank(ATTACKER);
        (bool ok, bytes memory r) = MARGIN_ACCT.call(abi.encodeWithSelector(SEL_WITHDRAW_MA, uint256(1 ether), NATIVE));
        assertFalse(ok, "attacker withdraw must revert");
        assertEq(bytes4(r), INSUFFICIENT_BALANCE, "expected InsufficientBalance()");
        assertEq(MARGIN_ACCT.balance, balBefore);
    }

    function test_MarginAccount_batchWithdrawMaxTokens_is_noop_for_attacker() public {
        address[] memory toks = new address[](1);
        toks[0] = NATIVE;
        uint256 balBefore = MARGIN_ACCT.balance;
        vm.prank(ATTACKER);
        (bool ok,) = MARGIN_ACCT.call(abi.encodeWithSelector(SEL_BATCH_MAX, toks));
        assertTrue(ok, "call itself succeeds");
        assertEq(MARGIN_ACCT.balance, balBefore, "but no value moves for a zero-balance caller");
    }

    function test_MarginAccount_toggleProtocolState_reverts() public {
        vm.prank(ATTACKER);
        (bool ok, bytes memory r) = MARGIN_ACCT.call(abi.encodeWithSelector(bytes4(0xe004f924), false));
        assertFalse(ok); assertEq(bytes4(r), UNAUTHORIZED);
    }

    // =====================================================================
    // ERC-2771 forwarder: cannot be used to impersonate a margin holder
    // =====================================================================

    struct MarginAccountRequest {
        address from;
        address marginAccount;
        uint256 value;
        uint256 nonce;
        uint256 deadline;
        bytes4 selector;
        bytes data;
    }

    function test_Forwarder_forged_request_reverts() public {
        // verifyMarginAccountRequest(MarginAccountRequest,bytes) with an empty signature must revert/false.
        MarginAccountRequest memory req = MarginAccountRequest({
            from: ACCT26_OWNER,
            marginAccount: MARGIN_ACCT,
            value: 0,
            nonce: 0,
            deadline: type(uint256).max,
            selector: SEL_WITHDRAW_MA,
            data: abi.encode(uint256(1 ether), NATIVE)
        });
        vm.prank(ATTACKER);
        (bool ok, bytes memory r) = FORWARDER.call(abi.encodeWithSelector(SEL_VERIFY_MARGIN_REQ, req, hex""));
        // either it reverts (bad sig / deadline) or returns false — never true for a forged request
        if (ok) {
            assertFalse(abi.decode(r, (bool)), "forged request must not verify");
        } else {
            assertGt(r.length, 0, "reverted with reason");
        }
    }

    /// Global: a sweep of unprivileged calls moves zero value.
    function test_global_no_value_moves() public {
        uint256 acBefore = ACCOUNT_CORE.balance;
        uint256 maBefore = MARGIN_ACCT.balance;
        vm.startPrank(ATTACKER);
        ACCOUNT_CORE.call(_acWithdrawData(26, NATIVE, type(uint256).max, ATTACKER));
        ACCOUNT_CORE.call(_acWithdrawData(2, NATIVE, type(uint256).max, ATTACKER));
        ACCOUNT_CORE.call(_acWithdrawData(94, NATIVE, type(uint256).max, ATTACKER));
        ACCOUNT_CORE.call(abi.encodeWithSelector(SEL_SET_AUTHORITY, ATTACKER));
        MARGIN_ACCT.call(abi.encodeWithSelector(SEL_WITHDRAW_MA, type(uint256).max, NATIVE));
        vm.stopPrank();
        assertEq(ACCOUNT_CORE.balance, acBefore, "AccountCore untouched");
        assertEq(MARGIN_ACCT.balance, maBefore, "MarginAccount untouched");
    }
}
