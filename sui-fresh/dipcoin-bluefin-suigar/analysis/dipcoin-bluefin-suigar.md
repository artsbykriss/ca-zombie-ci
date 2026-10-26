# ZH4 pass-7 — DipCoin / Bluefin Pro / Suigar (Sui) — version/import + share/NAV + missing-signer deep-dive

**Date:** 2026-10-25 · **Chains:** Sui mainnet · **Mode:** read-only (public GraphQL `https://graphql.mainnet.sui.io/graphql`); **no** signing/sending/deploying; no secrets written. Tooling: `sui-fresh/tools/sui.py` + local scripts in `analysis/`.

**Primitive hypothesis tested:** (a) version/package import — an old Sui package version stays callable on the same shared objects after an upgrade; (b) share/NAV mispricing; (c) missing signer/owner.

---

## 0. TL;DR

| Target | Live value (USD) | E-U now | Confidence | Why closed / open |
|---|---|---|---|---|
| **DipCoin** (perps/vault) | Bank<USDC> ≈ **$1,844,560** | **$0** | high | `protocol::check_version` gates every old version against the live `ProtocolConfig.version == 6`; ungated real value-movers need a `VaultNAV` only the gated `new_vault_nav` can build |
| **Bluefin Pro** | ~$1.5M (corpus; bank balance not GraphQL-readable) | **$0** confirmed | medium | No per-package gate ⇒ **old versions ARE callable**, but no weaker old-version guard proven exploitable. **Separate high-severity candidate (all versions incl. latest): 0x0-signer auth bypass + caller-supplied oracle prices** — mechanism confirmed, profit path not completed |
| **Suigar** (casino house) | USDC+SUI houses ≈ **$175,242** | **$0** | high | `sweethouse::assert_valid_version` gates v1 (`package_version()==0`, live `version_set=={1}`); v1/v2 value bodies byte-identical ⇒ old-version calls are equivalent to latest |

**Total live E-U now: $0** (with proof). The headline *residual* risk is Bluefin's 0x0-signer bypass (unconfirmed profit).

---

## 1. Method

* `tools/sui.py ver <pkg>` → full version chains. `package(address:)` in GraphQL always resolves to the **latest** version, so per-version bytecode was fetched with `object(address:<version-addr>).asMovePackage.modules` (`analysis/fetch_versions.py`) and saved under `analysis/disasm/{dipcoin,suigar,bluefin}/vNN_*.json`.
* `analysis/sigs.py` — extract function signatures; `analysis/diff_versions.py` — per-module signature diffs; `analysis/gate_check.py` / `suigar_gate.py` — transitive call-graph reachability to each protocol's version-gate function; `analysis/real_fns.py` — classify each function body as REAL vs deprecation STUB (`LdU64(999);Abort` / `method_deprecated`); `analysis/ungated_real.py` — the real+callable+ungated surface per version.
* Live state via GraphQL `object`/`objects`; prices via `coins.llama.fi` (USDC $0.99958, SUI $0.92598).

---

## 2. DipCoin (vault / spot / perp)

### 2.1 Package & version chain — **9 versions**
Original `0x978fed071cca22dd26bec3cf4a5d5a00ab10f39cb8c659bbfdfbec4397241001` (v1) → latest `0xa5b1b7a4cc8a765b422f41b8cfbc43553574f5731abdfa038df8d3cce09efec9` (v9).

| v | package object | modules | expected `check_version` const |
|---|---|---|---|
| 1 | `0x978fed071cca22dd26bec3cf4a5d5a00ab10f39cb8c659bbfdfbec4397241001` | 21 | 1 |
| 2 | `0x9645033a540eaa77aaa4b5f0695759a14e8b7c250ea318ef403ce1d96a4a738f` | 23 (+`vault`,`migrate`) | 2 |
| 3 | `0x3d11bc46bb4fbcdef7d17f69ac10e3a471d8f09cf104f94b5113dc2cd1c44fd2` | 23 | 3 |
| 4 | `0x857c7c6e50c5e6574966cf110897b99e8a510f8346b0a60a7604fb917b155086` | 24 (+`price_feed`) | 4 |
| 5 | `0x92df31c1b3e14ac7e54d6e606341f36d2743a1cf45119fda4b4efb83d623276f` | 24 | 4 |
| 6 | `0x6671fbc069c94343bb217ea450993c3168cd8ecb433d1c6be339dafcfb53e68c` | 24 | 4 |
| 7 | `0x47f361827c432c2dc286946f73c497509e4ef986311a716af9efbe47db0e1cb4` | 25 (+`cctp`) | 5 |
| 8 | `0xcd35ff7f5d2a5fa8e9ed4d0147040c54d4a7dd19d08596d860be4712cdf7cf9b` | 25 | 6 |
| 9 | `0xa5b1b7a4cc8a765b422f41b8cfbc43553574f5731abdfa038df8d3cce09efec9` | 25 | 6 |

