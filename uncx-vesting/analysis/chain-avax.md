# UNCX Vesting V2 — Avalanche (chain 43114) incident & residual-exposure report

**Scope:** Avalanche main VestingManager `0x586FEfeeFA117cEC8f32a6B2a0ABEE443315eb87` and the 14.4 KB secondary build `0x2ba0cb1153f10d2a95e16e0581324244b9227ddb`, incident window Oct 14 00:00 UTC → Oct 16 00:00 UTC (window start block 97,485,346). State reads at block 97,667,599 (2026-10-16 ≈02:15 UTC); balances at block 97,664,473 (01:17:38 UTC). Read-only analysis; public RPCs and public APIs only.

## Headline numbers

| Item | Value |
|---|---|
| Incident-window activity | **0 creations, 0 top-ups, 0 cancels, 0 releases** — no attacker activity on Avalanche |
| Containment events in window | 3× `FlatFeeUpdated`, 1× `FeePercentageUpdated` |
| Live manipulable schedules (soft+topable, uncancelled) | **0** — no `isTopable=true` schedule has **ever** been created on Avalanche |
| Cumulative top-ups ever (`VestingToppedUp`) | **0** |
| Current extractable residual | **≈ $0.36** (main $0.25 + secondary $0.11; excl. unpriced SHIBX) |
| Secondary (14,391 B) fresh-attacker verdict | **Not viable** — flatFee 1,000 AVAX (~$9.97k) vs pool $0.11; 2 residual fee-exempt creators noted (latent config risk, no economic upside) |
| Attacker addresses (ETH/BSC exploit) | 0 nonce, 0 balance; never a creator/beneficiary here |

## Main contract live state (block 97,667,599)

| Field | Value |
|---|---|
| Code size | 18,010 bytes (standard main build) |
| `nextVestingId` | 729 (ids 0–728; last creation 2026-09-07) |
| `feePercentage` | 500 (= 5%; was 10 = 0.1% before Oct 14) |
| `flatFee` | `uint256.max` (creation effectively disabled for non-exempt creators; zero exempt creators remain) |
| `owner` | `0x31c44A17aa2E639B40f33DA805CB1DB55d969693` (Gnosis Safe, same across all chains) |
| `feeCollector` | `0xD45dD91DF475bFD944335160f538c1A14888DC1C` |
| Native balance | 0 |

## Token balances (snapshot 2026-10-16 01:17:38 UTC, blk 97,664,473)

| Symbol | Contract | Dec | Balance | Price USD | Value USD |
|---|---|---|---|---|---|
| USDC | 0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e | 6 | 247,887 raw (= 0.247887) | 0.999578 | $0.25 |
| SHIBX | 0x440abbf18c54b2782a4917b80a1746d3a2c2cce1 | 18 | 225.714331707244706532 | — (no DEX pair) | unpriced |
| **Main total** | | | | | **$0.25** (excl. SHIBX) |

Secondary `0x2ba0cb11…`: USDC 113,178 raw (= $0.1131) → **$0.11**.

## Containment timeline (Avalanche)

1. **2025-08** — fee setup: `flatFee` 0 → 4 AVAX, `feePercentage` 10.
2. **2026-09-07** (blk 94,680,825) — ops granted creator fee exemptions on the secondary to `0x037287a8…` and `0x7618283e…` (tx `0xd12f025a…`; **still active at report time**).
3. **2026-10-07 09:26:29** (blk 96,944,633) — pre-hardening: secondary `flatFee` → 1e21 wei = 1,000 AVAX (tx `0xd7f94909…`, sender `0x85bd8ebf…`).
4. **2026-10-14 16:48:24** (blk 97,545,125) — containment step 1: main `flatFee` → 1e21 = 1,000 AVAX (tx `0x8a111ef2…`, sender `0x85bd8ebf…` → owner Safe).
5. **2026-10-14 19:59:58** (blk 97,556,212) — containment step 2: `flatFee` → 2.3e24 = 2,300,000 AVAX (~$22.9M) (tx `0xf5ba35e1…`).
6. **2026-10-14 20:55:30** (blk 97,559,361) — containment step 3: `flatFee` → `uint256.max` + `feePercentage` → 500 (tx `0x712f25d7…`).

**No other events occurred in the window** — no creations, top-ups, cancels or releases on either contract.

## Live manipulable schedules (critical output)

**None.** Full-history decode of all 729 main + 954 secondary `VestingCreated` events: **not a single creation carried `isTopable=true`** (main flags: soft+transferable 664 / plain 65; secondary: plain 891 / soft+transferable 63).

- The exploit sequence (release → `topUpVesting` → cancel cycle) is structurally impossible here: `topUpVesting()` simulation on sampled ids reverts **`NotTopable` (0x3813f790)**.
- Zero `VestingToppedUp` events exist in the entire history of both contracts.
- Historical releases (main 3, secondary 4 — all 2025) are outside the incident window; zero cancels ever. Zero `VestingToppedUp`.
- **Residual extractability = $0**; contract-held balances are dust ($0.25 + $0.11).

## Secondary 14.4 KB build (`0x2ba0cb1153f10d2a95e16e0581324244b9227ddb`)

| Field | Value |
|---|---|
| Code size / build | 14,391 bytes (same family as BSC/Base secondaries) |
| `nextVestingId` / `feePercentage` | 954 / 10 (0.1%) |
| `flatFee` | 1e21 wei = 1,000 AVAX ≈ **$9,971** — raised Oct 7 (pre-incident hardening) |
| Owner / feeCollector | same Safe / same collector |
| Fee-exempt creators | **`0x037287a8…` and `0x7618283e…` still exempt** (set 2026-09-07) |
| Balances | USDC $0.1131 |
| Incident-window events | **0** |
| Historical activity | 954 creations (2025-08-05 → 2025-08-16), 4 releases (2025); dormant since Aug 2025 |

**Verdict:** flatFee 1,000 AVAX ($9,971) vs pool $0.11 → **not viable** for a fresh attacker, by ~90,000×. The two surviving fee exemptions are the only latent risk on this chain: an exempt key can create schedules without paying `flatFee`, but even a full drain of this pool is $0.11 and no topable schedule exists there. Flagged for follow-up only as a configuration-hygiene item.

## Confidence / caveats

- Full-history events via Routescan + direct RPC (`api.avax.network`) chunked `eth_getLogs`; balances via on-chain `balanceOf`; block timestamps read directly from chain.
- USD marks: DefiLlama 2026-10-16 ≈01:50 UTC (AVAX $9.9715, USDC $0.99958). SHIBX has no DEX pair — left unpriced.
- Avalanche block timestamps confirm containment started 16:48 UTC (before the Base/ETH attack reports circulated widely) and escalated to max at 20:55 UTC Oct 14.
- No write transactions were sent; no keys used.
