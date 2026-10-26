# ZH4-PASS7 TIER-3 · #6 — Unlock Protocol governance capture (Base)

**Date:** 2026-10-25 · **Chain:** Base (8453) · **Mode:** READ-ONLY — no transaction signed/sent on any live network; `eth_call`/state reads + **local anvil fork only** (Foundry tests run on GitHub Actions).
**Status:** mechanism **fork-proven**; acquisition cost **measured on-fork**; **capture shown to be deterred by live governance turnout** — live state re-read at block 53,083,993 / 53,084,185.

---

## 1. TL;DR

| Target | Live value (nominal) | Realizable by an unprivileged attacker | Why | Latent risk |
|---|---|---|---|---|
| **UnlockProtocolGovernor** `0x65bA0624…0aD9` → **UPTimelock** `0xB34567C4…ed1b` (Base) | **$38,493** (27.17M UP + 6.431 ETH + 3,997 USDC + 0.497 WETH) | **≈ $0** | The cheap-quorum mechanism is real (quorum = **0.3 % = 3,000,000 UP ≈ $2,120**, no `guardian()`, fork-proven end-to-end) **but the proposal must win a 6-day vote** — and Unlock's governance is **active**: recent turnout is **6.58M–13.85M UP (2.2×–4.6× quorum)**, and a **single delegate (`0x38b826a4…`) already holds 3,420,169 UP — more than the quorum and more than the attacker's stake — and votes `Against`** on proposals it dislikes. Out-bidding the community needs >13.85M UP (~$44.5k with a ~$35k non-recoverable price impact) > the ~$29k prize ⇒ net-negative | if all active delegates abstain for the 6-day window, the capture nets ≈ $29k; if UP liquidity deepens, >13.9M becomes cheap |

**Headline:** the Unlock timelock's 0.3 %-quorum / no-guardian / timelock-owned-ProxyAdmin configuration is a **textbook instant-governance target**, and the mechanism is fork-proven — but the *economic* capture is **deterred by live governance participation**. **E-U ≈ $0 today** (MEDIUM confidence). The **E-U-conditional** upside if the vote went unopposed is **≈ $29k net** (the number pass7 pitched), which the turnout data makes unlikely.

---

## 2. Total live extractable now

- **E-U (unconditional): $0.00**
- **E-U-conditional** (only if the drain proposal passes unopposed — LOW probability): **≈ $29,085 net** (nominal prize $38,493 − illiquid-UP premium − ~$118 acquisition cost). Range $20,000–$29,200.
- **H-O (holder self-service): $0** — no holder-only exit reaches the timelock funds.
- **P (privileged / governance-only): $38,493** — the timelock is governance-controlled, **and** both ProxyAdmins (`0xf7521e34…` governor, `0x5c17f89e…` timelock) are `owner() == the timelock`, so a passed proposal also gains **full upgrade authority** over the governor, the timelock and the UP token.
- **S (stuck): $0.**

---

## 3. The mechanism, in exact terms

`UPGovernor` (impl `0x6ac91d932b575e16c3d724eb43fbc9ce7bf5f7f2`, behind `TransparentUpgradeableProxy 0x65bA0624…0aD9`) is a **stock OpenZeppelin v5 upgradeable governor** (`GovernorUpgradeable` + `GovernorSettingsUpgradeable` + `GovernorCountingSimpleUpgradeable` + `GovernorVotesUpgradeable` + `GovernorVotesQuorumFractionUpgradeable` + `GovernorTimelockControlUpgradeable`). Live parameters (block 53,083,993):

| Param | Value | Source call |
|---|---|---|
| `votingDelay` | 345,600 s (**4 days**) | `votingDelay()` |
| `votingPeriod` | 518,400 s (**6 days**) | `votingPeriod()` |
| `proposalThreshold` | 50,000e18 UP | `proposalThreshold()` |
| `quorumNumerator`/`Denominator` | **3 / 1000 → 0.30 %** | `quorumNumerator()`, `quorumDenominator()` |
| `quorum(now)` | **3,000,000e18 UP** | `quorum(timestamp-1)` |
| `COUNTING_MODE` | `support=bravo&quorum=for,abstain` | `COUNTING_MODE()` |
| `guardian()` | **reverts — no guardian** | `guardian()` |
| `timelock()` | `0xB34567C4…ed1b` | `timelock()` |
| `token()` | `0xaC27fa80…6187` (UP) | `token()` |

