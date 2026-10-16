# Z3-H17 · Meridian Perps (Robinhood Chain, chain id 4663) — sequencer-action validation + merUSD parity

**Date:** 2026-10-16 · **Chain:** Robinhood Chain (4663) · **Status:** read-only; PoC fork-verified only; no mainnet transactions
**Scope:** ExchangeGateway UUPS proxy `0xD540F47F214dC7D6D244E62A6aE7e06B586Ef44A` → impl `0x0f17d8468c49d6C80E4ee10Cc87a767085A4B9A8` ("ExchangeGateway", solc 0.8.28, verified, Solady EIP712/UUPS/Ownable) · registry handlers (all verified): ActionHandler `0xEB9a61e37A28828E84D97e1487D66b444800a280`, CollateralManager `0x719256070f9ec31dfa8df58791fdb80602e431a4`, ExchangeConfig `0xc334010fdd465e5d7b758ec27f90094574de4183`, PerpEngine `0x94e37b0a9e16e6efff842a9e373f0aa2edca0fc8`, PerpEngineAdmin `0x14c899f08c26af5db8b33cbb4a01fce7898b2a20`, Liquidation `0x03fff44b0d7192be942098bf69017cbb293121b0`, Deleverage `0x4cd414a3c1d17d8d9ecea6b7628da790dc733966`, DeleverageWithCompensation `0x5842d29f7266cb0eb327258a3b4fb03c2f8c7bf1` · merUSD `0xAd221259D4A1f2d7376dc1012C561bc86640F009` (proxy) → `0x9a5c0ca8138923bf3788579fb48dabb0339bbbde` (verified) · LP vault `0x24b84023c8e4Da635be228C380C09bfE5271BF9d`.
**Method:** full verified-source review (gateway + ActionHandler + CollateralManager + MeridianUSD + VerifierLib), live-state reads (registry storage slots decoded, sequencer/owner/roles), historical-batch replay tests on a fork of live state (Foundry).

---

## 1. TL;DR

| target | live extractable (unprivileged) | why closed / open | latent risk |
|---|---|---|---|
| `processActions` / `processActionsDryRun` (action execution) | **$0** | gateway gate `onlySequencer(msg.sender)`; **fork-proven**: fresh caller → `NotSequencer(0x05967877)`. Monotonic `lastActionId` + per-action user signatures | **P (primary risk): the single sequencer is an EOA hot key** (`0x39f7e293…`, approved live). A compromised sequencer controls matching, funding/PnL realization and liquidation processing — a full-trust role, but not external-unprivileged |
| historical signed-action replay | **$0** | **fork-proven**: replaying a real sequencer batch (tx `0x44aca2f0…`, block 89,792,031) as a fresh caller → `NotSequencer`; even the real sequencer replaying it → `ActionAlreadyProcessed(0xb6132fdd)` (batch id ≤ `lastActionId`) | none |
| user-signature validation (MatchOrders / LinkSigner / RevokeLinkedSigner / ConvertToken / InitiateWithdraw) | **$0** | EIP-712 domain = (Meridian, 1, chainId, verifyingContract = gateway); digests include sender/subaccount/amounts/nonce/signedAt (+destination for withdraws); ECDSA = Solady `tryRecover` with `recovered == sender && recovered != 0`; ERC-1271 path capped at 179k gas with a strict 4-byte magic-value check; per-(account,action,nonce) `usedNonces`; expiry via per-action `actionExpiryBuffers` | — |
| withdraw lifecycle (`InitiateWithdraw` has **no inline signature check**) | **$0** | design: the user signature travels inside the action and is enforced at **`finalizeWithdraw`** (`CollateralManager`: `account.verifySignature(withdrawDigest, pendingWithdraw.signature, 0)`), gateway-gated to account/claimer/owner. **fork-proven**: third-party finalize → `Unauthorized()`; bogus digest → `WithdrawNotFound()` | P-class nuance: the sequencer can *initiate* a withdraw against any balance (debit into a pending withdraw with a destination of its choosing) that can never be finalized without the user's signature; owner `rescueFunds` after `rescueDelay` sends to that recorded destination. Sequencer alone ⇒ user-fund lockup griefing, not theft |
| direct calls to the ActionHandler (bypassing the gateway gate) | **$0** | **fork-proven inert**: handler code executes against its own empty storage; gateway state (accounts/registry) untouched; registry target decoded from gateway storage = the verified handler | none while the registry is correct (owner-gated updates) |
| `ping()` | **$0** | permissionless **by design** (documented in-source: "Public by design … not authenticated liveness"); only updates `lastPingTimestamp` | none |
| merUSD wrap/unwrap parity | **$0** | verified `MeridianUSD`: `wrap` pulls the exact amount via `transferFrom` then mints 1:1 (only the `defaultWrappedToken`); `unwrap` burns then pays 1:1. **Live: totalSupply = USDe backing = 1,733,782.135870236e18 exactly**; wrapping a non-default token reverts (fork-proven) | owner Safe can change the wrapped-token list/default (P); fee-on-transfer underlyings would be a design hazard — current underlying (USDe) is not |
| `deposit` / `depositUsd` / `depositOnBehalf` | **$0** | deposits credit only the caller's own `(account, subaccount)` after the sequencer processes FinalizeDeposit; per-token deposit caps; `depositOnBehalf` restricted to owner/delegate depositors; no measured-balance vs credited-amount mismatch for the listed 18-dp assets | deposit-token quirks (fee-on-transfer/rebasing) would surface as pending/finalized mismatches; watch any newly listed token |
| LP vault `0x24b84023…` (ERC-4626) | **$0 (E-U)** | `convertToAssets(1e18) = 1.00789e18`; totalAssets 96,524.63; not part of the gateway's trust boundary; per DL it is an "Accountable" curator vault (self-service; H-O) | not audited here beyond reads (out of mission scope) |

