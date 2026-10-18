# USDD 2.0 on TRON — PSM / CDP map and redeem-arb probe

**Scope:** measurement only. No transaction was signed or broadcast. All reads are `triggerconstantcontract` / public REST at the block recorded below.
**Final state block:** `87,211,072` (`000000000532bc40e836b95ef7588b3e79d30b0be5e6403c6381f37d58585d79`), `2026-10-18T06:50:18Z`.
**Start block:** `87,209,600`, `2026-10-18T05:36:36Z`.
**Target:** USDD 2.0 token `TXDk8mbtRbXeYuMNS83CfKPaYYT8XWv9Hz`; PSM `TBXW4hS5KYjjbJXDpnrPf4zhkLwrpUjbyz`; DSS/CDP core.

---

## 1. Verdict

| Class | USD | Basis |
|---|---:|---|
| **E-U** (external unprivileged, net of fees) | **$0** | No positive round trip at the recorded block. Best on-chain USDD/USDT spot = **0.99999978** (V3 fee 100), V3 fee = 1 bp. Buying 1M USDD and redeeming via PSM = **-$99.79**; minting 1M USDD via PSM and selling on V3 = **-$100.22**. Add ~$8–15 energy. |
| **E-U-conditional** | **$0 current** | Precondition not met. If on-chain USDD/USDT dislocates by ≥10 bp with current V3 depth (1.302M USDD), max ≈ **$1,172**; at 100 bp, max ≈ **$12,890** (V3 depth cap). PSM can redeem 41.23M, so a deep 1% dislocation would be worth ≈ $412k, but no such depth exists on-chain. CEX-only route ≈ **$45/clip** at $25k–$50k, not permissionless and capped by $23k–$55k/day CEX volume. |
| **H-O** (hidden/operational) | **$0** | No leaked/compromised key evidence. Deployer EOA is denied on all core contracts. |
| **P** (privileged) | **$1,230,000,000** theoretical; **$41,232,487** immediate | Pause proxy is a ward on Vat/Jug/Spotter/Dog/Vow/PSM. `Vat.suck(pauseproxy,pauseproxy,rad)` simulated successfully → unlimited unbacked USDD; `PSM.file('tin'/'tout',…)` simulated successfully. GovernorBravo → 2-day Timelock → GovActionsProxy → Pause (delay 0) → PauseProxy. **GovActionsProxy owner is a single EOA** `TSF2rqLdrrZG7PZkDxtvu6B2PTpofidMAX` (119,959,129 TRX ≈ $40M), a potential bypass path. |
| **S** (structural, proven loss) | **$0** | No proven insolvency. Risks: PSM USDT covers only **3.13%** of supply; jUSDD holds **32.31%** of supply; **819.8M** of Vat debt is unattributed to enumerated ilks; old→new USDD exchange is unfunded. |

**Confidence:** 0.82 (0.9 on the E-U price/PSM state, 0.55 on the debt-attribution gap).
**Bottom line:** The named class — permissionless USDD mint/redeem arbitrage — is **open but closed at the margin**. The PSM is a 0-fee, 1:1 USDT redemption facility and is already actively arbitraged (BuyGem/SellGem every few blocks). At the recorded block the on-chain price is at par to 0.0022 bp, far inside the 1 bp V3 fee. The visible ~17 bp “discount” vs $1 is mostly **USDT/USD**: the on-chain par price × the protocol’s USDT/USD oracle (0.99873) already implies USDD ≈ 0.99873, i.e. ~13 bp of the ~17 bp; only ~4 bp is left for thin CEX quotes (BingX 0.9978, Gate 0.9973). The main on-chain pool is at par.

---

## 2. Method and recorded blocks

- TRON state: `POST https://api.trongrid.io/wallet/triggerconstantcontract` with `visible=true`, base58 owner/contract, ABI-encoded params.
- Contract metadata / ABI / source names: `wallet/getcontract`, `wallet/getcontractinfo`, Tronscan `/api/contract`, `/api/transaction`, `/api/transaction-info`.
- Logs/events: Tronscan `internal_transactions` / `trc20TransferInfo`, TronGrid `/v1/contracts/{addr}/events`.
- DEX: on-chain SunSwap V3 factory/pool `slot0`/`liquidity`/balances; SunSwap V2 factory/pair reserves; SunCurve 2pool `get_dy`/`balances`/`fee`.
- Off-chain reference: DefiLlama `coins.llama.fi`, CoinGecko simple price and tickers.
- All values are from the block noted in each dump. Final snapshot block in `raw/final_snapshot.json`; a second read immediately after (`block_after=87,211,086`) showed only normal PSM churn.

