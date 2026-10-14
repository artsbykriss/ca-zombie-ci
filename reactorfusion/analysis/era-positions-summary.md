# ReactorFusion (zkSync Era) — positions, borrowers & liquidation scan

- **Block**: 72477761 (single block; all reads at this block)
- Comptroller `0x23848c28Af1C3AA7B999fA57e6b6E8599C17F3f2`, oracle `0x1d54dd49218333125c858c0239bbda424db55c43`
- closeFactor = 0.5, liquidationIncentive = 1.08
- Accounts with on-chain state read: **1863**; with positions: **1497**; underwater: **105**

## Markets (live)

| market | underlying | CF | dec | price USD | supply | totalBorrows | cash | supply USD | borrows USD |
|---|---|---|---|---|---|---|---|---|---|
| rfUSDCe | USDC.e | 0.85 | 6 | 0.999865 | 36,476.9240 | 25,002.6350 | 11,495.1680 | $36,472 | $24,999 |
| rfETH | ETH (native) | 0.80 | 18 | 2,508.72 | 113.1037 | 28.9586 | 84.1505 | $283,745 | $72,649 |
| rfWBTC | WBTC | 0.80 | 8 | 83,287.3 | 0.2798 | 0.1323 | 0.1475 | $23,302 | $11,018 |
| rfUSDT | USDT | 0.85 | 6 | 0.998744 | 21,665.8176 | 4,131.0327 | 17,535.6464 | $21,639 | $4,126 |
| rfZK | ZK | 0.60 | 18 | 0.0159452 | 2,224,040.3970 | 32,417.6468 | 2,191,630.9333 | $35,463 | $517 |
| rfUSDC | USDC (native) | 0.85 | 6 | 0.999865 | 3,639.1344 | 743.2646 | 2,895.8698 | $3,639 | $743 |

**Totals: supply $404,259; borrows $114,052; cash $290,245.**

## Underwater accounts (shortfall > 0)

