# Z3-H16 · FermiSwap (Ethereum) — live prop-AMM desk; corpus pricing hypothesis refuted; $0 unprivileged extraction

**Date:** 2026-10-16 · **Chain:** Ethereum (chain id 1) · **Status:** read-only; PoC fork-verified only; no mainnet transactions.

**Verdict headline:** the corpus hypothesis ("swap pricing reads the contract's own inventory → donation/sandwich-manipulable quote") is **refuted**. Pricing comes from **provider-posted price lanes** with same-block freshness enforcement; the vault's inventory is only an **output cap** (plus a ≤0.003 % rebalancing term). The permissionless swap path **is live** and executes at market ± a few bps. **External unprivileged extractable value today: $0.** The loaded surface is privileged: vault manager key can sweep all (~$5.31M, by design), and the 8 still-authorized price providers can, if a key leaks, ratchet within the `PB` band (~+45 %) and drain roughly a third of the quote inventory per epoch (~$0.78M on the USDC lane).

---

## 1. TL;DR

| Target (Ethereum) | Live extractable (unprivileged) | Why closed / open | Latent risk |
|---|---|---|---|
| traderVault `0x585d4472…` (~$5.31M: 874.9 WETH, 2.73M USDC, 0.148M USDT, 3.74 cbBTC, 0.00087 WBTC @ block 26,202,605) | **$0** | Swaps are priced from provider-posted lanes (gated `NP`), fresh per block; all other paths manager/trader-gated (`NM`/`NT`); old swapper has 0 allowance; registry writes `NotAuthorized` | Provider-key compromise → `PB`-band-limited drain ≈ +45 %/epoch (~$0.78M/epoch on USDC lane); manager keys sweep everything (by design) |
| FermiSwapper (new) `0x5979458912…` | **$0** (it only routes; vault allowances ~MAX are the loaded gun) | requires fresh provider price; swaps execute at market ±3 bps | if any provider posts stale/wrong price, same-block searchers take it |
| FermiSwapper (old) `0xb1076fE3…` | **$0** | stale registry lane (`StaleUpdate`) **and** vault allowance = 0 (double-dead) | re-approval would re-open (manager action) |
| Arb executors `0xB4723899…`, `0xeff407D9…` (vault allowances ~MAX) | **$0** | trader-gated (`NT`); traders = team solver EOAs, added by manager | trader-key compromise → can move vault inventory |
| Engines / registry / vault | **$0** | `NM` / `NP` / `NotAuthorized` gates verified live | key compromise only |

**Total live extractable now (external unprivileged): $0 — confidence high.**
Categories: **E-U $0 · H-O $0 · P ≈ $5.31M (vault manager; by design) · S $0.**

## 2. Mechanism in exact terms (deployed code)

Flow: `user/solver → FermiSwapper(0x5979458912) → FermiEngine4(0x0109AA91) → price lane`, then
`IERC20(tokenOut).safeTransferFrom(traderVault, recipient, amountOut)` — the vault pays.

- **FermiSwapper v20260604** (`0x5979458912F80B96d30D4220af8E2e4925A33320`, verified): `fermiSwapWithAllowances`, `swap`, `swapExactOut`, `fermiSwapWithCallback` all call `fermi.swap(...)` and pay the recipient from `traderVault`.
- **Engine4** `0x0109AA912B58508886a2a707204B0F8C8b164CCc` (VERSION 20260907, unverified):
  - Price: `acee8aab(lane, price8dp)` — **provider-gated** (`NP`). 8 lanes (one per pair), one dedicated provider EOA each (all added at block ~25,581,315, Jul 21 2026; all still authorized).
  - Freshness: `unlocked(tokenIn,tokenOut)` true only when an update landed **in the same block**; otherwise every quote/swap reverts `"SP"`.
  - Band: swap-time check `"PB"` — single-step price moves above ~+45 % revert; step-ratcheting caps at ~1.44–1.72× (measured; no per-block/time refresh observed in-test).
  - Inventory: `debug_traceCall` of live swaps shows `STATICCALL balanceOf(vault)` on both legs — payout capped by vault balance. Measured rebalancing sensitivity: +1M USDC donated → quote +0.0024 %; **no donation/sandwich vector** (gain/cost ≈ 1e-7, donation unrecoverable).
