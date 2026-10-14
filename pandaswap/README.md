# PandaSwap (BSC) — L2 Phase-2 deep dive

**Date:** 2026-10-14 · **Chain:** BSC (56) · **Status:** read-only; PoC fork-verified only; no mainnet transactions
**Triage source:** `l2-triage-a/summary.json` row `pandaswap` — $84,422 live (high confidence), factory `0x9Ad32bf5DaFe152Cbe027398219611DB4E8753B3` (129 pairs).

---

## 1. TL;DR

| Target | Live value (on-chain) | Extractable by external unprivileged attacker | Why closed / open | Latent risk |
|---|---|---|---|---|
| 129 PandaSwap V2 pairs (LP reserves) | **$83,531.70** priced side (block 127,538,000s); DefiLlama live $108,471 | **$0** | Reserves belong to LP holders; `burn()`/`removeLiquidity` live and unpaused → **H-O** | LP keys lost → becomes S (the largest LP holder is a codeless address, see §3) |
| `balance − reserve` excess (skim) | **$0** — 0 pairs with real excess (full 129-pair single-call re-read + CI) | **$0** | All pairs reconcile; earlier "huge excess" readings were an RPC batch-misalignment artifact (§7) | Stray transfers would be skimmable by anyone (pairs are stock UniV2) |
| Stale-price arbitrage vs live market | POLS/WBNB pool $3.26k, others small | **$0 (fork-proven negative)** | PandaSwap pool prices match the live PancakeSwap pools to <0.5%; a DefiLlama-price-based model suggested ~$569 but the fork PoC shows **all trade sizes lose money** (best −0.036 WBNB at 0.2 WBNB in) | If Pancake liquidity for a token dies, no exit market exists at all |
| Fake/spam-token pairs (vBTC/WBNB etc.) | $213 WBNB-side dust in 4 pairs | **$0 (fork-proven)** | No excess; `skim` yields 0; output-without-input reverts `UniswapV2: INSUFFICIENT_INPUT_AMOUNT` | — |
| BambooMaker (factory `feeTo`) protocol-fee LP | ~**$23** of accumulated fee-LP | **$0** | `convert()` is permissionless (EOA-only) but proceeds go to the BambooBar (xBAMBOO holders); the maker's own LP is the only value at stake | Sandwiching `convert()` could extract a fraction of ~$23 (onlyEOA blocks flash loans) |
| PNDA token mint/cap | 74.95B PNDA supply; cap 100B | **$0 (P)** | `mint()` onlyOwner (owner = codeless address `0x9942cb4c…`, nonce 1); `manualMint` bricked (`manualMinted` 250M > limit 100k); `capUpdate` onlyAuthorized (deployer EOA) | Owner key, if alive, can mint up to 25B more PNDA — but PNDA exit liquidity is only ~$4.5k |
| BambooBar (xBAMBOO) | 1.554B PNDA backing; 804.7M xBAMBOO | **$0** | `leave()` pays pro-rata PNDA to xBAMBOO burners → **H-O** | — |
| Farm (MasterChef/MasterChefV2) | not live | **$0** | The PNDA owner (intended MasterChef) has **no code**; no MasterChef holds LP; no PNDA emissions since supply went static | — |

**Total live extractable by an external unprivileged attacker now: ≈ $0 — high confidence.**
The triage's $84.4k is LP-owned value (H-O), not attacker-extractable. The strongest positive result is a full cryptographic proof that all 129 pairs execute the stock, verified UniswapV2Pair code (§2), plus a fork-measured negative arbitrage result on the most mispriced-looking pair (§5).

---

## 2. Deployed reality and the pair-code proof

| Contract | Address | What it is |
|---|---|---|
| Factory | `0x9Ad32bf5DaFe152Cbe027398219611DB4E8753B3` | Verified `UniswapV2Factory` (solc 0.5.16, optimizer 200), "PandaSwapv2" branding; 10,941 B runtime; `allPairsLength() = 129`; `pairCodeHash() = 0xb785cebe4aa62be64e9e412e79c479c58578c1c3d0ffbb4602a9217d8b289559` |
| `feeTo` | `0xe1a2CD535C4e7d9C2C187e529f9f491cceA41e07` | **BambooMaker** (verified, solc 0.6.12): `factory()` = this factory, `bar()` = BambooBar, `owner()` = `0x3bC3…6951` |
| `feeToSetter` | `0x3bC3c8aF8CFe3dFC9bA1A57c7C3b653e3f6d6951` | EOA (also PNDA-authorized, maker owner) |
| BambooBar | `0xef88e0d265ddc8f5e725a4fda1871f9fe21b11e2` | xBAMBOO (name "BambooBar", symbol BAMBOO); stakes PNDA (`sushi()` = PNDA); `leave()` pro-rata |
| PNDA | `0x47DcC83a14aD53Ed1f13d3CaE8AA4115f07557C0` | Verified `PndaToken`; owner `0x9942cb4c…` (codeless); no transfer fees |
| All 129 pairs | e.g. `0x059fC92273CdF0809ba45f199E0a12d8899Ab402` (ETH/PNDA) | Unverified on BscScan but **provably the stock pair code** (below) |

