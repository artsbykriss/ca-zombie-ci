# Child verification: Arcus pToken claim math & extraction limits

Target: pBTC3x `0x4472C69d299382F8847ebCE4FC6Ed8e295510E3e` (BeaconProxy→impl `0x1815A37b6027Ae8066720d873A508F25fC151AC5`), asset `0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168`, factory `0x9c3663FA9ab976E67B42939486EC4966Cb41a0BB`.
Method: local anvil fork of Robinhood chain (`anvil --fork-url https://rpc.mainnet.chain.robinhood.com --port 8555`), `anvil_setStorageAt`/`anvil_impersonateAccount` + `debug_traceCall` (structLogs/callTracer) + real state-changing `eth_sendTransaction`s on the fork. No mainnet writes.

## 1. Claimable storage map (ERC-7201 base `0xd9fd031555da3bce2baaa52849713cb138dd684400ec2ca4d5930be5a6752a00`)

Two independent per-`msg.sender` pools, each a (assets, shares) counter pair in adjacent slots:

| Pool | slot formula | +1 |
|---|---|---|
| Deposit/mint claims (0x6e553f65, 0x94bf804d) | `CAd = keccak(msg.sender, base+0x12)` | `CSd` |
| Withdraw/redeem claims (0xb460af94, 0xba087652) | `CAr = keccak(msg.sender, base+0x1b)` | `CSr` |

Key is **msg.sender only** — receiver/controller args are destinations, not mapping keys (verified: changing receiver leaves the SLOAD slot unchanged; slot formula reproduced exactly, e.g. keccak(0xaaaa..aa,(base+0x12)) = `0xa887f7e4b593eb42213549856fe8bab7329fba26d6ff15c4e9ff501b35b4c5e8`).

Observed namespace values at fork (block ~89,713,137): `+0x00` factory, `+0x01` asset, `+0x02` = 0xd42c46c7bad6a54b38395f846b09981ce75fb8e2, `+0x03/+0x04` name/symbol, `+0x05`=18, `+0x06`=1000, `+0x07`=1e7, `+0x08`=1, `+0x0a`=0x589d1d601309 (=TA*1000+1, TA=97431825945), `+0x0b`=0x11da3e98c7, `+0x0c` cumulative paid-out assets, `+0x0e`=344.

## 2. Exact claim math (measured, integer-exact)

All four paths move **pre-custodied** balances (shares or assets already held by the pToken); `totalSupply` is unchanged on every claim (no mint/burn).

- `deposit(assets, receiver)`: requires `CSd>0` else `0x9811e0c7`; requires `assets ≤ CAd` else `0x6565c4ec InsufficientClaimable(assets, CAd)`; `sharesOut = floor(assets*CSd/CAd)` (if 0 → `0x9811e0c7`); transfers `sharesOut` **from the pToken's own ERC20 share balance** to receiver; `CAd -= assets; CSd -= sharesOut`.
- `mint(shares, receiver)`: `assetsIn = ceil(shares*CAd/CSd)`; transfers `shares` from pToken custody; `CAd -= assetsIn; CSd -= shares`. (When `CAd` hits 0, further mints still succeed charging 0 — bounded by `CSd`.)
- `withdraw(assets, receiver, controller)`: `controller` must equal msg.sender else `0x5cab937e`; requires `assets ≤ CAr` else `0x6565c4ec`; `sharesIn = ceil(assets*CSr/CAr)`; pays `assets` from the pToken's **asset-token custody** to receiver; `CAr -= assets; CSr -= sharesIn`.
- `redeem(shares, receiver, controller)`: controller==sender else `0x5cab937e`; requires `shares ≤ CSr` else `0x6565c4ec`; `assetsOut = floor(shares*CAr/CSr)`; pays assets from custody; `CSr -= shares; CAr -= assetsOut`.

Rounding is **always vault-favouring or neutral** (floor on shares-out/assets-out, ceil on assets-in/shares-in). No claim path writes totalAssets `+0x0a`; only `+0x0c` (cumulative payout) updates (e.g. withdraw(1e6) SSTORE `...2a0c` = 0x16ba201). Claim entry points are **not manager-gated** — any address is a valid controller with its own counters.

