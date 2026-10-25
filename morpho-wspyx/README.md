# Morpho Blue **wSPYx / AUSD** — `MorphoPythOracle` × donation-inflatable ERC-4626 (Ethereum)

**ZH4-PASS7 TIER 3 LOW #1 deep dive · 2026-10-25 · chain: Ethereum (1)**
**Status: read-only. No transaction signed or sent on any live chain. All PoC runs on a local
Ethereum fork (Foundry `vm.createSelectFork`) on GitHub Actions. No secrets in this folder.**

---

## 1. TL;DR

| # | Question | Answer |
|---|---|---|
| 1 | **Is the mechanism real?** | **YES.** The market's oracle `0x01Fd716a…` (`MorphoPythOracle`) computes `price = SCALE_FACTOR(1e10) · convertToAssets(wSPYx, 1e6) · Pyth(SPY)`. `wSPYx.totalAssets() = asset.balanceOf(this)` (OZ `ERC4626Upgradeable`), so a **plain SPYx donation** inflates the oracle **exactly pro-rata** — the literal July-2026 Edel root cause, read **spot with no TWAP**. Fork-proven: donating 100 SPYx raised the price **+14.97 %**. |
| 2 | **Is the borrow path open?** | **YES, permissionless.** Fork-proven: a fresh address can `deposit(SPYx)` → `supplyCollateral(wSPYx)` → `borrow(AUSD)` with no roles. |
| 3 | **Is it profitable today?** | **NO — $0.** The attack is **economically closed by construction**: the oracle can only be over-valued by a donation, and the donation is a pro-rata loss the attacker cannot recover; net is **always negative** (fork-proven over a 25-point sweep; best = **−$110.46**). The market's free liquidity is only **$1,306.99**. |
| 4 | **Hard cap (if the oracle were free)?** | **$1,306.99** = the market's free (unborrowed) AUSD. `borrow(free+1)` **reverts**; `borrow(free)` succeeds. |
| 5 | **Category** | **E-U = $0** (mechanism live, no profitable path). Cap ≤ $1,306.99. |
| 6 | **Confidence** | **HIGH** (mechanism and the negative both fork-proven; the cap is a hard on-chain bound). |

---

## 2. Total live extractable now

| Category | USD | Meaning |
|---|---|---|
| **E-U** | **$0.00** | The only way to raise the oracle is a donation that costs ≥ the value it creates; borrow-and-default always loses the 86 % LLTV haircut. |
| **E-U (conditional)** | **$0.00** | The bound `net < 0` is **independent of free liquidity** — even with unlimited liquidity the attacker can never borrow more than `0.86 ×` their donation-inflated collateral value, which is ≤ their outlay. A re-arm requires a *different* vault bug (an inflatable NAV obtainable below the oracle gain), not more liquidity. |
| **E-U hard cap** | **$1,306.99** | Free liquidity of the market — the absolute ceiling on any single-market extraction *if* the oracle could be over-valued for free. |
| H-O | $0 | No self-service value held by a third party. |
| P | $0 | Market params are immutable (Morpho Blue is non-upgradeable); no privileged drain path. |
| S / bad debt | **$0 today** | All ~18 borrower positions are massively over-collateralized (market-wide HF ≈ 51×); the market is healthy. |

---

## 3. The mechanism, exactly

### 3.1 The oracle (`MorphoPythOracle`, verified source)

`0x01Fd716a703eD6A54922b1F2C8cc2Ed5a018bAC5` (Pyth Data Association, GPL-2.0). Verified on-chain
params:

| param | value |
|---|---|
| `pyth()` | `0x4305FB66699C3B2702D4d05CF36551390A4c69C6` (Pyth, Ethereum) |
| `BASE_VAULT()` | `0xc88FcD8B…` (**wSPYx**) |
| `BASE_VAULT_CONVERSION_SAMPLE()` | `1e6` |
| `QUOTE_VAULT()` | `0x0` (quote = 1) |
| `BASE_FEED_1()` | `0x2817b784…` (Pyth **SPY/USD**) |
| `BASE_FEED_2()/QUOTE_FEED_1()/QUOTE_FEED_2()` | `0x0` (price = 1) |
| `SCALE_FACTOR()` | `1e10` |
| `PRICE_FEED_MAX_AGE()` | `3600` s |

