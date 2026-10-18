# ZH4-02 — Startale Earn (Soneium): live 3-hourly JIT yield capture

**Date:** 2026-10-18 · **Chain:** Soneium (1868) · **Latest live read:** block **29,573,641** (2026-10-18T00:07:13Z) · **PoC forks:** 29,573,086 and 29,568,020
**Status:** read-only; **fork-verified only**; no mainnet transactions, no keys used. All values are 6-decimal USDSC at $0.99913 (DefiLlama, 2026-10-17 23:49 UTC).

---

## TL;DR

| Question | Answer |
|---|---|
| **What is the bug?** | The RewardRedistributor snapshots the EarnVault's `totalPrincipal()` nominally at **HH:00:05** and distributes at **HH:00:09** every 3 h. The split is sized from that snapshot, but `EarnVault.onYield()` credits the **live** `totalPrincipal()`. A deposit made in the block before the snapshot is counted in the split numerator, then earns the whole epoch's vault allocation pro-rata — while the depositor holds for only ~4–40 seconds (nominal 4–6 s). |
| **Live extractable now (E-U)** | **$92.12/day per $1M of JIT capital** ($33,624/yr) — measured on two real consecutive epochs. At the **$3.5M** PoC size: **$322.43/day** ($117,686/yr). At the full attackable USDSC float (**$3,618,233**): **≈$333/day** ($121.7k/yr). |
| **Why is it live?** | No deposit lock, withdrawal delay, fee, minimum, cap, whitelist or deposit-age check. Deposit and withdraw are permissionless and instant. The only “defence” is the snapshot used for the split, which the vault's own accrual ignores. Owner can only pause/blacklist **after** the fact. |
| **Victim** | **Startale treasury's “remainder” bucket**, not honest depositors. Fork-proven: honest depositors' epoch yield is unchanged ($6.503125 vs $6.503126 control; $13.026195 vs $13.0262); Startale's `toStartaleExtra` drops by exactly the attacker's capture. |
| **Capital needed** | $1M is readily available (Uniswap v4 PoolManager alone holds **$2.253M** USDSC; additional $500k Safe, $219k/$162k EOAs). Full $3.62M requires OTC/multiple holders. No USDSC lending market found. |
| **Flashloan atomicity** | **NO.** `snapshotVaultTVLs()` and `distribute()` are `onlyRole(OPERATOR_ROLE)` (sole member = keeper EOA); `onYield` is RR-only. A real **$2M** v4 flash loan is available ($2.253M depth, zero protocol fee, fork-proven) but the atomic cycle **reverts at the keeper gate** (`AccessControlUnauthorizedAccount`), and the keeper's snapshot→distribute gap is 2 blocks / 4 s. The 2-block position must be funded with own/collateralized USDSC. See `FLASHLOAN.md`. |
| **Economic caveat** | The gross return on dedicated capital is only **≈3.3%/yr** (3.2–3.4% across windows; the protocol's own base rate). It is pure incremental income for an entity that already holds USDSC; a fresh attacker must amortise a few hundred to ~$1k round-trip acquisition cost (~1–11 days of epochs) and needs a borrow cost below 3.3%/yr. |
| **Competitor bots** | **None.** 120,000 blocks (22 epochs, 63 h) scanned: **0** deposits in the pre-snapshot 10-block window and **0** in the snapshot→distribute window. 75 same-user deposit→withdraw roundtrips within 30 blocks exist (dominated by a $1 cycler) but **none** fall in the epoch window. Lifetime census (v10, 1,312 epochs): 16 incidental $10–21 window deposits, no economic JIT. |
| **Confidence** | **High** on mechanics, rates, live state and PoC. **Medium** on the full-$3.62M float-bound realisation (capital acquisition/slippage). |

**Verdict:** a real, permissionless, repeatable **income-class E-U leak** of protocol revenue, ~$92/day per $1M and up to ~$333/day at the entire USDSC float, with no on-chain blocker today. It is not a principal drain; it is a predictable 8×/day skim of Startale's redistribution remainder.

---

## 1. Target map and live state

| Item | Value (block 29,573,641 unless noted) |
|---|---|
| EarnVault proxy | [`0xFdeB7e9F59cad080D9158ff850Ce79bCf6cdd5f0`](https://soneium.blockscout.com/address/0xFdeB7e9F59cad080D9158ff850Ce79bCf6cdd5f0) |
| EarnVault impl | `0x7dCA02767dfD57888CE087900f9cfDf3D9a2af6f` — EIP-1967 slot verified; runtime codehash **0x49971fba…41fa83**, identical to the saved verified-source bytecode; `getVersion() = "EarnVaultV1"` |
| RewardRedistributor | [`0xda798684ffD5eb509c2Ab7b8352EC55B31F18201`](https://soneium.blockscout.com/address/0xda798684ffD5eb509c2Ab7b8352EC55B31F18201) — codehash **0x2b96e242…6ea18**, identical to saved verified source; not a proxy |
| USDSC | `0x3f99231dD03a9F0E7e3421c92B7b90fbe012985a` (M0 `UsdscToken`, impl `0x38E4713a…`); `totalSupply = $4,480,591.955252` |
| Owner / pauser (both contracts) | SafeL2 multisig `0x3C27038D9906caa5D68355B1800625EAcaCd93dA` |
| RR treasury | `0x5e41066D55ED832f9E3d9e747DaF352Cf29391Ef` |
| Keeper / sole `OPERATOR_ROLE` | `0x86bE13a26d548FA5407Ee3E5a8321B4E1019333C` |
| Vault `totalPrincipal` | **$848,044.621512** |
| Vault `claimReserve` | $850,841.582979 |
| Vault USDSC balance | **$852,359.908674** |
| Fee / max snapshot age | `fee_on_yield_bps = 30`; `snapshotMaxAge = 300 s` |
| Paused? | vault **false**, redistributor **false** |
| Last snapshot | block **29,573,427** at **2026-10-18T00:00:05Z** (`lastEarnTVL = $848,044.621512`) |
| Last distribution | block **29,573,429** at **00:00:09Z** — minted **$34.462**, `toEarn` **$6.5031**, `toStartaleExtra` **$27.7765** |
| sUSDSC (secondary, ON) | `0x938bca6c4281313Baa82154745E4d020E85E7340`, totalAssets **$10,301.35** (same class, ~$0.12/epoch — negligible) |
| Attackable float | **$3,618,232.93** = supply − vault − sUSDSC − RR |
| Largest USDSC holders | UniV4 PoolManager $2,252,985.60; EarnVault $852,353.41; Safe $500,339.67; EOA $219,656.85; EOA $162,476.01; UniV3 pool $134,884.61; Startale treasury Safe $65,545.35 |

### Epoch schedule and fresh census (12 epochs, 2026-10-16 15:00 → 2026-10-18 00:00 UTC)

Nominal schedule is snapshot **HH:00:05**, distribution **HH:00:09**. In the 22 fresh epochs, 16 snapshots were exactly at :05 and 16 distributions exactly at :09; all snapshots fell in **:05–:19** and all distributions in **:09–:27** (≤22 s jitter). The distribute block was **2 blocks / 4 s** after the snapshot in 21/22 epochs (one 5-block / 10 s outlier). Minted yield alternates between a **small** (~$33–35) and a **large** (~$67–69) epoch — an observed pattern consistent with the M0 index being pushed in multi-epoch chunks (we do not need to model the cause: the attacker reads `previewSplitCurrent()` immediately before depositing):

| Epoch (UTC) | Minted | `toEarn` | `toStartaleExtra` |
|---|---|---|---|
| 10-17 15:00 | $67.0451 | $12.7001 | $53.9902 |
| 10-17 18:00 | $34.9138 | $6.6016 | $28.1275 |
| 10-17 21:00 | $69.0368 | $13.0262 | $55.6452 |
| 10-18 00:00 | $34.4620 | $6.5031 | $27.7765 |
| **12-epoch mean** | **$51.1882** | **$9.6838** | **$41.2335** |

`toOn` averages only **$0.117/epoch** (sUSDSC). The protocol's base rate is `net/S_base = 51.1882 × 0.997 / 4,480,300 ≈ 1.139×10⁻⁵ per epoch` → **≈3.33%/yr**.

The CI re-read at 00:21Z (11 epochs, same window) gives a mean of **$49.556 minted/epoch → $88.22/day per $1M**; the local 12-epoch mean gives $51.188 → $91.12/day. The fork pair ($92.12/day) sits at the top of this narrow range; we use it for the headline because both halves were executed end-to-end.

---

## 2. The mechanism, exactly

Deployed, verified code (no upgrade since deployment):

1. **Keeper snapshot** — `RewardRedistributor.snapshotVaultTVLs()` (`onlyRole(OPERATOR_ROLE)`, `whenNotPaused`) stores `lastEarnTVL = earnVault.totalPrincipal()` and `lastSusdscTVL = susdscVault.totalAssets()` nominally at **HH:00:05**.
2. **Keeper distribution** — `distribute()` nominally at **HH:00:09** calls `USDSC.claimYield()` (mints fresh USDSC to the RR), takes a 30 bp fee, then splits `net` with `S_base = totalSupply − minted`:
   - `toEarn = net × T_earn_snapshot / S_base` ← the **only** use of the snapshot;
   - `toOn = net × T_yield_snapshot / S_base`;
   - the remainder `toStartaleExtra` goes to Startale's treasury.
   It transfers `toEarn` to the vault and calls `earnVault.onYield(toEarn)`.
3. **Vault accrual** — `EarnVaultUpgradeable.onYield()` (deployed impl, L304–334) has **no snapshot of its own**:
   `globalIndex += toEarn × RAY / totalPrincipal_LIVE` (L329).
   A deposit made after the snapshot but before `onYield` is credited at the moment of accrual; a deposit made **before** the snapshot also inflates `T_earn` 1:1.

**Play P (dominant):**

1. Attacker deposits `X` one block before the keeper's snapshot (or earlier; there is no age check).
2. Snapshot records `T_earn = H + X`; the ordinary split would have used `H`.
3. At distribution, `toEarn = net × (H+X)/S_base`. The attacker's pro-rata share is `X/(H+X)`, so the attacker receives
   **`capture = net × X / S_base`** and honest depositors still receive `net × H / S_base`; `toStartaleExtra` shrinks by exactly the attacker's capture.
4. Immediately withdraw after the distribution block: `withdraw()` auto-settles and auto-claims all accrued USDSC. No lock, fee or delay.

The alternate “Play W” (deposit after the snapshot, before distribution) dilutes honest depositors and is strictly dominated for a rational attacker (v10: 3.35× worse per dollar at $2M); it is not used here.

### Why it is not closed

- `deposit()` (`_deposit`, L621–637): `safeTransferFrom`, increment principal and `claimReserve`; **no minimum, cap, timestamp, cooldown or whitelist**.
- `withdraw()` (L255–289): permissionless, instant, auto-claims.
- No share/rounding exploit is needed; principal is 1:1.
- The Quantstamp **STA-1** finding (Nov 2025) explicitly recommended a 1-hour withdrawal cooldown / minimum hold; it was **not implemented**. PR **#72** (2026-04-23) acknowledged: *“EarnVault has no snapshot protection at all … This is a residue of STA-1.”* The shipped “phase 1” snapshot protects only the **split**, not the vault's accrual. No phase 2 shipped; EarnVaultV2 (PR #74, not deployed here) only auto-compounds.

---

## 3. Fork PoC — end-to-end, against live state

Foundry 1.8.5, `via_ir`, Soneium mainnet fork via the public keyless RPC. All transactions are on the fork; no mainnet state is touched. Tests: `poc/test/StartaleJIT.t.sol`; run `cd poc && forge test -vv --fork-url https://rpc.soneium.org`.

**CI runs:** [run 39082442261](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39082442261) (7/7 PASS; 60k-block census; `live_state.json` @ block 29,574,064, 11 epochs, `ci-out/`) and [final re-run 39083339713](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39083339713) (7/7 PASS; monitor included; block 29,574,500, 6-epoch mean **$51.143 minted/epoch → $91.04/day per $1M**, monitor status OK, 0 window deposits; `ci-out/final_run/`). Both show the same parameters: `totalPrincipal $848,032.58–$848,032.62`, `pending $33.270037`, `float $3,618,245`, fee 30 bp, not paused. One intermediate re-run hit a transient public-RPC HTTP 429 in the optional census; the scripts now back off 60 s on 429 and the final run passed.

**7/7 PASS.** The PoC executes the real keeper sequence — attacker `deposit(X)` one block before the snapshot, keeper `snapshotVaultTVLs()`, keeper `distribute()` two blocks later, attacker `withdraw(X)` in the next block — against the **real deployed contracts** and the **real pending M0 yield** at each fork block.

### Epoch A — the actual next epoch at the time of the run (small half)

Fork block **29,573,086** (2026-10-17T23:48:43Z), pending `claimYield = $34.461987`.

| Scenario | `toEarn` | Attacker capture | Honest share of `toEarn` | Startale `extra` |
|---|---|---|---|---|
| P0 control (X=0) | $6.503126 | — | $6.503126 | $27.7765 |
| **P1: X=$1,000,000** | $14.171502 | **$7.668376** | $6.503125 | $20.108106 |
| **P2: X=$3,500,000** | $33.342443 | **$26.839317** | $6.5031 | $0.937165 |

`toEarn` is the **total** vault allocation; attacker capture + honest share = `toEarn`. `toStartaleExtra` is the separate remainder bucket that absorbs the loss. The attack does not change the honest share (control $6.503126 vs attack $6.503125); the attacker's $7.668376 comes entirely out of Startale's extra ($27.7765 → $20.108106).

Gas: deposit **152,574**, withdraw **144,559** (297,133 total). At Soneium's live effective gas price 2.3e6 wei (0.0023 gwei) plus a measured L1 data fee of 4.12e9 wei/tx, the two-tx epoch costs **≈$0.0017**; 8 epochs/day ≈ **$0.013/day** (≈$4.8/yr). Gas is economically irrelevant (a 10⁴× smaller number than the capture).

**Real-chain validation:** the epoch our fork simulated actually executed on mainnet 11 minutes later at block **29,573,429** (00:00:09Z) — minted **$34.462**, `toEarn` **$6.5031**, `toStartaleExtra` **$27.7765** — matching the fork's `pending = $34.461987` / `toEarn = $6.503126` to the cent. This is not a hypothetical replay.

### 3b. Flashloan atomicity (follow-up) — **NO**

The complete single-tx cycle flashloan → `deposit` → `snapshotVaultTVLs` → `distribute` → `withdraw` → repay **cannot be executed by an unprivileged attacker**. Both keeper calls are `onlyRole(OPERATOR_ROLE)`; the sole member is the keeper EOA `0x86bE…333C`; `EarnVault.onYield` is `onlyYieldRedistributor` (the RR). A fork PoC with a **real $1M v4 flash loan** reverts at `snapshotVaultTVLs()` with `AccessControlUnauthorizedAccount(attacker, OPERATOR_ROLE)` and the entire transaction (loan + deposit) rolls back. Even the keeper cannot snapshot+distribute in one block: `MustSnapshotInPreviousBlocks` forces the snapshot into a prior block, and the live gap is 2 blocks / 4 s (21/22 epochs). Loan liquidity is **not** the constraint: Uniswap v4's PoolManager holds **$2,252,926.68** USDSC and successfully lent **$1M and $2M** in single-tx fork tests at zero protocol fee (87,965 gas round trip). Uniswap v3 adds only ~$135k + ~$125k USDSC; Aave v3 Soneium has no USDSC reserve; Morpho Soneium has no USDSC market. There is no trustless multi-block flash loan; a substituted collateralized loan needs upfront collateral. Full details: **`FLASHLOAN.md`**; tests: `poc/test/StartaleFlashloan.t.sol` (7/7 PASS; total suite 14/14).

### Epoch B — the preceding large half

Fork block **29,568,020** (just before the 21:00:05 snapshot), pending `claimYield = $69.036772`.

| Scenario | `toEarn` | Attacker capture | Honest share of `toEarn` | Startale `extra` |
|---|---|---|---|---|
| Real epoch (no attacker) | $13.0262 | — | $13.0262 | $55.6452 |
| **P1L: X=$1,000,000** | $28.388284 | **$15.362088** | $13.026195 | $40.283130 |
| **P2L: X=$3,500,000** | $66.793506 | **$53.767310** | $13.0262 | $1.877908 |

### Daily run-rate (4 small + 4 large epochs, measured on the two real forks)

| Capital | Capture / epoch | **Capture / day** | Annualised | Gross return |
|---|---|---|---|---|
| **$1,000,000** | $7.668376 / $15.362088 | **$92.121856** | **$33,624** | 3.36%/yr |
| **$3,500,000** | $26.839317 / $53.767310 | **$322.426504** | **$117,686** | 3.36%/yr |
| $3,618,233 (full float) | $27.75 / $55.58 | **≈$333.3** | **≈$121.7k** | 3.36%/yr |

`P3` additionally proves a same-block deposit→withdraw returns the principal **exactly 1:1** (no fee, no lock). `P4` runs all four measured scenarios in one test and emits `RESULT_DAILY_1M` / `RESULT_DAILY_3_5M`.

**Capital/slippage note.** The PoC forges the attacker's USDSC balance (equivalent to acquiring it at par; `totalSupply` is deliberately left unchanged, exactly as a secondary-market purchase would). A fresh attacker buying $1M of a $1 stablecoin on Soneium's stable pools pays roughly a few hundred to ~$1k round-trip (1–10 bps); at $92/day the break-even is ~1–11 days of repeated epochs. The natural attackers are existing USDSC holders (the PoolManager LPs, the $500k Safe, the $219k/$162k EOAs), for whom the acquisition cost is zero and the capture is incremental. The full $3.62M requires OTC/multiple holders and is an upper bound; no USDSC lending market was found, and the snapshot→distribute gap spans blocks, so a single-transaction flash loan cannot fund the position.

---

## 4. What an attacker can and cannot do

**Can:**
- Deposit any amount at any time (no cap/minimum/whitelist); withdraw principal + accrued instantly.
- Time the deposit to the publicly predictable **HH:00:0x** snapshot and exit in the next block after the distribution, 8×/day; ~4–40 s exposure per epoch (nominal 4–6 s).
- Target only the large ($69) epochs by reading `previewSplitCurrent()` before depositing; targeting all 8 epochs maximises dollars, targeting only large epochs minimises exposure.
- Rotate fresh addresses; use `depositWithPermit` to avoid a separate approval transaction.
- Capture from Startale's remainder without touching honest depositors (fork-proven).

**Cannot:**
- Drain principal or the `claimReserve` (1:1 reserved; `withdraw` ≤ principal).
- Force `claimYield()` off-schedule (RR-only `YIELD_CLAIMER_ROLE`).
- Use a single-transaction flash loan: v4 can lend $2.25M, but `snapshotVaultTVLs()`/`distribute()` are `OPERATOR_ROLE`-gated (fork revert) and the position must survive the 2-block keeper gap; no trustless multi-block flash loan exists.
- Beat a pre-emptive pause/blacklist if the Safe acts first — but that is post-hoc, does not stop `onYield` accrual, and a fresh address bypasses blacklisting.

**On-chain blockers found: none.** The only frictions are economic: the gross return on dedicated capital is only ~3.3%/yr (3.2–3.4% across windows; borrowing above that loses money), round-trip slippage to acquire USDSC, and reliance on the keeper schedule.

---

## 5. Classification, confidence and monitors

**Classification: E-U (external, unprivileged), income-class.** No roles, whitelist, insider access or governance needed. Repeatable 8×/day indefinitely while the code and schedule persist. The vault has been live since Nov 2025; the current RewardRedistributor schedule has run since **2026-04-30** (~5.6 months, 1,323 epochs), and the deployed codehash is unchanged since deployment.

**Confidence:**
- **High** on the mechanism (verified deployed source + bytecode hash match + two real fork epochs + the real 00:00:09 epoch matching the simulation).
- **High** on the live rate ($51.19 mean minted/epoch over 12 fresh epochs; $91–92/day per $1M).
- **Medium** on the $333/day full-float figure (depends on sourcing $3.62M at par without moving the peg/DEX price).

**Monitors (cheap, should be alerting):**
1. **Code/upgrade:** EIP-1967 impl slot of the EarnVault ≠ `0x7dCA02767dfD57888CE087900f9cfDf3D9a2af6f`, or a new `getVersion()` / EarnVaultV3; any change to `onYield` that credits snapshot principal or adds a deposit-age gate.
2. **Parameters:** `fee_on_yield_bps ≠ 30`, `snapshotMaxAge ≠ 300`, `owner/pauser` change, `paused = true`, new `setBlacklisted` events.
3. **Schedule:** `lastSnapshotBlockNumber` older than ~3 h + a few blocks, or a missing `Distributed` event per 3 h (keeper down).
4. **Competitor JIT:** any deposit in `[snapshotBlock−5, snapshotBlock)` or `(snapshotBlock, distributeBlock]` above ~$100k; our 60k/120k-block censuses found **0**. A sharp rise in `toEarn` with a matching fall in `toStartaleExtra` is the on-chain signature.
5. **Capital build-up:** large USDSC accumulation by a fresh address (top-holder changes), especially if paired with repeated deposits within the window.

A ready-to-run implementation is **`analysis/monitor.py`** (read-only; exits 1 if any alert fires). Sample run 2026-10-18T00:25Z over the last 12,000 blocks: impl `0x7dca…`, not paused, fee 30, maxAge 300, owner/pauser unchanged, 3 snapshots / 3 distributions, 7 deposits, **0 window deposits → status OK** (`ci-out/monitor.json`).

**What would close it:** any of — a withdrawal cooldown / minimum hold; counting only principal that is ≥1 epoch old; snapshotting principal inside `onYield`; a deposit cap tied to the epoch; or a vault redeploy with snapshot-based accrual (EarnVaultV3).

---

## 6. Methodology, sources, caveats

- **Deployed source:** Soneium Blockscout verified contracts for the EarnVault impl (`0x7dCA…`, 22 files), RewardRedistributor (`0xda79…`, 28 files) and USDSC/M0 (`0x3f99…` → impl `0x38E4713a…`). Runtime codehashes recomputed and matched to the saved compiler output: vault `0x49971fba…`, RR `0x2b96e242…`.
- **Live state:** `eth_call`/`eth_getLogs` over the keyless public Soneium RPC at explicit blocks (29,573,641 latest; 29,573,086 and 29,568,020 fork pins). No keyed RPC URLs are stored in this folder.
- **Epoch history:** 22 fresh epochs in the 120k-block scan (2026-10-15 09:00 → 2026-10-17 21:00, 63 h), 12 of them in the compact `live_state.json` dump, via `eth_getLogs`; the lifetime history (1,323 epochs, ΣtoEarn $17,220, 1,312 vault windows, 16 incidental window deposits, 120 same-user roundtrips) is carried from the v10 wave-2 decode, which used the same deployed code (codehash unchanged).
- **PoC:** Foundry fork tests against the live contracts at two real epoch boundaries; 7/7 pass; no mainnet transactions.
- **Prices:** DefiLlama `coins.llama.fi` — USDSC $0.999128, ETH $2,395.83 at 2026-10-17 23:49 UTC.
- **Sources:** Quantstamp STA-1 (Nov 2025) and StartaleGroup/stablecoin-vault-contracts PRs #55/#56 (snapshot fix) and #72 (residue acknowledged); ZH4 wave-2 `v10-startale.md`.

**Caveats:**
- The PoC forges the attacker's USDSC balance (capital assumed acquired at par and returned on withdrawal); it does not model DEX slippage or borrow cost. The extraction is real as protocol-revenue loss, but a fresh attacker's *net* edge is reduced by acquisition cost and a ~3.3%/yr opportunity cost.
- The M0 yield is claimed in alternating $34/$69 chunks; the exact daily rate tracks M0's index-update cadence and can change with the M yield rate/TVL.
- Full-float ($3.62M) capture is an extrapolation from the $3.5M PoC, not a fork trade through DEX liquidity.
- The sUSDSC vault ($10.3k, $0.12/epoch) has the same class of exposure but is economically negligible and is not added to the headline.

## 7. Files

```
startale-earn/
├── README.md                     # this report
├── FLASHLOAN.md                  # follow-up: keeper gating / atomicity / loan sources
├── summary.json                  # machine-readable headline
├── analysis/
│   ├── scan_epochs.py            # recent-epoch + JIT-deposit census (RPC, 1000-block chunks)
│   ├── monitor.py                # closing-condition / competitor-bot monitor (exit 1 on alert)
│   ├── live_state.py             # live state + 12-epoch JSON dump
│   ├── live_state.json           # latest state @ 29,573,641 (00:07:13Z)
│   ├── recent_epochs.json        # 22 epochs / 122 deposits / 465 withdrawals, 63 h
│   ├── flashloan_evidence.txt    # role-gate calls, depths, current recheck
│   ├── flashloan_poc_local.log   # flashloan suite 7/7 PASS
│   ├── poc_full_local.log        # local 7/7 PASS log (main suite)
│   └── __pycache__/              # (harmless)
├── poc/
│   ├── foundry.toml              # via_ir, solc 0.8.24
│   ├── src/IStartale.sol         # minimal live-contract interfaces
│   ├── test/StartaleJIT.t.sol    # Play-P PoC, 7 tests
│   ├── test/StartaleFlashloan.t.sol # keeper gates + v4 $1M/$2M flashloan + atomic revert, 7 tests
│   └── lib/forge-std/            # vendored
├── ci/run.sh                     # live state + census + monitor + forge tests -> ci-out/
├── ci-out/                       # CI artifacts, run 39082442261 (60k census)
│   └── final_run/                # CI artifacts, final run 39083339713 (30k + monitor)
└── ci-log.txt                    # helper-downloaded log (final run)
```
