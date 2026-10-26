# Independent verification — Archer Exchange (separate code, separate agent)

Artifacts in this directory were produced by an **independent verifier** (a child subagent with its
own, separately-written scripts — `archer_sim.py`, `archer_sim_matrix.py`, `enumerate.py`, `rpc.py`)
that did **not** use the parent's PoC. It re-enumerated maker books and re-ran the maker-book
substitution from scratch. Read-only; `simulateTransaction` only.

## Claim under test
> An unprivileged signer cannot withdraw a victim maker's free balance by passing the victim's
> `MakerBook` PDA (`MakerWithdrawFunds`, tag 12).

## Result: **VERIFIED**

| Case | Observed | Where |
|---|---|---|
| ATTACK — fresh signer as `maker` + `authority`, **victim's** `MakerBook` | `{"InstructionError":[2,{"Custom":502}]}` (`UnauthorizedMaker`) | `sim_taskA.json`, `sim_taskA_matrix.json` (slot 461 395 776) |
| CONTROL — victim as `maker`+`authority` + victim's own `MakerBook` | **`err: null` (SUCCESS)**, 15 380 CU | `sim_taskA_matrix.json` |

The verifier's own enumeration (`maker_books.json`, `candidates.json`) found the same shape of
state: e.g. book `hAcfvB8xtTHAUsbtwiS8DSsU4JJw7svAv3ELLLGYJNw` for maker
`AJHBvSxP2r1bVgLC7LBYNn6YsmdrdwZEG2QncTj3jezF` on market `2Tk1fXG1RuEAqqttVWj2DLXSHabb6QvsTJDFqFZa1uT2`
with `quote_free = 3700`, `len = 776`.

## Verdict
No counter-evidence. The parent's conclusion (substitution rejected; positive control reaches the
handler) is **independently reproduced**. Not falsified.

*Raw outputs: `sim_taskA.json`, `sim_taskA_matrix.json`, `maker_books.json`, `candidates.json`,
`enumerate.log`, `sim_matrix.log`.*
