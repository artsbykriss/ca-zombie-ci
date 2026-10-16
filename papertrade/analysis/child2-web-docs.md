# Papertrade (HyperEVM) — post-incident web & docs dossier

**Prepared:** 2026-10-16 (all fetches on 2026-10-15/16, times in UTC unless noted)
**Scope:** official statements after 2026-10-10, current docs content vs. pre-incident snapshot, DefiLlama row, news claims and contradictions, second-incident/audit/token checks, relayer model.
**Method note:** raw fetched pages saved under `child2/raw/` (HTML + markdown). `docs.papertrade.xyz` is a bundled SPA: every page body lives inside the JS bundle `/assets/index-u2mlmHj8.js`; the bundle was fetched directly (its sha256 is the integrity check below). Quotes marked “via” are verbatim from a third party because the primary could not be fetched today.

---

## Task 1 — Official Papertrade statements after 2026-10-10

### 1.1 Launch post — @papertrade_xyz, 2026-10-10 09:28:17 UTC
URL: https://x.com/papertrade_xyz/status/2108852108766437759 (verbatim scrape 2026-10-16)

Key content (quoted in `child2/raw/x_posts.md`):
- Launch at 14:00 UTC 2026-10-10; “if you wish to participate in the launch you must predeposit.”
- Caps at launch: “papertrade has individual atomic position limits of 10m. there is no limit on the number of 10m positions a user can have. papertrade also has floating oi headroom per market/side … set at 1bn per market/side for launch.”
- “profit deadman: 0.2 basis points”; asym PnL fee params (`baseRate: .1`, `rateMultiplier: 15000`, `referenceNotional: 100000*k`, `positionMultiplier: 814.598 btc / 483.979 eth`).
- Admin keys: 2-of-3 multisig (@izebel_eth, @blurr, @UngusTrade); guardian can “pause opens and freeze individual/global markets”, owner can “change configure relayers/keepers” and upgrade contracts (“all contract upgrades are gated by a 7 day timelock”).
- “the frontend relayer plays an important role during launch, controlling how transactions are submitted to the hyperevm.”

### 1.2 Post-incident statement — @papertrade_xyz, 2026-10-11 15:42:55 UTC
URL: https://x.com/papertrade_xyz/status/2109308773231911359 (verbatim scrape 2026-10-16; 1,224 likes)

Exact sentences that answer “what did they say they changed”:
- “as the congestion rolled off, we began the process of **tightening up oi caps both onchain and at the relayer level**.” ← the only mitigation change they have named publicly.
- “the overnight manipulation attempts on btc/eth on the hl bbo were not an oversight in the mechanism design we spent six months working on. these were always accounted for and only possible because the oi caps were extremely permissive for launch congestion.”
- “any oi cap during the queued launch demand would have exacerbated the slow experience, and the queue itself provided a natural protection against manipulation as confirming opens/closes had non-deterministic timing.”
- “in a system like this, a manipulation attack is always possible - whether economically advantageous to attempt is the question. our goal is to set the parameters such that it is almost never profitable, and that the risk is extremely high/-EV at the tail even when it does work.”
- “evidence of this can be seen in the user that won overnight and continued to try again, ultimately donating almost all his profit back to the house via new accounts, without accounting for the cost of manipulating the bbo on hyperliquids side.”
- “a number of users equally opted to "undo" their manipulated trades in exchange for their farmed paper.”
- Also: “one day after launch, papertrade is a fully working 1000x exchange with 5m in the LP and has paid out 25M to stakers.”

**What is NOT in the statement** (checked against the full text): no new oracle, no TWAP, no deviation cap/breaker, no commitment to change BBO-mid pricing, no named allowlist/blacklist, no cap numbers, no incident report, no audit, no wallet addresses or tx hashes.

### 1.3 Any later official statements (Oct 12–16)?
An x-com sample of @papertrade_xyz posts from 2026-10-10→10-16 returned no further risk/incident content. Later posts are merchandise (“papertrade (the garments company)”, “papertrouser_ measurements”, Oct 12/15), link/media-only posts (Oct 12–14), “literally, trillions” (Oct 14) and “mandarin localization available now” (Oct 14). Nothing else on the oracle, caps, audits or the incident. (List in `child2/raw/x_posts.md` §9.)

