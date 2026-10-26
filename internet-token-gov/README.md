# P7-LOW-8 — Internet Token governance capture (ProtocolGovernor + GovTimelockController)

**Date:** 2026-10-25/26 · **Chain:** Base (8453) · **Status:** read-only; PoC fork-verified only; **no mainnet transactions**
**Targets:** `ProtocolGovernor` `0xc5C3a1882Eff9539527D88E2453cAB10d9bc1581` · `GovTimelockController` `0xE05dD5B785f578337B2B8F695Fbc521669c69403`
**Fork-verification:** GitHub Actions run [`40232520195`](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40232520195) — **3/3 tests PASS**
**On-chain snapshot:** Base block **53082738** (ts 1792954823, 2026-10-25), keyless RPC, `eth_call` only.

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why open | Latent risk |
|---|---|---|---|
| `ProtocolGovernor` 3 % quorum over a funded timelock, **no on-chain guardian** | **$13,180 net** (gross $18,379 − acquisition $5,199) — *fork-verified arithmetic; conditional on no admin cancellation and no further opposing delegation* | 3.0 % quorum (25.26 M INT) is **buyable for $4.07 k** from the live pool; **but the bare quorum LOSES** — a live delegate (`0x0000de00…`) holds **28,239,311 INT (> quorum)** and votes `Against`, so the attacker must buy **30.24 M INT = $5,199** (fork TEST D); 1-day vote delay, 3-day vote, 1-day timelock; no `guardian()`; `EXECUTOR_ROLE(0)` is false but the governor can execute | Timelock carries the token's `CONFIG_ADMIN`+`ROLE_ADMIN` ⇒ a passing proposal can re-grant `TOKEN_MINTER` and re-arm the Sep-2026 mint bug |

**Total live extractable now (E-U): ≈ $13,180** · confidence **LOW** (mechanism & arithmetic high-confidence; outcome gated by off-chain admin/holder behaviour).

**Corpus correction:** pass7 `gov-capture.md` estimated Internet Token at “**~$12–80 k**”. Fork-measured value: **net $13,180** (gross $18,379), acquisition $5,198.74 (the stake needed to out-vote the live 28.24 M delegate). The “$339 k nominal treasury” is **95 %+ unsellable INT**; only the **$11.6 k liquid legs + $6.8 k pool WETH** are realisable.

---

## 2. Total live extractable now

```
E-U  = $13,180.48   (gross realisable $18,379.22  −  winning-stake acquisition $5,198.74)
H-O  = $0
P    = $339 k nominal treasury (governance-only, 292.5 M INT illiquid)  [not additive with E-U]
S    = $0
```
Confidence **LOW**: the extraction path is fork-proven and the costs/prices are on-chain measured, but success requires (a) the single `PROPOSAL_ADMIN` EOA not to call `cancelWithReason()` during the 4-day window, (b) the `ROLE_ADMIN` EOA not to `disableTransfers()`/blacklist, and (c) the live 28.24 M-vote delegate (`0x0000de00…`) not to attract further delegation. All are unobservable off-chain.

> **Parent-agent verification (independent).** The bare 25.26 M quorum is **not** enough: `eth_getLogs` over the last ~600 k Base blocks shows **2 proposals**, and the delegate `0x0000de0028b400E5EA4F988859852C003600eADE` (EOA) voted **`Against` on both** — with **28,239,311.38 INT** of live voting power (**1.118× the quorum**). Since OZ requires `forVotes > againstVotes`, the attacker must hold **> 28.24 M INT**. Fork **TEST D** measures the winning stake (30,239,311.38 INT) at **2.208770759 WETH = $5,198.74**. Corrected net **$13,180.48**. Evidence: `analysis/governance-turnout.json`; CI run [`40248236760`](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40248236760) (4/4 PASS).

---

## 3. Mechanism, in exact terms

Deployed source (`analysis/gov.sol`, `analysis/timelock.sol`, full OZ v4.9 sources in `analysis/src_gov/`):

