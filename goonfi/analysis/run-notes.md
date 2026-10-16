# Run notes — GoonFi Z3-H2 (repro steps, read-only)

All commands are read-only. Local runs used keyless endpoints
(`SOLANA_RPC_URL=https://solana-rpc.publicnode.com`; `getProgramAccounts` needs
`https://api.mainnet-beta.solana.com` — used only in `sweep_markets.py`).

## 1. Recon / artifacts
```
python3 analysis/fetch_core.py            # program, programdata, pool, vaults, oracle accounts
python3 analysis/pd_parse.py progdata_v2-account.bin   # extract ELF (sha256 a24aa13a…)
python3 analysis/fetch_upgrade_history.py # 41 v2 upgrades + 48 v1 upgrades (upgrade-history-*.json)
python3 analysis/enumerate_accounts.py    # 36 x 2048B markets + 719kB global state
python3 analysis/fetch_market.py          # GMCJ market/vault/oracle decode
python3 analysis/sweep_markets.py         # all markets + all oracles (market-sweep.json)
python3 analysis/tvl_sweep.py             # USD TVL per market (tvl-sweep.json) — $5,176,428 total
python3 analysis/oracle_updates.py        # who updates oracles; keeper txs are v1 transactions
python3 analysis/bpf_disasm.py            # 30-instruction disassembly of the 512B dijkbk program
python3 analysis/dump_fixtures.py         # live-state fixtures for the LiteSVM PoC
```

## 2. Incident forensics
- Tx `5A1YuYHf…MGV2` (slot 409,430,505): GoonFi paid 1,539.265798532 WSOL for 4,096 USDC;
  BisonFi paid 127,286.030966 USDC for the same WSOL. Decoded in
  `zombie-hunt-iii/work/S4-solana-move.md` + re-verified here from raw tx data.
- Historical prices (DefiLlama): SOL $82.6694, TRUMP $2.9768, ETH $1,999.02 (2026-03-28).
- Implied GoonFi quote: `P/denom = 2.661007` (solve `P = in_B × 1e9 / out_A`).

## 3. LiteSVM PoC (35 labelled checks)
```
cd poc && CARGO_TARGET_DIR=/tmp/goonfi-target cargo run --release
```
Outputs the T0–T10 matrix (see README §3). Key results: incident replay pays
38.799742877 WSOL (fair $105.57), non-pool oracles rejected `Custom(32)`,
stale `Custom(21)`, bad price `Custom(9)/(36)`, oversized `Custom(36)`,
oracle write from non-keeper `MissingRequiredSignature`.

## 4. Mainnet read-only simulation (supplementary)
`analysis/sim_oracle_write.py`, `sim_replay_real.py` — used to look for the oracle
write mechanism; note the RPC's `accounts` return reflected live (pre-)state, so the
decisive write-gate test was done in LiteSVM with the real ELF instead.

## 5. CI
`bash /home/heisenberg/CA/ci/ci-run.sh goonfi` → GitHub Actions
(artsbykriss/ca-zombie-ci). Run URL + logs: `ci-log.txt`, `ci-out/poc-output.txt`.
