# AlpsCon AI Trade Hub — V7–V9 latent re-arm watch (BSC)

**Date:** 2026-10-20 · **Chain:** BNB Smart Chain (56) · **Status:** read-only; no transaction signed or sent. All state read with `cast call` / `eth_call` at named blocks. Primary snapshot **BSC block 128,633,400 (2026-10-19 22:22:18 UTC)**; independent CI re-check at **128,639,449**.
**Scope:** the V7/V8/V9 `AiTradeHubContract` share pools, the swap gate `0x7227…`, V6, V4/V5, the Vault, and the 2026-10-19 refill. This is a watch item from ZH4-PASS2 Tier-3 row 2, not a new finding.

---

## TL;DR

| Question | Answer |
|---|---|
| **Live E-U now** | **$0** — the only public-key whitelist entry is gone; every value-moving call from that key reverts |
| Gate | `isInWhiteList(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266)` on swap `0x7227d229be754fa49f416d48e8eaa121184b1721` = **false** (block 128,633,400). 16 standard Hardhat/Anvil/Ganache/Truffle/public-key addresses all false |
| **V9 refill trigger** | **FIRED** — **+464,360.873076 USDC** at block **128,595,562** (2026-10-19 17:38:27 UTC). Only **$34,763.78** remained at 22:22; **$30,190.64** at the CI block |
| V8 f39f `user_earnings` | **$151,557.34 — unbacked**, V8 holds **0 USDC** → **S** (stale accounting claim) |
| V7 f39f `user_earnings` | **$173,192.80 — unbacked**, V7 holds **0 USDC** → **S** |
| V4/V5 | **$5,931.94**; old swap has 0 balances / 0 allowances, old TRAI has no DEX pair → **S** |
| V6 | **$405.71**; `swapContract` slot 3 = `0x0` → disabled → **S** |
| Vault | **$5,912,217.00**; 2-of-2 multisig + module gating → **P** |
| **Re-arm trigger** | `isInWhiteList(0xf39f…2266)` returns **true** again on `0x7227` (or any public/test key is added) **plus** a funding path into V7/V8/V9 or a re-enabled V6 |
| Confidence | **high** that E-U = $0 today; **medium** on the size/path of the latent re-arm |

**One-line verdict:** the Oct-18 exploit is closed by the whitelist, not by a code fix; the Oct-19 refill proves the pools are still operated and can be reseeded, but the Hardhat key is still de-whitelisted and all $324.7k of its remaining accounting claims are unbacked. **H-O/S, not E-U.**

---

## 1. What changed since pass-2

Pass-2 read block **128,593,934** (2026-10-19 ~17:19 UTC) and found V9/V8/V7 = **0 USDC**, gate false. **1,628 blocks later**, at **128,595,562 (17:38:27 UTC)**, the team distributed **464,360.873076 USDC** from the Vault through the V9 fund module into V9. That is exactly the "any V7–V9 refill" escalation trigger from the pass-2 table.

It did **not** reopen the exploit, because the gate stayed false. Within ~5 hours, **429,617.15 USDC (92.5%)** left V9:

| Flow | USDC | Count |
|---|---:|---:|
| Distribution in | +464,360.873076 | 1 tx |
| To V9 fund module `0x442c…` | −408,132.006263 | 14,902 fee transfers |
| To users | −21,485.147610 | 396 recipients |
| **Residual in V9 at 22:22** | **34,763.782329** | — |
| Residual at CI block 128,639,449 | 30,190.64 | — |

The 408k was **monthly service fees** (14,902 `MonthlyFeeCharged`-style transfers), not a user payout. FundV2 forwarded it onward and now holds **0 USDC**; the project fund EOA `0x3e38…` holds **$21,042.72**.

**Correction to the prompt:** V9 did **not** have $110k at 18:20 UTC. At **18:20:20** (block 128,598,922) it held **$227,663.46**; it crossed ~$110k around **18:35** (block ~128,601,000 = $123.6k; 128,602,000 = $74.0k). The refill was **$464.36k**, and it was consumed by fees/claims within hours.

---

## 2. Mechanism in exact terms

V7/V8/V9 each compute a user's locked balance as **local locked + imported previous-version locked**:

```solidity
function _getUserLockedAmount(address user) internal view returns (uint256) {
    Contributor memory c = contributors[user];
    uint256 imported;
    if (!c.migrated)
        (,,, , imported, , , , ,) = getPreviousVersionStats(user); // V9→V8→V7→V6
    return c.lockedAmount + imported;
}

function _calculateUserEarningByShares(address wallet) internal view returns (int256) {
    uint256 locked = _getUserLockedAmount(wallet);
    int256 gross   = (int256(locked) * stats.profitPerShare) / 1e10;
    int256 claimed = (int256(locked) * contributors[wallet].entryProfitPerShare) / 1e10;
    return gross - claimed;
}
```

If a user's locked balance sits in V6/V7/V8 but the user never deposited into V9, V9's `entryProfitPerShare` is 0, so V9 pays `imported × V9.pps` with no offset. The Oct-18 attacker deposited into **V6**, called `V6.migrate()` to convert pending→locked, then claimed V9 (gross 329,384.80), V8 (21,635.46) and V7 (2,069.54), netting **$152,295.36** after the ALPS round trip and Aave premium (tx `0x824b…5fc2`, block 128,315,188).

The deployed V7/V8/V9 bytecode is **unchanged and has no pause**. The only live barrier is `onlyVerified` → `swapContract.isInWhiteList(msg.sender)`.

---

## 3. Live state at BSC block 128,633,400

**Gate checks (`0x7227…`, `isInWhiteList`)**

