# ZH4-RESIDUAL DEEP-DIVE — SaucerSwap V2 · SMARDEX USDN · Venus Flux

**Date:** 2026-10-23 (re-verified 2026-10-24) · **Mode:** read-only (no tx signed/sent; fork-only PoCs; keyless public RPCs; no secrets in this folder)
**Parent:** ZH4 pass-3 residual reconciliation (OPEN #3/#4/#5) · **Status:** COMPLETE — all three deep-dives delivered with green CI; consolidated verdict below.

This umbrella folder holds the coordinator's **independent live-state verification** and the per-target index. The three deep-dive deliverables are the sibling folders:

| Target | Chain | Live funds (2026-10-23) | Deep-dive folder | Headline E-U |
|---|---|---:|---|---:|
| SaucerSwap V2 (UniV3-fork CLMM) | Hedera (295) | **$16.78M** (DL 2026-10-20) | `../saucerswap-v2/` | **$0.00** (high) |
| SMARDEX USDN | Ethereum (1) | **$1.36M** (453.5 wstETH @ $3,001.10) | `../smardex-usdn/` | **$0.00** (high) |
| Venus Flux (Instadapp Fluid) | BSC (56) | **$2.17M supply / $1.29M borrowed** (DL 2026-10-23) | `../venus-flux/` | **$0.00** (high) |

## Consolidated verdict

**Total live extractable by an external unprivileged attacker: $0.00** (confidence **high** across all three).
Categories: **E-U $0 · H-O $0 · P** (SaucerSwap: $171.82 pool HBAR, factory-owner only) **· S $0**.
Latent (re-arm) risks are tracked per target and are **not** E-U today:

| Target | Headline E-U | Why $0 | Latent / conditional (not E-U today) |
|---|---:|---|---|
| SaucerSwap V2 | $0 | Faithful UniV3 port; pool positions keyed by `msg.sender`, LP positions bound to the HTS NFT owner, `collectProtocol` factory-owner-only, Hedera network enforces HTS spender allowances on the `safeTransferFrom`→`transferToken` path | permissionless sweep helpers ($0 today); single-EOA owner; pool creation frozen (fee ≈$1M) |
| SMARDEX USDN | $0 | No tick liquidatable (weakest of 28 positions **6.87 %** from liq, block 26,265,216); `liquidate` pays only a ≤0.5 ETH reward and needs a real Wormhole-signed Pyth price ≤45 s old; every setter/upgrade role-gated | ≤1.0–1.5 ETH reward after a genuine ≥6.9 % crash in 45 s; empty pending-action queue |
| Venus Flux | $0 | wstUSR oracle **is broken** (redemption rate 1.13297 vs ~$0.083 market, ≈13.6×) but the market is **fully paused** (borrow limit 1 wei, Liquidity user-pause bits, DEX swap paused, DEX share caps 0) | **≈$244k** over-borrow the instant governance un-pauses / re-arms, or on any other chain with the same stale redemption-rate oracle |

All three verdicts were re-checked live on **2026-10-24** (Ethereum 26,265,216 · BSC 129,587,304 · Hedera 101,522,768) and are unchanged.

> Note on folder layout: the principal's CI hint names `saucerswap-smardex-venus`; because the CI helper syncs exactly one folder, each deep-dive folder runs its own CI (`ci-run.sh saucerswap-v2|smardex-usdn|venus-flux`), and this umbrella folder runs a 4th, independent cross-chain live-state job.

---

## Independent live-state verification (this folder)

Blocks at read time: **Ethereum 26,253,680 · BSC 129,277,882 · Hedera 101,459,790**.
Raw dump: `analysis/independent-live-state.json`; CI job: `ci/run.sh` → `ci-out/independent-live-check.json`.

### SMARDEX USDN (Ethereum) — headline funds confirmed
- Protocol ERC1967 proxy `0x656cB8C6d154Aad29d8771384089be5B5141f01a` → impl slot = `0x271df5517a4daacb7cab988aa64d23debda4c498` (byte-for-byte the repo's own `broadcast/01_DeployProtocol.s.sol/1` deployment).
- `getBalanceVault()` = **266.2209 wstETH**; `getBalanceLong()` = **187.2641 wstETH** → **453.485 wstETH ≈ $1,361,087** at $3,001.10/wstETH.
- `getTotalLongPositions()` = **29** (lane said 28); `usdnPrice()` = **1.0000749** (protocol price ≈ par); USDN `totalSupply` = **805,742.54**.
- **Re-check 2026-10-24 (block 26,265,216):** vault 269.898 + long 182.598 = **452.496 wstETH**; `getTotalLongPositions()` = **28** (one closed); weakest position buffer **6.87 %** (still not liquidatable).

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

## CI runs (all green)
- SaucerSwap V2 (10/10): https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39923618014
- SMARDEX USDN (9/9): https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39960310248
- Venus Flux (10/10): https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39961692014
- Umbrella live-state (this folder): https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39916130311

*Read-only. No secrets. No transactions.*
