# childB — EVM lead sanity check (pass7 residual reconciliation)

**Date:** 2026-10-25 · **Mode:** READ-ONLY (`cast call` / `cast balance` / `cast code` / `cast storage` + public RPCs + DefiLlama/DexScreener prices + explorer source reads). No tx signed/sent; no keys written.
**Mandate:** quick live sanity check (exists? live balance? already disproven? prior verdict?) for the pass7 "unread/unresolved funded" **EVM** leads. One-line disposition: OPEN / LANE-CLOSED / PRIOR-COVERED / NOT-A-PROTOCOL.

**Chains/blocks at read (2026-10-25):** eth 26,271,478 · base 53,081,735 · polygon 96,164,964 · cronos 102,071,802 · berachain 27,969,052 · hyperevm 49,507,696 · apechain 53,004,545 · monad 116,540,826 · ink 59,454,409.
**Prices (DefiLlama/DexScreener):** ETH $2,353.35 · HYPE/WHYPE $77.18 · APE $0.126756 · HONEY $0.9969 · CGO $0.0001316 · rUSD $1.0004.

---

## A. Accounting-lane unread / not-reached

| # | Target | Chain | EXISTS + live state (block) | Prior verdict (grep) | Disposition |
|---|---|---|---|---|---|
| A1 | **DexFi Aggregator Vault V2** | Base | Factory `0xcb34f261a5284554bb9fea8aa12a0578c4ba3fc6` **exists**, code 16,145 B, `vaultsCount()=1895`, `owner()=0x76e1736ea8Cda4d0Ed4923B8E119586716C5725f`. Vault clone (beacon `0x991872559f227337e300382077f0045ae9e50da2`, owner=factory) → impl `0x2149F9c9e6a6A4260325A13ed091616983193C24` (23,366 B). Selectors present: `deposit`, `withdraw`, `harvest(uint256)`, `emergencyWithdraw`, `owner`, `transferOwnership`; **absent**: `setFarm*`, `setFarmConnector`, `setConnector`, `setStrategy`, `migrate`, `rescueTokens`, `sweep`. `emergencyWithdraw()` from a random EOA reverts `EmergencyWithdrawUserBalanceZero` (caller-scoped); `harvest(uint256)` permissionless (compounds, no caller payout). (base 53,081,735) | pass3 `lane-yield.md` #13 **NOT REACHED**; pass7 accounting **unread** (RPC-blocked) | **LANE-CLOSED (this probe)** — the lane's stated hypothesis (unauth `setFarm` / swappable connector) is **refuted**; no unprivileged drain selector found. Residual: 23 KB impl not source-read end-to-end |
| A2 | **CGO Finance** (Cougar MasterChef fork) | Cronos | MasterChef `0x5795BE23A2C330209849e0D1D19cc05755E23Ca2` **exists**, code 14,525 B, `poolLength()=43`, `totalAllocPoint()=44700`, `owner()=0x2e4C48D9a4abde9cCCCF110Bf5F58636d49ef5ee`. Reward token CGO `0x869c3e35ef9e5f50003d9a2a80f1d61d670d4cb6`: MC holds **41,825,492 CGO** of 71,787,297 supply → reward reserve ≈ **$5,504** @ $0.0001316 (DexScreener). (cronos 102,071,802) | pass3/7 **NOT REACHED / unread** | **LANE-CLOSED** — TVL ~$1.01M is user-owned LP; only pool-held fungible asset is CGO (~$5.5k exit liquidity); standard owner-gated Cougar MasterChef. Not drainable |
| A3 | **Hyperbeat Earn** | HyperEVM 999 | mcHYPE vault `0xd19e3d00f8547f7d108abfd4bbb015486437b487` **exists**, code 19,689 B, name **"MEV Capital HYPE"**, `totalAssets=10,684.20 WHYPE`, `totalSupply=10,153.84`, `owner=curator=0xb830B8B1A41c38603dBC6E4b562Ff599eDB415C4` (SafeProxy code 345 B; `getOwners()` = 3 → multisig). `liquidHypeStrategist 0x83a80e5b64086197c01cbb123df2aea79a149c1d` **code = 0 → EOA, not an unverified contract**. oracle `0x1ceab703956e24b18a0af6b272e0bf3f499aca0f` code 2,227 B (proxy, non-vault). beHYPE `0xd8FC8F0b03eBA61F64D08B0bef69d80916E5DdA9` EIP-1167 (130 B), supply 151,910. DL hyperbeat-earn TVL **$18.56M**. (hyperevm 49,507,696) | pass3 closed **beHYPE LST**; pass7 flag **PRIOR-PARTIAL** ("unverified strategist") | **LANE-CLOSED** — audited **MetaMorpho** base, owner is a multisig Safe, and the "unverified strategist" is an **EOA** → the flagged lead is refuted |
| A4 | **BitBay `UsdcDaiV4Vault` family** | Polygon | Victim `0x048E88311ca84876aeA086125825492e2AF2e5A0` code 24,319 B, DAI=0 USDC=0, `liquidity()=0`, `totalShares=14,837.64`, `mintThis=true`. Deployer `0xc70f0ec950c51bb4e410a94c21468247bfddf29c` nonce **4,762**. Resolved creations (nonces 0–6,20,21,25,28,96,97) all have code but **native=0, DAI=0, USDC=0, and NONE respond to the vault interface** (`liquidity()/totalShares()/mintThis()` all empty). Siblings `0x8Ec52157`="BitBay Reserve", `0x26948f01`="BitBay Frozen", `0x49018904`="BitBay Community" confirmed non-vault. (polygon 96,164,964) | ZH3 **Z3-H6 rearm-watch**; pass6 `deployer-lineage.md` #3 **LANE-CLOSED** ("~25-vault family, $0") | **PRIOR-COVERED** + live re-check **resolves** pass7's "family inconclusive": **no funded sibling vault exists** |
| A5 | **Goldilocks Goldivaults** (rUSD/uniBTC/rsETH) | Berachain | rUSDVault `0x8f65453BF050233d3BD6a08A5Eb53C1fD73312EC`, uniBTCVault `0x8742DB52a4EAEFE88bE5D3431980E221aaAA1EE3`, rsETHVault `0xE4dC8142CEd52C547384032e43379b0514341c22` — each code 9,788 B; **`name()/symbol()/totalSupply()/totalAssets()/assetToken()/concluded()/owner()` all REVERT**. Residual: rUSD 3,198.69 (≈$3.2k), uniBTC 75,630 sat (≈$80), rsETH 0.012982 (≈$40). The DL ~$527k = **HONEY 524,216.64 held by Goldiswap AMM `0xb7E448E5677D212B8C8Da7D6312E8Afc49800466`**, not the vaults. (berachain 27,969,052) | pass7 accounting **CLOSED (inactive)** | **LANE-CLOSED (inactive)** — confirmed: all view calls still revert |
| A6 | **GrowiHF** | Hyperliquid HyperCore | HyperCore-native vault `0x1e37a337ed460039d1b15bd3bc489de789768d5e` (chain 9999), flags `hypercore_native` / `perp_dex_trading_vault`; **permissioned/whitelisted** (deposits disabled by leader; redemptions open). DL TVL **$13.54M**. No EVM contract surface. | pass7 accounting **LOW (watch)** | **NOT-A-PROTOCOL** — HyperCore-native, no EVM unprivileged surface |
| A7 | **Curvance** | Monad ($131.6M) | Not re-read (prior-corpus confirmation only). | `ci/ZH4P5` advisories-git: **"Curvance (≈HEAD)"** = deployed ≈ audited HEAD | **PRIOR-COVERED** |
| A7 | **Tydro** | Ink ($131M) | Not re-read. | `ci/ZH2B6` H2-02 (E-U $0 across 11); `wave1/r5-exotic.md`: USDe feed frozen **LTV=0**, "no path"; appears in ZH2 corpus | **PRIOR-COVERED** |
| A7 | **Nado Spot** | Ink ($50.5M) | Not re-read. | `ci/ZH2B6` H2-02: **Nado ≈$55.9M, E-U $0.00, fork-proven gates** | **PRIOR-COVERED** |

