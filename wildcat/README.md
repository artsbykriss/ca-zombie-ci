# Wildcat Protocol V2 — borrower-controlled credit markets on Ethereum + Plasma (fresh Plasma deployment)

**Date:** 2026-10-25 · **Chains:** Ethereum (1), Plasma (9745) · **Status:** read-only research; PoC
fork-verified only; **no mainnet transaction was ever sent/signed**. This folder is self-contained.

**Scope:** the pass-7 `fresh-deep` lane flagged Wildcat as a fast-growing fresh deployment
(DefiLlama TVL ≈ **$14.51M** at 2026-10-25, `+382 %/7 d`; Ethereum **$14.40M** + Plasma **$17.4k** held)
and asked whether the protocol's **"borrower-controlled terms"** are truly by design (not extractable by an
unprivileged attacker) or whether the **Plasma deployment** exposes an unprivileged path.

**Answer:** the terms *are* the design, and there is **no unprivileged extraction path** on either chain.
An external attacker with no roles and no privileges can take **$0**. The value at risk is lender credit
risk (holders) and borrower privilege (the borrower can drain the market it controls) — both by design.

---

## 1. TL;DR

| Target | Live extractable (external, unprivileged) | Why closed | Latent / non-E-U risk |
|---|---|---|---|
| Wildcat V2 — **Plasma** (4 markets, `0x9A0B…`, `0x74C7…`, `0xFf60…`, `0xa460…`) | **$0** | Every value path is `onlyBorrower`, pays the *named* account, or pays the configured fee recipient. The two open markets hold $17,361.47 (Rhinofi) and $0 (seve1). | Borrower (a Gnosis Safe / 7702 smart-account) can `borrow()` the market's remaining assets (P); lenders bear that credit risk (H-O). |
| Wildcat V2 — **Ethereum** (89 registered markets, arch `0xfEB5…`) | **$0** | Identical V2 code, same gating; ~$14.40M held across 89 markets, all with registered/privileged borrowers. | Same as above; protocol-fee recipient is `isRecipientOrOwner`-gated. |
| Shared infrastructure (ArchController, HooksFactory, Sentinel, Escrow, FeeRecipient) | **$0** | Owner / registered-borrower / recipient gated; the two permissionless calls (`pushProtocolFeeBipsUpdates`, `collectFees`) move value only to protocol-controlled addresses. | SphereX engine + arch-controller owner are P (can censor/upgrade the protection layer). |

**Total live extractable now: $0.00. Confidence: HIGH** (deployed source read end-to-end + 15 fork tests
on the live Plasma state). The honest headline is $0 because the mechanism *is* the product: Wildcat is an
undercollateralised private-credit escrow where the **borrower** sets terms and can withdraw what it
borrows, and lenders knowingly take that counterparty risk.

---

## 2. The mechanism, in exact terms

Wildcat V2 markets are **non-upgradeable** `WildcatMarket` contracts (immutable borrower/asset/hooks/factory,
`version() == "2"`). The design, verbatim from the audit README and the project's own "Known Issues" doc:

> "the reserve ratio … can be zero, enabling truly uncollateralised markets … the protocol itself is entirely
> hands-off when it comes to any given market … it can't force a borrower to repay assets to a market, and it
> can't stop the borrower from making APR/capacity changes … **if a borrower fails to repay their debt for any
> reason, lenders will inevitably lose funds.** If the borrower is malicious, they can hurt lenders in a variety
> of ways, including … adding themselves as a lender in order to withdraw beyond the borrow limit on a market
> they intend to default on; slowly reducing the APR by 25 % every two weeks …"

Read end-to-end from the **verified deployed source** (`WildcatMarket` + `WildcatMarketBase` +
`WildcatMarketConfig` + `WildcatMarketToken` + `WildcatMarketWithdrawals` + `WildcatSanctionsSentinel` +
`WildcatSanctionsEscrow` + `OpenTermHooks`/`BaseAccessControls`/`MarketConstraintHooks` + `HooksFactory` +
`WildcatArchController` + `FeeMath` + `MarketState`; see `analysis/src/`):

