# ZH4-RESIDUAL DEEP-DIVE — SaucerSwap V2 · SMARDEX USDN · Venus Flux

**Date:** 2026-10-23 · **Mode:** read-only (no tx signed/sent; fork-only PoCs; keyless public RPCs; no secrets in this folder)
**Parent:** ZH4 pass-3 residual reconciliation (OPEN #3/#4/#5) · **Status:** in progress — per-target verdicts finalised below once the three deep-dive folders complete and their CI runs are green.

This umbrella folder holds the coordinator's **independent live-state verification** and the per-target index. The three deep-dive deliverables are the sibling folders:

| Target | Chain | Live funds (2026-10-23) | Deep-dive folder | Headline E-U |
|---|---|---:|---|---:|
| SaucerSwap V2 (UniV3-fork CLMM) | Hedera (295) | **$16.78M** (DL 2026-10-20) | `../saucerswap-v2/` | _pending_ |
| SMARDEX USDN | Ethereum (1) | **$1.36M** (453.5 wstETH @ $3,001.10) | `../smardex-usdn/` | _pending_ |
| Venus Flux (Instadapp Fluid) | BSC (56) | **$2.17M supply / $1.29M borrowed** (DL 2026-10-23) | `../venus-flux/` | _pending_ |

> Note on folder layout: the principal's CI hint names `saucerswap-smardex-venus`; because the CI helper syncs exactly one folder, each deep-dive folder runs its own CI (`ci-run.sh saucerswap-v2|smardex-usdn|venus-flux`), and this umbrella folder runs a 4th, independent cross-chain live-state job.

---

## Independent live-state verification (this folder)

Blocks at read time: **Ethereum 26,253,680 · BSC 129,277,882 · Hedera 101,459,790**.
Raw dump: `analysis/independent-live-state.json`; CI job: `ci/run.sh` → `ci-out/independent-live-check.json`.

### SMARDEX USDN (Ethereum) — headline funds confirmed
- Protocol ERC1967 proxy `0x656cB8C6d154Aad29d8771384089be5B5141f01a` → impl slot = `0x271df5517a4daacb7cab988aa64d23debda4c498` (byte-for-byte the repo's own `broadcast/01_DeployProtocol.s.sol/1` deployment).
- `getBalanceVault()` = **266.2209 wstETH**; `getBalanceLong()` = **187.2641 wstETH** → **453.485 wstETH ≈ $1,361,087** at $3,001.10/wstETH.
- `getTotalLongPositions()` = **29** (lane said 28); `usdnPrice()` = **1.0000749** (protocol price ≈ par); USDN `totalSupply` = **805,742.54**.

### Venus Flux (BSC) — identity + a material correction to the lane premise
- Identity confirmed: `flux.venus.io/lending/56`, DefiLlama slug `venus-flux`, category Lending, **$2,169,068 supply / $1,287,104 borrowed** (2026-10-23).
- Fluid `Liquidity` proxy `0x52Aa899454998Be5b000Ad077a46Bbe360F4e497` (impl `0x3560a1d1e9f30b61cd0e24349f7a23890f6261d9`); `LiquidityResolver 0xca13A15de31235A37134B4717021C35A3CF25C60`.
- `listedTokens()` = BNB, USDC, USDT, BTCB, ETH, **wBETH**, **syrupUSDT**, **wstUSR**, **U (United Stables)**, **asBNB (Astherus BNB)**.
- **Correction:** lane-lending row 8 called the four exotic tokens "Venus LST/LP wrappers". On-chain they are **third-party** tokens — Maple `syrupUSDT`, Resolv `wstUSR`, `U` (United Stables), Astherus `asBNB` — i.e. the risk is Fluid's **oracle path for exotic collateral**, not a Venus wrapper. (See `../venus-flux/` for the traced oracle verdict.)

### SaucerSwap V2 (Hedera) — live and UniV3-shaped
- Factory `0.0.3946833` = `0x…003c3951` (24,535 B code); `feeAmountTickSpacing(3000)` = **60** (canonical UniV3); factory `owner()` = `0x…00103179` (Hedera account `0.0.1061241`).
- SwapRouter `0x…003c437a` (13,831 B); NonfungiblePositionManagerV2 `0x…003ddbb9` (21,218 B).
- `name()`/`totalSupply()` on the position manager revert via the JSON-RPC relay — consistent with the position NFT being a **Hedera Token Service (HTS)** token (`0.0.4054027`) rather than a pure ERC721; this is also the main fork-testing limitation for Hedera (HTS precompiles). Documented in `../saucerswap-v2/`.

---

## Method / caveats
- All reads via keyless public RPCs (`https://ethereum-rpc.publicnode.com`, `https://bsc-rpc.publicnode.com`, `https://mainnet.hashio.io/api`). No keyed URL is stored anywhere in this folder.
- USD prices from DefiLlama `coins.llama.fi` at the stated timestamp; confidence 0.99.
- The per-target folders own the code review + fork PoCs; this folder only cross-checks live state and reconciles the three verdicts.

## Files
- `README.md` (this), `summary.json`
- `analysis/independent-live-state.json`
- `ci/run.sh`, `ci-out/independent-live-check.json`
- `ci-log.txt`, `ci-artifacts/` (filled by `ci-run.sh`)

*Read-only. No secrets. No transactions.*
