# The Red Village (Polygon) — Z3-H4 deep dive: public `forwardRequest` → router-held `_authorizeUpgrade` → ZooKeeper drain

**Date:** 2026-10-16 · **Chain:** Polygon (137) · **Status:** read-only research; fork-only PoC (no mainnet transactions signed or sent); no secrets in this folder.

**Finding (Z3-H4):** `PolygonTRVRouter.forwardRequest(serviceName, serviceId, data)` was public with **no caller gate**, while the router itself held `_authorizeUpgrade` on the game's UUPS service proxies. On 2026-09-21 an attacker relayed `upgradeTo(maliciousImpl)` to the `SeasonService` proxy through this path and swept **31.426018474517367982 WETH** (~$80.7K at the time) from **299 players' standing WETH approvals** held by `TRVZooKeeper` (txs `0xac0666c5…` @ block 94,200,341 and `0x3730141a…` @ block 94,200,868; attacker EOAs `0xa566592c…` / `0xe3c4e2ea…`).

**Mandate of this deep dive:** determine the live E-U (fresh-attacker standard) and the exact re-arm conditions, with fork verification.

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why closed / open | Latent risk |
|---|---|---|---|
| Router relay path (`forwardRequest` → `upgradeTo`) | **$0** | Router proxy implementation replaced by a **"stopped" brick** (`0x7babf263…`) at block 94,241,212 — every call reverts `"stopped"`; the brick has **no upgrade function**, so the router is permanently frozen | None for a fresh attacker (path unrecoverable) |
| `SeasonService` proxy (`0xb172…`) | **$0** | Still runs **the attacker's implementation** (`0xa3822cdf…`, never replaced); its `upgradeTo` / `delegatecall(address,bytes)` backdoors are gated to `tx.origin == 0xa566592c…` / `0xe3c4e2ea…` (attacker EOAs). Not usable by anyone else | **Attacker-private backdoor** (key-gated); usable by the attacker if the ZooKeeper roles are ever re-granted |
| `TRVZooKeeper` vault (`0x426d…`) | **$0** | All role lists **empty** (team revoked `transferERC20In/Out`, `transferERC721In/Out`, `transferERC1155In/Out`, `setAccessControlProvider` in the 94.22M-block response). Only the ZooKeeper owner EOA can move funds (`P`) | Re-arms on any **privileged role re-grant**; every new approval to the ZooKeeper is instantly drainable by the owner key, and by the attacker if the old SeasonService is re-authorized |
| Standing WETH approvals (299 victims + other historical approvers) | **$0 E-U** | Full sweep: **488 of 691** historical approvers still carry a nonzero allowance, but **487 of 488 have zero balance**; the single live pair is 0.020692910651366064 WETH, drainable only by the ZooKeeper owner (**P**) | ~3,417.70 WETH nominal standing allowances (431 wallets ≤100 WETH each) — instantly drainable if any of those wallets is funded **and** a role is re-granted |
| `AccessControl` (`0x3f0B…`) | **$0** | Role admin = owner EOA only (all `grantRoles`/`grantMaster` members empty) | Owner-key compromise would re-arm everything (`P`) |
| Registry (`0x6547…`) | **$0** | Same "stopped" brick at block 94,241,214 | None (permanently frozen) |
| Stuck WETH in NFT contracts | **$0 E-U** | 0.0167 WETH in `SummonChampions` + 0.12 WETH in `TRVBPToken`; neither contract has any ERC20-withdrawal function → **S (stuck)** | None (unrecoverable) |

## 2. Total live extractable now: **$0.00** (E-U)

- **E-U (external unprivileged): $0.00** — high confidence (fork-verified; see §6). No permissionless call path reaches any value today.
- **E-U conditional re-arm (fresh-attacker standard): $0.00** — the only re-arm path (role re-grant) is a **privileged** action, and even after a re-grant of the old SeasonService, the drain is executable only by the attacker's key-gated backdoor, not by a fresh attacker.
- **P (privileged):** the ZooKeeper owner EOA can drain every live `(allowance, balance)` pair today — measured total **0.020692910651366064 WETH ≈ $50.51** (single wallet `0xa1f57609…`); latent up to **≈3,417.70 WETH** nominal if the standing-allowance wallets are ever funded.
- **S (stuck):** 0.1367 WETH in two NFT contracts ≈ **$334** (at $2,441.10/WETH) — permanently unrecoverable; plus the bricked router/registry and the hostile-controlled SeasonService proxy.

