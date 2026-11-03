# Papertrade (HyperEVM 999) — 2026-11 escalation: contract set 2 re-verification

**Date:** 2026-11-03 · **Chain:** HyperEVM (chain 999) + HyperCore · **Status:** read-only; no transactions, no signatures, no keys; fork-free PoC + CI re-verification. **No mainnet transactions.**
**Prior record:** `README.md` (ZH3-C3, 2026-10-16) — same midpoint-oracle primitive, monitor with `tradingPaused=false`; the Oct-10/11 identical-design drain realised **$1.28M net**. This file **appends** to that record; nothing in the prior analysis is deleted or overwritten.

---

## 1. Verdict in one table

| CA2 claim | Re-verified at block 50,278,754 (2026-11-03 ~13:10 UTC) | Holds? |
|---|---|---|
| `lpBankrollAvailable()` = 4,669,398.5 @ 50,208,900; $4,912,307.74 @ 50,221,178 | Live: **$4,947,295.09**; indexer `lp` = **$4,946,690.87** @ 50,278,469. At both CA2 blocks the contract returns **$4,946,326.83** (public RPC + Etherscan proxy agree). The two CA2 figures are **not reproducible** and differ from each other by $242,909. | Magnitude yes; exact figures **no** |
| `totalQueued()=0`; `tradingPaused()=false` | `totalQueued=0`, `queueHead=4`; indexer queue `{total:"0",count:0}`; `tradingPaused=false` | **Yes** |
| Exchange has BBO-mid selector `0xc0182669` but no `getMarkPrice`/`getOraclePrice` selector and no mark/oracle precompile push ⇒ no deviation breaker possible | Current impl `0x0A44049d…` (23,959 B, keccak `0x1fcb8043…`): `c0182669` ×1; `a066fae9` ×0; `2af78bd1` ×0; `610806/610807/61080e` ×0. Live mid = floor((bid+ask)/2) on assets 0/1/2. Docs (current, set 2): *"the pricing pipeline has no independent reference price against which to reject the quote."* | **Yes** (on the **new** impl too) |
| Relayer is an open pipe (`authorizedRelayers(0xc916e55b…)=1`); session-key registration permissionless (969 owners/1,000 events; 748 owners/6,000 batches) | Both relayers authorized. 1,000 recent `251fb27d` txs in 3,116 blocks, all from `0xc916e55b…`; 906 opens / 856 closes decoded from 2,000 txs; 183 distinct embedded owners in 3.5 h. **≥12,000 sampled `SessionKeyRegistered` events / 5,406 distinct owners** over 1.2 M blocks; 1,000/957 in the last 100 k. Newest registration stores `agent = address(0)`. | **Yes** |
| $4.9M is payable | **Gross free-LP cash, not net.** At live OI caps the maximum full-cap single-market sweep nets **+$4,248** (ETH long, 10 bp); everything else is negative. | **No — gross ≠ net** |

**Net answer:** **E-U now = $0 (high confidence).** **E-U conditional = $0–0.5M realistic**, hard ceiling $4.947M but requiring $0.57–4.49 B of notional; **H-O = $0, P = $0, S = $0**. The $4.947M is **gross**; the net ceiling at today's caps is **≈ $0–4 k per full-cap sweep**.

---

## 2. What changed since the ZH3-C3 monitor (2026-10-16)

