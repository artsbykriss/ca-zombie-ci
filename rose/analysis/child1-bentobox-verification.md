# Child1 — VASE vs BentoBox V1: fork verification + live permissionless-path audit

**Auditor:** child1 subagent (Rose/Aurora deep-dive) · **Date:** 2026-10-13 (UTC)
**Scope:** `/home/heisenberg/CA/rose/analysis/` · read-only, public keyless RPC only (no secrets, no transactions).

---

## 0. Verdict summary

1. **"Verbatim fork of BentoBox V1, strings-only difference" — REFUTED.**
   The VASE (`0xee793001Ce9Fa988712B15a59CCf5dC7d54b22FF`, Aurora) is byte-identical to the live Ethereum BentoBox V1
   (`0xF5BCE5077908a1b7370B9ae04AdC565EBd643966`) across **all business logic** except:
   - **one semantic change**: `setStrategy()`'s queue branch computes `strategyStartDate = block.timestamp` —
     the `+ STRATEGY_DELAY (2 weeks / 0x127500)` term is **absent** (5 bytes). The 2-week strategy timelock is gone.
   - three keccak constants renamed: domain name `"BentoBox V1"` → `"Vase"`, and the two approval-warning
     strings `…BentoBox?` → `…Vase?` (invisible at ASCII/string-table level; only the hashes differ).
   - `"BentoBox: "` → `"Vase: "` in 9 revert messages (as the parent found) — plus **~90 bytes of
     solc-generated ABI-decoder helper code whose call-vs-inline factoring differs** (net −9 bytes).
     These helper regions were reviewed instruction-by-instruction and differentially tested;
     they are calldata↔memory copy/bounds-check code with no state-changing opcodes
     (no `SSTORE/CALL/DELEGATECALL/CREATE/LOG/SELFDESTRUCT`). I could not reproduce them with any
     solc 0.6.12 setting I tried (native + WASM builds, runs 1…2³²−1, evmVersion, optimizer details,
     revertStrings, batch public/memory variants). **Cause unresolved; semantic impact: none found.**
2. **Permissionless value extraction from the live VASE today: $0.**

| metric | value |
|---|---|
| Aurora state block | **219,872,980** (code hash identical at 219,867,439 and 219,872,980) |
| `owner()` / `pendingOwner()` | `0x0e2a05ca5d1e218034f2b7deb6e9419159839f8b` (EOA, 0-byte code) / `0` |
| tokens with `excess = balance − totals.elastic ≠ 0` | **none** (12 tokens checked; all 7 funded tokens excess = 0) |
| strategies / pendingStrategy / strategyData.balance | all zero for every token |
| native ETH balance of VASE | 0 |
| whitelisted master contracts | exactly **one**: `0x857050Ef…AEd93` (GardenMaster), block 62,781,704, never revoked |
| approvals (`masterContractApproved`) | 175 events / **174 users**, all → GardenMaster, all `approved`, **no revocations** |
| probes that would extract value | **all revert** (see table §4) |

---

## 1. Method, scripts and exact evidence files

All scripts are saved in this folder; all raw JSON evidence as well. Read-only public RPCs:
`https://mainnet.aurora.dev` (Aurora) and `https://ethereum-rpc.publicnode.com` (Ethereum);
event logs via `https://explorer.aurora.dev/api/v2` (Blockscout MCP does not support channel 1313161554).

| file | purpose |
|---|---|
| `child1_fetch.py` → `child1_bytecodes.json` | fetch both deployed bytecodes + block numbers + SHA-256 |
| `child1_explore.py` | metadata tails (solc CBOR), ASCII strings, prefix/suffix |
| `child1_diff.py` → `child1_diff.json`, `child1_diff_report.txt` | unique-16-mer anchor alignment of the two bodies |
| `child1_disasm.py`, `child1_aligned.py` | linear EVM disassembler + phase-corrected disassembly |
| `child1_compile.py` | reconstruct flat source from Etherscan bundle, compile with solc 0.6.12 (`runs=999999`) |
| `child1_compare.py` | compiled-vs-live comparison with immutable slots + metadata masked |
| `child1_gapdiff.py`, `child1_align.py` → `child1_align_report.json` | diff categories; instruction-level alignment |
| `child1_sourcemap.py` | solc source maps (used to localize regions) |
| `child1_scan.py`, `child1_scan2.py`, `child1_solcjs.js`, `child1_wasm_vase2.json` | compiler-settings scan (native + WASM builds) |
| `child1_state.py` → `child1_state.json`, `child1_state_raw.json` | live VASE state at one block |
| `child1_paths.py` → `child1_paths.json` | exploit probes with revert decoding |
| `child1_logs.py` → `child1_events.json` | whitelist/approval/deploy/register events |
| `child1_diffcall.py`, `child1_local.py` → `child1_diffcall*.json`, `child1_local_diff.json` | behavioral differential tests |
| `child1_share_matrix.json` | holder accounting matrix per token |

