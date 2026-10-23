# StakeDAO-Curator — Pashov C-02 (`_update` override missing) live-state assessment & fork PoC

**Date:** 2026-10-23 · **Chain:** Ethereum mainnet (chainId 1) · **Status:** read-only; PoC fork-verified only; **no mainnet transaction was ever signed or sent.**

**Target:** Stake DAO "Curator / Morpho-collateral vault" (DefiLlama slug `stake-dao-curator`, ≈$1.008M) and the
`StrategyWrapper` family used as Morpho Blue collateral.
**Finding:** Pashov Audit Group, `StakeDAO-security-review_2025-07-21`, **C-02 "Checkpoints are almost always
outdated due to missing `_update` override"** (CRITICAL, **Acknowledged**).

> **Headline:** C-02's literal recommendation (override `_update`) was never implemented, **but the exact
> stale-checkpoint impacts are neutralised by a redesign in every wrapper that backs live value.** The four
> value-bearing Stake DAO Morpho markets (≈**$629,606** collateral, ≈$540,792 borrowed, funded by the ≈$1.008M
> curator vaults) run **patched** wrappers (permissioned transfer + `claimLiquidation` with a `liquidator` guard
> and hole-clamp + always-advance reward settle). Only 17 **dust** wrappers (~$0 collateral, ≈$19 underlying) still
> run the pre-patch code, and the one redeemable path there pays the attacker **$0**. **Live unprivileged
> extractable = $0.00.**

---

## TL;DR

| # | Target | Live value | Unprivileged extractable (E-U) | Why closed / open | Latent risk |
|---|---|---|---|---|---|
| 1 | **Stake DAO Curator — 4 value-bearing Morpho markets** (wrappers `0x6292…`, `0x12D7…`, `0x728c…`, `0xA31b…`) | **$629,606 collateral** ($540,792 borrowed; curator vaults $1.008M) | **$0** | **Patched wrappers**: `transfer`/`transferFrom` gated to the lending protocol; `claimLiquidation` has `require(liquidator != LENDING_PROTOCOL && liquidator != address(this))` + hole-clamp; reward settle always advances the checkpoint. C-02 has no reachable impact. | none found |
| 2 | **Stake DAO Curator — 17 dust Morpho markets** (pre-patch wrappers, e.g. `0x7658…`, `0x3B85…`) | collateral ≈ **$0**; wrapper underlying ≈ **$19** | **$0** | Pre-patch code (no `_update` override, no `claimLiquidation` guard) **is live here**, and `claimLiquidation(MORPHO, victim, amt)` **executes** — but the unwrapped shares are sent to **Morpho**, so the caller gains **0**. Result is griefing/DoS, not theft. | orphaned CRV pot ≈**$85** (see §5) |
| 3 | Orphaned reward pot on pre-patch wrapper `0x3B85…` (`stakedao-FrxMsUSD`) | **233.74 CRV ≈ $85.47** | **$0** (needs patience + real RV capital; not unconditional) | Stranded at `totalSupply = 1 wei`; pre-patch `_claim` only advances the checkpoint when the payout is non-zero, so a stale checkpoint can over-claim the pot **over time**. The patched wrapper fixes this. | **S/H-O** ≈$85 |

**Total live unprivileged extractable now: $0.00** (confidence **high**). Residual holder/stuck value ≈ **$104**
(≈$19 dust wrapper underlying + ≈$85 orphaned reward pot), none of it reachable by an external attacker.

---

## 1. The finding (Pashov C-02) in exact terms

Audit: `pashov/audits` → `team/md/StakeDAO-security-review_2025-07-21.md`, review commit
`2fc661343b77cc0c153c58a2ca75578395c66907`, fixes-review commit `07874f7…` (repo `stake-dao/contracts-monorepo`,
now private; a public extraction of the current tree is `stake-dao/lending-contracts-audit`). C-02 is filed
**Acknowledged** (no fix at the time):

> *"Strategy tokens are used as collateral token in Morpho Blue markets. … `_update` function is not overridden
> in strategy wrapper, which means checkpoints will be outdated almost always."*
> Impacts: (1) liquidator cannot redeem LP (checkpoint underflow in `withdraw`), (2) a liquidated borrower keeps
> his checkpoint and keeps claiming rewards on collateral he no longer owns, (3) fungibility is broken.

