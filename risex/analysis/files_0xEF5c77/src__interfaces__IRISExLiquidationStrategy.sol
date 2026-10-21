// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.29;

import {Position} from "src/interfaces/RISExTypes.sol";
import {IRISExStrategy} from "src/interfaces/extensions/IRISExStrategy.sol";

/// @title IRISExLiquidationStrategy
/// @notice Interface for the RISEx liquidation (xlpUSD) strategy
/// @dev Extends IRISExStrategy with liquidation takeovers, OTC transfers,
///      and acceptance limit management.
interface IRISExLiquidationStrategy is IRISExStrategy {
    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Preview state used internally during cross-margin takeover simulation
    struct CrossTakeoverPreviewState {
        uint256 marketCount;
        uint256 projectedGlobalExposure;
        uint256 totalNotional;
    }

    /// @notice Per-market limit configuration
    /// @param positionCap Max notional per takeover (6 dec, 0 = use default)
    /// @param dailyCapBps Daily cap in BPS (0 = use default)
    struct MarketLimitConfig {
        uint128 positionCap;
        uint16 dailyCapBps;
    }

    /// @notice Per-market daily tracking
    /// @param exposure Accumulated exposure today (6 dec)
    /// @param lastResetTimestamp Last lazy reset timestamp
    struct MarketDailyData {
        uint128 exposure;
        uint32 lastResetTimestamp;
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a cross-margin takeover is executed
    /// @param account The liquidated account
    /// @param marketIds Markets involved in the takeover
    /// @param notional Total notional value taken over (6 decimals)
    event TakeoverExecuted(
        address indexed account,
        uint16[] marketIds,
        uint256 notional
    );

    /// @notice Emitted when an isolated position takeover is executed
    /// @param account The liquidated account
    /// @param marketId The market of the taken-over position
    /// @param notional Notional value of the position (6 decimals)
    event IsolatedTakeoverExecuted(
        address indexed account,
        uint16 indexed marketId,
        uint256 notional
    );

    /// @notice Emitted when a position is transferred to the MM adapter via OTC
    /// @param marketId The market of the transferred position
    /// @param size The position size transferred
    /// @param price The OTC price
    event PositionTransferredToMM(
        uint16 indexed marketId,
        uint128 size,
        uint128 price
    );

    /// @notice Emitted when daily counters are reset
    /// @param timestamp The new day start timestamp
    event DailyCountersReset(uint256 timestamp);

    /// @notice Emitted when a market's position cap is updated
    /// @param marketId The market
    /// @param oldCap Previous cap (6 decimals)
    /// @param newCap New cap (6 decimals)
    event MarketPositionCapUpdated(
        uint16 indexed marketId,
        uint256 oldCap,
        uint256 newCap
    );

    /// @notice Emitted when a market's daily cap is updated
    /// @param marketId The market
    /// @param oldCapBps Previous cap in BPS
    /// @param newCapBps New cap in BPS
    event MarketDailyCapUpdated(
        uint16 indexed marketId,
        uint256 oldCapBps,
        uint256 newCapBps
    );

    /// @notice Emitted when the global daily cap is updated
    /// @param oldCapBps Previous cap in BPS
    /// @param newCapBps New cap in BPS
    event GlobalDailyCapUpdated(uint256 oldCapBps, uint256 newCapBps);

    /// @notice Emitted when the default position cap is updated
    /// @param oldCap Previous cap (6 decimals)
    /// @param newCap New cap (6 decimals)
    event DefaultPositionCapUpdated(uint256 oldCap, uint256 newCap);

    /// @notice Emitted when the default market daily cap is updated
    /// @param oldCapBps Previous cap in BPS
    /// @param newCapBps New cap in BPS
    event DefaultMarketDailyCapUpdated(uint256 oldCapBps, uint256 newCapBps);

    /// @notice Emitted when the MM adapter address is updated
    /// @param oldAdapter Previous MM adapter address
    /// @param newAdapter New MM adapter address
    event MMAdapterUpdated(address oldAdapter, address newAdapter);

    /// @notice Emitted when caps are enabled or disabled
    /// @param disabled True if all cap checks are now skipped
    event CapsDisabledUpdated(bool disabled);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when an invalid BPS cap value is provided (> 10,000)
    error InvalidCapBps();

