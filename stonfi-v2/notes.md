# STON.fi V2 (TON) — deep-dive notes

**Finding:** P3-STONFI-V2 · **Chain:** TON mainnet · **Date:** 2026-10-21
**Status:** read-only. No keys, no signing, no broadcasts. Everything below is public-chain
reads plus a local `@ton/sandbox` execution of the **deployed bytecode**. PoC: 27/27 PASS.

**Verdict: no unprivileged extraction path found. E-U = $0 (high confidence for the
bytecode-verified v2.2 ConstantProduct code, which holds ~$13.03M of the ~$14.35M v2 TVL).**

---

## 0. TL;DR

| Question | Answer |
|---|---|
| Did v2 drop v1's `pay_to` pool-address guard? | **No.** Same guard, same structure, now at `contracts/router/msgs/pool.fc:18-28` (v1: `contracts/router.func:52-53`). |
| Can an external sender forge a `pay_to`/notification to credit a swap without paying? | **No.** Forged `pay_to` → exit `82 invalid_caller`, no jetton transfer (sandbox, deployed code). Direct `transfer_notification`/`internal_transfer`/`swap` to a pool → exit `0xFFFF` (`wrong_op`) and reserves unchanged. |
| Is v2 a distinct codebase from v1? | **Yes** — different repo (`dex-core-v2`), different custody model (router holds all jettons; pools keep virtual reserves), lp_account two-step liquidity, cross-swap, vaults, 5 pool types. |
| Live TVL assessed | **$14,347,701.81** across 30,190 v2 pools / 51 routers. Of this, **$13,030,543.98** (29,215 pools, 23 routers) runs code that is **byte-identical** to the public repo. |
| Headline E-U | **$0.00** |

**Important correction to the parent's premise:** `https://api.ston.fi/v1/pools?dex_v2=true`
returns **both** v1 and v2 pools. The largest router `EQB3ncy…TiUt` is **major_version 1,
minor_version 0** and holds **18,826 pools / $9,749,006.80** — that is the already-closed v1
codebase (`ston-fi/dex-core` @ `6ab5b1c`), not v2. The true v2 split is:

| group | pools | TVL (USD) | code hash verified? |
|---|---:|---:|---|
| v2.2 ConstantProduct routers | 29,215 | 13,030,543.98 | **yes** (router, pool, lp_account, lp_wallet, vault) |
| v2.1 ConstantProduct routers | 965 | 445,679.91 | no (v2.1 source not published) |
| v2.2 WeightedStableSwap / StableSwap / WeightedConstProduct | 10 | 871,477.93 | no (deployed hash ≠ public HEAD build) |
| **v2 total** | **30,190** | **14,347,701.81** | |
| v1 (out of scope, prior corpus row C2-38) | 18,826 | 9,749,006.80 | v1 only |
| **all pools returned by the endpoint** | **49,016** | **24,096,708.61** | |

Largest single pool: `EQCGScrZe1xbyWqWDvdI6mzP-GAcAWFv6ZXuaJOuSqemxku4` (USDT/TON, v2.2 CP,
router `EQCS4UEa…cN3`, lp_fee 7 / protocol_fee 3) — **$4,974,815**; on-chain reserves at
`last_transaction_lt 111448125000011`: **2,495,983.160467 USDT** and **1,838,503.356806 TON**
(jetton wallet balances `EQCSLWJ9…p3` / `EQCSIMG…a3`).

---

## 1. Sources found (with commit hashes)

| What | URL | Commit / version |
|---|---|---|
| **v2 contracts (audited)** | https://github.com/ston-fi/dex-core-v2 | `af0a955cc835af9697cd383e201fefcbe1a6a87e` — "bump v2.2", 2025-03-31; `package.json` v2.2.0; no tags, only 2 commits (squashed) |
| v1 contracts (comparison only) | https://github.com/ston-fi/dex-core | `6ab5b1cb3ddb6a37a070f980bae84acbb0197814` — "initial release", 2023-01-25 |
| Live pool list | https://api.ston.fi/v1/pools?dex_v2=true | 49,016 pools, raw dump `analysis/pools_v2_raw.json` |
| Live router registry | https://api.ston.fi/v1/routers | 51 routers with major/minor version; `analysis/routers_raw.json` |
| Account code/data | https://toncenter.com/api/v3/addressInformation?address=…&include_boc=true | code (PUBLIB library cell) + data BOC |
| On-chain getters | https://toncenter.com/api/v3/runGetMethod | `get_router_data`, `get_pool_data`, `get_router_version` |
| Masterchain head | https://toncenter.com/api/v3/masterchainInfo · https://tonapi.io/v2/status | `seqno 100470576` / `100470578` (2026-10-21) |

