// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { IPrintrStorage } from "./IPrintrStorage.sol";

/**
 * @title Printr Getters Interface
 * @notice Interface for the PrintrGetters contract
 * @dev All price calculations use PRECISION_SCALAR (1e18) for accurate floating point math
 *      Implements cross-chain token deployment through ITelecoinFactory integration
 *      This interface defines the core storage and view functions for the Printr system
 */
interface IPrintrGetters is IPrintrStorage {

    /**
     * @notice Retrieves the address of a token based on its universal ID
     * @param telecoinId The universal token ID (deploySalt)
     * @return Address of the token associated with the given ID
     */
    function getTokenAddress(
        bytes32 telecoinId
    ) external view returns (address);

    /**
     * @notice Calculates the deterministic address for a token deployment
     * @dev Uses creator address and deployment parameters to compute the deployment address
     * @param tokenParams Parameters for the token deployment
     * @return tokenAddress The calculated token deployment address
     */
    function getTokenAddress(
        TelecoinParams calldata tokenParams
    ) external view returns (address tokenAddress);

    /**
     * @notice Retrieves information about a specific token
     * @param token Address of the token
     * @return CurveInfo struct containing the token's configuration and state
     */
    function getCurve(
        address token
    ) external view returns (CurveInfo memory);

    /**
     * @notice Gets the lock status for a token
     * @param token Address of the token to check
     * @return Array containing lock information
     */
    function getLiquidityLocks(
        address token
    ) external view returns (uint256[2] memory);

}
