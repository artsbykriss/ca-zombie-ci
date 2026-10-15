# Z3-C5 · EtherVista (Ethereum) — deep-dive: live-extractability of the `uint112` K-overflow pair

- **Date:** 2026-10-16 · **Campaign:** zombie-hunt-iii · **Chains:** Ethereum mainnet
- **Status:** read-only research; **PoC fork-verified only; no mainnet transactions, no keys used**
- **Canonical state block:** `26,201,112` (fleet scan) / `26,201,164` (extra checks) — 2026-10-15/16
- **Targets:**
  - Pair `0xfdd05552F1377aA488AFed744c8024358AF02041` (WETH/VISTA, verified `EtherVistaPair`, solc 0.5.16, immutable)
  - Factory `0x9a27cb5ae0B2cEe0bb71f9A85C0D60f3920757B4` (1,087 pairs, verified, immutable)
  - Live router `0x9bD63C5D44fF28390df1EaaFD4eB4BD73E94A72a` (`EtherVistaRouter`, verified, solc 0.6.6)
  - `routerSetter` EOA `0xCA90D843288E35beeADfCe14E5F906e3F1AFc7cB` (no code; not EIP-7702-delegated)

## 1. TL;DR

| Question | Answer |
|---|---|
| Can an external unprivileged attacker drain the pair **now**? | **No — $0.00.** The only swap gate is `require(msg.sender == factory.router(), 'EtherVistaPair: FORBIDDEN')` and `factory.router()` is the verified official router, whose every swap entry point derives outputs from `UniswapV2Library.getAmountOut` (no arbitrary-`amountOut` path). Direct crafted swaps revert; `skim()`/`claimShare()`/`sync()` yield nothing (T1–T3, T5, T7). |
| Fleet-wide live E-U (all 1,087 pairs)? | **$0.0007** — exactly one pair (`0xf6f275d6…`, UNI/WETH) carries 0.0001 UNI of skim-able excess; everything else is zero excess (full-fleet scan). |
| Latent, key-gated (P): one hostile-router swap | **$69,183.66** net on the target pair, single call, 1 wei capital (T4 + T6). Leaves **$3.75** residue. The `uint112` K-wrap is real, reachable **through a router change alone**, and present in **713 / 1,087** pairs. |
| Fleet-wide latent (P), all 713 overflowing pairs | **≈ $317,796.91** best-strategy (116.155 WETH ≈ $283,341 WETH-max floor + valuable token sides); target pair = 21.8% of it. Every pair is a WETH pair; a single `setRouter` exposes all of them at once. |
| Incident | 2026-10-09: `routerSetter` set the router to attacker contract `0x469424b6…`; **exactly one pair** drained (net 7.477952467865157795 WETH + 43,855.902196275763910451 VISTA); restored 180 s later. The key was **never rotated** and the same EOA still holds `routerSetter` + router treasury today. |

**Total live extractable now (E-U): $0.00** (target pair $0.00; fleet $0.0007 dust) — confidence **high** (bytecode-verified, fork-proven, full-fleet scan).
**Latent key-gated (P): $69,183.66** on the target pair in one call; **≈$317.8k fleet-wide** (713 overflowing pairs; 116.16 WETH price-free floor + token sides) — confidence **high** for the target pair and the mechanism, **high** for the WETH floor, **medium** for the full fleet USD total (707 overflowing pairs are unpriced long-tail tokens).

## 2. The bug in exact terms (deployed code)

Verified source `EtherVistaPair.sol` (solc 0.5.16, optimizer on/runs 200), deployed code confirmed byte-identical except metadata (§4):

```solidity
// swap(), line 611-638 — the only gate is line 612
function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
    require(msg.sender == IEtherVistaFactory(factory).router(), 'EtherVistaPair: FORBIDDEN');   // 612
    require(amount0Out > 0 || amount1Out > 0, 'EtherVistaPair: INSUFFICIENT_OUTPUT_AMOUNT');
    (uint112 _reserve0, uint112 _reserve1,) = getReserves();
    require(amount0Out < _reserve0 && amount1Out < _reserve1, 'EtherVista: INSUFFICIENT_LIQUIDITY');
    ...
    require(balance0 * balance1 >= reserve0 * reserve1, "K");                                    // 633  <-- BUG
    _update(balance0, balance1, _reserve0, _reserve1);
}
```

