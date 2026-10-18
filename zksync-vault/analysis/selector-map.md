# Selector map — SyncSwap Vault (V1), zkSync Era `0x621425a1Ef6abE91058E9712575dcc4258F8d091`

Source: `contracts/vault/SyncSwapVault.sol` + `VaultFlashLoans.sol` (SyncSwap core-contracts, commit
`5285a3a7b2b00ca8b7ffc5ae5ce6f6c6195e4aa7`, 2023-05-04; vault files last changed 2023-03-16).
The deployed EraVM runtime is **byte-identical** to this source compiled with zksolc 1.3.5 / solc 0.8.15
(optimizer on, runs 200) — see `decompilation.md`. The 25-slot dispatch table was extracted from the
runtime at bytes 28,576–29,343: 24 public functions + the `0xffffffff` sentinel. There is **no hidden
selector**, no `sweep`, no `execute`, no `delegatecall`, no `upgradeTo`.

| # | Selector | Function | Auth / gate | Value effect |
|---|---|---|---|---|
| 1 | `16c38b3c` | `setPaused(bool)` | `onlyOwner` | flash-loan pause only |
| 2 | `2d2da806` | `depositETH(address to)` | permissionless, `nonReentrant` | credits `msg.value` to `to`; pays value |
| 3 | `4782f779` | `withdrawETH(address to,uint256 amount)` | permissionless, `nonReentrant` | debits `balances[0][msg.sender]`; checked underflow |
| 4 | `511de15b` | `transferAndDeposit(address token,address to,uint256 amount)` | permissionless, `nonReentrant` | `safeTransferFrom(msg.sender→vault)`, credits actual delta; no `from` param |
| 5 | `5c975abb` | `paused()` | view | — |
| 6 | `5cffe9de` | `flashLoan(address receiver,address token,uint256 amount,bytes data)` | permissionless, `nonReentrant`, `whenNotPaused` | sends from raw balance; requires `post ≥ pre` + fee |
| 7 | `613255ab` | `maxFlashLoan(address token)` | view | raw `token.balanceOf(vault)` |
| 8 | `6b6b9f69` | `setFlashLoanFeePercentage(uint256)` | `onlyOwner`, ≤10% | fee config |
| 9 | `6cb568c1` | `withdrawAlternative(address token,address to,uint256 amount,uint8 mode)` | permissionless, `nonReentrant` | same debit as `withdraw`; mode only selects ETH/WETH wrapping |
| 10 | `715018a6` | `renounceOwnership()` | `onlyOwner` | ownership renounce |
| 11 | `8da5cb5b` | `owner()` | view | — |
| 12 | `a16e5112` | `flashLoanFeeRecipient()` | view | — |
| 13 | `b914cc64` | `setFlashLoanFeeRecipient(address)` | `onlyOwner` | fee config |
| 14 | `beabacc8` | `transfer(address token,address to,uint256 amount)` | permissionless, `nonReentrant` | internal transfer; debits `msg.sender`, credits `to` |
| 15 | `c499f8ce` | `flashLoanFeePercentage()` | view | 5e14 (0.05%) live |
| 16 | `cfaa541e` | `flashLoanMultiple(address,address[],uint256[],bytes)` | permissionless, `nonReentrant`, `whenNotPaused` | Balancer-style; sorted unique tokens; requires full repayment + fee |
| 17 | `d66bd524` | `reserves(address token)` | view | total attributed balance |
| 18 | `d9caed12` | `withdraw(address token,address to,uint256 amount)` | permissionless, `nonReentrant` | debits `balances[token][msg.sender]`; `to` is recipient only |
| 19 | `d9d98ce4` | `flashFee(address,uint256)` | view | fee = amount × 5e14 / 1e18 |
| 20 | `ec85b12b` | `ERC3156_CALLBACK_SUCCESS()` | view | constant |
| 21 | `f2428621` | `wETH()` | view | immutable `0x5AEa…9a91` |
| 22 | `f2fde38b` | `transferOwnership(address)` | `onlyOwner` | ownership |
| 23 | `f7888aec` | `balanceOf(address token,address account)` | view | wETH remapped to native key |
| 24 | `f9609f08` | `deposit(address token,address to)` | permissionless, `nonReentrant` | **only free-credit path**: credits `token.balanceOf(vault) − reserves[token]` to any `to` |
| — | `ffffffff` | sentinel | — | EraVM dispatch terminator |

## Value-moving paths and what gates them

- **Withdraw / withdrawETH / withdrawAlternative / transfer** — the debit key is always `msg.sender`;
  `to` is only the recipient. A fresh caller with zero internal balance reverts with Panic `0x11`
  (`0x4e487b71…0011`). Live-tested (see `analysis/gates.txt`, `ci-out/verify.log`).
- **transferAndDeposit** — pulls `safeTransferFrom(msg.sender, vault, amount)` and then credits the
  **actual balance delta** (`balanceOf(vault) − reserves`). An unfunded caller reverts
  `TransferFromFailed` (`0x7939f424`). No `from` parameter exists to spoof.
- **deposit** — credits any pre-existing **unattributed** balance (`token.balanceOf(vault) − reserves[token]`)
  to a caller-chosen `to`. This is the only permissionless value-capture primitive. At the measured
  block USDC/USDT/ZK/WBTC/etc. excess was exactly 0; 40 spam-token excesses were worth $0.
- **flashLoan / flashLoanMultiple** — the receiver callback must return the ERC-3156 magic value, then
  the vault requires `postLoanBalance ≥ preLoanBalance` and `receivedFee ≥ fee`. A live state-override
  simulation with a receiver that returns the magic value but does **not** repay reverts
  `INVALID_POST_LOAN_BALANCE`; a receiver returning the wrong value reverts `IERC3156_CALLBACK_FAILED`.
  The vault sends tokens before the callback, but every state-changing entrypoint is `nonReentrant`.
- **Owner functions** — `setPaused` (flash loans only), fee config, ownership. The owner **cannot
  withdraw or sweep** any token; there is no such selector and no proxy/upgrade path.
