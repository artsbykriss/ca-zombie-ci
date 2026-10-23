# ZH4 residual OPEN-B — **Reflect Tranches** (Solana: RLP + Proxy programs)

**Date:** 2026-10-23 · **Chain:** Solana mainnet · **Status:** read-only; **no transaction was signed for broadcast
and none was sent.** Three methods: (a) read-only `simulateTransaction` replays of real on-chain instructions with
`sigVerify=false`, (b) an in-process **LiteSVM** harness loading the deployed program ELFs + cloned mainnet accounts
with a **fresh signer** *and* paired positive controls using the real privileged keys, and (c) static reads of the
deployed ELFs (audit-fix markers).
**Owner:** ZH4 residual-OPEN-B subagent (target 3 of 3).

DefiLlama slug `reflect-tranches` — **$2,759,315**; independently re-derived on-chain **$2,760,673**
(senior $2,349,287.33 + junior $411,385.75) at slot **460,456,908**.

---

## 1. TL;DR

| Target | Live value | Live extractable (unprivileged) | Why closed | Latent risk |
|---|---|---|---|---|
| **Reflect RLP** (junior / insurance fund) `JrXLmS6aYJNJDVxdAfjNJE5wikT8ubf3TA9iL2JA9Av` | **$411,386** junior LP (7 pools) | **$0** | Role system is **SUPREMO**-gated and the gate is *validated*: `update_action_role` → attacker `IncorrectAdmin(6043)`, real **MANAGER** also `6043`, real **SUPREMO** passes the gate (`InvalidInput(6001)`); `freeze_functionality` → attacker `6043` vs SUPREMO `6038` (gate passed); `create_permission_account` is permissionless but yields **zero roles**; `withdraw` binds to `cooldown.authority` (foreign cooldown → `Custom(2015)`) | Single upgrade authority `28sR8pmJ…` (= the only SUPREMO); junior LP stays slashable through the withdrawal cooldown (by design) |
| **Reflect Proxy** (senior tranche) `pRoxYU64BSjv8HbhENna8a7LVCrkzzNrnvbYuTwas8C` | **$2,349,287** senior (84 ProxyStates) | **$0** | `claim_fees` enforces `authority == ProxyState.authority` — **fully validated** (real authority → `[OK]`; role-less third party → `Custom(16)`); `update_authority` likewise (attacker `16` vs real authority `[OK]`); `update_fee`/`accept_authority`/`freeze_*`/`update_oracle`/`migrate_asset` authority-gated; `withdraw` (stable-swap) pinned to admin `KuBAWM6p…` | Single upgrade authority `28sR8pmJ…`; proxy `unwrap` layout not cleanly isolated (medium); pinned admin (docs: "to change in production") |

**Total live extractable now (E-U): $0.00 — confidence: high** for the RLP role system, the foreign-`Cooldown` path and
Proxy `claim_fees`; **medium** only for Proxy `unwrap` (see §6/§7).

---

## 2. What the target is

Reflect Tranches splits a yield-bearing stablecoin (USDC+) into **senior** (the Proxy program: branded, fee-bearing
stablecoins) and **junior** (the RLP program: a liquid insurance fund whose LP is slashed first to cover senior losses).
The DefiLlama adapter values: junior = the RLP pools' per-asset token accounts; senior = each pool's `protected_vault`
(a Proxy `ProxyState`) ATA balance.

| Component | Address | ProgramData | Last upgrade | Upgrade authority |
|---|---|---|---|---|
| RLP (junior) | `JrXLmS6aYJNJDVxdAfjNJE5wikT8ubf3TA9iL2JA9Av` | `FHdpnjuVWkjWAUf34GTArHMDKyKK8A9QCVeDp5z44Nr` | slot 453,581,722 = 2026-10-05 | `28sR8pmJxhtZNci3hPervkxu9f93nvHpFikbtzXoxmWA` |
| Proxy (senior) | `pRoxYU64BSjv8HbhENna8a7LVCrkzzNrnvbYuTwas8C` | `9nVDmUokhJDJ6h2z8MfycSGR5qNDFeo5CqSiJgPLCGX7` | slot 451,679,621 = 2026-09-29 | `28sR8pmJxhtZNci3hPervkxu9f93nvHpFikbtzXoxmWA` |

