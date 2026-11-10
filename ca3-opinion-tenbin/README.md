# CA3 — OPINION (BNB) + Tenbin Labs (Ethereum): live unprivileged extraction assessment

**Date:** 2026-11-10 · **Chains:** BNB Smart Chain (56), Ethereum (1) · **Status:** READ-ONLY.
No mainnet transaction was signed or sent. All chain reads are `eth_call` / `eth_getLogs` /
`eth_getStorageAt` at the stated blocks; exploit mechanics were exercised only on local forks
inside GitHub Actions.

**Headline: both targets are locatable, and both are closed to an external unprivileged
attacker. Live extractable now (E-U) = $0.00.** The residual value is either privileged
(P) or conditional on a privileged party failing/colluding (E-U-conditional), and in
OPINION's case the conditional path has strongly negative expected value.

---

## 1. TL;DR

| # | Target | Live E-U (unprivileged) | Why closed | Latent / conditional risk |
|---:|---|---:|---|---|
| 1 | **OPINION** (BNB) — Pashov **L-06** dispute timeout favors disputor | **$0.00** | `timeoutDispute()` is `OPERATOR_ROLE`-gated (EOA `0xBE39…c14e`); the disputor cannot trigger it. `resolve()` is gated to the ResolutionMultiSig contract `0x95ee…9e91`. The disputor's "win" needs a privileged timeout. | E-U-conditional up to **$2,621.00** (72 × 1,000 OPN) only if the committee fails **and** the operator calls the timeout; break-even timeout probability is 50%, observed 0/61 → EV ≈ **−$32.82** per spurious dispute. P-class collusion (committee member + disputor) can capture the same $2,621. |
| 2 | **Tenbin Labs** (Ethereum) — Zellic **3.2** revenue drain, **3.3** Morpho adapter inflation | **$0.00** | 3.2's `RevenueModule.collect()` is `REVENUE_KEEPER_ROLE`-gated (protocol EOA) and `CollateralManager.withdrawRevenue()` is `onlyRevenueModule`; verified by revert. 3.3's audited `MorphoVaultV1Adapter` is **not in the live adapter set**; live allocations go through `GenericMorphoAdapter` into **Steakhouse Prime USDC** ($139.17M TVL), where the required donation to zero a $447k allocation is **$5.99e31**. | 3.2 P-value ≈ **$23.28** today (min of unrealized revenue $35.93 and liquid USDC $203.63); over time the keeper can classify unrealized vault gains as revenue and pay them from principal. 3.3 requires the admin to point the adapter at an unsafe ERC-4626 vault *and* an allocation afterwards; not the live configuration. |

**Total live extractable now (external, unprivileged): $0.00** — confidence **high** for the
direct paths, **medium** for the conditional bounds (they depend on privileged-party behavior).

---

## 2. Total live extractable now

| Category | OPINION | Tenbin | Total |
|---|---:|---:|---:|
| **E-U** (external unprivileged, unconditional) | **$0.00** | **$0.00** | **$0.00** |
| **E-U-conditional** (requires a privileged failure/collusion) | $2,621.00 | $0.00 | $2,621.00 |
| **H-O** (holder/user self-service only) | $0.00 | $0.00 | $0.00 |
| **P** (privileged/governance only) | $72.81 (v4 residual) + up to $2,621.00 (operator/committee) | $23.28 now (keeper) | $2,717.09 |
| **S** (stuck/bricked) | $0.00 | $0.00 | $0.00 |

The headline **E-U is $0.00**. The $2,621.00 is not attacker-reachable without the
`OPERATOR_ROLE` EOA (or committee collusion); it is a P/liveness condition, not a bug an
unprivileged actor can drive.

---

## 3. Target 1 — OPINION (BNB Smart Chain)

### 3.1 The finding in exact terms

Pashov Audit Group, *Opinion* security review, 2026-03-24
(`pashov/audits/team/md/Opinion-security-review_2026-03-24.md`), scope
`DisputeResolver.sol` at `OpinionLabs/centauri@cd92a6c…` (fixes review `872af105…`).

**[L-06] Dispute timeouts always favor the disputor** — Impact **High**, Likelihood **Low**,
status **_Acknowledged_**.