Timelock (`UPTimelock` impl `0x4473b159…`, proxy `0xB34567C4…ed1b`): `getMinDelay() = 172,800 s` (2 days); `PROPOSER_ROLE(governor)=true`; `CANCELLER_ROLE(governor)=false`; `TIMELOCK_ADMIN_ROLE(self)=true`; `EXECUTOR_ROLE(address(0))=true` (open execution).

**The capture path** (all permissionless):

```
1. buy ≥3,000,000 UP from the UP/WETH UniV3 pool 0x9EF81F4E… and delegate() to yourself
2. UPGovernor.propose([UPToken, USDC, WETH, attacker],
                      [0,0,0,6.431e18],
                      [transfer(attacker,upBal), transfer(attacker,usdcBal),
                       transfer(attacker,wethBal), ""],
                      "…")
3. wait votingDelay (4 d)  → castVote(id, 1 /*For*/)        # weight is snapshotted, so sell the UP back now
4. wait votingPeriod (6 d) → queue(...)                      # timelock.scheduleBatch, salt = proposalId
5. wait minDelay (2 d)     → execute(...)                    # timelock.executeBatch; sends tokens AND ETH
```

Because `_castVote` reads `token.getPastVotes(account, proposalSnapshot)` (`snapshot = clock() + votingDelay`), the attacker must **hold the quorum stake for the 4-day delay**; after the snapshot the tokens are free to sell. `GovernorVotesQuorumFraction.quorum()` reads `getPastTotalSupply(snapshot)`, so **no flash-loan path exists** (this is *not* the X100 same-tx primitive — it is the slower "cheap quorum + no guardian + no on-chain cancel" variant).

**Why there is no privileged counter:** `guardian()` reverts (no veto). `CANCELLER_ROLE` is held by **nobody we could find** (governor=false, timelock-self=false, both ProxyAdmins=false) and `TIMELOCK_ADMIN_ROLE` is held only by the timelock itself ⇒ the only on-chain cancel is *another* governance proposal (itself 4+6+2 days). Both ProxyAdmins are `owner() == the timelock`, so the Unlock team **cannot** unilaterally upgrade/cancel. (Verified in source: `UPTimelock.cancel(bytes32)` is `onlyRole(CANCELLER_ROLE)`, and `GovernorTimelockControl._cancel` calls it.)

---

## 4. Live state (every number, with the call that produced it)

Block **53,083,993** (Base), timestamp 1792957333. Prices 2026-10-25 (DefiLlama `coins.llama.fi`): **ETH $2,353.68 · UP $0.0006694**.

| Item | Value | Call |
|---|---|---|
| UP `totalSupply` | 1,000,000,000 UP | `UP.totalSupply()` |
| UP `owner()` | `0xB34567C4…ed1b` (**the timelock** — a passed proposal also controls the token) | `UP.owner()` |
| Timelock **UP** | 27,171,281.4096 UP ≈ **$18,188** | `UP.balanceOf(timelock)` |
| Timelock **ETH** | 6.431220781 ETH ≈ **$15,137** | `eth_getBalance(timelock)` |
| Timelock **USDC** | 3,997.402409 USDC ≈ **$3,997** | `USDC.balanceOf(timelock)` |
| Timelock **WETH** | 0.497088301 WETH ≈ **$1,170** | `WETH.balanceOf(timelock)` |
| **Total nominal** | **≈ $38,493** | |
| UP/WETH 0.3 % pool `0x9EF81F4E…5242` | 18,306,217.37 UP + 6.155704308 WETH | `balanceOf(pool)` |
| UP/WETH pool `0xdd295951…a897` | 1,202,181.24 UP + 0.343444274 WETH | `balanceOf(pool)` |
| Timelock UP votes | **0** (undelegated) | `UP.getVotes(timelock)` |

### 4.1 Governance turnout — the decisive counter-evidence

`eth_getLogs` on the governor for the last ~600k blocks (~14 days): **3 proposals**, decoded `VoteCast` weights (`analysis/governance-turnout.json`):

