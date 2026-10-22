# Affluent / Factorial Finance (TON) — Incident OSINT

**Target:** Affluent (formerly Factorial Finance) — TON DeFi lending / "trustless asset management" protocol.
Website https://affluent.org · X https://x.com/AffluentOrg · Telegram https://t.me/affluent · Docs https://docs.affluent.org · Blog https://blog.affluent.org
**Incident window (per task):** 2026-10-14/15 · **Date recorded publicly:** 2026-10-16
**Collected:** 2026-10-22 (read-only OSINT)

---

## TL;DR / Bottom line

There are exactly **two public records** of this incident, and one is derived from the other:

1. **DefiLlama** (the primary record) — an entry in its hacks database.
2. **SlowMist Hacked** — an entry that cites **only DefiLlama** as its reference source.

Everything else (the "Smart Contract Hacking" dashboard, datasets) is a re-publication of the DefiLlama row.

**No post-mortem, no attacker address, no transaction hash, no named exploited contract, no abused function/opcode, no incident-specific team statement, and no independent security-firm analysis could be found.** The protocol's own channels have been silent since **before** the incident (X: last post Sep 30, 2026; Telegram: last post Jun 10, 2026; GitHub: last push Mar 16, 2026).

---

## 1. The public incident records (verbatim)

### 1.1 DefiLlama — primary
- Protocol page: https://defillama.com/protocol/affluent → "Hacks" panel:
  > **Date: Oct 16, 2026 · Amount: $1.05m · Classification: Token & Share Accounting · Technique: Unbacked Mint · Chains: TON · Target Type: DeFi Protocol**
  > FAQ: "Affluent has **1 recorded security incident**. The most recent incident occurred on **Oct 16, 2026** and involved **$1.05m**. It was classified as **Token & Share Accounting**."
- Machine record (`https://api.llama.fi/hacks`, entry with `defillamaId` **5726**):
  ```json
  {"date":1792108800,"name":"Affluent","classification":"Token & Share Accounting",
   "technique":"Unbacked Mint","amount":1053000,"chain":["TON"],"bridgeHack":false,
   "targetType":"DeFi Protocol","source":"","returnedFunds":null,"defillamaId":"5726","language":null}
  ```
  - `date` 1792108800 = **2026-10-16 00:00 UTC**.
  - **`source` is an empty string** — DefiLlama published *no* reference URL for this row (unlike most rows, which link a tweet/post-mortem). This is the single most important data-quality signal: the incident was not backed by a public source when logged.
- DefiLlama TVL context: TVL ~$1.43–1.46M (Oct 21–22), down **~43–47% over 30 days**; a snapshot on the TON chain page shows Affluent `-12.62%` 24h around Oct 17. Active loans $138,914–$147,227.

### 1.2 SlowMist Hacked — derived
- https://hacked.slowmist.io/ (2026-10-16 entry):
  > **Hacked target: Affluent**
  > "The Affluent DeFi protocol on the TON chain experienced an **unbacked minting** incident classified under **token and share accounting**, resulting in a loss of approximately **$1,053,000** due to a **smart contract vulnerability**."
  > Amount of loss: **$1,053,000** · Attack method: **Smart Contract Vulnerability**
  > **View Reference Sources → https://defillama.com/protocol/affluent** (i.e. the only source is DefiLlama)

### 1.3 smartcontractshacking.com — re-publication
- https://smartcontractshacking.com/hacks/affluent-hack-2026 → "Reported loss $1.1M · Oct 16, 2026 · Ton · Unbacked Mint"; Evidence = "analysis DeFiLlama defillama.com".
  > "**A detailed attack sequence is not available in this feed entry.**"

---

## 2. Date discrepancy (noted, unresolved)

- Task states the incident as **2026-10-14/15**.
- **Both DefiLlama and SlowMist record 2026-10-16.** No source was found supporting Oct 14/15 specifically. (UNCX and Pirate Chain also logged Oct 14/16 — do not confuse.)

