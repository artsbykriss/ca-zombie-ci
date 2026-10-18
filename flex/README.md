# Flex — Liquity-v1 fork with share-price oracles

**Date:** 2026-10-18 · **Chain:** Ethereum · **Status:** read-only; fork PoCs only; no mainnet transactions signed or sent.

**Scope:** Flex registry `0x9117440a7d03238905d1c8908157bd7a547c77c8`, its six Trove Managers, the custom `PriceOracle` contracts, the `Lender` (Yearn-v3 TokenizedStrategy) vaults, the `DutchDesk`/`Auction` redemption path, and every live trove at block **26,217,683** (2026-10-18 06:34:11 UTC).

---

## 1. TL;DR

| Question | Answer |
|---|---|
| Live external-unprivileged extractable now | **$0** (high confidence) |
| Why closed | No trove is below the 1.10 MCR; min CR = **1.10127**. `close_zombie_trove` is owner/approved-only. `redeem` is `onlyLender`. The oracles are share-price (pps) or Curve-EMA feeds, not spot pools; a donation cannot profitably inflate them (cost > borrow gain). No idle Lender USDC to borrow at scale. |
| Holder-only recoverable (H-O) | **$10,287.34** in 4 zombie troves (debt 0, collateral still held). Six other zombies (~$25,161) were claimed by their owners between the first scan and the snapshot — the path works and is being used. |
| Conditional E-U | **$1,737.04** demonstrated by fork PoC after a 2% oracle decline (yvcrvUSD trove, partial liquidation). Trigger is a market/oracle move, not attacker-controlled. Interest accrual alone is expected to cross 1.10 in ~9 days (m4), ~11 days (m2), ~34 days (m3), with a first-trigger bonus of roughly **$290–$560**. |
| Privileged (P) | $0 direct drain found. Markets are EIP-1167 minimal proxies (immutable target); oracles are immutable except `DADDY`'s ysyBOLD `set_depeg_mode`. |
| Stuck (S) | $0. |

**Headline: an external unprivileged attacker can extract ~$0 live. The residual value is in a conditional liquidation bonus, not in the oracle/redemption code.**

---

## 2. Mechanism in exact terms

Flex is a Liquity-v1-style CDP protocol where the borrow asset is supplied by a **Yearn-v3 `Lender` vault** rather than minted. Each market is a `Trove Manager` + `SortedTroves` + `Dutch Desk` + `Auction` set; the registry only lists endorsed markets.

1. **Deposit / borrow.** `open_trove` pulls collateral and records debt. The MCR is 1.10, the safe CR 1.20. Borrow tokens are delivered from the Lender's idle USDC; if idle is insufficient, the Trove Manager calls `_redeem` on the lowest-interest-rate troves, takes their collateral, and kicks a Dutch auction whose proceeds go to the borrower (the “airdrop” path). Debt is the full `debt_amount + upfront_fee`.
2. **Oracles.** The six markets use five different custom oracles:
   - `yvUSD` → `IYearnVault.pricePerShare()` (market 0), and a Morpho-wrapper of the same pps (market 2);
   - `siUSD` → `IERC4626.convertToAssets(1e18)` with iUSD **assumed $1** (market 1, empty);
   - `ysyBOLD` → ysyBOLD→yBOLD→BOLD exchange rates × BOLD/USDC Curve **EMA**, capped at 1.01; the 0.99 floor is disabled (`depeg_mode = true`);
   - `yvcrvUSD` → yvcrvUSD→crvUSD pps × crvUSD/USDC Curve **EMA**, capped at 1.01, no floor;
   - `yvWETH` → Morpho-wrapper of the yvWETH pps in WETH (market 5).
   All are **NAV / pps** feeds. None reads a DEX spot reserve that an attacker can move with a flash loan.
3. **Redemption / exit.** External users cannot redeem. `TroveManager.redeem` is `onlyLender`; the Lender's `_freeFunds` calls it to serve withdrawals. The Trove Manager takes collateral from the lowest-rate troves at the oracle price and kicks a Dutch auction with a 1.00× starting price and a 0.99× minimum. Proceeds up to the redeemed debt go to the withdrawing receiver; any surplus goes to the Lender.
4. **Liquidation.** `liquidate_trove` is permissionless. The liquidator repays debt and receives collateral plus a dynamic 0.5%–5% fee, interpolated between CR 1.10 and 1.05.

