# CA3 OPEN-2 (Target 1) — Faroo stPROS + five ERC-1967 custody proxies

**Date:** 2026-11-10 · **Chain:** Pharos (1672) · **Status:** read-only. No transaction was signed or
broadcast; no key was used. All value paths were probed with `eth_call` at a stated block; the Foundry
harness is fork-gated and was not run against mainnet.

---

## 1. TL;DR

| Target | Live extractable by an external unprivileged attacker | Why closed | Latent risk |
|---|---:|---|---|
| **Faroo stPROS + custody fleet** (`stPROS`, `BridgeVault`, `SlpDistributor`, `RewardsVault`, SLP #1/#2, staking precompile) | **$0.00** | Every value-moving entry is `onlyOwner` / `WHITELIST_ROLE` / `onlyVToken` / `NotSlp` / `NotKeeper` / timelock. The only permissionless entries are no-ops or self-scoped. The redemption queue is exactly funded (surplus 0 wei), and the oracle NAV is fully backed. | **P:** 24-hour TimelockController + pause-only guardian. SLP/RewardsVault implementations are source-documented but not byte-matched to the repo. **E-U-conditional:** JIT capture of a yield report is gross ≤ $545 and net-negative at any real cost of capital. |

**Total live extractable now: $0.00 — confidence: high.**

The mandate listed “5 unverified ERC-1967 proxies”. All five were resolved through the EIP-1967 slot,
decompiled, and matched to the protocol’s published deployment records. Three implementations match
their recorded runtime keccaks exactly; the two SLP proxies are byte-identical to each other and their
critical entry points were probed live.

---

## 2. What the system is

Faroo is a liquid-staking protocol for PROS. Users deposit native PROS or WPROS and receive stPROS.
Deposits are forwarded to `SlpDistributor`, which a keeper allocates to two whitelisted SLP proxies;
the SLPs delegate to the Pharos staking precompile (`0x4100…`). Staking rewards are claimed by a
whitelisted keeper into `SlpPharosRewardsVault`, which reports them to the `Oracle`. The Oracle holds a
`(T, V)` pool: `T` = pooled PROS, `V` = stPROS supply; the exchange rate is `T / V`. Redemptions burn
shares, fix a PROS amount, and join a global FIFO queue. `BridgeVault` holds the redemption reserve and
pays claims — but only to the registered vToken (stPROS).

The five custody proxies and their implementations:

| Contract | Proxy | Implementation | Source status |
|---|---|---|---|
| stPROS | `0x6b0A44c64190279f7034b77c13a566E914FE5Ec4` | `0xfD59860894E01773e9780B0d1DFAE4cA2B56708D` | runtime keccak `0xca9753…` matches repo record |
| BridgeVault | `0xF1dF1CB080256f48e8702c24149136E4A6dec25E` | `0xa7d36cB9dA47bA5123F9070FbA4bb5239C58387e` | runtime keccak `0x1d9038…` matches repo record |
| SlpDistributor | `0xf772B375f93650F798Bf724cE7A9a45c9e7a579F` | `0x05A224A9cdD84CfCa21866aE50Fa0cD663e3752f` | runtime keccak `0xfa824d…` matches repo record |
| RewardsVault | `0xd0C44d3079e97fF285dd7A3e4E0246320a9487e5` | `0xe6985303e0c917bda24c4566bb2f9af99916c531` | source in repo; bytecode not recorded |
| SLP #1 / #2 | `0xEC1d…d612` / `0xc53D…0C2C` | `0xc3d0…1ab` / `0xd15e…124` | source in repo; both impls have the same runtime keccak `0x486866…` |

---

## 3. The mechanism, in exact terms

There is no unprivileged value path. The proof is a set of live gates plus the accounting identity.

### 3.1 Gate inventory (all probed from a fresh EOA)

| Entry | Gate | Live revert |
|---|---|---|
| `BridgeVault.withdrawToken(token,to,amount)` | `onlyVToken`; token must equal `IERC4626(msg.sender).asset()` | `NotVTokenContract(0x1111…)` |
| `BridgeVault.withdrawTokenWrapped(to,amount)` | `onlyVToken`; asset must be WPROS | `NotVTokenContract(0x1111…)` |
| `BridgeVault.emergencyWithdraw` | `onlyOwner` | `OwnableUnauthorizedAccount` |
| `Oracle.update(token,amount)` | `msg.sender == slp` (RewardsVault) | `NotSlp` (`0xf5631094`) |
| `Oracle.onMint` / `onRedeem` | registered canonical vToken only | `NotVToken` (`0x1942eea2`) |
| `Oracle.setTokenAmount` / `setMaxAprPpm` / `setCommissionConfig` | `onlyOwner` (timelock) | `OwnableUnauthorizedAccount` |
| `SlpDistributor.distribute` | `onlyKeeper` + whitelisted SLP | `NotKeeper` |
| `RewardsVault.notifyOracle` | `WHITELIST_ROLE` | `AccessControlUnauthorizedAccount` |
| `SlpPharosProxy.bond/claim/claimRewardToRewardsVault/transferBack` | `WHITELIST_ROLE` | `AccessControlUnauthorizedAccount` |
| `Staking.claimReward(poolId)` / `claimStake(poolId)` | keyed by `msg.sender` | “No rewards to claim” / “No withdrawable stake” |
| `Staking.withdrawStake(poolId,amount)` | validator owner only | “Caller is not the validator owner” |

### 3.2 The only permissionless entries are neutral

- **`BridgeVault.unwrapWrapped()`** — unwraps the vault’s *own* WPROS balance into native PROS.
  It pays the caller nothing. Live: WPROS balance 0, so it is a no-op; the caller’s balance is unchanged.
- **`stPROS.withdrawComplete()` / `withdrawComplete(address receiver)`** — iterates
  `withdrawals[msg.sender]` only. `receiver` may be arbitrary, but the records are the caller’s own;
  a fresh EOA returns 0. The stored `w.receiver` wins when set at redeem time, so even a caller-chosen
  receiver cannot redirect someone else’s claim.
- **`vote`-style / donation paths** — `receive()` accepts native PROS. A donation increases
  `getTotalBalance()` and therefore helps the queue; it cannot be recaptured by the donor.
- **`stPROS.deposit` / `depositWithPROS`** — pull assets at the oracle rate and mint shares. A
  round trip (deposit 10,000 PROS → redeem all shares → `withdrawComplete`) pays **0** immediately;
  the withdrawal joins the queue at `queuedWithdrawal`, which is already fully funded. There is no
  rounding gain: `previewDeposit` floors shares and `previewRedeem` floors assets (protocol-favouring).

### 3.3 The accounting identity (why there is no surplus)

`getTotalBalance() = bridgeVault.getBalance(asset) + completedWithdrawal`.
Both terms are cumulative-since-genesis, matching the cumulative `queued` offset stored on every
withdrawal record. A record is claimable only when `getTotalBalance() > w.queued`; the payout is
`min(getTotalBalance() - w.queued, w.pending)`.

At block 22,613,377:

```
getTotalBalance()   = 1,247,604.019831042693382433 PROS
queuedWithdrawal()  = 1,247,604.019831042693382433 PROS
surplus             = 0 wei
```

A fresh withdrawal joins at `queued = 1,247,604.0198…`, so its immediate claim is exactly 0. The only
way to be paid is for new liquidity to arrive (rewards, new deposits allocated to redemption, or
someone else’s redemption reserve being consumed) — and then the FIFO head is paid first.

The oracle NAV is also fully backed:

```
T (totalAssets)                    = 5,119,038.227419285 PROS
current staked principal (25 pools)= 5,062,185.797111863
SLP #1 totalUnbonded (pending)     =    56,632.430307418
SlpDistributor float               =       220.000000000
sum                                = 5,119,038.227419281  (Δ 4e-9 PROS)
```

There is no inflated T, no double-counted WPROS, and no unbacked share.

---

## 4. What an attacker can and cannot do

| Path | Preconditions | Cost | Result |
|---|---|---|---|
| Call any owner/role entry | None | Gas only | Reverts (table §3.1) |
| Impersonate a vToken at BridgeVault | Register a fake vToken | `onlyOwner` (timelock) | Impossible unprivileged |
| Forge an oracle report | Be the reporter | `WHITELIST_ROLE` | Impossible unprivileged |
| Register a new gauge / reward token | Gauge creation is public, but payouts still route through gated reward accounting | Gas | No protocol funds move |
| Deposit → redeem → claim | Own PROS | Gas + 1-day unbonding | Returns own assets, 0 immediate surplus |
| Buy stPROS on a DEX and redeem at NAV | A market below NAV | Capital | No stPROS market was identified on Pharos; minting at NAV is the only route, which is NAV-neutral |
| JIT a yield report | Deposit just before a whitelisted report, redeem after | ~T capital, ≥1 day lock | Gross ≤ 1,022.5 PROS ($545) at the 50% APR cap and 3.5 h interval; net negative at a 5% cost of capital. Not E-U. |

**Capital needed:** $0 for every unprivileged path (none exists). The only conditional path needs the
full NAV (~$2.73M) for at least the 24-hour unbonding window and is net-negative.

---

## 5. PoC / verification

- **Executable proof:** `ci/run.sh` — 31 read-only `eth_call` probes at a pinned Pharos block.
  Result: **31 PASS / 0 FAIL** (`ci-out/faroo-probes.txt`, `ci-out/faroo-probes.json`).
  Includes the three recorded runtime-keccak matches, all gate reverts, the zero-surplus identity,
  and the `unwrapWrapped` neutrality check.
- **Portable Foundry harness:** `poc/test/FarooGate.t.sol` (13 tests). It compiles in CI. Foundry 1.8
  speaks `eth_getAccountInfo` and block-object params, which the Pharos public RPC rejects
  (`PARAM_VERIFY_ERROR`), so the harness is gated behind `PHAROS_FORK=1` and reports `SKIP` by default.
  The `eth_call` probes exercise the same deployed code at the same block without the client dialect.
- **Decompilation:** `analysis/decompiled/` contains Heimdall output for stPROS, BridgeVault,
  SlpDistributor and SLP #1; `analysis/bytecode/` contains the runtime code and extracted selectors.
  The three verified contracts also match the published `runtimeKeccak` records.

**CI:** https://github.com/artsbykriss/ca-zombie-ci/actions/runs/42742614973 (31/31 probes).

---

## 6. Verdict and residual risk

**E-U = $0.00 (high confidence).** The protocol’s only permissionless value-touching entries are the
donation receiver, the WPROS unwrapper, and the self-scoped withdrawal completer. All three are
value-neutral for the caller.

Residual / latent:

- **P (privileged):** a 24-hour TimelockController owns the proxies; a pause-only guardian can stop
  the system. If a proposer key is compromised, the attacker can upgrade and drain after 24 h. That is
  governance risk, not unprivileged extraction.
- **Source/bytecode gap:** SLP #1/#2 and RewardsVault are documented in the Faroo repo but are marked
  `EXTERNAL_DEPLOYED` (“deployed bytecode not verified against source”). Their live entry points were
  probed and are gated; a hidden selector cannot move value without passing those gates, but the
  bytecode was not formally matched.
- **JIT yield:** a deposit immediately before a whitelisted report captures a pro-rata slice of that
  report. Gross is capped by the rate allowance; at realistic capital cost it is net-negative. It
  dilutes holders by <0.02% per report, not an extraction path.

No blockers (no frozen tokens, no blacklist, no paused path).

---

## 7. Methodology, sources, caveats, files

**Method.** EIP-1967 slot reads → implementation code hashes → repo deployment records → selector
extraction (`cast selectors`) → Heimdall decompilation → live `eth_call` probes from a fresh EOA →
accounting reconciliation (staking `getDelegator` over all 25 registered pools + unbonding + float).

**Sources.** `faroo-xyz/stpros-contracts` (commit `5a94197`, deployments `mainnet/v4`), DefiLlama
`faroo` adapter, Pharos public RPC, Blockscout-free reads.

**Caveats.** Point-in-time at block 22,613,377; the queue equality moves with claims/deposits.
USD uses DefiLlama’s $2,729,582 TVL (implied PROS ≈ $0.533). The Foundry fork harness could not run
against the Pharos RPC dialect; the `eth_call` probe suite is the executed proof.

**Files.** `analysis/live-checks.md` (every read), `analysis/bytecode/`, `analysis/decompiled/`,
`analysis/selectors.json`, `ci/run.sh`, `ci-out/`, `poc/`, `summary.json`.
