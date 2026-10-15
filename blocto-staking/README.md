# L2-04 · BloctoTokenStaking (Flow) — zombie-hunt II, Tier-3 deep-dive

**Date:** 2026-10-15 · **Chain:** Flow mainnet (Cadence) · **Status:** read-only; no mainnet transactions ever sent; PoC run on a local Flow emulator only.

**Target:** `BloctoTokenStaking` at `0x0f9df91c9121c460` (same account as `BloctoToken`, `BloctoPass`, `BloctoPassStamp`, `BloctoTokenSale`).
**Prior:** "62M BLT staked, 29,762 stakers — admin-frozen; no path" (ZOMBIE-HUNT-II L2-04). **This report:** adversarially tested; verdict stands with exact gates + PoC.

---

## 1. TL;DR

| Target | Live value (nominal / realizable) | E-U extractable by fresh attacker | Why closed |
|---|---|---|---|
| BloctoTokenStaking staker records | 100,732,692.04 BLT (≈$111.2k @ last CMC price; **≈$0 realizable**) | **$0.00** | Every value-moving function is entitlement-gated: staker buckets only via the `Staker` resource embedded in the holder's own `BloctoPass` NFT; admin ops only via the `Admin` resource in the contract account; freeze (`stakingEnabled=false`) blocks all staking ops; the only public write surface (BloctoPass minter) reverts while frozen |
| ↳ of which holder-withdrawable **now** (H-O) | 38,684,639.69 BLT (34.73M unstaked + 3.95M rewarded) | $0 | `withdrawUnstakedTokens`/`withdrawRewardedTokens` have **no freeze gate** but are self-scoped — only the pass holder can call them (proven) |
| ↳ of which admin-gated (P) | 62,048,052.35 BLT (62.00M staked + 44.4k committed) | $0 | `requestUnstaking`/`unstakeAll`/`moveTokens` all require the frozen admin to act |
| Contract-account BLT treasury vault | 91,708,956.07 BLT (P) | $0 | `/public/bloctoTokenReceiver` is an **unentitled** `&BloctoToken.Vault` — deposit/read only; `withdraw` requires `FungibleToken.Withdraw` (compile-time) |
| BloctoTokenSale vaults (same account) | unknown BLT + tUSDT (S) | $0 | Contract source is **pre-Cadence-1.0 (`pub`)** and cannot load — bricked; unreachable by anyone incl. admin unless the contract account updates it (P) |

**Total live extractable now: $0.00 — confidence high.**

## 2. Headline

> **An external unprivileged attacker can extract $0.00 from BloctoTokenStaking (Flow).**
> Confidence: **high**. Basis: (a) live-state reads at block 167,841,172–167,841,459; (b) full audit of all 5 live contracts at that account (~2.3k lines) plus their Cadence dependency sources; (c) a 50/50-check Cadence emulator PoC proving the freeze gate, the holder-withdrawal path, and entitlement isolation; (d) adversarial enumeration of 9 candidate paths — all closed. The nominal 100.7M BLT held for stakers (≈$111k at the last tracked price, **≈$0 realizable** — BLT is delisted with $1.93 total on-chain liquidity) is holder-only (38.68M, H-O) or admin-gated (62.05M, P).

---

## 3. Mechanism in exact terms

`BloctoTokenStaking` is a fork of Flow's `FlowIDTableStaking`, migrated to Cadence 1.0 (entitlements). Live code SHA-256 `a4beb07263c95473bd87699d6e131d21c5528720e04a03f1b89241943a655cb3` (full source: `analysis/BloctoTokenStaking.cdc`).

Data model (all in the contract account `0x0f9df91c9121c460`):

