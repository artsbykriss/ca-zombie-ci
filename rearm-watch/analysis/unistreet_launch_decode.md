# Unistreet `LaunchpadFactoryAuto` — launch decode & fork-replay package

**Prepared:** 2026-10-16 · **Fork/verification block:** 26,201,639 (Ethereum mainnet) · **Read-only work**
**Factory:** `0xFB60CD0B36aD4bD839b91767a6Ad9055AB6aD825` · **Uniswap v4 PositionManager (POSM):** `0xbD216513d74C8cf14cf4747E6AaA6420FF64ee9e`
**Deliverables:** `analysis/unistreet_launch_calldata.json` (replay-ready blobs) · `analysis/unistreet_original_decoded.json` (byte-exact original decodes) · `analysis/unistreet_replay_scripts/` (helper scripts)

---

## TL;DR

- The factory made **19 `Launched` events in 15 real `launch()` txs** (4 more launches were made by the exploit/PoC contracts; those 4 **minted no positions**). All 15 seeded positions were created, then **swept in the August 2026 incident**: **7 by the exploit tx `0x9583e95d…`** (block 25,692,311) and the remaining **8 by the follow-up `0x962eb313…`** (block 25,692,392). The same pincer also hit a second factory (`0xd5799fd858d9163e75d28b2e4f68cf8569167ad8`, 4 positions burned).
- **Root cause (re-confirmed):** `launch()` forwards caller-supplied `initCalldata`/`modifyCalldata` verbatim into `POSITION_MANAGER.multicall([...])` **as the factory**. `multicall` uses `delegatecall` to itself, so the inner calls run with `msg.sender == factory`. A caller thus makes the factory call `setApprovalForAll(attacker, true)` on POSM (topic `0x17307eab…`), owning **every current and future position** the factory mints.
- **Sweep primitive:** POSM `BURN_POSITION` (action `0x03`) — “will automatically decrease liquidity to 0 if the position is not already empty” — burns the NFT and, with a following `TAKE_PAIR` (`0x11`), sends **both pool currencies straight to the approved attacker** (actions `0x0311`). Verified against the verified POSM source.
- **Replay package verified twice at block 26,201,639:**
  1. `eth_call` of the re-encoded **Pigcon** launch succeeded → returns predicted new token `0xcEB58068e2673753290aC172150864ed80d244C2`. Same for the **AFAO** alternative → `0x7542879bAD2FFc182CFDf200442cF56e6D845b0E`.
  2. Full **anvil fork e2e**: victim launch → `POSM.ownerOf(463532) == factory` → fresh attacker injects approval via its own malicious launch → attacker sweeps position 463532 → **attacker nets 60.888584 USDC + 988,440.250384850245701038 PIGCON′**, factory back to 0 positions.
- **Live risk today (2026-10-16):** `POSM.isApprovedForAll(factory, ·)` is still `true` for 4 operator contracts (`0xc7d8c70f…`, `0xeda1f193…`, `0x3c59433d…`, `0xde2e6079…`). **Any new launch on mainnet is instantly sweepable by those 4 contracts.** `POSM.balanceOf(factory) == 0` (nothing left to steal *today*).

---

## 1. Contract inventory & selectors

| Item | Value |
|---|---|
| Factory | `0xFB60CD0B36aD4bD839b91767a6Ad9055AB6aD825` (deployed block 25,668,142, 2026-08-02 15:37:59 UTC, tx `0x02bce355…`) |
| Clone implementation | `0x40f8727fC5686B6f3af581F3cE551Bd0278CC0e0` (`LaunchTokenAuto`) |
| Factory owner | `0xfF7fB7dd56a86727f7c67C4b2b7C6F536F98a0f4` (also first launcher) |
| PositionManager (ERC-721 owner of all LP positions) | `0xbD216513d74C8cf14cf4747E6AaA6420FF64ee9e` (verified `PositionManager` v0.8.26, v4-periphery) |
| v4 PoolManager | `0x000000000004444c5dc75cB358380D2e3dE08A90` |
| Universal Router | `0x66a9893cC07D91D95644AEDD05D03f95e1dBA8Af` |
| Second factory also hit in the incident | `0xd5799fd858d9163e75d28b2e4f68cf8569167ad8` (`launchesCount()=6`, same owner, 0 positions today) |

