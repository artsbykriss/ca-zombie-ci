# Burve (Berachain) — Sherlock 2025-04-burve **H-5** acknowledged-unfixed fee capture — live extractability

**Date:** 2026-10-22 · **Chain:** Berachain (chain id 80094) · **Campaign:** ZH4-PASS4 / P4-02 (TIER 2 HIGH)
**Status:** read-only; PoC **fork-verified only**; **no mainnet transactions signed or sent**.

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why closed / open | Latent risk |
|---|---|---|---|
| **H-5's target: `src/single/Burve.sol`** (Kodiak UniV3 LP wrapper with immutable ranges + `collectAndCalcCompound()`) | **$0 — not deployed** | No instance exists on Berachain mainnet (only a bArtio **testnet** deploy). Nothing to attack. | **HIGH if ever deployed** — the fee-sniping bug is real and explicitly "won't be fixed" |
| **Live $32k target: `SimplexDiamond` `0xa1beD164…` (the *multi* "Omni-Pool")** | **$0** | Different product. The H-5 mechanism (V3 ranges / fee compounding) is **structurally absent**; the multi uses checkpoint-based fee accounting that excludes new depositors. Fork-proven. | LOW (rounding/composability) |
| All other Sherlock Highs (H-1…H-9) on the live multi | **$0** | Fixed in the live facets (verified in deployed source). | — |

### **Total live extractable now: $0.00 (E-U). Confidence: HIGH.**

The pass-4 headline ("Burve · Diamond `0xa1beD164…` → impl `0x223184e3…`; TVL $32,030; Sherlock H-5 acknowledged-unfixed") **conflates two different products.** H-5 is a finding about the *single-pair* Burve; the contract holding the $32k is the *multi-token* SimplexDiamond. The H-5 target is not deployed on Berachain.

---

## 2. The bug / mechanism (in exact terms)

### 2.1 What H-5 actually says