- `reserve0`/`reserve1` are **`uint112`**. In solc 0.5.x the RHS product is evaluated in `uint112` and **wraps silently mod 2^112** (no SafeMath on operators). LHS `balance0 * balance1` is `uint256`.
- Live reserves (block 26,201,112): `r0 = 14,247,866,353,266,560,006` (14.247866353266560006 WETH), `r1 = 79,387,393,606,187,717,449,441` (79,387.393606187717449441 VISTA).
  `r0·r1 = 1.131101e42 > 2^112 = 5.192297e33` → RHS = `(r0·r1) mod 2^112 = 3,325,673,296,127,612,471,558,109,650,752,838` (3.3257e33). **The K check is inert.**
- **Reachability (precise):** a caller with `msg.sender == factory.router()` calls `swap(amount0Out, amount1Out, to, "")` with any amounts satisfying `amount0Out < reserve0`, `amount1Out < reserve1`, and ≥1 wei of input (e.g. 1 wei WETH), and any post-balances with `balance0·balance1 ≥ 3.3257e33`. The value-optimal drain leaves the min-value point of that hyperbola: `b0 = √(K·P1/P0) = 0.000774612923074342 WETH`, `b1 = √(K·P0/P1) = 4.293335673936902630 VISTA` ≈ **$3.75 residue** (prices: WETH $2,439.32, VISTA $0.433724 — DefiLlama, 2026-10-15).
- **Self-healing after one call:** post-drain reserves are `(0.0007746…, 4.2933…)`, product `3.3257e33 < 2^112`, so the K check is valid again and the dust cannot be taken without paying (test T9).
- Everything else on the pair is gated: `first_mint/mint/burn/updateProvider/fallback` (router), `transferFrom/approve/permit` (router), fee/protocol/metadata/renounce (`creator`). `skim()` is permissionless but moves only `balance − reserve` excess (**0** on the target pair). `claimShare()` is permissionless but pays only stored provider snapshots (non-provider gets 0).

## 3. Bytecode vs verified source (rigorous diff)

Files: `analysis/bytecode_diff.py`, `analysis/bytecode_diff.json`, `analysis/verified_{pair,router,factory}.json`, `analysis/pair_creation_deployed.hex`, `analysis/pair_runtime.hex`, `analysis/factory_runtime.hex`.

| Contract | Verified source (Etherscan) | Result |
|---|---|---|
| Pair `0xfdd05552…` | `EtherVistaPair`, solc 0.5.16, opt. 200 | **Executable code byte-identical** (17,880 B). 31 diff bytes — all inside the 50-byte CBOR metadata `bzzr1` source-hash field (Etherscan text normalisation); zero unclassified. |
| Router `0x9bD63C5D…` | `EtherVistaRouter`, solc 0.6.6, opt. 200 | **Byte-identical including metadata.** 920 diff bytes = 46 × 20-byte **immutable slots** (25× factory address, 21× WETH address) filled at construction; zero unclassified. ⇒ the live gate is exactly the verified source. |
| Factory `0x9a27cb5b…` | `EtherVistaFactory`, solc 0.5.16, opt. 200 | Executable code identical; 63 diff bytes = own metadata (32 B) + embedded pair-creation-code metadata (31 B); zero unclassified. |

Pair-specific proofs (independent of source text):
1. **Deployed creation code extracted from the factory runtime** (offset 2,194): `keccak256(creation) == factory.INIT_CODE_HASH() == 0xe260b72768e8ec6814aa811c576f346d208ba00840f835949d65c6424ac80a8d` ✓ (extraction self-validating).
2. **Embedded runtime == on-chain pair runtime** (17,932 B, offset 691) ✓.
3. **CREATE2 re-derivation**: `keccak(0xff ‖ factory ‖ keccak(token0‖token1) ‖ init_code_hash)[12:] == 0xfdd05552F1377aA488AFed744c8024358AF02041` ✓.
4. `keccak256(pair runtime) = 0x1521aa2ef47949e66e97249a63806f6d2ccf544fcf1ce406b2f12844ce5abb01` (asserted in test T8).

