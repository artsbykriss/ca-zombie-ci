// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title PrintrStaking Proxy
 * @notice Proxy contract for upgradeable PrintrStaking implementation
 * @dev Extends OpenZeppelin's ERC1967Proxy with ability to query current implementation
 */
contract PrintrStakingProxy is ERC1967Proxy {

    /**
     * @notice Initializes the proxy with an implementation and initialization data
     * @dev Delegates initialization call to implementation if data is provided
     * @param _logic Address of the initial implementation contract
     * @param _data Initialization call data (can be empty)
     */
    constructor(
        address _logic,
        bytes memory _data
    ) ERC1967Proxy(_logic, _data) { }

    /**
     * @notice Returns the current implementation address
     * @dev Exposes internal _implementation() function from ERC1967Proxy
     * @return The address of the current implementation contract
     */
    function implementation() public view returns (address) {
        return _implementation();
    }

}
