# Predy V2 `PredyPool.registerPair` — is the 2024 caller-becomes-owner drain still live? (ZH4-PASS5 Tier-3 #1)

**Date:** 2026-10-23 · **Chain:** Arbitrum One (42161) · **Status:** read-only; PoC fork-verified only; no mainnet transactions
**Target:** `PredyPool` proxy `0x9215748657319B17fecb2b5D086A3147BFBC8613` (impl `0x818074b77cd95215df23a8402f5e4fdca0ac4d17`)
**Live block:** 517,457,104 (reads) / 517,461,834 (fork PoC)

---

## 1. TL;DR

| Target | Live value | Live extractable (unprivileged) | Why closed | Latent risk |
|---|---|---|---|---|
| **PredyPool `0x9215748657319B17fecb2b5D086A3147BFBC8613`** (the 2024 victim) | ~$15.11 | **$0** | `registerPair` — the 2024 entry primitive — is now `onlyOperator`; **every** value-moving entry point (`trade`, `take`, `supply`, `withdraw`, `withdrawProtocolRevenue`, `withdrawCreatorRevenue`) is `onlyOperator`/`onlyByLocker`. The pool holds only 82.83 ARB + 0.0086 USDC.e. | Operator (proxy admin EOA `0x4f07…`) could re-open by registering a pair; monitor `operator()` / proxy impl. |
| **`PerpetualMarket` `0xc7ec02AEeCdC9087bf848c4C4f790Ed74A93F2AF`** + **`0xAdBAeE9665C101413EbFF07e20520bdB67C71AB6`** (the real DefiLlama *predy-v2* $12.3k) | **$12,067.57 USDC.e + 0.1128 WETH ≈ $12,332** | **$0 proven; not audit-complete** | 2022 `PerpetualMarket` (solc 0.7.6) — a **different codebase with no `registerPair`** (hence pass-5's *empty* revert). Auth surface reviewed: `initialize` guarded (`totalSupply()==0`), core funcs `onlyPerpetualMarket`, price = **Chainlink** feed, LP price uses internal `amountLiquidity` (donation-proof), `withdraw`/`deposit` are caller-bound, `execHedge` `onlyHedger`, permissionless `liquidateByPool` pays only from the vault's own margin. No unprivileged payout found, but the squeeth-style LP/hedge math was not fully audited. | $12.3k at risk if the LP-price/hedge math has a bug — **unresolved**. |

**Headline: external-unprivileged extractable = $0 (high confidence) for the 2024 `registerPair` recipe.**

**Two corrections to pass-5:**
1. **The pass-5 "empty revert through the proxy" was a mis-probe** on the *named* contract: with correct calldata
   `PredyPool.registerPair` reverts with the *named* custom error `CallerIsNotOperator()` (`0xd0769d8e`), not empty.
2. **The "$12.3k" is not in the named contract.** DefiLlama's `predy-v2` adapter (deleted from `main`, recovered from
   commit `cac3773a`) measures **`0xc7ec02AEeCdC9087bf848c4C4f790Ed74A93F2AF` + `0xAdBAeE9665C101413EbFF07e20520bdB67C71AB6`** —
   two 2022 `PerpetualMarket` contracts that *do* revert empty on `registerPair` (no such selector) and hold the
   ~$12.3k. The 2024 exploit victim (`0x9215…`) is a later, fully operator-gated deployment.

---

## 2. The 2024 bug and what changed

**Incident:** Predy Finance, Arbitrum, 14 May 2024, ~$464k. PoC: `SunWeb3Sec/DeFiHackLabs` `src/test/2024-05/PredyFinance_exp.sol`;
attack tx `0xbe163f651d23f0c9e4d4a443c0cc163134a31a1c2761b60188adcfd33178f50f`; attacker `0x76b02ab483482740248e2ab38b5a879a31c6d008`;
attack contract `0xb79714634895f52a4f6a75ecEb58C96246370149`.

