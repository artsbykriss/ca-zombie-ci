# EtherVista (Ethereum) — Historical Router Flips & 2026-10-09 Drain
**Z3-C5 deep-dive, history sub-audit — READ-ONLY investigation**

- **Scope owner / date:** subagent report, 2026-10-16. All data fetched read-only (Etherscan V2 API + public RPC `ethereum-rpc.publicnode.com`). No transaction was signed or sent.
- **Key actors**
  - Factory: `0x9a27cb5ae0B2cEe0bb71f9A85C0D60f3920757B4` (1,087 pairs; `getPair(WETH,VISTA)`-style, `PairCreated` events) — itself **created by the routerSetter EOA** (tx `0x4199c4e7…`, nonce 1, 2024-08-31 12:13:35).
  - `routerSetter` EOA: `0xCA90D843288E35beeADfCe14E5F906e3F1AFc7cB` (deployer + fee recipient of the protocol; 657 outbound txs, nonce 0–656).
  - Target pair: `0xfdd05552F1377aA488AFed744c8024358AF02041` = WETH (`0xC02aaA39…56Cc2`, token0) / VISTA (`0xC9bCa88B04581699fAb5aa276CCafF7Df957cbbf`, token1). **The only WETH/VISTA pair under this factory** (see Task 2).
  - Attacker EOA (burner): `0xbbf8f3fe8e4fdf6b594e6107144d78293d2018fa`; attacker contract/router: `0x469424b628A9D2036e41496E814dB500d683b120`.
- **Latest read block:** 26,201,136 (2026-10-16). `factory.router()` = `0x9bD63C5D44fF28390df1EaaFD4eB4BD73E94A72a` (**unchanged since 2026-04-08**; briefly replaced twice on 2026-04-21 and for 3 minutes on 2026-10-09).

---

## Task 1 — The 12 historical routers: creation, verification, classification

All 12 are real contracts (code present; none is an EOA or proxy). Creation data from `getcontractcreation` + `getsourcecode` (raw JSON in `raw/creation_*.json`, `raw/source_*.json`).

