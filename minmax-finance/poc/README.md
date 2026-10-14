# poc/ — why there is no Foundry fork project here

An IoTeX fork PoC is **not possible with the public infrastructure available**:

1. `anvil --fork-url <iotex-rpc>` fails against every public IoTeX RPC tested
   (`babel-api.mainnet.iotex.io`, `iotex.api.onfinality.io`, `4689.rpc.thirdweb.com`,
   `iotex-mainnet.public.blastapi.io`) with
   `Error: failed to create genesis … failed to unmarshal height {"blockHash":…,"height":"…"}: hex string without 0x prefix`
   — the IoTeX node returns native fields that foundry's fork client cannot decode.
2. Historical state is pruned: the RPC rejects `eth_getCode`/`eth_call` older than ~3,000 blocks
   (`history is pruned, only supported for latest 3000 blocks`), so a fork could not be pinned to the
   triage block anyway.
3. `eth_call` state overrides are silently ignored (verified by overriding a token `balanceOf` slot and
   reading it back), so a synthetic funded caller cannot be simulated either.

## What is used instead (and runs on CI)

* `ci/run.sh` → `analysis/extract_sim.py`: for every pool and ordered token pair, evaluates the best closed
  cycle `WIOTX →(Mimo V2, 0.3%)→ token_in →(MinMax pool, live calculateSwap())→ token_out →(Mimo V2)→ WIOTX`
  against the **live deployed contracts** at a pinned block, using the pool's own view function for the
  critical leg (the contract's math, not a re-implementation).
* `analysis/saddle_math.py`: a byte-exact Python re-implementation of Saddle v1 `SwapUtils` (getD/getY),
  verified against the live `calculateSwap()` of P1/P2/P5/P7/P9/P11 to **< 25 wei** on every probe — this is
  what establishes that the unverified implementation `0x0e62d07a…` is Saddle v1.
* `analysis/live_swap_evidence.json`: decoded live arbitrage transactions proving the swap paths execute
  (e.g. P5 emitted 27 `TokenSwap` events in a single 2,000-block window; the aggregator bot
  `0x782e8Aa8…` runs 5-hop cycles through P1/P5).

CI run: https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38492711664 (artifacts in `ci-artifacts/`).
