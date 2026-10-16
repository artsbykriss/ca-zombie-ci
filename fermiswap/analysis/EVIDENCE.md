# FermiSwap Z3-H16 — consolidated evidence (read-only, on-chain citations)

All reads are `eth_call`/`eth_getCode`/`eth_getLogs`/`debug_traceCall` only. No transactions were sent.
Fork tests ran in GitHub Actions (`artsbykriss/ca-zombie-ci`) on `vm.createSelectFork`.

## 1. Address book (all verified live, Oct 2026)

| Role | Address | VERSION | Verified | Notes |
|---|---|---|---|---|
| traderVault (inventory) | `0x585d44727129B9C69791B10238Ca605932938B4F` | 20260421? (has `VERSION`) | no | BaseManager-family; holds ~$5.3M |
| FermiSwapper (old) | `0xb1076fE3AB5e28005C7c323Bac5AC06a680d452e` | 20260421 | yes | vault allowance = 0 |
| FermiSwapper (new) | `0x5979458912F80B96d30D4220af8E2e4925A33320` | 20260604 | yes | vault allowances ~MAX |
| FermiEngine (3) | `0x90f73feA1Ee2dC514D4dbac0bFf7fF04B933767f` | 20260720 | no | reads PrioUpdateRegistry live |
| FermiEngine (4) | `0x0109AA912B58508886a2a707204B0F8C8b164CCc` | 20260907 | no | internal per-lane prices |
| FermiEngine (2, old) | `0xe514a3c48da8B233f65B5D15bA1905d6d35bFE48` | 20260521 | no | no live swapper points to it |
| FermiEngine (1, old) | `0x0Ba5665583a4593A86cDC935eA2c8Ff378c11317` | 20260421 | no | no live swapper points to it |
| PrioUpdateRegistry | `0xDa7AfeeD01fe625CF15d187a19f94B45f00b8C5F` | — | yes | shared price-update registry |
| Arb executor 1 | `0xB4723899a492330fedACcf22ec12F53A06e3B659` | 20260220 | no | UniV3 arb, trader-gated |
| Arb executor 2 | `0xeff407D968de7d312Fd5e036AEf8837b3679d777` | 20261006 | no | UniV4 arb, trader-gated |

**Managers / operators (EOAs):**
- `0x7117ca30af85706b964100dd8fbbe78f2fb6d3d8` — vault manager + old swapper manager. Proof: `vault.withdrawAllEth()` passes the `onlyManager` gate from this EOA, reverts `NM` from others (block 26,202,614).
- `0xff67d7211d4837607d601e65f27b97622540c47f` — new swapper manager + engine3/engine4 manager + ARB1/ARB2 manager. Proof: `swapper2.setVaultAddress(0xdead)` and `engine4.setSwapper(0xdead)` pass from this EOA, revert `NM` from others (block 26,202,614).
- Deployer: `0xf6860bb3956ace3a00fa4d43b5d7e8c4c94fd946` (vault, old swapper).

**Tokens:** WETH `0xC02a…6Cc2`, USDC `0xA0b8…eB48`, USDT `0xdAC1…1ec7`, WBTC `0x2260…C599`, cbBTC `0xcbB7…33Bf`.

**Pairs (base→quote only, 8):** WETH/USDC, WETH/USDT, WBTC/USDT, WBTC/USDC, USDC/USDT, cbBTC/USDC, cbBTC/USDT, WBTC/cbBTC.
`isActive(USDC,WETH) = false` (no reverse direction).

## 2. Quote math (reconstructed)

`swapper.fermiSwapWithAllowances` → `engine.swap(tokenIn, tokenOut, amountSpecified, msg.sender)`.
Engine (4) computes the output from a **provider-posted price** per pair-lane; it does **not** use a
`balanceOf(this)` spot price. Inventory enters in two places only:

1. **Cap**: `debug_traceCall` of a live swap shows the engine `STATICCALL balanceOf(vault)` on WETH and
   the quote token — the payout is capped by the vault's available balance (inventory), not priced from it.
2. **Tiny rebalancing term**: measured empirically (fork, block 26,202,605): donating +1,000,000 USDC to
   the vault moved a 1-WETH quote by +58,359 USDC-units (**0.0024 %**); donating +10 WETH moved it by
   −0.0007 %. Sensitivity ≈ 7×10⁻⁸ per unit donated → gain/cost ≈ 10⁻⁷. Donation is unrecoverable (no
   public path to remove inventory) → economically dead.

**Price feed mechanics:**
- Engine4 `acee8aab(lane, price8dp)`: caller must be an authorized provider → reverts `NP` for others.
  8 lanes, one dedicated provider each (added at block 25,581,3xx = Jul 21, 2026):
  lane `2eec03b8…` (WETH/USDC) ← `0x14e870f0…`, `1f160fb6…` (WETH/USDT) ← `0xfc42be94…`,
  `8572bdba…` ← `0x14ffd5d4…`, `9ea51877…` ← `0x842089e5…`, `ea14b3e8…` ← `0x47667e5c…`,
  `35d0b076…` ← `0xd6d3c12e…`, `fb19e614…` ← `0x70a387e6…`, `535ef089…` ← `0x21662401…`.
  Any authorized provider may post any *registered* lane (matrix test); unknown lane → `UP`.
