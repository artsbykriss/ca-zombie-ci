// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {Governed} from "../access/Governed.sol";
import {ProtocolConfig} from "../config/ProtocolConfig.sol";
import {IFeeSink} from "../interfaces/IFeeSink.sol";

interface IInsuranceFund {
    function coverLoss(uint256 amount) external returns (uint256 covered);
}

/// @title  Vault
/// @notice The house: passive LP lending desk (spec §7). LPs deposit USDC under a lock tier and
///         earn **borrow interest + funding + liquidation surplus + the 0.25% LP fee slice** —
///         NO token emissions (founder correction). Capital backs the leverage engine and can take
///         socialized loss, buffered first by the (initially unfunded) InsuranceFund.
///
/// @dev    ACCOUNTING (reuses the Phase 1 LPVault accumulator model, audited):
///           - Fees/income accrue per **yield-weighted share** (`feeShares = principal·multiplier`),
///             so longer locks earn more yield (§7.1) — via `accFeesPerShare`.
///           - Losses accrue per **principal** (capital at risk is weighted 1:1, not by lock) —
///             via `accLossPerPrincipal`. This avoids penalizing long lockers with extra loss.
///         (Post-unlock multiplier decay is a future refinement; flagged.)
///
///         LOSS WATERFALL (§7.3): `writeOffLoan` → InsuranceFund first, remainder socialized to LP.
///         At zero insurance balance it is effectively LP-only today.
///
///         THE MM WALL (invariant #4, structural): vault principal is reduced ONLY via
///         `writeOffLoan`, gated to `LEVERAGE_ROLE`. There is **no code path** by which MM
///         market-making P&L can reach this accounting — MM trading capital lives in separate
///         MMAccounts (built later). An MM that *deposits* here is treated as any LP. When the MM
///         layer lands, this `LEVERAGE_ROLE`-only loss entry is the wall's enforcement point.
contract Vault is Governed, ReentrancyGuard, Pausable, IFeeSink {
    using SafeERC20 for IERC20;

    bytes32 public constant LEVERAGE_ROLE = keccak256("LEVERAGE_ROLE");
    bytes32 public constant FEE_SOURCE_ROLE = keccak256("FEE_SOURCE_ROLE");
    bytes32 public constant PAUSE_GUARDIAN_ROLE = keccak256("PAUSE_GUARDIAN_ROLE");

    uint256 internal constant ACC = 1e18;
    uint256 internal constant BPS = 10_000;
    uint256 public constant MIN_DEPOSIT = 10e6; // $10

    ProtocolConfig public immutable config;
    IERC20 public immutable usdc;
    IInsuranceFund public immutable insurance;

    struct Position {
        address owner;
        uint8 tier;
        uint256 principal; // 6-dec
        uint256 feeShares; // principal · multiplierBps / BPS
        uint256 unlockTime;
        uint256 feeDebt;
        uint256 lossDebt;
        uint256 withdrawReadyAt;
        uint256 feeActiveAt; // H4: time at which feeShares may start earning (deposit + minFeeHold)
        bool feeActive; // H4: whether feeShares have been added to totalFeeShares and are earning
        bool requested;
        bool withdrawn;
    }

    mapping(uint256 => Position) internal _positions;
    uint256 public positionCount;

    uint256 public totalFeeShares; // Σ feeShares of active positions
    uint256 public totalPrincipal; // Σ principal of active positions (the TVL for ratios)
    uint256 public accFeesPerShare; // ACC-scaled, per feeShare
    uint256 public accLossPerPrincipal; // ACC-scaled, per principal
    uint256 public feeBuffer; // income arriving while totalFeeShares == 0

    uint256 public outstandingLoans; // 6-dec lent to leverage

    // daily-loss circuit breaker (§7.5)
    uint256 public currentDay;
    uint256 public lossToday;
    bool internal dailyReduceOnly; // auto-trips on daily loss; resets each day
    bool public manualReduceOnly; // guardian trip; persists until governance clears

    /// @notice Effective reduce-only state (auto OR manual): blocks new lends, allows repay/close.
    function reduceOnly() public view returns (bool) {
        return dailyReduceOnly || manualReduceOnly;
    }

    /// @dev Resume / un-brake powers (H5): callable by the fast guardian OR governance. The guardian
    ///      gives a false pause/trip a fast recovery; governance is retained as a backstop so the
    ///      system can never be stuck (the unpause permission set is a SUPERSET of the pause set).
    ///      Only resume powers use this — pause/trip stay guardian-only; nothing fund/param-moving does.
    modifier onlyPauseController() {
        if (
            !accessController.hasRole(PAUSE_GUARDIAN_ROLE, msg.sender)
                && !accessController.hasRole(GOVERNANCE_ROLE, msg.sender)
        ) revert Unauthorized(PAUSE_GUARDIAN_ROLE, msg.sender);
        _;
    }

    event Deposited(uint256 indexed id, address indexed owner, uint8 tier, uint256 principal, uint256 feeShares);
    event FeeShareActivated(uint256 indexed id, uint256 feeShares);
    event FeesClaimed(uint256 indexed id, uint256 amount);
    // remaining/feesPaid are NOT known at request anymore (settlement moved to withdraw, Fix B for M2)
    event WithdrawRequested(uint256 indexed id, uint256 readyAt);
    event Withdrawn(uint256 indexed id, uint256 payout, uint256 feesPaid);
    event IncomeDistributed(uint256 amount, bool buffered);
    event Lent(address indexed to, uint256 amount);
    event Repaid(uint256 amount);
    event WrittenOff(uint256 amount, uint256 insuranceCovered, uint256 socialized);
    event SurplusReceived(uint256 amount);
    event ReduceOnlySet(bool on, uint256 lossToday);

    error ZeroAddress();
    /// @dev Collateral token is not 6-decimal. USDC_SCALE (1e12) and every `/USDC_SCALE`
    ///      floor-division in this contract assume 6-dec collateral — that truncation is a
    ///      deliberate rounding bias that keeps Σ user claims ≤ the backing pool. An 18-dec
    ///      token (e.g. Binance-Peg USDC/USDT on BSC mainnet) would mis-scale silently.
    error CollateralNotSixDecimals(uint8 got);
    error DepositTooSmall();
    error InvalidTier(uint8 tier);
    error NotOwner();
    error StillLocked();
    error AlreadyRequested();
    error NotRequested();
    error CooldownNotElapsed();
    error AlreadyWithdrawn();
    error NotYetActive();
    error AlreadyActive();
    error ReduceOnlyActive();
    error OutstandingLoanCeiling(uint256 attempted, uint256 ceiling);
    error InsufficientLiquidity(uint256 amount, uint256 available);

    constructor(address accessController_, address config_, address usdc_, address insurance_)
        Governed(accessController_)
    {
        if (config_ == address(0) || usdc_ == address(0) || insurance_ == address(0)) revert ZeroAddress();
        config = ProtocolConfig(config_);
        if (IERC20Metadata(usdc_).decimals() != 6) {
            revert CollateralNotSixDecimals(IERC20Metadata(usdc_).decimals());
        }
        usdc = IERC20(usdc_);
        insurance = IInsuranceFund(insurance_);
    }

    // ─── deposit ────────────────────────────────────────────────────────────────

    function deposit(uint256 amount, uint8 tier) external nonReentrant whenNotPaused returns (uint256 id) {
        if (amount < MIN_DEPOSIT) revert DepositTooSmall();
        if (tier > 3) revert InvalidTier(tier);
        usdc.safeTransferFrom(msg.sender, address(this), amount);

        uint256 mult = config.lockMultipliersBps(tier);
        uint256 feeShares = (amount * mult) / BPS;
        uint256 unlockTime = block.timestamp + config.lockDurations(tier);

        // H4 (Fix A): feeShares earn only after a minimum hold, so capital present for less than
        // minFeeHold cannot sandwich a fee distribution. With minFeeHold == 0 the deposit is active
        // immediately (identical to the pre-fix behavior). Principal is ALWAYS loss-liable from now
        // (added to totalPrincipal) — only fee-EARNING is gated, never principal liquidity.
        uint256 hold = config.minFeeHold();
        bool active = hold == 0;

        id = ++positionCount;
        _positions[id] = Position({
            owner: msg.sender,
            tier: tier,
            principal: amount,
            feeShares: feeShares,
            unlockTime: unlockTime,
            feeDebt: active ? (feeShares * accFeesPerShare) / ACC : 0,
            lossDebt: (amount * accLossPerPrincipal) / ACC,
            withdrawReadyAt: 0,
            feeActiveAt: block.timestamp + hold,
            feeActive: active,
            requested: false,
            withdrawn: false
        });
        if (active) totalFeeShares += feeShares; // else added on activation, once the hold elapses
        totalPrincipal += amount;
        emit Deposited(id, msg.sender, tier, amount, feeShares);
    }

    /// @notice Activate a position's fee-earning once its minimum hold has elapsed (H4). Permissionless
    ///         — anyone (the owner, a keeper, the frontend) may call. claimFees/requestWithdraw also
    ///         auto-activate, so this is rarely needed directly. Activation only ever STARTS earning;
    ///         it never touches principal, so it can never be a path to losing funds.
    function activate(uint256 id) external {
        Position storage p = _positions[id];
        if (p.owner == address(0)) revert NotOwner();
        if (p.feeActive) revert AlreadyActive();
        if (block.timestamp < p.feeActiveAt) revert NotYetActive();
        _activate(p, id);
    }

    /// @dev Add a matured position's feeShares to the earning pool, caught up to the current
    ///      accumulator (feeDebt set to now ⇒ no claim on distributions during the hold).
    function _activate(Position storage p, uint256 id) internal {
        p.feeActive = true;
        p.feeDebt = (p.feeShares * accFeesPerShare) / ACC;
        totalFeeShares += p.feeShares;
        emit FeeShareActivated(id, p.feeShares);
    }

    /// @dev Auto-activate on the owner's own interactions if the hold has elapsed (ergonomics).
    function _activateIfEligible(Position storage p, uint256 id) internal {
        if (!p.feeActive && !p.withdrawn && block.timestamp >= p.feeActiveAt) _activate(p, id);
    }

    // ─── claims / withdrawal ──────────────────────────────────────────────────────

    /// @notice Claim accrued fees. NOT pause-gated (earned value always withdrawable, H-LP-1).
    function claimFees(uint256 id) external nonReentrant returns (uint256 fees) {
        Position storage p = _positions[id];
        if (p.owner != msg.sender) revert NotOwner();
        _activateIfEligible(p, id); // start earning if the hold has elapsed
        fees = _pendingFees(p);
        if (p.feeActive) p.feeDebt = (p.feeShares * accFeesPerShare) / ACC;
        if (fees > 0) usdc.safeTransfer(msg.sender, fees);
        emit FeesClaimed(id, fees);
    }

    /// @notice Begin withdrawal after the lock elapses, and start the cooldown. Fix B (M2): the
    ///         position STAYS in totalPrincipal (loss-liable) and totalFeeShares (earning) through the
    ///         cooldown — an exiting LP is still capital-at-risk until it actually leaves, so it bears
    ///         losses that land during its cooldown. Fees + loss are settled at {withdraw}, not here.
    ///         NOT pause-gated.
    function requestWithdraw(uint256 id) external nonReentrant {
        Position storage p = _positions[id];
        if (p.owner != msg.sender) revert NotOwner();
        if (p.requested) revert AlreadyRequested();
        if (p.withdrawn) revert AlreadyWithdrawn();
        if (block.timestamp < p.unlockTime) revert StillLocked();

        _activateIfEligible(p, id); // keep earning through the cooldown if matured
        p.requested = true;
        p.withdrawReadyAt = block.timestamp + config.withdrawalCooldown();
        emit WithdrawRequested(id, p.withdrawReadyAt);
    }

    /// @notice Complete a requested withdrawal after the cooldown: settle accrued fees + realize loss
    ///         (both through the cooldown), exit the pools, and pay out. Fix B settles HERE, not at
    ///         request, so losses during the cooldown reduce the payout (M2 closed).
    function withdraw(uint256 id) external nonReentrant returns (uint256 amount) {
        Position storage p = _positions[id];
        if (p.owner != msg.sender) revert NotOwner();
        if (!p.requested) revert NotRequested();
        if (p.withdrawn) revert AlreadyWithdrawn();
        if (block.timestamp < p.withdrawReadyAt) revert CooldownNotElapsed();

        uint256 fees = _pendingFees(p);
        uint256 loss = _realizedLoss(p);
        amount = p.principal - loss; // loss accrued through the whole residency, incl. the cooldown

        if (p.feeActive) totalFeeShares -= p.feeShares; // only in the pool if it was activated
        totalPrincipal -= p.principal;
        p.feeShares = 0;
        p.principal = 0;
        p.withdrawn = true;

        if (fees > 0) usdc.safeTransfer(p.owner, fees);
        if (amount > 0) usdc.safeTransfer(p.owner, amount);
        emit Withdrawn(id, amount, fees);
    }

    // ─── income (fees / surplus) ──────────────────────────────────────────────────

    /// @notice Receive the LP fee slice (IFeeSink, pull). Distributed as LP yield from day one.
    function notifyFee(uint256 amount) external onlyRole(FEE_SOURCE_ROLE) nonReentrant {
        usdc.safeTransferFrom(msg.sender, address(this), amount);
        _distribute(amount);
    }

    /// @notice Receive liquidation surplus from the leverage engine; distributed as LP yield.
    function receiveSurplus(uint256 amount) external onlyRole(LEVERAGE_ROLE) nonReentrant {
        usdc.safeTransferFrom(msg.sender, address(this), amount);
        _distribute(amount);
        emit SurplusReceived(amount);
    }

    function _distribute(uint256 amount) internal {
        uint256 total = amount + feeBuffer;
        if (totalFeeShares == 0) {
            feeBuffer = total;
            emit IncomeDistributed(amount, true);
            return;
        }
        feeBuffer = 0;
        accFeesPerShare += (total * ACC) / totalFeeShares;
        emit IncomeDistributed(amount, false);
    }

    // ─── leverage lending desk (LEVERAGE_ROLE only — the MM wall lives here) ──────

    /// @notice Lend `amount` to the leverage engine. Blocked in reduce-only; bounded by the
    ///         outstanding-loan ceiling (§7.5) and by available (un-lent) liquidity.
    function lendToLeverage(uint256 amount, address to) external onlyRole(LEVERAGE_ROLE) nonReentrant {
        _rolloverDay();
        if (reduceOnly()) revert ReduceOnlyActive();
        uint256 ceiling = (totalPrincipal * config.maxOutstandingLoanBps()) / BPS;
        if (outstandingLoans + amount > ceiling) revert OutstandingLoanCeiling(outstandingLoans + amount, ceiling);
        uint256 avail = availableLiquidity();
        if (amount > avail) revert InsufficientLiquidity(amount, avail);
        outstandingLoans += amount;
        usdc.safeTransfer(to, amount);
        emit Lent(to, amount);
    }

    /// @notice Lend for an UNWIND (liquidation / position close) — identical to {lendToLeverage} except
    ///         it is NOT blocked by reduce-only, so the daily-loss / guardian breaker can never block a
    ///         loss-REDUCING action (a position can always be liquidated/closed even while new opens are
    ///         halted). Still `LEVERAGE_ROLE`-gated and bounded by the outstanding-loan ceiling and
    ///         available liquidity. Inert until a leverage engine holds the role (none at launch).
    function lendForUnwind(uint256 amount, address to) external onlyRole(LEVERAGE_ROLE) nonReentrant {
        _rolloverDay();
        // (intentionally no reduceOnly() gate — this is the only difference vs lendToLeverage)
        uint256 ceiling = (totalPrincipal * config.maxOutstandingLoanBps()) / BPS;
        if (outstandingLoans + amount > ceiling) revert OutstandingLoanCeiling(outstandingLoans + amount, ceiling);
        uint256 avail = availableLiquidity();
        if (amount > avail) revert InsufficientLiquidity(amount, avail);
        outstandingLoans += amount;
        usdc.safeTransfer(to, amount);
        emit Lent(to, amount);
    }

    function repayLoan(uint256 amount) external onlyRole(LEVERAGE_ROLE) nonReentrant {
        usdc.safeTransferFrom(msg.sender, address(this), amount);
        outstandingLoans = amount >= outstandingLoans ? 0 : outstandingLoans - amount;
        emit Repaid(amount);
    }

    /// @notice Socialize a loan loss through the waterfall: InsuranceFund first, remainder to LP.
    function writeOffLoan(uint256 amount) external onlyRole(LEVERAGE_ROLE) nonReentrant {
        // Clamp the loss to genuinely-outstanding debt: a write-off can never socialize more than was
        // actually lent out and unrecovered, so a buggy/overstated `amount` from the leverage role
        // can't reduce LP principal beyond a real loan loss (defense-in-depth on the wall's magnitude).
        uint256 realLoss = amount > outstandingLoans ? outstandingLoans : amount;
        outstandingLoans -= realLoss;
        uint256 covered = insurance.coverLoss(realLoss); // sends `covered` USDC to this vault
        uint256 socialized = realLoss - covered;
        if (socialized > 0 && totalPrincipal > 0) {
            accLossPerPrincipal += (socialized * ACC) / totalPrincipal;
            _accrueDailyLoss(socialized);
        }
        emit WrittenOff(realLoss, covered, socialized);
    }

    // ─── circuit breakers (§7.5) ──────────────────────────────────────────────────

    function _rolloverDay() internal {
        uint256 today = block.timestamp / 1 days;
        if (today != currentDay) {
            currentDay = today;
            lossToday = 0;
            dailyReduceOnly = false;
        }
    }

    function _accrueDailyLoss(uint256 amount) internal {
        _rolloverDay();
        lossToday += amount;
        uint256 limit = (totalPrincipal * config.maxLossPerDayBps()) / BPS;
        if (!dailyReduceOnly && totalPrincipal > 0 && lossToday >= limit) {
            dailyReduceOnly = true;
            emit ReduceOnlySet(true, lossToday);
        }
    }

    /// @notice Guardian manual reduce-only trip (new opens paused, closes/repays allowed).
    ///         Persists across day rollovers until governance clears it.
    function tripReduceOnly() external onlyRole(PAUSE_GUARDIAN_ROLE) {
        manualReduceOnly = true;
        emit ReduceOnlySet(true, lossToday);
    }

    function clearReduceOnly() external onlyPauseController {
        manualReduceOnly = false;
        dailyReduceOnly = false;
        emit ReduceOnlySet(false, lossToday);
    }

    // ─── views ────────────────────────────────────────────────────────────────────

    function _pendingFees(Position storage p) internal view returns (uint256) {
        if (!p.feeActive) return 0; // not yet earning (within its minFeeHold) — H4
        return (p.feeShares * accFeesPerShare) / ACC - p.feeDebt;
    }

    function _realizedLoss(Position storage p) internal view returns (uint256 loss) {
        loss = (p.principal * accLossPerPrincipal) / ACC - p.lossDebt;
        if (loss > p.principal) loss = p.principal; // clamp — never below zero value
    }

    function pendingFees(uint256 id) external view returns (uint256) {
        Position storage p = _positions[id];
        if (p.withdrawn) return 0;
        return _pendingFees(p); // earns through the cooldown (Fix B); 0 while inactive (Fix A)
    }

    function positionValue(uint256 id) external view returns (uint256) {
        Position storage p = _positions[id];
        if (p.withdrawn) return 0;
        // loss-liable through the cooldown (Fix B), so a requested position still nets out its loss
        return p.principal - _realizedLoss(p);
    }

    function getPosition(uint256 id) external view returns (Position memory) {
        return _positions[id];
    }

    /// @notice TVL = active LP principal (the base for loan ceiling + daily-loss limit).
    function tvl() external view returns (uint256) {
        return totalPrincipal;
    }

    function availableLiquidity() public view returns (uint256) {
        return totalPrincipal > outstandingLoans ? totalPrincipal - outstandingLoans : 0;
    }

    /// @notice Utilization-kink borrow APR in bps (§7.2). High top end so interest bites at high
    ///         utilization. NOTE(param): for the steep `slope2` to engage, `uOptimalBps` must sit
    ///         BELOW `maxOutstandingLoanBps` (else utilization is ceiling-capped below the kink).
    function borrowAPRBps() public view returns (uint256) {
        if (totalPrincipal == 0) return config.baseRateBps();
        uint256 util = (outstandingLoans * BPS) / totalPrincipal;
        uint256 uOpt = config.uOptimalBps();
        uint256 base = config.baseRateBps();
        if (util <= uOpt) {
            return base + (config.slope1Bps() * util) / uOpt;
        }
        uint256 excess = util - uOpt;
        uint256 denom = BPS - uOpt;
        return base + config.slope1Bps() + (config.slope2Bps() * excess) / denom;
    }

    // ─── pause ──────────────────────────────────────────────────────────────────

    function pause() external onlyRole(PAUSE_GUARDIAN_ROLE) {
        _pause();
    }

    function unpause() external onlyPauseController {
        _unpause();
    }
}
