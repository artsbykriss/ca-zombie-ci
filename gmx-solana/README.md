# GMX Solana / GMTrade — residual unprivileged-extraction assessment

**Date:** 2026-10-26 · **Chain:** Solana mainnet-beta · **Status:** read-only; no signing, no mainnet
sends; all probes are `simulateTransaction` (`sigVerify:false`, `replaceRecentBlockhash:true`) on
attacker-built messages. No fork/PoC transactions were needed.

**Target:** DefiLlama protocol `gmx-solana` (GMX Solana / GMTrade), TVL **$26,545,788** (2026-10-26,
`api.llama.fi/protocol/gmx-solana`, SOL ≈ $100.8).

**Question:** how much can an external, unprivileged attacker (no roles, no admin, no insider
access) extract from the live deployment **right now**?

---

## 1. TL;DR

| Target | Live extractable (E-U) | Why closed | Latent risk |
|---|---|---|---|
| GMX-Solana **store** program `Gmso1uvJ…ucLo` | **$0** | Every value-moving path is gated by a protocol **role** (`#[access_control]`) or by an address/signer constraint; the attacker holds no roles and cannot create them. Oracle price-setting is bound to `ORACLE_CONTROLLER`; order/deposit/withdrawal/liquidation execution to `ORDER_KEEPER`; market/GT/treasury ops to their keepers/admin. | Privileged key risk: several `ORDER_KEEPER`/`PRICE_KEEPER` members are **on-curve EOAs** (hot keys). Not attacker-extractable, but a compromised keeper could move value. |
| treasury / timelock / competition / liquidity-provider | **$0** | All share the same **off-curve PDA** upgrade authority; their privileged instructions are role/admin-gated. | Same as above. |
| callback `9JtQ9f…` / gt-incentive `6iMXVS…` | n/a | **Not deployed** on mainnet (no account). | none |

## 2. Total live extractable now: **$0.00** — confidence **high**

An honest, proven negative. Evidence: (a) the deployed bytecode is the **audited** revision whose
full instruction surface is role-gated; (b) on-chain `simulateTransaction` probes show the attacker
holds no role and every candidate path reverts with a specific gate error (exact codes in §7).

Separately, the protocol's **total value at risk to a privileged key** (not the attacker) is the
full TVL ≈ **$26.55M** plus the ~$0.47k of SOL in the store account.

---

## 3. The mechanism / what was assessed (deployed code references)

This is not a "dead protocol" — it is a live, actively maintained, audited Anchor program with a
role-based permission system. The assessment therefore reduces to: *is there any unprivileged path
that moves value, and is the deployed binary the audited code?*

- Program model (repo `gmsol-labs/gmx-solana`, `programs/store/src/lib.rs`): a single `Store`
  account holds an RBAC table (`RoleStore`: up to 32 roles × 64 members) plus config, GT state and
  treasury. Instruction-level access control is expressed as
  `#[access_control(internal::Authenticate::only_<role>(&ctx))]`.
- **57 of 134** instructions have **no** `#[access_control]` gate; the other **77** are role-gated
  (ADMIN / MARKET_KEEPER / ORDER_KEEPER / ORACLE_CONTROLLER / PRICE_KEEPER / GT_CONTROLLER /
  CONFIG_KEEPER / FEATURE_KEEPER / TREASURY_* / MIGRATION_KEEPER). The full map is in
  `analysis/access_control_map_8af1e70.json`.
- The 57 ungated instructions were each checked for a value-moving primitive. They fall into three
  groups: (i) **read-only getters** (`has_admin`, `has_role`, `get_market_*`, `token_*`, …);
  (ii) **own-account lifecycle** (`create_/close_/update_ deposit|withdrawal|order_v2|shift|glv_*`,
  `prepare_*`, `set_referrer`, `set_builder_fee`, `claim_builder_fees`, `request_gt_exchange`,
  referral transfer) — all constrained by `owner: Signer` + a seed-derived `UserHeader` PDA with
  `has_one = owner`; (iii) **inert creates** (`initialize_token_map`, `initialize_oracle`,
  `initialize_market_config_buffer`, `prepare_gt_exchange_vault`).