Selectors / topics used in this report:

| Signature | 4-byte / topic0 |
|---|---|
| `launch((string,string,uint256,address,uint256,bytes32,string,string,string,string,bool),bytes,bytes,(address,uint256,bytes,bytes[],uint128[],address[]))` | `0x171f9e3e` |
| `harvest(address)` | `0x0e5c011e` |
| `initializePool((address,address,uint24,int24,address),uint160)` | `0xf7020405` |
| `modifyLiquidities(bytes,uint256)` | `0xdd46508f` |
| `setApprovalForAll(address,bool)` | `0xa22cb465` |
| `Launched(address,address,address,string,string)` (topic0) | `0xc5a807b0033def274292e9d3ba676e6fcfb69d9d383ccf9b69112237bd95def9` |
| `ApprovalForAll(address,address,bool)` (topic0) | `0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31` |

Factory tx census (Etherscan V2 `txlist`, 26 txs): **15 direct `launch()`, 10 `harvest()`, 1 deployment**. Four additional launches were made from contracts (internal calls): at blocks 25,692,311 / 25,692,392 / 25,692,393 / 25,692,449.

---

## 2. All 19 launches (Launched events + txlist + `positionIdOf`)

`*` = position swept by exploit tx `0x9583e95d…`; `†` = swept by follow-up `0x962eb313…`; `‡` = no position minted (malicious calldata).