There is no permissionless market creation in the registry (`endorse` is `only DADDY`). The market contracts are **EIP-1167 minimal proxies** (`363d3d373d3d3d363d73…`), so the implementation cannot be swapped.

---

## 3. Live-state assessment (block 26,217,683)

### 3.1 Registry and markets

Registry `0x9117440a7d03238905d1c8908157bd7a547c77c8`: `markets_count() = 6`, `DADDY = 0x4e8341C77c94cCE982AB96d92BB28D69f4638290`.

| # | Market | Collateral | Borrow | Oracle | `total_debt` | `collateral_balance` | Lender `totalAssets` |
|---|---|---|---|---|---|---|---|
| 0 | `0xd82DB989…2e49` | yvUSD `0x696d02Db…6987` | USDC | `0x6D8D09F1…4206` | 147 wei | 24,308.754188 yvUSD | $2,001.18 |
| 1 | `0x484E3c28…C09D` | siUSD `0xDBDC1Ef5…9bCB` | USDC | `0x38cAe071…A15a` | 0 | 0 | $0 |
| 2 | `0x8ee72c38…83c9` | yvUSD | USDC | `0xDB8DBB6c…7D2e` | $604,703.18 | 674,507.205395 yvUSD | $604,459.44 |
| 3 | `0xADf4E022…Fc6E` | ysyBOLD `0x23346B04…91cD` | USDC | `0x40556811…BaE65` | $188,407.10 | 224,565.623681 ysyBOLD | $211,035.47 |
| 4 | `0x7582b474…eA2E` | yvcrvUSD `0xBF319dDC…805F` | USDC | `0x01821e20…a8b2` | $100,587.15 | 97,198.005272 yvcrvUSD | $100,552.48 |
| 5 | `0xEe27D81B…334C` | yvWETH `0xac37729B…7571` | WETH | `0x4e2cad94…b96c` | 310.141929 WETH | 325.340671 yvWETH | 310.055350 WETH |

Lender addresses: m0 `0x33C45216…B732`, m1 `0x9a28d962…2456`, m2 `0xD93Dade7…e8bA`, m3 `0xf4996Ca4…a03C`, m4 `0xc1F281a3…ec84`, m5 `0x0d57098E…9e36`.

**Live oracle prices:** yvUSD **$1.035049**, siUSD **$1.095252**, ysyBOLD **$1.094808** (`depeg_mode = true`), yvcrvUSD **$1.160030**, yvWETH **1.090920 WETH**. DefiLlama NAV marks match the oracles to <0.1%.

