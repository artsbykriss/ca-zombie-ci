# Bril Finance (BSC) — L2 Phase-2 deep dive: live extractability

**Date:** 2026-10-14 · **Chain:** BNB Smart Chain (56) · **Status:** read-only; no mainnet transactions.
All state-changing PoC runs happen on a local/CI **fork** only. No secrets in this folder.

**Triage row (L2-Triage-A):** Bril Finance, Binance, LIVE-FUNDED **$98,016** (medium confidence),
key contract: strategy factory `0xfaa2e7c69F7F34195D3Ef6CF98B6B009A6A07F30`. Factory holds $0; the value is in
the strategy-managed vaults (not enumerated in Phase 1).

---

## 1. TL;DR

| Target | Live value (this run) | Unprivileged extraction now? | Why / gate |
|---|---|---|---|
| 48 Bril-managed ICHI vaults (77 strategy clones) | **$114,709** (my on-chain pricing at BSC block 127,496,806; DefiLlama $98,016) | **No — E-U ≈ $0** | Funds are user-held vault shares; vault owner = Bril Gnosis Safe; `vault.rebalance()` is `onlyOwner`. The one permissionless path (`strategy.rebalance()` / `performUpkeep`) executes `vault.rebalance(..., swapQuantity=0)` — a **no-trade re-range** — and requires the strategy to be an enabled Safe module. |
| Ready-to-rebalance set (19 strategies) | $38,704 | **No — E-U ≈ $0** | Of the 19, only **8 are enabled Safe modules** (the rest revert `GS104` at execution); those 8 manage vaults worth **$419.79 total**. |
| Bril Gnosis Safe itself | ~$1,324 (USDT/WBNB/CAKE/BTCB dust) | **No** | All 178 modules are fixed-code managers; the strategies can only make the Safe call `vault.rebalance(...)`. No arbitrary-call module found. |
| Wrapper staking contracts (user shares) | (part of vault TVL) | **No** | Verified MasterChef-style code; `withdraw`/`emergencyWithdraw` are self-service; owner can only recover non-staked/non-reward tokens. |

**Headline: external unprivileged attacker can extract ≈ $0 live (confidence: medium-high).**
Residual/latent: the permissionless keeper path is real and does move vault ranges; a *future* implementation that
sets `swapQuantity ≠ 0`, or a much shallower pool vs vault-value ratio, would change this. The economically
relevant bound is quantified in §6.

---

## 2. Architecture (verified on-chain)

```
RebalancerFactory (TransparentUpgradeableProxy) 0xfaa2e7c69F7F34195D3Ef6CF98B6B009A6A07F30
  admin (EIP-1967): 0xe02768682010984450a36f24eccdb4a1eb0ce869   impl: 0x6f85eb17955257a39fd78692f6884ebe6531fd8b
  ├─ 9 strategy types (impl contracts, UNVERIFIED bytecode)   ── 77 EIP-1167 clones ("strategy instances")
  └─ 48 ICHI vaults (verified ICHIVault, e.g. 0x2b1E2aaBc2dD09ec9E2e667e09705bEC5bd9C40D)
        every vault owner() = 0x05cC3CA6E768a68A7f86b09e3ceE754437bd5f12  (Bril Gnosis Safe)
        every strategy owner()/gnosis() = the same Safe
        every strategy is an ENABLED MODULE of the Safe
```

* Strategy implementation ABI matches ICHI's "Rebalancing / YieldIQ" family (`vaultAmounts()`, `vaultSummary()`,
  `simulate()`, `checkUpkeep/performUpkeep`, `poolPrices()`, `twapFast/twapSlow`, `dRebalanceInitiation`,
  `executionDelay`, `minTimeBetweenRebalances`). The clones are **unverified** on BscScan and Sourcify.
