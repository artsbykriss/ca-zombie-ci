# Z3-H17 Fresh-TVL Cluster — shared facts for child agents

**Date:** 2026-10-16 · **Parent folder:** `/home/heisenberg/CA/fresh-tvl-cluster/` (write only inside it)
**Posture:** read-only; fork-only PoCs; no mainnet transactions; no secrets in any file (public RPCs / redacted URLs only).

## DefiLlama TVL snapshot (2026-10-16, api.llama.fi/protocols)

| # | Protocol | Chain(s) | DL TVL | DL slug | listedAt |
|---|---|---|---|---|---|
| 1 | NaraUSD | Ethereum | $6,817,905 | `narausd` | 2026-09-03 |
| 2 | SUBFROST | Multi (BTC+ETH) | $8,939,908 | `subfrost` | 2026-08-28 |
| 3 | up v3 | Robinhood (4663) | $4,720,145 | `up-v3` | 2026-07-18 |
| 4 | Scorch | Solana | $4,275,008 | `scorch` | 2026-08-27 |
| 5 | Icarus CL | RISE (4153) | $8,031,361 | `icarus-cl` | 2026-08-21 |
| 6 | HertzFlow | BSC (56) | $7,102,753 | `hertzflow` | 2026-08-31 |
| 7 | Longbow | Robinhood (4663) | $3,246,960 | `longbow` | 2026-09-07 |
| 8 | Meridian Perps | Robinhood (4663) | $2,920,700 | `meridian-perps` | 2026-08-04 |
| 9 | Aero Lite | Arc (5042) | $3,199,528 | `aero-lite` | 2026-09-18 |
| 10 | Fang | Robinhood (4663) | $2,874,309 | `fang` | 2026-10-13 |

DL adapter sources fetched to `analysis/cluster/dl-adapters/` (nara-usd.js, sumTokens-data2.js §subfrost, uniswapV3.js §up-v3, uniswapV2.js §icarus-cl, hertzflow.js, longbow.js, meridian-perps.js, aero-lite.js, fang.js, scorch.js).

## Chains / RPCs / explorers (all keyless public)

| Chain | id | Public RPCs (probe order) | Source/logs |
|---|---|---|---|
| Robinhood Chain | 4663 | `rpc.mainnet.chain.robinhood.com`, `robinhood-rpc.publicnode.com`, `robinhood.drpc.org` | Etherscan V2 `chainid=4663` (free tier OK; use for logs — main RPC may refuse `eth_getLogs`) |
| Arc | 5042 | `rpc.mainnet.arc.io` | Etherscan V2 `chainid=5042` (free tier OK) |
| RISE | 4153 | `rpc.risechain.com` | try Etherscan V2 `chainid=4153`; fallback Blockscout/RISE explorer |
| BSC | 56 | `bsc-rpc.publicnode.com`, `bsc-dataseed.bnbchain.org` | Etherscan V2 free tier NOT available for 56 — use Sourcify v2 + RPC |
| Ethereum | 1 | `ethereum-rpc.publicnode.com`, `eth.drpc.org`, `1rpc.io/eth` | Etherscan V2 `chainid=1` |
| Solana | — | `https://api.mainnet-beta.solana.com` (public) | `getAccountInfo`, `getTokenAccountsByOwner` jsonParsed |

Etherscan V2 helper (key in `/home/heisenberg/CA/.env` — never print it):
`KEY=$(grep '^ETHERSCANV2_API_KEY=' /home/heisenberg/CA/.env | cut -d= -f2); curl -s "https://api.etherscan.io/v2/api?chainid=<id>&module=contract&action=getsourcecode&address=<addr>&apikey=$KEY"`

Robinhood block-space note: `eth_blockNumber` (~89.7M) differs from the header number Foundry reports (~26M). Cite `eth_blockNumber` + header hash (see fables/README.md §8).

## Per-protocol addresses & hypotheses