---

## 3. Contract graph

All addresses are TRON base58. “Code” is runtime bytes from `wallet/getcontractinfo`; “ABI” is the number of ABI entries returned by `wallet/getcontract` (0 = no verified ABI, code still present).

| Role | Address | Code B | ABI | Notes |
|---|---|---:|---:|---|
| USDD 2.0 token | `TXDk8mbtRbXeYuMNS83CfKPaYYT8XWv9Hz` | 4,089 | 0 | “Usdd Stablecoin”, 18 dec. Created by `UsddFab`. Method map: push/pull/move/rely/deny/mint/burn/permit. |
| PSM | `TBXW4hS5KYjjbJXDpnrPf4zhkLwrpUjbyz` | 4,555 | 24 | `UsddPsm`, ilk `PSM-USDT-A`. |
| PSM gem join | `TSUYvQ5tdd3DijCD1uGunGLpftHuSZ12sQ` | 2,853 | 17 | `AuthGemJoin5`, USDT (6 dec), custodies PSM USDT. |
| Vat | `TH5dhX7o39afSbfDT2e3c9k4itWjNKD4D9` | 8,247 | 0 | DSS core accounting. |
| UsddJoin | `TUajR7CbXU6hX8n3XtNkitFAD25JvP99K6` | 1,804 | 0 | DaiJoin analogue; **only confirmed ward/minter on USDD** (unknown wards not enumerable). |
| Vow | `TXLfZmQtLtLxWYNL2fxhw34JNGHB2EKeSU` | 5,768 | 0 | Surplus/debt sink; sin 2,000.66. |
| Spotter | `TU8Z8CeUd7pnXSMHTNqRgK6Qxxxyzsba1n` | 2,592 | 0 | Price feed / liquidation ratio. |
| Jug | `TWttvCqVmiLip7PL8Aut2Hi37swqv7EmYd` | 2,846 | 0 | Stability fee accumulator. |
| Dog | `TCwYKcDj8c5Te9hjj3UokcxhpY6skFoXnG` | 4,812 | 0 | Liquidation engine. |
| USDT | `TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t` | 14,945 | 46 | TetherToken; PSM gem and USDT-A collateral. |
| Old USDD 1.0 | `TPYmHEhy5n8TCEfYGqW2rPxsghSfzghPDn` | 3,166 | 19 | Supply 7,136,259.98. |
| Old→new exchange | `TQrq2p1aoAkNK94q3Q69ubJcv5nQ9y675R` | 4,729 | 31 | `USDDExchange`; rate 1, paused=false, **unfunded**. |
| Pause | `TNq6E9XsQfrzqVwam67LApZQx1omsj8dyW` | 4,073 | 0 | DSPause; delay 0; authority GovActionsProxy. |
| Pause proxy | `TE6RxGgQuD6J1faw9mZxtbHGDqcKh8DvKU` | 842 | 0 | Ward on Vat/Jug/Spotter/Dog/Vow/PSM. |
| GovActionsProxy | `TXzhj9Xh8xfzerjinRyM5TfoBL7Cw5hk5d` | 10,432 | 30 | Pause authority; owner EOA `TSF2rq...`. |
| GovernorBravo delegator | `TB6QhZHcrYz3sYh3NCxk2sbzfsdhC5rjAU` | 1,189 | 59 | Admin = Timelock. |
| Timelock | `TLqrqsPcmiUk6HJc6kxY7q56PH1TWCxDhh` | 6,262 | 21 | Delay 172,800 s = 2 days. |
| jUSDD market | `TKFRELGGoRgiayhwJTNNLqCNjFoLBh3Mnf` | 5,665 | 74 | `CErc20Delegator`; holds 425.6M USDD. |
| SunSwap V3 pool | `TD3C3hcmRgTP42Sxv7XsT6fHbeX5eAryq6` | 34,246 | 0 | USDD/USDT fee=100. |
| SunSwap V2 pair | `TDEoc9JmeTbcnKuCqZrQuykb3k6CwvDW6P` | 8,865 | 0 | USDD/USDT; dust ($16 TVL). |
| SunCurve 2pool | `THJCvwFmu6uDqKY59JbULHDgfddy2Zojty` | 18,130 | 55 | USDD/USDT StableSwap, fee 4 bp, A=1000. |
| ESM | `TVKZKa1LDadTPm2AoAW7hp9BtdScK4gSk8` | 3,791 | 0 | min 8.91B USDD. |
| End | `TXhepqfva4WvcK6HapedmzwDjdZv8KoY6p` | 8,319 | 0 | Emergency shutdown. |
| Flap | `TP2eYpkrgk7sLAts5tvzsFxHiDH8PmQcuH` | 2,205 | 0 | Surplus auction. |
| Flop | `TX6CM8K1FgS2nnTEjLsKW6TAVSipFXHh5C` | 6,367 | 0 | Debt auction. |
| DssDeploy | `TNqH7NFMDrHj5FSTGeGkepcEG5Fav9e6F6` | 14,674 | 52 | Deploy script; owner/authority = 0. |
| UsddFab | `THuAY3Dqaf5EMdUPcQtmFew85ZSTEENAYk` | 4,887 | 1 | USDD token factory. |

