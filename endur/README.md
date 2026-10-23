# ZH4-PASS3-OPEN-9 — Endur (xSTRK / xyBTCs) liquid-staking protocol on Starknet: live unprivileged-extraction assessment

**Status:** read-only live assessment + pinned-block CI evidence. **No mainnet transactions, no keys, no
state changes.** All reads are `starknet_call` / `starknet_getStorageAt` / `starknet_traceTransaction` against
keyless public RPCs at an explicit Starknet block. (Starknet has no EVM fork; the PoC is therefore a
read-only keyless probe, not a Foundry fork test — see §6.)

**Finding id:** `ZH4-PASS3-OPEN-9-ENDUR` (pass3-recon OPEN #9, `lane-lst` row 6).
**Chain:** Starknet mainnet (`SN_MAIN` = `0x534e5f4d41494e`).
**Pinned evidence block:** `16815577` (CI run) — `starknet-block 16815577`, ts `1792759621`.
**CI run:** https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39955935602 (conclusion: **success**).

---

## 1. TL;DR

| Target (ERC-4626 vault) | TVL (total_assets, USD) | Live extractable by unprivileged attacker | Why closed | Latent risk |
|---|---|---|---|---|
| **xSTRK** `0x28d7…4b0a` (STRK) | $7,858,815.66 | **$0** | ERC-4626 math rounds for the vault; `request_withdrawal` gated to LST; admin role-gated | reward-timing (LOW) |
| strkBTC `0x0477…fd88` (strkBTC) | $1,303,463.96 | **$0** | same class as xSTRK; same gates | reward-timing (LOW) |
| xWBTC `0x6a56…fc13` (WBTC) | $2,140,983.07 | **$0** | same | reward-timing (LOW) |
| xtBTC `0x43a3…b91` (tBTC) | $266,820.78 | **$0** | same | reward-timing (LOW) |
| xLBTC `0x7dd3…fe0` (LBTC) | $79,870.23 | **$0** | same | reward-timing (LOW) |
| xsBTC `0x580f…dc9` (solvBTC) | $136,875.94 | **$0** | same | reward-timing (LOW) |
| **Total** | **$11,786,829.64** | **$0** | | |

*Prices: DefiLlama `coins.llama.fi/prices/current` at ts `1792742xxx`: STRK $0.05290686, strkBTC $81,412.87,
WBTC $81,426.61, tBTC $81,551.00, LBTC $81,666.46, SolvBTC $81,512.26. All 6 vaults share one
implementation class `0x5f06dcb8ef65dd934ba261e6f5ddc03ad3707a028236289feef4ef451f01a52`.*

## 2. Total live extractable now: **$0.00** (confidence **high**)

An external, unprivileged attacker (no admin/operator/governance key, no whitelist, no insider access) can
**not** extract value from the Endur LST system today. Every candidate path was traced on-chain and is either
(a) arithmetic-safe, (b) caller-gated to the LST/VR, or (c) self-funded (a donation). Details and citations in
§5–§6.

## 3. The mechanism, in exact terms (deployed code references)

The system is Endur's `lst` Cairo package, deployed as one **ERC-4626 vault per asset** (share token = the vault
contract itself) plus a **per-vault withdrawal-queue ERC-721** and a **shared ValidatorRegistry (VR)** that wraps
the Starknet core staking contract. Source repo `Endur-fi/starknet-staking` is only a fork of
`starkware-libs/starknet-staking` (the *core* SNIP-18 staking contract) — **Endur's own `lst` Cairo source is not
public**. The deployed ABI (recovered from `starknet_getClassAt`) and the Cairo Security Clan audit
(`Endur-fi/lst`, initial commit `471693ff`, final `d607247e`, 22/11/2024) were used to reconstruct the design.

Key deployed functions (selectors verified against `entry_points_by_type`):

```
LST  (class 0x5f06dcb8…): asset,total_assets,total_supply,convert_to_assets/convert_to_shares,
                          deposit,mint,withdraw,redeem,deposit_to_validator,deposit_with_referral,
                          send_to_withdraw_queue,before_unstake,set_config,upgrade,initializer
WQ   (class 0x6b2e1893…): request_withdrawal(assets,shares,receiver),claim_withdrawal(id),
                          claim_withdrawal_to(id,receiver),take_funds(amount),
                          reduce_total_queue_amount(new,old),get_queue_state,get_request_info,ERC-721
VR   (class 0x432c0203…): add_validator,update_validator,add_delegator,stake_to_validator,receive_funds,
                          claim_rewards_for_validator,on_switch,migrate_delegators,send_to_withdrawal_queue,
                          total_stake,get_validator_token_info,get_settings,get_token_config
```