RLP is Anchor (8-byte `global:` discriminators); Proxy is **Pinocchio** with **1-byte** discriminators
(0 CreateProxy, 1 Wrap, 2 Unwrap, 3 ClaimFees, 4 UpdateFee, 5 UpdateAuthority, 7 CreateAsset, 8 DeactivateAsset,
9 FreezeFee, 11 UpdateDepositCap, 12 FreezeTokenAccount, 13 ThawTokenAccount, 14 UpdateOracle, 15 AcceptAuthority,
16 MigrateAsset, 17 PostOraclePrice, 100 Swap, 101 Withdraw — mapped empirically from the deployed ELF).

The deployed RLP exposes **19** instructions (`InitializeRlp, InitializeLp, InitializePoolReserve, AddAsset,
UpdateDepositCap, Slash, Deposit, RequestWithdrawal, Withdraw, MigrateCooldown, Swap, CreatePermissionAccount,
UpdateActionRole, UpdateRoleHolder, MigrateAsset, UpdateOracle, PostOraclePrice, ForceRemoveAsset, FreezeFunctionality`)
— a superset of the published interface docs, and with **no `deposit_rewards`**.

Live roles (only **three** `UserPermissions` accounts exist on chain):

| PDA | authority | roles |
|---|---|---|
| `8vMwZJqC2YWYH5ixwBS4RM7EVCxqZi55YPN5XYVxk625` | `28sR8pmJ…` (= upgrade authority) | `[SUPREMO]` |
| `CYsYS9JC3jyufisHDDJybjRTNdfwXxftAjiGa1EacUBY` | `KuBAWM6p…` | `[MANAGER]` |
| `GNwSK8YpM85bd2YeJaA2BmUxGVqEe4hyCLqc8eR2PCgt` | `Gx2XuhLE…` | `[]` |

**No `CRANK` holder exists.** Other live singletons: RLP `Settings` `9q89A973AWTkvWi87tKPj8GSw58b6JJhWALCJ1MGXNFc`;
84 ProxyStates (156 B `repr(C)`, authority at 82..114).

---

## 3. Live value

| Tranche | Value (USD) | Source |
|---|---|---|
| Junior (RLP pools) | $411,385.75 | 7 pools' per-asset token accounts |
| Senior (Proxy states) | $2,349,287.33 | 84 ProxyState USDC+/USDC ATAs |
| **Total** | **$2,760,673.08** | `analysis/value_summary.json` (one market `9YEKjRbR…` is unpriced → lower bound) |

Matured unclaimed RLP `Cooldown` escrow ≈ **$70**. ~20 cooldowns are still within their unlock window (junior LP stays
slashable until claimed — by design). No stuck/bricked funds identified.

---

## 4. Correction to the pass-5 lane: the code family **is audited**

The pass-5 lane called the live generation "0 audits". It is audited at `github.com/palindrome-eng/audits`:
Offside Labs **Reflect DeltaNeutral** (Sep 2025), **Reflect Proxy** (Nov 2025, `48d78c2c`→`34ae41c7`), **Reflect Core
Yield Routing** (Feb 2026); Adevar Labs **RLP after-fix** (2026-06-19, `5216e264`→`461b1555`), **RLP oracle-stacking**
and **Proxy oracle-stacking** (2026-10-08 after-fix). The RLP findings (H01 cooldown bypass, M01 `Role::UNSET`
access-control bypass, M04 `Role::PUBLIC` on privileged actions, M07 operator-key slash drain, …) are **Resolved**, and
the deployed ELF (last deploy 2026-10-05) contains the post-fix error strings `MinimumSuperadminsRequired`,
`PoolWipedOut`, `CooldownExpired`, `NoNavLossToCover`, `ProtectedVaultMismatch`.

