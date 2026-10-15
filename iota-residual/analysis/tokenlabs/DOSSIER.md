# TokenLabs vIOTA (IOTA L1) — adversarial dossier (L2-19)

*Read-only research. No transaction was signed or sent. All state reads are keyless public RPC
(`https://api.mainnet.iota.cafe`, Sui-style JSON-RPC + `iotax_*` extensions, GraphQL indexer
`https://graphql.mainnet.iota.cafe`). Reference checkpoint: `204,090,375` (2026-10-15 ~09:35 UTC); IOTA epoch 528.*

**Bottom line: no unprivileged direct-extraction path found in the live (v2) code. E-U direct = $0 (high
confidence). One conditional, capital-gated value-transfer path exists (reward-credit timing): ~$24.6/day
with capital = 1× TVL, ceiling ≈ $51/day (~$18.6k/yr) with unbounded capital. The dominant residual risk is
privileged (single EOA holds OwnerCap + OperatorCap + UpgradeCap).**

---

## 1. What the protocol is and where the code lives

TokenLabs vIOTA is a Move liquid-staking protocol on IOTA Rebased (MoveVM, Sui-style). Users deposit IOTA,
receive the reward-bearing `vIOTA` (Move type `…::cert::CERT`). The pool restakes into IOTA validators via the
`0x3::iota_system` / `0x3::staking_pool` framework.

| role | id | notes |
|---|---|---|
| v1 package (original) | `0xe4abf8b6183c106282addbfb8483a043e1a60f1fd3dd91fb727fa284306a27fd` | published 2026-02-02; **not the live code** |
| **v2 package (live)** | `0x6ab984dfae09bbef27551765622a85f461e0b46629eee60807b6e5399c0f7f0f` | upgrade 2026-02-21 12:14:44 UTC; MoveCalls resolve here |
| `NativePool` (shared) | `0xb435fa61ee8d5473ab36de02c88756f8c74fcc031b4e3a2fe2a6647bb06b2872` | object version field = 2 |
| `cert::Metadata<CERT>` (shared) | `0xb45b32d8d58c6499795036faa92b0561c6df089cdd4fc6ae8a0543981a698bf1` | holds `total_supply` (= vIOTA supply) |
| vaults `Table<address, Vault>` | `0xeee7c883e7f65ec447d6a1299c667373070f4bfb574ac4610bd5411f1d1659df` | 17 entries, 1 non-empty |
| `OwnerCap` / `OperatorCap` / `UpgradeCap` | `0x78c15e70…c171` / `0x636bda34…d656` / `0xed9b69c2…0f45` | all owned by `0x55556790…b54ae7c` (single EOA) |

Both packages were disassembled from on-chain bytecode with the official `iota` CLI 1.33.1
(`iota move disassemble`). Raw bytecode + disassembly: `bytecode/`, `bytecode_v2/`, `disasm/`, `disasm_v2/`.
The MoveBit audit (2026-01-14) covers **v1 only**; the v2 delta (`validator_cap_base`, `get_validator_priority`)
is unaudited.

## 2. Live state (verified, checkpoint 204,090,375)

| field | value |
|---|---|
| `paused` | false |
| `pending` | 0 |
| `total_staked` | 3,597,964,219,313,557 (3,597,964.219313557 IOTA) — **equals Σ 17 vaults exactly** |
| `total_rewards` | 255,612,938,399,482 (255,612.938399482 IOTA) |
| `collected_rewards` | 0 |
| vIOTA `total_supply` | 3,590,070,089,452,751 (3,590,070.089452751 vIOTA) |
| **ratio** | supply·1e18/total = 0.931620139554524951e18 (shares per IOTA); **1 vIOTA = 1.073398864561 IOTA** |
| solvency guard | supply (3.5901e15) ≤ total (3.8536e15) → `math::ratio` does **not** abort |
| `validator_cap_base` (v2 dyn. field) | 4,000,000,000,000,000 = 4,000,000 IOTA |
| `min_stake` / `base_reward_fee` / `rewards_threshold` | 1 IOTA / 99 (0.99 %) / 100 (1 %) |
| validators | 17 configured, priorities {100: 1, 25: 3, 8: 9, 5: 4}; **all TVL in one vault** (`0xe7f6929a…`, 529 receipts) |
| bad validators (priority 0) | none |