⇒ The deployed pair is exactly the verified `EtherVistaPair` (the K-wrap is genuine deployed logic, not a decompiler artefact), and the live router is exactly the verified `EtherVistaRouter` (no hidden arbitrary-`amountOut` function).

## 4. Live-state assessment (all reads on-chain, cited)

| Item | Value (block 26,201,112 / 26,201,164) |
|---|---|
| `factory.router()` | `0x9bD63C5D44fF28390df1EaaFD4eB4BD73E94A72a` — verified `EtherVistaRouter`, code 16,543 B, byte-identical to source |
| `factory.routerSetter()` | `0xCA90D843288E35beeADfCe14E5F906e3F1AFc7cB` — **EOA**, code 0 B (no EIP-7702), nonce 657, balance 0.001615912524873591 ETH |
| `factory.feeTo / feeToSetter` | `0x0 / 0x0` — permanently locked (`setFeeToSetter` unreachable) |
| `factory.allPairsLength` | **1,087** (all enumerated; unique = 1,087; all `factory()` bindings = the canonical factory; **1 distinct pair code hash** across the fleet) |
| Pair reserves / balances | `14.247866353266560006` WETH / `79,387.393606187717449441` VISTA — balances equal reserves exactly (`skim` excess = 0) |
| Pair ETH pot (`poolBalance`) | `0.606719450477681318` ETH (≈$1,479.94) — `claimShare()` pro-rata to provider snapshots only |
| Pair LP supply | `1,636.203551475290054082` LP: **1,500.0 LP (91.6756%) burned to `0xdEaD` on 2024-09-02** by the deployer EOA; 0.6072 LP with the EOA; ≈135.6 LP with other users; 1,000 wei locked at `0x0`; pair self-LP = 0 |
| `Providers(0xdEaD)` | `(0, 0)` — the burned LP has **no** claim on the ETH pot |
| Router leftovers | WETH 0, VISTA 0, ETH 8 wei → the router's "sweep full balance" paths pay nothing today |
| Router treasury | `treasury = treasurySetter = 0xCA90D843…` (same EOA), `treasuryFeeUsd = $1` per routed swap |
| VISTA token | `0xC9bCa88B…`, verified; its `approve()` is router-gated (that is why the Oct 9 attacker approved VISTA *after* hijacking the router) |
| Fleet (1,087 pairs) | **713 pairs with `r0·r1 > 2^112`**; 1 pair with skim excess (0.0001 UNI ≈ $0.0007); priced value $70,143.55 (target pair = $69,187.41 = 98.6%); WETH held by all pairs **118.049294 WETH** (overflow pairs 116.218262 WETH; WETH-max one-call drain 116.155449 WETH ≈ $283,340.78) |

## 5. What an attacker can / cannot do

### 5.1 E-U (external unprivileged) — closed
1. `pair.swap(amount0Out, amount1Out, …)` from any non-router address → **reverts `EtherVistaPair: FORBIDDEN`** (T1; both directions).
2. Via the **official router**: `swapExactETHForTokensSupportingFeeOnTransferTokens` / `swapExactTokensForETHSupportingFeeOnTransferTokens` compute `amountInput = balanceOf(pair) − reserveInput` and `amountOutput = getAmountOut(...)`; there is **no function that forwards a caller-chosen `amountOut`** (full source audited; test T7 proves output ≤ `getAmountOut`). The router also refuses `path.length != 2` and requires WETH at one end.
3. `skim(to)` → 0 (balances == reserves; T2). Fleet: one pair with $0.0007 of excess — the *only* live E-U in the entire fleet.
4. `claimShare()` from a non-provider → 0 ETH (T3); provider claims are their own value (H-O).
5. `sync()` / `transfer(0xdEaD)` → state/own-balance only.
6. **Authority closed:** `setRouter` / `setRouterSetter` revert for anyone except the `routerSetter` EOA — including for the official router itself (T5). No signature-based path; `feeToSetter` is 0x0; `createPair` cannot influence `router`.

