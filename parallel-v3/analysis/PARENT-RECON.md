# ZH4-PASS7 residual lane — recon notes (parent → child handoff)

Lane: `p7-oracle-residual` (unresolved-LOW tail of `zombie-hunt-iv/pass7/oracle.md`).
Targets: Flying Tulip Lend (~$9.1M, oracle unlocated), Parallel V3 (Diamond), Sturdy V2 (Ethereum isolated lending).

## Live recon performed by parent (Ethereum, keyless publicnode, block ~0x190dedb = 26,275,547; re-read at your own block)

### Flying Tulip Lend
- DefiLlama slug `flying-tulip-lend`, category Lending, chains Ethereum/Sonic/BSC, TVL ≈ $9.17M, audits `docs.flyingtulip.com/risks`.
- Ethereum: `LendingLens` proxy `0x3682168023e6ba8d1f995fda1d920827c5a8a43e` (impl `0x054c80b91b39fc4f84ef0ecd53bbb53163229795`).
  - `pm()` → `PositionsManager` proxy `0xbe4050a73a7fb384c65e885a15c33461a4b20055` (impl `0x89b6f9179671c0b471734b897e31f8760a94dc53`).
  - `config()` → `ConfigRegistry` proxy `0xa8777c3d446fa7f0b0fc97a80c1ea1d37f1ca33e` (impl `0x897bded2d9ac7478208958d14b2133d6d7506b17`).
  - ConfigRegistry `.oracleRouter()` → `0xe4372db43d2814750a19b93950157ad81d93674a` (impl `0xefd7d5471839e8cf1ee4cd6078de720262b705e9` = **`OracleRouterChainlink`**).
- **Oracle type CONFIRMED = Chainlink passthrough** (`OracleRouterChainlink`): per-asset `heartbeat` staleness check, `deviationBps` clamp vs `lastGoodPriceWad` anchor, `fallbackOnStale` → returns the (possibly stale) anchor. `priceUSD(asset)`→USD WAD; `exchangeRate(st,base)` for LST pairs (optional price-ratio fallback).
- `marginHfSafeBps = 15000`, `marginHfTargetBps = 12500`.
- Ethereum reserve wrappers (ftYieldWrapperV2): ftUSDC `0xD2e4A5ac4B4Da102317cF7C9A1289aDF082639E2`, ftUSDT `0x28b0905d83BCe5FFA6c54651F25858828A38123B`, ftWETH `0x460494aF61BcB92B59797B4e09C26A5ADecb2da2`, ftWBTC `0x1A5730c71576D77048E9FdC79DD40e4B1E8Fe042`, ftFT `0x7127BB9d9ad0f47B8dA9087e634D67F3946F840E`, ftWstETH `0x01980BD1B58313bD3767f6adc75Af8b6464f3db7`, ftcrvUSD `0xa41686c6018056b44a7027f4c912e6153cfb5c63`, ftscrvUSD `0xefab1b1856bbe0b6d78f2552614e34efad1eb6c6`, ftUSDG `0x8b419a64d95738b3dfcb55a35da7918dfd366bb0`, ftsUSDe `0xbc940f911744670523c3d4ebc56e1e28489591d7`.
- Lens ABI used by the DefiLlama adapter: `assetState(address)→(uint256 cash,uint256 borrows,uint256 reserves,uint256 utilWad)`, `getBalance(address,address)→(uint256 avail,uint256 holdBal)`.
- Sonic lens (same CREATE2) `0x3682168023e6ba8d1f995fda1d920827c5a8a43e`; BSC lens `0xc374d2ae274f31bf53c561d0b4024136cc692f48`.
- Corpus note (`residual-recon/analysis/d2d.md:46`): parked because "hybrid PCA/PUT soft liquidation; not scoped".

