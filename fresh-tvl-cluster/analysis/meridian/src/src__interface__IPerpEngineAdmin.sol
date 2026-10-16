// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IPerpEngine} from "./IPerpEngine.sol";

interface IPerpEngineAdmin {
    /// @notice Registers a product (i.e. trading pair) against the perp engine for trading.
    function register(IPerpEngine.RegisterPerpProductParams calldata params) external returns (uint32);

    /// @notice Initiates a serialized update for an existing product's numeric configuration.
    function update(IPerpEngine.UpdatePerpProductParams calldata params) external;

    /// @notice Updates an existing product's Pyth feed id.
    function updatePythFeedId(uint32 productId, uint32 pythFeedId) external;

    /// @notice Activates a pending product.
    function activate(uint32 productId) external;

    /// @notice Invokes the admin side of product delisting.
    function delist(uint32 productId) external;
}
