// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../interfaces/IVersionable.sol";

abstract contract Versionable is IVersionable {
    using SemanticVersion for SemanticVersion.V;
    using SemanticVersion for string;

    // --- STATE ---

    // keccak256(abi.encode(uint256(keccak256("VerioIP.Versionable.Version")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 private constant VERSION = 0xb4c488aef4348cbdb249603edd591c86e8995adea998b15b15d6023e10f23700;

    function _version() internal pure returns (IVersionable.Version storage $) {
        assembly {
            $.slot := VERSION
        }
    }

    // --- GETTERS ---

    /// @inheritdoc IVersionable
    function getVersion() external view returns (string memory) {
        return _version().v.toString();
    }
}
