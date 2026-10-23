# LiquidLoans (PulseChain) — CDP deep-dive: TVL drop is a price artifact; **no unprivileged path** (E-U = $0)

**Date:** 2026-10-23 · **Chain:** PulseChain (369) · **Status:** read-only; PoC is a local fork only; **no mainnet transaction was signed or sent.**
**Block:** 27,868,978 (PulseChain) · **PoC:** 5/5 tests PASS in GitHub Actions ([run 40010530029](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40010530029)) · **Folder:** `liquidloans/`

---

## TL;DR

| Item | Value |
|---|---|
| **Target (pass-2 OPEN #7)** | `0x9159f1d2a9f51998fc9ab03fbd8f265ab14a1b3b` |
| **Correction** | That address is the **LOAN governance token**, *not* the CDP. The CDP is the Liquity-v1 fork below. |
| **CDP core** | BorrowerOperations `0xa09bB56B…8BbF09` · VaultManager `0xD79bfb86…02D2Ab` · StabilityPool `0x7bFD4066…f84bc` · USDL `0x0dEEd148…6598A162` |
| **System at block 27,868,978** | **348,005,202,970.03 PLS** collateral · **955,590.92 USDL** debt · TCR **206%** · 96 vaults · **min ICR 1.516** |
| **TVL drop $4.28M → $1.63M** | **PLS oracle price −48%** (9.4059e-6 → 4.8683e-6) **+ a 6.3% collateral outflow**; no drain, no attacker trail |
| **Live extractable (unprivileged) — E-U** | **$0** |
| **H-O (self-service only)** | ≈ **$2.16M** user-owned (StabilityPool + LOANStaking + unclaimed CollSurplus) |
| **P (privileged / key)** | secondary-oracle UUPS owner is a **Gnosis Safe**; a compromised Safe could re-price and liquidate. Not external-unprivileged. |
| **Why closed** | Liquity-v1 fork; **all admin renounced** (`owner()=0`); oracle at market & two-sourced; **0 liquidatable vaults**; every exit is `msg.sender`-scoped |
| **Verdict** | **CLOSED — E-U $0 (high confidence).** Residual: sign-flipping oracle-basis peg arb (intended), oracle-Safe key risk (P). |

---

## 1. What the target actually is (correction to the pass-2 row)

The pass-2 OPEN #7 row labelled `0x9159f1d2a9f51998fc9ab03fbd8f265ab14a1b3b` "CDP (code present, ~5.5 KB)".
On-chain it is the **`LOANToken`** (verified source, solc 0.6.11, `totalSupply = 5.5e30`, symbol `LOAN`).
The actual protocol is **LiquidLoans**, a fork of **Liquity v1** on PulseChain (contracts renamed:
Vault = Trove, VaultManager = TroveManager, USDL = LUSD, PLS = ETH). The docs confirm the Liquity fork,
the Fetch-oracle/PulseX-V2-oracle design, and a Halborn review (DefiLlama's `audits: 0` is a data gap).

Deployed core (all verified source on PulseChain Blockscout unless noted):

| Role | Address |
|---|---|
| BorrowerOperations | `0xa09bB56B39D652988C7E7d3665aA7EC7308BbF09` |
| VaultManager | `0xD79bfb86fA06e8782b401bC0197d92563602D2Ab` |
| StabilityPool | `0x7bFD406632483ad00c6EdF655E04De91A96f84bc` |
| ActivePool | `0x3983f040916681085D7949F7ee78BfA12c5CB119` |
| DefaultPool | `0x717A736b34308d97EeFb5bd91539E0D3B9142dBE` |
| CollSurplusPool | `0x88742a6Fd16A00Fc671fff371E4CC8ff58378596` |
| GasPool | `0xdec755e596c43439d039e48bf145dfb4e45fee3d` |
| SortedVaults | `0xE1246517c3eCa1e2a198fc927296d8ff87BaBD3c` |
| PriceFeed | `0xc65Abc8B9B4B3cEE03430f6fc3d8A4760221A113` |
| USDL | `0x0dEEd1486bc52aA0d3E6f8849cEC5adD6598A162` |
| LOAN | `0x9159f1D2a9f51998Fc9Ab03fbd8f265ab14A1b3B` |
| CommunityIssuance / LOANStaking | `0x42151052…220895` / `0x853F0CD4…71C995` |

## 2. The bug / mechanism in exact terms

**There is no bug.** The mechanism investigated is the Liquity CDP math itself:

- **Borrow** (`BorrowerOperations.openVault`): lock PLS, mint USDL at `ICR = coll·price / debt ≥ MCR (110%)`, plus a 0.5–5% borrowing fee to LOANStaking.
- **Liquidate** (`VaultManager.liquidate` / `liquidateVaults`): only vaults with `ICR < MCR`; the Stability Pool offsets debt and takes collateral; liquidator gets `USDL_GAS_COMPENSATION = 200 USDL`.
- **Redeem** (`VaultManager.redeemCollateral`): burn USDL for PLS from the lowest-ICR vaults at the oracle price, minus `baseRate + redeemedFraction/BETA` (floor 0.5%).
- **Oracle** (`PriceFeed.fetchPrice`, callable by anyone): primary = "Fetch" (`0xb3E153ab…`), secondary = a PulseX-V2 TWAP UUPS proxy (`0x6039D143…`); falls back only when the primary is broken/frozen (>4h) or deviates >50%.

Every one of these is the canonical Liquity v1.1 logic. The only admin surface is the **secondary oracle's
UUPS proxy**, owned by Gnosis Safe `0xF796661E…`; the PriceFeed, VaultManager, BorrowerOperations,
StabilityPool, ActivePool, DefaultPool and CollSurplusPool are all **owner-renounced (`owner()=0`)**.

## 3. Live-state assessment (block 27,868,978)

| Check | Value |
|---|---|
| `getEntireSystemColl()` | 348,005,202,970.03 PLS |
| `getEntireSystemDebt()` | 955,590.92 USDL (= USDL `totalSupply`, no phantom gas-comp) |
| `PriceFeed.fetchPrice()` / `lastGoodPrice()` | 5.6558e-6 / 5.7252e-6 |
| Fetch primary (value, ts) | 5.6558e-6, fresh (head-time) |
| Secondary oracle (value, ts) | 5.5918e-6, fresh; divergence 1.1% (< 5% cap) |
| `status()` | `0` = fetchWorking |
| `getTCR(price)` | 2.0597e18 = **206%** (MCR 110%, CCR 150%); `checkRecoveryMode` = false |
| `getVaultOwnersCount()` | **96**; min ICR **1.516**, median 1.989, max 7.249; **0 below MCR** |
| `baseRate()` | 5.1864e15 (0.52%) |
| Balances | ActivePool 348.0e9 PLS; StabilityPool 66.65e9 PLS + 605,042.75 USDL; CollSurplusPool 7.33e9 PLS; LOANStaking 2.614e12 LOAN + 50,528.77 USDL + 1.316e9 PLS; CommunityIssuance 4.464e11 LOAN |
| Marks | PLS $5.6768e-6 (WPLS) / $4.948e-6 (native, DefiLlama); USDL $0.98947; LOAN $4.1366e-7 |

## 4. What an attacker can / cannot do

| Path | Result |
|---|---|
| **Liquidate** a healthy vault | Reverts — min ICR 1.516 ≫ MCR 1.10; **0 liquidatable vaults** |
| **Oracle manipulation** (push a false price) | Primary Fetch is fresh & reporter-based; secondary is a period-limited TWAP; both track market (WPLS $5.68e-6 vs oracle $5.66e-6). The fallback needs the primary frozen >4h — not attacker-controllable |
| **Redeem USDL at a profit** | A sign-flipping **oracle-vs-market basis trade** (≈±5%; −$7.87 to +$45.71 per 1,000 USDL across CI blocks) — the *intended* peg mechanism, bounded by USDL DEX depth (~$7k/24h) and the $955k debt. Not protocol extraction |
| **Borrow and walk away** | Max borrow = `coll·price/1.10`; the minted USDL is worth **less** than the collateral's market value (§7 test E: $5.06 vs $5.64 per 1M PLS). No value created |
| **Claim CollSurplus / withdraw StabilityPool / unstake LOAN for someone else** | Impossible — `CollSurplusPool.claimColl(msg.sender)` is gated to BorrowerOperations and passes the caller; `withdrawFromSP`/LOANStaking are `msg.sender`-scoped |
| **Use admin keys** | None exist (all renounced) except the secondary-oracle Safe |

## 5. The TVL drop, reconciled

Full reconciliation in `analysis/tvl-drop.md`. In short:

| UTC | block | system collateral (PLS) | oracle $/PLS | coll USD |
|---|---:|---:|---:|---:|
| 2026-10-13 | 27,782,555 | 377,007,128,871.78 | 9.4059e-6 | $3,545,800 |
| 2026-10-15 | 27,799,374 | 360,551,804,501.52 | 6.2139e-6 | $2,240,400 |
| 2026-10-19 | 27,832,894 | 353,174,650,006.15 | 4.8683e-6 | $1,719,400 |
| 2026-10-23 | 27,868,978 | 348,005,202,970.03 | 5.7252e-6 | $1,992,400 |

**Price leg ≈ −$1.71M (oracle −48%); quantity leg ≈ −$116k (−6.3% PLS); debt −21.6% (repayments/redemptions).**
DefiLlama's number is reproduced exactly by `ActivePool_PLS × DefiLlama's own PLS price` ($4.948e-6 native,
$5.677e-6 WPLS — a 13% internal spread); the "staking" leg is staked LOAN × $4.1366e-7. **No outflow trail.**

## 6. Categories

- **E-U = $0.** No external-unprivileged extraction path found.
- **H-O ≈ $2.16M** — user-owned, self-service only: StabilityPool $977k (66.65e9 PLS + 605k USDL), LOANStaking $1.139M (2.614e12 LOAN + 50.5k USDL + 1.32e9 PLS), CollSurplusPool $41.6k. (Borrower collateral $1.97M is locked behind debt repayment.)
- **P = $0 proven** — the only privileged surface is the secondary-oracle Gnosis Safe (`0xF796661E…`); a compromised Safe could re-price the oracle and liquidate/drain, but that is key-compromise, not an unprivileged path.
- **S = $0.** No bricked value identified.

## 7. PoC / fork verification

`poc/` — Foundry project; forks PulseChain (`https://rpc.pulsechain.com`, public) via `vm.createSelectFork`.
**5/5 PASS** (local + CI). Key numbers:

- `test_A_state_and_oracle` — coll 348.0e9 PLS, debt 955,590.92 USDL, TCR 206%, both oracles live, divergence 1.1%.
- `test_B_no_liquidatable_vault` — 96 vaults, min ICR **1.5156**, **0 liquidatable**; `liquidate(lowest)` reverts.
- `test_C_redemption_math` — 1,000 USDL → fee 5.02 USDL; net **+$2.00 (+0.2%) locally**, **−$7.87** at the first CI block, **+$45.71 (+4.6%)** at a later CI block — a sign-flipping **oracle-vs-market basis trade** (≈±5%), the *intended* redemption mechanism; bounded by USDL DEX depth (~$7k/24h volume) and the $955k debt. Asserted < 50% of notional.
- `test_D_scoped_exits_revert` — `claimColl(attacker)` and `withdrawFromSP(1)` from a fresh address both revert while the pools are funded (605,042.75 USDL, 66.65e9 PLS, 7.33e9 PLS).
- `test_E_borrow_math` — 1M PLS collateral $5,636 market vs max-borrow market value $5,062 → no profit.

CI: `bash /home/heisenberg/CA/ci/ci-run.sh liquidloans` (workflow runs `ci/run.sh` then `forge test -vvv`).
**CI run (PASS, 5/5, fork block 27,873,228):** https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40010530029 ·
artifact `result-liquidloans` → `ci-out/liquidloans-state.json` (matches the local capture). Earlier passing run: [39921598361](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39921598361).

## 8. Verdict & residual risk

**CLOSED — E-U $0 (high confidence).** LiquidLoans is a well-formed Liquity v1 fork with no live admin,
a two-sourced oracle at market, no liquidatable vaults, and strictly self-scoped exits. The pass-2
"$4.28M → $1.63M collapse" is a **PLS price artifact plus modest repayments**, not an exploit.

Residual (monitor, not extract):
1. **Secondary-oracle key risk (P):** UUPS proxy `0x6039D143…` is upgradeable by Gnosis Safe
   `0xF796661E25ee682Fc090C9dB1BdB981b3b252999`. A Safe compromise → arbitrary price → liquidations/drain.
2. **Peg/basis arb (E-U-conditional, ≈±5%):** USDL trades ~1% under $1 and the oracle can lag the market; redemption is the intended correction. Bounded by USDL DEX depth (~$7k/24h) and the $955k debt.
3. **Base deployment** (liquidloans.io advertises PulseChain + Base) is **out of scope** of this PulseChain OPEN.

## 9. Methodology & sources

- On-chain: PulseChain public RPC `https://rpc.pulsechain.com` (`eth_call`/`eth_getStorageAt`/`eth_getLogs`, blocks 27,782,555–27,868,978); PulseChain Blockscout (`api.scan.pulsechain.com`) for verified source/ABI; `cast` 1.8.5.
- Prices: `coins.llama.fi/prices/current` (PLS, WPLS, USDL, LOAN); GeckoTerminal; DefiLlama `/protocol/liquidloans` + `/protocols`.
- Docs: docs.liquidloans.io (Liquity fork; Fetch oracle + PulseX V2 fallback; Halborn review).
- PoC: Foundry 0.8.24, local + GitHub Actions fork.

**Caveats.** Point-in-time 2026-10-23; vault set, prices and the secondary oracle must be re-read before any action.
The ~$2.16M H-O figure is mark-to-market at the stated marks. The oracle-Safe (P) risk is stated but not proven exploited.
No secrets or keyed RPC URLs are stored in this folder; all work is read-only.

## 10. Files

- `README.md` (this) · `summary.json`
- `analysis/state.md` · `analysis/tvl-drop.md` · `analysis/vaults.txt` (96 vaults)
- `poc/` (`test/LiquidLoans.t.sol`) · `ci/run.sh` · `ci-out/liquidloans-state.json`
- `ci-log.txt` · `ci-artifacts/`
