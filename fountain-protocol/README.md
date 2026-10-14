# Fountain Protocol (Oasis Emerald) — zombie-hunt II, L2 Phase-2 deep-dive

**Date:** 2026-10-14 · **Chain:** Oasis Emerald (EVM, chain id 42262) · **Block (pinned):** 22,380,248
**Status:** read-only; fork-verified PoC only; no mainnet transactions; no secrets.

**Mission:** determine rigorously how much an external, unprivileged attacker can extract **live, right now**
from Fountain Protocol (fresh-attacker standard: no legacy positions, whitelists, keys or roles).

---

## 1. TL;DR

| Target | Live value (cash in markets) | Live extractable by external attacker (E-U) | Why closed / open | Latent risk |
|---|---|---|---|---|
| Classic comptroller `0xA7684aE7…` (4 markets: fROSE, fETH, fUSDT, fUSDC) | **~$89.2K** (oracle prices) / $93.5K (market prices) | **$0.00** | mint+borrow paused per market since 2023‑03‑11; **transfer+seize paused globally** → no way to acquire cTokens, open a position, or liquidate. Oracle stale (Band last update 2026‑07‑03). | If an admin ever unpauses seize: 246 accounts have live shortfalls ($16.7K total) but only ~$1.2K of priced collateral — liquidator profit bounded by ~$0.5K (10% incentive + 28–30% stale-price bonus). **Privileged-only.** |
| USD comptroller `0x1C0C3079…` (4 markets) | **$1.25** (0.553 USDT cash + 0.7 USDT debt) | **$0.00** | Markets are *not* paused, but the only live value is $1.25; the only borrower is over‑collateralised (no shortfall); minting requires ≥ collateral; empty-market inflation is a wash with no other suppliers. | None material (dust). |
| LPT comptroller `0x7c4d0c83…` (7 markets) | ~**$0** cash (0.0000571 ROSE + LP dust) | **$0.00** | mint+borrow paused per market since 2022‑09‑25; **transfer+seize paused globally**; all cash borrowed out. | 13.30M ROSE of debt (≈$82K oracle / $114K market) is uncollectible-by-liquidation; supplier claims are effectively stuck (S) unless borrowers repay voluntarily. |
| FTP token `0xd1dF9CE4…` + comptroller reward pools (927.6M + 6.6M FTP) | FTP is effectively worthless (only pool: 3,917 wROSE / 14.33M FTP ⇒ ~$0.0000017/FTP, ~$24 of wROSE depth) | **$0.00** | `claimComp` pays only the caller's *own* accrued rewards; a fresh attacker accrues 0 (fork-verified). | Holders can still claim accrued FTP (H-O); no market to sell into. |

### Total live extractable now (external unprivileged): **$0.00** — confidence **high**

An honest zero: every value-bearing path is either paused (mint/borrow/transfer/seize on both funded
comptrollers), requires owning a legacy position (redeem/claim — holder-only), or is privileged
(admin/Timelock/FTPGuardian). The only unpaused comptroller holds $1.25 and offers no profitable strategy.

---

## 2. The mechanism in exact terms

Fountain Protocol is a **Compound v2 fork** (Compound sources of the 0.5.16 era, plus custom FTP mining and
timestamp-based interest accrual) deployed on Oasis Emerald in Feb–Apr 2022. Three `Unitroller` proxies front
one `Comptroller` implementation each:

| Comptroller | Address | Implementation (verified) | Admin | Oracle |
|---|---|---|---|---|
| classic | `0xA7684aE7e07Dac91113900342b3ef25B9Fd1D841` | `0x1d3deb0ac637a85969a81be567a8627f57961856` (`Comptroller`) | `Timelock 0x5d4Ae9eCBeEa…` (admin EOA `0xf750B9a7…`) | `0x3789ae71…` (Band-based) |
| usd | `0x1C0C30795802Bf2B3232a824f41629BbBCF63127` | `0xd8f26369e00b2a00ef58122ebf13ea1f718cb9f2` (`USDComptroller`) | EOA `0x4Ce41518…` | `0x512efb22…` (Band-based) |
| lpt | `0x7c4d0c834701C6E7F57b8C1424d30aDC46eA0840` | `0xcf7aa043748c904a1c63eff40b08200d3daa9d4b` (`Comptroller`) | EOA `0x4Ce41518…` | `0x13322c29…` (LP oracle: DEX spot reserves + Band) |

