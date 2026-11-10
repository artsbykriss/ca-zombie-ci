# CA3 · C5 — HAI governance re-check (Optimism, chain 10)

**2026-11-10** · read-only; fork-verified only (GitHub Actions Foundry fork at block 159,337,108); **no mainnet transactions signed or sent**.

**Question.** CA3 re-opened C5 on the theory that the KITE price collapse made the 5 % quorum cheap again. This dossier re-verifies the live state, prices the acquisition of the quorum stake through every available route, fork-tests the capture, and reconciles with the ZH4-01 closure.

**Answer:** the re-opening premise is a data error. KITE is **$0.3086**, not $0.1139 (90-day low = $0.3071), quorum is **48,698.35 KITE ≈ $15,030.55**, and the live defence bloc is **122,423.63 votes**, not 41,155. A quorum-sized stake is sourceable from one whale, but it loses the vote 122,423.63 → 48,698.35 (fork-proven), and the treasury's KITE is only realizable at **$6,508**. **Live unprivileged extraction: $0.** Conditional stock: up to ~$808k *if* an attacker wins a 5-day public vote with 122,423.63 KITE = 71 % of the entire EOA float — which has no market route.

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why closed / open | Latent risk |
|---|---|---|---|
| **HAI Governor** `0xe807…3777` | **$0** | quorum 48,698.35 KITE ($15.0k) but the live defence bloc is 122,423.63 votes; a quorum-only proposal is **Defeated** (fork test 02) | Re-arms only if the defence bloc undelegates/sells, or an attacker sources 122k+ KITE OTC |
| **Treasury Safe** `0xDCb4…6724` (owner = Timelock, 1-of-1) | **$0** | reachable only through the Governor; underlying KITE exits at $6,508 | Direct prize is small in realizable terms |
| **StakingManager** `0x1250…BC90` (310,511 KITE, Timelock authorised) | **$0** | same governance gate; KITE exit already saturated by the treasury leg | — |
| **HAI SAFEEngine** `0x9Ff8…A700` (Timelock authorised; $801.4k collateral) | **$0** | the drain is a *governance* capability, not an unprivileged one; fork-proven only after the vote | **The real prize** — $678k proven on three joins |
| **KITE token mint** (Timelock authorised) | **$0** | mint requires the same vote; minted KITE has no exit liquidity | — |

**Total live extractable now: $0.00 (high confidence).**
Conditional (post-vote) prize: **~$808k** — but the gate is a stake equal to **71 % of all EOA-held KITE**, with no CEX, no bridge and $6.8k of DEX quote liquidity.

---

## 2. The mechanism, exactly

`HaiGovernor` is an OpenZeppelin v5 Governor stack:

```
Governor + GovernorSettings + GovernorCountingSimple + GovernorVotes
        + GovernorVotesQuorumFraction + GovernorPreventLateQuorum + GovernorTimelockControl
```

Verified source: `HaiGovernor` at `0xe807f3282f3391d237BA8B9bECb0d8Ea3ba23777` (Optimism, compiler 0.8.20).
Timelock: `0xd68e7D20008a223dD48A6076AAf5EDd4fe80a899`, `getMinDelay() = 86,400`.
Token: `ProtocolToken` (`KITE`) `0xf467C7d5a4A9C4687fFc7986aC6aD5A4c81E1404` — OZ ERC20Votes, `clock() = timestamp`, `CLOCK_MODE = "mode=timestamp"`.

**Live parameters (block 159,337,291):**

| Parameter | Value |
|---|---|
| `quorumNumerator()` | **5** (5 %) |
| `quorum(now−1)` | **48,698.35e18** |
| `proposalThreshold()` | **20,000e18** |
| `votingDelay()` | **43,200 s** (12 h) |
| `votingPeriod()` | **432,000 s** (5 d) |
| `lateQuorumVoteExtension()` | 86,400 s (1 d) |
| `guardian()` | **reverts — no guardian** |
| Timelock roles | PROPOSER/EXECUTOR/CANCELLER = Governor; TIMELOCK_ADMIN = **unassigned** |
| `totalSupply()` | **973,967e18** (973,967 KITE) |

