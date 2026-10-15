// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

interface ISFNConfigurationEntry {
    function sfnSetMinDepositAmount(
        uint32 productId,
        uint128 minDepositAmount
    ) external;

    function sfnSetMinWithdrawalAmount(
        uint32 productId,
        uint128 minWithdrawalAmount
    ) external;

    function sfnSetMaxUnderlyingAmountLimit(
        uint32 productId,
        uint128 maxUnderlyingAmountLimit
    ) external;

    function sfnSetIsDepositQueueOpen(
        uint32 productId,
        bool isDepositQueueOpen
    ) external;

    function sfnSetLateFeeBps(uint32 productId, uint16 lateFeeBps) external;

    function sfnSetHoursToStartLateFees(
        uint32 productId,
        uint8 hoursToStartLateFees
    ) external;

    function sfnSetHoursToStartAuctionDefault(
        uint32 productId,
        uint8 hoursToStartAuctionDefault
    ) external;

    function sfnSetHoursToStartSettlementDefault(
        uint32 productId,
        uint8 hoursToStartSettlementDefault
    ) external;

    function sfnSetDisputePeriodInHours(
        uint32 productId,
        uint8 disputePeriodInHours
    ) external;

    function sfnSetDisputeGraceDelayInHours(
        uint32 productId,
        uint8 disputeGraceDelayInHours
    ) external;
}
