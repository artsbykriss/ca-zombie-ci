# InsureDAO Phase-2 — Deployed-vs-Audited Source Diff & Exploitability Report (v2, corrected)

**Date:** 2026-10-13
**Scope:** Ethereum mainnet V1 deployments vs the Code4rena-audited Jan-2022 code and the latest InsureDAO repos.
**Rules followed:** read-only chain access; all artifacts written under `/home/heisenberg/CA/insuredao/analysis/source-diff/`; no keys/RPC secrets persisted; no transactions.

> **v2 correction note:** an earlier draft listed `CDSTemplate.compensate()` and `PoolTemplate.registerIndex()` as fresh-attacker E-U paths. A reachability re-analysis (documented in §3.3) showed that a fresh attacker cannot originate the calls those functions require — a Factory clone of an approved template has no generic/arbitrary external call, and the only code path that invokes `registerIndex`/`compensate` is owner-gated. Both are **rejected as E-U**; they remain privileged-role risks only. All other conclusions are unchanged.

---

## 1. Sources fetched

| What | Repo | Commit | Date | Notes |
|---|---|---|---|---|
| C4-audited code | `https://github.com/code-423n4/2022-01-insure` | `0c4c26cd1e4957202eb8a97d37e988f46b2f6ddc` | Jan 2022 snapshot | solc 0.8.7. `repos/c4-2022-01-insure/` |
| Current pool-contracts (deployed version) | `https://github.com/InsureDAO/pool-contracts` | `33276267085214cae30470da8e90c4117c833ac8` ("Merge PR #192 misc-develop", 2022-02-22) | blob-identical to all on-chain verified sources | `repos/pool-contracts/` |
| pool-contracts `audit/code4rena` | same | `5a9a1b4a5a7d14e8573ca9a1162943f1760c9a28` (2022-02-07) | fixes merged during C4 | `versions/audit-code4rena/` |
| pool-contracts `audit/peckshield` | same | `db9a2cde...` (2022-01-04) | pre-fix | `versions/audit-peckshield/` |
| pool-contracts latest `main` | same | `2966a5057b32f8f8d18edd8c22c5ac731d1412c4` (2022-09-26) | V2, solc 0.8.12 | `versions/latest-main/` |
| pool-contracts latest `develop` | same | `5d522db8acc96cadca0101b932b7ba6cfc9cefe3` (2022-11-21) | V2 | `versions/latest-develop/` |
| dao-contracts | `https://github.com/InsureDAO/dao-contracts` | deployed-era `538bd3a` (2022-02-26); latest `cd1d78aa...`; audit branches `audit/watchpug` `0dbabfb`, `audit-peckshield` `d74259a` | | `repos/dao-contracts/`, `versions/dao-*/` |
| Deployed verified sources | Etherscan fetch (parent) | `analysis/sources/` | | `versions/deployed/` |

Deployed addresses: PoolTemplate impl `0x1dcd35cfff8a9b44aecc4087c7847fb7a5be56f9`; IndexTemplate impl `0x2b16be3cacaea56a6fbe613031c0f6b641df828e`; CDSTemplate impl `0x99f790ada7fa1bdc2a6b976293273ee51f10a10e`; Vault (USDC) `0x131fb74C6fEdE6D6710FF224E07cE0eD8123f144`; Factory `0x01e6916CcFe3630364b4538d0f8C1c22E20d0F6b`; Registry `0xA035Dfd0D16F238493b374a1743B77448D9C8524`; Parameters `0xdDAA6ee776B701a7729D72BBd0d4FBe4bBb66476`; PoolProxy (owner) `0xF4d046D8FaC6dc37b5eAFAdd34407b19De3Ba350`; CDS instance `0x86c82E8cD8A865f01A8CeBed870Af5d58e69a439`.

**Provenance:** each deployed verified source is a byte-identical git blob in `pool-contracts@3327626`, and the deployed PoolTemplate runtime recompiles from that source with solc 0.8.10 (optimizer 200) to 20,570/20,613 identical bytes (difference = IPFS metadata hash only). Details §5.

