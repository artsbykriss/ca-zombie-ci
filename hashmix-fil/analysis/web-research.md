# HashMix FIL (Filecoin FEVM) — Web Research Notes

- Compiled: 2026-10-14 (UTC), by a read-only research subagent.
- Target: HashMix FIL Liquid Staking Protocol, Filecoin FEVM (chain id 314). Main pool under investigation: `0x587A7eaE9b461ad724391Aa7195210e0547eD11d`.
- Methods: web search/scrape (Firecrawl), GitHub API, DefiLlama API, Filfox, Wayback Machine, CertiK, Filecoin FIPs discussions. Chinese-language queries attempted.
- Caveats: X/Twitter data via scraper (may be incomplete); Filfox pages fetched as rendered; long GitHub discussion quotes were substring-verified against the raw page text.

## 0. CRITICAL DISAMBIGUATION — "HashMix FIL" and "STFIL" are TWO DIFFERENT PROTOCOLS

- **HashMix FIL** (DefiLlama slug `hashmix-fil`): HashMix team's FIL liquid-staking + lending pool on FVM. Liquid token = **cWFIL** (not stFIL). Main pool `0x587A7eaE9b461ad724391Aa7195210e0547eD11d`. No exploit/hack report found for it.
- **STFIL** (DefiLlama slug `stfil`): a separate project — STFIL DAO, stfil.io, token **stFIL**, "Incubated by @protocollabs Founders & @OVioHQ" (X bio). It suffered the April 2024 incident. Website now offline.
- Evidence of separation:
  - HashMix's own staking tutorial: "You will also see **cWFIL (HashMix liquid token)** in your wallet after staking." — https://medium.com/@hashmix/staking-tutorial-hashmix-fil-liquid-staking-protocol-955e979a3ee9 (May 31, 2023)
  - HashMix docs: "The cWFIL token address is 0x587A7eaE9b461ad724391Aa7195210e0547eD11d." — https://hashmix.gitbook.io/hashmix-fil-liquid-staking/liquidity-token
  - STFIL X account bio: "@Filecoin Liquid Staking & Restaking Protocol … Incubated by @protocollabs Founders & @OVioHQ" — https://x.com/stfil_io
  - No source found that links the HashMix and STFIL teams or contracts.

## 1. What HashMix / HashMix FIL is, and known contract addresses

### 1.1 Protocol identity (primary sources)

