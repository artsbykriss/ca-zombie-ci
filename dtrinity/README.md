# TARGET 3 — dTRINITY dLEND (Aave-V3 fork): liquidity-index inflation — **LIVE E-U = $0**

**Date:** 2026-10-25 · **Chains:** Fraxtal (252), Ethereum (1), Sonic (146); Katana (747474) has **no dLEND**.
**Status:** read-only research; **PoC fork-verified only** (CI, GitHub Actions); **no transaction signed or sent on any live chain**.
**Scope:** ZH4-PASS7 pass7 README §4 row 4 · `pass7/oracle.md` row 6 · `pass7/accounting.md` · `wave2/d2d-liqsweep.md` ("dTRINITY").
**Prior lead (re-verified, not trusted):** "Fraxtal impl is PATCHED; Ethereum exploited 2026-03 for $257k; siblings ≤$947k."

---

## 1. TL;DR

| Target (chain) | Live unprivileged extractable | Why closed / open | Latent risk |
|---|---|---|---|
| **dLEND Pool — Fraxtal** `0xD76C…BCE2` | **$0** | impl `0x20a24d51…` is **PATCHED**; every *unfrozen* reserve has **flash loans disabled** (`flash=0`); the only `flash=1` reserves are **frozen** | none found |
| **dLEND Pool — Ethereum** `0x6598…F153` | **$0** | impl `0xeaa40d04…` is **PATCHED**; **all 15 reserves** have **flash loans disabled** (`flash=0`) | none found |
| **dLEND Pool — Sonic** `0xEdC3…60CC` | **$0** | impl `0x179867c3…` is **UNPATCHED** (vulnerable `cumulateToLiquidityIndex`), **but every reserve is `frozen`** → `supply()` and `borrow()` revert `"28"`; the only borrowable asset with liquidity (dUSD) has **0 cash** | **if governance unfreezes a reserve AND lists a fresh thin market with flash enabled + borrowable liquidity** |
| **dLEND — Katana** | n/a | no Pool/L2Pool deployed (only the dUSD/dETH stablecoin system) | — |

**Total live extractable (external unprivileged), today: `$0.00`.** Confidence: **high** (code diff + live config bits + fork tests).

---

## 2. Total live extractable now

**$0.00** (E-U). Confidence **high**.

- The exploit primitive (`cumulateToLiquidityIndex` with **no minimum-liquidity guard**) is **present in the deployed Sonic impl** and was fork-proven to inflate a reserve's liquidity index by **+12.67 %** in a single flash-loan repayment. It is **removed** from the deployed Fraxtal and Ethereum impls (verified source) and is additionally unreachable there because flash loans are disabled.
- Every live gating condition for the *profitable* path (create a thin position via `supply`, extract via `borrow`) is blocked on the one chain that still carries the unpatched code (Sonic: all reserves frozen; dUSD cash 0).

Categories: **E-U $0 · E-U(conditional) $0 · H-O $0 · P $0 · S $0.** (Supplied TVL — DefiLlama `dtrinity-dlend` — is Ethereum $603,518 / Sonic $183,418 / Fraxtal $177,722; these are user-owned deposits, withdrawable by their owners on non-frozen reserves — not attacker-extractable.)

---

## 3. The bug / mechanism in exact terms

The 2026-03-17 dTRINITY Ethereum loss (~**$257,328.63 dUSD**, cbBTC market, aToken `0x504d0eac…`, impl `0xfDA3a0ef…`, attacker `0x08cfdff8…`) is an inherited Aave-V3 accounting edge case:

`ReserveLogic.cumulateToLiquidityIndex(reserve, totalLiquidity, amount)` (identical in all three impls):
```solidity
uint256 result = (amount.wadToRay().rayDiv(totalLiquidity.wadToRay()) + WadRayMath.RAY).rayMul(reserve.liquidityIndex);
reserve.liquidityIndex = result.toUint128();
```
Stock Aave-V3 `FlashLoanLogic._handleFlashLoanRepayment` passes the **supplier share of the flash-loan premium** into this function with
`totalLiquidity = IERC20(aToken).totalSupply() + accruedToTreasury·index`. There is **no minimum-liquidity guard**, so when the aToken scaled supply is driven to ~1–2 units (a *near-empty* market — the cbBTC market was 6 days old) the ratio `premium / totalLiquidity` explodes and the **liquidity index is permanently inflated**. Inflated `balanceOf = scaledBalance × index / RAY` then mis-states collateral and enables over-borrowing / repeated deposit-withdraw extraction → bad debt.

