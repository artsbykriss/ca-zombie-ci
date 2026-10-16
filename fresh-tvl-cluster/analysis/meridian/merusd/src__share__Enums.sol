// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

/// @notice A product's associated engine (i.e. instrument) type.
/// @dev Only PERP engine based instruments are supported (as of now).
enum EngineType {
    PERP,
    SPOT
}

/// @notice An order's direction (long = buy, short = sell).
enum OrderSide {
    BUY,
    SELL
}

/// @notice The type of offchain actions batched onchain for processing.
enum ActionType {
    LinkSigner,
    MatchOrders,
    InitiateWithdraw,
    UpdateFunding,
    RevokeLinkedSigner,
    LiquidateSubaccount,
    FinalizeDeposit,
    RealizeFunding,
    RealizePnl,
    DeleverageLiquidator,
    ConvertToken,
    LiquidateSubaccountWithCompensation,
    DeleverageLiquidatorWithCompensation,
    PerpProductDelistPositionSettlement,
    InitiatePerpProductDelist,
    FinalizePerpProductDelist,
    UpdatePositionFee,
    FinalizePerpProductUpdate
}

/// @notice The status of trading restrictions for a product.
enum ProductStatus {
    PENDING,
    ACTIVE,
    DELISTED
}
