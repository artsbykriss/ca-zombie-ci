# ZH4-03 — the exit question, resolved

**Date:** 2026-10-18 · **Chain:** Shibarium (109) / Ethereum (1) · **Mode:** read-only; fork + public RPC + explorer logs; no transactions sent.

## Question

The wave-2 finding proved a stale-price arb in three Shibarium pools but left the exit
unverified: *can value actually leave Shibarium?* The finding's +$877 chained number assumed
DAI could be bridged out. This note tests the legitimate user exit paths for BONE, WETH, DAI
and USDT, and for the on-chain venues that could convert proceeds into an exit-able asset.

## Short answer

| Asset | Canonical exit | Status today | Evidence |
|---|---|---|---|
| **WETH** (child of native ETH) | pos-portal `RootChainManager.exit` → `EtherPredicate` → ETH | **OPEN** | EtherPredicate still has RCM as `MANAGER_ROLE`; real WETH exit batch paid 0.0343566 + 0.03 ETH on 2026-10-02; predicate holds 1.94056 ETH |
| **BONE** (native, plasma child `0x…1010`) | plasma `WithdrawManager` (7-day) | **OPEN** | `Withdraw` events for BONE on 2026-10-10 (1,260 + 144.9 + 1,850.85 BONE), 2026-10-04 (5,240 BONE), 2026-10-03 (85.57 BONE); `HALF_EXIT_PERIOD=302,400` |
| **DAI** | pos-portal `RootChainManager.exit` → `ERC20Predicate` | **FROZEN** | `ERC20Predicate.MANAGER_ROLE` = only `0x80Cc222E…` (team EOA); RCM role revoked 2025-09-12; zero DAI transfers from the predicate since; predicate escrow 37.84 DAI |
| **USDT** | same | **FROZEN** | same role gate; predicate escrow 0.904373 USDT |

**Consequence for ZH4-03:** the only exit-able leg is **WBONE → WETH → ETH**.
The chained **WBONE → WETH → DAI** (+$937 nominal) and **WBONE → USDT** (+$59.97 nominal)
are **not realizable**; executing them converts BONE into an L2-only token. The standalone
WBONE/WETH leg is **+$746.95 gross / ≈$739 net** at the 2026-10-18 prices, one-shot.

## 1. The two predicates are wired differently

The Shibarium L1 bridge is a Polygon `pos-contracts` fork. Two token types are live:

```
RootChainManager (RCM) 0x08C4b60fda8aA6239b7de7d165BCF6F1686Cad82
  tokenToType(DAI)        = 0x8ae85d84…  -> typeToPredicate = 0x6Aca26bF… (ERC20Predicate)
  tokenToType(USDT)       = 0x8ae85d84…  -> typeToPredicate = 0x6Aca26bF… (ERC20Predicate)
  tokenToType(0xEeee…)    = 0xa234e091…  -> typeToPredicate = 0xc3897302… (EtherPredicate)
  rootToChildToken(0xEeee…) = 0x8ed7d143… (L2 WETH)
  childToRootToken(0x8ed7…) = 0xEeee…    (native ETH)
```

### ERC20Predicate `0x6Aca26bFCE7675FF71C734BF26C8c0aC4039A4Fa` — frozen

Verified source (`ERC20Predicate`, solc 0.6.6):

```solidity
function exitTokens(address, address rootToken, bytes memory log)
    public override only(MANAGER_ROLE)
{ ... IERC20(rootToken).safeTransfer(withdrawer, amount); }
```

Live role state (Ethereum block 26,215,857):

```
getRoleMemberCount(MANAGER_ROLE) = 1
getRoleMember(MANAGER_ROLE, 0)   = 0x80Cc222EA02F4334F67e9E55E7412fed62599004  (EOA, code size 0)
hasRole(MANAGER_ROLE, RCM)       = false
```

Role history:

| Date | Event | Block |
|---|---|---|
| 2023-08-08 | `MANAGER_ROLE` granted to RCM `0x08c4b60f…` and team EOA `0x80cc222e…` | 17,868,608 |
| 2025-09-10 | granted to emergency contract `0xda9CE761…` (the Sept-2025 incident response) | 23,334,256 |
| 2025-09-12 | **revoked** from `0xda9CE761…` | 23,349,018 |
| 2025-09-12 | **revoked** from RCM `0x08c4b60f…` | 23,349,223 |

The RCM is the only contract that can call `exitTokens` in the normal user flow
(`RCM.exit(bytes)` → predicate). With the RCM role revoked, **any DAI/USDT exit reverts at
the predicate's access-control modifier**. The same `MANAGER_ROLE` gate protects `lockTokens`,
so **DAI/USDT deposits are frozen too** — the canonical DAI/USDT bridge is dead in both
directions and the existing L2 supply is orphaned. There have been **zero DAI and zero USDT
`Transfer` logs from the predicate since 2025-09-12**, confirming no user exit has completed.

Even a privileged rescue is capped by the predicate's escrow:

| Token | L1 escrow in predicate | L2 total supply | Backing |
|---|---:|---:|---:|
| DAI | 37.8372351900716073 DAI | 6,535.2791816818163573 | **0.579%** |
| USDT | 0.904373 USDT | 12,779.518189 | **0.0071%** |

