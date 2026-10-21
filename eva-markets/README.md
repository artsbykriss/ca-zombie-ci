# Eva Markets (Ethereum) — face-valued Wildcat deposits: live E-U **$0.00**, $5.31M is depositor/H-O exposure

**Date:** 2026-10-21 · **Chain:** Ethereum · **Block:** 26,241,741 (ts 1,792,594,931)
**Status:** read-only; PoC fork-verified only; no mainnet transactions signed or sent.

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why closed | Latent / conditional |
|---|---|---|---|
| **Eva Markets** — evaUSDC `0x741b…0F58`, evaUSDT `0x501e…8B8B`, evaETH `0xdBEC…7e4C` | **$0.00** | All 3 Wildcat markets are **current** (`isDelinquent = false`). `depositFromMarket()` does mark at face, but each vault is **single-market**: face-minted shares are a pro-rata claim on the same market, so they do not dilute existing holders. There is **no on-chain venue** to buy impaired `wmt*` tokens at a discount (DexScreener/DefiLlama/Curve: no pair). The vault's live liquid USDC is **$112.998**. | **$2,695,448.45** cash-cap if a discounted `wmt*` venue appeared **and** the vault could queue a withdrawal before delinquency; **$5,314,011** accounting overstatement if Wintermute defaults (H-O/S). A 200k exit (8.2% of evaUSDC) already freezes the vault. |

**Total live extractable now: $0.00 — confidence: high.**

The pass-3 claim ("$5.31M conditional on delinquency + discounted token") is directionally right about the **mark**, but overstates the **extraction**: `depositFromMarket` at face is pro-rata fair while the market is current, the only live cash is $113, and in delinquency the vault's queue freezes before an outsider can redeem. The $5.31M is depositor money at risk from a Wintermute default, not an unprivileged attacker's payout.

---

## 2. Total live extractable now

| Category | USD | Basis |
|---|---:|---|
| **E-U (external unprivileged)** | **$0.00** | No delinquency, no discount venue, no forced-delinquency path, no liquid vault balance |
| E-U conditional | $0 today / ≤$2,695,448 cap | Requires an impaired `wmt*` seller + pre-delinquency queue slot; no such venue exists on-chain |
| H-O (holder-recoverable) | $5,314,010.84 | Vault depositors' async claims via `requestRedeem` → Wildcat withdrawal batch |
| P (privileged) | $5,314,010.84 | Three upgradeable proxies (ProxyAdmin → `0x85d19E…`) + `onlyAuthorized` operator (`skim`, `queueRequestsBatch`); overlaps H-O — not additive |
| S (stuck) | $0 today | Conditional: a partial batch freezes all requests (proven); a default leaves the face-marked NAV unrecoverable |

---

## 3. The mechanism, in exact terms

### 3.1 Vaults and markets

All three vaults are `TransparentUpgradeableProxy` → implementation `0xdc9f47c2cc5647be812f9ba3e2fc94ae16582e2e` (`EvaVault`, verified). Each vault is 1:1 (`totalAssets == totalSupply`) and holds one Wildcat market token:

| Vault | Market | Market name | `totalAssets` | Market token balance (face) | Idle asset | `excess()` |
|---|---|---|---:|---:|---:|---:|
| evaUSDC `0x741b…0F58` | `0xC9499006a149C553d18171747ED19Aa7C6Dd19E2` | Wintermute Trading USD Coin (`wmtUSDC`) | $2,440,738.43 | $2,445,624.90 | **$112.998** | $4,999.47 |
| evaUSDT `0x501e…8B8B` | `0x5Ab22e9c360807F16DFA34AD5C589055d2871a5B` | Wintermute Trading Tether USD (`wmtUSDT`) | $2,870,718.36 | $2,876,737.40 | $0 | $6,113.07 |
| evaETH `0xdBEC…7e4C` | `0xBAd1b632E90Ce02af868f07c572adB067eB98353` | Wintermute Trading WETH (`wmtWETH`) | 1.0182047 ETH ($2,554.05) | 1.0150105 ETH | 0 | 0.0009247 ETH |

