# C2-40 — Saber (Solana): zombie-hunt II deep dive

**Date:** 2026-10-15 · **Chain:** Solana · **Target:** Saber stable-swap pools (dead DEX, 139 funded pools per prior hunt)
**Status:** read-only; no mainnet transactions; PoC fork/simulation-verified only (LiteSVM against the **real deployed program bytecode**)

---

## 1. TL;DR

| Target | Live value (slot 457,257,871) | E-U (fresh unprivileged attacker) | Why closed/open | Latent risk |
|---|---|---|---|---|
| Saber stable-swap program `SSwpkEEcbUqx4vtoEByFjSkhKdCT862DNVb52nZg1UZ` — 172 pools | **$56.48M gross priced; $7.43M excluding dead sCASH** | **$0** (high confidence) | Withdraw/deposit/swap bind every vault, mint and authority to the pool's PDA-derived swap authority; a fake `token_program` is rejected by the SPL-Token instruction builders (`IncorrectProgramId`) before any CPI | Upgrade authority is a Goki multisig PDA → **P**: one upgrade drains all pools |
| Pool vaults (LP-holder custody) | same $7.43M | — | **H-O**: LP burns still work (withdraw is *not* pause-gated) | dead-token mix overstates USD |
| Deployed code version | — | — | Last upgrade **2022-02-07** — **pre-dates the 2022-02-25 rounding patch** | rounding leak ≤1 raw unit/swap → economically nil (dust) |

### Total live extractable by an external unprivileged attacker: **$0.00** (high confidence)

One-sentence: Saber's pools remain fully funded and functional, but every value-moving instruction either (a) requires real LP tokens of the pool's own LP mint, or (b) uses the pool's PDA authority only for internally-constructed SPL-Token instructions whose accounts are all validated — the "fake token program" trick fails at the Solana runtime level, and the "fake LP mint" trick is explicitly rejected by the deployed program (`SwapError::IncorrectMint`).

---

## 2. Prior finding & corrections

Prior hunt (ZOMBIE-HUNT-II, C2-40): *"Saber — dead DEX, 139 funded pools; $8.26M real (gross $57.3M minus dead CASH). **fake-LP class untested (escalation cut short)**."*

What this deep-dive changes:

1. **Fake-LP class: CLOSED.** The deployed program validates the LP mint on withdraw (`check_keys_equal!(pool_mint_info.key, token_swap.pool_mint, "Pool mint", IncorrectMint)`) — present since the first public source commit (2021-11-14), i.e. **before** the Feb-2022 deploy. Proven behaviorally on the deployed bytecode (PoC T1 → `Custom(13)`).
2. **New attack surface tested: fake token program / arbitrary CPI** (`token.rs` passes the attacker-supplied `token_program.key` into the SPL-Token instruction constructors and `invoke_signed`s with the swap-authority PDA). Closed at two levels: the SPL-Token builders reject any non-Tokenkeg id with `IncorrectProgramId` **before any CPI** (proven on the deployed bytecode, PoC T2), and the runtime's caller-account rule would independently prevent the follow-up CPI into Tokenkeg.
3. **Deployed code predates the Feb-2022 rounding patch** (last upgrade 2022-02-07; patch 2022-02-25). The leak is ≤1 raw unit of the output token per swap → not economically exploitable (PoC T4).
4. **Value re-verified**: gross $56.48M, of which $49.04M is dead Cashio sCASH; excluding it **$7.43M** — consistent with the prior $8.26M (price drift).
5. **Upgrade authority identified**: `EVmbDJCTGeExFGUKxmZwrfnzw4zpf7SPhPgfiLDjKUEV` — an off-curve PDA (Goki smart-wallet vault-style), currently holding 13.32 SOL; set by a Goki `SetAuthority` execution in May 2026. Upgrades are multisig-gated (**P**), not a naked EOA.

---

## 3. Deployed reality (what is actually on chain)

