# FilDA on BTTC — live external-unprivileged (E-U) extraction assessment

**Target:** L2-08 (FilDA / BitTorrent Chain, chainid 199) · **Date:** 2026-10-15 · **Mode:** read-only
(eth_call / eth_getLogs / eth_getStorageAt only — no transactions, no keys, no state changes)
**Latest blocks used:** markets `74094557` · accounts `74095104` · liq-plans `74095238` · simulations
`74095420` · probes `74095611` · final snapshot `74095812` · **final freshness re-check `74096366`**
(all 5 victims still in shortfall; payable fBTT liquidation still executes to success in eth_call).

## TL;DR

| Question | Answer |
|---|---|
| Can an unprivileged attacker extract value **now**? | **YES — permissionless liquidations** |
| Headline E-U | **≈ $6.21** (max), realistic net **$5.5–6.2** after costs |
| Confidence | **High** on mechanism (source + on-chain simulation + control test + historical liquidations); medium-high on net realization |
| Key address | victim `0x0dfd9fc5a3abefc047168830c10111bca895305f` (≈ $5.05 of the total) |
| Everything else | closed / privileged / holder-only (proofs below) |

## 1. Protocol & roles (all verified on-chain)

- Comptroller (Unitroller proxy) `0xe52792e024697a6be770e5d6f1c455550265b2cd` → impl
  `0xdb82850b0d28fbc3e00ded5b309cf13fa0165cfb` (**Qstroller** — `qsConfig()` + `safetyGuardian()` respond).
- QsConfig `0x5cab5ea2e616d9d8ed89b3420540f21cc5ac7698` (owner = admin multisig; safetyGuardian = pauseGuardian
  EOA). `compRate = 0` (rewards flywheel dead), `safetyVaultRatio = 0.1` (only affects `calculateSeizeTokenAllocation`,
  which the deployed cToken liquidation path does **not** use), `flashLoanFeeRatio = 0.0001`.
- Oracle adapter `0xb2f0fef3631bc222df0e669e39582119804db72b` (verified `ChainlinkAdaptor`, governance = multisig).
- **admin** `0x8bcb316f2d9313c8a9dbe9fdf1210f5243a81479` = unverified contract, `getOwners()`→3 EOAs,
  `required()`→**2-of-3 multisig** (P). **pendingAdmin** `0xc036cd9a16ab34f0bb317cdf2103e5cc3c7ba376` =
  1-of-4 multisig, **never accepted** (P; latent governance-migration risk).
- **pauseGuardian** `0x05ddc595fd33d7b2ab302143c420d0e7f21b622a` = **EOA** (deployer of all markets, nonce 240).
- Pause state at latest: `mintGuardianPaused=0`, `borrowGuardianPaused=0` (per market **and** global),
  `transferGuardianPaused=0`, `seizeGuardianPaused=0` → **everything open**.
- Global params: `closeFactorMantissa = 0.5`, `liquidationIncentiveMantissa = 1.15e18`,
  per-market liquidation incentive 1.2 for fBTT/fTRX collateral, 0 (=global) for fUSDT/fUSDC/fETH.
- Caps (QsConfig): fBTT borrow cap 1.5625e30, fUSDT 2 500e6, fTRX 14.7e9, fUSDC 2 500e6, fETH 818e18;
  supply caps ~2× borrow caps; **flashLoanCap = 0 on all → flash loans disabled**. No
  `CreditLimitChanged` / `WhitelistChange` / `BlacklistChange` events were **ever** emitted → no privileged
  unlimited-borrow addresses; victims are not blacklisted (`getCreditLimit`=0, `blacklist`=false).

## 2. Markets (block 74094557 + validated re-read 74095812; oracle prices are BTT-denominated)

| market | underlying | cash (USD) | borrows (USD) | reserves (USD) | supplier claim (USD) | exchRateStored | mint/borrow paused | oracle price vs real |
|---|---|---|---|---|---|---|---|---|
| fBTT `0x65019969b8308f062548d25b1483add15c582d5b` | WBTT 18d | 55.42 | 8.07 | 13.74 | 49.76 | 2.3513e16 | 0/0 | native market → hardcoded 1e18 (correct: 1 wei BTT = 1 wei BTT) |
| fUSDT `0x590052be9ad26e51f2f1382d29338fcc4c04bfbf` | USDT_t 6d | 2 026.05 | 24.19 | 1 977.08 | 73.15 | 25 118 | 0/0 | 2.8378e36 ≈ $0.999 (±0.1%) |
| fTRX `0x1b596e1fdd1d4895cf30f034ef1b7b6a8942136e` | TRX 6d | 10 001.77 | 4 912.21 | 893.82 | 14 019.87 | 23 035 | 0/0 | 9.4203e35 ≈ $0.3316 (±0.1%) |
| fUSDC `0xaee67519049092ab91efd033f7d350d62b9f166b` | USDC_t 6d | 2 305.76 | 73.93 | 2 313.99 | 65.69 | 95 916 | 0/0 | 2.8401e36 ≈ $0.9997 (±0.05%) |
| fETH `0xa258bffd5f6814303a718d2b9d34b40e14c66289` | ETH 18d | 1 436.36 | 0.62 | 1 077.79 | 359.19 | 2.1488e16 | 0/0 | 6.7193e27 ≈ $2 365.19 (±0.03%) |

