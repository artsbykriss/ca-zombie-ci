# HashMix FIL (Filecoin FEVM) — L2 Phase-2 deep dive

**Date:** 2026-10-15 · **Chain:** Filecoin FEVM (chain id 314) · **Status:** read-only; fork PoC only (Foundry on a live fork); no mainnet transactions.

**Verdict in one line:** a fresh, unprivileged attacker can extract **$0.00** live. The ~1,581.86 FIL held by the HashMix FIL V1 pool is fully accounted for as cWFIL holders' redemption claim (1,099.19 FIL, self-service) plus protocol reserves (482.68 FIL, controlled by the `feeCollector` EOA); every other value-moving function is gated (`feeCollector`, controller, or miner-certificate ownership). Proven by a 27-test Foundry fork suite: all 20 attacker paths revert, and a full sweep of all 46 pool + 33 controller selectors from a fresh attacker yields no FIL.

---

## 1. TL;DR

| Target | Live custody (FIL) | Unprivileged extractable | Why closed | Latent risk |
|---|---|---|---|---|
| HashMix FIL **V1 pool / cWFIL** `0x587A7eaE9b461ad724391Aa7195210e0547eD11d` | **1,581.864473** (cash) = holders 1,099.186237 + reserves 482.678236 | **0 FIL** | `_reduceReserves`/`_addReserves`/`_setReserveFactor`/`sweepToken` all `require(msg.sender == feeCollector)`; `borrowBehalf`/`repayBorrowBehalf` `require(msg.sender == controller)`; `updateFeeCollector` `require(msg.sender == controller)`; controller admin-gated (`OnlyAdmin`) + `initialize` re-init blocked; `borrow` requires ownership of a miner-certificate NFT; forged EIP-2612 permits revert | feeCollector EOA key compromise → drain 482.68 FIL reserves + sweep stray ERC-20s; ProxyAdmin owner EOA / controller admin multisig could upgrade or redirect feeCollector |
| HashMix FIL **V2 pool / cWFIL** `0x85e77391C3dDe4fee572A79CFef7f710c7476f82` | **241.096296** cash + **560.571822** loans outstanding = 801.668118 claim | **0 FIL** | same Compound-fork gating (`_reduceReserves`/`sweepToken`/`updateFeeCollector` revert for attacker, fork-verified) | V2 holders can only redeem the 241.10 FIL cash; 560.57 FIL depends on SP loan repayment |
| Controller `0xFA33F386…` (proxy → impl `0xD3A8DCba…`) | 0 FIL | **0 FIL** | `setAdmin`/`setFeeCollector`/`extract`/`config`/… → `OnlyAdmin()`; `borrow(loan,amount)` → `NotAllowed()` unless caller owns the loan NFT; `initialize` reverts (already initialized); unknown selectors hit a **no-op fallback** | admin = timelock/multisig `0x358Cc936…`; proxy admin = `0x13ce9eB1…` (owner EOA `0x06A4c652…`) |
| 7 sibling pool instances (V2 generation) | 0 FIL | 0 FIL | empty | — |

**Total live extractable by a fresh unprivileged attacker right now: $0.00 (high confidence).**

At FIL = $1.095 (CoinGecko, 2026-10-15): the 1,581.864 FIL the triage flagged is worth **$1,732.14**, of which **$1,203.61 is holders' redeemable claim** (H-O) and **$528.53 is protocol reserves** (P). Including V2, the whole protocol's live on-chain value is **≈ 1,822.96 FIL ≈ $1,996.14** in cash + 560.57 FIL in loans.

---

## 2. What the target actually is (correcting the corpus)

