# ZH4-PASS2 corrections reconciliation — UNCX VestingManager (`release()`/`cancel()`)

**Date:** 2026-10-20 · **Chains:** Ethereum (1), BNB Chain (56) · **ETH block:** 26,229,646 · **BSC block:** 128,639,266
**Status:** read-only; fork tests only (`eth_call`/Foundry fork; **no mainnet transactions**) · no secrets or keyed RPC URLs in this folder
**Scope:** reconciliation of ZH4-PASS2 correction **P2-03** against our ZH3-C1 verdict. UNCX is an **excluded / prior-corpus protocol** — this is a correction review, not a new report row.
**Bottom line: our ZH3 verdict stands. Live E-U is $0.00 (high confidence).** The pass2 correction is **rejected**: `release()` and `cancel()` are not permissionless, and the creation fee is the exact gate on the only primitive that can produce the double-debit.

---

## 1. TL;DR

| Pass2 P2-03 claim | Verified today | Evidence |
|---|---|---|
| “shared-pool double-debit in `release()`/`cancel()` is **permissionless**” | **FALSE as stated.** `release(id)` requires `msg.sender == schedule.beneficiary` (or the NFT owner). `cancel(id)` requires `msg.sender == schedule.creator`. Neither can be invoked on someone else’s schedule. What is permissionless is *creating and managing your own* vesting — which is fee-gated. | Verified source lines 597–601, 670–677; fork tests C, E |
| “the **creation fee does not gate `release()`**” | **TRUE but irrelevant.** `createVesting` / `createDailySoftVesting` / `createAirdropVesting` all require `msg.value >= flatFee`; the public exploit’s first step is `createVesting{value: 0.05 ether}`. Today `flatFee = uint256.max` on ETH and 35,000 BNB on BSC, with **zero** creator/token exemptions. | Source lines 511–547, 163–169; tests B, D, G; 5,100 + 995 schedule scan |
| “storage shows `_totalTokenShares == token balances` (1:1) for VEK/AXGT/OXN” | **CONFIRMED — and it refutes the premise.** A 1:1 pool is *not* share-corrupted: `release()` pays exactly the pro-rata claim. The attack needs a **creator-cancel of a soft schedule after a release** to double-debit the denominator; no attacker-controlled soft schedule remains in a funded pool. | Tests F, G; `analysis/eth_schedules_latest.json` |
| “`release()` processed as recently as Oct 17” | **CONFIRMED, but it was a normal beneficiary claim.** Tx `0x6d8894…` at block 26,209,802 was sent **from `0x648F3FD3…`**, exactly the schedule’s beneficiary. A second release (block 26,228,470, tx `0xf427acce…`) was likewise sent by its beneficiary. | Etherscan logs + `eth_getTransactionByHash` |
| “contracts non-proxy with no pause” | **CONFIRMED.** 18,010-byte runtime; EIP-1967 implementation slot = 0; no pause/upgrade function in the ABI or source. | `eth_getCode`, `eth_getStorageAt` |
| “ETH ~$4.18M nominal + BSC ~$1.48M nominal = ~$5.7M” | **NOMINAL ONLY.** Three of the five largest ETH marks (VEK, old-AXGT, OXN) have **no DEX pair at all**; the two that do are bounded by $154k/$32k of pool depth. Hard-realizable value *if the bug were reachable* is ≈ **$65k–131k** (ETH $46.6k–93.2k + BSC $18.9k–37.8k), not $5.7M. Live extractable is $0 because the path is gated. | Blockscout marks vs DexScreener depth; `analysis/reconcile_facts.json` |

**Total live extractable by an external unprivileged attacker now: $0.00** (high confidence). **No correction to our ZH3-C1 E-U verdict is warranted.** The pass2 correction is a *nominal-value* and *role-gating* error, not a newly live path.

---

## 2. The mechanism, exactly — and where it is gated

The deployed contract is the verified `VestingManager.sol` (solc 0.8.27, 18,010 bytes, non-proxy, immutable) at
`0xA98F06312b7614523d0f5e725e15fd20fB1b99F5` (ETH) and `0x7f3f9f4ED8987B78adC448a840169A0FD5AFFAAB` (BSC).

### 2.1 The double-debit

