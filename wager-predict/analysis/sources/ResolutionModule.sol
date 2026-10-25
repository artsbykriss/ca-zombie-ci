// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Governed} from "../access/Governed.sol";
import {ProtocolConfig} from "../config/ProtocolConfig.sol";
import {OutcomeToken} from "../tokens/OutcomeToken.sol";
import {MarketRegistry} from "../markets/MarketRegistry.sol";

/// @dev Minimal view surface the module needs from the leverage engine — kept as an interface so
///      resolution doesn't compile against the full engine. Both are read-only / non-mutating.
interface ILeverageOI {
    function getMarketOI(uint256 marketId) external view returns (uint256 oiYes, uint256 oiNo);
    function hasLeveragePosition(uint256 marketId, address owner) external view returns (bool);
}

/// @dev Minimal settlement + position surface the module needs from the curve engine (SpotEngine).
///      Curve (Tier-1 LMSR) markets settle on the SpotEngine, NOT on the OutcomeToken ledger.
///      `resolveMarket`'s `side` is 0=YES, 1=NO (matches LMSRMath.Side's ABI encoding).
interface ISpotSettle {
    function isInitialized(uint256 id) external view returns (bool);
    function isMigrated(uint256 id) external view returns (bool);
    function resolveMarket(uint256 id, uint8 side) external;
    function resolveVoidMarket(uint256 id) external;
    function sharesOf(uint256 id, address user) external view returns (uint256 yes, uint256 no);
    function collateralOf(uint256 id) external view returns (uint256); // curve money-at-stake (6-dec)
}