**Recipe (as deployed in 2024):**
1. `registerPair(AddPairParams{poolOwner: attacker, priceFeed: attacker, …})` — permissionless; the caller's
   `poolOwner`/`priceFeed` became attacker-controlled.
2. `trade(tradeParams, "")` — sets `lockData.locker = attacker` and invokes the attacker's `predyTradeAfterCallback`.
3. In the callback: `take(...)` the whole pool balance to the attacker, then `supply(...)` it back as the attacker's own LP
   (bypassing `PositionCalculator.checkSafe()` / `finalizeLock()`).
4. `withdraw(pairId, …)` — burns the attacker's LP and pays the attacker the pool's tokens.

**What the live implementation does now** (verified source of impl `0x818074b7…`, solc 0.8.19):

```solidity
modifier onlyOperator() { if (operator != msg.sender) revert CallerIsNotOperator(); _; }

function registerPair(AddPairLogic.AddPairParams memory p) external onlyOperator returns (uint256) { … }   // PredyPool.sol:109
function trade(TradeParams memory t, bytes memory s) external onlyOperator returns (TradeResult memory) { … } // :253
function supply(uint256,bool,uint256) external nonReentrant onlyOperator returns (uint256) { … }             // :212
function withdraw(uint256,bool,uint256) external nonReentrant onlyOperator returns (uint256,uint256) { … }   // :224
function take(bool,address,uint256) external onlyByLocker onlyOperator { … }                                 // :313
```

Live `operator()` = **`0x4f071924D66BBC71A5254217893CC7D49938B1c4`**, which is *also* the EIP-173 proxy owner/admin
(storage slot `0xb53127…`). So the only address that can register a pair or move funds is the protocol admin.

---

## 3. Live-state assessment (block 517,457,104)

| Item | Value | Evidence |
|---|---|---|
| Proxy `0x9215…` | EIP-173 proxy, code size **2,466 B** | `cast codesize` |
| Impl (EIP-1967 slot `0x360894…`) | `0x818074b77cd95215df23a8402f5e4fdca0ac4d17`, verified `PredyPool`, 18,973 B | `cast storage`, Etherscan V2 |
| Admin (slot `0xb53127…`) | `0x4f071924D66BBC71A5254217893CC7D49938B1c4` (EOA, code size 0) | `cast storage`, `cast codesize` |
| `operator()` | `0x4f071924D66BBC71A5254217893CC7D49938B1c4` | `cast call` |
| `registerPair(...)` from random EOA | revert **`CallerIsNotOperator()` `0xd0769d8e`** | `cast call --from 0x…1111` |
| `trade` / `supply` / `withdraw` from random EOA | revert `CallerIsNotOperator()` `0xd0769d8e` | `cast call` |
| `take` from random EOA | revert `LockedBy(0x0)` `0x4f4b04cc` (locker unset ⇒ blocked before operator gate) | `cast call` |
| `reallocate(pairId, "")` from random EOA | **succeeds** (permissionless; no-op when no rebalance) | `cast call` |
| `createVault(pairId)` from random EOA | **succeeds** (permissionless; creates a vault, moves no funds) | `cast call` |
| Pool token balances | USDC `0`; USDC.e `8603` (=$0.0086); WETH `0`; ARB `82.82945504` (=$15.10) | `balanceOf` at block |
| Pairs | #1 USDC.e/WETH; #2 USDC/WETH (accounting 220,876 USDC + 83.4 WETH, **actual balance 0**); #3 WETH/USDC `poolOwner = 0xb79714634895f52a4f6a75ecEb58C96246370149` (**the 2024 attack contract**), `lastUpdateTimestamp 1715672488` (2024-05-14) | `getPairStatus(1..3)` decoded |

Pair #3 is the residual artefact of the 2024 exploit (its `poolOwner` is literally the attacker's contract) and it is empty.

