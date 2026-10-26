# Perena (Numéraire) — Solana stable-swap "hinted" swap — residual deep-dive

**Date:** 2026-10-25/26 · **Chain:** Solana (mainnet-beta) · **Program:** `NUMERUNsFCP3kuNmWZuXtm1AaQCPj9uw6Guv2Ekoi5P`
**Status:** read-only; `simulateTransaction` (sigVerify:false) only; **no mainnet transaction signed or sent**. PoC = read-only simulation battery, re-run in CI.

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why closed | Latent risk |
|---|---|---|---|
| **Perena Numéraire `SwapExactInHinted`** (caller-supplied `hints:[u64;10]`) | **$0** | Deployed program (v0.1.3) **rejects any non-zero hint** with `UnsupportedFeature` (6008) at `swap_in.rs:252` *before* any swap math — the hinted path is disabled/stubbed. `hints=0` falls back to the ordinary hintless curve path. | None found on-chain. Off-curve upgrade auth (P-class). |
| **Perena privileged setters** (`set_owner/set_fee/set_status/set_inv_t_max/set_rate/set_whitelisted_adder/set_numeraire_*`) | **$0** | All gated `OnlyOwner` (6000) / account-validated (6005) | P-class (owner = `CPJo7euW…`, off-curve PDA) |
| **Perena LP paths** (`add_liquidity/remove_liquidity/remove_all_liquidity/skim/compound`) | **$0** | `payer_lp_account` must be owned by the caller (`ConstraintTokenOwner` 2015); `add_liquidity` is whitelist/owner-only | H-O (LP holders self-service) |

## 2. Total live extractable now: **$0** (confidence: **high**)

The program custodies **~$557,709** of stablecoin swap liquidity across 10 pools, but no unprivileged
extraction path exists. The "hinted swap" primitive that pass-7 flagged as the lead is **explicitly
disabled in the deployed bytecode**; every privileged setter is owner-gated; every LP operation is bound
to the caller's own LP token account.

---

## 3. The mechanism in exact terms

Perena's Numéraire program is an Anchor (v0.1.3) Curve-style stable-swap. The pass-7 lead was the
instruction `swap_exact_in_hinted`, whose arg struct `SwapExactInData` carries a caller-supplied
`hints: [u64;10]` + `path_hints: [u8;10]` (recovered from the SDK IDL `quineco/numeraire-sdk`,
`src/idl/numeraire.json`). The binary contains the string
*"The hints provided do not bound the swap amounts"*, suggesting a hint-validation check.

**Finding: the hinted code path is not enabled.** Simulating the live program with a non-zero hint in any
position returns:

```
Program log: Instruction: SwapExactInHinted
AnchorError thrown in numeraire/programs/numeraire/src/processors/swap_in.rs:252
Error Code: UnsupportedFeature. Error Number: 6008.
Error Message: This feature is currently unsupported or unenabled.
```

This happens at ~18.7k CU (before the swap math runs — the hintless path reaches ~116k CU to the balance
check). Every non-zero hint value tested (1, 10, 1000, 1e5, 1e9, 1e15, 2^63, 2^64−1, and a single
position set) yields the same `UnsupportedFeature`. `path_hints` is ignored entirely (non-zero
`path_hints` with `hints=0` behaves exactly like the hintless path). Only `hints = [0;10]` proceeds — i.e.
there is no caller-controlled hint that reaches the curve solver. **The primitive is closed by design in
this deployment.**

The symmetric exit-side instruction behaves identically: `swap_exact_out_hinted` with any non-zero hint
returns `UnsupportedFeature` (6008) at `swap_out.rs:111`, while `hints=0` reaches the normal path
(`InputTooBig` 6017 at `swap_out.rs:87`). So *both* hinted variants are disabled — this is a general
hint-path guard, not a per-pool status artifact.

