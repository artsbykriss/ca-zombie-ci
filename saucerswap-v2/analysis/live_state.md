# SaucerSwap V2 — live-state snapshot (read-only)

All reads 2026-10-23 (UTC) via keyless endpoints: `https://mainnet.hashio.io/api` (chainId 295) and
`https://mainnet-public.mirrornode.hedera.com/api/v1`. No transaction signed or sent.

- Factory `SaucerSwapV2Factory` = `0.0.3946833` / `0x00000000000000000000000000000000003c3951` (code 24,535 B, Sourcify exact)
- NFPM `SaucerSwapV2NonfungiblePositionManagerV2` = `0.0.4053945` / `0x00000000000000000000000000000000003ddbb9` (21,218 B, Sourcify exact)
- SwapRouter = `0.0.3949434` / `0x00000000000000000000000000000000003c437a` (13,831 B, exact)
- QuoterV2 = `0.0.3949424` / `0x00000000000000000000000000000000003c4370` (10,535 B, exact)
- LP NFT (HTS) = `0.0.4054027` / `0x00000000000000000000000000000000003ddc0b` — supplyKey = NFPM contract, no admin/kyc/freeze/wipe/pause keys, totalSupply 3881

## Factory live state
- owner = `0x0000000000000000000000000000000000103179` (EOA, code size 0)
- rentPayer = `0x0000000000000000000000000000000000102556` (EOA, code size 0)
- mintFee = `500000000` tinycents (~$0.05 → 61,672,813 tinybar ≈ 0.617 HBAR per mint)
- poolCreateFee = `10000000000000000` tinycents (~$1,000,000 → 1,233,456,267,808,024 tinybar ≈ 12.33M HBAR) — pool creation is effectively frozen
- no proxies (EIP-1967 impl slot = 0 on factory/NFPM/router/quoter)

## Pools (PoolCreated logs)
- **56 pools** total; newest created 2026-07-06 (block 97,318,913), oldest 2023-11-07
- fee tiers: 500 (7), 1500 (23), 3000 (19), 10000 (7)
- measured 2-sided pool TVL = **$17,614,148** at the read block (DefiLlama reports $15,888,282)

### Top pools by measured 2-sided TVL

| pool | pair | fee | token0 amt | token1 amt | TVL (USD) |
|---|---|---|---|---|---|
| `0x7eed8ad5b0b83d24bd4777c5a64e89e07f6fb692` | HBARX/HBAR | 1500 | 1.19401e+07 | 7.54837e+07 | $7,455,546 |
| `0xc5b707348da504e9be1bd4e21525459830e7b11d` | USDC/HBAR | 1500 | 1.12215e+06 | 3.75694e+07 | $4,146,632 |
| `0x335b3a8aaaecd63019091187dc8d99574f6552d0` | USDC/HTS-WETH | 1500 | 319679 | 393.541 | $1,265,039 |
| `0xaad728c531150e7ed89d5ae15638d0b552f2e71a` | HBAR/HTS-WBTC | 3000 | 4.09227e+06 | 4.04875 | $659,073 |
| `0x3c06ae8b2302958a5d5854a42f7f66fb396da4f6` | HBAR/HTS-WETH | 1500 | 4.05238e+06 | 135.855 | $652,572 |
| `0x3c8dbcb8475450569091f8c311b558d62cc39cf7` | USDC/HTS-WBTC | 1500 | 319559 | 3.92111 | $638,814 |
| `0x6a1ab8ed2e95c14843be797129936a7b40e39d8b` | HBAR/DOVU | 10000 | 3.27591e+06 | 9.10154e+07 | $362,488 |
| `0x017ee56b8a9098f5a9bde20075deb0c5a6906ef1` | USDC/USDT0 | 500 | 337664 | 8792.06 | $346,480 |
| `0x5fc19c944f1bccf5159e6ae92dc3bf2ff2576b98` | SAUCE/HBAR | 3000 | 1.77377e+07 | 1.26928e+06 | $305,884 |
| `0x509ada3a75a1d0118388f059e240ea2e18e8140b` | HBAR/PACK | 3000 | 1.51972e+06 | 2.4433e+07 | $267,748 |
| `0x7b03c1d76d24aa0cd361a4f2780106a6d20003c2` | HBAR/BONZO | 3000 | 447938 | 4.12057e+07 | $238,085 |
| `0x1e457cd3e86e31ea4df480cd4a3b9f06a4218d3c` | HBAR/KARATE | 3000 | 1.0743e+06 | 4.39551e+09 | $169,521 |
| `0xcfeffaae43f176f91602d75ec1d0637e273c973b` | SAUCE/XSAUCE | 1500 | 1.09898e+07 | 2.46539e+06 | $162,715 |
| `0x4d922a11e2d18cee52f9c83a86cb942a76249595` | HBAR/gib | 10000 | 930638 | 4.15257e+07 | $155,384 |
| `0xb3f4c4bdbd2c7466c43d9c90d97d893f2914dead` | GRELF/HBAR | 3000 | 1.18625e+06 | 496061 | $133,304 |

### Native HBAR held by pools (mint fees)
- Sum across 29 pools = **2,132.29 HBAR ≈ $171.82** (HBAR $0.08058). Extractable only by the factory owner via `UniswapV3Pool.collectProtocol` → `rentPayer` (privileged, P-class).
- Pool native balances are otherwise untouched by any permissionless function.

### Protocol-fee state
- Example pool USDC/HBAR `0xc5b707348da504e9be1bd4e21525459830e7b11d`: `slot0.feeProtocol = 102` (0x66 → 6/6) — protocol fee enabled; collectable only by the factory owner (`collectProtocol`).

### Verification of periphery wiring
- `PoolAddress.POOL_INIT_CODE_HASH = 0xa6f90015e94bcf7783c4347fcb9fe3142d5cd50b237b20ba6cfc93d80af56a8c`.
- CREATE2 recomputation for USDC/HBAR fee-1500 reproduces the on-chain pool `0xc5b707348da504e9be1bd4e21525459830e7b11d` exactly → the deployed pool bytecode matches the verified `UniswapV3Pool` source.
