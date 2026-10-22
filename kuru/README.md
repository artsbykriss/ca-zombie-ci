# P4-03 · Kuru (Monad) — unverified ERC-1967 clones holding user margin: **E-U $0** (closed)

**Date:** 2026-10-22 · **Chain:** Monad (143) · **Status:** read-only; PoC fork-verified only; **no mainnet transaction signed or sent**
**Parent:** ZH4-PASS4 Tier-2 HIGH (P4-03) · **Sibling:** `infrared/` (P4-04)

---

## 1. TL;DR

| Target | Live custody (this block) | Unprivileged attacker can extract | Why closed / open | Latent risk |
|---|---|---|---|---|
| **Kuru `AccountCore`** `0x264123a9…` → impl `0xb52debad…` (unverified) | **966,366.22 MON + 136,809.39 USDC** ≈ **$157,298** | **$0** | `withdraw(uint40,address,uint256,address)` requires `msg.sender` = account owner or an authorised signer holding `ACCOUNT_PERMISSION_WITHDRAW`; `fulfillApprovedWithdrawal` requires the configured `withdrawalAuthority` **and** the owner's EIP‑712 signature (nonce/epoch/deadline). All admin setters are `onlyOwner`. Proven live: attacker reverts `Unauthorized()`, the real owner succeeds. | Newer revision than the Lean‑verified `62c478b`; unverified bytecode |
| **Kuru `MarginAccount`** `0x2A68ba18…` → impl `0x35152507…` (unverified) | **4,195,855.97 MON + 133,466.20 USDC** ≈ **$222,426** | **$0** | `withdraw` / `batchWithdrawMaxTokens` debit `_msgSender()`'s own balance only; `debitUser`/`creditUser` are gated by `verifiedMarket[msg.sender]`; `deposit` credits a named user but pulls tokens from `msg.sender`. ERC‑2771 forwarder is signature‑verified. | Newer revision; unverified bytecode |
| **`KuruForwarder`** `0x974E61BB…` → impl `0xbf6cc109…` (**verified**) | 0 | **$0** | `executeMarginAccountRequest`/`execute` require `verify…()` = EIP‑712 signature over the exact request (`signer == req.from`), monotone nonces, allowed‑interface allow‑list. No `from` spoofing. | — |

**Total live extractable by an external unprivileged attacker now: $0.00 (confidence: high).**
**Total value under custody (holder-recoverable, H-O): ≈ $379,724.90** (5,162,222.19 MON ≈ $109,449.30 + 270,275.59 USDC) at block **115,617,713**, MON **$0.021202** / USDC **$1.00** (DefiLlama `coingecko:monad`, ts 1792673817).

> The pass‑4 lead (`zombie-hunt-iv/pass4/gap-chains.md`, row 2) said *"6,150,375 MON ≈ $137.6k in 141-byte ERC‑1167 clones with unreadable source"*. Correction: the balances have since fallen to **5,162,222 MON**, the contracts also custody **270,275 USDC** the lead did not count, and the "unreadable source" premise is largely resolved — the ABI matches Kuru's **official public SDK**, the DEX contracts are **public on GitHub**, and the exact `AccountCore` withdrawal policy has been **formally verified** by an independent benchmark.

---

## 2. The mechanism, in exact terms

### 2.1 What the two "unverified clones" actually are
Both custody contracts are **OZ‑style EIP‑1967 minimal proxies** (141 bytes incl. CBOR metadata) that read the `0x360894a1…` implementation slot and `delegatecall`:

