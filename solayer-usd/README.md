# Solayer USD (sUSD) — live extractability for an external unprivileged attacker

**Date:** 2026-10-25 · **Chain:** Solana mainnet-beta · **Status:** read-only research; `simulateTransaction(sigVerify=false)` only;
**no mainnet transaction was ever signed or sent**. This folder is self-contained.

**Target:** DefiLlama slug `solayer-usd` (~$0.71M TVL). The DeFi Llama adapter `projects/solayer-susd/index.js`
sums the holdings of one program-owned account, `FhVcYNEe58SMtxpZGnTu2kpYJrTu2vwCZDGpPLqbd2yG`, which turns
out to be the **sUSD pool PDA** of Solayer's `usdc-pool-program` (`s1aysqpEyZyijPybUV89oBGeooXrR22wMNLjnG2SWJA`).
The real sUSD mint is `susdabGDNbhrnCa6ncrYo81u4s9GM8ecK2UwMyZiq4X` (Token-2022, interest-bearing, symbol `sUSD`),
**not** the `LAYER4x…` address that DefiLlama lists as the entity key (that is the LAYER governance mint).

---

## 1. TL;DR

| Question | Answer |
|---|---|
| External unprivileged extractable **now** | **$0** |
| Confidence | **HIGH** |
| Why | The only value-moving instructions are all gated by Anchor `has_one` (manager / operator / rate-authority). The one user-facing mint path (`deposit`) is **closed** (the pool is in a sunset wind-down; `deposit.rs:73 DepositClosed`, and `update_susd_rate`/`collect_fee`/`initiate_batch_withdraw` all revert `6036 PoolSunset`). The one user-facing redeem path (`withdraw`) **only escrows the caller's own sUSD** and never moves USDC; the USDC payout is a separate `resolve_batch_withdraw` that requires the operator's signature. |
| Pool USDC backing (recoverable by rightful sUSD holders) | 708,102.871791 USDC ≈ **$707,819** |
| Privileged (manager/operator/multisig) reachable | 708,102.871791 USDC ≈ $707,819 |
| Stuck / bricked | $0 |

| Category | USD | Notes |
|---|---|---|
| **E-U** external unprivileged | **0** | every candidate path reverts; see §6 |
| **H-O** holder/user self-service recoverable | **707,819** | pool's USDC, redeemable by sUSD holders via `withdraw`→operator `resolve` (payout needs the operator step; docs: T+1) |
| **P** privileged / governance | **707,819** | manager (`7671j7qp…`, a Squads vault) + operator hot key (`AxnDY6n…`) + program upgrade authority |
| **S** stuck / bricked | **0** | |

---

## 2. What the target actually is

Solayer sUSD is a **yield-bearing stablecoin backed by tokenized T-bills** (OpenEden USDO/cUSDO). Its on-chain
core is an Anchor program, `usdc-pool-program` v0.1.0, that holds USDC and (formerly) cUSDO in a pool PDA and
mints/burns the interest-bearing sUSD mint against it.

* Program (BPFLoaderUpgradeable): `s1aysqpEyZyijPybUV89oBGeooXrR22wMNLjnG2SWJA`
  * programdata `7bzcebKDN8qDkftxobwArKJL8xSGaZ6zBPaY4C4wEhkf`, `last_deploy_slot 459777916`, space 1,044,725
  * **upgrade authority `7671j7qpSf9X5KbQDraXReGK8Dxg5xGjr9n913BWhqru`** (= pool manager = sUSD mint authority)
* sUSD mint `susdabGDNbhrnCa6ncrYo81u4s9GM8ecK2UwMyZiq4X` (Token-2022; `interestBearingConfig`, `tokenMetadata`,
  `metadataPointer`; mintAuthority = freezeAuthority = rateAuthority = the **pool PDA** `FhVcY…`)
* Pool PDA `FhVcYNEe58SMtxpZGnTu2kpYJrTu2vwCZDGpPLqbd2yG` (379-byte `Pool` account, discriminator `f19a6d0411b16dbc`)

