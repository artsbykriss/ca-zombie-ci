# analysis/ index — 01 (01 Exchange) Solana wind-down

All reads are mainnet reads on public RPC; all "sim_*" files are `simulateTransaction` results
(`sigVerify=false`, `replaceRecentBlockhash=true`) — nothing was signed or sent.

## Key evidence (used in README)
| File | What it is |
|---|---|
| `state_dump_raw.json` | vault PDA + 34 SPL token accounts + 1 Token-2022 account + recent signatures |
| `recent_txs.json`, `program_sig_sample.json` | recent program transactions; instruction census source |
| `accounts_raw.json`, `state_accounts.json` | program/config/vault account dumps |
| `redeem_layout.json` | RedeemUsdc account list + data (discriminator `658ef6b8c6385cae`) |
| `01_program.elf`, `01_program_strings.txt` | deployed zo program ELF (from programData `52xHuqib…`) + strings (instruction names, error names, embedded pubkeys) |
| `L2TEx.elf` | the L2TEx helper program (invoked after redeems; not required by zo) |
| `all_margins.json` | all 10,009 Margin accounts (dataSlice 441 B: nonce/authority/collateral) |
| `vault_ata_history.json` | vault USDC ATA flow history sample (44 RedeemUsdc rows etc.) |
| `live_snapshot_final.json` | final state snapshot (slot 456,617,346) |
| `sim_redeem_final.json` | **gate proof**: own-redeem SUCCESS $26,536.45; impersonation/fresh-signer ConstraintSeeds; foreign dest ConstraintTokenOwner |
| `sim_redeem4.json` | zamm-margin direct redeem InvalidZamm; dest-constraint test |
| `sim_admin_replay.json` | admin instructions with fresh signer → ConstraintAddress; admin replays → RedeemAlreadyEnabled |
| `sim_zamm_unstake.json` | staker program Unstake with fresh signer → ConstraintSeeds |
| `sim_zamm_forged.json` | zamm margin + forged zamm key → InvalidZamm |
| `sim_multi_redeem.json` | **3 redeems in one tx paid exact standalone amounts ($57,964.94)** → full-nominal, first-come-first-served (no pro-rata) |
| `claims_measured_top45.json` | measured claims rank 1–45: **$108,830.13** |
| `claims_measured_tail100.json` | ranks 46–145: **$22,524.93** |
| `claims_measured_146_400.json` | ranks 146–400: **$13,762.19** |
| `ci-out/`, `ci-artifacts/` | CI verification artifacts (see README §10) |

## Superseded / exploratory (kept for negative results)
| File | Note |
|---|---|
| `sim_results.json`, `sim_redeem2.json`, `sim_redeem3.json` | early matrix attempts that failed at the fee/`ConstraintMut`/ATA stage due to a `solders` AccountMeta argument-order bug and missing ATAs — superseded by `sim_redeem_final.json`; no conclusions drawn from them |
| `claim*` intermediate JSONs (`claims_measured.json`) | first measurement slice |
| `decode_pubkeys.py` output (stdout only) | greedy base58 splitting produced some mis-aligned keys; only known-address matches were used |

## Scripts
`dump_state.py`, `dump_accounts.py`, `dump_state_accts.py`, `fetch_txs.py`, `instruction_census.py`,
`check_upgrade_auth.py`, `download_elf.py`, `fetch_idl.py` (no on-chain Anchor IDL),
`decode_margins.py`, `enumerate_margins.py`, `measure_claims.py`, `measure_claims2.py`, `measure_tail.py`,
`measure_tail2.py`, `simulate_redeem.py`, `simulate_redeem2.py`, `simulate_redeem3.py`,
`simulate_redeem4.py`, `simulate_redeem_final.py`, `sim_admin_replay.py`, `sim_zamm_unstake.py`,
`sim_multi_redeem.py`, `final_checks.py`, `trace_vault.py`, `pull_instr_samples.py`.

`solrpc.sh` is a convenience wrapper that reads `$ALCHEMY_API_KEY` from the environment only (no key value is stored in any file).
