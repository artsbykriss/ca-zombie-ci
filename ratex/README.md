# RateX (Solana) — PT/YT leveraged-yield pricing path: read-only residual audit

**Date:** 2026-10-25 · **Chain:** Solana · **Status:** read-only; `simulateTransaction` (sigVerify:false) only; **no mainnet transaction signed or sent.**

**Scope:** ZH4 pass-7 lane `solana-sui.md` row 10 (RateX, DefiLlama `ratex-dex` ≈ $2.37M). This is the *distinct* RateX component (a leveraged-yield PT/YT AMM) — the collateral whose *pricing on the Loopscale side* broke Loopscale in Apr-2025. This audit tests RateX's **own** PT/YT pricing path for an unprivileged attacker.

## TL;DR

| Target | Live extractable (unprivileged) | Why closed | Latent risk |
|---|---|---|---|
| RateX program `RAtEwzA1…` (8 yield markets, PT/YT) | **$0** | Every pricing-path account is Anchor-bound (`ConstraintAddress` / `ConstraintRaw` / `ConstraintHasOne` / `ConstraintTokenOwner`); oracle & market-status mutations are `has_one`-gated to `state.admin`; only view/refresh instructions are permissionless and take no attacker-controlled value | Admin key `93KT94u…` (P) and off-curve upgrade authority (P) |

**Total live extractable now: $0.00 — confidence HIGH.**

## 1. The mechanism tested

RateX is a Pendle-style leveraged-yield exchange on Solana: per maturity it runs a **YieldMarket** (an AMM over a base LST and a synthetic quote) plus an **EarnVault** that mints/redeems **PT** (principal tokens) against a **rate oracle**. PT/YT pricing therefore depends on (a) the AMM `sqrt_price` and (b) the oracle `rate`. The classic unprivileged drain would be: substitute the caller-supplied `oracle`/`observation_state`, or move the AMM price, to mint PT cheaply / redeem expensively, or trigger liquidations of healthy margin positions.

Deployed code: `RAtEwzA1rerjeWip6uMuheQtzykxYCrEQRaSFCCrf2D` (BPFLoaderUpgradeable, programdata `CyrBq2j6YirGmGjhTAZCW6Dxex2kUzZoNvcrczchcntB`, deployed slot 358,637,540, ELF 2,423,952 B). Full Anchor IDL recovered (v2, 118 instructions) and cross-checked against the deployed program (the `earn_redeem` discriminator `[93,162,58,1,75,18,212,66]` matches on-chain txs).

## 2. Live state (slot 461,381,210)

| Account | Address | Notes |
|---|---|---|
| Program | `RAtEwzA1rerjeWip6uMuheQtzykxYCrEQRaSFCCrf2D` | upgrade auth `AbkPd7MssyeQmEfF4fDusoJTn2um4LArZHvk4wms4pig` (**off-curve** PDA) |
| State | `D332M7rsrdvF3VRcwMw3jvC4J5VPrwa2PoKEJQoCSbDV` | `admin = 93KT94uivk9egZVPReW27pmUpiBsHhSV11AmUuSExUVU`; keepers `93KT94u…, FVKcPm…, E5j3c7…`; twap_duration 300 |
| YieldMarkets | 8 (e.g. `6Z5Fg7cD…`) | 7 Expired, all `market_index` 0–7 |
| EarnVaults | 8 | PT supplies 0 → 9.2e10 base units |
| Oracles | 8 | `admin = 93KT94u…`; JitoSOL/bbSOL/BNSOL/INF-25xx |
| MarginMarkets | 17 | JitoSOL/bbSOL/BNSOL/INF/wsol, all Active |
| Lp / User | 39 / 38 | — |
| RateX ALT | `eP8LuPmLaF1wavSbaB4gbDAZ8vENqfWCL5KaJ2BRVyV` (232 addrs, authority `6az11ifD…`, on-curve) | DL adapter TVL source |

**TVL (live read):** summing the ALT-listed vault token accounts gives **≈ $1,995,982** at DefiLlama prices on 2026-10-25 (DL headline $2.37M). The at-risk surface is this ~$2M of market vault collateral.

## 3. What an attacker can / cannot do (simulateTransaction, sigVerify:false)

All simulations use a **neutral, unprivileged funded signer** (`5tzFkiKscXHK5ZXCGbXZxdw7gTjjD1mBwuoFbhUvuAi9`) and real program accounts.

