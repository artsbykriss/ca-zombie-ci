# ZH4-PASS5 · P5-03 — **Spot hook (AEGIS DFM)** deep-dive — Unichain

**Date:** 2026-10-23 · **Chain:** Unichain (130) · **Status:** read-only; PoC fork-verified only; **no mainnet transactions**
**Targets:** hooks `0x88C9fF9FC0B22cCa42265d3f1D1C2C39E41cDACC` + `0xA0b0D2d00fD544D8E0887F1a3cEDd6e24Baf10cc`
**Block pinned:** Unichain `61,991,016` (CI fork) / `61,989,337` (state dump)
**Method:** verified-source extraction (Etherscan V2 chainid 130) + full read of all 6 core contracts + read-only `eth_call`/`eth_getLogs` + Foundry fork PoC on GitHub Actions.

> Read-only research. Nothing here is an instruction to transact. PoCs run on local forks only.

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why closed | Latent risk |
|---|---|---|---|
| **Spot hook #1** `0x88C9fF9F…` (flags `0x1acc`) + FRLM `0xa7b3e230…` | **$0** | `reinvest` is permissionless but only re-adds the FRLM's **own** fee dust as protocol-owned LP (shares minted to the FRLM, never the caller); fabricated keys are inert; every value-out function is `onlyPolicyOwner`/`onlySpot`/`onlyPoolManager` | **P**: policy owner can set fees/POL-share and withdraw protocol-owned liquidity (~$19 held) |
| **Spot hook #2** `0xA0b0D2d0…` (flags `0x10cc`) + FRLM `0xA7ce35E8…` | **$0** | same code family; `reinvest` take/burn/re-add verified not to profit the caller; position ownership not hijackable | **P**: policy owner can withdraw protocol-owned liquidity (~$3.4 k). **S/DoS**: over-accounted ERC-20 ledger can brick `reinvest` |

**Total live extractable now: $0.00 (E-U). Confidence: HIGH.**
Pooled TVL (the *ceiling*, not the prize): **$4,245,629** — hook#1 $2,412,526 + hook#2 $1,833,103 (independently re-derived from the Uniswap Gateway `topV4Pools` `totalLiquidity.value`, 2026-10-23).

The hook **cannot** reach the pooled TVL: it has no function that touches other LPs' positions. Its only powers are a bounded dynamic-fee override and a bounded `beforeSwap`/`afterSwap` delta (its own protocol fee).

---

## 2. The mechanism (exact)

**Project = AEGIS Dynamic Fee Mechanism (`labs-solo/AEGIS_DFM`).** Both deployed hooks are **byte-identical** to `main` (`src/Spot.sol`, `src/FullRangeLiquidityManager.sol` diff = empty) — no fix-vs-deploy gap. Hooks are **non-upgradeable** (EIP-1967 impl/admin slots both zero).

Five contracts per deployment: `Spot.sol` (the hook), `FullRangeLiquidityManager.sol` (FRLM, protocol-owned-liquidity vault + ERC-6909 share token), `DynamicFeeManager.sol`, `PoolPolicyManager.sol`, `TruncGeoOracleMulti.sol`.

- **Dynamic fee** = `base + surge`, clamped by policy to `[minBaseFee, maxBaseFee] = [10, 30_000]` ppm (0.001 %–3 %) with surge ≤ 3×base. The hook returns it as an LP-fee override (`Math.setDynamicFeeOverride`), and separately charges a **protocol fee** = `dynamicFee × polShare` (default 10 %) as a swap delta, minting ERC-6909 to the FRLM.
- **`reinvest(PoolKey)` is permissionless** (`external`, no modifier). Guards: `REINVEST_COOLDOWN = 1 days`, both `pendingFees ≥ MIN_REINVEST_AMOUNT = 1e4`, and a **TWAP guard** (`reinvestmentTwap = 60 s`, `tickRangeTolerance = 50` ticks). On success it `take`s + `burn`s the FRLM's ERC-6909 fees, re-adds a full-range position via the PositionManager, and mints ERC-6909 shares **to the FRLM** (`_mint(address(this), poolId, liquidityAdded)`).
- **v4 fee accounting (fork-verified):** `Hooks.beforeSwap` does `amountToSwap += hookDeltaSpecified`, then `afterSwap` does `swapDelta -= hookDelta`, so the swapper pays **exactly** the specified input and the hook fee is routed to the FRLM. Measured on the live ETH/AG pool: `ethIn == amountIn == 1e15`, and `FRLM 6909(id 0)` grew by exactly `amountIn × 2520ppm × 100000ppm = 252000000000` wei. The fee is real, non-zero and correctly accounted.

