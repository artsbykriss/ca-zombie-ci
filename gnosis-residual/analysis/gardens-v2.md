# 1Hive Gardens v2 (Gnosis) — Residual Extraction Analysis

**Date:** 2026-10-15 · **Chain:** Gnosis (100) · **Status:** read-only; all state at block **48,767,754**; no transactions, no signing. Math validated against on-chain `calculateProposalConviction` (exact integer match) and against the historical execution of proposal 4 (Feb–Mar 2025).
**Scope (parent mission):** can an external unprivileged attacker extract HNY from 1Hive's Gardens v2 contracts (conviction-voting pool drain / community stake capture); quantify conditional paths net of costs.

---

## 1. TL;DR

| Target | Live value | Extractable by external unprivileged attacker? |
|---|---|---|
| CVStrategy pool 27 (HNY treasury) `0x9Fb2…F8A2` | **5,496.398 HNY = $5,380.52** | **Path is OPEN (permissionless) but NOT profitable for a fresh market-buying attacker: realistic net ≈ −$291 … −$832 (−$2,007 worst); perfect-routing best case +$174.** Hard cap on one proposal: **X < 0.5·F ≈ 2,748 HNY ($2,690)** |
| RegistryCommunity "1Hive" `0xE239…6257` (member collateral) | **5,694.657 HNY = $5,574.65** | **No outsider path.** Balance reconciles *exactly* with the sum of registered members' `stakedAmount` (diff 0.0); only self-unstake. kickMember is council-only and **disabled** (`isKickEnabled=false`) |
| Other Gardens communities on Gnosis (22 more) | 92.01 HNY total (stakes + stranded dust) | No fresh-attacker path (stakes are H-O for their members; 31 HNY in memberless/pool-less communities is stuck/P) |
| Council Safe `0xc6c2…3d81` (not a Gardens contract) | 645.16 HNY | P (Safe-owned; received the 1,000 HNY P4 payout) |
| HNY token mint | fixed supply 75,429.94 | MiniMeToken controller = `0xEd062e26…` (1Hive DAO agent) → mint is P |

**Headline: E-U = $0 (no reliable net-positive extraction for a fresh, market-funded attacker; best-case scenario ≈ +$175 = noise).** One-shot latent, holder-funded variant ≈ **+$800** in HNY terms for a holder of ≥1,676 HNY (X=1,000), up to ≈ +$1,500–1,900 for large holders — contingent on holding/slow-liquidating HNY and trivially blockable by the council (P).

---

## 2. Live architecture (verified at block 48,767,754)

Both the RegistryCommunity and the CVStrategy are **ERC1967 proxies whose implementation is a diamond host** (unverified code at the impl slot delegates via LibDiamond to verified facets). The parent-provided `CVStrategyV0_0.sol`/`RegistryCommunityV0_0.sol` (Oct-2024 sources) are **NOT the live code**; live code = diamond version (facet sources downloaded to `analysis/src_live/`, verified on Blockscout).

Addresses:
- RegistryCommunity "1Hive" proxy: `0xE2396fe2169ca026962971d3B2E373Ba925B6257`, EIP-1967 impl `0x7EFab2C3E82956CC621Ec658aD52615c6E6598E1` (verified "RegistryCommunity", VERSION()="0.0"). Facets: CommunityAdmin `0x9518…3a74`, CommunityMember `0xC504…6476`, CommunityPower `0xb1E3…494E`, CommunityStrategy `0x156d…32c9`, CommunityPause `0x8dF3…cCc8`, CommunityPool `0x2cFB…d9D6` (last two + admin unverified; behavior derived from bytecode selector table + live probes).
- CVStrategy pool 27 proxy: `0x9Fb2f1813228a97f559E29A6492EE27357FAF8A2`, EIP-1967 impl `0x2E4c11F66e3a124c2f689979eF635FDAF2eA0dC2`. Facets (verified): CVAdmin `0x4e0F…4061`, CVAllocation `0x3406…F3Bb`, CVDispute `0x58FC…3B22`, CVPower `0xB989…cda5`, CVProposal `0xaA61…48E5`, DiamondLoupe `0xD29D…404B`, CVPause `0xa4D3…a0b0`, CVSyncPower `0x447C…a406`, CVStreaming `0x86Cd…6a20`.
- Allo (FAllo, TransparentUpgradeableProxy): `0x1133eA7Af70876e64665ecD07C0A0476d09465a1`, impl `0xB087535DB0df98fC4327136e897A5985E5Cfbd66` (verified "Allo", Gnosis `distribute()` has **no permission check**).
- HNY (MiniMeToken): `0x71850b7E9Ee3f13Ab46d67167341E4bDc905Eef9`; supply 75,429.939563086058534633; controller `0xEd062e26c8F41a9088d060156eDC7fc6c17d5825` (contract; 1Hive DAO agent) → mint = P.
- RegistryFactory proxy: `0x08Df82f74D1f56F650E98da2dd4240F1A31711bc` (impl `0x8053DB39…`); `globalPauseController()` = `0xce853207ce3e16e268f572ea982801b8045f0afc`, owner of GPC = `0x00BcC26E…`.
- Upgrade authority (P): RC and strategy `_owner` storage (slot 51) = `0x91ab7a20cc3aee799df908fa1b2571fe8e07394a`, which resolves `owner()` to `0x00BcC26E792E393217bA895f5e85AE628FC994E9`. RC had **20** `Upgraded` events (latest 48,205,332), strategy **22** (latest 48,205,485) → both active, upgradeable (P).

