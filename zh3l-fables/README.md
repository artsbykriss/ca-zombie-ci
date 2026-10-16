# zh3l-fables — L6 live-extractability re-probe of Fables (Robinhood Chain, 4663)

Re-run of the Z3-H13 conclusions against **today's** chain state, with fresh fork evidence.
Read-only; public RPCs only; no keys.

- Target: `FablesPoolRegistry 0x159a113e…13ef3` (68 pools) · hooks `FablesRamp 0x08e52564…`,
  `FablesRWA 0x5eb87f69…`, `FablesRampETH 0x594e8e62…`, `FablesRWAETH 0xca89f079…`,
  pre-fix `FablesRampETH 0x06a88987…`.
- Tests (`poc/test/L6Fables.t.sol`): F1 drift vs prior finding (unchanged address/sink/code state),
  F2 permissionless native sweeps pay **only** the Safe, F3 old-hook park defect inert today /
  conditional on external inflow, F4 round-trip not profitable, F5 pots backed by ERC-6909 claims,
  F6 restricted surface closed for a fresh caller.
- Run: `cd poc && forge test -vvv` (keyless public RPC via `_pickRpc()`).

Result: 6/6 PASS at fork of live state. Best case for a fresh address: **$0**.

Full analysis: `../zombie-hunt-iii/work/L6-fables-valos.md`.
