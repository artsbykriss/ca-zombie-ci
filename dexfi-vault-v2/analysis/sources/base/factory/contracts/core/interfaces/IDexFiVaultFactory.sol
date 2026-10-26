// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "./IDexFiVault.sol";
import "./IDexFiVaultProfitStorage.sol";
import "./IDexFiProfit.sol";
import "./IDexFiFarm.sol";

interface IDexFiVaultFactory {
    struct FeeConfig {
        uint256 depositFee;
        uint256 harvestFee;
        uint256 withdrawFee;
        uint256 migrateFee;
    }

    struct ProfitConfig {
        uint256 minProfit;
        uint256 maxProfit;
        address profitStorageImplementation;
        uint256 vaultOwnerProfit;
    }

    struct VaultConfig {
        address vaultImplementation;
        uint256 maxDepositorsCount;
        uint256 initialPriceNativeAmount;
        uint256 minSyntheticTransferAmount;
        uint256 minNativeReinvestAmount;
    }

    struct IntegrationConfig {
        address operator;
        address keeper;
        address harvester;
        address migrator;
        address treasury;
        address profitClaimer;
        address zapper;
    }

    struct InitializableConfig {
        address source;
        bytes defaultInitializeData;
    }

    struct Beaconed {
        address beacon;
        address source;
        bytes defaultInitializeData;
    }

    function DIVIDER() external view returns (uint256);

    function MAX_DEPOSIT_FEE() external view returns (uint256);

    function MAX_HARVEST_FEE() external view returns (uint256);

    function MAX_WITHDRAW_FEE() external view returns (uint256);

    function MAX_MIGRATE_FEE() external view returns (uint256);

    function MIN_VAULT_MANAGEMENT_AMOUNT() external view returns (uint256);

    function MAX_VAULT_OWNER_PROFIT() external view returns (uint256);

    function MIN_DEPOSITORS_COUNT() external view returns (uint256);

    function MAX_DEPOSITORS_COUNT() external view returns (uint256);

    function native() external view returns (address);

    function defaultFarmsInitializeData(address) external view returns (bytes memory);

    function defaultFarmsInitializeDataTimestamp(address) external view returns (uint256);

    function profitTokenConnector(address) external view returns (IDexFiProfit);

    function farmCalculationConnector(address) external view returns (IDexFiFarm);

    function feeConfig() external view returns (FeeConfig memory);

    function profitConfig() external view returns (ProfitConfig memory);

    function vaultConfig() external view returns (VaultConfig memory);

    function integrationConfig() external view returns (IntegrationConfig memory);

    function farmsWhitelist(uint256 index) external view returns (address);

    function farmsWhitelistCount() external view returns (uint256);

    function farmsWhitelistContains(address farm) external view returns (bool);

    function profitTokensWhitelist(uint256 index) external view returns (address);

    function profitTokensWhitelistCount() external view returns (uint256);

    function profitTokensWhitelistContains(address profitToken) external view returns (bool);

    function vaults(uint256 index) external view returns (address);

    function vaultsCount() external view returns (uint256);

    function vaultsContains(address vault) external view returns (bool);

    function harvesterBlacklist(uint256 index) external view returns (address);

    function harvesterBlacklistCount() external view returns (uint256);

    function harvesterBlacklistContains(address vault) external view returns (bool);

    error NativeZero();
    error CallerNotOwnerOrOperator(address caller, address owner, address operator);

    error CreateVaultProfitTokenUnsupported(address profitToken);
    error CreateVaultInitializationFailed();

    error UpdateFarmsWhitelistBeaconNotWhitelisted(address beacon);
    error UpdateFarmsWhitelistBeaconSourceZero(address beacon);
    error UpdateFarmsWhitelistReinitializationFailed(Beaconed data);

    error UpdateProfitTokensWhitelistBeaconNotWhitelisted(address beacon);
    error UpdateProfitTokensWhitelistBeaconSourceZero(address beacon);
    error UpdateProfitTokensWhitelistReinitializationFailed(Beaconed data);

