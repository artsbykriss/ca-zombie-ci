# zkLink Nova Arbitrator message spoofing — live pause-state verification (CA2 LOW-tail C)

**Date:** 2026-11-03 · **Chain:** Ethereum · **Status:** read-only; no transaction signed or broadcast.

**Verdict: LOW confirmed — live E-U is $0.00.**
The verification flaw is real and still deployed (the `Arbitrator` implementation is unchanged, the
public relayer is still whitelisted, the confused-deputy gateway is still registered). But the payout
leg is **paused**: `ZkLink.paused() == true` since **block 26,297,792 (2026-10-29T10:26:59Z)**, and
`_proveL2LogInclusion` is `whenNotPaused`. Direct calls at the head revert **`Pausable: paused`** for
both `proveL2MessageInclusion` and `requestL2Transaction`; the bridge's `finalizeWithdrawal` and
`claimFailedDeposit` both route through those proof functions, so no forged root can be paid out.
There is only **0.622821572451440221 ETH ($1,419.23)** left on Ethereum — below the $10k bar even if the
pause were lifted.

**Prior-coverage distinction (important):** our ZH4-P2 pass covered the **2026-10-17 $9.0M
`finalizeWithdrawal` batch** and correctly classified it as a **legitimate 2024 depositor exit**
(3,000 uniETH deposited May-2024, 15-claim Multicall3 batch, no attacker). This finding is a different
event: the **2026-10-27 → 10-29 Arbitrator transient-storage replay / `syncBatchRoot` forgery**, which
drained **$783,100** (DefiLlama `zklink-nova`, 2026-10-27, "Cross-Chain Message Spoofing") via txs
`0x8a7e38b9…` (block 26,295,187) and `0x4f3c23e7…` (block 26,294,188). ZH4-P2 did **not** cover that
mechanism; it is not a duplicate.

---

## 1. TL;DR

| Item | Value |
|---|---|
| `ZkLink` | `0x5fd9f73286b7e8683bab45019c94553b93e015cf` (ERC-1967 proxy; impl `0xfcc8ea69…9dbe`) |
| `Arbitrator` proxy | `0x1ee09a2caa0813a5183f90f5a6d0e4871f4c6002`; impl **unchanged** `0x7a0bb4805ecb7fd3c8dabbe4afa0e91cb1761e34` |
| Public relayer | `0x0fdc28e64772a70109d10fd068f859cfa7dea2c6` — `relayers == true` |
| Confused deputy | `EthereumGateway 0x83bc7394738a7a084081af22eec0051908c0055c` — `secondaryChainGateways == true` |
| `L1ERC20Bridge` | `0xad16edcf7deb7e90096a259c81269d811544b6b6` — 0 ETH; 0 USDC/USDT/WETH/WBTC/HEX |
| `ZkLink.paused()` | **true**, block 26,297,792 → present; no `Unpaused` event after |
| Pause tx | `0xb68b67b9e77209e9fd2d2976c5ca2b82750f81ad5951ccf6901b47971d7f013c` |
| Owner / forward-fee allocator | `0xdb4D755E3b8735314147b9bB146327C269701E2D` |
| ZkLink ETH | **0.622821572451440221 ETH = $1,419.23** |
| Forward fee unwithdrawn | **0.336731588888613576 ETH = $767.31** (claimable by owner even while paused → P) |
| User escrow | **0.286089983562826645 ETH = $651.91** (stuck while paused → S) |
| Live E-U | **$0.00** (confidence: high) |
| E-U-conditional if unpaused | ≤**$1,419.23** (still <$10k) |

---

## 2. The deployed flaw (still there)

`Arbitrator.claimMessage` (impl `0x7a0bb480…`, verified source, solc 0.8.25) does:

```solidity
assembly { tstore(claiming.slot, 1) }
Address.functionCall(_sourceChainCanonicalMessageService, _sourceChainClaimCallData);
bytes32 _finalizeMessageHash;
assembly { _finalizeMessageHash := tload(finalizeMessageHash.slot) }
require(
    _finalizeMessageHash == keccak256(abi.encode(_sourceChainL1Gateway, _receiveValue, _receiveCallData)),
    "Incorrect finalize data"
);
```

`receiveMessage` writes `finalizeMessageHash` transiently, but `claimMessage` never clears it. In one
transaction a second `claimMessage` can re-use the hash authenticated by the first claim, while the
“claim” call target/calldata are entirely caller-supplied. `EthereumGateway.sendMessage` is
`onlyArbitrator` and does `ZKLINK.call{value:_value}(_callData)`, so the second claim becomes
`ZkLink.syncBatchRoot(batch, attackerRoot, 0)` with `msg.sender == gateway`. A forged
`l2LogsRootHashes[batch]` then makes any attacker-chosen withdrawal message pass
`proveL2MessageInclusion`, and `L1ERC20Bridge.finalizeWithdrawal` pays the token.

The public entry is `SyncL2TxHashRelayer.claimPrimaryChainSyncL2TxHashMessage(...)` — public on a
whitelisted relayer. The trace of the real drain (tx `0x8a7e38b9…`, block 26,295,187) shows exactly that
two-claim sequence; 33 ERC-20s left the bridge in that tx. The implementation was deployed
2024-04-18 (block 19,682,403) and has **not** been upgraded since — the vulnerable code is still what
runs.

---

## 3. Why it cannot pay today

Measured at Ethereum block **26,334,539** (2026-11-03; the earlier pinned read at 26,334,356 gives the
same values):

| Gate | Live value | Consequence |
|---|---|---|
| `ZkLink.paused()` | **true** | `_proveL2LogInclusion` is `whenNotPaused` |
| `proveL2MessageInclusion(0,0,(0,0xdEaD,0x),[])` | reverts **`Pausable: paused`** | no forged-root proof can validate |
| `requestL2Transaction(...)` | reverts **`Pausable: paused`** | deposits/escrow refill blocked |
| `L1ERC20Bridge.finalizeWithdrawal(...)` | calls `zkSync.proveL2MessageInclusion` (source line shown below) | blocked at the proof gate |
| `L1ERC20Bridge.claimFailedDeposit(...)` | calls `zkSync.proveL1ToL2TransactionStatus` → `_proveL2LogInclusion` | blocked at the proof gate |
| `Unpaused(address)` events since block 26,297,792 | **0** | pause still in force |
| ZkLink ETH balance | 0.622821572451440221 ETH | $1,419.23 total |
| Bridge ETH / major ERC-20 | 0 / 0 | no ERC-20 payout pool |

Bridge source (`L1ERC20Bridge.sol`, verified impl `0x3203e813…7352`):

```solidity
bool success = zkSync.proveL2MessageInclusion(_l2BatchNumber, _l2MessageIndex, l2ToL1Message, _merkleProof);
require(success, "nq");
```

`claimFailedDeposit` similarly calls `zkSync.proveL1ToL2TransactionStatus(...)`, which routes through
`_proveL2LogInclusion` (`whenNotPaused`). The bridge implementation `0x3203e813…7352` embeds
`0x5fd9f732…015cf` in its runtime (5 occurrences), i.e. the same paused ZkLink proxy — not a different,
unpaused mailbox.

---

## 4. Value split and what each actor can do

| Actor / category | Amount | Call |
|---|---:|---|
| External unprivileged attacker | **$0.00 now**; ≤$1,419.23 if unpaused | would need `unpause()` (owner-only) |
| Privileged (owner / forward-fee allocator) | **0.336731588888613576 ETH = $767.31** | `withdrawForwardFee(owner, delta)` — no `whenNotPaused`; simulated successfully at the head (`0x` return) |
| Stuck while paused (user escrow) | **0.286089983562826645 ETH = $651.91** | legitimate withdrawals revert until unpause; then holders can exit (H-O) |
| Bridge / other chains | $0 on Ethereum; Linea/Arbitrum/Manta/zkSync escrows hold $1.48M/$306k/$127k/$117k per DefiLlama, but reachability through the Ethereum Arbitrator was not established (open lead) | not counted |