### The proof that pairs are stock (no hidden backdoor)

1. **The factory's runtime embeds the pair creation code verbatim** (solc's `type(UniswapV2Pair).creationCode` constant): bytes `factory_code[1674:10889]` (9,215 B).
2. `keccak256(factory_code[1674:10889]) == factory.pairCodeHash()` — verified (`analysis/` + CI `proof` block). The on-chain hash is exactly the keccak of the embedded blob.
3. **Deployed pair runtime == the runtime portion of that blob**: `factory_code[1937:10807]` (8,870 B) equals the deployed code of pair `0x059fC9…` byte-for-byte.
4. **CREATE2 derivation matches**: for every pair, `CREATE2(factory, keccak256(token0‖token1), pairCodeHash)` equals the deployed pair address (129/129 in CI; 111/111 locally with no mismatch).
5. **The embedded blob == the verified BscScan source compiled by us**: compiling the exact verified bundle with solc 0.5.16 / optimizer 200 / istanbul yields a creation code identical to the embedded blob except for the 32-byte bzzr1 metadata hash (9,183 of 9,215 bytes byte-identical); the deployed pair runtime equals our compiled runtime with metadata stripped (CI `proof.compiled_equals_deployed_metadata_stripped`).

⇒ All 129 pairs execute the canonical UniswapV2Pair logic: 0.3% swap fee, standard `mint`/`burn`/`swap`/`skim`/`sync`, uint112 overflow guard, `_mintFee` protocol-fee mint to `feeTo`. There is no custom pair math to exploit.

**No farm found live.** The repo's `MasterChef`/`MasterChefV2` mint PNDA/BAMBOO, but PNDA's owner (the intended MasterChef, `0x9942cb4c…`) has **no code** and nonce 1; PNDA totalSupply is static (74,952,744,075.778591907702862261 across the campaign). No contract holds meaningful LP of the top pairs except the codeless address below. ⇒ no emissions to farm.

---

## 3. Live state (explicit block)

Enumeration at **block 127,518,422** (local) re-verified at 127,53x,xxx; CI re-run at a fresh block (`ci-out/enumeration.json`, `ci-out/summary.json`).

| Metric | Value |
|---|---|
| Pairs | **129** (all enumerated, not sampled) |
| Priced reserve value | **$83,531.70** (56 of 96 tokens priced by DefiLlama; unpriced = scam tokens and PNDA-V2 LP-token pairs) |
| DefiLlama protocol TVL | $108,471 (prices more tokens, incl. PNDA) |
| Top pairs | ATOM/WBNB $14.4k · Cake/WBNB $9.8k · MATTER/WBNB $8.8k · DOGE/WBNB $8.1k · XTZ/WBNB $4.8k · BAO/WBNB $4.7k · POLS/WBNB $3.3k · BSCX/WBNB $3.3k · SPARTA $2.6k · LINK $2.3k · PNDA/WBNB $2.2k |
| `balance − reserve` excess | **0 pairs** with real excess (single-call re-read of all 129 + CI); fork `skim()` on the 8 largest pairs transfers 0 |
| PNDA | totalSupply 74.952744B; cap 100B; owner `0x9942cb4c6180820e6211183ab29831641f58577a` (no code, nonce 1, balance 0); `manualMinted` 250M > `manualMintLimit` 100k (bricked); `authorized[0x3bC3…6951] = 1` |
| BambooBar | PNDA balance 1,553,814,826.76; xBAMBOO totalSupply 804,704,779.51 → **1.931 PNDA per xBAMBOO**; has a WBNB pair (`0xa300526d…`, $1.66k) |
| BambooMaker | accumulated protocol-fee LP across ~30 pairs ≈ **$23** (priced); 300 PNDA; no WBNB/ETH |
| LP concentration | `0x9942cb4c…` (codeless) holds **44,752.5 of ~63,159 PNDA/WBNB LP (71%)** and 157.177 of 157.178 ATOM/WBNB LP (99.999%) — largest holder of the two biggest pools (~$17.6k of LP) |

