> For the complete documentation index, see [llms.txt](https://docs.wildcat.finance/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.wildcat.finance/security-measures/spherex-protection.md).

# SphereX Protection

How Wildcat uses SphereX on-chain runtime protection to reject exploit-shaped transactions.

The Wildcat protocol contracts are protected on-chain by [SphereX](https://www.spherex.xyz/).

Without going into too much detail here, all external functions are wrapped in a modifier which sanity-checks any given transaction against a training set, reverting said transaction if it deviates too far from expected behaviour.

The net effect of this is that transactions which appear 'exploit-like' in shape (in that they take a novel path through function calls, interact strangely with contract storage, utilise an abnormal amount of gas and so on) are not permitted to execute, with a report of the transaction being sent to an off-chain analytics engine in order to determine the root cause of the rejection.

In the event that the transaction is legitimate (e.g. follows a path that had not been covered by training data), the Wildcat team are capable of updating the reference set to permit that transaction - and others like it - to succeed going forwards.

The nature of this protection means that access to Wildcat markets - and the wider protocol - is continuous even while under attack: deposits and withdrawals are be permitted as usual, whereas hostile transactions are rejected.

In the event that SphereX ceases to exist, the on-chain nature of the protection means that we would only lose access to the off-chain analytics engine and ability to update the reference set. In this (extreme) scenario, we can simply detach the engine and continue on as before, albeit with some wasted gas costs on existing contracts due to routing through a dead modifier.

It is worth noting however, that as with all security measures, the existence of SphereX within the Wildcat codebase does not *guarantee* total safety. In the event that Wildcat's team is compromised, it is possible to update the reference set with a hostile transaction after it has first been identified and subsequently replay the transaction. More generally, it is possible for the engine to be replaced with a trivial variant that rejects *every* transaction, effectively freezing the protocol in place.
