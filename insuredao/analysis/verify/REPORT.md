# InsureDAO — Phase-2 adversarial verification report (independent subagent)

**Date:** 2026-10-13 · **Role:** independent adversarial verification of the parent's headline **E-U = $0.00**
**Rules honored:** read-only on all chains (no tx, no key, no signing); only `eth_call`/`eth_getLogs`/fork simulation; no secrets or keyed URLs written anywhere; all new files live under `insuredao/analysis/verify/`.
**Question asked:** can a fresh, unprivileged attacker (no roles/keys/legacy positions; only public contracts + own capital/flash loans) extract **any** live value from InsureDAO on Ethereum v1 or the side chains? Treat the parent's conclusion as a hypothesis to falsify.

---

## 1. Independent verdict

| Target | Value at latest read | E-U by fresh attacker | Confidence |
|---|---|---|---|
| Ethereum v1 USDC vault `0x131fb74C…` | **122,292.300439 USDC** (+100 wei donation) | **$0.00** | **high** |
| Ethereum staking side (LP gauge / vlINSURE / escrow / Minter) | 0.52094149 WETH + 5,067,155.03 INSURE in the LP pair; 10.75M INSURE in InsureDepositor; 5.41M INSURE in escrow | **$0.00** | **high** |
| Arbitrum v2 vault `0x968C9718…` | 607.061566 USDC.e | **$0.00** | high (spot-checked) |
| Optimism v2 vault `0x54F23d2f…` | 232.764308 USDC | **$0.00** | high (spot-checked) |
| Astar v1 vault `0x190dA1B9…` | 548.239573 USDC | **$0.00** | high (spot-checked) |
| **Total in scope** | **≈ $123,680.37** | **$0.00** | |