**`total_assets` composition (measured, exact):**
`LST.total_assets(STRK) == VR.total_stake(STRK) == Σ(validators' staked_amount) + VR's unstaked STRK balance`.
At block 16815577, `LST.total_assets = VR.total_stake = 147,960,394,510,776,628,394,750,943 wei`
(delta = **0**). `VR.total_stake` calls `STRK.balanceOf(VR)` internally (confirmed by call trace). It does **not**
include accrued-but-unclaimed staking rewards (those live in the delegator `PoolMemberInfoV1.unclaimed_rewards`
and enter `total_assets` only when a reward claim re-stakes them) — this is the origin of the (small) latent
risk in §8.

**Withdrawal queue (2-step, 7-day):** a redeemer's shares are burned and a request
`WithdrawRequest{assets, shares, isClaimed, timestamp, claimTime, cumulative_requested_amount_snapshot}` is
recorded with `claimTime = now + 604800` (7 days, read from WQ storage). When the keeper finalises the unstake,
the VR sends STRK to the WQ (`take_funds`) and holders call `claim_withdrawal(id)`, which pays the recorded
`assets` to the NFT owner.

## 4. Live-state assessment (block 16815577)

Addresses (all verified live; `starknet_getClassHashAt` at the pinned block):

| Role | Address |
|---|---|
| xSTRK vault (LST) | `0x28d709c875c0ceac3dce7065bec5328186dc89fe254527084d1689910954b0a` |
| strkBTC / xWBTC / xtBTC / xLBTC / xsBTC vaults | `0x047751b3…fd88` / `0x6a567e68…fc13` / `0x43a35c14…b91` / `0x7dd3c80d…fe0` / `0x580f3dc5…dc9` |
| xSTRK WithdrawalQueue NFT | `0x0518a66e579f9eb1603f5ffaeff95d3f013788e9c37ee94995555026b9648b6` |
| BTC vaults' WithdrawalQueues | `0x535b6a83…c11f` / `0x670cdfa7…0f72` / `0x35b19400…d75a` / `0x293caaca…49ec` / `0x45f4f8af…1006` |
| ValidatorRegistry (shared) | `0x029edbca81c979decd6ee02205127e8b10c011bca1d337141170095eba690931` |
| governor (all contracts) | `0x5be5a5f27a86f0e0bdd71f07992a5c33ab36d1fc64f6b6ee5a0f2d6041889c9` |
| treasury | `0x301c5ba2c76af76c28e9f4d55680d8507267b9d324129a71d6cdc54a3318298` |
| Starknet core staking contract | `0xca1702e64c81d9a07b86bd2c540188d92a2c73cf5cc0e508d949015e7e84a7` |
| delegator (example, v0) | `0x76d15a66bec239c54a727056a8ab04b14f5441a2f559e6eb471cc7e8e878d99` |

Live values:

| Item | Value (block 16815577) |
|---|---|
| xSTRK `total_assets` / `total_supply` | 147,960,394.51 STRK / 124,531,370.82 xSTRK (rate **1.18813752**) |
| xSTRK vault's own STRK balance | **1 STRK** (idle; everything else is staked) |
| WQ STRK balance (backs funded claims) | **474,516.90 STRK** (≈ $25,105) |
| VR STRK balance (unstaked cash) | 13,423.29 STRK |
| WQ state | `max_request_id=10689`, `unprocessed=0`, `intransit=2,083,577.27 STRK`, `cumulative_requested=126,183,544.50 STRK`, `claim_time=604800 s` |
| WQ `lstDisp` (storage slot `sn_keccak("lstDisp")`) | `0x28d709c8…4b0a` = the xSTRK LST |
| VR settings | `rewards_fee_bps = 0x5dc = 1500` (15%), `treasury = 0x301c5ba2…`, `5 validators` |
| Pause state | **all 6 vaults `is_paused = 0`** (unpaused); WQ/VR unpaused |
| STRK allowance VR→WQ | `2^256−1` (unlimited, used by `take_funds`) |
| STRK allowance LST→WQ | **0** |
| `max_deposit` / `max_mint` (any receiver) | `2^256−1` (unlimited) |

## 5. What an attacker can and cannot do (exact call paths)

Access-control map built by invoking **every external entry point with `caller_address = 0x0`** (the most
unprivileged caller) at the pinned block. A revert whose reason is a caller/role check proves the gate; a revert
for any other reason (allowance, "exceeds max", time, deserialize) proves the entry point has **no caller gate**.
The map is reproduced by `ci/run.sh` → `ci-out/endur-live.json`.

**Cannot (all verified to revert for caller=0):**

