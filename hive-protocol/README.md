# Hive Protocol — BSquared (chain 223) — ZH4-PASS7 deep-dive

**Date:** 2026-10-25 · **Chains:** BSquared (223 / 0xdf) · **Status:** read-only; PoC fork-verified only; **no mainnet transaction signed or sent**.
**Target:** DefiLlama `hive-protocol` ("Stake BTC, safeguard B², get $B2"), TVL ≈$234M staked BTC, 0 audits, +2,304 %/7 d. Prior pass (PASS7 `fresh-deep.md` §3.11 / row 3) recorded it as **UNRESOLVED — contracts not located, tooling-blocked**.
**This report resolves it.** All Hive contracts are located, decompiled, and fork-verified.

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why closed / open | Latent risk |
|---|---|---|---|
| Hive staking `0xd5B5…46e` — 2,918.95 BTC ($234.98M) | **$0** | Payouts are per-user, stake-bounded, and gated on a matured `unstake`; every admin/config/value function is role-gated. 34 unprivileged probes moved **0 wei**. | Single-EOA `UPGRADE_ROLE` (P) |
| Hive vault `0xe677…a8F3` — 418.29 BTC ($33.67M) | **$0** | `deposit`/`withdraw` require `msg.sender == strategies[pid]` (= staking contract only) — fork-proven revert `no permission`. | Single-EOA `UPGRADE_ROLE` (P) |
| B2-staking `0x796e…cAc2` — 139.47 BTC ($11.23M) | **$0** | `withdraw()` needs a user request + lockup; `requestWithdrawals` needs caller balance; admin fns `onlyOwner`. | `owner()` EOA + UUPS (P) |
| B2 token `0x783c…e2a2` (120,035 B2 = $50.4k in staking) | **$0** | Standard ERC-20; no public mint. | P |

## 2. Total live extractable now: **$0.00** (confidence: **high**)

No external-unprivileged path moves native BTC or B2 out of any Hive contract. Verified on a
local fork by 17 tests (17/17 PASS) plus 34 targeted unprivileged probes; all admin/value
functions revert for a stranger, and the only value-moving user paths pay the caller their **own**
credited, request-bounded amount.

**Custodied value (holder-recoverable, H-O): 3,476.71 BTC ≈ $279,875,306** across the three
contracts. This is *not* extractable by an attacker — it is the stakers' own pool.

## 3. The mechanism, in exact terms

Hive is a **MasterChef-style BTC staking system** behind UUPS proxies, deployed at BSquared block
**747,123**, with a vault/strategy split:

- **Staking `0xd5B5…46e`** (impl `0x41b3C11d…946f7`, 23,572 B) — `depositBTC()` (payable), `unstake(pid,amount)`,
  `withdraw(pid)`, `claim(pid)`, `stakingBalance`, `withdrawRequest/Amount`, AccessControl
  (`ADMIN_ROLE`/`UPGRADE_ROLE`), Pausable, UUPS. Native pool `BTC_PID = 0`; 5 pools; `b2PerBlock = 0.3375`.
- **Vault `0xe677…a8F3`** (impl `0x59b1cDe6…6C036`) — `deposit(pid,amt,user)` / `withdraw(pid,amt,user)` /
  `transferToStaking(amt)`, each `require(msg.sender == strategies[pid], "no permission")`. `strategies(0..4)`
  **all** point at the staking contract.
- **Strategy manager `0xcf38…700B`** (impl `0x7b40…d3fd`) — `getStrategy/getStrategyCount/stakingBalance/withdraw`
  behind a caller whitelist (`withdraw` reverts `no permission to call` for an EOA).
- **B2-staking `0x796e…cAc2`** (impl `0x0619E227…aBdb`) — ERC-20 + `submit()`/`withdraw()`/`requestWithdrawals`/`poolClaim`
  wrapper, Ownable + UUPS.

**Exact call path of a legitimate exit (fork-proven):**
`depositBTC{value:x}()` → staking forwards `x` to `vault.deposit(0,x,user)` →
`unstake(0,x)` (reverts `Not enough staking token balance` if `x >` credited stake) →
wait for lockup → `withdraw(0)` → staking calls `strategyManager.withdraw(0,user)` (whitelisted) for the
credited amount, then `vault.withdraw(0,amount,user)`, then pays the caller from the **staking
contract's own balance**. No caller-supplied amount reaches the payout: `withdraw` takes only `pid`
and the amount comes from the caller's own accounting.