The `vault` module (typed by `0x9645033a…::vault::…`) was **added in v2** — confirmed (v1 has no `vault` module).

### 2.2 The version gate (the reason this target is closed)

`protocol::check_version` compares a live field against a **hardcoded u64**:

```
public(friend) check_version(Arg0: &ProtocolConfig) {
  0: MoveLoc[0]; 1: ImmBorrowField[0](ProtocolConfig.version: u64); 2: ReadRef
  3: LdConst[0](u64: 1)        ; v9 uses LdConst[0](u64: 6)
  4: Eq ; 5: BrFalse(7) ; 7: Call error::invalid_protocol_version(); 8: Abort ; 9: Ret }
```

`protocol::check_basic = check_version + check_is_normal(is_paused)`.

**Live state:** `ProtocolConfig` `0xdeff2ed27dfe5402e38d60b090a7dcf9b4842c16ec63e472119272173603dfd8`, `version = "6"`, `is_paused = false`. So **v1–v7 abort** on every function that reaches `check_basic`; only **v8/v9 pass**.

### 2.3 Deprecation-stub pattern
v9 replaces every superseded entry point body with `LdU64(999); Abort` and moves the live logic to `_v2/_v3/_v4` variants that call `protocol::check_basic`. Examples:
* `bank::deposit / withdraw / withdraw_all` = stub; live = `deposit_v2 / withdraw_v2 / withdraw_all_v2` (all call `check_basic`, and `withdraw_v2` debits `ctx.sender()` and pays `Arg3`).
* `vault::deposit / request_withdraw / claim_closed_vault_funds / close_vault / update_share_price / compute_perpetual_position_value` = stubs; live = `*_v2/*_v3`.
* `exchange::trade(_v2/_v3)` = stubs; live = `trade_v4`.

### 2.4 Ungated real value-movers (the only remaining candidates)
Per-version `real+callable+ungated` inventory (`ungated_real.py`) reduced to:
* `vault::new_vault_nav` — **GATED in all of v2..v9** (calls `check_basic`). It builds the `VaultNAV` and sets `bank_balance = bank::get_balance(bank, bank_account(vault))` (the real balance).
* `vault::update_share_price_v2(&mut Vault, VaultNAV, &Bank, &Clock)` — public, ungated, but (i) requires a `VaultNAV` value that only the gated `new_vault_nav` can produce (`VaultNAV` has no abilities and no other constructor), and (ii) re-validates `NAV.bank_balance == bank::get_balance(bank, bank_account(vault))` (v9 ops 52–59, abort 2045). `total_position_vaule` comes from `compute_perpetual_position_value_v2` reading the perpetual's real position and the PriceFeed oracle.
* `vault::compute_perpetual_position_value[_v2]` — needs a `VaultNAV`.
* `price_feed::update_price_feed` — public, ungated, but recovers the signer and requires `== PriceFeed.feeder`.
* `bank::remove_empty_account` — v2..v8 real but only deletes empty accounts (v9 = stub).
* `roles::set_exchange_admin` — entry, ungated, but takes `ExchangeAdminCap` **by value** ⇒ requires owning the cap (P).
* `vault::update_share_price` (no-Bank) is already a stub in **v2** (`error::method_deprecated`), so there is no “old share-price setter” to abuse.

**No old-version value-moving entry point lacks a guard that a later version added.**

### 2.5 Live state

| object | type | key fields |
|---|---|---|
| `0x3cc2bfbe6b9dc346f3f27a47b4b0c9eaaf0143c0c704726a1513a1e8c5d9a4c1` | `0x978fed07…::bank::Bank<…::usdc::USDC>` | `coin_balance = 1845334621258` = **1,845,334.62 USDC ≈ $1,844,560**; `accounts = 789`; `is_withdrawal_allowed = true` |
| `0x69bae0c198f83acf12656a247dfe85467819139560968669f14b4df0abe8efd7` | `0x9645033a…::vault::VaultConfig` | `operator = 0x339007e0…`; registry `21` vaults |
| `0xdeff2ed2…603dfd8` | `…::protocol::ProtocolConfig` | `version = 6`, `is_paused = false`, `settlement_cap_ids = []` |
| 21 `vault::Vault<USDC>` objects | `0x9645033a…::vault::Vault<USDC>` | all `closed_at != 0`, `total_shares = 0`, `deposit_status = false` → no live vault NAV to attack |

