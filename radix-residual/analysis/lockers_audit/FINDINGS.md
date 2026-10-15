# Lockers audit — JustLock / RlyFun / RadLock (Radix mainnet)

Scope: can an **external unprivileged attacker** (no roles/keys/whitelist, fresh capital, flash
loans allowed) extract live value **right now**? All "attack" tests are Radix Gateway
**preview simulations** (never signed, never submitted). Read-only on-chain reads only.

* State version at scan start: **563,365,207** (JustLock scan) — later stages: JustLock lock data
  @563,365,553; RadLock components @563,382,436 / lock NFTs @563,383,451; RlyFun @563,3xx
  (live reads as of 2026-10-15).
* XRD price used: **$0.00045194** (DefiLlama `coingecko:radix`, 2026-10-15). Token prices for
  non-XRD assets: Astrolescent `/tokens` `tokenPriceXRD × XRD_USD` unless stated (last-trade
  aggregator price; **illiquid positions can be worth far less on liquidation**).
* Attack-recipe files: `jl_*.py`, `rlyfun_*.py`, `radlock_*.py` in this folder; raw dumps alongside.

---

## Verdict table

| Target | Path | Live value | Verdict | Confidence | Gate |
|---|---|---|---|---|---|
| JustLock locker `component_rdx1cpae8…` | `unlock` of a foreign/big lock | — | **E-U $0** | High | receipt bucket (`lock_receipt_manager` NFT) must be *presented by the caller*; used receipts are `put` into `used_lock_receipts` with **no withdrawal method**; only `lock`/`unlock` exist |
| JustLock | time-locked receipts held by users (173 locks) | ~$65.8k nominal | **H-O** | High (class), Med (price) | holder of the LockReceipt NFT can `unlock` once `current >= unlockable_at` (11 XRD locks etc. already past) |
| JustLock | `unlockable_at = None` "forever locks" (30 locks) | ~$121.6k nominal | **S (stuck)** | High | contract assert requires `Some(unlockable_at)`; receipt resmgr `minter_updater`/`non_fungible_data_updater_updater`/`burner` = **DenyAll** → not even the owner badge can mint a replacement receipt |
| JustLock | owner badge (metadata only) | — | **P (metadata only)** | High | owner badge `resource_rdx1t4fh3…` held by `account_rdx12xthsg9…` (JustLock dApp acct); no value-moving owner method exists |
| RlyFun curves (1166 EarlyCurves) | `sell`/`buy` with foreign token bucket | $0 | **E-U $0** | High | curve vault rejects foreign resource (InvalidDropAccess); can't sell junk for XRD |
| RlyFun curves | buy→sell same tx round-trip | — | **E-U $0** | High | −1.89% per round trip (fees: dev 2.5% + platform 1% + jeety 1% + bull 0.9%) |
| RlyFun curves | curve XRD (640 curves) | 1,219,862 XRD ≈ **$551** | liquidity, not claimable | High | XRD is AMM reserve for token holders; no admin/creator path to it |
| RlyFun EarlyPump | `claim_fee` (fee vault) | **633,433.34 XRD ≈ $286** | **P** | High | proof of **pump owner badge** required; fresh-launch dev badge explicitly rejected (see evidence) |
| RlyFun EarlyPump | `claim_early_fee` | 14,280 EARLY (vault) | **P** | High | proof-gated (same class) |
| RadLock (live v2: `package_rdx1p53g7…`) | `withdraw_flat_xrd_fees` / `withdraw_liquidity_fees` | **10,500 XRD xrd_fee_vault ≈ $4.75** + per-token % fee vaults (200 keys) | **P** | High | hard role `admin_auth` = proof of admin badge `resource_rdx1th5shl…` (supply 1, held by RadLock dApp account); simulator returns `Unauthorized` |
| RadLock | TokenLockService `method_call` proxy (dispatch to all lock logic) | — | **E-U $0** | High | role `storage_access_auth` = badge supply 4, held **only by RadLock service components** |
| RadLock | LOCK logic v4 `withdraw` | — | **E-U $0** | High | signature: `withdraw(lock_proof: own, lock_ids: Option<Array<NF id>>, user_proof: own)` — two owned proofs/buckets required, i.e. the lock receipt NFT + user badge; fresh account has none |
| RadLock | locked value in 316 live locks (Locked Resource NFTs) | **~$115.6k nominal** | **H-O** | High (class), Med (price) | Locked-Resource NFT holder withdraws after `unlock_timestamp` (33 locks already expired); admin/team cannot take user locks through public methods |
| RadLock | `withdraw_auth_badge` / `deposit_auth_badge` | — | **E-U $0** | High | role `component_auth` = NonFungible badge requirement |

---

## A) JustLock locker — E-U $0