| # | block | launch tx | token | name (symbol) | launcher | paired | msg.value | positionId |
|---|------:|-----------|-------|---------------|----------|--------|-----------|-----------:|
| 0 | 25,668,757 | `0xa15936e3cc9d3eab330793ae12e1fa2e331bf28c080c3358a5ad7df00d60f292` | `0x3Bf4118F8862857872e6c13f87743Ab05a52Bc7D` | Unistreet (UNISTREET) | `0xfF7f…a0f4` | USDC | 0.375 ETH | 360162 `*` |
| 1 | 25,669,320 | `0x23447df6cec2d6a548add76ad9212a640f463a7aa9e371b3c467ad7c3a0b063c` | `0x52D48B1eb8067756f4104924F99ace9E5D058142` | GPU | `0xfF7f…a0f4` | `0x2d1f…bdee` | 0.03 ETH | 360222 `†` |
| 2 | 25,670,406 | `0x3d6aaed42d2c843dd69837640d32eaa23968a2f8521cfd90510635750fac04c9` | `0x1d6191DB2Ea17d11e6f84ECa0b937cB5639ce1d2` | Apple Cat (AAPLCAT) | `0x74ae…1e6a` | `0x14c3…2d4c` | — | 360377 `†` |
| 3 | 25,670,427 | `0xd9bf3f85131c7299e5c432b8229371597744b7f1c484471575d067c9ab4c0d35` | `0x9f479358d303422b7aF1BC0805d32d37D5961b64` | Tesla Optimus (OPTIMUS) | `0x74ae…` | `0xf6b1…103f` | — | 360379 `†` |
| 4 | 25,670,447 | `0xf03d0b36b0ddf0e9b4409e1931267c9bfe17977c4d54dbd244bf9e04c6cd9113` | `0x0270285A9054634C160D5D0A99e0e5229f756333` | STONKS | `0x9b71…e103` | `0xFeDC…2c08` | — | 360381 `†` |
| 5 | 25,670,453 | `0xb932245888fa66d2fffea29ece897ae4d263bfb2c63b525b7099059db64ec7d6` | `0xe5Dfc7562dD68D5168dA89769BC92D9B81D577d6` | SP69 | `0x2aaf…ddf6` | `0xFeDC…` | 0.04 ETH | 360382 `†` |
| 6 | 25,670,474 | `0x2833586eb266aaa6d63dd975458fc478da64195e798bd55193e287ddb94b316b` | `0x954727c49CBD6e2432E7Ad7533232b53e2dc81FC` | Unistreet Strategy (UNISTR) | `0x9b71…` | WETH | — | 360385 `*` |
| 7 | 25,683,797 | `0xdf73ca36395b25845fcd3e8916cb6dfa99fff23b383ed5767f58a5124948dfa7` | `0xae8acEAA7e210Dfa7172e16f8325286E148BDF93` | STAMIND (STARMIND) | `0x2aaf…` | `0x2d1f…` | 0.159 ETH | 363100 `†` |
| 8 | 25,684,003 | `0x599a835608ea98f756e0d3cccf1b7ec9e2c742c0bfc1ffdccf451be9f9bf6435` | `0xBac02f09e4A734086184064acf885d6C9e686c57` | Eth Mascot (LESLIE) | `0x8d1d…fc23` | WETH | — | 363137 `*` |
| 9 | 25,684,074 | `0x3d7f74428f5e94404709776a3af2fca02a79e9e0762eddc3cde7aafe5c6d3b45` | `0xd096a97331331D1eAeBFFb4EDCC48C74D8E04d70` | POTATO | `0x8d1d…` | WETH | — | 363145 `*` |
| 10 | 25,684,418 | `0x182386915344034949ce35813ec50c41a4f69f6162bf9dab1ad7d9c6a334b984` | `0x55448900B289c9fC1e8adBc8215bee1a029a129F` | Starmind (SPCX) | `0xf80f…b381` | `0x2d1f…` | 0.015 ETH | 363188 `†` |
| 11 | 25,685,523 | `0xc664115779eac584820ef34b13de76aeb9775e27d5aedcea15c04f64d1a7abf4` | `0xD424997D961e0e6e9c545498565E284EDfa40725` | ¬America First America Only (AFAO) | `0x7f77…3c45` | `0xFeDC…` | 0.1 ETH | 363414 `†` |
| 12 | 25,686,897 | `0x15eee3747594cc6d846d44da11ce6063a3603c4831f886a96880dcde84ae5816` | `0x3Fd263E3baDea86b6dAC10f331A60949E75657e6` | Unicorn (UNICORN) | `0x8d1d…` | WETH | — | 363678 `*` |
| 13 | 25,690,249 | `0xe4d7d32984a3aa644a86a8227d9e7aa01d8bea166b2b6187c50ae820d73cf67c` | `0x593Cc7d69be66Fa37746DB9437baD571EE3D36e9` | Catstreet (CATSTREET) | `0x8d1d…` | WETH | — | 364293 `*` |
| 14 | 25,690,730 | `0xacc0d1ce0ce545eb6a6ae2f8f6cfb6413cc59acb6fcfd4a84eef18587a966e85` | `0xAa145d7f316e0EaC3DDb163331CA770F2eb5307f` | Pigcon (PIGCON) | `0xC80D…194c` | USDC | 0.025 ETH | 364347 `*` |
| 15 | 25,692,311 | internal call inside exploit deploy `0x9583e95d…` | `0x3d8A2F4c522D7A6dac89820fC669D6552F25988E` | constructor-poc (CPOC) | exploit contract `0xc7d8c70f…6b77` | WETH | — | 364,584 `‡` |
| 16 | 25,692,392 | `0x962eb313a1290f9e1de336782d2e3fd0c6dc7b7816834bbef50278d28dbefb0b` | `0x6996b34c6BaE4a424818f6B951c8300B679886Ec` | drain-poc (DRN) | `0xeda1f193…205a` | WETH | — | 364,598 `‡` |
| 17 | 25,692,393 | `0x521ec066c637c9aaf765f9d9dc82f2861c8015d55bed623b9a238727eefb3c3f` | `0x861a3D2566E408a4378C2653C1d26C2dee57e18e` | drain-poc (DRN) | `0x3c59433d…5f51` | WETH | — | 364,598 `‡` |
| 18 | 25,692,449 | `0xcee7faa014170b4073123eb3bf06ddbd1454c502982872b13cd15c24810e7fb7` | `0x260b3402437a8A23377cF8Ec7E375f80a48e1563` | repro-poc (RPOC) | `0xde2e6079…7a6c` | WETH | — | 364,609 `‡` |