### 1.4 The one subsequent parameter announcement (found via third parties)
- DeFiPrime, 2026-10-11: “Papertrade has also [scheduled an LP reward-cap change](https://x.com/papertrade_xyz/status/2108992674187354553) from $5m to $10m shortly after 18:45 UTC on October 17. Excess bankroll above that cap is distributable to stakers, so the higher threshold changes when LP gains become available for distribution.” — https://defiprime.com/papertrade-tightens-caps-after-bbo-manipulation
- The Defiant, 2026-10-12 (via r.jina.ai): “Papertrade said it had scheduled the threshold above which excess bankroll funds go to stakers to rise to $10 million from $5 million shortly after 2:45 p.m. ET on Oct. 17.” — https://thedefiant.io/news/defi/papertrade-trader-losses-reach-32-4-million-two-days-after-launch
- The primary tweet (status 2108992674187354553) could not be re-scraped on 2026-10-16 (Firecrawl returned empty), so this claim rests on the two secondary sources plus the tweet URL. It **retains more capital inside the house** but is a staker-reward parameter, not an anti-manipulation mechanism.

### 1.5 Press characterizations of the official line (for the record)
- The Defiant headline summary: “The team says it is restricting exposure onchain and through relayers. Its statement does not confirm claims that a trader was blacklisted or prevented from closing positions.” (https://thedefiant.io/news/defi/papertrade-says-it-is-tightening-trading-limits-after-manipulation-allegations + @DefiantNews tweet 2026-10-11 15:59 UTC)
- FinanceFeeds (Oct 12), quoting the team/Block: “Papertrade has started reducing open-interest limits both on-chain and through its transaction relayers.”
- SigIntZero (Oct 15): “Papertrade says the exposure caps were deliberately loose for launch and is tightening them; **it has announced no change to the pricing itself**.”

---

## Task 2 — Current docs vs. the 2026-10-15 snapshot

### 2.1 Diff result: NO CHANGE
- Current fetch (2026-10-16): `https://docs.papertrade.xyz/` → index references `/assets/index-u2mlmHj8.js`; sha256 = `8920c33bd4f787091db90012f8c3eee4a43e33e6a6111979d0d35ffb3fb0dfad`.
- Prior snapshot `…/zombie-hunt-iii/work/raw/zh3v/docs_bundle.js` (saved 2026-10-15 18:47) → **same sha256**. The old `docs_index.html` referenced the same asset hash.
- Conclusion: the docs are byte-identical between the pre-existing extraction and today's fetch. **No new doc text = no doc-level new mitigation.** (Record: `child2/raw/docs_bundle_diff_record.txt`.)
- Docs set: 22 pages, no changelog page. Every page footer contains a static “Last updated: 2026-10-06”.
- Caveat: the reference extraction `docs_extracted.txt` is a larger artifact that also contains rendered copies of pages; its content matches the same bundle (spot-checked strings below). Raw per-page extracts of today's bundle: `child2/raw/docs_pages/`.

### 2.2 Risk page text as it stands today (`#/how/risk`)
> “Papertrade reads its execution price directly from Hyperliquid's BBO. … within that spread an attacker can place a small limit order on HL's book that does not need to fill: simply sitting on the inside changes the best bid or best ask, which moves the BBO mid by a tick or two.”
> “An attacker who shifts BBO this way may be able to open or close a Papertrade position at a distorted midpoint and profit when the quote returns toward the natural market. **This is a real residual risk: the pricing pipeline has no independent reference price against which to reject the quote.**”

Controls (unchanged; called “three relevant controls, but none is proof that BBO manipulation is impossible or unprofitable”):
1. “0.2 bps jitter-protection deadband.”
2. “Asymmetric impact curve.”
3. “Configurable directional OI caps. … **For launch, the keeper will be configured to target each side's current OI plus asset quantity worth $1 billion at the current BBO. The keeper leaves the cap alone while that headroom remains within a 10% hysteresis band ($900M–$1.1B)** … These are limits on new per-side exposure, not a $1 billion total-OI ceiling, a loss ceiling, or a guarantee against manipulation profit.”
> “Together these controls can reduce payoff and limit how much new directional exposure fits under the configured caps. **A manipulated but non-zero, uncrossed BBO can still pass the oracle, so residual manipulation and LP-loss risk remain.**”

Operational guards (unchanged): watching keeper set; pause guardian can retire a market (frozen BBO, permanent) or engage the global opens gate; trailing OI cap operator (same $1B / 10% hysteresis wording).

### 2.3 Pricing page (`#/how/pricing-bbo`) — still “No deviation breaker”
> “PriceOracle reverts if the precompile returns zero or a crossed book (ask < bid), but **it has no maximum-deviation, time-weighted-price, or lookback breaker.** A non-zero, uncrossed but manipulated BBO can therefore be accepted for execution. … see Risk.”
> “Papertrade's execution price is simply the midpoint: `price = (bid + ask) / 2;` … That's the whole pricing stack.” (precompile `0x…080e`, BTC index 0, ETH index 1)

### 2.4 Architecture / relayer (`#/how/architecture`)
> “`BatchExecutor`: entry contract for batched intents. **It accepts batches only from Papertrade's relayer keys**, then unpacks N user intents and dispatches them to `Exchange`.”
> “`SessionKeyManager`: … **Registration is submitted through the relayer**; revocation is a direct call from the user's wallet.”
> “**Frontends:** Papertrade's relayer submits every open and close. A different frontend can produce compatible user signatures and send them through the relayer, but it can't submit opens or closes to the contracts directly.”

### 2.5 Relayer/third-party registration (`#/how/builder-codes`)
> “Builder codes are not yet live.” … “**Permissionless builder codes are coming soon.** Once the on-chain plumbing is finalised, any frontend will be able to register, tag its intents with a builder identifier, and earn the 1% revenue share …” … “**No firm date.** We will document the registration flow, the per-intent tagging surface, and the builder-payout claim mechanics here once the on-chain plumbing is finalised.”
So: as of today there is **no public registration process to become a relayer or to have intents relayed by a third party**; a future builder-code program is planned but not live, and it is a revenue-share scheme, not a relayer-access scheme.

### 2.6 Admin keys (`#/how/risk` + `#/dev/contract-addresses`)
- Owner can “swap configured relayers/keepers”; guardian can retire markets / global pause; market keeper moves per-side OI caps and min margin/position value.
- Contracts: Exchange `0x6cd566…D0a2`, BatchExecutor `0x233Ff2…626E`, PriceOracle `0xa9B4c7…cC2e`, SessionKeyManager `0x8326Eb…B108`, Timelock `0xB915Fa…EA0F` (7-day delay), Multisig `0x696292…d1F6` (2-of-3).

---

## Task 3 — DefiLlama hacks DB row (exact)

API `https://api.llama.fi/hacks` (fetched 2026-10-16, 1,303 rows total), exact record:
```json
{"date":1791590400,"name":"Papertrade","classification":"Oracle Manipulation","technique":"Spot Price Manipulation",
 "amount":1280000,"chain":["Hyperliquid L1"],"bridgeHack":false,"targetType":"DeFi Protocol",
 "source":"","returnedFunds":null,"defillamaId":"9065","language":"Solidity"}
```
- Date `1791590400` = **Sat 2026-10-10 00:00:00 UTC**; amount **$1,280,000**; classification **Oracle Manipulation**; technique **Spot Price Manipulation**; chain **Hyperliquid L1**.
- **Reference URLs: none** — the API `source` field is an empty string, and the hacks page row (https://defillama.com/hacks, fetched 2026-10-16) shows no links: `| Papertrade | Oct 10, 2026 | $1.28m | Hyperliquid L1 | Oracle Manipulation | Spot Price Manipulation | Solidity |`.
- Local copies: `child2/raw/defillama_hacks_papertrade_row.json`, `child2/raw/defillama_hacks_page_excerpt.md`.

---

## Task 4 — News coverage, quantitative claims, contradictions

### 4.1 The incident (on-chain/attribution)
| Claim | Source | Date | Quote |
|---|---|---|---|
| 2 wallets, ~$20M clips each, ETH moved 10–20 bp, 9-figure Papertrade longs | @Dr_bobo54 via WuBlockchain / crypto.news / TokenPost / PrimeXBT | 2026-10-10 22:22 / Oct 11 | “getting actively exploited by two wallets moving ETH 10-20bps on hyperliquid using $20m clips” (via), “trades worth around $20 million … move Ethereum prices by 0.1%–0.2%” |
| Named wallet 0x2025137a136bea7446deba681cbfc7cf1970840e | @btlrtrades (butler) | 2026-10-11 03:50 | “papertrade got exploited for $1.28M by 0x2025…840e within just 8 hours of being live” |
| ~6,060 ETH bought 6:01–6:02 p.m. ET (+~$3), ~5,210 ETH sold next minute (−~$3.50) | The Block via FinanceFeeds | 2026-10-12 | (see `raw/news_quotes.md`) |
| ~$231M ETH volume on HL that evening; ~$52,000 fees; Papertrade records ~$3.18B volume / $1.28M profit; withdrew ~$2.48M after depositing ~$1.2M | The Block via FinanceFeeds | 2026-10-12 | “The wallet executed approximately $231 million in Ethereum trading volume … around $52,000 in fees.” |
| 30 ETH shorts ~660x, $297M notional, liquidated >3h later for ~$450k; losses minted ~17.6M PAPER | The Block via FinanceFeeds / SigIntZero | 2026-10-12 / 10-15 | “The same wallet subsequently opened 30 Ethereum short positions using approximately 660-times leverage…” |
| Loop stats: 296 wins / 305 trades, ~98s holds, gross $1.73M | @btlrtrades | 2026-10-11 | “296 wins out of 305 trades … total pnl: $1.73M” |
| Independent re-pull: ~$224M/$50k fees, loop from ~21:06 UTC | SigIntZero | 2026-10-15 | “Our day total, about $224 million and $50,000 of fees, sits a few percent under The Block's.” |
| Trader history: ~$14.2B lifetime HL volume, ~$13.1M profit since Feb 2025 | The Block / SigIntZero | 2026-10-11/15 | (FinanceFeeds + SigIntZero) |

### 4.2 Activity/size numbers (all post-launch)
| Metric | Value | Source | Date |
|---|---|---|---|
| Pre-deposits | **$85.3M** (DefiLlama, incl. customer balances + house pool) | crypto.news | Oct 10 11:10 |
| Pre-deposits | **$137M across 11,000+ addresses** | CryptoBriefing | Oct 10 |
| Deposits | **$138M from 11,465 addresses** | ainvest (headline, via search) | Oct 10-11 |
| TVL after launch | $118M → $70M → $67M | Bitcoin.com News | Oct 11 18:18 |
| TVL | $102M | CryptoBriefing | Oct 10 |
| TVL | $96M (+64.26% 24h) | KuCoin/MarsBit | Oct 11 00:13 |
| TVL | $77.8M | TokenPost | Oct 11 10:08 |
| Exchange HyperCore USDC balance | ~$66.2M | HyperliquidGuide (Hyperliquid API) | Oct 13 |
| OI peak | $11B (Bitcoin.com) / $10.1B or ~$11B, cover $54M → “about 185 to 1” | Bitcoin.com / CryptoTicker | Oct 11 / 13 |
| OI drop | −60% in 12h to $1.3B (from $3.3B); collateral −30% to $14.34M | TokenPost | Oct 11 |
| OI drop | −93.7% from $11B to $693M; “just $9.17 million is backing those outstanding positions” | Bitcoin.com | Oct 11 |
| OI drop | −88% | CryptoTicker | Oct 13 |
| OI level | $1.979B; margin $17.38M → ~114x | KuCoin/MarsBit | Oct 11 |
| Volume | $14.4B in first 10 min | CryptoBriefing | Oct 10 |
| Volume | >$678B in first 24h | TokenPost | Oct 11 |
| Volume | $596.28B in 24h; $45.8B/24h and OI ~$352M on Oct 13 | KuCoin/MarsBit; HyperliquidGuide | Oct 11 / 13 |
| Trader losses | ~$18M–$28M first days (PaperDash est.) | CryptoBriefing | Oct 10 |
| Trader losses | ~$30.24M net realized in 24h | KuCoin/MarsBit | Oct 11 |
| Trader losses | **~$32.4M net cumulative by Oct 12** | The Defiant | Oct 12 |
| Staker payouts | “> $10M … $10M to $12.6M+” opening hours | CryptoBriefing | Oct 10 |
| Staker payouts | “has paid out 25M to stakers” (team) | @papertrade_xyz | Oct 11 |
| Staker rewards | ~$26.31M cumulative (PaperDash) | The Defiant | Oct 12 |
| House pool | $3.15M (CryptoBriefing) / $3.14M (Defiant) → $5M (team) / $4.30M (PaperDash Oct 11) / $4.27M (PaperDash Oct 12, “no queued payout claims”); trough ~$2.4M | multiple | Oct 10–12 |
| Revenue rank | Papertrade $3.78M revenue for Oct 11 vs Pump.fun $2.11M, Hyperliquid $1.70M | The Defiant (DefiLlama) | Oct 12 |

### 4.3 Contradictions to flag
1. **Pre-deposits:** $85.3M (DefiLlama, includes house pool) vs $118M / $137M / $138M (11,465 addresses) vs $125M (Velo headline). CryptoTicker explicitly says sources diverge and refuses to pick: “We report the range as the sources give it.”
2. **Attacker size:** “$20M clips” (two wallets, Boblob) vs ~$231M total evening ETH volume (The Block) vs ~$224M (SigIntZero). The $20M refers to individual clip size, not total.
3. **Attacker PnL:** $1.28M net vs $1.73M gross (butler) vs “$1.28M–$1.54M” (CryptoTicker); one withdrawal of $1.54M at 22:06 (SigIntZero). On-record figure for the named wallet is $1.28M.
4. **OI collapse:** −60% to $1.3B in 12h (TokenPost) vs −93.7% to $693M (~24h) vs −88% (CryptoTicker) — different windows and possibly different measures.
5. **Pool size:** $3.15M vs $5M in the same 24h window; PaperDash readings ($4.30M/$4.27M) sit between; FinanceFeeds reports a ~$2.4M trough.
6. **Staker payouts:** $10–12.6M (opening hours) vs “25M” (team, day 1) vs $26.31M cumulative (PaperDash, Oct 12).
7. **Verification:** always flagged — WuBlockchain: “The allegations have not been independently verified, and Papertrade has not confirmed any losses” (Oct 11 10:16 GMT, before Papertrade's 15:42 UTC statement). Crypto.news on Oct 11 morning: “No confirmed public response from Papertrade … was identified.” The clawback claim (“donating almost all his profit back”) is team-only: “The Block could not independently verify that claim, and the originally identified wallet's withdrawals continued to exceed its deposits” (FinanceFeeds).

---

## Task 5 — Second incident / audits / bug bounties / $PAPER events

### 5.1 A second incident?
- **No confirmed second manipulation event in any source I found.** DefiLlama has exactly one Papertrade row (Oct 10). Searches for later exploitation, “second attempt”, “fresh wallet”, “blocked/blacklisted” surfaced only commentary about the Oct 10 event.
- The team's own account of follow-on attempts: “the user that won overnight **continued to try again**, ultimately donating almost all his profit back to the house via new accounts” (@papertrade_xyz, Oct 11). No independent confirmation; The Block could not verify (FinanceFeeds).
- Butler's (unconfirmed) claim of an ad-hoc intervention: “my guess is the team blocked 0x2025's closes to stop the attack. this is a temporary fix, the underlying oracle of papertrade is still identical, and vulnerable to the exact same manipulation which anyone could re-create from a fresh wallet.” (Oct 11). The Defiant: “Claims that a trader was blocked from closing positions remain unconfirmed”; SigIntZero (Oct 15): “Whether the close stalled in the queue or was held back by the team, no published on-chain evidence settles it.”
- A **separate, non-attack** wallet story circulated: “Papertrade: a wallet loses $979000 in trading yet ends up in profit” thanks to PAPER (“loss mining”), 1,012 trades (weex.com / Journal du Coin, ~Oct 14-15; body not retrievable on 2026-10-16). This is a PAPER-emissions outcome, not a second oracle incident. weex's snippet also says: “Two Different Wallets for Two Papertrade Flaws … The trader with $1.28 million operates from address 0x2025 …840e” (i.e., the two stories are distinct wallets).

### 5.2 Audits / bug bounties
- **Nothing found.** No audit report, no Immunefi/bounty page, and no audit/bounty mention in any Papertrade post, doc page, or news article I reviewed. The DefiLlama protocol metadata lists `"audits":"0"` (DefiLlama coins API, fetched in prior session data `dl_papertrade.json`). The docs make no security-audit claim.
- Papertrade's own docs are the de-facto risk disclosure; media note the risk was documented pre-launch (crypto.news, WuBlockchain, SigIntZero).

### 5.3 $PAPER / governance / parameter events
- PAPER remains **non-transferable** per current docs (“At launch it can't be transferred between wallets, but minting, staking, unstaking, and claims all work.” — `#/paper/overview`; same in `#/intro/faq`). The Defiant (Oct 12): “The rules initially allow staking and unstaking but not transfers between wallets.” No transferability-enable or listing event found. (A CoinGecko search result surfaced a “PaperTrade (PAPER)” price snippet, but `api.coingecko.com/api/v3/coins/papertrade` returns 404 “coin not found” and the /en/coins/papertrade page does not render a coin — no verifiable market for the protocol token 0xe40f17915DAa230324030003A197cdAEf2261C0e as of 2026-10-16.)
- Governance = 2-of-3 multisig 0x696292…d1F6 → 7-day Timelock 0xB915Fa…EA0F (docs `#/dev/contract-addresses`); no token voting.
- Parameter event: **LP staker-reward cap $5M → $10M scheduled for shortly after 18:45 UTC on 2026-10-17** (team tweet cited by DeFiPrime Oct 11 and The Defiant Oct 12). Keeps more capital in the house before surplus distributions.
- Marketing events (Oct 12–15: “garments company”/papertrousers merch, Mandarin localization at papertrade.xyz/zh) — no risk impact found.

---

## Task 6 — The relayer model as documented today

- **Permissioned relay, by design.** “BatchExecutor … accepts batches only from Papertrade's relayer keys” (docs `#/how/architecture`). “Papertrade's relayer submits every open and close. A different frontend can produce compatible user signatures and send them through the relayer, but it can't submit opens or closes to the contracts directly.” (`#/how/architecture`, Frontends). Same for “opens, closes, session-key registration, proxy deployment, and staking actions” (`#/how/risk`, Permissionless and gated surfaces). Owner can “swap configured relayers/keepers” (`#/how/risk`, Admin keys; launch post Oct 10: “change configure relayers/keepers”).
- **What the public app requires:** per docs `#/intro/quick-start`, only an EVM wallet (“MetaMask, Rabby, Frame, Rainbow, or anything that speaks WalletConnect”) and ≥10 USDC; “Your wallet pops once for a signature that registers a session key”. A first deposit pays “a one-time 1 USDC account activation fee” (`#/learn/deposits-withdrawals`) — an on-chain fee, not a signup. **No account, email, or KYC requirement is documented anywhere in the docs.** (Independent summary agrees: “Trading itself needs one wallet signature.” — HyperliquidGuide, Oct 13.) Note: the live trading app itself (exchange.papertrade.xyz) is a client-rendered SPA and could not be scraped through on 2026-10-16; the wallet-only description above is from the docs and third-party reviews, not from a rendered app session.
- **Is there a public relayer API?** None documented. The doc set has no API page; the only developer page is `#/dev/contract-addresses` (contracts + timelock/multisig). Third-party frontends are described as needing to route through Papertrade's relayer, but with no published submission protocol. Builder codes (which would give a frontend on-chain intent tagging + 1% revenue share) are “not yet live” with “No firm date.”
- **A third-party app does exist:** Bankr (bankr.bot) announced “Papertrade is live on Bankr. Trade BTC and ETH perps from chat or X, up to 1000x. Bankr runs your take profit and stop loss (best-effort) and stakes the PAPER your losses mint to earn USDC.” (@bankrbot, 2026-10-12 01:57 UTC; landing page bankr.bot/papertrade, page body not retrievable on 2026-10-16). This implies a partner-level arrangement with the relayer, but **no public API docs or registration process accompany it**.
- **Unrelated third-party artifacts:** a GitHub user hosts a “papertrade-x402: Pay-per-call Papertrade intelligence API for AI agents over x402: liquidation risk, liquidation maps, settlement estimates” repo (github.com/nirholas, via search snippet). This is a third-party analytics API, not an official relayer/API.
- **Relayer-level restriction post-incident:** stated twice by the team/news — “tightening up oi caps both onchain and at the relayer level” (team, Oct 11) and “restricting new exposure onchain and through relayers” (Defiant/FinanceFeeds, Oct 11-12). No public definition of what the relayer-level rule is (e.g., per-account caps, queueing, manual review), and no statement of allowlisting/denylisting users.

---

## Mitigations verified as of 2026-10-16

Verified = confirmed in a primary source fetched today (docs bundle, official X, DefiLlama API/page).

1. **OI caps tightened “onchain and at the relayer level.”** Verified as a team statement only (X, Oct 11 15:42 UTC) and echoed by The Defiant/FinanceFeeds. **No numbers, no on-chain parameter values published anywhere.** Externally, OI collapsed (~88–93.7%) in the following 24h (TokenPost, Bitcoin.com, CryptoTicker). Current docs still describe the launch policy ($1B headroom/side, 10% hysteresis band), not a revised policy.
2. **Permissioned relayer + owner-swappable relayer keys** (docs, unchanged). Users' intents must be signed by wallet/session key; the relayer cannot act without a signature; withdrawals bypass the relayer (`withdrawToCoreBySig` callable by anyone, real wallet signature needed).
3. **Pause guardian levers** (docs, unchanged): permanently retire a market with frozen BBO for closes, or engage a global opens gate (only owner can lift). Market keeper can set a per-side OI cap to zero, which effectively stops new opens on that side without freezing prices.
4. **Economic frictions** (docs, unchanged, and by their own text not a breaker): 0.2 bps deadband, asymmetric impact haircut, 2% win fee. “It is not a deviation check, however, and does not guarantee that a manipulation strategy is unprofitable.”
5. **Owner/keeper parameters behind 7-day timelock** (docs + launch post); the only scheduled change is the Oct 17 18:45 UTC LP reward-cap move $5M→$10M, which keeps more capital in the house.
6. **The BBO-mid pricing itself is unchanged**: docs still say “no maximum-deviation, time-weighted-price, or lookback breaker”; SigIntZero (Oct 15): “it has announced no change to the pricing itself.” The core manipulation path documented pre-launch remains open by design.

**Bottom line:** the only post-incident mitigation that *directly* shrinks the BBO-manipulation payoff is the (unquantified) tightening of directional OI caps on-chain and at the relayer. Nothing public shows a deviation breaker, TWAP/lookback, hold-time rule, independent reference price, per-account exposure formula tied to LP equity, or oracle change.

## Unresolved

- The actual new OI cap values, and what “at the relayer level” concretely means (submission throttling? per-account notional caps? manual review? screening/allowlisting?). No official details as of 2026-10-16.
- Whether the tightening is already fully in effect on-chain (docs unchanged; no on-chain parameter disclosure).
- Whether any *denylist/blacklist* or user screening exists (The Defiant: claims of a blocked trader “remain unconfirmed”; team statement does not name wallets).
- The clawback: whether the attacker truly “donated almost all his profit back” and the “undo” transactions (team-only; The Block could not verify; named wallet's withdrawals still exceed deposits).
- Second attempts: the team says the trader “continued to try again”; no independent confirmation, no second DefiLlama row, no on-chain incident report.
- Audits and bug bounties: none found for Papertrade; DefiLlama metadata shows `"audits":"0"`.
- PAPER transferability/listing timeline (docs still say non-transferable; the eventual enablement is a risk-shifting event).
- Whether the Oct 17 LP reward-cap change executes on schedule (primary tweet could not be verified today; two secondary sources cite it).
- The relaunch/relisting policy after market retirement (fresh instrument ID) has not been exercised in public.
- Doc freshness: bundle footer says “Last updated 2026-10-06” and the bundle is unchanged vs the Oct 15 snapshot, so docs likely do **not** yet reflect post-incident parameter reality.

---

## Source index (fetch date 2026-10-16 unless noted)

Official
- X @papertrade_xyz launch post — 2026-10-10 — https://x.com/papertrade_xyz/status/2108852108766437759
- X @papertrade_xyz incident statement — 2026-10-11 15:42 UTC — https://x.com/papertrade_xyz/status/2109308773231911359 (+ thread 2109309500406853725)
- X @papertrade_xyz LP cap tweet (cited by DeFiPrime/Defiant) — status 2108992674187354553 (primary not retrievable 2026-10-16)
- Docs SPA — https://docs.papertrade.xyz/ and bundle /assets/index-u2mlmHj8.js (sha256 8920c33b…, identical to 2026-10-15 snapshot); pages `#/how/risk`, `#/how/pricing-bbo`, `#/how/architecture`, `#/how/builder-codes`, `#/intro/quick-start`, `#/learn/deposits-withdrawals`, `#/learn/session-keys`, `#/dev/contract-addresses`
- X @bankrbot — 2026-10-12 — https://x.com/bankrbot/status/2109463312219926578

On-chain / data
- DefiLlama hacks API + page — https://api.llama.fi/hacks , https://defillama.com/hacks (row quoted in Task 3)
- DefiLlama protocol — https://defillama.com/protocol/papertrade

News / analysis (fetched)
- WuBlockchain — 2026-10-11 — https://x.com/WuBlockchain/status/2109226673149542858
- crypto.news — 2026-10-11 — https://crypto.news/hyperliquid-eth-trades-raise-concerns-was-papertrade-exploited/
- crypto.news — 2026-10-10 — https://crypto.news/papertrade-plans-1000x-leverage-launch-85-3m-deposits/
- CryptoBriefing — 2026-10-10 — https://cryptobriefing.com/papertrade-oracle-manipulation-allegation-pool/
- TokenPost — 2026-10-11 — https://www.tokenpost.com/news/investing/29834 and https://www.tokenpost.com/news/technology/29701
- Bitcoin.com News — 2026-10-11 — https://news.bitcoin.com/featured/papertrades-wild-weekend-ends-with-93-7-open-interest-wipeout/ (and …/papertrade-perp-dex-pulls-in-118m-in-24-hours-with-1000x-leverage/)
- KuCoin flash (MarsBit) — 2026-10-11 — https://www.kucoin.com/news/flash/papertrade-24-hour-trading-volume-near-600b-leverage-reaches-114x
- FinanceFeeds (The Block data) — 2026-10-12 — https://financefeeds.com/papertrade-faces-bbo-price-manipulation-allegations-following-hyperevm-launch/
- The Defiant — 2026-10-12 — https://thedefiant.io/news/defi/papertrade-trader-losses-reach-32-4-million-two-days-after-launch ; 2026-10-11 — …/papertrade-says-it-is-tightening-trading-limits-after-manipulation-allegations ; @DefiantNews tweet 2026-10-11 15:59
- Cryptonomist — 2026-10-11 — https://en.cryptonomist.ch/2026/10/11/papertrade-trading-limits/
- DeFiPrime — 2026-10-11 — https://defiprime.com/papertrade-tightens-caps-after-bbo-manipulation
- CryptoTicker — 2026-10-13 — https://cryptoticker.io/en/papertrade-reference-price-manipulation-leverage-limits/
- SigIntZero — 2026-10-15 — https://sigintzero.com/blog/papertrade-1-28m-bbo-oracle-manipulation
- HyperliquidGuide (independent) — 2026-10-13 — https://hyperliquidguide.com/ecosystem/papertrade-hyperevm-synthetic-perps
- PrimeXBT — 2026-10-11 — https://primexbt.com/news/papertrade-faces-unverified-allegations-that-two-wallets-moved-eth-prices-on-hyp/
- weex.com / Journal du Coin — “$979,000 loss-mining wallet” (headline + snippets only; body not retrievable)

Raw artifacts: `child2/raw/` (HTML pages, docs pages, X posts, Defiant text, DefiLlama row, news quotes, diff record).
