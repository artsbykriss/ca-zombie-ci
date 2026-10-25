# Evidence — Wager Predict (BSC, chainid 56) — raw on-chain citations

All calls are read-only `eth_call`/`eth_getCode`/`eth_getLogs` at the stated block via a **keyless** public RPC
(`https://bsc-rpc.publicnode.com`). Reproduce with `analysis/collect_live_state.py`.

Blocks: **129,591,335** (first read, ts 1,792,883,482) and **129,703,426** (re-read, ts 1,792,930,261).

## A. USDW wrapper (impl verified)

| Call | Result |
|---|---|
| `0xe5eBE2AE…getsourcecode` (chainid 56) | `TransparentUpgradeableProxy` proxy=1, impl=`0x7169d192b5e2add3268651cf598886af42518cd8` |
| `0x7169d192…getsourcecode` | `USDW` verified, solc 0.8.24, 36 sources (LockMint20, Administrator, PriceOracle, AccessControl, MathLib) |
| `USDW.totalSupply()` | 202545410567 (202,545.410567) |
| `USDW.paused()` | false |
| `USDW.priceOracle()` | `0x5c3a3b430E44bD18Fd7f29Cb3Ec1948Bac542a9A` (proxy → impl `0x0c1337a5ec095c4a93886cb787b94c0d55727a72`, `PriceOracle`, verified) |
| `USDW.depositRecipient()` | `0x255E92b8e79800349f137d5b8EA70c0B658fd397` — **eth_getCode = 0x (plain EOA)** |
| `USDW.redemptionSource()` | `0x959b4a9Ad2dD1beBfD2579121325a75768C4D024` — **eth_getCode = `0xef0100 || 0x03a46a241aa7073552652032aba85be46f647795` (EIP-7702 delegated EOA)** |
| `USDW.treasury()` | `0xB445A0A6eb574BA3d3Dcd0e81619a9240b85aa94` (EOA) |
| `USDW.administrator()` | `0xc2Dc9aad79Ab63D2772fb65Ce106584979DF610e` (proxy → impl `0x7a581645aa93094661453941d1f2d56553420fd4`, `Administrator`) |
| `USDW.isInputStable(0x8ac76a51…USDC)` | true (the only approved input stable; from `InputStableAdded` log at block `0x757c823`) |
| `PriceOracle.getOracleConfig(USDC)` | `(aggregator=0x51597f405303C4377E36123cBc172b13269EA163, maxStaleness=3600, soft=50, hard=500)` |
| Chainlink `0x51597f40…latestRoundData()` | answer 99,983,535 (8dp) = $0.99983535; age 387s (fresh) |
| `PriceOracle.quoteUsdwMint(USDC, 1e18)` | 1000000 (1 USDC → 1 USDW; par, protocol-favorable) |

**ISSUER_ROLE has no holder.** `Administrator(0xc2Dc9aad…).hasRole(ISSUER=0x76afa8a5…, X)` = false for every
candidate (SpotEngine, Vault, Registry, ResolutionModule, FeeRouter, InsuranceFund, both EOAs, Safe, Timelock,
Owner EOA, LmsrAsMaker). The Administrator `RoleGranted` log (topic0 `0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d`)
contains **only 4 grants**: GOVERNOR→`0xd873d9a8…` & `0x5a3000f7…`; OPERATOR→`0xd873d9a8…` & `0x69ae0036…`.
⇒ `mint/burn/lockTokens/unlockTokens/spendAllowance` are **dead**.

**Backing.** `aBnbUSDC 0x00901a076785e0906d1028c7d6372d247bec7d61.balanceOf(0x255E92b8…)` =
203,882.641 (first read) / **203,893.095** (re-read), 18dp ≈ $203.9k. `USDC-BSC.balanceOf(0x255E92b8…)` = 0.
`aBnbUSDC.allowance(0x255E92b8…, X)` = **0** for X ∈ {SpotEngine, Vault, USDW, Registry, ResolutionModule,
FeeRouter, LmsrAsMaker}. `USDC-BSC.allowance(0x255E92b8…, USDW)` = 0.

