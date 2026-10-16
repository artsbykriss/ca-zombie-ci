// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

library PerpPosition {
    struct Data {
        /// Position size; positive is long/buy and negative is short/sell, zero is closed
        int128 size;
        /// Current position cost, zero when closed
        uint128 cost;
        /// The cumulative funding at the point of matched orders
        int128 lastFundingUsd;
        /// The cumulative position fee at the point of matched orders or explicit realization
        uint128 lastPositionFeeUsd;
    }

    /// @dev Updates an existing perp position struct with new perp position values.
    function update(PerpPosition.Data storage self, PerpPosition.Data memory position) internal {
        self.size = position.size;
        self.cost = position.cost;
        self.lastFundingUsd = position.lastFundingUsd;
        self.lastPositionFeeUsd = position.lastPositionFeeUsd;
    }

    /// @dev Clears a perp position struct to zero values.
    function clear(PerpPosition.Data storage self) internal {
        self.size = 0;
        self.cost = 0;
        self.lastFundingUsd = 0;
        self.lastPositionFeeUsd = 0;
    }
}
