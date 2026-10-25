// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

library ScriptSecurityPolicy {
    error ScriptSecurityPolicy__PublicAddressRequired(string environmentVariable, uint256 encodedLength);
    error ScriptSecurityPolicy__LocalChainOnly(uint256 chainId);
    error ScriptSecurityPolicy__ProductionManifestRequired(string classification);

    function requirePublicAddress(string memory environmentVariable, bytes memory encodedValue) internal pure {
        if (encodedValue.length != 20) {
            revert ScriptSecurityPolicy__PublicAddressRequired(environmentVariable, encodedValue.length);
        }
    }

    function requireLocalChain(uint256 chainId) internal pure {
        if (chainId != 31_337 && chainId != 31_338) revert ScriptSecurityPolicy__LocalChainOnly(chainId);
    }

    function requireProductionManifestForMainnet(uint256 chainId, string memory classification) internal pure {
        if (chainId == 1 && keccak256(bytes(classification)) != keccak256(bytes("PRODUCTION_CANDIDATE"))) {
            revert ScriptSecurityPolicy__ProductionManifestRequired(classification);
        }
    }
}
