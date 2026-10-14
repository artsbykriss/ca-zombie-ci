# Printr (Base + Ethereum + Mantle + BSC + Avalanche + Arbitrum + Monad) — L2 Phase-2 deep dive: live unprivileged extraction

**Campaign:** zombie-hunt II · L2 watchlist Phase 2 · **Finding:** L2-Triage-A row 45 (`printr`)
**Chains:** Ethereum, Base, Mantle, BSC, Avalanche, Arbitrum, Monad (Solana leg out of scope)
**Date of work:** 2026-10-14 · **Status:** read-only; PoC fork-verified only; **no mainnet transactions**

**Triage input:** $40,000 live (treasury `0x8c843012…3fee` on all EVM chains via CREATE3).
**Re-verified and extended:** live value today is **≈ $41.2k** (treasury balances, all 7 EVM chains).
**External unprivileged attacker extraction (E-U): $0.00.** Every value-moving path is gated — treasury →
core-contract-only (immutable `printr`), admin → owner EOA (Ownable2UnauthorizedAccount), cross-chain minting →
LZ channel + hard-coded Solana peer, trading → fee-charged bonding curve with protocol-favouring rounding.
The $41.2k is **holder-recoverable** (H-O): telecoin holders can sell back into the curve and pull the basePair
reserves out of the treasury — self-service, not attacker-profitable.

> One-liner: an external attacker cannot take the Printr treasury; the money is the bonding-curve reserve that
> token holders can redeem, and every privileged/cross-chain path is correctly access-controlled and fork-verified.

---

## 1. TL;DR

| # | Target | Live value now | E-U (unprivileged) | Why open / closed | Latent risk |
|---|---|---|---|---|---|
| 1 | Treasury `0x8c843012…3fee` (7 chains) | ≈ $41.2k (WETH/WBNB/WAVAX/WMNT/WMON/USDC) | **$0** | `withdraw` gated on immutable `printr` = core; attacker → `WrongAccess()`, core → OK (fork-proven) | Owner EOA can upgrade module (P); key compromise = total loss |
| 2 | Legacy treasury `0xde420c83…1549` | unmigrated residue (eth) | **$0** | same `printr` gate (fork-proven) | none (immutable) |
| 3 | Bonding curves (5,343 telecoins on ETH alone) | curve reserves = the treasury balance | **$0** | 1 % fee both ways + rounding in protocol favour; round trip loses money (fork-proven) | none found |
| 4 | Cross-chain mint (`receiveFromChannel`) | n/a | **$0** | requires CREATE3 channel + `protocol==2` + hard-coded Solana peer `0x27289e1d…3b5f` (fork-proven) | LZ DVN/peer compromise on Solana side |
| 5 | Protocol/LP fee collection | ≈ $38 measured on 3 ETH tokens | **$0** | `collectProtocolFees`/`collectLiquidityFees` are permissionless to trigger but pay only funds/creator/stakers (fork-proven: attacker delta 0) | none for attacker |
| 6 | Admin surface (pause/upgrade/ownership/LZ config) | n/a | **$0** | `OwnableUnauthorizedAccount` for attacker on every entry point (fork-proven) | owner EOA `0x8dd1886b…c273` |
| 7 | Creator NFT `printrDev` mint | n/a | **$0** | mint from attacker reverts `0x878d41a8` | none |

**Total live extractable by an external unprivileged attacker today: $0.00** — confidence **HIGH** (fork-verified call-path matrix; all gates exercised live at block 26,192,609).

## 2. The protocol (what Printr actually is)

Printr is a **live** (launched Oct 2025, V2 Apr 2026) cross-chain token launchpad: creators “print” a telecoin on
one or several chains at once; each chain runs its own **linear bonding curve** (`(virtualReserve + reserve) × tokenReserve = k`)
that graduates into a locked UniV3/Uniswap-fork pool. A shared treasury per chain holds the basePair reserves
(`treasury()` = `0x8c843012…` on every chain). Fees: 1 % trading fee; collected fees are split
team 70 % / creator 30 % (growth & buyback = 0 on Ethereum) and, when POB staking is enabled, routed to the
PrintrStaking contract. Cross-chain transfers (“teleport”) use LayerZero V2 channels.