So the 4,040.83 DAI in the DAI/WETH pool and the 266.53 USDT in the WBONE/USDT pool are
**not redeemable on L1** at all — the escrow is three orders of magnitude too small.

### EtherPredicate `0xc3897302aB4B42931cB4857050Fa60f53B775870` — open

Same `exitTokens` code, but the role set is different:

```
getRoleMemberCount(MANAGER_ROLE) = 2
  [0] 0x80Cc222EA02F4334F67e9E55E7412fed62599004  (team EOA)
  [1] 0x08C4b60fda8aA6239b7de7d165BCF6F1686Cad82  (RCM)   <-- still live
hasRole(MANAGER_ROLE, RCM) = true
```

`EtherPredicate.exitTokens` parses the child burn log (`Transfer(from, 0, amount)`),
requires `to == address(0)`, and sends `amount` ETH to `from`. The RCM still holds the role,
so the normal `RCM.exit(bytes)` flow pays ETH to the WETH burner.

## 2. Live evidence that the WETH exit works

`0xd8d66ca65e3811743278cba2a62f7292c2e58278d2271f969b2361db3a9177dc`
(block 26,103,909, 2026-10-02 10:01:23 UTC):

- top-level call to batch helper `0x09b7496152fe1136ecfdc60d79d40f56837fecf8` (`0x6c83a890`),
- 2 inner calls to `RCM.exit(bytes)` (`0x3805550f`) whose payloads contain the **WETH child
  token** `0x8ed7d143…`,
- EtherPredicate emitted two `ExitedEther` events and paid:
  - `0.03435660242474078 ETH` to `0x886940e82318b3c8c38017b19f2219989957fccd`
  - `0.03 ETH` to `0x9cda5a5bce0f6915fe9f4c1767f9bdfbad777888`
- The same helper has 760 batch-exit txs, the latest on 2026-10-06.

The EtherPredicate's ETH buffer is **1.940558599296224434 ETH** (block 26,215,857). The
ZH4-03 WETH output is **1.193132635970670183 WETH**, so the payout fits; after it, 0.747426
ETH remains. This is the binding constraint: WETH supply is 186.180882 WETH, so the predicate
is only **1.04% backed**; exits are first-come-first-served.

What the 1.94 ETH buffer does *not* do is cover the whole 186 WETH supply. The missing
~184 WETH was minted by the emergency depositor `0xda9CE761…` (it still holds
`DEPOSITOR_ROLE` on the L2 child tokens) during the Sept-2025 incident; it is not backed by
L1 ETH. The WETH exit is therefore real but **not scalable**: an attacker can take at most
the current 1.94 ETH buffer, and only if they exit before it is drained.

## 3. BONE (native) exit is also open, but 7-day

The plasma bridge is independent of the pos-portal predicates. `DepositManager`
`0x885fce98…` and `WithdrawManager` `0x5f683665…` (impl `0xD12B1d5f…`, deployed 2025-10-13)
are live:

- BONE deposits: `Deposit` logs on 2026-10-17 at blocks 26,213,745 (2 BONE) and 26,214,197
  (16.65 BONE); the depositors' L2 BONE balances (18.66 BONE / 196.4 BONE) confirm the mint.
- BONE exits: `Withdraw` logs (token `0x9813037ee2218799597d83D4a5B6F3b6778218d9`) on
  2026-10-10 block 26,162,022 (1,260 + 144.9 + 1,850.85 BONE), 2026-10-04 block 26,119,619
  (5,240 BONE), 2026-10-03 block 26,108,411 (85.57 BONE).
- `HALF_EXIT_PERIOD = 302,400` s (3.5 days) and the full exit is 7 days; `processExits` is
  permissionless.

This matters for **entry**, not exit: the attacker can bridge 38,084 BONE L1→L2 (deposit),
wrap it, sell it, and exit the WETH. The BONE path is also the fallback if the WETH buffer is
drained — but only if the WETH can be converted back to BONE at a fair price, which the L2
venues cannot do (see §4).

## 4. Can DAI/USDT be converted to an exit-able asset on L2?

No venue with real depth:

| Pair | Address | Reserves today | Implied price | Note |
|---|---|---:|---|---|
| DAI/WETH | `0xD7115c43…` | 4,040.83 DAI / 0.71556 WETH | 5,647 DAI/WETH (2.34× fair) | tiny router hops (507 swaps since blk 18M; last 2026-10-15, 0.0000167 WETH) |
| DAI/WBONE | `0x7e308813…` | ~$0.22 | — | dust |
| DAI/USDT | `0x833e4b8e…` | ~$0.018 | — | dust |
| DAI/WBTC | `0x65f1ca5c…` | ~$0.75 | — | dust |
| USDT/WETH | `0x41e7756c…`, `0x30b17fa4…` | ~$4 + ~$2 | — | dust |
| WBONE/USDT | `0x4fC0DB98…` | 1,322.46 WBONE / 266.53 USDT | 0.2016 USDT/WBONE (3.63× fair) | 385 swaps since blk 18M; last 2026-10-13, 2.64 USDT hop |

