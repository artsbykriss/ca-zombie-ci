# ZH4-03 — Shibarium stale-WBONE cluster: exit-adjusted **$746.95 gross / ≈$739 net** (one-shot, E-U)

**Date:** 2026-10-18 · **Chains:** Shibarium (109) + Ethereum (1) · **Status:** read-only; PoC fork-verified only; **no mainnet transactions sent**.

**Headline correction to the wave-2 finding:** the quoted **+$877 chained / +$936 current-price** numbers are **nominal**. They assume the DAI output can leave Shibarium. It cannot: the L1 `ERC20Predicate`'s only `MANAGER_ROLE` holder is the team EOA, the `RootChainManager` role was revoked on 2025-09-12, and the predicate escrows **37.84 DAI / 0.90 USDT** against **6,535 DAI / 12,779 USDT** of L2 supply. The only exit-able leg is **WBONE → WETH → ETH**, which is **$746.95 gross / $739.07 net** at the 2026-10-18 prices. The exit question is now resolved: **WETH and BONE exit; DAI and USDT do not.**

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why open / closed | Latent risk |
|---|---:|---|---|
| **WBONE/WETH pool** `0xe4dbeE5F…` | **$746.95 gross / ≈$739 net, one-shot** | **OPEN**: WBONE is 1:1 mintable from BONE; the pool is a Solidly volatile vAMM with **zero swaps since block 18M** (last swap 2026-07-04); WETH exits to ETH via the live `EtherPredicate` | EtherPredicate has only **1.94056 ETH** vs 186.18 WETH supply; factory `pauser` is an EOA; LP is 99.96% in a gauge |
| **DAI/WETH pool** `0xD7115c43…` | **$0** (nominal: +$937 chained / +$488 standalone) | **CLOSED**: DAI L1 exit frozen — `ERC20Predicate.MANAGER_ROLE` = team EOA only; RCM revoked 2025-09-12; escrow 37.84 DAI vs 6,535 DAI L2 supply | If the role is restored **and** the escrow topped up, the DAI legs reopen |
| **WBONE/USDT pool** `0x4fC0DB98…` | **$0** (nominal +$59.97) | **CLOSED**: USDT L1 exit frozen — same predicate; escrow 0.904373 USDT vs 12,779 USDT L2 supply | Same |
| **WETH child token** `0x8ed7d143…` | the exit rail for the $739 | **OPEN**: `EtherPredicate` still has RCM as `MANAGER_ROLE`; real WETH exits paid 0.06436 ETH on 2026-10-02 | Only **1.04% backed**; first-come-first-served |

**Total live extractable now: $746.95 gross / $739.07 net (one-shot). Confidence: MEDIUM** — mechanics HIGH (fork-proven 7/7), exit MED-HIGH (real WETH exit + 1.94 ETH buffer), size MED (one-shot, buffer-limited).

---

## 2. The mechanism in exact terms

### 2.1 WBONE is a 1:1 wrapper of native BONE

`WBONE` = `0x839FdB6cc98342B428E074C1573ADF6D48CA3bFd` (18 decimals, total supply
803,611.317072142350078769). Selectors: `deposit()` `0xd0e30db0`, `withdraw(uint256)` `0x2e1a7d4d`.
The contract is not verified on Shibariumscan, but the fork test calls both:

- `deposit{value: 1e18}()` → WBONE balance **+1e18** exactly (`test_wbone_deposit_withdraw_1to1`, PASS).
- `withdraw(1e18)` → WBONE balance returns to the prior value (1:1 burn); the contract sends
  1 BONE to the caller (a `receive()` was needed in the test contract).

No fee, no cap, no whitelist. This is the acquisition primitive: **BONE → WBONE is free and permissionless**.

### 2.2 The pool is a dead Solidly volatile vAMM priced 1.84× high

`WBONE/WETH` = `0xe4dbeE5Fa46fB8A4D00FB719deDCAEDc91AE5F13`:

- `token0` = WBONE, `token1` = WETH, `stable()` = **false**
- factory `0xB9fbdFA27B7ba8BB2d4bB4aB399e4c55F0F7F83a`; `volatileFee()` = **20 bps**;
  `isPaused()` = **false**; `feeManager`/`pauser` = EOA `0x9FC924a7c8678C7Bb13114Bd0C74E446937499fA`
- reserves (block 19,476,110): **107,523.829458 WBONE / 4.568486556 WETH**
- `getAmountOut(1e18, WBONE)` = 42,402,761,208,099 wei = **0.0000424028 WETH** per WBONE
- implied WBONE price = 4.2488e-5 WETH = **$0.10196** at $2,399.73/WETH
- market BONE = **$0.055485** → **1.8376×** overpriced
- both sides are **real balances** (`balanceOf(pair)` = 107,523.829458 WBONE and
  4.568486556 WETH; not ghost reserves)
- last swap: **2026-07-04 17:01:06 UTC, block 17,967,045**; **0 swaps since block 18M**
  (the 2023–2025 history returned the explorer's 1,000-row page cap; the pool has been dead for ~105 days)
- LP: **698,856.9 / 699,127.16 (99.96%)** staked in gauge `0x0bC0b80141859F35F1913873354d9Db3f4D3C105`

The **DAI/WETH** pool `0xD7115c435eB221addbD3A1D15c95491ec0545f7f` (Solidly/UniV2, 0.3%)
holds **4,040.83 DAI / 0.71556 WETH** (implied 5,647 DAI/WETH, 2.34× fair). It is **not dead**:
507 swaps since block 18M, but the last (2026-10-15 03:40, block 19,436,538) was a **0.0000167 WETH**
router hop; the bot is nibbling, not arbitraging at size, and DAI is frozen anyway.

The **WBONE/USDT** pool `0x4fC0DB98A912829b803D2fCFb40C12d5E9aFAe2c` holds
**1,322.46 WBONE / 266.53 USDT** (0.2016 USDT/WBONE, 3.63× fair); 385 swaps since block 18M,
last 2026-10-13 13:49, a 2.64 USDT router hop. Same conclusion: tiny hops, not a real arb.

### 2.3 The realizable trade

Sell freshly-minted WBONE into the dead pool. With the 20 bps volatile fee, the optimum is:

```
x = 38,084.090645 BONE
→ 38,084.090645 WBONE (deposit 1:1)
→ 1.193132635970670183 WETH (getAmountOut at the 19,475,745 reserves)
cost  = 38,084.090645 × $0.055485081 = $2,113.0989
value = 1.193132635970670183 × $2,397.0888 = $2,860.0449
gross = $746.9460
```

After the trade the pool's marginal price equals the market; **so there is no second cycle**.
The pool's WETH side (4.568 WETH) bounds the one-shot.

### 2.4 Exit: WETH → ETH is live; DAI/USDT are not

| Asset | Path | Status |
|---|---|---|
| WETH | L2 `ChildERC20.withdraw(amount)` burns → checkpoint → L1 `RCM.exit(bytes)` → `EtherPredicate.exitTokens` → ETH to the burner | **OPEN** — RCM `hasRole(MANAGER_ROLE, EtherPredicate)` = **true**; real WETH exits paid 0.06436 ETH on 2026-10-02 |
| BONE | L2 `0x…1010.withdraw(amount)` → checkpoint → `WithdrawManager.startExitWithBurntTokens` → 7-day `HALF_EXIT_PERIOD` → `processExits` | **OPEN** — BONE `Withdraw` logs on 2026-10-10 (1,260 + 144.9 + 1,850.85 BONE), 2026-10-04 (5,240 BONE), 2026-10-03 (85.57 BONE) |
| DAI | same pos-portal flow, but `ERC20Predicate` | **FROZEN** — only `MANAGER_ROLE` holder is team EOA `0x80Cc222E…`; RCM role revoked 2025-09-12; **0 DAI transfers from the predicate since**; escrow **37.84 DAI** |
| USDT | same | **FROZEN** — same role gate; escrow **0.904373 USDT** |

The same `MANAGER_ROLE` gate protects `lockTokens`, so **DAI/USDT deposits are frozen too**;
the canonical DAI/USDT bridge is dead in both directions and the existing L2 supply is orphaned.

The `RolesGranted`/`RolesRevoked` history on the ERC20Predicate (`0x6Aca26bF…`):

| Date | Event | Block |
|---|---|---|
| 2023-08-08 | `MANAGER_ROLE` → RCM `0x08c4b60f…`, team EOA `0x80cc222e…` | 17,868,608 |
| 2025-09-10 | `MANAGER_ROLE` → emergency contract `0xda9CE761…` | 23,334,256 |
| 2025-09-12 | revoked `0xda9CE761…` | 23,349,018 |
| 2025-09-12 | **revoked RCM** | 23,349,223 |

The emergency contract `0xda9CE761…` is abandoned (7 txs total, last 2025-09-11; all
balances 0) and is not an exit route.

### 2.5 The WETH buffer is the real ceiling

`EtherPredicate` holds **1.940558599296224434 ETH** (block 26,215,857); the WETH child
total supply is **186.180882 WETH**. The buffer covers **1.04%** of the supply. The ZH4-03
output (1.19313 WETH) fits, leaving **0.747426 ETH**. If the buffer is drained by another
exiter first, the WETH leg's exit fails. This is why the exit confidence is MED-HIGH, not HIGH.

The ~184 WETH shortfall is not a mystery: the emergency depositor `0xda9CE761…` still holds
`DEPOSITOR_ROLE` on the L2 WETH/DAI/USDT child tokens and minted WETH during the Sept-2025
incident response. It is not backed by L1 ETH.

---

## 3. Live-state assessment (all reads at explicit blocks)

**L2 block 19,476,110 (state snapshot) / 19,476,148 (CI PoC), chain id 109. L1 block 26,215,845 / 26,215,857.**

| Item | Address | Live value |
|---|---|---|
| WBONE | `0x839FdB6cc98342B428E074C1573ADF6D48CA3bFd` | supply 803,611.317072 WBONE; deposit/withdraw 1:1 |
| WETH child | `0x8ed7d143Ef452316Ab1123d28Ab302dC3b80d3ce` | supply 186.180882 WETH; `withdraw()` burns |
| DAI child | `0x0726959d22361B79e4D50A5D157b044A83eC870d` | supply 6,535.279182 DAI |
| USDT child | `0xaB082b8ad96c7f47ED70ED971Ce2116469954cFB` | supply 12,779.518189 USDT |
| WBONE/WETH | `0xe4dbeE5Fa46fB8A4D00FB719deDCAEDc91AE5F13` | 107,523.829458 WBONE / 4.568486556 WETH |
| DAI/WETH | `0xD7115c435eB221addbD3A1D15c95491ec0545f7f` | 4,040.832270 DAI / 0.715561949 WETH |
| WBONE/USDT | `0x4fC0DB98A912829b803D2fCFb40C12d5E9aFAe2c` | 1,322.460852 WBONE / 266.533834 USDT |
| RCM | `0x08C4b60fda8aA6239b7de7d165BCF6F1686Cad82` | maps DAI→`0x0726…`, USDT→`0xaB08…`, `0xEeee…`→WETH |
| ERC20Predicate | `0x6Aca26bFCE7675FF71C734BF26C8c0aC4039A4Fa` | 1 manager: `0x80Cc222E…`; RCM role **false**; 37.837 DAI + 0.904373 USDT escrow |
| EtherPredicate | `0xc3897302aB4B42931cB4857050Fa60f53B775870` | 2 managers incl. RCM; **1.940558599 ETH** |
| DepositManager | `0x885fce983b6a01633f764325b8c3c5d31032c995` | BONE deposits live (2026-10-17) |
| WithdrawManager | `0x5f683665ca87dbc3d1358913da80e3c71c328fb0` | BONE exits live; `HALF_EXIT_PERIOD=302,400` |

**Pool factory:** `0xB9fbdFA27B7ba8BB2d4bB4aB399e4c55F0F7F83a` — `isPaused()=false`,
`volatileFee()=20` bps, `stableFee()=1` bps, `feeManager()=pauser()=0x9FC924a7…`.
**LP gauge:** `0x0bC0b80141859F35F1913873354d9Db3f4D3C105` holds 99.96% of the LP.

**Exit evidence (real, not simulated):**
- WETH: tx `0xd8d66ca65e3811743278cba2a62f7292c2e58278d2271f969b2361db3a9177dc`,
  block 26,103,909, 2026-10-02. Batch helper `0x09b74961…` → 2 × `RCM.exit(bytes)` with
  WETH payloads → `EtherPredicate` paid 0.03435660242474078 ETH and 0.03 ETH. The helper has
  760 batch-exit txs (last 2026-10-06).
- BONE: `Withdraw` events on the WithdrawManager for `0x9813037e…` at blocks 26,162,022,
  26,119,619, 26,108,411 (amounts above). BONE deposits at 26,213,745 / 26,214,197.

---

## 4. What an attacker can and cannot do

### Can (exact sequence)

1. **Acquire BONE on L1** (ShibaSwap/CEX) at ~$0.0555; 38,084 BONE ≈ $2,113. DEX fee ~$6.34
   at 0.3%, less on a CEX.
2. **Bridge BONE L1→L2** via `DepositManager.depositERC20` (or `depositERC20ForUser`).
   Recent deposits prove the path: 2026-10-17 blocks 26,213,745 (2 BONE) / 26,214,197 (16.65 BONE);
   the depositors' L2 balances (18.66 BONE / 196.4 BONE) confirm the mint. Gas ~150,255
   (0.000142 ETH at 0.95 gwei).
3. **Wrap and sell**: `WBONE.deposit{value: 38,084.09e18}()`; `WBONE.transfer(pair, x)`;
   `pair.swap(0, 1.19313e18, attacker, "")`. Gas ~424,632 on the L2 fork (test overhead
   included); L2 gas price ~1.5 gwei → negligible.
4. **Exit WETH**: `WETH.withdraw(1.19313e18)` burns on L2; wait for the next Shibarium
   checkpoint (~15 min); call `RCM.exit(payload)`. Gas ~500k on L1 (~$1.20 at 1 gwei, ~$6 at
   5 gwei). The `EtherPredicate` pays **1.19313 ETH** to the burner if the 1.94 ETH buffer is
   still there. Total lock-up ~1 hour.

**Net:** $746.95 − $6.34 (BONE fee) − $0.34 (deposit gas) − $1.20 (exit gas) − ~$0.00003
(L2 gas) = **$739.07**; at 5 gwei exit gas, **$734.27**; if BONE is already held, **$745.41**.

### Cannot

- **Exit DAI or USDT.** `RCM.exit` → `ERC20Predicate.exitTokens` reverts (RCM lacks
  `MANAGER_ROLE`); the predicate has made **0 DAI/USDT transfers since 2025-09-12**. Even the
  team can pay at most 37.84 DAI / 0.904373 USDT (the escrow). The 4,040.83 DAI and 266.53
  USDT in the pools are **L2-only**.
- **Realize the chained $937 or the USDT $59.97.** Executing them converts BONE into a token
  that cannot leave; the true net is negative (≈−$872 / −$66).
- **Scale or repeat.** The WETH output is 1.193 WETH, 61.5% of the 1.94 ETH buffer; WETH
  supply is 186 WETH, so the buffer is the hard cap. After the trade the pool is at fair
  price; no second cycle.
- **Survive a factory pause.** `Pair.swap` requires `!PairFactory.isPaused()`; the pauser is
  an EOA `0x9FC924a7…` (currently false). A pause blocks the trade (privileged, not E-U).
- **Rely on the fake-WBONE pools.** `0xC76F4c81…` `deposit()` reverts `Invalid sender address`;
  the token cannot be minted. Its pools hold ~$970 WETH / ~$516 USDT but are a trap.
- **Use the DAMN/WBONE pool** (`0x615b17bd…`, 550,351 WBONE / 32.14B DAMN, $62.8k GT
  reserve). DAMN ("Sol Killer", 69B supply) has zero volume and no obtainable source; the
  price is circular. Not an arb.

---

## 5. PoC / fork verification

**Project:** `poc/` (Foundry 0.8.24, `evm_version = "cancun"`, vendored `forge-std`).
**Tests:** `poc/test/ShibariumWbone.t.sol` — **7/7 PASS** in CI.

| Test | What it proves | Key output |
|---|---|---|
| `test_wbone_deposit_withdraw_1to1` | WBONE deposit/withdraw is exactly 1:1 | +1e18 WBONE for 1 BONE |
| `test_wbone_weth_arb_and_weth_burn` | The standalone arb executes on a Shibarium fork; WETH burns on L2 | 38,084.09 BONE → **1.193132635970670183 WETH**; cost $2,113.0989; value $2,860.0449; **gross $746.9460** |
| `test_chained_wbone_weth_dai_nominal` | The chained route is ~$937 **nominal**; DAI burn works on L2 | 15,718 BONE → 0.581638 WETH → **1,808.824552 DAI**; nominal $937.0695 |
| `test_wbone_usdt_nominal` | The USDT leg is ~$59.97 **nominal** | 1,196.75 BONE → **126.483977 USDT**; nominal $59.9700 |
| `test_l1_exit_gates` | DAI/USDT predicate is manager-frozen; EtherPredicate is open; escrows | 1 manager (`0x80Cc222E…`); RCM role false on ERC20Pred, true on EtherPred; 37.837 DAI / 0.904373 USDT escrow; 1.940558599 ETH buffer |
| `test_l1_erc20_exit_reverts` | `RCM` → `ERC20Predicate.exitTokens(DAI)` reverts | PASS (revert) |
| `test_l1_ether_exit_payout` | `EtherPredicate` pays the burn withdrawer | **1.193132635970670183 ETH** paid; 0.747425963 ETH left |

**CI:** https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39082788804 — `forge test -vvv`
on the public runner, 7 passed / 0 failed, Shibarium fork block **19,476,148**, Ethereum fork
block **26,215,857**. Artifact `result-shibarium-wbone.zip` contains the state snapshot
(`ci-out/state.json`). Local log: `analysis/poc-local.log`.

*Note on the L1 payout test:* it pranks the RCM and feeds the EtherPredicate a valid RLP burn
log to prove the payout leg and the predicate's funding. The **end-to-end** proof is the real
2026-10-02 batch tx above (RCM.exit with WETH payloads → 0.06436 ETH paid).

**Gas/cost assumptions:** L1 deposit 150,255 gas at 0.948 gwei = $0.34; L1 exit 500,000 gas
at 1 gwei = $1.20 (5 gwei = $6.00); L2 wrap+swap+burn ~424k gas at 1.5 gwei ≈ $0.00003; BONE
acquisition fee 0.3% = $6.34. The gross $746.95 is the fork output at the fixed 2026-10-18
prices (WETH $2,397.09). The live-price optimum moves with the oracle: **$750.10** at the
local state snapshot (WETH $2,399.73, ~01:00 UTC) and **$744.71** at the CI snapshot
(00:27 UTC), so the range is **$735–$750 net** depending on gas, BONE source and the WETH price.

---

## 6. Verdict and residual risk

**Classification:** **E-U $746.95 gross / $739.07 net, one-shot**, confidence **MEDIUM**.
The mechanics and the WETH exit are HIGH confidence; the size is MED because of the 1.94 ETH
EtherPredicate buffer and the one-shot nature. **H-O = P = S = $0** for this path.

**Why the wave-2 $877/$936 was too high:** those numbers were computed as if DAI/USDT could
be sold at face. They cannot be bridged out: the ERC20 predicate is manager-frozen and its
escrow is 0.58% / 0.007% of L2 supply. The chained and USDT routes are value-destructive at
execution; only the standalone WETH leg is rational.

**Residual / latent risk:**

1. **DAI/USDT re-opening:** if the team re-grants `MANAGER_ROLE` on `0x6Aca26…` to a live RCM
   **and** tops up the escrow (37.84 DAI / 0.904373 USDT today), the chained +$937 and USDT
   +$60 legs become realizable in principle. Watch `RoleGranted`/`RoleRevoked` on the predicate
   and its DAI/USDT balances. The escrow is the hard blocker; the role alone is not enough.
2. **WETH buffer:** the exit works only up to the 1.94056 ETH in the EtherPredicate. A top-up
   raises the ceiling; a drain by another exiter kills the WETH leg. Watch `ExitedEther` and
   the predicate balance.
3. **Pool risk:** 99.96% of the LP is staked in the gauge; the factory pauser/feeManager is an
   EOA (`0x9FC924a7…`). A pause or fee change blocks the swap (privileged).
4. **Competition:** no bot is trading the WBONE/WETH pool (0 swaps since block 18M; last
   2026-07-04). The DAI/WETH and WBONE/USDT pools have a tiny router bot (last 2026-10-15 /
  2026-10-13) but it is not arbitraging the key pool at size.

**What would change the verdict:** (i) a WETH top-up above ~1.2 ETH (raises exit confidence);
(ii) a DAI/USDT role restore + escrow top-up (reopens ~$1.0k nominal); (iii) a factory pause or
gauge pull (closes the trade); (iv) a bot taking the WBONE/WETH pool first (the finding is
one-shot).

---

## 7. Methodology, sources, caveats

- **Read-only:** all L2/L1 reads via public RPCs (`rpc.shibarium.shib.io`,
  `ethereum-rpc.publicnode.com`); no keys, no signed/sent transactions. The Foundry PoCs are
  forks only.
- **State:** L2 block 19,476,110 (state) / 19,476,148 (CI); L1 block 26,215,845 / 26,215,857.
  Prices: DefiLlama spot 2026-10-18 ~01:00 UTC (BONE $0.055485, WETH $2,399.73, DAI $1.000178,
  USDT $0.999122); the PoC log uses the slightly earlier WETH $2,397.09.
- **Sources:** Shibarium explorer (`shibariumscan.io`) API for logs/txlists; Etherscan V2 for
  L1 role/log/tx data; verified sources of `RootChainManager` impl `0x1b50d902…`,
  `ERC20Predicate` impl `0xfffc2D78…`, `EtherPredicate` impl `0x3f3bF9Ce…`, `ChildERC20`;
  DefiLlama; GeckoTerminal; the wave-2 finding `zombie-hunt-iv/wave2/d2b-staleprice.md` and
  the bridge lane `wave2/v8-shibarium.md`.
- **Caveats:** the WBONE contract is unverified (its 1:1 behavior is fork-proven, not
  source-proven); the L1 payout test uses a crafted log (the end-to-end path is evidenced by
  the real 2026-10-02 batch tx); the WETH buffer is thin; the trade is one-shot and sensitive
  to the exact reserves; the 2026-10-18 prices move.
- **Negative results documented:** DAI/WETH and WBONE/USDT pools are active but tiny-hop;
  fake WBONE is un-mintable; DAMN/WBONE is a circular-price trap; the emergency bridge
  `0xda9CE761…` is abandoned; the L2 DAI/USDT supplies are unbacked at the L1 escrow.

## 8. Files

```
shibarium-wbone/
├── README.md                     # this report
├── summary.json                  # machine-readable summary
├── analysis/
│   ├── state.json                # live state snapshot (public RPCs)
│   ├── collect_state.py          # reproducible state collector (no keys)
│   ├── exit-analysis.md          # the exit question in detail
│   └── poc-local.log             # local 7/7 test log
├── poc/
│   ├── foundry.toml
│   ├── lib/forge-std/            # vendored
│   └── test/ShibariumWbone.t.sol # 7 tests
├── ci/
│   └── run.sh                    # light state snapshot for CI
├── ci-out/
│   └── state.json                # CI-produced snapshot
├── ci-log.txt                    # CI run log
└── ci-artifacts/                 # downloaded artifact (state + log)
```

**CI:** https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39082788804
