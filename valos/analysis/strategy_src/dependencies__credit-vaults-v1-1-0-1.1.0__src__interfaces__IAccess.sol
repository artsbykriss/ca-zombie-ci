// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Struct containing transaction authentication data (EIP-712 typed)
/// @dev Chain ID is part of the EIP-712 domain separator, not this struct
struct TxAuthData {
    /// @notice The calldata of the function being called (selector + encoded args)
    bytes functionCallData;
    /// @notice The address of the contract where the transaction is being executed
    address contractAddress;
    /// @notice The address of the account executing/controlling the transaction
    address account;
    /// @notice The per-account nonce (prevents replay)
    uint256 nonce;
    /// @notice The block number after which the transaction is considered expired
    uint256 blockExpiration;
}

/// @notice Struct containing verification data for verifyMany function
struct VerifyManyData {
    /// @notice The function call data extracted from msgData
    bytes argsWithSelector;
    /// @notice The block expiration timestamp
    uint256 blockExpiration;
    /// @notice The start position of signatures in msgData
    uint256 signaturesStart;
    /// @notice The number of signatures to verify
    uint256 numSignatures;
}

/// @notice Enum representing different permission levels
enum PermissionLevel {
    /// @notice No permission
    None,
    /// @notice KYC based permission
    KYC,
    /// @notice Whitelist based permission
    Whitelist
}

/// @title Whitelistable Interface
/// @notice Interface for managing whitelisted accounts
interface IWhitelistable {
    /// @notice Emitted when allowed status is set for an account
    /// @param account The address of the account
    /// @param allowed The allowed status
    event AllowedSet(address indexed account, bool allowed);

    /// @notice Set allowed accounts
    /// @param accounts Array of account addresses
    /// @param allowed Array of allowed status corresponding to acounts
    function setAllowed(address[] calldata accounts, bool[] calldata allowed) external;

    /// @notice Check if an account is allowed
    /// @param account The address to check allowed status for
    /// @return bool True if the account is allowed, false otherwise
    function allowed(address account) external view returns (bool);

    /// @notice Check if multiple accounts are allowed
    /// @param accounts Array of account addresses
    /// @return bool True if the accounts are allowed, false otherwise
    function allowedMany(address[] calldata accounts) external view returns (bool);
}

/// @title Authorizable Interface
/// @notice Interface for managing authorizable accounts
interface IAuthorizable {
    /// @notice Emitted when the signer address is changed
    /// @param oldSigner The old signer address
    /// @param newSigner The new signer address
    event SignerChanged(address indexed oldSigner, address indexed newSigner);

    /// @notice Emitted when a transaction authentication data is verified
    /// @param chainID The chain ID where the transaction is intended to be processed
    /// @param nonce The nonce of the user being verified to prevent replay attacks
    /// @param blockExpiration The block number after which the transaction is considered expired
    /// @param contractAddress The address of the contract where the transaction is being executed
    /// @param userAddress The address of the user executing the transaction
    /// @param functionCallData The calldata of the function being called
    event TxAuthDataVerified(
        uint256 chainID,
        uint256 nonce,
        uint256 blockExpiration,
        address indexed contractAddress,
        address indexed userAddress,
        bytes functionCallData
    );

    /// @notice Set the signer address
    /// @param signer The address of the signer
    function setSigner(address signer) external;

    /// @notice Get the signer address
    /// @return The signer address
    function signer() external view returns (address);

    /// @notice Get the nonce for a given user
    /// @param user The address of the user
    /// @return The nonce of the user
    function nonces(address user) external view returns (uint256);

    /// @notice Get the message hash for a given transaction authentication data
    /// @param txAuthData The transaction authentication data
    /// @return The message hash
    function getMessageHash(TxAuthData calldata txAuthData) external view returns (bytes32);
}

/// @title Access Interface
/// @notice Interface for managing access to a contract
interface IAccess is IAuthorizable, IWhitelistable {
    /// @notice Get the permission level for the loan
    /// @return The permission level enum value
    function permissionLevel() external view returns (PermissionLevel);
}
