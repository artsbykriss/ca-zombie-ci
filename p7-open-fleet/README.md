# ZH4-PASS7 · O3 — Lazy Summer / FleetCommander "Ark" class + BSC-router re-probe

**Date:** 2026-10-26 · **Campaign:** ZH4 pass 7 · **Finding:** O3 (open) + PRIOR-PARTIAL (BSC router)
**Mode:** READ-ONLY. No transaction was signed or sent on any live network. Fork-only PoCs. No secrets in this folder.
**Chains:** Ethereum (1) · Base (8453) · Arbitrum (42161) · Sonic (146) · HyperEVM (999) · BSC (56)

> Status line: read-only; PoC fork-verified only; no mainnet transactions. Nothing here is an instruction to transact.

---

## 0. TL;DR

| Target | Live extractable (unprivileged) | Why closed / open | Latent risk |
|---|---|---|---|
| **O3 — FleetCommander "capped-Ark NAV donation" class (Summer.fi)** | **$0.00** (dust; theoretical ceiling ≈ **$750** on one Arbitrum fleet, unreachable) | The class precondition (**an Ark with `depositCap()==0` still in `getActiveArks()`**) survives on 6 fleets, but in **5 of 6 the capped Ark is empty** (`totalAssets()==0`); only **Arbitrum LR-USDC** has a capped **and funded** Ark ($500.79), inside a $1,251.17 fleet (≤$750.01 withdrawable). Decisively, **fleet-level `depositCap==0` on every fleet → deposits are closed**, so the deposit leg cannot be assembled. All other fleets have had their Arks removed (assets sit in the buffer). Fork-verified (4/4). | **MED** — immutable FleetCommander code; the fix is *operational* (Ark removal + caps at 0), so re-opening deposits or adding a mispriced/impairment-prone Ark re-arms it. |
| **PRIOR-PARTIAL — BSC DEX router `0xa331fde0…` (impl upgraded to `0xc700cf8d…`)** | **$0.00** today | **Mechanism FIXED** — the upgraded callback `TLOAD`s an EIP-1153 transient pool slot and binds the `transferFrom` payer to the router's own swap-context caller (not caller-supplied `data`); live `eth_call` reverts `SwapX: Invalid pool`; fork probe drains 0; 0 standing approvals for `spender = router`. | **LOW–MED** — re-arms only on a new impl upgrade by owner `0x2803E636…` reintroducing a data-supplied payer |

**Total live extractable now: $0.00** (confidence **HIGH** that the class yields no material unprivileged extraction today; the largest surviving TVL in the entire protocol is a *fairly-priced* buffer/ark position, not a donation target).

---

## 1. The bug / mechanism in exact terms

Summer.fi "Lazy Summer Protocol" vaults are **ERC-4626-style** vaults called **Fleets**, each managed by a
`FleetCommander` contract above a set of strategy adapters called **Arks** (`core-contracts/FleetCommander.sol`,
repo `OasisDEX/summer-earn-protocol`).

* **Share price** is computed from `totalAssets()` = **Σ over `getActiveArks()` of `ark.totalAssets()`** (the buffer is one such Ark).
* An Ark's `totalAssets()` **credits any ERC-20 transferred directly to the Ark address** at the Ark's own valuation — a
  plain `transfer()` mints no Fleet shares and adds no real liquidity, yet raises NAV.
* A **capped-for-offboarding** Ark is one whose per-Ark `depositCap` was set to `0` (via `setArkDepositCap`) but which
  was **not removed** from the active set (`removeArk` was never executed). It stays in `getActiveArks()`, keeps
  contributing to `totalAssets()`, and stays donatable.

**Exploit (2026-07-06, block 25,471,348, tx `0x0db528c4…da12`, ≈$6.04M):** the attacker pre-acquired impaired
Silo "Varlamore USDC Growth" shares cheaply, deposited ~64.83M USDC into LowerRisk USDC at the honest PPS (~1.0665),
**donated** the stale-valued Varlamore shares straight into the still-active capped Ark (NAV +≈9.5% → PPS ≈1.1677),
then **redeemed** at the inflated price. The payout came from the buffer and *other* liquid Arks — never from the
manipulated one. A reciprocal Term/LowerRisk path took a second ~$0.40M from HigherRisk USDC.

