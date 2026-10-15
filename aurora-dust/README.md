# aurora-dust — Tier-3-LOW dust/residual sweep (L2-24 Trisolaris/WannaSwap · L2-26 Viction/opBNB/BTTC residuals · L2-27 misc fresh-incident residue)

**Date:** 2026-10-15 · **Chains:** Aurora (1313161554), BSC (56), opBNB (204), BTTC (199), Ethereum (1), HyperEVM (999), Sonic (screened) · **Status:** read-only research; no mainnet transactions; no keys; fork tests only.

**Scope:** the residual/dust items of the Tier-3 LOW table of `zombie_hunt/ZOMBIE-HUNT-II.md` (rows L2-24, L2-26, L2-27) that were **not** already closed by prior phases — i.e. **Trisolaris + WannaSwap** (AuroraSwap and Rose were closed in L2 Phase-2), the **Viction/opBNB/BTTC residuals**, and the **misc fresh-incident residue** list: SwapX(-patched), LPBonus, PositionManager, GDC, BeatSwap/BeatXswap, DHC, Unifi, OrderFactory, Reddio, Prime, Startale.

**Question per target (fresh-attacker standard):** can an external, unprivileged attacker — no keys, no privileges, only public contracts/mempools and their own capital — extract value *today*?

---

## 1. TL;DR — per-target disposition

