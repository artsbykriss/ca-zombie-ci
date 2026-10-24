# Venus Flux (Instadapp Fluid, BSC) — per-token oracle trace & lockdown evidence

Read-only. All addresses are BSC (chainId 56). RPC: keyless public endpoints only.
Blocks: vault snapshot **129287349**; pause/withdraw probes **129324974**; oracle reads 129287349–129325xxx.

## 1. What "Venus Flux" is

`flux.venus.io/lending/56` is **not Venus's own lending code** — it is a deployment of Instadapp
**Fluid** on BSC (Venus front-end/branding). The deployment artefacts are in the public repo
`Instadapp/fluid-contracts-public` under `deployments/bnb/`.

Core contracts (BSC):

| Role | Address |
|---|---|
| Fluid Liquidity (unified liquidity layer proxy) | `0x52Aa899454998Be5b000Ad077a46Bbe360F4e497` |
| Liquidity `operate` implementation (`FluidLiquidityUserModuleOthers`, solc 0.8.29) | `0x3c06514287E74EDE035D293362A2369bDa60E642` |
| LiquidityResolver | `0xca13A15de31235A37134B4717021C35A3CF25C60` |
| VaultResolver | `0xA5C3E16523eeeDDcC34706b0E6bE88b4c6EA95cC` |
| VaultFactory (ERC721 position NFTs) | `0x324c5Dc1fC42c7a4D43d92df1eBA58a54d13Bf2d` |
| DexResolver | `0xAf572EfC84d905926F7b05C1B7bE04e4E89542B0` |
| VaultPositionsResolver | `0xaA21a86030EAa16546A759d2d10fd3bF9D053Bc7` |

`LiquidityResolver.listedTokens()` (block 129287349) =
`[BNB, USDC(0x8AC7…), USDT(0x55d3…), BTCB(0x7130…), ETH(0x2170…), wBETH(0xa2E3…), syrupUSDT(0x8E9d…), wstUSR(0x4254…), U(0xcE24…), asBNB(0x7773…)]`

The four "wrapper" tokens named in the lead resolve to:

| Truncated | Full | Name | Kind |
|---|---|---|---|
| `0x8E9d…` | `0x8E9d4cEa39299323FE8eda678cAD449718556c4e` | syrupUSDT | Maple yield-bearing stablecoin (6 dp) |
| `0x4254…` | `0x4254813524695def4163A169e901f3d7a1a55429` | wstUSR | Resolv wrapped staked USR (18 dp, ERC1967 proxy) |
| `0xcE24…` | `0xcE24439F2D9C6a2289F741120FE202248B666666` | U | United Stables (18 dp, proxy) |
| `0x7773…` | `0x77734e70b6E88b4d82fE632a168EDf6e910b6` → `0x77734e70b6E88b4d82fE632a168EDf6e700912b6` | asBNB | Astherus BNB LST (18 dp) |

## 2. Vault inventory (block 129287349, 35 vaults)

21 FluidVaultT1 + 14 smart vaults (T2/T3/T4). Live supply ≈ **$1.85M**, borrow ≈ **$1.17M**
(DefiLlama 2026-10-20 reported $1.88M / $1.22M — consistent).

Largest books: syrupUSDT/USDT ($573k col / $479k debt), BTCB/USDT, BNB/USDT, ETH/USDT.

## 3. Per-token oracle classification

Every vault exposes `oracle` + `oraclePriceOperate` (`VaultResolver.getVaultEntireData`).
Oracles are Fluid **GenericOracle** (composes ≤5 hops: Chainlink / Fluid CappedRate) or
**DexSmart*PegOracle** (Fluid DEX reserves + peg buffer). None is a raw spot pool.