### Live strategy state (block 48,767,754)
| Param (call) | Value |
|---|---|
| `cvParams()` | maxRatio **8,160,578** (0.8160578), weight **998,926** (0.0998926), decay **9,999,958** (0.9999958; 1−a = 4.2e-6), minThresholdPoints **100e18** |
| `getPoolAmount()` | **5,496.398013724949977708 HNY** (= balanceOf 5,496.259751 + 0.138 HNYx) |
| `totalPointsActivated()` | **5,069.627792347135925352** (pointSystem=2 → **Unlimited**, 1:1 with HNY) |
| `getPoolThresholdPoints()` | 5,073.182611413902524677 |
| `getPoolId()` | 27 · `proposalType()`=1 (Funding) · `sybilScorer()`=0 · `isPoolActive()`=false (unused in live logic) |
| `proposalCounter()`=4 · `activeProposalCount()`=0 · `activeProposalCountInitialized()`=false · `totalStaked()`=861.41 |
| `getArbitrableConfig()` (v2) | arbitrator `0x92bc0af7…`, tribunal `0x1b8c7f06…`, submitterCollateral **20 xDAI**, challengerCollateral 20 xDAI, defaultRuling=1, timeout 7d |
| `votingPowerRegistry()` | = RC (internal registry; syncPower disabled) |
| `superfluidToken()` | `0xc0712524b39323eb2437e69226b261d928629dc8` = **HNYx "Super Honey"** (GDA not connected, slot 129 = 0; streaming facet inactive) |
| `pauseController()` (strategy & RC) | **0x0** (pause checks skipped); GPC `isPaused(strategy/RC)` = false |

Proposals 1–3 = Cancelled, proposal 4 = Executed (1,000 HNY paid to councilSafe at block 39,070,697, tx 0xa37d2b50caa9…). **No active proposals exist today.**

### How the 5,496 HNY got there
13 inbound HNY transfers (6,496.259751 total) and 1 outbound (1,000) → net 5,496.259751 ✓ (`gardens-logs-transfers.json`). Main funders: councilSafe `0xc6c2…3d81` 4,785.69 HNY (2,379 + 906.69 + 1,500), `0x650e30621d4f65ab359229c183165a13bde7896d` 1,696.06, plus 11 small donations (0.001–5 HNY). `PoolAmountIncreased` events exist for the 7 fundPool calls (4,787.70 HNY); the rest arrived by direct transfer. P4's 1,000 HNY payout (to councilSafe) was the only outflow.

---

## 3. The conviction-drain path — exact requirements and gates

Full call path (all functions verified live; every gate passed by live reads/probes):

1. **Acquire S HNY** (market/OTC) → `approve(RC, 3 HNY)`.
2. **`RC.stakeAndRegisterMember("")`** (`CommunityMemberFacet`, 0x9a1f46e2) — **permissionless**. Live: `registerStakeAmount`=3 HNY, `communityFee`=0, factory `getProtocolFee(1Hive)`=0 → `getStakeAmountWithFees()`=3 HNY. Sets `stakedAmount=3`, `isRegistered=true`, `totalMembers=59→60`.
3. **`strategy.activatePoints()`** (`CVPowerFacet`, 0x814516ad) — self-service, not council-gated. Requires `_canExecuteAction(member)`:
   `sybilScorer==0` → falls to allowlist: `hasRole(keccak("ALLOWLIST"||poolId27), address(0))` **= true** (granted at block 38,391,943 by the authorized diamond init, never revoked; RoleRevoked count = 0) → **allowlist globally open**.
   *Live proof:* `eth_call activatePoints()` from non-activated member `0x121e1573…` **succeeds**; from non-member `0x…dEaD` reverts `UserNotInRegistry`; from member `0x809c9f8d…` reverts only `UserAlreadyActivated` (past the allowlist gate).