### Where is the "$12.3k"?
DefiLlama's `predy-v2` slug reports **$12,332.77** (2026-10-23) with tokens `USDC 12,068.5 + WETH 0.1128`. That does **not**
correspond to the named pool contract, which holds **~$15.11** on-chain. The DefiLlama adapter file for this slug
(`projects/predy/index.js`) is **not present** in `DefiLlama/DefiLlama-Adapters@main` (only `predy-v3`, `predy-v320`,
`predy-v5` exist), so the figure is stale/misattributed. Either way, the *contract named in the finding* holds ~$15, and
it is unreachable by an unprivileged attacker.

---

## 4. What an attacker can / cannot do

- **Cannot** register a pair (operator-gated) ⇒ the 2024 primitive is gone.
- **Cannot** trade, supply, withdraw, take, or withdraw revenue (operator/locker gated).
- **Can** call `reallocate` and `createVault` (permissionless), but neither transfers pooled tokens to the caller:
  `reallocate` only rebalances the pair's own Uniswap position and returns `exceedsQuote` from the *settlement callback*
  (the pair's own funds), and both pairs are empty; `createVault` just creates a vault struct.
- **Costs:** even if a path existed, it would need to beat gas (~$0.05–0.2 on Arbitrum) against a pool holding ~$15.

**Net extractable: $0.**

---

## 4b. The real "$12.3k" — 2022 `PerpetualMarket` contracts (different codebase)

DefiLlama's `predy-v2` slug uses module `predy/index.js` (deleted from `DefiLlama-Adapters@main`; recovered from commit
`cac3773a`), which sums USDC+WETH at **`0xc7ec02AEeCdC9087bf848c4C4f790Ed74A93F2AF`** (V2) and
**`0xAdBAeE9665C101413EbFF07e20520bdB67C71AB6`** (V2.0.2). Measured on-chain:

| Address | Contract | Code | USDC.e | WETH | ≈USD |
|---|---|---|---|---|---|
| `0xc7ec02…F2AF` | `PerpetualMarket` (solc 0.7.6) | 19,056 B, not a proxy | 1,987.704829 | 0 | $1,987 |
| `0xAdBAeE…1AB6` | `PerpetualMarket` (solc 0.7.6) | 22,785 B, not a proxy | 10,079.868319 | 0.1127972 | $10,345 |
| | | | | **total** | **≈$12,332** |

These are 2022 squeeth-style perps (product 0 = ETH future, product 1 = ETH²/10000). Interface:
`deposit`, `withdraw`, `trade`, `addMargin`, `liquidateByPool`, `execHedge`, `initialize`, `pause`/`unPause`, `owner`,
`setHedger`, `setFeeRecepient`. **No `registerPair`, no `operator()`** ⇒ `cast call` on either selector reverts **empty**
(the exact symptom pass-5 reported). Cores: `0x17f63ee2…` / `0x8b98991e…` (`PerpetualMarketCore`); owner
`0xb8d843c8E6e0E90eD2eDe80550856b64da92ee30` (not renounced); `hedger` set; `isSystemPaused=false` on `0xAdBAeE`.

**Auth surface reviewed (source-verified):**
- `initialize(_deposit, _rate)` — guarded by `require(totalSupply()==0)` in the core ⇒ **not re-initializable**.
- core `deposit`/`withdraw`/`updatePoolPosition`/`addLiquidity` — `onlyPerpetualMarket`.
- `getUnderlyingPrice()` = **Chainlink `AggregatorV3Interface.latestRoundData()`** (product 0 trade price read back
  `≈2402.5` = ETH/USD 8-dp) ⇒ not flash-loan-manipulable; LP price uses internal `amountLiquidity`, not token balance
  ⇒ donation-inflation-resistant.
- `withdraw`/`deposit`/`addMargin` — bound to `msg.sender`; `execHedge` — `onlyHedger`; `setHedger`/`setFeeRecepient` —
  `onlyOwner`; `liquidateByPool` — permissionless but the reward is taken from the *vault's own* margin
  (`decreaseLiquidationReward`), so no pool drain.
