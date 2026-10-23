# Metropolis DLMM `VaultFactory` + vault-side auth — deep dive (ZH4 residual OPEN #6)

**Date:** 2026-10-23 · **Chain:** Sonic (146) · **Status:** read-only; PoC fork-verified only; **no mainnet transactions signed or sent**; no secrets in this folder.
**Target:** `VaultFactory` `0x197d40B36677248E82939f96930bf4E7Fe8aD1c2` (Sonic) — pass4-recon OPEN #6: *"permissionless `createMarketMakerOracleVault`; the vault-side admin/auth was never read."*

---

## 1. TL;DR

| Target | Live unprivileged extractable (E-U) | Why closed | Latent risk |
|---|---|---|---|
| Factory `0x197d40B3…D1c2` | **$0** | Holds **0** native + **0** of every pair token; only forwards `msg.value` to `feeRecipient`; all admin fns `onlyOwner` (Gnosis Safe); `initialize4` is a `reinitializer(6)` and the proxy is already at version 6 ⇒ cannot be re-initialized | Owner Safe key compromise (P) |
| Vault implementation `OracleRewardVault` `0xe19B636A…BDB7` (124 clones, **$251,566** live) | **$0** | Every value-moving vault fn is `onlyFactory` / `onlyOperators` / `onlyStrategy`; every strategy fn is `onlyVault` / `onlyOperators` / `onlyFactory` / `onlyDefaultOperator` / `onlyTrusted` — all revert for a random EOA (probes + PoC) | Operator (P) can `rebalance`/`pauseDeposits`/`submitShutdown`; owner (P) can set fees/emergency — **neither can transfer principal to itself** |

**Total live extractable by an external unprivileged attacker now: $0** (confidence **high**).
The **"no custody"** claim is **confirmed** for the factory, and the previously-unread **vault-side auth is correctly gated** — this OPEN can be **closed**.

---

## 2. What the factory is (verified deployed reality)

| Item | Value | Source |
|---|---|---|
| Factory (proxy) | `0x197d40B36677248E82939f96930bf4E7Fe8aD1c2` | `eth_getCode` present |
| Proxy kind | TransparentUpgradeableProxy | EIP-1967 slots |
| EIP-1967 impl | `0x920b7adf83423283c2d1291cbf3d44dd56a80636` | storage slot `0x360894…382bbc` |
| EIP-1967 admin | `0x4541cda311ab72420743d03f8f45b42c858046dc` (ProxyAdmin) | storage slot `0xb531…6103` |
| ProxyAdmin owner | `0xd1f2823f3aBF4b8c7Ad1B6629421b2618a5e28aF` | `owner()` |
| Factory `owner()` | `0xd1f2823f3aBF4b8c7Ad1B6629421b2618a5e28aF` | `owner()` |
| Factory `getDefaultOperator()` | `0xd1f2823f…` | `getDefaultOperator()` |
| Factory `getFeeRecipient()` | `0xd1f2823f…` | `getFeeRecipient()` |
| `0xd1f2823f…` identity | **Gnosis Safe** (171-byte SafeProxy; 4 owners: `0xa2A334…`, `0x66c297…`, `0x372Dd8…`, `0x4A3723…`) | `getOwners()` |
| Impl source | `VaultFactory` verified, solc `0.8.10` (`src/VaultFactory.sol` + 35 files) | Etherscan V2 chain 146 |
| `_initialized` (slot 0) | **6** | `eth_getStorageAt` |
| Factory native balance | **0** | `eth_getBalance` |
| Factory token balances (wS/WETH/USDC/USDT) | **0 / 0 / 0 / 0** | `balanceOf(factory)` |
| Creation fee | `50e18` (50 S) | `getCreationFee()` |

