# ZH4-PASS2 RECON — residual reconciliation: every lane candidate → one disposition + OPEN list

**Campaign:** 2026-10-23 · **Agent:** ZH4-PASS2 recon (`ses_e9885e0c8ffenmCAxjMtTH3ELE`) · **Mode:** read-only — no transactions signed or sent.
**Scope:** `zombie-hunt-iv/pass2/README.md` + **all 16 lane files** (`ai-trading-pattern, alpscon, argent, bridges, collapses, dolomite-jupiter, governance-live, incidents, launchpads, live-disclosures, mini-chains, monitor-diff, non-evm-incidents, public-key-auth, secured-finance, sibling-sweep`).
**Mission:** the principal flagged that the lane files name far more protocols than the README lists, and that some funded candidates may never have been assigned. This report gives **every named candidate a disposition** and produces the **OPEN list** (funded + plausible unprivileged path + no verdict anywhere).

**Deliverables:** this file · `summary.json` · `analysis/candidates.json` (269 machine-readable rows) · `analysis/disposition-tables.md` · `analysis/live-checks.txt` · `ci-out/` · CI run URL (below).

---

## 1. Method

1. Extracted **every named protocol candidate** from each lane — table rows **and** prose leads — recording chain, live funds, the lane's own verdict/status, and the lane's confidence.
2. Dispositioned each against the **prior-coverage corpus**: `ci/ZH4P5|ZH4P4|ZH4P3|ZH4P2|ZH4(pass1)|ZH3|ZH2B*|L1|H/H2|RESULTS-TRACKER.md`, `ci/L2-*.json`, `ci/TIER3-LOW-TRACKER.md`, `ci/MONITOR-LIST.md`, the kept/verified root folders (`ls -d */`), and `bash zombie-hunt-iv/zh4-check.sh "<name>"`.
3. **Rule for same-protocol/different-bug-class:** marked `PRIOR-PARTIAL (distinct angle)` and stated whether the new angle is worth a check.
4. For each **OPEN**, ran a quick live sanity check (contract exists? balance? already disproven?) to rank it. Ethereum reads at block **26,253,609** (publicnode); other chains per lane.

**Disposition legend**

| Code | Meaning |
|---|---|
| **README-FINDING** | Elevated to a pass2 README finding (P2-01 Radworks, P2-02 Pirate Chain) |
| **README-CLOSED** | In the pass2 README's verified-closed / Tier-3 / corrections tables |
| **LANE-CLOSED** | The lane itself reached a verdict (closed / not-exploitable / privileged / watchlist) |
| **PRIOR-COVERED** | Already handled in an earlier tracker or a kept root folder |
| **PRIOR-PARTIAL** | Same protocol, **distinct bug class/angle** (flagged, with a check recommendation) |
| **NOT-A-PROTOCOL** | Metric / address / hypothesis / key-compromise / base-layer / context |
| **OPEN** | Funded ≥~$1k + plausible unprivileged path + **no verdict anywhere** |

---

## 2. Counts

| Disposition | Count |
|---|---:|
| Enumerated (total candidates) | **269** |
| README-FINDING (unique protocols: Radworks, Pirate Chain) | 3 rows / **2** |
| README-CLOSED | 38 |
| LANE-CLOSED | 88 |
| PRIOR-COVERED | 98 |
| PRIOR-PARTIAL (distinct angle) | 1 |
| NOT-A-PROTOCOL | 32 |
| **OPEN** | **9** |

The pass2 README elevated only **2** findings (Radworks, Pirate Chain) and its closed/Tier-3 tables cover ~38 rows. The remaining **~229** candidates lived only in the lane files — which is exactly the gap the principal flagged.

---

## 3. OPEN list (funded + plausible unprivileged path + no verdict anywhere)

Ranked by **funds × plausibility**. Live sanity checks at 2026-10-23 (block 26,253,609 on Ethereum unless noted).