### 2.6 Verdict — DipCoin
**E-U $0 / H-O $0 / P $0 / S $0 (confidence high).** The version gate (`protocol::check_version` vs live `ProtocolConfig.version == 6`) closes every old-version value path; the ungated NAV helpers cannot be fed an attacker-controlled `VaultNAV`. What would change the verdict: a version whose `check_version` constant equals 6 without the guards (none), or a public `VaultNAV` constructor (none).

---

## 3. Bluefin Pro

### 3.1 Package & version chain — **21 versions**
Original `0xe74481697f432ddee8dd6f9bd13b9d0297a5b63d55f3db25c4d3b5d34dad85b7` (v1) → latest `0x11d01c93c0461f8f505c993e48734b364a95fa7b32c7956e3bd58d93d27d0892` (v21). Full chain in `analysis/disasm/bluefin/_versions.json` (v1…v21; modules `account, admin, bank, bcs_handler, coin, constants, data_store, errors, events, exchange, margining_engine, perpetual, signature, signed_number, utils`).

### 3.2 The version check is NOT a package-version gate

Every entry point asserts the **data-store ABI version** equals a hardcoded constant:

```
withdraw_from_bank:  Call data_store::get_ids_version(&ids)  ; Call constants::get_version() ; Eq ; BrFalse -> errors::version_mismatch
                     Call data_store::get_eds_version(&eds)  ; Call constants::get_version() ; Eq ; BrFalse -> errors::version_mismatch
```

`constants::get_version()` returns **1 in every package version (v1…v21)**. Live `ExternalDataStore.version == "1"` and `InternalDataStore.version == "1"`. Therefore **every old package version passes the check and remains callable on the same shared objects** — the version/import primitive is satisfied for Bluefin.

### 3.3 Is any old version weaker? (v17 vs v18)

`exchange::withdraw_from_bank` differs at **v18**: v18 added an explicit
`account::get_max_withdrawable_amount(assets, positions, perps, assets) >= amount` check (abort `insufficient_funds`). v17 lacks it, but still (i) bounds by the account's own recorded quantity in `account::sub_margin_from_asset_vector` (`DepositedAsset.quantity >= amount` else `insufficient_margin`) and (ii) calls `margining_engine::verify_health(action_withdraw)`. So the v18 change is **defence-in-depth**, not a reproducible weaker-guard E-U. Other v18 changes are signature-domain-separator/`payload_type_*` refactors.

### 3.4 Separate finding — `signer == 0x0` authorization bypass (present in **all** versions v1…v21)

`signature::verify_signature_and_recover_signer(message, signature)` reads `signature[0]` as the scheme byte and, for **scheme `0x05`**, returns the **zero address** with **no cryptographic verification**:

```
64: MoveLoc[5](scheme:u8) ; 65: LdU8(5) ; 66: Eq ; 67: BrFalse(70) ; 68: LdConst[38](address: 0x000…000) ; 69: Ret
```

The value entry points treat `signer == 0x0` as **authorized**:

| entry fn | authorization expression |
|---|---|
| `exchange::withdraw_from_bank` | `valid = (signer == 0x0) OR (signer == account)` |
| `exchange::authorize_account` | `valid = (signer == 0x0) OR (signer == account)` |
| `exchange::adjust_margin` | `valid = (signer == 0x0) OR account::has_permission(account, signer)` |
| `exchange::adjust_leverage` | `valid = (signer == 0x0) OR account::has_permission(account, signer)` |
| `exchange::close_position` | `valid = (signer == 0x0) OR account::has_permission(account, signer)` |

There is **no `tx_context::sender()` check** in the exchange module's value entry points (0 sender calls in `withdraw_from_bank/close_position/adjust_margin/authorize_account/…`). An attacker can therefore pass `signature = [0x05, 64+ bytes]` and be treated as the zero-address signer. (Operator-only actions such as `set_funding_rate`, `set_gas_fee`, `prune_table`, `authorize_liquidator`, `deleverage`, `set_fee_tier`, `set_account_type` instead require `signer == data_store::get_operator_address(ids, "<action>")`, so they are *not* forgeable this way.)

