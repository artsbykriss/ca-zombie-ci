# ZH4 residual OPEN-B — **Reflect Tranches** (Solana: RLP + Proxy programs)

**Date:** 2026-10-23 · **Chain:** Solana mainnet · **Status:** read-only; **no transaction was signed for broadcast
and none was sent.** Two independent methods were used: (a) read-only `simulateTransaction` replays of real on-chain
transactions with `sigVerify=false`, and (b) an in-process **LiteSVM** harness that loads the deployed program ELFs plus
cloned mainnet accounts and exercises each value/role instruction with a **fresh signer**.
**Owner:** ZH4 residual-OPEN-B subagent (target 3 of 3).

DefiLlama slug `reflect-tranches` — **$2,759,315**; independently re-derived on-chain **$2,760,673**
(senior $2,349,287.33 + junior $411,385.75) at slot **460,466,328**.

---

## 1. TL;DR

| Target | Live value | Live extractable (unprivileged) | Why closed | Latent risk |
|---|---|---|---|---|
| **Reflect RLP** (junior / insurance fund) `JrXLmS6aYJNJDVxdAfjNJE5wikT8ubf3TA9iL2JA9Av` | **$411,386** junior LP across 7 pools | **$0** | Role system is `SUPREMO`-gated: `update_role_holder` / `update_action_role` / `freeze_functionality` / `slash` / `deposit_rewards` all reject a fresh signer (LiteSVM: `Custom(3005)/(3007)/(3012)`); `create_permission_account` is permissionless **but the created account carries zero roles** (roles tail `000…`); `withdraw` is bound to the cooldown's `authority` (foreign cooldown → `Custom(2015)`) | Single upgrade authority `28sR8pmJ…`; oracle-priced `swap` (0 audits on this generation); junior LP stays slashable through the withdrawal cooldown (by design) |
| **Reflect Proxy** (senior tranche) `pRoxYU64BSjv8HbhENna8a7LVCrkzzNrnvbYuTwas8C` | **$2,349,287** senior (84 ProxyStates) | **$0** | `claim_fees` enforces `authority == ProxyState.authority` — **validated** (control with the real authority succeeds; the same tx with a role-less third-party signer fails `Custom(16)`); `update_fee`/`update_authority`/`accept_authority`/`freeze_*`/`update_oracle`/`migrate_asset` are authority-gated; `withdraw` (stable-swap) is pinned to the admin key `KuBAWM6p…` | Single upgrade authority `28sR8pmJ…`; pinned admin `KuBAWM6p…` (docs: "to change in production") |

**Total live extractable now (E-U): $0.00 — confidence: medium.**

Confidence is **medium** (not high) because the LiteSVM *positive controls* for the RLP role-mutation and `withdraw`
gates did not pass (their hand-built account layouts were incomplete), so those two gates are **indicated by rejection
plus static reasoning** rather than by a fully validated control. The Proxy `claim_fees` gate *is* fully validated.
The live RLP/Proxy programs have **0 public audits**.

---

## 2. What the target is

Reflect Tranches splits a yield-bearing stablecoin into **senior** (the Proxy program: branded, fee-bearing stablecoins
backed by USDC+) and **junior** (the RLP program: a liquid insurance fund whose LP is slashed first to cover senior
losses). The DefiLlama adapter values: junior = the RLP pools' per-asset token accounts; senior = each pool's
`protected_vault` (a Proxy `ProxyState`) ATA balance.

| Component | Address | ProgramData | Last upgrade | Upgrade authority |
|---|---|---|---|---|
| RLP (junior) | `JrXLmS6aYJNJDVxdAfjNJE5wikT8ubf3TA9iL2JA9Av` | `FHdpnjuVWkjWAUf34GTArHMDKyKK8A9QCVeDp5z44Nr` | slot 453,581,722 = 2026-10-05 | `28sR8pmJxhtZNci3hPervkxu9f93nvHpFikbtzXoxmWA` |
| Proxy (senior) | `pRoxYU64BSjv8HbhENna8a7LVCrkzzNrnvbYuTwas8C` | `9nVDmUokhJDJ6h2z8MfycSGR5qNDFeo5CqSiJgPLCGX7` | slot 451,679,621 = 2026-09-29 | `28sR8pmJxhtZNci3hPervkxu9f93nvHpFikbtzXoxmWA` |

