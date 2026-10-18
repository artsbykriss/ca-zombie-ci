# ZH4 — Enosys AMM V3 (Flare + Songbird): $6.79M UniV3 fork, **$0 external-unprivileged extraction**

**Date:** 2026-10-18 · **Chains:** Flare (14), Songbird (19) · **Blocks:** Flare **72,386,299** (TVL), **72,386,500** (security tests), **72,386,707** (final state); Songbird **135,684,340** (TVL), **135,684,743** (final state)
**Status:** read-only. No transactions signed or sent, no keys, no mainnet writes. Every read is from a keyless public RPC or a public explorer API.

---

## TL;DR

| Question | Answer |
|---|---|
| **What is it?** | Enosys AMM V3, a Uniswap V3 fork on Flare and Songbird. Factories, position managers and **every pool are upgradeable TransparentUpgradeableProxy** contracts; pools add per-epoch fee/liquidity snapshots and WNat/FTSO delegation hooks. |
| **Live nominal TVL** | DefiLlama **$6,793,213** (Flare $6,730,975 + Songbird $62,238). On-chain mark: **Flare $6,728,825** at block 72,386,299 (DL −0.03%); Songbird **$62,238 DL / $144,051 local DEX mark** (price-source divergence); total **$6.79M–$6.87M**. |
| **External-unprivileged extractable today (E-U)** | **$0.00** — high confidence. No path to move pool principal, mint unbacked liquidity, collect another owner's position, spoof a callback, change fees/implementation, or forge reward snapshots. |
| **Mechanism reviewed** | 168 pools (106 Flare + 62 Songbird), $6.73M Flare + $62k–$144k Songbird. Core Uniswap V3 math is source-identical. The fork changes are upgradeability, historical snapshots, WNat delegation, and a permissionless protocol-fee collector with a **fixed** recipient. |
| **Gates live-tested** | `mint`/`swap`/`flash` without payment **revert**; NPM `collect`/`burn` from a non-owner revert `Not approved`; pool `collectProtocol`/`setFeeProtocol`/`resetupDelegations` revert `NA`; factory admin functions revert owner/governor errors; tracker writes revert `missing role`; FTSO/Monthly claims revert `NotNftOwner`. |
| **Biggest residual risk** | The **2-of-6 Safe** (not 4/6 as the docs claim) is owner/governor of both factories and can upgrade every pool. This is a privileged (P) risk over the full TVL, **not** an E-U path. |
| **Confidence** | **High** on the negative and on the live TVL. **Medium** on the exact current pool/factory source because those implementations are unverified; the verified predecessor differs only in an internal snapshot region, and all fund-moving paths were tested live. |
| **PoC** | `poc/test/EnosysNegativePoC.t.sol` (9 tests) + `poc/run.sh`; written, not run locally per campaign instructions. Expected 9/9 pass. |

**Verdict:** Enosys V3 is a live, materially-funded UniV3 fork with substantial custom code (upgradeable pools, history tracking, FTSO delegation), but the canonical payment, position-authorization, protocol-fee and role gates are intact. I found **no external unprivileged value-extraction path today: E-U = $0**.

---

## 1. Target map and live state

### Flare (chain 14, block 72,386,707)

