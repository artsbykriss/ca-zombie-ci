# Plasma USD Vault (Veda BoringVault + LayerZero teller) — exit gate and cross-chain NAV

**Date:** 2026-10-19/20 · **Chains:** Plasma (9745) + Ethereum (1) mirror
**Status:** read-only; fork-verified only; **no mainnet transactions signed or sent**; public RPCs only.

---

## 1. TL;DR

| Question | Answer |
|---|---|
| Live external-unprivileged extraction (E-U) | **$0.00** |
| Confidence | **High** for the live gate; **medium** for the conditional market number |
| Is the pass-2 "2.24% stale NAV / $699k unaccounted" real? | **No — it is a cross-chain aggregation artifact.** The accountant rate **1.048796** equals the **global** NAV **1.048826** (0.0029% = ~7h of Aave interest since the last rate update). The Plasma-only NAV (1.07236) and Ethereum-only NAV (0.038419) are local views; the $699k is the Ethereum mirror shares' claim, exactly offset by the Plasma excess. |
| Is the Ethereum mirror "96.3% undercollateralized"? | **Locally yes, globally no.** The Ethereum vault holds $26,582 for 691,899 shares ($725,661 at the rate); the backing for those shares is on Plasma. The LZ bridge is open both ways and public, so the shares can move to the backing. If the bridge is disabled, **$699k is stuck** (S). |
| Is there a public exit? | **No direct redemption.** `bulkWithdraw` is solver-only (`canCall=false`; `UNAUTHORIZED` for a fresh caller); `vault.exit/enter/manage` are not public. Deposits and LZ `bridge` are public. Two tiny DEX pools exist at 15–28% discounts. |
| What is actually at risk? | **P:** the owner/keeper can update the rate (±0.5% per 6h), pause, set solvers and disable the bridge; a malicious rate update or write-off could shift the **$699k** buffer. **S:** $699k if the LZ bridge is disabled. **E-U-conditional:** ~**$2.25k** (market depth) if a public exit opens at 1.0488. |
| Holder claims (global) | **$31,880,043** (30,395,919.318 shares × 1.048826 global NAV). |

**Headline:** the vault is **solvent globally** (NAV 1.0488) and **solver-gated**; the pass-2's $699k "stale-NAV" opportunity is not unprivileged-extractable. The real issues are the exit gate, the Ethereum mirror's local liquidity mismatch, and the privileged rate/bridge controls.

---

## 2. Mechanism (deployed code)

### Contracts

| Contract | Address (same on both chains) | Code |
|---|---|---|
| Vault (BoringVault) | `0xd1074E0AE85610dDBA0147e29eBe0D8E5873a000` | 7,515 B, non-proxy; Ethereum runtime verified (`BoringVault`) |
| Teller (LayerZeroTeller) | `0x4E7d2186eB8B75fBDcA867761636637E05BaeF1E` | 19,266 B, non-proxy; Ethereum source verified (`LayerZeroTeller`) |
| Accountant | `0x737f2522d09E58a3Ea9dcCFDB127dD0dF5eB3F18` | 7,893 B; `getRate()` returns stored `exchangeRate` |
| RolesAuthority | `0xb381DE863dadFEA44738E7179f0d1Fc73b59e278` | governs teller/vault/router capabilities |

### Access model (verified source)

- `deposit(asset, amount, minMint)` — `requiresAuth` but the authority grants it to `PUBLIC` (`canCall(0x1111, teller, deposit) = true`). It mints shares at `accountant.getRateInQuoteSafe(asset)`.
- `bridge(uint96 shares, to, wildcard, feeToken, maxFee)` — also `PUBLIC`; it burns the caller's shares on the source (`vault.exit(address(0), …, msg.sender, shares)`) and sends an LZ message.
- `bulkWithdraw(asset, shares, minAssets, to)` — **solver-only**; `requiresAuth` + `canCall(0x1111, teller, bulkWithdraw) = false`. It computes `assetsOut = shares × accountant.getRateInQuoteSafe(asset) / 1e6` and calls `vault.exit(to, asset, assetsOut, msg.sender, shares)`.
- `vault.exit/enter/manage` — not public (`canCall = false`); only the teller/router can call them.
- `LayerZeroTeller._lzReceive` — mints shares on the destination via `vault.enter` after checking `idToChains[srcEid].allowMessagesFrom`.
- `accountant.getRate()` — returns the stored `exchangeRate` (1.048796); `updateExchangeRate(uint96)` is `requiresAuth` (`canCall(0x1111, accountant, updateExchangeRate) = false`). The rate is **keeper-set**, bounded by ±0.5% per update and a 6h minimum delay.
- `LayerZeroTeller.idToChains`: Plasma `30101 → (true, true, 200000)`; Ethereum `30383 → (true, true, 200000)`. The peer is the same teller address on the other chain.