### Parallel Protocol V3 (Diamond / EIP-2535)
- DefiLlama slug `parallel-protocol-v3`, category CDP, TVL ≈ $908k, chains Ethereum/Base/Avalanche/Sonic/Hyperliquid.
- Ethereum `DiamondProxy` `0x6efeDDF9269c3683Ba516cb0e2124FE335F262a2` (impl facet-cut `0xf659fac08300d204f84af28f66ea3d630acaa72c`). `facets()` → 9 facets:
  - `0x58426574855da7a8c47e1d134d51fd17dca5129b` (1: `1f931c1c` diamondCut)
  - `0x4731f7c0a3b670f78ccb2e3620ae636465ca5279` (4: loupe)
  - `0x81a85266ca7dfcfe48a58349e15b258a91d68945` (15)
  - `0xf659fac08300d204f84af28f66ea3d630acaa72c` (6: `629feb62 4eec47b9 603b4327 b607d099 3ae308fa f92c72bc`)
  - `0x5ab916f3f3f834a5289d520077185ff8a9523eb9` (1: `05b41934`)
  - `0x5db9553cf9bdfcc78d02f5d5d474ccb2f167bfc7` (32, incl `b7181361` getCollateralList)
  - `0x6c58bd89f3a50a97ae39136d4044b70034cfce24` (8)
  - `0x3607e2f9fca2f18a9a13225e61b68af7f9f8bc5c` (5)
  - `0x72330ea0f4b4283a948314697665330b9a7afac0` (2)
- `getCollateralList()` (Ethereum) = [`0xcacd6fd266af91b8aed52accc382b4e165586e29`, `0xcf62f905562626cfcdd2261162a51fd02fc9c5b6`, `0x4c9edd5852cd905f086c759e8383e09bff1e68b3` (**USDe**), `0x9d39a5de30e57443bff2a8307a4256c8797a3497` (**sUSDe**)].
- Other chains' Parallelizer: avax `0x41d58951cbd12D4Ef49b0437897677bbF5547C80`, base `0xC3BEF21Ea7dEB5C34CF33E918c8e28972C8048eD`, sonic `0xBEFBAe2330186F031b469e26283aCc66bb5F8826`, hyperliquid `0x1250304F66404cd153fA39388DDCDAec7E0f1707`.
- Model: "over-collateralized … mint stablecoin against an approved basket of yield-generating correlated assets **at the oracle price** and redeem without cooldown."