| Address | Result | Note |
|---|---|---|
| `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` (Hardhat #0, public key) | **false** | removed Oct 18 11:10:59, tx `0xa69e…03e8`, block 128,351,990 |
| `0x3E3899adB50acd77BB010262803bB240dcC51223` (project fund EOA) | true | key not public |
| `0xa2f5b45e614a99fe6e653012275e8c3df472ccf7` (project EOA) | true | key not public |
| 16 standard Hardhat/Anvil/Ganache/Truffle/public-key addrs | all false | checked individually |
| `0x000…000` | false | — |

**Balances (USDC, 18-dec; block 128,633,400)**

| Contract | Address | USDC | Other | Status |
|---|---|---:|---|---|
| V9 | `0x9b210da482217afc24074e57f6f8337fe07f0124` | **34,763.782329** | 502.5M ALPS | live, gate-closed; `pps = 0.0370312721`; total locked 514,208,288.21 ALPS |
| V8 | `0xa58fbe390210460b7b07e52a29d4eb84308472e1` | **0** | 4.48M ALPS | live, `swap` slot 10 = `0x7227`; f39f earnings 151,557.34 |
| V7 | `0x047284b1e752e39ae7a721d361ec0b0a554ef014` | **0** | 3.00M ALPS | live, `swap` slot 10 = `0x7227`; f39f earnings 173,192.80 |
| V6 | `0x74f091a719fdd47a95f378c7fb5c3d18a4582405` | **405.714346** | 3.05M ALPS | **disabled**: storage slot 3 = `0x0` |
| V4 | `0xeecfcf2ff8200f642ed7bb7fe259e258869572b7` | 2,391.485274 | 1.31M TRAI | old swap only; TRAI illiquid |
| V5 | `0x466762aae51a862c05dfa937e3da295627b09161` | 3,540.452212 | 164.1M TRAI | old swap only; TRAI illiquid |
| Vault | `0x7e84f721d8082639d8dba7ed357b34523ffffa0b` | **5,912,217.003146** | 9.46B ALPS | modules/multisig only → P |
| Swap | `0x7227d229be754fa49f416d48e8eaa121184b1721` | 131.597184 | 0 ALPS | gate live |
| Fund EOA | `0x3E3899adB50acd77BB010262803bB240dcC51223` | 21,042.722164 | ALPS/TRAI | project key → P |
| FundV2 | `0x442c5d0e6b5399e1e8a3f160b1840ef41e1d4a81` | 0 | 0 | forwarded the 408k |
| New V6 | `0x275B8E042abC1D1AC79b61a8938eF7324aF95c9e` | 0 | 0 | app's new base V6; not the recursive bug |
| New swap | `0x29307e91dbc5ed7a8843eebd48ff9eddd206852b` | 0 | 0 | f39f false |

**`getStats(f39f)` (USDC units)**

| Version | locked | pending | paid | earnings |
|---|---:|---:|---:|---:|
| V9 | 0 | 0 | **464,472.892777** | **0** |
| V8 | 0 | 0 | 0 | **151,557.336199** |
| V7 | 0 | 0 | 0 | **173,192.796852** |
| V6 | 0 | 0 | 0 | 0 |

The V9 `paid` figure is exactly the attack's V9 net claim (312,915.556578) **plus** the V8 earnings (151,557.336199), because the copycat `recompound()` tx consumed the V8 claim into V9 accounting. V8's storage still shows the same **151,557.34** — i.e. the same claim is counted again and is unbacked. V7's 173,192.80 is a separate unbacked claim.

**Live reverts (read-only `eth_call`, no tx):**

```
V9.claimServiceResults()   from f39f -> revert AITradeHubNotVerifyError
V9.withdrawFunds(1)        from f39f -> revert AITradeHubNotVerifyError
V9.performAutomation(1)    from f39f -> revert AITradeHubPermissionDeniedError (onlyOwner)
V8.claimServiceResults()   from f39f -> revert AITradeHubNotVerifyError
V7.claimServiceResults()   from f39f -> revert AITradeHubNotVerifyError
```

**Old swap `0x5e4ff9fadf96dd6e8a32a7b66d99faf0060d4c10`:** f39f is still whitelisted (`true`), but the swap holds **0 USDC / 0 TRAI**, the fund's allowance to it is **0/0**, and old TRAI has **no Pancake pair** against USDT/USDC/WBNB (`getPair = 0x0`). The V4/V5 path is capital-blocked, not merely unprofitable.

**Vault:** `getModuleCount = 8` (Swap ×2, TradingFund, StakeDist, MLM, FundV8, FundV2 + one more), all ACTIVE and gated; pass-2 verified a 2-of-2 multisig. No share-bug path can make the Vault pay: `_claimServiceResults` pays from the version contract's own balance, not the Vault.

---

## 4. The Oct-19 refill — full decode

- **Tx:** `0x2e9d4cf8dbf01898e2d6a77e5562a22469f4cbd26be1134ff781a73192b92177`
- **Block/time:** 128,595,562 / **2026-10-19 17:38:27 UTC**
- **Sender:** `0xa2f5b45e614a99fe6e653012275e8c3df472ccf7` (project EOA, whitelisted) → V9
- **Vault event:** `VaultModuleWithdrawalTokenEvent(module=0x442c…, baseToken=USDC, to=V9, amount=464,360.873076)`
- **V9 event:** `ServiceResultsDistributed(amount=464,360.873076, monthlyFee=7)` (topic `0x2e84…`)
- **Outflow:** 429,617.153873 USDC — 408,132.006263 to FundV2 in 14,902 transfers, 21,485.147610 to 396 users. FundV2 forwarded the 408k and has 0 balance.

This is a **fee-charging distribution**: at 14.5k contributors and a 7/1000 monthly fee, most of the gross profit is captured by the fund. It is not a seed for an attacker and does not change the gate.

---

## 5. What an attacker can/cannot do now

**Cannot (all verified by reverts above):**
- Claim V9/V8/V7 directly (`onlyVerified`).
- Withdraw ALPS principal from V9 (`onlyVerified`).
- Run `performAutomation` (`onlyOwner` in this bytecode; the pass-2 fork confirmed `PermissionDenied`).
- Use V6 (`swapContract = 0`).
- Use V4/V5 (old swap has no balances/allowances; TRAI has no market).
- Reach the Vault (modules only).

**If the gate reopens (the only re-arm):**
- A whitelisted attacker could deposit into **V8** (live, `swap = 0x7227`), migrate, then claim V9 — the recursion does not require V6 to be re-enabled (source-level; not fork-tested because the gate is closed). V6 is only the original root path.
- V9's current pot is **$34.8k** (falling). At `pps = 0.0370312721`, claiming it needs ~**938,800 ALPS** (~$94k at the Vault's 10 ALPS/USDC rate). After the 8% contribution fee, 3% buy + 3% sell, and 5% withdrawal + 5% claim fee, the net is only ~**$10–15k** — capital-gated and shrinking.
- The larger latent prize is the **$324,750.14** of f39f accounting claims in V8/V7. They are **unbacked** (V8/V7 hold $0), so they cannot be paid today. If V8/V7 are refilled, `claimServiceResults` would pay them; the V9 `recompound()` path can also convert imported earnings to ALPS via the fund if ALPS liquidity is available. The copycat tx already used the V8 claim once and lost money to the round trip/MEV; a patient attacker with the gate open could try again. This is **S/latent**, not live E-U.

