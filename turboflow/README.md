# TurboFlow Perps — `svm-bridge` (Solana) — live-extractable-value assessment

**Date:** 2026-10-26 · **Lane:** ZH4 pass-7 · Solana funded-residual **B** · **Finding id:** `P7-solana-b-turboflow`
**Chains:** Solana (program under test) + BSC (same protocol, message counterparty)
**Status:** **read-only**. No transaction was signed, sent, or broadcast. All exploit evidence is
`simulateTransaction` (`sigVerify:false`, `replaceRecentBlockhash:true`) against **live mainnet state**.
No keys, secrets or keyed RPC URLs appear in this folder.

---

## 1. TL;DR

| Target | Live value now (on-chain, program-controlled) | E-U extractable now | Why closed / open | Latent (P) risk |
|---|---|---|---|---|
| **TurboFlow `svm-bridge`** `HwWQZdX116omFGrygkpng7fTzMbrg6JGpLaoM77cM7vg` | **$348,228.01** (Solana custody: 55,882.01 USDC + 292,345.997 USDT) | **$0** | Every withdrawal/approval path is role-gated (`RoleAdminMismatch` 6001); the deposit destination is a **program-derived PDA** (`ConstraintSeeds` 2006); the hidden legacy path derives **non-existent** PDAs | **P**: upgrade authority `HJbtKYPEum9bMVorEs8DEJUXLXv5XCi3mYuzJ45bYCxK` is an **on-curve plain key** (no on-chain account, 0 signatures ever) → single-key program takeover → drain Solana custody **$348k** (high conf.), forge messages to BSC bridge **$318k** (med.), potentially release Fireblocks MPC custody **~$6.1M** (low) |

## 2. Total live extractable now (external unprivileged attacker): **$0**

Confidence: **high** (every candidate path was simulated against live state and returned an explicit
Anchor authorization/constraint error — see §7).

| Category | USD | Basis |
|---|---|---|
| **E-U** (external unprivileged) | **$0.00** | all value-moving paths gated (proven by sim) |
| **H-O** (holder self-service) | **$0.00** | the only user-facing outflow is the reviewed withdrawal; it requires `REVIEW_ROLE`, so it is not holder-self-service and not attacker-reachable |
| **P** (privileged / governance) | **$348,228.01** (high) … **up to ~$6,660,000** (low) | single on-curve upgrade authority |
| **S** (stuck/bricked) | n/a — nothing is bricked; the legacy `ReviewTokenSolV1` path is simply unusable (uninitialised PDAs) |

Headline **live extractable now = $0.00** (E-U). The only real residual is the **P-class upgrade key**.

## 3. The mechanism, in exact terms (deployed code)

The deployed ELF is the Anchor program `svm-bridge` (metadata `svm_bridge`, source tree
`programs/svm-bridge/src/…` recovered from `.rodata`). Instruction discriminators are
`sha256("global:<snake_case_name>")[:8]`; account discriminators are `sha256("account:<Name>")[:8]`
(verified: `sha256("account:BridgeAccount")[:8] = 73b2b71b3ba95335` matches the live `BridgeAccount`).
No on-chain Anchor IDL is published (`createWithSeed(pid,"anchor:idl",pid) = 6QTWnASp…` → **no account**).

Authority model (confirmed by simulation, not by reading source):

* **Roles live in one `RoleData` account** (`8BXB7nkes…`, 7,292 B): `DEFAULT_ADMIN_ROLE`,
  `PROPOSE_ROLE`, `REVIEW_ROLE`, `TOKEN_ADMIN_ROLE`. Every privileged handler calls a role check that
  reverts with **`RoleAdminMismatch` (6001) "Role admin mismatch."** when the signer lacks the role.
* **`ProposeDeposit` requires `PROPOSE_ROLE`**, **`ReviewToken` requires `REVIEW_ROLE`** (proven, §7).
* **`DepositToken`'s destination is `#[account(seeds = …)]`-derived** — it is not a caller-chosen
  account, so a deposit cannot be redirected (§7.2).
* The bridge PDA `8iquHJQy…` is the SPL **transfer authority** of the custody token accounts; it is a
  program PDA (off-curve), signed only via `invoke_signed` inside the program.