`timeoutDispute()` → `_timeoutDispute()` sets `res.disputeSucceeded = true` unconditionally
when the re-vote window expires. `claim()` then pays the disputor
`stakedAmount + rewardAmount` = **2× the reward**. The auditor's concrete path is a disputor
who is also a committee member (or colludes with one) and blocks the re-vote from reaching
an executable `Approved` state; the timeout then pays the invalid dispute. The team
acknowledged it as an intentional liveness incentive.

The live implementation matches this exactly. The audited v4 source
(`0x153797a3…34ac`, verified, Solidity 0.8.20, `VERSION = "4.0.0"`) has:

```solidity
function timeoutDispute(bytes32 questionId) external onlyRole(OPERATOR_ROLE) nonReentrant whenNotPaused {
    _timeoutDispute(questionId);
}
...
function _timeoutDispute(bytes32 questionId) internal {
    ...
    if (block.timestamp < res.reVoteDeadline) revert ReVoteWindowOpen(questionId, res.reVoteDeadline);
    res.status = DisputeStatus.TooEarly;
    res.disputeSucceeded = true;
    ...
}
```

### 3.2 How the "unpublished" deployment was located

The audit report and the DefiLlama adapter do not name the resolver, but the deployment is
public in three places:

1. **DefiLlama `sumTokens.js`** registry entry `opinion`:
   - chain `bsc`, `owners = [0xAD1a38cEc043e70E83a3eC30443dB285ED10D774]`, token `USDT`.
   - `getsourcecode` on BSC: **`ConditionalTokens`** (Gnosis CTF, v0.5.10, verified) — the
     market collateral holder, not the resolver.
2. **`app.opinion.trade` Next.js bundle** (chunk `1587-11b6bd1263557ffe.js`) contains the
   BSC mainnet config:
   ```js
   [BSC_MAINNET]: {
     ConditionalTokenAddr: "0xAD1a38cEc043e70E83a3eC30443dB285ED10D774", // matches DefiLlama
     GnosisSafeWallte:      "0x8CBe095a9B7282Aa4Bfc1Ff64caeFFDD303F8ec3",
     FeeManager:            "0xc9063dc52deefb518e5b6634a6b8d624bc5d7c36",
     DisputeResolvers: { committee: "0x5E09dab0CC6f952c715919a1AbCe81AF918a5985",
                         auto:      "0xE19B1645ef54D703b5Ee6DFB7EdF91DEcAae64A4" }
   }
   ```
   A second (staging) stage lists `0x4CCF…590B` / `0x291c…6069` / `0x78A0…d5D6`; the stage
   whose `ConditionalTokenAddr` matches DefiLlama's owner is the production one above.
3. **BscScan `getsourcecode`** on both resolvers: `ERC1967Proxy`; EIP-1967 impl slot
   `0x3608…2bbc` gives:
   - committee `0x5E09…5985` → impl **`0x153797a3…34ac`** = verified `DisputeResolver`
     `VERSION 4.0.0` (the audited code).
   - auto `0xE19B…64A4` → impl **`0xe0f9f92a…0c5c`** = unverified, 18,914 bytes,
     `VERSION 5.0.0` (newer variant).

### 3.3 Live state (BSC block 132,687,070; snapshot block 132,686,514)

