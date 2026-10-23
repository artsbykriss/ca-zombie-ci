# World Markets Spot (Concord Exchange, MegaETH) — **$0.00 live unprivileged extraction** on **$668,908** of user custody

**Date:** 2026-10-23 · **Chain:** MegaETH (chain id **4326**) · **Status:** read-only; every state change is a local
Foundry fork or a state-less `eth_call`; **no mainnet transaction was signed or sent.**
**Live reads at block:** 29,963,373 / 29,963,541 / 29,964,301 (pinned) · **PoC:** **13/13 PASS** in GitHub Actions
([run 39959641892](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39959641892),
[run 39957898878](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39957898878),
[run 39957092762](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39957092762)).

---

## TL;DR

| Item | Value |
|---|---|
| **Target** | `Composite Exchange` (proxy) [`0x5e3Ae52EbA0F9740364Bd5dd39738e1336086A8b`](https://mega.etherscan.io/address/0x5e3Ae52EbA0F9740364Bd5dd39738e1336086A8b) + 3 facets + 14 order books + 4 `wl*` vaults |
| **Internal name** | **Concord Exchange** (interfaces: `IConcordProtocolPub`; audit: "World Markets") |
| **Total custody held by the exchange** | **$668,908.29** (9 tokens, block 29,963,541) |
| **DefiLlama reference** | $660,549 (World Markets Spot) — same custody, different price snapshot |
| **User-attributable (H-O)** | **$668,907.19** — the ledger sums to the exchange's token balances **exactly** (8 of 9 tokens delta = 0) |
| **Unattributed residual (S/P)** | **$1.10 USDm** (exactly 1.1e18 raw; no user ledger entry, no admin withdraw function) |
| **Live extractable, unprivileged (E-U)** | **$0.00** |
| **E-U confidence** | **high** on mechanics (20/20 permissionless probes revert with role errors; fork-proven) · **medium** that no deeper accounting bug exists (source unverified) |
| **Why closed** | Every user-scoped path is gated by `checkTradingPermission` → `CallerIsNotTrader (0xd07a9d6b)`; every account path by `CallerHasNoAccount (0xfb64298d)` / `CallerNotPermissioned (0xaebf6f28)`; every admin path by `AdminRoleOnly (0x10c95c62)`; order-book admin by `ExchangeOnlyCall (0x26e41fb0)`; `wl*` vault admin by vault-specific guards |
| **Verdict** | **CLOSE as OPEN #8 — E-U $0 (high)**. Residual risk is **privileged** (single-EOA admin) and **dust** ($1.10 stuck). |

### Corrections / additions to the pass-2 brief

1. **DefiLlama's `audits: 0` is wrong.** The team publishes a **2026-02-20 collaborative audit**
   (`github.com/World-Markets-Inc/smart-contract-audits`): **6 High / 12 Medium / 5 Low**, all marked
   RESOLVED (incl. `checkSellBalance` spot accounting, `lifo` lender-swap interest avoidance,
   `lendHoursDuration` underflow, lending-position key collision). This materially changes the
   "0 audits" premise.
2. **The contracts are not source-verified on either explorer** (Mega Etherscan chain 4326 and the
   Blockscout instance `megaeth.blockscout.com` both return "not verified"; Sourcify `match: null`).
   The protocol is reconstructible from the team's own public interface repo
   (`World-Markets-Inc/contract-owner` → `IConcordProtocol*.sol`, `PublicStruct.sol`), which is the
   authoritative ABI used here.
3. **The $664k is not "spot order-book liquidity".** 4 of the 5 spot books are **empty**
   (`countBuyOrders = 0`); the custody is **user vault balances** inside the exchange. DefiLlama's
   `sumTokens` methodology ("counts the value of all assets on the WorldInc exchange") is literally
   the exchange contract's token balances.
4. **The whole spot/perp/lend system is one custody contract.** Order books hold **zero** tokens;
   they are pure order storage. There is a single honeypot.

---

## 1. The mechanism in exact terms

World Markets is a fully on-chain order-book DEX with **unified cross-margin** across spot, perpetuals
and under-collateralised lending ("PrimeDEX"). All three markets share one exchange contract that
custodies every ERC-20 and keeps per-`(user, token)` ledgers.

### 1.1 Deployed topology (proxy + 3 facets)

The address DefiLlama/the adapter use (`0x5e3Ae5…`) is a **348-byte dispatcher**:

```
sload(0x040000000000000000) -> 0xe1fc1881…  (facet router; 24,358 bytes runtime)
    routes by the top 3 calldata bytes:
      != 0xffffff  -> sload(0x010000000000000000) = 0x431212abc… (trading facet, 23,792 B)
      == 0xffffff  -> sload(0x020000000000000000) = 0xafba6b6a… (bulk/account facet, 22,748 B)
admin (slot 0) -> 0xCe46EE0664e02d6FF478f08e580De42EeFA29cC9 (EOA, 0.0928 ETH)
```

| Contract | Address | Role |
|---|---|---|
| Exchange (proxy) | `0x5e3Ae52EbA0F9740364Bd5dd39738e1336086A8b` | custody + dispatch |
| Facet router | `0xe1fc1881d1c495b399c9890930aa416e89d691c2` | 56 selectors |
| Trading facet | `0x431212abc35737011ddd7306fb5229752b6bd115` | 22 selectors (`liquidate`, `payInterestAndFees`, `lifoLenderSwap`, `renewLoan`, `bankruptcy`, reads) |
| Bulk/account facet | `0xafba6b6a8d1b8cacd1fc12df9e32f23f1a923417` | 26 selectors (`createAccount`, `depositErc20`, `withdrawErc20`, `allowTradingForAccount`, `0xffffff**` bulk/admin) |
| View helper | `0x114ad4434ee438354da28d9633e2273cd7a1dcf2` | loops `getHighestTokenId`/`getMarkPrice`/`readTokenConfig` |
| 5 spot books | WETH `0xf818c8da…`, USDT0 `0x086a0a65…`, BTC.b `0x62d6ff25…`, wiTRY `0x8214ca3a…`, MEGA `0xbdbeacc6…` | bookType **11** |
| 5 perp books | WETH `0xf12fe484…`, BTC.b `0x757b27d9…`, SOL `0x0b35a779…`, HYPE `0xe666c9a0…`, MEGA `0x6be130b3…` | bookType **22** |
| 4 lend books | USDm `0x7a5d6c6b…`, WETH `0x0f762fb1…`, BTC.b `0xec956333…`, MEGA `0x5475b30b…` | bookType **33** |
| `wl*` vaults | wlUSDm `0xc2373c03…`, wlETH `0xf8183d13…`, wlBTCb `0x852025c1…`, wlMEGA `0xcafe11a0…` | NAV share tokens (proxy → `0xe90eee54…`) |
| Deployer / admin | `0xCe46EE0664e02d6FF478f08e580De42EeFA29cC9` | 120+ contract deployments |

### 1.2 Token ids and custody (block 29,963,541)

| id | token | exchange balance | price (DefiLlama) | USD |
|---:|---|---:|---:|---:|
| 1 | USDm `0xfafddbb3…` | 358,475.90959872 | $0.996943 | $357,379.92 |
| 4 | WETH `0x4200…0006` | 13.04612870 | $2,395.126 | $31,247.12 |
| 5 | USDT0 `0xb8ce59fc…` | 432.488298 | $1.00 (peg) | $432.49 |
| 6 | BTC.b `0xb0f70c0b…` | 0.28477168 | $81,687.84 | $23,262.38 |
| 9 | wiTRY `0x15b271d9…` | 10,241,538.31630721 | $0.024210 | $247,943.05 |
| 10 | MEGA `0x28b7e77f…` | 170,090.27558697 | $0.045817 | $7,792.97 |
| 11 | wlBTCb `0x852025c1…` | 0.00805472 | NAV $82,147.03 | $661.67 |
| 12 | wlUSDm `0xc2373c03…` | 79.77262455 | NAV $1.011529 | $80.69 |
| 13 | wlETH `0xf8183d13…` | 0.04490206 | NAV $2,405.115 | $107.99 |
| | **total** | | | **$668,908.29** |

Token ids 2 and 3 are unregistered. Ids 7 (SOL) and 8 (HYPE) are registered but hold 0.

### 1.3 Custody reconciliation — the decisive measurement

A full scan of **all 1,581 user ids × 11 token ids** (`getBalance(uint64,uint32)`, pinned to one block)
yields **1,687 active user-token pairs / 1,218 funded users**, and the per-token sums reproduce the
exchange's balances **exactly**:

| token | Σ user ledger (raw) | exchange balance (raw) | delta |
|---|---:|---:|---:|
| USDm | 358,474.809598723102096033 | 358,475.909598723102096033 | **+1.100000000000000000** |
| WETH | 13.046128702112466340 | 13.046128702112466340 | 0 |
| USDT0 | 432.488298 | 432.488298 | 0 |
| BTC.b | 0.28477168 | 0.28477168 | 0 |
| wiTRY | 10,241,538.316307207583761190 | idem | 0 |
| MEGA | 170,090.275586970329524782 | idem | 0 |
| wlBTCb | 0.00805472 | 0.00805472 | 0 |
| wlUSDm | 79.772624553227840001 | idem | 0 |
| wlETH | 0.044902055691996430 | idem | 0 |

So **$668,907.19 is user money (H-O, self-service)** and **$1.10 USDm** is an unattributed residual
(almost certainly accumulated protocol trading fees — taker 1.00% / maker 0.50% bps per
`OrderBookConfig`; there is no admin withdraw function, so it is effectively stuck). Sequestered
amounts (resting-order collateral) are dust: Σ spot/lend seq = 2,288,204,124 raw, Σ perp seq =
31,600,000 raw.

---

## 2. Live-state assessment — roles and gates

### 2.1 The permission model (from the deployed runtime + team interfaces)

`IConcordProtocolUser` documents: *"creates an account for msg.sender … msg.sender is the owner of
this account"*, and `allowTradingForAccount` delegates trading but **not deposit/withdraw**. The
`World-Markets-Inc/contract-owner` README states the exchange resolves the user id from `msg.sender`,
so approving a forwarder cannot let other callers trade your account. The on-chain evidence matches:
every user-scoped call made from an address with no account reverts with a role error.

| Custom error (from `IConcordProtocolErrors.sol`) | Selector | Meaning |
|---|---|---|
| `CallerIsNotTrader` | `0xd07a9d6b` | caller not owner/delegate of the passed userId |
| `CallerHasNoAccount` | `0xfb64298d` | caller has no exchange account |
| `CallerNotPermissioned` | `0xaebf6f28` | caller not permissioned for that account/role |
| `AdminRoleOnly` | `0x10c95c62` | admin-only |
| `ExchangeOnlyCall` | `0x26e41fb0` | order-book admin, exchange-only |
| `NoSuchPosition` | `0xabc24034` | unknown lending position |

### 2.2 Live probe matrix — 20/20 unprivileged calls revert (from `0x1111…1111`)

| Call | Revert | Gate |
|---|---|---|
| `withdrawErc20(USDm, 1)` | `0xfb64298d` | CallerHasNoAccount |
| `depositErc20(USDm, 1)` | `0xfb8f41b2` | TransferFailed (no balance/allowance) |
| `batchCommands(265, [])` | revert | account gate |
| `newSpotBuyOrder(book, 0)` / `cancelSpotBuyOrder` / `newLendOrder` | `0xd07a9d6b` | CallerIsNotTrader |
| `liquidate(265,265,0)` | `0xd07a9d6b` | CallerIsNotTrader |
| `payInterestAndFees(1,0,false)` | `0xabc24034` | NoSuchPosition (lookup precedes; caller also unpermissioned) |
| `markLendPositionAsNonReturnable(1)` | `0xd07a9d6b` | CallerIsNotTrader |
| `lifoLenderSwap(1)` | `0xd07a9d6b` | CallerIsNotTrader |
| `renewLoan(265,265,0)` | `0xd07a9d6b` | CallerIsNotTrader |
| `requestPerpTrueUp(1,1,4)` | `0xd07a9d6b` | CallerIsNotTrader |
| `bankruptcy(265,10000)` | `0xaebf6f28` | CallerNotPermissioned (OPS role) |
| `allowTradingForAccount(265, attacker)` | revert / `0xaebf6f28` | not the account owner |
| `liqSwap(265,0,0)` (bulk) | `0xd07a9d6b` | CallerIsNotTrader |
| `setTokenConfig(1,1,1)` | `0x10c95c62` | AdminRoleOnly |
| `setOpsAddress(attacker)` | `0x10c95c62` | AdminRoleOnly |
| `switchTokenAddress(1,attacker,[])` | `0x10c95c62` | AdminRoleOnly |
| `changeAdmin(attacker)` | revert | separate super-admin role (not the known admin) |
| `book.haltTrading(true)` / `book.setMinOrderQuantity(1)` | `0x26e41fb0` | ExchangeOnlyCall |
| `wl.setManagerAddress/setTraderAddress/setAdmin/rescueErc20` | vault errors (`0xc15c60b4`, `0x20a1c0fc`, `0x5208f36c`) | wl vault role guards |

Differential control: the same calls **succeed** from the correct principals — e.g.
`withdrawErc20` from the real owner `0xc37b5d9a…` (user 265) returns success, and
`setTokenConfig` / `setOpsAddress` succeed from the admin `0xCe46EE…`. The gates are real role
checks, not blanket reverts.

`computeBuy/SellMarketOrderSpecifyIn/Out(uint256)` on the order books **are** callable by anyone
(documented as "for use by PriceHelper … will error out"), but they are **side-effect-free**:
`countBuyOrders()` is unchanged across the call (fork-proven). Low.

---

## 3. What an attacker can / cannot do

**Cannot (all fork- and live-verified):**
- Move another user's balance — `batchCommands`/order entry/`lifoLenderSwap`/`liquidate` all require
  the caller to be the owner or a permissioned delegate of the passed `userId`.
- Withdraw anything without an account (`CallerHasNoAccount`) or above the ledger balance
  (withdrawals are `msg.sender`-scoped; there is no `userId` parameter on `withdrawErc20`).
- Grant itself trading rights on a victim account (`allowTradingForAccount` is owner-only).
- Halt books, change fees/min order, migrate a token address, rotate the admin, rescue `wl*` vault
  tokens — all role-gated.
- Exploit the order-book `compute*` simulations (no state change).
- Exploit the `wl*` vaults (mint/burn/admin gated; the vaults hold their own deposit tokens, and the
  exchange tracks them under distinct token ids 11/12/13, so a vault-share mint cannot be credited as
  USDm).

**Can:**
- `createAccount()` and `depositErc20()` — credit only what it actually transfers in.
- `computeFundingRateNow(tokenId)` — permissionless by design, recomputes the averaged funding rate;
  no balance effect observed.
- `renewLoan(user, userToPay, almostDueLendingId)` and `liquidate(...)` **if** the caller has an
  account and a target is genuinely liquidatable/renewable — these are permissionless-by-design
  public-good paths with a capped payout (≤1% of resulting value / 1% of min order size). **No
  liquidatable account was found** (spot books effectively empty: 4/5 have zero orders; the lend book
  has 5 sell orders; total sequestered ≈ dust).

**Costs:** none — no unprivileged path exists, so there is no gas/profit computation to make.
For completeness the full 12-call adversarial sweep costs **481,582 gas** and nets **$0.00**.

---

## 4. PoC / fork verification

**Project:** `world-markets-spot/poc/` (Foundry 1.8.5, solc 0.8.24, vendored `lib/forge-std`), fork of
the **public keyless** MegaETH RPC (`https://mainnet.megaeth.com/rpc`, override `MEGAETH_RPC`).

**CI:** [run 39959641892](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39959641892) —
**13/13 PASS** (block 29,964,301); earlier [run 39957898878](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39957898878) —
**11/11 PASS** (block 29,963,541); [run 39957092762](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39957092762) —
**11/11 PASS** (block 29,963,161). Artifact `result-world-markets-spot` → `ci-out/state.json`,
`ci-out/permission_matrix.json`.

| Test | Result | What it proves |
|---|---|---|
| `test_live_state_and_discovery` | PASS | chain id 4326; `getHighestTokenId`=13; `bulkReadMaxUserId`=1581; token1=USDm/18dec; token4=WETH; spot book (4,1)=`0xf818c8da…` bookType 11; not halted |
| `test_custody_in_exchange` | PASS | exchange holds >100k USDm; **spot and lend books hold 0** |
| `test_gate_trading_paths` | PASS | 10 trader-scoped calls → `CallerIsNotTrader` / `CallerNotPermissioned` |
| `test_gate_withdraw_and_account` | PASS | `withdrawErc20` → `CallerHasNoAccount`; `allowTradingForAccount(victim)` → `CallerNotPermissioned` |
| `test_attacker_account_has_zero_value` | PASS | attacker `createAccount()` succeeds, balance 0, `withdrawErc20` still reverts |
| `test_gate_admin_paths` | PASS | `setTokenConfig`/`setOpsAddress`/`switchTokenAddress` → `AdminRoleOnly`; `changeAdmin` reverts for everyone but the super-admin |
| `test_admin_role_is_real` | PASS | admin `0xCe46EE…` **can** `setTokenConfig` and `setOpsAddress`; `changeAdmin` reverts even for it |
| `test_gate_orderbook_admin_paths` | PASS | book `haltTrading`/`setMinOrderQuantity` → `ExchangeOnlyCall` |
| `test_orderbook_compute_is_readonly` | PASS | `computeBuyMarketOrderSpecifyIn` callable but `countBuyOrders` unchanged |
| `test_gate_wl_vault_admin` | PASS | wl vault `setManager`/`setTrader`/`setAdmin`/`rescueErc20` all revert |
| `test_liquidatable_set` | PASS | exactly **4 of 1,581** users are underwater (risk-adjusted deficits −$121.17 / −$1.48 / −$510.74 / −$3.21, ≈ **$641** total) |
| `test_keeper_liquidation_path` | PASS | permissionless `liquidate()` on all 4 reverts `LiquidationNotSuccessful` (0x62a8087e) — empty books; attacker USDm delta **0** |
| `test_sweep_no_unprivileged_state_change` | PASS | 12-call adversarial sweep, **0 successes**, 481,582 gas |

**Reproduce:**

```bash
cd world-markets-spot/poc
MEGAETH_RPC=https://mainnet.megaeth.com/rpc forge test -vv
```

**CI custom job:** `ci/run.sh` → `ci/dump_state.py` scans all users × tokens at a **pinned block**,
reconciles custody, replays the 20-call permission matrix as `0x1111…1111`, fetches DefiLlama prices,
and writes `ci-out/state.json` + `ci-out/permission_matrix.json` (exit 0; `unprivileged successes: []`).

---

## 5. Quantification

| Category | USD | Confidence | Basis |
|---|---:|---|---|
| **E-U** (external unprivileged) | **$0.00** | **high** | 20/20 permissionless probes revert with role errors (live, pinned block); 13/13 fork tests; every state-changing entry point is either role-gated or owner-scoped |
| **E-U-conditional** | **$0.00** | high | `liquidate`/`renewLoan` are permissionless but require a distressed account: **4 of 1,581 users are underwater** yet `liquidate()` reverts `LiquidationNotSuccessful` (empty books); sequestered collateral ≈ dust |
| **H-O** (holder self-service) | **$668,907.19** | high | Σ user ledgers == exchange custody (8/9 tokens delta 0); owners may withdraw their own balance subject to the portfolio check |
| **P** (privileged) | **$668,908.29** at risk | high | admin EOA `0xCe46EE…` can `setTokenConfig`, `setOpsAddress`, `switchTokenAddress` (migrate a token mapping + balances); a separate super-admin can `changeAdmin`; `wl*` vault manager/trader roles |
| **S** (stuck) | **$1.10** | medium | the only unattributed custody (1.1e18 USDm); no user ledger entry and no admin withdraw function found |

**Headline: external unprivileged extraction ≈ $0.00 (high confidence).**

---

## 6. Blockers, negative results, residual risk

**Why the target is closed (mechanically):**
- One custody contract, and every outflow is either `msg.sender`-scoped (`withdrawErc20`) or gated by
  `checkTradingPermission(userId)`.
- Admin surface is a distinct role (EOA), not reachable by `0xffffff**` spoofing; `switchTokenAddress`
  and `setTokenConfig` return `AdminRoleOnly` for anyone else.
- Order-book admin is `ExchangeOnlyCall`.
- No free-credit path found: `createAccount` + `depositErc20` credit only actually-transferred tokens;
  `wl*` share tokens are tracked as separate token ids.

**Negative results (checked, not exploitable):**
- 4/5 spot books and 4/5 perp books have **zero** resting orders; `bestBidOffer` = 0.
- `compute*MarketOrderSpecify*` callable by anyone → side-effect-free.
- Sequestered balances (resting-order collateral) ≈ dust (2.29e9 raw USDm).
- `changeAdmin` reverts for the known admin too → a separate super-admin exists (unidentified);
  not attacker-reachable.
- **4 of 1,581 users are underwater** (risk-adjusted deficits −$121.17 / −$1.48 / −$510.74 / −$3.21,
  ≈ **$641** total), but the permissionless keeper path is **inoperable**: `liquidate()` on each reverts
  `LiquidationNotSuccessful` (0x62a8087e) because the books have no liquidity; attacker USDm delta **0**.

**Residual / latent risk:**
- **Single-EOA admin over $668k.** `0xCe46EE…` (0.0928 ETH) controls `setTokenConfig`,
  `setOpsAddress` and `switchTokenAddress`; `switchTokenAddress(tokenId, newAddress, users)` can
  re-point a token id and migrate balances — a privileged migration primitive worth an admin-key
  review. The `wl*` vault `manager`/`trader` are `0x0ac3dd9a…`.
- **Unverified source.** Logic is reconstructed from the team's public interface repo + the audit
  report + runtime selector extraction. A subtle accounting bug in the matching engine, funding, or
  liquidation could exist that no interface-level probe would reveal — but there is no unprivileged
  value-moving entry point to trigger it.
- **Post-audit deployment.** The three facets were (re)deployed at blocks 21,800,870–876 (2026-06),
  after the 2026-02-20 audit; the deployed code is post-audit but unverified.
- `computeFundingRateNow` is permissionless and writes state — worth a targeted review if a bug class
  is sought.

---

## 7. Methodology, sources, caveats

**Method.**
1. Located the protocol from the DefiLlama adapter (`worldinc-perps/worldinc.ts`) → Composite Exchange
   `0x5e3Ae5…`; resolved the 348-byte proxy's facet slots by `eth_getStorageAt`.
2. Found the team's public GitHub org (`World-Markets-Inc`): the **audit PDF** and the **interface
   repo** (`IConcordProtocolPub`, `PublicStruct.sol`, `ISpotOrderBook`, `IOrderBookAbstract`,
   `ILendOrderBook`, `ConfigConstants`, `IConcordProtocolErrors`) — used as the authoritative ABI.
3. Enumerated selectors from the deployed runtimes (`63<sel>14` dispatch chains) and matched them to
   interface signatures (31/56 + 22 + 26); mapped the remainder to the admin/bulk surface.
4. Read live state at pinned blocks: token configs, 14 order books + configs, exchange balances,
   `bulkReadMaxUserId`, full 1,581 × 11 user-ledger scan.
5. Replayed a 20-call permission matrix as a fresh address via `eth_call` and differential-tested the
   same calls from the real owners/admin.
6. Fork-tested 13 scenarios in Foundry on a local MegaETH fork (GitHub Actions).

**Sources.** DefiLlama (`api.llama.fi/protocol/world-markets-spot`, `coins.llama.fi` prices);
`mega.etherscan.io` (Etherscan V2, chainid 4326) for tx/log lists;
`megaeth.blockscout.com` for address metadata; `github.com/World-Markets-Inc/{smart-contract-audits,
contract-owner}`; the public MegaETH RPC.

**Caveats.**
- **Unverified source** (see above); this is the main limitation and the reason E-U confidence is
  "high on mechanics, medium on completeness".
- **Point-in-time:** 2026-10-23; all numbers at blocks 29,963,373 / 29,963,541. Re-read before acting.
- The $1.10 residual is inferred to be protocol fees (no ledger entry); it is unattributed by
  construction, not by proof of origin.
- `wl*` NAVs are computed as `getAum()/totalSupply()` at the read block.
- No mainnet transaction was signed or sent; all state changes are local forks. No secrets or keyed
  RPC URLs are stored in this folder (public CI repo).

**Files.**
- `README.md` — this report.
- `summary.json` — machine-readable summary.
- `analysis/audit_report.pdf` / `.txt` — the team's 2026-02-20 audit.
- `analysis/contracts.json` — full system inventory (proxy, facets, 14 books, wl vaults, tokens).
- `analysis/selector_map.json`, `analysis/impl_selectors.txt` — deployed selector inventory.
- `analysis/live_state.json`, `analysis/valuation.json`, `analysis/reconciliation.json` — live state,
  USD valuation, custody reconciliation.
- `analysis/user_balances.json` — full 1,581 × 11 ledger scan (raw).
- `analysis/src/*.json`, `analysis/impl_e1fc_runtime.hex`, `analysis/wlUSDm*.hex` — runtime dumps.
- `poc/` — Foundry project (`src/Concord.sol`, `test/WMSpot.t.sol`, 13 tests).
- `ci/run.sh`, `ci/dump_state.py` — CI heavy job.
- `ci-out/`, `ci-artifacts/`, `ci-log.txt` — CI outputs and logs.
