# Residual enumeration — d2d-liqsweep

Source: `zombie-hunt-iv/wave2/d2d-liqsweep.md`

Rows/leads enumerated: **79**.

## Rows and prose/negative leads

| # | Target | Live funds | Disposition | Why / citation |
|---|---|---|---|---|
| 1 | RAAC PSM pmUSD -> sUSDS | $36.9k sUSDS; +$9.9k latent | PARKED | swap reverts today: 17.07% < 20% reserve floor; trigger watch ReserveRatioFloorUpdated or >=$10k sUSDS deposit — `d2d:19` |
| 2 | Mezo MUSD redemption arb | +$894 max | PARKED | live but below bar; already farmed — `d2d:20` |
| 3 | HyperEVM Morpho kHYPE position | $356k conditional | PARKED | HF 1.0042; not liquidatable today; keeper race — `d2d:21` |
| 4 | Robinhood Chain spUSDG Morpho | $390k conditional | PARKED | HF 1.0026; not liquidatable today — `d2d:22` |
| 5 | Enosys Loans troves | $689/liq conditional | PARKED | lowest ICR 1.158 vs MCR 1.10; no liquidations today — `d2d:23` |
| 6 | Metronome Synth msUSD | $45.8M nominal | closed (in-lane) | swap active but 10% fee vs ~10% discount => -9% round trip; no liquidatable positions — `d2d:24` |
| 7 | Fedz FUSD | $1.61M at $0.957 | PARKED | redemption restricted to Fedz-NFT holders — `d2d:25` |
| 8 | Alchemix alUSD Transmuter | $10.1M at $0.9528 | PARKED | drip-limited by repayments; unscanned — `d2d:26` |
| 9 | USDB (Blast) | $9.88M at $0.9896 | PARKED | ~1% via bridge exit; below bar — `d2d:27` |
| 10 | satUSD (River) | $124.7M at $0.9938 | PARKED | 0.62% discount; conversion path unscanned — `d2d:28` |
| 11 | BEND (Berachain) | $6.41M borrowed | closed (in-lane) | 0 accounts HF<1 with collateral; keepers active; exits thin — `d2d:S1` |
| 12 | Euler v2 / EVK Sonic | ~$1-2M borrowed | closed (in-lane) | 461 Liquidate events; keeper-active; no vacuum — `d2d:S2` |
| 13 | Neverland canonical Pool | ~$24k latent | LOW | HF 1.0204; needs -1.96%; full history scan — `d2d:L1; README:LOW#4` |
| 14 | Neverland isolated market | ~$3.1k latent | LOW | HF 1.0108; needs -1.07%; debt-token drift flagged — `d2d:L2; README:LOW#7` |
| 15 | Unitus (Conflux) | ~$33k debt | LOW | ceiling ~$1.3-1.7k; no known liquidatable — `d2d:L3; README:LOW#5` |
| 16 | Unitus all-4-chain child sweep (Conflux/Arbitrum/BSC/Ethereum) | best single ~$370 gross; ~$1.2-1.4k multi-chain best case | closed (in-lane) | no single-shot >$1k; USX exit is a TRAP (Swappi/Camelot/Pancake drained); no claims>assets race — `d2d:childC` |
| 17 | Voltage Lending (Fuse) | ~$85 | LOW | 2 real accounts +$44/+$41; 7 zero-collateral traps — `d2d:L4; README:LOW#6` |
| 18 | Colend (CORE) | $0 borrowed | closed (in-lane) | no debt; nothing to liquidate — `d2d:L5` |
| 19 | Klend | $0 / dead | closed (in-lane) | klend.finance parked; DL entry BSC/OKExChain $0; no Kaia lending venue — `d2d:L6` |
| 20 | Zappy (Telos) | ~$90k live per r7; DL DEX $2.6k | LOW | d2d domain-dead contradicts r7 on-chain reads; README takes r7 on-chain evidence; verify troves before action — `d2d:L7; README:LOW#8` |
| 21 | Curvance (Monad) | $80.68M debt | closed (in-lane) | 24,334 Borrow events; no account at true liquidation threshold — `d2d:childB` |
| 22 | Takara Lend (Sei) | ~$0.011 extractable | closed (in-lane) | 558 live borrowers; only material underwater account stripped; max $0.0055 — `d2d:childA` |
| 23 | dTRINITY dLEND (Sonic) | $0 borrowed | closed (in-lane) | gap closed — `d2d:S-neg` |
| 24 | Silo v2 Sonic | $0 borrowed | closed (in-lane) | dead leg — `d2d:S-neg` |
| 25 | LayerBank | $0 except RSK/RHC | closed (in-lane) | RSK prior corpus; RHC other lanes — `d2d:S-neg` |
| 26 | ZeroLend | $0 borrowed | excluded | shut Feb-2026; prior H-5 census — `d2d:S-neg` |
| 27 | Ionic / Angle / Mendi / YeiLend (4 names) | - | excluded | prior corpus / shut — `d2d:S-neg` |
| 28 | INIT Capital / Orbit / Impermax v2 / Sumer.money / Gravita (5 names) | $0-tiny | closed (in-lane) | nothing — `d2d:S-neg` |
| 29 | Kaia / Chiliz / WEMIX / Metis / Fuse / Manta / Blast / Mode / Core lenders (9 names) | - | closed (in-lane) | no material borrowed or dead — `d2d:S-neg` |
| 30 | Aave v3 long-tail legs (Celo/Gnosis/Sonic/Linea/Scroll/Manta/Mode) (7 names) | - | closed (in-lane) | keeper-run; sizes small — `d2d:S-neg` |
| 31 | CDP depeg re-screen (~423 stablecoins) | - | closed (in-lane) | no new depegs; known artifacts — `d2d:S-neg` |
| 32 | Dolomite (Berachain/Ethereum) | $2.42M/$396M borrowed | closed (in-lane) | no under-margined account with collateral; sticky Liquid gated to whitelisted partial liquidators — `d2d:S-neg` |
| 33 | Altura / AVLT | $9.7M bad debt | excluded | ZH2 H2-02; lender-side loss, not E-U — `d2d:35` |
| 34 | Main Street USD (msUSD) | $289.94 USDC minter | closed (in-lane) | no redeem function; collapsed — `d2d:36` |
| 35 | Tangible USDR / Lybra eUSD v2 / Fathom FXD / Sovryn DLLR / Babelfish XUSD / Resolv USR / Cod3x cdxUSD / USDD / Kolibri / Liquid Loans / AP USDA / Anzen / HexTrust / LISUSD / BOLD / satUSD / USDo / REUSD (18 names) | - | closed (in-lane) | dead artifacts/custodial/at peg; no permissionless par route — `d2d:37` |
| 36 | Flying Tulip Lend (Sonic $2.2M + Ethereum $4.2M borrowed) | $6.4M | PARKED | hybrid PCA/PUT soft liquidation; not scoped — `d2d:94` |
| 37 | Hydro Lending + Neptune (Injective) (2 names) | $2.4M + $2.0M | PARKED | CosmWasm path not verified — `d2d:94` |
| 38 | TermMax (Ethereum) | $21M | PARKED | fixed-rate AMM liquidation engine not scoped — `d2d:94` |
| 39 | Silo v2 Arbitrum/ETH/Avax | $2.2M borrowed | PARKED | isolated-pair borrower enumeration not run — `d2d:94` |
| 40 | apxUSD (Base) | $9.4M at $0.9859 | PARKED | no permissionless redeem path found in quick pass — `d2d:94` |
