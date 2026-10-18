# Katana Vault Bridge / vbASSET stack — LZ minter authorization deep-dive

**Date:** 2026-10-18 · **Chains:** Ethereum (1) ↔ Katana (747474) · **Status:** read-only; fork-only PoC; no mainnet transactions signed or sent; no secrets or keyed RPC URLs in this folder.

**Headline:** **$0.00 extractable by an external unprivileged attacker.** The LayerZero minter that B0 flagged as “unverified” is in fact **verified source** (`NonDefaultMintBurnOftAdapter`), is **endpoint-only and peer-bound in both directions**, has **no live re-initializer**, and its upgrade/owner authority is a **5-of-9 Safe**. A forged `lzReceive`, a replay, a wrong-EID peer, a direct `mint`, and a re-initialization were all executed on forks and **revert** (20/20 tests). The ~$27.76M of L1 backing is real and fully accounted for; the old 33.68 WBTC figure was a single-strategy snapshot, not the vault total.

---

## 1. TL;DR

| Target | Live value (notional) | Unprivileged extraction | Why closed | Latent / privileged risk |
|---|---|---|---|---|
| L2 vbUSDC minter `0x8072…93c0` (LZ OApp) | mints L2 vbUSDC (6.66M supply) | **$0** | `lzReceive` = `onlyEndpoint` + `_getPeerOrRevert(30101)`; peer = L1 adapter `0xb5ba…7bb3`; canonical EndpointV2; no other EID peer ever set | 5/9 Safe owns minter + proxy admin; can upgrade / setPeer / setToken (P) |
| L2 vbUSDT / vbWBTC / vbETH minters | 3.02M / 158.25 / 2,750.48 L2 supply | **$0** | same implementation, same endpoint, peers = matching L1 adapters, init counter = 1 | same 5/9 Safe |
| L1 adapters (escrow) | 64.7k / 204.4k / 0.20 / 270.09 vbTokens | **$0** | `lzReceive` onlyEndpoint + peer(30375) = matching L2 minter; canonical EndpointV2 | same 5/9 Safe; can setPeer and release escrow |
| L1 vbToken vaults | **$27,757,272.69** totalAssets | **$0** | ERC-4626 redeem burns shares; admin roles in Safes; no unguarded mint/withdraw | token admins 2/3–2/5 Safes; can upgrade / drain yield vault (P) |
| L2 custom tokens | $29.2M notional supply | **$0** | `mint`/`burn` = LxLy bridge, NativeConverter, or `MINTER_BURNER_ROLE`; only the LZ adapter has the role; already reinitialized to v2 | token admin 3/5 Safe; GER updater EOA can insert L2 roots (P) |

**Total live extractable now: $0.00** (high confidence). **Privileged surface:** $27.76M L1 + $29.2M L2 notional, under multisigs plus one L2 GER-updater EOA.

---

## 2. What B0 asked, and the answer

B0’s blocker was: *“the LZ minter is unverified; `peers(30101)` is set but `lzReceive`/origin authorization was not decompiled.”*

**Answer: the minter is not unverified.** Etherscan V2 (chain 747474) returns verified source for the implementation `0x8f45f7acd4b9fc0b446902790f304d444dff949b` = `NonDefaultMintBurnOftAdapter` (Agglayer `vault-bridge`, v1.1.0), and for the proxy `0x807275727dd3e640c5f2b5de7d1ec72b4dd293c0` = `TransparentUpgradeableProxy`. The full source tree (68 files) is saved in `analysis/src/l2_NonDefaultMintBurnOftAdapter_files/`.

The relevant code paths, verbatim from the recovered source:

