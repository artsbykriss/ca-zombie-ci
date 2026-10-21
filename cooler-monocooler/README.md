# Cooler / MonoCooler (Olympus, Ethereum) — up-only LTV oracle, live-state and extraction assessment

**Date:** 2026-10-21 · **Chain:** Ethereum (block **26,241,769**, 2026-10-21 15:07:47 UTC) · **Status:** read-only; fork PoC only; **no mainnet transaction signed or sent**
**Scope:** ZH4-PASS3 Tier-3 row 13 — "up-only fixed LTV oracle ($3,118/gOHM vs market $5,319); re-arm if gOHM < $3,118".

---

## 1. TL;DR

| Question | Answer |
|---|---|
| Is the "LTV oracle" really a price, and is it really up-only? | **Yes.** `CoolerLtvOracle` returns a fixed 18-dp **USDS per gOHM price**, not a ratio. `setOriginationLtvAt()` reverts `CannotDecreaseLtv()` on any decrease; `setLiquidationLtvPremiumBps()` also only increases; `setLtvOracle()` on the policy rejects a lower OLTV/LLTV. |
| Current value / market | Oracle **3,119.289 USDS/gOHM**; gOHM market **$5,337.30** → oracle = **58.44% of market**, i.e. a **41.56% haircut**. |
| Distance to trigger | gOHM must fall **41.56%** (to $3,119.29; OHM to **$11.586** at index 269.2385) before borrowing at the oracle becomes free money. The trigger is **not static**: OLTV ramps to 3,123.183 on 2026-10-27 and can be raised by governance (+≤500 per call, ≤100/day, 7-day lead). |
| Can an unprivileged attacker extract anything **today**? | **No. $0.** Borrowing 100% of the oracle price costs $5,337.30 of gOHM per $3,119.29 borrowed → **−$2,218.01 per gOHM (−41.6%)** before gas. |
| Are any accounts liquidatable (free-collateral bounty)? | **No.** All **328** borrowing accounts were enumerated from 9,020 `Borrow` events and read with `computeLiquidity()`: **0** above LLTV, **0** even above OLTV. Max LTV on the book = **3,118.44**. |
| Conditional E-U if gOHM < oracle | **$3.61M × (1 − P/3,119.29)**, bounded by treasury sUSDS headroom (**$3,606,287.84**); a fresh attacker's share drops to **~$1.39M** if incumbents use their $2.22M of pre-authorised top-up first. Max ~**$3.61M** only if gOHM → $0. |
| Protocol bad debt (not E-U) | **$0** at ≥$3,066.48; **$23.8M** at $2,500; **$44.9M** at $2,000; **$86.9M** at $1,000; **$129.0M** at $0. Collateral is 42,058.34 gOHM vs 128.97M USDS debt; **56.6% of the debt sits in one account** (`OrigamiHOhmManager`, LTV 3,118.44). |
| Verdict | **CLOSED today (E-U $0, high confidence).** Latent, governance-controlled re-arm: a gOHM crash below the up-only oracle, after which new borrows mint USDS at the stale price and are abandoned; the protocol has **no market-price liquidation path at all**, so the loss is structural, not recoverable. |

**Total live extractable now: $0.00 (E-U), confidence HIGH.** Conditional/latent E-U ceiling **$3.61M** (confidence MEDIUM on the bound, HIGH on the mechanism); protocol-side bad debt up to **$129M** (not attacker-extractable).

---

## 2. The mechanism in exact terms

### 2.1 `CoolerLtvOracle` is a price, not a loan-to-value ratio

`src/policies/cooler/CoolerLtvOracle.sol` (verified, solc 0.8.15, non-proxy `0x9ee9f0c2e91E4f6B195B988a9e6e19efcf91e8dc`):

```solidity
/// - They are both quoted in [debtToken / collateralToken] units
/// - It is a fixed 18dp price
/// - Origination LTV updates on a per second basis according to a policy set rate of change (and is up only or flat)
function currentOriginationLtv() public view returns (uint96) {
    if (_now >= originationLtvData.targetTime) return originationLtvData.targetValue;
    return originationLtvData.slope * (_now - originationLtvData.startTime) + originationLtvData.startingValue;
}
function setOriginationLtvAt(uint96 targetValue, uint40 targetTime) external onlyAdminRole {
    if (targetValue < _currentOriginationLtv) revert CannotDecreaseLtv();   // <-- up-only
    ...
}
```

Live struct at block 26,241,769 (`originationLtvData()`):

