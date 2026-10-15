# Liquid Driver (LQDR) — L2 Phase-2 deep dive (Fantom + BSC)

**Date:** 2026-10-15 · **Chains:** Fantom (250), BSC (56) · **Status:** read-only; fork-verified PoC only; **no mainnet transactions**.
**Blocks:** Fantom `123,693,113` (CI run 2) / `123,693,167` (local fork) · BSC `127,738,284`.
**CI:** [run 38692322831](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38692322831) (enumeration) · [run 38694548888](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38694548888) (valuation) · [run 38696616050](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38696616050) (fork PoC, see §7).

---

## 1. TL;DR

| Target | Live value in custody (nominal) | Extractable by unprivileged attacker (E-U) | Why closed | Latent risk |
|---|---|---|---|---|
| MasterChef `0x742474…` (25 pools) | LP ≈ $7,426 + 21,507 LQDR ≈ $969 | **$0** | Sushi-MCV1 accounting; `withdraw/emergencyWithdraw` are self-only; all admin fns Ownable (owner = Gnosis Safe 3/4) | Safe signer compromise (P) |
| MiniChef `0x6e2ad652…` (48 pools) | LP in 11 pools (BPT-OPERA ≈ $5.3k, rest dust) + 40,060 LQDR ≈ $1.8k | **$0** | MiniChefV2 (verified on BSC Etherscan); user accounting; `initialize` done; admin/upgrade gated | ProxyAdmin EOA `0x91e458…` (P) |
| MiniChef strategies (37) | LP staked in external farms ≈ $180k (llama) / ≈ $50k (DEX-implied) | **$0** | Pickle-style `LqdrStrategy`: `withdraw/withdrawAll` → `!depositor`; `harvest` → harvester whitelist | none found |
| Shadow farms (34) | 49.70 LP ≈ $4.90 (one farm) | **$0** | Proxy farms: all entry points revert from attacker; Ownable owner = `0x383ea1…` | ProxyAdmin EOA `0x731326…` (P) |
| Hundred chefs (4) | $0 (all empty) | $0 | MasterChefV2-style, empty | — |
| xLQDR (veLQDR) | 3,925,045.57 LQDR locked ≈ $176.9k nominal | **$0** | Curve-style voting escrow: only lockers can withdraw after expiry; admin has no fund-moving function | — |
| BSC MiniChef `0xd46db083…` (6 pools) | $0 (all empty) | $0 | verified MiniChefV2, all admin gated | ProxyAdmin (P) |
| Burner `0x05b7109b…` | 92,048.19 LQDR ≈ $4.2k | $0 | 391-byte contract with only `name()` — **funds are unrecoverable (S)** | — |

**Total live extractable now by an external unprivileged attacker: $0.00 (high confidence).**
All value is either user-owned (H-O: withdrawals gated to the depositor), admin-gated (P), or bricked (S). No permissionless function pays the caller; no theft bug found in any deployed component; every candidate path was simulated from a fresh EOA on a Fantom/BSC fork and reverts or is a zero-value no-op.

---

## 2. Architecture (per the triage row, re-verified on-chain)

Liquid Driver is a 2021-era Fantom yield farm with a Sushi-style MasterChef v1, a Sushi **MiniChefV2** (v2 farms with per-pool strategies), a set of **shadow farms** (proxy farms for partner LP tokens), four **Hundred-Finance chefs**, and a Curve-style **veLQDR voting escrow** (`xLQDR`). The DefiLlama adapter (`analysis/src/…`, recovered from `l2-triage-a/analysis/adapters/liquid-driver.js`) enumerates: MasterChef, MiniChef, 4 hundred-chefs, 34 shadow farms, xLQDR staking and Beethoven BPT resolution.

Verified deployed code (proxies resolved through the EIP-1967 implementation slot):