Notes:
- The `‡` IDs are the `positionIdOf` snapshots taken **before** the malicious multicall; `POSM.ownerOf()` for 364,584 / 364,598 / 364,609 reverts `NOT_MINTED` — those launches never minted an NFT (the `modifyCalldata` slot was used for `setApprovalForAll`).
- Harvest txs (10): blocks 25,668,848 / 25,668,884 / 25,668,904 / 25,670,477 / 25,677,705 / 25,677,709 / 25,677,726 / 25,683,985 / 25,684,023 / 25,687,957 (method `0x0e5c011e`).
- The launch txs are all `to = factory`; the four PoC launches are **internal** calls from the deployed attacker/PoC contracts, hence invisible in `txlist`.
- **Today (block ≈ 26,201,605):** `launchesCount() == 19`, `POSM.balanceOf(factory) == 0`, `POSM.nextTokenId() == 463530`.

---

## 3. The incident (2026-08-06 00:27–00:35 UTC)

### 3.1 Exploit tx — block 25,692,311 — `0x9583e95d5c88c7966e269197f4b09022f26b7a27ad2c13660dda6774e3136d14`

This is a **contract creation** (`to = null`, 17 KB initcode) from EOA `0xc94e23c58b9b2998edb7abc8f99393fead985076`; the deployed contract `0xc7d8c70f4349acc55409800c8768e801b7556b77` performs the attack **in its constructor** (one tx, atomic). Key receipt events:

```
[ 3] V4_POOL_MANAGER Initialize (CPOC pool created)          <- initCalldata slot = initializePool (valid call)
[ 4] ApprovalForAll POSITION_MANAGER: owner=FACTORY operator=0xc7d8c70f…6b77 approved=True   <- modifyCalldata slot = setApprovalForAll
[ 6] Launched token=0x3d8A2F…988E (constructor-poc), launcher=0xc7d8c70f…6b77
[ 7] ERC721 Transfer POSM: FACTORY -> 0x0 tokenId=360162      <- BURN_POSITION (auto-decreases liquidity)
[ 8] V4 ModifyLiquidity (delta = −liquidity)
[ 9] ERC20 Transfer 0x3Bf411… UNISTREET: PM -> 0xc7d8c70f…  amount=194762138870014350824479
[10] ERC20 Transfer USDC: PM -> 0xc7d8c70f… amount=17685818100
… (same triple for 6 more tokenIds) …
[32..41] loot forwarded from 0xc7d8c70f… to EOA 0xc94e23c5…
```

The attacker’s launch is the exact `launch()` code path: the factory mints CPOC, then `POSITION_MANAGER.multicall([initializePool, setApprovalForAll])` executes **as the factory** (`multicall` `delegatecall`s to POSM; `msg.sender` stays the factory), so POSM records an operator approval from the factory to the attacker. No MINT_POSITION means no CPOC position — but the factory now owns **no newly-protected positions at all**.

### 3.2 Why `setApprovalForAll` was enough (sweep mechanics)

Verified POSM source (`PositionManager.sol`, deployed at `0xbD2165…`):

- `BURN_POSITION` (`0x03`, params `(uint256 tokenId, uint128 amount0Min, uint128 amount1Min, bytes hookData)`), comment: *“Will automatically decrease liquidity to 0 if the position is not already empty.”* `_burn()` is gated only by `onlyIfApproved(msgSender(), tokenId)` — an operator approval passes.
- `_burn()` emits ERC-721 `Transfer(factory, 0x0, tokenId)` first, then `poolManager.modifyLiquidity(..., liquidityDelta = −liquidity)` (the log shows burn **then** the decrease), crediting POSM’s deltas.
- A following `TAKE_PAIR` (`0x11`, params `(address currency0, address currency1, address recipient)`) sends **both currencies to the attacker-chosen recipient**.

Hence the sweep action byte-string is **`0x0311`** per position.

### 3.3 The 7 positions swept in the exploit tx (task item 5)

