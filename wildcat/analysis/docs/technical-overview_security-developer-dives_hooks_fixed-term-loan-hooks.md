> For the complete documentation index, see [llms.txt](https://docs.wildcat.finance/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.wildcat.finance/technical-overview/security-developer-dives/hooks/fixed-term-loan-hooks.md).

# Fixed Term Loan Hooks

The fixed-term variant of the access-control hooks, adding a withdrawal-blocking fixed term.

The fixed term loan hooks template is identical to the access control hooks template with one additional feature - the borrower can define a timestamp before which the market is considered a "closed term" loan, where withdrawals are disallowed. This expiry time can be reduced but can not be set to a later date after deployment.

## `onCreateMarket`

When deploying a market, the borrower must provide an ABI encoded timestamp for the market's `fixedTermEndTime` in the `hooksData` field of `HooksFactory.deployMarket` or `HooksFactory.deployMarketAndHooks`. This time cannot be in the past and can not be more than one year in the future. They can optionally provide a minimum deposit amount by setting `hooksData` to the ABI encoded tuple `(fixedTermEndTime, minimumDeposit)`.

The `onQueueWithdrawal` hook will always be enabled, but will only require access if the borrower's provided config had `useOnQueueWithdrawal` enabled, which will also affect the transfer and deposit hooks in the same way as `AccessControlHooks`.
