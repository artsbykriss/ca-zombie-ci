# InsureDAO v2 — L2 chains (Arbitrum, Optimism, Astar) — Phase-2 audit report

**Scope:** InsureDAO v2 deployments on Arbitrum, Optimism, Astar (vaults, registries, ownership, factories, parameters, controllers, and every registered market + its EIP-1167 implementation).
**Method:** fully read-only. Keyless public RPCs (`https://arb1.arbitrum.io/rpc`, `https://mainnet.optimism.io`, `https://evm.astar.network` + publicnode/onfinality fallbacks). Verified sources pulled from Etherscan V2 / Blockscout and saved under `analysis/v2-chains/sources/`. All gate checks performed with `cast call` (eth_call) at latest block; **no transaction was sent and no key was used**. Scripts: `enumerate.py`, `followup.py`, `make_report.py` (keyless).

**Total v2 L2 value in scope: ≈ $1,388.06** (Arb $607.06 + Op $232.76 + Astar $548.24).

## Bottom line (E-U = extractable by a fresh, unprivileged attacker)

| chain | E-U | confidence | reason (gate) |
|---|---|---|---|
| Arbitrum | **$0.00** | high | Every value-out is gated: `borrowValue` → onlyMarket; `withdrawValue` → caller's own attribution; owner functions → `parameters.getOwner()` (EOA). Permissionless market clones are forced (factory reflist) to the real parameters contract, so a clone cannot be turned into a payout tool. |
| Optimism | **$0.00** | high | Same code and same owner/reference configuration as Arbitrum; all gates verified by eth_call reverts. |
| Astar | **$0.00** | high (one RPC limitation, see F1) | Older 0.8.10 generation with identical auth structure; reference allowlist identical. `createMarket` could not be re-simulated in eth_call because the public node cannot CREATE inside eth_call, but the reference restriction is proven by storage reads + event history. |

**Privileged risk (P, not E-U):** the single EOA **0x2c9bC901f39F847C2fe5D2D7AC9c5888A2Ab8Fcf** owns the vaults/registries/parameters/controllers on all three chains. It can take **$549.14** of fee attributions directly (public `withdrawValue`), drain Arb/Op remainders via `controller.emergencyExit`, and re-wire Astar via `vault.setController` — i.e. **100% of the $1,388.06** is owner-reachable. If this key is destroyed, all of it is permanently locked (S); it is not reachable by third parties either way.

---

## Arbitrum (chain_id 42161)

**E-U verdict: $0.00** — every value-moving path requires a role or the caller's own attribution; permissionless market creation is forced onto the real parameters contract (findings F1–F6). Owner-privileged exposure is finding F7.

- **Block (vault/market reads):** 514,519,558 ; follow-up detail block: 514,532,779
- **Vault:** `0x968C9718f420d5D4275C610C5c217598a6ade9f9` — token USDC.e 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8 (6 dec)
- **Vault value (valueAll):** 607055148 raw ≈ **$607.06** ; balance()=0 ; totalAttributions=516450932 ; totalDebt=0
- **Controller:** 0xE5E32AD53c183e7eEd57b226a93769DBcC21705F (AaveV3Strategy) ; managingFund=607055148 (≈$607.06)
- **Registry:** `0x0fa85C39c96A9172CcCa7F84CE68E08A2BB971C1` ; **Factory:** `0xeACe965860d5a33695a2d08f9fA8C4118A38712F` ; **Parameters:** `0x3956fEaEF1821bE55B66eBB707B4aBcefD84c0A2`
- **Ownership:** `0x62B86b6274DFa4Cc16beD9995E302A56D18891E2` → owner **0x2c9bC901f39F847C2fe5D2D7AC9c5888A2Ab8Fcf** (EOA, nonce 77, futureOwner=0). Owner's fee attribution in this vault: **376,475,435 raw ≈ $376.48** (redeemable by the owner via `withdrawValue`).
- **Markets:** 12

### Unique implementations
| impl | name | clones | examples |
|---|---|---|---|
| 0x576e74c0e1adb96b58f2237510853bc7d2561ebe | MarketTemplate (solc 0.8.12) | 10 | 0xe1a9f0add0…, 0x2d9e9d7f23…, 0x2ed1ba8ee5…, 0x153bc6b71d… … |
| 0xcb146803913cbfaa66c04e7fefc288af95c05af1 | IndexTemplate (solc 0.8.12) | 2 | 0xca570cb02d…, 0x49f97e64b5… |

