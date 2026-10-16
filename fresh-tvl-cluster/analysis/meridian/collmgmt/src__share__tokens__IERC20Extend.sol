// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Extend is IERC20 {
    /// @dev Returns the decimals places of the token.
    function decimals() external view returns (uint8);

    /// @dev Returns the symbol of the token.
    function symbol() external view returns (string memory);
}
