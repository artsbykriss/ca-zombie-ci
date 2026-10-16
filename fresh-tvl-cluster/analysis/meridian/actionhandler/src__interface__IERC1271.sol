// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

interface IERC1271 {
    /// @notice Returns whether the signature provided is valid for the provided data.
    /// @param hash Hash of the data to be signed
    /// @param signature Signature byte array associated with _data
    /// @return magicValue The bytes4 magic value 0x1626ba7e if valid
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}