| # | Router address | Created (UTC) | Created by | Creation tx | Verified? | Contract name | Classification | Active window (as `factory.router()`) |
|---|---|---|---|---|---|---|---|---|
| 1 | `0xeaaa41CB2a64b11FE761D41e747C032cdd60CACe` | 2024-08-31 12:18:35 | routerSetter | `0x415b53d1…b37693` | ✅ yes | **EtherVistaRouter** | **official v1** | 2024-08-31 12:37:35 → 2024-09-07 02:50:23 |
| 2 | `0xEad811d798020c635CF8DD4DDF31BDc5595b09f3` | 2024-09-07 02:27:35 | routerSetter | `0x56bb73aa…2c3174` | ✅ yes | **EtherVistaRouter** | **official v2** | 2024-09-07 02:50:23 → 2024-09-28 04:07:47 |
| 3 | `0xCEDd366065A146A039b92Db35756ecd7688Fcc77` | 2024-09-28 01:50:23 | routerSetter | `0xab142e6b…e628ad` | ✅ yes | **EtherVistaRouter** | **official v3** (long-lived) | 2024-09-28 04:07:47 → 2026-03-07 01:56:23 (interrupted 01:19–01:28 and 01:48–01:56) |
| 4 | `0x25B929E4dC4248858f4a874d076961070D88de04` | 2026-03-07 00:45:35 | routerSetter | `0x31e7b0f6…586b4a` | ❌ no | – | **test** (deployed 28 min before flip) | 2026-03-07 01:13:47 → 01:19:47 (6 min; no pair flows) |
| 5 | `0x13f2632393Ad736C8aAB9EEcCbbD8BcFE5bB5371` | 2026-03-07 01:25:47 | routerSetter | `0x82922e0e…8107a7` | ❌ no | – | **test** | 2026-03-07 01:28:35 → 01:48:47 (20 min; 1 test swap) |
| 6 | `0xA03626f924F550f615EbBbb6F024C250F9F0f3d4` | 2026-03-07 01:53:59 | routerSetter | `0xf771c149…15ae22` | ✅ yes | **EtherVistaRouter** | **official v4** | 2026-03-07 01:56:23 → 2026-04-07 18:42:23 |
| 7 | `0x2a27e4e1d2b97C5b8a2460df5342E0e9293D4fdf` | 2026-04-07 18:40:59 | routerSetter | `0x65085067…8155317` | ❌ no | – | **test** | 2026-04-07 18:42:23 → 19:43:23 (1 h; no pair flows) |
| 8 | `0xB7c6c50d6DFc478E7b40906f582E14575E7D895A` | 2026-04-07 19:29:35 | routerSetter | `0x3db5646a…b0d5aa98` | ❌ no | – | **test** | 2026-04-07 19:43:23 → 2026-04-08 02:29:35 (6 h 46 m; routed test swaps) |
| 9 | `0xDBF723f9Ee663fb643fB08F86829727f8140B2D6` | 2026-04-08 01:35:23 | `0xa2371a34a6b5f796f2e2a3da86c4a4479459bddf` ⚠️ *different deployer* | `0xd5bd09b7…4a73d87` | ❌ no | – | **test** | 2026-04-08 02:29:35 → 11:03:23 (8 h 34 m; routed test swaps) |
| 10 | `0x9Bd63C5D44Ff28390DF1eAAFd4EB4Bd73E94A72A` | 2026-04-08 10:56:35 | routerSetter | `0xf9f86913…cd33731` | ✅ yes | **EtherVistaRouter** | **official v5 — current** | 2026-04-08 11:03:23 → present (interruptions 2026-04-21, 2026-10-09) |
| 11 | `0xBC3902178A02939BA53a18C8Dd374a3Fc17F9c5C` | 2026-04-21 03:12:59 | routerSetter | `0xa852e2d7…c305dad` | ❌ no | – | **test** | 2026-04-21 03:13:47 → 03:14:59 (72 s; only `update()` called on it) |
| 12 | `0x469424b628A9D2036e41496E814dB500d683b120` | 2026-10-09 03:42:23 | `0xbbf8f3fe…18fa` (fresh burner EOA, nonce 0) | `0x3b7b1ba7…dbaf35ba` | ❌ no | – | **ATTACKER** | 2026-10-09 03:46:11 → 03:49:11 (180 s; drained 1 pair) |

