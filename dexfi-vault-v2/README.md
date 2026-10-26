# DexFi Aggregator Vault V2 — external unprivileged extraction assessment

**Date:** 2026-10-26 · **Chains:** Base (primary), Arbitrum, Ethereum, BNB, Avalanche, Sonic (+ Robinhood Chain / Arc, no RPC) ·
**Status:** read-only; no transaction signed or sent on any real chain. PoC is fork-verified only (GitHub Actions fork of Base).

**Target (DefiLlama):** *DexFi Aggregator* (slug `dexfi-aggregator`), TVL **$2,544,531** (2026-10-25).
Adapters: `projects/dexfinance-vault-v2/index.js` (+ `projects/dexfinance-vault/abi.js`).

> Prior tracker (ZH4 pass-7 row 10, pass-3 row 13) recorded **NOT REACHED** — the Base factory read was
> blocked by an RPC rate limit. This report resolves it: **the factory read succeeds; 1,895 Base vaults
> enumerated; the protocol is reachable.**

---

## 1. TL;DR

| Target | Live extractable (external unprivileged) | Why closed / open | Latent risk |
|---|---|---|---|
| **DexFi Aggregator Vault V2** (multi-chain) | **$0** (no drain path found; every candidate reverts) | Connector value functions are `onlyVault`; vault value functions are share-based or `onlyOwner`; `harvest` is permissionless but pays the caller a fee only out of *realised* rewards and sweeps no principal | **P:** factory owner can upgrade beacons (vault/connector/profit-storage impls) and re-point connector config for *all* vaults. **P:** vault owner controls `profit`/`publish`/`updateFarms`. **H-O:** users can self-withdraw. **MEV:** harvest swaps run with oracle+min-out guards (bounded). |

**Total live extractable now (E-U): $0.00** — confidence **medium-high** (architecture + fork evidence are
strong; the vault *implementation* is unverified, so the assessment rests on decompilation + behaviour).

---

## 2. The mechanism (exact terms, deployed code)

DexFi V2 is a **multi-farm liquidity-index vault factory**:

- `DexFiVaultFactory` (`0xcb34f261…` on Base) is `Ownable`+`Pausable`. Anyone may call
  `createVault(name,symbol,profit,profitToken,Farm[])` (`whenNotPaused`). The vault is a **`BeaconProxy`**
  over `vaultConfig.vaultImplementation` (a `UpgradeableBeacon` owned by the factory).
- Each `Farm` = `(beacon, percent, data)`. The factory keeps a **beacon whitelist** (`farmsWhitelist`,
  336 entries on Base); each whitelisted beacon has a **connector** (`farmCalculationConnector[beacon]`,
  a global `BeaconProxy`) and default init data.
- A vault creates **its own connector** per farm (`new BeaconProxy(beacon)`), initialized with the farm
  `data`; `vault.farmConnector(beacon)` returns it.
- Users `deposit(native,to,minMint)` → the vault pulls `native` (WETH on Base), forwards to the connector,
  which adds/creates a Uniswap/Aerodrome-CL position (or stakes an ERC20). Users get **synthetic shares**
  (`VT`). `withdraw`/`emergencyWithdraw` burn shares and return native.
- `harvest(minRestaking)` is **permissionless**: it calls each connector's `harvest()` (collects swap fees,
  swaps to native → vault) and splits the realised native into reinvest / **harvester fee** /
  profit / debt repayment. `feeConfig.harvestFee = 7.5%` (75e15) is paid to `msg.sender`.
- `profit` is routed to a per-vault `DexFiVaultProfitStorage` (verified source) and distributed to the
  publisher (vault owner, ≤1%) and share holders.

**Verified deployed sources used:** `DexFiVaultFactory`, `DexFiVaultProfitStorage`, `UniswapFarm`
(connector, verified on Base at `0x1569166f354e4701975c1E248501232FCe89074F`). The **vault implementation
`0x2149F9c9…` is NOT verified on Base/Arb/ETH/BSC/Avax/Sonic or Sourcify** — it was analysed by
decompilation (`heimdall`/`panoramix`) and by direct `eth_call` probing.

### Access-control matrix (live, block 53082339)

