# Flare/Kava/opBNB small-chain cluster — Tier-3 deep-dive (zombie-hunt II)

**Date:** 2026-10-15 · **Chains:** Songbird (19), Kava EVM (2222), opBNB (204)
**Status:** read-only; PoC fork-verified only; **no mainnet transactions, no keys, no secrets**.
**Targets:** L2-05 Flare Finance / Enosys **EXFI staking** (Songbird) · L2-06 **Hover** (Kava EVM) · L2-07 **Segment Finance** (opBNB)

---

## 1. TL;DR — per target

| # | Target | Verified value today | Live extractable by an external unprivileged attacker | Why closed | Latent risk |
|---|---|---|---|---|---|
| L2-05 | **Enosys Governance Stake Manager — EXFI** (`0xc4D89F8f…`, Songbird) | **$165.5k** held (16,263,923 EXFI = $165.1k + $456 other reward tokens). Staked principal 16,176,444 EXFI ($164.2k); unclaimed EXFI rewards 87,479 ($888) | **$0** (high confidence) | No retro rewards (epoch snapshot is a past block, unreachable retroactively); hints validated; claims pay exactly `bal×rate/1e18/10^(18-dec)` once; notifier/governor/owner paths revert; principal 1:1 | A staker who holds through an epoch's snapshot block earns a pro-rata share — including an attacker who *buys in early and exits after*, but the per-epoch pool is only ~$22 and the snapshot block is unpredictable from public state; dilution-only, capital-bound |
| L2-05b | **Enosys Governance Stake Manager — SFIN** (`0xA83E9033…`, same impl) | **$490.9k** held: 5,945.18 SFIN principal ($487.6k) + 313,828 EXFI unclaimed rewards ($3.19k) + 134,074 WSGB ($116) | **$0** (high confidence) | identical code/impl `0xB0E4D5ba…`, identical gates (test T6/L6) | same snapshot dilution note; EXFI-reward pool there ($3.19k) is the larger prize for any *future* accounting bug |
| L2-05c | **FarmingPool EXFI→SFIN** (`0xb78ebd4b…`, expired 2025-01-03) | 262,315 EXFI staked ($2,662) + 0.635 SFIN unclaimed ($52) | **$0** (high confidence) | `stakeFor`/`withdrawFor`/`withdrawAndGetRewardFor` are `onlyAllowedCaller`; `rescue*` owner-only; period finished → no new rewards; stakers withdraw their own principal 1:1 | none identified (principal is H-O) |
| L2-06 | **Hover** (Kava EVM) | cash $685-ish equivalent; total claims ~$2.3k nominal; 2 underwater positions (collateral $2,872 / shortfall $10,126) | **$0** (high confidence) | mint **and** borrow globally paused (`MP`/`BP`); liquidations **allowlisted to 2 protocol bots**; oracle (Pyth) **stale → `StalePrice()` reverts everywhere**; admin behind 2-of-8 Safe; all allowances 0 | If Pyth is refreshed *and* the bot allowlist were bypassed *and* mint/borrow unpaused → classic Compound-fork surface (~$137 liquidation bonus window for bots only). Tripwires listed in `children/hover/README.md` |
| L2-07 | **Segment Finance** (opBNB) | 5 markets; cash $685.33 + borrows $4,936.23 = **$5,621.56** claims | **$0** (high confidence) | **prices revert for everyone**: all 5 `getUnderlyingPrice` → `invalid resilient oracle price`; root cause `binance oracle price expired` (registry rounds ~29 h old vs `maxStalePeriod` 24 h); borrow/liquidate/`getAccountLiquidity` revert; only bad-debt (733.26 USDT + ~$5 dust) remains → liquidating loses money; no SEF rewards | **Sharpened 2026-10-15:** the team has partially revived the oracle (feeds now registered for USDT/FDUSD/ETH/BNB with real answers ~$0.999/$0.998/$2,503/$741, `maxStalePeriod` 0→86400; BTCB still has no feed). Config/revival paths remain owner/AccessControl-gated, but a fresh round push (feeder, unresolved whether permissioned) would re-open borrows/liquidations with *real* prices — still no profitable path (bad debt only), so E-U stays ~$0 while the $685 cash + $2.9k collateral unfreeze (H-O) |