The program's **full Anchor IDL is stored on-chain**, zlib-compressed inside a program-owned account
(`3wgB6vYowPy9PeqmZeFBM3o5R5zHGSmNamViuLrGxRo`, discriminator `184662bf3a907b9e`, 18,628 bytes decompressed).
It was recovered and is saved as `analysis/idl.json`. It is slightly **stale** vs. the deployed code: it lacks the
three `sunset_*` instructions and the `SunsetInfo` account type that are present in the ELF and in real tx logs.

### 2.1 Instruction surface (from ELF + on-chain IDL + real tx logs)

| # | Instruction | Signer | Value movement |
|---|---|---|---|
| 1 | `initialize` | manager | creates pool |
| 2 | `update_susd_metadata` | manager | metadata |
| 3 | `update_susd_rate` | rateAuthority | sets interest rate |
| 4 | `deposit` | **user** | user USDC → pool, mints sUSD to user |
| 5 | `initiate_batch_deposit` | operator | USDC → cUSDO via OpenEden |
| 6 | `resolve_batch_deposit` | operator | mints sUSD for the batch |
| 7 | `withdraw` | **user** | **escrows user sUSD → `poolSusdVault`; creates `WithdrawProof`** |
| 8 | `initiate_batch_withdraw` | operator | redeems cUSDO → USDC, sets payout ratio |
| 9 | `resolve_batch_withdraw` | operator | **pays USDC to each proof's `userUsdcVault`** |
| 10 | `update_openeden_info` | manager | ratios/vaults |
| 11 | `set_fee` / `set_manager` / `set_operator` / `set_rate_authority` | manager | roles |
| 12 | `collect_fee` | operator | mints fee sUSD to fee recipient |
| 13 | `emergency_transfer_rwa_token` | manager | moves cUSDO out |
| 14 | `handle_frozen_accounts` | **user** | gated on batch status |
| 15 | `create_susd_offset_pda` | manager | sets supply offset |
| 16 | `claim_with_migrated_deposit_proof` | **user** | pays sUSD from reserve |
| 17 | `migrate_deposit_proof` | manager | migrates legacy proofs |
| 18 | `sunset_redeem_all` | manager | redeems RWA to USDC |
| 19 | `sunset_finalize` | manager | sweeps USDC to main vault |
| 20 | `sunset_initiate_batch_withdraw` | operator | sunset redeem |

Only #4, #7, #14, #16 have a user-controlled signer; #4 is closed, #14/#16 are gated (see §6).

---

## 3. Live-state assessment (slot **461,393,409**, 2026-10-25)

| Item | Address | Value / check |
|---|---|---|
| Pool `Pool` acct | `FhVcYNEe58SMtxpZGnTu2kpYJrTu2vwCZDGpPLqbd2yG` | owner = program, space 379, disc `f19a6d0411b16dbc`, 0.0697 SOL |
| Pool.manager | `7671j7qpSf9X5KbQDraXReGK8Dxg5xGjr9n913BWhqru` | system acct, 0.0999 SOL — **Squads vault** (all admin txs executed via `SQDS4ep65…` `VaultTransactionExecute`) |
| Pool.operator | `AxnDY6nekRa4hEY1rm1g11A51EPPU29iAXXxh8vAqpM8` | system acct, 0.2846 SOL (hot key) |
| Pool.rateAuthority | `uRwMu2114gN23NZVFxkjM6Dwk1iqSc1LLQsHMmiT6Lr` | system acct, 0.2883 SOL |
| Pool.fee | 5 / 1000 (0.5%) → `3NC1UF4pus6ditVzbcJCLFCVyBLVJm2kxKMhb3mPAoaz` | |
| Pool.usdcMint | `EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v` | USDC |
| Pool.poolUsdcMainVault | `DN2KzAeiHFnndVpjWSTw8UkwF9PZaFSthSnVoW1MVThQ` | **708,102.871791 USDC** |
| Pool.susdMint | `susdabGDNbhrnCa6ncrYo81u4s9GM8ecK2UwMyZiq4X` | raw supply **617,526.573503**, uiAmount **729,545.645829** (interest-bearing) |
| Pool.poolSusdVault | `FfELPrBpJBzyND1xTM6NmXRaQJbuP8c5J8jmJWZvDJds` | 20,671,325 raw sUSD (24.42 ui) — **escrow of pending withdrawals** |
| Pool.batchDepositStatus | — | **2** (`DepositClosed` ⇒ pool is sunsetting) |
| Pool.batchWithdrawStatus | — | 1 |
| Pool.currentWithdrawId / currentWithdrawSusdAmount | — | 443 / 20,671,325 |
| sUSD reserve (legacy claims) | `93AZbo6a7De8YjSMbAL8xVasetsfwUjJnU5HMnzEaFXK` | 3,707,526 raw sUSD |
| `susdSupplyOffset` | `5P5xvu52ocJegFgdynRB2MtCJNbnw2jt6vbiAtFB8zQz` | 640,917,460 |
| `SunsetInfo` | `EtKFLi9f8HnUpDbc9y8KeaA1dbYeYgUq34ruAJ9P2cZh` | exists (pool already went through `sunset_redeem_all` slot 460,369,625 + `sunset_finalize` slot 460,572,956) |
| sUSD holders | — | **57,868** token accounts |
| USDC price (DefiLlama) | — | $0.9995984819 (ts 1792960181) |

