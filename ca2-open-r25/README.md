# CA2 OPEN-1 — R25 WrappedVault family (Pharos): the $169.4M is manager NAV, not on-chain USDC

**Date:** 2026-11-03 · **Chain:** Pharos mainnet (chain id **1672**) · **Block:** **22,019,671**
**Status:** read-only. No transaction was signed or sent. The PoC is `eth_call` / `eth_getCode` / `eth_getStorageAt` only. No secrets, no keyed RPC URLs.

---

## 1. TL;DR

| Target | `totalAssets()` (reported NAV) | USDC actually held | Unprivileged extractable | Why closed |
|---|---:|---:|---:|---|
| `vRPCQuarterlyVault` `0x94f7…1a86` | $84,364,217.74 | **$0.00** | **$0.00** | NAV = `totalSupply × latestNav / 1e13`; vault holds 0 USDC at every block checked; whitelist on; oracle/controller role-gated |
| `vRPCWeeklyVault` `0x1c2b…9268` | $2,085,032.21 | **$0.00** | **$0.00** | same AsyncVault design (impl `0x6360…3835`); 0 balance |
| `vRPCSemiYearlyVault` `0xee26…190b` | $10,019,986.32 | **$0.00** | **$0.00** | same impl as Quarterly (`0xe5d7…ed42`); 0 balance |
| `apcVault` `0xd042…908a` (APC3M) | $72,845,136.26 | **$0.00** | **$0.00** | R25 async vault, separate impl `0x880a…75fc`; 0 balance; 66.5% of shares self-held |
| `hybVault` `0x6ce4…075d` (pNYLIM-HYB) | $98,864.18 | **$0.00** | **$0.00** | **not R25** — Centrifuge-style wrapper for “NYLIM US High Yield Bond Fund”; 0 balance |
| **Total** | **$169,413,236.72** | **$0.00** | **$0.00** | |

**Total live extractable now: $0.00 — confidence: high.**
**Total on-chain USDC in the whole system: $0.00** (escrow holds 1 wei of dust). The entire Pharos USDC supply at the pinned block is **$11,779,172.72** — 14.4× *smaller* than the claimed $169.4M.

**Bottom line on the contradiction:** the prior pass2 row was **right** — “manager-set NAV; 0 USDC held; role-gated updates” is exactly what the contracts do. The `ca2-recon` “$169.4M measured” figure is also *arithmetically* right, but it is `totalAssets()` (a NAV number), not a token balance. The contradiction is a **metric error** (NAV vs `balanceOf`), not a different contract and not a stale read.

---

## 2. What the $169.4M actually is

### 2.1 The identity

`AsyncVault.totalAssets()` is not balance-derived. It is:

```
totalAssets() = totalSupply() * latestNav() / NAV_PRECISION      // NAV_PRECISION = 1e13
```

Verified live on `vRPCQuarterlyVault` at block 22,019,671:

| quantity | value |
|---|---:|
| `totalSupply()` | 78,978,788.304361 shares |
| `latestNav()` | 10,681,883,016,348 (= 1.0681883016348 × 1e13) |
| computed `totalSupply*nav/1e13` | 84,364,217,744,009 raw |
| `totalAssets()` | **84,364,217,744,009 raw = $84,364,217.744009** |
| `USDC.balanceOf(vault)` | **0** |

`latestNav` lives in storage slot 12 and is written only by `handleOracleReport(...)` (`0x4bda1b55`), which is `onlyRole(ORACLE_REPORTER_ROLE)`. At the pinned block `lastReportId = 201`, `lastAccountingTimestamp = 2026-11-03 07:00:00 UTC`, one report per day (previous: 2026-11-02 07:00:00 UTC), with a **±1,000 bps (10%) daily fluctuation cap** (`maxFluctuationBps = 1000`).

### 2.2 It is not USDC held anywhere on-chain