**The fix (Fraxtal `0x20a24d51…`, Ethereum `0xeaa40d04…`) routes the FULL flash-loan premium to the protocol treasury and never calls `cumulateToLiquidityIndex`** — see `analysis/flashloan_repayment_diff.md` for the exact patched-vs-unpatched source. This is precisely the pass7 description ("Route the full flash-loan premium").

Other `cumulateToLiquidityIndex` call sites: `BridgeLogic.executeBackUnbacked` (reachable only via `Pool.backUnbacked`, gated `onlyBridge` → `ACLManager.isBridge(msg.sender)` — **privileged**, present on all three chains including the patched ones). No other caller exists in the patched impls.

---

## 4. Live-state assessment (addresses, code, config, block numbers)

All reads 2026-10-25; blocks: **Sonic 81,615,554 · Fraxtal 43,073,936 · Ethereum 26,271,956**.
Raw dumps: `ci-out/{sonic,fraxtal,ethereum}_reserves.json` (artifact) and `analysis/*_reserves.txt`.

### 4.1 Deployed implementations (EIP-1967 slot `0x3608…2bbc`)

| chain | Pool proxy | live impl | verified name / solc | impl code keccak256 | flash-loan premium accrual |
|---|---|---|---|---|---|
| Fraxtal | `0xD76C827Ee2Ce1E37c37Fc2ce91376812d3c9BCE2` | `0x20a24d51aded06b5ccbc3cc8f71d1e141391a6d7` | L2Pool / 0.8.24 | `0x3427b8a4…97ec04` | **PATCHED** |
| Ethereum | `0x6598DaD18Bda89A0E58A1F427c8CeBc0dE90F153` | `0xeaa40d04b02726a130c3fd54da7aee7835974f1a` | L2Pool / 0.8.22 | `0xfb69ed07…fb7e11` | **PATCHED** |
| Sonic | `0xEdC3cfB1aa36c570cc1D374876268bDda2D460CC` | `0x179867c392add1bf4f7a3d4c70bf8f2f476bb8cc` | L2Pool / 0.8.20 | `0xb207a786…1680743` | **UNPATCHED** |

Verified sources pulled via Etherscan V2 (chainid 252/1/146): raw JSON `analysis/{fraxtal,eth,sonic}_impl_raw.json`; extracted under `analysis/src/`. Fraxtal deployed the patched impl as a **"SecurityUpgrade"** (`deployments/fraxtal_mainnet/L2Pool-Implementation-SecurityUpgrade.json` = `0x20a24d51…`; the earlier `L2Pool-Implementation.json` = `0xDfD607A7…` is not live). Ethereum's live impl (`0xeaa40d04…`) is **not** the incident impl (`0xfDA3a0ef…` in the repo's `PoolImpl.json`) — it was upgraded post-incident.

### 4.2 Reserve configuration (LTV / frozen / paused / flash bits decoded from `getReserveData.configuration`)

**Sonic — 11 reserves, ALL `frozen=1`, `paused=0`, `active=1`, `flashloanEnabled=1`.** (`frozen` blocks `supply` and `borrow`; it does **not** block `flashLoanSimple` or `withdraw`.)
Borrowable assets: **dUSD** (`borrowEn=1`, LTV 0, cash **0**), **dS** (`borrowEn=1`, LTV 0, cash **597.7**, ≈$600). All others `borrowEn=0`.
Liquid reserves (cash): wstkscUSD 150,546.7 · PT-wstkscUSD 42,362.3 · sfrxUSD 4,507.8 · stS 2,152.9 · dS 597.7 · wOS 5.0 · wstkscETH 9.29 · PT-aSonUSDC 1.29 · WETH 0.394 · scETH 0.0000165.

