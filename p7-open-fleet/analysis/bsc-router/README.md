# BSC SwapX router `0xa331fde028e6F17425AB9333c39ae43722340d24` — PRIOR-PARTIAL re-probe

**Campaign:** ZH4-PASS7 (folder `p7-open-fleet`) · **Mode:** READ-ONLY (`eth_call` / `eth_getCode` / `eth_getStorageAt` / `eth_getLogs`; local anvil fork simulation only — **no mainnet transactions**) · **Date:** 2026-10-26

**Bottom line:** the prior-corpus "HIGH, no known fix" is **corrected**. The proxy was **upgraded** (old impl `0x241f743e…` → current `0xc700cf8d7adf1782a53a4805d255cf17e126db7f`), and the new implementation **binds the V3-callback `payer` to the router's own swap context instead of to the caller-supplied `data`**. A fake V3 pool can still make the router call `pool.swap()` on it, but the callback now pulls tokens from the **router's caller** (the attacker), never from a victim named in the callback data. **Mechanism FIXED; live drainable value $0.**

---

## 1. What the bug was (Sep-2026 incident)

SwapX router is an unverified upgradeable DEX router (version string `1.9.1-bsc`). SlowMist/ExVul/DeFiHackLabs record a ~**62.28 WBNB (~$45.8k) / 29-victim** approval-drain on **2026-09-07** (tx `0x40eb22369da422a8275d5679054aa3a8c8906d93abc0bac3a3f2cad879389319`, block **120,524,634**).

Old-impl flow (confirmed by the public PoC and the prior corpus):

1. Permissionless entry **`0x33411b5e(Route[] routes, uint256 amountIn, uint256, uint256, uint256, address recipient, bytes)`** calls `pool.swap(0x128acb08)` on a **caller-chosen** `pool`.
2. The attacker's **fake pool** re-enters `uniswapV3SwapCallback(0xfa461e33)` / `pancakeV3SwapCallback(0x23a69e75)` with `data` naming an arbitrary **victim as `payer`**.
3. The callback decoded `payer` from that caller-supplied `data` and ran `transferFrom(payer, msg.sender, amount)` with **no check that `msg.sender` was a real factory-derived V3 pool**. `factoryV3()` returned `0x0`, so no canonical pool could even be derived.

## 2. Live state (block 129,804,693)

| Read | Value |
|---|---|
| proxy code size | **130 B** |
| proxy native (BNB) balance | **0** |
| EIP-1967 impl slot `0x360894a1…` | `0xc700cf8d7adf1782a53a4805d255cf17e126db7f` |
| EIP-1967 admin slot `0xb5312768…` | `0x0` (UUPS: upgrade logic lives in the impl, `upgradeToAndCall` `0x4f1ef286` is `onlyOwner`) |
| impl code size | **22,857 B** (unverified) |
| impl native balance | **0** |
| `factoryV3()` | **`0x0000000000000000000000000000000000000000`** |
| `factoryV2()` | **`0x0`** |
| `WETH()` | `0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c` (WBNB) |
| `owner()` | `0x2803E636498568182594F2909C8d6Cce8820BE15` |
| `version()` | `1.9.1-bsc` |
| `paused()` | `false` |
| `factory()` | reverts (no such function) |

**Upgrade history (via the EIP-1967 impl slot, archive reads):**

| block | impl |
|---|---|
| 120,524,634 (incident) | `0x241f743e2c654d4119e8d84fb8b6d86442fb9ba9` (old, vulnerable) |
| 120,724,905 | `0x50c086653e129a03a25956f559b8ba44a38c01e3` (intermediate) |
| **120,724,906 → head** | **`0xc700cf8d7adf1782a53a4805d255cf17e126db7f`** (current) |

**Selector presence in the current impl bytecode:** `0x33411b5e` ✔, `0x23a69e75` ✔, `0xfa461e33` ✔, `0x23b872dd` (transferFrom) ×3. `0x128acb08` (V3 `swap`) is **absent** — the router reaches the pool through the caller-supplied route, not a hard-coded swap selector.

## 3. Decompile conclusion — the callback is hardened

Tooling: **heimdall 0.9.2** `decompile --include-sol` (→ `impl-decompiled.txt`) plus a manual `cast disassemble` trace (`impl-disasm.txt`).

* The callback body (`0x23a69e75` at impl offset `0x040e`) starts by **`TLOAD`-ing an EIP-1153 transient slot** (slot key = code constant at `0x5794`) and **reverts `SwapX: Invalid pool`** unless that slot is non-zero **and `msg.sender` equals it** (`0x042d–0x0446`).
* The entry (offset `0x0692`) stores the pool / expected amount / payer / recipient into transient storage before it calls `pool.swap()`, and the callback clears/uses those slots. Additional guard `SwapX: v3 amountToPay exceeds expected`.
* New guard strings (absent from the old impl): `SwapX: Invalid pool`, `SwapX: invalid pool address`, `SwapX: v3 amountToPay exceeds expected`, `SwapX: v2 fee bps`, `SwapX: flap native refund/send failed`.
* Live probe: a **direct** `eth_call` of `uniswapV3SwapCallback` from a random EOA **reverts `SwapX: Invalid pool`** (the transient pool slot is empty).