The published interface docs describe a **different deployment** (`rhLMe6…` RLP does not exist on chain; the documented
proxy has `ProxyState LEN = 115` vs the live 156), so the docs were not used as ground truth.

---

## 5. What an attacker can / cannot do (evidence)

### 5.1 Validated read-only replay (`simulateTransaction`, `sigVerify=false`)

`analysis/sim_real.py` replays a **real** on-chain instruction's exact account list twice: (A) with the real signer
(control) and (B) with the signer replaced by a role-less third-party account.

| Target instruction | Real tx | A: control | B: unprivileged signer | Reading |
|---|---|---|---|---|
| Proxy `claim_fees` (disc 3) | `4jvxMJ9f…` slot 460,231,056 | **success** (`err=None`) | **fails `Custom(16)`** | integrator-authority check present and enforced → **gated** |

### 5.2 LiteSVM harness (`poc/`, CI run 39969562016, `harness exit=0`)

Deployed ELFs + 40 cloned mainnet accounts; sigverify disabled **inside the VM** so a real privileged pubkey can be the
signer for a positive control while a fresh random keypair is the unprivileged case. Paired results:

| Instruction | Unprivileged (fresh / registered-empty-role) | Real privileged key | Reading |
|---|---|---|---|
| `create_permission_account` | **succeeds**, roles tail `000…` | — | permissionless registration grants **no role** |
| `update_action_role(Slash→PUBLIC)` | `IncorrectAdmin(6043)` | **SUPREMO → `InvalidInput(6001)`** (gate passed); MANAGER → `6043` | **role gate validated** |
| `freeze_functionality(Slash)` | `6043` | **SUPREMO → `6038`** (gate passed) | **role gate validated** |
| `slash(pool0,1)` | `Custom(3007)` | SUPREMO `3007` | rejected for attacker (control blocked by pool state) |
| `withdraw` on a foreign matured cooldown | `Custom(2015)` | cooldown's real authority `2015` | rejected for attacker (control not obtained — account closed) |
| Proxy `claim_fees` | `Custom(16)` | **real authority → `[OK]`** | **fully validated** |
| Proxy `update_authority` | `Custom(16)` | **real authority → `[OK]`** | validated |
| Proxy `unwrap` (13 layouts, fresh signer burning a **victim's 963,858-token** position) | all fail | victim balance unchanged in every case | no theft observed (layout not cleanly isolated) |

### 5.3 Static / structural closure

- **Role escalation** — permissionless registration yields an **empty** role set; each privileged handler checks the
  action map against the caller's own seed-bound `UserPermissions` PDA; `Role::UNSET`/`PUBLIC` escalation rejected
  (Adevar M01/M04 fixes present).
- **Oracle-priced `swap` cannot be exercised** — **every live RLP pool holds exactly one asset**
  (`assetIdxs = [x,255,255,255]`), so the RLP `swap` has no two-asset pool to trade against. Prices come from Chainlink
  Data Streams (CPI to verifier `Gt9S41…`) / Pyth `PriceUpdateV2`; a relayer cannot forge a report and stale reports
  are rejected (`OracleReportNotNewer`).
- **Proxy `unwrap`** — SPL Token requires the token-account **owner** (or an approved delegate) to authorize a
  burn/transfer; the Proxy's `proxy_state` PDA is the branded **mint** authority, which is *not* a burn authority over
  third-party accounts. The Nov-2025 Offside proxy audit covered `wrap`/`unwrap` and found no missing-owner-check.
- `Deposit` / `RequestWithdrawal` / `MigrateCooldown` move only the caller's own tokens; `create_proxy` /
  `create_permission_account` create empty objects; all admin/asset/oracle setters are MANAGER/SUPREMO-gated.

---

## 6. Verdict & residual risk

**E-U = $0.00. Confidence: high** for the RLP role system, the foreign-`Cooldown` path and Proxy `claim_fees` /
`update_authority`; **medium** only for Proxy `unwrap`.

**P (privileged):** the single upgrade authority `28sR8pmJ…` (both programs; also the only SUPREMO), the MANAGER key
`KuBAWM6p…` (also the Proxy stable-swap admin), and the proxy integrator authorities (`apyaB89k…` for the largest
state) can move/redirect value by design.

**Residual/latent (not E-U):**
1. **Upgrade keys** — one key upgrades both programs and holds SUPREMO; no timelock observed. Key compromise = $2.76M.
2. **Junior LP remains slashable through the withdrawal cooldown** (by design) — an insurance-fund liveness/economic
   risk, not an exploit.
3. **Proxy pinned admin / oracle** — docs mark `KuBAWM6p…` and the Doppler oracle as "to change in production";
   `withdraw` lets that key drain the stable-swap vaults (P).

**Blockers / tooling limits (honest):**
- Proxy `unwrap` account layout was pinned only late (from a real `Wrap` tx, slot 460,447,739:
  `[user, user_stablecoin_ata, user_branded_ata, proxy_state, proxy_vault, branded_mint, oracle, cfg(259 B),
  token_program, stablecoin_mint]`) and still fails `InvalidAccountData` for both attacker and legitimate owner → the
  unwrap authorisation result is **not cleanly isolated** (medium confidence; closed by static SPL-Token semantics +
  the Offside audit).
- RLP `withdraw` positive control was not obtained: the only observed on-chain `Withdraw` tx references an account
  (`7bhqRJxC…`) that has since been closed. The gate is evidenced by the foreign-cooldown rejection plus the Adevar H01
  remediation.
- `getTokenSupply` / `getProgramAccounts(jsonParsed)` are unsupported on the keyless endpoint used; mint supplies were
  read from raw bytes.
- Point-in-time 2026-10-23; re-read all state before acting. Nothing here is an instruction to transact.

---

## 7. Methodology & files

**Methods.** (1) Locate programs from the DefiLlama adapter; dump deployed ELFs; read upgrade authorities. (2) Enumerate
accounts (`getProgramAccounts`): RLP settings/assets/pools/cooldowns/permissions, Proxy states. (3) Value the tranches
from token balances + DefiLlama prices. (4) Map the Proxy's 1-byte discriminators empirically by simulating each byte
and reading the program's own instruction-name log. (5) Replay real instructions read-only with a role-less signer
(`simulateTransaction`, `sigVerify=false`). (6) Run the paired privileged/unprivileged LiteSVM harness in CI. **No
transaction was signed for broadcast; nothing was sent.**

**Files.**
```
reflect-tranches/
├── README.md  summary.json
├── analysis/  sim_real.py sim_real2.py · value_summary.json live_state.json programs.json
│              raw_layouts.txt proxy.s rlp.s · findings.subagent-b.md (independent deep-dive)
│              docs/ (reflect integrator docs — different generation, see §4)
├── poc/       Cargo.toml src/main.rs (paired LiteSVM harness) accounts.json programs/{rlp,proxy,spl_token,ata}.so
├── ci/run.sh
├── ci-out/    litesvm-auth.txt (harness output) sim_real.txt sim_real2.txt sanity.json
├── ci-log.txt ci-artifacts/
```

**CI:** GitHub Actions **[39969562016](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39969562016)**
(branch `reflect-tranches`, conclusion **success**): built and ran the LiteSVM harness (`harness exit=0`); its output is
reproduced in `ci-out/litesvm-auth.txt` and `ci-log.txt`.

*Prepared 2026-10-23 · ZH4-OPEN-B Reflect Tranches · read-only · no transactions signed or sent.*
