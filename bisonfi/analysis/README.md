# BisonFi Z3-C4 — analysis artifacts index

All reads are read-only public-RPC; no secrets anywhere (keyed endpoints never written to disk).

| File | What it is |
|---|---|
| `exploit-tx.json` / `exploit-analysis.txt` | Full decode of the 2026-03-28 cross-program tx `5A1YuYHf…MGV2` (slot 409,430,505): accounts, inner CPIs, token deltas, logs |
| `pool-states-2048.json` | Raw dump of all 29 POOLSTAT accounts (getProgramAccounts, dataSize 2048) |
| `pool-states-decoded.json` / `pool_map.py` | Decoded map: name, authority, WSOL/quote vaults, mints, cached balances, last/prev update slot, ns timestamp |
| `decode_poolstat.py` | POOLSTAT layout decoder (offsets documented in README §1) |
| `history-old-authority.json` | All 14,778 txs of pre-handover authority `UfSM2ZFR…` (378M→457M) |
| `history-upgrade-authority.json` / `authority-txs.json` | All 156 txs of the current authority `6dDjBZdp…` + full tx bodies |
| `oldauth-loader-ops.jsonl` | Every loader op (Upgrade/ExtendProgram/SetAuthority*) found in the old authority's history — the fleet/BisonFi upgrade timeline (scan in progress, oldest-first) |
| `parse_authority_txs.py` / `scan_oldauth.py` | The scanners that produced the above |
| `elf.py`, `find_refs.py`, `log_sites.py`, `scan_calls.py` | Hand-rolled SBF ELF forensics: dynamic-symbol/PH parsing, lddw rodata-reference search, sol_log site→string mapping, syscall-hash census |
| `elf-strings.txt` | All printable strings in the live ELF (source paths, log strings) |
| `oracle-program-raw.elf`, `oracle_probe.py` | The 512-byte publisher program `dijkbk…` (24-CU write path) + its ProgramData |
| `instruction-clusters.json` | Live instruction census of the program (discriminators, account shapes, data) |
| `successful-swaps.json`, `direct-swap-samples.json` | Real successful swap txs used for byte-exact replay (T8) |
| `recent-bisonfi-swaps.json` | Jupiter-routed swaps (current interface evidence) |
| `final_numbers.py` | Fresh headline numbers (vault balances, oracle price, authority balances, fleet totals) |
| `rpc.py`, `rpc_alchemy.py`, `dune.py` | RPC helpers (keyless default; local-only keyed helpers that never persist URLs) |

## Upgrade timeline (BisonFi ProgramData `42snJ7ip…`)

Authority eras: **launch authority** (slot ~378.13M deploy) → **`UfSM2ZFR…`** (all pre-2026-04-04 upgrades) → **`6dDjBZdp…`** (SetAuthorityChecked at slot 423,831,228, 2026-04-04; ≥15 upgrades since; last upgrade 456,982,351 = 2026-10-13).

Pre-incident upgrades found in the scanned window (oldest→newest, buffer accounts in `oldauth-loader-ops.jsonl`): 378,372,044 · 378,603,174 · 382,496,099 · 390,007,231 · 394,851,336 · 396,781,613 · 397,651,303 · 397,875,243 · 399,410,452 · 399,419,934 · … (scan continues to 424.1M; exploit slot = 409,430,505).

Post-handover upgrades (current authority; from `authority-txs.json`): 423,834,023 · 423,886,535 · 425,128,780 · 425,791,237 · 426,880,430 · 428,618,055 · 429,084,761 · 429,099,739 · 429,723,582 · 431,242,336 · 433,340,392 · 433,544,678 · 433,545,970 · 436,189,357 · 437,254,912 · 438,843,898 · 439,069,617 · 439,101,627 · 440,136,481 · 440,551,753 · 443,561,169 · 445,986,300 · 447,077,053 · 447,341,702 · 449,101,126 · 451,697,277 · 451,758,256 · 452,076,797 · 453,690,524 · 454,324,679 · 454,617,760 · 456,170,356 · 456,982,351.

**Patch-level conclusion:** the program has been continuously upgraded (authority-gated) across the whole period; the March-era instruction surface (9 accounts, no vote account) differs from the current one (10/12 accounts), and the current build enforces freshness/oracle/restart controls in code. A config-only change cannot produce those differences → **code-level patch history**.