- `stakers: @{UInt64: StakerRecord}` — contract field; each `StakerRecord` holds four BLT vaults: `tokensStaked`, `tokensCommitted`, `tokensUnstaked`, `tokensRewarded`, plus `tokensRequestedToUnstake` (`BloctoTokenStaking.cdc:87-168`).
- `Staker` resource — one per staker ID, **stored inside the holder's `BloctoPass` NFT** (`BloctoPass.cdc:137`, created at mint via `stakingAdmin.addStakerRecord(id:)` in `NFT.init`, `BloctoPass.cdc:179-187`).
- `Admin` resource — stored at `/storage/bloctoTokenStakingAdmin` in the contract account (`BloctoTokenStaking.cdc:630-635`); gates `addStakerRecord`, `startNewEpoch`, `startStakingAuction`, `endStakingAuction`, `payRewards`, `moveTokens`, `setEpochTokenPayout`, `createNewAdmin` (all `access(AdminEntitlement)`).
- `stakingEnabled: Bool` — the freeze switch. Live value **`false`**. All of `stakeNewTokens`, `stakeUnstakedTokens`, `stakeRewardedTokens`, `requestUnstaking`, `unstakeAll` and `addStakerRecord` begin with `pre { stakingEnabled }` (lines 230, 245, 269, 281, 318, 360). `withdrawUnstakedTokens` (line 333) and `withdrawRewardedTokens` (line 341) have **no such precondition**.
- Rewards: admin calls `payRewards(stakerIDs)` after `endStakingAuction`; it mints `tokensStaked.balance × (epochTokenPayout/totalStaked)` per named staker into **that staker's own** `tokensRewarded` vault, with a per-epoch `{String: Bool}` dedup map (lines 398-437). There is no share pool an outsider can dip into.
- Unstaking: holder calls `requestUnstaking` (frozen-gated) → admin `moveTokens` moves staked→unstaked → holder calls `withdrawUnstakedTokens` at any time.

Gates that close the finding (all verified live + in the emulator PoC):

| # | Gate | Where |
|---|---|---|
| G1 | Staker methods require `StakerEntitlement`; the only `Staker` lives as a private field inside the holder's NFT; the NFT's staking methods require `BloctoPassPrivateEntitlement`; `Collection.borrowBloctoPassPrivate` requires `CollectionPrivateEntitlement`, obtainable only by the account that owns the collection storage | `BloctoTokenStaking.cdc:227-347`, `BloctoPass.cdc:61-88, 386-392, 455-469` |
| G2 | Admin methods require `AdminEntitlement`; Admin resource in the contract account; **no public capability** (`/public/bloctoTokenStakingAdmin` does not exist — probed) | `BloctoTokenStaking.cdc:352-489` |
| G3 | `stakingEnabled=false` (live) blocks staking, unstaking requests and new staker registration | live read + emulator PoC C1/C2 |
| G4 | The only public write surface — `/public/bloctoPassMinter` (borrowable `&{BloctoPass.MinterPublic}`, `mintBasicNFT` is `access(all)`) — reverts while frozen because `NFT.init → addStakerRecord` fails its precondition; when unfrozen it mints an **empty** pass (id = totalSupply, zero tokens) — no theft | `BloctoPass.cdc:496-538`, PoC C1 |
| G5 | Contract updates require the contract account's key: 1 active key (index 0, weight 1000, ECDSA secp256k1/SHA3-256, seq 291); key 1 revoked | `GET /v1/accounts/0f9df91c9121c460?expand=keys` |

---

## 4. Live-state assessment (read-only, exact blocks)

| Read | Block | Value |
|---|---|---|
| `BloctoTokenStaking.getStakingEnabled()` | 167,840,658 | **false** (frozen) |
| `getTotalStaked()` | 167,840,658 | 62,003,651.68051645 BLT |
| `getStakerIDCount()` | 167,840,658 | **29,762** records |
| `getEpoch()` / `getEpochTokenPayout()` | 167,840,658 | 208 / 125,000 BLT |
| `BloctoToken.totalSupply` | 167,840,658 | 375,999,852.53065610 BLT (= 350M genesis + 25,999,852.53 minted ≈ 208 epochs × 125k rewards) |
| Contract-account default BLT vault | 167,840,658 | 91,708,956.07304526 BLT (public balance cap) |
| Public capability probe | 167,840,740 | `/public/bloctoPassMinter` exists **and borrows as `&{BloctoPass.MinterPublic}`** (cap id 6); `/public/bloctoPassCollection`, `/public/bloctoTokenReceiver`, `/public/bloctoTokenBalance`, `/public/bloctoPassStampCollection` exist; `/public/bloctoTokenStakingAdmin` **absent**; `/public/bloctoPassStampMinter` absent |
| **Full enumeration of all 29,762 staker records** (sum of the four vaults per record) | 167,841,172 | **sumStaked = 62,003,651.68051645** (matches the contract field exactly) · **sumUnstaked = 34,731,383.27438927** · **sumRewarded = 3,953,256.41689412** · sumCommitted = 44,400.67102344 · sumRequestedToUnstake = 7,347,018.58957543 · records with staked>0: **2,792** · records with any tokens: **3,216** |
| `BloctoPass.totalSupply` / contract-account's own pass collection | 167,841,459 | 29,762 / **empty** (no team passes parked in the contract account) |
| Concentration (48 records > 100k BLT) | 167,841,459 | 56.66M staked (91.4%), 33.51M unstaked (96.5%), 3.62M rewarded (91.6%) — single whale `#836` holds **28.70M unstaked**; `#941` 10.0M staked + 2.12M rewarded; `#942` 5.60M staked all pending unstake; `#873` 5.0M staked |
| `BloctoTokenSale` import probe | ~167,840,790 | **fails to load**: ``error: `pub` is no longer a valid access modifier … This is pre-Cadence 1.0 syntax`` → bricked (S) |