| field | value |
|---|---|
| startingValue | 2,989.652447 USDS/gOHM |
| startTime | 1,777,151,351 (2026-04-25 21:09 UTC) |
| targetValue | **3,123.183269** |
| targetTime | 1,793,059,200 (**2026-10-27 00:00 UTC**) |
| slope | 8.3940212e-6 /s = **+0.7252 USDS/gOHM per day** |

`currentLtvs()` = **3,119.289005484298284112 / 3,150.481895539141266953** (premium = 100 bps, `liquidationLtvPremiumBps()`).
Bounds on governance: `maxOriginationLtvDelta` = 500 (per call), `minOriginationLtvTargetTimeDelta` = 604,800 s (7 d), `maxOriginationLtvRateOfChange` = 1.1574e12/s (**100/day**). So the trigger price can be ratcheted up at up to ~700/week, but can never be lowered.

### 2.2 Borrowing and liquidation use only this number

`MonoCooler` (verified, non-proxy `0xdb591Ea2e5Db886dA872654D58f6cc584b68e7cC`), `src/policies/cooler/MonoCooler.sol`:

```solidity
function _maxDebt(uint128 collateral, uint256 maxOriginationLtv) private pure returns (uint128) {
    // debt [USDS] = maxOriginationLtv [USDS/gOHM] * collateral [gOHM]
    return maxOriginationLtv.mulWadDown(collateral).encodeUInt128();
}
function _computeLiquidity(...) {
    status.currentLtv = _calculateCurrentLtv(status.currentDebt, status.collateral);
    status.exceededLiquidationLtv = status.collateral > 0 && status.currentLtv > gStateCache.liquidationLtv;
    ...
}
function _initGlobalStateCache(...) {
    (gStateCache.maxOriginationLtv, gStateCache.liquidationLtv) = ltvOracle.currentLtvs();  // only price source
}
```

**There is no market price anywhere in the contract.** Consequences:

1. Liquidation can be triggered **only by debt growth** (interest accrual, 0.49875%/yr continuously compounded), never by a gOHM price fall. From a max-LTV open (LTV = OLTV) the gap to LLTV is **100 bps**, i.e. **~2.00 years** of accrual.
2. If gOHM trades below the oracle, the protocol **cannot** liquidate the position on market price; the borrower simply stops paying and the treasury eats `debt − collateral × market`.
3. Conversely, while gOHM > oracle, **nobody** can be liquidated, so the "free collateral" path in `batchLiquidate()` (which pays the caller `debt/LLTV − collateral` gOHM and **does not require repaying the debt**) is unreachable.

### 2.3 The borrow path is genuinely permissionless

`borrow()` → `_requireSenderAuthorized(msg.sender, onBehalfOf)` → allowed when `sender == onBehalfOf` **or** an unexpired authorization exists. Self-borrow needs nothing. `addCollateral()` is permissionless on behalf of anyone. `borrowsPaused = false`, `liquidationsPaused = false`. `minDebtRequired` = 1,000 USDS.

Collateral is custodied by the `DLGTE` module `0xD3204Ae00d6599Ba6e182c6D640A79d76CdAad74` whose `depositUndelegatedGohm / withdrawUndelegatedGohm / applyDelegations / rescindDelegations` are all `permissioned` (kernel module permissions) → not reachable by an unprivileged caller. No reentrancy surface: gOHM is a plain ERC-20, and state is written before `treasuryBorrower.borrow()`.

---

## 3. Live-state assessment (block 26,241,769)

