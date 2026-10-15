# Serum Swap — read-only simulations (gate proofs + deployed-math fingerprint)

**Nothing was signed, nothing was sent.** All probes use `simulateTransaction` with
`sigVerify=false`, `replaceRecentBlockhash=true` against
`https://api.mainnet-beta.solana.com`. Raw responses: `sim-results.json`,
`sim-raw-version-probe.json`, `sim-version-probe-analysis.json`; harness: `sim_probe.py`
(+ `sim-config.json`), so every probe can be re-run.

Instruction encoding (from the deployed `instruction.rs`): 1-byte tag, then u64 LE fields —
`1 Swap(amount_in, minimum_amount_out)`, `3 WithdrawAll(pool_token_amount, min_a, min_b)`,
`5 WithdrawSingle(destination_token_amount, maximum_pool_token_amount)`.

Target pool for all probes: `AmHUjHKfSFP34D4VgPsviFNjWrvTN761Yazvv2eKAsSz`
(wSOL/`EPjFWdd5…` = SOL/USDC, $143.5 k, LP supply 12,264,607,061,681 at snapshot).
Common accounts: authority PDA `6PsW2dHTC4JRhKGHx9YKyknfTpYu7n3EZPBiqGz5ypM8`,
vault_a `3vnX3jx5EDeraXUBSLDZbDZM3zz9CE8jd9xAeTp9L8bo` (wSOL),
vault_b `34YKkqGeqGfv3EJDV79Ewga67rZUgQTNDRwYQGoxMDmi` (USDC),
pool_fee_account `Hykjqd4zjw44AGgGspBMdPsopv5F7j96becedqRohdEQ`,
pool_mint `BNbehZgqKVQpdMZiAULM3589B7juRdiBemfWS9awHCaw`.

---

## GATE-A — `WithdrawAllTokenTypes` with the attacker's own **empty** LP account

* Instruction list: `[createIdempotent ATA(payer, wSOL), createIdempotent ATA(payer, USDC),
  createIdempotent ATA(payer, pool_mint), SwaPpA9… WithdrawAll]`
* Attacker LP account = its own ATA of the pool mint → balance **0**.
* Instruction data: `03 e803000000000000 0000000000000000 0000000000000000`
  (tag 3, `pool_token_amount = 1000`, `min_a = 0`, `min_b = 0`).
* Accounts (order): swap, authority PDA, **payer (signer)**, pool_mint (w), LP ATA (w), vault_a (w),
  vault_b (w), USDC ATA (w), wSOL ATA (w), pool_fee_account (w), `Tokenkeg…`.
* Signers in the simulated message: the payer only (legitimately — the attacker owns its own ATAs).

**Observed result** (exact):
```
err: {"InstructionError": [3, {"Custom": 1}]}
logs: Program SwaPpA9LAaLfeLi3a68M4DjnLqgtticKg6CnyNwgAC8 invoke [1]
      Program log: Instruction: WithdrawAllTokenTypes
      Program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA invoke [2]
      Program log: Error: insufficient funds
      Program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA failed: custom program error: 0x1
      Program SwaPpA9LAaLfeLi3a68M4DjnLqgtticKg6CnyNwgAC8 failed: custom program error: 0x1
unitsConsumed: 52957
```
→ The program reached the LP `burn` CPI and the **token program rejected it**: a caller without LP
tokens cannot reach any vault transfer. `E-U` via this path = **$0**.

## GATE-B — `WithdrawSingleTokenTypeExactAmountOut` with the attacker's own **empty** LP account

* Instruction data: `05 40420f0000000000 ffffffffffffffff`
  (tag 5, `destination_token_amount = 1,000,000` = 1 USDC, `maximum_pool_token_amount = u64::MAX`).
* Same account list (10 accounts; `destination` = the attacker's fresh USDC ATA).

**Observed result** (exact):
```
err: {"InstructionError": [3, {"Custom": 1}]}
logs: Program log: Instruction: WithdrawSingleTokenTypeExactAmountOut
      Program Tokenkeg… invoke [2]
      Program log: Error: insufficient funds
      Program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA failed: custom program error: 0x1
      Program SwaPpA9LAaLfeLi3a68M4DjnLqgtticKg6CnyNwgAC8 failed: custom program error: 0x1
unitsConsumed: 79526
```
→ Same gate. Note the compute (37,782 CU inside the swap program) shows the program *computed* the
burn from the pool's real state and then failed at the burn: the exact-out math is reachable, the
value transfer is not.

## VERSION-PROBE — exactly which single-sided-withdraw math is deployed?

Purpose: the deployed build (2021-04-14) predates PR #1794 ("make single token withdrawal fair",
2021-05-25) which replaced `trading_tokens_to_pool_tokens` (deposit formula, `L·(√(1+D′/(S−D))−1)`)
with `withdraw_single_token_type_exact_out` (`L·(1−√(1−D′/S))`) for withdrawals. Because the two
formulas differ by ~2.5 % at a 5 %-of-reserve withdrawal, a single probe distinguishes the versions.