| # | Target | Chain | Live $ (verified now) | Plausibility | Gate / blocker | Next check |
|---|---|---|---:|---|---|---|
| 1 | **Inverse Finance** — `GovernorMills` `0xBeCCB6bb0aa4ab551966A7E4B97cec74bb359Bf6` / timelock `0x926df14a23be491164dcf93f4c468a50ef659d5b` / DOLA `0x865377367054516e17014CcdED1e7d814EDC9ce4` | Ethereum | **$113.06M DOLA mint authority** (operator = timelock) + ~$0.9M timelock (52,348 DOLA + INV/WBTC/sDOLA) | **MED-HIGH** | Permissionless `propose`→vote→`queue`→`execute` (quorum 24,000 INV ≈$263k; `proposalCount=379`). **Guardian requires 2 active parties**: deployer EOA `0x3fcb…cb28` `allowCancel(id,true)` **and** `rwg` 4/8 Safe `0x4b6c…f1b7` `executeCancel(id)`. A successful prop can `DOLA.mint(attacker,X)` (no cap). | Re-read guardian activity since 2026-02-12; decode recent proposals; check whether the 4/8 Safe / deployer EOA is still live; confirm no active hostile proposal. **Never assigned in any pass.** |
| 2 | **Gitcoin** — `GitcoinGovernor` `0x9D4C63565D5618310271bF3F3c01b2954C1D1639` / timelock `0x57a8865cfB1eCEf7253c27da6B4BC3dAEE5Be518` | Ethereum | **~$4.95M** (12,508,498.1 GTC + 138.76 ETH + $112k USDC — GTC balance re-verified) | **MEDIUM** | OZ-v5 governor (executed 2026-10-05) has a **Proposal Guardian** that can cancel, plus an Apr-2026 veto multisig with ~**4.06M GTC** delegated. Quorum 2.5M GTC (re-verified). Both guards must fail. | Identify + verify the guardian and veto-multisig delegation; check for any active proposal. **Never assigned in any pass.** |
| 3 | **Metric V1** — `MetricOmmPoolFactory` `0x2a53833cc95548cf52c7b159110e22D3a9018f32` (ETH + Base + ~8 chains, CreateX same-address) | multi | **$10.4M** (DefiLlama; ETH/Base/RH/Arb/AVAX/Polygon/Monad/BSC) | **LOW-MED** | Prop-AMM DEX, **0 audits**, custom pool code (factory = 21.5 KB runtime; exists on ETH + Base). Lane listed it but "not assessed in depth". | Pull adapter pools; recompile/verify factory+pools; check mint/collect/skim and oracle paths. |
| 4 | **Tempo Stablecoin DEX** — system precompile `0xdec0000000000000000000000000000000000000` | Tempo | **$15.8M** | **LOW** | Enshrined **Rust** orderbook (returns `0xef`); public surface narrow: `withdraw` is `msg.sender`-scoped (re-verified: zero-balance caller → `InsufficientBalance`). Residual risk in `fill_orders_exact_in/out` + "storage credits" accounting — "not fully fuzzed". | Invariant-fuzz `quoteSwapExactAmountIn/Out` vs executed fills on a local Tempo node for maker-credit > taker-debit delta. |
| 5 | **Upshift** (August Digital) — vaults via `api.augustdigital.io` (chain map: ETH/BSC/Base/AVAX/Hyperliquid/Monad/Plasma/Flare/Mezo/Ink/Fluent/Citrea/Solana/Sui/Stellar) | multi | **$8.8M** (Fluent row; larger cross-chain) | **LOW** | Audited curator (2 audits); lane "not assessed in depth". | Pull vault addresses from the API; check redeem/curator/allocator roles and any permissionless withdrawal. |
| 6 | **Katana Perps** — Custodian `0x23317197Cf82a14d7B7A671C23B94d39F6A2fa22` / Exchange `0x62230CeA619F734cc215bB8074bbF07bE4Eb633e` | Katana | **$1.364M** (vbUSDC; `exchange()` re-verified) | **MED (code unverified)** | Unverified **24,525-byte** Exchange with 96 selectors incl. obfuscated admin `join_tg_invmru_haha_212544a(uint256,bool,bool)`; tested paths revert (`SenderMustBeAdmin`; `Wallet exit not finalized`). **Signature verification in the withdraw/`operate` path could not be confirmed** — the one thing not provable without source. | Decompile selectors `0x1c794f24`, `0x851216f8`, `0x59702e17`, `0x8f51afe0`, `0x904cf00c`; verify EIP-712 signer binding + replay protection. |
| 7 | **LiquidLoans** — CDP `0x9159f1d2a9f51998fc9ab03fbd8f265ab14a1b3b` (code present, ~5.5 KB) | Pulse | **~$1.63M TVL** (was $4.28M on Oct 13) | **LOW-MED** | Fully-backed CDP, "immutable / governance-free / no admin keys", **0 audits**; TVL fell 62% in-window. Lane explicitly deferred: "recommend a separate adapter/on-chain check before treating it as an exploit." | Pull the `liquidloans-io` adapter; read collateral/redemption/liquidation paths; explain the $2.65M drop (outflow vs adapter). |
| 8 | **World Markets Spot** — order-book DEX (adapter `worldinc`) | MegaETH | **$664k** | **LOW** | MegaETH canonical DEX, **0 audits**; lane "not assessed in depth". | Locate contracts from the adapter; check margin/liquidation/withdraw auth. |
| 9 | **Rabby Swap legacy contract** (family on 19 chains) | 19 chains | **unquantified residual approvals** (original theft $200k, 2022) | **LOW** (likely <$1k) | Contract **never patched/paused**; any holder with a live allowance can be drained by anyone (caller-supplied instructions). Lane left it "UNVERIFIED — would need an allowance census; not worth it at likely <$1k". | Allowance census from the Revoke.cash exploit list; sum live allowances; only escalate if ≥$1k. |

### PRIOR-PARTIAL flagged for a check (distinct angle)

| Target | Prior angle | New angle | Live $ | Worth a check? |
|---|---|---|---:|---|
| **CapyFi** — Comptroller `0x00dc4965916e03A734190fA382633657c71f867E` | ZH2 **C2-13** (donation/inflation, E-U ≈$105/day) | **Apr-2026 public access-control disclosure** ("complete bypass of a required security control, permissionless access to restricted assets"); closed as "intentional design", team then redeemed 5.5B tokens (~62%, ~$55M) minutes later | **~$5.1M cash** (1.226M USDT + 364k USDC + 1,250 ETH + 6.36 WBTC) | **Yes** — different bug class from the prior close; live-funded; but protocol is excluded from ranking, so it is a correction/monitor, not an OPEN finding. |

---

## 4. Full disposition tables (every lane, every named candidate)

### governance-live.md