| Item | ZH3-C3 (block 48,648,947) | Now (block 50,278,754) |
|---|---|---|
| Exchange impl | `0x0f3febfc…` (23,052 B) | **`0x0a44049d…` (23,959 B, keccak `0x1fcb8043…`)** — contract set 2, upgraded **2026-10-21**, tx `0x4410b81e3eb76f83f5ddc4e3faee794fb67208d2f129bc013094b9d06055acb6` |
| Oracle impl | `0x3997ffc8…`, keccak `0x75f094da…` | **byte-identical** (2,475 B, same hash) |
| BatchExecutor / SKM impl | `0xe0bc9cc7…` / `0x0a2db5c7…` | **unchanged** |
| `tradingPaused` | false | false |
| `lpBankrollAvailable` | $4,958,944.58 | **$4,947,295.09** |
| OI headroom | BTC $4.3–9.0 M / ETH $7.0–8.6 M | **BTC $1.25–1.89 M / ETH $0.67–2.21 M** (27-min series; medians $1.50 M / $1.00 M) (~5× tighter) |
| `totalLockedMargin` | $9,606,525 | **$3,563,111** |
| `totalBalances` | $52,077,287 | **$17,781,507** |
| `totalQueued` / `queueHead` | $0 / 4 | **$0 / 4** |
| Per-account OI cap | not measured | **$10,000,000** (`accountOiCapRaw`) |
| Off-hours payout curve | not present (set 1) | **active** (`offHours=true`): holdback band 0.3–10 bp, max ≈2 bp at 4.2 bp; **zero above 10 bp** |
| Fee rates | 2% / 2% / 2% | **2% / 2% / 2%** (unchanged) |

**The implementation changed, the oracle primitive did not.** Contract set 2 adds a small-move holdback curve, a bust-price close, builder-code fees and a staker-fee push; none of these adds an independent reference price or a deviation breaker. The load-bearing claim therefore survives the upgrade.

---

## 3. Live state (atomic, single block)

All figures below are `eth_call`/`eth_getStorageAt` at **block 50,278,754** unless noted; artifact `analysis/escalation_snapshot.json`.

| Item | Value | Selector |
|---|---|---|
| Exchange proxy → impl | `0x6cd5661646289fb6e65ea5c032310fded797d0a2` → **`0x0A44049dBbb6b4762a6ba37aa0f7548c0B4A3723`** | EIP-1967 |
| Exchange impl size / keccak | **23,959 B / `0x1fcb80437ee76e0a495223b0aef8aecf74a4742b9fb7df18752354cd7e2877e0`** | `eth_getCode` |
| Oracle proxy → impl | `0xa9B4c7b7…` → **`0x3997ffc8cbd281d4fc8d0548e505ae2fbbbd985a`** (2,475 B, keccak `0x75f094da…`) | EIP-1967 |
| BatchExecutor impl | `0xe0bc9cc7b067060aafccbaa3e250700c9cdd7262` | EIP-1967 |
| SessionKeyManager impl | `0x0a2db5c7614b714fd9ec12b29bff3b4f4c545d82` | EIP-1967 |
| `tradingPaused()` | **false** | `0x53e23e2e` |
| `lpBankrollAvailable()` | **4,947,295.09 USDC** (18-dec internal) | `0x0cdd5fc4` |
| `totalQueued()` / `queueHead()` | **0 / 4** | `0x53ac4b66` / `0x96523644` |
| `totalLockedMargin()` | **3,563,111.33 USDC** | `0x01ad056f` |
| `totalBalances()` | **17,781,506.63 USDC** | `0xa69a2ad1` |
| `winFeeRate` / `lossFeeRate` / `liquidationFeeRate` | **2% / 2% / 2%** | `0x48ee5e08` / `0xf1a8786c` / `0x5fb3b1b5` |
| `nextPositionId()` | **2,086,723** (2,076,042 on 2026-11-02 ⇒ ~10.6 k positions/day) | `0x899346c7` |
| `collateralScale()` | **1e12** (6-dec native USDC → 18-dec internal) | `0xec0bdcfc` |
| `treasury()` | `0x15c215f722f79a34cb5c00` at this block (rotates; vanity CREATE2 deposit proxy) | `0x61d027b3` |
| `owner()` | `0xB915Fa41e824D6aA31BB833Ee81220C0F2c8EA0F` (7-day timelock) | `0x8da5cb5b` |
| `pauseGuardian()` / `marketKeeper()` / `authorizedKeeper()` | `0x69629276…` / `0x3721476d…` / `0x0924736b…` | — |
| Indexer `lp` / queue | **$4,946,690.87** @ 50,278,469; queue **total 0, count 0** | public `GET /query/protocol/summary`, `/query/protocol/queue-summary` |

