# O6 — Nullmask (ZK privacy pool) · Base + Ethereum + BNB Chain

**Date:** 2026-10-25 · **Chains:** base, ethereum, bsc · **Mode:** READ-ONLY on real chains (no tx signed/sent; `eth_call` / `eth_getBalance` / `eth_getLogs` / `eth_getStorageAt` only). All exploit simulation runs on a local Foundry fork in CI. No secrets in this folder.
**Finding:** `O6` (pass6-recon OPEN; `base-bsc-fresh.md` row 4; prior wave PARKED as "addresses unresolved").
**Status:** addresses now resolved; contract is **verified on Etherscan/BscScan**; full source read; live auth probed; fork PoC run in CI.

---

## 1. TL;DR

| Target | Live value now | Unprivileged (E-U) extractable | Why closed | Latent risk |
|---|---|---|---|---|
| Nullmask pool (same CREATE2 proxy `0xd64EF141…` on 3 chains) | **≈ $163.4k** (ETH 20.989 + Base 11.833 + BSC 91.150 BNB + 2,427.88 USDT + 16,898.74 USDC + 173.78 USDT) | **$0** (high confidence) | Every value-moving entry point is either ZK-proof-gated against a real UltraHonk verifier, role-gated (guard/whitelist-manager/admin), or pays only the treasury. `initialize` is spent; the proxy's one-shot `setImplementationAndCall` is spent; UUPS upgrades are gated by `canUpgrade == (caller == admin)`. | **P-class:** the pool admin is a **2-of-3 Gnosis Safe v1.5.0** on all three chains; 2 keys can upgrade the impl and drain everything (~$163k). The `guard` and `whitelistManager` are EOAs (hot keys) — DoS / curation only, **cannot** move principal. |

**Headline E-U = $0, confidence HIGH.** The prior lane under-measured this target 5.6×: it reported "12.377 ETH ≈ $28.9k on Base (BSC side ≈ dust)". In reality the same pool is live on **Ethereum (20.99 ETH), Base (11.83 ETH) and BNB Chain (91.15 BNB)** with whitelisted USDT/USDC on top.

---

## 2. Total live extractable now

- **External-unprivileged (E-U): $0.00** — no stranger path moves value out (proof below).
- **Holder-only / self-service (H-O):** ≈ **$163.4k** nominal sits in the three pools as user notes + accrued protocol fees. The note owners can withdraw with their own ZK proofs (self-service); the accrued protocol fees are claimable only by the treasury (see `sweepProtocolFees`). We cannot enumerate individual notes, so H-O is bounded by the live balances.
- **Privileged (P):** ≈ **$163.4k** — the shared 2-of-3 admin Safe can upgrade all three pools to a hostile implementation (fork-proven, §7). The `guard` EOA can only approve/reject pending deposits and pause; the `whitelistManager` EOA can only curate the token list.
- **Stuck / bricked (S): $0** measured (any ERC-20 sent outside the whitelist would be unrecoverable — none found).

---

## 3. What the target actually is

Nullmask is a live, audited ZK privacy pool (Poseidon2 note commitments, UltraHonk/Noir proofs, UTXO notes, Uniswap-V2 shielded swaps, off-chain deposit screening). Public material: `nullmask.io`, `nullmask.io/compliance`, a 4irelabs audit dated Oct 2026 (score 9.5/10, 0 critical). The **proxy address is identical on every chain** (`CREATE2`, no constructor args): `0xd64EF1417EB047ed0b54736a5a41F01178C391c6`.

Contracts (all verified; source pulled from Etherscan V2 `getsourcecode`):

