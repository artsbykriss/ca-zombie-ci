pragma solidity ^0.8.30;

import {Ownable, Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {AggregatorV3Interface} from "./OracleRouterChainlink.sol";

/// @title FtCappedOracle
/// @notice Reports the FT/USD NAV set by governance in 18-decimal USD units.
/// @dev NAV remains effective until governance sets another value. Round IDs track governance
///      updates; startedAt records the last NAV update and updatedAt is the current observation
///      time. This allows the fixed NAV to remain usable by routers with heartbeat checks.
contract FtCappedOracle is AggregatorV3Interface, Ownable2Step {
    using SafeCast for uint256;

    uint256 public constant DEFAULT_NAV_CAP_WAD = 93_600_000_000_000_000; // $0.0936

    error InvalidNavCap(uint256 capWad);

    event NavCapSet(uint256 previousCapWad, uint256 newCapWad);

    uint256 public navCapWad;
    uint80 public navRoundId;
    uint256 public navUpdatedAt;

    /// @param initialOwner Governance address authorized to set the FT NAV.
    constructor(address initialOwner) Ownable(initialOwner) {
        navCapWad = DEFAULT_NAV_CAP_WAD;
        navRoundId = 1;
        navUpdatedAt = block.timestamp;
        emit NavCapSet(0, DEFAULT_NAV_CAP_WAD);
    }

    /// @notice Set the USD NAV per FT in WAD (18 decimals), effective until the next update.
    function setNavCap(uint256 capWad) external onlyOwner {
        if (capWad == 0 || capWad > uint256(type(int256).max)) revert InvalidNavCap(capWad);
        uint256 previousCapWad = navCapWad;
        navCapWad = capWad;
        navRoundId += 1;
        navUpdatedAt = block.timestamp;
        emit NavCapSet(previousCapWad, capWad);
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    /// @dev updatedAt is observation time, not the time governance last changed NAV.
    ///      Use navUpdatedAt or startedAt to inspect the actual governance update time.
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (navRoundId, navCapWad.toInt256(), navUpdatedAt, block.timestamp, navRoundId);
    }
}