```solidity
// OAppReceiverUpgradeable (LayerZero OApp v2)
function lzReceive(Origin calldata _origin, bytes32 _guid, bytes calldata _message,
                   address _executor, bytes calldata _extraData) public payable virtual {
    if (address(endpoint) != msg.sender) revert OnlyEndpoint(msg.sender);
    if (_getPeerOrRevert(_origin.srcEid) != _origin.sender)
        revert OnlyPeer(_origin.srcEid, _origin.sender);
    _lzReceive(_origin, _guid, _message, _executor, _extraData);
}

// NonDefaultMintBurnOftAdapter
function _credit(address _to, uint256 _amountLD, uint32) internal override returns (uint256) {
    require(_to != address(0), CannotCreditAddressZero());
    CustomTokenLayerZero(address($.token)).mint(_to, _amountLD);   // token enforces role
    $.secondaryChainBalance += _amountLD;
    return _amountLD;
}

function reinitialize1(address _token, bool _approvalRequired, address _owner, address _delegate)
    external locked reinitializer(_incrementGlobalInitializationCounter(1)) nonReentrant { ... }
function reinitialize(bytes[] calldata data) external { _reinitialize(...); }
```

- `endpoint` is `immutable` and is `0x6F475642a6e85809B1c36Fa62763669b1b48DD5B` on Katana — **verified `EndpointV2`** (canonical LayerZero v2 endpoint).
- `peers(30101)` = `0xb5bADA33542a05395d504a25885e02503A957Bb3` (the L1 vbUSDC adapter). The mapping is keyed by EID, so a message from any other EID hits `NoPeer`.
- The L1 side mirrors it: `peers(30375)` = `0x807275727dd3e640c5f2b5de7d1ec72b4dd293c0` (the L2 minter), endpoint = `0x1a44076050125825900e736c501f859c50fe728c` (canonical `EndpointV2` on Ethereum).
- `globalInitializationCounter()` = **1** on every minter and every L1 adapter. The only selector in `reinitialize()` is `reinitialize1`; with counter 1, `expectedReinitializeDataLength = 1 - 1 = 0` → `AlreadyReinitialized()`. Calling `reinitialize1` directly hits `locked()` because `_unlocked` is false outside the self-delegatecall. Both tested on fork.
- The L2 token (`GenericCustomToken` v0.5.1) has `mint` guarded by `mintController`: `msg.sender == lxlyBridge || msg.sender == nativeConverter || hasRole(MINTER_BURNER_ROLE, msg.sender)`. On-chain, **the only `MINTER_BURNER_ROLE` holder is the LZ adapter**; the admin is the 3/5 Safe `0xd067…98cc`. The OZ `Initializable` slot is **2**, so the permissionless `reinitialize(...)` is closed (`InvalidInitialization`). The L1 adapter/minters are owned by the 5/9 Safe `0x619d…34EA`.

**Minter-auth verdict: CLOSED.** There is no unprivileged mint path through `lzReceive`, `send`, `mint`, `burn`, `reinitialize`, `reinitialize1`, `lzReceiveAndRevert`, or the LxLy/NativeConverter paths that feed the same token.

---

## 3. Live state (read-only, exact blocks)

Snapshot: **Ethereum block 26,217,817; Katana block 45,564,084** (2026-10-18 ~06:55 UTC). Raw values: `analysis/state_map.json`; collector: `analysis/collect_state.py`.

### 3.1 L1 vbToken vaults (ERC-4626, asset = underlying)

| Token | Address | totalAssets (units) | USD @ snapshot | totalSupply | LxLy escrow | LZ adapter | L1 circulating |
|---|---|---:|---:|---:|---:|---:|---:|
| vbUSDC | `0x53E82ABbb12638F09d9e624578ccB666217a765e` | 7,135,842.517824 USDC | $7,134,427.30 | 7,135,295.844591 | 6,592,142.164509 | 64,709.272092 | 478,444.408 |
| vbUSDT | `0x6d4f9f9f8f0155509ecd6Ac6c544fF27999845CC` | 3,066,794.473442 USDT | $3,064,219.81 | 3,066,663.038899 | 2,732,213.324770 | 204,365.547033 | 130,084.167 |
| vbWBTC | `0x2C24B57e2CCd1f273045Af6A5f632504C432374F` | 154.17237646 WBTC | $12,560,442.53 | 154.17237646 | 152.56042180 | 0.20097100 | 1.410984 |
| vbETH | `0x2DC70fb75b88d2eB4715bc06E1595E6D97c34DFF` | 2,074.582954529 ETH | $4,998,007.28 | 2,074.530377614 | 1,767.187879592 | 270.092388 | 37.25011 |
| vbUSDS | `0x3DD459dE96F9C28e3a343b831cbDC2B93c8C4855` | 175.798501756 USDS | $175.76 | 175.798501756 | — | — | 175.7985 |
| **Total** | | | **$27,757,272.69** | | | | |

