// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title IERC20Permit Interface with Errors
/// @notice Interface for ERC20 Permit extension with proper error definitions
/// @dev Extends the standard EIP-2612 permit functionality with error definitions
interface IERC20Permit {

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Thrown when a permit signature has expired
     * @param deadline The timestamp at which the signature expired
     */
    error ERC2612ExpiredSignature(uint256 deadline);

    /**
     * @notice Thrown when the recovered signer does not match the expected owner
     * @param signer The address recovered from the signature
     * @param owner The expected owner address
     */
    error ERC2612InvalidSigner(address signer, address owner);

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted when an owner manually invalidates their nonce
     * @param owner The address that invalidated their nonce
     * @param newNonce The new nonce value after invalidation
     */
    event NonceInvalidated(address indexed owner, uint256 newNonce);

    /*//////////////////////////////////////////////////////////////
                          PERMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the current nonce for the given owner
     * @dev This value must be included whenever a signature is generated for permit
     * @param owner The address to get the nonce for
     * @return The current nonce value for the owner
     */
    function nonces(
        address owner
    ) external view returns (uint256);

    /**
     * @notice Returns the domain separator used in the encoding of signatures
     * @dev Used to prevent signature replay attacks across different domains
     * @return The EIP-712 domain separator hash
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /**
     * @notice Returns the permit typehash used in EIP-712 signature encoding
     * @dev Constant value defining the structure of permit messages
     * @return The keccak256 hash of the permit type string
     */
    function PERMIT_TYPEHASH() external view returns (bytes32);

    /**
     * @notice Sets allowance using EIP-2612 signature-based authorization
     * @dev Allows setting allowance without requiring a separate transaction from the token owner
     * @param owner The owner of the tokens
     * @param spender The address authorized to spend the tokens
     * @param value The amount of tokens to authorize for spending
     * @param deadline The timestamp at which the permit expires
     * @param v The recovery parameter of the signature (27 or 28)
     * @param r The first 32 bytes of the signature
     * @param s The second 32 bytes of the signature
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Invalidates the current nonce for msg.sender
     * @dev Increments the nonce, making all outstanding permit signatures invalid
     * This provides users with an emergency mechanism to cancel pending permits in case of:
     * - Key compromise or suspected phishing
     * - Changed mind about a signed but not executed permit
     * - Need to invalidate multiple permits at once
     * Emits a NonceInvalidated event
     */
    function invalidateNonce() external;

}
