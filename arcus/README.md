# Z3-H12 — Arcus Perps (Robinhood Chain, 4663): unverified pToken NAV vaults — live extractable value

**Date:** 2026-10-16 · **Chain:** Robinhood Chain (chain id 4663) · **Status:** read-only; PoC fork-verified only; no mainnet transactions
**Finding (as briefed):** factory proxy `0x9c3663FA9ab976E67B42939486EC4966Cb41a0BB` (109-byte proxy → impl `0x58bdc1d3…`, unverified, no ERC-1967 admin slot) · pToken BTC-3x `0x4472C69d299382F8847ebCE4FC6Ed8e295510E3e` (beacon proxy → impl `0x1815a37b…`, unverified) · DL TVL **$57.9M** · on-chain sample `totalAssets` 97,431,825,945 (6 dp) / `totalSupply` 553.14e18.

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why closed / open | Latent risk |
|---|---|---|---|
| pToken BTC-3x `0x4472C6…` (+16 sibling pTokens, ~**$717.3k–$723.6k** on-chain NAV) | **$0** | NAV (`totalAssets`) is a **signer-signed, manager-pushed stored value** (EIP-712 domain `PerpsVaultNavOracle`, factory-bound). Deposits/redeems are priced at a **fresh** NAV computed by the operator at fulfill (verified: NAV tracks 3×BTC with median implied leverage **3.006**, n=87 intervals; NAV refreshes at every fulfill). Price = f(stored NAV, totalSupply) only → USDG donations cannot move it. Claims are single-use (replay reverts `0x6565c4ec`). **Deposits are quota-gated per (token, account)** — a per-controller asset/share quota must be granted by a privileged role; a fresh address cannot open a deposit request (fork-verified), and today only $100 of quota is open anywhere. Redeems are open to any share holder but pay the operator-priced NAV. | NAV-signer (single EOA) or manager-EOA key loss = P-class drain; quota-grant roles (incl. deployer EOA `0x38d0eaba…` still holding roleB); operator NAV lag > ~0.5% (fees) re-arms stale-NAV arb |
| Factory `0x9c3663FA…` (UUPS) | **$0** | All NAV/config/admin setters revert for non-role callers; `pTokenAt/pTokenCount` read-only. No ETH/USDG held. | UUPS upgrade authority (Safe 2-of-3) = P-class |
| Beacon `0x33846348…` (Ownable UpgradeableBeacon) | **$0** | `upgradeTo` onlyOwner = Gnosis Safe 2-of-3 `0x81B80499…`; all 17 pTokens share the impl. | impl swap = P-class (all pTokens at once) |
| Bridge vault `0xD42c46c7…` (minimal proxy) | **$0** | 221-byte EIP-1967 proxy; USDG balance 0; only called by pTokens during manager-bridged flows. | unverified impl; holds no value today |

**Total live extractable now: $0 (high confidence).** The $57.9M DefiLlama figure is the **Arcus perps exchange** TVL (collateral/positions on the Arcus DEX), *not* value custody inside these vault contracts: the 17 pTokens' on-chain NAV sums to **~$717.5k–$723.6k** (block-dependent; $723,606.49 at block 89,675,792, $717,518.73 at block 89,711,278), and their own USDG working balances are far smaller (BTC-3x holds $25,064.52).

---

## 2. What the contracts are (mechanism, in exact terms)

Arcus (built by the dYdX team with Robinhood Crypto; DefiLlama id `parent#arcus`) runs a perp DEX on Robinhood Chain. **pTokens** are transferable ERC-20s representing a pro-rata interest in an underlying perp account ("leveraged ETF-style" tokens; e.g. *Arcus BTC (3x Long)* = `pBTC3x`).

Architecture recovered by decompiling the unverified implementations (heimdall) + storage tracing (anvil fork):

