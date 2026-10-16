// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {ActionId} from "../share/UserDefinedTypes.sol";

interface IDeleverage {
    // --- Events --- //

    /// @notice Emitted when a position is reduced due to deleveraging.
    event PositionDeleveraged(
        uint32 indexed productId,
        address indexed account,
        bytes32 indexed subaccount,
        int128 sizeDelta,
        int128 realizedPnl,
        uint128 notional,
        uint64 messageIdx
    );

    /// @notice Emitted when the liquidator bankruptcy check failed but within tolerance.
    event DeleverageLiquidatorBankruptcyCheckMismatch(ActionId id, int256 equity, uint256 tolerance);

    // --- Structs --- //

    /// @notice Internal struct for deleverage match processing (full-size types).
    struct DeleverageUserMatch {
        /// Onchain productId for this match.
        uint32 productId;
        /// Size delta to deleverage from both positions (from the perspective of the user).
        int128 sizeDelta;
        /// Notional of the match `size x price` transferred from liquidator (absolute notional).
        uint128 notional;
        /// Realized PnL for the user from position reduction.
        int128 userRealizedPnl;
        /// Realized PnL for the liquidator from position reduction.
        int128 liquidatorRealizedPnl;
    }

    /// @notice Realized pnl data for a pre-processed user/product pair.
    struct RealizePnl {
        /// Onchain productId of the position being adjusted.
        uint32 productId;
        /// Signed change applied to the position cost to realize PnL.
        int128 costDelta;
    }

    /// @notice Packed user match for deleverage action - uses smaller types to minimize calldata.
    struct DeleverageUserMatchPacked {
        /// Index into the products array (max 65535 products).
        uint16 productIndex;
        /// Size delta to deleverage (in gwei precision, int64 sufficient for most positions).
        int64 sizeDelta;
        /// Notional of the match (in gwei precision).
        uint64 notional;
        /// Realized PnL for the user.
        int64 userRealizedPnl;
        /// Realized PnL for the liquidator.
        int64 liquidatorRealizedPnl;
    }

    /// @notice User struct for deleverage action.
    struct DeleverageUser {
        /// Address of the account being deleveraged.
        address account;
        /// Subaccount of the account being deleveraged.
        bytes32 subaccount;
        /// All deleverage matches for this user.
        DeleverageUserMatchPacked[] matches;
    }

    /// @notice User chunk for deleverage action with compensation.
    struct DeleverageUserChunk {
        /// Address of the account being deleveraged.
        address account;
        /// Subaccount of the account being deleveraged.
        bytes32 subaccount;
        /// All deleverage matches for this user.
        DeleverageUserMatchPacked[] matches;
        /// Realized pnl snapshots provided before position reduction.
        RealizePnl[] preRealizations;
        /// Number of pre-realizations that should be applied before each deleverage match in `matches`.
        uint16[] preRealizationCounts;
    }

    /// @notice Individual Pyth update payload and fee for deleverage.
    struct DeleveragePythUpdate {
        /// Pyth price update blob.
        bytes pythPriceUpdate;
        /// Fee in wei required by Pyth to perform this price validation.
        uint64 pythFee;
    }

    /// @notice Deleverage action with individual Pyth updates per product and packed encoding.
    struct DeleverageLiquidatorAction {
        /// Individual Pyth price update + fee per product (one update per productId).
        DeleveragePythUpdate[] pythPriceUpdates;
        /// Product IDs in the same order as pythPriceUpdates.
        uint32[] productIds;
        /// User deleverages with packed matches.
        DeleverageUser[] users;
        /// Matching engine message correlation index.
        uint64 messageIdx;
    }

    /// @notice Deleverage action with pre-realized PnL chunks to support liquidation sequencing.
    struct DeleverageLiquidatorWithCompensationAction {
        /// Individual Pyth price update + fee per product (one update per productId).
        DeleveragePythUpdate[] pythPriceUpdates;
        /// Product IDs in the same order as pythPriceUpdates.
        uint32[] productIds;
        /// User chunks containing matches and pre-realized pnl data.
        DeleverageUserChunk[] users;
        /// Matching engine message correlation index.
        uint64 messageIdx;
    }

    /// @notice Performs deleveraging by reducing liquidator positions against user positions.
    /// @dev Uses individual Pyth updates per product and packed struct encoding.
    /// @param id action identifier for the deleverage (useful when part of a batch operation).
    /// @param actionData the bytes of the packed payload excluding the action header.
    function deleverageLiquidator(ActionId id, bytes calldata actionData) external payable;
}

interface IDeleverageWithCompensation {
    /// @notice Performs deleveraging with pre-realized PnL per user chunk, reducing liquidator positions against user positions.
    /// @dev Uses the packed compensation wire format with pre-realization payloads.
    /// @param id action identifier for the deleverage (useful when part of a batch operation).
    /// @param actionData the full packed compensation action bytes, including the action header.
    function deleverageLiquidatorWithCompensation(ActionId id, bytes calldata actionData) external payable;
}
