# Pirate Chain (ARRR) — forged coin-import mint, two on-chain mints (~79.8M ARRR), exits closed

**Date:** 2026-10-19/20 · **Chain:** Pirate Chain L1 (Komodo/Zcash fork, Sapling + Ironwood shielded pools) · **Status:** read-only; no transactions signed or sent; no keyed RPCs or secrets in this folder.

**Finding ID:** ZH4-PASS2 / P2-02 (deep dive) · **Class:** consensus/issuance bug, **miner-only** (not a contract-level path) · **Verdict:** **E-U-conditional** — **$0 live**, **~$19.60M notional conditional** on an exit reopening, **~$1.0–2.9M realistic** at a forced liquidation.

---

## 1. TL;DR

| Question | Answer |
|---|---|
| What is the bug? | `ConnectBlock` skipped input/burn-proof validation for **every `IsMint()` transaction**. `IsMint()` is true for both the coinbase **and coin imports**, so a forged import-shaped tx in a block minted outputs with **no proof of burn**. The mempool *did* run the check, so the tx had to be placed directly in a block by a miner. |
| Affected versions | **v6.0.0 – v6.0.9** (code vulnerable from v6.0.0, 2026-08-17; mainnet v6.0.0 activation 2026-09-19; Ironwood activation 2026-10-03 at block **4,161,185**). v5.9.3 and earlier use `IsCoinBase()` and are **not** affected by this bug. |
| Patch | **v6.0.10** (tag `a262cf4`, published **2026-10-18 23:48:59Z**), mandatory, automatic reindex. Fix commit `da4e6252a3` (2026-10-14 23:50:13Z) changes `if (tx.IsMint())` → `if (tx.IsCoinBase())` and adds a regression test that connects a block with a forged import and expects `invalid-coin-import`. A second bug (non-canonical CLTV output-address spoofing, commit `3913cee40`) is fixed in the same release. **v6.0.11** (2026-10-19 21:19Z) is networking-only, no consensus change. |
| Patch adoption | **10 / 57 sampled peers (17.5%) on 6.0.10**; **28 / 57 (49.1%) on vulnerable 6.0.0–6.0.9**; **19 / 57 (33.3%) pre-6.0.0 and stuck**. Only **6 / 57** peers are on the explorer's tip. The network is split; the explorer follows the legacy (invalid) chain. |
| What was minted | **Two on-chain supply jumps**: **+39,822,234 ARRR on 2026-10-14** (the officially reported ~39.8M) and **+40,000,358 ARRR on 2026-10-16** (a second ~40.0M mint, not in the official statement). Total **79,822,592 ARRR**. |
| Current supply | **278,807,756 ARRR total** (277,513,421 circulating), **139.4% of the 200M cap**; pre-mint supply (2026-10-13) was **198,984,641 ARRR**. |
| Price / notional | **$0.2455/ARRR** (CoinGecko, 2026-10-19 23:58Z) → **$19.60M** for 79.82M ARRR (the first 39.8M alone ≈ $9.77M). |
| Can a fresh attacker mint now? | **Yes, miner-only, on ≤ v6.0.9 nodes** — but only into a chain that the venue/exchange accepts. The cost is trivial: network ≈ **1.92 MSol/s**, rented 51% ≈ **$50/day**, expected cost per block ≈ **$0.07** at NiceHash Equihash prices. |
| Can a fresh attacker monetize now? | **No.** Gate, MEXC and NonKYC have **deposits and withdrawals disabled**; no verified native-ARRR instant-swap or bridge exit. NonKYC already froze the first attempted deposit. |
| Live extractable (E-U) | **$0** (high confidence). |
| Conditional (E-U if an exit reopens) | **$19.60M notional**; **$1.0–2.9M realistic** after an 85–95% liquidity/freeze/fork haircut (low confidence). |