**Total live extractable now: $0.00** — confidence **high** for the E-U surface (fork-proven gate/replay/inertness results, verified sources for every contract on the path).
The dominant residual risk is **P-class centralization**: a **single EOA sequencer** (hot key) + 2-of-3 Safe owner.

## 2. The mechanism, in exact terms

1. **ExchangeGateway** (UUPS proxy) is a thin façade: every state-changing entrypoint is either `onlyOwner`, role-gated (`feeCollector`, `claimer`, `liquidator`, `delegateDepositor`, `emergencyPauser`) or delegated into a fixed registry target via **delegatecall to pre-registered, owner-set addresses** (no user-controlled delegatecall target). `multicall` is `onlyOwner`.
2. **`processActions(bytes[])`** — the sequencer's batch entrypoint: `_verifyNotPaused` → `Exchange.load().onlySequencer(msg.sender)` → delegatecall into `ActionHandler._processActions`. Actions are strictly ordered: each action's `ActionId` must exceed the previous (and the stored `lastActionId`), else `ActionAlreadyProcessed`. 18 action types are dispatched; user-authorizing ones verify EIP-712 signatures (see below), maintenance ones (funding/PnL/PnL-fee/delist) are sequencer-only by nature.
3. **Signature discipline** (`ActionHandler` + `VerifierLib`): digests are EIP-712 hashes with domain `("Meridian","1",chainId,address(this)=gateway)`; structs include the sender, subaccount, economic params, a per-action `nonce` (tracked in `usedNonces[account][actionType][nonce]`), and `signedAt` (checked against per-action `actionExpiryBuffers`). EOA path: `ECDSA.tryRecover` + `recovered == sender && recovered != 0`. Smart-contract wallets: ERC-1271 staticcall with a 179k gas cap and exact `0x1626ba7e` check.
4. **Withdraws are two-phase**: the sequencer's `InitiateWithdraw` action records `pendingWithdraw[digest] = {destination, token, amount, fee, signature, messageIdx}` and debits the subaccount immediately; `finalizeWithdraw(account, digest)` (gateway-gated: account / claimer / owner) re-verifies the **user's** signature over the digest and pays the recorded destination (same chain) or bridges via LayerZero OFT. Owner `rescueFunds` can complete after `rescueDelay` without the signature — to the recorded destination.
5. **merUSD** is a minimal 18-dec stable: only the owner can set wrapped tokens; `wrap/unwrap` are permissionless, restricted to `defaultWrappedToken` (= USDe), and 1:1 both ways.

## 3. Live-state assessment (2026-10-16; fork blocks 89,792,02x `eth_blockNumber` space / 26,202,7xx header space)

- **Registry (decoded from gateway storage, slot math `keccak(key . keccak(abi.encode("xyz.meridian.AddressRegistry.Data")))`):** the 8 addresses listed in Scope (all verified). Fork-proven in-test via `vm.load`.
- **Sequencer:** `0x39f7e2936316f99E578489509c2dB036F384E574` — **EOA (code size 0)**, `isSequencerApproved = true`, added at block 48,039,484 (the only `SequencerAdded` event). It processes batches continuously (sampled: 20 txs, most recent at block 89,792,031; selector `0x7bc8a752`).
- **Owner:** `0xF8067d8cA90b8510CE8ADe1eec24B7260eAfa5F7` — Gnosis Safe, **threshold 2 of 3** (`0xF3D11F98…`, `0xb6349012…`, `0xC18B0Cbe…`).
- **Roles:** feeCollector `0xFF68FdA91B0e785B4aee674D3B428C4AB6d8EAa7` ("primary"), liquidator `0x15982b91CFBCb0eF69D8d4c4c98C0003881917F7` ("primary"), PythLazer `0xACeA761c27A909d4D3895128EBe6370FDE2dF481` (maxAge 605,100), `isEmergencyPaused = false`.
- **Tokens (18):** USD, BTC, ETH, SOL, HYPE, XAUUSD/XAU, XAGUSD/XAG, SPYUSD/SPY, QQQUSD/QQQ, NEAR, ZEC, VVV, ENA, LIT — USD = merUSD.
- **merUSD:** totalSupply 1,733,782.135870236e18 = USDe (`0x5d3a1Ff2…`) balance in the merUSD contract — exact 1:1.
- **LP vault:** totalAssets 96,524.63; `convertToAssets(1e18)` = 1.007888253972866080e18.
- **Historical batch used in the replay test:** tx `0x44aca2f0b0792053886dca88722e6bd74574c8fcb6bfb9de4abfcc53b56151a2` (1,226-byte `processActions` calldata).