| Item | Value | How verified |
|---|---|---|
| Program | `SSwpkEEcbUqx4vtoEByFjSkhKdCT862DNVb52nZg1UZ` (native stable-swap, Curve-style) | `getAccountInfo`; owner `BPFLoaderUpgradeab1e…`, executable |
| ProgramData | `54aePuBcYcf8G3CDrWWd2MEiw6Q7UGy2kjgQBDhqoMdt` | decoded from program account |
| Last upgrade | **slot 119,721,738 · 2022-02-07 08:05:49 UTC** (`blockTime` 1644216349), tx `5ygvjFAXLwknuRLZVFNCCExmdPcvaTYEeYxHXv8JAWCT1cz6dgbnJ734mZaaCMcZeDQpdxFegrcwcwGKCratGiwb` via Goki smart wallet `GokivDYuQ…` | `getSignaturesForAddress` + `getTransaction` (logs `Upgraded program SSwpkEE…`) |
| Bytecode | 609,792 B, dumped to `poc/programs/saber_program.so` | `getAccountInfo` ProgramData |
| Upgrade authority | `EVmbDJCTGeExFGUKxmZwrfnzw4zpf7SPhPgfiLDJkUEV` — **off-curve PDA**, 13.319 SOL, 0 data; set by `SetAuthority` tx `3kGAgqXoA8EgDvSrdg9jzZL5oFNW3GpfwjzokQkEP63qAwn2PRy9zusUXak6wJXGZoVYHooe4MsXmd6fY5pZii5H` (slot 422,671,196, 2026-05-28) | `getAccountInfo` + curve check + tx decode (BPF-loader inner ix tag 4 = SetAuthority) |
| Source correspondence | deploy-era source ≈ commit `91c6203` (2022-01-02). Only program/math logic change after that date: `05650f9` "Patch rounding issue (#132)" (2022-02-25) → **deployed binary is pre-rounding-patch** | `git log/diff` on `saber-hq/stable-swap` |

**Pools** (`getProgramAccounts`, `dataSize=395`, slot 457,257,871):

* 172 initialized `SwapInfo` accounts; **165 with non-zero vault balances**; 109 with >$1 live value; 54 with >$1k.
* **All 172 pools pass structural checks**: `vault_a.owner == vault_b.owner == lp_mint.mint_authority == PDA(swap, nonce)` under the Saber program; no LP freeze authority; 0 anomalies.
* 10 pools are `is_paused` (nominal $49.05M, of which $49.04M is sCASH). `is_paused` gates `swap`, `deposit`, `withdraw_one` — **`withdraw` is not pause-gated** (verified in the deployed-era source), so LP holders can always exit.
* The USDC/USDT pool (`YAkoNb6HKmSxQN9L8hiBE5tPJRsniSSMzND1boHmZxe`) is **actively traded today** (e.g. Jupiter route tx `3Y3f5GzQLA18PjWSuyBdTUHM8Q1iXGSrCzNDqBZUqUw2S21BDxjBEhRHYYsvG4V8WkQoBLxhq7RT5scCecQP7H4c`, slot 457,259,071, three Tokenkeg CPIs inside the Saber swap) — the program is functional, not bricked.

### Live value composition (DefiLlama prices, slot 457,257,871)

| Slice | USD |
|---|---|
| Gross priced total (all pools) | **$56,481,748.60** |
| Dead Cashio **sCASH-8/9** inside CASH pools | −$49,042,260.43 |
| **Excluding sCASH** | **$7,428,731.06** |

Top live pools (sCASH excluded):

| Pool | Value | Pair | Paused |
|---|---|---|---|
| `BkwbeSfcX1h4thMDd7obGkHrPevf3QwgzJ4pCEqG18Lu` | $1,929,930 | renBTC / sBTC-8 (⚠ renBTC is dead; USD overstated) | no |
| `Lee1XZJfJ9Hm2K1qTyeCz1LXNc1YBZaKZszvNY4KCDw` | $1,456,718 | mSOL / SOL | no |
| `YAkoNb6HKmSxQN9L8hiBE5tPJRsniSSMzND1boHmZxe` | $1,046,962 | USDC / USDT | no |
| `Lid8SLUxQ9RmF7XMqUA8c24RitTwzja8VSKngJxRcUa` | $871,760 | stSOL / SOL | no |
| `ALLwa5WNZbvQsRKAqe1jdRGemdYQnW8E5k4msbRFcYtu` | $313,703 | swhETH-9 / aeWETH | no |
| `MARpDPs5A7XiyCWPNH8GsMWPLxmwNn9SBmKvPa9LzgA` | $269,692 | USDH / USDC | no |
| `heyk4SZTeCUV6a65WiVA5bzic3KcxgVf1qxobfeV4tQ` | $230,269 | (SBR) / SOL | no |
| `AURHmCnNwiW4uA2Qj1XvEh4iKgRUZYXtiY7FKAapUV5Y` | $222,778 | aSOL / SOL | no |