All 15 cToken markets are **immutable** (`CErc20Immutable` / `CEther`, no delegate). The `pauseGuardian` on all
three comptrollers is the `FTPGuardian` contract `0xC8C8Ae893611A617d128742AbE5AEd7952c71B7c`
(`systemStop(address)` — callable only by its `guardian` EOA `0xf750B9a7…`).

### What closes the extraction paths

1. **Mint & borrow paused per market** (`mintGuardianPaused[market]=1`, `borrowGuardianPaused[market]=1`):
   `mintAllowed()` reverts `"mint is paused"`, `borrowAllowed()` reverts `"borrow is paused"` — an attacker
   cannot open any position in the two funded comptrollers.
2. **Transfer & seize paused globally** (`transferGuardianPaused=1`, `seizeGuardianPaused=1`):
   `transferAllowed()` reverts `"transfer is paused"` and `seizeAllowed()` reverts `"seize is paused"`.
   Consequence: an attacker cannot acquire existing cTokens (transfer/`transferFrom` blocked) **and no
   liquidation can complete** — `liquidateBorrow` always ends in `seize()` → `seizeAllowed()` → revert.
3. **Timeline (on-chain proven):** the last classic `systemStop` was at 2023‑03‑11 14:53 UTC
   (round 4,896,841) and the last lpt `systemStop` at 2022‑09‑25 19:35 UTC (round 3,015,970); pause flags read
   `1` at every sampled block since (17M … 22.38M). The last *successful* mint/borrow in classic was
   2023‑03‑11 (before the pause); after it only `redeem`/`repay` succeeded (last redeem 2024‑07‑25).
4. **`claimComp` cannot be farmed:** it distributes `compAccrued[holder]` from frozen indices
   (`startSpeedTime` 2022‑02‑24 + 48×30‑day decay = mining ended 2026‑02‑04); a fresh address accrues 0 and
   receives 0 (fork-verified, `test_G`).
5. **Admin paths are privileged:** `_setMintPaused/…/_setSeizePaused(false)` require `pauseGuardian|admin`
   and only the admin may *unpause*; `Unitroller._acceptImplementation` requires the pending impl (zero);
   the `Timelock` requires `msg.sender == admin` for queue/execute/`executeImmediate` (and its 30‑day
   `executeImmediate` deadline expired in Mar 2022).
6. **USD comptroller (unpaused) has no material value and no shortfall:** cash 0.5533 USDT; the single
   borrower is over‑collateralised (liquidity $0.49, shortfall 0); minting requires ≥ collateral
   (cf 0.95), and the empty-market donation/inflation play is a wash (fork-verified, `test_K`) because
   there are no other suppliers to dilute.

### Oracle (staleness — relevant to latent risk, not to E-U)

The classic/usd oracles read **Band Protocol** `StdReference 0xda7a001b…`; the LPT oracle additionally prices
LP tokens from DEX **spot reserves**. Band data on Emerald was last updated **2026‑07‑03** (≥100 days stale at
the pinned block):

| Feed | Band rate (1e18) | Market (DefiLlama, 2026‑10‑11) | Divergence |
|---|---|---|---|
| ROSE | 0.00617995 | 0.00858042 | oracle **−28%** |
| ETH | 1742.93689471 | 2504.79020248 | oracle **−30%** |
| USDT | 0.99880078 | ~1.00 | ~par |
| USDC | 0.99980003 | ~1.00 | ~par |