**The critical, non-obvious requirement:** profit needs an Ark that credits a **mispriced** token above its acquisition
cost. A donation into a *fairly-priced* Ark is break-even at best (`profit = f·V − cost(V) < 0`). So the operative screen
is: **Ark active ∧ `depositCap()==0` ∧ Ark `totalAssets()>0` ∧ underlying mispriced**. The 2026 fix removed the 18
legacy Arks on the Ethereum fleets and unpaused the vaults (2026-07-30).

Deployed code is **immutable** (no EIP-1967 slot, no `upgradeTo`/`proxiableUUID` in the verified ABI; code = 24,544 B
and identical across ETH/Base/Arbitrum) → **the class cannot be patched in code; it is closed only operationally.**

---

## 2. Live-state assessment (read-only, 2026-10-26)

Blocks: **Ethereum 26,272,098 · Base 53,085,674 · Arbitrum 518,241,570 · Sonic 81,616,428 · HyperEVM 49,515,699.**

### 2.1 Enumeration method (exhaustive)
1. **On-chain registry:** `HarborCommand.getActiveFleetCommanders()` per chain (ETH/Base/Arb `0x09eb323d…`,
   Sonic `0xa8E4716a…`, HyperEVM `0x5CD5D7e3…`) + the `FleetCommanderEnlisted`/`Decommissioned` event log (Etherscan V2) —
   the enlisted set equals the live set on every chain (0 decommissions).
2. **Deployment registry:** every `#FleetCommander` / `#FleetCommanderDao` key in the repo's per-chain Ignition
   `deployed_addresses.json` (ETH/Base/Arb/Sonic/HyperEVM) — this surfaces fleets **not** in HarborCommand.
3. **Institutional fleets:** the 9 institution `HarborCommand`s (ExtDemoCorp, WisdomTree, Avantgarde, Orthodox, Targen).
4. **Fork surface:** GitHub code search for other EVM `FleetCommander` deployments → **none** (all hits are
   unrelated: games, AccelByte SDKs, etc.). DefiLlama "Lazy Summer Protocol" lists the same 5 chains.

**Monad (chainId 143) is a zero-address placeholder in the repo config — not deployed.** Sepolia is testnet.

### 2.2 Every live fleet (all 5 chains + institution + legacy)

Legend: `ta` = `totalAssets()` (raw / USD), `arks` = `getActiveArks().length`, **cap0** = active Arks with `depositCap()==0`
(count / how many of those are **funded**, i.e. `ark.totalAssets()>0`).

| Chain | Fleet | Address | paused | TVL (USD) | arks | cap0 (funded) |
|---|---|---|---|---|---|---|
| ETH | LR-USDC *(exploited 07-06)* | `0x98C49e13…eCf17` | no | **$0** (ta 0) | 10 | 0 |
| ETH | LR-USDT | `0x17Ee2D03…54AD8d` | no | $10,761.44 | 0 | – |
| ETH | LR-WETH | `0x67e53679…0aB506` | no | $76,608.12 (32.90 WETH) | 0 | – |
| ETH | HR-WETH | `0x2E6abcbc…A88e10` | no | $51,140.98 (21.96 WETH) | 0 | – |
| ETH | HR-USDC | `0xE9cDA459…70cB06` | **yes** | $0 | 5 | 1 (0) |
| ETH | DAO-WETH | `0x0C1FBCCC…632114` | no | $80,756.84 (34.68 WETH) | 0 | – |
| ETH | DAO-USDC | `0xd77F9a9F…0C76fc` | no | $11.63 | 0 | – |
| ETH | Bummer-LR-USDC | `0x8360E822…1187D` | no | $27.56 | 8 | 0 |
| ETH | Bummer-LR-WETH | `0x40e9C802…55651` | no | $23.70 (0.0102 WETH) | 9 | **5 (0)** |
| ETH | ExtDemo (whitelist) | `0x80153d7b…43BF` | no | $21.17 | 3 | 0 |
| Base | LR-USDC | `0x98C49e13…eCf17` | no | **$83,976.83** | 0 | – |
| Base | LR-EURC | `0x64Db8f51…8E0f0` | no | $8,596.29 (7,669.28 EURC) | 0 | – |
| Base | LR-WETH | `0x2bb9ad69…834af` | no | $48,906.82 (21.00 WETH) | 0 | – |
| Base | Bummer-LR-USDC | `0xf762b4E9…3A4d9` | no | $0 (**`totalAssets()` reverts** `Aera__VaultPaused`) | 5 | 1 (0) |
| Base | ExtDemo | `0x1dB644c6…1df5C` | no | $28.67 | 7 | 0 |
| Base | WisdomTree | `0x9FD22516…9cEC` | no | $15.00 | 2 | 0 |
| Base | v2b | `0xB5A07af4…76B73` | no | $28.05 | 1 | 0 |
| **Arb** | **LR-USDC** | **`0x4F63cfEa…4bb58`** | no | **$1,251.17** | **5** | **1 (1)** ← **only live target** |
| Arb | LR-USDT | `0x98C49e13…eCf17` | no | $6,561.91 | 0 | – |
| Arb | LR-USDC-2 | `0x71d77C39…7cf58A` | no | $436.11 | 0 | – |
| Arb | Bummer-LR-USDT | `0x45342A8a…e7cae` | no | $1.00 | 4 | 3 (0) |
| Arb | TarFi (whitelist) | `0x6e23CfE8…FDBEb` | no | $431.52 | 4 | **3 (0)** |
| Arb | ExtDemo (whitelist) | `0x2D55c68e…f50aD` | no | $6.47 | 5 | 0 |
| Sonic | LR-USDCe | `0x507A2D9E…64f8` | no | $7,236.58 | 0 | – |
| Hyper | LR-USDC | `0x252E5Aa4…232Ba` | no | $7,204.56 | 0 | – |
| Hyper | LR-USDT | `0x2cC190fb…4D346` | no | $1,047.14 | 0 | – |

