# BulbaSwap V3 (Morph L2) — unprivileged-extraction deep dive

**Finding:** ZH4-PASS3-OPEN-8-BULBASWAP-V3
**Date:** 2026-10-23
**Chain:** Morph L2 (chainId `2818` = `0xb02`)
**Status:** read-only; PoC fork-verified only; **no mainnet transaction was ever sent**
**Pinned state:** fork block **28,699,967** (RPC `https://rpc.morphl2.io`, keyless)

---

## 1. TL;DR

| target | live extractable by an unprivileged attacker | why closed | latent risk |
|---|---|---|---|
| UniswapV3Factory `0xFf8578…CDDD` | **$0.00** | deployed bytecode **byte-identical to canonical Uniswap V3 core v1.0.0** (only the embedded factory address differs); `owner` is a Gnosis Safe | P: `setOwner` / `enableFeeAmount` (governance) |
| 212 V3 pools (incl. the $2.53 M WETH/USDT pool) | **$0.00** | pool init code keccak == canonical `POOL_INIT_CODE_HASH 0xe34f…8b54` ⇒ every pool is a canonical `UniswapV3Pool`; no `skim()` exists in v1.0.0 | P: $17,620 accrued `collectProtocol` fees (owner-only) |
| NonfungiblePositionManager `0xC6B60E…C20A` | **$0.00** | byte-identical to canonical mainnet NPM (modulo immutables); `collect`/`decreaseLiquidity`/`burn` all `_isApprovedOrOwner`-gated | `sweepToken`/`unwrapWETH9`/`refundETH` are **public** but NPM balance is 0 |
| SwapRouter02 `0xa7304d…6453C` | **$0.00** | byte-identical to canonical mainnet SwapRouter02 | same public-sweep primitive, balance 0 |
| UniswapV3Staker `0x192122…432C2b` | **$0.00** | verified source identical to `Uniswap/v3-staker@main`; **never received a single token** (0 token transfers ever) | none live |
| V3Migrator / QuoterV2 / UniversalRouters / Permit2 | **$0.00** | canonical; zero balances | none live |
| BulbaSwapPointsRedemption `0xdbd064f9…` | **$0.00** | `claim()` requires an ECDSA signature from a live `globalSigner`; all withdrawals are `onlyOwner` | $10.71 USDT (H-O/P) |
| BulbaSwap **V2** router `0x81606e6f…` (context) | **$0.00** | canonical `UniswapV2Router02` has **no sweep/rescue function** | **13,096,433 MOOD permanently stuck (S)** |

### Total live extractable now: **$0.00** — confidence **high**

The deployed BulbaSwap V3 system is, at the bytecode level, **vanilla Uniswap V3** on Morph. There is no removed
`NoDelegateCall`, no weakened `flash` callback auth, no unguarded `mint`/`burn`/`collect`, no `skim` backdoor,
no altered tick/fee math, and no added public/owner function anywhere in the factory, pool, NPM, router or staker.
The only thing a permissionless caller can do that changes state is `increaseObservationCardinalityNext`
(pure gas griefing) and `createPool` (creates an empty pool). Neither yields value.

---

## 2. The claim being tested, in exact terms

The pass-3 recon lane flagged BulbaSwap V3 ($8.6 M, Morph) as an **unassessed** Uni-V3-shaped fork and proposed:
*"diff vs UniV3; test skim/collect auth."* The plausible exploit classes were therefore:

1. a **modified pool** (weakened `collect`/`flash`/`mint`/`burn` auth, removed `lock`, added `skim`);
2. a **modified NPM** allowing a third party to `collect`/`burn` another user's position;
3. a **modified factory** (`setFeeProtocol` / `owner` / `enableFeeAmount` gating);
4. a **public sweep primitive** on periphery holding stray tokens;
5. **TWAP/oracle manipulation** monetisable through an external integration.

All five were tested and all five are closed. The decisive evidence is not source-text similarity but
**deployed-bytecode identity**:

* Factory runtime code (24,535 bytes) differs from the canonical Ethereum-mainnet factory
  (`0x1F98431c8aD98523631AE4a59f267346ea31F984`) in **exactly 20 bytes**, all inside one address literal:
  the factory's own address embedded in the pool init code (`analysis/bytecode-diffs.txt`).