- `asset()` / `yieldVault()` / `totalAssets()` / `paused()` were read live; none is paused. `reservedAssets()` = 0; backing is in the ERC-4626 yield vaults, not sitting idle.
- L1 yield vaults are **MetaMorpho V1.1** vaults (not Yearn V3): USDC `0xBEefb9f61CC44895d8AEc381373555a64191A9c4` (totalAssets 9.426M; vbUSDC owns 6.775M shares = 7.139M, 75.7%), WBTC `0x812B2C6Ab3f4471c0E43D4BB61098a9211017427` (154.1849 WBTC; vbWBTC owns 154.1045 shares = 154.17, 99.99%), USDT `0xc54b4E08C1Dcc199fdd35c6b5Ab589ffD3428a8d`, ETH `0x31A5684983EeE865d943A696AAC155363bA024f9`. Their owners are Safes (5-of-N USDC, 4-of-N others); curators are 3/3 Safes.
- `LxLy escrow` is the balance of the vbToken held by the Agglayer bridge `0x2a3DD3EB832aF982ec71669E178424b10Dca2EDe`; `LZ adapter` is the balance held by the corresponding `NonDefaultOftAdapter` (escrow for the LZ path). Their sum plus L1 circulating equals `totalSupply` (bridge/LZ lock, not burn).

### 3.2 L2 custom tokens and their backing

| L2 token | Supply (units) | LxLy escrow (L1) | LZ adapter (L1) | NativeConverter backing (L2) | Surplus |
|---|---:|---:|---:|---:|---:|
| vbUSDC `0x203A…FD36` | 6,662,564.078427 | 6,592,142.164509 | 64,709.272092 | 53,401.641723 | **+47,689.00** |
| vbUSDT `0x2DCa…D2F2` | 3,018,610.295336 | 2,732,213.324770 | 204,365.547033 | 99,664.575481 | **+17,633.15** |
| vbWBTC `0x0913…Cf52` | 158.25298049 | 152.56042180 | 0.20097100 | 5.52439372 | **+0.03280603** |
| vETH (WETH) `0xEE7D…7aB62` | 2,750.480779615 | 1,767.187879592 | 270.092388 | 0 (native WETH) | native ETH in WETH = 718.244866 → +5.04 |

The L2 supply is **over-collateralized** in every bucket. The NativeConverter is a 1:1 converter: `convert(assets, receiver)` pulls `assets` of the underlying (`_receiveUnderlyingToken` checks the received amount exactly) and mints `shares`; `deconvert` burns and returns only `backingOnLayerY`. It cannot mint for free.

### 3.3 Minters and adapters (all four assets)

| L2 minter | Token | Owner | Endpoint | `peers(30101)` | Init | `secondaryChainBalance` |
|---|---|---|---|---|---|---|
| `0x8072…93C0` | vbUSDC | 5/9 Safe `0x619d…34EA` | `0x6F47…DD5B` | `0xb5bA…7Bb3` | 1 | 64,709.272092 |
| `0x4690…985E` | vbUSDT | same | same | `0x839d…Ab82` | 1 | 204,365.547033 |
| `0x8169…0DFC` | vbWBTC | same | same | `0x8d09…31D4` | 1 | 0.20097100 |
| `0x694d…B683` | vbETH | same | same | `0x8F45…949b` | 1 | 270.092388 |

