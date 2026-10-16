# Z3-H13 · Fables (Robinhood Chain, chain id 4663) — v4 hooks + `FablesLedger` share accounting

**Date:** 2026-10-16 · **Chain:** Robinhood Chain (4663) · **Status:** read-only; PoC fork-verified only; no mainnet transactions
**Scope:** `FablesPoolRegistry` `0x159a113e012593d9b3cc63ad45e30f0467e13ef3` (68 pools, all active) ·
hooks `FablesRamp` `0x08E52564Bad99E05a694b4809F397edcA417A080` (37 pools) · `FablesRWA` `0x5Eb87F69bE00Df39981622Fd60A8De4b7837e080` (11) ·
`FablesRampETH` `0x594e8e6281eDf2d363a0293a50004Cf868E7a080` (9) · plus 10 sibling hook revisions (11 pools, incl. the
**pre-fix** `FablesRampETH` `0x06a889870C8f83640D6816319f72e2aA579b6080`)
**Method:** univ4-hook-harbinger checklist on all 13 hooks + adversarial donation/fee-sync/role/sweep probes, all executed on a
fork of live Robinhood Chain state (Foundry), plus full verified-source review.

---

## 1. TL;DR

| target | live extractable (unprivileged) | why closed / open | latent risk |
|---|---|---|---|
| `sweepClaimFee(currency)` — **permissionless** on every hook | **$0** | pays `claimFeeOwed[currency]` **only** to `claimFeeRecipient` (Safe `0x9F88…0F6f`, 2-of-3). Fork-proven: sink receives exactly the pot, attacker receives nothing (T2) | none while the sink is a Safe; a malicious/EOA sink is an ADMIN action (P) |
| `sweepDistributor(currency)` — **permissionless** | **$0** | `distributor == 0x0` on all 13 hooks → early return; `distributorOwed == 0` everywhere. Fork-proven no-op (T3) | re-arms only if ADMIN sets a distributor (P) |
| `FablesLedger` principal + fee accounting | **$0** | deposits pull from `msg.sender`; withdrawals burn the caller's ERC-6909 receipts; fee claims are minted 1:1 with real collections; every pot is backed by hook-held claims (0 under-backed pairs). Fork-proven round-trip loses value (T6), donation unrecoverable (T7), forced syncs gain nothing (T15) | rounding dust is stuck (S), economically inert |
| admin/poke/pause surface (`pokeFee`, `setPoolConfig`, `setClaimFee`, `pause`, …) | **$0** | all `restricted`; every selector maps to role 0/1/2/4/9 — **no PUBLIC_ROLE mapping anywhere**; targets not closed. Fork-proven reverts for a fresh caller + `canCall`/`hasRole` reads (T4) | FEE_POKER/PAUSER are **hot EOAs** (P); a compromised poker can subsidise flow up to 50% for ≤72 h |
| **OLD `FablesRampETH` `0x06a88987…` native refund** | **$0 today** (balance = 0 wei) | `_refundNative()` refunds **the whole contract balance** to any `deposit` caller → any ETH park is a race prize. **Fork-proven: a fresh attacker with 10,000 wei captured a 1 ETH park** (T8) | **E-U-conditional**: re-arms the moment ETH lands in that hook (mis-addressed `withdraw(..., to = hook)`, sibling-hook mis-route, selfdestruct/coinbase) |
| current `FablesRampETH` `0x594e8e62…` (same scenario) | **$0** | delta-bounded refund (`balance - preCallBalance`) — fork-proven the park is **not** claimable (T9) | none |

**Total live extractable now: $0.00** — confidence **high** (fork-proven negatives on every candidate path, with live state
read at block `eth_blockNumber = 89,740,322`, header hash `0xcaf9c240932f201b48c906c3fd6d31c91da923c37536ad988579677b297815b3`).
The only genuine defect is conditional and sits on a **superseded** hook.

## 2. The mechanism, in exact terms

`FablesLedger` (inlined into every hook; `src/base/FablesLedger.sol` + `src/libraries/LedgerLib.sol`) is a per-range liquidity
ledger: users `deposit` liquidity into a hook-owned v4 position and receive ERC-6909 receipts 1:1 (`totalShares == position
liquidity`); fees are collected lazily on every touch, split between unstaked holders (`accFee*X128`), the staked/voter pot
(`distributorOwed`) and the protocol cut (`claimFeeOwed`), and paid out by burning the hook's own ERC-6909 claims.

What the finding flagged as dangerous:

1. **Permissionless sweeps.** `sweepClaimFee` / `sweepDistributor` are open to anyone — but both are *destination-locked*
   (`claimFeeRecipient` / `distributor`) and *amount-bounded* (their own pots). A sweep can only push already-recorded
   protocol revenue to the already-configured sink. Live: `claimFeeRecipient = 0x9F887B9930E9e716286333Bd8e291f64a8710F6f`
   (Safe v1.4.1, 3 owners / 2-of-3), `distributor = 0x0`, `ffFeeSink = 0x0`.
