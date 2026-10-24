# BulbaSwap V3 (Morph) — zombie-hunt deep dive

**Date:** 2026-10-24 · **Chain:** Morph (chain id 2818) · **Block:** 28,776,889
**Status:** read-only; PoC fork-verified only; **no mainnet transactions** (no signed/broadcast tx).

## TL;DR

| target | live extractable (unprivileged) | why closed | latent risk |
|---|---|---|---|
| BulbaSwap V3 factory `0xFf8578C2…9CDDD` + 212 pools | **$0** | Factory bytecode is **canonical `UniswapV3Factory`** (differs from mainnet canonical only in the `NoDelegateCall` self-address immutable). Pools are therefore canonical `UniswapV3Pool` bytecode; verified source is byte-identical to v3-core; swap/flash roundtrips are net-negative. | none for the AMM; privileged `collectProtocol`/`setFeeProtocol` are owner-only (owner `0x9876…45e7`) |

## Total live extractable now: **$0** (confidence: **high**)

The AMM is an unmodified Uniswap V3 deployment. There is no share/asset math of its own to
attack, no upgradeability, and no unprivileged path to pool funds.

## The mechanism / why this was open

The pass-3 recon flagged BulbaSwap V3 as "$8.6M, Uni V3 fork — **not assessable**: Morph
explorer exposes no contract API". The open question was whether the fork had modified the V3
pool math. It did not.

- **Factory = canonical.** `eth_getCode(factory)` on Morph and on Ethereum mainnet are both
  **24,535 bytes** and differ in exactly **20 bytes** — the factory's own address, i.e. the
  `NoDelegateCall.original` immutable. Zeroing that address in each makes the two runtime codes
  **byte-identical** (`keccak256` equal). `createPool` deploys pools from the creation code
  embedded in the factory runtime code, so identical factory bytecode ⇒ identical pool code.
- **Pool = canonical.** A representative pool (`0x5191035D…`, WETH/USDT 0.05%) is **22,142
  bytes**, same as a canonical mainnet pool (`0x8ad599c3…`, USDC/WETH 0.3%). Raw difference:
  376 bytes; after zeroing token0/token1/factory/pool addresses: **57 bytes**, all the fee
  (500 vs 3000), tickSpacing (10 vs 60) and derived `maxLiquidityPerTick` constants.
- **Source = canonical.** The pool is verified on `explorer-api.morphl2.io` as `UniswapV3Pool`
  (solc 0.7.6, runs 800, `is_changed_bytecode:false`). After stripping `pragma`/`import`/
  whitespace, **all 31 flattened files are byte-identical to Uniswap v3-core**.

## Live-state assessment

| item | value |
|---|---|
| factory | `0xFf8578C2949148A6F19b7958aE86CAAb2779CDDD` (explorer name `VitDEXFactory`) |
| factory owner | `0x9876097201662D70A63C935c2f7576B35D6f45e7` |
| pools (PoolCreated logs) | 212 |
| feeAmountTickSpacing(500/3000/10000) | 10 / 60 / 200 (canonical) |
| representative pool | `0x5191035D329f481eFf0143e690e0a4e366Dd1e0c` WETH/USDT fee 500 |
| DL TVL | ~$8.8M (`registries/uniswapV3.js`, `forkedFromIds:[2198]`) |
| prices used | WETH $2,335.76, BTC $80,290.89, ETH $2,335.44 (DefiLlama 2026-10-24) |

## What an attacker can/cannot do

- **Cannot** extract pool funds: `swap`/`mint`/`burn`/`flash` follow canonical accounting;
  `collectProtocol`/`setFeeProtocol` are `onlyFactoryOwner` (owner is not the attacker).
- **Cannot** gain via round-trips: `test_swap_roundtrip_no_free_value` — 10 WETH → swap
  WETH→USDT→WETH → **9.999001… WETH** (fees paid). `test_flash_charges_exactly_pool_fee` — a
  1 WETH flash increases the pool by exactly the 0.05% fee (0.0005 WETH), no leak.
- **Can** swap/mint/burn/collect normally, i.e. no more than any Uniswap V3 pool allows.

## PoC / fork-verification

`poc/` — Foundry project, forks Morph **and** Ethereum mainnet (`vm.createFork`), no broadcast.

| test | result |
|---|---|
| `test_factory_code_is_canonical` | **PASS** — factory equal to canonical modulo self-immutable |
| `test_pool_code_is_canonical_modulo_immutables` | **PASS** — 57 residual bytes = fee/tickSpacing constants |
| `test_swap_roundtrip_no_free_value` | **PASS** — net loss after two swaps |
| `test_flash_charges_exactly_pool_fee` | **PASS** — pool delta == 0.05% fee |

Local run: `4 passed; 0 failed` (`forge test --match-path test/BulbaV3.t.sol`).
CI: see `ci-log.txt` / `ci-artifacts/` (GitHub Actions, repo `artsbykriss/ca-zombie-ci`).

## Verdict

**E-U $0 (high).** BulbaSwap V3 is canonical Uniswap V3. Closed. No residual attacker path.
The only privileged surface is the factory owner's protocol-fee controls (P), which do not
enable theft from LPs.

## Methodology & sources

- `eth_getCode` + `eth_call` over public RPCs (`rpc.morphl2.io`, `ethereum-rpc.publicnode.com`).
- Blockscout v2 API `explorer-api.morphl2.io` for verified source + ABI + `PoolCreated` logs.
- DefiLlama (`api.llama.fi`, `coins.llama.fi`) for TVL/prices; Uniswap v3-core for canonical source.
- **No secrets, no keyed URLs, no signed transactions.**

## Caveats & limitations

- Only the WETH/USDT pool was code-diffed directly; all 212 pools share the factory's creation
  code, and the factory is proven canonical, so they are all covered.
- The peripheral router/NFT-manager were out of scope (the finding is the V3 AMM); they hold no
  pool funds.

## Files

- `analysis/bytecode-evidence.md` — full code-identity evidence
- `poc/{foundry.toml,src/BulbaProbe.sol,test/BulbaV3.t.sol}` — fork PoC
- `ci/run.sh` — network job (bytecode comparison → `ci-out/bulba-bytecode.json`)
- `summary.json` — machine-readable summary