`github.com/ston-fi/dex-v2` → 404. `@ston-fi/dex-core-v2` is **not** published on npm (E404).
Org repo list (28 repos) was enumerated; `dex-core-v2` is the only v2 core repo.
`dex-core-v2` has one branch (`main`) and no tags; neither HEAD nor any commit matches the
v2.1 / non-CP deployed hashes (see §3).

---

## 2. Architecture (why v1's guard still matters, and what changed)

**v1:** each pool holds its own jettons in its own jetton wallets; the pool sends `pay_to` to
the **router**, the router verifies `sender == pool(token0,token1)` and transfers from *the
pool's* jetton wallet. Guard: `dex-core/contracts/router.func:52-53`.

**v2:** custody changed. All jettons for a given jetton live in **one jetton wallet owned by
the router**. Pools keep only **virtual reserves** (`storage::reserve0/1`) and instruct the
router to pay out. So the router is the sole custodian, and the `pay_to` guard is the *only*
thing preventing an arbitrary caller from spending the router's wallet.

Flow (v2.2 CP):
```
user --jetton transfer--> router's jetton wallet --transfer_notification--> router
  router: route_dex_messages(sender_wallet, amount, from_address, dex_payload)
  router --op::swap(amount0|amount1)--> canonical pool (address = f(router, walletA, walletB))
  pool:   reserve_in += amount_in ; reserve_out -= (out + protocol_fee + ref_fee)
          save() ; --op::pay_to(out, token0/1)--> router
  router: verify sender == f(token0,token1) ; --jetton transfer--> user
          (or, for cross_swap, re-route the same amount into a second pool)
```
The pool credits only **after** the router's jetton wallet has credited the actual transfer
(the notification is emitted by the receiving wallet), so credits are backed. The pool debits
and `save()`s before the payout is delivered; a bounced payout leaves the tokens in the
router's wallet as an unaccounted surplus (donation), not a credit — no double-credit path.

v2-only surface checked: cross-swap (`op::cross_swap` → `route_dex_messages`), referral
vaults (`pay_vault` / `vault_pay_to` / `withdraw_fee`), `provide_lp` two-step via
`lp_account`, direct single-sided liquidity (`direct_add_liquidity`), 5 pool types
(CP / CS / SS / WCP / WSS). **No concentrated-liquidity (CL) pools in v2.**

---

## 3. Code-hash verification (source ⇄ deployed bytecode)

v2 accounts use **PUBLIB**: the account `code` is an exotic *library reference* cell
(`0x02` + 256-bit library hash). The account's `code_hash` is therefore the hash of the
*reference cell* (e.g. router `a7e2f92c…`), **not** the code. The real code hash is the
256-bit library hash inside it. Extracting that gives an exact match to the local build:

| Contract | Live account | Library hash (= real code hash) | Local build (`af0a955`, func 0.4.4-newops.1) | Match |
|---|---|---|---|---|
| Router (CP, v2.2) | `EQCS4UEa5UaJLzOyyKieqQOQ2P9M-7kXpkO5HnP3Bv250cN3` | `848d1da9f94d125219685290a670a23573a3ff671dfe3c04b7aa8832c6a4f5cc` | `848d1da9…f5cc` | **YES** |
| Pool (CP, v2.2) | `EQCGScrZe1xbyWqWDvdI6mzP-GAcAWFv6ZXuaJOuSqemxku4` | `a9338ecd624ca15d37e4a8d9bf677ddc9b84f0e98f05f2fb84c7afe332a281b4` | `a9338ecd…81b4` | **YES** |
| LPAccount | from `get_router_data` | `c95a2ed22ab516f77f9d4898dc4578e72f18a2448e8f6832334b0b4bf501bc79` | `c95a2ed2…bc79` | **YES** |
| LPWallet | from `get_router_data` | `c00836440d084e44fb94316132ac5a21417ef4f429ee09b5560b5678b334c3e8` | `c0083644…c3e8` | **YES** |
| Vault | from `get_router_data` | `e874ac89ab826bb4403e5e7bdb8b95df3698d2e7187fa366246e98ce329ea613` | `e874ac89…a613` | **YES** |
| Router (CP, v2.1) | `EQDi1eWU3HWWst8owY8OMq2Dz9nJJEHUROza8R-_wEGb8yu6` | `ef73e257a8c09b7f3a027b14171c06818242e30a05b16cf1d01bed2fcc936efb` | not reproduced | **NO** |
| Router (WSS, v2.2) | `EQAGV9vw11tKW2QOCYCXEmIdyufM3p5CfcgHcY9NiiBLfZGH` | `57de63d28e4d3608e0c02d437a7b50ef5f28f36a4821a047fd663ce63f4597ec` | best grid `0d000208…ccd` | **NO** |

Spot checks: two further v2.2 CP routers (`EQAQYbnb…fzR`, `EQCDT9dC…sWD`) both carry
`848d1da9…`; two further v2.2 CP pools (`EQBbsMjy…NGO`, `EQAFtMZm…PdX`) both carry
`a9338ecd…`. So the whole v2.2 CP family is one code pair.

Build grid tried for the non-matching routers (all `constant_product`/`weighted_stableswap`,
version 2.1/2.2 release, lp_fee ∈ {20,7}, protocol_fee ∈ {10,3}, locked ∈ {0,1},
func 0.4.4-newops.1 / 0.4.5 / 0.4.6, O0/O1/O2): **no match**. Conclusion: the v2.1 and
non-CP deployed code was built from source that is **not** the public HEAD. Their ABI and
message flow are the same (verified from live traces / getters), but bytecode identity is
unproven. Raw: `analysis/code_hash_match.json`, `analysis/router_data_v2.2.json`.

Build artifacts used by the PoC: `poc/artifacts/deployed_artifacts.json`
(router/pool code BOC + live data BOC). Router `code_boc` hash and pool `code_boc` hash are
asserted against the on-chain library hashes at test start.

---

## 4. Guards verified — exact `file:line` (repo `af0a955`)

### 4.1 The core guard: `pay_to` is pool-authenticated (v2's v1-equivalent)

`contracts/router/msgs/pool.fc`
- `:5` — `if ctx.at(OPCODE) == op::pay_to` (op `0x657b54f5`)
- `:18-27` — rebuild the canonical pool from `(my_address(), token0_address, token1_address,
  jetton_lp_wallet_code, lp_account_code)`
- **`:28` — `throw_unless(error::invalid_caller, equal_slices(pool~address(params::workchain), ctx.at(SENDER)))`** ← the guard
- `:70-88` — pay out `amount0_out` **or** `amount1_out` (only one is ever non-zero) via
  `jetton_wallet::transfer(...)`; `fwd_opcode == op::cross_swap` re-routes instead (`:46-55`)

v1 equivalent: `dex-core/contracts/router.func:43` (`if (op == pay_to)`), `:52-53`
(`get_pool_state_init_and_address(token0,token1)` then
`throw_unless(INVALID_CALLER, equal_slices(pool_address, sender_address))`).
**Same check, not removed.** v2 additionally binds `excesses_address`, `original_caller`,
`custom_payload` and `additional_info` in the body, and checks `to_address` workchain in the
pool (`contracts/pool/msgs/router.fc:42-47`).

Sandbox proof against the deployed bytecode (`poc/run.js`):
- forged `pay_to` from an arbitrary treasury → **exit 82**, 0 jetton transfers;
- `pay_to` from the canonical pool with a substituted token pair → **exit 82**;
- `pay_to` from the canonical pool, correct pair, 1000 units → **exit 0**, jetton transfer of
  exactly 1000 to the named owner.

### 4.2 Pool-side dispatch (only the router or the protocol-fee collector can move reserves)

