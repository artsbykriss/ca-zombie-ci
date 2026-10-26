# Hylo router (`hyRouTR…`) — caller-supplied-account substitution on `route`

**Date:** 2026-10-25 · **Chain:** Solana mainnet-beta · **Status:** read-only; `simulateTransaction`
only; **no transaction was signed or sent**; no keys used; all endpoints keyless/public.

**Finding:** ZH4-PASS7 TIER 3 LOW #12 — *"Hylo router, $37.6M. `update_lst_prices` substitution
CLOSED (10 sims, 6009); router `route` declares 0 accounts (open)."*

**Verdict: `route` is CLOSED — $0 external-unprivileged (E-U).** The zero-account declaration is a
*proxy design*, not a missing check: `route` forwards the caller's accounts to a **hard-coded**
target program (the Hylo exchange), and the exchange validates every one of them. The router adds
no signature and no authority of its own, holds no funds, and its PDAs are `router::ID` PDAs which
can never satisfy the exchange's `exchange::ID` PDA constraints.

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why closed | Latent risk |
|---|---|---|---|
| Hylo router `hyRouTRDAgn65xyyJ3L5c4k5SFmSdr3NxDV8Euzjy3f` | **$0** | `route` is a CPI proxy: target program is hard-coded (substituting the program account ⇒ `MissingAccount`); every forwarded account is re-validated by the exchange (`ConstraintRaw` 2003, `ConstraintSeeds` 2006, `ConstraintTokenMint` 2014, `ConstraintTokenOwner` 2015, `AccountNotSigner` 3010, `AccountNotInitialized` 3012); unsupported pairs rejected by the router itself (`UnsupportedPair` 6000) | **P**: router upgrade authority `GzyhwK4y…` (same as the exchange) can replace the proxy. Not E-U. |
| Hylo exchange (context, not this finding) | $0 for the tested primitive | `update_lst_prices` substitution already proven CLOSED (pass 7, 10 sims, `6009`) | — |

**Total live extractable now: $0.00** — confidence **high**.

---

## 2. The mechanism in exact terms

### 2.1 What `route` actually is

The published IDL (`hylo-so/sdk` → `hylo-idl/idls/hylo_router.json`) shows:

```
route      accounts: 0   args: (token_a, token_b, amount, slippage_config?)
route_v2   accounts: 1   (exo_registry)
```

`hylo-idl/src/instruction_builders/router.rs` (same repo, verbatim):

> `route` — *"Routes through the proxy program, forwarding the given accounts to the target program
> via CPI. Exo pairs resolve from the pair table compiled into the router."*

The router is therefore an **instruction proxy**: the caller passes the *target program's* account
list as the route instruction's own account list; the router picks the exchange instruction from
`(token_a, token_b)` and CPIs with those accounts.

### 2.2 Live confirmation (this is the live instruction, not a guess)

A confirmed mainnet transaction (Titan aggregator → Hylo router) shows the exact behaviour:

```
Program hyRouTRDAgn65xyyJ3L5c4k5SFmSdr3NxDV8Euzjy3f invoke [1]
  Program log: Instruction: Route
  Program HYEXCHtHkBagdStcJCp3xbbb9B7sdMdWXFNj6mdsG4hn invoke [2]
    Program log: Instruction: ConvertStableToLeverExo
    ...  (SPL token transfer)
```

* tx `5nSxg7ucq5YzAdYwujCt5AssYMqiWmWrLPxQwPoks4pzi9ivj972CuZuz36y5KMC6WjFnxT6rmzm1URLQjEdcgfY`
* router instruction data (81 B) starts with `e517cb977ae3ad2a` = `sha256("global:route")[:8]`
  — i.e. the **live instruction is `route` (v1)**, the compiled-table variant, *not* `route_v2`.
* args decoded: `token_a = 5YMkXAYcc…` (hyUSD), `token_b = 7ga6rtE9…` (the xHYPE exo levercoin),
  `amount = 789 366 268`, no slippage.
* the router's 18 accounts are **byte-identical** to the exchange `ConvertStableToLeverExo`
  account list, in order.

### 2.3 `route_v2`'s registry does not even exist

`EXO_REGISTRY = PDA(["exo_registry"], router)` = `F7BfTbic9AyaNKT7e4eoSbgZC7yxJvutA6S4VzosASg9`
**does not exist on-chain** (never initialised). So the registry-driven `route_v2` path is not in
use; all live traffic goes through `route` v1 and its compiled-in pair table.

---

## 3. Live-state assessment (all read-only; slot 461 384 770 unless stated)