### The pass-2 arithmetic, corrected

The pass-2 compared the accountant rate to the **Plasma-only** assets/shares:

```
Plasma-only NAV = (31,772,108.137257 aPlaUSDT0 + 81,353.017792 USDT0) / 29,704,020.248475
                = 31,853,461.155049 / 29,704,020.248475 = 1.072361
```

It did **not** include the 691,899.068960 shares on the Ethereum mirror. The global liability is the sum of both chains' supplies, and the global backing is the sum of both vaults' assets:

```
Global supply = 29,704,020.248475 + 691,899.068960 = 30,395,919.317435
Global assets = 31,853,461.155049 + 26,582.230118 = 31,880,043.385167
Global NAV    = 31,880,043.385167 / 30,395,919.317435 = 1.048826
Accountant    = 1.048796        (difference 0.0029% = 2.9 bps)
```

The 2.24% "gap" is exactly the Ethereum share of the global supply: `691,899.07 / 30,395,919.32 = 2.276%`. The $699k is the Ethereum shares' claim (`691,899.06896 × 1.048796 − 26,582.23 = $699,078.75`), and the Plasma vault holds exactly that excess (`31,853,461.16 − 29,704,020.248475 × 1.048796 = $699,078.75`). **It is not unaccounted yield.**

The rate was last updated at **1,792,428,047 = 2026-10-19 16:40:47 UTC**; the observation at 23:39 UTC is ~7h later. The 2.9 bps drift is ~$900 of Aave interest on the $31.77M aToken balance, exactly what a 3.77% APY over 7h produces. The rate is current, not stale.

---

## 3. Live state (read at named blocks)

Primary CI read: **Plasma 35,511,090**, **Ethereum 26,229,905** (2026-10-19 23:39 UTC). Local reads at 35,510,997 / 26,229,898 agree.

| Metric | Plasma | Ethereum mirror | Global |
|---|---:|---:|---:|
| Share supply (6 dp) | 29,704,020.248475 | 691,899.068960 | **30,395,919.317435** |
| aPlaUSDT0 | 31,772,108.137257 | — | — |
| USDT0 (idle) | 81,353.017792 | — | — |
| USDT | — | 26,581.695452 | — |
| USDC / USDS / DAI | — | 0.013440 / 0.248903 / 0.272324 | — |
| Assets (USD, 6 dp) | **31,853,461.16** | **26,582.23** | **31,880,043.39** |
| Local NAV (1e6) | **1.072361** | **0.038419** | **1.048826** |
| Accountant `getRate()` | **1.048796** | **1.048796** | — |