- `ProtocolGovernor` = OZ v4.9 `Governor` + `GovernorCompatibilityBravo` + `GovernorSettings` + `GovernorVotes` + `GovernorVotesQuorumFraction` + `GovernorTimelockControl` (+ a project `RoleModule`).
- **`quorum(timepoint) = getPastTotalSupply(timepoint) × 3 / 100`** and `COUNTING_MODE = "support=bravo&quorum=bravo"` ⇒ quorum is measured **against For votes only**.
- `clock()`/`CLOCK_MODE()` = **timestamp** (not block numbers) ⇒ votes use **ERC20Votes checkpoints keyed by timestamp**; the proposal snapshot is `clock() + votingDelay` = **+1 day**.
- `guardian()` **reverts** — there is **no on-chain veto** (unlike ENS/Compound).
- `GovernorTimelockControl.queue()` schedules the proposal on the timelock (`PROPOSER_ROLE(governor)=true`); after `getMinDelay()=1 day`, anyone can `execute()`; the governor holds `EXECUTOR_ROLE` and the timelock executes the batched calls **as itself**.
- The timelock is the **token's `ROLE_ADMIN` + `CONFIG_ADMIN` + `INFO_ADMIN` + `POOL_STATE_ADMIN`** in `RoleStore 0xd5D1A16084a116f8a6c2C706C110dBAD2E99Be83` ⇒ a passing proposal can call `RoleStore.grantRole(attacker, TOKEN_MINTER)` and then `RewardToken.mint()`. `TOKEN_MINTER` is **currently empty** (the Sep-21-2026 exploit was patched by revoking `LiquidityUnifier`'s minter role), but the *privilege to re-grant it* is one proposal away.

Attack path (no privileges, only capital):

1. Buy `quorum` = **25,258,494.79 INT** on the open market (fork-measured: **1.7287 WETH ≈ $4,069**).
2. `INT.delegate(attacker)`; `propose([INT,USDC,WETH],[0,0,0],[transfer(attacker,balanceOf(timelock))×3], desc)`.
3. Wait `votingDelay` (1 d) → `castVote(pid,1)` (For). Wait `votingPeriod` (3 d) → `Succeeded`.
4. `queue(...)` → wait `getMinDelay()` (1 d) → `execute(...)`.
5. Timelock transfers **292,506,402.85 INT + 6,213.52 USDC + 2.2756 WETH** to the attacker. Dump INT into the pool; keep USDC/WETH.

The attacker must hold INT across the snapshot (1 day) — so this is **not flash-loanable**; it is a 5-day capital commitment.

---

## 4. Live-state assessment (block 53082738)

| Call | Value |
|---|---|
| `governor.name()` | `ProtocolGovernor` |
| `governor.votingDelay()` / `votingPeriod()` | `86400` / `259200` |
| `governor.proposalThreshold()` | `1e24` (1,000,000 INT) |
| `governor.quorum(now)` | `25258494790736072374991870` = **25,258,494.79 INT** |
| `governor.quorumNumerator()/Denominator()` | `3 / 100` |
| `governor.COUNTING_MODE()` | `support=bravo&quorum=bravo` |
| `governor.clock()` / `CLOCK_MODE()` | `1792954823` / `mode=timestamp` |
| `governor.guardian()` | **reverts** (no guardian) |
| `governor.token()` / `timelock()` | `0x968D…eC19` / `0xE05d…9403` |
| `timelock.getMinDelay()` | `86400` (1 d) |
| `timelock.hasRole(PROPOSER_ROLE, governor)` | `true` |
| `timelock.hasRole(CANCELLER_ROLE, governor)` | `true` |
| `timelock.hasRole(EXECUTOR_ROLE, governor)` / `(0x0)` | `true` / `false` |
| `timelock.hasRole(TIMELOCK_ADMIN_ROLE, timelock)` / `(governor)` | `true` / `false` |
| `INT.totalSupply()` | `841,949,826.357869079166395686` |
| `timelock` balances | **292,506,402.8498 INT**, **6,213.520827 USDC**, **2.275605462835971471 WETH**, 0 ETH |

**RoleStore membership (all read at the same block):**

| Role | Members |
|---|---|
| `ROLE_ADMIN` | timelock, `0x0C02d2D3…fBA78` (small contract), `0x58B680C5…A7F5c` (**EOA, nonce 490**) |
| `CONFIG_ADMIN` | timelock, `0xbc1d8C79…e96f`, `0x0C02d2D3…`, `0x342585ED…2BCF`, `0x58B680C5…` |
| `PROPOSAL_ADMIN` | **`0x36f40D30…78BC` (EOA, nonce 3)** — can `cancelWithReason()` any Pending/Active proposal |
| `INFO_ADMIN` | `0x36f40D30…`, timelock |
| `TOKEN_MINTER` | **(empty)** |
| `TOKEN_BURNER` | `0x0B401740…`, `0x8df3ea2c…`, `0x58B680C5…` |
| `CALLBACK_ADMIN` | `0xEeeFe02e…`, `0x8df3ea2c…`, `0xDA7d3635…` |