4. **`RC.increasePower(S−3)`** (0x559de05d) → `strategy.increasePower` (Unlimited: points += amount) → power = S.
5. **`Allo.registerRecipient(27, abi.encode(CreateProposal{poolId:27, beneficiary:attacker, amountRequested:X, requestedToken:HNY, metadata}))` + 20 xDAI** (CVProposalFacet 0x2bbe0cae). Requirements: **member** ✓, arbitrator set ✓, token==pool token ✓, collateral 20 xDAI (refunded on execution), `activeProposalCount<128` ✓, strategy enabled ✓. **No council action needed; no fee.** (Non-member probe reverts `OnlyMember`.)
6. **`Allo.allocate(27, abi.encode([(pid, S)]))`** (CVAllocationFacet 0xef2920fc). Requires member+activated + support ≤ power; positive deltas additionally require `_canExecuteAction` (open) and an Active proposal. Sets `stakedAmount=S`.
7. **Wait** t blocks: conviction(t) = Σx·(1−aᵗ)/(1−a), a=0.9999958.
8. **`Allo.distribute(27, [], abi.encode(pid))`** — **permissionless** (Allo has no gate; strategy `_distribute` has none). Gate: conviction **>** threshold(X, F, TP), status Active, X ≤ F, X < maxRatio·F (=4,485.4 HNY). *Live proof:* calling distribute for executed P4 reverts `ProposalNotActive(4,4)` — i.e., reached the strategy's own check, not a permission gate.
9. **`strategy.deactivatePoints()` / `RC.unregisterMember()`** → S HNY returned; P4-style executed proposal's collateral refunded.

### Exact conviction/threshold math (validated)
- Simulator reproduces on-chain `calculateProposalConviction(4)` = `205097619047489597051011415` **exactly** (27-digit match) → `analysis/conviction_math.py`.
- Threshold: `thr = weight·T·D²·F² / ((D−decay)·(maxRatio·F−X·D)²)`, floored by `100e18·D/(D−decay)` = 23,809.52e18; `T = _getThresholdPoints(proposal)` (decay-weighted snapshot of activated points, updated on every stake/allocate).
- Max conviction of a stake S = S/(1−a) = S·238,095.24. Because the attacker's own stake also raises T, the **feasibility barrier** is: `(β − X/F)² > ρ` → **X < (β−√ρ)·F ≈ 0.5·F ≈ 2,748 HNY ($2,690)** — independent of how much is staked. Asymptotic minimum stake `S > ρ·T₀/((β−X/F)²−ρ)`.

---

## 4. Attack economics (the decisive gate)

**Exact simulation** (`attack_sim.py`, block 48,767,221): minimal stake S and wait time to pass a proposal requesting X HNY, given live F=5,496.40, T₀=5,069.63, TP₀=5,073.19:

| X (HNY) | X ($) | S_min | wait at S_min | recommended 1.25×S | wait at 1.25×S |
|---:|---:|---:|---:|---:|---:|
| 100 | 98 | ~944 | ~150 d | ~1,180 | 22 d |
| 250 | 245 | 1,025 | ~150 d | 1,282 | 22 d |
| 500 | 489 | 1,189 | 155 d | 1,486 | 22 d |
| 1,000 | 979 | 1,676 | 167 d | 2,095 | 22 d |
| 1,500 | 1,468 | 2,595 | 148 d | 3,244 | 22 d |
| 2,000 | 1,958 | 4,843 | 159 d | 6,053 | 22 d |
| 2,500 | 2,447 | 16,559 | ~166 d | 20,698 | 22 d |

(22 days = 383k blocks at 5 s/block; ~80 % of the asymptote.)

**Market cost** (live reserves read on-chain; 9 HNY v2 pools on Gnosis, total HNY-side depth **11,202 HNY / $10,966**; liquid-counter pools only **4,845 HNY / $4,743**; largest pool WXDAI/HNY `0x4505b262…` 3,217 HNY / $6,282). Round-trip model: buy S, sell S+X (`market_final.py`):

| Scenario | X=250, S=1,025 | X=500, S=1,189 | X=1,000, S=1,676 |
|---|---:|---:|---:|
| Pessimistic (main pool only) | −$585 | −$770 | −$2,007 |
| **Realistic (liquid pools: xDAI/WETH/EURe)** | **−$291** | **−$324** | **−$832** |
| Optimistic (all 9 pools at parity, perfect routing, free FOX/AGVE/… legs) | +$10 | +$127 | **+$174** |
| X=1,500 (S=2,595) optimistic | | | −$387 |
| X=2,000 (S=4,843) optimistic | | | −$4,226 |

**Fresh-attacker net ∈ [−$2,007 … +$174]; central estimate ≈ −$300…−$800. No reliable positive-EV extraction.** The structural reason: S_min ≈ 1.0–1.7× X forces a round trip of ~2.7–3.7× X (≈$3.3k–3.7k for X=1,000) through a market whose whole usable HNY-side depth is $4.7k–11k; the round-trip friction exceeds the extractable X. Larger X makes it strictly worse (S grows super-linearly; X<0.5F cap).

