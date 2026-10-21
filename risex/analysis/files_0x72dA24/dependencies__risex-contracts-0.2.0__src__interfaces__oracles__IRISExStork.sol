// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import { IAccessManaged } from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";
import { IStork } from "src/interfaces/externals/IStork.sol";
import { IRISExOracle } from "src/interfaces/oracles/IRISExOracle.sol";

interface IRISExStork is IAccessManaged {
    /// @notice Emitted when the Stork contract is set
    event SetStork(address stork);

    /// @notice Emitted when the oracle is set
    event SetOracle(uint16 indexed marketId, bytes32 indexed markPriceId, bytes32 indexed indexPriceId);

    /// @notice Emitted when the token oracle is set
    event SetTokenOracle(address indexed token, bytes32 indexed priceId);

    /// @notice Sets the oracle for a market
    /// @param marketId The ID of the market
    /// @param markPriceId The ID of the mark price
    /// @param indexPriceId The ID of the index price
    function setOracle(
        uint16 marketId,
        bytes32 markPriceId,
        bytes32 indexPriceId
    ) external;

    /// @notice Sets the oracle for a token
    /// @param token The address of the token
    /// @param priceId The ID of the price
    function setTokenOracle(
        address token,
        bytes32 priceId
    ) external;

    /// @notice Gets the price for a token
    /// @param token The address of the token
    /// @return The price
    function getTokenPrice(
        address token
    ) external view returns (uint256);

    /// @notice Gets the mark price for a market
    /// @param marketId The ID of the market
    /// @return The mark price
    function getMarkPrice(
        uint16 marketId
    ) external view returns (uint256);

    /// @notice Gets the index price for a market
    /// @param marketId The ID of the market
    /// @return The index price
    function getIndexPrice(
        uint16 marketId
    ) external view returns (uint256);

    /// @notice Sets the Stork contract
    /// @param stork The address of the Stork contract
    function setStork(
        address stork
    ) external;

    /// @notice Returns the Stork contract
    function getStork() external view returns (IStork);

    /// @notice Returns the RISExOracle contract
    function getRisexOracle() external view returns (IRISExOracle);

    /// @notice Returns the mark price ID for a market
    /// @param marketId The market ID
    function getMarkPriceId(
        uint16 marketId
    ) external view returns (bytes32);

    /// @notice Returns the index price ID for a market
    /// @param marketId The market ID
    function getIndexPriceId(
        uint16 marketId
    ) external view returns (bytes32);

    /// @notice Returns the price ID for a token
    /// @param token The token address
    function getTokenPriceId(
        address token
    ) external view returns (bytes32);

    /// @notice Emitted when the max price age is updated
    event SetMaxPriceAge(uint64 maxPriceAgeNs);

    /// @notice Sets the maximum allowed price age for staleness checks
    /// @param maxPriceAgeNs Maximum age in nanoseconds (0 = disabled)
    function setMaxPriceAge(
        uint64 maxPriceAgeNs
    ) external;

    /// @notice Returns the effective max price age in nanoseconds
    function getMaxPriceAge() external view returns (uint64);
}
