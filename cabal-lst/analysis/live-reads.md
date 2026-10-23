# Live reads — Initia mainnet (chain-id `interwoven-1`)

RPC: `https://rest.initia.xyz` (public) · block height at capture: **23,352,892**
(`https://rpc.initia.xyz/status`, 2026-10-23T07:33Z).
Package: `0x53c3f5d8e11844ba3747ebaec1b2d25051574ffbeedc69d72068395991e3ea28`.

View endpoint: `POST /initia/move/v1/view/json` with
`{"address","module_name","function_name","args","typeArgs"}` (scalar args are JSON strings,
`Object<Metadata>` args are quoted strings, per the DefiLlama adapter convention).

| module::function | args | result |
|---|---|---|
| `cabal::get_pools` | — | pool0 xINIT/sxINIT staked `7366894481866`, reward `106990753975`; pool1 USDC-INIT/cbl-USDC-INIT staked `4737924767617`, reward `1879874972251` |
| `cabal::get_support_tokens` | — | INIT `0x8e4733…`, xINIT `0x979ee3…`, sxINIT `0x8e72bf…`, USDC-INIT `0x543b35…`, cbl-USDC-INIT `0xa335e0…` |
| `pool_router::get_real_total_stakes` | INIT meta | `7366894481866` |
| `pool_router::get_real_total_stakes` | USDC-INIT LP meta | `4737924767617` |
| `pool_router::get_real_total_unbonding` | USDC-INIT LP meta | `30246201` |
| `cabal::get_cabal_token_total_supply` | 1 | `2726911250625` |
| `cabal::get_cabal_token_total_supply` | 0 | `5399713244169` |
| `cabal::get_sxinit_total_supply` | — | `5399713244169` |
| `cabal::get_lp_pool_unstaked_pending_amount` | 1 | **`63778039`** (63.778 LP — nonzero) |
| `cabal::get_lp_pool_unstaked_pending_amount` | 0 | `0` |
| `cabal::get_lp_pool_staked_amount` | 1 | `4737924767617` |
| `cabal::get_lp_pool_staked_amount` | 0 | `0` |
| `cabal::get_estimate_unstake_amount` | 1, 1000000 | **`1737428`** |
| `cabal::get_cabal_stake_token_price_rel_to_underlying` | 1 | **`1.737428732502257193`** |
| `cabal::get_stake_estimate` | 1, 1000000 | `{"fee_amount":"0","exchange_rate":"1.737428732502257193","net_converted_amount":"575563"}` |
| `cabal::get_sxinit_to_init_price` | — | `1.045275758486805377` |
| `cabal::get_xinit_to_init_price` | — | `1` |
| `emergency::paused` | — | `false` |

All raw responses: `analysis/live-view-raw.json`.

## Public entry points relevant to H-01
- `cabal::initiate_unstake(signer, type, share_amount)` — permissionless (LP token holders).
- `cabal::batch_undelegate_pending_lps()` — **permissionless**, no signer, rate-limited to once
  per `259200 s` (3 days) via `last_undelegate_time` (disasm L681). It calls
  `cosmos::move_execute(assets_store_signer, "cabal", "process_lp_undelegate", [type, pending])`.
- `cabal::claim_unbonded_assets(signer, indices)` / `claim_all_unbonded_assets(signer)` —
  permissionless, user self-service.
- Admin-only (privileged, not unprivileged-extractable): `manager` role store,
  `emergency::set_pause`, `set_unbond_period`, `set_*_fee_bps`, `change_validator`,
  `admin_overwrite_voting_power_history`.

## USD context (DefiLlama, 2026-10-23)
`protocol/cabal` → Initia $2,114,327 + Cabal $127,578 + Strat $502,890 ≈ **$2.74M**.
`get_pools` price hints: pool0 price_in_usd `0.13328` (INIT), pool1 `0.23617` (USDC-INIT LP).
