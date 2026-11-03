// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../utils/Constants.sol";
import "../interfaces/IOfflineClear.sol";
import "../interfaces/ITrading.sol";
import {RequestType, IPriceFacade} from "../interfaces/IPriceFacade.sol";
import "../libraries/LibAccessControlEnumerable.sol";
import "../libraries/LibTrading.sol";
import "../libraries/LibLimitOrder.sol";
import {ZERO, ONE, UC, uc, into} from "unchecked-counter/src/UC.sol";

// AP-13746 APX V2 offline clearing facet: admin closes leftover positions and cancels leftover
// limit orders on behalf of users.
// Design notes:
//  - Only ADMIN_ROLE may call (the normal path requires msg.sender to be the holder; here that check
//    is replaced by a role check).
//  - Closing keeps the existing async two-step flow: this facet only registers a CLOSE price request;
//    the second step is a normal PRICE_FEEDER feed that triggers closeTradeCallback to settle at the
//    fed market price and returns funds to ot.user. So this facet changes no settlement logic.
//  - Compared with the user-facing closeTrade, this deliberately bypasses the userCloseTrading switch
//    and the pair==CLOSE gate so clearing still works even if those switches are later turned off;
//    only the margin>0 validity check is kept.
//  - Cancelling completes synchronously and refunds the principal to the order owner.
//  - Batch-friendly: positions/orders that no longer exist are silently skipped instead of reverting
//    the whole batch.
contract OfflineClearFacet is IOfflineClear {

    function closeTradeByAdmin(bytes32[] calldata tradeHashes) external override {
        LibAccessControlEnumerable.checkRole(Constants.ADMIN_ROLE);
        LibTrading.TradingStorage storage ts = LibTrading.tradingStorage();
        for (UC i = ZERO; i < uc(tradeHashes.length); i = i + ONE) {
            bytes32 tradeHash = tradeHashes[i.into()];
            ITrading.OpenTrade storage ot = ts.openTrades[tradeHash];
            // Skip if already closed / nonexistent (may have been handled between scan and execution)
            if (ot.margin == 0) {
                continue;
            }
            // Deliberately skip the userCloseTrading and pair-status checks: offline clearing must run
            // under any market switch state. deltaQty matches the user-facing closeTrade (reduce OI).
            IPriceFacade(address(this)).requestPrice(
                tradeHash, ot.pairBase, RequestType.CLOSE,
                ot.isLong ? -(int256(uint256(ot.qty))) : int256(uint256(ot.qty))
            );
            emit AdminCloseTradeRequested(msg.sender, tradeHash, ot.user);
        }
    }

    function cancelLimitOrderByAdmin(bytes32[] calldata orderHashes) external override {
        LibAccessControlEnumerable.checkRole(Constants.ADMIN_ROLE);
        for (UC i = ZERO; i < uc(orderHashes.length); i = i + ONE) {
            bytes32 orderHash = orderHashes[i.into()];
            if (LibLimitOrder.cancelLimitOrderByOperator(orderHash)) {
                emit AdminCancelLimitOrder(msg.sender, orderHash);
            }
        }
    }
}