- **Factory** (proxy `0x9c3663FA…` → impl `0x58bdc1d3…`, UUPS v3, AccessControlEnumerable):
  - `createPToken(salt, …)` (0xed6d7b26) CREATE2-deploys BeaconProxy pTokens — role-gated.
  - `setManager(address,address)` (0x5df8122f), `setBeacon` (0xd42afb56), `setBridgeVault` (0xebcb0b7a) — role-gated.
  - EIP-712 domain name = **`PerpsVaultNavOracle`** (chainId 4663, verifyingContract = factory) — the domain used for the off-chain **NAV signatures**.
  - Roles: `DEFAULT_ADMIN_ROLE` = Gnosis Safe `0x81B80499C396a9931b9e44953425a82C1b2541bd` (Safe v1.4.1, **2-of-3**); `NAV_SIGNER_ROLE` = **one EOA** `0xC70352b9a07be0e6aFDce63AC05c540E7d8Fe45A`. Two further roles gate the operational setters (child verification, `analysis/child-ptokens-admin.md`): roleA `0xb91dda2c…` (holders: the Safe + `0x57D32496…`) gates `setManager`/`createPToken`; roleB `0xfb488cd4…` (holders include deployer EOA `0x38d0eaba…` and `0x57D32496…`) gates the per-token/global **deposit allowlists** (`0xd3c5ee0e`, `0xfe618ab1`), the per-token limit setter (`0x4e666f20`, values = per-token deposit caps, e.g. $350,000 for BTC-3x) and token enable (`0xc2eabaf3`); DEFAULT_ADMIN gates `setBeacon`/`setBridgeVault`/`setMetadataBaseURI`/`0x8da87eb1`/`upgradeToAndCall`. The manager EOA holds **no** factory roles (its authority is the pToken-side `managerOf`).
- **pToken** (BeaconProxy → impl `0x1815A37B…`): an ERC-7540-style async vault + ERC-20 share token.
  - `totalAssets` is a **stored NAV** (ERC-7201 slot `0xd9fd…2a0a`, value = NAV × 1000), not a balance. `totalSupply` = OZ ERC-20 namespaced slot `0x52c63247…bace02`.
  - **Price (verified exactly against storage, fork test):**
    `convertToShares(assets) = assets·(totalSupply + 1e7)·1000 / (NAV·1000 + 1)`
    `convertToAssets(shares) = shares·(NAV·1000 + 1) / (totalSupply + 1e7) / 1000`
    (virtual offsets: 1e7 wei shares / 1 scaled-asset wei — negligible; the price is effectively NAV/share).
  - Flows: `requestDeposit(assets,controller,owner)` (0x85b77f45) / `requestRedeem(shares,…)` (0x7d41c86e) → operator (manager EOA `0xB7410dc44e…`) calls `bridgeDeposit` (0x42cc5a88) / `bridgeRedeem` (0x4c22fd49) to move USDG to/from the perp account via the bridge vault, then **pushes the NAV + fulfills** via one of `0xac6ac9a0` (deposit, kind=1), `0x56478360` (redeem, kind=2), `0x8152068c` (pure revaluation) — each carrying a **65-byte ECDSA signature by the NAV signer** over an epoch-numbered struct. Claim: `deposit/mint` (0x2e2d2984/0xda39b3e7) or `redeem/withdraw` (0xba087652/0xb460af94) consumes per-controller `claimableAssets/claimableShares` fixed at fulfill.
  - `depositFeeBps` = 25 (0.25%), `depositsPaused` false, `requestTtl` 604800 (7 d), `nextRequestId` 344, `nextRedeemRequestId` 423.

**What the finding's "$57.9M unverified leveraged-token factory" really is:** a well-guarded async NAV vault family with a signer-pushed NAV. The classic manipulation surfaces (donation, spot-price read, first-depositor inflation, stale NAV) are **closed by construction or by operator behavior** — details in §4/§5.

---

## 3. Live-state assessment (all reads at block **89,717,726** unless noted; CI artifact `ci-out/live_state.txt`)

