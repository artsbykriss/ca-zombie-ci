# Z3-C1 deep-dive — UNCX Network "Vesting V2" (shared-pool share-accounting desync)

**Date:** 2026-10-16 (reads at ETH block 26,201,400 · BSC 127,874,818 · Base 52,659,814)
**Chains:** Ethereum, BNB Chain, Base, Robinhood Chain, Polygon, Unichain, Arbitrum, Avalanche, OP Mainnet, Ink
**Status:** read-only research · PoC fork-verified only (11/11 CI tests) · **no transactions signed or sent to any network** · no secrets in this folder
**CI:** https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38841672140 (success, 11/11 tests; earlier runs 38826471606, 38829097636)

---

## 1. TL;DR

| Target | Live extractable (unprivileged, fresh attacker) | Why closed / open | Latent risk |
|---|---|---|---|
| ETH main `0xa98f06…` | **$0** | flatFee = `uint256.max` (creation impossible); all 42 incident schedules drained (0 claimable); no live soft+topable schedule; no fee exemptions remain | owner can lower flatFee → one tx re-arms the immutable bug; new deposits into share-corrupted pools are traps |
| BSC main `0x7f3f9f4E…` | **$0** | flatFee = 35,000 BNB (≈$25.5M); all 355 incident schedules are cancelled or fully released (**0 live soft+topable**, verified by direct scan of ids 640–994), pool = 4.2e-8 BTCLE dust | `_totalTokenShares[BTCLE]=216,115` anomalous but no live claimant found — monitor future BTCLE deposits |
| Base main `0x7ca3dE7D…` | **$0** | flatFee = `uint256.max`; all 13 incident schedules cancelled/fully released; 0 live manipulable | owner-parameter re-arm |
| Robinhood `0xB31eAE…` | **$0** | flatFee = 1e25 wei (10k native); 42 schedules cancelled; 1 live soft+topable schedule with `totalAmount=0` (release reverts); attacked RKST pool share-corrupted (stuck) | owner-parameter re-arm; RKST ~$36.5k stuck (S) |
| Polygon / Unichain / Arbitrum / Avalanche / OP / Ink (main) | **$0** | same code, contained parameters; **no `isTopable=true` schedule has ever existed on these chains** (top-up/cancel structurally impossible); pools dust ($1.16 Unichain, $0.25 AVAX, $0.0016 Polygon, $0.0004 Ink, $0 OP) | owner-parameter re-arm; 2 fee-exempt creators still live on the AVAX/Arbitrum secondaries |
| Secondary 14.4 KB builds (ETH `0xBcD6aee8…`, BSC `0xEc76C87E…`, Base `0xcb08b6d8…`) | **$0** | **code is exploitable end-to-end (fork-proven)** but flatFee = 100 ETH / 100 BNB per attack (min 1 flat fee) vs pools of $4.73 / $1.34 / $0.03 | if fees are lowered or a pool >~$400k accumulates, the recipe works |

**Total live extractable by an external unprivileged attacker now: $0.00 (high confidence).**
Residual value still in the contracts is **holder-recoverable (H-O)**, not attacker-extractable:
≈ **$134k–$257k hard** (ETH $66–124k + Robinhood $60–118k + Polygon FCAR $7.5–15k; liquidity-bounded; $1.09M–$3.98M ETH paper) + ≈$45.7k–$68.5k nominal on BSC/Base + ~$36.5k stuck (S) + dust on the remaining L2s.

---

## 2. The bug — exact mechanism (validated against the real exploit tx)

Deployed code (verified source, solc 0.8.27, non-proxy, immutable): `VestingManager.sol`
`contracts/VestingManager.sol` — `0xa98f06312b7614523d0f5e725e15fd20fb1b99f5` (ETH) and the identical 18,010-byte build on 8 other chains. `VestingCalculator` = `0xa878f580CCA386DCee5226b7C3D455e35f62aaC4` (ETH).

