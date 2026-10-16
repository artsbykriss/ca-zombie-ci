# Z3-H17 · HertzFlow (BSC, chain id 56) — GMX-v2-fork config layer + wrapped-bank parity

**Date:** 2026-10-16 · **Chain:** BSC (56) · **Status:** read-only; PoC fork-verified only; no mainnet transactions
**Scope:** deployment **B** (value-bearing, DL adapter): DataStore `0xc244A37A17CE7aa14E1BDD73f6a047Ed6B56f6B8` · Reader `0xFC370bA161F4B54B12574c7e0a2121Cea57854A1` · ExchangeRouter `0x61e1116A943b27D21094599C2c5Bd75e980170a5` · RoleStore `0x616Ee07aa245EB578c7443E598dcc8b4451bEf30` · banks `0x00ceA665…`/`0xAB96931f…` (BeaconProxy → `0x9539cC76…`, verified Sourcify) · wrapped tokens HFUSD `0x7F7AD43d…` / HFUSD1 `0x026C39Ab…` · HFBankFactory/beacon-owner `0xd87FC971…` · admin Safe `0x2492bD5a…` (3-of-N).
Also checked: deployment **A** (fresh; the protocol's own SDK points there): DataStore `0x92A898D6…`, ExternalHandler `0xebc460d6…`, banks `0x1b40AE15…`/`0xB5D271f5…`, EOA admin `0x1a94a043…` (tiny TVL ~$183).
**Method:** verified-source review (Sourcify v2, solc 0.8.29, exact_match), live-state reads (keyless public RPC), protocol SDK/ABI reconstruction from the public `HertzFlow/frontend` repo, and 8 fork tests against live BSC state (Foundry).

---

## 1. TL;DR

| target | live extractable (unprivileged) | why closed / open | latent risk |
|---|---|---|---|
| HFBank redeem/burn parity (`redeem`, `redeemFromWrappedTransfer`, `WrappedToken._transfer` auto-redeem) | **$0** | permissionless `redeem` burns **msg.sender's** wrapped tokens only; `redeemFromWrappedTransfer` is caller-locked to the wrapped token; transfers to non-holders auto-redeem **the sender's** tokens. 1:1: bank reserves = supplies (U 30,429.4039091 bank vs 30,429.4039091 supply; USD1 7,078,605.21 bank vs 7,078,585.21 supply = +20 donation). Fork-proven (T5/T6) | none found |
| `WrappedToken.addMinter` / `setRedemptionBank` / holders whitelist | **$0** | `registrars(router)=false`, `minters(executor)=false`, `canHold(executor)=false`; only the factory (registrar) can manage minters; `setRedemptionBank` is bind-once and already bound. Fork-proven: `addMinter(attacker)` via the router reverts `NotRegistrar` (T7) | factory is the single registrar (P) |
| **`ExchangeRouter.makeExternalCalls` — permissionless** | **$0 today** | anyone can make the router execute arbitrary calls; they run as the shared executor `0x95d312da…`, which holds **no** RoleStore roles → DataStore setters revert `Unauthorized(executor,"CONTROLLER")` (T2). The executor **is** `isMintCaller` on both banks, so `bank.mint(receiver)` is reachable for any whitelisted `mintReceiver` (T3/T4) — but mint amount = `actualBalance − recordedUnderlyingBalance`, which is **0** (reserve == recorded) | **E-U-conditional**: any direct token donation to a bank becomes immediately mintable by any caller (minted to the DepositVault, not to the caller). Design flaw: a static executor with standing privileges runs arbitrary attacker calldata |
| market pool accounting / PRICE_FEED config | **$0** | markets hold ≥ accounted `POOL_AMOUNT`; markets not disabled; `PRICE_FEED` DataStore keys unset (prices are keeper/provider-fed via `OracleUtils.SetPricesParams`) | oracle provider trust is off-chain (P-class) |
| `MAX_LEVERAGE = 0`, `MIN_COLLATERAL_USD = 1e30 ($1)`, `maxPnlFactor`/`positionFeeFactor` keys read 0 in DataStore | n/a | these look like a **partially configured** fork (config gaps, not attacker-triggerable without order execution; order/deposit execution is keeper-relayed) | misconfiguration risk (H-O/outage), monitor keepers |

**Total live extractable now: $0.00** — confidence **high** for the wrapped-bank layer (fork-proven negatives + exact reserve accounting).
The only defects are a **latent design flaw** (permissionless-arbitrary-call executor that holds bank privileges) and the **20 USD1** un-synced surplus (already present, mintable only into the DepositVault).

## 2. The mechanism, in exact terms

HertzFlow is a GMX-v2 fork (DataStore/reader/router/handler architecture, `SetPricesParams` provider-fed oracle), wrapped in a custom **beacon-proxy redemption-bank layer**:

1. **`HFBank`** (implementation `0x9539cC7655C9BAc0Bc5b417Bd307DeC37b671ff0`, verified; ERC-7201 storage) escrows one underlying token per bank and mints/burns one `WrappedToken`:
   - `mint(receiver)` — requires `mintCallers[msg.sender]` **and** `mintReceivers[receiver]`; amount = `balanceOf(this) − recordedUnderlyingBalance`; mints that delta to `receiver`; re-syncs `recordedUnderlyingBalance = balanceOf(this)`.
   - `deposit/withdraw/borrow/repay` — `onlyBorrower`; `redeem`/`redeemFromWrappedTransfer` — redeem burns the holder's tokens 1:1 against the reserve; every path re-syncs `recordedUnderlyingBalance`.
   - `minReserveFactor = 0` live (borrow could drain the reserve; **no borrower** currently).
2. **`WrappedToken`** (verified): role-based mint/burn (`minters`, typically the bank; `registrars`, typically the factory; `admin`), a permanent `redemptionBank`, and a transfer hook that routes any transfer **to a non-whitelisted address** through `bank.redeemFromWrappedTransfer(from, to, amount)` — i.e. wrapped tokens cannot be held anywhere except whitelisted (market/vault) contracts; moving them out atomically redeems them for the underlying.
3. **HertzFlow's router returns external calls via a shared executor.** `ExchangeRouter.makeExternalCalls(targets, data, refundTokens, refundReceivers)` is permissionless, and the actual calls execute from a dedicated helper (deployment B: `0x95d312da653f8b9c6f04345f3b2463e91c7505b3`, 2,411 B; deployment A: `0xebc460d6409174caede99314c2f1c62657039185`). The executor is deliberately granted protocol privileges — live read: **`isMintCaller = true` on both banks** (that is how the user deposit flow works: `sendTokens(underlying→bank)`, then `makeExternalCalls([bank],[bank.mint(depositVault)])`, then `createDeposit`).

The defect: the executor executes **arbitrary, caller-supplied calldata** while holding standing privileges. Today that privilege is only `bank.mint` (surplus-only, destination-restricted to whitelisted receivers), and the router itself carries `CONTROLLER`+`ROUTER_PLUGIN` on the RoleStore but is **not** the caller of the external calls (fork-verified: inner-call `msg.sender` = executor; DataStore write reverts with `Unauthorized(executor,"CONTROLLER")`). If the executor is ever granted another role (or the same pattern is copied to another privileged contract), this becomes a one-transaction takeover.

## 3. Live-state assessment (block `eth_blockNumber = 127,909,605` · 2026-10-16)

- **Two deployments exist** on BSC — a config-rot smell worth flagging:
  - **B (value-bearing; DL adapter)**: supply HFUSD 30,429.403909100018067099 / HFUSD1 7,078,585.212162068475755047; bank reserves U 30,429.403909100018067099 / USD1 7,078,605.212162068475755047 (**+20.000000000000000000 surplus**); 5 markets, all enabled:
    M1 `0x5fD1FCee…` BTC/USD · HFUSD (pool 30,388.29) · M2 `0xF59B083e…` BTC/USD · HFUSD1 (2,965,649.42) · M3 `0x4FE5cEc3…` ETH/USD · HFUSD1 (1,751,358.55) · M4 `0x8122Dd26…` BNB/USD · HFUSD1 (1,155,412.66) · M5 `0x4eBaE5E5…` BNB/USD · HFUSD1 (1,159,925.79). Market token balances ≥ accounted pool on all five (M2: 2,982,832.40 held vs 2,965,649.42 accounted — residual fees).
  - **A (fresh; the SDK points here)**: 8 markets, HFUSD 182.549087960505371724 / HFUSD1 2.136619750379852659, banks equal to supply, **admin = EOA `0x1a94a0430F1ffC8718Cd30FdedCCaFA59A69B46E` (no code)**.
- **Roles (RoleStore B):** ExchangeRouter B = `CONTROLLER`, `ROUTER_PLUGIN`; executor `0x95d312da…` = none; admin Safe `0x2492bD5a…` = `ROLE_ADMIN` (Safe threshold 3, code 171 B); HFBankFactory `0xd87FC971…` = registrar on both wrapped tokens + beacon owner.
- **Bank ACL:** `isMintCaller(executor)=true` (both banks); `isMintReceiver(depositVaultB 0x1de72acb…)=true`; `isBorrower(executor/router)=false`; `minReserveFactor=0`; `paused=false`.
- **DepositVault B holds 2,360.54 HFUSD1** (pending deposits; attributed at execution by vault-delta accounting, upstream semantic `DepositUtils`: `depositVault.recordTransferIn(token)`).
- **Funded addresses other than the banks:** markets (wrapped tokens), DepositVault (2,360.54 HFUSD1). Executor and router hold 0 tokens.
- Index tokens are **pseudo-addresses** (`BTC/USD 0x26c52b0b…`, `ETH/USD 0x683083Be…`, `BNB/USD 0x3bc2B656…`, `DOGE/USD 0x14b61d2E…` — from the protocol SDK `configs/tokens.ts`), i.e. synthetic price indices with stable-collateral pools.
- **Config (DataStore B):** `IS_MARKET_DISABLED=false` (all 5); `FUNDING_FACTOR=2e22` (1e30-precision), `FUNDING_EXPONENT_FACTOR=1e30`; `MIN_COLLATERAL_USD=MIN_POSITION_SIZE_USD=1e30` ($1); `MAX_LEVERAGE=0`; `POSITION_IMPACT_POOL_AMOUNT` near-zero (0.00024 HFUSD1 on M2); `SWAP_IMPACT_POOL_AMOUNT=0`; `PRICE_FEED` keys unset for all tokens.

## 4. What an attacker can / cannot do (exact paths)

Can (fork-proven, none profitable):

- `makeExternalCalls([],[],[],[])` from a fresh EOA — succeeds (T1). All calls run from the executor `0x95d312da…`.
- `makeExternalCalls([DataStore],[DataStore.setUint(key,1)],…)` — **reverts** `ExternalCallFailed(Unauthorized(0x95d312da…,"CONTROLLER"))` (T2). The router's own `CONTROLLER` role is not reachable through `makeExternalCalls`.
- `makeExternalCalls([bank],[bank.mint(depositVault)])` — reverts `ExternalCallFailed(ZeroAmount())` today (`actual == recorded`, T3).
- After **any** un-synced donation to a bank: the same call **succeeds** and mints the surplus to the DepositVault; the caller's own wrapped balance stays 0 (T4: attacker donated 1,000 USD1, DepositVault +1,000 HFUSD1, attacker +0). Whether the minter can later capture the minted tokens depends on vault-delta attribution (whichever deposit executes next captures the delta — the minter can race it, not guarantee it).
- `makeExternalCalls([wrappedToken],[wrappedToken.addMinter(attacker)])` — reverts `NotRegistrar`; attacker never becomes a minter (T7). So the direct "mint free wrapped → redeem for underlying" drain is closed.
- `bank.redeem(1e18, attacker)` — reverts (no wrapped balance) (T6).

Cannot:

- Reach the banks' role-gated setters (`onlyAdmin` = Safe), borrow/withdraw/deposit as borrower (none), toggle pause, or touch the wrapped-token admin/registrar surface.
- Write a single DataStore key, create/write markets, or change the oracle config through the permissionless path.
- Redeem anyone else's wrapped tokens or make a bank pay out more than was burned.

Costs/preconditions for the conditional path: no capital beyond the donation itself; trigger = un-synced underlying balance in a bank; the payout lands in the DepositVault and is captured by the next executed deposit (vault `recordTransferIn` delta), so net attacker profit is ~0 unless they win the keeper race.

## 5. PoC / fork verification

- `poc/test/HertzFlow.t.sol` — contract `HertzFlowH17Test`; forks live BSC via keyless public RPCs (`bsc-rpc.publicnode.com`, dataseed; env override `BSC_RPC`). `ForkHelper.sol` does not compile against the vendored forge-std (parent-owned file; `VM_ADDRESS` redeclaration, solc 9097 — same note as the Fang child), so the identical env-override/first-working-RPC logic is inlined in the test.
- Local run (allowed pattern + `--skip 'src/ForkHelper.sol'`): **8/8 PASS** (`forge test --match-path 'test/HertzFlow.t.sol'`), fork block `127,909,605`.
- Key numbers asserted: T2 revert data `0x59afd6c6…a35b150b` = `ExternalCallFailed(Unauthorized(executor,"CONTROLLER"))`; T3 `ExternalCallFailed(ZeroAmount())`; T4 exact +1,000e18 delta to the DepositVault; T5 reserves ≥ supplies; T7 `addMinter` revert + minter unchanged; T8 M2 balance 2,982,832.3998 vs accounted 2,965,649.4178.

## 6. Verdict and residual risk

- **E-U (external unprivileged, live): $0.00 — high confidence.** Every candidate call path was reduced to a concrete sequence and either gated by a live-read guard or fork-falsified; the wrapped-bank parity is exact (reserves ≥ supply, burn-then-pay, caller-scoped).
- **E-U-conditional:** value = *any* token donation to a bank (observable trigger: `balanceOf(bank) > recordedUnderlyingBalance()`). Mint side is immediately permissionless and destination-restricted (DepositVault); capture requires winning the next-deposit race. The 20 USD1 currently present is the ceiling seen live. **Monitors:** `recordedUnderlyingBalance()` vs `balanceOf` on `0x00ceA665…`/`0xAB96931f…`; grants of any new role to `0x95d312da…`/`0xebc460d6…`; new `isMintCaller`/`isBorrower` flags.
- **H-O:** ~$7.11 M (the banks' U/USD1 backing wrapped supply; holders redeem 1:1 by construction). **P:** admin Safe (3-of-N) can set borrowers/reserve factor/pause and rotate the bank implementation via the beacon (factory-owned); order/deposit execution is keeper-relayed; oracle prices are provider-signed (`OracleUtils.SetPricesParams`) — off-chain trust. **S:** none material (the 20 USD1 surplus is inert unless minted).
- **Blockers/caveats:** BSC Etherscan V2 free tier is unavailable, so the fork's router/handlers could not be verified from source (DataStore, banks, wrapped tokens IS verified; router ABI reconstructed from the protocol's public SDK). Market handler internals (order/deposit execution, `recordTransferIn` semantics) were assessed from the upstream gmx-synthetics code the ABI matches; the `msg.sender` of `makeExternalCalls` inner calls and all ACLs were read/fork-proven directly.

## 7. Methodology & sources

Read-only throughout: Sourcify v2 verified sources (DataStore, HFBank/WrappedToken bundle), live `eth_call`/`eth_getLogs` (limited ranges) on keyless public BSC RPCs, protocol SDK reconstruction from `github.com/HertzFlow/frontend` (`configs/contracts.ts`, `configs/dataStore.ts`, `configs/markets.ts`, `modules/liquidity/transactions.ts`), and a state-override `eth_call` probe to identify the executor address, then fork tests. No transactions sent; no keyed URLs stored.

**Files:** `README.md` · `summary.json` · `live_state_B.json`, `datastoreB_dump1.json`, `markets_raw.txt`, `datastore_sourcify.json`, `bankimpl.json`, `bank1.json`, `HFBank.sol.txt`, `WrappedToken.sol.txt`, `ds_read.py`, `sdk/**` · `poc/test/HertzFlow.t.sol`.