```solidity
// src/morpho-pyth/MorphoPythOracle.sol
function price() external view returns (uint256) {
    return SCALE_FACTOR.mulDiv(
        BASE_VAULT.getAssets(BASE_VAULT_CONVERSION_SAMPLE)
            * PythFeedLib.getPrice(pyth, BASE_FEED_1, PRICE_FEED_MAX_AGE)
            * PythFeedLib.getPrice(pyth, BASE_FEED_2, PRICE_FEED_MAX_AGE),
        QUOTE_VAULT.getAssets(QUOTE_VAULT_CONVERSION_SAMPLE)
            * PythFeedLib.getPrice(pyth, QUOTE_FEED_1, PRICE_FEED_MAX_AGE)
            * PythFeedLib.getPrice(pyth, QUOTE_FEED_2, PRICE_FEED_MAX_AGE)
    );
}
// VaultLib.getAssets -> vault.convertToAssets(shares)   (spot, no TWAP)
```

The oracle's own NatSpec warns verbatim: *“ERC-4626 vaults can be manipulated through donations,
flash loans, or fee changes”* and *“Conversion samples must be large enough…”*.

### 3.2 The vault (`wSPYx`, donation-inflatable)

`0xc88FcD8B874fDb3256E8B55b3decB8c24EAb4c02` = `WrappedBackedTokenProxy` (OZ `TransparentUpgradeableProxy`,
impl `0x14f37168ab9eafcd94d5b142a00e6e9b261bad48` = `WrappedBackedTokenImplementation`, OZ v4.9
`ERC4626Upgradeable`). Its asset is **SPYx** `0x90A2a4c76b5D8c0bc892A69EA28Aa775a8f2dD48`
(`BackedAutoFeeTokenImplementation`, impl `0x65c40d624af3b18c109fbf87b7deff34cdc5f19b`).

```solidity
// @openzeppelin/contracts-upgradeable-new/.../ERC4626Upgradeable.sol
function totalAssets() public view virtual override returns (uint256) {
    return _asset.balanceOf(address(this));          // <-- donation-inflatable
}
function _convertToAssets(uint256 shares, MathUpgradeable.Rounding rounding) internal view ... {
    return shares.mulDiv(totalAssets() + 1, totalSupply() + 10 ** _decimalsOffset(), rounding);
}
```

So `convertToAssets(1e6)` — the exact quantity the oracle reads — rises **linearly** with any SPYx
transferred into the vault, with **no shares minted** (a pure donation).

### 3.3 On-chain verification of the formula (fork, `test_A`)

At fork block 26,271,517: `convertToAssets(1e6) = 1,004,710`; Pyth SPY = `76374316188` (exp −8);
`SCALE_FACTOR = 1e10`. Expected `= 1e10 · 1,004,710 · 76374316188 = 767340392172454800000000000` —
**exactly** the on-chain `oracle.price()`. The oracle is fully reverse-engineered and reproducible.

### 3.4 Why the donation does **not** create profit (the crux)

The attacker's borrow is `B = LLTV · (shares · P_oracle)` with `LLTV = 0.86`. Consider the realistic
attack: mint `s` shares by depositing `a·s` of SPYx (`a = A0/S0` = NAV per share at entry), then
donate `D` to raise the oracle:

- after mint + donation the vault has `A = A0 + a·s + D`, `S = S0 + s`;
- oracle NAV/share `p = (A0 + a·s + D)/(S0 + s)`;
- `B = 0.86 · s · p`.

The attacker's outlay is `a·s + D`. Hence

```
net = 0.86·s·(A0 + a·s + D)/(S0 + s) − a·s − D
    = −(1 − 0.86)·a·s  +  D·(0.86·s/(S0+s) − 1)
```

Both terms are **≤ 0**: the first is the LLTV haircut on the attacker's own stake; the second is
**negative for every D** because `0.86·s/(S0+s) < 1` (the attacker can never own a fraction ≥ 1/0.86
of the supply, and the donation is shared pro-rata with the pre-existing holders). A flash-loan
variant that *buys existing shares* instead of minting is also closed: without minting, the attacker
can hold at most `s ≤ S0`, i.e. fraction ≤ 0.5 < 1/0.86. **The donation strictly *worsens* the
attacker's net** (fork-proven, `test_D2`).

