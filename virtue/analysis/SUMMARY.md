# Virtue (IOTA L1) — consolidated analysis (evidence log)

Date: 2026-10-15 · Chain: IOTA Rebased L1 (Move) · RPC: `https://api.mainnet.iota.cafe` (public, keyless)
Latest checkpoint at verification: **204,100,983** (2026-10-15 ~10:2x UTC). All reads read-only; no transactions sent.

## 1. Canonical addresses (docs + iota-registry, verified on-chain)

| Component | Package / Object | Notes |
|---|---|---|
| Framework | `0x7400af41a9b9d7e4502bc77991dbd1171f90855564fd28afa172a5057beb083b` | modules: account, double, float, linked_table |
| VUSD Treasury | `0xd3b63e603a78786facf65ff22e79701f3e824881a12fa3268d62a75530fe904f` | vusd, admin, limited_supply, module_request |
| Oracle | `0x7eebbee92f64ba2912bdbfba1864a362c463879fc5b3eacc735c1dcb255cc2cf` | aggregater, collector, listing, result |
| CDP (orig id) | `0x34fa327ee4bb581d81d85a8c40b6a6b4260630a0ef663acfe6de0e8ca471dd22` | upgraded → v2 `0xcdeeb40c…86ba1` |
| Stability Pool (orig id) | `0xc7ab9b9353e23c6a3a15181eb51bf7145ddeff1a5642280394cd4d6a0d37d83b` | upgraded → current `0xe50fa492…0929b` |
| Recovery (new) | `0x732ce63849c64d630f256f2a926c90b309ffbc6a9a6806239088e1649ff8c952` | admin recovery mint (2026-10-01) |
| VUSD TreasuryCap | `0x0695bf8ccbe4e91970d5d95cfefda996b2fa913bca3724e91153017bcd345934` | owned by Treasury dynamic field (CapKey) |
| Treasury (shared) | `0x81f525f4fa5b2d3cf58677d3e39aabc4b0a1ca25cbba605033cfe417e47b0a16` | beneficiary `0x231b8f89…164a` |
| StabilityPool (shared) | `0x6101272394511caf38ce5a6d120d3b4d009b6efabae8faac43aa9ac938cec558` | vusd_balance 189,497,634,597 |
| Deployer | `0xf67d0193e9cd65c3c8232dbfe0694eb9e14397326bdc362a4fe9d590984f5a12` | published all packages |
| Admin (current caps holder) | `0x34adddfebf80ab25d8a842fe2ab152f96bc70c2d645c60b8eb6d765175cb6dbe` | AdminCap, ListingCap, 5×UpgradeCap, Publisher |

## 2. The four vaults (dynamic-field walk — previously failed, now complete)

`Vault<T>` objects each hold `position_table: LinkedTable<address, Position>`; positions were enumerated via
`iotax_getDynamicFields` on each table id and batch-read (`iota_multiGetObjects`). **79 positions total** (vault_positions.csv).

| Vault | Object | positions | collateral (raw) | VUSD borrowed | interest |
|---|---|---|---|---|---|
| Vault\<IOTA\> | `0xaf306be8419cf059642acdba3b4e79a5ae893101ae62c8331cefede779ef48d5` | 17 | 2,410,072,442,864 (2,410.07 IOTA) | 4,942,752.46 | 5.5% |
| Vault\<CERT(swirl)\> | `0xc9cb494657425f350af0948b8509efdd621626922e9337fd65eb161ec33de259` | 56 | 8,950,007,805,576,865 (8.95M CERT) | 140,610.97 | 6.0% |
| Vault\<IBTC\> | `0xcc094d9e3b491b0c943bb18daf07a49bd951f34688f9610d90982de06fc0c5c9` | 4 | 149,549,784 (14.955 IBTC, 10 dec) | 726.49 | 5.5% |
| Vault\<CERT(0xe4ab…)\> | `0x53b6405d2672be1e73f8ddea1766dbda57f1fed677be58fbfedc9fdddaafdd26` | 2 | 3,000,003,905,922 (3.0M) | 65.22 | 6.0% |

Vault `balance` == Σ position coll for every vault (exact match). MCR = 110% for all four; liquidation rule = `stability_pool::StabilityPoolRule`.

## 3. The incident (2026-08-28) — full mechanism, reconstructed on-chain

1. **21:48 UTC** — attacker `0x381d5b5f…7c7e9` (first-ever tx) calls `0x8650249d…::oracle_init_action::run` (Switchboard on IOTA) and **creates its own Oracle objects** (`OracleCreated` events; attacker-chosen keys). `mr_enclave` on those oracles is all-zero.
2. **21:53 UTC** — tx `CaAD9SRJjuvEbNiHQcgT176kg4F8jKUTM1EneeYsd3Gd` (48 commands):
   - 14× `aggregator_submit_result_action::run<IOTA>` pushing `value = 10000000000000000000000000` (1e25 ⇒ $10,000,000 / IOTA), `timestamp = 1787953989`, same 64-byte signature;
   - `collector::new<IOTA>` → `0x39fb7adf…::switchboard_rule::feed<IOTA>` → `0x7eebbee9…::aggregater::aggregate<IOTA>` → **PriceResult<IOTA> = 1e16 ⇒ $10,000,000** (`IOTA>` event `result: "10000000000000000"`);
   - `request::debtor_request<IOTA>` (deposit 1 IOTA, borrow 4,942,703.66 VUSD) → `vault::update_position<IOTA>` with `option::some(PriceResult)` → **minted 4,942,703,659,474 raw VUSD against 1 IOTA** (health check passed because the caller-supplied price said $10M);
   - 1,000,000 VUSD → `stability_pool::deposit_and_update`; remainder transferred out.
