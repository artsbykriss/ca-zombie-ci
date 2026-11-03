# Coffer (Solana) M-08 rounding — deployed-fix and per-call-bound verification (CA2 LOW-tail C)

**Date:** 2026-11-03 · **Chain:** Solana mainnet-beta · **Status:** read-only; no transaction signed or broadcast.

**Verdict: LOW confirmed — live E-U is $0.00.**
The post-incident fix is still the deployed `cubic_pool` bytecode: last deploy **slot 458,810,142 =
2026-10-19T11:04:29Z**, upgrade authority unchanged, and no later deploy. The fix predates the prior
behavioural simulation (slot 464,630,474) and the live ProgramData is still at that same deploy slot, so
the exact bytecode that was measured as patched is what runs today. Even in its unpatched form the
M-08 defect is bounded to **one raw unit per live leg per call**; across the 43 pools (29 mints,
5–9 decimals) one raw unit is at most **$0.000773** (1 sat of an 8-decimal BTC token), and a 9-leg call
is at most **$0.00695**. The realised incident was ~$0.7. This is not a >$10k primitive.

---

## 1. TL;DR

| Item | Value |
|---|---|
| Program | `cubic_pool` = `8iQtGj9mcUfFUGaiCpPy89swC3s8YTC8FhVZWfgeZhwu` (BPFLoaderUpgradeable) |
| ProgramData | `7Lh9eKmDMfHwDKkUjoqfYSRoPbin8dEzSAdkWkmavZw4`, 652,605 bytes |
| Last deploy | slot **458,810,142** = **2026-10-19T11:04:29Z** |
| Upgrade authority | `B4gyhrqLzX36VEu54ShqgTkb4TpXooTdxtcmvER3d3Bg` (Treasury PDA; governance) |
| ProgramData SHA-256 | `14e0965ad0ec5a4e7a7c3d3a68d6936559abe48ab165ce3c93f952dbfde65bd3` |
| Pools | 43 (27 × 1683-byte v5, 16 × 1154-byte legacy); all 27 v5 `pool_enabled == true` |
| Pool mints | 29 unique; decimals 5–9 (no 0-decimal token) |
| DefiLlama TVL | **$58,417.31** (2026-11-03) |
| Max one raw unit | **$0.0007726891** (1 sat of an 8-dp BTC token at $77,268.91) |
| Max 9-leg call | **$0.0069542** |
| Live E-U | **$0.00** |

**Correction to the CA2 row's "per-call bound is one raw unit (<$1)":** the bound is confirmed, but the
largest single raw unit in these pools is $0.00077, i.e. ~1,300× below $1. The realised incident ($0.7
from thousands of deposits) is consistent.

---

## 2. What M-08 is, and what the fix changed

M-08 was introduced by the M-04 fix and shipped in the 2026-09-07 rollout. In `add_liquidity`, the
minted BPT and each live leg's credited amount were computed as independent `floor()` operations on
the same `ratio_min`; a thin leg could be credited 0 while the depositor still received BPT, transferring
value from existing LPs to the depositor (redeemable via `remove_liquidity`).

The vendor's prescribed fix (Serokell follow-up, 2026-09-09) is:

```
realized_ratio_i   = div_up(credit_i, actual_i)
virtual_increase_i = mul_up(virtual_i, realized_ratio_i)
```

i.e. credit exactly what was received, and move the virtual balance up by the rounded-up ratio. The
2026-10-19 deploy is the implementation of that fix; the 2026-10-18 incident realised ~$0.7.

**Behavioural evidence (prior run, same bytecode):** a read-only `simulateTransaction` at slot
464,630,474 against the USDC/USDT pool (`AL4yxA4o…`, ≈$18.1k) with `token_amounts = [1, 1]` showed:

- `actual_balance` USDC `6,387,254,400 → 6,387,254,401` (+1)
- `actual_balance` USDT `11,752,656,809 → 11,752,656,810` (+1)
- `virtual_balance` USDC `4,425,046,065,443 → 4,425,046,066,136` (+693) = `ceil(4.425046e12 × ceil(1/6387254400))`
- `virtual_balance` USDT `4,430,411,203,905 → 4,430,411,204,282` (+377) = `ceil(4.430411e12 × ceil(1/11752656809))`

That is the exact `div_up`/`mul_up` signature of the fix; the pool credited the received amounts, not an
independently floored credit.