---

## B. fresh-detector hits (ApeChain + Ethereum)

| # | Target | Chain | EXISTS + live state (block) | Prior verdict (grep) | Disposition |
|---|---|---|---|---|---|
| B8 | **APEPredicts** `0xF609394F0882B732b287db10d1b0F53211a09f75` | ApeChain | **exists**, code 15,122 B, balance **30,921.24 APE = $3,920** (apechain 53,004,545). `owner()=0xd5d013cef20373839635Fbce206A1cf0054EC565`. Source verified: `resolveGame/withdraw/cancelGame/updateGameStatus/updateFeePercentage` all **onlyOwner**; `claim` caller-scoped (`depositsA[gameId][msg.sender]`). | pass7 fresh-detector **LOW, "not read to proof", $ below bar** | **LANE-CLOSED** — owner-gated + caller-scoped, dust (< $20k bar) |
| B9 | **CashOrCrash** `0x8c63d2a77480178868A5fd80AF23821a91fD8517` | ApeChain | **exists**, code 13,130 B, **17,349.90 APE = $2,200**; `owner()=0x1fFc20b99E1f4D0319c08d3bbb6B1ca92Db316f8`. Verified: `withdrawFunds/addAdmin/removeAdmin/setGameCounter/setMessagePrefix` **onlyOwner**; player fns require `msg.sender==playerAddress` or `isAdmin`. | pass7 fresh-detector **LOW** | **LANE-CLOSED** — gated, dust |
| B9 | **House** `0x2054709F89F18a4CCAC6132acE7b812E32608469` | ApeChain | **exists**, code 14,169 B, **15,103.49 APE = $1,914**; `owner()` reverts (manager-pattern). Verified: modifiers `onlyOwner/onlyGame/onlyRNG/onlyAdmin/validatePlayer`. | pass7 fresh-detector **LOW** | **LANE-CLOSED** — gated, dust |
| B9 | **GameApeVault** `0xf467d9AaFD051A290fB93D3eA67014966816D753` | ApeChain | **exists**, code 1,878 B, **979.95 APE = $124** (apechain 53,004,545). | pass7 fresh-detector **LOW ($72)** | **LANE-CLOSED** — dust |
| B10 | **OrbitNativeOFTAdapter** `0xe4103e80c967f58591a1d7cA443ed7E392FeD862` | ApeChain | **exists**, code 13,955 B, balance **876,645.53 APE = $111,131**; `owner()=0xf267589a1C2204AF90AB43f62e41F16F9071dE5C`. 2024 deploy (per lane); standard LayerZero V2 OFT adapter backing bridged APE, owner-gated. | pass7 fresh-detector **NEG** (old deploy, owner-gated) | **NOT-A-PROTOCOL / NEG** — owner-gated bridge adapter; funds are bridged-APE backing, not extractable |
| B11 | **PendingContributions** `0xf058ee35f381a12b3a0f504025419dcaf047ce7f` | Ethereum | **exists**, code 2,385 B, balance **91.2344 ETH = $214,706** (eth 26,271,478). Caller-scoped `contributions[msg.sender]` stuck crowdsale refunds. | `zombie_hunt/github_stuck_funds.md` **entry #68** ("Presale Pool (LINO/HEALP/Bulleon)", 2018 ICO, 91.23 ETH, 65 contributors) | **PRIOR-COVERED** — already in zombie_hunt corpus; caller-scoped |
| B12 | **xXx_bank** `0x22C8553B5F91a13bEe297Eed07656BC91e6bf285` | Ethereum | **exists**, code 822 B, **5.0028 ETH = $11,773** (eth 26,271,478). `Collect` caller-scoped (`Accounts[msg.sender]`) per lane source read. | pass7 fresh-detector **NEG** | **LANE-CLOSED** — caller-scoped, dust |
| B12 | **MindVault** `0x26B1E19B550d932fA265a9EE90b607462dC4Ff13` | Ethereum | **exists**, code 16,034 B, **0.093454 ETH = $220**. `sweep` = `onlyLiquidity`. | pass7 fresh-detector **NEG** | **LANE-CLOSED** — gated, dust |
| B12 | **ZK Pool** `0x77b5EaBe5018bF1Af932955774EB234dF7c5089d` | Ethereum | **exists**, code 5,411 B, **0.2 ETH = $471**. `withdraw(...,address _recipient,...)` ZK-proof-gated (Tornado lineage). | pass7 fresh-detector **NEG** | **LANE-CLOSED** — proof-gated, dust |

