// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import {
    IOracleEntry
} from "../../../oracle-entry/interfaces/IOracleEntry.sol";

interface IFCNBulkActionsEntry {
    function fcnBulkProcessDepositQueues(
        address[] calldata vaultAddresses,
        uint256 maxProcessCount
    ) external;

    function fcnBulkProcessWithdrawalQueues(
        address[] calldata vaultAddresses,
        uint256 maxProcessCount
    ) external;

    function fcnBulkEndAuctions(
        address[] calldata vaultAddresses,
        address[] calldata auctionWinners,
        uint40[] calldata tradeStartDates,
        uint16[] calldata aprBps,
        IOracleEntry.DataSource[][] calldata dataSources
    ) external;

    function fcnBulkStartTrades(
        address[] calldata vaultAddresses
    ) external payable;

    function fcnBulkCheckBarriers(
        address[] calldata vaultAddresses,
        uint16 maxObservations
    ) external;

    function fcnBulkCheckTradesExpiry(
        address[] calldata vaultAddresses
    ) external;

    function fcnBulkRepayBonds(
        address[] calldata vaultAddresses,
        uint128[] calldata amounts
    ) external payable;

    function fcnBulkSettleVaults(
        address[] calldata vaultAddresses
    ) external payable;

    function fcnBulkCollectFees(address[] calldata vaultAddresses) external;

    function fcnBulkRolloverVaults(address[] calldata vaultAddresses) external;

    function fcnBulkCheckSettlementDefault(
        address[] calldata vaultAddresses
    ) external;

    function fcnBulkCheckAuctionDefault(
        address[] calldata vaultAddresses
    ) external;
}