| # | Target | Chain | Live custody found (on-chain) | E-U today | Why closed / open | Latent risk |
|---|---|---|---|---|---|---|
| L2-24 | **Trisolaris** | Aurora | **$1,869,977** in 1,011 live UniV2 pairs + $2.0k stableswaps + $15.8k farm TRI + $739 xTRI bar | **$0** | Standard UniV2 fork (single pair codehash); 0 skim excess on top-80 pairs (sequential re-verify); balances == reserves; USN stableswap marginal price ($0.0907) ≈ USN market ($0.0867) → no material edge; farms/bar dynamic-ratio, no capture | LP property (H-O); USN pool $775 if USN ever becomes free |
| L2-24 | **WannaSwap** | Aurora | **$82,399** in 155 live pairs | **$0** | Same class; 0 skim excess on top-40 pairs | LP property (H-O) |
| L2-26 | **LuigiSwap (opBNB)** | opBNB | **$433.53** real balances (48 pairs) — **$137,684 of "reserves" is phantom** (10 pairs: 23–42 WBNB reserve vs 0 WBNB balance) | **$0** | Drained pairs; reserves stale; swaps revert (K-check on 0 balance); skim gives nothing (balance < reserve); no counter-token path | DefiLlama shows $275k phantom TVL — misleading for other hunters |
| L2-26 | **SpookySwap (BTTC)** | BTTC | **$21,466** (142 pairs, 11 live) | **$0** | Standard UniV2 fork, in sync, 0 skim-able pairs | LP property |
| L2-26 | **Intercroneswap (BTTC)** | BTTC | **$3,506** (440 pairs, 59 live) | **$0** | Same; 0 skim-able | LP property |
| L2-26 | **Kyber Classic (BTTC)** / Elk / JustMoney / InfiniTORR / MDEX / TORRSwap / UniFi-BTTC | BTTC | DL-scale $918–$14.8k each | **$0** | Screened at DefiLlama-scale (standard forks); **not individually re-enumerated** (documented limitation) | dust |
| L2-26 | **Viction residuals** | Viction | LuaSwap $17.8k E-U (already reported **C2-04**), deFusion (L2-12, sibling folder) | **$0** (residuals) | No other Viction protocol with live custody; nothing new found | LuaSwap counted under C2-04 |
| L2-27 | **SwapX** (2023 BSC incident; "patched") | BSC | selector `0x4f1f05bc` still in code; 8/16 victims still have **live BUSD allowances** (up to 3.96e10 BUSD) | **$0** | All victim BUSD balances are **0** (drained 2023) → `min(balance, allowance)` = 0. No post-2026-09 SwapX incident exists (DeFiHackLabs/DefiLlama checked) | If a victim ever receives BUSD again, the standing allowance is still spendable — worth a monitor |
| L2-27 | **LPBonus / MSN** | BSC | LPBonus pot **6,568.18 FIST ($1,522)**; MSN token holds **114,726.25 FIST + 3,762.28 USDT ($30,338)** | **$0** | Pot not profitably claimable — proven bound (see §4): over-claim factor ≤ A/R requires crushing the MSN reserve; the AMM round-trip fee **always** exceeds the pot for every feasible (A,R). MSN's own FIST/USDT are **stuck** (no rescue function) = S | LPBonus pot is H-O-ish for 894 LPs; MSN assets stuck |
| L2-27 | **PositionManager** | BSC | vault holds 1,431,203 wei USDT (18 dec) = $1.4e-12 | **$0** | Deposit path live but vault holds nothing | — |
| L2-27 | **GDC** | BSC | pair in sync: **0.157438 WBNB ($113.44)** + 491.28M GDC | **≤ $113.44 (conditional, unproven)** | Vulnerable code live (`stage1Ended()=0`, `deflationStopped()=0`, burn-collapse + reentrancy + extcodesize bugs present); pair nearly drained → ceiling = the pair's WBNB. Net after the attacker's round-trip **not** PoC-verified | Exploit path live; monitor if the pool is ever re-funded |
| L2-27 | **BeatSwap / BeatXswap** | BSC | 5 PancakeSwap-V3 LP NFTs worth **$7,050.31** (all-USDT side) owned by the two vesting contracts + 0.056/0.941 BTX dust | **$0** | `deposit()` paused on both; NFT withdrawal is `NotVestingOwner`-gated (beneficiary-only) → H-O; no permissionless mover | beneficiary recovery (H-O) |
| L2-27 | **DHC** | BSC | award proxy holds 1.0824 DHC (DHC/USDT pool exists, $41.5k) | **$0** | Award re-claim path live but the proxy's residual is dust | — |
| L2-27 | **Unifi** | BSC | reward manager holds 0.000211 UP; redeemer 0 | **$0** | Fake-pool claim path live but nothing left to drain | — |
| L2-27 | **OrderFactory** | Ethereum | factory 0 ETH, account system 0 ETH | **$0** | Drained (24.7 ETH incident) | — |
| L2-27 | **Reddio (RSV)** | Ethereum | vault holds **788.292235 USDT** exactly backed by rsvUSDT supply 788.291890 (≈1:1); 1 wei stETH; 1e11 WETH | **$0** | Share-price inflation bug persists, but needs pre-existing shares + an inflatable provider leg; the only provider (Lido) leg reads raw stETH = **1 wei** → inflation yields ~0; USDT is fairly backed | H-O (rsvUSDT holders); re-opens if ETH/stETH is ever deposited again |
| L2-27 | **Prime / PrimeFinance** | HyperEVM | lending pool aWHYPE holds 0.006142 WHYPE; DataStreamConsumer live | **$0** | Stale-report oracle bug persists but the WHYPE reserve is empty → nothing to borrow | monitor |
| L2-27 | **Startale** | Ethereum | factory + collector hold 0 USDC/USDT | **$0** | Transient-storage re-init bug persists, but the drain needs pre-funded counterfactual accounts; the ~330-account campaign drained them; no live funded victims identified | monitor new pre-funds |

**Total live extractable by an external unprivileged attacker, proven today: $0.00 (high confidence).**
Conditional, unproven bound: **≤ $113.44** (GDC, if the burn-collapse round trip still nets positive against the now-drained pool — not PoC-verified).
Live custody *not* attacker-extractable: ≈ $1.98M LP/protocol property (H-O/P/S split below).

| Category | USD | Notes |
|---|---|---|
| **E-U** (proven) | **$0.00** | every screen/closure documented below |
| E-U conditional | ≤ $113.44 | GDC only (unproven net) |
| **H-O** (holders/beneficiaries) | ≈ $1,954,000 | Trisolaris $1.89M (LP) + WannaSwap $82k (LP) + BeatXswap NFTs $7,050 (vesting beneficiaries) + Reddio USDT $788 (rsvUSDT holders) + LPBonus pot $1,522 (894 LPs) |
| **S** (stuck) | ≈ $30,338 | MSN token's FIST+USDT (no rescue function) |
| **P** (privileged) | — | Trisolaris MC/factory multisig + GDC owner + swapX-era leftovers (not quantified; no unprivileged path) |

