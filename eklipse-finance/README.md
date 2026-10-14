# Eklipse Finance (Kaia) — Phase-2 live-extractability deep-dive

**Date:** 2026-10-14 · **Chain:** Kaia (ex-Klaytn, chain id 8217) · **Batch:** L2 Phase-2 (Triage-B row 22)
**Status:** read-only; PoC **fork-verified only**; no mainnet transactions were sent.
**Headline: an unprivileged attacker can extract ~$10,406 of live value (net profit ≈ $9,494 after buying input tokens at market) from the Eklipse meta-pool, by minting the (depegged) base-pool LP cheaply and dumping it into the meta-pool for pUSD.**

---

## 1. TL;DR

| Target (Kaia) | Address | Live value | Unprivileged extractable | Why open / closed | Latent risk |
|---|---|---|---|---|---|
| Eklipse **meta pool** (baseLP/pUSD) | `0xe59234EeDC854b3b37D48EFd8a529069C3990F83` | **10,403.96 pUSD ($10,406.60)** + 9.13 baseLP | **$10,406.60 gross / ≈$9,494 net** (fork-verified drain) | Meta pool still prices base LP at its *nominal* virtual price (1.0413) while the LP's real market value is **$0.1036**; pool is extremely imbalanced (9.13 LP vs 10,404 pUSD) → pays **~$1.04–222 pUSD per $0.10 LP**. Permissionless `swap()`, unpaused, 0.06 % fee. | If nobody acts, the value sits indefinitely (reserves bit-identical for ≥7 days). Owner can `pause()` (EOA) |
| Eklipse base pool (KDAI/oUSDT/oUSDC) | `0x4F5d9F3b17988aA047e6F1Bc511fEc0BF25691f4` | $29,604.79 (KDAI 268,996.60 + oUSDT 30,401.01 + oUSDC 1,661.05) | $0 direct (swap rates at market) — but it is the **LP factory** for the attack above | Pool is arbitraged to market ratios; its LP is a claim on depegged tokens | H-O: baseLP holders can `removeLiquidity` |
| Eklipse swap pools p3–p5 (KDAI/oUSDT/oUSDC + KSD/KASH) | `0x323f…4D9A`, `0x5B4e…28c`, `0x29c6…C78e` | $1,833.27 priced (KDAI/oUSDT/oUSDC) | $0 (paired tokens KSD/KASH have **no market**) | Requires acquiring unpriced junk tokens to extract | Latent if KSD/KASH ever become tradable |
| Eklipse meta pools p6–p9 (baseLP + KSD/KASH/oBUSD/USDK) | `0x7f35…1abb`, `0xB1b7…c223`, `0xddA0…B7EC`, `0x75Dc…fD40` | $627.04 real (baseLP at $0.1036) | $0 | Same junk-token gate | Latent |
| Eklipse staking / pool2 (EKL) | `0xD067…6c58`, `0x625a…D3C2` | $0 (EKL has no market price; 16.5 M EKL staked) | $0 | EKL is unpriced/unmarketable | — |

**Total live extractable (E-U) now: ≈ $9,494 net / $10,406.60 gross — confidence: HIGH** (fork PoC + exact on-chain math).
Triage-B's $80,359.22 for this row is **overstated by ~$31.3k** — the DefiLlama adapter's `vaults` array lists pool `0x4F5d9F3b…` **twice**, and the triage summed owners without de-duplication (see §5.4).

---

## 2. Architecture (verified on-chain)

Eklipse Finance is a **Saddle-Finance-style StableSwap DEX** (Curve fork; DefiLlama `forkedFromIds: [3]`, tags `StableSwap`) deployed on Klaytn in April 2022, now dead (`deadUrl: true`). All pools share one implementation family (Solidity, `swapStorage` / `getTokens` / `getTokenBalances` / `getVirtualPrice` / `getA` / `addLiquidity(uint256[],uint256,uint256)` / `removeLiquidity…` / `swap(uint8,uint8,uint256,uint256,uint256)` / `calculateSwap` / `calculateTokenAmount`), with `owner`, `pause/unpause` and `feeDistributor` added.

DefiLlama's adapter (`projects/eklipse/index.js`, last revision before removal, commit `2346cd2b2759`) defines the exact target set used by the triage:

```js
const vaults = ['0x4F5d9F3b…','0xe59234Ee…','0xddA06aaB…','0x7f352a43…','0xB1b782f2…',
                '0x75Dc33f8…','0x4F5d9F3b…',   // <-- duplicate of the first entry
                '0x323fdda2…','0x5B4ed832…','0x29c6Eb80…'];
```

Pools and composition (tokens from `getTokens()`, balances from `getTokenBalances()`, block **229,754,867**):

| Pool | Tokens (index order) | Reserves | A | vp | paused |
|---|---|---|---|---|---|
| base `0x4F5d9F3b…91f4` | KDAI(18), oUSDT(6), oUSDC(6) | 268,996.599 / 30,401.011 / 1,661.047 | 2000 | 1.041312954 | false |
| **meta** `0xe59234Ee…0F83` | **baseLP(18), pUSD(18)** | **9.131925 / 10,403.963278** | 200 | 1.057825812 | false |
| p3 `0x323fdda2…4D9A` | oBUSD, KDAI, oUSDT, oUSDC | 0.232 / 264.029 / 130.547 / 8.101 | 2000 | 1.011670983 | false |
| p4 `0x5B4ed832…28c` | KSD, KDAI, oUSDT, oUSDC | 40,363.643 / 13,597.614 / 3,836.172 / 254.958 | 2000 | 1.010940678 | false |
| p5 `0x29c6Eb80…C78e` | KASH, KDAI, oUSDT, oUSDC | 7.744 / 12.450 / 5.860 / 3.678 | 50 | 1.006627205 | false |
| p6 `0x7f352a43…1abb` | baseLP, KSD | 318.033 / 1,446.837 | 50 | 1.034529430 | false |
| p7 `0xB1b782f2…c223` | baseLP, KASH | 1,239.980 / 676,714.065 | 50 | 1.021227198 | false |
| p8 `0xddA06aaB…B7EC` | baseLP, oBUSD | 4,484.398 / 11.937 | 2000 | 1.145949728 | false |
| p9 `0x75Dc33f8…fD40` | baseLP, USDK | 0.548 / 4.59e9 | 50 | 701,827.248 | false |

Tokens: **KDAI** `0x5c74070f…e32b` (18d), **oUSDT** `0xcee8faf6…d167` (6d), **oUSDC** `0x75428807…d103` (6d), **pUSD** `0x168439b5…7ae4` (18d), **baseLP/EKLP** `0xd83b9dFa…3E49` (18d), metaLP `0x63C7d729…b5f8` (18d), KSD `0x4fa62f1f…2e67`, KASH `0xce40569d…7823`, oBUSD `0x210bc03f…8b85`, USDK `0xd2137fdf…7753`, EKL `0x807C4E06…58cA`.

Roles: `owner()` = **`0x024dfd23bf033d3ae3e9a1e41244ffcb6f6671ea`** (EOA, no code) for base/meta/p6–p9; **`0xfd914b8463a2d22dd654da360c56913f31b3936e`** (EOA) for p3–p5. `feeDistributor` = `0x5a7b01f9…7836` (base/meta/p6–p9) or self (p3–p5). **No whitelist / blacklist / KYC functions exist in the ABI**; `paused()` is `false` everywhere.

### 2.1 Market prices (DefiLlama, 2026-10-14)

| Token | Price | 30-day range | Note |
|---|---|---|---|
| KDAI | $0.09635 | $0.0921–0.1061 | depegged bridge stable |
| oUSDT | $0.10509 | $0.1029–0.1103 | Orbit-bridge token |
| oUSDC | $0.29620 | — | Orbit-bridge token |
| **pUSD** | **$1.00025** | $0.99971–1.00035 | **real, liquid, pegged** |
| KSD / KASH / oBUSD / USDK / EKL | no price | — | unpriced / no market |

The **base LP's real value = $0.10361** (= base pool's $29,604.79 ÷ 285,741.485 LP). The meta pool values it at **1.0413** nominal — a ~10× over-valuation.

---

## 3. The bug / mechanism in exact terms

