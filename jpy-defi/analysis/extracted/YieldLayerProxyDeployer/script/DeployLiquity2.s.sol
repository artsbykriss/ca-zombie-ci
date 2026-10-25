// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {StdCheats} from "forge-std/StdCheats.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {TimelockController} from "openzeppelin-contracts/contracts/governance/TimelockController.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {ScriptSecurityPolicy} from "script/ScriptSecurityPolicy.sol";
import {MainnetProductionTimelockPolicy} from "script/MainnetProductionTimelockPolicy.sol";
import {MainnetCanaryBridgeAdmin} from "script/MainnetCanaryBridgeAdmin.sol";
import {SepoliaExternalAddresses} from "script/SepoliaExternalAddresses.sol";

import {StringFormatting} from "test/Utils/StringFormatting.sol";
import {ETH_GAS_COMPENSATION, MIN_DEBT, SP_YIELD_SPLIT} from "src/Dependencies/Constants.sol";
import {IBorrowerOperations} from "src/Interfaces/IBorrowerOperations.sol";
import {IMetadataNFT} from "src/Interfaces/IMetadataNFT.sol";
import "src/AddressesRegistry.sol";
import "src/ActivePool.sol";
import "src/JpydfToken.sol";
import "src/BorrowerOperations.sol";
import "src/JPYdfTroveNFT.sol";
import "src/TroveManager.sol";
import "src/CollSurplusPool.sol";
import "src/DefaultPool.sol";
import "src/GasPool.sol";
import "src/HintHelpers.sol";
import "src/LiquidationCandidateGetter.sol";
import "src/MultiTroveGetter.sol";
import "src/CollateralVaultLens.sol";
import {DebtInFrontHelper, IDebtInFrontHelper} from "src/DebtInFrontHelper.sol";
import {RedemptionHelper, IRedemptionHelper} from "src/RedemptionHelper.sol";
import "src/SortedTroves.sol";
import "src/DFStabilityPool.sol";
import "src/CollateralRegistry.sol";
import "src/NFTMetadata/JPYdfMetadataNFT.sol";
import "test/TestContracts/MetadataDeployment.sol";
import "test/Utils/Logging.sol";
import "test/Utils/StringEquality.sol";
import {CollateralYieldZapper} from "src/Zappers/CollateralYieldZapper.sol";
import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {
    IERC20MetadataUpgradeable
} from "openzeppelin-contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import {DToken} from "src/DToken.sol";
import {IDToken} from "src/Interfaces/IDToken.sol";
import {InterestRouterForwarder} from "src/InterestRouterForwarder.sol";
import {CollateralVault} from "src/CollateralVault.sol";
import {IStrategy} from "src/Interfaces/IStrategy.sol";
import {AaveV3Strategy, IAaveV3Pool, IAToken} from "src/Strategies/AaveV3Strategy.sol";
import {ERC4626Strategy} from "src/Strategies/ERC4626Strategy.sol";
import {IMorphoVaultV2, MorphoV2Strategy} from "src/Strategies/MorphoV2Strategy.sol";
import {ISkyLitePsmWrapper, ISkyUsdcSUsdsConverter} from "src/Interfaces/ISkyUsdcSUsdsConverter.sol";
import {SkyUsdcSUsdsConverter} from "src/Strategies/SkyUsdcSUsdsConverter.sol";
import {SkyUsdcSUsdsStrategy} from "src/Strategies/SkyUsdcSUsdsStrategy.sol";
import {PriceFeedProxy} from "src/PriceFeeds/PriceFeedProxy.sol";
import {PriceFeedPlaceholder} from "src/PriceFeeds/PriceFeedPlaceholder.sol";
import {DFWstETHPriceFeed} from "src/PriceFeeds/DFWstETHPriceFeed.sol";
import {DFUSDCPriceFeed} from "src/PriceFeeds/DFUSDCPriceFeed.sol";
import {JpyUsdRateProvider} from "src/PriceFeeds/JpyUsdRateProvider.sol";
import {LocalAavePool, LocalAToken} from "./local/LocalAaveVenue.sol";
import {LocalChainlinkAggregator} from "./local/LocalChainlinkAggregator.sol";
import {SepoliaChainlinkAggregator} from "./local/SepoliaChainlinkAggregator.sol";
import {LocalERC20FaucetDecimals, LocalStETH, LocalWETH, LocalWstETH} from "./local/LocalTokens.sol";

/// @dev Common surface of the production DF price feeds. Each active source exposes
///      the branch CollateralVault it reads backing from.
interface IDFFeedVaultRef {
    function collateralVault() external view returns (address);
}

interface IBaseStrategyView is IStrategy {
    function vault() external view returns (address);
}

interface IDeployInterestRouterForwarderView {
    function jpydfToken() external view returns (address);
    function recipient() external view returns (address);
    function owner() external view returns (address);
    function pendingOwner() external view returns (address);
}

interface ISepoliaLidoWstEthPreflight {
    function stETH() external view returns (address);
    function stEthPerToken() external view returns (uint256);
}

interface ISepoliaLidoStEthPreflight {
    function isStakingPaused() external view returns (bool);
    function isStopped() external view returns (bool);
    function getCurrentStakeLimit() external view returns (uint256);
}

contract YieldLayerProxyDeployer {
    address public immutable dTokenImplementation;
    address public immutable vaultImplementation;

    error ZeroAddress();
    error NotContract();

    constructor(address _dTokenImplementation, address _vaultImplementation) {
        if (_dTokenImplementation == address(0) || _vaultImplementation == address(0)) revert ZeroAddress();
        if (_dTokenImplementation.code.length == 0 || _vaultImplementation.code.length == 0) revert NotContract();

        dTokenImplementation = _dTokenImplementation;
        vaultImplementation = _vaultImplementation;
    }

    function deployYieldLayer(
        IERC20MetadataUpgradeable _underlying,
        string memory _dTokenName,
        string memory _dTokenSymbol,
        address _treasury,
        address _finalOwner
    ) external returns (DToken dToken, CollateralVault vault) {
        if (_treasury == address(0) || _finalOwner == address(0)) revert ZeroAddress();

        // Empty constructor data is scoped to this helper call: both proxies are
        // initialized before deployYieldLayer returns, so no external tx can seize them.
        dToken = DToken(address(new ERC1967Proxy(dTokenImplementation, "")));
        vault = CollateralVault(address(new ERC1967Proxy(vaultImplementation, "")));

        dToken.initialize(address(vault), address(this));
        // Fail closed across deploy and governance preparation. Active caps are
        // raised only inside the separately approved controlled-initialization
        // delivery that also creates the bootstrap Troves and seeds each SP.
        dToken.setCap(0);
        if (address(_underlying) != address(0)) {
            dToken.setAllowedUnderlying(address(_underlying), true);
            dToken.setTokenInfo(_dTokenName, _dTokenSymbol, _underlying);
        }

        vault.initialize(IERC20(address(_underlying)), IDToken(address(dToken)), _treasury, _finalOwner);
        dToken.transferOwnership(_finalOwner);
    }
}

contract LocalBridgeAdmin {}

interface ICCIPDeployRegistry {
    function getTokenConfig(address token)
        external
        view
        returns (address administrator, address pendingAdministrator, address tokenPool);
}

