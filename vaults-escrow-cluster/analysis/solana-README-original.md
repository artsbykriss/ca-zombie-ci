# Solana analysis workspace — ZOMBIE-HUNT IV

Read-only. Nothing here signs or broadcasts transactions.

## Quick start

```bash
cd /home/heisenberg/CA/vaults-escrow-cluster/analysis/solana
python3 -c 'import rpc; print(rpc.slot())'        # RPC health + slot
cat FINDINGS.md                                   # report
jq . verdicts.json                                # machine-readable verdicts
```

## Files

| Path | Purpose |
|---|---|
| `rpc.py` | Minimal JSON-RPC client (retries, finalized reads) |
| `pda.py` | Solana PDA derivation with a dalek-compatible on-curve check |
| `txutil.py` | Legacy transaction decode/build helpers (kept for reference) |
| `sim.py` | `simulateTransaction` helper using solders serialization; `sigVerify:false` |
| `decode_offerbook.py` | Zero-copy Offerbook Offer/Loan/User/Config decoders |
| `collect_offerbook.py` | End-to-end Offerbook state + escrow + Jupiter pricing collector |
| `evidence/` | Raw JSON dumps, ELF/strings, simulations, prices |
| `FINDINGS.md` | Full report with slots, call paths, blockers |
| `verdicts.json` | Per-target E-U / H-O / P / S summary |

## Important caveats

* `collect_offerbook.py` aggregates loan-vault value by the loan's *principal* mint; the
  loan vault actually holds **collateral**. Its `totals_usd.loan_vaults` is therefore wrong.
  The corrected figure is in `evidence/offerbook_summary.json` (and `verdicts.json`).
* The public Offerbook IDL is stale for `repay_token_loan` (now takes `Option<u64>`) and
  for the five yield instructions. Tested paths were validated against live transactions
  and simulation.
* PiggyBank has **two** programs; pbSPYx is on `Pig2ienhM3…`, not `Pig1CsXn…`.
* All "success" results are simulations against live state; nothing was persisted.

## Reproduce the key probes

* Offerbook withdraw binding: see `evidence/sim_withdraw.json` (`InvalidOwner` 6013).
* Offerbook fill binding: `evidence/sim_fill2_attack_lenderA_userB.json`,
  `evidence/sim_fillcoll_attack_borrowerX_userC.json`.
* Offerbook claim binding: `evidence/sim_claim.json`, `evidence/sim_claim_borrower.json`.
* Offerbook repay/token-program substitution: `evidence/sim_repay_fakeprogram.json`.
* PiggyBank round trips: `evidence/sim_piggy_roundtrip_usdc.json`,
  `evidence/sim_pig2_roundtrip.json`.
* PiggyBank claim binding: `evidence/sim_piggy_claim2.json`,
  `evidence/sim_piggy_claim_attack.json`.