| Candidate | Chain | Live $ | Disposition | Note |
|---|---|---:|---|---|
| Radworks (Radicle) | Ethereum | $14,760,000 | **README-FINDING** | P2-01; live governance capture; kept radworks/ |
| Inverse Finance (GovernorMills/DOLA) | Ethereum | $113,060,000 | **OPEN** | Unassigned; lane verdict GATED (2-party guardian); DOLA operator=timelock => arbitrary mint; quorum 24k INV; distinct from prior FiRM/H-30 angle |
| Gitcoin (GitcoinGovernor) | Ethereum | $4,950,000 | **OPEN** | Unassigned; lane verdict GATED (Proposal Guardian + 4.06M-GTC veto multisig); quorum 2.5M GTC |
| ENS | Ethereum | $62,220,000 | **LANE-CLOSED** | 5/8 Security Council can cancel (gated) |
| Compound | Ethereum | $6,900,000 | **LANE-CLOSED** | Proposal Guardian; quorum > treasury |
| Uniswap | Ethereum | $1,900,000,000 | **LANE-CLOSED** | No guardian but quorum cost ~15% of treasury |
| Silo Finance | Ethereum | $3,540,000 | **LANE-CLOSED** | Governor timelock empty; treasury in team multisigs |
| OpenDollar | Arbitrum | $7,700 | **LANE-CLOSED** | TVL $7.7k; no DEX; only add-collateral |
| HAI | Optimism | $111,000 | **README-CLOSED** | Hardening executed; prior ZH4-01/P2 |
| Aavegotchi | Ethereum | $1,700 | **LANE-CLOSED** | Treasury $1.7k non-own |
| Thales | Ethereum | — | **LANE-CLOSED** | Snapshot/council/multisig or prior corpus; not unfrozen on-chain timelock |
| Kleros | Ethereum | — | **LANE-CLOSED** | Snapshot/council/multisig or prior corpus; not unfrozen on-chain timelock |
| Tokemak | Ethereum | — | **LANE-CLOSED** | Snapshot/council/multisig or prior corpus; not unfrozen on-chain timelock |
| Balancer | Ethereum | — | **LANE-CLOSED** | Snapshot/council/multisig or prior corpus; not unfrozen on-chain timelock |
| Alchemix | Ethereum | — | **LANE-CLOSED** | Snapshot/council/multisig or prior corpus; not unfrozen on-chain timelock |
| Yearn | Ethereum | — | **LANE-CLOSED** | Snapshot/council/multisig or prior corpus; not unfrozen on-chain timelock |
| Frax | Ethereum | — | **LANE-CLOSED** | Snapshot/council/multisig or prior corpus; not unfrozen on-chain timelock |
| Convex | Ethereum | — | **LANE-CLOSED** | Snapshot/council/multisig or prior corpus; not unfrozen on-chain timelock |
| Yam | multi | — | **PRIOR-COVERED** | Prior corpus / governance wave |
| Moonwell | multi | — | **PRIOR-COVERED** | Prior corpus / governance wave |
| BarnBridge | multi | — | **PRIOR-COVERED** | Prior corpus / governance wave |
| Curio | multi | — | **PRIOR-COVERED** | Prior corpus / governance wave |
| Term | multi | — | **PRIOR-COVERED** | Prior corpus / governance wave |
| Neutron | multi | — | **PRIOR-COVERED** | Prior corpus / governance wave |
| BONKDAO | multi | — | **PRIOR-COVERED** | Prior corpus / governance wave |
| Ampleforth | multi | — | **PRIOR-COVERED** | Prior corpus / governance wave |
| Idle | multi | — | **PRIOR-COVERED** | Prior corpus / governance wave |
| Goldfinch | multi | — | **PRIOR-COVERED** | Prior corpus / governance wave |
| Badger | multi | — | **PRIOR-COVERED** | Prior corpus / governance wave |
| mStable | multi | — | **PRIOR-COVERED** | Prior corpus / governance wave |
| TrueFi | multi | — | **PRIOR-COVERED** | Prior corpus / governance wave |
| Cream | multi | — | **PRIOR-COVERED** | Prior corpus / governance wave |
| Fei | multi | — | **PRIOR-COVERED** | Prior corpus / governance wave |
| StrongBlock | multi | — | **PRIOR-COVERED** | Prior corpus / governance wave |
| Swerve | multi | — | **PRIOR-COVERED** | Prior corpus / governance wave |
| Ooki | multi | — | **PRIOR-COVERED** | Prior corpus / governance wave |
| Reserve | multi | — | **PRIOR-COVERED** | Prior corpus / governance wave |
| Olas | multi | — | **PRIOR-COVERED** | Prior corpus / governance wave |
| Token of Power | multi | — | **PRIOR-COVERED** | Prior corpus / governance wave |
| Moonriver | multi | — | **PRIOR-COVERED** | Prior corpus / governance wave |

### alpscon.md

| Candidate | Chain | Live $ | Disposition | Note |
|---|---|---:|---|---|
| AlpsCon V4 | BSC | — | **README-CLOSED** | Closed table + prior alpscon-latent (gate removed; pools drained) |
| AlpsCon V5 | BSC | — | **README-CLOSED** | Closed table + prior alpscon-latent (gate removed; pools drained) |
| AlpsCon V6 | BSC | — | **README-CLOSED** | Closed table + prior alpscon-latent (gate removed; pools drained) |
| AlpsCon V7 | BSC | — | **README-CLOSED** | Closed table + prior alpscon-latent (gate removed; pools drained) |
| AlpsCon V8 | BSC | — | **README-CLOSED** | Closed table + prior alpscon-latent (gate removed; pools drained) |
| AlpsCon V9 | BSC | — | **README-CLOSED** | Closed table + prior alpscon-latent (gate removed; pools drained) |
| AlpsCon Vault | BSC | — | **README-CLOSED** | Closed table + prior alpscon-latent (gate removed; pools drained) |
| AlpsCon SwapContract | BSC | — | **README-CLOSED** | Closed table + prior alpscon-latent (gate removed; pools drained) |
| AlpsCon fund modules | BSC | — | **README-CLOSED** | Closed table + prior alpscon-latent (gate removed; pools drained) |
| AlpsCon New V6/ALPS/New Swap | BSC | — | **LANE-CLOSED** | Watchlist; local accounting, 0 funds |
| AlpsCon InnovatorHub | BSC | — | **LANE-CLOSED** | 13.37M ALPS, no DEX pair, no USDC payout |
| AlpsCon owner/fund EOA/delegates | BSC | — | **NOT-A-PROTOCOL** | Addresses/actors |

### ai-trading-pattern.md

