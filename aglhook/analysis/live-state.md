# AGLHook — live-state evidence (Ethereum mainnet)

**Read-only. No transaction signed or sent. All reads are `eth_call`/`eth_getLogs`/`eth_getCode`.**

Block references: `26096061` (hook deploy), `26097030` (pool launch), `26253656` (latest at capture,
2026-10-23). Fork tests ran at blocks `26253612`–`26253637`.

---

## 1. Contracts

| role | address | code | notes |
|---|---|---|---|
| Hook | `0xA61d74D6362699B76b21ef3016649A58D27bE0CC` | 3,850 B | verified `AGLHook`, solc 0.8.37, no proxy |
| PoolManager | `0x000000000004444c5dc75cB358380D2e3dE08A90` | — | Uniswap v4 PoolManager (Ethereum) |
| AGL token | `0x63401cDd577478F9389A1683e866A937f072D1C2` | — | `Apex Gold Ledger` / `AGL`, 18 dp |
| Fee recipient | `0x06fbfb283bCA0d109bFB5Fd9CFb02B974D705998` | EOA (`0x`) | `xautFundWallet`, **immutable** |
| Fee-exempt | `0x8CCf65a2d5edFF1AAF865e6D75e70077a0e0bce5` | contract | `AGLBuyback` (sole entry in `feeExempt`) |
| Buyback operator | `0x69797731508079240Ef42b6F3235656fB3E6e119` | EOA (`0x`) | only address with `isOperator == true` |
| AGL owner | `0x9AfDee0B0AF90945e47E0D4e8D3139669A7c5F1A` | EOA (`0x`) | solady `Ownable` |

Hook deploy: tx `0xd904b84a…`, block `26096061`, CREATE2 factory `0x4e59b44847b379578588920ca78fbf26c0b4956c`,
deployer `0xcc4981815cdbdd881a2a110ef60d099990bc70ae`.

## 2. Hook reads (block 26253656)

| call | value |
|---|---|
| `REQUIRED_FLAGS()` | `0x20CC` (8396) |
| `uint160(hook) & 0x3FFF` | `0x20CC` ✅ matches |
| `bound()` | `true` |
| `boundPool()` | `0x02a13b057643e001f9436fa86e3c28945b6c4475a34e068df5c6ab4d42ff93bf` |
| `poolManager()` | `0x000000000004444c5dc75cB358380D2e3dE08A90` |
| `agl()` | `0x63401cDd577478F9389A1683e866A937f072D1C2` |
| `xautFundWallet()` | `0x06fbfb283bCA0d109bFB5Fd9CFb02B974D705998` |
| `owed()` | `600000000000000` (0.0006 ETH) |
| `PoolManager.balanceOf(hook, id=0)` | `600000000000000` — **equals `owed` exactly** |
| `hook` native ETH balance | `0` (holds an ERC-6909 claim, not ETH) |
| `owner()` / `admin()` / `paused()` | revert (no such functions) |
| EIP-1967 impl slot | `0x0` (not upgradeable) |

`feeExempt` is fixed at construction; the constructor calldata (in the deploy tx) shows the exempt
array length is **1** and its only element is `0x8CCf65a2…bce5` (the buyback). There is no setter.

## 3. AGL token (block 26253656)

| call | value |
|---|---|
| `name()` / `symbol()` | `Apex Gold Ledger` / `AGL` |
| `totalSupply()` | `984337440219669476708722211` (≈ 984.34 M; some burned) |
| `launchTs()` | `1790852411` = **2026-10-01 11:00:11 UTC** |
| `hook()` | `0xA61d74D6…E0CC` |
| `owner()` | `0x9AfDee0B0AF90945e47E0D4e8D3139669A7c5F1A` |

No mint-after-deploy, no pause, no blacklist, no fee-on-transfer. `openTrading` reverts (already
launched). `owner` has no path to balances, fees or liquidity.

## 4. Pool (ETH / AGL)

PoolKey = `(currency0=ETH, currency1=AGL, fee=0, tickSpacing=60, hooks=AGLHook)` → poolId
`0x02a13b05…93bf` (matches `boundPool`).

| field | value |
|---|---|
| `Initialize` block | `26097030` |
| initial `sqrtPriceX96` / `tick` | `0x144ec0a08115f73325de79b674c9` / `171132` |
| current `sqrtPriceX96` (b≈26253620) | `0x25a6e4d7cffb7ff13a431bfeaf2` |
| current `tick` | `128025` |
| `lpFee` / `protocolFee` | `0` / `0` |
| `liquidity` | `192469621223142870118663` |
| positions | **one** — ticks `[-887156, 171120]`, minted to the AGL contract (locked) |

Reserves (from liquidity + sqrtPrice + range, cross-checked against on-chain balances):
- **≈ 282.44 ETH**
- **≈ 115.95 M AGL** (PoolManager's AGL balance is 115,970,693.87 but that also carries a handful
  of unrelated AGL pools opened at launch; this pool's share is ≈ 115.95 M)
- mid price ≈ **362,923 AGL / ETH**

ETH = **$2,402.65** (DefiLlama `coins.llama.fi/prices/current/coingecko:ethereum`, 2026-10-23) ⇒
AGL ≈ **$0.006621**, **pool TVL ≈ $1.45 M** (282.44 × $2,402.65 + 115.95 M × $0.006621).

## 5. Fee flow (historical, block range 26097030 → 26253656)

| metric | value |
|---|---|
| `FeeCharged` events | ≥ **1000** (Etherscan page cap) |
| `FeeClaimed` events | **285** |
| total ETH claimed to `xautFundWallet` | **212.115 ETH** |

The mechanism is live and settling real value.

## 6. Reproduce

`analysis/read_state.sh` (uses `$RPC_URL`/`$NODEREAL_ETH_RPC_URL`/public fallback from the
environment — no secrets stored) and `analysis/decode_pool.py`.
