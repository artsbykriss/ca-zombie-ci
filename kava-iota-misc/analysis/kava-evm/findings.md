# L2-25 "zombie-hunt II" — Kava EVM (chain 2222): Tarot · Blueshift · Steer

**Verdict up front: `$0` external-unprivileged (E-U) extraction on all three targets, with proof.**
One genuinely broken pricing design exists on Tarot (latent ~**$2.83k**) but its only
collateral-supply route is gated by dead Voter gauges; Blueshift's TVL is stale accounting with
zero custody; Steer's live ~$1.48k is share-owned and its fee/emergency functions are role-gated
with roles frozen.

All work is read-only (`eth_call` / `eth_getStorageAt` / `eth_getLogs` + a local Foundry fork).
Kava prunes state within ~500 blocks, so every read uses `latest` with the block recorded.
RPC: `https://evm.kava.io` (fallback `https://kava-evm.publicnode.com`).
Snapshot blocks: Tarot `23035381`–`23036218`, Steer `23035781`, prices 2026-10-15.

Classification: **E-U** extractable by external unprivileged actor (live) · **H-O** only with
key/role · **P** precondition-dependent · **S** blocked/safe. Confidence in brackets.

---

## 1. Tarot (Avignon + Orleans factories) — E-U $0 · latent $2,828 blocked [high]

### Contracts, code, roles (all verified on-chain)

| item | address | notes |
|---|---|---|
| Factory "Avignon" | `0x82B3413D575Aa93806308A04b53c78ae2037dA11` | code 5507 B, Sourcify **exact_match** (solc 0.5.16), 9 lending pools |
| Factory "Orleans" | `0x54950cae3d8513EA041066F31697903de5909F57` | code 5506 B, same code, 2 lending pools |
| Price oracle | `0x36Df0A76a124d8b2205fA11766eC2eFF8Ce38A35` | verified `TarotSolidlyPriceOracleV2` (TWAP via pair `currentCumulativePrices`, `MIN_T=900`) |
| admin / reservesAdmin / reservesManager | `0x1bb4e4Fc…ea10` / `0x1E6bF02f…F969` / `0xD204E3dC…4D1E` | same on both factories |
| markets | 11 (9+2), all `initialized=true` | each = Collateral + Borrowable0 + Borrowable1 over a **Tarot VaultToken (vTAROT)**, itself wrapping a Vara "vAMM" LP staked in a Voter gauge |

