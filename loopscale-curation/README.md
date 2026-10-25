# Loopscale Curation (Solana) — read-only residual audit

**Date:** 2026-10-25 · **Chain:** Solana · **Status:** read-only; `simulateTransaction` (sigVerify:false) only; **no mainnet transaction signed or sent.**

## PRIOR-PARTIAL distinction (important)

Pass-5 (and `zombie-hunt-iv/pass5/new-protocols.md` row 12) assigned **"Loopscale Curation" $7.49M** as the **Loopscale core** lending program `1oopBoJG58DgkUVKkEzKgyG9dvRmpgeEm1AVjoHkF78`. **This report is a different component:** the **curation / roles module** that assigns a **curator role** on top of **Exponent strategy vaults** (`sVau1tXvayVWfotzm9Ahcv2qfnnfRWttt78BCnNC6dD`). Loopscale core is out of scope here and is prior-pass closed. The curation module is the "$7.07M" DefiLlama protocol `loopscale-curation` (double-counted: its AUM is deployed into Loopscale markets and Exponent, both counted by their own adapters).

## TL;DR

| Target | Live extractable (unprivileged) | Why closed | Latent risk |
|---|---|---|---|
| Exponent strategy vaults program `sVau1tXv…` (13 Loopscale-curated vaults) | **$0** | Price/AUM accounts are PDA-seed + explicit-account bound (`ConstraintSeeds` / `MissingPriceAccount` / `InvalidAccountData`); `UpdateTwapPrice` is `InvalidPriceManager` for a non-manager; `QueueWithdrawal` raises `PrivilegeEscalation` for a substituted signer; role changes go through a proposal/Squads governance path | Curator `bs1PuRvB…` is an **on-curve EOA** (key-management risk, P); each vault has its own Squads settings |

**Total live extractable now: $0.00 — confidence HIGH.**

## 1. Mechanism

The "curation" component is a **role assignment**: each Exponent strategy vault stores a `roles` list whose **curator** is set to **Loopscale Asset Curation** (`bs1PuRvB9rBBZkryBjADYvxc2qYh51EVW2fsb1uTiBN`). A curator/manager that can be captured by an unprivileged party — or a permissionless instruction that can inflate the vault NAV/AUM or move funds — would be an E-U drain. This report tests those two paths.

## 2. Live state (slot 461,389,570)

