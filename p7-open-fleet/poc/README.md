# P7-OPEN-FLEET / O3 — Lazy Summer `FleetCommander` donation-NAV-inflation PoC

Fork-only Foundry harness for the **2026-07-06 Lazy Summer (Summer.fi) FleetCommander
donation / NAV-inflation** bug class. Nothing here writes to mainnet: every test runs against a
read-only fork and all state changes live inside the in-memory EVM.

```
poc/
├── foundry.toml
├── lib/forge-std            # vendored (no `forge install`)
├── src/Interfaces.sol       # minimal IFleetCommander / IArk / IVault4626 surfaces
└── test/
    ├── Exploit_Repro.t.sol      # 2026-07-06 Ethereum reproduction + profit replay
    └── Generic_Donation.t.sol   # parameterised engine, wired to the Arbitrum candidate
```

Run (archive-capable RPCs required):

```bash
cd poc
FORK_RPC_URL=<eth-archive-rpc> ARB_RPC_URL=<arb-archive-rpc> forge test -vv
```

If `FORK_RPC_URL` / `ARB_RPC_URL` are unset the tests fall back to the public
`*.publicnode.com` endpoints, which **do not serve archive state** and will fail the fork — set
the env vars (the parent CI supplies them). Results land in `ci-out/`.

---

## Root cause

```
FleetCommander.totalAssets()  = Σ over getActiveArks() of ark.totalAssets()

SiloManagedVaultArk.totalAssets():                 // deployed source, verified
    uint256 shares = vault.balanceOf(address(this));
    if (shares > 0) assets = vault.convertToAssets(shares);
```

Any ERC-4626 share token that is **transferred directly to the ark** is instantly counted as NAV
at the external vault's `convertToAssets()` rate. No shares are minted, no `board()` call, no
access control — a bare `transfer` inflates the fleet's quoted NAV and therefore its PPS.

The donated shares are credited at NAV but are **not realisable**: for the exploited Silo vault
`vault.maxWithdraw(ark) == 0`, so the fleet's `withdrawableTotalAssets()` does not move. The
attacker redeems at the inflated PPS against the *other*, liquid arks.

Why a *fair-value* donation is not enough: donating a token acquired at its credited NAV is
loss-making by construction —

```
net = d·(credited − d)/(T + d) − credited  < 0     (credited > d)
```

so the bug is only *exploitable* when the ark's share token is obtainable **below** the NAV the
ark credits it at (illiquid / discounted / borrowed inventory).

---

## Test 1 — `Exploit_Repro.t.sol :: test_donationInflation_sensitivity`

Ethereum fork at block **25,471,347** (one block before the exploit tx `0x0db528c4…`). The
attacker's executor `0x0514F827…FC61` already holds vgUSDC at this block, so the donation is
sourced from it by impersonation (a pure transfer — deliberately **not** via `vault.deposit()`,
which would inject liquidity and un-freeze `maxWithdraw`, masking the bug).

Proves donation-sensitivity, the strongest minimal result:

| quantity | before | after |
|---|---|---|
| `ark.totalAssets()` | 0 | **1,821,149,917,443** |
| `fleet.totalAssets()` | 9,680,827,973,743 | 11,501,977,911,186 |
| fleet PPS (per 1e6 shares) | 1,066,484 | **1,267,110** |
| `fleet.withdrawableTotalAssets()` | 1,605,240,564,038 | **unchanged** |
| `vault.maxWithdraw(ark)` | 0 | **0** |

Donating `5e15` vgUSDC shares raised the ark's and the fleet's NAV by *exactly* the credited
`1,821,149,917,443` USDC and lifted the quoted PPS ~18.8%, while the realisable amount did not
budge. `vault.convertToAssets(1e18) = 364,229,983,488,787`.

## Test 2 — `Exploit_Repro.t.sol :: test_simplified_profit_replay`

A **deposit → donate → redeem** replay using state present at the fork block, asserting a net
profit. The donated inventory is the executor's own vgUSDC, acquired by the real attacker in a
*prior* transaction (Morpho USDT flash loan + Silo-market routing, ~5.3k trace nodes); that
acquisition leg is not replayed, so this test isolates the vulnerable core.

| step | value |
|---|---|
| attacker deposit | 50,000,000,000 USDC ($50,000) |
| shares received | 46,883,025,739 |
| donation (executor inventory) | 19,075,252,173,684,501 vgUSDC |
| credited NAV | 6,947,778,784,265 ($6.948M) |
| fleet NAV after donation | 16,678,606,758,008 |
| PPS after donation | 1,827,950 (from 1,066,484) |
| **redeemed** | **85,712,261,866** |
| **net profit** | **+35,712,261,866 USDC ($35,712.26)** |

