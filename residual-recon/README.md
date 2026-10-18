# ZH4 Wave-B0 — residual reconciliation

**Date:** 2026-10-18 · **Mode:** read-only; no transactions signed or sent; no keyed RPC URLs or secrets in this folder · **Scope:** every candidate row and named prose/negative lead in `zombie-hunt-iv/wave1/r1–r7` and `zombie-hunt-iv/wave2/d2a–d2d`, plus residual leads inside `wave2/v*.md`.

**Purpose.** The ZH4 README is the campaign’s verdict layer. This pass checks that nothing in the working files was left without a disposition, locates the “contracts not located” rows, and surfaces candidates that still have **live funds + a plausible unprivileged extraction path today** for dedicated deep-dives. It does not deep-dive them.

## Headline counts

| Metric | Count |
|---|---|
| Named candidates enumerated | **612** |
| Rows/groups in the disposition table | 371 |
| Tier 1/2 findings (README) | 7 |
| Tier 3 LOW (README) | 40 |
| Closed / excluded / covered | **404** (README 61 · in-lane 175 · excluded 166 · ZH4-03 covered 2) |
| Parked (below-bar / unlocated / watch / trigger / P-class) | **151** |
| **OPEN** (actionable residual) | **10** |

No new Tier 1/2 finding was created; the existing three CRITICAL and four HIGH findings stand. The residual value is in the OPEN list below.

*Counting note: the 612 named entries are represented by 371 rows/groups (ranked rows + named prose/negative leads, including prior-corpus exclusion lists and dead-end classes). The full per-name table is `analysis/ALL-ROWS.md`; grouped rows carry the number of names they represent.*

## OPEN list — ranked by live funds × plausibility