*(Remaining fleets with ~$0 TVL and empty Arks — BummerDAO on ETH, ExtDemo3a/3b/v2a on Base, Avantgarde/Orthodox on ETH, `0x015e60a0`/`0x26ce1915` on HyperEVM — omitted for brevity; full machine-readable data in `analysis/census/census.json`.)*

**Reading:** the protocol still holds ≈**$384k** of live TVL (largest single position: Base LR-USDC $83,976.83), but it
sits in **buffers** (donation = break-even, no Ark involved) or in **fairly-priced, non-capped Arks**. The
donation-class precondition (**capped ∧ funded** Ark) exists on exactly **one** fleet. Institution/legacy
"Bummer"/DAO fleets hold only tens of dollars.

### 2.3 The single live target — Arbitrum LR-USDC `0x4F63cfEa7458221CB3a0EEE2F31F7424Ad34bb58`

Asset USDC `0xaf88d065…5831`; `paused()==false`; `totalAssets()==1,250,799,763` (**$1,250.80**);
`totalSupply()==1,272,590,566,944` (1,272,590.57 shares → **PPS ≈ $0.000983** — deeply loss-socialised);
`withdrawableTotalAssets()==750,014,163` (**$750.01**).

| Ark | name | `depositCap` | `totalAssets` |
|---|---|---|---|
| `0x64e3d757…49461` | AaveV3-usdc-42161 | 9.5e11 | 0 |
| `0x7BB4536e…66151e` | CompoundV3-usdc-42161 | 7.1e12 | 0 |
| **`0x125dAE47…8783C`** | **SiloManagedVault-varlamore-usdc-42161** | **0 (capped)** | **500,788,753 ($500.79)** |
| `0x52536000…135ad` | MorphoVault-usdc-Gauntlet_USDC_Prime-42161 | 2.87e12 | 0 |
| `0x4EF91E09…03b74` | ERC4626-Sky_sUSDC-usdc-42161 | 5.4e13 | 335,121,321 ($335.12) |

Buffer `0xbb79242B9518F450cDe8eb957E15c38ab09B1419` holds $414.89. This is **the exact July-6 shape**: a
capped-for-offboarding Ark (the *same impaired Varlamore family*, on Arbitrum) still counted in NAV.

**Why it is still ~$0.** (i) The governed fix (`SIP2.60.2`, executed **2026-08-12**, Base→LayerZero→Arb) removed **12**
Arks from the three Arbitrum fleets — but **explicitly did NOT include the Varlamore Ark**, which is the one that
remains. (ii) The fleet is a **husk**: NAV $1,250.8 and only **$750.01 withdrawable**; the capped Ark holds just $500.79.
The classic drain's payout is bounded by *other* liquidity ($750), while capturing it requires depositing an amount
comparable to the fleet's own NAV. See §4 for the fork result.