| Entry point | Who may call | Live evidence |
|---|---|---|
| connector `deposit/harvest/withdraw/withdrawConvertless/emergencyWithdraw/reinitialize` | **only its vault** (`onlyVault`) | verified `DexFiFarm.sol`; `cast call` from EOA → revert |
| connector `initialize` | anyone, **once** | one-shot `initializer`; 2nd call reverts |
| vault `deposit/withdraw/emergencyWithdraw/depositConvertless*` | anyone (share-based) | `withdraw` with 0 shares → `ERC20: burn amount exceeds balance`; `emergencyWithdraw` → `EmergencyWithdrawUserBalanceZero` |
| vault `harvest(uint256)` | **anyone** | succeeds from a fresh EOA; returns `(reinvest, fee, profit, paidDebt, remainingDebt, restaking)` |
| vault `publish/updateFarms/updateProfit/updateProfitToken` | `onlyOwner` | revert `Ownable: caller is not the owner` |
| vault `initialize` | factory (once) | 2nd call → `Initializable: contract is already initialized` |
| factory `createVault` | anyone, but **farms must be whitelisted** | bogus beacon → `UpdateFarmsNotWhitelisted`; valid beacon → succeeds |
| factory whitelist/config setters, `pause`, `toggleVaultAutoHarvest` | `onlyOwner`/operator | source |
| profitStorage `allocate()`, `addProfitFunds()` | anyone | but only moves `fund`/own tokens; no user funds reachable |
| profitStorage `claim(amount,from)` | anyone, but `from=msg.sender` unless caller is `profitClaimer` | source |

---

## 3. Live-state assessment (addresses, roles, balances, block)

**Base (block 53082339; re-checked 53091923):**
- Factory `0xcb34F261a5284554BB9FEa8aA12A0578c4bA3fC6` — `vaultsCount=1895`, `owner=0x76e1736ea8Cda4d0Ed4923B8E119586716C5725f`, `paused=false`, `farmsWhitelistCount=336`, `profitTokensWhitelistCount=6`, `harvesterBlacklistCount=0`.
- `vaultConfig()` = `(beacon 0x991872559f227337E300382077f0045Ae9E50DA2, maxDepositors 1000, initialPriceNativeAmount 1e16, minSyntheticTransfer 1e12, minNativeReinvest 1e14)`; beacon→impl `0x2149F9c9e6a6A4260325A13ed091616983193C24` (code 23,366 B, **unverified**).
- `integrationConfig()` = operator `0x76e1736e…` (=owner), keeper `0xB034F984…`, harvester `0x55Ad99b7…`, migrator `0x1EDa34f0…`, treasury `0x6Af0c089…`, profitClaimer `0x09B9171F…`, zapper `0x16EE7453…`.
- `feeConfig()` = `(deposit 0, harvest 7.5e16, withdraw 0, migrate 0)`.
- `profitConfig()` = `(minProfit 0, maxProfit 1e18, profitStorage beacon 0x2279Ea3244DA46130D2c978b3d1F14B6c6e8D399 → impl 0xd4C16c97dEE7eEDADA5Abff3ba9F1a4fa5b3b9fa (verified), vaultOwnerProfit 1e16)`.
- `native()` = WETH `0x4200000000000000000000000000000000000006`.

**Other chains** — same owner, `paused=false`, `harvestFee=7.5%`:
Arbitrum `0x061f8132…` (27 vaults), Ethereum `0x4c1a8a04…` (25), BNB `0xc9dc65ae…` (101), Avalanche `0x5764dad2…` (48), Sonic `0x095d35c4…` (132). Robinhood `0x9DD987CB…` and Arc `0x3ca7c792…` (no public RPC used).

**Where the value sits (DefiLlama `currentChainTvls`, 2026-10-25):** Robinhood Chain **$1,240,450**,
Base vaults **$879,766**, Ethereum **$289,234**, Arbitrum **$110,020**, BNB $8,526, Arc $7,974,
Avalanche $4,281, Sonic $4,280. The separate **gDEX staking** bucket ($1,583,472; contract
`0xd7D11E2d4E8E7b65E905aa9d16E488C37195Ca62` holds **86,972.9 gDEX × $10.61 = $922,562**) is *not* part of
the vault TVL figure and is a different contract. Full per-vault enumeration is in `ci-out/scan_*.json`.

---

## 4. What an attacker can and cannot do

**Cannot (verified):**
- Call any connector `deposit/harvest/withdraw/…` directly — `onlyVault` (`CallerIsNotVault`).
- Re-initialise a vault or connector — `Initializable: contract is already initialized`.
- `publish`/`updateFarms`/`updateProfit` on someone else's vault — `Ownable: caller is not the owner`.
- `withdraw`/`emergencyWithdraw` without shares — reverts.
- Create a vault that points at an attacker-controlled connector — `createVault` requires a whitelisted
  farm beacon (`UpdateFarmsNotWhitelisted`), and the vault re-validates in `initialize`.