**The capture path.** Acquire ≥ threshold → `propose` a Timelock batch → vote For → `queue` → wait
86,400 s → `execute`. The timelock is the sole owner of the treasury Safe (`getOwners() = [TL]`,
`getThreshold() = 1`, `nonce = 79`), so the batch can call `Safe.execTransaction` directly
(`approveHash` + pre-validated signature `r=TL, s=0, v=1`).

**Timing constraint (snapshot).** In OZ v5 `proposalSnapshot = clock() + votingDelay()`.
Votes are read with `getPastVotes(account, snapshot)`, so:

* delegation must be checkpointed **before voteStart** (12 h after proposal);
* a proposal can be created with 20,000 KITE and the remaining 28,698.35 acquired **during** the 12-h delay;
* **tokens can be sold immediately after the snapshot and still vote** — the holding period is ~12 h, not the full 5 days.

**Not flash-loanable.** Votes come from timestamp checkpoints (`getPastVotes` / `getPastTotalSupply`), not current balances. A one-transaction flash loan cannot create a checkpoint before the snapshot. No KITE money market surfaced in the listing/holder review, so there is also no 12-h borrow to bridge the snapshot.

**The treasury's KITE does not vote.** `getVotes(SAFE) = 0`, `delegates(SAFE) = 0x0`. Quorum is a
fraction of `getPastTotalSupply`, so the attacker must supply their own 48,698.35 votes. Delegating
the treasury's 328,143.98 KITE is an *outcome* of the capture, not a prerequisite.

---

## 3. Live-state assessment (all reads at explicit blocks)

### 3.1 Governor / timelock / token

| Item | Value | Call |
|---|---|---|
| `quorumNumerator` | 5 | `quorumNumerator()` |
| `quorum(TS−1)` | 48,698.35e18 | `quorum(uint256)` |
| `proposalThreshold` | 20,000e18 | `proposalThreshold()` |
| `votingDelay` / `votingPeriod` | 43,200 / 432,000 | getters |
| `lateQuorumVoteExtension` | 86,400 | getter |
| `guardian()` | revert | no guardian |
| `totalSupply` | 973,967e18 | `totalSupply()` |
| `paused()` | false | getter |
| Timelock `getMinDelay` | 86,400 | getter |
| `hasRole(PROPOSER/EXECUTOR/CANCELLER, GOV)` | true/true/true | `hasRole` |
| `hasRole(TIMELOCK_ADMIN, GOV)` | **false** | role unassigned → delay cannot be changed |
| `authorizedAccounts(TL)` on KITE | **true** (mint authority) | `authorizedAccounts` |
| `authorizedAccounts(TL)` on HAI | **true** (mint authority) | `authorizedAccounts` |
| `authorizedAccounts(TL)` on SAFEEngine | **true** | `authorizedAccounts` |
| `contractEnabled()` SAFEEngine | true | getter |

Authorised KITE accounts: `0xd68e7D20…a899` (Timelock), `0x7CdE0d72…17b3`, `0xCb96543b…9E02`.

### 3.2 Treasury Safe and assets

`0xDCb421Cc4Cbb7267F3b2cAcAb44Ec18AEbEd6724` — GnosisSafeL2 1.3.0, owners `[Timelock]`, threshold **1**, **nonce 79** (unchanged since the Oct-18 hardening; no pending tx).

| Asset | Amount | USD @ 2026-11-10 |
|---|---|---|
| KITE | 328,143.981253588267391953 | $101,280.29 |
| OP | 462.947729816 | $46.43 |
| WETH | 0.01 | $21.27 |
| VELO | 0.6360389380706 | $0.02 |
| **Mark total** | | **$101,348.01** |
| **Realizable via DEX** | KITE dump = 4,520.31 HAI + 10,988.80 OP | **$6,576.02** |

The gap between mark and realizable is the whole story: the two Velodrome pools hold **$6,827.59**
of quote assets against 22,220.21 KITE. Dumping 328,143.98 KITE returns $6,508 (fork test 05).

### 3.3 Staking / vesting / other KITE

| Contract | KITE | Governance reach |
|---|---|---|
| `StakingManager 0x1250f232…BC90` | **310,511.02** | `authorizedAccounts(TL)=true` — admin path |
| `VotingTokenVestingPlans 0x1bb64AF7…Ef82` | 89,442.74 | not timelock-authorised (no claim found) |
| Velodrome KITE/HAI | 18,606.23 | public pool |
| Velodrome OP/KITE | 3,613.98 | public pool |
| RewardDistributor / VotingVaults / Safes / PoolManager | ~35,000 | public contracts |
| **All EOAs (1,603 addresses)** | **171,750.63** | free float |