| Candidate | Chain | Live $ | Disposition | Note |
|---|---|---:|---|---|
| AlpsCon/Tradeoshi (all versions) | BSC | — | **README-CLOSED** | Same family as alpscon lane |
| Third-party reward-import repeats | multi | — | **NOT-A-PROTOCOL** | 0 found in code indexes/DefiLlama |
| HubAI | multi | — | **NOT-A-PROTOCOL** | Generic web 'AI trading' leads; no on-chain hub |
| TradeHub | multi | — | **NOT-A-PROTOCOL** | Generic web 'AI trading' leads; no on-chain hub |
| QAI | multi | — | **NOT-A-PROTOCOL** | Generic web 'AI trading' leads; no on-chain hub |
| GT Protocol | multi | — | **NOT-A-PROTOCOL** | Generic web 'AI trading' leads; no on-chain hub |
| BitradeX | multi | — | **NOT-A-PROTOCOL** | Generic web 'AI trading' leads; no on-chain hub |
| Zero-activity hub deployments | BSC | — | **NOT-A-PROTOCOL** | Test/duplicate deployments, 0 funds |

### argent.md

| Candidate | Chain | Live $ | Disposition | Note |
|---|---|---:|---|---|
| Argent-style wallet modules (0x4e50/0xf490) | Ethereum | — | **README-CLOSED** | Closed table; digest fully bound; 0/1328 payable |
| 1,328 wallet set / victims / attacker | Ethereum | — | **NOT-A-PROTOCOL** | Addresses; nominal only |
| MARK/WETH pool | Ethereum | — | **NOT-A-PROTOCOL** | Historical sandwich venue |

### bridges.md

| Candidate | Chain | Live $ | Disposition | Note |
|---|---|---:|---|---|
| Echo Bridge (B2/uBTC) | BSquared | $10,620,000 | **README-CLOSED** | Privileged issuer burn+freeze; $0 E-U; prior ZH4P2 |
| zkLink Nova | Ethereum/L2 | $3,920,000 | **README-CLOSED** | Legit 2024 depositor exit; proof-gated; prior ZH4P2 |
| B2 Network / Echo Monad eBTC | B2/Bitcoin | — | **NOT-A-PROTOCOL** | Context/history |
| aBTC on Aptos | Aptos | — | **NOT-A-PROTOCOL** | Counterparty risk context |

### collapses.md

| Candidate | Chain | Live $ | Disposition | Note |
|---|---|---:|---|---|
| Stability | multi | — | **README-CLOSED** | Data/accounting artifacts; closed table |
| Republic Note | multi | — | **README-CLOSED** | Data/accounting artifacts; closed table |
| FluxBeam | multi | — | **README-CLOSED** | Data/accounting artifacts; closed table |
| 9mm V3 | multi | — | **README-CLOSED** | Data/accounting artifacts; closed table |
| LiquidLoans | Pulse | $1,634,818 | **OPEN** | NOT assessed (note-only); CDP, immutable, 0 audits; TVL $4.28M->$1.63M |
| Stream Finance | multi | — | **NOT-A-PROTOCOL** | Context (Silo bad-debt source) |

### dolomite-jupiter.md

| Candidate | Chain | Live $ | Disposition | Note |
|---|---|---:|---|---|
| Dolomite | ETH/ARB/BERA | — | **README-CLOSED** | De-dup + supplier rotation; closed table |
| Jupiter Lend DEX | Solana | — | **README-CLOSED** | sUSDai price-feed artifact; closed table |
| Concrete (WLFIcx) | Ethereum | — | **NOT-A-PROTOCOL** | Context (double-count removal) |

### incidents.md

| Candidate | Chain | Live $ | Disposition | Note |
|---|---|---:|---|---|
| UNCX VestingManager | ETH/BSC/Base/RH | — | **PRIOR-COVERED** | ZH3/prior; pass2 claim rejected ($0 live) |
| Argent-style modules | Ethereum | — | **README-CLOSED** | closed table |
| Pirate Chain (ARRR) | Pirate L1 | $19,600,000 | **README-FINDING** | P2-02; miner-only; kept pirate-chain/ |
| Cysic bridge | BSC | — | **LANE-CLOSED** | Halted; DB access; blacklist |
| Qubic | Qubic | — | **LANE-CLOSED** | Halted; conditional on restart |
| AlpsCon V9 | BSC | — | **README-CLOSED** | closed table |
| TIPMine / TIP | BSC | — | **LANE-CLOSED** | Drained; dust |
| EtherVista | Ethereum | — | **PRIOR-COVERED** | Excluded; monitor |
| Rujira FIN | THORChain | — | **README-CLOSED** | Tier3 #3; prior rujira-fin/ |
| KolanHook | Ethereum | — | **PRIOR-COVERED** | Drained; monitor |
| Bofur Capital | Ethereum | — | **NOT-A-PROTOCOL** | Phishing/key compromise |
| Private wallet compromise (ETH/BTC/SOL) | multi | — | **NOT-A-PROTOCOL** | Key compromise |
| sven.eth EIP-7702 drain | Ethereum | — | **NOT-A-PROTOCOL** | Single-wallet delegation drain |
| Ledger/CryptoBilis supply chain | multi | — | **NOT-A-PROTOCOL** | Hardware implant |
| Gamdom | multi | — | **NOT-A-PROTOCOL** | Hot-wallet key compromise |
| Autheo/THEO | Base | — | **PRIOR-COVERED** | pass-1 row |
| Hyperbridge | multi | — | **NOT-A-PROTOCOL** | Old incident republished |
| Volo Protocol | multi | — | **NOT-A-PROTOCOL** | Old incident republished |
| Venus/Thena | multi | — | **NOT-A-PROTOCOL** | Old incident republished |
| Upbit | multi | — | **NOT-A-PROTOCOL** | Old incident republished |

### launchpads.md