3. **21:53–23:05 UTC** — attacker swaps **455,000 VUSD** on two AMM pools (`amm_entries::swap_exact_coinB_for_coinA`, package `0xc0d03419…`):
   - pool `0xb768e68c…` (IOTA/VUSD): 105k VUSD → 366,442.34 IOTA;
   - pool `0x9b5c57e9…` (CERT/VUSD): 350k VUSD → 2,196,543.50 CERT.
   Real-asset extraction ≈ **$131.6k** at current prices (plus ~$1.2k collateral from SP withdrawal). Attacker still holds **4,146,017.57 VUSD** (pools drained to ~1,136 VUSD total) and 11,174,259.82 IOTA (mostly funded capital).
4. **2026-08-29 03:29 UTC** — deployer calls `vusd::remove_version` (tx `2qt1Kn3X9LNhXxBw29otbcY83H9B787DtAdLBHKFrE1J`) ⇒ **CDP module version set emptied ⇒ whole CDP frozen** (`err_invalid_module_version` on every request construction).
5. **2026-10-01** — deployer adds version 1 for the new `recovery::VirtueRecovery` module and runs `recovery::mint` (AdminCap-gated) for 46 SP depositors (`RecoveryMint` events), minting 113,406.35 VUSD and restoring the SP to 189,497.63 VUSD.

## 4. Oracle state today (dev-inspect, read-only)

| Test | Call | Result |
|---|---|---|
| P1 | `pyth_rule::feed<IOTA>` w/ IOTA PriceInfoObject | abort `pyth::check_price_is_fresh` (price 0.04433612, timestamp 1787666565 = 2026-08-25) |
| P2 | `pyth_rule::feed<IOTA>` w/ IBTC PriceInfoObject | abort `pyth_rule::err_invalid_price_info_object` — **feed-id check present** |
| P3 | `switchboard_rule::feed<IOTA>` w/ real aggregator + `aggregate` | abort `aggregater::err_total_weight_not_enough` — switchboard weight 0/absent |
| — | `aggregater::new` / `set_rule_weight` | require `&mut/& ListingCap` (owned by EOA `0x34adddfe…`) |
| — | `oracle::result::new` | Friend of `aggregater` only ⇒ PriceResult creatable only via `aggregate` |

Aggregator weights (live): `{pyth_rule::PythRule: 1}`, threshold 1. `WeightUpdated` history: pyth(1) → switchboard(1) → switchboard(0).

## 5. Freeze verification (dev-inspect)

| Test | Call | Result |
|---|---|---|
| F1/F4 | `request::debtor_request` (borrow, deposit, repay, withdraw) | abort `vusd::err_invalid_module_version` |
| W1 | `stability_pool::withdraw` (top depositor `0x014366e0…`) | success — H-O confirmed |
| W2 | `stability_pool::withdraw` (fresh address) | abort `err_account_not_found` |
| W3 | `stability_pool::claim<IOTA>` (fresh address) | success, returns 0-value coin |
| F3 | `stability_pool::deposit_and_update` (fresh address) | success (permissionless deposit) |
| — | `recovery::mint` | requires `&AdminCap` (privileged) |

Treasury `module_versions_map`: `{…::witness::VirtueCDP: [], …::recovery::VirtueRecovery: ["1"]}`.
VUSD `total_supply` = 5,197,561.500789 (CDP 5,084,155.15 + recovery 113,406.35).

## 6. Value accounting (2026-10-15, prices: IOTA $0.04531, BTC $81,211)

| Bucket | Amount | USD | Class |
|---|---|---|---|
| Vault collateral (4 vaults, frozen) | 2,410.07 IOTA + 8.95M CERT + 14.955 IBTC + 3.0M CERT_b | ≈ **$1,827,097** | **S** (owner-recoverable only if admin re-enables CDP ⇒ P-conditional) |
| Stability Pool | 189,497.63 VUSD (192 depositors, withdrawable now) | 189,498 (face) | **H-O** |
| Attacker-held unbacked VUSD | 4,146,017.57 VUSD | 0 realizable (liquidity drained) | note |
| DEX pools VUSD remainder | ≈1,136 VUSD | ~0 | note |
| Latent bad-debt position | 1.027 IOTA vs 4,942,737.62 VUSD debt | collateral ≈ $0.05 | S / protocol bad debt |

CERT price ≈ IOTA × 1.15578 (Swirl pool rate from cert_rule); CERT_b ≈ IOTA × 1.05881 (vcert_rule). IBTC treated at BTC/USD (Pyth feed e62df6c8…).

## 7. Files

- `raw/` — full JSON dumps (publish txs, vault objects, position tables, positions, oracle/rule modules, exploit + liquidation txs, SP history, Treasury versions, caps).
- `vault_positions.csv`, `sp_positions.csv` — complete position inventories.
- `dev_inspect_*.mjs` — the dev-inspect test scripts (also in `../ci/`).
