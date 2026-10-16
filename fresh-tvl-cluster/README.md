# Z3-H17 · Fresh-TVL cluster (10 protocols, $2.87M–$8.94M each) — fork-drift / config-rot / rate-provider deep dive

**Date:** 2026-10-16 · **Chains:** Robinhood Chain (4663), Ethereum (1), BSC (56), Arc (5042), RISE (4153), Solana · **Status:** read-only; PoC fork-verified only; no mainnet transactions
**Scope (all 10 targets, all verified live & funded on-chain):** NaraUSD · SUBFROST · up v3 · Scorch · Icarus CL · HertzFlow · Longbow · Meridian Perps · Aero Lite · Fang
**Method:** 4 parallel child agents (one per subgroup) + parent consolidation and independent verification. Every protocol got: contract/chain resolution, class-specific screen (BoringVault rate-provider / frUSD mint-parity / Slipstream-fork drift / GMX-v2 config rot / tokenized-equity oracle-LLTV / sequencer-action validation / Tomb-fork farm math / single-key upgrade authority), live-state reads at explicit blocks, and a Foundry fork suite against live state (65 tests, **65/65 PASS**). Scorch is Solana → RPC evidence script instead of a forge test (no EVM component).

**DefiLlama TVL snapshot 2026-10-16 (fresh):** SUBFROST $8.94M · Icarus CL $8.03M · HertzFlow $7.10M · NaraUSD $6.82M · up v3 $4.72M · Scorch $4.28M · Longbow $3.25M · Aero Lite $3.20M · Meridian Perps $2.92M · Fang $2.87M — **cluster total ≈ $52.1M**.

---

## 1. TL;DR — per-protocol verdict

