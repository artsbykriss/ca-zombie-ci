# Zilliqa legacy apps cluster — L2-09 ZilSwap v1.1 · L2-10 Avely stZIL · L2-11 PlunderSwap V2

**Date:** 2026-10-15 · **Chains:** Zilliqa EVM ("Zilliqa 2", chain id 32769) — the legacy Scilla chain was retired 2026-07-20 and its apps were ported to Z2 as Scilla contracts running on the Z2 Scilla interpreter.
**Status:** read-only; chain-native simulations via `eth_call` only; **no mainnet transactions, no keys, no secrets**.

**Headline: E-U = $0 across all three targets.** No external unprivileged extraction path was found. Nominal value at stake ≈ **$208k** (ZilSwap 17.16M ZIL ≈ $54.2k; Avely 14.49M ZIL staked ≈ $45.8k; PlunderSwap 17.04M WZIL + 54.07k zUSDC ≈ $108k), all of it LP/holder-owned or admin-gated. Confidence: **high** for ZilSwap and PlunderSwap; **medium-high** for Avely (withdrawal-path liveness is keeper-dependent).

---

## 1. TL;DR

| Target | Live value (block 38,180,944) | Live extractable (unprivileged) | Why closed / open | Latent risk |
|---|---|---|---|---|
| **L2-09 ZilSwap v1.1** (Scilla on Z2, `0x459cb2d3…`) | **17,163,352.82 ZIL** in 130 pools (≈$54.2k) | **$0** | Contract initialized (`initialized=True`), owner fixed, no pending owner; standard AMM math (v1.1 lineage, recompiled for Z2 Scilla); all 130 pool tokens reject `TransferFrom` with zero balance (scan: 0 broken); swap/liquidity paths atomic (ZIP-21: Scilla revert ⇒ whole tx revert); token custody verified 11/12 top pools exact | Pool tokens are legacy ZRC-2s (many illiquid); if any pool token ever silently succeeds a transfer without balance, that pool's ZIL is drainable. Monitor. 574,927 XSGD excess (~$428) is stuck (no `skim` transition) |
| **L2-10 Avely stZIL** (Scilla on Z2, `0xe6f14afc…`; token `0x097c26f8…`) | **14,493,919.47 ZIL** staked via zimpl + 1,845,050.60 ZIL idle in contract (≈$45.8k); 11,706,410.23 stZIL supply | **$0** | **Minting is paused** (`is_paused_in=True`); withdrawals open but require stZIL balance and go through holder→zproxy→zimpl with balance checks (`AuthorizedMoveIfSufficientBalance`), rewards/buffer preconditions, and an **admin-gated `ClaimRewards`** keeper step; all admin transitions owner/admin-gated; EVM token is a thin wrapper over the same Scilla ledger (no double-spend) | If the owner+admin unpause mint, the mint math (rate 1.238118) becomes live; if the keeper dies, redemptions stall (staked ZIL stuck). `WithdrawTokensAmt` sim currently reverts (keeper/cycle preconditions) |
| **L2-11 PlunderSwap V2** (EVM on Z2, factory `0xf42d1058…`, pair `0xb1ba1730…`) | **17,044,567.48 WZIL + 54,071.09 zUSDC** (≈$108k) in the WZIL/zUSDC pair; 30 pairs total | **$0** | Pair source public (`Plunderswap/plunderswap-core`): faithful Uniswap-V2 fork with 0.35% fee k-check (`balance*10000 − amountIn*35`) and PancakeSwap-style 15/35 protocol fee; standard 27 selectors; CREATE2 verified with init hash `0xe430f659…`; WZIL fully backed (38,972,796.48 ZIL); zUSDC `mint` reverts for non-owner; TokenManager (zUSDC owner) functions all revert for an attacker | `feeToSetter` is an EOA (can redirect protocol fees); zUSDC is a bridge token — the bridge/gateway (TokenManager `0xAaF7…`, gateway `0xba44bc…`) is the systemic dependency for the pair's zUSDC side |

