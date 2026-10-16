# Z3-H12 — Robinhood Chain public RPC / archive blockers (measured 2026-10-16)

## Public RPC
- `https://rpc.mainnet.chain.robinhood.com` — reachable, current-state `eth_call`/`eth_getLogs`
  (10M-block log ranges OK), `debug_traceCall` NOT available, archive NOT available.
- `eth_getLogs` over the full history of a pToken works in 10M-block chunks (used to rebuild the
  full 797-event NAV timeline).
- Etherscan V2 (chainid=4663) works for `txlist`, `getcontractcreation`, `eth_getTransactionByHash`
  (`module=proxy`). `eth_getTransactionReceipt` via Etherscan proxy returned empty logs on this chain;
  `eth_getLogs` on the public RPC was used instead.
- No verified source on Etherscan V2 or Sourcify v2 for any Arcus contract (factory impl
  `0x58bdc1d3068a0a79d7a662dee033d62cbd4f589f`, pToken impl `0x1815A37B6027Ae8066720d873A508F25fC151AC5`,
  beacon, bridge vault, factory proxy).

## Archive blocker
- Historical state is NOT available on the public RPC:
  `historical state d625b018... is not available` for `eth_call` at block 88864768
  (2 days old). This blocked two experiments:
  1. Replaying a signed NAV-update payload at a block within its validity window (to distinguish
     manager-gating from signature/epoch checks).
  2. Cross-token replay of a signed NAV payload on another pToken with the epoch state untouched.
- Fallbacks used instead: (a) replaying payloads at current state (both attacker and manager revert
  identically with `0x3ac328da(epoch,1,2)` — i.e. payloads are single-use/time-bound);
  (b) tracing SLOADs (`debug_traceCall` on a local anvil fork) to locate the epoch-state slot
  (`0x35c8245d61a7be11e113207cf273377bdf37e8520f503e3d58f1319aa7fbd8dd`, per-contract value,
  BTC-3x=2 consumed, HOOD-3x=0);
  (c) full event-history reconstruction from `eth_getLogs`.

## Tools used
- heimdall 0.x decompiler (impl bytecode), panoramix (failed to lift the proxy target cleanly),
  foundry (cast/anvil/forge), anvil fork at port 8545 (local, read-only simulations), Python for
  calldata decoding, CoinGecko for BTC hourly prices.