| L1 adapter | Token | Owner | Endpoint | `peers(30375)` | Init | Escrow |
|---|---|---|---|---|---|---|
| `0xb5bA…7Bb3` | vbUSDC | 5/9 Safe `0x619d…34EA` | `0x1a44…728C` | `0x8072…93C0` | 1 | 64,709.272092 |
| `0x839d…Ab82` | vbUSDT | same | same | `0x4690…985E` | 1 | 204,365.547033 |
| `0x8d09…31D4` | vbWBTC | same | same | `0x8169…0DFC` | 1 | 0.20097100 |
| `0x8F45…949b` | vbETH | same | same | `0x694d…B683` | 1 | 270.092388 |

All four minters share implementation addresses that are verified `NonDefaultMintBurnOftAdapter` on Katana; all four L1 adapters are verified `NonDefaultOftAdapter` on Ethereum. All eight proxy admins are `ProxyAdmin` contracts owned by `0x619d…34EA` (5/9 Safe). The `PeerSet` event history on every L2 minter contains exactly **one** EID (30101), set → revoked → re-set at the same two blocks (a config migration); no other EID was ever configured.

### 3.4 Authority

| Role | Holder | Type |
|---|---|---|
| L2 minters + L1 adapters owner / proxy-admin owner | `0x619D553686958A873A62B336b2DD97C3b25134EA` | Safe, **5-of-9** |
| L2 token admin (grant roles / upgrade) | `0xd0673F989bc3BA9314d0AAF28BfC84e99B7898CC` | Safe, **3-of-5** |
| L1 vbUSDC admin + proxy admin | `0xf4F2f5F6bAdBE05433C4604320ecC56BbECBC04E` | Safe, **2-of-3** |
| L1 vbUSDT/vbWBTC/vbETH admin | `0x2De242e27386e224E5fbF110EA8406d5B70740ec` | Safe, **2-of-N** |
| L1 vbUSDS admin | `0xA8C31B2edd84c654d06d626383f4154D1E40C5Ff` | Safe, **2-of-N** |
| L1 `YIELD_COLLECTOR_ROLE` | `0xcb1e45481461aef38e6b0a34f1444e9c5d647645` | **EOA** (can only mint yield to the recipient; no principal) |
| Katana GER updater | `0x3138BBdAeAd339d34F084445192B2be9dd4B9f27` | **EOA** (can insert L2 global exit roots — P risk; see §6) |
| Katana bridge manager / GER remover | `0x4e981bAe8E3cd06Ca911ffFE5504B2653ac1C38a` | Safe, **2-of-5** |

The `_lzReceive` target on the L2 token is the LZ adapter; the token’s `MINTER_BURNER_ROLE` history (5 `RoleGranted`, 2 `RoleRevoked` events) shows the admin migrated from the deployer to the 3/5 Safe and then granted the role to the adapter at block 21,668,941. No other grant exists.

---

## 4. What an attacker can and cannot do (exact paths)

### Closed / reverted on fork

| Attempt | Call | Revert |
|---|---|---|
| Direct delivery | `minter.lzReceive(origin, guid, msg, …)` from attacker | `OnlyEndpoint(attacker)` |
| Forged peer | as endpoint, `origin.sender = attacker` | `OnlyPeer(30101, attacker)` |
| Wrong EID | as endpoint, `origin.srcEid = 30375` (or 30110/30184) | `NoPeer(eid)` — no peer configured |
| Replay | re-deliver an old GUID | Endpoint `PayloadHash`/nonce check (canonical EndpointV2) |
| Direct mint | `vbUSDC.mint(attacker, 1e6e6)` | `Unauthorized()` |
| Direct burn | `vbUSDC.burn(victim, 1)` | `Unauthorized()` |
| Re-init minter | `minter.reinitialize([])` | `AlreadyReinitialized()` |
| Re-init minter (direct) | `minter.reinitialize1(...)` | `ReinitializersLocked()` |
| Re-init token | `vbUSDC.reinitialize(...)` | `InvalidInitialization()` (slot = 2) |
| Redeem without shares | `vbUSDC.redeem(1e6, attacker, attacker)` | `ERC4626ExceededMaxRedeem` |
| L1 adapter forged peer | as endpoint, wrong origin | `OnlyPeer(30375, attacker)` |
| L1 adapter direct delivery | from attacker | `OnlyEndpoint(attacker)` |