* **`borrow(amount)`** — `onlyBorrower`, capped at `borrowableAssets()` = `totalAssets − liquidityRequired`.
  This is the only path that moves `asset` **out** to a non-protocol address on demand.
* **`closeMarket()` / `rescueTokens()` / `setMaxTotalSupply()` / `setAnnualInterestAndReserveRatioBips()`** —
  `onlyBorrower` (`rescueTokens` additionally forbids the market asset).
* **`setProtocolFeeBips()`** — `msg.sender == factory` (the arch-owner-approved `HooksFactory`).
* **`collectFees()`** — permissionless, but pays the immutable `feeRecipient` (never the caller).
* **`executeWithdrawal(account, expiry)` / `executeWithdrawals([...])`** — permissionless, but pays
  `account` (or that account's sanctions escrow) — **no redirect**.
* **`queueWithdrawal` / `queueFullWithdrawal` / `repay` / `repayAndProcessUnpaidWithdrawalBatches`** —
  permissionless, but operate only on the caller's own balance / pull the caller's own funds (a gift).
* **`nukeFromOrbit(account)`** — permissionless, but requires the account to be Chainalysis-sanctioned and
  routes to that account's escrow.
* **`_depositUpTo`** — mints market tokens 1:1 against a real `transferFrom`; gated by the market's
  `OpenTermHooks` (`onDeposit`), which for the live Plasma markets accepts the permissionless
  `OpenAccessRoleProvider` credential **but** enforces a per-market minimum deposit. A deposit is a
  purchase, not an extraction.
* **Accounting is internal, not balance-derived:** `scaleFactor` (a ray) is advanced *only* by interest and
  delinquency accrual (`FeeMath.updateScaleFactorAndFees`); `totalAssets()` is only used as a *cap* on
  borrows/fees, never as the share price. Donation / first-depositor share-inflation attacks therefore do
  not exist, and every conversion floors (`MathUtils.mulDiv`), so round-trips never profit.
* **Access-control hooks** (`OpenTermHooks`) gate `onDeposit`/`onTransfer`/`onQueueWithdrawal`; credentials
  come from borrower-registered role providers (`OpenAccessRoleProvider`, access-token providers, …).

### 2.1 "Borrower-controlled terms" — by design, not E-U

A borrower can, on the market it deployed: borrow up to the reserve limit, lower the APR (25 %/2 weeks
without penalty, else a temporary reserve-ratio bump enforced by `MarketConstraintHooks`), close the market,
and (via the hooks) block/allow lenders. All of that is **explicitly intended** and is *not* reachable by an
unprivileged party: markets are deployed only by **arch-controller-registered borrowers**
(`HooksFactory.deployMarket` → `isRegisteredBorrower(msg.sender)`), and the borrower is immutable. The only
"victim" of a malicious borrower is a **lender** — a self-selected counterparty, i.e. **H-O/P, not E-U**.

---

## 3. Live-state assessment

**Plasma fork block 36,011,221** (`0x2258bd5`) · **Ethereum snapshot ≈ block 26,272,008** · USDT0 on Plasma
is the 6-dec LayerZero OFT `0xB8CE59FC…5ebb` (a `TransparentUpgradeableProxy`).

### 3.1 Deployments (Plasma, chainId 9745) — all verified on the Plasma explorer (Etherscan-V2 chainid 9745)

| Contract | Address | Notes |
|---|---|---|
| WildcatArchController | `0xdb2e0DE97d6d96aa56754635704a4273E0F348ae` | `owner()` = `0xC15bE5214978d1fc509ECdd4f9D5BC067C94D9Ae` (also a registered borrower) |
| HooksFactory | `0xB46bae25AC6D23148531ed1853a8881FD842E517` | only registered controllers; `deployMarket` needs `isRegisteredBorrower` |
| WildcatSanctionsSentinel | `0x37064895ba2C1e269EAF7FF32564818d08903f5B` | Chainalysis list `0x38056F7f…` |
| WildcatFeeRecipient | `0x437e0551892C2C9b06d3fFd248fe60572e08CD1A` | `releaseERC20Fees` = recipient/owner only |
| SphereXEngine | `0x931fe4a88e1C1f1A7402dF6A40988f38503f1061` | arch-controller-operated runtime guard |

Registered borrowers (4): `0x5b15F94E…` (EOA), `0xE6181517…`, `0x5Af8dEcb…` (**SafeProxy**), `0x16d9ba63…`
(**SafeProxy**). Registered controllers (1): the HooksFactory. Blacklisted assets: none.

### 3.2 The four Plasma markets

| Market | Name | `asset` | held (`totalAssets`) | `totalSupply` | APR | reserve | closed | borrower | hooks |
|---|---|---|---|---|---|---|---|---|---|
| `0x9A0BA9278284659194157C476010bCFEbeB21794` | Rhinofi USDT0 | USDT0 | **17,361,466,198** = **$17,361.47** | 1,264,500,193,398 | 10.00 % | 0 | no | `0x5Af8dEcb…` (Safe) | OpenTermHooks `0xf6Af2ae9…` |
| `0x74c7861C3E706e7299654F89A3C0091184Aa10f0` | seve1 USDT0 | USDT0 | **0** | 50,434,877,046 | 7.00 % | 0 | no | `0x16d9ba63…` (Safe) | OpenTermHooks `0xc5a61cee…` |
| `0xFf604FC5f725c107B0bd15974F03F3De2849500e` | Wintermute USDT0 | USDT0 | 60 wei | 0 | 0 | 100 % | **yes** | `0x5b15F94E…` (EOA) | OpenTermHooks `0x506d41a8…` |
| `0xa460c09c1CcFC655F048B2ebfD95b3D5285a1Faf` | USDT0 USDT0 | USDT0 | 0 | 0 | 0 | 100 % | **yes** | `0x5Af8dEcb…` (Safe) | OpenTermHooks `0xf6Af2ae9…` |

* `hooks()` is a packed `HooksConfig` uint256: address in the high 160 bits; enabled-hook flags
  `{95 Deposit, 94 QueueWithdrawal, 92 Transfer, 86 SetAnnualInterestAndReserveRatioBips}` → matches
  **`OpenTermHooks`** (`version()` verified on-chain). Each market's `getHookedMarket()` returns
  `isHooked=true, transferRequiresAccess=true, depositRequiresAccess=true, minimumDeposit=1,000 USDT0`.
* Rhinofi: `borrowableAssets() = 17,354,405,898` (~$17,354) → the borrower can withdraw all but ~$7.06
  (`coverageLiquidity = accruedProtocolFees = 7,060,901`). No pending/unpaid withdrawal batches; no unclaimed
  paid withdrawals (`state.normalizedUnclaimedWithdrawals == 0`).
* seve1: holds **$0**, `borrowableAssets() = 0`; ~$50.4k of lender claims outstanding (fully borrowed).

### 3.3 Ethereum (89 registered markets; the V2 arch-controller also lists legacy V1 markets)

Held ≈ **$14,397,110** across 89 markets (top: `0x4A8364A3…` $4.96M, `0x5Ab22e9C…` $4.51M,
`0x2F3E0b07…` $2.26M — USDe / stablecoin markets). **13 of 34 distinct borrowers are contracts**: 12 are
Gnosis-Safe proxies (171 B) and one is an **EIP-7702 delegated EOA** (`0x40a42340…`, code
`0xef0100‖0x63c0c19a…`, delegate = `EIP7702StatelessDeleGator`), i.e. a MetaMask-delegation smart account.
All are privileged signers; none is a permissionlessly-driveable contract. Spot-checked V2 markets return
`version()=="2"`; the deployed `WildcatMarket` source is identical to the Plasma one (same compiler inputs).

### 3.4 Deployed-code identity

The market source read here is the **Etherscan/Plasmascan-verified** deployed source (chainid 9745
`getsourcecode` returns `ContractName = WildcatMarket`, 224,916 B bundle; the hooks instances return no
source — they are `OpenTermHooks` clones, confirmed by `version()`). `ci/run.sh` additionally clones the
audited `wildcat-finance/v2-protocol` repo, compiles it with the deployed compiler settings
(`viaIR=true, optimizer=true, runs=200, bytecode_hash=none`) and compares runtime-bytecode keccaks against
the deployed addresses (result in `ci-out/bytecode-check.txt`).

---

## 4. What an attacker can / cannot do (exact call paths)

| Call (as an unprivileged attacker) | Result | Gate |
|---|---|---|
| `borrow(x)` | **revert `NotApprovedBorrower()`** (0x02171e6a) | `onlyBorrower` (immutable `borrower`) |
| `closeMarket()` | revert `NotApprovedBorrower()` | `onlyBorrower` |
| `rescueTokens(asset)` | revert `NotApprovedBorrower()` (borrower: `BadRescueAsset()`) | `onlyBorrower` + asset check |
| `setMaxTotalSupply` / `setAnnualInterestAndReserveRatioBips` | revert `NotApprovedBorrower()` | `onlyBorrower` |
| `setProtocolFeeBips` | revert | `msg.sender == factory` |
| `nukeFromOrbit(attacker)` | revert `BadLaunchCode()` | must be Chainalysis-sanctioned |
| `queueWithdrawal(1)` (0 balance) | revert (underflow / `NullBurnAmount`) | own balance |
| `executeWithdrawal(thirdParty, expiry)` | reverts for any non-existent batch; **for a real batch, pays `thirdParty`** | none (but no redirect) |
| `collectFees()` | succeeds; **pays `feeRecipient`**, attacker gains 0 | none (pays fixed recipient) |
| `repay(1)` | succeeds; pulls 1 from the **caller** (a gift) | none |
| `deposit(≥minDeposit)` | succeeds (open credential); mints market tokens 1:1 — a purchase, not extraction | OpenTermHooks + minDeposit |
| `deployMarket(...)` | revert `NotApprovedBorrower()` | `isRegisteredBorrower` |
| `HooksFactory.pushProtocolFeeBipsUpdates(...)` | permissionless, but writes the arch-owner-configured fee to markets | fee → `feeRecipient` |
| `FeeRecipient.releaseERC20Fees/releaseETH` | revert | recipient/owner only |

**Net: no unprivileged call increases the attacker's balance of any market asset.** The only permissionless
calls that move `asset` are `collectFees` (→ fee recipient) and `executeWithdrawal` (→ the named account).

---

## 5. PoC / fork-verification

Foundry project `poc/` (vendored `forge-std`; Plasma fork at block **36,011,221**, Ethereum sub-fork for
cross-checks). **15/15 tests pass.**

| Test | Proves |
|---|---|
| `test_deployed_market_and_hooks_are_v2_openterm` | `version()=="2"`, borrower/factory/arch/sentinel/feeRecipient/asset/hooks all as cited |
| `test_attacker_cannot_borrow` / `_close_market` / `_set_terms` / `_rescue` / `_nuke_unsanctioned_account` | all borrower-only paths revert for an attacker |
| `test_attacker_cannot_queue_or_execute_withdrawals` | zero-balance queue reverts; non-existent batch reverts |
| `test_executeWithdrawal_pays_named_account_not_caller` | **storage-fabricated real batch**: attacker calls the permissionless `executeWithdrawal(lender, expiry)`; the **lender** receives the 500 USDT0, the attacker gains 0 |
| `test_collectFees_pays_feeRecipient_not_caller` | attacker calls `collectFees()`; feeRecipient is paid, attacker gains 0 |
| `test_repay_is_a_gift_from_the_caller` | `repay` debits the caller, credits the market |
| `test_deposit_is_open_but_is_not_extraction` | minDeposit enforced; a deposit is a 1:1 purchase |
| `test_borrower_can_borrow_the_whole_market` | **the privilege is real**: the borrower can `borrow()` ~$17,354 out of the market (P, by design) |
| `test_arch_controller_is_owner_gated` / `test_hooks_factory_only_registered_borrowers_deploy` | shared infra is role-gated |
| `test_ethereum_deployment_is_the_same_code` | Ethereum markets are the same V2 code |

Run ID / artifact: see `ci-log.txt` and `ci-out/`. **Local runs are recorded in `analysis/`; the recorded CI
run URL is in `summary.json` (`poc.ci_run_urls`).**

---

## 6. Verdict and residual risk

* **E-U: $0.00** (high confidence). No external unprivileged path to any market's underlying asset on
  Ethereum or Plasma, at the cited block.
* **H-O (holder-recoverable):** the markets' held assets ($17,361.47 Plasma + ~$14.40M Ethereum) are
  redeemable by **lenders** through `queueWithdrawal`/`executeWithdrawal`, subject to borrower repayment.
* **P (privileged):** the borrower can `borrow()` up to the reserve limit and change terms; the arch-controller
  owner can register/blacklist; the SphereX operator can update the engine; the fee recipient's owner can
  move protocol fees. All are intended roles, not exploits. On Plasma the sanctions list is a **Wildcat-deployed
  copy** of the Chainalysis list (`WildcatCopyOfChainalysisList 0xfEB516d9…` behind `ChainalysisProxy
  0x38056F7f…`, both live and returning `false` for unsanctioned accounts) — a **freeze/censorship** capability
  (P), never a way to move funds.
* **S:** none material (the 60 wei in the closed Wintermute market is dust).
* **Latent:** a compromised borrower key (12 Safes + EOAs + one 7702 smart account) or a compromised Circle/
  Wildcat key is the real risk, and it is a key-management risk, not a code bug.

### Blockers / limitations
* The `v2-protocol` repo bytecode comparison may report `match=NO` if the repo tip differs from the deployed
  commit; the **authoritative** source is the explorer-verified deployed bundle (read here directly).
* Plasma `getRegisteredMarkets()` returned 4 markets at the fork block; the set can grow (a registered
  borrower may deploy more).
* USD figures use DefiLlama/CoinGecko at 2026-10-25; USDT0 priced ≈ $1.00.

---

## 7. Methodology & sources; caveats; files

**Method.** (1) Enumerated markets on both chains via `WildcatArchController.getRegisteredMarkets()`;
(2) pulled the **verified deployed source** for the market + all V2 components from Etherscan-V2 (chainid
9745 & 1) and read them end-to-end; (3) read the project's own audit README, "Known Issues", "Core Behaviour",
"Scale Factor", hooks and Sentinel docs; (4) confirmed every deployed role/hook/config on-chain at a pinned
block; (5) proved the gating with a Foundry fork PoC (15 tests); (6) compared compiled repo bytecode to the
deployed code in CI.

**Sources.** `docs.wildcat.finance` (llms.txt + per-page `.md`); `github.com/wildcat-finance/v2-protocol`;
`github.com/code-423n4/2024-08-wildcat` (README + Known Issues); Etherscan-V2 `getsourcecode` (chainids 1,
9745); public RPCs `rpc.plasma.to`, `ethereum-rpc.publicnode.com`; DefiLlama `api.llama.fi/protocol/wildcat-protocol`.

**Caveats.** All work read-only; the exploit is executed only on an in-memory fork. Point-in-time
2026-10-25 — re-read live state before acting. Web/docs content treated as untrusted data.

**Files.** `README.md` (this) · `summary.json` · `analysis/markets_state.json` (all 93 markets) ·
`analysis/src/plasma_market_bundle/` (verified deployed source) · `analysis/src/*.json` (raw explorer
responses) · `poc/` (Foundry, 15 tests) · `ci/run.sh` + `ci/live_state.py` (CI heavy job) · `ci-out/`,
`ci-log.txt`, `ci-artifacts/` (CI results).
