// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { IPrintrCore } from "./interfaces/IPrintrCore.sol";

import { PrintrPrinting } from "./printr/PrintrPrinting.sol";
import { PrintrStorage } from "./printr/PrintrStorage.sol";
import { PrintrTrading } from "./printr/PrintrTrading.sol";

/**
 * @title PrintrCore Implementation Contract
 * @notice Core contract for the Printr protocol that serves as the main entry point
 * @dev Combines functionality from multiple specialized contracts through inheritance
 *      and implements a proxy pattern with fallback delegation to the teleport contract
 */
contract PrintrCore is IPrintrCore, PrintrStorage, PrintrPrinting, PrintrTrading {

    /// @notice Version of the Printr protocol
    string public constant VERSION = "v1.0.0";

    /// @notice Address of the teleport contract
    address public immutable teleport;

    /**
     * @notice Initializes the Printr contract with required dependencies
     * @dev Sets up core protocol addresses and disables initializers for upgradeable pattern
     * @param storageParams Deployment parameters containing all required addresses and configurations
     * @param teleport_ Address of the teleport contract
     * @custom:oz-upgrades-unsafe-allow constructor Used safely with initializer pattern
     */
    constructor(
        DeploymentParams memory storageParams,
        address teleport_
    ) PrintrStorage(storageParams) {
        teleport = teleport_;
    }

    /**
     * @dev Fallback function that delegates calls to the teleport contract
     */
    fallback() external payable virtual {
        address teleportImplementation = teleport;
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), teleportImplementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable { }

}
