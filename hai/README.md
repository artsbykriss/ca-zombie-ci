# ZH4-01 — HAI ("Let's Get HAI"): governance-capture race on Optimism

**Date:** 2026-10-18 · **Chain:** Optimism (10) · **Latest block:** 158,341,534 (2026-10-18T00:04:05Z)
**Status:** read-only; fork-simulated with `eth_call` state override; **no mainnet transactions**. All figures are live reads at the stated block, priced with DefiLlama/DEX Screener at read time.

---

## TL;DR

| Question | Answer |
|---|---|
| **Is the race live?** | **Structurally yes, operationally dormant.** Quorum is still **1%** (9,739.67 KITE), threshold **5,000 KITE**, voting period 129,600s. The hardening proposal is **approved and queued but NOT executed**. The attacker stopped proposing on **2026-10-14 12:52 UTC** and liquidated all 9,768.5 KITE by 14:40 UTC. No proposals, votes or executions since 2026-10-16 03:53 UTC (verified by `eth_getLogs` to block 158,341,534). |
| **Live E-U extraction today** | **$0 permissionless** for an unprivileged attacker; **$195,568.43 conditional** if it can acquire 73,936.06 KITE OTC. A new attacker must outvote a **73,936.06 KITE** defender bloc (7.59% of supply). The two KITE DEX pools hold only **23,737.01 KITE** in total, so the required votes cannot be bought on-chain. The Oct 8–14 attacker's own 9,768.50 KITE FOR votes lost to 46,155–71,768 AGAINST on every proposal it actually voted on. |
| **Value at risk if defence lapses / is outvoted** | **$195,568.43 direct** = Treasury **$101,480.77** (328,143.98 KITE + 462.95 OP + 0.01 WETH + 0.64 VELO) + StakingManager **$94,087.66** (304,489.09 KITE, Timelock is the sole authorized account). Plus **$916,806** HAI protocol TVL and **unbounded mint authority** over KITE (FDV $300,957) and HAI (FDV $367,355). |
| **Cost to capture if defence lapses** | **~$5,099** to buy the 9,739.67 KITE quorum on DEX (1.7× spot; spot value $3,009.57) + ~$0.05 gas, over a 3-day proposal→timelock cycle. |
| **Cost to capture against current defence** | **≥73,936.06 KITE ≈ $22,846.37 spot**. Not purchasable on DEX (float 23,737 KITE); requires OTC/social acquisition from a whale or a delegation shift. |
| **Hardening** | Proposal `0xe58085b0…` state **Queued**; timelock op `0x52aa3307…` **ready since 2026-10-17 03:53 UTC**, **not executed** 20h later. `execute()` succeeds from **any EOA** (fork-proven). It would set quorum **5% (48,698.35 KITE)**, threshold **20,000 KITE**, voting period **432,000s**. |
| **Confidence** | **High** on mechanics, balances, roles and current votes. **Medium** on the conditional E-U and on whether 74k KITE can be sourced OTC; that is not visible on-chain until it happens. |

**Verdict:** the specific attack **failed and was abandoned**, but the vulnerability is **not closed**. The protocol remains one unexecuted transaction away from raising quorum above the entire DEX float. This is a **conditional CRITICAL**: $0 permissionless today, $195,568.43 direct (+$916,806 TVL exposure) if 73,936 KITE is acquired OTC or the defence lapses.

---

## 1. The mechanism, exactly

The Governor is a stock OpenZeppelin `Governor` with `GovernorSettings`, `GovernorCountingSimple`, `GovernorVotesQuorumFraction`, `GovernorPreventLateQuorum` and `GovernorTimelockControl` (`HaiGovernor.sol`, verified source in `analysis/gov_src.json`).

Live parameters (block 158,341,534):

| Parameter | Value |
|---|---|
| `votingDelay()` | 43,200s (12h) |
| `votingPeriod()` | 129,600s (36h) |
| `proposalThreshold()` | 5,000 KITE (0.513% of supply) |
| `quorumNumerator()` | **1** (1%) |
| `quorum(now)` | **9,739.67 KITE** |
| Timelock `getMinDelay()` | 86,400s (24h) |
| Governor → Timelock roles | `PROPOSER`, `CANCELLER`, `EXECUTOR` all held by the Governor |

The capture path is:

1. Attacker holds ≥5,000 KITE at proposal time (or receives a delegation), calls `Governor.propose(targets=[TreasurySafe], values=[0], calldatas=[Safe.execTransaction(...)], description)`.
2. 12h later the snapshot is taken; attacker votes FOR. If `forVotes ≥ 9,739.67` **and** `forVotes > againstVotes`, the proposal succeeds.
3. `Governor.queue(...)` → `Timelock.scheduleBatch(..., delay=86,400)`.
4. After 24h, **anyone** can call `Governor.execute(targets, values, calldatas, descriptionHash)`; the Timelock calls the Treasury Safe.
5. The Safe owner is the **Timelock**, threshold **1**. The payload supplies a `v=1` owner-approval signature (`r=Timelock, s=0, v=1`); Safe accepts it because `msg.sender == owner == Timelock`.
6. Safe `delegatecall`s MultiSend (`0xA238CBeb…`), which executes six calls **as the Safe**:

| # | Call | Amount |
|---|---|---|
| 0 | `KITE.approve(StakingManager, …)` | 50,000 KITE |
| 1 | `KITE.transfer(RewardDistributor, …)` | 500 KITE (camouflage) |
| 2 | `KITE.approve(RewardDistributor, …)` | 50,000 KITE |
| 3 | `OP.transfer(0x468c…, …)` | 100 OP (camouflage) |
| 4 | **`KITE.delegate(0x1472934131f7af94f3cf2542b6121a44d236cf39)`** | **327,643.98 KITE voting power** |
| 5 | `KITE.approve(0x468c…, …)` | 10,000 KITE |

The delegate call does **not move tokens**; it moves the Treasury's 327,643.98 KITE of voting power (33.64% of supply) to the attacker. That is already more than enough to pass any subsequent proposal (the defender bloc is 73,936). The attacker can then:

- transfer the Treasury's 328,143.98 KITE, 462.95 OP, 0.01 WETH and 0.64 VELO to itself;
- call `StakingManager.emergencyWithdraw(attacker, 304,489.09 KITE)` — the Timelock is the **only** authorized account on the StakingManager;
- mint KITE and HAI — the Timelock is an **authorized minter** on both tokens;
- change protocol parameters / oracles through whatever else the Timelock controls.

The Safe's `delegates(Safe)` is currently **zero**, so the capture has not happened; the Treasury still holds all 328,143.98 KITE.

---

## 2. The attack that actually happened

| Fact | Value |
|---|---|
| Attacker main | `0xDC6A914c4fA69917f4bc6A93cCe46CC348a6ec0c` |
| Attacker second | `0x1472934131f7af94f3cf2542b6121a44d236cf39` |
| Both are EIP-7702 EOAs | code `0xef0100` + impl `0x63c0c19a282a1b52b07dd5a65b58948a07dae32b`; nonces 882 / 31 |
| KITE acquisition | 5,274.748781996288 from `0xCc7B4a64…` (2026-10-08 15:42) + 4,493.755683726184 from `0xF4Bf778d…` to the second EOA (15:43); 1,000 moved between them. **Peak 9,768.504465722472 KITE.** |
| Proposals | **858** total (2026-10-08 17:34 → 2026-10-14 12:52), of which **851 are the identical delegate payload** (first 2026-10-12 02:26:29) |
| Vote attempts | 8 proposals received FOR votes, all exactly **9,768.504465722472 KITE** (just above the 9,739.67 quorum). Only **2** of those were delegate-payload proposals (Oct 12 02:26 and Oct 13 15:40). |
| Result | **All 858 defeated.** Against votes were 46,155.02 (Oct 9) → 65,104.31 (Oct 12) → 65,462.36 (Oct 13) → 71,768.10 (Oct 14). The attacker never came within 35,000 votes of passing. |
| Exit | 2026-10-14 14:29–14:40: 4,000 KITE to `0x0a2854Fbbd…`; 5,768.504465722472 KITE to the KITE/HAI pool `0xf2d3941b6E…`. Both attacker EOAs now hold **0 KITE** and **0 votes**. |
| Gas | 866 governor txs, 106,911,971 gas, Blockscout L2 fee 1.1e-5 ETH (≈$0.03). Defender `0xCAFd…` spent 254,402,711 gas / 0.024358 ETH (≈$58.34) on 1,300 txs. Proposal spam is effectively free on OP; defence is ~2,000× more expensive in gas. (L1 data fee not fully captured by the `fee` field; still de minimis.) |