| # | Target | Chain | Live funds (est) | Plausibility / confidence | Path | Next check |
|---|---|---|---|---|---|---|
| 1 | **Katana Vault Bridge / vbASSET stack** | Katana L2 <-> Ethereum | ~$27.7M reported L1 vault totalAssets (7.14M USDC + 3.07M USDT + 154.2 WBTC + 2,074.6 WETH; USDC leg staked in yieldVault 0xbeef... whose totalAssets is 9.43M USDC) + 6.67M L2 vbUSDC supply | MED-HIGH / MEDIUM | Unverified 1,718-byte LZ OApp mints/burns bridged vbASSETs. peers(30101)=0xb5bada... is set; lzReceive origin/peer binding and endpoint auth not decompiled. A forged/replayed message minting unbacked vbASSET has the L2 Yearn vault + DEX exit as immediate liquidity. L1 vault proxies hold dust; stakedAssets sits in yieldVault 0xbeef... (USDC leg verified totalAssets 9.43M), so the reported $27.7M is partly strategy custody and the 154.2 WBTC figure needs reconciliation vs r6's 33.68 WBTC. | Decompile L2 minter and L1 adapter; confirm lzReceive onlyEndpoint + peer(30101)/origin binding; fork-test forged message and replay; reconcile vbWBTC totalAssets vs strategy custody. |
| 2 | **Unnamed zkSync Era settlement vault 0x621425a1** | zkSync Era | ~$5.5M+ (1,121.26 ETH + 2,182,482 USDC + 181,232 USDT + 12.52M ZK) | MEDIUM / LOW-MED | 61.9KB unverified contract; public withdraw(address,address,uint256) reverts with Panic 0x11 for a zero-balance caller, so accounting is per-user; 199,874 txs / 118.8M transfers suggests a CEX/payment omnibus. If the accounting mapping is caller-settable or transferAndDeposit credits without custody, the vault drains. | Decompile withdraw/transferAndDeposit, map the accounting storage and auth, identify the operator (CEX vs protocol); check deposit/withdraw event reconciliation. |
| 3 | **JustLend Energy Rental (MarketG1)** | TRON | 1.56M TRX native (~$500k) + 3.46M TRX nominal security deposits (~$1.11M per r4) | MEDIUM / MED-LOW | rentResource/returnResource/liquidate/forceLiquidate are permissionless; live fee is 8% of rent, min-deposit orders can be liquidated almost immediately; the badDebt branch (deposit < fee) books a loss while paying the fee. Renter+identifier collusion plus return-after-liquidate double-refund is untested. | Fork-prove the liquidate -> returnResource sequence and the badDebt branch; measure per-cycle extraction vs 3.46M TRX deposits; check for a non-colluding path. |
| 4 | **Alchemix V3** | Ethereum, Arbitrum, Optimism, Base | $40.6M DL | LOW-MED / LOW | Fresh VaultV2 ERC-4626 (Apr 2026) created via permissionless createVaultV2; share math, first-redeemer/donation, harvest/withdraw roles and migration lens unreviewed. | Pick largest CreateVaultV2 vault; donation/first-redeemer test; read harvest/withdraw role gates. |
| 5 | **Curve LlamaLend V2** | Ethereum, Optimism | $42.1M DL | LOW / LOW | Fresh Jun-Jul 2026 LL v2 markets, new controller/AMM/vault blueprints and per-market oracles; soft-liquidation/partial-repay edge math unreviewed. | Enumerate markets + oracle params; quick soft-liquidation/partial-repay pass. |
| 6 | **Flex** | Ethereum | $1.9M DL (6 markets) | LOW-MED / LOW | Liquity-v1 fork with custom PriceOracle and exotic collateral feeds; redemption/bonus math deviates from canonical Liquity and is unread. | Read oracle aggregator (spot vs Chainlink, staleness, decimals); fuzz redemption at low TCR. |
| 7 | **JPYdf** | Ethereum | $849k DL | LOW-MED / LOW | receiveFromStrategy(declaredAmount) and claim(requestId) are unprivileged accounting entrypoints; backstop release/writeoff and redeem-queue pricing unreviewed. | Trace receiveFromStrategy shortfall handling + backstop release + writeoff; verify redeem queue pricing. |
| 8 | **zkSwap V2 (legacy zkSync AMM)** | zkSync Era | $533k DL; 48 pairs | LOW / LOW | Unverified UniV2-style factory/pairs; pair0 holds 8,926 USDC + 3.74 WETH. Fork drift in swap/fee/collect or a missing feeTo auth would be directly harvestable. | Decompile factory/pair, diff vs UniswapV2; check feeTo/setter auth, skim/sync, pair creation. |
| 9 | **DeepSwap** | Solana | $78.7k DL | LOW / LOW | Raydium cp-swap fork tied to DEEP launchpad; missing owner check on withdraw/fee-claim or fork-drift in deposit/withdraw fees would drain pool vaults. | Recover IDL/diff program vs Raydium cp-swap; verify fee-recipient withdraw instruction auth. |
| 10 | **Motoswap / VampChef** | Ethereum | $55.6k DL | LOW / LOW | Proxied MasterChef + revenue-share staking + new UniV2 registry; legacy accRewardPerShare/lpSupply accounting and emergencyWithdraw unread. | Read VampChef impl (EIP-1967), verify lpSupply sync + emergencyWithdraw; check MotoStaking lock math. |

### OPEN detail — addresses and blockers

**1. Katana Vault Bridge / vbASSET stack** — Katana L2 <-> Ethereum