**Headline:** the pass-2 figure (39.8M ARRR, ~$9.75M) is **half the on-chain damage**. The explorer's daily pool history shows a **second +40.0M ARRR mint on 2026-10-16**, putting total supply at **278.8M — 139.4% of the 200M cap**. Minting is live for any miner on an unpatched node; **monetization is the only binding constraint**, and it is closed today.

---

## 2. The bug in exact terms

### 2.1 Mempool validates imports; `ConnectBlock` did not

Pirate Chain's coin-import transaction is identified by a single input whose `prevout.n == 1,000,000,000`:

```cpp
// src/primitives/transaction.h (v6.0.10)
bool IsMint() const { return IsCoinImport() || IsCoinBase(); }
bool IsCoinBase() const { return (vin.size() == 1 && vin[0].prevout.IsNull()); }
bool IsCoinImport() const { return (vin.size() == 1 && vin[0].prevout.n == 10e8); }
```

The **mempool** path (`AcceptToMemoryPool`) unconditionally calls `ContextualCheckInputs` (v6.0.9 `src/main.cpp:2368`). `ContextualCheckInputs` (definition at `src/main.cpp:3198`) skips the ordinary input checks for `IsMint()` but then explicitly validates imports:

```cpp
if (tx.IsCoinImport()) {
    LOCK(cs_main);
    ServerTransactionSignatureChecker checker(&tx, 0, 0, false, txdata);
    return VerifyCoinImport(tx.vin[0].scriptSig, checker, state);
}
```

`VerifyCoinImport` (`src/importcoin.cpp:440`) requires the scriptSig to contain an `EVAL_IMPORTCOIN` condition and verifies the burn proof/signature. So **broadcasting a forged import is rejected by the mempool**.

The **block-connection** path did not reach that check. In v6.0.9 `ConnectBlock` (line **4078** of `src/main.cpp`):

```cpp
if (tx.IsMint())        // BUG: true for coinbase AND coin imports
{
    chainSupplyDelta += tx.GetValueOut();
} else {
    ...
    if (!ContextualCheckInputs(...))   // VerifyCoinImport lives here
        return false;
}
```

Because `IsMint()` is true for imports, a forged import took the **coinbase branch**: no `ContextualCheckInputs`, no `VerifyCoinImport`, no burn proof. Its outputs were added to supply and accepted. v5.9.3 used `if (tx.IsCoinBase())` (line 4107); v6.0.0 changed it to `IsMint()`.

The fix (v6.0.10) is exactly:

```cpp
// Only the coinbase may skip input validation here. A coin import is also
// IsMint(), but it must take the else branch so ContextualCheckInputs runs
// VerifyCoinImport; otherwise any import-shaped transaction would mint its
// outputs with no proof of a burn.
if (tx.IsCoinBase())
```

**Reproduction shape** (from the upstream regression test added in the fix commit, `src/gtest/test_block_connect.cpp`):