Deployed-code references (from the dumped ELF `analysis/perena.so`, 1,100,691 bytes, ProgramData
`64h2hsxpnUprJu87bwH7HcYxoVtbidw95bZ7m5JTXGp`, last deploy slot **329,553,166**):
instruction names `InitVirtualStablePair, CreatePool, SwapExactInHinted, SwapExactIn, SwapExactInQuote,
SwapExactOutHinted, SwapExactOut, RemoveLiquidity, AddLiquidity, SetStatus, SetInvTMax, SetFee, SetOwner,
Skim, Compound, RemoveAllLiquidity, SetLpTokenMetadata, SetRate, SetNumeraireOwner, SetNumeraireStatus,
SetNumeraireWhitelistedPoolCreator, SetWhitelistedAdder`.

---

## 4. Live-state assessment

Read at slot **461,376,799** (RPC `api.mainnet-beta.solana.com`); pool decode re-verified in CI.

- Program `NUMERUNsFCP3kuNmWZuXtm1AaQCPj9uw6Guv2Ekoi5P`: owner `BPFLoaderUpgradeab1e…`, executable,
  ProgramData `64h2hsxpnUprJu87bwH7HcYxoVtbidw95bZ7m5JTXGp`, **upgrade authority `CPJo7euW…` (off-curve
  PDA)**, last deploy slot 329,553,166, ELF 1,100,691 bytes.
- `NumeraireConfig` = `FS159v4b2jo3fjGBaUFmDzgx7k616XhpKhMwX2Q3HeeD` (1480 bytes): owner `CPJo7euW…`,
  status = 1.
- 10 live `StablePool` accounts (4024 bytes each). Reserves (all stables @ $1):

| Pool | status | n | ≈USD |
|---|---|---|---|
| `2w4A1eGyjRutakyFdmVyBiLPf98qKxNTC2LpuwhaCruZ` | 16 | 3 (USDC/USDT/USD*) | 284,705.75 |
| `4FxWowiGfd8oseveAdXYafzc3fczKda9zi65oj6jqbtL` | 119 | 2 (sUSD/USD*) | 167,523.56 |
| `3PHVBLYZnJE4SXEAJ6seQLhxNprpECgTfCot5XgVNUZ5` | 119 | 2 (USDS/USD*) | 57,189.05 |
| `Gi3dGkokskdTFP7k7cmLBdmdbsQzd6VQcMWo5VyU82BZ` | 119 | 2 | 22,851.75 |
| `D99Hw2auf97WjzKPXZnpxTvJBt2TD6pPnk3a7uHceHqj` | 16 | 2 (USDC/AUSD) | 8,055.65 |
| `5M7McNWX7yBBGrZGB6XhmHYhFwWwwB2ckrA1HEpkf3SA` | 16 | 2 | 8,039.77 |
| `3jcCKowE3KdNro2QVETcVghGdTSQrCA7i9rbfZHhepEi` | 119 | 2 | 7,480.86 |
| `DvggYdonWQdygGvgtM5SrVLMhkYxgdTDr199yc673bF` | 16 | 2 | 1,666.30 |
| `6rYsH85HXG7w7ZCtYRwfj4T2fsUdGtmWWo52hRGRuVNr` | 16 | 2 | 196.34 |
| `ArzxRGqCTGpXD95JPeEYHREgARSMfBSUfX6CZorwSdWS` | 0 (test) | 2 (mzero) | 0.10 |
| **TOTAL** | | | **$557,709.12** |

`inv_T_max = 0` on every pool (cap disabled/unused). Real swaps are live: e.g. `swap_exact_in` on pool
`2w4A1eGy…` at slots 461,374,985 / 461,364,947 / 461,356,906 (routed via Jupiter, `swap_exact_in`
discriminator `68688356a1bdb4d8`; args `in_index/out_index/exact_amount_in/min_amount_out`).
No live tx uses the hinted variant.

---

## 5. What an attacker can / cannot do

**Cannot (proven by simulation):**
- Bypass the swap bound with a crafted hint — any non-zero hint → `UnsupportedFeature` (6008).
- Take pool ownership (`set_owner`) — `OnlyOwner` (6000).
- Change fee/status/inv_T_max/whitelisted-adder — `OnlyOwner` (6000).
- Change the Numéraire config owner/status/whitelisted-creator — `OnlyOwner` (6000).
- Change a mint rate (`set_rate`) — account validation fails first (`IncorrectAccounts` 6005).
- Redeem/compound/skim someone else's LP position — `payer_lp_account` must be owned by the caller
  (`ConstraintTokenOwner` 2015).