- **Engine3** `0x90f73feA…` (VERSION 20260720, unverified) + **PrioUpdateRegistry** `0xDa7AfeeD…` (verified): engine reads `getState(lane, ts, ts)` (min == max == `block.timestamp`) and reverts `StaleUpdate` (0x666a2814) when stale. Registry `updateState` reverts `NotAuthorized()` for non-updaters; `MAX_UPDATE_AGE = 0`, `MAX_UPDATE_LEAD_TIME = 0` (old signatures unreplayable). Engine3's 8 updaters remain authorized.
- **Vault** `0x585d44727129B9C69791B10238Ca605932938B4F` (BaseManager family): `withdrawAllTokens/transferToken/transferEth/executeGeneral/withdrawAllEth` all `onlyManager` (`NM`); batch-approve `67170281(tokens[],spenders[],amounts[])` used by the operator to (re)point allowances (history: `0xb1076fE3` approved 04-29 → revoked 09-07; `0x5979458912` approved 06-08/09-08; `0xb4723899` 04-24/10-06; `0xeff407D9` 10-06).
- **Arb executors**: `0xB4723899…` (UniV3 routes; `0x00000000`-selector fallback) and `0xeff407D9…` (UniV4 `unlock`/callback; VERSION 20261006) — both BaseManager-family, **trader-gated** (`NT`; trader lists read on-chain: 9 + 8 team EOAs incl. the manager bot), pulling from the vault and delivering back (vault-benefiting arb).

## 3. Live-state assessment (citations)

- **Vault balances** (block 26,202,605, 2026-10-16 04:09 UTC): WETH 874.926142761492545997 · USDC 2,731,601.402287 · USDT 147,922.912053 · WBTC 0.00086738 · cbBTC 3.73635507 ≈ **$5.31M**. The vault trades continuously (±10 %/hour); earlier same-day reads: 894.3 WETH / 3.11M USDC / 134.9 USDT / 0.274 cbBTC (block 26,202,258).
- **Allowances** (same block): ~MAX (2²⁵⁶−1 minus dust consumption) from the vault to `SWAP2`, `ARB1`, `ARB2`; **0** to `SWAP1`. Vault ETH = 0 (swept by operator 10-15).
- **Roles verified by gate simulation** (block 26,202,614): vault manager = `0x7117ca30af85706b964100dd8fbbe78f2fb6d3d8`; new-swapper + engine3/4 + arb managers = `0xff67d7211d4837607d601e65f27b97622540c47f` (both EOAs, both hot; `NM` from any other sender).
- **Feed state**: `unlocked = false` at the CI snapshot block; provider updates flow every 1–3 blocks while active (9,938 `acee8aab` calls Sep 8–15; resumption 10-15 12:46 UTC; active at writing).
- **Timeline**: vault 04-22 · old-swapper swaps 04-26→06-11 (596) · engines rotated 05-21/05-28/07-21 · new swapper 06-08 · engine4 09-07/08 · swaps to 09-16 · **dormant 09-16→10-15** · **re-armed 10-15 12:46 UTC** · live now.

## 4. What an attacker can / cannot do (exact paths, preconditions, costs)

**Can (unprivileged, live):** call `SWAP2.fermiSwapWithAllowances/swap` — but only in a block where a provider update for that pair landed; the price is the posted price (market ± a few bps). Measured: local fork at an update-block, 1 WETH → 2,436.503792 USDC vs market $2,435.72 (+0.03 % gross; below gas/priority costs). Posted-vs-market tracking: +4.1 bps (block 26,202,530), +17 bps (26,202,487). No profitable systematic trade.
**Cannot:** post/steer prices (`NP`), write engine3 lanes (`NotAuthorized`), call arb executors (`NT`), withdraw/sweep the vault (`NM`), use the old swapper (stale + 0 allowance), profit from donations (≤0.0024 % effect, unrecoverable), sandwich (same-block impact 0.0025 %).

