# Startale ERC-7579 — re-callable `initializeAccount` via EIP-1153 (re-check)

**Date:** 2026-11-03 · **Chain:** Ethereum mainnet · **Status:** read-only; PoC fork-verified only; **no mainnet transaction was signed or sent**.
**Prior verdict (CA2, 2026-11-02):** HIGH bug, demoted to LOW — "bounded to pending pre-funding", historical total $2,876.
**This re-check:** the code is **still re-callable today** (byte-identical to the exploited build), and the value is now **measured**, not assumed: the entire pre-funding flow over the last 200,000 blocks is **$155.15 gross** (28 days), with a **$4.58 maximum single event**.

> **Name disambiguation.** `startale-earn/` in this workspace is **Startale Earn** — a *different*
> contract (a yield vault, cited at $92.12/day per $1M). It is **not** this finding and was not touched.
> This finding is the **Startale ERC-7579 smart-account implementation** `0x000000b8f5…E05A`.

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why open/closed | Latent risk |
|---|---|---|---|
| Startale `StartaleSmartAccount` impl `0x000000b8f5f723A680d3D7EE624Fe0bC84a6E05A` + factory `0x0000003B3E7b530b4f981aE80d9350392Defef90` | **$0.00** steady-state net. Documented ceiling **$155.15 / 27.8 days** gross; **$4.58** max per event | Code **still exploitable** (3/3 fork tests). Value is gas pre-funding only: 50 of 434 recent accounts held ETH at `block-1`; **1** held tokens ($11.95 USDC). Attacker must win the deployment race and out-spend ~$0.15 gas per event | **Re-arms instantly** if a distribution/airdrop sends real value to not-yet-deployed counterfactual accounts (that is exactly what the Sept-2026 $2,876 exploit was: 330 accounts × ~$8.7 USDC/USDT) |

**Total live extractable now: $0.00** (confidence **high** on the code path; **medium** on the absolute ceiling because the public mempool cannot be enumerated).

---

## 2. The bug, in exact terms (re-read from the live verified deployment)

`AccountProxy` constructor (`src/utils/AccountProxy.sol`):

```solidity
constructor(address implementation, bytes memory data) payable {
    Initializable.setInitializable();                      // tstore(INIT_SLOT, 1)
    ERC1967Utils.upgradeToAndCall(implementation, data);   // delegatecall initializeAccount(initData)
}
```

`Initializable` (`src/lib/Initializable.sol`) uses **EIP-1153 transient storage**, which is scoped to the
**transaction**, not to the constructor frame:

```solidity
function setInitializable() internal { bytes32 slot = INIT_SLOT; assembly { tstore(slot, 0x01) } }
function requireInitializable() internal view { ... tload(slot) ... revert NotInitializable() }
```

`StartaleSmartAccount.initializeAccount` (`src/StartaleSmartAccount.sol:293`) has **no** `isInitialized`,
`ownerCount` or "already initialized" guard — the only gate for an external caller is that transient flag:

```solidity
function initializeAccount(bytes calldata initData) external payable virtual {
    if (msg.sender != address(this)) { Initializable.requireInitializable(); }
    _initializeAccount(initData);   // -> bootstrap.delegatecall(bootstrapCall)
}
```

Because the flag set inside the proxy constructor survives until the end of the **transaction**, any caller
can invoke `initializeAccount(attackerInitData)` a **second time in the same transaction** as the account's
deployment. `_initializeAccount` delegatecalls an attacker-supplied `bootstrap`, i.e. arbitrary code in the
account's context, and the account's balance is swept.

The factory is permissionless and deterministic
(`createAccount(bytes initData, bytes32 salt)` → `CREATE2(AccountProxy, salt, keccak(creationCode, impl, initializeAccount(initData)))`),
so an attacker who sees a pending deployment (or acts as the bundler) can reproduce the address, deploy it
first, and re-initialize it in the same transaction.