| Item | Value / call |
|---|---|
| MonoCooler | `0xdb591Ea2e5Db886dA872654D58f6cc584b68e7cC` — verified `MonoCooler`, **not a proxy**, `isActive() = true` |
| Oracle | `0x9ee9f0c2e91E4f6B195B988a9e6e19efcf91e8dc` — verified `CoolerLtvOracle` |
| gOHM / USDS | `0x0ab87046fBb341D058F17CBC4c1133F25a20a52f` / `0xdC035D45d973E3EC169d2276DDab16f1e407384F` |
| TreasuryBorrower | `0xD58d7406E9CE34c90cf849Fc3eed3764EB3779B0` — verified `CoolerTreasuryBorrower` |
| TRSRY / sUSDS | `0xa8687A15D4BE32CC8F0a8a7B9704a4C3993D9613` / `0xa3931d71877C0E7a3148CB7Eb4463524FEc27fbD` |
| Kernel / executor | `0x2286d7f9639e8158FaD1169e76d1FbC38247f54b` / `0x245cc372C84B3645Bf0Ffe6538620B04a217988B` (Olympus governance) |
| `totalCollateral()` | **42,058.343233953062415086 gOHM** |
| `totalDebt()` | **128,971,024.878805048809040285 USDS** (`globalState()` compounds to 128,973,219.48) |
| `loanToValues()` / `currentLtvs()` | 3,119.289005… / 3,150.481895… |
| `interestRateWad()` | 4.9875415e15 = **0.49875%/yr** |
| `borrowsPaused` / `liquidationsPaused` | **false / false** |
| `minDebtRequired` | 1,000 USDS |
| TRSRY sUSDS balance | **3,238,435.007204759 sUSDS** → **3,606,287.84 USDS** at `convertToAssets` 1.113589689803865 (this is the *entire* borrow headroom: `borrow()` pulls sUSDS from TRSRY) |
| gOHM market | **$5,337.300530** (DefiLlama `coins.llama.fi`, ts 1,792,595,355 = 2026-10-21; 269.238508 index × OHM $19.823689) |
| gOHM supply | 50,046.869 (13.47M OHM-equivalent) |

### Account book (all 328 borrowers)

Enumerated from **9,020 `Borrow(caller,onBehalfOf,recipient,amount)` events** (Etherscan V2 `getLogs`, 10 pages) → 328 unique `onBehalfOf`; each read with `computeLiquidity(address[])` at the pinned block.

| Metric | Value |
|---|---|
| accounts | 328 |
| Σ collateral / Σ debt | 42,058.006 gOHM / 128,973,219 USDS |
| accounts above LLTV (**liquidatable**) | **0** |
| accounts above OLTV | **0** |
| max LTV / min LTV | **3,118.439** / 1,886.476 |
| LTV gap to LLTV for the max account | 100 bps |
| largest account | `0xe6C5dc8508939B1c417f83B7fed3149ef22cF3Ff` = **`OrigamiHOhmManager`** (verified source) — **23,417.01 gOHM / 73,024,516.73 USDS**, LTV **3,118.439** = **55.7% of collateral, 56.6% of debt** |
| next 4 | 3,201.97 / 1,742.81 / 1,074.93 / 1,037.62 gOHM |
| pre-authorised top-up room (Σ OLTV·coll − debt) | **2,217,856 USDS** |
| fresh-attacker residual headroom | 3,606,288 − 2,217,856 = **1,388,432 USDS** |