    error UpdateFeeConfigDepositFeeOverflow(uint256 depositFee, uint256 limit);
    error UpdateFeeConfigHarvestFeeOverflow(uint256 harvestFee, uint256 limit);
    error UpdateFeeConfigWithdrawFeeOverflow(uint256 withdrawFee, uint256 limit);
    error UpdateFeeConfigMigrateFeeOverflow(uint256 migrateFee, uint256 limit);

    error UpdateVaultConfigVaultImplementationZero();
    error UpdateVaultConfigInvalidMaxDepositors(uint256 maxDepositors, uint256 min, uint256 max);
    error UpdateVaultConfigVaultInitialPriceNativeAmountUnderflow(uint256 initialPriceNativeAmount, uint256 min);
    error UpdateVaultConfigMinSyntheticTransferAmountUnderflow(uint256 minSyntheticTransferAmount, uint256 min);
    error UpdateVaultConfigMinReinvestAmountZero();
    error UpdateProfitConfigMaxProfitOverflow(uint256 maxProfit, uint256 max);
    error UpdateProfitConfigMinProfitOverflow(uint256 minProfit, uint256 maxProfit);
    error UpdateProfitConfigProfitStorageImplementationZero();
    error UpdateProfitConfigVaultOwnerProfitOverflow(uint256 vaultOwnerProfit, uint256 max);

    error UpdateIntegrationConfigOperatorZero();
    error UpdateIntegrationConfigKeeperZero();
    error UpdateIntegrationConfigHarvesterZero();
    error UpdateIntegrationConfigMigratorZero();
    error UpdateIntegrationConfigTreasuryZero();
    error UpdateIntegrationConfigProfitClaimerZero();
    error UpdateIntegrationConfigZapperZero();

    error ToggleVaultAutoHarvestCallerNotVaultOwner(address caller, address vault, address owner);

    error AddProfitTokensWhitelistProfitTokenZero();
    error AddProfitTokensWhitelistInitializationFailed(Beaconed data);

    error AddFarmsWhitelistFarmZero();
    error AddFarmsWhitelistInitializationFailed(Beaconed data);

    event VaultCreated(
        address indexed owner,
        address vault,
        uint256 profit,
        address profitToken,
        IDexFiVault.Farm[] farms
    );
    event FeeConfigUpdated(FeeConfig config);
    event VaultConfigUpdated(VaultConfig config);
    event ProfitConfigUpdated(ProfitConfig config);
    event IntegrationConfigUpdated(IntegrationConfig config);
    event VaultAutoHarvestToggled(address vault, bool blacklisted);
    event ProfitTokensWhitelistAdded(Beaconed[] profitTokens);
    event ProfitTokensWhitelistUpdated(Beaconed[] profitTokens);
    event ProfitTokensWhitelistRemoved(address[] profitTokens);
    event FarmsWhitelistAdded(Beaconed[] farms);
    event FarmsWhitelistUpdated(Beaconed[] farms);
    event FarmsWhitelistRemoved(address[] farms);

    function createVault(
        string memory name_,
        string memory symbol_,
        uint256 profit_,
        address profitToken_,
        IDexFiVault.Farm[] memory farms_
    ) external returns (address vault);

    function pause() external returns (bool);

    function unpause() external returns (bool);

    function addFarmsWhitelist(InitializableConfig[] memory farms_) external returns (Beaconed[] memory output);

    function updateFarmsWhitelist(Beaconed[] memory farms_) external returns (bool);

    function removeFarmsWhitelist(address[] memory beacons_) external returns (bool);

    function addProfitTokensWhitelist(
        InitializableConfig[] memory profitTokens_
    ) external returns (Beaconed[] memory output);

    function updateProfitTokensWhitelist(Beaconed[] memory profitTokens_) external returns (bool);

    function removeProfitTokensWhitelist(address[] memory beacons_) external returns (bool);

    function updateFeeConfig(FeeConfig memory config) external returns (bool);

    function updateVaultConfig(VaultConfig memory config) external returns (bool);

    function updateProfitConfig(ProfitConfig memory config) external returns (bool);

    function updateIntegrationConfig(IntegrationConfig memory config) external returns (bool);

    function toggleVaultAutoHarvest(address vault) external returns (bool);
}