* The hidden legacy `ReviewTokenSolV1` derives its own `custody_token_account`
  (`5nxKEQUFWN1FnCki1RmT7BKuKU2A5bGoTg5KoLVU7svX`, **does not exist**) plus `risk_window_stat`
  (`GMziBUjx…`, **does not exist**) and `address_freq_stat` (`7GWMbRpd…` / `ciswHh5E…`, **do not
  exist**) → the instruction **cannot execute** on the live deployment.

## 4. Live-state assessment (all reads read-only; Solana slot **461,461,199** finalized, 2026-10-26)

Program account (BPFLoaderUpgradeable):

| Field | Value |
|---|---|
| Program | `HwWQZdX116omFGrygkpng7fTzMbrg6JGpLaoM77cM7vg` (executable) |
| ProgramData | `7jn8SF6uUubRsLQP1FHbzzRnQhFAUMFSiw9B6TQN34iC` (704,433 B incl. header ⇒ ELF 704,388 B) |
| **Upgrade authority** | **`HJbtKYPEum9bMVorEs8DEJUXLXv5XCi3mYuzJ45bYCxK` — on-curve, account absent, `getSignaturesForAddress` = 0** |
| Last deploy slot | **433,197,055** |

Program state (enumerated by `getProgramAccounts` + discriminator filter):

| Type | Count | Notable |
|---|---|---|
| `BridgeAccount` | 1 | `2WpgSwhTXohXDxxCMmdaKgdaiuD62H6XreDMvu3PykLS`; the three Pubkey-sized fields at offsets `0x08–0x67` are **all zero** (bridge_admin / operator / allowed_program_id unset — names from ELF strings + third-party recon) → authz is entirely RoleData |
| `RoleData` | 1 | `8BXB7nkesJEu8JwjrAkP7zMYaSzJ6pe8HLf9mbXLSG47` |
| `Custody` | 2 | `5C5TeQcD1ks9GdrM1dveuQsL6K3Ag1terHNrGLWVX2VT`, `E3N2TD2WnuhRDqARrvaynXNFZ1yJ2sWfxAJE4nMY54er` (all-zero fields) |
| `NativeVault` | 1 | `2qbE2KD98t1QPwQpWf3Rg4SP4Lf8AN9deRfMnEfrrma8` — 1,690,880 lamports ≈ rent only ⇒ **no SOL custody** |
| `ProposeAccount` | 2 | `779z6J7…` (local 52 / remote 51), `GkzwkVY…` (local 52 / remote 100) |
| `ReviewAccount` | **5,296** | inbound-transfer records (1,085 B each) |
| `RiskConfig` / `RiskConfigPending` | 1 / 1 | `2V8qS36v…` / `JiaCLpaEx…` |
| `WhitelistEntry`, `WhitelistPendingEntry`, `RiskWindowStat`, `AddressFreqStat`, `AccessControl` | **0 / 0 / 0 / 0 / 0** | the risk/whitelist stat PDAs were **never initialised** |

Role holders (Borsh-decoded `RoleData`; all are **system-owned EOAs**, not program PDAs):

| Role | Members |
|---|---|
| `DEFAULT_ADMIN_ROLE` (2) | `GZhzWVhJtsj7Xg9zUt3JiJXzfJZby8sdpGDfyqZ8GdSq`, `5jGYngxnbgR9MRcDjUKBghKS6Pp8fsFfdj9K28PtCdF`* |
| `PROPOSE_ROLE` (2) | `9jfktqKRQASH8gYyiaLoFnG6u5RG8NsK99qPWVYfmPZ4`, `8HBZe73rjo1euQ1cUu5u3Atnby2wcQqCQ4mLb3BAXmY` |
| `REVIEW_ROLE` (2) | `GUAujt5S2yvnY4HVj5ysiiHfskmLXPkcbVfxcgLVd1is`, `BL7Gdt3NdawD4P3oJFy5ombLWo7knh2hSxLy7z1RXwte` |
| `TOKEN_ADMIN_ROLE` (1) | `AC9KdHpLGPV4tNVBLW9a2xhmXP36zHEbpueKVHaGrvL7` |

