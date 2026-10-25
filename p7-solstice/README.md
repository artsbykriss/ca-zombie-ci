# p7-solstice — Solstice Finance **YieldVault (eUSX)** deep-dive — Solana

**Date:** 2026-10-25 · **Chain:** Solana mainnet · **Mode:** READ-ONLY. No tx signed/sent.
**Status line:** read-only; PoC is `simulateTransaction` (`sigVerify:false`, `replaceRecentBlockhash:true`) on
attacker-built *unsigned* messages; no mainnet transaction was ever signed, sent, or landed.

> ZH4-PASS7 lane lead (`zombie-hunt-iv/pass7/solana-sui.md` row 1 / §Top-3 #1), which
> `pass7/README.md` §5 folds into “Solstice YieldVault → $0 closed”. This subagent was asked to
> **reconcile** that closure and to test the lane’s **explicitly-untested residual**
> (`unlock`→`cooldown_escrow` accumulation, the global `VestingSchedule` arithmetic, first-depositor /
> rounding). Verdict: **the README closure is correct**, and the residual is now closed too — with the
> decisive gates recorded below.

---

## 1. TL;DR

| Target | Live value | External-unprivileged extractable (E-U) | Why closed / open | Latent risk |
|---|---|---|---|---|
| **Solstice YieldVault `eUSXyKoZ…`** (permissionless `lock`/`unlock`/`withdraw`) | **4,578,980.353873 USX ≈ $4,574,692.63** in `ASSET_VAULT` (+ **556,229.813281 USX ≈ $555,708.96** held in per-user `CooldownEscrow` vaults) | **$0** | `total_assets` **stored** (donation-neutral); yield only via harvester `PermissionedAccount` PDA; share math symmetric `(TA − unvested)`; escrow additive, per-user, substitution-rejected; cooldown/vesting/rounding all gated | **P:** Squads 3-of-5 upgrade authority over both programs (latent). **S:** ≤ ~118 USX unvested-yield stranding if the pool fully empties mid-vest (theoretical). |
| USX program `USXyiSTs…` (mint/redeem) | $201.8M TVL (DefiLlama) | **$0** | mint/redeem is **whitelist/permissioned** (`RequestMint`/`ConfirmMint` + `permissioned_account`, `validate_permissions.rs`) | — |

**Total live extractable by an external unprivileged attacker right now: `$0`** (confidence **high**).

**Decisive gate (one line):** every attacker-reachable branch of the YieldVault either moves the
caller’s **own** assets at a symmetric `(total_assets − unvested)` rate, or is rejected by an explicit
Anchor constraint — `ConstraintSeeds` (2006) on the cooldown escrow / harvester PDA, `ZeroShareAmount`
(6017) on dust lock, `CooldownNotEnded` (6013) / `InsufficientFunds` (6015) on premature / repeat
withdraw. There is no path where an unprivileged caller receives assets they did not deposit or yield
they are not entitled to.

---

## 2. The mechanism (exact)

### 2.1 The permissionless surface is *only* the YieldVault
USX mint/redeem is permissioned. Recovered from the **USX program ELF** (`USXyiSTs…`, programdata
`3P5mNf86…`, upgrade auth `BzMuMbtah…`, off-curve): the instruction set includes
`RequestMint`/`ConfirmMint`/`CancelMint`/`RequestRedeem`/`ConfirmRedeem`/`ConfirmRedeemPartial` plus
`PERMISSIONED_ACCOUNT` seeds and `utils/validate_permissions.rs`; error strings
*“Permissions must be provided.”* / *“Account does not have permission to perform the operation.”*
The only permissionless E-U surface is therefore the **YieldVault**.

### 2.2 YieldVault accounting (from IDL + ELF + live state)
Anchor IDL (`yield_vault` v1.1.1, 15 instructions) pulled from
`smartcontractkit/external-adapters-js/…/idl/eusx_yield_vault.json`; ELF source paths recovered:
`programs/yield-vault/src/instructions/{lock,unlock,withdraw,transfer_in_yield,…}.rs`,
`utils/{maths,validate_amount,validate_controller,validate_cooldown,validate_permission,validate_yield}.rs`.

State:
- `YieldPool.total_assets` is **stored** (u128), not read from the vault balance → **donation-neutral**.
  Live: `total_assets == ASSET_VAULT` SPL balance **exactly** (both `4,578,980,353,873` at slot 461,377,202).
- `YieldPool.shares_supply` (u128) = eUSX mint supply (mint authority = the Controller PDA).
- `VestingSchedule` is **global**: a single `{vesting_amount, start_time, end_time}`.
- `CooldownEscrow` stores a **single** `asset_amount` + `cooldown_end` per user, with a **per-user PDA
  vault** (`COOLDOWN_ESCROW_VAULT`), verified: each escrow PDA’s token-account balance **equals** its
  `asset_amount` (checked on the top escrows; e.g. `353,498.439895 == 353,498.439895`).
- `PermissionedAccount` (harvester) has `can_send_yield = 1`; `transfer_in_yield` is the **only** way
  yield enters.

Live Controller params (slot 461,377,202): `vesting_period = 28,500 s`, `cooldown_period = 604,800 s`,
`fast_cooldown_cutoff = 1,000,000,000` (1,000 USX), `fast_cooldown_period = 86,400 s`, `is_frozen = 0`.

---

## 3. Live-state assessment (all read-only, cited)

| Item | Address | Live value @ slot 461,377,202 |
|---|---|---|
| YieldVault program | `eUSXyKoZ6aGejYVbnp3wtWQ1E8zuokLAJPecPxxtgG3` | programdata `BVDochYTcRGvCYmmdtsiX9qT63fy5dmGSB5hNgxMTbJY`; upgrade auth `CYr14TrXD5MAertRqcR58KirPz7XoHGZjfBsfn5M2voh` (**off-curve PDA**); last deploy slot 416,855,566; ELF 613,216 B |
| USX program | `USXyiSTsPEWz55pSK7sZoUL79ntoVGQbaTDT57tH6bx` | programdata `3P5mNf86…`; upgrade auth `BzMuMbtah9bqN4HERkPo2PsVoaQKD2xfvYq1xfDCFwEb` (**off-curve PDA**) |
| Controller PDA | `2aHdm37djj4c21ztMRBmmo4my6RtzN5Nn58Y39rpWbRM` | authority = `CYr14TrX…`; `is_frozen=0`; vesting 28,500 s; cooldown 604,800 s; fast cutoff 1,000 USX / 86,400 s |
| YieldPool PDA | `2rjmJdxZeBLKjUjKjrSdtSqshgXbLEcPbjiJZ2vLNcCT` | `total_assets = 4,578,980,353,873`; `shares_supply = 4,360,184,640,019` |
| ASSET_VAULT PDA | `2SGicAhchh23nsrtWrur7zPAdb4hHtnyThQVPfza8CHA` | **4,578,980.353873 USX** (== `total_assets`) |
| VestingSchedule PDA | `FCA4A8W8qzcXGDyBaQ8fiSqr2VowSihiz2bJKN9LcLwb` | `vesting_amount = 118.761904 USX`, `[1792947789, 1792976289]` (**active** during the whole test window) |
| PermissionedAccount (harvester) | `5KzVcKDyzMFUh32tMESHjfA7vTALfDHbVxq9HbZd8rz` | `can_send_yield = 1` |
| eUSX mint | `3ThdFZQKM6kRyVGLG48kaPg5TRMhYMKY1iCRa9xop1WC` | 6 dp; supply 4,356,975.733709; mint auth = Controller PDA; freeze auth **None** |
| CooldownEscrow set | 13,956 PDAs | 1,029 funded; **556,229.813281 USX** total escrowed (per-user vaults, not the pool) |

USX price: **$0.9990636083** (DefiLlama `coins.llama.fi`, timestamp 1792956173).

**Value buckets:** pool **$4,574,692.63** + escrow **$555,708.96** = **$5,130,401.60** user-owned.
`H-O` (holders self-service: `unlock`→cooldown→`withdraw`, and `withdraw` of already-escrowed funds)
= the whole $5,130,401.60. `E-U = $0`.

---

## 4. What an attacker can / cannot do

**Cannot (all fork-sim-proven, see §5):**
1. **Donate to inflate NAV** — `total_assets` is stored; a direct USX transfer to `ASSET_VAULT` changes
   nothing. (Live equality proves zero historical donation leakage.)
2. **Self-feed yield** — `transfer_in_yield` with the attacker as signer:
   - passing the real harvester PDA → `ConstraintSeeds 2006`;
   - passing the attacker’s derived PDA → `AccountOwnedByWrongProgram 3007`.
3. **Over-credit / double-pay via cooldown escrow** — two `unlock`s **add** (`asset_amount` sums;
   vault balance sums identically); `withdraw` pays exactly `asset_amount`, **zeroes** it, and a second
   `withdraw` in the same tx → `InsufficientFunds 6015`.
4. **Withdraw before cooldown** — `unlock` then immediate `withdraw` → `CooldownNotEnded 6013`.
5. **Downgrade a large escrow to the fast lane** — the fast/standard branch keys off the **resulting
   escrow total**; a 525 USX unlock is fast (86,400 s) but adding 630 USX (total 1,155 > 1,000)
   **upgrades the whole escrow to 604,800 s and resets the timer**. A large single unlock (>1,000)
   from a *fresh* escrow is also standard (604,800 s).
6. **Substitute the cooldown escrow/vault** (victim’s escrow, or victim’s vault) — `ConstraintSeeds 2006`.
7. **Steal unvested yield by lock/unlock** — `lock` and `unlock` use the **same** effective basis
   `(total_assets − unvested)`; a lock→unlock round-trip returns **≤** the deposit (pool-favouring floor).
8. **Dust / first-depositor** — `lock(1)` → `ZeroShareAmount 6017`; the pool is long initialised
   (4.36e12 shares) and `total_assets` is stored, so the ERC-4626 inflation attack is structurally closed.

**Could only if privileged (P, not E-U):** the Squads 3-of-5 (off-curve PDA) upgrade authority over the
YieldVault program could `Upgraded` a malicious program and drain. Not attacker-reachable.

**Griefing-adjacent (informational, not a drain):** any subsequent `unlock` **resets** `cooldown_end`
for the **entire** escrow to `now + period`. A user who unlocks, waits, then unlocks a second tiny
amount has the first amount’s timer extended — user-hostile liveness, no value leaves the caller.

---

## 5. PoC / verification (read-only `simulateTransaction`)

Harness: `analysis/sim.py` (builds unsigned legacy txs: `shortvec(nsig)` + zero sigs + compiled
message; `sigVerify:false`, `replaceRecentBlockhash:true`; reads post-state via the `accounts` config).
Runner: `analysis/probe_unlock.py`, `probe_cooldown.py`, `probe_misc.py`, `probe2.py`;
CI re-run: `ci/collect.py` (`ci-out/solstice_ci.json`, `ci-out/solstice_ci.log`).

| # | Probe | Result |
|---|---|---|
| A | `unlock(1.0 eUSX)` | OK · `asset_amount 1.050159`, rate **1.050159** |
| B | `unlock(1.0)×2` one tx | OK · escrow `3,490,803,154 → 3,492,903,472` (**+2×1,050,159, additive**), `cooldown_end` reset `now+604800` |
| C | `lock(1.0 USX)` | OK · `share_amount 952,235`, rate **1.050161** (same basis as unlock) |
| D | `lock(1.0)` → `unlock(952,235)` one tx | OK · returned **0.999999 USX** (≤ deposit; floor favours pool) |
| E | `unlock` then `withdraw` (active) | `CooldownNotEnded 6013` |
| F | `withdraw`×2 (expired) | 1st pays 3,490.803154 + **zeroes** escrow/vault; 2nd `InsufficientFunds 6015` |
| G | `lock(1 unit)` | `ZeroShareAmount 6017` (`lock.rs:113`) |
| H | `unlock` with **victim’s** escrow/vault | `ConstraintSeeds 2006` |
| I | `transfer_in_yield` as attacker (real PDA / own PDA) | `ConstraintSeeds 2006` / `AccountOwnedByWrongProgram 3007` |
| J | fresh escrow `unlock(525 USX)` | fast cooldown `86,403 s` |
| K | fresh escrow `unlock(2000 eUSX ≈ 2,100 USX)` | **standard** `604,803 s` (no fast-lane for large) |
| L | chunked `unlock(525)` + `unlock(630)` | 1st fast `86,403 s`; 2nd **upgrades to `604,803 s`** + resets timer |
| M | `unlock` with a **foreign** `user_shares` (wrong owner) | `InvalidOwner 6007` |
| N | `unlock` with a bogus `share_mint` | `InvalidShareMint 6012` |
| O | `withdraw` with a foreign/wrong-mint `user_assets` | `InvalidAssetMint 6011` |
| P | `lock` with a bogus `asset_vault` | `ConstraintSeeds 2006` |

**Numeric basis check:** at blocktime 1792955840, `U = 118,761,904 × (1792976289 − now)/28,500 = 85,196,039`;
`(total_assets − U)/shares_supply = (4,579,973,450,271 − 85,196,039)/4,361,130,300,628 = 1.0501599` —
exactly the `unlock` rate and the `lock` rate → **both use the same `(TA − unvested)` basis**.

**CI:** all of A–I re-run on GitHub Actions — see `ci-out/solstice_ci.json` and the run URL in §8.

---

## 6. Verdict & residual / latent risk

- **E-U = $0 (high confidence).** The cooldown-escrow and vesting-arithmetic residuals left untested by
  the lane are **closed**, with decisive gates: additive per-user escrow, exact-balance payout with
  zeroing, `ConstraintSeeds` on all caller-supplied escrow/PDA accounts, symmetric `(TA − unvested)`
  share math, and the `ZeroShareAmount` guard.
- **H-O = $5,130,401.60** — entirely user-owned; holders self-service `unlock`→cooldown→`withdraw`.
- **P = latent** — Squads 3-of-5 upgrade authority over both programs (off-curve PDAs). Not exercised.
- **S = $0 now** — no stranded donations (`total_assets == vault balance`). *Theoretical:* if **all**
  shares exit during a vesting window, the unvested remainder (`≤ vesting_amount ≈ 118 USX`) is left in
  `ASSET_VAULT` with `shares_supply → 0` and is unclaimable until a re-lock (and `(TA−U)` could hit 0).
  Bounded by ~$118, requires a 100 % exit — not material.

**Blockers to any attack:** none needed — the paths are simply gated by design. **What would change the
verdict:** (a) a new instruction / program upgrade (monitor `CYr14TrX…`), (b) a `transfer_in_yield`
permission grant to a non-harvester party (`EditPermissionedAccount`), (c) `is_frozen` toggling.

---

## 7. Methodology & sources

- IDL: `smartcontractkit/external-adapters-js` → `eusx_yield_vault.json` (v1.1.1, 15 ixs).
- ELF/source-map recovery: YieldVault `BVDochYTc…`, USX `3P5mNf86…` (`strings`; source paths + error
  catalogue + seed constants `CONTROLLER/VESTING_SCHEDULE/YIELD_POOL/ASSET_VAULT/COOLDOWN_ESCROW/
  COOLDOWN_ESCROW_VAULT/PERMISSIONED_ACCOUNT/SHARE_MINT/REDEEMABLE`). ELF sha256 (zero-trimmed) recorded
  in `analysis/README-evidence.md`.
- Live state: `getProgramAccounts` (13,956 escrows), `getAccountInfo`, `getTokenAccountsByOwner`,
  `getBlockTime`; all at slot 461,377,202 / blocktime 1792956767 (point-in-time).
- Gating: `simulateTransaction` (unsigned, `sigVerify:false`, `replaceRecentBlockhash:true`), 12+ probes.
- Independent corroboration: `Hudgins333/solana-audit-verification/writeups/solstice-usx.md`
  (Halborn Mar-2026; YieldVault audited Dec-2025, two Informational findings solved; **economic attack
  vectors explicitly out of scope**) — consistent with our findings.
- Caveats: BPF not fully decompiled (semantics proven behaviourally via simulation, not by reading Rust);
  point-in-time balances; the USX mint/redeem permissioning is cited from the USX ELF strings + docs.
  Nothing here is an instruction to transact.

---

## 8. Files index

```
p7-solstice/
├── README.md                     # this file
├── summary.json                  # machine-readable summary
├── analysis/
│   ├── sim.py                    # simulateTransaction harness (unsigned txs)
│   ├── decode_state.py           # state/event decoders
│   ├── probe_unlock.py probe_cooldown.py probe_misc.py probe2.py   # probe runners
│   ├── decoded_state.json escrow_summary.json holder_lookup.json eusx_holders.json small_holders.json
│   ├── eusx_yield_vault.json     # Anchor IDL
│   ├── audit-verification.md     # independent audit-verification writeup
│   └── README-evidence.md        # ELF hashes, seeds, error catalogue
├── ci/collect.py ci/run.sh       # CI re-run of probes
├── ci-out/solstice_ci.json ci-out/solstice_ci.log
└── poc/README.md                 # non-EVM note
```

**CI URL:** see `summary.json.poc.ci_run_urls` and `ci-log.txt`.