| Candidate | Chain | Live $ | Disposition | Note |
|---|---|---:|---|---|
| four.meme TokenManager3 | multi | — | **LANE-CLOSED** | Lane closed (signature/role/owner-gated) |
| four.meme RebateKeeper | multi | — | **LANE-CLOSED** | Lane closed (signature/role/owner-gated) |
| four.meme TokenManager | multi | — | **LANE-CLOSED** | Lane closed (signature/role/owner-gated) |
| four.meme TokenManagerBNW | multi | — | **LANE-CLOSED** | Lane closed (signature/role/owner-gated) |
| OpenFour FeeRouter | multi | — | **LANE-CLOSED** | Lane closed (signature/role/owner-gated) |
| OpenFour Registry/Core | multi | — | **LANE-CLOSED** | Lane closed (signature/role/owner-gated) |
| Flap Portal | multi | — | **LANE-CLOSED** | Lane closed (signature/role/owner-gated) |
| Flap SplitVault | multi | — | **LANE-CLOSED** | Lane closed (signature/role/owner-gated) |
| Flap tax-token Dividend | multi | — | **LANE-CLOSED** | Lane closed (signature/role/owner-gated) |
| Binance Wallet airdrop executor | multi | — | **LANE-CLOSED** | Lane closed (signature/role/owner-gated) |
| Clanker FeeLocker | multi | — | **LANE-CLOSED** | Lane closed (signature/role/owner-gated) |
| Clanker ClankerVault | multi | — | **LANE-CLOSED** | Lane closed (signature/role/owner-gated) |
| Flaunch ETH vault | multi | — | **LANE-CLOSED** | Lane closed (signature/role/owner-gated) |
| Umia CCA | multi | — | **LANE-CLOSED** | Lane closed (signature/role/owner-gated) |
| pump.fun + clones | multi | — | **LANE-CLOSED** | Lane closed (signature/role/owner-gated) |
| SunPump | multi | — | **LANE-CLOSED** | Lane closed (signature/role/owner-gated) |
| Bankr/Doppler | multi | — | **LANE-CLOSED** | Lane closed (signature/role/owner-gated) |
| Zora Coins | multi | — | **LANE-CLOSED** | Lane closed (signature/role/owner-gated) |
| DeepLock | multi | — | **LANE-CLOSED** | Lane closed (signature/role/owner-gated) |
| letsbonk/Believe/Moonit | multi | — | **LANE-CLOSED** | Lane closed (signature/role/owner-gated) |
| TON BigPump/memepad | multi | — | **LANE-CLOSED** | Lane closed (signature/role/owner-gated) |
| token bundler/sniper | multi | — | **LANE-CLOSED** | Lane closed (signature/role/owner-gated) |
| Genius.fun | BSC | — | **README-CLOSED** | Tier3 #6 |
| NOXA Fun fee lockers | multi | $3,900,000 | **README-CLOSED** | Tier3 #5; prior ZH4P2 ($0; principal locked) |
| Statics | Robinhood | — | **PRIOR-COVERED** | ZH4 fresh-perps cluster |
| four.meme TokenManager3 (custody) | BSC | $6,000,000 | **LANE-CLOSED** | $6M live; all admin/collect paths gated |

### live-disclosures.md

| Candidate | Chain | Live $ | Disposition | Note |
|---|---|---:|---|---|
| EIP-7702 sweeper fleet (CrimeEnjoyor) | Ethereum | $574,000 | **README-CLOSED** | closed table; 0 funded zero-auth delegations |
| Down To Finance / IndexedEx | Robinhood | — | **LANE-CLOSED** | Vaults undeployed; re-arm monitor |
| Lightning LDK / CLN downstream | Bitcoin Lightning | — | **LANE-CLOSED** | Upstream patched; no named live target |
| Cysic bridge | BSC | — | **LANE-CLOSED** | Halted |
| Rujira / THORChain v3.21 | THORChain | — | **README-CLOSED** | Tier3 #3 |
| Cosmos EVM third defect | Cosmos EVM | — | **NOT-A-PROTOCOL** | Disputed base-layer; not a contract path |
| Rabby Swap legacy contract | 19 chains | — | **OPEN** | Unquantified residual approvals; never patched; lane says likely <$1k -> verify |
| Olas POL LiquidityManager | ETH/Base/OP | — | **PRIOR-COVERED** | ZH4-04 |
| CapyFi | Ethereum | $5,100,000 | **PRIOR-PARTIAL** | ZH2 C2-13 (donation/inflation); NEW angle = Apr-2026 access-control bypass, $5.1M live cash -> worth a check |
| Limit Break / Magic Eden PaymentProcessor | multi | — | **PRIOR-COVERED** | ZH1 corpus; V3 usable to 2026-11-30 |
| Tether/THORChain freeze | THORChain | — | **NOT-A-PROTOCOL** | Compliance freeze |
| Base anonymous vault whitelist | Base | — | **NOT-A-PROTOCOL** | Privileged Safe whitelist |
| Mezo | Mezo | — | **PRIOR-COVERED** | ZH4 exotic/legacy |
| Marginal | multi | — | **PRIOR-COVERED** | ZH2/L2 |
| Lien Finance | multi | — | **PRIOR-COVERED** | Revoke.cash index; old/corpus |
| BarnBridge | multi | — | **PRIOR-COVERED** | Revoke.cash index; old/corpus |
| Ekubo | multi | — | **PRIOR-COVERED** | Revoke.cash index; old/corpus |
| Aperture | multi | — | **PRIOR-COVERED** | Revoke.cash index; old/corpus |
| SwapNet | multi | — | **PRIOR-COVERED** | Revoke.cash index; old/corpus |

### mini-chains.md

