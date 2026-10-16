# UNCX Vesting V2 — BSC (chain 56) incident & residual-exposure report

**Scope:** BSC main VestingManager `0x7f3f9f4ED8987B78adC448a840169A0FD5AFFAAB` and secondary build `0xEc76C87EAB54217F581cc703DAea0554D825d1Fa`, incident window Oct 14 00:00 UTC → Oct 15 ~23:44 UTC (`2026-10-14T16:51:09Z` first event — `127,629,706` — to `127,876,000`). State reads at **block 127,874,818** (2026-10-15 23:30:38 UTC). Read-only analysis; public RPCs and public APIs only.

## Headline numbers

| Item | Value |
|---|---|
| Attack executed | **Oct 14 2026, 18:55:19–19:14:04 UTC** (blocks 127,646,258–127,648,757) |
| Attacker EOA | `0x61671729bb3fcb7e3cb74ce4b436f467fac5c25d` |
| Attacker helper contract (= creator **and** beneficiary of all schedules) | `0x8174eee3af07c9a695ca363a38dc3190f6dd0dec` |
| Token attacked | **BTCLE** `0x9d2144328e1d618f54cd38540f5ee50671f6a208` (18 dec) |
| Schedules created in window | **355** (ids **640–994**), all BTCLE |
| Cancelled after top-up cycles | 288 |
| Still live soft+topable (uncancelled) | **66** (ids listed below) |
| Gross released (event sums) | 3,380,784.00 BTCLE (recycled capital included) |
| Gross topped up | 2,717,755.14 BTCLE |
| **Pool balance before attack** (block 127,629,700, 16:51 UTC) | **194,640.24 BTCLE** |
| Pool balance just before siphon (127,648,750) | 194,841.24 BTCLE |
| **Pool balance now** | 42,108,114,583 wei = 0.0000000421 BTCLE |
| **Net drained (theft)** | **≈ 194,841.24 BTCLE ≈ $9,188** (BTCLE $0.0471529, DefiLlama) |
| Siphon schedule | id **640** — created with nominal 1 BTCLE total; `TokensReleased(640)` paid **194,841.239999957892933993 BTCLE** (the entire pool) |
| Current extractable residual | **$0** (see "Live manipulable schedules") |

## Main contract live state (block 127,874,818)

| Field | Value |
|---|---|
| Code size | 18,010 bytes |
| `nextVestingId` | 995 |
| `feePercentage` | 500 (= 5%) |
| `flatFee` | 35,000 BNB (3.5e22 wei) ≈ **$25.47M** (BNB $727.62, DefiLlama 2026-10-16 ~00:38Z) |
| `owner` | `0x31c44A17aa2E639B40f33DA805CB1DB55d969693` (Gnosis Safe v1.4.1, threshold 2) |
| `feeCollector` | `0xD45dD91DF475bFD944335160f538C1A14888DC1C` |
| `calculator` | `0xb4123869ca90735Bd2d9847B8A7Dc60c36699dC3` |
| `svgGenerator` (slot 9) | `0xbcbe98bc51674f772374c85a93d3fffcdf1502af` |
| Native balance | 0 |
| `_totalTokenShares[BTCLE]` / `_shareRatio[BTCLE]` | 216,115 / 5,132,383,678,117 (corrupted state) |

## Token balances (snapshot 2026-10-15 23:31:55 UTC)

Source: GoldRush token-balances snapshot (USD by GoldRush), cross-checked via Alchemy and BaseScan/BscScan pages. **Full 53-token list with raw balances is in `chain-bsc.json`.** Top holdings:

| Symbol | Contract | Dec | Balance | Price USD | Value USD | Last transfer |
|---|---|---|---|---|---|---|
| DROPS | 0xff0e7232c902d96b57cc99e52c1056acdd64bd5c | 18 | 74,924,999.999999998085300224 | 0.01496768 | $1,121,453.40 | 2026-05-31 |
| CDT | 0x4c1ad4512f91fd9445204c9c2ff2db32623c2937 | 18 | 409,999.999999999995805696 | 0.10819892 | $44,361.56 | 2026-03-28 |
| SORA | 0xabebed1684a789b3cf178db810f3cbb30cc14444 | 18 | 61,999,999.999999995738587136 | 0.0000355779 | $2,205.83 | 2025-10-20 |
| ENTRV | 0xd6b8e4f8c9f4694ae8e2a9565f7e039307e98b34 | 18 | 251,298,847.558559548376612864 | 0.0000028059 | $705.11 | 2025-10-28 |
| 龙Long | 0xc3c1b25ff8c3f828f36a030960d54082ed984444 | 18 | 20,000,000.000000001811939328 | 0.0000240611 | $481.22 | 2025-10-13 |
| Horizon | 0x5b2ba38272125bd1dcde41f1a88d98c2f5c14444 | 18 | 63,833,574.536029874325291008 | 0.0000041787 | $266.74 | 2025-10-29 |
| Polymind | 0x3365b7833c78d8cd38027e10f3f32c2a42bd4444 | 18 | 31,003,915.710890387995361280 | 0.0000049198 | $152.53 | 2025-10-29 |
| HAVEN | 0x3c06af089f1188c8357b29bdf9f98b36e51f7690 | 18 | 131,231.012856793506952433 | 0.0005958 | $78.19 | 2025-11-27 |
| USDT | 0x55d398326f99059ff775485246999027b3197955 | 18 | 0.10 | 0.9985294 | $0.0999 | 2025-12-12 |
| BTCLE | 0x9d2144328e1d618f54cd38540f5ee50671f6a208 | 18 | 0.0000000421 | 0.0485688 | ~$0 | 2026-10-14 19:14 |
| + 43 dust/memecoin tokens (mostly unpriced) | | | | | | |

Totals: GoldRush total **$1,169,704.68**; **BscScan net worth $45,724.49** (same page). The gap is almost entirely DROPS ($1.12M at $0.01497 — DefiLlama prices DROPS at $0.015027 with 0.99 confidence — but BscScan values it ~0) and CDT ($44.4k, no DefiLlama price). Treat the headline total as a nominal mark; realizable liquidity for DROPS/CDT is unverified.

## Incident detail (BSC)

`VestingCreated` signature: `VestingCreated(uint256 indexed id, address indexed beneficiary, address token, TimeAmount[] tranches, bool isSoft, bool isTopable, bool isTransferable)` — topic1 = id, topic2 = beneficiary. Creator = tx sender.

1. **16:51:09 / 16:53:38 UTC** — two UNCX-ops `FlatFeeUpdated` events (blocks 127,629,706 / 127,630,460; values not captured). Not part of the attack.
2. **18:55:19–18:55:51 UTC** — the attack's phase 1: **355 schedules created and immediately released** in ~11 txs from `0x6167…c25d` via helper `0x8174…0dec`. Each tx creates a batch of soft+topable schedules and calls `release()` on each right after creation. Schedule **640** (the future siphon) is created first with a nominal **1 BTCLE** total and deliberately NOT released.
   - Blocks/txs: `127,646,258` `0xf2c567f9…` (ids 640–656+); `127,646,273` `0xc551a109…`, `0x58b0dbca…`; `127,646,290` `0x57abe906…` (893–928), `0x81d164db…` (929–940), `0x454f1f5f…` (941–976), `0xcc25bd99…` (977–994).
3. **19:12:48 UTC** — `0x4c80d009…`: topUp+cancel wave (ids ~775–835).
4. **19:14:04 UTC** — `0xbb297797…` (ids 836–897), `0xaf55d0b7…` (binary-search probe schedule ids 943–990, power-of-two amounts 2^24…2^71), each topUp followed by cancel → `_totalTokenShares[BTCLE]` progressively over-reduced.
5. **19:14:04 UTC** — **`0xbd1b49a2…`: `TokensReleased(640)` = 194,841.239999957892933993 BTCLE** — the siphon, exactly the whole pool balance.
6. **20:06:34 UTC** — UNCX containment: `TokenFeeExemptionUpdated(BTCLE, false)` (`0x516f6e46…`; BTCLE had been fee-exempt, so the attack paid no fees).
7. **21:13:30 UTC** — UNCX containment: `FlatFeeUpdated(35,000 BNB)` + `FeePercentageUpdated(500)` (`0xf46762f5…`).
8. Post-attack, funds were swapped/exited to USDT and through aggregator `0x6131b5fae19ea4f9d964eac0408e4408b66337b5` (till ~20:23 UTC); last attacker EOA action seen in the enumeration at block 127,654,228.