2. **Sink rotation / native-transfer churn.** `_settleSinks(settleFirst)` runs at the head of `setClaimFee` / `setDistributor` /
   `setFFFeeSink` so a rotation settles the outgoing sink first — all ADMIN-gated. The current revisions carry the native wrap
   fixes (`FablesNativeETH._sweepDistributor`/`_sweepClaimFee` wrap ETH→WETH); the older revisions did not (see §5).
3. **The real defect — the old revision's refund.** In `0x06a889870C8f83640D6816319f72e2aA579b6080`:

   ```solidity
   function _refundNative() internal {
       uint256 balance = address(this).balance;
       if (balance == 0) return;
       (bool success,) = msg.sender.call{value: balance}("");   // ← whole balance, not msg.value - spent
       if (!success) revert RefundFailed();
   }
   ```

   `deposit` is payable and calls `_refundNative()` on native pools, so **any** ETH present in the hook at the end of a
   deposit (a stranger's forced transfer, a mis-addressed withdrawal routed to the hook, or a sibling-hook mis-route) is paid
   out to whoever deposits next. The current revisions replace this with a delta-bounded refund plus `_checkPayoutTarget`
   (`to != hook && to != poolManager`), which closes the race (fork-proven, T9).

## 3. Live-state assessment (block 89,740,322 · 2026-10-16)

- **Registry** `0x159a11…13ef3`: `poolCount = 68`, `activePools = 68`. Hooks: FablesRamp 37 · FablesRWA 11 · FablesRampETH 9 ·
  FablesRWAETH 2 · 8 single-pool FablesRWA revisions (8) · 1 old FablesRampETH (1) — 11 pools on 10 sibling hooks. Full table: `analysis/pool-map.md`.
- **PoolManager** `0x8366a39CC670B4001A1121B8F6A443A643e40951` (24,009 B, verified): stock v4-core; its `libraries/*`,
  `types/*` files are **byte-identical** to the vendored `lib/v4-core` the hooks were compiled against (diffed). `unlock`
  holds a transient lock, so nested unlocks revert; `mint`/`burn`/`take` account deltas to `msg.sender`.
- **Hooks** (all `Proxy: 0`, immutable, solc 0.8.26): code sizes 32,997 / 42,039 / 34,326 B for the three main ones;
  permission bits decoded from the addresses = `0x2080` (`beforeInitialize` + `beforeSwap`, no delta flags) — matches
  `_hookPermissions()` and the constructor's `Hooks.validateHookPermissions`.
- **AccessManager** `0xA362D98B33A7bb5B5E2180a05f995A70FB404f30` (OZ, verified): `expiration = 604800`,
  `minSetback = 432000`, no target closed. Role map (full selector sweep, 13 hooks + registry, `analysis/am_role_sweep.json`):
  role 0 ADMIN → `0x359856655934338d798f9cce1f181486301d36a5` (**EIP-7702 account**, delegate
  `0x5a7fc11397e9a8ad41bf10bf13f22b0a63f96f6d`) · role 1 FEE_POKER → 3 EOAs (`0xb9e8db60…`, `0x1b6a8808…`, `0x014f37fa…`) ·
  role 2 CALENDAR_OPS → `0xb9e8db60…` (delay 3600) · role 4 PAUSER → `0x5cda43da…` (EOA) · role 9 REVENUE_OPS → **no members**.
  **No `PUBLIC_ROLE` (2⁶⁴−1) mapping exists on any (target, selector) pair**; the hook targets carry a
  `getTargetAdminDelay` of 86,400 s for the ADMIN_ROLE-gated setters (schedule/execute path).
- **Value in the hooks' control** (all 68 pools have nonzero liquidity; TVL $36,007,467 per DefiLlama 2026-10-16):
  - hook-held ERC-6909 claims (unclaimed LP fees + protocol pots): **$628,980 priced** (+21 unpriced memecoin legs), all
    backed — `claims ≥ claimFeeOwed + distributorOwed` on every (hook, currency) pair (0 under-backed).
  - `claimFeeOwed` pots (permissionlessly sweepable → fixed Safe): **$21,132 priced** (+15 unpriced legs, incl. 13.85 M EARN,
    2.18 M NOSH) — 65 nonzero (hook, currency) pairs.
  - native pots: **0.3935 ETH** on FablesRampETH + **0.0101 ETH** on FablesRWAETH (≈$983 at $2,436/ETH) — sweepable to the Safe.
  - `distributorOwed`: **0 everywhere** (no staking: `ballotGate == 0` on every hook → `stake` reverts `DeskRetired`).
  - **native balances of all 13 hooks: 0 wei** — including the old hook (so its defect is worth $0 today).
- **Pause state:** `pausedUntil == 0` on every hook; `setPoolPaused`/`pausePool` unset.

## 4. What an attacker can / cannot do (exact paths)

Can (all verified, none profitable):

- `sweepClaimFee(currency)` for any currency — moves the pot to the Safe (T2). `sweepDistributor(currency)` — no-op (T3).
- `deposit`/`withdraw`/`claimFees`/`withdrawAndClaim` on any configured pool with their own capital. Round-trip is
  loss-making: measured **−1 wei** net on a CASHCAT range (T6); deposits are priced by v4 against the live tick with the
  caller's per-currency ceiling enforced (`PrincipalAboveMax` when exceeded).
- Force a fee sync on a range they do not own (1-wei deposit): costs the attacker ~84 k wei per sync and yields nothing (T15).
- Donate to a pool (no hook callback): the donation accrues pro-rata to in-range LPs and is not recoverable (T7).
- On the **old** hook only: `deposit` on its native pool with `msg.value ≥ amount0Max` **claims the hook's whole ETH balance**
  (T8: attacker deposited 10,000 wei into an ETH/USDG range and walked away with 999,999,999,999,999,402 wei).

Cannot:

- Call any `restricted` function (`pokeFee`, `clearPoke`, `setPoolConfig`, `setClaimFee`, `setClaimFeeBps`, `setDistributor`,
  `setFFFeeSink`, `setPaused`, `pause`, `setPoolPaused`, `pausePool`, `setBallotGate`, `setPoolAsymmetry`) — T4; also verified
  via `AccessManager.canCall` (false) and `hasRole` (false).
- Stake or use `syncRanges` (ballot gate unset → revert, T5); zero-share sync doors are closed (`ZeroShares`).
- Call `unlockCallback` (non-PoolManager reverts), `beforeSwap` (non-PoolManager reverts), or send ETH to a native hook's
  `receive()` (non-PoolManager reverts) — T11.
- Create or touch a foreign/unconfigured pool (`_checkKey`: `key.hooks == hook` and `maxFee[poolId] != 0`) — T12.
- Extract another holder's fees (`_positions[id][msg.sender]`), another range's principal (receipts are per `rangeId`), or the
  claim-fee pot (fixed sink).
- Block exits: `withdraw` has no pause modifier and no admin gate — fork-proven to still work while the real PAUSER role
  holder has paused the hook (`deposit` reverts, `withdraw` succeeds, T14).

Costs/preconditions for the only conditional path: no capital needed beyond gas + `amount0Max` (10,000 wei in the PoC);
the precondition is **a nonzero ETH balance in `0x06a88987…`** — a state that requires someone else's mistake (or a forced
transfer), because every legitimate native payout goes to a caller-chosen `to` that the old revision does not check against
the hook address.

