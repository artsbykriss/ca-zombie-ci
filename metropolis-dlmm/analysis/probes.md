# Metropolis DLMM — raw on-chain probes (read-only)

Chain: Sonic (146) · Public RPC `https://rpc.soniclabs.com` · point-in-time 2026-10-23.
Factory `0x197d40B36677248E82939f96930bf4E7Fe8aD1c2` · sample vault `0x6bE5a84D4A92269eC0Eb228B6c4dAdecED4C7D54` (WETH/wS ≈ $62.7k) · strategy `0x3CD06627E5DAf698F81fdaaD24b6d16DAF209450`.

## Live factory reads (block 81,495,606 via CI `ci-out/live_state.json`)
```
factory_native_balance      = 0
factory_owner               = 0xd1f2823f3aBF4b8c7Ad1B6629421b2618a5e28aF   (Gnosis Safe 1.4.1, threshold 2, 4 owners)
factory_impl_oracle         = 0xe19B636A6ABEe9C14eABB3F64e30c3304859BDB7   (OracleRewardVault)
factory_impl_simple         = 0x0000000000000000000000000000000000000000   (unset)
factory_impl_strategy       = 0x1817134Ad98B72a42AB68cc485fb123AFaC85e80   (Strategy)
factory_creation_fee        = 50000000000000000000  (50 S)
factory_num_oracle_vaults   = 124
vault_strategy              = 0x3CD06627E5DAf698F81fdaaD24b6d16DAF209450
vault_pair                  = 0x9eDE606c7168bb09fF73EbdE7bFD6FcfaBDA9Bc3
vault_total_supply          = 557113578879176291510735572151
vault_operators             = default 0xd1f2823f… / operator 0xA63C0A7007FFFD9eeDd28f4379b7113d916cD329
vault_deposits_paused       = false
strategy_operator           = 0xA63C0A7007FFFD9eeDd28f4379b7113d916cD329
strategy_aum_annual_fee     = 250  (2.5%)
```

## EIP-1967 slots
```
admin slot 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103 = 0x4541cda311ab72420743d03f8f45b42c858046dc (ProxyAdmin)
impl  slot 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc = 0x920b7adf83423283c2d1291cbf3d44dd56a80636 (VaultFactory)
storage slot 0 (Initializable _initialized) = 0x…06  -> reinitializer(6) already consumed
ProxyAdmin.owner() = 0xd1f2823f3aBF4b8c7Ad1B6629421b2618a5e28aF (same Safe)
```

## Factory token balances
```
wS   balanceOf(factory) = 0
WETH balanceOf(factory) = 0
USDC balanceOf(factory) = 0
USDT balanceOf(factory) = 0
```

## eth_call auth probes from random EOA 0x1111…1111
| Call | Result |
|---|---|
| `vault.pauseDeposits()` | revert `BaseVault__OnlyOperators` |
| `vault.resumeDeposits()` | revert `BaseVault__OnlyOperators` |
| `vault.submitShutdown()` | revert `BaseVault__OnlyOperators` |
| `vault.setStrategy(0xdead)` | revert `BaseVault__OnlyFactory` |
| `vault.recoverERC20(WETH,atk,1)` | revert `BaseVault__OnlyFactory` |
| `vault.setEmergencyMode()` | revert `BaseVault__OnlyFactory` |
| `vault.emergencyWithdraw()` | revert `BaseVault__NotInEmergencyMode` |
| `vault.executeQueuedWithdrawals()` | revert `BaseVault__OnlyStrategy` |
| `vault.queueWithdrawal(0,atk)` | revert `BaseVault__ZeroShares` |
| `strategy.withdrawAll()` | revert `Strategy__OnlyVault` |
| `strategy.setOperator(atk)` | revert `Strategy__OnlyFactory` |
| `strategy.rebalance(...)` | revert `Strategy__OnlyOperators` |
| `strategy.emergencyWidthdrawRange(0,1)` | revert `Strategy__OnlyDefaultOperator` |
| `strategy.harvestRewards()` | revert `Strategy__OnlyTrusted` |
| `strategy.setPendingAumAnnualFee(100)` | revert `Strategy__OnlyFactory` |
| `factory.setVaultImplementation(Oracle,atk)` | revert `Ownable: caller is not the owner` |
| `factory.setFeeRecipient(atk)` | revert `Ownable: caller is not the owner` |
| `factory.initialize4(atk,0)` | revert `Initializable: contract is already initialized` |
| `factory.createMarketMakerOracleVault(0xdead,0)` | revert `VaultFactory__VaultNotWhitelisted` |
| `vault.claim()` (from atk) | **succeeds** (self-scoped; atk WETH/wS balances unchanged) |

## Operator identity
- 32 distinct operators are EOAs (`eth_getCode` = `0x`); 2 are Gnosis Safe proxies (`0x5c61f8e0…`, and the factory owner).
- Two operator EOAs use **EIP-7702** delegation (`0xa63c0a70…`, `0x853725b1…` → `0x63c0c19a282a1b52b07dd5a65b58948a07dae32b` = `EIP7702StatelessDeleGator`). `execute(bytes32,bytes)` from a random caller → revert `NotEntryPointOrSelf`; `isValidSignature` → `ECDSAInvalidSignatureLength`. Operator authority is not hijackable.

## Vault inventory (124 Oracle vaults)
- `analysis/vaults_raw.json` — per-vault strategy, `getBalances()`, `totalSupply`, tokens, paused/flagged, operator.
- 92 funded; total `getBalances()` = **$251,566** at DefiLlama spot prices (wS $0.0522, WETH $2,402, WBTC $81,527, USDC ~$0.999, scUSD ~$1.001, stS $0.0569, OS $0.0521, EURC $1.120).
- 58 paused / 54 flagged (deposits only); 0 in emergency mode; 28 empty (shares 1e6 min-lot) ⇒ $0 stuck.
- Sample vault holds 111,981.7 METRO reward tokens (reward pool for share-holders only).

## Price path probes
```
vault.getOracleHelper()            = 0x01c871DfFC36eDC4dDf86FB4a9Bc690B3613a80f
oracleHelper.getDataFeedX()        = 0x1515eF39c96723422D364F7D28a85809Ee0a9140  (OracleLensAggregator)
dataFeedX.lens()                   = 0x189F3FAEE49F744b76dC0B2549a20146E836aa37  (DexLens proxy)
DexLens EIP-1967 impl              = 0xe640b1ad57fdadf8aa60d715a455b40eb374d90b  (verified DexLens)
DexLens.owner()                    = 0x4A3723B6e427Ecbd90f2848d6dF9381A676a02b9  (Safe owner EOA)
DexLens.initialize([]) from EOA    -> revert (DexLens__AlreadyInitialized)
DexLens feed setters               onlyOwnerOrRole(DATA_FEED_MANAGER_ROLE); role member count = 0
getTokenPriceNative(wS)            = 1e18    (native = wS)
getTokenPriceNative(WETH)          = 4.5827e22 (45,826 wS per WETH)
getTokenPriceUSD(USDC)             = 1.008e18
oracleHelper.getOracleParameters() = min 0 / max 2^256-1 / heartbeat 86400 / 86400 / deviation 5 / twapEnabled true / twapInterval 120
```
Deposit share pricing calls `_getOracleHelper().checkPriceInDeviation()` (5% TWAP band) — a manipulated lens price beyond 5% reverts; within 5% the mispricing is bounded and unprofitable after gas/slippage.