**Conditional (no-acquisition) variant — any existing HNY holder (unprivileged):** skip the buy leg; stake S from own holdings; sell only X into fresh depth (≈10-20 % impact for X=1,000-2,000). Net ≈ **+$800** for X=1,000 (S=1,676; ~5 months, or 22 days with S=2,095), ≈ +$1,500-1,900 for X=2,000 (S=4,843–6,053) for holders that large (e.g. EOAs `0xc89000e1…` 3,160 HNY, `0x62523603…` 1,946, `0x6120f29c…` 1,126, or contract `0x4ba7362f…` 21,399). Griefable: any member can raise T by staking (raises the threshold within ~days), and the **council can `setPoolParams` (0xd5b7cc54/0x2bbe0cae, onlyCouncilSafe, no bounds validation on cvParams) to raise the threshold arbitrarily** → P-block.

**Fees/costs:** 20 xDAI collateral (refunded), gas ≈ cents on Gnosis, no flash-loan route (22-day lockup), no HNY lending market (Aave v3 Gnosis reserves = WETH/wstETH/GNO/USDC/WXDAI/EURe/sDAI/USDT/wstETH only — HNY not listed).

---

## 5. Other capture surfaces (all negative)

- **Others' stakes / kick:** `CommunityPowerFacet.decreasePower` is self-only; `unregisterMember` self-only; `kickMember` requires `onlyCouncilSafe` **and** `isKickEnabled` — live `isKickEnabled()=false`. No outsider path.
- **RC collateral reconciliation (H-O claim closed):** sum over all 65 current registered members of `addressToMemberInfo().stakedAmount` = **5,694.657446335795 HNY** vs RC balance **5,694.657446335795 HNY → diff = 0.000000000000** (`gardens-enumeration.json`). The RC's HNY is exactly the members' refundable collateral.
- **Streaming/superfluid:** proposalType=Funding; GDA=0; `rebalance()` authorized-caller-only → no path.
- **Upgrades:** RC/strategy `diamondCut`/UUPS = effective owner `0x00BcC26E…` via `0x91ab7a20…` (P); used actively (latest upgrades block 48,205,3xx, 2026-09-12).
- **Pause:** factory `globalPauseController`=0xce85… exists but both contracts' `pauseController()` = 0 → not wired; GPC owner 0x00BcC26E… (P to wire/pause).
- **HNY token:** MiniMeToken, mint via controller `0xEd062e26…` (P). No permissionless mint.

## 6. All Gardens communities/pools on Gnosis (23 communities, RegistryFactory `CommunityCreated`)

HNY balances (on-chain, block 48,767,75x): **1Hive RC 5,694.66 + pool-27 strategy 5,496.26**; Gardens🌱 20.00; Beez Faucet 30.00; Paul's Testing Garden 40.00; Web3 Unilag 1.00; No Cap 1.00; Zuzalu 0.01; all others 0. Total ≈ 11,282.93 HNY ($11,046) of which 11,190.9 HNY ($10,955) sits in the two 1Hive contracts. The 30/1/0.01-HNY communities have **0 members and no pools** → outsider-stuck (S; their councils/owner 0x00BcC26E… retain a P path); the 20/40/1-HNY balances are the members' own stakes (H-O). The OmniBridge `0x0EeAcdb0…` (3,346.72 HNY) is bridge escrow backing bridged supply — excluded. **No other Gardens-related HNY pot exists.** (Non-HNY pots exist in the 1Hive community: 1,308.80 sDAI pool 8 and 8,599.06 sDAI pool 67 — out of scope but same conviction mechanics could apply; sDAI is far more liquid, noted for the parent.)

## 7. Negative results / dead ends (do not re-investigate)
- `distribute` of any existing proposal: P1–P3 Cancelled, P4 Executed → none executable; no active proposals.
- `registerRecipient` non-member → `OnlyMember` (0x…dEaD probe).
- Allowlist NOT closed (an early malformed calldata produced a false "false" — corrected; `hasRole(ALLOWLIST27, 0x0)=true` at both block 48,767,103 and 48,767,754).
- Support/allocate to Cancelled/Executed proposals reverts `ProposalInvalidForAllocation`.
- `editProposal` cannot reduce `requestedAmount` once support is staked (bait-and-switch closed).
- No HNY flash-loan/lending market; no instant conviction shortcut; no auto-activation on registration (member must call `activatePoints()`; strategy must already be enabled — pool 27 is).

## 8. Verdict