| Proposal | Voters | FOR | AGAINST | vs 3,000,000 quorum |
|---|---|---|---|---|
| `112785277236…` | 6 | **13,851,479** | 0 | 4.6× quorum |
| `11790216226306…` | 3 | 0 | **6,578,303** | defeated |
| `49741031545790…` | 4 | **10,678,655** | 0 | 3.6× quorum |

**Live delegate voting power right now:** `0x38b826a4426a0d4d9b4377ac57c9af0308281c5d` = **3,420,168.69 UP** (EOA) — **more than the 3,000,000 quorum and more than the attacker's 3M**; `0x9ded35ae…` = 2,441,262; `0xca763232…` = 2,383,794.

**Consequence:** the attacker's 3M UP stake (bought from the *pool*, which does **not** reduce these delegates' holdings) is outvoted by a **single** attentive delegate that has already voted `Against` once. To be safe the attacker must hold **>13.85M UP**; buying 13.85M from the 18.31M-UP pool costs **~18.9 WETH ≈ $44.5k** with a **~$35k non-recoverable price impact** (the stake must survive the 4-day snapshot, so it cannot be flash-loaned or round-tripped) — **net-negative versus the ~$29k realizable prize.**

---

## 5. What an attacker can / cannot do — costs

**Can (fork-proven, CI runs [40227629548](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40227629548) / [40226914520](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40226914520)):**
- buy exactly **3,000,000 UP for 0.90051 WETH = $2,119.55** through the live Uniswap V3 `SwapRouter02` (`exactOutputSingle`, measured on-fork);
- propose + vote + queue + execute and receive the timelock's **UP + ETH + USDC + WETH** in full — *given quorum-level votes*.

**Cost accounting of the conditional path (net if the vote passes):**

| Line | USD |
|---|---|
| Prize, fully-liquid legs (ETH + USDC + WETH) | **+$20,304.8** |
| Prize, UP leg (dump 27.17M UP into the two live pools: `Y·Q/(X+Q)` ≈ 3.78 WETH) | **+$8,900** (range $7.5k–$9.5k) |
| Realizable prize total | **≈ $29,205** |
| Buy 3M UP (measured) − sell back after the snapshot (≈ spot) | **≈ −$118** |
| **Net E-U-conditional** | **≈ $29,085** |

**Cost accounting of actually winning the vote (the real constraint):**
- minimum opposition to beat ≈ **13.85M UP** (observed max turnout); acquiring it from the pool costs **≈ $44.5k**, of which **≈ $35k is non-recoverable** price impact (4-day hold) ⇒ **net ≈ −$6k to −$15k**.

**Cannot:** flash-loan the quorum (past-supply snapshot); cancel on-chain (`CANCELLER_ROLE` unheld); win against the active delegates with only the 3M quorum stake.

---

## 6. PoC / fork verification

`poc/` — Foundry project (vendored `lib/forge-std`), fork of Base. **3/3 tests PASS** in CI.

| Test | What it proves |
|---|---|
| `test_01_liveState()` | every parameter + timelock balance above, asserted (`quorum==3e24`, `votingDelay==345600`, `minDelay==172800`, …) |
| `test_02_captureMechanism()` | full path with quorum-level votes: `propose` → `castVote(For)` → `queue` → `execute`; asserts the timelock ends at **0 UP / 0 USDC / 0 WETH / 0 ETH** and the attacker received them (`forVotes = 3,600,000e18`) |
| `test_03_acquisitionCost()` | live Uniswap V3 swap: **3,000,000 UP for 0.900505509506934864 WETH** (`dex_swap_ok=1`) |

**CI:** https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40227629548 (**success**; `Suite result: ok. 3 passed; 0 failed`) — also [40226914520](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40226914520). Artifact `result-unlock-gov` (live-state dump) in `ci-artifacts/`.

---

## 7. Verdict & residual / latent risk