---

## 3. The mechanism in exact terms (verified sources)

Deployed addresses (Polygon mainnet):

| Role | Address | Type |
|---|---|---|
| `PolygonTRVRouter` proxy | `0xc97dCb0492412bFBBf47332F1B1b49e177e8f15C` | ERC-1967-style minimal proxy |
| Router impl **today** | `0x7babf2638eadd2bc41d62ba632d2948ba1efb8a1` | "stopped" brick (reverts everything) |
| Router impl at incident | `0xad0c7d70c99a07f99ef24dfbb645dc5e251b0b60` | verified `PolygonTRVRouter` |
| `SeasonService` proxy | `0xb172E15974FEAAe221EbC0860B578Dd7B6B06b77` | ERC-1967-style minimal proxy |
| SeasonService impl **today** | `0xA3822CdF2Bb59CeFC7E70Fa5d693B7E9fBc50aFa` | **attacker's minimal impl** (unverified; deployed in the exploit tx) |
| SeasonService impl at deployment | `0x23f1dcb561a0d17e9a48fd379400759777b8fcaa` | verified `PolygonTRVSeasonService` |
| `TRVZooKeeper` vault | `0x426d27190A2DdB87f1C6235F710e159a0A3774D4` | direct contract (not a proxy), verified |
| `AccessControl` | `0x3f0B50B7A270de536D5De35C11C2613284C4304e` | direct contract, verified |
| `PolygonTRVRegistry` proxy | `0x6547b4A12953F70C44DF5bb57E78fce68199c5c8` | ERC-1967-style minimal proxy; impl **today** = same "stopped" brick |

**Root cause chain (from the verified sources):**

1. `PolygonTRVRouter.forwardRequest(string serviceName, string serviceId, bytes data)` — *public, no caller gate*:
   ```solidity
   address service = IPolygonTRVRegistry(coreRegistry).getServiceInstance(_serviceName, _serviceId);
   (bool success, ) = service.call(_funcEncodeWithSignature);   // arbitrary call, router as msg.sender
   ```
2. The router's own `_authorizeUpgrade` and every service's `_authorizeUpgrade` are `onlyRoler("_authorizeUpgrade")`; `BaseUpgradeable.onlyRoler` consults the shared `AccessControl` via `hasRole(msg.sender, address(this), "_authorizeUpgrade")`.
3. At the incident block, `hasRole(router, SeasonService, "_authorizeUpgrade") == true` (verified at block 94,200,340) → the relayed `upgradeTo(maliciousImpl)` passed the UUPS check with `msg.sender == router`.
4. The malicious impl then ran in the proxy's context; its calls to the ZooKeeper carried `msg.sender == SeasonService proxy`, and `hasRole(SeasonService, ZooKeeper, "transferERC20In"/"transferERC20Out") == true` at the time (verified) → `TRVZooKeeper.transferERC20In/Out` pulled and swept the standing approvals.

**The attacker's impl (still deployed, still the active impl) — exact behavior (disassembled from bytecode):**

- `upgradeTo(address)` / `upgradeToAndCall(address,bytes)` — custom errors `NotProxy()` (0xbf10dd3a), `NotUpgrader()` (0xa4174502), `NotContract()` (0x6f7c43f1). Guards, in order: (a) `address(this) != 0xa3822cdf…` (must be the proxy), (b) the proxy's current ERC-1967 impl slot must still equal `0xa3822cdf…`, (c) `tx.origin == 0xa566592cB94475BaF5B46Ce373A260dfC9d0dF3F` (immutable `UPGRADER`), (d) new impl has code.
- `delegatecall(address,bytes)` — custom error `NotAuthorized()` (0xea8e4eb5); guard: `tx.origin == 0xe3c4e2ea29cbE47aE205F9C18CBcb0C8C51bfdec` (immutable `AUTHORIZED`). This is the function the drain tx called (`0x6e0aacf7`), delegating to the attacker's helper `0x29040a143c7261b1c2a4ab0c5806ca7ad2009fc2`.
- `proxiableUUID()` returns the ERC-1967 slot only when `address(this) == 0xa3822cdf…`.

---