    /// @notice Thrown when a takeover exceeds the per-position cap
    /// @param marketId The market that exceeded the cap
    /// @param notional The notional value attempted
    /// @param cap The position cap for the market
    error TakeoverExceedsPositionCap(
        uint16 marketId,
        uint256 notional,
        uint256 cap
    );

    /// @notice Thrown when a takeover exceeds the per-market daily cap
    /// @param marketId The market that exceeded the cap
    /// @param exposure The projected total exposure
    /// @param cap The daily cap for the market
    error TakeoverExceedsMarketDailyCap(
        uint16 marketId,
        uint256 exposure,
        uint256 cap
    );

    /// @notice Thrown when a takeover exceeds the global daily cap
    /// @param exposure The projected total global exposure
    /// @param cap The global daily cap
    error TakeoverExceedsGlobalDailyCap(uint256 exposure, uint256 cap);

    /// @notice Thrown when attempting OTC transfer without MM adapter set
    error MMAdapterNotSet();

    /// @notice Thrown when attempting to set MM adapter to a strategy address
    /// @param addr The disallowed address
    error StrategyAddressNotAllowed(address addr);

    /// @notice Thrown when attempting to transfer a position that doesn't exist
    /// @param marketId The market with no position
    error NoPositionToTransfer(uint16 marketId);

    /*//////////////////////////////////////////////////////////////
                        ACCEPTANCE LIMIT CHECKS
    //////////////////////////////////////////////////////////////*/

    /// @notice Check if a takeover can be accepted based on all limits
    /// @dev Reverts with specific custom error if any limit is exceeded
    /// @param marketId The market ID
    /// @param notional The notional value of the position (6 decimals)
    function canAcceptTakeover(uint16 marketId, uint256 notional) external view;

    /// @notice Check if a cross-margin takeover can be accepted based on all limits
    /// @param account The account to check
    /// @return canAccept True if all positions fit within limits
    /// @return reason Revert reason if cannot accept (empty if can)
    /// @return marketIds The active cross-margin market IDs
    /// @return notionals The notional values per market (6 decimals)
    /// @return totalNotional The total notional across all markets
    function canAcceptCrossTakeover(
        address account
    )
        external
        view
        returns (
            bool canAccept,
            string memory reason,
            uint16[] memory marketIds,
            uint256[] memory notionals,
            uint256 totalNotional
        );

    /// @notice Preview cross-margin takeover with limit checks (reverts if over limits)
    /// @param account The account to preview
    /// @return marketIds Active cross-margin market IDs
    /// @return notionals Notional values per market (6 decimals)
    /// @return totalNotional Total notional across all markets
    function previewCrossTakeover(
        address account
    )
        external
        view
        returns (
            uint16[] memory marketIds,
            uint256[] memory notionals,
            uint256 totalNotional
        );

    /*//////////////////////////////////////////////////////////////
                        TAKEOVER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Execute cross-margin takeover for a bankrupt account
    /// @dev Requires keeper role. Resets daily counters if new day.
    /// @param account The account to take over
    function executeCrossTakeover(address account) external;

    /// @notice Execute isolated position takeover
    /// @dev Requires keeper role. Uses live position notional for cap checks.
    /// @param account The account to take over
    /// @param marketId The market ID of the isolated position
    function executeIsolatedTakeover(address account, uint16 marketId) external;

    /*//////////////////////////////////////////////////////////////
                       POSITION MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice Transfer position to MM adapter via OTC through adapter
    /// @dev Requires a valid EIP-712 signature from the signer
    /// @param marketId The market ID
    /// @param size The position size to transfer
    /// @param price The OTC price
    /// @param deadline Signature expiration timestamp
    /// @param signature EIP-712 signature authorizing this transfer
    function transferToMM(
        uint16 marketId,
        uint128 size,
        uint128 price,
        uint256 deadline,
        bytes calldata signature
    ) external;