| # | Instruction | Attacker action | Result | Verdict |
|---|---|---|---|---|
| 1 | `update_oracle` | neutral signer as `authority` | `Custom 2001 ConstraintHasOne` (account: state) | **gated to state.admin** |
| 2 | `update_oracle` | real admin signer (control) | `err: null` | admin-only works |
| 3 | `update_yield_market_status` | neutral signer | `Custom 2001 ConstraintHasOne` | **gated** |
| 4 | `epoch_update_begin` | neutral signer | `Custom 2001 ConstraintHasOne` | **gated** |
| 5 | `rollback_oracle` | neutral signer | `Custom 2001 ConstraintHasOne` | **gated** |
| 6 | `earn_redeem` | replay control | reaches handler (SPL err on already-redeemed PT) | control OK |
| 7 | `earn_redeem` | **substitute `oracle`** | `Custom 2012 ConstraintAddress` (account: oracle) | **oracle bound to market** |
| 8 | `earn_redeem` | **substitute `yield_market`** | `Custom 2003 ConstraintRaw` | **bound** |
| 9 | `earn_redeem` | substitute `earn_vault` | `Custom 2001 ConstraintHasOne` | **bound** |
| 10 | `earn_redeem` | substitute `authority` (neutral) | `Custom 2015 ConstraintTokenOwner` | **user token acct must be owned by signer** |
| 11 | `observe` | permissionless | `err: null` | by design (records current AMM price; no arbitrary value) |
| 12 | `calculate_pt_price` | permissionless view | `err: null` (pt_price_in_quote 1e9) | view only |
| 13 | `liquidate` | neutral signer on a live User | `Custom 2003 ConstraintRaw` (account: state); with admin signer → `Custom 6092 MeetMaintenanceCollateralRequirement` | **cannot seize a healthy position; authority-bound** |

The instruction surface (97 v1 / 118 v2) contains **no state-mutating instruction without a signer**: the only signer-less instructions are `calculate_*`, `get_amm_twap`, `load_observation_state`, `observe` — all read/refresh. Every oracle/status/epoch/admin instruction requires the `state.admin` signer. `earn_invest` (PT mint) shares the identical oracle/observation_state/yield_market account bindings as `earn_redeem`; no recent `earn_invest` transaction was available to replay (last 120 program sigs), so its binding is proven structurally rather than by replay.

## 4. Verdict and residual/latent risk

- **E-U (external unprivileged): $0.00 — HIGH confidence.** The PT/YT pricing path is closed: the oracle, yield market, earn vault and user token account are all Anchor-bound; oracle rate and market status are `has_one`-gated to `state.admin`; the only permissionless instructions move no value.
- **P (privileged):** the single admin key `93KT94uivk9egZVPReW27pmUpiBsHhSV11AmUuSExUVU` can set any oracle rate (`update_oracle`) and pause/expire markets (`update_yield_market_status`) across all 8 markets → a compromised admin key is a total-loss risk. The program upgrade authority `AbkPd7Ms…` is an off-curve PDA.
- **Historical note:** the Apr-2025 Loopscale failure was a *Loopscale-side* collateral-pricing error on RateX PT, not a RateX contract bug; that is out of scope here.
- **H-O / S:** none material (users can deposit/withdraw/redeem normally).

## 5. PoC / reproduction

- `analysis/ratex_probe.py` — self-contained live-state + simulation matrix (stdlib only). Writes `ci-out/ratex_results.json`.
- `analysis/ratex_tvl_probe.py` — ALT-vault TVL (DefiLlama prices).
- `analysis/soltx.py` — legacy-message builder for `simulateTransaction(sigVerify:false)`.
- `analysis/ratex.idl.json` — recovered Anchor IDL; `analysis/ratex_instructions.txt` — instruction names from the ELF.
- Run: `bash ci/run.sh` (or `python3 analysis/ratex_probe.py`).
- **CI:** see `ci-log.txt` / run URL recorded in `ci-out/ratex_results.json` companion notes.

## 6. Methodology, caveats, files

Read-only JSON-RPC (`getAccountInfo`, `getProgramAccounts`, `getSignaturesForAddress`, `getTransaction`, `simulateTransaction` with `sigVerify:false`, `replaceRecentBlockhash:true`). Addresses/roles/balances read at explicit slots. The v2 IDL is a slightly newer build than the deployed program (struct size differs by ~28 B); the *instruction* discriminators match, and the account *constraint* names/messages come from the deployed program's own Anchor logs, so the gating conclusions do not depend on the IDL version. Balances are point-in-time 2026-10-25.

Files: `README.md`, `summary.json`, `analysis/*`, `poc/README.md`, `ci/run.sh`, `ci-out/*`, `ci-log.txt`.

*Prepared 2026-10-25 · ZH4 p7-solana-c · read-only · no tx signed/sent.*