* The pool init code extracted from the factory's verified creation bytecode hashes to
  `0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54` — **exactly the canonical
  `POOL_INIT_CODE_HASH`** of `Uniswap/v3-core@v1.0.0` (`ci/verify_initcode.py`, PoC test 1).
  Because the CREATE2 address is `keccak256(0xff ‖ factory ‖ keccak256(abi.encode(token0,token1,fee)) ‖ POOL_INIT_CODE_HASH)[12:]`,
  a matching hash **proves** every pool created by this factory is a byte-identical canonical pool.
* NPM / SwapRouter02 / V3Migrator runtime code differ from their canonical mainnet counterparts **only** in
  20-byte immutable address slots (factory, WETH9, V2 factory/router, NPM, token descriptor).
* UniswapV3Staker runtime code is a different size only because of the optimizer-runs setting; the
  **verified source is byte-for-byte identical** to `Uniswap/v3-staker@main`
  (`analysis/source-diffs.txt`).
* The factory's verified source is **identical** (0-byte diff) to `Uniswap/v3-core@v1.0.0`
  `UniswapV3Factory.sol`.

---

## 3. Live-state assessment (all values at fork block 28,699,967)

### 3.1 Roles / governance

| contract | address | state |
|---|---|---|
| UniswapV3Factory | `0xFf8578C2949148A6F19b7958aE86CAAb2779CDDD` | deployed block 25,159 by `0x502dC547…17172`; **owner = GnosisSafeProxy `0x9876097201662D70A63C935c2f7576B35D6f45e7`** (set via `setOwner` at block 217,441) |
| factory fee tiers | — | `100→1`, `500→10`, `3000→60`, `10000→200` (4 `FeeAmountEnabled` events) |
| other V3 factories deployed by the same EOA | `0xd7fc3434…`, `0x7cb2b455…`, `0x530b746f…`, `0xfb0d1c33…`, `0x3269e83b…` | **0 pools each** — empty duplicates; `owner` = deployer EOA `0x502dC547…17172` |
| WETH9 (Morph predeploy) | `0x5300000000000000000000000000000000000011` | standard |
| NonfungiblePositionManager | `0xC6B60EE77854b7c11c39b6E3f5BCfe1866cbC20A` | `totalSupply()` = 2,370; `factory()` = BulbaSwap factory ✔ |
| SwapRouter02 | `0xa7304d322219553d4A85c9cE8eB7462Dcaf6453C` | `factory()` = BulbaSwap factory ✔ |
| V3Migrator | `0xe87c01ca304d69a94c4E079275B276BE659EE5eF` | canonical |
| UniswapV3Staker | `0x192122E28E45923cAbdcC40232a278867a432C2b` | canonical; `factory()`/`nonfungiblePositionManager()` correct; **0 token transfers in its entire history** |
| QuoterV2 | `0xc312e6417d07ae7ba73fef0832b1811194a7bbef` | canonical |
| BulbaSwapPointsRedemption (proxy) | `0xdbd064f9E41dB9F08cb9F481C72a2EEb29AFC9A4` | impl `0x8b4e589d7f345c5620454aa780a41604e5ea1740`; `owner()` = `0xF4a82c4A…1192`; `globalSigner()` = `0xCbE17Abd…f707`; `currentEventId()` = 5 |
| BulbaSwap V2 factory / router | `0x8d2a8b8f…` / `0x81606e6f…` | canonical `UniswapV2Factory` / `UniswapV2Router02` |

### 3.2 Pools — 212 `PoolCreated` events, all canonical

Enumerated from the factory's `PoolCreated(address,address,uint24,int24,address)`
(topic0 `0x783cca1c…b7118`); 212 events, fee-tier split `10000×83 / 3000×65 / 100×34 / 500×30`.
Every pool: `slot0().unlocked == true`, `observationCardinality == 1`, `observationCardinalityNext == 1`.

**Total reserves of all 212 pools: $8,937,393.70** (DefiLlama `coins.llama.fi/prices/current/morph:<token>`;
DefiLlama reports $8,669,681 for the protocol — the delta is tokens DefiLlama does not price).
Top pools (token balances read with `balanceOf(pool)`):

