# Rose (Aurora) — Holder & Value-Ownership Map (child2)

Snapshot: LP/stROSE/ROSE holder state at block **219871964**; VASE state at block **219871500** (fetch block 219871964; RPC `https://mainnet.aurora.dev`, chain 1313161554). All data read-only.

**Method.** LP-token and stROSE balances netted from genesis `Transfer` logs (all sums reconcile exactly with `totalSupply`); VASE balances netted from the full set of `LogTransfer` + `LogDeposit` + `LogWithdraw` events (this BentoBox fork emits deposits/withdrawals without `LogTransfer`; all 7 share sums equal `totals(token).base` exactly) and top holders verified with `balanceOf(token,addr)`. ROSE holders from the Blockscout holder API (top 500) and verified on-chain. Admin-fee excess = actual token balance − accounted balance.

**Prices used (as provided):** DAI/USDC/USDT $1.00, FRAX $0.9904, MAI $0.9962, UST $0.0363 (Aurora DEX; global $0.0053), RUSD $0.31, WETH $2,507, WBTC $83,108, WNEAR $5.02, ROSE $0.000021. ⚠️ All ROSE/stROSE values scale ×1000 if the intended ROSE price was $0.021. ⚠️ At current pool composition the DEX-implied prices differ materially for UST (≈$0.0050), MAI (≈$0.041) and RUSD (≈$0.022); using the provided prices overstates metaMAI-LP/RUSD-LP value. See §6.

## 1. Curve-style LP tokens — holders

All five LP tokens reconcile: Σ(holder balances) == `totalSupply` exactly (2021-2024 era activity; no missing mints).

### 3pool-LP — supply 53,650.7409 (1929 holders; unit ≈ $1.000003; total ≈ $53,650.91)

| holder | amount | % of supply | EOA/C | dead? | USD | notes |
|---|---|---|---|---|---|---|
| 0x52caca9a2d52b27b28767d3649565774a3b991f3 | 17,444.45559652 | 32.515% | contract | no | $17,444.51 | Rose farm (stakes 3pool-LP; owner 0x6adf…) |
| 0xff84ba26ba108d1de17291f95443aeb0b0dd5ab5 | 11,651.93518065 | 21.718% | contract | no | $11,651.97 | fee-recipient contract #1 (63 shares; owner 0x9fb0…) |
| 0x10bddfc02186c35e837e709a1bf1ea3c017c3f06 | 6,406.46299352 | 11.941% | EOA | no | $6,406.48 |  |
| 0x296bea2b562888497dd46236f3d3580ff07ff694 | 5,548.54056221 | 10.342% | contract | no | $5,548.56 | fee-recipient contract #2 (30 shares; owner 0x9fb0…) |
| 0xa34315f1ef49392387dd143f4578083a9bd33e94 | 2,885.19476447 | 5.378% | contract | no | $2,885.20 | metaFRAX pool |
| 0x79b0a67a4045a7a8dc04b17456f4fe15339cba34 | 1,468.69956556 | 2.738% | contract | no | $1,468.70 | RUSD pool |
| 0x28d24cd683b67511e9701ff0b71fe890314d8d92 | 1,294.65946452 | 2.413% | contract | no | $1,294.66 | fee-recipient contract #3 (7 shares; owner 0x9fb0…) |
| 0xd6cb7bb7d63f636d1ca72a1d3ed6f7f67678068a | 884.36020459 | 1.648% | contract | no | $884.36 | team contract (owner 0x6adf…) |
| 0xaa9d4f972bc4fd5a42295030ae94493a5f14c857 | 398.35120368 | 0.742% | EOA | no | $398.35 |  |
| 0xd812cc1fc1e0a56560796c746b1247e2bd4f31f2 | 364.82739021 | 0.680% | contract | no | $364.83 | team contract (owner 0x6adf…) |
| 0x8fe44f5cce02d5be44e3446bbc2e8132958d22b8 | 292.76565431 | 0.546% | contract | no | $292.77 | metaUST pool |
| 0x09337f2db0f56f24835f3157bf241886d6f45e19 | 264.38929137 | 0.493% | EOA | no | $264.39 |  |
| 0x65a761136815b45a9d78d9781d22d47247b49d23 | 246.55794136 | 0.460% | contract | no | $246.56 | metaMAI pool |
| 0xe9920c2bdd13dfead70e4b4721d34f710cbb8cdb | 199.81730072 | 0.372% | EOA | no | $199.82 |  |
| 0x7c63b0497ec503e631ced528db6401321ca3bb4f | 197.01326819 | 0.367% | EOA | no | $197.01 |  |

