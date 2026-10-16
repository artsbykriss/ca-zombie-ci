# UNCX Vesting V2 — Optimism (chain 10) incident & residual-exposure report

**Scope:** Optimism main VestingManager `0x2Ba0cb1153f10d2A95E16e0581324244b9227dDB` and the 14.4 KB secondary build `0xAd2071A3021a118A92E95328A6D12bEE0E1C5D8d`, incident window Oct 14 00:00 UTC → Oct 16 00:00 UTC (window start block 158,168,612). State reads at block 158,258,954 (2026-10-16 ≈02:18 UTC); balances at block 158,257,346 (01:17:49 UTC). Read-only analysis; public RPCs and public APIs only.

## Headline numbers

| Item | Value |
|---|---|
| Incident-window activity | **0 creations, 0 top-ups, 0 cancels, 0 releases** — no attacker activity on Optimism |
| Containment events in window | 2× `FlatFeeUpdated`, 1× `FeePercentageUpdated` |
| Live manipulable schedules (soft+topable, uncancelled) | **0** — no `isTopable=true` schedule has **ever** been created on Optimism |
| Cumulative top-ups ever (`VestingToppedUp`) | **0** |
| Current extractable residual | **≈ $5.05** (main $0; secondary $5.05) |
| Secondary (14,391 B) fresh-attacker verdict | **Not viable** — flatFee 100 ETH (~$243k) vs pool $5.05 |
| Attacker addresses (ETH/BSC exploit) | 0 nonce, 0 balance; never a creator/beneficiary here |

## Main contract live state (block 158,258,954)

| Field | Value |
|---|---|
| Code size | 18,010 bytes (standard main build) |
| `nextVestingId` | **0 — the main contract was never used** (no schedule has ever been created) |
| `feePercentage` | 500 (= 5%; was 10 = 0.1% before Oct 14) |
| `flatFee` | `10000000000000000000000000` wei = **10,000,000 ETH** (1e25; ≈$24.3B) — non-exempt creation effectively blocked |
| `owner` | `0x31c44A17aa2E639B40f33DA805CB1DB55d969693` (Gnosis Safe, same across all chains) |
| `feeCollector` | `0xD45dD91DF475bFD944335160f538c1A14888DC1C` |
| Native balance | 0; **no tokens ever received** |

## Token balances (snapshot 2026-10-16 01:17:49 UTC, blk 158,257,346)

Main: no token balances — the contract holds nothing.

Secondary `0xAd2071A3…`:

| Symbol | Contract | Dec | Balance | Price USD | Value USD |
|---|---|---|---|---|---|
| USDC | 0x0b2c639c533813f4aa9d7837caf62653d097ff85 | 6 | 5,050,000 raw (= 5.05) | 0.999578 | $5.05 |
| ACHIVX | 0xfaf87e196a29969094be35dfb0ab9d0b8518db84 | 6 | 100 raw (= 0.0001) | — (no DEX pair) | unpriced |
| **Secondary total** | | | | | **$5.05** |

## Containment timeline (Optimism)

1. **2025-08** — fee setup: `flatFee` 0 → 0.05 ETH, `feePercentage` 10.
2. **2026-10-05 09:30:11** (blk 157,796,917) — pre-hardening: secondary `flatFee` → 1e20 wei = 100 ETH (tx `0x669623e4…`, sender `0x46565eed…`).
3. **2026-10-14 16:57:21** (blk 158,199,132) — containment step 1: main `flatFee` → 1e22 wei = 10,000 ETH (tx `0x460d52a2…`, sender `0x46565eed…` → helper `0x78138875…`).
4. **2026-10-14 21:14:17** (blk 158,206,840) — containment step 2: `flatFee` → 1e25 wei = 10,000,000 ETH + `feePercentage` → 500 (tx `0xc050ac3d…`, sender `0x85bd8ebf…` → owner Safe).

**No other events occurred in the window** — no creations, top-ups, cancels or releases on either contract.

## Live manipulable schedules (critical output)

**None.** Full-history decode: the **main contract has zero creations ever** (`nextVestingId=0`), and the secondary's 501 creations (2025-08-13 → 2025-08-14, a one-day campaign with 501 distinct beneficiaries) are **all** soft+transferable flags with **`isTopable=false`** — not a single topable schedule was ever created on Optimism.

- The exploit sequence (release → `topUpVesting` → cancel cycle) is structurally impossible here: `topUpVesting()` simulation on sampled ids reverts **`NotTopable` (0x3813f790)**.
- Zero `VestingToppedUp`, zero `VestingCancelled`, zero `TokensReleased` events exist in the entire history of both contracts.
- **Residual extractability = $0**; the only balance is the secondary's $5.05 USDC.

## Secondary 14.4 KB build (`0xAd2071A3021a118A92E95328A6D12bEE0E1C5D8d`)

| Field | Value |
|---|---|
| Code size / build | 14,391 bytes (same family as BSC/Base secondaries) |
| `nextVestingId` / `feePercentage` | 501 / 10 (0.1%) |
| `flatFee` | 1e20 wei = 100 ETH ≈ **$243,150** — raised Oct 5 (pre-incident hardening) |
| Owner / feeCollector | same Safe / same collector |
| Fee-exempt creators | none |
| Balances | USDC $5.05 + ACHIVX dust (unpriced) |
| Incident-window events | **0** |
| Historical activity | 501 creations (2025-08-13 → 2025-08-14); dormant for ~14 months |

**Verdict:** flatFee 100 ETH ($243k) vs pool $5.05 → **not viable** by ~48,000×. Zero topable schedules in its history.

## Confidence / caveats

- Full-history events via Blockscout (`optimism.blockscout.com`) + direct RPC (`mainnet.optimism.io`, small batches — the public node rejects large batch requests with HTTP 413); balances via on-chain `balanceOf`; block timestamps read directly from chain.
- USD marks: DefiLlama 2026-10-16 ≈01:50 UTC (ETH $2,431.50, USDC $0.99958). ACHIVX has no DEX pair — unpriced.
- The OP main contract is a never-used shell — the single cleanest negative result across the six chains.
- No write transactions were sent; no keys used.