### 5.2 P (key-gated latent) — the live weapon
Preconditions: **(a)** `factory.router()` is changed to a hostile contract — requires the `routerSetter` key (one tx); **(b)** the pair has `r0·r1 > 2^112` (target: yes; 713/1,087 pairs: yes). Cost: ~250–350 k gas + 1 wei; no flash loan, no capital. Result: **one** `swap()` takes `14.247091740343487 WETH + 79,383.100270513780 VISTA` (T4, fork-proven), net **$69,183.66**, leaving $3.75. The hostile router can also drain every other overflowing pair in the same window; the fleet-wide priced total is **$69,258.64**, and 707 further overflowing pairs hold unpriced long-tail tokens (mostly dust).

### 5.3 H-O (holder-only) and S (stuck)
- **H-O:** live LP holders can redeem through the official router (`removeLiquidityETHSupportingFeeOnTransferTokens`): their share is `135.5963 + 0.6072 = 136.2036 LP / 1,636.2036 = 8.3244%` of the pool ≈ **$5,759.6**; plus provider `claimShare()` on the 0.6067 ETH pot (≈ **$1,479.9**, pro-rata; the burned LP has no claim). Total H-O ≈ **$7,239.5**.
- **S:** the 1,500 burned LP (91.6756%) can never be redeemed — `0xdEaD` cannot call the router, and the router cannot move its LP (`allowance[0xdEaD][router] = 0` → SafeMath underflow in `transferFrom`). Its pro-rata backing ≈ **$63,427.8** is unredeemable under normal operation (but is captured by any hostile-router drain).

### 5.4 Fleet latent — full 1,087-pair audit (`analysis/pairs.csv`, `ci-out/fleet_scan.json`)
- Router binding is **factory-global**: every pair reads `factory.router()` at call time, so a single `setRouter` exposes all 1,087 pairs simultaneously. No pair has its own router binding; no pair's `factory()` differs from the canonical factory; all 1,087 have identical bytecode (1 code hash).
- **Every pair is a WETH pair** (the factory only creates token/WETH pairs). 713/1,087 pairs overflow `uint112`.
- **WETH-max one-call drain** (keep the other side at reserve, shrink the WETH side to `ceil(Kwrap / other_reserve)`): feasible for all 713 overflowing pairs; total **116.155449 WETH ≈ $283,340.78** (price-free floor). Verified against direct reads on sample pairs (e.g. `0xc4f08200…` 5.886325 WETH, `0xd426817f…` 4.940011 WETH, `0x3924908e…` 3.140643 WETH).
- Balanced min-value drain (needs prices): $69,258.64 total, of which the target pair is $69,183.66 (99.9%); the only other priced overflowing pair is `0x2625f076…` ($63.25).
- **Best-strategy fleet latent** (attacker takes `max(WETH-max, balanced)` per pair): **≈ $317,796.91**. Target pair = 21.8%; the remaining ~$248.6k sits in 712 long-tail pairs whose WETH side is real even though their memecoin side is unpriced.
- Skim-able excess fleet-wide: **$0.0007** (one pair). Pair self-LP: 0. Pairs with `factory()` mismatch: 0.

## 6. Incident forensics (2026-10-09) — and why the weapon is still loaded

