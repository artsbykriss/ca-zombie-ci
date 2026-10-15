# C2-41 · Phase Stake (Solana) — zombie-hunt II deep-dive

**Date:** 2026-10-15 · **Chain:** Solana mainnet · **Status:** read-only; chain-native simulation only (no mainnet transactions; `simulateTransaction`, `sigVerify=false`); no secrets.

**Product:** Phase's liquid staking token **YIELD** — an SPL stake pool on **Sanctum's multi-validator SPL stake pool program** `SPMBzsVUuoHA4Jm6KunbsotaahvVikZs1JyTW6iJvbn` (branch `sanctum-spl-multi-pool-deploy` of `igneous-labs/sanctum-spl-stake-pool`).
**Pool account:** `phasejkG1akKgqkLvfWzWY17evnH6mSWznnUspmpyeG` · **YIELD mint:** `phaseZSfPxTDBpiVb96H4XFSD8xHeHxZre5HerehBJG`.

## TL;DR

| Target | Live extractable (fresh unprivileged attacker) | Why closed/open | Latent risk |
|---|---|---|---|
| Phase Stake pool (30,002.23 SOL ≈ $3,050,730) | **$0** | Deployed program is byte-identical to upstream SPL stake-pool v1.0.0 (unpatched); with the validator list `Active`, every value path is fair-NAV, authority-gated, or blocked by PDA/freshness checks (8 chain-native simulations) | Privileged: off-curve manager PDA + multisig-style upgrade authority; **single-key staker** (validator ops only, no direct theft); single-key `sol_withdraw_authority` (UX gate over the ~86 SOL reserve) |
| Phase Stake — **F-1 conditional (validator removal window)** | up to ≈ **$2.80M** for 1,000 SOL capital (≈$316k for 10 SOL) | Deployed program = unpatched v1.0.0: `UpdateValidatorListBalance` zeroes a deactivating validator's recorded lamports → deposits mint at a collapsed price. **Precondition: a staker `RemoveValidatorFromPool`** (privileged; historically recurring) | HIGH tripwire — live the moment a validator is rotated; fix = program upgrade (Sanctum) |