**Preconditions that would open a path (re-arm conditions):**
1. **Provider-key compromise** (any of 8 lane providers, all still authorized): post within-band prices, ratchet, swap same-block → extract ≈ 31 % of the drained quote inventory per epoch. With a 2.73M USDC inventory: ~708 WETH (~$1.72M) in, ~$0.78M net out per epoch (USDC lane alone; other lanes stack). `PB` caps single-step jumps; steps within band pass.
2. **Vault manager key** (`0x7117ca30af…`, EOA): sweep all (~$5.31M) — by design (P).
3. **Manager/operator action**: re-approving the old swapper or re-enabling lanes; provider-set changes (team control).
4. **Trader-key compromise** (arb executors): move vault inventory through UniV3/V4 routes.

## 5. PoC / fork verification

Foundry suite `poc/` (fork-only, `vm.createSelectFork`, no mainnet txs) — **17/17 tests PASS in CI**:

- `poc/test/FermiPoC.t.sol` — T1 live snapshot (balances/allowances/locks), T2 `"SP"` when locked (walked to a locked block), T3 old swapper fresh-lane still blocked (`ERC20: transfer amount exceeds allowance`), T4 `NP`, T5 `NotAuthorized`, T6 `NT` ×2, T7 `NM` ×3, T8 donation ≤0.01 % (measured 0.0024 %), T9 same-block impact ≤0.01 % (measured 0.0025 %), T10 provider unlock → vault pays at posted price (vault delta == attacker delta, 2,427,507,653), T11 absurd price → `PB`, extraction 0, T12 live unprivileged probe (reverts `SP` when locked; **executed live at $2,436.50/WETH vs market $2,435.72 in a local update-block**).
- `poc/test/DonationProbe.t.sol` — donation sensitivity curve (7×10⁻⁸ per unit; ~0.0024 % for +1M USDC).
- `poc/test/BandProbe.t.sol` — band width & ratchet: 1.45× OK / 1.49× `PB`; +3 %-step walk to 1.43×; +20 %-step to 1.44×; +40 %-step to 1.40×; multiblock/`warp` no refresh.

**CI (public repo `artsbykriss/ca-zombie-ci`):**
- Run 1 (17/17): https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38848938942
- Run 2 (17/17 + artifacts `ci-out/forge_test_vvv.log`, `ci-out/live_snapshot.txt`): https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38849085925

Gas: swap ~200–450k gas (T10: 444,998); unlock post ~50k. No flash loans needed for any unprivileged path (none exists); no fees paid in PoC (fork).

## 6. Verdict, residual and latent risk

- **E-U today: $0** (high confidence). The permissionless swap is live but priced at market ± a few bps; donation/sandwich dead; all inventory-moving paths gated.
- **Latent (monitor)**: provider authorizations (8 EOAs per engine, all live) + ~MAX allowances to swapper/arb + hot manager EOAs = key-compromise blast radius of the full vault. The `PB` band (~+45 %/epoch) caps but does not eliminate a provider-key drain; the manager key can always sweep (by design).
- **Re-arm conditions**: any provider key leak/rotation error; team re-approving old swapper; manager misconfiguration. Suggested monitoring: `unlocked()` spikes, `acee8aab` price-vs-market deviation > ~1 %, `UpdaterAdded/Removed` on the registry, allowance changes from the vault, trader list changes on the arb executors.

## 7. Methodology, caveats, files

- Method: Etherscan V2 (source/ABI/txs/logs), `cast` reads at pinned blocks, `debug_traceTransaction`/`debug_traceCall` (callTracer) via public RPCs, DefiLlama prices, heimdall/evmole for unverified ABIs, fork PoC in GitHub Actions.
- Caveats: engine4/vault/arb bytecode is unverified — pricing internals reconstructed empirically (band/ratchet bounds are empirical, not source-derived); the `PB` reference-update rule was not fully reverse-engineered (walk tests bound the per-epoch ceiling at ~+45 %); vault balances move with live trading (snapshot at block 26,202,605; total ~$5.31M ±10 %); provider authorization set may change (tests try all 8 known providers).
- Files: `analysis/EVIDENCE.md` (citations), `analysis/*.sh` (probes), `analysis/*.txt|json` (raw dumps), `analysis/src/`, `poc/` (tests), `ci/run.sh`, `ci-out/` (CI artifacts + logs), `summary.json`.