| Category | USD (HNY @ $0.978918) | Confidence |
|---|---|---|
| **E-U (fresh external attacker, market-funded)** | **$0** (path open; net −$2,007…+$174; central −$300…−$800) | **medium-high** |
| **E-U conditional (HNY-holder-funded)** | **~+$800 one-shot** (X=1,000); ceiling ≈ +$1,900 (X=2,000, holdings ≥4.8k HNY); theoretical max X ≈ 2,748 HNY ≈ $2,690 needs S≈16.5k | medium |
| H-O | 5,694.66 (1Hive members) + 61.00 (small-community members) | high |
| P | 645.16 (councilSafe) + upgrade/params/pause authority + MiniMe mint | high |
| S | ~31 HNY stranded (Beez Faucet 30, Web3 Unilag 1, Zuzalu 0.01) for outsiders | medium |

**Exact gates that close/degrade the path:** (1) economics — S_min ≈ 1.0–1.7× X and X < 0.5·F ≈ 2,748 HNY against a market whose usable HNY depth is $4.7k–11k → round-trip friction exceeds the take; (2) time — 22 days best-case (1.25–1.5× stake) to ~5 months at S_min; (3) griefability — members restaking raises T, and council `setPoolParams` can raise the threshold arbitrarily (P); (4) holders-only — the only clearly positive-EV variant needs pre-existing HNY.

**What would change the verdict:** deeper HNY liquidity (≥ $100k HNY-side) or a bid-side OTC/block facility would flip the fresh-attacker path to positive (at X≈1,000-2,000); a change of cvParams (lower weight, lower maxRatio, higher minThreshold) would close it harder; wiring the GlobalPauseController or archiving the community would freeze it (P); the same mechanics apply to the far-more-liquid sDAI pools (1,308.80 + 8,599.06 sDAI) — a materially higher-value sibling target for the campaign to review.

## 9. Files
- `analysis/gardens-live-state.json` — all live calls (block 48,767,221) + `read_live_state.py`
- `analysis/gardens-logs-transfers.json` + `fetch_logs.py` — HNY in/out to strategy & RC, RoleGranted/RoleRevoked
- `analysis/gardens-enumeration.json` + `enumerate.py` — members, reconciliation, strategies, pools, factory topics
- `analysis/gardens-communities.json`, `gardens-pool-balances.json` — 23 communities & all pools
- `analysis/gardens-math-constants.json`, `conviction_math.py` — validated formula reproduction
- `analysis/gardens-attack-sim.json`, `attack_sim.py` — exact S_min/wait table
- `analysis/gardens-hny-liquidity.json`, `gardens-market-cost.json`, `gardens-market-final.json`, `market_cost.py`, `market_final.py` — DEX depth + round-trip costs
- `analysis/src_live/` — verified live sources of all facets/impls (RC, 9 CV facets, Allo, GPC)
- `analysis/gardens-verdict.json` — machine-readable summary

**Caveats:** Gnosis block time 5 s assumed (verified via two reads 118 blocks ≈ 10 min apart). Non-stable counter-assets (FOX/AGVE/WATER/LINK/BRIGHT) modelled at pool parity; the optimistic row overstates routability (thin counter-legs). Holder-variant net values assume patient/slow liquidation without further price impact. All amounts block 48,767,754; HNY price $0.978918 (DefiLlama 2026-10-15). No secrets or keyed URLs are present in any file.

---

## 10. Sibling sDAI pools (8 & 67)

**Date:** 2026-10-15 · all state read live at blocks **48,768,354 – 48,768,818** (unless noted) · read-only · no transactions.
**Question:** do the 1Hive sDAI pots (pool 8 ≈ 1.31k sDAI, pool 67 ≈ 10.5k sDAI) flip the pool-27 verdict to a **net-positive fresh-attacker E-U** drain?

**Answer: NO — but for the opposite reason to pool 27. The sDAI pools are not "open-but-unprofitable": they are permission-gated by an explicit member ALLOWLIST. A fresh attacker cannot activate points or add support at all (`UserCannotExecuteAction`). The economics, however, are inverted: IF the allowlist were open (or for a holder of an allowlisted key), the same conviction-drain is clearly NET-POSITIVE on sDAI (pool 67: +$3.0k…+$4.4k realistic per proposal). The allowlist is the single decisive gate.**

### 10.1 Live state (sDAI token `0xaf204776…`, $1.2617/sDAI¹)

