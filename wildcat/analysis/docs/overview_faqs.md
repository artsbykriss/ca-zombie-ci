> For the complete documentation index, see [llms.txt](https://docs.wildcat.finance/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.wildcat.finance/overview/faqs.md).

# FAQs

Answers to common questions about balances, withdrawals, delinquency, market access, integrations, security and support.

## Withdrawals

### Why isn't all of my withdrawal claimable, and when will I receive the rest?

There are three common reasons:

* The withdrawal cycle has not yet ended.
* The batch has expired but has only been partly funded. The available liquidity is then divided proportionally between the lenders in that batch.
* Liquidity is present, but the relevant market state or unpaid withdrawal batches have not yet been processed.

Depending on the circumstances, anyone may call either `updateState()` or `repayAndProcessUnpaidWithdrawalBatches(0, 10)`. The latter adds no new repayment and attempts to apply liquidity already held by the market to as many as ten unpaid batches.

Wildcat Labs now automates most of this second kind of processing through a sentinel service operated as a courtesy to users. This forms part of what is tentatively called the **Hydra executor**: infrastructure for making the various pokes, calls and invocations which help the protocol provide a smoother user experience. The underlying functions remain public and can still be called manually.

You may claim the amount already available without forfeiting the unfunded remainder. That remainder stays queued until the batch receives further liquidity.

A withdrawal request cannot be cancelled or reversed once it has been queued.

Older expired batches are funded before newer ones. If the market does not hold enough liquidity, the borrower must return further assets before the outstanding amount can become claimable.

In the app:

* **Ongoing** means the withdrawal cycle has not yet ended.
* **Claimable** is the amount presently available to withdraw.
* **Outstanding** is the portion still waiting to be funded.

See [Making withdrawals](/using-wildcat/day-to-day-usage/lenders.md#making-withdrawals).

***

### Why are my wallet balance, transferable amount and claimable amount different?

They describe different assets or stages of a withdrawal:

* **Wallet balance** is the rebasing market-token balance currently held by the address. It represents the address's unqueued lender position and normally rises as interest accrues.
* **Transferable amount** is the portion of that wallet-held market-token balance which the market's transfer policy permits the address to send. Open markets permit arbitrary recipients, restricted markets require an eligible recipient, and disabled markets permit transfers only back to the market for withdrawal. Transferability does not measure market liquidity.
* **Claimable amount** is underlying asset already allocated to that address's withdrawal batches and presently available to claim. It is determined by the withdrawal cycle and batch funding, not by the address's remaining market-token balance or its ability to transfer those tokens.

Submitting a withdrawal request moves the requested market tokens out of the lender's wallet. As liquidity is assigned, queued market tokens are burned and the corresponding underlying asset becomes claimable. A partly funded batch can therefore have a claimable amount smaller than the amount requested, while any market tokens which were not queued remain a separate rebasing wallet balance.

See [Reading lender balances](/using-wildcat/day-to-day-usage/lenders.md#reading-lender-balances).

***

### When do withdrawal cycles start and end?

Withdrawal cycles do not begin at a fixed time each day. The first withdrawal request made while no cycle is active starts a new cycle.

Its expiry is calculated using that market's configured withdrawal-batch duration. Later requests made during the same cycle join the existing batch and receive the same expiry.

Once the cycle expires, another cycle does not start automatically. A new one begins when the next eligible withdrawal request is submitted.

***

### Does a requested withdrawal continue earning interest?

No. Tokens placed into a withdrawal batch stop earning interest from the start of that batch's cycle.

The batch records the market's scale factor when the cycle begins. If a lender joins the batch part-way through the cycle, their amount is adjusted back to that starting scale factor. This prevents a later participant from earning interest for part of a period during which the earlier withdrawal requests were already excluded from accrual.

Assets reserved for a processed withdrawal batch do not earn interest and cannot be borrowed again. They remain in the market until claimed.

***

### Can Wildcat bump or prioritise my withdrawal?

No. Wildcat cannot move one lender ahead of another, fund a withdrawal on a borrower's behalf, or submit a transaction from a user's wallet.

Expired batches are funded in chronological order. Within a batch, available liquidity is distributed proportionally between its participating lenders.

You may claim a partly funded amount while the remainder stays queued. The remaining withdrawal cannot be cancelled.

If the borrower has returned liquidity but it has not yet been allocated, anyone may call `repayAndProcessUnpaidWithdrawalBatches(0, 10)`. Wildcat Labs now automates most of these calls through its sentinel service, as part of the tentative Hydra executor, but the function remains public.

If the market state itself is stale, anyone may call `updateState()`.

If there is genuinely insufficient liquidity in the market, the borrower must return more assets before the outstanding withdrawal can be funded.

***

### How do I ping a market?

"Ping" is informal and context-dependent.

In discussions about bringing a market's accounting up to date, it usually means calling `updateState()`. This updates the market's state without requiring a deposit, repayment or withdrawal.

In discussions about pending or outstanding withdrawals, "ping" has generally meant calling:

```solidity
repayAndProcessUnpaidWithdrawalBatches(0, 10)
```

The first argument adds no repayment. The second asks the market to process up to ten unpaid withdrawal batches using whatever liquidity is already available. That liquidity is applied to expired batches in first-in, first-out order.

Wildcat Labs now automates most of this withdrawal-processing work through a sentinel service run as a courtesy to users. It forms part of the tentative Hydra executor, which performs the various pokes, calls and invocations needed across protocol markets to provide a smoother user experience.

Both functions remain public and may still be called manually:

* [`updateState()`](https://github.com/wildcat-finance/v2-protocol/blob/c7be4039f8f383a9dda4e45f63331c17d63f9ed9/src/market/WildcatMarket.sol#L26-L30)
* [`repayAndProcessUnpaidWithdrawalBatches()`](https://github.com/wildcat-finance/v2-protocol/blob/c7be4039f8f383a9dda4e45f63331c17d63f9ed9/src/market/WildcatMarketWithdrawals.sol#L279-L312)

***

## Interest, debt and market health

### Does the borrower pay interest on all deposits or only the amount borrowed?

Interest accrues against the market's outstanding lender supply, not merely the amount transferred out by the borrower.

If lenders deposit 4 million units and the borrower draws 3 million, interest still accrues on the 4 million represented by the outstanding market-token supply.

That supply falls as market tokens are burned through withdrawals. Once a closed market has been fully repaid and no lender supply remains, further interest no longer accrues.

***

### Why is a market marked delinquent or pending?

A market becomes delinquent when its available liquidity falls below its required liquidity.

That requirement may include:

* The liquidity demanded by the market's reserve ratio.
* Amounts needed for pending or processed withdrawals.
* Accrued protocol fees.

A market can therefore become delinquent because of withdrawals, accrued interest or fees even if the borrower has not made a new transfer.

The market first enters its configured grace period. Penalty interest applies only after the cumulative delinquency timer exceeds that grace period.

For a particular market, check its live reserve shortfall, grace period and delinquency time. The status alone does not establish why the shortfall occurred.

***

### What does delinquency change while my withdrawal is queued?

Delinquency, withdrawal interest, batch payment and claim timing are separate:

* **Interest:** the amount placed into the withdrawal batch stops earning interest from the start of that batch's cycle. Any market tokens which remain in the lender's wallet continue to rebase normally. Penalty APR applies to the market's outstanding lender supply after the grace threshold; it does not turn a queued withdrawal back into an interest-bearing wallet balance.
* **Payment and liquidity:** delinquency means the market holds less than its required liquidity. Pending withdrawals are part of that obligation, and new liquidity is applied to older expired batches before newer ones. Delinquency does not cancel or reprioritise the request.
* **Claim timing:** the configured cycle expiry does not move merely because the market is delinquent. Expiry makes the batch eligible for settlement, but only its funded portion is claimable. Any unfunded remainder stays queued until more liquidity is supplied and processed.

See [Delinquency and queued withdrawals](/using-wildcat/delinquency.md#what-delinquency-changes-for-a-queued-withdrawal).

***

### What should a borrower check regularly?

The protocol does not prescribe a daily operational ritual, but borrowers should monitor:

* Market reserves and available liquidity.
* Delinquency status, grace periods and penalty exposure.
* Ongoing, expired and unpaid withdrawal batches.
* Upcoming withdrawal expiries.
* Outstanding debt, accrued interest and protocol fees.
* Recent market events.
* The borrower wallet's underlying-asset balance and transaction readiness.

The [Telegram notification bot](/using-wildcat/telegram-notification-bot.md) can help surface relevant market events. It does not replace the borrower's own monitoring or any obligations contained in a market's legal agreement.

***

## Deposits and access

### I deposited but did not receive market tokens. Is the deposit delayed?

A successful deposit mints market tokens in the same transaction. There is no separate settlement period.

First confirm that both the token approval and the deposit transaction succeeded. The deposit transaction should emit a `Deposit` event.

If the deposit failed, check:

* The selected network.
* The underlying-token balance.
* The approved allowance.
* The market's remaining capacity.
* Its minimum-deposit setting.
* Whether the wallet has the required market credential.
* Any applicable market terms or Master Loan Agreement requirements.

When requesting support, provide the market address, wallet type, network, transaction hash and exact error message. Never provide a seed phrase or private key.

***

### Why does a market have a minimum deposit?

A minimum deposit is an optional, borrower-configured floor applied to each deposit transaction.

It still applies when a lender already has a larger position. It is not merely a minimum account balance.

There is no protocol-wide formula for choosing the value. A borrower may set it according to the market's capacity, asset, lender profile or operational requirements.

The default is zero, and the borrower can update it. A borrower may also set the minimum above the market's available capacity to prevent new deposits without changing the market's stated maximum capacity.

***

### How do I access the app or qualify to lend in a market?

Open [app.wildcat.finance](https://app.wildcat.finance), connect a supported wallet and accept the applicable terms.

Access is determined separately for each market under the borrower's chosen access-control policy. Depending on the market, this may involve:

* Self-service credential creation.
* Direct borrower approval.
* Verification through an external provider.
* Sanctions screening.

Check the market and borrower profile for its stated process. Wildcat cannot broker access, override the borrower's policy or transfer approval from one market to another.

See [Onboarding](/using-wildcat/onboarding.md) and the [Lender guide](/using-wildcat/day-to-day-usage/lenders.md).

***

### If my wallet satisfies one role provider but not another, may it deposit?

Under Wildcat's shipped `AccessControlHooks`, approved role providers are alternative sources of a deposit credential, not a checklist which every lender must satisfy. One valid, unexpired credential from any provider still approved by the hook instance is sufficient for the access check. A failed check against one provider does not override a valid credential from another.

The market's hook instance makes the final on-chain access decision; a role provider only supplies or validates evidence. To determine access for a particular wallet, the evidence must identify the market and wallet and show:

* which hook instance and access-control template the market uses;
* whether the provider is currently approved and whether its credential has expired under that provider's configured time-to-live;
* any stored credential, pull-provider result, or transaction-supplied proof required by that provider; and
* whether the wallet has been explicitly blocked from deposits.

Some evidence may exist only in provider-specific data supplied with the deposit transaction or in an external verification system. Without it, public market configuration alone cannot prove that the wallet will pass. A custom hook may also implement different rules, so the alternative-provider behaviour must not be assumed outside the shipped `AccessControlHooks` template.

Passing the access hook does not guarantee that a deposit will succeed: balance, allowance, capacity and minimum-deposit checks still apply.

See [How multiple role providers are evaluated](/using-wildcat/day-to-day-usage/market-access-via-policies-hooks.md#how-multiple-role-providers-are-evaluated).

***

### We applied to become a borrower and have not heard back. Who should we contact?

Reply through the channel used for the original application or contact <contact@thewildcat.foundation>.

Include the company name, approximate application date, email address used and the appropriate contact person. Do not send identity documents through Telegram or an unsolicited direct message.

See [Onboarding](/using-wildcat/onboarding.md) for the current process.

***

### Fireblocks is rejecting my deposit transaction. What should I do?

This is usually caused by a Transaction Authorization Policy (TAP) rule which blocks interactions with DeFi contracts.

Add a Contract Call TAP rule which allows the Wildcat market address you are trying to use, then place that rule above any generic blocking rules. Fireblocks documents the process in its [TAP examples](https://support.fireblocks.io/hc/en-us/articles/7361651981468-TAP-examples) guide, which requires a Fireblocks account.

***

## Data and integrations

### Can I read APR, capacity and debt programmatically?

Yes. The market contracts expose the principal values directly, including:

* `annualInterestBips()` for the base annual lender interest rate. One hundred basis points equals 1%.
* `maximumDeposit()` for the market's configured maximum deposit.
* `totalDebts()` for the market's current total debt.
* `currentState()` for a consolidated view of current market state.
* `balanceOf(account)` for a lender's current market-token balance.
* `getAccountWithdrawalStatus(account)` for the account's withdrawal status.

`annualInterestBips()` is the base lender APR. It should not be treated as including penalty interest or the protocol fee.

For batched and consolidated reads, use **`MarketLensV2`**.

Contract addresses are listed under [Contract deployments](/technical-overview/contract-deployments.md).

***

### How can I enumerate Wildcat markets?

Use the network's `ArchController`.

It exposes the registered-market count and paginated access to registered market addresses through `getRegisteredMarkets(...)`.

Registration does not necessarily mean that a market remains open for deposits. Consumers should also inspect each market's current state and filter closed markets where appropriate.

If the integration needs to group markets by hooks implementation, it can additionally query the relevant hooks factory for deployed instances or templates.

Addresses and results are network-specific. Do not combine registries from different chains without labelling them.

***

### How do I track my original deposits, current balance and loan history?

A lender's current market-token balance is rebasing. It represents the lender's present claim on the market's underlying assets, rather than a static record of the amount originally deposited.

Use the app's **Market History**, together with block-explorer records, to review deposits, transfers, withdrawal requests and claims.

Subtracting one balance snapshot from another is not a reliable substitute for transaction history. Balances may be affected by:

* Further deposits.
* Interest accrual.
* Transfers.
* Withdrawal requests.
* Partial funding and claims.
* Rounding.

For accounting purposes, reconstruct the position from events and transactions rather than relying on balance differences alone.

***

### Can I export annual borrowing, repayment and interest figures as CSV?

Yes. Download the [Wildcat Market CSV Exporter Claude skill](/using-wildcat/wildcat-market-csv-exporter.md). The Wildcat app itself does not currently produce a one-click CSV or PDF with annual borrowing, repayment and interest figures.

You can reconstruct the activity from the app's Market History, contract events, block-explorer transactions and indexed protocol data.

Give the skill a market address and it builds a verified transaction ledger, a complete decoded event history and a separate quarantine file for unrelated or potentially malicious token transfers.

Once those files exist, we have found that either Fable or Sol can derive follow-up reports, including annual borrowing, repayment and interest figures, without much fuss.

The exports are raw protocol records, not certified financial or tax reports. You may still need an accountant or another suitable provider to review anything used for formal reporting.

***

## Security

### Have all audit findings been resolved?

It would not be accurate to describe every published finding simply as "fixed".

The 2024 Code4rena review reported one high-severity and eight medium-severity findings. Wildcat then completed remediation work and two mitigation reviews.

Some findings were fixed through code changes. Others were accepted as design trade-offs or documented as intentional behaviour. The status depends on the finding.

See:

* The [Code4rena audit report](https://code4rena.com/reports/2024-08-wildcat).
* [Code security reviews](/security-measures/code-security-reviews.md).
* [Known issues](/technical-overview/security-developer-dives/known-issues.md).

An audit is scoped to particular code and a particular point in time. It should not be read as a guarantee that the protocol is free of risk.

***

## Contact and announcements

### Who should I contact about a partnership, listing or integration?

Use the appropriate channel in the [Wildcat Telegram community](https://t.me/+ewyCAZOA5_Y2Zjg0). This allows the team to route the enquiry to the right people without relying on unsolicited direct messages.

Borrower-onboarding or Foundation matters may instead be sent to <contact@thewildcat.foundation>.

Be wary of anyone who contacts you privately first while claiming to represent Wildcat. Where possible, confirm the person and conversation through a public community channel.

***

### Is there a Discord, and where should I ask for support?

Wildcat does not presently list an official public Discord.

For support, use the appropriate channel in the [Wildcat Telegram community](https://t.me/+ewyCAZOA5_Y2Zjg0). Foundation, onboarding or compliance enquiries may be sent through the relevant email channel.

The [Wildcat notification bot](https://t.me/wildcat_notifications_bot) is an automated notification service, not a support account.

Wildcat does not solicit users through purported Discord moderators. Treat unexpected direct messages, support offers and wallet links with suspicion.

***

### Are you hiring, and can I DM someone about a role?

Treat a role as genuine only if Wildcat has published it through an official channel.

Community administrators and support contributors cannot confirm unpublished or private recruitment exercises. Do not rely on unsolicited direct messages claiming to offer work.

If you have a relevant enquiry which does not correspond to a published vacancy, use the appropriate channel in the [Wildcat Telegram community](https://t.me/+ewyCAZOA5_Y2Zjg0).

Never pay an application fee, connect a wallet or sign a transaction as part of a recruitment process.

***

## Troubleshooting

### I have a Safe multisig. How do I connect it?

Open the [Safe](https://app.safe.global/) interface and add Wildcat as a [Custom App](https://help.safe.global/en/articles/40859-add-a-custom-safe-app).

Use `https://app.wildcat.finance` for the mainnet app or `https://testnet.wildcat.finance` when using Sepolia.

***

### The site is down or will not load. What should I do?

First confirm that you are using [app.wildcat.finance](https://app.wildcat.finance).

Record:

* Browser and version.
* Network and market.
* Whether the wallet connects successfully.
* Wallet type.
* The affected page.
* The exact error message.
* Whether the issue persists in a private window or with non-wallet extensions disabled.

Try a hard refresh and reconnect the wallet.

If a transaction appeared to fail, check its hash on the relevant block explorer before submitting it again.

Report the problem in the appropriate channel in the [Wildcat Telegram community](https://t.me/+ewyCAZOA5_Y2Zjg0). Include the diagnostic information above, but never share a seed phrase, private key or other secret.