| Component | Address | Code | Notes |
|---|---|---|---|
| LQDR token | `0x10b620b2dbac4faa7d7ffd71da486f5d44cd86f9` | BEP20, 8,824,411.54 supply | `mint` onlyOwner = MasterChef |
| MasterChef (MCV1) | `0x742474dae70fa2ab063ab786b1fbe5704e861a0c` | 12,334 B, matches GitHub `MasterChef.sol` selector set | `lqdrPerBlock()` = **0** (emissions stopped), `totalAllocPoint` = 1e8, `startBlock` 5,682,837, `owner()` = Safe |
| MasterChef owner | `0xb1f7e2d9c20a8223e792b013bb86caf271c0b93d` | Gnosis Safe v1.3.0 | 4 owners (`0x9c16a421…`, `0x5f2481dd…`, `0x6d1cdd77…`, `0x383ea123…`), **threshold 3** |
| MiniChef (FTM) | `0x6e2ad6527901c9664f016466b8da1357a004db0f` | TransparentUpgradeableProxy (1,581 B) → impl `0x4b7e4f46…` (14,481 B) | `poolLength` 48; strategies on 37 pools; proxy admin `0xe71e06e5…` (owner `0x91e458fc…`) |
| MiniChef (BSC) | `0xd46db083de31c64af3f680f139a31ff37bac004f` | proxy → impl `0x929c697c…` = **verified `MiniChefV2` on BSC Etherscan** | 6 pools, all empty |
| Shadow farms ×34 | e.g. `0x59ab3c33…`, `0x0f45b4a8…` | proxies → 4 impls (`0x141001cc…`, `0xae628e8d…`, `0x825dcfc3…`, `0x9e4e1516…`) | `lpToken()`, `strategy()`, `withdraw(uint256)`, `withdrawAll()`, `deposit()`; `owner()` = `0x383ea123…`; proxy admin `0x731326a2…` |
| Hundred chefs ×4 | `0x79364e45…`, `0x9a07fb10…`, `0xed566b08…`, `0x669f5f28…` | proxies → impl `0x8d8a40da…` (14,960 B) | MCV2-style; all balances 0 |
| xLQDR (veLQDR) | `0x3ae658656d1c526144db371faef2fff7170654ee` | Vyper voting escrow (11,611 B) matching `xLQDR-model/contracts/veLQDR.vy` | `supply` 3,925,045.57; voting power 708,093.68; `admin()`/`controller()` = `0x383ea123…` |
| Strategies ×37 | e.g. `0x2623e2b5…` | Pickle-style `LqdrStrategy` (4,752 B) | `depositor()` = MiniChef; `harvesters()` whitelist; farms in external masterchefs `0x18b4f774…`, `0xaef349e1…`, `0x9083ea37…`, `0x37cf4902…` |
| Burner | `0x05b7109b2dae299d882c410c1a281fc194658e89` | 391 B, only `name()` | holds 92,048.19 LQDR; **no transfer function — stuck** |
| Fee recipient / dev | `0x3ac76a44…` (42.1 FTM), `0x3cde01de…` (32.4 FTM) | EOAs | deposit-fee / dev addresses (small FTM balances, not custody) |

Sources: `analysis/live-state.json`, `analysis/probe2.json`, `analysis/probe3.json`, `analysis/impl-map.json` (all read-only `eth_call`/`eth_getCode` at the stated blocks). The MasterChef source is the public `LiquidDriver-finance/liquiddriver-contracts` repo; the BSC MiniChef implementation source was pulled from BSC Etherscan (chainid 56) and matches the FTM behaviour (`BoringERC20` revert strings, same selectors).

---

## 3. Live-state assessment (what is actually there)

Read at Fantom `123,693,113` / BSC `127,738,284` (2026-10-15), keyed to `ci-artifacts/result-liquid-driver/ci-out/live-state.json` + `valuation.json`:

* **MasterChef**: 16 of 25 pools hold LP (largest: pid 2, 717.70 LP = 23.4 % of that pool ≈ $5.7k at DefiLlama prices). LQDR balance 21,507.45 (reward reserve for stakers). Native FTM 0. `lqdrPerBlock = 0` → no further emissions.
* **MiniChef (FTM)**: 11 of 48 pools hold LP directly; the only material one is `pid 32` = 101,248.59 **FTM-OPERA BPT** (42.77 % of a pool holding 230,169.2 WFTM ≈ $5.3k); the rest are dummy/BPT dust. LQDR balance 40,059.85. 37 pools delegate LP to strategies.
* **Strategies**: LP is staked in external masterchefs/gauges; `balanceOf()` values (e.g. 188,794 LP on one strategy) total ≈ $180.5k at DefiLlama prices, ≈ $50.2k at DEX-implied prices (several underlyings are de-pegged bridged assets, e.g. Fantom LINK at $0.17 vs $12 mainnet).
* **Shadow farms**: only `0x59ab3c33e75C91B2B632d51144e57293EF64E556` is funded — 49.696 LP of the LQDR/FTM pair `0xe42bb367…` (pool TVL ≈ $4.9k) ≈ **$4.90**; the other 33 are empty.
* **Hundred chefs**: `strategyBalance` and `farmBalance` = 0 in all four.
* **xLQDR**: `supply` = 3,925,045.57 LQDR locked; LQDR balance = 3,925,057.25 (≈ supply, no shortfall). Voting power decays (708,093).
* **Burner**: 92,048.19 LQDR.
* **BSC**: 6 MiniChef pools, all zero; no other funded LD contract found (xLQDR-equivalent on BSC not funded).
* **Rewarders**: `rewarder(1) = rewarder(10) = 0x211413eb…` (a MiniChefV2-style secondary rewarder, owner `0x383ea1…`, holds **9,746.68 WFTM** ≈ $526 — pending WFTM rewards for those pools' stakers; all entry points revert from a fresh EOA), `rewarder(21) = 0x6fd9a46a…` (owner `0x383ea1…`, holds 0 LQDR/WFTM/BOO/USDC).

**Valuation caveat (important):** Fantom exit liquidity is broken/thin. The deepest LQDR/FTM pair (`0x506ddcc7…`) holds only 18,669 WFTM + 22,005 LQDR (LP supply 14,715). A constant-product dump of the *entire* 3.9M locked LQDR yields only 18,565 WFTM (≈ $1.0k at $0.054/WFTM; ≈ $0.2k at DEX-implied $0.0096). Nominal USD values below therefore overstate recoverable value by an order of magnitude or more.

---

## 4. Attack-surface audit — what an unprivileged attacker can/cannot do

All calls below were executed as `eth_call` from a fresh address `0x1111…1111` (and `vm.prank` on fork) — never a transaction. Raw evidence: `analysis/probe3.json`, `analysis/probe_minichef_strategies.py` output, `ci-out/fingerprints.json`.

| Call path | Result from attacker | Gating check (live value) |
|---|---|---|
| `MasterChef.withdraw(pid, 1)` | revert `withdraw: not good` | `userInfo[pid][atk].amount = 0` |
| `MasterChef.emergencyWithdraw(pid)` | succeeds, transfers 0 | `user.amount = 0` |
| `MasterChef.pendingLqdr(pid, atk)` | 0 | — |
| `MasterChef.add/set/updateEmissionRate/transferOwnership` | revert `Ownable: caller is not the owner` | owner = Safe (3-of-4) |
| `MasterChef.dev/setFeeAddress` | revert `dev: wut?` / `setFeeAddress: FORBIDDEN` | dev/fee EOAs |
| `MasterChef.mint(atk, 1e18)` | revert (no such function; `0x40c10f19` in bytecode is the embedded `lqdr.mint` call constant) | LQDR `mint` onlyOwner |
| `MiniChef.withdraw(pid, 1, atk)` / `withdrawAndHarvest` | revert `SafeMath: subtraction overflow` | user accounting (verified MiniChefV2) |
| `MiniChef.harvest(pid, atk)` | succeeds, pays 0 | pending = 0 |
| `MiniChef.emergencyWithdraw(pid, atk)` | succeeds, transfers 0 | user.amount = 0 |
| `MiniChef.initialize(atk,atk,atk)` | revert `Initializable: contract is already initialized` | initialized |
| `MiniChef.setLqdrPerSecond/setFeeAddress/setTreasuryAddress` | revert (`FORBIDDEN`) | owner/fee/treasury gated |
| `MiniChef.upgradeTo/upgradeToAndCall` | revert | TransparentUpgradeableProxy admin `0xe71e06e5…` |
| `Strategy.withdraw(0)` / `withdrawAll()` | revert `!depositor` | `depositor()` = MiniChef |
| `Strategy.harvest()` | revert | `harvesters(atk) = false` |
| `Strategy.deposit()` | succeeds but deposits the strategy's own `want` (0 idle) into its farm — no gain to caller | — |
| Shadow farm `withdraw(0/1)`, `withdrawAll()`, `deposit()`, `harvest()`, `emergencyWithdraw()` | **all revert** | farm-level accounting + owner gating |
| Shadow farm `setStrategy/transferOwnership` | revert `Ownable` | owner = `0x383ea123…` |
| Shadow/hundred `upgradeTo` | revert | ProxyAdmin `0x731326a2…` / `0xa8187f8f…` |
| xLQDR `withdraw()` (no lock) | succeeds as **zero-value no-op** (delta 0) | `locked(atk).amount = 0`, `end = 0` |
| xLQDR `deposit_for(atk, 1)` | revert `No existing lock found` | — |
| BSC MiniChef `withdraw(pid,1,atk)` | revert | same MiniChefV2 logic |
| BSC MiniChef `setLqdrPerSecond/initialize/upgradeTo` | revert | owner / initialized / proxy admin |
| Rewarder `0x211413eb…` (holds 9,746.68 WFTM) `harvest/withdraw/emergencyWithdraw` | revert | owner `0x383ea123…`; fresh-address `userInfo = 0` |

**Conclusion:** there is no permissionless value-moving path. The only permissionless functions (`harvest`, `updatePool`, `massUpdatePools`, `massHarvestFromStrategies`, strategy `deposit`) either pay the caller their own pending rewards (zero for a fresh address) or move the contract's own idle funds into its farm. No re-entrancy or accounting bug was found in the deployed MasterChef/MiniChefV2 (both match their published/verified sources and use effects-before-interactions), and the strategy pattern is the standard Pickle design with a hard `!depositor` check.

---

## 5. PoC / fork verification

`poc/` (Foundry; vendored forge-std): `test/LiquidDriver.t.sol` (Fantom fork) and `test/LiquidDriverBSC.t.sol` (BSC fork). Each attacker attempt runs with `vm.prank(0x…DeaDBeef)` against the live fork and asserts either a revert or zero delta. Tests (see CI run 3):

| Test | What it proves |
|---|---|
| `test_masterchef_state` | 25 pools, `lqdrPerBlock = 0`, LQDR held; logs all LP balances |
| `test_masterchef_foreign_withdraw_reverts` | foreign `withdraw(1)` reverts in **all 25 pools**; `emergencyWithdraw` transfers 0; `pendingLqdr = 0` |
| `test_minichef_foreign_withdraw_reverts` | foreign `withdraw(pid,1,atk)` reverts in **all 48 pools**; `harvest` pays 0 |
| `test_strategy_gated` | `withdraw(0)` → `!depositor`, `harvest` → revert, `withdrawAll` → revert on **every** Pickle-style strategy |
| `test_proxy_admins_not_attacker` | EIP-1967 admin slots set and ≠ attacker; `upgradeTo` from attacker reverts |
| `test_shadow_farm_foreign_withdraw` | all withdrawal entry points on the funded shadow farm fail; attacker LP balance unchanged |
| `test_xlqdr_state_and_foreign_withdraw` | escrow holds 3.925M LQDR; lockless `withdraw()` = no-op; `deposit_for` on lockless address reverts |
| `test_lqdr_exit_liquidity` | constant-product ceiling: dumping all locked LQDR into the deepest pair yields ≤ 18,565 WFTM |
| `test_attacker_portfolio_no_increase` | after every permissionless call across MasterChef/MiniChef, attacker's LQDR/WFTM/USDC/BOO/LP balances are unchanged |
| `test_bsc_minichef_empty_and_gated`, `test_bsc_attack_surface` | BSC: all pools empty; foreign withdraw and admin calls revert |

Local: `test_xlqdr_state_and_foreign_withdraw` + `test_lqdr_exit_liquidity` PASS (fork 123,693,167). Full suite: CI run 3 (link above), log in `ci-log.txt`, artifacts in `ci-artifacts/`.

Gas/cost: the tested attack paths revert before any transfer, so there is no gas/loan arithmetic to report — net extraction is $0 with any capital or flash loan.

---

## 6. Verdict and residual risk

* **E-U (external unprivileged extractable): $0.00 — high confidence.** Every value-moving entry point on every deployed contract is gated to the depositor/owner; all tested attacker paths revert or are zero-value no-ops; the two reward/accounting engines (MasterChef v1, MiniChefV2) match published/verified sources.
* **H-O (user-recoverable, nominal): ≈ $373k** — xLQDR lockers $176.9k; MiniChef strategies' LP $180.5k; MasterChef LP+LQDR $8.4k; MiniChef BPT/LQDR ≈ $7.2k; shadow farm $4.90. **Realizable is a small fraction**: LQDR exit liquidity is ≈ $3-9k total across pairs; the bridged tokens in the LP (LINK, miMATIC, FRAX, WBTC) trade at heavy discounts on Fantom. DEX-implied LP value is ≈ $50k, and the xLQDR position's dump ceiling is ≈ $0.2-1.0k (constant product).
* **P (privileged):** MasterChef owner = Gnosis Safe 3-of-4; MiniChef/shadow/hundred proxy admins are EOAs (`0x91e458…`, `0x731326…`, `0xa8187f8f…` owned by `0x383ea123…`); xLQDR admin = `0x383ea123…`. These can upgrade implementations / change parameters but **cannot directly withdraw user funds** from the current implementations. Key compromise of these EOAs is the main residual risk (upgrade-to-malicious-impl scenario) — out of scope for the unprivileged standard.
* **S (stuck):** Burner `0x05b7109b…` holds 92,048.19 LQDR (≈ $4.2k nominal) with no transfer function — permanently unrecoverable; dummy "NTOKEN/Dummy/XXX" pool tokens; any LQDR left in the MasterChef beyond staker pending rewards is unrescuable (no rescue function).
* **Residual unknowns:** (1) qLQDR/mxLQDR/liHND vault addresses (marketed on the project site) could not be located from public sources — if they hold value, they were not covered by the adapter and were not audited here; (2) the deployed FTM MiniChef implementation `0x4b7e4f46…` is unverified (its selector set matches MiniChefV2 plus `lqdrPerBlock`, and all probed behaviours match the verified BSC implementation); (3) user-level pending rewards (LQDR) were not enumerated per-user.

---

## 7. Methodology, sources, files

**Method.** Re-verified the triage row on-chain: enumerated all adapter addresses (MasterChef, MiniChef ×2, 34 shadow farms, 4 hundred chefs, xLQDR, BPTs), resolved every EIP-1967 proxy implementation and proxy-admin slot, extracted function selectors/strings from unverified bytecode, pulled verified sources where available (BSC Etherscan; GitHub `liquiddriver-contracts`, `xLQDR-model`, pickle-finance ABI), then simulated every attacker path with `eth_call` from a fresh EOA and with Foundry fork tests (`vm.prank`). Values priced with DefiLlama and cross-checked with DexScreener-implied prices; BPTs resolved via the Beethoven X vault.

**Sources.** `l2-triage-a/summary.json` (row 48); DefiLlama adapter `liquid-driver.js`; GitHub `LiquidDriver-finance/liquiddriver-contracts` (MasterChef/MasterChefV2/LqdrToken/Burner/Timelock), `LiquidDriver-finance/xLQDR-model` (veLQDR.vy), `pickle-finance/pf-core` (LqdrStrategy ABI); BSC Etherscan V2 (MiniChefV2 source); on-chain reads.

**Files.** `analysis/` (fetch_state.py, probe2.py, probe3.py, resolve_impls.py, fingerprint.py, valuation.py, valuation_dex.py, `live-state.json`, `probe2/3.json`, `impl-map.json`, `selectors.json`, `valuation-dex.json`, `src/`), `poc/` (Foundry project + tests), `ci/` (enumerate.py, fingerprint.py, valuation.py, run.sh), `ci-out/` (CI artifacts), `ci-log.txt`, `ci-artifacts/`.

**Caveats.** Public RPCs only (keyless); a few reads were retried and one CI fingerprint batch returned provider errors for `from`-address simulations (superseded by the Foundry fork tests, which are authoritative). USD values are nominal at 2026-10-15 prices; treat them as an upper bound on realizable value.