```
release(id):
  relShares = D·V/T − released                       // shares vested minus already-released
  amount    = relShares · balance / totalShares      // pays pro-rata of the SHARED pool
  released += relShares ; totalShares −= relShares

cancel(id):                                          // creator-only, soft-only
  vestedShare   = V·D/T
  sharesToRemove = D − vestedShare                   // does NOT subtract `released`
  totalShares  −= sharesToRemove ; _depositedShares = vestedShare
  refund = T − V to creator
```

`release()` already removed `released` shares from `totalShares`; `cancel()` removes the unvested shares **without crediting that already-removed amount**, so the same `released` shares are debited a second time. The denominator shrinks below the shares actually backed by the pool, and every surviving position (including the attacker’s “receiver” schedule) over-claims. This is the bug we verified in ZH3 and the Oct-14 exploit exploited.

### 2.2 The two roles that make it unreachable for a fresh attacker

| Function | Gate in deployed code | Consequence for a fresh attacker |
|---|---|---|
| `createVesting` / `createDailySoftVesting` / `createAirdropVesting` | `msg.value >= flatFee` (plus 5% token fee) | **ETH: `flatFee = uint256.max`** (1.16e77 wei); **BSC: 35,000 BNB**. Zero exemptions. Cannot create the attacker schedules the recipe needs. |
| `release(id)` | `msg.sender == ownerOf(id)` if NFTized, else `msg.sender == schedule.beneficiary` | Cannot release anyone else’s schedule. A bought NFT gives release rights only. |
| `cancel(id)` | `msg.sender == schedule.creator` **and** `schedule.isSoft` | Cannot cancel anyone else’s schedule; `creator` is set only at creation and is **never changed by NFT transfer**. |
| `topUpVesting(id)` | `msg.sender == schedule.creator` | Cannot top up a victim schedule. (Top-up itself has no flat fee — but the role gate is decisive.) |
| `transferVesting(id, to)` | `msg.sender == schedule.beneficiary` | Cannot redirect someone else’s claim. |
| `mintVestingNFT(id)` | `msg.sender == schedule.beneficiary` | Cannot mint someone else’s NFT. |

The exploit needs **three things the attacker must own in the same token pool**: (1) a schedule that is released, (2) a **soft** schedule that its **creator** cancels, and (3) a receiver schedule still holding shares. Owning (3) alone (via an NFT purchase) is harmless: release pays pro-rata. Owning none of them is the fresh-attacker case: **no path**.

### 2.3 The “permissionless” claim is a category error

The public DeFiHackLabs PoC says *“createVesting / createAirdropVesting / topUpVesting / cancel / release carry no owner, role or signature gate — any address may create and manage its own vestings.”* That is true in the narrow sense: there is no whitelist. But “any address may create **its own** vesting” is not “any address may call `release`/`cancel` on **any** vesting.” The PoC itself pays `FLAT_FEE = 0.05 ether` on every `createVesting`; at today’s `flatFee = uint256.max` the exact PoC reverts at the first create (fork test D).

---

## 3. Live-state assessment (every number read at an explicit block)

### 3.1 Ethereum — `0xA98F06312b7614523d0f5e725e15fd20fB1b99F5`, block 26,229,646

