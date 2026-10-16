# child-verify.md — adversarial falsification attempt: Fables v4 hooks (Robinhood Chain, 4663)

## VERDICT

**CONFIRMED — no live unprivileged extraction path found.**
The predecessor's conclusion survives my attempts to falsify it. The only value-capture
mechanism that exists anywhere in the family is the *conditional* one already named:
the OLD FablesRampETH `0x06a88987…` full-balance native refund. It is **unfuelled today**
(hook ETH balance = 0 wei), it is a race prize rather than a directed theft, and the only way
to create fuel is a withdrawal whose `to` the *sender themselves* sets to that hook.
I could not turn it into an attacker-driven path.

Read-only: no signing/sending; only `eth_call`, `eth_getBalance`, `eth_getCode`,
`eth_getBlockByNumber` against `https://rpc.mainnet.chain.robinhood.com`.

## Live reads re-verified (this run, "latest")

| item | value |
|---|---|
| ETH balance of **all** hooks (ramp 08E5, rwa 5Eb8, rampeth 594e, rwaeth ca89, old 06a8, 8×rwa variants, 159a) | **0 wei** |
| PoolManager ETH balance | 25 340.028 ETH (pool reserves, not hook-owned) |
| rampeth 594e `claimFeeOwed(native)` | 393 528 520 371 224 300 wei |
| rampeth 594e PM ERC-6909 `balanceOf(hook, 0)` | 741 144 276 450 536 218 wei (> pot ⇒ backed) |
| ramp 08E5 `claimFeeOwed(USDG)` / PM claims | 8 865 584 633 / 17 846 663 906 |
| `distributor()`, `ballotGate()`, `ffFeeSink()`, `paused()` on 08E5/5Eb8/594e | 0 / 0 / 0 / false |
| `claimFeeRecipient()` on 08E5/5Eb8/594e | `0x9F88…0F6f` (Safe); old 06a8 = 0 |
| old 06a8: `claimFeeBps()` = 0, `claimFeeRecipient` = 0, pool `0xbac3aa…` maxFee = 6000 pips, tickSpacing 10, tick −198 359, L = 10.93e18 |
| old 06a8 PM ERC-6909 claims | 11 348 742 292 962 157 300 wei native + 27 263 936 434 USDG (claims, **not** balance) |
| `pause(100)`/`setPaused(100)`/`setClaimFeeBps(…)` **from an unprivileged address** (`eth_call`) | revert (AccessManager enforcement is live) |
| `sweepClaimFee(native)` / `sweepDistributor(native)` from attacker | succeed; both pay only the fixed sink (recipient Safe / unset distributor ⇒ no-op) |
| `stake`/`unstake` from a non-holder | revert (gate unset / no shares) |
| role 0 (ADMIN) held? `hasRole(0, 0x3598…)` = uint256.max ⇒ yes; `hasRole(1|4|9, 0x3598…)` = 0; `adminDelay(hook)` = 86 400 s | privileged only |
| 240 recent blocks (24 s, 1 305 txs) with full tx bodies | **0 txs directly to any hook** |

## Candidates examined

1. **`_refundNative` whole-balance refund (CURRENT hooks)** — BLOCKED. Delta-bounded:
   `_setForeignNative(address(this).balance - msg.value)` at `rampeth/src/base/FablesLedger.sol:725`,
   refund `balance > pre ? balance - pre : 0` at `:806-813`. A park P is preserved because
   `settle{value: owed}` spends at most the caller's own prepay (`msg.value ≥ amount0Max ≥ owed`).
   Cannot be drained.
2. **`to = address(this)` / `to = PoolManager` on withdraw/claimFees (CURRENT)** — BLOCKED at
   `FablesLedger.sol:515-517` (`_checkPayoutTarget`), called `:1019` and `:1071`. The old-flavour
   loss shape (stranded tokens; PM self-transfer = silent burn) is inert.
3. **Sibling native hook as `to` (strand ETH into old 06a8)** — the guard is instance-scoped and
   the docs admit it (`FablesLedger.sol:465-476`). Reachable **only** when the withdrawer passes
   `to = 0x06a88987…` themselves; no code path substitutes `to`. Old hook has no rescue; its
   `_refundNative` (old ledger `:450-455`, `msg.sender.call{value: address(this).balance}`) makes the
   park a race prize: any next `deposit` on the old hook gets the whole balance. See "conditional
   path" below.
4. **`_split`/`creditFees` over-mint** — BLOCKED. Mints equal exactly `fee0+fee1`
   (`ramp/src/libraries/LedgerLib.sol:140-141`); credits sum to the same fee:
   `cut + (net − skim) + skim = fee`, with `cut ≤ fee` proven by
   `mulmod(fee,staked,total) < total` ⇒ carry `>>128 ∈ {0,1}` and `mulDiv ≤ fee−1` while
   `staked < total` (`LedgerLib.sol:447-461`); `_creditStaked` only floors further (`:464-469`).