| Role | Address | Notes |
|---|---|---|
| Pool proxy (`NullmaskProxy`, ERC-1967, ~935 B) | `0xd64EF1417EB047ed0b54736a5a41F01178C391c6` | same address on ETH/Base/BSC |
| Implementation (Base) | `0xc763e8212e5c4143b8404c19f848c7d18e1ae5a1` | `Nullmask.sol` (1594 lines), solc 0.8.28, opt runs=0, cancun; `VIRTUAL_CHAIN_ID=43618`, router `0xBE6D8f0d…` |
| Implementation (Ethereum) | `0x8b5E7C7399A1b4C15D2ae9ee3cffF40a2468797b` | `VIRTUAL_CHAIN_ID=43615` |
| Implementation (BSC) | `0xecf4f3b3efc1454624bc524067257ff7c085bda1` | `VIRTUAL_CHAIN_ID=43619` |
| Upgrade controller (`AdminUpgradeController`) | `0xcD12496c9821075fD807c3488F3E0020715DED27` | same on all chains; `canUpgrade(caller,impl) = caller == admin` |
| Admin (Safe v1.5.0, 2-of-3) | `0xb2b1A7b415DBDf38308ba8206B0aED433Ed0706F` | owners `0x51429d3A…`, `0x7b7e20a8…`, `0x5fAC594f…` (same on ETH/Base/BSC) |
| Guard (deposit screener, EOA) | `0x0558E584846D1c913205c33588575CF5a20Bf856` | nonce 3503 — active hot key |
| Whitelist manager (EOA) | `0x51429d3A233579e7a46E3848E331dd0FD34674e0` | also Safe owner #1 |
| Treasury (EOA) | `0xDD85F4AfDE114dc7c480b012Feaa83152a0C0D09` | fee sink |
| Verifiers (UltraHonk, ~17.7 KB each) | `0x8eF11508…` (withdrawal, logN 17), `0x56eEFC4f…` (transfer, logN 18), `0xec5700f2…` (swap, logN 18) | same addresses on all chains |

---

## 4. Mechanism — every value path and its gate (exact terms)

Entry points that can move value (from the verified ABI, 76 functions):

| Function | Gate on a stranger | Result |
|---|---|---|
| `shieldedWithdrawal` | `_checkSpend`: `isKnownNoteTreeRoot(root)` must be true, `txNullifiers` unused, then **UltraHonk proof** over 38 public inputs (incl. `VIRTUAL_CHAIN_ID`, recipient, value, coinId) | reverts `InvalidNoteTreeRoot(0)` with root 0; with a real root + garbage proof the **verifier** reverts `ProofLengthWrongWithLogN(17,4,9152)` |
| `shieldedTransfer` | `_checkSpend` + `isKnownKeyRegistryRoot(rkRoot)` + proof (46 inputs) | reverts `InvalidKeyRegistryRoot(0)` |
| `shieldedSwap` | `_checkSpend` + deadline bound + `amountOutMin != 0` + proof (52 inputs) + `allowedRelayers(msg.sender)` inside the linked `NullmaskSwap` library | reverts |
| `sweepProtocolFees(token)` | **none** (permissionless) | **succeeds**, but sends `protocolFeesAccrued[token]` to `treasury` only; caller receives nothing |
| `deposit` / `depositTo` | recipient must have a registered receiving key; token whitelisted | creates a *pending* deposit; only the guard can credit it |
| `approveDeposit` / `rejectDeposit` / `pullDeposit` | `msg.sender == guard` | reverts `NotGuard(0x…dEaD)` |
| `withdrawPendingDeposit` | hash must match the original depositor (`msg.sender`) | reverts `DepositNotPending(0)` |
| `setGuard/setRelayer/setTreasury/setVerifiers/setWhitelistManager/setFeeConfig/setTokenParams/setDepositLimits/setWithdrawalsPaused/upgradeToAndCall` | `canUpgrade(msg.sender) == true` (admin Safe) | reverts `UpgradeNotAuthorized(0x…dEaD)` |
| `setTokenWhitelist` | whitelistManager or admin | reverts `NotWhitelistManager(0x…dEaD)` |
| `setPaused` | guard or admin | reverts `NotGuard(0x…dEaD)` |
| `setUpgradeController` | `msg.sender == upgradeController` contract | reverts `NotUpgradeController(0x…dEaD)` |
| `initialize` | OZ `initializer` | reverts `InvalidInitialization` |
| `setImplementationAndCall` (proxy) | one-shot; impl already set | reverts `ImplementationAlreadySet` |