## 4. Live-state assessment (Polygon mainnet, latest block 95,606,441 — CI fork block; sweep blocks 30,879,409 → 95,224,548)

*(all values read-only via public RPC / Etherscan V2; full dumps in `analysis/`)*

### 4.1 The mitigation timeline (team EOA `0xCD3b6008ba2F5115004ab7A07Be779cAa63CdF3F`)

| Block | Action | Evidence |
|---|---|---|
| 94,200,341 | Attacker relays `upgradeTo(0xa3822cdf…)` via `forwardRequest` (tx `0xac0666c5…`) | `Upgraded` event on SeasonService proxy |
| 94,200,868 | Drain tx `0x3730141a…` — 299 `transferERC20In` pulls + `transferERC20Out` of **31.426018474517367982 WETH** to `0xa566592c…` | 600 logs; ZooKeeper→attacker WETH transfer |
| 94,227,393–94,227,448 | 25+ `revokeMaster(account, contract)` calls on the AccessControl | txs by `0xCD3b…` |
| 94,240,965–94,241,005 | 10 `modifyServiceInstance` calls: `System/Router`, `System/ZooKeeper`, `Season/SeasonService`, `System/SystemVerifier`, `System/AccessControl` re-pointed to `0xe09be4a0…` (3-byte no-op stub) then `0x9fac792f…` (`0x60006000fd` = revert stub) | registry storage (slot 302 mapping, read directly) |
| 94,241,204 | Deploy "stopped" brick `0x7babf263…` | tx `0xd206cfd2…` |
| 94,241,212 | Router `upgradeTo(brick)` | tx `0xbcc4f570…` |
| 94,241,214 | Registry `upgradeTo(brick)` | tx `0x3dcb19bc…` |

### 4.2 Role state (AccessControl `0x3f0B…`, `hasRole(account, contract, methodInfo)`)

| Check | At block 94,200,340 (pre-incident) | Today |
|---|---|---|
| `hasRole(router, SeasonService, "_authorizeUpgrade")` | **true** | **false** |
| `hasRole(SeasonService, ZooKeeper, "transferERC20In")` | **true** | **false** |
| `hasRole(SeasonService, ZooKeeper, "transferERC20Out")` | **true** | **false** |
| `getMembersByRole(ZooKeeper, "transferERC20In"/"Out"/721In/721Out/1155In/1155Out/"setAccessControlProvider")` | — | **all empty** |
| `getMembersByRole(AccessControl, "grantRoles"/"revokeRoles"/"grantMaster"/"revokeMaster")` | — | **all empty** |
| `getMastersByRole(SeasonService)` / `(Router)` | — | `[0x2f3422F381e74a273eAde3CE88FCe525460ad6E4]` = `PolygonTRVDeployer` (team contract; inert now — both contracts are bricked/hostile) |
| `getMastersByRole(ZooKeeper)` / `(AccessControl)` | — | **empty** |

**Owners:** `TRVZooKeeper.owner() = 0xBd28b1786060AdE61f0bFcEde736a80fC64ba13c` (EOA); `AccessControl.owner() = 0x909680a5E46a3401D4dD75148B61E129451fa266` (EOA, also owner of the three NFT contracts).

### 4.3 Backdoor gating on the SeasonService proxy (eth_call, latest)

| Call | From | Result |
|---|---|---|
| `router.forwardRequest("Season","SeasonService", upgradeTo(x))` | fresh EOA | **revert `"stopped"`** (router brick) |
| `SeasonService.upgradeTo(x)` | fresh EOA | **revert `NotUpgrader()`** |
| `SeasonService.upgradeTo(x)` | `0xa566592c…` | passes gate; `NotContract()` for an EOA target (gate open for attacker) |
| `SeasonService.delegatecall(target,data)` | fresh EOA | **revert `NotAuthorized()`** |
| `SeasonService.delegatecall(target,data)` | `0xe3c4e2ea…` | gate passes (runs target code in proxy context) |
| `ZooKeeper.transferERC20In(WETH, x, 1)` with `msg.sender = SeasonService` | — | **revert `"Caller does not have permission"`** |
| `ZooKeeper.transferERC20In/Out` from owner `0xBd28…` | — | succeeds (`P`) |

### 4.4 Balances

