# L2 close-out — RELATED rows: **Serum Swap** (Solana) + **Cega V2** (Ethereum, Arbitrum)

**Date:** 2026-10-15 · **Status:** read-only; no mainnet transactions; PoCs are fork/simulation-only.
**Scope:** the two remaining `RELATED` rows of `ci/L2-WATCHLIST.json` that prior work did not cover:
`serum-swap` (H-22 audited Serum v3 + OpenBook v1, **not** the Swap AMM product) and `cega-v2`
(H-12 audited Cega V1; V2 explicitly out of scope).

---

## 1. TL;DR

| target | chain(s) | live custody (verified) | **E-U now (fresh attacker)** | why closed/open | latent risk |
|---|---|---|---|---|---|
| **Serum Swap** (SPL token-swap program `SwaPpA9…`) | Solana | **$204,350.99** realizable / $259,285.47 at DefiLlama prices (292 pools, slots ≈457,162,187–457,166,000) | **$0.00** bug-based (high) · **$4.22** residual stale-price arb (med-high) | every vault payout needs the caller's own LP burn (sim-proven revert); vault authority = PDA([pool]) verified 292/292; deployed 2021-04 build's single-sided withdraw **over**-charges (sim-proven); no admin/sweep instruction exists; 0 Stable-curve pools → OtterSec stable rounding bug has **no live target** | upgrade authority `DpWjxjJE2SC…` is **not revoked** (P over the whole $204k); $140,698.78 of LP value sits in the program-owner fee account `HfoTxFR1…` (key-gated, P) |
| **Cega V2** (Treasury proxies + CegaEntry diamond) | Ethereum + Arbitrum | **$109,234.20** (ETH $32,472.68 + ARB $76,761.52) | **$0.00** (high) | Treasury `withdraw` is `onlyCegaEntryOrRedepositManager`; `RedepositManager.redeposit` is `onlyCegaEntry`; user withdrawals bounded by own share balance; queue processing / settlement / fees `onlyTraderAdmin`; settlement requires the Trade Winner NFT; AddressManager setters `onlyCegaAdmin`; **all fork-proven reverts** | proxy owners are **2-of-6 Safes** (upgrade = P); `CEGA_ADMIN`/`TRADER_ADMIN` = EOAs + Safes (key risk, P); funds are residual custody (vaults zombie, queues empty) |

**Total live extractable by an external unprivileged attacker right now: ≈ $4.22** (Serum Swap stale-price
arbitrage at realizable prices; **$0.00 bug-based**). Confidence: **high** for both $0 verdicts, **medium-high**
for the $4.22 residual. Upper bounds if one accepts DefiLlama prices for unmarketable Sollet tokens: $15,186.78
(and $13,414.58 of that requires *already holding* the dead token — not a fresh attacker).

---

## 2. Serum Swap (Solana) — SPL token-swap AMM

### 2.1 What the product is (vs. H-22's Serum v3/OpenBook)
DefiLlama's `serum-swap` adapter tracks the Solana program **`SwaPpA9LAaLfeLi3a68M4DjnLqgtticKg6CnyNwgAC8`**
(the SPL token-swap AMM). H-22 audited the Serum **v3 order book** (`9xQeWvG…`) and OpenBook v1 — a different
program. This dossier covers the AMM program itself.

