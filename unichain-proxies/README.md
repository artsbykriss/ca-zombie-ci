# Unichain `ImmutableProxy` family (×130, ZH4-PASS6 residual **O8**) — deep dive

**Date:** 2026-10-25 · **Chain:** Unichain (chain id 130) · **Status:** read-only; PoC fork-verified only; **no mainnet transaction signed or broadcast**.

**Verdict: live extractable by an external unprivileged attacker = $0 (high confidence).**
The family is the **Eco Protocol (ERC-7683 intent) escrow** system: 299 verified `ImmutableProxy`
clones, each a minimal `Proxy` delegatecalling a `Vault` implementation. Every clone is **empty today**
(0 USDC, 0 native), every value-moving entry point is `onlyPortal`, and the Portal's value paths are
hash-bound to the intent creator / prover-recorded claimant. The recon's "**~$130k across ~130 clones**"
is a **stale Blockscout `/token-balances` artifact** (the index still reports pre-settlement snapshots).

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why closed | Latent risk |
|---|---|---|---|
| 299 `ImmutableProxy` clones (Eco intent vaults) | **$0** | all clones empty; `withdraw/refund/recover/fundFor` are `onlyPortal` → `NotPortalCaller`; Portal pays hash-bound recipients | none found |

## 2. Total live extractable now: **$0** — confidence **high**

Categories: **E-U $0** · **H-O $0** · **P $0** · **S $0**.

## 3. The mechanism, in exact terms

- **Proxy (`ImmutableProxy`)** — minimal proxy; runtime is
  `60806040523615604957366000803760008036817f<impl>5af43d6000803e156044573d6000f35b3d6000fd5b00`
  (75 bytes). `receive()` accepts native; `fallback()` `delegatecall`s the embedded `impl` (byte offset 33).
- **`Vault` impl (verified, `0x3fd339E58769a56D08dcd2683F9012E881287476`)** — `contracts/vault/Vault.sol`.
  `portal` is an **immutable set in the impl's constructor** (`portal = msg.sender`), i.e. the impl's
  **deployer**. Because immutables are baked into the impl's runtime code, **all clones share the same
  `portal`**. Every value function carries `modifier onlyPortal { if (msg.sender != portal) revert NotPortalCaller(msg.sender); }`.
  There is **no initializer / no unguarded setter** (the "unguarded init" class does not apply — the
  proxy has no init and the impl has no mutable authority).
- **Portal (`IntentSource`)** — `withdraw(destination, routeHash, reward)` is permissionless but sets
  `claimant = IProver(reward.prover).provenIntents(intentHash).claimant`; `refund` pays `reward.creator`;
  `refundTo` requires `msg.sender == reward.creator`; `recoverToken` pays `reward.creator`.
  `intentHash = keccak(abi.encodePacked(destination, routeHash, keccak(abi.encode(reward))))`, and the
  vault is `CREATE2(portal, salt=intentHash, initCode)`. **Tampering with any reward field (e.g. `prover`)
  changes the intentHash ⇒ a different, empty vault.**

## 4. Live-state assessment (all read on-chain, block 62191907 / 2026-10-25 14:57 UTC)

