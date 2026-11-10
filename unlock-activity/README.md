# Unlock Protocol governance — capital, recoverability and activity (Base)

**Date:** 2026-11-10 · **Chain:** Base (8453) · **Mode:** READ-ONLY — no transaction was signed or sent on any live network; `eth_call`/`eth_getLogs` + **local anvil forks only** (Foundry tests ran on GitHub Actions).
**Status:** pass7 `unlock-gov/` extended, not duplicated. Mechanism and acquisition cost re-measured at block **55,433,658**; full 158-proposal history decoded; **11/11 fork tests PASS** in CI run [42741782318](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/42741782318).
**Headline:** **E-U now = $0.00** (unconditional). A 3,000,000 UP quorum stake costs **$3,511.78** and a failed attempt loses only **$20.54** — but $3k buys *quorum, not victory*: the observed opposition is **6.58M–13.69M UP**, the max ever is **47.11M UP**, and **two prior "govscan capture" attempts both failed**. Conditional upside if the DAO is completely asleep: **$26,914**.

---

## 1. TL;DR — the three questions

| Question | Answer (fork-measured, block 55,433,658) |
|---|---|
| **"About $3k for quorum, right?"** | **Yes for the capital, no for the cost.** 3,000,000 UP costs **1.655510 WETH = $3,511.78** through the live UniV3 pool (spot value $3,352.18; slippage $159.60 / 4.8%). But it is **capital, not expense**: selling the 3M back returns **$3,491.23**, so the **failure-case loss is $20.54 (0.59%)**, not $3k. |
| **Can the deployer `0x81dd955d…` stop it?** | **No — and ca3's premise is wrong.** The deployer holds **59,735.099462 UP**, not 59,735,099.46 (a 1000× decimal error; the on-chain `VoteCast` weight is 59,735.099462). Its `Against` vote is **0.2%** of a 3M `For`; fork test **09** shows a 3M `For` proposal **Succeeds** even with the deployer voting `Against`. |
| **Who actually blocks it?** | `0xf5c28ce24acf47849988f147d5c75787c0103534` — **39,447,548 votes** (an EOA that received 370.1M UP at the UDT conversion and distributed most of it). It has voted **6 times, all `Against`**, always 39.45M. Plus a **13.69M** steward coalition that defeated the 2026-10-29 capture attempt. A **390.56M UP** 3-of-5 Safe (`0x3074517c…`) has **never delegated** (0 votes) — latent, not active. |
| **How long must the 3M be held?** | **One block (~2 seconds) around the snapshot**, not the 4 days pass7 assumed. The token uses `clock() = block.timestamp`; `proposalSnapshot = propose_timestamp + 345,600`. Buy in the block before/at the snapshot, sell in the next block; `getPastVotes(snapshot)` still returns 3.05M and `castVote` counts 3.05M. **Same-block flash loan fails** (the checkpoint is overwritten to 50k — test 06). |
| **What does a failed attempt cost?** | **$20.54** (3M round-trip) + **$0.33** (50k threshold round-trip) + gas (<$0.10) ≈ **$21**. 99.4% of the $3,512 is recovered. The same 3M can be reused for repeated attempts; `propose` takes **no deposit/escrow**. |
| **Can it be cancelled?** | Yes — by the proposer **only while Pending** (the 4-day delay, before the snapshot). After voting starts, **nobody** can cancel: the governor has no `CANCELLER_ROLE` and `guardian()` reverts. Fork test **11**. |
| **Is UP freely transferable?** | **Yes.** Stock OZ ERC20 + ERC20Votes + Ownable; no pause, no blacklist, no lock, no vesting, no transfer tax. `owner()` is the timelock; the only privileged functions are `mint` (one-shot, already used) and `transferOwnership`. Base-native (`l1Address()` reverts); **no CEX listing** (CoinGecko shows only UniV3 + Aerodrome). |
| **Realistic success rate** | **3M stake: ≈0–2%.** Both capture attempts drew ≥6.58M `Against`; a 3M `For` loses both. **13.69M stake: ≈5–10%**, conditional on the 39.45M whale staying out *and* the 13.69M stewards not escalating — but the whale can add 39.45M at any time, and the 13.69M buy has a **$165k** mark-to-market impact / MEV exposure. **>47.11M: not DEX-purchasable** (the whole pool holds 14.53M UP). |
| **Net expected value** | **≈ $0.** 3M is a cheap lottery ticket (EV **+$250 at p=1%**, **+$6 at p=0.1%**); 13.69M is **+$790 at p=5%** only if the attacker avoids MEV, and **−$155k** if the $165k impact is arbed. Risk-adjusted: no reliable profit. |