### metaUST-LP — supply 49,086.7678 (306 holders; unit ≈ $0.048377; total ≈ $2,374.65)

| holder | amount | % of supply | EOA/C | dead? | USD | notes |
|---|---|---|---|---|---|---|
| 0x56de5e2c25828040330cef45258f3ffbc090777c | 36,074.99034600 | 73.492% | contract | no | $1,745.19 | Rose farm (stakes metaUST-LP; owner 0x6adf…) |
| 0x5dab27d4fbf82cd0dfad97d2d1a011b29690ccd7 | 4,811.75777934 | 9.803% | EOA | no | $232.78 |  |
| 0x4cdbe2f58df67d5cace7ebd35dd90b59abc27bd1 | 4,602.72426452 | 9.377% | EOA | no | $222.66 |  |
| 0x5abaeef3cd2b68b7464d2d7654a1b08e305e9512 | 1,242.16996045 | 2.531% | EOA | no | $60.09 |  |
| 0x51c51e651df6db7f1a6f54a8d6ad4bf89b73412c | 699.69774999 | 1.425% | EOA | no | $33.85 |  |
| 0x25cab5547875affd2ae3959cbaafdb58229282f3 | 500.74535389 | 1.020% | EOA | no | $24.22 |  |
| 0xc0c11f196448e25947d33d012502797964ddaa92 | 402.53917323 | 0.820% | EOA | no | $19.47 |  |
| 0x40df56e0fc184089c8b4093e54a51752641a3a69 | 250.06066666 | 0.509% | EOA | no | $12.10 |  |
| 0xff9d38a54193d91859cd28575c76d1178b96ba00 | 160.57853019 | 0.327% | EOA | no | $7.77 |  |
| 0x1409d054645e3127aede2bcd0adb8ca71efa0af9 | 100.15950511 | 0.204% | EOA | no | $4.85 |  |
| 0x956369b2373effa5d5398e2d5ab6184a07f7b3d7 | 56.21877113 | 0.115% | EOA | no | $2.72 |  |
| 0x2975335d7a5e77373d31512a2a61d9fd00bbaf47 | 29.95345525 | 0.061% | EOA | no | $1.45 |  |

### metaFRAX-LP — supply 5,869.5864 (176 holders; unit ≈ $0.995059; total ≈ $5,840.58)

| holder | amount | % of supply | EOA/C | dead? | USD | notes |
|---|---|---|---|---|---|---|
| 0xb9d873cdc15e462f5414ccdfe618a679a47831b4 | 5,717.70526405 | 97.412% | contract | no | $5,689.45 | Rose farm (stakes metaFRAX-LP; owner 0x6adf…) |
| 0x86951b2e7cab5c9cae52de4329c179432264a159 | 24.14866845 | 0.411% | EOA | no | $24.03 |  |
| 0xf4274cbe555b7af78b1df2526a35993ce3bbfb8e | 15.40000009 | 0.262% | EOA | no | $15.32 |  |
| 0x31270214b9cea11f1a07e3a55b4f6643a64f94ff | 13.37358147 | 0.228% | EOA | no | $13.31 |  |
| 0x3df4453497da5105b67b4566531267d5fcf7fefa | 10.48791348 | 0.179% | EOA | no | $10.44 |  |
| 0xbe8f11693b631fcda04e880f767557e23cbc3d8e | 9.01585352 | 0.154% | EOA | no | $8.97 |  |
| 0xc41a6ca6ed19eedecee9c3320f442d18d911991c | 7.98538354 | 0.136% | EOA | no | $7.95 |  |
| 0x9df9b714e4bbce108295d2468da4f2ac0b2ec09d | 7.98538312 | 0.136% | EOA | no | $7.95 |  |
| 0x0a94aadbcedcab8d279412c8ad5133983075dbb7 | 5.92298632 | 0.101% | EOA | no | $5.89 |  |
| 0x5404138bcfb53214c789ce94418b8df499713cc3 | 5.47665979 | 0.093% | EOA | no | $5.45 |  |
| 0xdfb7009edd56ada61ce83ef03111815efa604c7e | 5.20957703 | 0.089% | EOA | no | $5.18 |  |
| 0x292a0d94cdce3bffd5710a13b1b99571d86fa1cf | 4.00380257 | 0.068% | EOA | no | $3.98 |  |

### metaMAI-LP — supply 80.1315 (55 holders; unit ≈ $1.022427; total ≈ $81.93)