- **No unprivileged payout path found.** Residual uncertainty: the squeeth-style `getLPTokenPrice` / `NettingLib` /
  hedge math was **not** fully audited, so a latent LP-mispricing drain cannot be excluded. This is the item to
  re-check if $12.3k of value is to be defended.

---

## 5. PoC / fork-verification

`poc/test/PredyRegisterPair.t.sol` (Foundry, forks Arbitrum via `ARB_RPC_URL`):

| Test | Result |
|---|---|
| `test_registerPair_is_operator_gated` | **PASS** — random EOA ⇒ `CallerIsNotOperator` |
| `test_all_value_paths_operator_gated` | **PASS** — `trade`/`withdraw`/`supply` ⇒ `CallerIsNotOperator`; `take` ⇒ `LockedBy(0)` |
| `test_operator_can_register_control` | **PASS** — `operator()==0x4f07…`; pranked operator registers pair #4 (control proving the gate is the only barrier) |
| `test_permissionless_surface_is_harmless` | **PASS** — `createVault`/`reallocate` succeed but move no value |
| `test_measure_live_pool_value` | **PASS** — pool USDC 0 / WETH 0 / USDC.e 8603 / ARB 82.82945504 |

**Local run:** 5/5 PASS. **CI:** see `ci-log.txt` and `ci-artifacts/`; run URL recorded in `summary.json`.

---

## 6. Verdict & residual risk

**Verdict (2024 `registerPair` recipe): CLOSED — E-U = $0 (high confidence).** The named `PredyPool` `0x9215…` is fully
operator-gated (`registerPair` + all value movers), the sole operator is the protocol admin EOA (also proxy owner), and
the pool holds ~$15.11 that is unreachable by an outsider. The 2024 caller-becomes-owner drain cannot be reproduced.

**Verdict (the actual $12.3k at `0xc7ec02` + `0xAdBAeE`): no unprivileged payout found; NOT audit-complete (medium
confidence).** The 2024 recipe does not apply (no `registerPair`). Reviewed auth is sound (Chainlink price, guarded
init, caller-bound LP ops, hedger-gated hedge, margin-bounded liquidation reward). The outstanding risk is the
un-audited LP-price/hedge math — flagged for follow-up, not proven exploitable.

**Residual / latent (privileged, not E-U):** the named `PredyPool` proxy is upgradeable and the operator/admin is a
single EOA (`0x4f07…`, code size 0); key compromise or upgrade re-opens full control. The 2022 markets' owner is
`0xb8d843c8…` (EOA, not renounced).

**Blockers / limitations:** DefiLlama's `predy-v2` figure is not reproducible from the named contract (adapter deleted
from `main`); it maps to the two 2022 markets instead. The 2022 `PerpetualMarketCore` LP/hedge math was not fully
audited. The fork PoC is against current Arbitrum state; historical 2024 state was not re-forked (not needed — the fix
is in the live impl, confirmed by source + `eth_call`).

---

## 7. Methodology & sources

- Etherscan V2 (`chainid=42161`) `getsourcecode`/`getabi` for proxy + impl; full verified source bundle extracted
  (`analysis/impl_source_raw.txt`, `sources_flat.json`, `PredyPool.sol`, `AddPairLogic.sol`, `ReallocationLogic.sol`).
- `cast storage` (EIP-1967 impl/admin slots), `cast call` (`operator`, `getPairStatus(1..3)` decoded via `cast decode-abi`),
  `balanceOf` for USDC/USDC.e/WETH/ARB, `cast codesize`.
- DeFiHackLabs `2024-05/PredyFinance_exp.sol`; DefiLlama `api.llama.fi/protocol/predy-v2`.
- Foundry 1.8.5 fork PoC; public RPC `https://arb1.arbitrum.io/rpc`.

**Files:** `analysis/probe1..8.sh`, `analysis/sig.py`, `analysis/impl_abi.json`, `analysis/PredyPool.sol`,
`analysis/AddPairLogic.sol`, `analysis/pair_1..3.hex`, `poc/test/PredyRegisterPair.t.sol`, `summary.json`.