| Item | Value |
|---|---|
| Factory proxy / impl | `0x9c3663FA9ab976E67B42939486EC4966Cb41a0BB` / `0x58bdc1d3068a0a79d7a662dee033d62cbd4f589f` (EIP-1967 impl slot set; **admin slot = 0**) |
| Factory `version()` / `pTokenCount()` | 3 / **17** |
| Beacon / owner | `0x33846348210A0Cc0345F354d9DE52b89AD473A76` / Safe `0x81B80499…` (2-of-3: `0x4f1d777b…`, `0x57D32496…`, `0xEAb7F386…`) |
| pToken impl (all 17) | `0x1815A37B6027Ae8066720d873A508F25fC151AC5` (unverified; code hash stable) |
| NAV_SIGNER_ROLE holder | `0xC70352b9a07be0e6aFDce63AC05c540E7d8Fe45A` (single EOA) |
| Manager EOA (BTC-3x) | `0xB7410dc44e2715161E9914272e2D55D7c5061FAa` (all 800+ fulfill/update txs) |
| Bridge vault | `0xD42c46c7BaD6A54b38395F846b09981CE75fb8e2` (221-byte proxy; USDG balance 0) |
| Asset | USDG `0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168` (Global Dollar, 6 dp) |
| BTC-3x NAV / supply / price | 97,431,825,945 (6 dp = $97,431.83) / 553.143870668396094780 / $176.141924 per share |
| BTC-3x USDG balance / reservedAssets / fee / paused | $25,064.52 / $24.83 / 25 bps / false |
| All 17 pTokens NAV (sum) | **≈ $717.3k–$723.6k** (block-dependent; $723,606.49 @ 89,675,792 → $717,518.73 @ 89,711,278 → $717,274.41 @ 89,750,332; all 17 share manager EOA `0xB7410dc44e…`; two test tokens, one empty `pTEST3` `0x122408c1…` TA=0/TS=0 with no quota; per-token data in `analysis/child-ptoken-inventory.json`) |
| DefiLlama | `parent#arcus` = $58,379,835 "Robinhood Chain" (perps exchange TVL — distinct from pToken custody) |

**NAV history (reconstructed from all 797 NAV-affecting events via `eth_getLogs`, `analysis/arcus_logs.json` + `analysis/nav_rows.json`):** 343 deposit fulfillments, 411 redeem fulfillments, 43 pure revaluations (median gap 10.2 h, max 167 h). Between consecutive events the stored NAV drifts by a median **$166.61** (max $27,790) of PnL — i.e. the operator **refreshes PnL at every fulfill**, not only at revaluations.

**Beacon upgrade history (all 17 pTokens share the impl):** 9 `upgradeTo` calls by the deployer EOA `0x38d0eabaedbcd65c2c2ff8e075f58f29f83cc101` at blocks 29,083,226 → 47,233,756 (last one set the current impl `0x1815A37B…`), then `transferOwnership` to the 2-of-3 Gnosis Safe `0x81B80499…` at block 51,223,179 — **no upgrades since**. The factory proxy was likewise upgraded once (impl `0xd42f03be…` at creation → `0x58bdc1d3…`).

---

## 4. What an attacker can / cannot do (fresh-attacker standard)

**Cannot (each verified):**