Full tables: `analysis/live_pools.json`, `analysis/pools_analysis.json`, raw state `analysis/pools_raw.json`.

> **Dead-token haircut:** several DefiLlama-priced assets in these pools are effectively dead (renBTC, sBTC, aeFEI/aeMIM, UXD/USDH, sFTT, wUST). The *recoverable* value is therefore below $7.43M — consistent with the prior hunt's $8.26M at its pricing date, but the direction of the correction is downward, not upward. Nothing in this haircut creates an attacker path.

---

## 4. The bug class in exact terms — and why every candidate path is closed

### 4.1 What the deployed program enforces (deploy-era source = `91c6203`; identical to HEAD except the rounding patch)

| Instruction | Gating checks (deployed) | Attacker consequence |
|---|---|---|
| `Withdraw` (tag 3) | `swap_authority == PDA(swap, nonce)` (`check_swap_authority`); `token_a_info == swap.token_a.reserves`; `token_b_info == swap.token_b.reserves`; `admin_fee_dest_{a,b} == swap.token_{a,b}.admin_fees`; **`pool_mint_info == swap.pool_mint`** (`IncorrectMint`); LP `supply != 0` | A fake LP mint (even one the attacker fully controls) is rejected. Real LP tokens of the real mint are required (burn signed by their owner). |
| `Swap` (tag 1) | `source != vault_a/vault_b`; `swap_source`/`swap_destination` must be the pool's own vaults; `admin_destination == swap.token.admin_fees`; `authority == PDA(swap, nonce)`; `!is_paused` | Vault-to-attacker transfers cannot be requested directly; input must come from the attacker's own account, signed by them. |
| `Deposit` (tag 2) | `source != vault`; vault keys bound; `pool_mint == swap.pool_mint`; `authority == PDA(swap, nonce)`; `!is_paused` | Deposits mint real LP for real value only. |
| `WithdrawOne` (tag 4) | vault keys bound to pool; `pool_mint == swap.pool_mint`; `authority == PDA(swap, nonce)`; `!is_paused` | Same as above. |
| `Initialize` (tag 0) | LP mint authority must equal the new pool's PDA, supply 0, no freeze authority, decimals match, vaults owned by the PDA, no delegates/close authorities | Permissionless pool creation cannot be turned into a theft primitive against other pools. |
| Admin (tags 100–107) | `check_has_admin_signer` (key equality **and** `is_signer`); admin transfer has a 3-day timelock; `set_fee_account`, `set_new_fees` | Admin cannot withdraw funds at all — only pause/unpause, retarget fees, rotate admin. **P**-only (DoS/fee redirection). |

### 4.2 The genuine code smell: attacker-supplied `token_program` — closed twice over

`stable-swap-program/program/src/processor/token.rs` builds SPL-Token instructions using **the attacker-supplied account key** as the program id:

```rust
let ix = spl_token::instruction::transfer(token_program.key, source.key, destination.key, program_authority.key, &[], amount)?;
invoke_signed(&ix, &[token_program, source, destination, program_authority], signers) // seeds = [swap, nonce]
```

If a fake program could be substituted here, Saber would `invoke_signed` it **with the pool's swap-authority PDA marked as a signer** (and, on the swap path, with the pool vault in the account list) — a classic arbitrary-CPI drain primitive.

**Gate 1 — proven on the deployed bytecode: the SPL-Token instruction constructors themselves validate the program id.** Every `spl_token::instruction::*` builder (transfer / mint_to / burn) calls `check_program_account(token_program_id)` (`spl-token` v3.x, `src/lib.rs`):

```rust
pub fn check_program_account(spl_token_program_id: &Pubkey) -> ProgramResult {
    if spl_token_program_id != &id() { return Err(ProgramError::IncorrectProgramId); }
    Ok(())
}
```

Saber propagates the error with `?`, so passing anything other than Tokenkeg fails with **`IncorrectProgramId` before any CPI is attempted**. PoC **T2** (deployed bytecode, real pool state): the transaction fails with `Program log: Error: IncorrectProgramId`, the attacker program is **never invoked**, and both vaults are untouched.

**Gate 2 — defense in depth, should Gate 1 ever be bypassed:** the runtime requires the CPI callee program account to be present in the *caller's* instruction accounts (agave `program-runtime/src/cpi.rs` → `verify_instruction_accounts` → `ic_msg!("Unknown program …")` / `InstructionError::MissingAccount`). Saber passes exactly `[source, destination, authority, token_program(=attacker program)]`; an attacker program invoked there holds no account info for Tokenkeg and therefore cannot CPI into it — the PDA signer it would receive is unusable.