The meta pool `0xe59234…0F83` holds a base-pool LP token as one of its two coins. Its precision multiplier for the LP index is **dynamic**: `getTokenPrecisionMultipliers()[0] = base_pool.getVirtualPrice()` (= 1.041312951e18), so the LP is priced at *par* (1.0413 "dollars") by the stable-swap invariant, even though the LP's real market value is **$0.10361** (its underlying KDAI/oUSDT/oUSDC are depegged ~90 %).

Because the pool is also **extremely imbalanced** (xp = [9.51 LP-scaled, 10,404 pUSD]; D = 7,628.28), the marginal payout for LP is far above par:

* `calculateSwap(0,1,dx)` (LP → pUSD), measured on-chain: **222.43 pUSD for 1 LP**, 1,286.41 for 10 LP, 2,594.17 for 100 LP.
* Fair value of 1 LP = **$0.1036**. The pool therefore pays a 2,100× premium at the margin and still ≥ $1.04 pUSD/LP even after 5,000 LP are dumped.
* The exact Saddle invariant model reproduces the on-chain quotes to 9 decimals with **swap fee = 0.06 %** (`implied_fee = 0.0006000` constant across sizes) and `A = 200`, `D = meta_vp × metaLP_supply`.

So any attacker who can obtain base LP for ~$0.10 can sell it to the meta pool for ≥ ~$1.04 of **real pUSD**. The cheapest LP source is the base pool itself: `addLiquidity` with a single cheap token (KDAI at $0.09635 → 0.93 LP per KDAI at the margin; oUSDC even better per dollar: 2.76 LP per oUSDC, limited to 1,700 tokens).

Why this state exists: the meta pool's LP reserve has been drained to 9.13 LP while 10,404 pUSD remains — most plausibly via `removeLiquidityOneToken`/imbalanced withdrawals by metaLP holders during the 2022–2023 depeg. Whatever the cause, the state is **live, stable and untouched**: the pUSD and baseLP reserves are bit-identical (10,403.963278 / 9.131925) at every sampled block from **7 days ago through now** (blocks 229,151,231 → 229,756,031), i.e. the free lunch has been sitting there for at least a week and nobody has taken it.

**Extraction cap = the meta pool's pUSD balance: 10,403.963278 pUSD ($10,406.60).**

---

## 4. What an attacker can do (exact call path)

Preconditions: a Kaia account with gas (KAIA) and ~$770–$970 of KDAI (buyable on Kaia DEXes at the DefiLlama price; no whitelist, no roles, no flash loan needed — a flash loan would only remove the small upfront capital).

```
1. buy KDAI on the open market (~$0.09635 ea.)                    [external]
2. KDAI.approve(basePool, amount)
3. basePool.addLiquidity([kdai,0,0], 0, deadline)   -> base LP    (permissionless)
4. baseLP.approve(metaPool, lp)
5. metaPool.swap(0, 1, lp, 0, deadline)             -> pUSD        (permissionless, 0.06% fee)
6. sell pUSD at ~$1.00                                            [external]
```

Fork-verified results (block 229,753,258):

| Attack | Spend | Cost @ market | LP minted | pUSD received | Gross USD | **Net USD** |
|---|---|---|---|---|---|---|
| 8,000 KDAI | 8,000 KDAI | $770.80 | 7,428.38 | 10,264.54 | $10,264.54 | **$9,493.74** |
| 10,000 KDAI (near-full drain) | 10,000 KDAI | $963.50 | ~9,289 | **10,383.95** | $10,383.95 | **$9,420.45** |
| 1,700 oUSDC (alt input) | 1,700 oUSDC | $503.54 | 3,263.41 | 6,179.49 | $6,179.49 | **$5,675.95** |

After the 10,000-KDAI drain only **20.01 pUSD** is left in the meta pool (99.8 % drained). Gas is ~0.8 M per attack (≈ $0.01 on Kaia) — negligible.

**Cannot** (verified negative results):
* Direct swaps inside the base pool are at market ratios → no profit (1,000 KDAI → 908.94 oUSDT; in-USD $96.35 vs out-USD $95.52).
* Base-pool LP round trips are a loss: deposit 1,000 KDAI ($96.35) → 928.58 LP → `removeLiquidityOneToken` yields 999.74 KDAI ($96.33), 904.30 oUSDT ($95.03) or 284.67 oUSDC ($84.32) — the pool charges the scarcity premium on oUSDT/oUSDC and fees kill the KDAI leg.
* No admin/owner/upgrade path exists for an outsider: `owner` is an EOA, no `migrateTo`/`setFee` reachable by non-owner, no proxy.
* No self-destruct / mint of pUSD or LP by outsiders (LP minted only via `addLiquidity`).
* EKL staking & pool2 pay only EKL (unpriced, no market).