| Proxy | Impl (unverified) | Impl code | Role |
|---|---|---|---|
| `0x264123a9B96Cc1193944cC25C188f1bD3dFa670e` (`AccountCore`) | `0xb52debad718730ee0a4c12c28e70d346dbcc9e5b` | 33,512 B | Account/margin core for the **spot** order books (per‑account balances, sub‑accounts, builders, signers, spot settlement, withdrawals) |
| `0x2A68ba1833cDf93fa9Da1EEbd7F46242aD8E90c5` (`MarginAccount`) | `0x351525073afa933720329756716fcf7d741e7ff0` | 5,174 B | Legacy CLOB margin account (`balances[keccak(user,token)]`) |
| `0x974E61BBa9C4704E8Bcc1923fdC3527B41323FAA` (`KuruForwarder`) | `0xbf6cc109c6ebca4b28e3e51fd8798294599cfe2a` (**verified**) | 5,7xx B | ERC‑2771 meta‑tx forwarder for the margin account |
| `0xd651346d7c789536ebf06dc72aE3C8502cd695CC` (`Router`) | `0xf1635175914acf4db170395d524323225e1f1a04` | 10,874 B | market factory / owner of markets |

The deployed selector sets were recovered by scanning the runtime bytecode for `PUSH4 <sel> EQ` dispatcher entries (105 for `AccountCore`, 23 for `MarginAccount`, 24 for the forwarder) and resolved against `4byte.directory` / openchain. The `AccountCore` selector set corresponds to the **`accountCoreAbi` shipped in Kuru's official SDK** (`github.com/Kuru-Labs/ts-sdk`, `src/generated/abis.ts`, 104 functions) — i.e. the deployed ABI is publicly known even though the explorer source is not.

### 2.2 The withdrawal gate (the thing the lead wanted tested)
`AccountCore.withdraw(uint40 rootAccountId, address token, uint256 amount, address recipient)` — `0x67f3e6c3`.
The withdrawal policy of exactly this contract (`src/account/AccountCore.sol`) is modelled and **machine‑checked** by the independent `lfglabs-dev/ethereum-verification-benchmark` case **`kuru/withdrawal_limit`** (source revision `62c478b05dfe936c87fa95f35d89307d4a2d303c`; 8 spec groups, combined `PolicyBundle`, "no custom axioms or admitted reference proofs"). The model's authorisation predicate is:

```lean
def withdrawAuthorized (c : Core) (now id : Nat) (caller : Key) : Bool :=
  let accountMeta := c.accounts id
  if accountMeta.rootId = 0 then false
  else if caller = accountMeta.owner then true
  else
    let auth := c.grants accountMeta.rootId caller
    if auth.expiry ≠ 0 ∧ now > auth.expiry then false
    else decide (Nat.testBit auth.permissions 4 = true ∨ Nat.testBit auth.permissions 3 = true)  -- WITHDRAW / INTERNAL_TRANSFER
```

The **approved** path `fulfillApprovedWithdrawal` requires `caller = w.core.authority` **and** `signatureValid` (owner == signer, domain `KuruAccountCore`, chainId, exact `ApprovedWithdrawal` payload, `nonce == approvedNonces[account]`, `authorityEpoch == epoch`, `now ≤ deadline`), then consumes the nonce **before** the transfer (replay‑excluded), all under a persistent reentrancy guard.

### 2.3 `MarginAccount` withdrawal gate
`withdraw(uint256,address)` (`0x00f714ce`) and `batchWithdrawMaxTokens(address[])` (`0x0f163fa8`) debit **`_msgSender()`'s own** `balances` entry only; `debitUser`/`creditUser`/`creditUsersEncoded`/`creditFee` are gated by `verifiedMarket[msg.sender]` (markets registered by the Router). `deposit(_user,_token,_amount)` credits `_user` but pulls tokens from `msg.sender`, so it cannot be used to steal.

### 2.4 ERC‑2771 is not a spoofing vector
`MarginAccount.isTrustedForwarder(0x974E61BB…) == true`, and the forwarder appends the request's `from` to the calldata suffix consumed by `_msgSender()`. `KuruForwarder` (verified source, identical in `Kuru-Labs/Kuru-contracts-dex-public`) only forwards after `verify(req,signature)` recovers the EIP‑712 signer and requires `signer == req.from`, with monotone nonces and an allowed‑interface allow‑list. A forged request reverts `SignatureMismatch`.