---

## 6. Classification (USD, USDC $1.00)

| Category | USD | What |
|---|---:|---|
| **E-U** | **0.00** | Gate closed; all public keys false; all calls revert |
| **H-O** | **34,763.78** | V9 balance, claimable by whitelisted users (and routable by owner automation) |
| **P** | **5,912,217.00** | Vault (2-of-2 multisig + modules); plus fund EOA $21,042.72 and Swap $131.60 |
| **S** | **331,087.78** | V8 $151,557.34 + V7 $173,192.80 (unbacked f39f accounting) + V4/V5 $5,931.94 + V6 $405.71 |

The H-O figure is falling as fees/claims drain V9; it is not attacker-reachable. The S figure is an **accounting liability**, not cash.

---

## 7. Monitor trigger — exact

1. **Primary:** `cast call 0x7227d229be754fa49f416d48e8eaa121184b1721 "isInWhiteList(address)(bool)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` returns **true**.
2. **Any new public/test key:** the swap emits no whitelist event, so poll the bit for the 16 known test keys and watch owner txs to `0x7227`. Only two project EOAs are currently true.
3. **Funding:** V7/V8/V9 USDC > 0. V9 is already >0 (and changing); V7/V8 are 0. The refill trigger alone is **not** sufficient — the gate is binding.
4. **Root path:** V6 storage slot 3 (`swapContract`) != `0x0` (currently `0x0`).
5. On any trigger: fork at the trigger block, replay the pass-2 call tree, and net out 5% withdrawal + 3% swap fee + ALPS round trip + gas. The break-even is not the nominal claim.

**Monitoring commands:** `alpscon-latent/ci/run.sh` (read-only; prints gate, balances, stats) and `analysis/collect_state.py`.

---

## 8. Evidence index

| Item | Value |
|---|---|
| Attack tx | `0x824b83f94bdc2e69b81f1cb2dfdf9d4aeed066114e3de29e3af59bd2d9355fc2` (block 128,315,188, 2026-10-18 06:34:55 UTC) |
| Copycat/recompound tx | `0x351ea172363c28ca4e5f9c3e5477ffcb1278afabc86a11f8cbbf6c36336474` (block 128,319,580) |
| Whitelist removal | `0xa69e7250e48d8a1207a3e0ff6754185f6eb1625762ce7d5d234c6d1ea4ee03e8` (block 128,351,990, 11:10:59 UTC) |
| Oct-19 distribution | `0x2e9d4cf8dbf01898e2d6a77e5562a22469f4cbd26be1134ff781a73192b92177` (block 128,595,562, 17:38:27 UTC) |
| State snapshot | `analysis/state-128633400.json`; CI snapshot `analysis/state-<block>.json` |
| Refill decode | `analysis/refill.json` |
| Outflow logs | `analysis/v9_out.json.gz` (15,298 USDC Transfer logs, gzip) |
| Revert proof | `analysis/reverts.txt` |
| Collector | `analysis/collect_state.py`; `ci/run.sh` |
| CI | see `ci-log.txt` / `ci-artifacts/` (run URL recorded after the run) |

**Sources:** BscScan verified sources for V4–V9, Vault, Swap, funds (all verified); `eth_call`/`eth_getStorageAt` at the named blocks; pass-2 trace `zombie-hunt-iv/pass2/alpscon.md`. No fork transaction was sent; the gate/revert proof is live `eth_call` only. No CPU-heavy work, so no Foundry fork job was needed.

---

## 9. Caveats

- **Point-in-time:** V9's balance is a moving target ($34.76k at 22:22, $30.19k at 23:0x). Re-read before acting.
- **Whitelist is not enumerable:** the swap emits no `AddAddressToWhiteList` event. We tested the 16 standard public keys plus the two known project EOAs; an unknown/leaked whitelisted key cannot be excluded. That is the main residual unknown, as pass-2 noted.
- **Vault roles:** the 2-of-2 multisig/module gating is from pass-2; this pass re-read the module count but not every signer.
- **USD:** USDC $1.00, BSC USDC (18 decimals); ALPS has no independent market (only the Vault swap), so ALPS figures are not marked to a market.
- **Accounting claims:** the $151.5k/$173.2k are `user_earnings` values, not cash; V8/V7 balances are 0. Do not count them as extractable.

*Read-only research; no mainnet transactions. Prepared 2026-10-20.*