## 5. Version drift (why the old hooks matter)

Code-only diffs (comments stripped) of the 10 sibling revisions against the current ones (`analysis/harbinger-checklist.md` §7):
the older `FablesRampETH` (`0x06a88987…`, 28,189 B) and the 8 single-pool `FablesRWA` revisions differ in exactly the ways
the current revisions' own NatSpec records as fixed defects — full-balance native refund, missing payout/sink sentinels,
hook-wide (not per-pool) claim fee, missing per-pool pause, weaker poke-discount floor, no native claim-fee wrap, no EOA
probe on `setDistributor`. None of the older revisions has an *additional* unprivileged path beyond the refund race.

## 6. Independent verification

A second agent re-derived the verdict adversarially from the deployed sources (read-only, live RPC): it proved the
`_split` credit sum equals the fee minted (`cut ≤ fee` via the residual-carry bound), that every balance-mutating path
settles first so no holder can over-draw `accFee`, that `claimFeeSyncIndex` is monotone and `claimFeeFor` is min-only,
that v4's signed deltas make the withdraw path `take`-only, and that the PM lock + `NonzeroDeltaCount` + `nonReentrant`
close the hostile-token reentrancy class. It also re-read live state (all hooks 0 ETH; rampeth 0.3935 ETH pot vs
0.7411 ETH claims; old hook 11.349 ETH claims but 0 balance) and scanned 240 recent blocks (1,305 txs) — **zero direct
hook calls**. Its verdict: **CONFIRMED, no live unprivileged extraction path**; strongest remaining doubt is a
router that derives the withdrawal `to` from attacker-supplied data (would turn the sibling-hook strand into an induced
loss). Full note: `analysis/child-verify.md`.

## 7. PoC / fork verification

- Project: `poc/` (Foundry 1.8.5, solc 0.8.26, forge-std vendored). Forks live state via keyless public RPC
  (`rpc.mainnet.chain.robinhood.com`, fallbacks publicnode/drpc; no keys anywhere).