| holder | amount | % of supply | EOA/C | dead? | USD | notes |
|---|---|---|---|---|---|---|
| 0x226991aadeefde03bf557ef067da95fc613abffc | 77.38265516 | 96.570% | contract | no | $79.12 | Rose farm (stakes metaMAI-LP; owner 0x6adf…) |
| 0x19917c01653558c1efa8fcd419fa7bc15b9e9bde | 2.27824008 | 2.843% | contract | no | $2.33 | StrategyRoseLP (Beefy-style vault; strategist 0x2d04…) |
| 0xd20b976584bf506baf5cc604d1f0a1b8d07138da | 0.20048947 | 0.250% | EOA | no | $0.2050 |  |
| 0x6d62ed9470eb0fcfe2c17493ac32b555be44e2cd | 0.15380621 | 0.192% | EOA | no | $0.1573 |  |
| 0x83646b933ee0cfa62363a7f15d7533bf2642f006 | 0.10016310 | 0.125% | EOA | no | $0.1024 |  |
| 0x04c331c944392f0ae0fa3f4000f8abdce1fa85bd | 0.01595534 | 0.020% | EOA | no | $0.0163 |  |
| 0x287cdd0a59d69e9f101e90bdbcc892607df08cf9 | 0.00019141 | 0.000% | EOA | no | $0.0002 |  |
| 0xc322150ad327091351af0c64f82627098cd04924 | 0.00000000 | 0.000% | EOA | no | $0.0000 |  |
| 0x7374e3e9c57b7063df9216fe46b179747e9ae2c6 | 0.00000000 | 0.000% | EOA | no | $0.0000 |  |
| 0x4a5c218cf4fb73f0c28d7a0b913a73876da21eb9 | 0.00000000 | 0.000% | EOA | no | $0.0000 |  |

### RUSD-LP — supply 8,892.5071 (88 holders; unit ≈ $0.340751; total ≈ $3,030.13)

| holder | amount | % of supply | EOA/C | dead? | USD | notes |
|---|---|---|---|---|---|---|
| 0x9286d58c1c8d434be809221923cf4575f7a4d058 | 8,757.74927504 | 98.485% | contract | no | $2,984.21 | Rose farm (stakes RUSD-LP; owner 0x6adf…) |
| 0x33d835ba506684273a1d1d07f2f64d63de389150 | 121.93700302 | 1.371% | EOA | no | $41.55 |  |
| 0xf09a24f132da1474ec4d33e6700cbda96bb6b717 | 4.19803713 | 0.047% | EOA | no | $1.43 |  |
| 0x2ac08ae0ad590f04d72c21ef0d28545177857286 | 3.00040585 | 0.034% | EOA | no | $1.02 |  |
| 0xead8aa856fac469e54642151437c4e69743eee6e | 1.90647934 | 0.021% | EOA | no | $0.6496 |  |
| 0xb4cf2ea0020d2c05c8e40bda9c47395c18a77df3 | 1.65656021 | 0.019% | EOA | no | $0.5645 |  |
| 0x5f2c09a28416a1867cc55e5dd06f98caf8bdf8cc | 1.49243402 | 0.017% | EOA | no | $0.5085 |  |
| 0x54efdae67807cf4394020e48c7262bdbbdebd9f2 | 0.51596889 | 0.006% | EOA | no | $0.1758 |  |
| 0x4418b66ee70ea53740906a34f57a16441dcbc98f | 0.04536194 | 0.001% | EOA | no | $0.0155 |  |
| 0x7f110166494d525fe09203ab3e62ec1d309121e3 | 0.00536126 | 0.000% | EOA | no | $0.0018 |  |


### stROSE vault (0xe23d…e16F) — supply 14,320,254.61; vault holds 15,042,587.74 ROSE (backing 1.050441 ROSE per stROSE); unit ≈ $0.00002206; total ≈ $315.89