## 2. Total live extractable now

**$0.00** across all three targets (confidence: **high** for all three).

Nominal value present: **≈ $667k** (EXFI manager $165.5k + SFIN manager $490.9k + FarmingPool $2.7k + Hover $2.3k + Segment $5.6k), of which **$651.8k is staker principal (H-O, self-service withdrawals)** and ~$4.1k is unclaimed rewards that only their owners can claim.

No category E-U path survived adversarial testing; the only live payouts are (a) each staker's own principal and (b) pro-rata epoch rewards to whoever held stake at the epoch's snapshot block.

---

## 3. L2-05 — Enosys EXFI governance staking, in exact terms

### 3.1 What the contract is (corrected from the lead)

The lead ("16.19M EXFI + 262k rewards, user-scoped") conflated three contracts. Verified mapping:

| Contract | Role | Impl | Held today |
|---|---|---|---|
| `0xc4D89F8f593F215f3636793E3353A36C196Cf87A` | **EnosysGovernanceStakeManagerExfi** (TransparentUpgradeableProxy, admin `0xEE8Cc71c…`) | `0xB0E4D5baB93B0a7a6A99b7AFCfb50501d8B19772` (unverified) | 16,263,923 EXFI ($165.1k) + WSGB/SFIN/exXDC/FXRP/exETH/exUSDT rewards |
| `0xA83E90337e2711b1c84df0AD7428403dBd0ce730` | **EnosysGovernanceStakeManagerSfin** (same impl) | `0xB0E4D5ba…` (same) | 5,945.18 SFIN ($487.6k) + **313,828 EXFI ($3.19k)** + 134,074 WSGB |
| `0xb78ebd4b13a2202068618bf98f952c0271159107` | **FarmingPool EXFI→SFIN** (verified source, proxy→`0x2Aa2a34f…`), `periodFinish` 2025-01-03 | 262,315 EXFI ($2,662) staked + 0.635 SFIN unclaimed |

Design (from live ABI + bytecode + docs): stake EXFI (or SFIN) → 24-hour epochs (`DURATION=86400`, `ZERO_EPOCH_START=1759406400`) → the APYCloud keeper registers each epoch's fee income (`updateRewardAmountByToken`) → stakers claim their share with `claimRewards()`.

**Verified payout formula** (exact, live):
`unclaimed(user, token) = Σ_epochs balanceOfEpoch(user,e) × epochRewardRate(e,token) / 1e18 / 10^(18−decimals(token))`
`balanceOfEpoch(user,e) = getBalanceAt(user, epochSnapshotBlock(e))` (checkpoint binary search, veCRV-style).

Live verification: for 3 real stakers (one lagging, two caught-up) + a fresh address, the on-chain `getAllUnclaimedRewards` equals the formula sum **exactly**, for all 8 reward tokens (`ci/run.sh`, `FORMULA_IDENTITY PASS`, block 135,447,xxx).

### 3.2 Adversarial tests and results

