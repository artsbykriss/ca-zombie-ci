# Segment Finance (opBNB) — adversarial extraction probe: verdict **$0 extractable**

**Campaign:** flare-kava-small / Tier-3 deep dive, lead L2-07 · **Chain:** opBNB (chain id 204) · **Date:** 2026-10-15
**Status:** read-only research; every claim is a live `eth_call`/`eth_getLogs` at a recorded block; the PoC runs
on a **local fork only**. No real-chain transaction was signed or sent. No secrets in this folder.
Final re-verification: **block 195,783,829** (oracle still reverts for all five markets, registry still empty,
`maxStalePeriod` still 0, SEF still unwired, whale `getAccountLiquidity` still reverts).

**Target:** Segment Finance lending protocol on opBNB — Comptroller `0x71ac0e9a7113130280040d0189d0556f45a8cbb5`,
five markets (seFDUSD, seUSDT, seETH, seBTC, native seBNB), ≈**$5.62k of claims** and ≈**$685 of cash**
(block 195,761,245, prices 2026-10-15T09:47Z).
**Campaign lead said:** "~$1–4k | all markets supplied; insolvent". **Result of adversarial test:** the lead
understates the nominal value (it is ≈$5.6k, not $1–4k) but the **extractable** number is **$0** for an
external unprivileged attacker, for a reason the lead did not identify: the protocol's oracle is **dead and
unprivileged-unrevivable**, which freezes every value-moving path.

---

## 1. TL;DR

| # | Path | Category | Live net USD | Why open/closed |
|---|---|---|---|---|
| 1 | Borrow against collateral / flash-loan-collateral drain | E-U | **$0** | every `borrow` reverts `invalid resilient oracle price` (oracle dead); no price ⇒ no liquidity math |
| 2 | Liquidate the bad-debt / underwater positions | E-U | **$0** | `liquidateBorrow` on real members reverts on the oracle; the only shortfall positions are unprofitable anyway (733 USDT debt with ~0 collateral; a $5 dust position with less collateral than repay) |
| 3 | Sonne-class empty-market/donation attack | E-U | **$0** | no empty market exists (supply 2.5e7–1.85e12 seTokens) and no borrow leg; a donation is a pro-rata gift to existing holders — fork-verified net-negative |
| 4 | Mint→redeem / redeemUnderlying rounding arbitrage | E-U | **$0** | both legs accrue first at the same rate; round-trip is value-neutral (fork-verified) |
| 5 | `claimSegment` / SEF / SEUSD reward capture | E-U | **$0** | `getSEFAddress() = 0` — the reward token was never wired; `claimSegment` is a no-op; `_grantSEF` is "only admin can" |
| 6 | Steal seTokens via approvals (`transferFrom`) | E-U | **$0** | `transferAllowed` for a member source hits the dead oracle; non-member sources are dust with no public allowance found |
| 7 | Admin/upgrade/reward levers (oracle, markets, Safe) | P | $0 | every setter is gated by the 2-of-3 Safe / AccessControlManager; `pendingAdmin`/`pendingImpl` = 0 (no hijack) |
| 8 | Non-member `redeem` (Compound semantics) | **H-O** | **≈$140 (own funds)** | accounts that minted but never called `enterMarkets` bypass the oracle; **being used live right now** (seBNB, last 2026-10-13) |
| 9 | Member redeem / whale exits (the ≈$5.6k) | **S/H-O** | $0 today | frozen until governance revives the oracle; cash cover is only 12% anyway (USDT cash = 1 wei) |

**Total live extractable by an external unprivileged attacker: `$0` (high confidence).**
**Latent/tripwire:** if the Safe fixes the oracle (P), liquidations become possible again — but the only
remaining shortfall positions are unprofitable, so even then E-U ≈ $0. The real residual is the frozen
holder value (~$5.6k), not attacker profit.

---

## 2. The mechanism (exact terms)

Segment on opBNB is a **Venus-lineage Compound-V2 fork** (`SeToken`/`SeBep20Delegator` + a Diamond
Comptroller). Its entire price input chain is:

`Comptroller.oracle()` → **ResilientOracle** proxy `0xaacf634dd705d37e94c38ea68384e669d2b4d491`
→ per-asset **main oracle only** → **BinanceOracle** proxy `0x15cb42a8bc953ba604cf17dcbaa7d78b235979bf`
→ **FeedRegistry** `0x72d55658242377af22907b6e7350148288f88033` (Chainlink FeedRegistry-style).