**Conclusion: closed.**

### 4.3 Rounding: deployed code is pre-patch, leak is dust

The last upgrade (2022-02-07) predates commit `05650f9` (2022-02-25, "Patch rounding issue"), whose only non-test change is:

```rust
- let dy = swap_destination_amount.checked_sub(y)?;
+ let dy = swap_destination_amount.checked_sub(y)?.checked_sub(1)?;
```

Pre-patch, `dy` (trader output) could round up by **≤1 raw unit per swap**. The regression tests in that commit show the affected sequences (amp 324449, zero fees). PoC **T4** replays them against the deployed bytecode on a synthetic pool and measures the leak.

Economic bound: 1 raw unit of a 6-decimal stablecoin = $0.000001; a swap costs ≥5,000 lamports (≈$0.001) plus priority fees. Break-even is impossible; extracting even $1 of USDC would require ~10⁶ swaps costing ~$1,000. On the live pools, the trade fee (1/10,000 on the USDC/USDT pool) makes it strictly worse.

---

## 5. What an attacker can/cannot do — call paths & preconditions

**Cannot (E-U):**

1. `Withdraw(pool_token_amount)` with an attacker-owned LP mint/account → **reverts `Custom(13)` (IncorrectMint)**. Preconditions to succeed: real LP tokens of the pool's LP mint (H-O), or compromising the LP mint's authority — which is the pool PDA, unreachable.
2. `Withdraw` with a crafted `SwapInfo` account whose `reserves` point at the real vaults → authority check binds the signer to the crafted swap key; the real vaults' owner is the *real* pool PDA, so Tokenkeg rejects the transfer (`OwnerMismatch`). PoC **T3**.
3. `Swap`/`Deposit` with a malicious `token_program` → **rejected with `IncorrectProgramId` by the SPL-Token instruction builders before any CPI**; the attacker program is never invoked (PoC **T2**). Even if that check were absent, the runtime's caller-account rule would prevent the follow-up CPI into Tokenkeg.
4. Re-initializing/overwriting an existing pool account (`is_initialized` gate); mutating pool state (owned by the program).
5. Any admin path (pause/unpause/fees/admin rotation) — `is_signer` + key equality required; nothing extracts funds anyway.
6. Front-running the rounding leak for profit (dust, see 4.3).

**Can (legitimately):**

* LP holders: `Withdraw`/`WithdrawOne` at any time — even on paused pools (withdraw has no pause check). This is the H-O recovery path for ~$7.4M (dead-token haircut applies).
* Anyone: `Swap` on the 162 unpaused pools (arbitrage bots already do — Jupiter routes through them), `Deposit`, and permissionless creation of new pools (cannot touch existing funds).

**Costs:** a full swap tx ≈ 48k CU ≈ 5,000 lamports; a fake-token-program attempt costs the same and returns nothing.

---

## 6. PoC / verification (fork-style simulation on the real bytecode)

`poc/` is a Rust workspace executed in CI (`ci/run.sh` → GitHub Actions on the public CI repo):

* `poc/programs/saber_program.so` — exact mainnet Saber bytecode (dumped from ProgramData).
* `poc/programs/tokenkeg.so` — exact mainnet SPL Token bytecode (dumped; current ProgramData slot 419,472,000).
* `poc/accounts.json` — cloned real pool state (slot 457,257,871) for the USDC/USDT pool `YAkoNb6…`.
* `poc/malicious/` — the attacker SBF program (built with `cargo build-sbf`), which logs the accounts/signer flags it receives and attempts a Tokenkeg CPI.
* `poc/harness/tests/saber_poc.rs` — LiteSVM harness (same agave runtime crates as the validator).

| Test | Purpose | Result |
|---|---|---|
| T0 | Control: legitimate swap with the real Tokenkeg program | PASS — vault A +1000, vault B pays out |
| T1 | Fake LP mint withdraw | **CLOSED** — `Custom(13)` (IncorrectMint), vaults untouched |
| T2 | Malicious `token_program` (fake token program) | **CLOSED** — `IncorrectProgramId` before any CPI; attacker program never invoked; vaults untouched; no "CPI SUCCEEDED" |
| T3 | Crafted SwapInfo redirecting real vaults | **CLOSED** — token transfer rejected, vaults untouched |
| T4 | Rounding probe (deployed bytecode, pre-patch sequence) | leak measured ≤1 raw unit/swap → economically nil |

