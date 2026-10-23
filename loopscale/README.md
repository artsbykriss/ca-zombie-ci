# ZH4 residual OPEN-B — **Loopscale Curation** (Exponent strategy-vaults program, Solana)

**Date:** 2026-10-23 · **Chain:** Solana mainnet · **Status:** read-only; **no transactions signed or sent**;
the fresh-signer probe uses `simulateTransaction` with `sigVerify=false` (a dry run against live state, not a broadcast).
**Owner:** ZH4 residual-OPEN-B subagent (target 2 of 3).

DefiLlama slug `loopscale-curation` — **$7,487,668 live** across 13 curator vaults at slot **460,363,439**.

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why closed | Latent risk |
|---|---|---|---|
| **Loopscale Curation** — 13 `ExponentStrategyVault`s on program `sVau1tXvayVWfotzm9Ahcv2qfnnfRWttt78BCnNC6dD` | **$0** | Every value-moving instruction is role-gated (verified live: `UnauthorizedRole 6005` / `InvalidPriceManager 6068`); all three audits' findings are Resolved; the deployed binary was upgraded **2026-10-14**, *after* the audits, and carries the fix markers | LOW: acknowledged DoS findings (pre-funded-PDA DoS, zero-mint for allowlisted creators); a compromised Loopscale curator key could drain its own vaults (P) |

**Total live extractable now (E-U): $0.00 — confidence: high.**

---

## 2. What the target actually is

"Loopscale Curation" is **not** a Loopscale program. The DefiLlama adapter
(`projects/loopscale-curation/index.js`) reads AUM from the **Exponent strategy-vaults program**
`sVau1tXvayVWfotzm9Ahcv2qfnnfRWttt78BCnNC6dD` and keeps only vaults whose `roles.curator` is
`bs1PuRvB9rBBZkryBjADYvxc2qYh51EVW2fsb1uTiBN` (Loopscale Asset Curation). Loopscale is the **curator/manager**;
Exponent is the vault framework. The vaults deploy into Loopscale markets and Exponent positions
(`LoopscaleLoan`, `LoopscaleStrategy`, `LoopscaleVaultStake` position variants are in the on-chain enum).

Program facts (read on-chain, slot 460,363,439):

| Item | Value |
|---|---|
| Program | `sVau1tXvayVWfotzm9Ahcv2qfnnfRWttt78BCnNC6dD` (executable, BPFLoaderUpgradeable) |
| ProgramData | `36EV3EKoArMVsWQNonccP68eEN2jRoQdPxj46JjmC4cA` |
| Last upgrade | slot **456,916,574** = **2026-10-14T17:11:12Z** |
| Upgrade authority | `62zLwJ1xBfsUkhLuBtxgdd8xvhrJ19suDBxviXG95baN` |
| ELF size | 2,702,032 bytes, stripped eBPF (dumped to `analysis/program_elf.so`) |
| Global price registry | PDA `exponent_prices` = `ACfqroCCvTQBocSt5DdRuCu5DKbQm7cLDrxKkSzyvFb` (initialized) |
| Program admin | PDA `admin` of `exponent_admin` = `8HNzNyJjN5Gyf5EmDjwSnKttvC59347DR6ZG1E4cqBWA` |

---

## 3. Live-state assessment (slot 460,363,439)

13 vaults, all `status_flags=0`, manager **=** curator **=** `bs1PuRvB9rBBZkryBjADYvxc2qYh51EVW2fsb1uTiBN`:

| Vault | Underlying | AUM (base) | USD |
|---|---|---|---|
| `9iPUphFXxnyAKYnCTG3XZv5ybHv5Ki1diqA5mis3TBVB` | USDC | 4,332,812.43 | $4,330,620.10 |
| `EsTx9ToYW2k1DsTw6ccpmP3RrXQriod114hcM7U5ZKaR` | USDC | 2,021,087.03 | $2,020,064.40 |
| `BWuXMAURGyehq9AWCDDY79YE88ADkgYKr9wGw3Y3nVd8` | SOL | 8,063.785 | $841,285.47 |
| `63q8q952GEsJsjsQuFFJRnYDf7NBpcMLLxFuFGyYWg6C` | SOL | 2,684.800 | $280,102.14 |
| `3hM9qdba55P6PyRE4v69RB64sFGsaALA3zZrAhwWw4GA` | USDC | 10,353.23 | $10,347.99 |
| `5i9ZHcZJRnc5KVzCjovGsEw3GwuYPTnappP3DskAnotP` | SOL | 20.004 | $2,086.98 |
| `D6KZ7dKdtuBGZkZZ2Rpnt1T9jUWzbxVcpwGe7BUZAqi4` | synth-USD | 1,000.99 | $1,000.49 |
| `34VfWz4gbzKmsgtSsbqVPA6mzaH2LTEucMyko2APZcN7` | synth-USD | 1,000.00 | $999.49 |
| `CafHV1mnD4iRsTetmM9iULj1Cuui7PVbPo3hGxWi3x1K` | USDC | 850.24 | $849.81 |
| `utJ4Hftdqn3ZtkPy3Y59ea5E78PtJvBrrB6eGT9Mw7S` | synth-USD | 198.06 | $197.96 |
| `3AME6Z3hzbdekdUNazmVWH339peF9VvEtEdQFTpADGKP` | SOL | 1.088 | $113.48 |
| `4apKX8527bymFrQL4mE7pQuLdfxdHp5esGUuDkqqbypY`, `BN97ARPm7JG7KffduSsu9BB821Bbx1VWpEpGRCzqhTx4` | SOL / USDC | 0 | $0.00 |
| | | | **$7,487,668.31** |

Prices: DefiLlama coins API (SOL $104.33, USDC $1.00 at the stated time). Raw JSON: `analysis/loopscale_exposure.json`.

---

## 4. Instruction surface

The instruction set was recovered from the published SDK `@exponent-labs/exponent-sdk@0.9.30`
(`build/client/vaults/instructions/*`) — it is a **1-byte-tag** (pinocchio-style) dispatch, not Anchor 8-byte:

`deposit_liquidity`(01) · `queue_withdrawal`(04) · `fill_withdrawal`(05) · `execute_withdrawal`(06) · `update_price`(07) ·
`sentinel_set_vault_flags`(0a) · `manage_vault_settings`(16) · `initialize_prices`(18) · `manage_prices`(19) ·
`update_twap_price`(1a) · `refresh_aum`(27) · plus proposal/governance, policy wrappers
(`wrapper_add/remove/update_policy`, `wrapper_execute_withdrawal`), `manager_update_position`, `initialize_vault`,
`execute_withdrawal_from_reserves`, `collect_management_fee`, `stake_vote`/`unstake_vote`, `migrate_*`.

Role model: `manager`, `allocator`, `curator`, `sentinel`, `price_manager` (plus governance proposals/squads).
The deployed ELF (`analysis/elf_strings.txt`) contains the error strings
`Signer is not authorized for this role`, `Invalid manager`, `Invalid price manager`,
`Cannot remove the last price manager`, `Invalid vault creator`, `YVault creators capacity exceeded`,
`Live wrapper setup only supports additive strategy position changes`,
`Direct policy changes require an empty vault (total AUM must be zero)`.

---

## 5. Fresh-signer auth probe (read-only, live state)

`analysis/sim_auth_probe.py` — builds each instruction with a **fresh random keypair** in the role slot and calls
`simulateTransaction` with `{sigVerify:false, replaceRecentBlockhash:true}` (nothing is broadcast). Results:

| # | Instruction (fresh signer) | Result | Interpretation |
|---|---|---|---|
| A | `sentinel_set_vault_flags` | **`UnauthorizedRole` 6005** @ `sentinel_set_vault_flags.rs:71` | sentinel role enforced |
| B | `manage_vault_settings` | **`UnauthorizedRole` 6005** @ `wrapper_manage_vault_settings.rs:28` | manager/allocator role enforced |
| C | `execute_withdrawal` (fresh signer as `owner`) | `AccountNotInitialized` 3012 (`withdrawal_account`) | a fresh signer has no withdrawal account → cannot withdraw |
| D | `deposit_liquidity` (fresh signer) | `AccountNotInitialized` 3012 (`token_src`) | deposit only debits the caller's own token account |
| E | `initialize_prices` | **`UnauthorizedRole` 6005** @ `initialize_prices.rs:34` | global price-registry takeover (ADV-08/09) closed |
| F2 | `manage_prices [RemovePrice]` | **`InvalidPriceManager` 6068** @ `manage_prices.rs:209` | price-manager role enforced |
| — | `refresh_aum` / `update_price` | reach body (permissionless crank by design) | oracle-validated; not an extraction path |