**Falsification attempt failed.** I reproduced every gate independently (live `eth_call` + 14/14 fork tests of my own, not the parent's), enumerated the entire factory surface from raw events, and attacked each vector in the mission. No live path by which an unprivileged outsider ends with more value than they put in was found. Every value-out remains either holder-scoped (H-O), owner/role-gated (P), or inert.

The parent's headline stands. Several **new facts** refine (not overturn) it — see §4.

---

## 2. Live state (independently re-read, block **26,185,967**, 2026-10-13)

All reads via keyless `https://ethereum-rpc.publicnode.com` / `https://eth.drpc.org` (batch JSON-RPC, script `raw/state_read2.py` → `raw/state.json`). Fork tests at blocks 26,186,047–26,186,163.

| Claim | Call | Result |
|---|---|---|
| Vault value | `0x131fb74C….valueAll()` / `balance()` / `totalAttributions()` | `122,292,300,439` / same / same |
| Vault debt/controller | `totalDebt()` / `controller()` | `0` / `0x0` |
| USDC actually in vault | `USDC.balanceOf(vault)` | `122,292,300,539` (100 wei donation over tracked balance) |
| Attribution ledger | Σ `attributions(m)` over 29 markets + `attributions(PoolProxy)` | `122,289,085,305` + `3,215,129` = `122,292,300,434`; +5 wei dust = `totalAttributions` **exactly** |
| Market census | registry `getAllMarkets()` + factory `MarketCreated` logs | **29**: 25 PoolTemplate + 3 IndexTemplate + 1 CDSTemplate; **29 MarketCreated events, no others** |
| Template census | factory `TemplateApproval` logs (topic `0x647b650a…`, blocks 14,252,968–14,253,052) | exactly 3 ever: PoolTemplate `0x1dcd35cF` (approval, **isOpen=true**, dup=false), IndexTemplate `0x2B16Be3c` (open=false), CDSTemplate `0x99f790Ad` (open=false) |
| All markets status | `marketStatus()` / `paused()` / index `locked()` | all `0 (Trading)` / `false` / `false` |
| Claim path dead | `PoolProxy.default_reporting_admin()` + `reporting_admin(m)` ∀29 | `0x0` for all |
| Owner stack | `Parameters.getOwner()` = `PoolProxy 0xF4d046D8…` → admins = 3-of-5 Safe `0x54bE2F27…` | unchanged |
| Open template refs | `reflist(open,0,0x0)=true`, `reflist(open,1,USDC)=true`, `(2,Registry)=true`, `(3,Parameters)=true`; `conditionlist(open,0)=1e9` | attacker market must use the **real** USDC/registry/parameters and deposit ≥1,000 USDC |
| Per-pool params | `getLockup`=14 d, `getWithdrawable`=31 d, `getGrace`=14 d, `getMaxList`=10 | |
| Premium model live | `getPremium(1e6, 604800)` on pools = `191` raw; `BondingPremium 0x2D54777D…` | insurable, but claims dead |

### Premium/credit ledger of the four pools with `attributionDebt > 0` (raw units)

| Pool | rewardPerCredit | totalCredit | attributionDebt | index pendings | **unclaimable orphan** |
|---|---|---|---|---|---|
| `0x8c494310` | 1472 | 1,059,121,879 | 1,559,868 | 0xDAea = 1,559,027 | **841 wei** |
| `0x641BE011` | 236 | 1,539,121,879 | 115,714 | 0xDAea = 0, 0x7E08 = 113,280 | **2,434 wei** |
| `0xbDB009e6` | 245 | 1,681,182,639 | 346 | both = 0 | **346 wei** |
| `0x58803187` | 495 | 480,000,000 | 238,012 | 0x7E08 = 237,600 | **412 wei** |

Every index slot in every pool is occupied by an index with `credit > 0` (no evictable slot). Orphans total **4,033 wei ($0.004033)** and are unclaimable by anyone (rounding residue of `rewardPerCredit`); they slightly *reduce* LP value. No new premium can be created without a payer, and the payer gets a dead policy.

### Staking side (live)

| Item | Value |
|---|---|
| LP pair `0x1b459aec…` (WETH/INSURE) | reserves `0.520941492286142546 WETH` + `5,067,155.028348764875938328 INSURE`; totalSupply `1,582.940166580034074009` LP |
| LP gauge `0xF57882cF…` | holds `1,582.94016 LP` (all but 0.00016658); `is_killed=false`; `working_supply=717.21439…`; **`gauge_relative_weight` = 0 for the current and last week** (GaugeController `0x297ea2af…`) |
| vlINSURE gauge `0xbCBCf05F…` | holds `11,261,119.952242 vlINSURE`; `is_killed=false`; weight last week `0.8769e18`, current week `0` |
| InsureDepositor `0xA12ab76a…` | holds `10,754,075.2785 INSURE`; `lockIncentive=0`; `incentiveInsure=0`; **escrow lock ended 1,773,878,400 (2026-03-19)** |
| VotingEscrow `0x3dc07E60…` | holds `5,412,108.2864 INSURE`; `collateral_manager=0x0`; `smart_wallet_checker=0xd39E280A…`; controller = EOA `0x79F5Dc19…` |
| Minter `0x76E8B82E…` | `emergency_module=0x0`; `mint(gauge)` pays only the caller's own `integrate_fraction` |
| Staking ownership `0x56246e83…` | `owner() = 0x79F5Dc19BC96ec1DB776d39535BDe169e67E33f4` (**EOA, no code**) — privileged role over escrow/gauges/vlINSURE/Minter (P) |

---

## 3. Per-vector verdicts (each with exact evidence)

### Vector 1 — Premium/credit accounting: can a fresh index capture existing `attributionDebt`/`rewardPerCredit`? → **CONFIRMED-NO-PATH**

*Live reads* (`raw/targeted_premium.log`): the four pools above; every index slot occupied by `credit>0` (eviction requires the incumbent's `credit==0`, which implies `rewardDebt==0` and `pending==0`).
*Fork test* `test_v1_index_premium_capture_fails` (PASS): for each of `0x8c494310`, `0x641BE011`, `0xbDB009e6`, `0x58803187`:
1. attacker market `m` created via the open PoolTemplate (listed);
2. `m.registerIndex(0)` on a pool with a live index → reverts `ERROR: WITHDRAW_CREDIT_FIRST` (cannot evict);
3. `m.registerIndex(freeSlot)` + `m.allocateCredit(1e7)` → `pendingPremium(m) == 0` and `m.withdrawCredit(1e7) == 0`;
4. `attributionDebt`, `rewardPerCredit`, `vault.attributions(m)` all unchanged; `vault.attributions(INDEX_DAEA)` still owns its 1,559,027 pending.
*Why the mechanics block capture:* `allocateCredit` snapshots `rewardDebt = credit*rpc/1e6` at entry, so a fresh index earns only the **delta** from future premiums. There are no future premiums (protocol dead), and the only way to create one (`insure`) makes the attacker pay it.

### Vector 2 — Pool share math (small supplies, locked pools, `supply==0`, `worth()` edges) → **CONFIRMED-NO-PATH**

*Live-state scan:* **no market anywhere has `supply>0 && originalLiquidity==0`**, and **no market has `supply==0 && originalLiquidity>0`** (all 14 zero-supply pools have `OL==0`). The dangerous `worth()` branch (`_amount*supply`) is therefore unreachable on existing value; even if reached, a depositor *loses* (proved algebraically and by the fork test on `0x58803187`).
*Fork test* `test_v1_share_math_roundtrip` (PASS): deposit 1 USDC, request, warp 14 d + 1, withdraw-all on `0x8dfFb0c2` (supply=4), `0xC03Ab4bB` (supply=5,199), `0x58803187` (supply=0, AD>0, locked 210), `0xB0AC0465` (supply=0, credit-only), `0xB127A536` (supply=0, credit-only):
`deposited 1,000,000 → minted 1,000,000 → withdrew 1,000,000` in every case (**never more out than in**). Locked pools (`0x8c494310`, `0x641BE011`, `0x0a3f7392`) were additionally probed: withdrawal is capped by `_availableBalance = totalLiquidity - lockedAmount`, and `unlock` clears the stale locks (public good).
*Rounding direction:* every mint/payout floors and every burn ceils (`_divRoundUp`), i.e. all rounding favours the vault/remaining holders. CDS roundtrip (`test_v1_cds_roundtrip`, PASS): deposit 1,000,000 → withdraw ≤ 1,000,000. Index roundtrip (`test_v1_index_roundtrip`, PASS): minted 999,609, withdrew 999,999 ≤ 1,000,000.

### Vector 3 — `unlock(id)` + `withdraw` interaction → **CONFIRMED-NO-PATH**

*Fork test* `test_v1_unlock_public_good_only` (PASS): attacker calls `0x8c494310.unlock(0)` → `lockedAmount 11,820,670,000 → 0` (pure public good; only helps LPs withdraw their own shares). `requestWithdraw(1)` from the zero-balance attacker reverts `ERROR: REQUEST_EXCEED_BALANCE`; attacker USDC gain = 0. `unlockBatch` cannot double-decrement (`insurances[id].status` is set false). No path for a non-holder to create a withdrawal request, and `withdraw` pays `vault.withdrawValue(_retVal, msg.sender)` (LP-scoped).

### Vector 4 — Vault interactions (`repayDebt`, `offsetDebt`, `transferAttribution`, stale `valueAll`) → **CONFIRMED-NO-PATH**

*Fork tests* `test_v1_repayDebt_no_capture`, `test_v1_attacker_market_inert` (both PASS):
* `vault.totalDebt()==0` and `vault.debts(m)==0` for every market; `repayDebt(anything, target)` clamps `_amount` to `debts[target]==0` → transfers **0**, no-op; `offsetDebt` from a debtless caller/target reverts (`ERROR_REPAY_DEBT_BADCONDITIONS` / underflow).
* `transferValue` from an EOA with no attributions reverts; from the attacker's **own market** it moves exactly the market's own 1,000 USDC worth of shares to the attacker (their own deposit, no more).
* The market clone's external surface was driven from a fresh EOA (all 12 state-changing fns, try/catch): no call moved any value to the attacker beyond their own deposit; CDS attribution unchanged (`59,793,841,027`).
* `withdrawValue`/`withdrawAttribution`/`withdrawAllAttribution` from zero-attribution addresses revert/no-op; `utilize` reverts (`controller==0`); `withdrawRedundant`/`setController`/`setKeeper` revert (`Caller is not allowed to operate`).

### Vector 5 — PoolProxy `withdraw_admin_fee` / `distribute` for every token & distributor → **CONFIRMED-NO-PATH**

*Live reads* (`raw/state.json`, `raw/vaultset_events.log`): `Parameters.getVault(token)` is **only set for USDC** — WETH/DAI/USDT/INSURE/WBTC/LP all return `0x0` (calls revert). Definitive: the Parameters contract emitted **exactly one `VaultSet` event ever** (`token=USDC`, `vault=0x131fb74C…`, block 14,253,099) — there is no other vault mapping to sweep. USDC distributors: id0 “Core Dev” = Safe (weight 25%), id1 “ReportingDAO” = `0x71B6943e…` (50%), id2 “Community” = Safe (25%).
*Fork test* `test_v1_admin_fee_and_distribute` (PASS): attacker EOA calls `withdraw_admin_fee(USDC)` → exactly `3,215,129` raw (PoolProxy's own fee dust) moves into PoolProxy; `distributable` = 25/50/25%. Then `distribute(USDC,id)` for id 0,1,2 → **all three revert** (Safe fallback returns no `bool`; Aragon Govern clone has no `distribute(address)`); because the tx reverts, the temporary `safeApprove` is rolled back. Attacker USDC change = **0**; Safe change = 0. The $3.215 remains in PoolProxy, unreachable.
*Other PoolProxy entry points:* every other external fn (`add_distributor`, `set_distributor*`, `commit_set_*`, `set_reporting_admin`, all `*_set_*`, `distribute_many`, `set_distributor_kill`, …) is gated by `ownership_admin`/`parameter_admin`/`emergency_admin` = Safe; `distribute*` are EOA-only but only push to the fixed distributor set.

### Vector 6 — Staking side (InsureDepositor / gauges / VotingEscrow) → **CONFIRMED-NO-PATH**

*Fork test* `test_v1_staking_side_no_profit` (PASS) and live reads:
* **vlINSURE:** fresh attacker deposits 1 INSURE → gets exactly 1 vlINSURE; no function returns INSURE; `lockInsure()` **reverts `Cannot add to expired lock.`** (the aggregated escrow lock ended 2026-03-19 — see §4.2); `incentiveInsure=0` so even when it worked it minted nothing to the caller.
* **LP gauge:** fresh attacker deposits own LP, `user_checkpoint`, `claimable_tokens` → **0** (gauge weight is 0); `Minter.mint(LP_GAUGE)` mints exactly the caller's own claimable (`0`); `withdraw` returns their own LP. `kick(addr)` only re-checkpoints/re-caps that address's boost (no transfer); `claimable_tokens(victim)`/`user_checkpoint(victim)` credit only the victim.
* **VotingEscrow:** `withdraw()` by a non-holder is a zero-transfer no-op; `force_unlock(anyone)` reverts `only collateral manager allowed` (`collateral_manager==0`); `increase_amount`/`deposit_for` only add to (donate to) a lock.
* **Minter:** `emergency_module==0x0` → `emergency_mint` unreachable; `mint_for` needs the target's own approval.

### Vector 7 — Everything else (full external-surface sweep)

| Sub-vector | Verdict | Evidence |
|---|---|---|
| Factory surface | CONFIRMED-NO-PATH | only PoolTemplate is open (event-verified); Index/CDS `createMarket` from EOA reverts `ERROR: UNAUTHORIZED_SENDER`; refs forced to real contracts; 29/29 markets factory-created in Feb-2022 |
| Attacker market inertness | CONFIRMED-NO-PATH | `test_v1_attacker_market_inert`: `redeem`→`NO_APPLICABLE_INCIDENT`, `applyBounty`/`applyCover`/`setPaused`→owner gate, `resume`→`UNABLE_TO_RESUME`, `unlock`→bad conditions, `registerIndex`/`allocateCredit`/`withdrawCredit`/`insure` → no value to attacker |
| `IndexTemplate.adjustAlloc()` (permissionless) | CONFIRMED-NO-PATH | `test_v1_adjust_alloc_permissionless_selfclaim`: attacker calls it on all 3 live indexes; any increase in `vault.attributions` goes to **the index itself** (0xDAea +1,559,027; 0x7E08 +350,880), total attributions conserved, attacker gained 0 |
| Fake credit inflation | CONFIRMED-NO-PATH (+DoS note) | `test_v1_fake_credit_no_drain`: allocate `1e18` credit → `totalCredit` inflated, `withdrawCredit(0)` returns 0, vault balance unchanged except the attacker's own premium; at inflated TVL `BondingPremium.getPremium` **panics (division by zero)** → `insure` reverts on that pool (griefing only; no value moves) |
| CDS `compensate` | CONFIRMED-NO-PATH | EOA → `ERROR:UNREGISTERED`; only listed contracts pass the gate; the attacker's listed market can pass it only if *its own code* calls `compensate`, which PoolTemplate never does (only `_liquidation`, owner/resume-gated) |
| Index `compensate` | CONFIRMED-NO-PATH | EOA and a listed market both revert `COMPENSATE_UNAUTHORIZED_CALLER` (`allocPoints[msg.sender]==0`; only owner `set`) |
| `IndexTemplate.resume()` | CONFIRMED-NO-PATH | `locked==false` on all 3 → `ERROR: MARKET_IS_NOT_LOCKED` |
| `repayDebt` untracked-balance trick | CONFIRMED-NO-PATH | no debts exist; even with debt, repaid tokens are untracked and only owner-sweepable |
| 100-wei vault donation | CONFIRMED-NO-PATH | `USDC.balanceOf(vault) - balance == 100`; `withdrawRedundant` onlyOwner |
| INSURE pair WETH | H-O (not E-U) | pair holds 0.5209 WETH; only LP **holders/stakers** can sell INSURE into it; no free INSURE exists (`mint` minter-only, `emergency_module=0`, vlINSURE irreversible) |
| Side chains | CONFIRMED-NO-PATH | see §5 |

---

## 4. New facts that refine the parent's report (not overturn)

1. **Staking-side ownership is a separate EOA.** The vault/parameters/factory/registry `Ownership 0xf4dB9926…` is owned by PoolProxy (Safe). But the **staking** stack (escrow `0x3dc07E60`, all 31 gauges, GaugeController `0x297ea2af`, Minter, InsureDepositor `0x56246e83…`) is owned by the **EOA `0x79F5Dc19BC96ec1DB776d39535BDe169e67E33f4`** (no code), which is also `escrow.controller`. That EOA can UUPS-upgrade InsureDepositor (`_authorizeUpgrade` onlyOwner) and release/relock the 10.75M INSURE, kill gauges, or change the escrow controller — a **P** role, not attacker-reachable. The parent classified the staking side as holder-scoped/S; the privileged surface is broader than "owner upgrades" but still P.
2. **`lockInsure()` is now bricked.** The InsureDepositor's aggregated escrow lock ended `1,773,878,400` (2026-03-19); `lockInsure()` and `deposit(amount, _lock=true, …)` revert `Cannot add to expired lock.` (live `eth_call`). Only `deposit(amount, false, …)` works (irreversible). The parent's README ("lockInsure() only moves it into the 4-year lock") is outdated. No E-U consequence.
3. **LP gauge is not killed but earns nothing.** `is_killed=false`, yet `gauge_relative_weight` = 0 for the current and previous week (votes expired; controller decays weight) → `claimable_tokens` for a fresh staker is 0 and `Minter.mint` pays 0. The vlINSURE gauge's weight was 0.877 last week but is 0 this week. The parent's "no permissionless payout" conclusion holds; the precise reason is weight decay, not a kill switch.
4. **Unclaimable premium orphans:** 4,033 wei total across 4 pools (see table). Immaterial but worth noting for completeness — they are neither H-O nor P; they are simply stuck.
5. **`getPremium` panic at inflated TVL:** a fresh index can inflate `totalCredit` and make `BondingPremium.getPremium` revert (division by zero), bricking `insure` on that pool until credit is withdrawn. Griefing only (insurance is dead; no payout path), but it is a real permissionless state-bricking primitive.

---

## 5. Side-chain spot verification (independent)

Reads at latest block, keyless RPCs (`raw/sidechains.log`):

| Chain | Vault | valueAll | balance | controller / managingFund | owner | templates (approval, isOpen, dup) |
|---|---|---|---|---|---|---|
| Arbitrum | `0x968C9718…` | 607,061,566 | 0 | AaveV3Strategy `0xE5E32AD5…` / 607,061,575 (ratio 1e6) | EOA `0x2c9bC901…` | MarketTemplate `0x576e74c0` **(true,true,false)**; IndexTemplate (true,false,true); Reserve (true,false,true) |
| Optimism | `0x54F23d2f…` | 232,764,308 | 0 | AaveV3Strategy `0xDb8502A1…` / 232,764,308 | EOA `0x2c9bC901…` | MarketTemplate `0x4763f972` **(true,true,false)**; IndexTemplate (true,false,true) |
| Astar | `0x190dA1B9…` | 548,239,573 | 548,239,573 | none (`0x0`, keeper `0x0`) | EOA `0x2c9bC901…` | PoolTemplate `0x00749760` **(true,true,false)**; IndexTemplate (true,false,true) |

* **Open market templates exist on all three chains** (parent's §7 said "no permissionless payout path"; it did not stress that Arb/OP MarketTemplate is open). I verified the reference allowlist on Arb: slot1 only USDC.e (`reflist(...,1,0x0)=false`), slot2 only the real registry, slot3 only the real parameters — so an attacker clone is forced onto the honest parameters and its owner functions resolve to the owner EOA, exactly like v1. The clone's only value-moving calls (`withdraw`→LP-scoped; `redeem`→Payingout+own policy+merkle; `applyBounty`→onlyOwner; `_liquidation`→applyBounty/resume) are gated. v2 `Vault` adds `addBalance` (onlyMarketOrOwner, pulls from the caller) and `renounceAttribution` (self-burn) — neither pays the caller.
* v2 `AaveV3Strategy.adjustFund()` is permissionless but a no-op at the current 100% managing ratio (`expectUtilize == managingFund`); `immigrate(_from)` requires `managingFund()==0` (false on both chains); `emergencyExit` is onlyOwner. No unprivileged extraction.
* The $1,388 side-chain value plus the Arb/OP/Astar owner-EOA fee attributions are all **P/H-O**; a fresh attacker gets $0. I did not re-run a full per-market fork simulation on the side chains (light-touch spot verification only) — this is the one limitation of this verification.

---

## 6. Strongest near-misses (why each fails)

1. **CDS `compensate` (59,793.84 USDC pot).** Its only gate is `registry.isListed(msg.sender)`, and a fresh attacker **can** create a listed market via the open PoolTemplate. It fails only because the clone has no code path that invokes `CDS.compensate`; the sole originator is `PoolTemplate._liquidation` (owner `applyBounty` or post-`Payingout` `resume`), and no market is `Payingout`. If any listed contract exposed a public function calling `compensate`, the CDS pot would be drainable — worth flagging as latent risk.
2. **PoolProxy fee sweep.** Permissionless and real ($3.215), but it pays only PoolProxy, and all three distributor targets reject the `distribute(address)` call (revert rolls back the approval). Attacker $0.
3. **Index premium orphans (4,033 wei).** Real but unclaimable by construction.
4. **Fake-credit `insure` DoS.** Real permissionless griefing (bricks `getPremium`), but no payout path exists, so it extracts nothing.
5. **vlINSURE/escrow (10.75M + 5.41M INSURE).** The staking-side EOA owner could release/upgrade them (P); a fresh attacker cannot mint, buy, or unlock them.

---

## 7. Reproducibility / file index

* `raw/state_read2.py` → `raw/state.json` — batched live reads (markets, vault, pools, indexes, CDS, gauges, params, PoolProxy, staking). Keyless RPC.
* `raw/targeted_premium.py` → `raw/targeted_premium.log` — `rewardPerCredit`/pending premium per (pool, index).
* `raw/factory_events.log` — Blockscout log evidence: 3 `TemplateApproval` events ever, 29 `MarketCreated` events ever.
* `raw/vaultset_events.log` — Blockscout log evidence: exactly 1 `VaultSet` event ever (USDC only).
* `raw/sidechains.log` — Arb/OP/Astar vault, controller, owner, template reads.
* `raw/forge_test_final.log` — my fork suite, **14/14 PASS** (also `forge_test_run2..5.log`, `forge_dbg*.log` during debugging).
* `poc/` — my own Foundry project (`foundry.toml` uses `${FORK_RPC_URL}`, defaulting to keyless `https://ethereum-rpc.publicnode.com`; no keys stored). Tests: `poc/test/Verify.t.sol`.
  `test_v1_live_state_recheck`, `test_v1_index_premium_capture_fails`, `test_v1_share_math_roundtrip`, `test_v1_unlock_public_good_only`, `test_v1_attacker_market_inert`, `test_v1_admin_fee_and_distribute`, `test_v1_staking_side_no_profit`, `test_v1_adjust_alloc_permissionless_selfclaim`, `test_v1_fake_credit_no_drain`, `test_v1_factory_surface`, `test_v1_repayDebt_no_capture`, `test_v1_compensate_gates`, `test_v1_cds_roundtrip`, `test_v1_index_roundtrip`.
* `raw/Minter.sol`, `raw/PremiumModel.sol` — verified sources fetched from Blockscout for the two auxiliary contracts.

**Final answer to the mission:** no live extraction path found. Independent verdict: **E-U = $0.00 (high confidence)** for Ethereum v1 and the side chains, matching the parent's headline. The strongest near-miss is the CDS `compensate` path (isListed-only gate), which is unreachable solely because no listed market's code originates the call.