### 3.1 Reconciliation of $4.669M vs $4.912M vs $4.947M

- CA2 quotes **4,669,398.5 @ 50,208,900** and **$4,912,307.74 @ 50,221,178** — a $242,909 jump in ~12,278 blocks (≈4.7 h).
- At those exact blocks, **both** the public RPC (`rpc.hyperliquid.xyz/evm`) and Etherscan V2's archive proxy return **4,946,326.83** for `0x0cdd5fc4`. The current value is **4,947,295.09**.
- The public RPC's historical `eth_call` is demonstrably inconsistent: `nextPositionId()` at block 50,208,900 reads **2,086,676**, while a *later* block (50,277,105) reads **2,086,491** — a monotonic counter cannot go backwards. Historical reads therefore cannot be used to adjudicate CA2's figures.
- The same indexer summary reports **$74,130.51 of pending fees** (`fees.pending`), so the truly free pot net of accrued fees is ≈ **$4.873 M** — immaterial to the verdict (it changes none of the ratios below).
- **Finding:** the **order of magnitude ($4.9 M) is correct**, the **exact CA2 figures are not reproducible**, and the two figures are mutually inconsistent as `lpBankrollAvailable()` values. Treat the live number — **$4,947,295.09** — as authoritative. This does not change the verdict: the pot is ~$4.95 M either way.

---

## 4. No deviation breaker — re-verified on the current implementation

**Byte scan** (`analysis/escalation_snapshot.json.selector_scan`, `poc/test/Escalation.t.sol::test_E1`):

| pattern | occurrences in `0x0a44049d…` | meaning |
|---|---|---|
| `c0182669` | **1** | `getMid(asset)` — the only price the trade path reads |
| `a066fae9` | **0** | `getMarkPrice` (precompile `0x0806`) |
| `2af78bd1` | **0** | `getOraclePrice` (precompile `0x0807`) |
| `610806` / `610807` / `61080e` | **0 / 0 / 0** | no direct PUSH2 of the mark/oracle/BBO precompiles |
| `fb466481` | 1 | raw `getBBO`, used by `pauseMarket` (freezes the pair) |
| `ec6783f0` / `2792e706` | 1 / 1 | open / close entries |

**Live behavioural check** (same block, one batch): asset 0 `(773,730 + 773,820)/2 = 773,775`; asset 1 `(228,160 + 228,170)/2 = 228,165`; asset 2 `(14,390 + 14,393)/2 = 14,391` (floor). The oracle returns exactly the half-sum with no clamp; a +1,018 bp uncrossed book is accepted (PoC `test_E2`). There is **no independent reference price anywhere in the Exchange**, so a deviation/TWAP/lookback breaker is not merely absent — it cannot be computed on this path.

**Docs corroboration (current version, contract set 2):** *"This is a real residual risk: the pricing pipeline has no independent reference price against which to reject the quote."* and *"A manipulated but non-zero, uncrossed BBO can still pass the oracle."*

**Disassembly of the call site (extra check):** the single `PUSH4 0xc0182669` sits in an internal `_readMid` routine (`0x5ba1–0x5c0a`). The only storage read before the `STATICCALL` is a packed word at `keccak(assetId, 0x23)` tested for a **pause/retire flag**; if set, the routine loads the stored `frozen_bid`/`frozen_ask` (shifts 72/8 bits) and computes their midpoint. There is no second price read and no comparison against a reference — the only branch is live-mid vs frozen-mid.

**Oracle impl unchanged:** `0x3997ffc8…` is byte-identical to the 2026-10-15 snapshot (keccak `0x75f094da…`), so the primitive is not a contract-set-2 regression — it is the same design.

---

## 5. The unprivileged path — still open, no per-account policy visible