The contract is a **shared vault per token**: one balance holds every project's allocations; each schedule gets "shares" priced by
`_shareRatio[token] = (totalShares+1)e18/(balance+1)` (refreshed at the start of `createVesting`, `topUpVesting`, `release`).

```
release(id): rel = D·V/T − released;  amount = rel · balance / totalShares     (pays pro-rata of the SHARED pool)
cancel(id):  vestedShare = V · D / T;  sharesToRemove = D − vestedShare         (NO − released term!)
             refund = T − V to creator;  D := vestedShare;  totalShares −= sharesToRemove
```
`V` is the calculator's *raw* vested amount (tranche amounts are **gross**, `T` is **net of the 0.1% token fee**).

**Desync:** `cancel()` removes `D − V·D/T` shares while refunding `T − V` tokens → shares removed per token refunded = **D/T**, but the pool's fair ratio is **S/B**. Whenever `D/T > S/B` the cancel *over-reduces* global shares; every remaining share is then worth more, and a second attacker-controlled schedule ("receiver") can release and over-claim the whole pool.

The attacker manufactures `D/T > S/B` by **donating tokens directly** to the contract (balance ↑, shares unchanged → `S/B` ↓) *after* their schedules' shares were minted at the pre-donation ratio. The validated integer model (`analysis/sim_exploit.py`) reproduces the real EDGEN leg **exactly** (all five payment amounts and the final `S=17,572,899`, `B=32,941,964,644` wei).

**Real exploit (ETH, block 26,191,745, tx `0x35206537…23823d`, attacker `0x78c9b118…a2f5b3`, helper contract `0x6cebdf09…1f26c`):**
flash-swapped EDGEN from the token's V2 pair → created 11 schedules (ids 5058–5068) in 5 tokens (EDGEN/ZC/pepecoin/LO0P/PAAL) → 26 top-ups → 11 releases → 6 cancels → 1 receiver release drained each pool to dust. EDGEN: pool 57,344,850.92 → 3.29e10 wei dust; attacker net +107.07M EDGEN, of which **57.34M was other holders' money** (the donation was recovered).

**Knife-edge property (important for re-arming):** profitability depends on exact integer rounding. Of ~140 parameter combinations searched with the faithful model, only the EDGEN-ratio family (and its ×0.999 variant) is solvent+profitable; the same recipe at nearby ratios is a *loss*. An attacker must simulate and tune; the copycats did (4 more drain txs on ETH, incl. token `0x140007c655…` and two ZC rounds).

---

## 3. Live-state assessment (every number on-chain, explicit blocks)

### 3.1 Ethereum main — `0xa98f06312b7614523d0f5e725e15fd20fb1b99f5` (block 26,201,400)
- 18,010 bytes code, not a proxy, no pause/sweep. `nextVestingId` = **5100**, `owner` = `0x31c44A17aa2E639B40f33DA805CB1DB55d969693`, `feeCollector` = `0xD45dD91DF475bFD944335160f538C1A14888DC1C`, calculator `0xa878f580…`.
- **Containment timeline (owner txs):** flatFee 0.05 ETH → **100 ETH** (blk 26,192,030) → **10,000 ETH** (26,192,977) → **`uint256.max`** (26,193,348); `feePercentage` 10 → **500 (5%)**; token exemption for `0x78069e97…` removed (26,193,056); 3 creator exemptions removed (26,197,490). **Currently: flatFee = `uint256.max`, feePercentage = 500, zero exemptions** (fork-verified, tests A1/A5).
- **All 42 incident schedules (5058–5099) have claimable = 0** — `_getReleasableShares` = 0 or reverts on underflow (D < released) (fork-verified, test A3). No live soft+topable incident schedule exists.
- Pools after the attack (dust): EDGEN `32,941,964,644` wei; LO0P `6,562,488` wei; PAAL `0`; pepecoin `288.9`; ZC `96,728.7`; copycat token `0x140007c6…` `0`.
- **Untouched pools (holder claims):** 64 token types held; Blockscout-marked total $3.98M nominal, DefiLlama-marked ≈$1.09M, **hard-realizable ≈$66k–124k** (see §5).