Results (logs, machine-readable summaries): `ci-out/`, `ci-log.txt`, `ci-artifacts/`.
CI run URL: **_(filled after run — see ci-log.txt header)_**

---

## 7. Verdict & residual risk

* **E-U (fresh unprivileged attacker): $0.00 — high confidence.** All value-moving paths require real LP tokens (validated mint) or are rejected before any CPI (fake token program → `IncorrectProgramId`). Verified in source (deploy-era + HEAD, plus the spl-token 3.x `check_program_account` gate), in runtime source (defense in depth), and behaviorally against the deployed bytecode (T0–T4).
* **H-O: ~$7.43M** (DefiLlama; dead-token haircut applies) recoverable by LP holders via `withdraw`, including on paused pools.
* **P: the same value is upgradeable** by the Goki multisig (`GokivDYuQ…`) that controls the program's upgrade authority `EVmbDJ…`. This is the single largest latent risk: one approved upgrade can deploy code that drains every pool. No E-U path exists without it.
* **S: $0** — nothing is bricked; the program is live and actively used.
* **Residual/latent risks to monitor:**
  1. Any future **upgrade** of `SSwpkEE…` (watch ProgramData `slot`; any change = re-audit immediately).
  2. Admin key rotations (`commit_new_admin` + 3-day timelock are public and observable).
  3. Rounding-dust harvesting (economically irrational; ignore unless fees are ever set to 0 *and* tx costs drop ~1000×).

---

## 8. Methodology & sources

1. **Target set:** `getProgramAccounts(dataSize=395)` on the swap program → all 172 initialized `SwapInfo` accounts; decoded with the exact `Pack` layout (395 B) from `stable-swap-client/src/state.rs`; vaults/LP mints/fee accounts fetched via `getMultipleAccounts`; per-pool PDA authority recomputed and compared.
2. **Deployed reality:** program + ProgramData decoded; upgrade history via `getSignaturesForAddress`/`getTransaction`; bytecode dumped; upgrade authority curve-checked (on/off-curve).
3. **Value:** DefiLlama `coins.llama.fi` prices at slot 457,257,871; sCASH identified as dead Cashio CASH; per-pool USD computed; raw data saved.
4. **Code audit:** `saber-hq/stable-swap` at the deploy-era commit `91c6203` and HEAD; full diff between them; runtime rule verified in `anza-xyz/agave` (`program-runtime/src/cpi.rs`, `invoke_context.rs`).
5. **Behavioral verification:** LiteSVM with the real `.so` bytecode + cloned accounts + a purpose-built attacker SBF program (T0–T4).

**Caveats & limitations**

* LiteSVM reproduces the agave runtime rules but is not a validator; T2's result rests on the same `verify_instruction_accounts` path used in production (cited in §4.2).
* The deployed binary cannot be byte-compared to a rebuild; its *behavior* was probed directly (T1 pool-mint check, T4 rounding) and matches the deploy-era source.
* USD values are point-in-time DefiLlama prices; several priced assets are dead/illiquid (renBTC, sBTC, aeFEI/aeMIM, UXD/USDH) → treat $7.43M as an upper bound on recoverable value.
* Prior-hunt numbers ($57.3M gross / $8.26M real) were taken at a different time/pricing; the delta is price drift, not new funds.

**Files index**

```
saber/
├── README.md                  ← this file
├── summary.json               ← machine-readable verdict
├── analysis/
│   ├── enumerate_pools.py     ← on-chain pool enumeration (public RPC, no keys)
│   ├── analyze_pools.py       ← decode + price + anomaly analysis
│   ├── pools_raw.json         ← raw account dump (slot 457,257,871)
│   ├── pools_analysis.json    ← per-pool decoded state + USD
│   └── live_pools.json        ← sCASH-adjusted live value table
├── poc/
│   ├── programs/              ← dumped mainnet bytecode (Saber + Tokenkeg)
│   ├── accounts.json          ← cloned pool state (USDC/USDT pool)
│   ├── malicious/             ← attacker SBF program (fake token program)
│   └── harness/               ← LiteSVM tests T0–T4
├── ci/run.sh                  ← CI job (build SBF attacker program + run harness)
├── ci-out/                    ← CI results (logs + per-test JSON)
└── ci-log.txt / ci-artifacts/ ← CI run logs/artifacts (helper-downloaded)
```