Both failure conditions are live and permanent for an unprivileged actor:

1. **The registry holds no keys at all.** `exists("USDT","USD") = exists("FDUSD","USD") = exists("ETH","USD")
   = exists("BTCB","USD") = exists("BNB","USD") = false`; `latestRoundDataByName(...)` reverts
   `Key does not exist`; `latestRoundData(USDT, 0x0)` reverts `Feed not found`.
2. **`maxStalePeriod[symbol] == 0` for all five symbols** on the BinanceOracle. The check is
   `block.timestamp - updatedAt > maxStalePeriod` ⇒ any non-zero age reverts; combined with (1) the price
   is *always* invalid.

Therefore `ResilientOracle.getUnderlyingPrice(market)` **reverts `invalid resilient oracle price` for all five
markets**, and every market operation that consults account liquidity reverts with it:
`borrow`, `borrowBehalf`, `liquidateBorrow`, and `redeem`/`redeemUnderlying`/`transfer`/`transferFrom` **for
market members** (Compound's `redeemAllowedInternal`/`transferAllowed` bypass the liquidity check only when
`accountMembership[src] == false`; `mint` never sets membership — only `enterMarkets` does).

All three price layers' write functions are privileged:
`ResilientOracle.setTokenConfig/pause/setAccessControlManager` → AccessControl revert (`0x4a3fa293`);
`BinanceOracle.setMaxStalePeriod/setSymbolOverride` → AccessControl revert; `transferOwnership` →
`OwnableUnauthorizedAccount` (`0x118cdaa7`); `FeedRegistry.proposeFeed/confirmFeed` → `Only callable by owner`.
Owners/admins are the **2-of-3 Gnosis Safe** `0x1f41cfbbf95bac4f5a220700f78dbaa1e34b97d1` and its ProxyAdmins.
**No permissionless price input exists anywhere in the chain.**

The Sonne-class "empty-market donation" bug class does not apply: there is no market with negligible supply
(min supply 2.5e7 seTokens), mint/redeem/borrow all accrue interest first (no stale-rate window), and a
donation inflates the exchange rate pro-rata — the donor's own redeemable value grows by only their share.
Fork-verified: donating 100 FDUSD to a market where the attacker holds a tiny share leaves them net-negative.

---

## 3. Live-state assessment (block 195,761,245; full detail in `state.md` / `state.json`)

- **Comptroller** `0x71ac0e9a…` (Unitroller → Diamond impl `0xae2a97297ea09f82229076c9caff7c00a6140817`,
  4 facets): `admin = 0x1f41cfbb…`, `pendingAdmin = 0`, `pendingImpl = 0`, `closeFactor = 0.5`,
  `liquidationIncentive = 1.10`, `pauseGuardian = 0`, `protocolPaused = false`, exactly 5 markets.
- **Docs-listed "Comptroller (beacon)" `0xba3835ed56a8b705a202642a83595cddc5b7b729` has no code.**
- **Admin** = Gnosis Safe 1.3.0 **2-of-3** (`0x97a1644f…`, `0x1ac51371…`, `0x14e7c230…`) — also owner of the
  two ProxyAdmins (`0x982e35f6…` oracle, `0x26016da9…` BinanceOracle).
- **Markets** (all `reserveFactor = 0`, `totalReserves = 0`, `admin = Safe`):

| Market | cash | borrows (current) | supply | borrowIndex | last accrual |
|---|---|---|---|---|---|
| seFDUSD `0xfe62ba74…` | 173.604 FDUSD | 169.050 | 1.5575e12 | 1.056 | 65,471,838 |
| seUSDT `0x7add376c…` | **1 wei** | 2,086.809 | 1.8524e12 | 3.252 | 153,196,838 |
| seETH `0x81b98b28…` | 0.040920 ETH | 0.511635 | 5.2875e8 | 3.715 | 163,095,580 |
| seBTC `0x56755816…` | 0.0019272 BTC | 0.0125131 | 2.4988e7 | 1.191 | 72,359,914 |
| seBNB `0x7e844423…` (native) | 0.359716 BNB | 0.635906 | 4.0327e9 | 1.488 | 195,199,920 |

  Value: **cash $685.33**, borrows $4,936.23, **total claims $5,621.56**; cash cover per market 0%–51%.