TVL = cash+borrows ≈ **$20 844**; reserves ≈ **$6 276 (P)**; supplier claims ≈ **$14 568 (H-O)**.
`exchangeRateStored` matches the live invariant `(internalCash+borrows−reserves)/totalSupply` for all markets
(rounding-level diffs only). All 5 markets use **stored `internalCash`** accounting (CErc20Delegate and
CWrappedNativeDelegate both), so direct token transfers do **not** change the exchange rate.

## 3. Oracle — privileged pipeline, no unprivileged write path

`ChainlinkAdaptor.getUnderlyingPrice` → for wrapped-native returns hardcoded `1e18`; otherwise
`price = feed(asset)/feed(BTT) × 10^(36−d)` (BTT-denominated Compound convention, internally consistent).
Feed freshness at read: `updatedAt` ≈ 54 min–1.3 h old; all 5 answers match DefiLlama within ~0.5%.

Deep-dive: each asset feed (`0xf67ef5e7…` BTT, `0x489d5e73…` USDT, `0xbf2eba1c…` TRX, `0xd2417f4b…` USDC,
`0xea1ca194…` ETH; all owner = pauseGuardian EOA) wraps aggregator
`0xda7a001b254cd22e46d3eab04d937489c93174c3` (owner EOA `0x10e0a94d30e1eb07fe003e5ca25f90bc4547d355`,
nonce 4; `setRef(address)` **owner-gated** — random caller → `Ownable: caller is not the owner`) → ref
`0xf4a07d980a56f67f6ea178c3918b21dcae1b4e50` (no setters; slot0 fixed) → `0x328d15ac…` (Ownable, owner =
`0x10e0a94d…`) → custom push-oracle `0xc0a3e3d7f8e911dbaa909acde2595342ae3badc9` (AccessControl:
`activate(tunnelId,seq)`, `listing(symbols)`, activator roles — **role-gated**).
**Conclusion: no permissionless price-setting function exists at any layer.** Caveat (latent): the adapter does
no staleness check, so a stalled pusher would freeze prices (not a live path today).

## 4. Empty-market / donation test — CLOSED (with exact math)

- No market has `totalSupply == 0` (fBTT 5.98e24 wei, fUSDT 2.91e21, fTRX 1.83e24, fUSDC 6.85e20, fETH 7.07e18).
- `mint`/`redeem` use standard Compound math: `tokens = amount×1e18/er` truncating, `amount = tokens×er/1e18`
  truncating → round-trips always lose dust. `er = (internalCash+borrows−reserves)×1e18/totalSupply` computed
  **live** (no cache).
- Donations: for CErc20 markets a direct token transfer changes `balanceOf` but **not** `internalCash` →
  `er` unchanged; anyone may call `gulp()` and the excess goes to **`totalReserves`** (spendable only by admin).
  fBTT (wrapped-native) additionally ignores stray native BTT except via `gulp()` → also reserves
  (2 950 609 stray BTT ≈ $1.04 → admin). Donation to inflate `er` therefore (a) doesn't even move `er`, and
  (b) would only revalue the donor's own tokens in any case → **no profitable path**.
- The only "empty-ish" bandwidth is fUSDT/fUSDC whose `er` is tiny because reserves ≈ cash (97–100%);
  suppliers got diluted, but reserves are admin-only (P).

## 5. LIVE E-U: permissionless liquidations (the deliverable)

Enumerated all 773 `Borrow` events (Etherscan V2 logs, 5 markets, complete) → 57 unique borrowers, 14 with
open debt. `comptroller.getAccountLiquidity()` at block 74095104 says **5 accounts are in shortfall now**:

| victim | collateral (real USD) | debt (real USD) | best liquidation | seized | **profit** |
|---|---|---|---|---|---|
| `0x0dfd9fc5a3abefc047168830c10111bca895305f` | fUSDT 19.999 + fETH 18.671 | fBTT 8.072 + fUSDC 58.433 | repay 17.3702 USDC→seize all fUSDT; repay 16.2344 USDC→seize all fETH | 38.6515 | **$5.0469** |
| `0x4e92b67c1a0dc26f346e822ddf0d7395427285b6` | fUSDT 8.481 | fUSDC 15.495 | repay 7.3734 USDC→seize all fUSDT | 8.4814 | **$1.1080** |
| `0xfa000ac96119db8ae14f89f86f5e2948af19406c` | fBTT 0.330 | fUSDT 0.635 | repay 0.2734→seize | 0.3298 | $0.0564 |
| `0xf86520e8559ff8807ecfa5674f69f3725c25aa34` | fBTT 0.00766 | fUSDT 0.00442 | repay 0.0022→seize | 0.0027 | $0.0005 |
| `0x05677a84098943fd5187819791f324efc2895c97` | fUSDT 0.00497 | fUSDT 0.00400 | repay 0.0020→seize | 0.0023 | $0.0003 |
| | | | | **TOTAL** | **≈ $6.21** |