Method (disclosed): the LP source is the pool's own `pool_fee_account`
(`Hykjqd4zjw44AGgGspBMdPsopv5F7j96becedqRohdEQ`, owner `HfoTxFR1…`), which is **marked as the
transaction signer only inside the simulated message** (possible because `sigVerify=false`). This is
a *read-only math probe*, not an attack: the attacker cannot sign for that account and nothing is
executed on-chain. Its only output is the program's internal LP-burn number.

* Instruction data: `05 4587a9d500000000 ffffffffffffffff`
  (tag 5, `destination_token_amount = 3,586,441,445` = 5 % of the USDC reserve, max = u64::MAX).
* Destination: a fresh `createIdempotent` USDC ATA of the payer.

**Observed result** (exact, from `sim-raw-version-probe.json`):

| quantity | observed |
|---|---|
| `err` | `None` (simulated execution **succeeded**) |
| `unitsConsumed` | 80,388 |
| vault B (USDC) pre → post | `71,728,828,918` → `68,142,387,473` (exactly −3,586,441,445) |
| vault A (wSOL) | unchanged `696,794,210,803` |
| LP source pre → post | `7,854,478,786,491` → `7,536,257,737,888` |
| **LP burned** | **`318,221,048,603`** |

**Formula comparison** (`sim-version-probe-analysis.json`; fee on half the output = 4,483,051,
D′ = 3,581,958,394, S = 71,728,828,918, L = 12,264,607,061,681):

| hypothesis | predicted burn | difference vs observed |
|---|---|---|
| **deployed (pre-#1794)**: `ceil(L·(√(1+D′/(S−D))−1))` | `318,221,048,611` | **8 units — 2.5×10⁻¹¹ relative** (spl_math 128-bit fixed-point `sqrt`) |
| post-fix (#1794): `ceil(L·(1−√(1−D′/S)))` | `310,153,567,464` | 8.07×10⁹ — **2.54 %** |

→ The live program **is** the pre-#1794 build (consistent with the binary/date evidence in
`state-summary.md` §4), and that math **over-charges** the withdrawer (it burns more LP than the
later, test-verified "fair" version for the same output). There is no surplus to extract here; the
direction of the discrepancy is a *loss* for whoever withdraws single-sided.

A second, small probe (same shape, `destination_token_amount = 1,000,000` = 1 USDC) also executed
with `err: None` (`sim-results.json`, 68,035 CU) and is kept as a reproducibility check (its burn is
in the ~10⁸-LP range where fixed-point noise dominates any formula discrimination).

---

## Cost of the gates (for the "net profit" question)

* The gate probes cost **52,957 CU** (WithdrawAll, failing) and **79,526 CU** (WithdrawSingle,
  failing) — a few thousand lamports in fees — and deliver nothing. They are included to show the
  gate is not "soft" (not a slippage/argument check that could be set to 0): it is the token
  program's own balance check inside the burn CPI.
* Even with LP tokens, single-sided withdrawal is a **loss-making** round trip (see above); the only
  fair redemption path is `WithdrawAllTokenTypes`, which returns `floor`-ed pro-rata amounts and
  therefore cannot yield more than the LP's share. No flash-loan or capital-side trick exists because
  the shortfall is structural, not capital-dependent.
* Normal `Swap` is open to everyone (that is the product). Its economics are quantified in
  `state-summary.md` §3: $4.22 of realizable mispricing across 292 pools, $13.4 k of real-side value
  behind unmarketable Sollet tokens (requires owning the dead token), $0 attributable to any code
  defect.

## Reproduce

```bash
python3 fetch_state.py                       # enumerate + decode all 340 accounts (public RPC)
python3 analyze_value.py                     # price them, compute arb notes -> pools.json
python3 sim_probe.py sim-config.json         # re-run the four probes (read-only)
```
