# ZH4-PASS2 Tier-3 small leads — bOSMO / OpenFour / Genius.fun

**Date:** 2026-10-19/20 · **Chains:** Osmosis, BSC · **Mode:** read-only; no transactions signed or
sent. Every exploit path was reproduced with exact integer math and/or a local BSC fork; the
bOSMO path is a CosmWasm contract, so it is proven by raw-state reads + the deployed v3.0.15
source + two historical on-chain validations, not by an EVM fork.

## TL;DR

| # | Target | Chain | Live extractable (E-U) | Why open / closed | Confidence |
|---|---|---|---|---|---|
| 1 | **bOSMO / Backbone Labs** | Osmosis | **18,386.17 OSMO ≈ $965.16** (join batch 126) · 18,465.43 ≈ $969.32 (submit 126 first) · hard ceiling $991.78 | `code_id 741` (v3.0.15) double-counts the `135p8` delegation on redemption: mint 0.0379425, redeem 0.0569138 = **1.500×**; permissionless, no pause | **HIGH** mechanism / **MEDIUM** USD |
| 2 | **OpenFour tax-token sandwich** | BSC | **$0** | `swapForQuote` has no `minOut` (real), but live tax swaps are **≤0.72% of pool depth**; break-even is ~2% after 0.5% DEX fees + gas. 15/40 top tax tokens have tax; only 2 above `minDispatch` (max $29.25) | **HIGH** for current flow |
| 3 | **Genius.fun “graduation race”** | BSC | **$0** | `forceSweptGraduation` and `rescueSweptGraduation` are **`onlyOwner`** (random caller → `OwnableUnauthorizedAccount`); factory holds 0 BNB/USDT/USDC; permissionless `createGraduatedPool` pays no caller | **HIGH** |

### Total live extractable now: **≈ $965** (one-off, bOSMO)
The only positive-EV path is bOSMO. OpenFour is a real missing-slippage bug with zero current
economics; Genius.fun is owner-gated (P), not an unprivileged race.

## 1. bOSMO / Backbone Labs — live 1.5× redemption double-count · Osmosis

**Contract:** `osmo1s3l0lcqc7tu0vpj6wdjz9wqpxv8nk6eraevje4fuwkyjnwuy82qsx3lduv` (`code_id 741`,
label `bOsmo-gravedigger-1`, cw2 **3.0.15**). Admin `osmo1lu92…` (single-sig EOA); owner
`osmo14dx3…`. No migration, no pause, `paused_validators: []`.

**Bug.** v3.0.15 `submit_batch()` computes the redemption payout from
`query_all_delegations()` **plus** `query_delegations(VALIDATORS_ACTIVE \ VALIDATORS)`. On this
contract `VALIDATORS = {u2wsa}`, `VALIDATORS_ACTIVE = {135p8, u2wsa}`; `135p8` holds
9,446.654561 OSMO and is added twice. Mint uses the full delegation set, so:

* mint `18,893.309122 / 497,945.621653 = 0.0379425 OSMO/bOSMO`
* redeem `28,339.963683 / 497,945.621653 = 0.0569138 OSMO/bOSMO` — exactly **1.5×**

The deployed binary is fingerprinted by two historical events: a 0.1 OSMO bond at height
72,593,027 minted exactly 2,564,906 usteak, and batch 125 at height 72,610,033 paid exactly
1,521,225,913 uOSMO — the latter only matches if the `135p8` delegation (10,617.557927 OSMO at
the time) is double-counted. Batch 124 paid 1.67485 OSMO/bOSMO vs the forum’s stated fair
1.1174 (1.499×).

**Path.** `Bond(receiver=attacker)` with `d` OSMO → `Unbond` the minted bOSMO; pending batch 126
is already ripe (`est_unbond_start_time` 2026-10-19T03:47:49Z), so the same tx calls
`SubmitBatch`; wait 14 days; `Reconcile` + `WithdrawUnbonded`. Exact optimum:
`d=23,636.25 OSMO`, `m=622,948.956363 bOSMO`, `U=42,529.559121 OSMO`,
payout `42,022.417801`, **net 18,386.167801 OSMO = $965.16** at $0.0524936. If batch 126 is
submitted first, batch 127’s optimum is `d=23,651`, net **18,465.433299 OSMO = $969.32**. Hard
ceiling `N0 = 18,893.309122 OSMO = $991.78`; at the pass-2 price $0.057396 the numbers are
$1,055.29 / $1,059.84 / $1,084.40.

**Why not the $2.74k bank balance.** The contract holds 47,660.55 OSMO, but it is prior-batch
claims + a **45,233.51 OSMO** residual/compensation pot; the redeem formula only undelegates and
never reads the bank. The overflow path that could reach it (`U > N`) is rejected: the deployed
wasm contains `attempt to subtract with overflow` and v3.0.15 was built with `overflow-checks =
true`. Bank = **S/P**, not E-U.

