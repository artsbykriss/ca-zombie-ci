// SPDX-License-Identifier: MIT
pragma solidity >=0.8.29;

/// @title IPendingSettlementCleaner
/// @notice Interface for deferred maker settlement pumping
/// @dev Dirty price levels accumulate fill segments during matching. This interface provides
///      bounded settlement pumping to replay those segments and settle individual maker orders.
interface IPendingSettlementCleaner {
    /// @notice Emitted once per settlement batch processed at a dirty level
    /// @param protocol The protocol address whose orders were settled
    /// @param marketId The market identifier
    /// @param tick The raw tick value of the settled level
    /// @param processedOrders Number of maker orders settled in this batch
    /// @param processedSegments Number of fill segments consumed in this batch
    event BatchSettled(
        address indexed protocol, uint16 indexed marketId, uint24 tick, uint32 processedOrders, uint32 processedSegments
    );

    /// @notice Describes a dirty price level awaiting deferred settlement
    struct DirtyLevel {
        bool exists;
        uint24 tick;
        uint32 pendingSegments;
    }

    /// @notice Progress metrics returned from a pumping operation
    struct PumpProgress {
        uint32 processedLevels;
        uint32 processedOrders;
        uint32 processedSegments;
        bool done;
    }

    /// @notice Returns how many dirty levels currently have pending deferred settlement work
    function pendingWorkCount(
        address protocol,
        uint16 marketId
    ) external view returns (uint256);

    /// @notice Returns the next dirty level candidate for settlement pumping
    function peekDirtyLevel(
        address protocol,
        uint16 marketId
    ) external view returns (DirtyLevel memory);

    /// @notice Pumps deferred maker settlement work in bounded chunks
    function pumpDirtyLevels(
        address protocol,
        uint16 marketId,
        uint32 maxLevels,
        uint32 maxOrders,
        uint32 maxSegments
    ) external returns (PumpProgress memory);

    /// @notice Pumps deferred settlement for a specific user's pending orders only
    /// @dev Order-driven: finds ticks containing the user's pending orders and settles FIFO
    ///      within each tick until the user's orders reach pendingSteps == 0. Callers can bound
    ///      work per call via maxOrders / maxSegments to avoid OOG when the user's order sits
    ///      deep in the queue behind many other users' fills. The progress.done flag returns
    ///      false when pending deferred fills remain, supporting incremental multi-tx settlement.
    /// @param protocol The protocol address whose orders are being settled
    /// @param marketId The market identifier
    /// @param userId The user whose pending orders to settle
    /// @param maxOrders Maximum orders to process (use type(uint32).max for unbounded)
    /// @param maxSegments Maximum segments to process (use type(uint32).max for unbounded)
    /// @return Progress metrics (done = true when all user orders are fully settled)
    function pumpForUser(
        address protocol,
        uint16 marketId,
        uint32 userId,
        uint32 maxOrders,
        uint32 maxSegments
    ) external returns (PumpProgress memory);
}
