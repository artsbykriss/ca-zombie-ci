# UNCX Vesting V2 — Base (chain 8453) incident & residual-exposure report

**Scope:** Base main VestingManager `0x7ca3dE7D58A0bCAd115184597553485A919320c5` and the 14.4 KB secondary build `0xcb08b6d865b6de9a5ca04b886c9cecef70211b45`, incident window Oct 14 00:00 UTC → Oct 15 ~23:44 UTC (blocks 52,573,000–52,659,521). State reads at Base block ≈**52,659,814** (2026-10-15 23:30 UTC). Read-only analysis; public RPCs and public APIs only.

## Headline numbers

| Item | Value |
|---|---|
| Attack executed | **Oct 14 2026, 19:48:49 UTC** (tx1) and **20:17:57 UTC** (tx2–4) — blocks 52,608,991 and 52,609,865 |
| Token attacked | **IMO** `0x5a7a2bf9ffae199f088b25837dcd7e115cf8e1bb` (18 dec) |
| Attack tx senders | tx1 `0xc0ffeebabe5d496b2dde509f9fa189c25cf29671` (via router `0x16e41af5…`); tx2 `0xb929c7215c0ec8ebad5fbf73b1da63bccfff1896` (via new contract); tx3 `0x0000000000300a8c18629d5c4fc25a498f22b6bd`; tx4 `0x0000000000382d3e66fafaf4f7c563b76b2da40f98` (both via helper `0x0000000000be226afde21672a5e4adc45692e69d`) |
| Schedules created in window | **13** (ids 836–848); 10 soft+topable, all **cancelled**; 4 non-soft "siphon" schedules (836, 840, 843, 846), all fully released |
| **Pool balance before attack** | **200,798.00 IMO** (blocks ≤52,608,900) |
| Pool balance after tx1 | 185.4149 IMO |
| Pool balance now | 0.04639495106327033 IMO (46,394,951,063,270,333 wei) |
| **Net drained (theft)** | **≈ 200,797.95 IMO ≈ $111,276** (IMO $0.5541715, DefiLlama 2026-10-15 23:23Z) |
| Biggest single over-claim | schedule **836**: nominal total 10,000 IMO → `TokensReleased` **280,612.585077942418623959 IMO** |
| Live manipulable schedules | **0** |
| Current extractable residual | **$0** |

## Main contract live state (block ≈52,659,814)

| Field | Value |
|---|---|
| Code size | 18,010 bytes |
| `nextVestingId` | 849 |
| `feePercentage` | 500 (= 5%) |
| `flatFee` | `uint256.max` (creation effectively disabled for non-exempt creators post-incident) |
| `owner` | `0x31c44A17aa2E639B40f33DA805CB1DB55d969693` (Gnosis Safe v1.4.1, threshold 2) |
| `feeCollector` | `0xD45dD91DF475bFD944335160f538C1A14888DC1C` |
| `calculator` | `0xBb1fE9B7ae3b6f1CF1C8505d203B543010245c0D` |
| `svgGenerator` (slot 9) | `0x9a9741059bb19a09441e4e1dc62ba1b608d5a66a` |
| Deployment interaction | tx `0x9cff1fb34d81d3b3d54a824ae57aa021bd368624c63033ec115b99c54ccb9091`, block 52,098,737 (UNCX deployer `0x90cf3e1f…`, inferred from transfer) |
| Native balance | 0 |

## Token balances (snapshot 2026-10-15 23:31:55 UTC)

Source: GoldRush token-balances snapshot (USD by GoldRush), cross-checked via Alchemy and BaseScan. **Full 135-token list with raw balances is in `chain-base.json`.** Top holdings:

| Symbol | Contract | Dec | Balance | Price USD | Value USD | Last transfer |
|---|---|---|---|---|---|---|
| DOT (usedot) | 0x23a2847d772803f9efc64b4277b782b06296fe51 | 18 | 8,409,164.591563805 | 0.008146978 | $68,509.28 | 2026-09-09 |
| LIFE | 0x151ccc74972a6f85690afe997d0fdd69efdc71fe | 18 | 5,131,633.198196399 | 0.00014418445 | $739.90 | 2026-10-05 |
| cbLTC | 0xcb17c9db87b595717c857a08468793f5bab6445f | 8 | 0.16237857 | 60.09656 | $9.76 | 2026-09-18 |
| AERO | 0x940181a94a35a4569e4529a3cdfb74e38fd98631 | 18 | 1.0 | 0.88868773 | $0.89 | 2025-11-08 |
| USDC | 0x833589fcd6edb6e08f4c7c32d4f71b54bda02913 | 6 | 0.306884 | 0.9979091 | $0.31 | 2026-09-02 |
| **IMO** | 0x5a7a2bf9ffae199f088b25837dcd7e115cf8e1bb | 18 | **0.0463949506** | 0.5538152 | $0.026 | 2026-10-14 20:17 |
| + 129 dust/memecoin tokens (mostly unpriced) | | | | | | |

