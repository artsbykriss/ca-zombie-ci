# Printr — live-state inventory (EVM chains)

Work date: 2026-10-14. Read-only: every number below comes from `eth_call`/`eth_getStorageAt`/`eth_getCode`,
Etherscan V2 metadata, GoldRush balances or the CI fork (block **26,192,609**, Ethereum).
No mainnet transaction was ever sent. Keyed RPC URLs are not stored anywhere in this folder.

## 1. Contract map (Ethereum mainnet)

| Role | Address | Code | Notes |
|---|---|---|---|
| PrintrCore proxy (same on all chains) | `0xb77726291b125515d0a7affeea2b04f2ff243172` | 273 B ERC1967 (verified `PrintrProxy`) | EIP-1967 impl slot read per chain |
| Implementation (Ethereum) | `0x014da58b3ec914fc661ba810c619e86a286468ba` | 16,485 B, **unverified** | dispatcher = 38 selectors (buy/sell/spend/witnessSell + getters) |
| Teleport (fallback target) | `0xc5e0c0ecb27d800bb4068cdfa7219af3dd33f8bd` | 20,079 B, **unverified** | fallback delegatecall target of the impl; 61 selectors |
| Module (teleport fallback target) | `0xb163ec43b56fa2afec83b2d382fce0e95608e6d1` | 20,111 B, **unverified** | fee distribution / owner / print / quoting; UUPS (`UPGRADE_INTERFACE_VERSION` 5.0.0) |
| Treasury (current) | `0x8c843012b347664caf84b907053754208a933fee` | 2,228 B, unverified | `printr()` immutable = core; holds curve reserves |
| Treasury (legacy) | `0xde420c835240216198bf4fd1eda28d7ead2a1549` | 2,320 B, unverified | `printr()` = core; migration source |
| LZ channel LZ_FAST(2) | `0x69b20d727573a47a47104388af8b3772c69dc384` | 2,917 B | `printr()` = core, `protocol()` = 2 |
| LZ channels LZ_SECURE(3) / LZ_SLOW(4) | `0xef9275d8…d39` / `0x03b2bdd5…228` | **no code on Ethereum** | `getLzChannel(3/4)` returns undeployed addresses |
| LZ endpoint (V2) | `0x1a44076050125825900e736c501f859c50fe728c` | — | standard LayerZero V2 |
| Module/proxy owner | `0x8dd1886ba3ab106f595ab7a8a831577c2d21c273` | EOA | Ownable2Step owner (pause/upgrade/protocol admin) |
| Fee funds (growth=buyback=team=staking) | `0x65f7a87c6e055f55edd81fc01eee506f66acd4ab` | — | all four fee splits point at one address on Ethereum |
| Staking contract (PrintrStaking proxy) | `0x49336345486268fd2e24fe8c400e0310be98b5d5` | verified proxy | impl `0x0c4ed257…` (ERC721 staking positions) |
| Locker | `0x25c9c4b56e820e0dea438b145284f02d9ca9bd52` | verified `UniV3LPLocker` | holds locked UniV3 LP NFTs |
| Liquidity module | `0x95f1dffd1db61fc8c4694879fc6b4710990edc0a` | unverified | delegatecalled for pool create/swap/LP deploy |
| create3Deployer | `0x1f279e2fd9c4febd6f2b009b627441aa7639ce88` | verified `Create3Deployer` | used for channel/treasury/token addresses |
| printrDev NFT | `0x1e1577ba4dc74007ed6e8fb3d3ce2ce5477f531d` | 9,880 B | creator NFT (`mint` gated; attacker call reverts `0x878d41a8`) |
| mainTelecoinFactory | `0xf908631d1eda180cb90b87ac8b03dea8e080fef6` | unverified | |
| wrappedNativeToken | `0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2` | WETH | |

Chain-specific values (read live):

| chain | block | impl | treasury() | teleport() |
|---|---|---|---|---|
| ethereum | 26,192,609 | `0x014da58b…68ba` | `0x8c843012…3fee` | `0xc5e0c0ec…f8bd` |
| base | 52,555,856 | `0x1a5708e3…2454` | same | `0x5c7456cf…f8cb` |
| mantle | 101,919,105 | `0x5b9a66a5…d83ca` | same | `0x00ac3e90…67f1` |
| arbitrum | 514,820,494 | `0xe2bfd303…78f8` | same | `0x72339ab5…f078` |
| bsc | 127,565,826 | `0x07b92b4a…d3e5` | same | `0x24b338c8…f519` |
| avalanche | 97,514,314 | `0x24fa38d8…3525` | same | `0x9726f8e2…fe80` |
| monad | 113,248,591 | `0x60a898f1…395d` | same | (RPC flaky at read time) |