---

## 3. Live-state assessment

| Role | hook#1 | hook#2 |
|---|---|---|
| Hook (Unichain) | `0x88C9fF9FC0B22cCa42265d3f1D1C2C39E41cDACC` (flags `0x1acc`) | `0xA0b0D2d00fD544D8E0887F1a3cEDd6e24Baf10cc` (flags `0x10cc`) |
| PoolManager | `0x1F98400000000000000000000000000000000004` | same |
| PositionManager | `0x4529A01c7A0410167c5740C487A8DE60232617bf` | same |
| FRLM | `0xa7b3e2306a0B46dbdE3B533c4e2C3Be6a24352a3` | `0xA7ce35E886e58926Ad0C149f4cc558e27D458a2c` |
| PolicyManager / owner | `0xE072D3C7567D4B326dDdE0F77062E6758Aec0eE7` / `0xF0E74f35…0603` | `0xaaf29f2C…CDDa` / `0xF0E74f35…0603` |
| Oracle | `0xbe4F23B9488300c532A5d9d8D11B0b8163Be6ABF` | `0x22e086c085fbDA3214DB238F8a930d22228Facb5` |
| FeeManager | `0xD7deABAb9ECd3BcB3B89ab0cE2c84C8565bB8D98` | `0xe6768629156d4B713e266b87502fbeccc218a028` |
| `reinvestmentPaused` | `false` | `false` |
| Pools / TVL | 33 pools initialised, 5 funded, **$2,412,526** | 7 pools funded, **$1,833,103** |
| Hook code | verified, == `AEGIS_DFM@main` | verified, == `AEGIS_DFM@main` |
| EIP-1967 impl/admin slot | `0x0` / `0x0` (not upgradeable) | `0x0` / `0x0` (not upgradeable) |

**FRLM custody (the only hook-adjacent value):**
- FRLM#1: 8.565 USDC ($8.56) + 0.00003383 WBTC ($2.76) + 0.00319 ETH ($7.66) ≈ **$19**; **0 positions**; `accountedBalances == balanceOf` and `accountedERC6909Balances == PoolManager.balanceOf` exactly (no surplus, no phantom 6909).
- FRLM#2: ERC-20 6.15 USDC + 0.454 XRP-equivalents + dust; ERC-6909 605.92 USDC ($605) + 0.0034 WBTC ($278) + 185.7 XRP + 1 512 XPL + 1 334 DOGE + dust; **7 protocol-owned positions** (largest: ETH/WBTC 0.494 ETH + 0.01457 WBTC ≈ **$2,375**). Total ≈ **$3.4 k** (all protocol-owned, withdrawable only by the policy owner). `accountedERC6909Balances == PM.balanceOf` for every currency.
- Prices: DefiLlama 2026-10-23 — USDC $0.9994, WBTC $81,552.83, ETH $2,402.70. AG/AGS/XRP/XPL/DOGE on Unichain are **not priced** by DefiLlama (memecoins) — their USD contribution is ~$0.

**Privileged surfaces (P):** `setReinvestmentPaused`, `depositToFRLM`, `withdrawFromFRLM` (hook, `onlyPolicyOwner`); `deposit`, `withdraw`, `withdrawProtocolLiquidity`, `sweepExcessTokens`, `sweepExcessERC6909`, `setReinvestmentTwap`, `setTickRangeTolerance` (FRLM, `onlySpot`/`onlyPolicyOwner`); `setManualFee`, `setPoolPOLShare`, `setMin/MaxBaseFee`, `setSurgeFeeMultiplierPpm`, … (policy, `onlyOwner`); `refreshPolicyCache`, `setAutoTunePaused` (oracle, `onlyOwner`).

