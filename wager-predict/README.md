# O5 — Wager Predict (SpotEngine LMSR + LP Vault + USDW wrapper) · BSC

**Date:** 2026-10-25 · **Chain:** bsc · **Mode:** READ-ONLY on real chains (no tx signed/sent; `eth_call`/`eth_getBalance`/`eth_getCode`/`eth_getStorageAt` only). Fork PoC only. No secrets in this folder.
**Finding:** `O5` (pass6-recon OPEN; `base-bsc-fresh.md` row 1; the lane's "strongest fresh funded target"; the unread surface was the USDW wrapper impl).
**Status:** USDW impl now read (verified); every value-moving selector probed from a fresh EOA; live value re-measured.

---

## 1. TL;DR

| Target | Live value now | Unprivileged (E-U) extractable | Why closed | Latent risk |
|---|---|---|---|---|
| `SpotEngine 0x76b91e83…` (verified, LMSR curve engine) | **175,889.930252 USDW** (BSC block 129,703,926) | **$0** (medium confidence) | `initializeMarket`/`haltMarket` are `msg.sender == registry`; `resolveMarket`/`resolveVoidMarket` are `RESOLUTION_ROLE`; `exitForGraduation`/`consumeMigratedShares` are `GRADUATION_ROLE`; `claimWinnings` is caller-scoped + `nonReentrant` (shares zeroed before transfer); `buyShares`/`sellShares` route through the audited LMSRMath port and are structurally solvent (`seed ≥ ceil(b·ln2)`). | LMSR fixed-point/settlement math not fork-fuzzed; a rounding/overshoot bug would need a live market. |
| `USDW 0xe5eBE2AE…` (proxy → verified impl `0x7169d192…`) | totalSupply 202,545.410567 USDW | **$0** (high confidence) | `deposit` is permissionless but mints **≤ par** (Chainlink `quoteUsdwMint`, capped at 1.0, hard-depeg-reject); `redemption` **locks** USDW via `lockedLedger` which is **excluded from `balanceOf`** (no double-spend); `process` is `onlyOperator`; `cancel` is user-only; all config is `onlyAdministrator`. | Backing sits in **EOAs** (`depositRecipient 0x255E92b8…`, `redemptionSource 0x959b4A9A…`); `redemptionSource` holds ~$0.21 and has **no allowance** to USDW → USDW redemptions may be unprocessable (H-O/solvency risk, not E-U). |
| `Vault 0x88d163d4…` (LP vault) | 236.555097 USDW | $0 | `deposit/claimFees/requestWithdraw/withdraw` are `p.owner == msg.sender`; lending/write-off paths are `LEVERAGE_ROLE`. | role-key compromise (P). |

**Headline E-U = $0, confidence MEDIUM.** The lane's "unread USDW impl" is now read and is **sound** (Chainlink-priced, ≤1:1 mint, lock-ledger anti-double-spend, operator/admin gates). No unprivileged path to the ~$176k was found.

---

## 2. Total live extractable now

- **External-unprivileged (E-U): $0.00**.
- **Holder-only / self-service (H-O): ≈ $176.1k** — traders can `sellShares`/`claimWinnings` on settled markets; USDW holders can `redemption` → but see the redemption-source blocker below. LP-vault depositors can `withdraw` their own shares.
- **Privileged (P): ≈ $176.1k** — `RESOLUTION_ROLE`/`GRADUATION_ROLE`/`LEVERAGE_ROLE`/admin keys (gov Safe 2/3 `0xF39342C6…` per the lane) and the USDW admin/operator/issuer keys can settle, migrate, or configure. The USDW issuer (`ISSUER_ROLE`) can `mint`/`burn`/`lockTokens` via LockMint20.
- **Stuck / bricked (S): $0** measured, but the USDW redemption path looks under-funded (see §5).

---

## 3. What the target is

A fresh (deployed 2026-10-05) BSC prediction market: a Hanson **LMSR** curve engine (`SpotEngine`), an LP lending **Vault**, a `MarketRegistry`, a `ResolutionModule` (proposer bond + dispute window), a `FeeRouter`, an `InsuranceFund`, and a **USDW** stablecoin wrapper.

| Role | Address | Verified? |
|---|---|---|
| SpotEngine (holds the funds) | `0x76b91e83f2A12dc52E33f856eeA300E5B3A62c0c` | **yes** |
| LP Vault | `0x88d163d40D6BFe0Ad2b17f4a90A03053fEbf3014` | yes |
| USDW proxy | `0xe5eBE2AE0a036C955bfF58291826C50F7d670D43` | yes (proxy) |
| USDW impl | `0x7169d192b5e2add3268651cf598886af42518cd8` | **yes** (`USDW`) |
| PriceOracle proxy / impl | `0x5c3a3b430E44bD18Fd7f29Cb3Ec1948Bac542a9A` / `0x0c1337a5ec095c4a93886cb787b94c0d55727a72` | yes (`PriceOracle`, Chainlink) |
| MarketRegistry | `0x2D7E1000da132C46f20C7ba4f39F1BEF74F7adb4` | — |
| InsuranceFund | `0x3E3f937922Ed0a843C1566ce76723564aC2872Ab` | — |
| Gov Safe 2/3 (lane) | `0xF39342C6…` | — |

---

## 4. Mechanism — every value path and its gate

**SpotEngine (verified source, `wp_SpotEngine.sol`).** Live probes from `0x…dEaD` at BSC block 129,703,926:

| Call | Result for a stranger |
|---|---|
| `resolveMarket(0,0)` / `resolveVoidMarket(0)` | revert `Unauthorized(<RESOLUTION_ROLE>, 0x…dEaD)` |
| `exitForGraduation(0)` / `consumeMigratedShares(0,·)` | revert `Unauthorized(<GRADUATION_ROLE>, 0x…dEaD)` |
| `initializeMarket(0,1,1,0)` / `haltMarket(0)` | revert `OnlyRegistry` |
| `claimWinnings(0)` | revert `NotSettled(0)` (caller-scoped `_shares[id][msg.sender]`, zeroed before transfer, `nonReentrant`) |
| `buyShares/sellShares(0,…)` | revert `NotInitialized(0)` (LMSRMath; permissionless on a live market) |

Source confirms: `initializeMarket`/`haltMarket` `msg.sender == registry`; `resolveMarket`/`resolveVoidMarket` `onlyRole(RESOLUTION_ROLE) nonReentrant`; `exitForGraduation`/`consumeMigratedShares` `onlyRole(GRADUATION_ROLE) nonReentrant`; `claimWinnings` `nonReentrant` caller-scoped; solvency is structural (`seed ≥ ceil(b·ln2)`).

**USDW (verified source, `USDW.sol` + `LockMint20.sol`).**
- `deposit(backingToken, amt)`: permissionless, but `usdwOut = PriceOracle.quoteUsdwMint(...)` — Chainlink `latestRoundData` with staleness + depeg caps (`_quoteParWithDepeg` caps mint at par when depegged; hard-reverts beyond the hard threshold). **Cannot mint more than the stable's par value.** Backing is sent to `depositRecipient`.
- `redemption(payoutToken, amt, receiver)`: permissionless; `_lckAdd(msg.sender, amt)`; `LockMint20.balanceOf = super.balanceOf − lockedLedger`, and `_chkUnlck` enforces the unlocked balance on every transfer/burn → **a locked redemption cannot be double-spent or sold**.
- `process(requestId, executionCost)`: `onlyOperator`; burns the user's USDW and `safeTransferFrom(redemptionSource, receiver, payout)`.
- `cancel`: `msg.sender == r.user`. Config (`setTreasury/setPriceOracle/setDepositRecipient/setRedemptionSource/addInputStable/setVerifiers`) is `onlyAdministrator`; `LockMint20.mint/burn/lockTokens/unlockTokens` require `ISSUER_ROLE`.

---

## 5. Live-state assessment (BSC block 129,703,926; USDW priced at ~$1)

| Address | native | USDW | Notes |
|---|---|---|---|
| `SpotEngine 0x76b91e83…` | 0 | **175,889.930252** | collateral token is USDW (`usdc()==USDW`) |
| `Vault 0x88d163d4…` | 0 | 236.555097 | LP vault |
| USDW `totalSupply` | — | 202,545.410567 | `paused=false`; `treasury=0xB445A0A6…`; `priceOracle=0x5c3a3b43…`; `redemptionRequestNonce=2` |

- **Backing custody:** `depositRecipient = 0x255E92b8e79800349f137d5b8EA70c0B658fd397` (EOA) holds **203,882.85 aBnbUSDC** (`0x00901a07…`, 18dp). **But `isInputStable(aBnbUSDC) == false`** — the only approved input stable observed is **BSC USDC `0x8AC76a51…`**. `redemptionSource = 0x959b4a9Ad2dD1beBfD2579121325a75768C4D024` (EIP-7702-delegated EOA, 23-byte designator) holds **0.2139 USDC** and has **allowance 0** to USDW. So USDW redemptions currently have no funded source/allowance → a **solvency/H-O blocker**, not an E-U path.
- No allowance from the issuer wallet or the redemption source to USDW, the SpotEngine, or anyone else for the backing tokens.
- Prices: USDW ~$1; backing token aBnbUSDC ~$1 (not approved as input).

---

## 6. What an attacker can / cannot do

**Cannot (proven):** resolve/void a market; migrate a market; claim another user's winnings; halt/initialize a market; mint USDW above par; redeem USDW without the operator; double-spend a locked redemption; pull the issuer's backing; change any USDW/engine parameter; upgrade.

**Can (fair/own capital):** `buyShares`/`sellShares` on a live market (LMSR; pay/receive fair value); `claimWinnings` on a settled market they hold; `deposit` approved stables to mint USDW at ≤par; `redemption` (lock) their own USDW; `cancel` their own request.

**Cost/preconditions for the only theoretical drains:** none for an unprivileged actor; the LMSR is structurally solvent and all settlement/migration paths are role-gated.

---

## 7. PoC / fork verification

`poc/` — Foundry project (vendored `forge-std`), forks BSC via `BSC_RPC_URL` (keyless fallback `https://bsc-rpc.publicnode.com`), fresh unprivileged EOA `0x…dEaD`, no impersonation. Asserts each privileged selector reverts with its exact error and the SpotEngine USDW balance is unchanged after an attacker call sweep. `ci/run.sh` writes `ci-out/live_state.json`. See `ci-log.txt` / `summary.json` for the CI run URL.

---

## 8. Verdict, residual & latent risk, blockers

**Verdict: E-U = $0 (MEDIUM confidence).** The previously-unread USDW impl is sound (Chainlink-priced ≤1:1 mint, lock-ledger anti-double-spend, operator/admin gates) and the LMSR engine is role-gated with structural solvency. No unprivileged path to the ~$176k was found.

**Residual / latent risk (not E-U):**
- **LMSR fixed-point:** not fork-fuzzed here (needs a live, funded market id); a `mulDiv` overshoot would be the only remaining E-U class — low likelihood given the audited port and the `seed ≥ b·ln2` invariant.
- **USDW redemption appears un-funded:** `redemptionSource` holds ~$0.21 with no allowance, and the 203.9k "backing" is a token that is **not** an approved input stable → USDW holders may be unable to redeem. This is a **holder/solvency** risk (H-O), not an attacker gain.
- **P:** gov Safe 2/3 + USDW admin/operator/issuer keys.

**Blockers:** market ids could not be enumerated cheaply (no `marketCount`/`nextMarketId` getter); the lane's address set was used for the role/governance contracts. Point-in-time 2026-10-25; re-read live state before acting. Nothing here is an instruction to transact.

---

## 9. Methodology, sources, caveats, files

**Method.** Pulled the verified `SpotEngine`/`Vault`/`USDW`/`PriceOracle` sources via Etherscan V2 `getsourcecode` (chainid 56); read `USDW.sol`, `LockMint20.sol`, `PriceOracle.sol`, `SpotEngine.sol`; read live state (`balanceOf`, roles, custody, allowances); probed every mutating selector from a fresh EOA with `eth_call`; enumerated the depositRecipient's ERC-20 holdings via `alchemy_getTokenBalances`.

**Key on-chain evidence (address + block + call).**
- `SpotEngine(0x76b91e83…).balanceOf(USDW)` = 175,889.930252 (block 129,703,926).
- `USDW.totalSupply()` = 202,545.410567; `priceOracle()` = `0x5c3a3b43…` (verified `PriceOracle`); `depositRecipient()` = `0x255E92b8…`; `redemptionSource()` = `0x959b4A9A…`.
- `resolveMarket(0,0)` from `0x…dEaD` → `Unauthorized(<RESOLUTION_ROLE>,0x…dEaD)`; `initializeMarket` → `OnlyRegistry`; `claimWinnings(0)` → `NotSettled(0)`.
- `isInputStable(0x8AC76a51…)==true`, `isInputStable(0x00901a07…)==false`; allowance(issuer→USDW)==0.

**Sources.** Etherscan V2; keyless public RPCs; DefiLlama prices; `base-bsc-fresh.md` (lane) for the role/governance address set.

**Caveats & limitations.** (1) LMSR not fork-fuzzed (no cheap market-id enumeration). (2) H-O value bounded by balances. (3) Point-in-time. (4) `forge-std` ships its own public placeholder URL — not a secret.

**Files.**
- `README.md` (this), `summary.json`
- `analysis/` — `collect_live_state.py`, `probe_results.json` (live selector probes)
- `poc/` — Foundry project; `ci/run.sh`; `ci-out/`; `ci-log.txt`
