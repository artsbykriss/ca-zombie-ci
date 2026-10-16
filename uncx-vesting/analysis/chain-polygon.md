# UNCX Vesting V2 — Polygon (chain 137) incident & residual-exposure report

**Scope:** Polygon main VestingManager `0x09e9f68F72917984e333BD2E18Adae5fAFf97587` and the 14.4 KB secondary build `0x88a98dc689e85b42daf70a065d03151c09659710`, incident window Oct 14 00:00 UTC → Oct 16 00:00 UTC (window start block 95,487,125). State reads at block 95,607,566 (2026-10-16 ≈02:16 UTC); balances at block 95,605,423 (01:17:42 UTC). Read-only analysis; public RPCs and public APIs only.

## Headline numbers

| Item | Value |
|---|---|
| Incident-window activity | **0 creations, 0 top-ups, 0 cancels, 0 releases** — no attacker activity on Polygon |
| Containment events in window | 2× `FlatFeeUpdated`, 1× `FeePercentageUpdated` |
| Live manipulable schedules (soft+topable, uncancelled) | **0** — no `isTopable=true` schedule has **ever** been created on Polygon |
| Cumulative top-ups ever (`VestingToppedUp`) | **0** |
| Current extractable residual | **$0** (all pools dust); only sizeable holding is 2,001 FCAR on the main contract — nominal $37.1k, but DEX liquidity ≈$30.1k |
| Secondary (14,391 B) fresh-attacker verdict | **Not viable** — flatFee 10,000 POL (~$957) vs pool $0.001 |
| Attacker addresses (ETH/BSC exploit) | 0 nonce, 0 balance; never a creator/beneficiary here |

## Main contract live state (block 95,607,566)

| Field | Value |
|---|---|
| Code size | 18,010 bytes (standard main build) |
| `nextVestingId` | 4285 (ids 0–4284; last creation 2026-04-05) |
| `feePercentage` | 500 (= 5%; was 10 = 0.1% before Oct 14) |
| `flatFee` | `252348200000000000000000000` wei = **252,348,200 POL ≈ $24.14M** (finite, not `uint256.max`) — non-exempt creation effectively blocked |
| `owner` | `0x31c44A17aa2E639B40f33DA805CB1DB55d969693` (Gnosis Safe, same across all chains) |
| `feeCollector` | `0xD45dD91DF475bFD944335160f538c1A14888DC1C` |
| Native balance | 0 |

## Token balances (snapshot 2026-10-16 01:17:42 UTC, blk 95,605,423)

| Symbol | Contract | Dec | Balance | Price USD | Value USD |
|---|---|---|---|---|---|
| FCAR | 0x13f812237bcad602a524d399618c467d49dd080c | 18 | 2,001 | 18.54 (DexScreener, liq $30.1k) | $37,098.54 *nominal* |
| PHILX | 0x859eabdb8637e3b087d9a7babb9b9990153a2217 | 18 | 100,000,000.0047 | — (no DEX pair) | unpriced |
| XSR | 0xa5b1e92659c10851d6bc9d34723225508b5b1a62 | 18 | 2,272.219999999999868928 | — (no DEX pair) | unpriced |
| TTT5 | 0xd9a90c3a3ebdc650ffc725eaf8f33d825a5525c5 | 18 | 3,637.5 | — (no DEX pair) | unpriced |
| USDC | 0x3c499c542cef5e3811e1192ce70d8cc03d5c3359 | 6 | 1,625 raw (= 0.001625) | 0.999578 | $0.0016 |
| (spam ×4) | 0x0c7c8046…, 0x935ab0fa…, 0xf23165e1… (voucher tokens, 0 dp) | 0 | 1 each | — | $0 |

FCAR headline: **$37.1k nominal at last DEX price; the FCAR pool holds only ≈$30.1k of liquidity, so that value is not fully realizable** — treat as ≲$30k gross and likely far less for a single seller. PHILX/XSR/TTT5 have no discoverable DEX pair.