The defender coalition voted AGAINST on **every** attacker proposal. On the last 200 proposals it was four delegates:

| Delegate | Live votes (block−1) |
|---|---|
| `0xCAFd432b7EcAfff352D92fcB81c60380d437E99D` | 41,155.023163658253462783 |
| `0xE02e8AFcE6BFE464edA586E3a54ba9901FF2C81d` | 12,113.358768349716705194 |
| `0xBad58e133138549936D2576ebC33251bE841d3e9` | 18,183.533402805423336204 |
| `0x35d067D337Dd3F7E2BBb4367bed467DCfae1E1fb` | 2,484.140888312268198191 |
| **Total** | **73,936.05622312566 KITE (7.591% of supply)** |

The defence is delegated voting power, not owned KITE: `0xCAFd` holds only 2.48 KITE itself; one 20,403 KITE holder (`0x0a453F46…`) delegates to it. The bloc can shrink if delegators move.

The hardening proposal (`0xe58085b0c24b45029d65620b87dfe1ea98a411b1ecd127721433d6805ae65229`) was created by `0xCAFd…` on 2026-10-14 01:49, passed with **53,448.87 FOR / 0 AGAINST**, and was queued on 2026-10-16 03:53:17. It has been **ready to execute since 2026-10-17 03:53:17** but nobody has executed it. Our fork simulation shows a plain EOA calling `Governor.execute(...)` succeeds and sets the new parameters.

---

## 3. Live state at block 158,341,534

### Governor / Timelock
- Governor `0xe807f3282f3391d237BA8B9bECb0d8Ea3ba23777`; Timelock `0xd68e7D20008a223dD48A6076AAf5EDd4fe80a899`.
- `quorumNumerator()=1`; `proposalThreshold()=5,000e18`; `votingPeriod()=129,600`; `votingDelay()=43,200`.
- Hardening: `state=5 (Queued)`, `proposalEta=1792209197` (2026-10-17 03:53:17Z), timelock `isOperationReady=1`, `isOperationDone=0`, `getTimestamp=1792209197`.
- Timelock `PROPOSER_ROLE`/`CANCELLER_ROLE`/`EXECUTOR_ROLE` = Governor only; a direct `executeBatch` from an EOA reverts with `AccessControlUnauthorizedAccount`.
- Neither Governor nor Timelock is a proxy (EIP-1967 implementation slot = 0; runtime code 20,256 / 8,088 bytes).

### Treasury Safe `0xDCb421Cc4Cbb7267F3b2cAcAb44Ec18AEbEd6724`
- `getOwners() = [Timelock]`; `getThreshold() = 1`; `nonce() = 79`.
- KITE **328,143.981253588267391953**; OP **462.947729816**; WETH **0.01**; VELO **0.6360389380706**.
- `KITE.delegates(Safe) = 0x0` (not captured); the three allowances named in the payload (StakingManager, RewardDistributor, 0x468c…) are all 0.
- Spam airdrops (LARRY, BEARY, etc.) are present but worthless.
- USD at read time: **$101,480.77** (KITE $0.3090, OP $0.12903, WETH $2,395.46, VELO $0.03698).

### StakingManager `0x1250f2326F04ac61Ee5aEd92fEf74BcAC6E6BC90`
- KITE balance **304,489.089383841731990571** ($94,087.66).
- `authorizedAccounts() = [Timelock]` — **only** the Timelock. `emergencyWithdraw(address,uint256)` is `isAuthorized`, so a captured Timelock can send the entire staked KITE anywhere.
- `KITE.delegates(StakingManager) = 0x0`; its 304k KITE is **not voting**.

### Token authorities
- KITE `0xf467c7d5a4a9c4687ffc7986ac6ad5a4c81e1404`: total supply **973,967.0**; authorized accounts = `[Timelock, 0x7cde…, 0xcb96…]`. Timelock can **mint** KITE.
- HAI `0x10398abc267496e49106b07dd6be13364d10dc71`: total supply **303,745.53831565316**; authorized = `[Timelock, 0x30ce…]`. Timelock can **mint** HAI.