| holder | amount | % of supply | EOA/C | dead? | USD | notes |
|---|---|---|---|---|---|---|
| 0xe653a57f4a86808e9982ff618dabaef2969fb0f8 | 3,203,543.53 | 22.371% | EOA | no | $70.67 |  |
| 0x3da00d8107de86885e1c826f4eb4e5551b97d419 | 2,455,370.08 | 17.146% | EOA | no | $54.16 |  |
| 0x5c9757e093a0871ec338b141f56bc56f85844a3d | 1,532,082.06 | 10.699% | EOA | no | $33.80 |  |
| 0xf3b55be2dbddc148be645b2b61cdd8691cce9890 | 1,257,947.55 | 8.784% | EOA | no | $27.75 |  |
| 0xa82d29b345078c6a37bb897af61754215391a35e | 1,223,417.78 | 8.543% | EOA | no | $26.99 |  |
| 0xcd327563d7ca2c437586c593f6a7b6562125319a | 494,220.02 | 3.451% | EOA | no | $10.90 |  |
| 0x70484215203ccbedb80ffb36016e4e77c78252e3 | 297,261.95 | 2.076% | EOA | no | $6.56 |  |
| 0x566d85c5916a74073faf16a2ab07a15e7bbf24e5 | 291,173.49 | 2.033% | EOA | no | $6.42 |  |
| 0x6afa006f87331c05ea61fc6bf989f29594642c67 | 127,809.36 | 0.893% | EOA | no | $2.82 |  |
| 0xb42028bac044326700f56ae37c5b49a38514fae5 | 116,955.02 | 0.817% | EOA | no | $2.58 |  |
| 0xe9271bd4d191645716eb32a2fd380aa0cc9a9029 | 113,406.01 | 0.792% | EOA | no | $2.50 |  |
| 0x7e6601a0cb2b5ae129c09661846a053ea07223fb | 106,732.40 | 0.745% | EOA | no | $2.35 |  |
| 0x0fc5d2f07d60320918a39c435044437b038f0a70 | 102,862.94 | 0.718% | EOA | no | $2.27 |  |
| 0xb6d522041713497504c6d8fe855c6f9be52d35b3 | 102,747.86 | 0.718% | EOA | no | $2.27 |  |
| 0x14ff0bc9417b6796f79768729002a793b51205b8 | 101,643.16 | 0.710% | EOA | no | $2.24 |  |

### ROSE ERC-20 (0xdcd6…f970) — supply 436,261,248 ROSE (explorer scan: top 500 holders; unit $2.1e-05; total ≈ $9,161.49)

| holder | amount | % of supply | EOA/C | dead? | USD | notes |
|---|---|---|---|---|---|---|
| 0xf7ad847c2524b1021045bbd2765a41123c9a9233 | 123,873,156.11 | 28.394% | EOA | no | $2,601.34 | team EOA — beneficiary of the 66.67M ROSE vesting contract |
| 0x0483606d3b7a2917f70ec6b86b7701083aae40f9 | 66,666,666.67 | 15.281% | contract | no | $1,400.00 | ROSE vesting contract (owner 0xf9c4…) |
| 0x25dddc42dbcf3b018515523d08db69b528e60a92 | 60,774,790.54 | 13.931% | EOA | no | $1,276.27 | team EOA — beneficiary of the 33.33M ROSE vesting contract |
| 0xdba93205afeaf53098b27870f6811d4b3e52c355 | 52,175,178.23 | 11.960% | EOA | no | $1,095.68 |  |
| 0x9f9d73b478c2e1495d20cf9e3371f68f12d5b750 | 33,333,333.33 | 7.641% | contract | no | $700.00 | ROSE vesting contract (owner 0xf9c4…) |
| 0xe23d2289fbca7de725dc21a13fc096787a85e16f | 15,042,587.74 | 3.448% | contract | no | $315.89 | stROSE vault |
| 0xc25ad0b20a3b7cf4c6e1fd41b1892469bfc688bb | 12,155,133.80 | 2.786% | EOA | **YES (nonce 0)** | $255.26 |  |
| 0x28815638559bded4d74dccf3e32d57e652cf1b2d | 9,226,844.22 | 2.115% | contract | no | $193.76 | ROSE vesting contract (owner 0xf9c4…) |
| 0x2d44f9e943535c9cc9507af039d4bc83a3cf8743 | 6,666,666.67 | 1.528% | contract | no | $140.00 | ROSE vesting contract (owner 0xf9c4…) |
| 0xc6c3cc84eabd4643c382c988fa2830657fc70a6b | 6,353,733.64 | 1.456% | contract | no | $133.43 | UniswapV2Pair |
| 0x70637de674b02ebb082b441876ab5af8ca49e801 | 5,891,145.64 | 1.350% | contract | no | $123.71 | ROSE vesting contract (owner 0xf9c4…) |
| 0xf8292df55d17998aa7d3cb5d8424dd80147f3540 | 4,712,821.16 | 1.080% | EOA | no | $98.97 |  |
| 0x3da00d8107de86885e1c826f4eb4e5551b97d419 | 4,634,738.93 | 1.062% | EOA | no | $97.33 |  |
| 0xb88ce5f830195fed2dc61683a6cc2ccb5a90e2a7 | 3,771,612.99 | 0.865% | EOA | no | $79.20 |  |
| 0xed4c231b98b474f7caecadd2736e5ebc642ad707 | 3,616,869.87 | 0.829% | contract | no | $75.95 | SushiSwap LP Token |
| 0x24f029f6c284888b30b38648004dc7280e601a7c | 3,540,720.96 | 0.812% | contract | no | $74.36 | ROSE vesting contract (owner 0xf9c4…) |
| 0xe060b1713188d1f6de32d9236ca45bdef5b6ed7e | 2,470,017.16 | 0.566% | EOA | no | $51.87 |  |
| 0x27ddd34949fdd0e5e8f4e89d0a33965c1542909e | 2,266,837.29 | 0.520% | EOA | no | $47.60 |  |
| 0xbe753e99d0dbd12fb39edf9b884ebf3b1b09f26c | 2,191,726.79 | 0.502% | contract | no | $46.03 | Trisolaris LP Token |
| 0xcdbcdbd3668a9bdf9a9f61802b0b2ccc78f3910d | 1,666,666.67 | 0.382% | contract | no | $35.00 | ROSE vesting contract (owner 0xf9c4…) |
| 0x1b2dab8062e1d7ea6d6bff01ae297fede19e3125 | 1,336,439.06 | 0.306% | EOA | no | $28.07 |  |
| 0xe4ff40a4c5c1a0dba232a08d54296e06bd162553 | 1,178,199.53 | 0.270% | contract | no | $24.74 | ROSE vesting contract (owner 0xf9c4…) |
| 0xa82d29b345078c6a37bb897af61754215391a35e | 1,055,517.36 | 0.242% | EOA | no | $22.17 |  |
| 0xb55cdbf92bde6ae3525cda9e1d268207d69c0359 | 1,006,905.07 | 0.231% | EOA | no | $21.15 |  |
| 0x38d5b97ae17383a00fbfd455fcc5bae63b80d6c8 | 687,243.18 | 0.158% | EOA | no | $14.43 |  |
| 0x52caca9a2d52b27b28767d3649565774a3b991f3 | 472,931.62 | 0.108% | contract | no | $9.93 | Rose farm (stakes 3pool-LP; owner 0x6adf…) |
| 0x9286d58c1c8d434be809221923cf4575f7a4d058 | 444,957.25 | 0.102% | contract | no | $9.34 | Rose farm (stakes RUSD-LP; owner 0x6adf…) |
| 0xf42dfa388123df02f05ea73897d6f4b8ba6e4eb9 | 441,031.71 | 0.101% | EOA | no | $9.26 |  |
| 0xae1a6d43772c515206e9ffa90df15c400317b318 | 410,940.92 | 0.094% | EOA | no | $8.63 |  |
| 0x13890ab8da77ba9b399fa2bca922a3bf73374de0 | 400,000.00 | 0.092% | EOA | **YES (nonce 0)** | $8.40 |  |