### 3.2 BNB Chain main — `0x7f3f9f4ED8987B78adC448a840169A0FD5AFFAAB` (block 127,874,818)
- 18,010 bytes; `nextVestingId` 995; `feePercentage` **500**; `flatFee` **35,000 BNB (3.5e22) ≈ $25.5M**; same owner Safe.
- Attack Oct 14 18:55–19:14 UTC (`0x61671729…c25d` via helper `0x8174eee3…0dec`): **355 schedules (640–994) on BTCLE**, 288 top-up+cancel cycles, siphon schedule 640 (nominal 1 BTCLE) released **194,841.24 BTCLE = the entire pool** → pool now 4.2e-8 BTCLE. **Net theft ≈ $9.2k** (194,841 BTCLE @ $0.0472 DefiLlama — *not* the $969k nominal figure in the incident reports; BTCLE's price and the recycled gross amounts explain the gap).
- **All 355 incident schedules are cancelled or fully released: 0 live soft+topable schedules** (direct on-chain scan of ids 640–994: `soft && topable && !cancelled` = 0). Each has `released == D == T` → claimable 0; pool is dust → **$0 today**. (A child-agent draft reported 66 "live" schedules; that was a decode false-positive — corrected here by direct re-scan.)
- `_totalTokenShares[BTCLE] = 216,115` wei vs pool balance `42,108,114,583` wei — anomalous ratio left by the attack; with no live manipulable schedule and creation blocked, no extraction path was found (monitor any future BTCLE deposit).
- Other holdings: DROPS 74.9M (nominal $1.12M @ GoldRush, BscScan marks ~$0 — conflict flagged), CDT $44.4k, SORA $2.2k… BscScan net worth **$45.7k**.

### 3.3 Base main — `0x7ca3dE7D58A0bCAd115184597553485A919320c5` (block ≈52,659,814)
- 18,010 bytes; `nextVestingId` 849; `feePercentage` **500**; `flatFee` **`uint256.max`**.
- Attack Oct 14 19:48/20:17 UTC: 13 schedules (836–848) on IMO (`0x5a7a2bf9…e1bb`); siphon 836 (nominal 10k IMO) released 280,612.6 IMO; **pool 200,798 → 0.0464 IMO; net theft ≈ $111.3k**. All 10 soft+topable schedules cancelled; **0 live manipulable**; residual $0.
- Other holdings: DOT (usedot) 8.41M ≈ $68.5k (GoldRush) + small.

### 3.4 Robinhood Chain — `0xB31eAEFA2A0bdC53Df6D7a7f0f289b6eE1a8AAF3` (block 89,634,103, RPC `rpc-robinhood.blockmachine.io`)
- **26,673-byte build** (different, larger variant); `nextVestingId` 193; `flatFee` **1e25 wei**; `feePercentage` **500**; same owner/feeCollector.
- 193 schedules read: 32 token types; 137 soft; **42 cancelled** (the Oct-14/15 attack); 1 live soft+topable (id 125) with `totalAmount = 0` → `release()` reverts (division by zero) — not usable; 5 ids unread (RPC glitch).
- **The RKST pool (the attacked one) is share-corrupted: `totalShares = 2.2e22` but the three live schedules alone hold `D = 6.66e25` shares** → any `release()` computes `rel·B/S > B` and reverts → **the 19.95M RKST residual (~$36.5k) is stuck (S)**. CASHCAT pool = dust (442,131,209 raw @18dp).
- **Untouched RH pools are healthy (density 1:1) and fully holder-claimable (H-O):** AGE 834.86M (2 live non-soft schedules = the whole pool; paper $1.69M @$0.002021, deepest pool $130.6k → hard ≈$33–65k), SLEUTH 495.8M (paper $186.6k, pool $78.3k → hard ≈$20–39k), ASI 600M (paper $60.5k, pool $27.9k → hard ≈$7–14k). HBF/GWOOD/GENIE/DIMEZ/UNUS/FIRE have no DEX pairs → $0 hard.
- Hard residual on RH ≈ **$60–118k (H-O)** + ~$36.5k stuck (S).

### 3.5 Other main deployments (all 18,010-byte build; all contained)
**Structural finding (L2 chains):** on Unichain, Avalanche, Polygon, Arbitrum, OP and Ink **no schedule with `isTopable=true` has ever been created** — verified for Unichain (1,439 creations decoded → 0 topable) and across 12,500+ creation events decoded by the L2 sweep (child agent). `topUpVesting()` reverts `NotTopable` on every sampled id; zero `VestingToppedUp` events exist on any of these chains. The exploit's top-up/cancel cycle is therefore **structurally impossible** there, independent of the fee containment. (Contrast: ETH/Base/RH/BSC all had topable schedules, including the attackers'.)
| Chain | Address | nextId | flatFee | fee% | Pool residual |
|---|---|---|---|---|---|
| Polygon | `0x09e9f68F72917984e333BD2E18Adae5fAFf97587` | 4,285 | 2.523e26 wei (252.3M POL ≈$24.1M) | 500 | USDC $0.0016 + FCAR 2,001 (paper $37.1k, pool $30.1k → hard ≈$7.5–15k) + 3 no-pair tokens; secondary `0x88a98dc6…` (nextId 103, flatFee 10,000 POL, $0.001) |
| Unichain | `0x3dd1e6c7F905322136E5DF5ECf638059877E0a20` | 1,439 | `uint256.max` | 500 | **$1.16 USDC** + 10,500 VST ($0) + 0.92 DAI; secondary `0x8c1678ba…` (nextId 1,817, flatFee 100 ETH, $1.02) |
| Arbitrum | `0x7f3f9f4ED8987B78adC448a840169A0FD5AFFAAB` | 626 | 1e25 wei | 500 | **$0.005 USDC** (all 626 schedules on Arbitrum USDC `0xaf88d065…`); secondary `0xE02514F7…` (nextId 2,236, flatFee 100 ETH, $0.50, **2 fee-exempt creators still active**) |
| Avalanche | `0x586FEfeeFA117cEC8f32a6B2a0ABEE443315eb87` | 729 | `uint256.max` | 500 | **$0.25 USDC** + 225.7 of one token; secondary `0x2Ba0cb11…` (nextId 954, flatFee 1,000 AVAX ≈$9.97k, $0.11, **2 fee-exempt creators still active**) |
| OP Mainnet | `0x2Ba0cb1153f10d2A95E16e0581324244b9227dDB` | 0 | 1e25 wei | 500 | **$0** (never used); secondary `0xAd2071A3…` (nextId 501, all soft/non-topable, $5.05 USDC) |
| Ink | `0xF28704c691290547924e2129D407dA36bda8ce0f` | 2 | `uint256.max` | 500 | **$0.0004** USDT0 (18,433-byte different build, different deployer; no secondary exists) |

