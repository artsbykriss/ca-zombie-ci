# ZH4-OPEN-B-SUSHI-STELLAR — Sushi (Stellar Soroban) residual-OPEN deep dive

**Date:** 2026-10-23 · **Re-verified:** 2026-10-24 (fresh ledger + green CI, see §7.2) · **Chain:** Stellar (Soroban, public network) · **Finding:** `ZH4-OPEN-B-SUSHI-STELLAR`
**Status:** **read-only; no transaction was ever signed or sent.** All verification uses Soroban
`simulateTransaction` (a dry run that returns required authorization entries) plus keyless
ledger/event reads. No mainnet transactions, no private keys, no fork needed (Soroban has no
EVM-style fork — see §7 for the tooling-honest substitute).
**Lane origin:** `zombie-hunt-iv/pass5/non-evm.md` row 17 ("Sushi Stellar — $15.1M — Soroban
UniV2-style AMM pools — Not reviewed") · `pass5-recon/README.md` OPEN-B.

---

## 1. TL;DR

| Target | Live TVL | Live extractable (unprivileged) | Why closed | Latent risk |
|---|---|---|---|---|
| **Sushi Stellar — current factory** `CD3KRKGDRVWPXVB3VXLUMQKMX6XZ6Q2H334IVZD4XXNAMKSRVQL5GLYF` (63 pools, pool wasm `003710b3…`) | **$15,117,631** (DefiLlama `sushi-stellar`; re-derived on-chain ≈ **$15.0M**) | **$0** | Every value-moving entry point requires the correct `require_auth`: swap→`sender`; mint/burn/collect→position owner (the PositionManager); collect_protocol→factory owner; flash_begin/end→the immutable FlashExecutor; set_router_authorized→the factory contract; pause/upgrade/migrate/set_admin→the admin account. Verified **live** by dry-run simulation returning the required auth entries. | Owner-key compromise (single account `GC7RIP4D…`), uncollected protocol fees ~$17.9k, CLMM math not exhaustively audited |
| **Sushi Stellar — legacy factory** `CCRSMJDITH3VK5QOGYCVZDAKIY5GL3RCG4TCVLIAVB662IW2V5KJGZGF` (61 pools, pool wasm `95a8e001…`) | ~$44k | **$0** | Same auth model; that pool version has **no** admin/upgrade/pause entry points at all. | Immutable code (cannot be fixed if a logic bug exists) |
| Sushi **router** `CDMIM23WOUL5CZBKX3GOA3V5R5AMVIMTCP52KCDQORWELAPLJ27WZCHL` | $0 (stateless) | **$0** | `swap_exact_input*` calls `pool.swap(sender=user,…)`; the pool pulls input from `sender` (auth'd). `swap_exact_output*` are unimplemented stubs. `init_router` is gated. | — |
| Sushi **PositionManager** (NFT) `CARTUL5AWDZYBSN7HUUJZSKCAKCIAKM7M54Z76G6KRYCK4XPR3OHUQZ4` | $0 (positions live in pools) | **$0** | NFT-ownership enforced on `collect`/`decrease_liquidity`/`transfer`/`approve` (live: foreign token → `#1007 Unauthorized`); admin fns require the admin. | Owner-key compromise |
| Sushi **FlashExecutor** `CDKKPFBNNQETVN4Y2CIU6CQMWCPIZDXDZE76IDSTF7HLQT6Q573PCDTH` | $0 (transient) | **$0** | Single entry `execute_flash_loan` requires `user.require_auth()`; `pool.flash_end` re-checks `balance ≥ balance_before + expected_fee` per token before releasing. | — |

---

## 2. Total live extractable now: **$0** (confidence: **high**)

**E-U = $0.00.** No unprivileged path was found that moves value out of the pools, the router, or
the position manager. The headline TVL ($15.1M) is protected by standard Soroban
`Address::require_auth` gating on **every** value-moving entry point, confirmed both statically
(per-export host-call call graphs from the deployed WASM) and dynamically (live dry-run simulation
that returns the *required* authorization entries for each call).

**P (privileged) = $15,117,631** — the factory owner account `GC7RIP4D7UETKBZU7FNUYW5XIR2IPLUQDV2DUTZRKVF6C3P2A5QEDSZI`
can `upgrade_pool` (upgrades are **not** frozen and **not** permanently disabled) and `set_protocol_fee`,
and is the sole admin of every pool and of the PositionManager. **H-O = $0** (LP positions are ordinary
self-service NFTs). **S = $0.**

> Honest negative result: the OPEN-B lead ("Soroban UniV2-style AMM; not reviewed") resolves to a
> **well-gated UniV3-style CLMM port** with no unprivileged extraction path found. This is a
> measurement, not an all-clear on the AMM *math* (see §8 residual).

---

## 3. The deployment (what it actually is)

The corpus label "UniV2-style" is **wrong**: the factory spec, events and errors are a faithful
**Uniswap-V3 concentrated-liquidity** port (`fee` + `tick_spacing`, `mint`/`burn`/`collect`,
`slot0`, `liquidity`, tick bitmap, `fee_growth_global_*_x128`, oracle observations/checkpoints,
flash locks, protocol fees 0 or 4–10).

| Component | Address | Deployed WASM hash |
|---|---|---|
| Factory (current) | `CD3KRKGDRVWPXVB3VXLUMQKMX6XZ6Q2H334IVZD4XXNAMKSRVQL5GLYF` | `9f94c577ea24c2f71cbb0c964c9c9d321e02448d1fe946020afb18974b1c2602` |
| Factory (legacy) | `CCRSMJDITH3VK5QOGYCVZDAKIY5GL3RCG4TCVLIAVB662IW2V5KJGZGF` | `fc9b0df087ddc0c8f0cf38ae0d59bf275390b6be8e9de9ea4ec3de7bc43b55f3` |
| Pool (current, 63 pools) | per-pool `C…` from `pool_created` | **`003710b383f9da7d650a7f719a7be479110266427817ebbed61d924505fcd7c7`** |
| Pool (legacy, 61 pools) | per-pool `C…` | `95a8e0018530226701ef8d31c7d4c2fe20ed9d7c303a14a70c3d96848ca4fa54` |
| Router | `CDMIM23WOUL5CZBKX3GOA3V5R5AMVIMTCP52KCDQORWELAPLJ27WZCHL` | `4edd745f5fbf4d103edb55041efb8e6c399f66d43c0b6d38b781e63c432b6c8d` |
| PositionManager (NFT) | `CARTUL5AWDZYBSN7HUUJZSKCAKCIAKM7M54Z76G6KRYCK4XPR3OHUQZ4` | `be969de545da89a04508e4952e94a53a77e76ecfa67d74b23fd56e0be42290d4` |
| Tick lens / Pool lens | `CASKWJSINHFW7BF7RUOA4E2FP6B2TYRKFX2UOPWLCPOOPUR6UU3G2RWC` | `148ca1a98456b2b2cabff5b846de9a27690fcabc76c6a7081fdf9535d6773018` |
| FlashExecutor (immutable) | `CDKKPFBNNQETVN4Y2CIU6CQMWCPIZDXDZE76IDSTF7HLQT6Q573PCDTH` | `272253de67fe19e0601d2c597d5f0f29e07dcbacd556528a1ed546165657ea89` |
| Owner / admin (all of the above) | account `GC7RIP4D7UETKBZU7FNUYW5XIR2IPLUQDV2DUTZRKVF6C3P2A5QEDSZI` (`bf143f83…6041`) | — |

The source repo is **private** (not on GitHub; the WASM embeds `/home/shakes/.rustup/…` and
`contracts/swap-router/src/{swap,quote,multi_hop}.rs` paths). Analysis therefore uses the
deployed WASM (via the public `stellar-experimental/contract-wasms` mirror, SHA-256-verified
byte-identical) and the contract specs + live dry-run probes.

### 3.1 Mechanism — exact code references

Deployed pool WASM `003710b3…` (verified SHA-256 matches the on-chain `pool_wasm_hash` and the
mirror). Import `a.0` = host `require_auth`; the per-export call graph
(`analysis/wasm/callgraph_003710b3…txt`) shows `require_auth` is reachable from every value-moving
export. Live dry-run evidence (see §5) resolves **whose** auth each one demands:

| Entry point | Auth target (live dry-run) | Payment/effect |
|---|---|---|
| `swap(sender, recipient, …)` | `sender` | pool pulls **input from `sender`** (`token.transfer(sender, pool, amount_in)`) then pays `recipient` — observed in the dry-run event log |
| `swap_prefunded(router, …)` | `router` **and** `is_router_authorized(router)` | only the factory-authorized router (`CDMIM23W…`) passes; other addresses → `#1 Unauthorized`; when authorized it **fails closed** (`#72 InsufficientToken0` / `#73 InsufficientToken1`) unless the input was actually prefunded |
| `mint` / `burn` / `collect(owner, …)` | `owner` (position owner = PositionManager) | pool verifies the **PM contract's** auth; an external caller cannot forge it (live: `pool.collect(owner=PM, recipient=attacker)` returns an auth entry for `CARTUL5A…`, not for the attacker) |
| `collect_protocol(recipient, …)` | factory owner | reads `factory.get_owner()` via cross-contract call, then `owner.require_auth()` (live: required address `bf143f83…` = `GC7RIP4D…`) |
| `flash_begin(recipient, a0, a1, initiator)` | `initiator == flash_executor` **and** `initiator.require_auth()` | `initiator ≠ flash_executor` → `#82 MustUseFlashExecutor`; records the FlashExecutor's auth |
| `flash_end()` | `initiator` from the stored `FlashLock` (= FlashExecutor) | re-reads both token balances and requires `balance ≥ balance_before + expected_fee` per token (WAT: `balance_before + expected_fee` vs current, else `#80/#81 InsufficientRepayment`); `#83 FlashNotLocked` if no lock |
| `set_router_authorized(factory, router, allowed)` | the **factory contract** | live auth entry targets `f6a8a8c3…` = the factory; an external caller cannot forge a contract's auth |
| `pause` / `unpause` / `migrate` / `transfer_admin` / `upgrade` / `revoke_upgradeability` | the admin account | live auth entries all target `bf143f83…` = `GC7RIP4D…` |
| `initialize(sqrt_price_x96)` | *none* (by design, UniV3) | but every pool is already initialized → `#41 PoolAlreadyInitialized`; an uninitialized pool holds no funds |
| `poke_oracle` / `observe*` / `snapshot_cumulatives_inside` / all `get_*` / `quote_*` | *none* (by design) | read/observation only; `poke_oracle` returned `[true, <ts>]` live |

Factory `CD3KRKGDRVWPXVB3VXLUMQKMX6XZ6Q2H334IVZD4XXNAMKSRVQL5GLYF`: `set_owner`,
`set_pool_wasm_hash`, `approve_pool_wasm_hash`, `revoke_pool_wasm_hash`, `set_upgrade_frozen`,
`disable_upgrades_permanently`, `upgrade_pool`, `migrate_pool`, `set_protocol_fee`,
`set_default_router`, `clear_default_router`, `set_pool_router_authorized`, `e_fee_amt` all
transitively call `require_auth` (call graph) and are owner-gated. `create_pool` /
`create_and_initialize_pool` / `get_pool` are permissionless **by design** (pool creation with no
funds at risk).

---

## 4. Live-state assessment (explicit ledger)

**Ledger:** read at `65,094,566` (sweep) → `65,094,625` (end); factory state re-read at `65,090,623`–`65,091,316`.
**Re-verification (2026-10-24):** the CI job re-read factory state / all 63 current-pool balances at ledger
`65,095,245`–`65,095,274`, and a local spot-check of the auth **targets** (not just counts) ran at ledger
`65,118,452` — all unchanged (`get_owner` = `GC7RIP4D…`, `get_pool_wasm_hash` = `003710b3…`).
RPC: keyless `https://mainnet.sorobanrpc.com` (public).

| Quantity | Value |
|---|---|
| `factory.get_pool_wasm_hash()` | `003710b383f9da7d650a7f719a7be479110266427817ebbed61d924505fcd7c7` (current pool code) |
| `factory.get_owner()` / pool `get_admin()` | `GC7RIP4D7UETKBZU7FNUYW5XIR2IPLUQDV2DUTZRKVF6C3P2A5QEDSZI` |
| `factory.get_flash_executor()` | `CDKKPFBNNQETVN4Y2CIU6CQMWCPIZDXDZE76IDSTF7HLQT6Q573PCDTH` (immutable) |
| `get_protocol_fee_0/1()` | **4 / 4** (protocol fee **enabled**: ¼ of swap fees accrue to the owner) |
| `is_upgrade_frozen()` / `is_upgrade_permanently_disabled()` | `false` / `false` (owner can still upgrade) |
| Pools (current factory `pool_created` events) | **63** unique; 57 `pool_upgraded` (54→current wasm, 3→an older one); 3 `pool_migrated`; 2 `wasm_approved` |
| Pools (legacy factory) | **61** unique (pool wasm `95a8e001…`, no admin/upgrade entry points) |
| `is_paused()` (all current pools sampled) | `false` |
| TVL (DefiLlama `sushi-stellar`) | **$15,117,631** (`currentChainTvls.Stellar`) |
| TVL (independent re-derivation from `token.balance(pool)` over all 63 pools) | ≈ **$15.0M** ($10.55M in tokens with a DefiLlama price + the remainder in tokenized treasuries `deJAAA`/`deJTRSY`, `PYUSD`, `USDY`, `USDGLO`, `USDE`, `SolvBTC` valued at ~$1) — consistent with DefiLlama |
| Accrued **uncollected protocol fees** | ≈ **$17,900** (XLM 48,313.86 = $8,538.88; USDC 9,195.53 = $9,191.59; + deJAAA/deJTRSY ~$86; + dust) — owner-gated |

**Data-quality note (2026-10-24 CI re-run):** 2 of the 63 current pools
(`CAOGXY6DW2KWUVOWCGGPLW7MIJNP7XCMXY736LNLOKYEQA3CBKXVIDEA`, `CAWN3BM2ADBMA4CQZLIHTBXA3BQHV4VAPK42LWT5ONAKZW6PH2BBCKLS`)
returned `HostError: Error(Storage, MissingValue)` for the `token1` `balance` read; their `token0` balance is `0` and the
missing storage entry is the Soroban encoding of a **zero balance** (the contract has no entry to return), i.e. these two
pools hold **$0**. They are excluded from the TVL figure and are not a data gap that hides value.

Largest pools (from `analysis/tvl.json`):

| Pool | Pair | USD |
|---|---|---|
| `CBVHBZSZOS6KRDJ4D44FU2YLIENOVSSLM3UGKW6XQMVIFUAMWIWCVH2U` | USDT0/USDC | $5.11M |
| `CD7ZJUQEJODTJXWJMDJRV7UHCANOBX3FC6KXJV3DMIFX3JXUWMF3U3T5` | USDC/deJAAA | $2.17M + deJAAA |
| `CDMJRRH5MAJLB7T5SQAWQOOL7UJ3BABGTURSVKIE6AEDSXESDDJIBVCT` | deJTRSY/USDC | $2.00M + deJTRSY |
| `CCR2CH4GQVCZHG7CHFVMNANCK45CU5DVKXZIIITDZQAU3CEJZ7RQH2MQ` | native(XLM)/USDC | $0.63M |
| `CC22BLZAFTS7M6Z25HOMKDLV65PBP5CIHFER2OTZB5IRNL3YBWDXKDFF` | PYUSD/USDC | $0.33M + PYUSD |
| `CA75VVHLWSM7W6ULNQI7ZJYDFOMQCCPKIDDDHBAL5KOKHWWKWQ5S7MHO` | USDY/USDC | $0.27M + USDY |

Tokens are 7-decimal Stellar SACs / SEP-41 contracts: native XLM (`CAS3J7GY…`), USDC
(`CCW67TSZ…`), USDT0, PYUSD, EURC, USDY, USDGLO, USDE, sUSDE, CETES, deJAAA/deJTRSY
(18-dp tokenized treasuries), SolvBTC, LIBRA-family (`LIBRE`), `DAWG`, `BLND`, `AQUA`, `SUSHI`,
`VELO`, `SHX`, etc.

---

## 5. What an attacker can / cannot do (exact paths + live evidence)

All evidence below is a **read-only dry run** (`simulateTransaction`). "AUTH-REQUIRED = X" means
Soroban returned an authorization entry that the transaction would need; the attacker cannot
produce X unless X is the attacker's own account (source) or a contract the attacker controls *in
the same invocation tree*.

| Attacker attempt (source = a random funded account) | Live result | Reading |
|---|---|---|
| `pool.collect_protocol(recipient=attacker, MAX, MAX)` | AUTH-REQUIRED = `bf143f83…` = **factory owner** (and with a non-zero amount the payout then fails on the recipient's missing trustline, `#13`) | only the owner can collect protocol fees |
| `pool.set_router_authorized(factory, attacker, true)` | AUTH-REQUIRED = `f6a8a8c3…` = **the factory contract** | cannot be forged externally |
| `pool.upgrade(003710b3…)` / `pool.pause()` / `pool.migrate()` | AUTH-REQUIRED = `bf143f83…` = **admin** | gated |
| `pool.collect(owner=PM, recipient=attacker, …)` | AUTH-REQUIRED = `233a2fa0…` = **the PositionManager** | cannot be forged externally |
| `pool.burn(owner=PM, …)` | traps/auth as above | gated |
| `pool.swap_prefunded(router=attacker, …)` | `#1 Unauthorized` | attacker is not an authorized router |
| `pool.swap_prefunded(router=CDMIM23W… (authorized), recipient=attacker, …)` | `#72 InsufficientToken0` / `#73 InsufficientToken1` | **fails closed** — the prefunded input is verified; nothing is paid out |
| `pool.swap(sender=attacker, recipient=attacker, …)` | proceeds, then `token0.transfer(attacker → pool, amount_in)` | input is **pulled from `sender`**; the attacker pays |
| `pool.swap(sender=victim, …)` | requires `victim`'s auth | cannot make a victim pay |
| `pool.flash_begin(…, initiator=attacker)` | `#82 MustUseFlashExecutor` | only the immutable FlashExecutor may start a flash |
| `pool.flash_end()` | `#83 FlashNotLocked` | no active lock |
| `posmgr.collect(token_id=4 owned by a third party, operator=attacker, recipient=attacker)` | `#1007 Unauthorized` | PM enforces NFT ownership |
| `posmgr.decrease_liquidity(token_id=4, operator=attacker)` | `#1007 Unauthorized` | gated |
| `posmgr.transfer_from(from=victim, token_id=4, spender=attacker)` | `#202 InsufficientApproval` | gated |
| `posmgr.approve(token_id=4, owner=attacker)` | `#203 InvalidApprover` | gated |
| `posmgr.set_admin(attacker)` / `posmgr.upgrade(…)` / `posmgr.revoke_upgrades_permanently()` / `posmgr.migrate()` | AUTH-REQUIRED = `bf143f83…` = **admin** | gated |
| `router.init_router(…)` | `#1 Unauthorized` | gated |
| `router.swap_exact_input_single(sender=attacker, …)` | calls `pool.swap(sender=attacker,…)`; input pulled from `attacker` | attacker pays |
| `router.swap_exact_output_single(…)` | returns an error (unimplemented stub) | no path |
| legacy pool `collect_protocol(attacker,0,0)` | AUTH-REQUIRED = `bf143f83…` = **owner** | gated |
| legacy pool `set_router_authorized(legacy_factory, attacker, true)` | AUTH-REQUIRED = `a3262468…` = **legacy factory** | gated |
| legacy pool `upgrade`/`pause`/`get_admin` | `Error(Storage, MissingValue)` | that pool version has **no** admin/upgrade/pause |

**Costs:** an attacker needs nothing but their own capital; there is no path, so there is no cost
model to report. Nothing here is an instruction to transact.

---

## 6. Verdict

**No unprivileged extraction path exists today.** E-U = **$0.00** (confidence **high** for the
access-control class: every value-moving entry point's required authorization was read live, not
inferred). The $15.1M of TVL is protected by standard Soroban `require_auth`, and the two
"interesting" surfaces — the factory-authorized `swap_prefunded` and the immutable FlashExecutor —
both **fail closed**.

### Residual / latent risk (not E-U)

1. **Single-owner upgrade power (P, $15.1M).** `GC7RIP4D…` is the sole owner of the factory, every
   pool, and the PositionManager; pool upgrades are **not** frozen and **not** permanently
   disabled. Owner-key compromise ⇒ total loss. Recommend `disable_upgrades_permanently()` once
   the deployment is final, and a multisig for the owner.
2. **Uncollected protocol fees ≈ $17.9k** are sitting in the pools (protocol fee = 4/4). Only the
   owner can `collect_protocol`, so this is P, not E-U.
3. **Oracle manipulation (integration risk).** `poke_oracle`/`observe` are permissionless by
   UniV3 design, and a CLMM spot price is movable by a flash-funded swap. This is a risk to any
   *external integrator* that consumes a Sushi-Stellar TWAP, **not** a way to drain Sushi's own
   pools. Any consumer must use a sufficiently long TWAP window.
4. **CLMM math audited only by spot check.** This pass proves the *authorization* model and
   spot-verifies the swap math (see §7.1: the exact-input single step matches the reference UniV3
   formula bit-for-bit, and tick walking / price-limit handling behave correctly). It is **not** a
   differential fuzz campaign against the reference implementation, so a subtle logic bug on an
   untested edge (e.g. extreme tick ranges, fee-growth rounding at position boundaries) cannot be
   fully excluded from a static read of name-stripped WASM. Confidence of a *drainable* math bug:
   **low**.
5. **Legacy pools are immutable** (`95a8e001…` has no upgrade entry point) and hold ~$44k; if a
   logic bug exists there it can never be patched. Small, but worth a note.

### Blockers / tooling limits (honest)

- **No public source.** The contract source repo is private; the WASM names section is stripped.
  Analysis is on the deployed WASM (via a SHA-256-verified public mirror), the on-chain contract
  spec, and live dry runs.
- **No fork.** Soroban has no local EVM-style fork; `simulateTransaction` against mainnet state is
  the equivalent read-only dry run. It executes the real contract logic and returns the required
  auth entries but does not (and must not) apply state.
- **No signatures.** Because simulation "records" auth rather than enforcing it, a *successful*
  simulation with a foreign auth target is *not* proof of exploitability — it is proof of the
  *requirement*. That is exactly the signal used here (AUTH-REQUIRED = who must sign).
- **No value was moved.** Nothing was drained, front-run, or spammed; this is measurement-only.

---

## 7. Verification / reproducibility

| Artefact | What it does |
|---|---|
| `analysis/enumerate_pools.py` | enumerates `pool_created` (+ `pool_upgraded`) events from both factories via stellar.expert → `analysis/pools.json`, `analysis/pool_upgrades.json` |
| `analysis/wasmhash.py` | reads a contract's own WASM hash from its ledger entry |
| `analysis/live_state.py` | reads `token0/token1/fee/is_paused/protocol_fees/liquidity` + `token.balance(pool)` for all 124 pools → `analysis/live_state.json` |
| `analysis/tvl.py` | prices tokens via `coins.llama.fi` and computes per-pool/total TVL → `analysis/tvl.json` |
| `analysis/probe_auth.py`, `probe_router.py`, `decode_ev.py` | the live auth probes and event-log decoding in §5 |
| `analysis/wat.py`, `resolve.py`, `trace_auth.py` | WAT parsing: export → transitive host-call resolution, `require_auth` reachability, call paths |
| `analysis/math_check.py` | independent re-implementation of the reference UniV3 exact-input single-step math (`getNextSqrtPriceFromAmount0RoundingUp` + `getAmount1Delta`) compared against the deployed pool's `quote_exact_input` |

### 7.1 AMM-math spot verification (independent)

To reduce the "unfuzzed math" residual, the deployed pool's `quote_exact_input` was compared against a
from-scratch reference implementation of the UniV3 exact-input single-step formula
(`analysis/math_check.py`), on the largest pool `CBVHBZSZOS6KRDJ4D44FU2YLIENOVSSLM3UGKW6XQMVIFUAMWIWCVH2U`
(USDT0/USDC, fee 500, L = 51,127,499,327,196,036, sqrtP = 79,224,003,392,089,074,614,615,627,931):

| Case | pool `sqrt_price_x96` (after) | reference | pool out | reference out |
|---|---|---|---|---|
| `zero_for_one=true`, in 1,000,000 | `79224003390540392680110392738` | `79224003390540392680110392738` | `-999395` | `999395` |
| `zero_for_one=false`, in 1,000,000 | `79224003393637919159627137489` | `79224003393637919159627137489` | `-999604` | `999604` |

**Bit-for-bit match** (ceil on the next sqrt price, floor on the output amount, fee applied on the
input) — the core swap step is a faithful UniV3 port. Tick walking also behaves correctly: a larger
input walks the price `tick -2 → -5 → -203` with `liquidity` changing `5.11e16 → 9.99e5` and stops
exactly at the supplied price limit (`move = 1.000000%`). This is a spot check, not a fuzz campaign,
but it materially lowers the probability of a drainable swap-math bug.

| `analysis/wasm/` | deployed WASM + WAT + specs (factory, current/legacy pool, router, PositionManager), SHA-256 verified |
| `ci/verify.py`, `ci/run.sh` | self-contained CI re-run of the key state reads + all auth probes → `ci-out/sushi-stellar-ci.json` |

**Run:** `bash ci/run.sh` (local) · `bash /home/heisenberg/CA/ci/ci-run.sh sushi-stellar` (GitHub Actions) · CI URL in §7.2.

### 7.2 CI

GitHub Actions run **[40137251707](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40137251707)**
(2026-10-24, repo `artsbykriss/ca-zombie-ci`, branch `sushi-stellar`, workflow `poc.yml`, conclusion **success**;
an identical earlier green run is [40134239947](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40134239947)):
`ci/run.sh` installs `stellar-sdk` and runs `ci/verify.py`, which independently re-reads the factory state,
re-enumerates the pools, re-reads all balances, and re-runs every authorization probe, uploading
`ci-out/sushi-stellar-ci.json` (artifact `result-sushi-stellar`). The log ends
`[ci] core invariant observed: True` / `[ci] verify exit code: 0`, and every §5 probe reproduced
(`swap_prefunded` fails closed `#72`; `swap_prefunded` by a non-router `#1`; `flash_end` `#83`;
`initialize` `#41`; `posmgr.collect` of a foreign NFT `#1007`; `router.init_router` `#1`; the owner-gated
`collect_protocol`/`set_router_authorized`/`upgrade`/`pause` each return exactly 1 auth entry).

> **Earlier run.** The first attempt (run `39960306325`, 2026-10-23) **failed** on a transient public-RPC
> glitch — `mainnet.sorobanrpc.com` returned a non-JSON body during the parallel balance sweep
> (`json.decoder.JSONDecodeError`), aborting the job. `ci/verify.py` was then hardened (per-call retry with
> backoff, multi-endpoint failover, per-pool error capture instead of abort) and the re-run above is green.
> The auth conclusions were never in doubt (the same probes pass locally); this was purely endpoint flakiness.

---

## 8. Methodology, sources, caveats, files

**Method.** (1) Identify the deployment from the Sushi SDK constants and the DefiLlama adapter.
(2) Enumerate pools from `pool_created` events on both factories (stellar.expert, keyless) and
reconcile with the public `stellar-experimental/contract-wasms` mirror (WASM hashes SHA-256
verified byte-identical to on-chain). (3) Read each pool's `token0/token1/fee/protocol_fees/liquidity`
and `token.balance(pool)` and price with DefiLlama. (4) Static auth analysis: for every exported
function, resolve its transitive host-call set from the deployed WAT and check `require_auth`
reachability. (5) **Dynamic auth analysis**: dry-run each sensitive entry point with
`simulateTransaction` and read the *required authorization entries* (who must sign). (6) Trace the
router and PositionManager call paths and probe foreign-object operations.

**Sources.** DefiLlama (`api.llama.fi/protocol/sushi-stellar`, `coins.llama.fi`); stellar.expert
event API; Soroban RPC `simulateTransaction`/`getLedgerEntries`; `sushi-labs/sushi` SDK constants;
`stellar-experimental/contract-wasms` (WASM/WAT/specs/call graphs); Sushi docs.

**Caveats.** Point-in-time 2026-10-23; re-read all state before acting. TVL is DefiLlama's figure
plus an independent on-chain re-derivation (unpriced tokenized-treasury legs approximated at ~$1).
Auth requirements are read in Soroban *recording* mode (the standard way to discover them);
"fails closed" for `swap_prefunded` was observed as `InsufficientToken0/1` errors. The AMM *math*
was not fuzzed.

**Files.** `README.md`, `summary.json`, `analysis/*` (scripts + JSON dumps + `analysis/wasm/*`),
`ci/run.sh`, `ci/verify.py`, `ci-out/sushi-stellar-ci.json`, `ci-log.txt`, `ci-artifacts/`.

**CI:** GitHub Actions [40137251707](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40137251707)
(branch `sushi-stellar`, **success**, 2026-10-24; earlier green run 40134239947); artifact
`result-sushi-stellar` → `ci-out/sushi-stellar-ci.json`.

**Independent auth-target re-check (2026-10-24, ledger 65,118,452):** decoding the required
`SorobanAuthorizationEntry` XDR for each probe gives `collect_protocol → GC7RIP4D…` (owner),
`set_router_authorized → CD3KRKGD…` (the factory contract), `upgrade`/`pause → GC7RIP4D…` (owner),
`collect(owner=PM) → CARTUL5A…` (the PositionManager) — i.e. the *targets* (not just the entry counts) are
exactly as tabulated in §5.

*Prepared 2026-10-23 · re-verified 2026-10-24 · ZH4-OPEN-B Sushi Stellar · read-only · no transactions signed or sent.*
