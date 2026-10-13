# InsureDAO — L2 Phase-2 deep dive (zombie-hunt II)

**Date:** 2026-10-13 · **Chains:** Ethereum (v1), Arbitrum (v2), Optimism (v2), Astar (v1) · **Folder:** `insuredao/`
**Status:** read-only research; PoC fork-verified only; **no mainnet transactions were sent**; no secrets in this folder.

---

## 1. TL;DR

| Target | Live custody | Extractable by fresh unprivileged attacker (E-U) | Why closed/open | Latent risk |
|---|---|---|---|---|
| **ETH USDC Vault `0x131fb74C…` (v1)** | **$122,292.30** | **$0.00** | Every value-out needs either (a) the caller's own `attributions` (LP shares), (b) `registry.isListed` **and** code that invokes it, or (c) the owner (`PoolProxy` → 3-of-5 Safe) / a reporting admin. No reporting admin is set → claims are dead. All 12 PoC tests pass. | If the Safe (or a successor owner) sets a reporting admin, that role can forge an incident and drain pools via `redeem`/`borrowValue` (P). |
| ETH staking (`vlINSURE`, veINSURE, iToken & LP gauges) | ≈$1,305.75 (LP WETH side) + INSURE (≈$0) | $0.00 | Gauge/iToken/escrow exits are holder-scoped; `vlINSURE` is explicitly irreversible; INSURE has no market. | InsureDepositor holds 10.75M INSURE with no public transfer-out (S unless owner upgrades). |
| Arbitrum (v2) | $607.06 | **$0.00** (see §7) | v2 Vault; all value-out paths gated (own attribution / onlyMarket / owner EOA); permissionless clones forced onto the real parameters. Owner EOA's $442.52 fee attribution + `emergencyExit` = P. | Privileged EOA paths only. |
| Optimism (v2) | $232.76 | **$0.00** (see §7) | same code/owner config as Arbitrum; gates verified by eth_call reverts. Owner EOA's $174.88 fee attribution + `emergencyExit` = P. | same |
| Astar (v1) | $548.24 | **$0.00** (see §7) | same family as Ethereum v1; all markets Trading; LP claims only; owner EOA `setController` = P; former owner holds a $75.70 legacy claim. | same |
| **Total** | **$124,986.10** | **$0.00** | | |

**Headline: an external, unprivileged, fresh attacker can extract $0.00 live from InsureDAO (high confidence).**
All live value is holder-recoverable (H-O) or privileged (P); nothing is stuck beyond its owner's reach except ~$0 of unmarketable INSURE.

---

## 2. What InsureDAO is and what "live" means here

InsureDAO was a peer-to-pool DeFi insurance protocol (2021–2023, now dead: front-end gone, no activity). Two contract generations exist on-chain:

* **v1 (Ethereum, Astar)** — `Vault` (per-token underwriting pool) + `Factory`-cloned markets: `PoolTemplate` (insurance pool), `IndexTemplate` (leveraged index of pools), `CDSTemplate` (the CDS/"surplus" market). On Ethereum all owner functions route through **`PoolProxy`** `0xF4d046D8…`, whose admins are a **3-of-5 Gnosis Safe** `0x54bE2F27…`. Deployed 2022-02-22 (`pool-contracts@3327626`, solc 0.8.10); Astar runs the same v1 code family (USDC vault).
* **v2 (Arbitrum / Optimism)** — rewritten `Vault` + `Registry` + templates (solc 0.8.12), deployed later; same accounting model (attributions = shares; `valueAll()` = balance + controller funds).

The v1 USDC vault `0x131fb74C6fEdE6D6710FF224E07cE0eD8123f144` holds **122,292.300439 USDC** (`valueAll() == balance() == totalAttributions`, controller = `0x0`, totalDebt = 0, price per share = exactly 1e6). 100% of its `attributions` are held by the 29 registered markets (122,289.085305) plus `PoolProxy` (3.215129 fee dust) plus 5 raw units of dust — nothing is "loose" in the vault.

---