### Market table (raw units, 6-dec USDC)
| market | symbol | impl | attributions | underlyingValue | totalSupply | status | paused | attrDebt | locked | totalCredit | origLiq | totalLiq | vault.debts |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 0xe1a9f0add0022f3fa35a3a605b699f64fbe374e1 | iGMX | 0x576e74c0… | 91,799,975 | 107,905,018 | 91,194,772 | Trading(0) | False | 359,733 | 0 | 1,644,008 | 107,482,699 | 109,126,706 | 0 |
| 0x2d9e9d7f23787163320db40573a864ed99ab6406 | iRDNT | 0x576e74c0… | 13,484,676 | 15,850,377 | 13,402,397 | Trading(0) | False | 57,317 | 0 | 411,002 | 15,783,082 | 16,194,084 | 0 |
| 0x2ed1ba8ee5c5749490717b7febfd43d1bc8f6a47 | iDPX | 0x576e74c0… | 2,799,557 | 3,290,700 | 2,797,466 | Trading(0) | False | 23,811 | 0 | 411,002 | 3,262,728 | 3,673,730 | 0 |
| 0x153bc6b71d997e25ea799e2934123fd0f41ce442 | iVSTA | 0x576e74c0… | 882,382 | 1,037,183 | 880,048 | Trading(0) | False | 2,361 | 0 | 411,002 | 1,034,413 | 1,445,415 | 0 |
| 0x7b869f4bce2ecee63741c9e416c8bcf544b7a950 | iMYC | 0x576e74c0… | 157,381 | 184,991 | 124,622 | Trading(0) | False | 32,737 | 0 | 411,002 | 146,512 | 557,514 | 0 |
| 0x937e109022440bc9e321a175f412fdee4b86f69b | iPLS | 0x576e74c0… | 138,499 | 162,796 | 134,379 | Trading(0) | False | 4,127 | 0 | 113,396 | 157,946 | 271,342 | 0 |
| 0xc36df98b1810180afd9b49cb36c715e9369a1fb0 | iMCB | 0x576e74c0… | 26,482,754 | 31,128,789 | 26,255,421 | Trading(0) | False | 8,364 | 0 | 113,396 | 31,119,109 | 31,232,505 | 0 |
| 0xdea1ee6c0fb25243e3098f4ea0744de824463f59 | iJONES | 0x576e74c0… | 86,177 | 101,295 | 89,763 | Trading(0) | False | 171 | 0 | 113,396 | 101,095 | 214,491 | 0 |
| 0x21863cc84c4abbdf65b0d0eaea4ce3520262ce43 | iSPELL | 0x576e74c0… | 0 | 0 | 0 | Trading(0) | False | 0 | 0 | 113,396 | 0 | 113,396 | 0 |
| 0xde323a01d11f5d1a29fd8c7394f7e781fe4efb18 | ihETH | 0x576e74c0… | 342,128 | 402,149 | 327,678 | Trading(0) | False | 14,457 | 0 | 113,396 | 385,158 | 498,554 | 0 |
| 0xca570cb02dcab8c89f47e52e0d083ad481728283 | iIndex | 0xcb146803… | 3,254,310 | 3,825,233 | 3,220,482 | — | False | — | — | — | — | 3,825,252 | 0 |
| 0x49f97e64b5eae37558976eb7a5bb1d7fba7b4cdb | iIndex | 0xcb146803… | 547,584 | 643,650 | 546,525 | — | False | — | — | — | — | 643,653 | 0 |


---

## Optimism (chain_id 10)

**E-U verdict: $0.00** — every value-moving path requires a role or the caller's own attribution; permissionless market creation is forced onto the real parameters contract (findings F1–F6). Owner-privileged exposure is finding F7.

- **Block (vault/market reads):** 158,159,954 ; follow-up detail block: 158,161,631
- **Vault:** `0x54F23d2fdC1E17D349B1Eb14d869fa4deD6A6D2b` — token USDC 0x7F5c764cBc14f9669B88837ca1490cCa17c31607 (6 dec)
- **Vault value (valueAll):** 232764196 raw ≈ **$232.76** ; balance()=0 ; totalAttributions=204708765 ; totalDebt=0
- **Controller:** 0xdb8502a16efc7074ed1dd1e087d6616851c3374e (AaveV3Strategy) ; managingFund=232764196 (≈$232.76)
- **Registry:** `0x636938b5fF717F525C696F8961B9A1AEC38749A1` ; **Factory:** `0x6a9A52C8e17AeAD4f11De66282Ba6440818cf33E` ; **Parameters:** `0x5e204BF6eF5CD2594DfEb131608a8770d6A1a907`
- **Ownership:** `0x7dF2501C62b56f8dd5F1644bfC4300A517CE22BC` → owner **0x2c9bC901f39F847C2fe5D2D7AC9c5888A2Ab8Fcf** (EOA, nonce 666, futureOwner=0). Owner's fee attribution in this vault: **153,800,391 raw ≈ $153.80** (redeemable by the owner via `withdrawValue`).
- **Markets:** 37

### Unique implementations
| impl | name | clones | examples |
|---|---|---|---|
| 0x4763f9720603342aad40056db65883bd55355945 | MarketTemplate (solc 0.8.12) | 33 | 0x9cdc27b3fe…, 0x3e9ed64b43…, 0xedf6ee7660…, 0x9ad56b0a16… … |
| 0x016d4eb10fbce28010fde53c68c016b611b1aa0a | IndexTemplate (solc 0.8.12) | 4 | 0x9ac5895302…, 0x6d702e9ef0…, 0xf3037fa218…, 0x5c9618f2dc… |

