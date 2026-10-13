# Nuri CL (Scroll) — L2 Phase-2 deep dive

**Date:** 2026-10-14 · **Chain:** Scroll (534352) · **Target:** Nuri Exchange CL (Ramses V2 fork) ·
**Status:** read-only; PoC fork-verified only (CI anvil fork at block 35364505); **no mainnet transactions were signed or sent**; no secrets committed.

**Triage row:** `l2-triage-b` #17 — Nuri CL, $116,430.64 live (CL factory `0xAAA32926fcE6bE95ea2c51cB4Fcb60836D320C42`, 95 pools, block 35337420).

---

## 1. TL;DR

| Target (live at block 35364648/35364740) | Live value | E-U now (fresh attacker) | Why closed | Latent risk |
|---|---|---|---|---|
| **Nuri CL pools** — 95 pools via factory `0xAAA32926…` | **$116,741** (WETH/USDC $59.3k, WETH/STONE $15.9k, WETH/USDT $9.9k, …) | **$0** | All principal is owned by position NFTs (H-O); every admin/protocol path is gated (`AUTH` / `onlyFeeCollector`); prices track the market (<0.16% dev, below fees) | Safe can `setImplementation` **immediately** (no timelock) → all pools upgradeable by 1-of-3 Safe (P) |
| Gauge NURI rewards — 62 gauges (19 alive) | 3,434,097 NURI + 0.001 WETH ($2.61) | **$0** | Claims require NFT owner/operator; pool checkpoint guard blocks retro-claims (fork-proven); NURI has no exit liquidity | — |
| FeeDistributors — 31 FDs hold WETH>0 | **~$3,671** (core WETH/USDC/USDT $3,282.96: 0.7168 WETH + 1,370.37 USDC + 114.90 USDT; plus SCR/LSTs/DAI/USDe/NURI at marginal prices) | **$0** | Claims require veNFT `isApprovedOrOwner`; rewards snapshotted per period by voter-only `_deposit/_withdraw`; split/merge blocked while voted; 6/6 attacker sims revert; >99% of the historical 85.6 WETH / 251.4k USDC inflow was already claimed by the recorded voters | Periods deposited with `votes==0` are permanently stuck (S): live samples 536 NURI + 17.8 USDC + 47 SCR; burned-veNFT rewards unrecoverable |
| Protocol fees in pools (feeProtocol=100% of swap fee) | **$128.85** | **$0** | `pool.collectProtocol` is `onlyFeeCollector`; `FeeCollector` pays **100% to the treasury Safe** (`treasuryFees=10000`) — fork-proven | FeeCollector sweeps its *whole* balance to treasury (treasury-sweeper, not attacker profit) |
| NFP (positions) | $0 held by NFP | **$0** | `collect/decreaseLiquidity/burn/getReward` revert for non-owners; 7,573 NFTs, owners = users | `sweepToken/unwrapWETH9/refundETH` are public (Uniswap-standard) — value sent to the NFP is stealable by anyone (currently $0) |
| veNURI | 20,767,434 ve (30.43M NURI locked) | **$0** | `withdraw/merge/split/transferFrom` all `_isApprovedOrOwner` | — |
| **Nuri V2 AMM** (74 pairs, factory `0xAAA16c01…`) | **$4,576** ($5,237 incl. NURI at marginal) | **$0** | `skim()` excess = 0 wei on all 148 sides; no self-owned LP; all admin setters revert; `claimFees()` only notifies the fee distributor ($0.07 total) | — |

### **Total live extractable by an external unprivileged attacker now: $0.00**
**Confidence: high** (10/10 fork tests PASS on CI; every candidate path either reverts, pays a third party, or is capped at <$10 by market pricing/liquidity; independent child audits of NFP/ve/V2 and fee distribution).

---

## 2. What Nuri CL is (exact architecture, re-verified)

Nuri is a **Ramses V2 fork** on Scroll ("NURI is a next-generation AMM … combining … Uniswap v3 with a custom incentive engine, vote-lock governance"). The identical factory address `0xAAA32926…` is also used by Nile CL (Linea) and Ra (Fraxtal) — the same codebase family deployed by the same team.

