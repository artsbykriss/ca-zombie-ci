// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {IPrintrLike, ITreasuryLike, IERC20Like} from "../src/PrintrInterfaces.sol";

/// @title Printr live-state PoC (read-only; fork only)
/// @notice Proves, on an Ethereum mainnet fork at the latest block, exactly which
///         unprivileged paths are open vs closed. No mainnet transactions.
contract PrintrLiveTest is Test {
    // --- live addresses (Ethereum mainnet, verified 2026-10-14) ---
    address constant PRINT = 0xb77726291b125515D0A7AfFeeA2b04f2FF243172; // PrintrCore proxy
    address constant TREASURY = 0x8c843012B347664caf84B907053754208a933FeE; // current treasury
    address constant LEGACY_TREASURY = 0xdE420c835240216198bf4fd1eDa28D7EAD2A1549;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant LZ_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    address constant CH2 = 0x69B20D727573A47a47104388AF8B3772C69Dc384; // LZ_FAST channel
    address constant TELEPORT = 0xC5e0C0ecb27d800bB4068cdFa7219aF3dD33f8bd;
    // hardcoded Solana LZ peer checked by receiveFromChannel (LZ_FAST)
    bytes32 constant SOLANA_PEER = 0x27289E1d3B5C3AF5e16600167C7463fcaA125509fc61e2de08491aece7993b5f;
    // live telecoins with active curves (from TokenTrade logs)
    address constant TOK_A = 0xaE0f1B6a369608f5dd05E968f6C78Bcd3eb77777; // PrintrTelecoin (verified source)
    address constant TOK_B = 0x8aE65D8ab3F0B29D1768E693a753f6D2A4f60226;
    address constant TOK_C = 0xB685dAB7795F0b73Ef9bc343248BcB2C17b77777;

    address constant ATTACKER = address(0xA11CE);
    address constant FUND = 0x65f7A87C6e055f55EdD81Fc01eEE506F66ACD4AB; // growth/buyback/team/staking fund

    IPrintrLike printr = IPrintrLike(PRINT);
    ITreasuryLike treasury = ITreasuryLike(TREASURY);

    string outjson;
    bool hasFork;

    function setUp() public {
        string memory rpc = vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("")));
        if (bytes(rpc).length == 0) {
            rpc = "https://ethereum-rpc.publicnode.com";
        }
        try vm.createSelectFork(rpc) {
            hasFork = true;
        } catch {
            hasFork = false;
        }
        vm.deal(ATTACKER, 10 ether);
    }

    // ---------------------------------------------------------------
    // 1. Treasury: only the core can withdraw
    // ---------------------------------------------------------------
    function test_treasury_access_control() public {
        require(hasFork, "no fork");
        console2.log("fork block:", block.number);
        console2.log("treasury.printr():", treasury.printr());
        assertEq(treasury.printr(), PRINT, "treasury is bound to core");

        uint256 wethBefore = IERC20Like(WETH).balanceOf(TREASURY);
        console2.log("treasury WETH balance:", wethBefore);
        assertGt(wethBefore, 0, "treasury holds WETH");

        // attacker call -> WrongAccess()
        vm.prank(ATTACKER);
        (bool okA, bytes memory retA) = TREASURY.call(
            abi.encodeWithSelector(ITreasuryLike.withdraw.selector, WETH, ATTACKER, 1)
        );
        assertFalse(okA, "attacker withdraw must revert");
        assertEq(bytes4(retA), bytes4(keccak256("WrongAccess()")), "WrongAccess expected");
        console2.log("attacker treasury.withdraw reverted WrongAccess: OK");

        // core call -> succeeds
        vm.prank(PRINT);
        (bool okC,) = TREASURY.call(
            abi.encodeWithSelector(ITreasuryLike.withdraw.selector, WETH, PRINT, 1)
        );
        assertTrue(okC, "core withdraw must succeed");
        console2.log("core treasury.withdraw succeeds: OK");

        // legacy treasury: same gate
        vm.prank(ATTACKER);
        (bool okL, bytes memory retL) = LEGACY_TREASURY.call(
            abi.encodeWithSelector(ITreasuryLike.withdraw.selector, WETH, ATTACKER, 1)
        );
        assertFalse(okL, "attacker legacy withdraw must revert");
        assertEq(bytes4(retL), bytes4(keccak256("WrongAccess()")));
        console2.log("attacker legacy-treasury.withdraw reverted WrongAccess: OK");
        outjson = "treasury_gate=closed\n";
    }

    // ---------------------------------------------------------------
    // 2. Admin surfaces: attacker reverts
    // ---------------------------------------------------------------
    function test_admin_functions_closed() public {
        require(hasFork, "no fork");
        bytes4 unAuth = bytes4(keccak256("OwnableUnauthorizedAccount(address)"));
        address owner = printr.owner();
        console2.log("owner:", owner);

        _expectUnauth(PRINT, abi.encodeWithSignature("pause()"), unAuth, "pause");
        _expectUnauth(PRINT, abi.encodeWithSignature("unpause()"), unAuth, "unpause");
        _expectUnauth(PRINT, abi.encodeWithSignature("transferOwnership(address)", ATTACKER), unAuth, "transferOwnership");
        _expectUnauth(PRINT, abi.encodeWithSignature("renounceOwnership()"), unAuth, "renounceOwnership");
        _expectUnauth(
            PRINT,
            abi.encodeWithSignature("upgradeToAndCall(address,bytes)", ATTACKER, bytes("")),
            unAuth,
            "upgradeToAndCall"
        );
        uint8[] memory empty = new uint8[](0);
        _expectUnauth(
            PRINT,
            abi.encodeWithSignature("updateGlobalProtocols(uint8[],uint8[])", empty, empty),
            unAuth,
            "updateGlobalProtocols"
        );
        console2.log("all admin surfaces owner-gated: OK");
    }

    function _expectUnauth(address target, bytes memory data, bytes4 want, string memory label) internal {
        vm.prank(ATTACKER);
        (bool ok, bytes memory ret) = target.call(data);
        if (ok) {
            console2.log(string.concat(label, ": UNEXPECTED SUCCESS"));
        } else {
            console2.log(string.concat(label, ": reverted as expected"), bytes4(ret) == want ? "(OwnableUnauthorizedAccount)" : "(other)");
        }
        assertFalse(ok, "admin call must not succeed for attacker");
    }

    // ---------------------------------------------------------------
    // 3. receiveFromChannel: channel + protocol + Solana peer gate
    // ---------------------------------------------------------------
    function test_receiveFromChannel_gates() public {
        require(hasFork, "no fork");
        bytes4 unauthCaller = bytes4(keccak256("UnauthorizedCaller()"));
        bytes4 invalidLen = bytes4(keccak256("InvalidPayloadLength()"));

        // (a) attacker directly
        vm.prank(ATTACKER);
        (bool okA, bytes memory rA) = PRINT.call(
            abi.encodeWithSelector(bytes4(0x08e56f01), uint8(2), SOLANA_PEER, bytes(""))
        );
        assertFalse(okA);
        assertEq(bytes4(rA), unauthCaller, "direct attacker must be UnauthorizedCaller");
        console2.log("direct attacker call: UnauthorizedCaller OK");

        // (b) real channel, wrong peer
        vm.prank(CH2);
        (bool okB, bytes memory rB) = PRINT.call(
            abi.encodeWithSelector(bytes4(0x08e56f01), uint8(2), bytes32(uint256(0xdead)), bytes(""))
        );
        assertFalse(okB);
        assertEq(bytes4(rB), unauthCaller, "wrong peer must be UnauthorizedCaller");
        console2.log("channel + wrong peer: UnauthorizedCaller OK");

        // (c) real channel, correct Solana peer -> passes auth, fails payload parse
        vm.prank(CH2);
        (bool okC, bytes memory rC) = PRINT.call(
            abi.encodeWithSelector(bytes4(0x08e56f01), uint8(2), SOLANA_PEER, bytes(""))
        );
        assertFalse(okC);
        assertEq(bytes4(rC), invalidLen, "correct peer must reach payload parsing");
        console2.log("channel + correct peer: reaches parser (InvalidPayloadLength) OK");
    }

    // ---------------------------------------------------------------
    // 4. Trading round trip: attacker cannot profit
    // ---------------------------------------------------------------
    function test_buy_sell_roundtrip_no_profit() public {
        require(hasFork, "no fork");
        address[3] memory toks = [TOK_A, TOK_B, TOK_C];
        uint256 sellsOk;
        for (uint256 i = 0; i < toks.length; i++) {
            (bool active, uint256 reserve) = _curveActive(toks[i]);
            if (!active || reserve == 0) {
                console2.log("token skipped (no active curve):", toks[i]);
                continue;
            }
            uint256 spend = 0.01 ether;
            uint256 before = ATTACKER.balance;
            vm.startPrank(ATTACKER);
            IERC20Like(toks[i]).approve(PRINT, type(uint256).max);
            (bool ok1,) = PRINT.call{value: spend}(
                abi.encodeWithSignature("spend(address,address,uint256,uint256)", toks[i], ATTACKER, spend, uint256(0))
            );
            uint256 tokBal = IERC20Like(toks[i]).balanceOf(ATTACKER);
            (bool ok2,) = PRINT.call(
                abi.encodeWithSignature("sell(address,address,uint256,uint256)", toks[i], ATTACKER, tokBal, uint256(0))
            );
            vm.stopPrank();
            uint256 afterBal = ATTACKER.balance;
            console2.log("token:", toks[i]);
            console2.log("  spend ok / sell ok:", ok1, ok2);
            console2.log("  bought tokens:", tokBal);
            console2.log("  ETH before / after:", before, afterBal);
            if (ok1 && ok2) {
                sellsOk++;
                assertLt(afterBal, before, "round trip must lose money");
                console2.log("  net loss (wei):", before - afterBal);
            }
        }
        assertGt(sellsOk, 0, "at least one live holder sell path");
        console2.log("holder sells that completed:", sellsOk);
    }

    function _curveActive(address token) internal view returns (bool, uint256) {
        (bool ok, bytes memory ret) = PRINT.staticcall(abi.encodeWithSelector(bytes4(0x61f029fb), token));
        if (!ok || ret.length < 192) return (false, 0);
        // CurveInfo: (address basePair, uint16 totalCurves, uint256 maxTokenSupply, uint256 virtualReserve, uint256 reserve, uint256 completionThreshold)
        uint256 reserve;
        uint256 threshold;
        assembly {
            reserve := mload(add(ret, 0xa0)) // word 4 (0x20 + 4*0x20)
            threshold := mload(add(ret, 0xc0)) // word 5 (0x20 + 5*0x20)
        }
        return (threshold != 0 && reserve > 0, reserve);
    }

    // ---------------------------------------------------------------
    // 5. collectProtocolFees: permissionless, but not attacker-payable
    // ---------------------------------------------------------------
    function test_collectProtocolFees_not_profitable() public {
        require(hasFork, "no fork");
        address[3] memory toks = [TOK_A, TOK_B, TOK_C];
        for (uint256 i = 0; i < toks.length; i++) {
            (bool okQ, bytes memory retQ) = PRINT.call(
                abi.encodeWithSelector(bytes4(0x80de8806), toks[i])
            );
            uint256 total;
            if (okQ && retQ.length >= 64) {
                // FeeDistribution: (totalAmount, growth, buyback, team, creator, creatorAddress)
                (total,,,,,) = abi.decode(retQ, (uint256, uint256, uint256, uint256, uint256, address));
            }
            console2.log("token:", toks[i], "accumulated fees:", total);
            if (!okQ || total == 0) continue;

            uint256 aEth = ATTACKER.balance;
            uint256 aWeth = IERC20Like(WETH).balanceOf(ATTACKER);
            uint256 aTok = IERC20Like(toks[i]).balanceOf(ATTACKER);
            vm.prank(ATTACKER);
            (bool okC,) = PRINT.call(abi.encodeWithSelector(bytes4(0x2a54db01), toks[i]));
            uint256 aEth2 = ATTACKER.balance;
            uint256 aWeth2 = IERC20Like(WETH).balanceOf(ATTACKER);
            uint256 aTok2 = IERC20Like(toks[i]).balanceOf(ATTACKER);
            console2.log("  collectProtocolFees(attacker) ok:", okC);
            console2.log("  attacker ETH delta:", int256(aEth2) - int256(aEth));
            console2.log("  attacker WETH delta:", int256(aWeth2) - int256(aWeth));
            console2.log("  attacker TOKEN delta:", int256(aTok2) - int256(aTok));
            assertLe(aEth2, aEth, "attacker ETH must not increase");
            assertLe(aWeth2, aWeth, "attacker WETH must not increase");
            assertLe(aTok2, aTok, "attacker token must not increase");
        }
    }
}
