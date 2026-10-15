# BDEX V3 (BOT Chain) + RocketSwap-Anubis (Anubis) — zombie-hunt II, L2-23 deep dive

**Date:** 2026-10-15 · **Chains:** BOT Chain (677), Anubis (6714) · **Status:** read-only; fork-verified only; no mainnet transactions.
**Scope:** L2-23 (BDEX V3 / RocketSwap-Anubis-class). The STRATO part of L2-23 was already covered under H2-05 and is **not** re-done here.

---

## 1. TL;DR

| Target | Chain | Lead (DefiLlama) | Live value verified | External-unprivileged extractable (E-U) | Why closed | Latent risk |
|---|---|---|---|---|---|---|
| **BDEX V3** | BOT Chain (677) | $31.05M | 24 UniV3 pools; main USDT/WBOT pool = **15,625,899.53 USDT + 1,255,110.55 WBOT** (~$31.2M) | **$0** (high confidence) | Core is **byte-identical to canonical Uniswap V3 v1.0.0**; USDT mint is `MINTER_ROLE`-gated (EOA); every pool counterparty token is fixed-supply or role-gated; V2/V3 prices agree (no arb); factory admin functions owner-gated | Owner EOA `0x4a1aAD…930e` + USDT minter EOA `0x7800c931…42b1` can mint/alter (P). "USDT" is **team-issued**, not canonical Tether — TVL is only as real as the issuer |
| **RocketSwap Anubis** | Anubis (6714) | $354.2M (DAI $209M + USDT $145M) | 861 UniV2 pairs; synthetic DAI supply 257.76M, USDT 162.48M; DAI/USDT pair 3.27M/3.28M; top pools paired with LGNS/AiLGNS/GLGNS/Rome/GOT… | **$0** (high confidence) | Pair/factory are a faithful 0.8.20 port of canonical UniV2 (diff = revert strings only); synthetic mint is gated to two bridges whose inbound path requires a **canonical Hyperlane 2-of-3 multisig ISM** (byte-identical to `@hyperlane-xyz/core` v10.1.5) behind a **canonical Hyperlane Mailbox**; `ProtocolReserve` withdraw is admin-gated; no skim excess; no mintable pool counterparty | Whole system (Anubis $354M + source-chain collateral ≈$424M) controlled by one **owner EOA** (UUPS upgrades, ISM/router config) + 2-of-3 EOA validator sets per bridge (P) |

**Total live extractable by an external unprivileged attacker, now: $0.00 — high confidence.**
(Latent/privileged exposure: ≈$354M on Anubis + ≈$424M collateral on Ethereum/BSC/Polygon, reachable only with owner/validator keys.)

---

## 2. What the "gated" claim actually is (mechanism in exact terms)

### 2.1 RocketSwap Anubis — the $354M is synthetic, minted by a Hyperlane bridge

* Both "DAI" and "USDT" on Anubis are **`HyperlaneSyntheticToken`** contracts (`mintPublic`/`mintPrivate` callable **only** by `publicBridge`/`privateBridge`, set by the owner):
  * DAI `0x83fd06F0846d9D90B3016bF670Efe2E0B11cDe14` (18 dec, supply 257,756,442.76)
  * USDT `0xDfb6a28BC6DC51fed17c27C880F2c66cDd040A3e` (6 dec, supply 162,475,388.95)
* The bridges are **`HyperlaneTokenBridge`** UUPS proxies (`0x8932fe77…` public, `0x250BA4E7…` private), deterministic same-address deployments on **Anubis, Ethereum, BSC and Polygon**. Registered tokenIds (e.g. USDT `0x8b1a1d9c…`, DAI `0xa5e92f3e…`) point at the same router addresses on domains 1 (Ethereum), 56 (BSC), 137 (Polygon).
* Inbound `handle(origin, sender, message)` is `onlyMailbox` **and** requires `sender == remoteRouters[tokenId][origin]`; delivery is capped by a per-token 24h limit (public bridge: 1e12 shared USDT / 1e24 shared DAI per day; excess is parked as a pending claim). Private bridge has no limit but a whitelist and a separate validator set.
* The gate is the **ISM**: both mailboxes use `StaticMerkleRootMultisigIsm` (moduleType 4) with **threshold 2 of 3 validators**:
  * public: `0x0b709a7b…`, `0x4D27EfE4…`, `0xD1C2E530…`
  * private: `0x24e91219…`, `0x601518ec…`, `0xac950893…`
  * identical sets on all four chains; all six validators are **EOAs**.