---

## 2. Total live extractable now

| Category | USD | Note |
|---|---:|---|
| **E-U unconditional** | **$0.00** | The vote is the binding constraint; 0/2 prior capture attempts succeeded. |
| **E-U conditional** (unopposed vote) | **$26,914** | Nominal prize $47,405; UP leg only realises $9,540 (32% of nominal). |
| **P (privileged/governance)** | $47,405 nominal | Timelock holdings at block 55,433,658: 26,858,278.41 UP + 6.4312 ETH + 2,697.40 USDC + 0.4971 WETH. |
| **H-O** | $0 | No holder-only exit reaches the timelock. |
| **S (stuck)** | $0 | — |

The timelock's nominal value moved from pass7's $38,493 to **$47,405** only because UP/ETH prices moved (UP $0.0011174, ETH $2,121.26); the UP balance fell 27.17M → 26.86M and USDC 3,997 → 2,697 after executed payments. **Realizable** is **$26,934** (ETH $13,642 + USDC $2,697 + WETH $1,054 + UP-dump $9,540).

---

## 3. Capital — exact cost, every route

### 3.1 Price and pool state (block 55,433,658, 2026-11-10T02:18Z)

| Item | Value |
|---|---|
| DefiLlama UP | **$0.001117392** (confidence 0.99) |
| DefiLlama ETH | **$2,121.2647** |
| UniV3 UP/WETH 0.3% pool | `0x9EF81F4E2F2f15Ff1c0C3f8c9ECc636580025242` — **14,529,731.52 UP + 6.62013479 WETH** (~$30.2k) |
| Aerodrome UP/WETH pool | `0xDd295951b46B245638E3C3643299210Eea06a897` — 887,736.85 UP + 0.465095 WETH (~$1.99k, volatile) |
| UP total supply | 1,000,000,000 UP |
| Quorum | 3,000,000 UP |
| Proposal threshold | 50,000 UP |

### 3.2 Measured acquisition (SwapRouter02 `0x2626664c…e481`, exactOutputSingle, fee 3000)

| Stake | WETH paid | USD paid | Spot value | Slippage | Sell-back WETH | Sell-back USD | **Round-trip loss** |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 50,000 UP (threshold) | 0.02634185 | **$55.88** | $55.87 | $0.01 | 0.02618424 | $55.54 | **$0.33** |
| 3,000,000 UP (quorum) | 1.65551043 | **$3,511.78** | $3,352.18 | $159.60 (4.8%) | 1.64582526 | $3,491.23 | **$20.54** |
| 6,580,303 UP (Oct-13 opposition) | 4.17255708 | **$8,851.10** | $7,352.44 | $1,498.66 (20.4%) | 4.14968083 | $8,802.57 | **$48.53** |
| 13,690,000 UP (Oct-29 opposition) | 85.03199830 | **$180,375.38** | $15,297.10 | $165,078 (1079%) | 84.75531226 | $179,788.45 | **$586.92** |

The 13.69M buy is **94% of the pool's UP reserves**; its $165k "impact" is mark-to-market, not the round-trip loss. It is only recoverable if **no other trader** sells UP into the temporarily repriced pool (average cost 11.8× spot; ≈207× at the margin) between the buy and the sell — a 2-block window that MEV bots can attack. That distinction is the core of the risk analysis in §6.

### 3.3 Every acquisition route