- The triage row (`l2-triage-c`, slug `hashmix-fil`) listed custody `0x587A7eaE9b461ad724391Aa7195210e0547eD11d` with 1,581.864473 FIL and noted "Filecoin pool holds ~1.6K FIL (~$1.7K); residual staking claims; API dead". **Confirmed on-chain.**
- **It is NOT "stFIL" and NOT HashMix's miner-locked FIL.** The contract is the **HashMix FIL V1 liquid-staking pool**, which is *also* the cWFIL ERC-20 (`name()="cWFIL"`, `symbol()="cWFIL"`, 18 decimals, `underlying()=0x0` → **native FIL**). HashMix's own docs: *"The cWFIL token address is 0x587A7eaE9b461ad724391Aa7195210e0547eD11d"* (hashmix.gitbook.io/hashmix-fil-liquid-staking/liquidity-token).
- **stFIL (`0x3C3501E6c353DbaEDDFA90376975Ce7aCe4Ac7a8`) is a different protocol** (STFIL DAO, April 2024 police-seizure incident, ~2.27M FIL still at `f410falck…`). No on-chain linkage to HashMix (zero interactions; all 50 pool counterparties are EOAs). See `analysis/web-research.md` §0/§2.
- The earlier-noted "HashKing/FILLiquid proxy patterns" are unrelated to this target: the **pool is not a proxy** (EIP-1967 impl/admin slots = 0); only the *controller* is a proxy.
- Source is **not public** (Blockscout `is_verified:false`, Sourcify `match:null`, audited repo `HashMixProject/hashmix-fevm` 404). The runtime bytecode is an identifiable **Compound-v2 cToken fork (solc 0.8.18)** with native-FIL support, EIP-2612 permit, `borrowBehalf`/`repayBorrowBehalf`, a `feeCollector` role, and a `ReentrancyGuard`. We decompiled both the pool and the controller implementation locally (panoramix) and resolved every selector.

---

## 3. Live-state assessment (all reads on Filecoin FEVM, public keyless RPCs)

### 3.1 V1 pool `0x587A7eaE9b461ad724391Aa7195210e0547eD11d` (f02200067)

| Item | Value | Method |
|---|---|---|
| Native balance | **1,581.864473017953114284 FIL** | `eth_getBalance` |
| Runtime code | 22,338 bytes, unverified | `eth_getCode` |
| Proxy slots (impl/admin/beacon) | all 0 → **not a proxy** | `eth_getStorageAt` |
| `name()`/`symbol()`/`decimals()` | cWFIL / cWFIL / 18 | `eth_call` |
| `underlying()` | `0x000…000` (native FIL) | `eth_call` |
| `totalSupply()` | 102,637.961067478399973187 cWFIL | `eth_call` |
| `exchangeRateStored()` | 0.010709353782224222 | `eth_call` |
| `getCash()` | 1,581.864473017953114284 | `eth_call` |
| `totalReserves()` | **482.678236460184996056 FIL** | `eth_call` |
| `totalBorrows()` | 0.000000014207457 FIL (dust) | `eth_call` |
| `borrowIndex()` | 1.204951118210162 | `eth_call` |
| `reserveFactorMantissa()` | 5% | `eth_call` |
| `protocolSeizeShareMantissa()` | 2.8% | `eth_call` |
| `accrualBlockNumber()` | **3,678,820** (= last activity 2024-02-23) | `eth_call` |
| `controller()` | `0xFA33F3866e7eF32F79734BCC5e011d767F8E574b` | `eth_call` |
| `feeCollector()` | `0xD59060790f28EcD10Be2d23cEc88a39461A8d0cd` (**EOA**, protocol ops wallet) | `eth_call` |
| `interestRateModel()` | `0xE1DACa5a43DADd1b4db972d5d3a66eCF9960Eb81` (JumpRateModel) | `eth_call` |

**Exact value reconciliation:** 102,637.961067478399973187 × 0.010709353782224222 = **1,099.186236557782 FIL** (holders) + 482.678236460184996056 (reserves) = **1,581.864473017967 FIL** = `getCash()` (Δ 1.4e-11 FIL, rounding). So the pool's balance is fully attributed: nothing is unowned/stray.