| | Pool 8 (`0xaa019598…`) | Pool 67 (`0x96dee484…`) |
|---|---|---|
| `getPoolAmount()` (drainable) | **1,309.876004 sDAI** = $1,652.7 (1,308.804032 sDAI balance + 1.071971 Super Savings xDAI `0xd30aa2f6…`) | **10,545.18 sDAI** = $13,304.9 (8,599.061575 sDAI + 1,945.98 supertoken) |
| `cvParams` | maxRatio 1.2880072 · weight 0.0829481 · decay 0.9999939 · minThresholdPoints 10 | maxRatio 1.6321157 · weight 0.3995702 · decay 0.9999939 · minThresholdPoints 19 |
| `pointSystem` | **3 = Quadratic** (`P=√(S·1e18)`) | **3 = Quadratic** |
| `totalPointsActivated` / `getPoolThresholdPoints` | 132.3489 / 132.3606 pts | 122.6874 / 122.6991 pts |
| `proposalCounter` / active | 32 / **0** | 21 / **0** |
| `arbitrableConfig` (v2 / v1) | arbitrator `0x92bc0af7…`, tribunal Safe `0x1b8c7f06…`, submitter=challenger=**10 xDAI**, defaultRuling 1, timeout 7 d | arbitrator `0x92bc0af7…`, tribunal = **councilSafe**, 10 xDAI, defaultRuling 1, 7 d |
| Misc | proposalType=Funding, isPoolActive=false (unused), registryCommunity=RC, sybilScorer=0, owner `0x00BcC26E…`, pauseController `0x0` | same |

`sDAI` is an ERC-4626 over WXDAI: `convertToAssets(1e18)=1.26181544`, `maxRedeem(strategy)` = full balance, vault holds 41,363,928 wxdai vs 32,781,283 supply → **X sDAI is redeemable to ≈X·$1.2617 cash instantly, no DEX needed** (vs. HNY: illiquid). ¹ DefiLlama $1.261687; on-chain rate 1.26181544 × WXDAI $0.99987 = $1.26165 (both agree).

### 10.2 The decisive gate: ALLOWLIST (CLOSED — unlike pool 27)

* `_canExecuteAction` = `hasRole(keccak256("ALLOWLIST"||poolId), user)` (sybilScorer=0; pointSystem≠Custom). Live: `hasRole(ALLOWLIST8=0x1e7e…, address(0)) = 0` and `(ALLOWLIST67=0xb607…, address(0)) = 0` — **pool 27's open-allowlist trick (address 0 granted, block 38,391,943) does NOT exist here.**
* Full-range RoleGranted/RoleRevoked logs: pool 8 = 9 EOAs at creation (36,775,633) +2 (36,860,486) → all 11 revoked (39,106,746) → **14 re-granted (39,694,672) +1 (40,382,802)**; pool 67 = **15 granted at creation (40,891,404)**, none revoked. All 15 verified `hasRole=1` live in **both** pools; 3 random non-listed members = 0.
* `eth_call` probes: allowlisted non-activated member `0x62523603…` → `activatePoints()` **succeeds** (both pools); allowlisted already-activated `0x2f9e1134…` → `UserAlreadyActivated` (0xd5b9bc96); non-allowlisted members (`0x121e1573…`, `0x01a1de6c…`, `0x3af7f9f0…`) and non-members → revert **`UserCannotExecuteAction` (0xeee56a60)**. No activation → no `allocate` support (`UserIsInactive`/`UserCannotExecuteAction`) → zero conviction → `distribute` impossible.
* Role admins: `hasRole(getRoleAdmin(ALLOWLIST8), strat8)=1`, `(ALLOWLIST67, strat67)=1` → grants/revokes only via `strategy.setPoolParams` → `onlyCouncilSafe` (councilSafe `0xc6c2…` or owner `0x00BcC26E…`). **No permissionless grant path.**
* `syncPower()` (NFT-registry power injection) reverts `SyncDisabledForInternalRegistry` — no alternate power route.
* T0 is 100% insider: pool 8 activated power = 63.25 (`0x809c9f8d`) + 24.49 (`0xa25211b6`) + 15.21 (`0x07ad02e0`) + 12.49 (`0x8758e5…`) + 9.32 (`0x6c965b…`) + 7.59 (`0x2f9e1134`) = 132.35 ✓ exact; pool 67 = same minus `0x8758e5` plus 2.83 (`0xb2206f94`) = 122.69 ✓ exact. **No outsider holds any points.**

### 10.3 Counterfactual — if the allowlist were open, the drain IS net-positive

Exact integer simulator (same as §4; **validated: reproduces live `calculateThreshold` on 9/9 values on both pools**), Quadratic staking `P=√(S·1e18)`, proposal from a freshly-registered member, conviction waited out (10 xDAI collateral, refunded on execution, gas ≈ $0.10). S = min stake for execution within ≤30 d; net = X·$1.2617 − (buy S − sell S back, exact multi-pool DEX model, frozen live reserves) [realistic = xDAI/WETH/EURe pools only; optimistic = all 9 pools at parity].