| Route | Depth / price | Verdict |
|---|---|---|
| **UniV3 UP/WETH 0.3%** | 14.53M UP / 6.62 WETH; 3M = $3,512, 13.69M = $180k | **Only scalable public route.** 3M is 21% of reserves; 13.69M is 94%. |
| **Aerodrome UP/WETH** | 0.888M UP / 0.465 WETH (~$1.99k) | Cannot supply 3M (pool has <0.9M UP); negligible. |
| **CEX** | **None.** CoinGecko tickers: only Uniswap V3 + Aerodrome | No deposit/withdrawal/OTC desk. |
| **Bridges** | UP is Base-native; `l1Address()` reverts; CoinGecko platforms = Base only | **No bridge route.** |
| **UPSwap `0x12be7322…`** | Holds **54,079,702 UP**; fixed rate **1 UDT = 1,000 UP**; also 945,920 UDT for buy-backs | UDT = "Unlock Discount Token", a **Base-bridged legacy token** (`l1Token` 0x90DE…, `l2Bridge` 0x4200…10). UDT's only market: Ethereum UniV2 `0x9cA8…67C1`, **$270 liquidity, $0.8254**. At that price 3M UP = 3,000 UDT = **$2,476** (cheaper than the DEX, zero slippage), and the round trip returns 3,000 UDT. **But the pool holds ~164 UDT**: the route is only usable by an existing UDT holder / OTC, not a public 3M purchase. |
| **Holder transfers / OTC** | Top holders: 390.56M Safe (3-of-5), 39.45M `0xf5c2…`, 54.08M UPSwap, 26.86M timelock, 4.92M `0x0d84…`, 4.18M `0x87ec…`… | Token is freely transferable; an OTC deal with an early UDT investor is possible in principle. But the large holders **are the defending coalition**; no public OTC desk exists. |
| **Locked / vesting** | No on-chain lock/vesting in UP. The 390.56M Safe is a **3-of-5 Gnosis Safe**, not a vesting contract; it has never delegated (0 votes). The 54.08M UPSwap is escrowed against UDT. | No unlock event is imminent; no free float beyond the ~15.4M in the two pools. |

**Minimum capital to execute:** **$3,512** for a 3M quorum attempt (peak ~$3,568 if the 50k threshold is held simultaneously; the 50k can be sold before the 3M buy). **$8,851** to match the Oct-13 opposition; **$180,375** to match the Oct-29 opposition. **>47.11M is not purchasable from the DEX** (pool holds 14.53M UP) — it would require OTC from the defenders.

---

## 4. Recoverability if the vote fails

### 4.1 `propose` takes no deposit or escrow

`UPGovernor.propose` (verified impl `0x6ac91d93…`) checks only `getVotes(proposer, clock() - 1) >= proposalThreshold()`; it transfers nothing. The 50k is **not escrowed**. Fork test **07**: propose with 50k, sell the 50k immediately after, the proposal remains `Pending` and can still be voted. The 50k threshold must be held for **one prior block** (`getVotes(..., clock()-1)`), not the same block; cost $0.33.

### 4.2 Snapshot timing — the 4-day hold was wrong

`UP` overrides `clock()` to **`block.timestamp`** (`CLOCK_MODE = "mode=timestamp"`). `_propose` sets `snapshot = clock() + votingDelay()`; `_castVote` reads `getPastVotes(account, proposalSnapshot)`. Therefore:

- Buy 3M in the block **before or at** the snapshot timestamp, sell in the **next block**; the checkpoint at the snapshot remains 3M. Fork test **05**: bought at `snapshot-2`, sold at `snapshot+2`, `getPastVotes(snapshot) = 3,050,000 UP`, `castVote` weight **3,050,000 UP**. Hold ≈ **2 seconds**, not 4 days.
- **Same-block flash loan fails**: buy and sell in the same block/timestamp overwrites the checkpoint at that timestamp to 0/50k. Fork test **06**: after a same-block 3M round trip, `getPastVotes(snapshot) = 50,000 UP`, vote weight **50,000**, not 3M.
- A 1-block *collateralised* borrow (Aave/Compound/Morpho) is the only leverage route; **UP is not listed on Aave V3 Base** (`getConfiguration(UP)=0`, aToken 0) or **Compound III** (`BadAsset`). Morpho Blue is permissionless but no liquid UP market was found. Borrowing WETH against ETH/USDC for 2 seconds costs <$0.01 but needs collateral — it does not change the exposure, only the equity.
- The 50k threshold also cannot be flash-loaned in the same block (`getVotes(proposer, clock()-1)`); it needs a 1-block hold, cost $0.33.

### 4.3 Failure-case net

| Item | 3M attempt | 6.58M attempt | 13.69M attempt |
|---|---:|---:|---:|
| Capital deployed | $3,511.78 | $8,851.10 | $180,375.38 |
| Recovered on sell-back | $3,491.23 | $8,802.57 | $179,788.45 |
| **DEX round-trip loss** | **$20.54** | **$48.53** | **$586.92** |
| 50k threshold round-trip | $0.33 | $0.33 | $0.33 |
| Base gas (5-6 txs) | <$0.10 | <$0.10 | <$0.10 |
| **Total if defeated** | **≈ $20.9** | **≈ $49** | **≈ $587** |
| Recoverable share | **99.4%** | **99.5%** | **99.7%** |

The $3k is **not lost** on failure; only the $20.54 fee is. But the 3M is not enough to win (see §6), and the 13.69M stake that could match the last opposition carries a **$165k** mark-to-market impact that is only recoverable if no other trader interferes. Even for the 3M, a full MEV capture of the 4.8% impact raises the loss to ~$160 — still small.

### 4.4 Cancel and reuse

- **Cancel:** the proposer may cancel **only while `Pending`** (the 4-day voting delay, before the snapshot) — `Governor.cancel` checks `ProposalState.Pending` and `_msgSender() == proposer`. Fork test **11**. After the snapshot the proposal is `Active`; the only other cancel path is `GovernorTimelockControl._cancel → timelock.cancel(id)`, which requires `CANCELLER_ROLE` — held by **nobody** (governor=false, timelock-self=false). So the attacker can abort before committing the 3M if on-chain preparation is visible, but **cannot cancel once voting starts**.
- **Reuse:** yes. The 3M is sold after the snapshot, the proposal runs its course, and the same capital can be re-bought for the next proposal's snapshot. Each attempt costs **~$21** + gas. `propose` leaves no state that prevents a new proposal with the same targets/description (a cancelled/defeated proposal can be re-proposed under a different description hash).

---

## 5. Activity — 158 proposals, who votes, and what turnout looks like

Full decoded history: `analysis/proposals.csv` (158 rows), `analysis/votes.csv` (1,710 `VoteCast`), `analysis/governance_decoded.json`. Governor deployed at Base block **18,036,287** (2024-08-05); `ProposalCreated` logs from block 18,036,287 to 55,431,663; 2,079 governor logs decoded.

### 5.1 Census

| Metric | Value |
|---|---|
| Proposals | **158** (2024-08 → 2026-10) |
| Executed | **99** |
| No quorum | **54** (34.2%) |
| Defeated | **3** |
| Canceled | **1** |
| Succeeded (not executed) | **1** |
| Turnout min / median / max | **0 / 5,109,176.99 / 47,569,740.04 UP** |
| Turnout below 3,000,000 | **34 / 158 (21.5%)** |
| Cadence | **~5.9/month** overall; **~4.1/month** excluding the Sept-2026 51-proposal spam burst; ~3–5/month in 2026 |
| Zero-vote proposals | 2 (plus ~47 one-voter "Proposals" in Sept 2026) |

The Sept-2026 burst (51 proposals, mostly "Proposals"/"Proposal 0x…" with 0 votes) is a **governance-spam incident**, not routine cadence — the 50k threshold is cheap enough to spam. It inflates the no-quorum count; the genuine median turnout is still **~5.1M**, 1.7× quorum.

