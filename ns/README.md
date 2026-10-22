# ZH4-PASS4 Tier-3 · **NS** (`NSToken`) — burn-from-pair + `pair.sync()` deep dive

**Date:** 2026-10-22 · **Chain:** BSC (56) · **Status:** read-only; fork-verified only; **no mainnet transaction signed or sent**
**Target:** NS token `0x33F1c4FBb7e4e040F4f4E6bC492E4fedf750fd41` · pair `0xF1a5896D91C1E2372b159455ad013B2D17c0BB0b` (PancakeSwap V2, NS/USDT)
**Pattern:** $NEM-class "burn-from-pair + `sync()`" (`pass4/skim-burn.md` row #8, gate unresolved)

---

## 1. TL;DR

| Question | Answer |
|---|---|
| Burn-from-pair + `sync()` function | `burnNsFromPair(uint256 burnBps)` — burns `pairBal·bps/10000` of the pair's NS, then `pair.sync()` |
| **The exact gate** | `if (msg.sender != pairBurnOperator) revert Unauthorized();` — **+ 1-day cooldown**, `bps ≤ 500` |
| Who is `pairBurnOperator`? | `0x2bdeadCEf40a9129ea99A4a99Ec03ccdBC9a3942` — a **Gnosis Safe multisig proxy** (`masterCopy() = 0x29fCb43b46531BcA003ddC8FCB67FFE91900C762`, Safe v1.3.0); also `governance` |
| Fresh-EOA probe | **reverts `Unauthorized()` (`0x82b42900`)** |
| **Live extractable by an unprivileged attacker** | **$0.00** (high confidence) |
| Nominal value at risk (USDT side, block 129,126,816) | **$628,841** — privileged-only |

**Total live extractable now: $0.00** (confidence **high**). Category: **P** (privileged/governance-only).

---

## 2. The mechanism (deployed code, verified source `src/NashStake/NSToken.sol`)

```solidity
uint256 public constant MAX_PAIR_BURN_BPS = 500;        // 5%
uint256 public constant PAIR_BURN_COOLDOWN = 1 days;
uint256 public constant MIN_TOTAL_SUPPLY  = 2_100_000 ether;

function burnNsFromPair(uint256 burnBps) external {
    if (msg.sender != pairBurnOperator) revert Unauthorized();        // ← THE GATE
    if (burnBps == 0 || burnBps > MAX_PAIR_BURN_BPS) revert InvalidValue();
    if (pairBurnSequence != 0) {
        uint256 nextAvailableTime = lastPairBurnTime + PAIR_BURN_COOLDOWN;
        if (block.timestamp < nextAvailableTime) revert PairBurnCooldownActive();
    }
    uint256 pairBalanceBefore = balanceOf(officialPair);
    uint256 requestedAmount  = pairBalanceBefore * burnBps / BPS_DENOMINATOR;
    uint256 remainingAmount  = totalSupply() - MIN_TOTAL_SUPPLY;
    uint256 actualBurned = requestedAmount < remainingAmount ? requestedAmount : remainingAmount;
    if (actualBurned == 0) revert InvalidValue();

    pairBurnSequence += 1;
    lastPairBurnTime = block.timestamp;
    _burn(officialPair, actualBurned);                                // ← burns FROM the pair
    INashV2Pair(officialPair).sync();                                 // ← pair.sync()
    emit OfficialPairNsBurned(msg.sender, burnBps, pairBalanceBefore, actualBurned, totalSupply());
}
```

This is the *precise* NEM shape (burn from the pair, sized by `balanceOf(pair)`, then `sync()`), but it is **explicitly role-gated and rate-limited**.

Two other functions matter for completeness:
* `burn(uint256)` is **permissionless** but only burns the **caller's own** NS (`_burn(msg.sender, …)`), and reverts if `msg.sender == officialPair`. It cannot touch the pair reserve → not extraction.
* `processFees()` is permissionless but only swaps NS already held by the token contract for USDT to `feeTo`; it does not burn from the pair.

### Why pass4 left it "unresolved"

pass4 saw only the bytecode's external `sync()` and an empty revert on a probe. The gate is a plain `msg.sender != pairBurnOperator` check; `pairBurnOperator` lives in storage (slot 8) and is a Safe proxy, so `eth_call` from a random EOA reverts `Unauthorized()`.

---

## 3. Live-state assessment (block **129,126,816**)

| Item | Value |
|---|---|
| `officialPair` | `0xF1a5896D91C1E2372b159455ad013B2D17c0BB0b` |
| `token0` / `token1` | NS / USDT `0x55d3…7955` |
| `getReserves()` | **11,265.766484491480745237 NS** · **628,841.197473420625955417 USDT** |
| `NS.balanceOf(pair)` | `11,265.766484491480745237` — **equals reserve0 → no live desync** |
| `totalSupply()` | 20,999,982.776695010653921181 NS (floor `MIN_TOTAL_SUPPLY` = 2,100,000) |
| `pairBurnOperator()` (slot 8) | `0x2bdeadCEf40a9129ea99A4a99Ec03ccdBC9a3942` (code 171 B, Safe proxy) — **4-of-6 Gnosis Safe** (storage: `singleton`=Safe v1.3.0, `ownerCount`=6, `threshold`=4, `nonce`=16) |
| `governance()` (slot 6) | same Safe address |
| `feeTo()` (slot 7) | `0xe236122936e39Bb79fF29F09ae015e6aa9b61265` (code 171 B, Safe proxy) |
| `owner()` | `0x0` (renounced) |
| EIP-1967 impl slot | `0x0` → not a proxy / non-upgradeable |
| `buyTaxBps` / `sellTaxBps` | 300 / 300 (3 % each) |
| `pairBurnSequence` | **0** — the burn has **never** been called since launch |
| base-side value | **$628,841** (USDT) |
| recent activity (~8,000 blocks) | 103 NS transfers, 93 pair `Sync` (public `sync()` bots) — actively traded |

Gate probes from a fresh EOA `0x…DeaDBeef` (`eth_call`, no tx):

| Call | Result |
|---|---|
| `burnNsFromPair(500)` | **revert `Unauthorized()` `0x82b42900`** |
| `burnNsFromPair(1)` | **revert `Unauthorized()` `0x82b42900`** |
| `burn(1e18)` | revert `ERC20InsufficientBalance` (`0xe450d38c`) — attacker holds 0 NS (self-burn only) |

---

## 4. What an attacker can / cannot do

**Cannot:** call `burnNsFromPair` (Unauthorized); call any setter (`setPairBurnOperator`, `setFeeTo`, `transferGovernance` are `onlyGovernance` = the Safe; `setTaxRates`, `setTaxExempt` are `onlyOwner` = renounced/`0x0`). No unprivileged entry to the burn exists.

**Latent (privileged) capability — quantified on fork:** if the Safe/operator key were ever compromised, one `burnNsFromPair(500)` burns 5 % of the pair's NS and `sync()`s, lifting the NS price ~**5.26 %** with the USDT side untouched; the 1-day cooldown caps it at one such step per day (≈5.26 %/day), and an attacker would additionally need to already hold NS to sell into it. See `test_ns_latent_if_operator_compromised`.

---

## 5. PoC / fork verification

`poc/test/NsPoC.t.sol` (Foundry fork on `BSC_RPC_URL`):

| Test | Asserts |
|---|---|
| `test_ns_live_state` | reserve0 == real pair NS balance; `pairBurnSequence == 0` |
| `test_ns_gate_reverts_unauthorized` | outsider call → `Unauthorized()` `0x82b42900` |
| `test_ns_operator_is_gnosis_safe` | operator == governance; proxy `masterCopy() == 0x29fCb43b…C762` |
| (state read) | Safe storage: `ownerCount = 6`, `threshold = 4`, `nonce = 16` → **4-of-6 multisig** |
| `test_ns_arg_and_cooldown_bounds` | `burnBps = 501` → `InvalidValue()` |
| `test_ns_latent_if_operator_compromised` | pranked operator burn drops reserve0 ~5 %, reserve1 unchanged, `sync()` ran; immediate second call → `PairBurnCooldownActive()` `0x4c154b5f` |
| `test_ns_public_burn_is_self_burn_only` | public `burn()` reverts `ERC20InsufficientBalance` for a 0-balance caller |

* CI: see `ci-log.txt` / `summary.json` (`ci_run_urls`). Result: **all tests pass**.
* `ci/run.sh` writes `ci-out/live-state.json`.

---

## 6. Verdict, residual & re-arm triggers

**Verdict: privileged-only — $0 extractable by an unprivileged attacker (high confidence).** The NEM-shaped burn+sync exists verbatim but is guarded by `pairBurnOperator` (a Gnosis Safe), a 1-day cooldown and a 5 % cap. A fresh EOA cannot call it, and the Safe's `masterCopy()` confirms a multisig, not an EOA or a permissionless helper.

**Residual / latent risk:** a compromised or malicious Safe signer set could step the NS price ~5.26 %/day (bounded by cooldown) — a governance-trust risk, not an outsider exploit. `pairBurnSequence == 0` means the mechanism is untested live; a future operator call is a monitorable event.

**Re-arm triggers:** (1) `pairBurnOperator` changed to an EOA or to a contract exposing a permissionless pass-through; (2) the Safe's threshold/owners changing; (3) any new code path that calls `burnNsFromPair` unauthenticated.

---

## 7. Methodology & files

**Method:** BscScan verified source read; keyless-RPC `eth_call`/`getStorageAt`/`getLogs` at explicit blocks; Foundry fork tests (CI). No secret is written into this folder.

```
ns/
├── README.md
├── summary.json
├── analysis/
│   ├── src/NSToken.sol (+ OZ/interface files)   # verified source
│   └── (live reads referenced from btcx/analysis/state.json & probe.py)
├── poc/                          # Foundry project (forge-std vendored)
├── ci/run.sh
├── ci-out/
└── ci-log.txt
```

**Caveats:** point-in-time (2026-10-22, block 129,126,816). USDT ≈ $1. Nothing here is an instruction to transact.