## 3. The bug/mechanism in exact terms (why the money cannot be taken by an outsider)

The vault's value can only leave through:

```
Vault.withdrawValue / withdrawAttribution / withdrawAllAttribution   -> require caller's own attributions
Vault.borrowValue                                      -> onlyMarket (registry.isListed)
Vault.utilize                                          -> controller != 0 (it is 0)  -> reverts
Vault.withdrawRedundant / setController / setKeeper    -> onlyOwner (PoolProxy)
```

`attributions` are only minted by `addValue/addValueBatch` (called by a market, for a depositor who pays) and only moved by the owner of those shares. Therefore an outsider needs **a market that holds shares and pays a third party**. Exhaustive grep of every deployed template (see `analysis/sources/*`) shows the complete set of value-moving calls and their gates:

| Contract | value-out call | gate | reachable by fresh attacker? |
|---|---|---|---|
| PoolTemplate | `withdraw` → `withdrawValue(retVal, msg.sender)` | own iTokens + prior withdrawal request | H-O only (fair value) |
| PoolTemplate | `redeem` → `borrowValue(payout, insured)` | `marketStatus==Payingout` + own policy + merkle proof | **no** — all pools are Trading; `applyCover` is owner-gated |
| PoolTemplate | `applyBounty` → `borrowValue(amount, contributor)` | `onlyOwner` | **no** (owner = PoolProxy; needs reporting admin) |
| PoolTemplate | `_liquidation` → `offsetDebt`/`transferDebt`/`IIndex.compensate` | `applyBounty` (owner) or `resume()` (requires Payingout + pendingEnd) | **no** — no pool is Payingout |
| PoolTemplate | `allocateCredit`/`withdrawCredit` → `transferAttribution(pending, msg.sender)` | caller must be a registered index; `pending` is strictly the index's own premium share (fresh index → 0) | no value captured |
| IndexTemplate | `withdraw` → `withdrawValue` | own iTokens | H-O only |
| IndexTemplate | `compensate` → `offsetDebt` (+ pulls CDS) | `allocPoints[msg.sender] != 0` (owner-set pools only) | **no** |
| CDSTemplate | `withdraw` → `withdrawValue` | own iTokens | H-O only |
| CDSTemplate | `defund` | `onlyOwner` | **no** |
| CDSTemplate | `compensate` → `transferValue(amount, msg.sender)` | `registry.isListed(msg.sender)` **and the caller's own code must call it** | **no** — only `PoolTemplate._liquidation` calls it, and that is owner/resume-gated |
| PoolProxy | `withdraw_admin_fee(token)` | **permissionless** | yes, but moves only PoolProxy's own $3.215 to PoolProxy; `distribute()` to the Safe/Govern distributors reverts; attacker gains nothing |

The critical nuance (and the reason a fresh market cannot be used as a weapon): the only template the Factory leaves open (`templates(0x1dcd35cf…)= (true, true, false)`) is **PoolTemplate**, and a PoolTemplate clone has **no generic external call** — it can only invoke `compensate` on markets that *self-registered* as its indexes, and self-registration is only possible for markets whose code has `registerIndex`, i.e. PoolTemplate clones themselves (which have no `compensate`). `IndexTemplate.set()` (the other `registerIndex` caller) is `onlyOwner`. Hence an attacker-created listed market is inert.