## 3. Chunking / adversarial extraction (real fork txs)

- deposit, pool (CA=3, CS=10): single claim(3) → 10 shares; 3×claim(1) → 3,3,4 = **10 shares** (identical). Formula `floor` confirmed on remainder (7/2 → 3).
- redeem (CA=3, CS=10): single S=10 → 3 assets out; 10×S=1 → 0,0,0,0,0,0,0,1,1,1 = **3 assets out** (identical).
- withdraw (CA=3, CS=10): single w(3) → 3 out, CS spent 10; 3×w(1) → 3 out, CS spent 4+3+3 = **same**; 4th chunk reverts `0x6565c4ec`.
- mint (CA=3, CS=10): 10×mint(1) → total CA charged 3 (=ceil path), CS 10 → same as single mint(10).
- Over-claim: redeem(shares=CSr+1) and withdraw(assets=CAr+1) → `0x6565c4ec`. Deposit/mint when vault lacks the shares → `0xe450d38c ERC20InsufficientBalance(vault, balance, needed)` (observed with CS=1e30 > custody).
- Re-inflation: after draining a pool to 0, transferring shares to the pToken does not change storage; retry → `0x6565c4ec`. Donations only enlarge vault custody.

**Max theoretical gain from chunking = 0 wei of shares/assets (rounding can only lose dust ≤ n−1 wei). Max extractable per path in USD = 0 beyond the credited CA/CS amounts**, which are write-only by the privileged fulfill path.

## 4. Privileged-side gating (revert selectors recorded)

- pToken fulfill sels from attacker: `0x4204bef9`, `0x748e20ef`, `0x4c22fd49`, `0x42cc5a88` → `0x6c981570 NotManager(msg.sender, manager)`; `0x0690a09d` → `0x3ac328da` (epoch). From manager EOA they pass the gate and fail later on args (`0x1f2a2005`, `0x0a8c14ec`, epoch).
- Gate = `msg.sender == factory.managerOf(pToken)` via STATICCALL `0x7f41826b` → factory impl `0x58bdc1d3068a0a79d7a662dee033d62cbd4f589f`. Result: **EOA `0xb7410dc44e2715161e9914272e2d55d7c5061faa` (no code)**. Not signature-only at the pToken level; only that EOA (or factory re-registration) can fulfill.
- Factory sels `0xd3c5ee0e/0x4e666f20/0xfe618ab1/0x8da87eb1` → `0xe2517d3f` for unprivileged. `0xac6ac9a0/0x56478360/0x8152068c` exist on none of pToken/factory/manager (empty reverts); manager-contract `0x006102b1` calling pToken would itself get `0x6c981570`.

## 5. Contradictions / corrections to parent conclusions

1. **Claim math is NOT `convertToShares` at claim time.** Claims are pure pro-rata on counters frozen at fulfill: `floor/ceil(a·CS/CA)`. The `(TS+1e7)*1000/(TA+1)` price formula governs views/fulfill, not claim execution — important for the chunking question (no TS/TA drift between chunks has any effect).
2. `0x9811e0c7` = zero-shares error (also when CS>0 but floor→0); `0x6565c4ec` is the counter cap; both no-arg beyond args shown.
3. Parent's `convertToShares(1e6)=5677240114319981` does not round-trip: `convertToAssets(5677240114319981)=999999`; the consistent value is `5677240114340550` (→1000000). Likely a stale-block reading. Selector `0xc6e6f4c3` reverts on-chain; `previewDeposit` returns 0 for all tested inputs.
4. `totalAssets` (`+0x0a`) is untouched by all claim paths (SSTOREs only at pool slots, token balance slots, `+0x0c`); no unprivileged NAV write found.
5. Deposit claims also require `sharesOut > 0` — a controller cannot dust-drain a pool with CA≫CS.

Fork scripts/artifacts: `/tmp/opencode/arcus-child/{forklib.py,exp_deposit.py,sl_trace.json,tc_latest_2.out}`.
