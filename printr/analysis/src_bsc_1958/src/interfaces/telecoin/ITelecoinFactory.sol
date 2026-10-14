// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { ITelecoin } from "./ITelecoin.sol";

/**
 * @title Telecoin Factory Interface
 * @notice Interface for cross-chain telecoin deployment and management
 * @dev Provides functionality for deterministic token deployment and addressing across chains
 *      Integrates with Axelar's Interchain Token Service (ITS)
 */
interface ITelecoinFactory {

    /**
     * @notice Computes the deterministic address for a token deployment
     * @dev Uses CREATE3 address computation formula to ensure consistency across chains
     * @param telecoinId Universal token identifier (used as CREATE3 salt)
     * @return token The computed address where the token will be deployed
     */
    function tokenAddress(
        address deployer,
        bytes32 telecoinId
    ) external view returns (address token);

    /**
     * @notice Deploys a new token contract at a deterministic address
     * @dev Uses CREATE3 for deployment and handles initial ownership setup
     * @param params The deployment parameters for the telecoin
     * @param treasury Address to receive the initial token supply
     * @param initialSupply The initial supply to mint
     * @return token Address of the deployed token contract
     */
    function deployToken(
        ITelecoin.TelecoinDeployParams memory params,
        address treasury,
        uint256 initialSupply
    ) external payable returns (address token);

}