**Token mechanics that matter:** `areTransfersEnabled = true`; two transfer callbacks are registered — `AllowListCallback 0xfd5BBCA6…` (disallowed-accounts list currently **empty**) and `TradeFeeCallback 0x71C51C4a…`. `TradeFeeCallback._beforeTokenTransfer` reverts **only** for transfers involving its own immutable `pool`; ordinary DEX transfers are unaffected (confirmed by the fork dump).

**Liquidity — measured with `balanceOf`, not indexers.** GeckoTerminal's `reserve_in_usd` for this token is **demonstrably stale/wrong** (it reports $51,561 for a pool that on-chain holds 980 INT + $0.136, and $6,662 for a pool holding 841 INT + $0.000115):

| Pool | DEX | INT | Quote | tradeable? |
|---|---|---|---|---|
| `0xDEc6Eadb…6969d` | UniV3-fork (factory `0x0Fd83557…`) fee 1 % | 102,008,837.5 | **2.8932 WETH** | **YES** (L=2.363e22) |
| `0xE2DdA091…04610` | canonical UniV3 fee 1 % | 109,911 | 1.0339 WETH | **NO** — `liquidity()=0` (out of range) |
| `0x2528cb39…d58f` | UniV3-fork | 980 | $0.136 USDC | no (dead) |
| `0x878f8845…6e47` | Maverick V2 | 841 | $0.000115 USDC | no (dead) |
| `0xf38a84b4…0121` (v4, hooked) | Uniswap v4 | — | — | unverified; `StateView.getLiquidity=0` |

⇒ **Only `0xDEc6Eadb…` is verifiably funded and tradeable.** Its INT side (102.0 M) is deep enough to buy the 25.26 M quorum; its WETH side (2.893 WETH) is the entire realisable dump.

---

## 5. What an attacker can / cannot do (exact)

**Can:** buy quorum, delegate, propose, vote, queue, execute, receive the three tokens, dump INT.
**Cannot:** flash-loan the vote (timestamp checkpoints + 1-day snapshot ⇒ must hold across the snapshot); mint INT (no `TOKEN_MINTER` member); exceed the pools' quote-side reserves.

Costs: acquisition 1.7287 WETH ($4,068.76, fork-measured); Base gas ≈ $1–3; no flash-loan fee (not used). Capital locked ~5 days.

