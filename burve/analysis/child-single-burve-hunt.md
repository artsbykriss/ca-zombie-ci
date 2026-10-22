# Child report — Is the "Single Pair Stable LP" Burve (`src/single/Burve.sol`) deployed on Berachain mainnet?

**Scope:** Berachain mainnet, chain id **80094**. Read-only on-chain probes only (no signing/sending).
**Mainnet block at time of probing:** **27,828,475** (`eth_blockNumber` via https://berachain-rpc.publicnode.com).
**Date:** 2026-10-22.
**Signature of the target contract:** ERC20 whose `name` ends in `-Stable-KodiakLP`, `symbol` ends in `-SLP-KDK`, and which answers `queryTVL()` (`0x3a2aabcc`) and/or `getInfo()` (`0x5b9b0b89`).

---

## (a) VERDICT

**NO — no instance of the single-pair Burve (`src/single/Burve.sol`) is deployed (or funded) on Berachain mainnet today.**

**Confidence: high (~85%).** Every direct line of evidence is negative:
- the project repo only ever deployed the single Burve to **testnet bArtio (chain 80084)**, never to 80094;
- the team's mainnet deployer EOA deployed 66 contracts, none of which is a single Burve;
- no ERC20 on Berachain matching the name/symbol/ABI signature could be found in any index reachable keyless;
- DefiLlama, the burve.fi front-end, and the Burve docs all describe/track only the multi-token Diamond, not a live single-pair pool.

The residual ~15% uncertainty is entirely due to the *limitation* that no exhaustive, keyless Berachain ERC20 name index was available (see section (c)); a deployed-but-empty, unverified single Burve that is indexed nowhere cannot be 100% excluded.

---

## (b) ADDRESSES CHECKED WITH ON-CHAIN EVIDENCE

All mainnet calls below were executed with `eth_call`/`eth_getCode` against public Berachain RPCs (publicnode / rpc.berachain.com / drpc) at/near block **27,828,475**. `name`=`0x06fdde03`, `symbol`=`0x95d89b41`, `queryTVL`=`0x3a2aabcc`, `getInfo`=`0x5b9b0b89`.

### The only known single-Burve deployment in project history — TESTNET (chain 80084), not mainnet
| Address | What it is | Evidence |
|---|---|---|
| `0xda5826868528ace919721ef324a69c16b9486d08` | **Single Burve "BurveStable"**, deployed on **chain 80084 (bArtio testnet)** | `broadcast/BurveStable.s.sol/80084/run-latest.json` → `CREATE contract: Burve`, chainId `80084`, from `0xab3042eefe6ed5dd8c681b40b30181c4b067916c` (repo commit `b04f81c`) |
| `0xab3042eefe6ed5dd8c681b40b30181c4b067916c` | testnet deployer EOA | Etherscan V2 chainid=80094 `txlist` → **"No transactions found"** (never active on mainnet) |

**Mainnet check of the testnet Burve address:** `eth_getCode(0xda58…6d08, latest)` on chain 80094 → **`0x`** (no code). → the testnet deployment does not exist on mainnet.

### The team's mainnet deployer EOA (per task context)
| Address | Evidence |
|---|---|
| `0xbe7dc5cc7977ac378ead410869d6c96f1e6c773e` | Deployed **66** contracts on mainnet (`dpl-all-creations.txt`). All 66 probed (`probe-out.json`): **none** return a name/symbol or answer `queryTVL()`. Matches found were unrelated (`CubbieBera/CUBS`, `noopMEAD/noMEAD`, etc.). |

### Single Burve candidates surfaced by Berascan search — all rejected
Searched `https://berascan.com/search?q=…` (server-rendered HTML) for the distinctive strings:

**`q=SLP-KDK`** → only 2 fuzzy/trigram hits, neither a single Burve:
| Address | Mainnet evidence (block 27,828,475) |
|---|---|
| `0xc0D1aC00A30fA4e30e44AFc7313d6312c87E21dF` | Kodiak Finance **KDK** token; `name`/`symbol` = null via generic call, no `queryTVL`; matched on "KDK" |
| `0x35E5dB674D8e93a03d814FA0ADa70731efe8a4b9` | Resolv **rlp** token; no `queryTVL`; matched on "LP" |

**`q=Stable-KodiakLP`** → 7 hits, **all unrelated** (fuzzy match on "Stable"):
| Address | Verified contract name (Etherscan V2 `getsourcecode`) | name/symbol/queryTVL |
|---|---|---|
| `0x205B459139BFE2057e7557f2c0CDE6C71D8F0EfC` | `ComposableStablePool` (Balancer) | null / null / null |
| `0x10C811844C657eB1d42aa4B52676b4F2cbCa04EE` | `ComposableStablePool` | null / null / null |
| `0xdE04c469Ad658163e2a5E860a03A86B52f6FA8C8` | `ComposableStablePool` | null / null / null |
| `0xF961a8f6d8c69E7321e78d254ecAfBcc3A637621` | `ComposableStablePool` | null / null / null |
| `0x976eF125c739b5d2F7Bb8d59045B14367eC6d444` | `ComposableStablePool` | null / null / null |
| `0x1B77105A9C79617f1e0e4655d755731Bc1D99085` | `ComposableStablePool` | null / null / null |
| `0xc0D1aC00A30fA4e30e44AFc7313d6312c87E21dF` | Kodiak KDK token | null / null / null |

**`q=Burve`** (filter=all) → 6 hits, all rejected:
| Address | Mainnet evidence |
|---|---|
| `0xb290B149bAF365cF93fA1257EE50e3EF4eb504bE` | EOA (code `0x`) |
| `0x28b88cfD875C883cDb61938C97B8d1baabf31c88` | EOA |
| `0xFF422fbaB9000Cf0B5d89111dd7eD541E05757a4` | EOA |
| `0xc6e28b94737f664b0be4230bd86793B6B6ed973B` | verified contract **`EulerIRMAdaptiveCurveFactory`**; no name/symbol/queryTVL/getInfo |
| `0xde78c116035582966B8c962b021D4015573B94b1` | EOA |
| `0x5B7D25e2c242Fa82cF24678C2D3D7cBeA4f507E9` | EOA |

### Addresses used by the (testnet) single-Burve deploy scripts — checked on mainnet
| Address | Role in script | Mainnet code (block 27,828,475) |
|---|---|---|
| `0x8a960A6e5f224D0a88BaD10463bDAD161b68C144` | HONEY/WBERA pool (`DeploySingleBurve.s.sol`) | **`0x`** (no code) |
| `0x246c12D7F176B93e32015015dAB8329977de981B` | stable pool (`BurveStable.s.sol`) | **`0x`** (no code) |
| `0x12C195768f65F282EA5F1B5C42755FBc910B0D8F` | island (`DeploySingleBurve.s.sol`) | 45-byte **minimal proxy**; `pool()`=`0x357817efaed68bd1ccc9034e963485040a822a8b` (NOT the script's pool) → coincidental address reuse, unrelated to Burve |
| `0x63b0EdC427664D4330F72eEc890A86b3F98ce225` | island (`BurveStable.s.sol`) | 45-byte **minimal proxy**; `pool()`=`0x97c69416c5c7d29cf3d163d126c5eda4372f8e79` (NOT the script's pool) → unrelated |

### Reference (multi-token Diamond, for contrast — NOT a single Burve)
| Address | Evidence |
|---|---|
| `0xa1beD164c12CD9479A1049f97BDe5b3D6EC21089` | Multi-token Diamond (deployed block 6660733). `owner()`=`0xead30c685f6b4817722018e3205c5f2edd5403db`; `getTokens()` returns 9 tokens; no `queryTVL()`. |
| `0xead30c685f6b4817722018e3205c5f2edd5403db` | Diamond owner; 20 mainnet txs, no relevant created contracts (only itself). |
| `0x89c3208A2312EEC4ad620bD78b719198Bbd0f2c7` | Older/alt Diamond referenced in some branch deployment JSONs. |

---

## (c) METHODS USED

1. **Full Git history/branch audit** of `itos-finance/Burve` (mirror clone, all 44 branches + all commits). Searched every ref for:
   - `SLP-KDK` / `Stable-KodiakLP` (only ever in `src/single/Burve.sol`, `src/Burve.sol`, `src/stable/Burve.sol` — never in a deployment artifact);
   - broadcast files: the **only** Foundry broadcasts in history are `broadcast/BurveStable.s.sol/80084/*` and `broadcast/Env.s.sol/80084/*` — **chain 80084 (bArtio testnet) only**. **No `broadcast/**/80094/**` exists anywhere.**
   - deployment JSONs (`deployed_addrs.json`, `script/berachain/deployments/*.json`, `script/deployment.json`) across all branches — every one references the **multi Diamond**, never a single-Burve address.
   - single/stable deploy scripts: `script/BurveStable.s.sol` (deleted; testnet) and `script/DeploySingleBurve.s.sol` (branches `env-debug`, `environment`; hard-coded **bArtio** pool/island addresses). No mainnet single-Burve deploy script exists.
2. **GitHub code search API** (`repo:itos-finance/Burve`) for `SLP-KDK`, `Stable-KodiakLP`, `queryTVL` — confirms the strings live only in the source + tests.
3. **On-chain probes (mainnet 80094, keyless public RPC)** — `eth_getCode`, `name()`, `symbol()`, `queryTVL()`, `getInfo()`, `pool()`, `owner()`, `getTokens()` on every candidate above; plus a 66-address batch probe of the team deployer's contracts (`probe-out.json`).
4. **Explorer search** — `berascan.com/search` for `SLP-KDK`, `Stable-KodiakLP`, `KodiakLP`, `SLP`, `Burve`, `noMEAD`, `CUBS` (HTML) and `berascan.com/searchHandler` (JSON); `testnet.berascan.com/search` for the same.
5. **Etherscan V2 API (chainid=80094)** — `account/txlist` for the testnet deployer and the diamond owner; `contract/getsourcecode` to identify the contract names of every candidate hit.
6. **DefiLlama** — `api.llama.fi/protocol/burve` (id 6388: Berachain-only, TVL "sum of all tokens in the closure", adapter targets only `0xa1beD164…`), `api.llama.fi/protocol/burve-protocol` (a *different* project on BNB/Arbitrum/Base), `yields.llama.fi/pools` (zero pools for project "burve"; zero Berachain pools with symbol matching `SLP`/`KodiakLP`), and the adapter source `projects/burve/index.js` (hard-codes the multi Diamond only).
7. **Front-end & docs** — scraped `https://www.burve.fi/pools/` (lists only "Omni-token Pools": USD up to 6.50% APR, BERA "Coming soon"); read `docs.burve.fi` "Single Pair Stable LP" page (describes the product but publishes **no contract address**).
8. **DEX indexers** — DexScreener `dex/search` for `SLP-KDK`/`Stable-KodiakLP` → **empty**; GeckoTerminal `search/pools` for `Burve` → only a BSC pair belonging to the unrelated Burve Protocol.
9. **Cross-checks attempted but unavailable (see limitations):** Blockscout MCP (`lookup_token_by_symbol`) — Berachain 80094 **not supported**; GoldRush/Covalent `/tokens/` — **credits exceeded (402)**; Dune API — account is **read-only** (cannot create/execute queries); DexPaprika `/search` — **monthly limit (402)**.

---

## LIMITATIONS / NOT COVERED

- **No exhaustive Berachain ERC20 name/symbol index was reachable keyless.** The decisive test — "does *any* token on chain 80094 have symbol ending `-SLP-KDK`?" — could not be run exhaustively. Berascan search is a fuzzy/trigram matcher (e.g. `SLP-KDK` returns KDK and rlp; `Stable-KodiakLP` returns Balancer ComposableStablePools), so its negative result is *suggestive, not conclusive*.
- Blockscout does not support chain 80094; GoldRush/Covalent credits are exhausted; Dune is read-only on the available key; DexPaprika and other indexers are out of anonymous quota.
- **Testnet bArtio (80084) is deprecated** (replaced by Bepolia), so the historical testnet deployment `0xda58…6d08` could not be re-confirmed live on its original chain; it was confirmed from the Foundry broadcast artifact plus the absence of any code at that address on mainnet.
- A single Burve deployed on mainnet **and never indexed/verified and holding zero balances** cannot be strictly ruled out; the verdict rests on the absence of *any* deploy script, broadcast, deployment JSON, DefiLlama entry, front-end listing, or explorer/indexer hit, plus the fact that the team's known mainnet deployer created none.

---

## BOTTOM LINE

The "Single Pair Stable LP" Burve is a real, audited source contract (`src/single/Burve.sol`), but the only deployment on record is to **testnet bArtio (chain 80084)**, e.g. `0xda5826868528ace919721ef324a69c16b9486d08`. **No such contract exists on Berachain mainnet (80094) today**, and the single-pair product does not appear anywhere on the burve.fi front-end, in DefiLlama, or in any mainnet explorer/indexer result. The live "Burve" on Berachain is exclusively the **multi-token Diamond `0xa1beD164c12CD9479A1049f97BDe5b3D6EC21089`** (~$32k TVL, DefiLlama `burve`).
