# Child A — live sanity check (read-only, public RPCs + DefiLlama)

Date: 2026-10-23. Method: `eth_getCode` / `eth_getBalance` / view calls at current head via public RPCs; USD from `coins.llama.fi`. No keys, no writes, no txs.

---

## 1. Cabal LST — Initia (non-EVM)
- Chain: Initia / Cabal / Strat (Move, non-EVM) — **no EVM address**.
- DefiLlama `cabal` (Governance Incentives): total TVL **≈ $2,744,795** (latest point 1792734023).
  - per-chain: Initia **$2,114,327**, Cabal **$127,578**, Strat **$502,890**.
- Verdict: **non-EVM, TVL only** — live, ~$2.74M TVL. No contract to inspect here.

## 2. shMonad — Monad (143)
- Proxy `0x1B68626dCa36c7fE922fD2d55E4f631d962dE19c`; impl (EIP-1967) `0x8ee4ff5fF50198dcbb7b882a0781f42724DD095f` (matches "0x8ee4ff5f…").
- Block **115,828,947**. `eth_getCode`: **present** (proxy + impl).
- Native balance: **8,365,651.27 MON** (8.3656e24 wei) ≈ **$182,130** @ $0.021771.
- `totalAssets()` = 333,812,435.085 MON ≈ **$7,267,000** (staked/delegated + held). `totalSupply()` (shMON, 18dp) = 203,379,679.31.
- Verdict: **live + funded** (~$7.27M assets). Surprise: native balance is only ~2.5% of totalAssets (rest is staked/delegated) — a native-balance-only check would under-report.

## 3. Kipseli — Base (8453)
- "reserve" `0xbee3211ab312a8d065c4fef0247448e17a8da000`. Block **52,974,224**.
- `eth_getCode`: **present** (4,019 hex chars ≈ 2,009 bytes) — it is a **deployed contract, not an EOA**, despite being flagged "unverified".
- Native (ETH): **0**. Token balances: USDC `0x8335…2913` = **440,831.23** (≈$440.6k); WETH `0x4200…0006` = **31.0887** (≈$74,706 @ $2,403); USDT `0xfde4…9bb2` = 0.
- DefiLlama `kipseli` currentChainTvls: Base **$694,460**, Robinhood Chain $299,284, Binance $395,648 (total ≈$1.39M).
- Verdict: **live + funded** on Base (contract holds ~$515k in the two checked tokens; DL Base TVL $694k).

## 4. Metropolis DLMM VaultFactory — Sonic (146)
- `0x197d40B36677248E82939f96930bf4E7Fe8aD1c2`. Block **81,493,855**.
- `eth_getCode`: **present** (4,483 hex chars). Native (S): **0**. `owner()` = `0xd1f2823f3aBF4b8c7Ad1B6629421b2618a5e28aF`.
- Verdict: **live** (deployed factory); native balance 0 as expected for a factory (not a value-holding vault).

## 5. Morpho VaultV2 — World Chain (480)
- `0x5C6F9354b6176C14f7dF1C1e16a0DC4A0Ff9c3E1`. Block **36,701,092** (thirdweb) / 36,701,078 (alchemy public).
- `eth_getCode`: **present** (43,619 hex chars ≈ 21.8 KB). Native (ETH): **0**.
- ERC-4626: `asset()` = `0x2cFc85d8E48F8EAB294be644d9E25C3030863003` = **WLD** (18dp); `totalAssets()` = **425,753.227 WLD** ≈ **$235,158** @ $0.5524.
- Verdict: **live + funded** (~$235k). Surprise: contract `name()` = **"AgentBank Deposit Vault"**, asset is **WLD** (not a stablecoin) — confirm it really is the intended "Morpho VaultV2" target, not an unrelated AgentBank vault.

## 6. CIAN Yield Layer — Mantle (5000)
- Block **102,303,744**.
- Vault `0x6B2BA8F249cC1376f2A02A9FaF8BEcA5D7718DCf` — `eth_getCode`: **present**; name **"Bybit-CIAN Yield Layer USDC"**; `asset()` = `0x09Bc…0dF9` (USDC, 6dp); `totalAssets()` = 36,444,326.42 USDC ≈ **$36,430,000**; native MNT 0.0000364.
- Vault `0x74D2Bef5Afe200DaCC76FE2D3C4022435b54CdbB` — `eth_getCode`: **present**; name **"Bybit-CIAN Yield Layer USDT0"**; `asset()` = `0x779D…3736` (USDT0, 6dp); `totalAssets()` = 74,063,685.12 USDT0 ≈ **$73,970,000**; native MNT 0.0000741.
- Combined ≈ **$110.4M**, matching DefiLlama `cian-protocol` Mantle currentChainTvl **$110,220,211** (global DL TVL ≈$318M).
- Verdict: **live + funded** (~$110.4M across the two vaults).

---

## Summary (2 lines)
All six candidates are **live**: Cabal is non-EVM (~$2.74M TVL, TVL only); shMonad ~$7.27M, Kipseli Base ~$694k, Metropolis Sonic factory live (0 native), Morpho/AgentBank World ~$235k WLD, CIAN Mantle ~$110.4M.
No empty/dead targets; surprises: Kipseli "reserve" is a deployed contract (not an EOA), the World Chain vault is "AgentBank Deposit Vault" holding WLD, and shMonad holds only ~2.5% of totalAssets as native MON.