**Identity chain (re-verified today):** last deploy slot is **458,810,142** (2026-10-19), which is
*earlier* than the simulation slot **464,630,474**; the ProgramData is still at 458,810,142 today
(local re-read at slot 464,913,747; the CI re-check at slot 464,921,077 gives the same last-deploy slot and hash), and its SHA-256 is unchanged. Therefore the deployed
bytecode measured as patched is the bytecode live now. No fresh simulation was run in this pass — the
behavioural result is inherited from the prior run, while the deployment identity is re-verified
on-chain. This is stated as a caveat, not hidden.

---

## 3. Live state (slot 464,913,747, 2026-11-03)

| Check | Result |
|---|---|
| `getSlot` | 464,913,747 (confirmed) |
| ProgramData owner | `BPFLoaderUpgradeab1e11111111111111111111111` |
| ProgramData length | 652,605 bytes (matches prior) |
| `last_deploy_slot` (offset 4, u64 LE) | **458,810,142** |
| `last_deploy_blocktime` | **1,792,407,869 = 2026-10-19T11:04:29Z** |
| Upgrade authority | `B4gyhrqLzX36VEu54ShqgTkb4TpXooTdxtcmvER3d3Bg` (tag 1) |
| `getProgramAccounts` dataSize 1683 | 27 (all `pool_enabled == true` per prior read) |
| `getProgramAccounts` dataSize 1154 | 16 legacy |
| DefiLlama TVL | $58,417.31 |

Pool token set (29 mints) includes SOL (9 dp), USDC/USDT (6), JUP/JTO/RAY/WIF/BONK (5–9), cbBTC/zBTC/wBTC
(8). **No pool mint has fewer than 5 decimals**, so one raw unit cannot exceed the 8-dp BTC case.

---

## 4. The bound, exactly

Per the audit's own accepted-risk table: *“Rounding in `add_liquidity` can favour the depositor by at most
one raw unit per token per call — Economically negligible.”*

| Leg type | One raw unit | USD at 2026-11-03 prices |
|---|---:|---:|
| 8-dp BTC (cbBTC/zBTC/wBTC) | 1 sat | **$0.0007726891** |
| 9-dp SOL | 1 lamport | $0.0000000928 |
| 6-dp USDC/USDT | 1 micro-unit | $0.000001 |
| 5-dp BONK | 1 raw | <$0.000001 |
| 18-dp token | 1 wei | negligible |

Worst case the pool has 9 live legs → **$0.0069542 per call**. Solana signature fee is 5,000 lamports
≈ $0.000464 at SOL $92.84, plus priority fee; the net per call is at most a few tenths of a cent. The
2026-10-18 incident realised **$0.7** from thousands of deposits, independently corroborating the
ceiling. Reaching $10k would require ~1.4M worst-case calls (≈$670+ in bare signature fees before
priority fees), with per-call state and block-space constraints — not a viable extraction path, and the
fix makes the live gain **zero**.

---

## 5. E-U / H-O / P / S quantification

| Category | Value | Basis |
|---|---:|---|
| **E-U (live)** | **$0.00** | M-08 fix deployed; simulation shows full credit + `mul_up` virtual; no live rounding gain |
| E-U-counterfactual (unpatched) | ≤$0.00695/call | one raw unit per leg, 9 legs max; not a >$10k primitive |
| H-O | TVL $58,417.31 | LPs can withdraw their own liquidity normally; not attacker-reachable |
| P | upgrade authority `B4gy…` | governance can upgrade the program |
| S | none | all v5 pools enabled; no frozen value attributable to this bug |

---

## 6. Evidence / files

- `analysis/verify.py` — re-reads ProgramData, parses last-deploy slot/hash/authority, counts pools, reads TVL.
- `analysis/pool_tokens.json` — 27 v5 pools, 29 mints, decimals, max-raw-unit bound.
- Prior behavioural run: `ca2/.work/final/coffer-rounding.md` §3 (slot 464,630,474; same bytecode).
- Program/ProgramData addresses corroborated by the vendor SDK `coffer-so/sdk` `src/config/networks.ts`
  and the vendor audit index `coffer-so/audit`.

## 7. Caveats

- The program source is private; the fix is verified behaviourally and by deployment identity, not by a
  source diff. The ProgramData SHA-256 is recorded so a future re-check can detect any upgrade.
- The prior simulation used a real LP signer with `sigVerify: false` and no broadcast; it was not re-run
  in this pass because the ProgramData has not changed since (last deploy 458,810,142 < simulation slot
  464,630,474). If the program is upgraded, the behavioural conclusion must be re-tested.
- TVL is DefiLlama's figure; it is not attacker-extractable via this bug.

**CI (read-only re-verification):** https://github.com/artsbykriss/ca-zombie-ci/actions/runs/41647220393