| tokenId | token | original launch tx | block | contained at sweep (token side) | paired side |
|--------:|-------|--------------------|------:|--------------------------------:|-------------|
| 360162 | UNISTREET `0x3Bf4…Bc7D` | `0xa15936e3…f292` | 25,668,757 | 194,762.138870014350824479 | 17,685.8181 USDC |
| 364347 | PIGCON `0xAa14…307f` | `0xacc0d1ce…6e85` | 25,690,730 | 990,832.743807381699492546 | 58.089129 USDC |
| 360385 | UNISTR `0x9547…81FC` | `0x2833586e…316b` | 25,670,474 | 998,652,042.988167494522831927 | 0.003721675186263759 WETH |
| 363137 | LESLIE `0xBac0…6c57` | `0x599a8356…6435` | 25,684,003 | 999,114.072950077539650974 | 0.00348789569564756 WETH |
| 363145 | POTATO `0xd096…4d70` | `0x3d7f7442…3b45` | 25,684,074 | 0.999999999999999999 | — |
| 363678 | UNICORN `0x3Fd2…57e6` | `0x15eee374…5816` | 25,686,897 | 9,999.9999999999999999977 | — |
| 364293 | CATSTREET `0x593C…36e9` | `0xe4d7d329…f67c` | 25,690,249 | 999,999.999999999999999999596 | — |

Loot forwarded to EOA `0xc94e…5076` in the same tx (logs 32–41): CPOC 1e24 (launch leftover) + **0.007209570881911319 WETH + 17,743.907229 USDC** + all token amounts above.

### 3.4 Follow-up txs (same incident, same operator pattern)

- `0x962eb313…` (block 25,692,392): swept the **remaining 8** factory positions — 360222 (GPU), 360377 (AAPLCAT), 360379 (OPTIMUS), 360381 (STONKS), 360382 (SP69), 363100 (STARMIND), 363188 (SPCX), 363414 (AFAO) — **and** 4 positions of the second factory `0xd5799fd8…` (361912, 361944, 363097, 363919), after injecting approvals on both.
- `0x521ec066…` and `0xcee7faa0…`: approval injections on the factory (and on `0xd5799fd8…`) only; no burns.
- All four PoC/PoC-style txs are one-shot contracts deployed per tx (sample checks on Etherscan show unverified source); the deployed instances still hold the approvals today.

**Net effect:** all 15 factory positions were drained across two txs ~5.4 minutes apart (00:27:47 → 00:33:08); today `POSM.balanceOf(factory) == 0`. The four injected operator approvals **remain live on mainnet**, so a new launch is immediately at risk.

---

## 4. Decoded seed-buy launches

Two real launches decoded in full (byte-exact in `analysis/unistreet_original_decoded.json`):

### 4.1 Pigcon — PRIMARY replay candidate — tx `0xacc0d1ce…` (block 25,690,730)

`Params`

| field | value |
|---|---|
| name / symbol | `Pigcon` / `PIGCON` |
| supply / seedAmount | `1000000000000000000000000` (1e24) both |
| pairedStock | USDC `0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48` |
| salt (orig) | `0xd3f0bc3f5c5961f2fd43b74f4418ae191b1ab17d8a5b0171b81efc0a15b79bbe` |
| description | `""` |
| image | 2,983-char `data:image/webp;base64,…` (kept verbatim in the JSON) |
| website / twitter | `https://github.com/Uniswap/unipig/blob/master/www/static/pigcon.png` / `https://x.com/Uniswap/status/1181470959498227712` |
| holdersShare | `true` |

`initCalldata` (196 B) — `initializePool((address,address,uint24,int24,address),uint160)` `0xf7020405`:

- PoolKey `(currency0=USDC, currency1=token 0xAa14…307f, fee=10000, tickSpacing=200, hooks=0x0)`
- `sqrtPriceX96 = 1120455419495722798374638764549163435` (≈ price 200 tokens/USDC; current tick ≈ 329,3xx, just above the position range)

`modifyCalldata` (868 B) — `modifyLiquidities(bytes,uint256)` `0xdd46508f`:

- unlockData `actions = 0x020d` → **MINT_POSITION (0x02)** + **SETTLE_PAIR (0x0d)**
- MINT_POSITION params: same PoolKey; `tickLower = 269000`, `tickUpper = 329000`; `liquidity = 75578006572755136`; `amount0Max = 0`; `amount1Max = 1e24`; `owner = factory`; `hookData = 0x`
- SETTLE_PAIR: `(USDC, token)`
- `deadline = 1785958836` (original; **rewritten to 4102444800** in the replay)

`SeedBuys`:

- `payAsset = WETH`, `totalPayIn = 25000000000000000` (0.025 ETH), `preCommands = 0x00` (Universal Router command **V3_SWAP_EXACT_IN**)
- `preInputs[0]` = `(recipient = 0x00…01 = UR sentinel “MSG_SENDER” → the factory, amountIn = 2.5e16, amountOutMin = 0, path = WETH -500- USDC, payerIsUser = true)`
- `amounts = [2.5e16]`, `recipients = [0xC80D6DeaD5205fe62abB9009510D1bA13C3B194c]` (original launcher)
- `msg.value` = 0.025 ETH exactly.

Receipt cross-validation (tx succeeded): `ApprovalForAll` absent (honest launch), POSM minted **tokenId 364347** to the factory; token settle `999999999999999996129584` (1e24 − 3,870,416); v3 swap WETH→USDC `47,868,873`; v4 seed buy USDC→PIGCON returned `9,109,341,349,439,837,110,375` to the launcher + 3,870,416 dust — full flow matches the calldata decode.

### 4.2 ¬America First America Only (AFAO) — secondary candidate — tx `0xc664115779…` (block 25,685,523)