**Fraxtal — 13 reserves.** `flashloanEnabled=1` **only** on the four **frozen** reserves (scrvUSD, FXB20251231, sDAI, USDe); **every unfrozen reserve has `flashloanEnabled=0`.** dUSD (`borrowEn=1`, LTV 0, cash 13,673.7 dUSD). No reserve is both flash-enabled and supplyable.

**Ethereum — 15 reserves. `flashloanEnabled=0` on ALL of them.** dUSD (`borrowEn=1`, LTV 0, cash 115,341.2 dUSD). Others `borrowEn=0`.

### 4.3 Why each chain is closed
- **Fraxtal / Ethereum:** the premium never touches the index (patched code) **and** the flash-loan path is switched off (`flash=0` on every reachable reserve). The only `cumulateToLiquidityIndex` left (`backUnbacked`) needs the `isBridge` role.
- **Sonic:** the vulnerable code is live, but the attack needs (a) `supply` to create/drive down a thin position and (b) `borrow` to monetise it — both revert `"28"` (RESERVE_FROZEN) on every reserve; and the only liquid borrow asset (dUSD) has **0 cash**. The reserves that still hold meaningful aToken supply (wstkscUSD 150k, PT-wstkscUSD 42k, …) cannot be driven to a thin state because their supply is other depositors'.

---

## 5. What an attacker can / cannot do

**Can (permissionless, live):**
- Call `flashLoanSimple` on Sonic frozen reserves (premium 5 bps) — proven to succeed; **but** it only moves the reserve's own premium pro-rata (net ≤ 0 for the inflater) and there is no position to over-credit, no borrowable liquidity, and no supply to create a position.
- Nothing on Fraxtal/Ethereum (flash disabled; code patched).

**Cannot:**
- `supply()` / `borrow()` on Sonic (`"28"` frozen) → cannot create the thin position or monetise phantom collateral.
- `flashLoanSimple()` on any *unfrozen* Fraxtal reserve or any Ethereum reserve (`"91"` FLASHLOAN_DISABLED).
- Reach `backUnbacked` without the `isBridge` ACL role.

**Preconditions for the profitable path (none currently met):** a **near-empty** reserve (tiny aToken scaled supply) **+** flash loans enabled **+** a large flash-loan capacity (so premium ≫ supply) **+** a borrowable asset with liquidity. Only the first three coexist today on Sonic's frozen near-empty reserves — and they are frozen.

---

## 6. PoC / fork verification

Foundry project `poc/` (vendored `lib/forge-std`), run in **CI (GitHub Actions, `artsbykriss/ca-zombie-ci`)**.
**Run:** https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40229332526 — **7/7 PASS** (also 40228869145 for the first, 3/7 pass, superseded).

| Test | Fork | Result |
|---|---|---|
| `test_sonic_supply_blocked_frozen` | Sonic | `supply(wstkscUSD,1)` reverts `Error("28")` |
| `test_sonic_borrow_blocked_frozen` | Sonic | `borrow(dUSD,1,…)` reverts `Error("28")` |
| `test_sonic_flashloan_open` | Sonic | `flashLoanSimple(WETH,1)` **succeeds** (flash path open) |
| `test_sonic_unpatched_index_inflates` | Sonic | donate 100 WETH to aToken → flash-loan 100 WETH → index `1.0000000508e27 → 1.126733e27` (**×1.1267, +12.67 %**) — **proves the deployed Sonic impl is UNPATCHED** |
| `test_fraxtal_flashloan_disabled_on_unfrozen_reserve` | Fraxtal | `flashLoanSimple(sUSDe,1e18)` reverts `Error("91")` |
| `test_fraxtal_supply_blocked_on_frozen_reserve` | Fraxtal | `supply(scrvUSD,1)` reverts `Error("28")` |
| `test_fraxtal_patched_no_index_inflation` | Fraxtal | identical donate+flash-loan recipe (flash bit forced on via storage override to isolate code) → index **exactly unchanged** — **proves the patch** |