- **CI: 17/17 PASS** — final run https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38843722806 (`fables` branch;
  earlier: 38843184408 = 15/15, 38842951890 = 16/17 with a leftover block-pinned diagnostic the non-archive RPC cannot serve).
- Files: `poc/test/FablesZ3H13.t.sol` (T1–T10), `poc/test/FablesZ3H13b.t.sol` (T11–T18). Key numbers:

| test | result | key number |
|---|---|---|
| T2 `sweepClaimFee` | PASS | Safe received exactly 8,850,309,640 (USDG 6dp); attacker +0 |
| T6 round trip | PASS | paid 84,599,784,663,186,321,921 CASHCAT; net **−1 wei** |
| T7 donation | PASS | 100 USDG donated, unrecoverable |
| T8 **old hook park** | PASS | **attacker gained 999,999,999,999,999,402 wei (~1 ETH); hook balance 0 after** |
| T9 current hook park | PASS | attacker net **−1 wei**; park stays |
| T14 liveness | PASS | real PAUSER pauses: `deposit` reverts, `withdraw` succeeds |
| T15 forced sync | PASS | 5 foreign syncs cost 420,470 wei, gained 0 |
| T10 backing | PASS | 0 under-backed (hook, currency) pairs |
| T17 native wrap-sweep | PASS | 0.3935 ETH pot → WETH to the Safe; attacker +0; hook ETH = 0 after |
| T18 old-hook sweeps | PASS | both sweeps are no-ops (no recipient, no distributor) |

- CI artifacts: `ci-out/live_state.json` + `live_state.txt` (block 89,740,322 snapshot: registry, per-hook roles/sinks/pots/claims).

## 8. Verdict and residual risk

- **E-U (external unprivileged, live): $0.00 — high confidence.** Every candidate path was reduced to a concrete call sequence,
  gated by a live-read guard, or fork-falsified.
- **E-U-conditional: the old `FablesRampETH` `0x06a88987…` park drain.** Value = whatever ETH lands there (measured max in the
  PoC: ~1 ETH; not bounded by the contract). Re-arm conditions, in order of likelihood: (a) any LP or integration calls
  `withdraw`/`claimFees`/`withdrawAndClaim` with `to = 0x06a88987…` (the old revision does not refuse it); (b) a router that
  forwards a user-supplied `to`; (c) `selfdestruct`/coinbase forced transfers. The next `deposit` on its native pool collects
  the park. Recommended monitor: `eth_getBalance(0x06a889870C8f83640D6816319f72e2aA579b6080) > 0`.
- **H-O:** ~$36.0 M TVL — LP principal + ~$629 k unclaimed fees, all self-service (`withdraw` is unconditional, even under a
  pause). **P:** ~$21.1 k claim-fee pots + 0.404 ETH native pots flow to a 2-of-3 Safe; role keys (FEE_POKER/PAUSER, hot EOAs)
  are the main privileged risk. **S:** sub-unit rounding dust in hook-held claims (no redemption path, inert); ERC-20s a user
  mis-addresses to a hook (unrecoverable by design — the new revisions block `to == hook`, the old ones do not).
- **Blockers/caveats:** `eth_getLogs` is refused by the public RPC (used Blockscout MCP for event reconstruction); the chain's
  block **header** `number` (26.2M space) differs from `eth_blockNumber` (89.7M space) — Foundry reports the former, so block
  citations here use `eth_blockNumber` + header hash; DefiLlama prices are point-in-time and unpriced memecoins are excluded
  from USD totals; the two contract-revision families mean findings must always be qualified by address.

## 9. Methodology & sources

Read-only throughout. All state via keyless public RPC (`eth_call`/`eth_getCode`/`eth_balance`/`extsload`) and the Blockscout
MCP (logs, role-grant reconstruction). Verified sources from Etherscan V2 (chain 4663) for every contract cited; hooks
re-checked for `Proxy: 0` and permission bits; PoolManager sources diffed against the hooks' vendored v4-core. Adversarial
PoC on a Foundry fork, 15 tests, run in public CI. Prior-corpus check: `zombie_hunt/FINDINGS.md` and the workspace have no
Fables entry beyond this finding; the chain appears in Z3-C1 (UNCX) and Z3-H12 (Arcus) only.

**Files:** `README.md` · `summary.json` · `analysis/harbinger-checklist.md` · `analysis/pool-map.md` ·
`analysis/am_role_sweep.json`, `hook_state.json`, `value_enum.json`, `registry_pools.json`, `pool_liquidity.json`,
`token_meta.json`, `token_prices.json`, `am_events`-derived role map · `analysis/sources/**` (verified sources incl. the
pre-fix revision) · `poc/` (tests) · `ci/` (state dump) · `ci-out/`, `ci-log.txt`, `ci-artifacts/`.
