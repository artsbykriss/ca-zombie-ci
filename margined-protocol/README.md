# Margined Protocol — L2 Phase-2 deep dive (Neutron + Osmosis, CosmWasm)

**Date:** 2026-10-15 · **Chains:** Osmosis (osmo-1), Neutron (neutron-1) · **Status:** read-only; no transactions; no signing; no broadcast.
All "dry-runs" below are `POST /cosmos/tx/v1beta1/simulate` with a **dummy signature** — the state is discarded by the node, nothing is signed or sent.

**Triage row (L2 Phase-1):** LIVE-FUNDED, $11,031.97, 18 vault contracts, confidence medium — *"Osmosis+Neutron vaults hold ~$11K (TIA/ATOM/OSMO/stOSMO); sunset derivatives."*

---

## 1. TL;DR

| Target | Live value (USD) | Category | Why |
|---|---|---|---|
| Osmosis redemption vaults (TIARedemption, ATOMRedemption, OSMORedemption) | **$9,506** | **S (stuck)** | Deposit **and** redeem both revert: the handler dispatches a `feed` submessage to its `feedr` contract (code 1887), which does not implement `feed`. Nobody (holders included) can withdraw until the team migrates the feedr. |
| Osmosis LSD vault banks (stOSMO, stTIA, ampOSMO, bOSMO, qOSMO) | **$184** | mostly **S**, small **E-U ≤$12 conditional** | stOSMO/ampOSMO deposits+redeems work but round-trip P&L ≈ 0 (see §4); bOSMO/stTIA deposits revert (slippage / swap-estimate); qOSMO deposit panics (division by zero). |
| Neutron redemption escrow (`margined-locust-redemption-queue`) | **$8,369** | **H-O** | 4 pending redemptions, 3 users; user-scoped claims proven (user claims OK, non-user → `No redemptions found`). 5,000 ATOM of it belongs to a Hydro Hedging Strategy redemption (shared escrow, not Margined). |
| Neutron ATOMdATOM fund vault | **$436** | **H-O** | NAV-proportional vault (public `fund` source matches); holders can redeem pro-rata. |
| Neutron fund vaults ATOMFund/wBTCUSDC/NTRNUSDC/TIAUSDC/ATOMUSDC/TIAFund | $0 | **S** | Contract bank balances are **zero** while internal accounting (`total_staked_tokens`/`total_withdrawn_tokens`) is non-zero — assets withdrawn by controllers, no recoverable bank. |
| NTRNStructured | $0.00 | S | 0.5 NTRN, deposits/redemptions never processed. |

## 2. Total live extractable **now** (external unprivileged attacker)

> ### **E-U = $0.00** (confidence: **high**)
> One conditional, low-confidence path remains: **ampOSMO LSD vault** — a 1 ampOSMO deposit→redeem returns 1.1654 OSMO; if ampOSMO's true market value is below 1.1654 OSMO the cycle is profitable, capped by the vault's liquid bank (288.35 OSMO ≈ **$12**). ampOSMO's only pool (1923) is broken (`ran out of ticks`), so obtaining ampOSMO at a discount is **not demonstrated**; with the ampOSMO actually available to a fresh attacker the profit is ~$0.07. Classified **conditional ≤$12, low confidence** — not counted in the headline.

Full split: **E-U $0.00 · H-O $8,804.95 · P $0.00 · S $9,689.82 · total live in scope $18,494.77** (prices: OSMO $0.0418508, ATOM $1.67378, TIA $0.52853, stOSMO from on-chain swap 1.418482 OSMO; block heights Osmosis 72,560,792 / Neutron 61,879,419, 2026-10-15 06:48 UTC).

## 3. What Margined Protocol actually is (verified on-chain)

Contract families (identified from cw2 `contract_info` in raw storage + WASM binaries downloaded from the chains):

