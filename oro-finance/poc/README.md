# poc/

No Foundry project here: the target is a **Solana BPF program** (`iNtiXEFgDNrc6FUt4cFALDe3D8RF3sVnNuKSHwxZRop`),
so a Foundry/EVM fork PoC does not apply.

The proof is instead a set of **read-only `simulateTransaction` probes** (sigVerify:false,
replaceRecentBlockhash:true) built from real on-chain instruction layouts. They live in
`../analysis/` (`sim_sell.py`, `explore.py`, `discover.py`, `reach_test.py`) and are re-run in CI
by `../ci/run.sh`; results land in `../ci-out/oro_sim_results.txt`.

Nothing is signed or sent on any network.
