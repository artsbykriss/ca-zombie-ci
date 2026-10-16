// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import {PermissionLevel} from "./IAccess.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title IAsyncVaultFactory
/// @notice Interface for creating async vaults
interface IAsyncVaultFactory {
    /// @notice Emitted when a new async redeem vault is created
    /// @param vault The address of the created vault
    event AsyncRedeemVaultCreated(address indexed vault);

    /// @notice Creates a new async redeem vault
    /// @param asset The asset token address for the vault
    /// @param proxy The proxy address for the vault
    /// @param sharesTransferable Whether shares are transferable
    /// @param permissionLevel The permission level for the vault
    /// @param name The name of the vault
    /// @param symbol The symbol of the vault
    /// @param precision The precision for the vault
    function createAsyncRedeemVault(
        IERC20 asset,
        address proxy,
        bool sharesTransferable,
        PermissionLevel permissionLevel,
        string memory name,
        string memory symbol,
        uint256 precision
    ) external returns (address);
}