**Holders (12, complete set, verified by `balanceOf`; sum = totalSupply):** largest `0x256fA19F…` 97,341.438245 cWFIL (94.84% → 1,042.46 FIL); then `0x106a9841…` 3,296.45, `0x7126063A…` 994.25, `0x3D01FeB1…` 499.25, and 8 more small holders. Full table in `analysis/onchain-discovery.md` §4.

**Activity (complete, 282 txs):** only `mint(uint256)` (172; 225,042.95 FIL in), `redeem` (56), `redeemUnderlying` (48), one cWFIL `transfer`, one `accrueInterest()` (2023-05-29), one `_reduceReserves(uint256)` (2023-05-26, from EOA `0xcF89b3A29499229E35d4fe71dFE54BEC2C1EbA48`, 60.45 µFIL). **Nothing since 2024-02-23**; `accrualBlockNumber` frozen at 3,678,820. Last tx: `redeem` by `0x0440fad1…`.

### 3.2 Controller `0xFA33F3866e7eF32F79734BCC5e011d767F8E574b` (proxy)

| Item | Value |
|---|---|
| Type | EIP-1967 TransparentUpgradeableProxy (2,112 B) |
| Implementation slot | `0xD3A8DCbada627FBE5E21eF224486Af4412c80aDF` (19,482 B; created 2023-08-15) |
| Proxy admin (slot) | `0x13ce9eB145a40b14B721570F0A91fc97656807DC` (ProxyAdmin; owner EOA `0x06A4c652…`) |
| `admin()` | `0x358Cc936fc3035A49E02d670Ec9b8E0061E97979` (timelock/multisig contract; `agree`/`execute(bytes32)`; last activity 2024-05-22) |
| `feeCollector()` / `pool()` | `0xD590…` / `0x587A…` ✓ |
| `version()` | 1 |
| Storage layout (decompiled) | slot 0/1 initializer+reentrancy flags (=1); `admin` @52; `feeCollector` @53; `pool` @55; minter @56; loanNFT @57; minter-registry @58; core @59 |

**Controller guard map (decompiled, `analysis/panoramix_controller_clean.txt`):**
- `setFeeCollector(address)`, `setAdmin(address)`, `extract(address,address)`, `config(...)` and 10 further state setters → `if adminAddress != caller: revert OnlyAdmin()`. Admin = the timelock/multisig.
- `borrow(uint256 loan, uint256 amount)` → calls `loanNFT.ownerOf(loan)` and `revert NotAllowed()` unless `owner == caller`; then reads loan terms from the certificate NFT. Fresh attacker owns no certificate ⇒ cannot borrow.
- `5a446a28(pool, newFeeCollector)` (admin-only) → `pool.updateFeeCollector(newFeeCollector)` — this is how the pool's feeCollector is changed.
- `initialize(governor, minter, lp_token)` → OpenZeppelin `Initializable` — reverts `'Initializable: contract is already initialized'`; not re-callable.
- Unknown/unmatched selectors → **no-op fallback** (verified: `0xdeadbeef` behaves identically).
- ReentrancyGuard on all money-path functions.

### 3.3 V2 pool `0x85e77391C3dDe4fee572A79CFef7f710c7476f82` (f02639857)

23,188-byte Compound-fork pool, `name/symbol=cWFIL`, created 2023-09-01, controller `0x10D81c7a…` (proxy; upgraded 2025-04-11 to impl `0x8f468C3e…`), same `feeCollector` EOA, IRM `0xC1032473…`. Live: **cash 241.09629576477042 FIL**, `totalBorrows` **560.5718224714605 FIL**, `totalReserves` 0.00007589 FIL, `totalSupply` 75,729.43577725258 cWFIL, `exchangeRate` 0.010585950286250716, `accrualBlockNumber` 4,868,638 (2025-04-11). Claim check: (241.0963 + 560.5718 − 0.00008)/75,729.4358 = 0.0105859 ✓.

### 3.4 Other addresses in the suite