1. **Relayer key gate (on-chain, not a user gate).** `authorizedRelayers(0xc916e55b…)=true`, `authorizedRelayers(0xe726b15c…)=true`, all others probed false; the setter is owner-only (owner = timelock). The venue's relayer is a **shared, multi-tenant pipe**: **1,000 recent `251fb27d` batches in 3,116 blocks (~1.7 h), 100% from `0xc916e55b…`**; decoding 2,000 sampled recent txs yields **906 opens / 856 closes** and **183 distinct embedded owner addresses in ~3.5 h**. Live trade feed shows retail-sized flow (median open **$8,040**, max **$800,000**, leverage 100–1000×).
2. **Session-key registration is permissionless in practice.** **≥12,000 sampled `SessionKeyRegistered(address,address,uint64)` events over 1.2 M blocks / 5,406 distinct owners** (last 100 k blocks: 1,000 events / 957 owners). Newest: owner `0xc91061d1…`, key `0x1e408716…`, expiry `1,796,238,457`; `sessionKeys(owner,key) = (expiry, agent = 0x0000…0000)`. The stored builder/agent is **address(0)**, so the BuilderRegistry gate does not bind and no 0.5% builder fee is paid.
3. **The public submission surface has no account allowlist.** The venue publishes a Rust SDK (`df-papertrade-core 0.0.11-beta`, 2026-10-21) and a public relayer at **`https://exchange.papertrade.xyz`**; submission is **`POST /intents`** with a signed intent. The only documented off-chain control is an **`Origin`-header check** (*"A request with a foreign `Origin` header gets a 400, so a browser page on another origin must go through its own server"*) — a CORS-style control, **not authentication**; any server-side client can satisfy it. Verified live: `GET /state/trading` with `Origin: https://example.com` returns **HTTP 400**, with the venue origin **HTTP 200**. The public `GET /state/trading` publishes `intakeControls = [revision 1793510630386810, paper_stake_minimum 1,000e18, paused = []]` — **no action is paused and there is no per-account allowlist field**. `accountOiCapRaw = $10,000,000`; `minimumOpenNotionalRaw = $500`; `minimumTradeSizeRaw = $10`; `offHours = true`.
4. **Builder/agent = `address(0)`** for the sampled live registrations; the venue's own docs say papertrade.xyz leaves the builder empty.
5. **Conclusion:** an ordinary funded EOA can sign a session-key registration and a signed open/close intent and have it relayed. The remaining unverifiable gate is a **server-side relayer policy**; nothing in the on-chain state, the public intake state, the SDK, or the docs evidences one. We did **not** POST an intent (read-only mandate), so this remains a residual caveat, not a blocker we can prove away.

---

## 6. Economics — why $4.9 M gross is not $4.9 M net

### 6.1 The live caps (the real ceiling)

`instruments(uint32)` has **no OI-cap field**; the caps live in packed storage (mapping base `0x24`, slot+1) and are set by the keeper's `setOiCaps` (`0x628a9fd6`). The public `GET /state/trading` mirrors them and is the cleanest source. At block 50,278,754:

| market | long cap | long cap $ | short cap | short cap $ | long headroom | short headroom |
|---|---|---|---|---|---|---|
| BTC | 642.72 BTC | **$49.71 M** | 192.82 BTC | **$14.91 M** | $1.39 M | $1.31 M |
| ETH | 14,875.45 ETH | **$33.94 M** | 6,859.62 ETH | **$15.65 M** | $0.98 M | $1.01 M |
| **total** | | **$83.64 M** | | **$30.56 M** | | |

The `instruments()` struct decodes cleanly as 8 words — `rateMultiplier 15000`, `positionMultiplier 814.598 (BTC) / 483.979 (ETH)`, `assetIndex`, `maxLeverage 1000`, `maxPositionNotional $10 M`, `bustBuffer 4.76/4.81 bp`, `baseRate 10%`, `referenceNotional $100 k`. The caps are **not** in it; CA2's failure to decode them there is expected.

