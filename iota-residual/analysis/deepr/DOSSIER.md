# Deepr Finance (IOTA EVM) — adversarial dossier (L2-20)

*Read-only research. No transaction was signed or sent. State read from keyless public RPC
(`https://rpc.ankr.com/iota_evm`, chain id 8822) at block 13,020,635–13,020,710 (2026-10-15 ~08:49–09:35 UTC)
and Blockscout (`https://explorer.evm.iota.org`) for verified sources.*

**Bottom line: E-U = $0 (high confidence).** Every value-moving component is a faithful, verified Compound-V2
fork or a standard MasterChef pool; the oracle is a clean owner-only Supra adapter; the admin is a Gnosis Safe.
The only theoretical unprivileged extraction is **$0.20** of dust liquidation bonuses (28 underwater positions,
total shortfall $0.87, total debt $4.94). Live holder-recoverable value ≈ **$141.6k cash** (supplier claims
$177.1k); ~$13.3k of DEEPR sits in the reward contracts.

---

## 1. System map (IOTA EVM, chain 8822)

| component | address | verified source | role |
|---|---|---|---|
| Unitroller (proxy) | `0xee07121d97FDEA35675e02017837a7a43aeDa48F` | `Unitroller.sol` | Comptroller storage/proxy |
| Comptroller impl | `0x4B13e770b29b80D8AEa25Ab909D2CdB8b935C20D` | `Comptroller.sol` (68 KB) | risk + reward logic |
| cToken delegate | `0x9d2Cc6101bb94cC7052B39d24F45fF1472b98C7F` | `CErc20Delegate` + `CToken.sol` (49.5 KB) | all markets share this delegate |
| dWETH | `0x0f571c5f3c328f57cdddf204d752c7ddb49686d5` | CErc20Delegator | market |
| dWIOTA | `0x260817581206317e2665080a2e66854e922269d0` | CErc20Delegator | market |
| dUSDC.e | `0xf96adbfcd3eb9fd61fada3f2ed70ac47e3e1e045` | CErc20Delegator | market |
| dDeepr | `0x5041af7b6461717d97ea3422dfc61553c1f8f8b4` | CErc20Delegator | **deprecated + paused** |
| Price oracle | `0x580bef00fa3ae215913cccc62a8d0e74160569e8` | `SupraPriceOracleAdapter.sol` | Supra pull-oracle adapter |
| RewardPool | `0x18041c94d941177574a1d79b0c55dd894e9e02bc` | `RewardPool.sol` | MasterChef-style DEEPR staking |
| DEEPR token | `0x4Eb8E03461360C2AcBb4B5963a18b8f9faEE8221` | `Comp` (+ LayerZero OFT mixin) | governance token / rewards |
| admin (Comptroller, markets, RewardPool) | `0x84456E99Fe3e0C0b06E6e48854f9a6D2c56a7cBD` | — | **Gnosis Safe proxy** (345 B, `masterCopy()` = `0xa619486e`, solc 0.7.6) |
| pauseGuardian / borrowCapGuardian | `0x5b5f504F605ac54Eae0953Cd6160B26863a66aaB` | — | pause-only powers |
| DEEPR owner | `0x1355765f7ddc3fd59679f87dfe92e6606fc9d635` | — | token owner (no public mint exists) |

All of these are verified on Blockscout; the sources were downloaded and reviewed
(`src/full/`, `src/deepr/`). Compiler 0.8.10–0.8.20, optimizer on.

## 2. Live state (block 13,020,635; prices = the protocol's own Supra feed at that block)

| market | cash | borrows | reserves | shares (8 dp) | exchange rate | cash USD |
|---|---|---|---|---|---|---|
| dWETH | 34.709753496843065768 WETH | 3.195526119981316555 | 0.002581119480785571 | 186,062,940,180 | 2.0371e26 | $82,133 |
| dWIOTA | 876,552.295616273632828071 IOTA | 257,492.529354803994848810 | 4,424.595410005811469115 | 5,601,929,201,427,486 | 2.0165e26 | $39,708 |
| dUSDC.e | 19,768.674067 USDC | 16,575.988510 | 123.826564 | 148,230,088,467,496 | 2.4435e14 | $19,765 |
| dDeepr | 2 DEEPR | 0 | 0 | **0** | 2e26 (initial) | ~$0.0001 |
| **total** | | **$35,799.91** | **$330.3** | | | **$141,606** |

Prices used: WETH $2,366.43, IOTA $0.0453, USDC $0.99982 (Supra pairs 19/171/89, fresh at read time);
DEEPR $0.00006877 (CoinGecko, 2026-10-15). Supplier claim (cash + borrows − reserves) = **$177,075**.

Comptroller config: `closeFactorMantissa` 0.5, `liquidationIncentiveMantissa` 1.08e18 (8 % bonus),
`maxAssets` 0, `transferGuardianPaused` false, `seizeGuardianPaused` false, no pending admin/implementation.
Borrow caps: dWETH 200 WETH, dWIOTA 3,000,000, dUSDC.e 1,000,000 (all in underlying units).
dDeepr market: `collateralFactor=0`, `reserveFactor=1e18`, `mintGuardianPaused=true`, `borrowGuardianPaused=true`
→ matches the fork's `isDeprecated()` predicate.

Reward contracts: Comptroller holds **65,959,952.64 DEEPR** ($4,536) for lender/borrower accruals;
RewardPool holds **62,686,372.93 staked + 6,997,548.30 locked + 57,734,950.17 unemitted DEEPR** ($8,762 of user
claims + $3,970 of future rewards). `rewardsPerSec` = 0.24 DEEPR/s, `timelockInterval` = 7 days, `trustee` = 0.
`compRate` = 0.923 DEEPR/s split 75.7 % users / 24.3 % team.