| Holder | WETH | Notes |
|---|---|---|
| `TRVZooKeeper` | **0** | vault emptied at the incident; no deposits since |
| Router / SeasonService / Registry | 0 / 0 / 0 | |
| `SummonChampions` `0x57f698d9…` | 0.0167 | **stuck** (no ERC20 withdrawal in contract) |
| `TRVBPToken` `0x4055e350…` | 0.12 | **stuck** (withdraw() moves only native POL) |
| Old TRVC `0x8a57d0cb…` | 0 | |

### 4.5 Approval surface (full-history sweep, all 324,696 Approval events to the ZooKeeper)

Method: every `Approval` log on WETH (and a cross-check with no address filter, topic2 = ZooKeeper — WETH is the only token involved) with `spender = TRVZooKeeper`, full history (blocks 30,879,409 → 95,224,548), then a Multicall3 `allowance`+`balanceOf` sweep over every unique approver at the latest block. Artifacts: `analysis/weth_approvals_zookeeper_merged.json.gz`, `analysis/allowance_balance_full.json`, `analysis/approval_owners_summary.csv`, `analysis/victim_reconciliation.json`; re-verified independently by `test_T7` in CI.

- Unique wallets that ever approved WETH to the ZooKeeper: **691**
- Still carrying a nonzero allowance today: **488**
  - **431 wallets** with realistic allowances (≤100 WETH): **3,417.70 WETH** nominal total — e.g. many ~9–10 WETH approvals from 2023 that were never consumed (the attacker only pulled from wallets that *held* WETH).
  - **57 wallets** with non-standard huge allowances (1e16–8e17 WETH nominal; e.g. `0xd725f8fe…` with 4,548 approval events) — operational/aggregator wallets, all with **zero balance**.
- Wallets with allowance **and** balance (the only live pair): **1** — `0xa1f5760901dfc4251e0506f179ba9c2a56e28d77` (allowance 9.99508 WETH, balance **0.020692910651366064 WETH ≈ $50.51**). Drainable only by the ZooKeeper owner (`P`).
- **Correction vs the prior pass:** the earlier "272 victims retain 4.158 WETH" figure was an undercount. Re-measured on-chain: **272 of the 299 incident victims still carry allowances**, totalling **1,924.07 WETH** in the ≤100 WETH bucket (plus 38 victims in the non-standard huge bucket). Direct `cast call` spot-checks confirm (e.g. `0x001b8e2c…` allowance 9.999925 WETH, balance 0).
- Post-incident approvals: **none** — the 15 `Approval` events after the drain block are all `approve(ZK, 0)` revocations (several via EIP-7702 batch-revoke tools, the most recent at block 95,224,548).

**NFT operator surface (re-arm, secondary):** 62 `ApprovalForAll(owner, ZooKeeper)` grants still active; 46 of those owners still hold **1,365 TRV NFTs** (TRVG/TRVC collections). The ZooKeeper's ERC721 roles are revoked, so these are not movable today; they re-arm only under a role re-grant.

---

## 5. What an attacker can / cannot do

**Today (fresh unprivileged attacker): nothing.** Every candidate path:

1. `router.forwardRequest(...)` → reverts `"stopped"` (impl is the brick). The brick exposes only `proxiableUUID()`; no upgrade function exists, so the router can never be revived. **Dead.**
2. `SeasonService.upgradeTo/delegatecall` → `NotUpgrader()`/`NotAuthorized()` for any caller whose `tx.origin` is not the attacker's EOAs. `tx.origin` cannot be forged. **Dead for third parties.**
3. Direct ZooKeeper calls (`transferERC20In/Out`, …) → `"Caller does not have permission"`; all role lists empty. **Dead.**
4. `AccessControl.grantRoles/…` → owner-only; role lists empty. **Dead.**
5. Registry-based resolution → registry is bricked; any `onlyRoler` call by a non-owner in the v3.2 services reverts `"stopped"` inside `onlyRoler` (the registry lookup itself reverts). **Dead.**
6. The 15 post-drain approvals are all `approve(ZK, 0)` revocations; no new approvals exist to drain. **Nothing to take.**

**Attacker (key-holding) could today:** use the `tx.origin`-gated `delegatecall` backdoor to execute arbitrary code as the SeasonService proxy, and replace its implementation. **But every downstream authority of the SeasonService proxy has been revoked** — its ZooKeeper roles are gone, so it can no longer move anything. The backdoor is a live capability with **no reachable value**.