| Call | Revert | Conclusion |
|---|---|---|
| `WQ.request_withdrawal(assets,shares,receiver)` | `Only LST can call` | attacker cannot inject an arbitrary `assets`/`shares` pair |
| `WQ.reduce_total_queue_amount(new,old)` | `Invalid caller` | gated to the LST |
| `LST.send_to_withdraw_queue(amount)` | `Caller does not have role` | operator-gated |
| `LST.set_config` / `upgrade` / `initializer` | `Caller does not have role` / `Must be prev onwer` | admin-gated |
| `LST.before_unstake` | `Invalid delegator member` / `invalid validator` | gated to registered delegator |
| `VR.add_validator` / `update_validator` / `add_delegator` / `update_supported_token` / `set_settings` / `upgrade` | `Caller does not have role` | admin-gated |
| `VR.stake_to_validator` | `Invalid caller` | gated |
| `VR.on_switch` | `delegator not found` | gated to a registered delegator |
| `VR.migrate_delegators` / `send_to_withdrawal_queue` (real token) | `Only LST can call` | gated |
| `delegator.claim_rewards` / `stake` / `start_delegation` | `only VR can call` | gated |
| `delegator.start_unstake_intent` / `update_unstake_intent` / `switch_pool` / `send_to_withdraw_queue` | `Caller does not have role` | role-gated |

**Can (permissionless) — and why none of them extract value:**

1. `LST.deposit` / `mint` / `withdraw` / `redeem` / `deposit_to_validator` / `deposit_with_referral`, ERC-20
   transfers — the ERC-4626 entry points. **Round-trip is provably non-profitable** (§6).
2. `WQ.claim_withdrawal(id)` — permissionless, but pays the recorded `assets` to the **NFT owner** (verified by
   trace: a third-party account `0x2d6cf618…` claimed request 10685, funds went to owner `0x6fb76c68…`). It only
   helps the owner; `isClaimed` prevents double-claim; STRK is a plain ERC-20 (no re-entrancy hook).
   `WQ.claim_withdrawal_to(id, receiver)` is **owner-gated** (`Only owner can claim`).
3. `WQ.take_funds(amount)` — permissionless, but it pulls `amount` **from the caller**
   (`STRK.transferFrom(msg.sender, WQ, amount)`; caller=0 → `ERC20: insufficient allowance`). It is a
   self-funded top-up of the queue, never a drain. The VR's unlimited allowance to the WQ is *not* reachable
   this way (the call still transfers from `msg.sender`).
4. `VR.receive_funds(validator, token, amount)` — permissionless, self-funded (`ERC20: insufficient allowance`
   for caller=0). A donation that credits `pending_stake`.
5. `VR.claim_rewards_for_validator(validator, token)` — permissionless, token-gated (returns `Out of gas` in a
   static call because it iterates the validator's delegators). It only *realises* staking rewards (which then
   re-stake and raise `total_assets`); it cannot redirect them to the caller. Relevant only to the latent risk
   in §8.

**Fee / share-math check.** The ERC-4626 `adjust_*` fee hooks are the identity (deposit/redeem carry no entry/exit
fee); `preview_deposit(1e18) == convert_to_shares(1e18, floor)` and `preview_redeem(1e18) ==
convert_to_assets(1e18, floor)`. The only fee is the 15% `rewards_fee_bps` taken from staking rewards to the
treasury.

## 6. PoC / verification — ERC-4626 round-trip is non-profitable

There is no EVM fork for Starknet, so the PoC is a **read-only keyless probe** (`analysis/endur_probe.py`, run by
`ci/run.sh`) that pins a block, calls the live contracts and evaluates the round-trip with exact integer
arithmetic **and** the contracts' own preview functions.

For each input `A`: `shares = preview_deposit(A)` then `out = preview_redeem(shares)`. Because deposit floors
shares (`shares ≤ A·T/TA`) and redeem floors assets (`out ≤ shares·TA/T`), `out ≤ A` always. Measured at the
pinned block over `A ∈ {1, 2, 10⁶, 10¹², 10¹⁵, 10¹⁸, 10¹⁹, 10²¹, 10²⁴, 2·10²⁴, 10²⁶} wei`:

- **max profit = 0 wei**; worst case = −2 wei (loss).
- `withdraw`→`redeem` round-trip: net = 0 wei for every size tested.
- Mint-then-redeem: `mint` uses `ceil` for shares, `redeem` uses `floor` → net ≤ 0.

A first-depositor / donation-inflation attack is not available: all six vaults have `total_supply > 0`, and
`total_assets` is derived from the VR's staked principal + cash (a direct STRK donation to a vault does not change
`total_assets`). `deposit` mints shares from the *pre-deposit* `total_assets` (traced), so a deposit is priced at
the fair rate.

