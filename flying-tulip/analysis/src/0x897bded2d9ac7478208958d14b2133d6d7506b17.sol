// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2025 Flying Tulip Inc. All rights reserved.
pragma solidity ^0.8.30;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {
    Ownable2StepUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IConfigRegistry} from "./interfaces/IConfigRegistry.sol";
import {IftYieldWrapper} from "@ft-common/interfaces/IftYieldWrapper.sol";
import {Constants} from "./utils/Constants.sol";

contract ConfigRegistry is
    Initializable,
    UUPSUpgradeable,
    Ownable2StepUpgradeable,
    IConfigRegistry
{
    error NotGuardian();
    error HealthFactorMinimum();
    error InvalidBps();
    error FtYieldWrapperRequired();
    error FtYieldWrapperWrongAsset();
    error FtYieldWrapperImmutable();
    error MarginConfigInvalid();
    error AssetDecimalsUnsupported();
    error BorrowableRequiresMM();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    address public guardian;
    mapping(address => AssetCfg) public assetCfg;
    address public oracleRouter;

    // ========== MarginClosed Configuration ==========
    /// @notice Target HF used by liquidation engines for MarginClosed accounts (e.g. 10000 = 1.0x).
    uint16 public marginHfTargetBps;
    /// @notice Safe HF used by PositionsManager invariants for MarginClosed accounts (e.g. 20000 = 2.0x).
    uint16 public marginHfSafeBps;
    /// @notice If true, MarginClosed accounts cannot withdraw while any debt is outstanding.
    bool public marginWithdrawRequiresNoDebt;
    /// @notice Optional settlement asset for MarginClosed accounts (address(0) disables).
    address public marginSettlementAsset;
    /// @notice If true, MarginClosed accounts may only withdraw `marginSettlementAsset`.
    bool public marginRestrictWithdrawToSettlement;
    /// @notice Optional minimum equity (margin) required for accounts with debt, in USD-WAD (1e18).
    /// @dev Set to 0 to disable.
    uint256 public marginMinEquityUSDWad;
    mapping(address => bool) public dnmmStrategies;

    modifier onlyGuardianOrOwner() {
        _onlyGuardianOrOwner();
        _;
    }

    function _onlyGuardianOrOwner() internal view {
        if (msg.sender != guardian && msg.sender != owner()) revert NotGuardian();
    }

    function initialize(address _owner, address _oracle) external initializer {
        __UUPSUpgradeable_init();
        __Ownable_init(_owner);
        __Ownable2Step_init();
        _setGuardian(_owner);
        _setOracle(_oracle);
        // set default risk thresholds to match constructor-era defaults
        _setMarginHfTarget(12000); // 120%
        _setMarginHfSafe(21000); // 210%
        // delay remains 0 by default
    }

    function setGuardian(address g) external onlyOwner {
        _setGuardian(g);
    }

    function _setGuardian(address g) internal {
        guardian = g;
        emit GuardianChanged(g);
    }

    function _setOracle(address o) internal {
        oracleRouter = o;
        emit OracleSet(o);
    }

    function setOracle(address next) external onlyOwner {
        _setOracle(next);
        emit OracleChanged(next);
    }

    function setAsset(address asset, AssetCfg calldata c) external onlyOwner {
        // Prevent valuation overflow/DoS from misconfigured tokens (10 ** decimals).
        // Most production ERC20s use 6-18 decimals; enforce a sane upper bound at listing time.
        if (IERC20Metadata(asset).decimals() > 18) revert AssetDecimalsUnsupported();
        // Sanity checks: bps fields must be within [0, 10000]
        if (c.mmBps > Constants.BPS) revert InvalidBps();
        if (c.borrowable && c.mmBps == 0) revert BorrowableRequiresMM();
        if (c.ftYieldWrapper == address(0)) revert FtYieldWrapperRequired();
        if (IftYieldWrapper(c.ftYieldWrapper).token() != asset) revert FtYieldWrapperWrongAsset();
        // Safety: changing a live asset's wrapper would strand all existing PM funds
        // (cash is accounted in wrapper shares). Require wrapper to be immutable once set.
        address prevWrapper = assetCfg[asset].ftYieldWrapper;
        if (prevWrapper != address(0) && prevWrapper != c.ftYieldWrapper) {
            revert FtYieldWrapperImmutable();
        }
        assetCfg[asset] = c;
        emit AssetSet(asset, c);
    }

    function setAssetMM(address asset, uint16 newMmBps) external onlyOwner {
        if (newMmBps > Constants.BPS) revert InvalidBps();
        AssetCfg storage cfg = assetCfg[asset];
        if (cfg.borrowable && newMmBps == 0) revert BorrowableRequiresMM();
        cfg.mmBps = newMmBps;
        emit MMChanged(asset, newMmBps);
        emit AssetSet(asset, cfg);
    }

    function setAssetBorrowable(address asset, bool borrowable) external onlyOwner {
        AssetCfg storage cfg = assetCfg[asset];
        if (borrowable && cfg.mmBps == 0) revert BorrowableRequiresMM();
        cfg.borrowable = borrowable;
        emit BorrowableChanged(asset, borrowable);
        emit AssetSet(asset, cfg);
    }

    function setAssetCollateral(address asset, bool collateral) external onlyOwner {
        AssetCfg storage cfg = assetCfg[asset];
        cfg.collateral = collateral;
        emit CollateralChanged(asset, collateral);
        emit AssetSet(asset, cfg);
    }

    function setDNMMStrategy(address strategy, bool ok) external onlyOwner {
        dnmmStrategies[strategy] = ok;
    }

    function getAssetCfg(address asset) external view returns (AssetCfg memory) {
        return assetCfg[asset];
    }

    function setMarginHFTarget(uint16 bps) external onlyGuardianOrOwner {
        if (bps < Constants.BPS) revert HealthFactorMinimum();
        // Maintain invariant: hfSafe >= hfTarget.
        // If safe is unset (0), allow initializing target first.
        if (marginHfSafeBps != 0 && bps > marginHfSafeBps) revert MarginConfigInvalid();
        _setMarginHfTarget(bps);
    }

    function _setMarginHfTarget(uint16 bps) internal {
        marginHfTargetBps = bps;
        emit MarginHFTargetSet(bps);
    }

    function setMarginHFSafe(uint16 bps) external onlyGuardianOrOwner {
        if (bps < marginHfTargetBps) revert HealthFactorMinimum();
        _setMarginHfSafe(bps);
    }

    function _setMarginHfSafe(uint16 bps) internal {
        marginHfSafeBps = bps;
        emit MarginHFSafeSet(bps);
    }

    function setMarginMinEquityUSDWad(uint256 minEquityUSDWad) external onlyGuardianOrOwner {
        marginMinEquityUSDWad = minEquityUSDWad;
        emit MarginMinEquitySet(minEquityUSDWad);
    }

    // UUPS upgrade authorization: owner-gated
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