**Graph:** `DssDeploy` deployed `Vat`, `USDD` (via `UsddFab`), `UsddJoin` (via `UsddJoinFab`), `Vow`, `Spotter`, `Jug`, `Dog`, `Flap`, `Flop`, `End`, `ESM`, `Pause`, and proxy registry. `Pause` → `PauseProxy` is the only remaining active ward set on the core. The PSM was deployed separately by the same deployer EOA and wired to the same Vat/UsddJoin/Vow. The USDD token’s only confirmed mint ward is `UsddJoin`; unknown wards could not be enumerated without `Rely` logs.

### Deployer and admin
- Deployer EOA: `TXHDjs83UhE2MeSfy3TGMobdzR1KEFPySR` (EOA, no code, no token balance). It was **denied** on Vat, Dog, Vow, Jug, Spotter after setup; `DssDeploy.owner()` and `.authority()` are `0`.
- `Pause.authority` = `GovActionsProxy`; `Pause.proxy` = `PauseProxy`; `Pause.delay` = **0**.
- `GovActionsProxy.owner` = `TSF2rqLdrrZG7PZkDxtvu6B2PTpofidMAX` — a **single EOA** (0 code, 119,959,129 TRX ≈ $40M). `GovActionsProxy.authority` = 0. `customExec` from that owner passes auth (inner call can fail); from a random address it reverts `ds-auth-unauthorized`.
- `GovernorBravo.admin` = Timelock (`TLqrqs...`), implementation `0xf05b6ae56bedfecfc5f0325cd265be5086475a12`. Timelock delay = 2 days, admin = GovernorBravo.
- `GovActionsProxy.govActions` = `TDLgCe2SatVew6PxSwYmqsc3zfahqXwuqX`.
- ESM `min` = 8.91B USDD ≈ 6.8× current supply; not a practical brake.

---

## 4. USDD token state and mint authorization

Recorded at block 87,211,072:

- `totalSupply()` = **1,317,294,810.7072296 USDD** (18 dec).
- `decimals()` = 18; `name()` = “Usdd Stablecoin”; `symbol()` = USDD.
- `owner()` reverts (no Ownable).
- Method map (Tronscan): `push`, `pull`, `move`, `rely`, `deny`, `transfer`, `transferFrom`, `approve`, `permit`, `mint`, `burn`.
- `wards(address)`:
  - `UsddJoin` `TUajR7...` = **1**
  - PSM `TBXW4h...` = 0
  - `USDDExchange` `TQrq...` = 0
  - PauseProxy `TE6Rx...` = 0; Pause `TNq6...` = 0; Governor `TB6Q...` = 0
  - DssDeploy `TNqH7...` = 0; UsddFab `THuAY...` = 0; Vat `TH5dh...` = 0
  - deployer `TXHDjs...` = 0
- `mint(address,uint256)` is `0x40c10f19`, auth-gated by `wards[msg.sender]`. Simulated from PauseProxy:
  - `USDD.mint(pauseproxy, 1e18)` → **REVERT `Usdd/not-authorized`**.
- **No blacklist/freeze** selector exists in the token method map. USDD transfers are permissionless (unlike USDT, which has blacklist functions).
- **Ward scan:** we queried `wards` for all **61 contracts created by the deployer** (the full deployer contract graph): only `UsddJoin` returned 1. No old join, PSM, fab, or proxy is a token ward.

**Direct-mint conclusion:** no public `mint`/`issue`; the only token minter among all deployer-created contracts is `UsddJoin`, and `UsddJoin` only mints when it moves internal Vat USDD (i.e., against Vat debt). Unknown wards outside the deployer graph cannot be excluded without full `Rely` event history. The USDD token itself cannot be minted by governance directly; governance mints through `Vat.suck` + `UsddJoin.exit` (see §8).