| Item | Value | Check |
|---|---|---|
| Router program | `hyRouTRDAgn65xyyJ3L5c4k5SFmSdr3NxDV8Euzjy3f` | `getAccountInfo`, owner `BPFLoaderUpgradeab1e…` |
| Router programdata | `GCsBXReXttZUUfG1JVxiXMvWPHbWikS3FVdZPy1hjXjM` | ELF 240 376 B, sha256 `25f88987c8223775…` |
| Router upgrade authority | `GzyhwK4y7EKPEevAMc2TEpgi1Y3znwj14FUzkHmCMiNP` | deployed slot 439 863 765 |
| `EXO_REGISTRY` PDA | `F7BfTbic9AyaNKT7e4eoSbgZC7yxJvutA6S4VzosASg9` | **exists = false** |
| Router `EVENT_AUTH` PDA | `DsRFnNGgyQCpSH7dDHi6ZC2YnYGnG1J2cEPSyeomDwyj` | **exists = false** |
| SPL/Token-2022 accounts owned by router program or its PDAs | **0** | `getTokenAccountsByOwner` × {Token, Token-2022} × 3 owners |
| Hylo exchange | `HYEXCHtHkBagdStcJCp3xbbb9B7sdMdWXFNj6mdsG4hn` | live, `protocol_paused = false` |
| `Hylo` PDA | `9cd2sAfbBvKs4SX9YKo4dcjwP3TgTVQ8dT5koshGcDND` | admin `12DAP8y5…`, treasury `mAQQ9Bph…`, lst_registry `9Mb2Mt76…` |
| Custody reachable only via the **exchange** | **$58,538,018.64** measured (JITOSOL vault $30.20M, earn-pool hyUSD $20.56M, cbBTC vault $3.36M, hySOL vault $2.39M, HYPE vault $2.04M) | `analysis/hylo_tvl.json` |

Note: the router's **program account** holds 1 141 440 lamports (rent-exempt program metadata) — not
withdrawable by anyone but the loader/upgrade authority.

### 3.1 The structural argument (why a router PDA signature is worthless here)

Every signer-bearing account in every Hylo **exchange** instruction is either
* an external signer (`user` / `admin`), or
* a PDA of the **exchange** program: `pda!(exchange::ID, …)` for `vault_auth`, `fee_auth`,
  `mint_auth`, `lst_header`, `exo_pair`, `exo_levercoin`, `usdc_pair`, `hylo`, `settlement_auth`,
  `pool_auth` (see `hylo-idl/src/pda.rs`).

A PDA is `find_program_address(seeds, program_id)`. The router's PDAs are derived under
`router::ID`; **no router PDA can equal an exchange PDA**. Therefore even if `route` signed with
every one of its PDAs (it has none that matter, and `invoke` is unsigned anyway), it could not
satisfy a single exchange constraint. The router cannot escalate authority it does not have.

---

## 4. What an attacker can / cannot do

All results below are `simulateTransaction` (`sigVerify:false`, `replaceRecentBlockhash:true`) of a
**replay of the real live `route` CPI** (`analysis/hylo_router_results.json`).

| # | Test | Result | Meaning |
|---|---|---|---|
| H1 | **CONTROL** — replay the real `route` CPI, amount ≤ live balance | **SUCCESS** | harness reproduces the live path; handler reached |
| H2 | substitute the **CPI program account** (idx 17) with a bogus program | **`MissingAccount`** | the CPI target is **hard-coded** — not read from the account list |
| H3 | `hylo` (idx 1) → another exchange PDA | `3012 AccountNotInitialized` | rejected |
| H4 | `exo_pair` (idx 2) → the WETH pair PDA | `3012 AccountNotInitialized` | rejected (pair not registered) |
| H5 | `collateral_mint`/`levercoin_mint` (13/12) → WETH pair | `3012 AccountNotInitialized` | rejected |
| H6 | `collateral_usd_pyth_feed` (14) → SOL/USD feed | **`2003 ConstraintRaw`** | the feed is explicitly bound to the pair |
| H7 | `user_levercoin_ta` (9) → an ATA of the wrong mint | **`2014 ConstraintTokenMint`** | token-account mint binding enforced |
| H8 | `event_authority` (16) → another PDA | **`2006 ConstraintSeeds`** | seeds enforced |
| H9 | `user` (0) → attacker (marked signer) | **`2015 ConstraintTokenOwner`** | downstream token-owner binding enforced |
| H10 | keep the accounts, change `token_b` in the args | **`6000 UnsupportedPair`** | router rejects a pair/account mismatch |
| H11 | ask for an unsupported pair `(HYPE, WETH)` | **`6000 UnsupportedPair`** | compiled table is authoritative |
| H12 | drop one account (17 instead of 18) | **`MissingAccount`** | list arity enforced |
| H13 | leave `user` un-signed | **`3010 AccountNotSigner`** | the exchange requires the real user's signature — the router cannot supply it |

