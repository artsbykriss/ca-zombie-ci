# Rose (Aurora) — zombie-hunt L2 Phase-2 deep dive

**Date:** 2026-10-14 · **Chain:** Aurora (chain id 1313161554) · **Status:** read-only; PoC fork-verified only; no mainnet transactions.
**Finding:** L-2 Phase-2 row 16 — "Rose" (DefiLlama slug `rose`, adapter `projects/rose/index.js`), triage live custody **$118,808**.
**CI:** GitHub Actions run https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38484211687 (`rose` branch, **18/18 tests PASS**, state dump block 219,876,627) — see `ci-log.txt` and `ci-artifacts/`.

---

## 1. TL;DR

| target | live value (realisable) | external-unprivileged extractable | why closed / open |
|---|---|---|---|
| 3pool `0xc90d…4A3f` (DAI/USDC/USDT) | $54.4k (LP-owned) + $0.7k admin fees | **$0.014** (one-shot imbalance bonus) | Curve-style stableswap; add/remove round-trips lose except a one-shot ~0.000095% imbalance bonus; LP tokens + admin fees owner/holder-gated |
| metaUST `0x8fe4…22B8` | $2.4k at Aurora-DEX UST price | $0 | pool prices UST at $0.0363 = Aurora market (Trisolaris $0.0358); both round-trip directions loss-making |
| metaFRAX `0xa343…3E94` | $5.8k | $0 | FRAX priced ~$0.999 in-pool; no executable Aurora FRAX market to arb against (Trisolaris FRAX pools are dust) |
| metaMAI `0x65a7…9D23` | $0.5k | $0 | MAI priced $0.54 in-pool; no Aurora MAI market |
| RUSD pool `0x79B0…BA34` | $3.0k | $0 | RUSD priced $0.31 in-pool = Trisolaris RUSD/WNEAR market ($0.30); round trips lose |
| VASE (BentoBox) `0xee79…22FF` | $42.7k (users/treasury) | $0 | byte-level stock BentoBox V1 (only error strings renamed + `STRATEGY_DELAY` removed — owner-only impact); `totals == balanceOf` for all tokens; no `skim`; flash loans require whitelisted masters |
| Gardens ×6 (Kashi CDP) | $27.7k collateral (net of borrows) | **≈$0.06** (liquidation dust) | all insolvent users already harvested by the team's keeper bot; remaining insolvent collateral ≤ $0.081 total; solvent positions protected by fixed Chainlink-style oracles |
| Farms ×5 (multi-reward staking) | $27.9k staked LP | $0 | `recoverERC20`/`addReward`/`setPaused`/`nominateNewOwner` all owner-gated; `withdraw` only caller's own stake |
| stROSE vault `0xe23d…e16F` | $316 (15.04M ROSE @ $0.000021) | $0 | `mint()` requires ROSE `transferFrom` (deposit); `burn()` self-only |
| RUSD token `0x19cc…642E` | ~$320 realisable (pool depth) | $0 | `mint` owner-only; `burn` self-only; only 2 shallow pools (~$320 depth) price it |
| admin fees (unclaimed) | $2,919.58 | $0 | permissionless `donate_admin_fees` sends them to the team's PaymentSplitter (`release()` pays fixed payees, not the caller) |

**Total live extractable by an external unprivileged attacker: ≈ $0.08 (≈8 cents). Confidence: HIGH.**

---

## 2. Architecture (verified on-chain)

Rose on Aurora = **Curve-style stableswap pools** + **Kashi-style CDP lending markets ("Gardens")** on a **BentoBox fork ("VASE")** + **RUSD** CDP stablecoin + **stROSE** staking + **multi-reward farms**.

```
                         ┌───────────────────────────────────────────────┐
   DAI/USDC/USDT ───────▶│ 3pool 0xc90d… (Curve fork, A=100, fee=4bp)    │── LP 0xff79d5…
                         └───────────────────────────────────────────────┘
                                    ▲ base pool (base_virtual_price cached)
        UST / FRAX / MAI ───▶ meta pools 0x8fe4…, 0xa343…, 0x65a7… (2-coin metas)
        RUSD ───────────────▶ RUSD pool 0x79B0…
                         ┌───────────────────────────────────────────────┐
   collateral tokens ──▶ │ VASE (BentoBox V1 fork) 0xee79…               │◀── share accounting
                         └───────────────────────────────────────────────┘
                                    ▲ deposits/withdrawals (msg.sender == from)
        6 Garden clones (Kashi fork, master 0x8570…) ── borrow RUSD, liquidate
                         ┌───────────────────────────────────────────────┐
   LP tokens ──────────▶ │ 5 multi-reward farms (owner 0x6adf…)          │── reward token ROSE
                         └───────────────────────────────────────────────┘
   ROSE ────────────────▶ stROSE vault 0xe23d…  (1.0504 ROSE per stROSE)
```

