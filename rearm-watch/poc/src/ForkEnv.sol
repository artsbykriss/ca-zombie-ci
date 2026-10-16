// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

// ForkEnv — resolves an RPC URL from the environment, treating SET-BUT-EMPTY as unset.
// CI injects e.g. POLYGON_RPC_URL="" when the secret is missing; vm.envOr would return the empty
// string and vm.createSelectFork would fail with "invalid rpc url". This helper falls back instead.
abstract contract ForkEnv is Test {
    function _rpc(string memory name, string memory fallback_) internal view returns (string memory) {
        string memory v = vm.envOr(name, string(""));
        return bytes(v).length == 0 ? fallback_ : v;
    }
}