| Token (collateral) | Vault oracle | Underlying source | Live oracle | Market | Verdict |
|---|---|---|---|---|---|
| BNB | GenericOracle_BNB_* `0x25FcD7…` | Chainlink BNB/USD `0x0567F232…` | $744.93 | $744.93 | OK |
| ETH | GenericOracle_ETH_* `0x0F53c623…` | Chainlink ETH/USD `0x9ef1B8c0…` | $2398.6 | $2398.49 | OK |
| BTCB | GenericOracle_BTCB_* `0x9B932588…` | Chainlink BTC/USD | $81695 | $81534 | OK |
| wBETH | GenericOracle_WBETH_* `0x9024ac8c…` | CappedRate(wBETH `exchangeRate()`=1.109 ETH) × Chainlink ETH/USD | $2660.17 | $2659.83 | OK |
| syrupUSDT | GenericOracle_SYRUPUSDT_USDT `0x0c7F7f62…` | CappedRateChainlink_SYRUPUSDT `0x3DD2Fdaf…` → Chainlink "SYRUPUSDT / USDT **Exchange Rate**" `0xac9962aA…` = 1.149 | 1.149 | $1.1457 | OK (redemption-rate feed, currently ≈ market) |
| asBNB | CappedRateASBNB_ASBNB `0x91D16960…` | asBNB `exchangeRate()` = 1.0677 BNB | 1.0677 | 1.0628 | OK |
| U (debt token) | GenericOracle_*_U | Chainlink BNB/USD ÷ U | $0.9983 | $0.9992 | OK |
| **wstUSR** | GenericOracle_WSTUSR_USDT `0xc0767760…` / WSTUSR_USDC `0x2643Fc74…` | CappedRateChainlink_WSTUSR `0x4c38911E…` → rateSource `0xA40a0dC2…` = **wstUSR→stUSR redemption rate** | **1.13297** | **~$0.083** | **BROKEN — ~13.6× over-valued** |

### wstUSR detail (the finding)

`GenericOracle_WSTUSR_USDT.getExchangeRate()` = `1132966158918315225000000000` (1.132966158918315225e27)
= **1.13297 USDT per wstUSR**. Its single hop is `FluidCappedRateChainlink` `0x4c38911E…`
(`infoName = "USR per 1 WSTUSR"`, `rateSource = 0xA40a0dC2…`, `invertCenterPrice = false`,
`maxAPRPercent = 900000` (9000%), `maxDownFromMaxReachedPercentCol = 0` → defaulted to 100% ⇒
downward moves pass through, `liquidation` rate == operate rate).

The rate source `0xA40a0dC2…` returns `latestAnswer() = 1.132966158918315225e18`, and its
`description()` = **"WSTUSR-STUSR Exchange Rate"** — the **wstUSR → stUSR redemption (exchange) rate**
(stUSR = staked USR). It is *not* a wstUSR market price.

**USR permanently de-pegged on 2026-03-22** (Resolv signing-key compromise minted 80M unbacked
USR; USR fell to $0.02–0.25 and has since traded $0.07–0.16). Live (2026-10-23, DefiLlama):
`USR = $0.0734`, `wstUSR = $0.0831` (the wstUSR/USR ratio 1.132 matches the oracle exactly — the
whole error is the implicit `1 stUSR = $1` peg).

So the Fluid oracle prices **1 wstUSR = 1.13297 USDT** while its market value is **~$0.083**:
a **~13.6× over-valuation**. The CappedRate never saw the depeg because its source is a
redemption rate that only accrues upward — exactly the failure mode described in the Fluid/Resolv
post-mortem (Fluid's oracle was ~15h stale at $1.13 while the market fell to $0.02, producing
~$21M bad debt across six wstUSR vaults **on Ethereum**).

## 4. Why it is NOT extractable on BSC today (the lockdown)

Unlike Ethereum (where the mis-pricing was exploited for ~$21M before Fluid paused the market),
the BSC Venus Flux wstUSR market is **fully and deliberately frozen**:

**(a) Liquidity-layer per-user pause bits (bit 255 of the user supply/borrow config).**
Slot = `keccak256(abi.encode(token, keccak256(abi.encode(user, mappingSlot))))`, supply map = 8,
borrow map = 9 (see `analysis/pause_bits.py`). Read at block 129324974:

| user | token | supplyPaused | borrowPaused |
|---|---|---|---|
| T1 wstUSR/USDT vault `0x3996464c…` | wstUSR | **1** | – |
| T1 wstUSR/USDT vault | USDT | – | **1** |
| T1 wstUSR/USDC vault `0xeAEf5630…` | wstUSR | **1** | – |
| T1 wstUSR/USDC vault | USDC | – | **1** |
| T2 wstUSR/USDT vault `0xF74cb9D6…` | USDT | – | **1** |
| wstUSR/USDT DEX `0x3C0441B4…` | wstUSR | **1** | – |
| wstUSR/USDT DEX | USDT | **1** | – |
| T1 syrupUSDT/USDT vault `0x82B27fA8…` | syrupUSDT / USDT | 0 | 0 |
| T3 syrupUSDT vault `0xE6b5D1Cd…` | syrupUSDT | 0 | 0 |

