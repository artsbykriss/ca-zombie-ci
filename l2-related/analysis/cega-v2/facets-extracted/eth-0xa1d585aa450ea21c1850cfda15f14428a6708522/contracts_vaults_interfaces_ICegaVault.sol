// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface ICegaVault is IERC20 {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}