Code hashes (from live account state): `BloctoTokenStaking a4beb07263c95473…`, `BloctoPass 2054631f10deccf7…`, `BloctoToken 0490f2fae8e1be28…`, `BloctoPassStamp dba9d701334b2cf7…`, `BloctoTokenSale d06aa0d98561096e…`.

**Prices.** BLT is dead as a market: CMC status `untracked`, 0 market pairs, 24h volume 0, `totalOnchainLiquidity` **$1.93** (one PancakeSwap-v2 BLT/BUSD pool `0xc1129bd3fd1405a01a46cec0560dd42eab9af240` on BSC; live reserves 815,441.58 BLT / 1.5301 BUSD → **$1.876e-6/BLT**). Last CMC-tracked close: **$0.00110384** (2025-08-31, zero volume). Secondary on-chain reference: IncrementFi BLT oracle $0.0001 (prior snapshot, block 167,313,115). Nominal figures below use the last CMC price; **realizable value is ≈$0** at any size.

Nominal USD (last CMC price $0.00110384): H-O **$42,701.62** · P **$68,491.07** · contract vault **$101,231.93** · whole staker ledger **$111,192.69**. At the live pool price: H-O $72.59 · P $116.43 — i.e. nominal only; the pool cannot absorb even a fraction of one whale's bucket.

---

## 5. What an attacker can / cannot do (all paths tested)

| # | Candidate path (fresh attacker, no keys) | Result | Exact gate / evidence |
|---|---|---|---|
| 1 | Mint a `BloctoPass` via the public minter capability to obtain a `Staker` resource | **Reverts while frozen** | `mintBasicNFT → NFT.init → Admin.addStakerRecord` pre-condition: `Cannot register a staker operator if the staking auction isn't in progress` (PoC C1, full stack trace) |
| 2 | Same mint after an unfreeze | **Succeeds but worthless** | New pass id = `BloctoPass.totalSupply` (29,762 unused), all four vaults 0.0, no other record touched (PoC C1) |
| 3 | Borrow someone else's pass/collection private refs and withdraw their buckets | **Impossible** | Checker: ``has no member `borrowBloctoPassPrivate` `` through the public cap; narrowing to plain `&BloctoPass.Collection` → ``requires `CollectionPrivateEntitlement` authorization, but reference is unauthorized`` (PoC C3) |
| 4 | Reach the staking `Admin` (payRewards/moveTokens/startStakingAuction/…) | **Impossible** | No public capability; cross-account storage borrow: ``access denied … requires `Storage | BorrowValue` authorization``; admin borrow probes return nil (PoC C3) |
| 5 | Drain the contract account's 91.7M BLT default vault via `/public/bloctoTokenReceiver` | **Impossible** | Capability is unentitled `&BloctoToken.Vault`; `withdraw` is `access(FungibleToken.Withdraw)` (`BloctoToken.cdc:156-161`) — compile-time blocked |
| 6 | Claim other stakers' `tokensUnstaked`/`tokensRewarded` | **Impossible** | Every `Staker.*` method operates on `self.id` only; the record is borrowed from the contract field, and withdrawal references are `access(contract)` (`BloctoTokenStaking.cdc:146-166, 333-347`) |
| 7 | Capture past rewards as a fresh staker | **Impossible** | Rewards are minted per named staker ID by the admin into that staker's own bucket with a per-epoch dedup map (`BloctoTokenStaking.cdc:398-437`) — no share pool, no retrospective claim |
| 8 | Force-replace a victim's `StakerRecord` via `addStakerRecord` (force-assign `<-!`) or a duplicate-ID NFT deposit | **Impossible** | `addStakerRecord` is admin-gated + frozen; NFT ids are monotonic from `BloctoPass.totalSupply`; `Collection.deposit` only accepts `@BloctoPass.NFT` |
| 9 | Use the bricked `BloctoTokenSale` (`purchase`/refunds) or its vaults | **Impossible** | Contract cannot load (pre-1.0 syntax); its vaults are unreachable until the contract account updates it (P) |