`0x37878C62…` multisig (CertiK remediation) 0.01 FIL; `0x358Cc936…` timelock/multisig 0 FIL; deployer EOA `0x06A4c652…` 2.81 FIL; `0xcF89b3A2…` (constructor arg; historical reserve caller) 0.04 FIL; `0xD590…` feeCollector/ops 0.235 FIL; 7 sibling 22,190-byte pool instances 0 FIL; stFIL (other protocol) 0 FIL. Total HashMix-related ≈ 1,826.06 FIL (analysis/onchain-discovery.md §5).

---

## 4. The mechanism — exact call paths and why they are closed

**Privilege model (all verified in the deployed bytecode, not the audit):**

1. **Pool privileged role = `feeCollector` EOA `0xD590…`.** The pool has *no* `admin()`; every privileged pool function is `require(caller == feeCollectorAddress)`:
   - `_reduceReserves(uint256)` → pays reserves to the feeCollector (`doTransferOut(feeCollector, amount)` in the native branch). Reserves = **482.678 FIL**. (fork-verified: feeCollector can take 1 wei; attacker reverts)
   - `sweepToken(recipient, asset)` → sends any ERC-20 (not underlying) held by the pool to `recipient` (reverts `'CErc20::sweepToken: can not sweep underlying token'` for native).
   - `_addReserves(uint256)` (payable), `_setReserveFactor(uint256)`.
2. **`updateFeeCollector(address)` = `require(caller == controllerAddress)`**, and the controller's `setFeeCollector`/`5a446a28` are `OnlyAdmin` (timelock/multisig). So an attacker cannot re-point the privileged role.
3. **`borrowBehalf(address,uint256)` / `repayBorrowBehalf` = `require(caller == controllerAddress)`**; the controller's `borrow` requires the caller to own the miner-certificate NFT for that loan (`NotAllowed()` otherwise).
4. **User paths are value-neutral:** `mint(0){value:X}` (native-FIL convention — historical txs confirm `mintAmount=0`, FIL in `msg.value`) mints cWFIL at the exchange rate; `redeem`/`redeemUnderlying` burn the caller's cWFIL (revert `'ERC20: burn amount exceeds balance'` without shares) and pay FIL out at the same rate; `accrueInterest()` is permissionless but only updates rate accounting (borrows ≈ 0); `transfer`/`approve`/`permit` are standard ERC-20/EIP-2612 (forged permits revert with `ECDSA: invalid signature`); `getAllRates`/`getCash`/… are views. Reentrancy guards + CEI order on `redeem`/`redeemUnderlying`.
5. **No pause/blacklist on the pool**; it is simply dormant (last call 2024-02-23). No uninitialized proxy, no admin takeover, no sweeper for native FIL.

**Attacker economics:** there is no call sequence that pays the caller. Depositing (`mint`) is a loss; redeeming requires pre-existing cWFIL; the four payout functions (`_reduceReserves`, `sweepToken`, `borrowBehalf`→via controller, `extract`) all require roles the attacker doesn't have. Hence E-U = **0**, with the two positive controls (feeCollector drains reserves; multisig re-points feeCollector) proving the gates are *guards*, not broken functions.

---

## 5. Fork PoC (Foundry, live Filecoin fork)

**Files:** `poc/test/HashMixFIL.t.sol` (27 tests), `poc/foundry.toml`, vendored `poc/lib/forge-std`. The test suite forks Filecoin FEVM live (fallback list of keyless public RPCs: ankr → glif → chain.love → blockscout) and records the fork block in every test log.

**Result: 27/27 PASS** (local run at fork blocks ~6,457,123–6,457,181; CI run links in §7).