\* second admin member decoded from the `RoleData` blob; alignment caveat noted in §9.

**Value (measured, Solana slot 461,461,199; BSC `latest`):**

| Custody | Address | Amount | USD |
|---|---|---|---|
| **Solana custody USDC** (authority = bridge PDA) | `9ayXbTyhkJ49WtG6DA2PCN6EAKtM8DCneMzhJPTMRWcj` | 55,882.011659 | $55,882.01 |
| **Solana custody USDT** | `6hVp2UaWWQwGo2c6yHj39WJWDNenR48GsLGKPzSa7EU2` | 282,344.970921 | $282,344.97 |
| **Solana custody USDT #2** | `Cjhbg8g13QpfVLPvavQjz8RsDMNifyHkLZ8L4b2TCTEw` | 10,001.0261 | $10,001.03 |
| **Solana subtotal (program-controlled)** | | | **$348,228.01** |
| BSC bridge contract | `0x145CD0d5C3dD0eF1405dCf1b4D2BCE7c611625dB` | 28,231.42 USDC + 289,440.03 USDT | $317,671.45 |
| **On-chain subtotal (program/bridge-controlled)** | | | **$665,899.46** |
| Fireblocks MPC vaults (off-chain custody, EOA-owned) | Solana `2ZEku38c…`,`FYmWdMq9…`,`3uCQ76uw…`,`8ckjipCec…`; BSC `0x8757f9E1…`,`0x077Ab3f5…` | 506,099.55 USDT + 5,593,862 USDT | $6,099,961.55 |
| **Total (matches DefiLlama `turboflow-perps` $6,756,251)** | | | **≈ $6,765,861** |

Price assumption: USDC = USDT = $1.00 (stablecoins), 2026-10-26. DefiLlama adapter
(`DefiLlama/DefiLlama-Adapters/projects/turboflow/index.js`) confirms the TVL is exactly
"USDT/USDC held by the BSC bridge contract + Fireblocks MPC vaults + 6 Solana token accounts" — i.e.
**~$6.1M of the headline TVL is off-chain MPC custody, not on-chain program custody**.

## 5. What an attacker can and cannot do (exact call paths)

**CANNOT (all proven by simulation against live state):**

1. **Complete a withdrawal.** `ReviewToken` (disc `b6c03990c1accb27`) with a signer that holds
   `PROPOSE_ROLE` but not `REVIEW_ROLE` →
   `AnchorError caused by account: signer. Error Code: RoleAdminMismatch (6001) … at 13,037 CU`.
   The same transaction with the real reviewer reaches the handler (`review_token.rs:113`,
   `HasReviewed` 6007) — i.e. the role check is the gate and it fires **before** any fund movement.
2. **Redirect a deposit.** `DepositToken` (disc `0b9c60da27a3b413`) with `custody_token_account`
   replaced by any other USDT account →
   `ConstraintSeeds (2006) … custody_token_account … Left: FYmWdMq9… Right: 6hVp2UaWW…`. The
   destination is a **program-derived PDA**; a caller cannot choose it.
3. **Forge a proposal.** `ProposeDeposit` (disc `010a4814fd248a0e`) with a valid derived
   `review_account` PDA and a `REVIEW_ROLE` signer → `RoleAdminMismatch (6001)` ⇒ `PROPOSE_ROLE` required.
4. **Administer the bridge.** `SetContractStatus` (`6536c6cd5ff3eebb`, accounts `[signer,
   bridge_account, role_data]`), `GrantRole` (`daea800f5221ecfd`, `[signer, role_data]`),
   `ApplyRiskConfig` (`88159e4093744f50`, `[signer, role_data, risk_config, risk_config_pending]`) —
   all rejected with `RoleAdminMismatch (6001)` for a role holder that lacks the required admin role.
5. **Use the hidden legacy path.** `ReviewTokenSolV1` (`246e06b47c8fa3e5`) executes its account
   validation but **derives accounts that do not exist on chain**
   (`custody_token_account = 5nxKEQUF…` → `AccountNotInitialized 3012`;
   `risk_window_stat = GMziBUjx…`, `address_freq_stat = 7GWMbRpd… / ciswHh5E…` → all `NULL`,
   and `getProgramAccounts` finds **0** `RiskWindowStat`/`AddressFreqStat`/`WhitelistEntry` accounts).