- hashmix.org (live Oct 2026): "Decentralized Cloud Hash Power Tokenization and Circulation Protocol. Redistribute the Global Hash Power Freely"; links: App (app.hashmix.org), FVM Product (fvm.hashmix.org), whitepapers (docsend), Twitter @HashMixOfficial, TG t.me/HashMixChannel, GitHub HashMixProject, Medium hashmix.medium.com, Discord. — https://hashmix.org/ ; footer "copyright@hashmix2021".
- Docs "Introduction": "HashMix is an open staking and lending platform… built our first Filecoin staking application in early 2021. We've helped dozens of miners get loans, sealed an additional 300 PiB SP, and FIL holders received an average of 20% APY. Peak TVL exceeded 1 million FIL." — https://hashmix.gitbook.io/hashmix-fil-liquid-staking/
- Docs "Team": "The HashMix team has been actively involved in the Filecoin ecosystem for over three years. In July 2021, we launched our Filecoin lending product… peak of $100 million TVL, offering stakers an average of 20% APY." — https://hashmix.gitbook.io/hashmix-fil-liquid-staking/team
- Filecoin Foundation ecosystem listing: "HashMix FIL Liquid Staking Protocol is a fully decentralized FIL liquid staking and lending protocol built on FVM." — https://fil.org/ecosystem-explorer/hashmix (page fetch returned 429; text from search index)
- Filecoin blog (FVM Imaginarium, staking protocols): mentions "HashMix has been facilitating…" — https://www.filecoin.io/blog/fvm-imaginarium-staking-and-leasing-protocols
- Launch: "On June 1st, the HashMix FIL Liquid Staking Protocol was launched, and within a month, the protocol's Total Value Locked (TVL) surpassed $2 million!" — https://medium.com/@hashmix/certik-audit-report-on-hashmix-fil-liquid-staking-protocol-details-226182a7a409 (Jul 3, 2023)
- V2 launch: "Three months ago, we launched HashMix FIL Liquid Staking… we have made the decision to release an enhanced pool known as HashMix FIL Liquid Staking V2… HashMix FIL lending, which attracted 1 MM FIL max and provided an average 20% APY for stakers, helped more than 40 SPs seal over 200 Pib." — https://medium.com/@hashmix/hashmix-fil-liquid-staking-protocol-v2-launching-5c634cee62f0 (Sep 13, 2023)
- Architecture (docs): FIL holders deposit FIL → receive cWFIL; Storage Providers borrow FIL against miner collateral; "Earnings are the interest of the loan… SPs will pay FIL as the loan's interest, which is the income of HashMix stake users." — https://hashmix.gitbook.io/hashmix-fil-liquid-staking/faq
- cWFIL ratio (docs, verbatim): "Users can stake FIL into the HashMix smart contract on FVM and receive roughly 1:100 cWFIL tokens in exchange." — same FAQ page (ratio ambiguous; see UNRESOLVED).
- Audited component names (actual FEVM source is private; see §0/§3): `Hashmix.sol`, `CreditsBook.sol`, `HsmERC20.sol`, `MinerCertificate.sol`, `MultiSig.sol`, `PeanutFarm.sol`, `PeanutHull.sol`, `FeeModel.sol`, `InterestRateModel.sol`, `JumpRateModel.sol`, `WhitePaperInterestRateModel.sol`, `ExponentialNoError.sol`, `Leb128.sol`, `ErrorReporter.sol` — CertiK audit PDF (link §3).
- DefiLlama adapter (public fork copy) shows the pool is Compound-style: commented-out calls to `totalBorrows` / `totalReserves` on the pool, plus a dead TVL API call: `let tvl = await get("https://fvm.hashmix.org/fevmapi/tvl"); api.add(nullAddress, tvl.data); return sumTokens2({ api, owner: POOL, tokens: [nullAddress] });` with `const POOL = "0x587A7eaE9b461ad724391Aa7195210e0547eD11d";` — https://github.com/ShiftForex/defillama/blob/main/projects/hashmix/index.js (original removed from DefiLlama-Adapters main; now referenced in https://github.com/DefiLlama/DefiLlama-Adapters/blob/main/registries/deadAdapters.json).

### 1.2 Contract addresses (HashMix)

From HashMix's own Medium post (Jul 3, 2023): "The relevant contract addresses are as follows:
- **Staking Pool (also CwFIL token): 0x587A7eaE9b461ad724391Aa7195210e0547eD11d**
- **Timelock contract and multi-sig addresses: 0x358cc936fc3035a49e02d670ec9b8e0061e97979**"
— https://medium.com/@hashmix/certik-audit-report-on-hashmix-fil-liquid-staking-protocol-details-226182a7a409

From the live FVM app JS bundle (fetched 2026-10-14): https://fvm.hashmix.org/v2/static/js/main.56b1bbc0.js
- Current prod config (`mt="2"`): pool `0x85e77391C3dDe4fee572A79CFef7f710c7476f82` (V2 pool), `hashmixContractAddress` `0x10d81c7a15da6218f475b82ebfd638cfc3cf36a5`, chainId `0x13a` (314).
- Legacy config (`mt="1"`): pool `0x587A7eaE9b461ad724391Aa7195210e0547eD11d` (V1 pool), `hashmixContractAddress` `0xFA33F3866e7eF32F79734BCC5e011d767F8E574b`.
- Dev/testnet (chainId `0x1df5e76` = 31415926): pool `0x302B4d4f9A838d50eC63C32D54A1BBD813B30c36`, controller `0x715A185447c6EcFcdB6e9815b31B2f434129Ad63`; RPC dev ws `http://117.184.165.178:34567/rpc/v1`.
- API endpoints used by the app: `/fevmapi/tvl`, `/fevmapi/miner_latest_estimate`, `/fevmapi/estimate_list`, `/fevmapi/bind_referer`, `/fevmapi/get_rate_history_list`, `/fevmapi/get_pool_history_list` (all POST `version:2`).

