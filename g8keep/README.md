# g8keep (Base) — L2 Phase-2 deep dive

**Date:** 2026-10-15 · **Chain:** Base (8453) · **Status:** read-only; PoC fork-verified only; no mainnet transactions
**Finding:** L2-Triage-A row `g8keep` (triage: LIVE-FUNDED $1,000, medium confidence)
**Folder:** `/home/heisenberg/CA/g8keep/`

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why closed/open | Latent risk |
|---|---|---|---|
| g8keep factory LP positions (77 Uniswap V2 pairs, 32.0467 ETH ≈ **$77,447**) | **$0.00** | LP tokens are held by the factory and permanently locked (`lockedTokens[pair]=1`, no unlock function); every factory exit is `onlyOwner`; LP cannot be burned/transferred by anyone | The pools remain live AMM markets: the WETH can leave only by selling launch tokens into them at AMM price. Owner EOA dormant since 2025-02-12 → if its key revived, only non-LP fee tokens are withdrawable |
| Factory fee-token balances (138 ERC-20s) + penalty-receiver holdings | **$0.00** | `withdrawToken`/`sellTokens` are `onlyOwner`; penalty receiver `transferToken` is allowlist-gated (owner-only) | Owner-key compromise/revival would let the owner sell fee accruals into the locked pools |
| `g8keepVester` deployer vestings (35 vestings) | **$0.00** | `claim(id)` requires `vesting.recipient == msg.sender` | Deployers can still claim (H-O) |
| Snipe-protection logic in `g8keepToken` | **$0.00** | All snipe windows expired (last deployment 2025-01-13; max window 30 days) | None live |

**Total live extractable now: $0.00** (E-U), confidence **high**.
**Value that exists but is not attacker-extractable:** 32.0467 ETH ($77,446.66) locked in factory-held LP (category **S** — nobody, not even the owner, can redeem it), plus illiquid launch-token balances in the factory (owner-only, **P**) and in the vester (recipient-only, **H-O**).

The triage headline ($1,000) came from pricing 3 small pairs only. Full enumeration of all 77 factory-held LP tokens at block 52,628,356 (CI) / ~52,614,511 (local) gives **32.046733 ETH ≈ $77,446.66** of WETH attributable to the factory's locked LP — 77× the triage estimate. None of it is extractable by an unprivileged attacker.

---

## 2. Architecture (verified against deployed code)

g8keep is a Base token-launch platform ("fair launch" launcher with locked initial liquidity and anti-snipe mechanics).

| Contract | Address | Role |
|---|---|---|
| `g8keepFactory` | `0x3C0B43867Cd04fEdfD6a95497e5ea7e3aFF8cCaE` | Permissionless `deployToken`; creates `g8keepToken` via CREATE2, creates the Uniswap V2 pair, adds initial liquidity, **holds the LP forever**; owner-only fee sales/withdrawals |
| `g8keepFactoryConfiguration` | `0x1e72b9aab655dc20427920973fabd99948c812f4` | Deployment config contract (owner-settable params; consumed once at factory construction) |
| `g8keepPenaltyReceiver` | `0x3ac64a6bebebc576bef52fc22ed5e3c64bee4462` | Receives snipe penalties; `transferToken` allowlist-gated |
| `g8keepVester` | `0x254b4A4222285BAa10E6eFce66a6EcfdF5d807A9` | Deployer vesting; `claim(id)` recipient-only |
| Uniswap V2 router | `0x4752ba5dbc23f44d87826276bf6fd6b1c372ad24` | Canonical Base V2 router used by the factory |
| WETH | `0x4200000000000000000000000000000000000006` | Only allowed paired token (`allowedPairs[WETH]=true`; USDC/USDbC/DAI/cbBTC checked = false) |

**Factory owner:** `0x28253c1A76256bf1D9095587826AfCC5705aF98a` — an **EOA** (code size 0), which is also the `g8keepFeeWallet`. Nonce 57; last outgoing tx block 26,298,905 = **2025-02-12** (dormant ~20 months). Owner balance: 0.1542 ETH.

**Key mechanics (source: verified Basescan source, extracted to `analysis/src/`):**