Delegate chain on Ethereum (all proxy-read):
`0xb77726…3172` (PrintrProxy, ERC1967) → impl `0x014da58b…68ba` → fallback → teleport `0xc5e0c0ec…f8bd` → fallback → module `0xb163ec43…e6d1`.

Live addresses, roles, balances and block numbers: **`analysis/LIVE-STATE.md`** (all chains, exact reads).

## 3. The audit — every value-moving path, with live gating values

Full detail in `analysis/LIVE-STATE.md`; the fork matrix lives in `poc/test/PrintrLive.t.sol`.

1. **Treasury withdrawal.** The treasury’s `printr()` is an **immutable** = the core proxy. `withdraw` from an
   attacker reverts `WrongAccess()`; from the core address it succeeds (same for the legacy treasury). The core
   only calls `withdraw` inside `buy`/`sell`/`_migrateTreasury`, i.e. against payment or against tokens being
   surrendered. No path lets an attacker call it with an arbitrary recipient.
2. **Trading math.** `_estimateTokenCost` rounds cost **up**, `_estimateTokenRefund` rounds refund **down**,
   `_quoteTokenAmount` subtracts 1 wei on inexact division; both sides pay the 1 % `tradingFee`. A buy→sell
   round trip therefore always ends below the starting balance (fork-proven on 3 live Ethereum curves).
   Price limits (`maxPrice`/`minPrice`) only cap the user’s own fill; they cannot be inverted for profit.
3. **Cross-chain mint (`receiveFromChannel`).** Fork matrix: direct attacker → `UnauthorizedCaller()`;
   the real LZ channel with a **wrong** peer → `UnauthorizedCaller()`; the real channel with the hard-coded
   Solana peer `0x27289e1d…3b5f` → passes auth and reaches payload parsing (`InvalidPayloadLength()` on an
   empty message). So minting requires a genuine LayerZero message whose originSender is the Printr Solana
   program. `teleportIn/Out` on the token contracts are additionally `msg.sender == printr`-gated.
4. **Fee distribution.** `collectProtocolFees`/`collectLiquidityFees` are **permissionless to trigger** but the
   amounts are paid to the platform funds / creator NFT owner / stakers. Fork: attacker calls succeed on three
   tokens with accumulated fees (0.000659 / 0.013980 / 0.000637 WETH) and attacker ETH/WETH/token deltas are **0**.
5. **Admin surface.** `pause`, `unpause`, `transferOwnership`, `renounceOwnership`, `upgradeToAndCall`,
   `updateGlobalProtocols` all revert `OwnableUnauthorizedAccount` for the attacker; `setLzDelegate` and
   `updateTelecoinProtocols` are owner-gated as well. Owner = EOA `0x8dd1886ba3ab106f595ab7a8a831577c2d21c273`.
6. **Creator NFT.** `printrDev.mint(telecoinId, attacker)` reverts (`0x878d41a8`) — creator-fee capture via
   self-minted NFTs is closed.
7. **Witness/permit flows** (verified `PrintrTelecoin` source): `permitWitnessCall` binds the whole inner call
   (target/method/nativeValue/params) into the EIP-712 witness, enforces `params[0:32] == owner`, uses nonces and
   deadlines; `witnessSell` additionally requires `msg.sender == token`. No redirect/replay path found.

**Negative results (so they are not re-investigated):** LZ_SECURE/LZ_SLOW channels are **not deployed** on
Ethereum (`getLzChannel(3/4)` → codeless addresses; only LZ_FAST works); the legacy treasury holds only spam
tokens ($0 non-spam) and is gated identically; the staking contract holds dust on Ethereum ($0) and $0.02 on
Base; thousands of telecoins in the treasury are spam-flagged dust (no market); the LP locker
(`UniV3LPLocker`, verified) is a standard third-party locker — its `unlock` requires the lock owner + expiry,
and only its `collector` (protocol) can harvest fees; `paused == false` on every chain checked
(ETH/Base/Mantle/BSC/AVAX/Arbitrum/Monad) and the owner is the same EOA `0x8dd1886b…c273` on all of them.

## 4. Live value inventory (all EVM chains)

