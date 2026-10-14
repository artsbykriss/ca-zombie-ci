// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IERC20Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { IERC20Permit } from "./IERC20Permit.sol";

/// @title IERC20Witness Interface
/// @notice Interface for ERC20 tokens with witness-based permit functionality
/// @dev Extends standard ERC20 with permitWitness functions that include additional validation data
interface IERC20Witness is IERC20Permit, IERC20Metadata, IERC20Errors {

    /*//////////////////////////////////////////////////////////////
                          WITNESS-SPECIFIC ERRORS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Thrown when an invalid witness value is provided
     * @dev The witness data failed validation checks
     */
    error ERC20InvalidWitness();

    /**
     * @notice Thrown when attempting to call the contract itself
     * @dev Self-calls are not permitted for security reasons
     */
    error ERC20InvalidCallTarget();

    /**
     * @notice Thrown when invalid call data is provided
     * @dev The call data format or content is malformed
     */
    error ERC20InvalidCallData();

    /**
     * @notice Thrown when an external call fails during witness operations
     * @dev The target contract call returned failure or reverted
     */
    error ERC20CallFailed();

    struct ContractCall {
        address target;
        string method;
        uint256 nativeValue;
        bytes params;
    }

    /*//////////////////////////////////////////////////////////////
                      PERMIT WITNESS LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the permit witness typehash for EIP-712 signature encoding
     * @dev Used for permitWitness function signature validation
     * @return The keccak256 hash of the permit witness type string
     */
    function PERMIT_WITNESS_TYPEHASH() external view returns (bytes32);

    /**
     * @notice Returns the base permit witness type string for EIP-712 structured data
     * @dev Used as a prefix to construct full type strings with witness data
     * @return The base permit witness type string stub
     */
    function PERMIT_WITNESS_TYPESTRING_STAB() external view returns (string memory);

    /**
     * @notice Returns the contract call witness type string completion
     * @dev Appended to PERMIT_WITNESS_TYPESTRING_STAB to form complete EIP-712 type string
     * @return The contract call type string completion
     */
    function WITNESS_CALL_TYPESTRING() external view returns (string memory);

    /**
     * @notice Returns the contract call typehash for EIP-712 signature encoding
     * @dev Used for ContractCall struct hashing in witness validation
     * @return The keccak256 hash of the ContractCall type string
     */
    function WITNESS_CALL_TYPEHASH() external view returns (bytes32);

    /**
     * @notice Returns the witness type identifier for transfer operations
     * @dev Used to validate witness data in transfer contexts
     * @return The bytes32 identifier for transfer witness operations
     */
    function TRANSFER_WITNESS() external view returns (bytes32);

    /**
     * @notice Sets allowance using signature with additional witness validation
     * @dev Extends standard permit functionality with witness data for enhanced security
     * @param owner The owner of the tokens
     * @param spender The address authorized to spend the tokens
     * @param value The amount of tokens to authorize for spending
     * @param deadline The timestamp at which the permit expires
     * @param witness Additional validation data to prevent certain attack vectors
     * @param v The recovery parameter of the signature (27 or 28)
     * @param r The first 32 bytes of the signature
     * @param s The second 32 bytes of the signature
     */
    function permitWitness(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        bytes32 witness,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Sets allowance using signature with custom witness type string for free-form witness data
     * @dev Extends permitWitness with witnessTypeString parameter to support various witness structures
     * @param owner The owner of the tokens
     * @param spender The address authorized to spend the tokens
     * @param value The amount of tokens to authorize for spending
     * @param deadline The timestamp at which the permit expires
     * @param witness Additional validation data hash to prevent certain attack vectors
     * @param witnessTypeString The EIP-712 type string for the witness data structure
     * @param v The recovery parameter of the signature (27 or 28)
     * @param r The first 32 bytes of the signature
     * @param s The second 32 bytes of the signature
     */
    function permitWitness(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        bytes32 witness,
        string calldata witnessTypeString,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Permits and executes a direct transfer using signature authorization
     * @dev Combines permit and transferFrom into a single operation with witness validation
     * @param owner The owner of the tokens to transfer
     * @param spender The recipient address for the transfer
     * @param value The amount of tokens to transfer
     * @param deadline The timestamp at which the permit expires
     * @param v The recovery parameter of the signature (27 or 28)
     * @param r The first 32 bytes of the signature
     * @param s The second 32 bytes of the signature
     * @return success Whether the transfer operation was successful
     */
    function permitTransferFrom(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool success);

    /**
     * @notice Permits token allowance and executes an external call in one transaction
     * @dev Combines permit functionality with external contract interaction using witness validation
     * @param owner The owner of the tokens
     * @param spender The address authorized to spend the tokens
     * @param value The amount of tokens to authorize for spending
     * @param deadline The timestamp at which the permit expires
     * @param call ContractCall struct containing target address, method signature, and parameters
     * @param v The recovery parameter of the signature (27 or 28)
     * @param r The first 32 bytes of the signature
     * @param s The second 32 bytes of the signature
     * @return returnData The return data from the executed external call
     */
    function permitWitnessCall(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        ContractCall calldata call,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable returns (bytes memory returnData);

}