- `supply/seedAmount` 1e24; `pairedStock = 0xFeDC5f4a6c38211c1338aa411018DFAf26612c08` (stock token); salt `0x78292b2e…`; `holdersShare` (as decoded).
- init `initializePool`, PoolKey `(currency0 = AFAO token 0xD424`, `currency1 = 0xFeDC…`, 10000, 200, 0)`, `sqrtPriceX96 = 200955998787779260925394748`.
- modify: `actions = 0x020d`; MINT `tickLower = −119200`, `tickUpper = −59200`, `liquidity = 2715918765149857016287`, `amount0Max = 1e24`, `amount1Max = 0` (position funded entirely on the token0 side); SETTLE_PAIR `(token0, 0xFeDC…)`.
- SeedBuys: WETH 0.1 ETH; UR V3 path **WETH -500- USDC -3000- 0xFeDC…** (two-hop); recipient `0x7f77F1fA…3C45`.

---

## 5. Fork-replay package (fresh salt, latest block)

### 5.1 Re-encoding rules applied

1. **Fresh random salt** (old salt’s clone exists → CREATE2 collision), regenerated until the clone’s address preserves the original currency ordering.
2. Token address replaced in the three places it appears: `initCalldata` PoolKey, modifyCalldata MINT_POSITION PoolKey, modifyCalldata SETTLE_PAIR pair. Everything else is byte-for-byte the original.
3. `modifyLiquidities` deadline → `4102444800` (2100-01-01) so it is valid at any fork timestamp.

| | Pigcon (primary) | AFAO (alt) |
|---|---|---|
| fresh salt | `0x754c689e2ab73347fef62ef3f1a1d1726043a4048b42c250287518c9b6bfcac0` | `0x74047be8eda3a91843e4bfd4803b80a57b9c09bdfe6e9fbd46b04512bfe0d26e` |
| predicted token | `0xcEB58068e2673753290aC172150864ed80d244C2` | `0x7542879bAD2FFc182CFDf200442cF56e6D845b0E` |
| `factory.predict(salt)` | ✓ matches local OZ-Clones CREATE2 | ✓ |
| `value_wei` | `25000000000000000` | `100000000000000000` |
| currencies kept | `currency0 = USDC < currency1 = token` ✓ | `currency0 = token < currency1 = 0xFeDC…` ✓ |
| `eth_call` @ block 26,201,639 | **SUCCESS** → returns `0x…ceb58068…44c2` | **SUCCESS** → returns `0x…7542879b…5b0e` |

### 5.2 Validation evidence

- **Encoder round-trip:** rebuilding the *original* `launch()` input for both txs from the decoded fields reproduces the on-chain calldata **byte-identically** (11,658 and 11,274 hex chars). This proves the decode/encode pipeline before the salt swap.
- **`eth_call` at block 26,201,639** (public RPC, from a funded address, `value = value_wei`): no revert, return value equals the predicted clone address — the full launch (CREATE2 deploy, `initializePool`, Permit2 approvals, MINT_POSITION+SETTLE_PAIR, v3 pre-swap, v4 seed buy) executes against real mainnet state.
- **anvil fork e2e at block 26,201,639 (`analysis/unistreet_replay_scripts/e2e_fork_demo.py`):**

| step | tx | gas | result |
|---|---|---:|---|
| victim `launch()` (this JSON) | `0x5faba8bbd23d3b9a63c4e5ce405c0f52d0f94dc58b2d6c17786a6815f8cbf8ca` | 3,504,091 | token `0xcEB58068…`; **position 463532 minted, `ownerOf == factory`**; real liquidity seeded (seed buy + 1 %-fee pool) |
| fresh attacker approval-injection launch | `0x8eb542173bcf25dd2327b9b142cc4b39412270afa89f3d7e99aba64c2d142f7e` | — | `POSM.isApprovedForAll(factory, attacker) == true` |
| attacker sweep (`actions 0x0311`) | `0x2973fd1ac47d8b7b04eb92fab559c770bfe3374fbf649491acb165497bae25cb` | 247,962 | position burned; **attacker received 60.888584 USDC + 988,440.250384850245701038 PIGCON′**; factory POSM balance back to 0 |

(The fork sweep nets slightly more USDC than the historical one because the v3 WETH/USDC price at block 26,201,639 differs from Aug 2026 — 0.025 ETH ≈ $60.89 vs $47.87 — good sanity check.)

### 5.3 Using `analysis/unistreet_launch_calldata.json` from a Foundry test

Top level of the JSON is exactly the requested schema for the primary victim launch: `salt`, `predictedToken`, `params`, `initCalldata`, `modifyCalldata`, `seedBuys`, `value_wei` (plus metadata: `sourceTx`, `predictedTokenCheck`, `e2e`, `altLaunch`, `attackerReplay`, `mainnetStateToday`).

```solidity
// sketch - consume with forge-std
string memory json = vm.readFile("analysis/unistreet_launch_calldata.json");
bytes32 salt       = vm.parseJsonBytes32(json, ".salt");
address predicted  = vm.parseJsonAddress(json, ".predictedToken");
assertEq(FACTORY.predict(salt), predicted);                  // CREATE2 sanity

// build Params field-by-field (vm.parseJsonString/Uint/Address/Bool), then:
// params.salt = salt must be set from the JSON string (bytes32).
ILaunchpadFactoryAuto.Params memory p = ...;
ILaunchpadFactoryAuto.SeedBuys memory sb = ...;
bytes memory initCalldata   = vm.parseJsonBytes(json, ".initCalldata");
bytes memory modifyCalldata = vm.parseJsonBytes(json, ".modifyCalldata");
uint256 valueWei            = vm.parseJsonUint(json, ".value_wei");

vm.deal(victim, 1 ether);
vm.prank(victim);
address token = FACTORY.launch{value: valueWei}(p, initCalldata, modifyCalldata, sb);
require(token == predicted, "token mismatch");
// position: POSM.ownerOf(POSM.nextTokenId()-1) == address(FACTORY)
```

Notes for the test author:
- `params.image` is a ~3 KB data URI; substituting `""` is harmless for the attack demo (metadata only) — but do not change the numeric/currency fields.
- `seedBuys.recipients` currently points at the historical launcher `0xC80D…194c`; substitute the victim address if the demo should show the victim receiving seed-buy tokens.
- The `attackerReplay` section contains a working malicious-launch blob and a sweep blob from the fork run (hard-coded to the demo attacker `0x…1111`; regenerate for another address — see the scripts).
- Fork at **26,201,639** for parity with these results, or `latest`.

---

## 6. Appendix — exact commands (public RPCs only; API key read from env, never printed)

```bash
RPC=https://ethereum-rpc.publicnode.com
FACTORY=0xFB60CD0B36aD4bD839b91767a6Ad9055AB6aD825
POSM=0xbD216513d74C8cf14cf4747E6AaA6420FF64ee9e