| address | role | USDC balance (block 22,019,671) |
|---|---|---:|
| all 5 vault proxies | vaults | **0** each |
| `0x1f971696…d57d` | vRPCQ whitelist proxy | 0 |
| `0x89362a53…7b1e` | vRPCQ withdraw queue proxy (impl `0x8fe1…9cac`) | 0 |
| `0xa1f93265…cad2` | vRPCQ `swaper` (“Swap”, impl `0xf2ad…fa15`) | 0 |
| `0xb4b6d9f8…826c` | vRPCQ `custodian` (EOA, no code) | 0 |
| `0xf3503da2…411f` | R25 shared `escrow` | **1 wei** |
| `0x50851423…2b18`, `0xb78227eb…9e3f` | queue/whitelist ProxyAdmins | 0 |
| `0xE5D7E7E0…eD42` | vRPCQ implementation | 0 |
| `0x880ac096…75fc`, `0xd72e841f…2984` | apc / hyb implementations | 0 |

The vaults held 0 USDC at blocks **19,000,000 / 20,000,000 / 21,000,000 / 22,000,000** as well (see `analysis/historical-balances.json`). This is not a snapshot artifact: there is no block at which these vaults held the asset.

### 2.3 The scale check

- Whole Pharos USDC supply: **11,779,172.72 USDC** (`totalSupply()` at block 22,019,671; token `0xC879…1815`, 6 dp, `name/symbol = USDC`, 25,004 holders, explorer price $0.999623).
- Claimed AUM: **169,413,236.72**.
- Ratio: **14.38×**.

Even if every USDC on Pharos were inside these five vaults, the NAV could not be honoured. The claim is necessarily an **off-chain** claim (emerging-market consumer-credit receivables), which matches the issuer’s public materials: R25 “VRPC” = Variable Real Private Credit, Axil Consumer Credit Vault (92-day / 7-day / 182-day terms), with periodic attestations in a Google Drive folder (DefiLlama RWA page for `VRPCQ`). DefiLlama reports the same $84.36M “Onchain AUM” for VRPCQ — it uses `totalAssets()` as well, so it is not independent evidence of a balance.

### 2.4 Who holds the claims (protocol-owned vs user-deposited)

`vRPCQuarterlyVault` — 5 holders / 88 transfers:

| holder | shares | % |
|---|---:|---:|
| R25 `escrow` `0xf3503da2…411f` | 68,195,032.797 | **86.35%** (user custody) |
| EOA `0xffdea41b…9521` | 6,366,791.907 | 8.06% |
| vault-manager proxy `0x8ecdf424…ab9f` | 2,444,079.940 | 3.09% |
| EOA `0x40836f8f…9819` | 1,972,883.645 | 2.50% |
| dust `0xf03c006f…30c9` | 0.015 | 0.00% |

`escrow` `0xf3503da2…411f` is the same contract that other R25 vaults expose as `escrow()` (e.g. `apcVault.escrow()`), so it is the shared user-custody contract. It holds **1 wei** of USDC and **0** of the underlying.

Concentration notes (relevant to what the AUM really is):
- `vRPCSemiYearlyVault`: the vault holds **3,605,110.97 of its own 9,448,908.25 shares = 38.15%** (treasury/unsold inventory).
- `apcVault`: the vault holds **46,726,346.48 of 70,278,480.33 APC3M shares = 66.49%** of its own supply. The escrow holds **0** APC3M.
- `hybVault`: `backingShares()` = 99,580.105 of `underlyingShare` `0x4827…2505` (“NYLIM US High Yield Bond Fund”, HYB), but `HYB.balanceOf(hybVault) = 0` — the backing is held by the Centrifuge vault `0x74189e01…6da8`, not by the wrapper.

So a large part of the reported $169.4M is **not third-party user money**: it is self-held share inventory (apc 66.5%, vRPCS 38.2%) plus a manager-attested NAV on off-chain receivables.

### 2.5 Is the share accounting real?

Internally, yes: `totalSupply × latestNav` reconciles to the wei on all three AsyncVaults that expose both (`totalAssets` matches the identity exactly on vRPCQ; the same formula reproduces vRPCW/vRPCS at their respective NAVs within rounding). Shares are real ERC-20s with a real holder set, and `requestRedeem` is a real ERC-7540-style path.

