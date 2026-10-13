# 01 (01 Exchange / 01.xyz) — Solana wind-down vault: live extractability audit

**Date:** 2026-10-14 · **Chain:** Solana mainnet-beta · **Finding ID:** `01` (L2 watchlist Phase-2, triage row #12)
**Status:** read-only; chain-native simulations only (`simulateTransaction`, `sigVerify=false`, `replaceRecentBlockhash=true`); **no mainnet transactions sent or signed**; no secrets in this folder.

---

## 1. TL;DR

| Target | Live custody (slot 456,617,346) | E-U (fresh attacker) | Why | Latent risk |
|---|---|---|---|---|
| 01 wind-down USDC vault PDA `HjHSNe8hhvZ8hKCRrhKg1DGiGPd9NYQbUjT1SQRDo4kZ` + program `Zo1ggzTUKMY5bYnDvT5mtVeZxzf2FaLTbKkmvGUhUQk` | **111,615.829133 USDC ≈ $111,615.83** (+ ~$23 dust tokens; one Token-2022 holding is a dead mint) | **$0.00** | `redeem_usdc` is bound to the caller's own margin PDA (`ConstraintSeeds` = `[signer, state, "marginv1"]`), pays only to a token account owned by the signer (`ConstraintTokenOwner`), and each margin's claim is single-spend (replay pays 0). All admin paths are `admin`-gated (`ConstraintAddress`); the zamm path rejects forged keys (`InvalidZamm`). | **P:** zo program is upgradeable (authority `DtCyZ…` = off-curve multisig PDA); staker program `6N71ta5g…` is upgradeable by the on-curve admin hot key `DH7N1sJQ…`. **H-O:** the vault is (first-come-first-served) user claim money — see §8 shortfall caveat. |

**Total live extractable now by an external unprivileged attacker: $0.00** (confidence **high** — gate proven by 15+ chain-native simulations; see §7).
**Live value recoverable by the rightful users themselves (H-O): ≈ $111.6K** — outstanding wind-down claims, of which **$145,117.24 has been measured redeemable** across 373 margins (§8).

---

## 2. What "01" is, and what the target actually is

The triage row priced the vault address `HjHSNe8hhvZ8hKCRrhKg1DGiGPd9NYQbUjT1SQRDo4kZ` from the DefiLlama adapter `01.js` (`sumTokensExport({ owner })`). Live investigation shows:

- **`HjHSNe8hhvZ8hKCRrhKg1DGiGPd9NYQbUjT1SQRDo4kZ` is NOT a wallet — it is off-curve: a program-derived address (PDA)**, owned by the System Program with 0 data, that holds 34 SPL token accounts + 1 Token-2022 account. Its USDC ATA `3er2PEWxhpuRkbVwE3ks2nynr5EtcSjCs5fdDJiKQocp` holds the funds.
- It is the **USDC vault of "01" (01 Exchange / 01.xyz, the Solana perp DEX of the N1 ecosystem)**. The program is **`Zo1ggzTUKMY5bYnDvT5mtVeZxzf2FaLTbKkmvGUhUQk`** ("01 Program"; source paths inside the ELF: `programs/zo/src/…`).
- The protocol is **mid-wind-down but live**: the wind-down build was deployed 2026-04 (programData `52xHuqib…` last deploy slot 413,063,530), the team (admin `DH7N1sJQxyLJqc79fk67U32mymejUiRVH8SqayTuRtG7`) ran `InitWinddownBook` → 25×`SettleCollateral` → `SetManualRatesAndOverrides` → `FinalizeWinddown` on 2026-04-14, and **users have been calling `RedeemUsdc` ever since** (most recent 2026-10-10; ~$65.1K redeemed to date, incl. one $59,804.42 unstake payout on 2026-05-24).

So the finding is not "abandoned contract with free money" — it is a **live, gated wind-down payout machine**. The audit question is whether an outsider can take *someone else's* claim or the vault itself.

## 3. Architecture (all facts re-verified on-chain)

| Item | Address / value | Evidence |
|---|---|---|
| zo program (upgradeable) | `Zo1ggzTUKMY5bYnDvT5mtVeZxzf2FaLTbKkmvGUhUQk`; programData `52xHuqibnMfqrPeN2zpg1ygKkLpJ3HHxU1QzX97VB4AN`; **upgrade authority `DtCyZQSP9AjdasXJPs5m5Q8dovo73UJvUG1ieosofDwX` (off-curve → multisig PDA)** | `getAccountInfo` |
| USDC vault PDA | `HjHSNe8hhvZ8hKCRrhKg1DGiGPd9NYQbUjT1SQRDo4kZ` — System-owned, 0 data, **off-curve**, 1,100,649 lamports | curve test + `getAccountInfo` |
| Vault USDC ATA | `3er2PEWxhpuRkbVwE3ks2nynr5EtcSjCs5fdDJiKQocp` — **111,615.829133 USDC** | `getTokenAccountBalance` @ slot 456,617,346 |
| Global state | `71yykwxq1zQqy99PgRsgZJXi2HHK2UDx9G4va7pH6qRv` (36,322 B; hardcoded in `programs/zo/src/config.rs`) | ELF strings + tx layout |
| Admin hot key | `DH7N1sJQxyLJqc79fk67U32mymejUiRVH8SqayTuRtG7` (on-curve, 15.94 SOL) | `getAccountInfo` + admin-signed txs |
| Staker/"zamm" program | `6N71ta5gVjN65hSTDnK4fy4B1YWGgMLyeSu8WEr8Uh2J` (upgradeable; authority = admin hot key) | `getAccountInfo` |
| Zamm pool margins | `CX2tWRJC9z3L6zwnBTAk2keWVzUXgju6LFu9wzso9Zfn`, `G6ke5Mr7BuTZYfcsc2K7mJPj8vtiQ418WSsk8DxLkRvW` (owner `Fe5bofsZuBi8fPez2aKzBa9uTc2iRV4pPU2D1SHMfXDt`) | tx logs + on-chain reads |
| Margin accounts | **10,009** (dataSize 793, disc `98118ec350c4a130`); layout = disc(8)+nonce(1)+authority(32)+collateral[25]×i80f48(400)+control(32)+pad(320) | `getProgramAccounts` |
| Control accounts | 4,490 B = disc(8)+authority(32)+open_orders_agg[50]×89 | matches 2022 public ABI (`01protocol/zo-abi`) |

**Instruction set of the deployed (wind-down) build** (extracted from the ELF + verified discriminators = `sha256("global:<name>")[:8]`):
`redeem_usdc 658ef6b8c6385cae`, `finalize_winddown cbc28cbd27150e21`, `init_winddown_book eaefd1a003ddb538`, `set_manual_rates_and_overrides c2fc9bfe1d8a3348`, `settle_collateral 2c08bb9510edd963`, `close_margin d1b6de1372b280e9`, `consume_events dd91b1341f2f3fc9`, `cache_oracle f1dc8357f592c983`, `create_margin 139b4868a4c00344`, `force_cancel_all_perp_orders e4b279d4e6e8eb20`, `update_heimdall c555f804f4492fab`, `update_oracle 7029d112f8e2fcbc`, `zamm_transfer 5172fb20f0e71608`, `init_state 7cd5498850258d36`.

## 4. The mechanism, exactly

`redeem_usdc` (data = 8-byte discriminator only, **no amount argument**) takes 10 accounts:

```
[0] state 71yykwxq… (writable)     [5] control PDA (writable)
[1] vault PDA HjHS… (ro)           [6] destination USDC token account (writable)
[2] 6kSuaA8F… (writable)           [7] vault USDC ATA 3er2PEW… (writable)
[3] authority (signer, writable)   [8] Dwi4TnaY… (ro)
[4] margin PDA (writable)          [9] SPL Token program
```

The program signs for the vault PDA (CPI transfer authority = `HjHS…`, see inner instruction of every redeem), pays the **margin's own remaining claim** (event `RedeemUsdcLog {authority, margin, amount}`, disc `437a2f4a0f060e20`), and zeroes the claim. Gates proven live by simulation (§7):

1. **`margin` must be the PDA `[signer, state, "marginv1"]`** → any cross-user attempt fails `ConstraintSeeds` (2006) on `margin`.
2. **destination must be a token account owned by the signer** → foreign ATA fails `ConstraintTokenOwner` (2015).
3. **claim is single-spend**: replaying the last real redeem tx → zo instruction *succeeds* with amount **0** (claim consumed); the tx only fails later at an unrelated `L2TEx` receipt program (`Result (Failed): Some(0) >= Some(…`).
4. Zamm-pool margins cannot be redeemed directly at all: `InvalidZamm` (6077) even with a forged "zamm key" remaining account.

Admin instructions are one-shot and `admin`-gated: fresh-signer replays of `finalize_winddown`, `set_manual_rates_and_overrides`, `settle_collateral` all fail `ConstraintAddress` (2012) on `admin`; the original admin replays fail `RedeemAlreadyEnabled` (6099) — the wind-down cannot be re-run. `init_winddown_book` fails at the System program (account already exists).

## 5. What an attacker can / cannot do (exact paths)

| Path | Preconditions | Result |
|---|---|---|
| `redeem_usdc` on someone else's margin | attacker key | **Reverts** `ConstraintSeeds` — margin PDA is derived from the caller. |
| `redeem_usdc` to an attacker ATA while signing with a victim's margin | victim key | **Reverts** `ConstraintTokenOwner`. |
| Re-redeem own margin (double-dip) | own key | Succeeds but pays **0** (claim zeroed). |
| Redeem a zamm pool margin | zamm key | **Reverts** `InvalidZamm`. |
| `set_manual_rates_and_overrides` to inflate own claim | admin key | **Reverts** `ConstraintAddress`; also one-shot. |
| `finalize_winddown` / `settle_collateral` re-run | admin key | **Reverts** (`ConstraintAddress` / `RedeemAlreadyEnabled`). |
| Unstake another user's stake in `6N71ta5g…` | attacker key | **Reverts** `ConstraintSeeds` on `staker_info`. |
| Upgrade `Zo1ggz…` and drain | upgrade-authority multisig | **P** — not available to an unprivileged attacker; authority is an off-curve PDA (multisig vault), account does not exist as data. |
| Create a fresh margin + redeem | attacker key | A fresh margin has zero claim → pays $0. |

Cost side note: the attacker path (if it existed) would have cost ~5,000 lamports base fee + rent for the ATA (~2.04M lamports, refundable) — irrelevant since every path reverts.

## 6. Live-state assessment (re-verified)

- Vault USDC: **111,615.829133** (`3er2PEW…`) at finalized slot **456,617,346**; vault PDA lamports 1,100,649.
- Other vault-PDA token accounts: 34 SPL (dust; Jupiter-priced tail ≈ $23 total, largest `8yeSLFG6…` ≈ $23) + 1 Token-2022 account holding 384,000 units of mint `7atgF8KQo4wJrD5ATGX7t1V2zVvykPJbBfNeVf1icFv1` — **that mint account does not exist** (closed/burned) → the holding is dead value.
- Margin accounts: 10,009; measured redeemable claims across the top 400 margins (373 with claims) = **$145,117.24** (§8).
- Program upgrade authority: off-curve PDA `DtCyZ…` (no account data) — consistent with a multisig vault; **the zo program and the staker program are both upgradeable**.
- Wind-down redemption history: first redeem 2026-04-15 (vault $176,728.62), ~$65.1K redeemed since (largest single $59,804.42 on 2026-05-24 via Unstake→ZammTransfer→RedeemUsdc), current $111,615.83.

## 7. Proof — chain-native simulations (read-only)

All tests use `simulateTransaction` with `sigVerify:false`, `replaceRecentBlockhash:true` — **nothing was signed or sent**. Scripts and raw outputs in `analysis/`; CI re-run in `ci-out/` (§10).

| Test | Call | Result |
|---|---|---|
| T-OWN | funded margin owner redeems own margin | **SUCCESS**, `RedeemUsdcLog` amount = 26,536,453,286 raw ($26,536.45); vault ATA −26,536.453286 |
| T-CONTROL | 531euoNt redeems own (already consumed) | SUCCESS, amount = **0** |
| T1 replay | exact replay of last real redeem tx | zo instruction **SUCCESS amount 0**; tx fails later at L2TEx receipt check |
| T-IMP-A/B/C | 531euoNt signs, victim margin/control, dest own/own/victim ATA | **ConstraintSeeds (2006) on `margin`** |
| T-FRESH / T-FRESH-2 | fresh random signer + victim margin | **ConstraintSeeds (2006)** |
| T-DEST | own margin → foreign ATA | **ConstraintTokenOwner (2015)** |
| T5 zamm | zamm margin + forged zamm key | **InvalidZamm (6077)** |
| Admin replays | finalize/set-rates/settle with fresh signer | **ConstraintAddress (2012) on `admin`** |
| Unstake replay | staker program with fresh signer | **ConstraintSeeds (2006) on `staker_info`** |

Sources: `analysis/sim_redeem_final.json`, `sim_redeem4.json`, `sim_admin_replay.json`, `sim_zamm_unstake.json`, `sim_zamm_forged.json`, `sim_redeem3.json`, `sim_results.json`; scripts `analysis/simulate_redeem*.py`, `sim_admin_replay.py`, `sim_zamm_unstake.py`.

## 8. Outstanding claims (H-O) and a shortfall finding (medium confidence)

By simulating `redeem_usdc` for the largest margins (same read-only method), the **currently redeemable claims** are:

| Slice | Margins | Sum |
|---|---|---|
| Top 43 (rank 1–45 with claims) | 43 | **$108,830.13** |
| Rank 46–145 | 93 | **$22,524.93** |
| Rank 146–400 | 243 | **$13,762.19** |
| **Measured total (top 400 margins)** | **373** | **$145,117.24** |
| Current vault balance | — | **$111,615.83** |
| Wind-down pool (Apr-14-2026, after swaps) | — | **$176,728.62** (pre-existing $44,845.17 + $131,883.45 swapped in by 25 `SettleCollateral` txs) |
| Redeemed since (44 redeems, largest $59,804.42) | — | **$65,112.79** |

- Largest single claims: $26,536.45; $15,912.97; $15,515.52; $10,147.77; $8,701.05; $8,613.16; $3,946.22; …
- **Payouts are full-nominal and first-come-first-served, not pro-rata.** A single simulated tx redeemed the top 3 margins and paid each its exact standalone amount ($26,536.45 + $15,912.97 + $15,515.52 = $57,964.94; vault ATA 111,615.83 → 53,650.89) — `analysis/sim_multi_redeem.json`.
- **Consequence:** the measured claims of 373 margins already exceed the whole remaining pool by **≈ $33.5K** (and ~1,600 more margins carry non-trivial collateral values that are unmeasured). If these claimants are ordinary users, **the last ~25% of claims cannot be paid** — a claimant-side (H-O) shortfall, not an E-U path.
- **Why medium confidence:** some large claimants may be protocol-controlled (e.g., authority `zoKyPQR8n7…` — $15,515.52 — has a "zo" vanity prefix; protocol-owned margins are indistinguishable on-chain and would absorb part of the gap). The two zamm pool margins (`CX2tWRJC…`, `G6ke5Mr7…`) hold large internal balances but **cannot** be redeemed through the public path (`InvalidZamm`) — they flow through the staker program `6N71ta5g…` only.

## 9. Verdict

- **E-U = $0.00, confidence high.** Every value-moving path reachable by a fresh unprivileged attacker is either PDA-seeds-bound to the caller (redeem/close/unstake), admin-gated, zamm-key-gated, or single-spend. Proven by chain-native simulation, not by reading docs.
- **H-O ≈ $111.6K** — the vault is the users' (and possibly protocol's) wind-down claim pool; rightful claimants can still redeem (`redeem_usdc` works today, e.g. $350.67 paid 2026-10-10). **Secondary finding (medium confidence):** measured redeemable claims across the top 373 margins total **$145,117.24** vs a pool of **$111,615.83**; payouts are full-nominal, first-come-first-served (proven by a 3-redeem single-tx simulation paying $57,964.94 exactly), so at least ~$33.5K of claims appear unpayable today (some large claimants may be protocol-controlled — see §8).
- **P:** the zo program can be upgraded by the off-curve multisig authority `DtCyZ…`; the staker program `6N71ta5g…` can be upgraded by the on-curve admin hot key `DH7N1sJQ…` (15.94 SOL). A malicious/compromised admin or multisig could drain the vault — that is the principal residual risk and is outside the fresh-attacker standard.
- **S:** the Token-2022 384,000-unit holding (`7atgF8KQ…`) is bricked (mint account does not exist). Any rounding dust left after all claims is likely stuck (no sweep instruction observed in the wind-down build).

