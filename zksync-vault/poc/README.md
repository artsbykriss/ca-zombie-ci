# PoC — negative proof for SyncSwap Vault (V1)

**There is no exploit.** This folder documents the read-only proof that no unprivileged value-moving
path exists, plus the one positive primitive (excess attribution) and a live flash-loan
non-repayment test.

## 1. Why not a Foundry fork

Foundry/revm executes EVM bytecode. zkSync Era contracts are **EraVM** bytecode; `anvil`/`forge
--fork-url` cannot run them, and no zkSync Era fork backend is available in this environment. The
PoC therefore runs against the live chain via **`eth_call` with state overrides** — read-only,
nothing is signed, deployed or persisted. This mirrors the fork test's purpose: show the call path
reverts (or succeeds) against real deployed state.

## 2. Flash-loan non-repayment (the strongest "drain" candidate)

`flashLoan` sends tokens to a receiver, calls `onFlashLoan`, then requires
`postLoanBalance >= preLoanBalance` and `receivedFee >= fee`.

We inject (state override) a 39-byte EVM contract at `0x2222…2222` that returns the ERC-3156 magic
value `0x439148f0…8dd9` but **does not repay**. Call:

```
flashLoan(0x2222…2222, USDC, 1_000_000, 0x)   from 0x1111…1111
```

Result (live, reproduced in `ci/verify.py`):

```
execution reverted: INVALID_POST_LOAN_BALANCE
0x08c379a0...194e56414c49445f504f53545f4c4f414e5f42414c414e4345
```

Control: a receiver returning the wrong 32-byte value reverts
`IERC3156_CALLBACK_FAILED`. A successful loan is only possible if the receiver returns
principal+fee; it cannot reduce the vault.

## 3. Withdraw/transfer binding (negative tests)

From a fresh address with no internal balance:

| call | revert |
|---|---|
| `withdraw(USDC, attacker, 1)` | Panic `0x11` (`0x4e487b71…0011`) |
| `withdrawETH(attacker, 1e18)` | Panic `0x11` |
| `withdrawAlternative(USDC, attacker, 1e6, 0/2)` | Panic `0x11` |
| `transfer(USDC, attacker, 1e6)` | Panic `0x11` |
| `transferAndDeposit(USDC, attacker, 1e6)` | `TransferFromFailed` (`0x7939f424`) |

Positive control: the same `withdraw` called **from the USDC/WETH pool address** succeeds, proving
the debit is `msg.sender`-bound and the recipient is arbitrary — but only that pool contract can
initiate it.

## 4. Excess attribution (the only free-credit primitive, worth $0)

`deposit(token, to)` credits `token.balanceOf(vault) − reserves[token]` to any `to`. Live:

```
deposit(Zeeka 0xcadd7c5b…, fresh) -> 964086122000000000000000000   (spam token, no market)
deposit(USDC, fresh)              -> 0
```

Standing real-token excess across 2,825 tokens: **$0**. Spam tokens: 40, $0. One pool
(`0x1996ecc2…`) has 100 raw USDC excess = **$0.0001**, below gas.

## 5. Reproduce

```
bash ci/run.sh          # full suite: compile check + gates + sweeps
```

`ci/verify.py` contains the exact calldata/state-override JSON. No keys, no transactions.
