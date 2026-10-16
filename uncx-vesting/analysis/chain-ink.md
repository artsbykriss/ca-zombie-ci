# UNCX Vesting V2 — Ink (chain 57073) incident & residual-exposure report

**Scope:** Ink main VestingManager `0xF28704c691290547924e2129D407dA36bda8ce0f` (an **18,433-byte build** — not the standard 18,010-byte main; deployed by a different creator `0x4401E39b18Fb46E346e9B7883D4B5C82fb803b4d`), incident window Oct 14 00:00 UTC → Oct 16 00:00 UTC (window start block 58,437,589). State reads at block 58,618,278 (2026-10-16 ≈02:18 UTC); balances at block 58,615,073 (01:18:04 UTC). Read-only analysis; public RPCs and public APIs only.

## Headline numbers

| Item | Value |
|---|---|
| Incident-window activity | **0 creations, 0 top-ups, 0 cancels, 0 releases** — no attacker activity on Ink |
| Containment events in window | 3× `FlatFeeUpdated`, 2× `FeePercentageUpdated`, 3× `CreatorFeeExemptionUpdated` (all removed) |
| Live manipulable schedules (soft+topable, uncancelled) | **0** — no `isTopable=true` schedule has **ever** been created on Ink |
| Cumulative top-ups ever (`VestingToppedUp`) | **0** |
| Current extractable residual | **$0.0004** (USDT0 dust) |
| Secondary 14.4 KB build | **None exists** on Ink (deployer nonce 0; main built by a different creator) |
| Attacker addresses (ETH/BSC exploit) | 0 nonce, 0 balance; never a creator/beneficiary here |

## Main contract live state (block 58,618,278)

| Field | Value |
|---|---|
| Code size | **18,433 bytes** — a distinct build (storage layout differs from the standard mains; all state read via public getters) |
| `nextVestingId` | 2 (ids 0 and 1 only; both Oct 7–9, 2026) |
| `feePercentage` | 500 (= 5%; was 10 = 0.1% before Oct 14) |
| `flatFee` | `uint256.max` (creation effectively disabled; all 3 fee-exempt creators were removed Oct 15) |
| `owner` | `0x31c44A17aa2E639B40f33DA805CB1DB55d969693` (Gnosis Safe, same across all chains) |
| `feeCollector` | `0xD45dD91DF475bFD944335160f538c1A14888DC1C` |
| Native balance | 0 |

## Token balances (snapshot 2026-10-16 01:18:04 UTC, blk 58,615,073)

| Symbol | Contract | Dec | Balance | Price USD | Value USD |
|---|---|---|---|---|---|
| USD₮0 (USDT0) | 0x0200c29006150606b650577bbe7b6248f58470c1 | 6 | 417 raw (= 0.000417) | 0.9987 | $0.0004 |
| **Total** | | | | | **$0.0004** |

(USDT0 is Tether's omnichain token — **6 decimals**; 417 raw = $0.0004, not $417.)

## Containment timeline (Ink)

Ink is the newest deployment of the six (first fee event 2026-10-05; first schedule Oct 7):

1. **2026-10-05 13:29:06** — initial fee setup: `flatFee` 0.05, `feePercentage` 10.
2. **2026-10-07** (blks 57,866,575–78) — ops granted creator fee exemptions to `0xa4068dcb…`, `0x037287a8…`, `0x7618283e…` (3 txs `0xbc5b9555…`, `0xdc83f1bc…`, `0x39419dee…`).
3. **2026-10-14 17:01:04** (blk 58,498,853) — containment step 1: `flatFee` → 1e22 wei = 10,000 ETH (tx `0x643cadc1…`, sender `0x85bd8ebf…` → owner Safe — note: on Ink even the *first* raise came from the ops Safe, unlike other chains).
4. **2026-10-14 21:17:53** (blk 58,514,262) — containment step 2: `flatFee` → 1e25 wei = 10,000,000 ETH + `feePercentage` → 500 (tx `0x4d23eff6…`).
5. **2026-10-15 11:14:12** (blk 58,564,441) — containment step 3: `flatFee` → `uint256.max` + `feePercentage` 500 + **removed all 3 creator exemptions** (tx `0x969a1e6e…`).

**No other events occurred in the window** — no creations, top-ups, cancels or releases.

## Live manipulable schedules (critical output)

**None.** Full-history decode: only **2** `VestingCreated` events exist on Ink — ids 0 and 1, created and (partially) released by fee-exempt creator/beneficiary `0xa4068dcb…` on **Oct 7–9 (before the incident window)**:

| id | Created | Flags | Released |
|---|---|---|---|
| 0 | 2026-10-07 15:24:46 UTC (blk 57,888,275) | soft, **non-topable**, transferable | 583 raw = 0.000583 USDT0 (Oct 9 12:00:35) |
| 1 | 2026-10-09 08:56:37 UTC (blk 58,037,786) | soft, **non-topable**, transferable | 100,000 raw = 0.1 USDT0 (Oct 9 12:00:28) |

- No schedule on Ink has ever been topable; `topUpVesting()` reverts **`NotTopable` (0x3813f790)**; zero `VestingToppedUp` events.
- Both schedules were created *while the creator was fee-exempt* (a benign ops/partner pattern — the same address was also exempted on Unichain and Base and de-exempted during containment there).
- **Residual extractability = $0** (post-release pool = $0.0004).

## Secondary build: none found

The standard 14.4 KB secondary does **not exist on Ink**: the UNCX deployer (`0x90cf3e1f…`) has nonce 0 on Ink, and this main contract was deployed by a different creator (`0x4401E39b18Fb46E346e9B7883D4B5C82fb803b4d`). No other plausible secondary build was found. **No secondary-exposure question arises on Ink.**

*(Contrast: every other chain of the six has a 14,391-byte secondary; Ink's absence is itself a differential finding.)*

## Confidence / caveats

- Full-history events via the Ink explorer (`explorer.inkonchain.com`) + direct RPC (`rpc-gel.inkonchain.com`); balances via on-chain `balanceOf`; block timestamps read directly from chain.
- The 18,433-byte build was read only via public getters (storage layout differs from the standard mains) — no raw-slot claims made.
- USD marks: DefiLlama 2026-10-16 ≈01:50 UTC (ETH $2,431.50); USDT0 $0.9987 (DexScreener, $1.64M liq).
- Releases on Ink (0.1 and 0.000583 USDT0) are within normal soft-schedule behavior and pre-date the incident.
- No write transactions were sent; no keys used.