Because the oracle is stale **low**, no over-borrowing is possible; instead, collateral is *under*-valued,
which would make liquidations extra profitable for a liquidator (and would liquidate some positions that are
healthy at market prices) — but seize is paused.

---

## 3. Live-state assessment (all reads at Emerald block 22,380,248 unless noted)

### Comptrollers (roles, pauses, params)

| Field | classic | usd | lpt |
|---|---|---|---|
| `admin()` | `0x5d4Ae9eCBeEa7038324582d8b4B745a715Ddfb72` (Timelock; `admin()`=EOA `0xf750B9a7…`) | `0x4Ce41518591272a42406b4829f6C4f66907891e9` (EOA) | `0x4Ce41518591272a42406b4829f6C4f66907891e9` (EOA) |
| `pauseGuardian()` | FTPGuardian `0xC8C8Ae89…` (guardian EOA `0xf750B9a7…`) | same | same |
| `seizeGuardianPaused()` | **1** | 0 | **1** |
| `transferGuardianPaused()` | **1** | 0 | **1** |
| `closeFactor` / `liqIncentive` | 0.5 / 1.10 | 0.5 / 1.01 | 0.5 / 1.15 |
| mint/borrow paused per market | **all 4** | none | **all 7** |

### Markets — cash, borrows, reserves, claims (raw units; USD at oracle prices)

| Market | Underlying | Cash | Borrows | Reserves | Supplier claims | Cash USD (oracle) |
|---|---|---|---|---|---|---|
| classic fROSE `0xd7d588…` | ROSE (CEther) | 322,698.74 ROSE | 65,671.35 ROSE | 43,706.69 ROSE | 344,665.4 ROSE | $1,994 |
| classic fETH `0x275b88…` | WETH (wormhole) | 4.641647 WETH | 0.012206 WETH | 1.329432 WETH | 3.324415 WETH | $8,090 |
| classic fUSDT `0x352cc3…` | USDT | 78,869.089 USDT | 3,939.008 USDT | 11,511.863 USDT | 71,296.23 USDT | $78,775 |
| classic fUSDC `0x61d90f…` | USDC | 337.935 USDC | 15,343.084 USDC | 4,270.314 USDC | 11,410.71 USDC | $338 |
| lpt fROSE `0x63f1fe…` | ROSE (CEther) | 0.0000571 ROSE | **13,305,841.95 ROSE** | 11,246.20 ROSE | 13,294,595.7 ROSE | ~$0 |
| lpt LP markets (6) | LP tokens | dust | dust–2,332 LP | dust | dust | ~$0 |
| usd fUSDT_wormhole `0x255270…` | USDT | 0.553299 USDT | 0.700000 USDT | 0 | 1.253299 USDT | $0.55 |
| usd fUSDC_* (3) | USDC | 0 | 0 | 0 | 0 | $0 |

**Cash total (what suppliers could redeem today):** **$89,196.8** at protocol-oracle prices
(**$93,532.8** at DefiLlama market prices, matching the Phase‑1 triage figure). The single largest claim is
`0xf8aae8d5…` with 3,250,268,038,774 fUSDT cTokens ≈ **68,900 USDT**.

### Bad debt / shortfall accounts (live, at oracle prices — fork-verified via `getAccountLiquidity`)

| Account | Comptroller | Shortfall (USD 1e18) | Debt | Collateral |
|---|---|---|---|---|
| `0x4ec0306f…` | classic | **$7,825.21** | 7,997.42 USDC (+2 wei USDT) | 4,467,118,274,532 cROSE ≈ 46,010 ROSE ($284) |
| `0xb4049a0d…` | classic | **$1,171.84** | 7,641.54 ROSE + 1,196.35 USDC | 635,430,094,426 cROSE ≈ 6,545 ROSE ($40) |
| `0x9046fe48…` | classic | $42.57 | 3,035.47 ROSE + 315.79 USDT | mixed cTokens |
| `0xe0da368d…`, `0xe8a78a33…` | classic | <$0.001 each | tiny | tiny |
| `0x94aa22b1…` | lpt | $0.49 | 1.0029 ROSE + dust | 995,397,473 cROSE-lpt |
| none | usd | — | — | (only borrower is over-collateralised) |