# method id / topics
cast sig "launch((string,string,uint256,address,uint256,bytes32,string,string,string,string,bool),bytes,bytes,(address,uint256,bytes,bytes[],uint128[],address[]))"   # 0x171f9e3e
cast keccak "Launched(address,address,address,string,string)"   # 0xc5a807b0…def9
cast sig "initializePool((address,address,uint24,int24,address),uint160)"   # 0xf7020405
cast sig "modifyLiquidities(bytes,uint256)"                     # 0xdd46508f

# Etherscan V2 (txlist / logs / raw txs / receipts)
set -a; . /home/heisenberg/CA/.env; set +a
curl -s "https://api.etherscan.io/v2/api?chainid=1&module=account&action=txlist&address=$FACTORY&sort=desc&apikey=$ETHERSCANV2_API_KEY"
curl -s "https://api.etherscan.io/v2/api?chainid=1&module=logs&action=getLogs&fromBlock=25668142&toBlock=latest&address=$FACTORY&topic0=0xc5a807b0033def274292e9d3ba676e6fcfb69d9d383ccf9b69112237bd95def9&apikey=$ETHERSCANV2_API_KEY"
curl -s "https://api.etherscan.io/v2/api?chainid=1&module=proxy&action=eth_getTransactionByHash&txhash=0xacc0d1ce…&apikey=$ETHERSCANV2_API_KEY"

# on-chain reads
cast call $FACTORY 'launchesCount()(uint256)' --rpc-url $RPC                      # 19
cast call $POSM 'balanceOf(address)(uint256)' $FACTORY --rpc-url $RPC             # 0
cast call $FACTORY 'predict(bytes32)(address)' 0x754c689e…cac0 --rpc-url $RPC     # 0xcEB58068…
cast call $POSM 'isApprovedForAll(address,address)(bool)' $FACTORY 0xc7d8c70f4349acc55409800c8768e801b7556b77 --rpc-url $RPC   # true

# eth_call verification of the replay (block 0x18fce27 = 26201639)
cast rpc eth_call '{"from":"0x28C6c06298d514Db089934071355E5743bf21d60","to":"0xFB60CD0B36aD4bD839b91767a6Ad9055AB6aD825","value":"0x58d15e17628000","data":"<init/modify blobs assembled by build_calldata.py>"}' 0x18fce27 --rpc-url $RPC

# local fork + full e2e (scripts copied into analysis/unistreet_replay_scripts/)
anvil --fork-url https://ethereum-rpc.publicnode.com --fork-block-number 26201639 --port 8555
python3 analysis/unistreet_replay_scripts/e2e_fork_demo.py
```

Script pipeline (`analysis/unistreet_replay_scripts/`):
`decode_launch.py` (raw tx → decoded JSON) → `reencode_launch.py` (fresh salt + token swap → replay JSON) → `build_calldata.py` (full `launch()` calldata; `original` mode round-trips vs the historical inputs) → `e2e_fork_demo.py` (anvil validation incl. attack).

---

## 7. Caveats

- This package is for **fork simulation only** — all blobs were validated with `eth_call`/anvil and must never be broadcast to mainnet.
- The fresh salts are single-use per fork instance (CREATE2). Re-running on the same anvil instance requires regenerating.
- `params.image` (data URI) is preserved byte-exact in the JSON; the `4byte`-style decoders and some tooling may truncate it in logs — only the JSON matters for encoding.
- The 4 live POSM operator approvals on mainnet mean a real new launch is sweepable **now**, without the attacker even needing to inject anything; the fresh-attacker path (malicious launch) is what the incident used and what the e2e demo replicates.
- Out-of-scope but noted: the same incident also drained the sibling factory `0xd5799fd8…` (4 positions, same owner).