- `add_liquidity` — whitelist/owner-only (docs) and owner-bound LP account.

**Can:** trade against the pools at the ordinary curve price (no edge). Hold LP and redeem own share
(H-O). `skim`/`compound` are permissionless keepers but act only on the caller's own LP account and take
no attacker-controlled args.

**Preconditions/costs:** none reachable. No flash loan or capital helps because the extraction path does
not exist.

---

## 6. PoC / fork-verification

Read-only simulation battery (attacker-built legacy messages, neutral funded signer as the only signer,
real program/pool/config/vault accounts, `sigVerify:false`, `replaceRecentBlockhash:true`).

- `analysis/perena_hint_test.py` — hinted/quote battery across hint values (baseline + 8 values + 4 hinted).
- `analysis/perena_auth_test.py` — 12 privileged/LP instructions with an unprivileged payer.
- `analysis/decode_pools.py` — live StablePool decoder (10 pools, sizes verified).
- CI job `perena/ci/run.sh` re-ran the whole battery on a GitHub runner.

**Results: PASS (all negative — no extraction).** CI run
**https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40232700278** (conclusion: success; artifact
`result-perena`, 5 files). Local re-run reproduced identically.

Key CI evidence lines:
- `[hinted h=1] err=…Custom 6008 … swap_in.rs:252 UnsupportedFeature`
- `[hinted h=0] err=…Custom 6015 … swap_in.rs:159 InsufficientBalance` (hintless path, blocked only by the
  empty test trader balance)
- `[set_owner] … OnlyOwner (6000)`; `[set_fee] OnlyOwner`; `[set_rate] IncorrectAccounts (6005)`
- `numeraire pool reserves (all stables @ $1): $557709.12`

---

## 7. Verdict & residual risk

- **E-U = $0 (high confidence).** The flagged hinted-swap primitive is disabled in the deployed program;
  no unprivileged drain exists.
- **H-O** ≈ $557.7k (LP holders can redeem their own pro-rata share; normal).
- **P** = pool/config ownership and the **off-curve upgrade authority `CPJo7euW…`** (a PDA → Squads /
  program-controlled; an authority holder could upgrade and drain). Not E-U.
- **S** = $0.

**Blockers / caveats:** (1) BPF was not decompiled — the "hinted disabled" conclusion rests on the live
program's deterministic `UnsupportedFeature` revert plus the SDK IDL; the exact source of line 252 is not
read. (2) The `swap_exact_in_quote` return-data path emitted a quote but then reverted `Unreachable`
(6032) under my account set; not needed for the verdict. (3) Balances/prices are point-in-time at
2026-10-25/26 and should be re-read before acting. (4) Nothing here is an instruction to transact.

---

## 8. Methodology & sources; files index

**Method:** program account/upgrade-auth probe (`getAccountInfo`, `probe.py`); ELF dump + `strings`
(`dump_elf.py`); Anchor on-chain IDL probe (`fetch_idl.py`, not published); IDL recovered from the
project's public SDK (`quineco/numeraire-sdk`, `src/idl/numeraire.json`); `getProgramAccounts` +
custom `StablePool` decoder; `getSignaturesForAddress`/`getTransaction` for real swaps; and
`simulateTransaction` (sigVerify:false) for the hint and authority batteries. DefiLlama adapter
(`projects/perena/index.js`) confirmed the program id and TVL scope. CI: `bash ci/ci-run.sh perena`.

**Files:** `analysis/probe.py`, `analysis/dump_elf.py`, `analysis/fetch_idl.py`, `analysis/scan_idl.py`,
`analysis/decode_pools.py`, `analysis/perena_sim.py`, `analysis/perena_hint_test.py`,
`analysis/perena_auth_test.py`, `analysis/find_swap.py`, `analysis/perena.so`,
`analysis/numeraire_sdk_idl.json`, `analysis/pools.json`, `analysis/perena_strings.txt`; `ci/run.sh`;
`ci-out/`; `ci-log.txt`; `ci-artifacts/`; `summary.json`.

*Prepared 2026-10-26 · ZH4 pass-7 · Solana · read-only · no tx signed/sent.*