Key reproduction commands:

```bash
cd /home/heisenberg/CA/rose/analysis
python3 child1_fetch.py        # bytecodes + block numbers
python3 child1_compile.py vase2  # rename + STRATEGY_DELAY=0 + hash renames
python3 child1_align.py vase2 vase  # final diff classification
python3 child1_state.py        # live state at one Aurora block
python3 child1_paths.py        # exploit probes
python3 child1_logs.py         # events (explorer.aurora.dev)
```

### Toolchain validation (critical)
Etherscan-verified BentoBox source (flattened, 50,834 B) recompiled with
`solc 0.6.12+commit.27d51765`, optimizer enabled, runs `999999`, metadata ipfs —
after masking the 6 immutable slots (`immutableReferences`) and the 53-byte metadata:
**0 differing bytes vs the live Ethereum BentoBox** (`child1_compare.py original bentobox`).
This proves the toolchain reproduces the exact compiler output for this source.

---

## 2. Bytecode-diff evidence

### 2.1 Raw hashes / sizes (recorded)

| | VASE (Aurora) | BentoBox V1 (Ethereum) |
|---|---|---|
| address | `0xee793001Ce9Fa988712B15a59CCf5dC7d54b22FF` | `0xF5BCE5077908a1b7370B9ae04AdC565EBd643966` |
| fetch block | 219,867,439 | 26,186,234 |
| runtime size | 22,831 B (body 22,778) | 22,845 B (body 22,792) |
| sha256 | `0x69f60d0c76d17a96bf2b8fae298fc64b09d82da26a0c183f2863b30b7672a33f` | `0xeb25a902505c8f511d27e3cb547cd87f110aafc6ecb47abafb7c2ab8f494c2b3` |
| metadata (last 53 B) | ipfs `QmRGXzvNgzC56ES8YvNXHtkSLTZtiMq9C5fhfmdeynEYHw`, `solc 0.6.12` | ipfs `QmWYa55eFWQafrUNdruZqX73RJmDCGf9xV6LdizRMkCeXc`, `solc 0.6.12` |
| Aurora explorer | **not verified** — no source/ABI (`explorer.aurora.dev/api/v2/smart-contracts/…` returns only creation/deployed bytecode) | verified (Etherscan) |

Control: canonical BentoBox V1 deployments on Polygon/BSC/Gnosis are byte-identical to Ethereum
(same IPFS hash `79eb38…`), and Trisolaris's BentoBoxV1 on Aurora
(`0x4cA5dD575DacE76781C41cafe68281dfc4dF0038`) is also byte-identical to canonical. The VASE variant
is **not** a standard Aurora BentoBox build.

### 2.2 Diff budget (final: my reconstruction `vase2` vs live VASE)

Reconstruction `vase2` = canonical source with: `"BentoBox: "→"Vase: "` (12 source occurrences; 9 unique
messages), `keccak256("BentoBox V1")→keccak256("Vase")`, `"…BentoBox?"→"…Vase?"`,
`STRATEGY_DELAY = 2 weeks → 0`.

Both bytecodes linear-disassemble into **exactly 10,390 instructions**. Alignment result:

| category | count | detail |
|---|---|---|
| matching instructions | 10,205 | split over 145 exact blocks |
| SHIFT regions | 138 | every difference is a `PUSH2` jump-target whose delta (+3 ×93, −9 ×45) equals the local cumulative shift; **all targets land on `JUMPDEST` in both**; 0 exceptions |
| STRUCT regions (ABI helpers) | **5** | confined to two byte ranges: `[20054, 20144]` and `[22676, 22688]` (reconstruction offsets); net **−9 bytes**; opcode inventory: `ADD SUB MUL GT ISZERO CALLDATACOPY POP MSTORE JUMP JUMPI JUMPDEST PUSH1/2/32 DUP1-12 SWAP1-3 REVERT` only — **no SSTORE, no CALL/DELEGATECALL/STATICCALL, no CREATE, no LOG, no SELFDESTRUCT** |
| unexplained elsewhere | **0** | |