**Why E-U is $0.** There is no permissionless function whose payout depends on a caller-supplied
amount, no shared-balance withdrawal, no unguarded mint, and no reachable admin path. `withdraw(0)`
by a stranger *succeeds* (a soft no-op paying 0) — this is the only superficially odd behaviour and
it moves nothing.

## 4. Live-state assessment (block 39,897,334, keyless `https://rpc.bsquared.network`)

| Address | Kind | Code | Native BTC | USD |
|---|---|---|---|---|
| `0xd5B5f1CA0fa5636ac54b0a0007BA374A1513346e` | staking proxy → impl `0x41b3C11d…946f7` | 170 B | 2,918.949047718480553371 | $234,975,340.22 |
| `0xe677F4B6104726D76DeBc681d7a862CE269aA8F3` | vault proxy → impl `0x59b1cDe6…6C036` | 170 B | 418.289511807089039265 | $33,672,297.37 |
| `0x796e4D53067FF374B89b2Ac101ce0c1f72ccaAc2` | B2-staking → impl `0x0619E227…aBdb` | 224 B | 139.474180565218215250 | $11,227,668.76 |
| `0xcf38C660e0E99BED4c4aC8817922A0a3A996700B` | strat mgr → impl `0x7b40…d3fd` | 169 B | 0 | — |
| `0x783c3f003f172c6Ac5AC700218a357d2D66Ee2a2` | B2 token | 10,457 B | 0 (120,035.29 B2 = $50,410) | — |
| `0xA3eb53ddA8181Ae48FDfE16Ed3d7F37859F7f97b` / `0x8208bd314b6d730845E0F1427bC5a150EdE9baE7` | aux proxies | 224 B | 0 | — |

Getters: `paused=false`, `withdrawPaused=false`, `claimPaused=false`, `poolLength=5`, `vault()=0xe677…a8F3`,
`vault.strategies(0..4)=0xd5B5…46e`, `strategyManager.getStrategyCount()=5`.
Prices: BTC $80,499.98, B2 $0.41996 (DefiLlama, 2026-10-25). **ERC-1967 slots** (staking/vault/stratmgr/B2-staking)
all resolve to the impls above; admin slots are 0 (Solady proxies — no separate admin).

**Roles:** `ADMIN_ROLE`/`UPGRADE_ROLE` on the staking contract are held by **EOA
`0x8Da30b68b1E11761e1307EB10564a39E01ae4480`**; on the vault by **EOA
`0x8f3c6735152074e4ce2b31bba8b48f128998d76d`**; `0x796e` `owner()` is `0x8Da30b…4480`.
Initial grants (staking block 747,123) went to `0x8f3c67…d76d`; no role events in 39.0M–39.895M.

**Upgrades:** vault impl changed at block **39,700,059** (tx `0x46e6115d…`), staking impl
`0x6a7C2f12…D1D06` → `0x41b3C11d…946f7` at block **39,700,812** (tx `0xe6f12697…`). Around this
migration ~2,800 BTC moved vault→staking via the role-gated `transferToStaking`; total BTC is conserved.

## 5. What an attacker can / cannot do

- **Cannot** call `vault.withdraw`/`vault.deposit`/`vault.transferToStaking` (revert `no permission`).
- **Cannot** call `strategyManager.withdraw` (revert `no permission to call`).
- **Cannot** `unstake`/`withdraw` more than their own credited stake (`Not enough staking token balance`).
- **Cannot** touch `setVault`/`setB2`/`setB2PerBlock`/`setStartBlock`/`setEndBlock`/`pause*`/`grantRole`/
  `upgradeToAndCall` (all revert for a stranger).
- **Can** deposit BTC, accrue B2, and — after `unstake` + lockup — withdraw exactly their own stake.
- Preconditions/costs: none that yield profit; there is no capital, flash-loan, oracle or
  governance lever. Net = **$0**.

## 6. PoC / fork-verification

`poc/` — Foundry, forks BSquared via `vm.createSelectFork(vm.envOr("BSQUARED_RPC_URL", "https://rpc.bsquared.network"))`.

