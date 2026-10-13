# pSTAKE LSD (stkBNB / stkXPRT) — L2 Phase-2 deep dive

**Date:** 2026-10-13 · **Chains:** BSC (stkBNB), Persistence core-1 (stkXPRT) · **Status:** read-only; fork-PoC verified on CI; no mainnet transactions

| Target | Live value now | Extractable by fresh unprivileged attacker | Why closed/open | Latent risk |
|---|---|---|---|---|
| BSC `StakePool` `0xC228CefDF841dEfDbD5B3a18dFD414cC0dbfa0D8` (stkBNB, V2 proxy) | **159.211388550510322716 BNB ≈ $118,137** in native BNB (block 127,472,407) | **$0** | Every value-moving entry point either requires stkBNB (burn→fair redemption at the pool's own rate), is role-gated (DEFAULT_ADMIN_ROLE / BOT_ROLE), or reverts. Claim requests are per-owner (`from` = token sender) and cannot be created or claimed by third parties. | 2-of-3 Gnosis Safe admins can `pause()` + `withdrawBNB()` the whole balance (P); 5.75 BNB surplus is admin-only |
| Persistence `liquidstake` module (`stk/uxprt`, module acct `persistence15uvj9phxl275x2yggyp2q4kalvhaw85syqnacq`) | **1,117,050.285846 XPRT ≈ $3,973** net backing for 748,782.94 stkXPRT (head 2026-10-13) | **$0** | Permissionless mint/redeem only; both math paths truncate against the user; no reward/fee path pays the caller; module active but not paused | whitelist admin (single address) can pause / re-whitelist validators (P) |

**Total live extractable by an external unprivileged attacker now: $0.00 (E-U)** — confidence **high** on BSC (fork-verified), **medium-high** on Persistence (source + live-state audit; no dynamic PoC).

The triage row's $118,683 is real money still sitting in the BSC pool, but it is **other people's claim reserve + remaining stkBNB backing**, not an open faucet:

| Category | Amount (BNB) | USD @ $742.015/BNB | Who can take it |
|---|---|---|---|
| **E-U** external unprivileged | 0 | $0.00 | nobody |
| **H-O** holder/user recoverable | 153.459996684744 | $113,869.66 | 176 users with open claim requests (87.593098268524 BNB) + all stkBNB holders (65.866898416220 BNB redeemable at 1.0514833643277688 BNB/stkBNB) |
| **P** privileged-only | 5.751291865766 (surplus, plus full sweep ability) | $4,267.55 | 2-of-3 Gnosis Safe admins via `pause()`+`withdrawBNB(to)` (can also sweep the H-O funds; not counted twice) |
| **S** stuck | 0 | $0.00 | — |

---

## 1. What the target actually is

pSTAKE's legacy liquid staking was wound down (pSTAKE blog: "Final Update: Liquid Staking Deprecation", 2025-10-13; support ended 2025-12-31). Two legs remain on-chain:

**BSC — stkBNB StakePool.** `0xC228CefDF841dEfDbD5B3a18dFD414cC0dbfa0D8` is an OZ `TransparentUpgradeableProxy` (verified) whose current implementation is `StakePool` V2 `0xc54a9c4ac81f55eb62e8670e5b376a263e320e38` (verified, solc 0.8.7). Upgrade history (proxy `Upgraded` events):

| Block | Time (UTC) | Implementation |
|---|---|---|
| 20,155,830 | 2022-08-04 | `0x1ba1725fe9d7a907458ca167eb8d83aedfa1e62a` |
| 38,369,096 | 2024-05-02 | `0x17cdf9913230d5f9a2b7a0f5b0df286581d528ee` |
| 47,425,583 | 2025-03-13 | `0xc54a9c4ac81f55eb62e8670e5b376a263e320e38` (current) |

The pool holds all remaining BNB as `_claimReserve`. All BSC-native staking was wound down: the five `StakeCredit` contracts report `getPooledBNB(DelegationManager) = 1` wei each, and the DelegationManager (`0x3A29F1DE4d069745Db7184089E657e4c8d83c558`) holds 0 BNB.

**Persistence — liquidstake module** (`pstake.liquidstake.v1beta1`), module account `persistence15uvj9phxl275x2yggyp2q4kalvhaw85syqnacq`; stkXPRT denom `stk/uxprt`. Module is still active (recent successful `MsgLiquidStake` at height 29,491,114, 2026-10-02).

## 2. Live-state assessment (BSC, block 127,472,407 unless noted)

| Item | Value | Source |
|---|---|---|
| pool native balance | `159211388550510322716` wei (159.211388550510322716 BNB) | `eth_getBalance` |
| `paused()` | `false` | pool |
| `claimReserve()` | `159211288550510322716` wei | pool |
| `bnbToUnbond()` | `-71618190281986797248` (−71.618190281986797248 BNB) | pool |
| `bnbUnbonding()` | `0` | pool |
| `getDeposits()` | `100000000000000` wei (0.0001 BNB dust) | pool |
| `exchangeRate()` | `totalWei=65866898416220492850`, `poolTokenSupply=62641883505527747919` → 1.0514833643277688 BNB/stkBNB | pool |
| stkBNB `totalSupply` / pool / feeVault | `62641883505527747919` / 0 / 0 | token `0xc2E9d07F66A89c44062459A47a0D2Dc038E4fb16` |
| stkBNB `paused()` / owner | `false` / `0xe76fa3540274C5C5656Fc6993721DEc955b2E73a` (Safe) | token |
| `DEFAULT_ADMIN_ROLE` members | 2: `0xA12B1647Ef326e468C20ea593a493B1ec480Aa8c`, `0xe76fa3540274C5C5656Fc6993721DEc955b2E73a` — both **Gnosis Safe 1.3.0, 2-of-3** | `getRoleMember`/`getThreshold` |
| `BOT_ROLE` member | 1: `0xed40b180FAa16FbBDbc03784dDCDf6ce4531dc8e` (EOA) | `getRoleMember` |
| proxy admin (EIP-1967) | `0x457ccda8d92172bb0a692a9167ca82673694d370` (`ProxyAdmin`, owner = `TimelockedAdmin` `0xc1F861FBE4AA730ba19DFA1b1e75ec030E54B607`, 1-day delay) | storage slot / `owner()` |
| AddressStore `0x4a6b3127A1D295878d8790F6ece0776F65FEc121` | owner = same TimelockedAdmin; stkBNB = `0xc2E9…`, feeVault = `0x2FC80E731C40ec6590783bb11Eede9dd43fC69bf`, DM = `0x3A29…` | `owner()`, `getStkBNB()`… |
| DelegationManager | all entry points `onlyStakePool`; balance 0 | source + `eth_getBalance` |
| stake credits (5 validators) | `getPooledBNB(DM)` = `1` wei each | `eth_call` |
| stkBNB mint/burn | only callable by the StakePool (`onlySender(_addressStore.getStakePool())`) | token source |

**Claim-request reconstruction (all-history event scan + head-state reads).** `Withdraw(address,uint256,uint256,uint256)` has the same topic0 in all three implementations and is emitted on every request creation (`_withdraw`), so the scan is complete: **1,988 Withdraw events, 1,188 unique users**; at head **176 users still hold 191 open requests totalling `87593098268523525468` wei = 87.593098268523525468 BNB**. 344 `UnbondingFinished` (cumulative 102,949.33 BNB), 107 `InitiateDelegation_ShortCircuit` (23.91 BNB), one `Rebalancing_Success` of 190.289926085 BNB at block 47,456,795 (post-V2 recovery). **No `BNBWithdrawn` event has ever been emitted.**

Accounting identity: `claimReserve − pending_claims − stkBNB_backing = 5.751291865766304398 BNB` surplus; `bnbToUnbond = −(claimReserve − pending_claims)` exactly.

## 3. What an attacker can and cannot do (BSC)

Permissionless surface: `deposit()`, `tokensReceived()` (only callable by stkBNB), `claim(index)`, `claimAll()`, `epochUpdate()`.

- **Cannot create a claim request without burning stkBNB.** Requests are created only in `_withdraw(from, amount)` reached via the ERC777 hook, where `from` is the token sender and `amount` is the actually-transferred stkBNB. Direct `tokensReceived` calls revert `UnknownSender`; stkBNB `mint`/`burn` revert for non-pool callers.
- **Cannot claim someone else's request.** `claim(index)`/`claimAll()` always use `msg.sender` as `from`; `_claim` pays `from`.
- **No profitable round trip.** Deposit floors `tokens = wei*S/T`; withdrawal floors `wei = tokens*T/S`. Verified numerically at live values: 5 BNB → 4,755,186,976,445,019,054 stkBNB → 4,999,999,999,999,999,999 wei back (loses 1 wei/cycle; no loop).
- **Cannot inflate the rate.** `epochUpdate()` is permissionless but computes validator earnings from `StakeCredit.getPooledBNB`; all five positions are at 1 wei with stored stakes 1 wei → earnings 0 → reverts `NoRewardsAccured`. Even if it succeeded it mints fee tokens only to the FeeVault.
- **Donations do not help.** The pool's `receive()` accepts only the DelegationManager; forced BNB (selfdestruct) would sit as `getDeposits()` without touching `exchangeRate`.
- **Admin/BOT paths revert for outsiders**: `withdrawBNB`, `triggerRebalance`, `pause/unpause/updateConfig` (admin); `initiateDelegation`, `initiateRedelegation`, `unbondingInitiated`, `unbondingFinished`, validator management (BOT).
- **V2 removed the claim cooldown check** (`_canBeClaimed` is dead code; `_claim(from,index)` no longer calls it). Consequence: the 87.59 BNB of old V1-era requests is *immediately* claimable by their owners — a **holder-recovery improvement**, not an attacker path.

**Latent (privileged) risk:** either Safe admin can `pause()` and then `withdrawBNB(to)` the **entire** balance (it zeroes `_claimReserve`, `_bnbToUnbond`, `_bnbUnbonding`), including the 113.87k of holder funds — that is the P path; the surplus beyond H-O claims is 5.75 BNB. Proxy upgrade is behind a 1-day TimelockedAdmin. BOT is an EOA but its functions can only move BNB to the hard-coded DelegationManager, not to arbitrary addresses.

## 4. Persistence leg (stkXPRT)

Live state (LCD `rest.cosmos.directory/persistence`, 2026-10-13):

| Item | Value |
|---|---|
| `stkxprt_total_supply` | 748,782.939653 stkXPRT |
| `net_amount` (backing) | 1,117,050.285846 XPRT |
| `mint_rate` | 0.670321604265029056 stkXPRT/XPRT (1 stkXPRT = 1.491821 XPRT) |
| `total_unbonding_balance` / `proxy_acc_balance` | 0 / 0 |
| `unstake_fee_rate` / `module_paused` | 0 / false |
| `whitelist_admin_address` / `fee_account_address` | `persistence1ealyadcds02yvsn78he4wntt7tpdqhlhg7y2s6` |
| module account | `persistence15uvj9phxl275x2yggyp2q4kalvhaw85syqnacq` (0 liquid, 0 delegations — proxy account holds the stake) |

Value: 1,117,050.285846 XPRT × $0.0035564 = **$3,972.71** (XPRT price 2026-10-13; DefiLlama). Permissionless surface is `MsgLiquidStake` / `MsgLiquidUnstake` only; both use `MulTruncate`/`QuoTruncate`/`TruncateInt` in the user-pays direction (`NativeTokenToStkXPRT`, `StkXPRTToNativeToken`), fee 0, min stake 1,000 uxprt. No function pays a caller without burning stkXPRT; no attacker-influenceable input to `net_amount` except donations (which *lower* `mint_rate` for the donor). **E-U = $0; H-O = $3,972.71 recoverable by stkXPRT holders via unbonding; P = whitelist admin pause/re-whitelist.**

## 5. PoC / fork verification (CI)

Foundry project `poc/` (vendored forge-std), fork of BSC at head via `BSC_RPC_URL` with public fallback. Tests (`poc/test/StakePoolLive.t.sol`):

1. `test_live_state` — code/roles/rate/balance snapshot; asserts not paused, balance == claimReserve (±dust), rate supply == token supply, 2 admins.
2. `test_attacker_no_extraction_path` — fresh attacker: `claim(0)` reverts; `claimAll()` no-op; direct `tokensReceived` reverts; `send` without stkBNB reverts; direct `mint`/`burn` revert; `withdrawBNB`/`triggerRebalance`/`initiateDelegation` revert; `epochUpdate` reverts (or pays nothing); under-min deposit reverts; attacker balance unchanged.
3. `test_holder_redemption_and_roundtrip_loss` — 3× deposit 5 BNB → send stkBNB to pool → immediate claim; asserts each round trip returns ≤ principal (live loss 1 wei/cycle) and no leftover stkBNB.
4. `test_existing_pending_claimant_can_claim` — pranks a real address that still has open requests; `claim(0)` pays BNB (H-O live).
5. `test_admin_can_sweep_when_paused` — pranks an admin Safe: `pause()` + `withdrawBNB` empties the pool (P path, fork-only).

Custom CI job `ci/run.sh` + `ci/scan.py` independently re-scans the full Withdraw history and re-derives the pending-claim total and live state, writing `ci-out/ci_state.json` and `ci-out/pending_claims.json`.

**CI runs:**
- GitHub Actions (repo `artsbykriss/ca-zombie-ci`): `https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38468524769` — first run failed only because the new repo has an empty `BSC_RPC_URL` secret (fixed: empty-string fallback); see rerun link below.

## 6. Verdict and residual risk

- **E-U $0.00, high confidence (BSC).** The $118k is a claim reserve, not an open path: value can only leave by burning stkBNB at the pool's own rate (fair), by an owner claiming their own request, or by admin sweep. All verified on a fork with real state.
- **H-O $113,869.66 (BSC) + $3,972.71 (Persistence).** Remaining stkBNB holders and the 176 open-request users can still recover at the stated rates; the V2 upgrade removed the 8-day cooldown gate, so old requests are immediately claimable.
- **P $4,267.55 surplus** (and full-balance sweep capability) behind 2-of-3 Safes + 1-day timelock.
- **Residual/latent:** if the pool is ever `pause()`d and swept by admins, holder funds go with it (centralization risk, not attacker risk). If a future upgrade reintroduces a cooldown bug or the stkBNB token is repointed via AddressStore (timelock), re-assess. Nothing else is live for an outsider.
- **Negative results recorded:** direct hook calls, direct mint/burn, rate sync, rebalance, delegation, under-min deposit, self-send, donation paths — all closed (see PoC).

## 7. Methodology & sources

- On-chain reads at explicit blocks via public/keyless RPCs (`bsc-rpc.publicnode.com`; archive scans via a private keyed endpoint whose URL is never written to this repo). Full event history: Withdraw/Claim/Deposit/Upgraded/Unbonding*/Rebalancing/BNBWithdrawn topics, blocks 20,155,830 → head.
- Verified sources: StakePool V2 `0xc54a9c…`, V1.5 `0x17cdf991…`, V1 `0x1ba1725f…`, StakedBNBToken `0xc2E9…`, AddressStore, DelegationManager impl `0xcc853b0b…`, ProxyAdmin, TimelockedAdmin (Etherscan V2, chainid 56).
- Persistence: LCD `rest.cosmos.directory/persistence` (`/pstake/liquidstake/v1beta1/params|states|validators`), auth module accounts, bank supply/owners, tx search; module source `persistenceOne/persistenceCore` (`x/liquidstake`).
- Prices: DefiLlama `coins.llama.fi` (BNB $742.015254725042, XPRT $0.0035564263339559, both 2026-10-13). DefiLlama protocol `pstake-lsd` frozen at $192,828 (2025-10-30).
- Blog/context: pSTAKE "Final Update: Liquid Staking Deprecation" (2025-10-13), "Final Notice" (2025-12-16).

**Caveats:** (1) The BSC numbers move as holders claim/redeem — snapshot block 127,472,407; the CI job re-derives them at run time. (2) The Persistence leg is a source-level + live-state audit; no Cosmos fork PoC. (3) USD values are point-in-time; BNB/XPRT prices are volatile. (4) The `getClaimRequestCount` reconstruction assumes the Withdraw event is the only request-creation path — verified across all three implementations' sources.

**Files:** `analysis/` (live_state.json, pending_claims.json, claim_counts.json, sources, ABI dumps, event summaries), `poc/` (Foundry), `ci/` (independent re-scan), `ci-out/`, `ci-log.txt`, `summary.json`.