### 1 · NaraUSD (Ethereum) — BoringVault rate-provider mint/redeem
- MCT (MultiCollateralToken) `0x4eD90999f558Fdc28606b7F7f9AFc7044befb803` · NaraUSD `0x5C6263904CCFD3Bcf1aAa6e7063dDd29743b3Bb7` · NaraUSD+ `0x1aa23CDFC941f6b54251C72012A9Bfa4bF5394D6` · protocol Safe `0xaB05c0DB9D26e96A9dcEDCAFCA23341316F6fe6F`
- Collateral: USDT, USDC, sUSDS, Midas mGLOBAL `0x7433806912Eae67919e66aea853d46Fa0aef98A8`, Blackopal LiquidStone II BoringVault share `0x15e2579B1F0cBe973889a76826D3a2313b6509c6` (6dp) priced by accountant `0xda594876BA13BCC22065E03fFcFB24A22E5c6724` (`getRate()` 18dp; 1.1358e18 on 2026-08-26)
- Hypotheses: manipulable/stale rate provider → mispriced mint/redeem; share-math rounding; redeem parity across collaterals.

### 2 · SUBFROST (Ethereum side) — frUSD mint parity
- frUSD vault proxy `0x95779e7e1c943042255b8a78273fe6de4823cf06` → impl `0x5376beedba9ba7f5b0396d28bd75473027b8bd55` (unverified at screening; re-check)
- 3CRV strategy `0x5c5d66c82e2c634074661c3e7427668737c70100` (holds 3CRV `0x6c3f90f043a72fa612cbac8115ee7e52bde6e490`; Curve 3pool `0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7`)
- Live screening reads: vault 530.85 USDC + 3,272.96 USDT; strategy 52,493.56 3CRV (≈$56k ETH-side). DL $8.94M = mostly BTC-side frBTC (Alkanes + BRC2.0) = signing-group trust model (P/S, not E-U).
- Hypotheses: mint/redeem parity bug; public vault functions; strategy withdraw to arbitrary receiver.

### 3 · up v3 (Robinhood) — Slipstream fork
- CLFactory `0x1ac9dB4a2608ba45D6127B1737949b51Bb54B7F3` (verified, solc 0.7.6); owner = Gnosis Safe 2-of-4 `0x0eEA30aBa3f07abFA20E4b544F55e0f917d9DFd8`; PoolCreated topic `0xab0d57f0…` (non-standard event shape); fromBlock 6,184,096
- Hypotheses: fork drift vs canonical Slipstream/Ramses (collect/fee-split/gauge/skim/flash callback auth).

### 4 · Scorch (Solana) — single-key upgrade authority (P)
- Program `SCoRcH8c2dpjvcJD6FiPbCSQyQgu3PcUAWj2Xxx3mqn`; upgrade authority `6km771wAtWmH16R8fsRp8zEUduDFPF1vtEXWTx4buiWZ` (verify live); TVL = SPL/Token-2022 balances of authority PDA `["authority"]` under the program (per DL adapter).
- Hypotheses: P-class upgrade exposure; E-U only if an unprivileged program instruction path exists (try Anchor IDL account `["anchor:idl", program]`; else unknown).

### 5 · Icarus CL (RISE) — Slipstream fork
- Factory `0x6f7DA11c13Ba09A153dA06d376044e5859Db607B` (allPools/allPoolsLength; start 2026-01-26). Sibling `helios-v3` on RISE factory `0xbF30bD8567628Dc4E120b7536d051EaFaA3fD0fa` (compare — same lineage).
- Hypotheses: same Slipstream drift screen as up v3 / Aero Lite.

### 6 · HertzFlow (BSC) — GMX-v2 fork
- DataStore `0xc244A37A17CE7aa14E1BDD73f6a047Ed6B56f6B8` · Reader `0xFC370bA161F4B54B12574c7e0a2121Cea57854A1` (both verified, Sourcify, solc 0.8.29 viaIR)
- Wrapped market tokens HFUSD/HFUSD1 with `redemptionBank()` / `underlyingToken()`; started 2026-08-14
- Hypotheses: DataStore config rot (price feeds, maxPriceAge, funding/impact params, market disable flags); wrapped-bank mint/redeem parity.