**The pool is in a sunset wind-down.** `sunset_redeem_all` moved 665,076.226483 cUSDO out of
`poolRwaTokenMainVault` back to the OpenEden vault, and `sunset_finalize` moved 707,958.346338 USDC into
`poolUsdcMainVault`. Deposits are closed (`deposit.rs:73 DepositClosed`), and `update_susd_rate.rs:26`,
`collect_fee.rs:72`, `initiate_batch_withdraw.rs:85` all revert **`6036 PoolSunset`** — the wind-down blocks
further rate/fee/batch-deposit operations. The 708,102.87 USDC is now earmarked to redeem the outstanding
617,526.57 raw sUSD (~1.1467 USDC per raw sUSD).

---

## 4. The mint / redeem / NAV path, in exact terms

* **Mint (`deposit`)** — user transfers USDC into `poolUsdcMainVault` and the program mints sUSD to the user's
  Token-2022 ATA; a `DepositProof` PDA (seeds `["deposit_proof", pool, user, nonce_be8]`) records the deposit.
  Mint ratio is a stored/operator-updated ratio (OpenEden ratios in `OpenedenInfo`), **not** derived from pool
  balances, so there is no donation/first-depositor surface. **This instruction now reverts `DepositClosed` (6039).**
* **Redeem (`withdraw`)** — user transfers `amount` **raw** sUSD from their own ATA into `poolSusdVault` and a
  `WithdrawProof` PDA (seeds `["withdraw_proof", pool, user, nonce_be8]`) records `{from, amount, mint, batchId, userUsdcVault}`.
  **`withdraw` moves no USDC.** Verified live: replaying a withdraw for the largest holder moved exactly `-1000`
  raw sUSD from their ATA into `poolSusdVault` and nothing else (slot 461,393,xxx).
* **Payout (`resolve_batch_withdraw`, operator-only)** — reads the batch USDC (`expected_amount`), computes
  `usdc_withdraw_amount = floor(proof.amount * numerator / denominator)` for each `(proof, userUsdcVault)` pair in
  `remaining_accounts`, transfers USDC from `poolUsdcTokenAccountForWithdraw` to each `userUsdcVault`, and closes
  the proof. Confirmed from a real tx (slot 460,050,965): vault `usdcLDuD…` 1,482,371,326 → 0, distributed
  1,068,995,032 + 108,051,683 + 305,324,611 = 1,482,371,326. `userUsdcVault` in the proof equals
  `ATA(proof.from, USDC)` (verified for `pzWrVqaj…`).
* **NAV / share price** — sUSD is a Token-2022 **interest-bearing** mint (`preUpdateAverageRate 806`, rate updated
  by `update_susd_rate`; uiAmount multiplier ≈ 1.1814 today). The redeem exchange rate is the stored
  `withdrawUsdcSusdTokenRatio` (currently 1,482,371,326 / 1,291,803,292 = 1.14752), set by the operator from
  actual USDC redemption.

---

## 5. Live-state assessment of every address / code check

All addresses above were read with `getAccountInfo` / `getTokenAccountBalance` / `getTokenSupply` at slot
**461,393,409**; the raw dumps are in `analysis/` and `ci-out/`.

