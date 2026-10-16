# Z3-H15 · AZverse (Arbitrum + custody on ETH/BSC/Berachain/BTC) — AssetVault validator-signature binding + permissionless expired-withdrawal crank

**Date:** 2026-10-16 · **Chain:** Arbitrum One (chainid 42161) + custody EOAs on Ethereum, BSC, Berachain, Bitcoin
**Status:** read-only; PoC fork-verified only; **no mainnet transactions were signed or sent**. All numbers from live on-chain reads at recorded blocks + fork simulations in CI.

---

## 1. TL;DR

| Target | Live value (2026-10-16) | Live extractable (unprivileged) | Why closed / open | Latent risk |
|---|---|---|---|---|
| **AssetVault v1** `0x91ba5258…` (impl `0x94a99081…`, UUPS, verified, bytecode-matched) | **$127,357.05** in-contract (56,546.177146 USDT0 + 70,905.068253 USDC + 2 gwei ETH) | **$0** | Every value-moving path is `OPERATOR_ROLE` + **2-of-3 validator signatures**; the one permissionless function (`executeExpiredPendingWithdrawal`) pays only the **recorded receiver**; the 8 stale pending withdrawals are all `paused` → `WithdrawalPaused` revert | Operator key + 2-of-3 validator signer keys (AWS-KMS signer services) = full vault drain — the **AFX-Trade class** (July 2026, $24.15M via hot validator keys). Key-custody risk, not an on-chain bug |
| **AssetVault v2** `0x949556cb…` (impl `0xb5d7cfae…`, same code revision) | **$12.82** in-contract; but it is the **busier production vault** (thousands of withdrawals; activity minutes before the snapshot) | **$0** | Same code, same 2-of-3 scheme (different signer set). All privileged roles on v2 sit on a **single EOA** `0x8d91b670…` (no Safe/timelock) → v2 upgrade/admin key is the weaker link | Key custody (P). $12.82 at risk today |
| **Custody wallets** `0x03a7e587…`, `0xc2a290ec…`, `0xdc379823…` (plain **EOAs** on every chain) | **$51,799,219.72** (dominated by `0xdc379823` = **50,002,409.64 USDT0 ≈ $49.95M** on Arbitrum) | **$0** | Plain EOAs — no contract to exploit. **No live ERC-20 allowances** from any custody wallet to any of the 11 historical spenders (verified live = 0) | Off-chain key/MPC custody (P). DL calls them "third-party qualified-custodian wallets" |
| **BTC hot wallet** `13JJtAGYdjYdHiqBcs9zAy95aWzvbW4Nx6` | $79,364 (DL) | **$0** | Off-chain UTXO custody | P |
| **Governance (v1)** Safe 3-of-4 → 3 timelocks (ADMIN/UPGRADE/VALIDATOR) | — | **$0** | Proposer = Safe only; executors open (standard OZ, harmless without a proposal); bootstrap admin renounced; timelocks self-administered | Safe 3-of-4 + timelock delays (30 min / 24 h) |

