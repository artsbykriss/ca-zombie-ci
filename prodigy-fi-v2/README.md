# Prodigy.Fi V2 (Base) — residual OPEN O4 deep-dive

**Date:** 2026-10-25 · **Chain:** Base (8453) · **Finding:** O4 (pass6-recon OPEN row; pass6 lane `base-bsc-fresh` row 3)
**Status:** read-only; PoC fork-verified only; **no mainnet transaction signed or sent**; no secrets in this folder.

**Target:** `PositionManager 0x50aB3FE7d089c4F0dD8096aAeA9578f8E7B18AF7` → unverified impl
`0xb1522e3514adfa6cbacd6675378fce03e1b97dd8` (EIP-1967 impl slot confirmed). 1714 vaults; pools
`0x864cd493…` (empty) and `0xe1303B2514755A72da4AcA9B917d96F16c842c80` (funded).
All reads at **Base block 53,044,841**.

---

## 1. TL;DR

| Target | Live value (Base, 53,044,841) | External-unprivileged extractable? | Why closed | Latent risk |
|---|---|---|---|---|
| `PositionManager 0x50aB3FE7…` (UUPS factory) | 0 native, 0 tokens | **No** | every non-view selector is `onlyOwner`/already-initialised; owner = single EOA | **P** (owner key) |
| Collateral pool `0xe1303B25…` (impl `0x50c0be44…`, unverified) | **$18,927.43** (4,147.92 USDC + 4.0654 WETH + 0.06555 cbBTC) | **No** | `withdraw(token,amt)` is `mapping[msg.sender]`-keyed; all other outflows require `msg.sender` to be a factory-registered vault or owner | **P** (owner key / UUPS) |
| 1714 vaults (EIP-1167 clones) | 0 each (all collateral is pooled) | **No** | deposits gated by deposit window + (V2) EIP-712 signature; creator/owner gated admin | — |
| Pool v1 `0x864cd493…` | 0 | No | empty | — |

**Headline: external-unprivileged extractable = $0.00 (high confidence).**
The ~$18.9k on Base is real, live and audited-but-closed: the funds are in a single escrow
contract whose only outbound transfer is indexed by the caller's own balance. The residual risk
is **privileged** (a single EOA owner can `upgradeToAndCall`).

---

## 2. Total live extractable now

| Category | USD | Confidence | Basis |
|---|---|---|---|
| **E-U** (external unprivileged) | **$0.00** | high | every value-moving selector reverts from a fresh EOA (fork test 12/12 PASS) |
| **E-U-conditional** | $0.00 | high | no conditional path found (no uninitialised clone, no re-init, no missing caller check) |
| **H-O** (holder/user-only) | ≤ **$18,927.43** | medium | pool funds are withdrawable by their own depositors via `withdraw(token,amt)` |
| **P** (privileged) | **$18,927.43** (Base) | high | `owner` is EOA `0xB17A226B…`; UUPS `upgradeToAndCall` ⇒ key compromise drains |
| **S** (stuck/bricked) | $0.00 | medium | nothing is bricked; withdrawals and settlement paths are live |

Protocol-wide context (DefiLlama 2026-10-24): **$67,961.68** total — Ethereum $44,912.86,
**Base $18,807.42**, Hyperliquid L1 $3,231.73, Berachain $1,009.68. The brief's "$68.9k" is the
whole-protocol number; the Base leg owned by this subagent is ~$18.9k.

---

## 3. The mechanism in exact terms

Prodigy.Fi V2 is a live, **audited** (Halborn 2024-10-30 + a 2025-12-09 collaborative report,
both at `github.com/prodigyfi/audits`) multi-chain options-vault protocol. On Base:

1. **Factory** `PositionManager 0x50aB3FE7…` (verified proxy → **unverified** impl
   `0xb1522e35…`, 14.6 KB) is `UUPSUpgradeable` (`proxiableUUID`, `UPGRADE_INTERFACE_VERSION()
   == "5.0.0"`, `upgradeToAndCall`) + `Ownable` (`owner()`). It deploys vaults
   (`getDeployedVaultCount() == 1714`) as **EIP-1167 clones** and keeps a `vaultImplementation`
   pointer (`setVaultImplementation(address,uint8)`).