### Where the value sits (classification)
- **H-O ($83.5k)**: pair reserves are redeemable by LP holders via `burn()`; xBAMBOO holders via `leave()`; locked-PNDA holders via `unlock()` (linear vesting to block 773,253,277).
- **P**: PNDA `mint()` (owner), `capUpdate` (authorized deployer EOA), factory `setFeeTo`/`setFeeToSetter`, PNDA `lock()`.
- **S (likely)**: the LP attributed to the codeless `0x9942cb4c…` (~$3.2k of PNDA/WBNB LP share + ~$14.4k ATOM/WBNB share ≈ $17.6k) is unreachable unless that key exists; without archive state the address cannot be classified as EOA (H-O) vs self-destructed contract (S).

---

## 4. What an attacker can / cannot do (exact paths)

**CAN (all yield ≈ $0):**
1. **Swap** in any pair at the fair AMM price (0.3% fee) — fork-verified round trip loses the fee (0.5 WBNB in → 0.497428 WBNB back).
2. **`skim(to)`** any pair — transfers `balance − reserve`; measured 0 on all funded pairs (full-set CI check).
3. **Trigger `BambooMaker.convert(token0,token1)`** (EOA-only) — burns the maker's fee-LP and swaps to PNDA for the bar; value at stake ≈ $23 and the attacker must be an EOA (no flash loans).
4. **Trade xBAMBOO** (WBNB pair) at ~its PNDA backing (1.931 PNDA/share; pool-implied and intrinsic values agree within 0.1%).

**CANNOT:**
- Drain any pair: pairs are stock; `swap` without input reverts `UniswapV2: INSUFFICIENT_INPUT_AMOUNT` (fork test 04/08); the k-check holds.
- Skim real value: no real excess exists (single-call reads + CI).
- Arbitrage against the live market: fork PoC on the most mispriced-looking pair (POLS/WBNB, where a stale DefiLlama price suggested +$536) shows **all sizes lose money** (best −0.0363 WBNB ≈ −$27 at 0.2 WBNB input; −2.29 WBNB at 3 WBNB) because the PandaSwap pool is already aligned with PancakeSwap (both ≈ 2.377e-5 WBNB/POLS). The DefiLlama-model "arb" was an artifact of stale off-chain pricing, not an on-chain opportunity.
- Mint PNDA / raise the cap: `mint` reverts `Ownable: caller is not the owner`; `manualMint`/`capUpdate` revert (fork test 06).
- Withdraw others' LP, xBAMBOO, or locked PNDA; `unlock()` is `msg.sender`-scoped; `transferAll()` only moves the caller's own tokens.
- Change the factory `feeTo`/`feeToSetter` (owner-gated).
- Pull the vBTC/WBNB pair's WBNB side via the fake-token path: balances are normal (no excess), `skim` = 0, no-input swap reverts (fork test 08).

---

## 5. PoC / fork verification

Foundry project `poc/` (solc 0.8.24, cancun; forge-std vendored). All tests run against a throwaway BSC fork (`vm.createSelectFork(BSC_RPC_URL)`); nothing is broadcast. A second project `poc05/` compiles the verified 0.5.16 bundle for the bytecode comparison (run by `ci/run.sh`).

| Test | Purpose | Local result |
|---|---|---|
| `test_00_state_sanity` | fork block, 129 pairs, feeTo/feeToSetter, pairCodeHash, pair spot check | **PASS** (fork 127,537,896) |
| `test_01_create2_all_pairs` | CREATE2(factory, salt, pairCodeHash) == deployed pair for all 129 | PASS in CI (129/129; 111/111 locally, no mismatch) |
| `test_03_skim_no_real_excess` | attacker `skim()` on 8 funded pairs; gains must be 0 | **PASS** — 0/0 on every pair |
| `test_04_no_free_output_without_input` | `swap(0,out,…)` reverts `UniswapV2: INSUFFICIENT_INPUT_AMOUNT` | **PASS** |
| `test_05_roundtrip_loses_fees` | WBNB→PNDA→WBNB loses the 0.3% fee | **PASS** (0.5 → 0.497428 WBNB) |
| `test_06_pnda_mint_gates` | `mint`/`manualMint`/`capUpdate` revert for a fresh attacker | **PASS** (owner `0x9942cb4c…`, cap 100B, manualMinted 250M) |
| `test_07_stale_price_arb_pols` | net-P&L arb vs live PancakeSwap, 8 sizes | **PASS** (asserts no positive profit; best −0.0363 WBNB) |
| `test_08_fake_token_pairs_no_drain` | vBTC/WBNB pair: skim 0, no-input swap reverts | **PASS** |
| CI `ci/run.sh` proofs | init-code extraction, keccak==pairCodeHash, CREATE2 129/129, compiled-vs-deployed runtime, excess scan, DefiLlama pricing, live-market arb scan | see CI run links below |