* `7671j7qp…` (manager) is a **Squads multisig vault** — every admin action in the last 1000 txs was an inner
  instruction of `SQDS4ep65T869zMMBKyuUq6aD6EgTu8psMjkvj52pCf / VaultTransactionExecute`. It is also the
  program's upgrade authority and the sUSD mint/freeze authority, so governance can replace code and mint/freeze.
* `AxnDY6n…` (operator) is a plain system account (hot key) with 0.28 SOL — it is the only signer accepted by
  `initiate/resolve_batch_*`, `collect_fee`.
* The `LAYER4x…` mint DefiLlama lists is the LAYER governance token (supply ~1e9, decimals 9, Metaplex metadata
  name "Solayer"); it is unrelated to the sUSD pool's value.
* `BnANu5Ct…` (DL adapter's second token) is the OpenEden **cUSDO** mint ("Compounding Open Dollar"); the pool's
  cUSDO vaults are now empty (redeemed during sunset).

---

## 6. What an attacker can / cannot do (every path, with the exact revert)

All tests use a **neutral third-party signer** `743QjwzJdZwRibbPAc4ie73JeM7aWyCZtFT3ZVJXuVN8` (a normal sUSD
holder, no role) and real program accounts, via `simulateTransaction(sigVerify=false, replaceRecentBlockhash=true)`.
Reverts are Anchor errors: `2001 ConstraintHasOne`, `2003 ConstraintRaw`, `2006 ConstraintSeeds`,
`2015 ConstraintTokenOwner`.

| Attack | Result |
|---|---|
| `set_manager` / `set_operator` / `set_rate_authority` / `set_fee` / `update_susd_metadata` / `create_susd_offset_pda` / `emergency_transfer_rwa_token` / `sunset_finalize` as attacker | **`2001 ConstraintHasOne`** on `pool` (left = role key, right = attacker) |
| `update_susd_rate` as attacker | **`2001 ConstraintHasOne`** on `pool` |
| `initiate_batch_deposit` / `resolve_batch_deposit` / `initiate_batch_withdraw` / `resolve_batch_withdraw` / `collect_fee` as attacker | **`2001 ConstraintHasOne`** on `pool` |
| **Control:** `set_fee` signed by the real manager | **success** (proves the instruction is functional and the signer identity is the only blocker) |
| **Control:** `update_susd_rate` signed by the real rateAuthority | passes the gate, then **`6036 PoolSunset`** |
| **Control:** `initiate_batch_withdraw` signed by the real operator | passes the gate, then **`6036 PoolSunset`** |
| `update_susd_rate` / `collect_fee` / `initiate_batch_withdraw` signed by the correct role key | **`6036 PoolSunset`** (`The pool is sunset`) — the wind-down also blocks further rate/fee/batch-deposit operations |
| `resolve_batch_withdraw` signed by the real operator | passes the gate, then **`6026 InvalidStatus`** (no active withdraw batch) |
| `deposit` as attacker | **`6039 DepositClosed`** (`deposit.rs:73`) — mint path closed for everyone |
| `deposit` with a victim's USDC token account | **`2015 ConstraintTokenOwner`** |
| `withdraw` as attacker with 0 sUSD | **`1`** (SPL `insufficient funds`) — program escrows first, never pays USDC |
| `withdraw` with a victim's sUSD vault | **`2015 ConstraintTokenOwner`** on `signer_susd_vault` |
| `withdraw` re-using another user's `WithdrawProof` | **`2006 ConstraintSeeds`** (proof PDA = `["withdraw_proof", pool, signer, nonce]`) |
| `claim_with_migrated_deposit_proof` with attacker's own vault | **`2015 ConstraintTokenOwner`** (`user_susd_vault` must be owned by `proof.from`) |
| `claim_with_migrated_deposit_proof` with the proof's vault but attacker signer | **`2003 ConstraintRaw`** |
| `migrate_deposit_proof` as attacker | **`2006 ConstraintSeeds`** |
| `handle_frozen_accounts` as attacker | **`6026 InvalidStatus`** (`handle_frozen_account.rs:215`) — needs an active batch status the attacker cannot set |
| `initialize` as attacker | fails (`system` CPI) — pool already exists |
| `sunset_redeem_all` (attacker and manager) | fails (`system` CPI, RWA already redeemed) |

**Live redeem replay (holder `DgCkhZVteCDbV2KeiaFy4P9meAp8nLaLaSY9DvAkJCRM`):** `withdraw` **succeeds** and moves
exactly `-1000` raw sUSD from the holder's ATA into `poolSusdVault` — **no USDC leaves the pool**. This is the only
unprivileged value-moving effect in the whole program, and it moves the caller's *own* sUSD into a
program-controlled escrow.

**Conclusion:** there is no unprivileged call path that mints sUSD for free, mints sUSD against someone else's
funds, redeems sUSD without escrowing it, re-uses/forges a proof, or redirects the pool's USDC. **E-U = $0.**

### Cost / preconditions for an attacker
* `withdraw` costs ~0.000005 SOL rent + fees per proof and yields only the attacker's own redemption. Spamming
  dust proofs is a nuisance (griefing the operator's batch), not profit.

---

## 7. PoC / simulations

* **Local (this session):** `analysis/battery_local.py`, `battery2.py`, `battery3.py`, `battery4.py`,
  `battery5b.py` — the full gating + user-path matrix, plus `analysis/decode_proofs.py` (real
  `resolve_batch_withdraw` payout decode) and `analysis/final_state.py` (frozen live state + prices).
* **CI (GitHub Actions, `bash /home/heisenberg/CA/ci/ci-run.sh solayer-usd`):** `ci/sim_matrix.py` re-reads live
  state and re-runs the whole matrix on a clean Ubuntu runner with only `python3` (stdlib). Results:
  `ci-out/live_state.json`, `ci-out/sim_matrix.json`, `ci-out/solayer_sim.log`.
  * CI run URL: `<<CI_RUN_URL>>`
  * **sim matrix: `<<TESTS_PASSED>>`/`<<TESTS_TOTAL>>` passed.**

Key numbers: pool USDC `708102871791` (raw); sUSD raw supply `617526573503`; sUSD uiAmount `729545.645829`;
withdraw payout ratio `1482371326/1291803292`; live escrow replay `-1000` sUSD / `+0` USDC.

---

## 8. Verdict, residual / latent risk, blockers

**Verdict — E-U = $0 (confidence HIGH).** The sUSD mint/redeem/NAV surface is correctly access-controlled. The
only unprivileged state-changers are `deposit` (closed) and `withdraw` (escrows the caller's own sUSD only).
Every instruction that can move USDC out of the pool requires the operator signature and is protected by
`has_one = operator`; every instruction that can change roles, fees, the interest rate, the supply offset or the
upgrade authority requires the manager/rateAuthority.

**Residual / latent risk (not attacker-extractable):**
* **Trust in the operator hot key.** `resolve_batch_withdraw` takes `remaining_accounts` as `(proof, userUsdcVault)`
  pairs and pays USDC to whatever `userUsdcVault` the *proof* recorded. The proof's `userUsdcVault` is fixed at
  withdraw time, so a user cannot redirect it — but the operator is a single hot key with the power to choose
  which proofs to settle and in what order. A compromised/rogue operator (or the manager via `emergency_transfer_rwa_token`
  while RWA remains, or the upgrade authority) can abscond with the ~$707.8k. This is **P**, not E-U.
* **Solvency / yield shortfall.** Raw supply 617,526.57 vs pool USDC 708,102.87 (ratio 1.1467) while the
  interest-bearing uiAmount is 729,545.65 (multiplier 1.1814): the accrued interest (uiAmount) slightly exceeds
  the USDC backing. Holders redeeming at the raw ratio get ~1.1467 USDC/raw; the ~1.18 ui-rate is not fully
  backed. This is a holder loss, not an attacker gain.
* **Two unclaimed `MigratedDepositProof`s** (`3U2chkh…` 0.926881 sUSD, `B1L4836…` 2.780645 sUSD) are claimable
  only by their rightful owners (gated by `ConstraintRaw` + `ConstraintTokenOwner`); a residual of ~3.7 sUSD sits
  in the reserve.
* **`sunset_initiate_batch_withdraw`** account layout could not be reconstructed (it is absent from the stale IDL);
  it was not exercised on-chain in the sampled window. It is the operator-gated sunset twin of
  `initiate_batch_withdraw` and its RWA vaults are already empty, so it is not an E-U vector — but it is the one
  instruction whose account list was not fully verified.

**Blockers / what would change the verdict:**
* A new instruction or a code upgrade (the upgrade authority is live) could re-open `deposit` or add an
  unprivileged path — re-run `ci/run.sh` after any `last_deploy_slot` change.
* If `handle_frozen_accounts` were ever reachable with an attacker-chosen batch status, its `susd_mint`/`susdSupplyOffset`
  writes would need re-examination; today it reverts `InvalidStatus` unconditionally for an attacker.
* If a future `deposit` were re-opened, the mint-ratio rounding and first-depositor behaviour would need a fresh pass
  (the ratio is operator-set, so donation manipulation is still unlikely).

---

## 9. Methodology, sources, caveats, files

**Method:** recover the on-chain Anchor IDL (zlib blob in a program account), recover discriminators from the ELF
and real tx logs, decode the `Pool`/`OpenedenInfo`/`WithdrawProof`/`MigratedDepositProof` accounts, enumerate real
instruction account layouts from `getTransaction`, then build and `simulateTransaction` an attacker matrix against
live state. All reads keyless public RPC; all sims `sigVerify:false, replaceRecentBlockhash:true`; nothing signed/broadcast.

**Sources:** on-chain accounts; the on-chain IDL (`analysis/idl.json`); ELF strings (`analysis/solayer_strings.txt`);
Solayer docs (solayer.org/product/susd, docs.solayer.org/susd); Solayer's public client
(`github.com/solayer-labs/solayer-cli`, `susd/actions/{deposit,withdraw}.ts`); DefiLlama prices.

**Caveats:** single snapshot (slot 461,393,409); prices drift; the on-chain IDL is stale (missing the `sunset_*`
instructions and `SunsetInfo`), so `sunset_initiate_batch_withdraw`'s account list is inferred; `Status` enum
values in the deployed code differ from the stale IDL (observed `batchDepositStatus = 2`); one instruction
(`sunset_redeem_all`) cannot be re-run because its RWA vault is empty.

### Files index
| Path | Purpose |
|---|---|
| `analysis/solrpc.py` | keyless RPC helper (kept) |
| `analysis/dl-adapter.js` | DefiLlama adapter (kept) |
| `analysis/idl.json` | recovered on-chain Anchor IDL |
| `analysis/solayer_susd.so` / `solayer_strings.txt` | program ELF + strings |
| `analysis/recon1*.py`, `recon2.py`, `recon3.py`, `recon4.py`, `recon5.py` | recon (accounts, instruction scan, sunset/migrate txs) |
| `analysis/pool_decoded.json`, `final_state.json` | decoded live state |
| `analysis/discriminators.json`, `disc.py` | Anchor discriminators |
| `analysis/pda.py`, `solsim.py` | PDA derivation + tx builder/simulator |
| `analysis/battery_local.py`, `battery2.py`, `battery3.py`, `battery4.py`, `battery5b.py` | local sim batteries |
| `analysis/battery*.json` | raw sim results |
| `ci/sim_matrix.py`, `ci/run.sh` | CI heavy job |
| `ci-out/live_state.json`, `ci-out/sim_matrix.json` | CI outputs |

---

## STANDING CI CLAUSE (verbatim)

All CPU-intensive / storage-heavy work (Foundry compile+tests, fork simulations, Go/Rust/wasm builds, large enumerations/scans, data crunching) MUST run on GitHub Actions via `bash /home/heisenberg/CA/ci/ci-run.sh <folder>` (repo `artsbykriss/ca-zombie-ci`, auth = `CHRIS_GITHUB_API_KEY` → account `artsbykriss`; `GITHUB_API_KEY`/kingmariano is billing-locked and returns "Bad credentials" — do not use it). Local work is limited to light RPC reads, `cast call`, small scripts and web fetches; do not run long local anvil/fuzz/build jobs. Folder layout for CI: `poc/` (Foundry project), `ci/run.sh` (heavy job), `ci-out/` (result files → artifacts). Never commit secrets, `.env` contents, private keys, API keys or keyed RPC URLs into the folder — the CI repo is public. Report which parts ran in CI (with the run URL) vs locally.

*Local (this session): all light RPC reads, decoding, and the initial sim batteries.
CI (`ci-run.sh solayer-usd`): the full `ci/sim_matrix.py` matrix + live-state snapshot on a clean runner (URL above).*