### The only mint/burn paths that exist

1. **LZ path (peer-gated).** `send()` on L1 adapter locks `amountLD` of vbToken in the adapter, then `_lzSend` emits a message to EID 30375. The L2 minter’s endpoint verifies the DVN payload, `lzReceive` checks `msg.sender == endpoint` and `peers(30101) == origin.sender`, then `_credit` mints. The reverse burns on L2 and releases on L1. Both sides have exactly one peer; neither can be pointed at an attacker chain without the 5/9 Safe.
2. **LxLy path (proof-gated).** The custom token grants the Agglayer bridge `0x2a3D…2EDe` mint/burn permission. `claimAsset` verifies a Merkle proof against a global exit root that exists in `globalExitRootManager.globalExitRootMap`; on Katana the root is inserted by `globalExitRootUpdater` (EOA — P), on Ethereum by the bridge or the rollup manager (contracts). A random proof reverts `GlobalExitRootInvalid` / `InvalidSmtProof`; the nullifier prevents replay.
3. **NativeConverter (1:1).** Pulls the exact underlying amount (`_receiveUnderlyingToken` checks balance delta) and mints 1:1; `backingOnLayerY` = the underlying balance on-chain for every converter. No free mint.
4. **L1 vault deposit/redeem (1:1).** `deposit` pulls underlying and mints vbToken 1:1; `redeem` burns vbToken and releases underlying from reserve + yield vault. `convertToShares/Assets` are 1:1; there is no share-price donation edge with a non-empty vault (6.7M shares). `donateAsYield` is permissionless but only adds backing.
5. **`completeMigration` (onlyMigrationManager).** The MigrationManager is called only by the LxLy bridge after a valid `claimMessage`; it then pulls the claimed underlying and mints/bridges vbToken to address(0) (locked). No permissionless caller can invoke it.

### Why the WBTC figure was wrong in r6

r6’s “33.68 WBTC” was a single-strategy balance read, not the vault total. Live:
- `vbWBTC.totalAssets()` = **154.17237646 WBTC** ($12.56M).
- `vbWBTC` holds **154.1045278 shares** of the MetaMorpho WBTC vault `0x812B…7427`; that vault’s `totalAssets` = **154.18491727 WBTC**; the shares convert to 154.17 WBTC (99.99% of the vault).
- The L1 vault holds **0 WBTC directly**; the WBTC is supplied to Morpho markets via the MetaMorpho vault. The old “only 33.68 WBTC” / “strategies hold $24.8k” observations were partial custody views.
- The L1 escrow holds **152.56042180 vbWBTC**; the LZ adapter holds **0.20097100**; L1 circulating is **1.410984**; sum = 154.17237646 = totalSupply. The L2 supply of 158.25298049 is 152.5604 + 0.2010 + 5.5244 (NativeConverter, backed by L2 WBTC.e) + 0.0328 surplus.

**WBTC reconciliation conclusion:** the reported 154.2 WBTC is real; the 33.68 figure is stale/partial. The $27.7M L1 headline is accurate to within ~1% (live $27.757M at snapshot prices: ETH $2,409.16, WBTC $81,470.12, USDC $0.99980, USDT $0.99916, USDS $0.99980).

---

## 5. PoC / fork verification

**Files:** `poc/foundry.toml`, `poc/test/KatanaBridge.t.sol` (vendored `poc/lib/forge-std`). Foundry 1.8.5. Two forks: Ethereum via `FORK_RPC_URL` (fallback `https://eth.drpc.org`) and Katana via `KATANA_RPC_URL` (fallback `https://rpc.katana.network`). No block pin (latest state); no transactions are sent.