### 3.6 Secondary 14.4 KB deployments (older build, same vulnerable math)
| Chain | Address | code | nextId | flatFee | fee% | Pool |
|---|---|---|---|---|---|---|
| ETH | `0xBcD6aee8D104Dd6F1985686bF294cE9Ed2269CAF` | 14,392 B | 243 | **100 ETH ≈ $400k** | 10 (0.1%) | **$4.73 USDC** |
| BSC | `0xEc76C87EAB54217F581cc703DAea0554D825d1Fa` | 14,391 B | 1,303 | **100 BNB ≈ $72.8k** | 10 | **$1.34** (0.5 CAKE + 0.22 USDC) |
| Base | `0xcb08b6d865b6dE9a5ca04b886c9cECEf70211b45` | 14,391 B | 1,101 | **100 ETH ≈ $244k** | 10 | **$0.03** |
| Unichain | `0x8c1678ba864f1e113027f40eb3aee082d81ef67d` | 14,391 B | 1,817 | **100 ETH** | 10 | $1.02 |
| Arbitrum | `0xE02514F79440922Fa013C2Ee887d5bc76416B209` | 14,391 B | 2,236 | **100 ETH** | 10 | $0.50 · **2 exempt creators** |
| Avalanche | `0x2Ba0cb1153f10d2A95E16e0581324244b9227dDB` | 14,391 B | 954 | **1,000 AVAX ≈$9.97k** | 10 | $0.11 · **2 exempt creators** |
| Polygon | `0x88a98dc689e85b42daf70a065d03151c09659710` | 14,391 B | 103 | **10,000 POL** | 10 | $0.001 |
| OP | `0xAd2071A3021a118A92E95328A6D12bEE0E1C5D8d` | 14,391 B | 501 | **100 ETH** | 10 | $5.05 |

