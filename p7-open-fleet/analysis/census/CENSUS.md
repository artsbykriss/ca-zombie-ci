# FleetCommander CENSUS — Lazy Summer Protocol (open-fleet)

Read-only on-chain enumeration of every FleetCommander / FleetCommanderDao in the repo's per-chain
Ignition registries, unioned with each chain's live `HarborCommand.getActiveFleetCommanders()` set.
Purpose: find fleets that still list a **capped ark** (`ark.depositCap()==0`) in their active set — the
structural precondition of the 2026-07-06 donation-inflation exploit.

Prices: WETH $2,328.67 (`coins.llama.fi`, ts 1792974352); EURC $1.1209; stables (USDC/USDT/USDC.e/USDT0) 1:1.
Decimals verified on-chain. Raw amounts and per-chain block numbers are in `census.json`.

## Summary

| Chain | Block | Harbor live set | Fleets w/ code | USD>1000 | active arks | capped active arks |
|---|---|---|---|---|---|---|
| Ethereum (1) | 26273220 | 7 | 11 | 4 | 38 | 6 |
| Base (8453) | 53092342 | 3 | 6 | 3 | 26 | 15 |
| Arbitrum (42161) | 518286647 | 3 | 4 | 2 | 9 | 4 |
| Sonic (146) | 81623204 | 1 | 1 | 1 | 0 | 0 |
| HyperEVM (999) | 49529553 | 2 | 4 | 2 | 14 | 0 |
| **TOTAL** | — | — | **26** | **12** | **87** | **25** |

## Ethereum (chainId 1) — block 26273220

Harbor live: 0x98c49e13bf99d7cad8069faa2a370933ec9ecf17, 0x17ee2d03e88b55e762c66c76ec99c3a28a54ad8d, 0x67e536797570b3d8919df052484273815a0ab506, 0x2e6abcbcced9af05bc3b8a4908e0c98c29a88e10, 0xe9cda459bed6dcfb8ac61cd8ce08e2d52370cb06, 0x0c1fbccc019320032d9acd193447560c8c632114, 0xd77f9a9f2b0c160db3e9dc2cce370c1a740c76fc

| Fleet | code | harbor | asset | paused | totalAssets | totalSupply | withdrawable | buffer | arks | capped | USD |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `0x0c1fbccc019320032d9acd193447560c8c632114` | 24575 | True | WETH | false | 34.68 | 34.50 | 34.68 | 34.68 | 0 | 0 | 80,756.84 |
| `0x17ee2d03e88b55e762c66c76ec99c3a28a54ad8d` | 24544 | True | USDT | false | 10,761.44 | 10,113.97 | 10,761.44 | 10,761.44 | 0 | 0 | 10,761.44 |
| `0x218f3255fa97a60bf99f175c9c5c56fdf06b15fc` | 24506 | False | USDC | false | 7.20 | 7.05 | 5.44 | 1.00 | 5 | 0 | 7.20 |
| `0x2e6abcbcced9af05bc3b8a4908e0c98c29a88e10` | 24544 | True | WETH | false | 21.96 | 21.28 | 21.96 | 21.96 | 0 | 0 | 51,140.98 |
| `0x40e9c802f9566b16a66a48d9a1d7a8d73fe55651` | 24544 | False | WETH | false | 0.01 | 0.02 | 0.01 | 0.01 | 9 | 5 | 23.70 |
| `0x48d047532191479852c1f1903cb83700c42a3b8f` | 24575 | False | USDC | false | 6.04 | 6.04 | 5.00 | 5.00 | 1 | 0 | 6.04 |
| `0x67e536797570b3d8919df052484273815a0ab506` | 24544 | True | WETH | false | 32.90 | 31.91 | 32.90 | 32.90 | 0 | 0 | 76,608.12 |
| `0x8360e8224e3948cd7febdc5fa8c12d50af81187d` | 24544 | False | USDC | false | 27.56 | 25.84 | 4.46 | 0.06 | 8 | 0 | 27.56 |
| `0x98c49e13bf99d7cad8069faa2a370933ec9ecf17` | 24544 | True | USDC | false | 0.00 | 9,562,316.69 | 0.00 | 0.00 | 10 | 0 | 0.00 |
| `0xd77f9a9f2b0c160db3e9dc2cce370c1a740c76fc` | 24575 | True | USDC | false | 11.63 | 11.45 | 11.63 | 11.63 | 0 | 0 | 11.63 |
| `0xe9cda459bed6dcfb8ac61cd8ce08e2d52370cb06` | 24544 | True | USDC | true | 0.00 | 534,078.85 | 0.00 | 0.00 | 5 | 1 | 0.00 |