| Pool | X (sDAI) | X ($) | S_min (HNY) | capital (buy $, realistic) | 30-d wait | **net realistic** | net optimistic |
|---|---:|---:|---:|---:|---:|---:|---:|
| 8 | 250 | 315 | 109 | 110 | ~30.0 d | **+$310** | +$312 |
| 8 | 500 | 631 | 241 | 249 | ~30.0 d | **+$606** | +$619 |
| 8 | 750 | 946 | 715 | 823 | ~30.0 d | **+$731** | +$852 |
| 8 | 1,000 | 1,262 | 3,557 | 13,140 | ~30.0 d | −$9,874 | −$1,219 (market depth kills it) |
| 67 | 1,500 | 1,893 | 791 | 928 | ~30.0 d | **+$1,628** | +$1,778 |
| 67 | 3,000 | 3,785 | 1,306 | 1,756 | ~30.0 d | **+$3,034** | +$3,475 |
| 67 | 4,000 | 5,047 | 1,915 | 3,109 | ~30.0 d | **+$3,278** | +$4,376 |
| 67 | 5,000 | 6,309 | 2,958 | 7,458 | ~30.0 d | +$645 (thin) | +$4,647 |
| 67 | 6,000 | 7,570 | 4,910 | n/a (> liquid depth) | ~30.0 d | infeasible | +$2,324 |

(60-day variants differ by <15% on S: e.g. 67/X=4,000 → S=1,762, net realistic +$3,590. At S_min the wait is inherently ~the window searched; capital is the HNY working stock, recovered at exit minus friction.)

**Binding constraints, in order:** (1) **allowlist** — the only hard gate today; (2) HNY market depth ($4.7k liquid side / $11.2k all-pools) caps S at ≈3–5k → caps X at ≈4–5k sDAI on pool 67 and ≈750–1,000 on pool 8; (3) Quadratic points make stake P² — X near the pool amount becomes astronomically expensive; (4) 30–60 d exposure (re-parameterisation by council, competing drains, price moves). **One-shot realistic best ≈ +$3.3–3.6k net on pool 67 (X=4,000).** This is a material inversion of the HNY verdict and is why the allowlist matters: without it, this is a net-positive, capital-light, permissionless drain of a liquid asset.

### 10.4 Live residual actually exposed (H-O/P, not E-U)

Current pools are actively used treasury pots (drain-and-refill pattern): pool 8: **25/32** proposals executed, 4,466.26 sDAI total; pool 67: **19/21** executed, 48,202.32 sDAI total. Funders: pool 8 ← councilSafe 3,434 + Safe `0x5c64bae6…` 736.069 + 5 + **1,600 from pool 67** (prop 19 payoff); pool 67 ← Super Savings xDAI `0xd30aa2f6…` 56,780 sDAI over 11 transfers (via `Allo.fundPool`; e.g. 9,114.97 at blk 48,365,701, tx from EOA `0xf33600fa…`) + 21.2. No `ProposalDisputed` event has EVER been raised on pools 8, 67 or 27.

With correct T handling (their points already inside T0), the allowlisted holders could each drain (beneficiary = self, no HNY purchase, gas-only cost):
| Member | Stake / points | pool 8 ≤30 d | pool 67 ≤30 d | combined ≤30 d |
|---|---:|---:|---:|---:|
| `0x809c9f8d…` (largest; setup/ops key) | 4,000 HNY / 63.25 | 1,129.4 sDAI | **7,723.2 sDAI** | **8,852.6 sDAI = $11,169** (asymptote $11,442) |
| `0xa25211b6…` | 600 / 24.49 | 791.0 | 1,965.5 | 2,756.5 = $3,478 |
| `0x07ad02e0…`, `0x14d928…`, `0x8758e5…` | 12–15 pts | 432–550 | 0 (< 19-pt floor) | $545–694 each |
| other 9 allowlisted stakes | ≤9.32 pts | 0 (< 10-pt floor) | 0 (< 19-pt floor) | $0 |

Total at risk across both pools now: **$14,957.6** (11,855.06 sDAI). A single key (`0x809c9f8d`, the operator EOA that also ran the allowlist setup and most executions) could take ≈**$11.2k in one 30-day round**, ≈$8.4k of it from pool 67 — the pools' own min-threshold floors (10 / 19 points) are what stop the smaller allowlisted stakes.

### 10.5 Re-verified gates (item 3 of the parent task)