| # | account | shortfall USD | debt USD | collateral USD | max repay USD | bonus USD | debt mkts | coll mkts |
|---|---|---|---|---|---|---|---|---|
| 1 | `0x9c20ed8ecda9ee63b80b89af7d5ac9fd8644985f` | 153.84 | 159.07 | 0.00 | 79.53 | 6.36 | rfETH $159.07 | rfZK $0.00 |
| 2 | `0xa62c69f91d0a7229a8f925868d8eb0c6943810fb` | 68.31 | 70.63 | 0.00 | 35.31 | 2.83 | rfETH $70.63 | rfZK $0.00 |
| 3 | `0x688671e84095e0fc2bd7b0de02b098cb5b6a48b5` | 5.04 | 5.13 | 0.12 | 2.56 | 0.21 | rfUSDCe $5.13 | rfETH $0.12 |
| 4 | `0x41f219c81722f3d2244f6f381e725e1f4875e796` | 4.85 | 5.13 | 0.00 | 2.57 | 0.21 | rfUSDCe $1.10, rfUSDC $4.03 |  |
| 5 | `0x55826f7459236341ee817f0478ee7832cd6f2e7f` | 3.33 | 5.17 | 3.25 | 2.58 | 0.21 | rfUSDCe $1.14, rfUSDC $4.03 | rfZK $3.25 |
| 6 | `0x62f25d0944a1b512a1d77e4dede57f72ffc8ef25` | 2.93 | 5.33 | 4.26 | 2.67 | 0.21 | rfUSDCe $1.22, rfUSDC $4.11 | rfZK $4.26 |
| 7 | `0x4e376347a9a778c1e27c097e1b4719246d26868c` | 2.14 | 3.15 | 1.62 | 1.57 | 0.13 | rfETH $3.15 | rfZK $1.62 |
| 8 | `0x02a63a450061bd6b830f172e4166686c4875742f` | 1.98 | 3.94 | 2.82 | 1.97 | 0.16 | rfUSDCe $1.52, rfZK $2.42 | rfETH $1.05, rfZK $1.77 |
| 9 | `0x7df220262a4c9ca1fa9b7224bc6f7f4572a892cc` | 1.62 | 2.99 | 2.42 | 1.49 | 0.12 | rfUSDCe $1.53, rfUSDC $1.46 | rfZK $2.42 |
| 10 | `0x71784a8b738a340c433c48cce913c1f633869830` | 1.39 | 1.39 | 0.00 | 0.70 | 0.06 | rfUSDCe $1.39 | rfETH $0.00 |
| 11 | `0x86ed8d965561418ec4fc347721bac919487c75af` | 1.35 | 1.35 | 0.01 | 0.68 | 0.05 | rfUSDCe $1.35 | rfZK $0.01 |
| 12 | `0xcb99ae35748c16e246d560f9993af496212517a0` | 1.32 | 2.63 | 1.65 | 1.32 | 0.11 | rfUSDCe $0.84, rfWBTC $1.79 | rfETH $1.65 |
| 13 | `0x5d1023475bbad9ff9c903be5e4972385c1102927` | 1.26 | 3.68 | 4.09 | 1.84 | 0.15 | rfETH $3.68 | rfZK $4.09 |
| 14 | `0x584d83263332bef5d0c2a953f5fff43153a2b615` | 1.23 | 1.54 | 0.41 | 0.77 | 0.06 | rfUSDCe $1.54 | rfETH $0.41 |
| 15 | `0x6d80c528861aa189bb3fbff4966b7f8d6a173243` | 1.16 | 3.41 | 3.80 | 1.70 | 0.14 | rfETH $3.41 | rfZK $3.80 |
| 16 | `0xb77caf495fe8d47fd7ca953714285d6a20337777` | 1.14 | 1.18 | 0.05 | 0.59 | 0.05 | rfUSDCe $1.13, rfETH $0.06 | rfUSDCe $0.01, rfETH $0.04 |
| 17 | `0x009e5fb9b87173d45e078abc426d828d56d86199` | 0.97 | 1.15 | 0.24 | 0.58 | 0.05 | rfUSDCe $1.15 | rfETH $0.24 |
| 18 | `0x025a938b15fcffc17b53a7186aef534c0c1378e6` | 0.96 | 1.16 | 0.25 | 0.58 | 0.05 | rfUSDCe $1.16 | rfETH $0.25 |
| 19 | `0x40527b1c0e6f780d4597e7ae8efdce434653e7c0` | 0.78 | 2.90 | 2.70 | 1.45 | 0.12 | rfUSDCe $0.76, rfWBTC $1.30, rfUSDT $0.39, rfUSDC $0.45 | rfUSDCe $0.00, rfETH $2.70 |
| 20 | `0x07309d827fef05c4d70605af2f38e49778f02596` | 0.75 | 2.02 | 1.64 | 1.01 | 0.08 | rfUSDCe $2.02 | rfETH $1.64 |
| 21 | `0xb672db202ed658cbc87005b3d63fe31b650fa555` | 0.69 | 1.60 | 1.14 | 0.80 | 0.06 | rfWBTC $1.60 | rfETH $1.14 |
| 22 | `0x8ed0974727378ebcf069941f14d4e71fb39468c4` | 0.66 | 3.65 | 3.74 | 1.82 | 0.15 | rfUSDCe $0.32, rfETH $1.49, rfWBTC $1.84 | rfETH $3.74 |
| 23 | `0x8cdd0b35e7d24d4733c34782efaa0c14ff3737b4` | 0.62 | 1.00 | 0.51 | 0.50 | 0.04 | rfUSDCe $0.03, rfETH $0.76, rfWBTC $0.21 | rfETH $0.30, rfZK $0.21 |
| 24 | `0xed5b514b2005b281571d4723a3c59e91f108411f` | 0.61 | 3.85 | 4.57 | 1.93 | 0.15 | rfETH $3.85 | rfETH $2.57, rfZK $2.01 |
| 25 | `0x1b3f5ff5aa2d58644f8f80854aee65dca044f76e` | 0.50 | 0.58 | 1.81 | 0.29 | 0.02 | rfUSDCe $0.30, rfUSDT $0.28 | rfETH $1.81 |
| 26 | `0xe90b70dd99263dea233753364253fdfe30032728` | 0.49 | 1.34 | 1.06 | 0.67 | 0.05 | rfWBTC $1.34 | rfETH $1.06 |
| 27 | `0x2c48ed856d83840cc727a5feb2ea54b6748aca8d` | 0.47 | 1.01 | 0.69 | 0.51 | 0.04 | rfUSDCe $1.01, rfETH $0.00 | rfETH $0.69 |
| 28 | `0x7872209b2deff8bc5c0a27ddc35eb52326a8fd16` | 0.46 | 0.75 | 0.37 | 0.38 | 0.03 | rfUSDCe $0.75 | rfETH $0.37 |
| 29 | `0xf98a4158ca994185725d9ca575f53d5f74eb5d72` | 0.43 | 2.71 | 2.87 | 1.36 | 0.11 | rfETH $0.59, rfWBTC $1.74, rfUSDT $0.38 | rfETH $2.87 |
| 30 | `0x71b3e3b3069d715bb3d4aac8fe0fd83f3d8120a4` | 0.36 | 1.54 | 1.47 | 0.77 | 0.06 | rfUSDT $1.54 | rfETH $1.47 |
| 31 | `0x27713da70026bf1409a511c2f71f9f389acad80a` | 0.33 | 1.14 | 1.42 | 0.57 | 0.05 | rfUSDCe $1.14 | rfZK $1.42 |
| 32 | `0xd397236e68c9cd0e0ef948648f74e09550515810` | 0.33 | 1.28 | 1.23 | 0.64 | 0.05 | rfUSDCe $1.28, rfETH $0.00 | rfUSDCe $0.00, rfETH $1.23 |
| 33 | `0x7a98f63debb9036c72c44b92d70b61b2eec42eb5` | 0.33 | 3.17 | 4.15 | 1.58 | 0.13 | rfETH $3.17 | rfETH $1.94, rfZK $2.21 |
| 34 | `0x6ad87ab20934cb3601bfeb64fc962f57768e26c8` | 0.31 | 1.16 | 1.06 | 0.58 | 0.05 | rfUSDCe $0.33, rfWBTC $0.61, rfUSDT $0.22 | rfETH $1.06 |
| 35 | `0x00a54dd33f2afffe5487875ec0606a2f93eac329` | 0.31 | 0.38 | 0.13 | 0.19 | 0.02 | rfUSDCe $0.38 | rfZK $0.13 |
| 36 | `0x7deaec5462b99d29ccb4be41e63f46a80ae3e205` | 0.29 | 0.58 | 0.38 | 0.29 | 0.02 | rfUSDCe $0.15, rfETH $0.33, rfWBTC $0.10 | rfETH $0.29, rfZK $0.10 |
| 37 | `0x17bcb6ac05befdc4a6c3eccac0d2e62563875104` | 0.29 | 0.95 | 0.79 | 0.48 | 0.04 | rfUSDCe $0.95 | rfUSDCe $0.79 |
| 38 | `0x117b993bd80e4d10b21290f7fd6c10af69a0938c` | 0.28 | 0.94 | 0.77 | 0.47 | 0.04 | rfUSDCe $0.94 | rfUSDCe $0.77 |
| 39 | `0x00ab5a2a8be47c19795407dbb2a8026404b2aa1f` | 0.27 | 0.90 | 0.74 | 0.45 | 0.04 | rfUSDCe $0.90 | rfUSDCe $0.74 |
| 40 | `0x10f1568175af3e130fb7bc5bc6e8199a57df8dbb` | 0.26 | 0.88 | 0.73 | 0.44 | 0.04 | rfUSDCe $0.88 | rfUSDCe $0.73 |
| 41 | `0x155099458814b37c9cf8142ecc1875033ccfa2b2` | 0.26 | 0.87 | 0.71 | 0.43 | 0.03 | rfUSDCe $0.87 | rfUSDCe $0.71 |
| 42 | `0x1d2acf02722c505ead9cb5a2ff9ba4755df0af13` | 0.26 | 0.59 | 0.43 | 0.30 | 0.02 | rfUSDCe $0.59 | rfETH $0.43 |
| 43 | `0x0abc9a5292fdee14b5414ce40596dc9c92a20c1d` | 0.26 | 0.86 | 0.71 | 0.43 | 0.03 | rfUSDCe $0.86 | rfUSDCe $0.71 |
| 44 | `0xbde72edb8da76771f895a96856155d5a5e563e90` | 0.25 | 1.06 | 1.01 | 0.53 | 0.04 | rfWBTC $1.06 | rfETH $1.01 |
| 45 | `0x0ab53b1b7a3ca5ea4a301225a8efbb09cb925833` | 0.25 | 0.82 | 0.68 | 0.41 | 0.03 | rfUSDCe $0.82 | rfUSDCe $0.68 |
| 46 | `0x05a2b7eab54a32e884ac07d690bd01644e01bd73` | 0.23 | 0.78 | 0.65 | 0.39 | 0.03 | rfUSDCe $0.78 | rfUSDCe $0.65 |
| 47 | `0x78c7114ce50d83a4a86c33d5843cd9809619d042` | 0.23 | 0.47 | 0.30 | 0.24 | 0.02 | rfUSDCe $0.44, rfETH $0.04 | rfETH $0.30 |
| 48 | `0x0b2d3dd982dbc6c2ee2dd34d0057ae5f08a726c1` | 0.23 | 1.37 | 1.47 | 0.68 | 0.05 | rfUSDCe $1.37 | rfETH $1.47 |
| 49 | `0x7400c0ff47a824a9b64d33ebdaff0071ac9fb98f` | 0.23 | 0.54 | 0.35 | 0.27 | 0.02 | rfETH $0.54 | rfUSDCe $0.35 |
| 50 | `0xa39027dde266cb16c99615019827b5d3303a8c20` | 0.23 | 1.27 | 1.34 | 0.63 | 0.05 | rfUSDCe $1.27 | rfETH $1.34 |
| 51 | `0x135393afe1ce97d050fcb719d1c4239ea51f8000` | 0.20 | 0.68 | 0.56 | 0.34 | 0.03 | rfUSDCe $0.68 | rfUSDCe $0.56 |
| 52 | `0x3bd7a89aace0a9fac66a9255d49e9866c4a8f016` | 0.20 | 0.67 | 0.55 | 0.33 | 0.03 | rfUSDCe $0.67 | rfUSDCe $0.55 |
| 53 | `0x01f81a6317bea9c6acbef5e80bedb2a4fe35c45a` | 0.20 | 0.66 | 0.54 | 0.33 | 0.03 | rfUSDCe $0.66 | rfUSDCe $0.54 |
| 54 | `0x2a4a4b6ee7fc6030b81e19502e26ba51a2ab7c5a` | 0.19 | 0.47 | 0.32 | 0.24 | 0.02 | rfWBTC $0.47 | rfUSDCe $0.32 |
| 55 | `0x04904c10f1df3639f35db5cf6462175435b94803` | 0.18 | 0.59 | 0.49 | 0.30 | 0.02 | rfUSDCe $0.59 | rfUSDCe $0.49 |
| 56 | `0x4ae0f6d1e3d76f2bc0b771d0559d4ce33cbbddf3` | 0.18 | 0.64 | 0.52 | 0.32 | 0.03 | rfETH $0.64 | rfUSDCe $0.52 |
| 57 | `0xf54502f36175a167c4e3d6ed749738ed709686cf` | 0.16 | 0.58 | 0.52 | 0.29 | 0.02 | rfWBTC $0.33, rfUSDT $0.25 | rfETH $0.52 |
| 58 | `0x2fd06770c8d685f7041150b9968979930b9c2ce1` | 0.16 | 1.25 | 1.41 | 0.63 | 0.05 | rfUSDCe $1.25 | rfETH $1.41 |
| 59 | `0xbae6f47ec72aa3c8b09f442b35f981e587796666` | 0.15 | 0.28 | 0.16 | 0.14 | 0.01 | rfUSDCe $0.28 | rfETH $0.16 |
| 60 | `0x18d88cc2d4135dab73cc8fee8750e9eaa62b28f0` | 0.15 | 0.25 | 0.13 | 0.13 | 0.01 | rfUSDCe $0.25 | rfETH $0.13 |