**Total live extractable now (E-U): $0** — confidence **high**. **But there is a conditional tripwire (F-1)**: the deployed program is unpatched SPL stake-pool v1.0.0, and the day the staker removes/rotates the pool's validator, a **fresh unprivileged attacker** can collapse the recorded NAV and deposit at a false price — quantified up to ≈ **$2.80M** for a 1,000 SOL deposit (≈ $316k for just 10 SOL). Not reachable today (validator list has one `Active` record). See §3a.
**H-O (holder-only recoverable): 30,002.23 SOL ≈ $3,050,730** (all YIELD holders can redeem at NAV via `WithdrawStake` + deactivate/withdraw cooldown; instant SOL exit is Phase-gated; net of the 0.1% withdrawal fee ≈ 29,972 SOL ≈ $3,047,678). Holder distribution (`analysis/onchain-state.md`): 4,261 token accounts; top1 41.28% (marginfi v2 vault), top5 97.29%; ≈47.6% sits in Loopscale accounts and ≈41.3% in marginfi — i.e. the economic holders are those protocols' depositors. The manager fee account holds 2.01457808 YIELD ≈ $244.63.
**P (privileged):** no value is *exclusively* privileged, but the pool is exposed to key compromise. Verified control (`analysis/onchain-state.md`): the manager `7LqSTwcw…` is **Squads v4 vault[0] of multisig `GRe1iCBE…` (3-of-N, 24 h timelock, created 2026-10-12)** — a `SetManager` Squads tx that day moved 4 Phase pools onto the vault; the **staker `DxWfcgb…` is a single on-curve key that actively signs** (validator ops/redelegation only — it cannot move stake out of pool-owned accounts); `sol_withdraw_authority` is a single on-curve key (only gates instant SOL exit for the caller's own tokens); the program upgrade authority `47SND7bG…` is an off-curve/multisig-style PDA (full drain if compromised). The manager fee account is the ATA of EOA `Gutj91DY…`. Latent overlay, not E-U.
**S (stuck): $0** — no stuck value identified.

> Prior label in ZOMBIE-HUNT-II: "H-O". This deep-dive confirms H-O, closes E-U at $0 **today** (8 chain-native simulations + full gate audit), and documents the F-1 tripwire (§3a) that turns the pool into a permissionless capture the day the staker rotates its validator.

## 1. What Phase Stake is (verified on-chain)

- SPL stake pool state (611-byte account, borsh `StakePool` layout of the Sanctum fork; verified field-by-field):
  - `manager` = `7LqSTwcwHodtrRmPWkptKWraELTW2DpchzRWhdoS4HH1` (off-curve → program-controlled, e.g. multisig vault)
  - `staker` = `DxWfcgb2kENzzFy6ATP8KconVj6FriFU2GDnK1TmK6mK` (**on-curve → single keypair address**, currently unfunded/no account)
  - `stake_deposit_authority` = `DTws8vTwkJ1U1gpfgtbLsxydVgnDkLBoB9n1KYvw27BT` = the program's **default deposit PDA** `[pool, b"deposit"]` (verified by PDA derivation) → stake deposits are permissionless
  - `sol_deposit_authority` = **None** → SOL deposits are permissionless
  - `sol_withdraw_authority` = `phaseUTHSD78uiD8rnRQWuvbEakvY1chNSeftkpvz6d` (**on-curve keypair**, funded 0.02 SOL) → instant SOL withdrawals are **gated**
  - withdraw authority PDA = `9HYjrCF5evTobLmay372kpUWSNTrtmDU2NkQtqjdnHKa` (derived with stored bump 251; owns reserve/mint authority)
  - `validator_list` = `phaseeExd43yGjjad2FZSigdG9UTRpMdxS4aMerx821`; `reserve_stake` = `phaseECAeXantYWXvRGkmeh7ddQsUJTf7DcywquY9Z2`; `manager_fee_account` = `GAGMZfQU5ArnaciyQBnDLsEpbbhpyqPR24t98WYL4n6U`
  - Fees: epoch 0%, stake deposit 0%, SOL deposit 0%, stake/SOL withdrawal **0.1%** (Fee is `{denominator, numerator}` — denominator-first; values (1000,1))
- **Live custody (verified at slots 457,256,565 and 457,272,609 / epoch 1058; final snapshot `analysis/final_state_snapshot.json`):**
  - `total_lamports` = **30,002,233,945,691** (30,002.23 SOL) = reserve (86.13 SOL − rent) + the single live validator stake account `8QtQ1U34DPs2UKQiwUoRPMHnjJedsmdASZdbQHa7VHKh` (29,916.10 SOL, delegated to `CiTYUYPAPHdcri5yEfsmqVcs54J6j8X1QaiFLgYqMVe`, activation epoch 952, active)
  - validator list vec length = **1 live entry**; the remaining 3,949 entry slots contain stale bytes that the program ignores (bounds-checked)
  - `pool_token_supply` = 25,123,581,135,630 raw = 25,123.58 YIELD (matches mint supply exactly); **NAV = 1.19419 SOL/YIELD**
  - manager fee account holds 2.01457808 YIELD
  - SOL price used: **$101.6834** (DefiLlama, 2026-10-15) → **$3,050,729.63** for 30,002.23 SOL (DefiLlama protocol TVL snapshot: $3,066,607)

> The finding row's "25,183 SOL" is the YIELD *token* supply ballpark, not the pool's SOL backing; the on-chain backing is 30,002.23 SOL (the YIELD NAV is ~1.194, not 1.0). The row's "$3.06M" matches DefiLlama's TVL snapshot ($3,066,607) — consistent with 30,002 SOL at a slightly higher SOL price, or the token supply at ~$122/SOL. At the current DefiLlama SOL price ($101.6834, 2026-10-15) the backing is **$3,050,729.63**.

## 1a. Product & market context (OSINT, see `analysis/osint.md`)

- Phase = **Phase Labs** (phase.cc, @phase_), a Solana infra team operating since 2021 (8 named members). `phase.cash`/`@0xPhase` (Base CASH) is a **different project**; DefiLlama's parent grouping is a metadata error.
- YIELD is **effectively untraded**: one Raydium pool with **tvl 0 / zero volume**, no Meteora pair; Jupiter routes YIELD via `VaultLiquidUnstake` (non-AMM); 24h: 1 buy / 4 sells ($99.65 buy vs $2,699 sell volume); Sanctum Infinity holds only 20.15 YIELD. → the 19.4% NAV premium cannot be harvested at scale (no market to buy below NAV), and no meaningful below-NAV arb exists.
- Displayed prices disagree (phase.cc UI 1.121 vs Sanctum 1.1576 vs Jupiter 1.1928 vs on-chain NAV 1.1942); Sanctum/Jupiter show 0.0 APY for both Phase pools while Solana Compass shows ~5.45% — indexer/UI quirks; the on-chain stake is active and earning (stake account credits observed, lamports grow each epoch).
- **NAV premium explained:** the pool was created **2024-04-17 23:06:58 UTC** (slot 260,739,588; `analysis/creation_tx.json`, `analysis/onchain-state.md`); the 19.4% premium over 1.0 = **2.493 years of staking rewards ≈ 7.377%/yr CAGR** — normal, and the validator stake account equals delegation + rent exactly (no hidden donations). The only non-deposit inflow found in full history is a 141.59 SOL Jito MEV tip (2026-10-15). Recent deposits mint YIELD at exactly the current NAV.
- The SPMBzs program hosts **56 stake pools** (including jupSOL, NAV 1.2145) — Phase Stake is one instance; the program family is widely used and audited, **but this deployment is the unpatched upstream v1.0.0** (see §3a).
- No exploit, audit or advisory for Phase/YIELD/pdSOL found; no incident in DefiLlama's hack DB.

## 2. Gate map (every value path)

| Instruction | Gate (verified) | Attacker effect |
|---|---|---|
| `DepositSol` | `sol_deposit_authority` = None → no signature | mints YIELD at exact NAV (floor favors pool) — no bonus |
| `DepositStake` | deposit authority = default PDA → program signs (`invoke_signed`); source must be fully active (stake-program merge precondition) | mints at NAV; no authority signature |
| `WithdrawStake` | none beyond pool-token ownership (withdraw PDA is program-signed) | burns YIELD at NAV −0.1%; returns *stake* (must deactivate + cooldown) |
| `WithdrawSol` | `sol_withdraw_authority` must sign | **blocked** without Phase's key |
| `UpdateValidatorListBalance`, `UpdateStakePoolBalance`, `CleanupRemovedValidatorEntries` | permissionless cranks; all accounts PDA-checked | refresh state; cannot *inflate* `total_lamports`; **can *deflate* it via F-1** when a `Deactivating*` record exists (§3a) |
| `AddValidatorToPool`, `RemoveValidatorFromPool`, `Increase/Decrease*ValidatorStake`, `DecreaseValidatorStakeWithReserve`, `Redelegate`, `SetPreferredValidator` | staker (signer) | blocked |
| `SetManager`, `SetFee`, `SetStaker`, `SetFundingAuthority`, `Create/UpdateTokenMetadata` | manager/staker (signer) | blocked |
| `stake_split_from` = reserve | blocked while validator stake exists | reserve cannot be drained via stake path |

## 3. Chain-native simulation (CI, read-only)

`ci/simulate.js` — 8 `simulateTransaction` runs against live mainnet state (sigVerify=false; nothing sent). Results (`ci-out/simulation.json`, CI artifact):

| Sim | What | Result |
|---|---|---|
| A | fresh attacker ATA + `DepositSol` 2 SOL | **success**; minted 1,674,780,696 raw YIELD = exactly `floor(2e9·supply/total)` |
| B | A + `WithdrawStake` all minted tokens | **success**; attacker receives stake account with 1,997,999,998 lamports (NAV −0.1% fee), 0 YIELD left → round trip **loses** 0.1% + rent |
| C1 | `WithdrawSol` without authority account | **fail** `NotEnoughAccountKeys` |
| C2 | `WithdrawSol` with authority present but unsigned | **fail** `Custom:7 SignatureMissing` ("SOL withdraw authority signature missing") |
| D | `WithdrawStake` sourced from reserve | **fail** `Custom:23` ("withdrawing from reserve … use validator stake first") |
| E | `SetFee` as attacker | **fail** `Custom:6 WrongManager` |
| F | `AddValidatorToPool` as attacker | **fail** `Custom:21 WrongStaker` |
| G | `UpdateStakePoolBalance` as attacker | **success** (permissionless crank) |
| H | `DepositStake` with a fresh attacker-delegated stake account | deposit path reached the merge with **no authority signature** (both PDA authorizes succeeded); merge fails `Custom:6 MergeMismatch` because a freshly delegated source is *activating* while the pool stake is fully active — a stake-program state precondition, not a pool gate |

CI runs:
- run 1 (sims A–D): https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38748873096 — success
- run 2 (sims A–G): https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38749387375 — success
- run 3 (sims A–H + first F-1 attempt): https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38754480437 — sims success; F-1 PoC harness bug (fixed)
- run 4/5 (F-1 harness fixes): 38755612830 / 38756984395 — sims success; F-1 harness fixes (rentEpoch float, missing co-signer)
- run 6 (final, sims A–H + F-1 PoC): (recorded in `ci-log.txt`; artifacts in `ci-artifacts/`)

## 3a. F-1 — conditional unprivileged path (HIGH tripwire, not live today)

**Provenance first:** the deployed program is **not** a modified Sanctum fork — all 8 source files are byte-identical to upstream `solana-program/stake-pool@program@v1.0.0` except the `declare_id!` (SPMBzs…), a fee-rounding hardening (`Fee::apply` ceil), and off-chain instruction builders (see `analysis/program-audit.md`). The same code runs Sanctum's SPL1 program `SP12tW…`. **The pool is an unpatched old-version deployment.**

**The bug (F-1):** in `UpdateValidatorListBalance` (permissionless, no signer), the record loop initialises `active_stake_lamports = 0` and for a record with status `DeactivatingValidator`/`DeactivatingAll` and `no_merge=false`:

- if the stake is already inactive → it merges into the reserve;
- **else (stake still active/cooling) → nothing is assigned** → the write-back stores **0** while the validator stake account still holds the lamports (`sp2_processor.rs:2469-2496`, write-back ≈ 2533-2535).
- Upstream fixed it in `program@v2.2.0` by adding `else { active_stake_lamports = validator_stake_info.lamports(); }` (verified in `upstream/up_v22_processor.rs`).

**Effect:** `UpdateStakePoolBalance` recomputes `total_lamports = (reserve − min_reserve) + Σ records` → understated by `X` (the deactivating validator's stake). Any deposit in that epoch mints `D·S/(T−X)` instead of `D·S/T`. When the stake later merges into the reserve, NAV recovers — the attacker's excess tokens become backed and are cashed out via permissionless `WithdrawStake` (the program explicitly supports splitting from the reserve when no validator stake remains).

**Precondition (privileged):** a `Deactivating*` record exists. Only the staker's `RemoveValidatorFromPool` creates it (`sp2_processor.rs:1208-1213`; staker-gated). No permissionless instruction can create it. **Live status: Phase's validator list has exactly one record, status `Active`** (verified slot 457,272,609) → **not reachable today**.

**Quantification (Phase's live numbers, X = 29,916.10 SOL, T′ = 86.13 SOL, S = 25,123.58, gain = D·X/(T′+D)):**

| Attacker deposit D | Minted YIELD (vs fair) | Gain at recovery | USD |
|---|---|---|---|
| 10 SOL | 2,916.6 (348× fair) | ≈ 3,112 SOL | ≈ $316k |
| 100 SOL | 29,166 (116× fair) | ≈ 16,084 SOL | ≈ $1.63M |
| 1,000 SOL | 291,662 (11.6× supply!) | ≈ 27,543 SOL (92% of pool) | ≈ $2.80M |

**Window:** from the staker's removal until the deactivating stake merges into the reserve — ~1–2 epochs ≈ 2–5 days, recurring on every validator rotation. Historical signal: the pool has rotated validators before — the validator list's stale `ReadyForRemoval` bytes (epochs 953–954: `sTach38…`, `chdv8H9…`, `hnhxfrnd…`, `nateBZg7…`) are remnants of removed validators; the current validator was (re)delegated at activation epoch 952.

**PoC:** `ci/f1/` — a local `solana-test-validator` seeded with cloned mainnet accounts (pool, validator list, reserve, mint, fee account, validator stake account, upgradeable program) and the crafted precondition (record status byte → `DeactivatingValidator`; the stake account left active, since only the staker can legitimately create the state). The attack tx `[UpdateValidatorListBalance, UpdateStakePoolBalance, DepositSol(10 SOL)]` is signed by a **fresh keypair** and is fully permissionless. Results in `ci-out/f1_poc_result.json` / `ci-out/f1_poc.log`.

**Remediation:** Sanctum upgrades the program to v2.2.0+ behavior (or Phase never removes its last validator — fragile). Until then, the trigger is a single staker transaction away.

## 4. Verdict

**E-U = $0 today (high confidence).** No fresh unprivileged path moves value beyond fair NAV **while the pool's validator list stays `Active`**. The one conditional unprivileged path (F-1, §3a) requires a staker validator-removal; if triggered, a fresh attacker can capture up to ≈ $2.80M of the pool for ~1,000 SOL of capital (≈ $316k for 10 SOL) — a HIGH tripwire that recurs on routine validator rotation. The only other conditional "profit" is ordinary market arbitrage if YIELD ever trades below NAV — the profit comes from the seller, not the pool, and YIELD has no meaningful market (see §1a).

**Residual/latent risks (privileged, not E-U):** the **staker is a single on-curve key** (validator ops only — it cannot move stake out of pool-owned accounts) and `sol_withdraw_authority` is a single on-curve key (only gates instant SOL exit from the ~86 SOL reserve for the caller's own tokens); the manager is an off-curve PDA and the program upgrade authority is an off-curve/multisig-style PDA (full-drain power if compromised). The 19.4% NAV premium is real, fully backed, and belongs to YIELD holders.

## 5. Methodology & files

**Method.** (1) Located the target from DefiLlama's registry (`solanaStakePool.js`), then read all state on-chain via keyless public RPCs (publicnode / api.mainnet-beta): pool, validator list (borsh `BigVec` layout), reserve, validator stake account, mint, fee account, authorities, programdata/upgrade authority; (2) verified PDA derivations against the chain (withdraw authority bump 251, deposit PDA, stake PDA) after fixing an ed25519 on-curve bug in the local tooling; (3) audited the deployed program source (Sanctum branch, hash-compared to upstream v1.0.0/v2.2.0) — full instruction→gate table in `analysis/program-audit.md`; (4) ran 8 chain-native `simulateTransaction` cases (sigVerify=false, nothing signed or sent) against live state; (5) built a local `solana-test-validator` F-1 PoC with cloned mainnet accounts and a crafted precondition; (6) OSINT/market checks (`analysis/osint.md`).

**Caveats & limitations.**
- Solana has no EVM-style local fork replay here; the live-state simulations execute against mainnet state at simulation time (not historical blocks). F-1's precondition cannot be created without the staker key, so its PoC uses a local validator with a crafted (legitimately-shaped) account state; the exploit instructions themselves are the real deployed program.
- Sim H (DepositStake) could not complete the merge because a freshly delegated source is still *activating* while the pool stake is fully active (`MergeMismatch`) — a stake-program state precondition, not a pool gate; production stake deposits require an active source (or the ephemeral-account flow).
- The staker's on-chain nature (single on-curve key) cannot be resolved further from chain data (it may be held in custody/MPC off-chain).
- Public RPC rate limits; no keyed Solana RPC was used (Alchemy capacity exhausted). Publicnode's `getSignaturesForAddress` index is truncated to ~24 h — full history was re-fetched via api.mainnet-beta (41k+ pool sigs).
- Numbers are point-in-time (epoch 1058, 2026-10-15); the pool is live and changes as users deposit/withdraw.

**Files index.**
- `analysis/pool_state_parsed2.json`, `final_state_snapshot.json` — pool state (borsh-parsed) + final snapshot
- `analysis/vlist_used.json`, `stake_account_final.json` — validator list (vec_len=1) + the validator stake account
- `analysis/sol_util.py`, `rpc.sh`, `parse_pool2.py`, `crossval.py`, `pdas.py`, `stake_accounts_final.py` — tooling (PDA derivation, on-curve check, parsers)
- `analysis/program-audit.md` — full instruction→gate audit, provenance diff, F-1 analysis (child agent, independently verified here)
- `analysis/osint.md` — team/market/security OSINT (child agent)
- `analysis/creation_tx.json`, `history_analysis.json`, `pools_scan.json`, `auth_map.json` — history/NAV-premium evidence, 56-pool scan, authority mapping (child agent)
- `ci/simulate.js`, `ci/run.sh`, `ci-out/simulation.json|log` — live-state simulations A–H
- `ci/f1/{fetch_accounts.js,attack.js,run.sh}`, `ci-out/f1_poc_result.json|log`, `ci-out/test-validator.log` — F-1 PoC
- `summary.json` — machine-readable summary
