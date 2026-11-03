# CA2 OPEN-4 — Stellar "Evergreen" share vault (`CALFCZ4T…`)

**Date:** 2026-11-03 · **Chain:** Stellar mainnet (Soroban) · **Target:** `CALFCZ4TY2CLHDHNJWCZX6JKYGUPV7P3GNQ3UVABXNE5JCV2E774APUM`
**Status:** read-only. No transaction was signed or broadcast, no key was used, no secret or keyed URL was written to this folder. All dynamic checks are `getLedgerEntries` + `simulateTransaction` (record mode) against the public endpoint `https://mainnet.sorobanrpc.com`.

---

## 1. TL;DR

| Question | Answer |
|---|---|
| Evergreen's **isolated TVL** | **$33,752,730.95** — 33,752,730.9523545 USDC held by the vault itself (USDC SAC balance = `total_assets()` exactly; `deployed_assets = 0`; 0 strategy subaccounts). This is **29.6%** of the $113.84M protocol figure, not the whole protocol. |
| **WASM verdict** | **Byte-identical to the published upstream release**, not an unverified fork: on-chain WASM `3bd05dfa…bcd12` (92,025 B) was rebuilt in CI from `upshift-protocol/stellar-upshift-vault-contracts@v0.1.0` (commit `6b786b5…`) with Rust 1.95.0 / wasm32v1-none / Stellar CLI 25.1.0, and the SHA-256 matched exactly (in-CI `cmp`: identical). The contract carries `source_repo=github:upshift-protocol/stellar-upshift-vault-contracts`, `cliver=25.1.0`, `binver=0.1.0`. |
| **Is it a fork of `Into-The-Block-Corp/StellarVaults@c29a8bf`?** | **No.** That repo is a different contract family (a 6-function deposit-record vault, WASM `ca6b85a1…`, used by the sibling XLM/USDC vaults). The Evergreen vault is Upshift's ERC-4626-style `august-vault`. The recon statement "not hash-matched to that repo" is true but does not mean unverified — it matches a *different* upstream repo exactly. |
| **E-U (external unprivileged)** | **$0.00 — high confidence.** 24 record-mode simulations: every value-moving path is gated by `require_auth` and/or SEP-41 allowance; every admin/operator entry point rejects a caller with no role. |
| **P (privileged)** | **$33,752,730.95** — the **operator** key alone can set `deployed_assets` from 0 to an arbitrary fake NAV (the AUM rate limit is skipped at the zero boundary) and redeem a $1 share position for the entire vault balance. The admin (also a single EOA) can replace the WASM with no timelock. |
| **H-O / S** | H-O $0.00 (no stuck value; the 99.94% holder can redeem its entire balance; no allowance is needed by anyone else). S $0.00 permanent. **Liveness caveat:** the WASM *code* entry TTL expires at ledger **65,383,903** (~**2026-11-09**, 5.7 days after the read); if nobody extends/restores it, calls fail until a permissionless restore. |

**Verdict:** the open row is **closed at E-U $0.00**. The deployed code is exactly the audited/attested Upshift v0.1.0 build. The residual risk is a **privileged operator drain (P, $33.75M)** and a single-EOA admin upgrade key — not an unprivileged path.

---

## 2. Categories (definitions used by the campaign)

