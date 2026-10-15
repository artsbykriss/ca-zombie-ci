// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.24;

import { IAddressManager } from "../aux/interfaces/IAddressManager.sol";

library AddressManagement {
    bytes32 private constant SWAP_MANAGER = "SWAP_MANAGER";

    function getSwapManager(
        IAddressManager addressManager
    ) internal view returns (address) {
        return addressManager.getAddress(SWAP_MANAGER);
    }
}