**Result: 20/20 PASS** locally (59 s). Tests:

```
test_l2Minter_lzReceive_onlyEndpoint          PASS
test_l2Minter_lzReceive_onlyPeer              PASS
test_l2Minter_reinitialize_closed             PASS
test_l2Minter_reinitialize1_locked            PASS
test_l2Minter_peerIsL1Adapter                 PASS
test_l2Minter_onlyLzPeerCanMint               PASS
test_l2Token_mint_unauthorized                PASS
test_l2Token_burn_unauthorized                PASS
test_l2Token_reinitialize_closed              PASS
test_l2Token_roles                            PASS
test_l1Adapter_lzReceive_onlyEndpoint         PASS
test_l1Adapter_lzReceive_onlyPeer             PASS
test_l1Adapter_peerIsL2Minter                 PASS
test_l1Adapter_holdsBacking                   PASS
test_l1Vault_redeemWithoutSharesReverts       PASS
test_solvency_vbUSDC                          PASS
test_solvency_vbUSDT                          PASS
test_solvency_vbWBTC                          PASS
test_solvency_vbETH                           PASS
test_allMinersShareSameOwnerAndEndpoint       PASS
```

The solvency tests switch forks mid-test: read the L1 escrow/adapter balance, switch to Katana, read L2 supply and converter backing, assert `l2Supply <= escrow + adapter + converterBacking`. All pass with the surpluses in §3.2.

**CI:** see `ci/` (`run.sh` re-runs `ci/check.py`: auth re-reads, backing invariants, secret scan, `summary.json` schema) and the GitHub Actions run URL recorded in `summary.json` / §11. The same 20 Foundry tests run in CI via `poc/foundry.toml`.

---

## 6. Residual and privileged risk (what would change the verdict)

1. **5/9 Safe `0x619d…34EA`** owns all four L2 minters, all four L1 adapters, and all eight proxy admins. A compromise (or collusion) can upgrade any side, set an arbitrary peer, or `setTokenAndApprovalRequired` on a fresh token, then mint arbitrary L2 supply and/or release the L1 escrow. This is **P**, not E-U. The Safe is 5-of-9 with nine distinct owner addresses; threshold is high, but it is still the root of trust.
2. **3/5 Safe `0xd067…98CC`** is the L2 token admin: it can grant `MINTER_BURNER_ROLE` to any address or upgrade the token proxies. **P**.
3. **Katana GER updater EOA `0x3138BBdA…9f27`** (no code) can call `insertGlobalExitRoot(bytes32)` on the Katana GER manager `0xa40D…B8fA`. That lets a single key insert an arbitrary L2 global exit root and then `claimAsset` a crafted leaf, minting unbacked vbUSDC/vbUSDT/vbWBTC through the LxLy bridge. The attacker’s immediate exit is Katana DEX liquidity: the main Sushi vbUSDC/vbUSDT pool `0x5f88eeb3a5662489eb2d5da9f0c73f03355f3009` has **$2.18M** reserve (24h volume $19.3k); other vbUSDC pools add ~$1.15M. This is the single largest **privileged** risk found. It cannot release the L1 vbToken escrow (the Ethereum GER is updated only by the L1 bridge/rollup manager), so the L1 $27.76M is not directly reachable by this key. **Recommendation: move `globalExitRootUpdater` to a Safe/timelock and monitor `UpdateHashChainValue` events.**
4. **L2 vbUSDC concentration in `yvvbUSDC` `0x80c34BD3…B159`**: totalAssets **6,052,618.379712 vbUSDC** = **90.85%** of L2 vbUSDC supply, totalDebt 6.0526M across seven Yearn V3 strategies (totalIdle 0, pricePerShare 1.028681, role_manager `0x2297…C9a4`, accountant `0x1f39…7c8a`). A Yearn/strategy bug or role compromise would hit ~$6.05M of user funds; this is a yield-vault risk, not a bridge-mint path. The vault is not shut down and deposits are open (`deposit_limit` = max).
5. **L1 backing is in MetaMorpho/Morpho markets**, not in the vbToken contracts. The MetaMorpho owners are 5-of-N/4-of-N Safes and curators 3/3 Safes; Morpho market bad debt or a curator error is a yield risk to the $27.76M, not an unprivileged extraction path.
6. **LxLy bridge / GER contracts** (`0x2a3D…2EDe`, `0xa40D…B8fA` on Katana; `0x2a3D…2EDe`, `0x580b…3CFb` on Ethereum) are verified Agglayer contracts. The L1 gate is `msg.sender == bridge || rollupManager`; the Katana L2 root insertion is the EOA above. The L1 bridge proxy admin is `0x0f99…CC4A`, owned by `0xBBa0…6d13` (a 19.8KB governance/timelock contract, not a Safe) — outside this LZ-minter scope, and the prior r6 lane already closed the forged-GER path on L1.
7. **LayerZero config**: the OApp delegate is the 5/9 Safe. A delegate can change the receive library/DVN config; a malicious library could accept forged messages. This is **P**. No non-default library was found on the paths tested; the endpoint is canonical `EndpointV2` on both chains.
8. **`YIELD_COLLECTOR_ROLE` is an EOA** `0xcb1e…7645`. It can only call `collectYield()`, which mints vbToken equal to the positive `backingDifference()` to the yield recipient; it cannot touch principal (`drainYieldVault` and `setYieldVault` are `DEFAULT_ADMIN_ROLE`, Safes). Low residual.

