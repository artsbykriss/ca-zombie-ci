# ZH4-PASS4 Tier-3 · **DMD** (`DMDToken`) — burn-from-pair + `pair.sync()` deep dive

**Date:** 2026-10-22 · **Chain:** BSC (56) · **Status:** read-only; fork-verified only; **no mainnet transaction signed or sent**
**Target:** DMD token `0x939Df4A5A5022037BB33102C6489e774E063b160` · pair `0x29f9148a8518e327e8677Ba21C3fa3A55DD1e6Bc` (PancakeSwap V2, DMD/USDC)
**Pattern:** $NEM-class "burn-from-pair + `sync()`" (`pass4/skim-burn.md` row #9, gate unresolved)

---

## 1. TL;DR

| Question | Answer |
|---|---|
| Burn-from-pair + `sync()` function | `burnFromMainPair()` — burns `pairBal·50/10000` (0.5 %) of the pair's DMD, then `pair.sync()` |
| **The exact gate** | `modifier onlyAdmin { if (msg.sender != admin) revert NotAdmin(); }` — **no cooldown** |
| Who is `admin`? | `0xfB9E004c6e8a89F0348fEcBD1c62387635630247` — **EOA** (`eth_getCode` = `0x`, 0 bytes) |
| Fresh-EOA probe | **reverts `NotAdmin()` (`0x7bfa4b9f`)** |
| Buying DMD | **disabled** (`buyEnabled() == false`) → buys revert `BuyingDisabled()` (`0x44c1679c`) |
| **Live extractable by an unprivileged attacker** | **$0.00** (high confidence) |
| Nominal value at risk (USDC side, block 129,126,816) | **$284,918** — privileged-only |

**Total live extractable now: $0.00** (confidence **high**). Category: **P** (privileged/admin-only).

---

## 2. The mechanism (deployed code, verified source `contracts_new/DMDToken.sol`)

```solidity
uint256 public constant PAIR_BURN_BPS   = 50;                 // 0.5%
uint256 public constant MIN_TOTAL_SUPPLY = 1_000_000 * 10**18;

modifier onlyAdmin() { if (msg.sender != admin) revert NotAdmin(); _; }

function burnFromMainPair() external onlyAdmin nonReentrant {  // ← THE GATE
    address pair = mainPair;
    if (pair == address(0)) revert PairNotSet();
    uint256 supply = totalSupply();
    if (supply <= MIN_TOTAL_SUPPLY) return;
    uint256 pairBal = balanceOf(pair);
    if (pairBal == 0) return;
    uint256 targetFromPair = (pairBal * PAIR_BURN_BPS) / 10_000;
    uint256 maxBurnByFloor = supply - MIN_TOTAL_SUPPLY;
    uint256 burnAmt = targetFromPair > maxBurnByFloor ? maxBurnByFloor : targetFromPair;
    if (burnAmt > pairBal) burnAmt = pairBal;
    if (burnAmt == 0) return;
    _burn(pair, burnAmt);                 // ← burns FROM the pair
    IUniswapV2Pair(pair).sync();          // ← pair.sync()
}
```

Notes:
* `burnFromMainPair` is the **only** caller of `sync()` in the token, and it is `onlyAdmin`.
* There is **no cooldown** — but the gate is a single EOA key. The `admin` EOA could deploy a helper contract that loops `burnFromMainPair()` in one transaction (each call burns 0.5 % and syncs) → the NEM-style repeated collapse is *possible for the admin key*, but not for an outsider.
* Adjacent (different class): `_handleBuy` also `_burn`s 1 % of the pair's DMD per buy **without** `sync()` — but buys are disabled, and this desync direction (real < reserve) is not attacker-profitable.

---

## 3. Live-state assessment (block **129,126,816**)

| Item | Value |
|---|---|
| `mainPair()` | `0x29f9148a8518e327e8677Ba21C3fa3A55DD1e6Bc` |
| `token0` / `token1` | USDC `0x8AC7…580d` / DMD |
| `getReserves()` | **284,917.587339866291158858 USDC** · **722,196.582352079125067941 DMD** |
| `DMD.balanceOf(pair)` | `722,196.582352079125067941` — **equals reserve1 → no live desync** |
| `totalSupply()` | 20,176,229.223753040743380219 DMD (floor 1,000,000) |
| `admin()` (slot 13) | `0xfB9E004c6e8a89F0348fEcBD1c62387635630247` — **EOA** |
| `owner()` (slot 5) | `0x3Df33d473811c46c402a014840C07Cf6397304Bf` — **EOA** |
| EIP-1967 impl slot | `0x0` → not a proxy / non-upgradeable |
| `buyEnabled()` | **false** |
| `lpHelper()` | `0xdd38fAc98b8ba6c1CC3b86DF34C079418830Bcbd` |
| `dividendWallet()` / `marketingWallet()` | `0x952e680667F5Eef19e545a9dE3a4D288e4F48595` / `0x3dAf480583d56802ceDb940B82C30dC011AeD97F` (171 B Safe proxy) |
| base-side value | **$284,918** (USDC ≈ $1) |
| recent activity (~8,000 blocks) | 221 DMD transfers, 97 pair `Sync` (public `sync()`), 0 buys (buy-disabled) |

Gate probes from a fresh EOA `0x…DeaDBeef` (`eth_call`, no tx):

| Call | Result |
|---|---|
| `burnFromMainPair()` | **revert `NotAdmin()` `0x7bfa4b9f`** |
| router `swapExactETHForTokens(WBNB→USDC→DMD)` from a funded EOA | **revert `BuyingDisabled()` `0x44c1679c`** |

---

## 4. What an attacker can / cannot do

**Cannot:** call `burnFromMainPair` (NotAdmin); call any `onlyOwner` setter (`setAdmin`, `setMainPair`, `setBuyEnabled`, `injectLiquidity`) — `owner()` is a separate EOA and not the attacker. Buys are disabled, so a fresh attacker cannot even acquire DMD to sell into a manipulated reserve.

**Latent (privileged) capability — quantified on fork:** with the `admin` EOA key, looping `burnFromMainPair()` (no cooldown) **100×** removes ~**39 %** of the pair's DMD and `sync()`s each time (DMD price up ~65 %), while the USDC side is untouched. See `test_dmd_latent_admin_loop_burn`. This is a key-compromise / insider risk, not an outsider path.

---

## 5. PoC / fork verification

`poc/test/DmdPoC.t.sol` (Foundry fork on `BSC_RPC_URL`):

| Test | Asserts |
|---|---|
| `test_dmd_live_state` | reserve1 == real pair DMD balance; `mainPair` set |
| `test_dmd_gate_reverts_not_admin` | outsider call → `NotAdmin()` `0x7bfa4b9f`; logs `admin`/`owner` EOAs; `buyEnabled == false` |
| `test_dmd_buy_is_disabled` | router buy → `BuyingDisabled()` `0x44c1679c`; attacker balance 0 |
| `test_dmd_latent_admin_loop_burn` | pranked admin ×100 drops pair DMD reserve ~39 %, USDC reserve unchanged, `sync()` ran |

* CI: see `ci-log.txt` / `summary.json` (`ci_run_urls`). Result: **all tests pass**.
* `ci/run.sh` writes `ci-out/live-state.json`.

---

## 6. Verdict, residual & re-arm triggers

**Verdict: privileged-only — $0 extractable by an unprivileged attacker (high confidence).** `burnFromMainPair` is `onlyAdmin`, and `admin` is a single EOA (not a permissionless helper). Buying is additionally disabled, so there is no outsider entry at all.

**Residual / latent risk:** the missing cooldown + EOA admin means a single compromised `admin` key (or an insider) can repeatedly collapse the DMD reserve against the untouched USDC side — a real but privileged loss vector (≈39 % of the pair in 100 calls). Worth flagging to the project as a design risk (EOA admin + uncapped burn loop).

**Re-arm triggers:** (1) `admin` set to a contract with a permissionless pass-through to `burnFromMainPair`; (2) `buyEnabled` toggled true (re-opens a buy path — still not an exploit by itself, but changes the attacker surface); (3) any change making `burnFromMainPair` permissionless.

---

## 7. Methodology & files

**Method:** BscScan verified source read; keyless-RPC `eth_call`/`getStorageAt`/`getLogs` at explicit blocks; Foundry fork tests (CI). No secret is written into this folder.

```
dmd/
├── README.md
├── summary.json
├── analysis/src/DMDToken.sol        # verified source
├── poc/                             # Foundry project (forge-std vendored)
├── ci/run.sh
├── ci-out/
└── ci-log.txt
```

**Caveats:** point-in-time (2026-10-22, block 129,126,816). USDC ≈ $1. Nothing here is an instruction to transact.