Externally, **it is not balance-backed on-chain**. The accounting is a claim on an issuer/custodian, not a claim on tokens in the contract. This is a “tokenized fund” accounting model, not a rehypothecation bug: nothing was double-lent on-chain, because nothing was on-chain to begin with.

---

## 3. The prior closure vs the live read

| source | statement | verdict |
|---|---|---|
| `pass2-recon/README.md` row R25 | “Manager-set NAV; 0 USDC held; role-gated updates” | **correct on all three counts** |
| `ca2-recon` OPEN row 1 | “$169,413,236.76 measured … contradiction of prior closure” | **measurement error**: it summed `totalAssets()`, never read `balanceOf(vault)` |
| this report | $169.41M is NAV/AUM; on-chain asset balance is $0.00 | reconciles both |

No different-contract error: the vaults named in the recon are the ones read here; all five `asset()` calls return the same canonical Pharos USDC `0xC879…1815`. No stale read: the same zero balances reproduce at five historical blocks.

---

## 4. Deployed code and call graph

### 4.1 vRPCQ / vRPCS implementation `0xE5D7E7E079ECA99EBE5295e24a3908374e8aEd42` (26,337 B, **unverified**)

Heimdall decompilation (`analysis/decompiled/impl_vRPCQ_e5d7/`) recovers the interface:

`deposit(uint256,address)`, `mint(uint256,address)`, `withdraw(uint256,address,address)`, `redeem(uint256,address,address)`, `requestRedeem(uint256,address,address)` (`0x7d41c86e`), `cancelRedeemRequest(uint256)` (`0xc3f0d30e`), `batchRedeem(uint256[])`, `batchAutoRenew(uint64,uint256)`, `handleOracleReport((uint64,uint64,uint64,uint256,address))` (`0x4bda1b55`), `claimableRedeemRequest`, `pendingRedeemRequest`, `getAvailableShares`, `getLockedShares`, `redeemRequests`, `nextRedeemRequestId`, `custodian`, `swaper`, `whitelist`, `latestNav`, `maxFluctuationBps`, `maturityPeriod`, `share`, `getProxyAdmin`, `getProxyImplementation`.

Key semantics confirmed live + from the BlockSec audit source excerpts (`analysis/audit-blocksec-r25.md`):
- `handleOracleReport` is `onlyRole(ORACLE_REPORTER_ROLE)`; strict **+1 day / +1 reportId** sequencing; `block.timestamp >= accountingTimestamp`; `|newNav - oldNav| / oldNav <= maxFluctuationBps` (10%).
- `batchRedeem` computes `assets = shares * settlementNav / 1e13`, subtracts `withdrawFeeBps`, enqueues `withdrawQueue.requestWithdrawal(...)`, then calls **`swaper.withdrawByAgent(requestId, custodian, assetsAfterFee)`**. The USDC for a redemption therefore comes from the **`swaper`/Swap contract**, not from the vault’s own balance.
- `_onReceiveShares` assigns `unlockTime = lastAccountingTimestamp + maturityPeriod + 1 days`; the quarterly vault’s `maturityPeriod` is 7,948,800 s (92 days).
- `requestRedeem` enforces `msg.sender == owner` (probe in §5.3).

### 4.2 The other implementations

| vault | impl | size | identity |
|---|---|---:|---|
| vRPCW | `0x6360b337196d69a92b3e2fc6f57681c5f6773835` | 45,771 B | AsyncVault variant (same `share()/latestNav` family) |
| apcVault | `0x880ac096be22069751445bd17b3cd6e40b8575fc` | 15,201 B | AsyncVault variant with `escrow`, `accountant`, `epochManager`, `vaultManager`; share token `0xec47e6f3…` = **AxilPrimeCredit-3M (APC3M)**, 18 dp, 70,278,480.334 supply |
| hybVault | `0xd72e841f56b2a0b7423d6c4ffd8ae96fdf812984` | 22,523 B | **Centrifuge-style** vault: `centrifugeVault`, `settleDeposits`, `settleRedeems`, `depositQueueState`, `redeemQueueState`, `pricePerShare`, `backingShares`; `pricePerShare = 992219` (0.992219), `underlyingShare` = NYLIM HYB, `backingShares` 99,580.105 but `HYB.balanceOf(vault) = 0` |