6. **Extract native SOL.** `ReviewNative` (`51e0c08a25f5b29f`) enforces its `signer` constraint, and
   `NativeVault` holds only rent (1,690,880 lamports) ⇒ nothing to take.

**CAN (by design, permissionless — no attacker value):**

* `DepositToken` / `DepositNative`: any signer may deposit their **own** tokens into the
  program-derived custody account (control sim succeeded: `deposit_nonce 14412 → 14413`, event
  emitted). This only moves the attacker's own funds *into* the protocol.
* Note: a deposit that is never reviewed is not reversible by the depositor on Solana (the Solana→BSC
  leg is settled off-chain by the relayer) — that is a *user* risk (H-O for the depositor only), not
  an attacker-extractable value.

**Cost:** an attacker needs only ~5,000 lamports of fees per rejected attempt; no capital, no flash
loan. Rejected paths cost nothing on-chain (they revert).

## 6. PoC / fork-verification

* Method: **attacker-built legacy messages + `simulateTransaction`** with
  `{"sigVerify":false,"replaceRecentBlockhash":true,"commitment":"processed"}`. `sigVerify:false`
  means the message-level signer flag is honoured without a real signature, so the simulation tests
  **program-level authorization only** — exactly what is in question. All accounts are live mainnet
  accounts; the sim is never broadcast.
* Real transactions were **replayed verbatim** first (control) and then mutated by a single
  substitution (signer / destination account / instruction discriminator) so that any difference in
  outcome is attributable to the mutation.
* Results (all reproduced by `ci/run.sh`):

| # | Test | Control | Attacker | Verdict |
|---|---|---|---|---|
| 1 | `review_token` signer swap | `HasReviewed` 6007 @ review_token.rs:113 | `RoleAdminMismatch` 6001 | **gated** |
| 2 | `deposit_token` dest swap | `null` (success, nonce 14412→14413) | `ConstraintSeeds` 2006 (`custody_token_account`) | **PDA-bound** |
| 3 | `set_contract_status` role | n/a | `RoleAdminMismatch` 6001 | **gated** |
| 4 | `grant_role` role | n/a | `RoleAdminMismatch` 6001 | **gated** |
| 5 | `apply_risk_config` role | n/a | `RoleAdminMismatch` 6001 | **gated** |
| 6 | `propose_deposit` role | n/a | `RoleAdminMismatch` 6001 | **gated** |
| 7 | `review_token_sol_v1` | n/a | `AccountNotInitialized` 3012 (derived custody absent) | **dead path** |
| 8 | `review_native` | n/a | `AccountNotSigner` 3010 (signer constraint) | **gated**, and no SOL held |
| 9 | 1,000-transaction census (slots 458,877,241→461,463,512) | — | only `deposit_token`(677) `propose_deposit`(161) `review_token`(162) | **no admin / native / legacy instruction is in use** |

* CI: the full matrix is reproduced by `ci/run.sh` on GitHub Actions (public repo
  `artsbykriss/ca-zombie-ci`, workflow `poc.yml`, branch `turboflow`).
  **Run: https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40250592489 (conclusion: success).**
  Raw log: `ci-log.txt` (custom-job section) and the uploaded artifact
  `result-turboflow/ci-out/ci-results.txt` under `ci-artifacts/`.
  The CI run re-verified every error code independently on a fresh runner
  (slot **461,464,595**), and re-read live balances (USDT custody 282,612.110921 — the bridge is
  actively receiving deposits, so the Solana custody figure is a moving target of ≈ $348–349k).

Raw CI log excerpts (verbatim, `ci-out/ci-results.txt`):

