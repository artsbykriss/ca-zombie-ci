# Audited repo vs deployed package

## Audited code
- Repo: https://github.com/code-423n4/2025-04-cabal
- Audited commit (linked in every finding): `5b5f92ab4f95e5f9f405bbfa252860472d164705`
  (2025-04-28, "Merge pull request #1 … contest-preparation").
- Repo HEAD today: `d5e21693c56f6ae0e1e6bdf88d2759e4f3f4a7d1` — the only post-audit change is
  `2e4319f chore: add discord channel export` (76 files, **all `discord-export/`**; zero
  `.move` changes). C4 repos are frozen at the contest snapshot; **there is no fix commit in
  this repo to compare against.**
- Audited `Move.toml` named addresses:
  - `staking_addr = 0xe472ba1c00b2ee2b007b4c5788839d6fb7371c6`
  - `vip = 0xe55cc823efb411bed5eed25aca5277229a54c62ab3769005f86cc44bc0c0e5ab`
- Audited module set (10): `bribe, cabal, cabal_token, emergency, manager, package,
  pool_router, snapshots, utils, voting_reward`.

## Where the live protocol actually is
- Live package address (confirmed by the DefiLlama `projects/cabal` adapter querying
  `pool_router::get_real_total_stakes` for live TVL, and by our own view calls):
  **`0x53c3f5d8e11844ba3747ebaec1b2d25051574ffbeedc69d72068395991e3ea28`**
  on **Initia mainnet, chain-id `interwoven-1`** (`https://rest.initia.xyz`).
- The audited `0xe472ba1c…` address has **zero modules** on mainnet:
  `GET /initia/move/v1/accounts/0xe472ba1c00b2ee2b007b4c5788839d6fb7371c6/modules`
  → `{"modules":[],"pagination":{"total":"0"}}`. It is not the live deployment.

## Live module set (16) — newer than the audited 10
`bribe, cabal, delta, utils, router, manager, package, emergency, snapshots, cabal_init,
cabal_token, pool_router, echelon_util, voting_reward, vote_allocator, cabal_init_pool`

New vs audit: `delta, router, cabal_init, cabal_init_pool, echelon_util, vote_allocator`
(the audit scope was 8 of these; the deployed build has 16). Every module carries
`upgrade_policy = COMPATIBLE` (upgradeable in place).

## `cabal` module surface diff (audited source vs live ABI)
- Audited `cabal.move` declares ~53 public/entry functions (incl. test helpers); the live `cabal`
  module ABI exposes **67**.
- **Renamed in the exact H-01 path: audited `process_lp_unstake` → live `process_lp_undelegate`.**
- 20 live-only functions, incl. `process_lp_undelegate, claim_all_unbonded_assets,
  deposit_init_and_stake, deposit_bribe_and_vote, vote_external_using_bribe_weights,
  get_stake_estimate, get_sxinit_to_init_price, get_xinit_to_init_price, set_minimum_stake,
  update_voting_power_history, admin_overwrite_voting_power_history`.
- Live `pool_router` gained unbonding-accounting surface not present in the audit:
  `get_real_total_unbonding, update_unbonding_delegation_cache,
  update_unbonding_delegation_cache_internal, extend_all_delegations, is_whale,
  set_whales, record_external_whale_voting_power, set_token_reward_multiply_bps`, etc.

Conclusion: **the live package is a substantially rewritten, post-audit build. The audited
commit is not the deployed code.**

## Other Cabal deployments (DefiLlama)
- Initia (`interwoven-1`): the LST above — DL $2,114,327.
- `cabal-1` L2 (Cabal appchain): iUSD vault `0x5Eb1A2e8218a0140151ce3445A3799d6C4433f46`,
  Delta-Neutral vault `0x69fdf919612Ef40e89e56282C6891aca41640204` (EVM, ERC-4626) — DL $127,578.
- `strat-1` MiniMove rollup: xSLP vault (`lp`/`vault` modules at
  `0x9a838c8d805e885481f594efee110d6f5b407d530866f4973955afae88941733` /
  `0xd49da8a8c29c1294b98fcb119ae3bdc1cf697ac2b42d63caed608b07941ce111`) — DL $502,890.
  These are separate products (post-H-01) and are **not** the LST audited in 2025-04.