Selling DAI back into the DAI/WETH pool gives WETH at the pool's 5,647 DAI/WETH price, i.e.
~$0.42 per DAI — a ~58% loss versus face. There is no fair DAI→WETH/BONE venue. USDT is
worse: the only USDT/WETH pools hold ~$6 combined.

The **fake-WBONE** pools (`0xC76F4c81…`, total supply 837,571) hold real WETH/USDT
(~$970 WETH side, ~$516 USDT side) but the fake token's `deposit()` reverts
`Invalid sender address`; it cannot be minted. Even if it could, the USDT side is frozen.
Dead end.

## 5. What this does to the ZH4-03 numbers

| Route | BONE in | Output | Gross nominal | Exit-able? | True net |
|---|---:|---|---:|---|---:|
| WBONE → WETH (standalone) | 38,084.09 | 1.19313 WETH | **$746.95** | **YES** (EtherPredicate) | **$739.07** |
| WBONE → WETH → DAI (chained) | 15,718 | 1,808.82 DAI | $937.07 | NO | **-$872** if executed (DAI trapped) |
| WBONE → USDT | 1,196.75 | 126.48 USDT | $59.97 | NO | **-$66.40** if executed |
| DAI/WETH standalone (sell WETH) | 0.38234 WETH | 1,404.44 DAI | $488.23 | NO | **-$917** if executed |

The standalone WETH leg is the only rational execution. It also **consumes** the WBONE/WETH
pool's mispricing: after selling 38,084 WBONE the pool's marginal price equals the market
price, so there is no second cycle. The ceiling is the one-shot **$746.95 gross**; the
$0.95k wave-2 ceiling was the sum of nominal legs that cannot exit.

## 6. Residual / what would reopen value

1. **DAI/USDT:** if the team re-grants `MANAGER_ROLE` on `0x6Aca26…` to a live RCM **and**
   tops up the L1 escrow (37.84 DAI / 0.90 USDT today), the chained +$937 / USDT +$60 legs
   become realizable in principle. Watch `RoleGranted`/`RoleRevoked` on `0x6Aca26…` and the
   DAI/USDT balances of the predicate. The escrow, not the role, is the hard blocker.
2. **WETH:** if the EtherPredicate is topped up (or the unbacked WETH is burned/reconciled),
   the exit capacity rises above 1.94 ETH. If the buffer is drained, the WETH leg's exit
   fails. Watch `EtherPredicate` ETH balance and `ExitedEther` events.
3. **Pool risk:** 99.96% of the LP is staked in gauge `0x0bC0b801…`; the factory's
   `pauser`/`feeManager` is an EOA `0x9FC924a7…` (`isPaused=false` today, `volatileFee=20`).
   A pause or fee change blocks the swap (privileged, not E-U).
4. **Competition:** no bot is trading the WBONE/WETH pool (0 swaps since block 18M; last swap
   2026-07-04). The DAI/WETH and WBONE/USDT pools have a tiny router bot, but it is not
   arbitraging the key pool at size.

## 7. Citations

- L2 blocks: 19,476,148 (CI PoC), 19,476,110 (state snapshot); chain id 109.
- L1 blocks: 26,215,857 (CI PoC), 26,215,845 (state snapshot).
- Pools: `0xe4dbeE5Fa46fB8A4D00FB719deDCAEDc91AE5F13`, `0xD7115c435eB221addbD3A1D15c95491ec0545f7f`,
  `0x4fC0DB98A912829b803D2fCFb40C12d5E9aFAe2c`.
- Factory `0xB9fbdFA27B7ba8BB2d4bB4aB399e4c55F0F7F83a`: `isPaused()=false`, `volatileFee()=20`,
  `stableFee()=1`, `feeManager()=pauser()=0x9FC924a7c8678C7Bb13114Bd0C74E446937499fA`.
- L1: `RCM 0x08C4b60f…`; `ERC20Predicate 0x6Aca26bF…`; `EtherPredicate 0xc3897302…`;
  `DepositManagerProxy 0x885fce98…`; `WithdrawManagerProxy 0x5f683665…`.
- Exit tx: `0xd8d66ca65e3811743278cba2a62f7292c2e58278d2271f969b2361db3a9177dc` (2026-10-02).
- Role history: RoleGranted/RoleRevoked logs on `0x6Aca26…` at blocks 17,868,608 / 17,868,608 /
  23,334,256; RoleRevoked at 23,349,018 / 23,349,223.
- BONE `Withdraw` logs: blocks 26,162,022 / 26,119,619 / 26,108,411. BONE `Deposit` logs:
  blocks 26,213,745 / 26,214,197.
- Token supplies (L2, block 19,476,110): WETH 186,180.882062108962902; DAI
  6,535.2791816818163573; USDT 12,779.518189; WBONE 803,611.317072142350078769.
- DefiLlama spot at 2026-10-18 ~01:00 UTC: BONE $0.055485081, WETH $2,399.73, DAI $1.000178,
  USDT $0.999122. The PoC log uses the slightly earlier $2,397.09 WETH and $0.055485081 BONE.
