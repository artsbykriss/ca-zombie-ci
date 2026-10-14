// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { IPrintrStorage } from "./IPrintrStorage.sol";

/**
 * @title Printr Owner Interface
 * @notice Interface for administrative functions related to fee collection
 * @dev Extends IPrintrStorage to provide fee management capabilities
 */
interface IPrintrOwner is IPrintrStorage {

    /**
     * @notice Pauses the contract, preventing all trading and liquidity operations
     */
    function pause() external;

    /**
     * @notice Unpauses the contract, allowing trading and liquidity operations to resume
     */
    function unpause() external;

}
