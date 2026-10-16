# UNCX Vesting V2 — Arbitrum (chain 42161) incident & residual-exposure report

**Scope:** Arbitrum main VestingManager `0x7f3f9f4ED8987B78adC448a840169A0FD5AFFAAB` and the 14.4 KB secondary build `0xe02514f79440922fa013c2ee887d5bc76416b209`, incident window Oct 14 00:00 UTC → Oct 16 00:00 UTC (window start block 514,581,113). State reads at block 515,241,193 (2026-10-16 ≈02:17 UTC); balances at block 515,229,728 (01:17:46 UTC). Read-only analysis; public RPCs and public APIs only.

## Headline numbers

| Item | Value |
|---|---|
| Incident-window activity | **0 creations, 0 top-ups, 0 cancels, 0 releases** — no attacker activity on Arbitrum |
| Containment events in window | 2× `FlatFeeUpdated`, 1× `FeePercentageUpdated` |
| Live manipulable schedules (soft+topable, uncancelled) | **0** — no `isTopable=true` schedule has **ever** been created on Arbitrum |
| Cumulative top-ups ever (`VestingToppedUp`) | **0** |
| Current extractable residual | **≈ $0.51** (main $0.0052 + secondary $0.5009 incl. CIP) |
| Secondary (14,391 B) fresh-attacker verdict | **Not viable** — flatFee 100 ETH (~$243k) vs pool $0.50; 2 residual fee-exempt creators noted (latent config risk, no economic upside) |
| Attacker addresses (ETH/BSC exploit) | 0 nonce, 0 balance; never a creator/beneficiary here |

## Main contract live state (block 515,241,193)

| Field | Value |
|---|---|
| Code size | 18,010 bytes (standard main build) |
| `nextVestingId` | 626 (ids 0–625; all created 2025-08-21) |
| `feePercentage` | 500 (= 5%; was 10 = 0.1% before Oct 14) |
| `flatFee` | `10000000000000000000000000` wei = **10,000,000 ETH** (1e25) — non-exempt creation effectively blocked |
| `owner` | `0x31c44A17aa2E639B40f33DA805CB1DB55d969693` (Gnosis Safe, same across all chains) |
| `feeCollector` | `0xD45dD91DF475bFD944335160f538c1A14888DC1C` |
| Native balance | 0 |

## Token balances (snapshot 2026-10-16 01:17:46 UTC, blk 515,229,728)

| Symbol | Contract | Dec | Balance | Price USD | Value USD |
|---|---|---|---|---|---|
| USDC | 0xaf88d065e77c8cc2239327c5edb3a432268e5831 | 6 | 5,225 raw (= 0.005225) | 0.999578 | $0.0052 |
| **Main total** | | | | | **$0.0052** |

Secondary `0xe02514f7…`:

| Symbol | Contract | Dec | Balance | Price USD | Value USD |
|---|---|---|---|---|---|
| USDC | 0xaf88d065e77c8cc2239327c5edb3a432268e5831 | 6 | 499,123 raw (= 0.499123) | 0.999578 | $0.4989 |
| DOUBLE | 0x20ccde1c4781d0f0a352532d31dda3c1933e5109 | 18 | 98.183666344182652176 | — (no DEX pair) | unpriced |
| CIP | 0xd7a892f28dedc74e6b7b33f93be08abfc394a360 | 18 | 2.26 | 0.0008755 (DexScreener, liq $8.4k) | $0.0020 |
| **Secondary total** | | | | | **$0.50** |

## Containment timeline (Arbitrum)

1. **2025-08-21** — fee setup: `flatFee` 0 → 0.05 ETH, `feePercentage` 10.
2. **2026-10-05 09:29:04** (blk 511,882,538) — pre-hardening: secondary `flatFee` → 1e20 wei = 100 ETH (tx `0x62fc450d…`, sender `0x85bd8ebf…`).
3. **2026-10-14 16:57:06** (blk 514,801,802) — containment step 1: main `flatFee` → 1e22 wei = 10,000 ETH (tx `0x3258c06a…`, sender `0x46565eed…` → helper `0x78138875…`).
4. **2026-10-14 21:13:52** (blk 514,858,666) — containment step 2: `flatFee` → 1e25 wei = 10,000,000 ETH + `feePercentage` → 500 (tx `0x23f5fe8e…`, sender `0x85bd8ebf…` → owner Safe).

**No other events occurred in the window** — no creations, top-ups, cancels or releases on either contract.

## Live manipulable schedules (critical output)

**None.** Full-history decode of all 626 main + 2,236 secondary `VestingCreated` events: **not a single creation carried `isTopable=true`** (main flags: soft non-transferable 500 / plain 125 / transferable-only 1; secondary: plain 1,527 / soft+transferable 208 / soft non-transferable 500 / transferable-only 1).

- The exploit sequence (release → `topUpVesting` → cancel cycle) is structurally impossible here: `topUpVesting()` simulation on sampled ids reverts **`NotTopable` (0x3813f790)**.
- Zero `VestingToppedUp` events exist in the entire history of both contracts; zero cancels.
- One historical release on the secondary (2025, id 0, beneficiary `0x037287a8…`, amount 1.483573560056682429e18 raw) — outside the incident window and consistent with a normal soft-schedule claim.
- **Residual extractability = $0**; contract-held balances are dust ($0.0052 + $0.50).

## Secondary 14.4 KB build (`0xe02514f79440922fa013c2ee887d5bc76416b209`)

| Field | Value |
|---|---|
| Code size / build | 14,391 bytes (same family as BSC/Base secondaries) |
| `nextVestingId` / `feePercentage` | 2236 / 10 (0.1%) |
| `flatFee` | 1e20 wei = 100 ETH ≈ **$243,150** — raised Oct 5 (pre-incident hardening) |
| Owner / feeCollector | same Safe / same collector |
| Fee-exempt creators | **`0x037287a8…` and `0x7618283e…` still exempt** (set ~Sept 2026, blk 502,629,681) |
| Balances | USDC $0.4989 + DOUBLE (unpriced) + CIP $0.0020 |
| Incident-window events | **0** |
| Historical activity | 2,236 creations (2025-08-05 → 2025-08-13), 1 release (2025); dormant for ~14 months |

**Verdict:** flatFee 100 ETH ($243k) vs pool $0.50 → **not viable** for a fresh attacker by ~500,000×. On Arbitrum the secondary is the *used* contract (the 18,010-byte main saw only 626 schedules on a single day in Aug 2025; the secondary saw 2,236 in Aug 2025). The two surviving fee exemptions mirror Avalanche's — configuration-hygiene items only, since no topable schedule exists and the pool is empty.

## Confidence / caveats

- Full-history events via Etherscan V2 (chainid 42161) chunked `getLogs` + direct RPC; balances via on-chain `balanceOf`; block timestamps read directly from chain.
- USD marks: DefiLlama 2026-10-16 ≈01:50 UTC (ETH $2,431.50, USDC $0.99958); CIP via DexScreener ($0.0008755, $8.4k liq). DOUBLE has no DEX pair — unpriced.
- Arbitrum block times ~0.25 s; window start block computed by solver for Oct 14 00:00 UTC.
- No write transactions were sent; no keys used.
