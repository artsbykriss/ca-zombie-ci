// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../interfaces/telecoin/IERC20Witness.sol";

import "./ERC20.sol";

/**
 * @notice ERC20 extension with witness-based permit functionality for enhanced security
 * @dev Extends ERC20 with permitWitness functions that include additional validation data
 */
contract ERC20Witness is IERC20Witness, ERC20 {

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 CONSTANTS
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_WITNESS_TYPEHASH = keccak256(
        "PermitWitness(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline,bytes32 witness)"
    );

    string public constant PERMIT_WITNESS_TYPESTRING_STAB =
        "PermitWitness(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline,";

    string public constant WITNESS_CALL_TYPESTRING =
        "ContractCall call)ContractCall(address target,string method,uint256 nativeValue,bytes params)";

    bytes32 public constant WITNESS_CALL_TYPEHASH =
        keccak256("ContractCall(address target,string method,uint256 nativeValue,bytes params)");

    // Witness type prefixes to prevent signature collision between different witness functions
    bytes32 public constant TRANSFER_WITNESS = bytes32(0);

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the ERC20Witness token with metadata and witness-based permit functionality
     * @dev Calls parent ERC20 constructor to set up basic token functionality with added witness capabilities
     * @param _name The human-readable name of the token (e.g. "My Token")
     * @param _symbol The token symbol used on exchanges (e.g. "MTK")
     * @param _decimals Number of decimal places for token amounts (typically 18 for most ERC20 tokens)
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol, _decimals) { }

    /*//////////////////////////////////////////////////////////////
                          PERMIT WITNESS LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets allowance via signature with additional witness data for enhanced security
     * @dev Extends EIP-2612 permit with witness parameter to prevent signature replay across different contexts
     * @param owner The address that owns the tokens and is granting the allowance
     * @param spender The address that will be allowed to spend the tokens
     * @param value The amount of tokens to approve for spending (in token's decimal units)
     * @param deadline The timestamp after which the permit signature is no longer valid
     * @param witness Additional context data hash to prevent cross-context signature replay
     * @param v The recovery identifier of the signature (27 or 28)
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
    ) public virtual {
        if (witness == TRANSFER_WITNESS) {
            revert ERC20InvalidWitness();
        }

        _validatePermitWitness(owner, spender, value, deadline, witness, v, r, s);

        allowance[owner][spender] = value;

        emit Approval(owner, spender, value);
    }

    /**
     * @notice Sets allowance via signature with additional witness data for enhanced security
     * @dev Extends EIP-2612 permit with witness parameter to prevent signature replay across different contexts
     * @param owner The address that owns the tokens and is granting the allowance
     * @param spender The address that will be allowed to spend the tokens
     * @param value The amount of tokens to approve for spending (in token's decimal units)
     * @param deadline The timestamp after which the permit signature is no longer valid
     * @param witness Additional context data hash to prevent cross-context signature replay
     * @param v The recovery identifier of the signature (27 or 28)
     * @param r The first 32 bytes of the signature
     * @param s The second 32 bytes of the signature
     */
    function permitWitness(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        bytes32 witness,
        string memory witnessTypeString,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        if (witness == TRANSFER_WITNESS) {
            revert ERC20InvalidWitness();
        }

        _validatePermitWitness(owner, spender, value, deadline, witness, witnessTypeString, v, r, s);

        allowance[owner][spender] = value;

        emit Approval(owner, spender, value);
    }

    /**
     * @notice Executes a direct transfer via signature without setting persistent allowance
     * @dev Uses witness-based permit with TRANSFER_WITNESS to authorize a one-time transfer
     * @param owner The address that owns the tokens and is authorizing the transfer
     * @param spender The address that will receive the tokens (typically msg.sender)
     * @param value The amount of tokens to transfer (in token's decimal units)
     * @param deadline The timestamp after which the permit signature is no longer valid
     * @param v The recovery identifier of the signature (27 or 28)
     * @param r The first 32 bytes of the signature
     * @param s The second 32 bytes of the signature
     * @return Always returns true to indicate successful transfer
     */
    function permitTransferFrom(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual returns (bool) {
        // Use permitWitness to set the allowance
        _validatePermitWitness(owner, spender, value, deadline, TRANSFER_WITNESS, v, r, s);

        // Execute the transfer
        _update(owner, spender, value);
        return true;
    }

    /**
     * @notice Executes an external contract call with permit-based authorization
     * @dev Sets allowance via witness permit then executes arbitrary call. Witness is derived from call data to
     * prevent replay
     * @param owner The address that owns the tokens and is authorizing the call
     * @param spender The address that will be allowed to spend the tokens (typically the target contract)
     * @param value The amount of tokens to approve for spending (in token's decimal units)
     * @param deadline The timestamp after which the permit signature is no longer valid
     * @param call ContractCall struct containing target, method, and encoded params with owner as first param
     * @param v The recovery identifier of the signature (27 or 28)
     * @param r The first 32 bytes of the signature
     * @param s The second 32 bytes of the signature
     * @return The return data from the external contract call
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
    ) public payable returns (bytes memory) {
        // Validate inputs before expensive signature operations
        if (call.target == address(0) || call.target == address(this)) {
            revert ERC20InvalidCallTarget();
        }

        // Validate method is non-empty
        if (bytes(call.method).length == 0) {
            revert ERC20InvalidCallData();
        }

        // CRITICAL: Validate owner is first parameter (32 bytes) in call.params
        if (call.params.length < 32 || bytes32(call.params[0:32]) != bytes32(uint256(uint160(owner)))) {
            revert ERC20InvalidCallData();
        }

        // Validate msg.value is sufficient for the native value transfer
        if (msg.value < call.nativeValue) {
            revert ERC20InvalidCallData();
        }

        bytes32 witness = keccak256(
            abi.encode(
                WITNESS_CALL_TYPEHASH,
                call.target,
                keccak256(bytes(call.method)),
                call.nativeValue,
                keccak256(call.params)
            )
        );

        // Use permitWitness to set the allowance
        permitWitness(owner, spender, value, deadline, witness, WITNESS_CALL_TYPESTRING, v, r, s);

        // Building the call data
        bytes memory callData = abi.encodePacked(bytes4(keccak256(bytes(call.method))), call.params);

        // Execute the external call
        (bool success, bytes memory returnData) = call.target.call{ value: msg.value }(callData);
        if (!success) {
            // Forward the revert reason if available
            if (returnData.length > 0) {
                assembly {
                    let returnDataSize := mload(returnData)
                    revert(add(32, returnData), returnDataSize)
                }
            } else {
                revert ERC20CallFailed();
            }
        }

        return returnData;
    }

    /*//////////////////////////////////////////////////////////////
                   PERMIT WITNESS INTERNAL VALIDATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Internal function to validate witness-based permit signatures using default typeHash
     * @dev Validates EIP-712 signature for witness permit with PERMIT_WITNESS_TYPEHASH
     * @param owner The expected owner address that should have signed the permit
     * @param spender The spender address included in the signed message
     * @param value The token amount included in the signed message (in token's decimal units)
     * @param deadline The deadline timestamp included in the signed message
     * @param witness The witness data hash included in the signed message
     * @param v The recovery identifier of the signature (27 or 28)
     * @param r The first 32 bytes of the signature
     * @param s The second 32 bytes of the signature
     */
    function _validatePermitWitness(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        bytes32 witness,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        _validatePermitWitnessSignature(owner, spender, value, deadline, witness, PERMIT_WITNESS_TYPEHASH, v, r, s);
    }

    /**
     * @notice Internal function to validate witness-based permit signatures with custom witness type
     * @dev Validates EIP-712 signature for witness permit with custom witnessTypeString
     * @param owner The expected owner address that should have signed the permit
     * @param spender The spender address included in the signed message
     * @param value The token amount included in the signed message (in token's decimal units)
     * @param deadline The deadline timestamp included in the signed message
     * @param witness The witness data hash included in the signed message
     * @param witnessTypeString Custom witness type string for EIP-712 type construction
     * @param v The recovery identifier of the signature (27 or 28)
     * @param r The first 32 bytes of the signature
     * @param s The second 32 bytes of the signature
     */
    function _validatePermitWitness(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        bytes32 witness,
        string memory witnessTypeString,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        // Validate witnessTypeString is not empty and reasonable length
        if (bytes(witnessTypeString).length == 0 || bytes(witnessTypeString).length > 1024) {
            revert ERC20InvalidWitness();
        }

        bytes32 typeHash = keccak256(abi.encodePacked(PERMIT_WITNESS_TYPESTRING_STAB, witnessTypeString));
        _validatePermitWitnessSignature(owner, spender, value, deadline, witness, typeHash, v, r, s);
    }

    /**
     * @notice Core internal function to validate witness-based permit signatures with a given typeHash
     * @dev Validates EIP-712 signature, checking deadline, incrementing nonce, and recovering signer
     * @param owner The expected owner address that should have signed the permit
     * @param spender The spender address included in the signed message
     * @param value The token amount included in the signed message (in token's decimal units)
     * @param deadline The deadline timestamp included in the signed message
     * @param witness The witness data hash included in the signed message
     * @param typeHash The EIP-712 typeHash for the permit structure
     * @param v The recovery identifier of the signature (27 or 28)
     * @param r The first 32 bytes of the signature
     * @param s The second 32 bytes of the signature
     */
    function _validatePermitWitnessSignature(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        bytes32 witness,
        bytes32 typeHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        if (deadline < block.timestamp) {
            revert ERC2612ExpiredSignature(deadline);
        }

        bytes32 hash;
        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            uint256 nonce = nonces[owner]++;
            bytes32 structHash = keccak256(abi.encode(typeHash, owner, spender, value, nonce, deadline, witness));

            hash = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), structHash));
        }

        address recoveredAddress = ecrecover(hash, v, r, s);

        if (recoveredAddress == address(0) || recoveredAddress != owner) {
            revert ERC2612InvalidSigner(recoveredAddress, owner);
        }
    }

}
