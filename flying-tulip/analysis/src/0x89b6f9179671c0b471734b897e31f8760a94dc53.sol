// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2025 Flying Tulip Inc. All rights reserved.
pragma solidity ^0.8.30;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IAccountValuesLens, AccountSnapshot} from "./interfaces/IAccountValuesLens.sol";
import {IConfigRegistry} from "./interfaces/IConfigRegistry.sol";
import {IIRM} from "./interfaces/IIRM.sol";
import {
    ReentrancyGuardTransientUpgradeable
} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardTransientUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {RiskLib} from "./utils/RiskLib.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IPositionsManager} from "./interfaces/IPositionsManager.sol";
import {TransientSlot} from "@openzeppelin/contracts/utils/TransientSlot.sol";

import {Constants} from "./utils/Constants.sol";
import {IPMViews} from "./interfaces/IPMViews.sol";
import {IftYieldWrapper} from "@ft-common/interfaces/IftYieldWrapper.sol";
import {ILeverageFlashCallback, ILiquidationFlashCallback} from "./interfaces/IFlash.sol";

contract PositionsManager is
    IPMViews,
    IPositionsManager,
    Initializable,
    ReentrancyGuardTransientUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20;
    using TransientSlot for *;

    uint256 internal constant WAD = Constants.WAD;
    uint256 internal constant RAY = 1e27;
    uint256 internal constant DEBT_SHARE_SCALE = 1e18;

    struct Position {
        uint256 avail;
        uint256 hold;
        uint40 lastT; // timestamp checkpoint within the currently-open epoch
        uint32 lastSettledEpoch;
        uint256 openSupplyTime; // banked stake-time within open epoch due to stake changes (asset*sec)
    }

    struct AssetState {
        uint256 borrowIndexWad;
        uint256 cash;
        uint256 borrows;
        uint256 totalSupplied;
        uint256 reserves;
        uint256 totalSuppliedTime; // Cumulative integral S(t) = ∫ totalSupplied dt (units: asset * seconds).
        uint40 lastAccrual;
        uint32 epoch; // Latest settled epoch id. Open epoch is always (epoch+1) and not stored yet.
    }

    struct EpochData {
        uint40 t_end; // epoch end timestamp
        uint256 S_end; // totalSuppliedTime at epoch end
        uint256 rateRay; // FT*RAY / (asset*sec)
        uint256 X_end; // X_end = Σ (Δt * rateRay) up to this epoch, units FT*RAY/asset
        uint256 interest; // actual FT received for this epoch
        uint256 supplyTime; // total stake-time for this epoch (asset*sec)
    }

    // --- PositionsManager storage (prefix must match exact declaration order) ---
    IConfigRegistry public config;
    mapping(address => bool) internal _assetInitialized;
    // Skip fields before collateral/debt only if order matches; we include full block necessary
    address public admin;
    mapping(address => bool) public engines; // PositionsManager, RFQ, ftLP, OrderBook, AMM, etc

    // Core ledgers
    // user => token => Position{}
    mapping(address => mapping(address => Position)) public collateral;
    mapping(address => mapping(address => uint256)) public debtShares; // user->asset->debt shares
    // asset => asset state
    mapping(address => AssetState) public astate;
    mapping(address => uint256) public totalDebtShares;
    // asset => epoch #
    mapping(address => mapping(uint32 => EpochData)) public epochs;

    // Per-account active asset sets (separate for clarity & simpler netting)
    mapping(address => address[]) internal _userCollAssets; // user -> assets with non-zero collateral
    mapping(address => mapping(address => uint256)) internal _collIx; // user->asset->index+1 (0 = absent)
    mapping(address => address[]) internal _userDebtAssets; // user -> assets with non-zero debt
    mapping(address => mapping(address => uint256)) internal _debtIx; // user->asset->index+1 (0 = absent)

    // Externalized account valuation lens (upgradeable)
    IAccountValuesLens public valuesLens;

    // Emergency per-asset borrow pause (deposits/withdraws still governed by asset enabled flag)
    mapping(address => bool) public borrowPaused;
    // Emergency per-asset deposit/withdraw pause (orthogonal to `enabled` and borrowPaused)
    mapping(address => bool) public depositPaused;
    mapping(address => bool) public withdrawPaused;

    bytes32 public DOMAIN_SEPARATOR;
    // Caps in token units (0 = no cap)
    mapping(address => uint256) public supplyCap; // asset => max (cash + borrows)
    mapping(address => uint256) public borrowCap; // asset => max borrows

    mapping(address => mapping(bytes32 => uint256)) public noncesTyped;

    // ========== Engine Allowances (Internal Settlement) ==========
    // user => engine => asset => remaining allowance (token units)
    mapping(address => mapping(address => mapping(address => uint256))) internal
        engineDebitAllowance;

    // Mirror of OpenZeppelin's transient reentrancy guard storage slot so that
    // engines can temporarily lock PM's `nonReentrant` entrypoints across an
    // external flash-style callback window.
    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ReentrancyGuard")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant _REENTRANCY_GUARD_STORAGE_PM =
        0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00;

    // Tracks which engine locked the PM reentrancy guard in the current transaction (transient storage).
    // This prevents one allowlisted engine from clearing another engine's lock or clearing the guard
    // while PM is executing a `nonReentrant` function (where no engine "owns" the lock).
    bytes32 private constant _ENGINE_REENTRANCY_LOCK_OWNER_PM =
        keccak256("ftdnmm.positionsmanager.engineReentrancyLock.owner");

    /// @custom:oz-upgrades-unsafe-allow constructor
    /// Immutable addresses; fixed per implementation version
    address public immutable FT;
    uint256 public DOMAIN_CHAIN_ID;

    // ========== Engine-scoped Holds (Internal Settlement) ==========
    // user => engine => asset => held amount reserved by that engine (token units)
    // Used to prevent cross-engine theft/cancellation of holds.
    mapping(address => mapping(address => mapping(address => uint256))) public engineHeld;

    // ===== Meta modules allowlist =====
    mapping(address => bool) public metaModules;

    // ===== Liquidation modules allowlist (subset of engines with special powers) =====
    mapping(address => bool) internal liquidationModules;

    // ========== Debt Delegation (Borrow Allowances) ==========
    // user => delegate => asset => remaining borrow allowance (token units)
    mapping(address => mapping(address => mapping(address => uint256))) public borrowAllowance;

    // ========== Tokenizer (ERC20 wrappers) ==========
    /// @notice Allowlisted tokenizer per collateral asset that may call `engineTransferAvail` without
    ///         consuming per-user `engineDebitAllowance`.
    /// @dev Still requires the tokenizer to be an allowlisted engine (`onlyEngine`).
    mapping(address => address) public tokenizerForAsset;

    constructor(address systemTokenFT_) {
        FT = systemTokenFT_;
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    event AdminTransferred(address indexed prev, address indexed next);
    event EngineSet(address indexed m, bool ok);
    event TokenizerSet(address indexed asset, address indexed prev, address indexed next);
    event Deposit(address indexed u, address indexed a, uint256 amt);
    event Withdraw(address indexed u, address indexed a, uint256 amt);
    event Borrow(address indexed u, address indexed a, uint256 amt);
    event Repay(address indexed u, address indexed a, uint256 amt, bool full);
    event Accrue(address indexed a, uint256 newIndex);
    event DepositFor(
        address indexed from, address indexed beneficiary, address indexed asset, uint256 amount
    );
    event DepositReferred(
        address indexed beneficiary,
        address indexed integrator,
        address indexed asset,
        uint256 amount
    );

    event RepayFor(
        address indexed from,
        address indexed borrower,
        address indexed asset,
        uint256 amount,
        bool full
    );

    event ValuesLensSet(address indexed lens);
    event BorrowPauseSet(address indexed asset, bool paused);
    event DepositPauseSet(address indexed asset, bool paused);
    event WithdrawPauseSet(address indexed asset, bool paused);
    event MetaModuleSet(address indexed module, bool ok);
    event LiquidationModuleSet(address indexed module, bool ok);

    // Margin / position-level risk mode
    event EngineApprovalSet(
        address indexed user, address indexed engine, address indexed asset, uint256 debitAllowance
    );
    event BorrowDelegateApprovalSet(
        address indexed user,
        address indexed delegate,
        address indexed asset,
        uint256 borrowAllowance
    );
    event EngineTransferAvail(
        address indexed engine, address indexed from, address indexed to, address asset, uint128 amt
    );
    event EngineTransferHoldToAvail(
        address indexed engine, address indexed from, address indexed to, address asset, uint128 amt
    );

    event EngineBatchAction(uint8 indexed kind, address indexed user);

    event Skimmed(address indexed asset, uint256 delta, uint256 newCash);

    // Settlement primitives (orderbook engines)
    event HoldReserved(address indexed user, address indexed token, uint128 amt);
    event HoldReleasedToAvail(address indexed user, address indexed token, uint128 amt);

    enum EngineActionKind {
        HOLD,
        RELEASE_HOLD_TO_AVAIL,
        TRANSFER_AVAIL,
        TRANSFER_HOLD_TO_AVAIL,
        TRANSFER_DEBT_SHARES,
        BORROW_TO_ENGINE,
        DEPOSIT_FROM_ENGINE
    }

    struct EngineAction {
        EngineActionKind kind;
        address from;
        address to;
        address asset;
        uint128 amount;
    }

    event EpochSettled(
        uint32 indexed epochId, uint256 rewardAmount, uint256 stakeTime, uint256 rateRay
    );

    modifier onlyAdmin() {
        _onlyAdmin();
        _;
    }

    modifier onlyEngine() {
        _onlyEngine();
        _;
    }

    /// @dev Ensures the account remains above the protocol's "safe" HF threshold after the action.
    ///      Keep this inside `nonReentrant` contexts to avoid reentrancy during the external lens call.
    modifier enforcePostHF(address user) {
        _;
        _enforceHFInvariant(user);
    }

    function setValuesLens(address lens) external onlyAdmin {
        if (lens == address(0)) revert ftPositionManagerLensZero();
        valuesLens = IAccountValuesLens(lens);
        emit ValuesLensSet(lens);
    }

    function setBorrowPaused(address asset, bool paused) external onlyAdmin {
        borrowPaused[asset] = paused;
        emit BorrowPauseSet(asset, paused);
    }

    function setDepositPaused(address asset, bool paused) external onlyAdmin {
        depositPaused[asset] = paused;
        emit DepositPauseSet(asset, paused);
    }

    function setWithdrawPaused(address asset, bool paused) external onlyAdmin {
        withdrawPaused[asset] = paused;
        emit WithdrawPauseSet(asset, paused);
    }

    function initialize(address _cfg, address _admin) external initializer {
        __ReentrancyGuardTransient_init();
        __UUPSUpgradeable_init();
        if (_cfg == address(0)) revert ftPositionManagerZeroAddress();
        if (_admin == address(0)) revert ftPositionManagerZeroAdmin();
        config = IConfigRegistry(_cfg);
        admin = _admin;
        emit AdminTransferred(address(0), admin);
        DOMAIN_CHAIN_ID = block.chainid;
        DOMAIN_SEPARATOR = _computeDomainSeparator(block.chainid);
    }

    function _computeDomainSeparator(uint256 chainId) internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("PositionsManager")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function _onlyAdmin() internal view {
        if (msg.sender != admin) revert ftPositionManagerOnlyOwner();
    }

    function _onlyEngine() internal view {
        if (!engines[msg.sender]) revert ftPositionManagerOnlyEngine();
    }

    function _consumeEngineDebitAllowance(address user, address asset, uint256 amt) internal {
        uint256 allowance = engineDebitAllowance[user][msg.sender][asset];
        if (allowance == type(uint256).max) return;
        if (allowance < amt) revert ftPositionManagerInsufficientEngineDebitAllowance();
        unchecked {
            engineDebitAllowance[user][msg.sender][asset] = allowance - amt;
        }
    }

    function _consumeTransferAllowance(address from, address asset, uint128 amt) internal {
        if (from != msg.sender && msg.sender != tokenizerForAsset[asset]) {
            _consumeEngineDebitAllowance(from, asset, amt);
        }
    }

    function engineDebitAllowanceOf(
        address user,
        address engine,
        address asset
    )
        external
        view
        returns (uint256)
    {
        return engineDebitAllowance[user][engine][asset];
    }

    function _requireSelfOrMetaModule(address user) internal view {
        if (user != msg.sender && !metaModules[msg.sender]) revert ftPositionManagerOnlyEngine();
    }

    function setMetaModule(address module, bool ok) external onlyAdmin {
        if (module == address(0)) revert ftPositionManagerZeroAddress();
        metaModules[module] = ok;
        emit MetaModuleSet(module, ok);
    }

    function setLiquidationModule(address module, bool ok) external onlyAdmin {
        if (module == address(0)) revert ftPositionManagerZeroAddress();
        liquidationModules[module] = ok;
        emit LiquidationModuleSet(module, ok);
    }

    function _useTypedNonce(address user, bytes32 typehash) internal returns (uint256 n) {
        if (DOMAIN_CHAIN_ID != block.chainid) {
            DOMAIN_CHAIN_ID = block.chainid;
            DOMAIN_SEPARATOR = _computeDomainSeparator(block.chainid);
        }
        n = noncesTyped[user][typehash];
        unchecked {
            noncesTyped[user][typehash] = n + 1;
        }
    }

    function useTypedNonce(address user, bytes32 typehash) external returns (uint256 n) {
        if (!metaModules[msg.sender]) revert ftPositionManagerOnlyEngine();
        n = _useTypedNonce(user, typehash);
    }

    event TypedNonceInvalidated(
        address indexed user, bytes32 indexed typehash, uint256 oldNonce, uint256 newNonce
    );

    /// @notice Invalidate pending signed operations for the caller by bumping the nonce for `typehash`.
    /// @dev `newNonce` must be strictly greater than the current nonce.
    function invalidateTypedNonce(bytes32 typehash, uint256 newNonce) external {
        uint256 oldNonce = noncesTyped[msg.sender][typehash];
        if (newNonce <= oldNonce) revert ftPositionManagerInvalidNonce();
        noncesTyped[msg.sender][typehash] = newNonce;
        emit TypedNonceInvalidated(msg.sender, typehash, oldNonce, newNonce);
    }

    // UUPS upgrade authorization
    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}

    /*//////////////////////////////////////////////////////////////
                           ADMIN CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    event CapsSet(address indexed asset, uint256 supplyCap, uint256 borrowCap);

    function setCaps(address asset, uint256 supplyCap_, uint256 borrowCap_) external onlyAdmin {
        supplyCap[asset] = supplyCap_;
        borrowCap[asset] = borrowCap_;
        emit CapsSet(asset, supplyCap_, borrowCap_);
    }

    function setAdmin(address _admin) external onlyAdmin {
        if (_admin == address(0)) revert ftPositionManagerZeroAdmin();
        emit AdminTransferred(admin, _admin);
        admin = _admin;
    }

    function setTokenizer(address asset, address tokenizer_) external onlyAdmin {
        if (asset == address(0)) revert ftPositionManagerZeroAddress();
        address prev = tokenizerForAsset[asset];
        tokenizerForAsset[asset] = tokenizer_;
        emit TokenizerSet(asset, prev, tokenizer_);
    }

    function setEngine(address m, bool ok) external onlyAdmin {
        if (m == address(0)) revert ftPositionManagerZeroAddress();
        engines[m] = ok;
        emit EngineSet(m, ok);
    }

    function initializeAsset(address asset) external onlyAdmin {
        if (address(valuesLens) == address(0)) revert ftPositionManagerLensZero();
        if (_assetInitialized[asset]) revert ftPositionManagerAlreadyInitialized();
        IConfigRegistry.AssetCfg memory c = config.getAssetCfg(asset);
        if (!c.enabled) revert ftPositionManagerNotInitialized();
        AssetState storage s = astate[asset];
        uint40 t = uint40(block.timestamp);
        s.lastAccrual = t;
        s.borrowIndexWad = WAD;
        // Genesis epoch 0
        epochs[asset][0] =
            EpochData({t_end: t, S_end: 0, rateRay: 0, X_end: 0, interest: 0, supplyTime: 0});
        s.epoch = 0;
        _assetInitialized[asset] = true;
    }

    /// @notice Engine-only hook to toggle the same transient reentrancy guard
    ///         used by PM's `nonReentrant` modifier. Intended for external
    ///         engines that perform flash-style callbacks (e.g., RFQ) so that
    ///         user-facing PM entrypoints cannot be reentered during the callback.
    function setEngineReentrancyLock(bool locked) external onlyEngine {
        // If PM is already inside a `nonReentrant` context, do not allow
        // external engines to override the guard state.
        if (locked) {
            if (_reentrancyGuardEntered()) {
                revert ReentrancyGuardReentrantCall();
            }
            _ENGINE_REENTRANCY_LOCK_OWNER_PM.asAddress().tstore(msg.sender);
            _REENTRANCY_GUARD_STORAGE_PM.asBoolean().tstore(true);
        } else {
            if (_ENGINE_REENTRANCY_LOCK_OWNER_PM.asAddress().tload() != msg.sender) {
                revert ftPositionManagerEngineReentrancyLockNotOwner();
            }
            _ENGINE_REENTRANCY_LOCK_OWNER_PM.asAddress().tstore(address(0));
            _REENTRANCY_GUARD_STORAGE_PM.asBoolean().tstore(false);
        }
    }

    function _approveBorrow(
        address user,
        address delegate,
        address asset,
        uint256 borrowAllowance_
    )
        internal
    {
        borrowAllowance[user][delegate][asset] = borrowAllowance_;
        emit BorrowDelegateApprovalSet(user, delegate, asset, borrowAllowance_);
    }

    function approveBorrow(
        address user,
        address delegate,
        address asset,
        uint256 borrowAllowance_
    )
        public
    {
        _requireSelfOrMetaModule(user);
        if (delegate == address(0) || asset == address(0)) revert ftPositionManagerZeroAddress();
        _approveBorrow(user, delegate, asset, borrowAllowance_);
    }

    function approveBorrow(address delegate, address asset, uint256 borrowAllowance_) external {
        approveBorrow(msg.sender, delegate, asset, borrowAllowance_);
    }

    function _approveEngine(
        address user,
        address engine,
        address asset,
        uint256 debitAllowance
    )
        internal
    {
        engineDebitAllowance[user][engine][asset] = debitAllowance;
        emit EngineApprovalSet(user, engine, asset, debitAllowance);
    }

    function approveEngine(
        address user,
        address engine,
        address asset,
        uint256 debitAllowance
    )
        public
    {
        _requireSelfOrMetaModule(user);
        if (engine == address(0) || asset == address(0)) revert ftPositionManagerZeroAddress();
        _approveEngine(user, engine, asset, debitAllowance);
    }

    function approveEngine(address engine, address asset, uint256 debitAllowance) external {
        approveEngine(msg.sender, engine, asset, debitAllowance);
    }

    /* ===================== Account Modes ===================== */
    function _accrue(address asset) internal {
        AssetState storage s = astate[asset];
        uint40 t = uint40(block.timestamp);
        if (t == s.lastAccrual) return;
        if (_assetInitialized[asset] == false) revert ftPositionManagerNotInitialized();

        uint40 dt = t - s.lastAccrual;
        // Always accrue supply-time, independent of whether there are active borrows.
        // This is required for correct epoch reward distribution which is time-based.
        s.totalSuppliedTime += s.totalSupplied * dt;

        // Short-circuit if no outstanding borrows: skip IRM call and math
        if (s.borrows == 0) {
            s.lastAccrual = t;
            emit Accrue(asset, s.borrowIndexWad);
            return;
        }

        uint256 denom = s.cash + s.borrows;
        if (denom == 0) {
            s.lastAccrual = t;
            emit Accrue(asset, s.borrowIndexWad);
            return;
        }

        // Utilization and borrow APR
        IConfigRegistry.AssetCfg memory c = config.getAssetCfg(asset);
        uint256 utilWad = Math.mulDiv(s.borrows, WAD, denom);
        uint256 aprWad = IIRM(c.irm).borrowAPR(asset, utilWad);

        // Borrow index factor
        uint256 interestWad = Math.mulDiv(aprWad, dt, 365 days);
        uint256 bFactorWad = WAD + interestWad;

        // Debt is share-based, so global borrows can grow directly by the realized interest without
        // needing a per-borrower floor-matching recast through the borrow index ratio.
        uint256 interestUnits = Math.mulDiv(s.borrows, interestWad, WAD, Math.Rounding.Ceil);
        s.borrowIndexWad = Math.mulDiv(s.borrowIndexWad, bFactorWad, WAD);
        s.borrows += interestUnits;
        s.reserves += interestUnits;
        s.lastAccrual = t;
        emit Accrue(asset, s.borrowIndexWad);
    }

    /// @dev Fetches account values and computes HF in basis points.
    function _accountHfBps(address user)
        internal
        view
        returns (uint256 equityUSDWad, uint256 collUSDWad, uint16 hfBps)
    {
        AccountSnapshot memory s = valuesLens.accountValues(address(this), user);
        equityUSDWad = s.equityUSDWad;
        collUSDWad = s.collUSDWad; // raw; does not include engine PnL
        hfBps = RiskLib.hfBps(s.equityUSDWad, s.maintUSDWad);
    }

    /// @dev Enforces the "safe" HF threshold used for user-facing actions (borrow/withdraw/etc).
    function _enforceHFInvariant(address user) internal view {
        (uint256 equityUSDWad,, uint16 hfBps) = _accountHfBps(user);
        if (hfBps < config.marginHfSafeBps()) {
            revert ftPositionManagerHealthFactor();
        }
        uint256 minEquity = config.marginMinEquityUSDWad();
        // Only enforce a minimum margin for accounts that have actual borrows outstanding.
        if (minEquity != 0 && _userDebtAssets[user].length != 0 && equityUSDWad < minEquity) {
            revert ftPositionManagerMinEquity();
        }
    }

    function _syncSupplyPosition(address user, address asset) internal {
        _settleUser(user, asset);
        _accrueOpenSupplyTime(user, asset);
    }

    function _depositIntoWrapper(address asset, address wrapper, uint256 amount) internal {
        IERC20 token = IERC20(asset);
        token.forceApprove(wrapper, amount);
        IftYieldWrapper(wrapper).deposit(amount);
        token.forceApprove(wrapper, 0);
    }

    function _withdrawFromWrapper(address wrapper, uint256 amount, address to) internal {
        IftYieldWrapper(wrapper).withdraw(amount, to);
    }

    /// @dev Shares the external struct decoder for paths that only need the configured wrapper.
    function _yieldWrapper(address asset) internal view returns (address) {
        return config.getAssetCfg(asset).ftYieldWrapper;
    }

    /* ===================== User flows ===================== */

    function _depositFrom(
        address from,
        address beneficiary,
        address asset,
        uint256 amt
    )
        internal
        returns (uint256 received)
    {
        // 1) bring interest up-to-date under pre-action util
        _accrue(asset);
        _syncSupplyPosition(beneficiary, asset);

        IConfigRegistry.AssetCfg memory c = config.getAssetCfg(asset);
        if (!c.enabled) revert ftPositionManagerAssetDisabled();
        if (depositPaused[asset]) revert ftPositionManagerDepositPaused();

        // Pull funds and deposit into the wrapper.
        IERC20(asset).safeTransferFrom(from, address(this), amt);
        address wrapper = c.ftYieldWrapper;
        _depositIntoWrapper(asset, wrapper, amt);

        // supply cap check
        AssetState storage s = astate[asset];
        uint256 newTotalSupplyUnits = (s.cash + s.borrows) + amt;
        uint256 cap = supplyCap[asset];
        if (cap != 0 && newTotalSupplyUnits > cap) revert ftPositionManagerSupplyCap();

        // Credit beneficiary
        collateral[beneficiary][asset].avail += amt;
        s.cash += amt;
        s.totalSupplied += amt;
        _touchCollAsset(beneficiary, asset);

        // Emit appropriate event
        if (from == beneficiary) {
            emit Deposit(beneficiary, asset, amt);
        } else {
            emit DepositFor(from, beneficiary, asset, amt);
        }
        return amt;
    }

    function _emitDepositReferral(
        address beneficiary,
        address integrator,
        address asset,
        uint256 amount
    )
        internal
    {
        if (integrator != address(0)) {
            emit DepositReferred(beneficiary, integrator, asset, amount);
        }
    }

    function deposit(address asset, uint256 amt) external nonReentrant {
        _depositFrom(msg.sender, msg.sender, asset, amt);
        _emitDepositReferral(msg.sender, address(0), asset, amt);
    }

    /// @notice Deposit collateral with optional integrator attribution.
    /// @dev A zero integrator emits no referral event. Attribution grants no rights.
    function deposit(address asset, uint256 amt, address integrator) external nonReentrant {
        _depositFrom(msg.sender, msg.sender, asset, amt);
        _emitDepositReferral(msg.sender, integrator, asset, amt);
    }

    /// @notice Permissionlessly checkpoint a user supply-time and realize settled FT rewards.
    /// @dev This changes no principal and remains available while deposits or withdrawals are paused.
    function checkpointSupply(address user, address asset) external nonReentrant {
        _accrue(asset);
        _syncSupplyPosition(user, asset);
    }

    /// @notice Permissionlessly checkpoint every currently active supply source for a user.
    /// @dev The entry length is cached because settlement can append FT to the active set. Initial
    ///      sources cannot be removed by this path, and FT is synchronized before reward credit.
    ///      Inactive historical sources still require a known-source checkpoint.
    function checkpointSupplyAll(address user) external nonReentrant {
        address[] storage assets = _userCollAssets[user];
        uint256 length = assets.length;
        for (uint256 i; i < length; ++i) {
            address asset = assets[i];
            _accrue(asset);
            _syncSupplyPosition(user, asset);
        }
    }

    function depositFor(address beneficiary, address asset, uint256 amount) external nonReentrant {
        _depositFor(beneficiary, asset, amount);
        _emitDepositReferral(beneficiary, address(0), asset, amount);
    }

    /// @notice Deposit for a beneficiary with optional integrator attribution.
    /// @dev The referral event attributes the credited beneficiary, while `DepositFor` identifies
    ///      the payer. A zero integrator emits no referral event.
    function depositFor(
        address beneficiary,
        address asset,
        uint256 amount,
        address integrator
    )
        external
        nonReentrant
    {
        _depositFor(beneficiary, asset, amount);
        _emitDepositReferral(beneficiary, integrator, asset, amount);
    }

    function _depositFor(address beneficiary, address asset, uint256 amount) internal {
        if (amount == 0) revert ftPositionManagerAmountZero();
        if (beneficiary == address(0)) revert ftPositionManagerZeroAddress();
        if (
            beneficiary != msg.sender && !metaModules[msg.sender]
                && _collIx[beneficiary][asset] == 0
        ) {
            revert ftPositionManagerThirdPartyNewCollateralAsset();
        }
        _depositFrom(msg.sender, beneficiary, asset, amount);
    }

    function _flashBalanceDelta(
        IERC20 token,
        bytes calldata callbackData
    )
        internal
        returns (uint256 balBefore, uint256 delta)
    {
        balBefore = token.balanceOf(msg.sender);
        ILeverageFlashCallback(msg.sender).onLeverageFlash(callbackData);
        uint256 balAfter = token.balanceOf(msg.sender);
        delta = balAfter > balBefore ? (balAfter - balBefore) : 0;
    }

    function _withdrawTo(
        address user,
        address asset,
        uint256 amt,
        address to,
        bool isLiquidation
    )
        internal
    {
        if (to == address(0)) revert ftPositionManagerZeroAddress();
        // 1) accrue first so HF check uses fresh debt/indices & pre-action util
        _accrue(asset);
        _syncSupplyPosition(user, asset);

        if (!isLiquidation && withdrawPaused[asset]) {
            revert ftPositionManagerWithdrawPaused();
        }
        // Ensure sufficient liquidity in the cash bucket
        AssetState storage s = astate[asset];
        if (s.cash < amt) revert ftPositionManagerInsufficientLiquidity();

        collateral[user][asset].avail -= amt;
        s.cash -= amt;
        s.totalSupplied -= amt;
        address wrapper = _yieldWrapper(asset);
        if (isLiquidation) {
            IftYieldWrapper(wrapper).withdrawBypassCB(amt, to);
        } else {
            _withdrawFromWrapper(wrapper, amt, to);
        }

        _touchCollAsset(user, asset);
        emit Withdraw(user, asset, amt);
    }

    function withdraw(
        address user,
        address asset,
        uint256 amt,
        address to
    )
        public
        nonReentrant
        enforcePostHF(user)
    {
        _requireSelfOrMetaModule(user);
        if (amt == 0) revert ftPositionManagerAmountZero();
        _withdrawTo(user, asset, amt, to, false);
    }

    function withdraw(address asset, uint256 amt) external {
        if (!_reentrancyGuardEntered()) {
            withdraw(msg.sender, asset, amt, msg.sender);
            return;
        }
        if (_ENGINE_REENTRANCY_LOCK_OWNER_PM.asAddress().tload() != address(0)) {
            revert ReentrancyGuardReentrantCall();
        }
        if (!config.dnmmStrategies(msg.sender)) revert ftPositionManagerOnlyEngine();
        if (amt == 0) revert ftPositionManagerAmountZero();
        _withdrawTo(msg.sender, asset, amt, msg.sender, false);
        _enforceHFInvariant(msg.sender);
    }

    /// @notice Flash-style withdraw flow: withdraw collateral to the caller, execute callback, then repay
    ///         debt using tokens received by the caller and optionally deposit leftover repay tokens.
    /// @dev Repays and deposits are executed within this call so `enforcePostHF` observes the final state.
    function withdrawFlashAndRepayFor(
        address user,
        address collateralAsset,
        uint256 collateralAmount,
        address repayAsset,
        uint256 minRepayAmount,
        bytes calldata callbackData
    )
        external
        onlyEngine
        nonReentrant
        enforcePostHF(user)
    {
        _consumeEngineDebitAllowance(user, collateralAsset, collateralAmount);

        _withdrawTo(user, collateralAsset, collateralAmount, msg.sender, false);

        IERC20 repayToken = IERC20(repayAsset);
        (uint256 repayBalBefore, uint256 delta) = _flashBalanceDelta(repayToken, callbackData);

        uint256 used = 0;
        if (delta != 0) {
            used = _repay(msg.sender, user, repayAsset, delta);
        }
        if (used < minRepayAmount) revert ftPositionManagerRepayTooLow();

        // Deposit any remaining repayAsset (beyond what was pulled for repay) as collateral.
        uint256 repayBalFinal = repayToken.balanceOf(msg.sender);
        uint256 leftover = repayBalFinal > repayBalBefore ? (repayBalFinal - repayBalBefore) : 0;
        if (leftover != 0) {
            _depositFrom(msg.sender, user, repayAsset, leftover);
        }
    }

    /// @notice Flash-style collateral rebalance: withdraw collateral to the caller, execute callback,
    ///         then deposit received tokens as collateral for `user`.
    /// @dev The deposit is executed within this call so `enforcePostHF` observes the final state.
    function withdrawFlashAndDepositFor(
        address user,
        address collateralAsset,
        uint256 collateralAmount,
        address depositAsset,
        uint256 minDepositAmount,
        bytes calldata callbackData
    )
        external
        onlyEngine
        nonReentrant
        enforcePostHF(user)
    {
        _consumeEngineDebitAllowance(user, collateralAsset, collateralAmount);

        _withdrawTo(user, collateralAsset, collateralAmount, msg.sender, false);

        IERC20 depToken = IERC20(depositAsset);
        (, uint256 delta) = _flashBalanceDelta(depToken, callbackData);

        uint256 credited = 0;
        if (delta != 0) {
            credited = _depositFrom(msg.sender, user, depositAsset, delta);
        }
        // Use actual deposited amount (excludes settlement side-effects like FT realization).
        if (credited < minDepositAmount) revert ftPositionManagerDepositTooLow();
    }

    /// @notice Liquidation-module flash flow: seize collateral (withdraw to module), run callback,
    ///         then repay and enforce target HF.
    /// @dev The liquidation module must:
    ///      - implement `ILiquidationFlashCallback.onLiquidationFlash(bytes)` (called with `callbackData`),
    ///      - during the callback, acquire repayment funds and approve PM to pull them from the module.
    function liquidateFlash(
        address user,
        address seizeTo,
        address[] calldata seizeAssets,
        uint256[] calldata seizeAmounts,
        address[] calldata repayAssets,
        uint256[] calldata repayAmounts,
        bytes calldata callbackData
    )
        external
        nonReentrant
        returns (uint256[] memory repayUsed)
    {
        if (!liquidationModules[msg.sender]) {
            revert ftPositionManagerOnlyEngine();
        }
        if (seizeTo == address(0)) revert ftPositionManagerZeroAddress();

        // Pre-check: account must be below target HF to be eligible for liquidation.
        // Capture pre-state equity for the post-action insolvency exception check.
        (uint256 equityUSDPre,, uint16 hfPre) = _accountHfBps(user);
        if (hfPre >= config.marginHfTargetBps()) {
            revert ftPositionManagerHealthFactorNotBelowTarget();
        }

        uint256 seizeLen = seizeAssets.length;
        uint256 repayLen = repayAssets.length;
        // 1) Seize collateral: withdraw underlying from user's `avail` to the liquidation module.
        for (uint256 i = 0; i < seizeLen; ++i) {
            uint256 amt = seizeAmounts[i];
            if (amt == 0) revert ftPositionManagerAmountZero();
            _withdrawTo(user, seizeAssets[i], amt, seizeTo, true);
        }
        // 2) Callback: module can trade seized collateral and source repayment funds.
        ILiquidationFlashCallback(msg.sender).onLiquidationFlash(callbackData);
        // 3) Repay debts: pull funds from the liquidation module and book repayment to `user`.
        repayUsed = new uint256[](repayLen);
        for (uint256 j = 0; j < repayLen; ++j) {
            uint256 amt = repayAmounts[j];
            if (amt == 0) revert ftPositionManagerAmountZero();
            address asset = repayAssets[j];
            // Skip assets with no recorded debt shares to avoid unnecessary pulls/reverts.
            if (debtShares[user][asset] == 0) {
                continue;
            }
            // Cap repayment to what the module actually made available to PM (balance + allowance),
            // so the module can approve an upper bound and avoid unnecessary pulls/reverts.
            uint256 cap = amt;
            uint256 allowance = IERC20(asset).allowance(msg.sender, address(this));
            if (allowance < cap) cap = allowance;
            uint256 bal = IERC20(asset).balanceOf(msg.sender);
            if (bal < cap) cap = bal;
            if (cap != 0) {
                repayUsed[j] = _repay(msg.sender, user, asset, cap);
            }
        }
        // 4) Post-check: enforce target HF with insolvency exception.
        (, uint256 collUSDWadPost, uint16 hfPost) = _accountHfBps(user);
        if (hfPost < config.marginHfTargetBps()) {
            // Insolvency exception: account was already insolvent (equity == 0) before
            // the liquidation AND all seizable collateral (excluding engine PnL) has been exhausted
            // (terminal condition). Non-collateral assets and engine PnL should not block
            // bad-debt cleanup. Blocking this would leave bad debt unresolved.
            if (equityUSDPre == 0 && collUSDWadPost == 0) {
                // Insolvency exception: bad-debt path handled by engine.
            } else {
                revert ftPositionManagerHealthFactorBelowTarget();
            }
        }
    }

    function _borrowTo(address user, address asset, uint256 amt, address to) internal {
        if (to == address(0)) revert ftPositionManagerZeroAddress();
        IConfigRegistry.AssetCfg memory c = config.getAssetCfg(asset);
        if (!c.enabled) revert ftPositionManagerAssetDisabled();
        if (!c.borrowable) revert ftPositionManagerAssetNotBorrowable();
        if (c.mmBps == 0) revert ftPositionManagerBorrowRequiresMM();
        // Borrowing requires a valid IRM (used for accrual and risk previews once borrows > 0).
        if (c.irm == address(0)) revert ftPositionManagerAssetNotConfigured();
        if (borrowPaused[asset]) revert ftPositionManagerBorrowPaused();

        _accrue(asset);

        AssetState storage s = astate[asset];
        if (s.cash < amt) revert ftPositionManagerInsufficientLiquidity();

        // enforce borrow cap
        uint256 newBorrows = s.borrows + amt;
        uint256 bcap = borrowCap[asset];
        if (bcap != 0 && newBorrows > bcap) revert ftPositionManagerBorrowCap();

        uint256 sharesOut = _sharesForBorrow(asset, amt);
        debtShares[user][asset] += sharesOut;
        totalDebtShares[asset] += sharesOut;

        s.borrows += amt;
        s.cash -= amt;
        _touchDebtAsset(user, asset);
        _withdrawFromWrapper(c.ftYieldWrapper, amt, to);
        emit Borrow(user, asset, amt);
    }

    function borrow(
        address user,
        address asset,
        uint256 amt,
        address to
    )
        public
        nonReentrant
        enforcePostHF(user)
    {
        _requireSelfOrMetaModule(user);
        if (amt == 0) revert ftPositionManagerAmountZero();
        _borrowTo(user, asset, amt, to);
    }

    function borrow(address asset, uint256 amt) external {
        borrow(msg.sender, asset, amt, msg.sender);
    }

    /// @notice Flash-style borrow flow: borrow to the caller, execute callback, then deposit received
    ///         collateral from the caller as collateral for `user`.
    /// @dev The deposit is executed within this call so `enforcePostHF` observes the final state.
    function borrowFlashAndDepositFor(
        address user,
        address borrowAsset,
        uint256 borrowAmount,
        address collateralAsset,
        uint256 minCollateralAmount,
        bytes calldata callbackData
    )
        external
        onlyEngine
        nonReentrant
        enforcePostHF(user)
    {
        _consumeBorrowAllowance(user, borrowAsset, borrowAmount);
        _borrowTo(user, borrowAsset, borrowAmount, msg.sender);

        IERC20 collToken = IERC20(collateralAsset);
        (, uint256 delta) = _flashBalanceDelta(collToken, callbackData);

        uint256 credited = 0;
        if (delta != 0) {
            credited = _depositFrom(msg.sender, user, collateralAsset, delta);
        }
        // Use actual deposited amount (excludes settlement side-effects like FT realization).
        if (credited < minCollateralAmount) revert ftPositionManagerDepositTooLow();
    }

    function _repay(
        address from,
        address user,
        address asset,
        uint256 amt
    )
        internal
        returns (uint256 used)
    {
        _accrue(asset);

        uint256 userShares = debtShares[user][asset];
        if (userShares == 0) revert ftPositionManagerNoDebt();

        AssetState storage s = astate[asset];
        uint256 assetTotalShares = totalDebtShares[asset];
        uint256 borrows = s.borrows;
        if (borrows == 0 || assetTotalShares == 0 || userShares > assetTotalShares) {
            revert ftPositionManagerDebtShareInvariant();
        }
        uint256 fullDebt = Math.mulDiv(userShares, borrows, assetTotalShares, Math.Rounding.Ceil);

        uint256 sharesToBurn;
        if (amt >= fullDebt) {
            sharesToBurn = userShares;
        } else {
            sharesToBurn = Math.mulDiv(amt, assetTotalShares, borrows);
            if (sharesToBurn == 0) revert ftPositionManagerRepayTooLow();
        }

        // Repayment is share-centric: retire only the floor book value of the burned shares,
        // while charging their ceiling value. The at-most-one-unit surplus is protocol revenue.
        uint256 debtReduction = Math.mulDiv(sharesToBurn, borrows, assetTotalShares);
        used = Math.mulDiv(sharesToBurn, borrows, assetTotalShares, Math.Rounding.Ceil);

        uint256 remainingBorrows = borrows - debtReduction;
        uint256 remainingShares = assetTotalShares - sharesToBurn;
        if ((remainingBorrows == 0) != (remainingShares == 0)) {
            revert ftPositionManagerDebtShareInvariant();
        }

        IERC20(asset).safeTransferFrom(from, address(this), used);
        _depositIntoWrapper(asset, _yieldWrapper(asset), used);

        debtShares[user][asset] = userShares - sharesToBurn;
        totalDebtShares[asset] = remainingShares;

        s.borrows = remainingBorrows;
        s.cash += used;
        s.reserves += used - debtReduction;

        bool full = (debtShares[user][asset] == 0);
        _touchDebtAsset(user, asset);

        // Emit appropriate event
        if (from == user) {
            emit Repay(user, asset, used, full);
        } else {
            emit RepayFor(from, user, asset, used, full);
        }

        return used;
    }

    function repay(address asset, uint256 amt) external nonReentrant {
        _repay(msg.sender, msg.sender, asset, amt);
    }

    function repayFor(address borrower, address asset, uint256 amount) external nonReentrant {
        if (borrower == address(0)) revert ftPositionManagerZeroAddress();
        _repay(msg.sender, borrower, asset, amount);
    }

    /* ===================== Account valuation ===================== */

    // admin can withdraw accrued reserves (protocol profit) when liquid
    function withdrawReserves(
        address asset,
        address to,
        uint256 amount
    )
        external
        onlyAdmin
        nonReentrant
    {
        if (amount == 0) revert ftPositionManagerAmountZero();
        _accrue(asset); // keep economics consistent
        AssetState storage s = astate[asset];
        if (amount > s.reserves) revert ftPositionManagerInsufficientReserves();
        if (s.cash < amount) revert ftPositionManagerInsufficientCash();

        // Effects
        s.reserves -= amount;
        s.cash -= amount;

        // Interactions
        _withdrawFromWrapper(_yieldWrapper(asset), amount, to);
    }

    /// @notice Reconcile `s.cash` to on-chain token balance for donated or direct-transferred tokens.
    ///         Credits to reserves (can be distributed via FT).
    function skim(address asset) external onlyAdmin nonReentrant {
        _accrue(asset);
        AssetState storage s = astate[asset];
        address wrapper = _yieldWrapper(asset);
        uint256 underlyingBal = IERC20(asset).balanceOf(address(this));
        if (underlyingBal != 0) {
            _depositIntoWrapper(asset, wrapper, underlyingBal);
        }
        uint256 shares = IftYieldWrapper(wrapper).balanceOf(address(this));
        if (shares <= s.cash) return;
        uint256 deltaShares = shares - s.cash;
        s.cash = shares;
        s.reserves += deltaShares;
        emit Skimmed(asset, deltaShares, s.cash);
    }

    /// @notice View your global balance for a token.
    function getBalance(
        address user,
        address token
    )
        external
        view
        returns (uint256 avail, uint256 holdBal)
    {
        Position storage p = collateral[user][token];
        return (p.avail, p.hold);
    }

    /* ===================== Views ===================== */

    function userCollateralAssets(address user) external view returns (address[] memory) {
        return _userCollAssets[user];
    }

    function userDebtAssets(address user) external view returns (address[] memory) {
        return _userDebtAssets[user];
    }

    function _hold(address user, address token, uint128 amt) internal {
        if (user != msg.sender) {
            _consumeEngineDebitAllowance(user, token, amt);
        }
        _accrue(token);
        _syncSupplyPosition(user, token);
        Position storage p = collateral[user][token];
        p.avail -= amt; // underflow-safe (revert) if insufficient
        p.hold += amt;
        engineHeld[user][msg.sender][token] += amt;
        _touchCollAsset(user, token);
        emit HoldReserved(user, token, amt);
    }

    function _releaseHoldToAvail(address user, address token, uint128 amt) internal {
        _accrue(token);
        _syncSupplyPosition(user, token);
        uint256 eHeld = engineHeld[user][msg.sender][token];
        if (eHeld < amt) revert ftPositionManagerInsufficientEngineHeld();
        unchecked {
            engineHeld[user][msg.sender][token] = eHeld - amt;
        }
        Position storage b = collateral[user][token];
        b.hold -= amt;
        b.avail += amt;
        _touchCollAsset(user, token);
        emit HoldReleasedToAvail(user, token, amt);
    }

    /// @notice Engine-only atomic transfer: move `amt` from `from` avail to `to` avail.
    /// @dev Enforces per-user engine allowances and does not change `totalSupplied`.
    function engineTransferAvail(
        address from,
        address to,
        address asset,
        uint128 amt
    )
        external
        onlyEngine
        nonReentrant
        enforcePostHF(from)
    {
        // Debit allowance (from)
        _consumeTransferAllowance(from, asset, amt);
        _engineTransferAvail(from, to, asset, amt);
    }

    function _engineTransferAvail(address from, address to, address asset, uint128 amt) internal {
        if (from == address(0) || to == address(0)) revert ftPositionManagerZeroAddress();
        if (from == to) revert ftPositionManagerSelfTransfer();
        if (amt == 0) revert ftPositionManagerAmountZero();

        _accrue(asset);
        _syncSupplyPosition(from, asset);
        _syncSupplyPosition(to, asset);

        collateral[from][asset].avail -= amt;
        collateral[to][asset].avail += amt;
        _touchCollAsset(from, asset);
        _touchCollAsset(to, asset);
        emit EngineTransferAvail(msg.sender, from, to, asset, amt);
    }

    /// @notice Engine-only atomic settlement: move `amt` from `from` hold to `to` avail.
    /// @dev Requires that `amt` was previously held by this engine via `hold()`.
    function _engineTransferHoldToAvail(
        address from,
        address to,
        address asset,
        uint128 amt
    )
        internal
    {
        if (from == address(0) || to == address(0)) revert ftPositionManagerZeroAddress();
        if (from == to) revert ftPositionManagerSelfTransfer();
        if (amt == 0) revert ftPositionManagerAmountZero();

        _accrue(asset);
        _syncSupplyPosition(from, asset);
        _syncSupplyPosition(to, asset);

        uint256 eHeld = engineHeld[from][msg.sender][asset];
        if (eHeld < amt) revert ftPositionManagerInsufficientEngineHeld();
        unchecked {
            engineHeld[from][msg.sender][asset] = eHeld - amt;
        }
        collateral[from][asset].hold -= amt;
        collateral[to][asset].avail += amt;
        _touchCollAsset(from, asset);
        _touchCollAsset(to, asset);
        emit EngineTransferHoldToAvail(msg.sender, from, to, asset, amt);
    }

    /// @notice Engine-only batch settlement with a single post-HF check per debited user.
    /// @dev This allows engines to net multi-leg settlements atomically without intermediate HF reverts.
    function engineBatch(EngineAction[] calldata actions) external onlyEngine nonReentrant {
        uint256 n = actions.length;
        address[] memory hfUsers = new address[](n);
        uint256 hfLen = 0;

        for (uint256 i = 0; i < n; ++i) {
            EngineAction calldata a = actions[i];

            if (a.kind == EngineActionKind.HOLD) {
                _hold(a.from, a.asset, a.amount);
                hfUsers[hfLen++] = a.from;
            } else if (a.kind == EngineActionKind.RELEASE_HOLD_TO_AVAIL) {
                _releaseHoldToAvail(a.from, a.asset, a.amount);
            } else if (a.kind == EngineActionKind.TRANSFER_AVAIL) {
                _consumeTransferAllowance(a.from, a.asset, a.amount);
                _engineTransferAvail(a.from, a.to, a.asset, a.amount);
                hfUsers[hfLen++] = a.from;
            } else if (a.kind == EngineActionKind.TRANSFER_HOLD_TO_AVAIL) {
                _engineTransferHoldToAvail(a.from, a.to, a.asset, a.amount);
            } else if (a.kind == EngineActionKind.TRANSFER_DEBT_SHARES) {
                _accrue(a.asset);
                debtShares[a.from][a.asset] -= a.amount;
                unchecked {
                    debtShares[a.to][a.asset] += a.amount;
                }
                _touchDebtAsset(a.from, a.asset);
                _touchDebtAsset(a.to, a.asset);
                hfUsers[hfLen++] = a.to;
            } else if (a.kind == EngineActionKind.BORROW_TO_ENGINE) {
                _consumeBorrowAllowance(a.from, a.asset, a.amount);
                _borrowTo(a.from, a.asset, a.amount, msg.sender);
                _emitEngineBatchAction(a.kind, a.from);
                hfUsers[hfLen++] = a.from;
            } else if (a.kind == EngineActionKind.DEPOSIT_FROM_ENGINE) {
                _depositFrom(msg.sender, a.to, a.asset, a.amount);
                _emitEngineBatchAction(a.kind, a.to);
            } else {
                revert ftPositionManagerOnlyEngine();
            }
        }

        for (uint256 j = 0; j < hfLen; ++j) {
            _enforceHFInvariant(hfUsers[j]);
        }
    }

    function _emitEngineBatchAction(EngineActionKind kind, address user) internal {
        emit EngineBatchAction(uint8(kind), user);
    }

    /// @notice Close the current open epoch and distribute `interest` FT across supply-time in that epoch.
    /// @dev Pulls FT from msg.sender.
    ///      If interest > 0 and there was no supply-time, reverts to avoid locking FT.
    function settleEpoch(address asset, uint256 interest) external onlyAdmin nonReentrant {
        if (interest == 0) revert ftPositionManagerAmountZero();

        _accrue(asset);
        _accrue(FT);
        AssetState storage s = astate[asset];

        EpochData storage prev = epochs[asset][s.epoch];
        uint40 nowTs = uint40(block.timestamp);

        uint256 supplyTimeEpoch = s.totalSuppliedTime - prev.S_end; // ASSET*sec
        if (supplyTimeEpoch == 0) revert ftPositionManagerNoSupplierInterest();
        IERC20(FT).safeTransferFrom(msg.sender, address(this), interest);
        address wrapper = _yieldWrapper(FT);
        _depositIntoWrapper(FT, wrapper, interest);
        astate[FT].cash += interest;

        uint256 rateRay = Math.mulDiv(interest, RAY, supplyTimeEpoch);
        if (rateRay == 0) revert ftPositionManagerAmountZero();
        uint256 duration = uint256(nowTs - prev.t_end);
        // X_end = X_prev + duration * rateRay
        uint256 X_end = prev.X_end + (duration * rateRay);

        uint32 newEpoch = s.epoch + 1;
        epochs[asset][newEpoch] = EpochData({
            t_end: nowTs,
            S_end: s.totalSuppliedTime,
            rateRay: rateRay,
            X_end: X_end,
            interest: interest,
            supplyTime: supplyTimeEpoch
        });

        s.epoch = newEpoch;

        emit EpochSettled(newEpoch, interest, supplyTimeEpoch, rateRay);
    }

    /// @dev Settle user across all newly settled epochs in O(1) (no loops).
    function _settleUser(address user, address asset) internal {
        AssetState storage s = astate[asset];
        Position storage p = collateral[user][asset];
        uint256 principal = p.avail + p.hold;

        uint32 curr = s.epoch;
        uint32 userSettled = p.lastSettledEpoch;
        if (curr == userSettled) return;

        // Epoch that was open when the user last checkpointed
        uint32 openEpoch = userSettled + 1;
        uint256 rateRay = epochs[asset][openEpoch].rateRay;
        uint256 _ft = 0;

        // Convert banked stake-time from that open epoch
        if (p.openSupplyTime != 0) {
            if (rateRay != 0) {
                _ft = Math.mulDiv(p.openSupplyTime, rateRay, RAY);
            }
            p.openSupplyTime = 0;
        }

        // Clamp lastT for safety (e.g. users who never interacted)
        uint40 baseT = epochs[asset][userSettled].t_end;
        uint40 userLastT = p.lastT;
        if (userLastT < baseT) userLastT = baseT;

        uint40 openEndT = epochs[asset][openEpoch].t_end;
        if (userLastT > openEndT) userLastT = openEndT;

        // X(lastT) = X_end[userSettled] + (lastT - t_end[userSettled]) * rate(openEpoch)
        uint256 X_at_lastT =
            epochs[asset][userSettled].X_end + (uint256(userLastT - baseT) * rateRay);
        uint256 X_now = epochs[asset][curr].X_end;

        if (principal > 0 && X_now > X_at_lastT) {
            _ft += Math.mulDiv(principal, X_now - X_at_lastT, RAY);
        }

        // Move checkpoint to start of current open epoch
        p.lastSettledEpoch = curr;
        p.lastT = epochs[asset][curr].t_end;

        if (_ft > 0) {
            address ft = FT;

            // Ensure the user's FT reward settlement checkpoint is up-to-date before increasing
            // their FT principal. This prevents retroactive accrual on the FT asset itself when
            // a user first receives FT via rewards from another asset.
            if (asset != ft) {
                _settleUser(user, ft);
            }

            // Accrue FT global supply-time at the pre-mint supply to ensure correct FT-epoch
            // accounting when FT is itself an epoch-settled asset.
            _accrue(ft);

            // Hard safety cap: never credit more FT than is currently unallocated in-system.
            // Underpaying is acceptable; overpaying (phantom FT) is not.
            AssetState storage sFT = astate[ft];
            // `reserves` are already accounted for within cash/borrows; do not double-count them.
            uint256 backing = sFT.cash + sFT.borrows;
            uint256 allocated = sFT.totalSupplied;
            uint256 unallocated = backing > allocated ? backing - allocated : 0;
            if (_ft > unallocated) _ft = unallocated;

            if (_ft > 0) {
                _accrueOpenSupplyTime(user, ft);
                collateral[user][ft].avail += _ft;
                sFT.totalSupplied += _ft;
                _touchCollAsset(user, ft);
            }
        }
    }

    function _touchCollAsset(address user, address asset) internal {
        Position storage p = collateral[user][asset];
        bool active = (p.avail + p.hold) > 0;
        uint256 ix = _collIx[user][asset];

        if (active && ix == 0) {
            _userCollAssets[user].push(asset);
            _collIx[user][asset] = _userCollAssets[user].length; // 1-based
        } else if (!active && ix != 0) {
            uint256 arrIx = ix - 1;
            address[] storage arr = _userCollAssets[user];
            uint256 last = arr.length - 1;
            if (arrIx != last) {
                address moved = arr[last];
                arr[arrIx] = moved;
                _collIx[user][moved] = arrIx + 1;
            }
            arr.pop();
            _collIx[user][asset] = 0;
        }
    }

    function _touchDebtAsset(address user, address asset) internal {
        bool active = (debtShares[user][asset] > 0);
        uint256 ix = _debtIx[user][asset];
        if (active && ix == 0) {
            _userDebtAssets[user].push(asset);
            _debtIx[user][asset] = _userDebtAssets[user].length; // 1-based
        } else if (!active && ix != 0) {
            uint256 arrIx = ix - 1;
            address[] storage arr = _userDebtAssets[user];
            uint256 last = arr.length - 1;
            if (arrIx != last) {
                address moved = arr[last];
                arr[arrIx] = moved;
                _debtIx[user][moved] = arrIx + 1;
            }
            arr.pop();
            _debtIx[user][asset] = 0;
        }
    }

    function _consumeBorrowAllowance(address user, address asset, uint256 amount) internal {
        uint256 allowance = borrowAllowance[user][msg.sender][asset];
        if (allowance < amount) revert ftPositionManagerInsufficientBorrowAllowance();
        unchecked {
            borrowAllowance[user][msg.sender][asset] = allowance - amount;
        }
    }

    function _sharesForBorrow(address asset, uint256 amt)
        internal
        view
        returns (uint256 sharesOut)
    {
        uint256 assetTotalShares = totalDebtShares[asset];
        uint256 borrows = astate[asset].borrows;
        if (borrows == 0) {
            if (assetTotalShares != 0) revert ftPositionManagerDebtShareInvariant();
            return amt * DEBT_SHARE_SCALE;
        }
        if (assetTotalShares == 0) revert ftPositionManagerDebtShareInvariant();
        return Math.mulDiv(amt, assetTotalShares, borrows, Math.Rounding.Ceil);
    }

    /// @dev Bank supply-time inside the current open epoch before changing supply.
    function _accrueOpenSupplyTime(address user, address asset) internal {
        Position storage p = collateral[user][asset];
        uint256 principal = p.avail + p.hold;

        uint40 nowTs = uint40(block.timestamp);
        uint40 lastT = p.lastT;

        // If first interaction, just initialize lastT
        if (lastT == 0) {
            p.lastT = nowTs;
            return;
        }

        if (nowTs > lastT && principal > 0) {
            uint256 dt = uint256(nowTs - lastT);
            p.openSupplyTime += principal * dt; // asset*sec
        }

        p.lastT = nowTs;
    }
}