### Markets / liquidity
- KITE DEX liquidity **$14,702.99** in two Velodrome pools: KITE/HAI `0xf2d3941b…` ($11,616.28) and KITE/OP `0xf4638d…` ($3,086.71). Total KITE in both pools: **23,737.008 KITE** (spot $7,334.78).
- HAI DEX liquidity **$128,303.04** across 10 pairs (largest HAI/alUSD $57,286).
- KITE price $0.30900 → FDV $300,957; HAI price $1.20942 → FDV $367,355.
- HAI protocol TVL **$916,806** (DefiLlama `lets-get-hai`, 2026-10-17 23:42Z; the brief's $927k is consistent).

---

## 4. Capture economics

### 4.1 If the defender bloc is absent (the protocol's intrinsic risk)

| Item | KITE | USD (spot) |
|---|---|---|
| Quorum (1%) | 9,739.67 | $3,009.57 |
| **DEX cost to buy quorum** (both pools, 0.3% fee, optimal split) | 9,739.67 | **$5,099.07** (avg $0.5235/KITE, 1.69× spot) |
| Proposal threshold | 5,000 | $1,545.01 |
| Cycle | 12h delay + 36h vote + 24h timelock = **3 days** | — |
| Payoff: Treasury | 328,143.98 | $101,480.77 |
| Payoff: StakingManager | 304,489.09 | $94,087.66 |
| **Direct payoff** | 632,633.07 | **$195,568.43** |
| Protocol TVL exposure | — | $916,806 |
| Mint authority | unbounded KITE + HAI | KITE FDV $300,957 / HAI FDV $367,355 |

Even after the ~$5.1k DEX cost, the direct mark-to-market payoff is ~**38×**. Realized value is lower because 632k KITE cannot be sold into a $14.7k DEX; the attacker would need OTC exits or would hold governance control to extract protocol value. That is the difference between **mark-to-market** and **realizable** value.

### 4.2 With the current 73,936 KITE defence

The binding constraint is no longer quorum; it is **againstVotes**. To pass, the attacker needs `forVotes > 73,936.06` (and ≥9,739.67 quorum), i.e. **≥73,936.06 KITE** — 7.59% of supply. The two DEX pools contain only **23,737.01 KITE**, so the required votes **cannot be acquired on-chain at any price**. The attacker would need OTC purchases from large holders or a delegation shift. The defence bloc is **3.11× the entire DEX KITE float**.

### 4.3 If hardening executes

| Parameter | Now | After hardening |
|---|---|---|
| Quorum | 1% = 9,739.67 KITE ($3,009.57) | **5% = 48,698.35 KITE ($15,047.87)** |
| Proposal threshold | 5,000 KITE ($1,545.01) | **20,000 KITE ($6,180.03)** |
| Voting period | 129,600s (36h) | **432,000s (5 days)** |
| Defence bloc | 73,936.06 | 73,936.06 |
| Defence margin above quorum | 64,196.39 KITE (6.59×, $19,837 spot) | 25,237.71 KITE (1.52×, $7,798 spot) |
| Quorum vs DEX float | 0.41× (buyable) | **2.05× (not buyable)** |

After hardening, the **on-chain-buyable capture path is closed**: 48,698 KITE > 23,737 KITE of DEX float. The attacker would still need >73,936 KITE OTC, or the defence to shrink below 48,698. This is why executing the hardening is the single highest-value defensive action.

### 4.4 Gas war

OP gas is effectively free for proposal spam: 858 proposals + votes cost the attacker ~$0.03 in L2 fees (Blockscout `fee` field), while the defender's 1,300 txs cost ~$58.34. The attacker can spam proposals faster than a human defender can respond; only a small set of delegates (`0xE02e…`, `0x35d0…`) matched the cadence. This asymmetry is a live griefing/attention-exhaustion vector even without capture.

---

## 5. Why the attack failed — and why it can restart

**Failed because:**
1. The attacker only ever held **9,768.50 KITE** (1.003% of supply) — enough for quorum, not enough for a majority. Its two real attempts got 9,768.50 FOR vs 65,104.31 and 65,462.36 AGAINST.
2. Four delegates auto-voted AGAINST on every proposal, including 851 identical delegate payloads over 2 days. The attacker could not find a turnout gap.
3. The attacker's 9,768.50 KITE was acquired via two EOA transfers on Oct 8 (no DEX pool involved) and was fully liquidated on Oct 14, so the campaign had a finite budget.
4. The defender queued the hardening proposal on Oct 16, which — if executed — raises the threshold to 20,000 KITE and quorum above the DEX float.

**Can restart because:**
1. **Hardening is still unexecuted.** `quorumNumerator()` is still 1; one EOA can execute it, but nobody has for ~20h.
2. The Treasury still holds 328,143.98 KITE and `delegates(Safe)=0`.
3. The StakingManager's 304,489 KITE is one Timelock call away from `emergencyWithdraw`, and the Timelock can mint KITE/HAI.
4. The defence bloc is delegated, not owned; a single 20k–50k holder moving delegation changes the margin. The top non-defence holders include 51,118 KITE (`0xE207…`, delegated to `0x297b…`), 20,403 KITE (`0x0a453…`, delegated to `0xCAFd`), 12,722 KITE (`0xd96f…`), 9,753 KITE (`0xf23f…`), 8,666 KITE (`0xeCeA…`), 8,147 KITE (`0xcFdB…`).
5. An OTC buyer can acquire 74k KITE without touching the DEX; the on-chain float constraint only blocks the *permissionless* path.

---

## 6. Fork verification (no mainnet transactions)

Foundry 1.8.5's `op-revm` panics on OP Mainnet post-Isthmus blocks (`Missing operator fee scalar for isthmus L1 Block`) before test code runs, so the Foundry test is kept in `poc/` but disabled (`poc/foundry.toml.disabled`). The equivalent proof uses **`eth_call` with a code override**:

- `ci/harness_code.txt` — runtime bytecode of a harness placed at the Timelock address (so `address(this) == Timelock` and the Safe sees `msg.sender == owner`).
- `ci/payload.txt` — the exact 1,477-byte `Safe.execTransaction` calldata from attacker proposal `377946732172…`.
- `ci/verify_state.py` — runs both simulations and 13 assertions.

**Results at block 158,341,534 locally and block 158,341,606 in CI (`ci-out/verify.json`, `ci-out/ci_verify.json`, 13/13 PASS):**

| Check | Result |
|---|---|
| Hardening `execute()` from a plain EOA | success; `quorumNumerator` 1→**5**, threshold 5,000→**20,000e18**, votingPeriod 129,600→**432,000** |
| Safe payload executed with `from=Timelock` | success; `KITE.delegates(Safe)` → **0x1472…**; Safe KITE 328,143.98→**327,643.98**; RewardDistributor +500 KITE; `0x468c…` +100 OP; allowance to StakingManager 50,000 KITE; Safe nonce 79→80 |
| Direct `Timelock.executeBatch` from an EOA | reverts (AccessControl) |
| Timelock op ready / done | ready=1, done=0 |
| Treasury KITE intact / not delegated | 328,143.98 / 0x0 |
| KITE, HAI, StakingManager Timelock authority | all true |
| Quorum still 1% / threshold 5,000 | true |
| Defence bloc ≥70,000 KITE | true (73,936.06) |
| New governance activity since 2026-10-16 | 0 ProposalCreated, 0 VoteCast, 0 ProposalExecuted, 0 CallExecuted |

**CI URL:** https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39081525897 — **13/13 PASS at block 158,341,606 (2026-10-18T00:06:29Z)**, artifact `result-hai`.

The `poc/HaiGovernance.t.sol` file contains the same two tests in Foundry form (fork block 158,341,121) for reproducibility on a fixed toolchain.

---

## 7. Monitors

1. **Hardening execution** — `Timelock.CallExecuted(id=0x52aa3307…)` or `Governor.ProposalExecuted(0xe58085b0…)`; then check `quorumNumerator()==5`.
2. **ProposalCreated spam** — count/rate per hour from `0xDC6A…` or any new proposer; the 858-proposal campaign is the template.
3. **Timelock `CallScheduled` / `CallExecuted`** — any new operation, especially targets = Treasury Safe or StakingManager.
4. **KITE OTC / transfers** — large `Transfer` to a new EOA, then `delegate(...)`; watch the top-20 holders and the two DEX pools.
5. **Delegation changes** — `DelegateChanged` on KITE for the four defender delegates; a 25k+ shift is enough to erase the post-hardening margin.
6. **Treasury Safe nonce / `delegates(Safe)`** — a nonce increment with no known proposal, or a non-zero delegatee, is the capture itself.

---

## 8. Verdict, residual risk, caveats

**Classification:** **E-U (governance capture, own capital), conditional.**
- **Live permissionless E-U: $0.** The specific attacker exited; the current defence bloc (73,936 KITE) exceeds the entire DEX KITE float (23,737 KITE), so the required votes are not permissionlessly acquirable.
- **Conditional E-U: $195,568.43.** The same capture is reachable by an OTC buyer of 73,936.06 KITE (≈$22,846 spot) or if the defence bloc drops below the attacker's stake.
- **Latent (defence-lapse) E-U: $195,568.43 direct + $916,806 TVL exposure + unbounded KITE/HAI mint authority.** If the defence lapses, ~$5,099 buys the quorum and a 3-day cycle captures the Treasury and StakingManager.
- **Post-hardening latent E-U:** quorum 48,698.35 KITE is above the DEX float, so the permissionless path closes; OTC/social capture at >73,936 KITE remains.

**Confidence:** high on the deployed mechanics, state, roles and vote counts (all read at an explicit block; payload executed in a state-override simulation). Medium on the economic conclusion because (a) KITE mark-to-market values are not realizable into $14.7k of DEX liquidity, (b) an OTC whale could still supply 74k KITE, and (c) the defence bloc is delegated and can change.

**Caveats / blockers:**
- The attacker's OTC cost basis is unknown; the 9,768.5 KITE came from two EOAs, not a DEX, so we cannot compute its P&L precisely.
- The Blockscout `fee` field understates the L1 data fee; the gas comparison is directional, not exact.
- Foundry fork tests are blocked by the upstream `op-revm` Isthmus panic; the state-override proof is equivalent for these two calls but does not persist state.
- The $916,806 TVL is DefiLlama's protocol TVL, not a proven drain path; the direct, proven drainable assets are the $195,568 Treasury + StakingManager KITE.
- No mainnet transaction was sent. The hardening remains unexecuted because we do not transact.

---

## 9. Methodology, sources, files

**Method:** enumerated all 5,901 Governor logs and 4,156 Governor txs from Blockscout v2 (2024-02-12 → 2026-10-16), decoded 1,013 `ProposalCreated`, 4,560 `VoteCast`, 143 `ProposalQueued`, 142 `ProposalExecuted`; read live state at block 158,341,534 via keyless `https://mainnet.optimism.io`; scanned `eth_getLogs` from 158,262,010 → 158,341,534 for new activity; priced with DefiLlama and DEX Screener; executed both critical calls via `eth_call` state override.

**Key sources:** verified `HaiGovernor.sol`, `ProtocolToken.sol`, `TimelockController.sol`, `StakingManager.sol`; Safe `getOwners/getThreshold/nonce`; KITE/HAI `authorizedAccounts`; DefiLlama `lets-get-hai`; DEX Screener KITE/HAI pairs.

**Files:**
```
hai/
├── README.md                      # this report
├── summary.json                   # machine-readable verdict
├── analysis/
│   ├── gov_logs_all.json          # 5,901 Governor logs (24 MB)
│   ├── gov_txs_all.json           # 4,156 Governor txs (24 MB)
│   ├── gov_src.json / kite_src.json / tl_src.json / staking_src.json
│   ├── latest_state.json          # live reads at 158,341,121
│   ├── key_numbers.json           # derived economics
│   ├── analyze_local.py / proposal_tally.py / rpc_state.py
│   ├── rpc_recent_logs.py / recent_logs.json
│   └── attacker_samples.json
├── ci/
│   ├── run.sh                     # CI entrypoint
│   ├── verify_state.py            # 13 live checks + 2 state-override simulations
│   ├── payload.txt                # exact attacker Safe calldata
│   └── harness_code.txt           # state-override harness bytecode
├── ci-out/verify.json             # local 13/13 result
├── ci-out/ci_verify.json          # CI 13/13 result (block 158,341,606)
├── ci-log.txt / ci-artifacts/     # CI log/artifacts (after run)
└── poc/
    ├── HaiGovernance.t.sol        # Foundry form (disabled: op-revm bug)
    └── foundry.toml.disabled
```

**No secrets or keyed RPC URLs are stored in this folder.** All scripts use `OP_RPC_URL` from the environment or the keyless public endpoint.