### 5.2 Who votes

| Delegate | Current votes | Votes cast | For / Against / Abstain | Notes |
|---|---:|---:|---|---|
| `0xf5c28ce2…3534` | **39,447,548** | **6** | 0 / **6** / 0 | The real whale. EOA, received 370.1M UP at the UDT conversion; voted only in the 2026-09-19→10-03 attack window, always 39.45M `Against`. |
| `0x6554dc05…ed56` | 6,225,983 | 3 | 3 / 0 / 0 | Delegate for `0x0d8410…` (4.92M) etc.; holds 6.2M but has cast only 3 votes. |
| `0x38b826a4…1c5d` | 3,450,169 | **103** | 79 / 24 / 0 | Most active delegate; voted `For` on the 2026-10-29 "govscan capture" (the 3.4M `For`). |
| `0xd2bc5cb6…be23` | 3,257,740 | 73 | 70 / 3 / 0 | Core steward. |
| `0x87ece993…793f` | 2,578,087 | 30 | 22 / 6 / 2 | |
| `0x9ded35ae…94e5` | 2,441,249 | 103 | 100 / 3 / 0 | Top proposer (57 proposals). |
| `0x34c2871c…e2d5` | 2,398,485 | 41 | 33 / 8 / 0 | |
| `0xca763232…3854` | 2,355,795 | 111 | 83 / 28 / 0 | |
| `0x9492510b…cac4` | 2,306,823 | 1 | 1 / 0 / 0 | |
| `0x79f16606…c032` | 2,283,792 | 42 | 40 / 1 / 1 | |
| `0x676efef0…3577` | 774,339 | 45 | 24 / 21 / 0 | |
| **Deployer `0x81dd955d…2052`** | **59,735** | **2** | **0 / 2 / 0** | **59,735.099462 UP, not 59.7M.** Voted Against the 2026-03-23 treasury transfer (proposal still executed 4.52M For) and the 2026-09-19 "Migrate treasury" (defeated by the 42.4M `Against` coalition — 39.45M of it the whale — not by the deployer). |
| **Safe `0x3074517c…e7dd`** | **0** | 0 | — | **390,561,436.78 UP** in a 3-of-5 Gnosis Safe, **never delegated**. Latent 39% of supply. |
| Timelock `0xB345…ed1b` | 0 | 0 | — | 26.86M UP undelegated. |

**Does the deployer vote on every proposal?** No — **2 / 158 (1.3%)**, both `Against`, both with the same 59,735.099462 weight. Its delegation history (8 `DelegateChanged` events) includes self, a Safe owner (`0x4ce2dd…`), and Vitalik (`0xd8da6b…`), but the **current delegate is itself**; it is simply a 59.7k-UP minnow, not a 59.7M whale.

**Does the whale vote on every proposal?** No — 6 / 158 (3.8%), all `Against`, all 39.45M, all in a 10-day window (2026-09-23 → 2026-10-03). It did **not** vote on the 2026-10-29 capture; the 13.69M steward coalition defeated that one without it.

### 5.3 The capture attempts (the decisive evidence)

| Date | Proposal | Proposer | `For` | `Against` | Outcome |
|---|---|---|---:|---:|---|
| 2026-09-19 | "Migrate treasury assets to enhanced UPTreasuryV2 security module" | `0x8db23a7f…` | 5.16M | **42.41M** | **DEFEATED** |
| 2026-09-19 | "#Introduce and Assign the Governance Cancel Role" | `0x66503f90…` | 0 | **47.11M** | NO_QUORUM (would lose) |
| 2026-09-19 | "# Payment for the DAO collaboration platform in September" (spoof) | `0x66503f90…` | 0 | **47.11M** | NO_QUORUM |
| 2026-09-28 | "# Introduce and Assign the Governance Cancel Role" | `0xf88ee8b9…` | 0 | **39.80M** | NO_QUORUM |
| 2026-10-13 | **"govscan capture"** — drain USDC/WETH/6.431 ETH to proposer | `0xc48bad63…` | 0 | **6.58M** | NO_QUORUM (with 3M For: 3M < 6.58M → defeated) |
| 2026-10-29 | **"govscan capture"** — upgrade both ProxyAdmins | `0xfc910bd1…` | **3.40M** | **13.69M** | **DEFEATED** |
| 2026-09-22 | "# Defensive Delegation of UP Voting Power to DAO Stewards & Delegates" | `0xc1ea63e3…` | 3.23M | 0 | **EXECUTED** — the DAO's response |