Test groups:
- **20 attacker-path tests** — every one reverts for the fresh attacker (`0x…A77ACc0`, no roles/positions): `_reduceReserves(1)` and `_reduceReserves(482.678 FIL)`, `sweepToken(attacker, WFIL|pool)`, `_addReserves(1)`, `_setReserveFactor(0)`, `updateFeeCollector(attacker)`, `borrowBehalf(attacker,1)`, `repayBorrowBehalf`, `redeem(1)` without shares, forged `permit` (r=s=v=0 and v=27), controller `setAdmin`/`setFeeCollector`/`extract`/`borrow`/`initialize`/`config`, and V2 `_reduceReserves`/`sweepToken`/`updateFeeCollector`.
- **2 exhaustive sweeps** — all **46 pool selectors** and all **33 controller selectors** called from the attacker (8 zero words of args): no FIL gain (`require(ATT.balance <= balBefore)`); the only successes are views, zero-amount no-ops (`redeem(0)`, `redeemUnderlying(0)`), `accrueInterest()`, and the controller's no-op fallback (proved by comparing with `0xdeadbeef`).
- **5 positive controls** — (a) `mint(0){value:1 FIL}` succeeds, attacker pays 1 FIL and receives cWFIL (deposit-only); (b) `accrueInterest()` permissionless; (c) the largest holder self-redeems 973.414 cWFIL for **10.424638998325516102 FIL** (H-O path works); (d) the `feeCollector` EOA can `_reduceReserves(1)` and receives 1 wei (P path works); (e) the timelock/multisig can `setFeeCollector` on the controller (P path works).

Gas: 30k–1.8M per call; **no flash loans/capital needed anywhere** because no path pays.

**Key fork numbers:** V1 pool cash 1,581.864473 FIL; reserves 482.678236 FIL; holders' claim 1,099.186237 FIL; attacker net gain 0 wei.

---

## 6. Verdict & residual risk