Sherlock contest **858** (`2025-04-burve`, report in `analysis/sherlock-report.md`), issue
[#288](https://github.com/sherlock-audit/2025-04-burve-judging/issues/288):

> **H-5: Attacker captures unclaimed fees by timing deposit with range re-entry and price manipulation** — *"This issue has been acknowledged by the team but won't be fixed at this time."*

Root cause, verbatim from the report: in `Burve/src/single/Burve.sol` → **`collectAndCalcCompound()`** (lines 848-920 of the audited commit `945f30bf`), fees are collected from the underlying **Uniswap-V3 / Kodiak positions** and compounded back into the immutable ranges. When the pool tick is **out of range** for all Burve ranges, only one side of the pair can be used to add liquidity; if the collected amount on the "wrong" side does not meet the minimum-liquidity threshold, **nothing is compounded** and the fees sit idle in the contract. An attacker:

1. deposits into Burve while the range is out of bounds,
2. swaps the underlying pool to push the price back **into** the range,
3. lets the next `collectAndCalcCompound()` (triggered by the withdraw path) convert the previously-idle fees into real liquidity,
4. withdraws, capturing a disproportionate share of the accumulated fees.

Immutable ranges make the state "inevitable" per the finding. **This is a `src/single/Burve.sol` bug** — a Kodiak/UniV3 LP wrapper.

### 2.2 Which contract is actually live

The Diamond at `0xa1beD164c12CD9479A1049f97BDe5b3D6EC21089` is **`src/multi/Diamond.sol` (`SimplexDiamond`)** — the multi-token "Omni-Pool". On-chain `facets()` returns 15 facets (`analysis/facets.txt`):

```
DiamondCutFacet      DiamondLoupeFacet   BaseAdminFacet      ValueFacet
ValueSingleFacet     AddTokenValueFacet  RemoveTokenValueFacet QueryValueFacet
SwapFacet            SimplexAdminFacet   SimplexSetFacet     SimplexGetFacet
LockFacet            VaultFacet          ValueTokenFacet
```

There is **no single-Burve facet**. Its selectors (`queryTVL()` `0x3a2aabcc`, `getInfo()` `0x5a9b0b89`) do not exist on the Diamond — asserted in the PoC (`test_liveTargetIsNotSingleBurve`).

The multi design has **no Uniswap-V3 positions, no tick ranges and no `collectAndCalcCompound()`**. Grepping the live facet sources for `collectAndCalcCompound | TickRange | uniswapV3MintCallback | compoundedNominalLiq` returns **zero hits** (`analysis/livef/**`). The H-5 mechanism cannot exist here.

### 2.3 The multi's fee accounting (why the analogous attack is closed)

The multi's fees live in per-closure checkpoints (`Closure.earningsPerValueX128`) and per-user checkpoints (`Asset.earningsPerValueX128Check`). Every value operation:

1. `Closure.trimAllBalances()` — recognises pending ERC-4626 yield into `earningsPerValueX128` using the **pre-operation** `valueStaked` as denominator;
2. `Closure.finalize(...)` — for a deposit, `addEarnings(tax)` is applied **before** `valueStaked += value` (the H-4 fix, present in the live source);
3. `AssetBookImpl.add/remove` → `collect()` — snapshots the caller's checkpoint **before** changing their `value`.

So a brand-new depositor's checkpoint equals the current (post-trim) checkpoint and their `value` is added afterwards ⇒ **zero share of pre-existing fees**. This is the exact analogue of H-5's "deposit just before the windfall" and it is structurally impossible here. (Fork-proven in §7.)

---

## 3. Live-state assessment (every relevant address, read at explicit blocks)

**Block pins:** `27827331` (facets), `27827918` (closures/tokens), `27827952` (TVL), `27828119` (vault custody), `27828532` (fork tests).

| Item | Value | Evidence |
|---|---|---|
| Diamond | `0xa1beD164c12CD9479A1049f97BDe5b3D6EC21089` (203 B proxy) | `eth_getCode`, `facets()` |
| Created | block `6660733` (2025-06-20), tx `0xd46c12d3…`, deployer `0xbe7dc5cc7977ac378ead410869d6c96f1e6c773e` | Etherscan V2 `getcontractcreation` |
| Facets | 15 (see §2.2); impl `0x223184e3a571eaba246dc3f23807423c45ae11bd` = **SimplexAdminFacet** | `analysis/facets.txt` |
| `owner()` | `0xEAD30c685F6B4817722018E3205c5f2edD5403DB` (a 2.18 kB contract, deployed by the same deployer) | `0x8da5cb5b` |
| Tokens (9) | USDC.e, USD₮0, BUSD, NECT, USDe, USDA, MEAD, rUSD, BYUSD | `getTokens()` |
| Closures | 511 enumerated; ~24 hold non-dust value (cid 3,5,6,7,9,11,12,13,31,48,511…) | `getClosureValue(0..511)` |
| `defaultEdgeFeeX128` | `1.70e35` ⇒ **≈0.05 %** | `getSimplexFees()` |
| `protocolTakeX128` | `2.72e34` ⇒ **≈0.008 %** | `getSimplexFees()` |
| Vertices / vaults | 9 active ERC-4626 vaults (USDC.e `0x444868B6…`, USD₮0 `0xF2d2d55D…`, BUSD `0x7f2B60fD…`, NECT `0x474F32Eb…`, USDe `0xD628b5aB…`, USDA `0x0d1A3CE6…`, MEAD `0x82576213…` = **NoopVault**, rUSD `0x3000C6BF…`, BYUSD `0x2948609C…`) | `viewVaults(token)` |
| Diamond token balance | **0** for all 9 (custody is inside the vaults) | `balanceOf(Diamond)` |
| Native BERA | 0 | `eth_getBalance` |
| Locks | **no token locked** (`isLocked` = false × 9) | `0x4a4fbeec` |
| Admin gates | `transferOwnership/acceptOwnership`, `addVertex`, `addClosure`, `withdraw`, `set*`, `addVault/acceptVault/vetoVault/removeVault/transferBalance/hotSwap`, `lock/unlock`, `addLocker/addUnlocker` — **all `AdminLib.validateOwner()`** | live facet sources |

**TVL (two independent methods):**

| Method | Block | USD |
|---|---|---|
| Closure accounting (`getClosureValue` → `AdjustorLib.toReal` → DefiLlama prices) | 27827952 | **$33,583.48** |
| Ground-truth vault custody (`balanceOf(Diamond)` → `convertToAssets`) | 27828119 | **$35,313.64** |

Breakdown (custody method): USDC.e $7,854.58 · USD₮0 $13,565.83 · BUSD $6,193.98 · NECT $1,600.25 · USDe $1,953.76 · USDA $1,507.72 · MEAD $19.77 · rUSD $1,205.88 · BYUSD $1,411.88.
DefiLlama's `burve` slug reports **$32,030** — consistent (same order; small block/price skew). **The cap is ≈ $32–35 k.**

---

## 4. Is H-5's target deployed? (the decisive question)

**No.** The single-pair Burve (`src/single/Burve.sol`, ERC-20 symbol pattern `<t0>-<t1>-SLP-KDK`, name pattern `<t0>-<t1>-Stable-KodiakLP`, distinctive views `queryTVL()`/`getInfo()`) is **not deployed on Berachain mainnet today**. Evidence (full detail in `analysis/child-single-burve-hunt.md`):

- **Project history:** the only single-Burve Foundry broadcast in `itos-finance/Burve` (all 44 branches) is **bArtio testnet, chain 80084** → `0xda5826868528ace919721ef324a69c16b9486d08`. **No `broadcast/**/80094/**` exists**; every mainnet deployment JSON references the multi Diamond.
- **Team deployer EOA** `0xbe7dc5cc…` deployed 66 mainnet contracts; **none** answers `queryTVL()`, `getInfo()`, or exposes a name/symbol matching the single-Burve pattern (`analysis/dpl-all-creations.txt`, `analysis/probe.py`).
- The testnet address has **no code** on 80094 at block 27,828,475.
- Berascan search: `SLP-KDK` → only unrelated tokens; `Stable-KodiakLP` → 7 Balancer pools; `Burve` → 5 EOAs + an Euler factory. All rejected by `queryTVL()`.
- DefiLlama `burve` **and** `burve-protocol` adapters both target **the multi Diamond**; `yields.llama.fi` has zero Burve pools; `burve.fi` lists only "Omni-token Pools"; docs give no single-pool address.

**Confidence ~85 %.** The residual is the absence of a fully exhaustive keyless Berachain ERC-20 name index; a deployed-but-empty, unindexed single Burve cannot be excluded at 100 %. If one is deployed **with funds and out-of-range ranges**, H-5 becomes live and real (see §9 monitors).

---

## 5. What an attacker can / cannot do (exact call paths)

**Cannot (all closed):**

| Path | Gate | Live value |
|---|---|---|
| Owner/admin paths (`addClosure`, `set*`, `addVault`, `hotSwap`, `transferBalance`, `withdraw`, `lock/unlock`, …) | `AdminLib.validateOwner()` | owner = `0xEAD30c68…` |
| Capture pre-existing fees by depositing then withdrawing | checkpoint accounting | proven 0 (`test_h5_feeSniping_afterFees_isZeroCapture`) |
| Capture fees by injecting a windfall yourself | you must pay the fee you'd capture (fraction < 1) + 2 taxes | proven net loss (`test_h5_selfFundedFeeInjection_notProfitable`) |
| H-7 NoopVault donation (MEAD) | the Diamond owns **100 %** of the NoopVault's shares | donation accrues to Burve users; donor loses 100 % (`test_noopVaultDonation_attackerLoses`) |
| H-5 single-Burve fee sniping | **target not deployed** | n/a |
| Reentrancy | `ReentrancyGuardTransient` + `RFTLib` lock on every value/swap facet | — |

**Can (permissionless, but value-neutral):** `addValue`, `removeValue`, `addValueSingle`, `removeValueSingle`, `addSingleForValue`, `removeSingleForValue`, `swap`, `simSwap`, `collectEarnings` (self-scoped), `queryValue`, `transfer/approve/transferFrom` of the BVT value token. These are the only unprivileged entry points and they are priced by the closure invariant; no arithmetic path to profit was found (residual rounding risk noted in §9).

---

## 6. Costs / capital

Nothing is extractable, so no capital question arises. For completeness: the unprivileged operations are ordinary stable-swap LP actions requiring only the pool tokens and gas on Berachain (sub-cent at ~3.5 Gwei); a fee-sniping attempt costs more than it can earn (PoC: −0.03 USDC on a 100 USDC round trip; −0.27 USDC on a 1000 USDC self-funded injection).

---

## 7. PoC / fork verification

Foundry project: `burve/poc/` (`foundry.toml`, `src/IBurve.sol`, `test/BurveLive.t.sol`). Forked from a **keyless public Berachain RPC** (`vm.createSelectFork(envOr("BERA_RPC_URL","https://berachain-rpc.publicnode.com"))`); no pinned block so each run reads current state.

```
Ran 5 tests for test/BurveLive.t.sol:BurveLiveTest
[PASS] test_liveState
[PASS] test_liveTargetIsNotSingleBurve
[PASS] test_h5_feeSniping_afterFees_isZeroCapture
[PASS] test_h5_selfFundedFeeInjection_notProfitable
[PASS] test_noopVaultDonation_attackerLoses
Suite result: ok. 5 passed; 0 failed
```

Key numbers (block 27828532):

- `test_h5_feeSniping_afterFees_isZeroCapture` — a whale swap produced real fees in cid 3 (`epv[USDC] = 979756560459551818548078016 > 0`); a **fresh** depositor's `queryValue` earnings were **`0` for both tokens**; the immediate round trip returned `99,999,970,031` for `100,000,000,000` in (**−29,969** wei = −0.03 USDC).
- `test_h5_selfFundedFeeInjection_notProfitable` — deposit 1000 USDC → attacker swaps 500 USDC (paying the pool fee) → withdraw: `1,000,000,000,000 → 999,999,733,759` (**−266,241** = −0.27 USDC).
- `test_noopVaultDonation_attackerLoses` — MEAD NoopVault: Diamond redeemable `19.773 → 119.773 MEAD` after a 100 MEAD donation; donor holds 0 shares and lost 100 MEAD.
- `test_liveState` — 9 tokens, 9 vertices, owner `0xEAD30c68…`, edge fee ≈0.05 %, all 9 vault addresses (incl. MEAD = NoopVault).

**CI runs:** see `summary.json` → `poc.ci_run_urls` (GitHub Actions on `artsbykriss/ca-zombie-ci`, workflow `poc.yml`). CI log: `burve/ci-log.txt`; artifacts: `burve/ci-artifacts/`.

---

## 8. Verdict and residual / latent risk

- **E-U (external unprivileged, live): $0.00 — HIGH confidence.**
- **H-O: $0** (LPs can always withdraw their own value via `removeValue`/`removeValueSingle`; that is self-service, not extraction).
- **P: ≈$33.6–35.3 k** — the whole TVL is only reachable by the owner/admin surface.
- **S: $0.**

**Residual/latent:**
1. **H-5 is real but undeployed.** If Burve ever deploys `src/single/Burve.sol` on Berachain (or another chain) with immutable ranges that go out of range, the acknowledged-unfixed fee sniping applies. This is a **monitor**, not a live E-U.
2. **Rounding/composability on the live multi.** The invariant math (`ValueLib`, `Erc4626` share accounting, `Reserve`) was audited (H-1…H-9, all fixed in the live source) but is not fuzz-proven here; a rounding bug would be LOW-value given a ~$33 k cap.
3. **NoopVault class.** MEAD uses a `NoopVault`; H-7 is closed today only because the Diamond owns 100 % of its shares. If a **new** NoopVault vertex is added while empty, the donation window reopens (needs admin action).

**Blockers to extraction:** none needed — the value simply isn't reachable by an unprivileged caller.

---

## 9. Methodology & sources

- Sherlock contest **858** (`2025-04-burve`) report + scope via `audits.sherlock.xyz/api/contests/858` (`analysis/sherlock-858.json`, `analysis/sherlock-report.md`); audited commit `945f30bf…`; audited `src/single/Burve.sol` at `analysis/single-Burve.sol`.
- Etherscan V2 (chain 80094) for verified source/ABI of the Diamond and all 15 facets (`analysis/facets-src/*.parsed.json`, `analysis/livef/**`, `analysis/live/**`).
- Direct `eth_call`/`eth_getCode`/`eth_getBalance` against keyless public Berachain RPCs (publicnode / rpc.berachain.com / drpc) via `analysis/bera.py`, `analysis/diamond_state.py`, `analysis/tvl.py`, `analysis/custody.py`, `analysis/probe.py`.
- DefiLlama `protocols`/`coins.llama.fi` for the `burve` slug and token prices.
- Foundry 1.8.5 fork tests (CI) — `burve/poc/`.

### Caveats & limitations
- Point-in-time **2026-10-22**; re-read balances before acting. Nothing here is an instruction to transact.
- The single-Burve negative is ~85 % confident (no exhaustive keyless ERC-20 name index on Berachain).
- I did **not** attempt to exploit the live multi for rounding bugs beyond the H-5 class; a fuzzing campaign on `ValueLib` is the natural next step if the cap ever grows.
- I did **not** deploy `src/single/Burve.sol` on a fork to demonstrate H-5 directly (it would require a Kodiak pool + exact range configuration); the mechanism is taken from the audit report + source, and its **absence** from the live target is what matters.

### Files index
```
burve/
├── README.md                     ← this file
├── summary.json                  ← machine-readable verdict
├── analysis/
│   ├── sherlock-report.md, sherlock-858.json, single-Burve.sol   ← H-5 + audited single source
│   ├── facets.txt                ← live facet map (addresses × selectors)
│   ├── diamond-abi.json, diamond-sources.json                    ← live multi bundle
│   ├── live/ , livef/            ← live facet sources (unique + per-facet)
│   ├── closure-values.json, tvl-out.txt, tvl-usd.json            ← closure/TVL dumps
│   ├── custody.json              ← ground-truth vault custody
│   ├── dpl-all-creations.txt, deployer-code-sizes.json, probe.py ← deployer census
│   ├── child-single-burve-hunt.md← single-Burve deployment hunt (child agent)
│   └── bera.py, diamond_state.py, tvl.py, custody.py, rpc.sh     ← read-only tooling
├── poc/                          ← Foundry fork PoC (5/5 PASS)
├── ci/run.sh                     ← CI live-state re-dump → ci-out/
├── ci-out/                       ← CI artifacts
├── ci-log.txt, ci-artifacts/     ← downloaded by ci/ci-run.sh
└── summary.json
```