---

## 3. Live-state assessment (block 115,617,713 = `0x6e42fb1`)

| Contract | Native MON | USDC (6dp) | USD |
|---|---:|---:|---:|
| `AccountCore 0x264123a9…` | 966,366.2188 | 136,809.390411 | **$157,297.76** |
| `MarginAccount 0x2A68ba18…` | 4,195,855.9678 | 133,466.203201 | **$222,426.63** |
| `KuruForwarder 0x974E61BB…` | 0 | 0 | $0 |
| **Total** | **5,162,222.1866** | **270,275.5936** | **$379,724.90** |

Config (both proxies):
- `owner()` = `0x8b736dce2071783fd9db0a423dad17cc8ed5788b` (both; Kuru multisig)
- `AccountCore.authority()` = `0x15db88bac73d856b3ca53683f82058826a3b6e8f`
- `AccountCore.withdrawalAuthority()` = `0x81f6f37d079b88fdd6c5f674b3f328eee028fe56`
- `AccountCore.feeCollector()` = `0x62ee1b8d1efdf8f73c78db87b888406b194e266a`
- `withdrawalsFrozen()` = `false`, `protocolPaused()` = `false`
- Account id **26** (the largest holder) owner = `0x9daba38229f593d90f99062bb18ed41f57b16ce8`; `getBalance(26, native)` = **73,613.82 MON**, `getSpotReservedBalance(26, native)` = **706,519.58 MON** (reserved = locked in open spot orders). Account 94 holds 50,000 MON; ids 2,4,5,7,11,36,45,57,67,74 hold small amounts.

> Token balance reads: `USDC 0x754704Bc059F8C67012fEd69BC8A327a5aafb603` (`symbol()="USDC"`, `decimals()=6`). WMON balance of both custody contracts is 0.

---

## 4. What an attacker can and cannot do (exact call paths)

| Call (from a fresh address `0x1111…1111`) | Result (raw revert data) | Meaning |
|---|---|---|
| `AccountCore.withdraw(1, 0x0, 1e18, attacker)` | `0x82b42900` = **`Unauthorized()`** | not the owner / no WITHDRAW grant |
| `AccountCore.withdraw(0, …)` | `0xfaba8ebe` = **`AccountNotFound()`** | unregistered account |
| **`AccountCore.withdraw(26, 0x0, 1e18, attacker)`** (a **funded** account) | `0x82b42900` **`Unauthorized()`** | cannot touch even a whale account |
| **`AccountCore.withdraw(26, 0x0, 1, recipient)` from `0x9daba3…` (the owner)** | **succeeds** (`0x`) | the path is live and owner‑gated (not merely dead) |
| `AccountCore.setAuthority / setWithdrawalAuthority / toggleProtocolState / upgradeToAndCall` | `0x82b42900` `Unauthorized()` | `onlyOwner` |
| `AccountCore.createSubaccount(victim, 0)` | `0x82b42900` `Unauthorized()` | only your own root account |
| `AccountCore.createSubaccount(attacker, 0)` | succeeds → id `0x89`; **0 value moved** | registers an empty account |
| `AccountCore.fulfillApprovedWithdrawal(…, sig=0x)` | reverts | authority + signature + nonce + epoch + deadline |
| `AccountCore.f4838452(0/1)` (unresolved 1‑arg fn) | `0x82b42900` `Unauthorized()` | gated |
| `MarginAccount.withdraw(1e18, 0x0)` | `0xf4d678b8` = **`InsufficientBalance()`** | self‑only balance |
| `MarginAccount.batchWithdrawMaxTokens([0x0])` | succeeds, **0 moved** | self‑only |
| `MarginAccount.toggleProtocolState(false)` | `0x82b42900` `Unauthorized()` | `onlyOwner` |
| `KuruForwarder.verifyMarginAccountRequest(…, sig=0x)` | reverts / `false` | no forged relay |