The claim path is **permanently dead**: `default_reporting_admin == 0x0` and `reporting_admin[market] == 0x0` for all 29 markets, so `PoolProxy.pool_apply_cover` / `pool_apply_bounty` (the only routes to the pools' owner-only functions) can never be called by anyone. Without `applyCover`, `redeem()` reverts `ERROR: NO_APPLICABLE_INCIDENT` and no `Payingout` state can be reached.

---

## 4. Live-state assessment (Ethereum, block 26,185,830, 2026-10-13 20:02 UTC)

* Vault `0x131fb74C6fEdE6D6710FF224E07cE0eD8123f144`: `valueAll()=122,292,300,439`; `balance()=122,292,300,439`; `totalAttributions()=122,292,300,439`; `totalDebt()=0`; `controller()=0x0`; `keeper()=0x0`; `token()=USDC`; USDC `balanceOf(vault)=122,292,300,539`.
* Owner stack: `Ownership.owner()` = `PoolProxy 0xF4d046D8…`; `Parameters.getOwner()` = same; `PoolProxy.ownership_admin/parameter_admin/emergency_admin` = `0x54bE2F27E95BdAA5104960aAE7816554C0e3F056` = **Gnosis Safe 1.3.0, threshold 3, owners** `0x44F224b9…, 0xc3EaCb24…, 0xbCc6DCC2…, 0x928472F2…, 0x55951Ce2…` (nonce 2).
* Reporting: `default_reporting_admin = 0x0`; `reporting_admin[*] = 0x0` (all 29); `get_reporter(*) = 0x0`.
* Registry `0xA035Dfd0…` lists **29 markets**; all v1 markets are EIP-1167 clones of PoolTemplate `0x1dcd35cf…` (25), IndexTemplate `0x2b16be3c…` (3), CDSTemplate `0x99f790ad…` (1). All 25 PoolTemplate markets: `marketStatus=0 (Trading)`, `paused=false`.
* Attribution ledger (exact, verified to sum to `totalAttributions` minus 5 wei of dust):

| Market | Type | attributions (USDC) | LP-claimable | notes |
|---|---|---|---|---|
| `0x86c82E8c…` | CDS | 59,793.8410 | 59,793.8410 | `crowdPool` = same; surplus 0 |
| `0x22453153…` | Pool | 16,018.8723 | 16,018.8723 | 100% of iTokens in LiquidityGauge `0xCa2Bd134…` (is_killed=true) |
| `0x8c494310…` | Pool | 10,778.9593 | 10,777.3994 | idxPremium 1.559868; lockedAmount 11,820.67 (stale 2022 policy) |
| `0xDFdFcFEd…` | Pool | 10,000.0000 | 10,000.0000 | single EOA holder |
| `0x1CF1195a…` | Pool | 6,600.0000 | 6,600.0000 | 6,500 EOA + 100 gauge |
| `0xDAea5b1B…` | Index | 5,295.6094 | 5,295.6094 | LP 4,795.10 EOA + 500 gauge |
| `0x641BE011…` | Pool | 5,101.3231 | 5,101.2074 | idxPremium 0.115714; locked 3,000 |
| `0x961DfEcF…` | Pool | 5,000.0000 | 5,000.0000 | — |
| `0xd5f1Ab3c…` | Index | 1,555.1519 | 1,555.1519 | — |
| `0x7E08daB4…` | Index | 1,200.0000 | 1,200.0000 | 100% gauge `0x1A047380…` |
| `0xdF7A7BC9…` | Pool | 500.0000 | 500.0000 | — |
| `0xbDB009e6…` | Pool | 345.0849 | 345.0846 | idxPremium 346 wei |
| `0x0a3f7392…` | Pool | 100.0001 | 100.0001 | locked 500 (expired) |
| `0x58803187…` | Pool | 0.2380 | 0.0000 | all value is index premium 0.238012 |
| `0xC03Ab4bB…` | Pool | 0.0052 | 0.0052 | — |
| 14 others | Pool | 0.0000 | 0.0000 | empty shells |
| `0xF4d046D8…` (PoolProxy) | fees | 3.215129 | — | **P** (Safe) |

* Full 29-row table (machine-readable): `analysis/market-tokens.json`, `analysis/full-state.json`, `analysis/markets-map.json`.
* Staking side: `LiquidityGauge 0xf57882cf…` holds 1,582.94016 of 1,582.94016658 INSURE/WETH LP (`0x1b459aec…`) whose reserves are **0.52094149 WETH + 5,067,155.03 INSURE**; at WETH $2,506.51 (DefiLlama 2026-10-13) the WETH side = **$1,305.75**; INSURE has no market (DexScreener: 0 pairs) → ≈$0 realizable. `VotingEscrow 0x3dc07E60…` holds 5,412,108 INSURE; `InsureDepositor` (vlINSURE proxy `0xA12ab76a…`, impl `0xb0730e7f…`) holds 10,754,075.28 INSURE with no public transfer-out; `lockIncentive=0`, `incentiveInsure=0`, and the aggregated escrow lock **expired 2026-03-19** so `lockInsure()`/`deposit(...,lock=true)` now revert (`Cannot add to expired lock`) — the 10.75M INSURE is frozen in place. The staking stack (escrow, gauges, GaugeController, Minter, InsureDepositor) is owned by a separate **EOA `0x79F5Dc19BC96ec1DB776d39535BDe169e67E33f4`** (P: UUPS-upgrade/relock). The LP gauge is not killed but has `gauge_relative_weight = 0` (no emissions; `claimable_tokens` for a fresh staker = 0). No DEX pairs exist for INSURE or any iToken (DexScreener).
* Live proof that H-O works: the CDS LP `0xcc34E60802…` withdrew 109.397189 USDC (2026-04-28, tx `0xad5d0236…`) and 20.328382 USDC (2026-09-19, tx `0x7ae834ac…`) through `CDS.withdraw`; both succeeded (Blockscout).

---

## 5. What an attacker can / cannot do (exact paths, preconditions, costs)

**Can (all fair-value or zero-profit):**
* Create a market: `Factory.createMarket(PoolTemplate, meta, [1e9, ≥1e9], [anyTarget, USDC, Registry, Parameters])` — permissionless, costs a ≥1,000 USDC initial deposit that becomes the attacker's own iTokens; the clone is registered by the factory (`Registry.isListed = true`). Fork-proven (test_05).
* Deposit/withdraw own funds in any market at exactly 1:1 (vault price is exactly par; rounding always favours the pool).
* Register a fresh market as an index on any pool (`registerIndex`, needs a free slot ≤ `getMaxList=10`); `allocateCredit`/`withdrawCredit` move **zero** value for a fresh index (fork-proven, `pending = 0`).
* Call `unlock(id)` on expired policies (pure public good: reduces `lockedAmount`, unblocking LP withdrawals).
* Call `PoolProxy.withdraw_admin_fee(USDC)` — permissionless; moves **$3.215** of PoolProxy's own fees to PoolProxy and allocates them to the distributors ("Core Dev" 25% / "ReportingDAO" 50% / "Community" 25%). `distribute()` then reverts (distributor contracts have no `distribute(address)`); the attacker receives nothing (fork-proven, test_09).
* Buy iTokens from holders — but they redeem at fair value only (H-O); no discount venue exists.

**Cannot (each verified by revert on the fork):**
* `Vault.withdrawValue/withdrawAttribution/transferValue/offsetDebt` from a zero-attribution address → `WITHDRAW-VALUE_BADCONDITIONS` / `WITHDRAW-ATTRIBUTION_BADCONS` / `TRANSFER-VALUE_BADCONDITIONS` / `ERROR_REPAY_DEBT_BADCONDITIONS`.
* `Vault.borrowValue` from an EOA → `ERROR_ONLY_MARKET`; from a *listed attacker market* only if the market's own code calls it — its only callers (`redeem`, `applyBounty`) are owner/Payingout-gated.
* `Vault.utilize` → `ERROR_CONTROLLER_NOT_SET`; `withdrawRedundant`/`setController`/`setKeeper` → `Caller is not allowed to operate`.
* Pools: `applyCover`/`applyBounty`/`setPaused` → `Caller is not allowed to operate`; `resume` → `ERROR: UNABLE_TO_RESUME`; `redeem` → `ERROR: NO_APPLICABLE_INCIDENT`.
* CDS: `defund`/`setPaused` → `ERROR: ONLY_OWNER`; `compensate` from an EOA → `ERROR:UNREGISTERED`.
* Indexes: `compensate` → `COMPENSATE_UNAUTHORIZED_CALLER`; `set`/`setLeverage` → `Caller is not allowed to operate`.

**Latent (privileged) paths** — reachable only by the 3-of-5 Safe (or a future owner/reporting admin), documented for completeness:
* `PoolProxy.pool_apply_cover` + `redeem` with a forged merkle root can borrow from a pool up to its available balance (and pull the CDS via `IndexTemplate.compensate`).
* `Vault.setController`/`utilize` can move the whole balance to an attacker-controlled controller; `withdrawRedundant` can sweep the tracked-redundant amount; `Registry.supportMarket` + `addValue` can pull tokens from users who still have standing vault allowances.

---

## 6. PoC / fork verification

* Project: `poc/` (Foundry, vendored forge-std; `foundry.toml` solc 0.8.24, cancun). Tests fork Ethereum at the current head through `FORK_RPC_URL`/`RPC_URL` (no secrets stored).
* **Result: 12/12 PASS** on GitLab CI (GitHub Actions blocked by account billing):
  `https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38467538976` (12/12 PASS) and `https://gitlab.com/group18185918/insuredao-ci/-/pipelines/2944108622` (12/12 PASS, fallback) · logs: `ci-out/github-run-38467538976.log`, `ci-out/gitlab-run1.log`.
* Test list (all in `poc/test/InsureDAO.t.sol`):
  1. `test_01_live_state` — vault token/controller/owner/registry, `valueAll≈122,292.30`, par share price, 29 markets, Safe admin, no reporting admin, all markets Trading.
  2. `test_02_attacker_vault_paths_revert` — 9 attacker vault calls revert; `withdrawAllAttribution` is a 0-value no-op.
  3. `test_03_market_owner_paths_revert` — pool/index/CDS owner functions revert for a fresh EOA.
  4. `test_04_claim_paths_dead` — `resume`, `redeem`, CDS `compensate`, index `compensate` all revert.
  5. `test_05_open_template_market_creation` — attacker really can create a listed market with 1,000 USDC (open template, reflist USDC/Registry/Parameters), then: owner fns revert, `registerIndex`+`allocateCredit`+`withdrawCredit` yield `pending=0`, attribution unchanged, market holds no USDC.
  6. `test_06_latent_listed_market_borrow` — shows a *listed* market can borrow from the vault (latent, needs owner/Payingout code path).
  7. `test_07_cds_compensate_latent` — shows a listed market calling CDS `compensate` moves attribution (latent, unreachable by outsiders).
  8. `test_08_honest_lp_withdraw` — sole iToken holder of `0xDFdFcFEd…` withdraws exactly 10,000 USDC after the 14-day lockup (H-O proof).
  9. `test_09_admin_fee_sweep…` — permissionless sweep works, $3.215 allocated 25/50/25, attacker gets $0.
  10. `test_10_unlock_expired_policy` — `lockedAmount` 11,820.67 → 0 via public `unlock(0)`.
  11. `test_11_index_premiums` — index pending premium `1,559,027` raw ($1.56) is index-owned (H-O), not capturable by a fresh index.
  12. `test_12_staking_side` — vlINSURE INSURE balance frozen; no unprivileged exit.
* Independent verification: child subagent re-fetched the deployed-vs-audited source diff (`analysis/source-diff/REPORT.md`) — deployed = `pool-contracts@3327626` with **all 14 C4 highs fixed**, **no extra selectors** (PoolTemplate 56/56, IndexTemplate 42/42, CDS 32/32, Vault 33/33) and a recompile of PoolTemplate matching 20,570/20,613 bytes (only IPFS metadata differs). It independently rejected the two candidate paths (CDS `compensate`, `registerIndex` slot claim) and confirmed INSURE minting is not capturable (minter-only; `emergency_module=0`; no DEX pairs).
* Second independent verification (adversarial): child subagent re-derived the whole conclusion with **14/14 of its own fork tests** and event-level censuses (`analysis/verify/REPORT.md`): exactly 3 templates ever approved (only PoolTemplate open), exactly 29 `MarketCreated`, exactly 1 `VaultSet` (USDC only — no other sweepable vault), all index slots occupied by credit-bearing incumbents, deposit→withdraw round trips always return ≤ deposit, `unlock` is a pure public good, staking side yields $0 profit. It independently reproduced every gate and confirmed **E-U = $0.00 (high)**. Its refinements: staking-side owner is a separate EOA `0x79F5Dc19…` (P); `lockInsure()` bricked (escrow lock expired 2026-03-19); LP-gauge weight 0 (not killed); 4,033 wei of unclaimable premium orphans; and a permissionless griefing primitive (a fake index can inflate `totalCredit` until `BondingPremium.getPremium` panics, bricking `insure` — no value moves).

---

## 7. Side chains (Arbitrum / Optimism / Astar)

Full child audit: `analysis/v2-chains/REPORT.md` + `state.json` (all markets, impls, gates, raw reads).

| Chain | Code gen | Vault | Token | `valueAll` | USD | Markets | E-U | P (owner-held) |
|---|---|---|---|---|---|---|---|---|
| Arbitrum | v2 (solc 0.8.12) | `0x968C9718f420d5D4275C610C5c217598a6ade9f9` | USDC.e | 607,055,148 | $607.06 | 12 (10 MarketTemplate `0x576e74c0…` + 2 IndexTemplate `0xcb146803…`) | **$0.00** | $442.52 fee attribution + `emergencyExit` |
| Optimism | v2 | `0x54F23d2fdC1E17D349B1Eb14d869fa4deD6A6D2b` | USDC | 232,764,196 | $232.76 | 37 (33 `0x4763f972…` + 4 `0x016d4eb1…`) | **$0.00** | $174.88 fee attribution + `emergencyExit` |
| Astar | **v1** (0.8.10 family; `keeper()` present) | `0x190dA1B9fA124BD872e9166bA3c7Dd656A11E8F8` | USDC | 548,239,573 | $548.24 | 15 (12 PoolTemplate `0x00749760…` + 3 IndexTemplate `0x734afd33…`) | **$0.00** | $18.86 owner + $75.70 former-owner legacy claim; `setController` |

* On Arb/OP the value sits in an AaveV3Strategy controller (`managingFund` = full value); `balance()=0`, `totalDebt=0`, share price 1.1754 / 1.1371 USDC per attribution.
* The v2 factories are open (`createPool`/`createMarket` permissionless — proven by eth_call clone creation and 15 historical txs), **but** the reference allowlist pins token/registry/parameters to the real contracts, so fresh clones inherit honest owner gates; no Reserve/CDS instance exists on these chains.
* All value-out gates revert for an unprivileged caller (exact strings: `Caller is not allowed to operate`, `WITHDRAW-VALUE_BADCONDITIONS`, `ERROR_REPAY_DEBT_BADCONDITIONS`, `ERROR_NO_APPLICABLE_INCIDENT`, `Not an Official Pool`, `ERROR: UNAUTHORIZED_CALLER`).
* The `Ownership` owner on all three chains is the single EOA **`0x2c9bC901f39F847C2fe5D2D7AC9c5888A2Ab8Fcf`** (`futureOwner=0`) — a privileged role (P): it can withdraw its own fee attributions via public `withdrawValue`, drain Arb/Op remainders via `controller.emergencyExit`, and re-wire Astar via `setController`. If that key is destroyed the value is locked (S) — either way no third party can take it.
* Astar RPC limitation: the public node cannot execute CREATE inside eth_call, so Astar's permissionless-create was proven via reflist storage + historical create txs rather than simulation (child report F1).

---

## 8. Verdict, residual/latent risk, blockers

* **E-U (fresh unprivileged attacker): $0.00** (high confidence).
* **H-O (holders self-service): $124,270.92** = $122,289.09 of Ethereum vault attributions (LP claims + index premiums) + $1,305.75 staked LP (WETH side) + $676.09 of side-chain market LP claims. The CDS LPs are already withdrawing (2026-04, 2026-09).
* **P (privileged): $715.18** = Ethereum PoolProxy fee dust $3.22 + side-chain owner-EOA fee attributions $636.26 + Astar former-owner legacy claim $75.70. The same privileged actors also hold latent authority over the full balances (Safe → reporting admin/controller; EOA → emergencyExit/setController).
* **S (stuck/bricked):** ≈$0 of value; INSURE (5.41M locked in escrow + 10.75M in InsureDepositor) is unmarketable; `vlINSURE` is explicitly irreversible.
* **Blockers/limits:** the protocol is dead — no premiums flow, no reporting admin, no DEX markets for INSURE/iTokens, so no path to become a claimant at a discount; the only "open" surface (permissionless market creation) leads to inert contracts.
* **Conditional paths:** none that convert to E-U. Acquiring iTokens (from holders) only grants fair-value H-O redemption; the "legacy staker" style precondition does not exist here because no unprivileged claim/replay function remains live. The only preconditions that unlock value are privileged (Safe → reporting admin/controller; side-chain owner EOA → `emergencyExit`/`setController`).
* **What would change the verdict:** (a) Safe signers (or a leaked key) set a reporting admin and forge an incident → up to ~$59.8k (CDS) + pool balances drainable (P); (b) a bug discovered in the v2 templates (child audit found none); (c) a market appearing for iTokens below par.

---

## 9. Methodology, sources, caveats, files

**Method:** corpus leads → Etherscan V2 verified sources → exhaustive reachability review of every deployed template/vault/PoolProxy function → live-state reads at pinned block 26,185,000 and head 26,185,830 → Foundry fork PoC (12 tests) on GitLab CI → independent child verification (source diff + selector/bytecode check; v2/side-chain audit; adversarial re-test of the E-U $0 headline). Three child subagents were used; all wrote only under `analysis/`.

**Sources:** Code4rena 2022-01 InsureDAO report (all 14 highs checked against deployed code); `InsureDAO/pool-contracts@3327626`; Etherscan V2; Blockscout (holders, transfers); DefiLlama prices (WETH $2,506.51 @ 2026-10-13); DexScreener (no INSURE/iToken pairs); the L2 triage row (`l2-triage-a/summary.json`).

**Caveats:** (1) v1 state is static but not frozen — H-O withdrawals can reduce the vault balance over time; numbers are stated at the cited blocks. (2) Privileged-path amounts are "what a compromised/malicious Safe could take", not attacker-reachable today. (3) INSURE valuation is approximate (no market); the LP's realizable value is bounded by its 0.5209 WETH. (4) The v2 chains' audit relies on the child's report plus my reads of the v2 vault/registry; per-pool internal accounting there was verified by the child. (5) GitHub Actions is billing-blocked; all CI evidence is from GitLab (public pipeline link above).

**Files:**
```
insuredao/
├── README.md                  (this file)
├── summary.json               machine-readable result
├── analysis/
│   ├── sources/               verified sources (vault, registry, factory, 3 templates, PoolProxy, InsureDepositor, gauge, INSURE)
│   ├── market-tokens.json     per-market supply/LP claims/premiums/locks
│   ├── full-state.json        per-market status/attributions/parameters
│   ├── markets-map.json       clone implementations + factory template flags
│   ├── pool-index-graph.json  pool↔index graph + credits
│   ├── multichain.json / v2chains.json / multichain2.json
│   ├── itoken-holders.json, classify.py, *.py (read-only RPC scripts, keyless)
│   ├── evidence.md            key citations (address + block + call)
│   ├── source-diff/           child B: diffs vs C4-audited + selector/bytecode checks (REPORT.md)
│   ├── v2-chains/             child A: v2 chains audit (REPORT.md, state.json, sources)
│   └── verify/                child C: adversarial verification of the E-U $0 headline (REPORT.md)
├── poc/                       Foundry PoC (12/12 PASS)
├── ci/                        GitLab CI config (Debian + foundryup)
├── ci-out/gitlab-run1.log     CI test log
├── gitlab-log.txt             raw pipeline trace
└── summary.json
```