`hybVault` is **not** an R25 contract. It was bundled into the recon row by address proximity; its $98,864 is a Centrifuge-wrapper NAV, not R25 private credit. The R25-attributable part of the $169.4M is **$169,314,372.54** (the four R25 vaults).

### 4.3 Proxy / admin chain

- vRPCQ/vRPCS: non-standard 1,115-byte proxy (`getProxyAdmin` / `getProxyImplementation`, `upgradeToAndCall` guarded by `msg.sender == admin`). EIP-1967 admin slot = `0xd83C0A13CFcD9990Edee0765eeb3e134aa931b40` (1,018-byte `ProxyAdmin`-style contract); its `owner()` = `0x946643403Ad76edDD17cBC9B412E9673B2207C82`, itself a 1,115-byte contract of the same proxy family.
- vRPCW admin = `0x82a87f5f385fac3e6f66e289e3826054b87c1d78` (ProxyAdmin), `owner()` = `0x94664340…7C82`.
- Whitelist proxy admin = `0xb78227eb…9e3f`; queue proxy admin = `0x50851423…2b18`; both `owner()` = `0x94664340…7C82`.
- Swap proxy `0xa1f93265…cad2` admin = `0xee8d1f21c148567b5b275acdc7f7727c3c7b2a37`, `owner()` = `0xa74A8Dc2a2360B3db6A65C5B17f3fd61ddCEa10D` (a 2,007-byte contract of the Swap-proxy family).

All upgrade authority is **P** (privileged), not attacker-reachable.

---

## 5. What an unprivileged attacker can and cannot do

Attacker model: fresh EOA, no roles, no whitelist, no protocol privileges, only public contracts/RPC.

### 5.1 Gates that are on

| gate | live value | effect |
|---|---|---|
| `whitelistEnabled()` | **1 (true)** | deposits require whitelisting |
| `isWhitelisted(0x1111…1111)` | **0** | attacker cannot deposit |
| `isWhitelisted(0x40836f…9819)` | 1 | the 2.5% holder is whitelisted |
| `maxRedeem(attacker)` | **0** | nothing to redeem |
| `getRedeemRequestCount(attacker)` | **0** | no requests |
| `paused()` (all vaults) | 0 | not paused (so “paused” is not the closure reason) |
| `ORACLE_REPORTER_ROLE` | `0xa33b05f6…5860` (EOA) | NAV updates are one key, 1/day, ±10% |
| `CONTROLLER` | same EOA `0xa33b05f6…5860` | batch settlement / renew |

### 5.2 Every value-moving entrypoint reverts for the attacker

`eth_call` with `from = 0x1111…1111` (block 22,019,671):

| call | result |
|---|---|
| `deposit(1e6, attacker)` | **revert** |
| `mint(1e6, holder)` | **revert** |
| `requestRedeem(1e6, attacker, attacker)` | **revert** |
| `requestRedeem(1e6, attacker, holder)` (owner ≠ sender) | **revert** |
| `cancelRedeemRequest(7)` (not owner) | **revert** |
| `redeem(1e6, attacker, attacker)` | **revert** |
| `withdraw(1e6, attacker, holder)` | **revert** |
| `handleOracleReport(...)` | **revert** |

The reverts are not merely “no balance”: the auth probes show `requestRedeem` rejects a third-party `owner`, and `cancelRedeemRequest` rejects non-owners, so an attacker cannot manufacture a claim on the escrow’s 86% either.

### 5.3 Allowances: no funded holder can be pulled

| holder | USDC | allowance → swaper | allowance → queue | allowance → vRPCQ |
|---|---:|---:|---:|---:|
| liquidity proxy `0x8ecdf424…ab9f` | $1,016,065.35 | 0 | 0 | 0 |
| EOA `0x40836f8f…9819` | $296,756.63 | 0 | 0 | **698,360.32** |
| issuer `0x475A6042…8b46` | $230,947.78 | 0 | 0 | 0 |

The only non-zero allowance is a normal **deposit approval** from a shareholder to the vault it deposits into. It is not consumable by a third party: `deposit`/`mint` use `msg.sender` as payer (probes above), and no other entrypoint takes an arbitrary `owner`/`from`.