Net body length delta: 22,792 − 22,778 = **14 bytes = 5 (STRATEGY_DELAY) + 9 (ABI-helper factoring)**.

### 2.3 The semantic change (material finding #1): `setStrategy` timelock removed

`setStrategy()` queue branch, verified at offset 8453 by disassembly of both live contracts:

```
BentoBox (and my original recompile, identical):
8453: PUSH2 0x2112        ; return addr
8456: PUSH3 0x127500      ; 1,209,600 s = 2 weeks = STRATEGY_DELAY
8460: TIMESTAMP
8461: ADD                 ; timestamp + STRATEGY_DELAY
8462: PUSH2 0x43df
8465: JUMP                ; -> to64()

VASE (live):
8453: PUSH2 0x210d        ; return addr
8456: TIMESTAMP
8457: PUSH2 0x43da
8460: JUMP                ; -> to64(timestamp)   *** no +2 weeks ***
```

Effect (owner-only): the owner can `setStrategy` twice with the same arguments — including via `batch` in a
single transaction — and activate a strategy immediately (`require(block.timestamp >= strategyStartDate)`
passes at once), then `harvest(token, true, 0)` moves tokens to the strategy (up to 95% per call). Canonical
BentoBox forces a 2-week wait. **This is a real deviation from the claimed "verbatim fork".** It is not
permissionless (owner = live EOA `0x0e2a05ca…`), but it removes the main time-based defense against an
owner/operator rug.

### 2.4 Hash constants renamed (material for signature semantics)

| offset | canonical | VASE | preimage |
|---|---|---|---|
| 12341 | `b426802f…` | `e25df715…` | `keccak256("Revoke access to BentoBox?")` → `…"Revoke access to Vase?"` |
| 12379 | `422ac532…` | `2ee8d10e…` | `keccak256("Give FULL access to funds in (and approved to) BentoBox?")` → `…Vase?"` |
| 16764 | `d7df266a…` | `7e371a28…` | `keccak256("BentoBox V1")` → **`keccak256("Vase")`** |

Live `DOMAIN_SEPARATOR()` = `0x1369f98b2a4a6ba099548af2d9276453c8a16d1a8ab950f2f74c12d4d99ecc23`, which
**exactly matches** `keccak256(abi.encode(EIP712Domain-hash, keccak256("Vase"), 1313161554, VASE))`
(computed for names "BentoBox V1"/"Vase"/"Vase V1": only "Vase" matches). Domain binds chain-id + address →
no cross-chain signature replay from Ethereum/other BentoBoxes.

### 2.5 The ABI-helper regions (material finding #2, semantics-verified)

Three logical sites (5 alignment regions, `a_bytes`/`b_bytes` above): the solc-generated
"copy calldata to memory + zero pad" and "mstore+advance" helpers used by the ABI decoding of
`batch(bytes[] calldata, bool)`, `deploy(address, bytes calldata, bool)` and `batchFlashLoan`.
The canonical build **shares** these helpers (jump-call); the VASE build **inlines** them at one site.
Same operations, same order, same stack effects — different factoring. Evidence of equivalence:

* Cross-chain differential battery (`child1_diffcall.py`): live VASE vs canonical ETH BentoBox, identical
  crafted calldata (13 cases: empty/multiple `batch`, nested `batch`, unknown selector, non-multiple-of-32
  byte payload, malformed length/offset/huge length, `deploy` master 0/dead, `transferMultiple` empty `tos`).
  Result: **all interpretable cases identical** (success bytes equal; reverts equal modulo node wording and
  the `Vase:`/`BentoBox:` rename; the two apparent mismatches were (a) an embedded owner address from state,
  (b) my `from`-address test artifact — both re-verified equal: `InvalidFEOpcode`/`Ok(InvalidCode(254))` for
  empty-`tos` bounds check, owner-masked results equal).
