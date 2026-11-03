# CA2 LOW-tail A — three "LOW / $0" findings re-verified

**Date:** 2026-11-03 · **Chains:** CORE (1116), Ethereum (1) · **Status:** read-only; no transactions sent.
**Mission:** independently confirm or refute CA2's LOW ratings for b14g, Vara Bridge and Hifi, with the
live blocking condition and exact gate for each.

## Consolidated verdict

| # | Target | CA2 rating | This review | E-U now | E-U conditional | Confidence |
|---|---|---|---|---|---|---|
| 1 | **b14g** Merge Marketplace batch withdraw (CORE) | LOW / $0 | **CONFIRMED $0** | $0.00 | ≤$331.01 if unpaused | high |
| 2 | **Vara Bridge** forged Plonk proof (Ethereum) | LOW / ~$12 | **CONFIRMED LOW** | $0.00 | $12.05, ≤$164 ceiling | high on $12; medium on $164 |
| 3 | **Hifi** `harvestIdle` + hijacked Governor (Ethereum) | LOW / $0 | **CONFIRMED $0** | $0.00 | $0.00 | high |

**Total live extractable now: $0.00.** Total conditional if every temporary gate lapsed: **$343.06**
(b14g receiver dust $331.01 + Vara ERC20Manager $12.05), still 29× below the $10k bar.

## Per-target headlines

### 1. b14g — paused, not patched ($0 now)

Snapshot CORE block **40,132,817**. Marketplace `0x04EA…8967` impl `0x621eb85e…`, CoreVault
`0xee21…B83F` impl `0x8c6046a4…`, FairShare `0x13E3…04b1` impl `0x5877b346…` all have
`paused() = 1`. The batch selector `0x94923c60` reverts `Pausable: paused`; `unpause()` is owner-only
(2-of-4 Safe `0xff2a4d8f…`). The 97.05M CORE is already gone (CoreAgent 211.05M now vs 315.92M
pre-exploit); `totalCoreStake()` is stale. The vulnerability is neutralised only by the pause flag — no
code fix — so unpausing reopens it, with a latent upper bound of ~$331 of native dust at the 91 receivers.
Read: [`b14g/README.md`](../b14g/README.md).

### 2. Vara Bridge — live bug, temporary challenge, $12 cap ($0 now)

Snapshot Ethereum block **26,334,420**. MessageQueue impl `0xadf9f599…` (last upgrade 2026-09-03, before
the 2026-09-04 circuit fix) and verifier `0xb7142e82…` are unchanged. `paused() = false`,
`isEmergencyStopped() = false`, but **`isChallengingRoot() = true`**: latest challenge at block
26,333,446 expires **2026-11-05 09:42:23 UTC**. `submitMerkleRoot` from a stranger reverts
`ChallengeRoot()` (`0x4df7989c`). ERC20Manager holds **1.000000 USDC + 11.045094 USDT = $12.05**;
wVARA has no DEX liquidity. The freeze is renewable and has lapsed before, so $12.05 is the real
exposure when unfrozen. Read: [`vara-bridge/README.md`](../vara-bridge/README.md).

### 3. Hifi — malicious impl installed, protocol empty ($0 now)

Snapshot Ethereum block **26,334,420**. BalanceSheet impl is still the attacker's `0xb77baf19…`;
`harvestIdle(WETH)` is callable but reverts `BalanceSheet__HarvestIdleZero()` (`0x40eaba5a`). Even when
funded, it pays only the hardcoded attacker Safe `0x14856a1E…63Fd`, never the caller. BalanceSheet/Safe/
Timelock/Governor/Fintroller hold 0 ETH and no material tokens (1 HEX, 50 SPARK, 17 SHEETp, no markets).
Proposal 22 is Active with 0 votes and needs 3,339,677 HIFI quorum; HIFI DEX liquidity is $334. Read:
[`hifi/README.md`](../hifi/README.md).

## What was independently verified vs. carried over

- **b14g:** live pause flags, owner/Safe, selector reverts, impl slots, all receiver balances (decoded
  from the exploit calldata), CoreAgent/attacker balances. The historical exploit mechanics and the
  pre-exploit impl equality come from the CA2 report (CORE archive state for 40,042,124 is no longer
  served by the public endpoint).
- **Vara Bridge:** live challenge state and expiry, `submitMerkleRoot`/`challengeRoot` reverts, verifier
  address, absence of upgrades after 2026-09-03, all ERC20Manager balances, wVARA supply and every DEX
  pair read. The circuit-underconstraint root cause (commit `68d699e`) and the 2026-10-19/20 $12,776
  exploit are from CA2; no new proof was generated.
- **Hifi:** live impl slot, harvestIdle revert, full balance sweep, proposal 21/22 state, quorum,
  timelock/proxyadmin/minter roles, HIFI and MFT liquidity. The proposal-21 execution history is from
  CA2/Spreek; this review corrected the prior "MFT has no DEX market" statement (a tiny UniV2 pair
  exists but the swap is value-destructive).

## Category totals

| Category | USD | Notes |
|---|---|---|
| **E-U** | **0.00** | all three are blocked now |
| **E-U-conditional** | **343.06** | b14g $331.01 + Vara $12.05, only after pause/challenge lapse |
| **H-O** | 0.00 | no holder self-service value identified |
| **P** | ≤$334.43 realizable | Hifi governance (token-gated); b14g owner Safe can unpause; Vara admin can fix |
| **S** | 0.00 | no permanently stuck value proven |

## CI

GitHub Actions `artsbykriss/ca-zombie-ci`, workflow `poc.yml`, folder `ca2-low-a`:
`ci/run.sh` re-reads all three states with `cast` at pinned blocks and writes
`ci-out/live_state.json`. Run URL: see `ci-log.txt` / the run printed by `ci/ci-run.sh ca2-low-a`.

**Files:** [`b14g/`](../b14g/) · [`vara-bridge/`](../vara-bridge/) · [`hifi/`](../hifi/) ·
this folder (`summary.json`, `ci/run.sh`, `ci-out/live_state.json`).