**Cost of the best candidate (path 1 when unfrozen):** a Flow tx fee (~1e-6 FLOW) for an empty pass — negative value. No capital, no flash loans, no MEV angle exists: there is no function that moves another party's value at all.

---

## 6. PoC / verification

- **Cadence emulator PoC (local only, no real-network writes):** `poc-cadence/` — deploys the **live contract sources** (BloctoToken, BloctoTokenStaking, BloctoPass, BloctoPassStamp + real mainnet dependency sources) on a throwaway Flow emulator and runs 3 claim suites: **50/50 checks PASS**.
  - **C1 (19 checks):** public-cap `mintBasicNFT` frozen → revert with the exact precondition message + full call stack; unfrozen → success with zero-balance pass. Supply unchanged after the frozen attempt.
  - **C2 (21 checks):** with `stakingEnabled=false` verified immediately before: `withdrawUnstakedTokens(50)` succeeds (bucket 50→0, owner wallet 900→950 BLT); `moveTokens`+`payRewards` credit 1.0 BLT; `withdrawRewardedTokens(1.0)` succeeds. Negative control: `stakeUnstakedTokens` reverts `Cannot stake if the staking auction isn't in progress`.
  - **C3 (5 checks):** entitlement isolation — private/entitled borrows all nil or checker-rejected; admin probes nil; public positive control non-nil.
  - Artifacts: `ci-out/cadence-poc/poc_result.json`, `poc.log`, `checks.jsonl`, `evidence/*.out` (57 raw CLI outputs).
- **Live-state scripts (public Flow Access REST, read-only):** `analysis/scripts/*.cdc` + `analysis/{flowscript.py, enumerate_stakers.py, top_holders.py, sample_events.py, scan_events_parallel.py}`; results in `analysis/` and `ci-out/live/`.
- **CI run(s):** see `ci-out/ci_urls.txt` (GitHub Actions on `artsbykriss/ca-zombie-ci`, workflow `poc.yml`, branch `blocto-staking`); CI re-runs the enumeration, the concentration analysis, 500k-block event scans and the emulator PoC.
- **Reproduce locally:** `python3 analysis/flowscript.py analysis/scripts/global_state.cdc`; `bash poc-cadence/run.sh`.

---

## 7. Verdict, residual & latent risk

**E-U = $0.00 (high confidence).** No unprivileged value-extraction path exists. The only public write surface is neutralized by the freeze and, even unfrozen, produces nothing of value. The 100.7M BLT in staker records is strictly holder-scoped (38.68M withdrawable now, 62.05M requiring the admin) and the 91.7M BLT treasury vault is contract-account-only.

Split (nominal at last CMC price $0.00110384; realizable ≈ $0):
- **E-U: 0 BLT = $0.00**
- **H-O: 38,684,639.69 BLT = $42,701.62** — pass holders may withdraw unstaked/rewarded buckets at any time even while frozen (PoC C2). Caveat: Blocto's wallet shut down 2025-12-18; holders who never migrated keys cannot exercise this → that portion is effectively S.
- **P: 62,048,052.35 BLT = $68,491.07** (stakes; admin must resume + `moveTokens`) **+ 91,708,956.07 BLT = $101,231.93** (contract-account treasury vault). Both are contract-account-key-gated.
- **S: BloctoTokenSale vaults** (unknown amounts, unloadable contract) + orphaned records (unknown).