| Item | Value |
|---|---|
| **v5 auto resolver (active)** | `0xE19B1645ef54D703b5Ee6DFB7EdF91DEcAae64A4` (impl `0xe0f9f92a20402611f95b68352a7783f430060c5c`), `VERSION 5.0.0`, `paused = false` |
| **v4 committee resolver (idle)** | `0x5E09dab0CC6f952c715919a1AbCe81AF918a5985` (impl `0x153797a30fa330e87902e9ac4286d03f624834ac`), `VERSION 4.0.0`, `paused = false`, `getActiveQuestionIds().length = 0` |
| v5 `OPERATOR_ROLE` holder | `0xBE39f18621a478354BcA521D89B71770085Fc14e` — **EOA**, nonce 130,241, 0.0339 BNB (`hasRole = true`) |
| v5 `resolve()` authorized address | `0x95eea6b2a441dd720177ddd365a113f8b4129e91` — a **custom ResolutionMultiSig** contract (`VERSION 1.3.0`, `admin() = 0x074A4acF…2655`, `proposals(uint256)`), recovered from the revert payload `0xfff7d58e(caller, 0x95ee…)` |
| v5 OPN balance (reward pools) | **72,000 OPN** = **$2,621.00** at OPN `$0.036402718` (DefiLlama, 2026-11-10) |
| v4 OPN balance (residual) | **2,000 OPN** = **$72.81** |
| Active questions | **72**, all `status = 0 (Pending)`; 71 still inside the dispute window at snapshot; per-question reward **1,000 OPN**; total reward pool **72,000 OPN** |
| Dispute window | ~6 h per question (`disputeDeadline − receivedAt ≈ 21,618 s`); re-vote window 24 h (`globalReVoteWindow = 86400` on v4; v5 per-question config) |
| CTF collateral | `0xAD1a38cEc043e70E83a3eC30443dB285ED10D774` holds **2,753,274.36 USDT** (18 dec) ≈ **$2.753M** — market collateral, **not** in the resolver |
| Event history (132,650,000→132,685,435) | 63 `ResolutionReceived`, 61 `ResolutionFinalized`, 63 `RewardDeposited`, **0 `DisputeFiled`**, **0 `DisputeTimedOut`**, **0 `StakeClaimed`** |

The v5 `getResolution` storage layout was recovered on-chain: `_resolutions` mapping slot
`0x161`; fields match v4 (questionId, original[2], final[2], status+reason, receivedAt,
disputeDeadline, reVoteDeadline, disputor, stakeToken, rewardAmount, stakedAmount, claimed,
disputeSucceeded).

### 3.4 The permissionless boundary (what an attacker can and cannot do)

| Function | Gate | Unprivileged? | Evidence |
|---|---|---|---|
| `dispute(bytes32,uint8)` | none (requires stake = reward, `rewardAmount > 0`, inside window) | **YES** | `eth_call` from `0x1111…` returns `ResolutionNotFound` on a missing id, not an auth error; fork test succeeds |
| `claim(bytes32)` | none, but only after a terminal status; if `disputeSucceeded`, only the disputor | **YES (call), value only to disputor/treasury** | fork test; `claim` on Pending → `InvalidStatus` |
| `timeoutDispute(bytes32)` | `onlyRole(OPERATOR_ROLE)` | **NO** | `eth_call --from 0x1111…` → `AccessControlUnauthorizedAccount(0x1111…, 0x9766…b929)`; fork test |
| `finalize(bytes32)` | `onlyRole(OPERATOR_ROLE)` | **NO** | same revert |
| `resolve(bytes32,uint256[])` | `msg.sender == 0x95ee…9e91` (ResolutionMultiSig) | **NO** | storage-override `eth_call` on a Disputed resolution → `0xfff7d58e(caller, 0x95ee…9e91)` for attacker, random and operator; fork test from test contract and from the disputor both fail |
| `depositRewardPool` / `withdrawRewardPool` | `REWARD_MANAGER_ROLE` | **NO** | `AccessControlUnauthorizedAccount(0x1111…, 0x0f51…f94d)` |
| `pause` / `unpause` | `OPERATOR_ROLE` | **NO** | source + role |
| `upgradeTo` | `DEFAULT_ADMIN_ROLE` | **NO** | UUPS `_authorizeUpgrade` |

**The exact L-06 path and why it is not E-U:**

1. Attacker calls `dispute(q, WrongResult)` before `disputeDeadline`, locking 1,000 OPN
   ($36.40). This is permissionless.
2. The committee (ResolutionMultiSig `0x95ee…`) must fail to submit `resolve(q, …)` within
   the 24 h re-vote window. **The attacker cannot prevent this** — `resolve` is gated to the
   Safe-like contract, and the committee has processed 61/63 resolutions in the observed
   window (~15/hour, 72 disputes is within its demonstrated throughput).
3. The operator EOA `0xBE39…` must then call `timeoutDispute(q)`. **The attacker cannot
   call it.** If the operator never calls, the question stays `Disputed` and the stake is
   locked (S for that question) — the attacker loses.
4. Only then does `disputeSucceeded = true`, and `claim` pays 2,000 OPN. Net to the attacker
   = **+1,000 OPN = $36.40**.