`contracts/pool.fc`
- `:16` — rejects non-zero workchain senders
- `:22-25` — `if equal_slices(sender, storage::protocol_fee_address) { handle_protocolfee_messages(); }`
- **`:28-31` — `if equal_slices(sender, storage::router_address) { handle_router_messages(); }`**
- `:33-39` — `handle_lp_wallet_messages()` (burn) and `handle_lp_account_messages()` are
  separately gated by derived-address checks (§4.4/§4.5)
- `:48-52` — otherwise only getter messages; `throw(error::wrong_op)`

Sandbox: direct `swap` / `internal_set_fees` / `internal_update_status` /
`transfer_notification` / `internal_transfer` from an arbitrary address → **exit 0xFFFF** and
reserves byte-for-byte unchanged.

### 4.3 Constant-product math (rounding favours the pool)

`contracts/pool/pools/constant_product/pool.fc`
- `:2` — `amount_in_with_fee = amount_in * (fee_divider - lp_fee)` (no fee on input rounding)
- `:3` — `base_out = muldiv(amount_in_with_fee, reserve_out, reserve_in*fee_divider + amount_in_with_fee)`
  → **floor** (`muldiv` = `MULDIV` semantics; `@ton/core` `muldiv` floors), favours pool
- `:9` — `protocol_fee_out = divc(base_out * protocol_fee, fee_divider)` → **ceil** (`DIVC`), favours pool
- `:13` — `ref_fee_out = divc(base_out * ref_value, fee_divider)` → ceil, capped at 1 %
  (`params::max_fee = 100`, `contracts/common/params.fc:13`; checked in
  `contracts/pool/msgs/router.fc:81`)
- `:16` — `base_out -= protocol_fee_out + ref_fee_out`

`contracts/pool/msgs/router.fc`
- `:92-105` — reserve credit/debit; protocol fee accrued separately (`collected_token*`)
- `:111` — `tx_deadline > now()` (v1 had no deadline)
- `:112` — `total_supply_lp > 0`
- `:113` — `out >= 1`
- **`:114` — `min_out > out` → `swap_refund_slippage`** (full refund, no partial fill)
- `:115-118` — post-state reserve bounds (`0 < reserve < 2^120-1`)
- `:152` — `storage::save()` only after the payout message is queued; any throw takes the
  `catch` at `:153-174` and refunds the input without saving

Sandbox against live reserves (r0=2,495,983,160,467 / r1=1,838,503,356,805,576, fee 7/3):
`amount_in = 1e9` → `pay_to = 735,553,921,026` = formula exactly
(`baseOut 735,774,653,423`, protocol fee 220,732,397); `reserve0 += 1e9`;
`reserve1 -= baseOut`. `min_out = reserve1` → `swap_refund_slippage`, full 1e9 refund,
reserves unchanged. Expired deadline → `swap_refund_tx_expired`, reserves unchanged.

### 4.4 Liquidity: LP account and LP wallet are derived-address authenticated

`contracts/lp_account.fc:19-30` — only `sender == pool_address` or `sender == user_address`
are handled. `contracts/pool/msgs/lp_account.fc:18-26` — `cb_add_liquidity` requires
`sender == lp_account(my_address(), user_address)`; `:146-151` — same for `cb_refund_me`.
`contracts/pool/msgs/lp_wallet.fc:11-22` — `burn_notification_ext` requires
`sender == lp_wallet(from_address, my_address())`; `:25-35` — burn output is
`muldiv(lp_amount, reserve, total_supply)` (floor) with both sides > 0 and supply > 0.
`contracts/lp_wallet.fc:20` — `transfer` requires `sender == owner`; `:111` — `burn` requires
`sender == owner`.
Initial deposit: `contracts/pool/msgs/lp_account.fc:31-46` — `sqrt(a*b)`, 1000 LP locked
(`params::required_min_liquidity = 1001`, `contracts/common/params.fc:10`).
`provide_lp` credit is only booked in `cb_add_liquidity`; until then the tokens sit in the
router wallet unaccounted and `refund_me` returns exactly the booked amount
(`contracts/lp_account/msgs/user.fc:4-38`), so there is no double-spend of a pending deposit.