* **Agreement `0x59a15718…` does NOT cover the CV strategies**: `getDisputableInfo(strategy 8/67/27) = (false, 0)`. The id-3 requirement from the main report (action/challenge amount `6.061864241695410850`, challengeDuration 259,200 s = 3 d) belongs to the **old ConvictionVoting app `0x0b21081c…`** — confirmed live: `getDisputableInfo = (true, 3)`, id-3 decode = 3-day duration with the 6.0618e18 amounts. Challege path there is the legacy Celeste route; irrelevant to pools 8/67.
* **Celeste `0x44E4fCFed…` = AragonCourt, code live but not wired to the CV pools** (0 events in the last ~200k blocks ≈ 11.6 d; not referenced by any strategy). The CV arbitrator is Gardens' own EIP-1967 proxy `0x92bc0af7…` → impl `0x106fA428…` (unverified, deployed by owner `0x00BcC26E…`).
* **In-strategy dispute (CVDisputeFacet):** any *member* (allowlist not required) may `disputeProposal` by locking **10 xDAI** challenger collateral + arbitration fee → proposal `Disputed` → `distribute` reverts; after 7 d the arbitrator (or timeout with defaultRuling=1) returns it to `Active` → **challenges only delay, they do not block**, unless the (untested, unverified) arbitrator actually rules 2 = Rejected. Challenger loses collateral to council on failure. Zero disputes ever on any CV pool.
* **Council P-blocks confirmed live:** `setPoolParams` = `onlyCouncilSafe` (unbounded cvParams — can raise weight/minThreshold or close the allowlist); `kickMember` council-only + `isKickEnabled()=false`; `pauseController()=0x0` (RC & both strategies) and GPC `isPaused=false` (not wired); owner/upgrade authority `0x00BcC26E…` (active diamond upgrades).

### 10.6 Verdict

| Category | USD | Confidence |
|---|---|---|
| **E-U (fresh external attacker)** | **$0 — path is CLOSED by the ALLOWLIST gate** (`UserCannotExecuteAction` on activate/support; 15-address list, council-managed). NOT "open but unprofitable" like pool 27. | **high** |
| E-U *counterfactual* (if allowlist opened) | **net-positive**: pool 67 realistic **+$3.0k…+$3.6k** (best X≈4,000, S≈1.8–1.9k HNY, 30–60 d), pool 8 **+$0.31k…+$0.73k** (X=250–750); pool 67 optimistic ceiling +$4.4k; repeatable if refilled | medium-high (math exact; market model) |
| H-O/P (15 allowlisted insiders) | single key ≈ **$11.2k / 30 d** (max $14,957.6 across both pools) | medium-high |
| P (council/owner) | setPoolParams (allowlist/cvParams), upgrades, pause wiring | high |

**What would change the verdict:** the council (or owner) calling `setPoolParams` to grant `ALLOWLIST` to `address(0)` (or to any single address they lose control of) instantly creates a **net-positive E-U path** — the opposite of the HNY pool where deeper liquidity would be needed. The funds are liquid cash (sDAI redeemable at 1.2618 xDAI), the gate is one role grant, and the pools are refilled regularly by 1Hive. Conversely, wiring the pause controller, raising `minThresholdPoints`/`weight`, or de-activating the strategies closes the latent risk. Two of the 15 allowlisted addresses are EIP-7702 delegated EOAs (`0x8d5fe65f…`→`0x63c0c19a…`, `0x6c965b65…`→`0x612373d7…`).

**Caveats:** sDAI price/rate as of 2026-10-15 ($1.2617; the vault is ERC-4626 over WXDAI, redemption capacity verified). Pool 67's supertoken leg grows slightly over time (streams), so `getPoolAmount` drifts upward (10,545.04→10,545.18 across ~20 min). The counterfactual net uses the same HNY DEX depth model as §4 (reserves re-read live at blk 48,768,532: 4,844 HNY liquid side / 11,202 all-pools) and assumes the attacker survives the 30–60 d wait unchallenged/uncounteracted; a competing drain or cvParams change can invalidate it mid-flight. The sell-back leg is priced on pre-buy (fresh) reserves, so the realistic nets are a mildly optimistic bound (order ~10 %). Insider X-max values assume that member acts alone with current stake and that no peer drains concurrently.

### 10.7 Files (this section)
- `analysis/gardens-sdai-live.json` + `sdai_read.py` — pool params, balances, arbitrable configs, Agreement/GPC reads (blk 48,768,354+)
- `analysis/gardens-sdai-allowlist.json` + `sdai_allowlist.py` — full RoleGranted/RoleRevoked history for ALLOWLIST8/67
- `analysis/gardens-sdai-allowlist-probes.json` + `sdai_probes.py` — live hasRole matrix, `activatePoints` probes, proposal history, sDAI in/out transfers
- `analysis/gardens-sdai-params-live.json`, `gardens-sdai-attack-sim.json` + `sdai_attack_sim.py` — validated exact sim + counterfactual net table + live HNY depth
- `analysis/gardens-sdai-insider.json` + `sdai_insider_sim.py` — per-address max drain (correct T handling)
- `analysis/gardens-sdai-verdict.json` — machine-readable summary
No secrets or keyed URLs are present in any file.