Supply reconciliation: 973,967 total = 328,144 treasury + 310,511 staking + 89,443 vesting + 22,220 pools + 223,649 other. `sum(top-2000 holders) = 977,543.39` — +0.37% indexer drift vs `totalSupply` (holder snapshot taken earlier than the supply read; the staking balance accrues).

### 3.4 Live delegated votes — the decisive number

`getVotes` scanned over all 2,000 indexed holders + Governor + Timelock at block 159,336,403:

| Delegate | Votes | Share |
|---|---|---|
| `0x297BF847Dcb01f3e870515628b36EAbad491e5E8` | 52,202.96 | 39.8 % of delegated |
| `0xCAFd432b7EcAfff352D92fcB81c60380d437E99D` | 41,580.38 | 31.7 % |
| `0xBad58e133138549936D2576ebC33251bE841d3e9` | 20,921.70 | 16.0 % |
| `0x35d067D337Dd3F7E2BBb4367bed467DCfae1E1fb` | 4,016.60 | 3.1 % |
| `0x9492510BbCB93B6992d8b7Bb67888558E12DCac4` | 3,702.01 | 2.8 % |
| **Defence bloc** | **122,423.63** | **12.57 % of supply** |
| Total delegated (all others) | 131,098.14 | 13.46 % of supply |

`0x297BF847` has held ~52k votes for >12 months (`getPastVotes` −1 d/−7 d/−30 d/−365 d ≈ 52.2k–54.2k) — it is a standing delegate, not a new accumulator. `0xCAFd432b` grew from 41,155 (Oct 18) to 41,580; `0xBad58e` from 18,488 to 20,922.

**This is the correction to CA3.** CA3 counted only `0xCAFd432b` (41k). The bloc is **122,423.63
votes — 3.0× what CA3 assumed and 2.51× the quorum.**

### 3.5 Prices

| Asset | Price | Source |
|---|---|---|
| KITE | **$0.308646** | DefiLlama `coins.llama.fi` ts 1794269276; CoinGecko 0.309064; DexScreener 0.3094/0.3136 |
| KITE 90-day range | $0.3071 – $0.8355 | CoinGecko market_chart |
| OP | $0.100293 | DefiLlama |
| WETH | $2,127.24 | DefiLlama |
| HAI | $1.19587 | DefiLlama |

**None of the three independent price sources shows $0.1139.** The 90-day low is $0.3071. CA3's
`$0.113859` is unsupported; the `$37.4k` treasury and `$5,545` quorum both derive from it.

### 3.6 Governance liveness

Last Governor event: `ProposalExecuted` + `QuorumNumeratorUpdated` + `ProposalThresholdSet` +
`VotingPeriodSet` at block **158,342,971 (2026-10-18 00:51:59 UTC)** — the hardening execution.
**Zero `ProposalCreated`/`VoteCast` since.** The 858-proposal spam war is over; the attacker EOAs
(`0xDC6A914c…`, `0x1472934131…`) hold 0 KITE / 0 votes.

### 3.7 The protocol prize (P-class, but fork-proven)

HAI TVL $801,379 (DefiLlama, live): WETH $398,932 · wstETH $270,214 · rETH $80,953 · VELO $29,767 · TBTC $9,840 · OP $6,276 · alETH $4,152 · msETH $1,245.

The Timelock is an authorised account on `SAFEEngine 0x9Ff826860689483181C5FAc9628fd2F70275A700`
(`authorizedAccounts(TL) = true`, `contractEnabled = true`; 14+ live collateral types updating every
~10 s). That gives `modifyCollateralBalance(cType, account, +wad)` — credit internal collateral from
nothing — and the join's `exit(account, wad)` then transfers the real ERC-20 out:

| Join | Asset | Balance | USD |
|---|---|---|---|
| `0xbE57D71e81F83a536937f07E0B3f48dd6f55376B` | WETH | 187.18917 | $398,151 |
| `0x77a82b65F8FA7da357A047B897C0339bD0B0B361` | wstETH | 101.57000 | $270,176 |
| `0x99E2b46c584382D9668a1DBc64A9a23D2828F74B` | TBTC | 0.131339 | $9,840 |
| **Fork-proven subtotal** | | | **$678,167** |