**Re-arm conditions (exact preconditions):**

| # | Precondition (all required) | Who can trigger | Result |
|---|---|---|---|
| R1 | AccessControl owner (`0x909680a5…`) re-grants a ZooKeeper transfer role to the **old SeasonService proxy** | privileged only | The **original attacker** (key-gated backdoor) can drain everything: new approvals, residual allowances on funded wallets, and the NFT operator surface — one tx, gas only |
| R2 | … re-grants a role to a **different, unprivileged-exploitable contract** | privileged only | Fresh-attacker E-U would equal that contract's reach (none exists today) |
| R3 | A funded wallet still carrying a residual allowance + role present (R1) | player funding + R1 | That wallet's WETH is instantly drainable |
| R4 | ZooKeeper owner key used/compromised | privileged/key | Drains all live `(allowance, balance)` pairs; today **0.0207 WETH (≈$50.51)** — the measured `P` total |
| R5 | AccessControl owner key compromised | key | Can execute R1/R2/R4 arbitrarily |

**No unprivileged actor can move any value today, and no unprivileged action re-arms the system.** Every re-arm route passes through a privileged key or the attacker's own key.

---

## 6. PoC / fork verification

**Files:** `poc/test/RedVillage.t.sol`, `poc/src/Attackers.sol` (Foundry; public RPCs only; no keys).

| Test | What it proves | Result |
|---|---|---|
| `test_T1_router_forwardRequest_is_bricked` | router relay reverts `"stopped"`; brick has no `upgradeTo` | **PASS** (gas 63,761) |
| `test_T2a_season_upgrade_gated_to_attacker_origin` | impl slot is still the attacker's; fresh caller → `NotUpgrader()`; attacker origin → upgrade succeeds | **PASS** (gas 69,196) |
| `test_T2b_season_delegatecall_gated_to_attacker_origin` | fresh caller → `NotAuthorized()`; attacker origin → delegatecall executes in proxy context | **PASS** (gas 70,445) |
| `test_T3a_zookeeper_roles_revoked_today` | all ZooKeeper roles empty; `transferERC20In` from SeasonService reverts `"Caller does not have permission"` | **PASS** (gas 149,574) |
| `test_T3b_zookeeper_roles_were_live_before_incident` | at block 94,200,867 the relay + ZooKeeper roles were live | **PASS** (gas 33,536) |
| `test_T4a_rearm_drain_blocked_today_even_with_backdoor` | with a re-armed player + malicious impl installed, the drain still reverts (roles revoked) | **PASS** (gas 362,717) |
| `test_T4b_rearm_drain_works_once_roles_regranted` | after the AccessControl owner re-grants the roles, the same drain succeeds instantly | **PASS** (gas 601,589) |
| `test_T5_zookeeper_owner_path_is_privileged` | unprivileged caller reverts; owner can pull standing approvals | **PASS** (gas 417,152) |
| `test_T6_historical_permissionless_replay` | at block 94,200,340 a **fresh caller** relays `upgradeTo` through `forwardRequest` and drains the first 10 documented victims (+ vault pre-balance) = **23.537011567103208243 WETH** gained | **PASS** (gas 379,067) |
| `test_T7_full_allowance_balance_sweep` | full sweep over every historical approver → 691 checked / 488 with allowance / 1 live (0.020692910651366064 WETH) | **PASS** (gas 13,841,301) |

**Suite: 10/10 PASS** (fork of Polygon mainnet at the CI's latest block 95,606,441; archive fork at block 94,200,340 for T6; public RPCs only; `evm_version = cancun` required — the attacker's impl uses `MCOPY`).

**CI runs (public repo, keyless artifacts):**
- ✅ Final: https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38837619929 (10/10 pass)
- Iterations: runs 38836603861 (7/10; test-harness bugs) and 38837226456 (9/10; `evm_version` fix)
- Artifacts: `ci-artifacts/result-red-village/ci-out/{live_state.json, sweep_results.json}`

**Key numbers:** historical drain 31.426018474517367982 WETH; vault pre-balance 0.075638972516 WETH; the attacker's total take = 31.426018474517367982 WETH. Gas cost of the whole exploit today would be trivial (<0.1 POL) — cost is not the blocker; the revoked roles are.

---

## 7. Verdict and residual / latent risk

