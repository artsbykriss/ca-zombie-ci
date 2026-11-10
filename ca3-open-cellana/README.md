# CA3 OPEN-2 (Target 2) — Cellana `vote_manager::rescue_stuck_rewards` (Aptos)

**Date:** 2026-11-10 · **Chain:** Aptos mainnet · **Status:** read-only. No transaction was signed or
broadcast; no key was used. The entry function was analysed from the deployed ABI + source mirror and
checked with live `/v1/view` reads.

---

## 1. TL;DR

| Question | Answer |
|---|---|
| Can an unprivileged caller extract anything beyond their own rewards? | **No. $0 direct.** The function claims rewards for the passed address and sends every claimed asset to `incentivize(pool, rescued_rewards)`, which deposits them into the pool’s incentive reward pool. There is no transfer/mint/deposit to the caller. |
| Can the caller redirect or grief? | It can move a **dead** (non-existent) veNFT address’s unclaimed rewards into a pool’s incentive pool, and it can advance the epoch (already a public entry). Live veNFTs are excluded by `assert!(!nft_exists(account_address))`. No principal is touched. |
| Is there a live reward pool worth attacking? | The protocol is dust: the top pool holds **0 USDC + 13 APT**; the top-pool fee total for the prior epoch is **0**; the incentive pool is empty. |
| Current-epoch fee figure | 44.65 USDC + 73.79 APT (~$87.9) for epoch 2966, the only non-zero reward total observed. |

**Total live extractable now: $0.00 — confidence: high on “no direct payout”, medium on the exact
dead-reward inventory (tooling limit, §6).**

---

## 2. The function, exactly

Package `0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1`, module `vote_manager`:

```
rescue_stuck_rewards(address, vector<Object<LiquidityPool>>, u64)
  visibility: public, is_entry: true, no &signer
```

Deployed ABI (public fullnode) matches the source mirror
(`asilenced/Boston_Next.js@ae6b912:vote_manager.move`, module `fullsail::vote_manager`):

```move
assert!(!voting_escrow::nft_exists(account_address), E_NFT_EXISTS);
let current_epoch = epoch::now();
for each pool in liquidity_pools:
    for start_epoch in [current_epoch - epoch_count, current_epoch):
        rescued += rewards_pool::claim_rewards(account_address, fees_pool, start_epoch);
        rescued += rewards_pool::claim_rewards(account_address, incentive_pool, start_epoch);
    incentivize(liquidity_pool, rescued);
```

`rewards_pool::claim_rewards`, `add_rewards`, `increase_allocation`, `decrease_allocation` are all
**`friend`** functions, and the only friend is `vote_manager`. There is no external allocation-mint
or direct-claim path. `claimable_rewards` is a public view only.

`incentivize(pool, rewards)` asserts the gauge exists, asserts each token is whitelisted for that
pool, calls `advance_epoch()`, then `rewards_pool::add_rewards(incentive_pool, rewards, now+1)`.

**Call graph:** the only sink for the claimed assets is the pool’s incentive reward pool. The caller is
never a recipient.

---

## 3. Live-state assessment (epoch 2966)

| Item | Value |
|---|---|
| Top pool | `0x234f0be57d6acfb2f0f19c17053617311a8d03c9ce358bdf9cd5c460e4a02b7c` (86.5% of votes) |
| Top-pool reserves | **0 USDC / 13 APT** (~$7.6) |
| `fees_pool(top)` | `0xedd6a18ade851139ab8dd5a90b0234826f8193b4e3047665a5b9144cc91bf41e` |
| `incentive_pool(top)` | `0x8926ecb1aff4263a32eac211c41cc0d06d59a32de1263112cb286a138f010ba` |
| `gauge(top).total_stake` | 598,569,252,019 raw |
| `total_rewards(fees_pool, 2965)` | **0** |
| `total_rewards(incentive_pool, 2965)` | **0** |
| `total_rewards(fees_pool, 2966)` | 44,651,411 raw USDC + 7,379,380,468 raw APT (~$87.9) |
| `claimable_rewards(fresh, fees_pool, 2965)` | `[0, 0]` |
| `nft_exists(fresh)` | false |
| Total voting power | 15,142,257.95 |

The protocol is effectively dead: the largest pool holds ~$7.6 of APT, the incentive pool is empty,
and the only non-zero fee figure is the current epoch’s ~$88. There is no material reward pool to
redirect.

---

## 4. What an attacker can and cannot do