### 2.2 Deployed reality (all verified on-chain)
| fact | value | evidence |
|---|---|---|
| program | `SwaPpA9LAaLfeLi3a68M4DjnLqgtticKg6CnyNwgAC8`, executable, owner `BPFLoaderUpgradeab1e…` | `getAccountInfo` @ slot 457,162,187 |
| programdata | `FV9WWFWYzWHDpAc8oxiFKV1LmFUyWw7HGdo4GK19MiZW`, 619,629 B; ELF sha256 `f86b866c8717f4a052bd61b36bfd1dee203d32673a0bb5cb1fbd8b99f8e65719` | `getAccountInfo` @ slot 457,162,688 |
| last deploy | slot **73,737,036** = **2021-04-15 04:22:07 UTC** | `getBlock` |
| upgrade authority | **`DpWjxjJE2SCsraeZqKqLtvdPjiaABmcmNAZSP9iUaGrn`** (Option tag=1 at byte 12, key at 13..45; signed the last upgrade) — *correction to an earlier off-by-one read of `7orsQE9o…`* | programdata header + `getTransaction(4iDNVHQK…)` |
| build fingerprint | SPL token-swap @ commit **`9281b6e82899`** (2021-04-14, crate 2.1.0) built with `--features production` | layout match, source-path strings, the production-only literal `HfoTxFR1…`, date |
| account census | **340** accounts: 339×324 B + 1×323 B; **292 initialized pools** (262 ConstantProduct + 30 ConstantPrice), 48 uninitialized; **0 Stable, 0 Offset** | `getProgramAccounts` (dataSize/dataSlice) |
| authority PDA | `vault_a.owner == vault_b.owner == PDA([pool], stored nonce)`, `pool_mint.mint_authority == PDA` for **292/292** | full decode, `pools-raw.json` |
| fee accounts | all 292 `pool_fee_account`s owned by `HfoTxFR1Tm6kGmWgYWD6J7YHVy1UwqSULUGVLXkJqaKN` | decode |
| fee configs | 286× (25/10000, 5/10000, 0/0, 20/100), 6× (0/10000, 5/10000, 0/0, 20/100) — no abnormal values anywhere | decode |

### 2.3 Live value
* **Σ vault value: $259,285.47** (DefiLlama prices) / **$204,350.99** (live-DEX “realizable” prices with a
  ≥$1k-liquidity floor; unmarketable Sollet tokens → $0).
* Two SOL/USDC(SDT) pools (`AmHUjHK…`, `HChRYaZ…`) hold **$172.5k ≈ 84 %** of realizable value.
* LP value attributable to the program-owner fee account: **$140,698.78 = 68.9 %** of realizable value.
* Remaining LP holders: **$63,652.21 = 31.1 %**.
* Dust traps: 11 zero-supply pools hold $0.05; 48 uninitialized accounts hold 0.151 SOL rent (S).

### 2.4 Gates — why a fresh attacker gets $0 (bug-based)
1. **Withdraw paths** (`WithdrawAllTokenTypes`, `WithdrawSingleTokenTypeExactAmountOut`): the attacker must
   burn their own LP tokens; vault authority is the pool PDA. Chain-native **simulation** with an empty LP
   account fails at the token program burn (`InstructionError [3, Custom(1)]`). No LP ⇒ no payout.
2. **Version probe (deployed math)**: a read-only `simulateTransaction` (sigVerify=false; a third-party LP
   account only *marked* signer inside the simulated message — nothing signed/sent) shows the observed LP burn
   **318,221,048,603** vs the deployed pre-#1794 formula prediction **318,221,048,611** (rel. err 2.5e-11) and
   the post-fix formula **310,153,567,464** (2.54 % off) ⇒ the live program is the 2021-04 build. That build's
   single-sided withdrawal charges the withdrawer **more** LP than the later “fair” formula — pool-favouring,
   **not** an extraction vector.
