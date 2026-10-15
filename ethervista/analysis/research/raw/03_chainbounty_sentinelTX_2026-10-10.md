# Raw: ChainBounty / SentinelTX report on the EtherVista pair incident
URL: https://community.chainbounty.io/posts/01a124e8-a44f-7e49-94c0-d3d8326e54f4
Author: dooooo · Published October 10, 2026 · Category: Community Investigation
Title: "EtherVista: Two swaps and the USDC trail"
Adapts: "EtherVista Pair Incident — Ethereum Investigation Report", SentinelTX case CASE-ASYNC2B8, dated October 10, 2026.
Extraction method: Firecrawl query-mode over the page (2026-10-15/16). Quotes are exact from the extracted answer.

INTRO (from direct scrape):
"On October 9, 2026, an Ethereum address received 7.477952467865157 WETH and 43,855.90219627576 VISTA in a transaction that made two swap-selector calls against an EtherVista liquidity pair. SentinelTX's report follows the subsequent disposal: VISTA went to the burn address, while ETH unwrapped from WETH was converted into 18,590.716460 USDC. … The sequence gives the approximately US$18,600 public incident estimate a concrete proceeds trail. … the reported overflow mechanism remains an assessment, and the two ending USDC positions are calculated from flows rather than measured balances. No exchange deposit, bridge deposit, or mixer interaction was identified in the traced flow."

TIMELINE (UTC, 2026-10-09):
- 03:37:59 — EOA 0xbbf8f3…2018fa received 0.046448 ETH from an address labeled "HitBTC, UnionChain.ai" (tx 0xbbe324f8dd2ba2b91d428ab76704b74ea697771f136aa1778c98b68226a8f3ad).
- 03:42:23 — EOA's first transaction deployed the helper router 0x469424…83b120 (tx 0x3b7b1ba7d633b1c4390a0c85312bd91836b715d7d290887bc4c39272dbaf35ba). "The deployment establishes the reported creator relationship; it does not by itself establish continuing administrative control."
- 03:43:59 — small purchase: 0.004008 ETH → 0.005864694170948497 VISTA (tx 0xad2425c14a1fdb5f953b445897221cd8efb510a5759847c75939e0bb41ed3161).
- 03:47:11 — VISTA contract call, selector 0x095ea7b3 (ERC-20 approve) (tx 0x172795c3db39d498f08e329d1cd6f5e145a71ce589efbbdfea3980741670696b).
- 03:47:59, block 26152259 — EOA called its newly deployed helper; incident tx 0xb2c7332d9e1be6a86d9d37083aa4cc0d94b60eb95cc9b29494555a3c09764930.
- 03:54:11 — disposal row: 0.006027 ETH outgoing; 2.0 VISTA sent to the pair.
- 03:55:47 — 43,930.080656851984 VISTA sent to 0x000000000000000000000000000000000000dEaD (tx 0x9be0e1c315cc2298597758a98bd12c8f25a7ee50037897644401a7d6f5638db4).

AMOUNTS / TRAIL:
- Received in incident tx: 7.477952467865157 WETH + 43,855.90219627576 VISTA.
- WETH unwrapped: 1.0 + 2.0 + 2.0 + 2.0 + 0.46 + 0.017 = 7.477 ETH (0.000952467865157 WETH left unwrapped).
- Uniswap Universal Router conversions: 3.0 ETH→7,469.156952 USDC; 3.362307 ETH→8,369.649164 USDC; 1.105714 ETH→2,751.910344 USDC. Total: 7.468021 ETH → 18,590.716460 USDC.
- Transfers to pre-existing wallet 0x043c8f2df89612f9da2d91a92d30d3295cf842d3: 1,000 USDC (05:36:47); 5,000 (05:41:47); 5,000 (05:43:47). Total 11,000 USDC.
- Flow-derived positions at end of record: receiving wallet 11,000 USDC (no outbound in traced window); starting EOA 7,590.716460 USDC net. "Neither figure is a live balance reading." EOA's signed history ends at nonce 22, 05:43:47.

ASSESSMENTS (quoted):
- "SentinelTX assesses it as a public EtherVista router. Its appearance in the route does not make it part of the operator's infrastructure."
- "The transfer establishes where the reported funds went; the recipient's role beyond receiving them remains open."
- Funds returned: "The page does not state that funds returned; it tracks disposal (VISTA to burn address, ETH to USDC, and USDC transferred to a pre-existing wallet)."
- Team/operator response: "The provided page contains no mention of team/operator response or statements."
Note: the report does NOT document any setRouter call or explain how 0x469424…83b120 became the pair's authorized router.
