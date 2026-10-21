// SPDX-License-Identifier: MIT
pragma solidity >=0.8.29 <0.9.0;

/// @title IStork
/// @notice Interface for the Stork oracle contract
/// @dev This interface provides access to Stork's temporal numeric values and verification functions
interface IStork {
    /*//////////////////////////////////////////////////////////////////////////
                                    STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Represents a temporal numeric value with timestamp and quantized value
    struct TemporalNumericValue {
        /// @dev Nanosecond level precision timestamp of latest publisher update in batch
        uint64 timestampNs; // 8 bytes
        /// @dev Should be able to hold all necessary numbers with 18 decimals (up to
        // 6277101735386680763835789423207666416102355444464034512895)
        int192 quantizedValue; // 24 bytes
    }

    /// @notice Input structure for updating temporal numeric values
    struct TemporalNumericValueInput {
        TemporalNumericValue temporalNumericValue;
        bytes32 id;
        bytes32 publisherMerkleRoot;
        bytes32 valueComputeAlgHash;
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    /// @notice Publisher signature structure for verification
    struct PublisherSignature {
        address pubKey;
        string assetPairId;
        uint64 timestamp; // 8 bytes
        uint256 quantizedValue; // 32 bytes
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Updates multiple temporal numeric values by verifying signatures and ensuring freshness
    /// @param updateData Array of TemporalNumericValueInput structs containing feed updates
    /// @dev Requires sufficient fee based on the number of updates
    /// @dev Reverts with InvalidSignature if any feed update fails signature verification
    /// @dev Reverts with NoFreshUpdate if none of the provided updates are fresher than current values
    /// @dev Reverts with InsufficientFee if the provided fee is less than the required amount
    function updateTemporalNumericValuesV1(
        TemporalNumericValueInput[] calldata updateData
    ) external payable;

    /// @notice Retrieves the latest temporal numeric value for the specified feed ID
    /// @param id The identifier of the feed
    /// @return value The latest TemporalNumericValue struct for the feed
    /// @dev Checks for staleness threshold (typically 3600 seconds)
    /// @dev Reverts with NotFound if no value exists for the given feed ID
    /// @dev Reverts with StaleValue if the value is older than the valid time period
    function getTemporalNumericValueV1(
        bytes32 id
    ) external view returns (TemporalNumericValue memory value);

    /// @notice Retrieves the latest temporal numeric value for the specified feed ID without checking freshness
    /// @param id The identifier of the feed
    /// @return value The latest TemporalNumericValue struct for the feed
    /// @dev Does not check for staleness - use with caution
    /// @dev Reverts with NotFound if no value exists for the given feed ID
    function getTemporalNumericValueUnsafeV1(
        bytes32 id
    ) external view returns (TemporalNumericValue memory value);

    /// @notice Calculates the total fee required for the given updates
    /// @param updateData Array of TemporalNumericValueInput structs representing updates
    /// @return feeAmount The total fee required for the updates
    function getUpdateFeeV1(
        TemporalNumericValueInput[] calldata updateData
    ) external view returns (uint256 feeAmount);

    /// @notice Verifies multiple publisher signatures against the provided Merkle root
    /// @param signatures Array of PublisherSignature structs
    /// @param merkleRoot The Merkle root to validate against
    /// @return bool True if all signatures are valid and match the Merkle root
    function verifyPublisherSignaturesV1(
        PublisherSignature[] calldata signatures,
        bytes32 merkleRoot
    ) external pure returns (bool);

    /// @notice Retrieves the current version of the contract
    /// @return string The version string (e.g., "1.0.3")
    function version() external pure returns (string memory);
}