### Market table (raw units, 6-dec USDC)
| market | symbol | impl | attributions | underlyingValue | totalSupply | status | paused | attrDebt | locked | totalCredit | origLiq | totalLiq | vault.debts |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 0x9cdc27b3fe01288309989d382f44fc67bdf2a5c7 | iNsure | 0x4763f972… | 0 | 0 | 0 | Trading(0) | False | — | — | — | — | — | — |
| 0x3e9ed64b439b928bc4c018e25a5b8feb0eb69138 | iTHALES | 0x4763f972… | 0 | 0 | 0 | Trading(0) | False | — | — | — | — | — | — |
| 0xedf6ee7660ffcac440ca36aa6b8d132e069b8f7e | iNsure | 0x4763f972… | 1,650,259 | 1,876,427 | 1,643,835 | Trading(0) | False | 7,519 | 0 | 0 | 1,867,879 | 1,867,879 | 0 |
| 0x9ad56b0a167c11bad4697bd1ec3d31009829442d | iNsure | 0x4763f972… | 0 | 0 | 0 | Trading(0) | False | — | — | — | — | — | — |
| 0x763a502ed8560bb07da128f78927afd3d7947b4d | iNsure | 0x4763f972… | 0 | 0 | 0 | Trading(0) | False | — | — | — | — | — | — |
| 0x1efad06a6852f867ff37dc55c3f825cd873b07f5 | iNsure | 0x4763f972… | 2,509 | 2,852 | 1,356 | Trading(0) | False | 1,154 | 0 | 0 | 1,540 | 1,540 | 0 |
| 0x40ab9c4bcdc740a58fec55e927e344105a5d5b04 | iLYRA | 0x4763f972… | 127,356 | 144,810 | 111,128 | Trading(0) | False | 15,956 | 0 | 3,366,360 | 126,668 | 3,493,028 | 0 |
| 0x707f48ccf763fca9c89f3683d2b968b51dcda687 | iNsure | 0x4763f972… | 6,150,443 | 6,993,364 | 6,123,625 | Trading(0) | False | 12,496 | 0 | 3,366,360 | 6,979,157 | 10,345,517 | 0 |
| 0xb1b03529d79f5d802551182aaf8b2be57320a9f5 | iNsure | 0x4763f972… | 12,331,349 | 14,021,366 | 12,328,766 | Trading(0) | False | 3,934 | 0 | 3,366,360 | 14,016,896 | 17,383,256 | 0 |
| 0xdb70a780a0c3cbb2dea45764f2485276cc2c0919 | iNsure | 0x4763f972… | 0 | 0 | 0 | Trading(0) | False | — | — | — | — | — | — |
| 0xbca439e119fcc5827e2e20c4c343fdb651e8a530 | iBEETS | 0x4763f972… | 0 | 0 | 0 | Trading(0) | False | — | — | — | — | — | — |
| 0x3947c8611c02199d21f1a7bd97dbc485f4298c26 | iCRV | 0x4763f972… | 5,405 | 6,145 | 676 | Trading(0) | False | 4,730 | 0 | 3,366,360 | 767 | 3,367,127 | 0 |
| 0xbb9019a6dc8c91181d5949f9478692f7372bce39 | iSNX | 0x4763f972… | 3,832 | 4,357 | 479 | Trading(0) | False | 3,354 | 0 | 134,151 | 544 | 134,695 | 0 |
| 0x64ef3ba3062649d9ca765c4327a53a40e569922e | iPERP | 0x4763f972… | 0 | 0 | 0 | Trading(0) | False | — | — | — | — | — | — |
| 0x5c5d760dbf9c32554646dac3b8bb63f93658a1d6 | iBIFI | 0x4763f972… | 193 | 219 | 0 | Trading(0) | False | 193 | 0 | 134,151 | 0 | 134,151 | 0 |
| 0x314d7541fb6ae62a9925ab7ec207d544f2ef3f2b | iNsure | 0x4763f972… | 21,525 | 24,475 | 1,232 | Trading(0) | False | 20,294 | 0 | 134,151 | 1,400 | 135,551 | 0 |
| 0xa423ed396c4d682189a448c85606a0ec8e48859c | iVELO | 0x4763f972… | 7,566,049 | 8,602,979 | 7,522,860 | Trading(0) | False | 22,352 | 0 | 134,151 | 8,577,566 | 8,711,717 | 0 |
| 0xc53d728df4fe6bf6d4130f09056df93c232b9b41 | iNsure | 0x4763f972… | 138,170 | 157,106 | 123,418 | Trading(0) | False | 14,843 | 0 | 134,151 | 140,229 | 274,380 | 0 |
| 0x05152a03baa6efde6e7fc7596abeecfba2a00a21 | iNsure | 0x4763f972… | 1,105,204 | 1,256,672 | 1,102,165 | Trading(0) | False | 4,447 | 0 | 3,353,241 | 1,251,616 | 4,604,857 | 0 |
| 0x9440de9fb570dfeace5256cba1a67def4e07e20a | iSONNE | 0x4763f972… | 0 | 0 | 0 | Trading(0) | False | — | — | — | — | — | — |
| 0xc8319451b5007f15efd9e0094304d7ca9717c8ac | iNsure | 0x4763f972… | 0 | 0 | 0 | Trading(0) | False | — | — | — | — | — | — |
| 0xd07f3c78829a4bb274a7115a5f8f1d2a9f9d572b | iIB | 0x4763f972… | 0 | 0 | 0 | Trading(0) | False | — | — | — | — | — | — |
| 0x353dd745e5f25e4ac44c4601cbb8ca3e267bb646 | iUSD+ | 0x4763f972… | 4,420 | 5,025 | 0 | Trading(0) | False | 4,420 | 0 | 3,353,241 | 0 | 3,353,241 | 0 |
| 0xdbebb640f91802b210a36a5caacf3b8251d32089 | iWPC | 0x4763f972… | 0 | 0 | 0 | Trading(0) | False | — | — | — | — | — | — |
| 0x964eacdaec44b6ed4769405d265e9b1006de7757 | iNsure | 0x4763f972… | 0 | 0 | 0 | Trading(0) | False | — | — | — | — | — | — |
| 0x6b63194f7fb93312807e422d6d5b7b1dd21c2b29 | iQI | 0x4763f972… | 0 | 0 | 0 | Trading(0) | False | — | — | — | — | — | — |
| 0xa137048ab7f39e007dda7d66c1868b77ad15bf40 | iPICKLE | 0x4763f972… | 0 | 0 | 0 | Trading(0) | False | — | — | — | — | — | — |
| 0x87b1e7fa0fd64577e8f951ac5b01a7271938a227 | iNsure | 0x4763f972… | 0 | 0 | 0 | Trading(0) | False | — | — | — | — | — | — |
| 0x2a9fc2ef8d7c9e084b14d18628dc82f572333c72 | iNsure | 0x4763f972… | 0 | 0 | 0 | Trading(0) | False | — | — | — | — | — | — |
| 0x63f624676f379af2ce51e6c0eaf2da4898f37a72 | iSDL | 0x4763f972… | 85,515 | 97,234 | 81,997 | Trading(0) | False | 3,529 | 0 | 3,353,241 | 93,222 | 3,446,463 | 0 |
| 0x1d7c4e662d898eac2563aa6ecb10ffd7a80eff51 | iNsure | 0x4763f972… | 0 | 0 | 0 | Trading(0) | False | — | — | — | — | — | — |
| 0xdb12a2c6805619fcef103e71fb7690c81e3dda38 | iNsure | 0x4763f972… | 0 | 0 | 0 | Trading(0) | False | — | — | — | — | — | — |
| 0xc34d89aed8513b1e5f840073cbae17ad317bf1dd | iNsure | 0x4763f972… | 0 | 0 | 0 | Trading(0) | False | — | — | — | — | — | — |
| 0x9ac5895302662abf7c88f1a9289f629c21634adf | iIndex | 0x016d4eb1… | 709,744 | 807,014 | 399,722 | — | False | — | — | — | — | 807,014 | 0 |
| 0x6d702e9ef07d0e5ae32f5c4bb53edcf7bc61974f | iIndex | 0x016d4eb1… | 10,892,608 | 12,385,444 | 10,000,000 | — | False | — | — | — | — | 12,385,447 | 0 |
| 0xf3037fa2185776601196bc10e88448a9518b848f | iIndex | 0x016d4eb1… | 61,741 | 70,202 | 0 | — | False | — | — | — | — | 70,202 | 0 |
| 0x5c9618f2dcc50b349d61f5f00b0371e94f203e29 | iIndex | 0x016d4eb1… | 10,052,026 | 11,429,660 | 10,000,000 | — | False | — | — | — | — | 11,429,663 | 0 |