| Path | Test | Result |
|---|---|---|
| Claim rewards for epochs before staking (retro capture) | Fresh account: `balanceOfEpoch(e)=0` for e ∈ {0,1,10,100,200,300,current-1}; `getAllUnclaimedRewards=0`; `claimRewards()` reverts `No any rewards` | **CLOSED** (live + local bytecode test L1) |
| Hint abuse (`stakeWithHint(amount,balanceHint)` with bogus hints) to corrupt checkpoints | Oversized hint reverts `Balance hint is larger than expected value`; undersized hint accepted but the binary search self-corrects — checkpoints stay block-sorted, past epochs stay 0, balance ≤ deposits | **CLOSED** (local bytecode test L3) |
| Claim twice / claim inflation | `claimRewards` pays exactly the formula once; second call reverts `At least one epoch has not passed` | **CLOSED** (L2) |
| Forge rewards (`updateRewardAmountByToken`) | Reverts `Not allowed reward notifier` for anyone but `apyCloud` (`0xb8d1c66a…`, read via raw selector `0xa5032f3c`) | **CLOSED** (live + L4) |
| Governor paths (`addVoting`/`updateVoting`) | Revert `Not a governor` | **CLOSED** (live + L4) |
| Owner paths (`updateApyCloudVault`, `updateRewardTokensAdd/Remove`, `updateGovernor`, `updateTotalSupplyAggregationRange`, `rescue`) | Revert `Ownable: caller is not the owner` (owner = EOA `0x28591A8d…`) | **CLOSED** |
| Fee/pending-fee theft (`withdrawReturnedFees(bool)`) | Reverts `No pending fees` for a fresh account; pending fees are only created by governor `addVoting` (gated) | **CLOSED** |
| Permissionless epoch-total finaliser (`updateTotalSupplyByEpochIfNeeded(e)`) | Callable for settled epochs but **idempotent**: returns exactly the stored `totalSupplyByEpoch(e)` for epochs 370–376 (live, `ci/run.sh`); reverts for current/next epoch | **CLOSED** (no manipulation) |
| Permissionless distribution trigger (vault `triggerDistribution(bool)`) | Callable by a fresh EOA at an epoch rollover but moves only real fees to all stakers pro-rata (local test T5, fairness bound) | **STERILE** |
| Principal theft | `withdraw(amount>balance)` reverts; 1:1 transfer out; manager EXFI ≥ totalSupply always | **CLOSED** (L5) |
| Snapshot dilution (flash-stake one epoch) | A staker must hold at `epochSnapshotBlock(e)` — a **past block with no interaction at it** (live: e377 snapshot `135,308,151`, an empty-interaction block inside `epochInterval(377)=[135,287,584,135,336,697]`) → momentary (same-block) balances never count; flash-stake is impossible; only "hold through an unknown mid-epoch block" works | **Only dilution, capital-bound** (see §3.3) |

### 3.3 Residual/latent risk (quantified)

