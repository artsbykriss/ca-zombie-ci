# Pala (Kaia) — zombie-hunt II, L2 watchlist Phase-2 deep dive

**Date:** 2026-10-14 · **Chain:** Kaia mainnet (chainId 8217, ex-Klaytn Cypress) · **Status:** read-only; PoC fork-verified only; no mainnet transactions.

**Target (triage row):** Pala — LIVE-FUNDED, triage market-priced custody **$41,651.40** (block 229,512,567), DefiLlama inflated $400,740 (its adapter reads Pala's internal oUSDT-denominated price lens and treats it as USD).

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why closed/open | Latent risk |
|---|---|---|---|
| Pala DEX (89 UniV2 pairs, factory `0xa25b…9cb1`) | **$0** (high confidence) | `skim()` excess = 0 on **89/89 pools** (fork-verified: 0 pools with excess, 89 without); pool balances == stored reserves; factory setters revert `Pala: FORBIDDEN`; arb across real-value pools ≤ ~$0.09 | None material; pools are actively traded (recent swaps) |
| PALA farm `0xcfc1…76c` (MasterChef) | **$0** (high confidence) | Emissions (0.0625 PALA/block) accrue to pool 15 (alloc 99,993/99,994), whose LP can only be minted with REWARD/BURN tokens — both `Ownable`-gated, 1-token supply, no market → LP unobtainable by an attacker; `migrate()` reverts (no migrator), `dev()`/`setMigrator()` gated; `pendingReward(0, attacker) = 0`; `emergencyWithdraw` pays 0 | If REWARD/BURN owner ever mints/sells, farm emissions (~$4/day) become farmable |
| ATTEN farm `0x8837…771` | **$0** | Farm ended at block 78,207,245; PALA balance 13,474.58 == staked principal; not a PALA minter | None |
| PALA / ATTEN tokens | **$0** | `mint` owner-only / minter-only (`caller is not minter`); no public mint | Owner key could mint (P) |
| ATTEN claim contract (= ATTEN token) | **$0** for attacker | `claim()`/`pendingReward` per legacy holder; reward window over (`getMultiplier(now, now+1) = 0`); 115,727.44 PALA unclaimed (≈$87 at lens price) | Legacy ATTEN holders could still claim (H-O) |
| pKLAY `0x1f2d…da5` | **$0** | 1:1 KLAY wrapper; native balance == totalSupply exactly (561,297.59 KLAY) | None (holders redeem 1:1, H-O) |
| WKLAY `0x2ff5…947c` | **$0** | 1:1 KLAY wrapper; native == supply exactly (237,705.46 KLAY) | None (H-O) |
| Viewer/lens `0x2B16…1B9` | **$0** | View-only; holds 0 tokens/0 KLAY; prices only 3 of 178 tokens (WKLAY/PALA/oUSDC) in oUSDT units; no on-chain value-moving consumer | If an external protocol consumes the lens, spot-derived prices could be manipulated — out of Pala scope |

**Total live extractable by an external unprivileged attacker: $0** (high confidence).

**Custody measured live (block 229,800,562):** **$66,944.61** market-priced (`oUSDT $23,994.66; PALA $18,284.01; oUSDC $12,922.27; WKLAY $8,496.29; oETH $1,511.55; oXRP $777.32; KDAI $647.15; oWBTC $311.37`). PALA is valued at the lens-implied price; excluding it, hard-value custody is **$48,660.60**. This value belongs to LP holders/stakers (H-O) — of which ≈ **$26.2k is staked in the two farms** (H-O for stakers) and the rest is LP tokens held outside the farms (H-O for their holders; some may be lost keys → S).

---

## 2. The mechanism in exact terms

Pala is a **Uniswap V2 fork DEX** (pairs include EIP-2612 permit; runtime code 14,925 B; selectors `mint/burn/swap/skim/sync/getReserves/kLast/initialize/permit`), with:

- **Factory** `0xa25ba09d8837f6319cd65b2345c0bbea99c39cb1` — `allPairsLength() = 89`, `feeTo() = 0x0`, `feeToSetter() = 0xa46be0bcc61a9ca048fabb625ea80c75f872686d` (EOA). `setFeeTo`/`setFeeToSetter` from an arbitrary caller revert `Pala: FORBIDDEN`.
- **Lens/viewer** `0x2B16648ddD1559fc86e0c0617213Ab5dd2Ea01B9` — `poolInfos()` (89 pools: tokens, reserves, balances), `tokenInfoDetail(address)` (info + **price**), `tokenPrice(address)`, `farmInfos(address)`, 178-token registry (`0x273cbaa0`), `kusdt() = 0xcee8FAF…d167` (oUSDT).
- **Farms** (SushiSwap-style MasterChef):
  - PALA farm `0xcfc140e8e3b1b05f9acb4a42249b7abb8c27576c`: 16 pools, `totalAllocPoint = 99,994`, `rewardPerBlock = 0.0625 PALA`, `startBlock = 78,244,017`, `migrator() = 0`, `devaddr() = 0xa46be0bc…`, `owner() = 0x6981705d…` (EOA). `isMinter(PALA farm) = true` → the farm **mints** PALA rewards. Pool 15 (alloc 99,993) stakes LP of pair `0xf7469c09…74c5`.
  - ATTEN farm `0x883726a307d420286086679f7851d8378bb16771`: 10 pools, `totalAllocPoint = 100`, `rewardPerBlock = 1 ATTEN`, atten farm `endBlock = 78,207,245` (long past), `migrator() = 0`. `isMinter(ATTEN farm) = true` (mints ATTEN, not PALA).
- **Tokens**: PALA `0x7a1cdca99fe5995ab8e317ede8495c07cbf488ad` (owner `0x6981705d…`; `mint(uint256)` owner-only, `mint(address,uint256)` minter-only), ATTEN `0x9160421ea3d1a24101d985b026a60cb0442322cc` (same pattern + PALA claim machinery), WKLAY `0x2ff5f6de…` (1:1 KLAY wrapper), pKLAY `0x1f2d6282…` (1:1 KLAY wrapper).
- **Pool-15 LP gate**: pair `0xf7469c09…74c5`'s tokens are `REWARD` (`0x6d52751b…`, 1-token supply) and `BURN` (`0xfe9138db…`, 1-token supply) — both `Ownable`, `mint` owner-only (owner `0xa36e0629…`). The LP (100% staked in the farm) cannot be minted or bought by an outsider.

**The "inflated oracle" (triage note), explained.** The viewer's `tokenPrice` returns prices **denominated in oUSDT**, not USD: at block 229,800,562 only three tokens are priced — WKLAY `0.4259884910673348`, PALA `0.007217161590779585`, oUSDC `2.812380349406114` (oUSDT itself returns 0; all other 174 registry tokens return 0). DefiLlama's Pala adapter (`projects/pala/index.js`) multiplies pool reserves by `tokenInfoDetail().price` and reports the sum as **USDT** — i.e. it implicitly values oUSDT (post-Orbit-hack, market $0.104) at $1.00, inflating TVL ~6× ($400,740 vs $66,945 market-priced with the full price table; vs the triage's $41,651 which omitted WKLAY/PALA). The lens itself is **not** the extractable object: it is a view contract with no value-moving consumers among Pala contracts (farms use alloc-points, pairs use reserves, wrappers are 1:1). Its prices move with pool spot state (WKLAY moved 0.4350→0.4260 between reads), so it would be manipulable if some external contract consumed it — none found on Kaia for Pala.

**ATTEN→PALA claim (launchpad, 2021).** The ATTEN token contract doubles as the PALA claim distributor: `rewardToken() = PALA`, `startBlock() = 78,293,645`, `rewardPerBlock() = 0.5 PALA`, `getMultiplier(78,293,645, 92,708,845) = 14,415,200` (the 168-day window; `getMultiplier(now, now+1) = 0`). It still holds **115,727.44 PALA** unclaimed; per-address `pendingReward`/`claimedReward` govern claims (observed only for legacy addresses; pools hold dust ATTEN with pending ~1e-8 PALA). Buying the dust ATTEN in the pools does not unlock meaningful PALA (the 700.63-ATTEN pool has pending 0 / claimed 9.54). Bounded ≈ $87 at lens price; H-O for legacy holders at most.

---

## 3. Live-state assessment (Kaia mainnet, CI state probe, block 229,800,562)

Source: `ci-out/state_probe.json` (GitLab pipeline artifact). All values at block 229,800,562 unless noted.

- **89/89 pairs probed:** `pools_with_positive_excess = 0`, `pools_with_negative_excess = 0`; `balances_usd_total == reserves_usd_total == $66,944.61` → every pool's token balances equal its stored reserves (skim = $0).
- **PALA farm:** owner `0x6981705d…` (EOA), `migrator() = 0`, `devaddr() = 0xa46be0bc…`, `totalAllocPoint = 99,994`, `rewardPerBlock = 0.0625 PALA`, PALA balance `4,658,619.222702579` == pool-0 staked principal. Attacker simulations: `migrate(0)`, `dev(attacker)`, `setMigrator(attacker)` → revert; `pendingReward(0, attacker) = 0`.
- **ATTEN farm:** owner `0x6981705d…`, `migrator() = 0`, `totalAllocPoint = 100`, `rewardPerBlock = 1 ATTEN`, PALA balance `13,474.580575105847` == pool-0 staked principal. Same reverts.
- **Roles:** PALA owner `0x6981705d…`; `isMinter(attacker) = false`, `isMinter(palaFarm) = true`; supply `79,090,616.506491270171412292`. ATTEN owner `0x6981705d…`; `isMinter(attenFarm) = true`; supply `7,257,600`. `mint(uint256)` / `mint(address,uint256)` from attacker → revert (`Ownable`/`caller is not minter`). Factory `feeTo = 0x0`, `feeToSetter = 0xa46be0bc…`; setter simulations revert `Pala: FORBIDDEN`.
- **Wrappers:** pKLAY `native == totalSupply == 561,297.593682772912801472` (delta 0); WKLAY `native == totalSupply == 237,705.462526663220865292` (delta 0).
- **Viewer:** 178 registry tokens; nonzero `tokenPrice`: WKLAY `0.4259884910673348`, PALA `0.007217161590779585`, oUSDC `2.812380349406114`; `kusdt() = oUSDT`; viewer holds 0 tokens/0 KLAY.
- **Fork-verified spot checks (block 229,801,572, local ankr fork):** `factory.allPairsLength == 89 == embedded list` and every factory pair is in the list; skim test: **0 pools with excess, 89 without, 0 failures** (gas 3,686,047).
- **Farm-staked value (H-O):** ≈ $22,633 of LP staked in the PALA farm + $451 in the ATTEN farm + 4,672,094 PALA single-staked ≈ $3,532 → ≈ **$26.2k staker-recoverable**.
- **Custody by token (pools):** oUSDT 231,006.62 ($23,994.66); PALA 24,185,198.73 ($18,284.01 @ lens price); oUSDC 44,242.23 ($12,922.27); WKLAY 187,970.93 ($8,496.29); oETH 8.9818 ($1,511.55); oXRP 582.87 ($777.32); KDAI 6,947.39 ($647.15); oWBTC 0.0163 ($311.37); ATTEN 700.63 ($0).

---

## 4. What an attacker can/cannot do (exact call paths)

**Cannot (fork-verified, `poc/test/Pala.t.sol`):**
- `factory.setFeeTo(attacker)` / `setFeeToSetter(attacker)` → revert `Pala: FORBIDDEN`.
- `PALA.mint(...)`, `ATTEN.mint(...)` → revert `Ownable: caller is not the owner` / `caller is not minter`.
- `palaFarm.migrate(0)` → revert `migrate: no migrator`; `dev(attacker)` → devaddr-gated; `setMigrator(attacker)` → owner-gated.
- `palaFarm.withdraw(0,1)` (zero stake) → revert; `emergencyWithdraw(0)` → pays 0 (asserted no balance change).
- `REWARD.mint`/`BURN.mint` → revert `Ownable: caller is not the owner` → **LP for farm pool 15 unobtainable** → farm emissions not capturable.
- `skim(pool)` → transfers 0 on all 89 pools (no excess).

**Can (permissionless, value-neutral):**
- `massUpdatePools()` / `updatePool(pid)` — mints accrued PALA to the farm, updates `accRewardPerShare`; pays the caller nothing (asserted).
- `initRewardPerBlock()` (0x60709b18) / `updateRewardPerBlock()` (0xdf27123a) — callable, but only adjust the emission rate; emission capture remains LP-gated (see §6).
- Normal swaps/mints/burns against pairs — arbitrage bounded by depth (≈$0.09 across all priced pairs; §6).
- Wrapper deposit/withdraw (WKLAY/pKLAY) 1:1 — no gain.

---

## 5. PoC / fork verification

- Files: `poc/test/Pala.t.sol`, `poc/foundry.toml` (via-IR), `ci/probe_state.py`, `ci/run.sh`, `ci/gitlab-pala.yml`.
- Tests: `test_factoryCount` (89 pairs cross-check), `test_skimExcess` (all-pool skim + JSON), `test_adminGates`, `test_farmsNoFreeMoney`, `test_pklayBacking`, `test_viewerOracleLens`, `test_farmEmissionFunctions`, `test_farmLpAcquisitionGate`.
- Local fork results (ankr, block 229,801,572): `test_factoryCount` PASS; `test_skimExcess` PASS (**0/89 pools with excess**); `test_adminGates` PASS; `test_pklayBacking` PASS.
- CI: GitLab pipeline `https://gitlab.com/group18185918/pala-ci/-/pipelines/2947886494` (state probe PASS at block 229,800,562; forge step initially hit an RPC 429, rerun with fork-retries and ankr — see ci-log/artifacts). GitHub Actions run: `https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38617004412` (dispatched; local network to GitHub API was intermittent during the session).

---

## 6. Bounded/conditional opportunities (not headline E-U)

- **Cross-pool arbitrage (measured, ≈$0.09):** real-value pools are aligned with DefiLlama reference prices within fees — oUSDC/oUSDT +0.01%, KDAI/oUSDT +0.00%, oXRP/oUSDT +0.19%, oETH/oUSDT +0.32%, oWBTC/oUSDT +0.33%; the only material deviation is the WKLAY/oUSDT pool `0xAb47eDf3…` at −2.28% (pool TV $1,717), whose optimal gross extraction is **$0.09**. Dust pools with huge % deviations hold $0.
- **Farm emissions if REWARD/BURN ever becomes obtainable:** the PALA farm mints 0.0625 PALA/block (≈5,400 PALA/day ≈ $4/day at the lens price), accruing 99.993% to pool 15's staker. If the REWARD/BURN owner (EOA `0xa36e0629…`) mints and sells the tokens (or the farm's alloc/migrator is ever changed), an attacker could mint LP, stake, and capture emissions, then sell PALA into the pools (bounded by pool depth, ≈$40k of non-PALA reserves across the PALA pools). Latent, privileged-triggered.
- **ATTEN claim:** 115,727.44 PALA (≈$87) unclaimed; legacy-holder path only (H-O); window over.

---

## 7. Verdict, residual risk, blockers

- **Verdict:** no live unprivileged extraction found. All custody is LP-holder/staker property (H-O) or lost (S); the DEX/farm/token machinery has no open admin, mint, migrate, or skim path.
- **Residual/latent:** (1) REWARD/BURN owner mint → turns on farmable emissions (~$4/day, bounded by pool depth); (2) PALA/ATTEN owner mint (P); (3) the lens being consumed by a future/external protocol (out of scope); (4) legacy ATTEN claim (H-O, ≈$87).
- **Blockers for extraction:** zero excess balances (skim = 0, 89/89 pools), all privileged setters gated, farm LP for the emission-bearing pool gated by owner-mintable REWARD/BURN.

---

## 8. Methodology & sources; caveats

- All state read with `eth_call`/`eth_getCode` at explicit blocks; selectors cross-checked with `cast sig`; token prices from DefiLlama `coins.llama.fi` (2026-10-14: oUSDT $0.10387, oUSDC $0.29208, oETH $168.29, oWBTC $19,047.97, oXRP $1.3336, KDAI $0.09315; WKLAY/pKLAY = KLAY ≈ $0.0452, 1:1 wrappers verified on-chain; PALA at the lens-implied price).
- **Caveat (local tooling):** the local machine's network to public Kaia RPCs was intermittent; single calls were double-read and cross-checked across three RPCs (`public-en.node.kaia.io`, `rpc.ankr.com/kaia`, `klaytn.drpc.org`), and bulk probes were run in CI. One early probe bug (reading `balanceOf(token)` instead of `balanceOf(pool)`) was found and fixed before drawing conclusions; the buggy runs were discarded.
- **Caveat (coverage):** LP-token holder enumeration was not completed (the public node does not serve historical logs and does not expose token-holder indexes); the H-O/S split of custody is computed from farm `poolInfo` + pair `totalSupply`/reserves, not from a full holder census. Pair bytecode was not diffed against a locally compiled canonical Uniswap V2 pair (behavioral checks only).
- Sources: on-chain reads (this report), DefiLlama adapter `projects/pala/index.js`, triage `l2-triage-b` (block 229,512,567), DefiLlama prices API, Pala launch announcement (Medium, 2021-11-22).

## 9. Files index

- `README.md` (this file), `summary.json`
- `analysis/`: `pool_list.json` (89 pairs), `verified_reads.json`, `viewer_state.json` (farms/token list decode), `decode_viewer.py`, `decode_state.py`, `probe_v3.py`, `rpc.txt`
- `poc/`: Foundry project (`test/Pala.t.sol`, `foundry.toml`, vendored forge-std)
- `ci/`: `run.sh`, `probe_state.py`, `gitlab-pala.yml`, `retry-ci.sh`
- `ci-out/`: CI-produced `state_probe.json` + `skim_results.json` (local fork)