CI runs (public repo `artsbykriss/ca-zombie-ci`): see `ci-log.txt` / `ci-artifacts/` — run URL recorded in `summary.json`.

Key fork-measured numbers (block 127,538,669): POLS arb net P&L by size (WBNB in → WBNB net): 0.2 → −0.0363; 0.4 → −0.1218; 0.6 → −0.2372; 0.8 → −0.3721; 1.0 → −0.5205; 1.5 → −0.9287; 2.0 → −1.3681; 3.0 → −2.2932. Skim gains: 0 for all 16 token legs on the 8 funded pairs.

---

## 6. Verdict and residual/latent risk

**Extractable now (E-U): ≈ $0 — high confidence.** The DEX is a stock, verified UniswapV2 deployment whose pools are LP-owned (H-O) and already priced in line with the live PancakeSwap market; there is no excess to skim, no farm emitting, and every privileged path is keyed to EOAs without code or to the deployer.

**Latent / conditional paths (not counted in E-U):**
- **PNDA owner key** (`0x9942cb4c…`, codeless, nonce 1): if the key exists, it can mint up to 25B PNDA and `lock()` any holder. Realistic extraction is bounded by PNDA exit liquidity (PNDA/WBNB+USDC+BUSD+ETH pools ≈ $4.5k of hard side) — a rug of a few $k, not the $76k "notional" PNDA value.
- **`feeToSetter` EOA** (`0x3bC3…6951`): can redirect factory fees (`setFeeTo`) and raise PNDA's cap (`capUpdate`, authorized) — no unprivileged path.
- **BambooMaker sandwich**: `convert()` has no slippage bound; an EOA can sandwich the maker's own swaps, bounded by the maker's ~$23 of fee-LP.
- **LP at the codeless address**: ~71% of PNDA/WBNB LP and ~89% of ATOM/WBNB LP sits at `0x9942cb4c…`; if that key is lost, that share becomes S (nobody can move it), which actually *increases* the per-LP value of the remaining redeemable LP.

**Blockers/caveats:** 40 of 96 tokens are unpriced (scam tokens, LP-token pairs) — their reserve value is treated as $0; some DefiLlama prices are stale vs on-chain markets (POLS: $0.0609 off-chain vs $0.0177 on-chain Pancake) and were *not* used for the arb conclusion — the fork PoC used the actual Pancake pools.

---

## 7. Methodology, corrections & files

- **Blocks:** local enumeration 127,518,422; local fork tests 127,537,8xx–127,538,7xx; CI block in `ci-out/summary.json`.
- **Sources:** BscScan-verified sources for factory/pair bundle, PndaToken, BambooBar, BambooMaker (Etherscan V2 API, chainid 56); GitHub `Pandaswapdex/pandaswap-contracts`; DefiLlama `coins.llama.fi` for USD pricing; PancakeSwap factory `0xcA143Ce…` for live-market quotes; GoldRush for token holders.
- **Corrections found during the work (documented so they are not re-investigated):**
  1. Python `hashlib.sha3_256` is **not** Ethereum Keccak-256; all hash proofs here use a pure-Python Keccak-256 (`analysis/keccak.py`, self-tested). Earlier apparent mismatches were this bug.
  2. Batched public-RPC responses were occasionally **misaligned by the providers** (a 96-byte `getReserves()` result landed in a `balanceOf` slot), producing absurd "excess" values (1e167 etc.). All balance/excess conclusions here use **single-call** reads; the fork tests independently confirm 0 excess.
  3. DefiLlama token prices can be stale relative to the on-chain market; arbitrage conclusions must be computed against actual venue pools (done: `analysis/pancake_arb.py`, `poc/test/PandaSwap.t.sol::test_07`).
- **Files:** `analysis/` (pairs-list.json, all-pairs.json, priced.json, arb-live.json, maker.json, graph.json, farm.py, graph.py, enumerate*.py, price.py, pancake_arb.py, arb_live.py, balances_single.py, keccak.py, disasm.py, rpc.py); `poc/` (Foundry tests); `poc05/` (0.5.16 verification build); `ci/` (run.sh + enumerate_ci.py); `ci-out/` (CI artifacts); `ci-log.txt` / `ci-artifacts/` (CI logs).
- **Limitations:** no archive-node trace of historical PNDA mints (public RPCs only); the codeless `0x9942cb4c…` address's history (EOA vs self-destructed contract) could not be resolved without archive state; unpriced tokens assumed $0.
