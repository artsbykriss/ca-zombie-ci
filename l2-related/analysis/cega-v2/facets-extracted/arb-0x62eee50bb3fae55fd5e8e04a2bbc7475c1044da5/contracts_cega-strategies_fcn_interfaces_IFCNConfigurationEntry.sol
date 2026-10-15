// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

interface IFCNConfigurationEntry {
    function fcnSetLateFeeBps(uint32 productId, uint16 lateFeeBps) external;

    function fcnSetMinDepositAmount(
        uint32 productId,
        uint128 minDepositAmount
    ) external;

    function fcnSetMinWithdrawalAmount(
        uint32 productId,
        uint128 minWithdrawalAmount
    ) external;

    function fcnSetIsDepositQueueOpen(
        uint32 productId,
        bool isDepositQueueOpen
    ) external;

    function fcnSetHoursToStartLateFees(
        uint32 productId,
        uint8 hoursToStartLateFees
    ) external;

    function fcnSetHoursToStartAuctionDefault(
        uint32 productId,
        uint8 hoursToStartAuctionDefault
    ) external;

    function fcnSetHoursToStartSettlementDefault(
        uint32 productId,
        uint8 hoursToStartSettlementDefault
    ) external;

    function fcnSetMaxUnderlyingAmountLimit(
        uint32 productId,
        uint128 maxUnderlyingAmountLimit
    ) external;

    function fcnSetDisputePeriodInHours(
        uint32 productId,
        uint8 disputePeriodInHours
    ) external;

    function fcnSetDisputeGraceDelayInHours(
        uint32 productId,
        uint8 disputeGraceDelayInHours
    ) external;
}
