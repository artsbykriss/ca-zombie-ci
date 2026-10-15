// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { Withdrawer, VaultStatus } from "../../../Structs.sol";
import { DCSProductCreationParams, DCSProduct } from "../DCSStructs.sol";
import {
    IOracleEntry
} from "../../../oracle-entry/interfaces/IOracleEntry.sol";

interface IDCSBulkActionsEntry {
    function dcsBulkEndAuctions(
        address[] calldata vaultAddresses,
        address[] calldata auctionWinners,
        uint40[] calldata tradeStartDates,
        uint16[] calldata aprBps,
        IOracleEntry.DataSource[] calldata dataSources
    ) external;

    /**
     * @dev Starts trading for multiple vaults in bulk.
     * @param vaultAddresses Array of vault addresses to start trading for.
     */
    function dcsBulkStartTrades(
        address[] calldata vaultAddresses
    ) external payable;

    /**
     * @dev Processes the deposit queues for multiple vaults in bulk.
     * @param vaultAddresses Array of vault addresses to process deposit queues for.
     * @param maxProcessCount The maximum number of deposits to process for each vault.
     */
    function dcsBulkProcessDepositQueues(
        address[] calldata vaultAddresses,
        uint256 maxProcessCount
    ) external;

    /**
     * @dev Processes the withdrawal queues for multiple vaults in bulk.
     * @param vaultAddresses Array of vault addresses to process withdrawal queues for.
     * @param maxProcessCount The maximum number of withdrawals to process for each vault.
     */
    function dcsBulkProcessWithdrawalQueues(
        address[] calldata vaultAddresses,
        uint256 maxProcessCount
    ) external;

    /**
     * @dev Rolls over multiple vaults to the next cycle in bulk.
     * @param vaultAddresses Array of vault addresses to roll over.
     */
    function dcsBulkRolloverVaults(
        address[] calldata vaultAddresses,
        uint256 maxProcessCount
    ) external;

    /**
     * @dev Checks and handles trade expiry for multiple vaults in bulk.
     * @param vaultAddresses Array of vault addresses to check for trade expiry.
     */
    function dcsBulkCheckTradesExpiry(
        address[] calldata vaultAddresses
    ) external;

    /**
     * @dev Checks and handles auction default for multiple vaults in bulk.
     * @param vaultAddresses Array of vault addresses to check for auction default.
     */
    function dcsBulkCheckAuctionDefault(
        address[] calldata vaultAddresses
    ) external;

    /**
     * @dev Checks and handles settlement default for multiple vaults in bulk.
     * @param vaultAddresses Array of vault addresses to check for settlement default.
     */
    function dcsBulkCheckSettlementDefault(
        address[] calldata vaultAddresses
    ) external;

    /**
     * @dev Settles multiple vaults in bulk.
     * @param vaultAddresses Array of vault addresses to settle.
     */
    function dcsBulkSettleVaults(
        address[] calldata vaultAddresses
    ) external payable;

    /**
     * @dev Collects fees from multiple vaults in bulk.
     * @param vaultAddresses Array of vault addresses to collect fees from.
     */
    function dcsBulkCollectFees(address[] calldata vaultAddresses) external;
}
