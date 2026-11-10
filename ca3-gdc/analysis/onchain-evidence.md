# GDC — on-chain evidence (2026-11-09 exploit + 2026-11-10 copy-cat)

All reads are keyless/public RPC `eth_call`/`eth_getLogs`/`eth_getTransactionReceipt`.
No transactions were signed or broadcast.

## 0. Units (this is the whole correction)

| Item | Raw value | 18-decimal value | USD @ $687.7169957527018 |
|---|---:|---:|---:|
| Pair WBNB "as reported by C3" | 44,080,303,063,849 wei | **0.000044080303063849 WBNB** | **$0.0303** |
| C3 claim | — | "44.080303063849 WBNB" | "$30.2k" |

C3 divided the raw wei by 1e12 instead of 1e18: the ratio of claim to reality is exactly **1,000,000×**.
`WBNB.decimals() = 18`; `GDCToken.decimals() = 18`; `pair.getReserves()` returns 112-bit raw wei.
DexScreener and GeckoTerminal independently report the pool's liquidity as **$0.04 / $0.0689**.

## 1. The 2026-11-09 exploit was real (51.2256 WBNB)

Pair `0xe3349Ca6AC1656e02B20b8d5a4C095e28255eb0A` (token0 = GDC, token1 = WBNB):

| Block | reserve0 (GDC wei) | reserve1 (WBNB wei) | WBNB (decimal) | USD |
|---:|---:|---:|---:|---:|
| 132,546,182 (pre) | 642,611,624,985,035,009,025,331,617 | 51,225,608,092,426,095,503 | 51.225608 | $35,228.72 |
| 132,546,183 (post) | 12,314,309,785,469,112,019,672 | 80,638,219,041,498 | 0.000080638 | $0.0555 |

Exploit tx: `0x1427d8e6f543710413886a1624e08f0b1cff8e62e9aa3e00eb04a61b86c30872`
- from `0x09343312e8a2fd4f8c8ee130a7715587ab21125f` → to contract `0xa7d63831f6399751d1a151f8d7448b7894418a4b` (unverified)
- `gasUsed = 2,924,278`; status 1; 107 logs.
- Intermediate pair state inside the tx: **66 wei GDC / 806,382.190414979402831419 WBNB** — matches the
  "66 wei GDC against 806,382 WBNB" description in `ca3/README.md` §5.2.
- WBNB flows in the tx: a 207,316.511906 WBNB in-transfer from `0x8f73b65b4caaf64fba2af91cc5d4a2a1318e5d8c`
  (verified `ERC1967Proxy`), 806,382.190334 WBNB back out of the pair to the attacker contract, and a
  final **50.008996501098265649 BNB** profit transfer. At $687.72 that is **$34,392.04**.

So the corpus got the exploit right and the residual wrong.

## 2. The residual after the exploit was dust, and is now gone

| Time | Block | WBNB in pair | USD |
|---|---:|---:|---:|
| 2026-11-09 post-exploit | 132,546,183 | 0.000080638219041498 | $0.0555 |
| C3 re-check ("44.08 WBNB") | 132,651,750 | 0.000044080303063849 | $0.0303 |
| 2026-11-10 before copy-cat | 132,672,605 | 0.000044080303063849 | $0.0303 |
| 2026-11-10 after copy-cat | 132,672,606 | 0.000041429328023098 | $0.0285 |
| Latest check | 132,680,921 | **0.000032856030398949** | **$0.0226** |

### Copy-cat tx `0x0f7bb6a7d12c9d25eb1fbee4f280acaf9fafd0ba4bab58e48a66f6cef9c002ce`

- block 132,672,606; from `0x77Aabf4517f962d772C64c33e2F75D246670aB0A` to PancakeSwap Router; `gasUsed = 1,003,754`.
- sold **1,100 GDC** (`0x3ba1910bf341b00000`).
- `SellTaxForwarded`: gross 1,100 GDC, tax 770 GDC (`0x577257fa…`).
- inner tax swap moved 603.625 GDC into the pair, took **2,054,437,188,018 wei (0.000002054 WBNB)** out.
- `ReserveFloorDistribution`: actual 1,100 GDC burned from the pair; `sync()`.
- outer (user 30%) leg: 330 GDC credited to the pair, paid **1,137,693,488,197 wei (0.0000011377 WBNB)**
  (`0x108e3d0f445`).