Secondary `0x88a98dc6…`: FHA ≈100,000 (= 99,999.9999999999991611392, unpriced) + ANOT 20,000 (unpriced) + USDC 1,000 raw (= $0.001) + 4 spam tokens → **$0.001**.

## Containment timeline (Polygon)

1. **2025-08** — fee setup: `flatFee` 0 → 500 POL, `feePercentage` 10.
2. **2026-10-05 09:26:56** (blk 94,991,510) — pre-hardening: secondary `flatFee` → 1e22 wei = 10,000 POL (tx `0x28117614…`, sender `0x46565eed…`).
3. **2026-10-14 17:00:34** (blk 95,527,940) — containment step 1: main `flatFee` → 1e24 wei = 1,000,000 POL (tx `0x527f469c…`, sender `0x46565eed…` → helper `0x78138875…`).
4. **2026-10-14 21:13:07** (blk 95,538,042) — containment step 2: `flatFee` → **252,348,200 POL** (2.523482e26 wei) + `feePercentage` → 500 (tx `0x9adce690…`, sender `0x85bd8ebf…` → owner Safe). Polygon is the only chain where the final `flatFee` is finite rather than `uint256.max` or 10M-native.

**No other events occurred in the window** — no creations, top-ups, cancels or releases on either contract.

## Live manipulable schedules (critical output)

**None.** Full-history decode of all 4,285 main + 103 secondary `VestingCreated` events: **not a single creation carried `isTopable=true`** (main flags: soft+transferable 3,526 / plain 759; secondary: soft+transferable 103 = all). No creation on this chain ever designated a schedule as topable.

- The exploit sequence (release → `topUpVesting` → cancel cycle) is structurally impossible here: `topUpVesting()` simulation on sampled ids reverts **`NotTopable` (0x3813f790)**.
- Zero `VestingToppedUp` events exist in the entire history of both contracts. Zero cancels and zero releases — ever — on both contracts.
- **Residual extractability = $0** on the pools; the FCAR balance is a normal token holding of the main contract (deposited vesting tokens), not attacker-extractable via any schedule path.

## Secondary 14.4 KB build (`0x88a98dc689e85b42daf70a065d03151c09659710`)

| Field | Value |
|---|---|
| Code size / build | 14,391 bytes (same family as BSC/Base secondaries) |
| `nextVestingId` / `feePercentage` | 103 / 10 (0.1%) |
| `flatFee` | 1e22 wei = 10,000 POL ≈ **$956.72** — raised Oct 5 (pre-incident hardening) |
| Owner / feeCollector | same Safe / same collector |
| Fee-exempt creators | none |
| Balances | FHA/ANOT (unpriced) + USDC $0.001 |
| Incident-window events | **0** |
| Historical activity | 103 creations (2025-08-12 → 2025-08-20, all soft+transferable); dormant for ~14 months |

**Verdict:** flatFee 10,000 POL (~$957) vs pool value ≈$0. **Not viable.** Zero topable schedules in its history; the one path (soft+topable creation) is both fee-prohibited and worthless here.

## Confidence / caveats

- Full-history events via Etherscan V2 (chainid 137) chunked `eth_getLogs` + direct RPC; balances via on-chain `balanceOf`; block timestamps read directly from chain.
- USD marks: DefiLlama 2026-10-16 ≈01:50 UTC (POL $0.095672, USDC $0.99958). PHILX/XSR/TTT5/FHA/ANOT have no DEX pairs — unpriced.
- FCAR: $18.54 is the last DexScreener trade price with ≈$30.1k pool liquidity; the nominal $37.1k is an upper bound, not realizable value.
- The final Polygon `flatFee` (252,348,200 POL) is large but finite; non-exempt creation at that price is economically dead for any realistic token pool.
- No write transactions were sent; no keys used.