This is the empirical answer: **0 / 2 direct "govscan capture" attempts succeeded**, and the largest observed `Against` is **47,111,520 UP**. The 2026-10-29 attempt is the closest analogue: 3.4M `For` vs 13.69M `Against`; a **13.69M+** attacker would have beaten *that* coalition by ~3.4M if the whale stayed out — but the whale can add 39.45M, and would turn a 13.69M stake into a defeat.

### 5.4 A lone 3M vote — counterfactual

Adding 3M `For` to every historical proposal and assuming the deployer abstains gives **135 / 158 passes** — but that is an apathy upper bound, not a success probability: 54 proposals had zero/low turnout and no opposition. For the **adversarial** subset (the 6 capture/treasury proposals above), a 3M `For` would have lost **all of them** (6.58M–47.11M `Against`). The one clear "3M-class" pass is the 2025-04-10 ApeBond transfer (3.397M `For`, 0 `Against`, executed) — a legitimate routine transfer, not a drain.

---

## 6. Success probability and expected value

### 6.1 Defence is layered and reactive

- **39.45M** whale: can single-handedly defeat any DEX-purchasable stake (max 14.53M). It voted 6/6 `Against` on the Sept-Oct 2026 attack cluster.
- **13.69M** steward coalition: defeated the 2026-10-29 capture without the whale.
- **390.56M** Safe: undelegated but available to the team in principle; if it ever delegates, the defence becomes unassailable.
- **4-day public delay + 6-day vote**: the proposal is visible for 10 days; the attacker's 13.69M buy would itself be a visible price spike.

### 6.2 Probability estimates (calibrated, not curve-fit)

| Attacker stake | Capital | Beats observed | Loses to | p(success) estimate |
|---:|---:|---|---|---:|
| 3.0M | $3,512 | nothing | 6.58M (Oct-13), 13.69M (Oct-29), 47.11M (max) | **0–2%** (0/2 observed) |
| 6.58M | $8,851 | ties Oct-13 (needs +1) | 13.69M, 47.11M | **2–5%** |
| 13.69M | $180,375 | beats Oct-29 by 3.4M if whale absent | 39.45M whale, 47.11M max | **5–10%** (conditional on whale apathy) |
| >47.11M | not DEX-purchasable | all | — | **<1%** (OTC only; defenders are the sellers) |

### 6.3 EV (prize $26,914; failure loss per §4.3)

| Stake | Failure loss | EV at p=1% | EV at p=5% | EV at p=10% |
|---:|---:|---:|---:|---:|
| 3.0M | $20.9 | **+$248** | +$1,326 | +$2,673 |
| 6.58M | $48.9 | +$221 | **+$1,299** | +$2,647 |
| 13.69M (no MEV) | $587 | −$312 | **+$788** | +$2,163 |
| 13.69M (MEV captures impact) | ≤$165,078 | −$163,158 | **−$155,478** | −$145,879 |

The **3M lottery ticket has positive EV at any p > 0.08%** — that is the honest economic statement. But the absolute EV is small, the success requires total DAO apathy (never observed for a treasury transfer), and the 13.69M "winning" stake only has positive EV if the attacker can execute the buy/sell without MEV capturing the $165k impact (private order flow / builder bundle). **Risk-adjusted, the attack is not a reliable profit.**

### 6.4 "About $3k, right?" — the precise answer