- one input: `prevout = COutPoint(<arbitrary txid>, 1000000000)`;
- `scriptSig` of 2–100 bytes (passes `CheckTransaction`'s coinbase-like length check), with or without a meaningless `OP_RETURN` payload;
- arbitrary outputs, e.g. `1000 * COIN` to a key the attacker controls;
- the block is connected directly (`ConnectBlock`) and, pre-fix, accepted; post-fix it returns `invalid-coin-import`.

The test uses the public `CRYPTO777` key on a private test chain; on mainnet the attacker uses their own key and then shields.

### 2.2 The second validation failure: output-address spoofing

Pirate is a private asset chain (`ASSETCHAINS_PRIVATE != 0`). Non-coinbase transparent outputs with value must pay a **notary vout** (`komodo_isnotaryvout`) or the transaction is rejected (`src/main.cpp:1718–1725`, `1883–1890`). The second bug was **non-canonical CLTV script classification**: `Getscriptaddress` treated certain non-standard scripts as time-locked and read the address from the wrong place, so an output could **report a notary address it did not actually pay** while remaining spendable by the attacker. The fix (`3913cee40`) requires the exact canonical CLTV layout.

Together: bug 1 creates the coins; bug 2 makes the output pass the private-chain address restriction and remain spendable. The attacker then shielded the coins into Sapling/Ironwood.

### 2.3 Affected-version timeline

| Version | Date | `ConnectBlock` branch | Status |
|---|---|---|---|
| v5.9.3 | 2026-06-24 | `IsCoinBase()` | not affected by this bug |
| **v6.0.0** | **2026-08-17** | **`IsMint()`** | **vulnerable** (mainnet v6.0.0 activation 2026-09-19) |
| v6.0.1 … v6.0.9 | 2026-08-21 … 2026-10-13 | `IsMint()` | **vulnerable** |
| **v6.0.10** | **2026-10-18 23:48Z** | **`IsCoinBase()`** | **patched**, mandatory reindex |
| v6.0.11 | 2026-10-19 21:19Z | `IsCoinBase()` | patched; networking only |

The code bug existed from v6.0.0 (Aug 17). The observed exploit is **2026-10-14**, 11 days after Ironwood activation (Oct 3) and after the fix commit was written (Oct 14 23:50Z). The binary patch was not released until Oct 18, leaving a four-day window in which every ≤6.0.9 node/miner was vulnerable.

---

## 3. On-chain evidence: two mints, 278.8M supply

The explorer's **live stats** endpoint (`https://explorer.piratechain.com/stats/stats.json`, read 2026-10-19 23:05Z) reports:

| Field | Value |
|---|---|
| Height | **4,180,718** (explorer data updated 2026-10-19 14:21:03Z; "data is stale") |
| Total supply | **278,807,755.92 ARRR** |
| Circulating supply | **277,513,420.60 ARRR** |
| Locked in Sprout | 1,294,335.32 ARRR |
| Max supply | **200,000,000 ARRR** |
| **Mined so far** | **139.4%** |
| Pools | transparent 20,241,591.14 · Sprout 1,294,335.32 · Sapling 234,239,957.28 · Ironwood 23,031,872.18 |
| Current block reward | **0.25 ARRR**; next halving 4,277,735 (~2026-12-24); then 0.125 |
| NetHash | **1.921 MSol/s** |
| Difficulty / block time | 6,216,414.1 / **60.3 s** |
| Nodes seen (24h/7d/30d) | **104 / 272 / 621** |
| Peers sampled / on 6.0+ | 57 / **38 (67%)**; 19 pre-Ironwood "stuck"; most common version **5.9.0 (11 peers)** |
| Last notarized height | 4,177,169 |

### 3.1 Daily pool history — the two jumps

`https://explorer.piratechain.com/stats/history.json` (read 2026-10-19 22:07Z) gives daily pool balances. The total (transparent + Sprout + Sapling + Ironwood) is:

| Day (UTC) | Blocks | Total supply (ARRR) | Δ vs prior day | Pool detail |
|---|---:|---:|---:|---|
| 2026-10-12 | 1,438 | 198,984,284 | — | normal emission |
| 2026-10-13 | 1,422 | **198,984,641** | +357 | pre-mint baseline |
| **2026-10-14** | 1,442 | **238,806,875** | **+39,822,234** | Sapling +20,089,844; Ironwood +19,732,390; transparent flat |
| 2026-10-15 | 1,408 | 238,807,228 | +353 | normal |
| **2026-10-16** | 1,435 | **278,807,586** | **+40,000,358** | transparent **+20,000,356**; Sapling **+19,999,573**; Ironwood +429 |
| 2026-10-17 | 676 | 278,807,755 | +169 | chain slows (676 blocks vs ~1,435/day) |

- **First mint:** +39,822,234 ARRR — exactly the official "approximately 39.8 million" (20.0% of the 198.98M pre-mint supply). It is split between Sapling (+20.09M) and Ironwood (+19.73M), matching the statement that the coins were moved into shielded pools.
- **Second mint:** +40,000,358 ARRR on **2026-10-16**, after the official Oct-15 statement. It appears as **20.0M transparent + 20.0M Sapling**, i.e. a 40M mint with half shielded, or a 40M transparent mint of which 20M was shielded the same day. The day's transaction count is normal (1,463, of which only **3 transparent** and **9 shielding**), so this is a handful of very large transactions, not organic activity. The exact 40,000,000 size and the pool split are inconsistent with ordinary emission (358 ARRR/day).
- **Total:** **79,822,592 ARRR** forged across two events, **$19.60M** at $0.2455. The first mint alone is $9.77M.

**Confidence:** high on the supply jumps and the total (the explorer is a full node and the daily totals are internally consistent with the pool balances); **medium** on whether the second +40M is a second mint by the same attacker, a copycat, or an indexer correction that surfaced a previously unaccounted 40M output. The round 40,000,000, the transparent/Sapling split, the normal tx counts, and the absence of any rescan note favor a **second mint**. A full-node UTXO audit / block scan would settle it; the public explorer's block pages are client-rendered and were not scrapeable in this pass.

### 3.2 Supply vs the 200M cap

- Pre-mint (2026-10-13): **198,984,641** — just under the 200M cap (99.5%).
- After the first mint: **238,806,875** — 119.4% of cap.
- After the second mint: **278,807,756** — **139.4% of cap**.
- The explorer itself labels this "**Mined so far 139.4%**" and "Projected final supply ≈ 278,929,231 ARRR". This is not a nominal/CoinGecko figure; it is the node's pool sum.

> **Correction to the public narrative:** the widely quoted 196.2M "supply" is a **static nominal figure** (it has been 196,213,797.97 on CoinGecko since at least Oct 2023; the old `/api/supply` endpoint returns the same constant). The live explorer's pool sum is **278.8M**. The 39.8M headline is only the first mint; the second +40.0M takes the cap breach to **78.8M**.

---

## 4. Patch adoption and network state

### 4.1 Peer version distribution (explorer sample, 57 peers)

| Version | Peers | On explorer tip | Status |
|---|---:|---:|---|
| **6.0.10** (patched) | **10** | 0 | 17.5% of sample |
| 6.0.9 | 3 | 2 | vulnerable |
| 6.0.8 | 9 | 1 | vulnerable |
| 6.0.7 | 5 | 1 | vulnerable |
| 6.0.6 | 1 | 1 | vulnerable |
| 6.0.4 | 2 | 0 | vulnerable |
| 6.0.3 | 5 | 1 | vulnerable |
| 6.0.1 | 2 | 0 | vulnerable |
| 6.0.0 | 1 | 0 | vulnerable |
| 5.9.3 / 5.9.2 / 5.9.0 | 3 / 5 / 11 | 0 | pre-6.0.0, stuck (19 total) |

- **Patched: 10/57 = 17.5%.** Vulnerable 6.0.0–6.0.9: **28/57 = 49.1%**. Pre-6.0.0 stuck: **19/57 = 33.3%**.
- Only **6 of 57** peers are on the explorer's tip; the 10 patched 6.0.10 peers are all `onTip: 0`. This is consistent with a **chain split**: the explorer follows the legacy chain that contains the forged imports; patched nodes have reindexed/rejected those blocks and are on a different (valid) chain; the 5.9.x peers are stuck on the pre-Ironwood chain.
- GitHub downloads corroborate thin adoption: **91** v6.0.10 asset downloads and **1** v6.0.11 download in the first ~24h (v5.9.3 has 687 lifetime downloads). Source builds/Docker are not counted, so this is a lower bound, but the peer sample is the better measure.

### 4.2 Chain state

- Last height **4,180,718**, explorer updated **2026-10-19 14:21:03Z** and marked **"data is stale"** — no update for ~9 hours at read time. Last notarized height 4,177,169. The chain is **stalled or split**; the daily block count fell to 676 on Oct 17 (vs ~1,435/day).
- Ironwood activated at block **4,161,185** (2026-10-03). The exploit window is between activation and the mints.
- The hard-fork plan announced around Oct 17 would start "at the block before an unauthorized mint", but **no block height or activation date has been published** (TokenPost, 2026-10-17). v6.0.10's mandatory reindex is the mechanism that rejects the forged-import blocks; v6.0.11 adds no consensus change.

---

## 5. What an attacker can and cannot do

### 5.1 Mint (live, miner-only)

**Preconditions:**
1. A Pirate Chain node/miner on **v6.0.0–v6.0.9** (or a patched node modified to re-enable the branch).
2. Ability to construct a block directly (solo mine or pool collusion). The mempool rejects the forged import, so it cannot be broadcast as a normal tx.
3. A spendable output that passes the private-chain transparent-output restriction (bug 2), or a direct shielded output if the transaction shape permits.
4. The resulting block must be accepted by the nodes/venues the attacker wants to use.

**Cost (measured):**
- Network **1.921 MSol/s**, block time **60.3 s**, block reward **0.25 ARRR** (~$0.061), daily emission **358 ARRR** (~$88).
- NiceHash Equihash market: **0.57–0.63 BTC/GSol/day** (~**$51,429/GSol/day** at BTC ≈ $82k).
- Renting **10%** of the network: **$9.88/day**; **51%: $50.39/day**; **100%: ~$98.7/day**.
- Expected cost per block (any share): **~$0.069** of rented hash. The high end of the range (if the true hashrate is 2–3× the explorer estimate) is still **< $1/block**.
- A single forged block can mint **~40M ARRR (~$9.8M notional)**. Mining economics are irrelevant next to the mint; the block reward is a rounding error.

**What the attacker cannot do:** broadcast the forged import through the mempool (rejected by `AcceptToMemoryPool` → `ContextualCheckInputs` → `VerifyCoinImport`), or get a patched v6.0.10+ node to accept the block. If the patched chain has more work, a venue running a patched node will not credit the invalid chain.

### 5.2 Monetize (closed today)

| Venue | Status at 2026-10-19/20 | Evidence |
|---|---|---|
| **Gate** | **Deposit + withdraw disabled**, trade enabled | `GET /spot/currencies/ARRR` → `deposit_disabled:true, withdraw_disabled:true, trade_disabled:false`; 24h quote vol **$14,743**; top-100 book **$6.6k bid / $9.2k ask** |
| **MEXC** | **Deposits + withdrawals suspended** (Oct 15, at project request) | MEXC announcement "Suspension of ARRR Deposits and Withdrawals"; 24h quote vol **$64,664**; top-100 book **$9.4k bid / $15.1k ask** |
| **NonKYC** | **Deposit + withdraw disabled** ("By request of the Pirate Chain devs."); market still trades existing balances | NonKYC ARRR asset state `depositActive:false, withdrawalActive:false`; CoinGecko 24h vol ~**$430k** (largest ARRR market) |
| **ChangeNOW** | Native ARRR **not supported**; only BSC-wrapped ARRR; `ARRR(BSC)→BTC` returns **PAIR_NOT_AVAILABLE** | `vip-api.changenow.io/v3/exchange/estimate` |
| **Godex** | **ARRR not listed** | `api.godex.io/api/v1/coins` (no ARRR) |
| **Other instant swappers** | Not verified / key-gated; no confirmed live native-ARRR pair | Changelly/SimpleSwap/StealthEX/Swapzone/FixedFloat/LetsExchange |
| **vARRR / Verus bridge** | Verus–Ethereum bridge **hacked 2026-05-18 ($11.58M)**; ARRR↔vARRR atomic-swap liquidity unverified | Verus bridge post-mortems; vARRR page |
| **AtomicDEX** | P2P order book exists in principle; no public depth; not scalable | — |
| **Base "ARRR" token** | **Not the real coin**: 1,000,000,000 supply, $309k liquidity, **$0.02 24h volume** | Base `0x6145…7bd2`; `totalSupply = 1e27` |
| **OTC** | No public ARRR desk; private bilateral only, unverifiable | — |

**Conclusion:** there is **no open, verifiable native-ARRR deposit rail**. The 24h tracked volume across the three CEXes is ~**$509k**, while the forged notional is **$19.60M** (~38× daily volume). Order books are **$16–25k** deep. A forced sale of 79.8M ARRR would collapse the price; even a 5–15% realization is optimistic.

### 5.3 Quantification

| Category | USD | Confidence | Notes |
|---|---:|---|---|
| **E-U live now** | **$0** | **high** | All CEX deposit rails closed; no verified instant-swap/bridge; chain split/stalled |
| **E-U conditional notional** | **$19.60M** | high on amount; low on realisability | 79,822,592 ARRR × $0.2455 |
| **E-U conditional realizable** | **$1.0M – $2.9M** | **low** | 85–95% haircut for liquidity, exchange freeze/KYC, fork risk; 5–15% of notional |
| First-mint-only realizable | $0.49M – $1.47M | low | if the second +40M is excluded/untraceable |
| **H-O / P / S** | $0 | — | no holder/privileged/stuck value in this path |

**Race risk: high.** The attacker must exit **before** (a) a hard fork invalidates the post-mint coins, (b) exchanges complete v6.0.10 reindexing and refuse the legacy chain, or (c) another holder/attacker dumps into the same thin book. The first attempted deposit was already frozen by NonKYC. The chain's own explorer is on the **invalid** chain; the patched peers are on a **different** chain. This is a live fork, not a hypothetical.

---

## 6. Verification / PoC

This is a **non-EVM consensus bug**; there is no Foundry fork PoC. Verification is source-level + on-chain:

1. **Source asymmetry verified** by comparing `src/main.cpp` at v5.9.3, v6.0.9 and v6.0.10:
   - v5.9.3 `ConnectBlock` → `if (tx.IsCoinBase())` (line 4107) — safe.
   - v6.0.9 `ConnectBlock` → `if (tx.IsMint())` (line 4078) — vulnerable; `ContextualCheckInputs`/`VerifyCoinImport` is in the `else` branch only.
   - v6.0.10 `ConnectBlock` → `if (tx.IsCoinBase())` with the comment "Only the coinbase may skip input validation here" — fixed.
   - Mempool path: `AcceptToMemoryPool` calls `ContextualCheckInputs` unconditionally (v6.0.9 line 2368); `ContextualCheckInputs` calls `VerifyCoinImport` for `IsCoinImport` (lines 3262–3267); `VerifyCoinImport` requires `EVAL_IMPORTCOIN` + signature (`src/importcoin.cpp:440`).
2. **Upstream regression test**: the fix commit adds `ExpectForgedImportBlockRejected` in `src/gtest/test_block_connect.cpp`, constructing a forged import (`prevout.n = 1000000000`, arbitrary output, optional bogus payload) and asserting `ConnectBlock` rejects it with `invalid-coin-import`. This is the project's own PoC; we did not rebuild the C++ node (hours of Rust/Equihash deps), so we rely on the upstream test plus the static diff.
3. **On-chain verification**: explorer `stats.json` (total supply 278.807756M, 139.4% of cap) and `history.json` (daily pool balances) show the two jumps: **+39,822,234** on 2026-10-14 and **+40,000,358** on 2026-10-16. The pre-mint baseline (2026-10-13) is **198,984,641**.
4. **CI**: `ci/run.sh` re-runs the source checks, recomputes the mint deltas from `history.json`, checks the peer-version buckets, exit-rail flags and economics, and writes `ci-out/verification.json` (15/15 checks PASS locally). CI run: https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39342090783 (15/15 checks PASS; artifact `result-pirate-chain`).

---

## 7. Verdict, residual risk, blockers

**Verdict:** **E-U-conditional, miner-only.** The mint is live and cheap on unpatched nodes, but **$0 is extractable today** because every CEX deposit rail is closed and no verified instant-swap/bridge exists. The on-chain damage is **~79.8M ARRR (~$19.60M notional)**, not 39.8M; the supply is **139.4% of the 200M cap**. If a venue reopens on the legacy chain, the realistic capture is **~$1.0–2.9M** after liquidity/freeze/fork haircuts, with high race risk. If the hard fork activates first, the forged coins are worth **$0**.

**Residual/latent risk:**
- **Patch adoption is only 17.5% of sampled peers.** 28/57 peers are on vulnerable 6.0.0–6.0.9; any of them can mine another forged block. The second +40M mint on Oct 16 shows the bug was exploited again **after** the public disclosure.
- **Network split:** the explorer follows the invalid chain; the patched peers are elsewhere; only 6/57 peers are on the explorer tip. A venue's chain choice determines whether a new mint is creditable.
- **Hard fork undefined:** the announced fork has no height/date; the v6.0.10 reindex may cause a messy split. If the fork is not coordinated, the legacy chain could persist and the forged supply could become fungible again.
- **Liquidity:** even if all three CEXes reopened, the book depth ($16–25k) and $509k/day volume cannot absorb $19.6M; the price would collapse. The attacker's best case is a slow OTC sale at a steep discount, not a market dump.
- **Attribution:** the second mint's 20M transparent output is potentially traceable; the first mint's coins are shielded. A law-enforcement/exchange freeze could catch the transparent leg.

**Blockers (why $0 live):**
1. Gate `deposit_disabled=true`, `withdraw_disabled=true`.
2. MEXC deposits/withdrawals suspended at project request (Oct 15).
3. NonKYC `depositActive=false`, `withdrawalActive=false` ("By request of the Pirate Chain devs"); first depositor frozen.
4. No native-ARRR ChangeNOW pair; Godex does not list ARRR; other instant swappers unverified/key-gated.
5. vARRR/Verus bridge hacked (May 2026); AtomicDEX thin/unverified; Base "ARRR" is a 1B-supply impostor.
6. Hard-fork/reindex risk and chain split; the legacy chain may be orphaned at any time.

---

## 8. Methodology, sources, caveats, files

**Method:** read-only. Source fetched from `raw.githubusercontent.com/PirateNetwork/pirate` at tags `v5.9.3`, `v6.0.9-53cfa71`, `v6.0.10-a262cf4`; commit/release metadata from the GitHub API. On-chain data from the official explorer `explorer.piratechain.com/stats/stats.json` and `history.json` (fetched via `r.jina.ai` because the origin is Cloudflare-protected; the JSON is the explorer's own full-node data). Exchange status from Gate's public API, NonKYC's market page state, MEXC's public announcement, ChangeNOW's public estimate API, and Godex's public coin list. Price from CoinGecko. Mining economics from the explorer's `networkSolps`/`difficulty`/`avgBlockSeconds` and NiceHash's public Equihash market price (0.57–0.63 BTC/GSol/day; BTC ≈ $82k). No transactions, no wallet, no keys, no keyed RPC URLs.

**Sources (primary):**
- Fix commit: https://github.com/PirateNetwork/pirate/commit/da4e6252a3f9273ed757554fe3ffb154556f45b8
- v6.0.10 release: https://github.com/PirateNetwork/pirate/releases/tag/v6.0.10-a262cf4 (published 2026-10-18 23:48:59Z, mandatory reindex)
- v6.0.11 release: https://github.com/PirateNetwork/pirate/releases/tag/v6.0.11-d9a9312 (2026-10-19 21:19Z, networking only)
- Official incident update: https://x.com/PirateChain/status/2110774266123767871 (2026-10-15 16:46Z, 39.8M, two validation failures, shielded, NonKYC restricted)
- Explorer stats: https://explorer.piratechain.com/stats (total 278,807,756; 139.4%; 1.921 MSol/s; 57 peers)
- Explorer history: https://explorer.piratechain.com/stats/history.json (daily pools; +39,822,234 on Oct 14; +40,000,358 on Oct 16)
- MEXC suspension: https://www.mexc.com/announcements/article/suspension-of-arrr-deposits-and-withdrawals-17827791539150 (2026-10-15)
- NonKYC market: https://nonkyc.io/market/ARRR_USDT (`depositActive:false`, `withdrawalActive:false`)
- Gate API: https://api.gateio.ws/api/v4/spot/currencies/ARRR
- ChangeNOW estimate: https://vip-api.changenow.io/v3/exchange/estimate (native ARRR unsupported; BSC pair unavailable)
- TokenPost hard-fork plan: https://www.tokenpost.com/news/technology/34157 (no height/date as of 2026-10-17)
- Public coverage of first mint: The Defiant, Crypto Times, Crypto Briefing, Blockchain Breaches (all 39.8M; none report the second +40M)

**Caveats:**
- The explorer's data is **9 hours stale** at read time; the chain may be split. The total supply and daily deltas are the explorer node's pool sum, not an independent UTXO audit by us.
- The **second +40M** is our on-chain inference from the daily pool jump. It is not in any public report we found. A full-node block scan / UTXO audit should confirm the exact txids; the block pages are client-rendered and were not scrapeable in this pass. If it is an indexer correction rather than a mint, the total supply is still 278.8M, but the "two mints" attribution would change.
- The peer sample is 57 peers seen by one explorer node, not a network census; the 17.5% patched share is a **sample**, with selection bias.
- NiceHash rental prices are an external market snapshot (Oct 17–18, 2026); actual rental cost/liquidity varies. The cost conclusion (<$1/block) is robust across a 10× range.
- Realizable value is a judgment, not an on-chain quantity; the $1.0–2.9M band is 5–15% of notional and is **low confidence**.
- No transactions were signed or sent; no exchange accounts, no KYC, no OTC contact.

**Files:**
```
pirate-chain/
├── README.md                     # this report
├── summary.json                  # machine-readable summary
├── analysis/
│   ├── build_evidence.py         # recomputes supply/mints/peers/economics
│   ├── computed-summary.json     # generated numbers
│   ├── onchain-supply-daily.csv  # daily pool balances, Sep 25–Oct 17
│   ├── peer-versions.json        # 57-peer version distribution
│   ├── economics.json            # hashrate, block reward, rental cost
│   ├── liquidity.json            # notional, book depth, realizable band
│   ├── p2p_probe.py              # read-only P2P probe (TLS; peer closed; no tx)
│   └── evidence/                 # raw source, explorer JSON, exchange evidence
│       ├── main-v5.9.3.cpp / main-v6.0.9.cpp / main-v6.0.10.cpp
│       ├── jina-stats.json / jina-history.json
│       ├── stats-raw.html / explorer-stats.md
│       ├── gate-currency.json / gate-orderbook.json / gate-ticker.json
│       ├── mexc-orderbook.json / mexc-ticker.json
│       ├── nonkyc-market.html / exchange-rails.json
│       ├── coingecko.json / whattomine.json / github-releases.json
│       └── block-tip.md / block-ironwood.md (client-rendered; empty)
├── ci/
│   ├── run.sh                    # CI entry point
│   └── verify.py                 # 15 checks -> ci-out/verification.json
└── ci-out/
    ├── verification.json
    └── summary.txt
```

*Prepared 2026-10-20 · read-only research · no transactions, no secrets.*