Additionally these entry points call `data_store::update_oracle_prices(ids, symbols, prices)` with **caller-supplied prices and no bounds/signature check**, so the oracle price used by the subsequent health/PnL math is attacker-chosen.

**Profit-path status (honest):** `withdraw_from_bank` decodes `(eds, symbol, account, amount, salt, signedAt)` and pays `account` — i.e. the recipient equals the account, so the bypass alone gives no cross-account redirect. `close_position` requires a **delisted** market (none confirmed live) and settles PnL into the payload-specified account, which is the most promising extraction vector (insurance pool) but was **not** completed within budget. `adjust_margin`/`adjust_leverage` re-balance the account's own assets. **Confidence: mechanism high, profitability low.**

### 3.5 Live state

| object | type | key fields |
|---|---|---|
| `0x740d972ea066fe3302ee655163373cda2e9529bfa93d2266e1355cf56899da57` | `0xe74481…::data_store::ExternalDataStore` | `version = 1`; `sequence_number = 218404`; `operators size = 0`; 8 perpetuals; `asset_bank` nonce 76209, `supported_assets size = 1`, `deposits size = 0` |
| `0xa9f033047d2fc453da063b03500a48950d2497bb0a2faec57da2833d42a12806` | `…::data_store::InternalDataStore` | `version = 1`; **accounts = 43,269**; 8 perpetuals; 4 operators; 11 liquidators; `gas_fee = 30000000`; `sequence_number = 8314262` |
| `0x10d48e112b92c8af207c1850225284a7ca46bac1d935c4af4cf87ce29b121694` | `0x9added62…::bluefin_vault::Vault<0x5d4b3025…::coin::COIN>` (Wormhole USDC; **separate package**) | `name="Aqua"`; `total_locked_amount = 71147420000` (≈71,147.42); `coin_balance = 611340050`; `total_amount_to_be_withdrawn = 12914540000`; 2,901 users; `deposit_paused = true`; `withdraw_paused = false` |

The asset-bank coin balances are stored as dynamic fields of a **nested UID** (`AssetBank.id`) and are **not discoverable via GraphQL `dynamicFields`** → exact bank USD not read; corpus value $1.5M retained.

### 3.6 Verdict — Bluefin Pro
**E-U $0 confirmed** (version/import: old versions callable but no weaker guard proven exploitable). **Residual (high severity, unconfirmed profit):** the `scheme==0x05 → signer 0x0 → authorized` bypass plus caller-supplied oracle prices in `withdraw_from_bank / authorize_account / adjust_margin / adjust_leverage / close_position`. What would change the verdict to E-U>0: (i) a live delisted market enabling `close_position` insurance-pool extraction at an attacker-set oracle price, or (ii) an account/recipient field mismatch in `withdraw_from_bank` (verified absent), or (iii) a replay/first-deposit trick to seed a fake balance.

---

## 4. Suigar (SweetHouse casino house)

### 4.1 Package & version chain — **2 versions**
Original `0xcbb0929f21450013ebe5e86e7139f2409da2e3ed212c51126a7e6448b795a43f` (v1) → latest `0x76176d6964b43881e05f7263a9533cb1bf212c7dd6827bfa52775ed2c6b64648` (v2). Modules: `core, float, house, i64, math, mock_pond, oracle, pipe, swap_rakeback, sweethouse, utils`.

### 4.2 The version gate

```
package_version(): u64  ->  v1: LdU64(0)   ;  v2: LdU64(1)
assert_valid_version(&SweetHouse): require SweetHouse.version_set.contains(package_version()) else abort
```

Live `SweetHouse` `0xa1549d73230118716bc08865b8d62454f360ddaf40eee2158e458e52125d4ef1` has `version_set = ["1"]`. So **v1's `assert_valid_version` aborts (0 ∉ {1}); v2 passes.** (`assert_valid_version` is called ~50× in the sweethouse module.)

### 4.3 v1 vs v2 body diff
Only `oracle` (a v2 pricing refactor: `get_usd_price` → `read_price_quote*`/`check_quoted_usd_price`), `sweethouse::{init,package_version}`, `mock_pond::id` changed. **Every pool/pipe/sweethouse value function is byte-identical between v1 and v2** ⇒ calling v1's ungated functions (`deposit_private_pool`, `deposit_public_pool_and_mint_staked_coins`, `deposit_rakeback_pool`, `claim_own_redeem_request_after_delay`, …) is behaviourally identical to v2's — **no version-differential exploit.**