| UTC | Event (all on-chain) |
|---|---|
| 03:37:59 | Burner EOA `0xbbf8f3fe8e4fdf6b594e6107144d78293d2018fa` funded with 0.046448 ETH from `0x963737C550E70FFe4D59464542a28604eDb2eF9a` (Etherscan label "Union Chain") |
| 03:42:23 | Burner deploys helper router `0x469424b628a9d2036e41496e814db500d683b120` (nonce 0) |
| 03:43:59 | Burner makes a 0.004008 ETH test buy **through the official router** |
| 03:46:11 | **`routerSetter` EOA calls `setRouter(0x469424b6…)`** (tx `0xc97ad886…`, block 26,152,250) |
| 03:47:11 | Burner approves VISTA (possible only because it now controls the router gate) |
| 03:47:59 | Drain tx `0xb2c7332d…` (block 26,152,259): pair → attacker 21.365578479614736555 WETH, back 13.887626011749578, net **7.477952467865157795 WETH**; pair → attacker **43,855.902196275763910451 VISTA**. **Exactly one pair** touched; the helper router received exactly one call in its lifetime |
| 03:49:11 | `routerSetter` EOA restores the official router (tx `0x7adfb703…`) |
| after | VISTA burned to `0xdEaD`; WETH→ETH→18,590.72 USDC; 11,000 USDC parked at `0x043c8f2d…` (still there), 7,590.72 USDC left in the burner. No mixer/CEX |
| 2026-10-13 | Last outbound tx of the `routerSetter` EOA (nonce 656) |

- All **17** `setRouter` calls in history come from the same EOA; `setRouterSetter` was **never** called (before or after the incident). The EOA's ±24 h around the attack contains **only** the two `setRouter` txs — no interaction with either attacker address.
- The pool today is the **post-attack state** (no `Mint`/`Burn` since block 26,150,000): the attacker left the pool **still overflowing** (`r0·r1 > 2^112`), i.e. **100% re-drainable** the moment the router flips again.
- Public record (research sub-report): SlowMist flagged the incident (uint112 overflow; attacker registered as authorized router); **no team/Arctide statement, no key-compromise claim, no fund return, no post-mortem**; the `routerSetter` key was never rotated or handed to a multisig; the team is anonymous; Etherscan labels the EOA "Ethervista: Deployer"; Arctide acquired "Ethervista's technology" on 2026-09-16 but no public statement exists on key custody. Attribution of the Oct 9 authority use (compromise vs insider) **remains unresolved** from public data; on-chain, the key holder executed both the hostile set and the restore.

## 7. PoC / fork verification

Project `poc/` (Foundry; forge-std vendored). Fork: pinned block `26,199,454` via `FORK_RPC_URL`.

| Test | Result | Key numbers |
|---|---|---|
| T1 `unprivilegedSwapBlocked` | PASS | direct crafted `swap()` reverts `EtherVistaPair: FORBIDDEN` |
| T2 `noSkimExcess` | PASS | balances == reserves; `skim` moves 0 |
| T3 `claimShareZeroForNonProvider` | PASS | non-provider gets 0 ETH; `poolBalance = 0.606719 ETH` |
| T4 `LATENT_hostileRouterDrains` | PASS | one swap: **14.247091740343487 WETH + 79,383.100270513780 VISTA**, leaves 0.000774612923074342 WETH + 4.293335673936901 VISTA (**$3.75**); gas 253,117 |
| T5 `unprivilegedCannotSetRouter` | PASS | `setRouter`/`setRouterSetter` revert for attacker **and** for the official router |
| T6 `secondPair_drainable_in_one_swap` | PASS | a **second** WETH pair with overflow is drained >0.05 WETH in one hostile swap (systemic proof) |
| T7 `officialRouter_bounded_by_getAmountOut` | PASS | honest swap output ≤ `getAmountOut`; real K preserved |
| T8 `code_identity` | PASS | pair code hash == canonical; 25-pair sample identical; `INIT_CODE_HASH` matches |
| T9 `dust_protected_after_drain` | PASS | post-drain K check self-heals; second drain attempt reverts `K` |
| T10 `router_leftovers_empty` | PASS | router WETH/VISTA/ETH ≈ 0 |

- **CI:** GitHub Actions `artsbykriss/ca-zombie-ci` (branch `ethervista`) — run URL in `summary.json` / `ci-log.txt` (see §9).
- Heavy jobs (`ci/run.sh`): full 1,087-pair scan, bytecode diff for pair/router/factory, extra live-state checks.

## 8. Verdict