- Freshness: `engine4.unlocked(tokenIn,tokenOut)` is true only if an update landed **in the current block**
  ("SP" otherwise). Verified: update at block 26,202,488 → `unlocked` false at 26,202,489.
- Engine3 reads the registry live: `getState(lane, block.timestamp, block.timestamp)` (min == max),
  reverting `StaleUpdate` (0x666a2814) when stale. Registry writes: `updateState(...)` reverts
  `NotAuthorized` for non-updaters; `MAX_UPDATE_AGE = 0`, `MAX_UPDATE_LEAD_TIME = 0` (kills old-signature
  replay). Engine3's 8 updaters still authorized (`isUpdater(engine3, ·) = true` for all, block 26,202,373).
- Swap-time price band `"PB"`: single post ≤ ~+45 % passes, +49 % reverts; step-ratcheting (walk +3 %/step
  ×12, +20 %/step, +40 %/step) tops out at ~1.44–1.72× before `PB`; `vm.warp(+1 h)`/`vm.roll` did not
  refresh the reference in-test. Practical bound: **≈ +45 % price inflation per epoch**.

## 3. Live state (CI snapshot, block 26,202,605, 2026-10-16 04:09 UTC)

```
vault WETH  = 874.926142761492545997   (~$2.13M @ $2435.04)
vault USDC  = 2,731,601.402287         (~$2.73M)
vault USDT  =   147,922.912053         (~$0.15M)
vault WBTC  =         0.00086738       (~$71)
vault cbBTC =         3.73635507       (~$0.31M)
TOTAL ≈ $5.31M   (fluctuates ±10 %/hour: live trading)
```

Allowances from the vault (same block): WETH/USDC/USDT/WBTC/cbBTC → new swapper ≈ MAX
(2²⁵⁶−1 minus small consumption, e.g. USDC: 2²⁵⁶−1−680,001.97 USDC consumed); WETH/USDC/WBTC → ARB1 ≈ MAX;
WETH/USDC → ARB2 ≈ MAX; old swapper = 0. `unlocked(WETH,USDC) = false` at the snapshot block.

## 4. Gates verified live (all from a random address / fork tests)

| Path | Call | Result |
|---|---|---|
| Vault withdraw | `withdrawAllTokens/transferToken/executeGeneral` | `NM` |
| Engine4 price post | `acee8aab(lane,price)` | `NP` |
| Registry write (engine3) | `updateState(engine3,lane,ts,[price])` | `NotAuthorized()` |
| Arb executors | fallback route calldata | `NT` (trader-gated; traders = team EOAs) |
| New swapper swap, no fresh update | `fermiSwapWithAllowances` | `SP` |
| New swapper swap, fresh update | same | executes at posted price |
| Old swapper swap, fresh registry lane | same | revert `ERC20: transfer amount exceeds allowance` |
| Engine4 swap with absurd price | post 1e15 then swap | `PB` (price band) |

## 5. Unprivileged extraction measurements

- **Local live run** (fork at ~block 26,202,530, an update landed in that block):
  unprivileged swap 1 WETH → **2,436.503792 USDC** (effective $2,436.50/WETH) vs market
  $2,435.72 (DefiLlama) → **+0.03 % gross**, below gas/priority cost; the same block's posted lane price
  was $2,436.716 → engine spread ≈ 0.87 bps.
- **Posted-price tracking**: block 26,202,530 posted $2,436.72 vs market $2,435.72 (+4.1 bps);
  block 26,202,487 posted $2,431.95 vs market ~$2,427.70 (+17 bps). No systematic mispricing.
- **Donation**: delta 58,359 / 2,427,507,653 = 0.0024 % (T8).
- **Same-block impact** after a 10 WETH swap: delta 61,304 / 2,427,507,653 = 0.0025 % (T9) — no sandwich surface.
- **Provider-key conditional**: with a provider key, post +45 %-band prices and ratchet; at +45 % the vault
  overpays ~31 % of the drained amount → draining the 2.73M USDC inventory costs ~708 WETH (~$1.72M at
  market) and nets ~$0.78M per epoch for the USDC lane alone (T11 shows the `PB` guard blocks single-step
  absurd prices; BandProbe shows the ratchet works to ~+45 %).

## 6. Timeline

- 2026-04-22: vault deployed; 04-26 → 06-11: 596 swaps via old swapper (single-user dominated);
  engines rotated 05-21 / 05-28 / 07-21; 06-08: new swapper deployed (engine2 → engine3 → engine4);
  09-07/08: engine4 (VERSION 20260907) deployed, allowances re-pointed, registry lanes last written ~09-01;
  swaps continued to 09-16; **dormant 09-16 → 10-15**; **re-armed 10-15 12:46 UTC** (engine4 updates resume);
  active at time of writing (updates every 1–3 blocks; solvers arbitraging UniV3/V4 against the vault).
- Vault operator (`0x7117ca30af…`) last touched the vault 10-15 15:41 UTC (executeGeneral + withdrawAllEth).

## 7. Prior corpus claim vs finding

Corpus: "swap pricing reads the contract's own inventory → donation/sandwich-manipulable quote."
**Refuted**: pricing is provider-posted (8dp, per-block freshness); inventory is an output cap plus a
≤0.003 % rebalancing term; donation is unrecoverable; no same-block price impact.