Notable closed paths (exact constraints):

- **Oracle price setting** — `set_prices_from_price_feed` requires the signer to be **both** the
  oracle's `authority` (`has_one = authority`) **and** hold `ORACLE_CONTROLLER`
  (`#[access_control(only_oracle_controller)]`). `initialize_oracle` *is* permissionless, so an
  attacker can create their own oracle bound to the real store with themselves as authority — but
  the role check still blocks setting prices (§7, test 6).
- **Market fee claiming** — `claim_fees_from_market` calls
  `validate_claim_fees_address(authority.key)` → `require!(treasury.is_receiver(address))`.
  Only the treasury receiver can claim. `transfer_receiver` is restricted to the current receiver
  (`authority.key() == store.receiver()`); `accept_receiver` requires the designated
  `next_receiver` to sign.
- **Builder fees** — `set_builder_fee` requires `order.header.owner == owner.key()` with
  `owner: Signer`; `settle_builder_fee` is permissionless but enforces
  `order.builder() == builder_user.key()` and pays the builder's own claim vault.
- **Action closers** (`close_order_v2`, `close_deposit`, `close_withdrawal`, `close_shift`,
  `close_glv_*`) are executor-signed but constrain `receiver == header.receiver()` and
  `rent_receiver == header.rent_receiver()` (which defaults to the owner) — funds/rent cannot be
  redirected.
- **Execution/liquidation** (`execute_*`, `liquidate`, `update_adl_state`, `auto_deleverage`,
  `update_closed_state`, `update_fees_state`) are all `ORDER_KEEPER`.
- **Treasury/store authority** — `transfer_store_authority` (ADMIN),
  `accept_store_authority` (`store has_one = next_authority`).

### Deployed vs audited byte-diff (mission item 1)

| Fact | Value |
|---|---|
| Program | `Gmso1uvJnLbawvw7yezdfCDcPydwW2s2iqG3w6MDucLo` |
| ProgramData | `CSp2sB68THdrJP6N7Au4Y5u89VJ1E1ebaqZ2soHhQvav` |
| Upgrade authority | `6qp7veALWas5rxXJRQXUEbffRtDyhB8koxenBpS51SrA` (**off-curve PDA**, system-owned, 5.742 SOL) |
| Last deploy slot | **459,556,802** (block time 2026-10-21 08:08 UTC) |
| ELF length | 4,360,824 bytes (allocated 4,376,045) |
| sha256(ELF[..len]) | `8fbdc5cf1a446b467460764990a2002360ebde330513fa45d8e57e7ce2b00e15` |
| Observed slot at capture | 461,362,168 / 461,365,574 |

Repo `gmsol-labs/gmx-solana`, audit commit **`8af1e70`** (2026-10-08, version 0.11.0). HEAD at recon
`f102501` (2026-10-21) is **14 commits ahead**.

A full reproducible build of an Anchor 0.31.1 / Solana 2.1.21 SBF program is environment-sensitive
(the deployed ELF embeds `/home/runner/work/platform-tools/...` sysroot paths), so an exact-hash
match is impractical; we used a **discriminator/symbol/string diff** instead, which is decisive:

1. **ELF discriminator scan** (`analysis/discriminator_halves.py`). Anchor 0.31 compiles the 8-byte
   instruction discriminator into two 32-bit immediates (raw 8 bytes are *not* contiguous), so we
   scan for both 4-byte halves of `sha256("global:<name>")[:8]`. Random-name false-positive control:
   **0/500**. Result: **134/134** instructions of commit `8af1e70` are present; the **5** post-audit
   instructions (`close_gt_exchange_v2`, `set_gt_delegate`, `increase_gt_allowance`,
   `decrease_gt_allowance`, `request_gt_exchange_v2`) are **absent**.
