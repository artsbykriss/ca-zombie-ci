# CoW Protocol `GPv2Settlement` — GlueX/CIP-55 solver-allowance deep-dive

**Date:** 2026-10-23 · **Chain:** Ethereum mainnet · **Status:** read-only; PoC fork-verified only; **no mainnet transactions**.
**Campaign:** ZH4 pass-5 Tier-3 row 4 · **Folder:** `cow-gpv2/` · **Target:** `0x9008d19f58aabd9ed0d60971565aa8510560ab41` (GPv2Settlement)

---

## 1. TL;DR

| # | Question | Answer | Why | Confidence |
|---|---|---|---|---|
| 1 | Does the settlement own token **allowances**? | **YES — ~400 live (spender,token) pairs** | `allowance(settlement, spender) > 0` for ~104 distinct spenders, incl. solver helper contracts. **pass5's "no settlement-owned approvals found" is wrong.** | high |
| 2 | Can an unprivileged caller **pull the buffer** today? | **NO — $0 proven** | Every live spender is `msg.sender`-bound, auth-gated (`onlyCowSettlementContract`, `authenticateFor`, `onlyOwner`) or signature-gated. Fork-verified on the strongest candidates. | high |
| 3 | Can an unprivileged caller pull **user approvals**? | **NO** | Users approve `GPv2VaultRelayer` (`0xc92e8bdf…`), whose only fund path `transferFromAccounts` is `onlySettlement` (source). | high |
| 4 | What is at stake behind the allowances? | **≈ $2,931.92** (settlement fee/gas buffer) | Measured `balanceOf` at block 26,253,971, priced with DefiLlama. Excludes unpriced `imBTC` (0.00132) and `SLP` (50 142) ⇒ ~$3.0k. | high |
| 5 | Residual/latent risk | **Legacy Hashflow router `0xF6a94dfD…`** still live, unpaused, max-approved, and it pulls the base token from the **calldata `trader` field** *before* the market-maker signature is checked | The exact 2023 CoW-hack mechanism (helper `0xf6a94dfd` + `trader = settlement`). Exploiting it needs a valid unexpired MM-signed quote naming the settlement. **Unproven today.** | medium |

## 2. Total live extractable now

> **E-U (external unprivileged) = $0.00** — no permissionless drain path exists today (high confidence).
> **Latent exposure behind the live allowances = $2,931.92** (the settlement buffer; medium-confidence conditional vector via the legacy Hashflow router).

Categories: **E-U $0.00** · **H-O $0.00** (no user-facing self-service contract involved) · **P $0.00** (privileged paths exist but are out of scope) · **S $0.00**.

---

## 3. The mechanism (exact terms)

CoW's settlement is the protocol's fee/gas **buffer** holder. Because users pay fees in the *sell token*, the settlement accumulates small balances of arbitrary tokens ("buffer"), which solvers may also internalise. To route through external venues a solver, inside a `settle()` transaction, makes the settlement emit `approve(router/helper, …)` interactions (or leaves a router approval in place). **The settlement therefore owns live ERC-20 allowances to every venue it has ever routed through** — including third-party solver helper contracts.

This is the template that produced two real CoW losses:

* **Feb-2023 (`SwapGuard`, ~$180k).** Attack orders made the settlement approve the `SwapGuard` helper, then pulled DAI out of the settlement. (`SwapGuard` `0xcd07a7695e3372acd2b2077557de93e667b92bd8` still appears in the settlement's approval history — 16 logs — but holds no live allowance for any token the settlement holds today.)
* **Nov-2024 (GlueX, CIP-55, $76,783).** A solver deployed a helper whose **`uniswapV3SwapCallback` was unrestricted**; anyone could call the callback with fake deltas naming the settlement as payer, so MEV bots drained the buffer in 67 txs. The DAO's own mitigation was a **$5k buffer cap** ("Settlement Contract Buffers" forum thread) — which is why this target is worth re-checking: the buffer is capped but the **allowance surface is not**.

The condition for a live drain is therefore narrow and testable:

> some currently-approved spender must (a) be callable by an unprivileged address and (b) execute `token.transferFrom(settlement, …)` using a `from` taken from **attacker-controlled calldata** (not `msg.sender`).

Everything below tests exactly that condition.

---

## 4. Live-state assessment

### 4.1 Settlement (block 26,253,971)

| Field | Value |
|---|---|
| `eth_getCode` size | 16,165 bytes (unchanged, no proxy) |
| Native balance | 0.027762249 ETH |
| Public entry points that move funds | `settle()` and `swap()` are **`onlySolver`**; `invalidateOrder`/`setPreSignature` require `owner == msg.sender`; `freeFilledAmountStorage`/`freePreSignatureStorage` are `onlyInteraction`; `simulateDelegatecallInternal` reverts by construction (`revertWith`). Source read. |
| Owned allowances | see 4.3 |

### 4.2 Buffer (block 26,253,971, DefiLlama prices)

| token | amount | USD |
|---|---|---|
| USDC | 591.906958 | 591.66 |
| stETH | 0.10075151 | 241.48 |
| CRV | 590.67710720 | 212.43 |
| MKR | 0.12389807 | 205.95 |
| GNO | 1.75515343 | 198.33 |
| PYUSD | 183.55167200 | 183.58 |
| WBTC | 0.00205599 | 167.44 |
| USDe | 132.55884607 | 132.47 |
| UNI | 17.80430325 | 127.37 |
| USDT | 118.67155800 | 118.56 |
| WETH | 0.04430481 | 106.30 |
| wstETH | 0.03429350 | 102.61 |
| USDS | 94.53080976 | 94.53 |
| rETH | 0.02863898 | 80.64 |
| TUSD | 73.16408983 | 73.05 |
| CVX | 28.12401176 | 69.39 |
| sDAI | 38.76370734 | 45.83 |
| DAI | 39.81926376 | 39.82 |
| AAVE | 0.26206305 | 38.61 |
| BAL | 261.52955661 | 32.32 |
| cbETH | 0.00966411 | 26.50 |
| LDO | 21.21482148 | 8.18 |
| PEPE | 1 491 429.500 | 7.52 |
| COMP | 0.30411994 | 7.39 |
| LUSD | 5.24296670 | 5.26 |
| EURS | 5.23 | 5.85 |
| SHIB | 838 417.30 | 4.28 |
| COW | 23.07950529 | 3.10 |
| XAUt | 0.00024100 | 0.97 |
| LINK | 0.04208910 | 0.51 |
| *(imBTC, SLP)* | *0.00132041 / 50 142* | *unpriced* |
| **TOTAL** | | **$2,931.92** |

The buffer is **volatile block-to-block** (solver internalisation + daily fee sweeps): a read four hours earlier gave ≈$1.5k and the CI read gave the same ~$2.9k shape. Raw JSON: `analysis/buffer_valuation.json`, `ci-out/live_state.json`.

### 4.3 The settlement-owned allowance surface (the real correction to pass5)

Enumerated by decoding every `Approval(owner = settlement)` log via Etherscan V2 `getLogs` with **recursive bisection over the 1000-result cap** (see `analysis/scan_full.py`, `analysis/scan_per_token.py`).

* **221,541** approval logs, **104 distinct spenders**, **2,532 distinct tokens**, blocks **12,959,355 → 15,450,000+** (global sweep) plus per-token sweeps for the tokens the settlement holds. (`analysis/spender_census.json`, `analysis/approvals_raw.jsonl.gz`.)
* **399 live `(spender, token)` pairs** across **72 distinct spenders** (of the 104 ever approved) where `allowance(settlement, spender) > 0` **and** the settlement's `balanceOf(token) > 0` (`analysis/material_surface.py`, full list in `analysis/material_surface.json`).

Spender families (Etherscan contract names, `analysis/spender_census.json`):

| family | examples | pull semantics | verdict |
|---|---|---|---|
| DEX routers | `UniswapV2Router02` ×2, `SwapRouter` (Uni V3), `SwapRouter02` (Universal), `AggregationRouterV3/V4/V5`, `ZeroEx` proxy, `TokenTransferProxy` ×2 (Paraswap), `AugustusSwapper`, `Vault` (Balancer), `DODO`, `PancakeRouter`, `DXswapRouter` | `transferFrom(msg.sender, …)` / `authenticateFor(funds.sender)` / `onlyOwner` | **closed** (source + fork) |
| Curve / Vyper pools (~60 of the 104) | `Vyper_contract` ×many, `MassetProxy` (mStable) | pool pulls from `msg.sender` | **closed** |
| RFQ / intent venues | `KyberSwapRFQ`, `BebopSettlement`, `HashflowRouter` (current `0x55084ee0`), `SwapFacade`, `MultiplexFeature`, `UniswapV3Feature`, `Swap` (AirSwap) | maker/MM signature over the order; taker = `msg.sender` | **closed** (source) |
| Solver helper `CowExecutor` ×2 | `0x2FbB05d2…`, `0xf3fc03f5…` | `onlyCowSettlementContract` (`require(msg.sender == cowSettlementContract)`) | **closed** (source + fork) |
| Solver helper `0x1d94BedC…` (unverified) | generic V3/V2 router | `uniswapV3SwapCallback` validates `msg.sender` is a real V3 pool; payer = entry `msg.sender` | **closed** (fork: `"UNIV3R: bad pool"`) |
| Solver helper `0x0500001f…` (unverified) | generic router | direct callback call does not move funds | **closed** (fork) |
| **Legacy `HashflowRouter` `0xF6a94dfD…`** (unverified) | 2023 CoW-hack helper | pulls base token from **calldata `trader`** *before* the pool's MM-signature check | **latent** — needs a valid MM-signed quote with `trader = settlement` (§7) |
| `SwapGuard` `0xcd07a769…` (2023 hack) | 16 historical logs | no live allowance for any held token | closed |
| `0xc0e82c1e…` (2023 attacker contract) | `eth_getCode == 0x` | empty | closed |

**Every live spender was resolved to a known contract family; no unclassified spender remains.**

### 4.4 User approvals to the settlement

`Approval(owner = *, spender = settlement)` = **434 logs** ever. The settlement's only fund-movement entry points are `settle()`/`swap()` (`onlySolver`) — there is no permissionless `transferFrom` path, so these allowances are not drainable either. Users normally approve `GPv2VaultRelayer` `0xc92e8bdf79f0507f65a392b0ab4667716bfe0110`, whose `transferFromAccounts` is `onlySettlement`.

---

## 5. What an attacker can / cannot do

**Cannot (proven):**
* `USDC.transferFrom(settlement, attacker, …)` directly → reverts (attacker is not the approved spender).
* Balancer `Vault.swap(s, funds.sender = settlement, …)` → reverts at `authenticateFor(funds.sender)`.
* `UniswapV2Router02.swapExactTokensForTokens(…)` → pulls from `msg.sender`; settlement balance unchanged.
* `CowExecutor.guardedUncheckedCall / guardedUnlimitedApprovedInteractionCall` → revert (`onlyCowSettlementContract`).
* `0x1d94BedC.uniswapV3SwapCallback(a0, a1, abi.encode(settlement))` from a fake pool → reverts `"UNIV3R: bad pool"`; from a real pool the helper is only reachable through its own `msg.sender`-bound entry.
* `0x0500001f.uniswapV3SwapCallback(…)` called directly → fails, settlement unchanged.
* Legacy `0xf6a94dfD.tradeRFQT` with the 2023 calldata → `"HashflowRouter: Quote has expired"`; with the expiry bumped but the old signature → `"ERC20: transfer amount exceeds balance"` on the `transferFrom(settlement, …)` (i.e. the pull executes *before* the pool's signature check, but the tx reverts without a valid quote).
* Settlement entry points (`setPreSignature`, `invalidateOrder`, `freeFilledAmountStorage`, `simulateDelegatecall*`) → gated / view / revert-by-design.

**Could (conditional, unproven):** obtain a Hashflow RFQ quote **signed by an authorised market maker with `trader = GPv2Settlement`** and submit it to the still-live legacy router `0xF6a94dfD…`, which pulls the base token from `trader`. Costs are gas only; the size is the settlement's balance of that base token (up to ≈$2.9k for the whole buffer, less for a single token).

---

## 6. PoC / fork verification

Foundry project `poc/` (vendored `lib/forge-std`), forks mainnet at **block 26,253,971**, read-only.

```
poc/test/CoW.t.sol            8 tests  — approval surface, direct pull reverts, Balancer spoof reverts,
                                         Uni V2 does not touch the settlement, gated entry points,
                                         buffer snapshot, GlueX template model, approved-spender control
poc/test/GlueX.t.sol          5 tests  — helper allowances live; 0x1d94 callback guarded ("UNIV3R: bad pool");
                                         0x0500001f callback does not drain; CowExecutor entries guarded;
                                         direct transferFrom reverts
poc/test/LegacyHelper.t.sol   2 tests  — legacy Hashflow helper: allowances live; 2023 calldata replay reverts
poc/test/HashflowLegacy.t.sol 2 tests  — expiry-bumped replay: pull path executes but tx reverts (no valid quote)
                             = 17 tests, 17 PASS / 0 FAIL
```

Notable passing negative results (raw revert data recorded by the tests):

* `0x1d94BedC…uniswapV3SwapCallback` → `Error("UNIV3R: bad pool")` (84-byte unpadded payload).
* `0xf6a94dfD…f0210929` with expiry bumped → `Error("ERC20: transfer amount exceeds balance")`, SUSHI balance unchanged (810.573933664125177194 before and after).
* `CowExecutor.guardedUncheckedCall` / `guardedUnlimitedApprovedInteractionCall` → revert.

CI (public GitHub Actions, `artsbykriss/ca-zombie-ci`): **https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39960095505** (17/17 PASS; first run `39921142500` was the 8-test version). `ci/run.sh` additionally dumps the live buffer + allowance snapshot to `ci-out/live_state.json`.

Gas: the drain-shaped calls, if they ever succeeded, are a single ~120–200k-gas transaction (~$1–3 at 1 gwei), so *any* material buffer would be worth draining — the barrier is the auth model, not gas.

---

## 7. Verdict, residual and latent risk

**Verdict.** `GPv2Settlement`'s live allowance surface is **much larger than pass5 reported** (~400 live pairs to ~104 spenders, including solver helpers), but **no unprivileged drain path is open today** — proven on a fork for the strongest candidates and by source for the rest. **E-U = $0.00 (high confidence).**

**Latent / residual (the real finding).**
1. **Legacy Hashflow router `0xF6a94dfD0E6ea9ddFdFfE4762Ad4236576136613`.** Still live and unpaused, holds a **max allowance** from the settlement for WETH/DAI/USDC/USDT/WBTC/LINK/UNI/AAVE/CRV/BAL/MKR/LDO/PEPE/cbETH/COMP (and more), and its `tradeRFQT`/`f0210929` flow executes `baseToken.transferFrom(quote.trader, …)` where **`trader` is a calldata field**, *before* the pool verifies the MM signature. The **current** HashflowRouter (`0x55084ee0…`) was hardened to `transferFrom(_msgSender(), …)`; the **legacy** one was not. This is the exact 2023 CoW-hack helper and mechanism (`trader = settlement`). Exploiting it requires an authorised Hashflow MM to sign a quote naming the settlement as `trader` (the attacker requests it from the public RFQ API) — which the 2023 attacker did. Whether Hashflow still signs such quotes could not be tested read-only ⇒ **unproven**, medium confidence. **Recommended action (CoW): revoke `allowance(settlement, 0xF6a94dfD…)`; add a monitoring rule for new solver-helper approvals.**
2. **Structural GlueX exposure.** The DAO's own mitigation caps the buffer at ~$5k, so a future GlueX-style helper bug is bounded but still live — and the allowance *surface* (not the buffer) is unbounded. Any newly approved solver helper with an unrestricted callback re-arms the vector instantly.
3. **Settlement entry points are solver-gated, not owner-gated** — a single compromised solver key can already route arbitrary interactions; that is P (privileged), out of scope, but it is the delivery mechanism for the GlueX class.

**Re-arm triggers / monitors**
* A new `Approval(owner = 0x9008d19f…, spender = <unknown contract>)` where the spender is not a known venue.
* Any Hashflow quote with `trader = 0x9008d19f…` (or an MM signature for the legacy router).
* Any change to `authorizedPools` on `0xF6a94dfD…` / a misconfigured pool signer.
* A settlement-buffer read above ~$5k (the DAO's own cap) persisting across blocks.

**Blockers / caveats.** No transactions were sent; the Hashflow leg cannot be closed read-only without an MM quote. `imBTC`/`SLP` are unpriced (dust, likely illiquid). The approval census is complete for 0–15.5M blocks and for every token the settlement holds today; the global sweep of 15.5M→head was truncated by RPC/DNS flakiness (see §9), so a *previously unseen* spender could in principle appear in that window — the per-token sweeps of all held tokens bound that risk.

---

## 8. Methodology & sources

* **Live state**: `eth_call`/`eth_getLogs` via `NODEREAL_ETH_RPC_URL` and public RPCs (`ethereum-rpc.publicnode.com`, `eth.drpc.org`); `debug_traceTransaction` (callTracer) via `eth.drpc.org` to read the helper call/callback layouts.
* **Approval census**: Etherscan V2 `getLogs` with recursive bisection over the 1000-record cap (`analysis/scan_full.py`, `analysis/scan_per_token.py`, `analysis/scan_gap.py`).
* **Allowances/balances**: batched JSON-RPC `allowance`/`balanceOf` (`analysis/check_atrisk.py`, `analysis/material_surface.py`).
* **Pricing**: DefiLlama `coins.llama.fi/prices/current` (`analysis/buffer_value.py`).
* **Source**: Etherscan V2 `getsourcecode` for GPv2Settlement, Balancer Vault, ZeroEx, AggregationRouterV3, Paraswap TokenTransferProxy, HashflowRouter, CowExecutor, KyberSwapRFQ, BebopSettlement, SwapFacade, AirSwap Swap, DODO.
* **Prior art**: CoW forum *CIP-55: Slashing of the GlueX solver* and *Settlement Contract Buffers*; SolidityScan *CoW Swap Hack Analysis — Arbitrary Callable SwapGuard*; `zombie-hunt-iv/pass5/paymasters-intents.md` §2 (whose "no settlement-owned approvals" claim this folder corrects).

## 9. CI

* Run: **https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39960095505** (final, 17 tests, success) and **https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39921142500** (first, 8 tests, success).
* Artifact `ci-out/live_state.json` (buffer + allowance snapshot) is copied to `ci-out/`.

## 10. Files index

```
cow-gpv2/
├── README.md                       this file
├── summary.json                    machine-readable summary
├── ci/run.sh                       CI job: live-state snapshot → ci-out/
├── ci-log.txt                      CI log
├── ci-out/live_state.json          CI-produced buffer/allowance snapshot
├── poc/                            Foundry project (foundry.toml, lib/forge-std)
│   └── test/CoW.t.sol, GlueX.t.sol, LegacyHelper.t.sol, HashflowLegacy.t.sol
└── analysis/
    ├── spender_census.json         104 spenders with names + block ranges
    ├── approvals_raw.jsonl.gz      every Approval(owner=settlement) log (221,541)
    ├── material_surface.py/.json   399 live (spender,token) pairs
    ├── buffer_valuation.json       buffer priced at block 26,253,971
    ├── atrisk.json, live_allowances.json
    ├── scan_full.py / scan_per_token.py / scan_gap.py / scan_approvals_etherscan.py
    ├── check_atrisk.py / check_allowances.py / live_surface.py / material_surface.py / buffer_value.py
```

*Read-only research. Nothing in this folder is an instruction to transact. No secrets are stored here.*