- Per-epoch reward pool (live, epoch 376 registration): **2,189.23 EXFI ($22.22) + 61.05 WSGB ($0.05) + dust**. An attacker who *knows the snapshot rule* could try to hold a large balance only at the snapshot block; but the snapshot block is only revealed after the epoch (it is stored at the next epoch's first interaction) and is not derivable from public state without the (unverified) source, so in practice the attacker must hold for a whole epoch.
- To capture, say, 50 % of one epoch's rewards the attacker needs ≈ half of TVL (8.1M EXFI ≈ $82k) held across the snapshot block → ≈ $11 of rewards per epoch. Not economically meaningful; **no principal risk**.
- The unclaimed-reward pools ($888 in the EXFI manager, $3,185 in the SFIN manager) are the prize for any *future* accounting bug in this unverified implementation; the epoch/checkpoint/hint code is custom and not covered by the frontend ABI. Monitor for implementation upgrades (admin `0xEE8Cc71c…`).
- `withdrawReturnedFees(bool)` (permissionless, pays "returned voting fees") is a future-risk surface if the governor/voting-fee logic ever mints pending fees to arbitrary users — currently impossible (governor-gated).

---

## 4. L2-06 — Hover (Kava EVM), condensed

Full evidence: `children/hover/README.md`, `children/hover/state.json`, `children/hover/borrowers.csv` (all 160 borrowers from 13,453 hKAVA + 1,303 hATOM + 17,205 hUSDT Borrow events), `children/hover/oracle.md`.

- Comptroller `0x3A4Ec955a18eF6eB33025599505E7d404a4d59eC` (Unitroller), oracle `0xE8Ae943de7f036Cfa505127641Eee7c5b6606878` (Pyth-based), admin = 2-of-8 Gnosis Safe `0xcecC934494adED6c0c82C52656a845862176ceeE`.
- **mint + borrow paused per market**: `mintGuardianPaused[hKAVA|hATOM|hUSDT] = true`, `borrowGuardianPaused[...] = true` → `hUSDT.mint(1e6)` reverts `MP`, `borrow` reverts `BP` (block 23,034,510).
- **Liquidation allowlist**: `liquidateBorrowAllowed(hUSDT,hKAVA,0x1111…,borrower,1e6) → 1 (UNAUTHORIZED)`; the allowlist holds exactly 2 protocol bot addresses; `allow()` owner-only (block 23,035,488).
- **Oracle stale & failing closed**: all `getUnderlyingPrice()` revert `StalePrice()`; Pyth `publishTime` ≈ 2026-03-29 (≈200 days stale). Bots hit the same wall; historical bot profits were routed to the team's `profitWallet`, not the caller.
- Max theoretical liquidation bonus for the 2 underwater positions: **$136.77 gross**, bot-only, and it requires an oracle refresh first → **$0 for outsiders**.
- Donation/empty-market, force-feed, redeem, `seize`, reward-claim, reserve/sweep paths: all closed (12-path table in the child README).

## 5. L2-07 — Segment Finance (opBNB), condensed

Full evidence: `children/segment/README.md`, `children/segment/state.json`, `children/segment/borrowers.csv`, `children/segment/oracle.md`.

- Comptroller `0x71ac0e9A7113130280040d0189d0556f45a8CBB5` (5 markets: seFDUSD/seUSDT/seETH/seBTC/seBNB), oracle `0xAacf634DD705D37e94C38EA68384e669D2b4d491`, admin = 2-of-3 Safe `0x1f41cFbBF95baC4F5A220700f78DbAa1E34B97D1` (block 195,783,829).
- **All five prices revert today**: `getUnderlyingPrice(any seToken)` reverts `invalid resilient oracle price`; chain `ResilientOracle → 0x15cB42A8… BinanceOracle → FeedRegistry 0x72d55658…`. `BinanceOracle.getPrice(...)` reverts `binance oracle price expired`.
- **Live change detected during this deep-dive (blocks ~195.76M → ~195.80M):** the team has been re-configuring the oracle — feeds are now *registered* for USDT/FDUSD/ETH/BNB (answers $0.99899909 / $0.99810609 / $2,503.31 / $740.96, 8-dec) and `maxStalePeriod` is now **86400** (was 0). The rounds are ~29 h old, i.e. **stale by ~5 h** → every price still reverts. **BTCB has no feed** → seBTC stays unpriceable regardless.
- **No unprivileged revival** (verified): `setMaxStalePeriod`, `setSymbolOverride`, `ResilientOracle.setTokenConfig/pause`, `FeedRegistry.proposeFeed/confirmFeed`, `transferOwnership` all revert (AccessControl `0x4a3fa293` / `Ownable` / `Only callable by owner`). The BinanceOracle implementation (`0x8769277379fbb80e28666238e98f67ebbdb4fff7`) exposes only 15 selectors — config + `getPrice`, **no round-submission entry point**; the round-push path lives in the registry's feed adapters (not resolved — flagged as residual unknown).
- `borrow`, `liquidateBorrow`, `getAccountLiquidity` revert for every caller → the classic Compound-fork surface is frozen. Only bad debt remains: **733.26 USDT** (`0x68a01870…`, ~0 collateral) + ~$5 dust → liquidation is a loss. Non-member `redeem` works → the ~$685 cash is **H-O** (market members), not attacker-extractable. Last functional day: 2026-05-19. Reward token `SEF` is not deployed; `claimSegment` is a no-op.

---

## 6. PoC / verification

### 6.1 Deterministic bytecode-level PoC for the EXFI manager (runs in CI)

The Songbird public RPC keeps only ~3 blocks of state (`eth_getStorageAt` at `latest-5` already fails), so a *live* fork is impossible. Instead the **exact deployed implementation runtime bytecode** (`0xB0E4D5ba…`, fetched read-only) is etched into a local EVM and initialised, giving full state-changing coverage of the live logic:

`poc/test/ExfiStakeManagerLocal.t.sol` — **5/5 PASS**:
- `test_L1_no_retro_capture` — fresh staker gets zero for every pre-stake epoch; claim reverts `No any rewards`
- `test_L2_fair_payout_exact_formula` — end-to-end reward registration + claim: payout == formula exactly, second claim reverts, second user paid
- `test_L3_hint_abuse_no_corruption` — oversized hint reverts; undersized hint cannot corrupt checkpoints (sorted, past epochs 0, balance ≤ deposits)
- `test_L4_gating` — notifier/owner/pending-fee paths revert for unprivileged caller
- `test_L5_principal_and_permissionless_update` — no over-withdraw; permissionless epoch-total finaliser callable for settled epochs, rejected for current/next

Harness notes (honest limits): the local chain pins `epochSnapshotBlock` (slot 159) and `totalSupplyByEpoch` (slot 164) with `vm.store` to the values the live chain would hold — slots verified against live state (`epochSnapshotBlock(376)=135,239,270`). The live equivalents of every gate are additionally asserted read-only in `ci/run.sh` (21/21 PASS).

### 6.2 Live read-only evidence job (`ci/run.sh`) — 21/21 PASS

- fresh-account probes (7 epochs), `canClaimRewards=false`, unclaimed all-zero
- **formula identity** on 3 real stakers + fresh account across all 8 reward tokens (batched JSON-RPC)
- gating reverts for `updateRewardAmountByToken`, `addVoting`, `updateApyCloudVault`, `updateRewardTokensAdd`, `updateGovernor`, `updateTotalSupplyAggregationRange`, `withdrawReturnedFees`, fresh `claimRewards`
- permissionless epoch-total finaliser idempotency + current-epoch rejection
- FarmingPool `withdrawFor` (`StaticPool: Not allowed caller`) and `rescueUnclaimedTokens` owner-gate
- full state dump → `ci-out/exfi-state.json`

### 6.3 Fork tripwire suites for Hover / Segment (ran green in CI)

`poc/test/HoverFork.t.sol` (9 tests) and `poc/test/SegmentFork.t.sol` (13 tests) ran **green** in the final CI run against the public Kava/opBNB RPCs (the state windows held). They are designed as live tripwires: e.g., the Segment suite asserts the invariant that keeps prices dead — for each symbol, either no feed exists (`BTCB`), or the registry denies the caller, or `block.timestamp > updatedAt + maxStalePeriod`; a fresh round would make it fail loudly (which is the point). All assertions were additionally pre-verified by live `eth_call` (exact calls/blocks/reverts in the child READMEs).

### 6.4 CI runs (all green, final)

- **Final run:** https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38737040250 — `27/27` PoC tests PASS (ExfiStakeManagerLocal 5, HoverFork 9, SegmentFork 13) and `21/21` live read-only checks PASS; artifact `ci-out/exfi-state.json` (valid JSON, block 135,454,111) downloaded to `ci-artifacts/`.
- Earlier runs (same branch): 38736086700 (26/27 — one Segment tripwire asserting the pre-revival oracle config), 38734333811 (25/27 — pre-fix checks).
- Workflow: `poc.yml` on `artsbykriss/ca-zombie-ci`, branch `flare-kava-small`; log at `ci-log.txt`.

### 6.5 Independent verification (second agent, adversarial)

A separate verification agent (`children/exfi-verify/`) was tasked to **falsify** the $0 verdict. Result: **CONFIRMED, no falsification found** (`children/exfi-verify/VERIFY.md`, `summary.json`, `probes.json`). Highlights (its own live reads, blocks 135,453,827–135,455,804):
- payout identity re-derived from scratch and matched **exactly per epoch** for 3 of its own stakers across all 8 tokens (an exact-then-floor variant is off by +1…+5 base units, proving the per-epoch truncation order);
- `withdrawTo`/`withdrawToAndGetReward*`/`exit` from a non-owner always revert `Cannot withdraw, exceed the balance` / `Amount is zero` — funds are only ever drawn from `msg.sender`;
- simulated claims pay exactly the `getAllUnclaimedRewards` array, cursor advances, second claim reverts;
- `updateTotalSupplyByEpochIfNeeded` returns the stored value **and leaves storage unchanged** (in-call read-after-write, epochs 376/375/373);
- `stakeToWithHint(amount, third_party)` = donation only (caller pays, no old-epoch credit);
- full fresh-account sweep (19 write calls, then all 8 token balances in the same `eth_call`): **all zero**;
- **FarmingPool correction:** the real `allowedCaller` entries are two **EOAs** (`0x9EbF9637…8c72`, `0x43fc122D…4A07`; exactly 2 `UpdateAllowedCaller` events ever) — no contract pass-through exists, so no third-party-withdraw risk.

Residual gap (both agents agree): the stake-manager implementation is **unverified**, so a novel bug outside the exercised call graph cannot be excluded by black-box probing; monitor the proxy admin `0xEE8Cc71c…` for upgrades. (Also: the folder was deleted externally mid-verification and restored from the CI snapshot; all numbers were re-checked against the chain.)

---

## 7. Verdict

**Nothing in this cluster is extractable by an external unprivileged attacker today: E-U = $0.00 (high confidence).**
- EXFI/SFIN governance staking: rewards are correctly epoch-scoped and checkpoint-verified; all value-moving paths are gated; principal is 1:1. Category: principal = **H-O** (each staker's own), unclaimed rewards = **H-O**, admin/fee paths = **P**, nothing **S** (withdrawals work).
- Hover: paused + allowlisted + stale-oracle-fails-closed. Category: cash/claims = **H-O**; admin = **P**.
- Segment: oracle dead → frozen; only bad debt remains. Category: cash = **H-O**; admin/oracle = **P**; some positions = **S** (no profitable exit/liquidation).

## 8. Methodology & sources

- Live state read at explicit blocks: Songbird 135,442,983 → 135,447,xxx; Kava 23,034,510 / 23,035,488; opBNB 195,761,245 → 195,783,829.
- ABI recovery: frontend bundle of `gov.enosys.global` (full manager ABI, 80 functions), bytecode selector scan + OpenChain/4byte lookups, heimdall-rs 0.8.4 decompilation of the implementation, verified `FarmingPool` source from the Songbird explorer.
- Contract map cross-checked against `Thanasimos/Thanas-flare-builders-toolkit` (`enosys-contracts` skill references).
- Prices: CoinGecko (EXFI $0.010150, WSGB/SGB $0.000863, SFIN $82.02, FXRP $1.31, exETH $2,364, USDT $0.999, XDC ≈ $0.03) at 2026-10-15.
- Campaign context: `zombie_hunt/ZOMBIE-HUNT-II.md` (L2-05/06/07), `ci/SUBAGENT-BRIEF.md`.

**Caveats:** (1) the stake-manager implementation is unverified; conclusions rest on the recovered ABI, decompilation, bytecode-level tests and live call behaviour. (2) The exact `epochSnapshotBlock` derivation was not fully reverse-engineered; all observed values are non-interaction blocks inside the epoch's stake/withdraw interval, which is what matters for the no-flash-stake argument. (3) Songbird/Kava/opBNB public RPCs prune state, so live fork tests are unreliable; the bytecode-level suite + live read-only assertions substitute for them. (4) USD values move with prices; token amounts are exact.

## 9. Files index

```
flare-kava-small/
├── README.md                      ← this file (deliverable)
├── summary.json                   ← machine-readable summary
├── ci/run.sh                      ← live read-only evidence job (21 checks) + state dump
├── ci-log.txt, ci-artifacts/      ← CI logs/artifacts
├── ci-out/exfi-state.json         ← CI state dump
├── poc/
│   ├── foundry.toml, exfi_impl_bytecode.hex
│   └── test/ExfiStakeManagerLocal.t.sol   (5/5 PASS, exact deployed bytecode)
│   └── test/HoverFork.t.sol, SegmentFork.t.sol (tripwires; live-verified assertions)
├── analysis/                      ← ABI, selectors, decompilation, epoch/snapshot data, prices, enosys refs
│   ├── stake_manager_abi.json, sel_A.txt, impl_hex.txt, farmingpool_src.sol, fp_impl_src.sol
│   ├── govjs/ (frontend bundle + extracted ABI), enosys_refs/ (address tables)
│   └── *_logs.json, epochSnapshot analysis, price table
└── children/
    ├── hover/    README.md, state.json, state.md, borrowers.csv, oracle.md, summary.json, test/HoverFork.t.sol, analysis/
    └── segment/  README.md, state.json, state.md, borrowers.csv, oracle.md, summary.json, test/SegmentFork.t.sol, analysis/
```