**A positive control exists** (H1 ⇒ SUCCESS), so the negatives are not "everything reverts"
artefacts: the exact same instruction *works* when the account set is legitimate.

### 4.1 Independent verification

A second, separately-written verifier (own scripts, own PDA derivations) reproduced: the router and
both of its PDAs own **0** token accounts; `EXO_REGISTRY`/`EVENT_AUTH` do not exist;
`router_pda_equals_exchange_pda = false`; the program-account substitution ⇒ `MissingAccount` with the
router log `Unknown program HYEXCHtH…`; the `user` substitution ⇒ `2015 ConstraintTokenOwner`; and the
unmodified live `route` CPI ⇒ **SUCCESS**. See `analysis/verify/VERIFY.md`.

**No path found** that lets a caller-supplied account set misroute value, mint without backing, or
withdraw from a vault. The router's own reachable state (registry/event PDAs) does not exist and
holds nothing.

---

## 5. PoC

* `poc/hylo_router_poc.py` — self-contained (only `solders` + stdlib). Enumerates the structural
  facts, replays the live `route` CPI as a control, then runs 12 substitutions.
* `poc/solcore.py` — keyless RPC + PDA + `simulateTransaction` toolkit.
* Run: `python3 poc/hylo_router_poc.py` → writes `ci-out/hylo_router_results.json`.
* CI: `ci/run.sh` (run on GitHub Actions via `ci/ci-run.sh hylo-router`); run URLs in
  `ci-log.txt` / `ci-artifacts/`.

Expected (last local run, slot 461 384 770): 1 control SUCCESS + 12 rejections, as tabulated above.

---

## 6. Verdict, residual and latent risk

* **E-U (external unprivileged): $0.00.** The primitive (caller-supplied account substitution
  through a zero-account proxy) is **closed**, both structurally and empirically.
* **H-O:** $0 (no holder-recoverable value in the router).
* **P (privileged):** the router upgrade authority `GzyhwK4y7EKPEevAMc2TEpgi1Y3znwj14FUzkHmCMiNP`
  can replace the router program; the same authority also controls the exchange. This is normal
  admin power, not E-U.
* **S (stuck):** nothing stuck.
* **Latent risk / monitor:** if the router is upgraded to *stop* validating (e.g. a new
  `route` that trusts a caller-supplied program), or if `initialize_exo_registry` is called and
  `route_v2` becomes the live path, re-test. Tripwire: router programdata hash change
  (`25f88987c8223775…`) or `EXO_REGISTRY` (F7BfTbic…) becoming initialised.

---

## 7. Methodology, sources, caveats, files

**Method.** (1) Dump the program ELF from the upgradeable loader (ProgramData) and hash it;
(2) recover the instruction surface from the on-chain IDL published in the project's own SDK
(`github.com/hylo-so/sdk`, `hylo-idl/idls/hylo_router.json`) plus ELF source-map strings
(`programs/hylo-router/src/lib.rs`, `util.rs`); (3) pull a **real** `route` CPI from a confirmed
transaction and replay it; (4) mutate one account at a time; (5) map Anchor error codes.

**Caveats / limitations.**
* The router program source is **not** public; the account-resolution logic is inferred from the
  published IDL + live behaviour. The *empirical* result (12 rejections + 1 working control) does
  not depend on that inference.
* `sigVerify:false` lets any pubkey be marked a signer for simulation; H13 (no-user-signer ⇒
  `AccountNotSigner`) shows the exchange really does require the user's signature, so the H1 control
  is not an artefact of unverified signatures.
* Point-in-time 2026-10-25; re-read state before acting. Nothing here is an instruction to transact.
* Account substitution at *exo* pairs beyond HYPE (ONYC/PST/WETH/ZEC vaults do not exist) could not
  be exercised because those pairs are not registered/live.

**Files.** `README.md` · `summary.json` · `analysis/` (ELF + sha256, source paths, live state,
results JSONs, `live_state.md`) · `poc/` · `ci/` · `ci-out/`.

*Prepared 2026-10-25 · read-only · no tx signed or sent.*