---

## 5. Live-state assessment (addresses, code, balances, roles)

All reads are `eth_call`/`eth_getCode` at explicit blocks with keyless public RPCs (see §8). Full dumps: `analysis/pool_state.json`, `analysis/final_state.json`, `analysis/lp_state.json`, `analysis/owner_probe.json`.

1. **Code checks** — all 9 pools have code (base 20,308 B; meta 18,713 B; LPs 4.4–15.9 kB; EKL 15,874 B). No EIP-1967 proxy slots on the pools; `owner()` returns an EOA (0 bytes of code) → no admin backdoor beyond `pause`/fees.
2. **Pause state** — `paused() == false` on all 9 pools (block 229,754,867).
3. **Balances** — as tabulated in §2 (exact raw values in `analysis/final_state.json`).
4. **Triage correction** — the DL adapter's `vaults` list contains `0x4F5d9F3b…` twice; the triage's `sum_tokens` over 10 owners therefore double-counted that pool: 245,895.68 KDAI + 54,795.52 oUSDT + 1,446.55 oUSDC ≈ **$31,342** of the reported $80,359.22. Corrected custody at the triage block ≈ **$49,017** (matches DefiLlama's $47.2–49.5 k). The row's true current live value is **$42,471.69** (priced; junk tokens excluded).
5. **Admin balances (P)** — base pool `getAdminBalances()` = 828.213 KDAI + 1,043.829 oUSDT + 78.317 oUSDC ≈ **$212.70**, fully backed by the pool's balance and withdrawable only by the owner (`withdrawAdminFee()`); meta pool = 0. **p3/p4/p5 are broken**: their recorded `adminBalances` exceed the actual pool balances (p3: 6,232.19 KDAI admin vs 264.03 KDAI held; p5: 756.23 oBUSD admin vs 7.74 held), i.e. the accrued fees were already consumed by LP withdrawals and `withdrawAdminFee()` would revert — phantom, not withdrawable (S).
6. **pUSD** — supply 1,663,773; price flat at $1.0000–1.0003 over 30 days (DL conf 0.99). 10,404 pUSD = 0.63 % of supply → sellable. pUSD is a role-managed (`AccessControl`), `Pausable` token with `mint`/`burn`; it is **not paused** and has **no blacklist/freeze function** (checked: `blacklist`, `addBlackList`, `isBlacklisted`, `freeze`, `blocklist` all revert). Caveat: the issuer could in principle pause pUSD, which would block the pool's outgoing transfer.

### 5.1 Categories (no double counting)

| Category | USD | What |
|---|---|---|
| **E-U** | **10,406.60** | meta-pool pUSD, takeable by any unprivileged account via `swap` (net ≈ $9,494 after input cost) |
| **H-O** | 31,438.06 | base pool $29,604.79 (withdrawable by baseLP holders via `removeLiquidity`) + p3/p4/p5 $1,833.27 (their LP holders) |
| **P** | 212.70 | base-pool unclaimed admin fees (owner-only) |
| **S** | 0 | KSD/KASH/oBUSD/USDK/EKL positions — no market, nobody can realise them |

---

## 6. PoC / fork verification

* Project: `poc/` (Foundry, `forge-std` vendored). Attacker contract: `poc/src/Eklipse.sol` (`EklipseAttacker.attack(tokenIn, amount)` → `addLiquidity` + `swap`). Tests: `poc/test/Eklipse.t.sol`.
* **GitLab CI (primary recorded run — GitHub API was unreachable): pipeline [2945532474](https://gitlab.com/group18185918/eklipse-finance-ci/-/pipelines/2945532474), job 17161592065 → `5 passed; 0 failed`** at fork blocks 229,756,932/229,756,952 (log: `gitlab-log.txt`, copy in `ci-out/gitlab-ci-log.txt`). The CI job ran both `ci/run.sh` and the plain `forge test -vvv` step; both passed ("forked via public RPC" = `public-en.node.kaia.io`).
* CI numbers (block 229,756,952): 8,000 KDAI → 7,422.91 LP → **10,262.57 pUSD** (net +$9,491.77, gas 825,786); 1,700 oUSDC → 3,284.83 LP → **6,201.81 pUSD** (net +$5,698.27); 10,000 KDAI → **10,383.90 pUSD**, leaving 20.07 pUSD (gas 801,604); negative control passes (gas 67,560).
* Local fork run (identical suite): 5/5 PASS at block 229,753,258 (`ci-out/local-forge-test.log`).
* GitHub Actions fallback: run URL(s) appended in `summary.json` once the dispatch completes (`artsbykriss/ca-zombie-ci`, workflow `poc.yml`).
* Test list:
  1. `test_snapshot_state` — live state snapshot (passes always).
  2. `test_exploit_kdai_drain_meta` — 8,000 KDAI → 10,264.54 pUSD (profit assertion > 5× cost).
  3. `test_exploit_ousdc` — 1,700 oUSDC → 6,179.49 pUSD.
  4. `test_max_extraction_kdai_10k` — 10,000 KDAI → 10,383.95 pUSD, leaves 20.01 pUSD.
  5. `test_negative_control_base_swap` — base-pool swap is NOT profitable (market-efficient).
* Fork selection is RPC-agnostic (`KAIA_RPC_URL` env → keyed dRPC from `DRPC_API_KEY` → public Kaia RPCs); no keyed URL is ever written to disk, logs or artifacts.

---

## 7. Verdict, residual & latent risk

* **Verdict: OPEN.** E-U ≈ **$10,406.60 gross / ≈$9,494 net**, HIGH confidence — proven by a fork PoC that executes the full path (mint LP → swap → pUSD) with real contract calls and measures the output.
* The opportunity is stable (balances unchanged over days) and requires only ~$770 of market-bought KDAI; the pool's owner (an EOA) has not paused anything and would have to react to close it.
* Residual/latent: the same "nominal valuation of a depegged LP" bug would re-open on the other meta pools (p6–p9, ~$627 of baseLP) the moment KSD/KASH/oBUSD/USDK obtain any market; p3/p4's ~$1.8k of KDAI/oUSDT/oUSDC is likewise gated only by the junk-token market.
* Blockers for the attacker: none (no pause, no whitelist, no allowance requirement — the pool pulls tokens via `transferFrom` after `approve`). Main non-technical caveat: sourcing ~8–10k KDAI without moving its market price (DL 30-day traded range $0.092–0.106 implies a functioning market; even 10 % slippage leaves ≈ $9.4k net).

---

## 8. Methodology & sources; caveats; files

**Method.** (1) Reconstructed the target set from the DefiLlama adapter history (GitHub commit `2346cd2b2759`) and the triage row; (2) re-verified every address/role/balance on-chain at pinned blocks via keyless public Kaia RPCs; (3) identified the implementation (Saddle-style StableSwap) by extracting the Vyper/Solidity dispatcher selectors from bytecode and matching against openchain/4byte; (4) rebuilt the exact Saddle invariant math in Python and validated it against `calculateSwap` to 9 decimals (fee = 0.06 %); (5) proved the extraction with a Foundry fork PoC (local + CI); (6) priced everything with DefiLlama and cross-checked with the base pool's own swap rates.

**Caveats.** USD values use DefiLlama prices at 2026-10-14 (KDAI $0.09635, oUSDT $0.10509, oUSDC $0.29620, pUSD $1.00025); the attacker's realised profit depends on KDAI acquisition slippage and pUSD exit price, both of which are liquid but not infinitely deep. The PoC funds the attacker via `deal()` (simulating the market purchase) and accounts its cost at market price. Fork blocks drift between runs; all conclusions were reproduced at ≥3 different blocks.

**Files.** `README.md` (this), `summary.json`, `analysis/` (state dumps, math model, P&L, bytecode selectors), `poc/` (Foundry project), `ci/run.sh` (heavy job), `ci-out/` (CI/local logs), `ci-log.txt`, `ci-artifacts/`.