RLP is Anchor (8-byte `global:` discriminators); Proxy is **Pinocchio** with **1-byte** discriminators
(0 CreateProxy, 1 Wrap, 2 Unwrap, 3 ClaimFees, 4 UpdateFee, 5 UpdateAuthority, 7 CreateAsset, 8 DeactivateAsset,
9 FreezeFee, 11 UpdateDepositCap, 12 FreezeTokenAccount, 13 ThawTokenAccount, 14 UpdateOracle, 15 AcceptAuthority,
16 MigrateAsset, 17 PostOraclePrice — mapped empirically from the deployed ELF's instruction-name log, see §7).

Live singletons / roles (read at slot 460,466,328):

| Item | Address |
|---|---|
| RLP `Settings` (PDA `["settings"]`) | `9q89A973AWTkvWi87tKPj8GSw58b6JJhWALCJ1MGXNFc` |
| RLP `UserPermissions` SUPREMO | `8vMwZJqC2YWYH5ixwBS4RM7EVCxqZi55YPN5XYVxk625` |
| RLP `UserPermissions` MANAGER | `CYsYS9JC3jyufisHDDJybjRTNdfwXxftAjiGa1EacUBY` |
| Proxy states | **84** `ProxyState` PDAs; integrator authority of the largest = `apyaB89kiVoc1xfYiYAMmRDB2M1qSYYdHy7psv5pPwE` |
| Proxy stable-swap admin (pinned) | `KuBAWM6pZ43ip8b7eB3kjJwUqdPwYpSuoCFkn4bcLgw` |

---

## 3. Live value

| Tranche | Value (USD) | Source |
|---|---|---|
| Junior (RLP pools) | $411,385.75 | 7 pools' per-asset token accounts (mints `AvZZF1Ya…`, `3b8X44fL…`, `2uxaYT1f…`, `HnnGv3Hr…`, `9YEKjRbR…`) |
| Senior (Proxy states) | $2,349,287.33 | 84 ProxyState USDC+/USDC ATAs |
| **Total** | **$2,760,673.08** | `analysis/value_summary.json` |

Matured cooldowns are near-zero value; ~20 cooldowns are still within their unlock window (junior LP stays slashable
until claimed — by design). No stuck/bricked funds identified.

---

## 4. Instruction surface & authorization model

**RLP (Anchor).** User: `restake` (deposit), `request_withdrawal` + `withdraw` (two-step, cooldown-bound),
`swap` (oracle-priced). Crank (CRANK role): `deposit_rewards`, `slash`. Admin (MANAGER/SUPREMO):
`initialize_rlp`/`initialize_lp`/`add_asset`/`update_deposit_cap`/`freeze_functionality`/`create_permission_account`/
`update_role_holder`/`update_action_role`. A `Cooldown` PDA is `["cooldown", authority, pool_id, cooldown_id]` and
carries the withdrawer's `authority`; the RLP `Settings` holds the `action → role` map.

**Proxy (Pinocchio).** Integrator: `create_proxy`/`update_fee`/`update_authority`/`accept_authority`/`claim_fees`;
user: `wrap`/`unwrap` (virtual-offset share math, `VIRTUAL_SHARES = VIRTUAL_ASSETS_USDC = 1_000_000` per the
integrator docs); protocol: `swap` (permissionless, oracle-priced, 1 bp fee) and `withdraw` (pinned admin).

---

## 5. What an attacker can / cannot do (evidence)

### 5.1 Validated read-only replay (`simulateTransaction`, `sigVerify=false`)

`analysis/sim_real.py` replays a **real** on-chain instruction's exact account list twice: (A) with the real signer
(control) and (B) with the signer replaced by a role-less third-party account.

| Target instruction | Real tx | A: control | B: unprivileged signer | Reading |
|---|---|---|---|---|
| Proxy `claim_fees` (disc 3) | `4jvxMJ9f…` slot 460,231,056 | **success** (`err=None`) | **fails `Custom(16)`** | the integrator authority check is present and enforced → **gated** |

(`analysis/sim_real2.py` additionally replays whole transactions; for the Proxy tx the control aborts on an unrelated
3rd instruction — an RLP `Deposit` — but the substituted-signer run still isolates the Proxy gate and shows
`Custom(16)`.)

> The RLP `withdraw` replay could not be used: the real tx at slot 460,429,494 *closed* its cooldown and escrow, so
> those accounts no longer exist and the replay fails on `AccountNotInitialized` for both control and unprivileged
> (a stateful-replay limitation, documented honestly). The RLP withdraw gate is covered by the LiteSVM harness (§5.2).

### 5.2 LiteSVM harness (`poc/`, run in CI)

Loads the deployed `rlp.so` + `proxy.so` + SPL Token/ATA, 40 cloned accounts, a synthetic clock, and a **fresh random
signer** with an airdrop. Results (harness exit 0):

| Test | Result |
|---|---|
| `create_permission_account` (fresh attacker) | **succeeds** — but the created `UserPermissions` **roles tail = `0000000000000000000000000000`** (no role granted) |
| `update_role_holder(CRANK)` as attacker | rejected `Custom(3012)` |
| `update_role_holder(UNSET)` as attacker | rejected `Custom(3012)` |
| `update_action_role(Slash → PUBLIC)` as attacker | rejected `Custom(3005)` |
| `slash(1 unit)` as attacker | rejected `Custom(3007)` |
| `freeze_functionality(Slash)` as attacker | rejected `Custom(3005)` |
| `withdraw(attacker)` on a foreign matured cooldown | rejected `Custom(2015)` |
| Proxy `claim_fees` as attacker | rejected `Custom(16)` |
| Proxy `unwrap` layout matrix (13 layouts) | all rejected (layout/account errors) |

**Harness caveats (important):** the positive controls for `update_role_holder` (synthesized SUPREMO perms account)
and for `withdraw` (rewriting `cooldown.authority`) **failed** — the hand-built account layouts/patches were incomplete
(`Custom(3008)` / `Custom(3012)`, and the patched `proxy_state` became `InvalidAccountData`). So those two gates are
supported by *rejection + static reasoning*, not by a passing control. The victim branded account used by the `unwrap`
matrix had a **zero balance** in the clone, so that matrix could not have demonstrated theft anyway.

### 5.3 Static reasoning

- **Proxy `unwrap` cannot consume a victim's branded tokens even without an owner check:** SPL Token `burn`/`transfer`
  require the token account's **owner** (or an approved delegate) to sign. The Proxy's `proxy_state` PDA is the branded
  **mint** authority, which is *not* a burn/transfer authority over other accounts' balances. So passing a third
  party's branded account as the source cannot succeed.
- **RLP `create_permission_account` grants nothing by itself** (verified: roles tail all-zero); privilege requires
  `update_role_holder`, which is SUPREMO-gated.

---

## 6. Verdict & residual risk

**E-U = $0.00 (confidence: medium).** No unprivileged extraction path was found. The only fully control-validated
gate is the Proxy `claim_fees` authority check; the RLP role-mutation and withdraw gates are rejected for an
unprivileged signer and are SUPREMO/cooldown-authority-bound by construction, but their harness positive controls did
not pass, and this generation of both programs has **0 public audits** — hence medium, not high.

**P (privileged):** the single upgrade authority `28sR8pmJ…` (both programs) and the RLP SUPREMO/crank keys, and the
Proxy admin `KuBAWM6p…`, can move/redirect value by design.

**Residual/latent (not E-U):**
1. **Upgrade keys** — one key upgrades both programs; no timelock observed. Key compromise = $2.76M.
2. **Oracle-priced `swap` (RLP)** — permissionless; if the Pyth/Switchboard validation or swap math is wrong, it is a
   drain vector. Not proven; the deployed RLP has no audit. **Highest-value follow-up.**
3. **Junior LP remains slashable through the withdrawal cooldown** (by design) — an insurance-fund liveness/economic
   risk, not an exploit.
4. **Proxy pinned admin / oracle** — docs mark `KuBAWM6p…` and the Doppler oracle as "to change in production";
   `withdraw` lets that key drain the stable-swap vaults (P).

**Blockers / tooling limits:**
- The Reflect integrator docs the corpus/mirror expose describe a **different (newer) generation** of programs
  (`ProxycrBk…` / `rhLMe6…` / `moCKes…`) than the live DefiLlama-tracked ones (`pRoxYU64…` / `JrXLmS6a…`), so the docs
  could not be used as ground truth; all conclusions come from the deployed ELFs + live state.
- The RLP `withdraw` and Proxy `unwrap` account layouts were not fully recovered, so those two instructions are the
  weakest links in the evidence (see §5.1/§5.2). Both were only ever *rejected* for an unprivileged caller.
- Point-in-time 2026-10-23; re-read all state before acting. Nothing here is an instruction to transact.

---

## 7. Methodology & files

**Methods.** (1) Locate programs from the DefiLlama adapter; dump the deployed ELFs via `getAccountInfo` and read
upgrade authorities. (2) Enumerate accounts (`getProgramAccounts`): RLP settings/assets/pools/cooldowns/permissions,
Proxy states. (3) Value the tranches from token-account balances + DefiLlama prices. (4) Map the Proxy's 1-byte
discriminators empirically by simulating each byte and reading the program's own instruction-name log. (5) Replay real
transactions read-only with a role-less signer (`simulateTransaction`, `sigVerify=false`). (6) Run the LiteSVM harness
in CI. **No transaction was signed for broadcast; nothing was sent.**

**Files.**
```
reflect-tranches/
├── README.md  summary.json
├── analysis/  sim_real.py sim_real2.py (validated replays) · value_summary.json live_state.json
│              programs.json cooldowns.json prices.json raw_layouts.txt proxy.s rlp.s
│              docs/ (reflect integrator docs — newer generation, see caveat)
├── poc/       Cargo.toml src/main.rs (LiteSVM harness) accounts.json programs/{rlp,proxy,spl_token,ata}.so
├── ci/run.sh
├── ci-out/    litesvm-auth.txt (harness output from CI)
├── ci-log.txt ci-artifacts/
```

**CI:** GitHub Actions **[39967195978](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39967195978)**
(branch `reflect-tranches`, conclusion **success**): `ci/run.sh` built and ran the LiteSVM harness
(`harness exit=0`) and uploaded `result-reflect-tranches`; the harness output is reproduced in
`ci-out/litesvm-auth.txt` and `ci-log.txt`.

*Prepared 2026-10-23 · ZH4-OPEN-B Reflect Tranches · read-only · no transactions signed or sent.*