**Blockers / what closes it.** (1) Admin migrates `code_id 741` (one EOA tx; forum says a fixed
build is pending); (2) owner `pause_validator(135p8)` (makes `E=0`); (3) the Osmosis Liquidity
SubDAO `osmo1rvq5cq2…` still holds **359,940.35 bOSMO (72.3% of supply)** and could redeem first,
capturing `N0` via governance; (4) any other batch drains the delegations. Both validators are
jailed/unbonding (`135p8` UNBONDED since 2026-06-10; `u2wsa` UNBONDING 2026-10-28), but the
keeper still accepts delegate/undelegate, so the path works. If the attacker’s bond lands on
`u2wsa` instead of `135p8`, `E` stays fixed and the max net falls to ~9,446.65 OSMO (~$496).

**Other bOSMO surface.** 9 pools hold bOSMO; the only meaningful one is a custom CW pool with
1,302.97 bOSMO / 29.89 OSMO. Buy-below-redeem yields ~9.86 OSMO (~$0.52); the earlier mint→sell
arbitrage is drained. Community pool bOSMO is 5.01 (governance-only). Immaterial vs the staked
backing.

**Verdict:** **E-U ≈ $965 (ceiling $992)**, live now. H-O = 40,508 OSMO compensation + the
already-queued batch 124/125/126 claims. P = admin migration / owner validator pause / SubDAO
redemption. S = 45,233.51 OSMO residual bank. Full detail:
[`bosmo-backbone/README.md`](bosmo-backbone/README.md), independent review:
[`bosmo-backbone/analysis/child-verify.md`](bosmo-backbone/analysis/child-verify.md).

## 2. OpenFour / four.meme tax tokens — real missing `minOut`, $0 extractable · BSC

**Bug (verified source).** `Token5._dispatchFee()` (e.g. 4Ball
`0xD6423F99863e13b0a3Fa00b5e1E5597792f74F8C`) calls
`ITokenHelper(TOKEN_HELPER_5).swapForQuote(to, amountToken)`; `DividendLaunchToken._dispatchTax()`
calls `ILiquidityHelper.swapForQuote(token, router, quoteToken, to, amountToken)`. Neither
interface has a `minOut`/`amountOutMin` parameter, and the helper has no slippage argument to
forward. Any wallet-to-wallet transfer (or a sell) triggers the dispatch, so it is
permissionless — the pass-2 premise is correct.

**Why it is $0 today.** Live scan of the top 40 V9 tax tokens (four.meme `VOL_DAY_1` list + BSC
reads at block 128,636,158): 15 have `feeRate > 0`; only **2** have `feeAccumulated ≥
minDispatch`:

| Token | accrued tax | swap value (F+H+LP) | pool quote | swap/pool |
|---|---:|---:|---:|---:|
| CHIM | 4.751M tokens | **$29.25** ($23.40 swapped) | $3,271 | **0.68%** (fork) |
| bibi Pro | 574k tokens | **$1.51** | $2,159 | **0.05%** (fork) |
| SPX001 | 380k tokens | $271 (pending; min $285) | $38,433 | 0.57–0.61% |
| AHA | 96.9k tokens | $104 (pending; min $431) | $43,966 | 0.24–0.81% |

A reverse sandwich of a tax **sell** captures at most `v²/(4Q)` before fees; two DEX legs cost
`0.5%·v`. Break-even is `v/Q > ~2%`. Every live token is **<0.75%**, so the net is negative even
before gas (`SPX001`: gross $0.53, fees $1.43, net −$0.90; CHIM: −$0.08). The FeeRouter’s 23.65
WBNB is caller-unreachable (`claimDevFee`/`claimPartnerFee` keyed by `msg.sender`); no principal
path.

**Re-arm:** for any tax token, `feeAccumulated × price / pair_quote_reserve > ~2%` (or a large
`minDispatch` vs a shallow pool). Then the missing `minOut` becomes live MEV. Full table and
arithmetic: [`openfour/README.md`](openfour/README.md).

**Verdict:** **E-U $0** at current flow (HIGH); real latent bug; no principal at risk.

## 3. Genius.fun — “graduation race” is owner-only · BSC

**Factories:** active v4.2 `0x37eE8AeE29C5efd3C1A7edA6dF3F510779928a37`, legacy v4.1
`0x78EAE9537C0ef90DFe9B7ae964682Fe8138afe31`; owner of both
`0xE7C7B7EE71db0f1B4F0Ff25D7cEc191268e7FD98` (**Gnosis Safe 2-of-3**);
`GRADUATION_RESCUE_DELAY = 604,800 s` (7 days).

Verified source (`src/GeniusLaunchFactory.sol`, Sourcify full match):

