# analysis/ — Primus Confidential Vault (FHE), BSC

Read-only evidence for `../README.md`. **No secrets are stored here** — all RPC URLs in scripts are
keyless public endpoints; the pinned-block reads were taken through an archive RPC whose key is
redacted (`live_state.json.rpc`).

## Contents

| File | What it is |
|---|---|
| `live_state.json` | 115 `eth_call` results at BSC block **129,593,000** (owners, keepers, thresholds, balances, aggregate states). Key → `{to, sig, result}`. |
| `config_dump.txt` | Raw extract from the dapp JS chunk (`_next/static/chunks/4781-*.js`, module `83401`) containing the BSC-mainnet address config. |
| `src/src_<addr>.json` | Raw Etherscan V2 `contract&action=getsourcecode` responses (chainid 56) for every proxy **and** its implementation. |
| `src/flat/` | 272 extracted `.sol` files named `<Contract>__<addr10>__<file>.sol`. The security-relevant ones: |
| | `UnitasMintAggregatorConfidential__0x8b621304__*.sol`, `UnitasRedeemAggregatorConfidential__0xa2652e6c__*.sol` |
| | `ConfidentialConverter__0x15c0ac63__*.sol` (incl. `ConfidentialERC20Upgradeable.sol`, `ConfidentialERC20ConverterUpgradeable.sol`, `ConfidentialConverter.sol`, `Impl.sol`) |
| | `RestrictedConfidentialConverter__0x18d3f55b__RestrictedConfidentialConverter.sol` |
| | `ACL__0xe9627450__ACL.sol`, `FHEExecutor__0x349e8cf8__FHEExecutor.sol` |
| | `Decryption__0x8cacbebe__Decryption.sol`, `SpaceBridgeConfig__0x120d2112__SpaceBridgeConfig.sol` |
| | `CiphertextVerification__0xb1164e7b__CiphertextVerification.sol` |
| | `UnitasRewardPool__0xe14cfce2__UnitasRewardPool.sol` |
| | `StakedUSDuV2__0x385C2794__StakedUSDuV2.sol` / `StakedUSDu.sol`, `UnitasMintingV2__0xbB984CE6__UnitasMintingV2.sol`, `UnitasProxy__0x8d5e94c1__UnitasProxy.sol` |

## Address index (BSC 56)