**Total: $5,314,010.84** at ETH $2,508.38 (DefiLlama, 2026-10-21). `excess()` is unrealized interest; only the operator can `skim()` it (mints shares to the operator, does not pay USDC).

### 3.2 `depositFromMarket()` exact valuation

```
scaledBefore = wildcat.scaledBalanceOf(vault)
transferFrom(msg.sender, vault, marketAssets)
scaledAfter  = wildcat.scaledBalanceOf(vault)
balanceAfter = wildcat.balanceOf(vault)
scaledReceived = scaledAfter - scaledBefore
shares = balanceAfter * scaledReceived / scaledAfter     // = normalized (FACE) value received
virtualAssets += shares; virtualShares += shares; mint(receiver, shares)
```

`balanceAfter / scaledAfter = scaleFactor / RAY`, so `shares` is exactly the **face** value of the received scaled tokens — no delinquency haircut, no market-price input. The function is permissionless (no whitelist) and has a **$2,000 minimum**. This is real, and the PoC reproduces it: 2,499,999,999 `wmtUSDC` → **2,499,999,999 shares**, `previewRedeem` = face.

### 3.3 Why it is not a live drain

1. **Single-market pass-through.** Each vault's only asset is one Wildcat market. Minting shares at face proportional to the tokens transferred does not change the per-share claim on that market: before 100 shares claim 100 tokens; after a 100-token/100-share deposit, 100/200 shares still claim 100/200 of the 200 tokens. There is no cross-subsidy from existing holders. The attacker's gain is only `(true recovery − price paid)` on the tokens they bought — a secondary-market arbitrage, not a vault exploit.
2. **No venue for impaired tokens.** `wmtUSDC`/`wmtUSDT`/`wmtWETH` have **no DEX pair** (DexScreener `pairs: null`; DefiLlama price empty; Curve registry 0 pools). The only on-chain `wmt*` venue is the Wildcat market itself, which mints at par. There is no trustless way to buy at a discount.
3. **No liquid vault balance.** A `claimRequest` pays only from the vault's actual USDC (`underlying.balanceOf(vault)`), not from `totalAssets`. Live idle is **$112.998**; `excess` is unrealized market interest. The vault's `deposit()` sends new USDC straight into the market, so it does not accumulate idle cash.
4. **Delinquency freezes the exit.** `_queueRedeemRequests` calls `_trySettleActiveBatch`; if the active batch is expired but not fully paid, `activeBatchExpiry` is not cleared and the next `queueRequestsBatch` reverts `ActiveBatchExists`. `claimRequest` requires the **full** `requestAmount`; a partial batch payment is trapped. The attacker's shares are burned at `requestRedeem`, and `cancelRequest` reverts once queued. The "exploit" locks capital, it does not free it.

### 3.4 Can a fresh attacker force delinquency? No.

Wildcat delinquency is `liquidityRequired() > totalAssets()` — i.e., an unpaid withdrawal batch exceeds cash. `queueWithdrawal` is permissionless for market-token holders, but an attacker who deposits USDC to obtain tokens **adds cash equal to the queue**, so the batch is payable. To queue without adding cash, the attacker needs an existing `wmt*` position; there is no on-chain way to acquire one at a discount. The realistic triggers are the borrower missing a payment or a large existing holder exiting — both external to a fresh attacker.

The PoC shows how fragile that is: a **200,000 USDC exit (8.2% of evaUSDC)** from the Curve pool is enough. The market's cash is $126,379.56, so the batch is partial; `claimRequest` reverts, `isDelinquent` becomes true (`timeDelinquent` 86,401 s), and a second `queueRequestsBatch` reverts `ActiveBatchExists`. The entire vault's redemptions freeze until Wintermute repays the $73,620 shortfall.

---

## 4. Live-state assessment (all at block 26,241,741)

### 4.1 Market state

| Market | Cash | Total debt | Face supply | Scale factor | Interest | Reserve | Delinquent? | `timeDelinquent` |
|---|---:|---:|---:|---|---:|---:|---|---:|
| `wmtUSDC` | **$126,379.56** | $74,024,134.68 | $73,942,515.06 | 1.179076487… | 8.50% | 0 | **false** | 0 |
| `wmtUSDT` | **$2,544,640.35** | $48,665,999.47 | $46,154,514.78 | 1.181221753… | 8.75% | 0 | **false** | 0 |
| `wmtWETH` | **9.738754821 ETH** ($24,426.60) | 2,360.699354 ETH | 2,351.669500 ETH | 1.064242359… | 3.75% | 0 | **false** | 11,184 (historic, cured) |