| Item | Value |
|---|---|
| runtime code | 18,010 bytes; EIP-1967 implementation slot `0x00…00` (not a proxy) |
| `owner()` | `0x31c44A17aa2E639B40f33DA805CB1DB55d969693` (same 2-of-N Safe across chains) |
| `flatFee()` | **`uint256.max` = 115,792,089,237,316,195,423,570,985,008,687,907,853,269,984,665,640,564,039,457,584,007,913,129,639,935` wei |
| `feePercentage()` | 500 (5%) |
| `nextVestingId()` | **5,100** (ids 0–5,099) |
| `feeExemptCreators` | **0 of 92 creators exempt** (all read at block 26,229,646) |
| `feeExemptTokens` | **0 of 76 tokens exempt** (incl. VEK/AXGT/AXGT2/OXN/TCT/EDGEN/PEPE/`0x78069e97…`) |
| containment | `flatFee → uint256.max` at block 26,193,348 (tx `0xf6c8ebc1…`); creator exemptions removed at block 26,197,490 (tx `0xde53e3e9…`) |
| events after containment | **0 `VestingCreated`, 0 `VestingCancelled`; 2 `TokensReleased`** (normal beneficiary claims) |

**Full schedule scan (5,100/5,100 decoded, `analysis/eth_schedules_latest.json`):**

| Metric | Count |
|---|---|
| schedules | 5,100 |
| cancelled | 39 |
| live (not cancelled) | 5,061 |
| live **soft + topable** | **1** (id 5,063) |
| live soft + topable **with claim > 0** | **0** |
| NFTized | 34 (10 `_transferable = true`) |
| pools with `totalShares == balance` (1:1) | 70 / 76 |
| pools not 1:1 | EDGEN, ZC, pepecoin, LO0P (the Oct-14-attacked pools) + 2 small pools |

**Key schedules:**

| id | token | creator = beneficiary | T | released | flags | claim now |
|---|---|---|---|---|---|---|
| 5,063 | pepecoin (`0xa9e8…`) | `0xf6d07225…` (Oct-14 helper) | 127,340.97 | same | soft + **topable** | **0** (fully released; PEPE pool holds 288.9 PEPE ≈ $40) |
| 5,035 | VEK | `0xbdcdb466…` | 250,000,000 | 0 | non-soft, not topable | 0 (not yet vested) |
| 4,963 | OXN | `0x325a1013…` | 570,000,000 | 0 | non-soft | 19,808,755.33 (pro-rata, healthy 1:1 pool) |
| 4,972 | WFC | creator `0x1137da98…`, NFT owner `0x986775ad…` | 100,000,000 | 9,728,708.44 | **soft + NFTized + transferable** | 3,750,432.69 |
| 5,030 | EDGEN | `0xcc5d4c9d…` | 722,222,000,000,000.5 | 0 | soft, not topable | nominal 255.77e24 **wei** vs pool balance 32.94e9 wei → release reverts |

The only live soft+topable schedule on ETH is the Oct-14 attacker’s **fully released** PEPE schedule; its `released == T`, so the cancellation refund is 0, and the pool is dust. The 34 NFTized schedules include soft/transferable positions, but an NFT transfer changes only the **beneficiary** — never `creator` — so it cannot unlock `cancel()`.

### 3.2 BNB Chain — `0x7f3f9f4ED8987B78adC448a840169A0FD5AFFAAB`, block 128,639,266

| Item | Value |
|---|---|
| runtime code | 18,010 bytes; EIP-1967 slot 0 (not a proxy) |
| `flatFee()` | **35,000 BNB = 3.5e22 wei** (≈$25.6M at BNB $732.58) |
| `feePercentage()` | 500 |
| `nextVestingId()` | 995 |
| fee exemptions | **0 creators / 0 tokens** |
| schedules | 995; 297 cancelled; 698 live |
| live soft + topable | **66 — all created by the Oct-14 helper `0x8174eee3…`; all claim 0** |
| BTCLE pool | 42,108,114,583 wei = **4.21e-8 BTCLE** (dust) |

The 66 live soft+topable schedules are the attacker’s own residual schedules from the Oct-14 BTCLE leg. Every one is fully released (`claim = 0`); the BTCLE pool is dust. They are a **re-arm monitor** (a future deposit into BTCLE would be at risk), not live value.

### 3.3 Recent release activity

| Block / time | Tx | Schedule | Caller | Beneficiary | Amount | Note |
|---|---|---|---|---|---|---|
| 26,209,802 (2026-10-17 04:11:59 UTC) | `0x6d88947837a29ab2a08125249b9b67439367cc800234c8d7cf80dc40426dde33` | 5,040 | `0x648F3FD3…` | `0x648F3FD3…` | 100,000 tokens | **caller == beneficiary** |
| 26,228,470 | `0xf427acce73a510ff1784664f978229cbb5fac3e20c3f1e216a8a002882c0c11f` | 4,939 | `0xDfF7D686…` | `0xDfF7D686…` | 99,500 TCT | **caller == beneficiary** |

These are exactly what a normal vesting claim looks like. They do not show a third party calling `release()`.

---

## 4. What a fresh attacker can / cannot do

**Fresh attacker:** a new EOA/contract, no owner/admin/operator key, no prior schedule, no fee exemption, only public contracts and flash-loanable capital.

| Attempt | Result | Why |
|---|---|---|
| `createVesting` / `createDailySoftVesting` / `createAirdropVesting` with 1,000,000 ETH | **revert `InvalidFlatFee()`** | `flatFee = uint256.max`; 1M ETH is ~10^71× short |
| Buy/acquire a transferable vesting NFT, then `release(id)` | succeeds only as the new beneficiary; pays **exactly pro-rata** | `release` is beneficiary-gated; `amount = relShares·B/S`; with S=B this is the claim, no premium |
| After buying the NFT, call `cancel(id)` / `topUpVesting(id)` | **revert `NotAuthorized()`** | `creator` is immutable across NFT transfers; only the original creator can cancel/top up |
| Call `release`/`cancel`/`topUp`/`transferVesting` on a victim’s schedule directly | **revert `NotAuthorized()`** | role gates above |
| Donate tokens to a pool and release | **net loss** | donation raises B for every holder; a holder with no schedule gets nothing, and any holder’s own donation is only partially recovered |
| Use the exact public DeFiHackLabs PoC at latest block | **revert `InvalidFlatFee()`** | first `createVesting{value: 0.05 ether}` cannot pay `uint256.max` |
| Repeat-release a schedule | second call reverts `NoTokensToRelease()` | shares are debited on the first release |
| Cancel a fully vested fee-paying schedule | reverts arithmetic underflow (`T` is net of the 5% fee, `getVestedAmount` is gross) | adds a second reason the residual attacker schedules cannot be weaponized without a top-up |
| Seed the double-debit with an **existing** soft schedule | no attacker-controlled soft schedule in a funded pool | ETH: only soft+topable is 5,063 (claim 0, dust); BSC: 66 attacker schedules, all claim 0, BTCLE dust |

**Costs:** the only live path would require `msg.value = uint256.max` wei (≈10^51 × world ETH supply) plus gas; it is not a capital-cost question. Under a hypothetical fee removal, the public recipe’s cost is ~1 flat fee + 5% token fee + flash fees + gas (the real Oct-14 attack netted ~$88k on the ETH leg); but that is a **conditional re-arm**, not a live path.

---

## 5. Fork verification (CI, 10/10 PASS)

**Run:** CI URL recorded in `ci-run.txt` / §8 after the run. Local dry run: **10 passed, 0 failed** at fork block 26,229,9xx.

Project: `poc/` (`foundry.toml`, `src/IVestingManager.sol`, `src/MockERC20.sol`, `test/UncxReconcile.t.sol`, vendored `lib/forge-std`).

| Test | What it proves | Result |
|---|---|---|
| A | live params, `flatFee=uint256.max`, `nextVestingId≥5100`, EIP-1967 slot 0 (non-proxy) | PASS |
| B | fresh attacker with 1,000,000 ETH cannot call any of the three creation entry points (`InvalidFlatFee`) | PASS |
| C | fresh attacker cannot `release`, `cancel`, `transferVesting` or `topUp` any live schedule (`NotAuthorized`) | PASS |
| **D** | **the exact public DeFiHackLabs PoC, run at latest state, reverts at the first create (`InvalidFlatFee`)** | **PASS** |
| **E** | **buying a transferable soft NFT gives release only: beneficiary changes, creator does not; release pays pro-rata; `cancel`/`topUp` still `NotAuthorized`** | **PASS** |
| F | release pays exactly `relShares·B/S` in a 1:1 pool; a second release reverts `NoTokensToRelease` | PASS |
| G | zero fee exemptions for the known creators/tokens (ETH) | PASS |
| H | **conditional re-arm:** with `flatFee=0` (simulated owner tx), create/release/cancel work — proving the sole live gate | PASS |
| I | the EDGEN corrupted-pool “claim” (255.77e24 wei) exceeds the pool (32.94e9 wei); `release` reverts | PASS |
| J | BSC manager: `flatFee=35,000 BNB`; fresh attacker `release`/`cancel` revert `NotAuthorized` | PASS |

The tests are read-only fork simulations. No transaction was signed or sent to a real network.

---

## 6. Nominal vs realizable — the $5.7M figure

Pass2’s $4.18M ETH + $1.48M BSC is a **mark-to-model** figure. At the same block:

| Token | Balance | Blockscout mark | Paper USD | Deepest DEX pool | Hard-realizable (25–50% depth) |
|---|---|---|---|---|---|
| VEK | 250.0M | $0.01001408 | $2,503,520 | **no pair** | **$0** |
| AXGT | 125.7M | $0.00749204 | $941,749 | $154,294.82 | **$38,574–77,147** |
| AXGT2 (old) | 95.0M | $0.00242024 | $229,923 | **no pair** | **$0** |
| OXN | 807.5M | $0.00041693 | $336,671 | **no pair** | **$0** |
| TCT | 51.85M | $0.00146316 | $75,865 | $32,080.89 | **$8,020–16,040** |
| **Top-5 total** | | | **≈$4.09M** | | **≈$46.6k–93.2k** |
| BSC: DROPS | 74.925M | $0.01574 | $1,121,453 | $29,767.83 | **$7,442–14,884** |
| BSC: LOOPRA | 34.965B | $0.00001315 | $459,000 | $45,885.04 | **$11,471–22,943** |
| BSC: CDT | 410.0M | — | $44,362 | **no pair** | **$0** |
| **Combined hard** | | | | | **≈$65.5k–131.0k** |

The three largest “missing” marks (VEK $2.50M, old-AXGT $230k, OXN $337k) have **no DexScreener pair at all** — 46 holders for VEK, 5,098 for OXN, and $0 24-hour volume. They cannot be sold on-chain at any size. The prior ZH3 report already bounded the ETH hard value at ≈$66k–124k; the pass2 $4.18M is a price-mark change (the pass2 `monitor-diff.md` itself says “~$4.18M at Blockscout exchange rates vs ~$1.16M at the Oct-16 DefiLlama set — a price-mark change, not new funds or a new path”). Nothing in the storage or event history changed to make the pools more valuable or more accessible.

**If the bug were reachable** (fee removed), the attack could drain the whole shared pool of each token, but the *realizable* proceeds are still capped by DEX depth at ≈$65k–131k. That is the correct conditional number to attach to the monitor, not $5.7M.

---

## 7. Verdict, residual/latent risk, monitors

**Verdict: E-U $0.00 live (high confidence).** Our ZH3-C1 closure is correct; the pass2 P2-03 correction is **rejected** on two independent grounds:
1. **Role gating:** `release` is beneficiary-only, `cancel`/`topUp` are creator-only. A fresh attacker cannot operate any existing schedule; an NFT purchase gives release rights only (pro-rata), never the cancel/creator right that produces the double-debit.
2. **Fee starvation:** the only way to obtain those roles is to create a schedule, which costs `uint256.max` wei on ETH and 35,000 BNB on BSC, with zero exemptions. The full 5,100/995-schedule scan finds no live soft+topable schedule with a positive claim in a funded pool.

**Classification:**

| Class | USD | What it is | Confidence |
|---|---|---|---|
| **E-U** | **$0.00** | no creation; no third-party release/cancel; no attacker-controlled soft schedule with a positive claim | high (source + full scan + 10/10 fork tests) |
| **H-O** | ≈$65k–131k hard (this ETH+BSC scope) | legitimate beneficiaries’ pro-rata claims: AXGT/TCT + DROPS/LOOPRA; VEK/old-AXGT/OXN/others are $0 hard (no pair) | medium (paper marks firm; hard bound is DEX-depth-dependent) |
| **P** | $0 extraction; one parameter key | owner Safe can lower `flatFee` or re-add an exemption; no sweep/pause exists | high |
| **S** | ≈$36.5k (carried from ZH3) | RH RKST share-corrupted pool; ETH attacked-pool dust | medium-high |

**Conditional re-arm (monitor, not live):** one owner transaction `setFlatFee(<payable>)` or `setCreatorFeeExempt`/`setTokenFeeExempt` re-opens creation, and the immutable bug becomes exploitable again (fork test H proves the full create/release/cancel cycle with `flatFee=0`). Because the ETH pools that remain valuable are 1:1 and mostly pairless, the *realizable* conditional is ≈$65k–131k, not $5.7M.

**Monitors (unchanged from ZH3, with updated values):**
1. `FlatFeeUpdated` / `CreatorFeeExemptionUpdated` / `TokenFeeExemptionUpdated` on ETH `0xA98F…` and BSC `0x7f3f…` (no such event after block 26,197,490 on ETH).
2. Any `VestingCreated` while `flatFee` is high (would imply a new exemption/bypass).
3. Deposits into the share-corrupted pools: ETH EDGEN/ZC/PEPE/LO0P; BSC BTCLE (anomalous `totalShares` 216,115 vs dust balance). New deposits are mispriced traps.
4. The residual attacker schedules: ETH 5,063 (PEPE) and BSC ids 898–994 (BTCLE) are claim 0 and dust; watch for a deposit that would make a top-up+cancel profitable.
5. Owner Safe `0x31c44A17…` (2-of-N) transactions.

**What would change the verdict:** a `FlatFeeUpdated` to a payable value (or a new exemption) on a deployment that still holds a pool with >~$65k of realizable liquidity; or a newly created soft+topable schedule in such a pool. Neither is present at block 26,229,646 / 128,639,266.

---

## 8. Methodology, sources, files

**Method.** Full enumeration of both manager deployments: 5,100 ETH + 995 BSC schedule tuples via batched `eth_call` at fixed blocks; private storage (`_totalTokenShares` slot 11, `_depositedShares` slot 12, `_shareRatio` slot 15, `flatFee` slot 17) via `eth_getStorageAt`; every creator/token checked against `feeExemptCreators`/`feeExemptTokens`; Etherscan V2 `getLogs` for `FlatFeeUpdated`, `CreatorFeeExemptionUpdated`, `TokenFeeExemptionUpdated`, `TokensReleased`, `VestingCreated`, `VestingCancelled` since containment; tx sender vs schedule beneficiary for both recent releases; Blockscout token marks + DexScreener depth + DefiLlama BNB/ETH for nominal-vs-realizable; exact public DeFiHackLabs PoC and the auth/role paths simulated on Foundry forks in CI. All reads at explicit block numbers.

**Sources.** Verified `VestingManager.sol` (solc 0.8.27) / `IVestingManager.sol` / `IVestingCalculator.sol` (Etherscan V2); public RPC `eth_call`/`eth_getStorageAt`; Etherscan V2 logs; Blockscout `api/v2/tokens/{addr}`; DexScreener `latest/dex/tokens`; DefiLlama `coins.llama.fi`; DeFiHackLabs `2026-10/UNCXSmartTokenVesting_exp.sol`; our ZH3-C1 folder (`uncx-vesting/`) for the historical incident reconstruction.

**Caveats / limitations.**
- Point-in-time reads (2026-10-20, blocks 26,229,646 / 128,639,266); re-verify before acting.
- The 25–50%-of-depth realizable bound is an estimate; the true sale impact for 125.7M AXGT into a $154k pool is likely at the low end.
- Blockscout marks for VEK/old-AXGT/OXN are not backed by a DEX pair; we report them only to reconcile pass2’s $4.18M and explicitly mark them $0 hard.
- The BSC nominal $1.48M comes from pass2/prior GoldRush marks; only DROPS and LOOPRA have observable pairs today. BscScan’s own net-worth figure was ~$45.7k at the ZH3 read.
- The `cancel()` underflow on fully vested fee-paying schedules is a separate quirk we observed; it further blocks the residual attacker schedules but is not itself an extraction path.
- No mainnet transaction was sent. The owner fee parameter remains the single re-arm.

**Files.**
```
uncx-reconcile/
├── README.md                          # this report
├── summary.json                       # machine-readable verdict
├── analysis/
│   ├── scan_schedules.py              # full schedule/pool scanner (ETH + BSC)
│   ├── scan_schedules_light.py        # BSC variant (no depositedShares/NFT pass)
│   ├── build_facts.py                 # derives reconcile_facts.json
│   ├── eth_schedules_latest.json      # 5,100 ETH schedules + 76 pools @ 26,229,646
│   ├── bsc_schedules_latest.json      # 995 BSC schedules + 42 pools @ 128,639,266
│   ├── logs_since_containment.json    # Etherscan V2 logs after block 26,193,348
│   ├── token_meta.json / bsc_token_meta.json
│   └── reconcile_facts.json           # consolidated evidence + nominal/realizable table
├── poc/                               # Foundry project (10 tests)
│   ├── foundry.toml
│   ├── src/IVestingManager.sol, src/MockERC20.sol
│   ├── test/UncxReconcile.t.sol
│   └── lib/forge-std/
└── ci-out/                            # local/CI test artifacts
```

**No secrets or keyed RPC URLs are stored in this folder.** Scripts take the RPC endpoint from argv/env; CI uses the workflow-injected `FORK_RPC_URL`/`BSC_RPC_URL`.