| Component | Address | Notes |
|---|---|---|
| CL factory proxy (TransparentUpgradeableProxy) | `0xAAA32926fcE6bE95ea2c51cB4Fcb60836D320C42` | logic `0xc66a64f8c1D14FA2E888cf67Cf187782B9dAbe80` (ClPoolFactory, verified 0.7.6) |
| — same address is the **pools' beacon** | | `pools → factory.implementation()` |
| Pool implementation (beacon logic) | `0xDBA1DDc96d2df6850808f0317CEeF773A74e565C` | ClPool (Ramses V2, 45,073 bytes runtime; source extracted) |
| Pools | 95 BeaconProxy pools (created from ~block 5.3M) | 4 fee tiers + custom tiers (fee=250 etc.) |
| FeeCollector (proxy) | `0xAAA2A49958a443Dc9d19FdDEe873B5D1d6e84A2f` | treasury = Safe; `treasuryFees=10000` (100%); `isTokenLive=true` |
| Voter (proxy) | `0xAAAf3D9CDD3602d117c67D80eEC37a160C8d9869` | 62 pools/gauges, 19 gauges alive |
| NFP manager (proxy) | `0xAAA78E8C4241990B4ce159E105dA08129345946A` | 7,573 position NFTs |
| VotingEscrow (proxy) | `0xAAAEa1fB9f3DE3F70E89f37B69Ab11B47eb9Ce6F` | 20.77M veNURI; 30.43M NURI locked |
| feeSetter | `0xAAA11500dDdB2B67a90d1a154dfB7eaBB518EAE6` → CommandCenter impl `0x6ED9D8B1…` | role-gated (AccessControl) |
| Owner / treasury / governor / council | Gnosis SafeL2 `0xC9d28676b7d470210a3C490B60729660eE5a7257` | **threshold 1 of 3** owners (`0x9726…b48c`, `0x4051…9016`, `0xbE0c…3f89`), nonce 1090 |
| ProxyAdmin (shared) | `0x8e01fc0d89b93a6447d6c6eca6fbd30e6e4a1ce3` | owned by TimelockController `0xAAA13CBe7A8Cf93CF3505d00Fe254fDCCE14EF4E` (minDelay **86400 s**; Safe holds PROPOSER+EXECUTOR+ADMIN) |

**How the pools are wired:** every pool is an OZ `ClBeaconProxy` whose beacon slot `0xa3f0ad74…` holds the factory proxy; `factory.implementation()` returns the shared ClPool logic. Pool state lives at the namespaced slot `keccak256("states.storage")` in each proxy.

---

## 3. Live-state assessment (all reads read-only at the stated blocks)

**Block 35364648** (local re-verification; CI enumeration at 35364740):

- 95/95 pools initialized (`sqrtPriceX96 > 0`), all `unlocked=true`; none bricked.
- Pool token balances re-read and priced with DefiLlama: **$116,740.98** total (priced tokens; unpriced airdrops contribute $0). Top pools: `0xe0da…9cd3` USDC/WETH $59,283; `0x97a90e…c73b` WETH/STONE $15,884; `0x05dff4…75bf` WETH/0xf610 $12,218; `0x6e13a2…7fe3` WETH/USDT $9,888; `0x02efd6…0cd7` WETH/0xa25b $7,317; `0x23c5d4…98fc` 0x01f0/WETH $6,905.
- **Prices vs market** (DL 2026-10-13: WETH $2509.65, USDC $0.99982, STONE $2682.71):
  - USDC/WETH pool: 2506.37 USDC/WETH vs market 2510.1 → **0.15%** (fee tier 0.30% → no arb).
  - WETH/STONE pool: 0.93652 STONE/WETH vs market 0.93504 → **0.16%**; the cheap side holds only 0.0917 STONE ($245) → max extractable <$0.50.
  - All other >2% deviations are in pools whose cheap side is dust (<$110) or which have `liquidity()=0` (untradeable). **Total arb across all 95 pools ≪ $10.**