**Signature-binding verdict (the finding's premise): NOT loose.** The digest binds `chainid`, `address(this)`, `withdrawalId`, `token`, `amount`, `fee`, `receiver`, `isForcePending` and a single-use `nonce`; OZ v5.6 ECDSA rejects high-`s` malleability and 64-byte EIP-2098; the two-pointer scan cannot double-count a signer. Forging a withdrawal requires **2 of 3 validator private keys AND an operator key** — no unprivileged path exists.

---

## 2. Total live extractable now: **$0.00** (confidence: **high**)

| Category | USD | Notes |
|---|---|---|
| **E-U** (external unprivileged attacker) | **$0.00** | No forgery/replay, no redirect, no double-execute, no live allowances, no unprivileged value path |
| **H-O** (holder/user self-service) | **$0.00** | Users cannot self-withdraw; every withdrawal is operator-initiated with validator signatures |
| **P** (privileged/key custody) | **$51,926,576.77** | $127,357.05 + $12.82 vault balances (operator + 2-of-3) · $51,799,219.72 custody EOAs (key/MPC) · $79,364 BTC hot wallet (key) |
| **S** (stuck/bricked) | **$0.00** today | **$2,704.80** of v1's balance is locked behind 8 paused pending withdrawals — operator-only unpause, not bricked; if abandoned → S |
| **Total live value screened** | **$52,005,953.73** | matches DefiLlama $52,009,583 (delta = price drift) |

**What would change the verdict:** (a) compromise of 2-of-3 validator signer keys **plus** any operator key → full drain of whatever the vault holds at that time (today $127k; the custody reserve is only reachable via its own keys); (b) the operator unpausing the 8 stale withdrawals → anyone can crank them, paying $2,704.80 to the **recorded receivers** (attacker profit still $0); (c) any future contract upgrade weakening the signature check (UPGRADE = Safe → 24 h timelock); (d) the v2 single-EOA admin (`0x8d91b670…`) being compromised → v2 could be upgraded to a drainer (v2 holds $12.82 today).

---

## 3. The finding and the exact mechanism

### 3.1 What the contract does

`AssetVault` (873 lines, solc 0.8.25, OZ v5.6, UUPS) is AZverse Perps' custody + withdrawal settlement contract. **Withdrawals are initiated by a hot "relayer" (`OPERATOR_ROLE`) and must carry validator signatures** meeting a power threshold. A "slow queue" exists for challenge-period review.

### 3.2 `_verifyValidatorSignature` — full review (impl lines 684–725)

```solidity
bytes32 validatorHash = keccak256(abi.encode(validators));      // caller supplies the set
uint256 totalPower   = availableValidators[validatorHash];      // must be registered (else revert)
uint256 requiredPower= validatorRequiredPowers[validatorHash];
bytes32 validatorDigest = MessageHashUtils.toEthSignedMessageHash(digest);   // EIP-191
for (sigIdx…) { (recovered,,) = ECDSA.tryRecoverCalldata(validatorDigest, sig);
                if error → skip;  // sorted two-pointer scan, advances validatorIndex on match
                power += validators[validatorIndex-1].power; }
if (power < requiredPower) revert NotEnoughValidatorPower();
```

* **Digest construction (requestWithdraw):** `keccak256(abi.encode("requestWithdraw", withdrawalId, block.chainid, address(this), action.token, action.amount, action.fee, action.receiver, isForcePending, nonce))` — then EIP-191 `personal_sign` prefix. **Every business field is bound**, plus chain id and contract address.
  * Cross-chain replay: blocked (`block.chainid`). Cross-contract replay: blocked (`address(this)`). Field substitution (amount/receiver/token/fee/id): blocked. Nonce replay: blocked by the global `nonceUsed` mapping (single namespace across all signed actions).
* **Other digests** (`rebalanceWithdraw`, `batchTogglePendingWithdrawal`, `batchFlushWithdrawals`, `batchResetWithdrawHotAmount`) each bind their own action name + fields + chainid + address + nonce — verified by reading all five constructions.
* **ECDSA (OZ v5.6, vendored in the verified bundle):** `s > n/2` → `InvalidSignatureS` (malleability rejected); only 65-byte signatures (EIP-2098 64-byte rejected); `ecrecover` returning 0 → rejected; `v` must be valid for the precompile. **No ecrecover-vs-ECDSA quirk is exploitable.**
* **Signer dedup:** the two-pointer scan consumes each validator slot at most once and the registered set is strictly ascending (enforced in `addValidators`), so duplicate/permuted signatures cannot double-count power.
* **Validator-set confusion:** the set is keyed by `keccak256(abi.encode(validators))`; an attacker-supplied set that is not registered reverts `InvalidValidators`. Only **one** set has ever been registered on v1 (one `ValidatorsAdded` event; zero `ValidatorsRemoved`).
* **Threshold:** `availableValidators[hash]=60`, `validatorRequiredPowers[hash]=40`. The per-signer powers are not in the event, so they were **brute-forced against the on-chain hash** `0x8141d873…`: the only (p1,p2,p3) with p1+p2+p3=60 that hashes to it is **[20,20,20]** → exactly **2-of-3**.

### 3.3 Validator set, key types, custody

| v1 validators (EOAs, `codesize=0`, nonce=0 — never send txs) | power |
|---|---|
| `0x6CC538784e6050A3e842104D7a50A1FaEF1dB3aa` | 20 |
| `0xDa1bB36dE3197A9171b2FF7e45bc27809715323b` | 20 |
| `0xF29Cc2E03DA7AEA7036f44ddc423644028D8cE6F` | 20 |

Signing keys live in **AWS KMS** behind per-key signer services (`github.com/AZverse/asset-vault-signer`: "The service holds one of the signing keys in the AssetVault contract's registered validator set … a withdrawal action needs both the relayer's request and enough validator signatures"; KMS key id `KMS_KEY_ID_VALIDATOR`, relayer PEM auth, CEX risk-check hook). v2 has a different 3-EOA set, also nonce=0 (KMS signers). Operators are 3 hot EOAs (nonces 131–6427).

### 3.4 The permissionless crank `executeExpiredPendingWithdrawal` (lines 556–571)

* Callable by anyone (`whenNotPaused nonReentrant`); requires: withdrawal exists, **pending**, **not executed**, **not paused**, `block.timestamp ≥ timestamp + pendingWithdrawChallengePeriod` (86400 s on v1, 120 s on v2).
* It pays `withdrawal.receiver` (fixed at request time), `amount − fee`; the fee accrues to the protocol; **the caller receives nothing**.
* Redirect impossible (no setter for receiver/amount); double-execute impossible (`executed = true` before the transfer + `nonReentrant` + `_checkWithdrawalNotExecuted`).
* **`executeExpiredPendingWithdrawal` has NEVER been called on v1** (0 of 450 lifetime txs). On v2 it is called only by the protocol's own operator EOAs (9 calls on 2026-10-14) — the permissionless path is used as a convenience, not attacked.

---

## 4. Live-state assessment (addresses, code, balances, roles — with blocks)

**Block numbers used:** Arbitrum `515,255,511` (final balances) and `515,245,153`/`515,246,276` (roles/config/bytecode); Ethereum `26,202,340`; BSC `127,904,931`; Berachain `27,552,948`. Prices: DefiLlama coins at ts `179,212,0561` (2026-10-16 ~03:16 UTC): USDT0 $0.998902, USDC $0.999547, ETH $2,439.93, BNB $728.99, BTC $82,072.53.

### 4.1 Contract identity (verified, not trusted)

* EIP-1967 impl slot of `0x91ba5258…` = `0x94a99081475d0b5B887c5a03FcD9B81e52C264DE`; **admin slot = 0** (UUPS, no transparent-admin); proxy = 163-byte ERC1967Proxy; impl codehash `0x75173058…`.
* **Bytecode verification (CI):** local compile of the verified source (solc 0.8.25, opt 200, cancun) matches the deployed runtime **byte-for-byte** after (i) patching the three UUPS `__self` immutable slots with the impl address and (ii) stripping the 53-byte CBOR metadata suffix. Raw diff = 92 bytes = 3×20 address bytes + 32 metadata-hash bytes, fully explained. Both impls (`0x94a99081…`, `0xb5d7cfae…`) match.
* The project's public repo `AZVerses/asset-vault-contracts` `src/AssetVault.sol` is **identical** to the verified source (873 lines, diff empty).
* One `Upgraded` event each (deployment only). No hidden functions (bytecode == source).

### 4.2 Roles on v1 (event-derived + `hasRole` confirmed live)

| Role | Holder | Type |
|---|---|---|
| DEFAULT_ADMIN / TOKEN / DEPOSIT / PAUSE | `0x4a335BB7f44fc27bf4fbB5705e71014bACe924Ec` | Gnosis **Safe 3-of-4** (v1.4.1; owners `0x8a0447…`, `0xE8ac0D…`, `0xE0318B…`, `0xA91fd0…`) |
| ADMIN | `0x7A1b6891269Ed1699F93e25296a6e23d6f4F7386` | TimelockController (30 min; proposer=Safe, executor open) |
| UPGRADE | `0x92996eA56590b0e659d695d9736Db62Cae843b51` | TimelockController (**24 h**; proposer=Safe, executor open) |
| VALIDATOR | `0x383A6439f966D67eDC6140d12024334616dDC276` | TimelockController (30 min; proposer=Safe) |
| OPERATOR | `0x32fCFf5C9BbCF45F4EfE50219CE9F24DF2889aF3`, `0x9276609d5bCe373938AE20F7c1eab7f0c1220701`, `0x9BBc8a82e24Fd4434103302Edf0f0758D51c575f` | hot EOAs (relayers) |

`rebalanceReceiver = 0x0` on v1 → `rebalanceWithdraw` always reverts `InvalidParameters` (disabled). `paused = false`. Challenge period = 86,400 s. Bootstrap admins were renounced; timelocks are self-administered; the open executor is standard OZ and harmless without PROPOSER.

### 4.3 v2 (the busier vault)

`0x949556cb…` → impl `0xb5d7cfae…`; challenge 120 s; `rebalanceReceiver = 0x8D91b670…` (set). **All of DEFAULT_ADMIN/ADMIN/TOKEN/PAUSE/UPGRADE/VALIDATOR sit on the single EOA `0x8d91b670579d36a5ff7ef8b7e6529a70d32588a5`** (nonce 115) — no Safe, no timelock. Validator set: `0x0915E8…`, `0x258673…`, `0x6e2b56…` (EOAs, nonce 0), total power 60 / required 40 (same 2-of-3 shape). Operators: `0xa9e61f9a…` (nonce 6427), `0x915a90c3…` (3563), `0x9232214a…` (3607). Activity continues (last `requestWithdraw` 2026-10-16 02:29 UTC). Balance: 4.201 USDT0 + 0.451791 USDC + 0.00335 ETH = **$12.82**.

### 4.4 Balances (USD at stated prices)

| Holder | Value | Notes |
|---|---|---|
| v1 vault (in-contract) | **$127,357.05** | 56,546.177146 USDT0 + 70,905.068253 USDC + 2 gwei ETH |
| v2 vault (in-contract) | $12.82 | 4.201 USDT0 + 0.451791 USDC + 0.00335 ETH |
| custody `0xdc379823` (Arbitrum) | **$50,064,725.71** | **50,002,409.638026 USDT0** + 117,157.250426 USDC + 0.0505 ETH — plain EOA |
| custody `0x03a7e587` (Arbitrum) | $195,744.69 | 104,665.36 USDT0 + 90,262.17 USDC + 0.399 ETH |
| custody `0xc2a290ec` (Arbitrum) | $48,774.64 | 19.9902 ETH |
| Ethereum custody (3 EOAs) | $612,818.29 | USDT 451,735.41 + USDC 111,738.77 + 20.44 ETH |
| BSC custody (3 EOAs) | $866,946.48 | USDT 603,167.51 + USDC 209,595.89 + 75.33 BNB |
| Berachain custody | $10,209.99 | 10,221.21 USDT0 |
| BTC hot wallet | $79,364.14 | DL figure (0.967 BTC) |
| **Total** | **$52,005,953.73** | ≈ DL $52.01M |

### 4.5 Approvals / unprivileged pull paths (custody EOAs)

* Arbitrum custody wallets have historically approved **11 distinct spenders** (swap routers etc.; 1000+ `Approval` events). **Live allowance to every one of them is 0** (checked `allowance()` for USDT0 + USDC × 2 wallets × 11 spenders). Ethereum/BSC custody wallets: **0 approval events ever**.
* Operator EOAs and the vault itself: **0 approval events ever** on all three chains.

### 4.6 The 8 stale pending withdrawals on v1 (all paused)

Created 2026-08-29/30 by the three operator EOAs (force-pending), then paused by the operator within ~20 min — a deliberate freeze (challenge-period review). All are `paused=true, pending=true, executed=false`, expired long ago. Total **$2,704.80** (USDC 200.00 + USDT0 2,507.643147). A fresh caller cranking them reverts `WithdrawalPaused`.

---

## 5. What an attacker can / cannot do

| Attempt | Result | Evidence |
|---|---|---|
| Forge validator signatures with own keys | Revert `NotEnoughValidatorPower` | unit tests (`test_nonvalidator_signature_fails`) |
| Reuse one validator's signature twice | Revert `NotEnoughValidatorPower` (no double count) | `test_duplicate_signature_not_double_counted` |
| Malleable high-`s` twin of a valid signature | Rejected (`InvalidSignatureS` → skip) | `test_highS_malleable_signature_rejected` |
| EIP-2098 64-byte signature | Rejected (`InvalidSignatureLength` → skip) | `test_eip2098_short_signature_rejected` |
| Replay across chains (same keys, different chain) | Digest differs; verification fails | `test_digest_binds_chainid` |
| Replay against another vault address | Digest differs | `test_digest_binds_vault_address` |
| Substitute amount / receiver / withdrawalId under a valid signature | Reverts (all fields bound) | `test_amount_is_bound`, `test_receiver_is_bound`, `test_withdrawalId_is_bound` |
| Nonce replay | Revert `NonceAlreadyUsed` | `test_nonce_replay_reverts` |
| Call `requestWithdraw` with no role | Revert `AccessControlUnauthorizedAccount` (fork-confirmed live) | `test_attacker_cannot_requestWithdraw`, `test_fork_fresh_attacker_cannot_requestWithdraw` |
| Crank an expired pending withdrawal as a fresh caller | Pays the **recorded receiver** only; caller earns $0; second call reverts | `test_crank_pays_recorded_receiver_only_and_cannot_double_execute` |
| Crank the 8 stale live withdrawals | Revert `WithdrawalPaused` (fork, live state) | `test_fork_fresh_caller_crank_paused_reverts` |
| Pull custody funds via historical approvals | Live allowances all 0 | `test_fork_no_live_allowances_from_custody_wallets` |
| Re-init the proxy / call impl directly | `InvalidInitialization` / no roles in impl storage | `test_reinitialize_reverts` |
| **Compromise operator + 2-of-3 validator signer keys** | **Full drain of the vault's balance at that moment** | AFX-Trade precedent (2026-07-22, $24.15M via 5-of-7 hot validator keys). **Privileged (P), not E-U.** |

Gas/cost notes: the crank costs ~100–150k gas and returns nothing; there is no capital requirement and no flash-loan surface anywhere in this contract (no pricing/oracle logic at all).

**Latent ops hazard (not E-U, documented):** `requestWithdraw` does not enforce `fee < amount`; a validator-signed pending withdrawal with `fee ≥ amount` can never be executed (`_transfer` reverts `InvalidParameters`) and there is no cancel/setter — permanently stuck until an upgrade. Fork-proven (`test_fee_ge_amount_pending_is_permanently_stuck`). Requires operator+validator error, not an attacker path.

---

## 6. PoC / fork verification

* **Unit suite** (`poc/test/AssetVaultUnit.t.sol`): mirrors live config (3 validators, powers [20,20,20], required 40, challenge 86,400 s, hardCapRatioBps 10000, refillRateMps 12) — **20/20 PASS**.
* **Fork suite** (`poc/test/AssetVaultFork.t.sol`): Arbitrum mainnet fork against live state — 12/12 PASS (impl slot + codehash, live config, roles, validator hash brute-force, the 8 paused withdrawals, fresh-caller reverts, zero allowances, balances, v2 parity). CI run URL in `ci-log.txt` / `ci-links.md`.
* **CI heavy job** (`ci/run.sh`): bytecode verification (both impls match after immutable patch + metadata strip), live-state dump, tx/approval census → `ci-out/`.
* **History census (local, Etherscan V2):** v1 lifetime txs = 450: 363 `requestWithdraw`, 24 `batchFlushWithdrawals`, 8 `batchTogglePendingWithdrawal`, 23 `grantRole`, 14 `revokeRole`, 15 `addToken`, 1 `addValidators`, 1 dust ETH transfer. **0 `executeExpiredPendingWithdrawal`, 0 `withdrawFees`, 0 `rebalanceWithdraw`, 0 `toggle`, 0 `depositOnBehalf`, 0 non-privileged calls.** Full per-tx JSON: `analysis/vault_txs.json`.

---

## 7. Verdict

* **E-U: $0.00 (high confidence).** The signature binding is complete; the permissionless crank is value-neutral; there are no live allowances; there is no pricing/accounting logic to manipulate. The finding's hypothesis ("if signature binding is loose… forging a withdrawal is unprivileged") is **disproven** for this deployment.
* **Residual risk is key custody, not code** — the AFX-class risk. Today's in-contract exposure is $127,357.05 (v1) + $12.82 (v2); the $50M sits in plain custody EOAs whose only protection is key management (DL: "third-party qualified-custodian wallets"; the site lists Cobo among partners; the vault signers use AWS KMS).
* **Re-arm conditions to monitor:** (1) any change to the v1 impl (UPGRADE event) — a weakened verifier would make the vault drainable; (2) `addValidators` (a new lower-threshold or attacker-keyed set would be accepted by any operator submission); (3) any deposit/refill of the vault (exposure grows, still gated); (4) unpause of the 8 stale withdrawals → public crank pays $2,704.80 to recorded receivers; (5) v2's single-EOA admin key.

---

## 8. Methodology, sources, caveats, files

**Methodology:** verified source pulled from Etherscan V2 (both impls + proxy), diffed against the project's GitHub repo; deployed bytecode compared to a local solc 0.8.25 compile (CI); full event/tx census via Etherscan V2; role/state/balance reads via public RPCs at recorded blocks; validator powers brute-forced against the on-chain `keccak256(abi.encode(validators))`; unit + fork PoC in GitHub Actions (public repo, keyless artifacts).

**Sources:** Etherscan V2 API; public RPCs (`arbitrum-one-rpc.publicnode.com`, `ethereum-rpc.publicnode.com`, `bsc-rpc.publicnode.com`, `rpc.berachain.com`); DefiLlama (`api.llama.fi/protocol/azverse`, adapter `projects/azverse/index.js`); project repos `AZVerses/asset-vault-contracts`, `AZverse/asset-vault-signer`; news for the AFX-Trade precedent (Coindesk/Blockaid, 2026-07-23).

**Caveats:** (1) point-in-time reads — re-verify before acting; (2) custody-wallet key management is not observable on-chain (EOA ≠ necessarily a single key; could be MPC); (3) the BTC figure is DefiLlama's, not independently re-read; (4) DL's adapter counts only the v1 vault + custody wallets — the v2 vault (busier) is not counted; (5) the CI runner had an empty `ARB_RPC_URL`/`ETHERSCANV2_API_KEY` secret, so CI uses public Arbitrum RPCs and the tx census ran locally (public data).

**Files index:**
* `analysis/src/` — full verified source bundle (AssetVault + OZ v5.6 + proxy)
* `analysis/logs_*.json` — all vault events (roles, tokens, validators, withdrawals, toggles)
* `analysis/all_withdrawals.json`, `analysis/unexecuted_withdrawals.json`, `analysis/vault_txs.json` — withdrawal + tx census
* `analysis/valuation.json` — USD table with prices/timestamps
* `analysis/parse_*.py`, `analysis/fetch_logs.py`, `analysis/read_*.sh` — reproducible scripts (keyless)
* `poc/` — Foundry project (unit + fork tests) · `ci/` — heavy job (bytecode verify, state dump, census)
* `ci-out/`, `ci-log.txt`, `ci-artifacts/` — CI evidence · `summary.json` — machine-readable summary