| Family (package) | Code IDs | Where | Role |
|---|---|---|---|
| `locust-vault` (LSD) v0.3.0/0.5.0 | OSMO 1049, 1457 | stOSMO, stTIA, ampOSMO, bOSMO, qOSMO | CL-position "LSD" vaults (pool_id, token0/token1, tolerance/slippage/max_positions). Deposit/redeem open; `process_withdrawal`/`rebalance` controller-only; `crank` permissionless. |
| `redemption-vault` v0.2.1 | OSMO 1295 | OSMORedemption, TIARedemption, ATOMRedemption, DYDXRedemption | "Redemption arb" vaults with `instant_withdraw_penalty` (20–50%), `penalty_duration` (21–30 d), whitelisted pools, rewards/feedr address. |
| `locust-vault` v0.2.1 (grid) | OSMO 1887 = NTRN 5221 (identical binary) | usdcaxlGrid, DYDXRedemption, **feedr contracts**, and all Neutron `fund`-labeled vaults | Query entrypoint stubbed (`unimplemented!()`); execute = `deposit`/`redeem`/`vault_extension`. |
| `fund` v0.1.0/0.2.0/0.3.1 | NTRN 5221, 3387 | ATOMFund, ATOMdATOM, wBTCUSDC, NTRNUSDC, TIAUSDC, ATOMUSDC, TIAFund | Source available in `margined-protocol/locust-vault-framework` (v0.3.0 ≈ deployed); controller withdraw/repay, permissionless crank (fees→treasury), pro-rata redeem into escrow. |
| `structured-vault` v0.0.2 | NTRN 1825 | NTRNStructured | Subscription-based vault, never processed. |
| `redemption` (escrow) v0.1.0 | NTRN 3383 | `neutron1rl7key…erkva8` | Escrow queue; `SendRedemption` whitelisted-funds-only; `ClaimRedemption` per-user. Source = framework repo v0.1.0 (exact match). |

Roles/ownership (all verified): every vault's admin/owner is a team EOA (`osmo1g8qypve…`, `osmo13y2js…`, `neutron1ha2hjl…`); controllers are separate EOAs; `pause`/`set_open`/`update_config` → `Caller is not admin`; `repay` → `Unauthorized`; `process_withdrawal` → `Unauthorized` (proven by dry-run from non-privileged signers). No permissionless function pays the caller: `crank` only accrues management fees to the treasury (fund) or rebalances (LSD).

## 4. The decisive experiment — LSD vault deposit→redeem round trip

Because `convert_to_shares`/`convert_to_assets` are stubbed in the deployed code, P&L was measured by executing a full **deposit + redeem in one simulated transaction** (state discarded) and reading the transfer events:

| Vault | In | Minted shares | Out | On-chain value | Net |
|---|---|---|---|---|---|
| stOSMO | 1.000000 stOSMO | 1,014,017 | 0.134922 stOSMO + 1.227598 OSMO | 1.418982 OSMO | **+0.035%** (break-even) |
| stOSMO | 4.000000 stOSMO | 4,056,070 | 0.540992 stOSMO + 4.904296 OSMO | 5.671876 OSMO | +0.033% |
| ampOSMO | 1.000000 ampOSMO | 44,978 | 0.000034 ampOSMO + 1.165420 OSMO | 1.1654 OSMO | depends on ampOSMO price |

Price basis: **on-chain executable swap**, 1 stOSMO → **1.418482 OSMO** (simulated pool-1252 swap; 0.1 OSMO → 0.070399 stOSMO ⇒ marginal 1.4205). Earlier DefiLlama `stride-staked-osmo` readings ($0.0546 with OSMO $0.0435 ⇒ ratio 1.254) were stale and made the same round trip look +11%; with the real on-chain rate it is **break-even**. This is the key correction that keeps the headline at $0.

Other deposit gates (all dry-run verified): OSMO deposits into stOSMO/ampOSMO vaults → `slippage bound` revert; bOSMO deposit → `slippage bound` revert (deterministic, both 1 and 2 boneOsmo); stTIA deposit → `Failed to estimate swap amount` (pool 1428); qOSMO deposit → panic `Denominator must not be zero`; redemption-vault deposits → `feed` submessage revert.

## 5. The bricked redemption vaults (S ≈ $9.5K) — the main live-state correction

A deposit into TIARedemption/OSMORedemption/ATOMRedemption reverts with:

```
dispatch: submessages: Error parsing into type cw_vault_standard::msg::VaultStandardExecuteMsg<vault::locust::ExtensionExecuteMsg>:
unknown variant `feed`, expected one of `deposit`, `redeem`, `vault_extension`
```

The handler dispatches a `feed` message to the vault's `rewards`/feedr contract (`margined-feedr-osmo` / `margined-feedr-atom`, code 1887 — same binary as usdcaxlGrid/DYDXRedemption), which does not implement `feed`. The **same revert occurs on redeem** (verified with a real share-holder, deployer2, sending 1,000,000 TIARedemption shares). Consequence: the $9.5K held by these three vaults is **stuck for everyone**, not just unprivileged attackers; the fix is a privileged migration of the feedr contracts (P). DYDXRedemption is empty.