---

## Astar (chain_id 592)

**E-U verdict: $0.00** — every value-moving path requires a role or the caller's own attribution; permissionless market creation is forced onto the real parameters contract (findings F1–F6). Owner-privileged exposure is finding F7.

- **Block (vault/market reads):** 15,064,424 ; follow-up detail block: 15,064,832
- **Vault:** `0x190dA1B9fA124BD872e9166bA3c7Dd656A11E8F8` — token USDC 0x6a2d262D56735DbA19Dd70682B39F6bE9a931D98 (6 dec)
- **Vault value (valueAll):** 548239573 raw ≈ **$548.24** ; balance()=548239573 ; totalAttributions=548239573 ; totalDebt=0
- **Controller:** none (controller()==0, keeper()==0)
- **Registry:** `0xd0Df5A352D74A746754C592a6277c9060A7c9c87` ; **Factory:** `0x7Fcd5370be47cEC0FC0a7Fe91230432dd34DdeA1` ; **Parameters:** `0xCa1FeE73b00c221966E5f25226402146BdffE259`
- **Ownership:** `0x4810fa5942A322c7bD30519eD3Ebe732066c3db3` → owner **0x2c9bC901f39F847C2fe5D2D7AC9c5888A2Ab8Fcf** (EOA, nonce 70, futureOwner=0). Owner's fee attribution in this vault: **18,863,572 raw ≈ $18.86** (redeemable by the owner via `withdrawValue`).
- **Markets:** 15