`createMarketMakerOracleVault(ILBPair,uint16)` is **not fully permissionless** — it requires
`_pairWhitelist[lbPair] == true`, `msg.value == _creationFee` (50 S), `aumFee <= 30%`, and a
non-zero `_vaultImplementation[Oracle]`. It creates a **new** vault + strategy and sets the caller as
**operator of that new strategy only** (`IStrategy(strategy).setOperator(msg.sender)`). It cannot be
pointed at an existing vault/strategy, and the factory retains nothing (`TokenHelper.safeTransfer(IERC20(address(0)), feeRecipient, msg.value)`).

**Implementation addresses (owner-set, live):**
- Oracle vault impl `getVaultImplementation(Oracle)` = `0xe19B636A6ABEe9C14eABB3F64e30c3304859BDB7` → verified **`OracleRewardVault`** (BlueLabs fork of Trader-Joe LB vaults).
- Simple vault impl `getVaultImplementation(Simple)` = `0x0` (unset).
- Strategy impl `getStrategyImplementation(Default)` = `0x1817134Ad98B72a42AB68cc485fb123AFaC85e80` → verified **`Strategy`**.
- Vaults are deployed with `ImmutableClone.cloneDeterministic` (immutable-args clones, **not** upgradeable).

**Price path (checked — this is the only external dependency that could misprice shares):** each vault's `OracleHelper` (`0x01c871Df…` for the sample) is `onlyFactory`-gated and one-shot (`_initialized`); `setOracleParameters`/`setTwapParams`/`setSequenzerUptimeFeed` are `onlyFactory`. It reads `OracleLensAggregator` (fresh by construction: `updatedAt = block.timestamp`) → `IPriceLens` = **`DexLens`** proxy `0x189F3FAEE49F744b76dC0B2549a20146E836aa37` (EIP-1967 impl `0xe640b1ad57fdadf8aa60d715a455b40eb374d90b`, verified `DexLens`). `DexLens.initialize` reverts `DexLens__AlreadyInitialized`; every feed setter is `onlyOwnerOrRole(DATA_FEED_MANAGER_ROLE)` (role has **0** members; owner `0x4A3723B6…` is a Safe owner EOA). Live prices sane (USDC $1.008, WETH 45,826 wS). Deposits additionally enforce a **5% TWAP deviation** check (`twapPriceCheckEnabled=true, deviationThreshold=5, interval=120`), bounding any residual mispricing.

## 3. Vault-side auth map (the OPEN's question)

Read in full: `BaseVault.sol`, `OracleVault.sol`, `OracleRewardVault.sol`, `Strategy.sol`, `VaultFactory.sol`.

