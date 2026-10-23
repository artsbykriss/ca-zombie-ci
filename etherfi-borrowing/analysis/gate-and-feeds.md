# Evidence — gate, roles, feeds (Optimism, 2026-10-23)

All reads via keyless public OP RPC. Block 158,569,891 (live reads), 158,572,136 (fork test).

## Deployed addresses (verified source)

| Role | Proxy | Impl | Source name |
|---|---|---|---|
| Cash Spoke | `0xdffcC3536D932eb51Df51a7F5FA407c4270d5308` | `0xa1f75d801633a1941cae6670352d627884dc3b68` | `EtherFiSpokeInstance` |
| Cash Hub | `0x66753c4e3fC84f1eD0e3C267C927284E9d90C572` | `0x697af34263bc8e5e6b0e6b0c37a1ec58cede2ce9` | `HubInstance` |
| LendGateway (only PM) | `0x01F8cDFb1694eA8fE4ED6c38a0fD78d1188E03F4` | `0x43d1c047cc32bc08507e9b27758acbddedf7083f` | `LendGateway` |
| DataProvider | `0xDC515Cb479a64552c5A11a57109C314E40A1A778` | `0x7b0c84e0959f92725d7ed2c0e83317a633be3191` | `EtherFiDataProvider` |
| SafeFactory | `0xF4e147Db314947fC1275a8CbB6Cde48c510cd8CF` | `0xae143062e65edbebfc4eded8a31092e3fdb496b8` | `EtherFiSafeFactory` |
| OracleSink | `0x7cb68ddc781153d9417E08bAf6A64e801e398d42` | `0x06a126e6c104bc5e63512be2aff9d5209a7c3e6a` | `OracleSink` |
| AaveOracle | `0xe8cbd37210bF1E29436dAe183d7b9fe45E886fA8` | — | `AaveOracle` |
| Treasury spoke (2nd Hub spoke) | `0x7EB4d25F137868662350603A2863F682287b0768` | `0xe634f603440ad127b2f7ce9d84bfd51d565be9f7` | `TreasurySpokeInstance` |
| CashModule (driver) | `0x7Ca0b75E67E33c0014325B739A8d019C4FE445F0` | `0xd4591b40af911ed7b06b78a0aee35255429d58b3` | `CashModuleCore` |

## Borrow gate

```
# EtherFiSpokeInstance.sol (impl 0xa1f75d80…)
require(IEtherFiDataProvider(0xDC515Cb4…).isEtherFiSafe(onBehalfOf), OnlyEtherFiSafe(onBehalfOf));

cast call 0xDC515Cb4… "isEtherFiSafe(address)(bool)" 0x1111…1111   -> false
cast call 0xDC515Cb4… "isEtherFiSafe(address)(bool)" 0x0FCDa4D5…  -> true   (a real Cash Safe)
cast call 0xdffcC353… "borrow(uint256,uint256,address)" 0 1000000 0x1111…1111 --from 0x1111…1111
    -> revert OnlyEtherFiSafe(0x1111111111111111111111111111111111111111)   selector 0xe883803e

# SafeFactory: deployEtherFiSafe(...) requires ETHERFI_SAFE_FACTORY_ADMIN_ROLE
#   isEtherFiSafe(addr) == deployedAddresses.contains(addr)
#   numContractsDeployed() = 563023
```

## Position managers

```
# only one UpdatePositionManager log in the Spoke's entire history:
block 155129845  positionManager 0x01F8cDFb1694eA8fE4ED6c38a0fD78d1188E03F4  active=true
cast call 0xdffcC353… "isPositionManagerActive(address)(bool)" 0x01F8cDFb… -> true
cast call 0xdffcC353… "isPositionManagerActive(address)(bool)" 0x1111…1111 -> false

# LendGateway: borrow(address,address,uint256,address) onlyDriver
#   _onlyDriver: msg.sender == etherFiDataProvider.getCashModule() || isDriver[msg.sender]
cast call 0x01F8cDFb… "isDriver(address)(bool)" 0x1111…1111 -> false
cast call 0x01F8cDFb… "borrow(address,address,uint256,address)" <safe> <USDC> 1000000 0x1111…1111 --from 0x1111…1111
    -> revert OnlyDriver()

# Spoke.supply(0, 1000e6, self) from attacker: SUCCEEDS (self is always a position manager)
# Spoke.borrow(0, 100e6, self) from attacker: revert OnlyEtherFiSafe
```