* Local anvil battery (`child1_local.py`): canonical recompile vs `vase2` recompile — all behaviourally
  comparable cases equal (including malformed inputs and the empty-`tos` bounds check). The two flagged
  cases were (a) a legitimate clone-address difference (`deploy` returns different CREATE addresses) and
  (b) a test artifact (`from` hardcoded to one contract's address). Nested `batch` hits
  `EVM error MemoryLimitOOG` in **both** — a canonical BentoBox property, same on the live VASE.
* Opcode inventory (§2.2): no state-changing opcodes in the regions.

Residual uncertainty: I cannot reproduce the factoring with any compiler setting tested, so I cannot
*prove* byte-level equivalence of these ~90 bytes; I assessed them by hand + behavior tests. Flagged for
the parent (see §6). No value-extraction capability exists in this code category.

---

## 3. Live-state audit (Aurora block **219,872,980**; code hash re-verified identical)

### 3.1 Vault-level

| item | value |
|---|---|
| `owner()` | `0x0e2a05ca5d1e218034f2b7deb6e9419159839f8b` (EOA — 0-byte code) |
| `pendingOwner()` | `0x0` |
| `DOMAIN_SEPARATOR()` | matches name `"Vase"`, chainId 1313161554, address VASE (see §2.4) |
| `nonces(owner)` | 0 |
| ETH balance | 0 wei |
| code length | 22,831 (sha256 identical to fetch block) |

### 3.2 Token accounting (all 12 candidates checked; funded ones shown)

| token | address | bal(VASE) | totals.elastic | excess | strategy | strategyData |
|---|---|---|---|---|---|---|
| USDC.e | `0xb12bfca5…c40802` | 8,718,605,422 | 8,718,605,422 | 0 | 0 | 0,0,0 |
| USDT.e | `0x4988a896…d91571f` | 29,316,395 | 29,316,395 | 0 | 0 | 0,0,0 |
| WNEAR | `0xc42c30ac…ae8501d` | 5.220754027247457588684263e24 | same | 0 | 0 | 0,0,0 |
| WETH | `0xc9bdeed3…fe3feb` | 7,417,495,791,935,697,213 | same | 0 | 0 | 0,0,0 |
| WBTC | `0xf4eb217b…410e89e` | 40,455,524 | 40,455,524 | 0 | 0 | 0,0,0 |
| UST (atUST) | `0x5ce9f0b6…e634a9dc` | 1,917.398966569947174445e18 | same | 0 | 0 | 0,0,0 |
| RUSD | `0x19cc4028…45642e` | 392,657.666121117445198758e18 | same | 0 | 0 | 0,0,0 |
| DAI/FRAX?/MAI?/others | various | 0 | 0 | 0 | 0 | 0,0,0 |

`excess = 0` for every token ⇒ the BentoBox "skim" allowance (`deposit(from = address(this))`) yields nothing.

### 3.3 Share accounting (100% of vault balances are owned shares; no orphans)

| token | gardenNear | gardenUsdc | gardenUsdt | gardenWeth | gardenAtust | garden6 `0x6ba5B451…` | user `0x3820fedd…` | others |
|---|---|---|---|---|---|---|---|---|
| USDC | 0 | **8,718,605,422** | 0 | 0 | 0 | 0 | 0 | 0 |
| USDT | 0 | 0 | **29,316,395** | 0 | 0 | 0 | 0 | 0 |
| WNEAR | **5.220…e24** | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| WETH | 1e14 | 0 | 0 | **7.4174…e18** | 0 | 0 | 0 | 0 |
| WBTC | 0 | 0 | 0 | 0 | 0 | 19,199 | **40,436,325** | 0 |
| UST | 0 | 0 | 0 | 0 | 116.947…e18 | 0 | **1,800.451…e18** | 0 |
| RUSD | 875.79e18 | 52.43e18 | 37.87e18 | 80.22e18 | 13.12e18 | 32.27e18 | **391,565.90e18** | 0 |

(each column sums exactly to `totals.elastic`; `child1_share_matrix.json`).
Note: a **6th garden clone** `0x6ba5B45149996597d96e6db19e4E1EFa81A6df97` exists (dust positions) and a
second master contract `0x9224b0d8ba7abfe73fc4c7cf60023a4e0549c679` (registered itself, deployed a clone
`0x98a4e619…`; that master now has **0 bytes of code**; clone holds 0 shares; **no approvals** ever to it).

### 3.4 Whitelist / approvals / deploys (complete event history)

* `LogWhiteListMasterContract`: **1 event** — `0x857050Ef…AEd93` approved=true at block 62,781,704. Never revoked.
  Live read confirms: `whitelistedMasterContracts[GardenMaster]=1`; all other probed addresses (5 gardens,
  owner, RUSD pool, random) = 0.
* `LogSetMasterContractApproval`: **175 events / 174 users, all approved=true, all master=GardenMaster**, no revocations.
  (One user approved twice: blocks 62,979,617 and 66,231,196.)
* `LogDeploy`: **7 deploys** — GardenMaster → 6 clones (the 5 in scope + `0x6ba5B451…`); `0x9224b0d8…` → 1 clone.
* `LogRegisterProtocol`: 1 event — `0x9224b0d8…` (now codeless).

---

## 4. Permissionless-path audit table (probe block 219,873,848)

All probes are `eth_call` at that block; revert reasons decoded from raw revert data.

| # | path an unprivileged attacker could try | preconditions | probe result | extractable |
|---|---|---|---|---|
| 1 | `deposit(token, from=VASE, to=attacker, amount>0, share=0)` ("skim") | any caller (`allowed(from)` lets `from == address(this)`) | revert **"Vase: Skim too much"** — 7/7 tokens; also share-path encoding | **0** |
| 2 | `withdraw(token, from=VASE, to=attacker, amount=1, 0)` | any caller | revert **"BoringMath: Underflow"** — 7/7 (VASE owns 0 shares) | **0** |
| 3 | `transfer(token, from=VASE, to=attacker, share=1)` / `transferMultiple(...)` | any caller | revert **"BoringMath: Underflow"** (both) | **0** |
| 4 | `transfer(token, from=victim, to=attacker, share=1)` | caller needs `masterContractApproved[masterContractOf[msg.sender]][victim]` | from plain EOA → revert **"Vase: no masterContract"** | **0** |
| 5 | same as #4 but `msg.sender = garden clone` (a clone of the whitelisted GardenMaster) | victim (174 users, incl. the 0.404 WBTC holder) approved GardenMaster | **call succeeds** (documented boundary) — but the garden's own code never performs an arbitrary-`from` transfer: `cook` `ACTION_VASE_TRANSFER(_MULTIPLE)` use `from = msg.sender`; `ACTION_CALL` is blocked from calling the VASE (`Garden: can't call`); `liquidate` moves `from = address(this)` (the garden's own holdings) and reverts for fresh clones (`require(allBorrowAmount != 0, "Garden: all are solvent")` because internal `userBorrowPart=0`); `addCollateral/repay` pull from `msg.sender` | **0** via VASE |
| 6 | `harvest(token, *, *)` with `strategy=0` | any caller | revert (external call to `address(0)` returns empty returndata → decode revert) | **0** |
| 7 | `claimOwnership()` | any caller | revert **"Ownable: caller != pending owner"** (`pendingOwner=0`) | 0 |
| 8 | `whitelistMasterContract` / `setStrategy` / `setStrategyTargetPercentage` / `transferOwnership` | `onlyOwner` | revert **"Ownable: caller is not the owner"** (4/4) | 0 |
| 9 | `registerProtocol()` | any caller | **succeeds**; sets `masterContractOf[msg.sender]=msg.sender` only — for an EOA a no-op; grants no approval, no funds | 0 |
| 10 | `deploy(masterContract, data, useCreate2)` | any caller (canonical behaviour, no whitelist check) | permissionless clone creation; a fresh clone of GardenMaster has zero internal positions → cannot liquidate or transfer anyone's shares; no approvals exist for any other master; clone-init runs clone code that cannot call privileged VASE functions | 0 |
| 11 | `flashLoan` / `batchFlashLoan` | any caller | must return `amount + 0.05% fee` to the vault (`require(_tokenBalanceOf ≥ totals + fee)`); fee accrues to depositors; borrower-supplied callback executes after transfer → skim harder; no path to keep funds | 0 |
| 12 | ETH/WETH path (`token_ = 0x0`) | any caller | vault ETH = 0; `deposit(token_=0)` requires `msg.value == amount` (WETH wrap); `withdraw/transfer(from=VASE)` revert (0 shares) | 0 |
| 13 | `batch(...)` as a proxy to bypass `allowed()` | any caller | `batch` only `delegatecall`s **itself**; `msg.sender` is preserved → `masterContractOf[attacker]=0` remains → `from=victim` still reverts | 0 |

**Total permissionless extractable: $0 (per every probe).**

USD context (per task prices; vault holdings): USDC $8,717.73 · USDT $29.29 · WNEAR $26.21 ·
WETH $18,595.66 · WBTC $33,621.78 · UST 1,917.399 @ $0.0363 (Aurora DEX) = $69.60 (at global $0.0053: $10.16) ·
RUSD 392,657.666 @ $0.31 = $121,723.88 → **nominal total ≈ $182,784** (≈ $61,060 ex-RUSD; RUSD/UST prices are
the dominant uncertainty — RUSD is a defunct-protocol token, so nominal ≠ realisable).

---

## 5. Known BentoBox V1 issues vs this deployment

* **deposit/withdraw rounding** — share minted rounds down, burn rounds up, `amount` rounds down for share
  withdrawals; `MINIMUM_SHARE_BALANCE = 1000` blocks ratio reset. Rounding always favours the vault.
  With `excess = 0` there is no profitable rounding cycle; donation of elastic raises everyone's share price.
* **flashLoan whitelist** — V1 flash loans are permissionless by design (no whitelist); fee
  `amount*50/1e5` must be returned in the same tx. Same in VASE (byte-identical logic).
* **masterContractApproval signature replay** — digest = EIP-712 (`DOMAIN_SEPARATOR()` + `nonces[user]++`);
  live separator matches name `"Vase"`, chainId 1313161554, verifyingContract = VASE → approvals signed for
  Ethereum/other BentoBoxes **cannot** be replayed here (and vice-versa). No `chainId`-less fallback issue:
  the immutable separator is used only while `chainid() == deployment chain`.
* **`transferMultiple`** — only `tos[0]` is checked against zero; later zero addresses would credit shares
  to `address(0)`. Self-inflicted only.
* **`USE_ETHEREUM` (token_ = 0) bypasses the skim-limit check in `deposit`** — but that path requires
  `msg.value = amount` (WETH `deposit{value}`), and the vault's own ETH is 0, so no extraction.
* **Removed STRATEGY_DELAY** (this fork only) — owner-only, same-tx strategy activation + harvest;
  see §2.3. Owner is a plain EOA; this is the main trust difference from canonical BentoBox.
* **Kashi-style master approvals** — 174 users approved GardenMaster, so any clone of GardenMaster inherits
  the approval *for the clone's own business logic*. I found no garden entry point that takes an arbitrary
  `from` (see table #5), and fresh clones cannot liquidate (`all are solvent` revert), so existing user
  shares held by the five live gardens cannot be seized through a new clone. Residual: a user who *deposits*
  into a hostile future clone could be liquidated — phishing-adjacent, requires user action, out of VASE scope.

---

## 6. Conclusion, confidence, and what the parent must double-check

**Verdict — unprivileged attacker extracts $0 from the VASE today. Evidence:**
(1) all business logic byte-identical to canonical BentoBox V1 except the STRATEGY_DELAY removal and
(cost-neutral) helper factoring; (2) excess = 0 for every token, all strategies/strategyData zero,
ETH = 0, pendingOwner = 0; (3) every extraction probe reverts with the expected reason; (4) privileges
are owner-gated; (5) the only approval surface (GardenMaster, 174 users) is reachable by garden clones
but no garden code path accepts an arbitrary `from` / fresh clones cannot liquidate.

**Confidence:** **HIGH** that (a) the "strings-only" claim is refuted and (b) the live VASE is not
permissionlessly drainable. **MEDIUM** on the cause of the 5 ABI-helper STRUCT regions (equivalence
reviewed by hand + differential tests, but not compiler-reproduced).

**Parent should double-check:**
1. **STRATEGY_DELAY removal** (the one semantic source change). Reproduce: `cast disassemble 0xF5BCE507…`
   contains `PUSH3 0x127500` near the `setStrategy` body; the live VASE does not (see §2.3). My `vase2`
   recompile with `STRATEGY_DELAY = 0` makes that region match byte-for-byte.
2. **The 3 ABI-helper sites** (`child1_align_report.json`, STRUCT regions): try to obtain the original
   Vase source (Sourcify/IPFS/GitHub/team) and diff; my judgement is "not exploitable", not "proven equal".
3. **Garden-side entry points** (out of my scope beyond §4 #5): confirm no Garden function takes an
   arbitrary `from` and no oracle-manipulation → liquidation chain affects shares users did not deposit
   into that clone.
4. **Valuation**: RUSD at $0.31 and UST at $0.0363 (Aurora) vs $0.0053 (global) dominate; re-price if the
   parent quotes TVL.
5. **6th garden clone / dead master2** (`0x6ba5B451…`, `0x9224b0d8…`) for ledger completeness.

*Limitations: block-tip reorg risk is negligible at this depth; prices per task instructions; event
enumeration from explorer.aurora.dev (single source); no transaction was ever signed or sent.*