---

## 5. PSM (UsddPsm)

Address `TBXW4hS5KYjjbJXDpnrPf4zhkLwrpUjbyz`; verified ABI `UsddPsm`.

| Parameter | Value |
|---|---|
| `ilk()` | `PSM-USDT-A` |
| `gemJoin()` | `TSUYvQ5tdd3DijCD1uGunGLpftHuSZ12sQ` (AuthGemJoin5, `gem()` = USDT, `dec()` = 6) |
| `usddJoin()` | `TUajR7CbXU6hX8n3XtNkitFAD25JvP99K6` |
| `vat()` | `TH5dhX7o39afSbfDT2e3c9k4itWjNKD4D9` |
| `vow()` | `TXLfZmQtLtLxWYNL2fxhw34JNGHB2EKeSU` |
| `usdd()` | `TXDk8mbtRbXeYuMNS83CfKPaYYT8XWv9Hz` |
| `tin()` | **0** |
| `tout()` | **0** |
| `sellEnabled()` | **1** |
| `buyEnabled()` | **1** |
| `wards(PauseProxy)` | **1** |
| `wards(GovActionsProxy/Governor/deployer)` | 0 |
| `vat.ilks(PSM-USDT-A)` Art | **41,230,957.497215 USDD** |
| rate / spot | 1.0 / 1.0 |
| line | **600,000,000 USDD** |
| `vat.urns(PSM)` ink / art | 41,230,957.497215 / 41,230,957.497215 |
| USDT in gemJoin | **41,232,487.378037 USDT** |
| USDT directly in PSM | 10.0 |
| USDD in PSM | 0 |
| `vat.gem(PSM)` | 0 (expected: after `frob`, gem is in `urns.ink`, not `gem`; the USDT is in the gemJoin) |

**Capacity**
- Redeem (`buyGem`, USDD→USDT): limited by `ink`/gemJoin USDT = **41,232,487.38 USDT**, i.e. **3.13%** of USDD supply. Larger redemptions revert when gemJoin USDT is exhausted.
- Mint (`sellGem`, USDT→USDD): limited by `line - Art` = **558,769,042.50 USDD**. No inventory limit; the user supplies USDT.
- No per-caller whitelist; `buyGem`/`sellGem` only check `buyEnabled`/`sellEnabled` and balances/allowances.

**Permissionless proof (constant simulation, no broadcast):**
- From ordinary EOA `TCFNp179Lg46D16zKoumd4Poa2WFFdtqYj` (0.001602 USDD, max allowance to PSM), `buyGem(TCFNp, 1600)` at block `87,210,985` → **success**, energy 237,035. `buyGem(..., 1e12)` = 1,000,000 USDT from the same EOA → revert `Usdd/insufficient-balance` (caller balance, not a PSM cap).
- Live PSM events (latest 50, block range ~87,208,900–87,210,118): `BuyGem`/`SellGem` every few blocks, fee = 0, values $1k–$507k. Examples:
  - `BuyGem` block 87,210,118, owner `0xece810…`, value 37,126,767 (37.13 USDT), fee 0.
  - `SellGem` block 87,210,050, owner `0xe4c9de…`, value 100,000,000,000 (100,000 USDT), fee 0.
- A representative BuyGem tx (`6ffe66ed…`) internally calls USDD burn (to the zero address), UsddJoin, Vat, GemJoin and transfers USDT from the gemJoin to the user — the standard PSM path.

**PSM fee/admin:** `file(bytes32,uint256)` is auth-gated by `wards` = PauseProxy only; simulated `file('tout',1e18)` and `file('tin',1e18)` from PauseProxy both succeed. Governance can change fees, but no public caller can. We did not test enable/disable `file` keys.

---

## 6. CDP / Vat state

Recorded at block 87,210,464 (ilks) and 87,211,072 (debt/supply).

- `Vat.debt()` = **1,319,118,172.384186 USDD**.
- `Vat.vice()` = **2,000.657983 USDD** (= `sin(Vow)`; only bad debt).
- `Vat.Line()` = **3,120,000,000 USDD**.
- `Vat.sin(Vow)` = 2,000.657983; `sin(PSM)` = 0; `sin(deployer)` = 0.

