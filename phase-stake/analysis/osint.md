# Phase Stake (YIELD) — OSINT / Web Research

**Subject:** Phase Stake on Solana — LST ticker `YIELD`, mint `phaseZSfPxTDBpiVb96H4XFSD8xHeHxZre5HerehBJG`,
stake pool `phasejkG1akKgqkLvfWzWY17evnH6mSWznnUspmpyeG`, sibling product Phase Delegation (`pdSOL`).

**Research method:** public web sources, public JSON APIs (Jupiter, Raydium, DefiLlama, Sanctum),
GitHub public APIs, and read-only public Solana RPC calls. No transactions were signed or sent.
No API keys or keyed RPC endpoints are recorded in this file.

**All URLs accessed 2026-10-15 unless a different date is stated.** Source-side dates are quoted as
published.

**Parent-session context used as given (not re-derived here):** manager authority
`7LqSTwcwHodtrRmPWkptKWraELTW2DpchzRWhdoS4HH1`, staker `DxWfcgb2kENzzFy6ATP8KconVj6FriFU2GDnK1TmK6mK`,
`sol_withdraw_authority` `phaseUTHSD78uiD8rnRQWuvbEakvY1chNSeftkpvz6d` (described as on-curve).

---

## 1. Project identity: who runs YIELD/pdSOL, and is it the same as Base "phase.cash"?

### 1.1 The Solana operator is **Phase Labs** (phase.cc), not the Base CASH team

| Attribute | Value | Source |
|---|---|---|
| Trading name | "Phase" — *"Staking infrastructure on @solana and @monad. 1M+ SOL delegated across 100+ validators. Securing the infrastructure layer since 2021."* | https://x.com/phase_ (accessed 2026-10-15); 12,008 followers, verified |
| Website | https://phase.cc/ (live) — *"Securing the infrastructure layer since 2021."* | https://phase.cc/ |
| Former domain | `phaselabs.io` **permanently redirects** to `phase.cc` | https://www.phaselabs.io/ → `https://www.phase.cc/` (HTTP redirect observed 2026-10-15); https://solanacompass.com/projects/phase-labs |
| Docs | https://phase-labs.gitbook.io/phase-labs (GitBook) and a Ghost blog at https://phase-1.ghost.io | both live 2026-10-15 |
| GitHub org | https://github.com/phaselabscrypto — bio *"Validators. Stake pools. Solana infrastructure since 2021."*, org created **2021-12-23**, `twitter_username: phase_`, blog `https://phase.cc/` | GitHub API `orgs/phaselabscrypto` |
| X (project) | https://x.com/phase_ | |
| LinkedIn | https://www.linkedin.com/company/phase-cc | |
| YouTube | https://www.youtube.com/@Phase_Media | linked from phase.cc |

**Named team** (phase.cc homepage, accessed 2026-10-15; repeated by Solana Compass):