**Underwater totals: 105 accounts; max single-pass repay ≈ $180.74; liquidator bonus ≈ $14.46.**

## Largest positions read (by debt USD)

| account | debt USD | collateral USD | adj collateral USD | shortfall USD | full state? | debt mkts |
|---|---|---|---|---|---|---|
| `0x8110298dd3183a2806e1066ca8a5e3834cf08d73` | 2,043.81 | 5,651.57 | 4,003.42 | 0.00 | True | rfUSDCe $1,525.52, rfWBTC $0.03, rfUSDT $518.26 |
| `0xc76209fbf05d38fcfe5462082734e45b5dce66c6` | 1,599.84 | 0.00 | 0.00 | 0.00 | False | rfUSDCe $1,599.84 |
| `0x54a7ede07e5af20530ecb65f850ab7d20dd308e8` | 359.42 | 1,235.37 | 1,048.88 | 0.00 | True | rfETH $359.42 |
| `0x3e0e25bb1b6e78b04eee17d747db674cb84a7133` | 290.93 | 660.84 | 521.24 | 0.00 | True | rfUSDCe $290.93 |
| `0x9ee4642a491e9c04af8cc7cce7d0bdfaa6765382` | 262.39 | 0.00 | 0.00 | 0.00 | False | rfUSDCe $262.39 |
| `0x46e8043224d0532d9d731ae58aee523dfc264965` | 206.34 | 564.03 | 414.42 | 0.00 | True | rfUSDCe $206.34 |
| `0x8a803f5f9377673397d00f4bc704c7da55111a7c` | 167.65 | 0.00 | 0.00 | 0.00 | False | rfUSDT $167.65 |
| `0xc29dc373aebc2db141aa5a8ef109cee746a99ab8` | 162.93 | 0.00 | 0.00 | 0.00 | False | rfUSDCe $162.93 |
| `0x9c20ed8ecda9ee63b80b89af7d5ac9fd8644985f` | 159.07 | 0.00 | 0.00 | 153.84 | True | rfETH $159.07 |
| `0x1bc73f51d9f8dd093c6ecee09ae6da2a1be62ea0` | 152.67 | 562.71 | 343.90 | 0.00 | True | rfUSDCe $152.67 |
| `0xc3b822c6462fb0a7df34e143a2a34d360a7a3893` | 116.84 | 0.00 | 0.00 | 0.00 | False | rfUSDCe $116.84 |
| `0x25d4ef82374e02e8f94535efa18f224e1e715e6a` | 107.56 | 138.88 | 111.10 | 0.00 | True | rfETH $107.56 |
| `0xa02a1ab39ef37b7d860d7a791661703023389149` | 84.69 | 431.41 | 258.84 | 0.00 | True | rfUSDCe $84.69 |
| `0xe66fbc8be19bd6b60a7fdc743a1019435ee0a04f` | 75.61 | 94.24 | 77.40 | 0.00 | True | rfUSDCe $27.40, rfETH $48.21 |
| `0xa62c69f91d0a7229a8f925868d8eb0c6943810fb` | 70.63 | 0.00 | 0.00 | 68.31 | True | rfETH $70.63 |
| `0x2a2864ad3190534961c9e059c5a2dbae6b8e726e` | 63.18 | 96.32 | 77.05 | 0.00 | True | rfUSDCe $23.28, rfETH $39.90 |
| `0x3cc39a1c89e470c2cf10b8f7bca768f0c7426a8c` | 61.09 | 236.53 | 141.92 | 0.00 | True | rfUSDCe $61.09 |
| `0xf3d6f5800ab8f0312d0dd7e0f5f3da1fe73dd217` | 43.25 | 0.00 | 0.00 | 0.00 | False | rfUSDCe $43.25 |
| `0x7997c1fcceb50111330c161660fc811baba74bb2` | 37.66 | 72.26 | 57.81 | 0.00 | True | rfUSDCe $37.66 |
| `0x3e73553cc3ddc0b386a549de534462e87d552999` | 34.30 | 44.63 | 35.70 | 0.00 | True | rfETH $34.30 |
| `0x0d6f1d4e2dfeb01142450950c61127c8a7a48a82` | 29.67 | 132.48 | 79.49 | 0.00 | True | rfUSDCe $29.67 |
| `0x78b3367b0f547cd16bac453f788956afce92447b` | 27.19 | 298.45 | 233.00 | 0.00 | True | rfETH $27.19 |
| `0x5b38dda75a794e084d059954d4597efe51a0a5f7` | 26.48 | 0.00 | 0.00 | 0.00 | False | rfWBTC $26.48 |
| `0x376d6dd8c45901e62ee4ebb3df63f4cc8d2a59ac` | 26.41 | 109.63 | 65.78 | 0.00 | True | rfUSDCe $26.41 |
| `0x7001ea6a2c7bcf12654641e5bd47c616c8a08f87` | 25.62 | 0.00 | 0.00 | 0.00 | True | rfUSDCe $25.62 |
| `0x090476500ca188fd2ada370bb1b4e020f86e8eaf` | 20.19 | 68.66 | 41.54 | 0.00 | True | rfETH $20.19 |
| `0x67830a2e4381e9049b37339b9b0d6514dde0ca6b` | 19.86 | 25.05 | 20.04 | 0.00 | True | rfETH $19.86 |
| `0xd6b5c6e1651dfb2e98b5db9df76824da92097a1a` | 19.46 | 0.00 | 0.00 | 0.00 | False | rfUSDCe $19.46 |
| `0x2bcf3dc34e616f01573a4d6c55b5d3a3921f243b` | 18.59 | 37.34 | 29.88 | 0.00 | True | rfUSDCe $18.59 |
| `0x45d3730a8f811519f3cc310d54ffc4d2142b3773` | 18.47 | 36.29 | 29.03 | 0.00 | True | rfUSDCe $18.47 |
| `0x8ef3264a51f4bc65303f7ab2b96aef2ca6c35daf` | 16.80 | 32.01 | 25.61 | 0.00 | True | rfUSDCe $16.80 |
| `0x29147bb06ec4ec46d000771180f20f9e33c97c70` | 15.30 | 62.66 | 37.59 | 0.00 | True | rfETH $15.30 |
| `0xe724bfc847d412703bf2065dcbec33687037e69c` | 15.19 | 19.30 | 15.76 | 0.00 | True | rfUSDCe $6.17, rfETH $9.03 |
| `0x2c16d4c5afd6dba484b88972fc80e217adb180eb` | 15.04 | 28.34 | 23.05 | 0.00 | True | rfETH $15.04 |
| `0x9c7804909513a7d200a9b0408c06fadbb5ef38a9` | 13.81 | 0.00 | 0.00 | 0.00 | False | rfUSDCe $13.81 |
| `0xce4df63e402cf661eeee372b77a666a7e5505dc6` | 13.14 | 27.07 | 21.97 | 0.00 | True | rfUSDCe $4.11, rfETH $9.03 |
| `0x02e9c9892958728cff30203c12b2263777a793d9` | 9.89 | 23.30 | 16.73 | 0.00 | True | rfUSDCe $6.17, rfUSDC $3.71 |
| `0xa26a93a4a504a75a8824c20a11292408b5595044` | 9.05 | 0.00 | 0.00 | 0.00 | True | rfETH $9.05 |
| `0x7212ab82f0229f67abbe4eed40dd69494939930b` | 8.77 | 0.00 | 0.00 | 0.00 | False | rfUSDT $8.77 |
| `0x667194a13318dd03ecb3fe47cdb8e43e6381618d` | 8.71 | 0.00 | 0.00 | 0.00 | False | rfUSDT $8.71 |

