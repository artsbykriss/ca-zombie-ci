# xALPH — PoC / verification notes

**Alephium is not an EVM chain**, so a Foundry `forge test` PoC does not apply here
(Alephium contracts are written in the **Ralph** language and run on the Alephium
UTXO + VM model; there is no `anvil`/EVM fork of Alephium). There is therefore **no
`poc/foundry.toml`** in this folder and the CI workflow's `forge test` step is skipped.

The verification that would normally live in `poc/` is instead:

| What | Where |
|---|---|
| Exact deployed-code read: the on-chain bytecode is byte-identical to the published SDK artifact, and a Ralph disassembler reconstructs every method | `../analysis/xalph_token_disasm.txt` (built by the codec in `@alephium/web3`) |
| Mint/burn arithmetic re-implemented and searched for a profitable round-trip (P1), rate monotonicity (P2), first-staker edge (P3) | `../analysis/roundtrip_math.py` (also run in CI: `ci/run.sh`) |
| Live-state re-read (backing vs supply, reserve, reward collector, method-13 check) | `../analysis/live_state.py` (also run in CI) |

The only "fork" available for a non-EVM chain is the live chain itself, and the whole
investigation is **read-only** (view calls / `multicall-contract` simulations and
`/contracts/{address}/state` reads). **No transaction was signed or sent.**

Reproduce locally (public keyless endpoints only):

```bash
python3 analysis/roundtrip_math.py --big
python3 analysis/live_state.py
```