Notes:
- All 17 `setRouter` txs carry selector `0xc0d78655` = `setRouter(address)` (verified locally with `cast sig`); all come from the routerSetter EOA. Full list incl. tx hashes further below (Task 3 timeline).
- The two `setRouter(0x13f2…)` calls on 2026-03-07 01:28:35 are two *successful* txs in the same block (nonces 557 & 559, with a USDC micro-payment, nonce 558, between them).
- `0xa2371a34…` (deployer of test router #9) also appears as a swap/LP counterparty in the Apr-7/8 test window — a second team-side operator address.
- `0x54cfcc2e…` (unverified "ERC" token emitting a mirror event after the attack) is NOT among the routers; see Task 4 notes.

---

## Task 2 — Did the Mar/Apr-2026 flip windows drain anything? — **No.**

Method: token-transfer history of the target pair `0xfdd05552…` restricted to each window (block ranges via `getblocknobytime`), plus net-flow math (out = transfers *from* the pair, in = transfers *to* the pair). Raw JSON: `raw/pair_tokentx_w1_mar07.json`, `…w2_apr07_08.json`, `…w3_apr21.json`, `…w4_oct09.json`; math in `raw/window_flows.txt`.

| Window | Block range | Txs in pair | WETH net (out−in) | VISTA net (out−in) | Finding |
|---|---|---|---|---|---|
| W1: 2026-03-07 01:00–02:30 (6 router flips) | 24,602,154–24,602,601 | 2 (both test swaps) | **−0.0002** (in) | **+0.22405812054985075** (out) | two 0.0001-ETH test buys via new routers 13f2/a036, VISTA delivered to routerSetter EOA; **no anomalous outflow** |
| W2: 2026-04-07 18:00 → 04-08 12:00 (4 flips) | 24,829,461–24,834,848 | 15 | **−5.149709303874554** (net *into* pool) | **−1022.1778004225337** (net *into* pool) | router iteration tests (swaps via b7c6/dbf7/9bd6, LP add/remove, small `0xdead` burns); every pair outflow is matched inside the same tx; **no drainage** |
| W3: 2026-04-21 02:45–04:00 (2 flips) | 24,925,384–24,925,758 | 2 | +0.1019334969636439 (out) | −120.516 (in) | two normal swaps by `0xad223df9…` **before** bc39 went live; during bc39's 72 s the pair saw **zero** transfers |
| W4: 2026-10-09 03:30–04:30 (attack + restore) | 26,152,169–26,152,469 | 8 | **+7.463792630603522 net out** | **+43,938.86073478394 net out** | the drain (exact numbers in Task 4/5) + attacker's micro-buys; see below |

**"Other WETH/VISTA pairs": none exist.** `getPair(WETH, VISTA)` returns `0xfdd05552…` (Uniswap-V2-style 1:1 mapping); `allPairsLength()` = 1087; `PairCreated` logs for token0=WETH = 268 pairs, of which exactly **1** has token1=VISTA (raw: `raw/logs_paircreated_weth_p1.json`). There is nothing else to check — the target pair is the *only* WETH/VISTA pool under this factory.

Exact drain-tx numbers (see Task 5 for the log-level detail):
- `WETH`: pair → attacker contract `21.365578479614736555`; attacker contract → pair `9.026956903960976779` + `4.860669107788601981`; attacker contract → attacker EOA `7.477952467865157795` ⇒ **net pair loss 7.477952467865157795 WETH**.
- `VISTA`: pair → attacker EOA `43,855.902196275763910452`; attacker EOA → pair `1 wei` ⇒ **net pair loss 43,855.902196275763910451 VISTA**.
- All values above are exact strings from Etherscan `tokentx` (`raw/attacker_tokentx.json`, `raw/pair_tokentx_w4_oct09.json`).

Window-level check: between `setRouter(attacker)` (03:46:11) and `setRouter(restore)` (03:49:11) the pair had **no other traffic** than the drain tx itself — and the malicious router contract received exactly **one** call in its entire lifetime (creation + drain; see Task 4).

---

## Task 3 — routerSetter EOA `0xCA90D843288E35beeADfCe14E5F906e3F1AFc7cB`

Raw: `raw/routerSetter_txlist.json` (885 rows, complete), `raw/routerSetter_txlistinternal*.json`.

### 3.1 Complete `setRouter` timeline (17 calls, all from this EOA; selector `0xc0d78655`)

| # | UTC | Block | Nonce | New router | Tx hash |
|---|---|---|---|---|---|
| 1 | 2024-08-31 12:37:35 | 20,648,599 | 3 | `0xeaaa41CB…` | `0x332d0c26b1ac56d610c3c721bebae79a7e3fb9c21f5ff3bb1405e5914e13f826` |
| 2 | 2024-09-07 02:50:23 | 20,695,841 | 123 | `0xEad811d7…` | `0x5471fb1c8815d907653d31a999081ef0c729a312bc904016f24833757b4ab373` |
| 3 | 2024-09-28 04:07:47 | 20,846,641 | 150 | `0xCEDd3660…` | `0xcb334bf42253bc28ca3a90b0694ebd7b421f59416e774491acac26254d1bee8e` |
| 4 | 2026-03-07 01:13:47 | 24,602,223 | 552 | `0x25B929E4…` | `0x15a8c3e7b0db0af4a1585310ec8b3e2110be26e50937d53c2b17bfc67f8bf168` |
| 5 | 2026-03-07 01:19:47 | 24,602,253 | 554 | `0xCEDd3660…` (back) | `0x406bc4370db901b1fc92ff70cb781a103cd5e81e0605f2001542636706320bd0` |
| 6 | 2026-03-07 01:28:35 | 24,602,296 | 557 | `0x13f26323…` | `0x502d9ae1cf9d8a005ea009c9c2fa0e5dc317d8cf5d10e84a79cdfb7d6b6df122` |
| 7 | 2026-03-07 01:28:35 | 24,602,296 | 559 | `0x13f26323…` (again) | `0xa4a6dee9c9ab0d49be66d04d5f11b0bc3907bfdb0202f5adc919b2e7b44be087` |
| 8 | 2026-03-07 01:48:47 | 24,602,396 | 562 | `0xCEDd3660…` (back) | `0x4383d1edab09529a6bd6f6d57222edb89080a8a38b4b8e7a5ae6a1f510d972c5` |
| 9 | 2026-03-07 01:56:23 | 24,602,434 | 565 | `0xA03626f9…` | `0xec47aa1b8c016449fbfa1a671578cc4201c71581d8e5a8f8e54072e67654f538` |
| 10 | 2026-04-07 18:42:23 | 24,829,672 | 590 | `0x2a27e4e1…` | `0x646a8910a42caa72045f02625497c0154f551fae10b29927f7f8fe4cebdb5fe6` |
| 11 | 2026-04-07 19:43:23 | 24,829,976 | 592 | `0xB7c6c50d…` | `0xc62875a4d19c0cae6248537b9ba3c9c585e8c97e66b1ccf6267c3531ec19f121` |
| 12 | 2026-04-08 02:29:35 | 24,832,001 | 594 | `0xDBF723f9…` | `0x904d980c1fced58841f02bdc2649986fa8a548d8c2964147f4d9963b1bbf197e` |
| 13 | 2026-04-08 11:03:23 | 24,834,565 | 599 | `0x9Bd63C5D…` | `0xb36da314885561961807b6cb18a1d332d516b47e9e4081e846cbc3c3e1b874b4` |
| 14 | 2026-04-21 03:13:47 | 24,925,527 | 611 | `0xBC390217…` | `0x83eec608ba34a2f7293d3d33a3fea3775eb78ba660ea8f494a660c8305cd3a7b` |
| 15 | 2026-04-21 03:14:59 | 24,925,533 | 613 | `0x9Bd63C5D…` (back) | `0xf73ddb067f6c6e459e51c654c19699e603a865e7092cd5536b0bf1162ff25108` |
| 16 | **2026-10-09 03:46:11** | **26,152,250** | 654 | `0x469424b6…` **[ATTACKER]** | `0xc97ad886a4cbd022edc33deaa44656d66814fe3df1142d03802c96ce7632cc7a` |
| 17 | 2026-10-09 03:49:11 | 26,152,265 | 655 | `0x9Bd63C5D…` (restore) | `0x7adfb703f74f7e46ce4b7d79f12b9a5310406e6f220ade5f8e8c6fc987226eda` |

### 3.2 ±24 h around every flip — what else did the key do?

- **2026-10-09 ±24 h (critical): ONLY txs #16 and #17.** No other activity whatsoever — no funding tx, no sweeps, no calls to any other contract, and **no interaction in either direction with the attacker contract (`0x469424b6…`) or the attacker EOA (`0xbbf8f3fe…`)** — checked in the EOA's full direct txlist and its internal-tx history (most-recent 1000 internal txs cover 2026-04-20 → 2026-10-14: 0 matches).
- 2024-08-31 ±24 h (launch day): deploy factory + router + first contracts, seed the pair, run `launch()`/buys (incl. one 10 ETH buy at 16:05), swap tests; USDC approvals.
- 2024-09-07 and 2024-09-28 ±24 h: deploy next router, set it, a handful of test calls.
- 2026-03-07 (W1): per flip the key: (1) received a 0.00016-ETH gas top-up from `0xb01caea8c6c47bbf4f4b4c5080ca642043359c2e`; (2) `setRouter`; (3) sent a **0.64 USDC micro-transfer to `0xe3478b0bb1a5084567c319096437924948be1964`** in the same block (6×, looks like an automated ops/log pattern); (4) one 0.0001-ETH test swap through the newly set router (13f2 at 01:30, a036 at 01:58).
- 2026-04-07/08 (W2): repeated ~1 gwei gas top-ups from a bot family (`0x96d5…89fee765`), router deployments, `setRouter`, then test swaps / `addLiquidityETH` / `safeTransferLp` / LP ops through each new router before settling on 9bd6.
- 2026-04-21 (W3): deploy bc39 03:12:59 → `setRouter(bc39)` → `bc39.update()` (`0xa2e62045`) at 03:14:23 → restored 9bd6 at 03:14:59 (72 s of exposure, zero pair traffic).
- **Post-attack (outside ±24 h): last-ever own tx = nonce 656, 2026-10-13 00:26:59** — 0.0235 ETH to `0x839a42a10a396ee5ec7c1f984fcd348fdb609b8e` (fresh EOA, nonce 1, now empty). The key still **receives ~0.0004-ETH fee payments from the current router** on every routed swap, including 2026-10-09 04:29-04:38, 10-10, 10-12, 10-14 (18 internal payments on/after Oct 9, all from `0x9bd63c5d…`).

### 3.3 Balance / nonce (read at block 26,201,077)

- ETH balance: **1,615,912,524,873,591 wei (0.001615912524873591 ETH)**
- Nonce: **657** (i.e., 657 outbound txs, nonces 0–656; last one 2026-10-13 00:26:59)
- First funds: 0.98238092 ETH on 2024-08-31 03:47:23 from **Binance 16** hot wallet `0xDFd5293D8e347dFe59E90eFd55b2956a1343963d` (Etherscan label).

### 3.4 `setRouterSetter` (`0xdd5819ad`) — never called

- 0 occurrences in the EOA's 885-row txlist; selector verified locally (`cast sig "setRouterSetter(address)"` ⇒ `0xdd5819ad`).
- 0 occurrences in the **factory's complete 21-tx history** (`raw/factory_txlist.json`). Confirmed: the setter address was never rotated via this EOA (or anyone else).

### 3.5 Notable counterparties (by tx count)

| Counterparty | Txs | What it is |
|---|---|---|
| `0x9099ef7f34dc1af0d27e49dc5b604bccc03dcb21` | 97 | "**HARDSTAKE**" (verified contract) — staking ops |
| contract creations (`to = null`) | 58 | factory, all routers, various helpers |
| `0xCEDd366065A146A039b92Db35756ecd7688Fcc77` | 46 | official router v3 |
| `0x96d5443082b8e1d5dbb96e8aa65ed30e89fee765` (+ `0x96d5…fee765` family) | 35 | bot/ops EOA — pays in USDC, sends 1-gwei gas top-ups |
| USDC `0xA0b86991…` | 31 | payments (incl. 0.64-USDC ops pattern) |
| target pair `0xfdd05552…` | 30 | `claimShare()` (`0x666da64f`) ×114 total etc. |
| VISTA token | 26 | approvals/transfers |
| official router v1 `0xeaaa41CB…` | 21 | |
| `0x1a97a037a120db530ddce8370e24ead0fe9cf5d0` | 18 | "**safeTokenFactory**" (verified) |
| factory | 17 | the 17 `setRouter` calls |
| Uniswap UniversalRouter `0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD` | 15 | ops swaps |
| gas top-ups in: `0xb01caea8c6c47bbf4f4b4c5080ca642043359c2e`, `0x96d5…89fee765` family, `0x4c5fbf8d…` (0.21 ETH) | – | funding bots / operators |

**No interaction with either attacker address exists anywhere in this EOA's history.**

---

## Task 4 — Attacker contract `0x469424b628A9D2036e41496E814dB500d683b120`

Raw: `raw/attacker_txlist.json`, `raw/attacker_tokentx.json`, `raw/drain_tx.json`, `raw/drain_receipt.json`, `raw/drain_logs_decoded.tsv`, `raw/attackerEOA_txlist.json`, `raw/attackerEOA_tokentx.json`, `raw/rpc_attacker_balances.txt`, `raw/rpc_flows.txt`.

### 4.1 Creation & funding chain

- **Created 2026-10-09 03:42:23 UTC, block 26,152,231**, tx `0x3b7b1ba7d633b1c4390a0c85312bd91836b715d7d290887bc4c39272dbaf35ba` by **`0xbbf8f3fe8e4fdf6b594e6107144d78293d2018fa`** — a **fresh burner EOA** whose first-ever tx (nonce 0) was this deployment. Code size ≈ 6.8 KB; unverified.
- The burner was funded **4 minutes earlier**: 2026-10-09 03:37:59, `0.04644843` ETH, tx `0xbbe324f8dd2ba2b91d428ab76704b74ea697771f136aa1778c98b68226a8f3ad`, from **`0x963737C550E70FFe4D59464542a28604eDb2eF9a`** (Etherscan label **"Union Chain"**, a blockchain-operations software provider; high-activity EOA, nonce ≈1.576 M at the time, ~187 ETH balance). No mixer involvement visible.
- Attacker contract tx history = exactly **2 txs**: creation + the drain call. Etherscan indexes **no** internal txs for it.

### 4.2 The drain tx

- **Tx `0xb2c7332d9e1be6a86d9d37083aa4cc0d94b60eb95cc9b29494555a3c09764930`, block 26,152,259 (2026-10-09 03:47:59 UTC)** — from burner EOA → attacker contract, value 0, method `0x5ee3f775` with args `(VISTA=0xC9bCa88B…cbbf, uint256 1)`; **no public signature exists for `0x5ee3f775`** (4byte: none).
- Token movements inside the tx (exact):
  - `21.365578479614736555` WETH: pair → attacker contract
  - `9.026956903960976779` + `4.860669107788601981` WETH: attacker contract → pair (returned)
  - `7.477952467865157795` WETH: attacker contract → burner EOA (net retained)
  - `43,855.902196275763910452` VISTA: pair → burner EOA
  - `1` wei VISTA: burner EOA → pair
- Immediately before (03:47:11) the EOA approved VISTA (tx `0x172795c3…`); just before the hijack, at 03:43:59, the EOA made a 0.004008-ETH test buy through the *official* router (`0xad2425c1…`).

### 4.3 Where the drained funds went

- **VISTA → burned.** 03:55:47, tx `0x9be0e1c315cc2298597758a98bd12c8f25a7ee50037897644401a7d6f5638db4`: `43,930.080656851986168396` VISTA sent to `0x000000000000000000000000000000000000dEaD` (the burner's *entire* VISTA balance after micro-trades). No VISTA sale on-chain.
- **WETH → ETH → Uniswap → USDC.** 6 `WETH.withdraw()` calls 03:59:35–04:05:11 (1 + 2 + 2 + 2 + 0.46 + 0.017 = 7.477 WETH; remaining 0.000952467865157795 WETH is still dust in the EOA). Then **3 `execute()` calls to Uniswap's UniversalRouter `0x23617e59a5925b2a4bf75d73ff6711cd0b29de85`** (04:41:59, 04:43:11, 04:44:11) with 3 + 3.3623065567684893 + 1.105714131330723 = **7.4680206880992123 ETH**, swapped via Uniswap V3/V4 pools (USDC/WETH 0.05 % `0x88e6a0c2…`, 0.01 % `0xe0554a47…`, V4 PoolManager `0x000000000004444c5d…`) into **18,590.71646 USDC** (7 transfer-ins, exact).
- **USDC → parked on two EOAs:**
  - **11,000 USDC** transferred 05:36:47 / 05:41:47 / 05:43:47 (1,000 + 5,000 + 5,000) to **`0x043c8f2df89612f9da2d91a92d30d3295cf842d3`** — an EOA with only April-2026 history (nonce 4, funded then from `0x9642b23e…`), **still holding 11,000.0001 USDC now**.
  - **7,590.71646 USDC** remains in the burner EOA `0xbbf8f3fe…` today (balance 7,590,716,560 raw — reconciled exactly, incl. a 0.0001-USDC poisoning dust).
- **No mixer, no CEX deposit, no bridge** observed for any drained value.
- Current balances of attacker infrastructure: attacker contract `0 ETH / 0 WETH / 0 VISTA / 0 USDC` (fully swept); burner EOA `0.014848005914668792 ETH + 0.000952467865157795 WETH + 7,590.71656 USDC + 0 VISTA`; burner's last own tx 2026-10-09 05:43:47 (nonce 22).

### 4.4 Spam / poisoning noise around the attacker addresses (ignore for accounting)

After the attack the burner is bombarded with history-poisoning: lookalike "ÚЅDС"/"U⁯S⁯Dꓚ" tokens replicating its USDC transfers, 0-value USDC `transferFrom` poisonings, 1-gwei dust from nonce-1 addresses, "PVC"/"ETHG" airdrop tokens, and a 43,930.08-amount "ERC" mirror event (unverified token `0x54cfcc2e…`, no corresponding EOA tx). None of these moved real value; they mimic the ~`0x043c*` address cluster that includes the real USDC recipient.

---

## Task 5 — Drain scope: how many pairs were hit on 2026-10-09? → **Exactly ONE.**

From the drain-tx receipt (`raw/drain_receipt.json`, 12 logs; decoded in `raw/drain_logs_decoded.tsv`):

| Log count | Emitter | Events |
|---|---|---|
| 5 | pair `0xfdd05552F1377aA488afed744c8024358AF02041` | `Sync` (`0x1c411e9a96…`) ×3, `Swap` (`0xd78ad95fa4…`) ×2 (topic1 = attacker contract) |
| 4 | WETH | Transfer ×4 |
| 2 | VISTA | Transfer ×2 |
| 1 | attacker contract | custom `0x9375a8dee9…` |

- Distinct **pair contracts emitting Swap/Transfer: 1** — only `0xfdd05552…` (the WETH/VISTA pair). No other pair contract appears in the receipt.
- Corroboration: the malicious router received **exactly one invocation** in its life (its 2-tx history), and between `setRouter` and restore (03:46:11–03:49:11) the pair showed no other transfers. **One pair drained, one drain tx.** (A fleet-wide scan of all 1,087 pairs is left to the parent — but any additional drain would have required another call to this router, and there was none.)

---

## Task 6 — Router state at end of 2026-10-09 and now

- Restore tx `0x7adfb703f74f7e46ce4b7d79f12b9a5310406e6f220ade5f8e8c6fc987226eda` set `router` back to `0x9Bd63C5D44Ff28390DF1eEAFd4EB4Bd73E94A72a` at 03:49:11 (block 26,152,265). It is the **last row of the factory's complete 21-tx history** — no `setRouter` after it.
- Live read at block **26,201,136** (2026-10-16): `factory.router()` = **`0x9bD63C5D44fF28390df1EaaFD4eB4BD73E94A72a`** — unchanged since. ✅
- The pair resumed normal trading within minutes (attacker's own micro-buys at 03:51+ via the restored router); current reserves: **14.24786635326656 WETH / 79,387.393606187717449441 VISTA**.

---

## Explicit "NOT FOUND" list

1. **`setRouterSetter` calls: none** — 0 occurrences in the routerSetter EOA's full txlist and 0 in the factory's complete 21-tx history.
2. **No interaction between routerSetter and the attacker contract/EOA** — 0 direct txs (both directions), 0 internal-tx matches (internal history covers 2024-08-31 and 2026-04-20→10-14).
3. **No drains in the 2026-03-07, 2026-04-07/08, 2026-04-21 flip windows** — net flows were *into* the pair; all outflows are tx-internal swap/LP legs and small `0xdead` burns.
4. **No other WETH/VISTA pair to check** — only 1 exists (`0xfdd05552…`); 268 WETH-based pairs total, 0 others with VISTA.
5. **No mixer/CEX/bridge deposit of drained funds** — WETH→USDC parked in two EOAs (`0x043c8f2d…` 11k, burner 7.59k); VISTA burned to `0xdEaD`.
6. **No public signature for the drain function `0x5ee3f775`** (4byte has none) and no referent for its `uint256 1` mode argument.
7. **No internal txs indexed for the attacker contract** (Etherscan: "No transactions found") — drain trace reconstructed from receipt logs instead.
8. **No other pair touched during the malicious-router window** (03:46:11–03:49:11).
9. **No `setRouter` (or other factory write) after the 2026-10-09 restore** — router unchanged since.

---

## Files (all under `ethervista/analysis/history/`)

- Scripts: `fetch_routers.sh`, `fetch_windows.sh`, `fetch_actors.sh`, `decode_drain_logs.jq` (all read-only; key taken from env, never stored).
- Router data: `raw/creation_0x*.json` (12), `raw/source_0x*.json` (12), `raw/factory_source.json`, `raw/factory_creation.json`, `raw/factory_txlist.json`.
- Pair/window data: `raw/pair_tokentx_w1_mar07.json`, `raw/pair_tokentx_w2_apr07_08.json`, `raw/pair_tokentx_w3_apr21.json`, `raw/pair_tokentx_w4_oct09.json`, `raw/window_flows.txt`, `raw/logs_paircreated_weth_p1.json`.
- routerSetter: `raw/routerSetter_txlist.json` (885 rows), `raw/routerSetter_txlistinternal.json`, `raw/routerSetter_txlistinternal_desc.json`.
- Attacker: `raw/attacker_txlist.json`, `raw/attacker_tokentx.json`, `raw/attacker_txlistinternal.json`, `raw/attackerEOA_txlist.json`, `raw/attackerEOA_tokentx.json`, `raw/attackerEOA_txlistinternal.json`, `raw/drain_tx.json`, `raw/drain_receipt.json`, `raw/drain_block.json`, `raw/drain_internal.json`, `raw/drain_logs_decoded.tsv`, `raw/recv_043c8f2d_txlist.json`, `raw/rpc_attacker_balances.txt`, `raw/rpc_flows.txt`.
- Counterparty lookups: `raw/addr_*_source.json`.

## Caveats

- Amounts are exact decimal strings from Etherscan V2 `tokentx`; the receipt-derived values in `drain_logs_decoded.tsv` are hex-decoded in jq (double precision) and may be rounded in the last digits — use the tokentx figures.
- "Binance 16" / "Union Chain" are third-party (Etherscan) labels; the funder EOAs' labels are not independently re-verified.
- Balance reads are point-in-time (block ~26,201,136, 2026-10-16); the attacker can still move parked USDC.
- The 2026-03-07 flip-window internal txs (sub-1000-row pages don't cover that date) were not individually enumerated; the direct txlist for the window is complete and shows nothing beyond the routine pattern described.
- Historical `router()` state at intermediate blocks could not be re-read (public RPC state is pruned); "unchanged since restore" rests on the complete factory txlist + latest-state read.