### 7 · Longbow (Robinhood) — tokenized-equity oracle/LLTV
- Morpho Blue singleton `0x9D53d5E3bd5E8d4Cbfa6DB1ca238AEA02E651010` (verified = standard Morpho); 55 curated market ids listed in `analysis/cluster/dl-adapters/longbow.js` (NVDA/AMZN/GOOGL/SPY/QQQ/…, ETH, WSNET, memes)
- Hypotheses: oracle/LLTV config for tokenized equities (spot vs reference price, thin DEX liquidity) → under-collateralized borrows; staleness.

### 8 · Meridian Perps (Robinhood) — sequencer-action validation
- ExchangeGateway proxy `0xD540F47F214dC7D6D244E62A6aE7e06B586Ef44A` → impl `0x0f17d8468c49d6C80E4ee10Cc87a767085A4B9A8` ("ExchangeGateway", verified, Solady UUPS)
- LP vault `0x24b84023c8e4Da635be228C380C09bfE5271BF9d` (ERC-4626) · exchange account `0x2f46C3FCe6BdA596c2771BCA618C4f69aE3E56B2` · subaccount `bytes32("primary")` · merUSD `0xad221259d4a1f2d7376dc1012c561bc86640f009`
- Hypotheses: `processActions` EIP-712/action replay/expiry; delegatecall handlers; merUSD parity.

### 9 · Aero Lite (Arc) — Slipstream fork
- CLFactory `0xb89Df768aF2CFE637ceB352c587Fe8edAf491d03` (verified, solc 0.7.6); owner = Safe-style `0x6b031ac7420c2730E65eD9F8B7b2BD0648be45c4` (same 172-byte proxy code as up-v3 owner)
- Hypotheses: same Slipstream drift screen.

### 10 · Fang (Robinhood) — Tomb-fork farm
- GenesisFarm `0xC01B68919Cd0297B1bf43E4942880E98682D3bbF` (verified) · gFANG `0x6376010d9D1F64de70D9e83c4093c8294515aC28` · Masonry `0x33Be17082Bd477dC804EdabBa1A8D777Da3F668d`; genesis tokens incl. WETH `0x0Bd7D308f8E1639FAb988df18A8011f41EAcAD73`, USDG `0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168`, NVDA, SPY, …
- Hypotheses: Tomb-lineage farm math (deposit/withdraw delta, reward debt, convert window, emission accounting).

## House rules for child agents
1. Read `/home/heisenberg/CA/ci/SUBAGENT-BRIEF.md` first; all its rules apply to you.
2. Write **only** inside `/home/heisenberg/CA/fresh-tvl-cluster/` (your `analysis/<proto>/`, your `poc/test/<Proto>.t.sol`). Never edit `poc/foundry.toml`, `poc/src/ForkHelper.sol`, other protocols' files, or anything outside this folder. Never run `git add/commit/push`. Never run `ci/ci-run.sh` (the parent runs CI).
3. Read-only mainnet: no signing/sending, no approvals, no `cast send` to real chains. Fork tests only.
4. No secrets in files. Use public RPCs or `vm.envOr` overrides; never embed keyed URLs.
5. Keep the local machine light: `cast`/`curl` reads are fine. Local forge iteration is allowed only as
   `cd /home/heisenberg/CA/fresh-tvl-cluster/poc && flock /tmp/opencode/forge-h17.lock forge test --match-path 'test/<Proto>.t.sol' -vv`
   (≤3 iterations; final verification is the parent's CI run). No local fuzz/invariant campaigns.
6. Tests: one file per protocol, unique contract name `<Proto>H17Test is ForkHelper`; import `{Test, console2} from "forge-std/Test.sol"` and `{ForkHelper} from "../src/ForkHelper.sol"`; assert both positive paths and negatives (reverts / zero attacker delta) with `console2.log` of key numbers; state the fork block in logs.