- **Positions** (complete — enumerated debt equals `totalBorrows` exactly in all five markets):
  - `0x68a01870…` **733.26 USDT bad debt** (~0 collateral after 10 historical liquidations);
  - `0xeed518c9…` 0.0022 ETH debt vs 0.00008 ETH collateral (unprofitable);
  - `0x8d97998b…` (83.6% of seFDUSD / 62.3% of seUSDT supply, ≈$4.2k claims, ≈$1.6k debt) and
    `0xf8221bdd…` (≈$6.9k claims, ≈$0.25k debt) are **market members** and price-frozen;
  - all other accounts are dust. `getAccountLiquidity()` reverts for every real holder.
- **Reward surface:** `getSEFAddress() = 0`, `segmentAccrued = 0`, `segmentRate`/speeds = 0,
  no reward distributor wiring → nothing to claim. `treasuryAddress = 0`, `seusdController = 0`.
- **Gas** is 0.001 gwei — costs are irrelevant (a 1M-gas tx < $0.001).

---

## 4. What an attacker can and cannot do

**Can (all value-neutral or self-funded):**
`mint`/`mintBehalf`, `repayBorrow`/`repayBorrowBehalf`, `accrueInterest`, `approve`, `enterMarkets`
(no oracle needed), and — for accounts that are **not** members of the market — `redeem`/`redeemUnderlying`
and `transfer`. None of these can be turned into profit: mint and redeem both accrue first at the same rate,
a donation is pro-rata, and the attacker cannot acquire *other people's* seTokens (member transfers are
oracle-blocked; no AMM/OTC market for seTokens exists; no public allowance was found).

**Cannot:** `borrow`, `borrowBehalf`, `liquidateBorrow`, member `redeem`/`transfer`, `seize` (non-listed
caller), `_reduceReserves`/`_setReserveFactor`/`_setInterestRateModel`/`_setComptroller`/`_setPendingAdmin`
(error 1 UNAUTHORIZED), `_setImplementation`/`_becomeImplementation`/`_resignImplementation`/
`initialize` (admin), `_grantSEF`/`_setPriceOracle`/`_setCollateralFactor`/`_setCloseFactor` (admin),
`ResilientOracle.setTokenConfig`/`pause`, `BinanceOracle.setMaxStalePeriod`/`setSymbolOverride`/
`transferOwnership`, `FeedRegistry.proposeFeed`/`confirmFeed`.

**Capital & cost notes:** extraction would need no flash loans because no capital-consuming path exists;
the largest capital-consuming candidate (liquidating the 733 USDT bad-debt position) would *lose* money
even with a working oracle (no collateral to seize). opBNB gas is negligible.

---

## 5. PoC / fork verification

- File: `test/SegmentFork.t.sol` (self-contained, forge-std only — parent copies it to `poc/test/`).
- Fork: `vm.createSelectFork(vm.envOr("OPBNB_RPC_URL", string("https://opbnb-mainnet-rpc.bnbchain.org")))`
  (no block pin: public opBNB RPCs are not archive nodes — `eth_call` at historical blocks returns
  `missing trie node`).
- Tests (11) — all are live-state assertions and negative controls:
  T1 `test_T1_live_state_invariants`, `test_T1_oracle_dead_for_every_market`;
  T2 `test_T2_borrow_and_liquidation_revert_dead_oracle`,
  `test_T2_member_redeem_frozen_nonmember_redeem_works`, `test_T2_mint_redeem_roundtrip_no_profit`,
  `test_T2_donation_attack_closed`, `test_T2_seBNB_no_extraction`;
  T3 `test_T3_liquidation_of_real_positions_reverts`, `test_T3_whale_positions_are_frozen`;
  T4 `test_T4_reward_paths_have_no_value`, `test_T4_admin_paths_gated`,
  `test_T4_oracle_revival_requires_privilege`, `test_T4_seize_and_market_hijack_closed`.
- CI run: **not run from this child session** (per brief, the parent executes the suite). Suite runtime is
  a few dozen RPC calls, well under the 10-minute budget.

Key live evidence (address + block + call):