Key facts (all re-read on-chain; latest block recorded in `summary.json`):

* Pools: `owner()` = `0x6ADf17424F6E68733C71209471dA50e155B5C5B2`, `fee_receiver()` = `0xf042F2dABba35f83eb126116f7Ff8dAdfC631E97` (OpenZeppelin PaymentSplitter, 3 payees 63/30/7), `fee()` = 4,000,000 (4 bp), `A()` = 100 / `A_precise()` = 10,000, `is_killed` storage slot `0x10` = **0** (pools not killed), LP tokens are separate BoringFactory ERC-20s with `minter()` = the pool (mint reverts for third parties, `set_minter`/`set_name` owner-only).
* Gardens: 6 clones of the verified "Garden" master `0x857050Ef3a0241a2c1f65ca1F0c100a04E4AEd93` (Kashi fork, solc 0.8.13). `collateralizationRate` 85–90%, `liquidationMultiplier` 107.5%, `borrowOpeningFee` 0.3%, `interestPerSecond` 630,592,947 (~2%/yr). Oracles are fixed-price wrappers around Chainlink-style "Oracle Proxy X/USD" feeds (`get(bytes)` → `(true, rate)`), owner = deployer; not attacker-manipulable.
* VASE: byte-identical to Ethereum BentoBox V1 `0xF5BCE5…` except (a) error-string prefix `BentoBox:` → `Vase:`, (b) `setStrategy` lacks the 2-week `STRATEGY_DELAY` (owner-only impact), (c) 5 solc ABI-copy helper regions (net −9 B). Same 31-entry dispatch table; `skim` is not an external function (it is only an `IStrategy` method).
* Farms: 5 identical 8,926-byte multi-reward Synthetix-style stakers (`rewardTokens(0)` = ROSE); `owner()` = `0x6adf…`; all privileged functions revert for third parties.
* The old `projects/rose/index.js` adapter (2024-08-07) defines exactly the addresses audited here (3pool + 3 metas + VASE garden tokens + stROSE staking).

---

## 3. What an attacker can and cannot do

### E-U (the only two live paths, both dust)

1. **3pool one-shot imbalance bonus** — deposit `[5000 DAI, 5000 USDC, 5000 USDT]` via `add_liquidity(uint256[3],uint256)` (`0x4515cef3`) and immediately `remove_liquidity(uint256,uint256[3])` (`0xecb586a5`). Measured on-fork at the pinned block: LP minted 14,999.983; removal returns 4,890.2768 DAI + 5,122.7911 USDC + 4,986.9464 USDT = **+0.014271 DAI-equivalent (+$0.0143)**. Repeating the same round trip is loss-making (−0.00068, then −0.0059, −0.0085, −0.0090); the "perfect balancing" deposit (`[1064.16 DAI, 0, 621.74 USDT]`) **loses** −0.016. So the bonus is a one-shot of ≤ ~$0.015; net of Aurora gas it is marginal.
2. **Liquidation dust** — the team keeper (`0xd3c2002911422cc769fe0207fd80d845b6524a1e`, last active block 217,103,562) already harvested the meaningful insolvent collateral. The largest remaining insolvent positions (per-user scan of all 5 live gardens) seize only dust:
   * gardenWeth user `0xaE1A6d43…` → pay 0.0235 RUSD, seize 0.0000155 WETH (**$0.039**)
   * gardenNear user `0x4085e9Fb…` → pay 0.00254 RUSD, seize 0.002416 WNEAR (**$0.012**)
   * gardenUsdc user `0x3Af0f49A…` → pay 0.0278 RUSD, seize 0.030014 USDC (**$0.030**)
   Gross seized **$0.081**; net of RUSD acquisition (≈$0.31/RUSD marginal, see §5) ≈ **+$0.06**. Preconditions: approve the Garden master in the BentoBox (`setMasterContractApproval(self, 0x8570…, true, 0,0,0)`), hold RUSD VASE shares, choose `maxBorrowPart` ≈ 90% of the collateral-limited part (a full-debt part reverts with a Solidity 0x11 panic on `userCollateralShare - collateralShare`).

