# Endur — live-state & unprivileged-path evidence

**Date:** 2026-10-24 · **Chain:** Starknet mainnet · **Block:** 16,886,110 · **Method:** read-only `starknet_call` (keyless public RPC `api.cartridge.gg/x/starknet/mainnet`)

## 1. Targets

Endur is a liquid-staking protocol on Starknet. DefiLlama reports **6 ERC-4626 vaults**
(`projects/endur/index.js`, `total_assets`). **All six share the same class hash**
`0x5f06dcb8ef65dd934ba261e6f5ddc03ad3707a028236289feef4ef451f01a52` (verified via
`starknet_getClassHashAt`) — one codebase, one analysis.

| vault | address | total_assets | total_supply | rate |
|---|---|---|---|---|
| xSTRK | `0x28d709c8…4b0a` | 147,406,854.1274 STRK | 124,036,873.6277 xSTRK | 1.188412 |
| strkBTC | `0x047751b3…fd88` | 15.9460 | 15.7610 | 1.011740 |
| xWBTC | `0x6a567e68…fc13` | 25.6075 | 24.8151 | 1.031931 |
| xtBTC | `0x43a35c14…b91` | 3.2726 | 3.1707 | 1.032139 |
| xLBTC | `0x7dd3c80d…fe0` | 0.9764 | 0.9542 | 1.023335 |
| xsBTC | `0x580f3dc5…dc9` | 1.6821 | 1.6290 | 1.032601 |

Pricing (DefiLlama, 2026-10-24): STRK $0.0464816, BTC $80,290.89 →
**xSTRK ≈ $6.85M + BTC vaults ≈ $3.81M ⇒ ≈ $10.66M live**.

Supporting contracts (from `Config` returned by `get_config()` and the project's public
relayer repo `Endur-fi/relayer`):

| role | address |
|---|---|
| WithdrawalQueue (ERC721 of claim tickets) | `0x518a66e5…8b6` |
| ValidatorRegistry | `0x029edbca…931` |
| Treasury | `0x301c5ba2…298` |
| Governor | `0x5be5a5f2…c9` |
| `is_paused` (vault & queue) | `false` / `false` |

## 2. Share math — no free roundtrip

`convert_to_shares` / `convert_to_assets` round **in the vault's favour** (canonical ERC-4626):

| assets in | shares out | assets back | delta |
|---|---|---|---|
| 1e18 | 841,459,336,215,763,425 | 999,999,999,999,999,999 | **−1 wei** |
| 1e21 | 841,459,336,215,763,425,002 | 999,999,999,999,999,999,998 | **−2 wei** |

Redeem direction: 1e18 xSTRK → 1.188411557113657423 STRK → 999,999,999,999,999,999 xSTRK (−1 wei).
No rounding path produces value.

## 3. Unprivileged-path / gate tests (caller = arbitrary)

Every value-moving or configuration entry point reverts for an unprivileged caller:

| call | revert |
|---|---|
| `vault.send_to_withdraw_queue(1)` | `Caller does not have role` |
| `vault.set_config(...)` | `Caller does not have role` |
| `vault.upgrade(1)` | `Caller does not have role` |
| `vault.before_unstake(...)` | `invalid validator` |
| `queue.request_withdrawal(1e18,1e18,0x123)` | **`Only LST can call`** |
| `queue.claim_withdrawal(10692)` (unclaimed) | `Too early to claim` (before owner/claim checks) |
| `queue.claim_withdrawal(1)` (claimed) | `ERC721: invalid token ID` (NFT burned on claim) |

`vault.deposit/mint/deposit_to_validator` are permissionless but only `transferFrom` the
**caller's own** STRK (revert `ERC20: insufficient allowance` for an empty caller) — deposits,
not extraction. `vault.redeem/withdraw` are share-gated (`ERC4626: exceeds max redeem`).
`queue.take_funds(amount)` is **ungated** but does `transferFrom(caller, queue, amount)` — it
pulls the caller's own STRK (a top-up), so it is net-neutral, not an extraction.

## 4. Backing / solvency

`vault.total_assets()` = 147,406,854.13 STRK. Sum of STRK staked across the registry's
validators (`get_validator_token_info` for the 4 STRK-supporting validators):
**147,486,081.44 staked + 28,699.58 pending = 147,514,781.02 STRK** — i.e. `total_assets` is
fully backed (and slightly conservative) by real staked STRK. The vault itself holds 1 STRK
liquid; the queue holds 551,214.29 STRK; the treasury holds 122,571.23 xSTRK.

Withdrawal queue state (`get_queue_state`): `max_request_id` = 10,692,
`unprocessed_withdraw_queue_amount` = 107,926.90 STRK, `intransit_amount` = 2,558,093.63 STRK,
`cumulative_requested_amount` = 126,842,685.14 STRK. A random sample of 700 request ids found
only **2 unclaimed** (25,055.83 STRK total) — the queue is essentially processed and holds
551k STRK against ~108k unprocessed ⇒ **over-funded**.

## 5. Conclusion

No unprivileged (E-U) value path was found. The withdrawal-queue ticket mint is gated to the
LST, all admin/role paths revert, the share math rounds safely, and `total_assets` is backed by
real staked STRK. Residual uncertainty: the class is **unverified** (no source on Voyager /
Starkscan), so the queue's internal FIFO/distribution logic (`take_funds`,
`reduce_total_queue_amount`, `cumulative_requested_amount_snapshot`) is assessed only
behaviourally; every entry point reachable by an outsider is gated or net-neutral.