Fork test 04 executed exactly this: `modifyCollateralBalance` from the Timelock, then `exit` from the
attacker, moving all three assets. (A call from a zero-balance account reverts with an arithmetic
underflow, so the join is not independently drainable — the SAFEEngine credit is the required step.)

The same primitive applies to the rETH/VELO/OP/alETH/msETH joins by code identity; the full TVL is
$801k. **This is a governance capability, not an unprivileged one** — it requires winning the vote.

---

## 4. Capital acquisition — every route

Full routemap: `analysis/acquisition-routes.md`.

| Route | Capacity | Verdict |
|---|---|---|
| Velodrome KITE/HAI `0xf2d3…15d1` | 18,606 KITE / $5,713 quote | cannot fill quorum; 20k costs $61.7k |
| Velodrome OP/KITE `0xf463…7238` | 3,614 KITE / $1,114 quote | same |
| **Optimism DEX total** | **22,220 KITE** | **< 50 % of quorum; 5.5× short of the winning stake** |
| CEX | **none** — CoinGecko tickers = 2 Velodrome pools only | no route |
| Bridges / other chains | **none** — DexScreener returns 11 pairs, all OP | no route |
| OTC — single whale | `0xE207…2067` = 51,118.88 KITE | **quorum reachable from one seller** |
| OTC — winning stake | 122,423.63 = **71.3 % of the 171,750.63 EOA float** | requires 6–8 whales to sell; not a market purchase |
| Flash loan | no KITE lending market; votes are timestamp checkpoints | **impossible** |

**Cost table (30 bp fee, best split across pools; OTC at spot or 2×):**

| Scenario | Cost | Realizable treasury | Net vs treasury | Net vs protocol |
|---|---|---|---|---|
| Quorum, spot OTC | **$17,547** | $6,576 | **−$10,971** | — |
| Quorum, 2× OTC | **$29,490** | $6,576 | **−$22,914** | — |
| Win 122,423.63, spot OTC | **$47,384** | $6,576 | **−$40,808** | +$727k |
| Win, 2× OTC | **$80,541** | $6,576 | −$73,965 | +$694k |

**Answer to the mandate's question:** the all-in cost of 48,698.35 KITE is **$17.5k–$29.5k**, versus
a treasury whose KITE is realizable at **$6,508** (mark $101,348 is not achievable — the pools hold
$6,828 of quote assets). **Against the treasury, it is net-negative.** It becomes net-positive only
when the $801k of HAI collateral is included — and that requires the 122k-vote win.

---

## 5. What an attacker can and cannot do

**Can (fork-proven):**
1. Buy/OTC 48,698.35 KITE, delegate, propose, vote For, queue, wait 1 day, execute → drain the Safe
   (test_01: captured 328,143.98 KITE with 0 Against).
2. With 130,000 KITE, beat the live 122,423.63-vote bloc and execute (test_03: captured KITE + 462.95 OP).
3. After winning, use `SAFEEngine.modifyCollateralBalance` + `CollateralJoin.exit` to move $678k of
   proven collateral (test_04), mint HAI (`HAI.authorized(TL)=true`), mint KITE, and pull the
   StakingManager's 310,511 KITE.

**Cannot:**
1. Pass with a quorum-only stake while the bloc votes — **defeated 122,423.63 → 48,698.35** (test_02).
2. Flash-loan the votes (timestamp checkpoints).
3. Buy the stake on a DEX (only 22,220 KITE exists in pools; 20k costs $61.7k).
4. Buy on a CEX or bridge from another chain (none exist).
5. Skip the 6.5-day cycle: 12 h delay + 5 d vote + 1 d timelock (+1 d if quorum is reached in the last day).
6. Use a guardian/canceller shortcut: no guardian; `TIMELOCK_ADMIN` unassigned; the Governor is the only proposer.

**Is there a faster path?** No. The only other governance-reachable surfaces (KITE/HAI mint,
StakingManager, SAFEEngine) are all downstream of the same `propose → vote → queue → execute`
pipeline. The Governor can change its own voting parameters only through the same full proposal cycle (the Oct-18 hardening did exactly that), and the Timelock's 1-day delay cannot be changed at all (`TIMELOCK_ADMIN` unassigned).

