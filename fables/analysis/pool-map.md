# Registry → 68 pools (FablesPoolRegistry `0x159a113e012593d9b3cc63ad45e30f0467e13ef3`)

All 68 pools are `active=true`. `L` = v4 pool liquidity (extsload slot `keccak(poolId,6)+3`, block ~89.74M).
`claims` = hook-held ERC-6909 claims for that pool's currencies (unclaimed fees + pots). USD priced via DefiLlama
`coins.llama.fi` on 2026-10-16 (pools with an unpriced memecoin show the priced leg only).

| # | poolId | hook | pair | fee pips | tickSpacing | L | hook claims (USD, priced) |
|---|---|---|---|---|---|---|---|
| 0 | `0x7990aad9e8fb…cb3dcd` | 0x66622f77b7 | USDG/NVDA | 8388608 | 10 | 0.5211e18 | $2,553 |
| 1 | `0x8674c1c5544f…5b8dcd` | 0xa0e8fbff13 | SPY/USDG | 8388608 | 10 | 3.334e18 | $1,672 |
| 2 | `0x988f3b6ceec4…bd485f` | 0x79576fbad6 | SPY/NVDA | 8388608 | 10 | 736.8e18 | $65 |
| 3 | `0xa2347ba69167…070147` | 0x70a9a88402 | USDG/AAPL | 8388608 | 10 | 0.2485e18 | $1,253 |
| 4 | `0xd5effce87036…331e8e` | 0x67d86050d2 | TSLA/USDG | 8388608 | 10 | 0.08442e18 | $1,308 |
| 5 | `0xbac3aa3b9158…bde551` | FablesRampETH(OLD) | ETH/USDG | 8388608 | 10 | 10.93e18 | $27,158 |
| 6 | `0xfe281bbfa9aa…5a7a3a` | 0xb608a78761 | USDG/GLD | 8388608 | 10 | 2.16e18 | $2,953 |
| 7 | `0x118887805417…4c397f` | 0xa4570c3759 | SPY/GLD | 8388608 | 10 | 96.46e18 | $8 |
| 8 | `0x4ac4259eb99d…4aa4f5` | 0x8af95932ec | USDG/META | 8388608 | 10 | 0.006723e18 | $562 |
| 9 | `0x6ef20273e821…7b8bb9` | FablesRWA | AMC/USDG | 8388608 | 60 | 0.04657e18 | $1,997 |
| 10 | `0x31608601d541…a16212` | FablesRamp | CASHCAT/USDG | 8388608 | 60 | 2.666e18 | $18,531 |
| 11 | `0x31f8624041c9…94726b` | FablesRWAETH | ETH/AMC | 8388608 | 60 | 1704e18 | $28 |
| 12 | `0xb59001413cb0…cce674` | FablesRampETH | ETH/PONS | 8388608 | 60 | 5.007e+04e18 | $543 |
| 13 | `0x5619cb842067…66346f` | FablesRWA | AMZN/USDG | 8388608 | 60 | 0.1282e18 | $2,383 |
| 14 | `0x16dce5f6a91b…7248a7` | FablesRWA | USDG/HIMS | 8388608 | 60 | 0.03234e18 | $2,042 |
| 15 | `0xb81d873dfb2b…4452b9` | FablesRWA | SPCX/USDG | 8388608 | 10 | 0.4299e18 | $3,018 |
| 16 | `0x486435a1f76c…7fa6ea` | FablesRamp | PONS/USDG | 8388608 | 60 | 8.778e18 | $23,845 |
| 17 | `0x8660c1c24d58…79ec1f` | FablesRamp | MEME/USDG | 8388608 | 60 | 1.28e18 | $19,132 |
| 18 | `0xbb15d6b62c89…20ae11` | FablesRamp | GME/USDG | 8388608 | 10 | 0.0002084e18 | $17,927 |
| 19 | `0x01b71670a61d…7d4abd` | FablesRamp | DJT/USDG | 8388608 | 20 | 0.0001621e18 | $17,842 |
| 20 | `0x422ed2d69860…d74a0e` | FablesRamp | SPY/QQQ | 8388608 | 1 | 114.5e18 | $1 |
| 21 | `0xe85f633a1374…ddfa93` | FablesRampETH | ETH/AI | 8388608 | 200 | 2.789e+04e18 | $912 |
| 22 | `0xf7e180365aed…77c8b3` | FablesRamp | USDG/SFI | 8388608 | 200 | 0.01495e18 | $17,905 |
| 23 | `0xd40585db9c33…da863e` | FablesRamp | ROUTE/USDG | 8388608 | 60 | 4.122e18 | $19,216 |
| 24 | `0x592e3fb7ea94…82fa96` | FablesRamp | AI/USDG | 8388608 | 60 | 7.265e18 | $19,637 |
| 25 | `0x6b187fad6ca2…2bc485` | FablesRamp | USDG/MOO | 8388608 | 200 | 0.577e18 | $17,808 |
| 26 | `0x4e2a7c0057ce…c8f594` | FablesRamp | USDG/ZZZ | 8388608 | 200 | 2.271e18 | $17,808 |
| 27 | `0x8fb2273e40a4…be62be` | FablesRamp | Index/USDG | 8388608 | 120 | 2.581e18 | $18,159 |
| 28 | `0x4aaa4f57bec2…31d2a7` | FablesRamp | USDG/UBIK | 8388608 | 200 | 4.149e18 | $17,808 |
| 29 | `0xf50a897ae1b4…019039` | FablesRamp | USDG/cbBTC | 8388608 | 10 | 1.982e-08e18 | $17,907 |
| 30 | `0x286f707c7526…940aa2` | FablesRampETH | ETH/CASHCAT | 8388608 | 60 | 2.558e+04e18 | $339 |
| 31 | `0x8e36bc9877b9…c398b2` | FablesRWA | USDG/MU | 8388608 | 60 | 0.001076e18 | $1,888 |
| 32 | `0x6948116f31d6…d77e02` | FablesRWA | GLXY/USDG | 8388608 | 60 | 0.002784e18 | $1,885 |
| 33 | `0xdb9c34002d17…75e9e6` | FablesRWA | USDG/CRCL | 8388608 | 60 | 0.1613e18 | $1,992 |
| 34 | `0xe1c3e133c917…1dc5ea` | FablesRWA | USDG/MSTR | 8388608 | 60 | 0.02391e18 | $1,954 |
| 35 | `0xc761f7de760d…961e92` | FablesRamp | USDG/ORBIO | 8388608 | 200 | 2.051e18 | $19,043 |
| 36 | `0x29bb26f93fe1…651fdf` | FablesRamp | frxUSD/aUSD | 8388608 | 1 | 1.163e+09e18 | — |
| 37 | `0xa1f381b8938b…575093` | FablesRamp | USDG/EARN | 8388608 | 200 | 5.556e18 | $17,808 |
| 38 | `0xdc844c8cc27a…5b926b` | FablesRamp | frxUSD/eUSD | 8388608 | 1 | 3.147e+08e18 | — |
| 39 | `0x7e42e835239e…5f56fb` | FablesRamp | frxUSD/USDG | 8388608 | 1 | 6.901e18 | $17,808 |
| 40 | `0x4030f646babe…31170d` | FablesRamp | USDG/NET | 8388608 | 60 | 2.205e-06e18 | $18,293 |
| 41 | `0xcf0bd6587434…61394e` | FablesRamp | USDG/BONER | 8388608 | 200 | 0.7748e18 | $18,074 |
| 42 | `0xd98f0f503d64…ba3107` | FablesRamp | WALLET/USDG | 8388608 | 200 | 0.8773e18 | $17,808 |
| 43 | `0x0f4d4d8a40ce…bf5758` | FablesRamp | frxUSD/SFI | 8388608 | 200 | 3543e18 | $97 |
| 44 | `0x3428910987af…6082fe` | FablesRamp | USDG/THRONE | 8388608 | 200 | 1.748e18 | $17,808 |
| 45 | `0x6c330014af1c…f96ca2` | FablesRWAETH | ETH/SPY | 8388608 | 10 | 23.69e18 | $0 |
| 46 | `0x76d4e09a330a…e9097e` | FablesRampETH | ETH/CHUMP | 8388608 | 200 | 11.93e18 | $11 |
| 47 | `0xaf30b4c01101…066ff9` | FablesRampETH | ETH/INU | 8388608 | 200 | 128.3e18 | — |
| 48 | `0x0bae6c92e5af…9abaf5` | FablesRampETH | ETH/STONKBROKER | 8388608 | 200 | 55.19e18 | $3 |
| 49 | `0x8138ea2894ce…13bacc` | FablesRWA | USDG/COIN | 8388608 | 60 | 0.0132e18 | $1,851 |
| 50 | `0x46c24538a851…bd98fe` | FablesRamp | USDG/NOSH | 8388608 | 200 | 0.2724e18 | $17,808 |
| 51 | `0x9fc86429019d…fb26d9` | FablesRamp | USDG/U | 8388608 | 1 | 0.005011e18 | $17,808 |
| 52 | `0x3078bf0a7a6b…bfec6f` | FablesRampETH | ETH/PIPEDOG | 8388608 | 200 | 44.5e18 | $0 |
| 53 | `0xcb69f1b3d627…e03961` | FablesRamp | USDG/SHROOM | 8388608 | 200 | 2.202e18 | $18,148 |
| 54 | `0x5e4c353496e4…48d97e` | FablesRWA | USDG/INTC | 8388608 | 60 | 0.02204e18 | $2,036 |
| 55 | `0xbe1a90db81cf…b4c4f9` | FablesRWA | USDG/PLTR | 8388608 | 60 | 0.01778e18 | $1,845 |
| 56 | `0xb4f01c156256…a76b5e` | FablesRampETH | ETH/VIRTUAL | 8388608 | 60 | 2.48e+04e18 | $212 |
| 57 | `0xe1c6088c8a16…7b0652` | FablesRamp | USDG/XBOW | 8388608 | 200 | 18.89e18 | $17,808 |
| 58 | `0x8147584eacbf…45d221` | FablesRamp | USDG/GLDSTN | 8388608 | 60 | 1.135e18 | $17,808 |
| 59 | `0x281e37e8abdc…875878` | FablesRamp | frxUSD/XBOW | 8388608 | 200 | 578.6e18 | — |
| 60 | `0x22a4834bbb17…af8eb9` | FablesRamp | BUN/USDG | 8388608 | 200 | 0.4755e18 | $17,825 |
| 61 | `0x71065a51e4fe…c1db7c` | FablesRamp | HOOKR/USDG | 8388608 | 200 | 0.0001942e18 | $17,808 |
| 62 | `0x67c0a63cd261…09b592` | FablesRamp | PARE/USDG | 8388608 | 200 | 0.000518e18 | $17,808 |
| 63 | `0x712a1610c207…56391e` | FablesRamp | USDG/HMM | 8388608 | 200 | 0.0002741e18 | $17,808 |
| 64 | `0xfed6a0bfe239…f34b79` | FablesRamp | MCD/USDG | 8388608 | 200 | 1.895e18 | $17,808 |
| 65 | `0x4f72cb3cdc89…c2df1c` | FablesRampETH | ETH/frxUSD | 8388608 | 60 | 9274e18 | — |
| 66 | `0x3e6fd764d07d…158be6` | FablesRamp | frxUSD/SPY | 8388608 | 60 | 0.8992e18 | $1 |
| 67 | `0x806628a7d5de…414ed8` | FablesRamp | USDG/KSKD | 8388608 | 200 | 5.715e18 | $17,808 |

**Priced hook-claim total across all pools: $628,980** (unpriced memecoin legs excluded).