3. **Constant-product swap math** uses `checked_ceil_div` → rounds in the pool's favour.
4. **Stable-curve rounding bug (OtterSec, Apr-2022, patch PR #2942)** is *present* in the deployed build but
   **there are zero Stable-curve pools** (census above), so it has no live target.
5. **No admin/sweep/pause instruction** exists in the deployed instruction set (tags 0–5 only); fee accounts
   are ordinary token accounts owned by `HfoTxFR1…` (their LP can be redeemed only by that key).
6. **Host-fee path** (caller-supplied host-fee account receives 20 % of the owner fee in LP) nets ≤ 1 bp of
   input per swap against a 25 bp trade fee (0 bp in 6 pools) — economically dead after slippage/rounding.

### 2.5 Arbitrage reality (not a bug; quantified for completeness)
Anyone can trade at curve prices; pools are live and aggregator-routed (Jupiter-routed swaps decoded today).
* **$15,186.78** = Σ optimal arb profit if every token is valued at DefiLlama prices (fee-aware, exact
  deployed integer math; `ci-out/serum-verify.json`).
* **$4.22** = what survives when the input token must be bought at its *live* DEX price and tokens without an
  observable market are valued at $0. The $15k is concentrated in pools whose other side is an unmarketable
  Sollet token (`soUSDT`, `soYFI`, `soLINK`) — DefiLlama prices them at underlying value; the real market for
  `soUSDT` is ≈$0.27 (Jupiter route via Orca/Flux), which matches the pools’ own prices (376 soUSDT/SOL vs
  market 377) ⇒ no real spread.
* **$13,414.58** = the valuable side of pools whose other side is unmarketable — extractable only by someone
  who *already holds* the dead token (a normal AMM sale), not by a fresh attacker.

### 2.6 Split
| category | USD | basis |
|---|---|---|
| **E-U (bug)** | **$0.00** | gates + simulations above |
| E-U (stale-price arb) | **$4.22** | realizable-price arb, 4 ConstantPrice pools |
| H-O | $63,652.21 | non-fee-account LP holders (LP redemption is self-service) |
| P | $140,698.78 | fee-account LP (key `HfoTxFR1…`) + upgrade authority `DpWjxjJE2SC…` |
| S | $15.60 | zero-supply dust + uninitialized rent |

---

## 3. Cega V2 (Ethereum + Arbitrum) — Treasury + CegaEntry diamond

### 3.1 Target resolution (the watchlist row is the DefiLlama `cega-v2` listing)
`cega-v2` is **not** the CEGA_STATE/LOV/FCN product system (that is the older EVM deployment used by the
`cega-v1` listing). The `cega-v2` adapter (recovered from the adapter repo history, 2024-12) tracks two
custody contracts:

| chain | proxy (EIP173ProxyWithReceive) | implementation | proxy owner (upgrade authority) |
|---|---|---|---|
| Ethereum | `0xA8AB795731fbBFDd1Fbc57ca11e6f722e7783642` | `0x9f1876e83b489c2e027859ecf660157a7b34cefe` (**Treasury**, solc 0.8.24, verified) | `0xeA3d63A3A514C4BeD5bF2c61224EF561f0355F53` = **2-of-6 Safe** |
| Arbitrum | `0x475C4AF369B28997B25bd756eF92797AD3F69593` | `0xf57573a1770bfd14f3985ee157e0b416069fd37e` (same source) | `0x2315f08cf01cC4eBF324ee928f64527E689A2B4c` = **2-of-N Safe** |

### 3.2 Treasury — the entire value-movement surface (67 lines of Solidity)
```solidity
function withdraw(asset, receiver, amount, trustedReceiver) external nonReentrant
    onlyCegaEntryOrRedepositManager   // msg.sender == addressManager.getCegaEntry() || getRedepositManager()
function withdrawStuckAssets(asset, receiver) external nonReentrant  // only stuckAssets[asset][msg.sender]
receive() external payable {}          // inbound only; no approvals are ever granted
```
Verified live wiring (both chains): AddressManager `0x1DdF7C4C…` (ETH) / `0x25b7A20B…` (ARB) →
CegaEntry `0x7a67D5Eb…` / `0xFD62eEbA…`, RedepositManager `0xF8a62c2e…` / `0x45914CfB…`,
ACLManager `0x954939B7…` / `0xe0D27910…`, plus CegaOracle / CegaFeeReceiver / TradeWinnerNFT.

### 3.3 Live custody (fork-verified, ETH block 26,197,102)
| asset | Ethereum | Arbitrum |
|---|---|---|
| native | 2.762715809590197196 ETH | 3.774118921846415395 ETH |
| USDC | 12,510.400436 | 65,005.198188 |
| USDT | 12,166.977439 | 2,675.711476 |
| wstETH | 0.306016666760146198 | (per adapter) |
| WBTC | 0.00312642 | (per adapter) |
| DAI / USDe / sUSDe | per DL adapter | per DL adapter |
| **DefiLlama total** | **$32,472.68** | **$76,761.52** |

### 3.4 The value-moving graph (all sources verified on Etherscan; 21 live facets per chain)
* `RedepositManager.redeposit(treasury, productId, asset, amount, receiver)` → `onlyCegaEntry`
  (`msg.sender == immutable cegaEntry`).
* User flows on the CegaEntry diamond: `addToWithdrawalQueue` / `fcn…` / `sfn…` / `dcs…`,
  `withdrawOrAddToWithdrawalQueue`, `withdrawInstantly` — **permissionless but bounded by
  `ICegaVault(vault).balanceOf(msg.sender) >= sharesAmount`**; payouts go to the recorded depositor.
* Queue processing (`processWithdrawalQueue`, `processDepositQueue` + bulk variants) → `onlyTraderAdmin`.
* Settlement (`sfnSettleVault`, `fcnSettleVault`, `dcsSettleVault`) → no role modifier **but** requires
  `msg.sender == ownerOf(vault.auctionWinnerTokenId)` (Trade Winner NFT) and pays **into** the Treasury.
* Fee collection (`collectVaultFees`) → `onlyTraderAdmin`; pays `addressManager.getCegaFeeReceiver()`.
* Offramp (`fillOrder`): maker-signed EIP-712 orders; **0 `OrderFilled` events ever** on both chains.
* Pendle (`claimPendleYield`): needs an off-chain Cega signer signature per (user, amount, chainId).
* AddressManager setters + CegaEntry `diamondCut` (owner = AddressManager) → `onlyCegaAdmin`.
* ACLManager (OZ AccessControl): `CEGA_ADMIN` = 2-of-6 Safe + EOA `0x2ca8b500…`; `TRADER_ADMIN` = 6 EOAs;
  `OPERATOR_ADMIN` = EOA + Safe; `SERVICE_ADMIN` = 1 EOA. All role holders are EOAs/Safes (P, key risk).

### 3.5 Vaults / positions (census: 89 ETH + 92 ARB vaults from `VaultCreated` events)
* Vault share tokens are 18-dp ERC-20s. Census (`ci-out/cega-vaults.json`): **89 ETH vaults — 83 Zombie,
  4 Traded, 1 FeesCollected, 1 Settled; 40 with nonzero share supply. 92 ARB vaults — 88 Zombie,
  3 DepositsClosed, 1 Traded; 63 with nonzero share supply.** Aggregate book `totalAssets` is dust-level
  (Σ 5.10e17 raw ETH-side / 1.60e18 ARB-side; e.g. dcsUSDC `0xf173Aee4…`: totalAssets 7.04e16, supply 2.06e20;
  dcsDAI `0x97C74ecA…`: 2.88e16 / 9.0e19).
* **Withdrawal queues are empty** on sampled vaults; **deposit queues**: 3 products hold pending deposits of
  **expired Pendle YT-weETH** tokens (1.8 + 1.1 YT on ETH products 83/84; 0.001 + 2.5 YT on ARB product 81) —
  recoverable self-service by their depositors (`removeFromDepositQueue` refunds `params.depositor`), worth ≈ $0.
* ⇒ the Treasury's $109,234.20 is **residual custody**: no live user-claimable queue exists; only
  trader/admin-gated CegaEntry paths (and the 2-of-6 Safe upgrade) can move it.

### 3.6 Fork proof (PoC, all PASS)
`poc/test/CegaV2Treasury.t.sol` (Foundry, live forks, read-only):
* `test_eth_live_state_and_gates` — balances; `owner()` = Safe; AM wiring; fresh-EOA `withdraw` **reverts**;
  `withdrawStuckAssets` moves nothing; a *contract* attacker also reverts; **0 allowances** to 1inch/0x/Uni routers.
* `test_arb_live_state_and_gates` — same on Arbitrum.
* `test_eth_entry_and_redeposit_gates` — `addToWithdrawalQueue` with 0 shares reverts;
  `RedepositManager.redeposit` reverts (onlyCegaEntry); `fcnProcessWithdrawalQueue` reverts (onlyTraderAdmin);
  `sfnSettleVault` reverts for a fresh caller; attacker gains nothing.

### 3.7 Split
| category | USD | basis |
|---|---|---|
| **E-U** | **$0.00** | all paths gated (source + roles + fork tests) |
| H-O | $0 today | no live user-claimable queues; vault claims are zombie/admin-conditional (dust book values) |
| P | **$109,234.20** | residual Treasury custody — only trader/admin-gated paths + 2-of-6 Safe upgrade can move it |
| S | $0.00 | none proven |

---

## 4. Total

| target | E-U (bug) | E-U (arb) | H-O | P | S | live custody |
|---|---|---|---|---|---|---|
| Serum Swap | $0.00 | $4.22 | $63,652.21 | $140,698.78 | $15.60 | $204,350.99 realizable |
| Cega V2 | $0.00 | — | $0.00 | $109,234.20 | $0.00 | $109,234.20 |
| **total** | **$0.00** | **$4.22** | **$63,652.21** | **$249,932.98** | **$15.60** | **$313,585.19** |

**Headline: an external unprivileged attacker can extract ≈ $4.22 live** (Serum Swap stale-price arbitrage,
medium-high confidence); **$0.00 from any code-level flaw** (high confidence, both targets).

---

## 5. PoC / verification / CI

* **CI run:** https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38717020995
  (`ci/run.sh` = Solana census/arb re-verification + Cega vault census; `forge test` = 3/3 PASS).
* Local fork tests: `poc/test/CegaV2Treasury.t.sol` — **3/3 PASS** (Ethereum + Arbitrum live forks).
* Chain-native Solana simulations (no signing, no sending): `analysis/serum-swap/simulations.md`,
  `sim-results.json`, `sim-version-probe-analysis.json`.
* Independent CI re-verification (mine): `ci-out/serum-verify.json` — census (339×324 B, 292 initialized,
  curve histogram {0:309, 1:30}), fee scan, per-pool reserves/decimals/USD, ConstantPrice + CP arb recomputation.
* Cega vault census: `ci-out/cega-vaults.json` (89 ETH + 92 ARB vaults, supplies, book assets, statuses).

## 6. Blockers, caveats, residual/latent risk
* **Serum Swap latent (P):** the program is upgradeable by `DpWjxjJE2SCsraeZqKqLtvdPjiaABmcmNAZSP9iUaGrn`
  (live, not revoked) — the entire $204k could be taken by that key (or by a key compromise). $140,698.78 of
  LP value is already key-gated to `HfoTxFR1…`.
* **Serum Swap arb uncertainty:** the $4.22 assumes the mispriced ConstantPrice pools can be drained with
  market-bought inputs; the $15.2k DefiLlama-price figure is **not** realizable (soUSDT real price ≈$0.27,
  soYFI/soLINK unmarketable). The $13.4k figure requires holding dead Sollet tokens.
* **Cega V2 latent (P):** 2-of-6 Safes (upgrade) + 6 trader EOAs + a CEGA_ADMIN EOA. The protocol is not
  paused; the diamond's facet set can be replaced by `CEGA_ADMIN` (via the AddressManager). Vaults are
  zombies; the residual $109k has no user-claimable path today.
* **Method limits:** public-RPC rate limits forced conservative sampling in the vault census (40/89 ETH
  vaults with nonzero supply verified; ARB partially). No private keys, no mainnet writes, no CI secrets.

## 7. Files index
```
l2-related/
├── README.md                     ← this file
├── summary.json                  ← machine-readable per-target summary
├── analysis/serum-swap/          ← child dossier: state-summary.md, gates.md, simulations.md, pools.json,
│                                   pools-raw.json, raw-program-accounts.json, sim-*.json, jup-prices.json,
│                                   realizable-arb.json, arb-cross.json, pool-activity.json, summary.json
├── analysis/cega-v2/             ← src/ (Treasury, AddressManager, CegaEntry, RedepositManager, ACLManager),
│                                   facets-src/ + facets-extracted/ (42 current facets), current-facets-*.json,
│                                   vaults-{1,42161}.json, state-onchain.json, diamondcut logs, facets.json
├── ci/solana_verify.py, ci/cega_vaults.py, ci/cega_vaults_pass.py, ci/run.sh
├── ci-out/                       ← serum-verify.json, cega-vaults.json, logs
└── poc/                          ← Foundry: CegaV2Treasury.t.sol (3 tests), vendored forge-std
```