Collateral keys: the factory's "pair" is the vTAROT ("Tarot Vault Token", symbol `vTAROT`);
`vTAROT.underlying = vAMM LP`; `vTAROT.gauge = Voter masterChef`; `vTAROT.getReserves()`
proxies `totalBalance × pairReserve / pairLPTotal` (the vault's slice). The lending collateral
accepts **vTAROT** and prices it with `totalSupply` + slice reserves.

Guard probes from `0x…dEaD` (all revert, so no unprivileged admin path):
`factory._setPendingAdmin` → `Tarot: UNAUTHORIZED`; `collateral._setSafetyMarginSqrt /
_setLiquidationIncentive / _setLiquidationFee` → `UNAUTHORIZED`; `borrowable._setReserveFactor /
_setBorrowTracker / _setKinkUtilizationRate` → `UNAUTHORIZED`; `borrowable.liquidate` on a healthy
account → `Tarot: INSUFFICIENT_SHORTFALL`. `mint/redeem/skim/borrow` are permissionless by design.

### Custody (block 23035485, realised prices)

| item | USD |
|---|---|
| vTAROT slices held by the 11 collateral contracts | **$6,352.04** |
| cash in the 22 borrowables (USDC $10.9k, DAI $1.89k, TAROT $1.99k, ETH $1.31k, WKAVA $290, LQDR $185, WBTC $125, VARA/MARE/MAI dust) | **$16,683.88** |
| outstanding borrows | $666.16 |
| **total book** | **$23,035.92** |

(DefiLlama's $3.76k TVL is a large undercount; its VARA leg is priced ~250× too high but on the
wrong token — see price notes below.)

### The defect (latent): oracle prices a dead, value-imbalanced pool as a balanced LP

`Collateral.getPrices()` returns `price_i = totalSupply·1e18/(2·reserve_i) · adj`, i.e. it books
each side of the pair at *2× its reserve*. Borrow power per unit of collateral is therefore

```
R_i = borrow capacity / collateral fair value = 2·value_i / (smxli · pool value),
     smxli = safetyMarginSqrt·liquidationIncentive = 1.4142·1.02 = 1.4426
```

`R_i > 1` exactly when one side is >69.3% of the pool's realised value. The dead Vara pools are
heavily one-sided, so R reaches 1.36–1.38 for 7 of 11 markets. Latent extract (take − deposit):

| vTAROT market (collateral) | profitable borrowable | R | lender cash | extract |
|---|---|---:|---:|---:|
| `0x109f3289665A8f034e2CACdBcfb678Cabe09f1d5` | USDC (`0x014bEF3b…DA865`) | 1.361 | $5,817.65 | **$1,544.27** |
| `0x2b973265fBd59Ef0e14203ec229169d4A6ec31e3` | USDC (`0x7b1A32bD…D52e1`) | 1.361 | $2,564.70 | $680.84 |
| `0x49381f3442631e81f3f4d8228d7309778ab02e42` | USDC | 1.361 | $1,590.39 | $421.84 |
| `0xd0605d69C75dc0FBe229feF91B3D2fDC565B91c4` | ETH | 1.378 | $487.23 | $133.76 |
| `0x3f4410faa08C5daDBBB0984A3ECc12A7b6A45B1B` | WBTC | 1.382 | $121.67 | $33.66 |
| `0xbc50b9f7f8a4ac5cfbb02d214239033dd5a35527` | USDC | 1.361 | $36.60 | $9.71 |
| `0x738114fc34D7b0D33f13d2b5C3d44484ec85c7F1` | USDC | 1.361 | $15.91 | $4.22 |
| **total** | | | **$10,634.15** | **$2,828.30** |

Values are oracle-consistent: the table uses each market's on-chain `getPrices()` (including its
TWAP adjustment), the vTAROT exchange rate and realised token prices. Example (verified in the
PoC): market `0x109f` — deposit ≈ $4,273 of WKAVA/USDC, borrow $5,818 USDC, walk away net ≈ $1,544.

### Why it is **not** live (E-U = $0): the collateral-supply gate is dead

To borrow you must first supply vTAROT. `VaultToken.mint()` forwards LP into the Voter masterChef,
whose `deposit` calls `voter.emitDeposit(...)`, which requires `isAlive[gauge]`. On-chain:

* `IVoter(0x4eB2B976…36a59).isAlive(gauge)` = **false for 10 of 11 markets** (all 7 profitable ones);
* the full attack call-path on `0x109f` **reverts inside `emitDeposit`** (fork trace at
  block 23036218, and the PoC asserts the revert);
* all vTAROT supply sits inside the collaterals (float = 1000 wei `MINIMUM_LIQUIDITY` per market),
  so there is no secondary source of vTAROT either;
* the single live gauge (market `0x0de0FD78…C69DC`, gauge `0xCa0d15B4…42c92`) is **not exploitable**:
  with the Kava VARA market price its pool is ~50/50 in value, `R = 0.6935` (WKAVA side) /
  `0.6929` (VARA side), and the live-gauge mint path works on the fork (2.088e21 vTAROT minted) —
  proving the gate, not the economics, is what stops the other markets.

### Per-path classification

| path | class | evidence |
|---|---|---|
| fresh deposit (vTAROT mint) + over-borrow + walk away | **S** (blocked) / conditional **E-U $2.83k** if a gauge is revived | `isAlive=false`, `emitDeposit` revert, PoC asserts |
| over-borrow by an existing vTAROT/cTAROT holder | **P** (insider) | supply is 100% inside collaterals; each holder can draw ~0.36× fair collateral from the borrowable |
| liquidate under-collateralised positions | **P** (not established; ≤2% incentive of the measured $666 outstanding borrows, so ≤ ~$13; collateral-overpricing makes full liquidations unattractive) | `liquidationIncentive=1.02e18`, `INSUFFICIENT_SHORTFALL` probes |
| admin paths (safety margin, reserves, factory admin) | **H-O** | `Tarot: UNAUTHORIZED` probes |
| world-facing debt-free mints / skim / flashRedeem arbitrage | **none found** | share math is exact 1:1 at current exchange rates; `skim` sends only surplus; `flashRedeem` requires burning ≥ the pro-rata cTAROT |

