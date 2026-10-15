# Oracle deep-dive — Segment Finance (opBNB): why every price path reverts

Read at block **195,761,245** (2026-10-15) via keyless `https://opbnb-mainnet-rpc.bnbchain.org`.
Raw call results: `analysis/state2.json`, `analysis/sim1.json`.

## The price chain (three layers, all single-sourced)

```
Comptroller 0x71ac0e9a…  --oracle()-->  ResilientOracle proxy 0xaacf634d…
   (TransparentUpgradeableProxy, impl 0xe9ad4be42b717b0cd3b38be5d05729b51d0ad469,
    proxy admin 0x982e35f6… owned by the 2-of-3 Safe)
        per-asset config (getOracle(asset, role)):
            main   = 0x15cb42a8bc953ba604cf17dcbaa7d78b235979bf  (enabled)
            pivot  = 0x0 (disabled)     fallback = 0x0 (disabled)
                                    │
                                    ▼
        BinanceOracle proxy 0x15cb42a8bc953ba604cf17dcbaa7d78b235979bf
          (TransparentUpgradeableProxy, impl 0x8769277379fbb80e28666238e98f67ebbdb4fff7,
           proxy admin 0x26016da930ef1670ee22be14b5255a98ce99d963 owned by the Safe)
          feedRegistryAddress() = 0x72d55658242377af22907b6e7350148288f88033
                                    │
                                    ▼
        FeedRegistry 0x72d55658… (Chainlink-FeedRegistry-style: exists/decimals/latestTimestamp/
          getAnswer/proposeFeed/confirmFeed…; owner 0xe4bdbee35744d0c81cf63f4670c4e4ecd17e09f7,
          access controller 0xccfb24799feedf1567e43edd47cdb9130343700a)
```

## Observed failures (all at the live block)

| Call | Result |
|---|---|
| `ResilientOracle.getUnderlyingPrice(seFDUSD/seUSDT/seETH/seBTC/seBNB)` | revert `invalid resilient oracle price` (all five) |
| `BinanceOracle.getPrice(USDT/FDUSD/ETH/BTCB/BNB_ADDR)` | revert `binance oracle price expired` (all five) |
| `BinanceOracle.maxStalePeriod("USDT"/"FDUSD"/"ETH"/"BTCB"/"BNB")` | **0** for every symbol |
| `BinanceOracle.symbols(symbol)` | `""` (no overrides) |
| `FeedRegistry.exists(symbol,"USD")` | **false** for FDUSD, USDT, ETH, BTCB, BNB |
| `FeedRegistry.latestRoundDataByName(symbol,"USD")` | revert `Key does not exist` |
| `FeedRegistry.latestRoundData(USDT-addr, 0x0)` | revert `Feed not found` |
| `ResilientOracle.paused()` | `false` (the oracle is not paused — it is unpriceable) |

`maxStalePeriod[symbol] == 0` makes the staleness test `block.timestamp - updatedAt > maxStalePeriod[symbol]`
true for any non-zero age (and `block.timestamp < updatedAt` reverts the other way), so even a fully fresh
registry entry could not be consumed unless `updatedAt == block.timestamp` exactly. Combined with a registry
that holds **no keys at all**, every price read is permanently invalid.

## No unprivileged revival

| Attempt from a random EOA | Result |
|---|---|
| `ResilientOracle.setTokenConfig(...)` | revert (AccessControl) |
| `ResilientOracle.pause()` / `setAccessControlManager(attacker)` | revert `0x4a3fa293` (AccessControl) |
| `BinanceOracle.setMaxStalePeriod("USDT",86400)` / `setSymbolOverride(...)` | revert `0x4a3fa293` (AccessControl) |
| `BinanceOracle.transferOwnership(attacker)` / `setAccessControlManager(attacker)` | revert `0x118cdaa7` (OwnableUnauthorizedAccount) |
| `FeedRegistry.proposeFeed(a,a,a)` / `confirmFeed(a,a,a)` | revert `Only callable by owner` |

AccessControlManager for both oracle layers: `0x2e81af8bdb43eaacf96d79145b36abc2407cc80a` (owner-gated);
ProxyAdmin owners are the 2-of-3 Safe `0x1f41cfbbf95bac4f5a220700f78dbaa1e34b97d1`.
**Revival is P (governance) — impossible for an external unprivileged actor.**

## Consequences — blocked paths (fork-verified)

Because `PolicyFacet.getAccountLiquidity` → `getHypotheticalAccountLiquidityInternal` → `oracle.getUnderlyingPrice`
reverts, everything that consults account liquidity reverts:

- `borrow(m)` / `borrowBehalf` — revert `invalid resilient oracle price` (verified for a fresh account **and**
  for real borrowers)
- `liquidateBorrow(...)` on real positions — revert (verified on `0x68a01870…` (733 USDT debt) and
  `0xeed518c9…`; both are market members). Only the *empty-account* case returns an error code 3
  without reaching the oracle.
- `redeem`/`redeemUnderlying`/`transfer`/`transferFrom` for any account that is a **member** of the market
  (Compound's `redeemAllowedInternal`/`transferAllowed` bypass the liquidity check only for non-members)
- `enterMarkets` does **not** call the oracle (verified: returns `[0]`), so a non-member stays redeemable —
  this is the H-O path, not an exploit.
- `getAccountLiquidity(holder)` reverts for both whales (`0x8d97998b…`, `0xf8221bdd…`), for the bad-debt
  account, and for every other real holder tested ⇒ their ≈$5.6k of claims are frozen.

## Timing of the failure

- The protocol was still fully functional on **2026-05-19** (block 144,381,129): a real liquidation
  succeeded then — tx `0xb88d70267cbc00cf8e89ac0115e7a6c3ae2408ed1028810f74152a6087216dc4`
  (liquidator `0x7765b930…` repaid 0.784141 USDT of `0x68a01870…`'s debt, seized 0.011614 seETH, then
  redeemed it) — a path that requires valid oracle prices.
- Since then only oracle-free operations appear in the log history: non-member redemptions
  (2026-07-12 block 163,095,580 seETH; 2026-10-13 block 195,199,920 seBNB, tx
  `0x5f22a29b93605a49f0e39c5e3b02af1e71b238c01ba9f10fe81a3f999c3c3cbd`) and repayments.
- ⇒ the oracle broke between 2026-05-19 and 2026-10-13; the exact block cannot be pinned with a
  non-archive public RPC (historical `eth_call` returns `missing trie node`).

## Manipulability

Not applicable while dead; for completeness the design is **not** DEX-spot based: the only source is the
BinanceOracle reading a Chainlink-style FeedRegistry keyed by symbol names, with no pivot/fallback oracle.
There is no attacker-controllable price input anywhere in the chain.