## 2. VASE (BentoBox) share holders

Shares/amounts: `balanceOf` verified for every listed holder. `totals(token)` reconciles exactly (Σ shares == base). `token.balanceOf(VASE) − totals.elastic == 0` for all 7 tokens → **no unaccounted surplus**.

### VASE RUSD — VASE balance 392,657.66612112; unit $0.31; total $121,723.88

| holder (share acct) | amount | % of VASE balance | EOA/C | dead? | USD | notes |
|---|---|---|---|---|---|---|
| 0x3820feddeaba00564166e68a73babdae5740394f | 391,565.96376041 | 99.722% | EOA | no | $121,385.45 | protocol treasury EOA (nonce 297) |
| 0x64c922e3824ab40cbbedd6c8092d148c283d3d3d | 875.79326328 | 0.223% | contract | no | $271.50 | Garden clone 0x64C9 |
| 0x084355fdd5fcfd55d60c5b8626756a6906576f13 | 80.22152691 | 0.020% | contract | no | $24.87 | Garden clone 0x0843 |
| 0xfbaf3ebf228eb712b1267285787e51add70086bb | 52.43502194 | 0.013% | contract | no | $16.25 | Garden clone 0xfbAF |
| 0x0f44fcd177098cb2b063b50f6c62e4f1e1f9d596 | 37.86996285 | 0.010% | contract | no | $11.74 | Garden clone 0x0F44 |
| 0x6ba5b45149996597d96e6db19e4e1efa81a6df97 | 32.26663089 | 0.008% | contract | no | $10.00 | additional Garden market clone (master 0x857050ef…); holds its users' collateral |
| 0xe8f7f08d50e12145cb722cff861e6a9b43eadba1 | 13.11595483 | 0.003% | contract | no | $4.07 | Garden clone 0xe8F7 |

