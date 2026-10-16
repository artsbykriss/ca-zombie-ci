// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {LPFeeLibrary} from "v4-core/src/libraries/LPFeeLibrary.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";
import {AccessManaged} from "@openzeppelin/contracts/access/manager/AccessManaged.sol";

/// @title FablesBaseHook
/// @notice Singleton dynamic-fee hook base: per-pool fee caps, an autonomous per-pool fee
///         supplied by the inheriting contract, an optional per-pool directional premium,
///         and a TTL-bounded two-sided poked override on top.
/// @dev The fee resolves per swap DIRECTION as: the poked side while fresh and non-zero,
///      otherwise the autonomous fee plus the direction's premium; always clamped to the
///      pool's cap. A poked side fully replaces the autonomous fee AND the premium (it can
///      lower as well as raise) and expires on its own, so the system never depends on an
///      operator but can always be corrected by one. Symmetric pools are the zero-config
///      default: premium 0 plus equal poke sides reproduce the single-fee behavior exactly.
///      Uses only the fee-override return of `beforeSwap` — no delta flags.
abstract contract FablesBaseHook is AccessManaged {
    using LPFeeLibrary for uint24;
    using PoolIdLibrary for PoolKey;

    error NotPoolManager();
    error NotDynamicFeePool();
    error NativeNotSupported();
    error PoolNotConfigured();
    error FeeAboveCap();
    error InvalidTtl();
    error InvalidMaxFee();
    error FeeBelowFloor();
    error PremiumExceedsFeeBand();
    error EmptyPoke();

    event FeePoked(PoolId indexed poolId, uint24 fee0For1, uint24 fee1For0, uint40 expiry);
    event PokeCleared(PoolId indexed poolId);
    event PoolAsymmetrySet(PoolId indexed poolId, uint24 premiumPips, bool premiumZeroForOne);

    /// @dev One slot. A side of zero means "no override for this direction" — zero was never a
    ///      legal fee (it sits below MIN_POOL_FEE), so the sentinel costs nothing.
    struct Poke {
        uint24 fee0For1;
        uint24 fee1For0;
        uint40 expiry;
    }

    /// @dev One slot: the pool's config floor plus its directional premium. The premium is
    ///      deliberately NOT packed into the poke slot — that would couple delayed-admin config
    ///      with hot-key TTL state and turn `clearPoke`'s `delete` into a read-modify-write.
    struct AsymConfig {
        uint24 floor;
        uint24 premiumPips;
        bool premiumZeroForOne;
    }

    /// @notice Longest a poked fee can outlive its transaction.
    uint40 public constant MAX_POKE_TTL = 72 hours;

    /// @notice Hard ceiling on any pool's fee cap, fixed at deployment. No role can configure
    ///         or poke a fee above it; changing it means deploying a new singleton.
    uint24 public immutable ABSOLUTE_MAX_FEE;

    IPoolManager public immutable poolManager;

    /// @notice Per-pool fee cap in pips; zero means the pool is not configured.
    mapping(PoolId poolId => uint24 cap) public maxFee;
    /// @notice Most of the live autonomous fee a poke may cut away. A poke is for reacting
    ///         fast, not for switching the curve off; a mis-classified market day is corrected
    ///         through the calendar overlay, which is what that overlay exists for.
    uint16 public constant MAX_POKE_DISCOUNT_BPS = 5000;

    /// @notice Cheapest fee any pool may be configured to charge, fixed in bytecode.
    uint24 public constant MIN_POOL_FEE = 100; // 0.01%, Uniswap's smallest standard tier

    /// @notice Per-pool config floor + directional premium; `floor` was the old `pokeFloor`
    ///         mapping (see the view of that name), `premiumPips` is 0 on symmetric pools.
    mapping(PoolId poolId => AsymConfig config) internal _asym;

    /// @notice Active poked override per pool; ignored once expired.
    mapping(PoolId poolId => Poke poke) public pokeOf;

    modifier onlyPoolManager() {
        if (msg.sender != address(poolManager)) revert NotPoolManager();
        _;
    }

    constructor(IPoolManager poolManager_, address authority_, uint24 absoluteMaxFee_) AccessManaged(authority_) {
        if (absoluteMaxFee_ == 0 || absoluteMaxFee_ > LPFeeLibrary.MAX_LP_FEE) revert InvalidMaxFee();
        ABSOLUTE_MAX_FEE = absoluteMaxFee_;
        poolManager = poolManager_;
        Hooks.validateHookPermissions(IHooks(address(this)), _hookPermissions());
    }

    /// @notice Callback set this hook uses; never includes delta flags.
    function _hookPermissions() internal pure virtual returns (Hooks.Permissions memory permissions) {
        permissions.beforeInitialize = true;
        permissions.beforeSwap = true;
    }

    /// @notice Whether this hook accepts pools whose currency0 is native ETH. False here and in
    ///         every ERC20-only hook; a native-capable variant (any hook inheriting `FablesNativeETH`) overrides it
    ///         to true AND carries the payable/settlement machinery that makes native pools work.
    ///         The flag and the machinery must travel together — flipping this alone would create
    ///         pools the ledger cannot settle deposits for.
    function _nativeAllowed() internal pure virtual returns (bool) {
        return false;
    }

    /// @notice Pools must use the dynamic-fee flag and be configured before initialization.
    function beforeInitialize(address, PoolKey calldata key, uint160) external view onlyPoolManager returns (bytes4) {
        if (!key.fee.isDynamicFee()) revert NotDynamicFeePool();
        if (maxFee[key.toId()] == 0) revert PoolNotConfigured();
        // `_checkKey` refuses native currency0, but that guard sits on the ledger paths, not on
        // the gate that creates the pool — so a native pool could be configured, initialized and
        // traded with dynamic fees while every deposit, withdraw, stake and claim reverted. A
        // pool no LP can ever hold a position in should not exist at all. Native-capable variants
        // opt out via `_nativeAllowed`, whose override is coupled to the settlement machinery.
        if (key.currency0.isAddressZero() && !_nativeAllowed()) revert NativeNotSupported();
        return IHooks.beforeInitialize.selector;
    }

    /// @notice Returns the per-swap fee override; never touches swap deltas.
    function beforeSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata params, bytes calldata)
        external
        view
        onlyPoolManager
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        uint24 fee = _resolveFee(key.toId(), params);
        return (IHooks.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, fee | LPFeeLibrary.OVERRIDE_FEE_FLAG);
    }

    /// @notice Fee the pool would charge a swap in the given direction right now, in pips.
    /// @dev Uses a zero-amount probe, so size-dependent components read as zero here.
    function currentFee(PoolId poolId, bool zeroForOne) external view returns (uint24) {
        return _resolveFee(
            poolId, IPoolManager.SwapParams({zeroForOne: zeroForOne, amountSpecified: 0, sqrtPriceLimitX96: 0})
        );
    }

    /// @notice The autonomous fee the pool charges the given direction with no poke live:
    ///         the curve plus the direction's premium, PRE-poke and PRE-cap.
    /// @dev This view is the keeper's composition input. On a pool with a premium, each poke
    ///      side states that direction's FULL intended fee — the poke replaces the premium
    ///      rather than composing with it — so a keeper must read its baseline here, not from
    ///      `currentFee`, which returns the poked, clamped fee while the keeper's own poke is
    ///      live. The value is PRE-cap and can exceed `maxFee` when the base sits within
    ///      `premiumPips` of it: clamp each composed poke side to the cap before calling
    ///      `pokeFee`, or the whole poke reverts FeeAboveCap (the swap-path resolver applies the
    ///      identical cap, so the clamped poke is behavior-identical to the intended one). Uses a
    ///      zero-amount probe, like `currentFee`.
    function autonomousFee(PoolId poolId, bool zeroForOne) public view returns (uint256) {
        uint256 base = _autonomousFee(
            poolId, IPoolManager.SwapParams({zeroForOne: zeroForOne, amountSpecified: 0, sqrtPriceLimitX96: 0})
        );
        AsymConfig memory asym = _asym[poolId];
        return zeroForOne == asym.premiumZeroForOne ? base + asym.premiumPips : base;
    }

    /// @notice The pool's CONFIGURED poke floor. NOT the lower bound a poke actually resolves to.
    /// @dev This used to say "the lower bound on a poke", and since the resolution clamp that is
    ///      false. `_resolveFee` floors a live poke at `max(_asym.floor, min(preFee, cap) / 2)`, so
    ///      the real lower bound moves with the CURVE and is strictly above this number whenever
    ///      the curve sits above twice it. On the live NVDA pool at the post-weekend bell that is
    ///      `max(300, 4000 / 2) = 2000`, not the 300 this returns.
    ///
    ///      The consequence is concrete: a keeper composing a poke from `pokeFloor` alone gets a
    ///      fee it did not ask for — `pokeFee` accepts the value, `FeePoked` logs it, and the pool
    ///      charges the higher resolved figure. Compose from `autonomousFee(poolId, dir)` and the
    ///      same clamp if you need the number the pool will actually charge.
    ///
    ///      Kept as an explicit view where the retired mapping's auto-getter stood, so every caller
    ///      of the old `pokeFloor(poolId)` still compiles and reads the same number.
    function pokeFloor(PoolId poolId) public view returns (uint24) {
        return _asym[poolId].floor;
    }

    /// @notice The pool's directional premium: `premiumPips` added to the autonomous fee of
    ///         swaps in the `premiumZeroForOne` direction. Zero on symmetric pools.
    function poolAsymmetry(PoolId poolId) external view returns (uint24 premiumPips, bool premiumZeroForOne) {
        AsymConfig memory asym = _asym[poolId];
        return (asym.premiumPips, asym.premiumZeroForOne);
    }

    /// @notice Sets or clears a pool's directional premium. Symmetry is the default; this is
    ///         the one knob that departs from it, and it travels the delayed-admin path like
    ///         every other config write.
    /// @dev `premiumPips <= cap - floor` is a STANDING invariant, not a set-time courtesy:
    ///      `_setPoolBounds` re-checks it when the band moves, so a premium exceeding the whole
    ///      band — one no curve the band admits could ever express — cannot be created by either
    ///      call order. (A curve running ABOVE the floor can still meet the cap mid-band and
    ///      truncate the premium there; that clamp is the resolver's job and is pinned as
    ///      documented behavior, not forbidden here.) The premium prices structural, persistent
    ///      one-sidedness
    ///      (directional loop flow, sell toxicity); transient direction calls belong to the
    ///      poke, which expires.
    function setPoolAsymmetry(PoolKey calldata key, uint24 premiumPips, bool premiumZeroForOne) external restricted {
        _checkOwnPool(key);
        PoolId poolId = key.toId();
        uint24 cap = maxFee[poolId];
        if (cap == 0) revert PoolNotConfigured();
        AsymConfig memory asym = _asym[poolId];
        if (premiumPips > cap - asym.floor) revert PremiumExceedsFeeBand();
        asym.premiumPips = premiumPips;
        asym.premiumZeroForOne = premiumZeroForOne;
        _asym[poolId] = asym;
        emit PoolAsymmetrySet(poolId, premiumPips, premiumZeroForOne);
    }

    /// @notice Temporarily replaces the per-direction fee for a pool. Expires on its own.
    /// @dev Two sides, each bounded on BOTH ends exactly as the single-fee poke was: ceiling is
    ///      the pool cap, floor is the cheapest fee the pool is configured to charge. A side of
    ///      ZERO is the sentinel for "leave this direction autonomous" — one-sided pokes are the
    ///      whole point in a depeg, where only one direction turns toxic. Each call restates the
    ///      WHOLE two-sided poke: the struct write replaces any live poke, so a sentinel side
    ///      returns that direction to autonomous even if it was previously poked non-zero. To
    ///      update one side of a live poke, restate the other side's value in the same call.
    ///      A live non-zero side
    ///      replaces that direction's autonomous fee AND premium; on premium pools the keeper
    ///      composes per side from `autonomousFee` (a symmetric {f, f} poke flattens the
    ///      configured spread for its lifetime — deliberate, so a mis-signed premium stays
    ///      hot-correctable). Cross-side patterns are intentionally unconstrained: a poke that
    ///      cheapens one side while taxing the other is indistinguishable from the canonical
    ///      emergency re-orientation when toxicity flips direction intraday, so containment for
    ///      this hot key stays per-side bounds + TTL + the guardian's zero-delay `clearPoke`,
    ///      not a pattern guard. FEE_POKER is the hot key on the FEE surface — not the system's
    ///      only zero-delay role: PAUSER (`pause`, `pausePool`, `clearPoke`, `emergencyKillGauge`)
    ///      and BRIBE_FORWARDER (`forward`) are zero-delay too. The distinction matters because
    ///      this sentence is quoted as a CALIBRATION YARDSTICK five times in `MarketCalendar` and
    ///      once in `SessionLib` ("no deeper than the hot key is held to"), and a reader who takes
    ///      it literally under-weights PAUSER's `emergencyKillGauge` — which is zero-delay, never
    ///      expires, and moves a desk's whole epoch share from its LPs and voters to the treasury.
    ///      That is a decided, documented trade-off; the problem was that this phrasing hid it.
    ///
    ///      Granted with no
    ///      execution delay because reacting fast is its whole purpose — which makes it the
    ///      likeliest to be compromised. Without a floor, whoever held it could set every pool
    ///      to zero for 72 hours and renew for the price of gas, so LPs earn nothing while
    ///      arbitrageurs take the pool apart for free. A ceiling alone bounds the wrong end.
    function pokeFee(PoolId poolId, uint24 fee0For1, uint24 fee1For0, uint40 ttl) external restricted {
        uint24 cap = maxFee[poolId];
        if (cap == 0) revert PoolNotConfigured();
        if (fee0For1 == 0 && fee1For0 == 0) revert EmptyPoke();
        uint24 floor = _asym[poolId].floor;
        if (fee0For1 != 0) {
            if (fee0For1 > cap) revert FeeAboveCap();
            if (fee0For1 < floor) revert FeeBelowFloor();
        }
        if (fee1For0 != 0) {
            if (fee1For0 > cap) revert FeeAboveCap();
            if (fee1For0 < floor) revert FeeBelowFloor();
        }
        if (ttl == 0 || ttl > MAX_POKE_TTL) revert InvalidTtl();
        uint40 expiry = uint40(block.timestamp) + ttl;
        pokeOf[poolId] = Poke({fee0For1: fee0For1, fee1For0: fee1For0, expiry: expiry});
        emit FeePoked(poolId, fee0For1, fee1For0, expiry);
    }

    /// @notice Clears an active poke, returning the pool to its autonomous fee (both sides).
    function clearPoke(PoolId poolId) external restricted {
        // `pokeFee` refuses an unconfigured pool; its undo must too. This is the zero-delay
        // guardian's only containment lever against a compromised poker key, and without the check a
        // mistyped id deletes an empty slot, emits `PokeCleared` naming a pool that does not exist,
        // and leaves the real poke running for the rest of its TTL behind a success receipt.
        if (maxFee[poolId] == 0) revert PoolNotConfigured();
        delete pokeOf[poolId];
        emit PokeCleared(poolId);
    }

    /// @notice Autonomous per-pool fee in pips for a swap, before premium, poke and cap apply.
    function _autonomousFee(PoolId poolId, IPoolManager.SwapParams memory params)
        internal
        view
        virtual
        returns (uint256);

    function _resolveFee(PoolId poolId, IPoolManager.SwapParams memory params) internal view returns (uint24) {
        uint256 base = _autonomousFee(poolId, params);
        uint256 cap = maxFee[poolId];
        AsymConfig memory asym = _asym[poolId];
        uint256 fee = params.zeroForOne == asym.premiumZeroForOne ? base + asym.premiumPips : base;
        Poke memory poke = pokeOf[poolId];
        // Second-level timestamp drift is immaterial against a TTL of operational size. NOT an
        // enforced floor: `pokeFee` accepts any `ttl` in [1, MAX_POKE_TTL], so a 1-second poke is
        // legal and its whole lifetime would sit inside sequencer timestamp discretion. The
        // consequence stays inside the hot key's own lever — a poke that does or does not apply —
        // which is why the convention is enough; this line used to state it as a guarantee.
        // forge-lint: disable-next-line(block-timestamp)
        if (poke.expiry > block.timestamp) {
            uint256 poked = params.zeroForOne ? poke.fee0For1 : poke.fee1For0;
            // zero is the sentinel: this side was not poked and keeps its autonomous fee
            if (poked != 0) {
                // Captured BEFORE the override replaces it: this is what the swapper would have
                // paid with no poke at all, premium included. Reading it after the assignment gives
                // the poked value and makes the floor below vacuous — the existing differential
                // fuzz test catches exactly that mistake.
                uint256 preFee = fee;
                fee = poked;
                // The poke's bounds are enforced at RESOLUTION, not only when it was set. Checking
                // once at `pokeFee` left two holes: raising a pool's floor afterwards left a live
                // poke charging under the new floor for up to 72h, and the static floor said nothing
                // about the pool's CURRENT fee — so the hot key could pin a pool that its own curve
                // had ramped to 400bps back down to its 100bps configured floor, renewably, handing
                // a permanent subsidy to exactly the toxic flow the curve exists to price.
                //
                // The discount is measured against the direction's own PRE-POKE fee, premium
                // INCLUDED. It used to be measured premium-free, on the argument that the 50% rule
                // protects the curve while the premium is admin policy layered on top. Three audit
                // lenses independently showed what that costs, and the numbers settle it: on the
                // shipped NVDA curve (cap 8000, floor 300, base 700 at midday) with the maximum
                // legal premium of 7700, the pool charges 8000 unpoked, and a poke of 300 resolved
                // to 350 — a realised cut of 9563 bps against a ceiling this contract documents as
                // 5000. A merely modest premium of 700 already gave 7500 bps. At premium 0 both
                // forms agree exactly, which is what pins the divergence on the premium term.
                //
                // The correction the premium-free form existed to preserve still works: suppressing
                // a mis-signed premium down to the base fee needs a floor of at most `base`, and
                // for any premium <= base this floor is at most `base`. What it no longer permits
                // is erasing a premium several times the curve, which is the case that made
                // MAX_POKE_DISCOUNT_BPS meaningless.
                //
                // MEASURED AGAINST THE CAPPED CURVE, not the raw one — and against `preFee`, the
                // premium-INCLUSIVE pre-poke fee, which is why the variable below is `preFee` and
                // not `base`. `preFee` is what the curve asks for in THIS direction;
                // `min(preFee, cap)` is what the pool would actually charge with no poke at all,
                // and the 50% rule is about what a swapper pays, not about an intermediate value
                // nobody is ever charged. Measuring against the raw value made the floor
                // exceed the cap for any curve value at or above `2 * cap` — at which point
                // `floor_ >= cap`, every legal poke resolves to the cap, and the fee is identical
                // whether or not a poke exists. The hot key's only lever became a silent no-op
                // during precisely the window it exists for (the opening descent), while `pokeFee`
                // still returned success and `FeePoked` still fired.
                //
                // That state is reachable with every field inside its own validated bound, because
                // the bound that escapes is a PRODUCT: `overnightFloor * spikeMult` with
                // overnightFloor 4000 (< cap 8000) and spikeMult 5 (< MAX_SPIKE_MULT 20) is 20000,
                // which is 2.5x the cap. `closedSpike` reaches it directly, being the one fee field
                // the validator never compares against `cap`. Clamping here fixes the whole class
                // rather than each field, and it cannot loosen anything: `min(preFee, cap) <=
                // preFee`, so the floor only ever moves down, and `clearPoke` is unaffected.
                //
                // `preFee` IS CAPTURED BEFORE `fee = poked` ABOVE, and that ordering is the whole
                // fix. Reading it after the assignment makes `effectiveBase` the poked value
                // itself, so the floor becomes half of what was just asked for — it can never bind,
                // and the discount ceiling is vacuous. That was this patch's own first attempt, and
                // `test_fuzz_differential_symmetricConfigMatchesOldResolver` caught it.
                uint256 floor_ = asym.floor;
                uint256 effectiveBase = preFee > cap ? cap : preFee;
                uint256 discountFloor = (effectiveBase * (10_000 - MAX_POKE_DISCOUNT_BPS)) / 10_000;
                if (floor_ < discountFloor) floor_ = discountFloor;
                if (fee < floor_) fee = floor_;
            }
        }
        if (fee > cap) fee = cap;
        // casting to 'uint24' is safe: fee is clamped to cap, which _setPoolBounds bounds to MAX_LP_FEE < 2^24
        // forge-lint: disable-next-line(unsafe-typecast)
        return uint24(fee);
    }

    /// @dev Records the pool's bounds. `floor` is the cheapest fee its own curve can produce;
    ///      it is what a poke may not undercut. Each hook computes it from its own config.
    /// @dev A key this hook does not serve. Cheaper than `_checkKey` and usable BEFORE the pool is
    ///      configured, which `_checkKey` cannot be (it requires a non-zero cap, and this is the call
    ///      that sets one). Without it a mistyped `hooks` field writes config for a PoolId this
    ///      contract can never serve and emits an event naming it, while the pool it was meant for
    ///      silently keeps its defaults — the same silent-misconfiguration class the sibling setters
    ///      already refuse.
    function _checkOwnPool(PoolKey calldata key) internal view {
        if (address(key.hooks) != address(this)) revert PoolNotConfigured();
    }

    function _setPoolBounds(PoolId poolId, uint24 floor, uint24 cap) internal {
        if (cap == 0 || cap > ABSOLUTE_MAX_FEE) revert InvalidMaxFee();
        // A lower bound on the CONFIG, not just on the poke. `pokeFee` was carefully bounded on
        // both sides while the config path — which sets the very floor the poke is measured
        // against — could be driven to 1 pip on a live pool, draining LPs by the same route the
        // poke floor exists to block.
        if (floor < MIN_POOL_FEE || floor > cap) revert InvalidMaxFee();
        AsymConfig memory asym = _asym[poolId];
        // The premium invariant holds against the NEW band, whichever setter moved last: a config
        // that would shrink the band below a live premium must first lower the premium, or the
        // premium would become one that NO curve the band admits could ever express in full.
        if (asym.premiumPips > cap - floor) revert PremiumExceedsFeeBand();
        maxFee[poolId] = cap;
        asym.floor = floor;
        _asym[poolId] = asym;
    }
}