```
FHE vault (Primus Confidential Finance)
  vault / UnitasProxy       0xe9E8573Bb351da16c6EE7dDaC0cBC70b7f9784AE  (impl 0x8d5e94c1eaae7d71ed4fcba2402e6b03380354f8)
  eU converter              0x3EcB7d91C98ca4B4924e0CC5Eca7472b21F06800  (impl 0x15c0ac633ef2d7f94d1b56245ccac82abd1d72a7)
  eUSDT converter           0xc2CC9419DDEb3425876091a1eb79D5C59017838c  (impl 0x15c0ac63...)
  esUSDu-u converter        0x06776741b1f8bfF5ea51750E91edcf03ed8C6994  (impl 0x18d3f55b450f092bbbcf729d866b8cf090827353)
  esUSDu-usdt converter     0x75787E2aBEE0ddaa747Eee5F0f4Ff58dB142354d  (impl 0x18d3f55b...)
  mint agg (u)              0xedcDd426f7690c7Da365f8E9BE0C396353e5dd24  (impl 0x8b6213044534be95c7d889594cedaaee7757c29d)
  mint agg (usdt)           0xE76F5202EF8eEB462eC784Fe51D69E9a8a0b56c1  (impl 0x8b621304...)
  redeem agg (u)            0xBef1366512ffFF33cdd6C48d66e48D33c6dbCa22  (impl 0xa2652e6c1a825a18567fa670ff9b4416039aad46)
  redeem agg (usdt)         0x485dBFD90DdF92E009438FF49b1918C6636a8f89  (impl 0xa2652e6c...)
  reward pool               0xCfd2917b0D8b83D7EB3a4BA637e0D8a034B7524F  (impl 0xe14cfce26ee00c4d7f3a8d0a5ebe263b49501436)
FHE system
  ACL                       0x3fE3B494Ae2d54fdee94C9fe60365024a44742AE  (impl 0xe96274507d1187ee545cccc55442a37fac6016d3)
  FHEExecutor               0x12964221F412e3e52F5f0C9592781904266dd9B4  (impl 0x349e8cf81d6a25f64281b4c34754a2a0de138d38)
  Decryption                0x29873f805e66B39c28D394B213f712B7b2B52ba1  (impl 0x8cacbebe0297ef0385c1a77f69b126678a076e4e)
  SpaceBridgeConfig         0x8914af6Bb24Cbff797Be208aBE388927C0FC0396  (impl 0x120d21125f96b68be0a156fe6a4836d4ac70a778)
  CiphertextVerification    0x9313191E3Eadc4C365d2043E8b7c03d73193D99A  (impl 0xb1164e7b5d8462564b794e9d179de09154613feb)
  AlphatrionReward          0xa536Ba1D17268e3821a17A591D7d6530cb593845  (impl 0xf6c179f2f68d5245bb5631eaaea8f7174eeffaaa)
Tokens / backend
  USDu                      0xeA953eA6634d55dAC6697C436B1e81A679Db5882
  U (United Stables)        0xcE24439F2D9C6a2289F741120FE202248B666666  (impl 0xbef21313c69c009fd7d9510a8d3a481a32473dfc)
  USDT (BSC)                0x55d398326f99059fF775485246999027B3197955
  StakedUSDuV2 (sUSDu)      0x385C279445581a186a4182a5503094eBb652EC71
  USDuSilo                  0x6F8A06A8087006309dfe89959b5b6A056bEbEAFD
  UnitasMintingV2           0xbB984CE670100AA855f6152f88b26EE57f4EA82A
Privileged actors
  owner#1 (Primus)          0xEA7Ff99584C1996Bd9E94033b5C7A1Fe37B00d87
  owner#2 (Primus)          0x3480B1E2f19D95cdfb8dA3ae40E9C7C500Fe4893
  aggregator keeper         0x43A28B8dD1ebc3752ECcfd610d70D5c2BCc18FB6
  reward-pool keeper        0x70520046798043970955AbF5189c63b11C3Dd3DC
  KMS signers (2-of-3)      0x7b0D311DE29c8AC04948a30BecB268F97d23B8ee / 0x91D3D15FE8f3b5fd4b26584FA3912dF3a432848b / 0x708f25bEc3a52748C44727909a6916439d9a08cc
  Alphatrion signers (2-of-3) 0x76b1bAa54a900e46eB1Cf8d3fbA4321075F5db13 / 0x4E7509a8aa606da5DB5B9113094E7adB15d2c608 / 0x72E772Fc2465DE96aB65202C54BC2821866CFB5E
```

## How to reproduce

```bash
# 1. resolve addresses (no key needed)
curl -s https://dapp.primuslabs.xyz/ | grep -oE '/_next/static/chunks/[^"]+\.js'
# fetch the chunks and grep the module 83401 config (see config_dump.txt)

# 2. verified source (needs ETHERSCANV2_API_KEY in env, never written to disk)
curl -s "https://api.etherscan.io/v2/api?chainid=56&module=contract&action=getsourcecode&address=0x3EcB7d91C98ca4B4924e0CC5Eca7472b21F06800&apikey=$ETHERSCANV2_API_KEY"

# 3. pinned-block reads (keyless public RPC ok for the latest block; archive needed for a pinned one)
cast call 0x06776741b1f8bfF5ea51750E91edcf03ed8C6994 "owner()(address)" --rpc-url https://bsc-dataseed.binance.org

# 4. gating probes as an unprivileged caller (read-only eth_call, nothing is sent)
cast call 0xedcDd426f7690c7Da365f8E9BE0C396353e5dd24 "dispatchAggregate()" \
  --from 0x00000000000000000000000000000000DeaDBeef --value 1000000000000000 \
  --rpc-url https://bsc-dataseed.binance.org      # -> NotKeeper(0x000..DeaDBeef)

# 5. fork PoC (heavy -> CI)
bash /home/heisenberg/CA/ci/ci-run.sh primus-fhe
```