**Residual fee exemptions (verified by storage, slot 19):** `0x037287a8844835e663c392d7f86eb2dbf2a14a98` and `0x7618283e4d27c1cdca572b791b499e4de9d9954a` remain fee-exempt on the **Avalanche and Arbitrum secondaries** (not on the mains, not on ETH/Base). An exempt key can create schedules free of the flat fee; both secondaries' pools are dust ($0.11/$0.50) and no topable schedule exists there → no economic upside today, but it is the one incomplete part of the containment's "remove fee-exempt clients" step (monitor).

Source-diff vs the main build: identical `cancel/release/topUpVesting/_getReleasableShares/_updateShareRatio` math; only bulk entry points and a per-tx `_flatFeePaid` flag differ (no fee bypass — the flag is reset at the start of every external create).

---

## 4. What an attacker can / cannot do (fresh-attacker standard)

**Cannot (fresh attacker, today):**
1. **Create a schedule on any main deployment.** `createVesting`, `createDailySoftVesting`, `createAirdropVesting` all require `msg.value ≥ flatFee`; flatFee is `uint256.max` on ETH/Base/Unichain/AVAX/Ink (1.16e77 wei — unpayable) and 35,000 BNB / 252.3M POL / 10M ARB/OP / 1e25 RH (all ≥$25M). Fee exemptions are empty (ETH fork-verified; BSC/Base/RH verified in child reports). No creation ⇒ the exploit's prerequisite is absent.
2. **Use someone else's schedule.** `cancel`/`topUp` require `creator == msg.sender`; `release` pays the beneficiary. Existing victims' schedules cannot be manipulated by a third party.
3. **Re-manipulate the incident schedules.** All soft+topable schedules on ETH/Base are cancelled (top-up/cancel revert `VestingAlreadyCancelled`, fork-verified). On BSC all 355 incident schedules are cancelled or fully released (0 live soft+topable; pool is dust).
4. **Profit on the secondary deployments.** The recipe is proven to work end-to-end against live secondary bytecode (fork PoC, §6), but an attack needs ≥1 flat fee: **100 ETH / 100 BNB** vs pools of **$4.73 / $1.34 / $0.03**. Not viable by ~5 orders of magnitude.

**Could (preconditions, if state changes):**
- If the owner lowers `flatFee` (or re-adds an exemption), **the bug is still in the immutable code** and any pool with value becomes drainable again with the same recipe (cost: 1 flat fee via `createAirdropVesting` with ≥3 soft+topable beneficiaries — one flat fee per call).
- On BSC, the BTCLE pool's `_totalTokenShares` is anomalous (216,115 wei vs 4.2e10 wei balance) but **all schedules are cancelled/fully released — no live claimant was found**; monitor any future BTCLE deposit into `0x7f3f9f4E…`.
- On ETH, deposits into pools whose share state was corrupted (EDGEN/ZC/pepecoin/LO0P) should be treated as at-risk: the pool's `S/B` ratio is broken and a future depositor's shares are mispriced.

