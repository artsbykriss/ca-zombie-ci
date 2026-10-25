// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {AggregatorV3Interface} from "src/Dependencies/AggregatorV3Interface.sol";

/// @notice Immutable, always-fresh Chainlink-compatible price fixture for the persistent Sepolia environment.
/// @dev The answer cannot be changed after deployment. A changing price or failure scenario is exercised by
///      replacing the PriceFeedProxy source through the same timelocked path used in production.
contract SepoliaChainlinkAggregator is AggregatorV3Interface {
    uint256 private constant SEPOLIA_CHAIN_ID = 11155111;

    error InvalidAnswer();
    error WrongChain(uint256 chainId);

    uint8 private immutable _decimals;
    int256 private immutable _answer;

    constructor(uint8 decimals_, int256 answer_) {
        if (block.chainid != SEPOLIA_CHAIN_ID) revert WrongChain(block.chainid);
        if (answer_ <= 0) revert InvalidAnswer();
        _decimals = decimals_;
        _answer = answer_;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80) {
        uint80 roundId = uint80(block.number);
        return (roundId, _answer, block.timestamp, block.timestamp, roundId);
    }
}
