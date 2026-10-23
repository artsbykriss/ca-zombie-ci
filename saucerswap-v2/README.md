# SaucerSwap V2 (Hedera) — residual unprivileged-value review

**Date:** 2026-10-23 · **Chain:** Hedera mainnet (chainId 295) · **TVL:** ~$15.89M (DefiLlama) / **$17.61M** measured 2-sided
**Status:** read-only; PoC is **local (non-forked)** and fork-verified only where possible; **no mainnet transaction signed or sent**.
**Scope:** `SaucerSwapV2Factory`, `UniswapV3Pool` (CLMM), `NonfungiblePositionManagerV2`, `SwapRouter`, `QuoterV2`, Hedera HTS helpers (`TransferHelper`, `AssociateHelper`, `NFTHelper`, `HbarConversion`).
**Row:** ZH4 pass-3 `lane-dex-nonevm.md` row 6 (OPEN #3). Prior corpus closed SaucerSwap **V1** only.

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why closed / open | Latent risk |
|---|---|---|---|
| SaucerSwap V2 CLMM (`0x…3c3951` factory, 56 pools, $17.6M) | **$0** | Faithful UniV3 port. Every value path is auth-gated: pool positions keyed by `msg.sender`; LP positions bound to the HTS NFT owner; `collectProtocol` factory-owner only; HTS `transferToken` allowance enforced by the network | permissionless periphery sweep helpers; single-EOA factory owner; HTS issuer freeze/wipe power |
| Pool native HBAR (mint fees, 2,132 HBAR) | $0 E-U (**$171.82 P-class**) | only `UniswapV3Pool.collectProtocol` (factory owner) moves it | owner key compromise |
| Periphery sweep helpers (`refundETH`/`unwrapWHBAR`/`sweepToken`) | $0 (contracts hold 0) | canonical UniV3 "sweep" helpers; only move balances already in the router/NFPM | any HBAR/token left in the router/NFPM is takeable by anyone |

## 2. Total live extractable now: **$0.00** (external unprivileged) — confidence **high**

Breakdown (measured 2026-10-23, Hedera block ≈ 101,461,655):

- **E-U (external unprivileged): $0.00** — no permissionless path moves another party's principal, fees or position value.
- **H-O (holder/user-only): $0.00 recoverable** (LPs can always withdraw *their own* liquidity via the normal, auth-gated `decreaseLiquidity`/`collect` — that is not attacker-extractable value).
- **P (privileged): $171.82** — native HBAR accrued from mint fees across 29 pools, sweepable only by the factory owner via `collectProtocol` → `rentPayer`; plus owner-collectable protocol fees (e.g. USDC/HBAR `feeProtocol=6/6`).
- **S (stuck): $0** — no bricked balances found (pool creation is frozen by design, see §5).

The headline is an honest **$0 with proof**: all candidate unprivileged value paths are gated, demonstrated by reverting/zero tests (§7) and by the deployed code (§4).

## 3. Background: what this is

SaucerSwap V2 is a **modified fork of Uniswap V3** (per its own whitepaper; the factory file is literally `UniswapV3Factory.sol`). It is deployed on Hedera, so the Uniswap core/periphery contracts were adapted to the Hedera Token Service (HTS): tokens are HTS tokens with an ERC-20/721 facade; all token movement goes through the HTS precompile at `0x167`; the HBAR↔tinycent exchange-rate precompile `0x168` prices the pool-creation/mint fees; LP positions are represented by an **HTS NFT** instead of an internal ERC-721.

All four core contracts are source-verified on Sourcify (solc 0.8.12), so this review is against real deployed code, not a decompilation.

## 4. The "bug"/mechanism in exact terms — and why there is none E-U

The fork is semantically a faithful port of UniV3 (full diff in `analysis/source_review.md` and `analysis/diff_*.txt`). The Hedera-specific deltas and their security impact:

1. **Pool token transfers** use `TransferHelper.safeTransfer(token, address(this), recipient, amount)` → HTS precompile `transferToken(token, sender, receiver, amount)` (`src/core/libraries/TransferHelper.sol`). The caller is always the pool moving *its own* value, which the HTS authorizes (`docs.hedera.com/evm/development/security`: *"transferToken … will behave as transfer in ERC20/721 if the caller owns the value being transferred, otherwise it will rely on approve spender allowances"*).
2. **Periphery `safeTransferFrom`** likewise calls HTS `transferToken` with an explicit `sender` (`src/periphery/libraries/TransferHelper.sol`). This is the one place that *looks* like an arbitrary-`from` drain (canonical uses ERC-20 `transferFrom`), but the network **enforces an owner-granted spender allowance** when `sender ≠ caller`, so it is equivalent to ERC-20 `transferFrom`. Moreover the `payer` is always the external caller (`MintCallbackData.payer = msg.sender` in `LiquidityManagement.addLiquidity`; `SwapCallbackData.payer = msg.sender` in `SwapRouter.exactInputSingle`), and `multicall` uses `delegatecall` preserving `msg.sender` — so no victim-as-payer injection.
3. **LP position ownership** — `NonfungiblePositionManager.isAuthorizedForToken(tokenSN)` reads `IERC721(nft).ownerOf(tokenSN) / getApproved / isApprovedForAll` on the HTS LP NFT. `nft` is set exactly once by `deployer` in `createNonFungible` (guarded by `onlyOnce`) and is immutable thereafter → **no cross-collection `tokenId` confusion**. `decreaseLiquidity`, `collect` and `burn` all carry this modifier. (`increaseLiquidity` and `mint` are permissionless — canonical — but only *add* liquidity.)
4. **Pool position accounting** — `UniswapV3Pool.collect/burn` use `positions.get(msg.sender, …)`, so a position belongs to its `msg.sender`; there is no external owner parameter to spoof.
5. **Protocol fees / HBAR** — `collectProtocol` is `onlyFactoryOwner`; the pool's retained native HBAR (mint fees) leaves only through it, to `rentPayer`. The factory's `collectRent()` is permissionless but merely forwards *factory* HBAR to `rentPayer` (no theft).
6. **Port fidelity** — the 0.7.6→0.8.12 port of `LiquidityMath.addDelta` (audit UVP-02M) uses checked arithmetic that reverts on the same conditions as canonical; the oracle/tick/swap-math libraries are unchanged in semantics.
7. **No proxies** — EIP-1967 implementation slot is `0` on factory, NFPM, router and quoter (not upgradeable).

## 5. Live-state assessment

All addresses verified with `eth_getCode`; source verified on Sourcify. Full detail in `analysis/live_state.md`.

| Contract | HTS id | EVM address | Code | Sourcify |
|---|---|---|---|---|
| SaucerSwapV2Factory | 0.0.3946833 | `0x00000000000000000000000000000000003c3951` | 24,535 B | exact |
| SaucerSwapV2SwapRouter | 0.0.3949434 | `0x00000000000000000000000000000000003c437a` | 13,831 B | exact |
| SaucerSwapV2QuoterV2 | 0.0.3949424 | `0x00000000000000000000000000000000003c4370` | 10,535 B | exact |
| NonfungiblePositionManagerV2 | 0.0.4053945 | `0x00000000000000000000000000000000003ddbb9` | 21,218 B | exact |
| LP NFT (HTS) | 0.0.4054027 | `0x00000000000000000000000000000000003ddc0b` | HTS redirect | — |

- **Factory:** `owner = 0x…103179` (EOA), `rentPayer = 0x…102556` (EOA), `mintFee = 500000000` tinycents (~$0.05/mint), `poolCreateFee = 1e16` tinycents (**~$1,000,000** → pool creation effectively frozen; last pool created 2026-07-06).
- **LP NFT:** supplyKey = the NFPM contract only; **no** admin/kyc/freeze/wipe/pause/metadata keys; `totalSupply = 3881`; `treasury = 0.0.4053945`.
- **Pools:** **56** `PoolCreated` events (mirror-node logs), fee tiers 500/1500/3000/10000. Measured 2-sided TVL **$17,614,148**; largest pools: HBARX/HBAR $7.46M, USDC/HBAR $4.15M, USDC/HTS-WETH $1.27M, HBAR/HTS-WBTC $0.66M, HBAR/HTS-WETH $0.65M.
- **Native HBAR in pools:** 2,132.29 HBAR ≈ **$171.82** (mint fees) — P-class.
- **Periphery balances:** router, NFPM, quoter, factory all hold **0** HBAR and 0 tokens.
- **Wiring check:** `PoolAddress.POOL_INIT_CODE_HASH = 0xa6f9…6a8c`; CREATE2 recomputation for USDC/HBAR fee-1500 reproduces the on-chain pool `0xc5b707348da504e9be1bd4e21525459830e7b11d` → deployed pool bytecode == verified source.

## 6. What an attacker can / cannot do

| Path | Result | Precondition / cost |
|---|---|---|
| `pool.swap` / `flash` | only on paid terms; no free value | capital + fees |
| `pool.mint` | adds liquidity (donation); HBAR fee required | costs HBAR |
| `pool.collect` / `burn` on another's range | **returns 0 / no effect** | position keyed by `msg.sender` |
| `pool.collectProtocol` | **reverts** for non-owner | `onlyFactoryOwner` |
| `NFPM.decreaseLiquidity` / `collect` / `burn` on another's `tokenSN` | **reverts `not authorized`** | must own/be approved on the HTS LP NFT |
| `NFPM.mint` / `increaseLiquidity` | only adds liquidity; mints/extends an NFT you own | gas + HBAR mint fee |
| `factory.collectRent()` | sends factory HBAR to `rentPayer` (not the caller) | permissionless, zero profit |
| `NFPM.refundETH()` / router `unwrapWHBAR`/`sweepToken` | sweeps balances **already in the contract** to any recipient | contracts hold 0 today → $0 |
| `pool.initialize` / `increaseObservationCardinalityNext` | no funds involved | permissionless |

Costs to attempt any theft: gas (Hedera ≈ $0.0001–$0.05/tx) — irrelevant because no path yields value.

## 7. PoC / verification

Because Hedera's HTS/HAS precompiles (`0x167`, `0x168`) are system contracts with no EVM bytecode, a
`--fork-url https://mainnet.hashio.io/api` fork cannot execute the token paths. Per the brief we
therefore run a **local, non-forked** Foundry suite that compiles the **real verified SaucerSwap V2
source** and mocks the two precompiles, then exercises the full mint→burn→collect lifecycle plus every
candidate unprivileged path.

- `poc/src/core/**`, `poc/src/periphery/**` — verbatim verified SaucerSwap V2 source (solc 0.8.12).
- `poc/src/mocks/` — `MockHTS` (0x167), `MockExchangeRate` (0x168), `MockERC20`, `MockNFT` (HTS LP-NFT stand-in), `MockWHBAR`, `Minter` (an ordinary LP implementing the mint callback).
- `poc/test/SaucerSwapAuth.t.sol` — **10 tests, 10 PASS**.

| Test | Asserts |
|---|---|
| `test_harness_pool_mint_burn_collect_owner` | real pool mint→burn→collect works (harness is real) |
| `test_NFPM_decreaseLiquidity_nonOwner_reverts` | non-owner `decreaseLiquidity` reverts `not authorized` |
| `test_NFPM_collect_nonOwner_reverts` | non-owner `collect` reverts `not authorized` |
| `test_NFPM_burn_nonOwner_reverts` | non-owner `burn` reverts `not authorized` |
| `test_NFPM_unmintedSerial_reverts` | unknown `tokenSN` cannot reach another position |
| `test_Pool_stranger_cannot_collect_others_position` | stranger `pool.collect` returns 0; owner still collects |
| `test_Pool_collectProtocol_onlyFactoryOwner` | non-owner `collectProtocol` reverts |
| `test_Pool_collectProtocol_owner_sweeps_hbar_to_rentPayer` | pool HBAR → `rentPayer` (privileged path) |
| `test_NFPM_refundETH_permissionless_sweeps_contract_balance` | leftover HBAR in NFPM is sweepable by anyone (latent, $0 today) |
| `test_harness_nfpm_wired` | `nft`/`deployer`/owner wiring correct |

Run: `cd poc && forge test -vvv` → **10 passed, 0 failed**.
CI: `bash /home/heisenberg/CA/ci/ci-run.sh saucerswap-v2` → run URL recorded in `ci-log.txt` (see §Files).

## 8. Verdict, residual & latent risk, blockers

**Verdict: $0 extractable by an external unprivileged attacker (high confidence).** SaucerSwap V2 is a
close UniV3 fork; the Hedera adaptations do not open a permissionless value path, and Hedera's own
security model closes the one place (`safeTransferFrom` → HTS `transferToken`) that could have been an
arbitrary-`from` drain.

Residual / latent risk (not E-U today):

- **Permissionless sweep helpers** (`refundETH`, `unwrapWHBAR`, `sweepToken`, `sweepTokenWithFee`) on the router and NFPM take any balance already in those contracts. Currently 0, but any future accidental transfer (or a partially-refunded pool-creation/mint) is immediately takeable by anyone.
- **Single-EOA factory owner** can change `mintFee`/`poolCreateFee`/`rentPayer`, enable fee tiers, and sweep pool HBAR + protocol fees. Key compromise = P-class loss of ~$172 HBAR + protocol-fee revenue, and could raise fees (griefing). No path to LP principal.
- **Pool creation frozen** (`poolCreateFee ≈ $1M`): an operational, not security, condition.
- **HTS issuer power:** a pool token's own admin (freeze/wipe/pause keys) could brick a pool — an external-token risk, not SaucerSwap's.

Blockers to a true fork PoC: Hedera HTS/HAS precompiles are not forkable via JSON-RPC; no Hedera fork RPC is available in CI. Documented rather than hidden.

## 9. Methodology, caveats, files

**Method.** (1) `eth_getCode` + Sourcify v2 for all four contracts; (2) mirror-node `/results/logs` to
enumerate all 56 `PoolCreated` events; (3) `eth_call balanceOf` + SaucerSwap token prices + DefiLlama
HBAR price for TVL; (4) line-by-line diff against canonical UniV3 core (0.7.6) and periphery; (5)
Hedera security-model docs + Omniscia/Halborn audit reports for the HTS semantics; (6) local Foundry
PoC compiling the real source with mocked precompiles.

**Caveats.** (a) The PoC is local, not a Hedera fork (precompiles unmockable on a JSON-RPC fork); the
mock's `transferToken` does not re-implement allowance checks, so allowance enforcement is argued from
Hedera's documented model, not reproduced. (b) TVL is a point-in-time 2026-10-23 read; DefiLlama's
$15.89M and our $17.61M differ mainly by whether HBARX (staked HBAR) pools are double-counted. (c)
Protocol-fee accrual across all 56 pools was not summed (only spot-checked). (d) Point-in-time; re-read
before acting. Nothing here is an instruction to transact.

**Files.**
```
saucerswap-v2/
├── README.md                     (this file)
├── summary.json                  (machine-readable)
├── analysis/
│   ├── live_state.md             (addresses, blocks, balances, wiring check)
│   ├── source_review.md          (fork diff vs canonical UniV3 + negative results)
│   ├── enumerate_pools.py        (read-only enumeration script)
│   ├── pools.json                (56 PoolCreated events)
│   ├── tokens.json / pool_balances.json / pool_tvl.json
│   ├── diff_*.txt                (per-library diffs vs canonical)
│   └── sources/{core,periphery-nfpm,periphery-router,periphery-quoter}
├── poc/                          (Foundry; forge-std vendored; 10/10 PASS)
│   ├── foundry.toml
│   ├── src/{core,periphery,oz,mocks}
│   └── test/SaucerSwapAuth.t.sol
├── ci/run.sh                     (optional read-only live-state snapshot → ci-out/)
├── ci-out/                       (CI results)
├── ci-log.txt / ci-artifacts/    (written by ci-run.sh)
└── summary.json
```