**TVL = 3,597,964.22 IOTA ≈ $162.6k** (IOTA $0.0452, DefiLlama/CoinGecko 2026-10-15). Pooled assets incl.
rewards ≈ 3,853,577 IOTA ≈ $174.2k. (The corpus figure "$222k" was priced at ~$0.0603; IOTA is ~$0.045 now.)

Ratio was independently verified against real event outcomes to 11 decimal places (StakedEvent
`iota_amount/cert_amount`), e.g. 101,252.0 IOTA → 94,328.402370174 vIOTA on 2026-10-15 08:02:53 UTC
(tx `E7LLLSCZrbGQFDviKkpnH2cQWc8BMWdGY85dEiCRPAZS`).

## 3. The complete value-moving surface (v2 ABI, from bytecode)

| entry | gate | who can call |
|---|---|---|
| `stake` / `stake_non_entry` | `version∈{1,2}`, `!paused`, `amount ≥ min_stake`, `shares>0` | anyone |
| `stake_to_validators*` | v2: **delegates to `stake_non_entry`, ignores the validator vector** | anyone |
| `unstake` / `unstake_non_entry` | `version`, `!paused`, `from_shares ≥ 1 IOTA`, burn == amount, assembled IOTA == amount | anyone (own vIOTA) |
| `rebalance` | `version`, `!paused`, **≥1 bad validator**, else abort 103 | anyone |
| `publish_ratio` | none (immutable refs only) — emits `RatioUpdatedEvent`, no state | anyone |
| `add_pending` | `OperatorCap` | operator |
| `update_rewards` | `OperatorCap`, `Clock`, strictly increasing `new_total`, ≥12 h since last, jump ≤ 1 % of staked | operator |
| `update_rewards_revert` | `OwnerCap`, strictly decreasing | owner |
| `change_*`, `set_pause`, `collect_fee_new`, `migrate`, `update_validators` | `OwnerCap`/`OperatorCap` | owner/operator |
| `cert::mint` / `burn_coin` / `burn_balance` | `public(friend)` → only `native_pool`; `Metadata.version==2` | — |

Share math (module `math`, floor division in both directions):
`ratio = supply·1e18/total` (aborts 502 if `supply > total`, i.e. underwater);
`to_shares = amount·ratio/1e18`; `from_shares = shares·1e18/ratio`;
`total = pending + total_staked + (total_rewards − collected_rewards)`.

IOTA framework semantics (source `iotaledger/iota`, `crates/iota-framework/packages/iota-system/sources/staking_pool.move:129-177`):
`request_withdraw_stake` returns **principal immediately** if the stake is not yet active
(`stake_activation_epoch > ctx.epoch()`), else **principal + rewards immediately**; no unbonding, no deferral
(`// TODO: implement withdraw bonding period here.`). TokenLabs therefore pays unstakes in the same tx.

## 4. Attack paths tested (adversarial)

