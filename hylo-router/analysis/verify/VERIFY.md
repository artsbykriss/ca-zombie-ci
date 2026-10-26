# Independent verification — Hylo router (separate code, separate agent)

Artifacts here were produced by an **independent verifier** (child subagent with its own scripts —
`hylo_verify.py`, `derive.py`, `b_extra.py`, `rpc.py`) that re-derived the PDAs from the published
IDL and re-ran the substitution from scratch. Read-only; `simulateTransaction` only.

## Claims under test
1. The router holds no custody and its PDAs (`EXO_REGISTRY`, `EVENT_AUTH`) hold no token accounts.
2. No `router::ID` PDA can equal an `exchange::ID` PDA.
3. Substituting the forwarded CPI program account ⇒ rejected.
4. Substituting `user` with a fresh signer ⇒ rejected.

## Results

| # | Claim | Observed | Verdict |
|---|---|---|---|
| 1 | router program + both PDAs own **0** SPL / Token-2022 token accounts; `EXO_REGISTRY` = `F7BfTbic9AyaNKT7e4eoSbgZC7yxJvutA6S4VzosASg9` **does not exist**; `EVENT_AUTH` = `DsRFnNGgyQCpSH7dDHi6ZC2YnYGnG1J2cEPSyeomDwyj` **does not exist** | `hylo_results.json → structural` | **VERIFIED** |
| 2 | `router_pda_equals_exchange_pda = false` (re-derived independently) | `hylo_results.json → structural` | **VERIFIED** |
| 3 | idx 17 (exchange program) → bogus pubkey | `{"InstructionError":[0,"MissingAccount"]}`; router log: `Unknown program HYEXCHtHkBagdStcJCp3xbbb9B7sdMdWXFNj6mdsG4hn` ⇒ the CPI target is **hard-coded** | **VERIFIED** |
| 4 | idx 0 (`user`) → fresh signer | `{"InstructionError":[0,{"Custom":2015}]}`; exchange log: `AnchorError occurred. Error Code: ConstraintTokenOwner. Error Number: 2015. Error Message: A token owner constraint was violated.` | **VERIFIED** |
| — | CONTROL — the live `route` CPI replayed as-is (amount 100) | **`err: null` (SUCCESS)**, exchange `ConvertStableToLeverExo` reached and returns a value | **VERIFIED** |

The verifier's run also confirms the forwarded custody accounts are exchange-owned
(`collateral_vault FWPLy9vh… owner = GwxovvRAG…` = `exo_vault_auth(HYPE)`, `fee_vault Hh8N3Fdau…
owner = 3HT6dD6A…` = `fee_auth(hyUSD)`).

## Note on error-code naming
The program's own logs are authoritative and are what this repo uses:
`2003 ConstraintRaw`, `2006 ConstraintSeeds`, `2014 ConstraintTokenMint`, `2015 ConstraintTokenOwner`,
`3010 AccountNotSigner`, `3012 AccountNotInitialized`, `6000 UnsupportedPair`.

## Verdict
No counter-evidence. All four claims **independently reproduced**. Not falsified.

*Raw outputs: `hylo_results.json`, `hylo_verify.log`, `derive.py`, `b_extra.py`.*
