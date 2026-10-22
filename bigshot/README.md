# BigShot — public `sweepToken()` pays the whole balance to a caller-supplied recipient (Optimism)

**Date:** 2026-10-22 · **Chain:** Optimism (10) · **Target:** `0x274D146c910dCe811805E08fF8F61a1c3A931c4a` ("BigShot")
**Status:** read-only research; PoC fork/etch-verified only; **no transaction was signed or broadcast.**
**Pin block:** `158,535,915` (live state) · **Verdict:** **E-U-conditional, $0 live** (empty contract) · **Confidence:** high (mechanism) / high ($0).

## 1. TL;DR

| # | Target | Live extractable (unprivileged) | Why open / closed | Latent risk |
|---|---|---|---|---|
| 1 | **BigShot `0x274D146c…931c4a`** (Optimism) | **$0** — native 0, zero ERC-20 balances, **0 transactions ever** | The drain fn is live and public, but the contract holds nothing | **Instant open drain** the moment any ERC-20 lands: any caller sends the whole balance to any recipient |
| 2 | Same contract on **Polygon** `0x274D146c…931c4a` | **$0** | deployed 2022 (block 33,570,593), native 0, **0 ERC-20 transfers ever**, 1 tx total (the deployment) | same instant drain on any inflow |
| 3 | Class siblings — canonical Uniswap V3 periphery (`sweepToken` is public **by design**) | **$0** (spam-only) | empty at rest; OP NonfungiblePositionManager holds 228 worthless airdrop tokens | known spam-magnet, not a bug |

**Total live extractable now: $0.00** (confidence high). BigShot is a *latent* drain: it is deployed on two chains (Optimism + Polygon), both empty, neither ever used for token flows.

## 2. The mechanism, exactly

BigShot is a verified short-selling protocol (solc 0.8.10) that inherits
`UniswapIntegrationHelper` → Uniswap **v3-periphery `PeripheryPayments`**. That base class makes the
sweep helpers **public** with **no access control**:

```solidity
function sweepToken(address token, uint256 amountMinimum, address recipient) public payable override {
    uint256 balanceToken = IERC20(token).balanceOf(address(this));
    require(balanceToken >= amountMinimum, 'Insufficient token');
    if (balanceToken > 0) { TransferHelper.safeTransfer(token, recipient, balanceToken); }
}
function unwrapWETH9(uint256 amountMinimum, address recipient) public payable override { … }
function refundETH() external payable override { … } // sends the ENTIRE native balance to msg.sender
```

No `onlyOwner`, no `msg.sender` check, no proof the caller owns anything. `sweepToken` pays the
contract's **whole** `balanceOf(this)` to a **caller-supplied** `recipient`; `refundETH()` pays the whole
native balance to `msg.sender`. This is the **T1 (destination-trust)** form of the Slice-class flaw.
`msg.sender`/`amountMinimum` are never bound to anything the caller must own.

Deployed-code checks (Optimism, block 158,535,915): `codesize = 18214`,
`codehash = 0x851d58c8d5b0ebc8984546a43696fdb941c7e529802078a46da432f173052911`;
selectors present: `0xdf2ab5bb` (`sweepToken(address,uint256,address)`), `0x49404b7c`
(`unwrapWETH9(uint256,address)`), `0x12210e8a` (`refundETH()`).

**Exact calldata** an attacker sends (drain an ERC-20 `T` to attacker, `amountMinimum = 0`):
```
0xdf2ab5bb
000000000000000000000000<T 20 bytes>
0000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000<recipient 20 bytes>
```

## 3. Live-state assessment

| Property | Value (block 158,535,915) | Source |
|---|---|---|
| code | 18214 bytes, verified `BigShot` | `eth_getCode` + OP Blockscout |
| `sweepToken` / `unwrapWETH9` / `refundETH` selectors | present | bytecode scan |
| native balance | **0 wei** | `eth_getBalance` |
| ERC-20 balances | **none** (`has_tokens:false`, `token-balances: []`) | OP Blockscout |
| transactions / token transfers ever | **0 / 0** | OP Blockscout counters |
| `owner()` | `0xbA79a22A4b8018caFDC24201ab934c9AdF6903d7` | `eth_call` |
| `owner` nature | **EIP-7702 smart EOA** (`code = 0xef0100‖0x1232b00bfa86e83353e05753caa3be8ea7087fac`) | `eth_getCode` |
| `WETH9()` / `factory()` | `0x4200…0006` / `0x1F98431c8aD98523631AE4a59f267346ea31F984` (canonical) | `eth_call` |

The deployer/owner is an EIP-7702-delegated smart account. BigShot is deployed on **two chains**; the
second instance (Polygon) is also empty — see §5.

## 4. What an attacker can / cannot do

- **Can (once funded):** any EOA calls `sweepToken(T, 0, attacker)` → receives 100% of BigShot's `T`
  balance; or `refundETH()` → receives 100% of its ETH. No preconditions beyond the contract holding value.