The custodian EOA `0xb4b6d9f8…826c` has approved the swaper for **68,791,831.27 USDC** but holds **0**. This is the one interesting latent fact — see §7.

### 5.4 The swaper is agent-gated

`Swap.withdrawByAgent(uint256,address,uint256)` (`0x7e48e7a5`):
- from the attacker → revert `0xe2517d3f` = **`AccessControlUnauthorizedAccount(address,bytes32)`**;
- from the vRPCQ vault address → a *different* revert (`Error(string)`), i.e. the vault **is** an authorized agent and fails later (no liquidity / price math), not at auth.

So redemptions can only be driven through the vault → Swap path, with amounts derived from a settled request, never caller-supplied directly.

---

## 6. PoC / verification

- **File:** `poc/r25_poc.py` (stdlib only; no `eth_utils`, no keys).
- **What it does:** pins a block, reads all five vaults + token + whitelist + queue + swaper + escrow + custodians, executes the seven attacker probes, checks historical balances and allowances, writes JSON, exits non-zero on any failed assertion.
- **Result (local, block 22,019,671): 44/44 assertions PASS.**
- **CI:** `bash /home/heisenberg/CA/ci/ci-run.sh ca2-open-r25` → `ci/run.sh` → `ci-out/r25-poc.json` (run URL recorded in `summary.json` / `ci-log.txt`).

Why not Foundry: Pharos’s public RPC does not implement `eth_getProof` in the form Foundry’s fork backend needs (the same limitation was hit in the CA2 recon). The prompt allows a documented read-only `eth_call` PoC in that case. The PoC is stronger than a fork for this specific question because it tests the *live* state at a pinned block rather than a reconstructed one.

Key PoC output:

```
block 22019671
measured_totalAssets_usd 169413236.722726
usdc_totalSupply_usd     11779172.720263
assertions 44/44 passed
```

Evidence files:
- `analysis/historical-balances.json` — all five vaults, USDC balance 0 at blocks 19M/20M/21M/22M/22,019,671.
- `analysis/decompiled/` — Heimdall output for the vRPCQ impl, vRPCW impl, Swap logic, queue impl, whitelist impl.
- `analysis/audit-blocksec-r25.md` — BlockSec R25 AsyncVault audit (2026-04-28; 6 low, 0 high/critical) with the exact `batchRedeem` / `handleOracleReport` source excerpts.

---

## 7. Verdict, categories, residual risk

### 7.1 Categories (USD, at block 22,019,671)

| category | USD | confidence | meaning |
|---|---:|---|---|
| **E-U** (external unprivileged) | **$0.00** | **high** | no on-chain pot, no unauthenticated entrypoint, no allowance to pull |
| **E-U-conditional** | **$0.00** | high | no attacker-triggerable condition found; see latent note below |
| **H-O** (holder-only, on-chain) | **$0.00** | high | holders can `requestRedeem`, but settlement needs a funded swaper; swaper balance = 0 |
| **P** (privileged) | — | — | oracle/controller EOA + upgrade admins can move NAV ±10%/day and upgrade impls |
| **S** (stuck) | **$0.00** | high | nothing is stuck *on-chain*; the $169.4M is an off-chain claim |

The $169.4M is **not** an E-U, H-O or S number. It is reported AUM / a contractual claim on an off-chain credit book. Booking it as “extractable” (as the recon row implied by putting it in an OPEN list) is wrong.

### 7.2 Latent risks (not currently extractable)

1. **Custodian allowance / future funding.** `0xb4b6d9f8…826c` (EOA) has approved the swaper for **68.79M USDC**. If R25 ever funds that EOA (repayments, new subscriptions) *and* an agent-path bug exists, the ceiling is the funded balance. Today the balance is 0 and `withdrawByAgent` is agent-gated. Monitor this address.
2. **Single oracle/controller key.** One EOA (`0xa33b05f6…5860`) reports NAV and controls settlement. It can move NAV up to +10%/day legitimately; over ~7 days that is a ~2× mark. That is a **P** risk (issuer/manager), not an attacker path. A compromised key could mark the vault up and then redeem its own/escrow shares — but the payout still requires a funded swaper.
3. **Off-chain attestation risk.** The NAV is backed by attestations in a Google Drive folder, not by on-chain collateral. Whether the $169.4M of receivables exists is not verifiable from Pharos. This is a credit/disclosure risk for holders, not an on-chain exploit.
4. **Upgradeability.** All proxies are upgradeable; the admin chain ends in contract `0x94664340…7C82`. A malicious upgrade could redirect the escrow’s shares or the swaper flow. **P**, not E-U.