Totals: GoldRush **$69,260.16**; BaseScan net worth **$66,173.29** ("Assets in Wallet (147)"). Both are dominated by the Base "DOT" token (~$65.4–68.5k). The two sources agree within ~4%.

## Incident detail (Base)

1. **16:48:49 UTC (block 52,603,591, timestamp computed)** — UNCX ops raise `flatFee` to 100 ETH (tx `0x7ffc524a…`, sender `0x46565eed…` → `0x781388759eacb9892f60d77d9a99c9be2f7f4ada`). Notably IMO was fee-EXEMPT at this point, so the raise did not stop the attacker.
2. **19:48:49 UTC (block 52,608,991)** — tx `0x9a679a1c42cc89dd31afa6d1a9a3433bebbe040fd3cffeb12b04e6969c6f71aa` (below: tx1) performed the whole exploit in one call: create 836 (10,000 IMO, non-soft "siphon") + 837/838/839 (360,000 IMO each, **soft+topable**) → `release()` 837/838/839 (360,000 each) → `topUpVesting` 837/838/839 (+288,000 each) → `cancel()` 837/838/839 → `release()` 836 = **280,612.585 IMO**. Pool 200,798 → 185.415 IMO (net −200,612.6).
3. **20:01:53 / 20:27:41 / 21:12:07 UTC** — UNCX containment: flatFee → 10,000 ETH (block 52,609,383); IMO token de-exempted (block 52,610,157; tx `0x2bd89b62…`); flatFee → 10,000,000 ETH + feePercentage 500 (block 52,611,490).
4. **20:17:57 UTC (block 52,609,865)** — three follow-up txs (below: tx2–tx4) repeated the pattern with smaller amounts (siphons 840/843/846), draining the remaining ~185 IMO to dust.
5. **Oct 15 11:10:53 UTC (block 52,636,653)** — UNCX sets flatFee = `uint256.max` and removes creator fee-exemption for `0xa4068dcb282a1a957740c3e0e10ae7b588216dd8`.

### Incident schedule table (all 13; current state)

`VestingCreated(uint256 indexed id, address indexed beneficiary, address token, TimeAmount[] tranches, bool isSoft, bool isTopable, bool isTransferable)`; creator = msg.sender (the router/helpers). `claimable_now = (releasableShares × poolBalance) / totalShares`, pool balance dust → 0 for all.

| id | type | total (IMO) | released (IMO) | soft | topable | cancelled | creator/beneficiary | tx |
|---|---|---|---|---|---|---|---|---|
| 836 | siphon | 10,000 | **280,612.585** (event) | no | no | no | 0x16e41af5…7b19 | `0x9a679a1c…` |
| 837 | manipulation | 360,000 | 360,000.000 | yes | yes | **yes** | 0x16e41af5…7b19 | `0x9a679a1c…` |
| 838 | manipulation | 360,000 | 360,000.000 | yes | yes | **yes** | 0x16e41af5…7b19 | `0x9a679a1c…` |
| 839 | manipulation | 360,000 | 360,000.000 | yes | yes | **yes** | 0x16e41af5…7b19 | `0x9a679a1c…` |
| 840 | siphon | 37.08298441 | 357.291825 | no | no | no | 0xbe4eae6f…39ac | `0xcf43762b…` |
| 841 | manipulation | 556.2447662 | 19.82251673 | yes | yes | **yes** | 0xbe4eae6f…39ac | `0xcf43762b…` |
| 842 | manipulation | 556.2447662 | 19.82251673 | yes | yes | **yes** | 0xbe4eae6f…39ac | `0xcf43762b…` |
| 843 | siphon | 2.336773889 | 22.51464443 | no | no | no | 0x77875e20…d64a | `0x47fa0312…` |
| 844 | manipulation | 35.05160834 | 35.05160834 | yes | yes | **yes** | 0x77875e20…d64a | `0x47fa0312…` |
| 845 | manipulation | 35.05160834 | 35.05160834 | yes | yes | **yes** | 0x77875e20…d64a | `0x47fa0312…` |
| 846 | siphon | 0.147251153 | 1.418754021 | no | no | no | 0x91a418f1…5192 | `0x0917b418…` |
| 847 | manipulation | 2.208767294 | 2.208767294 | yes | yes | **yes** | 0x91a418f1…5192 | `0x0917b418…` |
| 848 | manipulation | 2.208767294 | 2.208767294 | yes | yes | **yes** | 0x91a418f1…5192 | `0x0917b418…` |

