# Code4rena 2025-04-cabal-liquid-staking-token — H-01 (verbatim excerpts)

Source: https://code4rena.com/reports/2025-04-cabal-liquid-staking-token
Mirror PDF: `0xCabal/cabal-audits@d6fd0ad` → `25:04 Cabal Mainnet - Code4rena.pdf`
(sha256 of PDF not material; 30 pages; **no mitigation-review / team-response section** — the
report ends with `Disclosures`, identical to the web report.)

Audit window: **2025-04-28 → 2025-05-05**. Report published **2025-05-28**.
Scope: **8 Move contracts, 2,574 LoC** ("Cabal Liquid Staking Token").
Code repo: **https://github.com/code-423n4/2025-04-cabal**
Audited commit referenced in every finding link: **`5b5f92ab4f95e5f9f405bbfa252860472d164705`**
(matches `git log` in the cloned repo: `5b5f92a Merge pull request #1 … contest-preparation`,
dated 2025-04-28).

## H-01 title
> LP unstaking only burns the shares but leaves the underlying tokens in the system, which
> distorts the shares-to-tokens ratio and leads to incorrect amounts being calculated during
> staking and unstaking

Wardens: TheSchnilch, ret2basic.

## Finding description (verbatim)
> When a user unstakes LP tokens, the corresponding shares (Cabal tokens) are burned. However,
> the actual undelegation from the validator will occur only after a delay of up to 3 days.
> During this period, the shares are already burned, but the underlying tokens are still
> included in shares-to-token conversions. This is a problem because, in `process_lp_unstake`,
> the amount of tokens to unbond is calculated as follows:
> `…/sources/cabal.move#L1051-L1054`
>
> The `lp_amount` is calculated based on the amount of tokens actually staked on the validator.
> This includes tokens that are pending to be undelegated (`unstaked_pending_amounts`), for
> which the Cabal tokens have already been burned.
>
> This means that the `unbonding_amount` is also calculated incorrectly because the `lp_amount`
> is too high. As a result, the `unbonding_amount` will also be too high, and the unstaker will
> receive too many tokens that are actually belonging to other users.
>
> Since the Cabal tokens a user receives are also calculated this way in `process_lp_stake`,
> users will receive too few shares when there are pending undelegations.

## Impact (verbatim)
> Because users receive too many tokens that actually belong to other users, and since this
> issue occurs during normal unstaking and staking, it is high severity.

## Recommended mitigation (verbatim)
> The `unstaked_pending_amounts` should be subtracted from the `lp_amount` to correctly account
> for the pending tokens to be undelegated, for which the Cabal tokens have already been burned.

## Affected audited functions (commit 5b5f92a, `sources/cabal.move`)
- `process_lp_unstake` (L1043–L1085) — **buggy**:
  `lp_amount = reward_amount + pool_router::get_real_total_stakes(...)`; then
  `ratio = unstake_amount / supply(...)`; `unbonding_amount = ratio * lp_amount`.
  `supply` is read **after** the burn (`initiate_unstake` burns before the queued
  `process_lp_unstake` runs), while `lp_amount` still contains the burned-but-still-delegated
  tokens → over-claim.
- `process_lp_stake` (L938–L987) — **buggy** inverse: minted shares use
  `supply / (reward + real_total_stakes)` with no pending correction → under-mint.
- `get_estimate_unstake_amount` (L494–L509) — same over-stated estimate (no pending term).
- `initiate_unstake` (L688–L705), `unstake_lp`, `batch_undelegate_pending_lps` (L603–L620) —
  the burn/queue/pending machinery.

## Audit PoC (verbatim, `tests/core_staking_test.move`, run `initiad move test -f test_poc`)
- A stakes 100 ulp → supply 100, delegated 100.
- B stakes 50 ulp → supply 150, delegated 150.
- B unstakes 50 → shares burned to 100; pending = 50.
- A unstakes 50 (half of his shares) → **should get 50, actually gets 75**.
  (`debug::print(&unbonding_amount)` at line 1334 of the audited `cabal.move`.)

## Team response / mitigation status
**None published.** The C4 report has no "Mitigation Review" section and no team response for
H-01. The mirror PDF in `0xCabal/cabal-audits` is the same report. Therefore the deployed-code
question had to be answered directly from chain bytecode (this folder).