## Base (chainId 8453) — block 53092342

Harbor live: 0x98c49e13bf99d7cad8069faa2a370933ec9ecf17, 0x64db8f51f1bf7064bb5a361a7265f602d348e0f0, 0x2bb9ad69feba5547b7cd57aafe8457d40bf834af

| Fleet | code | harbor | asset | paused | totalAssets | totalSupply | withdrawable | buffer | arks | capped | USD |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `0x2bb9ad69feba5547b7cd57aafe8457d40bf834af` | 24544 | True | WETH | false | 21.00 | 20.44 | 21.00 | 21.00 | 0 | 0 | 48,906.82 |
| `0x5c841955d7ee3e2f7a077aa0aca3a7d724b15da2` | 24544 | False | WETH | false | 0.00 | 0.00 | 0.00 | 0.00 | 9 | 2 | 2.38 |
| `0x64db8f51f1bf7064bb5a361a7265f602d348e0f0` | 24544 | True | EURC | false | 7,669.28 | 7,409.66 | 7,669.28 | 7,669.28 | 0 | 0 | 8,596.29 |
| `0x774b8790a391ffb9f64f60ade77fbcc3a8942781` | 24373 | False | USDC | false | 0.00 | 0.00 | 0.00 | 0.00 | 12 | 12 | 0.00 |
| `0x98c49e13bf99d7cad8069faa2a370933ec9ecf17` | 24544 | True | USDC | false | 83,976.83 | 78,183.25 | 83,976.83 | 83,976.83 | 0 | 0 | 83,976.83 |
| `0xf762b4e90b21be81e5673058ac01b83a5833a4d9` | 24544 | False | USDC | false | 0.00 | 1.52 | 0.00 | 0.00 | 5 | 1 | 0.00 |

## Arbitrum (chainId 42161) — block 518286647

Harbor live: 0x98c49e13bf99d7cad8069faa2a370933ec9ecf17, 0x4f63cfea7458221cb3a0eee2f31f7424ad34bb58, 0x71d77c39db0eb5d086611a2e950198e3077cf58a

| Fleet | code | harbor | asset | paused | totalAssets | totalSupply | withdrawable | buffer | arks | capped | USD |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `0x45342a8ac1e9ef6877d7566ed7be5fc98f7e7cae` | 24544 | False | USDT | false | 1.00 | 1.01 | 1.00 | 0.00 | 4 | 3 | 1.00 |
| `0x4f63cfea7458221cb3a0eee2f31f7424ad34bb58` | 24544 | True | USDC | false | 1,251.17 | 1,272,595.90 | 750.02 | 414.89 | 5 | 1 | 1,251.17 |
| `0x71d77c39db0eb5d086611a2e950198e3077cf58a` | 24543 | True | USDC | false | 436.11 | 429.12 | 436.11 | 436.11 | 0 | 0 | 436.11 |
| `0x98c49e13bf99d7cad8069faa2a370933ec9ecf17` | 24544 | True | USDT | false | 6,561.91 | 6,262.60 | 6,561.91 | 6,561.91 | 0 | 0 | 6,561.91 |

## Sonic (chainId 146) — block 81623204

Harbor live: 0x507a2d9e87dbd3076e65992049c41270b47964f8

| Fleet | code | harbor | asset | paused | totalAssets | totalSupply | withdrawable | buffer | arks | capped | USD |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `0x507a2d9e87dbd3076e65992049c41270b47964f8` | 24544 | True | USDC.e | false | 7,236.58 | 6,820.02 | 7,236.58 | 7,236.58 | 0 | 0 | 7,236.58 |

## HyperEVM (chainId 999) — block 49529553

Harbor live: 0x252e5aa42c1804b85b2ce6712cd418a0561232ba, 0x2cc190fb654141dfbeac4c0f718f4d511674d346

