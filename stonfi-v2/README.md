# STON.fi V2 (TON) — P3-STONFI-V2

Read-only audit; no keys, no signing, no mainnet transactions. Full detail in **[notes.md](notes.md)**;
machine summary in **[summary.json](summary.json)**; PoC in **[poc/](poc/)**.

**Verdict: no unprivileged extraction path. E-U = $0.00 (high confidence).**

| Target | Live TVL | E-U | Why closed |
|---|---:|---:|---|
| v2.2 ConstantProduct (23 routers, 29,215 pools) | $13,030,543.98 | $0 | Deployed bytecode is byte-identical to `dex-core-v2@af0a955`; `pay_to` requires sender == canonical pool (`router/msgs/pool.fc:28`), pools accept only router/protocol-fee messages (`pool.fc:28`), math floors output/ceil fees, 27/27 sandbox tests pass |
| v2.1 ConstantProduct (18 routers, 965 pools) | $445,679.91 | $0 | Same architecture; deployed code hash ≠ public HEAD (source unpublished), so bytecode identity unproven |
| v2.2 non-CP (WSS/SS/WCP, 10 pools) | $871,477.93 | $0 | Same architecture; deployed code hash ≠ public HEAD |
| v1 (prior C2-38, out of scope) | $9,749,006.80 | — | Already closed |

**Key correction:** `api.ston.fi/v1/pools?dex_v2=true` mixes v1 and v2. The largest router
`EQB3ncy…TiUt` is **v1.0** ($9.75M, 18,826 pools). Actual v2 TVL is **$14,347,701.81**.

**Strongest evidence**
- Live PUBLIB library hashes == local build: router `848d1da9…f5cc`, pool `a9338ecd…81b4`,
  lp_account `c95a2ed2…bc79`, lp_wallet `c0083644…c3e8`, vault `e874ac89…a613`.
- Sandbox on the deployed bytecode: forged `pay_to` → exit `82`, no transfer; `pay_to` from the
  canonical pool → exit `0`, exact transfer; direct `swap`/`transfer_notification` to a pool →
  `wrong_op`, reserves unchanged.
- CP swap on live reserves reproduces the floored formula exactly (`735,553,921,026`).

**Blockers:** v2.1 and non-CP source not published; PUBLIB code cells must be resolved via the
embedded 256-bit library hash (done); API has no block pin.
