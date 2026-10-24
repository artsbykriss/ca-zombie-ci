# reflect-tranches — subagent-b findings (independent deep-dive)

**Date:** 2026-10-23 · **Mode:** READ-ONLY (keyless public RPC; LiteSVM in-process VM only; **no tx signed for broadcast, none sent**) · **Scope:** the live *Reflect Tranches* deployment on Solana — RLP `JrXLmS6aYJNJDVxdAfjNJE5wikT8ubf3TA9iL2JA9Av` (junior) + shared Reflect proxy `pRoxYU64BSjv8HbhENna8a7LVCrkzzNrnvbYuTwas8C` (senior), both upgrade authority `28sR8pmJxhtZNci3hPervkxu9f93nvHpFikbtzXoxmWA`.

> This file is the subagent-b deliverable. The parent owns `README.md` / `summary.json` / `ci/run.sh`; those were left untouched (and restored from the parent's copies after an accidental overwrite — see §8).

---

## 1. Verdict

**E-U = $0 live.** Confidence **high** for the RLP role system, the foreign-`Cooldown` path and proxy `claim_fees`; **medium** for proxy `unwrap`.

Live value in scope at slot **460 456 908**: senior `ProxyState` vaults **$2,349,287.33** + junior RLP pool vaults **$411,385.75** = **$2,760,673.08** (DefiLlama reports $2.73–2.85 M). One market (`9YEKjRbR…`) is unpriced, so this is a lower bound. Matured unclaimed RLP `Cooldown` escrow ≈ **$70**.

## 2. Two corrections to the pass-5 lane

1. **Not "0 audits".** Six published reports cover the deployed code family at `github.com/palindrome-eng/audits`: Offside Labs *Reflect DeltaNeutral* (Sep 2025), *Reflect Proxy* (Nov 2025, commit `48d78c2c` → fix `34ae41c7`), *Reflect Core Yield Routing* (Feb 2026); Adevar Labs *RLP after-fix* (2026-06-19, `5216e264` → `461b1555`), *RLP oracle-stacking* (2026-10-08 after-fix), *Proxy oracle-stacking* (2026-10-08 after-fix). The RLP findings (H01 cooldown bypass, M01 `Role::UNSET` access-control bypass, M04 `Role::PUBLIC` on privileged actions, M07 operator-key slash drain, …) are all Resolved, and the deployed ELF (last deploy **2026-10-05**, slot 453 581 722) contains the post-fix error strings `MinimumSuperadminsRequired`, `PoolWipedOut`, `CooldownExpired`, `NoNavLossToCover`, `ProtectedVaultMismatch`.
2. **The published interface docs describe a different deployment.** `rhLMe6vyM1wVLJaxrWUckVmPxSia58nSWZRDtYQow6D` (documented RLP) **does not exist on chain**; the documented proxy `ProxycrBk…` has `ProxyState LEN = 115`, while the live tranches proxy `pRoxYU64…` has `LEN = 156`. The deployed RLP exposes **19** instructions (superset of the documented 15) and has **no `deposit_rewards`**.

## 3. Instruction surface recovered from the deployed ELFs (not the docs)

RLP (`Instruction: <Name>` log strings, discriminators confirmed by disc-only probing): `InitializeRlp, InitializeLp, InitializePoolReserve, AddAsset, UpdateDepositCap, Slash, Deposit, RequestWithdrawal, Withdraw, MigrateCooldown, Swap, CreatePermissionAccount, UpdateActionRole, UpdateRoleHolder, MigrateAsset, UpdateOracle, PostOraclePrice, ForceRemoveAsset, FreezeFunctionality`.

Anchor account discriminators (verified): `Asset eab4f1fc8be0a008` (266 B), `LiquidityPool 42261140bc504481` (105 B), `Cooldown 32a65ec0ea4098d0` (168 B), `UserPermissions c3ad502028d84e6e` (55 B), `StreamPrice 19bdbb56fbf97b5d` (75 B), `Settings dfb3a3beb1e043ad` (379 B).

Proxy (Pinocchio, **1-byte** discriminator, verified by sending each byte and reading the log): `0 Create Proxy, 1 Wrap, 2 Unwrap, 3 Claim Fees, 4 Update Fee, 5 Update Authority, 7 Create Asset, 8 Deactivate Asset, 9 Freeze Fee, 11 Update Deposit Cap, 12 Freeze Token Account, 13 Thaw Token Account, 14 Update Oracle, 15 Accept Authority, 16 Migrate Asset, 17 Post Oracle Price, 100 Swap, 101 Withdraw`. Accounts: 84 × `ProxyState` (156 B raw `repr(C)`; `authority` at 82..114), 13 × 259 B `Asset` registry records (oracle legs at offset 40), 2 × 75 B `StreamPrice`.

## 4. The role system — the classic E-U surface

Only **three** `UserPermissions` accounts exist on chain (decoded from `["permissions", authority]` seeds + Borsh `disc ‖ bump ‖ authority ‖ Vec<Role>`):

| PDA | authority | roles |
|---|---|---|
| `8vMwZJqC2YWYH5ixwBS4RM7EVCxqZi55YPN5XYVxk625` | `28sR8pmJ…` (= upgrade authority) | `[SUPREMO]` |
| `CYsYS9JC3jyufisHDDJybjRTNdfwXxftAjiGa1EacUBY` | `KuBAWM6p…` | `[MANAGER]` |
| `GNwSK8YpM85bd2YeJaA2BmUxGVqEe4hyCLqc8eR2PCgt` | `Gx2XuhLE…` | `[]` |

**No `CRANK` holder exists**, so `slash` is reachable only through whatever the SUPREMO/MANAGER role sets are mapped to — the Adevar M07 “repeated ≤10 %/tx slash” risk is not armed by any dedicated key.

## 5. Evidence

### 5.1 Live read-only probes (`simulateTransaction`, `sigVerify=false`)

- `create_permission_account(new_admin = fresh signer)` → **SUCCEEDS** (err `null`, 25 637 CU): registration is permissionless.
- `update_role_holder` / `update_action_role` / `slash` / `freeze_functionality` with a fresh signer → **FAIL** `AnchorError AccountNotInitialized (3012)` on the caller's `permissions` / `admin_permissions`.
- With the **real** privileged pubkeys as signers (`sigVerify=false`): `update_action_role` signed by the real **MANAGER** → `Custom(6043) IncorrectAdmin`; signed by the real **SUPREMO** → `Custom(6001) InvalidInput` (i.e. it **passes the role gate** and only fails argument validation). `freeze_functionality` by the real SUPREMO → `Custom(6038) ActionNotFound` (gate passed).

### 5.2 LiteSVM harness (`poc/`, CI run [39969562016](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39969562016), `[ci] harness exit=0`)

Deployed ELFs + 40 cloned mainnet accounts; **sigverify disabled inside the VM** so a real privileged pubkey can be the signer for a positive control while a fresh random keypair is the unprivileged case.

```
[OK ] create_permission_account(attacker)
      attacker UserPermissions roles tail = 0000000000000000000000000000      <-- empty roles
[ERR] update_action_role attacker (registered, EMPTY roles) -> Custom(6043) IncorrectAdmin
[ERR] update_action_role real MANAGER                      -> Custom(6043) IncorrectAdmin
[ERR] update_action_role real SUPREMO                      -> Custom(6001) InvalidInput   (gate passed)
[ERR] freeze_functionality attacker -> Custom(6043) | real SUPREMO -> Custom(6038) (gate passed)
[ERR] withdraw attacker on a cooldown it does not own -> Custom(2015)   (Anchor token-owner constraint)
[ERR] withdraw cooldown's real authority              -> Custom(2015)   (account list incomplete; see §7)
[ERR] proxy claim_fees attacker            -> Custom(16)
[OK ] proxy claim_fees real proxy authority (positive control)            <-- gate fully validated
[ERR] proxy update_authority attacker -> Custom(16) | real authority -> [OK]
proxy unwrap, 13 candidate layouts, fresh signer burning a VICTIM's 963,858-token senior
      position: all fail; victim branded balance unchanged in every case
```

## 6. Paths closed

- **Role escalation** — permissionless registration yields an **empty** role set; every privileged handler checks the action map against the caller's own seed-bound `UserPermissions` PDA; `Role::UNSET`/`PUBLIC` escalation is rejected (Adevar M01/M04 fixes present).
- **Foreign `Cooldown` withdrawal** — `withdraw` binds the cooldown to `cooldown.authority`; a foreign matured cooldown is rejected (`Custom(2015)`). At stake ≈ $70.
- **Proxy `claim_fees`** — `signer == ProxyState.authority`; validated by a successful control with the real authority and failure (`Custom(16)`) for a third party.
- **Oracles** — prices come from Chainlink Data Streams (CPI to the verifier `Gt9S41…`) / Pyth `PriceUpdateV2` owned by `rec5EKMGg6…`; a relayer cannot forge a report and stale reports are rejected (`OracleReportNotNewer`). Moreover **every live RLP pool holds exactly one asset** (`assetIdxs = [x,255,255,255]`), so the RLP `swap` cannot be exercised against live pools at all.
- `Deposit` / `RequestWithdrawal` / `MigrateCooldown` move only the caller's own tokens; `create_proxy` / `create_permission_account` create empty objects; all admin/asset/oracle setters are MANAGER/SUPREMO-gated.

## 7. Material uncertainty

1. **Proxy `unwrap` (medium).** The account layout was pinned only late, from a real `Wrap` tx (slot 460 447 739): `[user, user_stablecoin_ata, user_branded_ata, proxy_state, proxy_vault, branded_mint, oracle, cfg(259 B), token_program, stablecoin_mint]`. With that shape the harness still fails with `InvalidAccountData` for both the attacker and the legitimate owner, so the authorisation result is *not* cleanly isolated; the deployed proxy is also the older shared program, not the one the current interface docs describe. Note the general SPL-Token fact that a **mint authority can burn from any token account**, so this path must be closed by an explicit owner check in the program. The Nov-2025 Offside proxy audit covered `wrap`/`unwrap` and found no missing-owner-check.
2. **RLP `withdraw` positive control not obtained.** The only observed on-chain `Withdraw` tx references one account (`7bhqRJxC…`) that has since been closed, so a fully-validated control could not be built; the gate is evidenced by the foreign-cooldown rejection plus the Adevar H01 remediation.
3. `getTokenSupply` / `getProgramAccounts(jsonParsed)` are unsupported on the keyless endpoint used; mint supplies/holder lists were read from raw account bytes. `getSignaturesForAddress` returns no history for the pool-0 branded mint or its holder ATAs.
4. Snapshot only (slot 460 456 908); re-read state before acting.

## 8. Housekeeping

An accidental overwrite of the parent's `README.md` / `summary.json` occurred while drafting; both were **restored byte-for-byte** from the parent's copies (backups also at `/tmp/opencode/parent-{readme,summary}-backup.*`). `ci/run.sh` was never modified. Nothing here is an instruction to transact.
