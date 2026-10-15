# DEX-market sweep for Horizon Protocol zAssets (independent verification)

**Question:** does ANY Horizon zAsset synth have a tradeable DEX market on BSC? This decides whether the live
`exchange()` (synth↔synth at oracle prices, fee ~0.32%) can be arbitraged by buying cheap zUSD on PancakeSwap
(~$0.578) and selling the received synth at market.

**Method** (`scan.py`, run at BSC block 127,738,225; public RPCs only):
* Factory sanity round-trip (`getPair` → `factory()`) for 7 V2 factories: PancakeSwap V2 `0xca143ce3…`, PancakeSwap V1
  `0xbcfccbde…`, ApeSwap `0x0841bd0b…`, BiSwap `0x858e3312…`, MDEX `0x3cd1c460…`, BabySwap `0x86407bea…`,
  BakerySwap `0x01bf7c66…` — all 7 verified OK.
* 1,134 `getPair(synth, quote)` calls: 27 synth addresses (26 registered + alternate zUSD proxy `0xf0186490…`) ×
  6 quotes (WBNB, BUSD, USDT, BTCB, ETH, CAKE) × 7 factories → **1 pair found** (see below), 1,133 zero, 0 errors.
* 216 `getPool(synth, quote, fee)` calls on PancakeSwap V3 `0x0bfbcf9f…` (fee tiers 100/500/2500/10000, quotes
  WBNB/USDT) → **1 pool found, with `liquidity = 0`**, 215 zero, 0 errors.
* Cross-check: DexScreener search/token lookups for the synth symbols/addresses (no BSC synth pairs beyond the one below).

**Result — only the zUSD/BUSD pair exists:**
| DEX | Pair | Tokens | Reserves | Note |
|---|---|---|---|---|
| PancakeSwap V2 | `0xc3bf4e0ea6b76c8edd838e14be2116c862c88bdf` | BUSD / zUSD (alt proxy `0xf0186490…`, same Synth target as registered `0x7F11125A…`) | 2,901.2615 BUSD + 5,020.9053 zUSD | spot $0.5778/zUSD; LP supply 3,407.94, 37.96% staked in dead farm |
| PancakeSwap V3 | `0xf92c986f3e5fe6b1446b1564aa763970071ada1d` | USDT / zUSD | `liquidity = 0` (empty) | unusable |

**Sanity check:** the zUSD/BUSD pair (which is known to exist) WAS found by the method — so the negative results are
trustworthy.

**Verdict:** **no zAsset other than zUSD has any DEX market on BSC, and zUSD's only market is the one dead V2 pair.**
Therefore the live `exchange()` cannot be arbitraged for a profit: exchanging cheap zUSD into zBNB/zBTC/zETH/… yields a
synth with **no exit market**, and exchanging it back to zUSD is circular (minus fees). The BUSD side of the zUSD/BUSD
pair is not extractable because zUSD cannot be minted (issuance blocked by the stale HZN oracle) nor bought below that
pair's own price.

**Caveats:** factory-based checks cover the listed V2/V3-style DEXs only (plus DexScreener cross-check); a bespoke
market outside these factories and not indexed by DexScreener would be missed. Additional legacy proxy addresses per
synth are possible (zUSD had one); the symbol cross-check mitigates this.
