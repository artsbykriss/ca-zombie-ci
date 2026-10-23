# ZH4-PASS3 — RESIDUAL RECONCILIATION (pass3 lane↔README gap closure)

**Date:** 2026-10-23 · **Mode:** read-only (no tx signed/sent; public/keyless RPCs only; no secrets in this folder)
**Scope:** every named candidate in `zombie-hunt-iv/pass3/README.md` + all **23 lanes** (`approvals, argent2, atomic-green, deri, fresh-pools, gauge-family, incidents, lane-bridge, lane-consumer, lane-curators, lane-dex-evm, lane-dex-nonevm, lane-lending, lane-lst, lane-old, lane-rwa, lane-yield, lane_derivs, leaked-keys, predictfun, replay, timewrap, wildcat`).
**Purpose (principal's flag):** the lane files name far more protocols than the pass3 README lists; some funded candidates were never assigned. This pass gives **every named candidate a disposition** and produces the **OPEN list** (funded ≥ ~$1k + a plausible unprivileged path + no verdict anywhere). It does **not** deep-dive.
**Prior-coverage sources used:** `ci/ZH4P5…ZH2B*` trackers, `ci/L2-*.{md,json}`, `ci/TIER3-LOW-TRACKER.md`, `ci/MONITOR-LIST.md`, `ci/MASTER-EXTRACTION-TABLE.md`, the kept root folders, `zombie-hunt-iv/zh4-check.sh`, `residual-recon/` (Wave-B0), `small-leads/`, and the pass1–5 README closed lists.

---

## HEADLINE COUNTS

| Disposition | Count |
|---|---:|
| Named candidate entries enumerated (protocols, addresses, metrics, hypotheses, grouped lists) | **≈ 645** |
| Disposition **rows** in the table (grouped rows carry name counts) | **231** |
| **README-FINDING** (assigned in pass3 README) | **7** |
| **README-CLOSED** (pass3 README "verified closed" table / removed list) | **42** |
| **LANE-CLOSED** (lane's own $0/closed/P/S verdict, incl. grouped prior lists) | **≈ 470** |
| **PRIOR-COVERED** (cited in a prior tracker / kept folder / pass1–5 README) | **≈ 78** |
| **PRIOR-PARTIAL** (same protocol, distinct bug class/angle) | **9** |
| **NOT-A-PROTOCOL** (metric / address artifact / hypothesis / custodial / native) | **≈ 41** |
| **OPEN** (funded ≥ ~$1k + plausible unprivileged path + no verdict) | **26** |

Known pass3 items **not** re-listed as OPEN: Pharaoh gauge, Cooler MonoCooler, Trueo, SimpleAccount, BiFi (README-FINDING); removed: Cetus, STON.fi V2, RISEx, Gimo, Verio, Waterline, Eva, Manifest, Hyperbeat, Sport.fun (README-CLOSED); prior: Radworks, Pirate Chain, UNCX, HAI (PRIOR-COVERED).

**Honest bottom line:** the pass3 lanes were individually thorough, but ~40–60 protocol-level candidates were left with an *explicit "not reached / unverified / watch"* status and **no verdict** — these are the residual. None is a proven drain; the OPEN list is a **next-check queue**, ranked by funds × plausibility. The strongest unassigned item is **MUX Perps ($9.7M, GMX-v1 fork whose live reentrancy-recipe class was never tested)**.

---

## OPEN LIST — ranked by live funds × plausibility

*Plausibility = (funds at risk) × (does the lane name a concrete permissionless path, vs "unverified/unreached"). All amounts are the lane's point-in-time 2026-10-20 figures. "Next check" is the single decisive test.*

| # | Target | Chain(s) | Live funds (est) | Plausibility / conf | Why OPEN (no verdict anywhere) | Next check |
|---|---|---|---|---|---|---|
| 1 | **MUX Perps** | Arbitrum (+AVAX/BSC/OP/Fantom) | **$9.71M** (Arb $8.84M) | **MED-HIGH / MED** | Lane `lane_derivs` row 24 + `lane-old` row 12: GMX-v1-lineage order-execution reentrancy (the ZH2 C2-22 Fulcrom recipe) — **UNTRIAGED**, "patch status not verified". `zh4-check.sh` clean (the L2-PHASE1 "MUX" hit is *g8keep*, a different target). Reader `0x437CEa95…` + MUX3 diamond `0x85c8F4a6…` live on Arbitrum (code confirmed 2026-10-23). | Run the Fulcrom C2-22 recipe against the MUX `OrderBook`/`PositionRouter`/`readerContract[arbitrum]`; grep for `callbackContract`/arbitrary-call + reentrancy guard; fork-test. |
| 2 | **EtherFi Borrowing Market** | Optimism (+Scroll) | **$300.6M supply / $43.2M borrowed** | **MED / MED** | `lane-lending` row 2: dedicated **Aave V4 Spoke** instance whose public `borrow` was **not tested**; docs claim KYC-only borrowing but the Spoke address is unpublished. RWA/stock feeds (QQQx/SPYx/PAXG/TBLLx) are the highest-value *unproven* oracle lead in that lane. | Resolve the Aave V4 Spoke address; test `borrow` from a non-KYC address; read each RWA oracle source. |
| 3 | **SaucerSwap V2** | Hedera | **$16.78M** | **MED / LOW** | `lane-dex-nonevm` row 6: **V2 CLMM is a distinct codebase** from the V1 that prior ZH2B6 closed ($0). Not reviewed this pass. | Pull V2 factory/pool source from HashScan; diff vs UniV3-core; check position-NFT `decreaseLiquidity` owner/recipient validation. |
| 4 | **SMARDEX USDN** | Ethereum | **$1.35M** (452.5 wstETH) | **MED / LOW** | `lane_derivs` row 3: all state-changing paths (`liquidate`, `validateOpenPosition/Close`, `initiateWithdrawal`) are permissionless; only 28 positions and no exhaustive scan; protocol price ≈ par today. | Fork Ethereum; enumerate all 28 long positions via events; call `getPositionValue`/`getLiqPrice`; test `liquidate` on the weakest; round-trip `initiateWithdrawal` net of fees/penalty. |
| 5 | **Venus Flux** | BSC | **$1.88M supply / $1.22M borrowed** | **MED / MED** | `lane-lending` row 8: Mar-2026 Instadapp-**Fluid** deployment with Venus LST/LP wrappers in `listedTokens()`; the per-token price sources were **not fully traced**; a spot/bad oracle on a wrapper allows over-borrow. | Trace each of `[0x8E9d…, 0x4254…, 0xcE24…, 0x7773…]` to its Fluid oracle/rate source; check for spot vs TWAP. |
| 6 | **JustLend sTRX (STRXProxy)** | Tron | **$3.27B DL** (frozen bandwidth/energy + delegated + 14-day unstaking + liquid) | **MED / LOW** | `lane-lst` row 10: **UNREVIEWED — "the biggest gap in the lane."** Tronscan does not expose verified source; exchange-rate accounting across frozen/delegated/energy-rental/unstaking buckets never read. Prior corpus closed **JustLend V2/Moolah and Energy Rental**, *not* sTRX. | Get STRXProxy source via TronGrid/Tronscan API key; check `exchangeRate` staleness and whether energy-rental revenue is counted before receipt. |
| 7 | **Mezo Swap / Tigris Mezo V3** | Mezo (BTC L2) | **$5.4M** (pool `0xcc372b7e…` $5.3M mUSDC/MUSD) | **MED / LOW** | `lane-dex-evm` row 15: brand-new Uni-V3-shaped fork (Mezo listed 2026-10-15); **no verified source** (Sourcify `match:null`, Blockscout API 404); "the highest-value unseen code in the lane." | Sourcify/decompile the pool+factory; diff vs UniV3-core; check swap/fee/position math. |
| 8 | **BulbaSwap V3** | Morph | **$8.6M** | **MED-LOW / LOW** | `lane-dex-evm` row 16: Uni-V3-shaped pool `0x5191035d…`, factory `0xff8578c2…`; Morph explorer exposes **no contract API**; not assessed. | Obtain verified source via Morph explorer/Sourcify; diff vs UniV3; test skim/collect auth. |
| 9 | **Endur (xSTRK / xyBTCs)** | Starknet | **$12.03M** (6 ERC-4626 vaults) | **LOW-MED / LOW** | `lane-lst` row 6: ERC-4626 over STRK/BTC with a withdrawal queue; `total_assets` may include pending/unbonding assets; **no working Starknet RPC** in-session; "audited!" claim not verified. | Get a Starknet RPC + the audit PDF; check `total_assets` vs `balanceOf(staker)` and queue share-burn. |
| 10 | **Apex Omni** | ETH/Arb/Base/BSC/Mantle | **$30.72M** (ETH $17.40M) | **LOW-MED / LOW** | `lane_derivs` row 23: **UNTRIAGED**; no contracts located from the DL adapter; orderbook/CEX-like venue (likely operator-settled = P) but the $30.7M custody surface was never mapped. `zh4-check.sh` clean. | Map the per-chain USDC vault(s); check owner/operator/settlement signer; test deposit/withdraw. |
| 11 | **PancakeSwap AMM V3 (Solana)** | Solana | **$6.24M** (Solana leg) | **LOW-MED / LOW** | `lane-dex-nonevm` row 10: new Solana port of Pancake V3; **not reviewed**; DL `audits=0` for the aggregate (data gap). | Identify program ID/upgrade authority; diff vs Raydium CLMM. |
| 12 | **stUSDT** | Tron (+ETH wrapper) | **$54.6M** market cap | **LOW-MED / LOW** | `lane-rwa` row 16 + `lane-old` row 22: upgradeable proxy; price/roles off-chain/role-gated; **only DL `totalSupply` checked** — "treat as unchecked, not closed." | Pull verified impl source from Tronscan; check `mint/redeem/updatePrice` roles. |
| 13 | **Mezo Vaults (sMUSD)** | Mezo | **$7.50M** | **LOW / LOW** | `lane-yield` row 10: savings-rate vault + a **strategy with unverified source** (Sourcify/Mezo explorer dead); `totalAssets()` reverts. | Get the strategy ABI/source from mezo-org GitHub; test `distributeYield` auth. |
| 14 | **HiYield (T-bill / IG vaults)** | Avalanche | **$1.724M + $52k** (T-bill holds 190,000 USDC = 11% cash) | **LOW-MED / LOW** | `lane-rwa` row 3: **547-byte custom proxy with no verified source**; `poolInfo()` exposes a matured T-bill (2026-04-16) at price 1.1095; bank-run-at-par vs illiquid credit unproven. Proxy live + 190,000 USDC custody confirmed 2026-10-23. | Disassemble the 547-byte fallback (impl resolved via factory `0x523688c1…`); check whether `withdraw` is open and cash covers `poolInfo[0]`. |
| 15 | **Premia V3** | Arbitrum | **$556k** | **LOW / LOW** | `lane_derivs` row 12: the only fresh **public** options AMM in the lane; oracles (`baseOracle`/`underlyingOracle`) **not enumerated**; audited but TVL small. | Enumerate `DeployPool` logs; read the largest pool's oracles + `getSpotPrice`; fork-test expiry manipulation and exercise/settle replay. |
| 16 | **StakePoint** | Solana | **$3.96M** | **LOW / LOW** | `lane-consumer` row 13: Solana locker/staking program; **not reviewed** (Anchor IDL not reversed). | Dump IDL from chain; review withdraw/claim auth. |
| 17 | **DaVinciGraph** | Hedera | **$1.85M** | **LOW / LOW** | `lane-consumer` row 14: locker/vesting contracts; HashScan verified source **not fetched**. | Fetch HashScan source for the locker set; test unlock bypass. |
| 18 | **VVS Flawless (VVS V3 CLMM)** | Cronos | **$3.23M** | **LOW / LOW** | `lane-old` row 10 + `lane-dex-evm` row 19: Algebra/CLMM fork, 0 audit labels; **not reached** (no working verified-source API). | Pull V3 factory/pool; diff vs Algebra; skim/balance check. |
| 19 | **MerlinSwap** | Merlin | **$5.9M** | **LOW / LOW** | `lane-dex-evm` row 19: **not reached** (explorer API unavailable). | Retry with a per-chain explorer key; diff vs upstream V2/V3. |
| 20 | **DOOAR V2** | BSC | **$5.4M** | **LOW / LOW** | `lane-dex-evm` row 19: **not reached**. | Retry source pull; diff vs upstream. |
| 21 | **Diamond Finance** | Bitkub | **$3.5M** | **LOW / LOW** | `lane-dex-evm` row 19: **not reached**. | Retry source pull. |
| 22 | **Gate Swap** | GateLayer | **$3.2M** | **LOW / LOW** | `lane-dex-evm` row 19: **not reached**. | Retry source pull. |
| 23 | **Qearn** | Qubic | **$15.1M** | **LOW / LOW** | `lane-lst` row 15: lock-for-reward with early-unlock penalty; **no Qubic tooling** in-session. | Read the Qubic C++ contract; penalty/reward-index review. |
| 24 | **Mezo Borrow** | Mezo | **$1.35M** | **LOW / LOW** | `lane-lending` row 7: Liquity-v1 fork with a custom "refinancing fee"; public `rpc.mezo.org` **unreachable** (re-confirmed 2026-10-23), so no live read. | Reach the Mezo RPC; read the fee adapter + price feed. |
| 25 | **ABC Pool (Conflux PoS)** | Conflux eSpace | **$5.64M** | **LOW / LOW** | `lane-old` row 7: PoS pool proxy (impl `0x8c5623…`); ConfluxScan API SPA-gated → **source not verified**; `poolSummary`=11,140 (×1000 CFX) live. | Retrieve impl source via ConfluxScan internal API/Sourcify; audit `withdraw`/`unstake` exchange rate. |
| 26 | **Lumi / Sodium smart accounts** | Arbitrum | unknown residual (historical $270k) | **LOW / LOW** | `replay` row 3: live ERC-1271 signer bypass (`0xb5BC46dF…`); implementation still deployed; **full scan of remaining funded Sodium proxies pending**. | Enumerate Sodium proxies with balance; test `validateUserOp` with an attacker ERC-1271 signer. |

### OPEN — non-EVM / native, parked (funded but no contract-level permissionless path; monitor only)

| Target | Chain | Funds | Why parked |
|---|---|---:|---|
| **Bittensor dTAO** | Bittensor | $474M reserves | Substrate **pallet**, not a contract; consensus/economic bug only (`lane-dex-nonevm` row 11). |
| **Hydration DEX** | HydraDX | $25.8M | Native omnipool/stableswap pallet; no contract surface (row 12). |
| **Osmosis DEX** | Osmosis | $11.4M | Native `x/gamm`; bOSMO is a separate pass2 finding (PRIOR). |
| **XRPL DEX** | XRPL | $34.85M | Native ledger; `fixCleanup3_4_0` amendment ~2026-10-23 (row 18). |
| **Stellar AMM** | Stellar | $8.75M | Native `liquidity_pools`; Heliobond Soroban fixed 2026-09-26 (row 19). |
| **ICPSwap** | ICP | $3.35M | DL address is the ICS **ledger**; pool canisters not enumerated (row 14). |
| **InitiaDEX** | Initia | $3.57M | Native Move module; weight/amp bounds not read (row 15). |
| **Storm Trade** | TON | $4.22M | TON FunC perps; tooling not set up (`lane_derivs` row 15). |
| **Lavarage** | Solana | $583k | Small spot-margin program; not reviewed (row 16). |
| **Synthetix V4** | Ethereum | $887k | New, heavily audited core; small TVL (row 17). |
| **DeSyn Basis** | Bitlayer | $1.80M | Only Bitlayer non-zero; source not read (row 21). |
| **MetalX / xExchange / Gala Swap** | Proton/MultiversX/Gala | $4.75M/$3.85M/$4.87M | Old chain-native AMMs; no fresh listing (row 20). |
| **StandX Solana program** | Solana | (EVM leg $1) | The $16.6M lives in the Solana program/off-chain settler; EVM side role-gated (`lane-bridge` row 6). |
| **Terminal Finance Pre-Deposits** | Ethereum | $510k | Standard ERC-4626 at the value bar; not reviewed (`lane-consumer` row 17). |
| **Goldilocks Goldivaults** | Berachain | $527k | Unverified YT/OT bonding-curve math (`lane-yield` row 12). |
| **DexFi Aggregator V2** | Base/Robinhood/… | $2.75M | Farm-connector vaults; source not reached (`lane-yield` row 13). |
| **Nerona** | Fluent | $1.37M | Addresses not published; explorer unreachable (`lane-yield` row 15). |
| **RelayDepository** | Ethereum | ~$0 measured | Approval spender, source unverified, no arbitrary-`from` in ABI (`approvals` row 8). |

---

## FULL DISPOSITION TABLE

Legend — **RF** = README-FINDING (assigned pass3) · **RC** = README-CLOSED (pass3 README closed/removed list) · **LC** = LANE-CLOSED (lane's own verdict) · **PC** = PRIOR-COVERED (cited tracker/folder) · **PP** = PRIOR-PARTIAL (distinct angle) · **NP** = NOT-A-PROTOCOL · **OPEN** = funded + plausible path + no verdict.
The complete per-name table (all ~645 entries, grouped) is `analysis/ALL-ROWS.md`; the grouped rows below carry the count of names they represent.

### pass3 README layer

| Candidate | Disposition | Note |
|---|---|---|
| Pharaoh CL gauge (Avalanche, +Nile/Nuri/Cleopatra) | **RF** | P3-01 CRITICAL; `pharaoh-gauge/`, `gauge-family.md` |
| BiFi Lending (ETH+BSC+AVAX+Kaia) | **RF** | P3-02 HIGH; `bifi/`; paused, one owner call re-arms |
| SimpleAccount/Guardian factory (Arbitrum) | **RF** | P3-03 HIGH; `simpleaccount/`; $0 today, re-arm |
| Cooler MonoCooler | **RF** | Tier-3 #13; `cooler-monocooler/`; up-only oracle, re-arm if gOHM<$3,118 |
| Eva Markets | **RF** | Tier-3 #1 (removed); Wildcat face-value deposit, conditional |
| Waterline Reservoir | **RF** | Tier-3 #2; curator Agua HF 1.0057 |
| Trueo | **RF** | Tier-3 #12 (removed); `trueo/`; resolution griefing |
| OnRe | **RF** | Tier-3 #10; Solana Token-2022 redemption freeze (not theft) |
| Cetus CLMM / STON.fi V2 / RISEx / Gimo / Verio / Manifest / Hyperbeat / Sport.fun | **RC** | removed list (8) |
| Wildcat (88 markets) / Deri V4 / Predict Fun / Atomic Green / Argent / Secured Finance / AlpsCon / launchpads / bridges / DEX forks / yield / LST / RWA / curators / approvals / leaked keys / time-wrap / fresh pools | **RC** | README "VERIFIED CLOSED" table (grouped) |

### lane-old.md
| Candidate | Disp | Note |
|---|---|---|
| Wildcat Protocol (88 mkts) | **RC** | `wildcat.md` closed E-U $0 |
| Deri V4 (6 vaults) | **RC** | `deri.md` closed; DL 46.2× overstated |
| Metronome Synth | **LC** | depeg trade dead by construction (HIGH neg) |
| Sovryn Zero | **LC** | TCR 11.06, 31 troves (HIGH neg) |
| Flux Finance | **LC** | cf=0 on public markets (HIGH neg) |
| Katana DEX (Ronin) | **LC** | 767-pair skim <$10 (HIGH neg) |
| ABC Pool (Conflux) | **OPEN** | #25 — unverified impl source |
| Quickswap V3 (non-Polygon) | **PP** | prior non_llama #138 flagged; Algebra diff angle |
| Agni Finance | **LC** | `lane-dex-evm` closed $0 |
| VVS Flawless | **OPEN** | #18 — not reached |
| PinkSale locks | **LC** | owner renounced; 58,706 locks |
| MUX Perps | **OPEN** | #1 — GMX-v1 recipe untested |
| Blur Lending (Blend) | **LC** | audited ChainLight |
| Alpaca Finance 2.0 | **PC** | ZH1 H-20; repo 404/stale |
| Scallop / Turbos / Mole / Aftermath / FluidTokens | **PC** | prior non-EVM r4 |
| Cetus CLMM | **RC** | removed (dex-nonevm) |
| Gravity Bridge | **LC** | validator-set, no E-U |
| ioTube | **PC** | Feb-2026 key incident |
| Wrapped.com / JustCryptos / stUSDT | **NP** | custodial issuers (stUSDT → OPEN #12) |
| triaged-out list (ether.fi, Lido, Aave, Uniswap, Curve, Maker, Fraxlend, Pancake, Sushi, Camelot, RealT, NEOPIN, BSCSwap, Fulcrom, PulseX, SyncSwap, BakerySwap, Blur Bids, MetalX, xExchange, WhaleEx, ICPSwap, DeDust/STON/Storm, Meld Gold, Lofty, APX, Paradex, Sky, stake.link, Meta Pool, GLIF, Stakee, Hydration, Summer.fi, Realms) | **PC/NP** | grouped (36) — prior corpus/top-tier/custodial/non-EVM |

### lane-lending.md
| Candidate | Disp | Note |
|---|---|---|
| Cooler MonoCooler | **RF** | Tier-3 #13 |
| EtherFi Borrowing Market | **OPEN** | #2 |
| Flex | **LC** | oracle==PPS, MCR 110% (HIGH) |
| JPY DeFi | **LC** | JPY feeds correct; zapper untested (LOW-MED) |
| SomniaLend | **LC** | Aave-v3 configs sane (HIGH) |
| Threshold thUSD | **LC** | Liquity v1 params (HIGH) |
| Mezo Borrow | **OPEN** | #24 |
| Venus Flux | **OPEN** | #5 |
| Flux Finance | **LC** | dup lane-old |
| Fraxlend | **LC** | 71 pairs, MED |
| BAMM | **LC** | MED, reviewed source |
| Revert Lend | **LC** | C4 2024-03 |
| Native Credit Pool | **LC** | HIGH |
| Templar Protocol | **LC** | EVM $0 (non-EVM core) |
| Enosys Loans | **LC** | HIGH; ±0.5% feeds |
| VETRO | **LC** | HIGH; ±1% peg tolerance |
| mStable V2 | **LC** | mis-categorised (dHEDGE) |
| BIMA/BTCFi CDP | **LC** | out of EVM scope |
| Hyperbeat USD | **RC** | removed |
| Rezerve Lending | **LC** | Euler curator (HIGH) |
| triaged list (USDD, Jupiter Lend, Tydro, Curve LlamaLend/V2, STRATO, Alpaca 2.0, Kava, Vesu, Vena, Morpho Midnight, Capyfi, Inverse, YeiLend, MORE, Longbow, JustLend V2, Arkadiko, Bastion, Orbit, Scallop, marginfi, RealT RMM, Sovryn, Mystic, Kinza, Mendi, Enosys Bridge, dust list, non-EVM list) | **PC/PP** | grouped (46) |

### lane-dex-evm.md
| Candidate | Disp | Note |
|---|---|---|
| Pharaoh CL gauges (×5) | **RF** | P3-01 |
| Lista DEX / StableSwap | **LC** | Curve port clean ($0) |
| Agni Finance | **LC** | $0 |
| Merchant Moe LB | **LC** | $0 |
| Pharaoh DLMM | **LC** | $0 |
| Angstrom | **LC** | v4 hook $0 |
| Katana DEX | **LC** | $0 |
| Thruster V3 | **LC** | $0 |
| Frax Swap | **LC** | $0 |
| SyncSwap | **PC** | ZH4 closed SyncSwap Vault V1 |
| Mezo Swap / Tigris | **OPEN** | #7 |
| BulbaSwap V3 | **OPEN** | #8 |
| Tempo Stablecoin DEX | **NP** | precompile `0xdec0…` |
| HyperSwap/Nado/BDEX/RocketSwap/Icarus/Metric/SparkDEX/BSCSwap | **PC** | grouped (8) |
| VVS Flawless/MerlinSwap/DOOAR/Diamond/Gate Swap | **OPEN/PP** | grouped (5) → #18–#22 |

### lane-dex-nonevm.md
| Candidate | Disp | Note |
|---|---|---|
| Cetus CLMM | **RC** | removed |
| STON.fi V2 | **RC** | removed |
| Manifest Trade | **RC** | removed |
| RocketSwap Anubis | **LC** | DL 55% fake; bridge backed |
| Byreal CLMM | **LC** | source clean |
| SaucerSwap V2 | **OPEN** | #3 |
| DeepBook V3 / Futarchy AMM / Minswap | **LC** | audited |
| PancakeSwap V3 Solana | **OPEN** | #11 |
| Bittensor dTAO / Hydration / Osmosis | **OPEN(parked)** | native pallets |
| ICPSwap / InitiaDEX | **OPEN(parked)** | #non-EVM |
| Temple / Cantex | **NP** | Canton permissioned |
| XRPL / Stellar | **PC** | native; prior pass2 |
| MetalX / xExchange / Gala Swap | **OPEN(parked)** | old native |
| triaged clusters (Sui old pkgs, BisonFi/GoonFi/Scorch/Tessera/FluxBeam/Saber/Serum/Raydium/Jupiter, SundaeSwap, SUNSwap, BDEX, Zia/Bond, Kumbaya/FaroSwap/Vena) | **PC** | grouped (12) |

### lane-lst.md
| Candidate | Disp | Note |
|---|---|---|
| Verio / Gimo / Hyperbeat | **RC** | removed (3) |
| Prime Staking V3_2 | **LC** | MED solvency red flag, not E-U |
| Ascend (a0G) | **LC** | accounting verified |
| Endur | **OPEN** | #9 |
| InceptionLRT | **LC** | small/audited |
| Biquid / OpenGDP | **LC** | non-EVM / Karak |
| JustLend sTRX | **OPEN** | #6 |
| Stakee / Adrastea / Hylo / CatFee | **LC/NP** | canonical/native |
| Qearn | **OPEN** | #23 |
| White-label Solana LSTs (18 names) | **LC** | shared audited programs |
| Audited LST/LRT frameworks (13 names) | **LC** | audited |
| Kyros / Fragmetric | **LC** | address mismatch |
| prior/excluded list (Kinetiq, Phase, marginfi, NEOPIN, SparkDEX, ExinPool, JustLend V2, custodial list) | **PC/NP** | grouped |

### lane-yield.md
| Candidate | Disp | Note |
|---|---|---|
| RockSolid / Syntropia | **LC** | P/H-O; EOA custody |
| SuperEarn / Ledgity / Royco V2 / Llama Airforce | **LC** | closed |
| StableHodl / Lazy / Zoo / lisAster | **LC** | P/S/custodial |
| Mezo Vaults | **OPEN** | #13 |
| Goldilocks / DexFi / CGO / Nerona | **OPEN** | #15/#26/#parked |
| TermFinance / Toros / Yield Yak / Spectra / Puffer / Solid Yield | **LC** | audited |
| triaged list (Avalon, Kinetiq, Faiyah, Startale, Rujira, Mezo Swap, Convergence, Troves, giants list, non-EVM list) | **PC/PP** | grouped (45) |

### lane-rwa.md
| Candidate | Disp | Note |
|---|---|---|
| Eva Markets | **RC** | removed |
| OnRe | **RF** | Tier-3 #10 |
| HiYield | **OPEN** | #14 |
| Kamui / Estate / Theo / Frax USD / Lista RWA / OpenTrade / ISC / T-RIZE / Clearpool / ZTLN / GPC / Uranium | **LC** | closed (12) |
| stUSDT | **OPEN** | #12 |
| dead-end list (Sky RWA, Anemoy, KAIO, Sygnum, R25, Valos, Ethena USDtb, Lofty, Meld, Kea, Defa, Mansory, RealT) | **PC/NP** | grouped (13) |

### lane-curators.md
| Candidate | Disp | Note |
|---|---|---|
| Apostro / Duplicated Key / frobUSDC / MEV Capital | **LC** | impaired $7.59M; $0.01 liquid; re-arm monitor |
| Waterline Reservoir | **RF** | Tier-3 #2 |
| Steakhouse/Sentora/Paypal/Grove/sky.money/Sentora Huma/Pendle/RockawayX/Hyperithm/Mainstreet/Adpend/Gauntlet | **LC** | closed (12) |
| triaged brands (41) | **PC/LC** | grouped |

### lane-bridge.md
| Candidate | Disp | Note |
|---|---|---|
| PulseChain Omnibridge | **LC** | onlyMediator; top lead E-U $0 |
| Sonic Gateway | **LC** | MPT proof-gated |
| Aster/Astherus | **LC** | OPERATE_ROLE |
| Taiko Bridge | **LC** | proof-gated; also leaked-key row |
| SoDEX / StandX / Gravity / Merlin's Seal / Mezo / Endurance | **LC** | role/proof-gated (StandX Solana → OPEN-parked) |
| Unit/HyperUnit, FBTC, SolvBTC, Lorenzo, Nexus, FAssets, Lombard, bgBTC, custodials, Grvt/ADI, Morph, OP-stack | **NP/LC** | grouped (~20) |

### lane-consumer.md
| Candidate | Disp | Note |
|---|---|---|
| Predict Fun | **RC** | removed; `predictfun.md` closed |
| Trueo | **RF** | Tier-3 #12 |
| Sport.fun | **RC** | removed |
| GoPlus / PinkSale / Punks Terminal / StonkBrokers / HoodLock / USDR / Buzz | **LC** | closed/custodial (7) |
| Blur Bids / AILayer | **NP** | address is a token |
| Bio Protocol / Stargate VeChain / Sigmausd / Stellar DeFi Hub / Swell | **LC/PC** | grouped |
| StakePoint / DaVinciGraph / Terminal Finance | **OPEN** | #16/#17/#parked |

### lane_derivs.md
| Candidate | Disp | Note |
|---|---|---|
| RISEx | **RC** | removed |
| Antarctic (AMLP/AHLP) | **LC** | P/S |
| SMARDEX USDN | **OPEN** | #4 |
| Derive V3 / Aegis / JUSD / Monetrix / Aster USDF / Phoenix / Hypercall / Opyn / Evedex / AnyHedge | **LC** | closed (10) |
| Premia V3 | **OPEN** | #15 |
| Storm Trade / Lavarage / Synthetix V4 / DeSyn | **OPEN(parked)** | grouped |
| Hakka | **NP** | out of class |
| BMX Freestyle | **PC** | SYMMIO lineage |
| SoSoValue Basis | **NP** | USDC.e address artifact |
| Apex Omni | **OPEN** | #10 |
| MUX Perps | **OPEN** | #1 |
| excluded list (Jupiter/Hyperliquid/dYdX/Extended/Lighter/Decibel/Papertrade/Arcus/AZverse/Moonlander/HertzFlow/Perpl/Meridian/BitFi/BULK/SYMMIO/Fulcrom/Deri) | **PC** | grouped (18) |

### Vector lanes
| Candidate | Disp | Note |
|---|---|---|
| incidents: Argent / AlpsCon / BiFi / 854-ETH sweep / webhook / Cysic / Qubic / EtherVista / UNCX / Coffer / Drift / Aztec | **RC/LC/NP/PC** | BiFi=RF; EtherVista=PC; Qubic=OPEN-parked; others closed/laundering |
| approvals: 25 ranked spenders + 8 extra | **LC** | all authority-correct; $0 drainable |
| approvals: RelayDepository, UUPSProxy | **OPEN(parked)** | source-unverified follow-up, $0 measured |
| approvals: 3 EOAs w/ ~500 approvals each | **NP** | key-holder surface |
| leaked-keys: Twyne, Taiko, Curvance + 11 test keys | **LC** | all $0; Twyne/Taiko latent-only |
| replay: Atomic Green (RF→RC) / SafeTransfer / Lumi-Sodium / Nimiq / Giddy / Dexodus / TokenStore / BiddableEscrow / WeiDex-Cryptex / LASiR | **RC/LC/PC/NP/OPEN** | Lumi-Sodium → OPEN #26 |
| timewrap: SimpleAccount (RF) / Argent / Barz / Openfort / Candide / SoulWallet / LSP11 / Authereum / HoodLock / StonkBrokers / UsualX / Umia / Kinetiq / Flying Tulip / Pheasant / Usd0PP / WealthManagement / timelocks | **RF/LC** | all closed |
| fresh-pools: 10 ranked + 5 phantom classes | **LC/NP** | all phantom/artifact |
| gauge-family: Pharaoh (RF) / Nile / Nuri / Cleopatra / 12 patched | **RF/LC** | dust |
| wildcat / deri / predictfun / atomic-green | **RC** | closed |

---

## METHOD

1. Read all 23 lane files + the pass3 README; extracted every table row, prose lead, "not reached", "watch", and "dead-end" name.
2. For each name: classified as README-FINDING / README-CLOSED / LANE-CLOSED (citing the lane verdict) / PRIOR-COVERED (grep of `ci/*TRACKER*.md`, `ci/L2-*`, `ci/MONITOR-LIST.md`, `residual-recon/`, `small-leads/`, kept root folders, `zh4-check.sh`) / PRIOR-PARTIAL / NOT-A-PROTOCOL / OPEN.
3. **OPEN** requires all three: funded ≥ ~$1k, the lane names a concrete plausible *unprivileged* path (or the code is unverified/unreached with real custody), and no verdict anywhere.
4. Live sanity checks on the top OPENs (2026-10-23, read-only, keyless RPCs): confirmed MUX reader+MUX3 diamond live on Arbitrum; HiYield proxy live + 190,000 USDC custody; SMARDEX protocol proxy live; Venus Flux Fluid Liquidity proxy live; Premia factory diamond live; Mezo/Starknet RPCs unreachable (matches lane).
5. No deep-dive; no fork; no transaction.

## CAVEATS
- Disposition counts are grouped: "PRIOR-CORPUS / top-tier / custodial" rows each carry many names, so the row count (231) is far below the named-entry count (~645).
- "PRIOR-COVERED" means the name appears in a prior tracker/kept folder/pass README — it is *not* re-verified here; a prior *closure* can be stale (UNCX was re-exploited after its E-U $0 verdict).
- OPEN "funds" are point-in-time lane figures (2026-10-20); DefiLlama is inflated for several (Deri, bridges, RocketSwap).
- Tooling gaps (Mezo, Starknet, Morph, Qubic, Tron, Conflux, Hedera, some Cronos/Merlin/Bitkub/GateLayer explorers) are the dominant reason OPENs remain — they are *unverified*, not *cleared*.

*Read-only. No secrets. No keyed RPC URLs in this folder. Companion: `analysis/ALL-ROWS.md`, `summary.json`, `ci-out/`.*
