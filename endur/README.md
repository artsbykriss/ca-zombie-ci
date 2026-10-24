# Endur (Starknet) — zombie-hunt deep dive

**Date:** 2026-10-24 · **Chain:** Starknet mainnet · **Block:** 16,886,110
**Status:** read-only; PoC is call-gate + fork-simulation evidence; **no signed/broadcast transactions**.

## TL;DR

| target | live extractable (unprivileged) | why closed | latent risk |
|---|---|---|---|
| Endur xSTRK + 5 BTC ERC-4626 vaults (`0x28d709c8…` class `0x5f06dcb8…`) ≈ **$10.66M** | **$0** | Share math rounds in the vault's favour; every privileged entry point reverts for an outsider; the withdrawal-queue ticket mint is gated `Only LST can call`; `total_assets` is fully backed by real staked STRK | class is **unverified** (no source on Voyager/Starkscan) — the queue's internal FIFO/distribution logic is assessed behaviourally only |

## Total live extractable now: **$0** (confidence: **medium-high**)

## The mechanism / why this was open

Pass-3 flagged Endur as "$12.03M DL, ERC-4626 over STRK/BTC with a withdrawal queue —
**not deep-read**: Starknet public RPC endpoints are dead/require keys". A working keyless
Starknet RPC (`api.cartridge.gg/x/starknet/mainnet`) was located, and the vault + queue +
registry were read live.

Endur is a liquid-staking protocol: an ERC-4626 vault (`xSTRK`, plus `xWBTC/xtBTC/xLBTC/xsBTC/strkBTC`)
that stakes STRK/BTC through a `ValidatorRegistry`, and a separate ERC-721 **WithdrawalQueue**
where each redemption mints a claim ticket NFT.

**All six vaults share one class hash** (`0x5f06dcb8…`) — one codebase.

## Live-state assessment

| item | value |
|---|---|
| xSTRK vault | `0x028d709c875c0ceac3dce7065bec5328186dc89fe254527084d1689910954b0a` (asset = STRK) |
| WithdrawalQueue (ERC721) | `0x518a66e579f9eb1603f5ffaeff95d3f013788e9c37ee94995555026b9648b6` |
| ValidatorRegistry | `0x029edbca81c979decd6ee02205127e8b10c011bca1d337141170095eba690931` |
| Treasury / Governor | `0x301c5ba2…298` / `0x5be5a5f2…c9` |
| paused | vault `false`, queue `false` |
| xSTRK total_assets / total_supply | 147,406,854.13 STRK / 124,036,873.63 xSTRK (rate 1.188412) |
| BTC vaults total_assets | strkBTC 15.946 · xWBTC 25.6075 · xtBTC 3.2726 · xLBTC 0.9764 · xsBTC 1.6821 |
| USD (STRK $0.0464816, BTC $80,290.89) | xSTRK ≈ **$6.85M** + BTC ≈ **$3.81M** ⇒ **≈ $10.66M** |
| staked STRK (registry sum) | **147,486,081.44** staked + 28,699.58 pending ≥ total_assets ✅ backed |
| queue STRK balance | 551,214.29 STRK vs 107,926.90 unprocessed ⇒ over-funded |
| queue requests | max id 10,692; 700-id sample ⇒ only 2 unclaimed (25,055.83 STRK) |

## What an attacker can/cannot do

Tested live via `starknet_call` (caller = arbitrary/zero):

| attempted call | result |
|---|---|
| `vault.send_to_withdraw_queue(1)` | revert `Caller does not have role` |
| `vault.set_config(...)` / `vault.upgrade(1)` | revert `Caller does not have role` |
| `vault.before_unstake(...)` | revert `invalid validator` |
| `queue.request_withdrawal(1e18,1e18,attacker)` | revert **`Only LST can call`** |
| `queue.claim_withdrawal(claimed id)` | revert `ERC721: invalid token ID` (NFT burned on claim) |
| `queue.claim_withdrawal(unclaimed id)` | revert `Too early to claim` |
| `vault.convert_to_shares→convert_to_assets` (1 STRK) | 0.999999999999999999 STRK (**−1 wei**) |

`deposit/mint/deposit_to_validator` are permissionless but only `transferFrom` the caller's own
STRK. `queue.take_funds(amount)` is ungated but pulls the **caller's own** STRK (a top-up ⇒
net-neutral). No path moves another party's value to the attacker.

## PoC / fork-verification

There is no Foundry fork for Starknet; the PoC is a **live `starknet_call` gate + share-math
harness** (`ci/run.sh`, re-run in CI → `ci-out/endur-checks.json`) plus the backing reconciliation.
Key results: all gates revert; roundtrip `−1/−2 wei`; `staked_covers_total_assets = true`.
`poc/README.md` documents the approach. CI run URL in `ci-log.txt` / `ci-artifacts/`.

## Verdict

**E-U $0 (medium-high).** No unprivileged value path. Residual (not E-U): the queue's internal
distribution logic is unreadable because the class is unverified — but every outsider-reachable
entry point is gated or net-neutral, and the queue is over-funded.

## Methodology & sources

- Live `starknet_call` / `starknet_getClassHashAt` over keyless public RPC `api.cartridge.gg`.
- Public relayer repo `Endur-fi/relayer` for the ABIs (`LST.ts`, `WithdrawalQueue.ts`,
  `ValidatorRegistryAbi.ts`) and addresses (`src/common/constants.ts`).
- DefiLlama adapter `projects/endur/index.js` (6 vaults) + `coins.llama.fi` prices.
- **No secrets, no keyed URLs, no signed transactions.**

## Caveats & limitations

- Contract classes are **unverified**; logic is inferred from ABI + behaviour.
- `reduce_total_queue_amount`'s exact signature could not be resolved (no calldata form
  deserialised); it is an admin-style reducer and, at worst, a griefing surface, not extraction.
- USD is price-sensitive (STRK/BTC moved during the session).

## Files

- `analysis/live-state.md` — full live-state & gate evidence
- `poc/README.md` — PoC approach (Starknet call harness)
- `ci/run.sh` — network job (gates + math + backing → `ci-out/endur-checks.json`)
- `summary.json` — machine-readable summary
