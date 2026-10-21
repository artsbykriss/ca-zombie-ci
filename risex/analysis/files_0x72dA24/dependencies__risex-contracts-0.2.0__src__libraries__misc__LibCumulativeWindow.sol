// SPDX-License-Identifier: MIT
pragma solidity >=0.8.29;

import { SafeCastLib } from "solady/src/utils/SafeCastLib.sol";

/// @title LibCumulativeWindow
/// @notice Fixed-window cumulative tracking for withdrawal limits (hourly/daily).
/// @dev Block-based windows. NOTE: Fixed windows have boundary burst vulnerability
///      (user can withdraw limit at end of window, then again at start of next).
///      This is a documented partial mitigation, not complete protection.
/// @custom:security-contact security@risex.io
library LibCumulativeWindow {
    using SafeCastLib for *;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev Withdrawal would exceed window limit
    error CumulativeLimitExceeded(uint256 currentTotal, uint256 requested, uint256 limit, uint256 windowBlocks);

    /// @dev Invalid configuration (zero limit or window)
    error InvalidWindowConfig();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Emitted when window resets
    event WindowReset(uint256 previousTotal, uint256 newWindowStart, uint256 windowBlocks);

    /// @dev Emitted when configuration changes
    event WindowConfigured(uint256 limit, uint256 windowBlocks);

    /*//////////////////////////////////////////////////////////////
                              DATA STRUCTURES
    //////////////////////////////////////////////////////////////*/

    /// @dev Window state - packed into two slots
    /// @param total Cumulative amount in current window (WAD)
    /// @param windowStart Block when current window started (uint64 safe: 584B years at 1 block/sec)
    /// @param limit Maximum allowed per window (WAD)
    /// @param windowBlocks Window duration in blocks
    struct Window {
        uint128 total;
        uint64 windowStart;
        uint64 windowBlocks;
        uint128 limit;
    }

    /// @dev Configuration for window initialization/update
    struct Config {
        uint128 limit;
        uint64 windowBlocks;
    }

    /*//////////////////////////////////////////////////////////////
                              CORE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Configure the window parameters.
    /// @dev Resets window on config change. Both limit and windowBlocks must be > 0.
    /// @param $ Storage pointer to the window
    /// @param config New configuration
    function configure(
        Window storage $,
        Config memory config
    ) internal {
        require(config.limit != 0 && config.windowBlocks != 0, InvalidWindowConfig());

        $.limit = config.limit;
        $.windowBlocks = config.windowBlocks;
        $.windowStart = block.number.toUint64();
        $.total = 0;

        emit WindowConfigured(config.limit, config.windowBlocks);
    }

    /// @notice Record a withdrawal and check against limit.
    /// @dev Resets window if expired. Reverts if limit exceeded. Skips if not configured.
    /// @param $ Storage pointer to the window
    /// @param amountWad Amount to record (WAD)
    function recordWithdrawal(
        Window storage $,
        uint256 amountWad
    ) internal {
        if (amountWad == 0) return;

        // Skip if not configured (limit == 0 means disabled)
        uint256 limit = $.limit;
        if (limit == 0) return;

        _syncWindow($);

        uint256 newTotal = $.total + amountWad;

        require(newTotal <= limit, CumulativeLimitExceeded($.total, amountWad, limit, $.windowBlocks));

        $.total = newTotal.toUint128();
    }

    /// @notice Get current window state without mutation.
    /// @param $ Storage pointer to the window
    /// @return total Current total in window
    /// @return remaining Remaining capacity
    /// @return blocksUntilReset Blocks until window resets
    function getWindowState(
        Window storage $
    ) internal view returns (uint256 total, uint256 remaining, uint256 blocksUntilReset) {
        Window memory m_window = _previewSync($);
        total = m_window.total;
        remaining = m_window.limit > m_window.total ? m_window.limit - m_window.total : 0;

        uint256 windowEnd = m_window.windowStart + m_window.windowBlocks;
        blocksUntilReset = block.number >= windowEnd ? 0 : windowEnd - block.number;
    }

    /*//////////////////////////////////////////////////////////////
                            PRIVATE HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Sync window to current block. Resets if expired.
    function _syncWindow(
        Window storage $
    ) private {
        uint64 windowStart = $.windowStart;
        uint64 windowBlocks = $.windowBlocks;

        // Initialize on first use
        if (windowStart == 0) {
            $.windowStart = block.number.toUint64();
            return;
        }

        // Check if window expired
        if (block.number >= windowStart + windowBlocks) {
            uint256 previousTotal = $.total;

            // Reset window
            $.windowStart = block.number.toUint64();
            $.total = 0;

            emit WindowReset(previousTotal, block.number, windowBlocks);
        }
    }

    /// @dev Preview window state without mutation.
    function _previewSync(
        Window storage $
    ) private view returns (Window memory m_window) {
        m_window = Window({ total: $.total, windowStart: $.windowStart, windowBlocks: $.windowBlocks, limit: $.limit });

        // Simulate reset if expired
        if (m_window.windowStart != 0 && block.number >= m_window.windowStart + m_window.windowBlocks) {
            m_window.windowStart = block.number.toUint64();
            m_window.total = 0;
        }
    }
}
