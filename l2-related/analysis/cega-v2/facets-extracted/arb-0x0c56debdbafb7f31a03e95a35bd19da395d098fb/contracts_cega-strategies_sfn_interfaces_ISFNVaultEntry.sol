// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import {
    IOracleEntry
} from "../../../oracle-entry/interfaces/IOracleEntry.sol";
import { SFNEndAuctionParams } from "../SFNStructs.sol";

interface ISFNVaultEntry {
    function sfnEndAuction(SFNEndAuctionParams calldata params) external;

    function sfnStartTrade(address vaultAddress) external payable;

    function sfnCheckBarriers(
        address vaultAddress,
        uint16 maxObservations
    ) external;

    function sfnCheckTradeExpiry(address vaultAddress) external;

    function sfnCollectVaultFees(address vaultAddress) external;

    function sfnRolloverVault(address vaultAddress) external;

    function sfnSubmitDispute(address vaultAddress, uint40 timestamp) external;

    function sfnProcessTradeDispute(
        address vaultAddress,
        uint40 timestamp,
        bool accept,
        uint128[] calldata newPrices
    ) external;

    function sfnCheckSettlementDefault(address vaultAddress) external;

    function sfnCheckAuctionDefault(address vaultAddress) external;

    function sfnSettleVault(address vaultAddress) external payable;
}
