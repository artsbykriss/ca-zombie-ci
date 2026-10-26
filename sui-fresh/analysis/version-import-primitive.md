# Sui version / package-import primitive — cross-cutting analysis (ZH4 pass-7)

Read-only. Public Sui GraphQL endpoint. No keys, no signing, no mainnet transactions.

## 1. The primitive (why it matters)

A Sui Move package is an immutable object. Upgrading publishes a **new package object at a new
address** while the *original* package id stays the "runtime id" used in type tags. Per Sui's own
docs and the Move Book:

- Sui docs (*Upgrading Packages*): *"You cannot delete old packages from the network... any
  transaction or package that references an old version's package ID can still call it."* and
  *"Without a version check, callers can keep calling the old version of a function... A useful
  pattern is to introduce versioning to the shared object and use a version check to guard access
  to functions."*
- Move Book (*Package Upgrades*): *"old versions of a package remain callable... If version 2 fixes
  a bug in a function that mutates a shared object, an attacker can simply keep calling the version 1
  function — on the very same shared object."*

So the hazard is: an upgrade that **adds/strengthens a guard** (or removes a dangerous function) does
**not** disable the old code, and old code shares the same live objects. It is exploitable iff
(a) the old version's function is still callable, (b) it is unprivileged (`entry`/`public`) and
(c) the live shared objects are still layout-compatible with the old code.

## 2. Empirical proof that the runtime resolves the OLD version's code

Method: `simulateTransaction` (Query field) with a gRPC-proto-JSON transaction
(`{"sender":"0x…","kind":{"programmableTransaction":{"inputs":[],"commands":[{"moveCall":…}]}}}`,
`checksEnabled:true`) — read-only, no signature. See `tools/sim_movecall.py`.

| probe | package called | module::function | runtime result |
|---|---|---|---|
| P1 | DipCoin **v1** `0x978fed07…` | `bank::set_relayer` | `FAILURE: Function Not Found` |
| P6 | DipCoin **latest v9** `0xa5b1b7a4…` | `bank::set_relayer` | `FAILURE: Move Bytecode Verification Error` (function *found*, args wrong) |
| P2 | nonexistent `0x9999…` | `bank::set_relayer` | GraphQL error `Object 0x9999… not found` |

`set_relayer` exists **only in v7+** of DipCoin. Calling it on the v1 package id gives
*Function Not Found* while the same call on the latest id resolves the function → the runtime loaded
**v1's own module set**, i.e. old versions are genuinely callable and are *not* silently redirected to
the latest. (P2 shows what a non-existent package looks like, so the distinction is meaningful.)

## 3. Struct-layout stability (determines exploitability)

Old code can only touch live shared objects if the object's struct layout is unchanged across the
upgrade. For DipCoin we compared the disassembled struct definitions of v1 vs latest v9:

| struct | v1 vs v9 |
|---|---|
| `bank::Bank` (key) | **identical** (`id: UID, accounts: Table<address,BankAccount>, coin_balance: Balance<Ty0>, is_withdrawal_allowed: bool, supported_coin: String`) |
| `bank::BankAccount` | identical |
| `position::Position` (key) | identical |
| `perpetual::Perpetual` (key) | identical |
| `protocol::ProtocolConfig` (key) | identical |

⇒ DipCoin's live perps/bank shared objects are **layout-compatible with v1 code**. (Sui "compatible"
upgrades keep existing field layouts; new fields are not added to `key` structs.) The layout gate is
therefore **not** a protection here — the gating logic itself is the only protection.

### 3b. Cross-family struct-stability scan (`poc/struct_diff.py`, first vs latest version)

| family | versions | structs identical | structs **changed** | structs only in latest |
|---|---|---|---|---|
| DipCoin | 9 | 94 | **0** | 52 |
| Bluefin Pro | 21 | 52 | **0** | 7 |
| Suigar | 2 | 83 | **0** | 1 |
| Bucket V2 vault | 4 | 11 | **0** | 1 |
| Bucket V2 pool | 4 | 6 | **0** | 1 |
| AlphaLend | 15 | 59 | **0** | 18 |
| Kai leverage | 21 | 49 | **0** | 24 |