```solidity
function forceSweptGraduation(address token) external onlyOwner nonReentrant { ... }
function rescueSweptGraduation(address token, address recipient) external onlyOwner nonReentrant { ... }
function createGraduatedPool(address token) external nonReentrant { ... }  // permissionless, pays no caller
```

On-chain at block 128,636,158: a random caller gets `OwnableUnauthorizedAccount` on both
`forceSweptGraduation` and `rescueSweptGraduation`; the owner passes auth and hits `TokenNotFound`;
`createGraduatedPool`/`graduate` from a random caller reach `TokenNotFound` (no auth gate). The
factory holds **0 BNB, 0 USDT, 0 USDC**. The only “race” is defensive: while a swept launch is in
phase `Swept`, anyone may call `createGraduatedPool`; if the seed succeeds, the owner’s 7-day
rescue is closed. That protects holders and pays the caller nothing (LP is minted to the
permanent locker). `forceSweptGraduation` also reverts `GraduationStillViable` on a healthy launch.

Live enumeration: 20,742 launches, 160 sweeps, all 160 now `PoolCreated` with
`sweptQuote = 0`; all 20,742 curves return `readyToGraduate() == false`; both factories hold 0 BNB
and 0 of 18 pair tokens. Historical peak was 75 BNB concurrently pending (2026-09-17), but even
then the only permissionless mover was `createGraduatedPool` (no caller payout). The 4.1 factory
is real and still enabled; the pass-2 `0x78EA…fe31` truncation is
`0x78EAE953…8afe31`, not the 698-byte `0x78eA5FE…E099` contract.

**Verdict:** **E-U $0** now and conditional on funding (HIGH). **P** = owner rescue to an
arbitrary recipient after 7 days on a guard-refused launch, up to ~15 BNB (~$10.95k) per stuck
launch. **H-O** = Genius FeeEscrow credits ~$200,769 (39.43 + 235.53 BNB) claimable only by their
ledger owners. Full detail: [`genius-fun/README.md`](genius-fun/README.md).

## 4. Methodology

* Every number is from a named block: Osmosis 72,830,341 (2026-10-19T22:45:29Z; re-checked at
  72,830,598) and BSC 128,636,158. Raw JSON is kept in each target’s `analysis/`.
* bOSMO: raw CosmWasm state decoded (hex keys / base64 values), validator sets and delegation
  amounts, v3.0.15 source matched to cw2, exact u128 floor simulator, two historical on-chain
  validations, bank/liability reconciliation, all 3,666 pools scanned, SubDAO and governance
  checked.
* OpenFour: verified Sourcify source for `Token5` and `DividendLaunchToken`, live 40-token scan of
  `feeRate`/`feeAccumulated`/`minDispatch`/allocation/pair reserves, sandwich break-even math.
* Genius.fun: verified Sourcify source, live owner/delay/balance reads, `eth_call` from a random
  EOA and from the owner, fork test.
* PoC: `poc/test/BscReadOnlyChecks.t.sol` — **3/3 pass** on a BSC fork at block 128,636,158
  (Genius owner gate; FeeRouter not caller-drainable; tax swaps 68/5/57 bps < 200 bps break-even).
* CI: GitHub Actions `artsbykriss/ca-zombie-ci`, workflow `poc.yml`; run URL in `summary.json` and
  `ci-log.txt`. The CI re-runs the bOSMO live read + exact math and `forge test`.

## 5. Caveats / limitations

* bOSMO is a CosmWasm contract; there is no EVM fork. The proof is exact state + deployed source +
  historical payouts, not a local VM execution. The 14-day unbond and admin migration/SubDAO
  redemption are real timing risks; the USD is OSMO-price-sensitive (±10% OSMO ≈ ±$96).
* OpenFour’s `price`/`day1Vol` come from the four.meme API (off-chain, cached); the accrued tax,
  `minDispatch`, rates and pool reserves are on-chain. The $0 verdict is robust to a 2× price move
  because the swap/pool ratios are ≤0.72% vs a 2% break-even.
* Genius.fun’s owner is a single EOA; this is a **P** centralization risk, not E-U. The v4.1
  legacy stack was not fully enumerated (the listed v4.1 address is not a factory).
* No secrets, keyed RPC URLs or `.env` contents are written in this folder. Public endpoints only.

## 6. Files

```
small-leads/
├── README.md                  # this file
├── summary.json               # machine-readable summary
├── bosmo-backbone/
│   ├── README.md
│   └── analysis/              # raw state, exact sim, independent child review
├── openfour/
│   ├── README.md
│   └── analysis/              # 40-token scan, accrued-tax/pool economics
├── genius-fun/
│   ├── README.md
│   └── analysis/              # source/live-state notes
├── poc/                       # Foundry fork checks (3/3 pass)
├── ci/run.sh                  # bOSMO live reproduction for CI
├── ci-out/                    # CI results
└── ci-log.txt                 # downloaded CI log
```
