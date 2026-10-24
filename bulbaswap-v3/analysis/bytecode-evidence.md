# BulbaSwap V3 — code-identity evidence

**Date:** 2026-10-24 · **Chain:** Morph (chain id 2818) · **Method:** read-only (`eth_getCode`, Blockscout v2 API, DefiLlama)

## 1. Target

| item | value |
|---|---|
| Factory | `0xFf8578C2949148A6F19b7958aE86CAAb2779CDDD` (explorer name: `VitDEXFactory`) |
| Representative pool | `0x5191035D329f481eFf0143e690e0a4e366Dd1e0c` — WETH/USDT, fee 500 (0.05%), tickSpacing 10 |
| Pools deployed by factory | **212** (`PoolCreated` logs) |
| Factory owner | `0x9876097201662D70A63C935c2f7576B35D6f45e7` |
| DL TVL | ~$8.8M (`uniswapV3.js` registry, `forkedFromIds:[2198]`) |
| Block used | `28776889` |

## 2. Factory bytecode == canonical UniswapV3Factory

Canonical mainnet factory `0x1F98431c8aD98523631AE4a59f267346ea31F984`:

| | bytes |
|---|---|
| canonical mainnet factory runtime code | 24,535 |
| Morph factory runtime code | 24,535 |
| differing bytes | **20** |
| positions | 1374–1393 |

The 20 differing bytes are exactly the factory's own address (the `NoDelegateCall.original`
immutable). After zeroing each factory's own 20-byte address occurrence, the two runtime
codes are **byte-identical** (`keccak256` equal).

```
eth   @1374: 1f98431c8ad98523631ae4a59f267346ea31f984   (canonical factory address)
morph @1374: ff8578c2949148a6f19b7958ae86caab2779cddd   (Morph factory address)
```

**Consequence:** `UniswapV3Factory.createPool` deploys pools from the pool creation code
embedded in the factory runtime code. Identical factory bytecode ⇒ identical pool creation
code ⇒ every one of the 212 pools is canonical `UniswapV3Pool` bytecode.

## 3. Pool bytecode == canonical UniswapV3Pool (modulo immutables)

| | bytes |
|---|---|
| canonical mainnet pool `0x8ad599c3…` (USDC/WETH 0.3%) runtime code | 22,142 |
| Morph pool `0x5191035D…` (WETH/USDT 0.05%) runtime code | 22,142 |
| differing bytes (raw) | 376 |
| differing bytes after zeroing token0/token1/factory/pool addresses | **57** |

The 57 residual bytes are the fee (500 vs 3000), tickSpacing (10 vs 60) and the derived
`maxLiquidityPerTick` uint128 constant — all immutable/derived values. No executable logic
differs.

## 4. Verified source == canonical source

The pool is **verified** on `explorer-api.morphl2.io` as `UniswapV3Pool`
(solc `v0.7.6+commit.7338295f`, optimizer runs 800, `is_changed_bytecode: false`).
After stripping `pragma`/`import` lines and whitespace, **all 31 files of the flattened
source are byte-identical to canonical Uniswap v3-core** (imports/pragma ranges differ only
because of flattening). ABI = canonical 25 functions (`swap`, `mint`, `burn`, `flash`,
`collect`, `collectProtocol`, `setFeeProtocol`, …).

The factory source is likewise canonical `UniswapV3Factory` (solc 0.7.6).

## 5. Conclusion

BulbaSwap V3 is an **unmodified** Uniswap V3 deployment. The pool math, mint/burn, flash
path, oracle and fee accounting are the battle-tested canonical code. There is **no
unprivileged value path** in the AMM: `collectProtocol`/`setFeeProtocol` are
`onlyFactoryOwner` (privileged), swaps/mints/burns/flash follow canonical accounting, and a
deposit→swap→withdraw roundtrip is net-negative (fees). Fork PoC: `poc/test/BulbaV3.t.sol`.