Full tx hashes: tx1 `0x9a679a1c42cc89dd31afa6d1a9a3433bebbe040fd3cffeb12b04e6969c6f71aa`; tx2 `0xcf43762bdecbaa2fa76ab5f93905323de78116c2f1fc1f960f25e793f156da1c`; tx3 `0x47fa0312a687403462c070f6fbb66e942d415227cae24b6623fe9f732a0cee34`; tx4 `0x0917b418be3c2a42023259e5489e3c2f73e92579b98a47a689d93bd5a0f9043c`.

(The "released" of siphon schedules 836/840/843/846 exceeds their nominal totals — 836 released 28× its 10,000 IMO total — direct evidence of the share-accounting over-claim. The manipulation schedules were themselves released and later cancelled; their `_depositedShares` were over-reduced below `released`, so `claimable = 0`.)

## Live manipulable schedules (critical output)

**None.** Full scan of all 849 schedules (ids 0–848) via `getVestingSchedule`:

- combos: `soft only: 260`, `plain: 577`, `soft+cancelled: 1`, `soft+topable+cancelled: 10`, `soft=false+topable=true: 1`.
- `soft=true AND topable=true AND cancelled=false` → **0 schedules**.
- The 4 uncancelled siphon schedules (836/840/843/846) are **not soft and not topable** → cannot be cancelled or topped up; all are fully released (`released == depositedShares`).
- IMO pool balance = 0.0464 IMO (dust) → even a hypothetical claim would be < $0.03.

**Residual extractability on Base = $0. No latent-hazard pattern of the BSC kind (no surviving soft+topable schedules).**

## Secondary 14.4 KB build (`0xcb08b6d865b6de9a5ca04b886c9cecef70211b45`)

Found by enumerating UNCX-deployer `0x90cf3e1fb9d1b35fad621649ca503ea13cf37163` transfers on Base (Alchemy) and matching the 14,391-byte code size of the BSC secondary. Code hash differs from the BSC secondary (same size, different build metadata). The address `0xEc76C87E…` (BSC secondary) has **no code on Base**.

| Field | Value |
|---|---|
| Code size | 14,391 bytes |
| `nextVestingId` | 1101 |
| `feePercentage` | 10 (= 0.1%) |
| `flatFee` | 100 ETH ≈ **$243,982** (ETH $2,439.82, DefiLlama) |
| `owner` | same Safe `0x31c44A17…9693` |
| `feeCollector` | same `0xD45dD91…DC1C` |
| `calculator` | `0x601b1cb16806DdB11f02010225ab7e2A20F400dF` |
| Balances | USDC 0.029 ($0.029) + one spam airdrop token (1 unit, 0 decimals, worthless) = **$0.03** (Alchemy; BaseScan confirms 3/3 assets, net $0.03) |
| Incident window events | **0** (none between 52,573,000–52,659,521) |
| Schedule scan | not fully scanned (pool value $0.03 makes it moot); no incidents |

**Verdict:** flatFee 100 ETH (~$244k) is ~8,000,000× the pool value ($0.03). No incident activity. **Not viable; negligible exposure.** (Base's documented "legacy" contract `0xA82685520C463A752d5319E6616E4e5fd0215e33`, 15,232 bytes, is a different, non-shared-pool generation — `nextVestingId()` reverts on it.)

## Confidence / caveats

- Window event capture: 1000-block chunked `eth_getLogs` (thirdweb public archive). All 52 manager events in the window were captured and decoded; pool balances were read at historical blocks via archive `eth_call` (pre-attack, post-tx1, now).
- Timestamps: 52,608,991 / 52,609,383 / 52,609,865 / 52,610,157 / 52,611,490 / 52,636,653 measured directly; block 52,603,591 timestamp computed from block delta at 2.0 s/block.
- USD marks: GoldRush snapshot (23:31:55Z) vs BaseScan ($66,173.29). IMO drain converted with DefiLlama $0.5541715438910414 → ≈ $111,276 (GoldRush price would give ≈ $111,204).
- Schedules 836/840/843/846 are uncancelled but non-manipulable (non-soft/non-topable, fully released) — not a residual extraction path.
- Base secondary could not be tied to a specific deployment block; found via deployer enumeration.
- No write transactions were sent; no keys used.