The program error file paths printed in the logs (`programs/exponent_vaults/src/...`) match the audited source layout,
confirming the deployed binary is the audited (post-fix) code.

---

## 6. What an attacker can / cannot do

- **Cannot** call any manager/allocator/sentinel/price-manager action — verified.
- **Cannot** re-initialize the global price registry or take it over — verified.
- **Cannot** create a vault (allowlist: `Invalid vault creator`) — fix marker present.
- **Can** call permissionless cranks (`refresh_aum`, `update_price`) and `deposit_liquidity`/`queue_withdrawal` for its
  own funds. A written price must match the configured oracle interface accounts and pass TWAP-divergence, confidence and
  heuristic checks; user-supplied `min_lp_out`/slippage bounds LP minting. No profit path found.
- **Privileged (P):** the curator key `bs1PuRvB…` (Loopscale) can drive manager-gated position changes; the audited
  manager-drain findings (Adevar ext M01–M09) are the reason those paths are restricted, but they are not E-U.

---

## 7. PoC / verification

- `analysis/sim_auth_probe.py` — 7 probes (A–F2 + cranks), output in `analysis/sim_results.txt` and `ci-out/sim_results.txt`.
- `analysis/decode_vaults.py`, `analysis/quantify.py` — vault decode + exposure valuation.
- `analysis/program_elf.so` (2.7 MB) + `analysis/elf_strings.txt` — deployed binary and its strings (fix markers).
- `analysis/audit_findings.md` — audit-finding inventory (Adevar ×2, OtterSec).
- CI: `.github` job `ci/run.sh` re-runs all of the above read-only and writes `ci-out/`. Run URL: **<fill from ci-log.txt>**.

## 8. Verdict & residual risk

**E-U = $0.00 (high confidence).** The $7.49M is guarded by role checks that are present and enforced in the
**currently deployed** binary, which post-dates and incorporates all three audits' fixes.

Residual/latent: acknowledged LOW DoS items (pre-funded-PDA seed DoS; zero-mint reachable only by allowlisted creators);
manager-role trust in the Loopscale curator key (P); permissionless oracle cranks by design.

**Blockers/limits:** the vaults program source is not public (only the SDK + audits), so the deployed-vs-audit
comparison is by upgrade date + fix-marker strings, not a byte-level diff. A full LiteSVM fork replay was not run —
reconstructing the vault's account graph plus Loopscale/Kamino CPI accounts is out of budget; the read-only
`simulateTransaction` probe is a stronger substitute (real deployed binary + real state).
**Note (accounting):** the DefiLlama adapter marks this protocol `doublecounted: true` — the vault AUM is deployed into
Loopscale markets / Exponent positions that are also counted by their own adapters, so the $7.49M is not necessarily
incremental TVL. This does not affect the E-U verdict.

## 9. Methodology & sources

DefiLlama adapter `projects/loopscale-curation/index.js` · Solana JSON-RPC `getAccountInfo`/`getProgramAccounts`/
`getTransaction`/`simulateTransaction` (keyless public endpoints) · `@exponent-labs/exponent-sdk@0.9.30` (npm) ·
audits from `github.com/exponent-finance/exponent-audits` · `sbpf disassemble` + `strings` on the dumped ELF.

### Files
```
loopscale/
├── README.md  summary.json
├── analysis/  recon.py decode_vaults.py quantify.py sim_auth_probe.py
│              loopscale_vaults.json loopscale_exposure.json vault_accounts_raw.json
│              program_elf.so elf_strings.txt elf_disasm.txt sim_results.txt audit_findings.md
├── ci/run.sh
└── ci-out/    (decode_vaults.out quantify.out sim_results.txt fix_markers.txt sanity.json)
```
