# BeraFarm — Oct-9 2026 incident reconstruction (ZH4-06)

Read-only; no mainnet transactions. Fork tests only. All blocks on Berachain (80094).

## 1. Verdict

The Oct-9 attack is a **RewardVault delegated-stake NAV-inflation** attack against the
BeraFarm strategy layer. It was stopped pre-execution by Kodiak's automated island pause,
then fully closed by BeraFarm's own protocol pause + two strategy upgrades. The current
build (Kodiak `0xc6865dc8`, Bend siblings `0xee965e0a`) is **not exploitable** by this
vector; a fork replay of the full recipe on the current bytecode is a net **loss** of
264 HONEY (gas/fees excluded), versus **+77,558 HONEY** on the pre-incident bytecode.

## 2. Target set and roles

| Component | Address | Role |
|---|---|---|
| TrancheVault0 (BUSD/HONEY) | `0x4a3c8Fdd55017773fEe33dE4aa7e12dD60B0A054` | holds senior/junior claims; permissionless deposit/withdraw (KYC whitelist off) |
| StrategyManager0 | `0x9546b34291393fb247db7d4C677f1394D4BbE0DD` | deposits/withdraws across 4 strategies |
| Kodiak strategy proxy | `0x1Ce23321A72F2dae96809cC6192f053A7aD5D8e4` | island LP + RewardVault gauge |
| HubBend-1 / HubBend-2 | `0xC8f67DD8…`, `0xa13e0a5f…` | Bend receipt token + RewardVault gauge |
| Dolomite | `0x7F41C51A…` | no gauge (not affected) |
| Kodiak island (USDe/HONEY) | `0xE5A2ab5D2fb268E5fF43A5564e44c3309609aFF9` | Kodiak LP token; mint/burn pausable |
| Kodiak island router | `0x679a7C63FC83b6A4D9C1F931891d705483d4791F` | `addLiquidity` → `island.mint` (paused Oct 9) |
| Kodiak swap router | `0xe301E48F77963D3F7DbD2a4796962Bd7f3867Fb4` | V3 router used for HONEY/USDe |
| Kodiak gauge (RewardVault) | `0x75Da1D58A8d97f7b626224E7E71fa44DB13689f2` | stake island LP; **public delegateStake** |
| Bend-1 gauge | `0xDb6e93Cd7BddC45EbC411619792fc5f977316c38` | stake Bend receipt; public delegateStake |
| Bend-2 gauge | `0xA2CBAac782bDeCC103b2d2F746b6330525025098` | stake Bend receipt; public delegateStake |

## 3. Pre-incident state (block 27,270,000, 2026-10-09 ~15:00 UTC)

Vault0 NAV **256,187.3 HONEY** (senior book 247,713.8, junior book 8,421.8; junior supply
8,038.7). Strategy NAVs: Bend-1 76,818.8, Bend-2 90,067.1, Dolomite 12,759.2, Kodiak 76,542.2.
Kodiak strategy: 552,650.0 island LP = 0.1385 HONEY/share. Gauge delegate total: 0.
Protocol not paused; deposits/withdrawals open; senior entry fee 1%, junior entry 0,
junior exit 1% (<7 days); vault swap slippage 2%, LP slippage 5%.

## 4. The vulnerable mechanism

1. `RewardVault.delegateStake(account, amount)` is **permissionless** and credits
   `_accountInfo[account].balance` (so `balanceOf(account)`) while tracking the delegator's
   own claim in `_delegateStake[account].stakedByDelegate[msg.sender]`.
   `delegateWithdraw(account, amount)` lets that delegator pull it back at any time.
2. Pre-incident strategies computed NAV as `_getUnderlyingBalance(hubVault.balanceOf(this))`.
   Delegated stake is therefore counted as the strategy's assets, even though the strategy
   cannot withdraw it (`RewardVault.withdraw` has `checkSelfStakedBalance`).
3. `TrancheVault._updateInvestment()` runs on every deposit/withdraw:
   `currentStrategyBalance > previousCurrentStrategyBalance` is booked as **profit** —
   senior gets its block-rate claim, the rest is credited to the **junior** tranche.