- **Live E-U: $0.00** on the target pair; **$0.0007** across the entire 1,087-pair fleet (one dust skim). Confidence **high**.
- **Latent P (one key):** `setRouter(hostile)` + one `swap()` = **$69,183.66 net** from the target pair in a single call with 1 wei of capital; the same switch exposes all 1,087 pairs — **≈$317.8k best-strategy fleet latent** (116.155 WETH ≈ $283.3k price-free WETH floor + valuable token sides). Confidence **high** (target), **high** (mechanism + WETH floor), **medium** (fleet USD total; 707 overflowing pairs are unpriced long-tail tokens).
- **H-O** ≈ $7,239.5 (live LP redemption + ETH pot). **S** ≈ $63,427.8 (burned LP backing).
- **Residual risk:** the weapon is *still loaded*: the pair is 100% re-drainable today; `routerSetter` was never rotated after the $18.6k incident; the single EOA key (no multisig/timelock) still controls the router and still collects the router treasury. Public attribution of the Oct 9 authority use is unresolved; nothing on-chain prevents a repeat.
- **Blockers to a live E-U path:** the router gate (bytecode-verified) and the absence of any arbitrary-`amountOut` entry point. What would change the verdict: any `setRouter` to a non-official contract (monitor), or a pair-level excess donation (skim; none today).

## 9. Monitors

1. `factory.router()` change (event-less — watch tx to factory with selector `0xc0d78655`), especially to anything ≠ `0x9bD63C5D…`.
2. `factory.routerSetter()` change (`0xdd5819ad`) — would indicate rotation/hand-off.
3. Pair `Sync`/`Swap` events with `amountOut ≈ reserve` (drain signature).
4. New WETH/VISTA or high-value pair activity; any pair's `balance > reserve` (skim excess).
5. Router treasury/key activity (EOA `0xCA90D843…` outbound txs).

## 10. Methodology & sources

- On-chain reads at pinned blocks 26,201,112 / 26,201,164 (publicnode/drpc public RPCs): reserves, balances, roles, LP supply/holders, code hashes, factory pair list (all 1,087).
- Verified sources: Etherscan V2 (`getsourcecode`) for pair/router/factory; saved as `analysis/verified_*.json`; compiled with official solc 0.5.16/0.6.6 binaries (standard-JSON) and diffed byte-for-byte.
- PoC: Foundry on GitHub Actions (`ci/run.sh` + `forge test -vvv`).
- Prices: DefiLlama `coins.llama.fi` (2026-10-15/16): WETH $2,439.32, VISTA $0.433724.
- Incident/public record: SlowMist tweet + Hacked-DB entry; SentinelTX/ChainBounty proceeds report; Protos (2024 router fee-sweep incident); official docs/repo; research sub-report `analysis/research/README.md`; history sub-report `analysis/history/README.md`.
- Sub-agent corroboration: router classification (5 official / 6 test / 1 attacker), Mar/Apr flips drained nothing (net flows *into* the pool), only one WETH/VISTA pair exists, Oct 9 touched exactly one pair.

### Caveats & limitations
- USD values are point-in-time (prices move; WETH is the dominant leg).
- 707 overflowing pairs are unpriced long-tail tokens — their non-WETH side is unquantified; the priced total bounds the realistic fleet value (the target pair is 98.6% of it).
- The bzzr1 metadata differences on pair/factory are source-text normalisation by Etherscan; executable code is byte-identical (proved).
- Attribution of the Oct 9 `setRouter` use (key compromise vs insider) is not resolvable from public/on-chain data; no claim is made either way.

### Files index
- `analysis/bytecode_diff.py`, `analysis/bytecode_diff.json`, `analysis/verified_{pair,router,factory}.json`, `analysis/pair_creation_deployed.hex`, `analysis/pair_runtime.hex`, `analysis/factory_runtime.hex`
- `analysis/fleet_scan.py`, `analysis/pairs.csv`, `analysis/fleet_scan.json`, `analysis/fleet_summary.json` (all 1,087 pairs)
- `analysis/extra_checks.py`, `analysis/extra_checks.json` (roles/bindings/LP split)
- `analysis/research/` (web research), `analysis/history/` (router/drain forensics)
- `poc/` (Foundry tests T1–T10), `ci/run.sh`, `ci-out/`, `ci-log.txt`, `ci-artifacts/`
- `summary.json`