### 2.4 Other capped-Ark fleets (all inert — capped Ark is EMPTY)
* **Arb TarFi `0x6e23CfE8…`** ($431.52): 3 capped Arks
  (Aave/Compound/Morpho-Gauntlet-Core) but **all `totalAssets()==0`**; the funded Ark (Sky sUSDC, $431.5k) is non-capped
  and fairly priced → no donation target.
* **ETH HR-USDC `0xE9cDA459…`**: 1 capped Ark (Term, empty); fleet **paused** + `totalAssets()==0`.
* **ETH Bummer-LR-WETH `0x40e9C802…`**: 5 capped Arks, all empty; TVL $25.
* **Arb Bummer-LR-USDT `0x45342A8a…`**: 3 capped Arks, all empty; TVL $1.
* **Base Bummer-LR-USDC `0xf762b4E9…`**: 1 capped Ark (empty); **`totalAssets()` reverts `Aera__VaultPaused`**
  (one Ark's external Aera vault is paused) → the whole fleet's NAV/redeem path reverts → ~$1.03 is **bricked (S)**.

---

## 3. What an attacker can/cannot do

**Can (permissionless):** `redeem` / `withdraw` (if you already hold shares), and a raw `ERC20.transfer` of any token
to any Ark address. No role is needed to donate or to redeem.

**Cannot — the deposit leg is closed.** `FleetCommander.getConfig().depositCap == 0` on **every** fleet
(verified live: ETH/Base/Arb LR-USDC + Arb LR-USDT), because the post-incident response capped every vault to zero
and the 2026-07-30 unpause left the caps at 0 (wind-down = withdrawals only). `maxDeposit(attacker) = min(depositCap −
totalAssets, asset.balanceOf(attacker)) = 0`, so an attacker **cannot mint fleet shares**. The donation-inflation
exploit *requires* first acquiring shares cheaply (then redeeming them dear); with the mint closed and no secondary
market for the fleet shares, the attack cannot even be assembled. Also cannot: add/remove Arks, change caps, unpause
(all `CURATOR_ROLE`/`SUPER_KEEPER_ROLE`/governance-gated).

**Profit condition:** `f·(NAV + V_credited) − D − cost(V) > 0`, where `f` = attacker's share fraction (bought with
deposit `D` at the pre-donation PPS), `V_credited` = value the Ark credits for the donated tokens, `cost(V)` = market
cost of acquiring them. On a *fairly-priced* Ark `V_credited ≈ cost(V)` → loss. Profit therefore requires (a) the
ability to obtain fleet shares, (b) a **mispriced** Ark asset obtainable *below* the NAV the Ark credits, **and**
(c) enough *other* liquidity to pay the inflated redemption.

Applied to the only funded capped Ark (Arb LR-USDC, §2.3): (a) fails (`depositCap==0`); (b) fails (the ark's share
token is mintable only at NAV, `vault.maxWithdraw(ark)==0`, no market); (c) the payout ceiling is
`withdrawableTotalAssets = $750.01`. Net is **≤ $0** — fork-verified (§4).

---

## 4. PoC / fork-verification

`poc/` — Foundry harness (`forge-std` vendored), **4/4 tests PASS** (local run ~88 s; CI run URL in §8).

**Test 1 — `Exploit_Repro.t.sol::test_donationInflation_sensitivity`** (Ethereum fork @ **25,471,347**, one block
before the exploit). Donating `5e15` vgUSDC directly to the Silo Varlamore Ark `0x61d70630…`:

| quantity | before | after |
|---|---|---|
| `ark.totalAssets()` | 0 | **1,821,149,917,443** |
| fleet `totalAssets()` | 9,680,827,973,743 | 11,501,977,911,186 |
| fleet PPS (per 1e6 shares) | 1,066,484 ($1.0665) | **1,267,110 ($1.2671)** |
| fleet `withdrawableTotalAssets()` | 1,605,240,564,038 | **unchanged** |
| `vault.maxWithdraw(ark)` | 0 | **0** |

→ donation raises quoted NAV/PPS by *exactly* the credited value while **realisable liquidity does not move** — the
mechanism, reproduced.