| Item | Value | Source |
|---|---|---|
| Named `ImmutableProxy` clones (Blockscout verified-name) | **299** | Blockscout `/smart-contracts?q=ImmutableProxy` |
| impls used | `0x3fd339…` (295), `0x204d732e…` (2), `0x9f70b0c8…` (2) | `constructor_args` / runtime byte offset 33 |
| `verified_at = 2026-10-16` (the finding's "~130") | **141** | Blockscout |
| USDC held by the 299 clones | **0.0 USDC** (all 299) | `balanceOf` via 4 independent RPCs |
| native held by the 299 clones | **0 wei** (all 299) | `eth_getBalance` |
| Portal of impl `0x3fd339…` | `0x399Dbd5DF04f83103F77A58cBa2B7c4d3cdede97` (embedded immutable + deployer) | runtime bytecode |
| Portal of impl `0x9f70b0c8…` | `0xEC000064576f9C95a8623Bc0eff3db6d296ea6df` | runtime bytecode |
| Portal of impl `0x204d732e…` | `0xEC000769A73b70e16f361a442292500b3BCf4A85` | runtime bytecode |
| `0x399Dbd5D` last activity | block 52,898,784 (2026-07-10) — **inactive** | Blockscout logs |
| `0xEC000064` last activity | block 60,029,342 (2026-09-30) — **inactive** | Blockscout logs |
| `0xEC000769` | **active** but migrated to a **different (non-`ImmutableProxy`) vault design** | live tx inspection |
| funded intents minus settled (portals `0x399Dbd5D`, `0xEC000064`) | **0 / 0** | IntentFunded ∖ (IntentWithdrawn ∪ IntentRefunded) |
| Blockscout `/token-balances` (stale) sum over 166 clones | **$271,684.77** | Blockscout (contradicted by RPC) |

**Staleness proof (clone `0x08A4955Fd5c06956B2D03A713627a2040d1c199a`):** created at block **42,591,324**
(2026-03-12), received 4,961.10 USDC at block 42,591,188 and sent 4,961.10 USDC out in the **same block**
as creation; last transfer = **OUT**. Live `balanceOf` = **0** on `mainnet.unichain.org`,
`unichain-rpc.publicnode.com`, `unichain.drpc.org`; yet Blockscout `/token-balances` still reports
`4,961,103,879`. The "funded" rows in the recon are exactly these stale snapshots — the clones have been
empty since March–June 2026.

## 5. What an attacker can / cannot do

**Cannot (all proven on a Unichain fork, 7/7 tests):**
- Call `withdraw`, `refund`, `recover`, `fundFor` on any clone from a fresh EOA → reverts
  `NotPortalCaller(attacker)` (`0x407c71ac`) for **all three impl families**.
- Redirect a withdrawal: `Portal.withdraw` pays the prover-recorded claimant; `refund`/`recoverToken`
  pay `reward.creator`; `refundTo` is creator-only.
- Forge a cheap drain by swapping `reward.prover`: changing any reward field changes the intentHash and
  therefore the vault address → the attacker only ever touches a freshly deployed empty vault.

**Preconditions/costs:** none reachable; the only theoretical cost would be gas on a call that reverts.
No flash loan or capital helps because the recipient is fixed by the intent hash.

## 6. PoC / fork verification

- **Files:** `poc/test/UnichainVaultPoC.t.sol` (Foundry, forks Unichain mainnet, read-only).
- **Result:** **7 / 7 PASS** — `test_clones_are_immutable_proxies`, `test_guard_main_impl`,
  `test_guard_9f70_impl`, `test_guard_204d_impl`, `test_clones_currently_empty`,
  `test_only_portal_can_move_funds`, `test_tampered_reward_yields_different_vault`.
- **CI (GitHub Actions, public repo `artsbykriss/ca-zombie-ci`):**
  - run: **https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40204644262** (success)
  - custom job re-scanned all 299 clones at block 62191907 → `n_clones=299, funded=0, total_usdc=0.0`
    (`ci-out/immutableproxy_scan.json`).
- Key numbers: guard revert gas ≈ 116k each; simulated funded-vault withdraw (impersonating the portal)
  moves 5,000 USDC to the chosen recipient — proving only the portal can move value.

## 7. Verdict, residual / latent risk, blockers

- **Verdict:** external-unprivileged extraction = **$0**. The design is sound: portal-gated vaults,
  hash-bound recipients, no uninitialized authority, no reentrancy-relevant ordering gap
  (status is set before the external call in `withdraw`/`_refund`).
- **Residual/latent:** the system **is** used (the newer portal `0xEC000769` settles intents within
  minutes), so vaults transiently hold value — but that value is only ever claimable by the intent's
  prover-recorded claimant or its creator. **No** window was found in which a stranger could take it.
- **Blockers to any "recovery" claim:** none, because there is no stuck value: `funded ∖ settled = 0`.

## 8. Methodology & sources; caveats; files

- Enumeration: Blockscout verified-name search `ImmutableProxy` (299) + `IntentPublished`/`IntentFunded`
  event logs (11,347 intents) for the two `ImmutableProxy`-creating portals.
- Balances/roles/immutables: direct `eth_call`/`eth_getCode`/`eth_getBalance` at pinned blocks
  (62182697, 62190582, 62191907) via 4 RPCs; impl sources from Blockscout (Vault verified) and
  `heimdall` selector extraction for the two unverified impls.
- **Caveats:** Blockscout `/token-balances` is unreliable here (stale) — **always** use RPC `balanceOf`;
  the two non-`0x3fd339` impls are unverified, so gating was confirmed by **live probe + bytecode**, not
  source. Amounts/state are point-in-time (block 62191907).
- **Files:** `analysis/` (live_rescan.py, live_rescan.json, token_balances_now.{py,json},
  impls/*.hex, immutableproxy_clone.json, prover_src/ Vault+IntentSource), `children/` (raw enumeration),
  `poc/` (Foundry), `ci/` (run.sh + scan_clones.py), `ci-out/`, `ci-log.txt`, `summary.json`.