Releases paid include the direct over-claim: schedule 640 with a 1 BTCLE total returned 194,841 BTCLE. (For Base, the analogous direct over-claim is schedule 836, see chain-base.md.)

## Live manipulable schedules (critical output)

**66 schedules** satisfy `isSoft=true AND isTopable=true AND cancelled=false` at latest state — all BTCLE, all creator=beneficiary=`0x8174eee3af07c9a695ca363a38dc3190f6dd0dec`:

`898–942, 948, 953, 958, 959, 961, 964, 967, 968, 971, 972, 973, 975, 977, 978, 979, 980, 987, 991–994`

- **Current claimable: 0 for every one of them.** For each, `released == _depositedShares == totalAmount` (verified per-schedule; e.g. 898: D=R=T=10,556.844312288930193711 BTCLE; 942: 4,722.366482869645213696; 994: 0.000001048576). `release()` would revert with `NoTokensToRelease`.
- **Pool state now:** `_totalTokenShares[BTCLE] = 216,115` wei, `shareRatio = 5,132,383,678,117`, `balanceOf(pool) = 42,108,114,583` wei (4.2e-8 BTCLE ≈ $2e-9).
- **Residual extractability today ≈ $0.**
- **Latent hazard (state corruption):** these 66 schedules remain topable and soft. If the BTCLE pool is ever refilled (donations, new vesting deposits), the helper can top-up + release against the corrupted `_totalTokenShares` (216,115 wei) and claim approximately the entire new balance. Recommendation: do not deposit BTCLE into `0x7f3f9f4E…` until patched.

Also present: 9 soft+cancelled+topable schedules and 56 `s0t1c0` (topable-only) leftover probes — not exploitable (cancel requires soft).

## Secondary 14.4 KB build (`0xEc76C87EAB54217F581cc703DAea0554D825d1Fa`)

| Field | Value |
|---|---|
| Code size | 14,391 bytes |
| `nextVestingId` | 1303 |
| `feePercentage` | 10 (= 0.1%) |
| `flatFee` | 100 BNB ≈ **$72,762** |
| `owner` | same Safe `0x31c44A17…9693` |
| `feeCollector` | same `0xD45dD91…DC1C` |
| `calculator` | `0xE02514F79440922Fa013C2Ee887d5bc76416B209` |
| Balances | Cake 0.5064 ($1.12) + USDC 0.2201 ($0.22) = **$1.34** (GoldRush 23:32Z; Alchemy confirms 2 tokens; BscScan $1.84) |
| Incident window events | **0** (none between 127,450,000–127,876,000) |
| Schedule scan | 1303/1303 read; **soft+topable+not-cancelled = 0** |

**Verdict:** a fresh attacker would need to pay 100 BNB (~$72.8k) and there is no manipulable schedule; pool value $1.34 is ~54,000× smaller than the fee. **Not viable.**

## Confidence / caveats

- Window event capture: 1000-block chunking on a public archive RPC (thirdweb); the full Oct-14→Oct-15 event stream for both BSC managers was captured; per-id creation association was reconstructed for the core attack range via a targeted rescan. Two pre-attack `FlatFeeUpdated` values (16:51/16:53) were lost when a raw output file was cleaned up (they are owner ops, not attacker actions).
- The 66 "live manipulable" schedules are a **latent-hazard** finding, not a live $-extraction finding: claimable = 0 and the pool is empty.
- USD marks: GoldRush snapshot 23:31:55Z vs BscScan net worth $45.7k — see balances section; do not treat the $1.17M total as liquid value.
- BTCLE net-drain conversion $9,188 uses DefiLlama $0.04715288599160382; with GoldRush's $0.04857 it is ~$9.46k.
- No write transactions were sent; no keys used.