**Economics (why this is not a rational attack):** each spurious dispute risks the full
$36.40 stake. Break-even timeout probability is **50%**. The observed timeout rate is
**0/61 = 0%** (95% upper bound ≈ 4.9%, rule of three). At p = 4.9%, EV per dispute =
0.049 × $36.40 − 0.951 × $36.40 = **−$32.82**. Disputing all 72 questions would lock
**$2,621** of capital for 24 h for an expected loss of roughly **−$2,360**. The only
positive-EV variant is insider collusion (a committee member deliberately blocking the
re-vote) — P-class, not E-U.

### 3.5 Quantification

- **E-U: $0.00** (high confidence — role gates verified by `eth_call` revert reasons and a
  fork test; the disputor cannot trigger the timeout).
- **E-U-conditional: $2,621.00** (the full 72 × 1,000 OPN reward pool) — requires committee
  failure **and** the operator's `timeoutDispute` call; not attacker-controlled, negative EV
  at observed liveness. Confidence **medium** (the bound is exact; the probability is an
  estimate).
- **P: $2,693.80** (v4 residual $72.81 + v5 operator/committee $2,621.00).
- **S: $0.00** (a never-timed-out `Disputed` question would lock the disputor's own stake;
  no third-party funds are stuck).
- The **$2.753M CTF collateral is not reachable through L-06**. L-06 only moves the
  resolver's OPN reward pool; the CTF pays out according to the final payouts, which the
  committee/operator controls.

---

## 4. Target 2 — Tenbin Labs (Ethereum)

### 4.1 The findings in exact terms

Zellic, *Core Contracts*, 2026-04-22
(`Zellic/publications/Core Contracts - Zellic Audit Report.pdf`), scope
`tenbinlabs/tenbin-contracts@820e700…`.

- **3.2 High — Revenue collection can drain CollateralManager principal using unrealized
  vault gains.** `RevenueModule.collect()` (gated `REVENUE_KEEPER_ROLE`) →
  `CollateralManager.withdrawRevenue()` (gated `onlyRevenueModule`) pays the requested
  amount from the manager's **liquid** balance, while `_getRevenue()` counts
  `vault.convertToAssets(vault.balanceOf(manager))` appreciation as revenue even when it is
  still unrealized. If the gain later reverses, the protocol has paid out principal.
- **3.3 High — MorphoVaultV1Adapter can lose allocated assets when used with arbitrary
  ERC-4626 vaults.** The adapter's constructor only checks that the target vault's `asset()`
  matches; it does not enforce Morpho V1 inflation protection. An attacker can seed/donate
  to an unsafe target vault so the adapter's `deposit()` mints ~0 shares; the parent vault
  records no claim and the attacker redeems the donation + allocation.