### Unique implementations
| impl | name | clones | examples |
|---|---|---|---|
| 0x0074976043140a371aead31189c2be459950c816 | PoolTemplate (solc 0.8.10) | 12 | 0x9789dc4b4b…, 0x4c1800e025…, 0xd7bd4ccba0…, 0x37d65a2f66… … |
| 0x734afd33dfb5100ee91efe690526dffdedbe0cf4 | IndexTemplate (solc 0.8.10) | 3 | 0x96f88002c1…, 0x9d5ad4016b…, 0xd07ef93b85… |

### Market table (raw units, 6-dec USDC)
| market | symbol | impl | attributions | underlyingValue | totalSupply | status | paused | attrDebt | locked | totalCredit | origLiq | totalLiq | vault.debts |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 0x9789dc4b4bb39566592b3761be42a9eb23ea5d34 | iNsure | 0x00749760… | 34,005,753 | 34,005,753 | 33,700,254 | Trading(0) | False | 0 | 0 | 0 | 34,005,753 | 34,005,753 | 0 |
| 0x4c1800e02532ed0fc60183454b9bffdf96b134f0 | iARSW | 0x00749760… | 110,702,778 | 110,702,778 | 110,525,813 | Trading(0) | False | 8,860 | 15,540,000 | 298,780,246 | 110,693,918 | 409,474,164 | 0 |
| 0xd7bd4ccba0e500e1506b4b5783339b62e4d44f7f | iATID | 0x00749760… | 1,000,000 | 1,000,000 | 1,000,000 | Trading(0) | False | 0 | 0 | 298,780,246 | 1,000,000 | 299,780,246 | 0 |
| 0x37d65a2f66d022b3f1739dedca1dfa076526d53e | inASTR | 0x00749760… | 1,084,188 | 1,084,188 | 1,000,000 | Trading(0) | False | 84,133 | 300,000,000 | 299,030,249 | 1,000,055 | 300,030,304 | 0 |
| 0x36ce8db174e14a673fd31cd46cf8dc1ce430afff | iSRS | 0x00749760… | 1,000,000 | 1,000,000 | 1,000,000 | Trading(0) | False | 0 | 0 | 250,003 | 1,000,000 | 1,250,003 | 0 |
| 0xd2b848a364df5410ce2161f9fd033da42baf7b78 | iAVAT | 0x00749760… | 1,000,000 | 1,000,000 | 1,000,000 | Trading(0) | False | 0 | 0 | 250,003 | 1,000,000 | 1,250,003 | 0 |
| 0xf89a343eeb7f5c82b5b1c8469899f8b8018c2956 | iSiO2 | 0x00749760… | 1,000,000 | 1,000,000 | 1,000,000 | Trading(0) | False | 0 | 0 | 250,003 | 1,000,000 | 1,250,003 | 0 |
| 0xe3f491c575e02902342ef8488bb3d6c392869fda | iZLK | 0x00749760… | 1,000,000 | 1,000,000 | 1,000,000 | Trading(0) | False | 0 | 0 | 250,003 | 1,000,000 | 1,250,003 | 0 |
| 0xb4bcb8a8e8c4760dd26a95c9cda302afca9063a8 | iNsure | 0x00749760… | 1,000,000 | 1,000,000 | 1,000,000 | Trading(0) | False | 0 | 0 | 250,003 | 1,000,000 | 1,250,003 | 0 |
| 0x4c83c55cdaecd197cb2ef04afb2964e4403819a0 | iMUUU | 0x00749760… | 1,100,000 | 1,100,000 | 1,100,000 | Trading(0) | False | 0 | 0 | 250,003 | 1,100,000 | 1,350,003 | 0 |
| 0xb6d53534cabf9cd65f51a9e1fc0d0be1d9bfd303 | iKGL | 0x00749760… | 1,000,000 | 1,000,000 | 1,000,000 | Trading(0) | False | 0 | 0 | 250,003 | 1,000,000 | 1,250,003 | 0 |
| 0x96f88002c1b1342da65d3d19c214ca398d3ecd7f | iIndex | 0x734afd33… | 298,780,246 | 298,780,246 | 298,764,411 | — | False | — | — | — | — | 298,780,246 | 0 |
| 0x9d5ad4016bb6b70fd2b2228471664a8cb5b97125 | iIndex | 0x734afd33… | 1,000,014 | 1,000,014 | 1,000,000 | — | False | — | — | — | — | 1,000,014 | 0 |
| 0x1fc217d745937b3858e7880ba178eb0b223fbd3c | iNsure | 0x00749760… | 0 | 0 | 0 | Trading(0) | False | — | — | — | — | — | — |
| 0xd07ef93b85e1d78d8e417eb259715bf5c29891e7 | iIndex | 0x734afd33… | 0 | 0 | 0 | — | False | — | — | — | — | — | — |