| Candidate | Chain | Live $ | Disposition | Note |
|---|---|---:|---|---|
| Plasma USD Vault (+ETH mirror) | Plasma/Ethereum | $32,830,000 | **README-CLOSED** | Tier3 #7; prior ZH4P2 ($699k = accounting artifact; solver-gated) |
| Katana Perps | Katana | $1,364,000 | **OPEN** | Unverified 24.5KB Exchange w/ obfuscated admin entrypoint; signature path not reversed |
| Tempo Stablecoin DEX | Tempo | $15,800,000 | **OPEN** | Enshrined Rust precompile; not fully fuzzed; fill_orders accounting unproven |
| R25 | Pharos | $164,400,000 | **LANE-CLOSED** | Manager-set NAV; 0 USDC held; role-gated updates |
| Gimo st0G | 0G | $4,390,000 | **PRIOR-COVERED** | ZH4P3 (byte-identical; E-U $0) |
| Ascend a0G | 0G | $3,410,000 | **LANE-CLOSED** | Mellow ERC-4626; role-gated |
| Zia (tradegpt) | 0G | $1,890,000 | **LANE-CLOSED** | UniV3 fork; unverified; no gate failure |
| Bond | 0G | $812,000 | **LANE-CLOSED** | UniV3 fork; owner EOA |
| FluxFlow V3 | Fluent | $810,000 | **LANE-CLOSED** | Only deviation = pre-set feeProtocol |
| Yuzu Money | Plasma | $66,300,000 | **LANE-CLOSED** | Deposits closed (ExceededMaxDeposit) |
| Ember Protocol | Pharos | $14,750,000 | **LANE-CLOSED** | USDC ERC-4626; API NAV; no donation path |
| Ploutos Money | Katana/Plasma | — | **LANE-CLOSED** | Insolvent; TVL 0 |
| BDEX V3 | BOT | $31,200,000 | **PRIOR-COVERED** | TIER3-LOW-TRACKER L2-23 |
| Kumbaya | MegaETH | $1,870,000 | **PRIOR-COVERED** | H2-02 |
| FaroSwap | Pharos | $1,280,000 | **PRIOR-COVERED** | ZH4 fresh-perps cluster |
| BitFi bfBTC | Pharos | $26,930,000 | **PRIOR-COVERED** | ZH4 fresh-perps cluster |
| Vena Finance | Fluent | $9,150,000 | **PRIOR-COVERED** | H2-05 |
| Tempo Morpho | Tempo | $190,000 | **LANE-CLOSED** | Morpho Blue canonical |
| Katana Morpho | Katana | $27,900,000 | **LANE-CLOSED** | Morpho Blue canonical |
| Nerona USDnr | Fluent | $1,180,000 | **LANE-CLOSED** | onlySwapFacility; totalAssets 0 |
| Upshift | multi | $8,800,000 | **OPEN** | Not assessed in depth; multi-chain curator; 2 audits |
| World Markets Spot | MegaETH | $664,000 | **OPEN** | Not assessed in depth; order-book DEX; 0 audits |
| Metric V1 | multi | $10,400,000 | **OPEN** | Not assessed in depth; Prop AMM DEX; 0 audits |
| Katana Vault Bridge | Katana | $27,700,000 | **PRIOR-COVERED** | ZH4 Wave B1 closed (LZ minter path closed) |
| Monad blue-chips (Aave/Euler/Morpho/Pendle/Curvance) | Monad | — | **PRIOR-COVERED** | Prior passes |
| Valos/Current/Neverland/Perpl | Monad | — | **PRIOR-COVERED** | Prior passes |
| Botanix | Botanix | — | **NOT-A-PROTOCOL** | Empty chain; RPC dead |

### monitor-diff.md

| Candidate | Chain | Live $ | Disposition | Note |
|---|---|---:|---|---|
| HAI | multi | — | **PRIOR-COVERED** | pass-1/ZH4 monitor; unchanged or downgraded |
| Olas POL | multi | — | **PRIOR-COVERED** | pass-1/ZH4 monitor; unchanged or downgraded |
| UNCX | multi | — | **PRIOR-COVERED** | pass-1/ZH4 monitor; unchanged or downgraded |
| Papertrade | multi | — | **PRIOR-COVERED** | pass-1/ZH4 monitor; unchanged or downgraded |
| EtherVista | multi | — | **PRIOR-COVERED** | pass-1/ZH4 monitor; unchanged or downgraded |
| Startale Earn | multi | — | **PRIOR-COVERED** | pass-1/ZH4 monitor; unchanged or downgraded |
| Shibarium WBONE | multi | — | **PRIOR-COVERED** | pass-1/ZH4 monitor; unchanged or downgraded |
| BeraFarm | multi | — | **PRIOR-COVERED** | pass-1/ZH4 monitor; unchanged or downgraded |
| Faiyah | multi | — | **PRIOR-COVERED** | pass-1/ZH4 monitor; unchanged or downgraded |
| Neverland | multi | — | **PRIOR-COVERED** | pass-1/ZH4 monitor; unchanged or downgraded |
| SatoHook | multi | — | **PRIOR-COVERED** | pass-1/ZH4 monitor; unchanged or downgraded |
| Jupiter Lend | multi | — | **PRIOR-COVERED** | pass-1/ZH4 monitor; unchanged or downgraded |
| Current | multi | — | **PRIOR-COVERED** | pass-1/ZH4 monitor; unchanged or downgraded |
| Kinetiq | multi | — | **PRIOR-COVERED** | pass-1/ZH4 monitor; unchanged or downgraded |
| Firelight | multi | — | **PRIOR-COVERED** | pass-1/ZH4 monitor; unchanged or downgraded |
| Hibachi | multi | — | **PRIOR-COVERED** | pass-1/ZH4 monitor; unchanged or downgraded |
| Decibel | multi | — | **PRIOR-COVERED** | pass-1/ZH4 monitor; unchanged or downgraded |
| Autheo | multi | — | **PRIOR-COVERED** | pass-1/ZH4 monitor; unchanged or downgraded |

### non-evm-incidents.md