## Transaction-based interaction stats (deduped by tx hash)

| market | unique txs | accounts (tx.from) | borrowers (borrow txs) | borrow | repay | mint | redeem | liquidate |
|---|---|---|---|---|---|---|---|---|
| rfUSDCe | 101,803 | 45,578 | 18,330 | 22,022 | 21,101 | 31,314 | 25,931 | 19 |
| rfETH | 53,376 | 26,593 | 2,755 | 4,056 | 0 | 0 | 25,569 | 0 |
| rfWBTC | 47,802 | 15,241 | 10,280 | 15,782 | 16,760 | 8,135 | 6,782 | 0 |
| rfUSDT | 26,199 | 11,078 | 7,135 | 7,979 | 8,119 | 5,817 | 4,281 | 0 |
| rfZK | - | - | - | - | - | - | - | - |
| rfUSDC | - | - | - | - | - | - | - | - |

## Event counts per market (eth_getLogs scan; coverage partial)

| market | logs scanned | Mint | Redeem | Transfer | Borrow | RepayBorrow | LiquidateBorrow | failed segments |
|---|---|---|---|---|---|---|---|---|
| rfUSDCe | 511,545 | 132,529 | 121,510 | 257,506 | 0 | 0 | 0 | 3 |
| rfETH | 305,055 | 72,385 | 78,301 | 154,369 | 0 | 0 | 0 | 1 |
| rfWBTC | 31,911 | 8,606 | 7,281 | 16,024 | 0 | 0 | 0 | 1 |
| rfUSDT | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| rfZK | 51,529 | 14,094 | 10,315 | 27,120 | 0 | 0 | 0 | 1 |
| rfUSDC | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

