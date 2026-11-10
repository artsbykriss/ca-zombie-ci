# Live sanity checks — CA3 residual reconciliation

Read-only `eth_call` / `balanceOf` / `eth_getStorageAt`. No transactions, no keys, no fork.
All times UTC, 2026-11-10. USD is context only.

## Block anchors

| Chain | Block | Method |
|---|---:|---|
| Ethereum | 26,380,997 | `eth_blockNumber` (publicnode) |
| Base | 55,405,158 | `eth_blockNumber` (mainnet.base.org) |
| Arbitrum | 522,832,557 | `eth_blockNumber` (arb1) |
| Pharos 1672 | 22,609,065 | `eth_blockNumber` (rpc.pharos.xyz) |
| Robinhood 4663 | 110,337,185 | CA3 read (not re-read in this pass) |
| BSC 56 | 132,657,191 | CA3/incident-patterns read (not re-read) |
| PulseChain 369 | 28,016,834 | CA3/incident-patterns read (not re-read) |

## Prior-closed large-fund rows — funds still present

| Target | Read | Value | Prior verdict |
|---|---|---:|---|
| Popdex bridge `0x0B15D6cF5e843C88034f64664D7fE66E5F79C5f2` | USDT0 `0xFd086bC7…` `balanceOf` @ Arb 522,832,117 | **74,937,815.664264 USDT0** | CLOSED E-U $0 (`wave2/v14-popdex.md`) |
| STRATO Safe `0x8c458f866e603335ef179a63a2528f357732f5d5` | ETH + USDC + USDT + wstETH @ ETH 26,380,997 | **70.38591955 ETH + 438,616.801305 USDC + 36,898.716576 USDT + 55.74050798 wstETH** (~$1.144M) | CLOSED E-U $0 (`ZH2B6 H2-05`) |
| Pacifica `PCFA5iY…` | not re-read | $2.28M program + $22M Squads cold (pass6) | CLOSED E-U $0 (`pass6/pacifica-bridge.md`) |
| JustLend sTRX `TU3kjFuht…` | not re-read | $3.135B TVL (DefiLlama) | CLOSED E-U $0 (`wave1/r4-non-evm.md` row 9) |

## OPEN candidates

### S05 — Vesper V2 fleet

- Pool API: `api.vesper.finance/pools?stages=prod` = **14 Ethereum pools**; `api-base.vesper.finance/pools` = **5 Base pools**. DefiLlama `currentChainTvls`: Ethereum **$78,464,470**, Base **$6,556,492**, OP **$2,339,934** (total ≈ **$87.36M**).
- Research checked only `vUSDC` (`0x0C49066C…`) and `vETH` (`0x103cc17C…`) yield vaults = **$9.69M** (CA3 `defillama-new.md` §4.7).
- Sampled pool `vaUSDC` `0xa8b607Aa09B6A2E306F93e74c282Fb13f6A80452` @ ETH 26,380,997:
  - `totalValue()` = `488409425967` = **488,409.425967 USDC**; `totalSupply()` = 373,075.756098 shares; `token()` = USDC; `governor()` = `0x9520b477Aa81180E6DdC006Fc09Fb6d3eb4e807A`.
  - ERC-1967 impl = `0x3ceddef5cbe54674fcbe1b4368a68b8d6a20fc46` (17,991 B, proxy runtime 2,004 B).
  - Selectors include `reportEarning(uint256,uint256,uint256)` `0x05bed046`, `migrateStrategy(address,address)` `0x6cb56d19`, `shutdown()`/`open()` `0xfc0e74d1`/`0xfcfff16f`, `whitelistedWithdraw(uint256)` `0xff643a7c`.
  - Fresh EOA: `reportEarning(0,0,0)` → revert **`16`** (controller gate); `migrateStrategy` → **`not-governor`**; `shutdown`/`open` → **`not-a-keeper`**; `depositAndClaim(1)` → `ERC20: transfer amount exceeds allowance` (self-scoped pull).
