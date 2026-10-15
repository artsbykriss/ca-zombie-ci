# Negative results / closed paths (do not re-investigate)

All checks read-only; fork tests in `poc/`; blocks: BOT 26,768,090 · Anubis 16,530,758 · ETH 26,197,551 · BSC 127,779,417 · POL 95,572,496.

## RocketSwap Anubis (chain 6714)

| # | Path tested | Result | Evidence |
|---|---|---|---|
| A1 | DEX core bug (swap/mint/burn/skim/sync/k-invariant) | **Closed** — faithful 0.8.20 port of canonical UniV2; only revert strings renamed | source diff `analysis/src_rocketswap_anubis/` vs v2-core master; `test_v2_swap_is_canonical` (100k DAI → 97,039 USDT = exact formula), `test_v2_lp_roundtrip_no_free_money` |
| A2 | `skim()` excess | **Closed** — reserves == balances in all top pools; `skim` pays 0 | `test_no_skimable_excess_in_top_pools` (DAI/USDT, Rome/USDT, LGNS/DAI) |
| A3 | Mint synthetic DAI/USDT directly | **Closed** — `Only public bridge` / `Only private bridge` | `test_token_mints_are_bridge_gated` |
| A4 | Forge a Hyperlane message to mint via the bridge | **Closed** — ISM rejects; needs 2-of-3 validator ECDSA | `test_forged_message_rejected_empty_metadata`, `test_forged_message_rejected_fake_signature`; ISM impl byte-matches `@hyperlane-xyz/core` v10.1.5 (`analysis/ism_bytecode_check.md`) |
| A5 | Modified/weak ISM or mailbox | **Closed** — Mailbox source == canonical Hyperlane `Mailbox.sol`; ISM = canonical multisig; both immutable/owner-gated | source diff; `recipientIsm(bridge)` == `0x966b2626…` read live on 4 chains |
| A6 | `claimPending` theft / double claim | **Closed** — `_settlePendingClaim(tokenId, msg.sender, …)` only settles the caller's own claim; daily-limit re-checked; revert on failed delivery | bridge source lines 352–368, 517–541 |
| A7 | `ProtocolReserve.withdraw` (56.78M DAI) | **Closed** — `ProtocolReserve: not admin` | `test_protocol_reserve_withdraw_is_admin_gated` |
| A8 | Pool counterparty tokens mintable | **Closed** — LGNS (`LGNS: not minter`), AiLGNS (no mint fn), GLGNS (fixed), Rome (`AccessControlUnauthorizedAccount`), ADAO2/GOT (`VaultOwned: caller is not the Vault`), Gladiator (revert), synthetics (bridge-gated) | mint simulations per token; sources in `analysis/anu_tok_*.json` |
| A9 | Outbound `bridge()` abuse (burn without release, fee refund reentrancy) | **Closed** — burn → dispatch; refund after effects; `nonReentrant`; no caller payout | bridge source `_bridge()` |
| A10 | Uninitialized proxy / claimable ownership | **Closed** — all proxies initialized (owner 0x73d72977… on every chain); UUPS `_authorizeUpgrade onlyOwner` | live reads of `owner()` on 4 chains |
| A11 | Cross-bridge / cross-chain replay | **Closed** — message id includes destination+recipient; mailboxes track deliveries; per-bridge ISMs differ | mailbox source; ISM/router configs per chain |
| A12 | Arb between Anubis pools (stale prices) | **Not found** — DAI/USDT pair at 1:1; pool prices consistent with each other | reserves reads; no external price oracle in the protocol |

## BDEX V3 / V2 (BOT chain 677)

| # | Path tested | Result | Evidence |
|---|---|---|---|
| B1 | V3 core bug | **Closed** — byte-identical to canonical Uniswap v3-core v1.0.0 | source diff (factory, pool, deployer, NoDelegateCall exact) |
| B2 | V2 core bug | **Closed** — canonical v2-core, revert strings renamed only | source diff |
| B3 | `USDT.mint` (15.6M in the main pool) | **Closed** — `AccessControlUnauthorizedAccount` (MINTER_ROLE on EOA 0x7800c931…) | `test_usdt_mint_is_role_gated`; RoleGranted/RoleRevoked logs |
| B4 | `USDT0` / other pool counterparties mintable | **Closed** — USDT0 has no mint selector; CA/Perla/FlowToken/TestToken fixed supply; BOUSDT role-gated; others no mint | selector scan + mint simulations |
| B5 | V3 factory admin (`setOwner`, `enableFeeAmount`) | **Closed** — Ownable-gated | `test_v3_factory_setOwner_is_owner_gated` |
| B6 | Price dislocation V2 vs V3 (free arb) | **Closed** — $12.28 vs $12.45 (≤1.4%) | `test_wbot_price_consistent_v2_vs_v3` |
| B7 | Free money via pool round trip | **Closed** — 1 WBOT → 12.4 USDT → 0.994 WBOT (2×0.3% fee) | `test_v3_swap_roundtrip_no_free_money` |
| B8 | `skim` equivalent | n/a (UniV3 has no skim); no donation excess observed in balances | `ci-out/bot_state.json` |

## Dead ends / notes

* Anubis RPC (`rpc.anubispace.org`) rate-limits aggressively — all reads used retries; some `cast` calls return empty on first attempt.
* ISM implementation is unverified on all explorers; IPFS metadata gateway is blocked (403/"blocked"); resolved by npm-artifact byte comparison.
* `0x27Cb55eE…` (56.78M DAI "ProtocolReserve") looks like a vault but is admin-gated.
* The RocketSwap pair list was enumerated fully (861 PairCreated events) but reserve-level inspection focused on the top pools by holder size; smaller pools (<$1k) were not individually re-checked.