### VASE WBTC — VASE balance 0.40455524; unit $83108; total $33,621.78

| holder (share acct) | amount | % of VASE balance | EOA/C | dead? | USD | notes |
|---|---|---|---|---|---|---|
| 0x3820feddeaba00564166e68a73babdae5740394f | 0.40436325 | 99.953% | EOA | no | $33,605.82 | protocol treasury EOA (nonce 297) |
| 0x6ba5b45149996597d96e6db19e4e1efa81a6df97 | 0.00019199 | 0.047% | contract | no | $15.96 | additional Garden market clone (master 0x857050ef…); holds its users' collateral |

### VASE UST — VASE balance 1,917.39896657; unit $0.0363; total $69.60

| holder (share acct) | amount | % of VASE balance | EOA/C | dead? | USD | notes |
|---|---|---|---|---|---|---|
| 0x3820feddeaba00564166e68a73babdae5740394f | 1,800.45165875 | 93.901% | EOA | no | $65.36 | protocol treasury EOA (nonce 297) |
| 0xe8f7f08d50e12145cb722cff861e6a9b43eadba1 | 116.94730782 | 6.099% | contract | no | $4.25 | Garden clone 0xe8F7 |

### VASE USDC — VASE balance 8,718.60542200; unit $1.0; total $8,718.61

| holder (share acct) | amount | % of VASE balance | EOA/C | dead? | USD | notes |
|---|---|---|---|---|---|---|
| 0xfbaf3ebf228eb712b1267285787e51add70086bb | 8,718.605422 | 100.000% | contract | no | $8,718.61 | Garden clone 0xfbAF |

### VASE USDT — VASE balance 29.31639500; unit $1.0; total $29.32

| holder (share acct) | amount | % of VASE balance | EOA/C | dead? | USD | notes |
|---|---|---|---|---|---|---|
| 0x0f44fcd177098cb2b063b50f6c62e4f1e1f9d596 | 29.316395 | 100.000% | contract | no | $29.32 | Garden clone 0x0F44 |

### VASE WNEAR — VASE balance 5.22075403; unit $5.02; total $26.21

| holder (share acct) | amount | % of VASE balance | EOA/C | dead? | USD | notes |
|---|---|---|---|---|---|---|
| 0x64c922e3824ab40cbbedd6c8092d148c283d3d3d | 5.22075403 | 100.000% | contract | no | $26.21 | Garden clone 0x64C9 |

### VASE WETH — VASE balance 7.41759579; unit $2507; total $18,595.91

| holder (share acct) | amount | % of VASE balance | EOA/C | dead? | USD | notes |
|---|---|---|---|---|---|---|
| 0x084355fdd5fcfd55d60c5b8626756a6906576f13 | 7.41749579 | 99.999% | contract | no | $18,595.66 | Garden clone 0x0843 |
| 0x64c922e3824ab40cbbedd6c8092d148c283d3d3d | 0.00010000 | 0.001% | contract | no | $0.2507 | Garden clone 0x64C9 |


## 3. Unclaimed admin-fee excess (pool actual balance − accounted balance)

For the Curve-style pools `balances(i)` excludes accrued admin fees; the difference is claimable **only by the pool owner (EOA 0x6adf…) via `withdraw_admin_fees`, paid to fee receiver 0xf042…**. For VASE the excess is token balance − `totals.elastic`.

### Admin-fee excess by pool

| pool | coin | excess (token units) | USD |
|---|---|---|---|
| 3pool | 0xe3520349… | 121.32350003 | $121.32 |
| 3pool | 0xb12bfca5… | 322.731146 | $322.73 |
| 3pool | 0x4988a896… | 294.683239 | $294.68 |
| metaUST | 0x5ce9f0b6… | 156.72550611 | $5.69 |
| metaUST | 0xff79d5bf… | 3.92738012 | $3.93 |
| metaFRAX | 0xda258543… | 40.66573812 | $40.28 |
| metaFRAX | 0xff79d5bf… | 40.59613732 | $40.60 |
| metaMAI | 0xdfa46478… | 171.10083665 | $170.45 |
| metaMAI | 0xff79d5bf… | 243.29730888 | $243.30 |
| RUSDpool | 0x19cc4028… | 1,318.44415125 | $408.72 |
| RUSDpool | 0xff79d5bf… | 1,267.87858649 | $1,267.88 |
| VASE (all 7 tokens) | — | 0 | $0.00 |

Total unclaimed admin-fee excess ≈ **$2,919.58** — owner-claimable only (privileged pot).

