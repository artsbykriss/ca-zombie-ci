# C2-38 — STON.fi v1 (TON): deprecated router, still swapped — **live unprivileged extraction: $0**

**Date:** 2026-10-15 · **Chain:** TON (mainnet, workchain 0) · **Status:** read-only research; all PoC runs in an
in-memory TVM sandbox (@ton/sandbox) on CI; **no mainnet transaction was ever sent**; no secrets in this folder.

**Headline:** The STON.fi v1 system (`EQB3ncyBUTjZUA5EnFKR5_EnOMI9V1tTEAAPaiU71gc4TiUt`) is **closed to a fresh
unprivileged attacker**: **E-U = $0** (confidence: **high**). The ~**$8.76M** of live USDT+pTON custody is real,
but every payout path is gated by hash-verified deployed code: `pay_to` requires the sender to be a genuine pool
contract, pool payouts are bounded by each pool's virtual reserves, real-token reserves can only be credited by
real transfers, and the pTON wallet caps any credited amount at the TON actually attached. The prior wave-2 verdict
(“CLOSED path; residual = router admin 7-day timelock”) is **confirmed adversarially** — with one addition: the
admin is a **single-key `wallet_v4r2`**, which is the dominant residual risk (P).

---

## 1. TL;DR table

| Target | Live value (2026-10-15) | Unprivileged extractable (E-U) | Why closed / open | Latent risk |
|---|---|---|---|---|
| v1 Router `EQB3ncy…` + its USDT wallet `0:4eec92…` + pTON wallet `0:1150b5…` | **3,685,022.71 USDT + 3,766,747.65 pTON ≈ $8.76M** (pTON 1:1 backed by 3,794,719.10 TON in-wallet) | **$0** | `pay_to` sender==pool (verified + sandbox-proven); pools immutable & permissionless-created; payouts bounded by pool reserves; real-side reserves need real transfers; pTON wallet credit = `min(claim, value−fwd)` (sandbox-proven) | **P**: admin single-key `wallet_v4r2` can `init_code_upgrade` → 7-day timelock → arbitrary router code → drain all. No upgrade pending today (`temp_upgrade` empty) |
| USDT/pTON pool `EQD8TJ8x…` (largest v1 pool) | reserves **2,561,647.49 USDT + 1,883,344.32 pTON**; collected protocol fees **1,015,401.42 USDT + 213,017.38 pTON**; 5,245.85 TON | $0 | LP withdrawals only (H-O); `collect_fees` blocked by `protocol_fee_address == HOLE` | P: admin `set_fees` can unblock the fees |
| All 18,826 v1 pools (aggregate) | USDT reserves 2,649,910.74; TON-side reserves 3,528,651.99 pTON ≈ **$7.41M** | $0 | per-pool reserve accounting; no cross-pool leak found | LP withdrawals (H-O) |
| Router's USDT wallet TON `15,007.20 TON` + pTON wallet excess `27,971.45 TON` | ≈ **$58k** | $0 | wallet code has no TON-withdraw op; owner (router) never sweeps | **S** (stuck) — growing with usage |
| `collect_fees` reward (permissionless, 254 pools with non-HOLE fee addr) | max reward observed ≈ **$0.15/call** | **$0 net** | caller must attach >1 TON (~$2); reward = fees/1000 | none |

**Total live extractable now (E-U): $0.00** — confidence **high**.

## 2. What was verified, and how

### 2.1 Deployed code == published source (hash-exact)
The repo `ston-fi/dex-core` (`main`, = tag `v1.0.0` + README edit) compiles with the project's own toolchain
(`ton-compiler` v2022.10, func 0.2.0) to **exactly** the on-chain code hashes:

| Contract | Compiled hash | On-chain hash | Match |
|---|---|---|---|
| Router | `276f7c2058931d4685750a9856a5ac2dfa04d1b83c932d1e429fa3ceecd42faf` | same | ✅ |
| Pool | `82566ad72b6568fe7276437d3b0c911aab65ed701c13601941b2917305e81c11` | same (= router's stored `pool_code`) | ✅ |
| LP account | `fe9085c0bcc4f58983c38c62a46d46646ccf5dd1ae042dfa0f8355d0e9812175` | same (= router's stored `lp_account_code`) | ✅ |
| LP wallet | `0857cdd89c74844150cacd35cd020bef9167cbe12cd330dfb8c779c14d6b1552` | same (= router's stored `jetton_lp_wallet_code`) | ✅ |

Evidence: `analysis/code_verify.json`, `analysis/storage_parse.json`. Every code-level claim below therefore applies
to the deployed system, not just the repo.

### 2.2 Live state (masterchain seqno 99,204,239; gen_utime 1792076167)
- **Router** `EQB3ncyBUTjZUA5EnFKR5_EnOMI9V1tTEAAPaiU71gc4TiUt`: `is_locked = false` (swaps live), admin
  `0:499bbc12fb933d4a6277c4b3028fc3a5f8928b8a41838fe19f0f02f5ffa6fb70`
  (= `EQAEmbvBL7kz1KYnfEswKPw6X4kouKQYOP4Z8PAvX_pvtw`, **`wallet_v4r2`, no plugins, seqno 798**),
  `temp_upgrade` empty (**no upgrade pending**), TON balance 3,463.24.
- **Router's USDT wallet** `0:4eec921b9d4d56a0d94676016d49c26b39b1d7901a7e153e66033f146a0886f4`
  (`EQBO7JIbnU1WoNlGdgFtScJrObHXkBp-FT5mAz8UagiG9KQR`): **3,685,022.71 USDT** (`get_wallet_data`), 15,007.20 TON.
  Its code is a **type-2 exotic library cell** (shared Tether USDT wallet implementation; cannot be executed in
  @ton/sandbox — see caveats).
- **Router's pTON wallet** `0:1150b518b2626ad51899f98887f8824b70065456455f7fe2813f012699a4061f`
  (`EQARULUYsmJq1RiZ-YiH-IJLcAZUVkVff-KBPwEmmaQGH6aC`): **3,766,747.65 pTON**, backed by **3,794,719.10 TON**
  in the same account (1:1 proxy-TON design). Address == hash(initial state init (balance 0, owner=router)) ✅.
- **USDT/pTON pool** `EQD8TJ8xEWB1SpnRE4d89YO3jl0W0EiBnNS4IBaHaUmdfizE` = `get_pool_address(USDT wallet, pTON
  wallet)` ✅: reserves 2,561,647.49 USDT + 1,883,344.32 pTON; collected fees 1,015,401.42 USDT + 213,017.38 pTON;
  `protocol_fee_address = 0:0…0` (HOLE); 5,245.85 TON; locked initial LP = 16 raw units (negligible).
- **Accounting invariant holds:** custody (3,685,022.71 USDT) ≈ Σ pool USDT reserves (2,649,910.74) + Σ collected
  USDT fees (1,016,509.59) within 0.5% (API staleness). Same for pTON. The router is solvent; no orphan pool of
  value that an outsider can claim.
- All 18,826 v1 pools were enumerated via `api.ston.fi/v1/pools?dex_v2=false` and aggregated per token
  (`analysis/final_snapshot.json`).

### 2.3 Why no unprivileged path exists (the four gates, all re-verified)
1. **`pay_to` gate (the only jetton exit).** The router moves jettons only when the sender is the pool contract for
   the two token-wallet addresses in the message (`get_pool_state_init_and_address(...); throw_unless(INVALID_CALLER,
   equal_slices(pool_address, sender_address))`). Because the pool address = hash(code, data) and `code` is the
   router's stored `pool_code` (hash-verified), a forger cannot deploy arbitrary code at a pool address.
   **Sandbox proof (T1):** `pay_to` from a non-pool → exit 82 `INVALID_CALLER`; from the real pool address → exit 0
   and the jetton transfer instruction is emitted to the USDT wallet.
2. **Pool payouts are bounded by the pool's own virtual reserves.** All `call_pay_to` amounts are computed from
   `reserve0/reserve1` (swap: AMM output with `reserve_out − out − fees > 0` enforced; burn: pro-rata share;
   refunds: the credited input). `cb_refund_me` pays the LP account's credits, which are created only by the pool's
   `add_liquidity` from router-routed, actually-received transfers.
3. **Real-side reserves can only be credited by real transfers.** A forged `transfer_notification` (the router does
   not verify the notifier's code) is routed to the pool computed from *(forger, token_wallet1)*; the credited side
   is always the **forger's own** side. **Sandbox proof (T5):** a forged notification claiming 10¹⁸ units produced a
   pool `pay_to` with `amount0_out = 10¹⁸` on the **fake** token address and `amount1_out = 0` on USDT
   (`fake_side_credited: true, usdt_side_credited: false`).
4. **pTON wallet: no free credit.** The wallet credits `min(claim, msg_value − forward_ton_amount)` — i.e. at most
   the TON actually attached — then notifies its owner (the router). **Sandbox proof (T2/T3):** claim 1,000,000 TON
   with 0.2 TON attached → credited 0.1 TON only; claim 50 with 5 attached → credited 4.9. Every permissionless op
   reverts (ft_transfer 87, all others 0xFFFF); only the owner (router) can move the balance.

### 2.4 Other paths examined and closed
- **Getter handlers** (`getter_pool_address`, `getter_pool_data`, `getter_expected_liquidity`, …): `send_payload`
  uses mode 128 but `raw_reserve(0, 4)` reserves the whole balance first — **sandbox proof (T4):** reply is funded
  only by the incoming message; contract balance change = 0. (Prevents draining the pools' 5,245.85 TON etc.)
- **`collect_fees` (permissionless):** pays fees to `protocol_fee_address` + 1/1000 reward to the caller. 254 pools
  have a non-HOLE address, but the largest fee pool there has 53.8 USDT / 57.0 pTON collected → reward ≈ $0.15 vs
  >1 TON (~$2) gas → **net negative**; all large pools are HOLE-blocked (see residual).
- **LP minting/burning, LP accounts, LP wallets:** mint = `min(Δ0·L/R0, Δ1·L/R1)` (real-side ratio binds); burns are
  pro-rata; credits/refunds are bounded by received transfers; all senders are address-derived contracts.
- **pTON minter** (`0:8cdc1d76…`): only `deploy_wallet` (deploys a zero-balance wallet) and TEP-74 discovery — no
  mint path. **pTON wallet data layout/address** re-derived and matched.
- **Router admin ops** (`set_fees`, `lock/unlock`, `reset_gas`, upgrades): sender == admin only. No pending upgrade.
- **USDT wallet:** all 128 sampled transfer instructions (0xf8a7ea5) came **exclusively** from the router (owner)
  over 400 recent txs (`analysis/usdt_wallet_senders.json`) — consistent with TEP-74 owner gating.

## 3. What an attacker can/cannot do (exact call paths)

| Attempt | Result | Preconditions / cost |
|---|---|---|
| `pay_to` directly to router (any token) | reverts 82 | none — no capital needed |
| Deploy fake pool + fake notifier, then swap fake→real | payout ≤ that pool's **real** reserve (attacker's own deposits); forger's side credited only | needs real deposits equal to payout → **no profit** |
| Forge pTON `transfer_notification` to credit pools for free | impossible: credit = `min(claim, value−fwd)` | must attach ≥ credited TON |
| Drain pool/router TON via getters | impossible (`raw_reserve(0,4)`) | — |
| `collect_fees` reward farming | max ≈ $0.15/call vs ≈$2 gas | net negative; large pools HOLE-blocked |
| Steal LP tokens / lp_account credits | owner-gated / address-derived senders | — |
| Impersonate the admin | impossible (single key, no plugins) | key compromise only |

## 4. PoC / sandbox verification (files, results, CI)

- PoC: `poc/stonfi_v1_poc.js` — loads the **live** code+data of the router, the USDT/pTON pool and the pTON wallet
  (keyless toncenter) into `@ton/sandbox`, runs T1–T5, writes `ci-out/stonfi_v1_poc.json`.
- Support probes: `poc/probe_permissionless_ops.js`, `poc/probe_wrap_matrix.js`, `poc/probe_credit_formula.js`,
  `poc/probe_getters.js` (same environment).
- **Result: all 5 test groups as expected** — `T1_router_pay_to_gate`, `T2_T3_pton_wallet`, `T4_getters_no_drain`,
  `T5_fake_notifier_pool` (see `ci-out/stonfi_v1_poc.json` and CI artifact).
- CI runs (public, `artsbykriss/ca-zombie-ci`):
  - run 1 (PoC v1, 4 groups): https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38754665195
  - **run 2 (final, full folder)**: https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38756241579
    (log: `ci-log.txt`, artifacts: `ci-artifacts/result-stonfi-v1/ci-out/stonfi_v1_poc.json`)
- No fork block pinning is meaningful here: the probes run against the deployed *code*, and live *data* is fetched
  at run time (state snapshot seqnos recorded in the outputs).

## 5. Verdict, residual & latent risk

- **E-U = $0** (high confidence). No fresh unprivileged path found; the prior wave-2 closure stands and is now
  code-hash-grounded and sandbox-proven.
- **H-O ≈ $7.41M**: LP holders can burn LP and withdraw (per-pool pro-rata). The locked initial LP is negligible
  (16 raw units on the big pool). Users' unclaimed `lp_account` credits are additionally self-service (not summed).
- **P ≈ $1.33M now, ≈ $8.76M ultimate**: the admin (single-key `wallet_v4r2`, no plugins) can (a) `set_fees` +
  `collect_fees` to free the 1,016,509.59 USDT + 223,030.30 pTON of protocol fees, (b) `reset_gas`/`reset_pool_gas`
  to sweep TON balances, and (c) **`init_code_upgrade` → 7-day timelock → `finalize_upgrades` → arbitrary router
  code → take the entire custody**. Today `temp_upgrade` is empty (no upgrade in flight) — the timelock gives a
  7-day on-chain warning if it ever starts.
- **S ≈ $58k**: 15,007.20 TON stranded in the USDT wallet + 27,971.45 TON excess in the pTON wallet (no reachable
  sweep op) + ~1,000 junk jetton balances in the router wallets (nominal $0).
- **Blockers/frozen value:** the HOLE `protocol_fee_address` blocks the big pools' fee collection; `is_locked=false`
  so swaps are live.

## 6. Methodology, sources, caveats

- Sources: live TON RPC/API (keyless toncenter v3, tonapi.io v2), the STON.fi public API and docs, GitHub
  `ston-fi/dex-core` (v1.0.0), `ston-fi/sdk`, `ston-fi/pton-contracts` (TEP-161 reference — *not* the deployed v1
  pTON), @ton/sandbox 0.22 + @ton/core 0.59 (local TVM).
- Everything was read-only; PoCs run in-memory only; CI artifacts are public and contain no secrets.
- **Caveats:** (1) the router's USDT wallet code is a *library* cell → not executable in @ton/sandbox; its
  owner-gating is supported by code-hash/library semantics plus the 400-tx behavioural sample, not by a local PoC.
  (2) The v1 pTON wallet/minter have no published source; behaviour was determined by decompilation
  (`analysis/pton_wallet_disasm.txt`) **and** black-box sandbox probes of the deployed code. (3) Pool aggregates
  come from the STON.fi API (~0.5% stale vs on-chain). (4) `E-U=$0` is a negative result — it is only as strong as
  the coverage listed above; the four gates above are the load-bearing checks.

## 7. Files index

```
stonfi-v1/
├── README.md                       (this file)
├── summary.json                    (machine-readable)
├── analysis/                       live reads, disassembly, verification scripts & JSONs
│   ├── code_verify.json            compiled-vs-deployed code hash proof
│   ├── storage_parse.json          router/pool storage decode + state-init check
│   ├── final_snapshot.json         final live state (seqno 99,204,239)
│   ├── pton_wallet_disasm.txt      deployed pTON wallet TVM disassembly
│   ├── pton_minter_disasm.txt      deployed pTON minter TVM disassembly
│   ├── usdt_wallet_disasm.txt      (decompiler output; exotic library cell)
│   ├── pton_credit_formula.json    credit = min(claim, value−fwd) evidence
│   ├── pton_wrap_matrix.json       forged-claim matrix (all capped)
│   ├── getter_probe.json           getter no-drain evidence
│   ├── usdt_wallet_senders.json    400-tx owner-gating sample
│   ├── admin_wallet_data.json      admin v4r2, no plugins
│   └── *.py                        client + verification scripts (keyless endpoints only)
├── poc/stonfi_v1_poc.js            main sandbox PoC (T1–T5) + support probes
├── ci/run.sh                       CI job (npm install + run PoC)
├── ci-out/                         PoC outputs (also uploaded as CI artifacts)
└── ci-log.txt / ci-artifacts/      CI log + artifacts
```
