// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import {
    IOracleEntry
} from "../../../oracle-entry/interfaces/IOracleEntry.sol";
import { SFNEndAuctionParams } from "../SFNStructs.sol";

interface ISFNBulkActionsEntry {
    function sfnBulkProcessDepositQueues(
        address[] calldata vaultAddresses,
        uint256 maxProcessCount
    ) external;

    function sfnBulkProcessWithdrawalQueues(
        address[] calldata vaultAddresses,
        uint256 maxProcessCount
    ) external;

    function sfnBulkEndAuctions(SFNEndAuctionParams[] calldata params) external;

    function sfnBulkStartTrades(
        address[] calldata vaultAddresses
    ) external payable;

    function sfnBulkCheckBarriers(
        address[] calldata vaultAddresses,
        uint16 maxObservations
    ) external;

    function sfnBulkCheckTradesExpiry(
        address[] calldata vaultAddresses
    ) external;

    function sfnBulkSettleVaults(
        address[] calldata vaultAddresses
    ) external payable;

    function sfnBulkCollectFees(address[] calldata vaultAddresses) external;

    function sfnBulkRolloverVaults(address[] calldata vaultAddresses) external;

    function sfnBulkCheckSettlementDefault(
        address[] calldata vaultAddresses
    ) external;

    function sfnBulkCheckAuctionDefault(
        address[] calldata vaultAddresses
    ) external;
}