| Candidate | Chain | Live $ | Disposition | Note |
|---|---|---:|---|---|
| Pirate Chain | Pirate L1 | $9,750,000 | **README-FINDING** | P2-02 |
| Qubic | Qubic | — | **LANE-CLOSED** | Halted; conditional on restart |
| Gamdom | multi | — | **NOT-A-PROTOCOL** | Hot-wallet key compromise |
| bOSMO / Backbone Labs | Osmosis | $965 | **README-CLOSED** | Tier3 #1; prior bosmo-backbone/ |
| Rujira FIN | THORChain | — | **README-CLOSED** | Tier3 #3; prior rujira-fin/ |
| Zano | Zano L1 | — | **LANE-CLOSED** | HF7 disabled gateway; rollback |
| XRPL (xrpld) | XRPL | — | **PRIOR-COVERED** | L1 tracker; patched |
| GoonFi V2 | Solana | — | **PRIOR-COVERED** | ZH3/ZH4P5; patched |
| TradeWiz | Solana | — | **NOT-A-PROTOCOL** | Private-key leak |
| Autheo/THEO | Base | — | **PRIOR-COVERED** | pass-1 |
| Cysic | BSC | — | **LANE-CLOSED** | Halted; out of lane |
| Ledger/CryptoBilis | multi | — | **NOT-A-PROTOCOL** | Hardware implant |
| Tectonic/Cronos | Cronos | — | **PRIOR-COVERED** | RESULTS-TRACKER |
| Neutron/Astroport/Drop | Neutron | — | **PRIOR-COVERED** | pass-1 corpus |
| Step Finance | Solana | — | **PRIOR-COVERED** | corpus |
| bLUNA / bJUNO / bKUJI (pfc_steak) | Terra/Juno | — | **LANE-CLOSED** | Different code hashes; no confirmed replay |
| BlueMove | multi | — | **PRIOR-COVERED** | pass-1/corpus |
| Scallop | multi | — | **PRIOR-COVERED** | pass-1/corpus |
| Typus | multi | — | **PRIOR-COVERED** | pass-1/corpus |
| Full Sail | multi | — | **PRIOR-COVERED** | pass-1/corpus |
| Virtue/IOTA | multi | — | **PRIOR-COVERED** | pass-1/corpus |
| TAC JettonProxy | multi | — | **PRIOR-COVERED** | pass-1/corpus |
| TONCO V2 | multi | — | **PRIOR-COVERED** | pass-1/corpus |
| USDD | multi | — | **PRIOR-COVERED** | pass-1/corpus |
| JustLend sTRX | multi | — | **PRIOR-COVERED** | pass-1/corpus |
| SecondFi | multi | — | **PRIOR-COVERED** | pass-1/corpus |
| Minswap | multi | — | **PRIOR-COVERED** | pass-1/corpus |
| NEAR Intents | multi | — | **PRIOR-COVERED** | pass-1/corpus |
| Nostra | multi | — | **PRIOR-COVERED** | pass-1/corpus |

### public-key-auth.md

| Candidate | Chain | Live $ | Disposition | Note |
|---|---|---:|---|---|
| AlpsCon AI Trade Hub | BSC | — | **README-CLOSED** | closed table |
| Kresko diamond + Vault (KISS) | Arbitrum | $4 | **README-CLOSED** | closed table (hh0 Redstone never consumed) |
| OpenAvatar / DAO4ART beta | Ethereum | — | **LANE-CLOSED** | Migrated; $0 |
| HunkyHeroes NFT | Ethereum | — | **LANE-CLOSED** | Supply 0 |
| D4A Diamond | Ethereum | — | **LANE-CLOSED** | Role revoked; $0 |
| Shiitake | Ethereum | — | **LANE-CLOSED** | $0 dormant/owner-gated |
| MondoTokens | Ethereum | — | **LANE-CLOSED** | $0 dormant/owner-gated |
| KKBB | Ethereum | — | **LANE-CLOSED** | $0 dormant/owner-gated |
| DinoBabies | Ethereum | — | **LANE-CLOSED** | $0 dormant/owner-gated |
| Distributor | Ethereum | — | **LANE-CLOSED** | $0 dormant/owner-gated |
| Century Secret Club | Ethereum | — | **LANE-CLOSED** | $0 dormant/owner-gated |
| ZDU | Avalanche | — | **LANE-CLOSED** | $0 / no price |
| MerkleRedeemer | Avalanche | — | **LANE-CLOSED** | $0 / no price |
| MoneyTree | Avalanche | — | **LANE-CLOSED** | $0 / no price |
| DeltaPrime | Avax/Arbitrum | — | **LANE-CLOSED** | Patched (threshold 3) |
| hh0 EIP-7702 delegation | Ethereum | — | **NOT-A-PROTOCOL** | Active executor; no value/auth grant |
| Kopio (Kresko fork) | Arbitrum | — | **LANE-CLOSED** | 0 hits |
| Remilia/Archetype | Ethereum | — | **LANE-CLOSED** | Commented constant only |
| EAS/attestation examples | multi | — | **NOT-A-PROTOCOL** | NatSpec only |

### secured-finance.md

| Candidate | Chain | Live $ | Disposition | Note |
|---|---|---:|---|---|
| Secured Finance (TokenVault ETH/FIL/ARB) | ETH/FIL/ARB | — | **README-CLOSED** | Closed table; Oct-15 build patched; PoC reverts |

### sibling-sweep.md