1. **Move the price by donation.** `convertToShares/convertToAssets` read only the stored NAV + totalSupply. Fork test `test_donation_cannot_move_nav`: donating 1,000,000 USDG to the pToken changes neither the NAV slot nor the price. The classic ERC-4626 donation/inflation attack has no surface here (the "asset" side of the formula is a signer-pushed number).
2. **First-depositor inflation on empty vaults.** Empty pToken `pTEST3` (NAV=0, supply=0) prices at exactly **$100/share** (`convertToShares(1e8)=1e18`, `convertToAssets(1e18)=1e8`), independent of the first deposit size; and the first deposit cannot set the price (the operator's fulfill sets NAV = deposit). Additionally, `pTEST3` has **no quota granted to anyone**, so `maxDeposit/maxMint/maxRedeem = 0` and `deposit` reverts `0x6565c4ec(amount, quota=0)` — it cannot be entered at all (child verification §2). Fork test `test_empty_token_initial_price`.
3. **Double-claim / replay a claim.** Replaying the real historical claim (`deposit(3604460120, …)`, block 88864900) from its own user reverts with `0x6565c4ec(amount, 0)` (claimable consumed). Fork test `test_no_double_claim`; `claimableDepositRequest(343, 0xf6c1…) == 0`.
4. **Replay a signed NAV payload.** The real 65-byte-signed `0xac6ac9a0` payload (block 88864767) reverts from **both** an unprivileged address and the manager with the same `0x3ac328da(epoch=45030, 1, 2)` — payloads are single-use/time-bound (epoch state is per-pToken: slot `0x35c8245d…` = 2 on BTC-3x, 0 on HOOD-3x; payload rejected on both). Fork test `test_nav_payload_replay_blocked`.
5. **Push a NAV/config/admin change.** All setters tested (`0xd3c5ee0e`, `0x4e666f20`, `0xfe618ab1`, `0x8da87eb1` on the factory; `0xac6ac9a0`, `0x56478360`, `0x8152068c`, `0x4204bef9`, `0x0690a09d`, `0x748e20ef`, `0x4c22fd49`, `0x42cc5a88`, `0x1c481e2d`, `0xe610da0b`, `0xf17bcffb`, `0x0fe21264`, `0x53131ea1` on pTokens) revert for unprivileged callers; 100 % of live calls come from the manager EOA. The manager check (`msg.sender == factory.managerOf(pToken)` via STATICCALL `0x7f41826b`, error `0x6c981570 NotManager`) is confirmed by fork traces for `bridgeDeposit`/`0x4204bef9`/`0x4c22fd49`/`0x748e20ef`/`0x42cc5a88` (child verification, `analysis/child-claim-math.md` §4) and present in the decompiled bodies of the other setters. Factory role-gated selectors revert `0xe2517d3f` (AccessControl unauthorized).
6. **Open a deposit request at all (quota + allowlist gate).** Fork-verified on live state: an allowlisted real depositor (`0xf6c1…`) successfully `requestDeposit`ed 5 USDG (escrowed; `pendingDepositRequest(344,…) = 5,000,000`), while a fresh address (and a fresh address used as *controller* by an allowlisted *owner*) reverted. The pToken reads a per-account quota pair (`{assetQuota, shareQuota}` at a keccak-derived storage slot) and the deposit side is additionally allowlisted at the factory (`0xd3c5ee0e` per-token / `0xfe618ab1` global allowlists, roleB-gated; factory per-address flag view `0x57d41c64`); state-override experiments show the fulfill credits exactly the pre-granted quota (child verification). **Today only $100 of deposit quota is open anywhere (pBTC3x, holder `0x001232c6…`)** — the deposit side is effectively closed to everyone, and a fresh attacker has no entry. **Redeems are open** to any share holder (fresh address successfully `requestRedeem`ed after receiving shares) but pay the operator-priced NAV.
7. **Stale-NAV arbitrage.** The share price an attacker actually gets is set at **fulfill**, using the operator's NAV computed seconds earlier — verified quantitatively: over 87 multi-hour intervals the NAV moved with median implied leverage **3.006** vs BTC (CoinGecko hourly), and per-event drift shows PnL is applied at each fulfill. Residual lag ≈ operator processing time (seconds), far below the 0.25 % deposit fee. (The pure revaluation cadence alone — median 10.2 h — would have been exploitable; it is **not** the pricing cadence.)

**Could do, in principle (not live):**
- Manipulate a **stale NAV** if the operator's fulfill NAV lags true perp-account equity by > ~0.5 % (deposit fee + exit cost) at the moment an attacker's request is fulfilled: deposit when stale NAV < true equity, redeem after the NAV refreshes (or redeem first when stale > true). **Re-arm condition:** monitor the signed NAV vs the perp account's mark-to-market (3×BTC benchmark) at fulfill; re-open if the gap exceeds fees at fulfill time.
- Cross-token / replayed NAV signature: **unverified** because the public RPC has no archive (payloads are time-bound; cannot replay inside their window — `analysis/blockers.md`). The EIP-712 domain is factory-wide, so token-binding must come from the signed struct (the pToken address is a struct field). If the digest omitted it **and** the update path were permissionless, an attacker could set one pToken's NAV from another's signed update — currently blocked by the per-token epoch state + time-bound payloads + (likely) manager gating.
- Claim rounding: the claim math is **pro-rata on frozen fulfill-time counters** (`deposit`: shares = ⌊assets·CS/CA⌋; `mint`: assets = ⌈shares·CA/CS⌉; `withdraw`: shares = ⌈assets·CS/CA⌉; `redeem`: assets = ⌊shares·CA/CS⌋), all vault-favouring and verified integer-exact on a fork (child verification: single vs chunked claims yield identical totals; over-claims revert `0x6565c4ec`; no re-inflation after draining a pool) — non-profitable by construction at 6-dp asset / 18-dp share scale.

**Cost side (for completeness):** deposit fee 25 bps (verified: effective fee +0.2414 %…+0.2506 % across real fulfill events); **no redemption fee** (verified: assets paid = shares × NAV/supply_before to −0.0000 % across the last 5 redeem fulfillments — `analysis/redeem_pricing_check.txt`); gas on Robinhood Chain is cheap but irrelevant at $0 extraction.

---

## 5. PoC / fork verification (CI)

Foundry project `poc/` — fork tests against **live Robinhood Chain state** via the public RPC (`RH_RPC`), read-only, no transactions.

- **Result: 7/7 PASS** — CI runs: **https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38844033248** (final, block 89,747,812), https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38843541968 (7 tests, block 89,744,453) and https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38839708953 (6 tests, block 89,717,726) — branch `arcus`, artifact `result-arcus`.
- Tests: `test_price_formula_matches_storage`, `test_donation_cannot_move_nav`, `test_no_double_claim`, `test_nav_payload_replay_blocked`, `test_empty_token_initial_price`, `test_vault_custody_and_reserved`, `test_deposit_request_gate` (see `poc/test/ArcusFork.t.sol`).
- CI custom job `ci/run.sh`: probes the RPC, records `ci-out/live_state.txt` (block, NAV, supply, price, fee, paused, pTokenCount, vault balance); disables the fork tests with a documented marker if the RPC is unreachable from the runner.

Local anvil-fork experiments (not in CI): full `debug_traceCall` slot mapping, payload decoding of all manager selectors, cross-token replay attempt, historical-claim replay, **live requestDeposit/requestRedeem flow test** (allowlisted user succeeds; fresh address blocked on deposits, allowed on redeems), and **independent claim-math verification by a child subagent** (`analysis/child-claim-math.md`: pro-rata counters, chunking invariance, over-claim reverts, manager-gating of fulfills).

---

## 6. Verdict, residual/latent risk, blockers

**Verdict: E-U $0 today (high confidence).** No unprivileged extraction path found on any of the 17 pTokens or the factory/beacon/bridge: the NAV is signer-signed and operator-pushed, the price function depends only on that stored NAV and totalSupply, claims are single-use, and the pricing NAV is fresh at fulfill.

**Classification of the residual value:**
- **P (privileged):** NAV-signer EOA `0xC70352b9…` (can sign arbitrary NAVs → instant mispricing/drain of any pToken if compromised); manager EOA `0xB7410dc44e…` (pushes signed updates + bridges funds); factory DEFAULT_ADMIN = Safe 2-of-3 (roles, beacon pointer, upgrades); roleA `0xb91dda2c…` (setManager/createPToken) and roleB `0xfb488cd4…` (deposit allowlists, per-token limits, token enable — **still held by the deployer EOA `0x38d0eaba…`** plus Safe owners); beacon owner = Safe 2-of-3 (single impl swap affects all 17 pTokens; 10 impls since launch, last at block 47,233,756); factory UUPS `upgradeToAndCall` (DEFAULT_ADMIN-only; 6 impls, last `0x58bdc1d3…`).
- **H-O (holder-only):** pending deposit/redeem requests are self-cancellable (`cancelDepositRequest`/`cancelRedeemRequest` require `controller == msg.sender` in the decompiled code) — funds are not stuck for holders even if the operator stalls. *(Caveat: the cancel → claim-cancel path was not fully exercised end-to-end because a fork RPC degradation interrupted the experiment; gating is inferred from decompiled code + the `redemption(422)` status-2 struct read.)*
- **S (stuck):** none identified (no paused paths; `depositsPaused=false` on all 17).
- **Conditional E-U (re-arm conditions):** (1) operator NAV lag > ~0.5 % at fulfill (signer outage/stale feed) → stale-NAV arb on deposits/redeems; (2) if any fulfill entry point is ever made permissionless **and** the signed struct omits the pToken address → cross-token NAV replay; (3) NAV-signer key compromise (P→E-U).

**Blockers encountered:** no verified sources for any Arcus contract; **no archive RPC** for Robinhood Chain (public endpoint only serves current state — `historical state … is not available`), so payload replay tests could only be run at current state (where they are time-bound), and historical NAV-vs-price checks used event data + CoinGecko rather than state replay. Documented in `analysis/blockers.md`.

---

## 7. Methodology & sources

1. **Recon of the corpus lead** (`zombie-hunt-iii/work/S3-fresh-tvl.md`, README Z3-H12) → re-verified every address on-chain (proxy code, impl slots, beacon, roles) — the corpus's "no ERC-1967 admin slot" and "109/229-byte proxies" confirmed.
2. **Decompilation:** heimdall on both unverified impls (`analysis/*_decompiled.sol`), plus `cast disassemble`/anvil traces for the functions heimdall failed to lift (the claim paths).
3. **State reconstruction:** ERC-7201 storage slot mapping via `debug_traceCall` on a local anvil fork; exact formula verified against live `convertToShares/convertToAssets`.
4. **Transaction forensics:** Etherscan V2 (chain 4663) `txlist` + `getcontractcreation` + `eth_getTransactionByHash`; full `eth_getLogs` history scan (797 NAV-affecting events) → NAV timeline; calldata decoding of every manager selector.
5. **Behavioral validation:** NAV-vs-BTC implied leverage (median 3.006, n=87) using CoinGecko hourly BTC; PnL-refresh-at-fulfill test via inter-event drift.
6. **PoC:** Foundry fork tests on live state (CI), local anvil fork for experiments (impersonation, `anvil_setStorageAt`-free tracing).

**Caveats & limitations:**
- Implementations are **unverified**; all conclusions are from decompilation + tracing + black-box behavior. Function semantics for the un-lifted claim paths rely on decompiled code + observed events + fork traces.
- The deposit-authorization flag's exact semantics (static allowlist vs time-varying per-account enablement) could not be fully pinned down: 6/8 historical depositors read `0x57d41c64 = true` today while 2 read false; either reading blocks a fresh attacker (empirically verified).
- The exact digest construction of the NAV signature was not recovered (payloads are time-bound and no archive RPC exists); token-binding of the digest is inferred (EIP-712 domain is factory-wide; the pToken address is a struct field) — replay is blocked today by per-token epoch state + time-bound payloads + manager gating.
- `convertToShares`/`convertToAssets` do not round-trip exactly (≤1 wei floor loss, e.g. `convertToAssets(convertToShares(1e6)) = 999999`); the quoted live values are raw contract outputs read at blocks 89,675,792 / 89,717,726 / 89,705,293.
- USD values use the on-chain USDG amounts (1:1 USD assumption for a Paxos-issued stablecoin) and BTC prices from CoinGecko.
- DefiLlama TVL ($57.9M) measures the Arcus perps exchange, not the pToken vaults — the headline "unverified factory holding $57.9M" is a **mis-attribution**: custody inside the reviewed contracts is ~$717.5k–$723.6k NAV (block-dependent).

**Files index:**
- `summary.json` — machine-readable verdict
- `analysis/factory_impl_decompiled.sol`, `analysis/ptoken_impl_decompiled.sol` — heimdall output
- `analysis/*_payload.hex` — decoded manager calldata (NAV updates, bridge, claims)
- `analysis/arcus_logs.json`, `analysis/nav_timeline.json`, `analysis/nav_rows.json` — full event history + NAV timeline
- `analysis/key_analysis.py`, `analysis/key_analysis.out` — headline numbers (leverage, reval cadence, drift)
- `analysis/redeem_pricing_check.txt` — exact deposit-fee (25 bps) and zero-redeem-fee verification from fulfill events
- `analysis/ptoken_inventory.txt`, `analysis/child-ptoken-inventory.json` — 17 pTokens (name/symbol/NAV/supply/asset/manager)
- `analysis/deposit-gate-evidence.md` — fork evidence for the per-controller deposit authorization gate
- `analysis/child-claim-math.md` — independent child verification of the claim math + fulfill gating
- `analysis/child-ptokens-admin.md`, `analysis/child-ptoken-inventory.json`, `analysis/child-ptoken-inventory.md` — independent child sweep: 17-token inventory, factory role map, upgrade history, quota model
- `analysis/blockers.md` — RPC/archive/source blockers
- `poc/` — Foundry fork tests (7/7 pass in CI) · `ci/run.sh` · `ci-out/` · `ci-log.txt`, `ci-artifacts/`
