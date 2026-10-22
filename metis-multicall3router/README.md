# Wheelx "Multicall3Router" — unguarded `cleanupERC20(token, refundTo)` drains its whole balance to any recipient · deployed on **34 chains**

**Date:** 2026-10-22 · **Chains:** Metis (named target) + 18 identical siblings · **Target:** `0x6222f99443A0d75bd96d40F2904606f60f37cdc2`
**Status:** read-only research; PoC fork/etch-verified only; **no transaction was signed or broadcast.**
**Pin blocks:** Metis `23,307,448` · BSC `129,127,210` · Ethereum `26,248,050` · **Verdict:** **E-U-conditional, ≈$0 live** (dust only) · **Confidence:** high.

## 1. TL;DR

| # | Target | Live extractable (unprivileged) | Why open / closed | Latent risk |
|---|---|---|---|---|
| 1 | **Multicall3Router `0x6222f994…f37cdc2`** (Metis, named target) | **$0** — native 0, no token balances | `cleanupERC20` is `external` with **no gate**; contract is empty | Instant drain of any token that lands |
| 2 | **Same address + code on 33 other chains** (identical codehash) | **≈$0.0006** drainable today (ETH: 1 HEX; BSC: 2.008e-8 WBNB) + spam | same unguarded code everywhere (deterministic deploy) | any inflow on any of 34 chains is instantly drainable |
| 3 | Class siblings (Slice-class `release`/`sweep` trusting a caller address) | **$0** | prior lanes closed (Slice patched, BigShot empty, splitters guarded) | monitor |

**Total live extractable now: $0.00** (≈ $0.0006 of worthless dust is *technically* drainable; confidence high).

## 2. The mechanism, exactly

`Multicall3Router` (verified source, solc 0.8.9, "Wheelx") is a swap router deployed through the
**Arachnid deterministic-deployment proxy** `0x4e59b44847b379578588920cA78FbF26c0B4956C`, so the **same
address + same runtime code** exist on **34 chains** (`codehash = 0x1797a996a32bdc9c3053cfcbd546946296ca37557a2a51ce3d593c267c63b8e0`,
`codesize = 4795`). It exposes **five unguarded value-moving entry points**:

```solidity
function cleanupERC20(address token, address refundTo) external {          // NO access control
    uint256 balance = IERC20(token).balanceOf(address(this));
    if (balance > 0) { IERC20(token).transfer(refundTo, balance); }        // whole balance -> caller-supplied recipient
}
function cleanupErc20s(address[] tokens, address[] recipients, uint256[] amounts) public virtual { … } // same, caller-chosen
function safeApproveIfBelow(address token, address spender, uint256 amount) external { … }  // grants ANY spender a max allowance
function safeApprovePermit2(address token, address spender, uint256 amount) external { … }  // Permit2 allowance to ANY spender
function safeMultiCall(bytes calls, address refundTo, bytes32 request_id) external payable { … } // delegatecalls multicall3 with CALLER data
```

`cleanupERC20` is the **T1 (destination-trust)** form of the Slice-class flaw: the payout destination is
fully caller-supplied and the amount is the contract's entire balance. Worse, `safeMultiCall`
`delegatecall`s `multicall3` with **fully caller-controlled calldata**, so an attacker can make the router
call `transfer`/`transferFrom`/ERC-721/1155 transfers on **any** asset it holds. Any ERC-20 that ever
lands in this router is drainable by anyone in one transaction (bots will race it).

Selectors (present in all 34 deployments): `cleanupERC20` `0x3dad0c9c`, `safeApproveIfBelow` `0x5e069ba5`,
`safeApprovePermit2` `0xe13157f5`.

**Exact calldata** an attacker sends (drain token `T` to attacker):
```
0x3dad0c9c
000000000000000000000000<T 20 bytes>
000000000000000000000000<recipient 20 bytes>
```

## 3. Live-state assessment (34 deployments)

**Native balance = 0 wei on every chain checked.** ERC-20 balances are spam/dust only:

| Chain | Deployed | Native | ERC-20 balance(s) | Value |
|---|---|---|---|---|
| Metis (target) | ✅ | 0 | none | $0 |
| Ethereum | ✅ | 0 | 1.0 HEX + 1 wei stETH + 1 wei eETH + spam | ≈ **$0.0006** |
| BSC | ✅ | 0 | **2.008e-8 WBNB** (20,081,028,819 wei) | ≈ $0.000014 |
| Optimism / Gnosis / Scroll | ✅ | 0 | spam airdrops only (Scroll: 1 spam ERC-20 + 57 spam ERC-1155) | $0 |
| Arbitrum | ✅ | 0 | USD₮0/WBTC/STG/WETH/USDC/ARB all **0** (active transit router) | $0 |
| Base, Polygon, Avalanche, Celo, Linea, Mantle, zkSync, Blast, Mode, Unichain, Soneium, Worldchain, XLayer, opBNB, Sonic, Manta, Taiko, Polygon zkEVM, Ink, Cronos, Sei, Zora, BOB, Flare, Ronin, Rootstock, Lisk | ✅ | 0 | none reported | $0 |

The router is used (Arbitrum: live USD₮0/WBTC/STG swaps; Metis: 10 txs, 47 token transfers) but tokens
**transit** and do not rest in it. Live value at rest ≈ **$0.0006** (a single HEX token).