**This is the same primitive DefiLlama describes for the 2026-09-16 incident:** *"…an initialization
authorization flag stored with transient storage remained set for the entire transaction. The attacker could
therefore deploy a victim's pre-funded account and reinitialize it again in the same transaction with a
malicious bootstrap, allowing its assets to be swept."* ExVul's contemporaneous thread reports ~$2,876 in
USDC+USDT taken from ~330 pre-funded accounts.

---

## 3. Live state (all reads at Ethereum block **26,334,697**, 2026-11-03)

| Check | Value | Method |
|---|---|---|
| Implementation `0x000000b8f5…E05A` | **24,399 bytes**, runtime keccak `0x90713de6…50ca67` | `eth_getCode` + `cast keccak` |
| Same runtime at the exploit block 25,986,306 (2026-09-16) | `0x90713de6…50ca67` — **identical → unpatched** | archive `eth_getCode` |
| Factory `0x0000003B…ef90` | 2,929 bytes, keccak `0x380e804e…5b4797`; `ACCOUNT_IMPLEMENTATION()` = the impl | `eth_getCode` / `eth_call` |
| `initializeAccount(bytes)` selector | `0x4b6a1419` present; `TSTORE 0x5d` / `TLOAD 0x5c` present | bytecode scan (prior + this pass) |
| Deployments in last 200,000 blocks | **434** `AccountCreated` events (26,134,433 → 26,334,433); burst 26.25M–26.29M = 409 | Etherscan `getLogs` (topic `0x47e5b5fc…`) |
| Recent rate | 11 accounts in the last 14,400 blocks ≈ **5.7/day** | same |
| ETH pre-funding at `creationBlock-1` | **50 / 434** accounts; **0.06250548 ETH total**; **0.002 ETH max** | `eth_getBalance` at historical block (archive) |
| USDC/USDT pre-funding at `block-1` | **0** across 434 (verified by both `balanceOf@block-1` and full `tokentx` history) | `eth_call` + Etherscan `tokentx` |
| Any-token pre-funding before creation | **1 / 434**: `0x310a54ed…0dec` held **11.951842 USDC** from block 25,587,225 until its deployment at 26,321,953 | `tokentx` net-of-flows |
| Current residual balances | 13 accounts hold **0.01495295 ETH ($34.26)**; all 13 `isInitialized() == true` (user accounts, not stuck) | `eth_getBalance` + `isInitialized()` |
| ETH/USD | **$2,290.97** (Chainlink `0x5f4eC3Df…8419`, same block) | `latestAnswer()` |

**Value measured, not inferred:** over 27.8 days the *entire* sweepable pre-funding pool on this factory was
**$143.20 of ETH + $11.95 of USDC = $155.15 gross**, with a **$4.58** largest single event. Gas for the
capture transaction (deploy + re-init + sweep, ~300–400k gas at the live 0.164 gwei base fee) is ≈ **$0.15**
per event, so the theoretical net is ≈ **$4.9/day** *only if the attacker wins every single deployment race*.
In practice most of these deployments are gas-prefunded userOps whose prefund is consumed by the EntryPoint;
an attacker who front-runs denies the userOp and keeps the residual.

---

## 4. What an attacker can and cannot do

**Can (proven on a fork, at head):**
1. Call `factory.createAccount(initData, salt)` (permissionless) for any not-yet-deployed account.
2. In the **same transaction** call `account.initializeAccount(evilInitData)`; the transient flag set by the
   `AccountProxy` constructor is still 1.
3. `evilInitData` delegatecalls an attacker bootstrap in the account context → sweep ETH/tokens.

**Cannot:**
- Re-initialize an account **after** the deployment transaction — the transient flag is gone. Verified:
  `initializeAccount` on a live account (`0x8BAf151C…2fDCb`) reverts `NotInitializable()` (`0xaed59595`).
