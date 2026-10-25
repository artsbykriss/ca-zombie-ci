pragma solidity ^0.8.0;

import { SignatureChecker } from "@openzeppelin/contracts-5.3.0/utils/cryptography/SignatureChecker.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts that use EIP-712 signatures.
 * It provides functionality to initialize the EIP-712 domain separator and verify signatures.
 */
abstract contract SignatureModule {
    /// @notice Error thrown when a signature is invalid
    error InvalidSignature();

    /// @dev Added supportive function to check if the signature is valid
    function _requireIsValidSignatureNow(address signer, bytes32 structHash, bytes memory signature) internal view {
        if (
            !SignatureChecker.isValidSignatureNow({
                signer: signer,
                hash: __hashTypedDataV4({ structHash: structHash }),
                signature: signature
            })
        ) revert InvalidSignature();
    }

    function __hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32);
}
