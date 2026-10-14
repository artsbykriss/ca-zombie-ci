# ReactorFusion Telos — Summary (oracle, positions, liquidation outlook)

Date: **2026-10-14**. All read-only (no transactions signed/sent). Chain: **Telos EVM (id 40)**.
Key blocks: head at probe time **≈ 493,963,354–493,965,000**; oracle switches at **313,919,449**
(2023-12-07) and **387,669,171** (2025-02-06); latest DIA feed updates **2026-10-06/07**.
Full evidence: `telos-oracle-mechanics.md`, `telos-positions.json`, `telos-probe*.json`, `telos-sources/`.

---

## (a) Exact oracle mechanism — and can an unprivileged attacker move prices?

**Current oracle = DIA, not Redstone.** The Comptroller/Unitroller
`0x19646a04BfDcf3553Adc8fAAf8B16D76EC41E494` uses `oracle()` =
**`0x0fa9de8362e662d6659a05ad284a2f454f49a8e2`** (verified `SimplePriceOracle`, "OmniDex"). It reads a
**`DIAOracleV2`** at `0x86c5997d10d1df6cbb15c01280e596ed5ac90a33`:

- `getUnderlyingPrice(cToken) = dia.getValue(assetsKeys[cToken]).price × 10**(28 − cToken.decimals())`.
  DIA prices are **8-decimal**; in this fork `cToken.decimals() == underlying decimals` (6 for USDC/USDT,
  18 for ETH/TLOS) → final scale **1e30 for stables, 1e18 for ETH/TLOS** (Compound-standard
  1e(36−underlyingDecimals)).