4. Attacker: deposit junior → mint/delegate island LP (or Bend receipt) to the strategy →
   withdraw junior at the inflated rate. The fake profit is unfunded; the payout comes from
   real assets of the other strategies, capped by the strategy's **self-staked** balance
   (the only part `hubVault.withdraw` can release).

Fork-proven per-strategy NAV deltas for a +10,000 delegated stake:
Kodiak 76,542.2 → 77,927.2 (+1,385.0 HONEY), Bend-1 76,818.8 → 86,903.3 (+10,084.5),
Bend-2 90,067.1 → 100,204.3 (+10,137.2).

## 5. Reconstruction of the Oct-9 attempt

| Time (UTC) | Block | Event |
|---|---|---|
| Oct 9 15:30 | 27,272,559 | last normal Kodiak keeper `getReward` |
| **Oct 9 20:29:36** | **27,281,530** | Kodiak/Hypernative bulk-pause of ~40 islands incl. `0xE5A2ab5D`; "malicious contract targeting an external vault provider" — the attacker's exploit had not landed |
| Oct 10 03:31 | 27,294,175 | keeper `getReward` fails inside `island.mint` with `Pausable: paused` (route closed) |
| Oct 10 07:50:16 | 27,301,950 | **BeraFarm protocol paused** by owner Safe |
| Oct 10 08:51 / 09:01:04 | 27,303,737 / 27,304,074 | new Kodiak strategy impl `0x807982bb` deployed/installed |
| Oct 10 08:58:16 | 27,303,990 | Kodiak unpauses all islands (route re-opened, but BeraFarm is paused) |
| Oct 11 09:55:38 | 27,348,911 | Kodiak strategy → `0xc6865dc8`; swap controller → `0x2be0125f` |
| Oct 11 10:10:50 | 27,349,367 | BeraFarm unpauses |

No attacker transaction was mined. The complete tx lists of vault0/vault1/strategy/
controller/factory/registry/oracle contain no attacker call in the incident window; the
only on-chain artefacts are the pause/unpause and the upgrades. The stop was pre-execution
(simulation/pending-tx detection by Hypernative).

Why the Kodiak pause mattered: the attacker needed Kodiak **island LP** to delegate to the
Kodiak strategy, and island LP could be minted through `islandRouter.addLiquidity` →
`island.mint` (`whenNotPaused`). The pause blocked that leg. Note the Bend strategies were
**not** dependent on Kodiak: their stake token is a Bend receipt token. That route stayed
open until BeraFarm's own protocol pause 11 hours later; the pause (deposits/withdraws
blocked) plus the Oct-10/11 upgrades closed it before the Kodiak route re-opened.

## 6. Loss estimate reconciliation

The three gauge-staking strategies held **243,428 HONEY** of the vault's 256,187 HONEY NAV
at block 27,270,000 (~95%). The incident reports' "at least $250K" matches this exposure.
The Kodiak leg alone is fork-proven at **+77,558 HONEY** net for the attacker (≈ $76.2k at
$0.983/HONEY), consistent with the per-strategy cap ≈ the strategy's self-staked value.
A full attack across Bend-1 + Bend-2 + Kodiak could in principle approach the ~$243k
gauge-staked NAV; the Bend legs were not drained in a single fork PoC (that would require
sourcing each receipt token), but their pre-patch NAV inflation is measured on-chain.

## 7. Post-incident route state (current)

Kodiak island `paused() == false`; last pause ended Oct 10 08:58; no re-pause. Island TVL
649,109 USDe + 1,253,491 HONEY, 13.74m shares, tick 4, range [-200, 110]. The route is
open, but the strategy no longer counts delegated stake, so the exploit replay is a loss.

## 8. What would re-arm it

- Any strategy proxy upgraded back to a `balanceOf`-only NAV implementation
  (`0x36bfa55a` / `0x64812160` class).
- A new strategy family that stakes in a RewardVault (or any contract with a
  stake-on-behalf/delegate primitive) without subtracting the delegated amount.
- A reward-vault change that makes `delegateTotalStaked` diverge from `balanceOf`
  (e.g., a new delegation primitive not mirrored in the strategy).