- **Accrued protocol fees** (`feeProtocol=100` = 100% of swap fee to protocol): $128.85 priced across all pools (0.0294 WETH $73.79 + 51.96 USDC $51.95).
- **Positions:** NFP `totalSupply()=7573`; CI sampled 800 tokenIds (stratified): 95 in WETH/STONE 0.025%, 88 in WETH/0xa25b 0.025%, 42 in WETH/0xf610 0.025%, 18 in 0x01f0/WETH, 4 in WETH/SCR, etc. Sampled owners are ordinary addresses/contracts; `tokensOwed` are tiny. Principal is held against these NFTs.
- **Gauges:** 62 gauges (19 `isAlive`); aggregate balances 3,434,096.93 NURI + 0.001041 WETH ($2.61) + 0 USDC/USDT.
- **FeeDistributors:** 31 FDs hold WETH>0; aggregate **~$3,671** priceable — core WETH/USDC/USDT **$3,282.96** (0.7168 WETH + 1,370.37 USDC + 114.90 USDT), plus SCR/LSTs/DAI/USDe and 9,744 NURI at marginal prices. Largest: `0x52239D…165F` (USDC/WETH gauge) 0.3126 WETH + 950.26 USDC + 175.8 NURI. Deposits with `votes>0` (2024-06 → 2025-08) are claimable only by the veNFTs that voted in those weeks; later deposits into zero-vote periods are stuck (S). The same FD took in 85.58 WETH / 251,420 USDC historically and >99% was claimed by the recorded voters before activity stopped ~9–10 months ago.
- **Roles:** factory `owner` = Safe; `feeSetter` = CommandCenter; `feeCollector` = FeeCollector; `implementation` = `0xDBA1…`. `ProxyAdmin.owner` = Timelock. Safe threshold 1-of-3.
- **NURI token:** 53,297 holders; no DefiLlama price; only real market is a V2 pair with ~0.26 WETH ($654) — dumping 1M NURI yields ≈$357 (child C).

---

## 4. What an attacker can and cannot do — exact paths

### Closed paths (each verified by a passing fork test or a live `eth_call` simulation)

| Path | Live gate | Result |
|---|---|---|
| `ClPoolFactory.setOwner/setImplementation/setFeeCollector/setFeeProtocol/enableFeeAmount` | `require(msg.sender == owner/feeSetter, "AUTH")` | **revert** (`AUTH`) |
| `ClPool.collectProtocol(attacker, max, max)` | `onlyFeeCollector` (`msg.sender == factory.feeCollector()`) | **revert** |
| `ClPool.setFee(uint24)` | `ProtocolActions.setFee` → `msg.sender == factory` | **revert** (`AUTH`) |
| `ClPool.setFeeProtocol()` | permissionless, but only re-syncs `slot0.feeProtocol` from `factory.poolFeeProtocol(pool)` | succeeds, **no state change** |
| `ProxyAdmin.upgrade(factory, attackerImpl)` | `owner == Timelock` (Safe → 24h delay) | **revert** |
| Gauge `getReward(tokenId)` / `getRewardForOwner` | NFT `ownerOf`/`getApproved`; voter/NFP only | **revert** (`Not authorized`) |
| FeeDistributor `getReward`/`getPeriodReward` | `IVotingEscrow.isApprovedOrOwner(msg.sender, tokenId)` | **revert** |
| FeeDistributor `getRewardForOwner` | `msg.sender == voter` | **revert** |
| `FeeCollector.collectProtocolFees(pool)` | **permissionless** — collects pool protocol fees | succeeds; **100% goes to the treasury Safe** (`treasuryFees=10000`); attacker balance unchanged (fork-proven with the real pool and with an attacker-controlled fake pool) |
| Retroactive gauge claims | pool `Position.getCheckpoint` returns 0 for periods before the position's first checkpoint; gauge `periodClaimedAmount` caps claims | recent token earns **0** for past periods (fork-proven) |
| Fake-position reward theft (direct `pool.mint(recipient=NFP, index=…)`) | gauge payout follows `nfpManager.ownerOf(tokenId)`; past periods return 0 | only self-gifting possible (child B) |
| V2 pair `skim()` / self-LP `burn()` | reserves == balances on all 148 sides; `balanceOf(pair)==0` | **0 wei extractable** (child C) |
| NFP `sweepToken/unwrapWETH9/refundETH` | public (Uniswap-standard), recipient = caller | **$0 in the NFP** (0 ETH + 0 of 16 tokens probed); latent only |
| Nuri Minter / NURI token | `!MINTER`, growthCap 0, initializers consumed | no open path (child B) |
| CommandCenter (feeSetter role) | every external fn is `onlyRole(OPERATOR/FEE_SETTER/ADMIN)`; attacker sims revert with missing-role hashes | no unprivileged fee/move path (child A) |
| Ramses V3 Oct-2024 $90K exploit pattern (`veWithdrawnTokenAmountByPeriod`, retro periods, NFT-split re-claims) | not present: per-(period,tokenId,token) `userClaimed`, `require(period <= getPeriod())`, `split/merge` require `!voted` | not applicable (source + live sims, child A) |