## Debt coverage (attributed vs on-chain)

| market | on-chain totalBorrows (USD) | attributed from reads (USD) | accounts with debt found | coverage |
|---|---|---|---|---|
| rfUSDCe | $24,999.27 | $5,090.09 | 725 | 20.361% |
| rfETH | $72,648.98 | $1,076.21 | 589 | 1.481% |
| rfWBTC | $11,017.99 | $75.13 | 120 | 0.682% |
| rfUSDT | $4,125.85 | $743.54 | 69 | 18.022% |
| rfZK | $516.90 | $2.42 | 1 | 0.468% |
| rfUSDC | $743.16 | $19.54 | 7 | 2.629% |

_The unattributed remainder sits in borrower accounts outside the crawled block ranges / sampled sets; sampled averages indicate it is spread over thousands of small residual positions._

## Method & coverage caveats

- State read via `getAccountSnapshot` / `getAccountLiquidity` eth_calls at one fixed block (keyed env RPCs + public; no secrets stored).
- **This fork's cTokens emit no Borrow/RepayBorrow/LiquidateBorrow events** (verified from verified ABI + 1M+ logs scanned with topic filters). Borrowers are enumerated from transactions (zkSync explorer txlist: methodId + input), then `borrowBalanceStored`/snapshots.
- GoldRush `events/address` is broken for these contracts (stops ~May-2023, no Borrow events) — not used as primary.
- Transaction crawls cover large but not all block ranges (public API rate limits): rfETH 1.9-6.1M + 40-64M; rfUSDCe 1.9-8.2M + 25-26M + 50-72.5M; rfWBTC 1.9-47M; rfUSDT 1.9-24M; rfZK/rfUSDC partial.
- Event scan (eth_getLogs) coverage is partial; event counts above are lower bounds. Historical totalBorrows sampled via archive eth_call.
- Borrower universe (deduped txs crawled): see table; the protocol was heavily farmed and most historical borrowers have fully repaid.