## 6. What an attacker can / cannot do

**Can:** deposit into stOSMO/ampOSMO LSD vaults (round trip ≈ break-even, net $0); call `crank` (no payout to caller); claim own pending redemptions in the Neutron escrow (H-O); deposit/redeem ATOMdATOM pro-rata (H-O); read everything.
**Cannot (verified):** call any admin/controller function (`Caller is not admin` / `Unauthorized`); claim another user's escrow redemption (`No redemptions found`); withdraw from the redemption vaults at all (S); deposit into bOSMO/stTIA/qOSMO or with OSMO; extract from any vault without a proven pricing bug. Preconditions for the conditional ampOSMO path: acquire ampOSMO below 1.1654 OSMO/unit with real liquidity (not demonstrated; pool 1923 broken), profit capped by the vault's 288.35 OSMO bank.

## 7. Verification (CI)

* Job: `margined-protocol/ci/run.sh` → `ci/verify.py` (read-only; public LCDs + simulate dry-runs) → `ci-out/verify.json`, `ci-out/verify.log`.
* Reproduces: heights, all bank balances, stOSMO+ampOSMO round trips, on-chain stOSMO→OSMO price and net P&L, redemption-vault deposit reverts, escrow user/non-user claim, admin gate.
* CI run: **see `summary.json → poc.ci_run_urls`** (GitHub Actions, `artsbykriss/ca-zombie-ci`).
* Local artifacts: `analysis/live-state-probe1.json`, `analysis/raw-storage.json`, `analysis/escrow.json`, `analysis/escrow-all-redemptions.json`, `analysis/sim-*.json`, `analysis/wasm/*.wasm` + strings, `analysis/prices-onchain*.json`.

## 8. Verdict & residual risk

* **E-U: $0.00 (high confidence).** The triage's "$11K live" is real value but it is **not attacker-extractable**: $9.5K is bricked by the `feed` bug (S), $8.4K is a user-claimable escrow (H-O, mostly Hydro's), $436 is a pro-rata fund vault (H-O), $184 sits in LSD vault banks whose deposit/redeem paths are either blocked or break-even.
* Residual/latent: (a) if the team migrates the feedr contracts, redemption-vault deposits/redeems resume — re-check the instant-withdraw-penalty math then (source unavailable, wasm strings only); (b) ampOSMO if it ever becomes liquid below 1.1654 OSMO/unit (≤$12); (c) admin keys are live EOAs — a compromised key could migrate/drain (P), not unprivileged.
* Blockers encountered: vault-standard pricing queries stubbed (`unimplemented!()`); simulate requires an existing signer account (solved with public on-chain pubkeys + dummy signature, never broadcast); DefiLlama has no direct feeds for stTIA/ampOSMO/bOSMO/qOSMO (priced via TIA proxy / on-chain swaps).

## 9. Methodology & caveats

* All state read at explicit heights (Osmosis 72,560,792 / Neutron 61,879,419) from public LCDs (`osmosis-api.polkachu.com`, `lcd-neutron.keplr.app`, `osmosis-rest.publicnode.com`).
* WASM binaries for code IDs 1049/1295/1457/1887 (Osmosis) and 1825/3383/3385/3387/5221 (Neutron) downloaded via `/cosmwasm/wasm/v1/code/{id}` (public chain data) for interface/auth analysis (`strings`).
* Execute-path behaviour proven with `simulate` dry-runs using public on-chain pubkeys and 64-byte dummy signatures; **no signature, no broadcast, state discarded**.
* USD = DefiLlama where available; stTIA valued at TIA (proxy, understates), stOSMO from on-chain swap, bOSMO/qOSMO from on-chain swaps, ampOSMO at OSMO (proxy).
* Caveats: simulate responses are point-in-time; CL position values inferred from payout events; `total_assets` units differ per family; escrow ATOM belongs to Hydro's users (shared framework escrow).

## Files

```
margined-protocol/
├── README.md                 (this file)
├── summary.json
├── analysis/                 (probes, raw storage, escrow, wasm + strings, simulations)
├── ci/run.sh, ci/verify.py   (read-only CI verification job)
├── ci-out/                   (verify.json / verify.log)
└── ci-log.txt, ci-artifacts/ (filled by ci-run.sh)
```