Borrower of all three: **`0x5b15F94EFC3A6e2c82D7db8efd8D5ba55dA11fEb`** — an EOA (code size 0), the Wintermute Trading market. All three markets are current on interest; the cash coverage is 0.17% / 5.51% / 0.41%, so the markets are demand-deposit-like and a run is the risk, not a live accounting bug.

### 4.2 Roles and upgradeability

| Item | Address | Notes |
|---|---|---|
| evaUSDC proxy admin | `0x5c6faf8bcb297b8f475c74c31eb37da3d97ee69b` | `ProxyAdmin`, owner `0x85d19EC4Be9720b55951759034d3eD35FB47E5e8` (10,853-byte contract) |
| evaUSDT proxy admin | `0x19d1db3abe8d6eb7ac53a13e39615224c0b84357` | same owner |
| evaETH proxy admin | `0x247aa660ca957c6c488982a0310353abbef02911` | same owner |
| Vault owner / governance | `0xc672CB223c11C7Db2C99Ce739629A4366ecAB8fF` | 345-byte contract |
| Mastermind / operator | `0xEa2Bc9417f776fe5509a1e68Cd26e0D76BCD01b2` / `0x42E24C894Dc784276828fE74f47B35B0c8A676fD` | operator is an EOA; `skim`, `queueRequestsBatch`, `depositIdleToMarket` are `onlyAuthorized` |
| Implementation | `0xdc9f47c2cc5647be812f9ba3e2fc94ae16582e2e` | upgradeable — **P risk over the full $5.31M** |

### 4.3 The only secondary market

`evaUSDC` and `evaUSDT` trade in a Curve pool `0x3C0965582dB7A0F660D491aA6174B9438f911c21` (2.1925M evaUSDT + 1.9166M evaUSDC; ~$4.1M TVL; price ~0.9986/0.9980). This is **vault shares**, not `wmt*` market tokens. Buying evaUSDC at 0.9986 and redeeming at 1.0 is a 0.14% gross carry, not the finding; it also depends on the Wildcat queue paying.

---

## 5. What an unprivileged attacker can and cannot do

### Cannot

