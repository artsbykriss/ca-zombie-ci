# ReactorFusion — Incident & External-Facts Research

Web-research only (no writes, no txs). Research date: **2026-10-14**. Addresses below were confirmed with
light read-only `eth_call`s (zkSync `mainnet.era.zksync.io`, Telos `rpc.telos.net`) and public APIs.

## Summary table

| # | Question | Finding | Confidence |
|---|----------|---------|------------|
| 1 | Was there an exploit/hack? | **No protocol exploit found.** No entry in DefiLlama hacks DB, DeFiHackLabs, rekt.news, news search. Only incident: the **team's X account was hacked** (2025-01-09), no protocol funds affected. TVL spike/drop Jan–Mar 2025 = zkSync Ignite farming ending, not a hack. | Medium-High (absence of public evidence) |
| 2 | Source repos & audits | `github.com/ReactorFusion/reactorfusion-contracts` (+ `ReactorFusion/contracts`, the audited one). PeckShield audit 2023-05-31: 1 High (fixed), 1 Medium (admin keys, mitigated), 4 Low; **oracle explicitly out of scope**. | High |
| 3 | Admin keys | zkSync: Unitroller admin = **OZ TimelockController** `0xee56…bdb5` (24 h), proposer = **2-of-3 Safe** `0xD971…4CE2`. Oracle owner = **EOA** `0x9999…060d` (also a Safe signer). Telos: Unitroller admin = **EOA `0x9999…060d`, no timelock**; upgradeable impl `0xD4b1…2b40`. | High |
| 4 | RF/RFT token & rewards | Token is **RF** (no "RFT" found). Delisted from CoinGecko, mcap null, app price ~$0. sRF staking described in docs; `RewardsDistributor` proxies live on both chains; emissions "suspended". Ignite ZK rewards were via Merkl; no active Merkl campaigns found now. | Medium |
| 5 | Abandoned/paused? Stuck funds? | **Wind-down announced** via frontend modal (quote below): "wind down ReactorFusion… discontinue support on both zkSync Era and TelosEVM", frontend "until the end of April". Announcement added after 2025-09-06, live by today. `reactorfusion.xyz` root is now a Firebase 404. **No public stuck-funds reports found.** | High for the modal; **date uncertain** |
| 6 | Publicly known unprivileged extraction path | None reported. Closest: **Telos oracle `push()` is permissionless** and trusts **one Redstone demo signer** (threshold 1) — requires a forged/valid signed package (key not public). zkSync oracle owner can repoint feeds (privileged). | Medium |

---

## 1. Incidents / hack history

- **No exploit found.** Checks (2026-10-14):
  - DefiLlama protocol API `https://api.llama.fi/protocol/reactorfusion` → `"hacks": []`; live TVL
    `zkSync Era $291,205`, `Telos $629` (borrowed: $114,187 / $171). First data 2023-04-24.
  - DefiLlama hacks dataset `https://api.llama.fi/hacks` (354 KB, all incidents) → **no "reactor" match**.
  - `github.com/SunWeb3Sec/DeFiHackLabs` README (full incident list) → no ReactorFusion.
  - Searches: "ReactorFusion exploit/hack/drained/bad debt", Rekt.news, BlockSec/SlowMist/PeckShield →
    nothing. (Firecrawl web/developer searches.)
- **X account takeover (not a protocol hack):** on **2025-01-09** the official account `@ReactorFusionR`
  was "hacked and suspended"; the team created `@rf_protocol` and posted a 3-tweet notice:
  `https://x.com/rf_protocol/status/1877238639991672963` (thread: `…1877238642189504975`,
  `…1877238643938476239`). The old handle is now gone. This is likely the only "ReactorFusion hack"
  that search engines surface.