## 4. What an attacker can / cannot do (exact paths)

Can (fork-proven, all harmless):

- `ping()` (anyone, ≥10 s cadence) — emits/updates a timestamp (T7).
- `deposit`/`depositUsd` their own funds (credited only after the sequencer finalizes; caps enforced).
- `wrap`/`unwrap` merUSD with the default USDe asset 1:1.
- Call the ActionHandler directly — inert (T3) because all real state lives in the gateway's storage.
- Attempt old-batch replays — rejected: `NotSequencer` (attacker) or `ActionAlreadyProcessed` (sequencer).

Cannot:

- Execute any action as a non-sequencer (`NotSequencer`), replay a processed batch (monotonic id), or reuse a user signature (per-action nonces + expiry + domain).
- Finalize a withdraw for anyone else (`Unauthorized`) or forge one without the user's signature (`WithdrawNotFound`/signature check in `CollateralManager`).
- Mint merUSD beyond a 1:1 deposit, unwind another holder's merUSD, or wrap a non-default asset.
- Change any config, registry record, or upgrade the proxy (onlyOwner 2-of-3 Safe), or render the exchange paused (pausers/owner only).

## 5. PoC / fork verification

- `poc/test/Meridian.t.sol` — contract `MeridianH17Test`; forks live Robinhood Chain via keyless public RPCs (env override `RHO_RPC`, publicnode/drpc fallbacks). `ForkHelper.sol` is not compilable as vendored (parent-owned; solc 9097) — inline-fork pattern as in the other Z3-H17 children.
- Local run: **7/7 PASS** (`forge test --match-path 'test/Meridian.t.sol' --skip 'src/ForkHelper.sol'`), fork block 89,792,0xx `eth_blockNumber` space.
- Key proof points: T1 `NotSequencer(0x05967877)` for a fresh caller; T2 attacker replay → `NotSequencer`, sequencer replay of the real historical batch → `ActionAlreadyProcessed(0xb6132fdd)`; T3 gateway state unchanged by direct handler calls + registry slot decodes to the handler; T4 `Unauthorized()`/`WithdrawNotFound()`; T5 merUSD supply == USDe backing, non-default wrap reverts; T6 sequencer EOA / 2-of-3 Safe / not paused; T7 ping permissionless.

## 6. Verdict and residual risk

- **E-U (external unprivileged, live): $0.00 — high confidence.** The action pipeline is sequencer-gated, replay-proof (monotonic ids), and user-signature-verified with a strict ECDSA/ERC-1271 discipline; the withdrawal lifecycle enforces the user's signature at finalization; merUSD is exactly 1:1 backed with a one-asset wrap/unwrap surface; direct handler calls are inert; the only permissionless functions are documented no-ops (`ping`) or self-service user actions.
- **P (dominant risk — not E-U):** single-EOA sequencer hot wallet — can match trades, push funding/PnL realizations, liquidate, and initiate withdraws (unfinalizable without user signatures). A compromised sequencer degrades to user-fund lockups and manipulated PnL/funding/liquidations within the exchange's accounting, plus rule-based DoS. Owner = 2-of-3 Safe (upgrade/registry/config/wrapped-token admin; `rescueFunds` after `rescueDelay`). These are privileged paths by construction.
- **H-O:** user balances and LP-vault shares are self-service but require sequencer-processed actions (liveness dependency). **S:** none found.
- **Monitors:** sequencer address changes/pauses; `rescueDelay` and pending-withdraw storms (sequencer griefing signal); owner-Safe signer set; newly listed tokens (fee-on-transfer/rebasing profiles); PythLazer feed age (`pythMaxAge` 605,100) and product delisting paths.
- **Blockers/caveats:** the full PerpEngine/Liquidation/Deleverage math was reviewed only at the interface level (the mission targets were sequencer gating, signature discipline, and merUSD parity); the PythLazer price-consumption path is available at `0xACeA761c…` (Pyth-operated, off-chain trust); historical batch structure was validated by replay rather than full per-op decoding.

## 7. Methodology & sources

Read-only: verified sources from Etherscan V2 (chain 4663) for the gateway proxy+impl, ActionHandler, CollateralManager, ExchangeConfig, PerpEngine, PerpEngineAdmin, MeridianUSD; storage-slot decoding of the ERC-7201-style registry and Exchange structs; live `eth_call`/log reads for roles/tokens/balances; a real historical sequencer batch replayed against fork state in 7 Foundry tests. No transactions sent; no keyed URLs stored.

**Files:** `README.md` · `summary.json` · `live_state.json`, `registry.json`, `recent_processactions_calldata.txt`, `recent_processactions_decoded.txt`, `seq_txs.json`, `seq_logs.json`, `gateway_impl.json`, `gateway_proxy.json`, `merusd.json`, `merusd_impl.json`, `src/`, `actionhandler/`, `collmgmt/`, `merusd/` (verified sources) · `poc/test/Meridian.t.sol`.