Raw diffs: `diffs/diff-c4-to-deployed-*.diff`, `diffs/diff-repo3327626-to-deployed-*.diff` (all empty), `diffs/diff-auditbranch-to-deployed-*.diff`, `diffs/diff-latestmain-to-deployed-*.diff`, `diffs/diff-dao-*-to-deployed-PoolProxy.diff`.

---

## 2. Diff summary — audited (Jan 2022) → deployed (Feb/Mar 2022)

The deployed code contains the fixes for all 14 C4 Highs and the fixed mediums. No security check was removed; the diff adds checks, refactors math/gas, and introduces four new surfaces (`registerIndex`, `applyBounty`, `insure(_for,_agent)`, `redeem(_,_loss)`).

### 2.1 Fixes visible in the diff
| C4 issue | Deployed fix (file:lines) |
|---|---|
| H-01 burn via `utilize()` with zero keeper/controller | `Vault.utilize` requires `controller != 0`, uses `controller.utilizeAmount()` capped by `available()` (Vault.sol:381-403) |
| H-02 `unlock()` repeat | `_unlock` sets `insurances[_id].status = false` (PoolTemplate.sol:359-377) |
| H-03/H-04 initial-deposit theft | `Factory.createMarket` → `market.initialize(msg.sender, ...)` (Factory.sol:219); `_references[4]` removed; depositor = caller (PoolTemplate.sol:174-212) |
| H-05 `withdrawRedundant` backdoor | rewritten (Vault.sol:523-549) |
| H-08 index compensate precision loss | new shortage flow; `_compensated` re-read from the vault (IndexTemplate.sol:436-467) |
| H-09 controller migration drain | `setController` requires new controller `valueAll()` not decreased (Vault.sol:556-567) |
| H-11 wrong liquidation math | `_liquidation` corrected (PoolTemplate.sol:783-822) |
| H-12 index LP resumes locked pool | `IndexTemplate.resume` requires `locked` and pools `Trading` (IndexTemplate.sol:471-485) |
| H-13 withdrawCredit after cover | `PoolTemplate.withdrawCredit` requires `Trading` (PoolTemplate.sol:456-464) |
| H-10 admin drain via Registry/Factory | acknowledged by sponsor; `onlyMarket` design retained (privileged) |
| M-01 repayDebt DOS | clamped (Vault.sol:275-288) |
| M-03 incident replay | `applyCover` requires `incidentTimestamp < now`; merkle leaf binds `(target, insured, loss)` (PoolTemplate.sol:690-699, 606-653) |
| M-02/M-06/M-07/M-08 | timestamp check, new credit engine (`_adjustAlloc`, `withdrawable`, `_totalFixedCredits`), per-market params |

### 2.2 Behavioral changes
- Per-market parameters: `getLockup/getWithdrawable/getGrace/getMinDate/getFeeRate(address(this))`.
- `redeem(_id,_loss,proof)`: loss bound in the leaf; payout `min(loss*ratio, insured amount)` always to `insured`; `agent` may redeem; `transferInsurance` removed.
- `insure(...,_for,_agent)`: payer is `msg.sender`; rights belong to `_for`.
- `applyBounty`: new `onlyOwner` (reporting-admin via PoolProxy).
- `registerIndex`: new; effect in practice owner-gated (§3.3).
- `PoolProxy`: `pool_apply_bounty`, `defund(_to,_amount)`; all still admin-gated; `withdraw_admin_fee`/`distribute` are permissionless triggers routing pooled fees to configured distributors.
- `InsureDAOERC20`: no external mint/burn; `initializeToken` internal; `transferFrom` max-allowance skip; `_beforeTokenTransfer` trims pending withdrawal requests.
- `Vault`: `_divRoundUp` (attribution burn rounds up; favors the vault), `_unutilize` solvency check.

