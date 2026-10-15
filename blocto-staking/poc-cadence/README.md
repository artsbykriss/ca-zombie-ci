# BloctoTokenStaking — local Cadence PoC for gates C1 / C2 / C3

**Target:** `BloctoTokenStaking` (Flow mainnet `0x0f9df91c9121c460`), the live fork of
`FlowIDTableStaking` behind Blocto's BloctoPass staking system.

**This PoC never touches a real network.** It deploys the *live contract sources* to a
throwaway local `flow emulator` and runs the gate scenarios there. No mainnet
transaction is built, signed or sent; no RPC URL or key is needed.

```
bash poc-cadence/run.sh                      # full run, ~4-6 minutes, non-interactive
# env overrides: POC_OUT_DIR=<dir>  POC_DEADLINE=<seconds>  FLOW_CLI=<path to flow v2>
# outputs (default):
#   ci-out/cadence-poc/poc.log            full transcript
#   ci-out/cadence-poc/poc_result.json    machine-readable PASS/FAIL per claim
#   ci-out/cadence-poc/evidence/*.txt     raw `flow` CLI output per step
#   ci-out/cadence-poc/checks.jsonl       flat check list
```

Exit code: `0` = harness completed (read `poc_result.json` for the verdict), `3` = harness
could not run at all.

## The three gates and what the run observed

| Gate | Claim | Verdict |
|---|---|---|
| **C1** | The **public** minter capability (`&{BloctoPass.MinterPublic}.mintBasicNFT`) lets any unprivileged account trigger BloctoPass minting; while `stakingEnabled == false` the mint reverts inside `Admin.addStakerRecord`'s pre-condition; unfrozen, the same mint succeeds and yields a pass whose staker record is **empty** | **PASS** (19 checks) |
| **C2** | `Staker.withdrawUnstakedTokens` / `withdrawRewardedTokens` have **no** `stakingEnabled` pre-condition, so a pass holder can still pull tokens out of their own `tokensUnstaked` / `tokensRewarded` buckets while the system is **frozen** | **PASS** (21 checks) |
| **C3** | Entitlement isolation: an outside account cannot reach the pass private collection reference, the entitled NFT reference, or the staking `Admin` | **PASS** (5 checks) |

### Exact messages observed (copied from `evidence/`)

**C1 — public mint while frozen** (`evidence/b3_mint_frozen.out`), call stack
`tx → mintBasicNFT → mintNFT → mintNFTWithCustomLockup → create NFT → BloctoPass.NFT.init → addStakerRecord`:

```
* transaction execute failed: [Error Code: 1101] cadence runtime error: Execution failed:
   ... (Cadence stack trace through BloctoPass:525 -> 532 -> 573)
 --> e03daebed8ca0615.BloctoPass:187:27
187 |             self.staker <- stakingAdmin.addStakerRecord(id: initID)
error: pre-condition failed: Cannot register a staker operator if the staking auction isn't in progress
```

After the revert: `BloctoPass.totalSupply` unchanged, victim-less — the *attacker's own*
collection stays empty (`passIDs == []`). With `stakingEnabled = true` the identical
transaction succeeds: `totalSupply: 0 -> 1`, the attacker receives pass id `0`, and
`StakerInfo(0)` reports `tokensStaked = tokensCommitted = tokensUnstaked = tokensRewarded = 0`
and the pass vault holds `0.0` BLT — the mint creates **no value and no claim on other
stakers' funds**, it only calls `Admin.addStakerRecord` (which the frozen flag blocks).

**C2 — withdrawal while frozen.** With `stakingEnabled == false` (verified by script
immediately before, `evidence/c7_state_frozen2.out` → `"stakingEnabled": false`):

| step | result |
|---|---|
| `user_withdraw_unstaked(50.0)` | **succeeds** — `tokensUnstaked: 50 -> 0`, +50 BLT lands in the pass vault, then 50 BLT reach the owner's wallet (950 total) |
| `admin_move_tokens([0])` while frozen | `tokensStaked: 0 -> 50` |
| `admin_pay_rewards([0])` while frozen | `tokensRewarded: 0 -> 1.0` BLT (epoch payout 1.0 / 50 staked) |
| `user_withdraw_rewarded(1.0)` | **succeeds** while still frozen — `tokensRewarded: 1.0 -> 0` |