## 4. Fee receiver 0xf042… (`PaymentSplitter`, ERC-20 variant)

`totalShares()=100`, `totalReleased()` (ETH path) = 0 (nothing ever released in ETH). 3 payees; ERC-20 releases already executed are shown from `released(token,payee)` calls. The splitter still holds **68.5586 UST** (unreleased) plus 1-2 wei dust; `release(token,payee)` is callable by anyone (funds go to the payee).

### PaymentSplitter payees (all three are unverified contracts owned by EOA 0x9fb0af8f…)

| payee | shares | pct | current token balances (from §2 data) |
|---|---|---|---|
| 0xff84ba26ba108d1de17291f95443aeb0b0dd5ab5 | 63 | 63% | LP3pool 11,651.9352 |
| 0x296bea2b562888497dd46236f3d3580ff07ff694 | 30 | 30% | USDC 7,662.0835, USDT 6,135.3094, DAI 2,685.4072, RUSD 0.0019, UST 4,450.3129, FRAX 1,125.8523, LP3pool 5,548.5406 |
| 0x28d24cd683b67511e9701ff0b71fe890314d8d92 | 7 | 7% | USDC 1,787.8195, USDT 1,431.5722, DAI 626.5950, UST 1,038.4063, FRAX 262.6989, LP3pool 1,294.6595 |


Cumulative `released()` (token, payee) — the admin fees already distributed historically:

### released(token,payee) cumulative

| token | payee#1 (63%) | payee#2 (30%) | payee#3 (7%) | USD |
|---|---|---|---|---|
| UST | 9,345.6571 | 4,450.3129 | 1,038.4063 | $538.49 |
| 3pool-LP | 11,651.9352 | 5,548.5406 | 1,294.6595 | $18,495.19 |
| USDC | 16,090.3754 | 7,662.0835 | 1,787.8195 | $25,540.28 |
| USDT | 12,884.1496 | 6,135.3094 | 1,431.5722 | $20,451.03 |
| DAI | 5,639.3550 | 2,685.4072 | 626.5950 | $8,951.36 |
| FRAX | 2,364.2899 | 1,125.8523 | 262.6989 | $3,716.81 |

Historically distributed admin fees ≈ **$77,693.16** (already paid to team-controlled payee contracts).

## 5. Ownership interpretation

### 5.0 Value summary at provided prices

| asset | total USD | protocol/team-held | user-held |
|---|---|---|---|
| 3pool-LP | $53,650.91 | $42,082.13 | $11,568.78 |
| metaUST-LP | $2,374.65 | $1,745.19 | $629.47 |
| metaFRAX-LP | $5,840.58 | $5,689.45 | $151.13 |
| metaMAI-LP | $81.93 | $81.45 | $0.4812 |
| RUSD-LP | $3,030.13 | $2,984.21 | $45.92 |
| VASE shares (7 tokens) | $182,785.30 | $155,056.63 treasury EOA | $27,728.67 gardens/other |
| stROSE | $315.89 | — | $315.89 (all user) |
| ROSE ERC-20 | $9,161.49 | vesting/team (see §5b) | float + dead EOAs |
| Admin-fee excess (unclaimed) | $2,919.58 | $2,919.58 owner-claimable | — |

