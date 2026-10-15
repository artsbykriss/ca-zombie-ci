# SYMMIO-IOTA (Symmio core diamond) — L2-25 deep-dive

**Date:** 2026-10-15 · **Chain:** IOTA EVM (chain 8822) · **Diamond:** `0xc258535aaF6ad3cEd5D2E03e2B66C35262488309`
**Status:** read-only; PoC fork-verified only; no mainnet transactions. All reads at block **13,020,955** (live-state pins re-read at 13,020,955; logs scanned in full: 48 pages / ~2,400 events).

## Verdict

| Category | USD | Confidence |
|---|---|---|
| **E-U (external unprivileged)** | **$0.00** | high |
| H-O (holder-only) | $1,975.76 (of $2,069.00 held) | high |
| P (privileged/roles/timelock) | remainder + full admin | high |
| S (stuck) | $0 | — |

**Headline: a fresh external attacker can extract $0.00 from SYMMIO-IOTA. High confidence.**

## Live state

- Collateral: **USDT** (`0xC1B8045A6ef2934Cf0f78B0dbD489969Fa9Be7E4`, LayerZero OFT "Tether USD", 6 dec, total supply 325,633.43).
- Diamond USDT balance: **2,069.000001 USDT** (matches DefiLlama $2,066.9975 for the IOTA EVM deployment).
- Verified diamond (EIP-2535) facets: DiamondCut, Account, Control, DiamondLoupe, Liquidation, PartyA, Bridge, View, FundingRate, ForceActions, Settlement, PartyB{PositionActions,QuoteActions,GroupActions}. Same code lineage as the other SYMMIO deployments (cf. H-04/IntentX).
- **Dormant**: 8 quotes ever (`getNextQuoteId() = 8`), **0 bridge transactions ever**, **0 open positions** for every party (`partyAPositionsCount` = 0 for all three PartyAs; `partyBPositionsCount` = 0 for all pairs), nobody liquidated. Last account activity: 2025-05-08/09; no events after ~block 10.33M.
- Internal balances (18-dec normalised):
  - PartyB contract `0x10b682bf…` (SymmioPartyB proxy): **1,909.992811176** USDT (`balanceOf`), allocated to pairs: 86.706 + 5.087 + 1.38.
  - PartyA `0x9BC9CA7e…` (also the original deployer/admin EOA): **21.860313** USDT allocated.
  - PartyA `0x1072d1DF…`: **29.904034** allocated. PartyA `0x0E47F832…`: **14.000001** allocated.
- Diamond **owner = `0xe639B85B77F5D31d37C52AD1F026C6508f48DC61` — an OZ `TimelockController`** (ownership history: deployer EOA `0x9BC9…` → `0x9CF7…` → timelock; complete log scan).
- Roles: DEFAULT_ADMIN/MUON_SETTER/SYMBOL_MANAGER/SETTER/PAUSER/UNPAUSER/PARTY_B_MANAGER/SUSPENDER = EOA `0x9BC9…`; **LIQUIDATOR_ROLE = 4 operator EOAs** (`0x848736ed…`, `0xb7975d66…`, `0x01b84d06…`, `0x3aF2cafC…`); SYMBOL_MANAGER also `0x85C021aD…`.
- Collateral token approvals: the PartyB proxy approves the diamond (huge allowance); the diamond itself holds the 2,069 USDT.
- Muon oracle config set: appId, compressed public key `(x, parity)`, gateway EOA `0xF621f85f20BBe733699306D336230184621dBe60` (expected EOA signer — the Muon gateway key).

## Attack-surface analysis (every value path)