2. **Vaults** are options positions over `(investmentToken, linkedToken)` ∈
   {USDC, WETH, cbBTC}². They hold **no tokens themselves** — `collateralPool()` on all 1714
   vaults returns `0xe1303B2514755A72da4AcA9B917d96F16c842c80`. Deposits are gated by
   `block.timestamp <= depositDeadline` and, in the V2 impl, by an off-chain signature
   (`signer()`, `signatureRequired()`, `consumeNonce(address,uint256)`).
3. **Collateral pool** `0xe1303B25…` (verified proxy → **unverified** impl `0x50c0be44…`,
   11.0 KB) is the single escrow. Its token balances are the protocol's Base TVL.

The exact gating, read from the decompiled pool (bodies recovered from the heimdall
disassembly because the decompiler is lossy):

- `withdraw(address token, uint256 amount)` `0xf3fef3a3` — dispatches to `keccak256(msg.sender,
  slot3)` (a per-caller balance map), requires `balance >= amount`, decrements it and transfers
  `amount` of `token` to `msg.sender`. A stranger's entry is 0 ⇒ reverts
  `CollateralPoolV2: insufficient withdrawable balance`.
- `processUserDeposit(address,uint256)` `0x1ea734b6`, `d5735e7d(address)`, `0xa4bc9c2d(bool)` —
  all first read `registeredVaults[msg.sender]` ⇒ revert `CollateralPoolV2: not registered vault`.
- `registerVault(address,address)` `0x05c4fdf9` — `require(msg.sender == factory)`.
- `approveVault(address,bool)` `0x3e99414e` — `require(msg.sender == vault.owner())`.
- `setFactory` / `setWhitelistedToken` / `setWhitelistedLP` / `transferOwnership` /
  `upgradeToAndCall` / `initialize` — `onlyOwner` / initializer.
- `0x1749aa26(address,uint256)` — reads `mapping[msg.sender]` and **early-returns (`STOP`) when
  it is zero**; moves nothing for a stranger.
- `0x715018a6` (the OZ `renounceOwnership` selector) — its body is a bare `STOP` (disabled stub);
  no state change, owner unchanged.

---

## 4. Live-state assessment (Base 53,044,841)

| Item | Value | How read |
|---|---|---|
| PM EIP-1967 impl slot `0x360894a1…` | `0xb1522e3514adfa6cbacd6675378fce03e1b97dd8` | `eth_getStorageAt` |
| PM EIP-1967 admin slot `0xb5312768…` | `0x0` (no transparent admin) | `eth_getStorageAt` |
| PM `owner()` | `0xB17A226B38A576738C1ad5E6ACC273a1A3A99A9F` | `eth_call` |
| Owner kind | **EOA** (`eth_getCode` = `0x`, nonce 234) | `eth_getCode`/`eth_getTransactionCount` |
| PM `paused()` | `false` | `eth_call` |
| PM `getDeployedVaultCount()` | `1714` | `eth_call` |
| PM `collateralPool()` / `vaultImplementation()` / `weth()` | `0xe1303B25…` / `0xBeD271eA…` / `0x4200…0006` | `eth_call` |
| Vaults with `collateralPool()==0` | 0 / 1714 | `getDeployedVaults` + 1714 `eth_call` |
| Vaults `isInitialized()==true` | 1714 / 1714 | `eth_call` |
| Vaults holding USDC/WETH/cbBTC/native | **0** | `balanceOf` × 11 tokens + `eth_getBalance` × 1714 |
| Vaults with `depositTotal()>0` | 16 | `eth_call` |
| Pool `0xe1303B25` balances | `4147915743` USDC (6dp) · `4065428875384615385` WETH · `6555499` cbBTC (8dp) | `balanceOf` |
| Pool `0xe1303B25` USD | **$18,927.43** | DefiLlama prices |
| Pool v1 `0x864cd493` USDC | `0` | `balanceOf` |
| PM native balance | `0` | `eth_getBalance` |