Design notes that close the obvious classes:
- **No proof bypass:** the only "withdraw" is `shieldedWithdrawal`, which always verifies a proof against `shieldedWithdrawalVerifier` (a real Barretenberg/UltraHonk verifier — it reverts on a wrong-length proof, it does not return `true`). Note nullifiers and the tx nullifier are burned only after the proof passes, and are keyed so a proof can execute once.
- **No fee/denomination mismatch:** `depositFeeBps`/`withdrawalFeeBps` are hard-capped at `MAX_PROTOCOL_FEE_BPS = 100` (1%); accrued fees are always ≤ the pool balance; `sweepProtocolFees` can only pay the treasury.
- **No public rescue/sweep of principal:** `sweepProtocolFees` moves only the fee counter; there is no `rescue`, `emergencyWithdraw`, or owner-withdraw of notes.
- **No guard bypass:** the "Guard" is an off-chain EOA hot key (`0x0558E584…`, no code). It can only *credit or refund a pending deposit whose keccak hash binds (recipient, token, amount, depositor, escrow)* — it cannot redirect a deposit to itself, and it cannot mint notes.
- **No unprivileged upgrade:** `_authorizeUpgrade` → `canUpgrade(msg.sender, impl)` = `msg.sender == admin`; the admin is the 2-of-3 Safe. The proxy's bespoke `setImplementationAndCall` reverts once the impl slot is non-zero.
- **Reentrancy:** all value paths are `nonReentrant` (transient); ETH escrow refunds are bounded (`REFUND_GAS_STIPEND = 30_000`, no returndata copy).

---

## 5. Live-state assessment (explicit blocks)

Read 2026-10-25 at public RPCs. Prices: ETH $2,342.11 · BNB $735.59 (DefiLlama).

| Chain | Block | Native balance | ERC-20 held (whitelisted) | USD |
|---|---|---|---|---|
| Ethereum | 26,265,712 | 20.989369104531742494 ETH | 2,427.881303 USDT (`0xdAC17F…`) | **$51,589** |
| Base | 53,047,050 | 11.833087186316877752 ETH | 16,898.743946 USDC (`0x833589…`) | **$44,613** |
| BNB Chain | 129,599,507 | 91.149893711770472317 BNB | 173.779312688240182312 USDT (`0x55d398…`) | **$67,223** |
| **Total** | | | | **≈ $163,425** |

Other state (all three pools, verified on-chain):
- `paused = false`, `withdrawalsPaused = false` on all chains; `depositFeeBps = withdrawalFeeBps = 50` (0.5%); `guard`, `upgradeController`, `treasury`, verifier addresses identical on all chains.
- `protocolFeesAccrued(ETH)`: Base ≈ 0.32 ETH, BSC ≈ 2.93 BNB, ETH ≈ 0.121 ETH (already the treasury's; permissionless to sweep).
- Note trees are populated and **actively growing**: Base `noteTreeSize ≈ 11.3k` / `keyRegistrySize ≈ 2.4k`; ETH 18,192 / 4,004; BSC 12,276 / 3,249. In a 5,000-block Base window there were **29 `DepositPending` and 93 `NoteAdded`** events → the pool is live, not abandoned.
- The proxy's EIP-1967 implementation slot resolves to the verified `Nullmask` on every chain; the EIP-1967 admin slot is `0` (admin is the `AdminUpgradeController`, not a slot).
- **Reconciliation of the brief's "12.377 ETH":** that figure is the *Base* pool only, at pass6's block 53,043,770 (we re-read 12.377716451919897763 ETH there — exact match). The balance drifts block-to-block as users deposit/withdraw (we saw 11.62–12.79 ETH over a few hundred Base blocks). The brief's "BSC side ≈ dust" is **wrong**: BSC holds ~91 BNB.

---

## 6. What an attacker can / cannot do

**Cannot (proven):** withdraw, transfer, or swap value out; approve/reject/credit a deposit; pause/unpause; set any parameter; change guard/relayer/verifier/treasury/controller; upgrade the implementation; re-initialize; call the one-shot proxy setter; reclaim someone else's pending deposit. Every one of these reverts for `0x…dEaD` with the specific access-control error (see §7 and `analysis/probe_auth.out`).

**Can (harmless):** call `sweepProtocolFees(token)` — it pays the treasury, not the caller; register their own receiving key (preimage to their own address) and deposit their own funds; submit a fee-less shielded operation for *someone else's* already-signed proof (the recipient is bound in the proof, so this only executes the owner's own withdrawal early — no theft).

