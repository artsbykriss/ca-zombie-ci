# Version/import candidates — Sui fresh cluster (auto-generated)

Functions present in OLD versions but ABSENT from the LATEST (name-level), excluding error/constant/event modules.
Presence-only; bodies may also differ (see body_diff.json). Generated 2026-10-25.

| family | versions | latest | old-version real fns not in latest |
|---|---|---|---|
| dipcoin | 9 | v9 | evaluator::verify_min_max_qty_checks (v1,2); library::add_intent_bytes_and_hash (v1,2,3,4,5,6); library::get_oracle_base (v1,2); library::get_oracle_price (v1,2); library::get_oracle_price_and_base (v3,4,5,6); library::get_price_identifier (v1,2,3,4,5,6); library::get_public_address (v1,2,3,4,5,6); library::get_result_public_key (v1,2,3,4,5,6); library::get_result_status (v1,2,3,4,5,6); library::verify_signature (v1,2,3,4,5,6); order::get_serialized_order (v1,2,3,4,5,6); order::verify_order_signature (v1,2,3,4,5,6); perpetual::update_oracle_price (v1,2,3); price_feed::get_price (v4,5,6); price_feed::get_prices_map (v4,5,6); price_feed::is_empty (v4,5,6); price_feed::price_info_perp_id (v4,5,6); price_feed::size (v4,5,6); price_feed::to_vectors (v4,5,6); protocol::add_settlement_cap_id (v1,2,3,4,5,6,7); protocol::remove_settlement_cap_id (v1,2,3,4,5,6,7); roles::check_settlement_operator_validity (v1,2,3,4,5,6,7) |
| bluefin-pro | 21 | v21 | account::compute_margin_required (v1,2,3,4,5,6,7,8,9,10); margining_engine::settle_pending_funding_payment (v1,2,3,4,5,6,7,8,9) |
| suigar | 2 | v2 | oracle::get_usd_price (v1) |
| bucket-vault | 4 | v4 | — |
| bucket-pool | 4 | v4 | — |
| alphalend | 15 | v15 | market::get_supply (v1,2,3,4,5,6,7,8,9,10); market::get_token_price_for_collateral (v1,2,3,4,5,6,7,8,9,10); market::split_promise_market_fee (v1,2,3,4,5,6,7,8,9,10); sui_staker::get_latest_exchange_rate (v1,2,3,4,5,6,7,8,9,10) |
| alphafi-oracle | 5 | v5 | — |
| kai-leverage | 21 | v21 | position_core_clmm::set_config_extension (v11,12,13,14,15,16) |
| kai-access | 2 | v2 | — |

## Function-BODY changes first->latest (non-error modules)

| family | module | changed | removed |
|---|---|---|---|
| dipcoin | bank | 7 | — |
| dipcoin | evaluator | 17 | verify_min_max_qty_checks |
| dipcoin | exchange | 9 | — |
| dipcoin | funding_rate | 2 | — |
| dipcoin | insurance_fund | 7 | — |
| dipcoin | isolated_adl | 2 | — |
| dipcoin | isolated_liquidation | 2 | — |
| dipcoin | isolated_trading | 3 | — |
| dipcoin | library | 1 | add_intent_bytes_and_hash, get_oracle_base, get_oracle_price, get_price_identifier, get_public_address, get_result_public_key, get_result_status, verify_signature |
| dipcoin | order | 24 | get_serialized_order, verify_order_signature |
| dipcoin | perpetual | 13 | update_oracle_price |
| dipcoin | position | 4 | — |
| dipcoin | protocol | 11 | add_settlement_cap_id, remove_settlement_cap_id |
| dipcoin | roles | 14 | check_settlement_operator_validity |
| dipcoin | s128 | 10 | — |
| dipcoin | settlement | 1 | — |
| dipcoin | sub_accounts | 3 | — |
| dipcoin | test | 5 | — |
| bluefin-pro | account | 18 | — |
| bluefin-pro | bank | 1 | — |
| bluefin-pro | bcs_handler | 1 | — |
| bluefin-pro | data_store | 10 | — |
| bluefin-pro | exchange | 17 | deposit_to_asset_bank<Ty0> |
| bluefin-pro | margining_engine | 4 | — |
| bluefin-pro | perpetual | 27 | — |
| bluefin-pro | signature | 11 | — |
| bluefin-pro | signed_number | 6 | — |
| bluefin-pro | utils | 3 | — |
| suigar | mock_pond | 2 | — |
| suigar | oracle | 6 | — |
| bucket-vault | request | 1 | — |
| bucket-vault | response | 1 | — |
| bucket-vault | vault | 18 | — |
| bucket-vault | version | 2 | — |
| bucket-pool | pool | 1 | — |
| bucket-pool | version | 2 | — |
| alphalend | alpha_lending | 42 | — |
| alphalend | market | 34 | get_supply<Ty0>, get_token_price_for_collateral, split_promise_market_fee<Ty0> |
| alphalend | oracle | 10 | — |
| alphalend | partner | 4 | — |
| alphalend | position | 25 | — |
| alphalend | rewards | 6 | — |
| alphalend | sui_staker | 6 | — |
| kai-leverage | balance_bag | 3 | — |
| kai-leverage | cetus | 21 | — |
| kai-leverage | debt | 2 | — |
| kai-leverage | debt_bag | 7 | — |
| kai-leverage | debt_info | 1 | — |
| kai-leverage | equity | 1 | — |
| kai-leverage | piecewise | 3 | — |
| kai-leverage | position_core_clmm | 98 | — |
| kai-leverage | position_model_clmm | 4 | — |
| kai-leverage | pyth | 5 | — |
| kai-leverage | supply_pool | 23 | — |
| kai-leverage | util | 3 | — |
