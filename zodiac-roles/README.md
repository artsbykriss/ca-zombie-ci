# Zodiac Roles v2.1.0 / Delay v1.1.0 — ERC-1271 revert-data authentication bypass

**Date:** 2026-11-03
**Chains:** Ethereum mainnet (primary; Polygon context from CA2)
**Status:** read-only; PoC on a local mainnet fork only; no mainnet transaction broadcast; no keys.

## TL;DR

| Question | Answer |
|---|---|
| Is the ERC-1271 bypass real on live code? | **Yes.** The live Roles v2.1.0 mastercopy `0x9646fDAD06d3e24444381f44362a3B0eB343D337` and Delay v1.1.0 `0x01F8cabB808D7dE0dF4202D4B60C8310d2f1339b` still contain `_isValidContractSignature` with the discarded `staticcall` success flag. A contract that reverts with `0x1626ba7e` is accepted. |
| Can an unprivileged caller forge the signature? | **Yes.** `moduleOnly` accepts a 97-byte trailing trailer whose `r` is an **enabled module Safe**, and the Safe's `isValidSignature` → `checkSignatures` → attacker contract reverts with the magic value. The discarded success flag then authorizes the call. |
| Does that drain the funds? | **No.** After authentication, `_authorize` checks `role.members[signer]` and the role's permission scope. On the two largest **reachable** instances every value-moving probe is rejected with `ConditionViolation`. |
| Largest reachable-but-blocked value | **$2,488,010.81** — Roles `0x2b818761…ba20`, avatar `0x4971DD01…e462` (631.86 wstETH + 2,974.25 GNO + 155.38 WETH + 20,592.67 USDC), role `MANAGER`, module Safe `0xf423f27F…47A9` (threshold 2, canonical handler). |
| Is there any permissive scope in the sample? | **No — 0 permissive hits** across 2 Roles instances × 6 drain shapes + the Delay queue probe. |
| Delay 1 ETH | The forged tx **queues** (`execTransactionFromModule` returns true), but the live queue is stuck at index 9 behind a pre-existing `MultiSend` transaction that reverts with Safe `GS104`; the attacker's tx cannot execute. The owner can `setTxNonce()` to skip the stuck txs (and can skip the attacker's tx). |
| Headline | **$0 E-U** (confidence: high for the sampled set; medium for the full population). The value is **H-O** (avatar owners) / role-admin-gated, not attacker-extractable. |

## 1. The bug in exact terms

Live Roles source (`analysis/roles_src/contracts__Roles.sol` + `@gnosis.pm/zodiac/contracts/signature/SignatureChecker.sol`):

```solidity
function _isValidContractSignature(address signer, bytes32 hash, bytes calldata signature)
    internal view returns (bool result)
{
    if (extcodesize(signer) == 0) return false;
    (, bytes memory returnData) = signer.staticcall(
        abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
    );
    return bytes4(returnData) == 0x1626ba7e;   // success flag discarded
}
```

`Modifier.moduleOnly` parses the last 97 bytes of calldata (`salt‖r‖s‖v`); with `v == 0`, `r` is the signer and `s` is the offset to the signature bytes. It requires `modules[signer] != 0`, then calls the signer. If the signer is a Safe whose fallback handler implements `isValidSignature`, the Safe's `checkSignatures` calls the contract named in the inner signature blob; that contract reverts with `0x1626ba7e`, the revert data bubbles up, and `_isValidContractSignature` accepts it.

Then `_authorize`:

```solidity
Role storage role = roles[roleKey];
if (!role.members[sentOrSignedByModule()]) revert NoMembership();
...
(status, result) = _transaction(role, to, value, data, operation, ...);
if (status != Status.Ok) revert ConditionViolation(status, result.info);
```

So the attacker needs **(a)** an enabled module that is a Safe with a 1271 fallback handler, **(b)** that module to be a member of a role, **(c)** a role key, and **(d)** the role's scope to permit a value-moving call. The first three are satisfiable on live instances; (d) is the binding control.

## 2. Live enumeration (independent)

