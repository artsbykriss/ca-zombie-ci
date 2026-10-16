# Deposit authorization gate — fork evidence (2026-10-16)

All experiments on a **local anvil fork** of Robinhood Chain (`anvil --fork-url https://rpc.mainnet.chain.robinhood.com`),
read-only w.r.t. the real chain (fork-only `eth_sendTransaction`, no mainnet writes).

## Experiment 1 — fresh address cannot open a deposit request

| Caller | Action | Result |
|---|---|---|
| `0xF6C1dCA6220983E07930A1a6298f4D00692E3089` (real depositor, factory flag `0x57d41c64` = 1) | `approve(USDG,pToken,5e6)` then `requestDeposit(5e6, U, U)` | **status 0x1 (success)**; `pendingDepositRequest(344, U) = 5,000,000`; U's USDG balance decreased by 5,000,000 (escrowed in the pToken); `nextRequestId` 344 → 345 |
| `0x2222222222222222222222222222222222222222` (fresh, flag = 0, funded + approved identically) | `requestDeposit(5e6, ATT, ATT)` | **status 0x0 (revert)**; `pendingDepositRequest(…, ATT) = 0` |
| U as `owner`, fresh ATT as `controller` | `requestDeposit(1e6, ATT, U)` | **status 0x0 (revert)** — the gate is on the controller |

Trace of the fresh-address call (`debug_traceCall`): the pToken delegatecalls its impl (depth 2), STATICCALLs the
factory (`0x9c3663fa…`, returns fine), then reverts at the branch following an SLOAD of a keccak-derived per-address
slot (`pc 2345`, slot `0x55c80fcc927e95168670d3c034f2b26c4a1f31bde1f03bc07dfa6946a7756ab2` for U) — a boolean
storage flag check. The allowlisted user's trace takes the other branch and continues (1946 vs 893 steps).

## Experiment 2 — redeem side is NOT gated

| Caller | Action | Result |
|---|---|---|
| U transfers 0.1 pBTC3x to fresh ATT | ERC-20 `transfer` | success |
| fresh ATT | `requestRedeem(0.05e18, ATT, ATT)` | **status 0x1 (success)** |
| U | `requestRedeem(0.05e18, U, U)` | status 0x1 |

=> any share holder can exit; deposits are permissioned per controller.

## Experiment 3 — factory per-address flag `0x57d41c64(addr)`

| Address | Role | Flag |
|---|---|---|
| 0x001232c60a… | depositor (fulfilled) | 1 |
| 0x075cb6d281… | depositor + manager-side | 1 |
| 0x46dd8d1e5a… | depositor + redeemer | 1 |
| 0xF6C1dCA622… | depositor + redeemer | 1 |
| 0x9e69595fF6… | depositor + redeemer | 1 |
| 0x90020d5037… | depositor + redeemer | 1 |
| 0x0A2d8AB934… | historical depositor | 0 |
| 0x9D90417eA4… | historical depositor / redeemer | 0 |
| 0x2222222222222222222222222222222222222222 | fresh | 0 |

6/8 historical depositors read 1; two read 0 (the flag may be time-varying or per-account enablement).
Either reading blocks a fresh address, as Experiment 1 shows directly.

## Caveats
- The exact mapping base of the pToken-side flag could not be recovered by brute force over the known
  ERC-7201 bases (keccak keying); the factory view `0x57d41c64` correlates with the observed gate.
- Anvil fork reads depend on the public RPC (no archive; a later fork attempt hit upstream rate limits —
  the experiments above completed before that).