- Sweep accounts whose `initData`/`salt` it cannot reconstruct (all observed salts are 0 and `initData` is
  standard, so in practice a pending userOp or a published counterfactual address is enough).
- Extract more than what is sitting at a not-yet-deployed counterfactual address at that instant.

**Preconditions / costs:** win the race (or be the bundler) for a deployment whose counterfactual address is
already funded; pay ~$0.15 gas; the reward is the residual pre-fund. No keys, roles, capital or flash loan.

---

## 5. PoC / fork verification

`poc/` (Foundry, `solc 0.8.24`, `evm_version = cancun`) — **3/3 PASS** locally and in CI:

| Test | What it proves |
|---|---|
| `test_code_unchanged` | live factory/impl keccak equals the constants; factory points at the impl |
| `test_post_tx_reinit_reverts` | a live, already-deployed account reverts `NotInitializable()` — the window is tx-scoped |
| `test_same_tx_reinit_sweeps_prefund` | full attack: real factory + real impl + a **real `initData` taken from an on-chain deployment**; the account is pre-funded with 0.002 ETH (the observed max), deployed and re-initialized in one tx; attacker receives the full pre-fund, account balance 0 |

The PoC uses a **fresh salt** (`keccak256("ca2-startale-poc-1")`) so it runs at head without archive state.
`test_same_tx_reinit_sweeps_prefund` asserts `acct.balance == 0` and `attacker.balance - before == 0.002 ether`.

CI: `bash /home/heisenberg/CA/ci/ci-run.sh startale-7579` → run URL in `ci-log.txt` / `ci-artifacts/`.

---

## 6. Verdict and residual risk

**Verdict: live bug, not live money. E-U = $0.00 (steady-state net); measured gross ceiling $155.15 / 27.8 days, $4.58 per event. Confidence high.**

Reconciliation with the prior verdict: **CA2 was right to demote it, and right about the mechanism; the
"pending pre-funding" bound is now quantified.** The prior pass said "no evidence of any current >$10k
exposure" without measuring; this pass measures the whole 200k-block cohort and confirms it (max $4.58).

**Re-arm conditions (any one flips this to material E-U):**
- A distribution / airdrop / batch payout sends value to **not-yet-deployed** Startale counterfactual
  addresses (the September event: 330 accounts × ~$8.7). This is the realistic trigger and it has happened once.
- Any integration publishes a counterfactual address and asks users to pre-fund it before deployment.
- A user pre-funds a new account with more than gas (e.g. a first deposit) before the deploy userOp lands.

**Blockers / limits:** the public mempool is not enumerable from a standard RPC, so "pending" value is
bounded by the empirical flow, not measured directly; the historical $2,876 was corroborated from DefiLlama +
ExVul but not independently re-derived on-chain (the 330 victim accounts were not enumerated); the recent
434-account cohort is dominated by what looks like protocol load-testing (0.01 USDC round-trips), so the
steady-state rate for *real* users may be lower than 5.7/day.

---

## 7. Methodology & files

Read-only: `eth_getCode`, `eth_getStorageAt`, `eth_call`, `eth_getBalance` at historical blocks, Etherscan V2
`getLogs`/`tokentx`/`getsourcecode`, Chainlink on-chain prices. Fork PoC in Foundry (CI). No keyed URL or key
is written to any file.

```
startale-7579/
├── README.md
├── summary.json
├── analysis/
│   ├── accountcreated_logs_*.json      # raw AccountCreated logs (200k blocks)
│   ├── prefund_scan.py / .json         # ETH pre-funding at creationBlock-1 for all 434
│   ├── prefund_scan_tok.json           # token transfers before creation
│   ├── tokentx_scan.py
│   ├── real_initdata_from_tx_0x335eabbc.hex   # real initData used by the PoC
│   └── live_state.py                   # reproducible live-state dump
├── poc/                                # Foundry project (vendored forge-std)
├── ci/run.sh · ci-out/ · ci-log.txt
```
