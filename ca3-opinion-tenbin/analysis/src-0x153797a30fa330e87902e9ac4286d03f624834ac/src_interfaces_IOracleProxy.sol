// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IOracleProxy
 * @notice Interface for OracleProxy contract
 * @dev Used by ResolutionMultiSig to forward resolution calls
 */
interface IOracleProxy {
    // ============ Events ============

    event ImplementationUpdated(
        address indexed oldImpl,
        address indexed newImpl,
        uint256 timestamp
    );

    event ResolutionForwarded(
        bytes32 indexed questionId,
        uint256[] payouts,
        address indexed resolver,
        uint256 timestamp
    );

    event GuardianUpdated(
        address indexed oldGuardian,
        address indexed newGuardian
    );

    // ============ Errors ============

    error UnauthorizedCaller(address caller, address expected);
    error InvalidImplementation();
    error ZeroAddress();
    error UnauthorizedPause();
    error InvalidPayouts();

    // ============ Core Functions ============

    /**
     * @notice Forward resolve call to ConditionalTokens
     * @param questionId The question ID to resolve
     * @param payouts The payout array [yesAmount, noAmount]
     */
    function resolve(bytes32 questionId, uint256[] calldata payouts) external;

    // ============ Admin Functions ============

    /**
     * @notice Upgrade the implementation contract
     * @param _newImpl Address of new resolver contract
     */
    function setImplementation(address _newImpl) external;

    /**
     * @notice Update the guardian address
     * @param _newGuardian New guardian address
     */
    function setGuardian(address _newGuardian) external;

    /**
     * @notice Emergency pause
     */
    function pause() external;

    /**
     * @notice Unpause
     */
    function unpause() external;

    // ============ View Functions ============

    /**
     * @notice Get ConditionalTokens address
     */
    function conditionalTokens() external view returns (address);

    /**
     * @notice Get current implementation address
     */
    function implementation() external view returns (address);

    /**
     * @notice Get guardian address
     */
    function guardian() external view returns (address);

    /**
     * @notice Check if contract is operational
     */
    function isOperational() external view returns (bool);

    /**
     * @notice Get current configuration
     */
    function getConfig() external view returns (
        address _conditionalTokens,
        address _implementation,
        address _owner,
        address _guardian,
        bool _paused
    );
}