    /*//////////////////////////////////////////////////////////////
                           VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get position in a specific market
    /// @param marketId The market ID
    /// @return pos The decoded position data
    function getPosition(
        uint16 marketId
    ) external view returns (Position memory pos);

    /// @notice Check if strategy has position in a market
    /// @param marketId The market ID
    /// @return True if has non-zero position
    function hasPosition(uint16 marketId) external view returns (bool);

    /// @notice Get position cap for a market (uses default if not set)
    /// @param marketId The market ID
    /// @return Position cap in 6 decimals
    function getMarketPositionCap(
        uint16 marketId
    ) external view returns (uint256);

    /// @notice Get daily cap for a market in absolute terms
    /// @param marketId The market ID
    /// @return Daily cap in 6 decimals
    function getMarketDailyCap(uint16 marketId) external view returns (uint256);

    /// @notice Get global daily cap in absolute terms
    /// @return Global daily cap in 6 decimals
    function getGlobalDailyCap() external view returns (uint256);

    /// @notice Check if adapter equity query is functional
    /// @return True if equity can be queried
    function canQueryEquity() external view returns (bool);

    /// @notice Get the MM adapter address
    /// @return MM adapter address
    function getMmAdapter() external view returns (address);

    /// @notice Returns true if all takeover cap checks are disabled
    function isCapsDisabled() external view returns (bool);

    /// @notice Get the global daily cap in BPS
    /// @return Cap in basis points
    function getGlobalDailyCapBps() external view returns (uint16);

    /// @notice Get the default market daily cap in BPS
    /// @return Cap in basis points
    function getDefaultMarketDailyCapBps() external view returns (uint16);

    /// @notice Get the last daily reset timestamp
    /// @return Timestamp of last reset (aligned to 00:00 UTC)
    function getLastResetTimestamp() external view returns (uint32);

    /// @notice Get the default position cap
    /// @return Cap in 6 decimals
    function getDefaultPositionCap() external view returns (uint128);

    /// @notice Get the daily global exposure
    /// @return Exposure in 6 decimals
    function getDailyGlobalExposure() external view returns (uint128);

    /// @notice Get market limit config for a market
    /// @param marketId The market ID
    /// @return positionCap Max notional per takeover (6 dec)
    /// @return dailyCapBps Daily cap in BPS
    function getMarketLimitConfig(
        uint16 marketId
    ) external view returns (uint128 positionCap, uint16 dailyCapBps);

    /// @notice Get market daily data for a market
    /// @param marketId The market ID
    /// @return exposure Accumulated exposure today (6 dec)
    /// @return lastResetTimestamp Last lazy reset timestamp
    function getMarketDailyData(
        uint16 marketId
    ) external view returns (uint128 exposure, uint32 lastResetTimestamp);

    /*//////////////////////////////////////////////////////////////
                        MANAGEMENT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Enable or disable all takeover cap checks
    /// @param disabled True to skip all cap checks (position, market daily, global daily)
    function setCapsDisabled(bool disabled) external;

    /// @notice Set position cap for a specific market
    /// @param marketId The market ID
    /// @param cap The cap in 6 decimals (0 to use default)
    function setMarketPositionCap(uint16 marketId, uint128 cap) external;

    /// @notice Set daily cap for a specific market
    /// @param marketId The market ID
    /// @param capBps The cap in basis points (0 to use default)
    function setMarketDailyCapBps(uint16 marketId, uint16 capBps) external;

    /// @notice Set global daily cap
    /// @param capBps The cap in basis points
    function setGlobalDailyCapBps(uint16 capBps) external;

    /// @notice Set default position cap for markets without specific cap
    /// @param cap The default cap in 6 decimals
    function setDefaultPositionCap(uint128 cap) external;

    /// @notice Set default market daily cap
    /// @param capBps The default cap in basis points
    function setDefaultMarketDailyCapBps(uint16 capBps) external;

    /// @notice Set the MM adapter address for OTC transfers
    /// @param newMmAdapter The MM adapter address
    function setMMAdapter(address newMmAdapter) external;

    /// @notice Reset daily counters if new day started
    function resetDailyCountersIfNeeded() external;

    /// @notice Manually reset a specific market's daily exposure
    /// @param marketId The market ID
    function resetMarketDailyExposure(uint16 marketId) external;
}