- **Cannot today:** there is nothing to take — the contract is empty and unused.
- **Cannot:** pull user approvals. `openShortTokenPosition` uses `transferFrom(msg.sender, …)`, so a
  third party cannot spend another user's allowance through BigShot.
- **Costs:** a plain ~50–80k-gas call. Net profit = whatever lands in the contract, minus gas.

## 5. Sibling sweep

- **Same source:** BigShot is deployed on **exactly two chains** — **Optimism** (target) and **Polygon**
  `0x274D146c910dCe811805E08fF8F61a1c3A931c4a` (deployed 2022-09-26, block 33,570,593; same owner
  `0xbA79a22A…`, same `BigShot` verified name, `sweepToken` `0xdf2ab5bb` present, `WETH9` = Polygon WETH).
  Runtime codehash differs (`0x692d2785…` vs `0x851d58c8…`) only because the constructor-baked
  immutables (WETH9/factory/Aave addresses) differ. **Both are empty:** Optimism has 0 transactions
  ever; Polygon has exactly **1** transaction (the deployment) and **0 ERC-20 transfers ever**.
- **Address has `codesize 0`** on 34 other chains checked (Ethereum, Base, Arbitrum, BSC, Gnosis, Linea,
  Scroll, Mantle, zkSync, Blast, Mode, Unichain, Soneium, Celo, Avalanche, Fantom, Worldchain, Polygon
  zkEVM, Arbitrum Nova, Manta, opBNB, Fraxtal, Cronos, Boba, Aurora, Core, XLayer, ZetaChain, ApeChain,
  Sonic, Ink, Taiko, Metis, Kava, Sei, Astar).
- **Same selector (class):** Uniswap V3 periphery `PeripheryPayments` (public `sweepToken` **by design**).
  OP NonfungiblePositionManager `0xC36442b4a4522E871399CD717aBDD847Ab11FE88` holds **228 spam airdrop
  tokens** (~$0) and 0 native; OP SwapRouter/SwapRouter02 hold 0 native. These are spam-magnets, not
  vulnerabilities — the canonical design assumes the contract never holds value at rest.
- **Funded-by-the-same-pattern:** none found on either chain.

## 6. PoC / fork verification

Foundry project `poc/` (solc 0.8.24). **4 / 4 PASS.**

| Test | What it proves |
|---|---|
| `test_etched_sweepToken_drainsWholeBalance_toCallerSuppliedRecipient` | etch the exact deployed runtime; seed 1000e6 mock token → arbitrary EOA receives all 1000e6 |
| `test_etched_refundETH_drainsWholeNativeBalance` | seed 5 ETH → `refundETH()` sends all 5 ETH to `msg.sender` |
| `test_live_optimism_selector_present_and_balances_zero` | live OP fork: selectors present, native + OP-token balances are 0 |
| `test_live_optimism_fork_sweepToken_drains` | live OP fork: seed 1e18 OP token → unprivileged EOA drains it via the exact calldata |

CI: **PASS 4/4** — run https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39781517056
(log `ci-log.txt`, artifacts `ci-out/`, `ci-artifacts/`).

## 7. Verdict, re-arm trigger, recommendation

- **Verdict:** **E-U-conditional — $0 today** (high confidence). The drain path is fork-proven and
  unpatched; the contract is simply empty and has never been used.
- **Re-arm trigger (exact):** **any** inbound value to `0x274D146c910dCe811805E08fF8F61a1c3A931c4a` on
  **Optimism or Polygon** — i.e. `token.balanceOf(BigShot) > 0` for any ERC-20, **or** `eth_getBalance(BigShot) > 0`.
  Watch: ERC-20 `Transfer` events with `to == BigShot` on both chains (or a periodic `balanceOf` over a
  token watchlist). On trigger, the drain is a single permissionless call — a bot will take it within one block.
- **Recommendation:** **keep as a monitor (re-arm on inflow); remove as an active finding** — no live
  value, no user funds at risk, mechanism inherited from a public-by-design Uniswap base class.

## 8. Methodology, caveats, files

- **Method:** verified source (OP Blockscout) + bytecode selector scan; `eth_getCode`/`eth_getBalance`/
  `eth_call` at pinned block; Foundry etch + Optimism-fork PoCs (read-only; no tx sent).
- **Caveats:** point-in-time (2026-10-22); a token transfer to the contract re-arms it instantly.
  OP-fork tests were run with the default (non-OP) global fork and `vm.createSelectFork(OP)` inside the
  test, per the pass-4 note about op-revm.
- **Files:** `README.md` · `summary.json` · `analysis/bigshot_runtime.hex`, `analysis/live_state.json`,
  `analysis/sibling_sweep.json` · `poc/` (foundry project, 4 tests) · `ci/run.sh` · `ci-out/` ·
  `ci-log.txt`.

*Read-only. Nothing here is an instruction to transact. Evidence in `ci-out/` + on-chain calls cited above.*