- `deployToken(...)` (permissionless): pulls `_initialLiquidity` of WETH from the caller (msg.value and/or WETH transferFrom), takes a 2% `g8keepInitialLiquidityFee` to the fee wallet, then `addLiquidity` mints the LP **to the factory**, and `lockedTokens[pairAddress] = true` is set *before* minting. There is **no function that ever clears `lockedTokens`**.
- `withdrawToken` reverts with `TokenLocked()` for locked tokens; `sellTokens` and `setApprovalToUniswapRouter` skip locked tokens. Even the owner cannot move the LP.
- `g8keepToken` charges a buy/sell fee (deployer treasury + 1% g8keep fee credited to the factory as internal balances). Transfers `from == G8KEEP` are fee-free. Snipe protection applies only while `block.timestamp < SNIPE_PROTECTION_END` (max 30 days).

---

## 3. Live-state assessment (block ~52,614,511 local / 52,628,356 CI)

### 3.1 Factory

| Item | Value |
|---|---|
| code size | 23,959 bytes, verified `g8keepFactory` (solc 0.8.20) |
| native / WETH balance | 0 / 0 |
| nonce | **79** = EIP-161 start 1 + penaltyReceiver (constructor CREATE) + **77** deployToken CREATE2s → pair enumeration is complete |
| `owner()` | `0x28253c1A…5aF98a` (EOA) |
| `g8keepFeeWallet()` | `0x28253c1A…5aF98a` (same EOA) |
| `penaltyReceiver()` | `0x3ac64a6b…e4462` |
| `g8keepTokenVesting()` | `0x254b4A42…807A9` |
| `g8keepFee` / `g8keepInitialLiquidityFee` | 100 bps / 200 bps |
| `pairedTokenMinimumLiquidity[WETH]` | 0.01 ETH |

**Storage layout verified by direct slot reads:** slot0 = vesting, slot1 = fee wallet, slot2 = packed fees + penaltyReceiver, slot3 = packed deployment settings, slot4 = `allowedPairs`, slot5 = `pairedTokenMinimumLiquidity`, slot6 = `lockedTokens`.

### 3.2 The 77 LP positions

- Enumerated from the factory's ERC-20 balances (GoldRush, 216 items total; 77 `UNI-V2` + 138 other tokens + ETH) — cross-checked against the factory nonce (77 deployments) and the DefiLlama adapter's `TokenDeployed` enumeration.
- All 77 are WETH pairs (`token0 == WETH`). The factory's LP balance equals `totalSupply − 1000` (MINIMUM_LIQUIDITY) in **75/77** pairs; the other 2 pairs have an additional small third-party LP position (2.97e18 and 1.25e20 LP wei; together 0.002396 ETH ≈ $5.79 of the WETH reserves) → the factory holds **~100% of each pair's LP**.
- `lockedTokens[pair] == 1` for **77/77** pairs (verified via `eth_getStorageAt` at slot `keccak256(pair, 6)`; CI re-verified).
- **Total WETH attributable to the factory's LP: 32.046733 ETH = $77,446.66** (ETH $2,416.68, DefiLlama 2026-10-14).
  - Total WETH reserves across all 77 pairs: 32.049129 ETH. Third-party LP (2 pairs) is 0.002396 ETH ($5.79). The rest is the factory's.
  - Largest: `0xc7d9143a…10ced` (HUH / Huh Cat pool) = 17.2665 ETH; then 1.645 ETH, 1.452 ETH, 1.181 ETH, 0.742 ETH …
- **Excess balances: none.** For all 77 pairs, `pair WETH balance == reserve0` and `pair token balance == reserve1` → `skim()` yields nothing anywhere (verified locally and in CI).
- Full table: `analysis/pairs_live.json`, `ci-out/state.json`.

### 3.3 Other value surfaces

| Surface | Contents | Gate |
|---|---|---|
| Factory's non-locked token balances | 138 ERC-20s — 1% g8keep trade-fee accruals + spam airdrops (e.g. G8KEEP, HUH, GATE, TIME, PEPE, DOGE…). No USD quotes (illiquid memecoins) | `withdrawToken`/`sellTokens` = `onlyOwner` |
| `g8keepPenaltyReceiver` | Penalty tokens from sniping across many launches; owner allowlisted (`allowedTransferers[owner] = 1732241073` = 2024-11-22, active) | `transferToken` = `onlyAllowedTransferer` |
| `g8keepVester` | 30+ launch tokens under 35 vestings | `claim(id)` = recipient only |
| `SNIPE_PROTECTION_END` (checked HUH/GATE/G8) | 2024-11-30 / 2024-11-04 / 2024-11-04 — all expired | n/a |

