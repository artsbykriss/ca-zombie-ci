# Cellana `vote_manager::rescue_stuck_rewards` — source, ABI and live state

Read-only. No transaction was signed or broadcast. No key was used.
Chain: Aptos mainnet. Package: `0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1`.

## 1. Deployed ABI (public fullnode)

`GET /v1/accounts/0x4bf5…/module/vote_manager` returns:

```
name: rescue_stuck_rewards
visibility: public
is_entry: true
params: [
  "address",
  "vector<0x1::object::Object<0x4bf5…::liquidity_pool::LiquidityPool>>",
  "u64"
]
return: []
```

- **No `&signer` parameter.** Any account can submit the entry function; the transaction sender is
  not used by the function body.
- The first parameter is a raw `address`, so the type system does **not** require it to be a
  `Object<VeCellanaToken>`. That is the only reason the function is interesting: the normal
  `claim_rewards` entry requires a signer and a typed veNFT object.

`rewards_pool` ABI (same package):

| Function | Visibility | Entry |
|---|---|---|
| `claim_rewards(address, RewardsPool, u64) -> vector<FungibleAsset>` | **friend** | false |
| `add_rewards(RewardsPool, vector<FungibleAsset>, u64)` | **friend** | false |
| `increase_allocation(address, RewardsPool, u64)` | **friend** | false |
| `decrease_allocation(address, RewardsPool, u64)` | **friend** | false |
| `claimable_rewards(address, RewardsPool, u64) -> SimpleMap` | public view | false |

`friends = [0x4bf5…::vote_manager]`. No external account or module can call the four friend
functions; there is no public allocation-mint or direct-claim path.

## 2. Source (mirror, exact body)

Source: `asilenced/Boston_Next.js@ae6b912:vote_manager.move` (module `fullsail::vote_manager`; the
deployed package uses `fullsail` as its named address). The deployed ABI matches the mirror exactly,
including the three-parameter signature and the `LiquidityPool` type.

```move
public entry fun rescue_stuck_rewards(
    account_address: address,
    liquidity_pools: vector<Object<LiquidityPool>>,
    epoch_count: u64
) acquires AdministrativeData, GaugeVoteAccounting {
    assert!(!fullsail::voting_escrow::nft_exists(account_address), E_NFT_EXISTS);

    let current_epoch = fullsail::epoch::now();
    vector::reverse<Object<LiquidityPool>>(&mut liquidity_pools);

    let pool_count = vector::length<Object<LiquidityPool>>(&liquidity_pools);
    while (pool_count > 0) {
        let liquidity_pool = vector::pop_back<Object<LiquidityPool>>(&mut liquidity_pools);
        let start_epoch = current_epoch - epoch_count;
        let rescued_rewards = vector::empty<FungibleAsset>();

        while (start_epoch < current_epoch) {
            let fees_pool = fees_pool(liquidity_pool);
            let incentive_pool = incentive_pool(liquidity_pool);
            vector::append<FungibleAsset>(&mut rescued_rewards,
                fullsail::rewards_pool::claim_rewards(account_address, fees_pool, start_epoch));
            vector::append<FungibleAsset>(&mut rescued_rewards,
                fullsail::rewards_pool::claim_rewards(account_address, incentive_pool, start_epoch));
            start_epoch = start_epoch + 1;
        };

        incentivize(liquidity_pool, rescued_rewards);
        pool_count = pool_count - 1;
    };
    vector::destroy_empty<Object<LiquidityPool>>(liquidity_pools);
}
```

`incentivize` (same file):

```move
public fun incentivize(liquidity_pool: Object<LiquidityPool>, rewards: vector<FungibleAsset>)
    acquires AdministrativeData, GaugeVoteAccounting {
    assert!(gauge_exists(liquidity_pool), E_GAUGE_NOT_EXISTS);
    // every token must be whitelisted as a reward token for this pool
    ...
    advance_epoch();
    let incentive_pool = incentive_pool(liquidity_pool);
    fullsail::rewards_pool::add_rewards(incentive_pool, rewards, fullsail::epoch::now() + 1);
}
```

### Call-graph conclusion

```
rescue_stuck_rewards(account, pools, n)
  ├─ assert !nft_exists(account)                 // excludes every live veNFT
  ├─ for epoch in [now-n, now):
  │    claim_rewards(account, fees_pool, epoch)       // friend, keyed by `account`
  │    claim_rewards(account, incentive_pool, epoch)  // friend, keyed by `account`
  └─ incentivize(pool, rescued)                        // -> add_rewards(incentive_pool, …, now+1)
```

There is **no transfer, deposit, withdraw or mint to `msg.sender`**. The only sink for the claimed
assets is `incentivize` → the pool's incentive reward pool. The caller receives nothing directly.

The `account_address` argument is an accounting key. For a normal live veNFT the object exists and
`nft_exists` is true, so the function aborts. For an address with no veNFT (including a burned/dead
veNFT object address), `claim_rewards` reads that address's reward shares. If it has none, it returns
an empty vector and the function is a no-op.