**Cost/preconditions for the only theoretical drains:** none available to an unprivileged actor at any capital level — there is no missing check to buy, no oracle to move, no proof to forge (the verifier is real and proof-bound).

**P-class path (privileged, not E-U):** two of the three Safe owners sign a Safe transaction that calls `AdminUpgradeController.execute(pool, upgradeToAndCall(hostileImpl, ""))` (or the Safe calls the pool directly) → the proxy points at the hostile impl → drain native + whitelisted ERC-20. Fork-proven in CI.

---

## 7. PoC / fork verification

`poc/` — Foundry project (vendored `forge-std`), forks Base at the live head via `BASE_RPC_URL` (keyless fallback `https://base-rpc.publicnode.com`), fresh unprivileged EOA `0x…dEaD`, **no impersonation for any E-U test**.

| Test | Asserts |
|---|---|
| `test_live_state_snapshot` | guard/controller/treasury/verifier addresses; `VIRTUAL_CHAIN_ID == 43618`; pool holds ETH; tree > 10k; native token whitelisted |
| `test_privileged_selectors_revert_for_fresh_eoa` | 15 setters revert with `UpgradeNotAuthorized` / `NotUpgradeController` / `NotGuard` / `NotWhitelistManager` |
| `test_initialize_cannot_be_recalled` | `InvalidInitialization` |
| `test_withdraw_pending_deposit_is_depositor_scoped` | `DepositNotPending(0)` |
| `test_deposit_without_receiving_key_reverts` | `ReceivingKeyNotFound` |
| `test_register_receiving_key_requires_address_preimage` | `NotAccountOwner` |
| `test_shielded_withdrawal_requires_known_root` | `InvalidNoteTreeRoot(0)` |
| `test_shielded_withdrawal_requires_valid_proof` | reverts (UltraHonk verifier rejects a garbage proof) |
| `test_shielded_transfer_requires_known_key_root` | `InvalidKeyRegistryRoot(0)` |
| `test_verifiers_reject_garbage_proofs` | all three verifiers revert on a 4-byte proof |
| `test_sweep_protocol_fees_only_pays_treasury` | treasury +accrued, caller +0 |
| `test_proxy_implementation_is_locked` | `ImplementationAlreadySet` |
| `test_controller_admin_is_2of3_safe_and_gates_upgrades` | admin == Safe; `canUpgrade(Safe)==true`, `canUpgrade(fresh)==false`; threshold 2, 3 owners |
| `test_P_class_safe_can_upgrade_and_drain_all_chains_local` | **P-class only:** with `vm.prank(Safe)`, `upgradeToAndCall(hostileImpl)` succeeds and the hostile impl drains the pool's ETH + USDC |

CI run URL(s): **<see §9 / `summary.json`>** — GitHub Actions `artsbykriss/ca-zombie-ci`, workflow `poc.yml`, branch `nullmask`. `ci/run.sh` additionally writes `ci-out/state.json` (cross-chain snapshot) and `ci-out/integrity.json` (source↔deployed-bytecode check for the Base impl).

---

## 8. Verdict, residual & latent risk, blockers

**Verdict: E-U = $0 (HIGH confidence).** The Nullmask pools are a correct, audited implementation of the shielded-pool pattern; every value-moving path is proof- or role-gated, and the deployed code is the verified source. There is no unprivileged path to any of the ~$163.4k.

**Residual / latent risk (not E-U):**
- **P (≈ $163.4k, medium confidence):** a shared **2-of-3 Gnosis Safe** on all three chains is the sole admin; 2 compromised keys drain every pool. This is the single largest risk on the target.
- **Guard hot key (`0x0558E584…`, EOA):** compromise ⇒ griefing only (pause, approve/reject pending deposits, keep bounded check/gas fees). Cannot move principal.
- **Cross-chain concentration:** one Safe + one controller govern ETH, Base and BSC simultaneously.
- **Zk-layer:** correctness of the Noir circuits is out of scope of an on-chain read; the verifiers are real, but a circuit soundness bug would be invisible here.

