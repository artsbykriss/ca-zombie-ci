# ZH4-PASS4 · Affluent / Factorial Finance (TON) — unbacked-mint deep-dive

**Date:** 2026-10-22 · **Chain:** TON · **Status:** read-only; PoC is **local-TVM emulation only** (no transactions signed or sent; no keyed RPC URLs; no secrets)

**Headline:** the reported **$1.05M** "Unbacked Mint / Token & Share Accounting" loss is **not** a one-off — the exact confused-deputy path is **still live and unprivileged today**, and **no contract has been patched**. A single forged `jetton_notify` (`op=0x7362d09c`) to an Affluent **pool** makes that pool relay an attacker-influenced `0xa1b21e8b` message to the **LendingVault** named in the notify's `sender` field; the vault (which trusts pool-sourced messages) then **mints unbacked vault shares** that can be burned to pull the underlying out of the pools.

---

## 1 · TL;DR

| Target | Live value | Unprivileged-extractable now | Why | Confidence |
|---|---|---|---|---|
| **Affluent pools** (BasicPool, AdvancedPool, EthenaPool, LendingVaultPool, Storm pools) | **≈$1.42M** | **≈$1.42M (upper bound)** via the pool→vault mint chain | A forged `jetton_notify` to a pool is accepted without a sender check; the pool relays `0xa1b21e8b` to the vault in the `sender` field; the vault **mints** unbacked shares (reproduced on the verified BasicPool). | **high** on the path; **medium** on the exact max amount |
| BasicPool alone | ≈$757k | (part of the above) | Same path, reproduced end-to-end on the verified BasicPool | high |
| **LendingVaults** (affTONl `EQADQ6Jc…`, affUSDTl `EQAGtgnr…`) | minters | — | They **are** the minting contracts; they reject a direct `0xa1b21e8b` from a non-pool sender | high |
| MultiplyVaults (×7) | ≈$3.1M | $0 | Forged notify / aggregated-data ops leave their storage unchanged; cleared | medium |
| The 2026-10-16 $1.05M loss | realised | — | Executed by burning unbacked `affTONl`/`affUSDTl` shares (see §7) | high |

## 2 · Live extractable now

**E-U ≈ $1.42M (upper bound)** — the asset custody of the six pools the two LendingVaults can pull from:

| Pool | custody (2026-10-22) |
|---|---|
| BasicPool `EQCrEHHG…` | ≈$757k (tsTON $533k, XAUt0 $222k, USD₮ $2.6k, stGRAM) |
| AdvancedPool `EQBCXQp2…` | ≈$337k (tsTON) |
| EthenaPool `EQA9iTdg…` | ≈$272k (tsUSDe $270k, USD₮) |
| LendingVaultPool `EQBQMDjW…` | ≈$42k (affTONl, tsTON) |
| StormUsdtPool `EQAYJdU9…` | ≈$6.2k |
| StormAdvancedPool `EQCOA3gN…` | ≈$2.2k |
| **Total** | **≈$1,416,000** |

Realised precedent: **$1.05M** (DefiLlama) / ≈$1.14M reconstructed (09-30 + 10-12 + 10-16 sessions). *The upper bound is bounded by the LendingVaults' LP positions; the amount a given mint can redeem is not fully reversed (see §8 caveats).*

## 3 · The mechanism, in exact terms

TON internal messages carry an opcode. **`0x7362d09c`** is the TEP-74 *jetton transfer notification*; normally a jetton wallet notifies its **owner** contract. Two Affluent contracts mis-handle it:

1. **The pool (`affluent_pool`) does not verify that the immediate sender of `0x7362d09c` is its own asset jetton wallet.** On a forged notify it consumes `amount`/`sender`/`forward_payload` and emits:
   - a `jetton_transfer (0x0f8a7ea5)` back to the message source, and
   - an internal **`0xa1b21e8b` to the `sender` field of the notify** — with the notify body embedded.
   (Real tx `59458f7a…` first showed a plain `wallet_v3r1` relaying an arbitrary notify to the BasicPool.)
2. **The LendingVault trusts `0xa1b21e8b` from a pool and mints/credits shares** (reproduced: `data_changed=True` when the message comes from a pool, `False` from an arbitrary sender).

So the pool is a **confused deputy**: the attacker controls the notify body (`sender` = a chosen LendingVault master; `forward_payload` = attacker data), the pool relays it to the vault as a trusted `0xa1b21e8b`, and the vault mints unbacked shares.

## 4 · End-to-end reproduction (the decisive test)

`ci/ton_chain.py` (and `poc/`), against **live** state:

1. Send the **exact 2026-10-16 exploit `jetton_notify` body** (public chain data, tx `9d627a19…`) to the **verified BasicPool**, from an arbitrary wallet → pool **accepts** it and **relays `0xa1b21e8b` to the affUSDTl vault**.
2. Feed that relay to the **affUSDTl vault** → **vault storage changes** (`data_changed=True`) — an unbacked share credit.
3. Feed the **same body** to the vault from an arbitrary sender → **`data_changed=False`** (vault rejects it) → proving the pool relay is the necessary trusted hop.

All relevant code hashes are **unchanged** from the registry entries (i.e. **unpatched**):
BasicPool `1b16962d…` · pool `0:425d0a76…` `b73ff42e…` · LendingVaults `eb9d9891…`.

