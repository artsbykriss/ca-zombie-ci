// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

library ProtocolTimeLibrary {
    uint256 internal constant WEEK = 7 days;
    uint256 internal constant EPOCH_DURATION = 7 days;
    uint256 internal constant EPOCH_OFFSET = 0;
    uint256 internal constant VOTE_WINDOW = 1 hours;

    /// @dev Returns start of epoch based on current timestamp
    function epochStart(uint256 timestamp) internal pure returns (uint256) {
        uint256 offsetTimestamp = timestamp - EPOCH_OFFSET;
        return timestamp - (offsetTimestamp % EPOCH_DURATION);
    }

    /// @dev Returns start of next epoch / end of current epoch
    function epochNext(uint256 timestamp) internal pure returns (uint256) {
        return epochStart(timestamp) + EPOCH_DURATION;
    }

    /// @dev Returns start of voting window
    function epochVoteStart(uint256 timestamp) internal pure returns (uint256) {
        return epochStart(timestamp) + VOTE_WINDOW;
    }

    /// @dev Returns end of voting window / beginning of unrestricted voting window
    function epochVoteEnd(uint256 timestamp) internal pure returns (uint256) {
        return epochNext(timestamp) - VOTE_WINDOW;
    }
}