| Item | Value |
|---|---|
| Factory proxy | [`0x17AA157AC8C54034381b840Cb8f6bf7Fc355f0de`](https://flare-explorer.flare.network/address/0x17AA157AC8C54034381b840Cb8f6bf7Fc355f0de) — 2,227 B, codehash `e518057e…` |
| Factory implementation | `0xD835919c035ccD8AE295c43be4277aa3002d5E2c` — 16,767 B, sha256 `355d4d00…` (unverified; opcode-identical to Songbird impl) |
| Factory EIP-1967 admin | `0xcE22c2af6839ea3702DF1A5D3167F5a8d71E9d35` (ProxyAdmin, owner = Safe) |
| Pools proxy admin | `0xAb856c28Ea2259Ce171FCF6560d8C0AEA9F42cec` (owner = factory) |
| Owner / governor | **Safe `0xdedda08961216adb9ca09b88986d110127b24270`** (Safe 1.3.0, threshold **2 of 6**, no modules, no guard) |
| Protocol fee / receiver | `protocolFee = 5` (0x55 on pools); receiver = ProfitDistribution `0x36794833ae009368fdFb9736216F1160B9d1cBbE` |
| NPM proxy | [`0xD9770b1C7A6ccd33C75b5bcB1c0078f46bE46657`](https://flare-explorer.flare.network/address/0xD9770b1C7A6ccd33C75b5bcB1c0078f46bE46657) — 2,227 B |
| NPM implementation | `0x0714C223Cee8B138CCEd16E10FbF452b9178b416` — 24,552 B; verified current source on Songbird (`0xb126…`); opcode-identical across chains |
| Pool implementation | `0x23f02a41DEa4fE6180b8E4aA56a745Ea1bA4A88e` — 24,204 B (unverified; opcode-identical to Songbird `0xfcba…`) |
| Epoch / block trackers | `0x5646f8f757ed7238f28ae930ab7e1d806413df36` / `0x46d99cf15f21a2a16fd2c70fc5412044506a8b30` |
| FTSO / monthly redistributors | `0x5a0BfF8Ff1AF1DF28619Fce57d07E3bBb7BAF3d7` (517,379.66 WFLR) / `0xef514BCC4ab6226f5666a30d0c4672f00946e3dD` (690,313.87 WFLR) |
| WNat registry | `0x3BaC97Fab1AEcA6815DB4464CaA9B2a7E0cFd220` |
| RewardManager | `0x38B542B05198aE2c8A16520B9f8A208b6552B77a` — APS, epochs 1031–1211, 1.955 APS left |
| Pools | **106** (all factory/token/fee/tickSpacing/getPool/isPoolDeployedByFactory consistent) |

### Songbird (chain 19, block 135,684,743)

| Item | Value |
|---|---|
| Factory proxy | `0x416F1CcBc55033Ae0133DA96F9096Fe8c2c17E7d` — 2,227 B |
| Factory implementation | `0xf0DE831540c7210376F6F7E798c694dEd99851fc` — 16,767 B (unverified; opcode-identical to Flare) |
| Factory EIP-1967 admin | `0x3aa48b3127E3E05d2871576087d81d53E840B499` (ProxyAdmin, owner = Safe) |
| Pools proxy admin | `0x56035A7Ec075e45830311e550a56a261009FA2c4` (owner = factory) |
| Owner / governor | **Safe `0x68d0818bb30b340ad99994592a88a3095e47522f`** (Safe 1.3.0, threshold **2 of 6**, no modules) |
| Protocol fee / receiver | `protocolFee = 5`; receiver = ProfitDistribution `0x16bfB7Db0b4208dc72B918849108e56714430D58` |
| NPM proxy / impl | `0xFC02eB1Ab5079627103357BfbB8167d3BBAc6f1e` / `0xb126C5Cd58D01896e6aa6025Fd9e2b4c62E78a6d` (24,552 B, **verified current source**) |
| Pool implementation | `0xfcba59D9F160BB8F26c0F1918d2AEaa74Ca3e3A6` — 24,204 B |
| Epoch / block trackers | `0x8f74604c944c30c92f1f5227b1fdde05e701b1c4` / `0x3f19c2ca8ba4f2e4942cb9d937f554c7a6051580` |
| FTSO / monthly | `0x421294D3eb38c87390fc7f1442623f5b7DBc5b86` (FTSO; monthly is the same address) — 490,920.09 WSGB |
| WNat registry | `0x1E3838C5Dc72B9a4f1D76E414e609652594d6096` |
| RewardManager | `0xa997E5FDd464b982d1Fbe51D8734A410744F3B7E` — SFIN, epochs 2069–2470, 13.763 SFIN left |
| Pools | **62** (all consistent) |

**Pool map:** all 168 pools are EIP-1967 proxies to the same per-chain implementation, `factory()` equals the factory, `getPool(token0,token1,fee)` equals the pool, `feeAmountTickSpacing(fee)` equals the pool's tick spacing, and `isPoolDeployedByFactory(pool)` is true. No fake or unregistered pools. One Flare pool (`0xf15f6790…`, WFLR/USDX 500) is **created but never priced** (`sqrtPriceX96 = 0`, `unlocked = false`) and holds 1 wei WFLR + 1,000 wei USDX; anyone can initialize it, but it has no value.

### Upgradeability / Safe risk (context, not E-U)

Both pools and the NPM/factory are upgradeable. Upgrading a pool requires the factory owner (Safe) to call `setPoolImplementation`/`updatePoolsImplementation`, which calls the PoolsProxyAdmin (owned by the factory). The Safe is **2-of-6** on both chains, while Enosys' own documentation says "4/6". There are no modules and no guard. A compromise of any **two** signers can therefore upgrade every pool and move the full ~$6.79M. This is a **privileged (P) centralization risk**, not an unprivileged path. The FTSO/monthly redistributors on Flare are additionally owned by a **single EOA** `0x51578d176168e1203f9a996f42db3bbf23db9acc` (holds ~$8k of WFLR); this is another P risk.

---

## 2. Live TVL verification

### Flare — top pools at block 72,386,299

| Pool | Pair / fee | Token balances | USD |
|---|---|---|---|
| `0xa4cE7dAf…0770` | stXRP/FXRP 500 | 1,229,745.148941 stXRP / 575,316.762176 FXRP | **$2,335,223** |
| `0x975f0369…6FB4` | CDP/USDT0 500 | 1,285,337.465981 CDP / 20,229.981033 USDT0 | **$1,296,618** |
| `0xb4CB11a8…59E7` | WFLR/FXRP 3000 | 68,043,357.046202 WFLR / 431,497.067938 FXRP | **$1,000,678** |
| `0x686f53F0…DbE1` | FXRP/USDT0 3000 | 559,311.545335 FXRP / 244,450.480697 USDT0 | **$969,098** |
| `0x3C2a7B76…5162` | WFLR/USDT0 3000 | 60,147,474.033815 WFLR / 103,044.744162 USDT0 | **$493,157** |
| `0x25B4f393…7144` | sFLR/WFLR 500 | 6,077,878.205497 sFLR / 17,432,315.254567 WFLR | **$187,772** |
| `0xf42A78AE…958c` | CDP/FXRP 3000 | 23,544.323383 CDP / 60,005.615164 FXRP | **$101,151** |
| `0x53dA4618…eaEd` | USDT0/APS 3000 | 11,622.077612 USDT0 / 133,802.657845 APS | **$77,010** |
| `0x3596702a…2984` | WFLR/CDP 3000 | 601,491.117295 WFLR / 62,067.637571 CDP | **$63,236** |
| `0xA7C9E734…B1b7` | HLN/USDT0 3000 | 87,511.700712 HLN / 1,306.276 USDT0 | **$35,316** |

- **Flare total: $6,728,825.23** across 106 pools (all token balances priced with DefiLlama; eETH/eQNT/FACT derived from their deepest WFLR pools).
- **DL Flare: $6,730,974.70** → on-chain is **−$2,149.47 (−0.03%)**. The match is essentially exact.

### Songbird — top pools at block 135,684,340

| Pool | Pair / fee | Token balances | USD (local mark) |
|---|---|---|---|
| `0x47F8222a…65dE` | exUSDT/USDX 100 | 22.907435 exUSDT / 42,127.845519 USDX | $42,151 |
| `0x31dc8421…2f94` | USDX/FXRP 500 | 11,469.160886 USDX / 5,785.945426 FXRP | $18,991 |
| `0x8713373c…4478` | SFIN/FXRP 3000 | 76.833269 SFIN / 4,284.042268 FXRP | $13,081 |
| `0x600d5614…daf0` | SFIN/EXFI 3000 | 53.685146 SFIN / 517,828.041961 EXFI | $12,114 |
| `0x80e3abF8…8cF` | WSGB/FXRP 3000 | 3,625,430.709439 WSGB / 5,418.080842 FXRP | $9,964 |
| `0xb76d223b…09a1` | WSGB/exXDC 3000 | 6,360,743.162300 WSGB / 101,512.616171 exXDC | $8,505 |

- **Songbird local mark: $144,050.65** (WSGB $0.0008055; exUSDT/USDX $1; FXRP $1.30; exXDC $0.0333; exETH $2,411; EXFI/SFIN derived from the deepest WSGB pools: $0.01326 / $97.76).
- **DL Songbird: $62,238.40** → local mark is **+$81,812 (+131%)**. The difference is entirely price-source dependent (USDX at $1 and SFIN at ~$98 are the swing factors); the token quantities themselves are consistent.
- **Total on-chain: $6,872,875.89** (Flare $6,728,825 + Songbird $144,051) vs **DL $6,793,213.10** → **+$79,663 (+1.17%)**. The Flare portion (98% of value) matches DL within **0.03%**; the whole discrepancy is Songbird price marks.

**Protocol fees:** $490.21 across 100 pools (largest: FXRP/USDT0 $242.81, WFLR/USDT0 $109.65, WFLR/FXRP $86.24). These are protocol-owned, collectible permissionlessly to ProfitDistribution.

**Conclusion:** the TVL is real and not phantom. The $6.79M headline is within 1.2% of the on-chain mark; the Flare core is exact.

---

## 3. Bytecode/source diff vs Uniswap V3

| Contract | Enosys runtime | Canonical runtime | Δ | Selectors | Verdict |
|---|---:|---:|---:|---:|---|
| Pool impl | 24,204 B | 22,142 B | **+2,062 B (+9.3%)** | 35 vs 26 | **Custom/patched**: core math identical; proxy init, history snapshots, WNat delegation, default protocol fee added |
| NPM impl | 24,552 B | 24,384 B | **+168 B (+0.7%)** | 49 vs 38 | **Custom/patched**: snapshot/descriptor/upgradeability added; canonical owner checks retained |
| Factory impl | 16,767 B | 24,535 B | **−7,768 B (−31.7%)** | 39 vs 8 | **Custom**: proxy-based factory with pools array, fee collector, upgrade admin |

**Core math is source-identical.** `SqrtPriceMath.sol`, `SwapMath.sol`, `LiquidityMath.sol`, `TickBitmap.sol`, `FullMath.sol`, `LowGasSafeMath.sol`, `SafeCast.sol`, `UnsafeMath.sol`, `FixedPoint128/96.sol` and `BitMath.sol` have **0-line diffs** vs Uniswap v3-core v1.0.0. `Tick.sol`, `Position.sol`, `Oracle.sol`, `TickMath.sol` and `TransferHelper.sol` differ only in pragma/visibility plus the appended `tickLower/tickUpper` fields in `Position.Info`; `Oracle`/`TickMath` functions were made `public` for external library linking. The pool main source is a 619-line unified diff vs canonical; the NPM is a 348-line diff.

**Pool additions (9 selectors):** `initialize(address,address,address,uint24,int24,bool,bool)`, `initialize(uint160)` (canonical init retained), `historyStateTrackerByEpoch/Block`, `isToken0/1Trackable`, `wnat`, `delegate()`, `resetupDelegations()`. No `sweep`, `rescue`, `withdraw`, `setOwner`, `upgradeTo`, or `delegatecall` entry point. The canonical `mint`/`swap`/`flash` payment checks (`M0/M1`, `IIA`, `F0/F1`), `lock`, `collect`/`burn` position-key semantics, and `onlyFactoryOrFactoryOwner` on `collectProtocol`/`setFeeProtocol` are all present.

**NPM additions (14 selectors):** `initialize`, `poolByTokenId`, `historyStateTrackerByEpoch/Block`, `tokenBalanceOfAt`, `tokenTotalSupplyAt`, `getNftUnderlyingTokenOwner`, `updateTokenDescriptor`, `tokenDescriptor`, `isApprovedOrOwner`, `nameHash`, `unwrapWNat`, `wnat`, `enosysdexV3MintCallback`. Canonical `decreaseLiquidity`/`collect`/`burn` still carry `isAuthorizedForToken`; `increaseLiquidity` remains permissionless as in canonical Uniswap (it only adds liquidity to the owner's position). `multicall` is the canonical delegatecall-to-self. `sweepToken`/`unwrapWNat` are public but the NPM holds **0 of all 16 pool tokens and 0 native** at the snapshot block.

**Factory:** the current Flare/Songbird implementation is unverified. The verified Coston1 predecessor (`0x43d7…`, 16,265 B) differs by opcode sequence, so it is an earlier revision; live auth behavior matches the documented factory (`owner`/`governor` = Safe; `setPoolImplementation`/`transferOwnership` = onlyOwner; `setGovernor`/`enableFeeAmount`/`updateProtocolFee`/`updateProtocolFeeReceiver` = onlyGovernor; `collectProtocolFees`/`collectProtocolFeesAll` permissionless with the fixed `protocolFeeReceiver`). `createPool` is permissionless and deploys a `TransparentUpgradeableProxy` with a deterministic CREATE2 salt; existing pools cannot be affected.

**Current pool implementation provenance.** Flare `0x23f02a…` and Songbird `0xfcba…` are **opcode-identical** (16,861 ops; only push constants differ). They differ from the verified Flare predecessor `0xC07b…` in **one internal region** starting at op 10,855. That region reads the `isToken0/1Trackable` flags and calls linked snapshot library `0x2c868fe8…` with selector `0x4d235ae3`, then `PoolSnapshotHelper.snapshotPoolState`; the rest of the runtime (selector dispatch, payment checks, tail) is opcode-identical. This is historical-accounting code, not a fund-moving path. All external ABI selectors are unchanged.

---

## 4. Security tests (read-only `eth_call`)

All tests at Flare block **72,386,500**, from `0x…dEaD`, via public RPC. Raw calls and results: `analysis/security_tests.json`.

| Test | Call | Result |
|---|---|---|
| Pool `mint` with no callback payment | `mint(attacker,-600,600,1e18,"")` from EOA | **revert** (post-callback `M0/M1`) |
| Pool `swap` with no callback payment | `swap(attacker,true,-1e6,MIN+1,"")` | **revert** (`IIA`) |
| Pool `flash` with no repayment | `flash(attacker,1e6,0,"")` | **revert** (`F0/F1`) |
| NPM `collect` non-owner | token 1, recipient attacker | **revert `Not approved`** |
| NPM `collect` owner control | token 1, recipient owner | **success** |
| NPM `burn` non-owner | token 1 | **revert `Not approved`** |
| Pool `collectProtocol` non-factory | recipient attacker, max/max | **revert `NA`** |
| Pool `setFeeProtocol` non-factory | `(10,10)` | **revert `NA`** |
| Pool `resetupDelegations` non-factory | — | **revert `NA`** |
| Factory `setPoolImplementation` | attacker | **revert** `Caller is not the factory owner` |
| Factory `transferOwnership` | attacker | **revert** `Caller is not the factory owner` |
| Factory `setGovernor` | attacker | **revert** `Forbidden` |
| Factory `collectProtocolFeesAll` | attacker | **success** (fixed receiver) |
| Tracker `updateLiquiditySnapshots` | attacker, token 1, 1e30 | **revert** `HistoryStateTrackerBase: missing role` |
| FTSO `claim` non-owner | token 1, recipient attacker | **revert** `NotNftOwner(uint256)` (`0xb832bf93`) |
| FTSO `claim` owner control | token 1, recipient owner | **success** |
| Dust pool `initialize(1.0)` | attacker | **success** (no value) |
| Pool `delegate()` | attacker | **success** (re-delegates to the recorded FTSO provider) |

**Additional structural checks:** all 168 pools have `factory()` = factory, `getPool` = pool, `feeAmountTickSpacing` = tickSpacing, `isPoolDeployedByFactory` = true; all active pools have `feeProtocol = 0x55`, `unlocked = true`, nonzero `sqrtPriceX96` (except the dust pool); the NPM/factory/ProfitDistribution hold 0 of all pool tokens; the history tracker UPDATER role is held by the NPM + every pool (107/41 Flare, 63/22 Songbird) and by no other address; `DEFAULT_ADMIN` is the Safe/factory/WNatRegistry.

---

## 5. Attacker can / cannot

**Can (permissionlessly, but without taking value):**
- `createPool(tokenA,tokenB,fee)` — deploys a new pool proxy; no effect on existing pools.
- `initialize(sqrtPriceX96)` on the one unpriced dust pool — sets its price; it holds 1 wei WFLR + 1,000 wei USDX.
- `collectProtocolFees(start,count)` / `collectProtocolFeesAll()` — sends protocol fees to the fixed `protocolFeeReceiver` (ProfitDistribution), not to the caller.
- `delegate()` on any pool — re-delegates the pool's WNat to the FTSO provider recorded by the redistributor (a provider set by the redistributor owner; cannot be redirected to an attacker).
- `increaseLiquidity(tokenId,…)` on any position — adds the caller's liquidity to the owner's position (canonical Uniswap behavior); the caller cannot collect it.
- `sweepToken`/`unwrapWNat` on the NPM — only stray balances; the NPM holds 0.
- Normal LP/swap/arbitrage — market risk, not a protocol bug.

**Cannot:**
- Mint liquidity without paying the pool (`mint` balance check).
- Take swap output without paying (`swap` balance check).
- Flash-borrow without repaying (`flash` balance check).
- Collect or burn another owner's position (`isAuthorizedForToken`).
- Collect protocol fees or change fee protocol (`onlyFactoryOrFactoryOwner`).
- Change the factory owner/governor/implementation/protocol-fee receiver or enable fee tiers (owner/governor).
- Forge history snapshots or reward claims (UPDATER role; `NotNftOwner`).
- Drain the FTSO/monthly redistributors (owner-only setters; claims owner-gated; `withdraw` is owner/insufficient-balance gated).
- Use a fake pool with the NPM (`PoolAddress.computeAddress` + CREATE2 factory deployment; `CallbackValidation`).
- Exploit a stale price in the material pools: the top pools' implied prices match DefiLlama/CoinGecko within rounding (stXRP/FXRP 0.9993 vs 0.996; CDP/USDT0 0.994 vs 0.993; WFLR/FXRP 0.00503 vs 0.00502; FXRP/USDT0 1.293 vs 1.292; sFLR/WFLR 1.882 vs 1.894).

---

## 6. PoC (negative controls)

`poc/test/EnosysNegativePoC.t.sol` contains 9 Foundry tests against a **read-only Flare fork** at block 72,382,727:

1. `test_mint_without_payment_reverts`
2. `test_swap_without_payment_reverts`
3. `test_flash_without_repayment_reverts`
4. `test_npm_collect_not_owner_reverts`
5. `test_pool_collectProtocol_not_authorized`
6. `test_pool_setFeeProtocol_not_authorized`
7. `test_factory_admin_not_authorized`
8. `test_collectProtocolFees_is_permissionless_but_fixed_recipient`
9. `test_live_pool_state`

The attacker contract implements all three pool callbacks and deliberately does not pay/repay; each pool call must revert. The tests are **negative controls** (they prove the gates close), not an exploit. They were **written but not run locally** per the campaign instruction not to run heavy jobs; `poc/run.sh` is the run script for the parent CI. Expected: **9/9 pass**. `forge build` succeeds.

---

## 7. Verdict / residual risk

| Category | USD | Meaning |
|---|---:|---|
| **E-U** (external unprivileged) | **$0.00** | No path found; all gates live-tested. |
| **H-O** (holder-owned / LP TVL) | **$6,793,213** | The nominal DL TVL is LP-owned and not attacker-extractable; on-chain Flare $6,728,825 + Songbird $62k–$144k. |
| **P** (privileged-only) | **$0** | No privileged-only *bug*; the 2/6 Safe can upgrade/drain the full TVL, and a single EOA owns the Flare FTSO/monthly redistributors (~$8k). These are centralization risks, not E-U. |
| **S** (stuck/socialized) | **$0** | No stuck principal found; the unpriced dust pool holds <$0.000001; protocol fees $490 are collectible to ProfitDistribution. |

**What would change the verdict:**
- A verified source for the current pool impl `0x23f02a…` / factory `0xd835…` revealing a **fund-moving** change (the verified predecessor differs only in the snapshot region; live tests cover mint/swap/flash/collectProtocol).
- A pool whose `factory/token0/token1/fee` or implementation does not match the factory (all 168 checked; none).
- A UPDATER/ADMIN role granted to an attacker-controllable address (only NPM + pools + Safe/factory/WNatRegistry).
- A Safe signer compromise or a hidden module/guard (2/6, no modules, no guard today).
- A material token integration bug (rebasing/fee-on-transfer) in a top pool (top tokens are standard WFLR/FXRP/stXRP/CDP/USDT0/sFLR).
- A verifiable risk-free arb between Enosys and a second venue (top pool prices are consistent; no stale gap found).

---

## 8. Methodology / caveats

**Method.** Public keyless RPCs (`flare-api.flare.network`, `songbird-api.flare.network`, `flare.drpc.org`) for `eth_getCode`, `eth_call`, `eth_getStorageAt`, `eth_getLogs`; Blockscout API v2 for verified source/ABI; DefiLlama coins/protocol APIs and CoinGecko for prices. Pool enumeration by `poolsCount()`/`pools(i)` and `getPools()` (106/62), with per-pool `token0/token1/fee/tickSpacing/slot0/liquidity/protocolFees` and `balanceOf`. All reads recorded with chain + block in `analysis/`.

**Caveats.**
1. The current Flare pool/factory implementations are **unverified**. The verified predecessor `0xC07b…` is a 24,204-byte `EnosysDexV3Pool`; the current impl is opcode-identical to Songbird's and differs from the predecessor only in the snapshot region. The NPM current source **is** verified (Songbird `0xb126…`) and opcode-identical to Flare. The negative result is based on live behavior plus the verified family, not on a byte-exact current source.
2. Songbird TVL is price-source sensitive: DL $62,238 vs local DEX mark $144,051 (USDX at $1, SFIN ~$98). Songbird is 0.9–2.1% of total; the verdict is unchanged.
3. The FTSO/monthly redistributors and some tracker implementations are unverified; only their public claim/setter auth and balances were tested.
4. `createPool` is permissionless and can bloat the `pools` array / the unpriced dust pool can be initialized to make `collectProtocolFeesAll()` revert (ranged collection still works). This is griefing, not value extraction.
5. The 2/6 Safe is below the documented 4/6; this is a real centralization risk and should be fixed, but it is not an external unprivileged path.
6. No Foundry tests were run locally; the parent CI should run `poc/run.sh` and update `summary.json` with the CI URLs.

**Files.** `analysis/` contains the raw evidence: `addresses.json`, `pools_live.json` (168 pools, slot0/balances), `tvl_final.json` (per-pool USD), `final_state.json` (code hashes, owners, roles), `security_tests.json` (18 exact `eth_call` results), `source_diff_summary.json`, `pool_diff.txt`, `npm_diff.txt`, verified source JSON, and the canonical source tree. `poc/` contains the Foundry negative controls. No secrets or keyed RPC URLs are written.
