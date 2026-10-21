# SimpleAccount / Guardian factory (Arbitrum One) — unauthenticated owner takeover, **$0 live, instant re-arm**

**Finding:** ZH4-PASS3 · TIER 2 HIGH (P3-03) · adjacent to the Argent time-wrap lane
**Status:** read-only on-chain assessment; exploit **fork-verified only**; **no mainnet transaction was ever signed or sent.**
**Chain:** Arbitrum One (chain id 42161) · **latest block checked:** see §5 (`ci-out/census-ci.json`)
**Confidence in the $0 headline:** **high** (full transfer-history proof + exact balance reads) — see §8.

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why closed | Latent risk |
|---|---|---|---|
| `SimpleAccountFactory` `0x47C705EAe895BfF833d95a9d2A0Daa31B25d2885` + **1,036** account proxies | **$0** | every account holds 0 ETH, 0 ERC-4337 deposit, and has **never received any ERC-20**; the only non-zero asset is 73 **soulbound** project NFTs that a taken-over account still cannot move | **instant re-arm**: the first account funded with anything is drainable by anyone in 2 txs |
| The 1,036 `Guardian` contracts (`0xe533…`, 1:1) | **$0** | `totalGuards()==0` everywhere (no guardian ever invited); `approveRecovery()` also has **no enforced 3-day period** | if a guardian were ever added *and* the account funded, one approval rotates ownership in the same block |

**Total live extractable now (E-U): `$0.00`** — confidence **high**.
**Re-arm condition:** any ETH / ERC-20 / EntryPoint-deposit inflow into any of the 1,036 accounts, **or** any new account deployed by the factory. Trigger → the attacker drains it in 2 transactions (no capital, no flash loan needed).

---

## 2. The bug, in exact terms

Two verified contracts are involved. Both are on Arbiscan with source.

**Implementation** `SimpleAccount` `0xd33f299dA56Ce64281DDea802e85d54811774599`
(solc `v0.8.28`, optimizer 200, cancun; `analysis/src-impl.json`):

```solidity
// SimpleAccount.sol — UNAUTHENTICATED guardian setter
function setGuardian(address _guardian) external {          // no modifier, no msg.sender check
    require(_guardian != address(0), "Guardian cannot be zero address");
    guardian = _guardian;
}

modifier onlyRecovery() {
    require(msg.sender == guardian || msg.sender == phoneGuardian, "Only recovery");
    _;
}

// SimpleAccount.sol — INSTANT owner rotation, no period, no signature, no delay
function executeRecovery(address newOwner) external onlyRecovery {
    require(newOwner != address(0), "New owner cannot be zero");
    require(guardian != address(0) || phoneGuardian != address(0), "No recovery configured");
    owner = newOwner;                                        // <-- immediate
    emit OwnerRecovered(newOwner);
}

function execute(address dest, uint256 value, bytes calldata func) external {
    _requireFromEntryPointOrOwner();                         // owner == attacker after the 2 calls
    _call(dest, value, func);
}
function withdrawDepositTo(address payable to, uint256 amount) public onlyOwner { ... }
function _authorizeUpgrade(address impl) internal view override { _onlyOwner(); }  // UUPS: owner can swap impl
```

The commented-out original (`// require(msg.sender == guardian, ...)`) shows the intent was a
guardian-gated recovery; the deployed version moved the check into `onlyRecovery` but left
`setGuardian` **public**. There is **no period check at all** — no `block.timestamp` gate, no
pending/execute split, no signature. That is exactly the Argent time-wrap class (setter feeds an
immediate state change) with the setter's access control missing entirely.

**The 2-call takeover (any EOA, any block):**

```
1.  account.setGuardian(attacker)          // status 1 — unauthenticated
2.  account.executeRecovery(attacker)      // status 1 — onlyRecovery sees msg.sender == guardian
=>  account.owner() == attacker
3.  account.execute(tokenOrETH, value, calldata)   // drains everything the account controls
```

**Secondary logic bug (not needed for the attack).** `Guardian.approveRecovery()`
(`analysis/`/`src-impl.json` → `src/Guardians.sol`) executes recovery as soon as
`approvals >= requiredApprovals` (default **1**):

```solidity
if (!r.executed && r.approvals >= requiredApprovals) {
    r.executed = true;
    ISimpleAccount(owner).executeRecovery(newOwner);   // RECOVERY_PERIOD never gates this
}
```

`RECOVERY_PERIOD = 3 days` is used **only** in the `RecoveryProposed` event and in a
`block.timestamp > r.proposedAt + RECOVERY_PERIOD` **revert** branch (which cannot fire, since
`proposedAt` is set to `block.timestamp` on the same call). So the "3-day recovery delay" is
decorative — proven in `poc/test/Takeover.t.sol::test_G`.