---

## 3. Attacker TON address(es)

**None found.** No attacker address appears in any public source. Searches for an address in connection with the incident returned nothing (see §8). The DefiLlama row has no `source`, and SlowMist posted no address (its `@SlowMist_Team` X feed shows detailed entries for other Oct-2026 incidents, but its Affluent entry carries no X link — only the DefiLlama URL).

## 4. Exploited contract address

**No public source names the affected contract.** The victim type is only described generically as a TON DeFi lending protocol with a "token & share accounting" failure.

For reference (public, from the DefiLlama adapter — these are Affluent/Factorial's *known* contracts, **not** a confirmation of which was hit):
- Lending vaults: `EQAGtgnr1G0XDilGURcOB3pUhl-Lo__J-TaJP0K4ey8cuSaW` (Factorial/Lending-Vault/USDT, symbol `affUSDTl`), `EQADQ6JcK0NMuNM5uwCcS9bjcn2RTvcxYIZjNlhIhywUrfBN` (Factorial/Lending-Vault/TON, symbol `affTONl`)
- Pools: `EQCrEHHG4Ff8TD3PzuH5tFSwHBD3zxeXaosz48jGLebwiiNx` (BasicPool), `EQBCXQp2sSTJhvnV6DlBqhTsdNMZc_tJcXQJ5XjoWiy-OAge` (AdvancedPool), `EQAYJdU9JFRcKAwMZv3MqD0QVjBEMGO_4mgwOJtTBOHR22ec` (StormUsdtPool), `EQCOA3gN3Dk-ml66zux_vuia7mTIBTENKxtomD6TDgnFZXoH` (StormAdvancedPool), `EQA3m4H3vTUOeXGW-o6AEyZxv6i79tR-i1f4XiW588HJoqND` (StormTonPool), `EQBQMDjWVLeX0vAUNDTRL-aA665EItLzSvONywKDHXJRCuxB` (LendingVaultPool), `EQCNgBmHVBRWpMeZE7E92RM-Gecnv88LJaXAlmqn4WAfJIA9` (TradoorAdvancedPool), `EQA9iTdgsPxvk08idCXQoefGqJGLTDQFy4W34AtEj7Z_25iT` (EthenaPool)
- Strategy-vault / vault-share jettons: `EQDtxQqkgIRQQR5hWlrQxiJMtLwjR3rEYNUBbEcvPDwCs1Ng` (affTONm), `EQBzSItiC1vpDUEftDeWDyjgMutf6CIzme16gzn9iNlolpcY` (affUSDTm), `EQDXmtbt1-WSP00tSh6N6FH-4lX7LbnrjORClmtmuZqg4Ymm` (affETHENAm), `EQBowXTtxDTSMEJbrIIcYzIvSXZ9V5HW2Oo2iSW0chUzod3d` (affGOLDm), `EQD3F7Ex_uxBjxEub8FxeDoYYUSIbAUVyehCb_JSiCVL369T` (affUSDe)
  Source: `https://raw.githubusercontent.com/DefiLlama/DefiLlama-Adapters/main/projects/factorial/affluentMarketAssets.js`

## 5. Mechanism

**No mechanism detail is public.** The only public labels are DefiLlama's taxonomy: classification **"Token & Share Accounting"**, technique **"Unbacked Mint"** — and SlowMist's paraphrase "unbacked minting incident classified under token and share accounting … smart contract vulnerability."

No function name, opcode, message-handler, or exploit sequence has been published. (Anything beyond the labels above would be speculation; treat the "share accounting" framing as DefiLlama's classification, not a confirmed root cause.)

## 6. Team statements / post-mortem

**None found.** There is **no post-mortem** and **no incident-specific statement** on any Affluent channel:

- **X @AffluentOrg** (https://x.com/AffluentOrg): timeline (retrieved 2026-10-22) shows pinned post **Apr 9, 2026** (Sentora Vault), then **Sep 30, Sep 18, Sep 7, Aug 14** — i.e. **the last post predates the incident**. No October 2026 posts, no hack notice. (Profile shows ~1,632 posts, 3,251 followers, joined Aug 2024.)
- **Telegram @Affluent / @FactorialFinance** (https://t.me/s/affluent): last message is **#133, dated 2026-06-10** (a forward about the TON→GRAM rename). Channel silent since June 2026; **no incident post**. Community chat @affluentchat still exists (~222 members) but is not a statement channel.
- **Blog (Substack)** https://blog.affluent.org: latest visible items are 2025-dated ("Ex-TON Foundation executive…", "Affluent Vaults Are Now Live in TON Wallet", Nov 3 2025). **No incident post.**
- **Docs** https://docs.affluent.org (llms.txt index): **no changelog** page exists; nothing about an incident.
- **GitHub org `factorial-finance`** (https://github.com/factorial-finance): last pushes — `dimension-adapters` 2026-03-16, `ton-assets` 2026-01-26, `DefiLlama-Adapters` (fork) 2026-01-26, `sdk-solv-btc` 2026-01-14, `audits` 2025-07-29. **No activity after March 2026; no post-incident fix commit.** Repos are forks/adapters; no `affluent-*` repo exists; no `ton-blockchain/abis` "data/affluent" was found.

## 7. DefiLlama adapter commit history (the "fix commit" lead)

- Adapter files exist: `projects/factorial/index.js`, `projects/factorial/affluentMarketAssets.js`.
- **Commit history for `projects/factorial` ends at 2025-11-26** ("use token labels", g1nt0ki). Prior commits: 2025-11-14 ("update: directly manage the pool list"), 2025-10-14 ("bidask"), 2025-06-20, 2025-06-18 ("Fix: Affluent (rate limit)"), 2025-03-26, 2025-03-25, 2025-02-04 ("Factorial").
- **No commit after 2026-10-15 touching `factorial`/`affluent` was found** — a scan of `DefiLlama/DefiLlama-Adapters` commits since 2026-10-10 shows no Affluent/Factorial/TON-Affluent change. **The "commit right after Oct 15 that reveals the fix" does not exist in this repo.**

## 8. Independent security-firm coverage

**None found.** No incident-specific post by **PeckShield/PeckShieldAlert, BlockSec, Ancilia, CertiK, Cyvers, or Beosin** was located. SlowMist's *entry* exists (§1.2) but is a summary that cites DefiLlama; SlowMist's X feed around 2026-10-14…10-21 covers other incidents (UNCX, Pirate Chain, Qubic, AlpsCon, Slice) but shows **no Affluent tweet**. No TON tx hash or attacker address was published by any firm.

## 9. Own on-chain observation (UNVERIFIED — NOT attributed)

Using the public **tonapi.io** API (read-only) on the known Affluent contracts:

- `EQAGtgnr…` (USDT Lending Vault, interfaces `affluent_lending_vault` + `jetton_master`) is active and had **activity bursts** in the incident window: **2026-10-16 ~20:36–20:46 UTC** and **2026-10-17 ~07:11–07:28 UTC** (sequences of `SmartContractExec` / `JettonTransfer` / `TonTransfer`, small values in the hundreds of USDT/TON range, involving recurring internal "rebalancer" contracts).
- Largest jetton holders of `affUSDTl` / `affTONl` are ordinary-sized, recurring addresses — **no single anomalous "attacker" holder was identifiable**.

**Caveat:** this activity is consistent with **routine vault rebalancing/withdrawal**, and I could **not** identify an "unbacked mint" transaction, an attacker address, or an exploit hash from it. It is reported here only as raw observation and **must not** be treated as the exploit. (toncenter.com v3 returned HTTP 403/429 to unauthenticated requests; tonapi.io was used instead.)

## 10. What could NOT be found (explicit)

- ❌ Any attacker TON address
- ❌ Any exploit transaction hash (lt+hash) or tonviewer/tonscan link
- ❌ The name/address of the exploited contract (pool / vault / lending vault / jetton minter)
- ❌ The abused function, opcode, or message handler
- ❌ Any step-by-step mechanism or attack sequence
- ❌ Any team statement (X, Telegram, blog, GitHub, Discord)
- ❌ Any post-mortem
- ❌ Any independent on-chain analysis (PeckShield, BlockSec, Ancilia, CertiK, Cyvers, Beosin, SlowMist original analysis)
- ❌ Any mainstream-press article (CoinDesk, Cointelegraph, The Block, Decrypt, CryptoSlate, Rekt) covering the Affluent incident
- ❌ A Rekt.news entry (not on the leaderboard; `/affluent-rekt/` → HTTP 500/404)
- ❌ A DefiLlama `source` URL (field is empty)
- ❌ Any funds-return / negotiation / whitehat record (`returnedFunds: null`)
- ❌ Any post-incident contract-migration or adapter "fix" commit

---

## Sources

| # | Source | URL | Date | What it gives |
|---|--------|-----|------|----------------|
| 1 | DefiLlama — protocol page | https://defillama.com/protocol/affluent | live 2026-10-22 | Date/amount/classification/technique/chain |
| 2 | DefiLlama — hacks API | https://api.llama.fi/hacks | live 2026-10-22 | Machine record, `defillamaId` 5726, empty `source` |
| 3 | DefiLlama — hacks database | https://defillama.com/hacks | live | "Affluent \| Oct 16, 2026 \| $1.05m \| TON" |
| 4 | SlowMist Hacked | https://hacked.slowmist.io/ | entry 2026-10-16 | $1,053,000; cites DefiLlama only |
| 5 | Smart Contract Hacking | https://smartcontractshacking.com/hacks/affluent-hack-2026 | 2026 | $1.1M; "no detailed attack sequence available" |
| 6 | Affluent X profile | https://x.com/AffluentOrg | retrieved 2026-10-22 | Last post Sep 30 2026 (pre-incident) |
| 7 | Affluent Telegram | https://t.me/s/affluent | retrieved 2026-10-22 | Last post #133, 2026-06-10 |
| 8 | Affluent blog (Substack) | https://blog.affluent.org/ | retrieved | No incident post |
| 9 | Affluent docs (llms.txt) | https://docs.affluent.org/llms.txt | retrieved | No changelog |
| 10 | GitHub org | https://github.com/factorial-finance | retrieved | Last push 2026-03-16; no fix commit |
| 11 | DefiLlama adapter (contracts) | https://raw.githubusercontent.com/DefiLlama/DefiLlama-Adapters/main/projects/factorial/affluentMarketAssets.js | retrieved | Candidate contract addresses |
| 12 | Adapter commit history | https://api.github.com/repos/DefiLlama/DefiLlama-Adapters/commits?path=projects/factorial | retrieved | Latest 2025-11-26; none post-incident |
| 13 | tonapi.io | https://tonapi.io/v2/accounts/EQAGtgnr1G0XDilGURcOB3pUhl-Lo__J-TaJP0K4ey8cuSaW/events | live | Vault activity bursts (unattributed) |
| 14 | Coindesk (background) | https://www.coindesk.com/business/2025/06/16/ton-based-protocol-affluent-wants-to-make-telegram-a-financial-super-app | 2025-06-16 | Affluent = ex-Factorial, co-founder Justin Hyun |
| 15 | DefiLlama audits repo | https://github.com/factorial-finance/audits | retrieved | Two audit PDFs (Feb 2025, Jun 2025) |

*All web content treated as untrusted data. No private keys used. No writes outside `/home/heisenberg/CA/affluent/analysis/`.*