| # | target (chain) | live E-U now | why closed / open | E-U-conditional (trigger) | class totals |
|---|---|---|---|---|---|
| 1 | **NaraUSD** (ETH) | **$0.00** (high) | mint+redeem Keyring-gated (`hasValidCredentials(fresh)=false`, fork-proven `KeyringCredentialInvalid`); parity exact 1:1, 0 fees, no oracle; instant-redeem cap $1,959 USDC + $999.50 USDT; all roles = Safe | ≤ **$270** — Keyring opened/removed *and* Curve pool imbalance (mint at par → sell into `0xf05F1b7b…`) | H-O $2,958.50 instant · P $9,139,735 (Safe 3-of-5) |
| 2 | **SUBFROST** (ETH side) | **$0.00** (high) | every fund-moving selector `onlyAuth` (BIP340 FROST) / `onlyVault` / owner→vault; fork-proven garbage-sig reverts; accept-path proven with test key; replay guards live | none | P $58,387.84 ETH + ~$8.88M BTC trust · H-O 0 |
| 3 | **up v3** (Robinhood) | **$0.00** (high) | CLPool **byte-identical** to audited `aerodrome-finance/slipstream`; NPM/fee-modules canonical; gauges 2024-gen with `_stakes`/ownership guards; fork-proven `NA`/`NNFT`/`F0` negatives | M-01 acknowledged `voter.poke()` grief/redistribute (no direct caller payout; monetisation needs an existing veUP stake) | H-O $4,693,965 LP + $241.9k emissions · P $167,191 voter fee pots |
| 4 | **Scorch** (Solana) | **$0.00** (medium) | router instruction surface = `swap`/`swap2022` only (IDL + 35-tx census), all user-signed; vault PDA owned by router; no withdraw instruction exists | none identified (core pricing engine unverifiable — no IDL/source) | P ≈ **$4,259,772** single-key upgrade authority (`6km771…`, verified plain keypair) |
| 5 | **Icarus CL** (RISE) | **$0.00** (high) | old-gen Slipstream, verified sources at every layer, auth canonical; fork-proven `NNFT`/`NA`/`F0`; gauge registered but unfunded (`rewardRate=0`); NPM ETH 0 | none live | H-O $8,067,346 LP (99.4% one USDR/USDC.e pool) |
| 6 | **HertzFlow** (BSC) | **$0.00** (high) | wrapped-bank parity exact (reserves ≥ supply, burn-then-pay, caller-scoped); mint permissioned (`isMintCaller`); redeem caller-locked; fork-proven 8/8 | ≤ donation size (live **$20** USD1) — permissionless `makeExternalCalls` mints *un-synced surplus only* to the DepositVault; capture needs winning the next-deposit race | H-O $7.11M · P $7.11M (admin Safe 3-of-N) |
| 7 | **Longbow** (Robinhood) | **$0.00 material** (high) | 16 "pool" feeds are **300-s Uniswap-V3 TWAPs** (fork-proven: +54% slot0 move → 0 bp feed move); 37 markets on operator-driven Chainlink proxies; Loopback oracle clamped (`0.9×TWAP` floor/5×floor cap); singleton idle liquidity ≈ $115k caps borrow-side attacks | **+$654** arithmetic EV on STONKBROKER (needs 5-min distortion; immaterial, not executed); flips material if any market's idle liquidity outgrows its pool depth | H-O $1.09M supplied · P $1.09M (feed operators) |
| 8 | **Meridian Perps** (Robinhood) | **$0.00** (high) | `processActions` `onlySequencer` (fork-proven `NotSequencer`); historical batch replay → `ActionAlreadyProcessed` (monotonic ids); EIP-712 + nonces + expiry + ERC-1271 strict; withdraw user-sig enforced at finalize; merUSD exactly 1:1 (supply == USDe backing) | none | P: single-EOA sequencer + 2-of-3 Safe (control over $1.73M collateral accounting; liveness) |
| 9 | **Aero Lite** (Arc) | **$0.00** (high) | factory+pool+linked library **byte-identical** to `dromos-labs/metadex-slipstream-public`; **no gauge layer at all** (`voter=0`, registry gaugeFactory=0, all pools gauge=0/nft=0); admin fork-proven reverts | none live (re-arms only if governance registers a gauge factory / malicious hook — P) | H-O $3,202,689 LP · P 0 |
| 10 | **Fang** (Robinhood) | **$0.00** (high) | canonical Tomb math (round trip −2% fee, fork-proven); 0/16 fee-on-transfer tokens; `convert()` unset; xGFANG redeem disabled; Masonry empty; Treasury pre-start | **FangRedeem** permissionless fixed **$1.00/FANG** payout — pot **$0 today** (fork-drained demo: $1,000 in one call); re-arms when `USDG.balanceOf(FangRedeem) > 0` **and** FANG < $1 | H-O $2,862,057 genesis principal · P $2,862,057 (owner EOA) |

## 2. Total live extractable now