**The critical property.** The entry still calls `pool.swap()` on a **caller-chosen** pool with **no factory validation** (`factoryV3()==factoryV2()==0x0`) — so the "fake pool" precondition still holds. But the callback's `transferFrom` **`from`** is now the **router's swap-context caller**, *not* a value decoded from the callback `data`.

**Fork reproduction (local anvil fork @ 129,801,893, no mainnet tx — `RouterProbe.t.sol`):** a fake pool re-entered both callbacks with `data` naming victim `0x…Beef01` as `payer`, and the entry `recipient` set to a *distinct* address `0x…Ca11E2`. Result for **both** `uniswapV3SwapCallback` and `pancakeV3SwapCallback`:

```
MockToken.transferFrom(Exploit [router caller], FakePool [callback msg.sender], amount)
victim drained = 0     recipient drained = 0     attacker drained = 0 (round-trips back)
```

The victim named inside the attacker-supplied `data` is **ignored**. The substitution primitive that powered the Sep-2026 exploit no longer exists.

## 4. Approval census (`Approval(owner, spender=router)`)

`topic0 = 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925`, `topic2 = 0x…a331fde028e6f17425ab9333c39ae43722340d24`, latest per `(owner, token)`.

> **Note on the incident block.** The task brief's "~block 62,000,000" is stale: the Sep-2026 incident block is **120,524,634** and the current head is **~129.8 M**. The 3 M-block window below (126.80 M–129.80 M) covers the recent period; it does **not** reach the incident block.

**Census result (exhaustive over the window):**

* Window **126,804,572 → 129,804,572** (last 3,000,000 blocks), 5,000-block chunks, **601 requests, 0 misses** → **0 `Approval(owner, spender=router)` events**.
* Independent spot checks with `topic0`-only and with an empty topic filter (all logs) at 127.2 M / 128.0 M / 128.5 M / 129.0 M / 129.5 M / 129.7 M also returned **0** — the router is **completely inactive post-incident**.
* Incident-window scan **120,400,000 → 120,800,000** → **0** approval events (the victims' approvals were granted long before the incident).
* Filter positive control: the same `topic0 + topic2` filter for `spender = PancakeRouter 0x10ED43C7…` returns **thousands** of events in a 5,000-block slice → filter syntax validated.

**Distinct tokens / funded pairs > $1000: none.** (The prior pass4 census claimed "51 pairs, 4 funded, 0 material" over 127.0–129.0 M; this re-probe finds **zero** approval events over that same range with a validated filter, so that figure is not reproducible.)

Because the callback no longer pays a caller-named payer, **no standing approval is drainable** — the census is informational only.

## 5. Verdict

| | |
|---|---|
| Mechanism | **FIXED** on `0xc700cf8d7adf1782a53a4805d255cf17e126db7f` |
| Live drainable value | **$0** |
| Confidence | **HIGH** (decompile + live `eth_call` revert + local-fork reproduction, three independent methods) |
| Re-arm trigger | a **new implementation upgrade** by owner `0x2803E636498568182594F2909C8d6Cce8820BE15` (`upgradeToAndCall`, selector `0x4f1ef286`) that reintroduces a data-supplied `payer` or removes the transient pool/payer binding |
| Monitor | (a) `eth_getStorageAt` EIP-1967 impl slot `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` ≠ `0xc700cf8d…`; (b) any `Approval(owner, spender=router)` with a funded, non-zero-value token; (c) `Upgraded(address)` event on the proxy |

## 6. Exact call path (for reference / future re-probe)

```
attacker
  └─ router 0x33411b5e( Route[]{kind,tokenIn,tokenOut,pool=fakePool,fee,...},
                        amountIn, 0,0,0, recipient, "" )
        └─ impl stores swap-context (payer = msg.sender) in transient storage
        └─ fakePool.swap(router, true, amountIn, 4295128740, data)   [selector 0x128acb08]
              └─ router 0x23a69e75 / 0xfa461e33 (amount0Delta, amount1Delta, data)
                    ├─ require pool != 0 && msg.sender == TLOAD(pool)   else "SwapX: Invalid pool"
                    └─ token.transferFrom( <router caller>, msg.sender, amount )   // NOT data.payer
```

Old vulnerable behaviour replaced `transferFrom(data.payer, …)`; the new impl uses the router's own caller, so an attacker can only move their own approved tokens.

## 7. Limitations / honesty

* The implementation is **unverified**; conclusions rest on decompilation + raw disassembly + live `eth_call` + a local fork, not on source.
* The wide `eth_getLogs` census was constrained by public RPC limits (free tiers cap archive ranges at ~5,000 blocks; several providers' log endpoints were quota-exhausted during this run). Coverage is recorded in `evidence.json`; the pass4 2 M-block census is cited for the historical picture.
* The Sep-2026 incident block is **120,524,634** (not ~62 M). The scanned 3 M window does not include it.
* Nothing here is an instruction to transact.