contract DeployLiquity2Script is StdCheats, MetadataDeployment, Logging {
    using Strings for *;
    using StringFormatting for *;
    using StringEquality for string;

    string constant DEPLOYMENT_MODE_COMPLETE = "complete";
    string constant DEPLOYMENT_MODE_JPYDF_ONLY = "jpydf-only";
    string constant DEPLOYMENT_MODE_USE_EXISTING_JPYDF = "use-existing-jpydf";
    string constant MAINNET_CANARY_MIN_DEBT_ACK = "JPYDF_MAINNET_CANARY_MIN_DEBT_1000_TEST_ONLY";
    string constant MAINNET_CANARY_REAL_BROADCAST_ACK =
        "JPYDF_MAINNET_CANARY_REAL_MAINNET_BROADCAST_SEPARATELY_APPROVED";
    string constant MAINNET_CANARY_ID = "jpydf-mainnet-persistent-canary-v2-2026-08";
    string constant MAINNET_CANARY_SALT_INPUT = "JPYDF_MAINNET_PERSISTENT_CANARY_V2_2026_08";
    string constant MAINNET_CANARY_MANIFEST_DIR = "canary-artifacts/jpydf-mainnet-persistent-canary-v2-2026-08";
    string constant MAINNET_CANARY_MANIFEST_PATH =
        "canary-artifacts/jpydf-mainnet-persistent-canary-v2-2026-08/deployment-manifest.json";
    string constant MAINNET_CANARY_BROADCAST_PATH =
        "canary-artifacts/jpydf-mainnet-persistent-canary-v2-2026-08/broadcast";
    string constant DEPLOYMENT_CLASSIFICATION_PRODUCTION = "PRODUCTION_CANDIDATE";
    string constant DEPLOYMENT_CLASSIFICATION_TEST_ONLY = "TEST_ONLY_NOT_FOR_PRODUCTION";

    uint256 constant PRODUCTION_MIN_DEBT = 100_000e18;
    uint256 constant MAINNET_CANARY_MIN_DEBT = 1_000e18;
    uint256 constant MAINNET_CANARY_MAX_STRATEGY_CAP = 100e6;
    uint256 constant MAINNET_CANARY_TIMELOCK_MIN_DELAY = 5 minutes;
    address constant MAINNET_DAY1_GAUNTLET_USDC_PRIME_V2 = 0x8c106EEDAd96553e64287A5A6839c3Cc78afA3D0;
    address constant MAINNET_CANARY_GAUNTLET_USDC_PRIME = 0xdd0f28e19C1780eb6396170735D45153D261490d;
    address constant MAINNET_CANARY_TIMELOCK = 0xEd33edB1eA442475eFd076e1AE2C9da9EdaB86f6;
    bytes32 constant MAINNET_CANARY_TIMELOCK_RUNTIME_CODEHASH =
        0x7919dd185a79d90854632f7fa3ce5d7ef7ba8fa01dda17fff718a9be37efa7bc;

    // DF Phase 4: 8 dToken-collateral branches (Parameters.md §1). Mainnet requires
    // explicit DF_ENABLE_MAINNET_DTOKEN_WIRING=true plus production feed/underlying env.
    // Branches 2-7 retain bootstrap-safe params until the production Timelock performs
    // their one-shot risk finalization as part of collateral activation.
    uint256 constant NUM_DF_BRANCHES = 8;
    uint256 constant NUM_DF_ACTIVE_BRANCHES = 2;

    uint256 constant SEPOLIA_CHAIN_ID = 11155111;
    address constant SEPOLIA_LIDO_STETH = 0x3e3FE7dBc6B4C189E7128855dD526361c49b40Af;
    address constant SEPOLIA_LIDO_WSTETH = 0xB82381A3fBD3FaFA77B3a7bE693342618240067b;

    // Local development uses mutable feeds so failure paths can be driven directly. Persistent Sepolia uses
    // immutable always-fresh fixtures and exercises failure/recovery by replacing the PriceFeedProxy source through
    // the production governance path. This prevents a public caller from changing the shared oracle inputs and
    // prevents the long-lived environment from stopping only because a deployment-time fixture timestamp expired.
    uint256 constant DF_LOCAL_COLL_USD_STALENESS = 24 hours;
    uint256 constant DF_DAY1_JPY_USD_STALENESS = 30 hours;
    uint256 constant DF_SEPOLIA_STETH_USD_STALENESS = 24 hours;
    uint256 constant DF_SEPOLIA_USDC_USD_STALENESS = 48 hours;
    uint256 constant DF_SEPOLIA_ETH_USD_STALENESS = 2 hours;
    uint256 constant DF_SEPOLIA_STETH_ETH_STALENESS = 25 hours;
    // 8-decimal Chainlink-style demo answers: stETH $4,000 / stable $1 and
    // JPY/USD 0.00666666 (~150 JPY per USD) => indicative JPY prices of roughly
    // ~720k (dwstETH: displayed price = demo stETH/USD × stEthPerToken (1.2e18 default on
    // LocalWstETH) ÷ JPY rate) / ~150 (dUSDC). Convenience values, not Parameters.md normatives.
    int256 constant DF_DEMO_ETH_USD = 4_000e8;
    int256 constant DF_DEMO_STABLE_USD = 1e8;
    int256 constant DF_DEMO_JPY_USD = 666666; // 0.00666666 with 8 decimals

    // Per-branch production feed selector, registered while creating the dToken collaterals
    // and consumed by _deployPriceFeed (which only receives the collToken address).
    uint8 constant DF_FEED_WSTETH = 1;
    uint8 constant DF_FEED_USDC = 2;

    address dfJpyUsdOracle; // single shared JPY/USD leg (SYS-RISK-001 shape)
    uint256 dfJpyUsdStaleness;
    address dfJpyUsdRateProvider;
    mapping(address dToken => address) dfCollUsdOracle;
    mapping(address dToken => uint256) dfCollUsdStaleness;
    mapping(address dToken => address) dfRedemptionEthUsdOracle;
    mapping(address dToken => uint256) dfRedemptionEthUsdStaleness;
    mapping(address dToken => address) dfRedemptionStEthEthOracle;
    mapping(address dToken => uint256) dfRedemptionStEthEthStaleness;
    mapping(address dToken => uint8) dfFeedKind;

    address WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    // used for gas compensation and as collateral of the first branch
    // tapping disallowed
    IWETH WETH;
    IERC20Metadata USDC;
    bytes32 SALT;
    address deployer;
    address bridgeAdmin;
    IInterestRouter dfInterestRouter;
    YieldLayerProxyDeployer yieldLayerProxyDeployer;
    TimelockController localZapperReferralTimelock;

    uint256 lastTroveIndex;

    struct LiquityContracts {
        IAddressesRegistry addressesRegistry;
        IActivePool activePool;
        IBorrowerOperations borrowerOperations;
        ICollSurplusPool collSurplusPool;
        IDefaultPool defaultPool;
        ISortedTroves sortedTroves;
        IStabilityPool stabilityPool;
        ITroveManager troveManager;
        ITroveNFT troveNFT;
        IMetadataNFT metadataNFT;
        IPriceFeed priceFeed;
        GasPool gasPool;
        IInterestRouter interestRouter;
        IERC20Metadata collToken;
        CollateralYieldZapper collateralYieldZapper;
    }

    struct LiquityContractAddresses {
        address activePool;
        address borrowerOperations;
        address collSurplusPool;
        address defaultPool;
        address sortedTroves;
        address stabilityPool;
        address troveManager;
        address troveNFT;
        address metadataNFT;
        address priceFeed;
        address gasPool;
        address interestRouter;
    }

    struct TroveManagerParams {
        uint256 CCR;
        uint256 MCR;
        uint256 SCR;
        uint256 BCR;
        uint256 LIQUIDATION_PENALTY_SP;
        uint256 LIQUIDATION_PENALTY_REDISTRIBUTION;
    }

    struct DeploymentVars {
        uint256 numCollaterals;
        IERC20Metadata[] collaterals;
        IAddressesRegistry[] addressesRegistries;
        ITroveManager[] troveManagers;
        LiquityContracts contracts;
        bytes bytecode;
        address jpydfTokenAddress;
        address riskParamsFinalizer;
        uint256 i;
    }

    struct DeploymentResult {
        LiquityContracts[] contractsArray;
        ICollateralRegistry collateralRegistry;
        IJpydfToken jpydfToken;
        HintHelpers hintHelpers;
        LiquidationCandidateGetter liquidationCandidateGetter;
        MultiTroveGetter multiTroveGetter;
        IDebtInFrontHelper debtInFrontHelper;
        IRedemptionHelper redemptionHelper;
        // DF Phase 4 yield layer (parallel to contractsArray)
        CollateralVault[] vaults;
        DToken[] dTokens;
        IStrategy[] strategies;
        IERC20Metadata[] underlyings;
    }

    struct SkyStrategyVenue {
        IERC20Metadata usds;
        IERC4626 susdsVault;
        ISkyUsdcSUsdsConverter converter;
    }

    function run() external {
        _requireProductionMinDebt(MIN_DEBT);
        string memory saltStr = vm.envOr("SALT", string(""));
        if (bytes(saltStr).length == 0 && block.chainid != 1) saltStr = block.timestamp.toString();
        SALT = keccak256(bytes(saltStr));
        string memory manifestPath = _deploymentManifestPath();

        bytes memory encodedDeployer = vm.envBytes("DEPLOYER");
        ScriptSecurityPolicy.requirePublicAddress("DEPLOYER", encodedDeployer);
        deployer = vm.envAddress("DEPLOYER");

        string memory deploymentMode = vm.envOr("DEPLOYMENT_MODE", DEPLOYMENT_MODE_COMPLETE);
        require(
            deploymentMode.eq(DEPLOYMENT_MODE_COMPLETE) || deploymentMode.eq(DEPLOYMENT_MODE_JPYDF_ONLY)
                || deploymentMode.eq(DEPLOYMENT_MODE_USE_EXISTING_JPYDF),
            string.concat("Bad deployment mode: ", deploymentMode)
        );

        // Sepolia branch 0 deliberately exercises Lido's deprecated deployment. Probe its current
        // state before starting the broadcast so a paused or miswired dependency cannot consume
        // deployment gas. jpydf-only mode does not deploy a collateral branch and therefore skips it.
        if (_isSepolia() && !deploymentMode.eq(DEPLOYMENT_MODE_JPYDF_ONLY)) {
            _validateSepoliaLidoWiring();
        }

        vm.startBroadcast(deployer);
        bool mainnetDTokenWiring = block.chainid == 1 && _envFlag("DF_ENABLE_MAINNET_DTOKEN_WIRING");
        _validateRunModeGates(deploymentMode, mainnetDTokenWiring, saltStr, manifestPath);
        if (_isMainnetCanaryBuild()) vm.createDir(MAINNET_CANARY_MANIFEST_DIR, true);

        // Fail-closed guard for the implicit "non-mainnet == local wiring" equation: on a chain
        // that is neither mainnet nor a recognized test chain (local Anvil 31337, AWS hosted
        // staging Anvil 31338, Sepolia 11155111), deploying test underlyings / oracle inputs and deployer-held roles must
        // be an explicit decision, never a silent default.
        if (block.chainid != 1 && !_isLocalDevChain() && !_isSepolia()) {
            require(
                _envFlag("DF_ALLOW_TEST_WIRING"),
                "DeployLiquity2: test wiring on unrecognized chain requires DF_ALLOW_TEST_WIRING=true"
            );
        }

        _log("Deployer:               ", deployer.toHexString());
        _log("Deployer balance:       ", deployer.balance.decimal());
        _log("Deployment mode:        ", deploymentMode);
        _log("CREATE2 salt:           ", 'keccak256(bytes("', saltStr, '")) = ', uint256(SALT).toHexString());
        _log("DF dToken wiring:       yes");
        _log("Token identity:         ", _isMainnetStaging() ? "testJPYdf (TEST ONLY)" : "JPYdf");

        // Deploy JPYDF or pick up existing deployment
        bridgeAdmin = _resolveBridgeAdmin();
        _log("Bridge admin:           ", bridgeAdmin.toHexString());

        bytes memory jpydfBytecode =
            bytes.concat(type(JpydfToken).creationCode, abi.encode(deployer, bridgeAdmin, _isMainnetStaging()));
        address jpydfAddress = vm.computeCreate2Address(SALT, keccak256(jpydfBytecode));
        JpydfToken jpydfToken;

        if (deploymentMode.eq(DEPLOYMENT_MODE_USE_EXISTING_JPYDF)) {
            require(jpydfAddress.code.length > 0, string.concat("JPYDF not found at ", jpydfAddress.toHexString()));
            jpydfToken = JpydfToken(jpydfAddress);

            // Check JPYDF is untouched
            require(jpydfToken.totalSupply() == 0, "Some JPYDF has been minted!");
            require(jpydfToken.collateralRegistryAddress() == address(0), "Collateral registry already set");
            require(jpydfToken.owner() == deployer, "Not JPYDF owner");
            require(jpydfToken.bridgeAdmin() == bridgeAdmin, "Wrong JPYDF bridge admin");
            require(jpydfToken.bridgeMinterCount() == 0, "JPYDF bridge minters already set");
            require(jpydfToken.proposedBridgeMinter() == address(0), "JPYDF bridge minter pending");
            require(jpydfToken.pendingBridgeAdmin() == address(0), "JPYDF bridge admin pending");
            if (_envFlag("DF_REQUIRE_CCIP_HANDOFF")) _requireCCIPHandoff(jpydfAddress);
        } else {
            jpydfToken = new JpydfToken{salt: SALT}(deployer, bridgeAdmin, _isMainnetStaging());
            assert(address(jpydfToken) == jpydfAddress);
        }

        if (deploymentMode.eq(DEPLOYMENT_MODE_JPYDF_ONLY)) {
            vm.writeFile(
                manifestPath,
                _withDeploymentMetadata(
                    string.concat(
                        '{"jpydfToken":"',
                        jpydfAddress.toHexString(),
                        '",',
                        _getBridgeReadinessJson(jpydfToken),
                        '"deploymentMode":"jpydf-only"}'
                    ),
                    deploymentMode
                )
            );
            return;
        }

        _configureBaseTokens();

        TroveManagerParams[] memory troveManagerParamsArray;
        string[] memory collNames;
        string[] memory collSymbols;

        (troveManagerParamsArray, collNames, collSymbols) = _dfBranchParams();

        DeploymentResult memory deployed =
            _deployAndConnectContracts(troveManagerParamsArray, collNames, collSymbols, jpydfToken);

        // DF Phase 4: hard-verify the dToken wiring before anything else.
        _verifyDFWiring(deployed);

        // DF Phase 4: Day-1 JPYdf liquidity standardizes on JPYdf/USDC Uniswap v4.
        // Flash-close / collateral-funded repay / Multiply are not kept in the
        // Day-1 ABI; future support must be added as a new audited route.

        // Stateless reporting views for every branch's CollateralVault. Must be inside the
        // broadcast or it is only simulated, and the manifest would record an address with no
        // code at it. Kept out of `_getManifestJson`, which is already at the stack limit.
        address collateralVaultLens = address(new CollateralVaultLens());
        vm.stopBroadcast();
        _writeCompleteDeploymentManifest(manifestPath, deployed, collateralVaultLens, deploymentMode);
    }

    function _writeCompleteDeploymentManifest(
        string memory _manifestPath,
        DeploymentResult memory _deployed,
        address _collateralVaultLens,
        string memory _deploymentMode
    ) internal {
        string memory manifest = _withCollateralVaultLens(_getManifestJson(_deployed), _collateralVaultLens);
        vm.writeFile(_manifestPath, _withDeploymentMetadata(manifest, _deploymentMode));
    }

    /// @dev Keeps an explicit verification deployment from overwriting the canonical local manifest.
    ///      The default preserves the established non-pilot deployment workflow.
    function _deploymentManifestPath() internal view returns (string memory) {
        if (_isMainnetCanaryBuild()) {
            return vm.envOr("DF_DEPLOYMENT_MANIFEST", string(""));
        }
        return vm.envOr("DF_DEPLOYMENT_MANIFEST", string("deployment-manifest.json"));
    }

    function _envFlag(string memory _key) internal view returns (bool) {
        string memory value = vm.envOr(_key, string("false"));
        return value.eq("true") || value.eq("1") || value.eq("yes");
    }

    function _isLocalDevChain() internal view returns (bool) {
        return block.chainid == 31337 || block.chainid == 31338;
    }

    function _configureBaseTokens() internal {
        if (block.chainid == 1) {
            WETH = IWETH(WETH_ADDRESS);
            USDC = IERC20Metadata(USDC_ADDRESS);
            return;
        }

        if (_isLocalDevChain()) {
            WETH = new LocalWETH({_tapAmount: 100 ether, _tapPeriod: 1 days});
            USDC = new LocalERC20FaucetDecimals("USDC", "USDC", 6, 0, type(uint256).max);
            return;
        }

        // Public-test deployments keep gas-compensation WETH local. Sepolia
        // binds dUSDC to the exact USDC reserve used by Aave V3 Sepolia so the
        // production Strategy can be exercised against the live venue.
        WETH = new LocalWETH({_tapAmount: 0, _tapPeriod: type(uint256).max});
        if (block.chainid == 11155111) {
            _requireContract(SepoliaExternalAddresses.AAVE_USDC, "SEPOLIA_AAVE_USDC");
            USDC = IERC20Metadata(SepoliaExternalAddresses.AAVE_USDC);
            require(USDC.decimals() == 6, "DeployLiquity2: Sepolia USDC decimals");
            require(keccak256(bytes(USDC.symbol())) == keccak256("USDC"), "DeployLiquity2: Sepolia USDC symbol");
            return;
        }

        // Explicitly allowed unknown test chains retain self-contained mock wiring.
        USDC = new LocalERC20FaucetDecimals("USDC", "USDC", 6, 0, type(uint256).max);
    }

    function _isSepolia() internal view returns (bool) {
        return block.chainid == SEPOLIA_CHAIN_ID;
    }

    /// @notice Read-only preflight for a Sepolia collateral deployment.
    /// @dev Can be run independently with forge script --sig validateSepoliaLidoWiring().
    function validateSepoliaLidoWiring() external view {
        require(_isSepolia(), "DeployLiquity2: Sepolia Lido preflight requires chain 11155111");
        _validateSepoliaLidoWiring();
    }

    function _validateSepoliaLidoWiring() internal view {
        address configuredWstEth = _dfRequiredBranchAddress("DF_UNDERLYING", 0);
        address configuredStEth = _dfRequiredBranchAddress("DF_ZAPPER_EXPECTED_STETH", 0);

        _validateSepoliaLidoWiring(configuredWstEth, configuredStEth);
    }

    function _validateSepoliaLidoWiring(address configuredWstEth, address configuredStEth) internal view {
        require(configuredWstEth == SEPOLIA_LIDO_WSTETH, "DF: noncanonical Sepolia Lido wstETH");
        require(configuredStEth == SEPOLIA_LIDO_STETH, "DF: noncanonical Sepolia Lido stETH");
        _requireContract(configuredWstEth, "DF_UNDERLYING_0");
        _requireContract(configuredStEth, "DF_ZAPPER_EXPECTED_STETH_0");

        try ISepoliaLidoWstEthPreflight(configuredWstEth).stETH() returns (address resolvedStEth) {
            require(resolvedStEth == configuredStEth, "DF: Sepolia Lido stETH mismatch");
        } catch {
            revert("DF: Sepolia Lido stETH probe failed");
        }

        try ISepoliaLidoWstEthPreflight(configuredWstEth).stEthPerToken() returns (uint256 rate) {
            require(rate != 0, "DF: Sepolia Lido wstETH rate is zero");
        } catch {
            revert("DF: Sepolia Lido wstETH rate probe failed");
        }

        try ISepoliaLidoStEthPreflight(configuredStEth).isStakingPaused() returns (bool paused) {
            require(!paused, "DF: Sepolia Lido staking is paused");
        } catch {
            revert("DF: Sepolia Lido staking pause probe failed");
        }

        try ISepoliaLidoStEthPreflight(configuredStEth).isStopped() returns (bool stopped) {
            require(!stopped, "DF: Sepolia Lido is stopped");
        } catch {
            revert("DF: Sepolia Lido stopped probe failed");
        }

        try ISepoliaLidoStEthPreflight(configuredStEth).getCurrentStakeLimit() returns (uint256 stakeLimit) {
            require(stakeLimit != 0, "DF: Sepolia Lido stake limit exhausted");
        } catch {
            revert("DF: Sepolia Lido stake limit probe failed");
        }
    }

    // Ethereum registration is shared by future EVM and Solana destinations.
    // Transport/pool activation remains a separate governance operation.
    function _requireCCIPHandoff(address token) internal view {
        address timelock = vm.envAddress("DF_TIMELOCK");
        MainnetProductionTimelockPolicy.requireValid(timelock);
        (address admin, address pending, address pool) =
            ICCIPDeployRegistry(0xb22764f98dD05c789929716D677382Df22C05Cb6).getTokenConfig(token);
        require(admin == timelock, "CCIP handoff: wrong administrator");
        require(pending == address(0), "CCIP handoff: administrator pending");
        require(pool == address(0), "CCIP handoff: pool already active");
    }

    function _validateCCIPDeploymentMode(string memory mode) internal view {
        require(block.chainid == 1, "CCIP handoff: Ethereum only");
        require(!mode.eq(DEPLOYMENT_MODE_COMPLETE), "CCIP handoff: split deployment required");
    }

    function _validateRunModeGates(
        string memory _deploymentMode,
        bool _mainnetDTokenWiring,
        string memory _saltInput,
        string memory _manifestPath
    ) internal {
        if (_isMainnetStaging()) {
            require(block.chainid == 1, "DeployLiquity2: staging requires Ethereum mainnet");
            require(_saltInput.eq("JPYDF_MAINNET_STAGING_20260924_01"), "DeployLiquity2: staging salt mismatch");
            require(_envFlag("DF_REQUIRE_CCIP_HANDOFF"), "DeployLiquity2: staging requires CCIP handoff");
            require(
                _manifestPath.eq(
                    string.concat(
                        "verification-manifests/mainnet-staging-20260924-01/",
                        _deploymentMode.eq(DEPLOYMENT_MODE_JPYDF_ONLY)
                            ? "token-manifest.json"
                            : "deployment-manifest.json"
                    )
                ),
                "DeployLiquity2: staging manifest path mismatch"
            );
        }
        if (block.chainid == 1 && !_isMainnetStaging()) {
            require(!_saltInput.eq("JPYDF_MAINNET_STAGING_20260924_01"), "DeployLiquity2: staging salt requires staging profile");
        }
        if (_envFlag("DF_REQUIRE_CCIP_HANDOFF")) _validateCCIPDeploymentMode(_deploymentMode);
        require(
            block.chainid != 1 || _deploymentMode.eq(DEPLOYMENT_MODE_JPYDF_ONLY) || _mainnetDTokenWiring,
            "DeployLiquity2: mainnet dToken wiring disabled"
        );
        require(block.chainid != 1 || bytes(_saltInput).length != 0, "DeployLiquity2: mainnet requires explicit SALT");

        if (block.chainid == 1 && MIN_DEBT != PRODUCTION_MIN_DEBT) {
            require(_isMainnetCanaryBuild(), "DeployLiquity2: unsupported mainnet non-production build");
            _validateMainnetCanaryGates(
                MIN_DEBT,
                _deploymentMode,
                _saltInput,
                _manifestPath,
                vm.envOr("DF_MAINNET_CANARY_MIN_DEBT_ACK", string("")),
                vm.envOr("DF_MAINNET_CANARY_ID", string("")),
                vm.envOr("FOUNDRY_BROADCAST", string("")),
                vm.envOr("DF_MAINNET_CANARY_EXPECTED_DEPLOYER", address(0)),
                vm.envOr("DF_BRIDGE_ADMIN", string(""))
            );
            _requireMainnetCanaryExecutionBoundary();
        }
    }

    function _requireMainnetCanaryExecutionBoundary() internal {
        if (vm.envOr("DF_MAINNET_CANARY_REAL_BROADCAST_ACK", string("")).eq(MAINNET_CANARY_REAL_BROADCAST_ACK)) {
            return;
        }

        try vm.rpc("anvil_nodeInfo", "[]") returns (bytes memory nodeInfo) {
            require(nodeInfo.length != 0, "DeployLiquity2: empty Anvil node info");
            return;
        } catch {
            revert("DeployLiquity2: canary execution requires local Anvil or explicit real-mainnet ack");
        }
    }

    function _validateMainnetCanaryGates(
        uint256 _actualMinDebt,
        string memory _deploymentMode,
        string memory _saltInput,
        string memory _manifestPath,
        string memory _minDebtAck,
        string memory _canaryId,
        string memory _broadcastPath,
        address _expectedDeployer,
        string memory _bridgeAdmin
    ) internal view {
        require(_actualMinDebt == MAINNET_CANARY_MIN_DEBT, "DeployLiquity2: unsupported non-production MIN_DEBT");
        require(_deploymentMode.eq(DEPLOYMENT_MODE_COMPLETE), "DeployLiquity2: canary requires complete deployment");
        require(_minDebtAck.eq(MAINNET_CANARY_MIN_DEBT_ACK), "DeployLiquity2: explicit canary MIN_DEBT ack required");
        require(_canaryId.eq(MAINNET_CANARY_ID), "DeployLiquity2: exact canary id required");
        require(_saltInput.eq(MAINNET_CANARY_SALT_INPUT), "DeployLiquity2: exact canary salt required");
        require(
            _manifestPath.eq(MAINNET_CANARY_MANIFEST_PATH), "DeployLiquity2: isolated canary manifest path required"
        );
        require(
            _broadcastPath.eq(MAINNET_CANARY_BROADCAST_PATH), "DeployLiquity2: isolated canary broadcast path required"
        );
        require(_expectedDeployer == deployer, "DeployLiquity2: canary deployer confirmation mismatch");
        require(_bridgeAdmin.eq(""), "DeployLiquity2: canary bridge admin must be inert");
    }

    function _requireProductionMinDebt(uint256 _actualMinDebt) internal view {
        if (block.chainid == 1) {
            require(_actualMinDebt == PRODUCTION_MIN_DEBT, "DeployLiquity2: production MIN_DEBT must be 100,000e18");
        }
    }

    function _isMainnetStaging() internal view returns (bool) {
        return _envFlag("DF_MAINNET_STAGING");
    }

    function _isMainnetCanaryBuild() internal view returns (bool) {
        return block.chainid == 1 && MIN_DEBT != PRODUCTION_MIN_DEBT
            && vm.envOr("DF_MAINNET_CANARY_ID", string("")).eq(MAINNET_CANARY_ID);
    }

    // See: https://solidity-by-example.org/app/create2/
    function getBytecode(bytes memory _creationCode, address _addressesRegistry) public pure returns (bytes memory) {
        return abi.encodePacked(_creationCode, abi.encode(_addressesRegistry));
    }

    function _deployAndConnectContracts(
        TroveManagerParams[] memory troveManagerParamsArray,
        string[] memory _collNames,
        string[] memory _collSymbols,
        JpydfToken _jpydfToken
    ) internal returns (DeploymentResult memory r) {
        require(troveManagerParamsArray.length > 0, "DeployLiquity2: empty branch params");
        require(troveManagerParamsArray.length <= 10, "DeployLiquity2: too many branches");
        require(_collNames.length + 1 == troveManagerParamsArray.length, "DeployLiquity2: name count mismatch");
        require(_collSymbols.length == _collNames.length, "DeployLiquity2: symbol count mismatch");

        DeploymentVars memory vars;
        vars.numCollaterals = troveManagerParamsArray.length;
        r.jpydfToken = _jpydfToken;
        (dfInterestRouter,) = _deployInterestRouter(r.jpydfToken);

        r.contractsArray = new LiquityContracts[](vars.numCollaterals);
        vars.collaterals = new IERC20Metadata[](vars.numCollaterals);
        vars.addressesRegistries = new IAddressesRegistry[](vars.numCollaterals);
        vars.troveManagers = new ITroveManager[](vars.numCollaterals);

        // Collaterals
        {
            bool mainnetDTokenWiring = block.chainid == 1;

            // DF Phase 4: every branch's core collateral is a dToken wrapping its Underlying
            // (ADR-002). Active branches 0..NUM_DF_ACTIVE_BRANCHES-1 get real underlyings + the
            // selected PRODUCTION Strategy; inert branches stay TokenInfo-less with cap 0.
            r.vaults = new CollateralVault[](vars.numCollaterals);
            r.dTokens = new DToken[](vars.numCollaterals);
            r.strategies = new IStrategy[](vars.numCollaterals);
            r.underlyings = new IERC20Metadata[](vars.numCollaterals);

            if (mainnetDTokenWiring) {
                dfJpyUsdOracle = _dfRequiredAddress("DF_JPY_USD_FEED");
                _requireContract(dfJpyUsdOracle, "DF_JPY_USD_FEED");
                dfJpyUsdStaleness = _dfRequiredUint("DF_JPY_USD_STALENESS");
                require(dfJpyUsdStaleness == DF_DAY1_JPY_USD_STALENESS, "DF: JPY staleness must be 30h");
                for (vars.i = 0; vars.i < NUM_DF_ACTIVE_BRANCHES; vars.i++) {
                    _requireMainnetDay1StrategyPolicy(vars.i);
                }

                // Branch 0 is wstETH, NOT the protocol WETH (which stays gas-comp-only),
                // so it has no defaultable address: it must be configured explicitly.
                r.underlyings[0] = IERC20Metadata(_dfRequiredBranchAddress("DF_UNDERLYING", 0));
                r.underlyings[1] = IERC20Metadata(vm.envOr(_dfEnvKey("DF_UNDERLYING", 1), address(USDC)));
                for (vars.i = 0; vars.i < NUM_DF_ACTIVE_BRANCHES; vars.i++) {
                    _requireContract(address(r.underlyings[vars.i]), _dfEnvKey("DF_UNDERLYING", vars.i));
                }
            } else {
                // Sepolia rehearses the production Day-1 Strategy topology. Local chains keep their independently
                // configurable integration fixtures.
                _requireSepoliaDay1StrategyPolicy();

                // Single shared JPY/USD leg for all production feeds (the SYS-RISK-001 shape:
                // one FX dependency across branches). Persistent Sepolia uses an immutable fixture;
                // resettable local chains retain the settable fixture used by failure drills.
                if (_isSepolia()) {
                    dfJpyUsdOracle = address(new SepoliaChainlinkAggregator(8, DF_DEMO_JPY_USD));
                } else {
                    LocalChainlinkAggregator jpyUsdFeed = new LocalChainlinkAggregator();
                    jpyUsdFeed.setDecimals(8);
                    jpyUsdFeed.setAnswer(DF_DEMO_JPY_USD);
                    jpyUsdFeed.setUpdatedAt(block.timestamp);
                    dfJpyUsdOracle = address(jpyUsdFeed);
                }
                dfJpyUsdStaleness = DF_DAY1_JPY_USD_STALENESS;

                // Sepolia branch 0 uses Lido's canonical wstETH after the run-level preflight.
                // Local dev chains retain the controllable Lido-compatible fixture. The
                // deployment-wide WETH stays gas-comp-only in both cases. Branch 1 reuses the
                // deployment-wide test USDC; branches 2-7 remain unbound.
                if (_isSepolia()) {
                    r.underlyings[0] = IERC20Metadata(_dfRequiredBranchAddress("DF_UNDERLYING", 0));
                } else {
                    LocalStETH localStEth = new LocalStETH();
                    r.underlyings[0] = IERC20Metadata(
                        address(new LocalWstETH({_stEthToken: localStEth, _tapAmount: 100e18, _tapPeriod: 1 days}))
                    );
                }
                r.underlyings[1] = USDC;
            }

            // One deployed state machine owns the shared FX cache and freeze clock.
            // Passing the raw aggregator to every branch would recreate independent
            // last-good rates and timers even though the underlying oracle is shared.
            dfJpyUsdRateProvider = address(new JpyUsdRateProvider{salt: SALT}(dfJpyUsdOracle, dfJpyUsdStaleness));

            for (vars.i = 0; vars.i < vars.numCollaterals; vars.i++) {
                bool active = vars.i < NUM_DF_ACTIVE_BRANCHES;
                string memory dTokenSlot = _dfDTokenSlot(vars.i);
                (DToken dToken, CollateralVault vault) = _deployYieldLayer(
                    active ? r.underlyings[vars.i] : IERC20Metadata(address(0)),
                    active ? string.concat("DToken ", _isMainnetStaging() ? "test" : "", dTokenSlot) : "",
                    active ? string.concat(_isMainnetStaging() ? "test" : "", dTokenSlot) : ""
                );
                r.dTokens[vars.i] = dToken;
                r.vaults[vars.i] = vault;
                vars.collaterals[vars.i] = IERC20Metadata(address(dToken));
                if (active) {
                    // Register the production feed selector + this branch's collateral/USD
                    // oracle, both consumed later by _deployPriceFeed.
                    uint8 kind = vars.i == 0 ? DF_FEED_WSTETH : DF_FEED_USDC;
                    dfFeedKind[address(dToken)] = kind;
                    if (mainnetDTokenWiring) {
                        address collUsdFeed = _dfRequiredBranchAddress("DF_COLL_USD_FEED", vars.i);
                        _requireContract(collUsdFeed, _dfEnvKey("DF_COLL_USD_FEED", vars.i));
                        dfCollUsdOracle[address(dToken)] = collUsdFeed;
                        dfCollUsdStaleness[address(dToken)] = _dfRequiredBranchUint("DF_COLL_USD_STALENESS", vars.i);
                        if (kind == DF_FEED_WSTETH) {
                            address redemptionEthUsdFeed =
                                _dfRequiredBranchAddress("DF_REDEMPTION_ETH_USD_FEED", vars.i);
                            _requireContract(redemptionEthUsdFeed, _dfEnvKey("DF_REDEMPTION_ETH_USD_FEED", vars.i));
                            dfRedemptionEthUsdOracle[address(dToken)] = redemptionEthUsdFeed;
                            dfRedemptionEthUsdStaleness[address(dToken)] =
                                _dfRequiredBranchUint("DF_REDEMPTION_ETH_USD_STALENESS", vars.i);
                            address redemptionStEthEthFeed =
                                _dfRequiredBranchAddress("DF_REDEMPTION_STETH_ETH_FEED", vars.i);
                            _requireContract(redemptionStEthEthFeed, _dfEnvKey("DF_REDEMPTION_STETH_ETH_FEED", vars.i));
                            dfRedemptionStEthEthOracle[address(dToken)] = redemptionStEthEthFeed;
                            dfRedemptionStEthEthStaleness[address(dToken)] =
                                _dfRequiredBranchUint("DF_REDEMPTION_STETH_ETH_STALENESS", vars.i);
                        }
                    } else {
                        int256 collUsdAnswer = kind == DF_FEED_WSTETH ? DF_DEMO_ETH_USD : DF_DEMO_STABLE_USD;
                        if (_isSepolia()) {
                            dfCollUsdOracle[address(dToken)] = address(new SepoliaChainlinkAggregator(8, collUsdAnswer));
                        } else {
                            LocalChainlinkAggregator collUsdFeed = new LocalChainlinkAggregator();
                            collUsdFeed.setDecimals(8);
                            // Branch 0's demo answer is the stETH/USD leg: the displayed dwstETH
                            // price is demo × stEthPerToken ÷ JPY rate (composite feed).
                            collUsdFeed.setAnswer(collUsdAnswer);
                            collUsdFeed.setUpdatedAt(block.timestamp);
                            dfCollUsdOracle[address(dToken)] = address(collUsdFeed);
                        }
                        dfCollUsdStaleness[address(dToken)] = _isSepolia()
                            ? (kind == DF_FEED_WSTETH ? DF_SEPOLIA_STETH_USD_STALENESS : DF_SEPOLIA_USDC_USD_STALENESS)
                            : DF_LOCAL_COLL_USD_STALENESS;
                        if (kind == DF_FEED_WSTETH) {
                            if (_isSepolia()) {
                                dfRedemptionEthUsdOracle[address(dToken)] =
                                    address(new SepoliaChainlinkAggregator(8, DF_DEMO_ETH_USD));
                                dfRedemptionEthUsdStaleness[address(dToken)] = DF_SEPOLIA_ETH_USD_STALENESS;
                                dfRedemptionStEthEthOracle[address(dToken)] =
                                    address(new SepoliaChainlinkAggregator(18, 1e18));
                                dfRedemptionStEthEthStaleness[address(dToken)] = DF_SEPOLIA_STETH_ETH_STALENESS;
                            } else {
                                LocalChainlinkAggregator redemptionEthUsdFeed = new LocalChainlinkAggregator();
                                redemptionEthUsdFeed.setDecimals(8);
                                redemptionEthUsdFeed.setAnswer(DF_DEMO_ETH_USD);
                                redemptionEthUsdFeed.setUpdatedAt(block.timestamp);
                                dfRedemptionEthUsdOracle[address(dToken)] = address(redemptionEthUsdFeed);
                                dfRedemptionEthUsdStaleness[address(dToken)] = DF_LOCAL_COLL_USD_STALENESS;

                                LocalChainlinkAggregator redemptionStEthEthFeed = new LocalChainlinkAggregator();
                                redemptionStEthEthFeed.setDecimals(18);
                                redemptionStEthEthFeed.setAnswer(1e18);
                                redemptionStEthEthFeed.setUpdatedAt(block.timestamp);
                                dfRedemptionStEthEthOracle[address(dToken)] = address(redemptionStEthEthFeed);
                                dfRedemptionStEthEthStaleness[address(dToken)] = DF_LOCAL_COLL_USD_STALENESS;
                            }
                        }
                    }

                    r.strategies[vars.i] = _deployAndRegisterStrategies(vars.i, vault, r.underlyings[vars.i]);
                }
            }
        }

        // One canonical Timelock owns the one-shot risk finalization for every reserved
        // branch. Active branches 0-1 pass zero and are finalized in the constructor.
        vars.riskParamsFinalizer = _resolveZapperLidoReferralManager();

        // Deploy AddressesRegistries and get TroveManager addresses
        for (vars.i = 0; vars.i < vars.numCollaterals; vars.i++) {
            (IAddressesRegistry addressesRegistry, address troveManagerAddress) = _deployAddressesRegistry(
                troveManagerParamsArray[vars.i], vars.i < NUM_DF_ACTIVE_BRANCHES ? address(0) : vars.riskParamsFinalizer,
                _collGasCompensationCap(vars.i)
            );
            vars.addressesRegistries[vars.i] = addressesRegistry;
            vars.troveManagers[vars.i] = ITroveManager(troveManagerAddress);
        }

        r.collateralRegistry = new CollateralRegistry(r.jpydfToken, vars.collaterals, vars.troveManagers);
        r.hintHelpers = new HintHelpers(r.collateralRegistry);
        r.multiTroveGetter = new MultiTroveGetter(r.collateralRegistry);
        r.liquidationCandidateGetter = new LiquidationCandidateGetter(r.collateralRegistry);
        r.debtInFrontHelper = new DebtInFrontHelper(r.collateralRegistry, r.hintHelpers);

        // Deploy per-branch contracts for each branch
        for (vars.i = 0; vars.i < vars.numCollaterals; vars.i++) {
            vars.contracts = _deployAndConnectCollateralContracts(
                vars.collaterals[vars.i],
                r.jpydfToken,
                r.collateralRegistry,
                vars.addressesRegistries[vars.i],
                address(vars.troveManagers[vars.i]),
                r.hintHelpers,
                r.multiTroveGetter,
                dfInterestRouter,
                r.vaults[vars.i],
                vars.i < NUM_DF_ACTIVE_BRANCHES ? r.underlyings[vars.i] : IERC20Metadata(address(0)),
                vars.i
            );
            r.contractsArray[vars.i] = vars.contracts;
        }

        r.jpydfToken.setCollateralRegistry(address(r.collateralRegistry));

        r.redemptionHelper = new RedemptionHelper(r.collateralRegistry, vars.addressesRegistries);
    }

    function _collGasCompensationCap(uint256 _branchIndex) internal pure returns (uint256) {
        // Reserved caps are bootstrap inputs; finalizeRiskParams sets the collateral-specific cap before activation.
        return _branchIndex == 0 ? COLL_GAS_COMPENSATION_CAP_DWSTETH : COLL_GAS_COMPENSATION_CAP;
    }

    function _deployAddressesRegistry(TroveManagerParams memory _troveManagerParams, address _riskParamsFinalizer, uint256 _gasCap)
        internal
        returns (IAddressesRegistry, address)
    {
        IAddressesRegistry addressesRegistry = new AddressesRegistry(
            deployer,
            _troveManagerParams.CCR,
            _troveManagerParams.MCR,
            _troveManagerParams.BCR,
            _troveManagerParams.SCR,
            _troveManagerParams.LIQUIDATION_PENALTY_SP,
            _troveManagerParams.LIQUIDATION_PENALTY_REDISTRIBUTION,
            _riskParamsFinalizer
        );
        address troveManagerAddress = vm.computeCreate2Address(
            SALT, keccak256(abi.encodePacked(type(TroveManager).creationCode, abi.encode(addressesRegistry, _gasCap)))
        );

        return (addressesRegistry, troveManagerAddress);
    }

    function _deployAndConnectCollateralContracts(
        IERC20Metadata _collToken,
        IJpydfToken _jpydfToken,
        ICollateralRegistry _collateralRegistry,
        IAddressesRegistry _addressesRegistry,
        address _troveManagerAddress,
        IHintHelpers _hintHelpers,
        IMultiTroveGetter _multiTroveGetter,
        IInterestRouter _interestRouter,
        CollateralVault _collateralVault,
        IERC20Metadata _underlyingToken,
        uint256 _branchIndex
    ) internal returns (LiquityContracts memory contracts) {
        LiquityContractAddresses memory addresses;
        contracts.collToken = _collToken;

        // Deploy all contracts, using testers for TM and PriceFeed
        contracts.addressesRegistry = _addressesRegistry;

        // Deploy Metadata
        contracts.metadataNFT = deployJPYdfMetadata(SALT);
        addresses.metadataNFT = vm.computeCreate2Address(
            SALT, keccak256(getBytecode(type(JPYdfMetadataNFT).creationCode, address(initializedFixedAssetReader)))
        );
        assert(address(contracts.metadataNFT) == addresses.metadataNFT);

        contracts.interestRouter = _interestRouter;
        addresses.borrowerOperations = vm.computeCreate2Address(
            SALT, keccak256(getBytecode(type(BorrowerOperations).creationCode, address(contracts.addressesRegistry)))
        );
        addresses.troveManager = _troveManagerAddress;
        addresses.troveNFT = vm.computeCreate2Address(
            SALT, keccak256(getBytecode(type(JPYdfTroveNFT).creationCode, address(contracts.addressesRegistry)))
        );
        addresses.stabilityPool = vm.computeCreate2Address(
            SALT, keccak256(getBytecode(type(DFStabilityPool).creationCode, address(contracts.addressesRegistry)))
        );
        addresses.activePool = vm.computeCreate2Address(
            SALT, keccak256(getBytecode(type(ActivePool).creationCode, address(contracts.addressesRegistry)))
        );
        addresses.defaultPool = vm.computeCreate2Address(
            SALT, keccak256(getBytecode(type(DefaultPool).creationCode, address(contracts.addressesRegistry)))
        );
        addresses.gasPool = vm.computeCreate2Address(
            SALT, keccak256(getBytecode(type(GasPool).creationCode, address(contracts.addressesRegistry)))
        );
        addresses.collSurplusPool = vm.computeCreate2Address(
            SALT, keccak256(getBytecode(type(CollSurplusPool).creationCode, address(contracts.addressesRegistry)))
        );
        addresses.sortedTroves = vm.computeCreate2Address(
            SALT, keccak256(getBytecode(type(SortedTroves).creationCode, address(contracts.addressesRegistry)))
        );

        contracts.priceFeed = _deployPriceFeed(address(_collToken), addresses.borrowerOperations);

        IAddressesRegistry.AddressVars memory addressVars = IAddressesRegistry.AddressVars({
            collToken: _collToken,
            borrowerOperations: IBorrowerOperations(addresses.borrowerOperations),
            troveManager: ITroveManager(addresses.troveManager),
            troveNFT: ITroveNFT(addresses.troveNFT),
            metadataNFT: IMetadataNFT(addresses.metadataNFT),
            stabilityPool: IStabilityPool(addresses.stabilityPool),
            priceFeed: contracts.priceFeed,
            activePool: IActivePool(addresses.activePool),
            defaultPool: IDefaultPool(addresses.defaultPool),
            gasPoolAddress: addresses.gasPool,
            collSurplusPool: ICollSurplusPool(addresses.collSurplusPool),
            sortedTroves: ISortedTroves(addresses.sortedTroves),
            interestRouter: contracts.interestRouter,
            hintHelpers: _hintHelpers,
            multiTroveGetter: _multiTroveGetter,
            collateralRegistry: _collateralRegistry,
            jpydfToken: _jpydfToken,
            WETH: WETH
        });
        contracts.addressesRegistry.setAddresses(addressVars);

        if (address(_collateralVault) != address(0)) {
            DToken(address(_collToken)).setRiskParamsRegistry(address(contracts.addressesRegistry));
        }

        contracts.borrowerOperations = new BorrowerOperations{salt: SALT}(contracts.addressesRegistry);
        contracts.troveManager = new TroveManager{salt: SALT}(contracts.addressesRegistry, _collGasCompensationCap(_branchIndex));
        contracts.troveNFT = new JPYdfTroveNFT{salt: SALT}(contracts.addressesRegistry);
        contracts.stabilityPool = new DFStabilityPool{salt: SALT}(contracts.addressesRegistry);
        contracts.activePool = new ActivePool{salt: SALT}(contracts.addressesRegistry);
        contracts.defaultPool = new DefaultPool{salt: SALT}(contracts.addressesRegistry);
        contracts.gasPool = new GasPool{salt: SALT}(contracts.addressesRegistry);
        contracts.collSurplusPool = new CollSurplusPool{salt: SALT}(contracts.addressesRegistry);
        contracts.sortedTroves = new SortedTroves{salt: SALT}(contracts.addressesRegistry);

        assert(address(contracts.borrowerOperations) == addresses.borrowerOperations);
        assert(address(contracts.troveManager) == addresses.troveManager);
        assert(address(contracts.troveNFT) == addresses.troveNFT);
        assert(address(contracts.stabilityPool) == addresses.stabilityPool);
        assert(address(contracts.activePool) == addresses.activePool);
        assert(address(contracts.defaultPool) == addresses.defaultPool);
        assert(address(contracts.gasPool) == addresses.gasPool);
        assert(address(contracts.collSurplusPool) == addresses.collSurplusPool);
        assert(address(contracts.sortedTroves) == addresses.sortedTroves);

        // setAddresses must run before these CREATE2 contracts exist because their
        // constructors read this registry. Replace every predicted branch-local
        // value with the deployed instance, then verify all 18 frozen fields and
        // their runtime code before continuing the deployment ceremony.
        addressVars.borrowerOperations = contracts.borrowerOperations;
        addressVars.troveManager = contracts.troveManager;
        addressVars.troveNFT = contracts.troveNFT;
        addressVars.metadataNFT = contracts.metadataNFT;
        addressVars.stabilityPool = contracts.stabilityPool;
        addressVars.activePool = contracts.activePool;
        addressVars.defaultPool = contracts.defaultPool;
        addressVars.gasPoolAddress = address(contracts.gasPool);
        addressVars.collSurplusPool = contracts.collSurplusPool;
        addressVars.sortedTroves = contracts.sortedTroves;
        _verifyAddressesRegistryWiring(contracts.addressesRegistry, addressVars);

        // Connect contracts
        _jpydfToken.setBranchAddresses(
            address(contracts.troveManager),
            address(contracts.stabilityPool),
            address(contracts.borrowerOperations),
            address(contracts.activePool)
        );

        // deploy zapper
        contracts.collateralYieldZapper =
            _deployZapper(contracts.addressesRegistry, _collateralVault, _underlyingToken, _branchIndex);
    }

    function _deployInterestRouter(IJpydfToken _jpydfToken)
        internal
        returns (IInterestRouter interestRouter, InterestRouterForwarder forwarder)
    {
        address recipient = vm.envAddress("DF_INTEREST_ROUTER_RECIPIENT");
        address owner = vm.envAddress("DF_INTEREST_ROUTER_OWNER");
        require(recipient != address(0), "DeployLiquity2: zero interest router recipient");
        require(owner != address(0), "DeployLiquity2: zero interest router owner");

        forwarder = new InterestRouterForwarder{salt: SALT}(IERC20(address(_jpydfToken)), recipient, owner);
        interestRouter = IInterestRouter(address(forwarder));
    }

    function _deployPriceFeed(address _collTokenAddress, address _borroweOperationsAddress)
        internal
        returns (IPriceFeed)
    {
        // DF Phase 4: front every branch's source with a PriceFeedProxy (12h-timelock
        // swappable source = ADR-005). Inert branches (no underlying) use a
        // PriceFeedPlaceholder source (ORCL-FR-008); active branches the PRODUCTION DF
        // feed (JPY composition + staleness failsafe + backingRatio multiplication read
        // from this branch's CollateralVault = ORCL-FR-014) over the configured
        // collateral/USD + JPY/USD aggregators. Local Production-Parity (§2-6): the feed
        // code path is production, while the external data source is settable.
        // The proxy constructor smoke-tests the source either way (SYS-RISK-006).
        DToken dTok = DToken(_collTokenAddress);
        address feedSource = address(dTok.underlying()) == address(0)
            ? address(new PriceFeedPlaceholder())
            : _deployDFFeedSource(dTok, _borroweOperationsAddress);
        return IPriceFeed(address(new PriceFeedProxy(feedSource, deployer, _borroweOperationsAddress)));
    }

    /// @dev Construct the PRODUCTION price feed for an active DF branch, wired to this
    ///      branch's collateral/USD aggregator, the shared JPY/USD leg and the branch
    ///      CollateralVault (backing input). The feed kind was registered when the dToken
    ///      collateral was created.
    function _deployDFFeedSource(DToken _dToken, address _borrowerOperationsAddress) internal returns (address) {
        uint8 kind = dfFeedKind[address(_dToken)];
        require(kind != 0, "DF: feed kind not registered");
        address collUsd = dfCollUsdOracle[address(_dToken)];
        address jpyUsdProvider = dfJpyUsdRateProvider;
        uint256 collUsdStaleness = dfCollUsdStaleness[address(_dToken)];
        address vault = _dToken.vault();
        require(collUsd != address(0), "DF: missing collateral/USD oracle");
        require(jpyUsdProvider != address(0), "DF: missing JPY/USD rate provider");
        require(collUsdStaleness != 0, "DF: zero collateral/USD staleness");

        if (kind == DF_FEED_WSTETH) {
            return _deployDFWstEthFeedSource(
                _dToken, collUsd, collUsdStaleness, jpyUsdProvider, vault, _borrowerOperationsAddress
            );
        }
        require(kind == DF_FEED_USDC, "DF: unknown feed kind");
        return
            address(new DFUSDCPriceFeed(collUsd, collUsdStaleness, jpyUsdProvider, vault, _borrowerOperationsAddress));
    }

    function _deployDFWstEthFeedSource(
        DToken _dToken,
        address _collUsd,
        uint256 _collUsdStaleness,
        address _jpyUsdProvider,
        address _vault,
        address _borrowerOperationsAddress
    ) private returns (address) {
        address redemptionEthUsd = dfRedemptionEthUsdOracle[address(_dToken)];
        uint256 redemptionEthUsdStaleness = dfRedemptionEthUsdStaleness[address(_dToken)];
        address redemptionStEthEth = dfRedemptionStEthEthOracle[address(_dToken)];
        uint256 redemptionStEthEthStaleness = dfRedemptionStEthEthStaleness[address(_dToken)];
        require(redemptionEthUsd != address(0), "DF: missing redemption ETH/USD oracle");
        require(redemptionEthUsdStaleness != 0, "DF: zero redemption ETH/USD staleness");
        require(redemptionStEthEth != address(0), "DF: missing redemption stETH/ETH oracle");
        require(redemptionStEthEthStaleness != 0, "DF: zero redemption stETH/ETH staleness");

        // Rate provider == the branch Underlying itself (wstETH), the mainnet shape:
        // the composite feed reads stEthPerToken() straight from the collateral token.
        return address(
            new DFWstETHPriceFeed(
                _collUsd,
                redemptionEthUsd,
                redemptionStEthEth,
                address(_dToken.underlying()),
                _collUsdStaleness,
                redemptionEthUsdStaleness,
                redemptionStEthEthStaleness,
                _jpyUsdProvider,
                _vault,
                _borrowerOperationsAddress
            )
        );
    }

    function _deployZapper(
        IAddressesRegistry _addressesRegistry,
        CollateralVault _collateralVault,
        IERC20 _underlyingToken,
        uint256 _branchIndex
    ) internal returns (CollateralYieldZapper collateralYieldZapper) {
        return _deployZapperWithReferralManagerCandidate(
            _addressesRegistry, _collateralVault, _underlyingToken, _branchIndex, address(0), false
        );
    }

    function _deployZapperWithReferralManagerCandidate(
        IAddressesRegistry _addressesRegistry,
        CollateralVault _collateralVault,
        IERC20 _underlyingToken,
        uint256 _branchIndex,
        address _referralManagerCandidate,
        bool _useCandidate
    ) internal returns (CollateralYieldZapper collateralYieldZapper) {
        bool hasYieldLayer = address(_underlyingToken) != address(0);
        if (hasYieldLayer) {
            // Native-ETH zap route: deliberately enabled per branch (mainnet branch 0 = Lido stETH);
            // unset/zero keeps the route disabled.
            address configuredStEth = vm.envOr(_dfEnvKey("DF_ZAPPER_EXPECTED_STETH", _branchIndex), address(0));
            address expectedStEth = _resolveZapperExpectedStEth(
                _underlyingToken, _branchIndex, configuredStEth, _envFlag("DF_ENABLE_LOCAL_NATIVE_ETH_ROUTE")
            );
            // Lido Rewards Share attribution address (deploy decision; zero disables attribution).
            address lidoReferral = vm.envOr(_dfEnvKey("DF_ZAPPER_LIDO_REFERRAL", _branchIndex), address(0));
            _validateProductionNativeEthRoute(_branchIndex, configuredStEth, lidoReferral);
            address lidoReferralManager = _useCandidate
                ? _resolveZapperLidoReferralManagerCandidate(_referralManagerCandidate)
                : _resolveZapperLidoReferralManager();
            collateralYieldZapper = new CollateralYieldZapper(
                _addressesRegistry, _collateralVault, _underlyingToken, expectedStEth, lidoReferral, lidoReferralManager
            );
        }
    }

    function _resolveZapperLidoReferralManager() internal returns (address manager) {
        manager = vm.envOr("DF_TIMELOCK", address(0));
        return _resolveZapperLidoReferralManagerCandidate(manager);
    }

    function _resolveZapperLidoReferralManagerCandidate(address manager) internal returns (address) {
        if (manager == address(0) && _isLocalDevChain()) {
            if (address(localZapperReferralTimelock) == address(0)) {
                address localAdmin = deployer == address(0) ? msg.sender : deployer;
                address[] memory proposers = new address[](1);
                proposers[0] = localAdmin;
                address[] memory executors = new address[](1);
                executors[0] = address(0);
                localZapperReferralTimelock = new TimelockController(0, proposers, executors, address(0));
            }
            return address(localZapperReferralTimelock);
        }
        require(manager != address(0), "DeployLiquity2: missing DF_TIMELOCK for Lido referral manager");
        _requireContract(manager, "DF_TIMELOCK");
        if (block.chainid == 1) {
            _validateMainnetZapperLidoReferralManager(manager, _isMainnetCanaryBuild());
        } else {
            TimelockController(payable(manager)).getMinDelay();
        }
        return manager;
    }

    function _validateMainnetZapperLidoReferralManager(address manager, bool isCanary) internal view {
        TimelockController timelock = TimelockController(payable(manager));
        if (isCanary) {
            require(manager == MAINNET_CANARY_TIMELOCK, "DeployLiquity2: canary requires pilot Timelock");
            require(manager.codehash == MAINNET_CANARY_TIMELOCK_RUNTIME_CODEHASH, "DeployLiquity2: Timelock codehash");
            require(
                timelock.getMinDelay() == MAINNET_CANARY_TIMELOCK_MIN_DELAY, "DeployLiquity2: canary Timelock delay"
            );
            return;
        }

        MainnetProductionTimelockPolicy.requireValid(manager);
    }

    function _resolveZapperExpectedStEth(
        IERC20 _underlyingToken,
        uint256 _branchIndex,
        address _configuredStEth,
        bool _enableLocalNativeEthRoute
    ) internal view returns (address) {
        if (_configuredStEth != address(0) || !_enableLocalNativeEthRoute || !_isLocalDevChain() || _branchIndex != 0) {
            return _configuredStEth;
        }

        return LocalWstETH(address(_underlyingToken)).stETH();
    }

    function _validateProductionNativeEthRoute(uint256 _branchIndex, address _configuredStEth, address _lidoReferral)
        internal
        view
    {
        _validateProductionNativeEthRouteForProfile(
            _branchIndex, _configuredStEth, _lidoReferral, _isMainnetCanaryBuild()
        );
    }

    function _validateProductionNativeEthRouteForProfile(
        uint256 _branchIndex,
        address _configuredStEth,
        address _lidoReferral,
        bool _mainnetTestBuild
    ) internal view {
        if (block.chainid != 1 || _mainnetTestBuild) return;
        if (_branchIndex != 0) {
            require(_configuredStEth == address(0), "DF: unexpected mainnet branch stETH route");
            require(_lidoReferral == address(0), "DF: unexpected mainnet branch Lido referral");
            return;
        }

        string memory ownerManifest = vm.readFile("../config/day1-branch-manifest.json");
        address expectedStEth = vm.parseJsonAddress(ownerManifest, ".branches[0].nativeEthRoute.expectedStEth");
        address expectedLidoReferral = vm.parseJsonAddress(ownerManifest, ".branches[0].nativeEthRoute.lidoReferral");
        require(_configuredStEth == expectedStEth, "DF: mainnet stETH differs from Day-1 owner manifest");
        require(_lidoReferral == expectedLidoReferral, "DF: mainnet Lido referral differs from Day-1 owner manifest");
    }

    function _getBranchContractsJson(LiquityContracts memory c, string memory slot)
        internal
        view
        returns (string memory)
    {
        return string.concat(
            "{",
            string.concat(
                // Avoid stack too deep by chunking concats
                string.concat(
                    // This is the Owner-approved slot identity, not necessarily the
                    // current ERC-20 symbol. Inert dTokens deliberately retain their
                    // on-chain `dTOKEN` fallback until an Underlying is approved.
                    string.concat('"collSymbol":"', slot, '",'),
                    string.concat('"collToken":"', address(c.collToken).toHexString(), '",'),
                    string.concat('"addressesRegistry":"', address(c.addressesRegistry).toHexString(), '",'),
                    _getBranchRiskParamsJson(c.addressesRegistry),
                    string.concat('"activePool":"', address(c.activePool).toHexString(), '",'),
                    string.concat('"borrowerOperations":"', address(c.borrowerOperations).toHexString(), '",'),
                    string.concat('"collSurplusPool":"', address(c.collSurplusPool).toHexString(), '",'),
                    string.concat('"defaultPool":"', address(c.defaultPool).toHexString(), '",'),
                    string.concat('"sortedTroves":"', address(c.sortedTroves).toHexString(), '",')
                ),
                string.concat(
                    string.concat('"stabilityPool":"', address(c.stabilityPool).toHexString(), '",'),
                    string.concat('"troveManager":"', address(c.troveManager).toHexString(), '",'),
                    string.concat('"troveNFT":"', address(c.troveNFT).toHexString(), '",'),
                    string.concat('"metadataNFT":"', address(c.metadataNFT).toHexString(), '",'),
                    string.concat('"priceFeed":"', address(c.priceFeed).toHexString(), '",'),
                    string.concat('"gasPool":"', address(c.gasPool).toHexString(), '",'),
                    string.concat('"interestRouter":"', address(c.interestRouter).toHexString(), '"') // no comma
                )
            ),
            "}"
        );
    }

    function _getBranchRiskParamsJson(IAddressesRegistry registry) internal view returns (string memory) {
        return string.concat(
            '"riskParamsFinalizer":"',
            registry.riskParamsFinalizer().toHexString(),
            '","riskParamsFinalized":',
            registry.riskParamsFinalized() ? "true," : "false,"
        );
    }

    function _getDeploymentConstants() internal pure returns (string memory) {
        return string.concat(
            "{",
            string.concat(
                string.concat('"ETH_GAS_COMPENSATION":"', ETH_GAS_COMPENSATION.toString(), '",'),
                string.concat('"INTEREST_RATE_ADJ_COOLDOWN":"', INTEREST_RATE_ADJ_COOLDOWN.toString(), '",'),
                string.concat('"MAX_ANNUAL_INTEREST_RATE":"', MAX_ANNUAL_INTEREST_RATE.toString(), '",'),
                string.concat('"MIN_ANNUAL_INTEREST_RATE":"', MIN_ANNUAL_INTEREST_RATE.toString(), '",'),
                string.concat('"MIN_DEBT":"', MIN_DEBT.toString(), '",'),
                string.concat('"SP_YIELD_SPLIT":"', SP_YIELD_SPLIT.toString(), '",'),
                string.concat('"UPFRONT_INTEREST_PERIOD":"', UPFRONT_INTEREST_PERIOD.toString(), '"') // no comma
            ),
            "}"
        );
    }

    function _getDeploymentClassification() internal view returns (string memory) {
        return !_isMainnetStaging() && block.chainid == 1 && MIN_DEBT == PRODUCTION_MIN_DEBT
            ? DEPLOYMENT_CLASSIFICATION_PRODUCTION
            : DEPLOYMENT_CLASSIFICATION_TEST_ONLY;
    }

    function _getDeploymentProfile() internal view returns (string memory) {
        if (_isMainnetStaging()) return "mainnet-staging";
        if (block.chainid == 1 && MIN_DEBT == PRODUCTION_MIN_DEBT) return "production-candidate";
        if (_isMainnetCanaryBuild()) return "mainnet-persistent-canary-v2-min-debt-1000";
        return "non-mainnet-test-only";
    }

    function _getDeploymentId() internal view returns (string memory) {
        if (_isMainnetStaging()) return "jpydf-mainnet-staging-20260924-01";
        if (_isMainnetCanaryBuild()) return MAINNET_CANARY_ID;
        if (block.chainid == 1 && MIN_DEBT == PRODUCTION_MIN_DEBT) return "jpydf-production-candidate";
        return "jpydf-non-mainnet-test-only";
    }

    // =============================================================
    //              DF Phase 4 — dToken deploy wiring (opt-in)
    // =============================================================

    function _dfBranchParams()
        internal
        pure
        returns (TroveManagerParams[] memory params, string[] memory names, string[] memory symbols)
    {
        params = new TroveManagerParams[](NUM_DF_BRANCHES);
        params[0] = TroveManagerParams(
            CCR_DWSTETH,
            MCR_DWSTETH,
            SCR_DWSTETH,
            BCR_DWSTETH,
            LIQUIDATION_PENALTY_SP_DWSTETH,
            LIQUIDATION_PENALTY_REDISTRIBUTION_DWSTETH
        );
        params[1] = TroveManagerParams(
            CCR_DUSDC,
            MCR_DUSDC,
            SCR_DUSDC,
            BCR_DUSDC,
            LIQUIDATION_PENALTY_SP_DUSDC,
            LIQUIDATION_PENALTY_REDISTRIBUTION_DUSDC
        );
        params[2] = TroveManagerParams(
            CCR_DETH, MCR_DETH, SCR_DETH, BCR_DETH, LIQUIDATION_PENALTY_SP_DETH, LIQUIDATION_PENALTY_REDISTRIBUTION_DETH
        );
        params[3] = TroveManagerParams(
            CCR_DUSD_A,
            MCR_DUSD_A,
            SCR_DUSD_A,
            BCR_DUSD_A,
            LIQUIDATION_PENALTY_SP_DUSD_A,
            LIQUIDATION_PENALTY_REDISTRIBUTION_DUSD_A
        );
        params[4] = TroveManagerParams(
            CCR_DBTC, MCR_DBTC, SCR_DBTC, BCR_DBTC, LIQUIDATION_PENALTY_SP_DBTC, LIQUIDATION_PENALTY_REDISTRIBUTION_DBTC
        );
        params[5] = TroveManagerParams(
            CCR_DUSD_B,
            MCR_DUSD_B,
            SCR_DUSD_B,
            BCR_DUSD_B,
            LIQUIDATION_PENALTY_SP_DUSD_B,
            LIQUIDATION_PENALTY_REDISTRIBUTION_DUSD_B
        );
        params[6] = TroveManagerParams(
            CCR_DJPY, MCR_DJPY, SCR_DJPY, BCR_DJPY, LIQUIDATION_PENALTY_SP_DJPY, LIQUIDATION_PENALTY_REDISTRIBUTION_DJPY
        );
        params[7] = TroveManagerParams(
            CCR_DJGB, MCR_DJGB, SCR_DJGB, BCR_DJGB, LIQUIDATION_PENALTY_SP_DJGB, LIQUIDATION_PENALTY_REDISTRIBUTION_DJGB
        );

        // One entry per branch except branch 0 (develop guard: names.length + 1 == params.length).
        // Branch 1 is active; branches 2-7 are named reservation slots with no Underlying binding.
        names = new string[](NUM_DF_BRANCHES - 1);
        symbols = new string[](NUM_DF_BRANCHES - 1);
        names[0] = "USD Coin";
        symbols[0] = "USDC";
        names[1] = "Ether (inert)";
        symbols[1] = "ETH";
        names[2] = "USD-A (inert)";
        symbols[2] = "USD-A";
        names[3] = "Bitcoin (inert)";
        symbols[3] = "BTC";
        names[4] = "USD-B (inert)";
        symbols[4] = "USD-B";
        names[5] = "Japanese Yen (inert)";
        symbols[5] = "JPY";
        names[6] = "Japanese Government Bond (inert)";
        symbols[6] = "JGB";

        _requireBranchRiskInvariants(params);
    }

    function _dfDTokenSlot(uint256 branchIndex) internal pure returns (string memory) {
        string[8] memory slots = ["dwstETH", "dUSDC", "dETH", "dUSD-A", "dBTC", "dUSD-B", "dJPY", "dJGB"];
        require(branchIndex < slots.length, "DF: branch slot");
        return slots[branchIndex];
    }

    /// @dev PRM-INV machine checks (SYS-RISK-005): verify every deploy input, including reserved
    ///      branch bootstrap values. Reserved branches repeat these checks on their final values
    ///      during one-shot finalization; active branches are fixed at deployment.
    ///      PRM-INV-005 (penalty bounds) is enforced by the AddressesRegistry constructor.
    function _requireBranchRiskInvariants(TroveManagerParams[] memory _params) internal pure {
        for (uint256 i = 0; i < _params.length; i++) {
            TroveManagerParams memory p = _params[i];
            // PRM-INV-001
            require(p.SCR < p.MCR && p.MCR < p.CCR, "DF: PRM-INV CR ordering");
            // PRM-INV-004
            require(
                p.MCR * (COLL_GAS_COMPENSATION_DIVISOR - 1)
                    >= (_100pct + p.LIQUIDATION_PENALTY_SP) * COLL_GAS_COMPENSATION_DIVISOR,
                "DF: PRM-INV SP coverage after gas compensation"
            );
            require(
                _100pct + p.LIQUIDATION_PENALTY_REDISTRIBUTION <= p.MCR,
                "DF: PRM-INV 1+penaltyRedistribution <= MCR"
            );
            // PRM-INV-003
            require(p.LIQUIDATION_PENALTY_SP <= p.LIQUIDATION_PENALTY_REDISTRIBUTION, "DF: PRM-INV penalty ordering");
            // PRM-INV-006. The bound is on SCR, the shutdown floor that urgent redemption pays its
            // bonus against. Checking MCR instead is strictly weaker, because PRM-INV-001 already
            // forces SCR < MCR, so an SCR under the bound would pass unnoticed.
            require(_100pct + URGENT_REDEMPTION_BONUS <= p.SCR, "DF: PRM-INV 1+urgentBonus <= SCR");
        }
    }

    /// @dev Deploy DToken + CollateralVault (UUPS proxies) for one branch, wired in the
    ///      contract-enforced order. Every branch is frozen at cap 0 until governance
    ///      handover; inert branches (underlying == 0) also skip setTokenInfo.
    function _deployYieldLayer(IERC20Metadata _underlying, string memory _dTokenName, string memory _dTokenSymbol)
        internal
        returns (DToken dToken, CollateralVault vault)
    {
        if (address(yieldLayerProxyDeployer) == address(0)) {
            yieldLayerProxyDeployer = new YieldLayerProxyDeployer(address(new DToken()), address(new CollateralVault()));
        }

        // DToken and Vault have a circular initialization dependency. Deploy both
        // proxies and initialize them inside one helper transaction so no
        // externally observable uninitialized proxy window exists on mainnet.
        (dToken, vault) = yieldLayerProxyDeployer.deployYieldLayer(
            IERC20MetadataUpgradeable(address(_underlying)), _dTokenName, _dTokenSymbol, _dfVaultTreasury(), deployer
        );
        dToken.acceptOwnership();
    }

    function _deployAndRegisterStrategies(uint256 _branchIndex, CollateralVault _vault, IERC20Metadata _underlying)
        internal
        returns (IStrategy)
    {
        uint256 strategyCount = _dfStrategyCount(_branchIndex);
        if (strategyCount == 1) return _deployAndRegisterStrategy(_branchIndex, 0, _vault, _underlying);

        IStrategy primaryStrategy;
        for (uint256 strategyIndex; strategyIndex < strategyCount; strategyIndex++) {
            string memory kind = _dfStrategyKind(_branchIndex, strategyIndex);
            require(!kind.eq("none"), "DF: array strategy none");
            IStrategy strategy = _deployAndRegisterStrategy(_branchIndex, strategyIndex, _vault, _underlying);
            if (strategyIndex == 0) primaryStrategy = strategy;
        }
        require(_vault.totalWeightBps() != 0, "DF: zero total strategy weight");
        return primaryStrategy;
    }

    function _deployAndRegisterStrategy(uint256 _branchIndex, CollateralVault _vault, IERC20Metadata _underlying)
        internal
        returns (IStrategy)
    {
        return _deployAndRegisterStrategy(_branchIndex, 0, _vault, _underlying);
    }

    function _deployAndRegisterStrategy(
        uint256 _branchIndex,
        uint256 _strategyIndex,
        CollateralVault _vault,
        IERC20Metadata _underlying
    ) internal returns (IStrategy) {
        string memory kind = _dfStrategyKind(_branchIndex, _strategyIndex);
        if (kind.eq("none")) return _validateNoStrategy(_branchIndex, _vault);
        if (kind.eq("aave")) return _deployAndRegisterAaveStrategy(_branchIndex, _strategyIndex, _vault, _underlying);
        if (kind.eq("erc4626")) {
            return _deployAndRegisterERC4626Strategy(_branchIndex, _strategyIndex, _vault, _underlying);
        }
        if (kind.eq("morpho-v2")) {
            return _deployAndRegisterMorphoV2Strategy(_branchIndex, _strategyIndex, _vault, _underlying);
        }
        if (kind.eq("sky-susds")) {
            return _deployAndRegisterSkyUsdcSUsdsStrategy(_branchIndex, _strategyIndex, _vault, _underlying);
        }
        revert(string.concat("DF: unknown strategy kind ", kind));
    }

    function _validateNoStrategy(uint256 _branchIndex, CollateralVault _vault) internal view returns (IStrategy) {
        require(_dfStrategyWeightBps(_branchIndex) == 0, "DF: none strategy weight");
        require(_dfStrategyCap(_branchIndex) == 0, "DF: none strategy cap");
        require(_vault.getStrategiesCount() == 0, "DF: none strategy registered");
        return IStrategy(address(0));
    }

    /// @dev Deploy and register the production AaveV3Strategy (UUPS proxy). Mainnet
    ///      consumes explicit frozen env addresses, Sepolia consumes the exact Aave V3
    ///      Sepolia USDC venue, and local chains deploy a self-contained parity venue.
    function _deployAndRegisterAaveStrategy(
        uint256 _branchIndex,
        uint256 _strategyIndex,
        CollateralVault _vault,
        IERC20Metadata _underlying
    ) internal returns (IStrategy) {
        IAaveV3Pool pool;
        IAToken aToken;
        if (block.chainid == 1) {
            address poolAddress = _dfRequiredStrategyAddress("DF_STRATEGY_AAVE_POOL", _branchIndex, _strategyIndex);
            _requireContract(poolAddress, _dfStrategyEnvKey("DF_STRATEGY_AAVE_POOL", _branchIndex, _strategyIndex));
            address aTokenAddress = _dfRequiredStrategyAddress("DF_STRATEGY_AAVE_ATOKEN", _branchIndex, _strategyIndex);
            _requireContract(aTokenAddress, _dfStrategyEnvKey("DF_STRATEGY_AAVE_ATOKEN", _branchIndex, _strategyIndex));
            pool = IAaveV3Pool(poolAddress);
            aToken = IAToken(aTokenAddress);
        } else if (block.chainid == 11155111) {
            require(
                address(_underlying) == SepoliaExternalAddresses.AAVE_USDC, "DF: unsupported Sepolia Aave underlying"
            );
            _requireContract(SepoliaExternalAddresses.AAVE_V3_POOL, "SEPOLIA_AAVE_V3_POOL");
            _requireContract(SepoliaExternalAddresses.AAVE_USDC_ATOKEN, "SEPOLIA_AAVE_USDC_ATOKEN");
            pool = IAaveV3Pool(SepoliaExternalAddresses.AAVE_V3_POOL);
            aToken = IAToken(SepoliaExternalAddresses.AAVE_USDC_ATOKEN);
        } else {
            LocalAavePool localPool = new LocalAavePool();
            LocalAToken localAToken = new LocalAToken(address(localPool), address(_underlying));
            localPool.setAsset(IERC20(address(_underlying)));
            localPool.setAToken(localAToken);
            pool = IAaveV3Pool(address(localPool));
            aToken = IAToken(address(localAToken));
        }

        AaveV3Strategy strategy = AaveV3Strategy(
            address(
                new ERC1967Proxy(
                    address(new AaveV3Strategy()),
                    abi.encodeCall(
                        AaveV3Strategy.initialize,
                        (
                            address(_vault),
                            IERC20(address(_underlying)),
                            deployer,
                            deployer,
                            IAaveV3Pool(address(pool)),
                            aToken
                        )
                    )
                )
            )
        );

        return _registerStrategy(_branchIndex, _strategyIndex, _vault, IStrategy(address(strategy)));
    }

    function _deployAndRegisterERC4626Strategy(
        uint256 _branchIndex,
        uint256 _strategyIndex,
        CollateralVault _vault,
        IERC20Metadata _underlying
    ) internal returns (IStrategy) {
        address erc4626VaultAddress = _dfRequiredStrategyAddress(
            "DF_STRATEGY_ERC4626_VAULT", _branchIndex, _strategyIndex
        );
        _requireContract(
            erc4626VaultAddress, _dfStrategyEnvKey("DF_STRATEGY_ERC4626_VAULT", _branchIndex, _strategyIndex)
        );
        IERC4626 erc4626Vault = IERC4626(erc4626VaultAddress);

        ERC4626Strategy strategy = ERC4626Strategy(
            address(
                new ERC1967Proxy(
                    address(new ERC4626Strategy()),
                    abi.encodeCall(
                        ERC4626Strategy.initialize,
                        (
                            address(_vault),
                            IERC20(address(_underlying)),
                            deployer,
                            deployer,
                            IERC4626(address(erc4626Vault))
                        )
                    )
                )
            )
        );

        return _registerStrategy(_branchIndex, _strategyIndex, _vault, IStrategy(address(strategy)));
    }

    function _deployAndRegisterMorphoV2Strategy(
        uint256 _branchIndex,
        uint256 _strategyIndex,
        CollateralVault _vault,
        IERC20Metadata _underlying
    ) internal returns (IStrategy) {
        address morphoVaultAddress = _dfRequiredStrategyAddress(
            "DF_STRATEGY_MORPHOV2_VAULT", _branchIndex, _strategyIndex
        );
        if (_isSepolia()) {
            require(
                morphoVaultAddress == SepoliaExternalAddresses.MORPHO_V2_USDC_VAULT,
                "DF: unsupported Sepolia Morpho V2 vault"
            );
        }
        _requireContract(
            morphoVaultAddress, _dfStrategyEnvKey("DF_STRATEGY_MORPHOV2_VAULT", _branchIndex, _strategyIndex)
        );

        uint256 maxPenaltyBps = vm.envOr(
            _dfStrategyEnvKey("DF_STRATEGY_MORPHOV2_MAX_PENALTY_BPS", _branchIndex, _strategyIndex), uint256(200)
        );
        require(maxPenaltyBps <= 200, "DF: morpho-v2 penalty > 200 bps");

        MorphoV2Strategy strategy = MorphoV2Strategy(
            address(
                new ERC1967Proxy(
                    address(new MorphoV2Strategy()),
                    abi.encodeCall(
                        MorphoV2Strategy.initialize,
                        (
                            address(_vault),
                            IERC20(address(_underlying)),
                            deployer,
                            deployer,
                            IMorphoVaultV2(morphoVaultAddress),
                            maxPenaltyBps
                        )
                    )
                )
            )
        );

        return _registerStrategy(_branchIndex, _strategyIndex, _vault, IStrategy(address(strategy)));
    }

    function _deployAndRegisterSkyUsdcSUsdsStrategy(
        uint256 _branchIndex,
        uint256 _strategyIndex,
        CollateralVault _vault,
        IERC20Metadata _underlying
    ) internal returns (IStrategy) {
        require(_branchIndex == 1, "DF: Sky strategy requires dUSDC branch");
        require(address(_underlying) == address(USDC), "DF: Sky strategy requires USDC");
        require(_underlying.decimals() == 6, "DF: Sky strategy requires 6-decimal USDC");

        SkyStrategyVenue memory venue = _dfSkyStrategyVenue(_branchIndex, _strategyIndex);
        uint256 maxConversionLossBps =
            vm.envUint(_dfStrategyEnvKey("DF_STRATEGY_SKY_MAX_CONVERSION_LOSS_BPS", _branchIndex, _strategyIndex));

        SkyUsdcSUsdsStrategy strategy = SkyUsdcSUsdsStrategy(
            address(
                new ERC1967Proxy(
                    address(new SkyUsdcSUsdsStrategy()),
                    abi.encodeCall(
                        SkyUsdcSUsdsStrategy.initialize,
                        (
                            address(_vault),
                            IERC20(address(_underlying)),
                            deployer,
                            deployer,
                            IERC20(address(venue.usds)),
                            venue.susdsVault,
                            venue.converter,
                            maxConversionLossBps
                        )
                    )
                )
            )
        );

        return _registerStrategy(_branchIndex, _strategyIndex, _vault, IStrategy(address(strategy)));
    }

    function _dfSkyStrategyVenue(uint256 _branchIndex, uint256 _strategyIndex)
        internal
        returns (SkyStrategyVenue memory venue)
    {
        address usdsAddress = _dfRequiredStrategyAddress("DF_STRATEGY_SKY_USDS", _branchIndex, _strategyIndex);
        _requireContract(usdsAddress, _dfStrategyEnvKey("DF_STRATEGY_SKY_USDS", _branchIndex, _strategyIndex));
        address susdsVaultAddress =
            _dfRequiredStrategyAddress("DF_STRATEGY_SKY_SUSDS_VAULT", _branchIndex, _strategyIndex);
        _requireContract(
            susdsVaultAddress, _dfStrategyEnvKey("DF_STRATEGY_SKY_SUSDS_VAULT", _branchIndex, _strategyIndex)
        );
        address psmWrapperAddress =
            _dfRequiredStrategyAddress("DF_STRATEGY_SKY_USDC_USDS_PSM_WRAPPER", _branchIndex, _strategyIndex);
        _requireContract(
            psmWrapperAddress, _dfStrategyEnvKey("DF_STRATEGY_SKY_USDC_USDS_PSM_WRAPPER", _branchIndex, _strategyIndex)
        );

        venue.usds = IERC20Metadata(usdsAddress);
        venue.susdsVault = IERC4626(susdsVaultAddress);
        venue.converter = new SkyUsdcSUsdsConverter(ISkyLitePsmWrapper(psmWrapperAddress));
    }

    function _registerStrategy(
        uint256 _branchIndex,
        uint256 _strategyIndex,
        CollateralVault _vault,
        IStrategy _strategy
    ) internal returns (IStrategy) {
        _vault.addToWhitelist(address(_strategy));
        // Forge estimates consumed gas, but valuation probes require their full stipend
        // to be available even when an empty strategy consumes very little of it.
        // Fund both estimate and principal probes, plus registration/proxy overhead.
        uint256 registrationGas = 2 * _vault.strategyValuationGasBudget() * 64 / 63 + 500_000;
        _vault.addStrategy{gas: registrationGas}(
            _strategy, _dfStrategyWeightBps(_branchIndex, _strategyIndex), _dfStrategyCap(_branchIndex, _strategyIndex)
        );
        return _strategy;
    }

    function _dfStrategyKind(uint256 _branchIndex) internal view returns (string memory) {
        return _dfStrategyKind(_branchIndex, 0);
    }

    function _dfStrategyKind(uint256 _branchIndex, uint256 _strategyIndex) internal view returns (string memory) {
        return _dfStrategyString("DF_STRATEGY_KIND", _branchIndex, _strategyIndex);
    }

    function _dfVaultTreasury() internal view returns (address) {
        return vm.envAddress("DF_TREASURY");
    }

    function _resolveBridgeAdmin() internal returns (address admin) {
        if (_isMainnetCanaryBuild()) {
            require(vm.envOr("DF_BRIDGE_ADMIN", string("")).eq(""), "DeployLiquity2: canary bridge admin must be inert");
            return _resolveMainnetCanaryBridgeAdmin();
        }

        bool configured;
        string memory configuredAdmin = vm.envOr("DF_BRIDGE_ADMIN", string(""));
        if (!configuredAdmin.eq("")) {
            configured = true;
            admin = vm.parseAddress(configuredAdmin);
        } else {
            require(_isLocalDevChain(), "DeployLiquity2: missing DF_BRIDGE_ADMIN");
            admin = _resolveLocalBridgeAdmin();
        }

        _validateBridgeAdminCandidate(admin, configured);
    }

    function _validateBridgeAdminCandidate(address admin, bool configured) internal view {
        require(admin != address(0), "DeployLiquity2: zero bridge admin");
        require(admin != deployer, "DeployLiquity2: bridge admin is deployer");
        _requireContract(admin, "DF_BRIDGE_ADMIN");
        if (block.chainid == 1) require(configured, "DeployLiquity2: missing DF_BRIDGE_ADMIN");
    }

    function _resolveLocalBridgeAdmin() internal returns (address admin) {
        bytes memory bytecode = type(LocalBridgeAdmin).creationCode;
        admin = vm.computeCreate2Address(SALT, keccak256(bytecode));
        if (admin.code.length == 0) {
            LocalBridgeAdmin deployed = new LocalBridgeAdmin{salt: SALT}();
            assert(address(deployed) == admin);
        }
    }

    function _resolveMainnetCanaryBridgeAdmin() internal returns (address admin) {
        bytes memory bytecode = type(MainnetCanaryBridgeAdmin).creationCode;
        admin = vm.computeCreate2Address(SALT, keccak256(bytecode));
        if (admin.code.length == 0) {
            MainnetCanaryBridgeAdmin deployed = new MainnetCanaryBridgeAdmin{salt: SALT}();
            assert(address(deployed) == admin);
        }
    }

    function _dfStrategyWeightBps(uint256 _branchIndex) internal view returns (uint256) {
        return _dfStrategyWeightBps(_branchIndex, 0);
    }

    function _dfStrategyCap(uint256 _branchIndex) internal view returns (uint256) {
        return _dfStrategyCap(_branchIndex, 0);
    }

    function _dfStrategyWeightBps(uint256 _branchIndex, uint256 _strategyIndex) internal view returns (uint256) {
        return _dfStrategyUint("DF_STRATEGY_WEIGHT_BPS", _branchIndex, _strategyIndex);
    }

    function _dfStrategyCap(uint256 _branchIndex, uint256 _strategyIndex) internal view returns (uint256) {
        return _dfStrategyUint("DF_STRATEGY_CAP", _branchIndex, _strategyIndex);
    }

    function _dfStrategyCount(uint256 _branchIndex) internal view returns (uint256) {
        string memory branchKey = _dfEnvKey("DF_STRATEGY_COUNT", _branchIndex);
        if (!vm.envExists(branchKey)) return 1;

        uint256 strategyCount = vm.envUint(branchKey);
        require(strategyCount != 0, "DF: zero strategy count");
        require(strategyCount <= 32, "DF: too many strategies");
        return strategyCount;
    }

    function _dfExpectedStrategyCount(uint256 _branchIndex) internal view returns (uint256) {
        uint256 strategyCount = _dfStrategyCount(_branchIndex);
        if (strategyCount == 1 && _dfStrategyKind(_branchIndex, 0).eq("none")) return 0;
        return strategyCount;
    }

    function _requireMainnetDay1StrategyPolicy(uint256 _branchIndex) internal view {
        if (_branchIndex == 1) {
            if (_isMainnetCanaryBuild()) {
                _requireMainnetCanaryStableStrategySet(_branchIndex);
                return;
            }
            // dUSDC: the production Day-1 set is exactly {aave, morpho-v2}.
            _requireMainnetDay1StableStrategySet(_branchIndex);
            if (_isMainnetStaging()) {
                for (uint256 i; i < _dfExpectedStrategyCount(_branchIndex); i++) {
                    require(_dfStrategyCap(_branchIndex, i) <= 1e6, "DF: staging strategy cap exceeds 1 USDC");
                }
            }
            return;
        }

        // dwstETH (branch 0) has no external Strategy on Day 1. Branches 2-7
        // are inert and use the same empty Strategy-set invariant.
        require(_dfExpectedStrategyCount(_branchIndex) == 0, "DF: Day-1 branch strategies disabled");
    }

    function _requireSepoliaDay1StrategyPolicy() internal view {
        if (!_isSepolia()) return;
        for (uint256 branchIndex = 0; branchIndex < NUM_DF_ACTIVE_BRANCHES; branchIndex++) {
            _requireMainnetDay1StrategyPolicy(branchIndex);
        }

        uint256 strategyCount = _dfExpectedStrategyCount(1);
        require(strategyCount == 2, "DF: Sepolia requires exactly two strategies");
        uint256[2] memory weights;
        uint256[2] memory caps;
        for (uint256 strategyIndex; strategyIndex < strategyCount; strategyIndex++) {
            weights[strategyIndex] = _dfStrategyWeightBps(1, strategyIndex);
            caps[strategyIndex] = _dfStrategyCap(1, strategyIndex);
        }
        _requireSepoliaStrategyAllocationPolicy(weights, caps);
    }

    function _requireSepoliaStrategyAllocationPolicy(uint256[2] memory _weights, uint256[2] memory _caps)
        internal
        pure
    {
        for (uint256 strategyIndex; strategyIndex < 2; strategyIndex++) {
            require(_weights[strategyIndex] == 5_000, "DF: Sepolia strategy weight must be 5000");
            require(_caps[strategyIndex] != 0, "DF: Sepolia strategy cap must be positive");
        }
        require(_caps[0] == _caps[1], "DF: Sepolia strategy caps must be symmetric");
    }

    function _requireMainnetCanaryStableStrategySet(uint256 _branchIndex) internal view {
        uint256 strategyCount = _dfExpectedStrategyCount(_branchIndex);
        require(strategyCount == 2, "DF: canary requires exactly two initial strategies");

        bool seenAave;
        bool seenGauntlet;
        uint256 totalWeightBps;
        for (uint256 strategyIndex; strategyIndex < strategyCount; strategyIndex++) {
            string memory kind = _dfStrategyKind(_branchIndex, strategyIndex);
            if (kind.eq("aave")) {
                require(!seenAave, "DF: duplicate canary strategy");
                seenAave = true;
            } else if (kind.eq("erc4626")) {
                require(!seenGauntlet, "DF: duplicate canary strategy");
                seenGauntlet = true;
                require(
                    _dfRequiredStrategyAddress("DF_STRATEGY_ERC4626_VAULT", _branchIndex, strategyIndex)
                        == MAINNET_CANARY_GAUNTLET_USDC_PRIME,
                    "DF: canary requires Gauntlet USDC Prime"
                );
            } else {
                revert(string.concat("DF: strategy outside canary initial scope ", kind));
            }

            require(
                _dfStrategyCap(_branchIndex, strategyIndex) <= MAINNET_CANARY_MAX_STRATEGY_CAP,
                "DF: canary strategy cap exceeds 100 USDC"
            );
            totalWeightBps += _dfStrategyWeightBps(_branchIndex, strategyIndex);
        }

        require(seenAave, "DF: canary missing aave strategy");
        require(seenGauntlet, "DF: canary missing Gauntlet strategy");
        require(totalWeightBps <= 10_000, "DF: canary strategy weight > 10000");
    }

    function _requireMainnetDay1StableStrategySet(uint256 _branchIndex) internal view {
        uint256 strategyCount = _dfExpectedStrategyCount(_branchIndex);
        require(strategyCount != 0, "DF: Day-1 strategy set missing");

        bool seenAave;
        bool seenMorphoV2;
        uint256 totalWeightBps;

        for (uint256 strategyIndex; strategyIndex < strategyCount; strategyIndex++) {
            string memory kind = _dfStrategyKind(_branchIndex, strategyIndex);
            if (kind.eq("aave")) {
                require(!seenAave, "DF: duplicate Day-1 strategy");
                seenAave = true;
            } else if (kind.eq("morpho-v2")) {
                require(!seenMorphoV2, "DF: duplicate Day-1 strategy");
                seenMorphoV2 = true;
                if (block.chainid == 1) {
                    require(
                        _dfRequiredStrategyAddress("DF_STRATEGY_MORPHOV2_VAULT", _branchIndex, strategyIndex)
                            == MAINNET_DAY1_GAUNTLET_USDC_PRIME_V2,
                        "DF: Day-1 requires Gauntlet USDC Prime V2"
                    );
                }
            } else {
                revert(string.concat("DF: strategy outside Day-1 scope ", kind));
            }

            totalWeightBps += _dfStrategyWeightBps(_branchIndex, strategyIndex);
        }

        require(seenAave, "DF: Day-1 missing aave strategy");
        require(seenMorphoV2, "DF: Day-1 missing morpho-v2 strategy");
        require(totalWeightBps <= 10_000, "DF: Day-1 strategy weight > 10000");
    }

    function _dfStrategyString(string memory _prefix, uint256 _branchIndex) internal view returns (string memory) {
        return _dfStrategyString(_prefix, _branchIndex, 0);
    }

    function _dfStrategyString(string memory _prefix, uint256 _branchIndex, uint256 _strategyIndex)
        internal
        view
        returns (string memory)
    {
        if (_dfStrategyArrayEnabled(_branchIndex)) {
            string memory strategyKey = _dfStrategyEnvKey(_prefix, _branchIndex, _strategyIndex);
            string memory value = vm.envString(strategyKey);
            require(bytes(value).length != 0, string.concat("DF: empty ", strategyKey));
            return value;
        }

        string memory branchKey = _dfEnvKey(_prefix, _branchIndex);
        try vm.envString(branchKey) returns (string memory branchValue) {
            require(bytes(branchValue).length != 0, string.concat("DF: empty ", branchKey));
            return branchValue;
        } catch {}

        try vm.envString(_prefix) returns (string memory sharedValue) {
            require(bytes(sharedValue).length != 0, string.concat("DF: empty ", _prefix));
            return sharedValue;
        } catch {}

        revert(string.concat("DF: missing ", branchKey));
    }

    function _dfStrategyUint(string memory _prefix, uint256 _branchIndex) internal view returns (uint256) {
        return _dfStrategyUint(_prefix, _branchIndex, 0);
    }

    function _dfStrategyUint(string memory _prefix, uint256 _branchIndex, uint256 _strategyIndex)
        internal
        view
        returns (uint256)
    {
        if (_dfStrategyArrayEnabled(_branchIndex)) {
            return vm.envUint(_dfStrategyEnvKey(_prefix, _branchIndex, _strategyIndex));
        }

        string memory branchKey = _dfEnvKey(_prefix, _branchIndex);
        try vm.envUint(branchKey) returns (uint256 branchValue) {
            return branchValue;
        } catch {}

        try vm.envUint(_prefix) returns (uint256 sharedValue) {
            return sharedValue;
        } catch {}

        revert(string.concat("DF: missing ", branchKey));
    }

    function _dfRequiredStrategyAddress(string memory _prefix, uint256 _branchIndex, uint256 _strategyIndex)
        internal
        view
        returns (address)
    {
        string memory key = _dfStrategyEnvKey(_prefix, _branchIndex, _strategyIndex);
        address value = vm.envAddress(key);
        require(value != address(0), string.concat("DF: zero ", key));
        return value;
    }

    function _dfRequiredAddress(string memory _key) internal view returns (address value) {
        value = vm.envAddress(_key);
        require(value != address(0), string.concat("DF: zero ", _key));
    }

    function _dfRequiredBranchAddress(string memory _prefix, uint256 _branchIndex) internal view returns (address) {
        string memory branchKey = _dfEnvKey(_prefix, _branchIndex);
        address value = vm.envAddress(branchKey);
        require(value != address(0), string.concat("DF: zero ", branchKey));
        return value;
    }

    function _dfRequiredUint(string memory _key) internal view returns (uint256 value) {
        value = vm.envUint(_key);
        require(value != 0, string.concat("DF: zero ", _key));
    }

    function _dfRequiredBranchUint(string memory _prefix, uint256 _branchIndex) internal view returns (uint256) {
        string memory branchKey = _dfEnvKey(_prefix, _branchIndex);
        uint256 value = vm.envUint(branchKey);
        require(value != 0, string.concat("DF: zero ", branchKey));
        return value;
    }

    function _requireContract(address _target, string memory _label) internal view {
        require(_target != address(0), string.concat("DF: zero ", _label));
        require(_target.code.length != 0, string.concat("DF: codeless ", _label));
    }

    /// @dev Exhaustive post-deployment check for the one-shot AddressesRegistry.
    ///      This intentionally runs after the CREATE2 targets have been deployed:
    ///      enforcing code existence inside setAddresses would reject the valid
    ///      counterfactual addresses required by the constructor dependency cycle.
    function _verifyAddressesRegistryWiring(
        IAddressesRegistry _registry,
        IAddressesRegistry.AddressVars memory _expected
    ) internal {
        _verifyRegisteredContract(address(_registry.collToken()), address(_expected.collToken), "collToken");
        _verifyRegisteredContract(
            address(_registry.borrowerOperations()), address(_expected.borrowerOperations), "borrowerOperations"
        );
        _verifyRegisteredContract(address(_registry.troveManager()), address(_expected.troveManager), "troveManager");
        _verifyRegisteredContract(address(_registry.troveNFT()), address(_expected.troveNFT), "troveNFT");
        _verifyRegisteredContract(address(_registry.metadataNFT()), address(_expected.metadataNFT), "metadataNFT");
        _verifyRegisteredContract(address(_registry.stabilityPool()), address(_expected.stabilityPool), "stabilityPool");
        _verifyRegisteredContract(address(_registry.priceFeed()), address(_expected.priceFeed), "priceFeed");
        _verifyRegisteredContract(address(_registry.activePool()), address(_expected.activePool), "activePool");
        _verifyRegisteredContract(address(_registry.defaultPool()), address(_expected.defaultPool), "defaultPool");
        _verifyRegisteredContract(_registry.gasPoolAddress(), _expected.gasPoolAddress, "gasPoolAddress");
        _verifyRegisteredContract(
            address(_registry.collSurplusPool()), address(_expected.collSurplusPool), "collSurplusPool"
        );
        _verifyRegisteredContract(address(_registry.sortedTroves()), address(_expected.sortedTroves), "sortedTroves");
        _verifyRegisteredContract(
            address(_registry.interestRouter()), address(_expected.interestRouter), "interestRouter"
        );
        _verifyRegisteredContract(address(_registry.hintHelpers()), address(_expected.hintHelpers), "hintHelpers");
        _verifyRegisteredContract(
            address(_registry.multiTroveGetter()), address(_expected.multiTroveGetter), "multiTroveGetter"
        );
        _verifyRegisteredContract(
            address(_registry.collateralRegistry()), address(_expected.collateralRegistry), "collateralRegistry"
        );
        _verifyRegisteredContract(address(_registry.jpydfToken()), address(_expected.jpydfToken), "jpydfToken");
        _verifyRegisteredContract(address(_registry.WETH()), address(_expected.WETH), "WETH");
    }

    function _verifyRegisteredContract(address _registered, address _expected, string memory _label) internal view {
        require(_registered == _expected, string.concat("DF: addressesRegistry ", _label, " mismatch"));
        _requireContract(_registered, string.concat("addressesRegistry ", _label));
    }

    function _dfEnvKey(string memory _prefix, uint256 _branchIndex) internal pure returns (string memory) {
        return string.concat(_prefix, "_", vm.toString(_branchIndex));
    }

    function _dfStrategyEnvKey(string memory _prefix, uint256 _branchIndex, uint256 _strategyIndex)
        internal
        view
        returns (string memory)
    {
        if (!_dfStrategyArrayEnabled(_branchIndex)) return _dfEnvKey(_prefix, _branchIndex);
        return string.concat(_prefix, "_", vm.toString(_branchIndex), "_", vm.toString(_strategyIndex));
    }

    function _dfStrategyArrayEnabled(uint256 _branchIndex) internal view returns (bool) {
        return vm.envExists(_dfEnvKey("DF_STRATEGY_COUNT", _branchIndex));
    }

    /// @dev DF Phase 4 deploy-tail invariant checks; reverts the whole deployment if any break.
    function _verifyDFWiring(DeploymentResult memory r) internal {
        assert(r.contractsArray.length == NUM_DF_BRANCHES);
        _verifyDFInterestRouter(r);
        _verifyBridgeReadiness(r);

        address reservedBranchRiskParamsFinalizer =
            r.contractsArray[NUM_DF_ACTIVE_BRANCHES].addressesRegistry.riskParamsFinalizer();
        _requireContract(reservedBranchRiskParamsFinalizer, "reserved branch risk params finalizer");

        for (uint256 i = 0; i < r.contractsArray.length; ++i) {
            LiquityContracts memory c = r.contractsArray[i];

            bool active = i < NUM_DF_ACTIVE_BRANCHES;
            require(c.addressesRegistry.riskParamsFinalized() == active, "DF: risk params finalization mismatch");
            require(
                c.addressesRegistry.riskParamsFinalizer() == (active ? address(0) : reservedBranchRiskParamsFinalizer),
                "DF: risk params finalizer mismatch"
            );

            require(address(r.collateralRegistry.getToken(i)) == address(c.collToken), "DF: registry token mismatch");
            require(
                address(r.collateralRegistry.getTroveManager(i)) == address(c.troveManager),
                "DF: registry troveManager mismatch"
            );

            PriceFeedProxy feedProxy = PriceFeedProxy(address(c.priceFeed));
            require(address(feedProxy.borrowerOperations()) == address(c.borrowerOperations), "DF: proxy BO mismatch");
            // Read back the on-chain consumer side too: the branch's AddressesRegistry must
            // reference this exact proxy. c.priceFeed alone is the in-memory deploy value, so
            // without this readback a registry-side miswire would pass verification
            // (Development-Plan Phase 4: proxy<->BO/AddressesRegistry bidirectional wiring).
            require(
                address(c.addressesRegistry.priceFeed()) == address(c.priceFeed), "DF: addressesRegistry feed mismatch"
            );
            require(feedProxy.source().code.length > 0, "DF: codeless source");

            _verifyDFPriceFeedReadback(c.priceFeed);

            DToken dToken = r.dTokens[i];
            require(address(dToken) == address(c.collToken), "DF: collToken is not the dToken");
            require(dToken.vault() == address(r.vaults[i]), "DF: dToken vault mismatch");
            require(dToken.riskParamsRegistry() == address(c.addressesRegistry), "DF: dToken registry mismatch");
            require(r.vaults[i].treasury() == _dfVaultTreasury(), "DF: vault treasury mismatch");

            if (active) {
                require(address(dToken.underlying()) == address(r.underlyings[i]), "DF: active underlying mismatch");
                require(dToken.cap() == 0, "DF: active cap != 0");
                require(r.vaults[i].backingRatio() == 1e18, "DF: backingRatio != 1e18");
                // Production-parity wiring: the source is the PRODUCTION DF feed and it reads
                // backing from THIS branch's vault (ORCL-FR-014 input side).
                require(
                    IDFFeedVaultRef(feedProxy.source()).collateralVault() == address(r.vaults[i]),
                    "DF: feed vault mismatch"
                );
                uint256 expectedStrategyCount = _dfExpectedStrategyCount(i);
                if (expectedStrategyCount == 0) {
                    require(address(r.strategies[i]) == address(0), "DF: none strategy present");
                    require(r.vaults[i].getStrategiesCount() == 0, "DF: none strategy registered");
                    require(r.vaults[i].totalWeightBps() == 0, "DF: none strategy weight");
                } else {
                    require(address(r.strategies[i]) != address(0), "DF: active strategy missing");
                    require(r.vaults[i].getStrategiesCount() == expectedStrategyCount, "DF: active strategy count");
                    require(r.vaults[i].totalWeightBps() != 0, "DF: active strategy weight");
                    require(address(r.strategies[i]) == address(r.vaults[i].strategies(0)), "DF: primary strategy");
                    for (uint256 strategyIndex; strategyIndex < expectedStrategyCount; strategyIndex++) {
                        IBaseStrategyView strategy = IBaseStrategyView(address(r.vaults[i].strategies(strategyIndex)));
                        require(strategy.vault() == address(r.vaults[i]), "DF: strategy vault mismatch");
                        require(strategy.underlying() == address(r.underlyings[i]), "DF: strategy underlying mismatch");
                    }
                }

                CollateralYieldZapper collateralYieldZapper = c.collateralYieldZapper;
                require(address(collateralYieldZapper) != address(0), "DF: active CYZ missing");
                require(
                    address(collateralYieldZapper.collateralVault()) == address(r.vaults[i]), "DF: CYZ vault mismatch"
                );
                require(address(collateralYieldZapper.dToken()) == address(dToken), "DF: CYZ dToken mismatch");
                require(address(collateralYieldZapper.collToken()) == address(dToken), "DF: CYZ coll mismatch");
                require(
                    address(collateralYieldZapper.underlyingToken()) == address(r.underlyings[i]),
                    "DF: CYZ underlying mismatch"
                );
                require(
                    address(collateralYieldZapper.borrowerOperations()) == address(c.borrowerOperations),
                    "DF: CYZ BO mismatch"
                );
                require(address(collateralYieldZapper.jpydfToken()) == address(r.jpydfToken), "DF: CYZ JPYdf mismatch");
            } else {
                require(address(dToken.underlying()) == address(0), "DF: inert has underlying");
                require(dToken.cap() == 0, "DF: inert cap != 0");
                require(address(r.vaults[i].underlying()) == address(0), "DF: inert vault has underlying");
                require(address(r.strategies[i]) == address(0), "DF: inert strategy present");
                require(r.vaults[i].getStrategiesCount() == 0, "DF: inert strategy registered");
                require(r.vaults[i].totalWeightBps() == 0, "DF: inert strategy weight");
                require(
                    feedProxy.source().codehash == keccak256(type(PriceFeedPlaceholder).runtimeCode),
                    "DF: inert source is not placeholder"
                );
                require(address(c.collateralYieldZapper) == address(0), "DF: inert CYZ deployed");
            }
        }
    }

    function _verifyDFPriceFeedReadback(IPriceFeed _priceFeed) internal {
        (uint256 price, bool failed) = _priceFeed.fetchPrice();
        require(price > 0 && price != type(uint256).max && !failed, "DF: bad fetchPrice");
        (uint256 redemptionPrice, bool redemptionFailed) = _priceFeed.fetchRedemptionPrice();
        require(
            redemptionPrice > 0 && redemptionPrice != type(uint256).max && !redemptionFailed,
            "DF: bad fetchRedemptionPrice"
        );
        (uint256 urgentRedemptionPrice, bool urgentRedemptionFailed) = _priceFeed.fetchUrgentRedemptionPrice();
        require(
            urgentRedemptionPrice > 0 && urgentRedemptionPrice != type(uint256).max && !urgentRedemptionFailed,
            "DF: bad fetchUrgentRedemptionPrice"
        );
    }

    function _verifyDFInterestRouter(DeploymentResult memory r) internal view {
        address routerAddress = address(r.contractsArray[0].interestRouter);
        require(routerAddress != address(0), "DF: zero interest router");
        require(routerAddress.code.length != 0, "DF: codeless interest router");

        IDeployInterestRouterForwarderView router = IDeployInterestRouterForwarderView(routerAddress);

        try router.jpydfToken() returns (address token) {
            require(token == address(r.jpydfToken), "DF: router token mismatch");
        } catch {
            revert("DF: router not forwarder");
        }

        try router.recipient() returns (address recipient) {
            require(recipient == vm.envAddress("DF_INTEREST_ROUTER_RECIPIENT"), "DF: router recipient mismatch");
            r.jpydfToken.requireValidRecipient(recipient);
        } catch {
            revert("DF: router not forwarder");
        }

        try router.owner() returns (address owner) {
            require(owner == vm.envAddress("DF_INTEREST_ROUTER_OWNER"), "DF: router owner mismatch");
        } catch {
            revert("DF: router not forwarder");
        }

        try router.pendingOwner() returns (address pendingOwner) {
            require(pendingOwner == address(0), "DF: router pending owner");
        } catch {
            revert("DF: router not forwarder");
        }

        for (uint256 i = 1; i < r.contractsArray.length; ++i) {
            require(address(r.contractsArray[i].interestRouter) == routerAddress, "DF: mixed interest router");
        }
    }

    function _verifyBridgeReadiness(DeploymentResult memory r) internal view {
        require(r.jpydfToken.bridgeAdmin() == bridgeAdmin, "DF: bridge admin mismatch");
        require(r.jpydfToken.bridgeMinterCount() == 0, "DF: bridge minters active");
        require(r.jpydfToken.proposedBridgeMinter() == address(0), "DF: bridge minter pending");
    }

    /// @dev Splices `collateralVaultLens` into the manifest. Adding it inside
    ///      `_getManifestJson` pushes that function past the stack limit.
    function _withCollateralVaultLens(string memory _manifest, address _lens) internal pure returns (string memory) {
        return string.concat('{"collateralVaultLens":"', _lens.toHexString(), '",', _stripLeadingBrace(_manifest));
    }

    function _withDeploymentMetadata(string memory _manifest, string memory _deploymentMode)
        internal
        view
        returns (string memory)
    {
        return string.concat(
            "{",
            string.concat(
                string.concat('"deploymentClassification":"', _getDeploymentClassification(), '",'),
                string.concat('"deploymentProfile":"', _getDeploymentProfile(), '",'),
                string.concat('"deploymentId":"', _getDeploymentId(), '",'),
                string.concat('"chainId":', block.chainid.toString(), ","),
                string.concat('"deploymentMode":"', _deploymentMode, '",')
            ),
            string.concat(
                string.concat('"create2Salt":"', uint256(SALT).toHexString(32), '",'),
                string.concat('"deployer":"', deployer.toHexString(), '",'),
                _stripLeadingBrace(_manifest)
            )
        );
    }

    function _stripLeadingBrace(string memory _json) internal pure returns (string memory) {
        bytes memory raw = bytes(_json);
        bytes memory out = new bytes(raw.length - 1);
        for (uint256 i = 1; i < raw.length; ++i) {
            out[i - 1] = raw[i];
        }
        return string(out);
    }

    function _getManifestJson(DeploymentResult memory deployed) internal view returns (string memory) {
        string[] memory branches = new string[](deployed.contractsArray.length);

        // Poor man's .map()
        for (uint256 i = 0; i < branches.length; ++i) {
            branches[i] = _getBranchContractsJson(deployed.contractsArray[i], _dfDTokenSlot(i));
        }

        // DF Phase 4: per-branch yield-layer addresses (dToken / vault / strategy / underlying),
        // emitted only when DF wiring populated the arrays (complete DF deploys, including mainnet).
        string memory dfYieldJson = "";
        string memory envFreezeJson = "";
        if (deployed.dTokens.length == deployed.contractsArray.length) {
            string[] memory dfYield = new string[](deployed.contractsArray.length);
            for (uint256 i = 0; i < dfYield.length; ++i) {
                dfYield[i] = _getDFYieldJson(deployed, i);
            }
            envFreezeJson = string.concat('"envFreeze":', _getEnvFreezeJson(deployed), ",");
            dfYieldJson = string.concat('"dfYield":[', dfYield.join(","), "],");
        }

        return string.concat(
            "{",
            string.concat(
                string.concat('"constants":', _getDeploymentConstants(), ","),
                string.concat('"collateralRegistry":"', address(deployed.collateralRegistry).toHexString(), '",'),
                string.concat('"jpydfToken":"', address(deployed.jpydfToken).toHexString(), '",'),
                // Protocol-level WETH (gas compensation token wired into every
                // AddressesRegistry). Consumers must read WETH from here, never
                // from a branch underlying, which can diverge (e.g. wstETH).
                string.concat('"weth":"', address(WETH).toHexString(), '",'),
                _getBridgeReadinessJson(deployed.jpydfToken),
                string.concat('"hintHelpers":"', address(deployed.hintHelpers).toHexString(), '",'),
                string.concat('"multiTroveGetter":"', address(deployed.multiTroveGetter).toHexString(), '",'),
                string.concat(
                    '"liquidationCandidateGetter":"', address(deployed.liquidationCandidateGetter).toHexString(), '",'
                ),
                string.concat('"debtInFrontHelper":"', address(deployed.debtInFrontHelper).toHexString(), '",')
            ),
            string.concat(
                string.concat('"redemptionHelper":"', address(deployed.redemptionHelper).toHexString(), '",'),
                envFreezeJson,
                dfYieldJson,
                string.concat('"branches":[', branches.join(","), "]")
            ),
            "}"
        );
    }

    function _getDFYieldJson(DeploymentResult memory deployed, uint256 branchIndex)
        internal
        view
        returns (string memory)
    {
        bool activeBranch = branchIndex < NUM_DF_ACTIVE_BRANCHES;
        uint256 strategyCount = activeBranch ? _dfExpectedStrategyCount(branchIndex) : 0;
        address dToken = address(deployed.dTokens[branchIndex]);

        return string.concat(
            "{",
            string.concat(
                string.concat('"dToken":"', dToken.toHexString(), '",'),
                string.concat('"collateralVault":"', address(deployed.vaults[branchIndex]).toHexString(), '",'),
                string.concat(
                    '"collateralYieldZapper":"',
                    address(deployed.contractsArray[branchIndex].collateralYieldZapper).toHexString(),
                    '",'
                ),
                _getDFYieldNativeEthRouteJson(deployed.contractsArray[branchIndex].collateralYieldZapper),
                string.concat('"treasury":"', deployed.vaults[branchIndex].treasury().toHexString(), '",')
            ),
            string.concat(
                string.concat('"strategies":[', _getDFYieldStrategiesJson(deployed, branchIndex, strategyCount), "],")
            ),
            _getDFYieldOracleJson(deployed.contractsArray[branchIndex].priceFeed, dToken),
            string.concat('"underlying":"', address(deployed.underlyings[branchIndex]).toHexString(), '"'),
            "}"
        );
    }

    function _getDFPriceFeedSourceJson(IPriceFeed priceFeed) internal view returns (string memory) {
        return string.concat('"priceFeedSource":"', PriceFeedProxy(address(priceFeed)).source().toHexString(), '",');
    }

    function _getDFYieldOracleJson(IPriceFeed priceFeed, address dToken) internal view returns (string memory) {
        return string.concat(
            string.concat(
                _getDFPriceFeedSourceJson(priceFeed),
                string.concat('"collUsdFeed":"', dfCollUsdOracle[dToken].toHexString(), '",'),
                string.concat('"collUsdStaleness":"', dfCollUsdStaleness[dToken].toString(), '",'),
                string.concat('"redemptionEthUsdFeed":"', dfRedemptionEthUsdOracle[dToken].toHexString(), '",'),
                string.concat('"redemptionEthUsdStaleness":"', dfRedemptionEthUsdStaleness[dToken].toString(), '",')
            ),
            string.concat(
                string.concat('"redemptionStEthEthFeed":"', dfRedemptionStEthEthOracle[dToken].toHexString(), '",'),
                string.concat(
                    '"redemptionStEthEthStaleness":"', dfRedemptionStEthEthStaleness[dToken].toString(), '",'
                ),
                string.concat('"jpyUsdFeed":"', dfJpyUsdOracle.toHexString(), '",'),
                string.concat('"jpyUsdStaleness":"', dfJpyUsdStaleness.toString(), '",'),
                string.concat('"jpyUsdRateProvider":"', dfJpyUsdRateProvider.toHexString(), '",')
            )
        );
    }

    function _getDFYieldNativeEthRouteJson(CollateralYieldZapper collateralYieldZapper)
        internal
        view
        returns (string memory)
    {
        address stEthToken;
        address lidoReferral;
        address lidoReferralManager;
        if (address(collateralYieldZapper) != address(0)) {
            stEthToken = address(collateralYieldZapper.stEthToken());
            lidoReferral = collateralYieldZapper.lidoReferral();
            lidoReferralManager = collateralYieldZapper.lidoReferralManager();
        }
        return string.concat(
            string.concat('"stEthToken":"', stEthToken.toHexString(), '",'),
            string.concat('"lidoReferral":"', lidoReferral.toHexString(), '",'),
            string.concat('"lidoReferralManager":"', lidoReferralManager.toHexString(), '",')
        );
    }

    function _getDFYieldStrategiesJson(DeploymentResult memory deployed, uint256 branchIndex, uint256 strategyCount)
        internal
        view
        returns (string memory)
    {
        string[] memory strategies = new string[](strategyCount);
        for (uint256 strategyIndex; strategyIndex < strategyCount; strategyIndex++) {
            strategies[strategyIndex] = _getDFYieldStrategyJson(deployed, branchIndex, strategyIndex);
        }
        return strategies.join(",");
    }

    function _getDFYieldStrategyJson(DeploymentResult memory deployed, uint256 branchIndex, uint256 strategyIndex)
        internal
        view
        returns (string memory)
    {
        return string.concat(
            "{",
            string.concat(
                string.concat(
                    '"strategy":"', address(deployed.vaults[branchIndex].strategies(strategyIndex)).toHexString(), '",'
                ),
                string.concat('"strategyKind":"', _dfStrategyKind(branchIndex, strategyIndex), '",'),
                string.concat(
                    '"strategyWeightBps":"', _dfStrategyWeightBps(branchIndex, strategyIndex).toString(), '",'
                ),
                string.concat('"strategyCap":"', _dfStrategyCap(branchIndex, strategyIndex).toString(), '"')
            ),
            "}"
        );
    }

    function _getEnvFreezeJson(DeploymentResult memory deployed) internal view returns (string memory) {
        address routerAddress = address(deployed.contractsArray[0].interestRouter);
        IDeployInterestRouterForwarderView router = IDeployInterestRouterForwarderView(routerAddress);

        return string.concat(
            "{",
            string.concat(
                string.concat('"bridgeAdmin":"', deployed.jpydfToken.bridgeAdmin().toHexString(), '",'),
                string.concat('"treasury":"', deployed.vaults[0].treasury().toHexString(), '",'),
                string.concat('"interestRouter":"', routerAddress.toHexString(), '",'),
                string.concat('"interestRouterRecipient":"', router.recipient().toHexString(), '",')
            ),
            string.concat(
                string.concat('"interestRouterOwner":"', router.owner().toHexString(), '",'),
                string.concat('"interestRouterPendingOwner":"', router.pendingOwner().toHexString(), '",'),
                string.concat('"jpyUsdFeed":"', dfJpyUsdOracle.toHexString(), '",'),
                string.concat('"jpyUsdStaleness":"', dfJpyUsdStaleness.toString(), '",'),
                string.concat('"jpyUsdRateProvider":"', dfJpyUsdRateProvider.toHexString(), '"')
            ),
            "}"
        );
    }

    function _getBridgeReadinessJson(IJpydfToken jpydfToken) internal view returns (string memory) {
        string memory minterCount = jpydfToken.bridgeMinterCount().toString();
        string memory proposedMinter = jpydfToken.proposedBridgeMinter().toHexString();
        string memory zeroAddress = address(0).toHexString();

        return string.concat(
            string.concat('"bridgeAdmin":"', jpydfToken.bridgeAdmin().toHexString(), '",'),
            string.concat('"bridgeMinterCount":', minterCount, ","),
            string.concat('"proposedBridgeMinter":"', proposedMinter, '",'),
            string.concat(
                '"launchEvidence":{',
                string.concat('"bridgeMinterCount":', minterCount, ","),
                string.concat('"proposedBridgeMinter":"', proposedMinter, '",'),
                string.concat('"bridgeAdapter":"', zeroAddress, '",'),
                '"activeBridgeAdapter":false,',
                '"day1JpydfLiquidityVenue":"uniswap-v4",',
                '"day1JpydfLiquidityPair":"JPYdf/USDC",',
                '"uniswapV4RouteStatus":"unwired-audit-scope",',
                string.concat('"uniswapV4RouteAdapter":"', zeroAddress, '",'),
                '"nonDay1JpydfLiquidityRoute":false',
                "},"
            )
        );
    }
}