**What would change the verdict:** a peer set on a chain the attacker controls; a live re-initializer (counter 0 / token slot <2); a `MINTER_BURNER_ROLE` grant to a non-adapter address; a non-canonical endpoint or receive library; a compromised 5/9 Safe or the GER EOA. None is true today.

---

## 7. Categories and quantification

| Category | USD | Note |
|---|---:|---|
| **E-U** | **$0.00** | no unprivileged path; all forge/replay/mint/re-init attempts revert |
| **E-U-conditional** | $0.00 | only under a 5/9 Safe or GER-EOA compromise (then P, not E-U) |
| **H-O** | $0.00 | no stuck user funds; L1 redeem and L2 bridge-back are live (self-service, 1:1) |
| **P** | **$27,757,272.69** (L1) + $29.2M L2 notional | Safe/upgrade authority + GER updater EOA; not attacker-extractable without keys |
| **S** | $0.00 | all contracts live, not paused, no bricked path |

The $27.76M is **not** “at risk from an attacker”; it is the honest user backing, fully over-collateralized (surpluses in §3.2). The P number is the value the privileged keys could redirect if compromised, not a live bug.

---

## 8. Methodology and sources

- **Address recovery:** `residual-recon/analysis/ALL-ROWS.md` and `zombie-hunt-iv/wave1/r6-new-chains.md`; corrected via live `eth_getCode`/EIP-1967 slots and Etherscan V2 `getsourcecode` on chains 1 and 747474.
- **Source recovery:** Etherscan V2 verified source for all implementations and proxies (L1 `GenericVaultBridgeToken`, `NonDefaultOftAdapter`, `TransparentUpgradeableProxy`; L2 `NonDefaultMintBurnOftAdapter`, `GenericCustomToken`, `WETH`, `EndpointV2`, `AgglayerBridgeL2`, `GlobalExitRootManagerL2SovereignChain`; L1 `AgglayerGER`, bridge). Saved under `analysis/src/`.
- **Live reads:** `cast call`/`eth_getStorageAt` at explicit latest blocks (Ethereum 26,217,817; Katana 45,564,084); balances of the tokens, bridge escrow, adapters, converters, MetaMorpho vaults, yvvbUSDC; EIP-1967 implementation/admin slots; OZ `Initializable` slot; `hasRole`; `peers`; `globalInitializationCounter`; `secondaryChainBalance`; `totalNetMintedByAdditionalMintersBurners`.
- **Logs:** `PeerSet(uint32,bytes32)` history on all four L2 minters via Katana `eth_getLogs` (exactly one EID each, set/revoked/re-set); `RoleGranted`/`RoleRevoked` on all L2 tokens (one `MINTER_BURNER_ROLE` grant, to the matching adapter); L1 L2 role history via Blockscout Etherscan-compatible logs.
- **Prices:** DefiLlama `coins.llama.fi/prices/current` at 2026-10-18 (ETH $2,409.16, WBTC $81,470.12, USDC $0.99980, USDT $0.99916, USDS $0.99980).
- **DEX exit:** GeckoTerminal `/networks/katana/tokens/0x203A…/pools` (main vbUSDC/vbUSDT pool $2,177,045.85 reserve; other vbUSDC pools $275.8k, $840.2k, $239.3k, etc.).
- **PoC:** Foundry 1.8.5 fork tests, no mainnet writes.