### Closed paths (with the live gate)

| candidate path | live gate that closes it |
|---|---|
| Drain a Garden by liquidating a *solvent* user | `liquidate` refreshes the oracle then skips solvent users (`Garden: all are solvent`); cf02ac (7.406 WETH vs 4,302 RUSD, ratio 2.39) and d74e80 (8,000 USDC vs 4,814 RUSD, 1.50) are solvent |
| Oracle manipulation → borrow against inflated collateral | oracle rates come from Chainlink-style proxies (`latestAnswer()`), not spot DEX pools; feeds undervalue WNEAR (4.4×) and WETH (0.65×) vs Aurora market and overvalue UST only 1.7× — and the gardens have only ~1,059 RUSD left to lend (test asserts < 1,200) |
| Borrow RUSD to extract | RUSD's realisable value ≈ $0.31 (marginal) and total market depth ≈ $320 (Rose RUSD pool 200.8 LP + Trisolaris RUSD/WNEAR 24.2 WNEAR); borrowed RUSD must be repaid 1:1 — no net gain |
| Arb meta pools vs market | Rose metaUST marginal UST price $0.03626 vs Trisolaris $0.03584 (test asserts within 25%); RUSD $0.3102 vs $0.3033 (within 30%); FRAX/MAI have no executable Aurora market (Trisolaris FRAX and MAI pools are drained dust) |
| Route inconsistency (direct vs two-step `exchange_underlying`) | all round trips lose (2×4 bp + slippage) in both directions and all sizes (tests) |
| LP over-mint / over-withdraw | `add_liquidity → remove_liquidity[_one_coin]` round trips lose (3pool, metaFRAX, both sides); `calc_*` views are consistent |
| Steal staked LP from farms | `recoverERC20(stakingToken, …)` reverts for non-owner; `withdraw` only the caller's own balance |
| Steal VASE deposits | `totals(token) == balanceOf(VASE)` for all 7 tokens (no excess); no strategies; only GardenMaster whitelisted; `allowed(from)` requires `from == msg.sender` or a master approved by `from`; `deploy` clones cannot move third-party shares |
| Steal admin fees | permissionless `donate_admin_fees` (`0x5cb2bb08`) transfers excess to `fee_receiver` (PaymentSplitter); test asserts the caller's balance is unchanged and the receiver receives exactly the excess |
| Drain stROSE | `mint(uint256)` reverts `BoringERC20: TransferFrom failed` (requires a ROSE deposit); `burn(address,uint256)` reverts `BoringMath: Underflow` for non-holders |
| Mint RUSD | `mint`/`mintToVase` are `onlyOwner`; `burn` is self-only |
| Pool admin abuse (kill/ramp/fee_receiver) | `kill_me`, `ramp_A`, `set_fee_receiver` all revert for non-owner (test) |

---

## 4. PoC / fork verification

* `poc/` Foundry project (solc 0.8.24, vendored forge-std). Fork: `https://mainnet.aurora.dev` (keyless), pinned at run time.
* **`poc/test/RoseExtraction.t.sol` — 14 tests, 14 PASS** (round trips, LP mint/burn, liquidations incl. dust measurement + solvent-revert, donate_admin_fees routing, VASE excess, farm gating, garden RUSD inventory, Aurora-market price consistency, stROSE gating, pool admin gating).
* **`poc/test/ImbalanceProbe.t.sol` — 4 tests, 4 PASS** (3pool max-extraction strategies incl. iterated round trips; all meta/RUSD-pool imbalance probes both directions → losses).
* Total: **18/18 PASS** (local run: `Ran 2 test suites … 18 tests passed, 0 failed`).
* CI also runs `ci/run.sh` → `ci/state_dump.py` (read-only, keyless) writing `ci-out/state.json` (pool/garden/VASE state + admin-fee excess = $2,919.57).

Key measured numbers (see `ci-log.txt` for the CI copy):
* 3pool round trip DAI→USDC→DAI: −0.08% … −1.6% (sizes 1k/5k/10k).
* metaUST USDC→UST→USDC: −0.09% … −0.079%; metaFRAX −0.088%.
* 3pool balanced add/remove: **+0.0143** (one-shot); iterated: +0.0143, −0.0007, −0.0059, −0.0085, −0.0090.
* Perfect-balance add/remove: −0.016 (loss).
* Liquidations: seized $0.081 total (gross), RUSD paid 0.0538 (≈$0.017).
* VASE excess: 0 for RUSD/WBTC/UST/USDC/USDT/WNEAR/WETH.
* Aurora market vs pool: UST $0.0358 vs $0.0363; RUSD $0.3033 vs $0.3102.