**Blockers / caveats:** the Robinhood-Chain (4663) deployment referenced in Nullmask's own materials could not be read (TLS failure on the public RPC) — it is not in our $163.4k total and was not analysed; the 4irelabs audit PDF (`nullmask-io/audits`) now 404s, so its two "Major" items (7.1.10, 7.1.12) could not be read (the in-code comments show many audit items remediated). Point-in-time 2026-10-25; re-read live state before acting. Nothing here is an instruction to transact.

---

## 9. Methodology, sources, caveats, files

**Method.** Resolved the proxy (EIP-1967 impl slot `0xc763e821…`), pulled all verified sources via Etherscan V2 `getsourcecode` (chainid 1/56/8453), decompiled with `heimdall` + `evmole`, read the full `Nullmask.sol`/`State.sol`/`NullmaskSwap.sol`/`AdminUpgradeController.sol`, then probed every mutating selector from a fresh EOA with `eth_call` (no tx) and simulated the shielded ops with hand-built calldata (`eth_abi`). Live balances via keyless public RPCs. Fork PoC in CI.

**Key on-chain evidence (address + block + call).**
- Base pool impl: `eth_getStorageAt(0xd64EF141…, 0x360894a1…bcc)` = `0xc763e8212e5c4143b8404c19f848c7d18e1ae5a1` (verified `Nullmask`).
- Admin: `AdminUpgradeController(0xcD12496c…).admin()` = `0xb2b1A7b4…`; `getThreshold()==2`; `getOwners()==[0x51429d3A…,0x7b7e20a8…,0x5fAC594f…]`; `VERSION()=="1.5.0"` (same on ETH/Base/BSC).
- `canUpgrade(0x…dEaD, 0) == false`; `canUpgrade(Safe, 0) == true`.
- `initialize(5 addresses)` from `0x…dEaD` → revert `InvalidInitialization` (`0xf92ee8a9`).
- `setGuard` etc. from `0x…dEaD` → revert `UpgradeNotAuthorized(0x…dEaD)`; `approveDeposit` → `NotGuard(0x…dEaD)`; `setTokenWhitelist` → `NotWhitelistManager(0x…dEaD)`.
- `shieldedWithdrawal(zeroStruct, 0x)` → revert `InvalidNoteTreeRoot(0x00…)`; with the live root + `0xdeadbeef` → verifier revert `ProofLengthWrongWithLogN(17,4,9152)`.
- `sweepProtocolFees(address(0))` from `0x…dEaD` → **succeeds**; `treasury()` = `0xDD85F4Af…`.
- Balances/blocks per §5.

**Sources.** Etherscan V2 `getsourcecode`; keyless public RPCs (publicnode); DefiLlama prices; Nullmask docs/compliance; 4irelabs audit (via search excerpt; PDF now 404).

**Caveats & limitations.** (1) Robinhood-Chain deployment unread (RPC TLS). (2) Audit PDF unavailable. (3) H-O value is bounded by pool balances, not enumerated per-note. (4) Point-in-time. (5) The vendored `forge-std` ships its own public Sepolia placeholder URL in `StdChains.sol` — not a secret of ours.

**Files.**
- `README.md` (this), `summary.json`
- `analysis/` — `probe_auth.sh`+`.out` (15 selectors from a fresh EOA), `probe_shielded.py`+`.out` (hand-built shielded calldata), `impl_decompiled.txt`, `bytecode/`, `src/{impl,proxy,controller}/` (verified sources)
- `poc/` — `foundry.toml`, `src/{INullmask,MaliciousImpl}.sol`, `test/Nullmask.t.sol`, `lib/forge-std`
- `ci/` — `run.sh`, `snapshot.py`, `integrity.py`; `ci-out/` — `state.json`, `integrity.json`; `ci-log.txt`, `ci-artifacts/`