### 4.4 Share/NAV analysis
`get_pool_total_value = pool.balance + pool.pipe_debt`; `deposit_public_pool` mints `amount+total` shares when `supply==0 OR total==0` (bootstrap) else `amount*supply/total`; `redeem_public_pool` pays `shares*total/supply_before`. The classic **first-depositor capture** requires `supply==0 AND total>0`. **Not live** (see below). `deposit_public_pool` enforces `amount+total <= max_capacity`.

### 4.5 Live houses (House objects are dynamic fields of SweetHouse)

| house | type | public_supply | public_pool (balance + pipe_debt = total) | private_pool total | rakeback | share price | USD |
|---|---|---|---|---|---|---|---|
| `0xd7d82627957f9665a6c64c5c2cc8f1867b398bf9c85155308e670169ade3f7e1` | `House<…::usdc::USDC>` (6dp) | 9,950,000,000 | 9,780,998,698 + 8,618,092,792 = 18,399,091,490 | 22,699,540,324 | 1,935,640,096 | 1.849 | **$43,016** |
| `0x1840b0629ddd4975701790da552d09b35025deabfa30135dff5ad4cba87f1bd6` | `House<0x2::sui::SUI>` (9dp) | 9,010,000,000,000 | 11,649,350,516,532 + 45,582,111,006,196 = 57,231,461,522,728 | 85,085,381,696,556 | 478,165,190,297 | 6.352 | **$132,226** |
| `0x4a7404cfdb1979e60a1c2b44672669b40b21eba22bb4bc09a439970265b62e93` | `House<…spring_sui::SPRING_SUI>` | **0** | 0 + 0 = **0** | 22,506,735,719 | 0 | — | ~$20 |

**Total Suigar ≈ $175,242.** No house has `supply==0 AND total>0`; the USDC/SUI public totals already exceed `max_capacity` (deposits blocked).

### 4.6 Verdict — Suigar
**E-U $0 / H-O $0 / P $0 / S $0 (confidence high).** Gate blocks v1; v1/v2 value bodies identical; no live first-depositor state. What would change the verdict: a future upgrade whose `package_version()` collides with a `version_set` entry while keeping an old ungated value body — none today.

---

## 5. Dead ends (recorded so they are not re-investigated)

* **DipCoin** `vault::update_share_price` (no-`&Bank`) is already a `method_deprecated` stub in v2 → no old share-price setter. `update_share_price_v2` validates `NAV.bank_balance` against the live bank and needs a gated `VaultNAV`. `roles::set_exchange_admin` needs the `ExchangeAdminCap` by value. All 21 live DipCoin vaults are closed with 0 shares.
* **Bluefin** v17→v18 `withdraw_from_bank` hardening is defence-in-depth (v17 already bounds by the account's own quantity + `verify_health`). `deposit_to_internal_bank`/`remove_tainted_asset` only finalise a pending `Deposit` (deposits table size 0). `liquidate` requires `has_permission` (no 0x0 path). Admin ops require `signer == get_operator_address(...)`.
* **Suigar** `deposit_public_pool` bootstrap branch requires `supply==0`; no live pool satisfies it with value. `redeem`/`withdraw_self_whitelist_pool` call `assert_valid_version`. Pipes are operator-driven (`public(friend)`).

## 6. Blockers / limitations

1. Sui JSON-RPC deprecated → GraphQL only; the `simulateTransaction` JSON shape was not exercised within budget, so the Bluefin 0x0 bypass and the DipCoin gates are **static (full-bytecode) proofs**, not dynamic PoCs.
2. Bluefin asset-bank balances live in dynamic fields of a nested UID and are **not GraphQL-discoverable** → exact bank USD unknown (corpus $1.5M used).
3. Bluefin 0x0-bypass **profitability** not completed (needs a delisted market and/or an account/recipient mismatch).
4. `analysis/` scripts are read-only and contain no secrets; all RPC is the public GraphQL endpoint.

## 7. Files

* `analysis/disasm/{dipcoin,suigar,bluefin}/vNN_*.json` — per-version module disassembly (full bytecode) + `_versions.json`.
* `analysis/fetch_versions.py`, `sigs.py`, `diff_versions.py`, `gate_check.py`, `suigar_gate.py`, `real_fns.py`, `ungated_real.py` — analysis scripts.
* `analysis/evidence.json` — object ids/types/versions/key fields, version chains, verdicts.