---

## 6. Fork verification

**CI run (final):** https://github.com/artsbykriss/ca-zombie-ci/actions/runs/42735188726 · earlier run: https://github.com/artsbykriss/ca-zombie-ci/actions/runs/42734157127
**Suite:** 6 passed / 0 failed, fork block **159,337,108** (Optimism), ~12 s.
**Files:** `poc/test/HaiCapture.t.sol`, `poc/foundry.toml`, vendored `poc/lib/forge-std`.
**State override label:** the attacker's KITE is injected with `deal` (balance slot write) and then
checkpointed via `delegate()` — **hypothetical capital**, clearly not an on-chain balance. Defender
votes use the **real, undealt** live delegations (no override).

| Test | Scenario | Result |
|---|---|---|
| 01 | 48,698.35 KITE, nobody votes Against | **PASS** — proposal Succeeded, executed, Safe KITE 328,143.98 → attacker |
| 02 | 48,698.35 For vs live bloc 122,423.63 Against | **DEFEATED** (state 3) — *quorum is not enough* |
| 03 | 130,000 For vs live bloc | **PASS** — Succeeded, executed; captured 328,143.98 KITE + 462.95 OP |
| 04 | Timelock-authorized collateral seizure | **PASS** — 187.19 WETH + 101.57 wstETH + 0.1313 TBTC moved |
| 05 | Exit liquidity of captured KITE | 328,143.98 KITE → 4,520.31 HAI + 10,988.80 OP ≈ **$6,508**; pools hold 22,220.21 KITE total |
| 06 | Supply/quorum math | quorum = 48,698.35; treasury/quorum = 6.738× |

Gas: 1.80M (quorum-only execute) / 2.07M (130k execute) / 0.50M (collateral seizure). At OP gas
prices this is cents; gas is irrelevant to the verdict.

Also in CI: `ci/run.sh` wrote `ci-out/op_state.json` with the live governor/token/Safe/HAI/pool reads
at the run block. `ci-out/` and `poc/out/` artifacts are uploaded.

---

## 7. Reconciliation with ZH4-01 (and CA3)

| Item | ZH4-01 (2026-10-17) | ZH4-P2 (2026-10-18) | **CA3 (2026-11-09)** | **This re-check (2026-11-10)** |
|---|---|---|---|---|
| quorum | 1 % = 9,740 KITE | 5 % = 48,698 KITE | 5 % = "48,698,350" KITE | **5 % = 48,698.35 KITE** |
| quorum USD | $3.6k | $16.5k | $5,545 | **$15,030.55** |
| threshold / period | 5,000 / 3 d | 20,000 / 5 d | 20,000 / 5 d | **20,000 / 432,000 s** |
| KITE price | $0.3722 | $0.33949 | $0.113859 | **$0.308646** |
| Treasury mark | $122k | $111.5k | $37.4k | **$101,348** |
| Defence bloc | 73,936 | 73,936 | "41,155" | **122,423.63** |
| DEX depth | $8.1k | $16.4k | "smaller now" | **$6,828 quote / 22,220 KITE** |
| Verdict | CLOSED | CLOSED | "re-opened, CRITICAL" | **$0 live; conditional** |

**What actually changed since the closure:** the hardening held (5 % / 20k / 5 d, guardian-less), the
defence bloc **grew 66 %** (73.9k → 122.4k), the DEX quote depth **fell 58 %** ($16.4k → $6.8k), and
KITE fell 9 %. None of that re-opens the attack; the last two make it harder.

**Why CA3's re-opening is stale:**
1. **Price error.** $0.113859 is not observed by DefiLlama, CoinGecko (90-day low $0.3071) or
   DexScreener. At the true $0.3086 the quorum is $15,030.55, not $5,545.
2. **Decimal error.** "48,698,350 KITE" is 1,000× the on-chain `quorum()` of 48,698.35e18. The
   `$5,545` number is internally consistent with 48,698 KITE at $0.1139 — so the prose figure is the typo.
3. **Defence undercount.** CA3 uses the single 41,155-vote delegate. The live bloc is 122,423.63
   (five delegates), i.e. 2.51× quorum; a quorum-only proposal is defeated (fork test 02).