**Vault (`OracleRewardVault`/`BaseVault`)**
| Function | Gate | Live value that matters |
|---|---|---|
| `deposit` / `depositNative` | permissionless (takes the caller's own tokens; `depositsAllowed`) | — |
| `queueWithdrawal(shares,recipient)` | permissionless; burns caller's own shares; `cooldownPassed` (10 min) | self-scoped |
| `cancelQueuedWithdrawal`, `redeemQueuedWithdrawal[Native]` | caller == user, or factory | self-scoped |
| `emergencyWithdraw` | permissionless **only when `_strategy == address(0)`**; pro-rata to caller's own shares | no vault is in emergency mode |
| `claim` / `updateAccRewardsPerShare` | **permissionless** but self-scoped reward accounting | only share-holders' own rewards |
| `executeQueuedWithdrawals` | `onlyStrategy` (`msg.sender == _strategy`) | reverts for EOA |
| `setStrategy` | `onlyFactory` | reverts |
| `recoverERC20` | `onlyFactory` (+ safety: cannot take `tokenX/tokenY` principal while a strategy is set) | reverts |
| `setEmergencyMode` | `onlyFactory` | reverts |
| `pauseDeposits`/`resumeDeposits`/`submitShutdown` | `onlyOperators` = strategy operator **or** factory default operator | reverts |
| `cancelShutdown` | `onlyFactory` | reverts |

**Strategy**
| Function | Gate |
|---|---|
| `withdrawAll` | `onlyVault` (sends tokens **to the vault**, never to a caller) |
| `rebalance` | `onlyOperators` (withdraws from LB into the strategy contract; deposits only back into the LB pair; the only outflow is the bounded AUM fee to the **fixed** `feeRecipient`) |
| `emergencyWidthdrawRange` | `onlyDefaultOperator` (into the strategy's own reserve) |
| `harvestRewards` | `onlyTrusted` (operator/defaultOperator/strategy/vault) |
| `setOperator`/`setPendingAumAnnualFee`/`resetPendingAumAnnualFee`/`setRebalanceCoolDown` | `onlyFactory` |

No vault/strategy function transfers tokens to a caller-supplied recipient. The AUM fee is capped at 30%/yr and its recipient is fixed at creation (`getFeeRecipientByVault` = market maker for MM vaults, else default fee recipient).

## 4. Live-state assessment (Sonic, block ~81,494,388, 2026-10-23)

- **124 Oracle vaults** (`getNumberOfVaults(Oracle)=124`), 0 Simple; 124 strategies.
- **92 vaults hold funds**; **total `getBalances()` = $251,566** (matches DefiLlama *"Metropolis DLMM Vaults"* $251,646).
- Token mix (principal): wS 1,452,415 · USSD 83,133 · USDC 7,132 · stS 293 · OS 175 · scUSD 70 · WETH 31.2 · WBTC 0.129 · EURC 11.2 · USDT 1.66.
- Largest: `0x6bE5a84D…7D54` WETH/wS ≈ **$62.7k**; `0xbfc8aaA5…aE9c` WETH/USSD ≈ $56.2k; `0x7b231723…9A89` wS/USSD ≈ $48.3k.
- **0 vaults in emergency mode** (`getStrategy() != 0` for all); **0 vaults with operator == 0**.
- 58 paused / 54 flagged — pausing only blocks **deposits**; withdrawals remain available (H-O intact).
- 28 vaults have shares outstanding but 0 balances (already shutdown/emptied; mostly the 1e6 min-shares held by the vault itself) ⇒ **$0 stuck**.
- **Operators:** 32 EOAs + 2 Gnosis Safe proxies. Two operators are **EIP-7702-delegated EOAs** (`0xa63c0a70…`, `0x853725b1…` → delegate `0x63c0c19a282a1b52b07dd5a65b58948a07dae32b`, *EIP7702StatelessDeleGator*); its `execute(bytes32,bytes)` reverts `NotEntryPointOrSelf` for a random caller, so the operator authority is not hijackable.

## 5. What an attacker can / cannot do

**Can (unprivileged):** create a *new* market-maker vault for a **whitelisted** pair by paying 50 S, and thereby become operator of that brand-new, empty vault; deposit/withdraw their own funds; call `claim()` (gets only their own rewards); redeem their own queued withdrawals.
**Cannot:** touch any existing vault's principal, shares, strategy, operator, or fees; re-initialize the factory; call any admin/operator function on any live vault or strategy. Every probe below reverts.

## 6. PoC / fork verification

- Files: `poc/test/MetropolisAuth.t.sol` (7 tests), `poc/foundry.toml`, `ci/run.sh` (live-state snapshot).
- Fork: Sonic mainnet via `SONIC_RPC_URL` (public fallback `https://rpc.soniclabs.com`).
- Tests: `test_factory_has_no_custody`, `test_vault_is_oracle_reward_vault_clone`, `test_vault_value_movers_revert_for_unprivileged`, `test_strategy_value_movers_revert_for_unprivileged`, `test_factory_admin_gated_and_create_gated`, `test_claim_is_self_scoped`, `test_operator_rebalance_cannot_extract_principal`. **7/7 PASS.**
- CI: **https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39921768006** (GitHub Actions `artsbykriss/ca-zombie-ci`, run 39921768006; `ci-log.txt`), plus a `ci-out/live_state.json` artifact snapshot (block 81,495,606).
- Raw eth_call probes (recorded in `analysis/`): from `0x1111…` — `pauseDeposits`→`BaseVault__OnlyOperators`, `setStrategy`→`BaseVault__OnlyFactory`, `recoverERC20`→`BaseVault__OnlyFactory`, `setEmergencyMode`→`BaseVault__OnlyFactory`, `emergencyWithdraw`→`BaseVault__NotInEmergencyMode`, `executeQueuedWithdrawals`→`BaseVault__OnlyStrategy`, strategy `withdrawAll`→`Strategy__OnlyVault`, `rebalance`→`Strategy__OnlyOperators`, `emergencyWidthdrawRange`→`Strategy__OnlyDefaultOperator`, `harvestRewards`→`Strategy__OnlyTrusted`, factory `setVaultImplementation`→`Ownable: caller is not the owner`, `createMarketMakerOracleVault(non-whitelisted)`→`VaultFactory__VaultNotWhitelisted`, `initialize4`→`Initializable: contract is already initialized`.

## 7. Verdict & residual risk

**E-U = $0 (high confidence).** The factory has no custody and the vault/strategy auth is correctly scoped. Residual:
- **P** (privileged): the owner Gnosis Safe (4 owners) can `setVaultImplementation`, `setOperator`, `setFeeRecipient`, `setPendingAumAnnualFee` (≤30%/yr), `setEmergencyMode`, `recoverERC20`, and the ProxyAdmin (same Safe) can upgrade. Even so, **no privileged path transfers principal to an arbitrary address** — `recoverERC20` cannot touch `tokenX/tokenY` principal while a strategy is set, `setEmergencyMode` returns funds to the vault for pro-rata `emergencyWithdraw`, and `setStrategy` only accepts a strategy matching the same vault/pair/tokens. So the worst P-class outcome is a bounded AUM-fee/DoS, not a sweep.
- **H-O ≈ $251,566**: holders can self-withdraw (queue → operator/defaultOperator rebalance → redeem). Withdrawal has a liveness dependency on a rebalance (operator or default operator); not permanently stuck because the default operator can always rebalance.
- **S ≈ $0**: no stuck value found.
- **Latent monitors:** (a) owner-Safe key compromise; (b) EIP-7702 operator keys (can rebalance/pause, still no direct extract); (c) if the owner ever sets a malicious `_vaultImplementation`, *future* vaults (not existing ones) would use it.

## 8. Methodology & sources

- Etherscan V2 `getsourcecode` (chain 146) for factory, Oracle vault impl, Strategy impl (all verified).
- Public Sonic RPC `eth_call`/`eth_getCode`/`eth_getBalance`/`eth_getStorageAt`; full enumeration of the 124 vaults (`analysis/enumerate_vaults.py`, `analysis/vaults_raw.json`); token symbols/decimals (`analysis/tokens.json`); DefiLlama prices (`analysis/prices.json`) and TVL (`api.llama.fi/protocol/metropolis-dlmm-vaults`).
- Source read in full: `analysis/src/` (factory), `analysis/src_vault/` (BaseVault/OracleVault/OracleRewardVault), `analysis/src_strategy/` (Strategy).

## 9. Caveats & limitations

- Point-in-time reads **2026-10-23** (~block 81,494,388); re-read balances before acting. Values move as vaults are rebalanced/deposited.
- USD uses DefiLlama spot prices at read time (wS $0.0522, WETH $2,402, WBTC $81,527, USDC ~$0.999); WLD n/a here.
- The OracleRewardVault clone bytecode was confirmed by behaviour + verified impl source, not by byte-for-byte recompilation.
- Reward-token accounting (`claim`/`updateAccRewardsPerShare`/phantom shares) is custom (BlueLabs) and was reviewed only for *unprivileged drain of principal*; it is self-scoped. A deeper reward-accounting diff was out of scope (residual is reward tokens, not principal).

## Files index
`README.md` · `summary.json` · `analysis/{src,src_vault,src_strategy}/*.sol` · `analysis/enumerate_vaults.py` · `analysis/vaults_raw.json` · `analysis/tokens.json` · `analysis/prices.json` · `poc/` · `ci/run.sh` · `ci-out/` · `ci-log.txt`

*Nothing here is an instruction to transact. Read-only; fork-only PoC; no secrets.*