### Open path (privileged — **P**, not E-U)

- **Immediate pool-logic upgrade:** `ClPoolFactory.setImplementation(newLogic)` is gated only by `owner` = Safe — **no timelock**. Any single signer of the 1-of-3 Safe can upgrade all 95 pools' logic in one transaction and drain the $116.6k of LP principal. Preconditions: 1 Safe key (or Safe transaction). This is the main residual risk.
- **Proxy upgrades** (factory logic, Voter, NFP, FeeCollector, VotingEscrow): ProxyAdmin → Timelock (minDelay 86400 s), Safe has PROPOSER+EXECUTOR → schedule + execute after 24 h.
- Treasury claims: `FeeCollector.collectProtocolFees(pool)` (permissionless trigger) moves the $128.85 of accrued protocol fees to the Safe.

---

## 5. PoC / fork verification

- Project: `poc/` (Foundry; forge-std vendored). Fork: **Scroll, pinned block 35364505**, public keyless RPC (3-RPC fallback chain in `setUp`).
- Tests: `poc/test/NuriClosedPaths.t.sol` — **10/10 PASS on GitHub Actions**:
  1. `test_pool_prices_track_market` — measured 2506.37 USDC/WETH (0.15% dev), 0.93652 STONE/WETH (0.16% dev).
  2. `test_factory_admin_paths_revert_for_stranger` — 5 admin selectors revert `AUTH`.
  3. `test_pool_protocol_and_fee_paths_revert_for_stranger` — `collectProtocol`/`setFee` revert.
  4. `test_setFeeProtocol_permissionless_but_noop` — permissionless call, value unchanged.
  5. `test_upgrade_path_is_timelocked_admin` — ProxyAdmin owner = Timelock, minDelay 86400, upgrade reverts.
  6. `test_gauge_and_fee_distributor_claims_are_owner_only` — all 3 claim paths revert.
  7. `test_feeCollector_collectProtocolFees_pays_treasury_not_attacker` — treasury receives pf−1 wei; attacker gets 0.
  8. `test_feeCollector_excess_balance_sweep_goes_to_treasury` — fork-funded 1,000 USDC in the FeeCollector is swept 100% to the Safe, attacker gets 0.
  9. `test_fake_pool_cannot_enrich_attacker` — attacker-controlled pool argument yields nothing.
  10. `test_recent_position_cannot_claim_past_period_rewards` — `periodEarned(2835, NURI, recentId) == 0`; pool checkpoint guard returns 0.
- CI runs (public repo `artsbykriss/ca-zombie-ci`):
  - **PoC + enumeration (success):** https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38482194238
  - (first attempt, enumeration hit public-RPC 429 before tests ran — kept for honesty): https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38480988932
- CI enumeration (`ci/enumerate.py`, block 35364740): 800 sampled positions parsed; all 62 gauge balances; `ci-out/summary_enum.json`, `ci-out/nfp_positions.json`, `ci-out/gauge_balances.json`.

