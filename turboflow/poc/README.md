# PoC

TurboFlow `svm-bridge` is a **Solana** program, so the Foundry/EVM PoC path does not apply here.

The PoC is a set of read-only **`simulateTransaction` harnesses** in `../analysis/`:

* `sim_swap.py`   — replay a real tx with the **signer swapped** (tests role gates)
* `sim_sub.py`    — replay a real tx with an **account substituted** and/or instruction data patched
* `sim_disc.py`   — call an instruction **by discriminator** with a caller-chosen account list
* `sim_replay.py` — replay a real tx verbatim (control)
* `probe_fields.py` / `auto_chain.py` — recover an instruction's account-struct field order from
  Anchor error messages and `ConstraintSeeds` `Left:`/`Right:` log lines

All harnesses build **legacy messages** (`../analysis/solmsg.py`) with zeroed signatures and submit
them with `{"sigVerify":false,"replaceRecentBlockhash":true}`. **No transaction is ever signed or
sent.** `../ci/run.sh` reproduces the full matrix on GitHub Actions.