Factory: Zodiac `ModuleProxyFactory` `0x000000000000aDdB49795b0f9bA5BC298cDda236`.
Event: `ModuleProxyCreation(address indexed proxy, address indexed masterCopy)` (`topic0 0x2150ada9…7c5f`).
Window: blocks 19,000,000–28,200,000 (the period in which the v2.1.0 / v1.1.0 mastercopies were in use), Etherscan V2 `getLogs` with `topic2` = mastercopy.

| mastercopy | version | Ethereum proxies found |
|---|---|---:|
| `0x9646fDAD06d3e24444381f44362a3B0eB343D337` | Roles v2.1.0 | **9,912** |
| `0x01F8cabB808D7dE0dF4202D4B60C8310d2f1339b` | Delay v1.1.0 | **136** |

Reachability precondition: the instance has at least one enabled module `M` with `extcodesize(M) > 0`, `M` is an ERC-1271-capable Safe (fallback handler set), and `roles[roleKey].members[M] == true` (or `defaultRoles[M]`). For the sample, `avatar()` was read for 6,683 of the 9,912 Roles proxies (the rest revert / are uninitialized); 130 of the 136 Delay proxies expose an avatar.

### 2.1 Largest nominal avatars (independent token scan)

Five-token scan (`USDC`, `USDT`, `WETH`, `wstETH`, `GNO`) over 6,683 avatars, DefiLlama prices 2026-11-03:

| Avatar | Roles instance | Value | Precondition | Reachable? |
|---|---|---:|---|---|
| `0x1A8c5314…4D17` | `0x3e6f23ad…132c` | 2,970,088.14 USDC ≈ **$2.97M** | `getModulesPaginated` returns **[]** | **No** — no enabled module, `moduleOnly` cannot find a signer |
| `0x9325cC41…b3E0` | `0xd6f7430c…f628` | 580,092.70 USDT ≈ **$580k** | module `0xbB91c81d…F4a8` has **no code** (EOA) | **No** — `extcodesize(signer)==0` |
| `0xac75FC4A…fC99` | `0x1d05199d…39a2` | 166,546.85 USDC ≈ **$166k** | module `0xC99dBbc6…F5a5` has no code | **No** |
| `0x246bb72f…b70C` | `0x38c61eca…6193` | 34,859.73 USDC ≈ **$35k** | module `0xF7AC4a05…EAf5` has no code | **No** |
| `0xEe6B63e2…33BB` | `0x3a226191…ac74` | 2.8653 WETH ≈ **$6.5k** | module `0x54240C95…3f0D` has no code | **No** |
| `0x5A4dd5E2…53c1` | `0x6d403019…a968` | 2.8173 WETH ≈ **$6.4k** | module `0x3687d272…03e7` has no code | **No** |
| `0xDB874eDe…e1a1` | `0xe85e820f…4ae9` | 2,112.13 USDC ≈ **$2.1k** | module `0x96c4aF8A…487b` has no code | **No** |
| `0x7F8987D6…2a28` | `0xf3eda195…1c5c` | 1,553.97 USDC ≈ **$1.6k** | module `0xfABCA795…123a` is a Safe threshold 2 but **handler = 0** | **No** |

The **$2.97M** instance is the largest nominal value, but it has no modules at all; the next three are blocked by EOA modules or a handler-less Safe. This is the independent confirmation of the "reachable-but-blocked" framing: the value that is *reachable through the bypass* is smaller than the naive token ranking.

### 2.2 Largest reachable instance (the target)

| Field | Value |
|---|---|
| Roles proxy | `0x2b818761ebCf1CcA5e609cC71D8feCB658ADBa20` |
| Avatar | `0x4971DD016127F390a3EF6b956Ff944d0E2e1e462` |
| Module (enabled) | `0xf423f27FAe9dDd0ee0d50cbC11B94c99DcB347A9` — Safe, `getThreshold()=2`, handler `0xf48f2b2d2a534e402487b3ee7c18c33aec0fe5e4` |
| Role key | `MANAGER` (`AssignRoles` at creation, block 20,935,124; `memberOf=true`) |
| Balances | 631.862475538579 wstETH; 2,974.2454619612095 GNO; 155.37750641344292 WETH; 20,592.673362 USDC |
| USD (DefiLlama 2026-11-03) | **$2,488,010.81** |
| Forged auth | **Passes** (2-of-2 inner Safe signature: two attacker contracts at ascending addresses, both revert `0x1626ba7e`) |
| Drain probes | wstETH/GNO/WETH/USDC `transfer` → `ConditionViolation(3, selector)`; native → `ConditionViolation(2, 0)`; `approve` → `ConditionViolation(5, 0)` |

