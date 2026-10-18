# Sophon Farm (Sophon + Ethereum) — boosted points farm; no reward token, $2.80M owner-custodial

**Date:** 2026-10-18 · **Chains:** Sophon (50104), Ethereum (1) · **Status:** read-only; no transactions. Foundry logic model only.

## TL;DR

| Question | Answer |
|---|---|
| Live TVL (priced assets) | **$2,801,393.22** L2 + $33.06 L1 Pendle exception |
| L2 farm | Proxy `0x5753fBeC29De6E2b56F73f7d7786e9f0d34897bb`; impl `0xbd0AAfC995dAB4DC868323BEc81B189De2556012` (`SophonFarmingL2`, verified) |
| External unprivileged extraction (E-U) | **$0** |
| Confidence | **High** — verified source, 25 pools enumerated, `eth_call` probes, 6/6 logic-model tests |
| Holder self-service (H-O) | **$2,801,340.07** |
| Privileged (P) | **$2,801,393.22** — owner Safe 2-of-6 can `_emergencyRescue`/upgrade; merkle admin Safe 3-of-7 can re-root |
| Stuck (S) | **$86.50** — PEPE pool is 22,304,710.35 PEPE short of liabilities |

**Headline:** Sophon Farm is a **points** farm, not a token-emitting MasterChef. There is no reward token in the ABI or balances. Deposits are disabled (`endBlock 14,476,600`), withdrawals are hard-bounded by each user's `depositAmount`, and the only permissionless calls (`massUpdatePools`, `claimMultiple`) move no tokens or pay only the Merkle leaf user. The real risk is privileged: the owner Safe can sweep all L2 LP tokens via `_emergencyRescue` (added in the current implementation), and the merkle-admin Safe can set a new root.

## Live state

* Sophon block **29,675,399** (snapshot at 29,675,272; no Deposit/Withdraw/PoolUpdated events after).
* `poolLength=25`, `pointsPerBlock=1e19`, `endBlock=14,476,600`, `endBlockForWithdrawals=46,012,600`, `isFarmingEnded=true`, `isWithdrawPeriodEnded=false`.
* `totalValue = 13,440,291,919,490,392,418,772,600` (sum of `poolValue.lastValue`).
* Priced assets **$2,801,393.22**; priced deposit liabilities **$2,801,479.43**; the **$86.21** gap is exactly the PEPE pool (farm balance 2,711,901,637.74 vs depositAmount 2,734,206,348.09 PEPE).
* A real sDAI depositor `0xc09e64cc…1a68` has `depositAmount=1.1e16`; `withdraw(0,1)` and `withdraw(0,max)` simulate successfully; `withdraw(0,1.1e16+1)` reverts `WithdrawTooHigh(1.1e16)`.
* All `priceFeeds.getPrice(lpToken)` return 0 now (Stork stale), but emissions ended long before; withdrawals still work.

## Why E-U is $0

| Path | Result |
|---|---|
| `withdraw(pid, amount)` | bounded by `user.depositAmount`; `depositAmount` is created only by `deposit()` (disabled) or `updateUserInfo()` (`msg.sender == immutable MERKLE`) |
| Same-block deposit + withdraw | earns zero points; `deposit` calls `massUpdatePools` before increasing `pool.amount` |
| Donation / share inflation | `pool.amount` is an internal 1:1 counter, not `balanceOf`-derived; no share math |
| `claimMultiple` with a bogus proof | reverts `InvalidMerkleProof`; `hasClaimed` set before the external call; receiver forced to the leaf user |
| `updateUserInfo` from an outsider | reverts `OnlyMerkle` |
| `transferPoints` | reverts `TransferNotAllowed` |
| `_emergencyRescue` / `replaceImplementation` / `setPointsPerBlock` | `OwnableUnauthorizedAccount` for an outsider |
| `submitLP` | dead — all `heldProceeds` are 0 and farm→router allowances are 0 |

The only permissionless state-changing calls are `massUpdatePools` (no token movement) and `claimMultiple` (proof-gated, self-receiver).

## Privileged (P) — dominant risk

* **Farm owner** `0xa3b1f968b608642dD16d7Fd31bEc0B2c915908dB` is a **Safe v1.4.1, 2-of-6**. The current implementation `0xbd0a…6012` (upgrade block 29,115,213) added `_emergencyRescue(address[],address)`; an `eth_call` from the Safe with LP tokens returns `0x`, proving it can sweep all **$2.80M** of L2 LP deposits to any receiver. It can also `replaceImplementation`.
* **Merkle admin / price-feed owner** `0x902767c9e11188C985eB3494ee469E53f1b6de53` is a **3-of-7 Safe**. `setMerkleRoot` and `grantRole` simulate successfully; a crafted root credits arbitrary `depositAmount`, and `unclaim(user,pid)` (`ADMIN_ROLE`) allows replay of an existing leaf.
* **L1 owner** `0x3b181838Ae9DB831C17237FAbD7c10801Dd49fcD` is a **3-of-5 Safe**; L1 balances are ~0 (only 8.55M PEPE for `PENDLE_EXCEPTION` + dust).

## Latent bug (not E-U today)

`_updatePool` keeps a stale `pv.lastValue` when a pool's amount hits 0 or its price is stale, diluting active pools (the logic model shows ~33% dilution). It did not affect the live emission period (sampled feeds were live through `endBlock`), and no zero-amount pool currently has a non-zero `lastValue`. This becomes relevant only if the owner re-enables emissions via upgrade.

## Verdict

* **E-U: $0** (high confidence).
* **H-O: $2,801,340.07** — users can withdraw their credited deposits; the PEPE pool users are $86.21 short.
* **P: $2,801,393.22** — 2-of-6 owner Safe can sweep/upgrade; 3-of-7 merkle admin can re-root. P and H-O overlap, not additive.
* **S: $86.50** — PEPE shortfall plus L1 dust.

## Caveats

* The Foundry suite is a **source-level logic model**, not a zkEVM fork. Foundry/revm cannot execute Sophon zkEVM bytecode; live conclusions rely on `eth_call` against the deployed contract + verified source.
* USD values use DefiLlama-implied prices; DL's own TVL is $2,769,518.37 (Sophon) + $33.34 (Ethereum), excluding USDC/USDT and unpriced LP dust.
* `PENDLE_EXCEPTION` is the Sourcify-verified `PendleSophonFarmingSY`; its `_redeem` calls the farm's `withdraw`, so its $33.06 is H-O subject to Pendle liquidity.
* The owner/merkle authorities were simulated with `eth_call` from the Safe addresses; this proves contract-level authority, not signer intent.

## Files

* **Full report:** [`analysis/NOTES.md`](analysis/NOTES.md)
* `analysis/evidence/` — verified sources, ABIs, pool dumps, role/upgrade logs, DL TVL.
* `poc/` — self-contained Foundry math model (`RewardMathModel.sol`, `RewardMath.t.sol`), **6/6 PASS** locally.

**Read-only; no transactions were signed or sent.**