## 3. Attack paths tested (adversarial)

| # | path | verdict |
|---|---|---|
| D1 | Oracle manipulation (fake/inflated collateral price) | **closed** — `SupraPriceOracleAdapter`: per-asset config with `pairIndex` + `maxStaleSec`; `getUnderlyingPrice` reverts on unset/zero/stale; **all setters `onlyOwner`**; prices come from Supra's push feed (`getSvalue`), not user input. No public update path |
| D2 | Comptroller reward-index initialization exploit (fresh address claims historic accrual) | **closed** — `distributeSupplierComp`/`distributeBorrowerComp` keep the upstream `compInitialIndex` (1e36) guard verbatim; accrual is proportional to actual cToken/borrow balances. `claimDeepr(holder,…)` is permissionless but only ever credits `holder` |
| D3 | cToken math deviations (mint/redeem/exchange-rate/rounding) | **closed** — deployed `CToken.sol` is line-for-line upstream Compound V2 (timestamp-based `accrueInterest`); `mintTokens = div_(amount, rate)` and `redeemTokens = div_(amountIn, rate)` match upstream exactly (diffed against `compound-finance/compound-protocol/contracts/CToken.sol`) |
| D4 | Liquidation abuse (self-liquidation, seize of wrong collateral, bonus farming) | **closed** — `liquidateBorrowFresh`/`seizeInternal` upstream-faithful; 50 % close factor, 8 % incentive. Liquidatable dust: 28 positions, total shortfall **$0.87**, total debt **$4.94** → max bonus **$0.20**, below gas cost |
| D5 | Empty/deprecated market drain | **closed** — dDeepr has `totalSupply = 0` (nobody can redeem), mint/borrow paused; its 2 DEEPR (~$0.0001) are stuck (S) |
| D6 | RewardPool (MasterChef) accounting exploit | **closed** — standard `_updatePool`/rewardDebt; `harvest()` pays only the caller's own accrual. **Minor quirk found and disproven**: `withdrawRequestAndHarvest()` sets `rewardDebt = (acc − staked·acc)/P = 0` instead of `staked·acc/P`; because `stakedAmount` is zeroed in the same call and re-deposits are blocked until the request completes, no double-claim is possible (a positive debt would instead make a later `harvest()` underflow-revert) |
| D7 | `depositOnBehalf` / `trustee` abuse | **closed** — `trustee == 0`, `onlyTrusted` unreachable |
| D8 | DEEPR token mint (LayerZero OFT `_credit`) | **closed** — `_credit`/`_debit` are `internal`; minting on IOTA EVM happens only via `lzReceive` on the endpoint (OApp endpoint-gated). No public `mint`; `Comp` fork with no minter role. A malicious remote peer would be an owner misconfiguration, not an unprivileged path |
| D9 | Privileged/admin paths | **P** — admin is a **Gnosis Safe** (not an EOA). It can `_reduceReserves` ($330), pause, set CF/oracle, and via `Unitroller._setPendingImplementation` + `_acceptImplementation` replace the Comptroller implementation (upgrade ⇒ drain $141.6k cash). RewardPool owner (same Safe) can `emergencyRewardWithdraw` the reward tokens ($3,970) but **cannot** touch staked user DEEPR |
| D10 | Interest-rate model manipulation | **closed** — 4 verified `BaseJumpRateModelV2` instances; all parameter setters are owner-only; rate is capped by `borrowRateMaxMantissa` |
| D11 | ShimmerEVM deployment | **empty** — DefiLlama chainTvl 0; no value there (not pursued further) |

## 4. Verdict

| category | value | confidence |
|---|---|---|
| **E-U** | **$0** (best case $0.20 of dust liquidation bonuses, below gas) | high |
| H-O | $141,606 cash redeemable now (total supplier claim $177,075); DEEPR stakers $8,762; unclaimed lender rewards $4,536 | high |
| P | market cash via comptroller upgrade ($141.6k) + reserves ($330) + RewardPool rewards ($3,970) | high |
| S | 2 DEEPR in the deprecated market (~$0.0001) | high |

**What would change the verdict**: a Comptroller implementation upgrade to a malicious one (admin), a Supra feed
compromise, or a yet-unpublished deviation in a market added later. None of these are unprivileged.

**Caveats / limits**: (a) the Comptroller implementation source was reviewed at the file level (not formally
verified byte-for-byte against the deployed bytecode beyond selector/length checks); (b) the borrower scan used
`getAccountLiquidity` at one block (184 addresses from borrow logs; totals reconcile with `totalBorrows`);
(c) DEEPR's USD value rests on a thin CoinGecko price; (d) ShimmerEVM was not scanned (DefiLlama reports 0).

## 5. Files

`market_state.json` (per-market state), `deep_state_1792051768.txt` (full snapshot: unitroller, comptroller misc,
Supra feeds, all 4 markets), `borrowers_health.json` (184 borrowers + liquidity/shortfall),
`logs_borrow_*.json` (borrow event scans), `src/deepr/Comptroller.sol`, `src/deepr/RewardPool.sol`,
`src/deepr/DEEPR_token.sol`, `src/deepr/CToken_deployed.sol`, `src/full/*.sol` (all verified sources),
`src/*.json` (raw Blockscout responses), `selector_scan.txt` (deployed selector inventories),
`scan_borrowers.py`, `deep_state.sh`.