Component `component_rdx1cpae8nqhyeu2pz6z89vwca8085xels52lhsfrutnvagxz53u3p4yvl`
(blueprint `Locker 1.0.0`, package `package_rdx1p4k2vlr…`; source cloned at
`analysis/src/just-lock_locker/src/lib.rs`).

### Source facts (verified live against deployed roles)
* Only two public methods: `lock(item, unlockable_at, name, description, key_image_url)` and
  `unlock(lock_receipts: Bucket)`. No fees, no royalties (`royalty_config: null`).
* `unlock` asserts the bucket resource == the receipt manager, requires
  `unlockable_at.is_some() && current >= unlockable_at`, then `vaults.get_mut(id).unwrap().take_all()`
  and `used_lock_receipts.put(receipts)`. There is **no method that ever takes from
  `used_lock_receipts`** (verified in state: vault `internal_vault_rdx1nptuh…` only grows).
* Receipt resource (`resource_rdx1nfajj55…`): `minter` = `require(global_caller(locker))`,
  `minter_updater` = **DenyAll**, `burner` = DenyAll, `non_fungible_data_updater` =
  `require(global_caller(locker))`, `non_fungible_data_updater_updater` = **DenyAll**. Nobody can
  forge or mutate receipts. Total minted 423, supply 423, burned 0.
* Component owner role = `require(resource_rdx1t4fh3l… (JustLock owner badge))`, held by
  `account_rdx12xthsg9usgcewtwszlcs5y02wwp6sl6teufwhk8hsuq3q840wajtt` (the dApp account). The
  component exposes only Metadata owner roles → **owner cannot move value**.

### Preview evidence (never submitted)
| Test | Manifest | Result |
|---|---|---|
| N1 fresh account tries to obtain a receipt | `account_rdx16ydf4jd…` (holds 0 receipts) `withdraw` receipt ×1 | **Failed** `AccountError(VaultDoesNotExist{resource_rdx1nfajj55…})` → no way to acquire a receipt except from a holder |
| N2 `unlock` with empty receipt bucket | `TAKE_ALL_FROM_WORKTOP` receipt (absent) → `unlock` | **Succeeded**, no events, no items → no drain via empty input |
| N4 `withdraw` method on locker | `CALL_METHOD locker "withdraw"` | **Failed** type-check: `BlueprintPayloadDoesNotExist` → no such entry point |
| A lock→unlock round trip | withdraw 1 XRD → `lock(…, Some(1700000000i64), …)` → `unlock` | **Succeeded**, events `EventLock`, `EventUnlock`; XRD returned to caller (method is permissionless *for the receipt holder*) |
| B `lock(None)` then `unlock` | 1 XRD with `unlockable_at = None` | **Failed** `PanicMessage("Item can not yet be unlocked, unlockable at: None @ src/lib.rs:216:17")` → forever-lock proven end-to-end |
| C future unlockable | `Some(2082700000i64)` then unlock | **Failed** panic with `Some(Instant { seconds_since_unix_epoch: 2082700000 })` → time gate proven |
| D foreign bucket to `unlock` | 1 XRD bucket to `unlock` | **Failed** `PanicMessage("Invalid lock receipts @ src/lib.rs:200:13")` |

Deployed-code confidence: panic paths in live previews report **`src/lib.rs:200:13` and `:216:17`**,
exactly matching the cloned source (code-hash re-verification via deterministic build was not run).