| Ilk | Art (USDD) | rate | spot (USD) | line (USDD) | mat | stability fee (annual) | pip | notes |
|---|---:|---:|---:|---:|---:|---:|---|---|
| USDT-A | 542,407.49 | 1.017487 | 0.951171 | 200,000,000 | 1.05 | ~0.0000062% | OSM `TMhsJi...`, src median `TNuBMH3A...`, peek 0.99873 | join `TDUkQbjr...` (GemJoin7), clip `TKvNF7...` |
| TRX-A | 167,918,968.48 | 1.018880 | 0.278063 | 400,000,000 | 1.20 | ~0.00050% | OSM `TVsQx...`, src median `TSB7M6...`, peek 0.333676 | GemJoinTrx `TJ1VWP...`, clip `TK9Ng6...` |
| TRX-B | 93,598,631.99 | 1.023266 | 0.285193 | 300,000,000 | 1.17 | ~0.00050% | same TRX OSM | GemJoinTrx `TGQKnH...`, clip `TWmmZ4...` |
| TRX-C | 187,936,287.51 | 1.014435 | 0.256674 | 400,000,000 | 1.30 | ~0.00050% | same TRX OSM | GemJoinTrx `TPUPPL...`, clip `TMZTbw...` |
| PSM-USDT-A | 41,230,957.50 | 1.0 | 1.0 | 600,000,000 | — | 0 | USDT join | PSM `TBXW4h...` |
| WBTC-A | 0 | 1.013390 | 54,272.68 | 10,000,000 | 1.50 | — | `TRkw65bz...`, peek 81,409.03 | initialized, no debt |
| WBTC-B | 0 | 1.018699 | 62,622.33 | 10,000,000 | 1.30 | — | same WBTC pip | initialized, no debt |
| WBTC-C / others probed | 0 | — | — | — | — | — | — | no debt |

**Stability fees** are effectively zero: USDT-A duty `1.000000000315523`/s → annual factor ~1.0000000622 (~0.0000062%); TRX duty `1.000000000158154`/s → annual ~0.0005%. The system is not fee-driven.

**Liquidation params:** Dog `chop` = 1.13 (13%) for USDT-A/TRX-A/B/C; `hole` = 35,000,000 (USDT) for the TRX ilks; WBTC clips exist with the same Dog. Clippers: `TKvNF7...` (USDT-A), `TK9Ng6...` (TRX-A), `TWmmZ4...` (TRX-B), `TMZTbw...` (TRX-C); PSM clip `T9yEga...`.

**Unresolved accounting gap:** sum of enumerated `Art × rate` = **499,297,497.24**, while `Vat.debt()` = **1,319,118,172.38**. The difference is **819,820,675.14 (62.1%)**. `vice` is only 2,000.66, so the gap is not recorded as bad debt. Enumerated lines sum to 1.92B vs `Line` 3.12B (1.20B global headroom). We probed 40+ candidate ilk names (ETH/BTC/USDC/TUSD/USDJ/SUN/JST/WIN/BTT/NFT/USDD/PSM variants) and only found the seven above. This may be additional ilks initialized outside `DssDeploy`, or a non-standard debt accounting; it is flagged, not claimed as unbacked. See §10.

---

## 7. Oracles

- **USDT:** Spotter pip is OSM `TMhsJiXUrT5eueuH1cq6SdvQEBt4YjKLfx`; `src()` = MedianUSDTUSD `TNuBMH3A628d9UAhgkBFpgqb3gHy2sbnF5`; `peek()` from the Spotter = **0.99873**, `has = true`. This is the protocol’s USDT/USD valuation, and it explains much of the apparent USDD “discount” in USD terms.
- **TRX:** OSM `TVsQxikpttN15u7vcjXKeVrtYRWbrqgPbH`; `src()` = MedianTRXUSD `TSB7M6eBpBD4RUrqdgPrTLkfzzYV39QTBo`; `peek()` = **0.333676**, `has = true`.
- **WBTC:** pip `TRkw65bzGiVqE3vaUH8ndvrNRmLbCgU2wa`; `peek()` = **81,409.027264**, `has = true`. Vat spots are price/mat: WBTC-A 54,272.68, WBTC-B 62,622.33.
- `peek()` calls from a non-whitelisted caller revert `Median/contract-not-whitelisted` / `OSM/contract-not-whitelisted`; reads above were made with the Spotter as `owner_address` (msg.sender), which is whitelisted. No `has=false` was observed.

---

## 8. DEX map and arbitrage probe

### 8.1 Venues