---

## 4. What an attacker can / cannot do

**Permissionless entries found:** `FullRangeLiquidityManager.reinvest(PoolKey)`, `FullRangeLiquidityManager.donate(PoolKey,uint256,uint256)`, `TruncGeoOracleMulti.increaseCardinalityNext(PoolKey,uint16)`, the ERC-6909 `transfer/transferFrom/approve/setOperator` of the FRLM's own shares, and the PM swap callbacks.

- **`reinvest` — cannot extract.** It always operates on a key whose `poolId` already carries `pendingFees` (fabricated/wrong-hook keys short-circuit at `total0 < 1e4` and return `false`). It converts the FRLM's ERC-6909 fees to ERC-20, adds a full-range position, and mints the shares to the FRLM. The caller receives nothing. It is additionally blocked while the spot tick deviates > 50 from the 60 s TWAP.
- **`donate` — pay-in only.** Verified: the caller's token delta equals the reported donation; nothing is returned.
- **No value-out for an unprivileged caller.** `sweepExcessTokens`, `sweepExcessERC6909`, `withdrawProtocolLiquidity`, `withdraw` all revert `UnauthorizedCaller` for a fresh address (fork-confirmed).
- **Position-ownership hijack is infeasible.** `_mintNewPosition` reads `positionManager.nextTokenId()-1` immediately after an atomic `modifyLiquidities`; the PositionManager's `ReentrancyLock` + v4's single PM lock prevent interleaving an extra NFT mint. Fork test: any position created by an attacker-triggered `reinvest` is owned by the FRLM.
- **Fee is bounded.** `[10, 30_000]` ppm base (max 3 %), surge ≤ 3×base; the override can never be 0 and never wraps the `OVERRIDE_FEE_FLAG`. `setManualFee`/policy setters are owner-only.
- **Gas griefing only:** anyone can call `increaseCardinalityNext` to grow a pool's oracle ring buffer (costs the caller gas; no value moved).

---

## 5. PoC / fork verification

Foundry project: `poc/` (`foundry.toml`, `src/SwapHarness.sol`, `test/Spot.t.sol`), vendored `lib/forge-std`.
Runs on Unichain fork via `vm.createSelectFork(vm.envOr("UNICHAIN_RPC_URL", "https://mainnet.unichain.org"))` (keyless public endpoint).

**Result: 11/11 PASS.**

| Test | What it proves |
|---|---|
| `test_pool_ids_match_live` | recomputed `poolId`s match the on-chain pools |
| `test_reinvest_hook1_fresh_caller_no_gain` | fresh caller triggers `reinvest` on a pool with live `pendingFees` → gains 0 tokens/ETH; 6909 ledger == PM balance; no ERC-20 surplus |
| `test_reinvest_hook2_fresh_caller_no_gain` | same, on the hook#2 pool with an **existing** position (take/burn/increase path) |
| `test_reinvest_position_never_owned_by_caller` | any minted position is owned by the FRLM, never the caller |
| `test_reinvest_fabricated_key_is_noop` / `test_reinvest_wrong_hook_key_is_noop` | arbitrary keys return `false`, move nothing |
| `test_privileged_functions_revert_for_attacker` | `sweepExcessTokens`/`sweepExcessERC6909`/`withdrawProtocolLiquidity` revert for a fresh caller |
| `test_dynamic_fee_nonzero_and_bounded` | live `base+surge > 0`, `< 1e6`, manual fee unset |
| `test_swap_applies_fee_and_attacker_cannot_profit` | swapper pays exactly the specified input; FRLM 6909 grows by exactly `amountIn×2520ppm×10 %` = 252 000 000 000 wei |
| `test_reinvest_twap_guard_blocks_after_price_move` | after a price-moving swap the TWAP guard refuses `reinvest` (`false`) |
| `test_donate_payin_only` | `donate` only debits the caller |