Other live state:
- Teller `isPaused = false`; `shareLockPeriod = 0`; `permissionedTransfers = false`.
- `assetData(USDT0)` on Plasma = `(allowDeposits=true, allowWithdraws=true, premium=0)`; `assetData(USDT)` on Ethereum = `(true, true, 0)`; USDC/DAI = `(false, false, 0)`.
- `accountant.accountantState`: `payoutAddress 0x68eC…8cFA`, `highwaterMark 1.048796`, `exchangeRate 1.048796`, `lastUpdateTimestamp 1,792,428,047`, `isPaused false`, `minimumUpdateDelay 21,600 s`, fees 0.
- The Ethereum mirror is **locally** undercollateralized: $26,582 of assets for $725,661 of claims (3.7% local coverage). The top holder [`0x3938A7D74f692A8A662Fb17d6081e3a494de22e6`](https://etherscan.io/address/0x3938A7D74f692A8A662Fb17d6081e3a494de22e6) holds **500,000 shares (72.3%)**; it must bridge to Plasma to reach the backing.

### Exit gate probes (CI + local, `eth_call`)

| Call from `0x1111…` | Result |
|---|---|
| `authority.canCall(0x1111, teller, deposit)` | **true** |
| `authority.canCall(0x1111, teller, bridge)` | **true** |
| `authority.canCall(0x1111, teller, bulkWithdraw)` | **false** |
| `authority.canCall(0x1111, vault, exit/enter/manage)` | **false / false / false** |
| `bulkWithdraw(USDT0, 1e6, 0, 0x1111…)` | **`UNAUTHORIZED`** |
| `deposit(USDT0, 1e6, 0)` | **`TRANSFER_FROM_FAILED`** (auth passed; no balance/allowance) |
| `bridge(1e6, 0x1111…, eid 30101, USDT0, 0)` | **arithmetic underflow** (auth passed; burns the caller's zero shares) |
| `getRateInQuoteSafe(USDT0)` | **1.048796** (same on Ethereum USDT) |

### Exit / bridge activity (not dead)

- **Plasma `BulkWithdraw`:** 122 events in blocks 25,000,000–35,510,052, totalling **4,221,663.06 shares**. The latest (block **35,494,152**) burned **955,031.43424 shares ≈ $1.001M** at 1.0488 via a solver/router; this exactly explains the `totalSharesLastUpdate` (30,659,051.68) minus the current Plasma supply (29,704,020.25).
- **Ethereum `BulkWithdraw`:** 139 events (621,177 shares), mostly historical USDS/DAI-era redemptions (assets `0xdC03…` USDS and `0x6B17…` DAI), not current USDT.
- **Ethereum teller last 300 txs:** 201 `bridge`, 93 `depositAndBridge`, 6 `deposit`, **0 direct `bulkWithdraw`** — the bridge is the active route.
- **Ethereum `MessageSent`:** 5,232 events in blocks 16M–26.23M (2,269,864 shares), so the LZ bridge is heavily used.
- **Plasma teller last 5,000 txs:** all `deposit` — public deposits are active.

This is a **solver-mediated exit**, not a dead protocol. The solvers are privileged role holders; the router at [`0x111c973C84b6f400A8B6b74675079A9ddA41F5dc`](https://plasmascan.to/address/0x111c973C84b6f400A8B6b74675079A9ddA41F5dc) has `canCall(0x1111, router, 0x5ff8a71f) = false`.

### Secondary market (found; tiny)

| Pool | Chain / DEX | Reserve | PlasmaUSD price | Discount to 1.048796 | 24h volume |
|---|---|---:|---:|---:|---:|
| USDC / PlasmaUSD 9.9% | Ethereum Uniswap V4, id `0x3f1cae…eef1` | **$45,506** | **$0.886224** | **15.5%** | $0 |
| USDT0 / PlasmaUSD 10% | Plasma Balancer V3, `0x681aa4…99f3` | **$4,097** | **$0.752438** | **28.3%** | $0 |

The pass-2 said "no market"; there are two, but their combined depth is **$49,603** and both have zero 24h volume. They are discounted exits, not a $699k liquidity pool.

---

## 4. What an attacker can / cannot do

**Cannot:**
1. Redeem shares for assets directly — `bulkWithdraw` is solver-only; `vault.exit/manage` are not public (fork tests 1–2).
2. Bypass the gate through the router — the router's batch function `0x5ff8a71f` is also `canCall = false` for a fresh address.
3. Steal another holder's shares — `bulkWithdraw` burns `msg.sender`'s shares; `vault.exit` is teller-only, and the teller always passes `msg.sender` or `address(0)` as `from`.
4. Upgrade the vault/teller — both are non-proxy (runtime code matches; no EIP-1967 implementation).
5. Exploit the "2.24% discount" through the teller — the teller pays **1.048796**, the same rate at which it mints. The Plasma-only 1.072361 is not a redemption rate.

**Can:**
- Deposit at 1.048796 (public). This is **fair vs the global NAV** (1.048826, 0.0029% below); it is not a 2.24% discount.
- Bridge shares (public, if they own them) — burn on source, mint on destination; the LZ fee is paid in native/LZ token.
- Buy/sell in the two tiny pools at a 15–28% discount. Buying PlasmaUSD at 0.7524 or 0.8862 and redeeming at 1.0488 would be profitable **only if a public exit opens**; the pool depth caps the profit at ~$2.25k gross.

**Conditional E-U (market-implied, if a public exit at 1.0488 opens):**

| Pool | PlasmaUSD in pool | Buy cost incl. fee | Redeem at 1.0488 | Gross profit |
|---|---:|---:|---:|---:|
| ETH V4 (9.9% fee) | 25,674 shares | $25,253 | $26,927 | **$1,674** |
| Plasma Balancer (10% fee) | 2,723 shares | $2,276 | $2,855 | **$579** |
| **Total** | | | | **≈$2,253** |

This is **not** $699k. The $699k would require buying the Ethereum shares at the **local** NAV (0.0384), but the actual on-chain market price is **0.8862** — the market already prices the bridge/backing. The top 500k-share holder is not for sale on-chain; an OTC purchase at 0.886 and redemption at 1.0488 would yield ~$94k, but that is a bilateral deal, not an unprivileged on-chain path.

---

## 5. Categories and quantification

| Category | USD | Basis |
|---|---:|---|
| **E-U (live)** | **$0.00** | No public redemption; `bulkWithdraw` `UNAUTHORIZED`; `vault.exit/manage` not public; router gated. Confidence **high**. |
| **E-U-conditional** | **~$2,253** | Only if a public exit at 1.0488 opens; capped by the two DEX pools' depth ($49.6k) and 9.9–10% fees. Confidence **low-medium**. |
| **H-O (holder claims)** | **$31,880,043** | Global claims at 1.048826; recoverable via solver/bridge, or at a 15–28% discount in the tiny pools. **Not self-service** in the strict sense. |
| **P (privileged)** | **$699,079** | The excess buffer can be released to Plasma holders by a rate update to the Plasma-only NAV (1.072361), or shifted the other way; the owner/keeper also controls pausing, solvers and the LZ bridge. Confidence **medium** (the rate is currently correct; this is a control risk, not a live exploit). |
| **S (stuck, conditional)** | **$699,079** | If the LZ bridge is disabled and no solver redeems, the Ethereum mirror's 691,899 shares are backed by only $26,582 locally. The 500k-share top holder is the most exposed. Confidence **medium**. |

**Why the pass-2 $699k is not E-U:** (i) the accountant rate is the global NAV, so there is no 2.24% mint/redeem discount; (ii) the only way to realize the buffer is a privileged rate update/write-off, or buying the Ethereum shares below the global NAV — the on-chain market prices them at 0.8862, not 0.0384; (iii) the exit is solver-gated. The $699k is a **cross-chain collateral buffer**, not unprivileged yield.

---

## 6. PoC / fork verification

**Project:** `plasma-usd-vault/poc/` (Foundry, vendored forge-std). **2/2 tests PASS** on GitHub Actions.

| Test | Result | What it proves |
|---|---|---|
| `test_plasma_rate_and_gate` | PASS | rate 1.048796; `getRateInQuoteSafe(USDT0)` = rate; Plasma local NAV 1.072361; `bulkWithdraw` gate false; `bulkWithdraw` reverts `UNAUTHORIZED`; `deposit` passes auth (`TRANSFER_FROM_FAILED`); `bridge` passes auth (underflow); LZ peer `(true,true,200000)`. |
| `test_global_nav_matches_rate` | PASS | Plasma supply/assets + Ethereum supply/assets → global NAV 1.048826; rate 1.048796; within 0.5% (actual 2.9 bps); Ethereum local NAV 0.038419; `bulkWithdraw` gate false on ETH; LZ peer `(true,true)`. |

- CI run: **https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39342854222** (`conclusion: success`; artifact `result-plasma-usd-vault`).
- Live state capture: `ci-out/state.json` (artifact), Plasma block **35,511,090**, Ethereum block **26,229,905**.
- Gas: gate test 325k; global NAV test 142k. The `bulkWithdraw` call is cheap but reverts before any transfer.

---

## 7. Verdict, residual/latent risk, blockers

**Verdict:** **E-U $0.00 (high confidence).** The vault is globally solvent at 1.0488; the pass-2 "2.24% stale NAV / $699k unaccounted" is a cross-chain aggregation artifact (the Ethereum mirror's 2.276% share of global supply). The exit is solver-gated; a fresh attacker cannot redeem. The only market-implied conditional is ~$2.25k in two tiny pools if a public exit opens.

**Residual/latent:**
- **P — rate control:** the owner/keeper can update the exchange rate by up to ±0.5% per 6h. A malicious or mistaken update toward the Plasma-only 1.072361 would shift the $699k buffer from the Ethereum mirror to Plasma holders (and vice versa). The current rate is correct.
- **P — solvers/bridge:** the owner/authority can add/remove solvers and disable the LZ bridge. The router `0x111c…` and teller roles are privileged.
- **S — bridge dependency:** if the LZ bridge is disabled, the Ethereum shares (691,899; $725.7k at rate) are locally backed by $26.6k; $699k is stuck. The top holder (500k shares) is the most exposed.
- **Local liquidity:** the Ethereum vault can pay only ~25,344 shares ($26.6k) at the rate; the rest must bridge. This is a queue, not a global insolvency.
- **Market discount:** the two pools price PlasmaUSD at 0.75–0.89, a 15–28% discount, reflecting the exit gate. Holders who need liquidity pay it.

**Re-arm triggers (when this verdict could change):**
1. A public `bulkWithdraw` capability appears (authority `PublicCapabilityUpdated`/`UserRoleUpdated`), or a public router exposes a batch redeem.
2. A DEX/lending market with **>$100k depth** accepts PlasmaUSD at a discount, or a lending market values it at 1.0488 while the DEX price is lower.
3. The accountant `exchangeRate` diverges from the global NAV by >0.5% (current 2.9 bps), especially an update toward 1.072361.
4. The LZ bridge is disabled (`idToChains.allowMessagesTo = false`) or the peer is changed.
5. A large Ethereum holder (e.g., the 500k-share `0x3938…`) bridges and attempts redemption; watch `MessageSent`/`BulkWithdraw`.
6. The vault/teller is upgraded (currently non-proxy) or a new vault version appears.

---

## 8. Methodology, sources, caveats, files

**Method:** DefiLlama/`mini-chains.md` lead → Sourcify verified `LayerZeroTeller` + `BoringVault`; live `eth_call`/`eth_getLogs` on Plasma and Ethereum at named blocks; exact asset/supply aggregation across both chains; accountant state + last update; `canCall` capability probes; 5,000-tx teller history; 122/139 `BulkWithdraw` events; GeckoTerminal pool discovery + reserve/price; Foundry dual-chain fork PoC.

**Sources:** Sourcify `1/0x4E7d…F1E` (`LayerZeroTeller`), `1/0xd107…a000` (`BoringVault`); Etherscan V2 (chain 1/9745) for tx/logs; Public RPCs `https://rpc.plasma.to`, `https://ethereum-rpc.publicnode.com`; GeckoTerminal `plasma/0x681a…99f3`, `eth/0x3f1c…eef1`; DefiLlama Veda/Plasma yields.

**Caveats:**
- The aToken balance is rebasing; the global NAV drifts ~0.003% per 6–7h between rate updates. The 2.9 bps observed is interest, not a leak.
- The rate is keeper-set (`updateExchangeRate(uint96)`), not computed on-chain; the "global NAV" is an independent balance-sheet check, not the contract's own formula.
- The Ethereum `USDS/DAI` dust and the vault's self-held 8.92556 shares are included/ignored as noted; they are immaterial ($0.5).
- The DEX pool prices are spot prices with **zero 24h volume**; the $2.25k conditional is a depth/fee bound, not a guaranteed profit.
- The Ethereum top-holder balance is from Blockscout at block 26,229,xxx; it may change.
- No mainnet transaction was sent; all "attacker" calls are `eth_call`/fork simulations.

**Files:**
- `README.md` (this file), `summary.json`
- `analysis/src/eth_teller_src_base_Roles_CrossChain_Bridges_LayerZero_LayerZeroTeller.sol` — verified teller source
- `analysis/src/eth_teller_src_base_Roles_TellerWithMultiAssetSupport.sol` — deposit/bulkWithdraw/gating
- `analysis/src/eth_teller_src_base_Roles_CrossChain_CrossChainTellerWithGenericBridge.sol` — bridge burn/mint
- `analysis/teller_events.json` — BulkWithdraw/BulkDeposit/MessageSent/MessageReceived events
- `analysis/scan_events_etherscan.py` — Etherscan V2 event scan (BulkWithdraw/BulkDeposit/MessageSent/MessageReceived)
- `poc/test/PlasmaVault.t.sol` — 2 dual-chain fork tests
- `ci/run.sh`, `ci/compute.py`, `ci-out/state.json` — live state capture
- `ci-log.txt`, `ci-artifacts/` — CI log and artifact