**SunSwap V3, fee 100 (0.01% = 1 bp)** — `TD3C3hcmRgTP42Sxv7XsT6fHbeX5eAryq6`
- token0 = USDT, token1 = USDD.
- `slot0().sqrtPriceX96` = `79228153772302657163861598152485112`; tick = 276,324.
- Price = `(sqrtP/2^96)^2 × 10^(6−18)` = **0.9999997793218742 USDT per USDD**; deviation **−0.0022068 bp**.
- Active liquidity = `6,341,732,851,783,686,609,478`.
- Pool balances: **2,107,674.47 USDT**, **1,302,045.37 USDD**.
- Fee 500 pool `TAuY4ywYvoS4AMJ1hd7uYZDeSN1o1SWyQ1`: `liquidity()` = 0.

**SunSwap V2** — `TDEoc9JmeTbcnKuCqZrQuykb3k6CwvDW6P`
- token0 USDT, token1 USDD.
- Reserves: **7.972970 USDT**, **8.023979 USDD** (raw 6/18 dec) — a **$16 TVL dust pool**, not $8M. Spot 0.993643.
- Best buy-and-redeem profit: **$0.0000228** at a $0.0135 input. Irrelevant.

**SunCurve StableSwap2Pool** — `THJCvwFmu6uDqKY59JbULHDgfddy2Zojty`
- coin0 = USDD (18 dec), coin1 = USDT (6 dec); `fee` = 4,000,000 / 1e10 = **4 bp**; `admin_fee` = 50%; `A` = 1000.
- `balances`: 954,360.398545 USDD; 760,452.318493 USDT.
- `get_dy` quotes (block 87,211,165):
  - 10,000 USDD → **9,993.556784 USDT** (0.99936; −6.4 bp)
  - 100,000 USDD → **99,923.408540 USDT** (0.99923)
  - 1,000,000 USDD → **758,814.596694 USDT** (0.7588; pool USDT depleted)
  - 10,000 USDT → **9,998.192360 USDD** (1.00018 USDT/USDD)
  - 100,000 USDT → **99,971.078805 USDD** (1.000289)
  - 1,000,000 USDT → **947,255.610673 USDD** (1.0557; pool USDD depleted)
- No direction clears the PSM’s 1:1 after the 4 bp pool fee at any size.

**Old USDD/USDT SunCurve** — `TNTfaTpkdd4AQDeqr8SGG7tgdkdjdhbP5c` (USDDOLD-USDT), not the 2.0 token. Old USDD supply 7,136,259.98; the old→new exchange is unfunded (§9). Not part of the E-U.

**CEX / global reference (CoinGecko, 2026-10-18 ~06:54 UTC):**
- USDD/USD 0.998338; USDT/USD 0.999128; USDC/USD 0.999775.
- Tickers: SunSwap V3 new USDD/USDT **1.0000876** ($2.755M/24h); HTX **0.99999** ($28.6k); BingX **0.9978** ($55.2k); Gate **0.9973** ($23.3k); MEXC **0.9988** ($3.4k); Kraken 0.9902 ($35); old USDD SunSwap V3 0.999776 ($66k); old USDD SunSwap V2 0.99407 ($543).
- DefiLlama: 0.9983599 (confidence 0.99). The global discount is mostly **USDT/USD** (protocol oracle 0.99873) plus a few bp of thin CEX quotes; the main on-chain pool is at par.

### 8.2 Round-trip math per $1M

At the recorded V3 price `p = 0.9999997793` and fee `f = 0.0001`:

1. **Buy USDD on V3, redeem via PSM `buyGem`**
   - Input to receive 1,000,000 USDD = `1,000,000 × p / (1−f)` = **1,000,099.79 USDT**.
   - PSM pays 1,000,000 USDT (tout = 0).
   - **P/L = −$99.79** (−1.00 bp), before slippage/energy.
2. **Mint USDD via PSM `sellGem`, sell on V3**
   - Input 1,000,000 USDT → 1,000,000 USDD (tin = 0).
   - V3 output = `1,000,000 × p × (1−f)` = **999,899.88 USDT**.
   - **P/L = −$100.22** (−1.00 bp), before slippage/energy.