---

## Verification evidence

### 1. Gate checks (eth_call, caller 0x2222… — no transaction)
```
# All executed as eth_call at latest (keyless RPCs), caller = 0x2222...2222 (no role). No transactions were sent.
ARB vault.borrowValue(1,attacker)   -> revert "Caller is not allowed to operate"      (onlyMarket)
ARB vault.withdrawValue(1,attacker) -> revert "WITHDRAW-VALUE_BADCONDITIONS"         (no attribution of caller)
ARB vault.addValue(1,attacker,attacker) -> revert "Caller is not allowed to operate"  (onlyMarket)
ARB vault.offsetDebt(1,attacker)    -> revert "ERROR_REPAY_DEBT_BADCONDITIONS"       (no attribution of caller)
ARB vault.utilize(1)                -> revert "Caller is not allowed to operate"      (onlyController)
ARB vault.setController(attacker)   -> revert "Caller is not allowed to operate"      (onlyOwner)
ARB registry.addPool(attacker)      -> revert "ERROR: UNAUTHORIZED_CALLER"            (factory/owner only)
ARB market.applyBounty(...)         -> revert "Caller is not allowed to operate"      (parameters.getOwner() only)
ARB market.redeem(0,1,[])           -> revert "ERROR: NO_APPLICABLE_INCIDENT"         (marketStatus != Payingout)
ARB market.registerIndex()          -> revert "Not an Official Pool"                  (msg.sender not listed)
ARB index.setLeverage(2e6)          -> revert "Caller is not allowed to operate"      (parameters.getOwner() only)
ARB controller.emergencyExit(attacker) -> revert "OnlyOwner"                          (onlyOwner)
ARB ownership.commitTransferOwnership(attacker) -> revert "Caller is not allowed to operate"

OP  vault.borrowValue/withdrawValue/utilize/setController -> same reverts as ARB
OP  registry.addPool(attacker)      -> revert "ERROR: UNAUTHORIZED_CALLER"
OP  market.applyBounty / applyCover -> revert "Caller is not allowed to operate"
OP  market.redeem(0,1,[])           -> revert "ERROR: NO_APPLICABLE_INCIDENT"
OP  index.set(0,attacker,100)       -> revert "Caller is not allowed to operate"
OP  controller.emergencyExit(attacker) -> revert "OnlyOwner"

AST vault.borrowValue(1,attacker)   -> revert "ERROR_ONLY_MARKET"                     (onlyMarket)
AST vault.withdrawValue(1,attacker) -> revert "WITHDRAW-VALUE_BADCONDITIONS"
AST vault.utilize()                 -> revert (bare)                                   (controller==0)
AST vault.setController(attacker)   -> revert "Caller is not allowed to operate"
AST registry.supportMarket(attacker)-> revert "ERROR: UNAUTHORIZED_CALLER"
AST market.applyCover/applyBounty   -> revert "Caller is not allowed to operate"
AST market.redeem(0,1,[])           -> revert "ERROR: NO_APPLICABLE_INCIDENT"
AST market.resume()                 -> revert "ERROR: UNABLE_TO_RESUME"
AST market.registerIndex(0)         -> revert "ERROR: UNREGISTERED_INDEX"
AST index.compensate(1)             -> revert "COMPENSATE_UNAUTHORIZED_CALLER"
AST index.lock()                    -> revert (bare, allocPoints[msg.sender]==0)
AST index.resume()                  -> revert "ERROR: MARKET_IS_NOT_LOCKED"
AST ownership.commitTransferOwnership(attacker) -> revert "Caller is not allowed to operate"
```