## Spoke.sol access model

```
modifier onlyPositionManager(address onBehalfOf) { require(_isPositionManager(onBehalfOf, msg.sender), Unauthorized()); _; }
function _isPositionManager(address user, address manager) internal view returns (bool) {
    if (user == manager) return true;                       // self-op allowed (supply/withdraw/repay/collateral)
    PositionManagerConfig storage config = _positionManager[manager];
    return config.active && config.approval[user];          // else must be an active, user-approved manager
}
# supply/withdraw/borrow/repay/setUsingAsCollateral all carry onlyPositionManager(onBehalfOf).
# borrow additionally carries the isEtherFiSafe override.
```

## RWA feeds

```
AaveOracle.getReserveSource(reserveId) -> feed (all decimals()==8)

reserve 19 iwSPYx  -> 0x8b44f7Ac…  OracleSinkPriceFeed  desc "iwSPYx / USD"  latestAnswer 76625349660
                      sink()=0x7cb68ddc…  token()=0xE7E553Cd… (wSPYx)  rateMaxStaleness()=604800
                      underlyingUsdFeed()=0xf41ebb84… (SPYx/USD)  rateDecimals()=6
reserve 20 iPAXG   -> 0xaC28d7fe…  ChainlinkPriceFeed   desc "PAXG / USD"   latestAnswer 403186701884
                      rateFeed()=0x977cd3bc… (Chainlink aggregator)  rateMaxStaleness()=604800
reserve 21 iwQQQx  -> 0x7106e8D7…  OracleSinkPriceFeed
reserve 22 iwTBLLx -> 0x81D0305B…  OracleSinkPriceFeed
reserve 24 iPAXGy  -> 0x9B92A2D4…  ChainlinkPriceFeed
reserve 26/27/28 wSPYx/wQQQx/wTBLLx -> 0xCC69…/0xEE10…/0xB526…  ERC4626RatePriceFeed (supply 0)

OracleSink 0x7cb68ddc…:
  peers(30101) = 0x000000000000000000000000c4d666b44daa8d6d12b84875384e08bae52afe19  (mainnet PriceRelay)
  paused() = false
  getPrice(0xE7E553Cd…) = (1005714, 1792735343)   # 6-dp rate
  maxStaleness(0xE7E553Cd…) = 604800
  # writes only via lzReceive with the OnlyPeer check (OAppReceiverUpgradeable)

Fork assertion: iwSPYx feed has NO slot0()/token0() -> not an AMM spot source.
```

## Liquidation

```
LiquidationLogic._validateLiquidationCall: require(healthFactor < 1e18, HealthFactorNotBelowThreshold())
RWA_USER 0x0FCDa4D5… getUserAccountData -> healthFactor 1623689080893371480 (1.62e18, healthy)
liquidationCall(19, 0, RWA_USER, 1e6, false) from attacker -> revert HealthFactorNotBelowThreshold()
```

## Hub / supply

```
Hub 0x66753c4e…: add/remove/draw/restore require _spokes[assetId][msg.sender].active (registered spokes only)
  add: require(balanceOf(hub) >= liquidity) after crediting; shares from stored addedShares/liquidity index
       -> direct token donation cannot inflate the share price
  sweep/reclaim: require(caller == asset.reinvestmentController)
  eliminateDeficit/... : restricted
getSpokeCount(asset0) = 2 -> [0x7EB4d25F…(treasury), 0xdffcC353…(Cash Spoke)]
```
