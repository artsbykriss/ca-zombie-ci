// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

interface IDCSConfigurationEntry {
    /**
     * @dev Sets the late fee basis points for a specific product.
     * @param lateFeeBps The late fee in basis points.
     * @param productId The ID of the product.
     */
    function dcsSetLateFeeBps(uint16 lateFeeBps, uint32 productId) external;

    /**
     * @dev Sets the minimum deposit amount for a specific product.
     * @param minDepositAmount The minimum deposit amount.
     * @param productId The ID of the product.
     */
    function dcsSetMinDepositAmount(
        uint128 minDepositAmount,
        uint32 productId
    ) external;

    /**
     * @dev Sets the minimum withdrawal amount for a specific product.
     * @param minWithdrawalAmount The minimum withdrawal amount.
     * @param productId The ID of the product.
     */
    function dcsSetMinWithdrawalAmount(
        uint128 minWithdrawalAmount,
        uint32 productId
    ) external;

    /**
     * @dev Sets whether the deposit queue is open for a specific product.
     * @param isDepositQueueOpen True if the deposit queue is open.
     * @param productId The ID of the product.
     */
    function dcsSetIsDepositQueueOpen(
        bool isDepositQueueOpen,
        uint32 productId
    ) external;

    /**
     * @dev Sets the number of days to start charging late fees for a specific product.
     * @param productId The ID of the product.
     * @param hoursToStartLateFees The number of days to start late fees.
     */
    function dcsSetHoursToStartLateFees(
        uint32 productId,
        uint8 hoursToStartLateFees
    ) external;

    /**
     * @dev Sets the number of days to start auction default for a specific product.
     * @param productId The ID of the product.
     * @param hoursToStartAuctionDefault The number of days to start auction default.
     */
    function dcsSetHoursToStartAuctionDefault(
        uint32 productId,
        uint8 hoursToStartAuctionDefault
    ) external;

    /**
     * @dev Sets the number of days to start settlement default for a specific product.
     * @param productId The ID of the product.
     * @param hoursToStartSettlementDefault The number of days to start settlement default.
     */
    function dcsSetHoursToStartSettlementDefault(
        uint32 productId,
        uint8 hoursToStartSettlementDefault
    ) external;

    /**
     * @dev Sets the maximum underlying amount for a specific product.
     * @param maxUnderlyingAmountLimit The maximum underlying amount limit.
     * @param productId The ID of the product.
     */
    function dcsSetMaxUnderlyingAmount(
        uint128 maxUnderlyingAmountLimit,
        uint32 productId
    ) external;

    /**
     * @dev Sets the dispute period in hours for a specific product.
     * @param productId The ID of the product.
     * @param disputePeriodInHours The dispute period in hours.
     */
    function dcsSetDisputePeriodInHours(
        uint32 productId,
        uint8 disputePeriodInHours
    ) external;

    /**
     * @notice Sets dispute grace period for the product
     * @param productId ID of the product
     * @param disputeGraceDelayInHours Dispute period in hours
     */
    function dcsSetDisputeGraceDelayInHours(
        uint32 productId,
        uint8 disputeGraceDelayInHours
    ) external;
}
