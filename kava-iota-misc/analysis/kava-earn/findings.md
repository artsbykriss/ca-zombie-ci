# Kava Earn (x/earn + x/savings + x/liquid) — L2-25 deep-dive

**Date:** 2026-10-15 · **Chain:** Kava L1 `kava_2222-10` (Cosmos SDK) · **Deployed app version:** `kava v0.28.2` (from `/cosmos/base/tendermint/v1beta1/node_info`), source pinned at tag `v0.28.2` (commit `686d591`).
**Status:** read-only; no transactions; all reads at explicit heights (latest ~23,035,688).

## Verdict

| Category | USD | Confidence | Note |
|---|---|---|---|
| **E-U (external unprivileged)** | **≈ $0.0008** | high | Orphan-denom dust capture (12,081 bkava base units ≈ 0.0121 bkava). Mechanism proven by code; economically irrelevant. |
| H-O (holder-only) | ≈ $1.39M | high | Depositors withdraw their own vault shares; savings module exactly solvent. |
| P (privileged/governance) | params-gated | high | Allowed vaults/strategies, reward periods, claim end, upgrade of chain binary. |
| S (stuck) | unclaimed rewards | medium | Earn claims expire 2026-11-01T23:59:59Z; bkava staking rewards are currently *not collected* (empty reward periods). |

**Headline: a fresh external attacker can extract ≈ $0 (dust-only, $0.0008) from Kava Earn today. High confidence.**

## Live value (heights 23,035,008–23,035,688)

