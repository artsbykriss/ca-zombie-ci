// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.24;

interface ISwapManager {
    enum SwapProtocol {
        None,
        UniswapV3
    }

    struct SwapData {
        uint256 deadline;
        uint128 minOutputAmount;
        bytes extraData;
    }

    event SwapProtocolAdapterUpdated(
        SwapProtocol swapProtocol,
        address adapter
    );

    event Swapped(
        address fromAsset,
        address toAsset,
        uint128 amount,
        address receiver,
        SwapProtocol swapProtocol,
        SwapData swapData
    );

    /**
     * @notice Gets adapter address for swap protocol
     * @param swapProtocol Swap protocol
     * @return Address of the adapter
     */
    function swapProtocolAdapters(
        SwapProtocol swapProtocol
    ) external view returns (address);

    /**
     * @notice Sets (or resets) adapter for swap protocol
     * @param swapProtocol Swap protocol
     * @param adapter Address of the adapter contract
     */
    function setSwapProtocolAdapter(
        SwapProtocol swapProtocol,
        address adapter
    ) external;

    /**
     * @notice Swaps with given params
     * @param fromAsset Input asset
     * @param toAsset Output asset
     * @param amount Amount to swap
     * @param receiver Address to receive the swap
     * @param swapProtocol Protocol to use for the swap
     * @param swapData Other data for the swap
     */
    function swap(
        address fromAsset,
        address toAsset,
        uint128 amount,
        address receiver,
        SwapProtocol swapProtocol,
        SwapData calldata swapData
    ) external returns (uint128 outputAmount);
}