---

## 6. Verdict

- **E-U (external unprivileged): $0.00** — high confidence. There is no permissionless path that pays the caller: pool principal is NFT-owned, admin paths revert, the one permissionless money-mover pays the treasury 100%, gauge/FD claims are owner-gated (6/6 live attacker sims revert), and prices are at market (arb <$10, bounded by dust-side liquidity).
- **H-O (holder-recoverable): ≈$116,612** (LP principal + `tokensOwed`), plus **≈$3,671** of unclaimed FeeDistributor rewards (veNFT voters; core $3,283), plus 3.43M NURI gauge rewards (illiquid, realizable ≪ $1k) — all require legacy ownership (NFT/veNFT), which a fresh attacker does not have.
- **P (privileged): $128.85** protocol fees (Safe) + full upgrade authority over ~$116.6k — note the **un-timelocked `setImplementation`** path behind a 1-of-3 Safe.
- **S (stuck): ≈$19** first-order (zero-vote FeeDistributor buckets: 17.81 USDC + 47.08 SCR + 536 NURI in live samples) plus any rewards of burned veNFTs (unquantified); FD has no sweep.
- **Blockers/caveats:** NURI has no meaningful exit liquidity, so NURI-denominated rewards are valued ≈$0; the position census is a stratified 800/7,573 sample (plus per-path simulations); the V2 factory logic is unverified on Scrollscan (behavioural probe only); USD figures use DefiLlama prices at 2026-10-13/14.

---

## 7. Methodology & sources

- On-chain reads (`eth_call`/`eth_getStorageAt`/`eth_getCode`/`eth_getLogs`) via keyless public RPCs (`rpc.scroll.io`, `scroll-rpc.publicnode.com`, `scroll.drpc.org`), blocks 35337420 → 35364740. Verified sources pulled from the public Scroll explorer API (`scrollscan.com/api/v2/smart-contracts/<addr>`).
- Prices: `coins.llama.fi` (WETH $2509.65, USDC $0.99982, STONE $2682.71, SCR, USDT); NURI unpriced.
- Independent child audits (same folder, read-only): `analysis/childA-feedist.md` (fee distribution), `analysis/childB-nfp.md` (NFP/veNURI/Minter), `analysis/childC-v2.md` (V2 AMM + NURI liquidity).
- Historical exploit research: Ramses Exchange Oct-2024 hack (QuillAudits/Verichains/SolidityScan) and Code4rena 2024-10 report — both target **Ramses V3** accounting (`veWithdrawnTokenAmountByPeriod`, GaugeV3 period skips); Nuri's Ramses-V2 FeeDistributor uses per-(period, tokenId) `userVotes/userClaimed` and its split/merge are blocked while voted, so that exploit class does not apply (verified in source + live state).
- Read-only throughout; fork-only PoC on GitHub Actions; no secrets in the public repo.

### Files
```
nuri-cl/
├── README.md                     # this file
├── summary.json                  # machine-readable summary
├── analysis/                     # state dumps, extracted verified sources, child audits
│   ├── live_state.json           # 95-pool balances+prices at block 35364648
│   ├── pool_info.json, pool_fees.json, prices.json, gauges.json
│   ├── sources/                  # pool/factory/gauge/FD/NFP/ve/CommandCenter verified sources
│   ├── sc/                       # raw explorer contract JSONs
│   ├── childA-feedist.md         # fee-distribution audit (child)
│   ├── childB-nfp.md             # NFP/ve/Minter audit (child)
│   └── childC-v2.md              # Nuri V2 census + NURI liquidity (child)
├── poc/                          # Foundry project (10 tests, fork Scroll @35364505)
├── ci/enumerate.py, ci/run.sh    # CI enumeration (800-position sample + gauge balances)
├── ci-out/                       # CI-run outputs (block 35364740)
├── ci-log.txt, ci-artifacts/     # CI log + artifacts
└── ci/                           # CI helper scripts
```