**Why the prior "no re-arm needed" is still correct:** the attack was gated by token acquisition and
the defence bloc in October, and both gates are *wider* today. The only genuinely new fact is the
fork-proven $678k collateral-seizure primitive — but it sits behind the same vote, and the winning
stake is 71 % of the EOA float. The monitor should stay on `ProposalCreated` / large `DelegateChanged`
/ KITE OTC accumulation, not on the price.

---

## 8. Verdict, confidence, residual risk

**Verdict: $0 live extractable by an unprivileged attacker (high confidence).** Conditional
critical-grade value (~$808k) exists but requires a vote-winning stake that has no market route.

**Confidence:**
- Live governor/token/Safe/HAI state, votes, prices, DEX depth: **high** (on-chain + three price sources).
- Vote arithmetic and the 6.5-day timeline: **high** (fork-proven end-to-end).
- Collateral seizure: **medium-high** — the exact calls succeed on a fork and the SAFEEngine/joins are
  live; the full $801k depends on the remaining joins and on no emergency pause/`disableContract`.
- Acquisition cost: **medium** — OTC premiums are unobservable; the DEX leg is exact.

**What would change the verdict (monitors):**
1. The defence bloc undelegating/selling (total delegated falls below ~50k) → quorum-only capture becomes live again.
2. A CEX listing or a deep KITE pool → acquisition becomes possible.
3. A single wallet accumulating ≥122k KITE (`DelegateChanged`/`Transfer`).
4. Any new `ProposalCreated` (none since 2026-10-18).
5. Governance adding a guardian or raising quorum again.

**Blockers:** no CEX; no bridge float; 22,220 KITE in pools; 122,423.63-vote defence; 6.5-day public
window; treasury KITE exit capped at $6,508.

---

## 9. Methodology, sources, files

**Method.** (1) Live reads at explicit blocks via public OP RPC (`cast call`, `getPastVotes`,
`getPastTotalSupply`, `getReserves`, EIP-1967 slots, `authorizedAccounts`). (2) Blockscout v2 for
verified source, holders (2,000 addresses paged) and token balances. (3) Delegation census:
`getVotes` over all indexed holders + Governor + Timelock (batched `eth_call`). (4) Acquisition
routing: DexScreener token lookup, CoinGecko tickers/market chart, DefiLlama prices, Velodrome pool
reserves and constant-product cost curves. (5) Protocol prize: DefiLlama TVL breakdown,
`SAFEEngine.authorizedAccounts`, `CollateralJoinChild` code and balances. (6) Foundry fork PoC on
GitHub Actions (pinned recent block, `deal` for the attacker's hypothetical KITE, real defender
delegations) → propose/vote/queue/execute + collateral seizure + exit-liquidity curve.

**Sources of truth:** `zombie-hunt-iv/README.md` ZH4-01; `zombie-hunt-iv/wave2/d2c-dormantdao.md`;
`ci/ZH4-RESULTS-TRACKER.md`; `ca3/README.md` §C5. Corpus is a lead source, not ground truth — every
number here is re-read on-chain.

**Caveats.**
- Fork block 159,337,108; live values move (the staking balance accrues, prices move). USD figures
  are pinned to 2026-11-10 prices as stated.
- The attacker's 48.7k/130k KITE is a **state override** (`deal`); no such balance exists on-chain.
- The treasury mark ($101,348) is not achievable; the realizable figure ($6,508) assumes both pools
  are drained and is an upper bound.
- HAI collateral seizure is a governance capability; it is *not* reachable without the vote, and it
  would likely trigger off-chain responses (pause, `disableContract`) not modelled here.
- OTC cost is modelled at spot and 2×; real block-trade premiums are unobservable.

**Files.**
```
ca3-hai/
├── README.md                       (this file)
├── summary.json                    machine-readable
├── analysis/
│   ├── live_state.json             governor/token/Safe/HAI at block 159,337,291
│   ├── economics.json              every number used in the verdict
│   ├── acquisition-routes.md       full routemap
│   ├── holders.csv / holders.py    2,000-holder census
│   ├── votes_scan.py / votes_scan.json  delegated-vote census
│   └── snapshot.sh                 re-runnable state snapshot
├── poc/                            Foundry fork PoC (6 tests)
├── ci/run.sh                       CI state snapshot → ci-out/op_state.json
├── ci-out/op_state.json            CI-run live state
├── ci-log.txt / ci-artifacts/      CI logs + artifacts
```
