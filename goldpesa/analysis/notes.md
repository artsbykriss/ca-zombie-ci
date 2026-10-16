# Z3-H5 GoldPesa — analysis notes (evidence + derivations)

All reads at Base block **52,660,634** (chain tip 2026-10-16 ~01:00 UTC). Raw dump: `../ci-out/state.json`.
Sources in this folder: verified hook bundle files (`GPXHooks.sol`, `GPX.sol`, `GPXOwner.sol`, `BaseHook.sol`, `AmountsHelper2.sol`, `GPMTreasury.sol`, `GoldPesaMines.sol`, `Pawn.sol`, `GPOVault.sol`, `ref_*` v4-core libs), `gpx_math.py` (exact integer replica), `hook_abi.json`.

## 1. checkRebalance replica (cross-checked: Python ⇄ Solidity fork test)

Inputs (live):
- `L = 23,063,189,219,641,299` (pool liquidity == position 3106206 liquidity; sole position)
- `sqrtPriceX96 = 180,051,204,617,000,423,516,900`, `tick = −259,906`
- position range `[−275,982, 887,272]`
- `usdcInsideUniswap = L(sp−sp_lo)/2⁹⁶ = 28,951,640,789`
- `gpxInsideUniswap = 10,148.524734826689003623e18`
- `circ = 100M − 99,930,888.384260767462321773 − 10,148.524734826689003623 − 971.776010345558154699 = 57,991.314994060290519905 GPX`

`aX96 = usdc·2¹⁹² / (circ·sp) = 1.74e22` → `simulatedTick = −306,638`.
Band `(−275,982, −259,906)`; `−306,638 ≤ −275,982` → **checkRebalance FALSE** (gap 30,656 ticks; aX96 must grow ≈4.63×).
Condition 7 (`−275,981 + 9,624 = −266,357 ≤ −259,906`) is TRUE — condition 6 is the binding one.

## 2. Trigger algebra (price-independent)

`simTick > lowerTick ⟺ L(sp−sp_lo)/(C·sp) > sp_lo ⟺ C < L/sp_lo − L/sp` (Q96-exact via `L·2⁹⁶/sp_lo`).

With `C = N′ − x_pool − T` and `x_pool = L(1/sp − 1/sp_hi)`:
`N′ − T − L/sp + L/sp_hi < L/sp_lo − L/sp` → **`T > N′ − L·2⁹⁶/sp_lo + L·2⁹⁶/sp_hi ≈ N′ − 22,672.15`** (sp_hi = MAX → last term ≈ 0).

Numbers: `N′ = 69,111.6157 GPX` → **threshold T = 46,439.46 GPX** (price/trade-independent; the pool-flow term cancels exactly).
Today T = 971.78 → **need +45,467.7 GPX (48×) into the treasury**, i.e. **66% of ALL non-reserve GPX**.

## 3. Why the treasury cannot be pushed there (cost bound)

- `GPX._update` guard: `if (from != gpxHook && to == treasury) revert UnauthorizedTreasuryTransfer` → **direct donations impossible**.
- Treasury inflows: transfer fees (0.5% of value) + swap GPX fees (0.25% of input). Fee splits: treasury = 50%, mines = 25%, pawn = 25%.
- To add X to the treasury, payers lose **2X** in fees. → +45,467.7 to treasury ⇒ **≥90,935 GPX of fees (~$469.6K nominal)**; ≥$234.8K even with perfect recycling of the pawn share.
- `GoldPesaMines` has **no GPX outflow** (grep of all transfer calls) → the mines' 25% share (**22,733.9 GPX**) is permanently stuck. Pawn converts GPX→GPO via GPOVault (GPX leaves circulation; vault can pay out to users, so partially recyclable).
- On-chain acquirable GPX: **10,148.5 GPX** (this pool; ~$52K with impact). Remaining supply is with users; no other market (DexScreener: this pool only, $12/24h).
- Natural rate: treasury = 971.8 GPX after the protocol's lifetime; pool volume ~$12/day.

**Conclusion:** trigger reachable only via economically absurd destruction ($235K–$470K for ≤$28.95K). Not a live E-U path.

## 4. Conditional extraction bound (fork-proven with mocked trigger)

`B = usdcInsideUniswap = 28,951,640,789` (USDC side). `TAKE_PAIR` takes the PM's net delta; `DeltaResolver._getFullCredit` reverts `DeltaNotPositive` when net < 0 → **D ≤ B**. Attacker's own burn+take then withdraws D.
Mocked trigger (vm.store hook slot 9 `gpxReserves`, C≈10,000 GPX): D=$28,000 → stolen 28,000; D=B+1 → revert; D=115K (2026-10-02 size) → revert. GPX side (10,148.5 GPX) nominally stealable via attacker-created GPX pool, but realizable only against the same pool's USDC → total realizable ≈ **$28.95K**.

## 5. Residual allowances (the one angle the prior sweep missed) — verified NOT extractable

Live: Permit2 `allowance(hook, GPX, POSM) = 92.781203640212676485` (exp `uint48.max`, nonce 0); USDC = 338.686030; ERC20 hook→permit2 identical; hook GPX balance 99,930,888.384; hook USDC = 0.

Deployed Base PositionManager (`0x7C5f5A4b…`, Sourcify-verified, older v4-periphery):
- `SETTLE` decodes `(Currency currency, uint256 amount, bool payerIsUser)`; `BaseActionsRouter._mapPayer(bool) = payerIsUser ? msgSender() : address(this)`.
- `PositionManager.msgSender() = ReentrancyLock._getLocker()` = the caller of the PM entry point.
- ⇒ the payer can only be the caller or the PM itself. **The hook can only be the payer when the hook itself calls the PM** (its own `reBalance`). No third party can name the hook.
- The USDC allowance additionally requires hook USDC > 0; the hook receives USDC only inside `reBalance`.
Negative control in `test_T5` (SETTLE with payerIsUser=false) reverts as expected.

## 6. Historical corroboration

- Incident tx `0x5c1febd5…51ad2c9` (block 52,078,502): Morpho flash loan 175,000 USDC (input shows Morpho/PM/POSM/hook/USDC/WETH/GPX + `0x28bed01600` = 175000e6), theft 114,999.999186 USDC.
- `lastRebalance = 1,790,946,351` = 2026-10-02 13:05:51 UTC = the incident tx timestamp; no rebalance since (position 3106206 minted by that rebalance, `nextTokenId` sequencing: phantom 3106205 → hook re-mint 3106206).
- Hook codehash `0x892c8ee3…79e3` stable across recent blocks; no proxy/delegatecall in source; no upgrade function.

## 7. Negative results recorded (do not re-investigate)

- Single-sided swaps cannot enter the band (buys: max `simTick ≈ −290,580` even buying the whole pool; sells: `simTick` strictly decreases; deep sells → `usdcInsideInPool = 0` → early false). Fork sweep T2.
- Phantom-debt replay on live state = $0 for D ∈ {1K, 10K, 28,951.64, 100K} (no rebalance; burn+take is net-zero).
- Residual allowances unspendable (PM payer model, see §5).
- NFT burn/decrease by third parties reverts (`onlyIfApproved`).
- No other GPX market exists (only this pool).
