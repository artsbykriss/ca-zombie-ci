// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Governed} from "../access/Governed.sol";
import {OutcomeToken} from "../tokens/OutcomeToken.sol";
import {LMSRMath} from "../libraries/LMSRMath.sol";

interface ISpotEngineGrad {
    function exitForGraduation(uint256 id)
        external
        returns (uint256 collateral6, uint256 reserve6, uint256 qYes6, uint256 qNo6);
    function consumeMigratedShares(uint256 id, address user) external returns (uint256 yes6, uint256 no6);
    function getSpotMarket(uint256 id) external view returns (
        bool initialized, uint256 b, uint64 endDate, uint256 qYes, uint256 qNo, uint256 collateral, uint256 reserve
    );
}

interface IRegistryState {
    function marketState(uint256 id) external view returns (uint8);
}

/// @notice Optional, post-deploy-settable gate on the actual tier-promotion (migration onto the book).
///         Lets a future policy require team/role approval to migrate — e.g. to keep wash-graduated junk
///         markets (M4) off the book tier once "Graduated" carries more weight (leverage eligibility) —
///         WITHOUT committing to it now. Inert at launch (`migrationGate == address(0)` ⇒ migration stays
///         permissionless, today's exact behavior). Cannot be added to this immutable contract later.
interface IMigrationGate {
    function canMigrate(uint256 marketId, address caller) external view returns (bool);
}

