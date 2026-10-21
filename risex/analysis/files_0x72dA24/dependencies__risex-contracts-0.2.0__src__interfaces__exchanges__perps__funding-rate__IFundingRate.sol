// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import { IAccessManaged } from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";
import { IPerpsManager } from "src/interfaces/exchanges/perps/engine/IPerpsManager.sol";
import { IRISExOracle } from "src/interfaces/oracles/IRISExOracle.sol";
import { IOrdersManager } from "src/interfaces/order-book/IOrdersManager.sol";

interface IFundingRate is IAccessManaged {
    struct FundingPayment {
        int128 accumulated;
        int96 currentFundingRate;
        uint32 lastUpdatedAt;
    }

    struct PendingFundingData {
        // ── slot 0: hot path (snapshot if-check + accumulation) ──
        int128 pendingSum;
        uint32 pendingCount;
        uint32 lastSnapshotKey;
        uint32 lastSnapshotWeight;
        // ── slot 1: snapshot value ───────────────────────────────
        int224 lastSnapshotValue;
    }

    struct FundingClamp {
        int96 floor;
        int96 cap;
    }

    /// @notice Emitted when a per-market funding clamp is set
    /// @param marketId The market ID
    /// @param floor The funding rate floor (0 = use global default)
    /// @param cap The funding rate cap (0 = use global default)
    event SetFundingClamp(uint16 indexed marketId, int96 floor, int96 cap);

    /// @notice Emitted when the funding rate is settled
    /// @param marketId The market ID
    /// @param fundingRate The funding rate
    /// @param newAccumulated The new accumulated funding payment
    /// @param indexPrice The index price
    /// @param startTimestamp The start timestamp
    /// @param endTimestamp The end timepoint
    event SettleFundingRate(
        uint16 indexed marketId,
        int256 fundingRate,
        int256 newAccumulated,
        uint256 indexPrice,
        uint256 startTimestamp,
        uint256 endTimestamp
    );

    /// @notice Emitted when a premium index is snapshotted
    event SnapshotPremiumIndex(
        uint16 indexed marketId,
        int256 premiumIndex,
        uint256 indexPrice,
        uint256 impactBidPrice,
        uint256 impactAskPrice,
        uint256 startTimestamp,
        uint256 endTimestamp
    );

    /// @notice Settles the funding rate for a market every 1 hour
    /// Impact Notional Amount = 500 USDC / IMR of the market = 500 USDC * max leverage of the market
    /// Impact Bid Price = Average(execution price of sell with size of Impact Notional Amount)
    /// Impact Ask Price = Average(execution price of buy with size of Impact Notional Amount)
    /// Premium Index = [max(0, Impact Bid Price - Index Price) - max(0, Index Price - Impact Ask Price)] / Index Price
    // Funding Rate = (Average Premium Index + Interest Rate) / 8
    /// @dev This is used to update the funding payment for a market
    /// @param marketId The market ID
    function settleFundingRate(
        uint16 marketId
    ) external;

    /// @notice Snapshots the premium index for a market every 5 seconds
    /// @param marketId The market ID
    function snapshotPremiumIndex(
        uint16 marketId
    ) external;

    /// @notice Snapshots the premium index, settles the funding rate, and syncs the quote token
    ///         block EMA in a single call
    /// @dev Saves gas by performing auth + lock check once instead of twice.
    ///      Also syncs the quote token block EMA to keep it fresh through organic trading activity.
    /// @param marketId The market ID
    function snapshotAndSettleFunding(
        uint16 marketId
    ) external;

    /// @notice Returns the accumulated funding payment for a market
    /// @param marketId The market ID
    /// @return accumulated The accumulated funding payment
    /// @return currentFundingRate The current funding rate
    /// @return lastUpdatedAt The last updated at
    function getFundingPayments(
        uint16 marketId
    ) external view returns (int128 accumulated, int96 currentFundingRate, uint32 lastUpdatedAt);

    /// @notice Returns the total number of premium items for a market
    function totalPremiumItems(
        uint16 marketId
    ) external view returns (uint256 totalPremiumItems);

    /// @notice Finds the premium index at or before a given timestamp
    /// @param marketId The market ID
    /// @param timestamp The timestamp to find the premium index at or before
    function findPremiumIndexAtOrBefore(
        uint16 marketId,
        uint32 timestamp
    ) external view returns (uint32 matchedTimestamp, int224 premiumIndex);

    /// @notice Returns the pending funding accumulator data for a market
    /// @param marketId The market ID
    /// @return pendingSum The time-weighted sum of premium indices since last settlement
    /// @return pendingCount The total elapsed seconds of accumulated snapshots since last settlement
    /// @return lastSnapshotValue The last pushed premium index value
    /// @return lastSnapshotKey The last pushed timestamp
    function getPendingFunding(
        uint16 marketId
    ) external view returns (int128 pendingSum, uint32 pendingCount, int224 lastSnapshotValue, uint32 lastSnapshotKey);

    /// @notice Returns the OrdersManager contract
    function getOrdersManager() external view returns (IOrdersManager);

    /// @notice Returns the PerpsManager contract
    function getPerpsManager() external view returns (IPerpsManager);

    /// @notice Returns the RISExOracle contract
    function getRisexOracle() external view returns (IRISExOracle);

    /// @notice Sets a per-market funding rate clamp override
    /// @dev Setting both floor and cap to 0 resets to global defaults
    /// @param marketId The market ID
    /// @param floor The funding rate floor (must be < 0). To reset to default, both floor and cap must be 0
    /// @param cap The funding rate cap (must be > 0). To reset to default, both floor and cap must be 0
    function setFundingClamp(
        uint16 marketId,
        int96 floor,
        int96 cap
    ) external;

    /// @notice Returns the effective funding clamp for a market (resolved with global defaults)
    /// @param marketId The market ID
    /// @return floor The effective funding rate floor
    /// @return cap The effective funding rate cap
    function getFundingClamp(
        uint16 marketId
    ) external view returns (int96 floor, int96 cap);
}
