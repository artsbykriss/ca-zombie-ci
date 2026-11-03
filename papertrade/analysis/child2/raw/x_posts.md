# X/Twitter primary posts (verbatim, scraped via Firecrawl 2026-10-16)

## 1) @papertrade_xyz launch post — https://x.com/papertrade_xyz/status/2108852108766437759
Posted 2026-10-10T09:28:17Z. Likes 944, RTs 119.

> **papertrade launch timing and details**
>
> papertrade is expected to launch at 14:00 UTC on 10.10.2026, following the scheduled hyperevm network upgrade.
> at this time trading through the frontend will be enabled.
> deposits will pause for a short period of time at 13:45 UTC, fifteen minutes before, to ensure that trading has the utmost priority during launch. if you wish to participate in the launch you must predeposit.
>
> **launch congestion**
> papertrade will be congested at the start due to launch demand. expect temporarily long confirmation wait times, especially for smaller notional trades.
> the frontend relayer plays an important role during launch, controlling how transactions are submitted to the hyperevm. some actions like staking distributions run separately in big blocks. the chain will always look as if only half of all possible gas is being used, this is optimal. using more than this would exponentially raise fees within minutes to unpayable prices.
>
> **oi limits**
> papertrade has individual atomic position limits of 10m. there is no limit on the number of 10m positions a user can have. papertrade also has floating oi headroom per market/side, which determines how much oi can be opened in a very short period. these are not designed to be triggered through normal trading usage and are set at 1bn per market/side for launch.
>
> **asym pnl fee parameters**
> papertrade inherits rollbit's asymmetric fee pnl curve
> the parameters are:
> - baseRate: .1
> - rateMultiplier: 15000
> - rateExponent: 1
> - referenceNotional: 100000*k (k=1m)
> - positionMultiplier: 814.598 btc / 483.979 eth
> - profit deadman: 0.2 basis points
>
> **admin keys**
> the papertrade admins (2 of 3 multisigs consisting of @izebel_eth @blurr @UngusTrade) perform three separate roles:
> - **guardian**: pause opens and freeze individual/global markets. if a market is frozen any existing positions can still be closed against the paused bbo mid.
> - **owner**: set impact curve and fee parameters. change configure relayers/keepers. list new markets and upgrade the contracts. all contract upgrades are gated by a 7 day timelock.
> - **markets**: adjust the oi headroom per market/side. set the minimum margin and minimum position sizes.

## 2) @papertrade_xyz post-incident statement — https://x.com/papertrade_xyz/status/2109308773231911359
Posted 2026-10-11T15:42:55Z. Likes 1,224, RTs 63. (Follow-up in thread: status 2109309500406853725, a media link.)

> thank you everyone for your participation and support through papertrade's launch.
>
> we flipped the stock market's volume in the first 6 hours. one day after launch, papertrade is a fully working 1000x exchange with 5m in the LP and has paid out 25M to stakers.
>
> addressing two points that have come up:
>
> -it was never possible to allow small notional to have the same priority as large notional. it opens the frontend up to spam congestion, which would have been infinitely worse than the existing queue. we designed the fair launch to be as inclusive as possible given those constraints.
>
> -speaking of constraints, the overnight manipulation attempts on btc/eth on the hl bbo were not an oversight in the mechanism design we spent six months working on. these were always accounted for and only possible because the oi caps were extremely permissive for launch congestion. any oi cap during the queued launch demand would have exacerbated the slow experience, and the queue itself provided a natural protection against manipulation as confirming opens/closes had non-deterministic timing. as the congestion rolled off, we began the process of tightening up oi caps both onchain and at the relayer level. in a system like this, a manipulation attack is always possible - whether economically advantageous to attempt is the question. our goal is to set the parameters such that it is almost never profitable, and that the risk is extremely high/-EV at the tail even when it does work. evidence of this can be seen in the user that won overnight and continued to try again, ultimately donating almost all his profit back to the house via new accounts, without accounting for the cost of manipulating the bbo on hyperliquids side. a number of users equally opted to "undo" their manipulated trades in exchange for their farmed paper.
>
> we are proud to be the first through the wall with this mechanism, at scale, in an adversarial environment. the market parameters cannot give undue advantage to either house or trader, such that the system becomes unstable and we have thought about these risks continuously since we began on this journey.
>
> good luck to us.

## 3) @btlrtrades (butler) on-chain breakdown — https://x.com/btlrtrades/status/2109129513078567221
Posted 2026-10-11T03:50:36Z. Likes 726.

