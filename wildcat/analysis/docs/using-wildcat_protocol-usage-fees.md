> For the complete documentation index, see [llms.txt](https://docs.wildcat.finance/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.wildcat.finance/using-wildcat/protocol-usage-fees.md).

# Protocol Usage Fees

There's no such thing as a free lunch.

Wildcat has the ability to charge fees for the usage of its markets.

Once a borrower is added to the global registry by the archcontroller, they can freely deploy markets with customizable parameters (e.g., capacity, withdrawal periods) and access-control hooks.

However, one parameter that borrowers cannot modify is the protocol fee. This fee can take one or both of the following forms:

#### Origination Fee:

* Paid during market deployment.

#### Streaming Fee:

* A percentage of the base APR that accrues over the supply of assets, rather than the market’s capacity. This does not accelerate the rebase of market tokens.

For example, if a borrower deploys a market with a 10% base APR and a 5% streaming protocol fee, the effective rate paid is 10.5%. Lenders still receive the full 10% APR, while the remaining 0.5% accrues to the protocol. Adjusting the base APR proportionally affects the protocol fee. For instance, lowering the base APR to 8% reduces the effective rate to 8.4%.

Protocol fees are not applied to penalty APRs. If a market with a 10% base APR incurs a 20% penalty APR, the total rate is 30.5% (10% + 0.5% + 20%), not 31.5%.

Protocol fees have seniority over lender claims within a market. When withdrawing reserves, lenders can only access the amount net of any accrued but unpaid protocol fees.

The archcontroller owner can adjust the fee configuration of active markets, with changes applied retroactively in V2 markets. For example, if a market launches with a 0% streaming fee and this is later increased to 5%, the new fee takes effect once the associated hook instance contract is updated. Origination fee adjustments do not apply to existing markets.

At the launch of Wildcat V2, the default fee was set at **5% streaming with no origination fee**. Streaming protocol fees are hard-capped at 10% of the base APR.