**Attack recipe (fork-proven, exact):** 3 schedules (1 receiver created pre-donation + 2 soft/topable manipulators) → release both manipulators → **donate** tokens to the contract → `topUpVesting` each manipulator to a tuned cumulative target `F` → `cancel` both → `release` the receiver (captures the concentrated pool). Minimum cost = **1 flat fee** (one `createAirdropVesting` call, 3 beneficiaries, all soft+topable). Capital (donation + top-ups) is flash-swappable from the token's own V2 pair (the real attacker did exactly that).

---

## 5. Residual value — paper vs hard (H-O, not attacker-extractable)

ETH main holdings, priced 2026-10-16 (DefiLlama/Blockscout rates; DexScreener depth for the realizable bound). Realizable bound = 25–50% of the deepest ETH pool's liquidity (a sale of that size already moves the price several-fold); amounts with no DEX pair are $0 hard.

| Token | Held | Paper (DefiLlama) | Deepest pool depth | Hard-realizable bound |
|---|---|---|---|---|
| AXGT `0x6112C3…` | 125.70M | $806k | $133,265 (AXGT/WETH 1%; vol $4.5k/24h) | **$33k–66k** |
| TCT `0xE9db0A…` | 52.845M | (no llama) $80.5k (BS) | $32,301 | **$8k–16k** |
| AXGT2 `0xDd6678…` | 95M | $217k | $68,557 (AXGT/WETH 1%; **vol $0/24h**, indexed by GeckoTerminal only) | **$17k–34k** |
| BOBINA | 700k | $4.9k | $26,679 | $4.9k |
| UPEG | 10.0 | $2.3k | $168,140 | $2.3k |
| ZC | 96,728 | $320 | $213,488 | $320 (over-subscribed, see below) |
| SC | 50M | $260 | $6,263 | $260 |
| PEPECOIN | 288.9 | $40 | $1.79M | $40 (over-subscribed) |
| VEK | 250M | $2.5M (BS) / no llama | no pair | **$0** |
| OXN | 807.5M | $337k (BS) | no pair | **$0** |
| RBR | 9.995M | $3.6k (BS) | no pair | **$0** |
| ~50 other tokens | — | ~$0 | — | ~$0 |
| **Total** | | **$1.09M–$3.98M paper** | | **≈ $66k–124k hard** |

These balances are claimable **pro-rata by the legitimate schedules' beneficiaries** (H-O) — the AXGT/AXGT2 pools were never attacked (density still 1:1) and no attacker schedule exists for them. Cross-chain H-O: **Robinhood AGE/SLEUTH/ASI ≈$60–118k hard** (healthy pools, 5 live non-soft schedules hold the whole pools); Base DOT ≈$68.5k nominal; BSC BscScan net worth ≈$45.7k (DROPS $1.12M nominal is marked ~$0 by BscScan — treat as unverified); Unichain/AVAX/Arbitrum/Ink ≈ $1.16 / $0.25 / $0.005 / $0.0004; Polygon adds FCAR ≈$7.5–15k hard (paper $37.1k).
**Stuck/over-subscribed (S):** the RH RKST residual (~$36.5k; live schedules hold D=6.66e25 vs totalShares=2.2e22 → release reverts) and the ETH attacked pools (EDGEN/ZC/pepecoin/LO0P/PAAL — share state corrupted by the attack; the pools are over-subscribed, so releases revert once the small remaining balance is exhausted).

---

## 6. PoC / fork verification (CI, 11/11 PASS)

**Run:** https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38826471606 — `forge test -vvv`, **11 passed, 0 failed** (logs in `ci-log.txt`).
Project: `poc/` (`foundry.toml`, `src/IVestingManager.sol`, `src/MockERC20.sol`, `test/UncxVesting.t.sol`, vendored `lib/forge-std`, `test/data/attack_input.txt` = raw 48 KB calldata of the real attack tx).