> papertrade got exploited for $1.28M by 0x2025137a136bea7446deba681cbfc7cf1970840e within just 8 hours of being live.
> ... how it works: papertrade prices every trade off hyperliquid's ETH price at that exact second. so if you can move hyperliquid's price for a few seconds, papertrade pays you for it.
> 22:01 opens $200M of longs on papertrade / 22:01 buys 6,055 ETH on hyperliquid, price goes up $3 / 22:03 closes the longs → +$168k / 22:03 flips to $160M of shorts / 22:03 sells 5,260 ETH on hyperliquid, price drops $3 / 22:04 closes the shorts → +$97k / 22:04 flips long again
> they won 97% of their trades — 296 wins out of 305 trades, typical hold: 98 seconds, total pnl: $1.73M
> then it went wrong: 23:13 opens 30 shorts on papertrade, $297M at 2507.35 / 23:13 sells ~6,600 ETH on hyperliquid, price drops to 2504.4 / same move as before. but this time the close never goes through. the short is stuck
> 02:31 ETH hits 2509.95. all 30 shorts liquidated, -$450k. leaving them with $1.28m of profit.
> my guess is the team blocked 0x2025's closes to stop the attack. this is a temporary fix, the underlying oracle of papertrade is still identical, and vulnerable to the exact same manipulation which anyone could re-create from a fresh wallet.

## 4) @Dr_bobo54 (Boblob) first public flag — https://x.com/Dr_bobo54/status/2109046831271268488
Posted 2026-10-10 ~22:22 UTC. (Scrape blocked 2026-10-16; text as quoted by SigIntZero:)
> getting actively exploited by two wallets moving ETH 10-20bps on hyperliquid using $20m clips

## 5) @WuBlockchain — https://x.com/WuBlockchain/status/2109226673149542858
Posted Sun, 11 Oct 2026 10:16:41 GMT. Likes 80.
> Papertrade Faces Allegations of BBO Price Manipulation on HyperEVM
> X user @Dr_bobo54 alleged that two wallets exploited Papertrade's pricing mechanism by using roughly $20 million orders on Hyperliquid to move ETH quotes by 10–20 basis points while holding much larger long positions on Papertrade. The HyperEVM-based perpetual platform reportedly uses the midpoint of Hyperliquid's best bid and offer as its execution price, making it potentially sensitive to short-term BBO manipulation. Trader Rune noted that Papertrade's own documentation lists BBO manipulation as an unresolved protocol risk. The allegations have not been independently verified, and Papertrade has not confirmed any losses.

## 6) @DefiantNews — https://x.com/DefiantNews/status/2109312822538911858
Posted 2026-10-11T15:59:00Z.
> PAPERTRADE TIGHTENS TRADING LIMITS
> The team says it is restricting new exposure onchain and through relayers after alleged price manipulation. Claims that a trader was blocked from closing positions remain unconfirmed.

## 7) @bankrbot — https://x.com/bankrbot/status/2109463312219926578
Posted 2026-10-12T01:57:00Z. Likes 149, RTs 21.
> Papertrade is live on Bankr.
> Trade BTC and ETH perps from chat or X, up to 1000x. Bankr runs your take profit and stop loss (best-effort) and stakes the PAPER your losses mint to earn USDC.
> > pay with any token
> > hedged PAPER farm routine
> https://bankr.bot/papertrade

## 8) @RuneCrypto_ (Oct 11, quoted by crypto.news) — https://x.com/RuneCrypto_/status/2109087204870131974
> the docs itself exposed the "exploit" risk [link]  (link resolves to Dr_bobo54's flag post)

## 9) Post statement timeline of @papertrade_xyz (x-com posts sample, no risk-related content)
- 2026-10-12T18:29:00Z status 2109712958024769820 — "our tailor informs us some people seem a little confused as to what they have purchased from our garment store..." (merch/garment narrative)
- 2026-10-12T18:44:08Z status 2109716767199093209 — link/media only
- 2026-10-13T02:23:27Z status 2109832356744011838 — link/media only (376 likes)
- 2026-10-13T02:24:08Z status 2109832530430136738 — link/media only
- 2026-10-14T14:40:58Z status 2110380347372470779 — "literally, trillions"
- 2026-10-14T21:18:53Z status 2110480488691552688 — "mandarin localization available now https://papertrade.xyz/zh/"
- 2026-10-15T16:00:48Z status 2110762825421652182 — "papertrade (the garments company) will be finalizing papertrouser_ measurements soon..." 
No further statements about the oracle, caps numbers, audits, or the incident were found on the account.
