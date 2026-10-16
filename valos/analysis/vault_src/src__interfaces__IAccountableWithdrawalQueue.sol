// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

/// @notice Struct tracking a withdrawal request
struct WithdrawalRequest {
    /// @notice The number of shares requested
    uint256 shares;
    /// @notice The controller of the request
    address controller;
}

/// @notice Struct tracking the withdrawal queue
struct WithdrawalQueue {
    /// @notice The next request ID to be processed
    uint128 nextRequestId;
    /// @notice The last request ID to be processed
    uint128 lastRequestId;
    /// @notice The mapping of request IDs to withdrawal requests
    mapping(uint128 requestId => WithdrawalRequest request) requests;
}

/// @notice Interface for the withdrawal queue
interface IAccountableWithdrawalQueue {
    /// @notice Fulfill a redeem request
    /// @param controller The controller of the request
    /// @param shares The number of shares to fulfill
    function fulfillRedeemRequest(address controller, uint256 shares) external;

    /// @notice Process up to `maxShares` shares
    /// @param maxShares The maximum number of shares to process
    /// @return assetsUsed The number of assets used to process the shares
    function processUpToShares(uint256 maxShares) external returns (uint256 assetsUsed);

    /// @notice Process up to `maxRequestId` request
    /// @param maxRequestId The last request ID to process
    /// @return processedShares The number of shares that were processed
    /// @return assetsUsed The number of assets used to process the shares
    function processUpToRequestId(uint256 maxRequestId)
        external
        returns (uint256 processedShares, uint256 assetsUsed);

    /// @notice Preview required shares that can be processed with `maxAssets`
    /// @param maxAssets The maximum number of assets to be matched with `maxAssets`
    /// @return processedShares The number of shares that can be processed with the assets
    /// @return assetsUsed The number of assets used to process the shares
    function previewRequiredShares(uint256 maxAssets)
        external
        view
        returns (uint256 processedShares, uint256 assetsUsed);

    /// @notice Preview the last request ID that can be processed with `maxAssets`
    /// @param maxAssets The maximum number of assets to be matched with `maxAssets`
    /// @return maxRequestId The last request ID that can be processed with the assets
    /// @return assetsUsed The number of assets used to process the shares
    function previewMaxRequestId(uint256 maxAssets) external view returns (uint256 maxRequestId, uint256 assetsUsed);

    /// @notice Get the total number of shares queued
    /// @return totalQueuedShares The total number of shares queued
    function totalQueuedShares() external view returns (uint256 totalQueuedShares);

    /// @notice Get the reserved liquidity
    /// @return reservedLiquidity The reserved liquidity
    function reservedLiquidity() external view returns (uint256 reservedLiquidity);

    /// @notice Get the withdrawal queue indices
    /// @return nextRequestId The next request ID to be processed
    /// @return lastRequestId The last request ID to be processed
    function queue() external view returns (uint128 nextRequestId, uint128 lastRequestId);

    /// @notice Get the withdrawal request for a controller
    /// @param controller The controller of the request
    /// @return request The withdrawal request
    function withdrawalRequest(address controller) external view returns (WithdrawalRequest memory request);

    /// @notice Get the withdrawal requests
    /// @param start The start index of the queue
    /// @param end The end index of the queue
    /// @return requests The withdrawal requests
    function withdrawalRequests(uint128 start, uint128 end)
        external
        view
        returns (WithdrawalRequest[] memory requests);
}