**Timeline:** factory deployed 2024-11-04; last token deployment 2025-01-13 (block 25,007,167); owner's last tx 2025-02-12; last factory-inbound Transfer event 2026-10-09 (sporadic trading of some launch tokens — e.g. HUH fee accruals). GeckoTerminal lists exactly **one** pool for HUH (this g8keep pool) with 24h volume 0 → no external market to source cheap tokens from.

---

## 4. What an attacker can and cannot do

Every candidate path was executed on a Base fork as a fresh EOA (`0xA11CE`), read-only:

| # | Call path | Preconditions | Result |
|---|---|---|---|
| 1 | `factory.withdrawToken(pair, attacker)` | none (permissionless call) | **revert** — Solady `Unauthorized()` (onlyOwner) |
| 2 | `factory.withdrawToken(token, attacker)` (fee tokens) | none | **revert** — onlyOwner |
| 3 | `factory.withdrawETH(attacker)` | none | **revert** — onlyOwner |
| 4 | `factory.sellTokens([...], deadline)` | none | **revert** — onlyOwner |
| 5 | `factory.setApprovalToUniswapRouter(...)` | none | **revert** — onlyOwner |
| 6 | `penaltyReceiver.transferToken(WETH, attacker, 1)` | none | **revert** — `NotAllowed()` |
| 7 | `vester.claim(0)` | none | **revert** — `InvalidCaller()` (recipient-only) |
| 8 | `pair.burn(attacker)` | needs LP of the pair | **revert** — `UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED` |
| 9 | `pair.transferFrom(factory, attacker, n)` | needs allowance | **revert** — no allowance, balance underflow |
| 10 | `pair.skim(attacker)` | permissionless | **succeeds, transfers 0** (no excess in any pair) |
| 11 | Router allowance `factory → router` (max on WETH + each launch token) | — | **inert**: the router only pulls tokens from `msg.sender`; no third-party pull function exists |
| 12 | `factory.deployToken{value: 0.01 ETH}(...)` | permissionless | **succeeds but is a net loss**: caller pays 0.01 ETH + 2% fee (0.0002 ETH to the owner's fee wallet) and the LP it creates is locked to the factory forever — the deployer can never withdraw it |

**Why the locked WETH is not extractable:** the only way WETH leaves a pair is `swap` — the seller must deliver launch tokens. Tokens exist only in: (a) the pool itself (buy at AMM price — round-trip loses buy+sell fees), (b) the factory's fee balances (owner-only), (c) the penalty receiver (allowlist), (d) the vester (recipient-only), (e) deployer/third-party wallets (private). There is no permissionless function anywhere in the system that pays the caller; there are no unclaimed balances or accounting over-credits in the token (fee credits are exact `amount * fee / BPS`, deducted from the transfer).

---

## 5. PoC / fork verification

- Project: `poc/` (Foundry; forge-std vendored), tests in `poc/test/G8keep.t.sol`; CI state dump in `ci/dump_state.py` + `ci/run.sh`.
- Fork: Base mainnet via CI `BASE_RPC_URL` (empty in CI env → public `https://mainnet.base.org` fallback; see caveats).
- Tests (10): state/roles/locks; withdrawToken/withdrawETH/sellTokens reverts; penaltyReceiver revert; vester revert; pair.burn revert; LP transferFrom revert; skim yields 0; deployToken net-loss + lock.
- CI runs (GitHub Actions, public repo `artsbykriss/ca-zombie-ci`):
  - Run 1 (state dump OK; forge test failed on empty-RPC env — fixed): `https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38692941438`
  - **Run 2 (final, success): `https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38693188476`** — `forge test -vvv`: **10 passed / 0 failed** (all 10 in `G8keep.t.sol`); state dump at block **52,628,356**: 77 pairs, **77/77 locked**, **32.04673289473592 ETH** attributable, **0 pairs with excess**.
  - Run 2 artifact: `ci-artifacts/result-g8keep/ci-out/state.json` (full 77-pair table), log in `ci-log.txt`.

---

## 6. Verdict, categories, residual risk

| Category | USD | Contents |
|---|---|---|
| **E-U** (external unprivileged) | **$0.00** | nothing extractable; every path gated |
| **H-O** (holder-only) | not quantifiable (illiquid launch tokens) | vester vesting claims by deployers; third-party LP of 0.0024 ETH ($5.79) in 2 pairs |
| **P** (privileged) | not quantifiable (illiquid launch tokens) | factory's 138 fee-token balances; penalty-receiver holdings (owner EOA dormant since 2025-02-12) |
| **S** (stuck) | **$77,446.66** (32.046733 ETH) | factory-held LP over 77 pairs — permanently unredeemable by anyone (locked, no unlock, no burn). The underlying WETH is *tradeable* out of the pools at AMM price but cannot be redeemed as liquidity |

**Confidence: high.** Verified: deployed bytecode, roles, storage-level lock flags for all 77 pairs, full pair enumeration (nonce cross-check), zero excess balances, all snipe windows expired, all revert paths simulated on a fork.

**Residual/latent risk:**
1. **Owner key revival/compromise** (EOA `0x28253c1A…`, dormant since 2025-02-12): the owner could `sellTokens` the factory's fee accruals into the locked pools and withdraw any non-locked dust. It cannot touch the 32.05 ETH of LP.
2. **Pool mispricing**: the locked pools are ordinary AMM markets; if a launch token (e.g. HUH) were obtainable below the pool price on another venue, an arbitrageur could sell into the pool. For HUH, GeckoTerminal reports this as the only pool (24h volume 0), so no such source exists today. This is ordinary market risk, not a protocol flaw.
3. **Unclaimed deployer vestings** (vester) — H-O, deployer-only.

**Blockers to a headline:** none — the negative result is proven, not assumed.

---

## 7. Methodology & sources

- Verified source (Basescan, chainid 8453): `g8keepFactory`, `g8keepToken`, `g8keepPenaltyReceiver`, `g8keepFactoryConfiguration`, `g8keepVester`, `UniswapV2Pair` — extracted to `analysis/src/`.
- Live reads: Base RPC (`eth_call`, `eth_getStorageAt`, `eth_getBlockByNumber`), Alchemy `getTokenBalances`/`getAssetTransfers`, GoldRush `token_balances`/`transactions_for_address`/`pool_spot_prices`, DefiLlama prices, GeckoTerminal pools. Full enumeration + lock flags re-verified in CI at block 52,628,356.
- Corpus: `zombie_hunt/FINDINGS.md` (row g8keep), `l2-triage-a/` row + CI artifacts, DefiLlama adapter (`projects/g8keep/index.js`).

**Caveats / limitations:**
- `BASE_RPC_URL` is empty in the CI environment; the dump and tests fall back to public Base RPCs (`mainnet.base.org`), so exact block numbers differ between local and CI runs (both recorded).
- USD conversions use the DefiLlama ETH spot at 2026-10-14 ($2,416.68); the launch tokens themselves have no reliable prices (illiquid) — they are reported as unquantified.
- The factory's 138 fee-token balances were enumerated via an indexer (GoldRush) and cross-checked with the factory nonce; individual token values are not relied on for the headline.
- No mainnet transactions were sent; all attack attempts are fork simulations.

## 8. Files

```
g8keep/
├── README.md                      (this file)
├── summary.json                   (machine-readable)
├── analysis/
│   ├── src/                       (verified deployed sources)
│   ├── factory_state.json         (roles, slots, totals, extraction paths)
│   ├── pairs_live.json            (all 77 pairs: reserves, LP, share, lock, excess)
│   ├── locked_map.json            (lockedTokens[pair] for 77 pairs)
│   ├── factory_balances_goldrush.json (all 216 factory ERC-20 holdings)
│   └── eth_price_snapshot.json
├── poc/                           (Foundry: interfaces + 10 tests)
├── ci/run.sh, ci/dump_state.py    (CI heavy job: full re-enumeration at latest block)
├── ci-out/                        (CI outputs: state.json, dump.log)
└── ci-log.txt, ci-artifacts/      (CI logs/artifacts)
```