* **Byte-level verification of the gate** (analysis/ism_bytecode_check.md): the deployed ISM implementation `0x6ce8c447…` (solc 0.8.22) is **byte-identical to the official `@hyperlane-xyz/core` npm artifact of `StaticMerkleRootMultisigIsm`** for every release 6.0.0→10.0.0 except the 7-byte `PACKAGE_VERSION` string, which reads **"10.1.5"** on-chain — i.e. the unmodified Hyperlane v10.1.5 multisig ISM. The Mailbox implementation `0x5a197a5f…` matches canonical `solidity/contracts/Mailbox.sol` (comment-only diff).
* Collateral backing the synthetics (read live): Ethereum 2.67M USDT + 51.28M DAI + 0.60M USDC + 234 ETH (public) and 155.0M DAI (private); BSC 114.60M USDT + 0.34M USDC + 0.14M DAI + 390 BNB; Polygon 45.38M USDT + 51.80M DAI + 1.00M USDC + 2.65M POL. ≈**$424M** total (stablecoins at face value + ~$1.7M native) — the system is fully collateralised.

### 2.2 The DEXes themselves

* **BDEX V3** factory `0x1C51c173…` (BOT): `UniswapV3Factory/Pool/PoolDeployer/NoDelegateCall` are **diff-clean vs Uniswap v3-core v1.0.0**; libraries differ only by pragma bounds/comments.
* **BDEX V2** factory `0x117115f3…` (BOT): canonical v2-core, only revert strings renamed ("BotDexV2: …").
* **RocketSwap Anubis** factory `0xaf6F4e64…`: a 0.8.20 rewrite of UniV2 — `swap/mint/burn/skim/sync` and the k-invariant are identical to upstream (only revert strings renamed, SafeMath → native checks); `feeTo` set (0x88355d3a…), `feeToSetter` EOA-gated.

### 2.3 Token-level checks (the classic "mint the counterparty and drain the pool")

| Chain | Pool (largest) | Counterparty token | Mint attempt result |
|---|---|---|---|
| Anubis | LGNS/DAI (45.5M DAI) | Longinus (LGNS) | `LGNS: not minter` |
| Anubis | DAI/GLGNS (16.9M DAI) | GLGNS | fixed supply (constructor-only mint) |
| Anubis | AiLGNS/DAI (13.2M DAI) | AiLGNS | no mint function in bytecode |
| Anubis | Rome/USDT (34.3M USDT) | Rome (RM) | `AccessControlUnauthorizedAccount` |
| Anubis | ADAO2/USDT (19.4M USDT) | Anubis DAO2 | `VaultOwned: caller is not the Vault` |
| Anubis | GOT/USDT (10.0M USDT) | GOLDEN PACT | `VaultOwned: caller is not the Vault` |
| Anubis | Gladiator/USDT (2.5M USDT) | Gladiator | revert (no public mint) |
| Anubis | DAI/`0xA921267c…` (5.3M DAI) | Hyperlane synthetic | bridge-gated (2-of-3) |
| BOT | USDT/WBOT (15.6M USDT) | — | `USDT.mint` → `AccessControlUnauthorizedAccount` |
| BOT | USDT0/USDT (105k USDT) | USDT0 | no mint function |
| BOT | CA/WBOT, Perla/WBOT, Kenostod/WBOT, FlowToken/USDT, TestToken/WBOT | all | fixed supply / no mint |