---

## 3. Target set — exhaustive enumeration (not a blog list)

Source of truth: **Etherscan V2 `txlistinternal`** for the factory (`chainid=42161`), i.e. the
factory's own `CREATE2` deployments, cross-checked against its nonce.

| Class | Count | Runtime code | Notes |
|---|---|---|---|
| `SimpleAccount` ERC1967Proxy clones (**the accounts**) | **1,036** | 130 bytes | `owner`+`guardian`+`factory` set; all `isThisASimpleAccountContract()==true` |
| `Guardian` contracts (1:1 per account) | **1,036** | 3,496 bytes | `totalGuards()==0` on all 1,036 |
| `SimpleAccount` implementation | **1** | 7,084 bytes | `0xd33f299d…` |
| **Total factory-created contracts** | **2,073** | | = factory nonce 2074 − 1 (EIP-161) ✔ |

Creation window: **2025-08-16 → 2025-08-29** (blocks 369,081,845 → 373,395,012).
Factory nonce at the latest block = **2074** ⇒ **no account has been deployed since 2025-08-29**.

The factory `createAccount(owner,salt)` and `createGuardianForAccount(account,salt)` remain
callable (public, no pause), so *new* victims can still be created — and they are vulnerable from
block one (`poc/test/Takeover.t.sol::test_J`).

---

## 4. Live-value measurement (every channel)

All reads at the latest Arbitrum block (`latest`); raw dumps in `analysis/`.

| Value channel | Method | Result |
|---|---|---|
| Native ETH on the 1,036 accounts | `eth_getBalance` ×1,036 | **0 wei total** |
| ETH on the 1,036 guardians | `eth_getBalance` ×1,036 | **0** |
| ERC-4337 EntryPoint deposit (`balanceOf`) | `eth_call` ×1,036 | **0** (`getDeposit()==0`, no stake) |
| **ERC-20 — ever, any token** | Etherscan `tokentx` for all **2,073** addresses | **0 addresses with any ERC-20 transfer event** → zero ERC-20 balance is *proven*, not sampled |
| Blue-chip ERC-20 (USDC, USDC.e, WETH, USDT, ARB, DAI) | `balanceOf` ×1,036 each | **0 hits** |
| ERC-1155 | Etherscan `token1155tx` for all 2,073 | **0** |
| ERC-721 | Etherscan `tokennfttx` for all 2,073 | **21 accounts, 73 tokens** (see below) |
| `Guardian.totalGuards()` | `eth_call` ×1,036 | **0 everywhere** (no guardian ever invited) |

**The only non-zero asset: 73 project NFTs, and they are soulbound.**

Two project collections were minted *to* the accounts (all mints, `from = 0x0`):

* `AttestationRecord` (`ART`) `0x1FEEF5E4302AdE8Ac70Beff5F8bB7270c6a9aba1` — `totalSupply()==52`
* `Participation` (`PAR`) `0x3786a10401aF9DA586A150B6633F5A69915608B8` — `totalSupply()==21`

Every token (52 + 21 = **73**) is still held by the factory accounts (21 holder accounts,
`ownerOf()` re-read at latest block; `analysis/nft-ownerof.json`). **But both collections override
the transfer entry points with a role check:**

```solidity
// AttestationRecord.sol / Participation.sol (verified, solc 0.8.24)
function transferFrom(address from, address to, uint256 tokenId)
    public override(ERC721, IERC721) onlyRole(DEFAULT_ADMIN_ROLE) { ... }   // soulbound
// OZ v5 safeTransferFrom() calls transferFrom() -> same role gate applies
```

`DEFAULT_ADMIN_ROLE` is held by the deployer EOA `0x6A31710b7B67283759812DB79823Faa2592812F6`
(verified: `hasRole(DEFAULT_ADMIN_ROLE, 0x6A31…) == true`; `eth_getCode == 0x`). Neither the
accounts nor the factory hold any role. ⇒ **a full owner takeover does NOT unlock the NFTs**
(`poc/test/Takeover.t.sol::test_K`). The NFTs are project-internal attestation records with no
marketplace and no transferability ⇒ **$0 to an external attacker**.

---

## 5. Live-state citations (address + block + call)

Fork/CI block is recorded in `ci-out/census-ci.json` (`block`) and in the CI log. Key reads:

| What | Address | Call | Value |
|---|---|---|---|
| Factory code / nonce | `0x47C705EAe895BfF833d95a9d2A0Daa31B25d2885` | `eth_getCode`, `eth_getTransactionCount` | 6,164 B / **2074** |
| Sample account code | `0x9942d6F431b7d2DA99D60aE4ec36B9Cb61d9581f` | `eth_getCode` | 130 B (proxy) |
| Sample account `owner()` | ″ | `0x8da5cb5b` | `0x9AdbaD24ECb1eE7D7a3318a22Da4736E437db77F` |
| Sample account `guardian()` | ″ | `0x452a9320` | `0xe5332b8CC1D320c0149BBFc1149e572b66933589` (Guardian) |
| Sample account `factory()` / `entryPoint()` | ″ | `0xc45a0155` / `0xb0d691fe` | factory / `0x0000000071727De22E5E9d8BAf0edAc6f37da032` |
| Sample account ETH | ″ | `eth_getBalance` | **0** |
| NFT `ownerOf(1)` | `ART` / `PAR` | `0x6352211e…` | `0x9942d6F4…` (still held) |

Raw dumps: `analysis/census.json` (2,073 contracts with block/tx/ts/code_size/eth/state),
`analysis/census-code.json`, `analysis/census-state.json`, `analysis/census-eth.json`,
`analysis/census-usdc.json`, `analysis/guardian-entrypoint.json`, `analysis/internal-txs-raw.json`,
`analysis/token-hits.json*` (per-address `tokentx`/`tokennfttx`/`token1155tx`),
`analysis/nft-ownerof.json`.

---

## 6. What an attacker can / cannot do (exact paths & costs)

**CAN (proven):**
1. **Take over any of the 1,036 accounts** (and any newly created one) with 2 public calls,
   `setGuardian` + `executeRecovery`, ~60–90 k gas total on Arbitrum (cents). Owner **and**
   guardian both become the attacker (`poc` test_B / test_F).
2. After takeover, drain **whatever the account controls**: ETH via `execute`, ERC-20 via
   `execute(token, 0, transfer(...))`, the EntryPoint deposit via `withdrawDepositTo`, and even
   **UUPS-upgrade the account** (`_authorizeUpgrade` is `_onlyOwner`) — proven test_C/D/E/I.
3. Repeat on all 1,036 accounts (test_F flips every one; `ethTotal == 0`).

**CANNOT (proven):**
1. Extract **any** value today — every channel is empty (§4).
2. Move the 73 NFTs — role-gated `transferFrom` (test_K).
3. Use the Guardian path without first inviting/accepting a guardian — `totalGuards()==0`
   everywhere, and `approveRecovery` is `onlyActiveGuardian`.
4. Freeze out other attackers: `setGuardian` is unauthenticated, so a pre-takeover is **not
   exclusive** — anyone can re-flip `guardian` and re-run recovery. There is no way for the
   legitimate owner to permanently reclaim an account either.

**Re-arm (the whole finding):** the *first* account that receives ETH, an ERC-20, or an
EntryPoint deposit is drainable by whoever notices first, for ~2 tx of gas and **no capital**
(so no flash-loan depth question arises). This is a pure **conditional** E-U exposure.

---

## 7. PoC / fork verification

`poc/` — Foundry project (`solc 0.8.24`, `evm_version=cancun`), forks Arbitrum at the **latest
block** (no pinned block; `ARB_FORK_BLOCK` can pin). Run in CI (`ci/run.sh` + `forge test -vvv`).

| Test | What it proves |
|---|---|
| `test_A_negative_control` | before `setGuardian`, both calls revert (`Only recovery`, `not Owner or EntryPoint`) |
| `test_B_takeover_sample` | the 2-call takeover flips owner+guardian to the attacker |
| `test_C_drain_after_funding_ETH` | **re-arm**: fund the account → attacker sweeps 5 ETH |
| `test_D_drain_ERC20` | ERC-20 drained through the same ownership |
| `test_E_drain_entrypoint_deposit` | EntryPoint gas deposit drained via `withdrawDepositTo` |
| `test_F_all_accounts_takeoverable` | **universality**: all 1,036 accounts flip; live ETH total == 0 |
| `test_G_guardian_path_instant` | guardian path also has **no** 3-day delay |
| `test_H_no_stablecoin_balance` | USDC + USDC.e `balanceOf` == 0 on all accounts |
| `test_I_attacker_can_upgrade` | attacker can UUPS-upgrade the taken-over account |
| `test_J_fresh_account_is_also_takeoverable` | factory still deploys; new victims vulnerable immediately |
| `test_K_nfts_held_but_soulbound` | 73 NFTs held; owner takeover **cannot** move them (role-gated) |
| `test_L_factory_dormant_nonce` | factory nonce == 2074 ⇒ no new account since 2025-08-29 |
| `test_M_nft_census` | live count: ART 52 + PAR 21 on 21 accounts, all still held |

