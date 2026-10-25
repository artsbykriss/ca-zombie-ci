// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Proxy} from "@openzeppelin/contracts/proxy/Proxy.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";

/**
 * @title NullmaskProxy
 * @notice ERC1967 proxy for the Nullmask UUPS upgradeable contract
 * @dev This proxy has no constructor arguments, ensuring a stable CREATE2 address.
 *      The implementation is set via setImplementationAndCall() after deployment.
 */
contract NullmaskProxy is Proxy {
    /**
     * @dev The implementation has already been set.
     */
    error ImplementationAlreadySet();

    /**
     * @dev Sets the implementation and optionally calls initialization data.
     * Can only be called once when the implementation is unset.
     * @param implementation The address of the implementation contract.
     * @param data Optional initialization calldata (delegatecalled to implementation).
     */
    function setImplementationAndCall(address implementation, bytes calldata data) external payable {
        if (ERC1967Utils.getImplementation() != address(0)) {
            revert ImplementationAlreadySet();
        }
        ERC1967Utils.upgradeToAndCall(implementation, data);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view override returns (address) {
        return ERC1967Utils.getImplementation();
    }
}