---

## 2. L2-24 — Trisolaris + WannaSwap (Aurora) — E-U $0 (high/medium-high)

**Live state (blocks: Aurora 220,069,716–220,071,422; re-verified at CI):**

*Trisolaris* (factory `0xc66F594268041dB60507F00703b152492fb176E7`, docs-verified core):
- **1,418 pairs** total, 1,011 with non-zero reserves; **Σ pair USD = $1,869,977** (prices: DefiLlama `coins.llama.fi`, per-token decimals incl. WNEAR 24-dec; cross-check DefiLlama TVL $2,094,870 — difference = stableswaps + price drift).
- Top pairs: wNEAR/WETH $440,092 (`0x63da4db6…`), AURORA/wNEAR $331,762, USDT.e/wNEAR $284,485, USDC.e/wNEAR $176,471, stNEAR/wNEAR $104,118.
- **Reserves == balances** on every checked pair (single pair codehash `0x279c2e57…` — standard UniV2); **skim excess = 0 on the top-80 pairs by value** (sequential, non-batched re-verification after a batched scan produced decoding artifacts).
- Stableswaps: USDC/USDT/USN pool `0x458459E4…` holds 32,705.37 USN + $387.48 USDT + $388.11 USDC (`calculateSwap(2,1,1e18)` = 0.090665 USDT/USN); USDC/USDT `0x51d96EF6…` $108.6; nUSD metapool `0x3CE7AAD7…` 1,155.72 nUSD.
- **USN angle (checked, closed):** USN total supply 609,200; the only external market is the wNEAR-USN pair `0xA36DF7c5…` (402.36 USN + 7.65 WNEAR → implied USN ≈ $0.0867) — essentially equal to the stableswap's marginal price $0.0907. Dumping externally-bought USN yields a sub-$3 edge at most (dust); deep dumps are priced down the StableSwap curve. **No material path.**
- Farms: MC1 `0x1f1Ed214…` holds 39,532,110.5 TRI ($5,066), MC2 `0x38389567…` 78,217,896.5 TRI ($10,024) — emissions accrue pro-rata to stakers (fair-value; no capture); xTRI bar `0x802119e4…` 5,766,738.4 TRI vs 2,606,509.1 xTRI (ratio 2.21, dynamic); TriMaker `0xe793455c…`, pTRI, USDC Maker all hold 0.
- Admin: factory/MC ownership = Trisolaris DAO multisig `0xf86119de…` / ops `0x99cbfCf7…`; no permissionless mover found.

*WannaSwap* (factory `0x7928D4FeA7b2c90C732c10aFF59cf403f0C38246`):
- **181 pairs**, 155 with reserves, **Σ $82,399** (top: WANNA/WNEAR $34,642 `0xbf9eef63…`); top-40 skim excess = 0.

**Verdict:** abandoned-but-live standard UniV2 forks; all custody is LP property. The same class was closed for AuroraSwap in L2 Phase-2 (125 pairs, 0 skim excess, single pair codehash, feeTo-only fee mint) — Trisolaris/WannaSwap inherit that analysis with the same evidence pattern. **E-U $0 (high for skim/standard-AMM paths; medium for "no exotic bug" — sweep-level, not a line-by-line audit).**

---

## 3. L2-26 — Viction / opBNB / BTTC residuals — E-U $0 (high)

**opBNB — LuigiSwap (`0x0dAe6d22…` factory, 48 pairs):** real balances (token `balanceOf`) total **$433.53** — matching the triage's $449.60, **not** DefiLlama's $275,368. The gap is **phantom TVL**: 10 pairs carry stale reserves of 23–42 WBNB while their actual WBNB balance is **0** (verified: `getReserves()` r0 = 42.52e18 vs `WBNB.balanceOf(pair)` = 0; same pair codehash as the in-sync pairs). Such pairs are bricked (swap reverts on the K-check; `skim()` sends nothing since balance < reserve). The pairs that are in sync hold dust (top: $56.50). **E-U $0.**