### 7.3 What would change the verdict

- Any USDC arriving at a vault, the queue, the swaper, or the custodian EOA (watch `0xb4b6d9f8…826c`).
- A `withdrawByAgent` implementation change that drops the agent check.
- Discovery of a share-lot double-spend in `requestRedeem`/`batchRedeem` *combined with* a funded swaper.

None of these is true at block 22,019,671.

---

## 8. Methodology & sources

- **On-chain:** Pharos public RPC `https://infra.originstake.com/pharos/evm` (keyless), chain id 1672; all reads pinned to block 22,019,671 unless a historical block is stated. `eth_call`, `eth_getCode`, `eth_getStorageAt`, `eth_getLogs` (10k-block windows).
- **Decompilation:** Heimdall 0.8.x (`--include-sol`) on the fetched runtime bytecode; ABI cross-checked against live `eth_call` behaviour and against the BlockSec audit source excerpts.
- **Audit:** BlockSec, “R25 AsyncVault Contracts”, signed 2026-04-28, report id `2632908b…` — 6 low findings, 0 high/critical (ERC-7540 incompatibility, max-limit functions, `assetsAfterFee` zero, gas griefing, `maturityPeriod` validation, config bounds). Repo mirror used: `DicksonWu654/web3-audit-findings`.
- **Product context:** DefiLlama RWA `VRPCQ` page (Onchain AUM $84.36m, price $1.07, Private Credit, issuer R25, attestations link) and `pharosscan.xyz` token/address pages (holders, names, 25,004 USDC holders, $0.999623).
- **Explorer:** `https://www.pharosscan.xyz` (Socialscan-based) for holder tables and token metadata; on-chain re-read for every number quoted.

### Caveats

- The `hybVault` is a Centrifuge wrapper, not R25; its $98.8k is included only because the recon row included it. R25-only total: **$169,314,372.54**.
- USDC `totalSupply()` on Pharos moves materially between blocks (bridge mints/burns): 11.66M → 13.33M → 11.78M observed within ~2k blocks. The comparison uses the value at the pinned block; the conclusion (supply ≪ claimed AUM) holds at every observed value.
- `totalAssets()` for `hybVault` drifts with the Centrifuge `pricePerShare` (98,864.21 → 98,864.18 over the session); the R25 vaults are stable between daily reports.
- The `apcVault` share supply is read from its separate share token (`0xec47…`), not from the vault proxy (the proxy does not implement `totalSupply()`).
- Heimdall output for the largest functions is partial (symbolic execution timeout); the auth conclusions in §5.4 are from live `eth_call` error selectors (`0xe2517d3f` = OZ `AccessControlUnauthorizedAccount`), not from the pseudo-Solidity alone.

---

## 9. Files

| path | contents |
|---|---|
| `README.md` | this report |
| `summary.json` | machine-readable result |
| `poc/r25_poc.py` | 44-assertion read-only PoC |
| `poc/sigs.py` | static selectors + address book |
| `ci/run.sh` | CI entrypoint (runs the PoC into `ci-out/`) |
| `ci-out/r25-poc.json` | full live-state + assertions |
| `ci-out/summary.txt` | console summary |
| `analysis/historical-balances.json` | 0-balance proof at 5 blocks |
| `analysis/decompiled/` | Heimdall output (impl, Swap, queue, whitelist, vRPCW) |
| `analysis/audit-blocksec-r25.md` | audit excerpts (public source) |
| `analysis/audit-finding-maturity.md` | audit finding detail (public source) |
| `ci-log.txt`, `ci-artifacts/` | CI run log + artifacts |
