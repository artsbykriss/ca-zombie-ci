# MonoSwap V3 (Blast) — L2 Phase-2 deep dive

**Date:** 2026-10-14 · **Chain:** Blast (81457) · **Target:** MonoSwap V3 factory `0x48d0F09710794313f33619c95147F34458BF7C3b` + its 61 CL pools
**Status:** read-only; PoC fork-verified only (GitHub Actions, local fork); **no mainnet transactions, no secrets**.

---

## 1. TL;DR

| Target | Live value (USD) | Category | Why |
|---|---|---|---|
| MonoSwap V3 CL pools (61) — LP principal + swap fees | **$112,003** | **H-O** | Positions are NFTs on the canonical Uniswap-V3-style NPM; owners can `decreaseLiquidity`/`collect` (fork-proven). No unprivileged path takes LP principal. |
| Accrued Blast WETH yield on pools | **$2,780** | **P** | `claimAllYield` (`onlyFactoryOwner`) claims the WETH yield; owner EOA `0x90a3…7f310` is live (collects protocol fees). Fork-proven. |
| Accrued Blast USDB yield on pools | **$19,284** | **S** | `claimAllYield` claims WETH **first**, then re-reads the (now zero) WETH claimable and passes it to `usdb.claim` ⇒ **USDB is never claimable by anyone**; fork-proven (owner gains 0 USDB while 13,327 USDB stays stranded in the main pool alone). |
| Protocol fees accrued in pools | **$1,077** | **P** | `collectProtocol` is `onlyFactoryOwner`; owner actively collects (recent txs). |
| Zero-liquidity pools with residual balances | **$10.22** | **S** | `liquidity()==0` ⇒ no swap/mint path can move them out. |
| Blast gas rebates on pools | ~$31 (0.0124 ETH) | **P/S** | Gas governor = deploy-time factory owner (EOA); no public claim path. |
| **E-U (unprivileged)** | **$0.00** | **E-U** | Max measurable extraction across all paths: **$0.00005** (micro-arb in one USDB/MUSD pool, below gas). |

### Total live extractable now: **$0.00 (E-U)** — confidence **high**

All $113,090 of pool balances + $22,064 of accrued yield is either owner-scoped (P), position-owner-scoped (H-O), or stuck (S). No fresh-attacker path exists.

---

## 2. What the protocol is / incident history

- **MonoSwap** was a Blast-native DEX (launched Feb 2024). **Hacked 2024-07-24**: a developer installed infostealer malware disguised as VC call software; the attacker stole private keys and drained ~$1.3M of staked liquidity, laundered via Tornado Cash (Halborn / PeckShield / protos.com). The team told users to withdraw and deployed replacement contracts.
- The **V3 AMM contracts audited here are live custody today**: the factory `0x48d0…7C3b` (deployed 2024-02-28, block 172,327) holds 61 CL pools with **$113,090** of balances (DefiLlama TVL for `monoswap-v3` matches).
- **Blast wind-down (announced 2026-10-02)**: withdrawals through the Blast interface until **2026-10-26**, then direct interaction with the L1 bridge contracts; assets remain withdrawable after that date. WETH/USDB therefore retain real exit value — the extraction question is genuine, not nominal.

---

## 3. Live-state assessment (all reads at Blast blocks 41,560,000–41,562,159; 2026-10-14)

| Item | Value | Evidence |
|---|---|---|
| Factory | `0x48d0F09710794313f33619c95147F34458BF7C3b`, code 24,515 B, verified source `MonoswapV3Factory` | `eth_getCode`, Etherscan V2 81457 |
| Factory owner | `0x90a30F6a76D05Cbe5Dad714838E0b38d53d7f310` — **EOA (code size 0)**, live: `collectProtocol` calls at blocks 40,088,549 … 41,479,196 | `owner()`, `txlist` |
| Owner history | deployer `0x13060d08…` → `0x90a3…` at block 13,814,337 (event `OwnerChanged`) | factory logs |
| Pools | 61 (61 `PoolCreated` events, last at block 27,019,302; none newer) | `eth_getLogs` |
| Fee tiers | 500→10, 3000→60, 10000→200 | `feeAmountTickSpacing` |
| Pool balances | **$113,089.82** total; $111,446.65 in USDB/WETH | balances × DefiLlama prices (USDB $0.99527, WETH $2,507.69) |
| Main pool | `0x0d44…89cd9` USDB/WETH 0.3%: 36,680.8 USDB + 27.03 WETH ≈ **$104,182**; **actively traded** (1,204 Swap/Mint/Burn/Collect events in last 49k blocks; last swap block 41,562,016) | `balanceOf`, `eth_getLogs` |
| Pool `feeProtocol` | 68 (=¼,¼) on 39 pools, 85 on 2, 0 on 1 | `slot0` |
| Protocol fees | **$1,076.54** across pools (top: 0x7b6b $479, 0x79fb $250, 0x6a96 $76) | `protocolFees` |
| Accrued Blast yield | **19,375.77 USDB + 1.1085 WETH ≈ $22,064** (CLAIMABLE mode set in each pool constructor) | `getClaimableAmount(pool)` on USDB/WETH |
| Native gas | 0.0124 ETH total (`readGasParams`) | Blast predeploy |
| NPM | `0x0F0C3dE3cd5185454eDe5EF184bC9C7F4133fb90` "Monoswap V3 Positions NFT-V1", 11,406 NFTs, **token balance 0** | `totalSupply`, `balanceOf` |
| Routers / factories | `0x334641E7…` (SwapRouter), `0x1Fdf0dBA…`, V2 factory `0xE27cb06A…` (62 pairs, real-asset side ≈ $1,085), V2 router `0x9FF95287…` — **all token/ETH balances ≈ 0** | balance sweep of 6 contracts × 46 tokens |
| MUSD | `0x837fE561…` — public `deposit`/`withdraw`; reserves 3.7237 USDB / 259.16B MUSD; **`withdraw` bricked** (`path` empty, `mono`=0) | source + `getReserves`, fork test |