**Total live extractable now: $0 (E-U).** H-O (holder/user-recoverable): ZilSwap pools ≈$54.2k LP-owned; Avely stZIL ≈$45.8k (conditional on keeper); PlunderSwap pair ≈$108k LP-owned. P (privileged): factory feeToSetter; Avely owner/admin; ZilSwap owner. S (stuck): XSGD pool excess ≈$428; (conditionally) Avely staked ZIL if the keeper stays dead.

---

## 2. Context: legacy chain retired, apps ported to Z2

- The **legacy Scilla chain was paused 2026-07-20** after the Ledger-app signing flaw (683.1M ZIL proven theft; all legacy transactions frozen; official plan: retire legacy, migrate everyone to Zilliqa EVM — [zilliqa.com/ledger-incident](https://www.zilliqa.com/ledger-incident/)). The legacy Scilla JSON-RPC (`GetBlockChainInfo`, `GetSmartContractSubState` on `api.zilliqa.com`) no longer exists — the endpoint now serves Z2 EVM (chain 0x8001).
- The legacy Scilla contracts (ZilSwap, Avely, tokens) **exist on Z2 at the same 20-byte addresses** as EVM contracts whose code is the embedded Scilla source; the Z2 node executes them with the Scilla interpreter. State is readable via `GetSmartContractSubState` (bech32 form) and via the **`scilla_read` precompile `0x…5a494c92`**; state-changing Scilla transitions are invoked through the **`scilla_call_2` precompile `0x…5a494c53`** ([ZIP-21](https://github.com/Zilliqa/ZIP/blob/master/zips/zip-21.md)).
- This means the L2-09/L2-10 targets are **live on Z2**, not frozen on the legacy chain. All checks below are on Z2 at block **38,180,944** (Z2 produces ~2-3s blocks; RPC `https://api.zilliqa.com`).
- Simulation caveat (documented, worked around): `scilla_call_2` via `eth_call` requires the **sender to have an EVM ZIL balance** (the node deducts Scilla gas from the sender in the pending state). All write-simulations below therefore use funded senders (WZIL contract `0x94e18ae7…`, Avely contract, holder EOAs). A no-op transition (`TransferSuccessCallBack`) succeeds from a funded sender, proving the call encoding (layout `abi.encode(target, transition, mode=1, params…)`).

## 3. L2-09 — ZilSwap v1.1 (Scilla DEX)

**Deployed:** `0x459cb2d3baf7e61cfbd5fe362f289ae92b2babb0` = `zil1gkwt95a67lnpe774lcmz72y6ay4jh2asmmjw6u` (the v1.1 deployment from `Switcheo/zilswap` README; v1.0 at `0xba11eb7b…` holds a residual 1,395.48 ZIL).

**Live state (block 38,180,944):**
- `owner = 0x1499856ca9a32e717e9e872923fd3f4740af99e7` (legacy owner), `pending_owner = 0x0`, `initialized = True`, `output_after_fee = 9970` (0.30% fee).
- **130 pools**, total ZIL reserve **17,163,352.8227 ZIL**; the contract's ZIL balance is identical (17,163,528.2267 ZIL — the +175.4 ZIL delta is pool-external dust).
- Top pools: XSGD 9.63M ZIL, gZIL 2.04M, ZWAP 1.87M, ZPAINT 0.73M, zUSDT 0.56M, … (full dump in `analysis/zilswap/zilswap_pools_raw.json`).

**Why no unprivileged drain:**
1. **Initialization closed.** `initialized=True`, no `pending_owner`; the owner-gated `Initialize*`/`AddFunds`/`SetFee`/`TransferOwnership` transitions are unreachable for an outsider.
2. **Code is the standard ZilSwap v1.1 AMM.** Deployed source (`analysis/zilswap/zilswap_v11.scilla`, extracted from the embedded Scilla code) vs upstream `Switcheo/zilswap` `src/zilswap-v1/ZilSwap.scilla`: same transitions, same `frac`/`outputFor`/`inputFor` constant-product math; differences are mechanical (v1.1 `initialized` guard + Z2-Scilla syntax: `Option`→explicit overflow checks, `let true = True`). No hidden mint/withdraw/transfer-owner path.
3. **Swap/liquidity atomicity.** `SwapExactTokensForZIL` updates the pool, then queues `TransferFrom(from=_sender, to=contract, amount)` to the token; ZIP-21 guarantees a Scilla revert aborts the whole call, and the zq2 precompile code returns failure if the Scilla call fails (`zilliqa/src/precompiles/scilla.rs`). Simulated swaps from a token-less funded sender **revert** (5 tested, incl. the top pool).
4. **All 130 pool tokens reject zero-balance `TransferFrom`.** Chain-native scan (`analysis/zilswap/transferfrom_scan_full.json`): simulate `TransferFrom(sender,sender,1)` from the WZIL contract (holds no pool tokens) on every pool token → **0 succeeded**. A broken token (silent success) would have allowed selling non-existent tokens into its pool for ZIL — none exists.
5. **Custody verified.** For 11/12 top pools, the token contract's `balances[ZilSwap]` **exactly equals** the pool's token reserve (e.g., gZIL 17,769,439,155,865,398,016 raw = reserve). The XSGD pool holds 574,927 XSGD more than its reserve — stuck excess (ZilSwap v1.1 has no `skim`).
6. **Callbacks are inert.** `TransferFromSuccessCallBack`/`TransferSuccessCallBack` are no-ops; `RecipientAcceptTransferFrom` only accepts when `initiator == self && recipient == self` (nothing gained). Allowance-based `TransferFrom` requires the user's approval to ZilSwap, so no third-party token spend.

**Residual/latent:** the pools' ZIL is LP-owned (`total_contributions`); LPs can `RemoveLiquidity` proportionally (H-O). The pool tokens are mostly legacy ZRC-2s with no Z2 market (XSGD, gZIL(legacy), ZWAP, ZPAINT, zETH(legacy)), so stale-price arbs against Z2-native lookalike tokens are not executable (the Z2-native gZIL `0x03a79429…` and zETH `0x17d5af56…` are *different contracts* from the pool tokens `0xa845c103…`/`0x2ca315f4…`).

## 4. L2-10 — Avely stZIL (Scilla LSD)

**Deployed:** Avely staking contract `0xe6f14afc8739a4ead0a542c07d3ff978190e3b92` (`zil1umc54ly88xjw4599gtq860le0qvsuwuj72s246`); stZIL token `0x097c26f8a93009fd9d98561384b5014d64ae17c2` (EVM ERC-20, 12 dec, supply 11,706,410.226 stZIL).

**Live state (block 38,180,944):**
- `is_paused_in = True` (**minting paused**), `is_paused_out = False`, `is_paused_zrc2 = False`.
- `totalstakeamount = 14,493,919.4661 ZIL`, `total_supply = 11,706,410.2263 stZIL` → **rate 1.238118 ZIL/stZIL**.
- Contract holds 1,845,050.60 ZIL; the holder contract's delegations at zimpl (`0xa7c67d49…`) total **14,493,929.47 ZIL** across 3 SSNs (verified via `scilla_read`).
- `owner = 0xd08d2a1c…` (a Scilla contract), `admin = 0xf61477d7…` (EOA), `zimpl = 0xa7c67d49…`, `holder = 0xa0835524…`, buffers ×3, SSNs ×3 — **all present on Z2**; zimpl `paused=False`, `bnum_req=0`.
- **Shared ledger proven:** the PlunderSwap stZIL/WZIL pool's Scilla balance (`balances[pool]` = 33,558,074,040,161) is **exactly** the pool's EVM token0 reserve — the EVM token is a wrapper over the same Scilla ledger (it contains both `scilla_read` and `scilla_call` precompile addresses in its code). So stZIL traded on PlunderSwap is the same claim as the Scilla balances (no double-representation).

**Why no unprivileged drain:**
1. **Minting is paused** (`is_paused_in=True` blocks `DelegateStake` and `ChownStakeConfirmSwap` via `RequireNotPausedIn`), so the mint-side rate math is not callable.
2. **ZRC-2 transitions are properly checked**: `Transfer`/`TransferFrom` call `AuthorizedMoveIfSufficientBalance` (balance) and allowance checks; `RequireNotPausedZrc2` is False.
3. **Withdrawals require stZIL ownership**: `WithdrawTokensAmt` → `DoWithdrawal` requires `balances[initiator]` and `AdjustDeleg` checks `withdraw_token_amt ≤ balance`; payouts (`CompleteWithdrawal`) are keyed to `withdrawal_unbonded[_sender]`, so nobody can complete another's withdrawal.
4. **Admin surface is gated**: `ChangeAdmin/ChangeOwner/ClaimOwner/ChangeZimplAddress/SetHolderAddress/ChangeBuffers/UpdateStakingParameters/SlashSSN/ClaimRewards/ConsolidateInHolder` all `RequireOwner`/`RequireAdmin`; owner is a contract, admin an EOA.
5. **End-to-end withdrawal simulation reverts** (`WithdrawTokensAmt(1 stZIL)` from a real holder at block 38,180,944): the flow is gated by cycle/reward preconditions (`AssertNoRewards`, `AsseertNoBufferedDeposit` at zimpl) that are satisfied by the **admin-only `ClaimRewards`** keeper step. No attacker path — and no quick H-O either until the keeper acts.

**Residual/latent:** if the owner/admin unpause mint, the mint math becomes live (rate-based mint is standard `muldiv`, but the system is under-collateralized *on Z2 only in idle balance* — backing is staked at zimpl). If the keeper is dead, redemptions stall and the 14.49M stZIL-backed ZIL is stuck (S). The stZIL/WZIL PlunderSwap pool (~$124) trades stZIL at a discount to the 1.238 rate — an arb only if redemption liveness returns.

## 5. L2-11 — PlunderSwap V2 (EVM)

**Deployed (Z2 EVM):** factory `0xf42d1058f233329185A36B04B7f96105afa1adD2` (30 pairs); feeTo = feeToSetter = `0xB4e8E3ba3ae55622e83bF2FedF179BDbda6Ac576` (**EOA**, no code); WZIL `0x94e18ae7…`; zUSDC `0xe59f97fa…`.

**Pair `0xb1ba173026dbc2a56af63669a402d4c3d7aeef3e` (WZIL/zUSDC):** reserves **17,044,567.48 WZIL + 54,071.09 zUSDC** (LP supply 0.953e18) — actively traded (reserves moved between two reads ~2h apart).

**Source-verified:** `Plunderswap/plunderswap-core` `PlunderPair.sol` = Uniswap-V2 fork with:
- `swap` k-check: `balanceAdjusted = balance*10000 − amountIn*35`, `require(b0Adj*b1Adj ≥ r0*r1*10000²)` → **0.35% fee**;
- `_mintFee`: `numerator = totalSupply*(rootK−rootKLast)*15; denominator = rootK*20 + rootKLast*15` → PancakeSwap-style **15/35 protocol fee** to `feeTo` (matches docs: 0.20% LP + 0.15% treasury);
- all other logic byte-for-byte standard V2 (lock modifier, `_safeTransfer`, `MINIMUM_LIQUIDITY`, `skim`/`sync`, permit extension).
- Deployed pair: **27 standard V2 selectors**; **CREATE2 address reproduced** with init code hash `0xe430f659afa40ede00151df237b294363f96de0408658f7c62089d10d64178cd` (from the app bundle) — deployed code is the factory's canonical pair.

**Why no unprivileged drain:**
1. Pair has no permissionless value-moving path beyond standard `swap`/`mint`/`burn`/`skim`/`sync`; k-check prevents any direct `swap()` that decreases k. `skim` extracts only excess (currently zero: balances == reserves).
2. **WZIL is fully backed**: supply 38,972,796.4755 WZIL == contract ZIL balance (38,972,796.4755 ZIL). No mint path besides `deposit()` against real ZIL.
3. **zUSDC cannot be minted by an attacker**: `mint(address,uint256)` reverts for a non-owner; owner is the bridge TokenManager proxy `0xAaF7F44c…` (impl `0x3ccb653d…`, a TokenManager with `getGateway/setGateway/withdrawFees/transfer/removeToken/transferTokenOwnership/setFees`), and **all of its state-changing functions revert for an attacker** (gateway `0xba44bc29…` is the validation layer).
4. Price is fair: pool implies 1 WZIL = $0.00317 vs Z2 V3 zUSDT/WZIL $0.00316 — inside round-trip fees (0.35% V2 + 0.01% V3).

**Residual/latent:** `feeToSetter` EOA can redirect protocol fees (P). The zUSDC bridge/gateway is a trusted dependency — if the bridge validation ever breaks, the pair's zUSDC side (and hence WZIL side) is at risk. LP tokens are freely burnable (H-O).

## 6. Verification / simulations (all read-only, chain-native)

| # | Check | Result | Artifact |
|---|---|---|---|
| 1 | ZilSwap state (`owner/initialized/pending_owner/fee`) | confirmed | `ci-out/verify_results.json` |
| 2 | ZilSwap pools: 130, 17,163,352.82 ZIL, contract balance match | confirmed | same |
| 3 | ZilSwap: `TransferFrom` zero-balance scan, **all 130 pool tokens** | **0/130 succeeded** | `analysis/zilswap/transferfrom_scan_full.json` |
| 4 | ZilSwap: token custody `balances[ZilSwap]` vs reserves (top 12) | 11/12 exact; XSGD +574,927 excess | `analysis/zilswap/custody_top12.md` |
| 5 | ZilSwap: `SwapExactTokensForZIL` from token-less funded sender | reverts (atomicity holds) | this README §3 |
| 6 | Avely state + rate + zimpl delegations (14,493,929.47 ZIL) | confirmed | `ci-out/verify_results.json` |
| 7 | Avely: shared-ledger (pool Scilla balance == EVM reserve) | **True** | same |
| 8 | Avely: `WithdrawTokensAmt(1 stZIL)` from real holder | reverts (keeper preconditions) | same |
| 9 | PlunderSwap: pair reserves, WZIL backing, zUSDC mint sim, TokenManager sims | all gated | same |
| 10 | PlunderSwap: pair selectors + CREATE2/init-hash + fee constants | standard V2 + 0.35% fee | `analysis/plunderswap/PlunderPair.sol` |

CI: `bash /home/heisenberg/CA/ci/ci-run.sh zilliqa-legacy` → **run 1: https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38722082047** (block 38,181,350; all checks passed; artifact `result-zilliqa-legacy`). The job re-runs `ci/verify.py` and uploads `ci-out/` as an artifact. See `ci-log.txt`, `ci-artifacts/` and `ci-out/ci-run-url.txt`.

## 7. Caveats & limitations

- The **legacy Scilla chain is retired** (no RPC): legacy-era balances were re-read on Z2 (post-migration state). All figures are Z2 state at the stated blocks.
- `scilla_call_2` write-simulations require a funded sender (node gas-deduction quirk); non-funded senders fail mechanically — noted so the "revert" results above are interpreted correctly (the funded-sender no-op success is the control).
- `eth_getLogs` is limited to 50-block ranges on the public RPC; no full holder enumeration was possible without an explorer (`evmx.zilliqa.com` no longer resolves).
- USD values use ZIL ≈ $0.00316 / zUSDC ≈ $1.0 (GeckoTerminal WZIL quote at query time). Nominal totals only; E-U is $0 regardless.
- The Avely withdrawal path was not proven to complete end-to-end (admin keeper step required); classified H-O conditional / latent S.

## 8. Files

```
zilliqa-legacy/
├── README.md                      (this file)
├── summary.json                   (machine-readable)
├── analysis/zilswap/              pools_raw, pool_tokens_classified, transferfrom_scan_full, deployed+upstream scilla sources
├── analysis/avely/                stzil_owner_scilla.txt (deployed source), holder/zproxy/zimpl sources
├── analysis/plunderswap/          PlunderPair/Factory/ERC20 sources, 30-pair state snapshot
├── ci/verify.py, ci/run.sh        self-contained re-verification suite (public RPC only)
└── ci-out/                        verify_results.json, SUMMARY.txt, verify.log, CI run URL
```