**Protocol-held value:** Lender assets **$1,665,480.5** at WETH $2,410.45, plus **$10,287.34** zombie collateral = **$1,675,767.8**. (DefiLlama's $1.9M counts gross collateral / a different WETH mark; the Lender receivables are the real protocol pot.)

**Borrowable idle:** m0 $2,002.19; m3 $22,775.92 USDC; m2/m4 $0; m5 0.009731 WETH. A new trove can borrow only ~$24.8k immediately; anything larger requires forcing redemptions of existing troves.

### 3.2 Troves

At the snapshot: **27 active**, **4 zombie**, 79 closed/liquidated among the 110 open-event troves with a readable struct.

| Market | Active troves | Debt | Collateral value | TCR | Min CR |
|---|---|---|---|---|---|
| m2 yvUSD | 9 | $604,965.79 | $695,563.93 | 1.1498 | **1.10175** |
| m3 ysyBOLD | 6 | $188,437.42 | $238,152.97 | 1.2638 | **1.10257** |
| m4 yvcrvUSD | 6 | $100,628.61 | $112,752.57 | 1.1205 | **1.10127** |
| m5 yvWETH | 6 | 310.15 WETH | 354.92 WETH | 1.1444 | 1.1018 |

Closest positions:
- m4 `9952961746…61515`: debt **$56,881.25**, collateral 48,520.18 yvcrvUSD, **CR 1.10127**;
- m2 `2405732447…68cdd`: debt **$98,477.14**, collateral 104,823.31 yvUSD, **CR 1.10175**;
- m3 `7965717729…41230`: debt **$53,619.66**, collateral 54,000.00 ysyBOLD, **CR 1.10257**.

None is below 1.10, so **no liquidation is possible today**.

### 3.3 Zombie troves (H-O)

Four zombie troves remain, all `debt = 0`, `status = ZOMBIE (2)`, with collateral still in the Trove Manager:

| Market | Trove | Collateral | USD at oracle | Owner |
|---|---|---|---|---|
| m2 | `5656160806…49573` | 1,521.880100 yvUSD | $1,575.22 | `0x5555e978…2ff5` (EOA) |
| m2 | `6036536838…32952` | 488.673642 yvUSD | $505.80 | `0x8d54e7f0…c198` |
| m2 | `2117511052…21320` | 486.019162 yvUSD | $503.05 | `0x7706ea31…f3c1` |
| m3 | `7843321952…92196` | 7,036.181988 ysyBOLD | $7,703.27 | `0xa8b4c7f8…4c4c` |
| **Total** | | | **$10,287.34** | |

Six other zombies (the m0 set, ~$25,161) were **claimed by their owners** between block 26,217,430 and 26,217,683 — the mechanism is live and is being used.

`close_zombie_trove` requires `trove.owner == msg.sender || approved[owner][msg.sender]` (line 866 of the verified source). A random caller reverts; the fork test proves both the revert and the owner claim.

### 3.4 Roles / upgradeability

- Market contracts are **EIP-1167 minimal proxies** to an immutable implementation; EIP-1967 impl/admin slots are zero. No market upgrade key.
- `Registry.endorse` / `unendorse` are `only DADDY` (EOA `0x4e8341…8290`). `DADDY` can also toggle the ysyBOLD oracle's `depeg_mode` (currently `true`, floor off). It cannot move market funds.
- Lender is a Yearn-v3 TokenizedStrategy; `report` is keeper/management, `setDepositLimit` is management. No drain path reviewed.

---

## 4. What an attacker can and cannot do

### Cannot
| Path | Gate | Live value |
|---|---|---|
| Liquidate a trove | `require(collateral_ratio < 1.10)` | min CR 1.10127 → **reverts** |
| Close a zombie | `owner || approved` | 4 zombies, owner-only |
| Call `TroveManager.redeem` | `assert msg.sender == lender` | reverts |
| Steal via `receiveFromStrategy`-style push | not present in Flex | — |
| Donate to inflate a pps oracle | donation raises pps by `D/S`; attacker's collateral is `f·D`; borrow gain `0.909·f·D < D` | unprofitable for any `f < 1.1` |
| Borrow against overvalued siUSD | market 1 has $0 Lender / 0 debt | no pot |
| Drain the Lender | `_freeFunds` sends auction proceeds to the receiver and books the same amount as loss; totalAssets is reduced by the full withdrawal | neutral |
| Take an active auction at a discount | all 31/36/12/8 auctions are fully taken (`current_amount = 0`); Auction collateral balances are 0 | no live auction |

### Can (conditional)
**Liquidation bonus after an oracle decline.** PoC: mock the yvcrvUSD oracle 2% lower, liquidate m4 trove `995296…`. The liquidator repaid **38,962.199322 USDC**, received **35,085.025667 yvcrvUSD**, worth **40,699.237536 USDC** at the real (unmocked) oracle price → **+1,737.038214 USDC** (≈4.46% on capital), gas 1.9M. The same test at the live price reverts (`!collateral_ratio`), proving no live path.

The **trigger is not attacker-controlled**: the oracle is a pps/EMA feed; donation does not lower pps, and the Curve EMA cannot be pushed 2% by a flash loan at acceptable cost. It is a **market-move contingent** opportunity, not an exploit of Flex code.

**Interest accrual is the likely trigger.** At current rates the closest troves cross 1.10 from debt growth alone in roughly:
- m4 `995296…` (5.1% APR): ~9 days → first bonus ≈ **$290**;
- m2 `240573…` (5.3% APR): ~11 days → ≈ **$560**;
- m3 `796571…` (2.8% APR): ~34 days → ≈ **$300**.

These are keeper/MEV rewards, not protocol theft.

---

## 5. PoC / fork verification

Project: `poc/` (Foundry 1.8.5, solc 0.8.24, pinned fork block **26,217,683**).

| Test | Result | What it proves |
|---|---|---|
| `test_min_cr_above_mcr_now` | PASS | min CR 1.101258 > 1.10; `liquidate_trove` reverts at the live price |
| `test_liquidation_after_2pct_oracle_drop` | PASS | 2% oracle drop → CR 1.079232; partial liquidation pays **+$1,737.04** |
| `test_zombie_close_is_owner_only` | PASS | all 4 remaining zombies revert for a random caller; each owner can close and receive the collateral |
| `test_redeem_is_lender_only` | PASS | external `redeem` reverts |

**CI:** https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39105673861 — **4/4 passed**, artifact `result-flex` (`ci-out/flex_live_state.txt`).

---

## 6. Verdict and residual risk

**E-U now: $0 (high confidence).** The market code is a faithful Liquity-v1-style CDP; the custom oracles are NAV/pps or Curve-EMA feeds, not manipulable spot pools. The only live value paths are gated by ownership (`close_zombie_trove`) or by the 1.10 CR (`liquidate_trove`).

**Residual / latent:**
1. **Conditional liquidation bonus** — up to ~$1.7k per near-threshold trove on a 2% oracle move; first interest-driven trigger expected in ~9 days. Monitor every block for `CR < 1.10`.
2. **ysyBOLD depeg-floor switch** — `DADDY` can set `depeg_mode = false`, imposing a 0.99 floor. If BOLD trades below 0.99, the oracle would overvalue ysyBOLD; a borrower could then borrow against overvalued collateral. This is **P-triggered** and not live (`depeg_mode = true` now).
3. **siUSD $1 assumption** — market 1 is empty (0 debt, 0 lender). If it is ever funded and iUSD depegs, the oracle would overvalue siUSD; watch `Lender` deposits into m1.
4. **Curve EMA lag** — ysyBOLD/yvcrvUSD oracles use EMA, not spot; a rapid crvUSD/BOLD depeg would leave them overvalued for a period. No live depeg at the snapshot (crvUSD ≈ $1.00, BOLD ≈ $1.00 implied).
5. **`Auction.take` reentrancy (latent, $0 live).** `Auction.take` has **no `@nonreentrant` modifier** despite the comment “No need to worry about re-entrancy since non-reentrant pragma is enabled” (verified source line 439). `current_amount` is updated before the callback, but `amount_received` is updated after it, so a receiver that reenters `take` can take the remaining collateral while the stale `receiver_remaining` still covers it. With every auction fully taken (`current_amount = 0`) and a 1:1 kick (`maximum_amount` = collateral value at the oracle), the live value is **$0**; the leak only materializes if the oracle rises between kick and take (surplus that should go to the Lender). Not counted in E-U.

**Blockers to any larger claim:** no trove below MCR; no idle Lender liquidity at scale; no permissionless zombie claim; no oracle spot pool; no active auction.

---

## 7. Methodology, sources, caveats, files

- Read verified sources from Etherscan v2: `Registry`, `Trove Manager` (96 KB Vyper), `Price Oracle` (5 variants), `Lender` + Yearn TokenizedStrategy, `Dutch Desk`, `Auction`.
- Enumerated all six markets from `Registry.markets(i)`, all `OpenTrove` logs, and read every trove at block 26,217,683. Re-read oracles, Lender `totalAssets`, idle balances and auction state at the same block.
- Fork-tested the four claims in `poc/` on a pinned mainnet fork. No mainnet transaction was signed or sent.
- **Caveats:** the snapshot is point-in-time; the zombie set is shrinking as owners claim. The 2% drop PoC is a mechanics proof, not a price forecast. The `total_debt` figure is not `sync_total_debt()`-refreshed; trove-level `get_trove_debt_after_interest` is used for CR. DefiLlama's $1.9M is gross collateral, not Lender receivables.

**Files:** `analysis/flex_market_config.json`, `analysis/flex_snapshot_26217683.json`, `analysis/flex_troves_26217683.json`, `analysis/flex_active_troves.json`, `analysis/flex_lender_state.json`, `analysis/src/` (verified sources), `poc/test/FlexFork.t.sol`, `ci-out/flex_live_state.txt`, `ci-log.txt`, `ci-artifacts/`.
