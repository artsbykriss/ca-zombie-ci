# ZH4-PASS4 Tier-3 · **BTCΞ** (`BTToken`) — burn-from-pair + `pair.sync()` deep dive

**Date:** 2026-10-22 · **Chain:** BSC (56) · **Status:** read-only; fork-verified only; **no mainnet transaction signed or sent**
**Target:** BTCΞ token `0xb1939843fB9220719d13076dCeEfb0aeaeF06666` · pair `0x3cC292bB0011951F3151eB998816c31680a2Ce87` (PancakeSwap V2, BTCΞ/BTCB)
**Pattern:** $NEM-class "burn-from-pair + `sync()`" (`pass4/skim-burn.md` row #4, gate unresolved)

---

## 1. TL;DR

| Question | Answer |
|---|---|
| Is the burn-from-pair + `pair.sync()` path permissionless? | **YES** — any EOA can trigger it with a 1-wei `transfer` |
| Does it collapse a reserve the way NEM's `flushLpSellRecycle()` did? | **NO** — it burns a fixed ~**0.104 %/hour** of the pair's BTCΞ (≈2.5 %/day), then `sync()`s. No attacker-controlled sizing, no loop. |
| Can a fresh unprivileged attacker profit? | **NO** — the token **reverts `"T0"`** on any transfer *out of the pair*, so BTCΞ cannot be bought/acquired from the pool at all. |
| **Live extractable by an unprivileged attacker** | **$0.00** (high confidence) |
| Nominal value at risk (base side, block 129,126,816) | **$2,462,523** (30.166 BTCB) — *not* extractable by an outsider |

**Total live extractable now: $0.00** (confidence **high**). Category: **not E-U** (effectively **S/H-O**: the value is locked behind a one-way pool + a 60-day deposit lock).

---

## 2. The mechanism (deployed code, verified source)

`BTToken` (verified on BscScan, solc 0.8.24, `BT.sol`). The NEM-shaped code path is:

```
transfer(to, amount)                 // public
 └─ _transferWithLogic(from,to,amt)
     └─ _updateCycle()                                   // runs on EVERY transfer
         └─ for (hour = lastExecuted+1; hour < currentHour; hour++)
             └─ _executePoolBurn(hour, day)
                 ├─ poolBalance = super.balanceOf(pancakePair)     // real pair balance
                 ├─ burnAmount  = poolBalance * calculateBurnRate() / 100000
                 ├─ _transfer(pancakePair, address(this), burnAmount)   // ← burns FROM the pair
                 ├─ _executeFee(hour, day, burnAmount/2)
                 │    └─ IPancakePair(pancakePair).sync()               // ← pair.sync()
                 └─ _transfer(address(this), DEAD, burnAmount/2)
```

* `calculateBurnRate()` (tokenExt `0x0239fa9a53161b180b28c909c2cc1bde49341aeb`) = **104** → `104/100000 = 0.104 %/hour`.
* `getHourlyCycle()` = `(block.timestamp - launchTime)/1h`; `launchTime = 1783659600` (2026-07-10), so the token has been live ~2,502 hourly cycles.
* Crucially, `_updateCycle` burns **one cycle per real hour** (`hour < currentHour`, bounded by a 100-cycle catch-up cap). There is **no way to loop it inside a transaction**.

### The gate that pass4 left unresolved

pass4 saw only `…a01b031663fff6cae9…` (an external `sync()` call in the bytecode) and could not resolve the caller. The caller is `_executeFee`, reached **permissionlessly** from `transfer`. So the burn path itself is **not** role-gated. The real gate is elsewhere:

```solidity
// BT.sol — _transferWithLogic
if (from == pancakePair) { revert("T0"); }   // ← THE GATE
```

Any transfer with `from == pancakePair` reverts **`"T0"`**, *except* when `from`/`to` is on `transferWhitelist` (only `tokenExt` and `feeSwapper` are). This blocks every pool→user transfer, i.e. **buying BTCΞ is impossible**.

### The one route that can move BTCΞ out of the pair

`_redeem(user)` → `router.removeLiquidity(BT, WBTC, lp, 0, 0, feeSwapper, …)`. `feeSwapper` is whitelisted, so the pair *can* pay BTCΞ to it; the token then pulls it into itself and returns it to the user. But `_redeem` requires `u.lpAmount > 0` (a prior BNB deposit) and **burns 100 % of the returned BTCΞ if held < 60 days** (`daysHeld < 60 → burnAmount = btAmount; userAmount = 0`). So a fresh attacker who deposits + redeems gets their BTCB back and **zero BTCΞ** — a net loss after taxes, not an extraction.

---

## 3. Live-state assessment (block **129,126,816**)

| Item | Value |
|---|---|
| `pancakePair` | `0x3cC292bB0011951F3151eB998816c31680a2Ce87` |
| `token0` / `token1` | BTCB `0x7130…Ead9c` / BTCΞ |
| `getReserves()` | **30.166339329950305264 BTCB** · **1,340,443.034863621595719426 BTCΞ** |
| `BT.balanceOf(pair)` | `1,340,443.034863621595719426` — **equals reserve1 → no live desync** |
| `totalSupply()` | 6,660,010 BTCΞ |
| `tokenExt` | `0x0239fa9a53161b180b28c909c2cc1bde49341aeb` (code 15,650 B) |
| `feeSwapper` | `0xe65123831461d416924b679070f3d85f51ecf5fa` (code 4,492 B) |
| `owner()` | `0x0` (renounced) |
| EIP-1967 impl slot | `0x0` → **not a proxy / non-upgradeable** (the `"T0"` gate is immutable code) |
| `launchTime` | 1783659600 |
| base-side value | 30.166339 × $81,631.49 (DefiLlama BTCB) = **$2,462,523** |
| recent activity (last ~8,000 blocks) | **186 BTCΞ transfers / 27 pair `Sync` / 24 pair `Swap`** → token is **actively traded**, so the hourly catch-up is ≈1 cycle (no dormant amplification) |

Gate probes from a fresh EOA `0x…DeaDBeef` (`eth_call`, no tx):

| Call | Result |
|---|---|
| `BTCΞ.transfer(attacker, 1e18)` with `from = pair` | **revert `"T0"`** |
| router `swapExactETHForTokens(WBNB→BTCΞ)` from a funded EOA | **revert `"T0"`** |
| `BTCΞ.transfer(self, 1)` from the attacker (the permissionless trigger) | **succeeds** (clamps amount to 0, runs `_updateCycle`) |

---

## 4. What an attacker can / cannot do

**Can:**
* Trigger `_updateCycle()` (any EOA, via `transfer(anyAddr, 1)`), causing at most **one** hourly burn of ~0.104 % of the pair's BTCΞ + a `sync()`. This *is* a real reserve mutation (BTCΞ price steps up ~0.104 %).

**Cannot:**
* **Acquire BTCΞ from the pool** — buys revert `"T0"`. With no BTCΞ in hand, the price step is worthless to the attacker.
* Amplify the burn — capped at 1 cycle/hour, no per-tx loop, fixed rate, sized off the *real* pair balance (`super.balanceOf`), not an attacker-influenceable input.
* Get BTCΞ via `redeem` inside 60 days — 100 % of the BTCΞ is burned on early redeem.
* Reuse the NEM recipe (`{transfer→skim→sync}`): BTCΞ has no `skim`, and the burn sizing is not caller-controlled.

**Cost / net:** triggering the burn costs only gas; **net extractable = $0** because there is no way to hold BTCΞ as a fresh attacker.

---

## 5. PoC / fork verification

`poc/test/BtcxPoC.t.sol` (Foundry, `vm.createSelectFork` on `BSC_RPC_URL`, vendored forge-std):

| Test | Asserts |
|---|---|
| `test_btcx_live_state` | reserve1 == real pair balance (no desync); token ordering |
| `test_btcx_buy_is_blocked_T0` | pair→EOA transfer reverts `"T0"`; router buy reverts `"T0"`; attacker balance 0 |
| `test_btcx_burn_permissionless_one_hour` | after warping 1 h, a 1-wei self-transfer reduces the pair's BTCΞ reserve by ~10 bps and `sync()`s; attacker still holds 0 |
| `test_btcx_dormant_catchup_is_capped_100` | worst-case dormant replay is capped at 100 cycles (~9.9 % of pair BTCΞ) — latent only, still worthless (unbuyable) |
| `test_ns_gate_is_not_unprivileged` / `test_dmd_gate_is_not_unprivileged` | cross-checks for the sibling targets |

* CI: see `ci-log.txt` / `summary.json` (`ci_run_urls`). Result: **all tests pass** (recorded in `ci-log.txt`).
* `ci/run.sh` additionally dumps `ci-out/live-state.json` (block, reserves, pair balances, gate probes).

---

## 6. Verdict, residual & re-arm triggers

**Verdict: not extractable by an unprivileged external attacker — $0 (high confidence).** The burn-from-pair + `sync()` shape is real and permissionless, but it is *self-limiting* (fixed rate, one cycle/hour, real-balance sizing) and, decisively, the pool is **one-way**: BTCΞ cannot be bought out of it (`"T0"`). A NEM-style collapse would require either (a) an attacker-controlled burn amount, or (b) an ability to hold/sell BTCΞ — neither exists.

**Residual / latent risk**
* If the `"T0"` restriction were ever removed (it is hardcoded in `_transferWithLogic`; the contract is **not** upgradeable), a holder could sell into the small hourly price step; a fresh attacker still could not *enter* without capital already holding BTCΞ.
* **Dormant catch-up:** if the token were ever idle for >100 h, one transfer replays the capped 100 cycles → ~**9.9 %** of the pair's BTCΞ burned in a single tx. This is a *latent* price step, but it remains non-extractable for a fresh attacker (unbuyable), and the token is currently active.
* Out-of-scope but adjacent (different bug class, not the burn/sync shape): the deposit/LP accounting in `tokenExt.processBuildLP` and `_redeem`'s day-based burn schedule — worth a separate look, not evaluated here.

**Re-arm triggers:** (1) any new path that lets an outsider obtain BTCΞ (new pair, airdrop, whitelist change, a *buyable* venue); (2) the token going dormant >100 h while BTCΞ is obtainable; (3) any code change removing `"T0"`.

---

## 7. Methodology & files

**Method:** BscScan/Etherscan-V2 verified source read; keyless-RPC `eth_call`/`getLogs` state reads at explicit blocks; DefiLlama price; Foundry fork tests (CI). No secret is written into this folder.

```
btcx/
├── README.md                     # this file
├── summary.json                  # machine-readable
├── analysis/
│   ├── rpc.py, state.py, state.json, probe.py     # live reads + gate probes
│   ├── activity.py, activity.json, activity.log   # recent-transfer activity
│   ├── src/BTToken.sol           # verified flattened source
│   └── verify/                   # independent verification (child agent)
├── poc/                          # Foundry project (forge-std vendored)
├── ci/run.sh                     # light live-state dump -> ci-out/
├── ci-out/                       # CI artifacts
└── ci-log.txt                    # CI test log
```

**Caveats:** point-in-time (2026-10-22, block 129,126,816); BTCB USD is DefiLlama spot. BTCΞ liquidity is priced only via this one PancakeV2 pool. Nothing here is an instruction to transact.
