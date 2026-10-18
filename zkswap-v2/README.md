# zkSwap V2 (legacy zkSync Era AMM) — Wave B1 deep-dive

**Date:** 2026-10-18 · **Chain:** zkSync Era (324) · **Status:** read-only; no transactions signed or sent; no keyed RPC URLs or secrets in this folder.
**Target:** DefiLlama “zkSwap V2” ($533k reported, deadUrl) — factory `0xeeE1Af1CE68D280e9cAfD861B7d4af776798F18d`, 48 pairs, unverified UniV2-style code.

## TL;DR

| Item | Live value | Why |
|---|---:|---|
| **E-U (external unprivileged)** | **$0** | 48/48 pairs have `balanceOf(pair) == getReserves()` (skim surplus = 0); 96/96 “drain the reserve with no input” `swap()` probes revert with the pair’s invariant check; `feeToSetter`/`setFeeTo`/pair `initialize` are gated (`Zks: FORBIDDEN`). |
| **H-O (LP holders)** | **$27,171 known-side / $39,390 gross** | 48 pairs hold user LP; holders can `burn()` their own LP. Not attacker-extractable. |
| **P (privileged)** | **$0 principal** | `feeToSetter` EOA can set `feeTo` (1/6 of future LP fee growth), cannot move reserves. |
| **S (stuck)** | **$0** | Every pair has live LP supply > 0; no orphaned reserves. |

**Headline: an external unprivileged attacker can extract $0 live. Confidence: high.** The $533k DefiLlama figure is not reproducible from live reserves; the real reserve value is ~$27k hard / ~$39k at pool-implied prices.

## 1. What was tested (bug hypothesis)

The residual-recon lead was: *unverified UniV2 fork; fork drift in swap/fee/collect or a missing feeTo auth would be directly harvestable.* A UniV2 pair is drainable only if one of the following is true:

1. `skim(to)` pays a surplus that is larger than the reserves (balance > reserves);
2. `swap()` does not enforce the constant-product invariant after the output transfer;
3. `mint()`/`burn()` mis-account LP (e.g., mint against a stale `totalSupply`), or a non-owner can burn another holder’s LP;
4. `initialize()` can be re-run on a live pair;
5. the factory’s `feeTo`/`feeToSetter` auth is missing (fee theft, not principal);
6. the pair uses a callback-capable token / missing reentrancy lock and can be re-entered during `swap`.

All six were checked. None is open.

## 2. Live state (exact reads)

Reads are `eth_call` at zkSync Era block **72,543,103** (2026-10-18); factory/pair code is unverified on `zksync.blockscout.com`.

### Factory `0xeeE1Af1CE68D280e9cAfD861B7d4af776798F18d`

| Call | Value |
|---|---|
| `codesize` | 7,968 bytes (unverified) |
| `allPairsLength()` | **48** |
| `allPairs(0)` | `0xa55E595aAeDA7F8F8e74b0F765B1c9f7EAa0540d` |
| `allPairs(47)` | `0x5316BDd57f39C77657D9aF788e59be6C90F2Eed6` |
| `feeTo()` | `0x0000000000000000000000000000000000000000` |
| `feeToSetter()` | `0x8Db2A6cb236Ba76f5435414E02d35828bf431BD5` (code size 0 → EOA) |
| `migrator()` | reverts (not present) |

### Pair 0 `0xa55E595aAeDA7F8F8e74b0F765B1c9f7EAa0540d`

| Call | Value |
|---|---|
| `codesize` | 44,384 bytes (EraVM; unverified) |
| LP token | name `ZKSwap Era`, symbol `ZKS-ERA`, 18 dp, `totalSupply 99,514.642933458`, 5,696 holders |
| `token0()` | `0x3355df6D4c9C3035724Fd0e3914dE96A5a83aaf4` (USDC.e, 6 dp) |
| `token1()` | `0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91` (WETH, 18 dp) |
| `getReserves()` | `8,970.503649 USDC.e` + `3.720086306644588420 WETH`, timestamp `1,792,293,272` |
| `kLast()` | 0 |
| `MINIMUM_LIQUIDITY()` | 1000 |
| `factory()` | the factory above |

At the ~$2,415 WETH / $0.99975 USDC prices used, pair0 is **$17,953.52**.

### Full 48-pair scan

`analysis/zkswap_pairs.json`, `analysis/zkswap_balances.json`, `analysis/zkswap_valuation.json`.

- **48/48 pairs: `balanceOf(token0) == reserve0` and `balanceOf(token1) == reserve1`** → `skim()` surplus is exactly **0** on every pair. No donations/airdrops are sitting above reserves.
- Reserves range from dust (pair 45: 1 wei USDT + 4.7e9 ZKB-wei) to pair0’s $17.9k. Gross value at DefiLlama/pool-implied prices: **$39,389.65**; known-side-only (excluding ZPET/ZKB/ZKS/MUTE pool-implied prices): **$27,171.08**.
- Top pairs: pair0 $17,953.52; pair19 $10,420.14 (ZPET/WETH; ZPET price is pool-implied); pair40 $6,085.93 (USDC/ZKB; ZKB price pool-implied); pair33 $955.22 (WETH/cbETH); pair6 $895.34 (USDT/WETH); pair2 $872.37 (WETH/WBTC).
- **No pair has `totalSupply == 0` with non-zero reserves** (no DeepSwap-style orphan).

The DefiLlama $533k is not supported by these reserves. The likely cause is the adapter valuing a large nominal amount of ZKS-ERA/ZKS/ZPET at a stale price; the on-chain reserves are ~$39k gross.

## 3. Attack-path checks (exact)

### 3.1 Drain probe — 96/96 revert