The team acknowledged both without a code fix (3.2: "not currently prepared for an upgrade
to CollateralManager"; 3.3: "only intended to be used with its intended vaults").

### 4.2 How the deployment was located

The Zellic report scope names the public repo and commit. `tenbin-contracts` (public,
`master` pushed 2026-11-06) contains **`deployments.json`** with the live addresses and the
`config/mainnet/*/vaults/*.toml` files with the parent-vault parameters. All addresses below
were re-read on-chain; none rely on the JSON alone.

### 4.3 Live state (Ethereum block 26,381,171; snapshot 26,381,150)

| Product | CollateralManager (UUPS proxy) | Impl | TVL (USDC) | `getRevenue` | Liquid USDC |
|---|---|---:|---:|---:|---:|
| **tBRL** | `0x67eB9338bAd71443aDC1f6C319D5400292a8b7e4` | `0xf5d141a140663e7b47a732d11abf8aa94804f423` | **447,127.46** | 12.649337 | 0.00 |
| **tGLD** | `0x42F3F01D45E67294e20cE98AcFDC24dD7EA75dEa` | `0x1b1ed1db1038b4d2d2d9b2b3f35d3b0dd82e8438` | **429,926.04** | 9.940470 | 37.275097 |
| **tMXN** | `0x2a21014B89F72de3Ffa6d645F89b8Ca5A6eFfe75` | `0x3695b2cba5586d45d722ded8909b2677dbfedf39` | **468,738.77** | 13.341266 | 166.359627 |
| **Total** | | | **$1,345,792.27** | **$35.93** | **$203.63** |

- All three implementations are verified `CollateralManager`; `_getRevenue` and
  `withdrawRevenue` are **identical to the audited 3.2 code** (including the
  `convertToAssets(balanceOf)` mark-to-market revenue and the liquid-balance
  `safeTransfer`).
- `pauseStatus = 0` (not paused) on all three.
- Revenue modules: tBRL `0x83cF…f5F`, tGLD `0x9337…62e`, tMXN `0xD7D6…033`; they already hold
  **$919.88** of collected USDC (632.73 + 0 + 287.15).
- `REVENUE_KEEPER_ROLE` holders are EOAs (code size 0): tBRL `0xdAA8…3A43`, tGLD
  `0xD1a8…EA03`, tMXN `0xB6BA…F714`. `collect()` from an unprivileged address reverts
  `AccessControlUnauthorizedAccount(0x1111…, 0x4287…a4f5)`; `withdrawRevenue()` from an
  unprivileged address reverts `OnlyRevenueModule`. Both were fork-verified.
- **Parent Morpho V2 vaults** (the `vaults(USDC)` of each manager):
  tBRL `0xE275…fAd9`, tGLD `0x7290…3c75`, tMXN `0x43E3…b6ca`. Each has 4 adapters:
  - one funded **`GenericMorphoAdapter`** (4,080 bytes) per parent, all pointing at
    **`0xbeef088055857739C12CD3765F20b7679Def0f51` = "Steakhouse Prime USDC" (steakUSDC)**,
    holding the full allocation;
  - one `MorphoMarketV1AdapterV2` (11,784 bytes, Morpho's own) with `realAssets = 0`;
  - two unfunded `GenericMorphoAdapter`s pointing at `0xBc65…5FE` "Spark USDC Vault"
    (`realAssets = 0`).
- **The audited `MorphoVaultV1Adapter` is not in the live adapter set.** None of the 12
  adapters exposes `morphoVaultV1()`; the repo removed the contract (only docs remain) and
  the live path is `GenericMorphoAdapter`. The audited code is not deployed behind these
  vaults.

### 4.4 Finding 3.2 — live but strictly keeper-gated

The accounting defect is live: for tMXN at the fork block,
`getRevenue = 13.518288`, `pendingRevenue = 0.016383`, `vaultAssets = 468,739.027306`,
`lastTotalAssets = 468,725.525401` → the $13.50 unrealized gain is counted as revenue
(exactly `pending + (vaultAssets − lastTotal)`). But every sink is gated:

- `RevenueModule.collect` — `onlyRole(REVENUE_KEEPER_ROLE)`;
- `RevenueModule.withdrawToMultisig` / `withdrawToManager` / `reward` /
  `setControllerApproval` — `REVENUE_KEEPER_ROLE`;
- `CollateralManager.withdrawRevenue` — `onlyRevenueModule` (the RevenueModule contract);
- `CollateralManager.deposit` / `withdraw` / `swap` — `CURATOR_ROLE`;
- `convertRevenue` / `rebalance` — `REBALANCER_ROLE`;
- `addCollateral` / `removeCollateral` / `rescueToken` — `DEFAULT_ADMIN_ROLE`.

The keeper is a protocol EOA, so this is **P**, not E-U. The keeper's *current* realizable
take is `min(getRevenue, liquid)` per manager = **$23.28** (tGLD $9.94 + tMXN $13.34; tBRL
has $0 liquid so its $12.65 cannot be paid). The theoretical take is the full $35.93 of
pending revenue once the managers hold liquid USDC. The harm is that paying unrealized gain
from principal can leave a collateral shortfall; the keeper cannot pay itself more than the
reported revenue, and the revenue is bounded by actual vault appreciation since the last
`lastTotalAssets` update.

### 4.5 Finding 3.3 — audited adapter absent; live target safe by scale

The audited `MorphoVaultV1Adapter` is not deployed in the live parent vaults. If it were,
the attack would still be conditional on the admin configuring an unsafe ERC-4626 target.
The actual live target is **Steakhouse Prime USDC**:

- `totalAssets = 139,172,709.25 USDC`; `totalSupply = 133,920,757.58` shares (18 dec);
- a $447,127 allocation mints ≈ 430,196 shares;
- to mint **< 1 wei share** the vault would need
  `totalAssets > allocation × totalSupply = 5.988e37` raw USDC = **$5.99e31** — 19 orders of
  magnitude above the vault's TVL;
- a **$1,000,000 donation** only dilutes the next allocation by **71 bps (0.71%)**; the
  attacker's 1-wei seed captures ~1/1.34e26 of the donation, so the attack loses ~$1M for
  ~$3.2k of dilution value.

Fork test `test_inflation_attack_infeasible_on_live_target` executed the $1M donation and
confirmed `previewDeposit` after the donation is still ≈430,196 shares (within 1% of the
pre-donation value). **E-U = $0.**

### 4.6 Quantification

- **E-U: $0.00** (high confidence — 3.2 sinks are keeper-gated; 3.3's audited contract is
  absent and the live target is economically un-attackable).
- **E-U-conditional: $0.00** (3.3 would need the admin to onboard an unsafe vault; 3.2
  would need the keeper to be the attacker).
- **P: $23.28 now** / $35.93 theoretical (keeper can move unrealized revenue; $919.88 of
  already-collected revenue also sits in the modules, keeper-movable).
- **H-O: $0.00** (users redeem their own positions through the normal controller; no
  stranded user value was found).
- **S: $0.00**.

---

## 5. Every unprivileged profit path considered

| Path | OPINION | Tenbin |
|---|---|---|
| Direct call to the vulnerable function | `timeoutDispute` — OPERATOR only → **closed** | `collect` / `withdrawRevenue` — keeper/module only → **closed** |
| Become the disputor and self-resolve | `resolve` gated to `0x95ee…` Safe → **closed** (storage-override + fork test) | n/a |
| Force the privileged party to act (spam/grief) | 72 disputes in 24 h is within the committee's demonstrated ~15/h throughput; the operator can pause (`whenNotPaused` on claim/dispute), which would lock the attacker's stake | n/a |
| Flash loan the stake | Unnecessary: stake is only $36.40/question; flash capital does not change the 50% break-even or the role gate | n/a |
| DEX/CEX acquisition of the stake token | OPN is liquid (DefiLlama price, PancakeSwap depth not needed at $36/position); acquisition does not create a profit path | n/a |
| Donate/inflate the vault | n/a | Live target has $139M TVL; required donation $5.99e31 → **closed** |
| Oracle/price manipulation | The resolver trusts the committee's payouts; no oracle in the L-06 path | `GoldOracleAdapter` etc. are outside 3.2/3.3 and admin-gated |
| Reentrancy / accounting | `nonReentrant` + CEI on dispute/claim; `claimed` guard; no path found | `nonReentrant` on collect/withdrawRevenue; `pendingRevenue`/`lastTotalAssets` update after transfer; no path found |
| Pause/upgrade takeover | `OPERATOR_ROLE` / `DEFAULT_ADMIN_ROLE` EOAs/multisigs — P-class, not unprivileged | `DEFAULT_ADMIN_ROLE` multisig — P-class |

---

## 6. PoC / fork verification

**Project:** `poc/` (Foundry, solc 0.8.24, vendored `forge-std`). **9/9 tests pass.**

**CI run:** https://github.com/artsbykriss/ca-zombie-ci/actions/runs/42735134675
(public repo `artsbykriss/ca-zombie-ci`, branch `ca3-opinion-tenbin`; earlier run
`42734829660` failed only because the CI `BSC_RPC_URL` env var was set-but-empty and the
fallback was not applied — fixed and re-run).

### OPINION — `poc/test/Opinion.t.sol` (4/4 PASS)

| Test | Result | What it proves |
|---|---|---|
| `test_timeoutDispute_unprivileged_reverts` | PASS | `timeoutDispute` from `0xA11CE` reverts (AccessControl) |
| `test_L06_conditional_path_requires_operator` | PASS | dispute → warp past `reVoteDeadline` → unprivileged `timeoutDispute` and `claim` revert → **impersonated** operator `0xBE39…` times out → disputor `claim` pays **2,000 OPN**, net **+1,000 OPN ($36.40)** |
| `test_resolve_on_disputed_is_not_permissionless` | PASS | on a Disputed resolution, `resolve` from the test contract **and from the disputor** both revert |
| `test_v4_resolver_is_idle_and_gated` | PASS | v4 has 0 active questions, 2,000 OPN residual, `timeoutDispute` gated |

Key CI log lines:
```
disputed; reVoteDeadline 1794369679
net disputor profit (OPN) 1000000000000000000000
resolve from test contract success? false
resolve from disputor success? false
unprivileged timeoutDispute reverted as expected
v4 OPN residual 2000000000000000000000
```

### Tenbin — `poc/test/Tenbin.t.sol` (5/5 PASS)

| Test | Result | What it proves |
|---|---|---|
| `test_collect_is_keeper_gated` | PASS | `collect` from `0xA11CE` reverts |
| `test_withdrawRevenue_is_module_gated` | PASS | `withdrawRevenue` from `0xA11CE` reverts `OnlyRevenueModule` |
| `test_revenue_bug_live_but_keeper_only` | PASS | `getRevenue = pending + (vaultAssets − lastTotalAssets)`; keeper `collect` moves **13.518288 USDC** from the manager's liquid balance |
| `test_inflation_attack_infeasible_on_live_target` | PASS | required donation $5.99e31; $1M donation → **71 bps** dilution; `previewDeposit` still ≈430,196 shares |
| `test_live_adapter_is_not_the_audited_vaultv1adapter` | PASS | live adapter target = Steakhouse Prime USDC; `morphoVaultV1()` absent; adapter funded |

Key CI log lines:
```
tMXN getRevenue (USDC 6dp) 13518288
tMXN pendingRevenue 16383
tMXN vaultAssets 468739027306
tMXN lastTotalAssets 468725525401
tMXN liquid USDC 166359627
privileged collect moved USDC 13518288
steakhouse totalAssets 139172783315297
steakhouse totalSupply 133920757578767257173007108
totalAssets needed to mint <1 wei share 59879652621228531609588576276707537656
dilution from $1m donation (bps) 71
previewDeposit after donation 430196440924994645148331
```

**No mainnet transaction was sent.** All value transfers above occurred on the fork; the
operator/keeper impersonations are explicit `vm.prank` calls and are labelled as privileged.

---

## 7. Verdict and residual/latent risk

**OPINION.** L-06 is a real design flaw, but it is a **liveness bet, not an unprivileged
drain**. The disputor cannot time out the dispute; the operator must do it, and the
committee must first fail. The reward pool is tiny relative to the protocol TVL
($2,621 vs $2.75M CTF collateral) because rewards are denominated in OPN at $0.036. The
auditor's "High impact" is about the fairness of an invalid dispute winning, not about an
external attacker capturing protocol principal. **E-U = $0.** Monitor: (a) `OPERATOR_ROLE`
changes / the operator EOA's automation; (b) a sustained rise in `DisputeTimedOut` events
(this is the empirical signal that the conditional path is live); (c) a v5 upgrade that
makes `timeoutDispute` permissionless or that raises the reward token value.

**Tenbin.** 3.2 is live in code but strictly keeper-gated; the keeper is a protocol EOA,
and the current realizable amount is $23.28. 3.3's audited adapter is not in the live
adapter set, and the live target vault is too large for the inflation attack. **E-U = $0.**
Residual risk: the admin could (i) add an unsafe ERC-4626 target behind a
`GenericMorphoAdapter` (the August report's `GenericMorphoAdapter`/factory is the live
component), or (ii) keep collecting unrealized revenue until a loss materialises. Both are
P-class/monitor items.

**Blockers to a larger claim (honest list):** (1) the OPINION v5 implementation is
unverified source; its `resolve` auth was recovered from revert payloads and storage
overrides, and the `timeoutDispute` gate from the ABI/`eth_call`; a source-level review of
v5 is not possible from the public repo. (2) The committee's off-chain re-vote process and
the operator's automation cadence are not public, so the timeout probability is estimated
from 4 hours of events, not a long history. (3) Tenbin's parent-vault allocator
(`0x48Fa…7614`, dev multisig) can change adapter targets at any time; a future unsafe
target would reopen 3.3. (4) No mainnet exploitation was attempted (read-only mandate).

---

## 8. Methodology & sources

- **DefiLlama**: `api.llama.fi/protocol/opinion` (TVL $2,745,953 at 2026-11-09; address
  `ethereum:0x7977…06e0` is the OPN token, not a resolver); `coins.llama.fi/prices/current`
  OPN = $0.036402718; `tenbin` → "Protocol not found".
- **DefiLlama Adapters**: `registries/sumTokens.js` entry `opinion` →
  `owners=[0xAD1a…D774]` on BSC; `getsourcecode` = `ConditionalTokens`.
- **Opinion dapp**: `https://app.opinion.trade` Next.js chunk `1587-11b6bd1263557ffe.js`
  → BSC mainnet `DisputeResolvers` (committee/auto) and production `ConditionalTokenAddr`.
- **BscScan via Etherscan V2** (`chainid=56`): `getsourcecode` for proxies/impls; event logs
  via public BSC RPC `eth_getLogs` (50k-block windows).
- **Pashov**: `raw.githubusercontent.com/pashov/audits/master/team/md/Opinion-security-review_2026-03-24.md`.
- **Zellic**: `github.com/Zellic/publications` → `Core Contracts - Zellic Audit Report.pdf`
  (April 2026) and `Tenbin Labs - Zellic Audit Report.pdf` (August 2026; scope of the
  GenericMorphoAdapter / CCIP adapter, no Highs).
- **Tenbin repo**: `github.com/tenbinlabs/tenbin-contracts` (public, `master` 2026-11-06)
  → `deployments.json`, `config/mainnet/*`, `src/CollateralManager.sol`,
  `src/RevenueModule.sol`, `src/external/morpho/GenericMorphoAdapter.sol`.
- **On-chain**: BSC `132,686,514`/`132,687,070`; Ethereum `26,381,150`/`26,381,171`.
  Exact calls are in `analysis/live-state.json`, `analysis/opinion_q_state.json`,
  `analysis/resolve-gating-result.json`, `analysis/resolver-logs.json`.

### Caveats

- OPN price is a DefiLlama spot price with 0.999 confidence; a thin OPN book could make the
  USD reward smaller than $36.40 at execution, but it does not create an unprivileged path.
- The v5 resolver's `getActiveQuestionIds()` returns 72; the reward pool can change as
  questions are added/finalized. The bound is stated at the snapshot block.
- The Tenbin TVL is the USDC value of the parent-vault positions; it excludes the
  asset-token liabilities and any off-chain futures hedge (which the protocol describes as
  the other backing leg). The USDC collateral is the on-chain extractable surface.
- `getRevenue` is a mark-to-market number; it changes with the vault's share price and with
  curator `deposit`/`withdraw` calls that reset `lastTotalAssets`.

### Files index

| File | Contents |
|---|---|
| `README.md` | this report |
| `summary.json` | machine-readable verdict |
| `poc/` | Foundry project, 9 fork tests |
| `ci/run.sh` | light live-state snapshot for the CI artifact |
| `ci-out/live-state.json` | block numbers at the CI run |
| `ci-log.txt` | full CI log (run 42735134675) |
| `ci-artifacts/` | uploaded CI artifact |
| `analysis/live-state.json` | exact on-chain snapshot (both chains) |
| `analysis/opinion_q_state.json` | 72-question status/reward/deadline dump |
| `analysis/resolve-gating-result.json` | storage-override `resolve` auth probe |
| `analysis/resolver-logs.json` | 280 resolver logs / topic decode |
| `analysis/pashov-opinion.md` | Pashov report text |
| `analysis/tenbin-core-april.txt` | Zellic April report text |
| `analysis/tenbin-august.txt` | Zellic August report text |
| `analysis/src-0x1537…/` | verified v4 DisputeResolver source |
| `analysis/src-0xf5d1…/` | verified tBRL/tMXN CollateralManager source |
| `analysis/src-0x1b1e…/` | verified tGLD CollateralManager source |
| `analysis/src-0x95ee…` | ResolutionMultiSig source request (unverified) |
| `analysis/tenbin-deployments.json` | Tenbin live address registry |

**Read-only attestation:** no transaction was signed, no key was used, no state was
modified on any live network. The only state changes in this work occurred inside ephemeral
forks in GitHub Actions and are documented above.
