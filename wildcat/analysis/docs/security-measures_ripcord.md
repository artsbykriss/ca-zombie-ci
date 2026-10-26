> For the complete documentation index, see [llms.txt](https://docs.wildcat.finance/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.wildcat.finance/security-measures/ripcord.md).

# Ripcord: Emergency Withdrawal Recovery

Ripcord is a best-effort emergency tool that rescues a withdrawal already queued from a compromised lender wallet, executing it and forwarding the released funds to a safe wallet in one private, atomi

Ripcord is an emergency tool for a narrow but nasty situation: a lender's wallet has been compromised, and there is already a withdrawal queued from it. When that withdrawal is executed, the market releases the assets to the account that queued it, which is the compromised wallet. Left alone, anything watching that address can take the funds the moment they land. Ripcord tries, on a best-effort basis, to execute the withdrawal and move the released funds to a safe wallet in the same block, in one private, atomic bundle, so nothing watching the public mempool gets a chance to grab them first. There are no guarantees and no promises. Wildcat Labs built and maintains it, and the source is public at [github.com/wildcat-finance/ripcord](https://github.com/wildcat-finance/ripcord).

{% hint style="warning" %}
**Precondition.** Ripcord only helps if a withdrawal has already been requested from the compromised wallet. It executes an existing queued withdrawal for that account. If the tokens were moved off to a hostile address before that request went in, there is nothing Ripcord, or anyone, can do to get them back.
{% endhint %}

## The Problem

[`executeWithdrawal`](/technical-overview/function-event-signatures/market/wildcatmarketwithdrawals.sol.md) is permissionless: anyone can call it. But it always sends the released asset to whichever account queued the withdrawal, so once a wallet is compromised, calling it in the ordinary way just hands the funds to whoever is watching that address. The release and the rescue have to happen together, in a single block, with nothing able to slip in between them. That is the problem Ripcord exists to solve.

## How the Bundle Works

Ripcord puts up to three transactions into one block and submits them privately to block builders as an all-or-nothing bundle:

1. `repayAndProcessUnpaidWithdrawalBatches(0, N)`, optionally, to apply liquidity already sitting in the market to the batch before it is executed;
2. `executeWithdrawal(account, expiry)`, to release the asset to the account;
3. a signed ERC-20 transfer moving the released asset from the account to a safe destination.

The first two are permissionless, so any funded relayer can sign and pay for them. The third can only be signed by the account holder, and that is done offline, in their own tooling; the page never sees the key. Because the bundle goes to builders privately and lands all-or-nothing, the release in step two cannot be separated from the transfer in step three, so it cannot be front-run.

Inclusion depends on a builder actually winning the block with the bundle in it, so it stays best-effort. You may need to resubmit across a few blocks.

## Data and Funds

Market data shown in the tool is read-only and provided as is, without warranty, so check it against something you trust before you act on timing. The tool never asks for a private key or a seed phrase; the one signature it needs is produced offline. Submission goes from the operator's browser straight to the relay endpoints listed in the tool, not through whatever host is serving the page. Wildcat Labs the company is not in the submit path: the default relayer is run by a Wildcat Labs team member on their own private infrastructure, separate from Wildcat Labs' systems, and it can be pointed at any endpoint instead.

## Source and Self-Hosting

The frontend, the read-only proxy, the offline signer, and the deployment notes are public at [github.com/wildcat-finance/ripcord](https://github.com/wildcat-finance/ripcord). Ripcord holds no keys and moves no funds on its own. It reads a market's live state, works out which [withdrawal](/using-wildcat/day-to-day-usage/lenders.md) batch the account is in, walks the account holder through signing the forward transaction offline, and fires the bundle. Anyone can read the code and stand up their own instance.
