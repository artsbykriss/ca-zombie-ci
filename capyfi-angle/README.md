# CapyFi — the *distinct* Apr-2026 access-control angle (ZH4 residual, pass2-recon PRIOR-PARTIAL)

**Date:** 2026-10-23 · **Chain:** Ethereum mainnet (Unitroller) · **Fork block:** 26,255,377 (live reads) / 26,254,120–26,255,341 (PoC)
**Status:** read-only; **fork-verified only; no mainnet transactions signed or sent.** No secrets in this folder.

**Question answered:** the pass2-recon flagged a *distinct* angle for CapyFi (prior finding ZH2 **C2-13**, donation/inflation): an **April-2026 public access-control disclosure** ("complete bypass of a required security control, allowing permissionless access to restricted assets"), closed as "intentional design", after which a team address redeemed 5.5B tokens / removed ~62% (~$55M), leaving **~$5.1M cash** live. **Can a fresh, unprivileged caller use that access-control gap to move the ~$5.1M cash today? — No. E-U = $0.00 (high confidence).**

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why closed / open | Latent risk |
|---|---:|---|---|
| CapyFi Unitroller `0x0b9a…f867E` + 13 markets — **the disclosed access-control gap** | **$0.00** | The "required security control" is the **mint whitelist** (caLAC/caRPC only). It is **live and enforced**: non-whitelisted `mint()` reverts `WhitelistAccess: not whitelisted` (incl. via `delegateToImplementation`). The only non-gated surface is **borrow/redeem/transfer**, which is a **mint-only design choice** and creates no free value (borrowing requires over-collateralisation). | The mint-only design is a **KYC/AML control gap** (a non-whitelisted user can borrow/redeem the KYC-restricted LAC/RPC) — reputational/regulatory, **not extractable value**. If the admin ever *sets a whitelist on a non-restricted market* or **lowers CF semantics**, nothing changes here. |
| The **~$5.16M cash** (1.238M USDT + 0.365M USDC + 1,251.8 ETH + 6.861 WBTC) | $0.00 | It is **supplier-owned (H-O)** and **over-collateralised**; there is no unprivileged path to move it. Zero-collateral `borrow()` reverts `BorrowComptrollerRejection(4)`. | — |

**Total live extractable now via this angle: $0.00** (high confidence). Only ~$2.0k of *uncollectible* bad-debt shortfall exists (no seizable collateral).

## 2. Total live extractable now: **$0.00** (confidence: **high**)

| Category | USD | Note |
|---|---:|---|
| **E-U** (external unprivileged, this angle) | **0.00** | whitelist enforced on mint; oracle + all admin fns gated; extraction bounded by over-collateralisation |
| **E-U** (liquidation dust, other accounts) | ~0.00 | full scan of **all 36 borrowers**: 5 with shortfall, **total $2,059.87** (largest $2,007.95, then $48.41, $1.89, $1.42, $0.21), all liquidity $0 → seizable collateral ≈ $0 → liquidating is a **loss** (`analysis/borrower-scan.txt`) |
| **H-O** (supplier-redeemable cash) | 5,160,241 | the 4 "real-asset" markets (USDT+USDC+ETH+WBTC). Total protocol cash across all 13 markets is **$48,955,771** (incl. **caRPC $41,991,954**) — all holder-redeemable |
| **P** (admin reserves) | 20,301 | `totalReserves` across markets; `_reduceReserves` is admin(multisig)-only |
| **S** (stuck) | 2,010 | uncollectible bad debt (shortfall, zero seizable collateral) |

## 3. The mechanism in exact terms (what the disclosure actually is)

CapyFi = Compound-v2 fork. Its only "required security control" is a **mint whitelist**:

- `Whitelist.sol` (UUPS proxy `0x302a893B…`, impl `0x6b787016…`) with `WHITELISTED_ROLE` (3 members) and an `isActive()` toggle; `activate/deactivate/add/remove` are `onlyAdmin`.
- Enforcement point: `CToken.mintInternal()` is `_checkWhitelist(msg.sender)`:
  ```solidity
  modifier _checkWhitelist(address account) {
      if (address(whitelist) != address(0) && whitelist.isActive()) {
          require(whitelist.isWhitelisted(account), "WhitelistAccess: not whitelisted");
      }
      _;
  }
  ```
- The whitelist is **set only on caLAC and caRPC** (`whitelist()` = `0x302a893B…`); every other market has `whitelist() == address(0)`.
- **Borrow / redeem / transfer / liquidate are not whitelist-gated** — the Comptroller's `mintAllowed`/`borrowAllowed`/`redeemAllowed` contain **no** whitelist logic.

So the disclosed "**complete bypass of a required security control, allowing permissionless access to restricted assets**" = a non-whitelisted user can **borrow (and redeem) the KYC-restricted assets (LAC/RPC)** even though they cannot **mint** them. The team's "intentional design / known issue" is the Compound **mint-only** whitelist. This is independently documented as design note **I-01** in the July-2026 audit writeup, and matches CapyFi's own audit-docs ("unrestricted token transfers and redemptions").