| Suite | Tests | Result |
|---|---|---|
| `test/HiveFork.t.sol` | 10 | PASS (state, roles, non-staker withdraw, deposit→withdraw payout source, unstake, cross-user, 34-fn probe, vault gating, claim, user struct) |
| `test/HiveWarp.t.sol` | 4 | PASS (warp-withdraw, unstake+warp+withdraw pays from staking, over-unstake reverts, `fe92e060` no-op) |
| `test/HiveB2.t.sol` | 3 | PASS (B2-staking state, permissionless probe, deposit/withdraw bounded) |
| **Total** | **17/17** | **PASS** |

**CI:** GitHub Actions `artsbykriss/ca-zombie-ci` —
- final green run: https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40231111043
- earlier runs (harness fixes): 40224572713, 40226092855, 40227881330, 40228437741, 40230039572, 40230781479
Heavy work (Foundry compile + fork simulations + 39M–39.9M `eth_getLogs` enumeration of 155 staking
events and 4 vault events) ran **in CI**; local work was limited to `cast call`/`eth_getBalance`/
`eth_getStorageAt`, heimdall decompiles, and web fetches.

## 7. Verdict and residual / latent risk

- **E-U = $0 (high confidence).** The finding is **code-clear, not tooling-blocked**: the contracts
  were located (via the DefiLlama `sumTokens` owner address + the 170-byte EIP-1967 proxy slot +
  heimdall decompilation) and every value path was read and fork-tested.
- **P (privileged):** the `UPGRADE_ROLE`/`ADMIN_ROLE` (and `0x796e` `owner()`) are **single EOAs** on a
  protocol with 0 audits and ~$280M custodied. A compromised key can `upgradeToAndCall` a drainer.
  This is the material risk — but it is privileged, not external-unprivileged. Recommend a
  multisig/timelock.
- **H-O:** 3,476.71 BTC is holder-recoverable through `unstake` → lockup → `withdraw`.
- **S:** none observed (funds are withdrawable; no bricked path found).
- **Blockers:** none for the E-U verdict. The BSquared explorer exposes no verified-source API
  (`/api/v2/…` 404; Sourcify 404; Etherscan-V2 unsupported chainid), so all contract logic was
  recovered by decompilation — a decompiler could in principle misread an obscure branch, which is
  why every claim is backed by a **fork test**, not just a decompile.

## 8. Methodology & sources

- **Discovery:** DefiLlama `hive-protocol` → `registries/sumTokens.js` owner `0xd5B5…46e`; `eth_getCode`
  → 170-byte Solady ERC-1967 proxy; `eth_getStorageAt(0x3608…2bbc)` → impl `0x41b3…946f7`.
- **Reads:** `cast call`/`eth_getStorageAt`/`eth_getBalance`/`eth_getLogs` on keyless
  `https://rpc.bsquared.network` (1000-block log cap handled by windowing).
- **Decompile:** `heimdall-rs v0.9.2` for impls `0x41b3…`, `0x59b1…`, `0x7b40…`, `0x0619e227…`
  (sources in `analysis/`). Selector resolution via openchain/4byte.
- **PoC:** Foundry 1.8.5 on GitHub Actions runners; fork at BSquared head.

## 9. Caveats & limitations

- Point-in-time **2026-10-25**; re-read all state before acting.
- The exact set of **all** `ADMIN_ROLE` holders was not enumerated (mapping not enumerable; the
  deployment-block `RoleGranted` window was scanned and the two upgrade senders identified). Additional
  holders may exist.
- The total user accounting was not summed, so "the whole 3,476.71 BTC is holder-attributable" is an
  assumption; any protocol-owned excess would be P/S rather than H-O. The E-U = $0 result does not
  depend on this.
- Web/X/docs content was treated as untrusted data; no transaction was signed or sent.

### Files index
- `README.md` (this file) · `summary.json`
- `analysis/` — `state.md`, `heimdall_impl_full.txt`, `abi_impl.json`, `heimdall_vault_impl.txt`,
  `heimdall_stratmgr.txt`, `heimdall_0x796e_impl.txt`, `impl_0x41b3_code.txt`, `unresolved_selectors.txt`
- `poc/` — `foundry.toml`, `lib/forge-std`, `test/HiveFork.t.sol`, `test/HiveWarp.t.sol`, `test/HiveB2.t.sol`
- `ci/run.sh` · `ci-out/` · `ci-log.txt` · `ci-artifacts/`