| Item | Value |
|---|---|
| Vaults program | `sVau1tXvayVWfotzm9Ahcv2qfnnfRWttt78BCnNC6dD` (BPFLoaderUpgradeable, programdata `36EV3EKoArMVsWQNonccP68eEN2jRoQdPxj46JjmC4cA`, deployed slot 456,916,574, ELF 2,702,032 B) |
| Upgrade authority | `62zLwJ1xBfsUkhLuBtxgdd8xvhrJ19suDBxviXG95baN` — **off-curve** (PDA/Squads) |
| Total Exponent strategy vaults | 72 |
| **Loopscale-curated vaults** | **13** |
| Curator (all 13) | `bs1PuRvB9rBBZkryBjADYvxc2qYh51EVW2fsb1uTiBN` — **on-curve EOA** (1.47 SOL) |
| Per-vault governance | each vault has its own `squads_settings` + `squads_vault` (distinct per vault) |
| DefiLlama `loopscale-curation` | **$7,075,933.52** (Solana, 2026-10-25) |
| On-chain idle reserves (13 vaults' `token_account_vault`) | ≈ **$25,191** (USDC $19,112 + SOL $3,088 + others); the remainder of AUM is **deployed into Loopscale/Exponent positions** (`aum_in_base_in_positions`) |

The 13 curated vaults: `utJ4Hftd…`, `34VfWz4g…`, `3AME6Z3h…`, `3hM9qdba…`, `4apKX852…`, `5i9ZHcZJ…`, `63q8q952…`, `9iPUphFX…`, `BN97ARPm…`, `BWuXMAUR…`, `CafHV1mn…`, `D6KZ7dKd…`, `EsTx9ToY…`.

## 3. What an attacker can / cannot do (simulateTransaction, sigVerify:false)

Neutral unprivileged funded signer `5tzFkiKscXHK5ZXCGbXZxdw7gTjjD1mBwuoFbhUvuAi9`; real program accounts. Instruction tags recovered from the deployed ELF/logs (`UpdatePrice`=0x07, `UpdateTwapPrice`=0x1a, `RefreshAum`=0x27, `DepositLiquidity`=0x01, `QueueWithdrawal`=0x04, `ExecuteWithdrawal`=0x06).

| # | Instruction | Attacker action | Result | Verdict |
|---|---|---|---|---|
| 1 | `UpdatePrice` | control | `err: null` | permissionless price push from bound feed accounts |
| 2 | `UpdatePrice` | substitute `exponent_prices` PDA (idx0) | `Custom 2006 ConstraintSeeds` | **PDA-bound** |
| 3 | `UpdatePrice` | substitute price entry (idx1) | `Custom 6085 InvalidAccountData` | **entry-bound** |
| 4 | `UpdatePrice` | substitute price feed (idx4) | `Custom 6070 MissingPriceAccount` | **feed-bound** |
| 5 | `UpdateTwapPrice` | neutral signer (idx0) | `Custom 6068 InvalidPriceManager` | **gated to price manager** |
| 6 | `RefreshAum` | neutral signer | `Custom 6080 StalePriceData` (no signer; input-free recompute) | **no arbitrary value** |
| 7 | `QueueWithdrawal` | substitute signer | `PrivilegeEscalation` (CPI unauthorized signer) | **gated to owner** |
| 8 | `ExecuteWithdrawal` | reached handler | account-state checks (AccountNotInitialized on replay) | gated |

The vault program exposes a full **proposal system** (`InitProposal`/`ActivateProposal`/`ExecuteProposal`/`FinalizeProposal`) and per-vault **Squads** settings; role/policy changes (`AddPolicy`/`UpdatePolicy`/`SyncPolicyAuthorities`) run through that governance path, not a permissionless call.

## 4. Verdict and residual/latent risk

- **E-U: $0.00 — HIGH confidence.** No permissionless path mutates the curator/manager role or the NAV/AUM with attacker-controlled value; price accounts are strictly bound; withdrawal requires the owner signer.
- **P:** the **curator is a single on-curve EOA** (`bs1PuRvB…`); compromise of that key, or of the off-curve upgrade authority `62zLwJ1x…`, is a governance/key-management risk, not an unprivileged path.
- **Not re-reported:** Loopscale core (`1oopBoJG…`), Exponent core (`ExponentnaRg…`) and Exponent v2 (`XPC1MM4d…`) are prior-pass closed clusters.

## 5. PoC / reproduction

- `analysis/loopscale_probe.py` — live state + gating matrix + vault value (stdlib only). Writes `ci-out/loopscale_results.json`.
- `analysis/exponent_ixscan.py` — recent-instruction tag scan; `analysis/exponent_gating.py` — per-tag replay with neutral signer.
- `analysis/soltx.py`, `analysis/pda.py`, `analysis/solrpc.py` — simulation/PDAs/RPC helpers.
- `analysis/exponent_instructions.txt` — 35 instruction names recovered from the ELF.
- Run: `bash ci/run.sh`.

## 6. Methodology, caveats, files

Read-only JSON-RPC (`getAccountInfo`, `getProgramAccounts`, `getSignaturesForAddress`, `getTransaction`, `simulateTransaction` sigVerify:false). Slot recorded. The vault struct layout has version drift (`MigrateVaultLayout` exists) so the full AUM was not byte-decoded; the value figure is DefiLlama's `loopscale-curation` AUM and the live idle-reserve cross-check (~$25k), which does not affect the structural gating verdict. The curator pubkey was located by byte-scan in each vault and confirmed on-curve.

Files: `README.md`, `summary.json`, `analysis/*`, `poc/README.md`, `ci/run.sh`, `ci-out/*`, `ci-log.txt`.

*Prepared 2026-10-25 · ZH4 p7-solana-c · read-only · no tx signed/sent.*