Prices (DefiLlama `coins.llama.fi`, 2026-10-24): WETH $2,340.38 · USDC $0.99953 · cbBTC $80,342.43.

---

## 5. What an attacker can / cannot do

**Can (nothing extractive):**
- Call the two inert selectors `0x715018a6` (pool, PM) and `0x1749aa26(token,amt)` (pool) — they
  succeed but move no tokens and change no state (proved by disassembly + fork balance checks).
- Deposit **their own** tokens into the pool (needs their own allowance) and later withdraw
  **their own** balance — i.e. H-O self-service, not extraction.

**Cannot:**
- Withdraw pool tokens: `withdraw(token,amt)` is keyed by `msg.sender` ⇒ reverts for any address
  with no deposit.
- Impersonate a vault: `processUserDeposit`/`d5735e7d`/`a4bc9c2d` require
  `registeredVaults[msg.sender]`.
- Register/approve a malicious vault: `registerVault` is factory-only; `approveVault` is
  vault-owner-only.
- Re-initialise the PM or the pool (`initialize` reverts), re-run `initializeUpgrade()`, `pause`,
  `unpause`, `setCollateralPool(V2)`, `setVaultImplementation`, `changeFeeReceiver`,
  `setMinDepositAmount`, `changeDepositDeadlineOffset`, `setWETH`, `transferOwnership`,
  `upgradeToAndCall` — all `onlyOwner`.
- Exploit a vault: `deposit(...)` reverts (`Vault: deposit period has ended` on v1 /
  `VaultV2: Signature required for deposit` on v2); creator/owner admin reverts.

**Cost:** n/a — no path exists, so there is nothing to fund (no flash loan, no gas-relevant
profit). Attacker net = $0.00.

---

## 6. PoC / fork verification

Foundry project `poc/` (`foundry.toml`, `test/ProdigyPoC.t.sol`), forks Base at pinned block
**53,044,841** (`vm.createSelectFork`), fresh attacker `vm.addr(0xA11CE)`, **no impersonation**,
no `vm.deal`, no `vm.store`.

12 tests, **12/12 PASS** (see CI log). What they prove:

| # | Test | Proves |
|---|---|---|
| 1 | `test_pool_holds_the_funds` | $18.9k sits in `0xe1303B25`; PM & pool v1 hold 0 |
| 2 | `test_vaults_hold_no_tokens_directly` | vaults hold 0 tokens/native |
| 3 | `test_pool_withdraw_reverts_for_stranger` | `withdraw` ⇒ `insufficient withdrawable balance` (USDC & WETH) |
| 4 | `test_pool_vault_only_functions_revert` | `processUserDeposit`/`d5735e7d`/`registerVault`/`approveVault` all revert with the exact reason |
| 5 | `test_pool_owner_only_reverts` | 6 owner/init paths revert |
| 6 | `test_renounce_selector_is_noop` | `0x715018a6` succeeds, no balance/owner change |
| 7 | `test_vault_value_paths_revert_for_stranger` | vault deposit window/signature + creator/owner gating |
| 8 | `test_position_manager_admin_reverts` | 22 PM admin/deploy selectors revert |
| 9 | `test_upgrade_control` | impl slot = `0xb1522e35…`; admin slot = 0; owner is an EOA |
| 10 | `test_attacker_net_profit_is_zero` | after all candidate calls, pool balances unchanged and attacker holds 0 |

**CI (GitHub Actions `artsbykriss/ca-zombie-ci`, branch `prodigy-fi-v2`, workflow `poc.yml`):**
run URLs recorded in `summary.json` → `poc.ci_run_urls` and in `ci-log.txt`. The custom job
`ci/run.sh` also writes `ci-out/live_state.json` (pinned-block snapshot with the three stranger
revert reasons).

**Local (light) work:** bytecode fetch, `heimdall`/`evmole` decompilation, selector lookups,
`eth_call` auth probes, 1714-vault enumeration, DefiLlama price reads. **CI:** `forge test` fork
suite + `ci/run.sh` fork state dump.

---

## 7. Verdict and residual / latent risk