| Test | What it proves | Key result |
|---|---|---|
| A1 | live containment params (ETH main) | flatFee=`uint256.max`, fee=500, nextId=5100 |
| A2 | fresh creation blocked on every create entry point (with 1,000,000 ETH!) | revert `InvalidFlatFee` |
| A3 | all 42 incident schedules drained | claimable=0; no live soft+topable |
| A4 | cancelled attacker schedules cannot be re-manipulated | `topUp`/`cancel` revert `VestingAlreadyCancelled` |
| A5 | no fee exemptions remain (3 creators + 1 token) | all false (storage-verified) |
| A6 | residual pools exist for holders | AXGT 125.7M, ZC 96,728.7, PEPE 288.9, EDGEN dust |
| **B1** | **historical replay of the real exploit tx** (fork at 26,191,744, pranked attacker, helper called with the real 48 KB calldata) | post-state matches chain exactly: EDGEN `32,941,964,644` wei, `totalShares[EDGEN]=17,572,899`, ZC `1.893e24`, nextId 5069 |
| **C1** | **secondary 14.4 KB deployment: full recipe end-to-end** (simulated 57.34M-token victim pool) | attacker profit **56.86M tokens**, victim pool → 32.9e9 dust (same shape as the real attack) |
| **C2** | **airdrop variant: one flat fee only** | profit **7.22M tokens** with a single 100-ETH flat-fee call |
| C3 | secondary economics | real pool $4.73 vs 100 ETH flat fee → not viable |
| C3b | secondary bytecode live | 14,391 bytes, same owner |

Supporting off-chain verification: exact integer model `analysis/sim_exploit.py` reproduces the EDGEN and ZC legs to the wei (all payment amounts + final pool state); attack tx decoded event-by-event (`analysis/attack_sequence.txt`, `analysis/attack_transfers.txt`); per-chain state reads and incident schedule scans in `analysis/` (+ `chain-bsc.md`, `chain-base.md`, `rh_*.json`).

---

## 7. Verdict, residual/latent risk, monitors

**Verdict: $0 live extractable by an external unprivileged attacker (high confidence).** The finding was real and is now **closed by owner-set parameters only** — the contract is immutable and permanently buggy. The two independent reasons: (1) schedule creation is economically impossible on every main deployment (astronomical flat fees, zero exemptions); (2) no attacker-controlled soft+topable schedule remains with a positive claim against a funded pool (ETH/Base/BSC fully drained; zero live soft+topable schedules remain anywhere).

**Classification (exact amounts + USD + confidence):**

| Class | Amount (USD) | What it is | Confidence |
|---|---|---|---|
| **E-U** (external unprivileged, fresh attacker) | **$0.00** | no creation possible (flat fees uint256.max / ≥$25M-equivalents; zero exemptions) and no live manipulable schedule with a positive claim on any funded pool | high (fork-verified on ETH; per-chain scans on BSC/Base/RH; source-level on all 18,010-byte deployments) |
| **H-O** (holder-only recoverable) | **≈$134k–$257k hard** ($1.09M–$3.98M ETH paper) | ETH untouched pools (AXGT/AXGT2/TCT/BOBINA/UPEG/…, liquidity-bounded), Robinhood AGE/SLEUTH/ASI, Polygon FCAR; + Base DOT ≈$68.5k nominal, BSC ≈$45.7k (BscScan net worth, uncertain) | medium (paper prices firm; the hard bound depends on DEX depth/price impact) |
| **P** (privileged) | $0 | no privileged extraction path exists; the owner can only change fee parameters (re-arm), not withdraw pools (no sweep/pause function in the code) | high (source-verified) |
| **S** (stuck/bricked) | **≈$36.5k** + ETH attacked-pool dust | RH RKST 19.95M (share-corrupted pool: `release()` reverts) + EDGEN/ZC/pepecoin/LO0P/PAAL residuals (over-subscribed after the attack; dust except ZC ~$320) | medium-high (arithmetic verified from storage) |