> **E-U (external unprivileged, live, net of costs): $0.00 — confidence high** (9/10 high; Scorch medium because the core AMM's pricing internals have no public IDL/source, but no unprivileged path exists in the only spendable instruction surface).
>
> **E-U-conditional (all quantified with triggers):** NaraUSD ≤ **$270** (Keyring-off + pool arb) · HertzFlow ≤ **donation size** (live $20; destination-locked mint + race) · Longbow **+$654** arithmetic (immaterial, unexecuted) · Fang = **FangRedeem pot at trigger** ($0 today; unbounded by contract when funded) · up v3 M-01 poke (redistribution; caller needs veUP stake to gain).
>
> **H-O (self-service recoverable, aggregate): ≈ $27.37M** — LP principal + gauge emissions + vault/farm principal + instant redemptions (see per-protocol sections).
> **P (privileged/key-holder at risk, aggregate, overlaps H-O by construction): ≈ $35.4M** — dominated by Scorch $4.26M (single-key upgrade), NaraUSD Safe $9.14M, SUBFROST $8.94M (FROST group key), HertzFlow $7.11M, Fang $2.86M, Meridian (single-EOA sequencer), Longbow feeds, up v3 voter pots. **S: $0 material** (dust/donations only).

## 3. Live-state verification (cluster reads 2026-10-16)

All reads keyless public RPC (`cast`/curl) at: **Ethereum 26,202,778 · Robinhood Chain 89,804,365 (`eth_blockNumber` space) · Arc 26,207,240 · RISE 24,520,097 · BSC 127,916,619 · Solana slot 457.5M**. A CI snapshot is re-generated per run into `ci-out/live_state.json` (artifact).

| check | live value | meaning |
|---|---|---|
| `FangRedeem.balanceOf(USDG)` `0x6EF1e6…6F47` | **0** | conditional drain disarmed today |
| `GenesisFarm.poolEndTime()` / `owner()` | 1,792,602,000 (2026-10-21 17:00 UTC) / EOA `0x608730…` | convert window + owner key |
| `MCT.totalSupply()` | 9,839,512.46e18 | NaraUSD supply; booked collateral 1,959.00 USDC + 999.50 USDT |
| `frUSD.totalAssets(0)/(1)`, `defaultPublicKey()` | 617,294,561 / 57,770,549,243 / `0xb6a6cf51…` | SUBFROST custody + single FROST key |
| up v3 `allPoolsLength` / `capMode`/`pendingCapMode` | 1,923 / 2 / 2 | core pools; M-03 not armed |
| Aero Lite `voter()` / `allPoolsLength` | `0x0` / 35 | no staking layer |
| Icarus `allPoolsLength` / `owner()` | 10 / Safe proxy `0x838fc415…` | live CL deployment |
| HertzFlow HFUSD1 bank vs supply | 7,079,499.92 vs 7,079,479.92 | **+20.0 USD1** un-synced surplus (the live conditional) |
| Longbow Morpho USDG balance | $53,729 | singleton idle liquidity (caps borrow-side) |
| Meridian merUSD supply vs USDe backing | 1,733,782.135870236e18 == 1,733,782.135870236e18 | exact 1:1 |
| Scorch program authority / PDA accounts | `6km771w…` (plain keypair) / 38 SPL + 13 Token-2022 | single-key upgrade + $4.26M inventory |

---

## 4. Per-protocol sections

### 4.1 · NaraUSD (Ethereum) — BoringVault rate-provider / multi-collateral mint
- **Addresses:** MCT `0x4eD90999f558Fdc28606b7F7f9AFc7044befb803` (impl `0xD8E8C72A…`) · NaraUSD `0x5C6263904CCFD3Bcf1aAa6e7063dDd29743b3Bb7` (impl `0x87cF5006…`) · NaraUSD+ `0x1aa23CDFC941f6b54251C72012A9Bfa4bF5394D6` · Keyring `0xb0B5E217…` (policy 15,713,807) · Safe `0xaB05c0DB…` (3-of-5) · Blackopal LiquidStone II BoringVault `0x15e2579B…` + accountant `0xda594876…`.
- **Mechanism:** mint/redeem are pure 1:1 decimals normalisation (no oracle, no fees). Both directions check Keyring credentials — a fresh address is rejected (`KeyringCredentialInvalid`, fork T3). MCT role-gated (`MINTER`=NaraUSD only, `COLLATERAL_MANAGER`=Safe). The BoringVault is a *strategy*, not collateral (`isSupportedAsset(BV)==false`); its accountant rate (1.1534e18) cannot move a single NaraUSD and `updateExchangeRate` is `requiresAuth` (fork T7).
- **Verdict:** **E-U $0.00 (high).** Even with a total Keyring bypass, the mint→redeem round trip delta is exactly 0 (fork T8) and instant redemption is capped by booked collateral ($2,958.50); the only monetisable shape is the ≤$270 Curve-imbalance arb. **Solvency note (user-facing, not an attack):** live backing $9,139,735 vs supply → **92.89% covered; gap ≈ $699.8k** ($500,009 USDT to an EOA now at $0; −133,022 mGLO migration shortfall). DL under-counts ~$2.32M (lists deprecated mGLOBAL wrapper).
- **PoC:** `poc/test/NaraUSD.t.sol` 9/9 PASS. Full detail `analysis/narausd/README.md`.

### 4.2 · SUBFROST (Ethereum side) — frUSD custody vault + Curve 3pool strategy
- **Addresses:** vault proxy `0x95779e7e…` → impl `0x5376beed…` (Sourcify exact) · strategy `0x5c5d66c8…` · 3CRV `0x6c3f90f0…` · Curve 3pool `0xbEbc4478…`.
- **Mechanism:** `depositAndBridge` is the only public selector (caller's own USDC/USDT, 1.99 flat + 10 bps, one-way). Every fund-moving path is `onlyAuth` — BIP340 Schnorr over `keccak(abi.encode(data, nonce, chainid, this))` with full-coordinate verification — or `onlyVault` (immutable) / owner→vault. The FROST key gates **withdrawals and UUPS upgrades**. Fork T5 stored a test pubkey to prove the accept path (exact payouts 97,911,990 / 897,111,990; replays rejected).
- **Verdict:** **E-U $0.00 (high).** P = $58,387.84 ETH-side (vault+strategy) + ~$8.88M BTC-side signing-group trust. The screening's "impl unverified" flag is corrected (Sourcify exact matches).
- **PoC:** `poc/test/Subfrost.t.sol` 5/5 PASS. Full detail `analysis/subfrost/README.md`.

### 4.3 · up v3 (Robinhood Chain) — Slipstream v2 fork drift
- **Addresses:** CLFactory `0x1ac9dB4a…` (1,923 pools; owner Safe 2-of-4 `0x0eEA30aB…`) · CLPool impl `0x11725976…` · NPM `0x07F44c47…` · Voter `0x7F749fDD…` (cap-mode) · gauges 91 live (870,817 UP ≈ $241.9k pending) · fee pots $167,190.96.
- **Mechanism/drift:** CLPool runtime is **byte-identical** (metadata-stripped) to `aerodrome-finance/slipstream` main; NPM source == upstream; fee modules byte-identical; gauge pair is the 2024 pre-penalty generation with identical auth (`_stakes[msg.sender]`, NFT ownership). No skim; foreign collect reverts `NNFT`; flash no-repay `F0`; repay leaves attacker +0 and pool +exactly the 1% fee.
- **Verdict:** **E-U $0.00 (high).** The only acknowledged unprivileged class is **M-01** (`voter.poke()` on a decayed-lock veNFT zeroes current-epoch Reward checkpoints → redistribution to other depositors; caller gains nothing directly — fork-proven permissionless on id 16). **M-03** (cap-mode bypass) is not armed (`capMode == pendingCapMode == 2 Enforced`). H-O $4.69M LP + $241.9k emissions; P voter pots + Safe.
- **PoC:** `poc/test/UpV3.t.sol` 9/9 PASS. Full detail `analysis/upv3/README.md` (+`bytecode-verification.md`).

### 4.4 · Scorch (Solana) — single-key upgrade authority (P)
- **IDs:** program `SCoRcH8c2dpjvcJD6FiPbCSQyQgu3PcUAWj2Xxx3mqn` · ProgramData `5TXQj77q…` · upgrade authority `6km771wAtWmH16R8fsRp8zEUduDFPF1vtEXWTx4buiWZ` (**plain system-owned keypair**, 7.75 SOL, top-level signer — not a multisig/PDA) · vault PDA `EHcege7dok1iYs7SxL2XzDPvhg6XzMVcx2V5SkMUurJP` (38 SPL + 13 Token-2022 accounts, $4,259,772 priced; parent-verified count).
- **Mechanism:** the router's entire instruction surface is `swap`/`swap2022` (community shank IDL + census of 35 recent txs: only tags 0x01/0x02, all user-signed). Vault accounts are PDA-owned — only the router can sign for them, and no instruction transfers vault funds except against a user's in-side transfer. Core AMM `ojh19oja…Corch` has no public IDL/source (stated as unknown, not as a path).
- **Verdict:** **E-U $0.00 (medium — no concrete path found; pricing internals unverifiable).** **P ≈ $4.26M** via one signed upgrade; secondary P: core authority `F6qazjHE…`. Monitors: ProgramData authority change, new deploys (slot > 425,743,288), new instruction tags, one-sided PDA outflows.
- **Evidence:** `analysis/scorch/scorch_evidence.sh` + `raw/**` (re-runnable, keyless). Full detail `analysis/scorch/README.md`.

### 4.5 · Icarus CL (RISE) — old-generation Slipstream deployment
- **Addresses:** factory `0x6f7DA11c…` (10 pools; owner Safe proxy `0x838fc415…`) · pool impl `0x4356B934…` · NPM `0x195D3037…` · CLGaugeFactory `0x42ac2D74…` · gauge `0xbdf33a22…` (unfunded).
- **Mechanism/drift:** verified sources at every layer; diffs vs upstream Slipstream are cosmetic (old-gen initialize, `tokens()` view, SLOAD cache). Auth canonical: 6-arg collect/4-arg burn `onlyNftManager`; stake/collectFees `onlyGauge`; flash before/after balance checks. Gauge `rewardRate=0`/`periodFinish=0`.
- **Verdict:** **E-U $0.00 (high).** H-O $8,067,346 LP — 99.4% in one USDR/USDC.e pool `0xCBc0c0d2…` ($8,017,213). No live emissions; NPM ETH 0.
- **PoC:** `poc/test/IcarusCL.t.sol` 7/7 PASS. Full detail `analysis/icaruscl/README.md`.

### 4.6 · HertzFlow (BSC) — GMX-v2 fork config rot + wrapped-bank parity
- **Addresses:** DataStore `0xc244A37A…` · Reader `0xFC370bA1…` · ExchangeRouter `0x61e1116a…` · executor `0x95d312da…` · banks `0x00ceA665…` (U) / `0xAB96931f…` (USD1) · HFUSD `0x7F7AD43d…` / HFUSD1 `0x026C39Ab…` · admin Safe `0x2492bD5a…` (3-of-N).
- **Mechanism/config:** `HFBank.mint(receiver)` is permissioned (`isMintCaller`) and mints **only** `balance − recordedUnderlyingBalance` to a whitelisted receiver. The router's `makeExternalCalls` **is permissionless** and executes as the executor — which holds `isMintCaller` on both banks — but no RoleStore roles (DataStore writes revert `Unauthorized(executor,"CONTROLLER")`, fork T2). Market config is partially populated (`MAX_LEVERAGE=0`, $1 min-collateral, PRICE_FEED keys unset; provider-fed oracle).
- **Verdict:** **E-U $0.00 (high).** E-U-conditional = any un-synced donation (live **$20** USD1): anyone can then mint the surplus — but **to the DepositVault**, and capture needs the next-deposit race; minting to self is impossible (fork T4). Design smell flagged: a static executor with standing privileges running arbitrary caller calldata.
- **PoC:** `poc/test/HertzFlow.t.sol` 8/8 PASS. Full detail `analysis/hertzflow/README.md`.

### 4.7 · Longbow (Robinhood Chain) — tokenized-equity Morpho oracle/LLTV
- **Addresses:** Morpho Blue singleton `0x9D53d5E3…` (standard, verified) · 55 curated market ids (adapter list) · 54 oracle contracts · "Loopback" oracle `0xCDE95990…` (WSNET markets).
- **Mechanism:** the 16 unverified "Uniswap V3 Pool Price in USD" feeds were heimdall-decompiled: they read `observe([300,0])` — a **300-second TWAP** — quoted through a WETH/USD Chainlink proxy. Fork-proven: a +54% same-tx `slot0` move changes the feed by **0 bp**. The Loopback oracle is `clamp(0.9×TWAP, floor, 5×floor) × index` (verified; fork-reconstructed exactly). All equity majors ride operator-driven Chainlink-style proxies; Morpho itself performs **no staleness check** (freshness fully delegated to feeds).
- **Verdict:** **E-U $0.00 material (high).** Per-market EV formula computed: `EV = idle − idle/(LLTV×F) − 2×fee×notional(F)`; best arithmetic case STONKBROKER **+$654** (needs 5-min distortion; immaterial/unexecuted). Singleton idle liquidity ≈ $115k caps all borrow-side paths. H-O $1.09M supplied; P feed operators.
- **PoC:** `poc/test/Longbow.t.sol` 7/7 PASS. Full detail `analysis/longbow/README.md`.

### 4.8 · Meridian Perps (Robinhood Chain) — sequencer-action validation
- **Addresses:** gateway proxy `0xD540F47F…` → impl `0x0f17d846…` (verified) · handlers ActionHandler `0xEB9a61e3…`, CollateralManager `0x71925607…`, PerpEngine `0x94e37b0a…` · merUSD `0xad221259…` · sequencer EOA `0x39f7e293…` · owner Safe 2-of-3 `0xF8067d8c…`.
- **Mechanism:** `processActions` is `onlySequencer`; actions carry monotonic ids; user-authorising actions verify EIP-712 (domain `Meridian/1/4663/gateway`) with per-action nonces, expiry buffers, Solady ECDSA (`recovered == sender != 0`) and a strict ERC-1271 path. Withdrawals are two-phase with the user signature enforced at `finalizeWithdraw`. A **real historical batch replayed on a fork**: attacker → `NotSequencer`; sequencer → `ActionAlreadyProcessed`. Direct handler calls are inert (own storage). merUSD wrap/unwrap 1:1 with USDe (supply == backing exactly, parent-verified).
- **Verdict:** **E-U $0.00 (high).** Dominant residual risk is **P: a single-EOA sequencer hot key** (matching/funding/PnL/liquidations/withdraw initiation — cannot finalize withdrawals without user sigs) + 2-of-3 Safe owner.
- **PoC:** `poc/test/Meridian.t.sol` 7/7 PASS. Full detail `analysis/meridian/README.md`.

### 4.9 · Aero Lite (Arc) — Metadex Slipstream deployment
- **Addresses:** factory `0xb89Df768…` (35 pools; owner Safe-style `0x6b031ac7…`) · pool impl `0x0Df9fc87…` + linked library `0x22557c01…` · registry `0xCe44907D…` · swap hook `0xaAf16400…`.
- **Mechanism/drift:** factory+pool+library are **byte-identical** to `dromos-labs/metadex-slipstream-public` (compiled against chain code, immutables/link addressed). There is **no gauge/voter/NPM layer**: `voter()=0`, registry `targetFactoryToGaugeFactory(factory)=0`, every pool `gauge=0/nft=0/stakedLiquidity=0`, so `setGaugeAndPositionManager` is unreachable. Fork-proven admin/collect/stake negatives (`NNFT`/`NG`/`NGF`).
- **Verdict:** **E-U $0.00 (high).** H-O $3,202,689 LP (cirBTC/USDC $1.11M; WETH/USDC $1.10M). Caveat: Arc native-token precompiles block in-fork transfers (positive flash-repayment test replaced by fee-bound assertions).
- **PoC:** `poc/test/AeroLite.t.sol` 6/6 PASS. Full detail `analysis/aerolite/README.md`.

### 4.10 · Fang (Robinhood Chain) — Tomb-lineage genesis farm
- **Addresses:** GenesisFarm `0xC01B6891…` (16 pools, $2,862,057 priced) · gFANG `0x6376010d…` · xGFANG `0x6D60D2B9…` · FANG `0x9E773948…` · **FangRedeem `0x6EF1e61E39195fA53189A9A880A89eF1D06E6F47`** · Masonry `0x33Be1708…` · owner EOA `0x608730…`.
- **Mechanism:** canonical Tomb GenesisPool math + a 2% deposit fee; fork-proven round trip −20.00 on 1,000 USDG; 0/16 fee-on-transfer tokens; reward-debt canonical. `convert()` unset (`convertible==0x0`), xGFANG `redeemingEnabled=false`, Masonry empty (donations stranded), Treasury pre-start (Oct 21). **The one real defect:** `FangRedeem.redeemFang` pays a hard-coded **$1.00/FANG to any caller**, no caps — currently disarmed only because its USDG balance is **0** (parent-verified); a funded pot was drained ($1,000) in one fork call.
- **Verdict:** **E-U $0.00 (high).** E-U-conditional: trigger `USDG.balanceOf(FangRedeem) > 0` **and** FANG obtainable < $1 (post-TGE market or armed convert window); value = pot balance. Secondary: `GenesisFarm.convert()` opens Oct 21 if owner arms it (owner-priced → FCFS arbitrage risk).
- **PoC:** `poc/test/Fang.t.sol` 7/7 PASS. Full detail `analysis/fang/README.md`.

---

## 5. PoC / fork verification

- **Project:** `poc/` (Foundry 1.8.5, solc 0.8.26, cancun; forge-std vendored; `poc/src/ForkHelper.sol` for keyless multi-RPC fork selection — fixed after children reported a `VM_ADDRESS` redeclaration build error).
- **Tests: 65 total, 65 PASS** (local: `Ran 9 test suites in 108.07s — 65 tests passed, 0 failed`). CI run: see §7.
- Test files: `UpV3.t.sol` (9) · `AeroLite.t.sol` (6) · `IcarusCL.t.sol` (7) · `NaraUSD.t.sol` (9) · `Subfrost.t.sol` (5) · `HertzFlow.t.sol` (8) · `Longbow.t.sol` (7) · `Meridian.t.sol` (7) · `Fang.t.sol` (7). Scorch: `analysis/scorch/scorch_evidence.sh` (RPC evidence, no EVM).
- Key negative proofs (all fork-executed): foreign NPM collect → revert; pool 6-arg collect → `NNFT`; flash no-repay → `F0`; flash repay ⇒ attacker +0; gauge withdraw/deposit → `NA`/`NG`; Keyring → `KeyringCredentialInvalid`; FROST garbage sigs → `InvalidSignature`; bank mint → `ZeroAmount`; `makeExternalCalls(DataStore)` → `Unauthorized(executor,"CONTROLLER")`; attacker batch replay → `NotSequencer`; third-party finalize → `Unauthorized`; Fang round trip −2%; FangRedeem live revert `Insufficient USDC`; Longbow same-tx +54% pool move → 0 bp oracle move.
- **State-override positives (proving the accept/gated paths are otherwise correct):** SUBFROST T5 (test FROST pubkey stored → exact payouts, replays rejected); FangRedeem funded-pot demo; Longbow Loopback formula reconstruction to the wei.
- **CI artifacts:** `ci-out/live_state.json` + `ci-out/live_state.txt` (per-run live snapshot; see §7).

## 6. Verdict and residual/latent risk; blockers

- **E-U today: $0.00 — high confidence** (9 high, Scorch medium on core internals only). Every candidate path per class was reduced to a concrete call sequence, gated by a live-read guard, or fork-falsified.
- **Re-arm monitors (exact):**
  1. `USDG.balanceOf(0x6EF1e61E39195fA53189A9A880A89eF1D06E6F47) > 0` (FangRedeem) → E-U-conditional drain (value = pot).
  2. `Keyring.checkCredential(15713807, <fresh>) == true` on NaraUSD → ≤$270 arb.
  3. HertzFlow `balanceOf(bank) > recordedUnderlyingBalance()` on `0x00ceA665…`/`0xAB96931f…` → surplus mint (DepositVault + race).
  4. up v3 `pendingCapMode != capMode` → M-03 window; `poke()` on zero-weight veNFTs → M-01 griefing.
  5. Scorch ProgramData `authority` change or any new deploy > slot 425,743,288; new instruction tags ≠ {0x01,0x02}; one-sided PDA outflows.
  6. Longbow: per-market `EV = idle − idle/(LLTV×F) − 2×fee×notional(F)` flips positive → manipulation becomes economic; stale DON feed > 24 h.
  7. Fang `GenesisFarm.convertible() != 0` or block time ≥ 1,792,602,000 → convert window review.
  8. Meridian sequencer address change / pending-withdraw storms; SUBFROST `defaultPublicKey` change; NaraUSD Safe role/Keyring config changes.
- **Blockers/caveats:** Arc native-token precompiles block in-fork transfers (Aero Lite positive-path test replaced by fee-bound assertions); Robinhood main RPC refuses `eth_getLogs` (Etherscan V2 used for logs; the chain's header block space differs from `eth_blockNumber` — both cited); BSC router/handlers unverified (Etherscan V2 free tier unavailable for 56; ABI reconstructed from the protocol SDK, DataStore/banks verified via Sourcify); Longbow pool feeds unverified (heimdall decompile + structural reads); Scorch core program has no public IDL/source; RISE has no Etherscan V2 support (Blockscout used); prices are point-in-time DefiLlama.
- **Not investigated (out of scope, stated honestly):** BTC-side SUBFROST signing group (trust model, untouched); Meridian PerpEngine/Liquidation math (interface-level only); Scorch core AMM pricing; Longbow LP-vault economics beyond reads; fee-on-transfer/rebasing token risks for newly listed assets.

## 7. CI

- Workflow: `poc.yml` on `artsbykriss/ca-zombie-ci`, branch `fresh-tvl-cluster`; runs `ci/run.sh` (live-state snapshot → `ci-out/live_state.json`) then `forge test -vvv` (65 tests).
- **Run URL(s):** _pending — filled by the orchestrating agent after the run completes_ (also recorded in `summary.json` → `poc.ci_run_urls` and `ci-log.txt`).
- Local pre-CI run: 65/65 PASS (log preserved in `ci-out/live_state.txt` surroundings / see `poc` artifacts in CI).

## 8. Methodology & sources; files index

**Method:** read-only throughout; no transaction was signed or sent to any real chain; all exploit probes ran on Foundry forks of live state (or via RPC reads for Solana). Class screens: BoringVault rate-provider/mint-redeem parity (NaraUSD); frUSD mint-parity + FROST gate (SUBFROST); Slipstream-fork drift vs canonical upstream incl. byte-identity compile checks (up v3, Aero Lite, Icarus CL); GMX-v2 DataStore config + wrapped-bank parity (HertzFlow); tokenized-equity Morpho oracle/LLTV + TWAP manipulation (Longbow); sequencer-action validation incl. historical replay (Meridian); Tomb-fork farm math + convert/redeem traps (Fang); single-key upgrade-authority exposure (Scorch).

**Sources:** verified contract sources (Etherscan V2 chain 1/4663/5042; Sourcify v2 for Ethereum/BSC; RISE Blockscout), byte-identity compiles against upstream repos (`aerodrome-finance/slipstream`, `dromos-labs/metadex-slipstream-public`), protocol SDKs (HertzFlow frontend), community IDL (Scorch via `bitquery/solana-idl-lib`), DefiLlama prices/TVL, public RPCs only (no keyed URLs anywhere). Prior-corpus check: all 10 targets are new to the Z3 corpus (screening §7).

**Files:** `README.md` (this) · `summary.json` · `analysis/<protocol>/README.md` + `summary.json` + raw state dumps (`analysis/upv3/`, `aerolite/`, `icaruscl/`, `narausd/`, `subfrost/`, `hertzflow/`, `longbow/`, `meridian/`, `fang/`, `scorch/`) · `analysis/cluster/` (DL snapshot, adapter sources, chain/RPC facts) · `poc/` (Foundry project, 9 test files, ForkHelper) · `ci/run.sh` (live-state snapshot) · `ci-out/` · `ci-log.txt` · `ci-artifacts/`.