/// @title  LmsrAsMaker
/// @notice The bridge where the two accounting worlds meet (spec §4.2). At graduation it migrates a
///         market's Tier-1 LMSR backing onto the complete-set {OutcomeToken} ledger, then holds the
///         curve's residual shares as inventory so the graduated book is never empty before the MMs
///         quote — resting them as orders via EIP-1271.
///
/// @dev    THE MIGRATION IS SOLVENCY-PRESERVING BY CONSTRUCTION:
///         The LMSR market has `Y` user-YES + `N` user-NO shares (asymmetric) backed by `C` USDC,
///         where LMSR guarantees `C ≥ max(Y, N)`. We mint exactly `C` complete sets (= `C` YES +
///         `C` NO) backed by exactly `C` USDC pulled from the extracted collateral, all to this
///         contract. Users then *claim* (transfer, supply-neutral) their `(y, n)`; the curve keeps
///         the remainder `(C−Y)` YES + `(C−N)` NO (both ≥ 0). Therefore at all times:
///             YES_supply == NO_supply == collateral == C   (the OutcomeToken structural invariant)
///         No share is ever unbacked, total collateral is conserved across the transition (C USDC
///         in → C of backing), and winners still redeem at exactly $1 (`C` winning shares ≤ `C`
///         collateral). The migrate step is atomic (one tx: extract + mint + mark), so a
///         half-migrated market is unreachable. Claim rounding (18→6-dec floor) leaves dust with
///         the curve — the system is only ever over-collateralized, never under.
contract LmsrAsMaker is Governed, ERC1155Holder, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bytes4 internal constant EIP1271_MAGIC = 0x1626ba7e;
    uint8 internal constant STATE_GRADUATED = 4; // MarketRegistry.MarketState.Graduated

    ISpotEngineGrad public immutable spotEngine;
    OutcomeToken public immutable outcomeToken;
    IRegistryState public immutable registry;
    address public immutable exchange;
    IERC20 public immutable usdc;

    /// @notice Off-chain signer that authorizes the curve's resting orders (EIP-1271). The pricing
    ///         strategy is off-chain; this key is the curve's on-chain authorization.
    address public orderSigner;

    mapping(uint256 => bool) public migrated;
    mapping(uint256 => uint256) public migratedCollateral; // C (6-dec) per market

    uint256 internal constant USDC_SCALE = 1e12; // 6-dec USDC ↔ 18-dec LMSR shares

    /// @notice R1 — the curve's deterministic LMSR AMM state per graduated market. Initialized from the
    ///         extracted graduation state; updated on every curve trade. `priceABps(qYes,qNo,b)` is the
    ///         manipulation-costly on-chain price the leverage liquidation mark (2a) anchors against:
    ///         moving it requires real LMSR-cost trading, and the SAME LMSR accounting that prices it
    ///         keeps it solvent (`collateral·1e12 ≥ max(qYes,qNo)`, the audited SpotEngine property,
    ///         continued post-migration). Layer-1 backing (collateralOf == supply) is the OutcomeToken's
    ///         own proven guarantee (mint/merge preserve it).
    struct CurveAMM {
        uint256 qYes; // 18-dec LMSR quantity
        uint256 qNo;  // 18-dec
        uint256 b;    // 18-dec depth
        uint256 collateral; // 6-dec USDC backing the LMSR (grows on buy, shrinks on sell)
        uint64 lastFillTs;  // freshness for the 2a mark
        bool live;
    }
    mapping(uint256 => CurveAMM) public amm;

    /// @notice The settlement integration allowed to drive curve trades (pairs each LMSR accounting
    ///         update with the real OutcomeToken/USDC settlement). `address(0)` ⇒ inert (uncallable).
    address public curveRouter;

    /// @notice Optional gate on migration (see {IMigrationGate}). `address(0)` ⇒ inert (permissionless
    ///         migration — the launch default). Forward-compat hook for gating promotion later (M4);
    ///         cannot be added to this immutable contract afterwards.
    address public migrationGate;

    event Migrated(uint256 indexed id, uint256 collateral, uint256 reserve, uint256 userYes, uint256 userNo);
    event SharesClaimed(uint256 indexed id, address indexed user, uint256 yes, uint256 no);
    event OrderSignerSet(address indexed signer);
    event MigrationGateSet(address indexed gate);
    event CurveTraded(uint256 indexed id, bool buy, LMSRMath.Side side, uint256 usdc, uint256 shares, uint256 priceYesBps);
    event CurveRouterSet(address indexed router);

    error ZeroAddress();
    /// @dev Collateral token is not 6-decimal. USDC_SCALE (1e12) and every `/USDC_SCALE`
    ///      floor-division in this contract assume 6-dec collateral — that truncation is a
    ///      deliberate rounding bias that keeps Σ user claims ≤ the backing pool. An 18-dec
    ///      token (e.g. Binance-Peg USDC/USDT on BSC mainnet) would mis-scale silently.
    error CollateralNotSixDecimals(uint8 got);
    error CurveNotLive(uint256 id);
    error CurveInsufficientShares(uint256 id);
    error CurveInsufficientReserve(uint256 id);
    error OnlyCurveRouter();
    error NotGraduated(uint256 id);
    error AlreadyMigrated(uint256 id);
    error NotMigratedYet(uint256 id);
    error MigrationBlocked(uint256 id);
    error UnderCollateralizedMigration(uint256 id);

    constructor(
        address accessController_,
        address spotEngine_,
        address outcomeToken_,
        address registry_,
        address exchange_,
        address usdc_
    ) Governed(accessController_) {
        if (
            spotEngine_ == address(0) || outcomeToken_ == address(0) || registry_ == address(0)
                || exchange_ == address(0) || usdc_ == address(0)
        ) revert ZeroAddress();
        spotEngine = ISpotEngineGrad(spotEngine_);
        outcomeToken = OutcomeToken(outcomeToken_);
        registry = IRegistryState(registry_);
        exchange = exchange_;
        if (IERC20Metadata(usdc_).decimals() != 6) {
            revert CollateralNotSixDecimals(IERC20Metadata(usdc_).decimals());
        }
        usdc = IERC20(usdc_);

        // Let the exchange settle the curve's resting orders against its inventory.
        OutcomeToken(outcomeToken_).setApprovalForAll(exchange_, true);
        IERC20(usdc_).forceApprove(exchange_, type(uint256).max);
    }

    function setOrderSigner(address signer) external onlyGovernance {
        orderSigner = signer;
        emit OrderSignerSet(signer);
    }

    /// @notice Set (or clear) the optional migration gate (governance). `address(0)` is the inert state
    ///         — DELIBERATELY accepted (unlike most setters): it is both the launch default and the
    ///         recovery path if an activated gate misbehaves. Not a missing zero-address check.
    function setMigrationGate(address gate) external onlyGovernance {
        migrationGate = gate;
        emit MigrationGateSet(gate);
    }

    // ─── graduation migration (atomic) ─────────────────────────────────────────────

    /// @notice Migrate a graduated market's LMSR backing onto the complete-set ledger. Permissionless
    ///         once the market is Graduated — the accounting is fixed by the extracted state.
    function migrate(uint256 id) external {
        if (migrated[id]) revert AlreadyMigrated(id);
        if (registry.marketState(id) != STATE_GRADUATED) revert NotGraduated(id);

        // Optional promotion gate (inert when unset → permissionless, today's behavior). Fail-CLOSED:
        // an activated gate that returns false (or reverts) blocks migration — the safe direction; the
        // market simply stays on the curve, and governance can reset the gate to address(0) to recover.
        address gate = migrationGate;
        if (gate != address(0) && !IMigrationGate(gate).canMigrate(id, msg.sender)) revert MigrationBlocked(id);

        (uint256 c6, uint256 r6, uint256 y6, uint256 n6) = spotEngine.exitForGraduation(id);
        // I8: enforce the graduation-conservation precondition `C ≥ max(Y, N)` that solvency rests on
        // (LMSR guarantees it; we no longer merely ASSUME it). If it were ever violated, minting only
        // `c6` sets would leave the winning side under-backed — so fail-safe: revert the migration.
        if (c6 < y6 || c6 < n6) revert UnderCollateralizedMigration(id);
        // c6 + r6 USDC received. Mint exactly c6 complete sets (= c6 USDC of backing) to this curve.
        migrated[id] = true;
        migratedCollateral[id] = c6;
        if (c6 > 0) {
            usdc.forceApprove(address(outcomeToken), c6);
            outcomeToken.mintCompleteSet(id, address(this), c6);
        }

        // R1: seed the curve's deterministic LMSR AMM from the extracted graduation state. The 18-dec
        // (qYes,qNo,b) come from the spot market (still readable post-exit); collateral = c6. The
        // SpotEngine invariant guarantees `collateral·1e12 ≥ max(qYes,qNo)` holds at this seed, and the
        // identical LMSR accounting (below) preserves it through every post-migration curve trade.
        (, uint256 b18, , uint256 qy18, uint256 qn18, , ) = spotEngine.getSpotMarket(id);
        amm[id] = CurveAMM({ qYes: qy18, qNo: qn18, b: b18, collateral: c6, lastFillTs: uint64(block.timestamp), live: true });

        emit Migrated(id, c6, r6, y6, n6);
    }

    /// @notice Claim the complete-set tokens equivalent to your migrated LMSR position. A pure
    ///         transfer from the curve's inventory — supply-neutral, so solvency is untouched.
    function claimMigratedShares(uint256 id) external {
        if (!migrated[id]) revert NotMigratedYet(id);
        (uint256 yes6, uint256 no6) = spotEngine.consumeMigratedShares(id, msg.sender);
        if (yes6 > 0) {
            outcomeToken.safeTransferFrom(address(this), msg.sender, outcomeToken.tokenId(id, OutcomeToken.Side.YES), yes6, "");
        }
        if (no6 > 0) {
            outcomeToken.safeTransferFrom(address(this), msg.sender, outcomeToken.tokenId(id, OutcomeToken.Side.NO), no6, "");
        }
        emit SharesClaimed(id, msg.sender, yes6, no6);
    }

    // ─── R1: the curve's deterministic LMSR AMM (post-migration price anchor for 2a) ────────────────
    // These maintain the curve's LMSR accounting (qYes,qNo,b,collateral) EXACTLY as the audited
    // SpotEngine does, so `collateral·1e12 ≥ max(qYes,qNo)` is preserved by the same math (proven by
    // invariant_curveSolventPostMigration). Gated to `curveRouter` — the settlement integration that
    // pairs each accounting update with the real OutcomeToken complete-set settlement + USDC flow
    // (the Layer-1 backing of which is the OutcomeToken's own proven guarantee). Default router 0 ⇒
    // inert (uncallable) until governance wires it.

    function setCurveRouter(address router) external onlyGovernance {
        curveRouter = router; // address(0) = inert; not a missing zero-check
        emit CurveRouterSet(router);
    }

    /// @notice Buy `usdcIn6` (6-dec) of `side` for `taker`. Real settlement: pull USDC, deliver the
    ///         OutcomeToken shares from inventory (minting complete sets when short — reserve-guarded),
    ///         and advance the LMSR accounting. Returns the delivered shares (6-dec).
    function curveBuy(uint256 id, LMSRMath.Side side, uint256 usdcIn6, address taker)
        external
        nonReentrant
        returns (uint256 shares6)
    {
        if (msg.sender != curveRouter) revert OnlyCurveRouter();
        CurveAMM storage a = amm[id];
        if (!a.live) revert CurveNotLive(id);

        usdc.safeTransferFrom(taker, address(this), usdcIn6); // pull payment
        uint256 shares18 = LMSRMath.deltaSharesForBuy(side, a.qYes, a.qNo, usdcIn6 * USDC_SCALE, a.b);
        shares6 = shares18 / USDC_SCALE; // 6-dec deliverable (rounds down ⇒ in the curve's favor)

        OutcomeToken.Side otSide = side == LMSRMath.Side.A ? OutcomeToken.Side.YES : OutcomeToken.Side.NO;
        uint256 tid = outcomeToken.tokenId(id, otSide);
        uint256 inv = outcomeToken.balanceOf(address(this), tid);
        if (inv < shares6) {
            uint256 mint6 = shares6 - inv; // mint complete sets to cover the shortfall
            if (usdc.balanceOf(address(this)) < mint6) revert CurveInsufficientReserve(id); // RESERVE GUARD
            usdc.forceApprove(address(outcomeToken), mint6);
            outcomeToken.mintCompleteSet(id, address(this), mint6); // collateralOf += mint6, both supplies += mint6
        }
        if (shares6 > 0) outcomeToken.safeTransferFrom(address(this), taker, tid, shares6, "");

        // advance the LMSR accounting on the 6-dec-aligned delivered amount (conservative)
        uint256 dq = shares6 * USDC_SCALE;
        if (side == LMSRMath.Side.A) a.qYes += dq;
        else a.qNo += dq;
        a.collateral += usdcIn6; // LMSR bankroll grows by the payment
        a.lastFillTs = uint64(block.timestamp);
        emit CurveTraded(id, true, side, usdcIn6, shares6, LMSRMath.priceABps(a.qYes, a.qNo, a.b));
    }

    /// @notice Sell `shares6` (6-dec) of `side` from `taker` to the curve. Real settlement: pull the
    ///         shares into inventory, pay the LMSR gross USDC (reserve-guarded), advance the accounting.
    function curveSell(uint256 id, LMSRMath.Side side, uint256 shares6, address taker)
        external
        nonReentrant
        returns (uint256 grossOut6)
    {
        if (msg.sender != curveRouter) revert OnlyCurveRouter();
        CurveAMM storage a = amm[id];
        if (!a.live) revert CurveNotLive(id);

        uint256 dq = shares6 * USDC_SCALE;
        uint256 qy = a.qYes;
        uint256 qn = a.qNo;
        if (side == LMSRMath.Side.A) {
            if (dq > qy) revert CurveInsufficientShares(id);
            qy -= dq;
        } else {
            if (dq > qn) revert CurveInsufficientShares(id);
            qn -= dq;
        }
        grossOut6 = (LMSRMath.cost(a.qYes, a.qNo, a.b) - LMSRMath.cost(qy, qn, a.b)) / USDC_SCALE;
        if (usdc.balanceOf(address(this)) < grossOut6) revert CurveInsufficientReserve(id); // RESERVE GUARD

        OutcomeToken.Side otSide = side == LMSRMath.Side.A ? OutcomeToken.Side.YES : OutcomeToken.Side.NO;
        outcomeToken.safeTransferFrom(taker, address(this), outcomeToken.tokenId(id, otSide), shares6, ""); // pull shares
        usdc.safeTransfer(taker, grossOut6); // pay the taker

        a.qYes = qy;
        a.qNo = qn;
        a.collateral -= grossOut6; // never more than the cost-function delta ⇒ stays ≥ max(q)
        a.lastFillTs = uint64(block.timestamp);
        emit CurveTraded(id, false, side, grossOut6, shares6, LMSRMath.priceABps(a.qYes, a.qNo, a.b));
    }

    /// @notice The curve's on-chain LMSR YES price (bps) + its freshness — the R1 reference the 2a
    ///         attested mark anchors against. Manipulation-costly: moving it requires LMSR-cost trading.
    function curvePriceBps(uint256 id) external view returns (uint256 priceYesBps, uint64 lastFillTs) {
        CurveAMM storage a = amm[id];
        return (LMSRMath.priceABps(a.qYes, a.qNo, a.b), a.lastFillTs);
    }

    // ─── EIP-1271: authorize the curve's resting orders ────────────────────────────

    /// @notice Validate an order hash signed by the curve's `orderSigner` (EIP-1271). Lets the
    ///         {ExchangeSettlement} treat this contract as a resting maker (the "LMSR as orders"
    ///         bridge), settling against the inventory above while the pricing strategy is off-chain.
    function isValidSignature(bytes32 hash, bytes calldata signature) external view returns (bytes4) {
        address signer = orderSigner;
        if (signer != address(0) && ECDSA.recover(hash, signature) == signer) {
            return EIP1271_MAGIC;
        }
        return 0xffffffff;
    }
}