| # | path | verdict |
|---|---|---|
| A1 | Round-trip stake→unstake rounding (`to_shares` floor then `from_shares` floor) | **closed** — both floors favour the pool; `A' ≤ A` always |
| A2 | Ratio inflation by direct IOTA donation | **closed** — `pending` is a `Balance` field inside the shared object; the only increments are `stake` (mints proportional shares), `add_pending` (OperatorCap) and validator withdrawals; no donation path |
| A3 | Ratio manipulation via stake/unstake sizing | **closed** — both legs move `supply` and `total` proportionally; rounding epsilon ≤ 1 nano |
| A4 | First-depositor/inflation attack on an empty pool | **closed** — pool is mature (3.59 M shares); `min_stake` 1 IOTA + `shares>0` check bound dust |
| A5 | Permissionless validator injection (`ensure_validator_exists(v, 50)` via `stake_to_validators`) | **closed in v2** — v2's `stake_to_validators_non_entry` ignores the caller's validator vector and delegates to `stake_non_entry`; `ensure_validator_exists` is unreachable. (This was a real v1 weakness, fixed by the Feb-21 upgrade) |
| A6 | `rebalance` abuse (permissionless state mutation) | **closed** — it can only move the pool's own stake between validators; it cannot pay the caller. **Today it reverts**: `get_bad_validators() == []` → `unstake_amount_from_validators` aborts 103. Never called in the protocol's history (0 txs, v1+v2) |
| A7 | `publish_ratio` (permissionless) | **closed** — immutable refs only; emits an event with the current fair ratio; no state, no oracle write. 0 calls ever |
| A8 | Under-reported rewards exploited by unstaking (`sub_rewards_unsafe` floors `total_rewards` at 0) | **closed** — the deviation `D = accounted − true` moves toward 0, i.e. the unstaker *under*-receives and remaining holders gain slightly; no attacker profit |
| A9 | Over-reported rewards (operator inflates `total_rewards`, then unstakes) | **privileged only (P)** — see §5 |
| A10 | `rebalance`/`unstake` DoS via validator-set state (inactive validator ⇒ `request_add_stake` aborts `EDelegationToInactivePool`, and `stake_pool` has no try/catch) | **latent, not attacker-triggerable** — would brick stake/unstake/rebalance while it persists; today all 17 validators are active and the single priority-100 validator has 402k IOTA of headroom below its 4 M cap |
| A11 | Reward-credit timing (JIT around the daily `update_rewards`) | **OPEN — conditional** (quantified in §5) |
| A12 | `collect_fee_new` / `migrate` / `set_pause` abuse | **privileged only (P)** — capability-gated; verified `OwnerCap`/`OperatorCap` are AddressOwner objects of one EOA |
| A13 | Fee/accounting leak (`collect_fee` extracting holder value) | **closed** — algebraically the holders' accounted claim is unchanged by a fee collection; the fee was carved out of `total_rewards` at credit time |

## 5. The one open path (A11) and the privileged risk (A9) — exact numbers

### A11 — reward-credit timing (E-U, conditional)
* Mechanism: rewards accrue continuously inside validator stakes but are only credited to the share price when
  the operator calls `update_rewards` — observed as a **daily cron at 09:00:0x UTC** (50 consecutive days,
  last `rewards_update_ts` = 2026-10-14 09:00:09 UTC). An attacker who is staked at the credit instant captures
  a full day's accrual regardless of how long they held.
* Attacker profit per credit: `P = X/(T+X) · R · (1 − 0.0099)` where `T ≈ 3.598 M IOTA`, and
  **R ≈ 1,138.6 IOTA/day** (measured: daily `FeeCollectedEvent` mean 11.27 IOTA ÷ 0.0099 fee rate; 50-day series).
* Quantified (IOTA @ $0.0452):
  * X = 1× TVL (3.598 M IOTA ≈ $162.6k): **≈ 544 IOTA/day ≈ $24.6/day ≈ $9.0k/yr (5.5 % APR on capital)** with ~4 min/day exposure;
  * X = 10× TVL (≈ $1.63 M): ≈ 1,026 IOTA/day ≈ $46.4/day ≈ $16.9k/yr (1.0 % APR);
  * X → ∞ (ceiling): ≈ 1,128 IOTA/day ≈ **$51/day ≈ $18.6k/yr** — the entire holder reward stream.
* Preconditions: capital; staking just before 09:00 UTC; the operator's update landing while staked; unstaking after.
  Net of gas (~0.01 IOTA) and negligible floor rounding. This is pro-rata value transfer from incumbent holders
  (yield-timing), **not principal theft** — the attacker earns exactly what an honest staker with the same capital
  earns for a day, but with minutes of exposure.