## 3. Live state (Aptos mainnet, epoch 2966)

| Quantity | Value |
|---|---|
| `epoch::now()` | 2966 |
| `voting_escrow::total_voting_power()` | 15,142,257.954723165 |
| Top pool (by votes) | `0x234f0be57d6acfb2f0f19c17053617311a8d03c9ce358bdf9cd5c460e4a02b7c` |
| Top-pool votes / total | 3,135,517,429,086,677 / 3,623,239,876,027,913 (86.5%) |
| Top-pool assets | USDC (`0xf22b…17fa::asset::USDC`) + APT |
| Top-pool reserves | **0 USDC / 13 APT** (raw legs; pool is dust) |
| `fees_pool(top)` | `0xedd6a18ade851139ab8dd5a90b0234826f8193b4e3047665a5b9144cc91bf41e` |
| `incentive_pool(top)` | `0x8926ecb1aff4263a32eac211c41cc0d06d59a32de1263112cb286a138f010ba` |
| `gauge(top)` | `0xc90ba4899905105e59f6b5fa399d655ee025e5dd7b85fef2b02a8a6e9d73818e` |
| `gauge.total_stake(top)` | 598,569,252,019 raw |
| `total_rewards(fees_pool, 2965)` | **0** |
| `total_rewards(incentive_pool, 2965)` | **0** (empty map) |
| `total_rewards(fees_pool, 2966)` | 44,651,411 raw USDC + 7,379,380,468 raw APT (~$44.65 + ~$43.24 at APT $0.586) |
| `claimable_rewards(fresh, fees_pool, 2965)` | `[0, 0]` |
| `nft_exists(fresh)` | false |
| `claimable_rewards(fresh, …, current)` | aborts `EREWARDS_CANNOT_BE_CLAIMED_FOR_CURRENT_EPOCH` |

The protocol is effectively dead: the top pool holds ~$7.6 of APT and no USDC, and the current-epoch
fee total is the only non-zero reward figure observed. The gauge's total stake is small.

## 4. What the caller can extract

| Path | Result |
|---|---|
| Pass your own non-NFT address | Claims that address's own reward shares; they are re-added to the pool. You receive 0. |
| Pass a live veNFT address | Aborts `E_NFT_EXISTS` (10). |
| Pass a dead/burned veNFT address with unclaimed fees | Claims those fees and recycles them into the incentive pool. You receive 0 directly; as a gauge staker of that pool you later receive your pro-rata share of the recycled incentives, along with every other staker. |
| Pass an address with no rewards | Empty vector; `incentivize` adds nothing (or advances the epoch, which is already a public entry). |
| Grief | Repeated calls can advance the epoch (already permissionless) and can move a dead address's rewards into the pool. No principal is touched. |

The value is **reward-only** and is bounded by the reward pools. LP principal, staked principal, and
veNFT locked principal are never in scope. The maximum indirect capture is the rescued amount
multiplied by the attacker's gauge share; the rest goes to other stakers.

## 5. Tooling limits (precise)

1. **Entry-function simulation is blocked by the fee check.** `/v1/transactions/simulate` requires
   the simulated sender to have enough APT for `max_gas_amount × gas_unit_price`; the minimum gas
   price is 100 and a fresh account has 0 APT. A funded sender would need a private key, which the
   read-only mandate forbids. All-zero signatures are accepted for *auth*, but not for the balance
   check. (Tested: `INSUFFICIENT_BALANCE_FOR_TRANSACTION_FEE`; `gas_unit_price=0` →
   `GAS_UNIT_PRICE_BELOW_MIN_BOUND`.)
2. **Dead-veNFT enumeration is not available through the public API.** The indexer `events` table is
   deprecated (`Request for Deprecated Resource: events`, HTTP 400); `events_v2` is not in the
   schema; heavy `token_activities_v2` scans time out (408) or rate-limit (429); the fullnode
   `/accounts/{addr}/events` endpoint returns `not found` because the deployed modules have no v1
   event handles. The `user_transactions` table can identify `create_lock_entry` / `withdraw_entry`
   calls but the filtered queries 408/429 from this host. Consequently the *inventory* of dead
   veNFTs with unclaimed rewards is not measured.
3. **No Move decompiler was provisioned.** `aptos` CLI is absent; the analysis uses the deployed
   ABI, the source mirror (ABI-identical), and live view calls.
4. **What *is* verified live:** the entry signature, the friend-only reward accounting, the
   `nft_exists` precondition, a fresh address's zero claimable rewards, the fee/incentive pool
   addresses, the dust reserves, and the zero incentive allocation for the past epoch.

None of these limits changes the direct-payout verdict: the function's only asset sink is
`incentivize`, and no code path pays the caller. They only bound the *indirect* LP-capture number,
which is dust because the protocol is dust.