CI run: https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39955935602 — `custom CI script` job
**success**; artifacts `result-endur` (`ci-out/endur-live.json`, `ci-out/endur-verdict.json`).
Full log: `ci-log.txt`.

## 7. Verdict and residual / latent risk

- **E-U (external unprivileged, headline): $0.00 — confidence high.** No permissionless path moves value to the
  attacker: the only share-price-affecting entry points are the ERC-4626 primitives (arithmetic-safe), the
  withdrawal-queue request (gated to the LST), and self-funded donations; every admin/rate/registry function is
  role-gated; all vaults are unpaused and solvent.
- **H-O (holder-only self-service):** n/a as a *finding* — all value is normally holder-redeemable through the
  7-day queue. The WQ's **474,516.90 STRK (≈$25,105)** is funded and claimable by the rightful request owners;
  `intransit` 2,083,577 STRK is being unstaked to fund future claims.
- **P (privileged-only):** n/a — the admin surface (`set_config`, `upgrade`, `pause`, VR registry) exists but is
  not a value-extraction path; role holders were not enumerable from public RPC (would need role-grant events).
- **S (stuck/bricked): $0** — no frozen/paused paths found; all vaults `is_paused = 0`.
- **Latent risk (LOW, not counted in E-U):** `total_assets` excludes accrued-but-unclaimed staking rewards.
  A capital-rich attacker could, in principle, deposit just before a permissionless
  `VR.claim_rewards_for_validator` call (which realises rewards and raises `total_assets`) and redeem just after,
  capturing `R·D/(A+D)` of the realised rewards `R`. Measured unclaimed rewards for one validator's 20 delegators
  ≈ **1,269 STRK (≈$67)**; system-wide this is on the order of $10²–$10³. The redemption is also queued for 7 days.
  Net of a flash-loan fee on ~$8M this is not profitable. Confidence **low**; a proper fix would mark rewards to
  market in `total_assets`.
- **Blockers / caveats:** Endur's `lst` Cairo source is **not public** (only the ABI, the audit PDF and Endur's
  own TS relayer ABIs are), so the conclusions rest on the deployed ABI + on-chain traces + the audit, not on
  source review. `starknet_call` forces `caller_address = 0x0`, so caller gates were proven by *reverting*
  behaviour, not by impersonating an arbitrary attacker (a real attacker is strictly less privileged than any
  privileged role and, for equality gates, equivalent to caller 0).

## 8. Methodology & sources

- **Live reads (keyless):** `https://starknet-rpc.publicnode.com` (fallback
  `https://starknet.api.onfinality.io/public`), methods `starknet_call`, `starknet_getStorageAt`,
  `starknet_getClassAt`, `starknet_getClassHashAt`, `starknet_getEvents`, `starknet_traceTransaction`.
- **Selectors:** `keccak256(name) & (2²⁵⁰−1)`; verified against on-chain `entry_points_by_type`
  (e.g. `total_assets = 0x21e1f786…`, `redeem = 0x2ef0a973…`, `request_withdrawal = 0x1b74955e…`).
- **Storage slots:** `sn_keccak(variable_name)` (verified: `lstDisp`, `token`, `claim_time`,
  `unprocessed_withdraw_queue_amount`, `intransit_amount`, `cumulative_requested_amount`, `last_request_id`).
- **Sources:** Endur docs "Contracts"; DefiLlama adapter `projects/endur/index.js`; Cairo Security Clan
  `Endur_Audit_Report.pdf` (repo `Endur-fi/lst`); Endur relayer ABIs (`Endur-fi/relayer`); call traces of
  `0x627a0b58…` (redeem→request_withdrawal) and `0x3fc3c6a3…` (deposit).
- **Prices:** DefiLlama `coins.llama.fi/prices/current`.

### Files index

```
endur/
├── README.md                     # this file
├── summary.json                  # machine-readable summary
├── analysis/
│   ├── endur_probe.py            # self-contained read-only probe (CI job body)
│   ├── sn_rpc.py                 # small keyless RPC helper used during recon
│   ├── abi-summary.txt           # every function of the 3 deployed classes (from starknet_getClassAt)
│   ├── structs.txt               # ABI structs/enums/events (Config, WithdrawRequest, QueueState, …)
│   ├── selectors.txt             # verified selectors
│   ├── trace-redeem.txt          # call traces proving redeem→request_withdrawal and deposit ordering
│   ├── endur_audit.txt / Endur_Audit_Report.pdf   # Cairo Security Clan audit (Endur-fi/lst)
├── ci/run.sh                     # runs the probe, writes ci-out/*.json + verdict
├── ci-out/                       # endur-live.json, endur-verdict.json (pinned-block results)
├── ci-artifacts/result-endur/    # CI-uploaded copies of ci-out
└── ci-log.txt                    # full CI log
```