- Keys: `USDC/USD`, `USDT/USD`, `ETH/USD`, `TLOS/USD`.
- `DIAOracleV2.setValue(key,value,ts)` is **restricted to `oracleUpdater` =
  `0x4b4c4a6e760fdea078efc6bea046946b639bddea`** (EOA; DIA's updater). `eth_call` simulation: `setValue`
  reverts for a random sender and for the oracle owner; succeeds only from that updater.
- **No staleness check anywhere** — the DIA timestamp is discarded; the Comptroller never checks freshness.
  Feed values are currently **~7.5–8.3 days old** (last update 2026-10-07 07:05:40 UTC for TLOS/USD).
- **Unprivileged price manipulation: NO on-chain path found.** Price writes require (i) DIA's updater key
  (trust/key-compromise, not unprivileged) or (ii) the oracle owner / Unitroller admin EOA
  `0x99999a3c4cb8427c44294ad36895b6a3a047060d`, which can `setDIAOracle(arbitraryContract)` or replace the
  oracle entirely (`_setPriceOracle`/upgrade) — privileged, no timelock on Telos.
- **Historical:** from 2023-12-07 to 2025-02-06 the oracle was `0x3b7023f3c99eae2fa0aaeb9490a78d5d98a24148`,
  a Redstone `SimplePriceOracle` with **permissionless `push(bytes32[])`** that only accepted
  `redstone-main-demo`-signed packages (**1-of-1 signer** `0x0C39486f770B26F5527BBBf942726537986Cd7eb`).
  It is deployed but disconnected; only an admin re-pointing could make it live again.

**Price verification** (oracle vs live, 2026-10-14):

| Asset | Oracle (stale DIA) | Live | Δ |
|---|---|---|---|
| rfTLOS | **0.01931047** | 0.01895246 (CoinGecko) | **+1.89%** |
| rfETH | 2,616.20618299 | 2,437.51 (DefiLlama) / 2,425.77 (CoinGecko) | **+7.33% / +7.85%** |
| rfUSDC | 0.99974455 | 0.99974701 | −0.000% |
| rfUSDT | 0.99969496 | 0.99930840 | +0.039% |

Note: the raw `getUnderlyingPrice(rfTLOS)` value `19310470000000000` is **$0.01931047 at 1e18 scale**, not
$19.31 — the $19.31 figure was a 1000× scale misreading. TLOS at ~$0.019 is consistent with CoinGecko
(market cap ~$8.56 M).

## (b) Real TLOS vs oracle

- Real TLOS ≈ **$0.01895–0.01896** (CoinGecko, 18:13 UTC); oracle says **$0.01931047** → **+1.85–1.89%**.
- ETH: real ≈ **$2,426–2,438**; oracle says **$2,616.21** → **+7.3–7.9%** (ETH fell after the last DIA push).

## (c) Positions and liquidation outlook (4 markets, block ≈ 493,963,354)

Coverage: **86 current cToken holders** (Teloscan holder API; per-market sums equal `totalSupply` exactly)
and **31 borrowers with outstanding debt** (every borrower whose last Borrow/Repay event was non-zero was
probed on-chain; their per-market sums equal on-chain `totalBorrows` → **100% of debt covered**). All 31
probed accounts' on-chain `getAccountLiquidity` matched our independent recomputation (0 mismatches).

Market totals (live USD): cash **$614.48**; borrows **$171.30**; supply-side value **≈ $784**.

**Underwater accounts: 13** (shortfall > 0 in on-chain `getAccountLiquidity`; same 13 at live prices).
Total shortfall **$12.80** (oracle) / **$12.88** (live prices), total debt $24.00, total collateral $16.00 →
estimated **bad debt ≈ $8.00** (mostly two accounts).

| Account | Debt | Collateral | Shortfall $ | Best liquidation (repay → seize) | Gross profit (live, pre-gas) |
|---|---|---|---|---|---|
| 0x1f3e0963…572b | 11.5287 USDC | 291.87 rfTLOS | **7.47** | 5.3726 USDC → 291.99 TLOS (all collateral) | **$0.163** |
| 0xa6476862…760d | 5.4104 USDC | 76.98 rfTLOS | **4.34** | 1.4171 USDC → 77.02 TLOS (all collateral) | $0.043 |
| 0xe0f29a06…52ca | 0.3690 USDT | 4.86 rfTLOS | 0.301 | 0.0896 USDT → 4.87 TLOS | $0.003 |
| 0x089fa7c1…4e00 | 236.7634 TLOS | 315.15 rfTLOS | 0.187 | 236.76 TLOS → 248.54 TLOS (full) | **$0.223** |
| 0x9999922c…20b3 | 0.000066 ETH + 4.5262 TLOS | 11.36 rfTLOS | 0.103 | 0.000066 ETH → 9.45 TLOS | $0.017 |
| 0x4fd9deca…a91f3 | 0.1225 USDT | 1.52 rfTLOS | 0.101 | 0.0279 USDT → 1.52 TLOS | $0.001 |
| 0x0dc4f07d…b216 | 0.1243 USDT | 1.72 rfTLOS | 0.100 | 0.0317 USDT → 1.72 TLOS | $0.001 |
| 0x3a158359…9ef9 | 0.1151 USDC | 1.95 rfTLOS | 0.088 | 0.0358 USDC → 1.95 TLOS | $0.001 |
| 0x36fc7bfe…64bb | 0.0614 USDT | 1.57 rfTLOS | 0.040 | 0.0289 USDT → 1.57 TLOS | $0.001 |
| 0x8eb71139…3802 | 70.6937 TLOS | 97.31 rfTLOS | 0.011 | 70.69 TLOS → 74.21 TLOS (full) | $0.067 |
| 0x327fa761…73ad | 0.0145 USDC | 0.20 rfTLOS | 0.012 | dust | ~$0.000 |
| 0x9fab819d…dbf9 | 0.0639 USDT | 0.76 rfTLOS | 0.053 | dust | ~$0.000 |
| 0x6991c1b4…8398 | 0.000004 USDC | dust | ~0 | dust | ~$0.000 |

**Realistic liquidation profit: ≈ $0.5 gross in total** (best case, live prices, before gas). Largest single
liquidation ≈ **$0.22** (0x089fa7c1, full TLOS self-liquidation). Two accounts hold nearly all the bad debt
(0x1f3e0963: $5.72 uncovered; 0xa6476862: $3.88 uncovered). Constraints checked:
`closeFactor = 1.0` (full repay allowed), `liquidationIncentive = 1.08`, `whitelistedLiquidator = 0`
(anyone may liquidate), protocol seize share 2.8% (already deducted), and all seize amounts are redeemable
against market cash (rfTLOS cash 11,042 TLOS covers every scenario; rfUSDC cash 7.06 USDC only involves dust).
Caveat: at live ETH prices, repaying a non-ETH debt to seize **rfETH** collateral would be loss-making
(−2.2%), so ETH-collateral liquidations are not profitable now; all profitable scenarios above seize rfTLOS.

## (d) Total live Telos cash (market `getCash`, converted at live prices)

| Market | Cash | Live USD |
|---|---|---|
| rfUSDC | 7.056647 USDC | $7.05 |
| rfUSDT | 104.375982 USDT | $104.30 |
| rfETH | 0.120545382167356918 ETH | $293.83 |
| rfTLOS | 11042.734467413018479963 TLOS | $209.29 |
| **Total** | | **≈ $614.48** |

(At the stale oracle prices the same cash is ≈ $640 — mostly the inflated ETH feed.)

## (e) Caveats

1. **Oracle staleness is the defining fact.** All prices are frozen at 2026-10-06/07 values with no on-chain
   freshness check; live ETH is ~7–8% lower than the oracle, so the protocol's own liquidity numbers
   understate how underwater ETH-collateralized debt is (the 13 accounts are underwater at both price sets,
   so liquidatability is robust).
2. **Live TLOS price source:** CoinGecko only ($0.01895–0.01896, mcap ~$8.6 M); DefiLlama has no TLOS/Telos
   entry and DexScreener does not index Telos. Cross-source confirmation is limited.
3. **Probe blocks differ slightly per dataset** (oracle prices ~493,954,038; market params ~493,957,742;
   account snapshots 493,963,354; holders API 2026-10-14). Interest accrues slowly; cross-checks agree to
   <0.02% and all on-chain liquidity matched our recomputation exactly.
4. **Coverage:** debt coverage is complete for the 4 listed markets (probed sums = `totalBorrows` per market).
   The 284 historical borrowers whose last Borrow/Repay event showed zero debt were not individually probed;
   0 × borrowIndex = 0, so they cannot carry debt unless the log scan missed an event — the exact per-market
   totals make that very unlikely. Holders with no debt are not underwater by definition; their collateral
   membership (`getAssetsIn`) was only probed for the 31 debtors.
5. **Profit realism:** profits are dust (cents) and before gas; Telos gas is ~0.04 TLOS (~$0.001)/tx, so gas
   does not change the picture. Realizing profit requires calling `liquidateBorrow` and redeeming seized
   cTokens for underlying (cash is available for the rfTLOS scenarios).
6. **No exploit found.** The only protocol-relevant trust issue remains the single DIA updater EOA (and the
   historical Redstone 1-of-1 demo signer); both are key-trust, not unprivileged, paths.