---

## 4. The code — what an attacker actually faces

**Factory** (`MonoswapV3Factory.sol`, 83 lines): canonical Uniswap V3 factory minus `feeTo`; `owner`-gated `setOwner`/`enableFeeAmount`; permissionless `createPool`. No value.

**Pool** (`MonoswapV3Pool.sol`): canonical Uniswap V3 pool **plus**:
1. `initialize()` hard-codes `feeProtocol = 68` (¼ of swap fees to protocol, owner-withdrawable);
2. `claimAllYield(address recipient) external onlyFactoryOwner` — Blast yield claim, with a bug:
   ```solidity
   weth.claim(recipient, weth.getClaimableAmount(address(this)));  // claims the WETH yield...
   usdb.claim(recipient, weth.getClaimableAmount(address(this)));  // ...then re-reads it: now 0
   ```
   The first statement zeroes the pool's WETH claimable, so the second statement's argument
   is always 0 ⇒ **USDB yield can never be claimed by anyone** (fork-proven: main pool owner
   gains 0.774 WETH and 0 USDB while 13,327 USDB stays stranded). **19,375.77 USDB ($19,284) is stuck (S).**
3. Blast constructor config (`CLAIMABLE` yield/gas, governor = factory owner at deploy).

**Libraries**: `FullMath`, `Tick`, `TickMath`, `Oracle`, `Position`, `SwapMath`, `SqrtPriceMath`, `TickBitmap`, `LiquidityMath`, `SafeCast`, `LowGasSafeMath`, `UnsafeMath`, `TransferHelper`, `BitMath`, `FixedPoint*` — **byte-identical to canonical Uniswap V3** (whitespace/pragma-normalised diff). No math bug.

**NPM** (`NonfungiblePositionManager.sol`): canonical Uniswap V3 NPM + `BlastConfigure` mixin; `sweepToken`/`unwrapWETH9`/`refundETH` public but **nothing to sweep** (balances 0). Position ops are `_isApprovedOrOwner`-gated.

**Blast rebasing tokens**: USDB/WETH `claim()` credits `msg.sender`'s own account only (`address account = msg.sender` in the implementation) ⇒ third parties cannot redirect a pool's yield — fork-proven.

---

## 5. What an attacker can / cannot do (exact paths)

| Path | Verdict | Evidence |
|---|---|---|
| Take LP principal | **No** — positions are NFT-owner-scoped; canonical NPM/pool | code diff + fork test `test_16` (non-owner revert, owner withdraws) |
| Claim pool USDB/WETH yield | **No** — USDB: only the pool can call `claim()`, and `claimAllYield` always passes 0 (S); WETH: owner-only | fork tests `test_05`, `test_08`, `test_14`, `test_15`, `test_17` |
| `collectProtocol` / `setFeeProtocol` | **No** — `onlyFactoryOwner` | fork test `test_07` |
| Sweep NPM/routers | **No** — zero balances; sweep returns 0 | fork test `test_09` |
| Stale-price arb (main USDB/WETH pool) | **No** — pool price within 0.09% of market, fee 0.3%; both swap directions fork-tested at a loss | fork tests `test_10`, `test_13` |
| Arb in secondary pools | **No material** — ezETH/WETH effective price 3× worse than market; USDB/WETH `0x56ce…` pays ~0 for a 0.005 WETH swap; other pools' tokens have no external market | fork tests `test_11`, `test_12` |
| Mint-and-dump (MUSD) | **Dust** — public `deposit()` mints at 6.96e10 MUSD/USDB; dumping into USDB/MUSD pools returns ≤ +5.4e13 wei USDB (≈ **$0.00005** at optimum; losses beyond that) | fork tests `test_01`–`test_04` (snapshot scan) |
| Mint-and-dump (KID) | **No** — `mint(uint256)` costs 0.04 ETH/unit vs pool price $0.0049 (≈20,000× loss) | selector probe + facet 0xd005f96d |
| Mint-and-dump (BAJA/YIELD/OLE/bETH…) | **No** — signature/controller/bridge-gated mints; paired real-asset pools ≤ $254 | source review |
| MUSD public `withdraw` redemption | **Bricked** — `path` empty, `mono`=0 ⇒ `_swap`/`burn` revert | source + `path(0)` reverts |
| Flash-loan + reentrancy | **No** — canonical `lock`; flash loans repay input+fee | code diff |

