# Parallel V3 Diamond `0x6efeDDF9269c3683Ba516cb0e2124FE335F262a2` — facets & selectors

All 9 facets verified on Etherscan V2 (chainid=1), compiler v0.8.28. **74 selectors total**.
Money-path (permissionless) facets: **Swapper** (mint/burn) and **Redeemer** (redeem).

## DiamondCut — `0x58426574855da7a8c47e1d134d51fd17dca5129b` (1 selectors)

| selector | signature |
|---|---|
| `0x1f931c1c` | `diamondCut((address,uint8,bytes4[])[],address,bytes)` |

## DiamondLoupe — `0x4731f7c0a3b670f78ccb2e3620ae636465ca5279` (4 selectors)

| selector | signature |
|---|---|
| `0xcdffacc6` | `facetAddress(bytes4)` |
| `0x52ef6b2c` | `facetAddresses()` |
| `0xadfca15e` | `facetFunctionSelectors(address)` |
| `0x7a0ed627` | `facets()` |

## SettersGovernor — `0x81a85266ca7dfcfe48a58349e15b258a91d68945` (15 selectors)

| selector | signature |
|---|---|
| `0xf0d2d5a8` | `addCollateral(address)` |
| `0xc1cdee7e` | `adjustStablecoins(address,uint128,bool)` |
| `0x87c8ab7a` | `changeAllowance(address,address,uint256)` |
| `0x5c3eebda` | `recoverERC20(address,address,address,uint256)` |
| `0x4591f148` | `revokeCollateral(address,bool)` |
| `0xc9580804` | `setAccessManager(address)` |
| `0x4d2b3e14` | `setCollateralManager(address,bool,(address[],bytes))` |
| `0xb13b0847` | `setOracle(address,bytes)` |
| `0x1b0c7182` | `setWhitelistStatus(address,uint8,bytes)` |
| `0x7c0343a1` | `toggleTrusted(address,uint8)` |
| `0x1cb44dfc` | `updateOracle(address)` |
| `0xdd94be04` | `updatePayees(address[],uint256[],bool)` |
| `0x83eae17b` | `updateSlippageTolerance(address,uint256)` |
| `0x561c14c4` | `updateSurplusBufferRatio(uint64)` |
| `0x41273657` | `setSwapRouter(address)` |

## SettersGuardian — `0xf659fac08300d204f84af28f66ea3d630acaa72c` (6 selectors)

| selector | signature |
|---|---|
| `0x629feb62` | `setFees(address,uint64[],int64[],bool)` |
| `0x4eec47b9` | `setRedemptionCurveParams(uint64[],int64[])` |
| `0x603b4327` | `setStablecoinCap(address,uint256)` |
| `0xb607d099` | `toggleWhitelist(uint8,address)` |
| `0x3ae308fa` | `pause(address,uint8)` |
| `0xf92c72bc` | `unpause(address,uint8)` |

## RewardHandler — `0x5ab916f3f3f834a5289d520077185ff8a9523eb9` (1 selectors)

| selector | signature |
|---|---|
| `0x05b41934` | `sellRewards(uint256,bytes)` |

## Getters — `0x5db9553cf9bdfcc78d02f5d5d474ccb2f167bfc7` (32 selectors)

| selector | signature |
|---|---|
| `0xfdcb6068` | `accessManager()` |
| `0x847da7be` | `getCollateralBurnFees(address)` |
| `0xeb7aac5f` | `getCollateralDecimals(address)` |
| `0x33352210` | `getCollateralInfo(address)` |
| `0xb7181361` | `getCollateralList()` |
| `0xb85780bc` | `getCollateralMintFees(address)` |
| `0xcd377c53` | `getCollateralRatio()` |
| `0x782513bd` | `getCollateralWhitelistData(address)` |
| `0x94e35d9e` | `getIssuedByCollateral(address)` |
| `0x4ea3e343` | `getManagerData(address)` |
| `0x10d3d22e` | `getOracle(address)` |
| `0x38c269eb` | `getOracleValues(address)` |
| `0xadc9d1f7` | `getRedemptionFees()` |
| `0x31da6b13` | `getStablecoinCap(address)` |
| `0x8db9653f` | `getTotalIssued()` |
| `0x8fb36037` | `isConsumingScheduledOp()` |
| `0x0d126627` | `isPaused(address,uint8)` |
| `0x96d64879` | `isTrusted(address)` |
| `0xfe7d0c54` | `isTrustedSeller(address)` |
| `0x77dc3429` | `isValidSelector(bytes4)` |
| `0xf9839d89` | `isWhitelistedCollateral(address)` |
| `0xa52aefd4` | `isWhitelistedForCollateral(address,address)` |
| `0x99eeca49` | `isWhitelistedForType(uint8,address)` |
| `0x1978a5ed` | `tokenP()` |
| `0xad33ddd0` | `getCollateralSurplus(address)` |
| `0xcfad0a32` | `getLastReleasedAt()` |
| `0x27f38113` | `getPayees()` |
| `0xf04da65b` | `getShares(address)` |
| `0x0baaa34d` | `getSlippageTolerance(address)` |
| `0x23bafad7` | `getSurplusBufferRatio()` |
| `0xd5002f2e` | `getTotalShares()` |
| `0x725c9c49` | `getSwapRouter()` |

## Swapper — `0x6c58bd89f3a50a97ae39136d4044b70034cfce24` (8 selectors)

| selector | signature |
|---|---|
| `0x4583aea6` | `quoteIn(uint256,address,address)` |
| `0x9525f3ab` | `quoteOut(uint256,address,address)` |
| `0x3b6a1fe0` | `swapExactInput(uint256,uint256,address,address,address,uint256)` |
| `0xd92c6cb2` | `swapExactInputWithPermit(uint256,uint256,address,address,uint256,bytes)` |
| `0xb92567fa` | `swapExactOutput(uint256,uint256,address,address,address,uint256)` |
| `0xc10a6287` | `swapExactOutputWithPermit(uint256,uint256,address,address,uint256,bytes)` |
| `0xa0f97974` | `swapExactInputWithAuthorization(uint256,uint256,address,address,address,uint256,bytes)` |
| `0xf3146488` | `swapExactOutputWithAuthorization(uint256,uint256,address,address,address,uint256,bytes)` |

## Redeemer — `0x3607e2f9fca2f18a9a13225e61b68af7f9f8bc5c` (5 selectors)

| selector | signature |
|---|---|
| `0xd703a0cd` | `quoteRedemptionCurve(uint256)` |
| `0xfd7daaf8` | `updateNormalizer(uint256,bool)` |
| `0xb5219346` | `redeem(uint256,address,uint256,uint256[],bytes32)` |
| `0xf70125ab` | `redeemWithAuthorization(uint256,address,uint256,uint256[],address[],bytes32,bytes)` |
| `0x2c1918f9` | `redeemWithForfeit(uint256,address,uint256,uint256[],address[],bytes32)` |

## Surplus — `0x72330ea0f4b4283a948314697665330b9a7afac0` (2 selectors)

| selector | signature |
|---|---|
| `0x86d1a69f` | `release()` |
| `0xfd0e77cc` | `processSurplus(address,uint256)` |