**BTTC:** SpookySwap `0xEE4bC421…` 142 pairs → **$21,466** real (top `0xbf9518af…` USDT_t $21,008 + 64.6e9 …), 0 skim-able; Intercroneswap `0x0cEE0dFb…` 440 pairs → **$3,506**, 0 skim-able. Kyber Classic factory `0xD9bfE997…` does not expose `allPairsLength()` (different interface) — not deep-screened (DefiLlama $10.5k). FilDA (L2-08), deFusion (L2-12), AntePool (L2-18) are covered by the sibling `bttc-viction-aurora` folder; LuaSwap (Viction) is C2-04 ($17.8k proven E-U, already counted). **E-U $0 for all residuals.**

---

## 4. L2-27 — misc fresh-incident residue — E-U $0 (high), one conditional ≤ $113

### 4.1 LPBonus / MSN (BSC) — mechanism + provable non-extractability

Incident (DeFiHackLabs `2026-09/LPBonus_exp.sol`): MSN's LP-reward pool `0x52272524…` (unverified, bytecode-reversed) accrues `oneshareFIST += fistOut*1e18 / reserveMSN` and pays `pending = (oneshareFIST − takedFIST[user]) * poolshare / 1e18`, `poolshare = min(LPbal*reserveMSN/LPtotal, userAddAmount)`. The attacker inflated the index at a **crushed** MSN reserve (89 MSN) and claimed at a **restored** reserve (491), over-claiming ~1.44M FIST.

**Live state (BSC 127,789,492):** LPBonus FIST pot **6,568.18 FIST ($1,522** at the FstSwap-implied $0.2317; the USDT/FIST pair holds $3.30M/14.26M FIST — FIST is a real, liquid token**)**; pair reserves FIST 1,308,307.90 / MSN 482.81; 894 registered LP holders (top-30 pending ≈ 8.2 FIST); LPBonus MSN balance 0.

**Why the residual pot is not profitably claimable (bound):** the over-claim factor is `poolshare / R ≤ A/R` where `A` = attacker `userAddAmount` (MSN added as liquidity) and `R` = the MSN reserve at inflation time. With the pot `P` capping the claim, max gross gain = `P·(1 − R/A)`. Crushing the reserve from `M0+A` to `R` costs an AMM round trip of `F_in ≈ F0·(1+A/M0)·(M0+A−R)/R` FIST; the two 0.25% pool fees alone (a **lower bound** on cost) are `0.005·F_in`. For every feasible `A` (≤ MSN total supply 5,000) and `R`, **`P·(1−R/A) < 0.005·F_in`** — e.g. A=482, R=241 → gain ≤ 3,288 FIST vs fee ≥ 39,300 FIST; A=5,000, R=274 → gain ≤ 6,208 FIST vs fee ≥ 1.4M FIST. **No profitable attack exists** (fork test asserts this over a parameter grid; CI-verified).

**MSN token's own FIST/USDT ($30,338):** `MSNToken` has **no function that moves arbitrary ERC-20s it holds** (checked full verified source: only its own `_balances` and the `cutter`/pair hooks). → **S (stuck)**.

### 4.2 GDC (BSC) — live path, bounded ≤ $113.44 (conditional)

`GDCToken 0xe3342358…` still contains the incident's bugs (verified source: `receive()` extcodesize-only gate; "buy as remove" `isRemove` misclassification; `swapSellAward` forwards only 30% while `_burnSellAgainstPair` burns the **full** nominal from the pair + `sync()`; reentrant tax-free exit via the referral `_sendBNB` raw call). Stage state: `stage1Ended()=0`, `deflationStopped()=0` (stage-1 burns still execute). Pair `0x9cd8d04c…` is in sync: **0.157438 WBNB + 491.28M GDC** (WBNB balance == reserve). The extraction ceiling is therefore the pair's WBNB = **$113.44** (BNB $720.66). Not PoC-verified (the original PoC's amounts are tuned for the pre-incident pool; a tuned PoC's value is bounded by $113) → reported as a **conditional bound**, not headline.

