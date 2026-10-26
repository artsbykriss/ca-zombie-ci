// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2025 Flying Tulip Inc. All rights reserved.
pragma solidity ^0.8.30;

import {IAccountValuesLens, AccountSnapshot} from "./interfaces/IAccountValuesLens.sol";
import {IPositionsManager} from "./interfaces/IPositionsManager.sol";
import {IConfigRegistry} from "./interfaces/IConfigRegistry.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {
    Ownable2StepUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {Constants} from "./utils/Constants.sol";
import {IOracleUSD} from "@ft-common/interfaces/IOracleUSD.sol";
import {IIRM} from "./interfaces/IIRM.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IAccountRiskModule} from "./interfaces/IAccountRiskModule.sol";

/// @notice Valuation lens that composes baseline lending valuation + optional per-engine risk modules.
/// @dev Returns an AccountSnapshot struct with equity, maintenance, collateral incl. PnL,
///      collateral excl. PnL, and debt values.
contract AccountValuesRouter is
    Initializable,
    UUPSUpgradeable,
    Ownable2StepUpgradeable,
    IAccountValuesLens
{
    uint256 internal constant WAD = Constants.WAD;
    uint256 internal constant BPS = Constants.BPS;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    // Use shared constants for consistency

    // -------- Errors --------
    error NotGuardian();
    error ZeroAddress();
    error RiskModuleNotAllowed();
    error RiskModuleAlreadyAdded();
    error RiskModuleNotFound();
    error CallerNotRiskModule();

    // -------- Roles --------
    address public guardian;

    // -------- Engine risk modules --------
    mapping(address => bool) public riskModuleAllowed; // implementation allowlist
    mapping(address => mapping(address => bool)) public isRiskModule; // pm => module => enabled?
    mapping(address => address[]) internal _riskModules; // pm => modules

    // -------- Per-user active modules (gas optimization) --------
    // pm => user => active risk modules (only these are consulted in `accountValues`)
    mapping(address => mapping(address => address[])) internal _activeRiskModules;
    // pm => user => module => index+1 in `_activeRiskModules`
    mapping(address => mapping(address => mapping(address => uint256))) internal
        _activeRiskModuleIndex;

    // Appended storage: explicit per-account waiver of all maintenance, including engine margin.
    mapping(address => mapping(address => bool)) public maintenanceExempt; // pm => user => exempt

    // -------- Events --------
    event MaintenanceExemptionSet(address indexed pm, address indexed user, bool exempt);
    event GuardianSet(address indexed guardian);
    event RiskModuleAllowed(address indexed module, bool allowed);
    event RiskModuleAdded(address indexed pm, address indexed module);
    event RiskModuleRemoved(address indexed pm, address indexed module);
    event RiskModuleActivated(address indexed pm, address indexed user, address indexed module);
    event RiskModuleDeactivated(address indexed pm, address indexed user, address indexed module);

    modifier onlyGuardianOrOwner() {
        _onlyGuardianOrOwner();
        _;
    }

    function _onlyGuardianOrOwner() internal view {
        if (msg.sender != guardian && msg.sender != owner()) revert NotGuardian();
    }

    // Inline self-call allowance removed (no longer needed with AccessManager ownership)

    function initialize(address _owner) external initializer {
        if (_owner == address(0)) revert ZeroAddress();
        __UUPSUpgradeable_init();
        __Ownable_init(_owner);
        __Ownable2Step_init();
        guardian = _owner;
        emit GuardianSet(_owner);
    }

    // UUPS upgrade authorization: owner-gated
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function setGuardian(address g) external onlyOwner {
        if (g == address(0)) revert ZeroAddress();
        guardian = g;
        emit GuardianSet(g);
    }

    // -------- Admin controls --------
    /// @notice Waive all maintenance for one trusted account, or restore its normal valuation.
    /// @dev Only the owner can enable; the guardian can also revoke. Exemption gives maximum HF,
    ///      including at zero equity, and prevents HF-based liquidation until revoked. Raw values,
    ///      PnL and PM's separate minimum-equity check are unchanged. No account is exempt by default.
    function setMaintenanceExempt(
        address pm,
        address user,
        bool exempt
    )
        external
        onlyGuardianOrOwner
    {
        if (exempt) _checkOwner();
        if (pm == address(0) || user == address(0)) revert ZeroAddress();
        maintenanceExempt[pm][user] = exempt;
        emit MaintenanceExemptionSet(pm, user, exempt);
    }

    function setRiskModuleAllowed(address module, bool allowed) external onlyOwner {
        if (module == address(0)) revert ZeroAddress();
        riskModuleAllowed[module] = allowed;
        emit RiskModuleAllowed(module, allowed);
    }

    /// @notice Emergency kill-switch to disable a risk module implementation globally.
    /// @dev Guardian can only disable; re-enabling requires the owner via `setRiskModuleAllowed`.
    function disableRiskModule(address module) external onlyGuardianOrOwner {
        if (module == address(0)) revert ZeroAddress();
        riskModuleAllowed[module] = false;
        emit RiskModuleAllowed(module, false);
    }

    function addRiskModule(address pm, address module) external onlyGuardianOrOwner {
        if (pm == address(0) || module == address(0)) revert ZeroAddress();
        if (!riskModuleAllowed[module]) revert RiskModuleNotAllowed();
        if (isRiskModule[pm][module]) revert RiskModuleAlreadyAdded();

        isRiskModule[pm][module] = true;
        _riskModules[pm].push(module);
        emit RiskModuleAdded(pm, module);
    }

    function removeRiskModule(address pm, address module) external onlyGuardianOrOwner {
        if (pm == address(0) || module == address(0)) revert ZeroAddress();
        if (!isRiskModule[pm][module]) revert RiskModuleNotFound();

        isRiskModule[pm][module] = false;

        address[] storage mods = _riskModules[pm];
        uint256 n = mods.length;
        for (uint256 i = 0; i < n; ++i) {
            if (mods[i] == module) {
                mods[i] = mods[n - 1];
                mods.pop();
                emit RiskModuleRemoved(pm, module);
                return;
            }
        }

        // If membership mapping was true but array scan fails, state is inconsistent.
        revert RiskModuleNotFound();
    }

    function getRiskModules(address pm) external view returns (address[] memory) {
        return _riskModules[pm];
    }

    // -------- Per-user activation --------
    /// @notice Opt a user into this module's `riskContribution` for `pm` (module-only).
    /// @dev Engines should activate when exposure transitions 0 -> >0, and deactivate when >0 -> 0.
    function activateRiskModuleForUser(address pm, address user) external {
        if (pm == address(0) || user == address(0)) revert ZeroAddress();
        if (!isRiskModule[pm][msg.sender]) revert CallerNotRiskModule();

        if (_activeRiskModuleIndex[pm][user][msg.sender] != 0) return;
        _activeRiskModules[pm][user].push(msg.sender);
        _activeRiskModuleIndex[pm][user][msg.sender] = _activeRiskModules[pm][user].length;
        emit RiskModuleActivated(pm, user, msg.sender);
    }

    /// @notice Remove a user from this module's `riskContribution` list for `pm` (module-only).
    /// @dev Deactivation is allowed even if the module was later removed from the PM allowlist.
    function deactivateRiskModuleForUser(address pm, address user) external {
        if (pm == address(0) || user == address(0)) revert ZeroAddress();

        uint256 idxPlusOne = _activeRiskModuleIndex[pm][user][msg.sender];
        if (idxPlusOne == 0) return;

        address[] storage mods = _activeRiskModules[pm][user];
        uint256 idx = idxPlusOne - 1;
        uint256 last = mods.length - 1;
        if (idx != last) {
            address moved = mods[last];
            mods[idx] = moved;
            _activeRiskModuleIndex[pm][user][moved] = idxPlusOne;
        }
        mods.pop();
        delete _activeRiskModuleIndex[pm][user][msg.sender];
        emit RiskModuleDeactivated(pm, user, msg.sender);
    }

    function getActiveRiskModules(
        address pm,
        address user
    )
        external
        view
        returns (address[] memory)
    {
        return _activeRiskModules[pm][user];
    }

    function accountValues(
        address pm,
        address user
    )
        external
        view
        override
        returns (AccountSnapshot memory s)
    {
        (uint256 rawCollUSD, uint256 rawDebtUSD, uint256 maintBaseUSDWad) =
            _accountValuesBase(pm, user);
        (int256 pnlUSDWad, uint256 maintEngUSDWad) = _engineRiskContribution(pm, user);

        s.maintUSDWad = maintBaseUSDWad + maintEngUSDWad;
        s.collUSDWad = rawCollUSD;
        s.debtUSDWad = rawDebtUSD;
        s.pnlAdjCollUSDWad = rawCollUSD + (pnlUSDWad > 0 ? uint256(pnlUSDWad) : 0);
        s.enginePnLUSDWad = pnlUSDWad;

        int256 equity = int256(rawCollUSD) - int256(rawDebtUSD) + pnlUSDWad;
        s.equityUSDWad = equity > 0 ? uint256(equity) : 0;
        if (maintenanceExempt[pm][user]) s.maintUSDWad = 0;
    }

    function _engineRiskContribution(
        address pmAddr,
        address user
    )
        internal
        view
        returns (int256 pnlUSDWad, uint256 maintUSDWad)
    {
        address[] storage mods = _activeRiskModules[pmAddr][user];
        uint256 n = mods.length;
        for (uint256 i = 0; i < n; ++i) {
            address mod = mods[i];
            // Avoid querying modules that have been removed from this PM or globally disallowed.
            // This ensures `removeRiskModule` and `setRiskModuleAllowed(false)` actually disable
            // contribution even if per-user activations remain in `_activeRiskModules`.
            if (!isRiskModule[pmAddr][mod] || !riskModuleAllowed[mod]) {
                continue;
            }

            (int256 p, uint256 m) = IAccountRiskModule(mod).riskContribution(pmAddr, user);
            pnlUSDWad += p;
            maintUSDWad += m;
        }
    }

    function _accountValuesBase(
        address pmAddr,
        address user
    )
        internal
        view
        returns (uint256 rawCollUSD, uint256 rawDebtUSD, uint256 maintUSD)
    {
        IPositionsManager _pm = IPositionsManager(pmAddr);
        IConfigRegistry cfg = _pm.config();
        address oracleRouter = cfg.oracleRouter();

        // -------- Collateral side --------
        address[] memory collAssets = _pm.userCollateralAssets(user);

        uint256 n = collAssets.length;
        for (uint256 i = 0; i < n; ++i) {
            address a = collAssets[i];

            IConfigRegistry.AssetCfg memory c = cfg.getAssetCfg(a);
            if (c.collateral) {
                (uint256 avail,) = _pm.getBalance(user, a);
                if (avail != 0) {
                    uint256 px = IOracleUSD(oracleRouter).priceUSD(a); // USD-WAD per token
                    uint256 scale = 10 ** uint256(IERC20Metadata(a).decimals());
                    uint256 valueUSD = Math.mulDiv(avail, px, scale); // floor
                    rawCollUSD += valueUSD;

                    maintUSD += Math.mulDiv(valueUSD, c.mmBps, BPS); // floor
                }
            }
        }

        // -------- Debt side --------
        address[] memory debtAssets = _pm.userDebtAssets(user);

        uint256 m = debtAssets.length;
        for (uint256 j = 0; j < m; ++j) {
            address a = debtAssets[j];
            uint256 shares = _pm.debtShares(user, a);
            if (shares == 0) continue;

            uint256 assetTotalShares = _pm.totalDebtShares(a);
            if (assetTotalShares == 0) continue;

            uint256 borrowsNow = _previewBorrows(_pm, cfg, a);
            if (borrowsNow == 0) continue;

            uint256 principalNow =
                Math.mulDiv(shares, borrowsNow, assetTotalShares, Math.Rounding.Ceil);

            uint256 px = IOracleUSD(oracleRouter).priceUSD(a);
            uint256 scale = 10 ** uint256(IERC20Metadata(a).decimals());
            uint256 valueUSD = Math.mulDiv(principalNow, px, scale, Math.Rounding.Ceil);
            rawDebtUSD += valueUSD;

            uint16 rateBps = cfg.getAssetCfg(a).mmBps;
            maintUSD += Math.mulDiv(valueUSD, rateBps, BPS);
        }
    }

    /// @notice Preview the current borrow index for `asset` as of now (view-only).
    function previewBorrowIndexWad(
        address pmAddr,
        address asset
    )
        public
        view
        returns (uint256 idxNow)
    {
        return _previewBorrowIndexWad(pmAddr, asset);
    }

    function _previewBorrowIndexWad(
        address pmAddr,
        address asset
    )
        internal
        view
        virtual
        returns (uint256)
    {
        IPositionsManager _pm = IPositionsManager(pmAddr);
        IConfigRegistry cfg = _pm.config();
        return _previewBorrowIndexWad(_pm, cfg, asset);
    }

    function _previewBorrowIndexWad(
        IPositionsManager _pm,
        IConfigRegistry cfg,
        address asset
    )
        private
        view
        returns (uint256)
    {
        (uint256 borrowIndexWad, uint256 cash, uint256 borrows,,,, uint256 lastAccrual,) =
            _pm.astate(asset);

        // If never initialized, treat as 1.0
        uint256 baseIdx = borrowIndexWad == 0 ? WAD : borrowIndexWad;
        uint256 last = lastAccrual;

        // No accrual history or same timestamp return stored index
        if (last == 0 || block.timestamp == last) return baseIdx;
        if (borrows == 0) return baseIdx;

        IConfigRegistry.AssetCfg memory c = cfg.getAssetCfg(asset);

        // Utilization at last accrual snapshot (consistent with your accrue())
        uint256 denom = cash + borrows;
        if (denom == 0) return baseIdx;

        uint256 utilWad = Math.mulDiv(borrows, WAD, denom);
        uint256 aprWad = IIRM(c.irm).borrowAPR(asset, utilWad);

        uint256 dt = block.timestamp - last;
        uint256 interestWad = Math.mulDiv(aprWad, dt, 365 days);
        uint256 factorWad = WAD + interestWad;

        return Math.mulDiv(baseIdx, factorWad, WAD);
    }

    function _previewBorrows(
        IPositionsManager _pm,
        IConfigRegistry cfg,
        address asset
    )
        private
        view
        returns (uint256 borrowsNow)
    {
        (, uint256 cash, uint256 borrows,,,, uint256 lastAccrual,) = _pm.astate(asset);
        if (borrows == 0) return 0;

        if (lastAccrual == 0 || block.timestamp == lastAccrual) return borrows;

        uint256 denom = cash + borrows;
        if (denom == 0) return borrows;

        uint256 utilWad = Math.mulDiv(borrows, WAD, denom);
        uint256 aprWad = IIRM(cfg.getAssetCfg(asset).irm).borrowAPR(asset, utilWad);
        uint256 dt = block.timestamp - lastAccrual;
        uint256 interestWad = Math.mulDiv(aprWad, dt, 365 days);
        uint256 interestUnits = Math.mulDiv(borrows, interestWad, WAD, Math.Rounding.Ceil);
        return borrows + interestUnits;
    }
}