- Live funds: ~$27.7M reported L1 vault totalAssets (7.14M USDC + 3.07M USDT + 154.2 WBTC + 2,074.6 WETH; USDC leg staked in yieldVault 0xbeef... whose totalAssets is 9.43M USDC) + 6.67M L2 vbUSDC supply
- Addresses: `L2 minter 0x807275727dd3e640c5f2b5de7d1ec72b4dd293c0; L1 vbUSDC 0x53E82ABbb12638F09d9e624578ccB666217a765e (impl 0xcc865b03..., yieldVault 0xbeefb9f61cc44895d8aec381373555a64191a9c4); L1 adapter 0xb5bada33542a05395d504a25885e02503a957bb3; L2 vbUSDC 0x203A662b0BD271A6ed5a60EdFbd04bFce608FD36`
- Path: Unverified 1,718-byte LZ OApp mints/burns bridged vbASSETs. peers(30101)=0xb5bada... is set; lzReceive origin/peer binding and endpoint auth not decompiled. A forged/replayed message minting unbacked vbASSET has the L2 Yearn vault + DEX exit as immediate liquidity. L1 vault proxies hold dust; stakedAssets sits in yieldVault 0xbeef... (USDC leg verified totalAssets 9.43M), so the reported $27.7M is partly strategy custody and the 154.2 WBTC figure needs reconciliation vs r6's 33.68 WBTC.
- Confidence: MEDIUM · plausibility: MED-HIGH
- Next check: Decompile L2 minter and L1 adapter; confirm lzReceive onlyEndpoint + peer(30101)/origin binding; fork-test forged message and replay; reconcile vbWBTC totalAssets vs strategy custody.

**2. Unnamed zkSync Era settlement vault 0x621425a1** — zkSync Era

- Live funds: ~$5.5M+ (1,121.26 ETH + 2,182,482 USDC + 181,232 USDT + 12.52M ZK)
- Addresses: `0x621425a1Ef6abE91058E9712575dcc4258F8d091 (owner/creator EOA 0x000002c34bae6dd7bec72acba6aaac1e01a359de)`
- Path: 61.9KB unverified contract; public withdraw(address,address,uint256) reverts with Panic 0x11 for a zero-balance caller, so accounting is per-user; 199,874 txs / 118.8M transfers suggests a CEX/payment omnibus. If the accounting mapping is caller-settable or transferAndDeposit credits without custody, the vault drains.
- Confidence: LOW-MED · plausibility: MEDIUM
- Next check: Decompile withdraw/transferAndDeposit, map the accounting storage and auth, identify the operator (CEX vs protocol); check deposit/withdraw event reconciliation.

**3. JustLend Energy Rental (MarketG1)** — TRON

- Live funds: 1.56M TRX native (~$500k) + 3.46M TRX nominal security deposits (~$1.11M per r4)
- Addresses: `proxy TU2MJ5Veik1LRAgjeSzEdvmDYx7mefJZvd -> impl TNoHbPuBQrVanVf9qxUsSvHdB2eDkeDAKD`
- Path: rentResource/returnResource/liquidate/forceLiquidate are permissionless; live fee is 8% of rent, min-deposit orders can be liquidated almost immediately; the badDebt branch (deposit < fee) books a loss while paying the fee. Renter+identifier collusion plus return-after-liquidate double-refund is untested.
- Confidence: MED-LOW · plausibility: MEDIUM
- Next check: Fork-prove the liquidate -> returnResource sequence and the badDebt branch; measure per-cycle extraction vs 3.46M TRX deposits; check for a non-colluding path.

**4. Alchemix V3** — Ethereum, Arbitrum, Optimism, Base

- Live funds: $40.6M DL
- Addresses: `factories 0xdd56b00302e91C4c2b8246156bDEAa1cEDc58984 (ETH), 0x8c7C0C380bA4eE38461eb5a6b82e5d930EC11Ca2 (Arb/OP), 0x2584E8b0616b3E750492c9629a3b27679C410cb9 (Base)`
- Path: Fresh VaultV2 ERC-4626 (Apr 2026) created via permissionless createVaultV2; share math, first-redeemer/donation, harvest/withdraw roles and migration lens unreviewed.
- Confidence: LOW · plausibility: LOW-MED
- Next check: Pick largest CreateVaultV2 vault; donation/first-redeemer test; read harvest/withdraw role gates.