## 4. What an attacker can / cannot do

- **Can (once funded):** any EOA calls `cleanupERC20(T, attacker)` → receives 100% of the router's `T`
  balance; or `safeApproveIfBelow(T, attacker, max)` + `T.transferFrom(router, attacker, bal)`; or
  `safeMultiCall` to move **any** asset (incl. NFTs). All fork-proven.
- **Cannot today:** extract material value — only ~$0.0006 of dust is present.
- **Costs:** ~50–90k gas per drain. On cheap chains gas < the value only for non-trivial inflows.

## 5. Sibling sweep (headline)

The **same runtime code exists at the same address on 34 chains** (deterministic deployment), all with
the identical `codehash 0x1797a996…b8e0`: Ethereum, Optimism, Base, Arbitrum, BSC, Polygon, Gnosis,
Avalanche, Celo, Linea, Scroll, Mantle, zkSync, Blast, Mode, Metis, Unichain, Soneium, Worldchain,
XLayer, opBNB, Sonic, Manta, Taiko, Polygon zkEVM, Ink, Cronos, Sei, Zora, BOB, Flare, Ronin, Rootstock,
Lisk. **All hold native 0; none holds material ERC-20 value.** Chains where the address has `codesize 0`
(Fantom, Arbitrum Nova, Fraxtal, Aurora, Core, ApeChain, Kava, Astar, Harmony, Oasis, Cyber, Kaia,
Metal L2, zkLink, Shape, Boba) are listed in `ci-out/m3r_siblings.json`. No other *different-address*
deployment of the Wheelx router was found. The Slice-class *shape* elsewhere was already closed by prior
lanes (Slice patched/paused, 0xSplits/OZ/thirdweb guarded).

## 6. PoC / fork verification

Foundry project `poc/` (solc 0.8.24). **7 / 7 PASS.**

| Test | What it proves |
|---|---|
| `test_etched_cleanupERC20_drainsWholeBalance_toCallerSuppliedRecipient` | etch exact runtime; seed 1000e6 → arbitrary EOA receives all |
| `test_etched_cleanupErc20s_drainsWholeBalance` | `cleanupErc20s` sends whole balance to caller-chosen recipient |
| `test_etched_safeApproveIfBelow_thenTransferFrom_drains` | attacker self-grants max allowance, then `transferFrom` drains |
| `test_live_bsc_cleanupERC20_drains_live_dust` | **live BSC fork**: drains the real 20,081,028,819 wei WBNB dust, no seeding |
| `test_live_bsc_safeMultiCall_arbitraryTransfer` | **live BSC fork**: `safeMultiCall`→multicall3 drains the same balance |
| `test_live_ethereum_cleanupERC20_drains_live_dust` | **live ETH fork**: drains the real 1.0 HEX, no seeding |
| `test_live_metis_selector_present_balances_zero_and_seeded_drain` | **live Metis fork** (target): selectors present, native 0, seeded balance instantly drainable |

CI: **PASS 7/7** — run https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39779479219
(log `ci-log.txt`, artifacts `ci-out/`, `ci-artifacts/`).

## 7. Verdict, re-arm trigger, recommendation

- **Verdict:** **E-U-conditional — $0 today** (high confidence). The unguarded drain is live on 34 chains
  and fork-proven; every instance is empty (dust only). ~$0.0006 is technically extractable.
- **Re-arm trigger (exact):** **any** ERC-20 (or native) inbound to `0x6222f99443A0d75bd96d40F2904606f60f37cdc2`
  on **any** of the 34 chains — i.e. `token.balanceOf(M3R) > 0` / `eth_getBalance(M3R) > 0`. Watch ERC-20
  `Transfer` events with `to == M3R` across all 34 chains (a single address to watch per chain). On any
  inflow, `cleanupERC20` drains it instantly — a bot will take it in the same block.
- **Recommendation:** **keep as a monitor (re-arm on inflow); remove as an active finding** — no live value;
  it is a legitimate swap router whose cleanup helpers simply lack an owner guard.

## 8. Methodology, caveats, files

- **Method:** verified source (Metis Blockscout) + `eth_getCode`/`eth_getBalance`/`eth_call` at pinned
  blocks across 34 chains; token balances via Blockscout v2 / Routescan; Foundry etch + BSC/ETH/Metis-fork
  PoCs (read-only; no tx sent). Sibling identity confirmed by keccak of runtime code.
- **Caveats:** point-in-time (2026-10-22); Base/BSC/Arbitrum Blockscout are Cloudflare/PRO-blocked, so
  their ERC-20 token lists were not exhaustively enumerated — but native balances are 0 and the router is a
  transit router (Arbitrum tokens checked = 0). The deterministic deployer means a **new** instance can be
  re-deployed at the same address on any new chain. Nothing here is an instruction to transact.
- **Files:** `README.md` · `summary.json` · `analysis/multicall3router_runtime.hex`,
  `analysis/live_state.json`, `analysis/sibling_sweep.json` · `poc/` (foundry project, 7 tests) ·
  `ci/run.sh` · `ci-out/` · `ci-log.txt`.

*Read-only. Evidence in `ci-out/` + on-chain calls cited above.*