`FluidLiquidityUserModuleOthers._supplyOrWithdraw` reverts with `UserModule__UserPaused` on the
pause bit for **both** supply and withdraw; `_borrowOrPayback` does the same. So wstUSR supply,
wstUSR withdraw, and the paired stablecoin borrow/payback are all blocked at the Liquidity layer.

**(b) Vault-level borrow limit = 1 wei.** `LiquidityResolver.getUserBorrowData(vault, USDT)` for
the T1 wstUSR/USDT vault returns `maxBorrowLimit = 1`, `borrowable = 0` (same for the USDC vault).
`getVaultEntireData(...).limitsAndAvailability.borrowLimit = 1`. Every wstUSR vault (T1/T2/T3/T4)
shows `borrowLimit = 1`.

**(c) Fluid DEX wstUSR/USDT pool is frozen.** `getDexConfigs` → `maxSupplyShares = 0`,
`maxBorrowShares = 0`; `dexVariables2` bit 255 (swap/arbitrage paused) = 1 — **only this pool** of
the five is paused (USDT/USDC, syrupUSDT/USDT, USDT/U, ETH/wBETH have bit 255 = 0). A `swapIn`
reverts `FluidDexError(51043)` = `DexT1__SwapAndArbitragePaused`. The pool also uses the same broken
centre price (`0x4c38911E…`, centre 1.13297e27, range [1.13013, 1.13581]).

**(d) Existing wstUSR positions are dust and frozen.** Only two non-zero positions exist:
NFT **38** (0.7 wstUSR / 0.449 USDT) and NFT **37** (0.5 wstUSR / 0.263 USDC), both owned by the
Instadapp multisig proxy `0x4F6F977aCDD1177DCD81aB83074855EcB9C2D49e`. Withdrawing 0.05 wstUSR
reverts `FluidLiquidityError(10998)` = `UserModule__UserPaused`; withdrawing 0.5 reverts
`FluidVaultError(31006)` = `Vault__PositionAboveCF`. So the residual collateral cannot be withdrawn
or liquidated by anyone unprivileged.

**(e) No other wstUSR surface.** `SmartLendingFactory.totalSmartLendings() = 0`. No vault has wstUSR
as a debt token. No oracle over/under-prices any other listed token (all within ±0.5% of market).

## 5. Live borrow liquidity (bound on any future extraction)

Global Liquidity-layer stablecoin state (block 129287349, via `getDexSwapLimitsAndAvailability`):

| token | supply | borrow | borrowable |
|---|---|---|---|
| USDT | 1,099,304.77 | 860,369.10 | **238,935.66** |
| USDC | 265,726.83 | 239,042.50 | **26,684.33** |
| U | 83,837.19 | 83,628.85 | 208.34 |

So even if governance re-armed the wstUSR market, the extractable amount would be bounded by the
available stablecoin liquidity ≈ **$265.6k** → net profit ≈ $244k (see §6).

## 6. Latent (re-arm) magnitude

If the pause were lifted and the borrow limit restored:
- borrow capacity per wstUSR = oracle 1.13297 × CF 90% = **1.0197 USDT**;
- market cost per wstUSR = **$0.0813**;
- profit ≈ **$0.938 per wstUSR** (net of the forfeited collateral);
- bounded by ~$238.9k USDT + $26.7k USDC → **≈ $244k net** at today's liquidity.

Trigger to re-arm: `updateUserSupplyConfigs/updateUserBorrowConfigs` (unpause) + borrow-limit change
by Fluid governance/guardians, or a new vault/DEX listing that accepts wstUSR, or (on any chain)
an un-paused Fluid wstUSR market with the same stale redemption-rate oracle.

## 7. Sources

- Instadapp/fluid-contracts-public `deployments/bnb/*.json` (all BSC addresses + constructor args).
- BscScan/Etherscan-V2 verified source: `FluidVaultT1`, `FluidLiquidityResolver`,
  `FluidLiquidityUserModuleOthers` `0x3c065142…`, `FluidCappedRate`, `FluidGenericOracle`,
  `FluidDexT1`, `FluidLiquidity`.
- Post-mortem gist `andrewhong5297/f8895e7a2539ca702e87bbecb345c736` (Resolv/Fluid bad-debt cleanup).
- Cointelegraph 2026-03-22/24 (Resolv 80M USR exploit), CoinGecko (USR = $0.0814).