**5. Curve LlamaLend V2** — Ethereum, Optimism

- Live funds: $42.1M DL
- Addresses: `ETH factory 0x8f6B56ec5DdF1f2691a1059f1D3cd97AC9EAB0Bd; OP 0x5F94073E3f51c1FFf92ffc6b4B06b7Af193B3640`
- Path: Fresh Jun-Jul 2026 LL v2 markets, new controller/AMM/vault blueprints and per-market oracles; soft-liquidation/partial-repay edge math unreviewed.
- Confidence: LOW · plausibility: LOW
- Next check: Enumerate markets + oracle params; quick soft-liquidation/partial-repay pass.

**6. Flex** — Ethereum

- Live funds: $1.9M DL (6 markets)
- Addresses: `registry 0x9117440a7d03238905d1c8908157bd7a547c77c8; markets incl. 0xd82db989...; oracles 0x6d8d09f1..., 0x38cae071...`
- Path: Liquity-v1 fork with custom PriceOracle and exotic collateral feeds; redemption/bonus math deviates from canonical Liquity and is unread.
- Confidence: LOW · plausibility: LOW-MED
- Next check: Read oracle aggregator (spot vs Chainlink, staleness, decimals); fuzz redemption at low TCR.

**7. JPYdf** — Ethereum

- Live funds: $849k DL
- Addresses: `wstETH vault 0x6042755ecca71a1be9c7091441ca5beaa6b520e4; USDC vault 0x087ebaf3f1b094b2046912a5e5f0bad78df3eaa7 -> impl 0x878da559d17458d84fd7a42804ccaea53c2f10b5`
- Path: receiveFromStrategy(declaredAmount) and claim(requestId) are unprivileged accounting entrypoints; backstop release/writeoff and redeem-queue pricing unreviewed.
- Confidence: LOW · plausibility: LOW-MED
- Next check: Trace receiveFromStrategy shortfall handling + backstop release + writeoff; verify redeem queue pricing.

**8. zkSwap V2 (legacy zkSync AMM)** — zkSync Era

- Live funds: $533k DL; 48 pairs
- Addresses: `factory 0xeeE1Af1CE68D280e9cAfD861B7d4af776798F18d; pair0 0xa55e595aaeda7f8f8e74b0f765b1c9f7eaa0540d`
- Path: Unverified UniV2-style factory/pairs; pair0 holds 8,926 USDC + 3.74 WETH. Fork drift in swap/fee/collect or a missing feeTo auth would be directly harvestable.
- Confidence: LOW · plausibility: LOW
- Next check: Decompile factory/pair, diff vs UniswapV2; check feeTo/setter auth, skim/sync, pair creation.

**9. DeepSwap** — Solana

- Live funds: $78.7k DL
- Addresses: `program HCrCy6bzHhZ1b6bXwQAucEFkKXyzYMh3hgAR8UPrYSEP`
- Path: Raydium cp-swap fork tied to DEEP launchpad; missing owner check on withdraw/fee-claim or fork-drift in deposit/withdraw fees would drain pool vaults.
- Confidence: LOW · plausibility: LOW
- Next check: Recover IDL/diff program vs Raydium cp-swap; verify fee-recipient withdraw instruction auth.

**10. Motoswap / VampChef** — Ethereum

- Live funds: $55.6k DL
- Addresses: `VampChef 0x51e648f08a9a08A724591938d9cbc483C809aCA4; MotoStaking 0xCE88F2C6B49EfBb92555eE5475311f0e250C2528; MOTO 0xBd965230588EAA536dE6aA45E8ebbc01638535e0`
- Path: Proxied MasterChef + revenue-share staking + new UniV2 registry; legacy accRewardPerShare/lpSupply accounting and emergencyWithdraw unread.
- Confidence: LOW · plausibility: LOW
- Next check: Read VampChef impl (EIP-1967), verify lpSupply sync + emergencyWithdraw; check MotoStaking lock math.

