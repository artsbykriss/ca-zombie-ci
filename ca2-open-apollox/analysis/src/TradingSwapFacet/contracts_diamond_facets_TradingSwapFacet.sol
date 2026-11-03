// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../security/OnlySelf.sol";
import "../interfaces/ITradingSwap.sol";
import "../interfaces/ITradingChecker.sol";
import "../libraries/LibTrading.sol";
import {ITradingPortalError} from "../../utils/Errors.sol";
import "../libraries/LibAccessControlEnumerable.sol";
import "../libraries/LibSwapManager.sol";


contract TradingSwapFacet is ITradingSwap, OnlySelf, ITradingPortalError {

    function setOneInchAggregationRouter(address oneInchAggregationRouter) external {
        LibAccessControlEnumerable.checkRole(Constants.ADMIN_ROLE);
        require(oneInchAggregationRouter != address(0), "oneInchAggregationRouter cannot be a zero address");
        LibSwapManager.setOneInchAggregationRouter(oneInchAggregationRouter);
    }

    function swapAndOpenMarketTrade(bytes calldata swapData, OpenDataInput memory data) external override returns (bytes32 tradeHash) {
        uint96 amount = LibSwapManager.oneInchSwap(swapData, data);
        data.amountIn = amount;
        return _openMarketTrade(data);
    }

    function _openMarketTrade(OpenDataInput memory data) private returns (bytes32 tradeHash) {
        ITradingChecker(address(this)).openMarketTradeCheck(data);

        LibTrading.TradingStorage storage ts = LibTrading.tradingStorage();
        address user = msg.sender;
        ITrading.PendingTrade memory pt = ITrading.PendingTrade(
            user, data.broker, data.isLong, data.price, data.pairBase, data.amountIn,
            data.tokenIn, data.qty, data.stopLoss, data.takeProfit, uint128(block.number)
        );
        tradeHash = keccak256(abi.encode(pt, ts.salt, "trade"));
        ts.salt++;
        ts.pendingTrades[tradeHash] = pt;
        //after swap, the swap has given the funds to this contract.
        //data.tokenIn.transferFrom(user, data.amountIn);
        ts.pendingTradeAmountIns[data.tokenIn] += data.amountIn;
        IPriceFacade(address(this)).requestPrice(tradeHash, data.pairBase, RequestType.OPEN, data.isLong ? int256(uint256(data.qty)) : -(int256(uint256(data.qty))));
        emit MarketPendingTrade(user, tradeHash, data);
        return tradeHash;
    }
}
