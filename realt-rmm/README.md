# ZH4-07 — RealT RMM v3 + RealTokenWrapper (Gnosis): E-U closed at **$0**, conditional whitelist/IBP case

**Date:** 2026-10-18 (UTC) · **Chain:** Gnosis (100) · **Status:** read-only; PoC fork-verified only; no mainnet transactions
**Targets:** RMM v3 pool [`0xFb9b496519fCa8473fba1af0850B6B8F476BFdB3`](https://gnosis.blockscout.com/address/0xFb9b496519fCa8473fba1af0850B6B8F476BFdB3) · RealTokenWrapper [`0x10497611Ee6524D75FC45E3739F472F83e282AD5`](https://gnosis.blockscout.com/address/0x10497611Ee6524D75FC45E3739F472F83e282AD5)
**Evidence blocks:** 48,811,425 (census) · 48,811,720 (fork pin/gate probe) · 48,811,498–48,812,046 (book/gate/state)

---

## 1. TL;DR

| Question | Answer |
|---|---|
| **Live extractable by an external unprivileged attacker (E-U)** | **$0.00** — high confidence |
| Is the mechanic real? | **Yes.** `RealTokenWrapper.liquidationCall` is permissionless, the caller picks the collateral mix, the RTW reserve pays a **10% liquidation bonus** and the **liquidation protocol fee is 0**. Fork-proven: 50 WXDAI → 1.0803 RealToken ($55.00 at the frozen mark) from a whitelisted caller. |
| Why is it $0 for an outsider? | **Every RealToken transfer is compliance-gated (RU03).** All **623/623** basket tokens deny a fresh EOA (Processor rule id 11); 620/623 allow the incumbent Safe. `receiveMethod=1` therefore reverts before the attacker receives anything. `receiveMethod=0` executes but yields a **non-transferable aRTW claim** whose only redemption is also RU03-gated. |
| Is there an exit market anyway? | **No.** Exhaustive re-check of **all 250,283 Yam offers** (book unchanged: 0 created / 0 deleted / 0 accepted since the v4b enumeration): 6 live cash bids, best **0.2446×** mark with **1 wei** available; **zero live cash bids ≥ 0.4×**, let alone the **0.909×** break-even. 30-day fills: median **0.137×**, p90 **0.222×**, max **0.748×** in real cash; the 99 fills that look like parity are **all paid in impaired pool aTokens**. |
| Notional prize (unreachable) | **$418,691** one-shot liquidation bonus across **204** underwater borrowers ($5.50M debt, $7.46M collateral at frozen marks). |
| Conditional (not E-U) | A **RealT-whitelisted/KYC'd** user, **if** the currently-paused off-chain **Issuer Buyback Program (IBP)** reopens and approves the orders: **+$7,102 to +$39,651** on **$591,810** deployed (**+1.2% to +6.7%**), medium confidence. |
| Incumbent insider | Safe `0x4F7765c9…` (2 owners, threshold 1; one owner is the Yam “parity” seller) ran **722 of 783** liquidations in the last 30 days (**$130,607** repaid → **$143,598** seized at marks), all `receiveMethod=1`, last on 2026-10-14. Its exit is intra-cluster/off-chain. |
| Recommendation | **Keep the finding as a correction/case study; remove it from the live HIGH/E-U ranking.** Monitor IBP, whitelist/rule-engine changes, oracle updates and any new ≥0.9× Yam bid. |

**Total live extractable now: $0.00 (E-U, high confidence).**

---

## 2. Mechanism, in exact terms

### 2.1 The wrapper is a permissionless liquidation front-end

`RealTokenWrapper` (UUPS proxy `0x1049…2AD5`, impl `0x48a8411781B41b2232c6224EAd7a1700B32E1880`, verified) wraps 623 RealTokens into a claim token `RTW-USD-01`. Users `supply()` RealTokens and receive RTW (and aRTW through the pool); `withdraw()` burns RTW and returns RealTokens.

`liquidationCall(address[] collateralAssets, uint256[] collateralAmounts, address debtAsset, address user, uint256 debtToCover, uint8 receiveMethod)` has **no access control**. It:
1. pulls `debtToCover` of the debt asset from the caller;
2. calls `POOL.liquidationCall(RTW, debtAsset, user, debtToCover, receiveAToken)` **as the wrapper** (the only address the aRTW/pool will accept);
3. lets the caller choose which RealTokens to seize (array is validated, last item truncated to fit exactly);
4. `receiveMethod=1` → `realToken.safeTransfer(msg.sender, amount)` at line ~323 of the impl; `receiveMethod=0` → aRTW transfer to the caller plus a wrapper-ledger credit; `receiveMethod=2` (DEX) is not activated (`LiquidationWithDexActivated` never emitted).

RTW reserve configuration (block 48,811,977): LTV 60%, LT 70%, **liquidation bonus 11,000 bps**, **liquidation protocol fee 0**, borrowing disabled. Debt assets WXDAI/USDC pay 10,500 bps with 0 protocol fee. A caller therefore grosses **10% of the repaid amount at wrapper marks**, before exit.

Live state (block 48,811,977):

| Item | Value |
|---|---|
| aRTW total supply | **29,222,995.91** |
| RTW held by aRTW | **29,287,838.33** |
| RTW held by wrapper | 212,602.10 |
| Oracle `getAssetPrice(RTW)` | **1.00000000** |
| Wrapper basket | **623 tokens, $29,287,838.33 at marks** |
| WXDAI reserve | aToken supply 5,907,899.52 vs variable debt 5,909,093.43 → **negative available liquidity** |
| USDC reserve | aToken supply 8,819,947.05 vs variable debt 8,821,301.27 → **negative available liquidity** |
| Borrowing | **disabled** on all reserves (config bit 58 = 0) |
| Marks | last `RealTokenPriceUpdated` at block **43,908,528 = 2025-12-30T11:53:45Z**; all 623 prices > 0 (min $46.65) |

### 2.2 The decisive blocker: RealToken recipient whitelist (`RU03`)

RealTokens are `IBridgeERC20` tokens whose transfers route through a **Processor** proxy [`0x3221a28eD2b2e955DA64d1d299956f277562C95c`](https://gnosis.blockscout.com/address/0x3221a28eD2b2e955DA64d1d299956f277562C95c) (impl `0xf5c1C5E5215B9bF2bc389F956a5b8D41605586c8`, admin `0x0be1241468df7e9d3b74a84869ddf05c36fd7e50`) and a **rule engine** `0x8F2f90aC35EDf2dA147DD745f5f6c64Bc54F2299`.

`Processor.transferFrom` runs every rule and does `require(ruleValid[i] > TRANSFER_INVALID, "RU03")`. The whitelist is **recipient-side**.

**Exhaustive census — all 623 tokens, live at block 48,812,046** (`analysis/gate_all.json`):

| Destination | Allowed | Denied | Rule |
|---|---|---|---|
| fresh EOA `0x1111…1111` | **0 / 623** | **623 / 623** | id 11, reason 1 |
| fresh EOA `0x…bEEF` | **0 / 623** | **623 / 623** | id 11, reason 1 |
| incumbent Safe `0x4F77…3151` | 620 / 623 | 3 (token-specific) | id 11 |
| victim `0x529f…1ed0` | 618 / 623 | 5 (token-specific) | id 11 |

Direct `RealToken.transfer(fresh, 1e18)` executed **from the wrapper itself** (the holder, the exact call `liquidationCall`/`withdraw` makes): **24/24 fresh-EOA probes revert RU03**, while **40/40 probes to the Safe / a victim / buyer `0xDc06…` succeed** (`analysis/live_state.json`, `analysis/gate_probe.json`).

**Public infrastructure is not whitelisted either** (`analysis/public_contracts_probe.json`): Yam, Gnosis OmniBridge, the Gnosis bridge, the RMM pool, aRTW, Multicall3, the Safe singleton, CoW settlement, Honeyswap/Sushi routers and USDC are **all denied** (rule 11) for the top-3 tokens; only the wrapper itself is allowed. There is no public-contract mule to route seized tokens through.

End-to-end wallet proof (`analysis/gate_probe.json`): the incumbent Safe calls `withdraw(token, amount, to)` for the same token/amount:
- `to = Safe` → **OK**
- `to = fresh EOA` → **revert RU03**

`receiveMethod=0` alternative: fork-verified to execute (claim ≈55 aRTW). But `aRTW.transfer` reverts with `CallerNotPoolOrWrapper(address)` (`0xa3a2cfb6`) — only the pool/wrapper may move it — and its redemption is the same RU03-gated `withdraw`. The claim is a dead end for an outsider.

### 2.3 The second blocker: there is no cash exit at the break-even

Break-even for a liquidator is **1/1.1 = 0.909× mark**. We re-ran the full book and fills:

- **Book:** `getOfferCount() = 250,283` — identical to the v4b exhaustive enumeration. Since block 48,794,906: **0 OfferCreated, 0 OfferDeleted, 0 OfferAccepted, 1 OfferUpdated** (not RealToken-side). The book is unchanged.
- **Exhaustive liveness:** of 2,671 bids in all 250,283 offers, 1,374 met the liveness-candidate filter and were re-checked with `showOffer` at block 48,811,528: **270 live, 6 live cash bids**.
  - Best live cash bid: offer 242569, **0.2446×** mark, **1 wei available** (amount listed 8.399999 USDC but unfunded).
  - The other 5 live cash bids: **0.059–0.193×**, ~$290 aggregate.
  - **0 live cash bids ≥ 0.4×. 0 live cash bids ≥ 0.909× at any size.**
  - The only bids that *look* ≥0.909× nominally are denominated in **aWXDAI/aUSDC** and are dust: e.g. offer 128540 at “1.05×” has **9.08e-6 aWXDAI** available (≈$0.000002). Pool aTokens cannot be redeemed (100% utilisation), so they are not cash.
- **30-day fills (891 RealToken fills, 1,429 `OfferAccepted` logs):** real-cash ratio **median 0.137×, p75 0.168×, p90 0.222×, max 0.748×**; **zero cash fills ≥ 0.909×**. The **99** fills at ≥0.909× *face value* were **all paid in aWXDAI (53) or aUSDC (46)** — i.e. impaired claims, not dollars. Last observable aWXDAI market print is $0.188–0.195 (v4b); at that value the “parity” fills are ~0.19×.

A blind seize-and-dump therefore loses **−60% to −85%** per dollar deployed *even if* the RU03 gate did not exist. The gate makes the loss exactly **$0** (call reverts) or **−100%** (method 0 dead claim).

---

## 3. Live-state assessment (all reads at the blocks shown)

| Role | Address | Checks |
|---|---|---|
| Pool proxy → `PoolV2` `0xD9Cf63C4…` (Aave v3 lineage) | `0xFb9b496519fCa8473fba1af0850B6B8F476BFdB3` | reserves: WXDAI, USDC, RTW, REUSD; no reserve frozen/paused; borrowing disabled |
| Wrapper proxy → `RealTokenWrapper` `0x48a84117…` (UUPS) | `0x10497611Ee6524D75FC45E3739F472F83e282AD5` | 623-token basket, $29,287,838.33 at marks; roles DEFAULT_ADMIN/UPDATER/GOVERNANCE/UPGRADER on one EOA `0x5Fc96c182Bb7E0413c08e8e03e9d7EFc6cf0B099` |
| aRTW → `ATokenRTW` `0xD4C0A21b…` | `0xF3220Cd8F66AEB86fC2A82502977EAb4BFd2f647` | supply 29,222,995.91; `transfer`/`transferFrom` only pool/wrapper |
| RTW → `RTW` `0x690Aa27E…` | `0xd3DFf217818b4F33eB38a243158FBeD2BBB029D3` | transfer/mint/burn wrapper-gated; holds 29.29M inside aRTW |
| Oracle | `0xb4AE809Ad7CEB7e5B579dEdD0De7c213aD5AB516` | `getAssetPrice(RTW) = 1e8`; wrapper prices frozen 2025-12-30 |
| Processor / rule engine | `0x3221a28e…` / `0x8F2f90aC…` | `canTransfer` recipient gate, rule 11 → `RU03` |
| Incumbent Safe (SafeL2) | `0x4F7765c9feBc51cD63F68f573920c0B7bF803151` | owners `0xCa543f90…`, `0x134d928B…`; **threshold 1**; nonce 1990 |
| Exit wallet (Safe owner, Yam parity seller) | `0x134d928B26DB2Da678F16974580B22E799293E6c` | $100,228 marks in 343 RealToken positions |
| Owner 1 (Yam churner) | `0xCa543f90a221dac783490BfeE4a1173AE07547c2` | $167,512 marks in 35 positions |
| Safe holdings | — | $18,618 marks in 288 positions |
| Cluster total | — | **$286,358 at marks** (never dumped at parity to outsiders) |

**Liquidatable population** (Blockscout holders of the three variable-debt tokens → 1,464 unique addresses → Multicall `getUserAccountData`, block 48,811,425):

| Metric | Value |
|---|---|
| Borrowers with debt | 1,443 (of 1,464 holders) |
| **HF < 1.0** | **204** |
| Liquidatable debt | **$5,504,423.92** |
| Collateral at wrapper marks | **$7,458,840.35** |
| **One-shot liquidation-bonus pool** (close-factor aware) | **$418,691.34** |
| Top-20 share | **$319,898.74** (76%) |
| Total protocol debt | $14,732,165.53 |

Top 5 (full list in `analysis/census.json`):

| Borrower | Collateral | Debt | HF | Max bonus |
|---|---|---|---|---|
| `0x309ccbc9…` | $1,295,885 | $992,170 | 0.9143 | $99,217 |
| `0x4b4759c5…` | $504,051 | $375,772 | 0.9390 | $37,577 |
| `0x529f2882…` | $341,418 | $251,777 | 0.9492 | $25,178 |
| `0x7a3c35f9…` | $599,981 | $439,306 | 0.9560 | $21,965 |
| `0x7ca24d44…` | $232,182 | $173,281 | 0.9379 | $17,328 |

**Recent liquidation flow** (wrapper `LiquidationCall`, last 30 days, block 48,811,846):

| Liquidator | Events | Debt repaid | Seized at marks | Method | Last block |
|---|---|---|---|---|---|
| incumbent Safe `0x4F77…` | **722** | **$130,607** | **$143,598** | 1 (RealToken) | 48,749,836 (2026-10-14) |
| `0x46bce371…` | 51 | $2,110 | $2,321 | 1 | 48,552,436 |
| `0x52c1d6eb…` | 10 | $2.11 | $2.32 | 0 (aToken) | 48,410,442 |
| **Total** | **783** | **$132,720** | **$145,921** | | |

The incumbent is the only meaningful liquidator, it cherry-picks the 118 IBP-eligible properties, and it has not sold at parity to anyone outside its own cluster (its “parity” counterparties are its owner’s exit wallet and two repeat buyers).

---

## 4. What an attacker can and cannot do (exact call paths)

**Path A — `receiveMethod=1` (the v4 headline).**
1. Fund `debtToCover` WXDAI/USDC, `approve(wrapper)`.
2. `wrapper.liquidationCall([token], [ledgerAmount], WXDAI, borrower, 50e18, 1)`.
3. **Result: revert `RU03`** at `realToken.safeTransfer(msg.sender, amount)`. Whole tx reverts; capital untouched; **net $0**. Gas 1,353,292 (≈0.0014 XDAI).
   - Fork proof: attacker `0x1111…` -> `test_2_method1_anon_reverts_RU03` **PASS**.
   - Identical call from the whitelisted Safe -> **PASS**, seizes 1.0803 token = **$55.00 = 1.10 × 50**, debt down 50 WXDAI (`test_3`, gas 1,488,959).

**Path B — `receiveMethod=0` (aRTW).**
1. Same call with method 0 → **executes**; caller receives ≈55 aRTW and a wrapper-ledger claim.
2. `aRTW.transfer(...)` → `CallerNotPoolOrWrapper` (`0xa3a2cfb6`).
3. `wrapper.withdraw(token, amount, freshEOA)` → **revert `RU03`**.
4. `wrapper.withdraw(token, amount, whitelistedAddress)` → succeeds, but delivers the asset to that whitelisted party, not the attacker.
5. **Net: −100% of deployed capital** (a dead claim). Fork proof: `test_4_method0_anon_claim_is_dead` **PASS**, gas 2,396,405.

**Path C — anything else.**
- Direct `POOL.liquidationCall` by an outsider: the pool transfers aRTW to the liquidator; `ATokenRTW.transferOnLiquidation` requires `to == wrapper` → reverts.
- `supply()`: requires holding a RealToken; a fresh address cannot receive one.
- Unbacked RTW mint / aRTW inflation: `RTW.mint/burn` onlyWrapper; aRTW index fixed at 1e27 and ledger writes only from token transfers.
- `receiveMethod=2` (DEX stablecoin): `LiquidationWithDexActivated` never emitted, `_realTokenDex` unset → reverts.
- `recoverByGovernance`, `updateTokenPrice`, `whitelistAssets`, upgrade: role-gated to the single EOA `0x5Fc96c18…` (P-side; out of scope for E-U).

**Costs:** Gnosis gas is economically irrelevant (1.1–7M gas per call at ~1 gwei ≈ $0.001–$0.01). The binding constraint is the whitelist, not capital or gas.

---

## 5. Conditional case (not E-U): whitelisted RealT user + re-enabled IBP

The only ≥0.909× channel is **off-chain, discretionary and currently paused**: RealT’s **Issuer Buyback Program** buys at the appraised price (= the frozen wrapper mark) minus 1.5% processor + 1.5% RealT + ≤5% vacancy → **net 0.92–0.97×**.

Live status fetched **2026-10-18T00:37Z** from `https://realt.co/sell-orders/` (`analysis/ibp_status.json`):

```
sell_tokens_settings.allow_sell_orders = "FALSE"
sell_order_processor_percent = "1.5"
sell_order_realt_percent     = "1.5"
sell_order_max_vacancy_percent = "5"
disabled_notice = "The Issuer Buyback Program is temporarily suspended due to ongoing
                   procedures. YAM remains operational ..."
```

Quantification (`analysis/ibp_conditional.json`, block 48,811,858):

| Item | Value |
|---|---|
| IBP-eligible RealTokens (of 623) | **118** |
| Eligible collateral inside the 204 underwater accounts | **$663,182.59** (149 accounts) |
| Total collateral of those accounts | $7,458,576.22 |
| **Deployable capital** (min(closeFactor·debt, eligible/1.1)) | **$591,809.90** |
| Net at IBP 0.92 | **+$7,101.72** (**+1.2%**) |
| Net at IBP 0.945 | **+$23,376.49** (**+3.95%**) |
| Net at IBP 0.97 | **+$39,651.26** (**+6.7%**) |

Conditions: (a) a RealT-whitelisted/KYC’d account, (b) IBP switched back ON, (c) RealT + issuer approval at ~$600k scale while RealT is in **voluntary liquidation** (announced 2026-07-02), (d) weekly limits. These are off-chain and unverifiable from the chain; hence **medium confidence**. This belongs in a **conditional/privileged bucket**, never in E-U.

The incumbent’s behaviour corroborates that this is the only profitable channel: 722 liquidations, 20 of its 21 seized token types IBP-eligible, and no public dumping.

---

## 6. PoC / fork verification

Foundry project: `poc/` (vendored `forge-std`), pinned Gnosis fork **block 48,811,720** with `GNOSIS_RPC_URL` (public fallback `https://rpc.gnosischain.com`).

```
forge test -vv
[PASS] test_1_state_snapshot()                      (gas:   863,406)
[PASS] test_2_method1_anon_reverts_RU03()           (gas: 1,353,292)
[PASS] test_3_method1_whitelisted_safe_succeeds()   (gas: 1,488,959)
[PASS] test_4_method0_anon_claim_is_dead()          (gas: 2,396,405)
Suite result: ok. 4 passed; 0 failed; 0 skipped
```

What each test proves:
1. **State snapshot:** HF 0.9204 on `0xcd2a…64c3`; collateral $763.78 / debt $580.88; mark $50.91; 4.062754 token ledger — the headline is live at the pinned block.
2. **RU03 gate:** a fresh EOA with 100 WXDAI calls `liquidationCall(..., 1)` → `revert RU03`; balance unchanged, zero tokens received.
3. **Whitelist flips the result:** the exact same call from the incumbent Safe succeeds; seizes 1.0803 token ($55.00 at mark, 1.10× the 50 WXDAI repaid); borrower debt drops 50 WXDAI. Mechanics confirmed, gate confirmed as the only difference.
4. **method=0 is a dead claim:** liquidation executes (≈55 aRTW), `aRTW.transfer` reverts `CallerNotPoolOrWrapper`, `withdraw(to=fresh)` reverts `RU03`, `withdraw(to=Safe)` succeeds — the attacker can only *donate* the asset to a whitelisted party.

**CI (green):** [run 39084872190](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39084872190) — 4/4 Foundry tests PASS; all live re-checks (`ci_check`, census, `gate_probe`, `gate_all`, Yam book, incumbent) exited 0 and their JSONs are in `ci-out/`. The CI reproduced 623/623 fresh-EOA denials, 204 liquidatable accounts, $418,691.34 bonus pool, `allow_sell_orders=FALSE`, and zero cash bids ≥0.4×.

---

## 7. Verdict, residual/latent risk, blockers

**Verdict: E-U $0.00, high confidence.** The v4 “$418k permissionless liquidation” headline is a **notional, non-realizable** number: the call is permissionless, but the **recipient whitelist** stops the value at the last hop, and the **exit market** would not pay the 0.909× break-even even if it did not.

| Bucket | USD | Confidence | Note |
|---|---|---|---|
| **E-U** | **$0.00** | **high** | method=1 reverts RU03; method=0 dead claim; no cash exit ≥0.909× |
| **H-O** (holder-only) | $0 | high | aRTW holders can only withdraw to whitelisted recipients at frozen marks; stable suppliers cannot withdraw (100% utilisation) |
| **P** (privileged) | $0 | high | one EOA holds all roles; no unprivileged path |
| **S** (stuck) | $0 | — | not classified as stuck; whitelisted holders can still redeem |
| **Conditional** (whitelist + IBP) | **+$7,102 to +$39,651** on $591,810 deployed | **medium** | off-chain approval, IBP paused |

**What would change the verdict (falsifiers):**
1. Any fresh/non-whitelisted address receiving a RealToken from the wrapper (method=1 or withdraw) → RU03 claim invalid.
2. A public resting **cash** bid ≥0.909× at size on Yam/Levinswap (or a credible open OTC bid) → the E-U number rises toward the dump/parity band (still ≤ notional).
3. IBP **active** (`allow_sell_orders ≠ FALSE`) and accepting outsider orders at >$10k → conditional becomes reachable, but still requires a whitelisted/KYC’d seller.
4. A rule-engine/Processor change (new token with no recipient rule, or a whitelisted public contract with a permissionless `execute`) → re-audit immediately.

**Residual/latent risk to monitor:**
- IBP switch (`realt.co/sell-orders`, `allow_sell_orders`), weekly limits and approval behaviour.
- Wrapper `RealTokenPriceUpdated` events (marks frozen since 2025-12-30; a reprice changes the bonus pool and the conditional math).
- Whitelist/rule-engine changes and any newly added token without a recipient rule.
- New Yam bids ≥0.9× (cash, funded) or a Levinswap pool with real depth.
- Incumbent Safe activity (last liquidation 2026-10-14; HF 0.914–0.999 top accounts remain).

**Recommendation: KEEP as the campaign’s correction/case study; REMOVE from the live-prize / HIGH E-U ranking.** It is a high-quality negative result, not a live extraction.

---

## 8. Methodology, sources, caveats

**Method.** All addresses/roles/balances/allowances were read on-chain at pinned blocks via keyless/public Gnosis RPC (no keys in any artifact). Source was pulled from Blockscout (verified implementations: `RealTokenWrapper`, `ATokenRTW`, `RTW`, `PoolV2`, `RealTokenYamUpgradeableV3`, `Processor`). Borrower census: Blockscout v2 holders of the three variable-debt tokens → 1,464 unique → Multicall3 `getUserAccountData`. Book: full 250,283-offer enumeration from the v4b run + fresh `showOffer` liveness for every candidate (the book is provably unchanged: `getOfferCount` identical and 0 created/deleted/accepted since block 48,794,906). Fills: `OfferAccepted` logs over 30 days. Fork PoCs: Foundry on a pinned Gnosis fork. No mainnet transactions.

**Caveats.**
- The 0.909× break-even uses wrapper marks frozen at 2025-12-30; the $418,691 bonus pool is *notional at those marks*, not cash.
- The RU03 gate is administered off-chain by RealT; the on-chain rule engine is the enforcement point. A future whitelist change could reopen Path A (though the exit market would still lose money at 0.137×).
- aWXDAI/aUSDC are treated as **impaired, not cash** (pool ~100% utilised; last observable market $0.188–0.195). The full-book liveness uses the Oct-17 enumeration; the delta scan (0/0/0 + 1 update) proves it is still current.
- IBP eligibility (118 tokens) and the 0.92–0.97 net are read from RealT’s own sell-orders page (price formula and per-property flags); approval/limits/paused status are off-chain and cannot be proven from the chain.
- The v4 “plain EOA” fork success is explained: that address was whitelist-eligible (it held token dust). The v4b correction is confirmed here at 623/623 scale.

**Files.**
```
realt-rmm/
├── README.md                     # this report
├── summary.json                  # machine-readable verdict
├── analysis/
│   ├── gnosis.py                 # keyless RPC helpers (no secrets)
│   ├── live_state.py/.json       # core state, reserves, basket, transfer probes
│   ├── census.py/.json           # 1,464 borrowers → 204 HF<1, $418,691 bonus pool
│   ├── gate_probe.py/.json       # 40 tokens × 8 destinations + Safe withdraw proof
│   ├── gate_all.py/.json         # ALL 623 tokens × 4 destinations (0 bypasses)
│   ├── public_contracts.py/.json # 12 public Gnosis contracts: only the wrapper is whitelisted
│   ├── yam_book.py/.json         # 6,000-offer sample + 30-day fills
│   ├── book_full.py/.json        # exhaustive 250,283-offer analysis + fresh liveness
│   │                              #   (input pickle is the v4b /tmp artifact, not committed)
│   ├── incumbent.py/.json        # Safe owners/holdings + 30-day liquidation flow
│   ├── ibp_conditional.py/.json  # conditional 118-token / $591,810 / +1.2–6.7%
│   ├── ibp_status.json           # IBP allow_sell_orders = FALSE (2026-10-18)
│   └── wrapper_tokens.json       # 623 marks
├── poc/                          # Foundry: foundry.toml, test/RealtRmm.t.sol, lib/forge-std
├── ci/run.sh, ci/ci_check.py     # CI live re-checks → ci-out/
├── ci-out/                       # CI artifacts (JSON + logs)
├── ci-log.txt                    # downloaded by ci/ci-run.sh
└── ci-artifacts/                 # downloaded by ci/ci-run.sh
```
