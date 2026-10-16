# UNCX Vesting V2 — Unichain (chain 130) incident & residual-exposure report

**Scope:** Unichain main VestingManager `0x3dd1e6c7F905322136E5DF5ECf638059877E0a20` and the 14.4 KB secondary build `0x8c1678ba864f1e113027f40eb3aee082d81ef67d`, incident window Oct 14 00:00 UTC → Oct 16 00:00 UTC (window start block 61,187,641). State reads at block 61,368,304 (2026-10-16 ≈02:10 UTC); balances at block 61,365,092 (01:17:31 UTC). Read-only analysis; public RPCs and public APIs only.

## Headline numbers

| Item | Value |
|---|---|
| Incident-window activity | **0 creations, 0 top-ups, 0 cancels, 0 releases** — no attacker activity on Unichain |
| Containment events in window | 3× `FlatFeeUpdated`, 2× `FeePercentageUpdated`, 1× `CreatorFeeExemptionUpdated` (a4068dcb removed) |
| Live manipulable schedules (soft+topable, uncancelled) | **0** — no `isTopable=true` schedule has **ever** been created on Unichain |
| Cumulative top-ups ever (`VestingToppedUp`) | **0** |
| Current extractable residual | **≈ $3.10** (main $2.08 + secondary $1.02; excl. unpriced VST) |
| Secondary (14,391 B) fresh-attacker verdict | **Not viable** — flatFee 100 ETH (~$243k) vs pool $1.02 |
| Attacker addresses (ETH/BSC exploit) | 0 nonce, 0 balance; never a creator/beneficiary here |

## Main contract live state (block 61,368,304)

| Field | Value |
|---|---|
| Code size | 18,010 bytes (standard main build) |
| `nextVestingId` | 1439 (ids 0–1438 all created before the incident; last creation 2026-10-02) |
| `feePercentage` | 500 (= 5%; was 10 = 0.1% before Oct 14) |
| `flatFee` | `uint256.max` (creation effectively disabled for non-exempt creators; zero exempt creators remain) |
| `owner` | `0x31c44A17aa2E639B40f33DA805CB1DB55d969693` (Gnosis Safe, same across all chains) |
| `feeCollector` | `0xD45dD91DF475bFD944335160f538c1A14888DC1C` |
| Native balance | 0 |

## Token balances (snapshot 2026-10-16 01:17:31 UTC, blk 61,365,092)

On-chain `balanceOf` for the full explorer-indexed inventory. **Raw balances are quoted — mind decimals: USDC is 6 dp, so 1,161,919 raw = $1.16, not $1.16M.**

| Symbol | Contract | Dec | Balance | Price USD | Value USD |
|---|---|---|---|---|---|
| USDC | 0x078d782b760474a361dda0af3839290b0ef57ad6 | 6 | 1,161,919 raw (= 1.161919) | 0.999578 | $1.16 |
| DAI | 0x20cab320a855b39f724131c69424240519573f81 | 18 | 0.915934 | 1.000175 | $0.92 |
| USDT | 0x588ce4f028d8e7b53b687865d6a67b3a54c75518 | 6 | 205 raw (= 0.000205) | 0.999027 | $0.0002 |
| VST | 0x4319980f7a02ddeea3d841d7c14f7bc55311b4da | 18 | 10,500 | — (no DEX pair) | unpriced |
| WETH | 0x4200000000000000000000000000000000000006 | 18 | 0 | — | $0 |
| (spam) | 0xac4eab74e176fcd5f410040c25db9db745982825 | 0 | 1 | — | $0 |
| **Main total** | | | | | **$2.08** (excl. VST) |

Secondary `0x8c1678ba…`: USDC 1,022,986 raw (= $1.02) + VST 1,000 (unpriced) → **$1.02**.

## Containment timeline (Unichain)

1. **2025-08-25** — fee setup: `flatFee` 0 → 0.05, `feePercentage` 10.
2. **2026-10-07 09:25:41** — ops pre-hardening: secondary `flatFee` → 100 ETH (tx `0xfa6056c4…`, sender `0x46565eed…`).
3. **2026-10-14 16:57:33** (blk 61,248,694) — containment step 1: main `flatFee` → 1e22 wei = 10,000 ETH (native; tx `0x3499611d…`, sender `0x46565eed…` → helper `0x78138875…`).
4. **2026-10-14 21:19:25** (blk 61,264,406) — containment step 2: `flatFee` → 1e25 wei = 10,000,000 ETH (native; ≈$24.3B) + `feePercentage` → 500 (tx `0x0b78723f…`, sender `0x85bd8ebf…` → owner Safe).
5. **2026-10-15 11:12:53** (blk 61,314,414) — containment step 3: `flatFee` → `uint256.max` + `feePercentage` 500 + **removed fee exemption for creator `0xa4068dcb…`** (tx `0x6f8608ba…`).

**No other events occurred in the window** — no creations, top-ups, cancels or releases on either contract.

## Live manipulable schedules (critical output)

**None.** Full-history decode of all 1,439 main + 1,817 secondary `VestingCreated` events: **not a single creation carried `isTopable=true`** (main flags: soft+transferable 1,297 / plain 141 / soft non-transferable 1; secondary: soft+transferable 405 / plain 1,212 / transferable-only 200).

- The exploit sequence (release → `topUpVesting` → cancel cycle) is structurally impossible here: `topUpVesting()` simulation on sampled ids reverts **`NotTopable` (0x3813f790)**.
- Zero `VestingToppedUp` events exist in the entire history of both contracts on Unichain.
- Historical releases (main 3, 2026; secondary 2, 2025) and cancels (main 12, 2025) are all outside the incident window and follow normal patterns.
- **Residual extractability = $0**; contract-held balances are dust ($2.08 + $1.02).

## Secondary 14.4 KB build (`0x8c1678ba864f1e113027f40eb3aee082d81ef67d`)

| Field | Value |
|---|---|
| Code size / build | 14,391 bytes (same family as BSC/Base secondaries) |
| `nextVestingId` / `feePercentage` | 1817 / 10 (0.1%) |
| `flatFee` | 100 ETH ≈ **$243,150** — raised Oct 7 (pre-incident hardening) |
| Owner / feeCollector | same Safe / same collector |
| Fee-exempt creators | none |
| Balances | USDC $1.02 + VST (unpriced) |
| Incident-window events | **0** |
| Historical activity | 1,817 creations (2025-08-05 → 2025-08-14), 2 releases (2025); dormant since Aug 2025 |

**Verdict:** flatFee 100 ETH is ~240,000× the pool value ($1.02). A fresh attacker creating a topable schedule would pay $243k to attack dust. **Not viable; negligible exposure.** (For completeness: it also has zero topable schedules in history.)

## Confidence / caveats

- Full-history events via Etherscan V2 (chainid 130) chunked `eth_getLogs`; balances via on-chain `balanceOf`; block timestamps read directly from chain.
- USD marks: DefiLlama 2026-10-16 ≈01:50 UTC (USDC $0.99958, DAI $1.00017, USDT $0.99903). VST has no DEX pair on DexScreener — left unpriced.
- The three containment txs were the *only* main-contract events in the window; `0x46565eed…` (early raise) and `0x85bd8ebf…` (later raises) are UNCX ops addresses used identically on Base/BSC and the other L2s.
- No write transactions were sent; no keys used.