**Grand total ≈ $260,160.46** at the provided prices. All ROSE/stROSE/ROSE-denominated parts are ×1000 if the intended ROSE price was $0.021; metaMAI/RUSD pots shrink if DEX-implied coin prices are used instead. Note: family-level overlaps exist (the treasury EOA's VASE RUSD/WBTC/UST ≈ $155.1k is the single largest unclassified pot).

**(a) User-owned (H-O).**
- LP tokens staked in the Rose farms (`0x52caca9a`, `0x56de5e2c`, `0xb9d873cd`, `0x9286d58c`, `0x226991aa`): 17,444 / 36,075 / 5,718 / 8,758 / 77 LP units ≈ **$27.9k**, withdrawable by stakers (farms are unverified; owner 0x6adf… could in principle interfere — flag for the audit).
- LP tokens NOT in protocol contracts (directly held by EOAs/other users): 3pool-LP 11,568.74 ($11,569), metaUST-LP 13,011.78 ($629), metaFRAX-LP 151.88 ($151), metaMAI-LP 0.4706 ($0.48), RUSD-LP 134.76 ($46).
- stROSE shares (~$316 at $0.000021; $316k at $0.021): redeemable against the vault's 15.04M ROSE.
- VASE shares held by the 6 Garden CDP clones ≈ **$27.7k** (USDC 8.7k + WETH 18.6k + WNEAR/UST/RUSD/WBTC dust): user collateral, but encumbered by outstanding market borrows; only net equity is user-owned.
- VASE RUSD/WBTC/UST of treasury EOA 0x3820… ≈ **$155.1k** (99.7% of RUSD, 100% of WBTC in VASE): on-chain looks like protocol treasury/DAO funds (nonce 297). Classify after key-role review — if that key belongs to the team this pot is P/H-O; if it is a user, H-O.

**(b) Team-owned / privileged (P; team H-O).**
- Fee-recipient contracts #1-3 (owner 0x9fb0af8f…): currently hold ≈ $11.65k + $23.3k + $5.4k in stables and 3pool-LP (≈$40.4k total; no ROSE). They have already received ≈ $78k of historic admin fees.
- ROSE vesting contracts (11 unique, owner 0xf9c4…, beneficiaries are team EOAs incl. 0xf7ad847c (123.9M ROSE) and 0x25dddc42 (60.8M)): 129,075,006 ROSE still inside ($2,711 at the given price; ×1000 at $0.021), fully vested (start Dec-2022, 365-day duration); claimable by beneficiaries.
- Farms' ROSE reward inventory: 1,253,238.62 ROSE total (0x52caca9a 472,932, 0x9286d58c 444,957, 0xb9d873cd 249,132 …) — farm-owner-controlled.
- Two team contracts `0xd6cb7bb7`/`0xd812cc1f` (owner 0x6adf…) hold 1,249 3pool-LP ≈ $1.25k.
- Unclaimed pool admin fees ≈ **$2.92k** — owner-only claim. VASE owner 0x0e2a05ca… can whitelist master contracts (BentoBox admin surface; no direct share seizure).

**(c) Stuck / dead (S).**
- EOA `0xc25ad0b2…` holds **12,155,133.8 ROSE ($255 at $0.000021; $255k at $0.021)**; EOA `0x13890ab8…` holds 400,000 ROSE ($8.40 / $8.4k). Both have **nonce 0 — they have never sent a transaction**. If keys are lost, value is stuck; if cold allocations, they are unclaimed H-O/P. Prime candidates for the 'unclaimed pot' list.
- 6th Garden market clone `0x6ba5b451…` (same master 0x857050ef…) holds 0.000192 WBTC + 32.27 RUSD in VASE with tiny outstanding borrows — an additional, previously uncatalogued market; collateral belongs to its position owner.
- Nothing else looks stuck: the PaymentSplitter's 68.56 UST is **claimable by anyone** via `release(UST,payee)` (funds flow to the payees, not the caller).

**(d) Potentially attacker-reachable (E-U).** No holder-map pot is directly attacker-extractable: every large balance is either owner-gated (admin fees, farms' admin functions), user-gated (LP/stROSE/VASE shares), or permissionless-forward with funds going to a fixed payee (splitter). Any E-U in this protocol will come from logic bugs in the Garden/farm/stROSE/VASE code (parent's audit), not from idle balances.

## 6. Sanity / valuation caveats

Pool composition implies very different marginal prices for the depegged meta-pool coins (A=100, 50/50 intent):

| pool | coin0 balance | coin1 (3pool-LP) balance | implied coin0 price | provided price |
| --- | --- | --- | --- | --- |
| metaUST | 57,460.4785 UST | 288.8383 | $0.005027 | $0.0363 |
| metaFRAX | 3,025.0150 FRAX | 2,844.5986 | $0.940362 | $0.9904 |
| metaMAI | 78.9681 MAI | 3.2606 | $0.041291 | $0.9962 |
| RUSDpool | 9,126.7976 RUSD | 200.8210 | $0.022004 | $0.31 |

Computed LP unit values used in §1: 3pool-LP $1.000003, metaUST-LP $0.048377, metaFRAX-LP $0.995059, metaMAI-LP $1.022427, RUSD-LP $0.340751.

Raw artefacts: `child2_holders_raw.json` (LP/stROSE/ROSE), `child2_vase_full.json` + `child2_vase_all_logs.json` (VASE), `child2_fees.json` (splitter + excess), `child2_classified.json` (EOA/contract/nonce/owner/name), scripts `child2_*.py` (working fetchers: `child2_fetch_holders2.py`, `child2_fetch_vase.py`, `child2_vase_recount.py`, `child2_fees.py`, `child2_classify.py`, `child2_report.py`). Stripped logs for the small LPs are `child2_raw_<LP>.json`; the 3pool-LP raw log (81 MB, 207,239 events) is kept at `/tmp/opencode/child2_raw_3pool-LP.json` only.
