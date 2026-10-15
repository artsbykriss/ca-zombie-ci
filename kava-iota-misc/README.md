# L2-25 — Kava / IOTA misc cluster deep-dive (Kava Swap · Kava Earn · Steer · Tarot · Blueshift · SYMMIO-IOTA · MagicSea)

**Date:** 2026-10-15 · **Chains:** Kava L1 (`kava_2222-10`), Kava EVM (2222), IOTA EVM (8822) · **Status:** read-only; PoC fork-verified only; no mainnet transactions.
**CI:** GitHub Actions `artsbykriss/ca-zombie-ci` run **[38738681388](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38738681388)** — `forge test -vvv` **21/21 PASS** (3 suites) + custom Kava-Earn invariant job **C1–C6 ALL_PASS** (earlier run 38736665097 also green; 38737176580 was red on a now-removed state-dependent assertion). Log: `ci-log.txt`; artifacts: `ci-artifacts/`; results: `ci-out/`.

> Prior (corpus): "mostly stale TVL; $0–255k; no bug". **Outcome after adversarial re-test: no E-U bug found; the prior is largely confirmed, with one correction (Blueshift's "$193k" is phantom, not real) and one quantified live-but-dust path.**

## TL;DR — per target

| # | Target | Chain | Live value (on-chain) | **E-U (fresh attacker)** | Why closed / open | H-O | P / S | Coverage |
|---|---|---|---|---|---|---|---|---|
| 1 | **Kava Earn** (`x/earn`+`x/savings`+`x/liquid`+`x/incentive`+`x/router`) | Kava L1 | **≈ $1.39M** (19.93M bkava + ~$22k stables + 500,009 USDX vault) | **$0.0008** (orphan-denom dust capture) | Vault `totalValue` = savings **record** (no donation vector); floor-rounding both ways; withdraw capped by account value; module accounts can't sign; savings exactly solvent; bkava fully backed (Δ=1.38 bkava) | $1.39M | P: params/upgrades · S: unclaimed rewards expire 2026-11-01 | **fully audited** (code @ v0.28.2 + live invariants) |
| 2 | **Kava Swap** (`x/swap`) | Kava L1 | ≈ $142.6k (12 pools, all `:usdx`) | **≈ $0.37** one-shot (Osmosis USDX route, 5% fee, 473-unit depth) | Module math floors/ceils in pool's favour; swap module balance == Σ reserves; no bug. Live mispricing only in 2 dead Sifchain pools (needs OTC tokens → H-O) | $257.81 (Sif-USTC/Sif-LUNC zombie pools) | S: swp:usdx "stale" theory false · P: none | **fully audited** (code @ 686d591 + sim) |
| 3 | **SYMMIO-IOTA** (Symmio diamond) | IOTA EVM | **$2,069.00 USDT** (internal: 1,975.76 owner-attributed) | **$0.00** | All value paths `msg.sender`-scoped (AccountFacet), **LIQUIDATOR_ROLE**-gated (LiquidationFacet), PartyB-gated (Settlement), Muon-signature-bound (ForceActions); owner = TimelockController; PartyB proxy multicall role-gated; 12h withdraw cooldown; 0 positions, 0 bridge txs, dormant since 2025-05 | $1,975.76 | P: roles/timelock/ProxyAdmin | **fully audited** (facets + live state + 11 gate tests) |
| 4 | **MagicSea** | IOTA EVM | **≈ $154k** (LB $131.1k + V2 $15.2k + staking/hooks ~$7.8k) | **$0.00** | LB stack is **verbatim Trader Joe joe-v2 v2.2.0** (0 diff lines); only delta = known composition-fee fix, **measured net-negative** to exploit (minter pays the 25% protocol cut; −$1.25 … −$0.0004/op); admin paths gated | LPs/user funds (bounded fee-bypass ≤$3.40/op, attacker-negative) | P: 3 operator EOAs (factory/proxies/OFT) | **fully audited** (source diff + live state + 6 tests) |
| 5 | **Tarot Kava** | Kava EVM | **book ≈ $23.0k** (11 markets: $16.7k borrowable cash + $6.4k collateral slices) | **$0.00** | **Latent over-borrow $2,828.30** (collateral oracle books dead Vara pools at 2×reserve → R = 1.361–1.382) **blocked**: supplying the needed vTAROT collateral requires `vTAROT.mint()` → Voter masterChef `isAlive[gauge]` = **false on 10/11 markets incl. all 7 profitable** (fork-asserted revert); the one live gauge is ~50/50 → R = 0.693 → $0 | ≈ $23.0k book (lender cash + vTAROT holders) | P: **gauge revival makes $2.83k instantly live**; admin setters revert | **fully audited** (deep-dive: Sourcify sources + fork) |
| 6 | **Blueshift Kava** | Kava EVM | **≈ $0** | **$0.00** | Both portfolios **and** both LP vaults hold **zero** tokens (USDT/USDC/DAI/WKAVA/BLUES); registry's cached `totalValue` ($193,007 USDT + 1,120 WKAVA) is **phantom**; only live asset = 6,244.8 BLUES staked (unpriced) | $0 | S: LP claims on empty portfolios; DefiLlama $76.90 is stale | **fully audited** (live-state exhaustive) |
| 7 | **Steer Kava** | Kava EVM | **≈ $1,475.55** (68 vaults, 29 with assets) | **$0.00** | `poke()` is permissionless but harvests **~$0.02 dust per vault** into the vault (not to the caller); `steerCollectFees`/`emergencyBurn` revert for outsiders; roles frozen (`DEFAULT_ADMIN_ROLE` empty). NB: DefiLlama's $0 and the Steer Kava subgraph are both stale — vaults exist on-chain | ≈ $1.48k (vault share holders) | P: frozen role holders | **fully audited** |

## Total live extractable now (external unprivileged attacker)

**≈ $0.37** (Kava Swap Osmosis→Kava USDX one-shot) **+ $0.0008** (Kava Earn orphan dust) = **≈ $0.37**.
**Confidence: high** that no scalable E-U path exists; **medium-high** on the $0.37 figure (execution/slippage-dependent, depth-limited).
Latent/conditional (not counted): Tarot's $2,828.30 oracle over-borrow (live the moment a dead gauge is revived); Kava Swap stale-price capacity if cheap USDX appears at scale: $17.1k@$0.30, $70.5k@$0 (cross-refs C2-57).

Category split (all targets): **E-U ≈ $0.37** · **H-O ≈ $1.57M** (Kava Earn $1.39M + MagicSea ~$154k + Tarot book ~$23.0k + SYMMIO-IOTA $1.98k + Steer ~$1.48k + Sif pools $0.26k) · **P** (roles/timelock/governance; Tarot gauge revival) · **S** (Kava Earn claim expiry; Blueshift phantom LP claims; stranded Sifchain denoms).

## 1. Kava Earn — the only target with a proven (dust) mechanism

Full detail: `analysis/kava-earn/findings.md`. Key facts (heights 23,035,008–23,035,688; app `kava v0.28.2`, source pinned at `686d591`):

- `GetVaultTotalValue` = the strategy's estimate: SAVINGS → **earn module's x/savings deposit record** (not a bank balance); HARD → synced hard deposit. ⇒ donations/sends cannot inflate share price; nobody can mutate the module's savings record (module accounts can't sign — `MsgWithdraw.GetSigners = depositor`).
- Share math: `ConvertToShares`/`ConvertToAssets` both floor; withdraw requires `withdrawAmount ≤ ConvertToAssets(accountShares)` ⇒ no rounding gain; round trips neutral-or-loss.
- Live invariants (re-verified in CI): savings module **exactly solvent** (142 denoms, 0 diffs); every SAVINGS vault `total_value` == the module's savings record; bkava **fully backed** (supply 19,928,789.665657 vs liquid-module shares 19,928,788.282333 → Δ 1.38 bkava); earn module account empty; reward periods **empty** (`claim_end 2026-11-01`), kavadist pool 37.9M KAVA ($2.6M, shared).
- **Only E-U**: 19 `bkava-<valoper>` denoms have savings-record dust with **no vault record** (total 12,081 units = 0.0121 bkava ≈ **$0.0008**). A fresh depositor into such a denom mints 1:1 shares while `totalValue` includes the orphan dust, then withdraws `D+M` ⇒ captures `D`. Proven by code trace; value dust.
- H-O $1.39M (depositors' own shares), S: unclaimed earn rewards become unclaimable after 2026-11-01; bkava staking rewards currently uncollected while periods are empty.

## 2. Kava Swap — module clean; live value is in two dead pools

Full detail: `analysis/kava-swap/findings.md` (heights 23,035,424–38; 12 pools; `swap_fee = 0.0015`).

- All 12 pools are `<asset>:usdx`; 8 trade actively at a consistent ≈$0.70/USDX; the swap module balance **equals** Σ reserves exactly; no profitable cross-pair cycle (<$0.01); `swp:usdx` "stale" theory disproved (Osmosis pool 1631 = authoritative $0.00156).
- **Live mispricing**: two pools last traded when LUNC/USTC were 2–5× higher — `ibc/B448…(Sif-USTC):usdx` (implied USDX $0.137) and `ibc/B8AF…(Sif-LUNC):usdx` ($0.349); channel-4's client is the **dead `sifchain-1`** ⇒ the tokens are stranded on Kava, no permissionless source exists ⇒ outsiders need OTC (H-O $257.81; +$250.07 and +$7.74 legs; break-even $0.0111/USTC).
- **E-U $0.37** one-shot: buy USDX on Osmosis pool 1390 (5% fee, 473-unit depth) → sell into Kava pools.
- Module review (deployed commit): fees rounded up, exact-out ceiled, invariant asserts; no share inflation, no claim/drain path; incentive module holds 0.

## 3. SYMMIO-IOTA — role-gated, dormant, $0 E-U

Full detail: `analysis/symmio-iota/findings.md`; PoC `poc/test/SymmioIota.t.sol` (11/11).

- Diamond `0xc258535aaF6ad3cEd5D2E03e2B66C35262488309` holds **2,069.000001 USDT** (collateral = LayerZero OFT "Tether USD"). Verified facets (14), owner = **OZ TimelockController** `0xe639B85B…`; roles: admin/pauser/suspender = EOA `0x9BC9…`, **LIQUIDATOR_ROLE = 4 operator EOAs**, etc.
- Value paths: AccountFacet all `msg.sender`-scoped + 12h withdraw cooldown; liquidation **role-gated** (this deployment); `settleUpnl` PartyB-only + Muon sigs; bridge path moot (`getNextBridgeTransactionId() = 0`); PartyB proxy (`SymmioPartyB`) `_call`/`withdrawERC20` require MANAGER/TRUSTED (MANAGER = `0x9CF7…`, DEFAULT_ADMIN empty/frozen).
- Live: 8 quotes ever, 0 open positions, 0 bridge txs, no withdrawals, dormant since 2025-05; internal balances = 1,909.99 (PartyB contract) + 21.86 + 29.90 + 14.00 (PartyAs) = $1,975.76 (H-O; the PartyB contract's share needs its key-holders).
- Gate tests: withdraw/withdrawTo/allocate revert; liquidatePartyA role-gate; settleUpnl PartyB-gate; transferOwnership `LibDiamond: Must be contract owner`; PartyB `_call` `Invalid access`; deposit/withdraw round trip exactly break-even.

## 4. MagicSea — verbatim upstream LB, net-negative delta

Full detail: `analysis/magicsea/findings.md`; PoC `poc/test/MagicSea.t.sol` (6/6).

- LB money-path **byte-identical to Trader Joe joe-v2 v2.2.0** (`1297c3822f`): LBPair impl `0xbc83aea9…`, LBFactory `0x8Cce20D1…` (97 pairs, $131k), LBRouter `0x25d526bA…` — 0 diff lines across `src/**` and libs.
- One unapplied upstream fix: composition-fee denominator (`7e5b0b4944`). Measured on the live USDC.e/USDT pool: mint+burn round trips are **always net-negative** (−$1.25 / −$0.063 / −$0.0004; Y-side −$0.32 ≈ theory 316,009µ vs 316,314µ observed) — the minter pays the 25% protocol cut. LP-side leakage ≤ **$3.40/op** (attacker loses ≥$1.13) ⇒ fee-bypass/griefing, not extraction.
- V2 ($15.2k) standard; hooks rewarder claim self-only; MasterChef/staking post-audit ($6k); MLUM/LUM OFTs dormant; admin EOA-gated.

## 5–7. Kava EVM deep-dive (Tarot · Blueshift · Steer)

Full detail: `analysis/kava-evm/findings.md` (deep-dive, Sourcify sources) + `state.json`; fork tests `poc/test/KavaEvm.t.sol` (4/4).

- **Tarot Kava**: 11 markets (Avignon 9 / Orleans 2) over Tarot VaultTokens wrapping dead Vara vAMM pools, staked in Voter gauges. **Latent over-borrow**: `Collateral.getPrices()` books each side at 2×reserve, so borrow-power/collateral-value reaches **R = 1.361–1.382** on value-imbalanced pools ⇒ **$2,828.30** latent (largest: vTAROT(WKAVA/USDC) `0x109f…` = $1,544.27 off $5,817.65 USDC lender cash; then `0x2b97…` $681, `0x4938…` $422, `0xd060…` $134). **Blocked**: the only collateral-supply route `vTAROT.mint()` deposits into the Voter masterChef which requires `isAlive[gauge]` — **false on 10/11 markets, incl. all 7 profitable ones** (fork-asserted); the one live gauge market is ~50/50 → R = 0.693 → $0. Book ≈ $23.0k. **P**: a gauge revival makes $2.83k instantly live (existing cTAROT holders can already draw ~0.36× fair). Admin setters revert `UNAUTHORIZED`.
- **Blueshift Kava**: registry `getPortfolios()` cached values ($193,007 USDT + 1,120 WKAVA) are **phantom** — both portfolios **and both LP vaults** hold **zero** tokens; only live asset 6,244.8 BLUES staked in the manual pool (unpriced). E-U $0; S for stale LP claims.
- **Steer Kava**: **68 vaults (29 with assets, $1,475.55)** — DefiLlama's $0 and Steer's Kava subgraph are both stale. `poke()` is permissionless but harvests ~$0.02 dust per vault **into the vault**; `steerCollectFees`/`emergencyBurn` revert for outsiders; roles frozen (`DEFAULT_ADMIN_ROLE` empty). E-U $0.

## Method & caveats

- Fresh-attacker standard; every address/role/balance read on-chain at explicit heights/blocks (recorded in each `analysis/*/state.json`); prices from DefiLlama coins API (2026-10-15).
- Kava EVM sources were recovered via Sourcify (factories exact-match) + on-chain reads; Tarot's oracle/vault/market logic is audited at the design level, Blueshift/Steer by exhaustive live-state + gate tests.
- Kava Swap USDX has no independent price feed; "≈$0.70" is the arbitrage equilibrium of 8 actively traded pools (mint disabled, 1.43M USDX CDP debt remains — C2-57 scope).
- Fork PoCs run on public RPCs (IOTA EVM / Kava EVM) at pinned blocks; if a public RPC prunes those blocks, re-pin.
- **No secrets** were written to this folder (public CI); all endpoints in scripts are keyless.

## Files

```
kava-iota-misc/
├── README.md                    ← this file
├── summary.json                 ← machine-readable summary
├── analysis/
│   ├── kava-earn/{findings.md,state.json}
│   ├── kava-swap/{findings.md,state.json,sim.py,snapshot.py,raw/…}
│   ├── magicsea/{findings.md,state.json,lb_pairs_state.json,contracts/…}
│   ├── symmio-iota/{findings.md,state.json}
│   ├── kava-evm/{findings.md,tarot_*.json,blueshift_registry_raw.txt}
│   ├── bkava_supply.json · liquid_delegations.json · savings_solvency.json
├── poc/                         ← Foundry project (fork tests, 20/20 in CI)
│   └── test/{SymmioIota.t.sol,MagicSea.t.sol,KavaEvm.t.sol}
├── ci/{run.sh,kava_earn_check.py}   ← custom Kava-Earn invariant job (ALL_PASS)
├── ci-out/kava_earn_check.json
├── ci-log.txt · ci-artifacts/
```