### 4.5 Referral / vault / excesses

`contracts/vault.fc:40` — `deposit_ref_fee` only from `storage::router_address`;
`:51-71` — `withdraw_fee` is callable by anyone but pays only
`storage::owner_address` via `vault_pay_to`; `contracts/router/msgs/vault.fc:9-13` —
`vault_pay_to` requires `sender == vault(to_address, token, router)`. So a third party can
trigger a referral payout but cannot redirect it. `excesses_address` is only ever the TON
change recipient (`utils::send_excesses`), never jettons.

### 4.6 Privileged surface (P, not E-U)

`contracts/router/msgs/admin.fc` — `set_fees` (`:6`), `reset_pool_gas` (`:55`),
`update_pool_status` (`:86`), `update_pool_code` (`:117`), `update_status` (`:148`),
`init_code_upgrade` (`:156`, 7-day timelock), `init_admin_upgrade` (`:171`, 2 days),
`init_pool_code_upgrade` (`:186`), `cancel_*`, `finalize_upgrades` (`:235`). All behind
`if equal_slices(ctx.at(SENDER), storage::admin_address)` (`contracts/router.fc:28-32`).
`contracts/pool.fc:41-45` + `contracts/pool/pools/weighted_stableswap/setter.fc:4-13` —
`set_rate` only from `rate_setter_address` (WSS only).

### 4.7 Async ordering / bounces

`contracts/router.fc:11-13` — bounced messages are ignored (`if ctx.at(IS_BOUNCED) return`).
`msgs::send_simple` builds **bounceable** messages (`funcbox/contracts/msgs.fc:17-26`), but no
handler re-credits on bounce. Because the pool saves its debited state before the payout and
the router ignores bounces, a failed payout can only **strand** value in the router's jetton
wallet (benefits nobody; not withdrawable by an attacker). There is no path where a bounce
re-credits reserves or double-pays.

---

## 5. What an attacker can / cannot do

**Cannot**
- Send `pay_to` to the router claiming to be a pool → exit 82.
- Send `swap`/`provide_lp`/fee/lock messages directly to a pool → `wrong_op`.
- Forge a jetton `transfer_notification` to credit a **real** pool: the router derives the
  pool from the *notification sender* + the payload's other wallet. A fake sender yields a
  **different** pool address (sandbox: routed to `EQATHHCW…` instead of the real pool; real
  reserves unchanged). To credit the real pool you would need to send from that pool's actual
  jetton-wallet address, which only its code controls.
- Exploit rounding: output floors, protocol/ref fees ceil, burn floors.
- Use `min_out`/deadline to force a partial fill: failures refund the whole input and leave
  reserves untouched.
- Redirect referrals/excesses: vault payout address is bound to the vault owner.

**Can (by design, not a finding)**
- Anyone can call `withdraw_fee` on a referral vault — but the payout only goes to the vault
  owner.
- Anyone can toggle nothing: pool `is_locked`/fees/pool code are router-admin-only.
- Create a pool for an arbitrary (even worthless/malicious) jetton; that pool's reserves are
  isolated and can only ever pay out what was actually deposited. A malicious jetton wallet
  can inflate its *own* pool's virtual reserve for free, but the other side of that pool is
  only funded by whoever voluntarily deposits it; there is no cross-pool accounting.

---

## 6. Live-state quantification

- Enumeration: 49,016 pools (`api.ston.fi`, 2026-10-21); 51 distinct routers.
- v2 only: 30,190 pools, **$14,347,701.81**; v2.2 CP (verified code): 29,215 pools,
  **$13,030,543.98**; v2.1 CP: 965 pools, $445,679.91; v2 exotic: 10 pools, $871,477.93.
- v1 (out of scope): 18,826 pools, $9,749,006.80 on `EQB3ncy…`.
- Largest v2 pool: `EQCGScrZ…xku4` — $4,974,815 (USDT/TON, fee 7/3). On-chain reserves
  (`get_pool_data`, lt 111448125000011): `reserve0 = 2,495,983,160,467` (USDT, 6 dp),
  `reserve1 = 1,838,503,356,805,576` (TON, 9 dp), `lp_total_supply = 55,300,686,121,352`.
