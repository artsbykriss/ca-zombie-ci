# Streamflow — Solana stake / vesting programs — external-unprivileged extraction study

**Date:** 2026-10-25 · **Chain:** Solana (mainnet-beta) · **Lane:** ZH4 pass-7, Solana row 7
**Status:** READ-ONLY. No transaction was signed or sent. Every result below comes from public
keyless JSON-RPC reads (`getAccountInfo`, `getProgramAccounts`, `getMultipleAccounts`,
`getSignaturesForAddress`) and from `simulateTransaction` on **attacker-built messages**
(`sigVerify:false`, `replaceRecentBlockhash:true`). Nothing here is an instruction to transact.

---

## 1. TL;DR

| Target | Live value (DL/on-chain) | Live extractable by an external unprivileged attacker | Why closed | Latent risk |
|---|---|---|---|---|
| **Stake program** `STAKEvGq…` (1182 pools, 63 529 entries) | staked tokens in 1182 pool vaults (mostly unpriced memecoins; DL `Solana-staking` = **$0.44M** STREAM) | **$0.00 — proven** | every value-moving ix requires a signer that is the pool authority / entry authority / the **hard-pinned** Streamflow worker; `vault`/`mint`/`stake_mint` are `has_one`-bound to the pool (sims → `6008`/`6011`); entry authority checked (sims → `6005 Unauthorized`) | program is **upgradeable** (auth `5u7o2WGg…`, off-curve PDA) → P-class; worker hot key `wdrwhn…` (on-curve, 2.08 SOL) for opt-in auto-unstake |
| **Reward programs** `RWRDdf…` + `RWRDyf…` (1202 pools, 29 009 entries) | reward vaults (mostly unpriced memecoins) | **$0.00 — proven** | `claim_rewards` requires the stake-entry authority **and** a `to` token account owned by that authority (sim → `2015 ConstraintTokenOwner`); vault `has_one` (sim → `6005 InvalidRewardVault`); `clawback` authority-gated (sim → `6003 Unauthorized`) | pool authority can `clawback` unclaimed rewards (P-class) |
| **Vesting / stream program** `strmRq…` (76 050 contracts) | vesting escrows (DL `Solana-vesting` ≈ **$625M** nominal; DL `Solana` core ≈ **$11.85M**) | **$0.00 — proven** | `withdraw` requires the **recipient** (or sender where enabled) as signer: attacker-as-authority sim → `InvalidAccountData`; **recipient control sim → SUCCESS** | upgradeable (same off-curve auth); `wdrwhn…` auto-claim withdrawor |
| **Governor / fee-manager** `GVERN…` / `FEELz…` | none | **$0.00** | all ixs authority-gated | P-class |

## 2. Total live extractable now: **$0.00** — confidence **high**

An external, unprivileged attacker (no authority keys, no Streamflow worker key, no upgrade
authority) can extract **$0.00** from the Streamflow stake, reward and vesting programs as deployed
at slot **461 362 807**. This is a *proven negative*, not an absence of search: 21 attacker-built
`simulateTransaction` probes all revert on an explicit account-constraint or authorization check,
while the matching **control** probes (real authority/recipient signing) **succeed**.

The value at stake is real but it is **holder-only (H-O)**: stakers, vesting recipients and reward
claimants can each withdraw their own position; nobody else can.

---

## 3. Instruction surface and authority model

Enumerated from the public Anchor IDLs (`streamflow-finance/staking-cli` @ `956bcd6`,
`streamflow-finance/js-sdk` @ `fb236ff`) plus the **generated TS descriptors** (which carry the
`address` constraints that the bare IDL omits) and the deployed ELF strings
(`programs/stake-pool/src/…`, `programs/reward-pool/src/…`). Copies in `analysis/idl/`.

### 3.1 Stake program `STAKEvGqQTtzJZH6BWDcbpzXXn2BBerPAgQ3EGLN2GH` (12 ixs)