- **TVL swing (not a hack):** zkSync TVL ~$2.6M (Dec 2024) → peak ~$13.9M (2025-01-20) → ~$1.5M (Apr 2025).
  This matches **zkSync Ignite** liquidity incentives (last RF tweet 2025-02-18: "Ignite Round 6 rewards
  claimable") and the program's cancellation — ZK Nation DSC decided on **2025-03-14/17** not to renew
  Ignite for Season 2; program concluded **2025-03-31**:
  `https://forum.zknation.io/t/zksync-ignite-cancellation/612`,
  `https://www.coindesk.com/business/2025/03/14/zksync-sunsets-liquidity-rewards-program-citing-bearish-market-conditions`.
- **Gap:** absence of public reporting is not proof of no exploit; on-chain accounting checks are the
  other agents' task. No funds-returned event is known.

## 2. Repositories, audits, oracle design

- GitHub org `https://github.com/ReactorFusion`; key repos:
  - `https://github.com/ReactorFusion/reactorfusion-contracts` (last push **2024-05-16**). Files:
    `Comptroller.sol`, `ComptrollerStorage.sol`, `Unitroller.sol`, `CToken.sol`, `CTokenInterfaces.sol`,
    `CErc20.sol`, `CErc20Immutable.sol`, `CEther.sol`, `PriceOracle.sol`, `SimplePriceOracle.sol`,
    `Reservoir.sol`, `Timelock.sol`, `Maximillion.sol`, `JumpRateModel.sol`, `JumpRateModelV2.sol`,
    `BaseJumpRateModelV2.sol`, `WhitePaperInterestRateModel.sol`, `InterestRateModel.sol`,
    `es33/ES33.sol`, `es33/RewardDistributor.sol`.
  - `https://github.com/ReactorFusion/contracts` — the **audited** repo (same core files plus
    `interfaces/`, `lib/Ledger.sol`, `lib/RPow.sol`, `es33/*`).
- **PeckShield audit, final 2023-05-31** (audited commits `e3f4d30` → fixes `51c6baf`):
  `https://github.com/peckshield/publications/blob/master/audit_reports/PeckShield-Audit-Report-ReactorFusion-v1.0.pdf`
  - PVE-001 Low `getSnapshots()` logic (resolved); **PVE-002 High** empty-market/MINIMUM_LIQUIDITY (resolved);
    PVE-003 Low ERC20 compliance; PVE-004 Low CErc20/CEther interface; **PVE-005 Medium "Trust Issue of
    Admin Keys"** (mitigated — team said multisig, not EOA); PVE-006 reward-distributor front-running/MEV.
  - Important quote: "the protocol assumes a **trusted price oracle** with timely market price feeds…
    **the oracle itself is not part of this audit**."
- **Docs** (`https://docs.reactorfusion.xyz/`, machine index `llms.txt`): `protocol/contracts.md` (full
  address list, both chains), `protocol/oracles.md` ("Chainlink"/`SimpleOracle`), `security/multi-sig-timelock.md`,
  `security/audit.md`, `tokenomics/srf-staking.md`, `tokenomics/reward-emissions-and-emission-schedule.md`
  ("All emissions have been suspended"), `other-information/official-links.md`.
- **Oracle designs actually deployed (verified sources):**
  - **zkSync Era — `SimplePriceOracle` `0x1d54DD…5C43`** (unitroller `oracle()` confirms). Verified source
    (zkSync explorer API): hardcoded `priceFeeds` for 4 cTokens + **`setPriceFeed(ct, feed) external
    onlyOwner`**; `getUnderlyingPrice` = `feed.latestAnswer() * 10**(36-decFeed-decCToken)`. Owner =
    `0x99999A3C4cB8427c44294Ad36895b6a3A047060d` (**EOA**). Feeds are Chainlink-style
    `EACAggregatorProxy` contracts (e.g. `0x1824D2…76E`, description "USDC / USD"), each owned by Safe
    `0x5120…2eed` (v1.3.0, **4-of-9**, nonce 70). Feeds are **live**: on 2026-10-14, USDT 0.99874446,
    USDC 0.99986539, BTC 83,717.29, ETH 2,508.72 (8 dec), timestamps 2026-10-13/14.
  - **Telos — `SimplePriceOracle` `0x3B7023f3…4148`** verified source (Teloscan API): inherits Redstone
    `MainDemoConsumerBase`; **`push(bytes32[] tokens) external` with no access control**; stores
    `rawPrices[feedId]` read via `cToken.redStoneFeedID()`. Redstone base (v0.6.x, unpkg) trusts exactly
    **one signer** `0x0C39486f770B26F5527BBBf942726537986Cd7eb`, `getUniqueSignersThreshold() = 1`, service
    id `redstone-main-demo` — a Redstone **demo** service (signer is listed as a Redstone provider in
    `redstone-api/src/config/providers.ts`; private key not public).
- Frontend bundle (`https://main.reactorfusion.xyz/assets/index.88d2237a.js`) contains the contract map:
  zkSync `{COMPTROLLER 0x2384…F3f2, RF 0x5f7C…3E4D, REWARD_DISTRIBUTOR 0x53C0DE…12A9, VC 0x99bB…87F2,
  VC_LENS 0xf551…B165, LENS 0xfCED…b4Df, ORACLE 0x9919f1…c6c2, MERKL_DISTRIBUTOR 0xe117…6a21, ZK, WETH,
  MAXIMILION, ERC20_PAYMASTER}`, Telos `{COMPTROLLER 0x1964…E494, RF 0xb99C…a6EB, REWARD_DISTRIBUTOR
  0xC124…27E3, VC 0xe65B…f988, LENS 0x874E…865d, ORACLE 0x3B70…4148}`.

## 3. Admin keys / ownership

- **zkSync Era:** `Unitroller(0x23848c28…F3f2).admin()` = `0xee568575A8DaeF55D2fac121FD2362dF6BbB5Db5`
  — docs call this the **Timelock**; on-chain it is an **OpenZeppelin TimelockController**
  (`getMinDelay()` = 86400 s = 24 h; `PROPOSER_ROLE` = Safe). **Safe** `0xD971FAA20db3ad4d51D453047ca03Ce4ec164CE2`
  (Safe API `safe-transaction-zksync.safe.global`): v1.3.0+L2, **threshold 2 of 3**, nonce 12, owners:
  `0x99999A3C4cB8427c44294Ad36895b6a3A047060d`, `0x1234561fEd41DD2D867a038bBdB857f291864225`,
  `0xe2c1F5DDcc99B0D70584fB4aD9D52b49cD4Cab03` (all EOAs; no public labels found). Docs:
  `docs.reactorfusion.xyz/security/multi-sig-timelock` (2/3 + 24 h).
- **Telos:** `Unitroller(0x19646a04…E494).admin()` = **`0x99999A3C4cB8427c44294Ad36895b6a3A047060d`**
  (**plain EOA**, no timelock) — same address as Safe signer #1. Unitroller is upgradeable
  (`comptrollerImplementation()` = `0xD4b18A93019BA2DD9d1AD0e66302730648bE2b40`); the admin EOA can change
  implementation/parameters directly.
- zkSync `SimplePriceOracle.owner()` = the same EOA `0x9999…060d` → can repoint any market's feed
  (`setPriceFeed`). Telos oracle has no owner-gated setter; writes go through permissionless `push()`.
- No explorer labels were found for any of these addresses in web search; the Safe is verifiable via the
  Safe transaction service (link above).

## 4. RF / "RFT" token, staking, rewards

- Token = **RF** ("ReactorFusion", 18 dec): zkSync `0x5f7CBcb391d33988DAD74D6Fd683AadDA1123E4D`
  (totalSupply ≈ 79.23 M), Telos `0xb99C43d3bce4c8Ad9B95a4A178B04a7391b2a6EB`. **No "RFT" token found**;
  CoinGecko search for "reactorfusion" returns nothing (delisted); DefiLlama `mcap: null`; app showed
  "$0.0000". OFT bridge: `proxyOFT 0xF543…5c1D`.
- **sRF staking** (docs `tokenomics/srf-staking.md`): single staking pool, 90% of protocol revenue to
  stakers, 24 h unstake delay; frontend has a "Stake" page. Exact staking contract address is **not in
  docs and not exposed in the bundle config** (to resolve on-chain; likely near the RF/VC addresses).
- **Rewards contracts:** `RewardsDistributor` proxy `0x53C0DE201cab0b3f74EA7C1D95bD76F76EfD12A9` (zkSync,
  ~10 KB code) and `0xC124FE2f5edc1b645076A0722A7db8E9BD0227E3` (Telos). Repo `es33/RewardDistributor.sol`
  + `es33/ES33.sol` (upgradeable; ES33 = escrowed reward token; `reap()` swaps USDC→WETH→RF; velocore/bribe
  integration) were added 2024-05-16. Docs: emissions suspended ("use external incentives instead").
- **Ignite/Merkl:** ZK rewards were claimable via the zkSync Ignite dashboard / Merkl
  (`MERKL_DISTRIBUTOR 0xe117ed7Ef16d3c28fCBA7eC49AFAD77f451a6a21` in the app config). Merkl v4 API for
  chain 324 shows **no active "reactor" campaigns now**; unclaimed balances from expired campaigns may
  still be claimable via Merkl's UI (not verified).
- The "ReactorFusion Loyalty Program (RLP)" route (`/rlp_dashboard`) exists in the frontend, but its docs
  page is now 404 — no public detail found.

## 5. Abandonment / wind-down / stuck funds

- **Wind-down modal** on `https://main.reactorfusion.xyz/` (and indexed at `https://app.reactorfusion.xyz/`):
  > "After careful consideration, we have made the decision to **wind down ReactorFusion and discontinue
  > support on both zkSync Era and TelosEVM.** … The ReactorFusion frontend will remain available **until
  > the end of April** to allow users to withdraw their funds. After that point, the frontend will be
  > discontinued. Any further interaction with the protocol would only be possible through direct smart
  > contract interaction…"
  Reasons given: no future ecosystem/incentive programs, operational costs. The component
  (`ProtocolUpdateModal.tsx`) is in bundle `index.88d2237a.js`.
- **Date evidence (gap):** the archived bundle of 2025-09-06 (`index.5ea5012c.js`, Wayback) contains **no**
  "wind down"/"TelosEVM" strings → the announcement was published **after 2025-09-06** and is live today
  (2026-10-14). Wayback has no snapshots after Sep 2025; X (`@rf_protocol`) has no post after 2025-02-18;
  Medium `@ReactorFusion` is 404. The "end of April" wording suggests an intended deadline of 2026-04-30
  (announcement ~Q1 2026), but the frontend is still serving today. **Exact announcement date: unknown.**
- `https://reactorfusion.xyz` (root) now returns a Firebase "Site Not Found" page; the app subdomains still work.
  Linktree `linktr.ee/reactorfusion` last modified 2026-08-26; still links app/docs/X/Discord/GitHub/audit.
- **Stuck-funds reports: none found** (searches for withdraw/stuck/reddit/telegram). The ~$78.8k cash the
  triage sees is consistent with users who never withdrew before/after the wind-down; no public claim of
  frozen funds.

## 6. Public-info view of possible unprivileged extraction paths

1. **Telos oracle `push()` is callable by anyone** (`0x3B70…4148`). Values are taken from Redstone-signed
   packages validated against a **single demo signer** (`threshold = 1`, service `redstone-main-demo`).
   If that signer's key were known/compromised, or a valid signed package with attacker-chosen values can
   be obtained, prices can be set arbitrarily → borrow-drain of Telos markets (DefiLlama Telos TVL ≈ $629).
   No public key exposure was found; the address is a real Redstone provider entry. Also note there is
   **no freshness check on read**, so stale values persist.
2. **zkSync oracle feeds are trusted proxies** (`EACAggregatorProxy`), each owned by a 4-of-9 Safe;
   `SimplePriceOracle.setPriceFeed` is `onlyOwner` (EOA `0x9999…060d`) — privileged, not unprivileged.
3. **Admin/upgrade paths** (zkSync 24 h timelock + 2/3 Safe; Telos EOA admin + upgradeable Unitroller) are
   privileged rug vectors, not external exploits.
4. Nothing publicly reported suggests a code-level (Compound-fork) unprivileged bug; the on-chain
   accounting review should confirm.

## 7. Method & gaps

- Tools: Firecrawl search/scrape (web, news, developer index), direct `fetch` of public APIs (DefiLlama,
  Safe tx-service, CoinGecko, Merkl, Teloscan, zkSync explorer API, GitHub API, unpkg, Wayback CDX),
  light read-only `eth_call`s (admin/owner/oracle/delay/feeds).
- Gaps: no exploit data either way for the protocol contracts themselves; wind-down announcement date
  unknown (between 2025-09-06 and 2026-10-14); no explorer labels for admin addresses; sRF staking
  contract address not public; Telos oracle's last-push time not checked (on-chain task).