**Latent risk / watch items:**
1. **Contract-account key:** a single active key controls everything (192.4M BLT across records + vault at nominal $212k; realizable ≈$0). If that key is lost/compromised, the picture changes (P→E-U in the latter case). This is the single highest-impact latent item; monitor key-index/weight changes.
2. **Unfreeze:** if anyone with the key ever calls `startStakingAuction`, stakers could process the pending 7.35M requested unstake and the public minter becomes callable again — still no outsider theft, but holder exits become fully live.
3. **Bricked `BloctoTokenSale`:** its vaults are unrecoverable unless the contract account ships a 1.0 update preserving field layout (P-recovery).
4. **Flowdiver API is dead** (Vercel deployment gone) — future monitoring of this account should use the public Access API or another indexer.

**Blockers encountered:** public access node retains only recent block history for events (404 beyond ~50M blocks back) and caps event queries at 250 blocks, so the last-admin-activity date is bounded rather than exact: **zero** `NewEpoch` events in a dense 4,839-window scan of the last 1,209,600 blocks (~2 weeks, 2026-10-15), zero staking events in sampled windows across the last ~10M blocks (~4 months), and zero in the CI dense scans of the last 500k blocks × 4 event types; epoch 208 + 208×125k minted rewards place the last epoch cycle before Blocto's Dec-2025 shutdown. BLT has no live market → USD values are nominal.

## 8. Methodology & sources

- Live reads: `https://rest-mainnet.onflow.org` (public Access API; `getAccount`, `/v1/scripts`, `/v1/events`) at blocks 167,840,658–167,841,459 (2026-10-15). Contract sources dumped from account state (hashes above). No keyed endpoints used; no transactions signed/sent.
- Code audit: full source of the 5 contracts + `FungibleToken`/`NonFungibleToken`/`MetadataViews` deps; entitlement analysis per Cadence 1.0.
- PoC: local Flow emulator (Flow CLI 2.18.0) — see `poc-cadence/README.md`.
- Market data: CMC data-api (status/price/pools), live PancakeSwap pair reserves, IncrementFi oracle reference; Blocto shutdown reporting (wallet/BloctoSwap/Teleport ceased 2025-12-18, $5.5M losses).
- Corpus: `zombie_hunt/ZOMBIE-HUNT-II.md` L2-04 row (lead only; all facts re-verified).

**Caveats:** (1) USD values are nominal — BLT is delisted with $1.93 on-chain liquidity; (2) staker-ID→holder attribution was not possible without an indexer, so the H-O bucket is classified by code capability, not by identity (one whale `#836` holds 28.70M of it); (3) Flow EVM-side BLT representations were not exhaustively searched (no tracked pools exist; CMC liquidity is $1.93 total); (4) the emulator PoC proves the *logic gates* with the live sources; live mainnet state is proven separately by the reads above; (5) no transactions were ever sent to any real network.

## 9. Files index

```
blocto-staking/
├── README.md                     # this file
├── summary.json                  # machine-readable summary
├── analysis/
│   ├── BloctoTokenStaking.cdc    # live source dump (also BloctoToken/Pass/PassStamp/TokenSale)
│   ├── flowscript.py             # read-only Cadence script runner (public REST)
│   ├── enumerate_stakers.py      # 29,762-record enumeration driver
│   ├── staker_enum.json          # full aggregate result (block 167841172)
│   ├── top_holders.py/.json      # concentration analysis (>100k BLT records)
│   ├── big_holders.cdc           # per-slice large-record reader
│   ├── sample_events.py, scan_events_parallel.py, find_last_event.py
│   ├── scripts/*.cdc             # global_state, cap_probe, pass_state, sale_probe, staker_slice
│   └── epoch_scan*.json/log      # event scans (freeze dating)
├── poc-cadence/                  # local emulator PoC (50/50 checks) + run.sh + README
├── ci/run.sh                     # CI heavy job (re-verification + scans + PoC)
├── ci-out/                       # CI outputs: live/, cadence-poc/, ci_urls.txt
└── ci-artifacts/                 # CI artifact downloads
```
