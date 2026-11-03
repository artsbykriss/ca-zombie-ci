# Aperture Finance instant-liquidity router — live-value re-verification (CA2 LOW-tail C)

**Date:** 2026-11-03 · **Chains:** Ethereum, Arbitrum, Optimism, Polygon · **Status:** read-only; no transaction was signed or broadcast.

**Verdict: LOW confirmed — live external-unprivileged extraction is $0.00.**
The arbitrary-call / caller-controlled `transferFrom` path is still present and was proven live by a
third-party transaction on 2026-08-21, but the value is gone: every still-approved UniV3 LP NFT has
`liquidity == 0` and `tokensOwed0/1 == 0`, the router holds no native or sampled token balance, and the
only *materially funded* ERC-20 approval (Truebit `TRU`, 3,477,020.1 tokens) is on a **globally paused token** —
`transferFrom` reverts `ERC20Pausable: token transfer while paused`.

One correction to the CA2 row: the router was **not “fully swept”** in the sense that every approval was
zeroed. A live, materially funded ERC-20 approval remains; it is blocked by the token's pause, not by the attacker.
If the token is unpaused, the nominal exposure is ~$17.6k (single MEXC market, thin), so this is a
**latent P-conditional** risk, not live E-U.

---

## 1. TL;DR

| Target | Chain | Live E-U now | Exact gate | Latent risk |
|---|---|---:|---|---|
| Aperture router `0xD83d960d…8913` | ETH / ARB / OP / POLY | **$0.00** | all 78 still-approved LP NFTs have zero liquidity/owed; funded ERC-20 approval is on paused TRU; dust ≤$0.58 | TRU unpause (proxy-admin) → ≤$17.63k nominal; realizable on MEXC depth is lower |

**Total live extractable now: $0.00 (confidence: high).**
**Latent / conditional: ≤$17,629.92 nominal (confidence: medium; not counted as E-U).**

---

## 2. The defect (what is still deployed)

`0xD83d960deBEC397fB149b51F8F37DD3B5CFA8913` is Aperture's “instant liquidity” router. It is closed
source, **not a proxy** (EIP-1967 implementation slot `0x3608…2bbc` is zero on ETH/ARB/OP/POLY), and the
same 19,444-byte (38,888-hex-character) runtime is deployed at the same address on all four chains (constructor
immutables differ per chain, so the code hashes differ; the entrypoints and length match).

The vulnerability class (public analyses: BlockSec, Olympix, SolidityScan, revoke.cash) is a
caller-controlled `from`/target in the router's low-level call path: the router calls
`transferFrom(victim, attacker, tokenId/amount)` after checking only the approval spender it sets up,
not the address/data it calls. The entry selector `0x67b34120` is still present in the runtime code.

**Proof the path is live (re-traced today, read-only):** Ethereum tx
`0x7d2c160dba1b2d1af3965499adc7a30baf6c1bd38eeb08f68b95e32d18ec6314`, block **25,803,114**
(2026-08-21), status **1**. `debug_traceTransaction` callTracer shows:

```
EOA 0xfcbe6aa9… -> router 0xD83d…8913  (selector 0x67b34120)
  router -> UniswapV3 NFPM 0xC364…1FE88 . transferFrom(0xc846d321…, 0xfcbe6aa9…, tokenId 0xd188b)
  router -> NFPM . mint(...)  -> new position tokenId 0x14aa1c to 0xfcbe6aa9…
```

The `Transfer` log confirms the NFT moved from a non-caller (`0xc846d321…`) to the caller
(`0xfcbe6aa9…`). This is an unprivileged, repeatable path against any ERC-721 position still approved
to the router; the same entry is asserted by the public analyses to accept ERC-20 targets.

---

## 3. Live state (measured at the blocks below)

Approval enumeration: every `Approval(owner, spender=router, value)` log ever emitted on each chain
(topic0 `0x8c5be1e5…`, topic2 = router), last approval per `(token, owner)`, then live
`balanceOf(owner)` / `allowance(owner, router)` at the chain head. Raw data:
`analysis/live_approvals.json`.

| Chain | Head block | Approval logs | Distinct (token,owner) | ERC-20 with allowance>0 & balance>0 | Approved NFTs | Approved NFTs with liquidity>0 |
|---|---:|---:|---:|---:|---:|---:|
| Ethereum | 26,334,413 | 245 | 110 | **1** (TRU) | 10 | 0 |
| Arbitrum | 520,879,985 | 668 | 173 | 0 | 36 | 0 |
| Optimism | 159,056,069 | 25 | 12 | 0 | 7 | 0 |
| Polygon | 96,670,312 | 545 | 97 | 7 (dust) | 25 | 0 |
| **Total** | | **1,483** | **392** | **8** | **78** | **0** |

Router balances: native **0** on all four chains; sampled ERC-20 balances (TRU, FANS, SHIB, USDC,
SUSHI) **0**; the router is non-custodial. The one OP NFT with non-zero liquidity (tokenId 1,018,074,
`liquidity = 214,173,985,621,107,308,065`) has `getApproved == 0` and
`isApprovedForAll(owner, router) == false`, so it is not reachable.

### 3.1 The one funded ERC-20 approval: Truebit `TRU` (paused)