### 4.3 Remaining L2-27 items — all $0

- **SwapX (2023 BSC, "patched")**: `0x6D898184…` still has the exploit selector `0x4f1f05bc`; 8/16 victims still hold **live BUSD allowances** (up to 3.96e10) but **all balances are 0** → drainable = 0. No post-2026-09 SwapX incident exists (DeFiHackLabs 2026-09/10 + DefiLlama hacks DB scanned; Sonic's swapx.fi shows no exploit record).
- **PositionManager** `0x7cedB2e5…`: holds 1,431,203 wei USDT (18 dec) = $1.4e-12. Closed.
- **BeatXswap** vesting `0x1e647FAA…` / `0x9a7A9224…`: `paused()=1` on both; own 2+3 PancakeSwap-V3 NFT positions worth $7,050.31 (USDT side) — `withdraw()` is `NotVestingOwner`-gated (beneficiary-only) → **H-O**; raw BTX 0.056/0.941 (dust).
- **DHC** proxy `0xe2a047aa…`: 1.0824 DHC (award re-claim path live; DHC/USDT pool $41.5k exists, so the token is tradeable) → residual dust, $0.
- **Unifi** manager `0x5D8aA155…`: 0.000211 UP; redeemer 0; fake-pool claim path live but empty → $0.
- **OrderFactory** `0xa27bcd59…` + Account System `0xfcf3d97c…`: 0 ETH each → $0.
- **Reddio RSV** `0x4315990D…`: 788.292235 USDT vs rsvUSDT supply 788.291890 (≈1:1 backed → H-O); 1 wei stETH; 1e11 WETH; the permissionless `registerErc20` + shared-raw-balance inflation bug persists but the only provider leg (Lido) reads raw stETH = 1 wei → inflation yields ~0 → E-U $0.
- **Prime/PrimeFinance** (HyperEVM): lending pool's aWHYPE holds 0.006142 WHYPE; `DataStreamConsumer` live (stale-report bug) but nothing to borrow → $0.
- **Startale** (Ethereum): factory `0x0000003B…` + collector hold 0 USDC/USDT; the transient-storage re-init bug persists, but draining requires pre-funded counterfactual accounts (the ~330-account campaign drained them) → $0 (no live funded victims identified).

---

## 5. What an attacker can/cannot do — exact gates

| Target | Attacker path | Exact gate that blocks it (live value) |
|---|---|---|
| Trisolaris / WannaSwap | `skim()` excess; stale-price arb; farm capture | skim excess = 0 (top-80/top-40 re-verified); reserves == balances; USN market ≈ pool marginal (edge < $3); farms pro-rata |
| LuigiSwap opBNB | `skim()`; swap out WBNB | 10 pairs: WBNB balance = 0 < reserve → `skim` sends 0, `swap` reverts on K-check; in-sync pairs hold $433 total, LP-owned |
| SpookySwap/Intercroneswap BTTC | skim/arb | 0 skim-able; standard forks; in sync |
| swapX (BSC) | `0x4f1f05bc(..., victim)` pulling BUSD | `min(BUSD.balanceOf(victim), allowance)` = **0** for all 16 victims |
| LPBonus | userAddLP → crush MSN reserve → fund index → burn LP → `UserRemoveLp` claim | `P·(1−R/A) < 0.005·F_in` for all feasible (A,R) — crush fee always exceeds the 6,568 FIST pot |
| GDC | deposit-in-constructor → untaxed buy → taxed sell burn-collapse → reentrant dump | **none found** (path live); ceiling = 0.157438 WBNB; net unproven |
| BeatXswap | withdraw/claim the LP NFTs | `info.user == msg.sender` (`NotVestingOwner`); `deposit` paused |
| Reddio RSV | register asset → deposit → redeem inflated shares | needs inflatable provider leg; Lido raw stETH = 1 wei; rsvUSDT 1:1 backed |
| Prime | replay stale signed report → borrow | WHYPE reserve = 0.0061 |
| Startale | re-init account → delegatecall sweep | needs pre-funded counterfactual account; none identified |

---

## 6. PoC / fork verification

- **`poc/test/LPBonusBound.t.sol`** — BSC fork test: reads live LPBonus/pair state and asserts that **no** (A,R) parameter set makes `P·(1−R/A) > 0.005·F_in`. Local: **1/1 PASS** (pot 6,568.18 FIST, worst-case gross gain 6,208.06 FIST, fee lower bound always larger). CI: see `ci-log.txt` / run URL below.
- **`ci/run.sh` + `analysis/ci_verify.py`** — CI state re-verification across Aurora/BSC/opBNB/BTTC/Ethereum/HyperEVM at fresh blocks; writes `ci-out/state-verification.json` (artifact). No keys; public RPCs only.
- **`analysis/`** — all screen scripts + raw JSON dumps (per-target balances, reserves, prices, skim checks): `l2-27-*.json`, `trisolaris-*.json`, `wannaswap-pairs.json`, `l2-26-*.json`, `swapx-residue.json`, `skim-top-verified.json`.
- CI runs: see §8 (`ci-log.txt`, `ci-artifacts/`).

---

## 7. Verdict, residual/latent risk, blockers

- **E-U proven: $0.00 (high).** Every listed target is either empty (balances ~0), closed by a live gate (paused/beneficiary/owner-gated), backed fairly (H-O), stuck (S), or economically unreachable (LPBonus bound).
- **Conditional (unproven): GDC ≤ $113.44** — the only target whose exploit path is fully live today; the net after the attacker's round trip was not PoC-verified. If the GDC pool is ever re-funded, this re-opens at the new pool size.
- **Latent risks worth monitoring:** (1) swapX victims' standing BUSD allowances (spendable the moment a balance appears); (2) Reddio RSV — any new ETH/stETH deposit re-arms the inflation bug; (3) Startale pre-funded counterfactual accounts; (4) Prime's stale-report oracle if the reserve is re-funded; (5) LuigiSwap phantom reserves — any tool trusting `getReserves()` will overstate TVL by $137k.
- **Blockers/limits:** Kyber-Classic BTTC (interface), Elk/JustMoney/InfiniTORR/MDEX/TORRSwap/UniFi-BTTC (DefiLlama-scale screen only), Startale victim enumeration (not feasible without a full address scan) — all dust-scale; none changes the headline.

---

## 8. Methodology & sources; caveats; files

**Method:** live `eth_call`/`getBalance`/`getCode` at recorded blocks (public RPCs: mainnet.aurora.dev, bsc-rpc.publicnode.com, opbnb-rpc.publicnode.com, rpc.bt.io, ethereum-rpc.publicnode.com, rpc.hyperliquid.xyz/evm); factory enumerations (allPairs/allPairsLength) with per-token decimals; DefiLlama `coins.llama.fi` prices; DeFiHackLabs incident PoCs (2026-09/10, 2023-02) for addresses/mechanisms; DefiLlama hacks DB + adapters; verified contract sources (MSNToken, GDCToken, LiquidityVestingConvert, InvestmentManagerFacet); fork tests (Foundry, local + CI).

**Caveats:** sweep-level (not line-by-line audits) for Trisolaris/WannaSwap and the BTTC long tail; LPBonus/GDC are unverified-by-source contracts (analyzed via bytecode-reversed interfaces + the published PoCs + live state); GDC's net extraction is unproven; USD values use one price snapshot (FIST $0.2317, BNB $720.66, TRI $0.000128, WANNA $0.000431); batched-scan artifacts were re-verified sequentially for the material sets.

**Files:** `README.md` (this), `summary.json`, `analysis/` (scripts + raw dumps), `poc/` (Foundry), `ci/`, `ci-out/`, `ci-log.txt`, `ci-artifacts/`.

**CI:** GitHub Actions `artsbykriss/ca-zombie-ci`, branch `aurora-dust` — run URL recorded in `ci-log.txt` (see final run below).