## Specific rows requested

| Row | Disposition |
|---|---|
| **Derive V3** ($185M) | **CLOSED-in-lane** — zk-proven withdrawal Outbox, permissioned `batchSubmitter`, owner can rotate roots/vkey, global bucket cap ~$2M @ ~$1M/hr. No E-U path at recon depth; risk lives in the zk/verification layer (r1:11, top-5 #3). Watch, not actionable. |
| **Flex** ($1.9M) | **OPEN (low)** — Liquity-v1 fork with custom PriceOracle and exotic collateral feeds; oracle/redemption math unread. |
| **Alchemix V3** ($40.6M) | **OPEN (low-med)** — fresh VaultV2 ERC-4626; donation/first-redeemer/harvest share math unread. |
| **Curve LlamaLend V2** ($42.1M) | **OPEN (low)** — fresh markets/new oracles; soft-liquidation/partial-repay edge unread. |
| **Morpho Midnight** ($8.6M) | **PARKED** — immutable, Morpho-audited, no concrete path; watch market config. |
| **JPYdf** ($849k) | **OPEN (low-med)** — public `receiveFromStrategy`/`claim`; shortfall/backstop/redeem-queue accounting unread. |
| **Qualia / BaiBai / Nullmask / Tacit** | **PARKED** — contracts not located (DL-only leads). |
| **DeepSwap** ($78.7k) | **OPEN (low)** — Raydium cp-swap fork; program diff/fee-recipient auth unread. |
| **Motoswap / VampChef** ($55.6k) | **OPEN (low)** — proxied MasterChef; `lpSupply`/`emergencyWithdraw` unread. |
| **shibbex / dogswap Shibarium pools** | **COVERED** by ZH4-03 deep-dive in flight; not deep-dived here. |
| **Metronome msUSD** | **CLOSED-in-lane** — swap active but 10% fee vs ~10% market discount ⇒ −9.0% round trip; no liquidatable positions; watch 9–11% collateral drop. |
| **Fedz FUSD** | **PARKED** — redemption restricted to Fedz-NFT holders. |
| **USDB** | **PARKED** — ~1% bridge-exit edge, below bar. |
| **satUSD** | **PARKED** — 0.62% discount, below bar / conversion path unscanned. |
| **BEND** | **CLOSED-in-lane** — 0 accounts HF<1 with collateral; 285 positions scanned; keepers active. |
| **Colend** | **CLOSED-in-lane** — $0 borrowed. |
| **Klend** | **CLOSED-in-lane** — dead/parked domain; DL entry BSC/OKExChain $0; no live Kaia venue. |
| **HyperEVM Morpho kHYPE** | **PARKED watch** — HF 1.0042; $356k conditional; not liquidatable today. |
| **Gimo st0G** | **PARKED** — ~$3.5M plausible, mint/updateMinter gated, exit liquidity ~$1.1k. |
| **CL8Y** | **CLOSED-in-lane** — identified as CeramicLiberty.com memecoin; both 0x addresses are EOAs (126.7 ETH + 0.03 ETH), no contract surface; Oct-15 BSC incident/recovery notice. |

## “Contracts not located” — resolved

| Target | Result |
|---|---|
| **MoreMarkets.xyz** ($467k DL) | **PARKED.** Located the RLUSD vault `0xb962fd1aBd9A365140493Bd499AcF1eC0AcfF040`; `totalAssets()` = **30.68 RLUSD**. The $432k Ethereum TVL is the market value of Midas hyperETH/BTC/USD tokens (data-feed × supply), not protocol custody. Flare fXRP supply 16,579 (6dp). No protocol pot. |
| **zkSwap V2** ($533k) | **OPEN (low).** Factory `0xeeE1Af1CE68D280e9cAfD861B7d4af776798F18d` (zkSync Era), 48 pairs; pair0 `0xa55e...` holds 8,926 USDC + 3.74 WETH. Pools are unverified; UniV2 fork. |
| **MUFEX** ($276k DL) | **PARKED.** Three vault contracts (`0x763ecd...`, `0x16BEDB...`, `0x60b4B5...`) across Arb/Polygon/Mantle/BSC; live USDT ≈ **$6.5k** (1,766 Arb + 3,234 Poly + 1,486 Mantle + ~0.3 BSC). DL TVL is stale. |
| **Lendle** ($176k) | **PARKED.** 11 reserves; aToken cash ≈ **$174.2k**; variable-debt ≈ **$13k**; all markets populated (no empty-market donation); Aave-v2 fork, no concrete path. |
| **xDollar** ($161k) | **CLOSED-in-lane.** IoTeX trove managers: 28 troves, 143,885 XUSD debt, 3.05M WIOTX collateral ≈ **$11.7k** ⇒ ~8% TCR. Insolvent; no extraction. |
| **Ronin deprecated staking manager** `0x8Bd81a19420bAd681B7bfc20E703EBd8e253782D` ($158.8k) | **CLOSED-in-lane.** 755,974.8 RON + 101,474.7 AXS (~$157k); impl `0x9b532621...` exposes only admin `withdrawEther`/`withdrawToken` (revert for a random caller) and reward-accounting functions; no user unstake/exit. P/S class. |

## Disposition method

- Enumerated every ranked table row in `wave1/r1–r7` and `wave2/d2a–d2d`; then named prose leads, “dead ends / notable negatives”, “also-ran”, watchlists, and “honest gaps”.
- Mapped each to: FINDING (README Tier 1/2), LOW (README Tier 3), CLOSED-README, CLOSED-LANE (negative verdict in the working file, cited), EXCLUDED (prior corpus/not a target), PARKED (below-bar/unlocated/watch/trigger/P-class), OPEN.
- For the six “contracts not located” targets: pulled DefiLlama adapters/registries, located contracts, and performed live `eth_call`/`balanceOf`/storage reads at the block numbers in `summary.json` (public RPCs only).
- Residual leads inside `wave2/v*.md` were checked: the only material one is the Beacon-proxy module, which v15 closes at $0 E-U ($423.9k tripwire); SparkDEX old-plugin residual is closed by v32; Rujira off-hash pair is $4.1k; Exponent/Tessera residuals are LOW with $0 demonstrated.

## Files

- `analysis/ALL-ROWS.md` — full disposition table (all lanes, all named leads).
- `analysis/r1.md` … `analysis/d2d.md` — per-lane enumeration with citations.
- `analysis/v-residuals.md` — residual leads inside the verification files.
- `analysis/rows.py` — machine-readable enumeration.
- `summary.json` — counts, OPEN list, specific-row verdicts, live block numbers.
- `ci/check.py`, `ci/run.sh`, `ci-out/` — CI validation + live-funds re-reads.

## CI

- Runs: **https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39081911266** (final, success) and https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39081800492 (first pass, success).
- The job re-computes the counts from `analysis/rows.py`, compares them to `summary.json`, scans the folder for keyed-URL/secret patterns (0 hits), and re-reads the OPEN-list funds at public RPCs. Results: `ci-out/validation.json`, `ci-out/live_checks.json`; copied artifacts in `ci-artifacts/result-residual-recon/`.

## Caveats

- OPEN is a triage label, not a proven bug. Confidence/plausibility are explicit.
- Point-in-time reads (2026-10-18); re-check before acting.
- Zappy contradiction: r7 on-chain reads show ~$90k; d2d L7 found the domain dead. README Tier 3 #8 follows the on-chain evidence; verify troves before any action.
- The zkSync vault may be a CEX/omnibus, not a protocol; that is the main blocker for OPEN #2.
- Nothing here is an instruction to transact; interacting with any listed contract may be illegal in the reader’s jurisdiction.