From the CertiK audit report (remediation note): "HashMix Team added multisig in commit `9fdfef4894c7f22c2401ebe47f593c3ee87c9d38`, **multisig address: `0x37878C623D87D5E99BEA602B9b72886676f3DEF0`**" — https://github.com/HashMixProject/securityAudit/blob/main/REP-final-20230607T032758Z.pdf

### 1.3 STFIL (separate protocol) addresses — for avoidance of confusion

- Original STFIL contract (from STFIL's own incident tweet, short-link resolved): ETH form **`0x3C3501E6c353DbaEDDFA90376975Ce7aCe4Ac7a8`** (f4: `f410fhq2qdzwdkpn25xp2sa3ws5ooplhevr5ittlp6by`, token "Staked FIL (stFIL)"). https://x.com/stfil_io/status/1777560493017686264 → https://filfox.info/en/address/f410fhq2qdzwdkpn25xp2sa3ws5ooplhevr5ittlp6by
- Incident funds destination (alleged police): `f410falck3ysg7e2k4outtq2r24ytd66cuddydnoga6a` (ETH: `0x02c4ade246f934aE3a939c351d73131FBc2A0c78`). Sources: https://www.coindesk.com/policy/2024/04/09/filecoin-liquid-staking-platform-stfil-claims-team-members-under-investigation-by-chinese-police ; https://github.com/filecoin-project/FIPs/discussions/989
- STFIL CLI README example lending-pool address (not primary contract): `0xc5A520f9Ea2DB52805f570741B1E869E07f308d4` — https://github.com/stfil-io/stfil-cli

## 2. The stFIL incident(s) — April 2024 (STFIL, not HashMix)

**Bottom line: confirmed, but it is the STFIL protocol's incident. No HashMix FIL exploit/incident was found in any source.**

Timeline:
- **Apr 5, 2024** — funds begin moving; the destination address `f410falck…` was created 2024-04-05 12:18:00 (Filfox: https://filfox.info/en/address/f410falck3ysg7e2k4outtq2r24ytd66cuddydnoga6a). FIP discussion references "the STFIL incident on April 5, 2024" (search snippet; https://github.com/filecoin-project/FIPs/discussions/989). Binance Square: "The STFIL incident occurred on April 5, 2024…" — https://www.binance.com/en/square/post/30335991749569
- **Apr 8, 2024** — team announcement (per Cointelegraph: "On April 8, the STFIL team announced that core technical members was detained by local Chinese police and that the mysterious upgrades and transfers had occurred during these detentions" — https://www.tradingview.com/news/cointelegraph:ceb82cb33094b:0-filecoin-foundation-launches-chinese-legal-inquiry-into-stfil-incident/).
- **Apr 9, 2024** — @stfil_io tweet (still the account's last visible post): "We believe that the STFIL core technical team is under investigation by local Chinese police… Last week, when the core technical team was under detention… FIL on the STFIL platform was moved to an unknown, external address. Additionally, in the past few days, there have been abnormal, unscheduled upgrades to the protocol. The funds were moved to the following address: [f410falck3ysg7e2k4outtq2r24ytd66cuddydnoga6a]. This is the original stFIL address: [f410fhq2…]. Upon learning the above information, the team is actively seeking assistance. We hope that the community can help track this unknown address…" — https://x.com/stfil_io/status/1777560493017686264
- **Apr 9, 2024** — press: CoinDesk: "STFIL said that its core technical team is being investigated and that lawyers have been hired… Tokens on the platform were moved to an unknown address that now holds **around $23 million in FIL**." / "The address in question holds **over 2.5 million FIL tokens** worth around $23 million." / "STFIL, which has just under $40 million total value locked" — https://www.coindesk.com/policy/2024/04/09/filecoin-liquid-staking-platform-stfil-claims-team-members-under-investigation-by-chinese-police ; The Block headline Apr 9, 2024: "Filecoin liquid staking platform STFIL claims team members under investigation" — https://www.theblock.co/news/macro/2024-04-09-filecoin-stfil-china-287163
- **Apr 12, 2024** — FIPs discussion #989 "Freeze stfil user's transferred asset address" opened by `justinjuarez3518`: "Currently, **more than 4.5 million FIL** of Stfil user assets have been transferred to 'unknown addresses' - https://filfox.info/en/address/f410falck3ysg7e2k4outtq2r24ytd66cuddydnoga6a, which most likely belong to the police." Also references FIP PR #990. — https://github.com/filecoin-project/FIPs/discussions/989 ; https://github.com/filecoin-project/FIPs/pull/990
- Mechanism per maintainer `momack2` (May 28, 2024 comment): "(My understanding is) there was a **4/6 multi-sig wallet** that allowed any party with access to 4/6 keys to deploy a new contract update changing anything about the smart contract…" and, in the same thread: "a state actor appears to have launched an investigation on the STFIL team, and these funds are allegedly under some form of seizure… The agency gained access to the admin multisig via the investigation by obtaining the keys of 4/6 signers (at least). They deployed a set of contract upgrades to block withdrawals for LPs, and to presumably take possession of liquid FIL in the staking pool." (same discussion URL; author of the second passage attributed loosely — verify on page)
- Foundation response: Cointelegraph — "Filecoin Foundation, a nonprofit… 'has a lawyer in China' and is investigating… according to an April 13 social media post from foundation senior fellow Danny O'Brien"; "FF has a lawyer in China who has been looking into the incident", the foundation has "high confidence" that STFIL team members are in police custody; it planned legal representation for staking providers and leasers. — https://www.tradingview.com/news/cointelegraph:ceb82cb33094b:0-filecoin-foundation-launches-chinese-legal-inquiry-into-stfil-incident/
- Community response — freeze proposal **rejected** at the protocol level:
  - `jennijuju` (maintainer, Apr 12, 2024): "The token movement was triggered by a series of signed transactions & user contract logics, it doesn't seem to be caused by bugs in the l1 protocol or bugs in smart contract… It will be a bad precedent to introduce censorship of FIL movement in blockchain protocol… I personally do not think this is a good idea."
  - `ansermino`: "This is not a situation where protocol-level censorship can be reasonably justified. (There aren't many….) Allowing a protocol-level resolution would set a bad precedent that would ultimately degrade the guarantees offered by the protocol."
  - `jsoares` (maintainer): "Based on public information, it appears that the funds were seized by law enforcement as part of a judicial inquiry into potential financial crimes. This is not the DAO hack…"
  - Victim `likhita-8091`: "Filecoin has teamed up with major exchanges to blacklist and freeze the address, prohibiting the account from recharging and monetizing… this amount of money is converted into nearly 100 million yuan." (claim, unverified)
  - All quotes from https://github.com/filecoin-project/FIPs/discussions/989 (substring-verified on page).
- Pre-incident size: STFIL tweet Mar 8, 2024: "We now have 5 MILLION #Filecoin staked on STFIL.IO" — https://x.com/stfil_io

Recovery status (as of 2026-10-14):
- The destination address **still holds 2,267,936.5357858668 FIL** (Filfox), 428 messages, latest tx **2025-11-12** (outflow of 1,767.4730 FIL to `f410f5cc…`, inflow 0.001 FIL). No wholesale sell-off observed. — https://filfox.info/en/address/f410falck3ysg7e2k4outtq2r24ytd66cuddydnoga6a
- No confirmed recovery/return to users found; discussion thread received comments through 2026 (dates up to 2026-05-18 per page).
- Protocol abandoned: STFIL site **stfil.io no longer resolves (DNS dead, checked 2026-10-14)**; community site `www.stfil.info` (cited by jsoares) also DNS-dead; @stfil_io silent since Apr 9, 2024. DefiLlama `stfil`: `deadUrl: true` — https://api.llama.fi/protocol/stfil

No link to HashMix found: searches for "HashMix" + "STFIL" produced no evidence of shared teams/contracts; the dispute involves STFIL's own multisig, not HashMix's.

## 3. Audits and security reports

- **CertiK — "Security Assessment, HashMix"**: "CertiK Assessed on Jun 7th, 2023"; "Delivered on 06/07/2023"; ecosystem Filecoin (FIL), Solidity, manual review + static analysis; codebase = `https://github.com/HashMixProject/hashmix-fevm/tree/0a5676a17f4d49ce6a07c3e461faa05016d18e82` (now 404). 14 files audited (list incl. `Hashmix.sol`, `CreditsBook.sol`, `HsmERC20.sol`, `MinerCertificate.sol`, `MultiSig.sol`, `PeanutFarm.sol`, `PeanutHull.sol`, `FeeModel.sol`, `JumpRateModel.sol`, `WhitePaperInterestRateModel.sol`, `ExponentialNoError.sol`, `Leb128.sol`, `ErrorReporter.sol`, `InterestRateModel.sol`). PDF: https://github.com/HashMixProject/securityAudit/blob/main/REP-final-20230607T032758Z.pdf
- Key findings (PDF):
  - GLOBAL-01 Centralization Related Risks: "Centralized privileged roles (`_owner`, `admin`, `controller`, `feeCollector`, `minter`, `farmer`, `creator`) control critical functions across multiple contracts… Any compromise to these accounts could allow a hacker to take advantage of this authority." Status: Acknowledged; multisig `0x37878C623D87D5E99BEA602B9b72886676f3DEF0` added in commit `9fdfef48…`.
  - GLOBAL-02 "Centralized Control of Contract Upgrade": "`CreditsBook`, `FeeModel`, and `Hashmix` are upgradeable contracts where the owner can upgrade the contract without community commitment. If an attacker compromises the account, they can change the contract implementation and drain tokens." Status: Acknowledged (multisig added, same commit).
  - Also HHM-01 "Potential Unpaid Debt", HHM-02 "`harvest()` Not Support Token", HMP-01 "Divide Before Multiply" (all Acknowledged).
- CertiK Skynet project page: "Code Audit History: 1 Audit available | Last Audit was delivered on Jul 5, 2023"; Code Security 50%; "2 Major Centralization (1 Acknowledged, 1 Mitigated)"; audit timeline "Requested on 6/9/2023, Revised on 7/5/2023"; Pulse feed "Security Audit Completed by CertiK (3y ago)". — https://skynet.certik.com/projects/hashmix
- HashMix Medium on the audit: "Prior to the launch, CertiK conducted a thorough audit of the protocol… Also our source code has been verified on Filfox and Beryx." — https://medium.com/@hashmix/certik-audit-report-on-hashmix-fil-liquid-staking-protocol-details-226182a7a409
- DefiLlama lists `audits: "2"` with `audit_links: ["https://github.com/HashMixProject/securityAudit"]` — one repo, one PDF found; second report not located. — https://api.llama.fi/protocol/hashmix-fil
- STFIL (separate) audit: CertiK Skynet project page linked by DefiLlama — https://skynet.certik.com/projects/stfil

## 4. Source code / GitHub

- HashMix org `HashMixProject`: only two public repos — `securityAudit` (one PDF, "Security audit reports") and `whitepapers`. No public FEVM/Solidity source. — https://github.com/HashMixProject
- The audited codebase repo referenced by CertiK — `https://github.com/HashMixProject/hashmix-fevm` (commit `0a5676a17f4d49ce6a07c3e461faa05016d18e82`) — returns **404** via the GitHub API on 2026-10-14 (private/removed).
- GitHub code search for the pool address `0x587A7eaE9b461ad724391Aa7195210e0547eD11d` found only third-party integration code, no HashMix source:
  - DefiLlama adapter forks: `projects/hashmix/index.js` (e.g. https://github.com/ShiftForex/defillama/blob/main/projects/hashmix/index.js)
  - `ipfs-force-community/filscan_backend` → `modules/syncer/fevm/defi_task/hashmix/defi_protocols.go` (GetProtocolName "HashMix FIL", GetContractId `0x587a7eae9b461ad724391aa7195210e0547ed11d`, TVL from DefiLlama slug `hashmix-fil`) — https://github.com/ipfs-force-community/filscan_backend
  - `guil-lambert/defipunkd` → `data/enrichment/hashmix-fil/{adapter,control,audits,sourcecode}.json` (enrichment; Filecoin unsupported by their verifier) — https://github.com/guil-lambert/defipunkd/tree/main/data/enrichment/hashmix-fil
  - `Zondax/web-beryx-explorer` → `src/api-client/beryx.test.ts` (Beryx test uses the pool address)
- Distinctive contract names (`PeanutHull`, `CreditsBook`): no public Solidity matches (repo is private).
- STFIL (separate protocol) repos: `stfil-io/stfil-home`, `stfil-io/stfil-docs` (archived), `stfil-io/stfil-cli`, `stfil-io/stfil-stake`, `stfil-io/protocol-whitepaper` — https://github.com/stfil-io

## 5. Current status (as of 2026-10-14)

- hashmix.org — live (marketing; "copyright@hashmix2021"). app.hashmix.org — live landing ("HashMix Lending", links FVM product, FIL Lending, ICP) — Wayback capture 2026-04-15: http://web.archive.org/web/20260415103117/https://app.hashmix.org/
- fvm.hashmix.org — **frontend up (HTTP 200)**, shows Stake/Unstake UI; **backend dead: all tested `/fevmapi/*` endpoints return 502** (`tvl`, `get_pool_history_list`, `get_rate_history_list`, `miner_latest_estimate`, `estimate_list`; POST `{"version":2}`). The DefiLlama adapter depends on `/fevmapi/tvl` → TVL tracking broke.
- DefiLlama: "HashMix FIL (cWFIL) — Deprecated protocol"; `deadFrom: "2026-01-01"`, `deadUrl: true`; TVL history first 2023-05-31 ($117,054), **peak $3,894,770 on 2024-03-09**, last recorded point 2025-03-11 ($164,350). — https://defillama.com/protocol/hashmix-fil ; https://api.llama.fi/protocol/hashmix-fil
- Docs/communications: GitBook docs live but stale ("Last updated 3 years ago"). Medium latest visible post Sep 14, 2023. X @HashMixOfficial last visible post **Jan 9, 2024** ("Since the interest rate of the HashMix V2 pool is more favorable, all SPs… have now borrowed from V2."). No pause/migration/withdrawal notices found anywhere.
- V1 pool dormancy: pool `0x587A…` last transaction **2024-02-23** (Filfox). V2 pool `0x85e7…` last activity **2025-04-11** (user `redeem(uint256)` OK + admin `_reduceReserves(uint256)`; one reverted tx earlier that day).
- STFIL (separate): stfil.io DNS dead; @stfil_io silent since Apr 9, 2024.

## 6. Control of the pool & the remaining ~1,581 FIL

- Who controls it (per public sources):
  - CertiK (GLOBAL-01/02): privileged roles (`_owner`, `admin`, `controller`, `feeCollector`, `minter`, `farmer`, `creator`) across `CreditsBook`, `FeeModel`, `Hashmix`, `HsmERC20`, `MinerCertificate`, `PeanutFarm`, `PeanutHull`; `CreditsBook`, `FeeModel`, `Hashmix` are upgradeable by owner. Remediation added multisig `0x37878C623D87D5E99BEA602B9b72886676f3DEF0`.
  - HashMix Medium: "Timelock contract and multi-sig addresses: `0x358cc936fc3035a49e02d670ec9b8e0061e97979`".
  - On-chain (Filfox): timelock/multisig `0x358Cc936…` = contract `f410fgwg…`, 29 messages, 4 unique addresses, methods `agree(bytes32)` / `execute(bytes32)` (HashMix's own `MultiSig.sol` pattern), created 2023-06-27, **last activity 2024-05-22**. CertiK multisig `0x37878C62…` = `f410fg6d…`, 35 messages, 6 unique addresses, last activity 2023-06-30. V1 controller `0xFA33F386…` = `f410f7iz…`, 223 messages, last tx 2024-01-08 (including a 20,459.8399 FIL invoke).
- The remaining FIL (V1 pool `0x587A…`): balance **1,581.864473017953 FIL**; 282 messages; 50 unique addresses; created 2023-05-23 02:10:30; last tx 2024-02-23 (`redeem(uint256)`), i.e. dormant for 2.5+ years. cWFIL token state: total supply **102,637.961067478399973187**, **12 holders**, 274 txs. — https://filfox.info/en/address/f410flb5h5lu3iynnojbzdktrsuqq4bkh5ui5druq3pq ; https://filfox.info/en/token/f410flb5h5lu3iynnojbzdktrsuqq4bkh5ui5druq3pq
- V2 pool `0x85e7…` holds only **241.09629576477042 FIL** (last activity 2025-04-11).
- Important explorer discrepancy: **Filfox says "Contract Source Code Verified" for the V1 pool (and for the timelock/multisig/STFIL contracts), while filecoin.blockscout.com reports it unverified.** The verified source may be retrievable via Filfox's Contract tab (JS-gated; not retrievable via simple HTTP during this pass). Beryx (now beryx.io) was the second verifier cited by HashMix.
- The V1→V2 migration context explains V1 dormancy: Jan 9, 2024 post "all SPs… have now borrowed from V2"; the V1 controller's last activity Jan 8, 2024 (`20,459.8399 FIL` invoke) matches the migration.

## Machine-readable JSON — contract addresses found

```json
[
  {"address": "0x587A7eaE9b461ad724391Aa7195210e0547eD11d", "role": "HashMix FIL V1 staking pool; also the cWFIL ERC-20 token contract; f4=f410flb5h5lu3iynnojbzdktrsuqq4bkh5ui5druq3pq (id f02200067); balance 1,581.864473017953 FIL; dormant since 2024-02-23", "source": "https://medium.com/@hashmix/certik-audit-report-on-hashmix-fil-liquid-staking-protocol-details-226182a7a409 ; https://hashmix.gitbook.io/hashmix-fil-liquid-staking/liquidity-token ; https://filfox.info/en/address/0x587A7eaE9b461ad724391Aa7195210e0547eD11d ; https://fvm.hashmix.org/v2/static/js/main.56b1bbc0.js"},
  {"address": "0xFA33F3866e7eF32F79734BCC5e011d767F8E574b", "role": "HashMix V1 controller ('hashmixContractAddress' in app config); f4=f410f7iz7hbtop3zs66ltjpgf4ai5oz7y4v2lytmsrfi; last activity 2024-01-08", "source": "https://fvm.hashmix.org/v2/static/js/main.56b1bbc0.js ; https://filfox.info/en/address/0xFA33F3866e7eF32F79734BCC5e011d767F8E574b"},
  {"address": "0x85e77391C3dDe4fee572A79CFef7f710c7476f82", "role": "HashMix FIL V2 staking pool + cWFIL token (current prod pool in the live app); f4=f410fqxtxheod3xsp5zlsu6op557xcdduo34c5lagkkq (id f02639857); balance 241.09629576477042 FIL; last activity 2025-04-11", "source": "https://fvm.hashmix.org/v2/static/js/main.56b1bbc0.js ; https://filfox.info/en/address/0x85e77391C3dDe4fee572A79CFef7f710c7476f82"},
  {"address": "0x10d81c7a15da6218f475b82ebfd638cfc3cf36a5", "role": "HashMix V2 controller ('hashmixContractAddress' in current prod config)", "source": "https://fvm.hashmix.org/v2/static/js/main.56b1bbc0.js"},
  {"address": "0x358Cc936fc3035A49E02d670Ec9b8E0061E97979", "role": "HashMix timelock + multisig (per official Medium post); f4=f410fgwgmsnx4ga22jhqc2zyozg4oabq6s6lzp75ifzq (id f02230996); agree/execute(bytes32); last activity 2024-05-22", "source": "https://medium.com/@hashmix/certik-audit-report-on-hashmix-fil-liquid-staking-protocol-details-226182a7a409 ; https://filfox.info/en/address/0x358cc936fc3035a49e02d670ec9b8e0061e97979"},
  {"address": "0x37878C623D87D5E99BEA602B9b72886676f3DEF0", "role": "Protocol multisig added as CertiK audit remediation (commit 9fdfef48...); f4=f410fg6dyyyr5q7k6tg7kmavzw4uimz3phxxqmfk2mky (id f02199149); last activity 2023-06-30", "source": "https://github.com/HashMixProject/securityAudit/blob/main/REP-final-20230607T032758Z.pdf ; https://filfox.info/en/address/0x37878C623D87D5E99BEA602B9b72886676f3DEF0"},
  {"address": "0x302B4d4f9A838d50eC63C32D54A1BBD813B30c36", "role": "HashMix dev/testnet pool (chainId 0x1df5e76 = 31415926; not mainnet)", "source": "https://fvm.hashmix.org/v2/static/js/main.56b1bbc0.js"},
  {"address": "0x715A185447c6EcFcdB6e9815b31B2f434129Ad63", "role": "HashMix dev/testnet controller (chainId 0x1df5e76; not mainnet)", "source": "https://fvm.hashmix.org/v2/static/js/main.56b1bbc0.js"},
  {"address": "0x3C3501E6c353DbaEDDFA90376975Ce7aCe4Ac7a8", "role": "STFIL (separate protocol) original stFIL contract/token; f4=f410fhq2qdzwdkpn25xp2sa3ws5ooplhevr5ittlp6by (id f02117164); balance 0 FIL; still probed as of 2026-07-22", "source": "https://x.com/stfil_io/status/1777560493017686264 (short link https://t.co/r42NUybJmT) ; https://filfox.info/en/address/f410fhq2qdzwdkpn25xp2sa3ws5ooplhevr5ittlp6by"},
  {"address": "f410falck3ysg7e2k4outtq2r24ytd66cuddydnoga6a", "role": "STFIL incident funds destination ('unknown address', alleged seized by Chinese police); ETH form 0x02c4ade246f934aE3a939c351d73131FBc2A0c78; still holds 2,267,936.5357858668 FIL as of 2026-10-14", "source": "https://www.coindesk.com/policy/2024/04/09/filecoin-liquid-staking-platform-stfil-claims-team-members-under-investigation-by-chinese-police ; https://github.com/filecoin-project/FIPs/discussions/989 ; https://filfox.info/en/address/f410falck3ysg7e2k4outtq2r24ytd66cuddydnoga6a"},
  {"address": "0xc5A520f9Ea2DB52805f570741B1E869E07f308d4", "role": "STFIL (separate protocol) example lending-pool address in stfil-cli README (not necessarily the main STFIL pool)", "source": "https://github.com/stfil-io/stfil-cli"}
]
```

## UNRESOLVED

1. **Identity/whereabouts of HashMix's current admin key holders** — multisig signers are not publicly named; relationship between timelock `0x358C…` and multisig `0x37878C…` (which one ultimately owns the pool's admin role) requires on-chain `owner()`/storage reads.
2. **Whether `redeem()` still functions for V1 pool cWFIL holders** — Filfox shows the last `redeem` succeeded 2024-02-23; no failed V1 txs seen, but this needs an on-chain simulation (parent session).
3. **Fate/ownership of the 1,581.86 FIL** in the V1 pool — no public statement; likely redemption liquidity/reserves given cWFIL supply (102,637.96 across 12 holders).
4. **Second CertiK audit** implied by DefiLlama (`audits: "2"`) — only one PDF found in `HashMixProject/securityAudit`.
5. **Verified source retrieval** — Filfox marks the pool "Contract Source Code Verified" but the Contract tab is JS-gated; Blockscout reports the same address unverified. Source text not captured in this pass.
6. **`HashMixProject/hashmix-fevm` repo** (audited codebase, commit `0a5676a1…`) — 404 today; whether it was ever public/archivable is unknown.
7. **Exact end of HashMix operations** — no shutdown/migration/pause notice found; communications stop between Sep 2023 (Medium) and Jan 9, 2024 (X); API silently died ~Mar 2025, DefiLlama marked dead 2026-01-01.
8. **STFIL fund recovery** — no recovery confirmed; destination still holds ~2.268M FIL with occasional small outflows (last 2025-11-12); commenter claim of exchange blacklisting unverified; thread still gets comments in 2026.
9. **The recalled "~$10M" figure** — no source with exactly $10M found; documented figures are ~$23M (2.5M FIL, CoinPesk), ">4.5M FIL" (FIP #989), "nearly 100M yuan" (~$14M, victim comment).
10. **cWFIL exchange-rate convention** — docs say "roughly 1:100 cWFIL per FIL"; needs on-chain confirmation (exchangeRateStored) for redemption math.
