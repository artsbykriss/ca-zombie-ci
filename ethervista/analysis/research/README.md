# EtherVista (Ethereum) — External web research

Companion file for the Z3-C5 on-chain deep-dive. Research window: 2026-10-15 → 2026-10-16 (UTC). All times UTC.
Method: Firecrawl web search/scrape; public APIs (GeckoTerminal, CoinGecko, DefiLlama, DexScreener); fxtwitter/Sotwe X mirrors; Wayback CDX. No transactions signed/sent; read-only.
Legend: [Z3-C5] = fact supplied by the campaign's on-chain analysis, not re-derived here. [NF] = not found/unverified — see §6.

## TL;DR
- The 2026-10-09 drain (~$18.6K) was executed via attacker contract 0x469424…83b120 "registered as the authorized router" (SlowMist wording). SlowMist's public root cause: uint112 overflow in the K-invariant check of EtherVistaPair.swap(). The realized loss is essentially the WETH side (≈7.478 WETH); the ~43.9K VISTA side appears to have been sent to the burn address by the attacker, not sold.
- No statement by EtherVista or Arctide about the incident was found (checked site, @ethervista (protected), @ArctideApp timeline, Medium, Discord/Telegram invites inaccessible). No public claim of key compromise, insider action, or returned funds [NF].
- Key custody: Etherscan labels 0xCA90D843288E35beeADfCe14E5F906e3F1AFc7cB "Ethervista: Deployer". The official published factory source makes the deployer the sole `routerSetter` (`setRouter` requires `msg.sender == routerSetter`); the contract contains no multisig/timelock for router changes, and `feeToSetter` is permanently burned (0x0). No public statement about hot-key vs multisig custody exists [NF]; the team is anonymous [NF: identity].
- Router history: the only officially published router is 0xcedd366065A146a039B92Db35756ecD7688FCC77 (repo updated 2024-10-24; on-chain created ~2024-09-29). The current router (0x9bD63C5D44fF28390df1EaaFD4eB4BD73E94A72a) is Etherscan-verified as "EtherVistaRouter" but was never published in the docs/repo; in active use at least since 2026-05-25 (Bloxy). No public discussion of the 2026-03/04 router flip-flops was found [NF].
- Project/current state (2026-10-15/16): CoinGecko price ≈ $0.4325, market cap ≈ $385.9K, rank 3996, 1y -92.0%; DefiLlama TVL ≈ $580,478; on-chain legacy VISTA/WETH pool activity ≈ 0 (GeckoTerminal), DexScreener no longer indexes any VISTA pair. Arctide (which says it acquired Ethervista's technology on 2026-09-16) still operates a VISTA swap/hardstake front-end at arctide.app/ethervista; ethervista.app says "Ethervista has been acquired by Arctide."

---

## 1. The 2026-10-09 incident (~$18.6K)

### 1.1 Primary report — SlowMist (2026-10-09 05:20 UTC)
Source: https://x.com/SlowMist_Team/status/2108427455572918626 (fetched via fxtwitter, 2026-10-15). Verbatim:
- "💸 @ethervista Loss: ~18.6K"
- "🔍 Root Cause: The EtherVistaPair.swap() function suffers from an integer overflow in its K-invariant check. Since both reserves are uint112, their multiplication overflows and wraps around, allowing the invariant check to pass even when the actual reserve product decreases significantly. The attacker exploited this flaw through an attacker-controlled contract registered as the authorized router, executing two crafted swaps to drain WETH and VISTA from the pool."
- "📌 Attacker: 0xbbf8f3fe8e4fdf6b594e6107144d78293d2018fa"
- "📌 Attack Contract (Router): 0x469424b628a9d2036e41496e814db500d683b120"
- "📌 Vulnerable Contract: 0xfdd05552f1377aa488afed744c8024358af02041"
- "Tx: https://etherscan.io/tx/0xb2c7332d9e1be6a86d9d37083aa4cc0d94b60eb95cc9b29494555a3c09764930"
Tweet metrics at fetch: 14,937 views, 60 likes, 25 replies. Tweet created 2026-10-09 05:20:52 UTC (fxtwitter `created_at`).
Note: SlowMist does NOT explain how authorization was obtained (no mention of setRouter, key compromise, or insider).

### 1.2 SlowMist Hacked DB entry (accessed 2026-10-15)
Sources: https://hacked.slowmist.io/ and https://hacked.slowmist.io/?c=ETH (entry dated 2026-10-09). Verbatim description: "EtherVista's liquidity pool was exploited due to an integer overflow in the K-invariant check inside EtherVistaPair.swap(). Both reserves are uint112, so their product can wrap around and the check can pass even when the real reserve product drops sharply. The attacker registered a self-controlled contract as an authorized router and ran two crafted swaps to drain WETH and VISTA, with a loss of about $18,600." Amount: $18,600. Attack method: "Smart Contract Vulnerability". Reference: the SlowMist tweet above.

### 1.3 News restatements (2026-10-09+)
- coinfomania via cryptonews.net (2026-10-09 13:14 UTC): "EtherVista Suffers $18.6K Loss Due to Exploit in Swap Function" — https://cryptonews.net/news/security/33565735/
- TokenPost: https://www.tokenpost.com/news/technology/28740 — "Ethervista Suffers Attack With Estimated $18,600 Loss"
- Binance Square / Foresight News: https://www.binance.com/en/square/post/375330733644868
- AiCoin news flash: https://www.aicoin.com/en/news-flash/3124763
- Gate news: https://www.gate.com/news/detail/VISTA/ethervista-loses-186k-to-swap-function-exploit-via-integer-overflow-24843800
- Digibastion threat-intel record (MEDIUM): https://www.digibastion.com/threat-intel/5b713a97-efa7-4cf5-aaa6-260b85a81c92
- Crypto Times: https://www.cryptotimes.io/2026/10/09/slowmist-flags-bitbay-and-ethervista-hacks-as-attackers-drain-32600-from-defi-vault-pool/
None of these contains a team statement or an authorization mechanism.

### 1.4 Independent proceeds-tracing report — SentinelTX via ChainBounty (published 2026-10-10)
Source: https://community.chainbounty.io/posts/01a124e8-a44f-7e49-94c0-d3d8326e54f4 ("EtherVista: Two swaps and the USDC trail", author dooooo, 2026-10-10; adapts "EtherVista Pair Incident — Ethereum Investigation Report", SentinelTX case CASE-ASYNC2B8). Key extracted findings:
- Timeline: 03:37:59 — attacker EOA 0xbbf8f3…2018fa receives 0.046448 ETH from an address labeled "HitBTC, UnionChain.ai" (tx 0xbbe324f8dd2ba2b91d428ab76704b74ea697771f136aa1778c98b68226a8f3ad). 03:42:23 — EOA deploys the helper router 0x469424…83b120 (tx 0x3b7b1ba7d633b1c4390a0c85312bd91836b715d7d290887bc4c39272dbaf35ba). 03:43:59 — small purchase (0.004008 ETH → 0.005864694170948497 VISTA). 03:47:11 — ERC-20 approve on VISTA via selector 0x095ea7b3. 03:47:59, block 26152259 — EOA calls its helper; incident tx 0xb2c7332d…; receives 7.477952467865157 WETH and 43,855.90219627576 VISTA. 03:54:11 — disposal steps (2.0 VISTA back to pair, etc.). 03:55:47 — 43,930.080656851984 VISTA sent to burn address 0x…dead (tx 0x9be0e1c315cc2298597758a98bd12c8f25a7ee50037897644401a7d6f5638db4).
- Proceeds: WETH unwrapped in six steps totaling 7.477 ETH; converted via Uniswap Universal Router (3.0 ETH→7,469.156952 USDC; 3.362307 ETH→8,369.649164 USDC; 1.105714 ETH→2,751.910344 USDC) = 18,590.716460 USDC total. Three later transfers to a pre-existing wallet 0x043c8f2df89612f9da2d91a92d30d3295cf842d3: 1,000 USDC at 05:36:47; 5,000 at 05:41:47; 5,000 at 05:43:47 (11,000 USDC total).
- "No exchange deposit, bridge deposit, or mixer interaction was identified in the traced flow."
- Attribution boundaries: "The deployment establishes the reported creator relationship; it does not by itself establish continuing administrative control." About the receiving wallet: "The transfer establishes where the reported funds went; the recipient's role beyond receiving them remains open."
- About the legitimate router appearing in the route: "SentinelTX assesses it as a public EtherVista router. Its appearance in the route does not make it part of the operator's infrastructure."
- The report does NOT identify how 0x469424…83b120 became "the authorized router" (no setRouter call in the chronology).

### 1.5 The router set/restore window (03:46–03:49) [Z3-C5]
Per the campaign's on-chain brief: factory router was set to the attacker contract 0x469424… at 03:46 UTC, drained, and restored at 03:49 UTC. NO public source (SlowMist, SentinelTX/ChainBounty, news) covers or explains this window; no public explanation of who held/used the routerSetter authority [NF].

### 1.6 Team statements / insider / key compromise / funds returned
- Team/Arctide statement on the incident: NOT FOUND. Checked 2026-10-15/16: ethervista.app (now only an acquisition notice); @ethervista on X (now a new protected account "Acquired by Arctide", created 2026-07-29); @ArctideApp timeline (no mention of the Oct 9 incident); Medium (@ethervista suspended); no blog/post-mortem anywhere.
- Key compromise claim: NOT FOUND.
- Insider/dev-action claim: NOT FOUND (no public allegation either way).
- Funds returned: NOT FOUND — SentinelTX shows disposal to USDC and transfer onward; no return, no recovery report as of 2026-10-15.

---

## 2. Docs, architecture, official contracts, audits, governance, treasury

### 2.1 Official docs (docs.ethervista.app, GitBook)
- Official links page: DEX ethervista.app; Etherfun etherfun.app; TWITTER x.com/ethervista; DEPLOYED CONTRACTS github.com/Ethervista/Deployed-Contracts; HARDSTAKE TEMPLATES github.com/Ethervista/HARDSTAKE.
- Pool mechanics: per-pool `launch(...)` sets buy/sell LP & protocol fees (USD-denominated via on-chain oracle); per-pool `protocolAddress` receives protocol fees; creator can update fees/protocolAddress only via a 2-step, 3-day-delay process, and can renounce.
- Router/LP mechanics: the router implements `updateSelf`, `safeTransferLp`, `hardstake` for the "Euler model" reward distribution; "router is a variable stored in the factory's contract" — LP transfers must go through the router.
- No governance docs; no audit links.

### 2.2 Official deployed contracts (GitHub, authoritative published list)
Source: https://github.com/Ethervista/Deployed-Contracts (README, last commit 2024-10-24). Verbatim list:
- ROUTER: 0xCEDd366065A146a039B92Db35756ecD7688FCC77
- FACTORY: 0x9a27cb5ae0B2cEe0bb71f9A85C0D60f3920757B4 (matches the campaign's factory)
- SAFE_TOKEN_FACTORY: 0x1a97A037A120Db530dDCe8370e24EaD0FE9cf5d0
- HARDLOCK (all tokens): 0xF6B510928ab880507246CD6946b7F061Eb8A9C78
- HARDSTAKE/BOOST: 0xEE5a6F8a55B02689138c195031d09BAFDc7d278F
- HARDLOCK (vista_lp only): 0x9099EF7f34dC1af0d27e49Dc5B604bcCC03dCB21
- VISTA-ERC20: 0xC9bCa88B04581699fAb5aa276CCafF7Df957cbbf
- VISTA-PAIR: 0xfdd05552F1377aA488AFed744c8024358AF02041 (matches the campaign's pair)
- AUTOBUY-BURNER: 0xe17A0C382c8332A889EC9D026D6948e26C7f617D

### 2.3 Routers over time (documented + on-chain-verified, with dates)
- 0xCEDd366065A146a039B92Db35756ecD7688FCC77 — the router published in the official repo (as of 2024-10-24). Etherscan labels it "Ethervista: Router", verified source, created by "Ethervista: Deployer" ~2024-09-29; 53,726 total transactions at fetch; balance ≈ $6.7.
- 0x9bD63C5D44fF28390df1EaaFD4eB4BD73E94A72a — current router [Z3-C5]. Verified contract named "EtherVistaRouter", no public Etherscan label, no docs/repo entry. Bloxy records factory createPair calls from this address as of 2026-05-25; ethscanner reports 1,255 transactions as of 2026-09-06.
- Initial router (Aug/Sep 2024, pre-0xcedd36): NOT FOUND in surviving public pages [NF].
- 2026-03/04 flip routers: no public documentation or discussion found [NF] — see §4.2.

### 2.4 Factory governance in the published source (decisive for key custody)
factory.sol (Solidity 0.5.16, official repo): `routerSetter` set to `msg.sender` in constructor; `setRouter(address)` requires `msg.sender == routerSetter`; `setRouterSetter` allows handing off or zeroing — only callable by the current routerSetter; comment: "Can be set to the zero-address if there is no intent to upgrade Router versions". `feeToSetter` is initialized to 0x0 (burned at deployment) → `setFeeTo` permanently uncallable. There is NO multisig, timelock, or two-step process for `setRouter` at the contract level. The VISTA token restricts ERC-20 `approve()` to the factory's router.

### 2.5 Audits / bug bounty / governance / treasury
- Audits: none found. DefiLlama protocol record: `"audits":"0"`. CertiK Skynet: "CertiK Audit: No", "3rd Party Audit: No", Code Security 45%. Bankless (2024): "There are outstanding question marks around Ethervista, like whether its smart contracts have been audited."
- Bug bounty: none found (CertiK: "No CertiK Bug Bounty", "3rd Party Bounty: No").
- Governance: none found. CertiK token scan flags "Ownership Not Renounced"; only privileged roles = single routerSetter + per-pool `protocolAddress`.
- Treasury: no treasury address published. Per-pool protocol fees go to each pool's `protocolAddress`. DefiLlama's fees adapter tracks gas+tokens received by 0xca90d843288e35beeadfce14e5f906e3f1afc7cb (the deployer EOA).
- V2/second DEX factory: none found. One factory (0x9a27…); the repo publishes "SAFE_TOKEN_FACTORY" (0x1a97…) and tokenFactory.sol (Etherfun). "Arctide V2" is a separate product on Circle's Arc chain.
- Development record (Wayback CDX of ethervista.app): /lending 2026-01-31, /hardlock 2026-01-13, /hardstake 2026-02-06, /ai-agents 2026-03-06, /farm & /dual-yield 2026-03-12, /deploy 2026-04-08, /etherfun-launch 2026-05-10 — active development through mid-2026 before the Arctide deal.

---

## 3. RouterSetter EOA 0xCA90D843288E35beeADfCe14E5F906e3F1AFc7cB

### 3.1 Public attribution
- Etherscan label: "Ethervista: Deployer". No contract code; small token dust holdings (~$0 value).
- It is the ContractCreator of the VISTA token (0xc9bca88b…) and of the labeled router 0xcedd36 (~2024-09-29).
- DefiLlama treats 0xca90…c7cB as the Ethervista fee-receiving address (fees adapter).
- Human identity behind it: NOT FOUND. Team publicly described as anonymous (Coinranking; Gate Learn). No pseudonym, no doxx, no public statement about who holds it.
- Public custody statements (multisig? hot key?): NOT FOUND.
- 2026-09-16 acquisition by Arctide ("acquired Ethervista's technology"): no source states whether the deployer/routerSetter key was transferred, retained, or destroyed [NF].

### 3.2 Why this matters (contract-level facts)
Per the factory source: the router can only be changed by the single routerSetter address; no delay, no timelock, no two-step confirmation. So the 2026-10-09 "attacker contract registered as authorized router" step is, at the contract level, a setRouter call that must have originated from whichever key controls the routerSetter address. Public sources do not resolve whether that was the deployer key itself, a compromise of it, or an authorized insider action [NF].

---

## 4. Other incidents / router changes (2024–2026)

### 4.1 September 2024 — "unconscious" fee-drain exploit via the router (confirmed, widely covered)
Source: Protos, ~2024-09-06 — https://protos.com/ethervista-unconsciously-hacked-hundreds-of-times-by-bot/
- Researcher Chaofan Shou (@shoucccc, 2024-09-05): an initial attacker "hacked Ethervista by exploiting an integer overflow in the router contract to steal all the fee in it"; Shou's generic backrun bot copied the malicious transaction "hundreds of times". Amounts: initial attacker 10 ETH (~$23,766); eight other bots ~20 ETH (~$47,500); Shou's bot ~8 ETH (~$19,000).
- Shou: "The liquidity pools on Ethervista are not at risk… The vulnerability is in the router and can only be exploited to sweep fees."
- Separate contemporaneous issues: fee-parameter bug; failed liquidity removal on ETH/USDT pool (researcher Stacy Muur).
- The officially published router 0xcedd36 was created by the deployer EOA ~2024-09-29 — consistent with a post-incident router replacement (no explicit announcement survives).

### 4.2 2026-03/04 factory-router flip-flop periods — no public discussion found
The seven addresses noted by the campaign produce NO public discussion, news, or post-mortems. Only explorer traces: 0xa03626… has an ETHplorer page (WETH issuance records 2026-03-08); 0xdbf723… appears as an ERC-20 transfer counterparty; the other five returned no usable public hits. No Etherscan labels, no team statements [NF].

### 4.3 Other reported incidents 2024–2026
None beyond §1 and §4.1 were found. SlowMist's hacked DB has a single EtherVista entry: the 2026-10-09 $18,600 event.

---

## 5. Current state of the project and VISTA (as of 2026-10-15/16)

### 5.1 Ownership/rebrand status
- ethervista.app now reads: "Ethervista has been acquired by Arctide. Trade on Arctide.app."
- arctide.app/ethervista: "Ethervista has been acquired by Arctide. Trade the OG Ethervista token here! … ONE TOKEN. THE ORIGINAL CONTRACTS. Your VISTA stays on Ethereum." Live page data at fetch: VISTA PRICE $0.4419; EST. MARKET CAP $394.29K; TOTAL STAKED 45,189; TOTAL BURNED 107,746; POOL LIQUIDITY $70.16K; block 26,201,076; working swap + "Hardstake (14-day lock)" UI.
- Arctide announcement (own X, ~2026-10-05): "On 16 September 2026, Arctide acquired Ethervista's technology and rebuilt that programmable revenue model for @Arc. … Ethervista helped pioneer programmable pool revenue in production. Arctide carries that foundation forward."
- @ethervista on X is now a NEW protected account "Acquired by Arctide" (id 2082267914191695872, created 2026-07-29). The original account has been deleted.
- Arctide's visible timeline (last ~14 days to 2026-10-15) never mentions the Ethervista drain.

### 5.2 Token and market data (with sources/dates)
- CoinGecko (last updated 2026-10-15T23:00:54Z): price $0.432519; market cap $385,917 (rank 3996); 24h volume $55,273; 1y -92.0%; ATH $74.91 (2024-11-01); ATL $0.405607 (2026-10-09, incident day); TVL $580,478; GoPlus public notice calling the token contract "unverified" (discrepancy vs Etherscan-verified token, unresolved).
- GeckoTerminal pool 0xfdd05552…: price $0.438; reserve_in_usd $69,942.70; volume 0.0 and 0 buys/0 sells across m5–h24; pool created 2024-09-02T09:36:51Z.
- DexScreener: no indexed VISTA pairs as of 2026-10-15/16.
- DefiLlama: TVL $580,477.80 (2024 peak ~$6.3M). Fees: 24h $0; 7d $18.97; 30d $483.12; 1y $9,509.32; all-time $1,062,928.32.
- CertiK Skynet: 7d active users 130; 7d transactions 181; 7d token transferred $56.50K (+370%); Pulse Feed "10/09 05:04 Volume 24h Reached $120,000"; market cap ~$395K.
- Interpretation: the legacy Ethereum pool is effectively dormant (zero swaps in the tracked pool), while aggregated ticker venues still show some volume (~$55K/24h per CoinGecko) — source unresolved [NF]. Arctide keeps a small live front-end for VISTA (swap + hardstake) with ~$70K pool liquidity.

---

## 6. NOT FOUND / UNVERIFIED (explicit list)

1. No public statement by EtherVista or Arctide about the 2026-10-09 incident — [NF].
2. No public explanation of HOW the attacker contract 0x469424… became "the authorized router" — [NF]. (Contract-level mechanics: only the routerSetter address can call setRouter.)
3. No claim of fund return or recovery; SentinelTX's trail shows conversion to USDC, 11,000 USDC to a pre-existing wallet, no mixer/bridge/exchange deposit identified as of 2026-10-10 — [NF: return].
4. Identity of the person/entity behind deployer/routerSetter EOA 0xCA90…c7cB — [NF; team anonymous]. No public custody statement — [NF].
5. Whether the deployer/routerSetter key was transferred to Arctide in the 2026-09-16 acquisition — [NF].
6. Initial (Aug/Sep 2024) router address — [NF].
7. Public discussion/explanation of the 2026-03/04 router flip-flop addresses — [NF].
8. Audits — none; bug bounty — none; governance/DAO — not found; treasury address — not published.
9. Content of the single protected tweet on the new @ethervista account — inaccessible [NF].
10. The ~$55K/24h aggregated VISTA volume source/venue — unresolved vs ~$0 on tracked on-chain pools [NF].
11. Deleted March 2026 "AI agents" pivot tweets of the old account — primary sources partially lost [NF].
12. Medium caution: the Medium account `@ethervista` is suspended; a similar post under `@ethervista_team` contains wallet-support phishing-style language. Treat any "Ethervista Rewards/staking" off-site pages as untrusted [flag, not attributed].

## 7. Source index (URLs)
Primary incident: https://x.com/SlowMist_Team/status/2108427455572918626 · https://hacked.slowmist.io/ · https://community.chainbounty.io/posts/01a124e8-a44f-7e49-94c0-d3d8326e54f4 · https://cryptonews.net/news/security/33565735/ · https://www.tokenpost.com/news/technology/28740 · https://www.aicoin.com/en/news-flash/3124763 · https://www.gate.com/news/detail/VISTA/ethervista-loses-186k-to-swap-function-exploit-via-integer-overflow-24843800 · https://www.digibastion.com/threat-intel/5b713a97-efa7-4cf5-aaa6-260b85a81c92
Contracts/architecture: https://docs.ethervista.app/llms.txt · /official-links · /pool-configuration · /hardstake-and-hardlock · https://github.com/Ethervista/Deployed-Contracts · https://etherscan.io/address/0xcedd366065a146a039b92db35756ecd7688fcc77 · https://etherscan.io/address/0x9bd63c5d44ff28390df1eaafd4eb4bd73e94a72a · https://bloxy.info/txs/calls_sc/0x9a27cb5ae0b2cee0bb71f9a85c0d60f3920757b4
Deployer EOA: https://etherscan.io/address/0xca90d843288e35beeadfce14e5f906e3f1afc7cb · https://ethereum.routescan.io/address/0xCA90D843288E35beeADfCe14E5F906e3F1AFc7cB · https://github.com/DefiLlama/dimension-adapters/blob/master/fees/ethervista.ts
Other incidents: https://protos.com/ethervista-unconsciously-hacked-hundreds-of-times-by-bot/ · https://x.com/shoucccc/status/1831490425385054706 · https://ethplorer.io/address/0xa03626f924f550f615ebbbb6f024c250f9f0f3d4
Current state: https://www.ethervista.app/ · https://arctide.app/ethervista · https://www.sotwe.com/ArctideApp · https://api.coingecko.com/api/v3/coins/ethervista · https://api.geckoterminal.com/api/v2/networks/eth/pools/0xfdd05552F1377aA488AFed744c8024358AF02041 · https://api.llama.fi/tvl/ethervista · https://api.llama.fi/summary/fees/ethervista · https://skynet.certik.com/projects/ethervista