- **Brandon Geraldi** — CEO (@DEVOUR_ on X); LinkedIn: *"As CEO and Founder of Phase Labs, I lead a team building high-integrity blockchain infrastructure and financial tools starting with Solana."* (https://www.linkedin.com/in/brandon-geraldi)
- **Adam Carter** — CTO (@hash_on_hash)
- **Dan Trilo** — CFO (@dantrilosol)
- **Jeff Newman** — CPO (@mynameisjeff_kb)
- **Gabriel Hicks** — Head of Staking (@gabrieldotsol)
- **Tyler Gotto** — Head of Marketing (@gotto_) — bylines on the 2026 blog posts
- **Nathan Anderson** — Operations Engineer (@Pixel_Shancus); **Dharmin Mehta** — Video Editor (@TheMogulSoul)

**Products claimed:** Phase Stake (validator + `$YIELD` LST), Phase Delegation (`pdSOL`, formerly "Aero Pool"),
Sentinel Stake (institutional, claimed ~$30M AUM), Netrunner (netrunner.tax), Align (hackathon/governance
platform), Ideapad (crowdfunding), branded white-label validators, custom LSTs. Roadmap mentions
**Monad** and **Polygon** in addition to Solana (phase.cc/stake; https://phase-labs.gitbook.io/phase-labs;
https://solanacompass.com/projects/phase-labs).

### 1.2 phase.cash / CASH / @0xPhase is a *different* project (high confidence)

| Attribute | Value | Source |
|---|---|---|
| Product | "Phase Cash" — CASH stablecoin, CDP/borrow-against-yield-collateral, on Base/Ethereum L2s | https://phase.cash/, https://docs.phase.cash/protocol/what-is-phase.md |
| Social | `twitter.com/0xPhase` (+ a Discord invite) — **no mention of Solana, YIELD or pdSOL anywhere on the site or docs** | https://phase.cash/ (Firecrawl render, 2026-10-15) |
| Docs freshness | docs.phase.cash footer: **"Last updated 3 years ago"** (~2023) | https://docs.phase.cash/protocol/what-is-phase.md |
| DefiLlama TVL | Base TVL **$89.98** (current), down from a ~$10K peak in late 2023; first data point 2023-10-23 | https://api.llama.fi/protocol/phase |
| DefiLlama audits | 2 Omniscia reports (https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b, https://omniscia.io/reports/0xphase-balancer-implementation-645cb15ec7eedb00140139f7) | https://api.llama.fi/protocol/phase |
| GitHub | `github.com/0xphase` — org **404 Not Found**; a user account `0xphase` exists but returned no usable profile data | GitHub API, 2026-10-15 |
| X handle today | https://x.com/0xPhase renders as a near-empty, **unverified account with 0 followers**, bio *"Believing in @Polymarket"*, last post 2025-10-31 — i.e. the original project handle appears lost/repurposed | Firecrawl render of https://x.com/0xPhase, 2026-10-15 |

**Findings:**
- I found **no primary-source link** (no shared team member, domain, GitHub org, social cross-post, or
  partner list overlap) between phase.cash/@0xPhase (Base CASH) and phase.cc/@phase_ (Solana Phase Labs).
  Different websites, different X handles, different GitHub orgs, different chains, different product types.
- The only thing tying them together is **DefiLlama metadata**: DefiLlama lists the Solana protocols with
  `parentProtocol: "parent#phase"`, and the parent record `phase` is the **Base CASH** protocol
  (`address: base:0xbe92452bb46485AF3308e6d77786bFBE3557808d`, `twitter: 0xPhase`, `url: https://phase.cash`).
  Both Solana children carry `twitter: phase_` and an **empty `url` with `deadUrl: true`**
  (https://api.llama.fi/protocol/phase-stake, https://api.llama.fi/protocol/phase-delegation).
- **Conclusion:** treat DefiLlama's parent grouping as a likely metadata error. The evidence indicates
  **Phase Stake / Phase Delegation are operated by Phase Labs (Solana, since 2021) and are unrelated to the
  Base CASH protocol**, which is separately dormant/abandoned (see §6). Confidence: medium-high — the absence
  of a link is strong, but a shared-ownership arrangement could exist without public disclosure.

**Also note — name collisions that will contaminate any search for "Phase Labs":**
- Ensemble VC's portfolio page "Phase Labs" is a **biotech** company ("organs repaired… limbs regrown", team
  from Neuralink/Moderna/Caltech): https://www.ensemble.vc/company/phase-labs — **not** the Solana team.
- A Crunchbase "Phase Labs — Pre Seed Round" exists (https://www.crunchbase.com/funding_round/phase-labs-856e-pre-seed--0a5a6519)
  but I could **not** verify which company it refers to. Do not attribute it to the Solana entity without proof.

---

## 2. Launch / lifecycle dates

| Date | Event | Source |
|---|---|---|
| 2021-01 | Phase Labs founded ("Founded Jan 2021", "operating since 2021") | https://solanacompass.com/projects/phase-labs ; https://phase.cc/ |
| 2021-12-23 | `phaselabscrypto` GitHub org created | GitHub API |
| **2024-04-18** | Commit *"Add phaseSOL to SanctumSplMulti list."* in Sanctum's LST list repo; merged **2024-04-24** via *"Merge pull request #62 from phaselabscrypto/master"* — i.e. **the Phase team itself submitted the Sanctum integration PR** | GitHub commit search on `repo:igneous-labs/sanctum-lst-list` (phaseSOL / aeroSOL) |
| ~2024-05-05 | Raydium CLMM WSOL/YIELD pool `openTime` = 1714936208 (≈2024-05-05/06) | https://api-v3.raydium.io/pools/info/ids?ids=AgPrbsenuRx4ad3FRwVaqjJw7RufrW1puuiTGaEisdZY |
| **2024-05-28** | YIELD stake pool `phasejkG1…` first seen by Jupiter (`firstPool.createdAt`) | https://lite-api.jup.ag/tokens/v2/search?query=phaseZSfPxTDBpiVb96H4XFSD8xHeHxZre5HerehBJG |
| 2024-06-07 | Jupiter token record `createdAt` for the YIELD mint (first priced) | Jupiter `tokens/v2`, `price/v3` |
| 2024-06-09 | pdSOL stake pool `aero2ePUR…` first seen by Jupiter | https://lite-api.jup.ag/tokens/v2/search?query=aeroXvCT6tjGVNyTvZy86tFDwE4sYsKCh7FbNDcrcxF |
| 2024-07-05 / 2024-07-30 | Commits *"add aeroSOL to sanctum-lst-list.toml"* / *"feat: add uptSOL and aeroSOL"*; Jupiter pdSOL token `createdAt` = 2024-07-30 | GitHub commit search; Jupiter |
| 2024-09-10 (per indexed snippet) | @PhaseDelegation post: *"Introducing Aero—a stake pool designed to empower and uplift Solana ecosystem contributors."* | https://x.com/PhaseDelegation (indexed excerpt) |
| 2025-05 | Phase Labs representatives met the SEC Crypto Task Force re: Solana ETP staking standards | https://solanacompass.com/projects/phase-labs |
| 2026-04-22 | Phase blog *"YIELD vs pdSOL"* — "One pdSOL currently represents 1.12749 SOL", "1M+ SOL staked" | https://phase-1.ghost.io/yield-vs-pdsol/ |
| ~2026-08-27 | DefiLlama first TVL point for both Solana protocols (`listedAt` 1787872301 / 1787857417) | llama API |
| 2026-09-28 | Phase blog *"Solana Liquid Staking with YIELD and DiversiFi"* — YIELD shipped into the dSTAKE vault | https://phase-1.ghost.io/dstake-yield-diversifi/ |
| 2026-10-14 | Latest @phase_ posts (Solana stake stats); latest DefiLlama TVL point | https://x.com/phase_ ; llama API |

**Naming note:** the Sanctum list entry for the YIELD mint is `name = "Phase Labs SOL"`, `symbol = "phaseSOL"`
(program `SanctumSplMulti`), while Jupiter/Raydium call the same mint `YIELD`/`Yield`. Solana Compass confirms
YIELD was *"previously referred to as phaseSOL"* (https://solanacompass.com/projects/phase-labs). Likewise the
pdSOL mint `aeroXvCT6…` is still `name = "aeroSOL"` in the Sanctum list. **These are rebrands, not separate tokens.**

---

## 3. YIELD token markets & price (is it traded anywhere?)

### 3.1 On-chain identity checks performed (read-only public RPC, 2026-10-15)

- `getAccountInfo(phasejkG1akKgqkLvfWzWY17evnH6mSWznnUspmpyeG)` → **exists**, `owner = SPMBzsVUuoHA4Jm6KunbsotaahvVikZs1JyTW6iJvbn`, space 611 bytes. Confirms the pool is owned by the Sanctum
  multi-validator SPL stake pool program.
- Jupiter's YIELD swap route `ammKey` `BanCwefGRK7DtAieu4qKziBn3B9JvtzDdfX3qWP8SLAJ` → exists, `space` 225,
  owned by program **`2rU1oCHtQ7WJUvy15tKtFvxdYNNSc3id7AzUcjeFSddo`** (not `SPMBzs…`) — consistent with a
  Sanctum vault/reserve-style unstake account rather than an AMM pool.

### 3.2 Cross-source YIELD price / NAV table (all 2026-10-15 unless noted)

| Source | Metric | Value |
|---|---|---|
| Jupiter Price v3 | `usdPrice` | **$121.7438** (SOL mark on same call: $101.1785 → implies ≈1.194 SOL) |
| Jupiter Price v3 | `liquidity` | **$3,058,640.84** (`fdv` = `mcap` = `liquidity` — i.e. a NAV × supply figure, not order-book depth) |
| Jupiter Price v3 | `priceChange24h` | **−4.99%** |
| Jupiter v1 Quote | 1 YIELD → SOL | **1.192759647 SOL**, `priceImpactPct` 0.0089% |
| Jupiter v1 Quote | 1 SOL → YIELD | **0.837729228 YIELD** (⇒ ≈1.1937 SOL per YIELD) |
| Jupiter v1 Quote | route | **100% `VaultLiquidUnstake`** (single hop) — *no AMM hop at all* |
| Solana Compass (pool page) | "Pool Token Value" | **1.194 SOL** |
| Solana Compass (pool page) | Current APY (10-epoch realised) | **5.45%** |
| Sanctum `extra-api` | `solValue` (per LST) | **1.15756606 SOL** ⚠ differs from NAV by ≈−3.1% |
| Sanctum `extra-api` | `apy/latest` | **0.0** ⚠ |
| phase.cc/stake UI | "1 $YIELD = … SOL" (server-rendered) | **1.121 SOL** ⚠ likely stale/fallback |
| DefiLlama (implied) | $3,048,433 ÷ 25,123.58 supply ÷ $101.18 SOL | ≈**1.199 SOL** |

⚠ **Unresolved price/NAV discrepancy — flag for on-chain reconciliation.** Five different numbers
(1.121 / 1.1576 / 1.1928 / 1.194 / ~1.199) are in circulation. Jupiter's *executable* quotes and
Solana Compass's pool page agree at ≈1.193–1.194, which is also what the parent session used (1.1942).
Sanctum's `sol-value` API (1.1576) and the phase.cc front-end default (1.121) do **not** agree and should be
explained by whoever reads the pool account directly. The redemption route is a single non-AMM
"VaultLiquidUnstake" hop, so a haircut/fee convention inside that path is one plausible cause.

### 3.3 Is YIELD traded anywhere? — **Effectively no. It is a redemption-only instrument.**

- **Raydium: exactly one YIELD pool exists, and it is empty.** Query returns a single CLMM pool
  `AgPrbsenuRx4ad3FRwVaqjJw7RufrW1puuiTGaEisdZY` (WSOL/YIELD, program `CAMMCzo5YL8w4VFF8KVHrK22GGUsp5VTaW7grrKgrWqK`)
  with **`tvl: 0`**, `price: 0.9981218072460164` (a stale 2024 quote), `mintAmountA: 0`, `mintAmountB: 0`,
  and **zero volume** for day/week/month. Source: https://api-v3.raydium.io/pools/info/mint?mint1=phaseZSfPxTDBpiVb96H4XFSD8xHeHxZre5HerehBJG&poolType=all&poolSortField=default&sortType=desc&pageSize=100&page=1
- **Meteora:** no pair returned for the YIELD mint (https://dlmm-api.meteora.ag/pair/search?query=phaseZ… → 404).
- **Jupiter liquidity semantics:** Jupiter's `$3.06M` "liquidity" equals `fdv` and `mcap` exactly, and matches
  the DefiLlama TVL — it is derived from the stake pool's backing, **not** from AMM depth.
- **Actual trading is negligible.** Jupiter `stats24h` for YIELD: **buy volume $99.65, sell volume $2,699.09,
  1 buy / 4 sells, 4 traders, net buyers 1**; `stats6h.volumeChange = −100%` (no trades in the last 6 hours).
  `organicScore: 0`, label `"low"`.
- **How redemptions actually route:** 100% via Jupiter's `VaultLiquidUnstake` (Sanctum unstake liquidity), at
  ~0.1% round-trip cost. So exits depend on Sanctum's unstake path, not on any DEX market maker.

**Related pdSOL market (for contrast), 2026-10-15:** mint `aeroXvCT6tjGVNyTvZy86tFDwE4sYsKCh7FbNDcrcxF`;
Jupiter `usdPrice` $118.0793, `liquidity` $112.46M (= NAV × supply), circSupply **952,415.11**, holders **241**,
24h buy volume **$0.006**, sell volume **$637.31** (2 buys / 1 sell). Sanctum `sol-value` = **1.130343380 SOL**;
Sanctum APY = **0.0** ⚠. Both Jupiter and Sanctum report an **empty/zero APY object** for BOTH YIELD and pdSOL,
which is unusual for live LSTs and is the single most interesting data-quality signal in this section.

### 3.4 Supply / holder / authority fields (Jupiter `tokens/v2`, 2026-10-15)

**YIELD** (`phaseZSfPxTDBpiVb96H4XFSD8xHeHxZre5HerehBJG`):

```
name "yield"  symbol YIELD  decimals 9
circSupply = totalSupply = 25,123.58113563     holderCount 1503
dev            = phaseGat2zkWtpMPbjPJWWj2EVN4tFR1HN4EqtwUzit
mintAuthority  = 9HYjrCF5evTobLmay372kpUWSNTrtmDU2NkQtqjdnHKa   (non-null!)
freezeAuthorityDisabled = true      devMints = 1
topHoldersPercentage = 98.894%      organicScore 0 ("low")   apy {} (empty)
isVerified = true   tags = ["lst","original-lst","verified","yield"]
firstPool = { id: phasejkG1akKgqkLvfWzWY17evnH6mSWznnUspmpyeG, createdAt 2024-05-28T07:23:37Z }
```

**pdSOL** (`aeroXvCT6tjGVNyTvZy86tFDwE4sYsKCh7FbNDcrcxF`): name "Phase Delegation Staked SOL", circSupply
952,415.109886, holderCount 241, `dev = aerorbeRSPU57GtKccocmjCbABfMQv5GcsXDy87LbMN`,
`mintAuthority = AKJt3m2xJ6ANda9adBGqb5BMrheKJSwxyCfYkLuZNmjn`, `freezeAuthorityDisabled = true`,
`topHoldersPercentage = 99.99987%`, `apy {}`.

Both mints have vanity-prefixed `dev`/operator addresses (`phaseGat…`, `aerorbe…`) and a non-null
`mintAuthority`. Read-only RPC `getAccountInfo` on both mint authorities (and on `phaseGat…`) shows
**System-owned, zero-data accounts holding small round SOL balances** (YIELD mint authority exactly
0.1 SOL; pdSOL mint authority ≈1.000028 SOL; `phaseGat…` ≈0.98 SOL). Whether the two mint authorities are
on-curve keypairs or program PDAs cannot be decided from `getAccountInfo` alone — **needs a curve check**
(the parent session already established that `sol_withdraw_authority phaseUTHSD…` *is* on-curve, which makes
the mint-authority question worth resolving explicitly).

### 3.5 Sanctum integration & Sanctum Infinity membership — **YIELD is in Infinity, but with ~20 tokens**

- **Sanctum LST list (repo `igneous-labs/sanctum-lst-list`), YIELD entry:**

```toml
mint = "phaseZSfPxTDBpiVb96H4XFSD8xHeHxZre5HerehBJG"
name = "Phase Labs SOL"   symbol = "phaseSOL"   decimals = 9
[sanctum_lst_list.pool]
program = "SanctumSplMulti"
pool = "phasejkG1akKgqkLvfWzWY17evnH6mSWznnUspmpyeG"
validator_list = "phaseeExd43yGjjad2FZSigdG9UTRpMdxS4aMerx821"
logo_uri = ".../phaselabscrypto/.github/main/profile/public/phaseSOL.png"
```

  (https://raw.githubusercontent.com/igneous-labs/sanctum-lst-list/master/sanctum-lst-list.toml) — note the
  logo is hosted in Phase's own `phaselabscrypto` org, and the pdSOL entry is `program = "Spl"`,
  `pool = aero2ePUR…`, `validator_list = aero4efZ7zHhWpqXQj4Uqw59koxj8KXqMCPUuvmhgUQ`.
- **This repo is now ARCHIVED** (`archived: true`, last push 2025-11-23, final commit message literally
  "archive") with README: *"ARCHIVE NOTICE — This repo is no longer in use. Sanctum LST metadata is now served
  from a live DB via our API at https://sanctum-api.ironforge.network."* So a stale `sanctum-lst-list` clone is
  **not** evidence of current listing; the live DB requires an API key I do not have.
- **Sanctum Infinity membership: YES, but residual.** The Infinity reserve account
  `AYhux5gJzCoeoc1PoJ1VxwPDe22RwcvpHviLDD1oCGvW` (documented reserves account for Infinity,
  https://learn.sanctum.so/docs/technical-documentation/infinity.md) holds a YIELD ATA
  `7LBYo6EGpeBkuuUGY9E57Ueai9HCkeZdVkEYLKvNkich` containing **20.151534751 YIELD** (checked by read-only
  `getTokenAccountsByOwner`, 2026-10-15). So YIELD has an initialised Infinity reserve slot but only ~$24 of
  liquidity in it. (Also note Sanctum's own docs say *"Infinity support... is not provided by default"* for
  new LSTs: https://learn.sanctum.so/docs/creating-your-own-lst-with-sanctum/the-setup-process-launching-your-lst/a-few-things-you-should-know-about.md)
- Sanctum's LST-list docs also note the **delegation crank only supports single-validator delegation for now**
  (same URL) — relevant because Solana Compass reports the Phase Stake pool currently stakes to
  **1 validator** (epoch 1058), despite a `SanctumSplMulti` program/validator-list setup.

### 3.6 DefiLlama listing

| | Phase Stake | Phase Delegation |
|---|---|---|
| DefiLlama id | 8527 | 8520 |
| Category | Liquid Staking (Solana) | Liquid Staking (Solana) |
| `audits` field | **"0"** | **"0"** |
| Latest TVL (2026-10-14) | **$3,048,433** (≈30,129 SOL @ $101.18) | **$111,880,837** (≈1,105,750 SOL) |
| Oldest point in series | 2026-08-26 | 2026-08-26 |
| `listedAt` | ≈2026-08-27 | ≈2026-08-27 |
| `url` / `deadUrl` | empty / **true** | empty / **true** |
| `parentProtocol` | `parent#phase` (the Base CASH protocol) | `parent#phase` |
| Adapter | `registries/solanaStakePool.js` → `phase-yield: { solana: 'phasejkG1…' }` | same file → `phase-delegation: { solana: 'aero2ePUR…' }` |

Sources: https://api.llama.fi/protocol/phase-stake, https://api.llama.fi/protocol/phase-delegation,
https://raw.githubusercontent.com/DefiLlama/DefiLlama-Adapters/main/registries/solanaStakePool.js
(definitive rows confirmed). Note the llama API's `module` fields (`phase-yield/index.js`,
`phase-delegation/index.js`) **do not exist** in the adapters repo (commit-history query returns empty) — the
real adapter is the registry file above, so the `module` field is misleading metadata.

**Corroborating third-party figures:** Solana Compass pool page (https://solanacompass.com/stake-pools/phasejkG1akKgqkLvfWzWY17evnH6mSWznnUspmpyeG):
*Total SOL Staked 30,002.2 · Staked Validators 1 (epoch 1058) · Pool Token Supply 25,123.58 · Pool Token Value
1.194 SOL · Current APY 5.45%*. For pdSOL, https://solanacompass.com/stake-pools reports 1,101,114 SOL / 4.62%,
and a StakeScope listing shows $125.83M.

⚠ **One secondary source is internally wrong and should not be used:** the Solana Compass *project profile*
states YIELD *"as of mid-2026 the token has a market cap of approximately $889K with around 10,000 tokens in
circulation"* (https://solanacompass.com/projects/phase-labs). That contradicts Jupiter (25,123.58 supply,
$3.06M) **and** Solana Compass's own stake-pool page (25,123.58 supply, 30,002 SOL). Treat the project-profile
figure as stale/erroneous.

---

## 4. Audits, incidents, post-mortems, security advisories

### 4.1 Phase / YIELD / pdSOL specifically — **nothing found**

- **DefiLlama's hack database (1,302 records) contains no entry matching "phase" or "sanctum".**
  Source: https://api.llama.fi/hacks (filtered, 2026-10-15).
- DefiLlama's `audits` field is **"0"** for both Phase Stake and Phase Delegation.
- No audit, post-mortem, exploit report, or security advisory naming Phase Labs / YIELD / pdSOL / phaseSOL was
  found in web search. The only "audit" results that surfaced for Phase were the **Base CASH** protocol's two
  Omniscia reports (different project — see §1.2).
- The Solana Compass project profile (which is reasonably detailed on this team) lists no audits and the
  SolanaQubits governance tracker separately notes no public governance/treasury. Absence of evidence, not
  evidence of absence — but there is **no published third-party security review** of Phase's own setup.

### 4.2 The Sanctum `SPMBzs…` program (the code YIELD's SOL sits in)

- Sanctum's LSTs are described as a **fork of Solana Labs' stake pool program at the `program@v1.0.0` tag**
  (https://learn.sanctum.so/docs/technical-documentation/sanctum-lsts). Audit list given there (all of the
  *upstream* SPL stake pool program):
  - Halborn (2023-12-31), Kudelski (2021-07-07), OtterSec (2023-01-20), Neodyme (2022-12-10),
    Quantstamp (2021-10-22) — linked from
    https://github.com/solana-labs/security-audits/tree/master/spl
  - Sanctum's own materials claim nine audits of the stake pool program
    (https://discuss.jup.ag/t/sanctum-lfg-building-the-infinite-lst-future/5339).
- **Sanctum program upgrade authority: an 11-member multisig including Jupiter, Jito, Sol Strategies, Solblaze
  and Sanctum; "no single party can unilaterally change the program"**
  (https://learn.sanctum.so/docs/technical-documentation/sanctum-lsts#safety). An older Jupiter Research post
  describes it as a 9-member multisig. **Management authority** (day-to-day LST setup/staking) is held by
  Sanctum and, per those docs, *"cannot steal your funds, even if compromised"* but **can raise fees**
  (subject to caps/notice).
- **Generic, not Phase-specific:** a "semantic inconsistency" vulnerability found in the official stake-pool
  program (reported by both Soteria and sec3, since patched) — surfaced by search only; I did not review the
  reports in depth and they predate any Phase integration:
  https://medium.com/coinmonks/solana-stake-pool-a-semantic-inconsistency-vulnerability-discovered-by-soteria-b92abcbaf909 ,
  https://sec3.dev/blog/solana-stake-pool-a-semantic-inconsistency-vulnerability-discovered-by-x-ray
- **Sanctum appears alive and shipping as of Oct 2026** (`igneous-labs/inf-1.5` pushed 2026-10-01,
  `sanctum-router-sdk` 2026-06-20, docs live) — so the archived LST-list repo is a documentation migration
  (`sanctum-api.ironforge.network` DB), not a shutdown signal.

---

## 5. Deprecation / sunset / withdrawal issues / migration signals

**No evidence that YIELD is deprecated, sunset, paused or in migration. Evidence of active promotion:**

- `phase.cc/stake` is a **live staking UI** with $YIELD in/out flows, "1 $YIELD = 1.121 SOL", 0.5–3.0% slippage
  and priority-fee options, "Trusted since 2021. 99.9% uptime." (accessed 2026-10-15).
- Phase blog **2026-09-28**: *"Solana Liquid Staking with YIELD and DiversiFi"* — YIELD integrated into the
  **dSTAKE vault (80% YIELD / 20% USDT)** on DiversiFi, deposits in USDC, vault
  `DmS33WpmsLkHQaqZxpWqQM7rPtta2E8V1JkSaXRL1f3h`. YIELD is described as "revenue-boosted" — native staking
  rewards **plus a share of Phase's business revenue** routed to holders.
  Source: https://phase-1.ghost.io/dstake-yield-diversifi/ (published 28 Sep 2026).
- Phase blog **2026-04-22**: YIELD positioned as the high-return product (0% commission, above-market APY)
  vs pdSOL for network impact. Source: https://phase-1.ghost.io/yield-vs-pdsol/
- @phase_ is **posting daily** (latest 2026-10-14), verified, 12,008 followers, still marketing pdSOL
  ("Hold $pdSOL and support all of them while you earn").
- Jupiter quotes, prices and the Sanctum `extra-api` all resolve YIELD/phaseSOL live on 2026-10-15.

**Adjacent "deprecation" signals that DO exist, and their scope:**

1. **A social channel was retired:** https://x.com/PhaseDelegation renders as *"Phase Delegation socials have
   been transferred to the @phase_ page"* (3,157 followers, unverified, no recent top-level posts). That is a
   **channel consolidation**, not a product sunset.
2. **The Base CASH protocol (a different project) is effectively dead:** DefiLlama Base TVL **$89.98**, docs
   "last updated 3 years ago", `@0xPhase` handle now unverified/repurposed. Do not confuse this with YIELD.
3. No redemption pause, withdrawal freeze, migration notice, or depeg warning was found for YIELD or pdSOL.
   Note that the only material "exit risk" observable is structural rather than announced: **there is no AMM
   liquidity** (Raydium pool tvl 0; Meteora none) and exits route 100% through Sanctum's `VaultLiquidUnstake`.

---

## 6. Governance & authority information

- **No public DAO / no protocol token governance.** SolanaQubits' stake-pool governance tracker records Phase
  under "No public DAO found" / *"Public token governance: Not confirmed"*: *"Phase exposes staking tokens and a
  bonded validator intake, but no public token-voting DAO, proposal portal, or DAO treasury was verified."*
  Its participation path is *"the Phase validator application and refundable Phase Bond, not governance
  voting"*; record verified **2026-08-15**. Source:
  https://solanaqubits.com/resources/solana-stake-pool-dao-governance/
  (Same page notes JPool uses a *"Squads 2-of-3 multisig"* for administration — phrasing that shows the author
  does distinguish multisig-controlled projects; it says no such mechanism for Phase.)
- **No public disclosure found** of who holds the stake pool's `manager` / `staker` /
  `sol_withdraw_authority` keys for `phasejkG1…`. Neither phase.cc, the GitBook, the Ghost blog, nor the
  SolanaQubits tracker names them. The task's `sol_withdraw_authority` being an **on-curve** account
  (`phaseUTHSD78uiD8rnRQWuvbEakvY1chNSeftkpvz6d`) is, from an OSINT standpoint, **unattested risky practice**
  relative to peers: there is no published claim of a Squads/realms multisig gating it.
- **Weak, indirect evidence of Squads usage by the team (not proof for these authorities):** the
  `phaselabscrypto` org maintains a repo `squads-export` — *"Export your multisig transactions with
  descriptions to json"* (pushed 2026-08-07). That shows familiarity with Squads multisigs somewhere in their
  tooling; it does **not** establish that pool authorities are multisig-controlled.
- **Program-level authority (the code, not the pool):** Sanctum's stake-pool program upgrade authority is an
  11-member multisig (Jupiter, Jito, Sol Strategies, Solblaze, Sanctum) per
  https://learn.sanctum.so/docs/technical-documentation/sanctum-lsts#safety — this constrains the *program*,
  not Phase's pool parameters.
- **Sanctum management authority can raise fees** (capped, with notice) and cannot steal funds (same URL).

---

## 7. Team track record & funding

**Track record (credible, multi-year, verifiable):**

- Operating Solana validators **since 2021** (~5 years by 2026): phase.cc, GitHub org (2021-12-23), LinkedIn.
- **@phase_ bio: "1M+ SOL delegated across 100+ validators"** (2026-10-15) — consistent with DefiLlama's
  Phase Delegation TVL of ~1.1M SOL, and with "170+ validators" for Aero/Phase Delegation from Solana Compass.
- **Ecosystem work:** hosted the **Bonkathon** hackathon on *Align by Phase Labs* (Bonk DAO + Radiants),
  ~$300–350K in prizes, cited in Messari's *State of Solana Q2 2024*
  (https://messari.io/report/state-of-solana-q2-2024) and 4Pillars
  (https://research.4pillars.io/en/research/solana-mega-report-like-apple-but-unlike-apple-v2).
- **Solana Mobile validator collaboration** with the Solana Foundation + Phase Labs (Altcoin Buzz archive).
- **Regulatory engagement:** May 2025 meeting with the SEC Crypto Task Force on Solana ETP staking, stake
  centralisation (Nakamoto coefficient 19), SOC 2 / ISO 27001 baselines.
- **Other shipped products:** Netrunner (netrunner.tax), Align, Ideapad, Sentinel Stake (claimed ~$30M AUM),
  white-label validators, custom LSTs. Multi-chain ambitions (Monad, Polygon) supported by
  `phaselabscrypto/validator-info-monad` (pushed 2026-04-02).
- Claimed **SOC 2 Type II certified** institutional infrastructure and 99.9% uptime SLA (phase.cc/stake).
- Social reach is modest: @phase_ 12,008 followers (verified); LinkedIn `phase-cc` 388 followers.

**Funding: NOT ESTABLISHED — and actively contaminated by name collisions.**

- I found **no funding announcement, round, lead investor, or valuation** attributable to the Solana Phase
  Labs.
- Two traps: (a) Ensemble VC's "Phase Labs" portfolio entry is a **biotech** company
  (https://www.ensemble.vc/company/phase-labs); (b) a Crunchbase "Phase Labs Pre Seed Round" page exists
  (https://www.crunchbase.com/funding_round/phase-labs-856e-pre-seed--0a5a6519) but its company could not be
  confirmed as the Solana entity. **Neither should be cited as Phase Labs (Solana) funding.**

---

## 8. Unknowns / confidence

**High confidence**
- Phase Stake (YIELD) and Phase Delegation (pdSOL) are operated by **Phase Labs** (phase.cc, `phaselabscrypto`,
  `@phase_`), a Solana infrastructure company operating since 2021, now with a named 8-person team and a live
  product suite.
- The `phasejkG1…` pool is owned by **`SPMBzsVUuoHA4Jm6KunbsotaahvVikZs1JyTW6iJvbn`** (verified on-chain);
  YIELD's mint was registered to Sanctum's LST list by the Phase team in **April 2024** and pdSOL's in
  **July 2024**.
- **YIELD has no meaningful secondary market**: one Raydium CLMM pool with **tvl 0 / zero volume**, no Meteora
  pair, no Sanctum Infinity depth (~20 YIELD), and Jupiter routes 100% through `VaultLiquidUnstake`. Daily DEX turnover is
  in the low thousands of dollars (24h: 1 buy, 4 sells).
- **No Phase/YIELD/pdSOL exploit, incident, audit, or security advisory is publicly recorded** (also absent
  from DefiLlama's 1,302-record hack DB).
- **No deprecation/sunset pause**: YIELD was still being promoted and integrated on 2026-09-28.

**Medium confidence**
- Base `phase.cash` / CASH / `@0xPhase` is a **different project** from Solana's Phase Labs; DefiLlama's
  `parent#phase` grouping appears to be a metadata error. No primary-source link was found in either direction.
  (Caveat: absence of evidence.)
- Sanctum's program-level security posture is sound (multisig-gated upgrade authority, five upstream audits);
  the **pool-level** authority posture is not publicly documented at all.

**Unknown / needs on-chain adjudication by the parent session**
1. **Which price is right?** 1.121 (phase.cc UI) vs 1.1576 (Sanctum `sol-value`) vs 1.1928/1.1937 (Jupiter
   executable quotes on 1 YIELD, both directions) vs 1.194 (Solana Compass pool page) vs ~1.199 (DefiLlama
   implied). A ~3% band is a material discrepancy for a redemption-only instrument.
2. **Why does Sanctum's `apy/latest` return 0.0 and Jupiter's `apy` object come back empty for both YIELD and
   pdSOL**, when Solana Compass measures 5.45% (10-epoch) for the same pool? Possible explanations include a
   stale/absent Sanctum DB entry (post-migration to `sanctum-api.ironforge.network`), the "revenue-boosted"
   rewards not accruing into the exchange rate, or a genuine reward-accrual stall. **This is the single most
   important open question** — it bears directly on whether YIELD's advertised yield is real.
3. **Are the mint authorities on-curve keypairs or program PDAs?** `9HYjrCF5evTobLmay372kpUWSNTrtmDU2NkQtqjdnHKa`
   (YIELD) and `AKJt3m2xJ6ANda9adBGqb5BMrheKJSwxyCfYkLuZNmjn` (pdSOL) are non-null and resolve to System-owned,
   zero-data accounts with small round SOL balances. Neither equals its stake pool account.
4. **Is the pool genuinely single-validator?** Solana Compass reports **1 staked validator (epoch 1058)** for a
   `SanctumSplMulti` pool with a validator list — either normal (Sanctum's crank is single-validator per its
   own docs) or a concentration risk if the intent was multi-validator.
5. **Whether the Phase team has any funding or a legal entity**, and whether "Phase Labs" (Solana) shares
   ownership with "Phase Cash" (Base) behind the scenes. Both unresolved.
6. **The "revenue-boosted YIELD" claim** (Phase business revenue routed into the exchange rate, per the
   2026-09-28 post) is unverified and is not visible in any API I queried.
7. **`@PhaseDelegation` → `@phase_` move** is documented only by the profile's own notice; no announcement of
   what, if anything, was retired alongside it.

**Sources used but not cited inline above:** https://phase-labs.gitbook.io/phase-labs/llms.txt (docs index),
https://learn.sanctum.so/docs/llms.txt, https://lite-api.jup.ag/price/v3 (accessed 2026-10-15 14:07 UTC per
`updatedAt` fields), https://api-v2.raydium.io / https://api-v3.raydium.io (Raydium API v3, 2026-10-15),
https://quicknode.com / https://stakescope.org/coins/SOL/ (aggregator cross-checks, secondary quality).
