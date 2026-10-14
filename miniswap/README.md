# MiniSwap (Ethereum) — L2 Phase-2 deep dive

**Date:** 2026-10-14 · **Chain:** Ethereum (1) · **Status:** read-only; PoC fork-verified only; no mainnet transactions
**Triage source:** `l2-triage-a/summary.json` row `miniswap` — $61,425 live (high confidence), "Ethereum factories `0x1e2c2102…`, `0xbbe02650…`" (the second address is **not deployed**).

---

## 1. TL;DR

| Target | Live value (on-chain, 2026-10-14) | Extractable by external unprivileged attacker | Why closed / open | Latent risk |
|---|---|---|---|---|
| **Factory 1** `0x1e2c2102cf8efcaaaf20ffe926469ec7cd0d0f6e` — 49 plain Uniswap-V2 pairs | **$61,320.04** priced (block 26,188,992) | **$0** | LP-owned reserves; no excess; no free mint; prices track the market | LP keys lost → S |
| **Factory 2** `0x2294577031f113df4782b881cf0b140e94209a6f` — 19 *mining* pairs (**missed by triage**) | **$33,058.59** priced | **$0** | LP-owned reserves; mining hook pays a **fee rebate**, not a profit | Mining emission dilutes MINI holders (~$40/day) |
| Mining mechanism (`MiniswapMiner` `0xcdd8dec1…`, 18/19 factory-2 pairs whitelisted) | MINI issuance live (block 26,188,094+) | **$0 net** — fork-proven: reward = the 0.3% fee paid, refunded as newly minted MINI (50 USDT swap → 67.58 MINI ≈ $0.149) | Swapper's net ≈ −slippage; no loop profit | 18,000 MINI/day cap ≈ **$39.7/day** of dilution |
| `feeTemp` MINI pools (pair-owned fee contracts) | **1,841,167.47 MINI ≈ $4,062** (18 pairs) | $0 | `sendTokenTo` is pair-only (stranger reverts); `getMineFeeAmount` pays out only inside LP `burn()` → **H-O** | — |
| LP fee claims in MINI | included above | $0 | Fork-proven: LP mint → swap → burn pays the pro-rata fee share (32.71 MINI in test_11) | LP keys lost → S |
| `feeTo` LP tokens (factory 1, EOA `0xe7847cc9…`) | **≈ $3,842** (26% of MINI/WETH LP etc.) | $0 | Protocol-owned (P if key alive, S if lost) | Key liveness unknown |
| YMI MasterChef `0x732b7baf…` | **66,391.18 USDT** staked + 1,223.84 YMI | $0 | Emissions ended (`getMultiplier(now,now+1)=0`); staked principal withdrawable by stakers → **H-O** | Staker keys lost → S |
| MG MasterChef `0x342a8a45…` | 90,602,736 MG + 1,610,915.97 MINI (staked/accrued) | $0 | Emissions ended; principal/rewards are staker-owned → **H-O** | — |
| MINI bonding curve (inside the token) | 0 ETH | $0 | Closed: `k=31 > maxK=30` (`require(k <= maxK)` fails); owner withdrew all ETH | — |
| Stale-price arbitrage (all 68 pairs) | — | **$0 material** | Implied vs external price within ±0.5% for real/real pairs; pool slippage > gap (test_07: every round trip loses ≥0.3%) | — |

**Total live extractable by an external unprivileged attacker now: ≈ $0 (high confidence).**
Live LP/staker-owned value (H-O) across both factories: **$94,378.63** priced on-chain + $4,062 LP fee claims + $66,391 staked USDT. The triage's $61,425 covered only factory 1 and missed factory 2 entirely (another $33,059); nothing in either factory is attacker-extractable.

---

## 2. Architecture (deployed reality)

MiniSwap is a 2020 Uniswap-V2 fork (deployer `0x36df7e6b…`) with **two factories** and a **MINI token mining mechanism**:

| Contract | Address | Role |
|---|---|---|
| Factory 1 (plain V2) | `0x1e2c2102cf8efcaaaf20ffe926469ec7cd0d0f6e` | 49 pairs, `feeTo=0xe7847cc9…`, `feeToSetter=0xe7847cc9…`, `migrator` absent |
| Factory 2 (**mining V1**) | `0x2294577031f113df4782b881cf0b140e94209a6f` | 19 pairs, `feeTo=0`, `feeToSetter=0x36df7e6b…`; pairs call the miner on swaps |
| `MiniswapMiner` (verified) | `0xcdd8dec17622468a1775d18bb4fcfe8be8ba8b68` | issues MINI to swappers + `feeTemp` on whitelisted pairs; `minFee=0`; `feeder=0xc9631c3a…` |
| `MiniswapMiner` #2 (unverified, same code) | `0x53c5009938aff6f48ca41cb50bdabb4c65a2daee` | second issuer (older deployment); no whitelisted pairs found |
| MINI token | `0x4d953cf077c0c95ba090226e59a18fcf97db44ec` | Tether-template ERC20 + `issueTo` (issueAuthAddr-gated) + closed bonding curve + pause/blacklist |
| V1 pair (impl, e.g. WETH/USDT) | `0xbbdf7d806a54fe1f5633a3de662543afce613d0a4` | V2 pair + permit + `swap(amount0Out, amount1Out, to, **originSender**, data)` + `miner()`/`feeTemp()`/`totalFeeAmount()`/`userInFeeAmount()`/`getMineFeeAmount()` |
| feeTemp contracts (440-byte) | e.g. `0xd3570199…` (WETH/USDT), `0xeef373c6…` (MINI/WETH) | per-pair fee collectors, `owner()` = the pair, `sendTokenTo(address,address,uint256)` pair-only |
| MG MasterChef | `0x342a8a451c900158ba4f1367c55955b5fbcb7cce` | MG farm (owner `0xe7847cc9…`); emissions ended (block 19,953,633) |
| YMI MasterChef | `0x732b7bafede7eeb83714ca9cc4c486f79ac8668b` | YMI farm (owner `0xe7847cc9…`); emissions ended (block 11,338,300) |

Sources: `MiniswapMiner` verified on Etherscan; the V1 pair interface + miner source from `github.com/MiniswapOrg/Miniswap-contract` (`contracts/interfaces/V1/IMiniswapV1Pair.sol`); deployed pair/factory bytecode verified against that interface (all getters match; the pair carries `miniswapV2Call`/`mining` integration and DS-Math fee accounting).