| Category | USD | Confidence | Basis |
|---|---:|---|---|
| **E-U** — external unprivileged attacker | **0.00** | **high** | 24 `simulateTransaction` probes: all value movers require the owner's/operator's auth or an existing allowance; all role-gated functions return `Unauthorized` (#1). |
| **E-U-conditional** | **0.00** | high | No code condition (pause, zero supply, empty market, stale oracle) opens a path. The only condition that unlocks value is compromise of the operator/admin key, which is a privileged path, not an external one. |
| **H-O** — holder-only / self-service | **0.00** | high | Nothing is stuck. The wallet subaccount holding 99.94% of shares can redeem all of them (`preview_redeem = 33,732,426.5154722 USDC`); the other ~19,766.7 shares are freely redeemable. |
| **P** — privileged | **33,752,730.95** | high on mechanism; high on amount (exact contract math, model) | Operator-only unbounded `deployed_assets` write from 0 → fake NAV → redeem at inflated price (below). Admin can upgrade to arbitrary WASM in one signature. |
| **S** — stuck / bricked | **0.00** permanent | high | All value is reachable. Code-entry TTL lapse would cause a *temporary* freeze, recoverable by any account via `RestoreFootprint`/`ExtendFootprintTTL`. |

Headline for the orchestrator: **live extractable by an external unprivileged attacker = $0.00.** Do not add the $33.75M TVL or the P figure to an E-U total.

---

## 3. Target and live state (ledger 65,285,946; instance last modified 65,267,505)

**Identification note:** the contract's own metadata does not contain the string "Evergreen"; it names the share token **"Sentora USDC" / `sentUSDC`**. "Evergreen" is the label used in the CA2 corpus. Identification rests on the contract ID `CALFCZ4T…` and the WASM hash `3bd05dfa…`, both of which match the OPEN row; the on-chain token name is recorded here so the target is not confused with the sibling USDC vault `CAHEWHOPP…` (a different, deposit-record contract).

`getLedgerEntries` for the contract instance (`analysis/instance_ledger_entry.json`, `analysis/instance_decoded.json`) returned:

| Field | Value |
|---|---|
| WASM hash (executable) | `3bd05dfa2bf65299d359e86a4672a45900e8c5768d9f056ad8da5ccd779bcd12` |
| Instance storage keys | `Admin`, `AssetAddress`, `DeployedAssets`, `Meta`, `Operator`, `SubaccountTypes`, `Subaccounts`, `TotalSupply`, `VirtualDecimalsOffset` |
| Admin | `GCE5LGZ6ADXMKHD6FRYLBRNOBUY4LAZFXJACFSBBN6AOSFFTRJPJZWFH` — **single-key EOA** (thresholds `[1,0,0,0]`, no extra signers) |
| Operator | `GABFK2HTLWNOZDR7EHA2EB4AGYHRC6SWMAORUE64DWUNIVZVCMYEYFH2` — **single-key EOA** (thresholds `[1,0,0,0]`) |
| Asset | `CCW67TSZV3SSS2HXMBQ5JFGCKJNXKZM7UQUWUZPUTHXSTZLEO7SJMI75` (USDC SAC; issuer `GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN`) |
| Share token | `Meta = {decimals: 13, name: "Sentora USDC", symbol: "sentUSDC"}`, virtual decimals offset 6 |
| `TotalSupply` | `328,588,906,164,540,243,848` raw = **32,858,890.616454024** shares |
| `DeployedAssets` | **0** |
| `Subaccounts` | `[GDLVR5MPWXWQNN5TSHIYZ3EVI47YVJ7JOEGODGU54USF24VNBNJ32XJQ]`, type **Wallet** (no strategies) |
| `Paused` | absent → `is_paused() = false` |

Live reads (`analysis/stellar_checks.py`, results `ci-out/stellar-checks.json`):

| Read | Value |
|---|---|
| `total_assets()` | `337,527,309,523,545` raw = **33,752,730.9523545 USDC** |
| Vault USDC SAC `balance(vault)` | `337,527,309,523,545` raw — **identical** (no off-vault assets) |
| `get_deployed_assets()` | 0 |
| `get_strategy_balances()` / `get_wallet_deployed_assets()` | 0 / 0 |
| Share price | **(33,752,730.9523545 / 32,858,890.616454024) = 1.027202389 USDC/share** |
| Wallet subaccount shares | `328,391,238,819,789,961,958` raw = 32,839,123.881979 shares = **99.93984%** of supply |
| Wallet subaccount USDC | 0 (it holds shares, not USDC) |
| Admin / operator / unrelated caller share balance | 0 / 0 / 0 |
| `max_withdraw(wallet)` / `max_redeem(wallet)` | `337,324,265,154,722` / `328,391,238,819,789,961,958` (full) |
| `preview_redeem(all wallet shares)` | `337,324,265,154,722` raw = **33,732,426.5154722 USDC** |

**Isolated TVL = $33,752,730.95.** The rest of the protocol's $113.84M is attributed to the sibling deposit-record vaults, which are a different contract family. We measured the two siblings with public contract IDs: XLM vault `CA54LVHMAY7HGLMVPN4W72XJB4OGKVZBZX26FWN6JD4P3HJFWQUQEHJO` holds **78,689,334.0961488 XLM**, USDC vault `CAHEWHOPPDBQYFMAOLDOXXGUX2BCR7EXP4CWYCRY3NEAJB35YPZMMJFF` holds **24,568,803.2111476 USDC** (both wasm `ca6b85a1…`, admin `GCOB2OVZ…`); a PYUSD vault exists but was not read. XLM was not re-priced, so the $113.84M total is the reporting source's figure, not our sum. Evergreen is the largest single measured USDC component and must not be conflated with the protocol total.

---

## 4. WASM recovery and build verification

### 4.1 Recovered bytecode
- `getLedgerEntries` on the contract-code key for hash `3bd05dfa…` returned the full code entry: **92,025 bytes**, `sha256(code) = 3bd05dfa2bf65299d359e86a4672a45900e8c5768d9f056ad8da5ccd779bcd12` (the Soroban WASM hash is the SHA-256 of the code).
- Saved as `analysis/onchain_vault.wasm`; metadata in `analysis/wasm_metadata.json`.

### 4.2 Embedded provenance
Custom sections of the on-chain WASM:

```
contractmetav0: binver=0.1.0  rsver=1.95.0
                rssdkver=25.1.1#94c2a3b3a5ded6b9cf9cef0c207bf8804f3eb294
contractmetav0: cliver=25.1.0#a048a57a75762458b487052e0021ea704a926bee
                source_repo=github:upshift-protocol/stellar-upshift-vault-contracts
```

The contract spec (`analysis/contract_spec.json`) contains 60 functions, 82 events, 19 error enums and 17 structs — the Upshift `august-vault` surface (ERC-4626 + operator/subaccount/AUM management), **not** the 6-function `Into-The-Block` deposit-record vault.

### 4.3 Reproducible build — in CI
`ci/run.sh` installs the pinned toolchain (Rust **1.95.0**, target `wasm32v1-none`), Stellar CLI **25.1.0** (deb SHA-256 pinned to `0260de46…`), clones `upshift-protocol/stellar-upshift-vault-contracts` at tag **v0.1.0** and runs:

```
stellar contract build --optimize --package august-vault \
  --out-dir /tmp/upshift-build \
  --meta source_repo=github:upshift-protocol/stellar-upshift-vault-contracts
```

**CI result (final run `41653556303`; first run `41651776449` produced the same hash):**

```
rustc 1.95.0 (59807616e 2026-04-14)
stellar 25.1.0 (a048a57a75762458b487052e0021ea704a926bee)
built_path=/tmp/upshift-build/august_vault.wasm
built_size=92025
built_sha256=3bd05dfa2bf65299d359e86a4672a45900e8c5768d9f056ad8da5ccd779bcd12
expected_onchain_sha256=3bd05dfa2bf65299d359e86a4672a45900e8c5768d9f056ad8da5ccd779bcd12
byte_identical_to_onchain_wasm=1
MATCH=1
```

- Final run: **https://github.com/artsbykriss/ca-zombie-ci/actions/runs/41653556303** (conclusion `success`, 2026-11-03); first run: `41651776449` (same result).
- The upstream repo itself publishes the same v0.1.0 hash in `VERIFY.md` (`august-vault: 3bd05dfa…d12, 92,025 bytes`, CLI 25.1.0). We did not rely on that statement: the CI build is independent and byte-identical.
- **Diff = empty.** There is no changed auth or share path relative to upstream v0.1.0. What differs from `c29a8bf` is the whole contract family, not a patch.

### 4.4 Point-in-time caveat
The vault is upgradeable (`upgrade(new_wasm_hash, operator)` → `require_admin`). The match proves the code at instances last modified **ledger 65,267,505**; the admin can change it at any time.

---

## 5. Authorisation analysis (source + live simulation)

### 5.1 Source-level model (v0.1.0)
- `deposit(assets, receiver, from, operator)`: `operator.require_auth()`; if `operator != from`, `transfer_from(operator, from, vault, assets)` needs an **asset allowance from `from` to `operator`**; if equal, a direct `transfer(from, vault, assets)`.
- `mint`: same, with `assets = preview_mint(shares)`.
- `withdraw(assets, receiver, owner, operator)`: `operator.require_auth()`; if `operator != owner`, `Base::spend_allowance(owner, operator, shares)` needs a **share allowance from `owner`**; burns owner's shares and sends assets to the caller-chosen `receiver`.
- `redeem`: same allowance rule.
- `transfer` / `transfer_from` / `approve`: OZ `Base`; `from`/`owner` `require_auth()`, `transfer_from` spends share allowance.
- `upgrade`: `Upgradeable` macro → `_require_auth(operator)` → `require_admin`.
- `propose_admin` / `cancel_admin_proposal` / `set_operator` / `set_aum_limits` / `set_aum_window_limits` / `pause` / `unpause` / `add_subaccount` / `remove_subaccount` / `seed_wallet_net_deployed`: `require_admin` (auth + equality with stored admin).
- `accept_admin`: pending admin's `require_auth`; requires a pending proposal.
- `deposit_to_subaccount` / `withdraw_from_subaccount` / `update_deployed_assets` / `update_wallet_deployed` / `update_wallet_deployed_batch` / `remove_wallet_and_reconcile`: `require_operator` (auth + equality with stored operator).
- `__constructor`: reserved; the host rejects direct invocation.
- **No `update_admin`, no unauthenticated initializer, no public mint of shares.** (The `update_admin` "first call is free" pattern exists in the `c29a8bf` repo's vault — it is absent here.)

### 5.2 Live `simulateTransaction` matrix (record mode)
Record mode returns the exact auth tree a call would need; it does not sign or submit. The attacker source is `GDIMN2XLD2U6ZKDLRDMZD7E5XYZDSMI52N5WEV7MN6NOMBJAC56MCPUK` — an existing, unrelated retail account with **0 USDC, 0 vault shares, no role**. Raw output: `ci-out/stellar-checks.json` (`simulations`, `operator_path`, `holder_liquidity`).

| Call (attacker source) | Result | Required auth / reason |
|---|---|---|
| `deposit(1 USDC, self, self, self)` | revert `Contract #10` (USDC SAC "balance not in allowed range") | Passed all vault checks/auth; fails only because the attacker has no USDC. Any funded caller can mint shares. |
| `mint(0.1 share, self, self, self)` | same `#10` | same |
| `withdraw(1 USDC, self, self, self)` | `Contract #407` `VaultExceededMaxWithdraw` | 0 shares |
| `redeem(1e12 shares, self, self, self)` | `Contract #408` `VaultExceededMaxRedeem` | 0 shares |
| `withdraw(1 USDC, attacker, wallet, attacker)` | `Contract #101` `InsufficientAllowance` | share allowance `wallet→attacker` is 0 |
| `redeem(1e12 shares, attacker, wallet, attacker)` | `Contract #101` | same |
| `deposit(0.1 USDC, attacker, wallet, attacker)` | SAC `#9` "not enough allowance to spend" | USDC allowance `wallet→attacker` is 0 |
| `transfer(wallet shares → attacker)` | record OK, **required auth = `G:GDLVR…`** | holder signature required — not executable by the attacker |
| `transfer_from(attacker, wallet, attacker, 0.1 share)` | `Contract #101` | share allowance 0 |
| `approve(wallet → attacker, 0.1 share, live_until=latest+100)` | record OK, **required auth = `G:GDLVR…`** | owner signature required |
| `upgrade(hash, attacker)` | `Contract #1` `Unauthorized` | admin only |
| `upgrade(hash, admin)` (admin source) | **OK** | admin is a single EOA — **P** |
| `propose_admin` / `set_operator` / `pause` / `set_aum_limits` / `add_subaccount` / `remove_subaccount` / `seed_wallet_net_deployed` / `remove_wallet_and_reconcile` | `Contract #1` `Unauthorized` | admin only |
| `accept_admin()` | `Contract #14` `NoPendingAdmin` | no pending proposal |
| `update_deployed_assets` / `deposit_to_subaccount` / `withdraw_from_subaccount` (attacker) | `Contract #1` `Unauthorized` | operator only |
| `__constructor(attacker, USDC, attacker)` | `Error(Context, InvalidAction)` "can't invoke a reserved function directly" | cannot re-initialise |
| `allowance(wallet, attacker / operator / vault)` | `0` / `0` / `0` | no share allowance anywhere |
| `max_withdraw(wallet)` / `max_redeem(wallet)` / `preview_redeem(all)` | full / full / `337,324,265,154,722` | holder liquidity intact |
| `redeem(all wallet shares, wallet, wallet, wallet)` (source = wallet) | record OK | only the source-account credential; the holder can exit |

**Conclusion:** no fresh/unprivileged caller can mint shares for free, move another holder's shares, withdraw against another owner, or touch admin/operator state.

### 5.3 Self-referential deposit (`from = operator = vault`) — recorded but not executable

A near-miss worth recording because a record-mode probe can look alarming:

- `deposit(assets=1 USDC, receiver=attacker, from=VAULT, operator=VAULT)` returns **OK in record mode** with `required_auth = C:CALFCZ4T…` and would mint `973,517,984,747` raw shares. The reason is structural: `deposit_internal` sees `operator == from` and calls `token.transfer(VAULT, VAULT, assets)` — a self-transfer that moves no value — then mints shares. If the vault could authorize itself, this would be an unprivileged infinite mint.
- It cannot. (1) The vault exports **no `__check_auth`** (the 60-function spec has no such entry). (2) A forged `SorobanAuthorizationEntry` carrying the vault's contract credential fails **enforce-mode** simulation: `Error(Auth, InvalidAction)` / `failed account authentication with error … Error(WasmVm, MissingValue)`. (3) A contract address is only acceptable as (a) a custom account implementing `__check_auth`, or (b) a direct invoker of a sub-call; at the top level the vault is the *current* contract, not an invoker, so `require_auth` on itself cannot be satisfied by an external caller.
- The variant `from=VAULT, operator=attacker` fails at the USDC allowance (SAC `#9`, allowance 0), and `withdraw`/`redeem` with `owner=VAULT` fail at `max_*` because the vault holds 0 shares.

**No mint.** Evidence: `analysis/self_auth_probe.py`, `ci-out/self-auth-probe.json`.

---

## 6. The privileged (P) path — operator can drain the vault

This is **not** an E-U path: it requires the operator key `GABFK2HT…`. It matters because the operator is a single EOA and the vault is otherwise fully liquid.

### 6.1 Mechanism
`update_deployed_assets(operator, amount)` is operator-only and feeds `total_assets = local_balance + Σ strategy.get_balance() + deployed_assets`. The AUM rate limiter is **explicitly skipped when the previous `deployed_assets` is 0** (source comment: *"old_deployed == 0: percentage-based rate limiting is undefined … Changes at the zero boundary are unrestricted"*). The live value is **0**, so the operator's first call can set **any** NAV.

Live record-mode simulation (source = operator) accepted all three:

| `update_deployed_assets(operator, N)` | Simulation |
|---|---|
| `N = 1` | OK (source-account auth only) |
| `N = 100,000,000,000,000,000` ($10B) | OK |
| `N = 11,392,468,804,947,658,614,539` (the exact fake NAV for a $1 deposit) | **OK** |

### 6.2 Exact extraction (contract's own formulas)
`analysis/operator_drain_model.py` → `ci-out/operator-drain-model.json`:

- Operator deposits **D = 1 USDC** at the fair price → receives `9,735,179,847,473` raw shares (0.9735 share).
- Sets `deployed_assets = N = 11,392,468,804,947,658,614,539` raw (≈ $1.139e15), chosen so `max_redeem` equals exactly the operator's share balance.
- Calls `redeem(all, receiver=operator, owner=operator, operator=operator)`; `max_redeem` passes (`convert_to_shares(local, total_assets) == shares`), and the payout is `337,527,319,523,544` raw = **33,752,731.95 USDC** — the entire vault.
- **Profit = 33,752,730.95 USDC** (the pre-existing balance), on $1 of capital, in three transactions.
- The same result holds for D = 100 … 100,000 USDC (profit is always the full pre-existing TVL).

The model uses the deployed conversion formulas and is validated against live reads: `preview_deposit(10,000,000) = 9,735,179,847,473` (exact match) and `preview_redeem(wallet shares) = 337,324,265,154,722`.

**Why it is P and not E-U:** only `GABFK2HT…` can sign `update_deployed_assets`; the attacker simulation returns `Unauthorized` (#1). No allowance, deposit, or public call lets an outsider move the counter.

### 6.3 Admin path
`upgrade(new_wasm_hash, operator)` with the admin EOA succeeds in record mode (source-account credential); any WASM can be installed immediately. There is no timelock. Admin = `GCE5LGZ6…`, thresholds `[1,0,0,0]`.

---

## 7. Liveness: code-entry TTL expires ~2026-11-09

- Instance TTL: `liveUntilLedgerSeq = 66,790,758` (≈ 87 days), bumped by every state-changing call.
- **WASM code-entry TTL: `liveUntilLedgerSeq = 65,383,903`**, i.e. **97,957 ledgers ≈ 5.67 days** after the read (latest 65,285,946) → around **2026-11-09T06:28Z**.
- The contract's `extend_ttl()` only bumps the **instance**, not the code entry. If nobody submits an `ExtendFootprintTTL`/`RestoreFootprint` for the code key, vault calls will fail with `EntryArchived` until a permissionless restore. **Temporary freeze, not loss.** Flagged as an operational blocker, S = $0 permanent.
- This also means a "dead" vault is not permanently dead: restoration is permissionless.

---

## 8. What an attacker can / cannot do (summary)

**Can (harmless or self-funded):**
- Deposit USDC and mint shares to any receiver, including themselves (`deposit`/`mint` are open to any caller; auth is on the `operator`, which is the caller; the vault pulls only the caller's own USDC).
- Redeem/withdraw their own shares, transfer their own shares, approve a spender.
- Call `extend_ttl()` (permissionless by design).
- Donate USDC to the vault (raises NAV for existing holders; no profit without shares).

**Cannot:**
- Mint shares without paying USDC (the token transfer is checked; `deposit` fails at the SAC when the caller is unfunded).
- Spend another holder's shares (`transfer` needs the holder's signature; `transfer_from`/`withdraw`/`redeem` need an allowance that is 0 for every non-owner).
- Pull another holder's USDC (`transfer_from` needs the asset allowance; 0).
- Pause, upgrade, change admin/operator, add/remove subaccounts, alter AUM, seed trackers (`Unauthorized`).
- Re-run the constructor (host rejects reserved function).
- Exploit rounding: deposit rounds shares down, withdraw rounds shares up, `mul_div_i128` promotes to I256 and panics on overflow; a 1-raw round trip loses value.
- Inflation/donation attack: virtual offset 6 and a 32.86M-share supply make the first-depositor attack uneconomic; donations accrue to the 99.94% holder, not the attacker.

---

## 9. Verdict, residual risk, blockers

**Verdict:** **CLOSED for E-U ($0.00, high confidence).** The "unverified Evergreen share vault" premise is falsified: the on-chain WASM is byte-for-byte the published Upshift v0.1.0 release, and its auth/share paths are the upstream ones. The `c29a8bf` repo is not the source of this contract (it is the source of the sibling XLM/USDC deposit-record vaults).

**Residual risk (not E-U):**
1. **Operator key (P, $33.75M).** Single EOA; unbounded first `deployed_assets` write from 0 → NAV inflation → full drain. This is the largest live risk.
2. **Admin key (P, $33.75M).** Single EOA with immediate `upgrade` authority; no timelock/multisig.
3. **Code TTL (S-liveness, temporary).** ~2026-11-09 freeze if not extended/restored.
4. **USDC issuer.** USDC SAC balance is `authorized=true, clawback=false` at entry level, but the Stellar USDC asset has issuer freeze/clawback authority. External blocker.

**What would change the E-U verdict:** a second WASM upgrade to code that drops `owner`/allowance checks (re-check the hash), or a compromised operator/admin key (then the loss is P/key-compromise, still not an unprivileged code path).

---

## 10. Methodology, sources, files

- **Chain reads:** `getLedgerEntries` for the instance and code keys; `simulateTransaction` record mode for 24 calls; `getHealth`/`getLatestLedger` for the ledger. Public endpoint only.
- **Toolchain:** `stellar-sdk` 16.1.0 (XDR decode), Stellar CLI 25.1.0, Rust 1.95.0, wasm32v1-none.
- **Sources of truth:** the deployed ledger entry and WASM (primary), the upstream repo at tag `v0.1.0` (`6b786b5…`), OZ `stellar-contracts@606ec84` (the vault's `stellar-tokens` dependency), and the `c29a8bf` repo only for the sibling-vault comparison.
- **Not relied on:** the protocol's own TVL figure (only the target's measured USDC balance is used), explorer badges, or the upstream `VERIFY.md` hash (independently rebuilt).
- **Limitations:** Soroban has no public fork; the last step of the operator drain is modelled with the contract's exact integer formulas (validated against live `preview_*` reads), not executed on a fork. The GitHub artifact download failed at fetch time (`productionresultssa31.blob.core.windows.net` unreachable); the build result is taken from the CI log and the live-check JSON is a local re-run of the same `analysis/stellar_checks.py` (the CI run of that script exited 0).
- **No secrets:** no key, `.env` value, or keyed URL is present in this folder.

### Files
| File | Contents |
|---|---|
| `analysis/onchain_vault.wasm` | Recovered on-chain WASM (92,025 B; sha256 `3bd05dfa…`) |
| `analysis/wasm_metadata.json` | Embedded provenance + build match |
| `analysis/instance_decoded.json`, `analysis/instance_ledger_entry.json` | Instance storage / raw ledger entry |
| `analysis/contract_spec.json`, `analysis/functions.json` | 60-function Soroban spec |
| `analysis/stellar_checks.py` | Re-runnable read-only checks + simulation battery |
| `analysis/operator_drain_model.py` | Exact P-path model |
| `analysis/self_auth_probe.py` | Self-referential deposit: record vs enforce proof |
| `analysis/sim_results2/3/4.json` | Exploratory simulation transcripts |
| `analysis/vault_events.json` | Vault events in the RPC retention window (one withdraw) |
| `ci/run.sh` | Pinned build + live checks |
| `ci-out/stellar-checks.json` | Final live state + 24 simulations (local re-run of the CI script) |
| `ci-out/operator-drain-model.json` | P-path numbers |
| `ci-out/self-auth-probe.json` | Self-deposit record/enforce result |
| `ci-out/ci-key-lines.txt` | CI-measured build hash lines |
| `ci-log.txt` | Full CI log (final run `41653556303`) |

### CI
- **Final run:** https://github.com/artsbykriss/ca-zombie-ci/actions/runs/41653556303 — `success` (first run `41651776449`, same build hash).
- **Build:** `built_sha256=3bd05dfa2bf65299d359e86a4672a45900e8c5768d9f056ad8da5ccd779bcd12`, `built_size=92025`, `MATCH=1`, `byte_identical_to_onchain_wasm=1`.
- **Live checks:** `live checks exit=0` (same script).
- **Artifact:** `result-ca2-open-stellar`, artifact ID `13237857162` (download blocked at the blob host; the `ci-out/` files here are the CI-log values plus a local re-run of the same script).