The book is one leveraged strategy (Origami's gOHM loop) plus a long tail of smaller users. That concentration is why the protocol-side number is large even though the attacker-side number is zero.

---

## 4. What an attacker can and cannot do

### 4.1 Today — the only permissionless path and why it loses money

```
buy gOHM (or buy OHM and Staking.stake 1:1 at index)   cost = P_market per gOHM
MonoCooler.addCollateral(c, self, [])                  (permissionless)
MonoCooler.borrow(type(uint128).max, self, self)       → c × OLTV USDS
walk away (never repay, never withdraw collateral)
```

Net per gOHM = `OLTV − P_market − slippage − gas` = **3,119.289 − 5,337.301 = −2,218.01 USD** today (**−41.56%**).
A flash-loan version is identical in sign: borrow USDS → buy OHM → stake → deposit → borrow → repay flash → keep the residual. The residual is negative, so the loop is never entered.

Other candidate paths, all closed:

| Path | Result |
|---|---|
| `withdrawCollateral` after borrowing | re-checks LTV **after** the state write (`_validateOriginationLtv`), reverts `ExceededMaxOriginationLtv` |
| reentrancy via gOHM | gOHM is a plain ERC-20 (no hooks); CEI respected; `treasuryBorrower.borrow` is the last call |
| `setAuthorizationWithSig` replay | nonce + chain-bound EIP-712 domain + signature deadline; no live authorization grants found |
| borrow on a victim's account | `_requireSenderAuthorized` → `UnauthorizedOnBehalfOf` |
| move collateral out of `DLGTE` | all DLGTE mutators are `permissioned` (kernel module ACL) |
| raise/lower the oracle | `onlyAdminRole`; decreases revert `CannotDecreaseLtv`; `setLtvOracle` rejects any lower OLTV/LLTV |
| force a liquidation | no account is above LLTV; `checkpointDebt()` only accrues time-based interest; there is no market-price input to manipulate |
| DEX manipulation of the oracle | the oracle reads **no** external market — nothing to manipulate |

### 4.2 If gOHM crosses below the oracle (the re-arm)

At market price `P < OLTV`, a fresh unprivileged attacker's profit is `capacity × (1 − P_eff/OLTV)` where `P_eff` is the all-in acquisition cost of gOHM (DEX slippage included) and `capacity` is bounded by the treasury's sUSDS:

| gOHM market `P` | protocol bad debt `max(0, debt − 42,058.34·P)` | attacker ceiling on $3.606M headroom | on $1.388M residual |
|---:|---:|---:|---:|
| 3,119.29 (= trigger) | $0 | $0 | $0 |
| 3,000 | $2.80M | $137.9k | $53.1k |
| 2,500 | $23.8M | **$715.4k** | $275.4k |
| 2,000 | $44.9M | **$1.29M** | $497.1k |
| 1,500 | $65.9M | **$1.87M** | $720.5k |
| 1,000 | $86.9M | **$2.45M** | $943.3k |
| 0 | $129.0M | **$3.61M** | $1.39M |

Notes on the bound:
- **Capacity is the treasury, not the collateral.** `CoolerTreasuryBorrower.borrow()` withdraws sUSDS from TRSRY and redeems to USDS; TRSRY holds **3.238M sUSDS ≈ $3.61M**. Governance can top this up at will, so $3.61M is the *current* ceiling, not a hard protocol cap.
- **Slippage is real.** gOHM's own DEX pools are tiny (largest $23.8k), but gOHM is mintable 1:1 from OHM at the staking index, and OHM has ~$15.5M of DEX liquidity (largest pool OHM/sUSDS $10.15M). Acquiring $3.6M of gOHM-equivalent would cost meaningful impact, so realised profit is below the table near the trigger and converges to it in a deep crash.
- **Existing borrowers act first.** They have **$2.22M** of pre-authorised top-up room and the same information; in a crash they drain the treasury headroom before a new attacker arrives. That is why the "fresh attacker" column is the realistic E-U number and the "$3.61M" is the protocol-wide loss-of-headroom number.
- **No liquidation backstop.** Because `_computeLiquidity` uses the stale oracle, a crashed position is *never* liquidatable; the protocol cannot auction or seize on market price. The loss is realised by abandonment, not by liquidation.

### 4.3 Cost side

Gas for `addCollateral + borrow` on mainnet ≈ 250–300k gas (PoC gas is in the CI log); at 5 gwei ≈ $30–60. Irrelevant versus the sign of the trade.

---

## 5. PoC / fork verification

Project: `poc/` (Foundry, `lib/forge-std` vendored). Fork pinned at **block 26,241,769**.

| Test | What it proves |
|---|---|
| `test_live_oracle_and_book` | OLTV 3,119.289 / LLTV 3,150.482, ramp target 3,123.183 @ 2026-10-27, totalCollateral 42,058.343, totalDebt 128,971,024.88, 0.49875%/yr, both pause flags false, TRSRY 3,238,435 sUSDS → 3,606,287.84 USDS |
| `test_borrow_max_is_unprofitable_at_todays_price` | 10 gOHM deposited → **31,192.890054842982841120 USDS** borrowed (= 100% of oracle), position healthy at LTV 3,119.289, **net −$22,180.19** vs the $53,373.01 market cost |
| `test_all_accounts_healthy` | the 12 largest accounts (including Origami) all `exceededLiquidationLtv = false` and `exceededMaxOriginationLtv = false` |
| `test_conditional_profit_if_gohm_below_oracle` | $0 at the trigger, $715k @ $2,500, $1.29M @ $2,000, $1.87M @ $1,500, $2.45M @ $1,000 on current headroom |
| `test_liquidation_bounty_timeline` | LLTV−OLTV gap 100 bps → **~2.00 years** of 0.49875%/yr accrual before a max-LTV position becomes liquidatable |

CI: GitHub Actions `artsbykriss/ca-zombie-ci`, workflow `poc.yml`, run **[39625968766](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39625968766) (re-run of 39625018533 after vendored-lib RPC redaction)** — **5/5 PASS** (`Suite result: ok. 5 passed; 0 failed`). Key logs: borrowed **31,192 USDS** for 10 gOHM, **NET −22,180 USD**; conditional ceilings **$22.3k @ 3,100 / $716.0k @ 2,500 / $1.294M @ 2,000 / $1.872M @ 1,500 / $2.450M @ 1,000**; `years to liq = 2.005`. Gas: 749,562 for the full `deal→approve→addCollateral→borrow` test (the protocol leg alone is ~250–300k).

Off-chain evidence (saved): `analysis/borrow_logs.json` (9,020 events), `analysis/accounts.json`, `analysis/accounts_liq.json` (per-account collateral/debt/LTV/flags), `analysis/exposure.json`, verified sources in `analysis/src/`.

---

## 6. Verdict and residual risk

- **E-U today: $0.00 — HIGH confidence.** Every gate was read live at one block and every account was checked: no liquidatable position, no free collateral, and the only permissionless value path (borrow at the oracle) is negative by 41.56%.
- **H-O: $0 today** (borrowers cannot extract more than their collateral is worth; they can always repay/withdraw normally).
- **P: governance controls the ramp** (can raise the trigger up to 700/week), the oracle address, interest rate, and pausing. This is the switch that turns the latent risk on — and note it is *one-directional*: governance can make the oracle more generous but **cannot** cut it when gOHM falls.
- **S: n/a.**
- **Conditional E-U: up to $3.61M** if gOHM < OLTV, realistically ~$1.39M for a fresh attacker after incumbents top up, minus DEX slippage. **Protocol bad debt** up to **$129.0M** if gOHM → 0 (not extractable by an attacker; it is a loss to Olympus).
- **The structural flaw that remains:** an up-only oracle with no market-price liquidation path. It is safe while `P_market > OLTV`; the instant that inverts, origination is free money, liquidation is impossible, and the loss is fixed by the ratio `debt/collateral` versus the market. 56.6% of the book is one leveraged account, so the loss is concentrated and the first mover is Origami, not an outsider.

### Re-arm monitor

- **`gOHM` market price < `currentOriginationLtv()`** — today **$5,337.30 vs 3,119.289**; alarm band **$3,400** (≈9% above trigger). Watch OHM: trigger at **OHM ≈ $11.586** (index 269.2385).
- Oracle writes: `OriginationLtvSetAt` / `LiquidationLtvPremiumBpsSet` / `LtvOracleSet` on `0x9ee9…` and `0xdb59…`. The 2026-10-27 ramp end (3,123.183) is the next scheduled step.
- TRSRY sUSDS top-ups (they raise the conditional ceiling).
- Any account crossing LLTV (2-year interest clock from a max-LTV open) — then `batchLiquidate` pays a permissionless gOHM bounty.

**Blockers / caveats:** no archive-node dependency was needed (state is ~5 blocks old); the gOHM market price is a DefiLlama aggregate (confidence 1.0, backed by OHM index × OHM price); DEX slippage for a $3.6M acquisition is estimated, not simulated; the "up to 700/week" oracle ratchet assumes governance uses its bounds.

---

## 7. Methodology, sources, files

- Verified sources via Etherscan V2 (`getsourcecode`, chainid 1) for `MonoCooler`, `CoolerLtvOracle`, `CoolerTreasuryBorrower`, `OlympusGovDelegation` (DLGTE), `gOHM`; decompiled-source cross-check of the policy/kernel ACL (`permissioned` modifier).
- Live reads: `eth_call`/`cast call` at block 26,241,769 for ~40 getters; `computeLiquidity(address[328])` in one call; 9,020 `Borrow` logs via Etherscan V2 `getLogs` (10 pages).
- Prices: `coins.llama.fi/prices/current` (gOHM $5,337.300530, OHM $19.823689, ts 1,792,595,355); sUSDS PPS from `convertToAssets(1e18)` = 1.113589689803865.
- DEX depth: GeckoTerminal public API (`/networks/eth/tokens/…/pools`) — OHM top-15 pools ≈ $15.55M, largest OHM/sUSDS $10.15M; gOHM's own pools are dust, so gOHM is acquired via OHM + `Staking.stake`.
- Fork PoC: Foundry 1.8.5, solc 0.8.24, `vm.createSelectFork(FORK_RPC_URL, 26_241_769)`, GitHub Actions.
- Files: `README.md` (this), `summary.json`, `analysis/src/*` (verified sources), `analysis/borrow_logs.json`, `analysis/accounts.json`, `analysis/accounts_liq.json`, `analysis/exposure.json`, `poc/test/Cooler.t.sol`, `poc/foundry.toml`, `ci-log.txt`, `ci-artifacts/`.

*Prepared 2026-10-21 · ZH4-PASS3 · read-only research; nothing here is an instruction to transact.*
