// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {PrimusConfigBase} from "./PrimusConfigBase.sol";

/**
 * @title PrimusConfigUpgradeable.
 */
contract PrimusConfigUpgradeable is Initializable, PrimusConfigBase {
    uint256[10] internal __gap;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function __PrimusConfigUpgradeable_init() internal onlyInitializing {
        _setupFHEConfig();
    }
}