3. **Energy:** `buyGem` ≈ 237,035 energy; a V3 swap ≈ 150k–200k. At chain `getEnergyFee = 100 sun` and TRX $0.3332, ~24–44 TRX ≈ **$8–15** per round trip (energy rental is cheaper). Per $1M this is negligible (0.001%), but it makes small trades worse.
4. **SunCurve:** 10k USDD → 9,993.56 USDT = **−$6.44 per $10k** (−6.4 bp); 1M USDD → 758,814.60 USDT = **−24.1%** due to depth. No.
5. **V2:** best possible profit **$0.00002**; no.
6. **CEX route:** buy USDD at 0.9973–0.9978, withdraw to TRON, redeem 1:1 for USDT. Gross 22–27 bp; a 10 bp taker fee + withdrawal + energy leaves ~5–15 bp. At a $25k–$50k clip (CEX daily volume is only $23k–$55k), net ≈ **$25–$45**. Not permissionless and not scalable.

### 8.3 What the PSM does to the price

The PSM is a 0-fee, 1:1 USDT↔USDD converter with 41.23M USDT redeem capacity and 558.77M USDD mint headroom. It is the marginal venue and is actively used: BuyGem/SellGem every few blocks, 24h PSM flow in the millions. The V3 fee 100 pool sits at par to 0.0022 bp; the V3 last trade (CoinGecko 1.0000876) is only +0.88 bp, still **below the 1 bp fee**. This is a well-arbitraged peg, not an “uncharted” mispricing.

---

## 9. Direct-mint, admin, and privileged surface

### 9.1 No public mint
- USDD `mint` is auth by `wards`; only confirmed ward is `UsddJoin` = 1.
- `UsddJoin.exit` is public but only moves internal Vat USDD; it cannot create Vat USDD.
- `USDDExchange.exchange` is public but the contract holds **0.0000151 new USDD**, so old→new migration is unfunded. `EXCHANGE_RATE=1`, `paused=false`, owner `TSF2rqLdrrZG7PZkDxtvu6B2PTpofidMAX` (`0xb28033b4...`) — the **same EOA** that owns `GovActionsProxy`; no new-USDD liquidity.
- jUSDD is a lending market, not a minter. It holds 425,616,498.02 USDD (32.31% of supply).

### 9.2 Privileged mint via `Vat.suck`
- `Vat.wards(PauseProxy) = 1`.
- Simulated at block `87,211,006` from `owner_address = PauseProxy`:
  - `Vat.suck(PauseProxy, PauseProxy, 1e18)` → **success** (energy 53,007).
- Standard Vat `suck` credits internal USDD and increases `debt`/`vice` without a collateral check; `UsddJoin.exit` (public, live=1, ward on token) can then mint the token to any address.
- `PSM.file('tin'/'tout', 1e18)` from PauseProxy → **success** (energy ~22k). Governance can set `tin`/`tout`; we did not test enable/disable `file` keys.
- `USDD.mint` from PauseProxy → revert `Usdd/not-authorized`, so the token itself is not directly mintable by governance; the `suck` + `exit` route is.

### 9.3 Admin chain and centralization
- GovernorBravo (Compound-style) → Timelock (2 days) → GovActionsProxy → Pause (delay 0) → PauseProxy (ward on all core contracts).
- **GovActionsProxy owner is a single EOA** `TSF2rqLdrrZG7PZkDxtvu6B2PTpofidMAX` (0 code, 119,959,129 TRX ≈ $40M). The same EOA owns `USDDExchange`. `customExec` from that EOA passes the proxy’s auth (inner call can fail); a random caller reverts `ds-auth-unauthorized`. If that key is compromised, the owner path could potentially bypass the 2-day Timelock (not proven; the inner call we tried failed). No evidence of compromise.
- The deployer EOA `TXHDjs...` has no remaining privileges (denied on Vat/Dog/Vow/Jug/Spotter; no token wards).
- ESM min 8.91B USDD (6.8× supply) is not a practical emergency brake.

### 9.4 Blacklist / freeze / liveness
- USDD token: no blacklist/freeze selectors; transfers are standard.
- USDT: has blacklist functions (TetherToken ABI), but the PSM gemJoin and its USDT are not blacklisted (balance and `live=1`; BuyGem succeeds).
- `UsddJoin.live=1`; `GemJoin.live=1`; PSM `sellEnabled=1`/`buyEnabled=1`.
- PSM can revert on `buyGem` if gemJoin USDT is exhausted, or `sellGem` if the 600M line is reached; no admin pause flag beyond `sellEnabled`/`buyEnabled` (currently 1).

---

## 10. Blockers, unknowns, and what would change the verdict