**redemptionSource** `USDC-BSC.balanceOf(0x959b4a9a…)` = 213901000000000000 (0.2139 USDC); USDW 0.

## B. SpotEngine

`0x76b91e83f2A12dc52E33f856eeA300E5B3A62c0c.getsourcecode` → `SpotEngine` verified (60 sources; `LMSRMath`,
`PriceAccumulator`, `Governed`, `ProtocolConfig`).

| Call | Result |
|---|---|
| `SpotEngine.usdc()` | `0xe5eBE2AE…` (USDW) |
| `SpotEngine.registry()` | `0x2D7E1000…` |
| `SpotEngine.feeRouter()` | `0x186DCA43…` |
| `SpotEngine.insuranceFund()` | `0x3E3f9379…` |
| `SpotEngine.balanceOf(USDW)` | 173362943506 (first) → **175889930252** (re-read) |
| `Registry.marketCount()` | 21; all `marketState(i)=3` (Listed) |
| `SpotEngine.paused()` | false |

`ProtocolConfig 0x3Ea6Ab92…`: platformBps=100, creatorBps=10, depthBps=80, lpBps=10 (Σ 200 bps); lpFeeDestination
= Vault; treasury = Gov Safe; `permissionlessResolution()=false`.

## C. Vault

`0x88d163d40D6BFe0Ad2b17f4a90A03053fEbf3014` verified. `totalPrincipal()=0`, `positionCount()=0`,
`feeBuffer()=233243495` (first) → **236555097** (re-read), `totalFeeShares()=0`, `accFeesPerShare()=0`,
`outstandingLoans()=0`, `availableLiquidity()=0`. Tier-0: `lockMultipliersBps(0)=10000`, `lockDurations(0)=0`
(no lock); `withdrawalCooldown=86400`.

## D. Resolution / graduation

`0xdfc40D309C0D8f4Cc42863991C8e606eD330e1E8` (`ResolutionModule`, verified): `spot()=SpotEngine`,
`registry()=Registry`, `usdc()=USDW`. `propose()` guard:
`config.permissionlessResolution() || hasRole(RESOLVER_ROLE) || hasRole(GOVERNANCE_ROLE)`; live
`permissionlessResolution()=false`.

`0xB6F097da…` (`LmsrAsMaker`, GRADUATION_ROLE): `migrationGate()=0xF00Da26DA913AA6360AD7e78e23Bd0dCb803b617`
(code present, `canMigrate` selector `d15f88d7` returns false). `curveRouter()=0`, `orderSigner()=0`.

`0x0DAdcFb8…` (Leverage): bytecode is a stub (selectors `44a319f6`/`f230d773` return 0). `LEVERAGE_ROLE` count = 0.

## E. AccessController roles (`0x108b97C4d76B8753232301196796B44Ad2F27bcE`)

| Role | Members |
|---|---|
| GOVERNANCE_ROLE | `0x8f1B33cfDdF0A2Da5a4dDa1E6250c02915ad8CE2` (PredictTimelock) |
| CREATOR / REVIEWER / RESOLVER / PAUSE_GUARDIAN | `0xF39342C6758156df432fc47cDfF0cDd593E6CcC0` (Safe 2/3) |
| TRADE_RECORDER_ROLE | `0x76b91e83…` (SpotEngine) |
| FEE_SOURCE_ROLE | `0x76b91e83…`, `0x186DCA43…` |
| RESOLUTION_ROLE | `0xdfc40D30…` |
| GRADUATION_ROLE | `0xB6F097da…` |
| MM_ROLE / LEVERAGE_ROLE | **none** |

## F. Fork PoC

`poc/test/WagerPredict.t.sol` — run in CI (`forge test -vvv`). Assertions: deposit par + gated mint/burn/lock/
process; buy→sell loss; fuzz no round-trip profit; 10 gated entry points revert for a stranger; unsettled claim
reverts; cannot sell others' shares; Vault fee-buffer capture; backing EOA has 0 allowances.
