# Z3-H5 · GoldPesa (Base) — Uniswap-V4 rebalance hook: $115K stolen 2026-10-02; **$0.00 E-U live today**, residual latent $28.95K conditional behind an economically unreachable trigger

**Date:** 2026-10-16 · **Chain:** Base (8453) · **Status:** read-only; fork-only PoC (no mainnet transactions) · **Fork block:** 52,660,634 (chain tip at measurement)

| | |
|---|---|
| **Target** | `GPXHooks` `0x4519e2b040ff1B64fa03aBe2AeF0BC99D7CcEaA8` (immutable, verified) · GPX `0x454F8c3f1FC79a98363DB6104A20AC59A02A3133` · pool id `0xe33d2ac4…dcac` |
| **Live extractable (unprivileged) now** | **$0.00** — confidence **high** |
| **Why closed** | The only value-moving path (hook `reBalance()`) is gated by `checkRebalance()`, which is **provably unreachable at any sane cost** (needs +45,467.7 GPX absorbed into the treasury; max feasible absorption costs ≥$235K–$470K for a ≤$28.95K extraction). Residual Permit2 allowances (92.78 GPX) are **unspendable** by anyone (PositionManager payer model). |
| **Latent / conditional** | **$28,951.64** USDC (the hook position's USDC side) — extractable **iff** `checkRebalance` ever flips true, which requires the treasury to exceed **46,439.5 GPX** (today 971.8). Fork-proven with a mocked trigger (mechanism live, trigger unreachable). |
| **Stuck (S)** | The hook's sole LP position: **10,148.5247 GPX + 28,951.6408 USDC ≈ $81,364.25** nominal (position value at the pool price $5.1646; USDC side $28,951.64 is the only hard value; the GPX side has no exit other than this pool). |
| **H-O / P** | $0 / $0 — no user-recoverable balances; no privileged path (immutable, ownerless hook; the GPXOwner multisig cannot move hook funds). |
| **Monitors** | hook `positionId()` (**3106206**), `lastRebalance()` (**1,790,946,351** = 2026-10-02 13:05:51 UTC), `Rebalanced` event, **treasury GPX balance vs 46,439.5**, pool tick vs band, Permit2 allowances (latent refresh on any rebalance). |

---

## 1. Bug and incident (exact terms)

The hook owns the GPX/USDC V4 pool's **entire** liquidity (position NFT **3106206**, range `[-275,982, MAX_TICK]`, `L = 23,063,189,219,641,299`). Every swap calls `beforeSwap()`; once an hour has elapsed, it calls `reBalanceRoutine()` → `checkRebalance()` → `reBalance()`, which does:

```solidity
// GPXHooks.sol (verified, immutable) — reBalance()
positionManager.modifyLiquiditiesWithoutUnlock(  // BURN_POSITION + TAKE_PAIR, NO settle check
    abi.encodePacked(uint8(Actions.BURN_POSITION), uint8(Actions.TAKE_PAIR)), burnParams);
```

`modifyLiquiditiesWithoutUnlock` executes inside **whatever PoolManager unlock is already open**. `TAKE_PAIR` pays out only the PositionManager's **net** delta. An attacker who, inside their own unlock, mints an unsettled pure-USDC position (phantom debt `D`) gets the hook's burn credit `B` silently netted against `D`: the hook receives `B − D`, and the attacker's own burn+take then withdraws `D` from the PoolManager.

**Incident (2026-10-02, block 52,078,502):** tx `0x5c1febd5047c2a15c37988b6abd5c8b984236dddf6fd24eed96b0f43951ad2c9`; attacker EOA `0x4a5FD2e9357cC87DF4cD6A1808174DBc8646899F` via contract `0x3d69591a3868FE77B531187486862c459Cce4e86`; Morpho flash loan 175,000 USDC; burn credit 148,868.602188, phantom debt **114,999.999186 USDC stolen** (hook kept 33,868.603002). The same tx fired the last rebalance ever (`lastRebalance = 1,790,946,351`) and minted today's position 3106206. **No rebalance has fired in the 14 days since.**

## 2. Live state (all reads at Base block 52,660,634; raw dump in `ci-out/state.json`)

| Item | Value |
|---|---|
| Hook code | 19,046 bytes, codehash `0x892c8ee3…79e3` (no proxy/delegatecall; immutable) |
| `positionId` / `lastRebalance` | `3106206` / `1,790,946,351` (2026-10-02 13:05:51 UTC) |
| Position owner / range / L | hook / `[-275,982, 887,272]` / `23,063,189,219,641,299` (== pool liquidity → sole position) |
| Pool slot0 / tick | `sqrtPriceX96 = 180051204617000423516900`, tick `−259,906` (GPX ≈ **$5.1646**) |
| Position composition | **10,148.524734826689003623 GPX + 28,951.640789 USDC** ≈ **$81,364.25** (DexScreener pool liq: $81,364.25) |
| Hook balances | GPX `99,930,888.384260767462321773` (= `gpxReserves`), USDC **0** |
| GPX supply / treasury GPX | `100,000,000` (fixed; no mint/burn) / `971.776010345558154699` |
| **`gpxCirculatingSupply`** | **57,991.314994060290519905 GPX** |
| **`checkRebalance` today** | **FALSE** — `simulatedTick = −306,638` vs band `(−275,982, −259,906)`; condition 7 (`lower+1+9624 ≤ tick`) is satisfied; condition 6 fails by **30,656 ticks** (≈4.63×) |
| Residual Permit2/ERC20 allowances (latent) | GPX **92.781203640212676485** (exp `uint48.max`, nonce 0) · USDC **338.686030** — spender = PositionManager only |
| Other market for GPX | none (DexScreener: this pool only; 24 h volume ≈ $12) |

The fork test `test_T1` reproduces the hook's internal math **exactly** with the same v4-core libraries: `simulatedTick = −306,638`, `gpxInsideUniswap = 10,148.524734826689003623`, `usdcInsideUniswap = 28,951,640,789`, `checkRebalance = FALSE`.

## 3. Re-arm model — exact, price-independent, and unreachable in practice

`checkRebalance()` fires iff `simulatedTick ∈ (lowerTick, currentTick)` and `lowerTick+1+9624 ≤ currentTick` and `enoughGPX`, where
`simulatedTick = tick( usdcInsidePool · 2¹⁹² / (circ · √P) )` and `usdcInsidePool = L(√P − √P_lo)`.

Algebra (verified against the fork replica) gives a **price/trade-independent** reduction. Let `N' = circulating + x_pool + treasury` (all GPX outside the hook's reserves; `N' = 69,111.6157` today). Since any GPX that leaves circulation (other than into the pool, which cancels exactly) must pass the fee mechanism into the **treasury**, and only the hook can transfer GPX to the treasury (the GPX token reverts every other sender), the trigger reduces to:

> **`checkRebalance` flips true ⟺ treasuryGPX > N′ − L·2⁹⁶/√P_lo ≈ 46,439.46 GPX** (given `currentTick ≥ −266,357`, true today and unaffected by fee-absorption).

Today the treasury holds **971.78 GPX** → it must gain **+45,467.7 GPX (48× today's balance, 66% of all non-reserve GPX)**.

**Why that is not reachable by an attacker:**
1. **Direct donation is impossible** — `GPX._update` reverts any transfer to the treasury unless `from == gpxHook`.
2. **Only fee splits feed the treasury**: 1% transfer fees (0.5% treasury / 0.25% mines / 0.25% pawn) and 0.5% GPX-side swap fees (0.25%/0.25%). To add X to the treasury, payers must lose **2X** in fees.
3. **Cost to trigger:** ≥ **90,935 GPX** of fees (~**$469.6K** nominal at $5.1646) must be paid to move +45,467.7 into the treasury; even the most charitable recovery accounting (recycling the pawn's half) leaves ≥ **$234.8K** destroyed. The mines' half (**22,733.9 GPX**) is permanently stuck — `GoldPesaMines` has **no GPX outflow** function.
4. **Acquisition constraint:** only **10,148.5 GPX (~$52K with heavy price impact)** is purchasable on-chain; the remaining ~35–80K GPX sits with users and has no on-chain venue.
5. **Natural accrual is negligible:** the treasury holds 971.8 GPX after the protocol's entire lifetime; the pool does ~$12/day volume. The gap needs a ~48× increase.

⇒ For a **≤$28.95K** extraction, an attacker must destroy **$235K–$470K**. The trigger is not "gated" — it is **economically self-defeating**. (Fork-measured confirmation of the mechanism's direction: `test_T7` cycles 20K GPX through 40 fee hops → treasury +≈3.3K GPX, `simulatedTick` +≈1.2K ticks, still ~29K ticks short.)

**Conditional amount if it ever fired** (fork-proven via a mocked trigger, `test_T4`): the phantom-debt replay extracts up to **B = 28,951.64 USDC** — bounded hard by `TAKE_PAIR`'s `DeltaNotPositive` revert (`D ≤ B`). Case A (D = 28,000 USDC) succeeds and steals 28,000; Case C (D = B+1) reverts; Case D (D = 115,000, the 2026-10-02 size) reverts — today's pool cannot support the historical extraction. The GPX side (10,148.5 GPX) can be nominally phantom-stolen too (attacker-created GPX pool), but its realizable value is capped by the same pool's USDC, so total realizable stays ≈ **$28.95K**.

## 4. v4-hook-harbinger checklist — every angle re-checked

| Angle | Result |
|---|---|
| **Permission bits** | Address bits `0x2AA8` match `getHookPermissions()` exactly (beforeInitialize, beforeAddLiquidity, beforeRemoveLiquidity, beforeSwap, beforeDonate, beforeSwapReturnDelta). No mismatch. |
| **Callback auth** | All callbacks `onlyPoolManager`; `beforeInitialize` reverts (blocks new pools with this hook); `beforeAddLiquidity`/`beforeRemoveLiquidity` gated by `isRebalancing` (set only inside `reBalance`); `beforeDonate` reverts. `BaseHook._unlockCallback` self-call is unreachable (hook never calls `poolManager.unlock`). |
| **Position NFT control** | `ownerOf(3106206) = hook`; `_burn/_decrease/_increase` require `onlyIfApproved(msgSender(), tokenId)` → third parties cannot touch it. |
| **Delta settlement** | The original shared-unlock flaw is intact but requires `reBalance()` (trigger above). Fee takes in `beforeSwap` are delta-balanced by the returned `BeforeSwapDelta` (no leak). |
| **Residual allowances (prior sweep missed this)** | The hook leaves `approve(permit2, maxSpend)` + `permit2.approve(token, positionManager, maxSpend, uint48.max)` after every rebalance: **live today = 92.78 GPX + 338.69 USDC**. **Unspendable:** the deployed Base PositionManager (older v4-periphery) encodes `SETTLE` as `(currency, amount, payerIsUser)`; payer = `msgSender()` (the caller) or the PM itself (`BaseActionsRouter._mapPayer`), and `msgSender() = _getLocker()` — the hook can be the payer **only when the hook itself calls the PM** (i.e. during its own `reBalance`). No third party can name the hook as payer. The USDC allowance additionally needs hook USDC > 0 (hook holds 0; USDC only ever enters during a rebalance). Negative control in `test_T5` reverts as expected. |
| **Other contracts** | `mintInitialLiquidity`/`setAddresses` are done (deployer-only, one-time); hook receive/fallback revert; `checkForDonations` sweeps stray GPX to the owner multisig (not attacker-useful); `GPXOwner` has no hook powers. |
| **Liveness (new observation)** | A holder of **≥22,672 GPX** (the position's max GPX capacity) can sell it all, draining the position's USDC (~$28.9K) and pinning the pool price at the MIN limit with **active liquidity = 0**. From then on **every swap reverts** in `beforeSwap` (`getMaxAmountInForPool2` → `InvalidPriceOrLiquidity`), liquidity can only be added via `reBalance` (which needs `beforeSwap`), so the pool is **permanently bricked** — a one-way griefing vector. It is **not extraction** (the seller receives only the pool's USDC at market, a large net loss) and requires GPX that is not purchasable on-chain (pool holds 10.1K; the rest sits with users, no market). |

## 5. What an attacker can / cannot do (paths, preconditions, costs)

- **CANNOT** extract anything from the hook today: the burn path is unreachable; the allowances are unspendable; the NFT is owner-locked; the pool blocks liquidity/donate operations.
- **CANNOT** flip the trigger without first destroying ≥45.5K GPX ($235K+; mines' share permanently stuck; only 10.1K GPX purchasable on-chain).
- **IF** the trigger ever flipped (e.g., decades of fee accrual, or a third party burning ~$235K+ of GPX into the fee mechanism): a **permissionless, flash-loanable** (Morpho holds 237.8M USDC) phantom-debt replay steals up to **28,951.64 USDC**, bounded by `TAKE_PAIR` positivity. Gas ≈ few hundred K; Morpho fee 0.
- **Costs today:** zero-profit; the replay with the trigger absent completes as a no-op with a small loss (~$100 swap fees) — measured in `test_T3`.

## 6. PoC / fork verification

Project: `poc/` (Foundry; vendored `forge-std` + minimal v4-core libs extracted from the verified hook bundle). All tests fork Base at **block 52,660,634** (env `BASE_RPC_URL`; auto-probed in CI).

| Test | What it proves |
|---|---|
| `test_T1_live_state_and_checkRebalance_false` | Exact live state; `simulatedTick=−306,638`; `checkRebalance=FALSE` (exact integer replica of the hook's math) |
| `test_T2_swap_sweep_cannot_trigger` | Buys 30K/600K USDC and sells 20K/100K/500K/2M GPX (snapshot-isolated) — **no rebalance**, position/lastRebalance untouched, `simulatedTick` never enters the band. Deep sells (≥100K GPX) drain the position's USDC and pin the price at the MIN limit; **every further swap then reverts in `beforeSwap` (`InvalidPriceOrLiquidity`)** — the pool bricks (liveness, not extraction; see §4) |
| `test_T3_phantom_debt_matrix_live_state_all_zero` | Full DFL-style attack replay at D ∈ {$1K, $10K, $28,951.64, $100K} on live state — **$0 stolen** each time, no rebalance. (Without a rebalance the mint-ceil/burn-floor round trip leaves a ~1 wei negative residue on the shared PM delta, so `TAKE_PAIR` reverts `DeltaNotPositive` — the same "all revert" the prior sweep saw. No theft either way.) |
| `test_T4_mocked_trigger_quantifies_conditional_extraction` | With the trigger mocked true (storage slot 9): D=$28,000 → **stolen 28,000 USDC**, hook re-mints position 3106208; D=B (=28,951.64) boundary; **D=B+1 reverts**; **D=$115K reverts** (today's pool cannot support the historical size) |
| `test_T5_residual_allowances_state` | Permit2/ERC20 allowances exact; USDC allowance unusable (hook USDC=0); SETTLE payer model negative control reverts |
| `test_T6_rearm_threshold_exact` | Trigger threshold **46,439.46 GPX**; N′=69,111.6; treasury 971.8; needs >65% of all non-reserve GPX absorbed |
| `test_T7_transfer_fee_absorption_scale` | Measured fee-absorption: 40 hops of a 20K pile → treasury +≈3.3K, `simTick` +≈1.2K ticks (≈1/25 of the gap) |

**CI (GitHub Actions, public repo `artsbykriss/ca-zombie-ci`):** run URLs + pass counts recorded in `ci-log.txt` / `summary.json` after the run completes (see §8). Fork block pinned; heavy work runs only on CI.

## 7. Verdict

- **E-U (external unprivileged) today: $0.00** — high confidence. Bug present, funds present, trigger unreachable at any economically rational cost; allowances unspendable.
- **E-U conditional: $28,951.64 USDC** — requires `treasuryGPX > 46,439.5` (cost ≥$235K–$470K to engineer; 48× natural gap; mines' fee share permanently stuck) — classify as **latent, not live**.
- **H-O: $0 · P: $0 · S: $81,364.25** (hook position: 28,951.64 USDC + 10,148.52 GPX; only the USDC side has hard value).
- **Residual/latent risks:** (a) any future rebalance refreshes ~1% residual allowances (still unspendable under the current PM, but worth monitoring if Uniswap ever migrates the PM to the newer arbitrary-payer encoding); (b) the trigger threshold is price-independent — a future **treasury accrual** (fee volume) is the only natural path, and it is decades away at current rates; (c) protocol-level upgrades (PoolManager/PositionManager) could change the assumptions.
- **Blockers (why nothing is extractable):** `checkRebalance` unreachable; PM payer model; owner-locked NFT; GPX treasury-transfer guard; `isRebalancing` gates; immutable ownerless hook.

## 8. Methodology & sources; caveats; files

**Method:** on-chain reads at pinned block 52,660,634 (cast, public RPCs); exact integer replication of the hook's `checkRebalance` math in Python and Solidity (same v4-core libraries); fork tests on CI; source-level review of the verified hook bundle (GPXHooks/GPX/GPXOwner/BaseHook/AmountsHelper2/GPMTreasury/GoldPesaMines/Pawn/GPOVault); PositionManager source fetched from Sourcify (Base); DexScreener/GeckoTerminal for market context; DeFiHackLabs `GoldPesa_exp.sol` for the incident reconstruction.

**Key sources:** Etherscan/Basescan verified source of `0x4519e2b0…` (bundle includes libraries, incl. deployed `AmountHelpers2` `0xdf10cfbc…`); Sourcify `0x7C5f5A4b…` (PositionManager); incident tx `0x5c1febd5…`; DFL PoC; SlowMist 2026-10-02.

**Caveats/limitations:** (1) The mocked-trigger test proves the mechanism/amount, not the trigger's reachability — reachability is an economic argument (conservation + cost), not a fork test. (2) Realizable value of the GPX side is approximated by the pool's USDC depth (the only market). (3) Mines/pawn/vault GPX recycling assumptions affect the *cost* of the re-arm, not the conclusion. (4) The treasury contract's outflow functions were not exhaustively audited (out of scope; they only make re-arming harder). (5) Fork state from public RPCs may be pruned for the pinned block on some providers; CI auto-probes endpoints.

**Files:** `README.md` (this) · `summary.json` · `analysis/` (verified sources, `gpx_math.py` exact replica, ABI) · `poc/` (Foundry project: `src/GPXSim.sol`, `src/GPXAttacker.sol`, `test/GoldPesa.t.sol`) · `ci/run.sh` (state dump + Base-RPC probe) · `ci-out/` (raw state JSON) · `ci-log.txt` + `ci-artifacts/` (CI results).