**Negative control (proves the frozen flag is really still enforced for other paths):**
`stakeUnstakedTokens` in the very same frozen state reverts with
`error: pre-condition failed: Cannot stake if the staking auction isn't in progress`
(`evidence/c20_stake_unstaked_frozen.out`).

**C3 — entitlement isolation** (executed by the *contract* account / an outside account,
never by the pass owner):

```
d1  public &{NonFungibleToken.CollectionPublic, BloctoPass.CollectionPublic}
    .borrowBloctoPassPrivate(...)        -> CHECKER ERROR (tx never executes):
    "value of type `&{NonFungibleToken.CollectionPublic, BloctoPass.CollectionPublic}`
     has no member `borrowBloctoPassPrivate`"
d1b same call after narrowing the public capability to the plain concrete
    &BloctoPass.Collection                    -> CHECKER ERROR (tx never executes):
    "requires `CollectionPrivateEntitlement` authorization, but reference is unauthorized"
d2  runtime probe (signed by the contract account, victim's public capability):
      borrow<auth(CollectionPrivateEntitlement) &BloctoPass.Collection> -> nil
      borrow<&{BloctoPass.CollectionPrivate}>                           -> nil
      borrow<auth(FungibleToken.Withdraw) &BloctoPass.NFT>              -> nil
      borrow<&{...CollectionPublic}> (positive control)                 -> non-nil
    -> the probe transaction succeeds (tx signed by the attacker)
d3  staking Admin probe (signed by the outside account):
      borrow<auth(AdminEntitlement) &Admin>(/public/bloctoTokenStakingAdmin) -> nil
      borrow<&Admin>(/public/bloctoTokenStakingAdmin)                        -> nil
      attacker's own /storage/bloctoTokenStakingAdmin                        -> nil
d4  getAccount(contractAccount).storage.borrow<...Admin>(...)  -> CHECKER ERROR:
    "access denied: cannot access `borrow` because function requires
     `Storage | BorrowValue` authorization, but reference is unauthorized"
```

## Layout

```
poc-cadence/
  run.sh                     the whole PoC (emulator lifecycle, deploy, scenario, results)
  flow.json                  project config template (__PLACEHOLDERS__ filled at runtime)
  contracts/                 byte-identical live sources (+ deps/ from mainnet, see contracts/README.md)
  transactions/*.cdc         one file per step (imports use mainnet addresses; rewritten at runtime)
  scripts/*.cdc              read-only state views
  tools/cadence_json.py      flattens `flow ... --output json` Cadence-JSON for assertions
  .runtime/                  throwaway: generated keys, local-address sources, flow.json, emulator db
```

`run.sh` is fail-soft: every check is recorded as PASS/FAIL with the observed value and the
raw CLI output is kept per step, so a failure is diagnosable from `evidence/` alone. It
never prompts (`-y`, `</dev/null` for the installer) and it stops scheduling new steps if a
global deadline is exceeded.

## Address mapping (mainnet → local)

The emulator rejects mainnet addresses (its address space is chain-scoped), so `run.sh`
copies the sources and rewrites **only the import address literals**:

| mainnet | local | contents |
|---|---|---|
| `0xf233dcee88fe0abe` | runtime account `dep-ft` | `FungibleToken`, `FungibleTokenMetadataViews`, `Burner` |
| `0x1d7e57aa55817448` | runtime account `dep-nft` | `NonFungibleToken`, `MetadataViews`, `ViewResolver` |
| `0x0f9df91c9121c460` | runtime account `blocto` | `BloctoToken`, `BloctoTokenStaking`, `BloctoPassStamp`, `BloctoPass` |
| `0x5555555555555555` (placeholder, txs/scripts only) | runtime account `user` | the unprivileged staker/attacker |

No other byte of any contract changes. The structure that matters is preserved:
`BloctoTokenStaking` and `BloctoPass` live on the **same** account (so
`BloctoPass.account.storage[/storage/bloctoTokenStakingAdmin]` resolves exactly as on
mainnet), and the staker/user account is a **different** account.