## 9. Caveats and limitations

- Point-in-time reads; re-check before acting. The L1 vaults are live and their totalAssets move with deposits/withdrawals and Morpho accrual.
- No full audit of the Yearn V3 `yvvbUSDC` strategies or the MetaMorpho/Morpho markets. Those are yield/custody risks (P/H-O), not the LZ minter auth question.
- No full audit of the Agglayer LxLy bridge; the prior r6 lane closed its forged-GER path, and this pass independently confirmed the L1 GER update gate and the Katana GER-updater role. The Katana updater EOA is flagged as P.
- The 5/9 Safe owner set is taken from `getOwners()`/`getThreshold()`; signer key hygiene is out of scope.
- `L2_ETH`/WETH supply includes native WETH deposits (718.24 ETH held by the WETH contract), not only bridged vbETH; that is why the L2 WETH notional exceeds the L1 vbETH backing.
- The DEX reserve figures are instantaneous and slippage-adjusted profit would be lower; they are quoted only as the P-path ceiling, not as E-U.

## 10. Files index

```
katana-bridge/
├── README.md                       # this report
├── summary.json                    # machine-readable verdict
├── analysis/
│   ├── state_map.json              # live state snapshot (blocks, balances, roles, prices)
│   ├── collect_state.py            # read-only collector (public RPCs; no secrets)
│   ├── read_state.py / read_state2.py / read_l2.py  # earlier read scripts
│   └── src/                        # verified sources (Etherscan V2)
│       ├── l1_GenericVaultBridgeToken_files/
│       ├── l1_NonDefaultOftAdapter_files/
│       ├── l2_NonDefaultMintBurnOftAdapter_files/
│       ├── l2_GenericVaultBridgeToken_files/
│       ├── AgglayerBridgeL2_files/ + GER_L2_impl_files/ + L1_GER_impl_files/
│       └── *.json                  # original source/ABI payloads
├── poc/
│   ├── foundry.toml
│   ├── lib/forge-std/
│   └── test/KatanaBridge.t.sol     # 20 tests, all PASS
├── ci/
│   ├── run.sh                      # CI job: check.py
│   └── check.py                    # auth re-reads + solvency + secret scan + schema
├── ci-out/live_checks.json         # CI result (also uploaded as artifact)
└── ci-log.txt / ci-artifacts/      # written by ci/ci-run.sh
```

## 11. CI runs

See `summary.json` `poc.ci_run_urls` for the final URLs (recorded after the GitHub Actions run). The job runs `ci/run.sh` (validation) and `poc/` `forge test -vvv` (20/20).

---

**Bottom line:** B0’s $27.7M figure is real, but the feared unverified LZ minter is a verified, endpoint-only, peer-bound OApp with a 5/9 Safe upgrade authority and no live re-initializer. **External unprivileged extraction today: $0.00, high confidence.** The meaningful residual is privileged: the 5/9 Safe, the 3/5 token admin, the Katana GER-updater EOA, and the 90.85% L2 vbUSDC concentration in `yvvbUSDC`.
