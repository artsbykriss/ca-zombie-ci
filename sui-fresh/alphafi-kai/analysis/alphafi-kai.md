# ZH4 pass-7 — AlphaFi AlphaLend & Kai Finance (Sui) — zombie deep-dive

**Date:** 2026-10-26 · **Chain:** Sui mainnet · **Status:** read-only; public GraphQL only; **no transactions signed/sent/deployed; no secrets written.**

**Primitive under test:** *version/package import* (old Sui package versions remain callable on the same shared objects) combined with **share/NAV** and **oracle** hypotheses.

**Headline:** **E-U (external unprivileged extractable) = $0 for both targets. Confidence: AlphaLend high, Kai medium-high.** The version-import primitive is **closed** on both protocols (every live shared object carries a version field and only the newest package version(s) accept it). AlphaLend additionally has a **live oracle misconfiguration** (ALPHA priced ~355× too high) that is the cause of its Sept-2026 wind-down, but it is neutralised by `safe_collateral_ratio = 0` + `deposit_limit = 0` + `borrow_limit = 0` and is **not** exploitable by a fresh unprivileged attacker today.

---

## 1. TL;DR table

| Target | Live extractable (unprivileged) | Why closed | Latent risk |
|---|---|---|---|
| **AlphaFi AlphaLend** (`0xd631cd66…`, 15 pkgs) | **$0** | Object version gate (`LendingProtocol.version == 4`; only v15 passes). All value fns also `verify_not_paused` + health-checked; all 36 markets have `borrow_limit = 0`; ALPHA `deposit_limit = 0`; ALPHA `safe_collateral_ratio = 0`. | **Live oracle misconfiguration**: ALPHA valued ~$8.92 vs real $0.0251 (≈355×) via `AlternatePriceIdentifier`. No new borrows/deposits are possible, but existing ALPHA-collateral positions look *healthy* (can't be liquidated) and owners can withdraw collateral → residual bad-debt / failed auto-liquidation risk. |
| **Kai Finance Leverage** (`0x51e0ccce…`, 21 pkgs) | **$0** | `SupplyPool.version == 2` (v19–v21), `PositionConfig.version == 5` (v19–v21), `Position.version == 3` (v17+); live pools v2 / configs v5 ⇒ only v19/v20/v21, and those three are **bytecode-identical**. Admin fns return a non-droppable `ActionRequest` hot potato gated by an allowlisted `Entity`. | 3rd-party POC #1 (rate limiter counts principal only) is real in code but is a **guardrail weakening**, not extraction. POC #2 targets the SAV vault, which is **out of the assigned package scope**. |

**Total live extractable now: $0 E-U.** (H-O = self-service withdrawal claims: AlphaLend ≈ **$2.63 M**, Kai ≈ **$0.886 M**.)

---

## 2. Package / version tables

### 2.1 AlphaFi AlphaLend — 15 versions (`alpha_lending`, `events`, `flow_limiter`, `market`, `oracle`, `partner`, `position`, `rewards`, `sui_staker`)

Original `0xd631cd66138909636fc3f73ed75820d0c5b76332d1644608ed1c85ea2b8219b4`, latest v15 `0xe48b33ef41d56e04fc42bf558e4d54d7cae8a363da9054a6c24bafc2c53a4f33`.

| pkg v | address | `verify_version` expects `LendingProtocol.version ==` |
|---|---|---|
| 1 | `0xd631cd66…19b4` | 1 |
| 2 | `0xc0198e7d…d6a4` | 1 |
| 3 | `0xee754fc0…afd2` | 1 |
| 4 | `0xde3bbb21…8dde` | 1 |
| 5 | `0xb1814a32…87e1` | 1 |
| 6 | `0xc27cbe69…c399` | 1 |
| 7 | `0x379591a3…4bfa` | 1 |
| 8 | `0x632bc1ae…1306` | 1 |
| 9 | `0xc8a5487c…5c79` | 1 |
| 10 | `0x5209a18e…9f61` | 2 |
| 11 | `0xce65b63c…5553` | 2 |
| 12 | `0xbc9d23d6…42be` | 2 |
| 13 | `0x15c16e76…0885` | 2 |
| 14 | `0x58fb555e…8ce93` | 3 |
| 15 | `0xe48b33ef…4f33` (latest) | **4** |

External oracle package (Pyth + Supra + Lazer + FixedPrice/Alternate rails) original `0x378b2a10…5cf4f`, latest v5 `0x869b2d44…d72d25` (v1 `0x378b2a10…`, v2 `0xabf1f1cf…`, v3 `0x39850d8d…`, v4 `0x7671937b…`). AlphaFi stdlib `math` `0x4b591bbc…1fcc` (v1, single version).

### 2.2 Kai Finance Leverage Core — 21 versions (16 modules) + Access Management — 2 versions

Original `0x51e0ccce48f0763f98f1cb4856847c2e1531adacada99cdd7626ab999db57523`, latest v21 `0xed2d91715c74fe7ec5a8d063cfe6bc21b90d9451c26eb90c03605b10fadd68dd`. Access Management original `0x0d9dd55ac7eb676dc78f7d0ae3bc5529d7fd6b52ac0d0edb2d7820c52d080026`, latest v2 `0x6f57ba9757d97ac3ad435c0cf4ab93413654d7af44fc723b1091c5dc2c83d1ae`.

Version constants (from bytecode) per core version:

| core v | `supply_pool::check_version` (`SupplyPool.version`) | `position_core::check_config_version` (`PositionConfig.version`) | `check_position_version` (`Position.version`) |
|---|---|---|---|
| 1–10 | 1 | 1 | 1 |
| 12–15 | 1 | 2 | 2 |
| 17–18 | 1 | 4 | 3 |
| **19–21** | **2** | **5** | **3** |

- Live `SupplyPool` objects: **all `version = 2`**. Live `PositionConfig` objects: **all `version = 5`**.
- ⇒ only **v19 / v20 / v21** pass the gates. **v19, v20 and v21 module bytecode is identical for every module** (full unified diff of all 16 modules is empty); the upgrades only changed dependency linkage. So there is no "old-but-compatible" version exposing weaker logic.
- Access Management v1 and v2 both declare `MODULE_VERSION = 1` (`check_version` asserts `Policy.version == 1`); v2 merely adds `admin_approve_request_with_original_id*` (still `PackageAdmin`-gated). No gate difference.

---

## 3. Version/import test — verdict **CLOSED**

The hypothesis was: an older package version exposes an unprivileged value function that a later version gated, and the shared object still satisfies the old code's preconditions.

**AlphaLend.** The live `LendingProtocol` (`0x01d9cf05d65fa3a9bb7163095139120e3c4e414dfbab153a49779a7d14010b93`, object version 1061331399) stores `version = 4`. `alpha_lending::verify_version` is:

```
verify_version(Arg0: &LendingProtocol) {
    ImmBorrowField[0](LendingProtocol.version: u64); ReadRef; LdConst(u64: 4); Eq; BrFalse(7)
    … 7: LdConst(u64: 8); Abort
}
```

Every older package compares against 1/2/3 and **aborts 8**. Old packages are still callable, but every old value function aborts on the current object.

I enumerated, for **all 15 versions**, the `public` functions that do **not** call `verify_version` (`analysis/check_gates2.py`). Across all versions they are only: `add_market` (always aborts 35), `get_version`, `get_price_identifier`, `get_safe_collateral_ratio`, `get_asset_price`, `refresh_market` (getters/state-refresh), and — only in **v1–v10** — `update_price`, `loan_bailout`, `get_claimable_rewards`, `get_borrow_amount`, `get_collateral_amount`. `update_price` and `loan_bailout` are the only unprivileged *value-touching* ones, and both are benign:
- `loan_bailout` calls `repay_internal` — it spends the caller's own coins to repay someone's debt (a donation).
- `update_price(&mut LendingProtocol, &PriceInfo)` copies a `378b2a10::oracle::PriceInfo` into the internal oracle, keyed by **that PriceInfo's own `coin_type`**, and only if `external.last_updated > internal.last_updated`. `PriceInfo` is a private-field struct constructible only inside `378b2a10::oracle` (via `get_price_info` copy or `update_price_from_pyth`), so no arbitrary price can be injected. (v11+ gate `update_price` with `verify_version` anyway.)

**Kai.** Live pools are `version = 2` and configs `version = 5`; only v19/v20/v21 accept them, and those are identical. `kai_leverage::supply_pool::check_version`:

```
public(friend) check_version<Ty0, Ty1>(Arg0: &SupplyPool<Ty0, Ty1>) {
    ImmBorrowFieldGeneric[0](SupplyPool.version: u16); ReadRef; LdConst(u16: 2); Eq; BrFalse(7)
    … 7: LdConst(u64: 5); Abort
}
```

Old cores compare against 1 (or config 1/2/4) and abort. **No old-but-compatible version exists.**

**Conclusion:** the version/package-import primitive yields **no unprivileged value path** on either protocol.

---

## 4. AlphaLend function inventory & gating (v15)

All of these are `public` (callable by any PTB) and **all** call `verify_version` (⇒ version 4):

| function | extra gates | notes |
|---|---|---|
| `create_position` | `verify_not_paused` | returns a `PositionCap` |
| `add_collateral<T>` | market `active`, `deposit_limit_exceeded`, partner-active | moves coins in |
| `remove_collateral<T>` / `withdraw` | `verify_not_paused`, `position::refresh` + `is_healthy` | cannot over-withdraw |
| `borrow<T>` | `verify_not_paused`, `market::borrow` → `verify_borrow_limit` (abort 30 when `borrow_limit == 0`), `is_healthy` | **blocked for all markets (borrow_limit=0)** |
| `flash_borrow<T>` | `verify_not_paused` | **skips `verify_borrow_limit`** — must be repaid via hot potato |
| `repay` / `loan_bailout` | — | |
| `liquidate<T0,T1>` | `verify_liquidations_not_paused`, `is_liquidation_protected`==false, `position::is_liquidatable` | unprivileged but by design; only genuinely liquidatable positions |
| `collect_reward` / `collect_reward_and_deposit` | requires `PositionCap` | |
| `fulfill_promise` | requires a `LiquidityPromise` hot potato | |

`verify_not_paused` / `verify_liquidations_not_paused` read a `PauseState` **dynamic field** on the protocol; the live object has **no `PauseState`** (only 2 `partner::Partner` and a `PauseCapRegistry`), so the protocol is **not paused** and liquidations are **not paused**. There are **no `entry` functions** in the disassembly; the market/position/oracle helper functions are all `public(friend)` (not directly callable).

**Why new borrowing is off:** `market::verify_borrow_limit` aborts 30 when `borrowed_amount + amount > borrow_limit`. Every one of the 36 live markets has `borrow_limit = 0`. Partner positions and flash borrows bypass this flag, but partner positions need a `PartnerCap` (admin-created) and flash borrows must be repaid in-tx.

---

## 5. Oracle analysis & the wind-down incident

### 5.1 How AlphaLend prices assets
- Lending math reads the **internal** oracle `d631cd66::oracle::Oracle` (embedded in `LendingProtocol`, id `0xd4c456a0378ac3d4bf0b3054e745850638f4f02ccf52b09c480a399196b3fb3f`, `price_staleness_threshold = 63`).
- Prices are pushed permissionlessly: `378b2a10::oracle::update_price_from_pyth(&mut Oracle, &PriceInfoObject, &Clock)` (Pyth-verified, conf/circuit-breaker checks) then `alpha_lending::update_price(&mut LendingProtocol, &PriceInfo)` copies them in.
- `378b2a10::oracle::get_price_info` falls back through **`AlternatePriceIdentifier`** and **`FixedPrice`** rails when a coin has no direct `PriceInfo`.

### 5.2 The misconfiguration (still live)
The external oracle's `AlternatePriceIdentifier` VecMap contains:

```
fe3afec26c59e874f3c1d60b8203cb3852d2bb2aa415df9548b8d688e6683f93::alpha::ALPHA
    -> 3a5143bb1196e3bcdfab6203d1683ae29edd26294fc8bfeafe4aaa9d2704df37::coin::COIN
```

`ALPHA` is **absent** from the oracle's 19 `price_infos`; `3a5143bb…::coin::COIN` **is** present with `price = 8.92497026` (USD, 18-dp fixed point — cross-checked: SUI in the same table is `0.92948381`, DefiLlama SUI `0.92696`). ALPHA's real price (DefiLlama, `sui:0xfe3afec2…::alpha::ALPHA`) is **`$0.02510257`**. So AlphaLend's oracle values ALPHA at ≈ **$8.92**, i.e. **≈355× too high**.

That is exactly the failure described by the wind-down coverage: *"a misconfigured ALPHA price oracle left AlphaLend with bad debt from undercollateralized loans; the Sui Foundation covered the shortfall; maintenance mode: withdrawals open, no new loans"* (x.com/AlphaFiSUI/status/2103622950935281787; cryptobriefing.com; tokenpost.com; ainvest.com; alphafi.xyz banner "repay by 5th Nov 2026 … automatically liquidated"). The mapping is **still present on-chain today**.

### 5.3 Why it is not E-U today
- ALPHA market `safe_collateral_ratio = 0` ⇒ ALPHA collateral has **zero borrowing power**.
- ALPHA `deposit_limit = 0` ⇒ `add_collateral` for ALPHA aborts (`deposit_limit_exceeded`).
- ALPHA `borrow_limit = 0` (and all other markets) ⇒ no new borrows.
- Overvaluation makes ALPHA-backed positions look **healthier**, not liquidatable ⇒ an outsider cannot seize them.
- No new position can be opened with ALPHA collateral (deposit blocked) ⇒ a *fresh* attacker has no entry.
- ALPHA market `outflow_limiter.max_rate = 0` ⇒ the flow limiter is **disabled** (withdrawals unlimited), consistent with the open-withdrawal wind-down.

**Residual / latent risk (not E-U):** because ALPHA is overvalued, ALPHA-collateralised positions appear solvent; owners can withdraw their ALPHA collateral while keeping the (real) borrowed assets, and the announced 5-Nov auto-liquidation **will not fire** while the oracle still reports $8.92. Fixing the ALPHA mapping (or setting ALPHA's internal price to $0) would let `liquidate` reach those positions — but that is an admin action, not an unprivileged one. If the team ever re-enables deposits/borrows before fixing the oracle, the misconfiguration becomes directly exploitable (borrow against 355×-inflated ALPHA).

---

## 6. Live-state tables (checkpoint 2026-10-25/26)

### 6.1 AlphaLend — 36 markets (Table `0x2326d387…` inside the protocol)

Total of `balance_holding + borrowed_amount`, valued with DefiLlama prices (`analysis/tvl.py`, raw dump `analysis/markets.json`): **≈ $2,627,348**.

Selected rows (coin, available liquidity, borrowed, `safe_collateral_ratio`/`liq_threshold`, `deposit_limit`/`borrow_limit`, active):

| # | coin | avail | borrowed | SCR / LT | dep_lim / bor_lim | active |
|---|---|---|---|---|---|---|
| 1 | SUI | 668,356,217,538,583 | 30,481,908,296,383 | 85 / 90 | 2e17 / **0** | ✅ |
| 5 | USDT | 45,128,245,782 | 37,372,787,268 | 85 / 90 | 2e13 / **0** | ✅ |
| 6 | USDC | 177,152,346,620 | 139,892,090,851 | 85 / 90 | 5e13 / **0** | ✅ |
| 9 | BLUE | 3,104,476,755,007,411 | 23,799,513,355,934 | 85 / 90 | … / **0** | ✅ |
| 12 | **ALPHA** | **5,663,858,421,797,845** | **0** | **0 / 99** | **0 / 0** | ✅ |
| 32 | USDC> (DeepBook staked) | 323 | 59,065,354 | 0 / 90 | 0 / 0 | ✅ |

`borrow_limit = 0` for **all 36** markets; `active = true` for 34. Protocol-level config: `max_safe_collateral_ratio 94`, `max_liquidation_threshold 99`, `sui_staking_enabled true`.

### 6.2 Kai — 11 SupplyPools (`SupplyPool.version = 2`) + 20 PositionConfigs (`version = 5`)

DefiLlama Kai TVL = **$886,181.96**. Pools seen depositing as recently as 2026-10-25 (e.g. `SupplyInfo` tx `81wDpJBacYbk4eTWMUrCHLyhRG3WLwfyDGLfhyaNy8zu`). Example: `SupplyPool<SUI, klsui::KLSUI>` `0x1b4c4e08…55cc8` (object v1061285915) holds SUI with 11 lending facilities; pool ids listed in `analysis/evidence.json`.

Active `PositionConfig` example `0x4ca0b323…c634f`: `allow_new_positions = true`, `max_position_l = max_global_l = u128::MAX`, `liq_bonus_bps = 300`, `min_init_margin_bps = 11000`. Several configs have `allow_new_positions = false` / `max_global_l = 0` (retired vaults).

Policy objects (access_management): `0x1cd2ba94…c35e9` (rule `supply_pool::ADeposit`, **14** allow-listed entities, enabled, v1); `0x0e6ea7e8…ab536` (rule `position_core_clmm::ARebalance`, 0 entities). Deposits are entity-allow-listed.

---

## 7. Categories (E-U / H-O / P / S)

| Target | E-U | H-O | P | S | Confidence |
|---|---|---|---|---|---|
| AlphaFi AlphaLend | **$0** | ≈ **$2,627,348** (depositor shares redeemable; withdrawals open, no `PauseState`) | admin-only config/fee/upgrade (AdminCap `0x0d6365df…e22b`, `LendingProtocolCap` `0x3aa48bc9…1c5c`) | $0 | **high** |
| Kai Finance Leverage | **$0** | ≈ **$886,182** (supply-pool / vault shares) | admin-only via access policy (`PackageAdmin` from `kai_leverage::access_init` OTW) | $0 | **medium-high** |

**E-U reasoning in one line each:** AlphaLend — every value fn is version-gated to v15, health-checked, and all borrows/deposits are disabled; the live ALPHA mispricing only *helps* would-be liquidators fail and cannot be turned into profit by a new attacker. Kai — live objects force the identical v19/v20/v21 code, and admin mutations are locked behind a non-droppable `ActionRequest` that only an allow-listed `Entity` can consume.

**What would change the verdict:**
- AlphaLend: admin re-enabling ALPHA deposits/borrows (or setting `safe_collateral_ratio > 0`) **without** fixing the ALPHA→COIN mapping ⇒ direct unprivileged borrow-against-inflated-ALPHA. Also, if the internal-oracle ALPHA price were read as *low* (rather than high), healthy positions would become liquidatable for a bonus.
- Kai: a future upgrade that bumps a version field **without** changing code in a way that creates a compatible older package, or a bug in an `ActionRequest`-consuming path (none found). POC #1 (rate limiter) becomes extractable only in combination with a price/oracle failure.

---

## 8. Dead ends / negative results (with evidence)

- **Version import (AlphaLend):** all 15 versions' `verify_version` constants enumerated; old ones abort 8. No ungated value function in any version (`check_gates2.py` output).
- **Version import (Kai):** v1–v18 abort on live v2 pools / v5 configs; v19/v20/v21 identical (empty module diff).
- **`add_market` in every AlphaLend version:** aborts 35 (disabled). Market creation is `AdminCap`+`verify_version` gated (`add_market_native`).
- **`update_price` (v1–v10, ungated):** copies only genuine external-oracle prices (coin_type-keyed, newer-only); no arbitrary injection.
- **`liquidate`:** unprivileged but requires `is_liquidatable` after `position::refresh`; with ALPHA overvalued no fresh liquidation profit is reachable by an outsider.
- **`flash_borrow`:** skips `verify_borrow_limit` but must be repaid in-tx (hot potato); no free value.
- **Kai access bypass:** `ActionRequest` has no abilities and private fields ⇒ cannot be dropped/destructured; only `approve_request`/`approve_and_return_context` (Entity allow-list) or `admin_approve_request` (`PackageAdmin`) consume it.
- **Kai oracle injection:** `oracle_price::validate` filters caller-supplied `PriceCollection` against the config `price_object_allowlist` and enforces `max_age_secs`; non-allow-listed price objects abort.

---

## 9. Blockers / limitations

1. **Nested-UID reads.** Sui GraphQL `object(address:)` / `multiGetObjects` return `null` for nested `UID`s (the internal AlphaLend oracle `0xd4c456a0…`, and `Table` ids such as the markets table). The internal oracle's `PriceInfo` values therefore could **not** be read directly; ALPHA's effective price was derived from the external oracle's `AlternatePriceIdentifier` fallback (which the code path demonstrably uses) plus DefiLlama. Reading the internal oracle would need a `simulateTransaction` read (not attempted).
2. Sui JSON-RPC is deprecated; no `sui` CLI locally; all reads via the public GraphQL endpoint.
3. Kai **SAV vault** (POC #2 target) is **outside** the assigned packages (Leverage Core + Access Management) and was only read from source, not re-verified on-chain.
4. Third-party POC (`GoodnessFx/KAI-FINANCE-POC`) treated as an untrusted lead; its finding #1 was re-verified in the in-scope source, #2 was not.

---

## 10. Method & sources

**Method.** Public Sui GraphQL (`https://graphql.mainnet.sui.io/graphql`). For each protocol: (a) full version chain via `package.packageVersionsBefore`; (b) per-version bytecode via `object(address:<version-addr>).asMovePackage.modules.disassembly`; (c) per-version gate-constant extraction and full module diffs; (d) live state via `objects(filter:{type})`, `multiGetDynamicFields` (Table/TypeName-keyed entries), and `events`; (e) USD via DefiLlama `coins.llama.fi`. Scripts: `analysis/fetch_versions.py`, `dump_mods.py`, `check_gates.py`, `check_gates2.py`, `markets.py`, `oracle_price.py`, `tvl.py`. Raw disassembly: `analysis/disasm/` (all AlphaLend versions + all 5 oracle versions + Kai v1/v20/v21 + both access versions). Data: `analysis/markets.json`, `analysis/external_oracle_fields.json`, `analysis/evidence.json`.

**Sources of truth.** On-chain bytecode + live objects (primary); DefiLlama prices/TVL; public reporting on the AlphaFi wind-down; `kunalabs-io/sui-smart-contracts` (`kai/leverage/core`, `access-management`); `GoodnessFx/KAI-FINANCE-POC` (untrusted lead).

**Caveats.** Prices move; USD figures are point-in-time. "ALPHA oracle price" is inferred via the documented fallback path (see §9.1). No mainnet transaction was ever signed or sent; nothing was deployed; no key material is present in this folder.
