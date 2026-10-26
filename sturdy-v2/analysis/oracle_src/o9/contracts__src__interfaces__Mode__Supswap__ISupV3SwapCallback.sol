// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.21;

/// @title Callback for ISupV3PoolActions#swap
/// @notice Any contract that calls ISupV3PoolActions#swap must implement this interface
interface ISupV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via ISupV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a SUPV3Pool deployed by the canonical SupV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the ISupV3PoolActions#swap call
    function supV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}