# Z3-H17 · Aero Lite (Arc, chain id 5042) — Metadex "Slipstream" CL deployment deep dive

**Date:** 2026-10-16 · **Chain:** Arc (5042) · **Status:** read-only; PoC fork-verified only; no mainnet transactions
**Scope:** CLFactory `0xb89Df768aF2CFE637ceB352c587Fe8edAf491d03` (35 pools) · CLPool impl `0x0Df9fc8730eeC048e9832B31B4bFf4351158e19B` (+ linked library `CLPoolNonSwapPath` `0x22557c01cf181b14b925d83008ed1d19150cd50b`) · FactoryRegistry `0xCe44907DC45D3BFa3f5f6035B0e6E8B22D780A42` · defaultSwapHook `0xaAf164008441F112e2858d9F7A2dB1B84b1E415` · clPoolTape `0x967f5352A6448e22D7361E149103350c49345Ee9` · owner Safe-style proxy `0x6b031ac7420c2730E65eD9F8B7b2BD0648be45c4`
**Method:** verified multi-file source fetch (Etherscan V2 chainid 5042), bytecode-identity compile-checks (incl. linked library), full live enumeration (35 pools), 6 fork tests, upstream identification (`dromos-labs/metadex-slipstream-public` — source-identical).

---

## 1. TL;DR

| target | live extractable (unprivileged) | why closed / open | latent risk |
|---|---|---|---|
| CLPool (mint / burn / collect / flash; gauge/fees paths) | **$0** | deployed factory + pool + linked library are **byte-identical** (modulo embeddeds) to the published `dromos-labs/metadex-slipstream-public` sources; fork-proven: 6-arg `collect` → `NNFT`; `stake` → `NG`; `collectFees` → `NG`; `setGaugeAndPositionManager` → `NGF`; no `skim`; flash payment enforced before/after balance (fork reverts at native-token transfer) | none |
| Staking / gauges | **$0** | **there are no gauges**: factory `voter() = 0x0`, registry `targetFactoryToGaugeFactory(factory) = 0x0`; every pool has `gauge = 0`, `nft = 0`, `stakedLiquidity = 0`. `setGaugeAndPositionManager` requires `msg.sender == registry gaugeFactory` = 0 → unreachable | if governance registers a gauge factory later (P-class), staking appears |
| Factory admin (fee managers, swap hook, tape, owner) | **$0** | all setters owner/manager-gated to Safe-style proxy `0x6b031ac7…`; fork-proven `setDefaultSwapHook` / `setOwner` / `setSwapFeeManager` revert for a fresh caller | P: `swapFeeManager` can set an arbitrary swap hook (affects fees ≤10% cap) |
| Swap hook `0xaAf16400…` (default for every pool) | n/a | admin-set contract; fee views bounded (pool0 200 pips, pool1 400 pips); called via `try/catch` with fallback to tick-spacing fee | trusted component; a malicious hook is P-class |
| NPM | none found | no `nft` is set on any pool; positions are managed via the pool's `msg.sender`-scoped paths (or a periphery that never registered); nothing parked | if an NPM-style manager is later registered via a gauge factory (P), positions become manageable through it |

**Total live E-U extractable now: $0.00 — confidence high** (byte-identity of all deployed code + absence of any gauge/voter/NFT-manager layer + fork-proven admin/unprivileged negatives).
TVL is LP principal (H-O): **$3,202,689 priced across 35 pools** vs DefiLlama $3.20M — top pools: cirBTC/USDC $1.11M · WETH/USDC $1.10M · USDC/EURC $476k · WETH/cirBTC $349k · USDC/GBPA $161k. Main reads at block 26,198,229; fork tests at block 26,205,724.

## 2. What is deployed, exactly

