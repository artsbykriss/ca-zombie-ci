// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @title DexFiInitializable
 * @dev Abstract contract for initializing contracts with OpenZeppelin's Initializable logic.
 */
abstract contract DexFiInitializable is Initializable {
    // Custom error for indicating that the contract is not initialized.
    error ContractNotInitialized();

    /**
     * @dev Modifier to check if the contract is initialized.
     * Throws a `ContractNotInitialized` error if not initialized.
     */
    modifier onlyInitialized() {
        if (_getInitializedVersion() == 0) revert ContractNotInitialized();
        _;
    }
}
