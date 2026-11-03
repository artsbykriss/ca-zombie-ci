// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IBook.sol";
import "./ITrading.sol";

interface ITradingSwap is ITrading, IBook {

    event MarketPendingTrade(address indexed user, bytes32 indexed tradeHash, OpenDataInput trade);

    function setOneInchAggregationRouter(address oneInchAggregationRouter) external;

    function swapAndOpenMarketTrade(bytes calldata swapData, OpenDataInput memory data) external returns (bytes32 tradeHash);

}