* Would change the verdict: (a) streaming rewards continuously (per-epoch credit) instead of an instant daily
  credit; (b) a withdrawal fee/queue; (c) crediting only to balances held over the full accrual window.

### A9 — privileged ratio inflation (P, not E-U)
`update_rewards` takes an **operator-supplied** u64 (no access to system state) and accepts an increase of up to
`rewards_threshold` (1 %) of `get_total_staked()` per ≥12 h. The single key `0x5555…b54ae7c` can therefore raise
`total_rewards` by ≤ 35,980 IOTA per call (≈$1.6k), mint/stake, unstake at the inflated ratio and extract real
principal from the vaults, repeatedly (≤2×/day ⇒ ≈$3.2k/day), until the pool is drained. It also holds the
`UpgradeCap` (arbitrary compatible upgrades, no timelock) and can pause. This is a **rug/collateral risk**, not an
unprivileged path; it is the protocol's dominant risk.

## 6. PoC / verification

* **Code-level proof**: full bytecode disassembly of v1 and v2 (`disasm*/`), with the v1→v2 diff (`np_diff.txt`,
  `vs_diff.txt`) showing exactly what the upgrade changed (version constants, `validator_cap_base`, per-validator
  total caps `cap_base·priority/100`, `update_validator` priority ≤ 200, `stake_to_validators` neutered).
* **Chain-native verification** (no tx): live-state reads + `iotax_queryEvents` history + the ratio checked against
  11 real Staked/Unstaked events; vault sum == `total_staked`; `bad_validators == []`.
  Reproduced in CI: `ci-out/live_state.json` (+ `ci/verify_live.py`). See `README.md` for the CI run URL.
* **Unprivileged callability** is proven by production history, not simulation: dozens of unprivileged senders
  (e.g. `0x5534b441…`, `0x2ee7eb39…`, `0x2fc059b4…`) call `stake`/`unstake` successfully every day; the last
  observed unstake paid 3,498.10 IOTA for 3,258.90 vIOTA in the same transaction.
* **Not proven by simulation**: `rebalance` has never executed on mainnet (its behaviour is read from bytecode; a
  dev-inspect would abort 103 today because there are no bad validators), and `publish_ratio` has never been called.

## 7. Classification

| category | value | note |
|---|---|---|
| **E-U direct** | **$0** | no unprivileged path to take principal or mis-price shares (high confidence) |
| E-U conditional | ≈$24.6/day at 1×TVL capital; ceiling ≈$51/day (~$18.6k/yr) | A11 reward-timing; pro-rata transfer from incumbents |
| H-O | TVL 3,597,964 IOTA ≈ $162.6k | holders redeem at fair value instantly, uncapped (own shares only) |
| P | up to ≈1 % of TVL per 12 h (~$1.6k/call) + full upgrade authority | A9 + `UpgradeCap`, all with one EOA |
| S | none | funds are movable; the only stuck-funds scenario would be a deactivated validator blocking `stake_pool` (latent, not present today) |

**Confidence**: high on $0 direct E-U (complete bytecode coverage of both package versions, live state,
50-day event history, and framework source). Medium on the A11 ceiling (depends on the operator keeping the
daily cron and on the attacker's ability to time it; the measured R is robust).

## 8. Files

`bytecode{,_v2}/` `disasm{,_v2}/` (all 5 modules each) · `pkg_abi.txt` (v1), `pkg_abi_v2_active.txt` (v2) ·
`np_diff.txt`, `vs_diff.txt` · `framework_lead/` (staking_pool.move, iota_system.move + quotes) ·
`framework/` (full framework set + README, by the child agent) · `live/` (raw object/tx JSON) ·
`events/` (raw event series) · `movebit_audit_2026-01-14.pdf` + `audit_excerpts.md` · `FINDINGS.md` (child agent's
live-verification report) · `DOSSIER.md` (this file).