**Test 2 — `Exploit_Repro.t.sol::test_simplified_profit_replay`**: deposit $50,000 → donate the executor's
`1.9075e16` vgUSDC (credited **$6.948M**) → redeem → **net +$35,712.26** (scaled replay; isolates the
deposit→donate→redeem core — the attacker's ~5.3k-node acquisition leg is not replayed).

**Test 3/4 — `Generic_Donation.t.sol`**: parameterised engine. Self-test on the Ethereum fleet reproduces
+$35,712.26; **`test_generic_arbitrum_live_candidate`** on the live P7-O3 candidate (Arbitrum fork @ 518,241,570):
donating `1e21` Silo shares credits `1,861,451` raw (=$1.86), NAV `1,250,795,250 → 1,252,656,701`, `withdrawableTotalAssets`
stays `750,014,057` → **asserts net = $0**, because (a) `fleet.maxDeposit(attacker)==0` (fleet `depositCap==0`, deposits
closed — independently re-verified in §3) and (b) the ark share token is mintable only at NAV (`vault.maxWithdraw(ark)==0`)
with no secondary market. Ceiling *if both were met* = `withdrawableTotalAssets` = **$750.014057**.
See `poc/README.md` for the full tables.

**Negative controls:** donation into a **fairly-priced** Ark is break-even; donation into an **empty** capped Ark
credits fair value only; the only depeg-prone legacy asset (OUSD) trades at $0.998.

**CI:** `ci/run.sh` selects archive-capable RPCs (the workflow's `eth_blockNumber` probe otherwise picks a
non-archive publicnode), runs `forge test -vvv`, writes `ci-out/`. GitHub Actions `artsbykriss/ca-zombie-ci`,
branch `p7-open-fleet` — run URL in §8.

---

## 5. PRIOR-PARTIAL re-probe — BSC DEX router `0xa331fde028e6F17425AB9333c39ae43722340d24`

**Prior corpus (HIGH, "no known fix"):** entry selector `0x33411b5e` calls `pool.swap()` on a **caller-chosen** pool;
the callback (`pancakeV3SwapCallback` `0x23a69e75` / `uniswapV3SwapCallback` `0xfa461e33`) decodes a **caller-supplied
`payer`** from `data` and runs `transferFrom(payer, msg.sender, amount)` with **no check that `msg.sender` is a real V3
pool** → approval-drain. Sep-9-2026 incident ≈62.28 WBNB / 29 victims. Implementation was **upgraded**
`0x241f743e…` → **`0xc700cf8d7adf1782a53a4805d255cf17e126db7f`**; both selectors still present; router native balance 0.

**Re-probe result — the prior "no known fix" is CORRECTED: the mechanism is FIXED.**
The proxy (`0xa331fde0…`, 130 B, native 0) is a **UUPS proxy**; the impl was upgraded
`0x241f743e…` (at the incident block) → `0x50c08665…` → **`0xc700cf8d7adf1782a53a4805d255cf17e126db7f`** (from BSC block
**120,724,906**; 22,857 B, unverified). The new callback (`0x23a69e75` @ impl offset `0x040e`) **`TLOAD`s an EIP-1153
transient pool slot and reverts `SwapX: Invalid pool` unless `msg.sender` equals it**; the `transferFrom` `from` is now
the **router's own swap-context caller**, *not* a value decoded from the callback `data`. (The entry still calls
`pool.swap()` on a caller-chosen pool — `factoryV3()==factoryV2()==0x0` — so the fake-pool precondition survives, but it
can now only move the *attacker's own* tokens.)

Three independent confirmations: (1) heimdall decompile + manual `cast disassemble` (`analysis/bsc-router/`);
(2) live `eth_call` of both callbacks from a random EOA **reverts `SwapX: Invalid pool`**; (3) a local anvil fork
(`RouterProbe.t.sol`) with a fake pool naming a victim in `data` produced `transferFrom(router-caller, fakePool, amount)`
→ **victim drained = 0, recipient drained = 0**.

`Approval(owner, spender=router)` census (topic0 `0x8c5be1e5…`, topic2 = router): **0 events** over the last 3,000,000
blocks (601 chunked requests, 0 misses; filter positively validated against PancakeRouter), 0 in the incident window,
0 funded. → **#approvals = 0, max USD = $0.**

**Verdict: $0 live, mechanism FIXED, confidence HIGH.** Re-arm trigger: a **new impl upgrade** by owner
`0x2803E636498568182594F2909C8d6Cce8820BE15` (`upgradeToAndCall` `0x4f1ef286`) that reintroduces a data-supplied payer.
**Monitor:** EIP-1967 impl slot `0x360894a1…` ≠ `0xc700cf8d…`; `Upgraded(address)` on the proxy; any
`Approval(owner, router)` with a funded real-token balance. Details in `analysis/bsc-router/README.md`.

---

## 6. Verdict, residual & latent risk

* **E-U today = $0.00** (high confidence). The O3 class is **effectively closed across every Summer.fi FleetCommander
  deployment** (all 5 chains + institution + legacy fleets): the only capped **and funded** Ark is Arbitrum LR-USDC's
  Varlamore Ark ($500.79 in a $1,250.8 husk, ≤$750 withdrawable, net-negative to attack).
* **H-O:** the ~$384k of surviving TVL is withdrawable by holders from the buffers of unpaused fleets (self-service).
* **S:** ~$1.03 bricked in Base Bummer-LR-USDC (`totalAssets()` reverts `Aera__VaultPaused`).
* **P:** all Ark/cap/pause changes are curator/governance-gated.
* **Latent (MED):** the FleetCommander code is **immutable** and the fix is operational. Any future Ark that is
  (a) capped-for-offboarding and (b) holds/credits an **impaired or mispriced** asset re-arms the class verbatim.
  **Monitor:** `getActiveArks()` ∩ `{depositCap()==0}` ∩ `{ark.totalAssets()>0}` on every fleet, plus PPS jumps.
* **Blocker to a larger number:** there simply is no funded, mispriced, capped Ark left. The two facts that would change
  the verdict: (1) a capped Ark acquiring a *stale/illiquid* asset balance > ~$10k; (2) any fleet TVL growing materially.

---

## 7. Methodology, caveats & files

**Sources of truth:** repo `OasisDEX/summer-earn-protocol` (core-contracts, per-chain Ignition registries, `config/index.json`);
on-chain `HarborCommand` registry + `FleetCommanderEnlisted` logs (Etherscan V2); verified FleetCommander ABI; Summer.fi
post-mortem, SIP1.7 / SIP2.60.2 (Tally), BA Labs retrospective, halaprix replay, LFG-Capital deep-dive.

**Caveats / limitations**
* Point-in-time **2026-10-26**; re-read live state before acting.
* `totalAssets()` is Ark-derived; an Ark's *credited* value can diverge from realisable value (that is the whole class) —
  the census reports credited value; the fork test probes realisability.
* Institution `FleetCommanderWhitelist` fleets are deposit-whitelisted but redeem-open; included for completeness.
* Public keyless RPCs used (Alchemy/GoldRush quota exhausted per pass-6/7 note). No keyed URLs written anywhere.

**Files**
* `analysis/census/census.json`, `analysis/census/CENSUS.md` — full per-chain fleet/Ark census.
* `analysis/census/chain-*.json` — repo deployment registries (ETH/Base/Arb/Sonic/HyperEVM).
* `analysis/fleetcommander_abi.json` — verified FleetCommander ABI.
* `analysis/bsc-router/` — router re-probe: `README.md`, `evidence.json`, `impl-decompiled.txt`, `impl-disasm.txt`,
  `impl-abi.json`, `RouterProbe.t.sol`.
* `poc/` — Foundry harness + tests; `ci/`, `ci-out/` — CI job + results; `ci-log.txt`, `ci-artifacts/`.
* `summary.json` — machine-readable summary.

## 8. CI

**GitHub Actions** `artsbykriss/ca-zombie-ci`, workflow `poc.yml`, branch `p7-open-fleet`:
**https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40251265363** (`conclusion=success`;
`custom CI script` → `forge test` **4 tests passed, 0 failed, 0 skipped**; artifact
`result-p7-open-fleet` → `ci-out/{forge-test.log,rpc-selection.json}`, both archive RPCs found; log `ci-log.txt`).
*Note:* `ci/run.sh` is needed because the workflow's default `eth_blockNumber` probe picks a **non-archive** publicnode
which cannot serve the historical fork blocks.

*Prepared 2026-10-26 · ZH4 pass-7 O3 · read-only · no secrets.*