### The mining mechanism (exact)
On every swap of a whitelisted pair, the pair calls `miner.mining(factory, feeTemp, originSender, token, fee)` where **`fee` = the 0.3% swap fee** (fork-verified against the on-chain bot tx `0x9801bbc1…`: 18.219533 USDT swap → fee 0.054658 USDT → 24.6998 MINI issued to the swapper **and** 24.6998 MINI to the pair's feeTemp). The miner swaps the fee for MINI on the MINI/USDT pair, burns ½, sends ½ to the feeder, and mints `issueAmount` MINI to `originSender` (caller-chosen in `swap()`) **and** `issueAmount` to `feeTemp`, capped by `mineInfo[day] ≤ 18,000 MINI/day`.

**Net effect for a swapper: the fee is refunded in MINI → effective swap fee ≈ 0, but no profit** (they paid the fee to receive it back). The `feeTemp` half accrues to LPs, paid out pro-rata on `burn()`.

### What is *not* a path (verified)
- **Factory 2 pairs were missed by triage**: `0xbbe02650…` from the triage row has **no code**; the real second factory is `0x22945770…`.
- **Free mint**: MINI `issueTo` requires `issueAuthAddr[msg.sender]` (only the two miners were ever authorized, blocks 10,797,377 / 10,800,462; no `rmIssueAuthAddr` calls found). YMI/MG `mint` = `onlyOwner` (their MasterChefs). HDOT/HBCH = admin multi-sig (`getAdminAddresses`). TPT = minter role. LEV = owner renounced (`0x0`) with `MINTER_ROLE`/`finishMinting`.
- **Excess/skim**: 0 on all 68 pairs (AMPL pairs have *negative* excess from rebases).
- **Stale prices**: real/real pairs within ±0.5% of DefiLlama/Uniswap (e.g. WETH/USDT 2510.6 vs 2516.8 market); the 0.3% MiniSwap fee + pool slippage make every arb negative (test_07).
- **Admin/upgrade**: no proxies (EIP-1967 slots empty on factory/pairs/token); `setFeeTo`/`setFeeToSetter` are feeToSetter-only; MINI pause/blacklist is owner-only.

---

## 3. Live state (explicit blocks)

CI enumeration at **block 26,188,992** (`ci-out/summary.json`, run `38531811021`); local enumeration at **block 26,188,321**; PoC fork tests at blocks **26,189,0xx**.

| Metric | Value |
|---|---|
| Factory 1 pairs / priced USD | 49 / **$61,320.04** |
| Factory 2 pairs / priced USD | 19 / **$33,058.59** |
| **Total priced** | **$94,378.63** |
| Pairs with `balance − reserve` > 0 | **0** (excess $0) |
| Whitelisted (mining) pairs | 18 of 19 (all but the dust MINI/YAMv2 pair) |
| `mineInfo[day]` (recent days 2561–2564) | 86.6 / 479.2 / 1,141.6 / 118.4 MINI (cap 18,000/day) |
| `feeTemp` MINI total | **1,841,167.47 MINI ≈ $4,062** |
| MINI price (MINI/WETH pair) | 8.736e-7 WETH ≈ **$0.002208** |
| ETH price (WETH/USDT pair) | 2,510.6 USDT |
| MINI total supply | 151,094,890.95 (max 1B, not paused) |
| Top pairs (priced) | WETH/USDT(f2) $19,147 · MINI/WETH(f1) $11,873 · HDOT/USDT(f1) $10,666 · YMI/WETH(f1) $8,662 · WETH/USDT(f1) $6,914 · YFI/WETH(f1) $6,828 · SUSHI/WETH(f2) $6,266 · HBCH/USDT(f1) $5,254 · MINI/WETH(f2) $4,859 |

---

## 4. What an attacker can / cannot do (exact paths)

**CAN (fork-proven, but $0 net):**
1. **Capture the mining fee rebate** (`test_01`): call `swap()` directly on any whitelisted pair with `originSender = self`; receive newly minted MINI = the MINI value of the 0.3% fee. Measured: 50 USDT in → 0.0197528 WETH + **67.577 MINI**; total value ≈ 49.75 USDT → net **−0.25 USDT** (price impact). No profitable loop exists (the refund equals the fee).
2. **Become an LP and collect the fee share** (`test_11`, `test_12`): mint LP, let fees accrue, burn → receive principal + pro-rata MINI from the feeTemp (32.71 MINI measured for a 500 USDT position after one 500 USDT swap). This is **H-O**, not extraction.
3. **Zero-fee flash swaps** (implicit): the 0.3% flash-swap fee is also refunded as MINI → effectively fee-free flash liquidity. No standalone profit.

**CANNOT:**
- Drain any pair: reserves are LP-owned; k-check, lock, and (V1) DS-Math accounting are intact; no excess to `skim()`.
- Mint any valuable token freely (all issue/mint paths gated; fork-verified for the whitelisted token set).
- Move `feeTemp` MINI: `sendTokenTo` reverts for strangers (`test_04`); `getMineFeeAmount` returns the LP's pro-rata share but transfers nothing outside `burn()` (`test_08`); LP received via transfer carries no claim (`test_13`).
- Exploit the MINI bonding curve: `k=31 > maxK=30` → every ETH deposit reverts; contract ETH balance = 0.
- Use admin paths: `setFeeTo`/`setFeeToSetter`, MINI `pause`/`addBlackList`/`destroyBlackFunds`/`setIssueAuthAddr`, MC `set`/`add`/`setMigrator` — all owner-gated.
- Farm MG/YMI: emissions ended (`getMultiplier(now, now+1) = 0`); pending rewards belong to historical stakers.

---

## 5. PoC / fork verification

Foundry project `poc/` (solc 0.8.24, via_ir, forge-std vendored). All tests fork Ethereum mainnet; nothing is broadcast. USDT is non-standard (no return value) — the PoC uses low-level safe transfers (this was the only initial test-harness failure, documented here to save future time).

| Test | Purpose | Result |
|---|---|---|
| `test_00_state_sanity` | block, MINI supply/pause, pair reserves, prices, whitelist, miner wiring | PASS |
| `test_01_mining_reward_fresh_attacker` | fresh contract swapper receives MINI = fee (50 USDT → 67.577 MINI) | PASS |
| `test_02_mine_and_dump_realized` | mine then dump MINI into MINI/WETH; net value vs 50 USDT | PASS (net −0.25 USDT) |
| `test_03_daily_cap_accounting` | `mineInfo[day]` vs 18,000/day cap | PASS |
| `test_04_feetemp_claim_paths` | stranger `sendTokenTo` reverts; feeTemp balances | PASS |
| `test_05_lp_burn_receives_mini` | LP mint→burn, `amountMINI` and `userInFeeAmount` behaviour | PASS |
| `test_06_factory1_no_mining_no_excess` | factory-1 pair: no mining hook, excess 0, round trip loses fees | PASS |
| `test_07_stale_price_arb_marginal` | YFI/WETH round trips at 1–100% sizes all lose ≥0.3% | PASS |
| `test_08_getMineFeeAmount_probe` | `getMineFeeAmount` returns 0 for non-LP; no token movement | PASS |
| `test_09_feetemp_claim_via_mint` | tiny mint sets `userInFeeAmount = totalFeeAmount` (snapshot), claim 0 | PASS |
| `test_10_fee_claim_after_swap` | mint → swap → claim path returns the pro-rata share | PASS (documented revert was a test balance bug) |
| `test_11_lp_transfer_after_fees` | LP transfer + burn after fees accrued: **fee share 32.71 MINI paid** | PASS |
| `test_12_two_lp_fee_accounting` | A burns first; B still exits fine (no cross-LP breakage) | PASS |
| `test_13_fee_snapshot_on_transfer` | fee claim does not travel with transferred LP (no double-claim) | PASS |

CI runs (public repo `artsbykriss/ca-zombie-ci`, branch `miniswap`):
- `38523307878` — enumeration OK (both factories, $94,378.63); tests 5/8 (harness USDT-return bug, fixed).
- `38531811021` — final suite (14 tests) + enumeration; see `ci-log.txt`.

Gas (mainnet): swap ≈ 300–600k gas (incl. mining hook); LP mint+burn ≈ 0.7–1.3M gas. At ≤5 gwei these are $2–$10 — far above any theoretical edge.

---

## 6. Verdict & residual risk

- **E-U ≈ $0.** The triage's $61,425 (and the additional $33,059 in factory 2) is **LP-owned value (H-O)**, not attacker-extractable. The only permissionless value faucet — the MINI mining hook — refunds exactly the fee paid, and every other path (skim, free mint, stale price, admin) is closed on-chain and fork-verified.
- **H-O:** $94,378.63 priced LP reserves (both factories) + $4,062 feeTemp MINI (LP fee claims via `burn`) + $66,391 staked USDT in the YMI MasterChef + staked MG/MINI in the MG MasterChef.
- **P:** `feeTo` LP ≈ $3,842 (factory 1, EOA `0xe7847cc9…`); MINI owner (pause/blacklist/issue-auth); MasterChef owners; factory `feeToSetter`.
- **S:** any LP/staker positions whose keys are lost; the MINI curve ETH (withdrawn by the owner); blacklisted addresses (none found).
- **Latent:** the mining emission (~18,000 MINI/day ≈ $39.7/day) continues to dilute MINI holders; the mechanism has no upper bound on duration. If the protocol's MINI price were manipulated low before a swap, the reward (priced off live reserves) would grow — but the reward is only ever the fee value, so no extraction emerges.
- **Blockers/frictions:** none needed — all candidate paths revert or net ≤ 0; nothing is paused.

## 7. Methodology, caveats, files

Method: on-chain reads at explicit blocks (nodereal/infura/drpc/publicnode; batched JSON-RPC); verified sources from Etherscan V2 and the MiniswapOrg GitHub repo; full 68-pair enumeration (reserves, balances, supplies, feeTemp balances, whitelist, mineInfo); DefiLlama pricing; fork PoCs on GitHub Actions. Read-only; no keys, no transactions, no secrets in the folder.

Caveats: (1) 19 of 36 factory-1 tokens are unpriced by DefiLlama → $94.4k is a lower bound (DefiLlama's protocol TVL $105k includes more tokens); (2) the V1 pair/factory bytecode is unverified — behavior was established by disassembly, the published V1 interface, and 14 fork tests; (3) "extractable $0" assumes the fee-rebate economics hold (fork-proven) and that no unknown MINI issuer exists beyond the two miners (checked: only two `setIssueAuthAddr` calls ever, no removals); (4) USD at DefiLlama prices on 2026-10-14 (ETH $2,510.6, MINI $0.002208).

Files: `analysis/pairs_raw.json`, `analysis/pairs_raw_f2.json`, `analysis/priced_pairs.json`, `analysis/priced_pairs_f2.json`, `analysis/mini_issue_issuers.json`, `analysis/mini_latest_issues.json`, `analysis/sources_*.sol` (miner, MINI token, V1 pair interface, ERC20, router) · `ci/enumerate.py`, `ci/rpc_ci.py`, `ci/run.sh` · `ci-out/{summary,pairs_f1,pairs_f2}.json` · `poc/` (Foundry, 14 tests) · `ci-artifacts/`.
