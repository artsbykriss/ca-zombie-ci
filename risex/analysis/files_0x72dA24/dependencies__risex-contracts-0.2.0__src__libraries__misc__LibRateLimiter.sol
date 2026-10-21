// SPDX-License-Identifier: MIT
pragma solidity >=0.8.29;

import { SafeCastLib } from "solady/src/utils/SafeCastLib.sol";

/// @title LibRateLimiter
/// @notice Token-bucket rate limiter using block.number for L2 sub-second chains.
/// @dev WAD-scaled values (1e18). Block-based timing is manipulation-resistant.
/// @custom:security-contact security@risex.io
library LibRateLimiter {
    using SafeCastLib for *;

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev Config validation failed (rate > capacity when enabled, or non-zero values when disabled)
    error InvalidConfig();

    /// @dev Request exceeds maximum bucket capacity
    error RequestAboveCapacity(uint256 capacityWad, uint256 requestedWad, address asset);

    /// @dev Insufficient available capacity in bucket
    error RateLimitExceeded(uint256 waitBlocks, uint256 availableWad, address asset);

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event ConfigUpdated(Config config);

    /*//////////////////////////////////////////////////////////////
                              DATA STRUCTURES
    //////////////////////////////////////////////////////////////*/

    /// @dev Bucket state - packed for gas efficiency
    /// @param capacity Maximum value the bucket can hold (WAD)
    /// @param refillPerBlock Refill rate per block (WAD/block)
    /// @param available Current available value (WAD)
    /// @param lastBlock Last sync block number (uint64 safe: 584B years at 1 block/sec)
    /// @param enabled Whether rate limiting is active
    struct Bucket {
        uint128 capacity;
        uint128 refillPerBlock;
        uint128 available;
        uint64 lastBlock;
        bool enabled;
    }

    /// @dev Configuration for bucket initialization/update
    struct Config {
        bool enabled;
        uint128 capacity;
        uint128 refillPerBlock;
    }

    /*//////////////////////////////////////////////////////////////
                              CORE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Apply a new configuration to the bucket.
    /// @dev Syncs bucket state before applying new config. Caps available at new capacity.
    /// @param $ Storage pointer to the bucket
    /// @param config New configuration to apply
    function configure(
        Bucket storage $,
        Config memory config
    ) internal {
        if (config.enabled) {
            // Rate cannot exceed capacity (prevents instant refill exploit)
            require(config.refillPerBlock <= config.capacity, InvalidConfig());
        } else {
            // Disabled config must have zeros
            require(config.refillPerBlock == 0 && config.capacity == 0, InvalidConfig());
        }

        _sync($);

        // Available never exceeds capacity
        if ($.available > config.capacity) {
            $.available = config.capacity;
        }

        $.capacity = config.capacity;
        $.refillPerBlock = config.refillPerBlock;
        $.enabled = config.enabled;

        emit ConfigUpdated(config);
    }

    /// @notice Consume a WAD-denominated notional value from the bucket.
    /// @dev Syncs bucket, validates capacity, updates available. Reverts if insufficient.
    /// @param $ Storage pointer to the bucket
    /// @param valueWad Value to consume (WAD scaled)
    /// @param asset Asset associated (for error context)
    function consumeValue(
        Bucket storage $,
        uint256 valueWad,
        address asset
    ) internal {
        // Disabled bucket passes (no enforcement)
        if (!$.enabled || valueWad == 0) return;

        _sync($);

        uint256 capacity = $.capacity;
        // Request cannot exceed capacity
        require(valueWad <= capacity, RequestAboveCapacity(capacity, valueWad, asset));

        uint256 available = $.available;
        if (valueWad > available) {
            uint256 refillPerBlock = $.refillPerBlock;
            // Calculate blocks to wait (ceiling division)
            uint256 waitBlocks =
                refillPerBlock == 0 ? type(uint256).max : (valueWad - available + refillPerBlock - 1) / refillPerBlock;
            revert RateLimitExceeded(waitBlocks, available, asset);
        }

        $.available = (available - valueWad).toUint128();
    }

    /// @notice Compute the current bucket state without mutating storage.
    /// @dev Useful for UI/off-chain queries to show available capacity.
    /// @param m_bucket Memory copy of bucket state
    /// @return Updated bucket state reflecting current block
    function preview(
        Bucket memory m_bucket
    ) internal view returns (Bucket memory) {
        if (m_bucket.lastBlock == 0) {
            m_bucket.lastBlock = block.number.toUint64();
            return m_bucket;
        }

        uint256 elapsed = block.number - m_bucket.lastBlock;
        if (elapsed == 0) return m_bucket;

        // Refill is linear with blocks
        uint256 refilled = m_bucket.available + elapsed * m_bucket.refillPerBlock;
        // Cap at capacity
        if (refilled > m_bucket.capacity) refilled = m_bucket.capacity;

        m_bucket.available = refilled.toUint128();
        m_bucket.lastBlock = block.number.toUint64();
        return m_bucket;
    }

    /// @notice Get current available capacity after sync.
    /// @param $ Storage pointer to the bucket
    /// @return Current available capacity (WAD)
    function getAvailable(
        Bucket storage $
    ) internal view returns (uint256) {
        return preview(_toBucketMemory($)).available;
    }

    /*//////////////////////////////////////////////////////////////
                            PRIVATE HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Sync bucket state to current block. Updates available based on elapsed blocks.
    function _sync(
        Bucket storage $
    ) private {
        uint256 lastBlock = $.lastBlock;
        uint256 currentBlock = block.number;

        // Initialize on first use
        if (lastBlock == 0) {
            $.lastBlock = currentBlock.toUint64();
            return;
        }

        uint256 elapsed = currentBlock - lastBlock;
        if (elapsed == 0) return;

        // Linear refill
        uint256 refilled = $.available + elapsed * $.refillPerBlock;
        // Cap at capacity
        if (refilled > $.capacity) refilled = $.capacity;

        $.available = refilled.toUint128();
        $.lastBlock = currentBlock.toUint64();
    }

    /// @dev Convert storage bucket to memory for preview calculations.
    function _toBucketMemory(
        Bucket storage $
    ) private view returns (Bucket memory) {
        return Bucket({
            capacity: $.capacity,
            refillPerBlock: $.refillPerBlock,
            available: $.available,
            lastBlock: $.lastBlock,
            enabled: $.enabled
        });
    }
}