- Seize quotes computed **on-chain** via `comptroller.liquidateCalculateSeizeTokens(0xc488847b)`; every
  `seizeTokens ≤ victim cToken balance` (checked for each leg, incl. the near-100% fUSDT/fETH legs above).
- Close factor 0.5 is applied per call; the two victim-1 legs are two separate calls (17.37 ≤ 29.22 then
  16.23 ≤ 20.53 of the remaining balance) — total repay equals the collateral cap ($38.67/1.15).
- **End-to-end simulations (read-only `eth_call`, no tx):** `liquidateBorrow` from an unfunded sender for the
  USDC legs reverts **only at USDC `transferFrom`** (i.e., all comptroller gates passed); the payable fBTT leg
  (`0xaae40a2a`, native BTT, no approval needed) executed to **success (`0x`)** from an address holding BTT —
  repaying 4.036M and 11.40M BTT of victim-1's debt and seizing fUSDT/fETH. **Control:** repay > 50% of debt
  reverts `!l (03)` (TOO_MUCH_REPAY via COMPTROLLER_REJECTION); the 9 healthy open-debt accounts return
  error 3 (INSUFFICIENT_SHORTFALL) on all probed pairs → the discriminator is sound.
- Historical corroboration: liquidations have executed before on this deployment — fBTT block `70713470`
  (liquidator `0x98c89980…` repaid 1,000,000 BTT of victim-1, seized fETH) and fTRX blocks `51227430/51227465`
  (in-kind). Nobody is currently finishing the job.
- Unwind: seized fUSDT redeems against fUSDT cash ($2,026 ≥ claim), fETH against fETH cash ($1,436 ≥ 0.0079
  ETH), fBTT native. Attacker funding: ~$34 USDC_t (bridge/DEX) **or** borrow USDC_t from fUSDC itself after
  depositing ~$42 of any listed collateral (fUSDC cash $2,306, cap 2,500) — verified available.

## 6. Visited and closed (do not re-investigate)

`getAllMarkets` = exactly 5 markets · no global/perp/isolated modes · reentrancy guards on every entry point
(nonReentrant in the verified delegates) · `seize` requires comptroller check + balance check · comptroller is
Qstroller (healthy `getAccountLiquidity` route) · `sweepToken` unauthenticated but pays **admin** (no attacker
profit) · `_reduceReserves`/`_setImplementation`/`_setPriceOracle`/oracle `setAssetSources` all admin/multisig ·
markups: `borrowFactorMantissa = 1e18` everywhere (no synthetic leverage) · `maxAssets` not enforced (harmless) ·
compToken `xFilDA` flywheel dead (`compRate = 0`, comptroller holds 1.03 xFilDA — dust/unreachable).

## 7. Bottom line

**E-U ≈ $6.21** (max; realistic net $5.5–6.2 after USDC_t acquisition slippage and gas; gas on BTTC is
negligible). Call path: `liquidateBorrow(victim, repay, cTokenCollateral)` (0xf5e3c462 CErc20 /
0xaae40a2a payable CWrappedNative) — permissionless, no allowlist, no pause, no privileged role needed.
Preconditions: attacker capital (~$34 USDC_t or ~$42 listed collateral), oracle prices within ~0.5% of market
(they are, feeds <1.3 h old). Everything else in the protocol is **P** (reserves $6.3k, governance) or
**H-O** (supplier claims $14.6k) — not E-U. If the protocol's owners repay/dust the 5 positions (or fix the
close-of-job by liquidating them), E-U drops to ~$0; the residual latent risks remain (freeze-prone oracle
pusher, unaccepted pending admin multisig).

## 8. Evidence files (this folder)

`filda_markets.json` `filda_oracle.json` `filda_qsconfig.json` `filda_accounts.json` `filda_liq_plans.json`
`filda_liq_probe.json` `filda_sim.json` `filda_final.json` `filda_events.json` `filda_qsconfig_events.json`
`filda_eu.json` + verified sources `filda_oracle_source.sol`, `filda_cerc20delegate_source.sol`,
`filda_cwrappednative_source.sol`, `filda_unitroller_source.sol`, `filda_comptroller_extract.sol`,
`filda_qstroller_extract.sol`, `filda_qsconfig_extract.sol` + scripts `filda_*.py`.