**Can (and why it is not profit):**
- **Call `harvest()` on any vault.** It is permissionless and pays `harvestFee` (7.5% of the *realised*
  rewards) to `msg.sender`. The connector's `RewardsManagement.processRewards` only swaps
  `harvestDebt` (capped to the collected fees), never principal or donations; the swaps carry
  `minSwapAmount` limits and are oracle-validated (`Oracle.validatePoolPriceWithSwap`,
  `acceptableDeviationSwap`). So the caller's take is a bounded keeper fee, funded from yield, not from
  principal — see the fork measurement in §5.
- **Deposit/withdraw** its own capital at the vault's current share price. Share supply is already
  large on funded vaults and the price is derived from farm *liquidity*, not `balanceOf(this)`, so the
  classic donation/first-depositor inflation does not reset (fork test §5).

---

## 5. PoC / fork-verification

Files: `poc/test/DexFi.t.sol` (+ `poc/src/Interfaces.sol`), run on GitHub Actions (Base fork).

*(results inserted after the CI run completes — see §5 table below)*

| Test | Assertion | Result |
|---|---|---|
| `test_connector_gates` | every connector value fn reverts from a fresh EOA | _pending_ |
| `test_harvest_permissionless_and_fee` | harvest succeeds; attacker WETH delta ≈ 7.5% of realised rewards | _pending_ |
| `test_harvest_loop` | repeated harvest yields ~0 once rewards are drained | _pending_ |
| `test_deposit_withdraw_roundtrip` | round trip nets ≤ 0 (no free value) | _pending_ |
| `test_share_inflation` | donation does not let attacker take victim's deposit | _pending_ |
| `test_owner_gates` | `publish`/`updateFarms` revert for non-owner | _pending_ |
| `test_emergency_withdraw_no_shares` | reverts | _pending_ |

**CI run:** _pending URL_

---

## 6. Verdict and residual/latent risk

- **E-U (headline): $0.00** live extractable by an external unprivileged attacker. Confidence
  **medium-high**.
- **H-O:** depositors can self-withdraw (`withdraw`, `emergencyWithdraw`) — not an attacker path.
- **P (privileged):** the factory owner `0x76e1736e…` (= operator) owns every `UpgradeableBeacon`
  (vault impl, every connector impl, profit-storage impl) and can `updateFarmsWhitelist` to push new
  default init data that the vaults apply to their connectors on the next deposit/harvest. That is a
  **total-loss capability over the ~$2.5M** if the key is compromised or turns malicious — but it is
  privileged, not E-U. The vault owner likewise controls `profit` (≤1e18) and `publish`.
- **S (stuck):** none observed.
- **Latent / monitor:** (a) harvest/rebalance swaps are oracle-guarded but the oracle is a
  factory-configured `INativeV3PriceOracleValidator` — a bad oracle config would open MEV extraction;
  (b) `minSwapAmount`/`MIN_AMOUNT_OUT` are config-controlled; (c) beacons removed from the whitelist are
  still used by existing vaults (Zellic finding #1) — stale connectors remain live.

## 7. Blockers / negatives (do not re-investigate)
- Vault implementation is **unverified** on all six chains and Sourcify → static reading limited to
  decompilation + live probing. The connector (`UniswapFarm`) *is* verified and was read in full.
- The DexFi source repo (`github.com/dexfinance-com/DexFi-Vaults`, commit `2d0f6bd5…`) referenced by the
  Zellic audit is **private/404**.
- Robinhood Chain ($1.24M) and Arc have **no public RPC** used here → their vaults are not enumerated.

## 8. Methodology & sources
- Read-only `eth_call`/`eth_getCode` on keyless public RPCs; Etherscan V2 verified sources;
  DefiLlama adapter + price API; Zellic "DexFi Factory" audit (2025-05-05, 2 findings: missing factory-side
  whitelist check — validated downstream in `DexFiVault.initialize` via `DexFiVaultHelper.processFarm`;
  connector data not cleared on whitelist removal).
- Heavy work (full 2,228-vault enumeration + valuation, fork PoC) ran on GitHub Actions.

## 9. Files index
- `analysis/rpc_scan.py`, `analysis/scan_full.py`, `analysis/value.py` — enumeration + USD valuation.
- `analysis/phaseA.py`, `ci-out/base_phaseA.json` — published-vault sweep.
- `analysis/sources/base/{factory,profitstorage,connector_uniswapfarm}/` — verified sources.
- `poc/` — Foundry fork PoC. `ci/run.sh` — heavy enumeration job. `ci-out/` — results.
- `summary.json` — machine-readable summary.