**Blockers / caveats (honest):**
1. **`PROPOSAL_ADMIN` EOA `0x36f40D30…`** can cancel the proposal during the 4-day Pending/Active window. Last on-chain activity ≈ Sep 2026 (nonce 3). No on-chain guardian, but this is a real off-chain veto.
2. **`ROLE_ADMIN`/`CONFIG_ADMIN` EOA `0x58B680C5…`** (nonce 490, last activity ≈ Oct 2026) can `disableTransfers()` or blacklist the attacker via `AllowListCallback` — either bricks the path.
3. **Holder opposition (quantified by the parent agent):** the live delegate `0x0000de0028b400E5EA4F988859852C003600eADE` (EOA) already holds **28,239,311.38 INT** of voting power — **more than the 25.26 M quorum** — and voted `Against` on both of the last two proposals. Because OZ requires `forVotes > againstVotes`, the bare quorum **loses**; the attacker must buy **> 28.24 M INT** (TEST D: 30.24 M for $5,198.74). GT reports 9,590 holders, top-10 = 76.5 % of supply (the timelock is 34.7 %), so further opposition is possible; buying more INT raises the cost steeply (the child's datapoint: 50 M INT ≈ 4.93 WETH, which halves the net). Evidence: `analysis/governance-turnout.json`.
4. Other INT pools (v4 hooked pool, out-of-range `0xE2DdA091`) may hold extra quote-side liquidity reachable only with out-of-range-liquidity manipulation techniques; **not counted** (unverified).

---

## 6. PoC / fork-verification

`poc/` (Foundry 0.8.24, vendored `lib/forge-std`) — `poc/test/InternetTokenGov.t.sol`. Forks Base via `vm.createSelectFork(BASE_RPC_URL || https://base-rpc.publicnode.com)`.

| Test | Result | Key numbers |
|---|---|---|
| `test_A_mechanism_timelock_capture` | **PASS** | quorum 25,258,494.79 INT; timelock drained of 292.5 M INT + 6,213.52 USDC + 2.2756 WETH via a single passing proposal (gas 1,653,853) |
| `test_B_acquisition_cost` | **PASS** | buys **25,258,494.79 INT** directly from pool `0xDEc6Eadb…` (`IUniV3Pool.swap`, exact-out) for **1,728,680,585,997,154,623 wei = 1.7287 WETH = $4,068.76** |
| `test_C_realisable_prize` | **PASS** | dumps 317,764,897.64 INT (own quorum + stolen 292.5 M) in 2 M-INT chunks → **2,893,194,473,190,431,240 wei = 2.8932 WETH = $6,809.65** (pool fully drained); gross realisable **$18,379.22** |
| `test_D_outbid_dominant_delegate` | **PASS** | proves the bare quorum LOSES (delegate votes 28,239,311.38 > quorum 25,258,494.79) and measures the winning stake: **30,239,311.38 INT for 2,208,770,759,054,776,873 wei = 2.2088 WETH = $5,198.74** |

**Runs:** [40232520195](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40232520195) (3/3, original) and [40248236760](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40248236760) (**4/4**, incl. the parent-added TEST D). Log: `ci-log.txt`; artifact: `ci-artifacts/`.

Net: `$18,379.22 − $5,198.74 = $13,180.48`.

---

## 7. Verdict & residual risk

- **Verdict:** the governance mechanism is genuinely open (no guardian, cheap quorum, funded timelock) and the extraction is **fork-proven**, but the **net is small ($13.2 k)** and **conditional** on off-chain admin/holder passivity ⇒ **E-U $13,180, confidence LOW**. This *corrects* the pass7 “$12–80 k” band downward to a precise, fork-measured number, and (via the parent agent's TEST D) shows the **bare quorum is insufficient** — a live delegate with 28.24 M INT must be out-voted, raising the acquisition cost to $5,198.74.
- **Latent risk (P):** the timelock holds the token's `ROLE_ADMIN`+`CONFIG_ADMIN`. Any future quorum holder can re-grant `TOKEN_MINTER` and re-arm the **Sep-21-2026 mint bug** (the vulnerable `LiquidityUnifier` `_validatePool` code is unchanged and still deployed — only the role was revoked). That is the more serious structural exposure, and it is governance-gated.
- **What would change the verdict:** a live `PROPOSAL_ADMIN`/`ROLE_ADMIN` operator (⇒ $0), an opposing whale, or a genuine second market for INT (⇒ higher net).

---

## 8. Methodology & sources; caveats; files

**Method.** All state read with `cast call` at pinned Base block 53082738 against keyless public RPCs; deployed sources pulled from Etherscan V2 (`ProtocolGovernor`, `GovTimelockController`, `RewardToken`, `RoleStore`, callbacks) and re-derived into `analysis/src_gov`, `analysis/src_timelock`; swap economics measured on a Foundry fork of Base (GitHub Actions).

**Sources.** Etherscan V2 (chainid 8453) verified source; `zombie-hunt-iv/pass7/gov-capture.md` & `gov-params.md` (leads, corrected here); GeckoTerminal pool API (used only for pool enumeration — its reserve figures are proven stale and were discarded in favour of `balanceOf`).

**Caveats.** INT is effectively illiquid (all pools vol24 = 0; pool-implied prices disagree ~10×); USD uses WETH $2,353.68 / USDC $1.00 at the snapshot. The v4 hooked pool `0xf38a84b4…` could not be verified and is excluded. Admin/holder behaviour is unobservable and is the dominant uncertainty.

**Files.** `README.md` · `summary.json` · `analysis/evidence.json` (raw reads) · `analysis/gov.sol`, `analysis/timelock.sol`, `analysis/src_gov/`, `analysis/src_timelock/` (deployed sources) · `poc/` (Foundry, 3 tests) · `ci/run.sh`, `ci-out/live-state.txt` · `ci-log.txt`, `ci-artifacts/`.

*No secrets, private keys or keyed RPC URLs are written anywhere in this folder. No transactions were sent to any network.*