1. **Force a delinquency for free.** Depositing to get `wmt*` adds cash; queueing it makes the batch payable. Acquiring an existing position requires a secondary venue that does not exist.
2. **Mint shares from thin air.** `shares = balanceAfter * scaledReceived / scaledAfter` is exactly proportional; no rounding inflation (and the market's scale factor only increases).
3. **Redeem more than the vault's actual USDC.** `claimRequest` checks `underlying.balanceOf(vault) >= requestAmount`; live idle is $112.998. `excess()` is not cash.
4. **Profit from the face mark against existing holders.** Single-market, pro-rata shares; the attacker's claim is the same market claim.
5. **Exit after a partial batch.** `claimRequest` needs the full amount; `cancelRequest` reverts after queueing; `queueRequestsBatch` reverts `ActiveBatchExists` while the batch is unpaid.

### Can (but not profitably)

- **Trigger the freeze with a 200k exit.** A 3.8% holder can freeze all redemptions for the $73,620 shortfall. This is griefing/DoS with the attacker's own 200k at risk, not theft.
- **Mint at face while delinquent.** Proven: 2,499,999,999 `wmtUSDC` → 2,499,999,999 shares while `isDelinquent = true`. The shares are marked at face but cannot be paid; this is the accounting overstatement, not an extraction.
- **Buy the impaired token OTC at a discount** (off-chain): then the gain is `(recovery − price) × size`, capped by the vault's realizable cash. Today that cap is **$2,695,448.45** (USDC $126,379.56 + USDT $2,544,640.35 + WETH $24,428.54) and requires a pre-delinquency queue slot; with no venue, realized E-U is **$0**.

---

## 6. Fork PoC / verification

**Project:** `eva-markets/poc` (Foundry 1.8.5, solc 0.8.24), fork of Ethereum mainnet at block **26,241,741**.
**CI:** [run 39628846662](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39628846662) — **5/5 PASS**.

| Test | Result |
|---|---|
| `test_live_markets_current_and_vault_state` | all 3 `isDelinquent = false`; USDC/USDT `timeDelinquent = 0`; totalAssets $2,440,738.43 / $2,870,718.36 / 1.0182047 ETH; cash $126,379.56 / $2,544,640.35 / 9.7388 ETH; idle $112.998 |
| `test_depositFromMarket_mints_at_face` | 2,499,999,999 `wmtUSDC` → 2,499,999,999 shares; `previewRedeem` = 2,499,999,999 |
| `test_current_market_roundtrip_is_breakeven` | 2,499,999,999 in → 2,499,999,999 out (1 wei rounding loss); fair while current |
| `test_large_exit_partial_batch_freezes_vault` | 200k request → batch pays $126,379.56; `claimRequest` reverts; `isDelinquent = true` (`timeDelinquent` 86,401 s); vault idle $112.998; 1 unpaid batch; next queue reverts `ActiveBatchExists` |
| `test_delinquent_market_still_minted_at_face` | while delinquent, 2,499,999,999 `wmtUSDC` still mints 2,499,999,999 shares at face |

Gas: 0.85–1.37M per path.

---

## 7. Verdict and residual risk

**E-U = $0.00 (high confidence).** The `depositFromMarket` face mark is real and reproducible, but it is not a live unprivileged drain: all markets are current, the vault is a single-market pass-through, the only impaired-token venue is absent, and the live liquid balance is $113. The $5.31M is **H-O/S** — depositor claims on Wintermute's three Wildcat markets.

**Residual / latent:**

- **H-O/S — Wintermute credit:** $74.02M / $48.67M / 2,360.70 ETH of debt against $126k / $2.54M / 9.74 ETH of cash. A missed coupon or a large exit triggers delinquency; a default impairs the face-marked NAV by `(1 − recovery) × $5.31M`.
- **S — queue freeze:** a 200k exit (8.2% of evaUSDC) freezes all redemptions because partial batches are all-or-nothing and `ActiveBatchExists` blocks new queues. This is live today and is the most practical user harm.
- **P — upgrade/operator:** three `TransparentUpgradeableProxy`s with a shared ProxyAdmin owner; the operator EOA can `skim` excess and choose when to queue requests. Key compromise or a malicious upgrade takes the full $5.31M.
- **Monitor:** `isDelinquent`/`timeDelinquent` on all three markets; `getUnpaidBatchExpiries`; Wintermute coupon payments; any DEX listing of `wmtUSDC`/`wmtUSDT`/`wmtWETH` (a discount would re-arm the conditional).

---

## 8. Methodology, sources, caveats

**Reads:** `eth_call` at block 26,241,741 via an archive RPC; Etherscan V2 verified sources for `EvaVault` (`0xdc9f…`), `WildcatMarket`, `EvaStorage`; `getLogs`/`currentState` for the three markets; DexScreener, DefiLlama, and Curve's pool registry for venues; proxy admin slots (`0xb531…`) for the three proxies.

**Caveats:**
- USD values use $1.00 for USDC/USDT (DefiLlama marks $0.99948/$0.99920) and ETH $2,508.38 at 2026-10-21 15:48 UTC.
- The 200k forced-delinquency test impersonates the Curve pool (an existing 1.916M evaUSDC holder) to request redemption; the operator call is impersonated. This is a faithful state transition, not a live transaction.
- `wmt*` token "no DEX pair" is a point-in-time negative result across DexScreener, DefiLlama, and Curve; an unindexed Uniswap v4 pool cannot be ruled out.
- The `totalAssets`/`excess` figures are 1:1 virtual accounting, not a mark-to-market of the Wildcat debt; the true recovery in a default is unobservable.

**Files:** `eva-markets/analysis/state.json` (machine-readable live state), `eva-markets/poc/test/Eva.t.sol`, `eva-markets/ci-log.txt`.

*Prepared 2026-10-21 · ZH4 pass-3 · Eva Markets · read-only, fork-only.*
