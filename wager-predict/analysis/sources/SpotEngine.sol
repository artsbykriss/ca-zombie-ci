// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {Governed} from "../access/Governed.sol";
import {ProtocolConfig} from "../config/ProtocolConfig.sol";
import {LMSRMath} from "../libraries/LMSRMath.sol";
import {PriceAccumulator} from "../libraries/PriceAccumulator.sol";

interface IFeeRouter {
    function route(address creator, uint256 platformAmt, uint256 creatorAmt, uint256 lpAmt) external;
}

interface IMarketRegistry {
    function recordActivity(uint256 id, address trader, uint256 volume) external;
    function getMarketInfo(uint256 id) external view returns (
        address creator, uint8 state, bool featured, uint64 endDate, uint64 createdAt,
        uint256 templateId, uint256 resolutionSourceId, bytes32 questionHash,
        uint256 b, uint256 seed, uint256 validityBond, uint256 distinctTraders
    );
}

/// @title  SpotEngine
/// @notice Tier-1 LMSR spot market (spec §4.1). Each market's liquidity is backed by the
///         **creator-funded seed** handed over by the {MarketRegistry} on listing — the treasury
///         funds nothing. Uses the audited {LMSRMath}; price(YES)+price(NO)=1 holds by
///         construction (the "mirroring" invariant, §4.3). Trade fees are the final 85/50/40/25
///         split (§10): platform/creator/LP route out via the {FeeRouter}; the **depth** slice is
///         retained as the market's reserve and grows `b` via autoExpandB (§4.1). The on-chain
///         {PriceAccumulator} feeds the TWAP (§4.4, retires the poker bot), and the depth-scaled
///         per-block move cap (§4.5) bounds per-block price movement (a speed bump, not a wall).
///
/// @dev    Tier-1 shares live on this engine's internal ledger (NOT the OutcomeToken complete-set
///         ledger, which backs the graduated/order-book tier) — the LMSR→book handoff at
///         graduation is a separate, high-scrutiny step. Settlement/payout is added with the
///         ResolutionModule. Trading is open while `now < endDate`; after that the registry moves
///         the market to Resolving (the two windows are mutually exclusive by time).
contract SpotEngine is Governed, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    using PriceAccumulator for PriceAccumulator.Data;

    bytes32 public constant PAUSE_GUARDIAN_ROLE = keccak256("PAUSE_GUARDIAN_ROLE");
    /// @notice The graduation manager (LmsrAsMaker) — may extract a market's LMSR backing on grad.
    bytes32 public constant GRADUATION_ROLE = keccak256("GRADUATION_ROLE");
    /// @notice The resolution authority (ResolutionModule) — may settle a curve market's outcome.
    ///         Same id as the registry's RESOLUTION_ROLE, so one grant covers both.
    bytes32 public constant RESOLUTION_ROLE = keccak256("RESOLUTION_ROLE");

    uint256 internal constant BPS_DENOM = 10_000;
    uint256 internal constant USDC_SCALE = 1e12;
    uint256 internal constant MIN_TRADE_USDC = 1e6; // $1
    int256 internal constant LN2_18 = 693147180559945309;
    uint256 public constant B_MAX = 100_000e18;
    uint256 public constant MIN_B_INCREMENT = 50e18;

    ProtocolConfig public immutable config;
    IERC20 public immutable usdc;
    address public immutable registry;
    IFeeRouter public immutable feeRouter;

    struct SpotMarket {
        bool initialized;
        bool halted; // early-halt (e.g. early void) — stops trading before endDate
        bool migrated; // graduated onto the OutcomeToken ledger (backing extracted)
        bool resolved; // curve-settled to a YES/NO winner (terminal)
        bool voided; // curve-settled as void (terminal)
        uint8 winner; // 0=YES (Side.A), 1=NO (Side.B); valid iff `resolved`
        uint16 voidYesBps; // YES mark (bps) captured at void; drives void refund split
        uint256 b; // 18-dec
        uint64 endDate;
        address creator;
        uint256 qYes; // 18-dec shares
        uint256 qNo;
        uint256 collateral; // 6-dec USDC backing LMSR payouts (seed + net flows)
        uint256 reserve; // 6-dec depth-fee reserve funding autoExpandB
        uint64 lastTradeBlock;
        uint256 cumMoveBpsInBlock;
        PriceAccumulator.Data acc;
    }

    mapping(uint256 => SpotMarket) internal _markets;
    // marketId => trader => [YES, NO] share balances (18-dec)
    mapping(uint256 => mapping(address => uint256[2])) internal _shares;

    /// @notice Where a settled curve market's surplus (unspent subsidy + depth reserve) is swept.
    ///         Governance-set to the InsuranceFund; falls back to `config.treasury()` while unset.
    address public insuranceFund;

    event MarketInitialized(uint256 indexed id, uint256 b, uint256 seed, uint64 endDate);
    event SharesBought(uint256 indexed id, address indexed buyer, LMSRMath.Side side, uint256 usdcIn, uint256 shares, uint256 newPriceYes);
    event SharesSold(uint256 indexed id, address indexed seller, LMSRMath.Side side, uint256 sharesIn, uint256 netOut, uint256 newPriceYes);
    event BExpanded(uint256 indexed id, uint256 increment, uint256 newB, uint256 reserveConsumed);
    event MarketHaltedEvent(uint256 indexed id);
    event MarketSettled(uint256 indexed id, uint8 winner, uint256 owed6, uint256 surplus6);
    event MarketVoidSettled(uint256 indexed id, uint16 voidYesBps, uint256 owed6, uint256 surplus6);
    event Claimed(uint256 indexed id, address indexed user, uint256 paid6);
    event InsuranceFundSet(address indexed fund);

    error ZeroAddress();
    /// @dev Collateral token is not 6-decimal. USDC_SCALE (1e12) and every `/USDC_SCALE`
    ///      floor-division in this contract assume 6-dec collateral — that truncation is a
    ///      deliberate rounding bias that keeps Σ user claims ≤ the backing pool. An 18-dec
    ///      token (e.g. Binance-Peg USDC/USDT on BSC mainnet) would mis-scale silently.
    error CollateralNotSixDecimals(uint8 got);
    error AlreadyResolved(uint256 id);
    error NotSettled(uint256 id);
    error NothingToClaim(uint256 id);
    error BettingOpen(uint256 id);
    error OnlyRegistry();
    error NotInitialized(uint256 id);
    error AlreadyInitialized(uint256 id);
    error UnderSeeded(uint256 id, uint256 seed, uint256 required);
    error BettingClosed(uint256 id);
    error MarketHalted(uint256 id);
    error TradeTooSmall();
    error SlippageExceeded(uint256 got, uint256 limit);
    error InsufficientShares();
    error BlockMoveCapExceeded(uint256 cumMoveBps, uint256 capBps);

    constructor(address accessController_, address config_, address usdc_, address registry_, address feeRouter_)
        Governed(accessController_)
    {
        if (config_ == address(0) || usdc_ == address(0) || registry_ == address(0) || feeRouter_ == address(0)) {
            revert ZeroAddress();
        }
        config = ProtocolConfig(config_);
        if (IERC20Metadata(usdc_).decimals() != 6) {
            revert CollateralNotSixDecimals(IERC20Metadata(usdc_).decimals());
        }
        usdc = IERC20(usdc_);
        registry = registry_;
        feeRouter = IFeeRouter(feeRouter_);
    }

    // ─── lifecycle (registry-driven) ──────────────────────────────────────────────

    /// @notice Initialize a market's LMSR backing. Called by the registry on listing, which has
    ///         transferred `seed` USDC to this engine immediately prior.
    function initializeMarket(uint256 id, uint256 b, uint64 endDate, uint256 seed) external {
        if (msg.sender != registry) revert OnlyRegistry();
        SpotMarket storage m = _markets[id];
        if (m.initialized) revert AlreadyInitialized(id);
        // I5: solvency rests on collateral_init = seed ≥ C(0,0) = ceil(b·ln2). The registry computes
        // this, but defend the precondition at the trust boundary rather than assume it.
        uint256 minSeed = _seed6(b);
        if (seed < minSeed) revert UnderSeeded(id, seed, minSeed);
        m.initialized = true;
        m.b = b;
        m.endDate = endDate;
        m.collateral = seed;
        (address creator,,,,,,,,,,,) = IMarketRegistry(registry).getMarketInfo(id);
        m.creator = creator;
        m.acc.update(5_000, block.timestamp, config.minObsInterval()); // seed the TWAP at 50%
        emit MarketInitialized(id, b, seed, endDate);
    }

    /// @notice Early-halt a market's trading (registry-driven, e.g. on early void). Distinct from
    ///         the global `whenNotPaused` emergency pause — this stops one market before its endDate.
    function haltMarket(uint256 id) external {
        if (msg.sender != registry) revert OnlyRegistry();
        _markets[id].halted = true;
        emit MarketHaltedEvent(id);
    }

    // ─── graduation handoff (LMSR → OutcomeToken complete-set ledger) ──────────────

    error AlreadyMigrated(uint256 id);
    error NotMigrated(uint256 id);
    event GraduationExit(uint256 indexed id, uint256 collateral, uint256 reserve, uint256 qYes6, uint256 qNo6);

    /// @notice Atomically extract a market's LMSR backing for migration onto the complete-set
    ///         ledger: freeze trading, transfer `collateral + reserve` USDC to the caller (the
    ///         graduation manager), and report the user-share totals in 6-dec. The internal share
    ///         ledger is retained so each user can later claim their migrated shares. Idempotent
    ///         guard (`migrated`) makes a half-migrated market unreachable.
    /// @return collateral6 LMSR collateral (6-dec) — exactly backs `collateral6` complete sets.
    /// @return reserve6    depth reserve (6-dec) — becomes the curve's working capital.
    /// @return qYes6       total user YES shares (6-dec).
    /// @return qNo6        total user NO shares (6-dec).
    function exitForGraduation(uint256 id)
        external
        onlyRole(GRADUATION_ROLE)
        nonReentrant
        returns (uint256 collateral6, uint256 reserve6, uint256 qYes6, uint256 qNo6)
    {
        SpotMarket storage m = _markets[id];
        if (!m.initialized) revert NotInitialized(id);
        if (m.migrated) revert AlreadyMigrated(id);

        m.migrated = true;
        m.halted = true; // no further LMSR trading
        collateral6 = m.collateral;
        reserve6 = m.reserve;
        qYes6 = m.qYes / USDC_SCALE;
        qNo6 = m.qNo / USDC_SCALE;
        m.collateral = 0;
        m.reserve = 0;

        uint256 out = collateral6 + reserve6;
        if (out > 0) usdc.safeTransfer(msg.sender, out);
        emit GraduationExit(id, collateral6, reserve6, qYes6, qNo6);
    }

    /// @notice Consume (zero) a user's migrated LMSR shares and report them in 6-dec, so the
    ///         graduation manager can deliver the equivalent complete-set tokens. Migration-only.
    function consumeMigratedShares(uint256 id, address user)
        external
        onlyRole(GRADUATION_ROLE)
        returns (uint256 yes6, uint256 no6)
    {
        SpotMarket storage m = _markets[id];
        if (!m.migrated) revert NotMigrated(id);
        uint256[2] storage s = _shares[id][user];
        yes6 = s[0] / USDC_SCALE;
        no6 = s[1] / USDC_SCALE;
        s[0] = 0;
        s[1] = 0;
    }

    function isMigrated(uint256 id) external view returns (bool) {
        return _markets[id].migrated;
    }

    // ─── settlement (resolution-driven) ─────────────────────────────────────────────
    //
    // Curve markets settle here (NOT via OutcomeToken — that ledger backs the graduated
    // tier). Solvency is structural: `initializeMarket` enforces seed ≥ ceil(b·ln2) and
    // LMSR's max market-maker loss is exactly b·ln2, so at any state
    //     collateral ≥ q[winner]/USDC_SCALE   (for EITHER winner)
    // i.e. collateral ≥ max(qYes,qNo)/USDC_SCALE. Winners are therefore always payable in
    // full ($1/share) with a non-negative surplus = the unspent subsidy + depth reserve,
    // which is swept to the InsuranceFund. The ResolutionModule (RESOLUTION_ROLE) drives
    // these; per-holder `claimWinnings` is permissionless.

    /// @notice Set the surplus sink (InsuranceFund). Governance-only. Until set, surplus
    ///         falls back to `config.treasury()`.
    function setInsuranceFund(address fund) external onlyGovernance {
        insuranceFund = fund;
        emit InsuranceFundSet(fund);
    }

    function _sink() internal view returns (address) {
        address f = insuranceFund;
        return f != address(0) ? f : config.treasury();
    }

    /// @notice Settle a curve market to a YES/NO winner. Keeps exactly the winners' claim
    ///         pool (`q[winner]/USDC_SCALE`) and sweeps the surplus to the InsuranceFund.
    function resolveMarket(uint256 id, LMSRMath.Side winner) external onlyRole(RESOLUTION_ROLE) nonReentrant {
        SpotMarket storage m = _markets[id];
        if (!m.initialized) revert NotInitialized(id);
        if (m.migrated) revert AlreadyMigrated(id);
        if (m.resolved || m.voided) revert AlreadyResolved(id);
        if (block.timestamp < m.endDate) revert BettingOpen(id);

        m.halted = true;
        m.resolved = true;
        m.winner = uint8(winner);

        uint256 owed6 = (winner == LMSRMath.Side.A ? m.qYes : m.qNo) / USDC_SCALE;
        uint256 pool = m.collateral + m.reserve;
        uint256 surplus6 = pool > owed6 ? pool - owed6 : 0; // ≥ reserve by solvency
        m.collateral = pool - surplus6; // == owed6 (the claim pool that stays backed)
        m.reserve = 0;

        if (surplus6 > 0) usdc.safeTransfer(_sink(), surplus6);
        emit MarketSettled(id, uint8(winner), owed6, surplus6);
    }

    /// @notice Settle a curve market as VOID — both sides refund at the curve mark
    ///         (YES at price `p`, NO at `1−p`). Solvent because
    ///         qYes·p + qNo·(1−p) ≤ max(qYes,qNo) ≤ collateral. No endDate gate (void may be
    ///         early, e.g. an unresolvable market).
    function resolveVoidMarket(uint256 id) external onlyRole(RESOLUTION_ROLE) nonReentrant {
        SpotMarket storage m = _markets[id];
        if (!m.initialized) revert NotInitialized(id);
        if (m.migrated) revert AlreadyMigrated(id);
        if (m.resolved || m.voided) revert AlreadyResolved(id);

        m.halted = true;
        m.voided = true;
        uint256 pYes = LMSRMath.priceABps(m.qYes, m.qNo, m.b); // 0..BPS_DENOM (priceABps clamps)
        if (pYes > BPS_DENOM) pYes = BPS_DENOM; // defensive: guarantees the uint16 cast + math stay exact
        m.voidYesBps = uint16(pYes);

        // Fold the BPS and USDC_SCALE divisions into ONE final truncation to minimise
        // rounding dust (and keep Σ per-user claims ≤ owed6 by floor distributivity).
        uint256 owed6 = (m.qYes * pYes + m.qNo * (BPS_DENOM - pYes)) / (BPS_DENOM * USDC_SCALE);
        uint256 pool = m.collateral + m.reserve;
        uint256 surplus6 = pool > owed6 ? pool - owed6 : 0;
        m.collateral = pool - surplus6;
        m.reserve = 0;

        if (surplus6 > 0) usdc.safeTransfer(_sink(), surplus6);
        emit MarketVoidSettled(id, uint16(pYes), owed6, surplus6);
    }

    /// @notice Redeem the caller's settled position. Resolved: winning side pays $1/share.
    ///         Voided: each side pays at the captured void mark. Zeroes both sides (the loser
    ///         side is worthless), so it is double-claim-proof.
    function claimWinnings(uint256 id) external nonReentrant returns (uint256 paid6) {
        SpotMarket storage m = _markets[id];
        if (!m.resolved && !m.voided) revert NotSettled(id);
        uint256[2] storage s = _shares[id][msg.sender];
        uint256 yes = s[0];
        uint256 no = s[1];

        if (m.resolved) {
            paid6 = (m.winner == uint8(LMSRMath.Side.A) ? yes : no) / USDC_SCALE;
        } else {
            uint256 p = m.voidYesBps;
            paid6 = (yes * p + no * (BPS_DENOM - p)) / (BPS_DENOM * USDC_SCALE);
        }
        if (paid6 == 0) revert NothingToClaim(id);

        s[0] = 0;
        s[1] = 0;
        m.collateral -= paid6; // checked: claim pool was sized to cover all winners
        usdc.safeTransfer(msg.sender, paid6);
        emit Claimed(id, msg.sender, paid6);
    }

    // settlement views
    function isInitialized(uint256 id) external view returns (bool) {
        return _markets[id].initialized;
    }

    function isResolved(uint256 id) external view returns (bool) {
        return _markets[id].resolved;
    }

    function isVoided(uint256 id) external view returns (bool) {
        return _markets[id].voided;
    }

    function resolvedWinner(uint256 id) external view returns (uint8) {
        return _markets[id].winner;
    }

    /// @notice A curve market's USDC collateral (6-dec) — the money-at-stake the ResolutionModule
    ///         sizes the proposer bond + dispute window against (it was previously blind to the
    ///         curve tier, reading only the OutcomeToken ledger).
    function collateralOf(uint256 id) external view returns (uint256) {
        return _markets[id].collateral;
    }

    /// @notice USDC `user` can currently claim on a settled market (0 if unsettled / nothing).
    function claimableOf(uint256 id, address user) external view returns (uint256 paid6) {
        SpotMarket storage m = _markets[id];
        if (!m.resolved && !m.voided) return 0;
        uint256[2] storage s = _shares[id][user];
        if (m.resolved) {
            paid6 = (m.winner == uint8(LMSRMath.Side.A) ? s[0] : s[1]) / USDC_SCALE;
        } else {
            uint256 p = m.voidYesBps;
            paid6 = (s[0] * p + s[1] * (BPS_DENOM - p)) / (BPS_DENOM * USDC_SCALE);
        }
    }

    // ─── trading ──────────────────────────────────────────────────────────────────

    function buyShares(uint256 id, LMSRMath.Side side, uint256 usdcIn, uint256 minSharesOut)
        external
        nonReentrant
        whenNotPaused
        returns (uint256 shares)
    {
        SpotMarket storage m = _liveMarket(id);
        if (usdcIn < MIN_TRADE_USDC) revert TradeTooSmall();

        usdc.safeTransferFrom(msg.sender, address(this), usdcIn);
        (uint256 platformAmt, uint256 creatorAmt, uint256 depthAmt, uint256 lpAmt) = _slices(usdcIn);
        uint256 netIn = usdcIn - platformAmt - creatorAmt - depthAmt - lpAmt;

        uint256 priceBefore = LMSRMath.priceABps(m.qYes, m.qNo, m.b);
        shares = LMSRMath.deltaSharesForBuy(side, m.qYes, m.qNo, netIn * USDC_SCALE, m.b);
        if (shares < minSharesOut) revert SlippageExceeded(shares, minSharesOut);

        if (side == LMSRMath.Side.A) m.qYes += shares;
        else m.qNo += shares;
        _shares[id][msg.sender][uint256(side)] += shares;
        m.collateral += netIn;
        m.reserve += depthAmt;

        uint256 priceAfter = LMSRMath.priceABps(m.qYes, m.qNo, m.b);
        _accrueBlockMove(m, priceBefore, priceAfter);
        m.acc.update(uint32(priceAfter), block.timestamp, config.minObsInterval());

        _routeFees(m.creator, platformAmt, creatorAmt, lpAmt);
        _maybeExpandB(id, m);
        IMarketRegistry(registry).recordActivity(id, msg.sender, usdcIn);
        emit SharesBought(id, msg.sender, side, usdcIn, shares, priceAfter);
    }

    function sellShares(uint256 id, LMSRMath.Side side, uint256 sharesIn, uint256 minUsdcOut)
        external
        nonReentrant
        whenNotPaused
        returns (uint256 netOut)
    {
        SpotMarket storage m = _liveMarket(id);
        uint256 held = _shares[id][msg.sender][uint256(side)];
        if (sharesIn == 0 || sharesIn > held) revert InsufficientShares();

        uint256 priceBefore = LMSRMath.priceABps(m.qYes, m.qNo, m.b);
        uint256 cBefore = LMSRMath.cost(m.qYes, m.qNo, m.b);
        uint256 newQYes = side == LMSRMath.Side.A ? m.qYes - sharesIn : m.qYes;
        uint256 newQNo = side == LMSRMath.Side.B ? m.qNo - sharesIn : m.qNo;
        uint256 cAfter = LMSRMath.cost(newQYes, newQNo, m.b);
        uint256 grossOut = (cBefore - cAfter) / USDC_SCALE;

        (uint256 platformAmt, uint256 creatorAmt, uint256 depthAmt, uint256 lpAmt) = _slices(grossOut);
        netOut = grossOut - platformAmt - creatorAmt - depthAmt - lpAmt;
        if (netOut < minUsdcOut) revert SlippageExceeded(netOut, minUsdcOut);

        m.qYes = newQYes;
        m.qNo = newQNo;
        _shares[id][msg.sender][uint256(side)] = held - sharesIn;
        m.collateral -= grossOut;
        m.reserve += depthAmt;

        uint256 priceAfter = LMSRMath.priceABps(m.qYes, m.qNo, m.b);
        _accrueBlockMove(m, priceBefore, priceAfter);
        m.acc.update(uint32(priceAfter), block.timestamp, config.minObsInterval());

        usdc.safeTransfer(msg.sender, netOut);
        _routeFees(m.creator, platformAmt, creatorAmt, lpAmt);
        _maybeExpandB(id, m);
        IMarketRegistry(registry).recordActivity(id, msg.sender, grossOut);
        emit SharesSold(id, msg.sender, side, sharesIn, netOut, priceAfter);
    }

    // ─── quotes (views) ────────────────────────────────────────────────────────────

    function getBuyQuote(uint256 id, LMSRMath.Side side, uint256 usdcIn)
        external
        view
        returns (uint256 shares, uint256 netIn)
    {
        SpotMarket storage m = _markets[id];
        (uint256 p, uint256 c, uint256 d, uint256 l) = _slices(usdcIn);
        netIn = usdcIn - p - c - d - l;
        shares = LMSRMath.deltaSharesForBuy(side, m.qYes, m.qNo, netIn * USDC_SCALE, m.b);
    }

    function getSellQuote(uint256 id, LMSRMath.Side side, uint256 sharesIn)
        external
        view
        returns (uint256 netOut, uint256 grossOut)
    {
        SpotMarket storage m = _markets[id];
        uint256 cBefore = LMSRMath.cost(m.qYes, m.qNo, m.b);
        uint256 newQYes = side == LMSRMath.Side.A ? m.qYes - sharesIn : m.qYes;
        uint256 newQNo = side == LMSRMath.Side.B ? m.qNo - sharesIn : m.qNo;
        grossOut = (cBefore - LMSRMath.cost(newQYes, newQNo, m.b)) / USDC_SCALE;
        (uint256 p, uint256 c, uint256 d, uint256 l) = _slices(grossOut);
        netOut = grossOut - p - c - d - l;
    }

    // ─── internal ────────────────────────────────────────────────────────────────

    function _liveMarket(uint256 id) internal view returns (SpotMarket storage m) {
        m = _markets[id];
        if (!m.initialized) revert NotInitialized(id);
        if (m.halted) revert MarketHalted(id);
        if (block.timestamp >= m.endDate) revert BettingClosed(id);
    }

    function _slices(uint256 amount)
        internal
        view
        returns (uint256 platformAmt, uint256 creatorAmt, uint256 depthAmt, uint256 lpAmt)
    {
        platformAmt = (amount * config.platformBps()) / BPS_DENOM;
        creatorAmt = (amount * config.creatorBps()) / BPS_DENOM;
        depthAmt = (amount * config.depthBps()) / BPS_DENOM;
        lpAmt = (amount * config.lpBps()) / BPS_DENOM;
    }

    /// @dev Depth-scaled per-block move cap (§4.5): bound the TOTAL |Δprice| within a block,
    ///      summed across trades, so a split-trade slam can't dodge it. cap loosens with `b`.
    function _accrueBlockMove(SpotMarket storage m, uint256 priceBefore, uint256 priceAfter) internal {
        uint256 move = priceAfter > priceBefore ? priceAfter - priceBefore : priceBefore - priceAfter;
        if (move == 0) return;
        uint256 cap = config.blockMoveCapBps(m.b);
        if (m.lastTradeBlock == block.number) {
            uint256 cum = m.cumMoveBpsInBlock + move;
            if (cum > cap) revert BlockMoveCapExceeded(cum, cap);
            m.cumMoveBpsInBlock = cum;
        } else {
            if (move > cap) revert BlockMoveCapExceeded(move, cap);
            m.lastTradeBlock = uint64(block.number);
            m.cumMoveBpsInBlock = move;
        }
    }

    function _routeFees(address creator, uint256 platformAmt, uint256 creatorAmt, uint256 lpAmt) internal {
        uint256 outbound = platformAmt + creatorAmt + lpAmt;
        if (outbound == 0) return;
        usdc.safeTransfer(address(feeRouter), outbound);
        feeRouter.route(creator, platformAmt, creatorAmt, lpAmt);
    }

    /// @dev Grow `b` from the depth reserve at a rate-capped step (§4.1). Preserves the
    ///      ~ln2/depthFeeRate (≈ $173) volume-per-unit-of-b relationship: a `Δb` increment
    ///      consumes exactly `ceil(Δb·ln2)` USDC of reserve.
    function _maybeExpandB(uint256 id, SpotMarket storage m) internal {
        if (m.b >= B_MAX) return;
        uint256 inc = (m.b * config.autoExpandRateCapBps()) / BPS_DENOM;
        if (inc < MIN_B_INCREMENT) inc = MIN_B_INCREMENT;
        if (m.b + inc > B_MAX) inc = B_MAX - m.b;
        uint256 required = _seed6(inc);
        if (m.reserve < required) return; // accumulate more reserve first
        m.reserve -= required;
        m.collateral += required;
        m.b += inc;
        emit BExpanded(id, inc, m.b, required);
    }

    function _seed6(uint256 b) internal pure returns (uint256 s) {
        uint256 seed18 = uint256((int256(b) * LN2_18) / 1e18);
        s = seed18 / USDC_SCALE;
        if (s * USDC_SCALE < seed18) s += 1;
    }

    // ─── views ────────────────────────────────────────────────────────────────────

    function getSpotMarket(uint256 id)
        external
        view
        returns (bool initialized, uint256 b, uint64 endDate, uint256 qYes, uint256 qNo, uint256 collateral, uint256 reserve)
    {
        SpotMarket storage m = _markets[id];
        return (m.initialized, m.b, m.endDate, m.qYes, m.qNo, m.collateral, m.reserve);
    }

    function oddsBps(uint256 id) external view returns (uint256 priceYes, uint256 priceNo) {
        SpotMarket storage m = _markets[id];
        return LMSRMath.oddsBps(m.qYes, m.qNo, m.b);
    }

    function sharesOf(uint256 id, address user) external view returns (uint256 yes, uint256 no) {
        uint256[2] storage s = _shares[id][user];
        return (s[0], s[1]);
    }

    function twap(uint256 id) external view returns (uint256 twapBps, uint8 status) {
        SpotMarket storage m = _markets[id];
        (uint256 t, PriceAccumulator.TwapStatus st) =
            m.acc.consult(config.twapWindow(), config.gradWindow(), block.timestamp);
        return (t, uint8(st));
    }

    // ─── curve mark exposure (inert forward-compat for a future curve-priced leverage release) ──────
    // Pure views — they add NO SLOAD/state/behavior to any existing path. A later curve-mark module
    // (an IMarkSource adapter for leverage) reads the live curve price via {oddsBps}, the last-trade
    // time via {curveLastUpdate} for its own tight freshness gate, and a windowed curve TWAP via
    // {curveTwap} with a caller-supplied `maxAge` — NOT the display-oriented gradWindow {twap} bakes in.

    /// @notice Timestamp of the curve's last recorded price (the accumulator's `lastUpdate`); `0` if
    ///         the market was never initialized/traded. For an external freshness gate.
    function curveLastUpdate(uint256 id) external view returns (uint64) {
        return _markets[id].acc.lastUpdate;
    }

    /// @notice Curve TWAP over `twapWindow` with a CALLER-supplied staleness horizon `maxAge`, so a
    ///         leverage mark can demand tight freshness instead of the lax gradWindow used by {twap}.
    function curveTwap(uint256 id, uint256 maxAge) external view returns (uint256 twapBps, uint8 status) {
        SpotMarket storage m = _markets[id];
        (uint256 t, PriceAccumulator.TwapStatus st) = m.acc.consult(config.twapWindow(), maxAge, block.timestamp);
        return (t, uint8(st));
    }

    // ─── pause ─────────────────────────────────────────────────────────────────────

    /// @dev Resume (H5): guardian OR governance, so a false pause has a fast guardian recovery while
    ///      governance is retained as a backstop (the unpause set is a superset of the pause set —
    ///      no stuck-paused path). pause stays guardian-only; nothing fund/param-moving uses this.
    modifier onlyPauseController() {
        if (
            !accessController.hasRole(PAUSE_GUARDIAN_ROLE, msg.sender)
                && !accessController.hasRole(GOVERNANCE_ROLE, msg.sender)
        ) revert Unauthorized(PAUSE_GUARDIAN_ROLE, msg.sender);
        _;
    }

    function pause() external onlyRole(PAUSE_GUARDIAN_ROLE) {
        _pause();
    }

    function unpause() external onlyPauseController {
        _unpause();
    }
}