`BloctoTokenSale.cdc` is excluded (pre-1.0 syntax, does not compile, irrelevant here).

## Static evidence (file:line) — independent of the emulator

From `contracts/` (live mainnet sources):

| gate | citation |
|---|---|
| C1 | `BloctoPass.cdc:523-526` `mintBasicNFT` is `access(all)` on the `MinterPublic` interface; `BloctoPass.cdc:187` `self.staker <- stakingAdmin.addStakerRecord(id: initID)` inside `NFT.init`; `BloctoPass.cdc:179-180` the borrow of the staking `Admin` from `BloctoPass.account.storage`; `BloctoTokenStaking.cdc:359-362` `pre { BloctoTokenStaking.stakingEnabled: "Cannot register a staker operator if the staking auction isn't in progress" }` |
| C2 | `BloctoTokenStaking.cdc:332-337` `withdrawUnstakedTokens` — no `pre`; `BloctoTokenStaking.cdc:340-347` `withdrawRewardedTokens` — no `pre`; compare `BloctoTokenStaking.cdc:229-231`, `244-246`, `268-270`, `280-282`, `317-320` where `stakeNewTokens` / `stakeUnstakedTokens` / `stakeRewardedTokens` / `requestUnstaking` / `unstakeAll` *do* carry `pre { ... stakingEnabled }` |
| C3 | `BloctoPass.cdc:61-88` `BloctoPassPrivate` interface methods are `access(BloctoPassPrivateEntitlement)`; `BloctoPass.cdc:457-461` `borrowBloctoPassPrivate` is `access(CollectionPrivateEntitlement)`; `BloctoPass.cdc:380-383` `CollectionPublic` exposes only `borrowBloctoPassPublic`; `BloctoTokenStaking.cdc:625-635` `init()` only `storage.save`s the `Admin` (never publishes a capability for it) |

## Caveats / notes

* **C1 is a denial-of-service / UX gate, not a theft gate.** Unfrozen, the public mint gives
  the minter an empty pass (id = `BloctoPass.totalSupply`, zero balances, `lockupAmount = 0`);
  it does not mint BLT and does not touch other stakers' records. The *interesting* part is
  the frozen-state revert: any outside account can trigger a panicking mint (gas is paid by
  the caller; on mainnet `stakingEnabled == false`, so the public minter is currently
  unusable).
* **C2 does not unfreeze anything.** It proves that *pulling out already-credited* tokens
  keeps working while frozen; moving tokens *into* staking (`stakeNewTokens`,
  `stakeUnstakedTokens`, `stakeRewardedTokens`, `requestUnstaking`, `unstakeAll`) is still
  blocked — see the negative control. The withdrawal path requires the pass owner's private
  entitlement, i.e. it is the legitimate owner path (the harness issues
  `auth(CollectionPrivateEntitlement) &BloctoPass.Collection` over the owner's *own* storage,
  which is what the Blocto frontend does).
* `admin_move_tokens` and `admin_pay_rewards` require `!stakingEnabled`, so the reward part of
  the C2 flow necessarily runs while frozen (that is the live mainnet state, epoch 208,
  125,000 BLT/epoch).
* **C3 nuance (documented, not a vulnerability):** narrowing the *public* capability to the
  plain concrete `&BloctoPass.Collection` **is** possible (ordinary Cadence reference
  narrowing, `evidence/d2_private_probe.out` check 2 now asserts this positively). It grants
  nothing: every staking/withdraw method is entitlement-gated, and both entitled borrows and
  entitled calls are rejected (`d1`, `d1b`, `d2` assertions 1/3/4). The `Admin` resource is
  unreachable from outside (`d3`, `d4`).
* The emulator is started with `--storage-limit=false` on the first free port quadruple from
  a fixed candidate list, so leftover servers/ports do not break the run. The emulator
  process is killed on exit via a trap.
* Mainnet's *live* state (`stakingEnabled=false`, `totalStaked=62,003,651.68051645 BLT`,
  29,762 staker records, epoch 208) is mirrored by explicitly calling `endStakingAuction()`
  with the contract account's `Admin` resource; a freshly deployed `BloctoTokenStaking`
  starts with `stakingEnabled = true` (contract `init()`), which the harness asserts as its
  baseline before freezing.