**In every family, not a single existing struct changed layout** — upgrades only *added* structs.
Consequence: the layout gate never blocks old code. Any old-version function that is (a) still
callable and (b) unprivileged is a live path; the **only** protection is the gating logic in that old
function (or an explicit version-check object). This is what the per-target reads then check.

## 4. Per-family version inventory (from `poc/version_matrix.py`, paginated & exact-version)

| family | original package | #versions | latest |
|---|---|---|---|
| DipCoin perps | `0x978fed07…` | 9 | `0xa5b1b7a4…` (v9) |
| Bluefin Pro | `0xe7448169…` | 21 | `0x11d01c93…` (v21) |
| Suigar | `0xcbb0929f…` | 2 | `0x76176d69…` (v2) |
| Bucket V2 vault | `0x9f835c21…` | 4 | `0xc1dd2977…` (v4) |
| Bucket V2 pool | `0xc2ae6693…` | 4 | `0x8a46afe6…` (v4) |
| AlphaLend | `0xd631cd66…` | 15 | `0xe48b33ef…` (v15) |
| AlphaFi oracle | `0x7671937b…` | 5 | (latest v5) |
| Kai leverage core | `0x51e0ccce…` | 21 | (latest v21) |
| Kai access mgmt | `0x0d9dd55a…` | 2 | (latest v2) |

Functions that existed in **older** versions but are **absent from the latest** (candidate version-
import hazards — each must be checked for (b) unprivileged and (c) still-reachable-on-live-objects):
see `ci-out/version_matrix.json` (generated by the PoC). Highlights that were then read in full:

- **DipCoin** — v1–v6 `bank::withdraw` / `withdraw_all` / `withdraw_v2`… **Read in full (§5): self-only,
  not a drain.**
- **Bucket V2 pool** — v1–v2 `pool::swap_in`/`swap_out`/`set_fee_config`/`set_price_tolerance`
  (removed by v3/v4) — see `bucket-v2/`.
- **AlphaFi oracle** — v1–v4 `oracle::update_price_from_pyth`, `validate_price_update`,
  `update_max_*`, `update_circuit_breaker_threshold_bps` (absent in v5) — see `alphafi-kai/`.
- **Bluefin Pro** — v1–v9 `bcs_handler::dec_withdrawal`/`enc_deposit`/`enc_operator_update` (operator
  BCS codecs), v1–v17 `account::compute_margin_required` etc.
- **Kai leverage** — v1–v18 `liquidate_col_x/y`, `cetus::destruct_exploited_position_and_return_lp`
  (an incident-response helper), `deleverage_for_liquidation`.
- **Suigar** — v1 `oracle::*` (removed in v2).

## 5. DipCoin v1 `bank::withdraw` — read in full (negative)

`entry withdraw<Ty0>(&ProtocolConfig, &mut Bank<Ty0>, &mut TxIndexer, vector<u8>, address, u128, &mut TxContext)`:

1. `protocol::check_basic` (pause check); reject zero recipient;
2. `sub_accounts::validate_unique_tx(&mut TxIndexer, Arg3)` — replay nonce, **no signature**;
3. `acct = tx_context::sender(ctx)`; require `Bank.is_withdrawal_allowed`; require `accounts[acct]`;
4. require `amount > 0` and `accounts[acct].balance >= amount`;
5. debit `accounts[acct].balance`; `coin::take(bank.coin_balance, amount)`; `transfer::public_transfer(coin, Arg4)`.

The debit is always from the **transaction sender's own** `BankAccount` (`tx_context::sender`), not
from a caller-supplied address. `Arg4` only chooses where the sender's *own* funds go. **⇒ not an
unprivileged drain.** v7+ kept `withdraw`/`withdraw_v2` (the earlier "removed" flag was a pagination
artefact in a pre-fix run; the paginated matrix is authoritative). Conclusion for DipCoin bank:
**$0 E-U from this path.**

## 6. Caveats

- Callability is proven; **exploitability** additionally needs (b) an unprivileged guard-free function
  and (c) layout compatibility. Each per-target claim is in the sibling folders.
- Sui JSON-RPC is deprecated on all public fullnodes; only GraphQL is used. `simulateTransaction`
  accepts a gRPC-proto-JSON tx (field names `commands`, `moveCall`).
- Point-in-time **2026-10-25**; re-read live state before acting.