These accounts **cannot be liquidated** (seize paused). They are the reason the fUSDC/lpt suppliers' claims
exceed available cash.

**Full enumeration (CI, block 22,380,251, 1,614 candidate accounts):** 758 accounts still carry debt and
**246 have a live shortfall** (protocol view, stale oracle): 5 ≥ $1,000 · 4 in $100–1,000 · 47 in $1–100 ·
91 in $0.01–1 · 99 < $0.01 — **total shortfall $16,748.41**. Every shortfall account holds some cToken
collateral, so absent the seize pause all of it would be liquidatable; today none of it is.

**Market ERC20 balances (CI scan):** every cErc20 market holds **only its own underlying** (plus zero of
everything else) — the unprotected `sweepToken` (inherited from pre-2021-fix Compound: no `msg.sender == admin`
guard) has nothing to sweep in this deployment.

**Open item (does not affect the verdict):** the lpt fROSE market's `totalBorrows` (13,305,841.95 ROSE) exceeds
the sum of `borrow(uint256)` amounts recoverable from the public Nexus tx history for that market
(4,700,101.58 ROSE over 368 borrow txs) even though its borrow index is only 1.0348 — i.e. some borrow txs are
not surfaced by the public indexer (likely internal-call borrows). The market's own accounting is internally
consistent (`cash + borrows − reserves == totalSupply × exchangeRate`), so the supplier claims and the S
classification below stand; the identity of the remaining borrowers is not resolvable with the public
indexers used here.

### Code verification (deployed == published source)

`verify/` builds the published repo (`github.com/dev-fountain/fountain-protocol`, commit `dd9475eb…`,
solc 0.5.16, optimizer 200) and `ci/verify_bytecode.py` compares runtime bytecode against Emerald:
**28/28 deployed contracts match metadata-stripped** — 3 Unitroller proxies, 3 comptroller implementations,
2 `OracleAnchoredView`, 1 `LPOracleAnchoredView`, 2 `JumpRateModelV2`, 1 `WhitePaperInterestRateModel`,
1 `Timelock`, 13 `CErc20Immutable`, 2 `CEther`. This closes the "unverified bytecode" gap.

---

## 4. What an attacker can and cannot do (exact paths)