### 2. Factory open-creation and reflist evidence
```
# Factory TemplateApproval events (complete history), verified per chain:
#  ARB: MarketTemplate 0x576e74.. (approval=true, isOpen=TRUE, dup=false); IndexTemplate 0xcb1468.. (false); ReserveTemplate 0xf2f7e2.. (false)
#  OP : MarketTemplate 0x4763f9.. (approval=true, isOpen=TRUE, dup=false); IndexTemplate 0x016d4e.. (false); ReserveTemplate 0x238963.. (false)
#  AST: PoolTemplate   0x007497.. (approval=true, isOpen=TRUE, dup=false); IndexTemplate 0x734afd.. (false)
# (events: 3 per chain; topics 0x647b650a..; corroborated by direct factory.templates(...) reads)

# Reference allowlist (reflist) per template, slots 1..3 (underlying/registry/parameters):
#   ARB: slot1 USDC.e=true, slot2 registry=true, slot3 params=true; wildcards 1..3 = false (slot0 wildcard=true)
#   OP : slot1 USDC=true,   slot2 registry=true, slot3 params=true; wildcards 1..3 = false (slot0 wildcard=true)
#   AST: slot1 USDC=true,   slot2 registry=true, slot3 params=true; wildcards 1..3 = false (slot0 wildcard=true)
#   Complete ReferenceApproval event history: 10 events on Arb, 10 on Op, 9 on Astar — only the values above.
# => a permissionless clone is FORCED to use the real USDC/registry/parameters.

# Permissionless creation simulation (eth_call, caller=0x2222...2222, zero balance, no approvals):
ARB factory.createPool(MarketTemplate,"attacker-poc",[0,0],[0x1111..,USDC.e,registry,params])
    -> SUCCESS, returns clone 0xfb57b8df7995b517c053b884188979642f5e18c1  (registered via registry.addPool)
OP  factory.createPool(MarketTemplate,"attacker-poc",[0,0],[0x1111..,USDC,registry,params])
    -> SUCCESS, returns clone 0xb679de5ecafbaf1eab1cdda96f548083454542a0  (registered via registry.addPool)
AST factory.createMarket(PoolTemplate,...) -> eth_call reverts data "0x" ON THE RPC because the Astar public node
    cannot execute CREATE inside eth_call (control test: a scratch contract doing CREATE returned address(0)).
    On-chain history: 15 successful createMarket txs (e.g. 0xfde93a25... block 963651) prove the path works.
    Replaying a historical createMarket tx at latest correctly reverts "ERROR: DUPLICATE_MARKET".

# Owner-only privileged simulations (eth_call --from 0x2c9bC901..., NO tx sent):
ARB vault.withdrawValue(1 USDC, owner) -> SUCCESS (burns 850745 attribution)  (owner holds fee attribution)
ARB controller.emergencyExit(owner)    -> SUCCESS (would transfer all aUSDC)
OP  controller.emergencyExit(owner)    -> SUCCESS
AST vault.setController(0x9999...)     -> SUCCESS (owner can then route vault.utilize())
```

---

## Audit findings (each with exact evidence)

**F1 — Permissionless market creation is LIVE on all three chains (owner-configured open factory).**
`factory.templates(MarketTemplate/PoolTemplate)` returns `(approval=true, isOpen=true)`. Simulated `createPool` from a zero-balance address succeeds on Arb and Op and returns a fresh clone; the factory atomically calls `registry.addPool(clone)`, so the clone is `isListed` and may call `vault.addValue/borrowValue/offsetDebt/transferDebt`. On Astar the same flow is proven by 15 historical `createMarket` txs.
*Why it is not directly extractable:* `createPool` requires every reference to pass `reflist[template][slot][ref] || reflist[template][slot][address(0)]`. For slots 1..3 (underlying token, registry, parameters) the wildcard is false and only the real USDC / real registry / real parameters contract are approved — verified by direct reflist reads at latest and by the **complete `ReferenceApproval` event history (10 events on Arb, 10 on Op, 9 on Astar; no other reference values)**. A fresh clone therefore inherits the honest parameters contract, and all value-moving owner functions (`applyCover`, `applyBounty`, `setPaused`, …) resolve to `parameters.getOwner() == 0x2c9bC901…` — not the attacker. IndexTemplate and ReserveTemplate are `isOpen=false` on every chain (ReserveTemplate is not even approved on Astar), so no attacker-controlled index or reserve can be created either.
*Latent risk (P):* if the owner ever calls `approveReference` to allow another parameters/registry address (or approves another template), any fresh market created with those references would be attacker-controlled and could `borrowValue` the vault contents. Today this requires the owner key.

**F2 — No public function moves vault value to a caller/attacker-supplied recipient.**
`MarketTemplate.withdraw` pays only `msg.sender` and only from the market's own attribution (`vault.withdrawValue(_retVal, msg.sender)`, capped by `_retVal <= _availableBalance()`). `redeem` pays `_insurance.insured` but is gated by `marketStatus == Payingout` (attacker-simulated call reverts `ERROR: NO_APPLICABLE_INCIDENT`), and `Payingout` can only be entered by `applyCover`, gated to `parameters.getOwner()` (reverts `Caller is not allowed to operate` for the attacker). `applyBounty` (the only other `borrowValue` caller) is the same owner gate. `IndexTemplate.withdraw` pays only the caller. `IndexTemplate.compensate` / `ReserveTemplate.compensate` are callable only by owner-registered markets / listed markets and only move attribution bookkeeping.
`ReserveTemplate.compensate` would let *any listed market* pull the reserve's value via `vault.transferValue(_compensated, msg.sender)` — a weak gate — but **no Reserve/CDS instance exists on any of the three chains** (`registry.getReserve(0)==0`, `registry.getCDS(0)==0`) and the template is `isOpen=false`, so the path is dead (S).