**Blockers to a positive E-U at the recorded block**
1. V3 spot 0.99999978 (−0.0022 bp) and 1 bp fee → every round trip loses ~1 bp.
2. SunCurve fee 4 bp and current quotes 0.99936/1.00018 → no edge.
3. V2 is $16 TVL dust.
4. PSM redemption capacity is only 41.23M USDT (3.13% of supply); a >41.23M redemption reverts on gemJoin USDT.
5. CEX discount is 8–27 bp but taker fees ~10 bp and daily volume $23k–$55k; not a $1M venue.
6. PSM mint headroom 558.77M is real, but DEX depth (1.30M USDD / 2.11M USDT on V3) caps sell size.

**Unresolved**
- **819.8M Vat debt gap** vs enumerated ilks. This is 62.1% of `Vat.debt()`, with `vice` only 2,000.66. It could be additional ilks initialized outside `DssDeploy` (we probed 40+ names; none found), or a non-standard accounting. It is a **confidence reducer for S**, not a proven loss.
- **USDT/USD oracle 0.99873 vs market USDT 0.99913/0.9998**: the protocol’s own USDT valuation is 4–10 bp below market. This affects the USD value of the PSM and the “discount” interpretation; it does not create a USDD-specific on-chain arb.
- **Old USDD exchange unfunded**: old USDD (7.14M supply) cannot be migrated at size; a legacy holder may be trapped. Not an E-U for new USDD.
- **GovActionsProxy owner EOA**: centralization risk; P is $1.23B theoretical if that key is compromised, not an external unprivileged path.

**What would change the verdict**
- An on-chain USDD/USDT dislocation >1 bp (V3) or >4 bp (SunCurve) with enough depth: enables the PSM round trip. At 10 bp and current V3 depth, ~$1.17k; at 100 bp, ~$12.9k. A deep venue at 1% discount would be worth up to ~$412k against the PSM’s 41.23M USDT.
- PSM fee change (PauseProxy `file`) to >0 would widen the no-arb band; currently 0.
- A large PSM redemption that exhausts gemJoin USDT would force buyGem to revert and could open a discount (redemption risk), but no such event at the block.
- A CEX maker program/zero-fee withdrawal at 8–17 bp could make the cross-venue route marginally positive, capped by CEX depth.

---

## 11. Evidence and reproduction

All raw calls and decoded outputs are in `raw/`; the helper and computations are in `scripts/`.

Key files:
- `raw/final_snapshot.json` — final block, supply, PSM params, Vat ilks/urns, gemJoin USDT, V3 slot0/liquidity, V3/V2 balances, exchange state.
- `raw/arb_math.json` — computed PSM capacities, V3/V2/SunCurve quotes, per-$1M P/L, conditional table.
- `raw/psm_state.json`, `raw/vat_psm_state2.json`, `raw/vat_sin2.json`, `raw/cdp_ilks_state.json` — PSM/Vat/ilks.
- `raw/psm_sim_buygem2.json` — successful permissionless `buyGem` constant simulation.
- `raw/privileged_sim.json` — `Vat.suck` success, `USDD.mint` revert, `PSM.file` success.
- `raw/govactions_probe.json` — GovActionsProxy owner/auth.
- `raw/sunswap_v3_state.json`, `raw/sunswap_v2_reserves.json`, `raw/suncurve_state.json`, `raw/suncurve_curve.json` — DEX state/quotes.
- `raw/psm_events.json` — live BuyGem/SellGem activity.
- `raw/usdd_exchange_state.json`, `raw/usdd_key_balances.json`, `raw/usdd_wards_extra.json`, `raw/usdd_wards_scan.json`, `raw/usdd_wards_admin.json`, `raw/oracle_state.json`, `raw/usdt_osm.json`, `raw/oracle_peek.json`, `raw/llama_prices.json`, `raw/coingecko_simple.json`, `raw/coingecko_tickers.json`.
- `scripts/tron_call.py` — read helper (no secrets).
- `scripts/compute_arb.py` — offline arb math from raw dumps.
- `scripts/make_summary.py` — builds `summary.json`.

Reproduce (network reads only; no broadcast):
```bash
cd analysis/usdd
python3 scripts/tron_call.py TBXW4hS5KYjjbJXDpnrPf4zhkLwrpUjbyz 'buyGem(address,uint256)' <addr> <gemAmt>
python3 scripts/compute_arb.py
python3 scripts/make_summary.py
```
No API keys, private keys, or keyed RPC URLs are present in any file. No values from `.env` were used; all RPC calls used the public `https://api.trongrid.io` and `https://apilist.tronscanapi.com` endpoints.
