> For the complete documentation index, see [llms.txt](https://docs.wildcat.finance/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.wildcat.finance/technical-overview/security-developer-dives/hooks/how-hooks-work.md).

# How Hooks Work

The hookable market functions, HooksConfig flags, intermediate state, and the extraData calldata buffer.

Each of the following is considered a core function within the WildcatMarket contract which we may want a hooks contract to be able to track, impose restrictions on, or otherwise react to in some way:

* `deposit` (+ `depositUpTo`)
* `queueWithdrawal` (+ `queueFullWithdrawal`)
* `executeWithdrawal` (+ `executeWithdrawals`)
* `transfer` (+ `transferFrom`)
* `borrow`
* `repay` (+ `repayOutstandingDebt`, `repayDelinquentDebt`)
* `closeMarket`
* `setMaxTotalSupply`
* `nukeFromOrbit`
* `setAnnualInterestAndReserveRatioBips`

Each of these functions has a corresponding hook that can be called on the configured hooks contract, as well as a flag in the market's hooks configuration (`HooksConfig`) indicating whether the hook *should* be called.

When one of these functions on a market is called, the market will check if the corresponding hook is enabled; if it is, it will call the hook function on the configured hooks contract, providing the intermediate state (prior to applying the full effects of the relevant action, but after accruing interest and fees), the relevant data for the action, the caller address (except for borrower-only functions) and an optional `extraData` buffer supplied by the caller.

Hooks can not modify internal behavior of the market and do not have any privileged access to its state; rather, they are designed to be *reactive to* and *restrictive of* market actions. This means, for example, that a hook can not change who receives a transfer or force a lender into a withdrawal, but it can prevent a transfer from occurring or keep some internal state about the withdrawal.

## **Exceptions To The Above**

There are two exceptions to the behavior described above.

1\) The rule about not modifying the market behavior is violated by `setAnnualInterestAndReserveRatioBips` - when a market's APR or reserve ratio are changed, the associated hook has the ability to modify those two values.

2\) The rule about only providing intermediate state (i.e. before execution of the action) is violated by the `queueWithdrawal` functions - when a withdrawal is queued, the intermediate state provided to the hooks call is the state *after* the market's `pendingWithdrawalExpiry` is updated. This ensures the hook has access to the withdrawal expiry if that is ever needed.

## `extraData` Buffer

In a call to one of the core functions listed above, the caller can append arbitrary bytes to the end of the function calldata. If they do, these bytes will be provided to the call to the hooks contract in the `bytes extraData` field. The primary use-case for this field is for the access control hooks, where the caller may need to provide a signature, merkle proof, or some other verification data in order to be authenticated to a particular market.

The `extraData` field is not part of the market's function signatures; the raw bytes must be appended to the end without ABI offset or length fields, and without padding to the closest word (otherwise the calculated length will be incorrect).

For calls to `executeWithdrawals` and `nukeFromOrbit`, the optional buffer cannot be provided.