- **$3,352** at spot; **$3,512** executable through the DEX; **$3,568** peak with the 50k threshold.
- That is **capital**, 99.4% recoverable; the **cost of a failed attempt is $20.54**.
- $3k buys **quorum only**. The observed opposition is **6.58M–13.69M UP**; matching it costs **$8,851–$180,375**, and beating the 47.11M max is **not possible from the DEX**.
- The **deployer is irrelevant** (59,735 UP). The binding constraints are the **39.45M whale** and the **13.69M steward coalition**.

---

## 7. Fork verification (11/11 PASS)

`poc/` — Foundry project, Base fork at block **55,433,658**, public RPC only. **CI run [42741782318](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/42741782318)** — `Suite result: ok. 11 passed; 0 failed; 0 skipped`.

| Test | Proves | Key result |
|---|---|---|
| `test_01_liveState` | Parameters + the ca3 correction | quorum 3M; deployer **59,735.099462 UP**; whale **39,447,548**; Safe **390,561,436.78 UP, 0 votes**; timelock 26.858M UP + 6.431 ETH + 2,697 USDC + 0.497 WETH |
| `test_02_roundTrip_3M` | Quorum acquisition + failure cost | pay **1.655510 WETH ($3,511.78)**, sell **1.645825 WETH ($3,491.23)**, **loss $20.54** |
| `test_03_roundTrip_50k` | Threshold cost | **$55.88**, round-trip **$0.33** |
| `test_04_buy_6_58M_and_13_69M` | Opposition acquisition | 6.58M = **$8,851.10** (loss $48.53); 13.69M = **$180,375.38** (loss $586.92) |
| `test_05_oneBlockSnapshotHold` | 1-block hold beats the 4-day assumption | buy at `snapshot-2`, sell at `snapshot+2`, `getPastVotes(snapshot)=3.05M`, vote weight **3.05M** |
| `test_06_flashloanSameBlockFails` | No same-block flash loan | after buy+sell same block, past votes = **50k**, vote weight **50k** |
| `test_07_thresholdTiming` | No escrow; 1 prior block needed | same-block propose reverts; next-block works; sell 50k immediately; proposal still `Pending` |
| `test_08_whaleAgainst_Defeated` | The real blocker | 3.05M `For` vs 39.4475M `Against` → **Defeated**, queue reverts, **loss $20.54** |
| `test_09_deployerAgainst_stillSucceeds` | Deployer cannot stop it | 3.05M `For` vs **59,735** `Against` → **Succeeded** |
| `test_10_unopposed_passesAndExecutes` | Conditional upside | drains 26.858M UP + 6.431 ETH + 2,697 USDC + 0.497 WETH; UP leg realises **4.4974 WETH ($9,540)**; **net $26,914** |
| `test_11_cancelWindow` | Cancel only while Pending | proposer cancel succeeds while `Pending`; reverts after voting starts |

CI artifact: `result-unlock-activity` (live-state JSON, full `proposals.csv`/`votes.csv`); `ci-log.txt`; `ci-out/live-state.json`.

---

## 8. Verdict, residual risk, blockers

**Verdict: E-U ≈ $0 (MEDIUM confidence; on-chain activity data high, future voter behaviour medium).** The mechanism is real and cheap — **0.3% quorum ($3,512), 1-block hold, no deposit, 99.4% recoverable capital, $20.54 failure cost** — but the **vote is the binding constraint**, and Unlock's governance is **actively defended**: a 39.45M whale that votes `Against` on every contentious proposal, a 13.69M steward coalition that defeated the last capture, a 390.56M undelegated Safe, and 0/2 observed capture successes. The deployer's 59.7M-vote premise is a **1000× decimal error**; it cannot stop a 3M `For`.

**Latent risk (what would re-arm it):**
- The 39.45M whale undelegates, goes inactive for a specific 10-day window, **and** the 13.69M stewards do not escalate → a 13.69M stake ($180k) wins with $26.9k upside.
- The 390.56M Safe delegates to a single address (39% of supply) — either a defence boost or, if that key is compromised, a catastrophic capture.
- UP liquidity deepens so >47.11M becomes cheap (currently impossible: the pool holds 14.53M).
- The 50k threshold enables governance spam (already observed: 51 proposals in Sept 2026); spam does not drain funds but can fatigue voters and lower turnout.
- The UPSwap's 54.08M UP is a fixed-price 1000 UP/UDT source; if a large UDT holder (or an OTC buyer) converts, it adds 54M UP of potential sell pressure and could fund a 13.7M+ stake outside the DEX.