---

## 6. PoC / fork verification

Foundry fork of Blast mainnet (public keyless RPC), **18 tests, all passing** (local run + CI). Files:

- `poc/test/MonoSwapV3.t.sol` — 18 tests:
  - `test_00` live snapshot (block, MUSD rate, pool balances, claimable yield)
  - `test_01` MUSD deposit open; `test_02/03/04` MUSD dump scans (USDB pool A/B, WETH pool) — **all sizes net-loss except a $0.00005 dust optimum**
  - `test_05/06/07` privileged paths revert for fresh address / work for owner
  - `test_08` third party cannot claim pool yield (`NotClaimableAccount`)
  - `test_09` NPM sweep returns 0
  - `test_10/13` main pool priced at market (both directions)
  - `test_11/12` secondary pool arb checks
  - `test_14` owner claims main-pool yield (P = 0.774 WETH, 0 USDB)
  - `test_15` USDB yield never claimable (WETH claimed, USDB = 0) — S proof
  - `test_16` position owner can withdraw; non-owner reverts (H-O proof)
  - `test_17` main-pool USDB yield stuck (13,327 USDB stranded) — S proof
- `ci/run.sh` — probes a working public Blast RPC, exports `BLAST_RPC_URL`, dumps live state to `ci-out/`.

**CI runs:** https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38485155201 (**18/18 PASS**, final) — first attempt https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38484428140 (14/18, three live-state-sensitive tests fixed) — see `ci-log.txt`, `ci-artifacts/`.

Key fork numbers (blocks 41,561,815 local / 41,562,147 CI):

| Scan | Deposit | USDB out | Net |
|---|---|---|---|
| MUSD pool A | 0.001 USDB | 0.0010535 | **+0.0000535 USDB ($0.00005)** |
| MUSD pool A | 0.01 USDB | 0.006011 | −0.00399 |
| MUSD pool A | 1 USDB | 0.01246 | −0.9875 |
| MUSD pool B / WETH pool | all sizes | — | loss |
| Main pool | 1 WETH in | 2,512 USDB | loss vs market 2,519.6 |
| Main pool | 1,000 USDB in | 0.39230 WETH | loss vs market 0.39688 |

---

## 7. Verdict, residual & latent risk

- **E-U = $0.00 (high confidence).** The V3 contracts are canonical Uniswap V3 + Blast integrations; the only MonoSwap-specific additions are owner-gated. Every unprivileged path was either fork-tested to a loss or gated by code/state verified on-chain.
- **P = $2,780 (all WETH yield) + $1,077 (protocol fees) + ~$31 (gas)** — extractable by the live factory-owner EOA. If that key is lost, this becomes S.
- **H-O = $112,003** — LP NFT owners can withdraw; no bank-run risk (balances exceed claims; swap fees accrue).
- **S = $19,284 (USDB yield stranded by the `claimAllYield` bug) + $10.22 (zero-liquidity dust) + MUSD backing 3.72 USDB** (redemption bricked).
- **Latent risk:** the USDB yield grows (~5%/yr on ~37k USDB ≈ +$900/yr) and is permanently unclaimable without a new pool/factory function. If the factory owner EOA is compromised, the attacker gets P (~$3,888), never LP principal.

**Blockers/caveats:**
- Blast wind-down: after 2026-10-26 withdrawals require direct L1 bridge interaction (assets remain recoverable).
- Two KID facets / a handful of token contracts are unverified; their mint gating was probed behaviourally (`mint(uint256)` exists, priced 0.04 ETH/unit ≫ market).
- Fork tests used keyless public RPCs; all claims are reproducible at the recorded block.

---

## 8. Methodology & sources

1. Re-enumerated the factory's 61 `PoolCreated` events; read `slot0`/`liquidity`/`protocolFees`/`fee`/`tickSpacing`/`factory` + token balances for every pool at a pinned block (3 independent public RPCs, retried per call).
2. Fetched verified sources (Etherscan V2, chainid 81457) and diffed pool/libraries/NPM against canonical Uniswap V3 mainnet deployments (whitespace/pragma-normalised).
3. Priced all tokens via DefiLlama `coins.llama.fi` (USDB $0.99527, WETH $2,507.69, ezETH $2,721.11, USDe $0.99959).
4. Fork-simulated every candidate extraction path on Blast mainnet state (Foundry, snapshots for scans).
5. Cross-checked incident history (Halborn, PeckShield, protos.com, cryptobriefing) and the Blast wind-down (The Block, Bankless, 2026-10-02).

**Files:** `analysis/live_state2.json` (all 61 pools), `analysis/tokens.json`, `analysis/v2_pairs.json`, `analysis/musd_state.json`, `analysis/periphery*.json`, `analysis/src/` (verified pool source), `analysis/npm_src/`, `poc/`, `ci-out/`.