---

## 5. Value map and valuation caveats

* **User-owned (H-O, not attacker-extractable):** pool LP outside protocol contracts ($11.6k 3pool-LP + metas), farm-staked LP $27.9k (stakers' claim; farms owner-controlled), garden collateral $27.7k (encumbered by borrows), stROSE $316.
* **Team/privileged (P):** unclaimed admin fees **$2,919.58** (owner-claimable via the pools' donate function → splitter), treasury EOA `0x3820fedd…` VASE balances (391,566 RUSD + 0.40436 WBTC + 1,800 UST), fee-recipient contracts ($40.4k of already-distributed fees), 11 ROSE vesting contracts (129.1M ROSE), farms' owner functions, VASE owner (incl. the `STRATEGY_DELAY` removal), RUSD mint.
* **Stuck/uncertain (S):** two nonce-0 EOAs hold 12.16M + 0.4M ROSE; the 6th Garden clone `0x6bA5…` (no code now) holds 0.000192 WBTC + 32.27 RUSD VASE shares (stuck).
* **Valuation caveats:** the triage's $118.8k used DefiLlama *global* prices. On Aurora, UST actually trades at ~$0.036 (7× the global $0.0053) and RUSD at ~$0.31 marginal / ~$0.02 average-value, with only ~$320 total sell-side depth — so the RUSD-denominated “treasury” pot is not realisable at $121k; its practical value is bounded by the two pools' depth (~$320). At Aurora-DEX prices the live system value is ≈ $140–150k nominal, of which ~$2.9k admin fees + ~$150k user/team-held.

---

## 6. Verdict, residual and latent risk

* **Verdict:** external unprivileged extraction today ≈ **$0.08** (3pool imbalance bonus $0.014 + liquidation dust $0.06). Confidence **high** (fork-verified, all gates re-read on-chain). The protocol is a well-preserved zombie: pools unpaused, keepers gone, markets consistent.
* **Residual/latent:**
  * 3pool one-shot imbalance bonus recurs if anyone re-imbalances the pool (e.g., a large swap) — still ≤ ~$0.15 per re-imbalance (Σbalances − D).
  * The VASE's `setStrategy` lacks `STRATEGY_DELAY`: the (live, nonce-254) owner can queue+activate a strategy in one tx and `harvest` is public — a malicious strategy could move up to the vault's non-strategy balances only if the owner acts (P), so it is a team-risk, not E-U.
  * Insolvent bad debt accrues interest forever; the solvent positions (cf02ac, d74e80) become liquidatable only after ~9 years at 2%/yr (or if the owner changes oracles).
  * The farms and the PaymentSplitter remain owner/payee-controlled (P).
* **Blockers for extraction:** all admin functions owner-gated; oracle feeds fixed; RUSD effectively illiquid; keeper already harvested the collateral.

---

## 7. Methodology, sources, files

* Method: DefiLlama adapter history → address set; Aurora public RPC (`https://mainnet.aurora.dev`) reads at pinned blocks; bytecode fingerprinting (PUSH4 dispatch extraction, diff vs Curve/`curve-contract` and vs Ethereum BentoBox); Vyper disassembly for unknown selectors; event-log reconstruction (VASE `LogTransfer`/`LogDeposit`/`LogWithdraw`, garden `LogAddCollateral`/`LogBorrow`/`LogLiquidate` flows, ERC-20 transfers); per-user solvency computed from the deployed Garden formula; fork PoC (Foundry) for every live path; children: BentoBox byte-level verification + full holder/ownership map.
* Corpus consulted: `zombie_hunt/FINDINGS.md`, `l2-triage-b` plan/summary/results, DefiLlama API + `DefiLlama-Adapters` git history, Etherscan V2 (BentoBox V1 source), `curvefi/curve-contract`, Blockscout (Aurora explorer).
* Caveats: prices are point-in-time (DefiLlama/Aurora DEX); fork tests pin the latest block at run time; UST/RUSD “market” prices derive from shallow Aurora pools and are sensitive to size; the child1 STRATEGY_DELAY finding was verified by differential disassembly, not a compiler-reproduced build.

**Files:** `analysis/` (fingerprints, dispatches, probes, child1/child2 reports + raw JSON), `poc/` (Foundry tests), `ci/` (state dump), `ci-out/` (CI artifacts), `summary.json`.