**The keeper's live policy is ~$1 M of headroom per side**, not the docs' launch language of "$1 billion" (the docs page still says $1 B / $900 M–$1.1 B hysteresis; the live values are ~1,000× tighter). In a **27-minute live series (block 50,277,698–50,279,364)** the keeper made **31 cap changes** in steps of **$0.17–2.14 M** (median ≈$0.25 M), and it trails OI 1:1 — when ETH long OI rose 576 ETH, the long cap rose 567 ETH. This is a **rate limiter**, not a fixed ceiling.

### 6.2 Payout per $1 M of notional (docs' impact curve, live params)

`adjustedPnl = rawPnl × scale`, `scale = 0.9 / (1 + 1/(move·15000) + 100,000/(1e6·move·mult))`, then ×0.98 win fee. `move` is after the 0.2 bp deadband and the off-hours holdback (zero above 10 bp).

| move | BTC $/1 M | ETH $/1 M |
|---|---|---|
| 10 bp | 724 | 676 |
| 15 bp | 1,157 | 1,102 |
| 30 bp | 2,471 | 2,408 |
| 60 bp | ~5,112 | ~5,112 |
| 100 bp | ~8,660 | ~8,660 |

**The 2% "loss fee" is not a cost to a winning attacker.** It is carved from the LP's gain when the *trader* loses. On a winning close the only protocol charge is the 2% win fee (already in the 0.98 factor). CA2's "minus 2% win fee, 2% loss fee" double-counts a fee the attacker does not pay on a win.

### 6.3 The live cost to move the BBO (the other side of the ledger)

Cross-and-rest (mech B), taker unwind, 4.5 bp HL taker, live books at BTC 77,316.5 / ETH 2,280.45 (`analysis/escalation_cost.json`):

| move | BTC up | BTC down | ETH up | ETH down |
|---|---|---|---|---|
| 10 bp | $51.9 k | $61.2 k | $18.7 k | $29.4 k |
| 15 bp | $83.5 k | $99.4 k | $35.1 k | $46.5 k |
| 30 bp | $214.1 k | $183.7 k | $84.3 k | $102.1 k |
| 60 bp | $692.3 k | $406.2 k | $310.9 k | $311.8 k |
| 100 bp | $1,225.8 k | $831.4 k | $635.4 k | $638.6 k |

### 6.4 Full-cap sweep — the maximum the contract can pay

If an attacker captured the **entire long cap of one market** (the most favourable case; the keeper would have to stand still), the payout and cost are:

| market/side | N | 10 bp payout | cost | net | 15 bp payout | cost | net |
|---|---|---|---|---|---|---|---|
| BTC long | $49.71 M | $36,004 | $51,883 | **−$15,879** | $57,522 | $83,476 | **−$25,954** |
| BTC short | $14.91 M | $10,801 | $61,192 | **−$50,391** | $17,257 | $99,408 | **−$82,151** |
| ETH long | $33.94 M | $22,939 | $18,691 | **+$4,248** | $37,397 | $35,121 | **+$2,276** |
| ETH short | $15.65 M | $10,578 | $29,438 | **−$18,860** | $17,245 | $46,534 | **−$29,289** |

- **Best case across all full-cap single-market sweeps: +$4,248** — **0.086%** of the $4.947 M bankroll, inside the ±10–30% book-model error.
- **Both markets at 15 bp:** payout **$94,919** vs cost **$118,602** → **−$23,683**.
- At 30 bp the largest payout ($122,836 BTC long) still costs $214,109; at 100 bp the largest payout ($429,377) costs $1,225,783.
- **The dominant constraint is the OI cap, not the LP bankroll.** Total long caps are **$83.6 M**; total short caps **$30.6 M**. Even capturing all of them at 15 bp pays **$94.9 k** against **$118.6 k** of book-move cost.
- The $10 M **per-account** OI cap makes even the full-cap sweep a multi-account operation: 5 accounts for BTC long ($49.7 M), 4 for ETH long ($33.9 M). The $4.3 B notional needed to drain the bankroll at 15 bp would require ~430 accounts at the cap.