* The strategies do not custody anything: all 77 hold **0 vault shares** and (checked) 0 of the major tokens.
* The strategies rebalance vaults by calling `safe.execTransactionFromModule(vault, 0, vault.rebalance(...), 0)`
  — i.e. the **Safe** (the vault's owner) is the `msg.sender` of `vault.rebalance(...)`. This is the only action
  the observed strategy code can make the Safe perform.
* ICHI vault source (verified at `0x2b1E2aaB…`): `rebalance(int24,int24,int24,int24,int256)` is `onlyOwner`;
  `deposit()`/`withdraw()` are permissionless (self-service); `deposit0Max/deposit1Max = 0` on most vaults
  (deposits closed, withdrawals open).
* Bril Safe: Safe v1.3.0 (`masterCopy 0x3E5c63644E683549055b9Be8653de26E0B4CD36E`), 8 owners, threshold 3,
  nonce 1283, **178 enabled modules** (paginated enumeration). 77 are the factory strategies; 129 are other
  manager clones pointing at other ICHI vaults outside the Bril factory set.
* Share holders: 150 positive balances across the 48 vaults; the Safe, the factory and all strategies hold 0.
  Large holders include verified "Wrapper" staking contracts (MasterChef-style) and EOAs; several small vaults
  are 100 % held by a single EOA (`0x4403b424ea406b9fbb8bf1169e8447f658cd776b`, an EOA with no code).

---

## 3. Live state (block 127,496,806 unless noted)

| Item | Value |
|---|---|
| Factory `getStrategyInstanceCount()` | 77 (69 enabled / 8 disabled) |
| `getVaultCount()` | 48 |
| Strategy types | 0 `regular-v3` (3), 1 `pancake-regular-v3` (8), 2 `pancake-regular-v3-1` (8), 3 `pancake-regular-v4-2` (29), 4 `follow-price-v1` (2), 5 `pancake-regular-v4-4` (12), 6/7 `median-stable-v2` (0/1), 8 `regular-v5` (14) |
| Total vault token value (priced, this run) | **$114,708.75** |
| DefiLlama reading | $98,016 (triage) |
| Ready-to-rebalance set (rebalance() succeeds from a fresh address) | **19** strategies / 18 vaults / **$38,704** |
| ICHI vault factory `baseFee` | 20 % of collected fees → feeRecipient `0x5693E56700Ba1Da17371b3E313Fe80E4b7C7D4bA`; 80 % → affiliate (mostly `0x3a5a97ecd55d80056733cb47f54137cca9b60032`) |
| Vault deposits | `deposit0Max = deposit1Max = 0` on most vaults (closed); 22 vaults still allow one-sided deposits |
| Vault hysteresis / twapPeriod | 0.05 %–0.5 % / 120–3600 s |

Ready-set highlights (strategy → vault → value → behaviour). **Execution additionally requires the strategy to be an
enabled Gnosis Safe module** (`safe.isModuleEnabled`); non-module strategies revert `GS104` when the rebalance tries to
execute (they can still write the harmless `rebalanceInitiation` timestamp).

| Strategy | Type | Vault | Vault value | Safe module? | rebalance() from attacker |
|---|---|---|---|---|---|
| `0x430ac9648ABDc966aB95E86A93e399A8ad4d5313` | t5 | ynBNB/WBNB | $277.57 | **yes** | initiate → wait 180 s → **executes** (fork-proven) |
| `0x0480630519A228eab3D20434b626c45d8D379992` | t2 | ETH/USDC | $58.71 | **yes** | initiate → wait 300 s → executes |
| `0x91D709d77dAf8E9c306a9e402A70f0FcA8A71651` | t5 | ynBNB/WBNB | $46.03 | **yes** | initiate → wait 180 s → executes |
| `0xd141ABc3DDcd69B29202C82c21B4E2d5ffBD2341` | t2 | CAKE/USDT | $37.23 | **yes** | initiate → wait 300 s → executes |
| `0x177E049cee3e9D96101924f82F02520923ce9186` | t3 | AIOZ/USDT | $0.11 | **yes** | executes immediately |
| `0x7957d882712ae929E85E2272b6576E8721961E31` | t3 | AIOZ/USDT | $0.09 | **yes** | executes immediately (`vault.rebalance(..., swapQuantity=0)`) |
| `0x013467C135B7C5ddCa410CF6153fdFFA6b1Be3fF` | t3 | AIOZ/WBNB | $0.03 | **yes** | executes immediately (`swapQuantity=0`) |
| `0x510a07BaEE6e3cc04860bE330Ac1112DFd2b207C` | t4 | WBNB/? | $0.01 | **yes** | initiate → wait 900 s → executes |
| `0xBcB0DAf89999C135E6B0570c9B99ddf8De0b77c0` | t1 | CAKE/WBNB | $23,085 | **no** | initiate OK; execute reverts `GS104` |
| `0xccd9af42F84b05abe3db79D0Ea33Bf67643B1926` | t1 | CAKE/USDT | $10,147 | **no** | initiate OK; execute reverts `GS104` |
| `0xde60E440775B5DD427c4f2bF1F2fBd9A14130a14` | t1 | CAKE/BTCB | $4,553 | **no** | initiate OK; execute reverts `GS104` |
| … 8 more non-module ready strategies | t1–t3 | various | $0.01–$448 | no | initiate only |
| **Executable value bound (8 module-enabled ready strategies)** | | | **$419.79** | | |

Probe results for all 77 (from a fresh `0xdEaD` caller, `eth_call`):
`19 OK`, `15 revert "no need"`, `38 revert "Pausable: paused"`, `2 revert "too soon"`, `1 revert GS104`
(module disabled), `2 revert` (generic/MS12).

---

## 4. The permissionless path in exact terms

1. `strategy.rebalance()` (selector `0x7d7c2a1c`) and `performUpkeep(bytes)` (`0x4585e33b`) have **no caller check**
   (verified: success with `from = 0x…dEaD`; failure modes are only `Pausable: paused`, `no need`, `too soon`).
2. When it fires, the strategy computes a new position from the pool state (`simulate()` → `(baseLo, baseUp,
   limitLo, limitUp)`) and calls
   `safe.execTransactionFromModule(vault, 0, abi.encodeCall(vault.rebalance, (baseLo, baseUp, limitLo, limitUp, swapQuantity)), 0)`.
3. The Safe (owner of the vault) then calls `vault.rebalance(...)`:
   burns both positions, distributes fees (20 % ICHI / 80 % affiliate), **optionally swaps `swapQuantity` at pool
   price with no slippage limit**, then re-mints base+limit ranges with the vault's balances.
4. In both executions observed live (traced with `debug_traceCall`), `swapQuantity = 0` → **no trade occurs**;
   the vault's tokens are simply re-arranged into new ranges. Fees are the only value that leaves (tiny).
5. The two-step strategies (`t1/t2/t4/t5`) require: call #1 sets `rebalanceInitiation = block.timestamp`
   (state write observed: strategy storage slot 9), then after `executionDelay` (180–900 s) call #2 executes.
   `minTimeBetweenRebalances` (1–6 h) then throttles repeats.

---

## 5. PoC / fork verification

* **Local anvil fork (executed, evidence in `analysis/fork_poc_evidence.json`)** — BSC fork; a fresh unprivileged EOA
  (`0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`, no roles) executed a full vault rebalance:
  * call 1 `rebalance()` → status 1; `strategy.rebalanceInitiation := block.timestamp`
  * wait 300 s (fork time) → call 2 `rebalance()` → **tx `0xaef4c2bbcc2f49287db392f06ae51157dcfd38f1e090e960eb7906b08cdd2f1c`, status 1,
    gasUsed 737,850, 22 logs** including the Safe's `ExecutionFromModuleSuccess(module)` event, 3× UniV3 `Burn`
    events, fee-distribution transfers, and the vault's ranges moved to the strategy's `simulate()` plan
    (base `[-887270, 887270] → [150, 887270]`, limit `[240, 887270] → [50, 150]`); `rebalanceInitiation` reset to 0.
  * further call → revert `too soon` (`minTimeBetweenRebalances` = 10,800 s).
  * control checks: direct `vault.rebalance` from the attacker → `Ownable: caller is not the owner`; non-module
    strategy execute → `GS104`; `pause/unpause/resetStrategy` → owner-only.
* `poc/test/BrilLive.t.sol` — Foundry fork suite (run via CI `ci/run.sh` → `forge test -vvvv`). CI results (run
  38500971995, block 127,514,436): **4/7 pass**, including:
  * `test_A_architecture` — vaults/strategies owned by the Bril Safe; **t1 strategy on the $23k vault is NOT a
    Safe module** (GS104 gate) while the t3 strategy is; strategies hold 0 shares.
  * `test_B_permissionless_execute_t3` — an unprivileged address executes `vault.rebalance(..., swapQuantity=0)`
    immediately (vault ticks move).
  * `test_G_types_t4_t5_t7` — for the t5 module strategy (`0x430ac964…`), an unprivileged address initiates, waits
    out `executionDelay`, then **executes**: full trace shows `Safe.execTransactionFromModule` →
    `ExecutionFromModuleSuccess(0x430ac964…)` → vault burns/re-mints → ticks become `simulate()`'s plan
    (base `150..887270`, limit `50..150`); `lastRebalance` set; further calls revert `too soon`.
  * `test_D/E/F` — price-manipulation probes: a 400 WBNB swap moves the CAKE/WBNB pool tick −57738 → −56663
    (~1 %) **but the strategy then refuses** (`simulate()`/`rebalance()` revert) — the built-in
    spot/TWAP volatility guard blocks manipulated execution.
* `ci/scan_modules.py` — CI scan of **all 178 Safe modules** (block ~127,513,7xx): **29 accept `rebalance()` from a
  fresh address**, and every traced execution shows `vault.rebalance(..., swapQuantity: 0)` with **no `pool.swap`
  anywhere** (`ci-out/modules-scan.json`) — independent, system-wide confirmation of the no-trade re-range.
* `ci/scan_ready.py` — re-scans all 77 strategies from a fresh address; ran on CI at blocks 127,504,422 and
  127,513,681 (77 strategies, 19 ready — consistent with 3 local scans at 127,491,600 / 127,494,165 / 127,496,806).
* CI runs (GitHub): 38488943822, 38494293996, 38496563057, 38496969691, 38500507078, 38500971995 — see `ci-out/`
  artifacts and `ci-log.txt`. Earlier runs were blocked by CI infrastructure (empty `BSC_RPC_URL` on the CI repo,
  pruned pinned block, a GitHub `foundry-toolchain` HTTP 500, blob-storage network timeouts); the local anvil fork
  and the final CI runs above cover the same ground.

---

## 6. What an attacker can/cannot do — economics

**Can:** trigger `rebalance()` on the 19 ready strategies — but only the **8 that are enabled Safe modules** can
actually execute (the other 11 revert `GS104`); read all state; use `vault.deposit()` where one-sided deposits are
still open; withdraw only their own shares.

**Cannot:** call `vault.rebalance()` directly (owner-only); pause/unpause/reset strategies (owner-only); move
other users' shares; make the strategies call any target other than the configured vault; extract via the
Wrapper staking contracts; execute a rebalance on any vault whose strategy is not an enabled module (this covers
the big vaults: $23.1k, $10.1k, $4.6k, $0.4k…).

**Manipulation bound (why E-U ≈ 0 even for the executable set):** the executed rebalance is a no-swap re-range
(`swapQuantity = 0`, observed in every executed case), so the only way to profit is to make the vault re-range
around a manipulated price and then trade against the mis-placed liquidity. Two independent bounds make this
negative-EV:

1. **Value bound:** the vaults reachable by the permissionless *execution* path are worth **$419.79 in total**
   (8 strategies × their vaults). The large ready vaults are behind non-module strategies.
2. **Cost bound:** manipulation cost is set by pool depth, which is far larger than those vaults. E.g. the
   CAKE/WBNB pool (`0x133B3D95…`, L = 2.12e23) costs ≈ 59 WBNB ≈ $44k notional per 1 % price move; a round trip
   costs ≈ 0.5 % of notional, i.e. hundreds of dollars — orders of magnitude more than the few-dollar leakage
   possible on a $0.01–$278 vault.

The two-step delay + `priceChange`/volatility gates (`someVolatility = 1 %`, `highVolatility`, `extremeVolatility`,
`isGasAcceptable`) additionally constrain execution. Conclusion: **no positive-EV unprivileged extraction today.**

---

## 7. Verdict, residual risk, blockers

* **E-U = $0** (no unprivileged extraction found). Confidence: **medium-high**.
  * Unprivileged trigger path exists but moves no value out (no-swap re-range) and is limited to **$419.79** of
    vault value (8 module-enabled strategies); all larger vaults are behind non-module strategies (`GS104`).
* **H-O = $114,709** — the vault value is user-held: holders can call `vault.withdraw(shares, to)` any time
  (withdrawals are open; shares are standard ERC-20). Wrapper stakers can `withdraw`/`emergencyWithdraw`.
* **P** — the Bril Safe (3-of-8) can `rebalance` vaults, `setDepositMax`, `setHysteresis`, `setAffiliate`,
  `setTwapPeriod`; Wrapper owners can `updateAdapterAddress`/`restart`. No privileged action moves user principal
  except a bad rebalance.
* **S** — none (no bricked custody found).
* **Blockers/caveats:** strategy implementations are unverified (behaviour inferred from ABI, traces and live
  calls); the 129 non-factory Safe modules were sampled, not exhaustively audited; the fork PoC ran locally
  because the CI runner had infrastructure/network failures (documented in §5/§9); several vault tokens are
  illiquid meme/points tokens whose realizable value is below the quoted price.

**Residual/latent risk:** if any strategy type is later shown to set `swapQuantity ≠ 0`, the extraction channel
re-opens — the correct mitigation is that nobody can trigger it without also paying the pool-depth cost, but the
margin would be much thinner on shallow pools.

---

## 8. Methodology & sources

* BscScan/Etherscan V2 (contract source), Sourcify (not verified), public BSC RPCs + DRPC (state), Alchemy
  (share-transfer history), DefiLlama (`coins.llama.fi` prices), GitHub (ICHI `ichi-sdk` ABIs, DefiLlama adapter,
  verified RebalancerFactory on other chains), web (Bril/ICHI docs, company status).
* All addresses/blocks in `analysis/` JSON dumps: `live_state.json` (77 strategies), `vault_state.json` (48
  vaults), `holders.json` (150 holders), `traces_rebalance.json` (execution traces), `prices_llama.json`.
* Read-only: every state-changing call was executed only as `eth_call`/`debug_traceCall` or inside a CI fork.

## 9. Files index

```
README.md                  this file
summary.json               machine-readable verdict
analysis/                  enumeration scripts + JSON dumps (live_state, vault_state, holders, traces, prices)
poc/                       Foundry fork suite (BrilLive.t.sol) + vendored forge-std
ci/run.sh, ci/scan_ready.py, ci/scan_modules.py, ci/fetch-ci.sh
ci-out/, ci-artifacts/     CI logs + artifacts (ready-scan.json, modules-scan.json, forge-bril.log)
ci-log.txt                 CI run log
```