Also closed: `ProtocolReserve` `0x27Cb55eE…` (holds **56.78M DAI**) → `withdraw(...)` reverts `ProtocolReserve: not admin`.

---

## 3. Live-state assessment (recorded blocks: BOT 26,768,090 / Anubis 16,530,758; ETH 26,197,551 / BSC 127,779,417 / POL 95,572,496)

| Item | Value |
|---|---|
| RocketSwap factory | `0xaf6F4e641C86A25518509BC840051A8652Af598A` — 861 pairs, `feeTo` 0x88355d3a…, `feeToSetter` 0xc5127Bb1… |
| DAI/USDT pair | `0xF14C0e3D…` — 3,267,322.87 DAI + 3,277,215.53 USDT (1:1) |
| Synthetics | DAI 257.76M (18 dec) / USDT 162.48M (6 dec); owner 0x73d72977… |
| Bridges | public/private proxies at 0x8932fe77…/0x250BA4E7… on 4 chains; **not paused**, whitelist off (public) / on (private); owner 0x73d72977… (EOA) |
| Mailboxes | 0x599899e6… / 0xbC9de608… (canonical Mailbox; localDomain 1/56/137/6714) |
| ISMs | 2-of-3 (validators above); immutable MetaProxies |
| ProtocolReserve | 56,783,788 DAI; `withdraw` admin-gated |
| BDEX V3 factory/pool | `0x1C51c173…` / `0x64F41847…` — 15.63M USDT + 1.255M WBOT; implied WBOT = **$12.45** |
| BDEX V2 WBOT/USDT | `0xdc7547f3…` — 3,030.86 USDT + 246.84 WBOT → **$12.28** (≤1.4% from V3 → no arb) |
| BOT USDT | supply 73.96M; `DEFAULT_ADMIN_ROLE`+`MINTER_ROLE` on EOA `0x7800c931…` (second minter revoked at block 1,047,754) |
| WBOT | canonical WETH (0.7.6), supply 1.271M |

---

## 4. What an attacker can / cannot do (exact paths)

**Cannot:**
1. `synthetic.mintPublic/mintPrivate` → `Only public/private bridge` (fork-proven).
2. `mailbox.process(metadata, forgedMessage)` → ISM rejects: empty metadata reverts; a fake root + zero signature reverts; the 2-of-3 ECDSA check cannot be satisfied without validator keys (fork-proven; the ISM bytecode is the canonical Hyperlane v10.1.5 implementation).
3. Mint any pool counterparty token (table in §2.3).
4. `ProtocolReserve.withdraw` → `not admin`.
5. Drain pools: swaps/LP mint-burn are canonical (fork-proven: 100k DAI in → 97,039 USDT out = exact x·y=k with 0.3% fee; LP round trip returns ≤ deposit). `skim()` pays **0** (reserves == balances at the pinned block in all top pools).
6. BOT: `USDT.mint` → `AccessControlUnauthorizedAccount`; `USDT0` has no mint; `V3factory.setOwner` → revert; the V3 swap round trip (1 WBOT → 12.4 USDT → 0.994 WBOT) loses the 2×0.3% fee — no free money.
7. No oracle: neither DEX uses an external oracle; UniV3 prices come from its own pool state (manipulation is only a cost, not a free mint), UniV2 uses the k-invariant.

**Could (only with keys — P):**
* Owner EOA `0x73d72977…` can upgrade both bridges (UUPS), re-point routers/ISMs, set bridges on the synthetic tokens and mint unlimited (full $354M/$423M control).
* Any 2 of the 3 validators per bridge can mint on Anubis / release collateral on source chains (daily limits only on the public bridge).
* BOT: USDT minter EOA can mint unlimited USDT; V3 factory owner can set fee protocol tiers; both are privileged.

---

## 5. Fork verification (CI)