### 6.5 What draining the $4.947 M would take

| move | BTC notional needed | ETH notional needed |
|---|---|---|
| 15 bp | **$4.28 B** | **$4.49 B** |
| 30 bp | $2.00 B | $2.05 B |
| 60 bp | $0.97 B | $0.98 B |
| 100 bp | $0.57 B | $0.58 B |

Those notionals are **7–50× the entire current long cap** ($83.6 M) and **32–250× the venue's total balances** ($17.8 M). The $4.947 M is a **gross payable pot**, not an achievable net.

### 6.6 The conditional path (keeper refills)

If the keeper keeps trailing caps at ~$1 M per event, an attacker can stack. Break-even notional (cost ÷ payout-per-$1):

- ETH 10 bp: **$27.7 M**; ETH 15 bp: **$31.9 M**; ETH 30 bp: **$35.0 M**.
- BTC 10 bp: **$71.7 M**; BTC 15 bp: **$72.2 M**; BTC 30 bp: **$86.7 M**.

At N = $100 M, a 10 bp ETH cycle pays **$67.6 k** against $18.7 k cost → **+$48.9 k**, before hedging. Accumulating $100 M at ~$1 M per 20–30 s takes **~35–50 min** of uninterrupted keeper refills, with the position exposed to natural drift and with the team's keeper explicitly monitoring BBO/OI. A $0.1–0.5 M single-session take is possible only in the best case; the prior monitor's $0.1–2 M is **too optimistic** for today's ~$1 M headroom (it was written against $4.3–9.0 M headroom).

---

## 7. Payout queue — no backlog

`totalQueued() = 0`, `queueHead() = 4`, and the public `/query/protocol/queue-summary` returns `{total:"0", count:0}` at block 50,278,469. A first-cycle win is therefore **immediately payable**, not deferred. The FIFO queue binds only once free LP cash is exhausted; it is empty today.

---

## 8. Fork/simulation status — exact limiting step

- **Done (fork-free, real bytecode):** `poc/test/Escalation.t.sol` — 6 tests: current Exchange impl hash + selector scan (E1), current oracle hash + half-sum/displaced-book behaviour (E2), and the full-cap economics (E3). `forge test` **6/6 PASS** (CI re-run recorded in `ci-log.txt`).
- **Not possible on an EVM fork:** the price input is the **HyperCore BBO precompile `0x080e`**, an L1 read of the off-EVM order book. An anvil fork of HyperEVM cannot reproduce a manipulated HyperCore book; the manipulation is a HyperCore order-book action (place/cancel/sweep), not an EVM transaction. The exact limiting step is therefore **off-EVM**: the attacker must move Hyperliquid's BBO, and that cost is measured from live L2 books (§6.3), not simulated on the EVM fork.
- The Papertrade leg itself is deterministic given the mid; the impact-curve formula was validated against real close events in the prior record (`pid 874527`: logged adjusted 22.948697 vs model 22.9484; `pid 873510`: full raw loss, no scaling).

---

## 9. Categories and confidence

| Category | USD | Confidence | Basis |
|---|---|---|---|
| **E-U (now)** | **$0** | **high** | Full-cap sweep max **+$4,248**; 3 of 4 15 bp sweeps negative; both markets at 15 bp **−$23,683**; $4.947 M needs $0.57–4.49 B notional |
| **E-U (conditional)** | **$0–0.5 M** realistic; hard ceiling **$4,947,295** | **medium-low** | Requires keeper to keep trailing ~$1 M/event, accumulation to $30–100 M over 0.5–1 h undetected, plus a 10–30 bp book move; the hard ceiling needs $0.57–4.49 B notional and is not achievable before a pause |
| **H-O** | **$0** | high | User balances/positions are user-controlled; withdrawals are wallet-signed; no stuck value found |
| **P** | **$0** | high | Owner/guardian can tune fees/params, pause/retire markets; no path to seize user balances |
| **S** | **$0** | high | No bricked value found; queue empty; markets live |