Incident history: nothing for the Kava deployment in DefiLlama's hacks DB or web search.

> Price note (matters for the table): Kava's `VARA` (`0xE1da44C0…7d73`) trades ≈ **$2.04e-6** on
> GeckoTerminal (VARA/WKAVA, the exact pair used by market `0x0de0…`), not the $5.1e-4
> CoinGecko price of the unrelated L1 token; `TAROT` ≈ $0.00450, `LQDR` ≈ $0.1488,
> `MARE` ≈ $2.83e-5 (all GeckoTerminal Kava pools). Using the wrong VARA price flips market
> `0x0de0…`'s R from 0.53 to 1.38 — the corrected value is used everywhere here.

---

## 2. Blueshift (Kava) — E-U **$0** [high]

| item | address | notes |
|---|---|---|
| Registry (proxy) | `0x49399653f651A25924b3D8718276b5b4372577b1` | ERC-1967 proxy; impl `0x788dcedf567B8024c8895f59FDB60a9568D93a21`, admin `0x352a1dB3F52dfc4F2C52dF33e118AE138Bc72a90`; owner EOA `0x44e3163c55a2e2b4488a284b84ce0288838e1719` |
| "Multichain Stablecoin Index" portfolio | `0xA8893E7d58D079A8fB7d999a19fe46682adA52FE` (LP `0x217F7785…4DD9A`) | registry claims `totalValue = 193,007,099,364` base units ≈ **$193k USDT** |
| "Kava Index" portfolio | `0x67C85757DEa3Bc6358C1352d1185E05CE8CB0406` (LP `0x7582eAac…48F3`) | registry claims `1,120.47 WKAVA ≈ $76.9` (this is DefiLlama's Kava TVL) |
| manual pool (staking) | `0x7A60918Bd5c83Ef7e2ABA87D13e3FD704f6A77E1` | holds 6,244.82 BLUES (no market price anywhere → $0) |

Raw reads (`getPortfolios()` decoded): portfolios list tokens `[USDT, USDC, DAI]` and
`[WKAVA, USDT, BLUES]` with amounts, but **every portfolio contract and both LP vaults hold
exactly zero** of USDT, USDC, DAI, WKAVA and BLUES (verified at the latest block; also zero for
the registry/impl/admin/owner addresses). The only Kava value held anywhere in the system is
6,244.82 BLUES in the manual pool plus 1,140 BLUES at the owner EOA — both unpriced.
**Conclusion: the $76.90 DefiLlama number and the $193k registry number are stale accounting;
real extractable value $0.** No permissionless function can pay a caller because no assets are
custodied. (Blueshift's BOB deployment carries the real TVL; Kava is abandoned.)

Incident history: none found.

---

## 3. Steer Protocol (Kava) — E-U **$0** [high]

| item | address | notes |
|---|---|---|
| Periphery (proxy) | `0xf90107890B640387ec3b0474F0c61674AEbCb510` | impl `0x245194ed39516431fF511A74c7b6df4cb4B5f1F3` (Sourcify match), admin `0xab36D30C…C6576`, owner `0x088F8F36ad78d81C092Ec8Dc172C6c0fA09D1594` |
| Strategy registry | `0xdca3251eBe8f85458E8d95813bCb816460e4bef1` | ERC-721, 15 strategy NFTs |
| Vault registry | `0xe240b9A2936f6Fb8860219bc059349e50f03492e` | `totalVaultCount() = 68`; every vault state = **PendingApproval(1)** |
| Vault beacon / impl | `0x25ddb84e4Ea4D32DF8Ecb2405757B1887E230D38` / `0x8032D063992f4f6A14bC2be69a0D24CB563365de` | MultiPositionKinetix (Uniswap-V3 LP manager over Kinetix) |
| roles on vaults | `STEER_ROLE` → `0x088F8F36…`; `MANAGER_ROLE` → `0xDe6024872d45032B9C62c2E015d2bcff2922B337` | `DEFAULT_ADMIN_ROLE` member count = 0 → **roles frozen** |

Live value (all 68 vaults enumerated from the registry; 29 with assets; `getTotalAmounts()` +
realised prices at block 23035781): **$1,475.55** total, largest vaults
`0x6C21797D…2422` ($467), `0xB6427fB9…8e0` ($400), `0x06a93C03…cFB` ($225).

Permissionless surface (probed from `0x…dEaD` and executed on the fork):
* `poke()` — **permissionless** and succeeds, but the fee it collects on the probe vault is
  **$0.0095 + $0.0090** (9,527 / 8,977 base units) — the deposit→poke→withdraw fee-capture
  attack is worth pennies at most, and the associated share math is the standard
  "totalAssets excludes uncollected fees" pattern, not a mispricing;
* `steerCollectFees(uint256,uint256,address)` and `emergencyBurn(int24,int24,uint128)` —
  **revert** for an unprivileged caller (role-gated); with `DEFAULT_ADMIN_ROLE` empty nobody can
  ever grant the roles, so these stay closed;
* `deposit/withdraw` are share-based and require the caller's own tokens (the vault pulls claims
  against the caller); `withdraw` beyond one's shares reverts `ERC20: burn amount exceeds balance`.

**Conclusion: no unprivileged payer on Steer Kava; the $1,475 is intact claimable value of vault
shareholders, not extractable by a stranger.** (Steer's DefiLlama Kava TVL of `$0` is a dead
subgraph, but a fresh attacker still gets `$0`.)

Incident history: none found.

---

## PoC / CI

File: `poc/test/KavaEvm.t.sol` (`KavaEvmTarotBlueshiftSteerTest`, forge 1.8.5/solc 0.8.24,
`forge test --match-path test/KavaEvm.t.sol`). Status: **4/4 passing** at fork block ~23036218.

| test | what it proves |
|---|---|
| `test_Tarot_LatentOverBorrow_BlockedByDeadGauge` | R = **1.3613e18**, latent **$1544.07**; `Voter.isAlive(gauge)=false`; `vTAROT.mint()` reverts (gate asserted) |
| `test_Tarot_LiveGaugeMarket_MintableButNotProfitable` | live gauge: mint **works** (2.088e21 vTAROT); `R = 0.6935 / 0.6929 < 1` → no profit |
| `test_Steer_PokeIsDust_CollectGated` | poke allowed, Δ = 9,527/8,977 units; `steerCollectFees`/`emergencyBurn` revert |
| `test_Blueshift_StaleTVL_ZeroCustody` | all 4 Blueshift contracts hold 0 of 5 tokens |

The fork defaults to `latest` because Kava prunes historic state; set `KAVA_BLOCK` (archive RPC)
or `KAVA_RPC` to pin. If a gauge is ever revived, the first test fails loudly (assertFalse on
mint success), which is the signal to re-run the full over-borrow attack — the sizing helpers for
that attack are described in the test comments and in `state.json`.

## Blockers / residual uncertainty

* **Tarot**: the latent path hinges on `Voter.isAlive` being set by governance (not permissionless).
  If RPC state for `isAlive` were wrong the fork mint-revert independently confirms the gate.
  Liquidation opportunities (≤ ~$13 at 2%) were not enumerated borrower-by-borrower (Borrow logs
  require 10k-block windows over ~23M blocks); the overpriced oracle makes liquidations
  unprofitable anyway, so this cannot exceed dust.
* **Steer**: vault withdrawal/poke math was probed on one vault; the 29 vaults share one
  implementation, and all value is share-owned, so systematic errors there would be
  shareholder-vs-shareholder dilution, not stranger extraction. Fee dust measured on the probe
  vault.
* **Prices**: TAROT/LQDR/MARE/VARA Kava prices come from thin pools (they are the only markets);
  two markets (`0x738114…`, `0xbc50…`) contribute <$15 to the latent total so their price error
  cannot change the headline.