### 2.3 Deployed vs latest repo (V2)
Latest `main`/`develop` are the V2 branch (solc 0.8.12, `implementations/*`, Controller, `openDeposit`, new premium model). Not deployed on Ethereum V1 (V2 lives on Arbitrum/Optimism/Goerli per parent's `multichain.json`). Raw diffs saved; no V1 conclusion depends on them.

---

## 3. Exploitability of the changed code

### 3.1 The structural constraint that decides every candidate
A fresh attacker's only way to obtain a *listed* contract is `Factory.createMarket` on an **approved + open** template. Complete on-chain template set (enumerated from Factory `TemplateApproval` logs; 3 events ever):

| Template | approval | isOpen | References approved | Conditions |
|---|---|---|---|---|
| PoolTemplate `0x1dcd...` | true | **true** | slot0 = wildcard, slot1 = USDC, slot2 = Registry, slot3 = Parameters | slot0 = `1e9` (min 1,000 USDC initial deposit) |
| IndexTemplate `0x2b16...` | true | false | slot0 = USDC, slot1 = Registry, slot2 = Parameters | — |
| CDSTemplate `0x99f7...` | true | false | slot0 = USDC, slot1 = Registry, slot2 = Parameters | — |

So a fresh attacker can only create **PoolTemplate clones**. A PoolTemplate clone:
- has no `delegatecall`, no generic "call arbitrary target/data" function, no fallback;
- makes outbound calls only with fixed selectors to (a) addresses read from its own storage (`registry`, `parameters`, `vault` — set once in `initialize()` under Factory approval constraints) and (b) `indexList` entries.

`indexList` can only be grown/replaced by `registerIndex()`, which requires `msg.sender` itself to be a listed market. **The only code path in the whole protocol that calls `IPoolTemplate(_pool).registerIndex(...)` is `IndexTemplate.set()` (IndexTemplate.sol:620,636), which is `onlyOwner`** (owner = PoolProxy → parameter admin). EOAs fail the `isListed` check; a clone cannot make itself call `registerIndex` (its code never does), and a raw (non-Factory) clone fails every `vault.onlyMarket` check because the vault looks up the real Registry.

Consequently the entire credit/compensation graph — `registerIndex → allocateCredit/withdrawCredit`, `IndexTemplate.compensate → CDSTemplate.compensate`, `PoolTemplate._liquidation → IndexTemplate.compensate` — is reachable only via owner-controlled state. The `isListed` checks alone would be insufficient, but the reachability argument above closes the path for unprivileged actors.

### 3.2 Changed-function verdicts (PoolTemplate / IndexTemplate / CDSTemplate / Vault)
| Function | Change | New E-U? | Why |
|---|---|---|---|
| PoolTemplate.initialize | `_depositor` = Factory caller; refs[4] removed | No | Fixes H-03/H-04; clone created+initialized atomically by Factory |
| PoolTemplate.deposit/_depositFrom | refactor | No | `_from` is always msg.sender (or Factory caller); same math |
| PoolTemplate.requestWithdraw/withdraw | per-market lockup, reorder | No | Same burn/price math; `_retVal <= available` retained |
| PoolTemplate.unlock/_unlock | status=false (H-02) | No | Fix; griefing note: anyone may unlock expired policies, blocking later redemption of past-period incidents (no profit; exists in both versions) |
| PoolTemplate.registerIndex | new | **No (owner-gated in practice)** | Only caller is `IndexTemplate.set()` (onlyOwner). Direct EOA calls revert on `isListed`. |
| PoolTemplate.allocateCredit | requires `indices[msg.sender].exist` | No | exist is set only by registerIndex; strictly more restrictive than audited `isListed` |
| PoolTemplate.withdrawCredit | +`marketStatus==Trading` (H-13) | No | Fix |
| PoolTemplate.insure | `_for`,`_agent`, per-market fee | No | Attacker pays premium; payout/rights to `_for`; `agent` cannot redirect payout |
| PoolTemplate.redeem | `_loss` bound in merkle leaf | No | Leaf binds loss; payout to `insured`; requires owner-applied incident |
| PoolTemplate.applyCover | timestamp check; paused check removed | No | `onlyOwner` = reporting admin via PoolProxy (currently `default_reporting_admin == 0x0`) |
| PoolTemplate.applyBounty | new | No (privileged) | `onlyOwner`; malicious reporter could pay bounties by design |
| PoolTemplate.resume/_liquidation | H-11 fix | No | Caller receives nothing; amounts derived from debt/credit |
| IndexTemplate.deposit/withdraw/withdrawable/_adjustAlloc | rewrite | No | Caller gets only own pro-rata share; new algorithm reserves max locked credits |
| IndexTemplate.compensate | H-08 fix | No | `allocPoints[msg.sender] != 0` — only owner-assigned pools |
| IndexTemplate.resume | H-12 fix | No | Locks/windows; no funds to caller |
| IndexTemplate.set/setLeverage | onlyOwner; `_indexB` registration | No | Privileged |
| CDSTemplate.initialize/deposit/fund | refactor | No | `fund` is a donation |
| CDSTemplate.defund | now `(_to,_amount)` | No | `onlyOwner` |
| CDSTemplate.requestWithdraw/withdraw | per-market lockup; supply guard | No | Self-service only |
| CDSTemplate.compensate | refactor; same `isListed` gate | No (see §3.3) | Only reachable from `IndexTemplate.compensate` (owner-assigned pools). Never called on-chain (no `Compensated` logs; `registry.getCDS` mapping is empty) |
| Vault.withdrawValue/transferValue/offsetDebt | round-up burn (`_divRoundUp`) | No | Rounding favors the vault; edge case: tiny withdrawals can revert when price/attribution > 1 (DoS, no gain) |
| Vault.borrowValue | zero guard | No | `onlyMarket`; callable only from market code paths (redeem/applyBounty) |
| Vault.repayDebt | M-01 fix | No | Public, pays on behalf |
| Vault.withdrawAttribution/withdrawAllAttribution/transferAttribution | checks/refactor | No | Own attributions only |
| Vault.utilize | H-01/H-09 fix | No | Live vault `controller() == 0x0` → reverts |
| Vault.withdrawRedundant | H-05 fix | No | `onlyOwner` |
| Vault.setController | H-09 fix | No | `onlyOwner` |
| Factory.createMarket | initialize(msg.sender,...) | No | Fix |
| Registry / InsureDAOERC20 | cosmetic / gas | No | No public mint/burn; `initializeToken` internal |

### 3.3 Rejected E-U candidates (documented to prevent dead ends)
1. **"Any listed market can drain the CDS via `compensate()`" — REJECTED.**
   `CDSTemplate.compensate` (impl_cds/CDSTemplate.sol:243-265) is guarded only by `registry.isListed(msg.sender)`, and it does `vault.transferValue(_compensated, msg.sender)`. However, the only code that calls `CDS.compensate` is `IndexTemplate.compensate` (IndexTemplate.sol:452), and that function requires `allocPoints[msg.sender] != 0` — set exclusively by `IndexTemplate.set()` (onlyOwner). A fresh attacker's only listed contract (a PoolTemplate clone) has no way to originate the call: it cannot be added to any pool's `indexList` (see §3.1), and its own `_liquidation()` requires `Payingout` (owner-applied cover) and an indexList entry. On-chain evidence: the CDS has never emitted `Compensated`; `registry.getCDS()` returns `0x0` for all indices and the global slot; `crowdPool = 59,793,841,027` intact. **No fresh-attacker path.**
2. **"`registerIndex` lets a listed market claim an index slot" — REJECTED.**
   `registerIndex` registers `msg.sender`; an EOA fails `isListed`, and a clone cannot make itself call it. The only caller is the owner-gated `IndexTemplate.set()`.
3. **"H-06 first-depositor inflation" — NOT PROFITABLE today.**
   `worth()` still rounds down, but new pools cannot be seeded tiny because `conditionlist[0] = 1e9` forces a ≥1,000 USDC initial deposit for Factory-created pools. For existing tiny-supply pools the legacy holder — not the attacker — would capture a victim's rounding loss, and there are no DEX markets for iTokens to buy the cheap shares. Requires a future victim depositor; no fresh-attacker profit.
4. **"`withdrawRedundant` / `utilize` / `setController`" — owner-gated** (PoolProxy admins `0x54bE2f27…`; live vault controller `0x0`).
5. **"PoolProxy `withdraw_admin_fee` / `distribute` are permissionless"** — they only move PoolProxy-owned fee attributions to configured distributors; callers gain nothing.
6. **"Malicious `_references[0]` token reentrancy during `initialize`"** — `initialized = true` is set before the external `name()/symbol()` call; `registry/parameters/vault` are not yet set, so callbacks fail; the token is only used for metadata.
7. **Selector/ABI anomalies** — none (§5).

### 3.4 Residual (privileged / design) risks, not fresh-attacker E-U
- **H-07/H-10 class**: the PoolProxy owner/parameter/emergency admin (`0x54bE2f27E95BdAA5104960aAE7816554C0e3F056`) and the Reporting admin can list markets, set parameters, apply covers, pay bounties, set controller/keeper, and call `defund/_withdrawRedundant`. A compromised admin can drain funds (acknowledged by the sponsor and by C4). Current `default_reporting_admin = 0x0`, so `applyCover/applyBounty` are frozen until set.
- **`resume()` robustness**: if an index registered via `set()` is not a conforming IndexTemplate (`adjustAlloc`/`compensate` missing) `resume()` reverts → pool frozen in `Payingout`. Only reachable by a bad owner configuration.
- **Minor griefing**: expired policies can be unlocked by anyone (blocks a later past-period cover redemption for that policy); CDS/index `fund` donations are unaccounted for; `withdraw_admin_fee` reverts when `total_weights == 0` or `n_distributors == 0`.
- **Vault `_divRoundUp` edge**: withdrawals of very small amounts revert when `valueAll > totalAttributions` (price per attribution > 1); users can withdraw more.

---

## 4. INSURE token + Minter analysis

**Addresses:** INSURE `0xd83AE04c9eD29d6D3E6Bf720C71bc7BeB424393E`; Minter `0x76E8B82EA3450fA598E5e164c7E28af172deBDC0` (source fetched from Blockscout: single `Minter.sol`, solc 0.8.10); GaugeController `0x297ea2afcE594149Cd31a9b11AdBAe82fa1Ddd04` (31 gauges); Ownership `0x56246e83F3148B05Ce2D90B44fbb4e9fa9EAF5bb` (owner `0x79F5Dc19BC96ec1DB776d39535BDe169e67E33f4`).

| Path | Caller | Where minted tokens go | Permissionless? |
|---|---|---|---|
| `InsureToken.mint(_to,_value)` | `minter` only | `_to`; also checks emission schedule | No |
| `InsureToken.emergency_mint(_amount,_to)` | `minter` only | `_to`; `emergency_minted += amount` first ⇒ schedule cap effectively bypassed for emergency mints | No |
| `Minter.mint(gauge)` / `mint_many` | **anyone** | `msg.sender`; amount = `integrate_fraction(caller) − minted[caller][gauge]` — only the caller's own gauge emissions | Yes, but needs a gauge position |
| `Minter.mint_for(gauge,_for)` | caller approved by `_for` | `_for` | No |
| `Minter.toggle_approve_mint(x)` | anyone | — (grants `x` mint rights **for** msg.sender; self-approval only) | Yes, harmless |
| `Minter.emergency_mint(amount)` | `emergency_module` only | `emergency_module` | No — **`emergency_module() == 0x0` on-chain ⇒ uncallable** |
| `Minter.set_emergency_mint_module` / token setters | `onlyOwner` | — | No |
| `InsureToken.update_mining_parameters()` | anyone | no mint (advances epoch) | Yes, harmless |
| `LiquidityGauge.deposit/withdraw/kick/claimable_tokens` | mixed | `withdraw` only own balance; `kick` adjusts boost; `claimable_tokens` checkpoints any address without transferring | No theft |

State: `total_supply ≈ 148.49M`, `emergency_minted = 0`, `rate ≈ 1.78e17/s`, no DEX market (DexScreener: 0 pairs) ⇒ INSURE ≈ $0.

**Verdict:** no unprivileged path mints INSURE to an attacker without that attacker staking in a gauge, and emissions go to the staker/approved beneficiary. Emergency minting is dead (`module = 0x0`). Not a value target.

**InsureDAOERC20 (iToken base):** `_mint`/`_burn` are `internal`; `initializeToken` is `internal` with an `require(!tokenInitialized)` guard; `transferFrom` only special-cases `type(uint256).max`; `_beforeTokenTransfer` overrides merely trim pending withdrawal requests. No public mint/burn or transfer-hook issues.

---

## 5. Deployed-bytecode vs verified-source selector check

Method: `cast code` per impl; extract the dispatcher (`DUP1 PUSH4 <sel> EQ JUMPI`, plus the `PUSH3`/`PUSH2` optimization solc emits for leading-zero selectors) and compare with the verified ABI + `cast sig` of every source function.

| Contract | Address | ABI functions | Dispatched | Selectors in code absent from source |
|---|---|---|---|---|
| PoolTemplate | `0x1dcd...` | 56 | **56/56** | none |
| IndexTemplate | `0x2b16...` | 42 | **42/42** | none |
| CDSTemplate | `0x99f7...` | 32 | **32/32** | none |
| Vault | `0x131f...` | 33 | **33/33** | none |

**Stronger check (PoolTemplate):** recompiled the verified source set with solc 0.8.10+commit.fc410830, optimizer 200, evm london → runtime **20,570 of 20,613 bytes identical** to `eth_getCode(0x1dcd...)`; the only difference is the 32-byte IPFS metadata hash (`f52efaf9…` on-chain vs `47d68f9d…` local, expected from source-unit naming). The deployed code is the verified source. Artifacts: `deployed_PoolTemplate_bytecode.hex`, `IndexTemplate_bytecode.hex`, `CDSTemplate_bytecode.hex`, `Vault_deployed_bytecode.hex`, `selector-check-PoolTemplate.json`, `compile-check/`, `tools/`.

---

## 6. Bottom line

1. **Provenance is exact:** deployed V1 sources are byte-identical to `InsureDAO/pool-contracts@3327626` (2022-02-22), and the PoolTemplate runtime compiles from that source (metadata-hash-only difference). No hidden selectors exist in any of the four implementations — no red flags.
2. **No fresh-attacker (E-U) value-extraction path was introduced by the audited→deployed change set, and none was found in the changed functions.** The diff is a fix set; the new surfaces (`registerIndex`, `applyBounty`, `insure(_for,_agent)`, `redeem(_,_loss)`) are either owner-gated in practice (reachability analysis, §3.1) or economically neutral for the caller.
3. The two initial E-U candidates (CDS `compensate` drain; `registerIndex` slot claim) were **disproved**: only `IndexTemplate.set()` (onlyOwner) can call `registerIndex`, and only owner-assigned pools can reach `CDS.compensate`. On-chain: no `Compensated` event ever, `getCDS` mapping empty, CDS `crowdPool` intact.
4. **Residual risks are privileged roles** (PoolProxy owner/parameter/emergency admin `0x54bE2f27…`, reporting admin — currently `0x0`) and the acknowledged H-07/H-10 design; plus minor griefing (post-expiry `unlock`, `withdraw_admin_fee` reverts) and a tiny-withdrawal revert edge from `_divRoundUp`.
5. **INSURE: no unprivileged capture.** `mint`/`emergency_mint` are minter-only; permissionless `Minter.mint()` pays only the caller's own gauge emissions; `emergency_module = 0x0`; no DEX market ⇒ ~$0.
6. **Blockers/limits:** no transactions executed (paths are code+state-derived); PoolProxy/Ownership EOAs not attributed to organizations; the PoolTemplate compile-match was the only full recompile (others verified by complete selector-set equality); admin template approvals enumerated from Factory logs up to the current tip.