| Fleet | code | harbor | asset | paused | totalAssets | totalSupply | withdrawable | buffer | arks | capped | USD |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `0x015e60a0b239214fdeab9ad21318b12c0d97c15d` | 24493 | False | USDC | false | 5.62 | 5.54 | 4.59 | 2.50 | 5 | 0 | 5.62 |
| `0x252e5aa42c1804b85b2ce6712cd418a0561232ba` | 24493 | True | USDC | false | 7,204.56 | 7,044.54 | 7,204.56 | 7,204.56 | 0 | 0 | 7,204.56 |
| `0x26ce19153db119bdf2bcf299503f7d419d4a6d4f` | 24493 | False | USDT0 | false | 4.10 | 4.03 | 1.00 | 1.00 | 9 | 0 | 4.10 |
| `0x2cc190fb654141dfbeac4c0f718f4d511674d346` | 24493 | True | USDT0 | false | 1,047.14 | 1,027.71 | 1,047.14 | 1,047.14 | 0 | 0 | 1,047.14 |

## CANDIDATES

Filter: active arks non-empty **AND** USD>100 **AND** `paused==false` **AND** >=1 capped ark (`depositCap()==0`).

| Chain | Fleet | TVL USD | asset | capped arks | liquid USD (buffer + non-capped) |
|---|---|---|---|---|---|
| Arbitrum | `0x4f63cfea7458221cb3a0eee2f31f7424ad34bb58` | 1,251.17 | USDC | 1 | 750.02 |

### Candidate detail

**Arbitrum — `0x4f63cfea7458221cb3a0eee2f31f7424ad34bb58`** (TVL $1,251.17 USDC, block 518286647)

- CAPPED ark `0x125dae47930c1118cf2db5a140877c64b408783c` `SiloManagedVault-varlamore-usdc-42161` — depositCap=0, totalAssets_raw=501147261
- bufferArk `0xbb79242b9518f450cde8eb957e15c38ab09b1419` balance_raw=414892848
- non-capped ark `0x64e3d757d0ea851a79cdc8390c9434a915949461` `AaveV3-usdc-42161` totalAssets_raw=0 cap=950000000000
- non-capped ark `0x7bb4536e67c804758f77c218d9af28856566151e` `CompoundV3-usdc-42161` totalAssets_raw=0 cap=7100000000000
- non-capped ark `0x525360007383bd0e6ba9deedd376c931c47135ad` `MorphoVault-usdc-Gauntlet_USDC_Prime-42161` totalAssets_raw=0 cap=2870000000000
- non-capped ark `0x4ef91e09adb31cc7ec9b663b6827155d6a103b74` `ERC4626-Sky_sUSDC-usdc-42161` totalAssets_raw=335126524 cap=54000000000000

## Anomalies

1. **totalAssets==0 with non-zero totalSupply** (share price 0 / fleet drained):
   - Ethereum `0x98c49e13bf99d7cad8069faa2a370933ec9ecf17`: totalAssets=0, totalSupply=9,562,316.69 USDC, paused=false, arks=10, capped=0
   - Ethereum `0xe9cda459bed6dcfb8ac61cd8ce08e2d52370cb06`: totalAssets=0, totalSupply=534,078.85 USDC, paused=true, arks=5, capped=1
   - Base `0xf762b4e90b21be81e5673058ac01b83a5833a4d9`: totalAssets=0, totalSupply=1.52 USDC, paused=false, arks=5, capped=1

2. **totalAssets << totalSupply (large NAV-per-share collapse), not paused**:
   - Arbitrum `0x4f63cfea7458221cb3a0eee2f31f7424ad34bb58`: totalAssets=1,251.17 vs totalSupply=1,272,595.90 USDC (NAV/share ~0.000983), paused=false

3. **Paused fleets that still list a capped ark** (risk latent if unpaused):
   - Ethereum `0xe9cda459bed6dcfb8ac61cd8ce08e2d52370cb06`: paused=true, USD=0.00, capped arks=1

_Generated read-only. Block numbers: Ethereum 26273220, Base 53092342, Arbitrum 518286647, Sonic 81623204, HyperEVM 49529553._