### 2.3 Second reachable instance

| Field | Value |
|---|---|
| Roles proxy | `0xef66973E7590C49475DC3013fA6841D14659BA66` |
| Avatar | `0x12BEEF35025841EFccb77D6EE40df86400Fdb4bB` |
| Module | `0xce3FDCB7497928b82c3B5095B8714afE577070D6` — Safe threshold 1, canonical handler `0xfd0732Dc9E303f09fCEf3a7388Ad10A83459Ec99` |
| Role | `gg_payroll` (`0x67675f706179726f6c6c…`) |
| Balance | 60,978.76 USDC |
| Forged auth | **Passes** |
| Drain probes | USDC `transfer` → `ConditionViolation(5, 0)`; `approve` → `ConditionViolation(3, 0x095ea7b3…)`; both blocked |

## 3. Delay v1.1.0 — 1 ETH, queued but stuck

Live instance:

| Field | Value |
|---|---|
| Delay proxy | `0x0F1D8A73C02F2E44b17aF3e1ac389E7ce0a2E15B` |
| Avatar Safe | `0x36B42d0EE96d66928674E02B005dF2d8D75E68C5` (threshold 1, canonical handler) |
| `txCooldown` | 21,600 s (6 h) |
| Balance | **1.0 ETH** (≈ $2,281.94) |
| Modules | `[0x36B42d0E…68C5]` — the avatar Safe itself; `modules[avatar] != 0` |
| Forged `execTransactionFromModule(attacker, 1 ETH, "", 0)` | **Queues successfully** (`queueNonce` increments; `TransactionAdded` emitted) |
| Execution | **Blocked.** The live queue has `txNonce=9`, `queueNonce=12`; the next tx (index 9) is a pre-existing `MultiSend` delegatecall that reverts with Safe `GS104` (`analysis/delay_pending_txs.json`). `executeNextTx` reverts, `txNonce` stays 9, so the attacker's tx is unreachable. |
| Owner remedy | `setTxNonce(12)` (onlyOwner) skips the stuck txs; `setTxNonce(13)` also skips the attacker's queued tx. Owner-controlled. |

Other funded Delay instances are dust (0.102, 0.1, 0.1, 0.02, … ETH); the only 2.52 ETH instance (`0x6e51ab91…702a`) has **no modules**, so the bypass cannot authenticate there. The 0.1 ETH instance with a module (`0x6e92cd35…04fc`) has an avatar with **no fallback handler** and a non-Safe module, so it is not exploitable.

## 4. Exact attacker path (for the record)

```
attacker → Roles.execTransactionWithRole(to, value, data, op, roleKey, false)
           ‖ innerSafeSig ‖ salt(32) ‖ r=moduleSafe(32) ‖ s=offset(32) ‖ v=0

moduleOnly → moduleTxSignedBy → _isValidContractSignature(moduleSafe, hash, innerSig)
  → moduleSafe.isValidSignature → CompatibilityFallbackHandler → Safe.checkSignatures
    → ISignatureValidator(attackerContract).isValidSignature(...) → revert 0x1626ba7e
  → bytes4(returnData) == magic → accepted
→ role.members[moduleSafe] checked
→ role scope (_transaction) → ConditionViolation on every value-moving shape tested
```

No key, no role, no Safe signature, no Safe compromise. Cost: gas only. But the scope rejects the call, so there is no profit.

## 5. Verdict and residual risk

**$0 E-U.** The bypass is real, live, immutable, and reproduced on the two largest reachable instances; the role scope is the binding control.