| # | pool | pair / fee | reserves | USD |
|---|---|---|---|---|
| 1 | `0x5191035D329f481eFf0143e690e0a4e366Dd1e0c` | WETH/USDT 0.05 % | 524.8931 WETH + 1,265,163.11 USDT | **$2,527,171** |
| 2 | `0x24a691c2c8afab7049b6ab6847e3d06b5cbe5a11` | WETH/USDT0 0.05 % | 223.8114 WETH + 538,272.09 USDT0 | $1,076,410 |
| 3 | `0xac573f9eb6ff53c26288141005feac8e73fa8f87` | WETH/USDC 0.05 % | 217.8934 WETH + 522,222.74 USDC | $1,046,434 |
| 4 | `0x1daa3cc94abdaed06f077e97ddf54ac1c98cbcb0` | USDC/USDT0 0.01 % | 344,083.65 USDC + 656,880.86 USDT0 | $1,000,055 |
| 5 | `0x80535b62b0debbe98d68ba466781f070abc31afa` | BGB/USDC 0.05 % | 260,316.71 BGB + 495,275.76 USDC | $990,652 |
| 6 | `0x1ac6c6ce2aca3018dbde8a8834cb0cf3f083f896` | USDT/USDC 0.01 % | 481,409.20 USDT + 468,929.51 USDC | $949,500 |
| 7 | `0x9acaa995cf74bb5c45f1f0b76053e4e4d9f90f09` | WETH/BGB 0.05 % | 161.1445 WETH + 203,918.22 BGB | $776,147 |
| 8 | `0xf0f974d5855bd006cc99843b3f7393376d5e4dcb` | BGB/WETH 0.05 % | 67,382.00 BGB + 53.5135 WETH | $257,106 |

(`analysis/pool_usd.json` holds all 212 rows with per-token amounts, decimals and prices.)

### 3.3 Positions (who actually owns the $8.94 M)

Enumerated all 2,370 position NFTs via `positions(tokenId)` + `ownerOf(tokenId)`:

* **566 positions carry liquidity**, spread over **228 distinct owners** — overwhelmingly EOAs (real LPs);
  the largest single holder is an EOA (`0x8557acFc…b5fB`, 166 positions). Two owners are
  `UniV3LPLocker` contracts (`0x25c9c4b5…bd52` 50 positions, `0x1cd6778b…2dfcd` 5).
* Only **11 positions have any `tokensOwed`**, totalling **$1.33** of uncollected fees.
* **0 positions** have liquidity > 0 while the pool balance is 0 (no accounting mismatch).

⇒ The $8.94 M is ordinary user-owned LP principal + fees → **H-O**, not attacker-extractable.

### 3.4 Protocol fees (privileged)

13 pools have `slot0().feeProtocol == 68` (`0x44` ⇒ 4/4, i.e. 25 % of swap fees to the protocol).
Reading the pool's `protocolFees` storage slot (slot 3) gives **$17,620.63** accrued, of which
**$13,293.28** sits in pool #1. `collectProtocol` is `onlyFactoryOwner`
(`require(msg.sender == IUniswapV3Factory(factory).owner())`) → **P**, Gnosis-Safe-only.

### 3.5 Stray balances in periphery

Exhaustive sweep of every contract deployed by `0x502dC547…17172` (35 contracts) × every pool token + WETH:

| holder | token | amount | USD | reachable? |
|---|---|---|---|---|
| NPM, SwapRouter02, V3Migrator, Staker, QuoterV2, UniversalRouters, Permit2, TickLens, descriptors, multicalls | — | **0** | **$0.00** | public `sweepToken`/`unwrapWETH9`/`refundETH` exist but there is nothing to take |
| BulbaSwapPointsRedemption | USDT | 10.7104 | $10.70 | signature-gated `claim` (H-O) / `onlyOwner` withdraw (P) |
| Gnosis Safe (protocol treasury) | USDT | 80.2560 | $80.16 | P |
| **BulbaSwap V2 router** `0x81606e6f…` | **MOOD** | **13,096,433.04** | ~$13,517 *(thin-market price, low confidence)* | **stuck (S)** — canonical `UniswapV2Router02` exposes no sweep/rescue |
| 82 zero-liquidity V3 pools | dust | — | $19.05 | **stuck (S)** — v1.0.0 has no `skim()` |

---

## 4. What an attacker can / cannot do

**Cannot (fork-verified, all revert or are no-ops):**

| call | caller | result |
|---|---|---|
| `NPM.collect({tokenId: foreign})` | attacker | revert `Not approved` |
| `NPM.decreaseLiquidity({tokenId: foreign})` | attacker | revert `Not approved` |
| `NPM.burn(foreign)` | attacker | revert `Not approved` |
| `NPM.increaseLiquidity(foreign)` | attacker | permissionless by design, but reverts (caller must implement `uniswapV3MintCallback`) and **moves no value out** |
| `pool.flash(recipient, amt, 0, "")` | attacker | revert `F0` unless `amt+fee` is repaid |
| re-enter `pool.swap` from inside `uniswapV3FlashCallback` | attacker | blocked by `lock` (`LOK`) |
| `pool.skim(recipient)` | attacker | **function does not exist** (selector `0xbc25cf77` absent from the deployed code) |
| `pool.collectProtocol(attacker,…)` | attacker | revert (owner-only) |
| `pool.setFeeProtocol(…)` | attacker | revert (owner-only) |
| `factory.setOwner(attacker)` / `factory.enableFeeAmount(…)` | attacker | revert (owner-only) |
| `PointsRedemption.claim(5,1,USDT,1,"")` | attacker | revert (ECDSA / `Invalid signature`) |
| `PointsRedemption.withdrawRemainingToken(5,USDT)` | attacker | revert (owner-only) |