- **DefiLlama TVL** for `kava-earn`: **$1,390,964.53**.
- Earn vault records: **124** (123 funded + empty private `ukava` vault).
- Composition (LCD `total_supply` + `vaults`):
  - `bkava` (per-validator liquid-staking tokens): **19,925,920.219103** units in the earn→savings record (KAVA-equivalent of the module's delegations: 19,925,929.740013 KAVA).
  - `erc20/multichain/usdc`: 15,587.488825 · `usdt`: 3,586.257861 · `dai`: 495.073496 · `bnb`: 2.53213225
  - `usdx` vault (**HARD** strategy): **500,009 USDX** (nominal $500k; USDX's real market value is the Kava-Swap child's scope; it is excluded from DefiLlama's number).
- At KAVA ≈ $0.0688 (DefiLlama, 2026-10-15): bkava leg ≈ $1.371M.

## Architecture (exact)

- `x/earn` vaults: `VaultRecord{TotalShares}` per **full denom**; `GetVaultTotalValue(denom)` = **strategy's `GetEstimatedTotalAssets`**, *not* any bank balance:
  - `SAVINGS` strategy → the **earn module account's x/savings deposit record** for that denom (`strategy_savings.go`).
  - `HARD` strategy → the module account's synced `x/hard` deposit (with interest) (`strategy_hard.go`).
- Allowed vaults are param-driven; `bkava-<valoper>` denoms map to the generic `bkava` AllowedVault (`keeper/params.go: GetAllowedVault`).
- Deposits move coins to the earn module account, then the strategy moves them to the savings module account (`savingsKeeper.Deposit`). The earn module account is empty (verified).
- Share math (`keeper/vault_share.go`): `ConvertToShares = floor(assets × totalShares / totalValue)`; `ConvertToAssets = floor(totalValue × shares / totalShares)`; withdraw requires `withdrawAmount ≤ ConvertToAssets(accountShares)` and burns `ConvertToShares(wantAmount)` shares (floor), with a dust cleanup that removes <1-unit remains (favors the vault).

## Adversarial analysis (all paths tested)

1. **Donation / share-inflation** — `totalValue` reads the savings **deposit record**, never `bankKeeper` balances. Direct sends to the earn/savings module accounts do **not** change the record. No inflation vector. ✔ (code: `GetVaultTotalValue` comment + `strategy_savings.go`).
2. **Cross-account withdrawal** — `x/savings MsgWithdraw.GetSigners = depositor`; `x/earn MsgWithdraw.GetSigners = from`; `x/router` msgs sign as `depositor`/`from` (`x/savings/types/msg.go`, `x/earn/types/msg.go`, `x/router/types/msg.go`). Module accounts cannot sign → the earn module's savings record (19.9M bkava) is untouchable by outsiders. ✔
3. **Rounding extraction** — both conversions truncate; withdraw is capped by `ConvertToAssets(accountShares)`, so a caller can never receive more than their proportional floor. Round trips are neutral-or-loss. ✔
4. **First-depositor attack** — if a vault record exists with `totalShares == 0`, `ConvertToShares` reverts ("share count is zero"); records are deleted at zero. ✔
5. **Savings solvency** — module balance == Σ deposit records for **all 142 denoms, zero diff** (`ci/kava_earn_check.py` C1; `analysis/savings_solvency.json`). The two non-earn depositors are normal users. ✔
6. **bkava backing** — liquid module delegations = 19,928,788.282333 shares vs bkava supply 19,928,789.665657 units → **delta +1.383324 bkava (0.0000069%)**; fully backed (truncation dust). ✔
7. **Orphan dust capture (the only E-U)** — 19 `bkava-<valoper>` denoms have **savings records with no vault record** (total **12,081 base units = 0.012081 bkava ≈ $0.0008**). A fresh attacker can deposit `M` into a fresh vault for such a denom (shares = M, 1:1 because no record), then withdraw `M` shares which pays `D + M` (the orphan dust `D` included, since `totalValue` = savings record). Proven by code trace (`deposit.go` → `ConvertToShares` store-read; `withdraw.go` → `ConvertToAssets`). Value: dust. Two of the affected validators (`168g9…`, `1s8ak…`) are unbonded/jailed; `IsDerivativeDenom` still returns true.
8. **Reward/claim accounting** — Synthetix-style indexes (`x/incentive/keeper/rewards_earn.go`). Hooks pass *pre-modification* shares on deposit/withdraw; `InitializeEarnReward` sets the index without paying the gap; `GetSynchronizedEarnClaim` pays `(global − user) × currentShares`; `ClaimEarnReward` pays `amt × multiplier.Factor` (factor ≤ 1) and subtracts `amt`; payout is from the **kavadist** module account (37,906,533.82 KAVA ≈ $2.6M — a *shared* pool for all incentive programs). No double-claim or free-claim path: claims are per-owner and only created via the deposit hook. ✔
9. **`x/router` module** (MintDeposit / DelegateMintDeposit / WithdrawBurn / WithdrawBurnUndelegate) — converts a user's own delegation ↔ bkava ↔ earn shares; `x/liquid` mint/burn math truncates in the module's favour; every msg signer = the depositor/from. No caller-side gain. ✔
10. **HARD-strategy vault (`usdx`)** — value = synced hard deposit (500,009 USDX vs 500,000 principal). First-withdrawer preference is bounded by accrued interest (9 USDX); no outsider path. The only risk is HARD-side bad debt (holder loss, not E-U).

## Live-state evidence

| Fact | Value | Source |
|---|---|---|
| Earn vaults / funded | 124 / 123 | `GET /kava/earn/v1beta1/vaults` |
| bkava in earn→savings | 19,925,920.219103 | same |
| Liquid module delegation shares | 19,928,788.282333 | `GET /cosmos/staking/v1beta1/delegations/kava1gggsz…` |
| bkava total supply | 19,928,789.665657 | `GET /cosmos/bank/v1beta1/supply` |
| Savings module vs records | exact, 0 diffs, 142 denoms | `GET /kava/savings/v1beta1/deposits` + balances |
| Earn module account | empty | balances |
| kavadist (reward pool) | 37,906,533.821176 KAVA | balances |
| earn_reward_periods | `[]` (frozen indexes) | `GET /kava/incentive/v1beta1/params` |
| claim_end | 2026-11-01T23:59:59Z | same |
| earn params allowed vaults | ukava(private), usdx(HARD), bkava(SAVINGS), usdc/usdt/dai(SAVINGS) | `GET /kava/earn/v1beta1/params` |

CI verification (`ci/kava_earn_check.py`, run by `ci/run.sh`): **C1–C6 all PASS** (savings solvency; vault value == savings record; bkava backing; orphan-dust quantification; earn-macc empty; reward periods/claim end). Output: `ci-out/kava_earn_check.json`.

## Negative results (do not re-investigate)

- No share-inflation/donation path (totalValue is a record, not a balance).
- No cross-account withdrawal (signer checks).
- No rounding arb (floor both ways + account-value cap).
- No claim/double-claim/free-claim path; reward indexes frozen (periods empty).
- No module-account drain (earn macc empty; savings macc only pays records; liquid macc pays shares 1:1).

## Residual/latent risk

- **S:** unclaimed earn rewards become unclaimable after 2026-11-01 (`ErrClaimExpired`). bkava staking rewards currently accrue but are not collected while `earn_reward_periods` is empty (governance would need to re-add a period).
- **P:** governance can change allowed vaults/strategies and reward periods; the chain binary is upgradeable by governance.
- **H-O risk:** the `usdx` HARD-strategy vault's realizable value depends on the (dead) USDX market and HARD solvency.

## Files

- `analysis/kava-earn/state.json` — raw state snapshot.
- `analysis/savings_solvency.json`, `analysis/bkava_supply.json`, `analysis/liquid_delegations.json` — raw reads.
- `ci/kava_earn_check.py`, `ci/run.sh`, `ci-out/kava_earn_check.json` — re-runnable invariant verification.
- Source pinned at `v0.28.2`: `x/earn/keeper/{deposit,withdraw,vault,vault_share,strategy_savings,strategy_hard,params}.go`, `x/savings/keeper/{deposit,withdraw}.go`, `x/incentive/keeper/rewards_earn.go`, `x/router/keeper/msg_server.go`, `x/liquid/keeper/derivative.go`.
