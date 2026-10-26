> For the complete documentation index, see [llms.txt](https://docs.wildcat.finance/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.wildcat.finance/using-wildcat/day-to-day-usage/market-access-via-policies-hooks.md).

# Market Access Via Policies/Hooks

How V2 hooks combine role providers, credentials, sanctions checks, allowlists and known-lender status to decide market access.

When you first encounter a Wildcat market, you will be prevented from depositing unless you meet certain requirements specified by the borrower, to make sure that they're not making use of funds sourced from Lazarus, or worse, Ripple enthusiasts.

The way that this worked in Wildcat V1 was that the borrower had to perform due diligence on each would-be lender that approached them and subsequently add their address to a controller contract via an on-chain transaction. This was a huge friction point, and one of the primary reasons we built V2.

Wildcat V2 abstracts this away by putting the `deposit` function behind a 'hook' (a piece of code that needs to succeed before access to the function is granted). We've built this in a way that borrowers can select arbitrary mechanisms tailored to their preferences, but the *most common* examples we expect to see are:

* Addresses that are not flagged as sanctioned by the Chainalysis sanctions oracle,
* Addresses that are members of a pre-determined set,
* Addresses that have some form of NFT or soulbound token testifying to their identity, and
* Addresses that have a credential testifying to off-chain circumstances.

The first example is the most accessible, and simply verifies whether or not the address applying for a credential is subject to a sanctions designation by the US, EU, UN and so forth, as provided by Chainalysis. Given that the entire protocol has defences against addresses flagged by Chainalysis (see [The Sentinel](/using-wildcat/day-to-day-usage/the-sentinel.md)), this category falls out naturally.

The second example is effectively the V1 model, but we didn't want to throw it in the bin: we just also didn't want it to be the *only* way that people could access Wildcat. We plan to evolve this slightly, however: if a borrower is an entity that has a significant number of OTC counterparties, Wildcat can look into deploy a hooks template which grants credentials by providing proof that your address is in the Merkle tree of that set.

The third example accounts for on-chain solutions such as [Coinbase Verifications](https://www.coinbase.com/en-gb/onchain-verify) and [Binance Account Bound Tokens](https://www.binance.com/en-GB/babt), assuming that the borrower is comfortable relying on these. In this case, access credentials are granted by signing a transaction that verifies that your address is in fact in possession of whatever is being sought out (i.e. an NFT in your wallet with a certain timestamp).

The fourth example is one that extends off-chain. Lenders may be required to upload KYC/KYB data to a third-party platform such as - for the sake of example - Netki, Fractal ID or Civic, in order to establish jurisdiction, extract evidence of accredited investor status and so on, and leverage a third-party wallet such as Privado or a ZK solution such as Keyring Network to relay that information onwards.

All of these are implemented via *role providers*, smart contracts deployed by the borrower that enforce the check, following a fairly loose specification: more on this in [Access Control Hooks](/technical-overview/security-developer-dives/hooks/access-control-hooks.md). For the most part, Wildcat will make templates for commonly requested use cases available so that it's simply point-and-click plus some initial configuration for the borrower, but borrowers *are* capable of writing their own Eldritch horror role providers and deploying them themselves, should the urge overtake them.

We'll be able to illustrate this in far more detail once we have some live policies and markets available, but the TL;DR is: in most cases, we expect you to be able to onboard yourself to Wildcat markets without ever having to reach out to a borrower via Telegram or email.

## How Multiple Role Providers Are Evaluated

For the shipped `AccessControlHooks` template, a hook instance owns the access decision and its approved role providers supply possible credentials. Providers are alternatives: one valid, unexpired credential from any provider which is still approved by that hook instance is sufficient. A lender does not need to pass every configured provider.

The hook first accepts an existing unexpired credential. If none exists, it can validate provider-specific data supplied with the transaction, refresh an expired credential from its pull provider, and then try the remaining approved pull providers. The first valid result is stored and access succeeds. If no provider yields a valid credential, the restricted action reverts.

Consequently, evidence that a wallet satisfies one provider is not enough to predict a particular deposit unless the evidence also identifies:

* the market and its hook instance;
* the hook template and whether deposit access checking is enabled;
* whether that provider is currently approved and its configured credential time-to-live;
* the wallet's stored credential or the provider result/proof needed to create one; and
* whether the hook instance has explicitly blocked the wallet from deposits.

Some providers can be queried on-chain by wallet address. Others validate data which must accompany the deposit transaction, and the underlying off-chain verification may not be public. In that case, public chain state alone cannot prove that the wallet will pass. Custom hook templates may impose different or cumulative rules; the alternative-provider behaviour described here belongs to Wildcat's shipped `AccessControlHooks` template.

Access is only one part of deposit execution. Even after the hook accepts the wallet, the transaction can still fail because of the underlying-token balance or allowance, remaining market capacity, or minimum-deposit setting.

## Credential Applicability/Durations

Depending on the way that a market is configured by a borrower, gaining a deposit credential for one market may simultaneously grant you access to other markets the same borrower has deployed. This is contingent on the markets having been deployed with the same policy tied to each, so it's worth checking if you're able to access more offerings by the same borrower.

When you have acquired a deposit credential granting you access to one or more Wildcat markets, it's worth noting that it may eventually expire, depending on whether or not the borrower has set a 'Time-To-Live' limit on it. This is to reduce the risk of an address being compromised and funds being deposited from an entity that is not the party which initially received the credential (unlikely as this may be). Credentials can be refreshed, assuming that the role provider that granted it is still tied to the market: borrowers can add and remove role providers from their access hook at will.

Note also that any address that received a credential and either (i) deposited while it was active or (ii) received market tokens from a third party while it was active is marked as a *known lender*. Known lenders permanently retain the ability to file withdrawal requests, so that a borrower is incapable of removing all role provider contracts from a market and erasing the ability for anyone to exit.
