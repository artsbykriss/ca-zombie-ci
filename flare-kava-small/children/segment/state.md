# Segment Finance (opBNB) — live-state dump

All reads at **block 195,761,245** (2026-10-15), keyless public RPC
`https://opbnb-mainnet-rpc.bnbchain.org`. Call data in `analysis/state1.json`, `analysis/state2.json`,
`analysis/sim1.json`, `analysis/live_positions.json`, `analysis/holders_live.json`.

## Contract map

| Role | Address | Notes |
|---|---|---|
| Comptroller (Unitroller) | `0x71ac0e9a7113130280040d0189d0556f45a8cbb5` | proxy; admin/pendingAdmin/impl at slots 0–3 |
| Comptroller impl (Diamond) | `0xae2a97297ea09f82229076c9caff7c00a6140817` | 8,577 B; 4 facets |
| Diamond facets | `0xc708fa2d…`, `0x5fa78303…`, `0x6e5530b5…`, `0x1d6c4696…` | Market / Policy / Reward / Setter |
| Docs "Comptroller (beacon)" | `0xba3835ed56a8b705a202642a83595cddc5b7b729` | **no code** (stale docs entry) |
| Admin (Safe) | `0x1f41cfbbf95bac4f5a220700f78dbaa1e34b97d1` | Gnosis Safe 1.3.0 proxy, **2-of-3**, masterCopy `0xe2cf742b…` |
| Safe owners | `0x97a1644f…`, `0x1ac51371…`, `0x14e7c230…` | 3 EOAs |
| ResilientOracle (proxy) | `0xaacf634dd705d37e94c38ea68384e669d2b4d491` | TransparentUpgradeableProxy |
| ↳ implementation | `0xe9ad4be42b717b0cd3b38be5d05729b51d0ad469` | |
| ↳ proxy admin | `0x982e35f6c693efe0ee253fba622ce443089c6b79` | owner = Safe |
| ↳ access control | `0x2e81af8bdb43eaacf96d79145b36abc2407cc80a` | |
| BinanceOracle (proxy) | `0x15cb42a8bc953ba604cf17dcbaa7d78b235979bf` | the *only* price source |
| ↳ implementation | `0x8769277379fbb80e28666238e98f67ebbdb4fff7` | |
| ↳ proxy admin | `0x26016da930ef1670ee22be14b5255a98ce99d963` | owner = Safe |
| ↳ feed registry | `0x72d55658242377af22907b6e7350148288f88033` | Chainlink-style FeedRegistry, owner `0xe4bdbee3…` (contract) |
| Market impl (shared) | `0xbe7c6bed5c0b79c3be45b1013f12a98c533c4798` | `SeBep20Delegate`, Compound CToken semantics |

Everything above is admin = the 2-of-3 Safe or the Safe-owned ProxyAdmins, except the FeedRegistry
(owned by an external contract; its write functions revert "Only callable by owner").

## Comptroller state

- `admin = 0x1f41…97d1`, `pendingAdmin = 0`, `comptrollerImplementation = 0xae2a…0817`, `pendingImpl = 0`
- `oracle = 0xaacf…d491`, `closeFactorMantissa = 0.5e18`, `liquidationIncentiveMantissa = 1.1e18`, `maxAssets = 0`
- `pauseGuardian = 0`, `protocolPaused() = false`
- `allMarkets(0..4)` = the five markets below; `allMarkets(5)` reverts ⇒ exactly 5 markets
- Reward surface: `getSEFAddress() = 0` (**SEF never wired**), `segmentAccrued(any) = 0`,
  `segmentSupplySpeeds/segmentBorrowSpeeds = 0`, `claimSegment(addr)` is a no-op returning success,
  `_grantSEF` is admin-gated ("only admin can"). Treasury/SEUSD wiring: `treasuryAddress = 0`,
  `treasuryPercent = 0`, `seusdController = 0`.
- Pause flags: legacy `mintGuardianPaused`/`borrowGuardianPaused`/`transferGuardianPaused`/`seizeGuardianPaused`
  functions do not exist on the deployed diamond ("Diamond: Function does not exist"); the action-based
  pause map could not be probed — irrelevant, since the oracle freeze already blocks every path
  (see oracle.md §Blocked paths).

## Markets