5. **Accumulator over-draw (Σ holders' `owed` > minted claims)** — BLOCKED. Every balance
   mutation settles first (deposit `:738-739`, withdraw `:1025-1026`, claimFees `:1094-1095`,
   stake `:1203-1204`, unstake `:1232-1233`, transfer `:1271-1273`, transferFrom `:1289-1291`);
   `accFee` only ever `+=` (`:251-252`); sum of draws telescopes to ≤ net.
6. **`settleUser` uint128 truncation (`:529-531`)** — value-losing / revert-only, not extractable.
   Requires ≥3.4e38 base units of one currency on one range; truncation pays *less*.
7. **`claimFeeFor` min-over-window walk** — cannot over-charge: takes the **minimum** over the
   window and falls back to `allTimeMin` which is monotonically the min ever (`:264-290`, `:298-321`).
   `claimFeeSyncIndex` is only ever written to `history.length` (`_syncRange` `:659`,
   `creditFees` `:117`), and history only grows ⇒ the index is monotone non-decreasing; nobody can
   reset it downward. `sinceIndex == 0 ⇒ 0` (`:272`) is the documented "backlog opened before any
   rate" case, LP-favouring, not attacker-selectable.
8. **`_effectiveClaimFee` vs the skim drift** — BLOCKED (single definition, `:1558-1586`; both the
   guard and `_split` read the same `claimFeeFor`; fully-staked shortcut matches `_split`'s
   `unstakedTotal == 0` early return `:191-208`). Direction is safe even if it drifted (min).
9. **`rangeId` / `_rangeKeys` first-writer** — BLOCKED. `id = keccak(poolId, tl, tu)` and
   `poolId = keccak(full PoolKey)`; a second writer would need a keccak collision, and
   `_checkKey` (`:622-629`) binds `key.hooks == this` + `maxFee != 0`. Currency of the payout is
   therefore always the currency that earned it.
10. **ERC-6909 receipt transfer/approve** — BLOCKED. Ledger overrides only add a staked-balance
    check + syncs (`:1259-1303`); auth lives in v4-core `ERC6909.transferFrom`
    (`ramp/lib/v4-core/src/ERC6909.sol:35-48`: sender/operator or `allowance -= amount`, checked
    arithmetic reverts on over-spend). `_checkTransferable` `:1305-1307` blocks moving staked shares.
11. **PAYOUT unlock / `_redeem` burn-then-take** — BLOCKED. Amounts are the caller's `owed`
    (zeroed before the unlock, `:1098-1100`, `:995-997`) or a pot counter; `burn` requires the hook's
    own claims (it has no allowance out to anyone) and `take` targets pass `_checkPayoutTarget`.
    A revert rolls the whole unlock back.
12. **Reentrancy via hostile currency (incl. mid-`transferFrom` PM calls)** — BLOCKED.
    Every door is `nonReentrant` (OZ transient guard) and `unlockCallback` refuses any caller but
    the PM (`:1354-1355`); nested `poolManager.unlock` reverts (`pm/src/PoolManager.sol:103-113`).
    A hostile token *can* call `sync/settle/mint/take` while the PM lock is held, but
    `NonzeroDeltaCount != 0 ⇒ CurrencyNotSettled` (`PoolManager.sol:111`) makes settle-sniping
    revert the whole tx: stealing the hook's settle credit leaves the hook's delta unpayable
    (`_settle` consumes the synced currency, `PoolManager.sol:347-361`; `CurrencyReserves.resetCurrency`),
    and minting/burning/taking can only ever net to the caller's own payment or a revert.
13. **Skip-the-victim's-fees (`claimed`/`owed` redirection)** — BLOCKED. Positions are keyed
    `_positions[id][msg.sender]`; `claimFees`/`withdrawAndClaim` can only pay the *caller's* `owed`
    to a `to` of the caller's choosing.
14. **Native wrap sweeps (`FablesNativeETH._sweep*`)** — BLOCKED. `take` goes to `address(this)`
    (its `receive` is PM-only, `:253-255`), wraps exactly `amount`, transfers to the admin-set sink;
    an unset sink simply parks the accrual (`:264-284`, `:296-322`). recipiend/distributor are 0 on
    the old hook, so nothing sweeps at all.
15. **forced ETH (selfdestruct / coinbase) into current hooks** — dead-ends by design: refunds are
    delta-bounded and there is no rescue; forced ETH into the *old* hook's balance would be capturable
    but only with the attacker's own ETH (donation), and EIP-6780 keeps pre-existing-contract
    `selfdestruct` from transferring (the chain is Cancun+ — the hooks use tstore).
16. **Deposit/withdraw principal sign abuse (`safeTransferFrom(user)` branch)** — BLOCKED.
    v4's `getAmount0Delta(..., int128 liquidity)` returns **positive for removals**
    (`pm/src/libraries/SqrtPriceMath.sol:261-271`), so `principal = callerDelta − fees ≥ 0` on every
    withdrawal and `_resolvePrincipal` can only `take` to `user`; the pull branch is reachable only
    with `user == msg.sender` (deposit). A withdrawal cannot make a third party's allowance pay.
17. **Over-withdraw / share theft** — BLOCKED. `_burn` underflow + `position.staked` underflow
    (`withdraw` `:1031-1039`); `_checkTransferable` on both transfer doors; `stake` pre-check
    `:1206`. Total shares are liquidity units, 1:1 (`RangeState.totalShares` invariant).
18. **`sweepDistributor` while `distributor == 0`** — no-op: `to == 0 ⇒ return` before zeroing
    (`LedgerLib.sol:751-754`); pot cannot be lost or taken.
19. **`stake` path** — dead: `ballotGate == 0` ⇒ `DeskRetired` (`:1144-1145`); `totalStaked` can
    therefore never grow, so the whole staked-cut/forsaken-fee surface is inert.
20. **Admin surface** — `restricted` is enforced live (probe above); the AccessManager has no
    PUBLIC_ROLE assignments reachable by an unprivileged address (`getTargetFunctionRole` sweeps:
    all restricted selectors resolve to roles 0/1/4/9; only role 0 is held, by the EIP-7702 admin,
    with a 86 400 s execution delay). Even a full ADMIN compromise cannot touch principal or
    existing pots: `claimFeeRecipient` is one-way (`:361`) and `_settleSinks` settles pots to the
    **current** sink at the head of every rotation (`:547-552`), so a rotated sink only ever earns
    *future* claim fees (≤2000 bps), and `withdraw`/`unstake` are unpausable by construction.
21. **RWA session/calendar surface** — only affects the swap fee; admin-gated
    (`MarketCalendar.sol:159,296,408,453` → `_checkCalendarAdmin` → `_checkCanCall`); no fund flow.

## The one conditional path (old hook), with today's fuel measured

- Old FablesRampETH `0x06a889870C8f83640D6816319f72e2aA579b6080`, single pool
  `0xbac3aa3b…` = native ETH / `0x5fc5360d…` (USDG), tickSpacing 10, live (tick −198 359,
  L ≈ 10.93e18), `maxFee` 6000, not paused.
- `deposit` is payable; the OLD ledger refunds **the entire contract balance** to `msg.sender`:
  `rampeth_06a88987/src/base/FablesLedger.sol:450-455`. Any successful deposit (any range; a
  below-spot range needs 0 ETH and only USDG) sweeps an existing park, including another user's
  mis-addressed withdrawal. The victim's own funds are also recoverable by the victim via the same
  route — it is a first-come race prize, not a directed theft.
- Today's fuel: `eth_getBalance(0x06a88987…) = 0` ⇒ the path is inert. The hook's 11.35 ETH of
  value sits as **PoolManager ERC-6909 claims**, which `_refundNative` never touches; those claims
  are drawable only through `owed` of the holders who earned them (claimFeeRecipient and distributor
  are both 0 on this hook, so no sweep can move them).
- How fuel could appear: only a PM `take` to that address, i.e. a withdrawal/claim on ANY native
  hook whose `to` is `0x06a88987…`. The new hooks' `_checkPayoutTarget` deliberately allows sibling
  hooks, so that destination is legal — but `to` is always the caller's own argument. No Fables
  code, and no `PoolManager` `take` reachable by a third party, sends ETH there on a victim's behalf.

## The 8 ERC-20 FablesRWA variants (code-only diff vs `sources/rwa/`)

All eight are **older vintages** of the same ledger: hook-wide claim fee (`ClaimFeeChange[]` +
`claimFeeBps`/`claimFeeAllTimeMin` instead of per-pool `PoolClaimFee`), no `setClaimFeeBps`,
no `withdrawAndClaim`, no per-pool pause, no `ve()`/`gaugeWeightNow` probes, no `_checkPayoutTarget`,
no `ClaimFeeAccrued` event, `validateDistributor` without the `code.length` check. Their
`FablesLedger.sol` is **code-identical to the old native ledger** — including the whole-balance
`_refundNative` — but they are **ERC20-only** (`_nativeAllowed()` false, native pools refused in
`FablesBaseHook.beforeInitialize` and `_checkKey`), so that refund is unreachable dead code.
The only *additional* divergence is the missing `_checkPayoutTarget`: `withdraw`/`claimFees` with
`to = address(this)` or `to = poolManager` is allowed. Both are **losses to the caller only**
(ERC-20 stranded on a rescue-less hook; PM self-transfer nets the manager's balance to zero and
burns the caller's claims) — no third party can set that `to`, so no unprivileged gain.
Live: their native balances are 0; they hold only their own currencies' PM claims
(e.g. `0x66622f77` 1 206 756 751 USDG, `0xb608a787` 1 564 562 144 USDG); `claimFeeOwed` on most
goes to the Safe (`0xa0e8fbff` has recipient 0).

## Strongest remaining doubt / not checked

1. **Router-mediated `to` substitution (the one real gap).** If any on-chain router/vault calls
   `withdraw/claimFees` on a native hook and derives `to` from *attacker-supplied* calldata while
   executing on a victim's position, the sibling-hook strand → old-hook refund becomes an induced
   loss. I could not rule this out: `eth_getLogs` is blocked, block time is ~0.1 s, and a bounded
   240-block full-tx scan (24 s of chain, 1 305 txs) showed **zero** direct hook calls, so the
   routers are elsewhere; an exhaustive historical scan was out of budget. Nothing in the Fables
   contracts themselves substitutes `to`.
2. **7702 admin account.** ADMIN role is held by `0x359856655934338d798f9cce1f181486301d36a5`, a
   delegation designator pointing at `0x5a7fc11397e9a8ad41bf10bf13f22b0a63f96f6d` (11 162 B).
   I did not fully reverse its authorization model. Even a full compromise is bounded to future
   revenue (≤20% claim fee on future collections; sink rotation is one-way and settles old pots
   first) plus ≤7-day DoS of deposits/claims — never principal, `owed`, or unpausable exits.
3. **Byte-identity assumption.** I analysed the Etherscan-extracted sources that ship with the
   task and did not recompile/byte-diff the deployments against them.
4. I did not enumerate every holder's `owed`/`totalStaked` (no log access); `ballotGate = 0`
   makes new staking impossible regardless, and `distributorOwed` reads 0 on the sampled hooks.

## Cited files / lines

- `sources/ramp/src/base/FablesLedger.sol`: `_checkPayoutTarget` 515-517; deposit native branch
  720-728; refund call 759; `_refundNative` 806-813; `_setForeignNative`/`_foreignNative` 818-832;
  withdraw 873-884; `_withdrawTo` 1007-1049; `claimFees` 1061-1106; stake gate 1144-1145;
  minGaugeWeight 1199-1201; sweeps 1241-1243/1655-1657; transfers 1259-1307; `syncRanges`
  1439-1458; `setBallotGate` 1469-1545; `_effectiveClaimFee` 1558-1586; `claimFeeFor` 1613-1616.
- `sources/ramp/src/libraries/LedgerLib.sol`: creditFees 102-122; `_split` mints 140-141;
  fully-staked 191-208; skim 239-250; accFee 251-252; `claimFeeFor` 264-290; `recordClaimFee`
  298-321; `validateDistributor` 329-350; `_takeStakedCut` 447-461; `settleUser` 478-552;
  `onUnlock` 559-581; `_settlePrincipal` 659-675; `_checkBound` 693-706; `_redeem` 709-713;
  sweeps 735-772; `_resolvePrincipal` 793-819.
- `sources/rampeth/src/base/FablesNativeETH.sol`: weth probe 210-242; `receive` 253-255;
  native sweeps 264-284 / 296-322.
- `sources/rampeth_06a88987/src/base/FablesLedger.sol`: `_refundNative` 450-455; deposit 393-441;
  `withdraw` zero-only `to` check 488; (no `_checkPayoutTarget` anywhere).
- `sources/rampeth_06a88987/src/FablesRampETH.sol`: `receive` 94-96.
- `sources/ramp/lib/v4-core/src/ERC6909.sol`: transfer/transferFrom/allowance 25-48.
- `sources/pm/src/PoolManager.sol`: unlock lock 103-113; modifyLiquidity 144-183; take 289-295;
  mint/burn 320-334; `_settle` 347-361; `CurrencyReserves.sol` (synced slot reset);
  `libraries/SqrtPriceMath.sol`: signed deltas 261-271.
- Live: pool `0xbac3aa3b…` (registry), old hook balance 0, PM claims 11 348 742 292 962 157 300,
  rampeth `claimFeeOwed(0x0)` 393 528 520 371 224 300 vs PM native claims 741 144 276 450 536 218,
  AccessManager `hasRole`/`getTargetAdminDelay` reads, restricted-call eth_call reverts.