**Monitor conditions (in order of materiality):**
1. `FlatFeeUpdated` / `FeePercentageUpdated` / `CreatorFeeExemptionUpdated` / `TokenFeeExemptionUpdated` events on any deployment — a fee reduction or exemption re-opens creation. Watch all 10 main + 8 secondary contracts, **especially the two still-exempt creators on the AVAX/Arbitrum secondaries** (`0x037287a8…`, `0x7618283e…`).
2. `VestingCreated` events on the main deployments — any successful creation while fees are high implies a new exemption/bypass.
3. **Deposits/transfers into pools with corrupted share state** — BSC `BTCLE` (anomalous `totalShares`; no live claimant found) and ETH EDGEN/ZC/pepecoin/LO0P pools (over-subscribed after the attack). New deposits would be priced at a corrupted ratio — monitor.
4. New `VestingCreated`/`TokensReleased` on the secondary deployments — if a pool >~$400k (ETH) / ~$73k (BSC) accumulates, the fork-proven recipe becomes profitable.
5. Owner Safe `0x31c44A17…` (2-of-N) transactions — the containment is one multisig action from reversal.

**Blockers/limitations:** the exploit's profitability is knife-edge in integer rounding (must be tuned per pool); the ETH pools that remain valuable (AXGT etc.) have no attacker schedule and cannot be seeded without paying the flat fee; the realizable value of the residual tokens is liquidity-bounded (paper ≠ hard).

---

## 8. Methodology & sources; caveats; files

**Method:** verified source pulled from Etherscan V2 (main + secondary + calculator); storage-slot mapping verified on-chain (slot 11 `_totalTokenShares`, 12 `_depositedShares`, 15 `_shareRatio`, 16/17/18 fees) and used to read private state at historical and latest blocks via archive RPCs; full event history decoded (VestingCreated/ToppedUp/Released/Cancelled/Fee*), including the containment timeline and copycat txs; per-chain state via public RPCs (BSC/Base/Polygon/Arbitrum/AVAX/OP/Unichain/Ink/RH `rpc-robinhood.blockmachine.io`); token balances via Blockscout/Alchemy-MCP/public RPC; prices via DefiLlama + DexScreener depth; fork tests via Foundry on GitHub Actions (public repo, keyless artifacts). All heavy work ran in CI; local work was RPC reads and small scripts.

**Caveats:** (1) point-in-time reads — re-verify before acting; (2) the "hard realizable" bound is an estimate (25–50% of deepest-pool depth) and depends on the seller's price impact tolerance; tokens without a DEX pair are marked $0 hard even where a nominal mark exists (VEK $2.5M, OXN $337k); (3) the BSC DROPS $1.12M nominal mark conflicts with BscScan (~$0) — treated as unverified; (4) incident-loss headlines ($969k BSC) are nominal/incident-feed figures; our wei-level reconstruction gives ≈$9.2k drained on BSC, ≈$111.3k on Base, ≈$242k ETH (5 tokens) per the attacker's sweeps; (5) 5 RH schedule reads and a handful of L2 reads hit RPC glitches — flagged inline; (6) no audits of UNCX were performed beyond the documented checks.

**Files:** `README.md` (this) · `summary.json` · `analysis/` (source dumps incl. `analysis/source*/`, attack receipt/logs/transfers, `sim_exploit.py` (validated model), state-read scripts, `eth_latest_state.json`, `eth_incident_schedules_residual.json`, `chain-bsc.md/.json`, `chain-base.md/.json`, `chain-unichain.md/.json`, `chain-avax.md/.json`, `chain-polygon.md/.json`, `chain-arbitrum.md/.json`, `chain-op.md/.json`, `chain-ink.md/.json`, `rh_schedules.json`, `rh_balances.json`, `pricing_residuals2.json`) · `poc/` (Foundry project) · `ci-log.txt` + CI run URL · `ci-out/`.