All impls are 16,485 B with different hashes → same code, different constructor immutables (chain constants).

## 2. Configuration (read on Ethereum via the proxy)

- `VERSION` = `v1.0.0`; `paused()` = **false**
- `tradingFee()` = **100 bips (1 %)**
- `protocolTelecoinShareBps` = 7500; `feePercentTeam` = 7000; `feePercentCreator` = 3000; `feePercentGrowth` = 0; `feePercentBuyback` = 0
- counters: main telecoins = 3623 (`0x2a373068`), teleporting telecoins = 1720 (`0xa9e9984a`)
- `getTeleportProtocolWhitelist()` = 0x1e (bits 1-4); only LZ_FAST channel deployed on Ethereum
- `receiveFromChannel` requires: `msg.sender` == CREATE3-computed channel, `protocol == 2`, and
  **`originSender == 0x27289e1d3b5c3af5e16600167c7463fcaa125509fc61e2de08491aece7993b5f`** (hardcoded Solana peer)

## 3. Live balances (treasury, GoldRush 2026-10-14; WETH ≈ $2,458.7 from the same quote)

| chain | value | main components |
|---|---|---|
| ethereum | **$10,485.25** | 4.264570 WETH (226 nonzero tokens incl. thousands of telecoins ≈ $0) |
| base | **$3,911.99** | 1.567211 WETH + 62.66 USDC (3,285 nonzero telecoins ≈ $0) |
| bsc | **$6,092.72** | 8.283933 WBNB (1,251 nonzero) |
| avalanche | **$3,114.38** | 312.341290 WAVAX (953 nonzero) |
| monad | **$6,148.93** | 253,980.017 WMON (2,926 nonzero) |
| arbitrum | ~$515 (triage) | 0.2066 WETH (GoldRush retry blocked by HTTP 552) |
| mantle | **$10,969.93** | 21,049.599 WMNT (GoldRush 2026-10-14) |
| **total ≈** | **$41,238** | |

Core contracts hold dust only (BSC $69.49; others ≈ 0). Staking contract: $0 (Ethereum, dust) / $0.02 (Base).
Legacy treasury (Ethereum): 24 nonzero tokens, all spam/dust → $0 non-spam.
Treasury WETH on the fork at block 26,192,609: `4,264,570,067,570,463,102` wei (CI log).

## 4. Call-surface audit (all read-only, fork-verified in `poc/test/PrintrLive.t.sol`)

| path | attacker result | verdict |
|---|---|---|
| `treasury.withdraw(WETH, attacker, 1)` | revert `WrongAccess()` (`0x6c5ffd54`) | closed |
| `treasury.withdraw(WETH, core, 1)` | succeeds | core-only |
| `legacyTreasury.withdraw(WETH, attacker, 1)` | revert `WrongAccess()` | closed |
| `pause()/unpause()/transferOwnership/renounceOwnership/upgradeToAndCall/updateGlobalProtocols` | revert `OwnableUnauthorizedAccount(address)` | P (owner EOA) |
| `receiveFromChannel(2, peer, msg)` from attacker | revert `UnauthorizedCaller()` | closed |
| `receiveFromChannel(2, peer, msg)` from channel with wrong peer | revert `UnauthorizedCaller()` | closed |
| `receiveFromChannel(2, correct peer, msg)` from channel | passes auth → `InvalidPayloadLength()` | only genuine Solana peer |
| `buy`/`spend` then `sell` round trip (3 live curves) | buy OK; sell OK after approval; net ETH loss ≈ 2 % | no profit |
| `collectProtocolFees(token)` from attacker | callable (permissionless) but attacker WETH/ETH/token delta = 0; pays funds/creator/stakers | no attacker profit |
| `printrDev.mint(telecoinId, attacker)` | revert `0x878d41a8` | closed |

## 5. Notes / negative results

- The teleport fallback chain is `proxy → impl → teleport → module`; only the module has owner/admin functions.
- `LZ_SECURE`/`LZ_SLOW` channels are undeployed on Ethereum → teleport with protocol 3/4 reverts (liveness only).
- The treasury gate is an immutable `printr` address inside bytecode (not storage) — cannot be re-pointed.
- The token contracts (`PrintrTelecoin`) are verified (`0xae0f1b6a…77777`): `teleportIn/Out` are core-gated;
  `permitWitnessCall` binds the whole call (target/method/params) into the signed witness and enforces
  `params[0:32] == owner`; nonce + deadline; no redirect/replay path found.
- `spend`/`buy` rounding always favours the protocol (cost rounded up, refund rounded down, quote -1 wei on remainder).