The wrapper is a **non-transferable ERC-20** whose per-user reward **checkpoints** (`userCheckpoints`) are updated
only in `deposit`/`withdraw`. When the lending protocol moves wrapper tokens (Morpho liquidation → liquidator), the
recipient has no checkpoint, and the victim's checkpoint is not reduced.

### 1.1 Live code — C-02 is present in the *pre-patch* wrapper, absent in the *patched* wrapper

The deployed `MorphoStrategyWrapper`/`StrategyWrapper` bytecode is **verified on Etherscan** and comes in **two
generations** (all deployed by EOA `0x794addd03889c2b96b16ad230e372b78964d9c76`):

| | pre-patch (old) | patched (current) |
|---|---|---|
| `_update` override | **absent** | **absent** |
| `transfer`/`transferFrom` | gated to lending protocol | gated to lending protocol |
| `claimLiquidation` | present, **no `liquidator` guard, no clamp** | `require(liquidator != LENDING_PROTOCOL && liquidator != address(this))` + hole-clamp (`NothingToClaim`) |
| reward settle (`_claim`/`_claimExtraRewards`) | advances checkpoint **only if payout ≠ 0** | **always advances** (`rewardPerTokenPaid = current`) |
| live example | `0x76589A67…`, `0x3B855AA8…` (17 in total) | `0x62923a64…`, `0x12D706F0…`, `0x728c3B9E…`, `0xA31b5941…` |

Because `_update` is not overridden in *either* generation, the C-02 recommendation was not followed; the
**patched** generation instead removes the attack surface (transfers only via the lending protocol + an explicit,
guarded liquidation reconciliation). The current design is documented in `stake-dao/lending-contracts-audit`
(`src/lending/README.md`: *"Wrappers are non-transferable… Liquidation must end with `claimLiquidation`"*), and the
guard's own comment states the reason: *"The lending protocol and this contract are never valid liquidators. Both
can carry an off-track balance that did not originate from a genuine liquidation."* Extracted sources and the
full diff are in `analysis/`.

---

## 2. Live-state assessment (addresses, blocks, roles, balances)

Snapshot block **26,255,442** (2026-10-23). All reads via public `eth_call`; source via Etherscan V2
`getsourcecode`.

**Curator vaults (DefiLlama `stake-dao-curator` = $1,007,814):**

| vault | contract | assets |
|---|---|---|
| Stake DAO USDC v1 | `0x13AA4f80AD5F06cE4f1A3a3cA58C37059F0EE4c5` (`MetaMorphoV1_1`) | ~$81k (drained) |
| Stake DAO USDC v2 | `0x8EDCC305E633d29BFB383872e79401c506cE9E6f` (`VaultV2`) | **359,574.94 USDC** |
| Stake DAO frxUSD v2 | owner `0xB0552b6860CE5C0202976Db056b5e3Cc4f9CC765` | **~648,444 frxUSD** |

**Morpho-collateral markets (22 markets whose collateral is a Stake DAO `MorphoStrategyWrapper`).** The four with
live value, all loan token frxUSD (`0xCAcd6fd266aF91b8AeD52aCCc382b4e165586E29`), LLTV `9.15e17`, IRM
`0x870aC11D48B15DB9a138Cf899d20F13F79Ba00BC`, supplied by *Stake DAO frxUSD v2*:

| market | collateral wrapper | collateral USD | borrowed USD | wrapper generation |
|---|---|---|---|---|
| `0x1f10c0899f…` `stakedao-frxsUSDS` | `0x62923a64D7940be920FD5cdc27873Ab8eEc59F9F` | 375,658.78 | 324,501.3 | **patched** |
| `0x4fbdeb7979…` `stakedao-frxUsDOLA` | `0x12D706F0aDFF3BE5d9Fa119424A85388FeCD6960` | 207,376.05 | 183,820.1 | **patched** |
| `0x35c92b233f…` `stakedao-crvfrxUSD` | `0x728c3B9Eb722F7aFC17F0D26A80d625C53059086` | 30,401.27 | 20,893.5 | **patched** |
| `0x328aadb887…` `stakedao-FrxMsUSD` | `0xA31b5941F2e74d89bDC66632959FE6A152692920` | 16,170.41 | 11,578.1 | **patched** |
| **total** | | **$629,606.51** | **$540,792.99** | |

Live reads (block 26,255,442): `W_FIX 0x6292…` `totalSupply = 359,614.566…e18` and `balanceOf(MORPHO) =
359,614.566…e18` (the whole supply is collateral); `W_OLD 0x7658…` `totalSupply = 988.586…e18`, `balanceOf(MORPHO)
= 0`. The remaining **18** markets are dust (`collateralUsd ≈ 0`, e.g. $1.0e-18).