### Live accounting (423 receipts, 423 lock vaults)
* 220 receipts spent (unlocked, vault empty).
* 173 time-locked locks: 161 with value (~$65.8k nominal incl. sREDDICKS adjustment), 12 empty/zero-value.
* 30 forever locks (`unlockable_at=None`): 25 with value ≈ **$121.6k nominal** (DCKS 402.3M ≈ $120.9k of it).
* Receipt holders: 93 accounts + the locker itself (222 receipts in `used_lock_receipts`, incl. 2
  receipts locked inside locks #19/#185 — nested receipt locks, low value).

Nominal breakdown (top items): S — DCKS 402,296,722 ≈ $120.9k, HIT 7.94B ≈ $29,
other meme locks ≈ $700 total. H-O — DCKS-family 125M ≈ $37.8k, sREDDICKS 67.6M ≈ $22.0k,
SRG 70.4M ≈ $3.8k, PAW 500M ≈ $1.7k (Astrolescent px), FLOOP 236 ≈ $1.1k, XRD 86,982 ≈ $39,
plus ~65 unpriced/meme positions (est. ≪ $1k).

**Liquidity caveat:** DCKS+sREDDICKS ≈ 92% of the total. The only deep DCKS pool (Ociswap
Precision Pool REDDICKS/XRD `component_rdx1cpwwhux…`) holds ≈6.04M XRD / 8.83M DCKS
(~$2.7k of XRD depth). The locked DCKS positions are 15–100× that depth; **realistic recovery is
a fraction of nominal**. Classification (S vs H-O) is unaffected.

## B) RlyFun EarlyCurves — E-U $0; owner fee vault 633k XRD is P

Package `package_rdx1p56v9lj…` (blueprints EarlyCurves, EarlyPump, CommentSection), registry
`internal_keyvaluestore_rdx1krtyftm7ly5fcwj7p9n4ksan9atxcvwhdpg3mnuc42atsdtc5nyu3v`.
1166 curves; **640 hold XRD, total 1,219,862.44 XRD ≈ $551.31** (DefiLlama XRD).

Call patterns were reconstructed from the live frontend bundles (rly.fun) and verified by
simulation (manifest arg counts probed via type-check errors):
`buy(Bucket)` → tokens; `sell(Bucket)` → XRD; `buy_pre(Bucket, Proof(dev))`;
`claim_lp_fees(Proof(dev))`; `dev_claim_reward(Proof(dev))`; `buy_from_pool(Bucket)`;
`set_curve_filled()`.

| Test (all preview) | Result |
|---|---|
| `sell` 100 COKE (its own token) | **Succeeded**; Sell event 0.0181876 XRD for 100 COKE (price 1.837e-4, effective 0.99× last price) |
| `sell` 1,000,000 **DCKS** (foreign) on COKE curve | **Failed** `SystemError(InvalidDropAccess…)` → foreign resource can not be dropped into the curve's token vault; **no junk-for-XRD path** |
| `sell` 50M DCKS | **Failed** `InsufficientBalance {requested: 50M, actual: 35M}` (whale account bound) — rerun bound was the foreign-resource rejection above |
| `buy` with 1M DCKS on COKE curve | **Failed** `InvalidDropAccess` → same protection on the buy side |
| `buy` 10 XRD → `sell` proceeds same tx | **Succeeded**: 10 XRD → 53,937.42 COKE → **9.8109 XRD** back = −1.89%/round-trip (fees). No arbitrage |
| `buy_from_pool` 1 XRD (filled curve) | **Succeeded**: SwapEvent 0.99 XRD → tokens at pool price (routed via `pool_rdx…`), 1% pool fee |
| `set_curve_filled()` on a filled curve | **Succeeded**, no value events (no-op trigger); on unfilled curve → panic `"EarlyCurve is not yet fulfilled @ src/valhalla.rs:349:13"` |
| `x_and_y_opt_vault` | type-check rejects a bucket; not a value-moving entry point for strangers |

**EarlyPump fee vault — the one big pot:**
`check_fee_vault()` (public getter) returns **633,433.343807393 XRD** in `fee_vault`
`internal_vault_rdx1tzm58…` (~$286). Full E-U attempt (single preview):
1. withdraw 420 XRD (simulated attacker capital) → `launch("PROBE", …, Decimal("0.00069"), false)`
   — creates a fresh token + **fresh dev badge** (the attacker becomes a dev);
2. `CREATE_PROOF_FROM_BUCKET_OF_ALL` on the freshly minted dev badge → `claim_fee(Proof)`:
   **Failed** `PanicMessage("Invalid proof: Expected ResourceAddress(9aedd18556…) but got
   ResourceAddress(9a23a51ac3d0… (= the dev badge))")` → claim_fee requires the **pump owner
   badge**, not any dev badge. Clean rejection of the strongest E-U hypothesis.
3. Control: with a proof of the pump owner badge (held by the rly pump dApp account
   `account_rdx1280jw5unz0w3ktmrfpenym6fjxfs7gqedf2rsyqnsgc888ue66ktwl`, supply 3 ids #0–#2),
   `claim_fee` **Succeeded** and moved the **entire 633,433.34 XRD** vault to the caller
   (resource changes: −633,433.34 from fee vault, +633,433.34 to owner acct). → **P**, not E-U.
`claim_early_fee` (early_fee_vault holds 14,280 EARLY) is in the same protected family.

## C) RadLock — E-U $0; locked value ~$115.6k is H-O

The brief's package `package_rdx1pk65frtcahcv0tnllnmucshajj7jl2q3nga0ds9de900nh9yc7vtsq` is the
**original (v1)** deployment. The **live components were recovered from the current app bundle**
(app.radlock.io config) and verified on-ledger:

| Role | Address | Package |
|---|---|---|
| RadlockService | `component_rdx1cptszkemad39h6avf03tz06new2ve80dfyr66ve9yyzdxvtt3j5kgs` | proxy pkg `package_rdx1p53g7…` |
| TokenLockService (storage proxy) | `component_rdx1crn49lcmzyuqpz4lgx8fulegk4pdzjz89lhegs4g5attrgxqjp4amc` | proxy pkg `package_rdx1p53g7…` |
| TokenVestService (storage proxy) | `component_rdx1cp7vsz98w06urq3n00rf9xz9jrlppyk0sukqrm4kvqvkjwucne6puh` | proxy pkg `package_rdx1p53g7…` |
| LOCK logic **v4** (current) | `component_rdx1cqvjerqdt5lmfqhzekhxzjm0dyjmr6d29rra843cxqk9z6epva2xwa` | logic pkg `package_rdx1p4pz6ws…` |
| VEST logic v4 | `component_rdx1cp0vessexwwrfvs3e7al93xkyjef9yj4tffprw72mnpenh5k5rn5er` | logic pkg `package_rdx1p4pz6ws…` |
| dApp definition / admin holder | `account_rdx12xtayjlrzs0d9rga27w48256d98ycgrpde6yrqpmavmyrr0e4svsqy` | admin badge supply 1 |

Badges: `RadLock Admin` (fungible supply 1, held by the dApp account), `RadLock Component Access`
(supply 4, held only by the 3 service components + one more component), `RadLock Service Badge`
(supply 5, components), `RadLock User Badge` NFT (supply 553), `Locked Resource` NFT (supply 426,
309 held by users = live receipts, 117 in the TokenLockService).

### Adversarial evidence (preview)
| Test | Result |
|---|---|
| `get_xrd_fee_vault()` (public getter) | **Succeeded** → returns `Decimal 10500` (10,500 XRD fee vault) |
| fresh account `withdraw_flat_xrd_fees()` | **Failed** `AuthError(Unauthorized{ failed_access_rules: RoleList([("admin_auth", [Protected(ProofRule(Require(Resource("resource_rdx1th5shl…)))))]` |
| fresh account `withdraw_liquidity_fees()` | **Failed** same `admin_auth` requirement |
| fresh account `TokenLockService.method_call()` | **Failed** `Unauthorized { role "storage_access_auth", requires resource_rdx1thy5r0v… }` |
| fresh account `TokenVestService.withdraw_auth()` | **Failed** `Unauthorized { role "admin_auth" }` |
| LOCK logic `withdraw` signature probe | 3 fields: `[0|lock_proof]` expected **Own** (proof/bucket!), `[1]` Option/Enum with Array payload (lock ids), `[2|user_proof]` expected **Own** → withdrawal requires owned proofs (receipt NFT + user badge); fresh account has neither |
| `withdraw_auth_badge` / `deposit_auth_badge` | **Failed** `component_auth` NonFungible badge requirement |

### Live locked value (426 Locked Resource NFTs, `resource_rdx1nfkacd…`)
316 status **Locked** (33 already past unlock time), 110 withdrawn. Nominal USD via Astrolescent:
**≈ $115,615** — ASTRL $58.5k (17.2M), BEER $37.5k (487M), XRD $3.6k (8.05M XRD in 50 locks),
DELIVER $3.2k, WOWO $2.6k, SCRYPTO $1.5k, HIT $1.2k, DOUBT $1.2k, GIFT $0.74k, DFP2 $0.74k,
SINX $0.69k, HUG $0.61k, EARLY $0.49k + ~100 unpriced tokens. Exit is holder-only via the receipt
NFT (+ user badge), unwithdrawn admin cannot touch user locks with public methods. Prices are
last-trade aggregator values; treat as nominal.

---

## Negatives with evidence (summary)
* JustLock: N1 `VaultDoesNotExist`; N2 empty-bucket unlock no-op Succeeded; N4 no `withdraw` method;
  B/C/D panics (None / future / foreign receipt).
* RlyFun: foreign-resource buy/sell → `InvalidDropAccess`; round-trip −1.89%; `claim_fee` with
  self-minted dev badge → `Invalid proof: Expected ResourceAddress(9aedd185…) but got (9a23a51a…)`;
  `set_curve_filled` no-op on filled curve.
* RadLock: every value-moving entry point tested returns hard `Unauthorized` role failures naming
  the specific badge resource; `withdraw` requires two owned proofs.
* Stream-filter note: the public gateway ignores `filter`/uses `affected_global_entities_filter`;
  no manifest bodies retrievable from the stream, so call shapes were verified via the live
  frontend bundles, source, and preview probing.

## Caveats / not done
* JustLock deployed code-hash ↔ source rebuild not reproducible here (needs docker
  `radixdlt/scrypto-builder`); line-number correspondence in live panics is strong but indirect.
* RlyFun and RadLock: no public source; interfaces probed empirically (arg counts / field names in
  type errors), not fully decoded from SBOR schemas.
* RadLock withdrawal was not exercised end-to-end with a real receipt+user-badge pair (no
  id↔holder mapping available publicly); the owned-proof requirement makes the negative solid.
* Valuations are nominal (thin liquidity). E-U verdicts do **not** depend on prices.
* 2 JustLock receipts are themselves locked inside locks #19/#185 (nested) — trapped-id detail not
  resolved; value negligible.
