// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import { IRISExAdapter } from "risex-adapter/interfaces/IRISExAdapter.sol";

/// @title IRISExAdapterConnector
/// @notice Version-specific RISEx call encoder/decoder used by a fixed adapter account.
/// @dev The connector is stateless. The adapter remains the caller for all external interactions.
interface IRISExAdapterConnector {
    /*//////////////////////////////////////////////////////////////////////////
                                    STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice A low-level call descriptor returned by buildCall.
    /// @param target The contract to call.
    /// @param value The ETH value to send.
    /// @param data The ABI-encoded calldata.
    struct Call {
        address target;
        uint256 value;
        bytes data;
    }

    /// @notice The set of RISEx protocol endpoint addresses.
    /// @param collateralManager The CollateralManager proxy address.
    /// @param ordersManager The OrdersManager proxy address.
    /// @param perpsManager The PerpsManager proxy address.
    /// @param accountRegistry The AccountRegistry proxy address.
    struct EndpointSet {
        address collateralManager;
        address ordersManager;
        address perpsManager;
        address accountRegistry;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when the requested action is not supported by this connector version.
    /// @param action The unsupported action.
    error UnsupportedAction(IRISExAdapter.Action action);

    /// @notice Thrown when the size in steps exceeds uint32 after division.
    /// @param size The raw size value.
    /// @param stepSize The step size divisor.
    error SizeOverflow(uint128 size, uint64 stepSize);

    /// @notice Thrown when the size is not exactly divisible by the step size.
    /// @param size The raw size value.
    /// @param stepSize The step size divisor.
    error SizeNotAligned(uint128 size, uint64 stepSize);

    /// @notice Thrown when the price in ticks exceeds uint24 after division.
    /// @param price The raw price value.
    /// @param stepPrice The step price divisor.
    error PriceOverflow(uint128 price, uint64 stepPrice);

    /// @notice Thrown when the price is not exactly divisible by the step price.
    /// @param price The raw price value.
    /// @param stepPrice The step price divisor.
    error PriceNotAligned(uint128 price, uint64 stepPrice);

    /// @notice Thrown when the book config query to OrdersManager fails or returns zero.
    error BookConfigQueryFailed();

    /// @notice Thrown when the WideOrderId exceeds uint40 after stripping the rest bit.
    /// @param orderId The overflowing order ID.
    error OrderIdOverflow(bytes32 orderId);

    /*//////////////////////////////////////////////////////////////////////////
                                   FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the connector implementation version.
    /// @return The version number.
    function connectorVersion() external pure returns (uint64);

    /// @notice Returns a bitmask of actions supported by this connector for the given endpoints.
    /// @param endpoints The current RISEx endpoint addresses.
    /// @return A uint256 bitmask where each set bit represents a supported action.
    function capabilities(
        EndpointSet calldata endpoints
    ) external view returns (uint256);

    /// @notice Encodes a low-level call for the given adapter action.
    /// @param action The adapter action to encode.
    /// @param adapterAccount The adapter's on-chain address (used as account identity).
    /// @param endpoints The current RISEx endpoint addresses.
    /// @param input The ABI-encoded action-specific parameters.
    /// @return call The encoded call descriptor.
    function buildCall(
        IRISExAdapter.Action action,
        address adapterAccount,
        EndpointSet calldata endpoints,
        bytes calldata input
    ) external view returns (Call memory call);

    /// @notice Decodes the return data from a RISEx call into adapter-level types.
    /// @param action The adapter action that produced the return data.
    /// @param returnData The raw return data from the call.
    /// @return result The decoded result in adapter-level encoding.
    function decodeResult(
        IRISExAdapter.Action action,
        bytes calldata returnData
    ) external pure returns (bytes memory result);
}