1. **AccountFacet** (`deposit`, `withdraw`, `withdrawTo`, `internalTransfer`, `allocate`, `deallocate`, `transferAllocation`, `depositFor`, reserve vault ops): all value moves are keyed on **`msg.sender`**; `withdrawTo(user, amount)` only ever debits the *caller*. `withdraw` has an explicit **12h `deallocateCooldown`** (43,200 s) since the user's last `withdrawCooldown` — an anti-flash-deposit guard. → outsider cannot touch others' balances.
2. **LiquidationFacet**: `liquidatePartyA`, `liquidatePartyB`, `setSymbolsPrice`, `deferredLiquidatePartyA`, `deferredSetSymbolsPrice`, `liquidatePendingPositionsPartyA`, `liquidatePositionsPartyA/B` are **`onlyRole(LIQUIDATOR_ROLE)`** in this deployment (unlike older versions). `settlePartyALiquidation` is permissionless but requires a liquidation already in progress and pays the *parties*, not the caller. No account here is liquidatable anyway (no positions, positive balances, `liquidatorShare = 0.5` irrelevant).
3. **SettlementFacet.settleUpnl**: `onlyPartyB` + Muon settlement signature; settlement moves value between the two parties per signed uPnL — no caller gain.
4. **ForceActionsFacet** (`forceCancelQuote`, `forceCancelCloseRequest`, `forceClosePosition`, `settleAndForceClosePosition`): Muon price signature + cooldowns; none can pay the caller.
5. **BridgeFacet**: `withdrawReceivedBridgeValue(s)` is permissionless but pays the *recorded receiver* of a RECEIVED bridge tx; **`getNextBridgeTransactionId() = 0`** → no transactions exist → moot. `transferToBridge` is self-scoped.
6. **ControlFacet**: every setter is role-gated; ownership sits behind the timelock.
7. **SymmioPartyB proxy `0x10b682bf…`** (impl `0x92ec3ce7…`): `_call`/`_multicastCall` (the only way to make the PartyB contract call the diamond) require **MANAGER_ROLE or TRUSTED_ROLE**; `withdrawERC20` requires MANAGER_ROLE; `_approve` requires TRUSTED_ROLE. Live roles: MANAGER = `0x9CF7EEe9…`, TRUSTED = 13 addresses (incl. `0x9BC9…`), PAUSER = `0x9BC9…`, UNPAUSER = `0x9CF7…`, **DEFAULT_ADMIN has 0 members** (role set frozen). So the PartyB's 1,909.99 USDT is withdrawable only by those key-holders (P/H-O), never by a fresh attacker.
8. **Other proxy `0x57Be055F…`** (impl `MultiAccount` `0xf3e94efc…`): the depositor-for-two-PartyAs contract; not a registered PartyB; no unprivileged path found.
9. **Muon signature forgery**: not attempted to be broken; the same Muon TSS/gateway scheme was audited under H-04 for the sibling deployments and every value path requires valid signatures. On IOTA, signatures are additionally gated behind roles for liquidation. Residual theoretical risk only.

## PoC (`poc/test/SymmioIota.t.sol`) — 11/11 PASS (fork block 13,020,955)

- `test_state_pins` — diamond USDT = 2,069.000001; next bridge tx = 0; all positions 0; not liquidated; PartyB internal balance 1,909.992811176; attacker holds no roles; owner is a contract.
- Gates: `withdraw`, `withdrawTo`, `allocate` revert for a zero-balance attacker; `liquidatePartyA` reverts on the **role gate**; `settleUpnl` reverts on the **PartyB gate**; `transferOwnership` reverts `LibDiamond: Must be contract owner`; PartyB `_call` reverts (`Invalid access`); PartyB `withdrawERC20` reverts.
- `test_roundtrip_deposit_withdraw_no_gain` — attacker deposits 10 USDT (after approval), gets exactly 10e18 internal, warps 12h+1s, withdraws 10 USDT → **exactly break-even**, diamond untouched.
- `test_deallocate_requires_muon_sig` — a dummy upnl signature reverts.

## Negative results (do not re-investigate)

- No permissionless liquidation (role-gated on IOTA).
- No permissionless bridge withdrawal of value (0 bridge txs; receiver-bound anyway).
- No cross-account withdrawal/deposit debit; no rounding gain on round trips; 12h withdraw cooldown.
- No PartyB-contract multicall access without MANAGER/TRUSTED; no role enumeration left open (DEFAULT_ADMIN empty).
- Not liquidatable: 0 positions, positive balances.

## Residual/latent risk

- **P:** the timelock owner + role EOAs can reconfigure (Muon ids, collateral, symbols) and (via ProxyAdmin `0xe42758ad…` / `0x2717749d…`) upgrade the PartyB/MultiAccount proxies; the diamond itself is EIP-2535-upgradeable by the owner.
- **S (conditional):** the 1,909.99 USDT internal balance of the PartyB contract requires its MANAGER/TRUSTED key-holders to act; if those keys are lost, funds are stuck (not extractable by others).
- **H-04 cross-reference:** the `SymmioPartyB isCallFromInstantLayer` bug found on other chains does **not** exist in this deployment's implementation (this is a different, role-gated multicall PartyB).

## Files

- `poc/test/SymmioIota.t.sol` — PoC.
- `analysis/symmio-iota/state.json` — raw reads + facets + roles + logs summary.