**Blockers:** (i) 39.45M whale + 13.69M stewards; (ii) the DEX cannot supply >14.53M UP, and 13.69M costs $180k with $165k mark-to-market risk; (iii) the 4-day public delay + 6-day vote give the DAO 10 days to react; (iv) no CEX/OTC public route to a larger stake.

---

## 9. Methodology, sources, caveats, files

- **Live reads** at Base block **55,433,658** (tests) / **55,433,572** (CI state dump): `eth_call`, `eth_getBalance`, `eth_getLogs`. Addresses/roles/balances are in `analysis/live-state.json`, `ci-out/live-state.json`, `analysis/proposals.csv`, `analysis/votes.csv`.
- **Full proposal history:** `eth_getLogs` on the governor from deployment block **18,036,287** to latest via a public-archive RPC; **2,079 logs** decoded with `eth_abi` → **158 `ProposalCreated`**, **1,710 `VoteCast`**, 100 `ProposalQueued`, 99 `ProposalExecuted`, 1 `ProposalCanceled`. Decoder: `analysis/decode_governance.py`.
- **Prices:** DefiLlama `coins.llama.fi` — UP **$0.001117392**, ETH **$2,121.2647** (2026-11-10). Spot values are 3M × price; executable costs are fork-measured through SwapRouter02.
- **Fork PoC:** `poc/test/UnlockActivity.t.sol`, Base fork, public RPC only; **11/11 PASS** on GitHub Actions run **42741782318**.
- **Sources:** verified governor/timelock/UP implementations from the pass7 source dumps (`unlock-gov/analysis/`); UPSwap source via Sourcify v2 (`0x59dd472b…`); UP token source (`0xf52ce8bc…`); `getReserveData`/`getConfiguration` on Aave V3 Base, `getAssetInfoByAddress` on Compound III.
- **Caveats:** (i) governance behaviour is social, not code — the p estimates are calibrated judgment, not a model; (ii) the 13.69M mark-to-market/MEV exposure is execution-dependent (private order flow could eliminate it); (iii) the UPSwap/UDT route is OTC-gated and its depth is unknown; (iv) the timelock/price state is point-in-time 2026-11-10; re-read before acting; (v) the `getPastVotes` 1-block hold assumes Base produces a block at/after the snapshot timestamp — a skipped block only widens the hold by one block, not four days.

## 10. Files

```
unlock-activity/
├── README.md                       # this file
├── summary.json                    # machine-readable
├── analysis/
│   ├── decode_governance.py        # ProposalCreated/VoteCast decoder
│   ├── dump_live_state.py          # CI live-state dumper (public RPC only)
│   ├── gov_logs_raw.json           # 2,079 raw governor logs
│   ├── governance_decoded.json     # 158 proposals + 1,710 votes (decoded)
│   ├── proposals.csv               # one row per proposal
│   ├── votes.csv                   # one row per VoteCast
│   ├── activity_summary.json       # turnout/outcome aggregates
│   ├── up_mint_logs.json           # 1B UP mint to the UPSwap
│   ├── upswap_udt_to_up.json       # 543 UDT→UP conversions (947.7M UP distributed)
│   └── up_transfer_logs.json       # raw log-query error (documented negative)
├── poc/                            # Foundry project (vendored forge-std)
│   ├── foundry.toml
│   └── test/UnlockActivity.t.sol   # 11 tests, 11 PASS
├── ci/run.sh                       # live-state + activity dump
├── ci-out/live-state.json          # CI artifact
├── ci-log.txt                      # CI run 42741782318
└── ci-artifacts/result-unlock-activity/…
```
