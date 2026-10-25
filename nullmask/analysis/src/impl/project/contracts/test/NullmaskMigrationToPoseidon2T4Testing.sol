// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {NullmaskTesting} from "../NullmaskTesting.sol";

/**
 * @title NullmaskMigrationToPoseidon2T4Testing
 * @notice Named entry point for the migration tests.
 * @dev `insertDummyKeys` now lives on NullmaskTesting, since growing the key registry is
 *      useful outside the migration tests too (see test/RootHistory.ts). This contract
 *      stays as the name the migration test suite deploys.
 *      DO NOT DEPLOY TO PRODUCTION
 */
contract NullmaskMigrationToPoseidon2T4Testing is NullmaskTesting {
    constructor(uint256 _virtualChainId, address _uniswapV2Router)
        NullmaskTesting(_virtualChainId, _uniswapV2Router) {}
}