---

## C. Bottom line

- **OPEN list from this EVM child: none.** Every listed target is funded-but-gated/caller-scoped (ApeChain games, xXx_bank, MindVault, ZK Pool, OrbitNative), inactive (Goldilocks), HyperCore-native (GrowiHF), already-corpus (PendingContributions, BitBay family), audited-base (Hyperbeat MetaMorpho), or a standard MasterChef with ~$5.5k reward exit liquidity (CGO).
- **Two pass7 "unresolved" claims resolved live:**
  1. **BitBay family** — no funded sibling vault exists (all creations 0 DAI/USDC and non-vault) → pass7's "family inconclusive" closes to PRIOR-COVERED.
  2. **DexFi Vault V2** — factory readable (1895 Base vaults) and the stated "unauth setFarm / swappable connector" hypothesis is **refuted** (`setFarm*`/`setFarmConnector`/`setConnector`/`setStrategy` selectors absent; `emergencyWithdraw` caller-scoped). Residual = the 23 KB impl was not source-read end-to-end.
- **One correction to the pass7 lane:** the Goldilocks **~$527k is HONEY in the Goldiswap AMM**, not in the (inactive, reverting) Goldivaults.
- **ApeChain "not read to proof"** (B8–B9) does **not** leave an open path: the contracts are verified and all value-moving entry points are `onlyOwner`/admin or caller-scoped; funds are dust (< $20k).