**Roles / control:** every wrapper's `owner()` is `address(0)` (ownership renounced after `initialize(marketId)`);
`lendingMarketId` is set once and immutable; `LENDING_PROTOCOL = 0xBBBB…FFCb` (Morpho Blue). `transfer`/
`transferFrom` revert with `TransferUnauthorized` unless `msg.sender == MORPHO`. No pause, no upgradeability on
the wrappers (non-proxy, `Proxy = 0`).

---

## 3. What an attacker can and cannot do

**Cannot (value-bearing markets).** On a patched wrapper:
* Move wrapper tokens to themselves (`transfer`/`transferFrom` gated).
* Call `claimLiquidation(MORPHO, victim, amt)` or `claimLiquidation(wrapper, victim, amt)` — reverts
  `InvalidLiquidation` (guard). **Fork-verified.**
* Over-claim rewards from a stale checkpoint — the settle always advances `rewardPerTokenPaid`.
* Profit from the missing `_update` override in any other way: the only non-protocol transfer is a Morpho
  liquidation, which the guarded `claimLiquidation` reconciles 1:1.

**Can (dust markets, pre-patch wrappers) — but nets $0.** With two real depositors and an off-track withdrawal:
1. `depositShares(X)` (patched: `depositShares(X, receiver)`) mints wrapper tokens and supplies them to Morpho.
2. The depositor withdraws its own collateral to a **different receiver** (`Morpho.withdrawCollateral(id, X, self,
   ALT)`), creating an off-track balance for `ALT` and an "off-track hole" for the depositor.
3. Anyone calls `claimLiquidation(MORPHO, depositor, X)` — **the pre-patch wrapper accepts it** (no guard): it
   burns `X` wrapper tokens **from Morpho's collateral balance**, sends `X` RewardVault shares to **Morpho**, and
   clears the depositor's hole. The caller receives **0**; `ALT`'s off-track tokens become **unredeemable** (its
   hole was consumed). Net attacker profit **$0**; effect is griefing/DoS of other borrowers.

Cost of the above: gas only. There is no flash-loan capital requirement, and no path pays the caller.

---

## 4. PoC / fork-verification

`poc/` — Foundry (solc 0.8.24, cancun). Fork-only, read-only on mainnet. RewardVault shares are sourced
realistically by dealing the vault's own underlying LP and depositing it through the vault (no state overrides).

| test | what it proves | result |
|---|---|---|
| `test_live_state` | patched market holds ≈359,615 wrapper tokens as Morpho collateral; pre-patch market holds 0 | **PASS** |
| `test_old_wrapper_missing_guard_no_profit` | pre-patch wrapper **executes** `claimLiquidation(MORPHO, A, sA)`; caller gains **0** RV shares; `ALT`'s off-track balance becomes unredeemable | **PASS** |
| `test_fixed_wrapper_guard_reverts` | patched wrapper **reverts** on `claimLiquidation(MORPHO,…)` and `claimLiquidation(wrapper,…)`; the legitimate `claimLiquidation(ALT,…)` settles the full amount | **PASS** |
| `test_orphaned_reward_pot` | pre-patch wrapper `0x3B85…` holds **233.74 CRV** at `totalSupply = 1 wei` | **PASS** |

**4/4 PASS.** CI run URL(s) are recorded in `ci-log.txt` / `summary.json`.

Key numbers: `W_FIX 0x6292…` totalSupply/collateral `359,614.566…e18`; `W_OLD 0x7658…` Morpho balance `0`;
orphaned pot `233,744,780,983,111,838,994` CRV = **$85.47** @ CRV $0.365743 (DefiLlama 2026-10-23).

---

## 5. Residual / latent risk

* **Orphaned reward pot (≈$85, pre-patch wrapper `0x3B85…`).** `totalSupply = 1 wei` but the wrapper holds 233.74
  CRV. The pre-patch `_claim`/`_claimExtraRewards` advance the checkpoint **only when the floored payout is
  non-zero**; a holder with a stale checkpoint who later grows their balance re-applies the old per-token rate to
  the new balance and can drain the shared pot. This is a **real but conditional** E-U: it requires (a) a dust
  deposit before an integral increase, (b) real RewardVault capital, (c) time for the integral to grow. It is not
  unconditional, and the pot is bounded at ≈$85. The patched wrappers fix it. Category **S/H-O**.
