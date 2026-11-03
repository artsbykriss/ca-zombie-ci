# ca2-supplychain — combined CI harness for CA2 H-3 + H-4

This folder is the **CI unit** for the two supply-chain findings. The deliverables themselves are:

- [`../btcpay/README.md`](../btcpay/README.md) — CA2 H-3, BTCPay Server ≤ 2.4.1
- [`../fearless-wallet/README.md`](../fearless-wallet/README.md) — CA2 H-4, Fearless Wallet extension 3.0.1/3.0.3–3.0.5

## What runs

`ci/run.sh` executes three read-only jobs and writes results to `ci-out/`:

| Script | What it verifies |
|---|---|
| `ci/btcpay_trace.py` | Full Esplora trace of the two vendor-named BTCPay collection addresses (BTC on Blockstream, LTC on LitecoinSpace): stats, first/last activity, gross received, current balance, USD at spot. |
| `ci/polkadot_verify.py` | For each published Fearless Wallet victim transfer: rebuild the block, recompute the extrinsic hash, find it, decode the signer and check it matches the reported victim; decode the amount where the call carries one; read current DOT and DED balances. |
| `ci/store_check.py` | Download and unzip the current Chrome Web Store CRX (version, sourceCommit, `tonscanner`/`whitelist?address` hits); fetch the remote `ton` switch file; fetch the 3.0.5 source; resolve `tonscanner.org` via DoH and test TCP 443; check the Firefox AMO listing. |

`ci/summarize.py` writes `ci-out/COMBINED.md`.

## Latest run

- **Run:** <https://github.com/artsbykriss/ca-zombie-ci/actions/runs/41644519322> — **success**
- **Log:** `ci-log.txt`
- **Key results:** BTCPay named addresses: **$1,802,475.75 gross received**, **$193,825.36 current** (2026-11-03 13:28 UTC); Fearless: **10/10** hashes found, **10/10** signers match, **6/10** amounts decoded; current CRX **4.2.4** with **0** `tonscanner` hits; remote switch **off**; `tonscanner.org` **resolves** (31.129.104.153) but **TCP 443 times out**.

## Safety

Public data only. No API keys, no `.env`, no private keys, no signed transactions, no BTCPay/LND instance access. The folder is synced to a public CI repository; it contains only public addresses, public URLs and read-only scripts.