The owner can withdraw the forward fee **even while paused**, which is why the full 0.6228 ETH is not
all “stuck”: 0.3367 ETH is P, 0.2861 ETH is S/H-O.

---

## 5. E-U / H-O / P / S quantification

| Category | Value | Basis |
|---|---:|---|
| **E-U (live)** | **$0.00** | `paused() == true`; prove/deposit revert `Pausable: paused`; `Unpaused` count 0 |
| E-U-conditional (single admin `unpause()` without Arbitrator upgrade) | ≤**$1,419.23** | whole ZkLink ETH balance is payable through a forged withdrawal; still below $10k |
| H-O | $651.91 | user escrow withdrawable by legitimate proofs after unpause |
| P | $767.31 | forward-fee allocator = owner; `withdrawForwardFee` works while paused |
| S | $651.91 while paused | user escrow locked by the pause |

`ZkLink.paused()` is a one-transaction owner action, and the Arbitrator would still need an upgrade for
the root cause to be fixed. But even a full unpause leaves Ethereum at ~$1.4k — the $10k bar is not met.
The per-chain escrows are the only way this could become material, and the public relayer only emits the
fixed `syncL2TxHash` payload shape; the arbitrary `sendMessage` route needs a message-service fee that
the Arbitrator's `Address.functionCall` cannot forward. Treat that as an open lead, not a finding.

One nuance: `ZkLink.syncBatchRoot` itself is **not** `whenNotPaused` (only `_proveL2LogInclusion` is). An
attacker can therefore pre-stage a forged `l2LogsRootHashes[batch]` while the contract is paused; the
payout still cannot settle until unpause, and deposits are paused so the escrow cannot grow during the
pause. If the owner unpauses without upgrading the Arbitrator, the staged root is immediately usable.

---

## 6. Evidence / files

- `analysis/zklink_impl_abi.json`, `analysis/bridge_impl_abi.json` — verified implementation ABIs.
- `analysis/verify.sh` — reproduces every live read at the named block (public RPC, no keys).
- Pause event: `Paused(0xdb4d755e…)` at block **26,297,792**, tx `0xb68b67b9…f013c`,
  timestamp **1,793,269,619 = 2026-10-29T10:26:59Z**; `Unpaused` query from 26,297,792 → latest returns
  zero records.
- `Arbitrator` source at impl `0x7a0bb480…` contains the stale `finalizeMessageHash` transient-storage
  pattern quoted above; impl slot unchanged.
- Real drain: tx `0x8a7e38b9c2a7a40981317ba87fbaa2e50527ec412cefc2fb4c9e3184f8848ae9`, block
  26,295,187; second drain `0x4f3c23e75b9134e8cae5a462550daad42fbbc19242567fcc34c0a035e297462c`,
  block 26,294,188.
- DefiLlama: `zklink-nova` Ethereum TVL $1,414.06; hacks entry 2026-10-27 $783,100.

## 7. Caveats

- The pause is an admin mitigation, not a code fix. If the owner unpauses without upgrading the
  Arbitrator, the path reopens — but only ~$1.4k is on Ethereum, so the live value bar is still not met.
- The Linea/Arbitrum/Manta/zkSync escrows are large in aggregate; reachability from the Ethereum
  Arbitrator is unproven. Do not count them without a trace.
- The prior ZH4-P2 “legit exit” conclusion is about the Oct 17 batch, not this Oct 27–29 spoof; the two
  are different transactions and different mechanisms.

**CI (read-only re-verification):** https://github.com/artsbykriss/ca-zombie-ci/actions/runs/41647220393