Ground truth for the real tx (recorded, not replayed): donated `19,551,517,226,711,127` vgUSDC
credited at `7,121,298,201,390`; the attacker EOA `0x7BF71616…3BDCa` ended with
`6,016,754.998` DAI plus fleet shares (started at 0); fleet `withdrawableTotalAssets` fell from
`1,605,240,564,038` to `13`.

> Note on `maxDeposit`: `FleetCommander.maxDeposit(owner) = min(depositCap − totalAssets,
> asset.balanceOf(owner))`, so the attacker is funded before the cap check.

---

## Generic engine — `Generic_Donation.t.sol`

One parameterised engine (`FleetConfig` struct) that, for any `(fleet, ark)` pair: reads
NAV/supply/PPS/`withdrawableTotalAssets`/ark NAV/vault rate → optionally deposits → donates the
ark's share token to the ark → re-reads NAV/PPS → computes `maxExtractable` = buffer ark + liquid
arks → redeems and asserts a net profit **iff** (a) fleet deposits are open *and* (b) the ark's
share token is obtainable below its credited NAV. Otherwise it asserts `net == 0` and logs why.

* `test_generic_engine_ethereum_selftest` — Ethereum fleet, deposits open, discounted inventory
  available → `net = +35,712,261,866` (same as Test 2; proves the engine reproduces the exploit).
* `test_generic_arbitrum_live_candidate` — the live P7-O3 candidate.

### Arbitrum candidate — `test_generic_arbitrum_live_candidate`

Fork at Arbitrum block **518,241,570**:

| quantity | value |
|---|---|
| fleet `0x4F63cfEa…bb58` `totalAssets` | 1,250,795,250 ($1,250.80) |
| fleet PPS (per 1e6 shares) | 982 ($0.982 — fleet is already underwater) |
| fleet `withdrawableTotalAssets` | **750,014,057** |
| buffer ark `0xbb79242B…1419` | 414,892,848 ($414.89) |
| Sky sUSDC ark `0x4EF91E09…3b74` | 335,121,209 ($335.12) |
| capped ark `0x125dAE47…783C` `totalAssets` | 500,781,193 (depositCap 0) |
| ark vault `0x2BA39e53…f1ee` `convertToAssets(1e18)` | 1,861 |
| `vault.maxWithdraw(ark)` | **0** (illiquid, same as Ethereum) |

The engine still demonstrates the bug is structurally present — donating `1e21` vgUSDC shares
credits `1,861,451` USDC and lifts NAV `1,250,795,250 → 1,252,656,701` (PPS 982 → 984) while
`withdrawableTotalAssets` stays at `750,014,057` — **but the exploit yields $0**:

1. **No redeemable shares.** `fleet.maxDeposit(attacker) == 0` at this block — the fleet is closed
   to deposits, so an attacker cannot obtain fleet shares to redeem (they would have to source
   them on the open market first).
2. **No below-NAV acquisition venue.** The ark's share token can only be minted at its credited
   NAV (`vault.deposit`, `maxWithdraw == 0`), and no market/lending venue for it was found on
   Arbitrum. Donating at NAV is loss-making, so `net = 0`.

**Max extractable for the Arbitrum candidate** (the ceiling *if* both conditions were met) is the
fleet's realisable liquidity:

```
buffer 414,892,848 + Sky sUSDC 335,121,209 = 750,014,057 USDC  (== withdrawableTotalAssets)
```

minus the cost of acquiring the donated share token below NAV and gas. The test asserts
`maxExtractable == 750,014,057` and that it equals `withdrawableTotalAssets`, and then asserts
`net == 0` for the reasons above.

---

## Notes / caveats

* The donation is sourced via `vm.prank` on a real holder (the attacker's executor on Ethereum;
  the largest vgUSDC holder on Arbitrum) and via `deal()` on the fleet asset. These are harness
  devices; they do not model the attacker's acquisition cost, which is why the replay isolates
  the deposit→donate→redeem core.
* `vm.warp` is used to clear the fleet's 600 s redemption cooldown.
* Tests must run against an **archive** RPC: `FORK_RPC_URL` (Ethereum) and `ARB_RPC_URL`
  (Arbitrum). No API keys or keyed URLs are stored in this repository.
* Each suite finishes in well under the 25-minute budget (fork-state fetches dominate; the fork
  disk cache makes re-runs seconds).