For every pair, two `eth_call` simulations:

```
swap(reserve0 - 1, 0, 0x…dEaD, 0x)      // try to move ~all token0 out with no input
swap(0, reserve1 - 1, 0x…dEaD, 0x)      // same for token1
```

All 96 calls revert. 95 revert with `Zks: INSUFFICIENT_INPUT_AMOUNT`; pair 45 (1 wei USDT reserve) reverts with `Zks: INSUFFICIENT_OUTPUT_AMOUNT`. This is direct evidence that the pair computes the input from the balance delta and enforces the k-invariant; there is no “free output” path. See `analysis/zkswap_drainprobe.json`.

### 3.2 Skim — 0 surplus

`skim(to)` is permissionless by design, but it can only transfer `balance - reserve`. Across all 48 pairs the difference is zero for both tokens. A `skim(0x…dEaD)` call on pair0 succeeds and transfers 0.

### 3.3 Auth / initialization gates

From a random caller (`--from 0x…dEaD`):

- `setFeeTo(address)` → revert `Zks: FORBIDDEN`
- `setFeeToSetter(address)` → revert `Zks: FORBIDDEN`
- pair `initialize(address,address)` → revert `Zks: FORBIDDEN`

So the factory fee switch and pair initialization are not unprivileged. (`feeTo` is already zero, so the protocol fee is off.)

### 3.4 Reentrancy / callback tokens

The live pairs hold only standard ERC-20s: USDC.e, WETH, USDT, DAI, WBTC, rETH, cbETH, CAKE, 1INCH, PEPE, SHIB, FLOKI, BEL, DEXTF, LUSD, ZKS, ZPET, MUTE, ZKB, and dust test tokens. None implements an ERC-777/ERC-1363-style transfer callback. A pair created by an attacker with a callback token would only custody the attacker’s own liquidity; it cannot touch the existing 48 pairs.

### 3.5 LP accounting

`mint`/`burn` are the standard UniV2 paths; `burn(to)` burns LP from the pair’s own balance (the caller must first transfer LP in). An attacker cannot burn another holder’s LP, and no pair has a stale `totalSupply` against live reserves. Pair0 `kLast = 0` and `feeTo = 0`, so `_mintFee` is a no-op.

## 4. What an attacker can / cannot do

**Can:** swap in any of the 48 pools (paying input + 0.3% fee), call `sync()`/`skim()` (0 surplus), create a new pair for arbitrary tokens (no effect on existing pairs), provide liquidity, burn their own LP.

**Cannot:** move reserves without input; set `feeTo`/`feeToSetter`; re-initialize a live pair; mint/burn someone else’s LP; collect a surplus that does not exist.

**Cost:** gas only; no flash-loan or capital path is needed for the drain probe, and it fails. There is no positive net path.

## 5. PoC / verification

- No Foundry fork: zkSync Era is not EVM-equivalent under `anvil` (EraVM), so the equivalent read-only verification is `eth_call` state simulation against the live chain; a successful `swap` in `eth_call` would be a real drain path. All 96 probes revert.
- Local evidence: `analysis/zkswap_scan.py` (48 pairs), `analysis/zkswap_skimcheck.py` (balance vs reserve), `analysis/zkswap_drainprobe.py` (96 probes), `analysis/zkswap_valuation.json`.
- CI run: **https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39105575777** (success; `ci-out/validation.json` re-reads `allPairsLength`, pair0 reserves and both drain probes).

## 6. Verdict

| Category | USD | Confidence | Basis |
|---|---:|---|---|
| **E-U** | **0** | **high** | 96/96 drain probes revert; 48/48 skim surplus 0; gates hold |
| E-U-conditional | 0 | high | only a yet-undiscovered fork-drift bug would change it; none found in the tested surface |
| H-O | 27,171 known-side / 39,390 gross | medium | LP holders can burn their own LP; prices for ZPET/ZKB/ZKS are pool-implied |
| P | 0 principal | high | `feeToSetter` can only set `feeTo` (1/6 future fee growth), no reserve access |
| S | 0 | high | all pairs have live LP supply |

**Residual / latent risk:** (a) code is unverified, so a non-invariant bug in an untested selector cannot be excluded; (b) pair0’s `blockTimestampLast` was `72,542,491` before a recent sync (an anomalous value, likely an old block-number/truncated timestamp) and its price cumulatives are huge — any external TWAP consumer would be mispriced, but no consumer was found; (c) `feeToSetter` is a single EOA and can turn on the 1/6 fee; (d) ZPET/ZKB/ZKS/MUTE have no external market, so the ~$12k of “pool-implied” value is not realizable.

## 7. Methodology / sources / files

- Enumerated `allPairs(0..47)` from the factory; read `token0`, `token1`, `getReserves`, `totalSupply` for each; read `balanceOf(pair)` for both tokens; computed surplus.
- Prices: DefiLlama `coins.llama.fi/prices/current` for known tokens; unknown tokens derived from the known side of their own pair and flagged as pool-implied.
- Simulated `swap` with `eth_call` (read-only; no tx signed/sent).
- Block: zkSync Era 72,543,103; reads over 2026-10-18.
- Files: `analysis/zkswap_pairs.json`, `zkswap_balances.json`, `zkswap_drainprobe.json`, `zkswap_valuation.json`, `zkswap_tokenmeta.json`, `pair0_code.hex`; scripts `zkswap_scan.py`, `zkswap_skimcheck.py`, `zkswap_drainprobe.py`, `zkswap_meta.py`.
- Caveats: public zkSync RPC rate limits; some reads are a few blocks apart; DefiLlama $533k not reconciled; no EraVM fork test.
- Nothing here is an instruction to transact.
