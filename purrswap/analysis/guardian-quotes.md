# Guardian audit — verbatim quotes

Source: `github.com/GuardianAudits/Audits` → `AbracadabraMoney/2025-03-29_AbracadabraMoney_PurrSwap_Balancer_Aggregator.pdf`
(90 pp.; extracted locally with pypdf). Only the passages relevant to this finding are quoted.

## C-06 — No Validation For Oracles Used In Pools (CRITICAL, ACKNOWLEDGED)

> **DESCRIPTION** External oracles were introduced to the PMM as a way to obtain the i value, which
> reflects the external price of a token pair. When creating a pool, the deployer provides an oracle
> address. However, there is no validation for the oracle address provided, representing a significant
> security risk, as a malicious oracle can manipulate the i value and control pricing. This risk is
> particularly dangerous because it may not be immediately visible—it could only present itself
> mid-transaction when the oracle is queried.
>
> **Potential Attacks:**
> - **Price Manipulation:** The oracle returns an artificially low i value mid-swap, resulting in the
>   user receiving significantly fewer tokens (or none at all).
> - **Gas Griefing:** The oracle performs computationally intensive operations when queried, causing
>   transactions to become excessively expensive or fail due to insufficient gas.
> - **Read-only Reentrancy:** While most of PurrLP's functions are protected by the nonReentrant
>   modifier, external integrators may not have this protection. A malicious oracle could re-enter
>   mid-transaction, potentially leading to unintended side effects.
>
> While PurrLP is designed to be permissionless, this flexibility introduces significant security
> risks—especially for pools deployed through the protocol's Router and Factory contracts. Users may
> assume these pools are inherently safe, but without oracle validation, they remain just as vulnerable
> to manipulation as manually deployed pools.
>
> **RECOMMENDATION**
> - The Factory contract should enforce that only protocol-approved oracles are used. The protocol can
>   maintain a whitelist of valid token-pair oracles.
> - At the Pool level, arbitrary oracles could still be allowed, but this risk should be explicitly
>   documented for users.
>
> **RESOLUTION** Status: Acknowledged.

## C-07 — Wrong initial target updates (CRITICAL, ACKNOWLEDGED)

> **DESCRIPTION** As described in the following issue from the previous audit, if the ratio used in
> buyShares is not 1:1, then R_STATE will be set to ONE. During the initial mint, _setReserves() will
> also set the base and quote reserve to the raw contract balance of these tokens, resulting in a
> R = 1 state even though the targets don't match the reserves.
> This leads to wrong target updates used for swap calculations and users receiving more or less from
> the token they are swapping depending on which one.
>
> ### MIM-DAI Pair, I = 3000 DAI
> 1. LP adds 2 MIM and 12000 DAI
> 2. R = 1, BASE_TARGET = 2, QUOTE_TARGET = 6000
> 3. A sellQuote of only 1 DAI is executed which makes R > 1
> 4. _adjustTarget() is called which adjusts the _BASE_TARGET, but uses the delta between
>    _QUOTE_RESERVE and _QUOTE_TARGET. Because QUOTE_RESERVE is 12000e18 + 1, but _QUOTE_TARGET is
>    6000, the _BASE_TARGET will experience a huge jump in its value, making the targets 4:6 when the
>    real ratio is 1:6.
>
> You will also find two examples of user selling 12000DAI immediately after initialization and when
> there is a 1 wei sellQuote() in between. Because of the wrong target update, there is a difference
> in the value received (~1.33 MIM vs ~0.8 MIM).
>
> **RESOLUTION** Status: Acknowledged.

## H-02 — PurrLP Cannot Be Used Without An Oracle (HIGH, ACKNOWLEDGED)

(Title as listed in the findings table; the body is the "stale _I_" class issue. Related to M-06.)

## M-03 — Unrestricted Pool Creation (MEDIUM, ACKNOWLEDGED)

> **DESCRIPTION** The Factory contract allows any user to create new pools without prior validation or
> permission checks. While this enables permissionless innovation, it also poses a significant risk
> that an attacker or inexperienced deployer could set critical parameters in a harmful way. For
> example, a malicious deployer could specify a completely incorrect target price _I_ or choose K = 0
> for a token pair where that setting makes no economic sense (non-stable pool). Worse yet, a deployer
> could assign a malicious oracle that returns manipulated prices, forcing unsuspecting liquidity
> providers into providing capital at unfair ratios. Because the Factory does not vet these parameters
> or oracles, liquidity providers joining such pools are exposed to extreme economic vulnerabilities
> or outright malicious conf[iguration].

## M-06 — Absence of Oracle Will Lead To Stale _I_ (MEDIUM, ACKNOWLEDGED)

> **DESCRIPTION** If a new PurrLP pool is deployed without specifying an oracle, the _I_ value remains
> the static ratio defined at initialization. Because asset prices typically evolve in real time, that
> constant _I_ quickly becomes inaccurate relative to the market. This inaccuracy leads to large
> arbitrage opportunities or perpetual mispricing in the pool.
>
> **RECOMMENDATION** Enforce in the Factory contract that a valid oracle is provided during pool
> deployment so the pool's _I_ can update as the market shifts. [...]
>
> **RESOLUTION** Status: Acknowledged.
