// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "./interfaces/IDexFiVaultFactory.sol";

/**
 * @title DexFiVaultFactory
 * @dev This contract serves as a factory for creating and managing DexFiVault instances.
 */
contract DexFiVaultFactory is IDexFiVaultFactory, Ownable, Pausable {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public constant DIVIDER = 1e18;
    uint256 public constant MAX_DEPOSIT_FEE = 5e16;
    uint256 public constant MAX_HARVEST_FEE = 1e17;
    uint256 public constant MAX_WITHDRAW_FEE = 3e16;
    uint256 public constant MAX_MIGRATE_FEE = 1e16;
    uint256 public constant MIN_VAULT_MANAGEMENT_AMOUNT = 1e12;
    uint256 public constant MAX_VAULT_OWNER_PROFIT = 75e15;
    uint256 public constant MIN_DEPOSITORS_COUNT = 1;
    uint256 public constant MAX_DEPOSITORS_COUNT = 1e4;

    address public immutable native;
    mapping(address => bytes) public defaultFarmsInitializeData;
    mapping(address => uint256) public defaultFarmsInitializeDataTimestamp;
    mapping(address => IDexFiProfit) public profitTokenConnector;
    mapping(address => IDexFiFarm) public farmCalculationConnector;

    FeeConfig private _feeConfig;
    ProfitConfig private _profitConfig;
    VaultConfig private _vaultConfig;
    IntegrationConfig private _integrationConfig;
    EnumerableSet.AddressSet private _farmsWhitelist;
    EnumerableSet.AddressSet private _profitTokensWhitelist;
    EnumerableSet.AddressSet private _vaults;
    EnumerableSet.AddressSet private _harvesterBlacklist;

    /**
     * @notice Returns the FeeConfig struct.
     * @return FeeConfig The FeeConfig struct.
     */
    function feeConfig() external view returns (FeeConfig memory) {
        return _feeConfig;
    }

    /**
     * @notice Returns the ProfitConfig struct.
     * @return ProfitConfig The ProfitConfig struct.
     */
    function profitConfig() external view returns (ProfitConfig memory) {
        return _profitConfig;
    }

    /**
     * @notice Returns the VaultConfig struct.
     * @return VaultConfig The VaultConfig struct.
     */
    function vaultConfig() external view returns (VaultConfig memory) {
        return _vaultConfig;
    }

    /**
     * @notice Returns the IntegrationConfig struct.
     * @return IntegrationConfig The IntegrationConfig struct.
     */
    function integrationConfig() external view returns (IntegrationConfig memory) {
        return _integrationConfig;
    }

    /**
     * @notice Returns the address at a given index in the farms whitelist.
     * @param index The index to query.
     * @return address The address at the specified index.
     */
    function farmsWhitelist(uint256 index) external view returns (address) {
        return _farmsWhitelist.at(index);
    }

    /**
     * @notice Returns the number of addresses in the farms whitelist.
     * @return uint256 The number of addresses in the farms whitelist.
     */
    function farmsWhitelistCount() external view returns (uint256) {
        return _farmsWhitelist.length();
    }

    /**
     * @notice Checks if a farm address is in the whitelist.
     * @param farm The address of the farm to check.
     * @return bool true if the farm is in the whitelist, false otherwise.
     */
    function farmsWhitelistContains(address farm) external view returns (bool) {
        return _farmsWhitelist.contains(farm);
    }

    /**
     * @notice Returns the address at a given index in the profit tokens whitelist.
     * @param index The index to query.
     * @return address The address at the specified index.
     */
    function profitTokensWhitelist(uint256 index) external view returns (address) {
        return _profitTokensWhitelist.at(index);
    }

    /**
     * @notice Returns the number of addresses in the profit tokens whitelist.
     * @return uint256 The number of addresses in the profit tokens whitelist.
     */
    function profitTokensWhitelistCount() external view returns (uint256) {
        return _profitTokensWhitelist.length();
    }

    /**
     * @notice Checks if a profit token address is in the whitelist.
     * @param profitToken The address of the profit token to check.
     * @return bool true if the profit token is in the whitelist, false otherwise.
     */
    function profitTokensWhitelistContains(address profitToken) external view returns (bool) {
        return _profitTokensWhitelist.contains(profitToken);
    }

    /**
     * @notice Returns the address at a given index in the vaults set.
     * @param index The index to query.
     * @return address The address at the specified index.
     */
    function vaults(uint256 index) external view returns (address) {
        return _vaults.at(index);
    }

    /**
     * @notice Returns the number of addresses in the vaults set.
     * @return uint256 The number of addresses in the vaults set.
     */
    function vaultsCount() external view returns (uint256) {
        return _vaults.length();
    }

    /**
     * @notice Checks if a vault address is in the set.
     * @param vault The address of the vault to check.
     * @return bool true if the vault is in the set, false otherwise.
     */
    function vaultsContains(address vault) external view returns (bool) {
        return _vaults.contains(vault);
    }

    /**
     * @notice Returns the address at a given index in the harvester blacklist.
     * @param index The index to query.
     * @return address The address at the specified index.
     */
    function harvesterBlacklist(uint256 index) external view returns (address) {
        return _harvesterBlacklist.at(index);
    }

    /**
     * @notice Returns the number of addresses in the harvester blacklist.
     * @return uint256 The number of addresses in the harvester blacklist.
     */
    function harvesterBlacklistCount() external view returns (uint256) {
        return _harvesterBlacklist.length();
    }

    /**
     * @notice Checks if a vault address is in the harvester blacklist.
     * @param vault The address of the vault to check.
     * @return bool true if the vault is in the harvester blacklist, false otherwise.
     */
    function harvesterBlacklistContains(address vault) external view returns (bool) {
        return _harvesterBlacklist.contains(vault);
    }

    /**
     * @param native_ The address of the native token.
     * @param integrationConfig_ The IntegrationConfig struct containing integration parameters.
     * @param feeConfig_ The FeeConfig struct containing fee parameters.
     * @param vaultConfig_ The VaultConfig struct containing vault parameters.
     * @param profitConfig_ The ProfitConfig struct containing profit parameters.
     */
    constructor(
        address native_,
        IntegrationConfig memory integrationConfig_,
        FeeConfig memory feeConfig_,
        VaultConfig memory vaultConfig_,
        ProfitConfig memory profitConfig_
    ) {
        if (native_ == address(0)) revert NativeZero();
        native = native_;
        _updateIntegrationConfig(integrationConfig_);
        _updateFeeConfig(feeConfig_);
        _updateVaultConfig(vaultConfig_);
        _updateProfitConfig(profitConfig_);
    }

    /**
     * @dev Creates a new vault with the specified parameters.
     * @param name_ The name of the vault.
     * @param symbol_ The symbol of the vault.
     * @param profit_ The initial profit value.
     * @param profitToken_ The address of the profit token.
     * @param farms_ An array of farms associated with the vault.
     * @return vault The address of the created vault.
     */
    function createVault(
        string memory name_,
        string memory symbol_,
        uint256 profit_,
        address profitToken_,
        IDexFiVault.Farm[] memory farms_
    ) external whenNotPaused returns (address vault) {
        if (profit_ > 0 && !_profitTokensWhitelist.contains(profitToken_))
            revert CreateVaultProfitTokenUnsupported(profitToken_);
        vault = address(new BeaconProxy(_vaultConfig.vaultImplementation, ""));
        if (!IDexFiVault(vault).initialize(name_, symbol_, msg.sender, profit_, profitToken_, farms_))
            revert CreateVaultInitializationFailed();
        _vaults.add(vault);
        emit VaultCreated(msg.sender, vault, profit_, profitToken_, farms_);
    }

    /**
     * @dev Pauses the contract.
     * @return true if the contract is successfully paused.
     */
    function pause() external onlyOwner returns (bool) {
        _pause();
        return true;
    }

    /**
     * @dev Unpauses the contract.
     * @return true if the contract is successfully unpaused.
     */
    function unpause() external onlyOwner returns (bool) {
        _unpause();
        return true;
    }

    /**
     * @dev Adds farms to the whitelist.
     * @param farms_ An array of farms to be added to the whitelist.
     * @return output An array of Beaconed structs containing information about the added farms.
     */
    function addFarmsWhitelist(
        InitializableConfig[] memory farms_
    ) external onlyOwnerOrOperator returns (Beaconed[] memory output) {
        output = new Beaconed[](farms_.length);
        for (uint256 i = 0; i < farms_.length; i++) {
            InitializableConfig memory farm_ = farms_[i];
            if (farm_.source == address(0)) revert AddFarmsWhitelistFarmZero();
            address beacon = address(new UpgradeableBeacon(farm_.source));
            farmCalculationConnector[beacon] = IDexFiFarm(address(new BeaconProxy(beacon, "")));
            output[i] = Beaconed({
                beacon: beacon,
                source: farm_.source,
                defaultInitializeData: farm_.defaultInitializeData
            });
            if (!farmCalculationConnector[beacon].initialize(farm_.defaultInitializeData))
                revert AddFarmsWhitelistInitializationFailed(output[i]);
            _farmsWhitelist.add(beacon);
            defaultFarmsInitializeData[beacon] = farm_.defaultInitializeData;
            defaultFarmsInitializeDataTimestamp[beacon] = block.timestamp;
        }
        emit FarmsWhitelistAdded(output);
    }

    /**
     * @dev Updates the whitelist with new farm information.
     * @param farms_ An array of Beaconed structs containing information about the farms to be updated.
     * @return true if the whitelist is successfully updated.
     */
    function updateFarmsWhitelist(Beaconed[] memory farms_) external onlyOwner returns (bool) {
        for (uint256 i = 0; i < farms_.length; i++) {
            Beaconed memory info = farms_[i];
            if (!_farmsWhitelist.contains(info.beacon)) revert UpdateFarmsWhitelistBeaconNotWhitelisted(info.beacon);
            UpgradeableBeacon beacon = UpgradeableBeacon(info.beacon);
            if (beacon.implementation() != info.source) {
                if (info.source == address(0)) revert UpdateFarmsWhitelistBeaconSourceZero(info.beacon);
                beacon.upgradeTo(info.source);
            }
            if (!farmCalculationConnector[info.beacon].reinitialize(info.defaultInitializeData))
                revert UpdateFarmsWhitelistReinitializationFailed(info);
            defaultFarmsInitializeData[info.beacon] = info.defaultInitializeData;
            defaultFarmsInitializeDataTimestamp[info.beacon] = block.timestamp;
        }
        emit FarmsWhitelistUpdated(farms_);
        return true;
    }

    /**
     * @dev Removes farms from the whitelist.
     * @param beacons An array of beacon addresses to be removed from the whitelist.
     * @return true if the farms are successfully removed from the whitelist.
     */
    function removeFarmsWhitelist(address[] memory beacons) external onlyOwner returns (bool) {
        for (uint256 i = 0; i < beacons.length; i++) {
            address beacon = beacons[i];
            _farmsWhitelist.remove(beacon);
            delete defaultFarmsInitializeData[beacon];
            delete defaultFarmsInitializeDataTimestamp[beacon];
        }
        emit FarmsWhitelistRemoved(beacons);
        return true;
    }

    /**
     * @dev Adds profit tokens to the whitelist.
     * @param profitTokens_ An array of profit tokens to be added to the whitelist.
     * @return output An array of Beaconed structs containing information about the added profit tokens.
     */
    function addProfitTokensWhitelist(
        InitializableConfig[] memory profitTokens_
    ) external onlyOwnerOrOperator returns (Beaconed[] memory output) {
        output = new Beaconed[](profitTokens_.length);
        for (uint256 i = 0; i < profitTokens_.length; i++) {
            InitializableConfig memory profitToken_ = profitTokens_[i];
            if (profitToken_.source == address(0)) revert AddProfitTokensWhitelistProfitTokenZero();
            address beacon = address(new UpgradeableBeacon(profitToken_.source));
            profitTokenConnector[beacon] = IDexFiProfit(address(new BeaconProxy(beacon, "")));
            output[i] = Beaconed({
                beacon: beacon,
                source: profitToken_.source,
                defaultInitializeData: profitToken_.defaultInitializeData
            });
            if (!profitTokenConnector[beacon].initialize(profitToken_.defaultInitializeData))
                revert AddProfitTokensWhitelistInitializationFailed(output[i]);
            _profitTokensWhitelist.add(beacon);
        }
        emit ProfitTokensWhitelistAdded(output);
    }

    /**
     * @dev Updates the whitelist with new profit token information.
     * @param profitTokens_ An array of Beaconed structs containing information about the profit tokens to be updated.
     * @return true if the whitelist is successfully updated.
     */
    function updateProfitTokensWhitelist(Beaconed[] memory profitTokens_) external onlyOwner returns (bool) {
        for (uint256 i = 0; i < profitTokens_.length; i++) {
            Beaconed memory info = profitTokens_[i];
            if (!_profitTokensWhitelist.contains(info.beacon))
                revert UpdateProfitTokensWhitelistBeaconNotWhitelisted(info.beacon);
            UpgradeableBeacon beacon = UpgradeableBeacon(info.beacon);
            if (beacon.implementation() != info.source) {
                if (info.source == address(0)) revert UpdateProfitTokensWhitelistBeaconSourceZero(info.beacon);
                beacon.upgradeTo(info.source);
            }
            if (!profitTokenConnector[info.beacon].reinitialize(info.defaultInitializeData))
                revert UpdateProfitTokensWhitelistReinitializationFailed(info);
        }
        emit ProfitTokensWhitelistUpdated(profitTokens_);
        return true;
    }

    /**
     * @dev Removes profit tokens from the whitelist.
     * @param beacons An array of beacon addresses to be removed from the whitelist.
     * @return true if the profit tokens are successfully removed from the whitelist.
     */
    function removeProfitTokensWhitelist(address[] memory beacons) external onlyOwner returns (bool) {
        for (uint256 i = 0; i < beacons.length; i++) _profitTokensWhitelist.remove(beacons[i]);
        emit ProfitTokensWhitelistRemoved(beacons);
        return true;
    }

    /**
     * @dev Updates fee configuration.
     * @param config New fee configuration.
     * @return true if the update is successful.
     */
    function updateFeeConfig(FeeConfig memory config) external onlyOwner returns (bool) {
        _updateFeeConfig(config);
        return true;
    }

    /**
     * @dev Updates vault configuration.
     * @param config New vault configuration.
     * @return true if the update is successful.
     */
    function updateVaultConfig(VaultConfig memory config) external onlyOwner returns (bool) {
        _updateVaultConfig(config);
        return true;
    }

    /**
     * @dev Updates profit configuration.
     * @param config New profit configuration.
     * @return true if the update is successful.
     */
    function updateProfitConfig(ProfitConfig memory config) external onlyOwner returns (bool) {
        _updateProfitConfig(config);
        return true;
    }

    /**
     * @dev Updates integration configuration.
     * @param config New integration configuration.
     * @return true if the update is successful.
     */
    function updateIntegrationConfig(IntegrationConfig memory config) external onlyOwner returns (bool) {
        _updateIntegrationConfig(config);
        return true;
    }

    /**
     * @dev Toggles automatic vault harvesting.
     * @param vault Address of the vault.
     * @return true if the toggle is successful.
     */
    function toggleVaultAutoHarvest(address vault) external returns (bool) {
        address vaultOwner = Ownable(vault).owner();
        if (msg.sender != vaultOwner) revert ToggleVaultAutoHarvestCallerNotVaultOwner(msg.sender, vault, vaultOwner);
        bool blacklisted_ = false;
        if (_harvesterBlacklist.contains(vault)) _harvesterBlacklist.remove(vault);
        else {
            blacklisted_ = true;
            _harvesterBlacklist.add(vault);
        }
        emit VaultAutoHarvestToggled(vault, blacklisted_);
        return true;
    }

    /**
     * @dev Updates fee configuration.
     * @param config New fee configuration.
     */
    function _updateFeeConfig(FeeConfig memory config) private {
        if (config.depositFee > MAX_DEPOSIT_FEE)
            revert UpdateFeeConfigDepositFeeOverflow(config.depositFee, MAX_DEPOSIT_FEE);
        if (config.harvestFee > MAX_HARVEST_FEE)
            revert UpdateFeeConfigHarvestFeeOverflow(config.harvestFee, MAX_HARVEST_FEE);
        if (config.withdrawFee > MAX_WITHDRAW_FEE)
            revert UpdateFeeConfigWithdrawFeeOverflow(config.withdrawFee, MAX_WITHDRAW_FEE);
        if (config.migrateFee > MAX_MIGRATE_FEE)
            revert UpdateFeeConfigMigrateFeeOverflow(config.migrateFee, MAX_MIGRATE_FEE);
        _feeConfig = config;
        emit FeeConfigUpdated(config);
    }

    /**
     * @dev Updates profit configuration.
     * @param config New profit configuration.
     */
    function _updateProfitConfig(ProfitConfig memory config) private {
        if (config.maxProfit > DIVIDER) revert UpdateProfitConfigMaxProfitOverflow(config.maxProfit, DIVIDER);
        if (config.minProfit >= config.maxProfit)
            revert UpdateProfitConfigMinProfitOverflow(config.minProfit, config.maxProfit);
        if (config.profitStorageImplementation == address(0))
            revert UpdateProfitConfigProfitStorageImplementationZero();
        if (config.vaultOwnerProfit > MAX_VAULT_OWNER_PROFIT)
            revert UpdateProfitConfigVaultOwnerProfitOverflow(config.vaultOwnerProfit, MAX_VAULT_OWNER_PROFIT);
        address previousProfitStorageImplementation = _profitConfig.profitStorageImplementation;
        if (previousProfitStorageImplementation != address(0)) {
            UpgradeableBeacon(previousProfitStorageImplementation).upgradeTo(config.profitStorageImplementation);
            config.profitStorageImplementation = previousProfitStorageImplementation;
        } else config.profitStorageImplementation = address(new UpgradeableBeacon(config.profitStorageImplementation));
        _profitConfig = config;
        emit ProfitConfigUpdated(config);
    }

    /**
     * @dev Updates integration configuration.
     * @param config New integration configuration.
     */
    function _updateIntegrationConfig(IntegrationConfig memory config) private {
        if (config.operator == address(0)) revert UpdateIntegrationConfigOperatorZero();
        if (config.keeper == address(0)) revert UpdateIntegrationConfigKeeperZero();
        if (config.harvester == address(0)) revert UpdateIntegrationConfigHarvesterZero();
        if (config.migrator == address(0)) revert UpdateIntegrationConfigMigratorZero();
        if (config.treasury == address(0)) revert UpdateIntegrationConfigTreasuryZero();
        if (config.profitClaimer == address(0)) revert UpdateIntegrationConfigProfitClaimerZero();
        if (config.zapper == address(0)) revert UpdateIntegrationConfigZapperZero();
        _integrationConfig = config;
        emit IntegrationConfigUpdated(config);
    }

    /**
     * @dev Updates vault configuration.
     * @param config New vault configuration.
     */
    function _updateVaultConfig(VaultConfig memory config) private {
        if (config.vaultImplementation == address(0)) revert UpdateVaultConfigVaultImplementationZero();
        if (config.maxDepositorsCount < MIN_DEPOSITORS_COUNT || config.maxDepositorsCount > MAX_DEPOSITORS_COUNT)
            revert UpdateVaultConfigInvalidMaxDepositors(
                config.maxDepositorsCount,
                MIN_DEPOSITORS_COUNT,
                MAX_DEPOSITORS_COUNT
            );
        if (config.initialPriceNativeAmount < MIN_VAULT_MANAGEMENT_AMOUNT) {
            revert UpdateVaultConfigVaultInitialPriceNativeAmountUnderflow(
                config.initialPriceNativeAmount,
                MIN_VAULT_MANAGEMENT_AMOUNT
            );
        }
        if (config.minSyntheticTransferAmount < MIN_VAULT_MANAGEMENT_AMOUNT) {
            revert UpdateVaultConfigMinSyntheticTransferAmountUnderflow(
                config.minSyntheticTransferAmount,
                MIN_VAULT_MANAGEMENT_AMOUNT
            );
        }
        if (config.minNativeReinvestAmount == 0) revert UpdateVaultConfigMinReinvestAmountZero();
        address previousVaultImplementation = _vaultConfig.vaultImplementation;
        if (previousVaultImplementation != address(0)) {
            UpgradeableBeacon(previousVaultImplementation).upgradeTo(config.vaultImplementation);
            config.vaultImplementation = previousVaultImplementation;
        } else config.vaultImplementation = address(new UpgradeableBeacon(config.vaultImplementation));
        _vaultConfig = config;
        emit VaultConfigUpdated(config);
    }

    modifier onlyOwnerOrOperator() {
        address owner_ = owner();
        if (msg.sender != owner_ && msg.sender != _integrationConfig.operator)
            revert CallerNotOwnerOrOperator(msg.sender, owner_, _integrationConfig.operator);
        _;
    }
}