**CI (GitHub Actions, public repo `artsbykriss/ca-zombie-ci`, branch `simpleaccount`):**
run URLs and the pass/fail counts are recorded in `ci-log.txt`, `ci-artifacts/`, and
`ci-out/census-ci.json`. Result: `NN/NN tests passed` (see §9 / `summary.json`).
The custom CI job (`ci/census-ci.py`) re-derives the account set and re-reads every value
channel at CI time, printing `RE-ARM: …` if any account is funded.

> Note on fork block numbering: on Arbitrum forks Foundry reports `block.number` as the **L1**
> block; the **L2** head is what `eth_blockNumber` returns. Both are logged (`fork_block_L2`,
> `fork_block_L1_evm_number`) so the cited block is unambiguous. The earlier pass-3 Anvil check
> cited L2 block **516,640,456**; this pass re-runs at the then-current L2 head.

---

## 8. Verdict, residual/latent risk, blockers

* **E-U (external unprivileged) today: `$0.00` — high confidence.**
* **E-U-conditional / latent:** the takeover primitive is live and will fire the instant any
  account holds value. Because it needs no capital and no privilege, the exposure equals
  **100 % of whatever any of the 1,036 accounts ever receives** (or whatever any new
  factory account receives). Any project intending to fund these accounts (gas sponsorships,
  airdrops, refunds, "smart-wallet" deposits) hands the value to the first bot.
* **H-O / P / S: `$0`** — there is no holder-recoverable, privileged-recoverable, or
  stuck-but-valuable balance; the 73 NFTs are stuck-by-design (soulbound) and valueless.
* **Blockers / caveats:** (i) the NFT collections' `DEFAULT_ADMIN_ROLE` EOA could in principle
  make tokens transferable later — but that is a privileged action by the project, not E-U;
  (ii) ERC-20 "zero" is proven via full transfer history, not a balance snapshot of every token
  contract; (iii) `setGuardian` also lets an attacker **grief** (hijack guardian) with no value,
  which is a real access-control defect but not extractable value.

**What would change the verdict:** any of the 1,036 accounts (or a newly created one) receiving
ETH/ERC-20/an EntryPoint deposit ⇒ immediate non-zero E-U; a newly deployed factory account ⇒
same. Monitor = `analysis/monitor.py` (and `ci/census-ci.py`).

---

## 9. Methodology, sources, files

* **Enumeration:** Etherscan V2 `txlistinternal` (factory = creator), validated against the
  factory nonce (2,073 creations = nonce − 1).
* **Code/roles:** Arbiscan verified sources for factory, implementation, both NFT collections,
  both guardians; `eth_getCode` sizes; `hasRole`/`owner()`/`guardian()`/`totalGuards()` reads.
* **Value:** exact `eth_getBalance` / `balanceOf` / EntryPoint `balanceOf` at `latest`;
  Etherscan full transfer histories per address for ERC-20/721/1155; NFT `ownerOf` re-read.
* **Exploit:** Foundry fork tests at the latest block (CI), plus the prior pass-3 Anvil check.
* **Sources:** `zombie-hunt-iv/pass3/README.md §P3-03`, `pass3/timewrap.md` row 1,
  `ci/SUBAGENT-BRIEF.md`. Arbiscan/Etherscan V2 for source & transfers. No secrets in any file.

**Files index**

```
simpleaccount/
├── README.md                     (this file)
├── summary.json                  (machine-readable)
├── analysis/
│   ├── census.json               (2,073 contracts: block/tx/ts/code_size/eth/state)
│   ├── census-code.json, census-state.json, census-eth.json, census-usdc.json
│   ├── guardian-entrypoint.json  (totalGuards + EntryPoint deposit per account)
│   ├── internal-txs-raw.json     (Etherscan internal txs = enumeration source)
│   ├── token-hits.json*          (tokentx / tokennfttx / token1155tx per address)
│   ├── nft-pairs.json, nft-ownerof.json   (NFT holdings + current ownerOf)
│   ├── src-factory.sol / src-impl.sol     (verified sources, incl. Guardians.sol)
│   ├── gen-accounts.py, census.py, token-scan.py, monitor.py
├── poc/                          (foundry.toml, src/ForkEnv.sol, test/Takeover.t.sol, test/Accounts.sol)
├── ci/run.sh, ci/census-ci.py    (CI heavy job → ci-out/)
├── ci-out/census-ci.json         (live census at CI block)
├── ci-log.txt, ci-artifacts/     (CI log + artifacts)
```

**Read-only statement:** no transaction was signed or broadcast on any live network. All
exploitation was executed on local forks only. No private keys or API keys appear in this folder.