| Market | Underlying | CF | cash | borrows (stored → current) | supply (seTok) | exchRate (stored → current) | borrowIndex | last accrual |
|---|---|---|---|---|---|---|---|---|
| seFDUSD `0xfe62ba74…` | FDUSD `0x50c57259…` | 0.77 | 173.60395 FDUSD | 147.955 → 169.050 | 1.5575e12 | 2.0646e26 → 2.2000e26 | 1.0564e18 | 65,471,838 |
| seUSDT `0x7add376c…` | USDT `0x9e5aac1b…` | 0.77 | **1 wei** | 1.1885e21 → 2.0868e21 | 1.8524e12 | 6.4157e26 → 1.1265e27 | 3.2516e18 | 153,196,838 |
| seETH `0x81b98b28…` | ETH `0xe7798f02…` | 0.75 | 0.040920 ETH | 0.22508 → 0.51163 | 5.2875e8 | 5.0308e26 → 1.0450e27 | 3.7147e18 | 163,095,580 |
| seBTC `0x56755816…` | BTCB `0x7c6b91d9…` | 0.75 | 0.0019272 BTC | 0.0035732 → 0.0125131 | 2.4988e7 | 2.2012e26 → 5.7788e26 | 1.1911e18 | 72,359,914 |
| seBNB `0x7e844423…` | native BNB | 0.65 | 0.359716 BNB | 0.633601 → 0.635906 | 4.0327e9 | 2.4631e26 → 2.4689e26 | 1.48797e18 | 195,199,920 |

- All markets: `reserveFactorMantissa = 0`, `totalReserves = 0`, `admin = Safe`, `pendingAdmin = 0`,
  `comptroller = 0x71ac…`, `decimals = 8`, `isSeToken() = true`.
- Borrow caps (raw): FDUSD/USDT 130,000e18; ETH 15e18; BTC 0.55e18; BNB 75e18.
- Supply caps (raw): FDUSD/USDT 150,000e18; ETH 25e18; BTC 1e18; BNB 100e18.
- The four ERC20 markets are `SeBep20Delegator` proxies pointing at the shared impl; **seBNB is a direct
  native contract** (`mint()`, `repayBorrow()`, `liquidateBorrow(address,address)` payable; no
  `implementation()`, no `mint(uint256)`).
- The markets implement `mintBehalf(address,uint256)` and `borrowBehalf(address,uint256)`
  (Venus-style delegated borrow); `borrowBehalf` reverts "not an approved delegate" for a random caller.
- `initialize(...)` on a market reverts "only admin may initialize the market" (no re-initialization).
- Interest accrual is heavily overdue on seUSDT/seETH/seBTC: `totalBorrowsCurrent` is 1.76× / 2.27× / 3.50×
  the stored value. Any call to the market (`accrueInterest`, `mint`, `redeem`, ...) accrues it.

## USD value (prices 2026-10-15T09:47Z, DefiLlama/CoinGecko)

| Market | cash | borrows (current) | claims (cash+borrows) | cash cover |
|---|---|---|---|---|
| seFDUSD | $173.09 | $168.55 | $341.65 | 50.7% |
| seUSDT | $0.00 | $2,084.87 | $2,084.87 | 0.0% |
| seETH | $96.83 | $1,210.67 | $1,307.49 | 7.4% |
| seBTC | $156.14 | $1,013.81 | $1,169.96 | 13.4% |
| seBNB | $259.27 | $458.33 | $717.60 | 36.1% |
| **total** | **$685.33** | **$4,936.23** | **$5,621.56** | 12.2% |

- Gas: 1,000,000 wei (0.001 gwei) ⇒ a 1M-gas transaction costs ≈ 0.000001 BNB (<$0.001).

## Positions

- Debtor set fully enumerated from the complete `Borrow`/`RepayBorrow` event history (blocks
  19,200,685 → 195,771,482, 1,774 events, 50k-block exhaustive scan). The sum of enumerated debts
  equals `totalBorrows` **exactly for all five markets** ⇒ no unknown borrowers. See `borrowers.csv`.
- Notable positions (block 195,761,245):
  - `0x68a0187089e2d1addee1ff35c4b0a7b5988931ea` — **733.26 USDT debt, ~0 collateral** (10 historical
    liquidations drained the seETH collateral). Bad debt; a liquidation would seize almost nothing.
  - `0xeed518c9d0719f016bebcfb3e25c4c9acd00b6c2` — 0.0022 ETH debt vs 0.00008 ETH collateral
    (unprofitable to liquidate: seizable < repay).
  - `0x8d97998b147db2412592cfd56d6efae78670105e` — **83.6% of seFDUSD and 62.3% of seUSDT supply**
    (≈$4.2k of claims) with only ≈$1.6k debt; member of all five markets.
  - `0xf8221bdd9f8615c27c430923353168755b58f81f` — ≈$6.9k of claims, ≈$0.25k debt; member of all five.
  - everyone else: dust.
- Membership: `mint`/`mintBehalf`/`borrow` do **not** add the account to the market; only `enterMarkets`
  does. Both whales (and most suppliers) are members of the markets they hold.
- `getAccountLiquidity(<any real holder>)` **reverts** with `invalid resilient oracle price` ⇒ their
  redeem/borrow/transfer/liquidation is all price-frozen.
- Non-member holders (oracle-free `redeem` is possible for them): seUSDT dust (cash = 0 anyway),
  seBNB ≈0.1945 BNB of claims (≈$140) — and this is being actively redeemed on-chain
  (last: tx `0x5f22a29b…` block 195,199,920, 0.033 BNB, 2026-10-13).