| ix | signer | binds |
|---|---|---|
| `create_pool` / `create_pool_v2` | `creator` | creates a new pool (permissionless) |
| `stake` | `payer` | `vault`/`mint`/`stake_mint` `has_one`→`stake_pool`; `to` = ATA(authority, stake_mint) |
| `unstake` | `authority` | entry.authority checked; vault/mint `has_one` |
| `unstake_as_worker` | `worker` **address-pinned** to `wdrwhnCv4pzW8beKsbPa4S2UDZrXenjg16KJdKSpb5u` | + token-account delegate check |
| `request_unstake` / `close_entry` | `authority` | entry authority checked |
| `change_authority` | `authority` (current) | pool authority checked |
| `migrate_entry` | `payer` | **address-pinned** `stakePoolFrom=Cja9f8JF…`, `stakePoolTo=BXRBbWMk…` (one-shot migration) |
| `set_token_metadata_spl/t22` | `authority` | Metaplex / Token-2022 program pinned |
| `create_lookup_table` | `payer` | ALT program pinned |

### 3.2 Reward programs (9 / 10 ixs)

`claim_rewards` (`claimant` signer, `to.owner == claimant`, `vault`/`mint` `has_one`→`reward_pool`,
`reward_entry` = PDA[reward-entry, reward_pool, stake_entry]), `claim_rewards_as_worker`
(`worker` **address-pinned**), `clawback`/`update_pool`/`change_authority`/`close_entry`
(`authority` signer + `has_one`), `fund_pool` (`funder` signer, treasury + fee program pinned),
`create_entry` (`payer`), `create_pool` (`creator`), dynamic: `set_governor`, `create_fund_delegate`
(worker pinned), `fund_as_delegate`.

### 3.3 Vesting/stream program `strmRqUCoQUgGUan5YhzUZa6KqdzwX5L6FpUxfmKg5m`