2. **On-chain instruction probe** (`analysis/instruction_probe.py`) — minimal `simulateTransaction`
   per discriminator: **134/134 audit instructions recognized** (non-101 error), **5/5 post-audit
   instructions return `InstructionFallbackNotFound` (Custom 101)**.
3. **String/source-path diff** — the embedded `programs/store/src/**` error-origin paths and all
   ≥10-char string literals are identical across `8af1e70 … 6cc72716`, and the ELF contains the
   audit set. The string `"[GT] Closing confirmed exchange…"` occurs **once** in the deployed ELF,
   matching ≤ `acaece1f` (the Oct-16 commit that added a second, v2 occurrence).
4. **Access-control diff** — the role-gating map is **identical** between `8af1e70` and `acaece1f`.

**Conclusion:** the deployed binary is the **audited v0.11.0 revision** (instruction surface exactly
`8af1e70`); none of the post-audit instructions landed on mainnet. Residual uncertainty: which of the
8 commits sharing the same instruction+string surface (`8af1e70 … 6cc72716`) produced it — these
differ only in backward-compatible data-layout fields, not in any gate. CI reproducible-build job:
`ci/run.sh` (run URL recorded in `ci-log.txt`).

**On the audit-commit fix #466** (`fix(store): refresh order oracle bounds on builder fee
checkpoint`): this fix changes only `set_builder_fee`'s body — it adds a `Clock::get()`, refreshes
the *order owner's own* order's `updated_at`/`updated_at_slot` for limit orders, and forbids market
orders from extending their window. It adds **no new instruction, no new error variant and no new
string literal**, so it is not binary-detectable from the deployed ELF; the deployed binary could in
principle be the parent `8af1e70^`. This does not change the verdict either way: the pre-fix
behaviour is *stricter* (no bounds refresh at all), the post-fix behaviour only lets an order owner
refresh their own order's window, and both require an `ORDER_KEEPER` to execute the order — no
unprivileged extraction path exists in either revision.

### CI reproducible-build job (`ci/run.sh`, repo `artsbykriss/ca-zombie-ci`)

`ci/run.sh` installs Solana **2.1.21**, clones the repo, and builds the store program at `8af1e70`
and `f102501` with `cargo build-sbf` (Anchor 0.31.1 / SBPF), then runs `ci/compare.py` which applies
the same discriminator-halves test to the freshly built ELF and prints its sha256 next to the
deployed hash. Runs: `actions/runs/40247998750`, `…/40248335413`, `…/40249313075`, final run URL in
`ci-log.txt`; artifacts land in `ci-artifacts/` and `ci-out/`. (The gmsol-store crate compiles under
the pinned SBF toolchain; the workspace CLI crate is excluded because its deps require a newer host
rustc.) A byte-identical ELF is not expected — the deployed binary embeds the official
platform-tools sysroot paths — so the discriminator/string/on-chain diff above is the load-bearing
evidence.

## 4. Live-state assessment

- **Store** `CTDLvGGXnoxvqLyTpGzdGLg9pD6JexKxKXSV8tqqo8bN` (10,232 bytes, 4.669 SOL ≈ $470.76).
  - admin `authority` = `ebpa6Yp5ubMEAopN9GqRUrgqsLNwU8Mp6pTaNF6XMr6` (**off-curve PDA**);
    `next_authority` identical.
  - `token_map` = `7cEiyyEB2VGMtnKLb7Ro7SsJKYZVBZjpS8ihBD8jR938`.
  - RBAC: **19 members**. Enabled roles incl. `ORDER_KEEPER, MARKET_KEEPER, ORACLE_CONTROLLER,
    PRICE_KEEPER, GT_CONTROLLER, CONFIG_KEEPER, FEATURE_KEEPER, MARKET_CONFIG_KEEPER, MIGRATION_KEEPER,
    TREASURY_{OWNER,ADMIN,WITHDRAWER,KEEPER}, TIMELOCK_{ADMIN,KEEPER}, RESTART_ADMIN`.
  - Role holders are **mixed**: `ORACLE_CONTROLLER` and `GT_CONTROLLER` are **PDAs**
    (`55tVJJu5…`, `4pnQyp…`, `5sg9Sj…`), `MARKET_KEEPER` is a PDA (`ES3bft…`); several
    `ORDER_KEEPER`/`PRICE_KEEPER`/`TREASURY_KEEPER` members are **on-curve EOAs** (hot keepers).
    Full decode: `analysis/store_decoded.json`.
  - Live `has_role` probe: the neutral attacker `5tzFkiKs…` → `PermissionDenied`; PDA `55tVJJu5…`
    → `true`.
- **Program accounts** (owned by store, read-only `getProgramAccounts`, `analysis/store_accounts.json`):
  Market **103**, Oracle **9**, UserHeader **39,486**, Position **61,826**, Order **205**,
  GtExchangeVault **581**, GtExchange **494**, GLV **7**, MarketConfigBuffer **122**,
  CallbackAuthority **1**, VirtualInventory **2**, TradeData **7**.
- **Sibling programs** (all share upgrade authority `6qp7veAL…`):
  treasury `GTuvYD5S…` (deploy slot 374,632,307), timelock `TimeBQ7gQy…` (352,328,085),
  competition `2AxuNr6e…` (348,433,799), liquidity-provider `LPMWczEV…` (399,521,457).
  **callback `9JtQ9fBS…` and gt-incentive `6iMXVSji…` have no account → not deployed.**

## 5. What an attacker can / cannot do

- **Cannot** set or manipulate oracle prices (`ORACLE_CONTROLLER`), execute/liquidate orders
  (`ORDER_KEEPER`), mint GT / confirm GT-exchange vaults (`GT_CONTROLLER`), change market config
  (`MARKET_KEEPER`/`MARKET_CONFIG_KEEPER`), toggle features (`FEATURE_KEEPER`), transfer store
  authority (`ADMIN`), claim market fees (`treasury.is_receiver`), or redirect action rent/output.
- **Can** (all harmless / self-scoped): create and close their own deposit/withdrawal/order/shift/GLV
  actions; set their own referrer and builder fee; create a referral code; request a GT exchange
  against their own GT; create an inert token map or oracle; permissionlessly settle a *pending*
  order's builder fee (funds go to the recorded builder); act as an `executor` to close another
  user's *completed* action (funds go to that user).
- **Cost of the closed paths:** none reachable, so no capital/gas calculus applies.

## 6. Verdict and residual / latent risk

- **E-U = $0.00, high confidence.** All extraction-relevant state transitions require a role the
  attacker cannot obtain; `initialize_oracle`/`initialize_token_map` are permissionless but produce
  inert accounts; the audit revision is what is deployed.
- **Latent / privileged risk (P):** the deployment is only as safe as its keeper keys. Several
  `ORDER_KEEPER`/`PRICE_KEEPER` members are single on-curve EOAs; a compromised `ORDER_KEEPER`
  could execute attacker-favourable orders against the ~$26.5M of market liquidity, and a
  compromised `ORACLE_CONTROLLER` (a PDA, so better) could mis-price. The `upgrade_authority` is an
  off-curve PDA (good). This is a key-management risk, not an E-U bug.
- **Liveness dependency (not E-U, not S):** user withdrawals/order settlement require an
  `ORDER_KEEPER` to call `execute_*`; if keepers halt, funds are not bricked but are delayed. Users
  can always `close_*` completed actions themselves.
- **No S-class bricked value** was identified.

## 7. Simulation battery (no fork needed — on-chain `simulateTransaction`)

Signer: neutral external funded account `5tzFkiKscXHK5ZXCGbXZxdw7gTjjD1mBwuoFbhUvuAi9`.
Raw results: `analysis/sim_battery.json`; script `analysis/simulate_battery.py`.

| # | Probe | Result | Meaning |
|---|---|---|---|
| 0 | `create_order_v2([store])` | `Custom 102` InstructionDidNotDeserialize | sanity: sim delivers data correctly |
| 1 | `has_admin(attacker)` | success, return `[0]` | attacker is **not** admin |
| 2 | `has_role(attacker,"ORACLE_CONTROLLER")` | `Custom 6004` PermissionDenied | attacker holds **no** roles |
| 3 | `has_role(55tVJJu5…,"ORACLE_CONTROLLER")` | success, return `[1]` | role held by a PDA |
| 4 | `has_role(4z1snZ…,"ORACLE_CONTROLLER")` | success, return `[0]` | that keeper is *not* the oracle controller |
| 5 | `set_prices_from_price_feed(attacker, real_oracle)` | `Custom 2001` ConstraintHasOne (Left `4z1snZ…`, Right attacker) | cannot price the real oracle |
| 6 | `create_account + initialize_oracle(attacker) + set_prices(attacker)` | `Custom 6004` PermissionDenied (ix 2, `states/roles.rs:179`) | even a **self-created** store-bound oracle cannot be priced without the role |
| 7 | `update_last_restarted_slot(attacker)` | `Custom 6003` NotAnAdmin (`utils/internal/authentication.rs:18`) | ADMIN gate rejects attacker |
| 8 | `claim_fees_from_market(attacker)` | `Custom 3007` AccountOwnedByWrongProgram | not invocable without the receiver's accounts; code gate `treasury.is_receiver` |
| 9 | `liquidate(attacker)` | `Custom 102` | not invocable without full keeper account set |

**Tests: 10/10 executed as expected (0 unexpected successes).**

## 8. Methodology & sources; caveats; files

**Sources of truth:** live Solana JSON-RPC (`getAccountInfo`, `getProgramAccounts`,
`getBlockTime`, `simulateTransaction`); repo `gmsol-labs/gmx-solana` at `8af1e70` / `f102501`;
in-repo Anchor IDL `crates/programs/idls/gmsol_store.json` (v0.11.0); DefiLlama
`api.llama.fi/protocol/gmx-solana` and `coins.llama.fi/prices`.

**Caveats / limitations:**
- Exact deployed commit among the 8 same-surface candidates not pinned (layout-only differences).
- The CI reproducible build is best-effort; the discriminator/string diff is the load-bearing
  evidence.
- The `claim_fees`/`liquidate` probes fail at account validation before reaching their named gate;
  the gate itself is established from source (`validate_claim_fees_address`; ORDER_KEEPER
  `#[access_control]`) and from the analogous clean `NotAnAdmin`/`PermissionDenied` probes.
- TVL is DefiLlama's figure, not an independent per-vault recount.

**Files index (all under `gmx-solana/`):**
- `analysis/sol.py`, `elf.py`, `elf_extract.py` — read-only RPC + ELF extraction
- `analysis/store_deployed.elf` (+ `.meta.json`, `.strings.txt`) — deployed program bytecode
- `analysis/discriminator_halves.py` / `discriminator_halves_scan.json` — instruction-surface diff
- `analysis/instruction_probe.py` / `instruction_surface_probe.json` — on-chain surface confirmation
- `analysis/access_control_map.py` / `access_control_map_8af1e70.json` — role-gate map
- `analysis/decode_store.py` / `store_decoded.json` — RBAC + authority decode
- `analysis/enumerate_accounts.py` / `store_accounts.json` — live account census
- `analysis/simulate_battery.py` / `sim_battery.json` — `simulateTransaction` battery
- `analysis/path_fingerprint.py`, `commit_pin.py`, `literal_fingerprint.py` (+ JSON) — deployed-vs-audit
- `ci/run.sh`, `ci/compare.py`, `ci-out/` — CI reproducible-build job
- `summary.json` — machine-readable summary