- **Gas cost alone: 1,003,754 × 0.05 gwei = 50,187,700,000,000 wei = $0.0345**, i.e. **1.53× the entire
  WBNB value the attacker could ever receive from the pool ($0.0226)**.

The attacker held 11,777.14 GDC and an infinite router allowance before the tx
(`balanceOf = 11,777,140,000,000,000,000,000`, `allowance = 2^256-1` at block 132,672,605).

A second copy-cat sell took the pair to 0.000039966955789245 WBNB (block ≈132,673,000); further micro-sells
left the current 0.000032856030398949.

## 3. Current live state (block 132,680,921)

| Field | Value |
|---|---|
| pair reserve0 | 12,316,971,177,631,596,075,223 wei = 12,316.971177631596 GDC |
| pair reserve1 | 32,856,030,398,949 wei = 0.000032856030398949 WBNB |
| pair WBNB balance | 32,856,030,398,949 wei (== reserve) |
| pair GDC balance | 12,316,971,177,631,596,075,223 wei (== reserve) |
| `blockTimestampLast` | 1,794,267,404 |
| `maxSellAmount()` | 1,231,697,117,763,159,607,522 wei = 1,231.697117763159607522 GDC |
| `currentStage()` | 1 |
| `reserveDistributor()` | `0x3cf55c7c22C6555139c818aB7a7a89aFf70F8360` (live, holds 999,943,033.640715 GDC) |
| `depositContract()` / Main | `0x8955Be303f033a837f7C3c407e0B2b3f9bC4fD5C` |
| `companyAccount()` | `0x9B8439CE1A7CcE61d4A1479343fdd17140411367` (EOA; 2.400754 BNB) |
| `rewardAccount()` | `0xc9410A0c2E7aFF6eB0eA77B126F8800150135401` (EOA; 0.978084 BNB) |
| token owner / Main owner | `0x83a9aeabbb20a6ff3a51d252193d3d8cfe68e1f2` (EOA) |
| token `totalSupply` | 2,400,000,000 GDC |
| GDC in `DEAD` | 968,277,924.023397927928 (40.34%) |
| GDC in Main | 3,239.26 |
| Main `pendingReserveDividend` / `distributionRemaining` | 0 / 3,239.26 |
| LP total supply / burned to DEAD | 260,886.702206 / 260,176.840275 (99.73%) |
| token contract native BNB | 0.0023 BNB (no sweep; $1.58) |

Pool price: 2.667541388e-9 WBNB/GDC = **$1.8345e-6/GDC**; whole 2.4B float nominal = **$4,402.83**,
realizable = **$0.0226**.

## 4. Acquisition / alternate paths (all tested on the fork)

| Route | Result |
|---|---|
| Buy GDC from the pair via router to attacker | **reverts** (`BuyingProhibited`) — `from == pair` and `to` not whitelisted |
| Buy GDC from the pair to `GDCMain` (whitelisted) | succeeds, but GDC lands in Main; no Main function sends GDC to an arbitrary caller |
| `pair.swap` GDC out to attacker | **reverts** (`BuyingProhibited`); only `to = DEAD` or `to = token` is allowed |
| `pair.skim(thief)` | **reverts** (`BuyingProhibited`), even at zero excess. Test `test_10` |
| Second DEX pair | none: factory `getPair(GDC,WBNB) == pair`; `token.pair() == pair`; `UnsupportedPool` blocks any other pool; DexScreener/GeckoTerminal show one pool |
| `distribute(uint256)` direct | **reverts** (`onlyController` = token). Test `test_11` |
| Second sell in the same block | **reverts** (`SameBlockTrade`). Test `test_12` |
| Repeat sell next block | allowed, output shrinks (945.6e9 → 882.2e9 wei). Test `test_13` |
| CEX / OTC | none found; FDV $2,635, one pool, 24h volume is wash flow |
| Flash loan | not needed and not useful: the entire pair is $0.02 |

## 5. Hard economic ceiling

```
pool WBNB                        = 32,856,030,398,949 wei
gas price                        = 50,000,000 wei (0.05 gwei, eth_gasPrice)
break-even gas for 100% of pool  = 657,120 gas
observed exploit-path gas        = 1,003,754 gas
```

Even an impossible 100%-effective drain, with zero acquisition cost and zero flash fee, cannot pay for
the gas of the transaction that performs it. The real path yields 945,627,483,667 wei ($0.00065) against
830,296 gas ($0.0285): **net −0.0000406 BNB (−$0.0279)** per attempt.