**CI run URL(s):** https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39916840187 (conclusion: success, 11/11 PASS). Fork block 61,991,016. Full log: `ci-log.txt`.

---

## 6. Verdict, residual & latent risk

**E-U = $0.00 (high confidence).** The pass-5 lead — "permissionless `reinvest` with custom `accountedBalances`/ERC-6909 accounting" — is real code but **not exploitable**: the custom ledgers are internally consistent (`accountedERC6909Balances == PoolManager.balanceOf` on every currency, verified live and post-reinvest), the re-added liquidity is protocol-owned, and every value-out path is gated. This matches the pass-5 grading ("LOW-MED — worth a dedicated fork audit").

**Latent / monitor:**
- **P (privileged):** the policy owner `0xF0E74f35…0603` (a contract; `admin() = 0x6CB1C9A1…c032`) can set `POL share` up to 100 % and manual fees up to 10 %, pause reinvestment, and withdraw all protocol-owned liquidity (~$3.4 k today). This is a **swapper/LP tax + protocol-liquidity key**, not a user-LP drain.
- **S / DoS:** `withdraw`/`withdrawProtocolLiquidity` transfer principal out **without decrementing `accountedBalances`**. On FRLM#2 `accountedBalances[USDC] = 118.07` while the real balance is `6.15`. A subsequent `reinvest` on a USDC pool can therefore revert (Permit2 pull > balance), silently bricking fee compounding. Non-attacker, no extraction.
- **Liveness:** the afterSwap `_tryReinvest` path can never create the first position (`_mintNewPosition` early-returns while the PM is unlocked), so compounding only happens if someone calls `reinvest` directly (once/day). An attacker *can* be that caller — but it only benefits the protocol.

**Ceiling caveat:** the $4.25 M "ceiling" is the Uniswap Gateway's `totalLiquidity` for the funded pools. Several paired tokens (AG/AGS/XRP/XPL/DOGE on Unichain) are **not priced by DefiLlama** and are likely memecoins; the true USD TVL may be lower. It does not change the E-U verdict (the hook cannot reach LP positions).

---

## 7. Methodology & sources

- Verified source: Etherscan V2 `getsourcecode` (chainid 130) for hooks + all six core contracts; full manual read of `Spot.sol`, `FullRangeLiquidityManager.sol`, `DynamicFeeManager.sol`, `PoolPolicyManager.sol`, `TruncGeoOracleMulti.sol`, `Math.sol`, plus the bundled `@uniswap/v4-core` `Hooks.sol`/`BalanceDelta.sol`/`ERC6909*.sol`.
- Project attribution: `github.com/labs-solo/AEGIS_DFM` (byte-identical `Spot.sol`/`FullRangeLiquidityManager.sol`; also `solosage1/anyprice-oracle`). No public audit report found.
- Live reads: Unichain RPC (`eth_call`, `eth_getLogs`), Etherscan V2 logs, Uniswap Gateway GraphQL `topV4Pools` (`origin: https://app.uniswap.org`), DefiLlama prices.
- Fork PoC: Foundry 1.x on GitHub Actions (`artsbykriss/ca-zombie-ci`), Unichain fork.

## 8. Caveats & limitations

- Point-in-time (2026-10-23). Re-read live state before acting.
- The Uniswap Gateway TVL is a top-100-per-chain sample (a lower bound on chain TVL; complete for these two hooks — 5/33 and 5/7 funded pools).
- ERC-6909 id for a currency = `uint256(uint160(currency))`; native ETH id = `0`.
- No audit report located for AEGIS_DFM; conclusions rest on source review + fork tests, not on a published audit.

## 9. Files index

- `analysis/` — verified source dumps (`0x88C9…/`, `0xA0b0…/`), `state_hook1.json`, `keys1.txt`, `uni_pools.json`, live-read scripts (`dump_hook1.sh`, `dump_pending.sh`, `find_pools*.sh`, `resolve_keys1.sh`), `aegis/` (repo HEAD sources).
- `poc/` — Foundry project (11/11 PASS on fork).
- `ci-log.txt`, `ci-artifacts/`, `ci-out/`.
- `summary.json`.