**What would change the verdict:** (a) the keeper re-widening the target headroom toward the documented $1 B (a 1,000× change) — the single biggest trigger; (b) a cap-policy change that stops trailing OI; (c) a thin-book regime cutting the 15 bp cost below ~$35 k; (d) evidence of a relayer-side per-account policy (we could not drive an end-to-end intent read-only).

---

## 10. Delta vs the $1.28 M monitor

- The **$1.28 M was realised** on 2026-10-10/11 at the launch headroom (~$1 B/side): 15–20 bp × ~$1 B × impact curve ≈ $1.1–1.5 M, consistent with the observed figure.
- Today the same recipe at **$1.0–1.6 M/side** pays **$1.1–1.8 k per $1 M** and costs **$35–99 k** to move the book — a **20–90× negative** ratio. The pot is **$4.947 M (3.9× the realised drain)**, but the **notional that can reach it is 7–50× the entire OI cap**.
- **Monitor update:** keep the row, but change the conditional estimate from **$0.1–2 M** to **$0–0.5 M**, and add the live headroom (~$1 M/side) and the $10 M per-account cap to the watch list. The primitive is unchanged; the **mitigation is still a rate limiter, not a redesign**.

---

## 11. Watch triggers

- `lpBankrollAvailable()` / `totalQueued()` / `queueHead()` — pot and backlog.
- Per-side headroom `cap − OI` (relayer `/state/trading`): alert if **sustained > $35 M ETH or > $70 M BTC** (the break-even zone).
- Keeper `setOiCaps` cadence/step size (authorizedKeeper `0x0924736b…`, marketKeeper `0x3721476d…`); a step > $5 M or a target change toward $1 B.
- `pauseMarket` / `setTradingPaused` by guardian `0x69629276…`; a retirement freezes the BBO at the retirement price (kills the attack).
- Exchange impl slot/hash change (current `0x0a44049d…` / `0x1fcb8043…`); any new reference-price selector.
- Oracle impl slot/hash (`0x3997ffc8…` / `0x75f094da…`).
- `authorizedRelayers` set, SKM impl, builder registry.
- Off-hours curve schedule (`offHours`) — a switch to the standard curve marginally improves small-move payouts, but 15 bp+ is unaffected.

---

## 12. Method and artifacts

- **Live reads:** `eth_call` / `eth_getStorageAt` / `eth_getCode` on the public keyless RPC `https://rpc.hyperliquid.xyz/evm` (chain 999), pinned to block **50,278,754**; Etherscan V2 (chainid 999) for txlists/logs and the archive `eth_call` cross-check; public `https://exchange.papertrade.xyz` `/state/trading`, `/query/protocol/summary`, `/query/protocol/queue-summary`, `/query/protocol/trades/recent`; `api.hyperliquid.xyz/info` for L2 books; docs.papertrade.xyz (current, contract set 2) and docs.rs `df-papertrade-core 0.0.11-beta`.
- **Artifacts:** `analysis/escalation_snapshot.json` (atomic state + selector scan + instruments), `analysis/escalation_state_trading.json` (public intake/caps), `analysis/escalation_cost.json` (live book-move cost), `analysis/escalation_econ.json` (full-cap table), `analysis/escalation_oi_poll.jsonl` (headroom series), `poc/test/Escalation.t.sol` (6 tests), `poc/data/*.hex` (live impl bytecode).
- **CI:** `ci/run.sh` runs the original ZH3-C3 snapshot (10-min headroom series, economics) **plus** the escalation snapshot/cost/econ and `forge test`; results in `ci-out/` and `ci-log.txt`. Run URL recorded in `summary.json`.
- **Read-only guarantee:** no transaction was signed or sent; no key was used; no keyed URL or secret is written in this folder. Historical `eth_call` on the public RPC is documented as load-balancer-inconsistent (a monotonic counter read backwards), so only latest-block reads are treated as decisive.

*This file appends to `README.md`; it does not replace the ZH3-C3 analysis.*