* **Bricked off-track balances (dust markets).** On pre-patch wrappers a griefer can consume a victim's hole with
  `liquidator = MORPHO`, stranding the real receiver's off-track wrapper tokens (and burning Morpho's collateral
  balance). Bounded by the dust markets' ≈$19 underlying. Category **S**.
* **Adjacent, out of C-02 scope (noted for completeness):** the same audit's **M-07/M-08/L-10** describe Curve-LP
  **oracle** price manipulation via flash loans (`CurveStableswapOracle`/`CurveCryptoswapOracle` reading pool
  state). The live value-bearing markets use the (patched) wrappers with per-market oracles
  (`0x9eD400…`, `0x0c63A8…`, `0x9223b2…`, `0x9aA3BF…`); oracle manipulation is a distinct attack surface and was
  **not** reduced to a live path here.

**Blockers / caveats:** values are DefiLlama/Morpho-API snapshots at block 26,255,442 and move with the market;
the dust wrapper underlying is priced by the wrapper token price and is a rough figure; the orphaned-pot drain was
reasoned from the source diff, not executed (it needs real-time integral growth).

---

## 6. Verdict

> **C-02 is present as source (no `_update` override) in every live `StrategyWrapper`, but it is reachable only in
> 17 dust markets that hold ≈$0 collateral. The four value-bearing Stake DAO Morpho markets ($629,606 collateral;
> $540,792 borrowed; $1.008M curator vaults) run patched wrappers whose `claimLiquidation` guard, hole-clamp and
> always-advance reward settle neutralise the stale-checkpoint impacts. Fork PoC: the pre-patch missing-guard path
> executes but pays the attacker $0 (griefing only); the patched path reverts; 4/4 tests PASS.**
>
> **Live unprivileged extractable (E-U): $0.00 — confidence high.** Residual holder/stuck ≈$104 (≈$19 dust
> underlying + ≈$85 orphaned reward pot), none attacker-reachable.

---

## 7. Methodology, sources, caveats, files

**Method.** Read the Pashov report from `pashov/audits`; located the live protocol via DefiLlama
(`api.llama.fi/protocol/stake-dao-curator`, `registries/curators.js`); enumerated the 22 Stake-DAO-collateral
Morpho markets via the Morpho Blue GraphQL API; pulled every wrapper's verified source (Etherscan V2) and
classified patched vs pre-patch by the `liquidator` guard / `NothingToClaim` clamp / settle fix; diffed against
`stake-dao/lending-contracts-audit`; measured live state (`eth_call`); built a fork PoC that reproduces the
liquidation-redemption path on both generations and measures attacker profit.

**Caveats.** (1) The audited repo `stake-dao/contracts-monorepo` is now private; the public
`stake-dao/lending-contracts-audit` extraction (commit `da08e86`, tree `5f4cb2dd`) is used as the current-main
reference and matches the patched live bytecode. (2) The literal 2025-07-21 audited commit could not be
byte-diffed; the *deployed* code is the ground truth used here. (3) Prices are snapshots. (4) The orphaned-pot
drain is source-diff-reasoned, not executed. (5) No mainnet transaction was sent; all exploit mechanics ran on
local forks.

**Files.**
```
stake-dao-curator/
├── README.md                                   ← this document
├── summary.json                                ← machine-readable summary
├── analysis/
│   ├── pashov-StakeDAO-2025-07-21.md           full audit report
│   ├── MorphoStrategyWrapper_live_0x7658.json  pre-patch verified source (JSON)
│   ├── MorphoStrategyWrapper_FIXED_0x6292.json patched verified source (JSON)
│   ├── live_src__wrappers__StrategyWrapper.sol  extracted pre-patch base
│   ├── fixed_src__lending__wrappers__StrategyWrapper.sol  extracted patched base
│   ├── diff_auditrepo_vs_live_StrategyWrapper.txt  pre-patch vs current-main diff
│   ├── wrapper_classification.json             patched/pre-patch classification (22 markets)
│   ├── old_wrappers_state.json                 per-wrapper totalSupply / RewardVault / asset
│   └── live_state.json                         live-state dump (addresses, block, values)
└── poc/
    ├── foundry.toml · lib/forge-std (vendored)
    ├── src/Interfaces.sol
    └── test/StakeDaoCurator.t.sol              4 fork tests (4/4 PASS)
```

> ⚠️ For security research only. The PoC runs on local forks; executing against mainnet would be unauthorised.
