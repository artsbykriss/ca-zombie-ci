# Radworks (Radicle) — live governance capture of a **$14.40M** timelock (+$0.36M Drips admin), no guardian

**Date:** 2026-10-20 · **Chain:** Ethereum mainnet · **Status:** read-only; all state changes are local-fork only; no mainnet transaction was signed or sent.
**Fork block:** 26,229,556 · **Latest re-check:** 26,229,853 · **PoC:** 8/8 tests PASS in GitHub Actions ([run 39340625186](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39340625186)).

---

## TL;DR

| Item | Value |
|---|---|
| **Target** | `RadworksGovernor` [`0xD64D01D04498bFc60f04178e0B62a757C5048212`](https://etherscan.io/address/0xD64D01D04498bFc60f04178e0B62a757C5048212) + Compound timelock [`0x8dA8f82d2BbDd896822de723F55D6EdF416130ba`](https://etherscan.io/address/0x8dA8f82d2BbDd896822de723F55D6EdF416130ba) |
| **Governance token** | RAD [`0x31c8EAcBFFdD875c74b94b077895Bd78CF1E64A3`](https://etherscan.io/token/0x31c8EAcBFFdD875c74b94b077895Bd78CF1E64A3) |
| **Treasury (timelock)** | **40,922,601.104474 RAD + 319,133.030979 USDC + 59.9 WETH + 500,000 GTC + 0.09816 ETH + 99.9958% of the Uniswap V2 RAD/USDC LP (3,788,431.42 RAD + 1,079,429.13 USDC)** |
| **Corrected treasury USD** | **$14,396,924** at RAD $0.283506 / ETH $2,407.95 / GTC $0.356086 (block 26,229,556) |
| **Additional admin-controlled value** | **Drips core + 4 drivers**: `Drips` proxy admin = timelock; Drips TVL ≈ **$363,248** |
| **Gross attacker-accessible** | **≈ $14,760,172** |
| **Live E-U (net, central)** | **≈ $3.0M** (range **$1.4M–$5.2M**); up to **≈$4.5M** if unopposed; **≈$0.1M–$1.4M** if Drips + core delegates oppose |
| **Capital required** | **$1.3M–$2.5M** for the 4M-RAD unopposed path; **$4M–$6M** if the attacker must outvote ~11.3M RAD |
| **Why open** | No guardian, no veto, no security council; timelock admin = governor; `RAD.delegates(timelock) = 0x0` so the treasury cannot vote; proposal path is fully permissionless |
| **Main blocker** | Voluntary delegate opposition: **Drips 7,105,352 RAD** + core voters ≈4.2M RAD. The 4M quorum is not enough in a contested vote |
| **Verdict** | **KEEP AS CRITICAL (E-U)** — mechanically open and fork-proven; economics are contested-scenario dependent |

### Corrections to the pass-2 brief (important)

1. **The treasury is $14.40M, not $11.98M.** The brief missed the timelock's **99.9958%-owned Uniswap V2 RAD/USDC LP** (`0x8C1c499b1796D7F3C2521AC37186B52De024e58c`: 3,788,431 RAD + 1,079,429 USDC, **$2.15M**), **500,000 GTC** (**$178k**), and **59.9 WETH** (**$144k**). The direct RAD + USDC alone was $11.92M.
2. **The 4M RAD quorum is not the attack cost in a contested vote.** The incumbent delegate bloc is **Drips 7.105M + core delegates ≈4.2M = ≈11.3M RAD** (up to ~11.7M if 0xea95/0xcaa3 also vote No). A hostile proposal must outvote them, not merely reach quorum. The brief's "if Drips votes No, the attacker needs >7.1M RAD" undercounts the core delegates by ~4.2M.
3. **The brief's $3.5M–$6M net is the unopposed / 50–70%-haircut case.** It is achievable, but a risk-adjusted estimate that includes the plausible contested scenarios is **≈$3.0M central (range $1.4M–$5.2M)**.
4. **The timelock is also the admin of the Drips protocol** (`Drips` + 4 drivers). The same governance capture can hand Drips admin to the attacker and drain **≈$0.36M** (fork-proven admin handover). This was not in the brief.

---

## 1. The mechanism in exact terms

`RadworksGovernor` is a verified ScopeLift/OpenZeppelin governor (solc 0.8.20, source at Etherscan) with a **constant** quorum and a Compound `Timelock`:

| Parameter | Value | Evidence |
|---|---|---|
| `quorum(block)` | **4,000,000e18 RAD** (constant; the block argument is ignored) | `RadworksGovernor.sol` `QUORUM = 4_000_000e18`; `quorum(0)` and `quorum(26,229,555)` both return `4e24` |
| `proposalThreshold()` | **1,000,000e18 RAD** | on-chain read |
| `votingDelay()` | **7,200 blocks** (~24h at 12s) | on-chain read |
| `votingPeriod()` | **17,280 blocks** (~2.4 days) | on-chain read |
| `timelock()` | `0x8dA8…30ba` | on-chain read |
| Timelock `delay()` | **172,800 s (2 days)** | on-chain read |
| Timelock `GRACE_PERIOD()` | **1,209,600 s (14 days)** | on-chain read |
| Timelock `admin()` | **the Governor** | on-chain read |
| Timelock `pendingAdmin()` | **0x0** (no migration in flight) | on-chain read |
| Guardian / veto / security council | **NONE** | verified source has no guardian/veto; `guardian()`, `veto()`, `securityCouncil()`, `owner()` all revert; only the proposer can `cancel` while Pending |
| Proposals to date | **8** `ProposalCreated` events; last executed **block 24,956,127 (2026-04-25)**; no active proposal now | Etherscan logs + `state()` on all 8 IDs |

**The key weakness:** the timelock's 40.92M RAD is **undelegated**:

```
RAD.delegates(0x8dA8…30ba) = 0x0000000000000000000000000000000000000000
RAD.getPriorVotes(0x8dA8…30ba, block-1) = 0
```

The treasury cannot vote to defend itself. The only entity that can move the treasury is the Governor, and the Governor is controlled by whoever holds ≥4M RAD at a proposal snapshot.

### Exact call path (permissionless)

1. Acquire ≥1,000,000 RAD to propose (threshold); acquire ≥4,000,000 RAD by the snapshot to meet quorum.
2. `RAD.delegate(attacker)` — delegation checkpoint must be at least one block old before `propose()` (`getPriorVotes(proposer, block.number-1)`).
3. `Governor.propose([RAD, USDC, WETH, GTC, PAIR], [0,0,0,0,0], [transfer(...), …], description)`.
4. Wait `votingDelay` = 7,200 blocks → snapshot; `castVote(proposalId, 1)` with the attacker's 4M+ weight.
5. Wait `votingPeriod` = 17,280 blocks; if `forVotes > againstVotes` and `forVotes + abstainVotes ≥ 4M`, the proposal is Succeeded.
6. `queue(...)`; wait the timelock's 172,800 s; `execute(...)`.
7. The timelock calls each target as itself:
   - `RAD.transfer(attacker, 40,922,601.104474e18)`
   - `USDC.transfer(attacker, 319,133.030979e6)`
   - `WETH.transfer(attacker, 59.9e18)`
   - `GTC.transfer(attacker, 500,000e18)`
   - `PAIR.transfer(attacker, 1,198,749.348279e18)` (the LP tokens)
8. The attacker transfers the LP tokens to the pair and calls `burn(attacker)`, redeeming **3,788,431.42 RAD + 1,079,429.13 USDC** (99.9958% of the pool).

**Total time:** 7,200 + 17,280 = 24,480 blocks ≈ 3.4 days, plus 2 days timelock ≈ **5.4–5.5 days**. Gas for the full path in the PoC: **1,449,383** (at 1 gwei / $2,408 ETH ≈ $3.5; at 10 gwei ≈ $35).

### Snapshot-flip nuance (reduces the holding period)

The vote weight is fixed at `proposalSnapshot = proposeBlock + 7,200`. The attacker can sell the 4M RAD at block `snapshot+1` and still `castVote` with the snapshot weight (fork-proven: `test_snapshot_flip_still_votes`). The capital is therefore locked for only ~24h before the snapshot, not the full 5.4 days — but the sale itself moves the thin market, and the attacker still needs the RAD for the eventual dump. This is an economic nuance, not a blocker.

### Secondary path: Drips protocol admin

The timelock is the **EIP-1967 admin** of the Drips `ManagedProxy` [`0xd0Dd053392db676D57317CD4fe96Fc2cCf42D0b4`](https://etherscan.io/address/0xd0Dd053392db676D57317CD4fe96Fc2cCf42D0b4) and four Drips drivers (`NFTDriver`, `ImmutableSplitsDriver`, `RepoDriver`, `AddressDriver`). `Managed._authorizeUpgrade` is `onlyAdmin`; the admin is the timelock. The same proposal can call `Drips.proposeNewAdmin(attacker)`; the attacker then calls `acceptAdmin()` and becomes the Drips admin, able to `upgradeToAndCall` a malicious implementation and drain the Drips contract's tokens.

**Drips TVL at block 26,229,556 ≈ $363,248** (USDC 251,441.26 + WETH 23.5766 + RAD 148,778.00 + USDGLO 3,545.71 + wstETH 1.5053 + WBTC 0.0568 + DAI 712.67 + GTC 945.70 + USDT 366.22 + small). This is fork-proven at the admin level (`test_drips_admin_handover`); the final drain is the standard UUPS upgrade.

---

## 2. Live-state assessment (block 26,229,556; re-checked 26,229,853)

### Addresses and code

| Contract | Address | Code check |
|---|---|---|
| RadworksGovernor | `0xD64D01D04498bFc60f04178e0B62a757C5048212` | verified `RadworksGovernor`, solc 0.8.20; deployed block 20,312,869; not a proxy |
| Compound Timelock | `0x8dA8f82d2BbDd896822de723F55D6EdF416130ba` | `admin()` = governor, `pendingAdmin()` = 0, `delay()` = 172,800 |
| RAD token | `0x31c8EAcBFFdD875c74b94b077895Bd78CF1E64A3` | verified `RadicleToken`, solc 0.7.6; Compound-style `delegates`/`getPriorVotes`; no mint, no pause, no blacklist; `balances` is `uint96` |
| Uniswap V2 RAD/USDC pair | `0x8C1c499b1796D7F3C2521AC37186B52De024e58c` | token0 = RAD, token1 = USDC; `totalSupply` 1,198,800.123004; timelock holds 1,198,749.348279 (**99.9958%**) |
| Drips core | `0xd0Dd053392db676D57317CD4fe96Fc2cCf42D0b4` | `ManagedProxy`; EIP-1967 admin = timelock; implementation `Drips` `0xb0c9b6d67608be300398d0e4fb0cca3891e1b33f` |
| Drips drivers | `0xcf9c…5258` NFTDriver, `0x1212…b774` ImmutableSplitsDriver, `0x7700…373e` RepoDriver, `0x1455…0610` AddressDriver | all `ManagedProxy`, admin = timelock |

### Balances (exact)

```
RAD.balanceOf(timelock)      = 40,922,601.104474020173290301
USDC.balanceOf(timelock)     = 319,133.030979
WETH.balanceOf(timelock)     = 59.900000000000000000
GTC.balanceOf(timelock)      = 500,000.000000000000000000
PAIR.balanceOf(timelock)     = 1,198,749.348279279609   (99.9958% of LP)
ETH.balanceOf(timelock)      = 0.098163434973740509
RAD.totalSupply()            = 99,998,580.000000000000000000
RAD.delegates(timelock)      = 0x0000000000000000000000000000000000000000
RAD.getPriorVotes(timelock)  = 0
```

The pair reserves at the fork block: **3,788,788.968862 RAD + 1,079,531.009208 USDC** (spot $0.28492, total reserve value $2,153,675). The timelock's LP share redeems for **3,788,431.419586904 RAD + 1,079,429.133507 USDC** (fork-proven via `burn`).

### Valuation (block 26,229,556)

| Asset | Amount | Price | USD |
|---|---:|---:|---:|
| RAD (direct) | 40,922,601.1045 | $0.283506 | $11,601,803.75 |
| LP — RAD leg | 3,788,431.4196 | $0.283506 | $1,074,043.11 |
| LP — USDC leg | 1,079,429.1335 | $1.00 | $1,079,429.13 |
| USDC direct | 319,133.0310 | $1.00 | $319,133.03 |
| WETH | 59.9000 | $2,407.95 | $144,235.98 |
| ETH | 0.09816 | $2,407.95 | $236.37 |
| GTC | 500,000 | $0.356086 | $178,042.83 |
| **Treasury total** | | | **$14,396,924.22** |
| Drips core TVL | | | **$363,247.58** |
| **Gross accessible** | | | **$14,760,171.80** |

At the latest re-check (block 26,229,853), RAD $0.28210 / ETH $2,403.13 / GTC $0.35919 → treasury ≈ **$14.33M**; all balances unchanged. Prices are mark-to-market, not liquidation values.

### Circulating / overhang

CoinGecko circulating supply **59,075,979 RAD**; market cap **$16.8M**; 24h volume **$3.136M** (not $5.36M). The attacker's total RAD (direct + LP) is **44,711,033 RAD = 75.7% of circulating** and 44.7% of total supply. A full liquidation is a block/OTC discount, not the spot price.

---

## 3. Voting landscape: what the attacker must outvote

### Current delegated power (top 600 holders, current `delegates()`; top entries cross-checked with `getCurrentVotes`)

| Delegate | Votes (RAD) | % of delegated | Votes cast in 8 proposals | Note |
|---|---:|---:|---:|---|
| `0x219dfbD6…8456` | **7,105,352.11** | 43.7% | 2 (both For) | Drips; the RAD is held by `0xcC7d…355A`, a 3-of-5 Gnosis Safe |
| `0x288703aa…1992` | 3,211,112.40 | 19.8% | **0** | Gnosis Safe 2-of-3, self-delegated; never voted |
| `0xc74f5515…a724` | 1,300,000.00 | 8.0% | 3 (all For) | EIP-7702 EOA |
| `0x7dcacf41…dd7e` | 1,200,000.00 | 7.4% | 4 (all For) | Proposer of 6 of 8 proposals |
| `0x464d78a5…0b0b` | 1,000,122.27 | 6.2% | 4 (all For) | Core voter |
| `0x2d7d6ec6…b05e` | 680,272.11 | 4.2% | 2 (all For) | EIP-7702 EOA |
| `0x6851566a…d707` | 554,274.00 | 3.4% | 0 | Never voted |
| `0xf9139d21…f831` | 519,711.09 | 3.2% | 0 | Never voted |
| `0x3e25b1e4…6fa61` | 315,996.61 | 1.9% | 0 | Never voted |
| `0xcaa3a3c8…0e1b` | 110,234.80 | 0.7% | 2 (all For) | Voted |
| **Total delegated (scanned)** | **16,246,745** | 100% | | top-5 = **85.0%** of delegated |
| **Undelegated (scanned)** | **83,334,769** | | | includes the **40,922,601** timelock; 83.7% of scanned supply |

The top-600 scan covers 99,581,514 of 99,998,580 RAD (99.58%); the remaining 417,066 RAD is outside the scan. The top delegates' `getCurrentVotes` matches the aggregate, so the top of the table is complete.

### Historical turnout (all 8 proposals)

| Proposal | Block | Voters | For (RAD) | Against | Note |
|---|---:|---:|---:|---:|---|
| first (test transfer) | 21,423,931 | 0 | 0 | 0 | Defeated (no quorum) |
| RGP-26 (a) | 21,424,039 | 10 | 4,683,821 | 0 | Expired before execution |
| RGP-26 (b) | 21,615,713 | 9 | 5,994,966 | 0 | Executed |
| RGP-28 | 24,033,411 | 5 | 4,055,627 | 0 | Executed |
| TODO | 24,033,472 | 0 | 0 | 0 | Canceled |
| RGP-27 | 24,034,451 | 6 | 4,055,627 | 0 | Executed |
| RGP-29 | 24,727,801 | **2** | 7,424,526 | 0 | Executed; Drips + one 0-weight voter |
| RGP-30 | 24,914,538 | **1** | 7,424,526 | 0 | Executed; Drips alone |

**No proposal has ever received a material Against vote.** The only "against" cast was a 0-weight address on RGP-29. The last two proposals passed with 1–2 voters, and RGP-27/28 passed with exactly **4,055,627 For** — only 55,627 above the 4M quorum. This is a low-attention, one-sided governance process.

### What the attacker must outvote

| Scenario | No votes | Attacker RAD needed | Approx. notional / capital |
|---|---:|---:|---:|
| A — Drips abstains/does not vote; core does not vote | 0 | **4,000,000** (quorum) | $1.13M notional; **$1.3–2.5M** all-in |
| B — Drips votes No | 7,105,352 | **>7,105,352** | $2.0M notional; **$2.9–3.2M** all-in |
| C — Drips + 0xc74f + 0x7dca + 0x464d + 0x2d7d vote No | ≈11.3M | **>11.3M** | $3.2M notional; **$4.5–5.6M** all-in |
| D — every delegated address votes No | 16.25M | **>16.25M** | $4.6M notional; **$7–10M** all-in; not viable |

The **0x2887 2-of-3 Safe (3.211M)** has never voted; if it joins, C becomes ~14.5M. The 7.5M RAD that Drips holds came from the treasury in RGP-27 (block 24,074,428); Drips is a treasury-funded grantee and is the most likely defender. Its delegate is an EOA; the Safe is 3-of-5. It voted on the last two Drips-specific proposals but not on the earlier six, so its general vigilance is unproven.

**Likelihood:** the unopposed (A) or Drips-only (B) scenarios are plausible because (i) governance attention is demonstrably low (1–2 voters on the last two proposals), (ii) the proposal can be bundled with routine-looking calls, and (iii) there is no guardian to force a review. The core team and Drips would likely oppose if alerted, so C is also plausible. The risk-adjusted probability weights used below are A 35% / B 20% / C 40% / D 5% — subjective, stated as such.

---

## 4. Economics: acquisition, liquidation, net

### Acquisition

The only DEX pool is the timelock's own Uniswap V2 RAD/USDC pair (reserves 3,788,789 RAD + $1,079,531; 24h DEX volume $45,691). CEX 24h volume is **$3.136M** (Binance RAD/USDT $747k; Binance RAD/TRY $530k; BTCC $376k; BtcTurk $245k; LBank $187k; Paribu $156k; Toobit $125k; CoinTR $100k; Bithumb $99k; BitKan $91k; WhiteBIT $71k; MEXC $67k). MEXC/Gate order books are thin: MEXC bids $65.8k (asks $2.44M, dominated by a $9.71 ask), Gate bids $18.6k / asks $51.4k. Binance's book was not retrievable from this environment (geo/API block); its aggregate volume is the better proxy.

Uniswap V2 constant-product cost to buy X RAD (paid in USDC):

| Buy | Cost | Avg price | % of pool RAD |
|---:|---:|---:|---:|
| 1.0M RAD | $387,098 | $0.387 | 26.4% |
| 2.0M RAD | $1,207,000 | $0.604 | 52.8% |
| 2.5M RAD | $2,094,000 | $0.838 | 66.0% |
| 3.0M RAD | $4,106,000 | $1.369 | 79.2% |
| 3.5M RAD | $13.08M | $3.738 | 92.4% |

The pool cannot supply 4M RAD at a sane price; the bulk must come from CEX/OTC. The brief's **$1.3–$2.5M all-in** for 4M RAD is reasonable (4M × $0.325–$0.625).

**Circular-LP amplifier (new):** because the timelock owns 99.9958% of the pool, any USDC the attacker pays to buy RAD from that pool goes to the timelock's own LP. If the attacker captures the LP in the same proposal, the DEX leg is recovered (minus 0.0042%). The **permanent** cost is only the CEX/OTC leg. Example: buy 2M RAD on the pool for $1.207M (recoverable) + 2M on CEX for ~$0.64M → $1.85M temporary outlay, **$0.64M permanent**. The net table below conservatively charges the full acquisition cost, so the true net is equal or better.

### Liquidation

The attacker ends with **44,711,033 RAD** (direct 40,922,601 + LP 3,788,431) = **75.7% of circulating**. The DEX pool can absorb only ~$1.0M for the entire position (selling 40.9M into the pool yields ~$0.99M, avg $0.024 — a 92% haircut). CEX 24h volume is $3.1M; selling 40.9M is ~13 days of total volume, and the order books are thin. The realistic exit is an **OTC block sale at a 50–70% discount**, or a slow multi-week sale with a 50–90% drawdown. The brief's 50–70% haircut (realization 30–50%) is the optimistic-to-central case; 90% drawdown (10% realization) is the stress case.

### Net table (USD, after acquisition cost; non-RAD assets include USDC/WETH/GTC + Drips TVL)

`Net = 44.711M × $0.283506 × realization + $2,084,325 − cost`

| Realization (haircut) | A: 4M, $1.36M | A′: 4M, $1.85M | B: 7.2M, $2.88M | C: 11.3M, $4.52M | C′: 11.3M, $5.65M | D: 16.3M, $8.15M |
|---|---:|---:|---:|---:|---:|---:|
| **0% (100%)** | **+$0.72M** | **+$0.23M** | −$0.80M | −$2.44M | −$3.57M | −$6.07M |
| **10% (90%)** | +$1.99M | +$1.50M | +$0.47M | −$1.17M | −$2.30M | −$4.80M |
| **20% (80%)** | +$3.26M | +$2.77M | +$1.74M | +$0.10M | −$1.03M | −$3.53M |
| **30% (70%)** | **+$4.53M** | +$4.04M | **+$3.01M** | **+$1.37M** | +$0.24M | −$2.26M |
| **40% (60%)** | +$5.79M | +$5.30M | +$4.27M | +$2.63M | +$1.50M | −$1.00M |
| **50% (50%)** | +$7.06M | +$6.57M | +$5.54M | +$3.90M | +$2.77M | +$0.27M |

Breakeven realization (fraction of spot RAD value needed to cover the acquisition cost; the non-RAD assets cover the 4M cost entirely):

| Scenario | Breakeven realization | Implied haircut |
|---|---:|---:|
| A: 4M, $1.36M | **0%** (non-RAD covers cost; +$0.72M at zero RAD) | n/a |
| A′: 4M, $1.85M | **0%** (+$0.23M at zero RAD) | n/a |
| B: 7.2M, $2.88M | 6.3% | 93.7% |
| C: 11.3M, $4.52M | 19.2% | 80.8% |
| C′: 11.3M, $5.65M | 28.1% | 71.9% |
| D: 16.3M, $8.15M | 47.9% | 52.1% |

**Scenario-weighted expected net** (A 35% / B 20% / C 40% / D 5%):

| Realization | Expected net |
|---|---:|
| 10% | **$0.08M** |
| 20% | **$1.35M** |
| 30% | **$2.62M** |
| 40% | **$3.89M** |
| 50% | **$5.15M** |

**Headline:** **≈$3.0M net central** (between 30% and 40% realization), **range $1.4M–$5.2M**, with **capital $1.3M–$2.5M** for A and **$4M–$6M** for C. The unopposed 4M path is profitable even if the stolen RAD is worthless (the non-RAD assets alone exceed the acquisition cost); the contested 11.3M path needs ~19–28% realization (72–81% haircut) to break even. The **binding constraint is delegate opposition, not the quorum**.

**Market exposure:** ~5.4 days from propose to execute; the attacker can sell the 4M RAD after the snapshot (block +7,200) and still vote, reducing the pre-vote holding period to ~24h. The stolen RAD remains exposed to the market/OTC process after execution.

---

## 5. PoC / fork verification

**Project:** `radworks/poc/` (Foundry 1.8.5, solc 0.8.24, vendored `lib/forge-std`), fork block **26,229,556**, archive RPC via CI (`BLOCKPI_RPC_URL`/`NODEREAL_ETH_RPC_URL` preferred; publicnode fallback).

**CI:** [https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39340625186](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39340625186) — **8/8 PASS**, success. Artifact: `result-radworks` (state JSON + logs).

| Test | Result | What it proves |
|---|---|---|
| `test_live_state` | PASS | quorum 4M, threshold 1M, delay 7,200, period 17,280, timelock admin/pendingAdmin/delay, treasury balances, LP 99.9958%, Drips 7,105,352 votes |
| `test_capture_with_quorum_only` | PASS | 4M RAD → propose → vote → queue → warp 2 days → execute; attacker receives **40,922,601 RAD + 319,133 USDC + 59.9 WETH + 500,000 GTC + 0.09816 ETH + LP**; redeems LP for **3,788,431 RAD + 1,079,429 USDC**; final **48,711,032.52 RAD + 1,398,562.16 USDC**; gas **1,449,383** |
| `test_drips_no_defeats_4m` | PASS | 4M For vs 7,105,352 No → **Defeated** (state 3) — the quorum is met but `forVotes > againstVotes` fails |
| `test_7_2m_for_beats_drips` | PASS | 7.2M For vs 7,105,352 No → **Executed** — outvoting Drips alone requires >7.105M |
| `test_snapshot_flip_still_votes` | PASS | sell all 4M RAD at `snapshot+1`, then `castVote` with the 4M snapshot weight — votes are fixed at the snapshot |
| `test_no_guardian_functions` | PASS | `guardian()`, `veto()`, `securityCouncil()`, `owner()` all revert — no guardian/veto |
| `test_third_party_cannot_cancel` | PASS | a random address cannot `cancel(uint256)` a Pending proposal; only the proposer can |
| `test_drips_admin_handover` | PASS | the timelock proposes the attacker as Drips admin; the attacker `acceptAdmin()`s — **Drips admin = attacker** (gas 673,255) |

**Key PoC numbers:** attacker final RAD **48,711,032.5240609244**; final USDC **1,398,562.164486**; LP redemption **3,788,431.4195869042 RAD + 1,079,429.133507 USDC**; full-path gas **1,449,383**; Drips handover gas **673,255**. The test transfers the exact live treasury payload, not a mock.

**Reproduce:**

```bash
cd radworks/poc
FORK_RPC_URL=<archive-rpc> forge test -vv
```

(The test prefers `BLOCKPI_RPC_URL`/`NODEREAL_ETH_RPC_URL` if set; no keyed URL is stored in the repo. `FORK_RPC_URL` may be a public archive RPC.)

---

## 6. Blockers, negative results, and residual risk

**Open / no blocker:**
- No guardian, no veto, no security council, no cancel role except the proposer.
- Timelock admin = governor; `pendingAdmin = 0`; no migration in flight.
- Treasury RAD is undelegated; `getPriorVotes(timelock) = 0`; the treasury cannot vote.
- The proposal path is permissionless; the attacker only needs RAD and gas.
- The 4M quorum is constant (not supply-scaled), so it does not grow with the stolen RAD.

**The real blocker (voluntary, not on-chain):**
- **Drips 7,105,352 RAD + core voters ≈4.2M RAD**. If they vote No, the attacker needs >11.3M RAD and ~$4–6M; the attack is still potentially profitable at 50–70% haircut but the margin is thin at 80–90%.
- **0x2887 Safe 3,211,112 RAD** has never voted; if it joins, the bar rises to ~14.5M.
- The proposal is public for ~3.4 days; Drips/core can cast a single No vote. If they are alerted, the attack fails. The absence of a guardian means the defense is purely voluntary attention.

**Negative results (checked, not exploitable):**
- **No direct allowance drain:** the timelock has a live **212,600 RAD** allowance to the `AddLiquidity` contract `0xb76fc4eb…` (block 12,061,887 approval of 500,000 RAD; 287,400 used). `AddLiquidity.addLiquidity` calls `transferFrom(msg.sender, …)`, so an external caller cannot pull from the timelock; the contract holds 0 RAD/USDC and has no withdraw. All other timelock RAD/USDC/WETH/GTC allowances are 0 (checked current `allowance` and Approval logs). **Not E-U.**
- **Drips `withdraw` excess is dust:** `withdraw(erc20, receiver, amt)` is public but only pays `balance − streams − splits`. At block 26,229,556 the excess is ~$0.007 USDC, ~0.0000004 WETH, ~0 RAD — no direct drain.
- **No active proposal:** 8 `ProposalCreated` events; all terminal (states 2, 3, 6, 7); last executed 2026-04-25. No hostile proposal is in flight today.
- **No V3 NFT positions:** `balanceOf(timelock)` on the Uniswap V3 NonfungiblePositionManager = 0. The `Sale` contract `0x864f…` holds 0 RAD/USDC/ETH. The only non-spam assets are RAD, USDC, WETH, GTC, ETH, and the V2 LP.
- **RAD token has no mint/pause/blacklist:** the attacker can transfer the stolen RAD; no token-level freeze.
- **The 5.4-day path cannot be shortened** by the attacker: votingDelay and votingPeriod are governance-set constants (only governance can change them), and the timelock delay is 2 days. A defensive proposal to change them would itself take ~3.4 days + 2 days and cannot beat an in-flight attack.

**Residual / latent risk:**
- The 212,600 RAD allowance to `AddLiquidity` is a latent governance/ops risk (if the timelock ever calls `addLiquidity`, it would pull 212,600 RAD into the pool). Not externally callable today.
- The Drips admin keys/roles are co-located with the timelock; any future governance capture also captures Drips (~$0.36M today, potentially more if TVL grows).
- The 0x2887 3.2M Safe is dormant; if it ever votes, it changes the defense calculus.
- RAD liquidity is the binding economic constraint; if liquidity deepens or a CEX listing grows, the attack becomes more profitable.

---

## 7. Verdict and recommendation

**Verdict: KEEP AS CRITICAL (E-U).** The mechanical path is fully open and fork-proven: no guardian, treasury undelegated, arbitrary `transfer` from the timelock, 8/8 tests. The gross prize is **$14.76M** (corrected from $11.98M); the risk-adjusted net is **≈$3.0M** (range $1.4M–$5.2M) with **$1.3–2.5M** capital in the unopposed case, rising to **$4–6M** if Drips + core delegates oppose. The confidence is **high on mechanics**, **medium-low on economics** (delegate behavior and liquidation depth). The brief's "$3.5–6M net" is the optimistic/unopposed case; the brief's "4M quorum" is not the contested-vote cost.

**Immediate mitigation (for the Radworks team):**
1. **Delegate the treasury's 40,922,601 RAD** to a dedicated defensive delegate (or a contract that always votes No on hostile proposals). This is the single highest-leverage fix: it would give the treasury ~40.9M votes and make any hostile proposal impossible without ~45M RAD. It requires a governance proposal now, while the current delegates are aligned.
2. **Add a guardian/security council with cancel power** (even a 3-of-5 multisig) to the Governor or a proposal guardian, like Gitcoin/ENS/Compound. The absence of any veto is the structural flaw.
3. **Raise the proposal threshold** from 1M to ≥4M RAD and/or add a longer voting delay; this raises the capital bar but does not replace a guardian.
4. **Move the Drips admin** off the timelock to a separate multisig with a distinct signer set, or add a timelock+guardian on the Drips proxy.
5. **Monitor** `ProposalCreated` events and publish a delegate alert; the attack's only real defense is a timely No vote.

**What would change the verdict:** a guardian/veto going live; the treasury's RAD being delegated to a defensive address; Drips/core delegates publicly committing to vote No; or RAD liquidity collapsing (which lowers the net but not the mechanical path).

---

## 8. Methodology, sources, caveats

**Method:** verified source + ABI on Etherscan V2; direct `eth_call`/`eth_getStorageAt` reads at block 26,229,556 (publicnode/BLOCKPI); latest re-check at 26,229,853; Etherscan logs for `ProposalCreated`, `VoteCast`, `ProposalQueued`, `ProposalExecuted`, `ProposalCanceled`, `Approval`; Blockscout holder list (top 600) + on-chain `balanceOf`/`delegates`/`getCurrentVotes`; DefiLlama/CoinGecko/GeckoTerminal prices and volume; MEXC/Gate order books; Foundry fork tests in GitHub Actions. The 600-holder delegate aggregation was cross-checked against `getCurrentVotes` for the top 9 delegates.

**Caveats:**
- **Point-in-time:** 2026-10-19/20; Drips/core delegate behavior and RAD liquidity must be re-checked before any action. The attack takes ~5.4 days and is capital-gated, not privilege-gated.
- **Liquidation values are estimates:** 44.71M RAD is 75.7% of circulating; DEX/CEX depth cannot absorb it at spot. The 30–50% realization range is an assumption, not a market quote. Binance's order book was not retrievable; MEXC/Gate books are thin and may not represent Binance depth.
- **Drips TVL is mark-to-market** at approximate token prices; the Drips drain requires an upgrade, which is fork-proven only at the admin-handover level (the final malicious implementation is standard UUPS and was not executed in the PoC to avoid `vm.etch` RPC limitations).
- **The top-600 holder scan** covers 99.58% of supply; 417k RAD outside the scan could include additional delegated votes. The top delegates are confirmed on-chain.
- **No mainnet transactions** were signed or sent; all state changes are local forks. No secrets or keyed RPC URLs are stored in this folder.

**Files:**
- `README.md` — this report.
- `summary.json` — machine-readable summary.
- `analysis/live_state.json` — exact state, balances, USD, latest re-check.
- `analysis/delegates.json`, `analysis/turnout.json` — voting landscape.
- `analysis/proposals.json`, `analysis/votes.json` — all 8 proposals and 33 votes.
- `analysis/dex_depth.json` — pool curves, CEX volume, order books.
- `analysis/economics.json` — cost/net/breakeven/scenario table.
- `analysis/holders_delegates_onchain.json`, `analysis/holders_raw.json` — holder/delegate scan.
- `analysis/drips_balances.json` — Drips TVL tokens.
- `analysis/allowances.json` — timelock allowances (if generated; see README §6).
- `poc/` — Foundry project; `poc/test/RadworksCapture.t.sol` (8 tests).
- `ci/dump_state.py`, `ci/run.sh` — CI state dump.
- `ci-out/state.json` — CI-read live state (block 26,229,853).
- `ci-log.txt`, `ci-artifacts/` — CI run log/artifact.
