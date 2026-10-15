// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import {
    IOracleEntry
} from "../../../oracle-entry/interfaces/IOracleEntry.sol";

interface IFCNVaultEntry {
    function fcnEndAuction(
        address vaultAddress,
        address auctionWinner,
        uint40 tradeStartDate,
        uint16 aprBps,
        IOracleEntry.DataSource[] calldata dataSources
    ) external;

    function fcnStartTrade(address vaultAddress) external payable;

    function fcnCheckBarriers(
        address vaultAddress,
        uint16 maxObservations
    ) external;

    function fcnCheckTradeExpiry(address vaultAddress) external;

    function fcnRepayBond(
        address vaultAddress,
        uint128 amount
    ) external payable;

    function fcnSettleVault(address vaultAddress) external payable;

    function fcnCollectVaultFees(address vaultAddress) external;

    function fcnRolloverVault(address vaultAddress) external;

    function fcnCheckSettlementDefault(address vaultAddress) external;

    function fcnCheckAuctionDefault(address vaultAddress) external;

    function fcnSubmitDispute(
        address vaultAddress,
        uint8 barrierIndex,
        uint40 timestamp
    ) external;

    function fcnProcessTradeDispute(
        address vaultAddress,
        uint8 barrierIndex,
        uint40 timestamp,
        uint128 newPrice
    ) external;
}