**Verdict: E-U ≈ $0 (MEDIUM confidence).** Unlock's governor has the *shape* of an instant-governance target — **0.3 % quorum (~$2,120)**, **no guardian**, **no on-chain cancel**, **timelock-owned ProxyAdmins**, and the protocol's own 27.2M UP **undelegated**. The mechanism is fork-proven end-to-end. **But the vote is the binding constraint and it is live:** three proposals in the last 14 days drew **6.58M–13.85M UP** of turnout, and a **single delegate already holds 3.42M UP ( > quorum > the attacker's 3M)** and has voted `Against`. The cheap path is defeated; the out-bid path is **net-negative** (≈$44.5k to acquire >13.85M UP vs ≈$29k realizable). This **corrects** pass7's "cleanest profitable capture (MED, ~$15–20k net)" — the mechanism is real, but the economics are deterred.

**Latent risk (what would re-arm it):**
- **Governance apathy** for the specific 10-day proposal window (all active delegates abstain) → the conditional ≈ $29k becomes live.
- **Deeper UP liquidity** (currently ~$28k) → acquiring >13.9M UP becomes cheap → the capture turns net-positive.
- **UP price appreciation / any timelock refill** → raises the prize; the quorum stake scales too, but more slowly (quorum is 0.3 % of supply, the prize is a fixed holding).
- **An executed precedent** would reveal whether the 6-day vote is ever contested.

**Blockers:** (i) active delegates with >quorum power; (ii) the 4-day hold makes the stake non-flash-loanable and the price impact non-recoverable; (iii) the UP leg is illiquid (27.17M UP only realises ~$8.9k).

---

## 8. Methodology & sources; caveats

- **On-chain reads** at Base blocks 53,083,993 / 53,084,185 (`eth_call`, `eth_getBalance`, `eth_getStorageAt`) — `analysis/live-state.json`. Verified source via Etherscan V2 `getsourcecode` (chainid 8453) for `UPGovernor`, `UPTimelock`, `UPToken` (impl `0xf52ce8bc…`) and the two `ProxyAdmin`s.
- **Governance turnout** via `eth_getLogs` on the governor (ProposalCreated `0x7d84a626…`, VoteCast `0xb8e13888…`), decoded `weight` — `analysis/governance-turnout.json`.
- **Fork PoC** on Base via `BASE_RPC_URL` (CI secret empty → public `https://base-rpc.publicnode.com` fallback); the decisive run was on GitHub Actions (public repo `artsbykriss/ca-zombie-ci`, branch `unlock-gov`).
- **Prices:** DefiLlama `coins.llama.fi/prices/current` (ETH $2,353.68; UP $0.0006694); pool depths from on-chain `balanceOf(pool)` + GeckoTerminal.
- **Corpus cross-check:** pass7 `gov-params.md` #2 / `gov-capture.md` pitched Unlock as the "cleanest profitable capture (MED, net ≈ $15–20k, not fork-simulated)". This folder **confirms the mechanism** (fork-proven), **measures** the acquisition cost ($2,120), **resolves** the open `CANCELLER_ROLE`/ProxyAdmin question (no off-chain cancel), and **corrects the economics**: the live governance turnout (6.58M–13.85M) deters the capture ⇒ E-U ≈ $0, conditional upside ≈ $29k.
- **Caveats:** (i) governance behaviour is not code — confidence MEDIUM, not HIGH; (ii) the UP-leg realisation is a single-shot AMM-dump estimate; (iii) the 12-day window means pool/turnout economics must be re-read before acting. **Point-in-time 2026-10-25.**

## 9. Files

```
unlock-gov/
├── README.md                       # this file
├── summary.json                    # machine-readable
├── analysis/
│   ├── live-state.json             # every on-chain value + the call that produced it
│   ├── governance-turnout.json     # decoded ProposalCreated/VoteCast turnout (decisive)
│   ├── up_recent_votecast_raw.json # raw eth_getLogs
│   ├── gov_impl.files/…            # verified UPGovernor source
│   ├── timelock_impl.files/…       # verified UPTimelock source
│   ├── UP_impl.sol                 # verified UPToken source
│   └── gov.json / timelock.json    # raw Etherscan V2 responses
├── poc/                            # Foundry project (fork only)
│   ├── foundry.toml
│   ├── lib/forge-std/              # vendored
│   └── test/UnlockCapture.t.sol    # 3 tests, 3 PASS
├── ci/run.sh                       # light live-state dump -> ci-out/
├── ci-out/live-state.json
├── ci-log.txt                      # CI run 40227629548
└── ci-artifacts/result-unlock-gov/…
```