Aero Lite is the **Metadex Slipstream** concentrated-liquidity stack (Dromos Labs' 2026 CL core, `dromos-labs/metadex-slipstream-public`), deployed on Circle's Arc. Source-identity was confirmed file-by-file (CLFactory/CLPool/CLPoolNonSwapPath/SwapHookLib IDENTICAL to repo main), then compile-checked against chain code:
- CLFactory runtime `==` compiled source except the embedded `poolImplementation` immutable (0 → `0x0Df9fc…`).
- CLPool runtime `==` compiled source except the linked library address → `0x22557c01…` (`CLPoolNonSwapPath`, an external DELEGATECALL library).
- Library runtime `==` compiled source except the self-address constant.

Security-relevant surface (all reviewed in source):
- Pool: open-price `createPool(tokenA,tokenB,tickSpacing,sqrtPriceX96)` (atomic create+initialize, no front-run window), `mint` (callback `msg.sender`, balance check `M0/M1`), `collect` 5-arg (`owner = msg.sender`), `collect` 6-arg + `burn` 4-arg (`_onlyNftManager`), `burn` 3-arg (`owner = msg.sender`), `stake` (`_onlyGauge`), `collectFees(recipient)` (`_onlyGauge`), `settleToBlock` (`_onlyGauge`), `setGaugeAndPositionManager` (`CL.validateGaugeFactory(registry, factory)` → `require(msg.sender == targetFactoryToGaugeFactory(factory))`), `swap`/`flash` callbacks to `msg.sender` with before/after balance enforcement (`IIA`, `F0/F1`), swap-hook fee path via `factory.getPoolSwapHook(pool)` with ≤10% cap and try/catch fallback.
- Factory: `owner`, `swapFeeManager`, `unstakedFeeManager` setters (self-gated to current holder), `setVoter` (owner-once), `setDefaultSwapHook`/`setPoolSwapHook` (swapFeeManager), `setDefaultUnstakedFee` (≤50%), `enableTickSpacing` (owner), `getUnstakedFee` short-circuits to `0` while `voter == 0` (no voter ⇒ no unstaked fee).
- Registry: `registerFactories` (permanent factory↔gauge-factory link), `registerTarget` (callable by an approved target factory), `targetFactoryToGaugeFactory`, `emissionCap`. No gauge factory is linked to this CLFactory (live read = 0).

## 3. Live-state assessment (2026-10-16)

- **Factory** `0xb89Df768…`: `owner() = 0x6b031ac7420c2730E65eD9F8B7b2BD0648be45c4`, `voter() = 0x0`, `poolImplementation() = 0x0Df9fc87…`, `factoryRegistry() = 0xCe44907D…`, `swapFeeManager() == unstakedFeeManager() == owner`, `defaultUnstakedFee() = 100,000`, `defaultSwapHook() = 0xaAf16400…`, `clPoolTape() = 0x967f5352…`, `discountRegistry() = 0x0`, `allPoolsLength() = 35`, tickSpacings `[1, 50, 100, 200, 2000, 10]`.
- **Pools:** 35 unique (enumerated `allPools(0..34)`), **all** with `gauge = 0`, `nft = 0`, `stakedLiquidity = 0`; 33 with liquidity > 0. Priced balances sum to **$3,202,689**: cirBTC/USDC $1,111,583 · WETH/USDC $1,099,758 · USDC/EURC $476,423 · WETH/cirBTC $349,305 · USDC/GBPA $161,085 · rest dust. Full table: `analysis/aerolite/aerolite_rank.json`.
- **Token behaviour on Arc:** USDC (`0x3600…0000`) and the Circle-token family route through native system precompiles (`0x1800…0001 isBlocklisted` etc.); Foundry forks cannot execute these calls (`OpcodeNotFound`), so **no token transfer is simulatable on an Arc fork**. This is an environment limitation, not a protocol finding.
- **Activity:** pool0 (`0xbe080aC3…`, USDC/EURC) shows a stream of `flash(…)` calls from one contract `0x863d20694e1e74a96a149fa21befe13fbbf529c6` (flash-loan/arb bot) — the flash path is heavily exercised on mainnet and pays fees.

## 4. What an attacker can / cannot do

**Cannot (fork-proven):**
- `pool0.collect(recipient, …, owner)` 6-arg → revert `NNFT` (T4).
- `pool1.stake(...)` → revert `NG`; `pool1.collectFees(attacker)` → revert `NG` (T3).
- `pool1.setGaugeAndPositionManager(attacker, attacker)` → revert `NGF` (T3).
- `factory.setDefaultSwapHook(attacker)` / `setOwner(attacker)` / `setSwapFeeManager(attacker)` → revert (T3).
- Any extraction via the staking layer: no gauge exists; registry maps the factory to gaugeFactory `0x0`, so `setGaugeAndPositionManager` can never succeed (T2).

**Can:**
- Create pools at arbitrary initial prices (only affects pools the attacker seeds).
- Use `flash` with repayment (fee = hook/tickSpacing fee, capped ≤10%); without repayment the pool's before/after balance check reverts (`F0/F1`; on Arc forks the revert surfaces earlier at the native-token transfer, `TF`).

## 5. PoC / fork verification

`poc/test/AeroLite.t.sol` (`AeroLiteH17Test is ForkHelper`), 6 tests, **6/6 PASS** locally (fork `rpc.mainnet.arc.io`, block 26,205,724). Structural: all pools gauge/nft zero; registry gauge factory zero; fee views 200/400 pips ≤ 10% cap; hook wired `0xaAf16400…`; admin/unprivileged negatives as in §4.
ForkHelper note: the parent's `poc/src/ForkHelper.sol` does not compile with the vendored forge-std (duplicate `VM_ADDRESS`); local runs used an identical-semantics patched copy in a scratch project; the delivered test imports `ForkHelper` as specified.

## 6. Verdict and residual/latent risk

- **E-U (external unprivileged, live): $0.00 — high confidence.** The deployed binary is source-identical to the published Metadex Slipstream repo; the protocol layer that could hold/manage LP positions (gauge factory, voter, NPM registration) is not configured: `voter = 0`, registry gauge factory = 0, all pools `gauge = 0 / nft = 0 / staked = 0`.
- **E-U-conditional:** none live. Re-arm conditions (all privileged): (a) governance registers a gauge factory for this CLFactory in the registry → gauges/NPM wiring possible; (b) `swapFeeManager` points a pool at a malicious hook (fees ≤10% cap, no principal risk); (c) NPM-style periphery registered via a future gauge factory.
- **H-O:** $3.20M LP principal (self-service burn/collect via pool paths; `withdraw`-class liveness is unconditional).
- **P:** factory/registry/hook/tape admin (Safe-style owner `0x6b031ac7…` and its managers); the `clPoolTape` recording contract.
- **S:** donation amounts sent directly to pools (no `skim`); dust positions.
- Caveats: Arc's native-token precompiles block in-fork transfers (flash-repayment positive test replaced by a fee-bounds test); the hook and tape contracts are unverified single-purpose helpers (admin-set, reviewed only at call-site level); Etherscan sources are verified (multi-file) and were independently byte-matched.

## 7. Methodology & sources

Read-only: `cast`, Etherscan V2 (chainid 5042), public RPC `rpc.mainnet.arc.io`, DefiLlama price API, GitHub `dromos-labs/metadex-slipstream-public`, forge/solc 0.7.6 compile + byte compare. Fork tests against live state, 6/6 pass. No keys, no transactions.

**Files:** `README.md` · `summary.json` · `analysis/aerolite/bytecode-verification.md` · `aerolite_pool_list_v2.json` · `aerolite_details_flat.json` · `aerolite_balances_out.json` (＋ retry) · `aerolite_prices.json` · `aerolite_rank.json` · `factory.json` + `factory-src/` · `poc/test/AeroLite.t.sol`.