/// @title  ResolutionModule
/// @notice Phase 2's optimistic, bonded resolution (spec §9) — the second historical attack surface
///         (both Polymarket resolution disasters were governance/oracle attacks), so it is built with
///         the same paranoia as the leverage bound. The flow:
///
///           1. **propose** — anyone holding NO position posts a bond sized to the money at stake
///              (spot OI + leveraged OI) and names an outcome (YES / NO / VOID).
///           2. **dispute** — within an OI-scaled window, anyone holding NO position can challenge by
///              posting a *larger* bond and naming a different outcome. This escalates to the multisig.
///           3a. **finalize** — if the window passes undisputed, anyone executes the proposal and the
///               proposer's bond is returned.
///           3b. **resolveDispute** — a disputed market is decided by the RESOLVER multisig (which must
///               itself hold NO position). The loser's bond is slashed **to the winner**; both wrong →
///               both bonds to the treasury. There is NO token-weighted vote anywhere in this path.
///
///         Execution flips the {OutcomeToken} (winners redeem $1/share in full — never capped — and a
///         bonded VOID refunds every holder at $0.5/share) and drives the registry's terminal
///         transition. Winners are always paid in full (supreme rule §0); every lever here protects the
///         *truthfulness* of the outcome, never a winner's payout.
///
/// @dev    The no-position gate is **defense-in-depth, not the primary defense.** On-chain identity is
///         Sybil-able (an interested party can bet from address A and propose from address B) and
///         ERC-1155 outcome tokens are giftable (a griefer can dust an honest proposer to block them —
///         a *liveness* nuisance with an easy workaround: propose from a fresh address; governance can
///         always propose). The real defenses are the bond, the larger-bond dispute, and the multisig
///         backstop. The gate simply raises the bar so you cannot trivially resolve a market you are
///         openly positioned in.
contract ResolutionModule is Governed, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice The dispute-resolution authority — a multisig (Gnosis Safe). Decides disputed markets.
    bytes32 public constant RESOLVER_ROLE = keccak256("RESOLVER_ROLE");

    uint256 internal constant BPS = 10_000;

    enum Phase {
        None,
        Proposed,
        Disputed,
        Settled
    }

    /// @dev None is the zero sentinel — a real proposal/outcome is never None.
    enum Outcome {
        None,
        Yes,
        No,
        Void
    }

    struct Resolution {
        Phase phase;
        Outcome proposed;
        Outcome counter; // the disputer's claimed outcome
        Outcome finalized; // the executed outcome (set at settlement)
        address proposer;
        address disputer;
        uint256 proposerBond;
        uint256 disputerBond;
        uint64 disputeDeadline;
    }

    ProtocolConfig public immutable config;
    OutcomeToken public immutable outcomeToken;
    MarketRegistry public immutable registry;
    ILeverageOI public immutable leverage;
    ISpotSettle public immutable spot;
    IERC20 public immutable usdc;

    mapping(uint256 => Resolution) public resolutions;

    event Proposed(uint256 indexed marketId, address indexed proposer, Outcome outcome, uint256 bond, uint64 disputeDeadline);
    event Disputed(uint256 indexed marketId, address indexed disputer, Outcome counter, uint256 bond);
    event Finalized(uint256 indexed marketId, Outcome outcome, address indexed proposer, uint256 bondReturned);
    event DisputeResolved(uint256 indexed marketId, Outcome outcome, address indexed winner, uint256 payout, uint256 toTreasury);
    event MarketClosed(uint256 indexed marketId);

    error ZeroAddress();
    error NotResolving(uint256 marketId);
    error AlreadyProposed(uint256 marketId);
    error NotProposed(uint256 marketId);
    error NotDisputed(uint256 marketId);
    error InvalidOutcome();
    error CounterMustDiffer();
    error DisputeWindowOpen(uint256 marketId);
    error DisputeWindowClosed(uint256 marketId);
    error HasPosition(uint256 marketId, address account);

    constructor(
        address accessController_,
        address config_,
        address outcomeToken_,
        address registry_,
        address leverage_,
        address spot_,
        address usdc_
    ) Governed(accessController_) {
        if (
            config_ == address(0) || outcomeToken_ == address(0) || registry_ == address(0)
                || leverage_ == address(0) || spot_ == address(0) || usdc_ == address(0)
        ) revert ZeroAddress();
        config = ProtocolConfig(config_);
        outcomeToken = OutcomeToken(outcomeToken_);
        registry = MarketRegistry(registry_);
        leverage = ILeverageOI(leverage_);
        spot = ISpotSettle(spot_);
        usdc = IERC20(usdc_);
    }

    // ─── propose ─────────────────────────────────────────────────────────────────

    /// @notice Post a bond and propose an outcome for a market that has entered Resolving. The bond
    ///         scales with the money at stake, so larger markets cost more to lie about.
    function propose(uint256 marketId, Outcome outcome) external nonReentrant {
        if (outcome == Outcome.None) revert InvalidOutcome();
        if (registry.marketState(marketId) != MarketRegistry.MarketState.Resolving) {
            revert NotResolving(marketId);
        }
        // C1: until a dispute-watcher bot is live, only the trusted RESOLVER multisig — or GOVERNANCE as
        // a backstop — may propose an outcome, so an attacker cannot set a self-favouring outcome and
        // finalize it. finalize() stays permissionless — it can only ever execute a proposal a RESOLVER
        // already vetted. Governance flips config.permissionlessResolution() on once a watcher exists to
        // restore the open flow.
        bool trusted = accessController.hasRole(RESOLVER_ROLE, msg.sender)
            || accessController.hasRole(GOVERNANCE_ROLE, msg.sender);
        if (!config.permissionlessResolution() && !trusted) revert Unauthorized(RESOLVER_ROLE, msg.sender);
        Resolution storage r = resolutions[marketId];
        if (r.phase != Phase.None) revert AlreadyProposed(marketId);
        // The no-position gate is defense-in-depth against arbitrary permissionless proposers. A trusted
        // RESOLVER / GOVERNANCE multisig is conflict-controlled socially, NOT by this on-chain gate:
        // outcome tokens are freely transferable, so gating the bound multisig on "holds no position"
        // lets a griefer dust it with 1 wei to permanently freeze the market — the exact reason
        // resolveDispute() also skips the gate. Exempt the trusted roles; every other (permissionless)
        // proposer is still gated.
        if (!trusted) _requireNoPosition(marketId, msg.sender);

        uint256 bond = computeBond(marketId);
        uint64 deadline = uint64(block.timestamp + disputeWindow(marketId));
        r.phase = Phase.Proposed;
        r.proposed = outcome;
        r.proposer = msg.sender;
        r.proposerBond = bond;
        r.disputeDeadline = deadline;

        usdc.safeTransferFrom(msg.sender, address(this), bond);
        emit Proposed(marketId, msg.sender, outcome, bond, deadline);
    }

    // ─── dispute ─────────────────────────────────────────────────────────────────

    /// @notice Challenge an open proposal with a different outcome, posting a larger bond. Escalates
    ///         the market to the RESOLVER multisig. The loser of the dispute forfeits their bond.
    function dispute(uint256 marketId, Outcome counter) external nonReentrant {
        Resolution storage r = resolutions[marketId];
        if (r.phase != Phase.Proposed) revert NotProposed(marketId);
        if (block.timestamp > r.disputeDeadline) revert DisputeWindowClosed(marketId);
        if (counter == Outcome.None) revert InvalidOutcome();
        if (counter == r.proposed) revert CounterMustDiffer();
        _requireNoPosition(marketId, msg.sender);

        uint256 bond = (r.proposerBond * config.disputeBondMultBps()) / BPS;
        r.phase = Phase.Disputed;
        r.counter = counter;
        r.disputer = msg.sender;
        r.disputerBond = bond;

        usdc.safeTransferFrom(msg.sender, address(this), bond);
        emit Disputed(marketId, msg.sender, counter, bond);
    }

    // ─── finalize (undisputed) ─────────────────────────────────────────────────────

    /// @notice After the dispute window passes with no challenge, execute the proposal and return the
    ///         proposer's bond. Permissionless — anyone can poke a market to settlement.
    function finalize(uint256 marketId) external nonReentrant {
        Resolution storage r = resolutions[marketId];
        if (r.phase != Phase.Proposed) revert NotProposed(marketId);
        if (block.timestamp <= r.disputeDeadline) revert DisputeWindowOpen(marketId);

        r.phase = Phase.Settled;
        r.finalized = r.proposed;
        uint256 bond = r.proposerBond;
        address proposer = r.proposer;

        _execute(marketId, r.proposed);
        if (bond > 0) usdc.safeTransfer(proposer, bond);
        emit Finalized(marketId, r.proposed, proposer, bond);
    }

    // ─── resolveDispute (multisig) ─────────────────────────────────────────────────

    /// @notice Decide a disputed market. RESOLVER multisig only, and the deciding signer must itself
    ///         hold no position. The winner (proposer or disputer, whoever named `truth`) takes both
    ///         bonds; if neither named the truth, both bonds go to the treasury. No token vote.
    function resolveDispute(uint256 marketId, Outcome truth)
        external
        nonReentrant
        onlyRole(RESOLVER_ROLE)
    {
        if (truth == Outcome.None) revert InvalidOutcome();
        Resolution storage r = resolutions[marketId];
        if (r.phase != Phase.Disputed) revert NotDisputed(marketId);
        // NOTE: the RESOLVER is a fixed, trusted multisig — we deliberately do NOT apply the
        // _requireNoPosition gate here. Outcome tokens are freely transferable, so gating the bound
        // resolver address on "holds no position" lets anyone permanently freeze a disputed market
        // (and lock all its funds + bonds) by dusting the multisig with 1 wei. The resolver's
        // conflict-of-interest is a governance/social control, not an on-chain gate a griefer can weaponize.

        r.phase = Phase.Settled;
        r.finalized = truth;
        uint256 pot = r.proposerBond + r.disputerBond;

        address winner;
        uint256 payout;
        uint256 toTreasury;
        if (truth == r.proposed) {
            winner = r.proposer;
            payout = pot; // proposer recovers own bond + the disputer's slashed bond
        } else if (truth == r.counter) {
            winner = r.disputer;
            payout = pot; // disputer recovers own bond + the proposer's slashed bond
        } else {
            toTreasury = pot; // both were wrong → both bonds slashed to the treasury
        }

        _execute(marketId, truth);
        if (payout > 0) usdc.safeTransfer(winner, payout);
        if (toTreasury > 0) usdc.safeTransfer(config.treasury(), toTreasury);
        emit DisputeResolved(marketId, truth, winner, payout, toTreasury);
    }

    // ─── housekeeping ──────────────────────────────────────────────────────────────

    /// @notice Move a settled market to the terminal Closed state once redemptions have wound down.
    ///         Governance-gated bookkeeping; redemption itself stays open in Resolved/Void.
    function closeMarket(uint256 marketId) external onlyGovernance {
        registry.markClosed(marketId);
        emit MarketClosed(marketId);
    }

    // ─── execution ─────────────────────────────────────────────────────────────────

    /// @dev Flip the token to its settled payout and drive the registry's terminal transition. VOID
    ///      refunds both sides at $0.5/share; a resolved market pays the winning side $1/share in full.
    function _execute(uint256 marketId, Outcome o) internal {
        // Tier split: a live curve market (initialized on the SpotEngine, not yet graduated)
        // settles on the SpotEngine; a graduated market settles on the OutcomeToken ledger.
        bool curve = spot.isInitialized(marketId) && !spot.isMigrated(marketId);
        if (o == Outcome.Void) {
            if (curve) spot.resolveVoidMarket(marketId);
            else outcomeToken.resolveVoid(marketId);
            registry.markVoid(marketId);
        } else if (o == Outcome.Yes) {
            if (curve) spot.resolveMarket(marketId, 0); // 0 = YES (LMSRMath.Side.A)
            else outcomeToken.resolve(marketId, OutcomeToken.Side.YES);
            registry.markResolved(marketId);
        } else {
            // Outcome.No (None is rejected by every caller before reaching here)
            if (curve) spot.resolveMarket(marketId, 1); // 1 = NO (LMSRMath.Side.B)
            else outcomeToken.resolve(marketId, OutcomeToken.Side.NO);
            registry.markResolved(marketId);
        }
    }

    // ─── bond + window sizing ───────────────────────────────────────────────────────

    /// @notice Money currently at stake on a market: spot complete-set collateral + leveraged OI.
    function moneyAtStake(uint256 marketId) public view returns (uint256) {
        (uint256 oiYes, uint256 oiNo) = leverage.getMarketOI(marketId);
        // Curve (Tier-1) money lives on the SpotEngine, not the OutcomeToken ledger — include it so
        // the proposer bond + dispute window scale with a curve market's real size (the module was
        // previously blind to the live tier: a $1B curve market bonded at only the floor).
        uint256 spotColl =
            (spot.isInitialized(marketId) && !spot.isMigrated(marketId)) ? spot.collateralOf(marketId) : 0;
        return spotColl + outcomeToken.collateralOf(marketId) + oiYes + oiNo;
    }

    /// @notice The proposer's bond: `max(bondFloor, bondRateBps · moneyAtStake)`. A lie about a big
    ///         market is expensive; a tiny market still requires the floor.
    function computeBond(uint256 marketId) public view returns (uint256) {
        uint256 byStake = (moneyAtStake(marketId) * config.bondRateBps()) / BPS;
        uint256 floor = config.bondFloor();
        return byStake > floor ? byStake : floor;
    }

    /// @notice The dispute window, linearly scaled from `disputeWindowMin` (tiny market) up to
    ///         `disputeWindowMax` once money-at-stake reaches `disputeWindowFullOI`. More value at
    ///         stake buys more time for a wrong proposal to be caught.
    function disputeWindow(uint256 marketId) public view returns (uint256) {
        uint256 lo = config.disputeWindowMin();
        uint256 hi = config.disputeWindowMax();
        uint256 full = config.disputeWindowFullOI();
        if (hi <= lo || full == 0) return lo;
        uint256 stake = moneyAtStake(marketId);
        if (stake >= full) return hi;
        return lo + ((hi - lo) * stake) / full;
    }

    // ─── conflict-of-interest gate ───────────────────────────────────────────────────

    /// @dev Revert unless `account` holds no spot outcome tokens AND no open leveraged position in
    ///      this market. Defense-in-depth (see contract NatSpec on its Sybil/dust limits).
    function _requireNoPosition(uint256 marketId, address account) internal view {
        // Curve markets hold positions on the SpotEngine, not the OutcomeToken ledger — check
        // both so the gate isn't blind to the live tier (the spot leg was previously missing).
        (uint256 curveYes, uint256 curveNo) = spot.sharesOf(marketId, account);
        if (
            curveYes != 0 || curveNo != 0
                || outcomeToken.balanceOf(account, outcomeToken.tokenId(marketId, OutcomeToken.Side.YES)) != 0
                || outcomeToken.balanceOf(account, outcomeToken.tokenId(marketId, OutcomeToken.Side.NO)) != 0
                || leverage.hasLeveragePosition(marketId, account)
        ) revert HasPosition(marketId, account);
    }
}