| Path | Precondition | Cost | Result |
|---|---|---|---|
| Call rescue with your own non-NFT address | None | Gas | Your own reward shares, if any, are recycled into the pool. You receive 0. |
| Call rescue with a live veNFT address | — | Gas | Reverts `E_NFT_EXISTS` (10). |
| Call rescue with a dead veNFT address that has unclaimed fees | Know a dead address (enumeration blocked, §6) | Gas + LP capital to capture incentives | Fees are moved to the pool’s incentive pool; the caller receives 0. As a gauge staker of that pool the caller later receives its pro-rata share, split with all other stakers. |
| Grief / epoch advance | None | Gas | `incentivize` calls `advance_epoch()`, but `advance_epoch` is already a public entry. No protocol-wide DoS; each call is bounded by the caller’s gas. |
| Touch LP principal / staked principal / veNFT locked principal | — | — | Impossible: the function only reads reward shares and moves `FungibleAsset` rewards. |

**Capital needed:** $0 for the function. To capture recycled incentives indirectly, the attacker needs
gauge (LP) stake in the chosen pool; the entire top pool is ~$8, so the capital is trivial and the
prize is equally trivial. No DEX/CEX acquisition of a token is required.

---

## 5. Verdict and residual risk

- **E-U: $0.00** — no direct payout path exists.
- **E-U-conditional: ≤ ~$88 per epoch** — only as an LP/gauge-staker share of recycled dead-NFT
  rewards; the incentive pool holds 0 today and the pool is dust, so the realistic value is **<$10**.
  Confidence low/medium (conditional).
- **H-O:** veNFT holders can claim their own rewards through the normal signer path; dust.
- **P:** the package has a governance `upgrade` entry; that is protocol-wide privileged risk, not a
  property of this function.
- **S:** dead-NFT rewards, if any, are recyclable rather than bricked; no principal is stranded.

Residual risk is a *reward-redistribution* nuisance: an attacker who is a dominant gauge staker can
convert other addresses’ dead reward shares into pool incentives and capture a share. It cannot touch
principal, and the live pools are too small to matter.

No blockers (no pause on the function; no whitelist on the caller).

---

## 6. PoC / verification and tooling limits

**Executed:** `ci/run.sh` → `ci/cellana_checks.py`, **25 PASS / 0 FAIL**, against the public Aptos
fullnode. It verifies:

1. the deployed ABI (`is_entry`, no signer, exact params),
2. `rewards_pool` friend-only visibilities and the friend list,
3. the source mirror’s rescue body (claim for the passed address, recycle via `incentivize`, no
   transfer/deposit to the caller),
4. live epoch / pool / fee / incentive state and a fresh address’s zero claimable rewards,
5. the payout model (direct = 0).

**Tooling limits (precise):**

- **Entry simulation blocked.** `/v1/transactions/simulate` checks the sender’s APT balance for
  `max_gas × gas_price`; a fresh account has 0 APT, the minimum gas price is 100, and using a funded
  private key is prohibited by the read-only mandate. Observed:
  `INSUFFICIENT_BALANCE_FOR_TRANSACTION_FEE`; with `gas_price=0`,
  `GAS_UNIT_PRICE_BELOW_MIN_BOUND`.
- **Dead-veNFT enumeration unavailable.** The indexer `events` table is deprecated (HTTP 400);
  `events_v2` is not in the schema; `token_activities_v2` scans time out (408) or rate-limit (429);
  the fullnode `/accounts/{addr}/events` returns `not found` (no v1 event handles). The
  `user_transactions` filtered queries 408/429 from this host. The *inventory* of dead veNFTs with
  unclaimed rewards is therefore unmeasured; it does not affect the direct-payout verdict.
- **No Move decompiler.** `aptos` CLI is absent; the deployed ABI, the ABI-identical source mirror,
  and live view calls are the evidence base.

---

## 7. Methodology, sources, files

**Method.** Deployed module ABI → `rewards_pool` visibility/friends → source mirror body → call-graph
review → live `/v1/view` state → payout model. No transaction, no key.

**Sources.** Aptos public fullnode (`/v1/accounts/…/module/…`, `/v1/view`), source mirror
`asilenced/Boston_Next.js@ae6b912:vote_manager.move`, Cellana package ABI for `rewards_pool`,
`liquidity_pool`, `gauge`, `epoch`.

**Caveats.** Point-in-time epoch 2966; APT priced at $0.586 (DefiLlama, 2026-11-10). The source is a
third-party mirror, but its ABI matches the deployed module exactly. The dead-reward inventory is
unmeasured (see §6); the verdict is structural.

**Files.** `analysis/source-and-abi.md`, `ci/cellana_checks.py`, `ci/run.sh`, `ci-out/`,
`summary.json`.