**Can (but worthless to an attacker):**

* `NPM.sweepToken(token, 0, attacker)` / `unwrapWETH9(0, attacker)` / `refundETH()` — genuinely public
  (canonical `PeripheryPayments`), but every periphery balance is 0 ⇒ transfers 0.
* `pool.increaseObservationCardinalityNext(n)` — permissionless; raises `observationCardinalityNext`
  from 1 to n. Pure gas griefing; **no value accrues to the caller**.
* `factory.createPool(a,b,fee)` — permissionless, creates an empty pool (costs gas, yields nothing).
* `pool.swap(...)` — canonical AMM; only ordinary arbitrage against *other users*, not protocol extraction.

**Costs:** none of the closed paths has a positive net (they revert before any value moves). No flash loan,
capital or MEV position is required to attempt any of them.

**Oracle caveat (not monetisable):** every pool has `observationCardinality == 1`, so `observe()` only serves
the single most-recent observation; `observe([0, 3600])` reverts `OLD` on the busiest pool. An external
integration therefore cannot use these pools as a TWAP oracle — which removes the classic
"raise cardinality then manipulate the TWAP" attack against a *victim* integration. No such integration was found.

---

## 5. PoC / fork verification

* `poc/` — Foundry project, `solc 0.8.24`, vendored `lib/forge-std`, fork
  `https://rpc.morphl2.io` @ block **28,699,967** (hardcoded keyless URL; no secrets).
* `poc/test/BulbaV3.t.sol` — **22 tests, 22 PASS** (see `ci-log.txt`).
* `ci/run.sh` — heavy job: init-code hash verification + 212-pool scan + 2,370-position enumeration +
  exhaustive periphery balance sweep; artifacts in `ci-out/`.
* CI run URL: see `ci-log.txt` / `summary.json` → `poc.ci_run_urls`.

Key test evidence:

```
[PASS] test_poolInitCode_isCanonicalUniswapV3()
   canonical POOL_INIT_CODE_HASH reproduces pool 0x5191035D329f481eFf0143e690e0a4e366Dd1e0c
[PASS] test_skimSelector_absentFromDeployedPool()   (skim selector 0xbc25cf77 absent)
[PASS] test_collectForeignPosition_reverts()
[PASS] test_decreaseLiquidityForeign_reverts()
[PASS] test_burnForeign_reverts()
[PASS] test_flash_reentrancyBlockedByLock()
[PASS] test_flash_repaymentRequired()
[PASS] test_collectProtocol_nonOwner_reverts()
[PASS] test_setFeeProtocol_nonOwner_reverts()
[PASS] test_factory_setOwner_nonOwner_reverts()
[PASS] test_factory_enableFeeAmount_nonOwner_reverts()
[PASS] test_npm_sweepToken_isPublicButEmpty()
[PASS] test_observe_reverts_beyondLastObservation()
[PASS] test_increaseObservationCardinalityNext_isPermissionless_griefOnly()
[PASS] test_staker_isEmpty_andUnused()
[PASS] test_pointsRedemption_claimRequiresSignature()
...
```

---

## 6. Verdict, residual / latent risk

**Verdict: no live unprivileged extraction. E-U = $0.00 (high confidence).**

This is an honest negative with a strong proof: the entire BulbaSwap V3 deployment is a
**byte-for-byte canonical Uniswap V3** (core + periphery + staker) with only immutable address
substitutions, so every known Uniswap V3 security property carries over unchanged.

Residual / latent risk (not extractable by an external attacker today):

* **P — governance:** the factory owner is a Gnosis Safe. It can `setOwner`, `enableFeeAmount`,
  `setFeeProtocol` on any pool and `collectProtocol` (**$17,620.63** accrued). If that Safe were
  compromised or its signers colluded, they could raise protocol fees to 100 % of swap fees
  (`setFeeProtocol(10,10)`-style values are bounded to 4..10, so up to 1/4), but they can never
  touch LP principal. The PointsRedemption proxy is also upgradeable (ProxyAdmin `0xe2e62246…`).