| Path | Function (permissionless) | Result today |
|---|---|---|
| Open a position in classic/lpt | `mint()/mint(uint)`, `borrow(uint)` | **reverts** `"mint is paused"` / `"borrow is paused"` |
| Acquire cTokens (any market) | `transfer`, `transferFrom` | **reverts** `"transfer is paused"` |
| Liquidate an underwater account | `liquidateBorrow(...)` | **reverts** `"seize is paused"` (after repay+calc; even `seize()` directly reverts) |
| Steal via seizure | `seize()` | **reverts** `"seize is paused"` |
| Farm FTP rewards | `claimComp(attacker)` | pays **0** (no position, indices frozen; 927.6M FTP stays in the comptroller) |
| Redeem someone else's cTokens | `redeem*` | impossible (own balance only; acquisition blocked) |
| Donate to inflate exchange rate | `_addReserves(uint)` | allowed, but only increases existing holders' value — **no profit** |
| Abuse `sweepToken` (pre-fix Compound, no admin guard) | `sweepToken(fakeToken)` | allowed — the market calls an attacker-chosen contract and sends its non-underlying token balances **to the admin**. No market holds non-underlying ERC20s (CI scan: only each market's own underlying), and the "cToken-as-caller" callback **cannot** escalate to `seize()` because the caller of a nested `seize()` is the attacker contract, which is not a listed market (fork-verified, `test_O`). **No caller profit.** |
| Unpause / admin | `_setMintPaused/_setSeizePaused(false)`, `_acceptImplementation`, Timelock | **reverts** `"only pause guardian and admin can pause"` / `"only admin can unpause"` / unauthorized |
| usd comptroller (open) | `mint`, `borrow`, `seize`, `transfer` | work, but max extractable = **$0** (dust; must post ≥ collateral; no shortfall to liquidate) |

Preconditions for the only theoretical extraction (a liquidation) — all false/unreachable:
(a) seize not paused — **paused**; (b) an underwater account — exists, but (a) blocks; (c) attacker capital
— flash-loanable, but irrelevant without (a).

**Costs:** an attacker's only live actions cost gas and return ≤ 0 (donations/repays return nothing).

---

## 5. PoC / fork verification

- Foundry project `poc/` forks Emerald at block 22,380,248 (local anvil fork started by `ci/run.sh`; `OASIS_RPC`
  overridable) and runs 15 tests (`poc/test/Fountain.t.sol`): state re-verification, every attack path above
  (expect-revert), the unprotected-`sweepToken` escalation attempt (negative), H-O recovery demos (redeem +
  claimComp), the usd dust/inflation analysis, oracle staleness, lpt bad debt.
- `ci/run.sh`: (1) builds `verify/` (legacy sources), (2) bytecode comparison, (3) live enumeration
  (Nexus tx history → candidate accounts → live positions at the pinned block; output `ci-out/enumeration.json`).
- **CI runs:**

| Run | URL | Result |
|---|---|---|
| run 3 (`38497766124`) | https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38497766124 | bytecode 28/28 ✓; enumeration ✓ (artifacts in `ci-out/`); Foundry suite 9/15 (4 RPC-429 infra failures + 2 test bugs, fixed) |
| run 4 (`38502878256`) | https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38502878256 | final: anvil-fork PoC + bytecode + enumeration |

Test results (final run): _(to be filled from run 4 logs)_

---

## 6. Verdict and residual/latent risk

**Verdict: E-U = $0.00 (high confidence).** The two comptrollers that hold 99.99% of the live cash have been
globally frozen since 2022‑09/2023‑03 (mint+borrow per market; transfer+seize globally), and the third holds
$1.25 with no profitable path. There is no code-level bug in the deployed contracts that bypasses these
gates (deployed bytecode == published source, 28/28), and no permissionless function pays a fresh caller.

**Latent risk (not extractable today):**
1. **If an admin unpauses** (EOA `0x4Ce41518…` for usd/lpt; Timelock `0x5d4Ae9eC…` with admin EOA
   `0xf750B9a7…` for classic), liquidations become possible. Quantified at live state: the 246 underwater
   accounts hold only **~$1,218 of priced collateral** (ROSE/ETH/stables; 31 more hold only unpriced LP dust)
   against $16,748 of bad debt — so a liquidator's total take is bounded by ~$1.2K of collateral, of which the
   profit is the 10% incentive plus the stale-price bonus (ROSE oracle is 28% below market ⇒ seizing at oracle
   prices is worth ~1.39× the repay). Order-of-magnitude: **≤ ~$0.5K of liquidator profit**, and only after a
   privileged unpause. This is **P** (privileged trigger) + external liquidator, not E-U.
2. **LPT oracle is spot-price based** (`reserveProductAndTotalSupply` + `getReserves`) — manipulable with a
   flash loan if the markets were unpaused; today it can only affect the *liquidity check* (not redemption
   amounts), so no exploit.
3. **Interest keeps accruing on frozen markets** (e.g., fUSDC borrow rate ≈ 285%/yr at 98% utilisation) —
   bad debt grows; suppliers' redeemable value is capped by cash regardless.
4. **Bad debt is uncollectible by liquidation** while seize is paused: lpt fROSE 13.30M ROSE and classic
   fUSDC 15.3K USDC of debt are effectively stuck unless borrowers voluntarily repay (S).

**Blockers that keep funds where they are:** `seizeGuardianPaused=1` + `transferGuardianPaused=1` (classic,
lpt); `mintGuardianPaused`/`borrowGuardianPaused` per market; admins/pauseGuardian are EOAs/Timelock not
attacker-reachable; FTP has no market value.

---

## 7. Categories

| Category | Amount | Notes |
|---|---|---|
| **E-U** (external unprivileged) | **$0.00** | all value-bearing paths paused/gated (high confidence) |
| **H-O** (holder-only) | up to **$89,196.8** at oracle prices ($93,532.8 market) | suppliers may `redeem` cash; largest claim 68.9K USDT (`0xf8aae8d5…`); FTP claims of accrued holders |
| **P** (privileged) | reserves ≈ **$18,366** (43,706.69 ROSE + 1.3294 WETH + 11,511.86 USDT + 4,270.31 USDC + 11,246.2 ROSE-lpt) + unpause authority | `_reduceReserves` (admin), pause/unpause, oracle/impl admin |
| **S** (stuck) | ≈ **$82.2K** oracle / **$114.1K** market (lpt fROSE claims, cash ≈ 0) + classic fUSDC claims above cash ($11.1K) + uncollectible debt | no liquidations; cash ≈ 0 in lpt |

---

## 8. Methodology & sources

1. **Deployed reality:** `eth_getCode`/`eth_call` on Emerald (public RPCs `emerald.oasis.dev`, `1rpc.io/oasis/emerald`)
   at pinned block 22,380,248; Unitroller implementation slots; 28/28 bytecode match vs the published repo
   (solc 0.5.16, optimizer 200).
2. **State:** comptroller roles/pauses/params; per-market cash/borrows/reserves/supply/exchange rate/accrual;
   per-account `getAccountLiquidity`/`getAccountSnapshot`/`compAccrued`; oracle reads (`getUnderlyingPrice`,
   `price(string)`, Band `getReferenceData` incl. `lastUpdated`).
3. **History:** Nexus API (`nexus.oasis.io/v1/emerald`) tx history per contract (method-decoded), systemStop
   calls from the FTPGuardian, `Failure` event decoding for liquidation attempts (2026‑01‑08 attempts failed
   with `INSUFFICIENT_SHORTFALL`, i.e., accounts healthy then; no successful liquidation since the pause).
4. **Fork PoC:** Foundry tests on CI (public Emerald RPC) — attack paths expect-revert; H-O paths succeed.
5. **USD pricing:** DefiLlama coins API at scan time (market) and protocol oracle prices (both reported).

**Caveats:** point-in-time snapshot; USD at stated prices; the FTP token is unpriced/illiquid (valued via its
only DEX pool, ~$24 depth); `getAccountLiquidity` uses the stale oracle, so "shortfall" is a protocol-view
number; the classic admin is a Timelock whose admin EOA may or may not still be live — that only affects the
latent-risk (P) scenario.

---

## 9. Files index

- `README.md` (this file) · `summary.json`
- `analysis/` — probe scripts (`probe_state.py`, `probe2.py`, `probe3.py`, `probe4.py`, `txscan.py`,
  `decode_state.py`), raw dumps (`state-*.json`, `state2-*.json`, `state3-*.json`, `state4-*.json`),
  consolidated `state-summary.json`, `tx-history-summary.json`
- `poc/` — Foundry project (`test/Fountain.t.sol`, vendored `lib/forge-std`)
- `verify/` — legacy solc 0.5.16 build of the published sources for bytecode comparison
- `ci/` — `run.sh` (custom job), `verify_bytecode.py`, `enumerate.py`
- `ci-out/` — CI artifacts (`bytecode-verify.json`, `enumeration.json`, …)
- `ci-log.txt`, `ci-artifacts/` — downloaded CI logs/artifacts