| Claim | Evidence |
|---|---|
| All five prices dead | `0xaacf634d…getUnderlyingPrice(0xfe62ba74…)` → revert `invalid resilient oracle price`; same for all 5 markets @ 195,761,245 |
| Root cause | `0x15cb42a8…getPrice(USDT)` → `binance oracle price expired`; `maxStalePeriod("USDT") = 0`; `0x72d55658…exists("USDT","USD") = false` |
| Borrow blocked | `0x7add376c…borrow(1e6)` → revert oracle message @ 195,761,xxx (any caller) |
| Liquidations blocked | `0x71ac0e9a…getAccountLiquidity(0x68a01870…)` → revert oracle message; same for `0x8d97998b…`, `0xf8221bdd…` |
| Member redeem frozen | `getAccountLiquidity(whale)` reverts; `redeem` path requires it for `accountMembership = true` |
| Non-member redeem live | tx `0x5f22a29b93605a49f0e39c5e3b02af1e71b238c01ba9f10fe81a3f999c3c3cbd` block 195,199,920 (2026-10-13) — non-member redeemed 0.033 BNB from seBNB |
| Last functional day | tx `0xb88d70267cbc00cf8e89ac0115e7a6c3ae2408ed1028810f74152a6087216dc4` block 144,381,129 (2026-05-19) — a full liquidation+redeem that required working prices |
| No reward value | `getSEFAddress() = 0`; `claimSegment(...)` succeeds but transfers nothing; `_grantSEF` → `only admin can` |
| Admin is a 2-of-3 Safe | `getThreshold() = 2`, `getOwners() = [3 EOAs]`, `VERSION() = 1.3.0` |

---

## 6. Verdict & residual risk

**Verdict: E-U = $0 (high confidence).** H-O ≈ $140 in seBNB is recoverable by the (non-member) holders
themselves and is visibly being drained on-chain; the remaining ≈$5.5k of holder claims are **S**
(price-frozen) until governance acts. Nothing is extractable by an outsider today, and even a *revived*
oracle would not create a profitable E-U path because the only shortfall positions are unprofitable.

**Tripwires to monitor (all P/state-flip):**
1. `ResilientOracle.getUnderlyingPrice` starts returning non-reverting values (oracle fixed) → re-run the
   liquidation math in `test_T3_*`; currently the only shortfall positions are the 733 USDT bad debt and a
   ~$5 dust position, both unprofitable — but new borrowing could change that.
2. `FeedRegistry` gains keys / `maxStalePeriod` becomes non-zero (governance-only).
3. The market `admin`/`pendingAdmin` or the Safe owners change (2-of-3 key compromise is the only way an
   attacker could reach the ≈$685 of cash and the frozen positions).

**Blockers/caveats:** opBNB public RPCs are non-archive → historical oracle checks impossible; the exact
block at which the oracle broke is only bracketed to (2026-05-19, 2026-10-13]; opBNB explorer APIs
(opbnb.bscscan.com, Etherscan V2 chainid 204) were unavailable during this work, so contract source was
recovered from the public `Segment-Finance/protocol` repo (feature- and error-string-matched to the
deployed bytecode) rather than verified explorer source; no private keys, no transactions.

---

## 7. Methodology, sources, files

- **RPC:** `https://opbnb-mainnet-rpc.bnbchain.org` (fallback `https://opbnb.publicnode.com`), keyless.
- **Logs:** exhaustive 50k-block `eth_getLogs` scan of all five markets over the whole chain
  (blocks 0 → 195.77M, 1,774 events: Mint/Redeem/Borrow/RepayBorrow/LiquidateBorrow/Transfer/AccrueInterest),
  batched and resumable (`analysis/scan_logs.py`, raw gz in `analysis/segment_logs.jsonl.gz`).
- **Source:** `github.com/Segment-Finance/protocol` (SeToken/SeBep20Delegator, Diamond facets) — matched to
  the deployed selectors/error strings (`mintBehalf`, `borrowBehalf`, "SeBep20Delegator::_setImplementation:
  Caller must be admin", Compound error codes).
- **Prices:** DefiLlama/CoinGecko, 2026-10-15T09:47Z — BNB $720.75, ETH $2,366.28, BTC $81,020.10,
  USDT $0.99907, FDUSD $0.99706.
- **Tooling:** Python JSON-RPC batcher (`analysis/rpc.py`, `analysis/reader.py`), selector scanner
  (`analysis/selscan.py`), log scanner (`analysis/scan_logs.py`). No Foundry execution locally (per brief).

Files: `README.md`, `state.json`, `state.md`, `oracle.md`, `borrowers.csv`, `summary.json`,
`test/SegmentFork.t.sol`, `analysis/` (raw reads + scripts + event log).
