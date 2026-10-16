// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

interface IGlobalRegistry {
    /// @notice Emitted when the security admin is set
    /// @param securityAdmin The address of the security admin
    event SecurityAdminSet(address securityAdmin);

    /// @notice Emitted when the operations admin is set
    /// @param operationsAdmin The address of the operations admin
    event OperationsAdminSet(address operationsAdmin);

    /// @notice Emitted when the treasury is set
    /// @param treasury The address of the treasury
    event TreasurySet(address treasury);

    /// @notice Emitted when the vault factory is set
    /// @param vaultFactory The address of the vault factory
    event VaultFactorySet(address vaultFactory);

    /// @notice Emitted when the rewards factory is set
    /// @param rewardsFactory The address of the rewards factory
    event RewardsFactorySet(address rewardsFactory);

    /// @notice Sets the security admin
    /// @param securityAdmin The address of the security admin
    function setSecurityAdmin(address securityAdmin) external;

    /// @notice Sets the operations admin
    /// @param operationsAdmin The address of the operations admin
    function setOperationsAdmin(address operationsAdmin) external;

    /// @notice Sets the treasury
    /// @param treasury The address of the treasury
    function setTreasury(address treasury) external;

    /// @notice Sets the vault factory
    /// @param vaultFactory The address of the vault factory
    function setVaultFactory(address vaultFactory) external;

    /// @notice Sets the rewards factory
    /// @param rewardsFactory The address of the rewards factory
    function setRewardsFactory(address rewardsFactory) external;

    /// @notice Protocol security admin
    /// @return The address of the Accountablesecurity admin
    function securityAdmin() external view returns (address);

    /// @notice Protocol operations admin
    /// @return The address of the Accountable operations admin
    function operationsAdmin() external view returns (address);

    /// @notice Protocol treasury
    /// @return The address of the treasury
    function treasury() external view returns (address);

    /// @notice Vault factory
    /// @return The address of the vault factory
    function vaultFactory() external view returns (address);

    /// @notice Rewards distributor factory
    /// @return The address of the rewards factory
    function rewardsFactory() external view returns (address);
}