Residual / unverified:
- The permission sweep is a **bounded sample** (2 Roles instances × 6 shapes + 1 Delay), not the full 227/46 set. CA2's 1,071-test sweep found 0 permissive; this run independently confirms the two largest reachable instances and the Delay queue.
- The scope decoding was done by simulation, not by decoding the packed `scopeConfig`; a role that permits a different value-moving shape (an allowlisted recipient the attacker controls, a delegatecall target, a token not in the sample) was not exhaustively searched.
- Polygon proxies (CA2: 291 Roles + 23 Delay) were not re-enumerated or probed in this run.
- The enumeration window starts at block 19M; the full 0–19M range was not re-scanned with the topic filter.
- The 1 ETH Delay value is dynamic: if the owner clears the stuck queue with `setTxNonce` but does not skip the attacker's tx, a previously queued attacker tx could become executable after 6 h. That is owner-dependent, not a live E-U.

## 6. PoC / CI

Foundry project `poc/` (vendored `lib/forge-std`, solc 0.8.24, fork tests):

| Test | Result |
|---|---|
| `ZodiacReproTest.test_repro_auth_bypass_and_scope` | PASS — 0x12BEEF, forged auth passes, `ConditionViolation(5,0)` |
| `ZodiacReproTest.test_repro_approve_blocked` | PASS — `ConditionViolation(3, 0x095ea7b3…)` |
| `ZodiacTopAvatarTest.test_top_avatar_auth_bypass_scope_blocked` | PASS — $2.488M instance, `ConditionViolation(3, 0xa9059cbb…)` |
| `ZodiacTopAvatarTest.test_top_avatar_other_tokens_blocked` | PASS — GNO/WETH/USDC all blocked |
| `ZodiacTopAvatarTest.test_top_avatar_approve_blocked` | PASS — `ConditionViolation(5,0)` |
| `ZodiacTopAvatarTest.test_top_avatar_native_blocked` | PASS — `ConditionViolation(2,0)` |
| `ZodiacDelayTest.test_delay_queue_only_auth_bypass` | PASS — queue succeeds, 1 ETH not moved |
| `ZodiacDelayQueueTest.test_pending_queue_liveness` | PASS — pending index-9 tx reverts `GS104`, `txNonce` stays 9 |

Local run: `8 passed, 0 failed` (4 suites). CI run: see `ci-log.txt` / `summary.json`.

## 7. Methodology / sources

- Factory logs: Etherscan V2 `module=logs&action=getLogs`, `topic0=0x2150ada9…`, `topic2` = mastercopy, block chunks 19M–28.2M.
- Mastercopy bytecode: live `eth_getCode` equality with the official v2.1.0 / v1.1.0 artifacts; verified source via Etherscan V2 `getsourcecode` (`analysis/roles_src/`).
- Per-instance state: `avatar()`, `getModulesPaginated(0x1,200)`, `getThreshold()`, Safe fallback-handler slot `0x6c9a6c4a…18d5`, `defaultRoles(module)`, `AssignRoles` logs.
- Balances/prices: `balanceOf` on USDC/USDT/DAI/WETH/wstETH/GNO; DefiLlama `coins.llama.fi` 2026-11-03.
- PoC: Foundry fork at Ethereum head ≈ 26,334,7xx; `vm.etch` of a 13-byte magic-revert contract; `vm.prank` fresh EOA. No mainnet state change.
- CA2 cross-check: 227 Roles + 46 Delay reachable, 1,071 tests, 0 permissive (`.work/promote/zodiac-roles.md`).

### Files

| File | Content |
|---|---|
| `analysis/roles_19m_28m.json` | 9,912 Roles v2.1.0 proxies (block, address) |
| `analysis/delay_19m_28m.json` | 136 Delay v1.1.0 proxies |
| `analysis/roles_avatars.json` | 6,683 proxy→avatar mappings |
| `analysis/roles_balances.json` | 5-token balances for those avatars |
| `analysis/roles_ranked.json` | Ranked avatars >$1k |
| `analysis/delay_bal.json` | Delay avatars, cooldowns, native balances |
| `analysis/delay_pending_txs.json` | The 3 live pending Delay txs and the GS104 replay |
| `analysis/sample.json` | The two reachable instances + the no-module/EOA-module counterexamples |
| `poc/test/*.t.sol` | 8 fork tests |