| chain | treasury value | block / source |
|---|---|---|
| Ethereum | $10,485.25 (4.264570 WETH) | 26,192,609 · GoldRush + fork |
| Base | $3,911.99 (1.567211 WETH + 62.66 USDC) | GoldRush 2026-10-14 |
| BSC | $6,092.72 (8.283933 WBNB) | GoldRush 2026-10-14 |
| Avalanche | $3,114.38 (312.341290 WAVAX) | GoldRush 2026-10-14 |
| Monad | $6,148.93 (253,980.017 WMON) | GoldRush 2026-10-14 |
| Mantle | $10,969.93 (21,049.599 WMNT) | GoldRush 2026-10-14 |
| Arbitrum | ≈ $515 (0.2066 WETH) | triage row (GoldRush HTTP 552 at retry) |
| **total** | **≈ $41,238** | |

Classification: **E-U $0**; **H-O ≈ $41.2k** (curve reserves, redeemable by telecoin holders via `sell`);
**P** = accumulated protocol fees (measured $38 on 3 sampled Ethereum tokens; unmeasured elsewhere, small);
**S** = dust telecoins/stranded balances (≈ $0).

## 5. PoC / fork-verification

- Project: `poc/` (Foundry, vendored forge-std). Test: `poc/test/PrintrLive.t.sol` — 5 tests, **5/5 PASS**
  on an Ethereum mainnet fork at block **26,192,609** (CI log: `ci-log.txt`, run
  https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38617506210).
- Tests: `test_treasury_access_control`, `test_admin_functions_closed`, `test_receiveFromChannel_gates`,
  `test_buy_sell_roundtrip_no_profit`, `test_collectProtocolFees_not_profitable`.
- Key CI numbers: treasury WETH = 4,264,570,067,570,463,102 wei; attacker withdraw → `WrongAccess`;
  core withdraw → success; admin → `OwnableUnauthorizedAccount`; wrong peer → `UnauthorizedCaller`;
  correct peer → `InvalidPayloadLength`; collectProtocolFees attacker deltas = 0.
- Second CI run (with ERC20 approval added so the holder `sell` leg executes): see `ci-log.txt` / run URL above.

## 6. Verdict & residual risk

An external, unprivileged attacker with only capital/flash loans **cannot extract value from Printr today**:
the $41.2k in the treasuries is either the bonding-curve reserve backing token holders’ self-service sells
(H-O) or protocol/creator fees (P). All admin and cross-chain entry points are correctly gated, and the
trading math cannot be round-tripped at a profit.

Residual/latent risks (not E-U): (a) the module/proxy owner is a single EOA `0x8dd1886b…c273` — a key
compromise would allow an upgrade to drain everything (privileged); (b) cross-chain minting depends on the
LayerZero DVN set and the Solana Printr program — a compromise there would let forged messages mint telecoins
that could be sold into the curve; (c) LZ_SECURE/SLOW channels are undeployed on Ethereum (liveness only).

## 7. Methodology & sources

Read-only RPC (`eth_call`/`eth_getStorageAt`/`eth_getCode`) at pinned blocks; Etherscan V2 metadata for
verified sources (PrintrProxy, PrintrCore v1.0.0 reference, PrintrTelecoin, UniV3LPLocker, Create3Deployer,
PrintrStakingProxy); heimdall-rs + evmole decompilation of unverified impls; GoldRush balances for the value
inventory; Printr docs (GitBook) + DefiLlama adapter for architecture; Foundry fork PoC executed on GitHub
Actions (`artsbykriss/ca-zombie-ci`). Full file index in `analysis/`. No secrets are stored in this folder.

## 8. Caveats & limitations

- The deployed impl/teleport/module are **unverified**; behaviour was established from bytecode selectors,
  decompilation and live/fork execution, not source. The PrintrCore v1.0.0 verified source (BSC) is close but
  not identical to the deployed version (print/fee-distribution moved to the module); the fork tests exercise
  the *deployed* bytecode.
- Arbitrum treasury balance is carried over from the triage row (GoldRush HTTP 552 during this run).
- P (accumulated fees) is only measured on 3 sampled Ethereum tokens; no full enumeration of 5,343 telecoins.
- Solana leg is out of scope for this EVM-focused review.