**Verdict: $0 external-unprivileged. The pass6 "MED opaque core" lead is CLOSED (negative).**
The unverified implementation is genuinely unread from source, but its *behaviour* is fully
constrained by on-chain probes: the only contract holding value (`0xe1303B25`) has exactly one
outbound transfer and it is caller-keyed; every other entry point is vault- or owner-gated.

**Residual / latent risk (not E-U):**
1. **P — single-EOA owner.** `0xB17A226B38A576738C1ad5E6ACC273a1A3A99A9F` is an EOA that owns the
   factory **and** both pools and can `upgradeToAndCall`. Key compromise ⇒ drain of the whole
   protocol ($67.9k). This is governance/key risk, not an unprivileged path. Monitor
   `Upgraded(address)` on the PM/pool proxies.
2. **Unverified bytecode.** The impls are unverified on BaseScan/Etherscan-V2/Sourcify. This
   analysis is decompiler- and disassembly-based; a *logic* bug reachable only through the
   registered-vault flow (e.g. a vault-owner self-dealing in settlement) would not be visible to
   a stranger but is not an E-U path either.
3. **Cross-chain twin.** The identical factory address runs on Ethereum (2268 vaults, same owner,
   pool `0xe1303B25` holds ≈ 11,208 USDC + 1.082 WETH ≈ $13.7k) — same conclusion expected; not
   exhaustively enumerated here (out of the Base scope).

**Blockers:** none for the verdict. The pool is not paused; withdrawals are live.

---

## 8. Methodology & sources; caveats; files

**Method.** (1) resolve the proxy→impl (EIP-1967 slot) and enumerate *every* selector of the
factory, both pools and the three vault implementations with `evmole` + `openchain.xyz`;
(2) decompile (`heimdall --include-sol`) and, where the decompiler is lossy, disassemble
(`heimdall disassemble`) to recover the exact control flow of the value-moving selectors;
(3) enumerate all 1714 vaults from `getDeployedVaults` and read pool/token/state for each;
(4) probe every value-moving selector with `eth_call` from a fresh EOA `0x…dEaD`;
(5) reproduce the whole thing as a Foundry fork suite and run it in CI.

**Sources.** Base public RPC (`base-rpc.publicnode.com`) for all reads; DefiLlama
(`api.llama.fi/protocols`, `coins.llama.fi/prices/current`, adapter
`projects/prodigy-fi-v2/index.js`); `github.com/prodigyfi/audits` (Halborn 2024-10-30 +
2025-12-09 collaborative report — both image-only PDFs, no extractable text);
`openchain.xyz` selector DB; Etherscan V2 `getsourcecode` (chainid 8453 — returns no source on
the free tier, but flags `Proxy=1` and gives the impl address for `0x864cd493…`).

**Caveats / limitations.**
1. The impl bytecode is unverified; a bug reachable only via the registered-vault settlement
   flow (which requires a vault owner, i.e. H-O/P) cannot be fully excluded. No stranger-reachable
   bug was found or is reachable from the observed gates.
2. BaseScan/Etherscan-V2 free tier would not return verified source; `evmole`/`heimdall`
   signatures for ~20 selectors remain unresolved (they are all view/`onlyOwner` per the
   fresh-EOA probe).
3. Point-in-time **2026-10-25**, block 53,044,841. Re-read state before acting. Nothing here is an
   instruction to transact.
4. USD is price-sensitive (WETH/cbBTC); the *token amounts* are exact and block-pinned.

**Files index.**
- `README.md` (this file) · `summary.json` (machine-readable) · `ci-log.txt` (CI log)
- `analysis/` — `NOTES.md`, `probe_auth.py`, `probe_results.json`, `enumerate_vaults.py`,
  `vaults.json`, `usd.json`, `live_state.json`, raw `.hex`, `*_selectors.json`,
  `*openchain*.json`, `*.heimdall-decompiled.sol`, `*.asm-disassembled.asm`
- `poc/` — `foundry.toml`, `test/ProdigyPoC.t.sol`, `lib/forge-std`
- `ci/run.sh` — pinned-block fork state dump → `ci-out/live_state.json`
- `ci-out/live_state.json` · `ci-artifacts/`
