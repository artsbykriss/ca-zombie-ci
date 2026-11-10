# Mezzanine (Ethereum) — live state, H-1 fix, M-1 probe

**Read-only. No transactions signed or broadcast. Local snapshot at Ethereum block
26,380,929 (2026-11-10); CI re-runs at the live head (26,381,184 in the local dry run).
All reads are `eth_call` / `eth_getCode`.**

## 1. Contracts and roles

| Item | Address | Notes |
|---|---|---|
| IssuanceVault proxy | `0xBB03549117e38103589774AE1D6338D1B237FFA2` | impl `0xB27788F6ABF1148fa6dab2FADd1Ab0B67b80b1Ee` |
| MZUSD proxy | `0x1BBa049d3869E8d467F38E52AcA8E99D64E310a6` | impl `0xB801a47cbB431f9a3234DA136bc4D75aBB5c7d88`, 18 decimals |
| wYLDS (accounting asset) | `0x6aD038cA6C04e885630851278ca0a856Ad9a66Cc` | 6 decimals, Hastra wYLDS |
| NavOracleAutomation | `0x9994BC2eCdFd7BDeB5423f5e48E285b91e6a69A7` | not a proxy |
| NAV feed | `0x9f0d1AEe42454d7e1FABd4522b415022B928a9c7` | 8 decimals |
| Total-supply feed | `0x736771260B9A0E1715A3Bf3aC05Dd6D71A8838b9` | 8 decimals |
| LossManager proxy | `0xD068f54EC22726ba7102Aa425B7845752BEd46E4` | impl `0x8bbd6b15f8026d54bba43cf801392d3a6d0e0905` |
| PauseManager | `0x516AE1c454b75A11a357BAc427AC41F361787a47` | all categories false |
| AccessManager | `0x60A64B9F10fA2C9CacD3EC701e6f3D226d5792Cd` | OZ v5 |
| Junior tranche proxy | `0x6F5d94Dc0c8bBf052aBF024259d087dA45AD96A1` | "Junior Hastra", trancheId 2, 21 dec |
| Senior tranche proxy | `0x0e246e5FA94E90ab784b03961C35AaD9999b6649` | "Senior Hastra", trancheId 1, 21 dec |
| Reservoir | `0x43bC5fB52A618F0F2efb0d68Cf900Bb2FbD8a501` | 0.966277 wYLDS |

AccessManager role holders (read from `RoleGranted` logs and `canCall`):

| Role | Function | Holder |
|---:|---|---|
| 0 (admin) | `setTrancheConfig`, `setFeeRates`, `setBuffer`, `setEpochConfig`, `registerTranche`, `setLossManager`, `setNavOracle`, `rejectPendingNav` | `0x0b61220A0d0aFd11da63B2931EE368E34E60d122` (Safe, 171-byte proxy) |
| 6 | `submitNav()` | `0x816dd023C90eDfb751EEfdCCe064AeBB3Bb2AaEd` (**EOA**, 0 code) |
| 9 | `finalizeEpoch(uint256)` | `0x0630e23e0c2D2147b64Ca493f656fE2514D2027B`, `0x8e070d0977Ad7fe597b24132518D19971CE17C51` |
| 10 | `performUpkeep(bytes)` | `0xFAf5012Ee1d9344cf388281e67982Efa75a0bC77`, `0x011b8dDf24Ad0eE09cc198cB0ac4f076F90bB81D` |
| 3 | `upgradeToAndCall` | restricted |
| 5 | `notifyYield`/`burnMZUSD` targets | tranche contracts |

The `submitNav` role being an EOA is a centralisation/key-risk observation (P-class), not an
unprivileged path: the function still reverts for every other caller (`AccessManagedUnauthorized`).

## 2. Live vault state (block 26,380,929)