**Verdict: the exploit path is CLOSED. E-U today = $0.00 (high confidence). The finding downgrades from "perpetual re-arm" to "attacker-key-gated backdoor + privileged-only re-arm".**

Residual risks, in order:

1. **Attacker-private backdoor on the SeasonService proxy** — the proxy permanently runs the attacker's impl (`0xa3822cdf…`); the team cannot upgrade it (their only relay, the router, is bricked; the backdoor gates on the attacker's keys). If the protocol ever re-grants the old SeasonService any ZooKeeper role, the attacker (or anyone who obtains those two EOA keys) can drain everything in one tx. **This is the main latent risk.**
2. **Privileged re-arm surface** — the AccessControl owner can re-grant roles; the ZooKeeper owner can always move any live `(allowance, balance)` pair. Monitor both keys.
3. **Residual allowances** — 488 wallets still carry allowances (≈3,417.70 WETH nominal in the ≤100 WETH bucket) with zero balances; funding any of them re-creates value that is owner-drainable (and attacker-drainable under R1). Players can still self-revoke (15 did).
4. **NFT operator surface** — 62 active `ApprovalForAll(ZooKeeper)` grants across 46 owners holding 1,365 TRV NFTs; dormant until any ERC721 role is re-granted.
5. **Stuck value (S):** 0.1367 WETH (~$334) in `SummonChampions` + `TRVBPToken` (no ERC20 exit), permanently unrecoverable; the router/registry bricks are permanent; the SeasonService proxy is unrecoverable by the team without the attacker's cooperation.

**Monitors (all read-only, cheap):**
- `AccessControl.getMembersByRole(ZooKeeper, "transferERC20In"/"transferERC20Out"/"transferERC721In"/"transferERC721Out"/"transferERC1155In"/"transferERC1155Out")` — **any non-empty value = immediate re-arm**.
- `AccessControl.getMembersByRole(AccessControl, "grantRoles")` + `getMastersByRole(ZooKeeper)`.
- `TRVZooKeeper.owner()` and `AccessControl.owner()` changes.
- SeasonService ERC-1967 impl slot (`0x360894…`) — any change = attacker (or key-holder) acted.
- WETH `Approval` events with `spender = 0x426d…` (new approvers) and WETH balances of the residual-allowance wallet set.
- `ApprovalForAll(operator = 0x426d…)` on TRVG/TRVC collections.
- Attacker EOAs `0xa566592c…` / `0xe3c4e2ea…` — any new tx.

---

## 8. Methodology & sources

- On-chain reads at explicit blocks (94,200,340/94,200,867/94,200,868/latest) via public Polygon RPCs; verified sources pulled from Etherscan V2 (`TRVZooKeeper`, `AccessControl`, `PolygonTRVRouter` impl, `PolygonTRVSeasonService` impl, `PolygonTRVRegistry` impl, `SummonChampions`, `TRVBPToken`).
- Full-history `Approval` log sweep (topic0=Approval, topic2=ZooKeeper) over all contracts (Etherscan V2, paginated), then a Multicall3 allowance+balance sweep over every unique approver (`poc/test/RedVillage.t.sol::test_T7`, artifacts in `ci-out/`).
- Bytecode disassembly of the attacker's live impl (heimdall) + eth_call gate probing; custom-error selectors verified (`NotUpgrader()=0xa4174502`, `NotAuthorized()=0xea8e4eb5`, `NotProxy()=0xbf10dd3a`, `NotContract()=0x6f7c43f1`).
- Fork PoC on GitHub Actions (public CI repo), public RPCs only; no keys, no mainnet transactions.
- USD: WETH = $2,441.10 (DefiLlama, 2026-10-16).

**Caveats:** (1) the attacker's impl is unverified bytecode — its gating was established by disassembly + eth_call probing, not source; (2) "residual allowances" are only liabilities, not recoverable value; (3) prices move — USD figures at the stated time; (4) reads are point-in-time; re-verify before acting; (5) no audit of the wider TRV system was performed beyond the paths documented here.

**Files index:** `README.md` (this) · `summary.json` · `analysis/` (sources/, logs, storage dumps, sweep inputs) · `poc/` (Foundry project) · `ci/run.sh` · `ci-out/` (CI artifacts) · `ci-log.txt` · `ci-artifacts/`.
