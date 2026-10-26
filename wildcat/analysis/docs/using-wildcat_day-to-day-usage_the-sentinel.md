> For the complete documentation index, see [llms.txt](https://docs.wildcat.finance/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.wildcat.finance/using-wildcat/day-to-day-usage/the-sentinel.md).

# The Sentinel

What's the worst that could happen?

We do not expect this to happen to any users of the protocol, but we have accounted for the potential that a lender address is added to a national sanctions list such as the OFAC SDN in a repeat of the Tornado Cash incident of August 2022.

The strict liability nature of transfers to and from addresses that have been tagged in such a manner means that we need to account for the potential for them to poison a entire market.

Here's how we've handled it:

### Lender Gets Sanctioned

In the event that a lender address is sanctioned, the sentinel contract deploys an escrow contract between the borrower of a market and the lender in question. This happens on the earlier of i) the lender attempting to make a withdrawal request, or ii) any party taps a `nukeFromOrbit` function present within market contracts that forces the sanctioned lender into a withdrawal request. Once that withdrawal expires, any claimable assets for their withdrawal request can be executed using the normal `executeWithdrawal` function.\
\
However, instead of the underlying assets being returned to the lender, they are instead transferred to the escrow contract. Assets within an escrow contract can be released to the lender via the `releaseEscrow` function in two cases:

* The lender address is no longer flagged as being sanctioned by the Chainalysis oracle, or
* The borrower involved in that particular escrow contract specifically overrides the sanction status via the `overrideSanction` function.

Note that this power cannot be randomly used to erase lenders from markets: the Chainalysis oracle must return true when asked if the lender address is sanctioned in order for the escrow contract to be created.

We do not believe that Wildcat protocol users are at risk of a simultaneous malicious exploit of the Chainalysis oracle and excision from a market as a result - in fact we do not expect `nukeFromOrbit` to ever actually be called - but it's better to be prepared.

### Borrower Gets Sanctioned

In the event that the *borrower* of a market is added to the Chainalysis oracle, any markets that they have deployed are immediately considered irreparably poisoned: *all* lenders will be affected by strict liability if they withdraw assets after the borrower repays assets back to the market after this point.

If this happens, the archcontroller is likely to sever the market - this means that while it will still operate normally, it will no longer show up on the UI (which queries the archcontroller for a list of which markets to display), and escrow contracts cannot be created for it.

You're going to want to speak to a lawyer in your jurisdiction if you're a lender to a market where this happens: we don't have a good answer in code for this, since it's fundamentally an off-chain issue.
