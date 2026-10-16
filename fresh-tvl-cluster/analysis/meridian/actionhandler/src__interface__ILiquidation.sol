// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {EngineType} from "../share/Enums.sol";
import {ActionId} from "../share/UserDefinedTypes.sol";

interface ILiquidation {
    // --- Events --- //

    /// @notice Emitted when the provided liquidation balance transfer value differs from reference calculation but within tolerance.
    event LiquidationBalanceTransferMismatch(
        ActionId id, int128 externalValue, int256 internalValue, uint256 tolerance
    );

    /// @notice Emitted when the internal maintenance margin check failed but within tolerance.
    event LiquidationMarginCheckMismatch(ActionId id, uint256 maintenanceMargin, int256 equity, uint256 tolerance);

    /// @notice Emitted when a position is transferred to liquidator due to liquidation.
    event PositionLiquidated(
        uint32 indexed productId,
        address indexed liquidatedAccount,
        bytes32 indexed liquidatedSubaccount,
        EngineType engineType,
        int128 size,
        uint128 notional,
        uint64 messageIdx
    );

    // --- Structs --- //

    struct LiquidatedProduct {
        /// Onchain productId of the liquidated position.
        uint32 productId;
        /// EngineType of product.
        EngineType engineType;
        /// Fee in wei required by Pyth to perform a price validation.
        uint64 pythFee;
        /// Size delta to liquidate e.g. position is long 0.42 then sizedelta -0.42 is required.
        int128 sizeDelta;
        /// Pyth price update blob.
        bytes pythPriceUpdate;
        /// Notional delta `size x price` as uPnL at transfer to liquidator.
        uint128 cost;
        /// Realized PnL for the liquidator from position changes.
        int128 liquidatorRealizedPnl;
    }

    struct RealizePnl {
        /// Onchain productId of the position being adjusted.
        uint32 productId;
        /// Signed change applied to the position cost to realize PnL.
        int128 costDelta;
    }

    struct LiquidateSubaccountAction {
        /// Address of liquidated trader.
        address liquidatedAccount;
        /// Subaccount of liquidated trader.
        bytes32 liquidatedSubaccount;
        /// Products with positions of liquidated trader to transfer.
        LiquidatedProduct[] products;
        /// Amount of balance transferred from the user to the liquidator beyond the positions.
        int128 balanceTransfer;
        /// Matching engine message correlation index.
        uint64 messageIdx;
    }

    struct LiquidateSubaccountWithCompensationAction {
        /// Address of liquidated trader.
        address liquidatedAccount;
        /// Subaccount of liquidated trader.
        bytes32 liquidatedSubaccount;
        /// Products with positions of liquidated trader to transfer.
        LiquidatedProduct[] products;
        /// Realized pnl snapshots provided before position transfer.
        RealizePnl[] preRealizations;
        /// Number of pre-realizations that should be applied before each liquidation in the containing `products` array entry.
        uint16[] preRealizationCounts;
        /// Amount of balance transferred from the user to the liquidator beyond the positions.
        int128 balanceTransfer;
        /// Matching engine message correlation index.
        uint64 messageIdx;
    }

    /// @notice Performs a full position takeover, transferring to the liquidator.
    /// @param id action identifier for the liquidation (useful when part of a batch operation).
    /// @param actionData the bytes of the initial payload excluding the first byte (action index).
    function liquidateSubaccount(ActionId id, bytes calldata actionData) external payable;

    /// @notice Performs a full position takeover with pre-realizations, transferring to the liquidator.
    /// @param id action identifier for the liquidation (useful when part of a batch operation).
    /// @param actionData full packed compensation action bytes, including the action header, with payload of type LiquidateSubaccountWithCompensationAction
    ///     messageIdx,
    ///     liquidatedAccount,
    ///     liquidatedSubaccount,
    ///     balanceTransfer,
    ///     numProducts,
    ///     numPreRealizations,
    ///     LiquidatedProduct[numProducts] (productId, engineType, pythFee, sizeDelta, pythPriceUpdateLength, pythPriceUpdate, cost,
    ///         liquidatorRealizedPnl),
    ///     RealizePnl[numPreRealizations] (productId, costDelta),
    ///     preRealizationCounts (length = numProducts).
    function liquidateSubaccountWithCompensation(ActionId id, bytes calldata actionData) external payable;
}