Key numbers: Sonic premium 5 bps (`FLASHLOAN_PREMIUM_TOTAL=5`), Fraxtal 3 bps, Ethereum 5 bps. The Sonic positive test needed a state change (a permissionless ERC-20 **donation** to the aToken — no supply) to create a thin market; the Fraxtal negative test forced the flash bit on to isolate the code. **Neither manipulation is required for the $0 verdict**: the live blockers (`"28"` / `"91"`) are read directly from the unmodified forks.

**Fork-before/after (unmodified state) is the decisive negative:** on Sonic the attack's entry (`supply`) and exit (`borrow`) both revert `"28"`; on Fraxtal/Ethereum the flash-loan primitive itself is `"91"`-disabled.

---

## 7. Verdict, residual / latent risk, blockers

**Verdict: $0 live extractable by an external unprivileged attacker.** The 2026-03 Ethereum incident (≈$257k) was remediated by a code fix (full premium → treasury) on Ethereum and Fraxtal, and the Sonic deployment that still carries the vulnerable code is fully frozen with no borrowable liquidity.

**Latent risk (Sonic only):** the deployed Sonic impl `0x179867c3…` is bytecode-distinct and **unpatched**. If governance (a) **unfreezes** a reserve (clears config bit 57) **and** (b) a **fresh, near-empty market** is listed there with flash enabled **and** (c) a borrowable asset with liquidity exists, the cbBTC-class exploit becomes live again, bounded by that market's liquidity. Re-arm monitor: `ReserveFrozen`/unfreeze events, `PoolConfigurator` reserve-config changes, or any new Sonic reserve listing.

**Privileged residual (all chains):** `Pool.backUnbacked` → `BridgeLogic.executeBackUnbacked` still calls `cumulateToLiquidityIndex`; it is `onlyBridge`-gated (`ACLManager.isBridge`). If the bridge role is ever granted to an attacker-influenced contract, that path inflates the index with `totalLiquidity = aToken.totalSupply()+accrued·index` and a **caller-supplied** `feeToLP` — a **P**-class risk, not E-U. Sonic ACLManager `0x973044bF0667D49de528CD32737028cc4E08E593`: `isBridge(Pool)=false` (no attacker-reachable bridge today).

**Blockers observed:** Sonic all-reserves `frozen`; Sonic dUSD `cash=0`; Fraxtal unfrozen reserves `flash=0`; Ethereum all reserves `flash=0`.

---

## 8. Methodology & sources; caveats; files

- **Method:** EIP-1967 impl reads; `eth_getCode`; Etherscan-V2 verified source (chainid 252/1/146); reserve-list + `getReserveData` + `balanceOf(aToken)` + `totalSupply` scans on public RPCs; dTRINITY GitHub deployment manifests; incident post-mortems (docs.dtrinity.org, DARKNAVY, Olympix, Verichains, SIT); **Foundry forks** of Sonic & Fraxtal (CI).
- **Caveats:** (i) point-in-time 2026-10-25 — re-read live state before acting; (ii) the Sonic positive test used a state override/donation to build a thin market (clearly labelled); the $0 verdict rests on the **unmodified** fork's `"28"`/`"91"` reverts; (iii) Katana's repo contains no dLEND Pool (dLEND exists only on ETH/Sonic/Fraxtal per DefiLlama `dtrinity-dlend` chains); (iv) public-RPC rate limits caused occasional retries.
- **Files:** `README.md`; `summary.json`; `analysis/flashloan_repayment_diff.md` (patch evidence); `analysis/{fraxtal,eth,sonic}_impl_raw.json` (verified source, raw); `analysis/src/{fraxtal,eth,sonic}_L2Pool/**` (extracted Solidity); `analysis/*_reserves.txt`; `analysis/scripts/*`; `analysis/deployments/*` (dTRINITY manifests); `poc/` (Foundry, 7 tests); `ci/run.sh` (live-state dumper → `ci-out/`); `ci-out/*.json`, `ci-artifacts/`, `ci-log.txt`.

**No keyed RPC URLs or secrets are stored in this folder.**