## 5 · Live-state assessment (TON, 2026-10-22)

- **BasicPool** `0:ab1071c6…`, code `1b16962d…`, `active`, custody ≈$757k, fully backed (actual ≥ claimed per market).
- **8 Pool instances**; two code hashes (`1b16962d…`, `b73ff42e…`) differing by one opcode constant. The exploit works on both (tested on a `1b16962d…` pool and on `b73ff42e…` pool `0:425d0a76…`).
- **LendingVaults**: `affTONl` `EQADQ6Jc…` and `affUSDTl` `EQAGtgnr…`, code `eb9d9891…`, `active`, both `jetton_master` + `affluent_lending_vault`.
- **MultiplyVaults** (7): storage unchanged under the forged ops tested → cleared.
- No pause/admin flag in the pool storage; owner/feeConfigurer/oracle are contracts.

## 6 · What an attacker can / cannot do

**Can (proven):** from an ordinary wallet, for ~0.01 TON of gas, send a single forged `jetton_notify` to a pool with `sender` = a LendingVault master and a crafted `forward_payload`; the pool relays `0xa1b21e8b`; the vault mutates its share accounting. The 2026-10-16 attacker minted `1e16` `affUSDTl` and `1e7` `affTONl` and burned them for **13,824.94 USDT** and **150,041.29 TON** in two transactions.

**Cannot:** call the vault directly (`0xa1b21e8b` from an arbitrary sender is rejected); spoof `src`; mint on the MultiplyVaults via the tested surfaces.

## 7 · The realised incident (corroboration)

- **10-16 20:46:02Z** tx `08b1751a89…`: burn `1e16` `affUSDTl` → **13,824.93 USDT** (from BasicPool $3,029 + StormUsdt $3,399 + Ethena $7,196 + Advanced $100 + StormAdvanced $100).
- **10-16 20:48:23Z** tx `ba3fc8ad72…`: burn `1e7` `affTONl` → **150,041.29 TON** (from BasicPool 126,352 + AdvancedPool 19,600 + LendingVaultPool 4,089).
- Prior sessions (same mechanism): **09-30** ≈504,827 TON (wallet `EQA04__gO…`), **10-12** ≈126,686 TON.
- Attackers: `EQAkM7tiVXJGaB0CTZ3Cc2MPi3vgPLfwx8fLmoVUKRTCwuCw` (10-16) and `EQA04__gOPOZvYeI0nBS233hWOKYWFyUBwtRecztUwyXobCz` (09-30/10-12).
- **Correction to the pass-4 note:** the BasicPool was **not** event-free; the earlier "zero events" was a tonapi `next_from` pagination artifact. BasicPool *was* a victim pool.

## 8 · Caveats, blockers, limitations

- **TON tooling is emulation-only** (no fork/anvil equivalent); the Tolk/FunC source is **not public**, so the handlers are characterised **behaviourally** (storage diff + emitted messages), not by source review.
- I proved the chain **mints**; I did **not** fully reverse the `forward_payload`/`0xa1b21e8b` format, so I did **not** prove a fresh attacker can redirect the mint recipient to a *new* address with a *custom* payload. Evidence that they can: in the replay the mint recipient came from the attacker-supplied body (not from `src`), and the original attacker minted to their own wallet. Confidence: medium-high.
- Consequently the exact maximum extractable (vs the $1.42M custody bound) is not established; the precedent is $1.05M.
- Lite-server reads are rate-limited; per-run block seqnos are in `ci-out/*.json`.
- Nothing here is an instruction to transact.

## 9 · Methodology & sources

- `ton-blockchain/abis` Affluent registry (`info.toml`, `types/*.tolk`), `tonkeeper/tongo` `affluent.xml`, `tonpy` disassembly.
- Live reads: TON lite servers (`tonpy.types.LiteClient`), `tonapi.io/v2` (anonymous), `toncenter.com/api/v2` (anonymous), `api.affluent.org/v2`.
- Incident records: DefiLlama `api.llama.fi/hacks` id 5726 (2026-10-16, $1,053,000, "Unbacked Mint"), SlowMist (cites DefiLlama only). **No attacker address / tx / post-mortem is public** (`analysis/intel.md`).
- Emulation: `tonpy==0.0.0.1.4rc0` native TVM transaction emulator against live account state (config param 43 dropped — bundled-emulator validator quirk).

## 10 · CI

- GitHub Actions (`artsbykriss/ca-zombie-ci`, branch `affluent`): **run URL in `ci-log.txt`**.
- Job `ci/run.sh` → installs `tonpy` → `ci/ton_emu.py` (23 forged-op storage tests + positive control) + `ci/ton_chain.py` (the decisive chain) → `ci-out/`.

## 11 · Files index

- `README.md`, `summary.json`
- `analysis/` — `loss-site.md` (loss isolation), `intel.md`/`intel.json`, `emu-results/`, scripts, raw dumps
- `poc/` — `ton_emu.py`, `ton_chain.py`, emulation variants, `README.md`
- `ci/` — `run.sh`, `ton_emu.py`, `ton_chain.py`; `ci-out/`, `ci-log.txt`, `ci-artifacts/`

*Point-in-time 2026-10-22; re-read all state before acting.*
