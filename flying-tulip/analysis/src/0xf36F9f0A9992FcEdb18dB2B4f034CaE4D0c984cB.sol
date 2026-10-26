// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2025 Flying Tulip Inc. All rights reserved.
pragma solidity ^0.8.30;

import {AggregatorV3Interface} from "./OracleRouterChainlink.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";

interface IChainlinkLatestAnswer {
    function latestAnswer() external view returns (int256);
    function decimals() external view returns (uint8);
}

/// @title ChainlinkLatestAnswerProxy
/// @notice AggregatorV3-compatible adapter for Chainlink wrappers that expose `latestAnswer()` but not
///         `latestRoundData()`.
/// @dev Returns round timing/ids from the base EACAggregatorProxy feed, while sourcing `answer` from
///      the adapter's `latestAnswer()`.
///      Includes optional fail-fast protections (pause, staleness, bounds).
contract ChainlinkLatestAnswerProxy is AggregatorV3Interface, Ownable2Step {
    error ZeroAddress();
    error NotAContract(address a);
    error Paused();
    error BaseRoundIncomplete(uint80 roundId, uint80 answeredInRound, uint256 updatedAt);
    error BaseRoundStale(uint256 updatedAt, uint32 maxStaleness);
    error NonPositiveAnswer(int256 answer);
    error AnswerOutOfBounds(int256 answer, int256 minAnswer, int256 maxAnswer);
    error InvalidAnswerBounds(int256 minAnswer, int256 maxAnswer);
    error AdapterDecimalsUnavailable();

    event PausedSet(bool paused);
    event StrictDecimalsSet(bool enabled);
    event RequirePositiveAnswerSet(bool enabled);
    event AnswerBoundsSet(bool enabled, int256 minAnswer, int256 maxAnswer);
    event MaxStalenessSet(uint32 maxStaleness);

    AggregatorV3Interface public immutable baseFeed;
    address public immutable adapter;

    bool public paused;
    bool public strictDecimals;
    bool public requirePositiveAnswer;
    bool public boundsEnabled;
    uint32 public maxStaleness; // 0 = disabled
    int256 public minAnswer;
    int256 public maxAnswer;

    constructor(address _baseFeed, address _adapter, address initialOwner) Ownable(initialOwner) {
        if (_baseFeed == address(0) || _adapter == address(0)) revert ZeroAddress();
        if (_baseFeed.code.length == 0) revert NotAContract(_baseFeed);
        if (_adapter.code.length == 0) revert NotAContract(_adapter);
        baseFeed = AggregatorV3Interface(_baseFeed);
        adapter = _adapter;

        // Fail-fast by default: prices must be positive.
        requirePositiveAnswer = true;
    }

    /*//////////////////////////////////////////////////////////////
                                ADMIN
    //////////////////////////////////////////////////////////////*/

    function setPaused(bool paused_) external onlyOwner {
        paused = paused_;
        emit PausedSet(paused_);
    }

    function setStrictDecimals(bool enabled) external onlyOwner {
        strictDecimals = enabled;
        emit StrictDecimalsSet(enabled);
    }

    function setRequirePositiveAnswer(bool enabled) external onlyOwner {
        requirePositiveAnswer = enabled;
        emit RequirePositiveAnswerSet(enabled);
    }

    function setAnswerBounds(int256 minAnswer_, int256 maxAnswer_) external onlyOwner {
        if (minAnswer_ > maxAnswer_) revert InvalidAnswerBounds(minAnswer_, maxAnswer_);
        boundsEnabled = true;
        minAnswer = minAnswer_;
        maxAnswer = maxAnswer_;
        emit AnswerBoundsSet(true, minAnswer_, maxAnswer_);
    }

    function disableAnswerBounds() external onlyOwner {
        boundsEnabled = false;
        emit AnswerBoundsSet(false, minAnswer, maxAnswer);
    }

    function setMaxStaleness(uint32 maxStaleness_) external onlyOwner {
        maxStaleness = maxStaleness_;
        emit MaxStalenessSet(maxStaleness_);
    }

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
        if (paused) revert Paused();

        (roundId,, startedAt, updatedAt, answeredInRound) = baseFeed.latestRoundData();

        if (answeredInRound < roundId || updatedAt == 0 || updatedAt > block.timestamp) {
            revert BaseRoundIncomplete(roundId, answeredInRound, updatedAt);
        }

        uint32 maxStale = maxStaleness;
        if (maxStale != 0 && block.timestamp - updatedAt > maxStale) {
            revert BaseRoundStale(updatedAt, maxStale);
        }

        answer = IChainlinkLatestAnswer(adapter).latestAnswer();

        if (requirePositiveAnswer && answer <= 0) revert NonPositiveAnswer(answer);
        if (boundsEnabled && (answer < minAnswer || answer > maxAnswer)) {
            revert AnswerOutOfBounds(answer, minAnswer, maxAnswer);
        }
    }

    function decimals() external view returns (uint8) {
        try IChainlinkLatestAnswer(adapter).decimals() returns (uint8 d) {
            return d;
        } catch {
            if (strictDecimals) revert AdapterDecimalsUnavailable();
            return baseFeed.decimals();
        }
    }
}