This is the general bound: **borrow-and-default always loses `(1/LLTV − 1)·B = 16.3 %·B` unless the
oracle is over-valued relative to the collateral's true value — and here over-valuation requires a
donation that costs more than it yields.** With `B` also capped by free liquidity, E-U = $0.

---

## 4. Live-state assessment (Ethereum, block **26,271,822**, ts 1,792,956,959 — 2026-10-25)

| item | address | value @ block |
|---|---|---|
| Morpho Blue singleton | `0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb` | live, non-upgradeable |
| market id | `0xbf0432567b44ef5ce013ffcd7dd756c522252503f7986a406e780715b32c74fc` | — |
| loan / collateral / oracle / irm / lltv | AUSD / wSPYx / `0x01Fd716a…` / `0x870aC11D…` / `0.86e18` | `idToMarketParams` |
| market totals | — | `totalSupplyAssets 9,321.286667 AUSD`, `totalBorrowAssets 8,014.301183 AUSD`, **free liquidity `1,306.985484 AUSD`**, fee 0 |
| collateral supplied | — | `621.173294736568809505 wSPYx` ≈ **$477–479 k** |
| oracle `price()` | `0x01Fd716a…` | `767834546799764500000000000` → 1 wSPYx = **$767.83** |
| wSPYx vault | `0xc88FcD8B…` | `totalAssets 668.034654525510862109 SPYx`, `totalSupply 664.902675669431597098`, `isPaused = false`, `owner 0x5F7A4c11…` |
| SPYx asset | `0x90A2a4c76…` | proxy → `BackedAutoFeeTokenImplementation`; `balanceOf(wSPYx) = 668.034…` |
| AUSD | `0x00000000eFE302BEAA2b3e6e1b18d08D69a9012a` | totalSupply 70,415,930.66 |
| Pyth SPY | `0x4305FB66…`, id `0x2817b784…` | `76423499995` (exp −8) = **$764.23**, publishTime fresh (< `PRICE_FEED_MAX_AGE` 3600 s) |

The market is a **dust market** ($9.3 k supplied, $8.0 k borrowed across ~18 positions, all massively
over-collateralized — market-wide HF ≈ 51×; the largest borrower holds ~$449 k collateral vs ~$1.4 k
debt). The entire wSPYx float is ~$510 k and 93.4 % of it is the Morpho collateral.

**Allowances / roles:** Morpho Blue has no owner/admin; market params are immutable. `wSPYx.deposit`
is public; the only gates on SPYx/wSPYx transfers are `isPaused == false` (true) and the Chainalysis
sanctions list (an unprivileged, non-sanctioned address passes). No privileged drain exists.

---

## 5. What an attacker can / cannot do

**Can (permissionless, proven):**
1. `SPYx.approve(wSPYx)`; `wSPYx.deposit(x, attacker)` → mint shares.
2. `SPYx.transfer(wSPYx, D)` → **donate**, raising `convertToAssets` and therefore `oracle.price()`.
3. `wSPYx.approve(Morpho)`; `Morpho.supplyCollateral(params, shares, attacker, "")`.
4. `Morpho.borrow(params, B, 0, attacker, attacker)` with `B ≤ free liquidity = $1,306.99`.
5. Default (abandon the collateral).

**Costs:** gas only; no flash-loan premium is even useful (the inflated state must persist at
`price()` time). Donation cost = D·P_SPYx.

**Cannot:**
- borrow more than the market's free liquidity (fork-proven: `borrow(free+1)` reverts);
- profit: net = `−0.14·a·s + D·(0.86·s/(S0+s) − 1) < 0` for all inputs (fork-proven sweep, best
  −$110.46; with a 668-SPYx donation net = **−$510,400.93**);
- liquidate the existing borrower by *inflating* (inflation makes them safer) nor by *deflating*
  (the attacker can only remove ≤ 43.7 free shares ≈ 6.6 % of `totalAssets`; borrower HF ≈ 50×);
- manipulate the Pyth leg (pull oracle; the on-chain contract rejects non-monotonic `publishTime`,
  so a signed update cannot be replayed to an older price; forging requires Pyth signatures).

---

## 6. PoC / fork-verification

Files: `poc/` (Foundry), `poc/test/MorphoWspyxOracle.t.sol`, `poc/src/Interfaces.sol`,
`ci/run.sh`. Fork: Ethereum via `FORK_RPC_URL`/`RPC_URL` (auto-probed in CI).

