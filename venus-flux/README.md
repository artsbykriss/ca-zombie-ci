# Venus Flux (Instadapp Fluid) on BSC — oracle/price-path deep dive

**Finding:** ZH4 pass-3 lane-lending row 8 / pass-3 README OPEN #5 · **Date:** 2026-10-23 · **Chain:** BSC (chainId 56)
**Status:** read-only; PoC fork-verified only; **no mainnet transaction was signed or sent**.
**Blocks:** vault snapshot **129287349**; pause/withdraw probes **129324974**; oracle reads **129326623**.
**CI:** `bash /home/heisenberg/CA/ci/ci-run.sh venus-flux` (run URLs in §7 / `ci-log.txt`).

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why closed / open | Latent risk |
|---|---|---|---|
| **Venus Flux** — wstUSR market (oracle path) | **$0** | Oracle **is** broken (wstUSR priced 1.13297 vs ~$0.083 market = **~13.6× too high**) but Fluid has **fully paused the wstUSR market**: borrow limit = 1 wei, Liquidity-layer user-pause bits set for wstUSR supply + USDT/USDC borrow, DEX swap paused, DEX share caps 0 | **~$244k** if governance un-pauses / re-arms |
| Venus Flux — all other collateral (BNB/ETH/BTCB/wBETH/syrupUSDT/asBNB/U) | **$0** | Every oracle matches market within ±0.5 % | — |
| Venus Flux — existing wstUSR positions | **$0** | Dust (1.2 wstUSR, ~$0.10) and frozen (can't withdraw) | — |

## 2. Total live extractable now: **$0.00** (E-U)

Confidence **HIGH (~0.9)**. The oracle bug is real and still live in the oracle contract, but every
call path that could monetise it reverts on-chain today (fork-verified, 10/10 tests — §7).

Categories: **E-U $0 · H-O $0 · P governance-only (unpause) · S ~$0** (dust frozen positions).

---

## 3. The mechanism, in exact terms

`flux.venus.io/lending/56` ("Venus Flux") is **not Venus's lending code** — it is an **Instadapp Fluid**
deployment on BSC (Venus front-end/branding). Deployment artefacts: `Instadapp/fluid-contracts-public`,
`deployments/bnb/`.

The lead was: *the per-token price/oracle sources were never fully traced; a bad/spot oracle on a
wrapper would allow over-borrow.* Tracing all ten listed tokens:

```
LiquidityResolver.listedTokens() =
[BNB, USDC, USDT, BTCB, ETH, wBETH,
 syrupUSDT 0x8E9d4cEa39299323FE8eda678cAD449718556c4e,   // Maple
 wstUSR   0x4254813524695def4163A169e901f3d7a1a55429,   // Resolv   <-- the bug
 U        0xcE24439F2D9C6a2289F741120FE202248B666666,   // United Stables
 asBNB    0x77734e70b6E88b4d82fE632a168EDf6e700912b6]   // Astherus
```

Each vault exposes its `oracle` + `oraclePriceOperate` (`VaultResolver.getVaultEntireData`). The
oracles are Fluid **GenericOracle** (≤5 hops of Chainlink / Fluid CappedRate) or **DexSmart*PegOracle**
(Fluid-DEX reserves + peg buffer). **No oracle is a raw spot pool.**

**The one broken oracle is wstUSR.** `GenericOracle_WSTUSR_USDT` (`0xc0767760627E88Eef7f653bce49e660a351E95eD`)
has a single hop into `FluidCappedRateChainlink` `0x4c38911E3797Ba0ebD9a1D40673CA1A993445EDF`
(`infoName = "USR per 1 WSTUSR"`, `rateSource = 0xA40a0dC23D3A821fF5Ea9E23080B74DAC031158d`).

```
wstUSR/USDT oracle getExchangeRate() = 1132966158918315225000000000   (1.132966158918315225e27)
rateSource 0xA40a0dC2 latestAnswer() = 1.132966158918315225e18        (wstUSR -> USR redemption rate)
```

`0xA40a0dC2…` is the **"WSTUSR-STUSR Exchange Rate"** (wstUSR→stUSR, stUSR = staked USR) — it only
accrues upward and knows nothing about USR's **market** price. **USR permanently de-pegged on
2026-03-22** (Resolv signing-key compromise minted 80M unbacked USR; USR fell to $0.02–0.25). Today
(DefiLlama 2026-10-23):

```
USR   = $0.0734      wstUSR = $0.0831      (wstUSR/USR = 1.132  -- exactly the oracle's rate)
oracle = 1.13297 USDT per wstUSR   =>  ~13.6x over-valuation (the oracle assumes 1 stUSR = $1)
```

This is exactly the failure mode of the Ethereum incident (public post-mortem gist
`andrewhong5297/f8895e7a2539ca702e87bbecb345c736`): *"Fluid's oracle was ~15 hours stale, still pricing
wstUSR at $1.13 while the market fell to $0.02 … opportunistic actors deposited discounted wstUSR at
the inflated oracle price, borrowed stablecoins, and walked away … ~$21M bad debt across six wstUSR
vaults."* The `FluidCappedRate` design caps **upward** moves (`maxAPRPercent`) but passes **downward**
moves through only if the *rate source* moves — and a redemption-rate source never does.

### Every other token is priced correctly (live, block 129287349)

| collateral | oracle | live | market | verdict |
|---|---|---|---|---|
| BNB | GenericOracle_BNB_* `0x25FcD7…` (Chainlink) | $745.28 | $744.93 | OK |
| ETH | GenericOracle_ETH_* `0x0F53c623…` (Chainlink) | $2400.64 | $2398.49 | OK |
| BTCB | GenericOracle_BTCB_* `0x9B932588…` (Chainlink) | $81651.9 | $81534 | OK |
| wBETH | GenericOracle_WBETH_* `0x9024ac8c…` (CappedRate(wBETH rate 1.109 ETH) × Chainlink ETH/USD) | $2662.42 | $2659.83 | OK |
| syrupUSDT | GenericOracle_SYRUPUSDT_USDT `0x0c7F7f62…` → CappedRateChainlink_SYRUPUSDT `0x3DD2Fdaf…` → Chainlink *"SYRUPUSDT / USDT Exchange Rate"* `0xac9962aA…` | 1.149 | $1.1457 | OK |
| asBNB | CappedRateASBNB_ASBNB `0x91D16960…` (asBNB rate 1.0677 BNB) | 1.0677 | 1.0628 | OK |
| U (debt) | GenericOracle_*_U | $0.9983 | $0.9992 | OK |

*(Note: syrupUSDT's source is an "Exchange Rate" feed, so a future syrupUSDT de-peg would not be
caught — the same class as wstUSR. Today it tracks market.)*

---

## 4. Live-state assessment (addresses, roles, blocks)

| Role | Address |
|---|---|
| Fluid Liquidity proxy | `0x52Aa899454998Be5b000Ad077a46Bbe360F4e497` |
| Liquidity `operate` impl `FluidLiquidityUserModuleOthers` | `0x3c06514287E74EDE035D293362A2369bDa60E642` |
| LiquidityResolver | `0xca13A15de31235A37134B4717021C35A3CF25C60` |
| VaultResolver | `0xA5C3E16523eeeDDcC34706b0E6bE88b4c6EA95cC` |
| VaultFactory (ERC721 position NFTs) | `0x324c5Dc1fC42c7a4D43d92df1eBA58a54d13Bf2d` |
| DexResolver | `0xAf572EfC84d905926F7b05C1B7bE04e4E89542B0` |
| wstUSR oracle / source | `0xc0767760627E88Eef7f653bce49e660a351E95eD` / `0x4c38911E3797Ba0ebD9a1D40673CA1A993445EDF` |
| T1 wstUSR/USDT vault · T1 wstUSR/USDC vault | `0x3996464c0fCCa8183e13ea5E5e74375e2c8744Dd` · `0xeAEf563015634a9d0EE6CF1357A3b205C35e028D` |
| Fluid DEX wstUSR/USDT | `0x3C0441B42195F4aD6aa9a0978E06096ea616CDa7` |

**TVL (block 129287349, 35 vaults):** supply **≈ $1,849,728** (@oracle), borrow **≈ $1,174,516**
(DefiLlama 2026-10-20: $1.88M / $1.22M — consistent). Largest books: syrupUSDT/USDT ($573k/$479k),
BTCB/USDT, BNB/USDT, ETH/USDT. wstUSR vaults total ≈ **$15** of collateral.

### The lockdown (why $0)

**(a) Vault borrow limit = 1 wei.**
`LiquidityResolver.getUserBorrowData(T1 wstUSR/USDT vault, USDT)` → `maxBorrowLimit = 1`,
`borrowable = 0` (same for the USDC vault). `getVaultEntireData(...).limitsAndAvailability.borrowLimit = 1`
for **all** wstUSR vaults (T1/T2/T3/T4).

**(b) Liquidity-layer per-user pause bits (bit 255 of the user supply/borrow config), block 129324974:**

| user | token | supplyPaused | borrowPaused |
|---|---|---|---|
| T1 wstUSR/USDT vault | wstUSR / USDT | **1** | **1** |
| T1 wstUSR/USDC vault | wstUSR / USDC | **1** | **1** |
| T2 wstUSR/USDT vault `0xF74cb9D6…` | USDT | – | **1** |
| wstUSR/USDT DEX | wstUSR / USDT | **1** | **1** |
| T1 syrupUSDT/USDT vault (control) | syrupUSDT / USDT | 0 | 0 |

`FluidLiquidityUserModuleOthers._supplyOrWithdraw` reverts `UserModule__UserPaused` on the pause bit
for **both supply and withdraw**; `_borrowOrPayback` likewise. (Deployed build reverts
`FluidLiquidityError(10998)` = `UserModule__UserPaused`; the repo HEAD renumbers it 11002 — the
deployed bytecode of `0x3c065142…` contains `PUSH2 0x2afa`.)

**(c) Fluid DEX wstUSR/USDT frozen.** `getDexConfigs` → `maxSupplyShares = 0`, `maxBorrowShares = 0`;
`dexVariables2` **bit 255 (swap/arbitrage paused) = 1** — the *only* paused pool of the five
(USDT/USDC, syrupUSDT/USDT, USDT/U, ETH/wBETH = 0). `swapIn(...)` reverts
`FluidDexError(51043)` = `DexT1__SwapAndArbitragePaused`. The pool also carries the same broken
centre price (`0x4c38911E…`, centre `1.13297e27`, range `[1.13013, 1.13581]`).

**(d) Existing wstUSR positions — dust and frozen.** Only two non-zero positions exist:
NFT **38** (0.7 wstUSR / 0.449 USDT) and NFT **37** (0.5 wstUSR / 0.263 USDC), **both owned by the
Instadapp multisig proxy `0x4F6F977aCDD1177DCD81aB83074855EcB9C2D49e`**. Withdrawing 0.05 wstUSR
reverts `UserModule__UserPaused`; withdrawing 0.5 reverts `FluidVaultError(31006)` =
`Vault__PositionAboveCF`.

**(e) Nothing else.** `SmartLendingFactory.totalSmartLendings() = 0`. No vault has wstUSR as a debt
token. No other listed token is mis-priced.

### Position-NFT / auth model (as asked)

Fluid VaultT1 positions are **ERC721 NFTs** minted by the `VaultFactory`; `operate(nftId, col, debt, to)`
mints a new NFT when `nftId == 0` and otherwise requires `VAULT_FACTORY.ownerOf(nftId) == msg.sender`
for withdraw/borrow. `Liquidity.operate` is callable only by **authorised** users (the vaults/DEXes);
each user has a per-token borrow limit and pause bit at the Liquidity layer. The wstUSR CF is
**90 %** (LTV high) — which is precisely why the broken oracle would be dangerous if reachable.

---

## 5. What an attacker can / cannot do

**Cannot (all revert on-chain, fork-verified):**
- supply wstUSR as collateral (`UserModule__UserPaused`, Liquidity pause bit);
- borrow USDT/USDC against wstUSR (`borrowable = 0` / borrow limit 1 wei / borrow pause bit);
- swap wstUSR→USDT on the Fluid DEX (`DexT1__SwapAndArbitragePaused`, 51043);
- deposit/borrow DEX shares (maxSupplyShares = maxBorrowShares = 0);
- withdraw the existing wstUSR collateral (`UserPaused` / `Vault__PositionAboveCF`).

**Could, only if governance re-arms** (unpause + raise the borrow limit):
acquire wstUSR cheaply (bridged OFT, market ~$0.083) → supply → borrow stablecoins at the oracle
value (1.13297 × CF 90 % = **1.0197 USDT per wstUSR**) → default. Net ≈ **$0.937 per wstUSR**, bounded
by available liquidity: **USDT 238,935.66 + USDC 26,684.33 ≈ $265.6k** → **≈ $244k net**.

---

## 6. Verdict & residual / latent risk

- **E-U: $0** (high confidence). The oracle bug is live but the market is deliberately frozen.
- **H-O: $0** — the pause blocks holders from self-withdrawing.
- **P:** governance/guardians can un-pause and re-limit (the only path that re-arms the bug).
- **S:** ~$0 — 1.2 wstUSR of dust collateral (market ~$0.10) frozen against $0.71 of debt; both are
  team-owned.
- **Latent/re-arm: ~$244k** at today's liquidity, the instant the pause is lifted or the borrow limit
  is restored — and instantly on any *other* chain that lists wstUSR with the same stale
  redemption-rate oracle and an open market.
- **Monitor:** `Liquidity.updateUserSupplyConfigs` / `updateUserBorrowConfigs` (unpause), vault
  borrow-limit changes, new Fluid wstUSR listings, and the `0xA40a0dC2…` rate source (it will never
  reflect the USR market price — only a governance `forceResetMaxRate` / config change or a new oracle
  fixes the root cause).

**Blockers (frozen tokens):** wstUSR supply/withdraw + the paired stablecoin borrow/payback are paused
at the Liquidity layer; the DEX wstUSR/USDT pool is swap-paused with zero share caps.

---

## 7. PoC / fork-verification

Foundry project `poc/` (vendored `lib/forge-std`). Fork: keyless BSC RPC
(`vm.envOr("BSC_RPC_URL", "https://bsc-rpc.publicnode.com")`). **10/10 tests pass.**

| test | proves |
|---|---|
| `test_wstUSR_oracle_is_redemption_rate_not_market` | oracle = 1.13297e27, liquidate == operate, >13× market |
| `test_liquidity_borrow_limits_are_one_wei` | both T1 wstUSR vaults: maxBorrowLimit = 1, borrowable = 0 |
| `test_deposit_wstUSR_only_reverts_paused` | supply reverts `UserPaused` |
| `test_borrow_against_wstUSR_T1_USDT_reverts` / `_USDC_reverts` | borrow reverts |
| `test_borrow_against_wstUSR_T2_reverts` | T2 smart vault also blocked |
| `test_dex_swap_wstUSR_to_USDT_reverts_paused` | `DexT1__SwapAndArbitragePaused`, 0 USDT extracted |
| `test_dex_wstUSR_pool_is_locked` | maxSupplyShares=0, maxBorrowShares=0, swapPaused bit = 1 |
| `test_existing_wstUSR_position_withdraw_frozen` | existing positions can't withdraw |
| `test_latent_profit_per_wstUSR_if_rearmed` | 1.0197 USDT borrow capacity vs ~$0.083 cost |

Reproduce (local, read-only fork):
```
cd poc && forge test -vv --fork-url https://bsc-rpc.publicnode.com
```
CI: `bash /home/heisenberg/CA/ci/ci-run.sh venus-flux` → run URL recorded in `ci-log.txt`.
(`ci_run_urls` in `summary.json` is filled after the run.)

---

## 8. Methodology & sources

- **Enumeration:** `LiquidityResolver.listedTokens()`, `VaultResolver.getAllVaultsAddresses()` (35 vaults),
  `DexResolver.getAllDexAddresses()` (5 DEXes); per-vault `getVaultEntireData` (configs, oracle, totals,
  limits) — `analysis/fetch_vaults.py`, `analysis/vaults.json`.
- **Oracle trace:** per-token oracle address from `getVaultEntireData`, then oracle source
  (Chainlink / Fluid CappedRate / GenericOracle / DexSmartPeg) read from verified source +
  constructor args in `deployments/bnb/*.json`; live values via `getExchangeRate()` /
  `latestAnswer()` — `analysis/oracle-trace.md`, `analysis/reads.sh`, `analysis/evidence.txt`.
- **Lockdown:** Liquidity user supply/borrow raw configs decoded for the pause bit
  (`analysis/pause_bits.py`); DEX configs + `dexVariables2` bit 255; `getTotalSupplySharesRaw`.
- **Fork PoC:** Foundry `poc/` (this repo) — 10 tests.
- **Prices:** DefiLlama `coins.llama.fi` + CoinGecko (USR/wstUSR).
- **Incident context:** Cointelegraph 2026-03-22/24; post-mortem gist `andrewhong5297/f8895e7a2539ca702e87bbecb345c736`.
- Prior coverage respected: `zombie-hunt-iv/pass4/verify-fluid.md` (Ethereum Fluid MM H-1 = FIXED) is
  **not** re-done here; this work is the BSC oracle/price path.

### Caveats & limitations
- E-U is $0 **because of a governance lockdown**, not because the oracle is correct. The mis-pricing
  is still deployed and would re-arm on any unpause / limit change / new listing / other chain.
- wstUSR has no reliable BSC market print; the ~$0.083 value is the Ethereum wstUSR price (DefiLlama) and wstUSR
  is a bridged OFT, so arbitrage should equate the two.
- Point-in-time 2026-10-23; governance can change pause/limit state at any block.

### Files index
```
venus-flux/
├── README.md                     this file
├── summary.json                  machine-readable summary
├── analysis/
│   ├── oracle-trace.md           full per-token oracle trace + lockdown evidence
│   ├── vaults.json               35-vault snapshot (block 129287349)
│   ├── fetch_vaults.py           vault enumerator
│   ├── totals.py                 USD totals + global liquidity
│   ├── pause_bits.py             Liquidity user pause-bit decoder
│   ├── reads.sh / evidence.txt   raw reproducible reads
│   └── sources/                  verified source excerpts (vault/userModule/errorTypes)
├── poc/                          Foundry project (foundry.toml, test/FluxBSC.t.sol, lib/forge-std)
├── ci-out/                       (CI artifacts, if any)
├── ci-log.txt / ci-artifacts/    (populated by ci-run.sh)
```