| Field | Value |
|---|---|
| Token | `0xf65b5c5104c4fafd4b709d9d60a185eae063276c` (AdminUpgradeabilityProxy; impl `0x18cedf10…4446`) |
| Owner | `0x530a445ce59467732e5da4df9c0a31f1d80ef16e` (EOA; code length 0) |
| Balance | **3,477,020.105893728270632095 TRU** (`balance_raw 3477020105893728270632095`) |
| Allowance to router | `115792089237316195423570985008687907853269984665640556317146959127110281543037` (~2^256) |
| Token state | **`paused() == true`** |
| Pause event | block **24,192,375** (2026-01-08T20:34:23Z), `Paused(0x39e6918d…)`; one pause, no unpause |
| `transferFrom` simulation | reverts **`ERC20Pausable: token transfer while paused`** (call from the router, i.e. the allowance leg is reached) |
| Nominal value | 3,477,020.1 × $0.00507041 = **$17,629.92** (CoinGecko contract price; only ticker = MEXC, 24h volume $55,850) |
| On-chain liquidity | Uniswap V2 TRU/WETH pair `0x80b4d4e9…85C5` holds 0.02058 WETH vs 96.74B TRU; V3 pools exist but are shallow. Selling the balance into the V2 pair yields ~$0.002 (constant-product), not $17.6k. |

The token's `DEFAULT_ADMIN_ROLE` and `PAUSER_ROLE` are both held by a single EOA,
`0x39e6918d41b06199656925173ff17499a225a090` (role counts 1/1; the same address emitted the pause). The
proxy admin `0xAb749Bccbee148DBD273Bff4840CfdF751491C0A` (contract, 2,844 bytes) can upgrade the
implementation but holds neither token role. Unpause is therefore a single-key admin action — **P**, not
external. So the freeze is a privileged/latent condition, not an attacker-reachable one.

### 3.2 Polygon dust (the only other live both-sides approvals)

| Token | Owner | Reachable raw | USD |
|---|---|---:|---:|
| WBTC `0x1bfd6703…` | `0xea95f723…` | 76 sat | $0.0587 |
| WBTC `0x1bfd6703…` | `0x8470138b…` | 147 sat | $0.1136 |
| USDC `0x3c499c54…` | `0x02b6709e…` | 100 (0.0001 USDC) | $0.0001 |
| USDC `0x3c499c54…` | `0x3d2855e5…` | 100 (0.0001 USDC) | $0.0001 |
| SUSHI `0x0b3f868e…` | `0xdb3b3510…` | 0.4543675 | $0.0872 |
| SHIB `0x6f8a0644…` | `0x8470138b…` | 69,323.9093 | $0.3197 |
| FANS `0x1a16afdf…` | `0xdc9ab9d7…` | 2,861,578,510 raw = 2.86e-9 FANS (18 dp) | negligible; no price/liquidity |
| | | **total priced** | **$0.5794** |

Gas on Polygon to execute the router call exceeds the priced dust; net ≈ $0.

---

## 4. What an attacker can / cannot do

**Can:** call `0x67b34120` (and sibling entries) with a victim `from` and a tokenId/amount; the router
executes `transferFrom` as `msg.sender`. For NFTs this is proven (tx above). For ERC-20s it is the
public-analysis claim; we did not independently reconstruct an ERC-20-target transaction because the
only funded ERC-20 approval is paused.

**Cannot:** get value from the router itself (0 native, 0 sampled tokens); move any of the 78 approved
NFT positions (all `liquidity == 0`, `tokensOwed == 0`); move TRU while the token is paused; unpause TRU
through the router (admin-only).

**Preconditions for the latent path:** (1) the TRU token DEFAULT_ADMIN/PAUSER EOA unpauses the token; (2) the ERC-20-target
variant of the router bug is reachable (as asserted by BlockSec/Olympix, not re-proven here); (3) an exit
with enough depth exists — MEXC is the only visible market and 3.48M TRU is ~31% of its $55.8k daily
volume, so realized value would likely be below the $17.6k nominal and could be below $10k.

---

## 5. E-U / H-O / P / S quantification

| Category | Value | Basis |
|---|---:|---|
| **E-U (live)** | **$0.00** | 78 approved NFTs empty; TRU paused; dust $0.58 not economically extractable |
| E-U-conditional (TRU unpaused + ERC-20 target works) | ≤$17,629.92 nominal | 3.48M TRU at $0.00507041; realized ≤ nominal, likely lower |
| H-O | n/a (holders can withdraw their own LP NFTs; no attacker value) | positions are self-custodied |
| P | TRU unpause | token DEFAULT_ADMIN/PAUSER EOA `0x39e6918d…a090` (single key) |
| S | 3,477,020.1 TRU frozen while paused | global ERC20Pausable |

---

## 6. Evidence / files

- `analysis/enumerate_approvals.py` — full re-enumeration (public RPCs + Etherscan V2 + Blockscout OP).
- `analysis/live_approvals.json` — 1,483 logs, 392 pairs, live balances/allowances, NFT owner/approval/liquidity.
- `analysis/heimdall2/decompiled.sol`, `analysis/heimdall/abi.json` — decompiler output for the unverified router.
- Exploit tx and trace: `0x7d2c160d…6314`, block 25,803,114; callTracer via `debug_traceTransaction`.
- TRU: proxy/impl slots, `paused()`, `Paused` event at block 24,192,375, `transferFrom` revert; role/pause data in `analysis/tru_permissions.json`.

## 7. Caveats

- The router is closed source; the exact parameter layout of `0x67b34120` was not fully reconstructed. The
  NFT-theft path is proven by the live trace; the ERC-20-theft variant rests on the cited public analyses.
- The TRU nominal price is a single-venue (MEXC) quote with no on-chain depth; it is not a realizable
  $17.6k at size. It is reported as nominal/latent, not E-U.
- Approval enumeration covers `Approval` events; `ApprovalForAll` operator grants were not exhaustively
  enumerated. The one non-empty OP position was checked directly: `isApprovedForAll == false`.

**CI (read-only re-verification):** https://github.com/artsbykriss/ca-zombie-ci/actions/runs/41647220393
