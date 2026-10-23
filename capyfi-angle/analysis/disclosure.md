# The Apr-2026 CapyFi public access-control disclosure (primary source)

**Source:** Reddit `r/bugbounty`, post `1s9n881`, dated **2026-04-01**, author handle `AWX-Houcine`.
**Title:** *"What do you do when a Web3 project quietly drains $55M to 'silently fix' your report, calls it 'intentional design', and Immunefi blocks mediation?"*
**URL:** https://www.reddit.com/r/bugbounty/comments/1s9n881/what_do_you_do_when_a_web3_project_quietly_drains/
**Recovered via:** PullPush API (`api.pullpush.io/reddit/search/submission/?ids=1s9n881`) — direct Reddit fetch is 403, mirror instances are Anubis-gated.

## Full selftext (verbatim)

> Hey everyone, dealing with a highly frustrating situation on a major Web3 bug bounty platform and wanted to see how the community handles these blatant "Silent Fix" scenarios.
>
> **The Setup:** I recently submitted a Critical severity finding for a DeFi protocol (**CapyFi)**, via **Immunefi**. The report demonstrated a complete bypass of a required security control, allowing permissionless access to restricted assets.
>
> **The Response:** The platform's triage team validated the report and escalated it to the project.
>
> The project responded by closing the report as "invalid", claiming the access control bypass was "intentional design" and the resulting exposure was a "known issue" they were comfortable with.
>
> **The Catch (The Silent Fix):** If it's intentional design and a comfortable known issue, you'd leave it alone, right?
>
> Instead, the on-chain data shows that **within minutes of the report being closed**, a team-controlled address initiated emergency transactions to redeem **5.5 Billion tokens** from the vulnerable pool.
>
> This overnight action reduced the pool's borrowable reserves by **62%** (representing over $55M in liquidity removed).
>
> Projects do not emergency-drain 60% of their liquidity for "intended features." They do it for live exposures they are terrified of.
>
> **The Kicker:** The platform accepted the project's "intentional design" excuse and finalized the closure. When I went to dispute this obvious contradiction using the platform's mediation system, the platform had **blocked mediation for the report** entirely, stating "a final decision has been made."
>
> **My Question to the Community:** I have clear evidence of contradictory documentation, and irrefutable on-chain proof of emergency mitigation happening *immediately* after the report escalation. Yet, I am blocked from disputing the project's bad-faith closure.
>
> 1. Has anyone else successfully fought a "Silent Fix" when the platform itself blocks mediation?
> 2. At what point does a triage platform's refusal to look at objective, on-chain contradictions become a systemic failure for researchers?
>
> Any advice from veteran Web3 hunters on how to escalate this, outside of taking the reputational hit of going fully public with the exploit code?

## What the disclosure does and does NOT say

- **Says:** "complete bypass of a required security control, allowing permissionless access to restricted assets"; team called it "intentional design / known issue"; a team address redeemed 5.5B tokens from "the vulnerable pool" cutting borrowable reserves 62% (>$55M).
- **Does NOT say:** the affected function, the market, or the chain. The reporter deliberately withheld the exploit code.

## Independent reconstruction of the affected control

CapyFi is a Compound-v2 fork whose **only** "required security control" is the **mint whitelist** (`Whitelist.sol`, UUPS proxy, `WHITELISTED_ROLE`). CapyFi's own audit-docs (github `Capyfi/capyfi-smart-contracts/docs/audit-docs.md`) state the whitelist *"restricts who can mint cTokens … while maintaining unrestricted token transfers and redemptions."* The independent July-2026 audit writeup (`github EduardoFernandess/audit-writeup-capyfi`) records the same control as design note **I-01 — "Mint whitelist does not gate borrow"**: a non-whitelisted user can supply ETH and **borrow** the restricted asset (RPC). That is exactly "permissionless access to restricted assets" with a mint-only control.

**On-chain this session:** the whitelist is live and enforced on mint; borrow/redeem/transfer are not gated. See `live-state.json` and `../README.md` §4–5.

## Note on the historical redemption

The reporter's "5.5B tokens / 62% / $55M" is consistent with the **caRPC** market (RPC ≈ $0.0103; 5.5e9 RPC ≈ $56.5M; current caRPC cash $41.99M ⇒ pre-event ≈ $98M, −57%≈62%). However, a full-history Etherscan `Redeem` log scan of caRPC on Ethereum returns **zero** Redeem events (147 events total, 2026-03→2026-10, none `0xe5b754fb…`), and caLAC/caWARS redeems in the Apr-2026 window are orders of magnitude smaller. The exact 5.5B-token redemption could not be pinned on Ethereum's Unitroller markets — it may have occurred on another CapyFi chain (LaChain/Base/World Chain) or via a route outside the Unitroller. This does **not** affect the E-U verdict (today's state is what matters), but it is recorded as an unresolved evidence gap.