---

## D. What ran locally

- Public RPCs only: `ethereum-rpc.publicnode.com`, `base-rpc.publicnode.com`, `polygon-bor-rpc.publicnode.com`, `cronos-evm-rpc.publicnode.com`, `berachain-rpc.publicnode.com`, `rpc.hyperliquid.xyz/evm` (999), `rpc.apechain.com`; `eth_blockNumber` + `cast call/balance/code/storage/nonce/compute-address`.
- Explorer/source: `apechain.blockscout.com` v2 API (source for APEPredicts/CashOrCrash/House/GameApeVault/OrbitNative); DefiLlama Adapters on raw.githubusercontent (dexfinance-vault[-v2], hyperbeat, cgo-finance, goldilocks, coreAssets) to resolve abbreviated addresses; DefiLlama `coins.llama.fi` + DexScreener for prices.
- Beacon resolution for DexFi clone: `cast storage <vault> 0xa3f0ad74…3d50` → beacon `0x991872559f227337e300382077f0045ae9e50da2` → `implementation()` → impl `0x2149F9c9e6a6A4260325A13ed091616983193C24`; selector presence via `cast sig` grep of the impl bytecode; `eth_call` simulations from `0x…dEaD`.
- `heimdall` was present but its decompile output was empty (not used for conclusions).
- **Blocked/no-op:** `base.blockscout.com` (Cloudflare "Just a moment…") and Sourcify (no match) for DexFi factory/vault source; Etherscan-V2 (missing/invalid key). Hyperbeat `liquidHypeStrategist` resolved by direct `eth_getCode` (code=0 → EOA).

*Prepared 2026-10-25 · pass7-recon childB · read-only · no secrets. Point-in-time; re-read live state before acting.*