Additional fresh-caller probes (all gated): `AccountCore.transferBetweenAccounts(26,94,native,1e18)` → revert `0x28cddf05` (Kuru custom error, unlisted); `authorizeAccountSigner(26,fresh,…)` → revert; `approveBuilder(26,fresh,…)` → revert. `rootAccountIdOf(feeCollector)` = 3; `rootAccountIdOf(owner multisig)` = 0.

**Cost to an attacker:** nothing extractable ⇒ no flash loan, no capital, no gas beyond a reverting `eth_call`. There is no permissionless value‑moving sink.

---

## 5. PoC / fork verification

`poc/` — Foundry project (`foundry.toml`, `test/KuruGates.t.sol`, `lib/forge-std` vendored). Forks Monad via the **public, keyless** `https://rpc.monad.xyz` (no secret in any file), `evm_version = cancun`.

Tests (assert revert selectors, and assert balances are untouched):
1. `test_AccountCore_attacker_withdraw_reverts_Unauthorized` — `Unauthorized()` for id 26; `AccountNotFound()` for id 0; no value moved.
2. `test_AccountCore_owner_withdraw_succeeds` — same calldata from the real owner **pays out** ⇒ differential proof the gate is auth.
3. `test_AccountCore_admin_setters_revert_Unauthorized`
4. `test_AccountCore_createSubaccount_forOther_reverts` (own account allowed, 0 value)
5. `test_AccountCore_fulfillApprovedWithdrawal_attacker_reverts`
6. `test_MarginAccount_attacker_withdraw_reverts` (`InsufficientBalance()`)
7. `test_MarginAccount_batchWithdrawMaxTokens_is_noop_for_attacker`
8. `test_MarginAccount_toggleProtocolState_reverts`
9. `test_Forwarder_forged_request_reverts`
10. `test_global_no_value_moves` — sweep of all unprivileged attempts; both custody contracts' native balances unchanged.

Run: GitHub Actions, `artsbykriss/ca-zombie-ci`, workflow `poc.yml`.

* **`https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39785217010`** — **green: `Suite result: ok. 10 passed; 0 failed; 0 skipped`** (Monad fork at head, chainid 143, AccountCore code 141 B, AccountCore balance ≈ 965,436 MON). Full log `ci-log.txt`.
* Earlier runs 39783856284 / 39784189678 failed to *compile/run* (an address-checksum literal, then a Foundry `createSelectFork` EVM-selection quirk — fixed by putting the keyless Monad RPC in `foundry.toml` as `eth_rpc_url`); the production paths were never the issue.

Notes: `forge test` uses `eth_rpc_url = "https://rpc.monad.xyz"` in `foundry.toml` so Foundry instantiates the Monad EVM for the whole run (a `vm.createSelectFork` call cannot select a Monad EVM from an Ethereum-configured test EVM). No secret in any file. Local `forge build` clean.

---

## 6. Verdict

**E-U $0.00 (high confidence).** The pass‑4 "unverified clone" residual is a *code‑readability* gap, not an exploit: every value‑moving entry point on both custody contracts is (a) self‑scoped, (b) account‑owner / authorised‑signer scoped, or (c) `onlyOwner`/`onlyAuthority`, and the ERC‑2771 relay is signature‑verified. The `AccountCore` withdrawal policy is additionally covered by an independent machine‑checked proof.

Categories: **E-U $0 · H-O ≈ $379,724.90 · P $0 · S $0**.

**Latent / monitor:** the deployed `AccountCore` is a **newer revision** than the Lean‑verified `62c478b` (it adds sub‑accounts, `authorizeAccountSigner`, `approveBuilder`, `loseWager`) — the formal proof does not literally cover this bytecode. Re‑check if the impl changes (`Upgraded` event) or if `withdrawalsFrozen`/`protocolPaused` flip. `MarginAccount` is described as legacy; if the team ever repoints it, re‑test.

