# Prosper Alpha — PoC notes

## Why there is no runnable Foundry fork here

`poc/test/ProsperAlpha.t.sol` is the Foundry fork test suite (round-trip P&L + role-gate reverts).
It **cannot run against the public Pharos RPC**: `rpc.pharos.xyz` returns a **non-standard
`eth_getProof`** payload — each proof node is an object `{nextBeginOffset, nextEndOffset, proofNode}`
instead of the standard hex string — so `anvil`/`forge` fail with
`database error: failed to get account for 0x0…: PARSE_VERIFY_ERROR: failed to parse block hash or number`.
That is a **tooling block, not a code result**. `poc/foundry.toml` is therefore renamed to
`foundry.toml.DISABLED` so the shared CI workflow does not attempt `forge test`.

## What actually runs (the PoC)

`ci/poc_sim.py` — a **read-only** `eth_call` simulation driven by `cast call` (no tx signed/sent),
invoked from `ci/run.sh` on GitHub Actions. It reproduces exactly the assertions of the Foundry
suite against live chain state:

- **A.** `quoteBuy(x)` → `quoteSell(pOut)` round-trip for 5 sizes × all 4 live markets
  (3 phase-0 + 1 phase-3) — asserts `netBack <= x` (always a ~2 % loss: symmetric `x·y=k` + 1 % fee each way).
- **B.** privileged value-movers called from an unprivileged EOA — asserts each **reverts**
  (`migrateToExternal`→`UnauthorizedRole(MIGRATOR_ROLE)`, `addLiquidity`, `LpTimeLock.claim`→`OwnableUnauthorizedAccount`,
  `LpTimeLock.register`, `Buyback.withdrawUsdc`→`UnauthorizedRole(FEE_OPERATOR_ROLE)`,
  `Factory.upgradeToAndCall`→`UnauthorizedOwner`, `AccessController.upgradeToAndCall`→`AccessControlUnauthorizedAccount`,
  `PTokenClaim.claim` with a forged allocation).
- **C.** `refreshPhase()` (permissionless) moves no WPROS.

Result: **29/29 PASS** (see `ci-out/poc_results.txt` in the CI artifacts).

The Foundry test can be run against any Pharos RPC that serves standard `eth_getProof`
(e.g. a full archive node) with:
`PHAROS_FORK_BLOCK=<n> forge test -vvv` (0 = latest).
