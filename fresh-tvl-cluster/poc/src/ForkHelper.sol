// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";

/// @title ForkHelper — shared keyless-RPC fork selection for the Z3-H17 fresh-TVL cluster
/// @notice Read-only PoC support. No keyed RPC URLs are ever embedded here; env overrides are
///         allowed (`vm.envOr`) so CI can inject a better endpoint, but the fallbacks are public.
abstract contract ForkHelper is Test {
    // NOTE: `VM_ADDRESS` is inherited from forge-std's Base (via Test); do not redeclare it here
    // (solc error 9097 "Identifier already declared" in inheritors).

    /// @dev Try each URL with a raw cheatcode call; the first URL that forks successfully is
    ///      selected and returned. Reverts if none work.
    function selectFirstWorkingFork(string[] memory urls) internal returns (string memory url) {
        for (uint256 i = 0; i < urls.length; i++) {
            if (bytes(urls[i]).length == 0) continue;
            (bool ok,) = VM_ADDRESS.call(abi.encodeWithSignature("createSelectFork(string)", urls[i]));
            if (ok) return urls[i];
        }
        revert("ForkHelper: no reachable RPC");
    }

    /// @dev Env override (if set and non-empty) else the first working public fallback.
    function forkChain(string memory envKey, string[] memory fallbacks) internal returns (string memory) {
        string memory override_ = vm.envOr(envKey, string(""));
        if (bytes(override_).length != 0) {
            (bool ok,) = VM_ADDRESS.call(abi.encodeWithSignature("createSelectFork(string)", override_));
            if (ok) return override_;
        }
        return selectFirstWorkingFork(fallbacks);
    }
}