**Blockers:** none. `withdrawalsFrozen=false`, `protocolPaused=false`; the owner path is live.

---

## 7. Methodology & sources

1. **Live reads** (`eth_getCode`, `eth_getStorageAt` EIP‑1967 slots, `eth_getBalance`, `eth_call`) on `https://rpc.monad.xyz` at block 115,617,713; Etherscan V2 (chain 143) for proxy/implementation + verification status.
2. **Decompile / selector map:** heimdall (`decompile`) for the ABI shape + a `PUSH4…EQ` dispatcher scanner; names resolved via `4byte.directory`/openchain. Files: `analysis/accountcore_impl_0xb52debad.hex`, `analysis/accountcore_4byte.txt`, `analysis/abi_diff.json`.
3. **Auth probes:** `eth_call` with `from` = fresh address (`analysis/probe_results.json`, `analysis/probe2`/`final`/`final2` output) — attacker reverts, owner succeeds.
4. **Public sources (the "unreadable source" resolution):** `github.com/Kuru-Labs/Kuru-contracts-dex-public` (MarginAccount / KuruForwarder / Router / OrderBook), `github.com/Kuru-Labs/ts-sdk` (`accountCoreAbi`, `src/account/withdrawals.ts` — `ApprovedWithdrawal` EIP‑712 type + `fulfillApprovedWithdrawal`), `github.com/Kuru-Labs/Kuru-contracts-flow-public`, docs `docs.kuru.io/contracts/Contract-addresses`.
5. **Formal verification:** `github.com/lfglabs-dev/ethereum-verification-benchmark`, case `kuru/withdrawal_limit` (revision `62c478b…`, `src/account/AccountCore.sol`), 8 spec groups + `PolicyBundle`, proofs complete.
6. **Fork PoC:** `poc/`, run on GitHub Actions (see §8).

### Caveats & limitations
- Point‑in‑time snapshot; balances and configs move. Re‑read before acting. Nothing here is an instruction to transact.
- The `AccountCore`/`MarginAccount` **implementations are not verified on the explorer**; the ABI identity is established from Kuru's official SDK + live selector scanning, not from a byte‑exact recompile. A byte‑exact recompile was not attempted for these two (the source revision is not public).
- The Lean model pins `62c478b…` and does **not** mechanise Solidity→Lean refinement, bytecode, or storage layout; it is a strong but not absolute gate for the deployed revision.
- USD uses MON `$0.021202` (DefiLlama, ts 1792673817) and USDC `$1.00`; the headline is $0 so price only affects the H‑O context.
- The 6,150,375 MON / $137.6k figure in `pass4/gap-chains.md` is stale (balances fell; USDC uncounted).

## 8. Files index
```
kuru/
├── README.md                 # this file
├── summary.json              # machine-readable summary
├── analysis/
│   ├── accountcore_impl_0xb52debad.hex   # on-chain runtime of AccountCore impl
│   ├── marginaccount_impl_0x35152507.hex # on-chain runtime of MarginAccount impl
│   ├── kuruforwarder_impl_0xbf6cc109.hex # verified KuruForwarder impl
│   ├── router_impl_0xf1635175.hex
│   ├── accountcore_4byte.txt             # 105 selectors + resolved names
│   ├── abi_diff.json                     # SDK ABI vs on-chain selector set
│   ├── probe_results.json                # eth_call auth probes (raw)
│   ├── probe.py / probe2.py / final.py / final2.py / scan.py / verify_usdc.py
│   └── (sels4byte.sh, accountcore_selectors_resolved.json, selectors_resolved.json)
├── poc/                      # Foundry fork PoC (10 tests)
├── ci-out/                   # CI-produced outputs
├── ci-log.txt                # CI log
└── ci-artifacts/             # CI artifacts
```
