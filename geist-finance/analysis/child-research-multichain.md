# Multichain collapse, Fantom anyTokens, Geist Finance, oracles & off-ramps — child research notes

**Compiled:** 2026-10-13 · **Method:** public web sources only; no blockchain RPC used. Facts are cited with sources and dates; estimates and unverified items are flagged.

## 1. What happened in the Multichain (ex-Anyswap) collapse — July 2023

- **May 21, 2023:** Multichain CEO "Zhaojun" (He Zhaojun) was arrested in China. The team confirmed this only on July 14; on May 31 it said it could not contact him and suspended services for 10+ chains. (Chainalysis, 2023-07-10/19: https://www.chainalysis.com/blog/multichain-exploit-july-2023/ ; web3isgoinggreat, 2023-07-13)
- **July 6–7, 2023 (first drain):** >$125M in unauthorized withdrawals; **nearly $120M came from the Fantom bridge**. Assets included wETH, wBTC and USDC; Dogechain lost ~$666k (85% of deposits), Moonriver ~$6.8M. (Chainalysis; Forbes 2023-07-07)
- **July 9–10 (second drain):** ~$107M more. Multichain claimed the CEO's sister moved funds for "asset preservation"; she was arrested July 13 and the status of those assets is "uncertain". (web3isgoinggreat 2023-07-10/13; Cointelegraph 2023-07-14)
- **July 14, 2023:** Multichain announced it was ceasing operations: keys, servers and funds were under the CEO's sole control, and his devices/hardware wallets/mnemonics had been confiscated by Chinese police. (Chainalysis; @MultichainOrg 2023-07-14)
- **Total:** commonly cited as **~$200–210M** across chains (CoinDesk 2024-03-05; blocmates 2025-05-15). Cause: compromised MPC keys under one person's control — a key compromise/rug-pull, not a smart-contract exploit (Chainalysis; Singapore judgment [2024] SGHC 173).
- **Circle and Tether froze ~$65M** of the moved assets in July 2023 (Chainalysis). Binance stopped deposits of suspended Multichain-bridged tokens effective 2023-07-07.
- **Fantom Foundation response:** CEO Michael Kong hired a Chinese law firm to investigate (July 2023). No compensation fund or redemption program was announced; scammers impersonated the Foundation with a fake "emergency FTM distribution" (Chainalysis).

## 2. Any recovery, compensation, migration or re-backing since?

**No token swap, re-backing or redemption ever materialized.** The only live path is litigation → liquidation of the Multichain entity:

| Date | Event | Source |
|---|---|---|
| 2024-01-30 | Singapore default judgment vs Multichain | Fantom Foundation blog |
| 2024-07-08 | Damages assessed: **US$2,187,870.55** — the Foundation's own loss only | [2024] SGHC 173 |
| 2025-05-09 | Winding-up granted; **KPMG Singapore** liquidators appointed, "to help recover and distribute missing or frozen assets for all parties affected" | blocmates 2025-05-15; The Block 2025-05-15 |
| 2025-10-23→30 | Chapter 15 petition in New York; order keeps **63,289,029 USDC** frozen in 3 addresses | Multichain Foundation legal Medium, "Latest Update — January 2, 2026"; Decrypt 2025-10-31 |
| 2025-12-08 | **Full Chapter 15 recognition**; KPMG liquidators recognized; Circle must keep blacklisting the hacker addresses | same Medium post |

- **Last public update found: 2026-01-02 (Medium).** No claims portal, distribution or newer update found as of 2026-10-13. Any recovery for anyToken holders is speculative and would at best be a partial distribution from frozen/recovered assets (~$63.3M USDC plus whatever liquidators find), not redemption at par.
- One non-mechanism exception: the bridge **unexpectedly restarted for ~2 hours on 2023-10-31/11-01**. One user bridged ~$1M of WBTC/ETH/USDT off Fantom; then it stopped again. (DL News 2023-11-01)
- multichain.org returned **HTTP 522** when checked on 2026-10-13 — no working frontend/redemption UI.
- **Conclusion:** the Fantom anyTokens have no issuer and no redemption claim. Today they can only be sold on-system at speculative DEX prices — exactly what the observed $0.013–$1,066 quotes are.
- **Caveat:** worth confirming on-chain whether Fantom "MIM" is Multichain-issued; its local price (~$0.043) is near canonical MIM (~$0.038), unlike the other any* assets.

## 3. Geist Finance timeline — no hack; death by bridge collapse

- **2023-07-06:** Geist paused its contracts in reaction to the Multichain outflows.
- **2023-07-09:** resumed **"withdraw and repay only"** mode while awaiting Multichain news.
- **2023-07-14:** announced **it would not reopen**: "After confirmation from Multichain that the funds will not be recovered… Geist will not reopen." Reasons: Chainlink oracles track *canonical* USDC/USDT/WBTC/ETH, so they cannot price the Multichain assets, which were then trading at ~22% of real value; re-enabling lending would immediately create bad debt for holders of non-Multichain assets (MIM, FTM). (@GeistFinance 2023-07-14; Cointelegraph 2023-07-14)
- Geist explicitly: "this is in no way an attempt to blame Chainlink oracles which worked as they should. There are no oracles for the Multichain assets themselves because there was the expectation to exchange them 1:1. Nobody is to blame except Multichain."
- TVL before shutdown: ~$29M (Cointelegraph 2023-07-14).
- **Never reopened:** no reopening announcements found; DeFiLlama labels it "Deprecated protocol", ~$117k TVL, $0 active loans (checked 2026-10-13).
- **No Geist hack/exploit found** in searches and all contemporaneous coverage attributes the shutdown to Multichain. Audits exist (Solidity Finance). → **The "no hack; died from the bridge collapse" hypothesis is confirmed by public sources** (usual caveat: absence of web evidence is not proof).
- **Discrepancy to resolve on-chain:** Chainlink's official Fantom sunset was only announced in Dec 2025 for 2026-01-12. If Geist's oracle on-chain is frozen at ~2024 values, that is *not* explained by Chainlink's announced deprecation and needs direct on-chain inspection of Geist's oracle wiring and updatedAt timestamps. *(Parent note: on-chain, Chainlink aggregators revert on `latestRoundData()` and every PriceFeed returns `lastGoodPrice` with `status()==1` — verified 2026-10-13.)*

## 4. Off-ramps for the anyTokens today

- **No bridge found that accepts the Multichain any* tokens** as deposits or redemptions. Multichain is dead, KPMG is liquidating the entity as a creditor matter, and there is no swap/redeem contract.
- **Same-chain only:** SpookySwap and SpiritSwap still quote the any* pools, and Fantom-covering aggregators such as OpenOcean can route any* to other Fantom tokens at market prices. That is a *sale*, not redemption.
- **To leave Fantom Opera**, one must first swap into an asset a live bridge supports: Axelar/Squid (canonical USDC/USDT/ETH/WBTC) and **Sonic Gateway** (USDC, EURC, WETH, FTM). None accept any* tokens.
- **Context:** Sonic Labs is retiring Fantom Opera legacy infrastructure; the Opera FTM→S bridge migration deadline (2026-06-30) has passed. Opera remains as legacy infrastructure, but liquidity and tooling keep shrinking.

## 5. Chainlink and Band Protocol price feeds on Fantom

- **Chainlink (verified):** Official changelog, dated **2025-12-16**: "Support for Data Feeds on Fantom will be deprecated on **January 12th, 2026**." (https://docs.chain.link/changelog/deprecated-fantom-data-feeds). No announcement of an earlier Fantom-wide outage was found.
- **Band Protocol (unverified):** Only historical Fantom integrations found (2021 Fantom/fMint). No current Band documentation page listing Fantom; Band's public feed monitor showed no Fantom signals in a scrape (JS-heavy page — weak evidence). **No formal "Fantom discontinued" announcement found; cannot verify either way.**

## Unverified / open items

1. Exact reason/time Geist's oracle stopped advancing — needs on-chain oracle/feed reads (parent: done; feeds frozen, Chainlink aggregators revert, Band base updates frozen at 2024-12-03).
2. Squid/Axelar's precise Fantom token list (API auth required for verification).
3. Band Protocol's current Fantom status (no authoritative public source found).
4. Whether Fantom MIM is a Multichain-bridged token at all.
5. Any post-2026-01-02 liquidation developments (no public update found).

*Prepared as child research for the Geist Finance (Fantom) investigation; web sources only, no RPC calls.*