**This is not a mint bypass.** On-chain, every mint path is gated (§5), so an attacker **cannot** obtain caLAC/caRPC collateral for free — which is the only way this control gap could become value.

## 4. Live-state assessment (block 26,255,377; publicnode; full dump in `analysis/live-state.json`)

**Contracts**
| Role | Address | Check |
|---|---|---|
| Unitroller (proxy) | `0x0b9af1fd73885aD52680A1aeAa7A3f17AC702afA` | `comptrollerImplementation()` → `0x00dc4965…f867E` (verified `Comptroller`) |
| Comptroller impl | `0x00dc4965916e03A734190fA382633657c71f867E` | verified; source in `analysis/src/comptroller/` |
| Oracle | `0xfbA2712d3bbcf32c6E0178a21955b61FE1FF424A` (`ChainlinkPriceOracle`) | `owner()` = multisig; config fns `onlyOwner` |
| Whitelist (proxy) | `0x302a893B1AC44fed29Cdf3e3a0a083d1Df3ce54E` | `isActive()=true`; `WHITELISTED_ROLE` = 3 members |
| Admin (multisig) | `0x6C15e4Bc44CC5674b1d7956D0e9596d2E509eD24` | Unitroller admin, all cToken admins, oracle owner, feed owner, whitelist admin |

**Markets (cash / borrows / reserves / CF / whitelist / paused)** — full table in `analysis/live-state.json`; headline:
| Market | cash (USD) | borrows (USD) | CF | mint whitelist | mint/borrow paused |
|---|---:|---:|---:|---|---|
| caUSDT | 1,237,151 | 2,045,720 | 0.85 | — | no/no |
| caUSDC | 364,663 | 854,647 | 0.85 | — | no/no |
| caETH `0x37DE…` | 2,999,752 | 4,197,902 | 0.80 | — | no/no |
| caWBTC | 558,675 | 99,648 | 0.80 | — | no/no |
| caLAC | 1,168,020 | 2,065 | 0.60 | **yes** | no/no |
| caRPC | 41,991,954 | 1 | 0.50 | **yes** | no/no |
| caWARS / caWBRL / caW… dust | 635,421 | 325,540 | 0 | — | no/no |
| caUXD / caETH-legacy | 126 | 15 | 0 | — | **paused** |

**Comptroller:** `closeFactor=0.5`, `liquidationIncentive=1.08`, `pauseGuardian=0x0`, `borrowCapGuardian=0x0`, `transfer/seizeGuardianPaused=false`.
**Whitelisted members:** `0xBac110FF…`, `0x9FB13A7d…`, `0xB6E17577…` — i.e. the only accounts allowed to **mint** LAC/RPC.

## 5. What an attacker can / cannot do — exact call paths

| Path | Result | Evidence |
|---|---|---|
| `caLAC.mint(x)` / `caRPC.mint(x)` as a fresh EOA | **REVERT** `WhitelistAccess: not whitelisted` | `cast call --from 0x…dead` |
| `caLAC.delegateToImplementation(abi.encode(mint))` as a fresh EOA | **REVERT** `WhitelistAccess: not whitelisted` | `cast call` (delegatecall preserves `msg.sender` → modifier still applies) |
| `mintBehalf` / any alternate mint | **no such function** (fallback reverts) | `cast call` |
| `caUSDT.borrow(x)` with **0 collateral** | **REVERT** `BorrowComptrollerRejection(4)` (INSUFFICIENT_LIQUIDITY) | fork test `test_03`; `cast call` |
| `caLAC.borrow(x)` while **not whitelisted**, with collateral | **SUCCEEDS** (the disclosed "permissionless access") — but is a **debt**, not value | fork test `test_02` |
| Borrow the $5.1M cash against own collateral | capped at **CF × collateral** (≤85%) → **net negative** | fork test `test_04` (max borrow $254,963 vs $300,000 collateral) |
| `CapyfiAggregatorV3.updateAnswer(…)` (price feed) | **REVERT** `UnauthorizedCaller` (`onlyAuthorized`) | fork test `test_06` |
| Oracle `addConfig / updateConfigPriceFeed / updateConfigFixedPrice / removeConfig` | `onlyOwner` (multisig) | source + `cast call` |
| `_setWhitelist / _setCollateralFactor / _reduceReserves / _setMintPaused / _supportMarket` … | admin(multisig)-only | source (all revert for non-admin) |
| Liquidate the 2 shortfall accounts | **loss** (seizable collateral ≈ $0 vs $2,010 shortfall) | fork test `test_05` |

**Conclusion:** the access-control gap is a **KYC/AML circumvention** (borrow/redeem the restricted LAC/RPC without whitelisting), **not a value-extraction primitive**. It does not touch the ~$5.1M cash, which is supplier-owned and over-collateralised. A complete borrower census (36 accounts, `analysis/borrower-scan.txt`) finds **$2,059.87** total shortfall with zero seizable collateral — uncollectible dust.