* **15/15 tests pass on GitHub Actions** (`artsbykriss/ca-zombie-ci` run [38733786859](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38733786859)) — `poc/test/Anubis.t.sol` 9/9, `poc/test/Bdex.t.sol` 6/6, plus the custom job that wrote `ci-out/anubis_state.json` and `ci-out/bot_state.json` (block 16,537,060 / 26,776,508). Log: `ci-log.txt`; artifacts: `ci-artifacts/`.
* Key tests: `test_forged_message_rejected_empty_metadata`, `test_forged_message_rejected_fake_signature`, `test_ism_is_canonical_2of3`, `test_token_mints_are_bridge_gated`, `test_protocol_reserve_withdraw_is_admin_gated`, `test_no_skimable_excess_in_top_pools`, `test_v2_swap_is_canonical`, `test_v2_lp_roundtrip_no_free_money`, `test_usdt_mint_is_role_gated`, `test_usdt0_has_no_mint_function`, `test_v3_swap_roundtrip_no_free_money`, `test_wbot_price_consistent_v2_vs_v3`.
* Evidence: `ci-out/anubis_state.json`, `ci-out/bot_state.json` (state snapshots), `analysis/live_state_evidence.json`, `analysis/ism_bytecode_check.md`.

---

## 6. Verdict & residual risk

* **E-U: $0.00 (high confidence)** for both targets. The "gated" prior is **confirmed**: the Anubis $354M is mint-gated by a canonical Hyperlane 2-of-3 multisig behind a canonical Mailbox; the BOT $31M sits in canonical UniV3 pools whose only meaningful tokens are a team-issued USDT (role-gated) and canonical WBOT.
* **H-O:** ≈$354.2M LP-owned pool value on Anubis (LPs can `burn` directly) and ≈$424M collateral redeemable by synthetic holders via burn→bridge (public bridge rate-limited to 1M USDT/1M DAI per 24h; private bridge unlimited but whitelisted). LP value on BOT ≈$31.2M. *(Note: the Anubis synthetic pools and the source-chain collateral are two sides of the same system — they are reported separately, not summed.)*
* **P:** the entire system — owner EOA (upgrades/config) + 2-of-3 validator EOAs per bridge + BOT USDT minter EOA. Privileged reach = Anubis synthetic system (≈$354M) **and** source-chain collateral (≈$424M) = ≈$778M nominal (double-counted across the two sides by construction).
* **S:** none (nothing bricked; both chains live and producing blocks).
* **Latent risks to watch:** (i) validator/owner key hygiene is the whole security model — a single leaked key pair (2 of 3) mints/releases everything; (ii) BOT-chain "USDT" is a team-issued token — if the issuer stops honouring it, the BDEX V3 TVL evaporates (no E-U, but a TVL-integrity caveat); (iii) the public bridge's daily mint limit is 1M USDT/1M DAI per 24h while the pools hold 100× that — a run on the bridge is rate-limited, not impossible.
* **Blockers encountered:** the Anubis RPC is rate-limited/flaky (retries used); the ISM implementations are unverified on explorers (resolved by byte-matching against the npm artifact).

---

## 7. Methodology, sources, caveats

* Read-only: `cast`/Blockscout APIs/public RPCs; forks in Foundry; **no transactions**.
* Byte-level comparisons: Uniswap v3-core v1.0.0 and v2-core (GitHub tarballs) vs verified explorer sources; `@hyperlane-xyz/core` npm artifacts (v6.0.0–v10.0.0) vs deployed ISM runtime bytecode (metadata-stripped) — match found, only `PACKAGE_VERSION` differs, deployed value "10.1.5".
* Caveats: USD figures at face value of stablecoins; BOT-chain USDT is not canonical Tether; periphery contracts (routers/NPM) were not exhaustively enumerated (not a pool-funds risk); source-chain collateral snapshot is a point-in-time read; the 861-pair RocketSwap enumeration was validated on the top pools by reserve size, not every pair.
* Files: `analysis/` (sources, diffs, evidence, pool lists), `poc/` (Foundry project), `ci/run.sh`, `ci-out/`, `summary.json`.