### Sturdy V2
- DefiLlama slug `sturdy-v2`, category Lending, TVL ≈ $229k, chains Ethereum/Mode/Optimism/Linea/Flow/Sei.
- Ethereum `AggregatorDataProvider` `0x69764E3e0671747A7768A1C1AfB7C0C39868CC9e` (not a proxy). `getStrategies()` = `0xb49a60bb` → **23 strategies**; `getVaults()` = `0x44d00f82` → 12 vaults.
- Strategy struct fields: `deployedAt, pair, pairData{ asset, assetSymbol, assetDecimals, collateral, collateralSymbol, collateralDecimals, rateContract, oracle, depositLimit, ratePerSec, fullUtilizationRate, feeToProtocolRate, maxOacleDeviation (typo in ABI), lowExchangeRate, highExchangeRate, maxLTV, protocolLiquidationFee, totalAsset, totalCollateral, totalBorrow, version }`.
- Decoded Ethereum strategies (block ~0x190dedb) — oracle / maxLTV:
  - 0 `pair 0x7578f31cc44fdf2f123a6f84c42f702f9c990091` asset crvUSD `0xf939e0a03fb07f59a73314e73794be0e57ac1b4e` coll `0x7ca00559b978cfde81297849be6151d3ccb408a9` oracle `0x1121ddd2007d2c6677e9987e289c3d52aaa9668c` maxLTV 90000 tA 57.3e18 tC 116.2e18 tB 15.3e18
  - 1 asset crvUSD coll `0xd901dcf4948a29d7d9d7e015aaf61591825ac267` oracle `0x3bd929574ff5dea4a23d3bb3b1ad0b95d0fe1e1d` maxLTV 85000
  - 2 asset crvUSD coll `0x241add131b9aaa7527132b752252b99420937adc` oracle `0xdb6ce32d36a9d807bab0c3947b31b06706758492` maxLTV 90000
  - 3 asset crvUSD coll `0x8176b059bd8f63aeb7e20282b12d243b4626e2ae` oracle `0x680f851a3796ab1aa1204ca8dd2214ef170d1a2d` maxLTV 90000
  - 4 asset WETH coll `0xd33dad974b938744dac81fe00ac67cb5aa13958e` oracle `0xa34fe4d13ca737d0b1f8d9c169cbd044c56f17ad` maxLTV 85000
  - 5 asset WETH coll `0xfd6db5011b171b05e1ea3b92f9eacaeeb055e971` oracle `0x3723d77a72e829cb367b4f0cdf35b9b95dc3e57d`
  - 6 asset WETH coll `0xb5b29320d2dde5ba5bafa1ebcd270052070483ec` oracle `0x1f4b81f8d61dda8a2752be59a9af9a9fb37c9ead`
  - 7 asset WETH coll `0xf951e335afb289353dc249e82926178eac7ded78` oracle `0xfef192cabf37a2396a8665f42f9a499a52baa185`
  - 8 asset `0x04c154b66cb340f3ae24111cc767e0184ed00cc6` (sUSDe?) coll `0x2c8a33c66c00264316ea4e4433e86a386eb6ecbf` oracle `0xd12b45a5ba878d4b406886a7876061306712b2f0`
  - 9 asset WETH coll `0xc69ad9bab1dee23f4605a82b3354f8e40d1e5966` oracle `0xa621a3809fda139c7aa63d7736d2e3eb0b351d0b`
  - 10 asset WETH coll `0x5cb12d56f5346a016dbba8ca90635d82e6d1bcea` oracle `0x22436aed9fe5a6408537e748280cb25a6d78978b`
  - 11 asset WETH coll `0xb05cabcd99cf9a73b19805edefc5f67ca5d1895e` oracle `0x49c27c15dbb239c4943c5f86361da724f8d1f8af`
  - 12 asset WETH coll `0xa1290d69c65a6fe4df752f95823fae25cb99e5a7` oracle `0xdeda72c39b7b2fb0433af9cfc21031d5ef3b126a`
  - 13 asset `0x40d16fc0246ad3160ccc09b8d0d3a2cd28ae6c2f` (GHO) coll `0xac22e3a3cfe4dc82ffd4ffa7453729ca963ceb5a` oracle `0x50710f355652439f7fcc752c58c15e6ae7626092`
  - 14 asset GHO coll `0xbccce9991d2c8a8056d677c0c52c20ac901f39ec` oracle `0x85db1a4ec3fc2dd880ae81464b1b946caa71c708`
  - 15 asset sUSDe coll `0x9ba021b0a9b958b5e75ce9f6dff97c7ee52cb3e6` oracle `0x0acd9d715e354861fe68d3cf339b9427d09a77ae`
  - 16 asset USDC `0xa0b86991…` coll `0x35d8949372d46b7a3d5a56006ae77b215fc69bc0` oracle `0x0d1039bec12cb320161bbd5578c62f1f8294d4b3`
  - 17 asset WBTC `0x2260fac5…` coll `0x8db2350d78abc13f5673a411d4700bcf87864dde` oracle `0xe8384d78667dfc4b4d5eae90308ea95a58229166`
  - 18-22 further (GHO/WBTC/USDC) with oracles `0x0b70f709… 0x9ce963c9… 0x4bd8bcd7… 0xeee4ecdd… 0x78852021…`
  - ⚠ `maxOacleDeviation` decoded as **0 for every strategy** — VERIFY with `cast` using the exact ABI (could be a decode/units issue; this is the crux).
- V1 had the **$800k oracle-manipulation hack (2023)**. V2 = two-tier: base risk-isolated pairs + aggregation vaults; per-strategy `oracle` + `maxOracleDeviation` + `lowExchangeRate/highExchangeRate` bounds.

## Shared rules
- Read-only mainnet; fork-only PoCs; heavy work in CI (`bash /home/heisenberg/CA/ci/ci-run.sh <folder>`); no secrets/keyed RPC URLs in files.
