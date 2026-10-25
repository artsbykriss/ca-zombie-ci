// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Governed} from "../access/Governed.sol";
import {ProtocolConfig} from "../config/ProtocolConfig.sol";
import {TemplateRegistry} from "./TemplateRegistry.sol";
import {RollingWindow} from "../libraries/RollingWindow.sol";

interface ISpotEngineInit {
    function initializeMarket(uint256 id, uint256 b, uint64 endDate, uint256 seed) external;
    function haltMarket(uint256 id) external;
}

/// @notice Optional, post-deploy-settable precondition on graduation. A future leverage release that
///         prices leverage off the (pre-graduation) curve uses this to block a market from graduating
///         while it carries open leveraged OI (the curve mark would otherwise be stranded). Inert at
///         launch (`graduationGuard == address(0)`), so the immutable registry stays forward-compatible
///         with the curve-priced leverage design without committing to it now.
interface IGraduationGuard {
    function canGraduate(uint256 marketId) external view returns (bool);
}

/// @title  MarketRegistry
/// @notice The market lifecycle spine (spec §3): submit → review → list → graduate, with the
///         three-tier validity model. Tier-1 (objective) checks REVERT in {createMarketSelfServe}
///         so spammers burn only gas (spec §3.1/§3.2). Self-serve creators fund the LMSR seed
///         (`b·ln2`) AND a refundable validity bond from their own wallet — **treasury funds
///         nothing** (invariant #13). Featured markets (CREATOR_ROLE) skip review.
///
/// @dev    Neutral-start gate (spec §3.4b) is structural: creation accepts NO initial position, so
///         every market opens at qYES=qNO=0 ⇒ 50% — a creator cannot pre-pin the price. The
///         subjective "genuinely uncertain" gate (§3.4a) is the REVIEWER_ROLE's job.
///
///         This component owns creation→review→graduation + the time-based →Resolving transition.
///         The terminal transitions (Resolved/Void/Closed) and validity-bond release on clean
///         resolution are added with the ResolutionModule, which will drive them after settlement.
contract MarketRegistry is Governed {
    error NotSelf();
    error NothingToClaim();

    /// @dev Bonds that failed to transfer at settlement, by creator. Settlement must
    ///      never depend on one address being able to receive. Audit H3.
    mapping(address => uint256) public unclaimedValidityBond;

    using SafeERC20 for IERC20;
    using RollingWindow for RollingWindow.Data;

    enum MarketState {
        Submitted,
        InReview,
        Rejected,
        Listed,
        Graduated,
        Resolving,
        Resolved,
        Void,
        Closed
    }

    struct Market {
        address creator;
        uint64 endDate;
        uint64 createdAt;
        MarketState state;
        bool featured;
        uint256 templateId;
        uint256 resolutionSourceId;
        bytes32 questionHash;
        uint256 b; // 18-dec liquidity parameter
        uint256 seed; // 6-dec USDC custodied (creator-funded LMSR backing)
        uint256 validityBond; // 6-dec USDC custodied (0 for featured)
        uint256 distinctTraders;
        RollingWindow.Data vol;
    }

    // ─── roles (membership lives in the central AccessController) ────────────────
    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");
    bytes32 public constant REVIEWER_ROLE = keccak256("REVIEWER_ROLE");
    /// @notice The spot engine / order book — reports trades that drive graduation metrics.
    bytes32 public constant TRADE_RECORDER_ROLE = keccak256("TRADE_RECORDER_ROLE");
    /// @notice The resolution module — drives the terminal Resolving→Resolved/Void→Closed transitions.
    bytes32 public constant RESOLUTION_ROLE = keccak256("RESOLUTION_ROLE");

    uint256 internal constant USDC_SCALE = 1e12;
    int256 internal constant LN2_18 = 693147180559945309; // ln(2) · 1e18

    ProtocolConfig public immutable config;
    TemplateRegistry public immutable templates;
    IERC20 public immutable usdc;

    /// @notice The spot engine that backs listed markets' LMSR liquidity. Settable so the registry
    ///         can deploy first; once set, the creator-funded seed is forwarded to it on listing.
    address public spotEngine;

    /// @notice Optional graduation precondition (see {IGraduationGuard}). `address(0)` ⇒ inert (no
    ///         graduation check), which is the launch default. Forward-compat hook for a later
    ///         curve-priced leverage release; cannot be added to this immutable contract afterwards.
    address public graduationGuard;

    uint256 public marketCount;
    mapping(uint256 => Market) internal _markets;
    mapping(uint256 => mapping(address => bool)) internal _hasTraded;
    /// @notice Per (market, trader) LIFETIME volume already counted toward gradVolume (capped at
    ///         `gradVolumePerWalletCap`). Anti-whale-wash: bounds any one wallet's graduation contribution.
    mapping(uint256 => mapping(address => uint256)) internal _countedVolume;
    /// @notice questionHash → live marketId (0 = none). Powers dedupe of CONCURRENT live markets;
    ///         cleared on reject/resolve/void so a recurring question can be re-created (I9). This is a
    ///         liveness-scoped lock, NOT a permanent global uniqueness guarantee — off-chain indexers
    ///         must not assume a questionHash maps to exactly one market over all time.
    mapping(bytes32 => uint256) public liveMarketByHash;

    event MarketSubmitted(
        uint256 indexed id, address indexed creator, uint256 templateId, uint256 resolutionSourceId,
        bytes32 questionHash, uint64 endDate, uint256 b, uint256 seed, uint256 validityBond
    );
    event MarketListed(uint256 indexed id, bool featured);
    /// @notice Validity bond that could not be pushed to the creator at settlement.
    ///         Claimable by the creator via claimValidityBond(). Audit H3.
    event ValidityBondAccrued(address indexed creator, uint256 amount);
    event ValidityBondClaimed(address indexed creator, uint256 amount);
    event ReviewStarted(uint256 indexed id);
    event MarketRejected(uint256 indexed id, bool malicious, uint256 bondSlashed);
    event Graduated(uint256 indexed id, uint256 distinctTraders, uint256 rollingVolume, uint256 ts);
    event MarketResolving(uint256 indexed id, uint256 ts);
    event MarketResolved(uint256 indexed id, uint256 bondReturned);
    event MarketVoid(uint256 indexed id, uint256 bondReturned);
    event MarketClosed(uint256 indexed id);
    event SpotEngineSet(address indexed spotEngine);
    event GraduationGuardSet(address indexed guard);
    event ActivityRecorded(uint256 indexed id, address indexed trader, uint256 volume, bool newTrader);

    error ZeroAddress();
    /// @dev Collateral token is not 6-decimal. USDC_SCALE (1e12) and every `/USDC_SCALE`
    ///      floor-division in this contract assume 6-dec collateral — that truncation is a
    ///      deliberate rounding bias that keeps Σ user claims ≤ the backing pool. An 18-dec
    ///      token (e.g. Binance-Peg USDC/USDT on BSC mainnet) would mis-scale silently.
    error CollateralNotSixDecimals(uint8 got);
    error MarketEndsTooSoon();
    error EmptyQuestion();
    error DuplicateQuestion(uint256 existingId);
    error BOutOfRange(uint256 b);
    error MarketNotFound(uint256 id);
    error InvalidState(uint256 id, MarketState current);
    error NotYetEnded(uint256 id);
    error GraduationConditionsNotMet(uint256 id);
    error GraduationBlocked(uint256 id);

    constructor(address accessController_, address config_, address templates_, address usdc_)
        Governed(accessController_)
    {
        if (config_ == address(0) || templates_ == address(0) || usdc_ == address(0)) {
            revert ZeroAddress();
        }
        config = ProtocolConfig(config_);
        templates = TemplateRegistry(templates_);
        if (IERC20Metadata(usdc_).decimals() != 6) {
            revert CollateralNotSixDecimals(IERC20Metadata(usdc_).decimals());
        }
        usdc = IERC20(usdc_);
    }

    /// @notice Set the spot engine that receives the seed on listing (governance).
    function setSpotEngine(address engine) external onlyGovernance {
        if (engine == address(0)) revert ZeroAddress();
        spotEngine = engine;
        emit SpotEngineSet(engine);
    }

    /// @notice Set (or clear) the optional graduation guard (governance). `address(0)` is the inert
    ///         state — DELIBERATELY accepted (unlike most setters) because it is both the launch default
    ///         and the recovery path if an activated guard misbehaves. Not a missing zero-address check.
    function setGraduationGuard(address guard) external onlyGovernance {
        graduationGuard = guard;
        emit GraduationGuardSet(guard);
    }

    /// @dev On listing, forward the custodied creator-funded seed to the spot engine and
    ///      initialize the market's LMSR backing. No-op if the engine isn't wired yet.
    function _onListed(uint256 id) internal {
        address engine = spotEngine;
        if (engine == address(0)) return;
        Market storage m = _markets[id];
        uint256 seed = m.seed;
        m.seed = 0; // custody moves to the spot engine
        if (seed > 0) usdc.safeTransfer(engine, seed);
        ISpotEngineInit(engine).initializeMarket(id, m.b, m.endDate, seed);
    }

    // ─── seed math (matches the audited Phase 1 subsidy computation) ─────────────

    /// @notice Creator-funded LMSR seed for liquidity `b`, in 6-dec USDC: `ceil(b·ln2 / 1e12)`.
    function previewSeed(uint256 b) public pure returns (uint256) {
        uint256 seed18 = uint256((int256(b) * LN2_18) / 1e18);
        uint256 s = seed18 / USDC_SCALE;
        if (s * USDC_SCALE < seed18) s += 1; // ceil
        return s;
    }

    // ─── creation ────────────────────────────────────────────────────────────────

    /// @notice Self-serve creation: tier-1 checks REVERT; pulls seed + validity bond from the
    ///         creator; lands in `Submitted` awaiting review.
    function createMarketSelfServe(
        uint256 templateId,
        uint256 resolutionSourceId,
        bytes32 questionHash,
        uint64 endDate,
        uint256 b
    ) external returns (uint256 id) {
        _tier1Checks(templateId, resolutionSourceId, questionHash, endDate, true);
        if (b < config.B_HARD_MIN() || b > config.bSelfserveMax()) revert BOutOfRange(b);

        uint256 seed = previewSeed(b);
        uint256 bond = config.validityBondFloor(); // TODO(param): make dynamic w/ invalid-rate
        usdc.safeTransferFrom(msg.sender, address(this), seed + bond);

        id = _record(msg.sender, templateId, resolutionSourceId, questionHash, endDate, b, seed, bond, false);
        _markets[id].state = MarketState.Submitted;
        emit MarketSubmitted(id, msg.sender, templateId, resolutionSourceId, questionHash, endDate, b, seed, bond);
    }

    /// @notice Featured creation (CREATOR_ROLE): protocol/MM funds the seed, no bond, skips review.
    function createMarketFeatured(
        uint256 templateId,
        uint256 resolutionSourceId,
        bytes32 questionHash,
        uint64 endDate,
        uint256 b
    ) external onlyRole(CREATOR_ROLE) returns (uint256 id) {
        _tier1Checks(templateId, resolutionSourceId, questionHash, endDate, false);
        if (b < 2_000e18 || b > config.B_HARD_MAX()) revert BOutOfRange(b);

        uint256 seed = previewSeed(b);
        usdc.safeTransferFrom(msg.sender, address(this), seed);

        id = _record(msg.sender, templateId, resolutionSourceId, questionHash, endDate, b, seed, 0, true);
        _markets[id].state = MarketState.Listed;
        emit MarketListed(id, true);
        _onListed(id);
    }

    function _tier1Checks(
        uint256 templateId,
        uint256 resolutionSourceId,
        bytes32 questionHash,
        uint64 endDate,
        bool enforceDuplicateCheck
    ) internal view {
        if (endDate <= block.timestamp + config.minDuration()) revert MarketEndsTooSoon();
        templates.requireValidResolutionSource(resolutionSourceId);
        templates.requireValidTemplate(templateId);
        if (questionHash == bytes32(0)) revert EmptyQuestion();
        // L1: the questionHash dedupe is a self-serve anti-spam guard. A trusted
        // CREATOR_ROLE featured market must NOT be griefable by someone squatting
        // the same hash via self-serve, so featured creation skips this check
        // (and _record then takes ownership of the hash lock).
        if (enforceDuplicateCheck) {
            uint256 dup = liveMarketByHash[questionHash];
            if (dup != 0) revert DuplicateQuestion(dup);
        }
    }

    function _record(
        address creator,
        uint256 templateId,
        uint256 resolutionSourceId,
        bytes32 questionHash,
        uint64 endDate,
        uint256 b,
        uint256 seed,
        uint256 bond,
        bool featured
    ) internal returns (uint256 id) {
        id = ++marketCount;
        Market storage m = _markets[id];
        m.creator = creator;
        m.endDate = endDate;
        m.createdAt = uint64(block.timestamp);
        m.featured = featured;
        m.templateId = templateId;
        m.resolutionSourceId = resolutionSourceId;
        m.questionHash = questionHash;
        m.b = b;
        m.seed = seed;
        m.validityBond = bond;
        liveMarketByHash[questionHash] = id;
    }

    // ─── review ──────────────────────────────────────────────────────────────────

    function startReview(uint256 id) external onlyRole(REVIEWER_ROLE) {
        Market storage m = _exists(id);
        if (m.state != MarketState.Submitted) revert InvalidState(id, m.state);
        m.state = MarketState.InReview;
        emit ReviewStarted(id);
    }

    function approveMarket(uint256 id) external onlyRole(REVIEWER_ROLE) {
        Market storage m = _exists(id);
        if (m.state != MarketState.Submitted && m.state != MarketState.InReview) {
            revert InvalidState(id, m.state);
        }
        m.state = MarketState.Listed;
        emit MarketListed(id, false);
        _onListed(id);
    }

    /// @notice Reject a submitted market. Seed is always returned to the creator. The validity
    ///         bond is returned on a good-faith rejection and slashed to treasury only if `malicious`
    ///         (spec §3.1 / §9.5).
    function rejectMarket(uint256 id, bool malicious) external onlyRole(REVIEWER_ROLE) {
        Market storage m = _exists(id);
        if (m.state != MarketState.Submitted && m.state != MarketState.InReview) {
            revert InvalidState(id, m.state);
        }
        m.state = MarketState.Rejected;
        delete liveMarketByHash[m.questionHash];

        uint256 seed = m.seed;
        uint256 bond = m.validityBond;
        m.seed = 0;
        m.validityBond = 0;

        if (seed > 0) usdc.safeTransfer(m.creator, seed);
        uint256 slashed;
        if (bond > 0) {
            if (malicious) {
                slashed = bond;
                usdc.safeTransfer(config.treasury(), bond);
            } else {
                usdc.safeTransfer(m.creator, bond);
            }
        }
        emit MarketRejected(id, malicious, slashed);
    }

    // ─── activity + graduation ────────────────────────────────────────────────────

    /// @notice Report trade activity for graduation metrics. Called by the spot engine / order book.
    function recordActivity(uint256 id, address trader, uint256 volume)
        external
        onlyRole(TRADE_RECORDER_ROLE)
    {
        Market storage m = _exists(id);
        if (m.state != MarketState.Listed && m.state != MarketState.Graduated) {
            revert InvalidState(id, m.state);
        }
        bool newTrader = !_hasTraded[id][trader];
        if (newTrader) {
            _hasTraded[id][trader] = true;
            m.distinctTraders += 1;
        }
        // Per-wallet cap: count at most `gradVolumePerWalletCap` of any ONE wallet's LIFETIME volume
        // toward the graduation rolling sum (cap == 0 ⇒ no cap). Lifetime-cumulative, so a wallet's
        // repeated trades accrue toward its OWN cap and don't reset, and partial fills (multiple smaller
        // calls) accumulate identically — a single wallet can't self-trade a market to graduation.
        // `distinctTraders` + `RollingWindow` are untouched; only the AMOUNT added to `m.vol` shrinks.
        uint256 counted = volume;
        uint256 cap = config.gradVolumePerWalletCap();
        if (cap != 0) {
            uint256 already = _countedVolume[id][trader];
            uint256 room = already >= cap ? 0 : cap - already;
            if (counted > room) counted = room;
            _countedVolume[id][trader] = already + counted;
        }
        m.vol.add(counted, block.timestamp, config.gradWindow());
        emit ActivityRecorded(id, trader, volume, newTrader); // emit the RAW trade size (honest)
    }

    /// @notice Graduate a Listed market once it is genuinely proven: aged past the smoothing
    ///         window, with enough distinct traders AND enough rolling (recent) volume (spec §3.3).
    ///         Permissionless — anyone may trigger once the conditions hold.
    function tryGraduate(uint256 id) external {
        Market storage m = _exists(id);
        if (m.state != MarketState.Listed) revert InvalidState(id, m.state);

        uint256 window = config.gradWindow();
        bool aged = block.timestamp >= uint256(m.createdAt) + window;
        bool enoughTraders = m.distinctTraders >= config.gradTraders();
        uint256 rolling = m.vol.rollingSum(block.timestamp, window);
        bool enoughVolume = rolling >= config.gradVolume();
        if (!(aged && enoughTraders && enoughVolume)) revert GraduationConditionsNotMet(id);

        // Optional graduation precondition (inert when unset). Fail-CLOSED: an activated guard that
        // returns false (or reverts) blocks graduation — the safe direction, since the market simply
        // stays curve-priced and tradeable. Governance can reset the guard to address(0) to recover.
        address guard = graduationGuard;
        if (guard != address(0) && !IGraduationGuard(guard).canGraduate(id)) revert GraduationBlocked(id);

        m.state = MarketState.Graduated;
        emit Graduated(id, m.distinctTraders, rolling, block.timestamp);
    }

    /// @notice Move a live market into Resolving once its event date has passed. Permissionless.
    function markResolving(uint256 id) external {
        Market storage m = _exists(id);
        if (m.state != MarketState.Listed && m.state != MarketState.Graduated) {
            revert InvalidState(id, m.state);
        }
        if (block.timestamp < m.endDate) revert NotYetEnded(id);
        m.state = MarketState.Resolving;
        if (spotEngine != address(0)) ISpotEngineInit(spotEngine).haltMarket(id);
        emit MarketResolving(id, block.timestamp);
    }

    // ─── terminal transitions (driven by the ResolutionModule) ─────────────────────

    /// @dev Release the custodied validity bond to the creator (one-shot). The bond is returned on
    ///      any settled outcome — a market reaching resolution was, by definition, a real question
    ///      (a malicious/invalid one is caught and slashed at review, §3.1).
    function _releaseValidityBond(Market storage m) internal returns (uint256 bond) {
        bond = m.validityBond;
        if (bond > 0) {
            m.validityBond = 0;
            // A bare safeTransfer here let ONE address brick a whole market. The
            // collateral is USDW, which carries a blacklist: if the creator were
            // blacklisted (or were a contract that reverts on receipt), this transfer
            // reverts, markResolved/markVoid revert with it, finalize() can never
            // succeed, and every trader's collateral plus the proposer's bond is
            // locked in that market permanently. No v2 contract has a rescue path.
            // Audit 2026-09-04 H3.
            //
            // Same treatment FeeRouter already gives its creator/treasury sinks:
            // push through an external self-call so a revert is catchable, and accrue
            // on failure so settlement always completes. The creator can claim later.
            try this.pushValidityBond(m.creator, bond) {
                // paid
            } catch {
                unclaimedValidityBond[m.creator] += bond;
                emit ValidityBondAccrued(m.creator, bond);
            }
        }
    }

    /// @notice Push a released bond. External ONLY so `_releaseValidityBond` can
    ///         try/catch it; self-call guarded so nobody else can move funds.
    function pushValidityBond(address to, uint256 amount) external {
        if (msg.sender != address(this)) revert NotSelf();
        usdc.safeTransfer(to, amount);
    }

    /// @notice Claim a validity bond that could not be pushed at settlement time
    ///         (e.g. the creator was blacklisted then, and is not now).
    function claimValidityBond() external returns (uint256 amount) {
        amount = unclaimedValidityBond[msg.sender];
        if (amount == 0) revert NothingToClaim();
        unclaimedValidityBond[msg.sender] = 0; // effects before interaction
        usdc.safeTransfer(msg.sender, amount);
        emit ValidityBondClaimed(msg.sender, amount);
    }

    /// @notice Finalize a market to a resolved outcome. Resolution-module only; the module owns the
    ///         outcome decision (bonded proposal + dispute). Frees the dedupe slot, returns the bond.
    function markResolved(uint256 id) external onlyRole(RESOLUTION_ROLE) {
        Market storage m = _exists(id);
        if (m.state != MarketState.Resolving) revert InvalidState(id, m.state);
        m.state = MarketState.Resolved;
        delete liveMarketByHash[m.questionHash];
        emit MarketResolved(id, _releaseValidityBond(m));
    }

    /// @notice Finalize a market to Void (unresolvable; holders refunded pro-rata by the token).
    function markVoid(uint256 id) external onlyRole(RESOLUTION_ROLE) {
        Market storage m = _exists(id);
        if (m.state != MarketState.Resolving) revert InvalidState(id, m.state);
        m.state = MarketState.Void;
        delete liveMarketByHash[m.questionHash];
        emit MarketVoid(id, _releaseValidityBond(m));
    }

    /// @notice Bookkeeping terminal: a settled market whose redemptions are complete. Permissionless
    ///         is unnecessary — the module/keeper closes it after settlement winds down.
    function markClosed(uint256 id) external onlyRole(RESOLUTION_ROLE) {
        Market storage m = _exists(id);
        if (m.state != MarketState.Resolved && m.state != MarketState.Void) {
            revert InvalidState(id, m.state);
        }
        m.state = MarketState.Closed;
        emit MarketClosed(id);
    }

    // ─── views ────────────────────────────────────────────────────────────────────

    function _exists(uint256 id) internal view returns (Market storage m) {
        m = _markets[id];
        if (m.creator == address(0)) revert MarketNotFound(id);
    }

    function getMarketInfo(uint256 id)
        external
        view
        returns (
            address creator,
            MarketState state,
            bool featured,
            uint64 endDate,
            uint64 createdAt,
            uint256 templateId,
            uint256 resolutionSourceId,
            bytes32 questionHash,
            uint256 b,
            uint256 seed,
            uint256 validityBond,
            uint256 distinctTraders
        )
    {
        Market storage m = _exists(id);
        return (
            m.creator, m.state, m.featured, m.endDate, m.createdAt, m.templateId,
            m.resolutionSourceId, m.questionHash, m.b, m.seed, m.validityBond, m.distinctTraders
        );
    }

    function marketState(uint256 id) external view returns (MarketState) {
        return _exists(id).state;
    }

    function rollingVolume(uint256 id) external view returns (uint256) {
        return _exists(id).vol.rollingSum(block.timestamp, config.gradWindow());
    }

    function hasTraded(uint256 id, address trader) external view returns (bool) {
        return _hasTraded[id][trader];
    }
}