Anchor program; `withdraw` requires `authority` signer where `authority ∈ {recipient, sender}`
(gated by the stream's `transferable`/`cancelable` flags), and validates the metadata/escrow/
treasury/partner/mint account set against the stored contract (`InvalidAccountData` otherwise).
`cancel` is `authority ∈ {sender, recipient}` per flags.

### 3.4 Hard-pinned addresses (from the generated descriptors)

```
unstakeAsWorker.worker            = wdrwhnCv4pzW8beKsbPa4S2UDZrXenjg16KJdKSpb5u
claimRewardsAsWorker.worker       = wdrwhnCv4pzW8beKsbPa4S2UDZrXenjg16KJdKSpb5u
createFundDelegate.worker         = wdrwhnCv4pzW8beKsbPa4S2UDZrXenjg16KJdKSpb5u
migrateEntry.stakePoolFrom        = Cja9f8JFS6sTgBqSRZGBrA2HDbUj4MZUGdtRYruKTeJp
migrateEntry.stakePoolTo          = BXRBbWMkscNBZoBL4fgRk77GBUX9eVP4AendQEumtPi8
fundPool.streamflowTreasury       = 5SEpbdjFK5FxwTvfsGMXVQTD2v4M2c5tyRTxhdsPkgDw
fundPool.feeProgram               = FEELzfBhsWXTNJX53zZcDVfRNoFYZQ6cZA3jLiGVL16V
claimRewardsAsWorker.stakePoolProgram = STAKEvGqQTtzJZH6BWDcbpzXXn2BBerPAgQ3EGLN2GH
```

---

## 4. Live-state assessment

Programs (all `BPFLoaderUpgradeab1e…`, all sharing upgrade authority
`5u7o2WGgHckh18opTfPsqKb8E3nhDKcReBrbzUeXg2n7`, **off-curve PDA**, holds 1.65 SOL, no data):

| program | programdata | last deploy slot | ELF bytes | sha256(truncated ELF) |
|---|---|---|---|---|
| stake `STAKEvGq…` | `Furs1qmRoTtb7E8qae53sKqmWCc9tRio4GPABDehPHh6` | 385 756 820 | 631 576 | `afe5f45a…f1207` |
| reward `RWRDdf…` | `8BAMsX3MtVancKhWu1rgHwSwKZKXq4mBTwGCVqV3Evf5` | 385 756 399 | 506 728 | `f5eab00e…822da` |
| reward-dyn `RWRDyf…` | `H6YkqxynrRq3PFHWG7a8GYq4HS6eB61ZSMX5YSRK1dgu` | 419 237 289 | 558 928 | `7fe1663e…c3c8c` |
| vesting `strmRq…` | `796tZf2QrH1ebZTQC1mDHYP6weDqSKuqbeyaXd64Prs` | 449 063 805 | 790 384 | `f459fdeb…389b6` |
| governor `GVERN…` | `E4RQErb152TmnvWhD3UPiuXxF97pjgSWdUjk4PyjubgC` | 385 756 347 | 299 656 | `8a602720…c69d0` |
| fee-mgr `FEELz…` | `7wrZjTzkXzgdz7RapLN8tKdjnMScNpp9BxKYNkE62PjD` | 293 246 468 | 246 440 | `f2639e58…e8483` |

Account census (`getProgramAccounts`, slot 461 362 807):

| program | StakePool / RewardPool | StakeEntry / RewardEntry | other |
|---|---|---|---|
| stake | 1 182 | 63 529 | 2 LookupTableLink |
| reward (fixed) | 1 081 | 21 341 | — |
| reward (dynamic) | 121 | 7 668 | 24 FundDelegate |
| vesting | — | 76 050 stream contracts | 171 legacy |

All three programs are **actively used** right now (recent signatures at slots 461.38–461.39M;
the vesting program is receiving "Auto-Claim" txs every few slots via the `wdrwhn…` withdrawor).

---

## 5. What an attacker can and cannot do

**Cannot (all proven by simulation, §6):**
- unstake / close / request-unstake / change-authority someone else's stake entry or pool;
- substitute a foreign vault / mint / stake-mint to redirect the escrow;
- claim another staker's rewards (needs their stake-entry authority **and** a token account they own);
- claw back a reward pool they do not control;
- use the `worker` path (hard-pinned to Streamflow's key, **and** it additionally requires the
  staker to have delegated the stake-mint account);
- use `migrate_entry` (address-pinned to a single legacy→new pool pair);
- withdraw / cancel another party's vesting stream.

**Can (all value-neutral or self-harming):**
- create a stake pool or reward pool for any mint (permissionless; only affects people who opt in);
- stake into any pool with their own tokens (gift), fund any reward pool (gift);
- `update_pool` on a pool they created (own pool only; `UpdateTooSoon` rate limit).

**Cost of the failed attempts:** each probe costs only the tx fee (≈5 000 lamports) and reverts —
there is no capital requirement and no flash-loan route because no path moves a foreign balance.

---

## 6. Simulation battery (read-only `simulateTransaction`, `sigVerify:false`)

Attacker-built legacy messages; neutral funded payer; real Streamflow PDAs as accounts. Full JSON
in `analysis/sims.json`, `analysis/reward_sims.json`, `analysis/vesting_probe.log`.

| # | probe | result | meaning |
|---|---|---|---|
| 1 | `unstake` victim entry, attacker authority | `6005 Unauthorized` | entry-authority gate |
| 2 | `unstake` own entry, real authority (**control**) | `6016 UnstakeRequestRequired` | gate **passed**; fails later on pool policy |
| 3 | `unstake` forged vault | `6008 InvalidStakeVault` | vault `has_one` binding |
| 4 | `unstake` forged mint | `6011 InvalidPoolMint` | mint `has_one` binding |
| 5 | `unstake_as_worker` attacker as worker | `6005 Unauthorized` | worker gate |
| 6 | `unstake_as_worker` real worker (**control**) | `6005 Unauthorized` | still gated → needs delegation |
| 7 | `migrate_entry` victim, attacker payer | `2012 ConstraintAddress` | hard-pinned source pool |
| 8 | `change_authority` attacker authority | `6005 Unauthorized` | authority gate |
| 9 | `change_authority` real authority (**control**) | **SUCCESS** | gate proven |
| 10 | `request_unstake` victim | `6005 Unauthorized` | authority gate |
| 11 | `close_entry` victim | `6005 Unauthorized` | authority gate |
| 12 | `stake` forged vault | `6008 InvalidStakeVault` | vault `has_one` binding |
| 13 | `claim_rewards` victim entry, attacker claimant | `2015 ConstraintTokenOwner` | `to` must be owned by claimant |
| 14 | `claim_rewards` real authority (**control**) | **SUCCESS** (Claimable 4 950 000 000 000) | gate proven |
| 15 | `claim_rewards` forged vault | `6005 InvalidRewardVault` | vault `has_one` binding |
| 16 | `claim_rewards` forged mint | `3007 AccountOwnedByWrongProgram` | mint type check |
| 17 | `clawback` attacker authority | `6003 Unauthorized` | authority gate |
| 18 | vesting `withdraw` attacker authority | `InvalidAccountData` | account-set/authority check |
| 19 | vesting `withdraw` real recipient (**control**) | **SUCCESS** ("Withdrawn 0.000000001 …") | gate proven |
| 20 | vesting `withdraw` sender-as-authority | `InvalidAccountData` | only the permitted party |
| 21 | vesting `cancel` attacker sender | `InvalidAccountData` / custom | authority gate |

Controls #2, #9, #14 and #19 are the important ones: the *same* account layout with the *correct*
signer succeeds, so the failures above are genuine authorization/constraint gates, not malformed
messages.

---

## 7. Deployed vs source, upgradeability (P-class)

- The deployed instruction discriminators match the public IDLs (sims log
  `Instruction: ClaimRewards`, `Instruction: Withdraw`, and the stake handlers' custom errors), so
  the public IDL/descriptor constraint set describes the deployed code.
- The stake/reward/vesting sources are **not public** (`github.com/streamflow-finance/staking`
  → 404; `SECURITY.TXT` in the ELF points there anyway). The 2022 OpCodes audit
  (`rust-sdk/audit_reports/protocol_audit_001.pdf`) covers only the **vesting** protocol program and
  is 4 years old; the stake/reward programs appear unaudited publicly.
- All five programs remain **upgradeable** by `5u7o2WGgHckh18opTfPsqKb8E3nhDKcReBrbzUeXg2n7`
  (off-curve, so a multisig/governance PDA rather than a hot key). This is the single largest
  latent risk: a compromised upgrade authority could replace any program and drain everything.
  It is **P-class** (privileged), not E-U.

---

## 8. Verdict and residual risk

**Verdict: $0.00 live extractable by an external unprivileged attacker — confidence HIGH.**
The Streamflow stake, reward and vesting programs are, as deployed at slot 461 362 807, correctly
gated: every value-moving instruction requires a signer that is the legitimate position owner (or a
hard-pinned Streamflow key), and every vault/mint/entry account is bound by `has_one`/PDA-seed/
`address` constraints. 21 probes, 4 successful controls, 17 explicit rejects.

**Residual / latent risk (not E-U):**
1. **Upgrade authority** (P) — all programs upgradeable by one off-curve PDA.
2. **`wdrwhn…` worker/withdrawor hot key** (P-conditional) — on-curve, 2.08 SOL; can auto-unstake /
   auto-claim / create fund delegates, but only for positions whose owners delegated to it, and the
   token destinations are the owners'. A key compromise is a real (if bounded) risk.
3. **Pool authorities** (P) — can `clawback` unclaimed rewards and update fixed-pool rates.
4. **`migrate_entry`** is permissionless but address-pinned to one pool pair; worst case is
   griefing, never theft.
5. Unpriced/memecoin stake vaults mean the "on-chain held" USD is dominated by illiquid tokens;
   the *attacker-extractable* figure is $0 regardless.

**Blockers / limitations:** the stake/reward source is closed, so the account constraints were
established from the IDLs, the generated descriptors and the ELF error strings rather than from
source; no BPF decompilation was performed. All state is point-in-time; re-read before acting.

---

## 9. Methodology, sources, files

**Method:** (1) re-verified program IDs, programdata, upgrade authorities, ELF sizes/hashes and
last-deploy slots; (2) enumerated the instruction surface from the public IDLs and the generated TS
descriptors (which carry `address` constraints) and cross-checked against deployed ELF strings;
(3) enumerated live accounts and read vault/escrow balances + mints; (4) priced mints with
DefiLlama; (5) built attacker messages and ran `simulateTransaction(sigVerify:false,
replaceRecentBlockhash:true)` with controls.

**Sources:** `github.com/streamflow-finance/staking-cli` @`956bcd6` (IDL + generated types),
`github.com/streamflow-finance/js-sdk` @`fb236ff` (staking + stream packages),
`github.com/streamflow-finance/rust-sdk` (audit PDF), DefiLlama (`api.llama.fi/protocol/streamflow`,
`coins.llama.fi`), public Solana JSON-RPC.

**Files:** `analysis/sol.py` (RPC), `analysis/simlib.py` (tx builder), `analysis/enum_all.py`
(live state), `analysis/sim_battery.py`, `analysis/reward_probe.py`, `analysis/vesting_probe.py`,
`analysis/programs.json`, `analysis/census.json`, `analysis/live_state.json`,
`analysis/sims.json`, `analysis/reward_sims.json`, `analysis/vesting_live.json`,
`analysis/idl/`, `ci/run.sh`, `ci-out/`.

**CI:** the heavy enumeration + probes ran on GitHub Actions (`artsbykriss/ca-zombie-ci`) — run URL
in §7/`summary.json`.