- `vaETH` `0xd1C117319B3595fbc39b471AB1fd485629eb05F2`: `reportEarning` → **`16`**; `whitelistedWithdraw(1)` → `ERC20: burn amount exceeds balance` (caller's own shares).
- Base `vaUSDC` `0x1e41238aCd3A9fF90b0DCB9ea96Cf45F104e09Ef` @ Base 55,405,158: `totalValue()` = **22,060.319011 USDC**; `reportEarning` → **`16`**; `migrateStrategy` → **`not-governor`**.
- Unsampled: 16 of 19 pools. Gate pattern is consistent on 3/3 sampled, but the V2 yield-vault wrappers and older pools were not checked.

### S12 — Faroo stPROS

- `stPROS` `0x6b0a44c64190279f7034b77c13a566e914fe5ec4` @ Pharos 22,609,065:
  - proxy runtime 2,739 B; ERC-1967 impl `0xfd59860894e01773e9780b0d1dfae4ca2b56708d`; admin `0x4238ea4adfa2bd6a5fc9b5e245dc1900cf0258aa`.
  - `name` "Faroo Staked PROS", `symbol` "stPROS", `decimals` 18, `asset` `0x52C48d4213107b20bC583832b0d951FB9CA8F0B0` (WPROS).
  - `totalAssets()` = `5119038227419281297341765` = **5,119,038.227419 PROS**; `totalSupply()` = `5077168065213820953538995` = **5,077,168.065214 stPROS**; `convertToAssets(1e18)` = **1.008246755212287229**.
  - `redeem`/`withdraw` from a fresh EOA → `ERC4626ExceededMaxRedeem/Withdraw` (self-scoped, max 0); `owner()` = `0xC30dB0543412c6881A543390d2c21FbBFf42805b`; `paused()` = false.
- Custody from DefiLlama adapter (`projects/faroo/index.js`): `SlpDistributor 0xf772b375f93650f798bf724ce7a9a45c9e7a579f` (220 PROS), `BridgeVault 0xf1df1cb080256f48e8702c24149136e4a6dec25e` (**1,157.991212614 PROS**), `RewardsVault 0xd0c44d3079e97ff285dd7a3e4e0246320a9487e5` (0), SLP `0xec1d6163…` (0), `0xc53d2c9d…` (0), staking precompile `0x4100000000000000000000000000000000000000`.
- All five custody contracts are 2,739-B ERC-1967 proxies — **impls unverified / not enumerated**. TVL $2.73M (DefiLlama), mostly network-staked PROS.

### S35 — Cellana `vote_manager::rescue_stuck_rewards`

- Aptos package `0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1`, function `vote_manager::rescue_stuck_rewards(address, vector<Object<LiquidityPool>>, u64)`.
- No `&signer` parameter. CA3 simulation (read-only, dummy signature) executed for `u64` = 0/1/2 with **zero balance changes**; 100/1,000 hit `EXECUTION_LIMIT_REACHED`; 1,000,000+ overflowed. Cellana TVL not listed by DefiLlama at scan time.
- Not re-simulated in this pass (Aptos tooling not provisioned); funds bounded to reward pools, not LP principal.

## Other live reads

### Syntetika / Ember Hilbert BTC (S11)

- Base 55,405,158: vault `0x9C2dCDbDB3F0A0F628D1112bBCABD9AE75353df3` — `name` **"Ember Hilbert BTC"**, `symbol` **"hBTC"**, `decimals` 8, `asset` cbBTC `0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf`.
- `totalAssets()` = `21528668325` = **215.28668325 cbBTC** (~$16.16M); `totalSupply()` = `21344404001` = 213.44404001 hBTC; `convertToAssets(1e18)` = **1.008632910260208237**.
- `bridgeAdapter()` = **`0x0000…0000`** — the `bridgeMint` path has no adapter configured today. Proxy (170 B), impl `0x23cc7e7e237d84b1ec055e863097e864aa282a1c`, admin slot 0.
- Correction: CA3 labels this "Syntetika"; on-chain metadata is Ember's hBTC vault (Syntetika is the DefiLlama curator listing).

### Vesper API pool list (ETH)

`0x650CD45D…` vaCBETH · `0x0538C8bA…` vaDAI · `0xd1C11731…` vaETH · `0xc14900dF…` vaFRAX · `0xef4F4604…` vaLINK · `0xCa7c607C…` vamsETH · `0x4C73F025…` vamsUSD · `0xDD9F61a8…` vaRETH · `0x4Dbe3f01…` vaSTETH · `0xa8b607Aa…` vaUSDC · `0x01e1d41C…` vaWBTC · `0x103cc17C…` vETH · `0x0C49066C…` vUSDC · `0x4B2e76Eb…` vWBTC.

Base: `0x3899a609…` vacbETH · `0x82562507…` vaETH · `0x913Ece18…` vamsETH · `0x1e41238a…` vaUSDC · `0x46fb68Eb…` vawstETH.