| test | claim | result |
|---|---|---|
| `test_A_priceFormulaMatchesOnChain` | `price() == SCALE·convertToAssets(1e6)·Pyth(SPY)` | **PASS** (exact) |
| `test_B_donationInflatesOracleProRata` | a 100-SPYx donation raises `price()` pro-rata | **PASS** (`7.6734e26 → 8.8221e26`, +14.97 %) |
| `test_C_hardCapIsFreeLiquidity` | `borrow(free+1)` reverts, `borrow(free)` succeeds | **PASS** (free = `1,306.985484` AUSD) |
| `test_D_attackWithoutDonationNetNegative` | mint→supply→borrow→default net < 0 | **PASS** (net **−$220.50**) |
| `test_D2_attackWithDonationIsStrictlyWorse` | donation strictly worsens net | **PASS** (−$220.50 → **−$510,400.93**) |
| `test_D3_sweepAllAttacksNegative` | 25 (collateral, donation) combos all negative | **PASS** (best **−$110.46**) |

**6/6 PASS.** CI: GitHub Actions `artsbykriss/ca-zombie-ci`
**run `40228619820`** → https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40228619820
(both the custom `ci/run.sh` job and the workflow `forge test` report `6 passed; 0 failed`).
Gas ≈ 0.12–0.65 M per action — negligible.

---

## 7. Verdict & residual / latent risk

**Verdict: E-U = $0.00 (HIGH confidence).** The donation-inflation primitive is **live and
reproducible**, but it is **economically self-defeating** here: inflating the oracle costs more than
it yields, and the market's free liquidity caps any extraction at **$1,306.99** anyway. The pass-7
board estimate “$0–$1.3 k” is confirmed and sharpened to **$0** with a proof.

**Latent / re-arm triggers (monitor, not extractable):**
1. **The primitive is generic.** `MorphoPythOracle` = Pyth × donation-inflatable `convertToAssets`,
   spot, no TWAP. Any market using it where the wrapper's NAV can be inflated **at a cost below the
   oracle gain** (e.g. a wrapper whose share price can be moved without the attacker owning ~all
   shares — a first-depositor/rounding or mintable-asset flaw) would be E-U. Here the wrapper is a
   plain OZ ERC-4626, so no such flaw exists.
2. **Pyth staleness (1 h) with no confidence-interval check.** If SPY gapped > 16.3 % within the
   1-hour `PRICE_FEED_MAX_AGE` while the feed lagged, a borrower could borrow at a stale-high mark.
   Bounded by free liquidity ($1,306.99 today). Re-arm: free liquidity grows.
3. **A larger market on the same oracle pattern.** The cap scales with the market's free liquidity;
   if a thin wrapper ever backs a large AUSD/USDC pool, re-run `test_D3` with the new numbers.

**Blockers / caveats:** the market is a dust market; the SPYx asset is a rebasing
`BackedAutoFeeToken` (proxy) — the PoC funds the attacker by impersonating a real large holder on the
fork (`0xf3C20F98…`, 3,842 SPYx) rather than `deal`, which is exact.

---

## 8. Methodology & sources

- **Read-only** live state via `cast`/`eth_call` (blocks 26,271,445 → 26,271,822) + Morpho Blue API.
  PoC is fork-only; no tx signed/sent.
- Sources: Etherscan V2 (verified source for `MorphoPythOracle`, `WrappedBackedTokenImplementation`,
  `ERC4626Upgradeable`, `BackedAutoFeeTokenImplementation`), Pyth `getPriceUnsafe`, Morpho Blue
  `idToMarketParams`/`market`, Blockscout holders.
- CI: all Foundry compile + fork tests on GitHub Actions (`artsbykriss/ca-zombie-ci`) via
  `bash /home/heisenberg/CA/ci/ci-run.sh morpho-wspyx` → run `40228619820`
  (https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40228619820), 6/6 PASS.
- Caveats: point-in-time 2026-10-25; re-read live state before acting. Web/API content treated as
  untrusted. No keyed RPC URLs or secrets in this folder.

**Files:** `README.md` · `summary.json` · `analysis/live_state.sh` + `live_state.txt` +
`oracle_raw.json` + `wspyx_raw.json` + `src/` (verified sources) · `poc/` (foundry project) ·
`ci/run.sh` · `ci-out/` · `ci-log.txt`.