## 6. PoC / fork verification

- `poc/test/CapyFiAngle.t.sol` — 6 tests, all PASS (fork at latest block).
- **CI (GitHub Actions, `artsbykriss/ca-zombie-ci`):** **6/6 PASS** — https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39953549604 (run `39953549604`).
- Key numbers (CI, fork block 26,255,325): max borrowable USDT = 254,963,453,399 (6dp) vs 300,000,000,000 collateral → no profit; bad-debt shortfall = 2,007,946,315,402,833,497,200 (1e18 USD) with **$0** seizable collateral.
- Artifact: `ci-artifacts/result-capyfi-angle/ci-out/capyfi-angle-results.json`.

| Test | Result |
|---|---|
| `test_01_whitelist_state_and_mint_gated` | PASS — whitelist active; non-whitelisted mint reverts |
| `test_02_nonwhitelisted_can_borrow_restricted_asset` | PASS — the disclosed gap confirmed (borrow, not mint) |
| `test_03_no_collateral_cannot_borrow_cash` | PASS — zero-collateral borrow reverts |
| `test_04_extraction_is_overcollateralised_no_profit` | PASS — capped at CF·collateral |
| `test_05_bad_debt_uncollectible` | PASS — no seizable collateral |
| `test_06_price_feed_update_is_owner_gated` | PASS |

## 7. Verdict & reconciliation with ZH2 C2-13

**Verdict: E-U (this distinct angle) = $0.00 — high confidence.** The Apr-2026 disclosure describes the **mint-only whitelist design** (borrow/redeem/transfer unrestricted). The whitelist is **live and enforced on every mint path**, the oracle and all admin functions are gated, and extraction of the ~$5.1M is impossible without over-collateralisation. The ~$5.1M cash is **H-O** (supplier-owned). The only live shortfalls are **uncollectible bad debt** (~$2.0k).

**Is the new angle additive to ZH2 C2-13? → NO.**
- C2-13 already concluded the **lending protocol itself is $0** and named the reason *"caLAC/caRPC mint whitelist-gated"* — i.e. the same control this disclosure concerns. C2-13's *non-zero* headline (E-U ≈ $105/day) came from a **different, adjacent product** (the stBTC `YieldOracle.reportYield()` leak), not the lending markets and not this access-control surface.
- My verification shows the whitelist is **not bypassable for minting**; the only "gap" is the mint-only design, which C2-13 effectively assumed and which the July-2026 independent audit recorded as design note **I-01**. So the distinct angle **does not change C2-13's verdict and adds $0**.
- Net: **correction/monitor, not a ranked finding** — consistent with pass2-recon's disposition.

**Residual / latent risk (non-E-U):** (a) the mint-only whitelist is a KYC/AML gap (a non-whitelisted user can borrow/redeem restricted LAC/RPC) — regulatory/reputational; (b) if the multisig ever sets a whitelist on a *non-restricted* market, mint would be gated there too (no attacker gain); (c) the $2.0k bad debt remains protocol loss (S).

**Blockers to any extraction (all live):** mint whitelist (`isActive=true`), over-collateralisation (CF ≤ 0.85), owner-gated oracle/feeds, admin(multisig)-gated parameter fns, no pause-guardian/bc-guardian to abuse.

## 8. Methodology, caveats & files

**Method:** live `cast`/JSON-RPC reads at a pinned block; Etherscan V2 verified sources (Comptroller, CToken, CErc20Delegator/Delegate, Whitelist, ChainlinkPriceOracle, CapyfiAggregatorV3); full-history `Redeem`/`Borrow` log scans; Foundry fork PoC; Firecrawl/web recovery of the primary disclosure (PullPush) and the July-2026 audit writeup.

**Caveats:**
- The disclosure **does not name the function**; the mapping to the mint-only whitelist is my reconstruction from the live code + CapyFi's own audit-docs + the July-2026 audit (I-01). A mint-whitelist bypass is **disproven** on-chain today.
- The reporter's 5.5B-token / 62% / $55M redemption could **not** be pinned to an Ethereum Unitroller `Redeem` event (caRPC has none; caLAC/caWARS far smaller) — possibly another CapyFi chain or route. Immaterial to the today-E-U verdict.
- Fork RPC = keyless publicnode; prices from CapyFi's own oracle (USDT $0.9989, USDC $0.9999, ETH $2,396.35, WBTC $81,428.75, LAC $0.009955, RPC $0.010267). USD at fork time.

**Files:** `README.md` (this) · `summary.json` · `analysis/live-state.json` · `analysis/disclosure.md` · `analysis/dump_live_state.py` · `analysis/src/**` (verified sources) · `poc/` (Foundry, 6/6) · `ci/run.sh` · `ci-out/` · `ci-log.txt` · `ci-artifacts/`.

*Prepared 2026-10-23 · read-only research · fork-only PoC · no mainnet transactions.*