```
### 3. REVIEW_ROLE gate on review_token
[control]  err={"InstructionError":[0,{"Custom":6007}]} units=31981
           AnchorError thrown in programs/svm-bridge/src/instructions/withdraw/review_token.rs:113.
           Error Code: HasReviewed. Error Number: 6007.
[attacker] err={"InstructionError":[0,{"Custom":6001}]} units=13037
           AnchorError caused by account: signer. Error Code: RoleAdminMismatch. Error Number: 6001.
### 4. deposit_token custody PDA binding
   AnchorError caused by account: custody_token_account. Error Code: ConstraintSeeds. Number: 2006.
   Left:  FYmWdMq9KT87jpZomMQR7Y2r4a2KbEiXkoDJcHMAP1vq
   Right: 6hVp2UaWWQwGo2c6yHj39WJWDNenR48GsLGKPzSa7EU2
### 5-7. set_contract_status / grant_role / apply_risk_config
   ... Role admin mismatch.  Error Number: 6001.
### 8. propose_deposit role gate
   set review_account: dbrv6zgi.. -> FbLPULQdgM8e7zTYYdCr3mjx1hg1LPrRFLrHZr7tddpL
   iter 1: field='signer' msg='Role admin mismatch.' err={"Custom":6001}
### 9. ReviewTokenSolV1 derived accounts
   set custody_token_account: 6hVp2UaWW.. -> 5nxKEQUFWN1FnCki1RmT7BKuKU2A5bGoTg5KoLVU7svX
   iter 2: field='custody_token_account' msg='The program expected this account to be already initialized.'
           err={"Custom":3012}
### 11. enumerate program state
   RiskWindowStat: 0   WhitelistEntry: 0   WhitelistPendingEntry: 0   AddressFreqStat: 0   AccessControl: 0
```
* Local execution: all steps are **light, read-only RPC reads + simulation calls**; no CPU-heavy job
  (no Foundry/anvil/fuzz) was required, hence CI is used only for independent reproduction.

## 7. Verdict and residual / latent risk

* **E-U = $0.00** (high confidence). No external unprivileged path to any of the $348k of Solana
  custody, and none to the $318k BSC bridge contract, was found; every candidate path reverts with an
  explicit Anchor authorization or seeds error.
* **H-O = $0.00.** The reviewed-withdrawal flow is `REVIEW_ROLE`-gated, so it is not user self-service.
* **P — the on-curve upgrade authority (the real finding).**
  `HJbtKYPEum9bMVorEs8DEJUXLXv5XCi3mYuzJ45bYCxK` is **not a PDA** (`on_curve = true`), has **no
  on-chain account**, and has **never signed a transaction** (`getSignaturesForAddress` → 0). A single
  plain ed25519 key therefore controls `BPFLoaderUpgradeable` upgrade authority over the program that
  guards the bridge. This is **not E-U** (it requires the private key), but it is a **single point of
  failure**:
  * high confidence: arbitrary code at the program ID can `invoke_signed` the bridge PDA
    (`8iquHJQy…`) and transfer the **$348,228.01** of Solana custody ATAs to the attacker;
  * medium confidence: it can emit forged deposit/withdrawal events, which the protocol's relayer /
    BSC validator would settle against the BSC bridge contract (**$317,671.45** on-chain);
  * low confidence: with forged settlement instructions it could induce release from the
    **Fireblocks MPC vaults (~$6.1M)** — that depends on off-chain MPC policy, not on the program.
  * **Quantified P exposure: $348,228 (high) → $6,659,861 (low-confidence upper bound).**
* **S:** nothing is bricked for users of the live path; `ReviewTokenSolV1` is simply unusable
  (its derived accounts were never created) — a dead code path, not stuck funds.
* **Blockers / caveats that could change the verdict:** (a) if the upgrade key were held in an
  undisclosed MPC/multisig (it is a single on-curve pubkey, so any such custody would have to be
  off-chain and would not be observable on Solana); (b) if the BSC relayer credits deposits purely
  from program events without re-checking custody balances, the `DepositToken` design would still be
  safe *on Solana* (destination is PDA-bound) — the residual trust is in the relayer, not the program;
  (c) balances are point-in-time and moved during the session (USDT custody grew ≈ 74 USDT in ~20 min).

## 8. Methodology & sources

* Instruction/account discriminators recovered from the deployed ELF
  (`analysis/turboflow.so`, md5-checked against ProgramData by a prior independent recon) and
  **verified against real transaction logs** (`Program log: Instruction: ReviewToken` etc.).