- Router `get_router_data` (`EQCS4UE…`): id `0x74fc2`, type `constant_product`, locked 0,
  code refs = the four hashes above. `get_router_version` = **(2, 2, "release")**.
- Masterchain head at time of measurement: **seqno 100,470,578**
  (`tonapi.io/v2/status`; `toncenter masterchainInfo` last seqno 100,470,576).

**E-U = $0.00.** **H-O = $0.00.** **P = $0.00** (admin can upgrade/freeze, but that is
privileged and timelocked — not unprivileged extraction). **S = $0.00.**

---

## 7. Verdict and confidence

- **v2.2 ConstantProduct (23 routers, 29,215 pools, $13.03M): E-U = $0, confidence HIGH.**
  The deployed router, pool, lp_account, lp_wallet and vault bytecode are byte-identical to
  the audited public source, and the PoC executes that bytecode against live state.
- **v2.1 ConstantProduct ($0.45M) and v2 exotic ($0.87M): E-U = $0, confidence MEDIUM.**
  Same architecture and message handlers in the public source; the deployed bytecode hashes
  do **not** match any build of the public HEAD, so bytecode identity is unproven. No
  unprivileged path was found in the source or in live traces, but this is not the same
  standard of proof.
- **v1 ($9.75M) is explicitly out of scope** and was closed earlier (row C2-38).

Nothing found rises to a finding. The most useful residual observation is structural, not a
bug: **v2 concentrates all pool jettons in the router's per-jetton wallets**; the pools'
reserves are virtual. That makes the router's `pay_to` guard a single point of failure for the
whole $13M (it is present and correct today), and makes any future router code upgrade
(admin, 7-day timelock) a systemic risk. That is P, not E-U.

---

## 8. Blockers / not done

1. **v2.1 and non-CP v2.2 sources are not public.** Their deployed library hashes do not match
   any build of `dex-core-v2@af0a955` (grid in §3). Cannot bytecode-verify those $1.32M.
2. **PUBLIB resolution.** Public RPCs return the library *reference* cell for the account
   code, not the code. Resolved by reading the 256-bit library hash out of the exotic cell and
   matching it to the local build. `@ton/sandbox` cannot execute a library cell, so the PoC
   redeploys the byte-identical resolved code at fresh addresses (documented in `poc/run.js`).
3. **`api.ston.fi` has no block pin.** TVL/reserve figures are the API snapshot + one
   `get_pool_data` call at an explicit `last_transaction_lt`. Values move with trading.
4. No fork of the full TON state was used; the PoC deploys only router + pool with live data
   and proxies the jetton wallets as message destinations. Jetton-wallet internals are not
   re-executed, but the guard under test is entirely in the router/pool.
5. No formal verification; no fuzzing of the math beyond the exact live-reserve vectors.

---

## 9. Files

```
stonfi-v2/
├── notes.md                      ← this file
├── summary.json                  ← machine-readable summary
├── analysis/
│   ├── pools_v2_raw.json         ← 49,016-pool API dump (from parent)
│   ├── routers_raw.json          ← /v1/routers dump (51 routers)
│   ├── router_data_v2.2.json     ← get_router_data stack for EQCS4UE…
│   ├── code_hash_match.json      ← library hash vs local build, per contract
│   └── tvl_split.json            ← v1/v2/v2.2-CP breakdown (generated)
├── poc/
│   ├── run.js                    ← 27 assertions against deployed bytecode
│   ├── artifacts/deployed_artifacts.json ← code BOC + live data BOC
│   ├── results.json              ← last local run (27/27)
│   └── package.json
├── ci/run.sh                     ← CI job (npm install + node run.js)
├── ci-log.txt / ci-artifacts/    ← filled by ci-run.sh
└── ci-out/                       ← results uploaded by CI
```

PoC run: local `node poc/run.js` → **27/27 PASS**. CI run URL: see `ci-log.txt` / §10.

## 10. CI

- Job: `stonfi-v2/ci/run.sh` → `npm install` in `poc/`, `node run.js`, copies
  `results.json` + `poc.log` to `ci-out/`.
- Run URL: **_(filled after the run — see `ci-log.txt`)_**.
