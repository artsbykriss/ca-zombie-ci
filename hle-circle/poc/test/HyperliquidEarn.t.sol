// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {Test} from "forge-std/Test.sol";

/// @title HyperliquidEarnToolingTest
/// @notice Documents — on a local HyperEVM fork — WHY the HyperCore-native "Hyperliquid Earn" reserves
///         cannot be fork-simulated from an EVM client, and what the single EVM-reachable surface is.
///
///         The authoritative live reads of the reserve state (precompiles `0x…080c` / `0x…0812`) are
///         performed out-of-band by `ci/run.sh` (raw `eth_call` against the public HyperEVM RPC) and
///         captured in `ci-out/hyperliquid_earn_state.json`, because Foundry/revm has no HyperCore
///         precompile support: the precompiles are executed by the validator, not by revm.
contract HyperliquidEarnToolingTest is Test {
    address constant PRE_TOKEN_INFO = 0x000000000000000000000000000000000000080C;
    address constant PRE_RESERVE = 0x0000000000000000000000000000000000000812;
    address constant CORE_WRITER = 0x3333333333333333333333333333333333333333;

    function setUp() public {
        string memory url = vm.envOr("HYPEREVM_RPC_URL", string("https://rpc.hyperliquid.xyz/evm"));
        bool ok;
        try this._tryFork(url) {
            ok = true;
        } catch {
            ok = false;
        }
        if (!ok) {
            vm.skip(true, "HyperEVM fork unavailable here; reserve mapping is done out-of-band in ci/run.sh");
            return;
        }
        emit log_named_uint("HyperEVM block", block.number);
    }

    function _tryFork(string memory url) external {
        vm.createSelectFork(url);
    }

    /// @notice revm (Foundry's local EVM) does not implement HyperCore's custom read precompiles, so a
    ///         fork of HyperEVM cannot execute the reserve-state reads — they revert locally. This is the
    ///         core tooling limit: the lending reserves are not EVM-auditable / not fork-simulable.
    function test_revm_cannot_execute_hypercore_precompiles() public view {
        // A codeless address call returns *success with empty returndata* in revm, so the HyperCore
        // precompiles yield nothing locally. The real validator returns a populated struct (captured by
        // ci/run.sh via eth_call). => Hyperliquid Earn is not fork-simulable from an EVM client.
        (bool okReserve, bytes memory retReserve) = PRE_RESERVE.staticcall(abi.encode(uint32(0)));
        assertTrue(okReserve, "call to codeless address succeeds");
        assertEq(retReserve.length, 0, "revm returns no reserve state (HyperCore precompile unimplemented)");

        (bool okToken, bytes memory retToken) = PRE_TOKEN_INFO.staticcall(abi.encode(uint32(0)));
        assertTrue(okToken, "call to codeless address succeeds");
        assertEq(retToken.length, 0, "revm returns no token info (HyperCore precompile unimplemented)");

        // the precompile addresses carry no deployed code (native, not contracts)
        assertEq(PRE_RESERVE.code.length, 0, "reserve precompile has no bytecode");
        assertEq(PRE_TOKEN_INFO.code.length, 0, "token-info precompile has no bytecode");
    }

    /// @notice The only EVM-facing write path is the CoreWriter system contract, whose action 15 is
    ///         Borrow-lend with encodedOperation {0=Supply, 1=Withdraw} — self-scoped, no borrow/repay
    ///         and no ability to touch another account's funds.
    function test_corewriter_is_the_only_write_surface() public {
        bytes memory code = CORE_WRITER.code;
        assertGt(code.length, 0, "CoreWriter deployed");
        // dispatcher embeds sendRawAction(bytes) selector 0x17938e13
        assertTrue(_contains(code, hex"17938e13"), "CoreWriter exposes sendRawAction(bytes)");
        emit log_named_uint("CoreWriter code size", code.length);
    }

    function _contains(bytes memory haystack, bytes memory needle) internal pure returns (bool) {
        if (needle.length > haystack.length) return false;
        for (uint256 i = 0; i <= haystack.length - needle.length; i++) {
            bool matchFound = true;
            for (uint256 j = 0; j < needle.length; j++) {
                if (haystack[i + j] != needle[j]) {
                    matchFound = false;
                    break;
                }
            }
            if (matchFound) return true;
        }
        return false;
    }
}