* Account-struct field order recovered by **error-driven probing**: pass a deliberately wrong account
  at each position and read the Anchor `AnchorError caused by account: <field>` message; PDAs are
  recovered from `ConstraintSeeds` `Left:`/`Right:` log lines. (`analysis/probe_fields.py`,
  `analysis/auto_chain.py`.)
* Value read with `getTokenAccountBalance` (Solana) and `eth_call balanceOf` (BSC, keyless
  `bsc-rpc.publicnode.com`).
* Corpus leads (`zombie-hunt-iv/pass7/solana-sui.md` row 8) were re-verified, not trusted. A public
  third-party recon note on the same program (`rickyananda/hermes-skills`,
  `red-teaming/solana-anchor-recon/references/turboflow-svm-bridge-recon-2026-09.md`) was read as an
  untrusted cross-check; its conclusions (no fund-loss bug; authz via RoleData) agree with the
  independent simulation evidence here, and this report adds the **first simulated proof** of the
  role gates, of the deposit PDA-binding, and of the `ReviewTokenSolV1` dead-path.

## 9. Caveats & limitations

1. Solana BPF was **not decompiled**. Instruction semantics were established by
   `simulateTransaction` against live state plus ELF string/source-path recovery — the resulting
   error codes are the evidence, not source reading.
2. `RoleData` is a Borsh blob whose exact record grammar was inferred (role-name/role-name/member
   count/members); the **first member of each role block is unambiguous**, the second admin member
   carries a small alignment uncertainty (flagged `*` in §4).
3. `simulateTransaction(sigVerify:false)` proves *program-level* authorization, not that a signature
   exists. That is the correct test for "can an unprivileged caller do X", and every gated path
   returned the same error a genuinely non-privileged signer would get.
4. The BSC leg was not simulated (out of lane); its value is read-only context for the P-risk.
5. All balances are point-in-time (Solana slot 461,461,199). Re-read before acting.
6. **Endpoints differ in pagination depth.** `solana-rpc.publicnode.com` returned only 195 signatures for
   a `limit:1000` query on this program while `api.mainnet-beta.solana.com` returned the full 1,000 — the
   full census was redone on the official endpoint (`analysis/tx_scan2.py`).
7. Nothing here is an instruction to transact.

## 10. Files

```
turboflow/
├── README.md                     # this report
├── summary.json                  # machine-readable summary (brief §7 schema)
├── analysis/
│   ├── turboflow.so              # deployed ELF (704,388 B) — read-only dump
│   ├── turboflow_strings.txt     # raw strings (source paths, custom errors, ix names)
│   ├── disc.py / discriminators.txt / ix_disc_snake.txt   # Anchor discriminator recovery
│   ├── rpc.py b58.py sim.py solmsg.py probe.py            # helpers (read-only, keyless RPC)
│   ├── scan_state.py state_raw.json dump_state.py         # getProgramAccounts enumeration
│   ├── diff_layout.py revacct_layout.txt                  # ReviewAccount layout inference
│   ├── identify.py role_parse.py role_scan.py role_members.py  # RoleData decode
│   ├── tx_scan.py tx_scan.json tx_scan_1000.log           # signature-page ix census
│   ├── tx_scan2.py tx_scan_full.json tx_scan_full.log     # full 1,000-transaction census (official RPC)
│   ├── sim_swap.py sim_sub.py sim_disc.py sim_replay.py   # replay + mutation harness
│   ├── probe_fields.py auto_chain.py                      # error-driven account-struct recovery
│   ├── live_value.py live_value.json final_state.py final_state.json  # value snapshots
│   ├── enumerate_state.py                                 # account-type census
│   ├── get_tx.py fetch_idl.py scan_idl.py find_swap.py dump_elf.py txl.py
│   └── auth_activity.py                                   # upgrade-authority activity check
├── ci/run.sh                     # reproduces the whole gating matrix on CI
├── ci-out/ci-results.txt         # CI results (full custom-job output)
├── ci-log.txt                    # CI run log (run 40250592489)
└── ci-artifacts/result-turboflow # uploaded artifact contents
```

*Prepared 2026-10-26 · read-only · no tx signed/sent · no secrets in folder.*