* **S — stuck:** $19.05 of dust in 82 zero-liquidity pools (v1.0.0 has no `skim`), and
  **13,096,433 MOOD (~$13.5 k at a very thin market price — low confidence)** permanently stranded in
  the BulbaSwap **V2** router `0x81606e6f…`, which exposes no sweep/rescue.
* **H-O — users:** $8.94 M of LP principal in 566 live positions (228 owners) plus $1.33 of uncollected
  fees, plus $10.71 USDT in PointsRedemption claimable with a valid `globalSigner` signature.
* **Oracle:** cardinality 1 on all pools ⇒ these pools must not be used as TWAP oracles.

**Blockers to any future re-assessment:** none technical — the target is fully verified and canonical.
The only way this verdict changes is if the factory `owner` Safe or the PointsRedemption `ProxyAdmin`
is used to deploy *new* non-canonical logic (a new pool type or a proxy upgrade).

---

## 7. Methodology, sources, caveats, files

**Method.** (1) Enumerated pools by `PoolCreated` logs, not by blog lists. (2) Proved code identity by
bytecode diff against canonical mainnet deployments *and* by CREATE2/init-code-hash derivation, rather than
trusting source text. (3) Measured live value with `balanceOf`/`slot0`/`protocolFees` storage reads at an
explicit block and priced with DefiLlama. (4) Reduced every candidate path to a concrete call sequence and
executed it on a Morph fork. (5) Separated E-U / H-O / P / S.

**Sources.** Morph explorer Etherscan-style API (`explorer-api.morphl2.io/api`: `getsourcecode`,
`getcontractcreation`, `getLogs`, `txlist`, `tokentx`); keyless `https://rpc.morphl2.io`; verified source of
the factory/NPM/router/migrator/staker from the Morph explorer; canonical sources from
`github.com/Uniswap/v3-core@v1.0.0`, `v3-periphery`, `v3-staker@main`; Ethereum mainnet RPC for canonical
bytecode; DefiLlama `coins.llama.fi`; DefiLlama protocol `bulbaswap-v3`.

**Caveats.** (a) Prices are DefiLlama spot at the measurement time; the MOOD price is derived from a V2 pair
holding only 0.000756 WETH and is therefore low-confidence. (b) `protocolFees` is a private storage slot —
read via `eth_getStorageAt` at slot 3; correct for the canonical layout, verified against the pool's own
`feeProtocol` values. (c) Position enumeration is point-in-time; LP churn is normal. (d) The 2,370-position
scan used the keyless public RPC — a few ids could not be re-read on retry, but 0 rows were dropped.
(e) `ownerOf` on burned ids reverts; those ids are recorded with `liquidity == 0`.

**Files index.**

```
bulbaswap-v3/
├── README.md                         this report
├── summary.json                      machine-readable summary
├── ci-log.txt                        CI run log + run URL
├── analysis/
│   ├── pools.json                    212 PoolCreated events (raw)
│   ├── pools_state.json              token0/token1/fee/liquidity/slot0/balances per pool
│   ├── pool_usd.json                 per-pool USD (all 212)
│   ├── token_meta.json, prices.json  123 pool tokens: decimals/symbol + DefiLlama price
│   ├── positions.json                2,370 positions: owner, liquidity, tokensOwed
│   ├── periphery_balances.json       balance scan of 20 named periphery contracts
│   ├── all_contract_balances.json    exhaustive scan: all 35 deployed contracts × tokens
│   ├── bytecode-diffs.txt            deployed bytecode vs canonical mainnet
│   ├── source-diffs.txt              verified source vs Uniswap upstream
│   ├── factory_verified.sol, factory_abi.json, factory_src.json
│   ├── canonical/                    Uniswap v3-core v1.0.0 reference sources
│   ├── morph_staker_main.sol, canonical_staker_main.sol, mainnet_staker_main.sol
│   ├── points_impl.sol, points_impl_abi.json
│   └── scan_pools.py, price_pools.py, enum_positions.py, scan_periphery.py,
│       scan_all_balances.py, bytecode_diff.py
├── ci/
│   ├── run.sh                        heavy CI job
│   └── verify_initcode.py            pure-python keccak init-code verification
├── ci-out/                           CI artifacts
└── poc/                              Foundry project (22 tests, all pass)
    ├── foundry.toml
    ├── src/Interfaces.sol
    ├── test/BulbaV3.t.sol
    └── lib/forge-std                 vendored
```