**F3 — Permissionless `registerIndex` gate cannot be reached by an unprivileged caller.**
`MarketTemplate.registerIndex()` requires `registry.isListed(msg.sender)` — i.e. the *index* must call the market. No public function of any listed template makes that call with an attacker-controlled target (IndexTemplate.set is owner-only; attacker cannot create an IndexTemplate clone, `isOpen=false`). Direct attacker call reverts `Not an Official Pool` (Arb/Op) / `ERROR: UNREGISTERED_INDEX` (Astar). Consequently no attacker can inject index credit (`totalCredit`), which is the only way to bend `_availableBalance`/`rewardPerCredit` accounting.

**F4 — Vault attribution accounting is self-consistent (no first-depositor/rounding extraction).**
`addValue` floors attribution, `withdrawValue`/`offsetDebt` round the burn up (`_divRoundUp`) — both round in favour of the remaining holders. Depositing X when `valueAll/T` is scaled returns exactly `underlyingValue(X,after) ≈ X`; the `worth()` edge case (`supply!=0 && originalLiquidity==0` → mint `= amount*supply`) yields a pro-rata claim no larger than the deposit (analysis in notes). `totalAttributions==0` while `valueAll>0` (the only inflation corner) is unreachable on these chains (516M attributions live on Arb, 205M on Op, 548M on Astar). Donation paths (`repayDebt`, `addBalance`) never favour the attacker.

**F5 — Controller (Arb/Op) has no unprivileged value-out.**
`AaveV3Strategy.returnFund`/`emigrate` are vault-gated, `emergencyExit`/setters are owner-gated (attacker sim reverts `OnlyOwner`). `adjustFund()` and `immigrate(_from)` are permissionless but only move funds *into* the Aave position from the vault or from an address that already approved the strategy — no path sends value to a caller-chosen address.

**F6 — Astar Vault variant (0.8.10) differences: none exploitable from outside.**
`borrowValue` has no `_unutilize` step (plain transfer; reverts on insufficient balance), `utilize()` is no-arg and, with `keeper==0`, would be permissionless **if a controller were set** — `controller()==0` today, and setting one is owner-only. `withdrawRedundant` only skips `balance<=tokenBalance` (no redundant balance today). All value-out paths still require the caller's own attribution or a role.

**F7 — Owners and privileged classification (P vs S).**
All three chains route ownership to a single EOA `0x2c9bC901f39F847C2fe5D2D7AC9c5888A2Ab8Fcf` (vault/registry/parameters/controller ownership; `futureOwner()==0` — no pending transfer). Nonces 77 (Arb) / 666 (Op) / 70 (Astar) show historical activity; key liveness cannot be proven on-chain. **Classified P (privileged, not E-U).** The same EOA directly holds fee attributions in each vault (376,475,435 / 153,800,391 / 18,863,572 raw) and can redeem them via the public `withdrawValue` at any time (owner-simulated withdrawal succeeds), in addition to `controller.emergencyExit` on Arb/Op and `vault.setController` + `utilize` on Astar.
**Astar former owner:** the shared Ownership contract had an interim owner `0x878bfba05b1d7c8c10868cb51be0732ed8c81646` from block 1,667,152 to 4,125,874 (AcceptNewOwnership events). That EOA still holds **75,702,994 raw ≈ $75.70** of fee attributions in the Astar vault (redeemable only via `withdrawValue`; no admin powers remain). Classification: P-legacy (its own key only), not E-U.

**F8 — Dead / dust market observations (no extraction).**
A handful of Op markets have `supply==0` with small residual attributions (iBIFI 193, iUSD+ 4420, iIndex 61741 raw) — stuck value, unreachable (withdraw requires supply != 0 but minting new shares would dilute to fair value).


---

## Notes & limitations
- Arb/Op public RPCs are non-archive: per-market “detail” reads (`attributionDebt`, `lockedAmount`, `totalCredit`, …) were taken at the follow-up block shown per chain; the vault-level reads were taken at the enumeration block. The tiny drift does not change any verdict (values move only by Aave interest / rounding dust).
- `marketStatus` is an enum: `0 = Trading` for every PoolTemplate/MarketTemplate market on all chains; IndexTemplate has no `marketStatus()`.
- Astar MarketTable source: `PoolTemplate` (solc 0.8.10) + `IndexTemplate` (solc 0.8.10); Arbitrum and Optimism are byte-identical `MarketTemplate`/`IndexTemplate`/`Factory`/`AaveV3Strategy`/`Vault` sources (solc 0.8.12).
- The Astar remainder (75,702,994 raw ≈ $75.70) belongs to the interim owner EOA 0x878bfba05b1d7c8c10868cb51be0732ed8c81646 (blocks 1,667,152–4,125,874); only that key can redeem it, so it is outside both E-U and the current-owner P path.
- Sources for every implementation and auxiliary contract are stored under `sources/`; raw reads are in `state.json`.

*Generated by make_report.py — all amounts raw 6-dec USDC unless marked $.*
