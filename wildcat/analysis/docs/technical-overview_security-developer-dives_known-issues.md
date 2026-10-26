> For the complete documentation index, see [llms.txt](https://docs.wildcat.finance/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.wildcat.finance/technical-overview/security-developer-dives/known-issues.md).

# Known Issues

Some aspects and quirks of the protocol codebase that may raise concern.

## **Avoiding Delinquency Fees**

If the borrower closes a Wildcat market while it is still in penalized delinquency, they will not have to pay out the remaining time worth of penalized delinquency fees as the timer will be set to zero.

We decided that this is an acceptable trade-off enabling lenders to access their funds immediately, rather than waiting what could range from days to weeks for a borrower to come good on their word.

## **Malicious/Delinquent Borrowers Can Lead To Loss Of Funds**

This one is fairly obvious but worth stating - if a borrower fails to repay their debt for any reason, lenders will inevitably lose funds.

If the borrower is malicious, they can hurt lenders in a variety of ways, including but not limited to: not repaying debt; adding themselves as a lender in order to withdraw beyond the borrow limit on a market they intend to default on; slowly reducing the APR by 25% every two weeks to avoid the penalty of an increased reserve ratio, and several other things.

## **Newer Withdrawals Lose Some Of Their Accrued Interest To Previous Withdrawals In The Same Batch**

This one is intentional but may initially seem erroneous.

If Alice creates a withdrawal batch with a request to withdraw 100 tokens while the scale factor is 1, and then Bob later requests a withdrawal of 200 tokens when the scale factor is 2 and they are in the same batch, Alice and Bob will both receive 150 underlying tokens: they have each been credited for 100 scaled tokens given to the batch.

This is very much desired behavior, as it prevents earlier lenders from being penalized for creating a batch (which benefits the other lenders). All interest earned on scaled tokens entered into a batch is distributed evenly to the lenders in the batch, as if they had all created their withdrawal requests at the same time.

The example given is also an extreme one: in practice it'd much more likely be a fraction of a percent.

## **Bad Hook Implementations**

If any of the hooks that are enabled for a market can revert unexpectedly, the corresponding market function may become permanently disabled. This is considered a known/unfixable issue with respect to the market, but if such an issue is actually discovered in a hooks template that has been developed and deployed, this is a major vulnerability that should be reported.

## **Sanctioned Account Handling Can Lead To Unexpected Behaviour On Markets With Withdrawal Restrictions**

If a market uses a hook with a withdrawal restriction, e.g. to prevent withdrawals before a specified date, sanctioned account handling may not work correctly as it will attempt to force the lender into a withdrawal, and those withdrawals are treated the same as any other.

This could lead to unavoidable interest payments to a sanctioned entity's escrow address (where the funds will go when withdrawals are eventually unrestricted).

## **Hooks Lack Some Specificity**

While one of the stated objectives of hooks is to enable auxiliary behavior based on the state of a Wildcat market (one example is a Masterchef-style contract), the hooks do not necessarily provide enough information to replicate the market state 1:1 in real time.

Specifically, because payment towards a withdrawal batch does not have its own hook, the hooks instance would need to query additional data and perform additional calculations to precisely track the balance of an account including its pending withdrawals in real time, or to know the exact state of a pending/unpaid withdrawal batch.

We anticipate that, for any features added in the future, considering an account to have burned their market tokens at the time a withdrawal is queued will be sufficient precision for the purposes we expect to need this for, and as such we consider the loss of 100% precision on the exact internal market state to be a reasonable sacrifice considering the additional cost such precision would impose.

Any other issues with the ability of a hooks instance to track the state of the market should be reported.

## **Conversion Between Scaled And Normalised Amounts Have Some Rounding Error**

We are aware that deposits, withdrawals, and even transfers incur some inevitable rounding error. We will only accept findings that show either:

* This dust is sufficient to break something in the market, or
* The rounding error can realistically be more than dust

So for example, we would not accept a finding that says you could do ten million transfers to accumulate ten million wei worth of the market token. On the other hand, in V1 there was a finding where the dust could cause a market to be impossible to close, which is why we now round down for withdrawal payments to a batch.

## **Some Assembly Blocks Leave Dirty Bits In Memory**

For example, in `HooksConfig`, all of the calls from a market to the various hook functions are done in assembly, with the calldata written to unallocated memory that is left as is at the end of the call. We would only accept a finding on this subject if it demonstrated a specific attack showing this is unsafe or can lead to buggy behavior.

## **Markets Can Be Constructed In A Way That Makes It Impossible For Anyone To Request A Withdrawal**

While we tried our best to ensure lenders who deposit to a market can not have their withdrawal rights revoked (by ensuring the deposit/transfer hooks are always enabled if the withdrawal hook is enabled), it is still possible for a borrower to maliciously prevent lenders from ever acquiring the necessary credential for withdrawals.

The way this would work is:

* Create a market with credentials required for withdrawal but not for deposit or transfers.
* Never add any role providers.
* Lenders can deposit, but since they'll never have a credential, they will never be given the `isKnownLender` flag, and thus can never withdraw.

Unfortunately it is not possible to remove this problem without eliminating certain kinds of market that are desirable, so we consider this in a similar vein to the issue with malicious borrowers simply not repaying their debt, in that it's up to lenders to be selective with who they lend to. As a mitigation, we force all markets deployed through the Wildcat frontend as having credentials required for deposit.

## **Reliance On Chainalysis**

If the Chainalysis sanctions oracle were to be compromised or otherwise start flagging accounts as sanctioned that in reality are not, that would lead to those accounts being frozen on all Wildcat markets they lend to.
