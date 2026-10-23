// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

/// @notice Minimal mock of the Hedera WHBAR contract: `token()` returns the wrapped-HBAR HTS token.
contract MockWHBAR {
    address public tokenAddr;
    constructor(address t) {
        tokenAddr = t;
    }
    function token() external view returns (address) {
        return tokenAddr;
    }
}
