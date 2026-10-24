# Exceed Finance — parent source-level analysis (read-only)

Program: `par1tyqusak2f2DXg9RHv78SVHNWXkJLSbtJZQSuWjV` (upgradeable, BPFLoaderUpgradeab1e)
ProgramData: `FtAx72dC6tg2hmocbzwDzKGXy9oNxvwB7xAi64em7xXP`, last deploy slot 454291151
**Upgrade authority: `87VfCnQ4d7XuZwriJAK7yADmqzrJQBx9FYMqCwdue5kv` (non-zero → upgradeable; P-risk)**

Public source (verified-build per docs): https://github.com/Exceed-Finance/exceed-program-library
(cloned to /tmp for reading; contains the codama-generated clients + unit tests + IDL-derived layouts.)

## Instruction set (discriminators recovered from generated clients)
- `stake` — accounts: access_control, pair, base_token_mint, staker_base_token_account, pair_base_token_account, lst_fee_account, lst_mint, staker_lst_account, price_feed, **staker [signer]**. → **permissionless** (fresh signer).
- `request_withdraw` (amount, merkle_proof) — **staker [signer]** → permissionless.
- `execute_withdraw` — **staker [signer]** → permissionless.
- `swap_lst` — **user [signer]** → permissionless (source/destination pair must share base mint).
- `update_pair_yield` (interval_apr_rate) — accounts: pair, **authority [signer]**, access_control → **P-gated**.
- `update_pair_limits` (deposit_cap, minimum_deposit, stake_fee_bps, swap_fee_bps, withdraw_fee_bps) — **authority [signer]**, access_control → **P-gated**.
- `fund_withdrawal_window` — **deposit_authority [signer]** → P.
- `vault_withdraw` — **authority [signer]** → P (moves pair base tokens to the authority).
- `create/close_withdrawal_window`, `restake_expired_withdraw` — window_authority [signer] → P.
- `withdraw_fees`, `manage_guardian`, `seal/unseal_program`, authority transfers → P.

## Access control (live `fVo899DhvJosC7DuN2T9p5GYfsTGJqTv6TDeE97YGBe`, read at slot 461004899)
- `is_whitelist_enabled = false` → staking/withdrawal is **permissionless** (no merkle proof).
- `is_sealed = false`; no guardians; no pending transfers.
- vault_authority = pair_authority = `WYSyHasQGFCtfHb1W5pFf64YCzvMSahJgBoZei5RrwJ` (a **wallet**, 0-len system account, i.e. an off-chain multisig per docs — "keys in multi-party custody").
- window_authority `F2x6FM19gx68ubHWxNBsJKQksM5N38QhmgYhEG7yLnHv`; deposit_authority `CpdVRBHtnDd3RbYzvESXdrAD5bhWdQNvbfLUfjJpQnTE`; unseal/access `DY9GqHNXBRxyS2cM4x8DasUwpRXzU2GDo2LFAefAjDkK`.
- `sol_usdc_feed_id = H6ARHf6YXhGYeQfUzQNGk6rDNnLBQKrenN712K4AQJEG` (Pyth SOL/USD).

## Rate model (from `clients/js/src/utils/rateCalculations.ts`, PRECISION = 1e12)
```
rate(now) = lastRate * (compounded + linear) / 1e12
  elapsed = now - lastTimestamp ; n = elapsed / secondsPerInterval ; rem = elapsed % spi
  compounded = intervalRate^n / 1e12^(n-1)     (loop of n iterations on-chain)
  linear     = (intervalRate - 1e12) * rem / spi
lstAmount(base)  = base * 1e12 / rate         (BaseToLst)
baseAmount(lst)  = lst * rate / 1e12          (LstToBase)
```
- **The rate is a fixed time-based schedule**, NOT derived from actual deployed capital. `interval_apr_rate` is set by the pair_authority (`update_pair_yield`).
- Mint (stake) and redeem (withdraw) use the **same** rate → symmetric, no rate arbitrage. Round-trip loses (floor).
- `WithdrawalRequest` stores `base_amount` **locked at request time** (no drift between request and execute).
- `execute_withdraw` pays from the **funded withdrawal window** (`window_base_token_account`), not the pair account.

## Live pair state (slot 461004899, ts 2026-10-24)
| symbol | pair | base | rate | lst supply | liability (base) | interval rate (APY) | lastTs age | depositCap |
|---|---|---|---|---|---|---|---|---|
| pikUSDC (=exUSDC) | EwqMpn… | USDC | 1.310690 | 453,461.483851 | 594,347.39 USDC | 1.000087045 (~10.0%) | 208.2 d | 10,000,000 USDC |
| exSOL | HwsGQ… | SOL | 1.055613 | 993.650330172 | 1,048.91 SOL | 1.000057513 (~6.3%) | 16.3 d | 100,000 SOL |
| exBTC | GpV9U2… | cbBTC | 1.032994 | 0.00823498 | 0.008507 cbBTC | 1.000018085 (~2.0%) | 13.1 d | 250 cbBTC |
| pikSOL | J6szVg… | SOL | 1.098231 | 855.267466892 | 939.28 SOL | 1.0 (0%) | 205.0 d | 0 |
| figUSDC | 7H59KP… | USDC | 1.036376 | 106.893384 | 110.78 USDC | 1.0 (0%) | 17.1 d | 0 |
| exETH | 5LBpmf… | 7vfCXT… | 1.037331 | 26.119819 | 27.09 | 1.0 (0%) | 17.1 d | 0 |
| pitUSDC / pitSOL | 12qKk… / AWXZo… | USDC / SOL | 1.0 | 0 | 0 | 1.0 | ~395 d | 0 |

**Pair base-token accounts hold ~0 of the base token** (e.g. exUSDC pair base acct `67f3oEHTLfkBcShmgtivVT5gzqVYrJ9HMP6oCRhS3n7Y` = 0 USDC; exSOL `8H5kdi2J…` = 0 SOL). Capital is deployed off-pair (Kamino/Jupiter per DefiLlama; the company's credit book) and redemptions are paid from authority-funded windows. ⇒ **scheduled liability ≫ on-pair capital** — this is the "schedule vs deployed capital mismatch". It is a **solvency/credit condition**, not a smart-contract exploit: there is no unprivileged instruction that mints LST without paying base at the same rate, or redeems above the scheduled rate.

## Errors
Program errors are 6000–6441 (`LiquidStakingError`). **3010 is NOT an Exceed error** — it is an Anchor framework code (`AccountNotEnoughKeys`), i.e. the attacker's account-substitution produced a malformed account list, not a passed authority check. `update_pair_limits`/`update_pair_yield` require `authority.is_signer` + membership in `access_control` (pair_authority) → **a fresh signer cannot pass** (they would get `InvalidAuthority 6007`, not 3010).

## Preliminary E-U verdict
**E-U $0 (medium-high)** pending child-B ELF/live-simulation verification:
- every value-moving authority instruction requires a signer matching an `AccessControl` authority field (P);
- `stake`/`request_withdraw`/`execute_withdraw`/`swap_lst` are permissionless but rate-symmetric and `base_amount` is locked at request time;
- no permissionless rate/limit setter;
- the residual is the schedule-vs-capital shortfall (H-O redeemers subject to window funding; the shortfall itself is S/company loss), plus the live **upgrade authority** `87VfCnQ4…` (P).