| Candidate | Chain | Live $ | Disposition | Note |
|---|---|---:|---|---|
| Secured Finance ETH | multi | — | **README-CLOSED** | Closed table |
| Secured Finance Filecoin | multi | — | **README-CLOSED** | Closed table |
| Secured Finance Arbitrum | multi | — | **README-CLOSED** | Closed table |
| Secured Finance Polygon zkEVM | multi | — | **README-CLOSED** | Closed table |
| Secured Finance Avalanche | multi | — | **README-CLOSED** | Closed table |
| Limit Break Payment Processor V2 | multi | — | **PRIOR-COVERED** | prior corpus |
| Set Protocol RebalancingSetTokenV3 | Ethereum | — | **PRIOR-COVERED** | ZH4P5; $0.11 profit |
| Cozy V2 | Ethereum | — | **PRIOR-COVERED** | ZH2B6 H2-03 |
| Unifi Protocol | multi | — | **PRIOR-COVERED** | TIER3-LOW-TRACKER |
| Zentra Finance | Citrea | $3,300 | **LANE-CLOSED** | <$10k; mostly drained |
| Reddio RedSonic | Reddio | — | **PRIOR-COVERED** | TIER3-LOW-TRACKER |
| DoinGud | Polygon | — | **LANE-CLOSED** | Empty |
| The Red Village | multi | — | **PRIOR-COVERED** | ZH3-H4 monitor |
| SpiralHookV2 | multi | — | **LANE-CLOSED** | Empty |
| PositionManager | multi | — | **PRIOR-COVERED** | L2/TIER3 |
| BitBay UsdcDaiV4Vault | multi | — | **PRIOR-COVERED** | ZH3-H7 monitor |
| Ethervista | Ethereum | — | **PRIOR-COVERED** | ZH3-C5 monitor |
| 79thVault | BSC | — | **LANE-CLOSED** | Role revoked; privileged |
| Adapter Vault Drain | Base | — | **LANE-CLOSED** | Owner/whitelist key |
| MALT | Ethereum | — | **PRIOR-COVERED** | ZH3 V2-malt |
| Notional V1 | Ethereum | — | **PRIOR-COVERED** | prior corpus |
| Flamincome | multi | — | **PRIOR-COVERED** | prior corpus |
| GoldPesa | multi | — | **PRIOR-COVERED** | ZH3-H5 monitor |
| Nimiq | Polygon | — | **PRIOR-COVERED** | ZH2B6; relayHub zeroed |
| FlashLoopAdapter | multi | — | **PRIOR-COVERED** | prior corpus |
| Ether.fi AtomicQueue | multi | — | **PRIOR-COVERED** | ZH1 C-07 monitor |
| PancakeV3SwapHelper | multi | — | **LANE-CLOSED** | Token-specific; dust/drained |
| LPBonus | multi | — | **LANE-CLOSED** | Token-specific; dust/drained |
| MUS | multi | — | **LANE-CLOSED** | Token-specific; dust/drained |
| ORB | multi | — | **LANE-CLOSED** | Token-specific; dust/drained |
| GDC | multi | — | **LANE-CLOSED** | Token-specific; dust/drained |
| DHC | multi | — | **LANE-CLOSED** | Token-specific; dust/drained |
| SKYDAO | multi | — | **LANE-CLOSED** | Token-specific; dust/drained |
| BeatXswap | multi | — | **LANE-CLOSED** | Token-specific; dust/drained |

---

## 5. What the README missed (the gap the principal flagged)

The pass2 README listed **2 findings + ~12 closed groups + 7 Tier-3 + 8 corrections**. The lanes named **269** protocol-level candidates. The material protocols that appear **only** in the lanes and were **never assigned** are the OPEN list above — chiefly:

- **Inverse Finance** and **Gitcoin** — the governance lane's own #2 and #3 pitches (both funded, both permissionless-proposal, both gated by a 2-party/veto guard). Radworks was elevated; these two were not assigned in any pass.
- **Metric V1, Tempo DEX, Upshift, Katana Perps, LiquidLoans, World Markets Spot, Rabby Swap legacy** — funded or residual, no verdict, no assignment.

Everything else that looked big in the lanes is dispositioned **README-CLOSED / LANE-CLOSED / PRIOR-COVERED** with a citation (e.g. Echo Bridge = privileged issuer burn; zkLink = legit exit; the −100% TVL names = data artifacts; launchpad custody = signature/role-gated; Secured Finance = patched; AlpsCon = gate removed; Katana Vault Bridge = ZH4 Wave B1 closed).

## 6. Prior-coverage sources used

- **Trackers:** `ci/ZH4P5`, `ZH4P4`, `ZH4P3`, `ZH4P2`, `ZH4` (pass1), `ZH3`, `ZH2B2..B7`, `L1`, `H`, `H2`, `RESULTS-TRACKER`, `TIER3-LOW-TRACKER`, `MONITOR-LIST`, `L2-*.json`.
- **Kept root folders:** `radworks/`, `pirate-chain/`, `bosmo-backbone/`, `rujira-fin/`, `uncx-vesting/`, `pharaoh-gauge/`, `bifi/`, `simpleaccount/`, `cooler-monocooler/`, `trueo/`, `affluent/` (removed as false positive), etc.
- **Mechanical:** `bash zombie-hunt-iv/zh4-check.sh "<name>"` for every fresh name.
- **Sibling recon folders:** `pass3-recon/`, `pass4-recon/`, `pass5-recon/`, `residual-recon/` (parallel; pass2 scope only here).

## 7. Caveats & limitations

- **Point-in-time:** live reads 2026-10-23. Inverse/Gitcoin guardian state, Metric/Tempo/Katana code, and LiquidLoans flows must be re-read before any action.
- **"No verdict anywhere"** is scoped to the campaign corpus (trackers + kept folders + `zh4-check.sh`). A verdict that exists only in an unreported session would not be visible here.
- **OPEN ≠ exploitable.** Each OPEN has a gate/blocker column; several (Tempo, World Markets, Upshift, Rabby) are below the practical bar and are listed for completeness. Inverse/Gitcoin are funded and permissionless-propose but **gated** — they are the highest-value unassigned candidates, not confirmed captures.
- Metrics/addresses/actors were dispositioned **NOT-A-PROTOCOL** and are not protocols; they are retained only so they are not re-investigated.
- No transactions were signed or sent; all addresses are public and read-only. No secrets are present in this folder.

## 8. CI

Custom read-only job (`ci/run.sh`) validates the candidate JSON, recomputes the disposition counts, and writes `ci-out/recon-summary.json`. Run via `bash /home/heisenberg/CA/ci/ci-run.sh pass2-recon`.

*Prepared 2026-10-23 · read-only research · evidence in `pass2-recon/analysis/`.*