| Item | Value |
|---|---|
| `tranchesLength()` | 2 |
| `getTranches(0,2)` | `[Junior, Senior]`, risk premiums `[2000, 0]`, **both `enabled = true`** |
| `epochDuration()` | `600,300` s (6.95 days) |
| `epochStart()` | `1,793,888,711` |
| `currentEpochId()` | 4 |
| Junior `totalAssets()` | `1,067,210,724,880,312,992,046,362` (1.067M MZUSD 18d) |
| Junior `totalSupply()` | `1,053,344,930,682,480,183,194,192,053` |
| Senior `totalAssets()` | `2,628,873,963,302,225,735,925,663` (2.629M) |
| Senior `totalSupply()` | `2,612,182,967,693,205,296,214,778,513` |
| Junior `directWithdrawEnabled()` | `false`, `unstakeDelayEpochs = 2`, `unstakeYieldReductionBps = 5000` |
| Senior `directWithdrawEnabled()` | `false`, `unstakeDelayEpochs = 1`, `unstakeYieldReductionBps = 5000` |
| MZUSD `totalSupply()` | `5,485,102.289389` (18d) |
| wYLDS `balanceOf(IssuanceVault)` | `307,999.879170` (6d) |
| wYLDS `balanceOf(Reservoir)` | `0.966277` (6d) |
| `maxLossPerTxUSDC()` | `1e12` (1,000,000 USDC) |
| PauseManager | `isPaused(vault, 0..4) = false` |

## 3. H-1 — oracle desync — FIXED LIVE

The deployed `NavOracleAutomation` source (verified) contains:

```solidity
// Both oracles should always be updated in the same transaction
if (navUpdatedAt != supplyUpdatedAt) revert OraclesNotInSync();
```

- `OraclesNotInSync()` selector = `0x5b890303`; the selector is present in the deployed runtime
  bytecode (19,534 hex chars) at the fork block.
- `submitNav()` is `restricted`; the AccessManager role 6 holder is the EOA
  `0x816d…2aed`. `canCall(attacker, NavOracle, submitNav)` = **false**.
- Live feeds at the local block:
  - NAV answer `514,577.37575714` (8d), `updatedAt = 1,794,237,395`
  - Supply answer `514,015.03912480` (8d), `updatedAt = 1,794,237,395`
  - **Equal timestamps**, both < `maxAnswerStaleness` (86,400 s). The feeds are the single
    Redstone multi-point package described in the source comments.
- `vetoPeriod = 86,400`, `maxAnswerStaleness = 86,400`; the `_assertStalenessBound` check
  (`staleness < max(veto, epochDuration)`) passes because `86,400 < 600,300`.
- `hasPendingNav()` = false at the local block.

Fork proof (`test_h1_oracles_not_in_sync_reverts`): with the NAV feed mocked at `now` and the
supply feed at `now - 1`, the authorized submitter's `submitNav()` reverts with
`OraclesNotInSync()`. With both at `now`, it succeeds and stores `pendingDeltaUSDC = 1,000e6`
for a mocked 1,000 USDC delta. The unauthorized caller reverts before reaching the feed logic
(`test_submit_nav_unauthorized_reverts`).

**H-1 is closed on the live contract.** The only residual is the generic yield-sniping window:
a depositor who enters a tranche after the pending NAV is fixed and before the 24h veto expires
shares in the *already reported, backed* yield. The capture is bounded by the reported delta
(live ~562 USDC per pending report), not by the attacker's deposit; see §5.

## 4. M-1 — loss applied to disabled tranches — NOT LIVE

`LossManager._applyLossAcrossOrder()` iterates `vault.getTrancheOrder()` and burns from each
tranche's `totalAssets()` without checking the `enabled` flag (the yield allocator in
`IssuanceVault._allocateYieldToTranches` *does* skip `!enabled`). This is the Sherlock M-1
finding, acknowledged won't-fix.

Live precondition: **both tranches are enabled**, so M-1 has no live effect. The fork test
`test_m1_disabled_junior_absorbs_loss` disables the Junior (and moves the 2,000 bps premium to
the Senior so the 10,000 bps total still validates), applies a 100,000 USDC loss, and observes:

- Junior **raw MZUSD** balance: `1,069,323,130,073,786,564,615,090` → `969,323,130,073,786,564,615,090`
  (exactly 100,000e18 burned);
- Senior raw balance: unchanged.

So the disabled Junior absorbs the loss, exactly as M-1 describes. This is a wealth transfer away
from the disabled tranche's existing holders; it is **not** a positive-yield primitive.

## 5. Can a fresh depositor profit?

### Loss case (both tranches enabled)

`test_m1_fresh_depositor_cannot_profit`:
- Deposit `200,000 MZUSD` into the first-loss Junior.
- Oracle applies a `200,000 USDC` loss.
- Request withdrawal, advance two epochs, finalize, claim.
- Claim: **`168,764.78 MZUSD`** vs `200,000` deposited → **−31,235.22 MZUSD (15.6% loss)**.

No fresh depositor can withdraw more than deposited; the loss is real and is allocated pro-rata.

### Disabled-tranche case

`test_m1_disabled_junior_protects_enabled_but_no_positive_yield`:
- Disable the Junior, deposit `200,000 MZUSD` into the Senior.
- Apply a `200,000 USDC` loss: the disabled Junior absorbs it; the Senior raw balance is unchanged.
- The Senior shares are worth `200,168.22 MZUSD` after the warp — the `168.22` is the normal live
  yield stream accruing during the ~2.5-day warp, not loss-shifting. There is no loss and no
  positive extraction beyond ordinary yield.

The M-1 benefit to an enabled-tranche holder is **loss avoidance**, funded by the disabled
tranche's existing holders. A fresh depositor can at most avoid a loss; they cannot withdraw more
than they put in.

### Yield sniping (residual, bounded)

`test_yield_sniping_bounded_by_reported_yield`:
- A pending NAV of `1,000 USDC` is submitted.
- The attacker deposits `1,000,000 MZUSD` into the Junior before `performUpkeep`.
- After the veto + yield stream, the attacker's share value is `1,001,243.87 MZUSD` — a capture of
  `1,243.87 MZUSD`, of which ~244 is the pre-existing live yield stream and ~1,000 is the reported
  delta. The capture is bounded by the reported yield, **not** proportional to the deposit.

Live ceiling: the current pending delta is `562.34 USDC` per report. Even with unlimited capital,
the absolute per-report capture is ≤ ~$562; with $1M deployed into a $4.7M effective TVL, the
capture is ~$120/report (~$6.2k/yr at 52.6 reports/yr, <0.7%/yr on capital). This is far below the
$10k bar and is not a viable E-U strategy.

## 6. USDC/wYLDS redemption and allowlist

- `MZUSD` deposits/withdrawals are gated by `AllowlistStub` at
  `0xE417cdb4c52F759F3Ff97bA19bAF0C35402Fb641`, whose `verifyAccount` is `pure` and returns `true`
  for every address. So MZUSD mint/redeem is effectively open in the live deployment (not a
  KYC gate). This does not create a profit path by itself: `deposit` is 1:1, `requestWithdrawal`
  charges 1 bp and is capped by the vault's wYLDS liquidity (307,999.88), and the redemption is
  1:1, not NAV-proportional.
- The `IssuanceVault.withdraw` is `onlyMZUSD`; `distributeYield` is `onlyNavOracle`; `rebalance` is
  `restricted` (role 7); `advanceEpoch` is `onlyLossManager`. No unprivileged vault drain exists.

## 7. Conclusion

- **H-1: CLOSED** — live bytecode contains `OraclesNotInSync`, the feeds are timestamp-synced,
  and the only submitter is a role-6 EOA; the fork test proves a desynced report reverts.
- **M-1: NOT LIVE** — both tranches are enabled. The code path is real (fork-proven: a disabled
  Junior burns 100,000 MZUSD on a 100,000 USDC loss), but it is a fairness/wealth-transfer bug for
  the disabled tranche's holders. A fresh depositor cannot withdraw more than deposited; the only
  residual is bounded yield sniping (~$562/report ceiling), which is sub-$10k and capital-heavy.
- **E-U = $0.**