## 10. CI / reproducibility

- Helper: `bash /home/heisenberg/CA/ci/ci-run.sh 01` → branch `01` of `artsbykriss/ca-zombie-ci`, workflow `poc.yml`, runs `01/ci/run.sh` → `01/ci/verify.py`.
- The CI job re-derives: slot + vault balance, margin count, upgrade authority, the full gate-test matrix (T1–T7), and a top-25 claim measurement; artifacts in `ci-out/` (`01-verify.json`, `01-verify.txt`, `01-verify.log`).
- **CI runs:**
  - https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38482919463 (slot 456,619,117; vault $111,615.83; T1 own-redeem SUCCESS $26,536.45; T2/T4 ConstraintSeeds; T3 ConstraintTokenOwner; T5 InvalidZamm; T6/T7 ConstraintAddress; top-25 claims $98,169.93)
  - https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38484214593 (final sync; slot 456,622,550; identical results; artifact `result-01`) — downloaded to `ci-artifacts/result-01/ci-out/`.

## 11. Methodology, sources, caveats, files

**Method:** live RPC reads on public endpoints (no keys); PDA/curve tests in pure Python; program ELF pulled from programData and string-mined for instruction names + hardcoded pubkeys; Anchor discriminators recomputed and matched to on-chain instruction data; gate testing by `simulateTransaction` replay/mutation (never sent); claim quantification by simulating `redeem_usdc` per margin with a funded simulation-only payer; historical flow analysis over the vault ATA's 6,000-signature history.

**Sources:** on-chain (all addresses above); 2022 public ABI `github.com/01protocol/zo-abi` (+ `zo-client`, `zo-sdk-py`) for account layouts; docs.01.xyz / `@n1xyz/nord-ts` for protocol identity; triage row `l2-triage-c` #12 and `zombie_hunt/FINDINGS.md` row "01".

**Caveats:** (1) simulation payer `DH7N1sJQ…` is only used as a fee-payer in *simulations*; nothing was signed. (2) Claim sums use `simulateTransaction` against current state, one margin at a time (no sequential state forking) — they are gross claims, not a solvency proof; see §8. (3) The two zamm margins' USD claims are unknown (blocked path). (4) The deployed program is a different build than the 2022 public source; instruction *semantics* were proven empirically, not read from source.

**Files index:** `analysis/` (raw JSON dumps, scripts, ELF, strings), `ci/` (`run.sh`, `verify.py`), `ci-out/` (CI artifacts), `ci-log.txt`, `summary.json`.