- **E-U (fresh unprivileged): $0.00 — high confidence.** All payout functions are role-gated; all user functions are value-neutral; the sweep of the entire selector surface produced no gain; the controller cannot be re-initialized or admin-taken-over; the pool is not a proxy and has no native-sweeper.
- **H-O (holders' self-service):** V1 1,099.186237 FIL (~$1,203.61) redeemable by the 12 cWFIL holders — demonstrated live in the fork. V2 claim 801.668118 FIL (~$877.83), of which only **241.096296 FIL (~$263.99) is liquid cash**; the remaining 560.571822 FIL depends on storage-provider loan repayment (borrowers hold miner-certificate NFTs).
- **P (privileged):** V1 reserves 482.678236 FIL (~$528.53) — withdrawable by the `feeCollector` EOA `0xD590…`; controller/proxy upgrades by the timelock/multisig `0x358Cc936…` and ProxyAdmin owner EOA `0x06A4c652…`; V2 reserves ~0.000076 FIL.
- **S (stuck):** none identified — every role address is a live EOA/contract; nothing is bricked.
- **Latent risk (not attacker-extractable today):** (1) the `feeCollector` EOA key compromise would drain the 482.68 FIL reserves and sweep stray ERC-20s; (2) the deployer EOA `0x06A4c652…` still owns the ProxyAdmin of the controller — an upgrade could change any controller rule (centralization risk flagged by CertiK GLOBAL-01/02); (3) dormant `redeem` accounting relies on the exchange rate; a large donation would only *raise* holders' rate (no extraction).

**Blockers to an exploit:** the `feeCollector`/controller roles, the miner-certificate NFT ownership requirement, and `Initializable`. Nothing is paused; the paths are simply closed by access control.

---

## 7. CI

- Workflow: `github.com/artsbykriss/ca-zombie-ci` → branch `hashmix-fil` → `poc.yml` (`forge test -vvv` + best-effort `ci/run.sh`).
- **CI run: <https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38692193294> — conclusion: success; `Suite result: ok. 27 passed; 0 failed` (forked live Filecoin FEVM from the GitHub runner).** Full log: `ci-log.txt`; artifacts: `ci-artifacts/result-hashmix-fil/` (includes `ci-out/live_state.json` — same values as §3: pool 1,581.864473 FIL, reserves 482.678236 FIL, feeCollector `0xD590…`, controller `0xFA33…`, block 6,457,968 — and `ci-out/selector_lookup.json` resolving the pool's gated selectors via openchain).
- `ci/run.sh` (best-effort, always exit 0): probes a working Filecoin RPC and exports `FIL_RPC_URL` to the forge step via `$GITHUB_ENV`, resolves all HashMix selectors via openchain, snapshots live pool/V2/controller state to `ci-out/live_state.json`.

---

## 8. Methodology & sources

- **Corpus first:** `zombie_hunt/FINDINGS.md` (row: HashMix FIL, Filecoin, $0.164M), `l2-triage-c` (slug `hashmix-fil`, custody `0x587A…`, 1,581.86 FIL), DefiLlama `hashmix-fil` (deadFrom 2026-01-01, last TVL 164,350 FIL on 2025-03-11).
- **Live reads:** Filecoin FEVM via keyless public RPCs (glif, chain.love, ankr, blockscout) + Filfox API + Blockscout v2 API. All values at blocks 6,457,049 / 6,457,953 / fork blocks 6,457,12x (Oct 14–15, 2026).
- **Decompilation:** `panoramix` on the pool runtime bytecode (22,338 B) and controller impl (19,482 B) — outputs `analysis/panoramix_pool_clean.txt`, `analysis/panoramix_controller_clean.txt`; selectors cross-checked via local ABI DB, 4byte and openchain (`analysis/pool_selectors_*.json`).
- **Fork PoC:** Foundry 1.7.1, `vm.createSelectFork` on live Filecoin FEVM; 27 tests; no mainnet transactions.
- **Web research:** HashMix docs/Medium/CertiK/GitHub/DefiLlama/Filfox — `analysis/web-research.md`; on-chain discovery — `analysis/onchain-discovery.md`.

### Caveats & limitations
- Contract source is private; conclusions rest on bytecode decompilation + live fork behavior (both consistent, and positive controls confirm the decompiled guard semantics).
- Panoramix pseudocode has cosmetic variable-name artifacts (e.g. event field labels); only guard/transfer lines were relied upon, cross-checked by fork tests.
- Fork tests ran against `latest` (no pinned block) — state can drift; each test logs its fork block.
- USD at FIL=$1.095 (CoinGecko 2026-10-15); the triage's $1,744.46 used $1.1037 (DefiLlama 2026-10-11).
- Filfox reports the pool "source verified" while Blockscout/Sourcify say unverified; the Filfox contract tab is JS-gated and the source was not retrievable — bytecode decompilation was used instead.

### Files index
```
hashmix-fil/
├── README.md                        # this file
├── summary.json                     # machine-readable verdict
├── analysis/
│   ├── web-research.md              # protocol history, STFIL disambiguation, addresses, audits
│   ├── onchain-discovery.md         # full address/holder/tx inventory + raw JSONs
│   ├── panoramix_pool_clean.txt     # decompiled V1 pool (guards)
│   ├── panoramix_controller_clean.txt # decompiled controller impl (guards, storage layout)
│   ├── pool_0x587A_code.hex, controller_impl_code.hex, v2_controller_impl_code.hex
│   ├── pool_selectors_resolved.json, pool_selectors_unknown_openchain.json, *_selectors.json
│   ├── pool_view_calls.json, pool_view_calls2.json, controller_view_calls.json
│   ├── guard_tests_ethcall.json, guard_tests2.json, controller_guard_tests.json
│   ├── filfox_pool_all_messages.json, controller_storage_slots.json, pool_holders_from_logs.json
│   └── (raw Blockscout/Filfox dumps from the discovery subagent)
├── poc/
│   ├── foundry.toml
│   ├── lib/forge-std/               # vendored
│   └── test/HashMixFIL.t.sol        # 27-test attacker PoC (fork)
├── ci/run.sh                        # best-effort selector lookup + live snapshot
├── ci-out/                          # CI outputs
├── ci-log.txt / ci-artifacts/       # fetched by ci-run.sh
└── summary.json
```
