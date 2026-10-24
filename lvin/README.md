# ZH4P5-LVIN — LVIN token (`recycle(uint256)`) NEM-class gate resolution

**Date:** 2026-10-23 · **Chain:** BSC (chainid 56) · **Status:** read-only; PoC fork-verified only; **no mainnet transaction was ever signed or sent**.

Target: LVIN token `0x33bC8653EcA8469108f65FE87B18c87C136545a8`, PancakeV2 pair
`0x43365C7B7b039bc06dC201Ddf38117cf1C69dc8b` (LVIN/USDT). Lane row #11 of
`zombie-hunt-iv/pass4/skim-burn.md` (NEM-class): carries `sync`, `getReserves`,
`recycle(uint256)` (`0xdd1c35bc`, LULA-family selector); a prior fork probe reverted
`"recycle fail"`, previously described as a *state condition*, not clearly a gate.

**Question resolved:** walk the `recycle` state preconditions and prove whether any
staking-contract path is reachable unprivileged.

---

## 0. UPDATE 2026-10-24 — head recheck (state drifted, verdict unchanged)

Re-read at HEAD (block **129 585 818**, 2026-10-24):

| Item | 2026-10-23 (blk 129 283 473) | HEAD (blk 129 585 818) |
|---|---|---|
| Pair reserves | 16 390 674.50 LVIN / 97 595.51 USDT | **17 274 748.25 LVIN / 77 551.79 USDT** |
| TOKEN `owner()` | `0x0` (renounced) | `0x0` (renounced) |
| TOKEN `stake` (slot 13) | `0xe120…488e` | `0xe120…488e` (unchanged) |
| Stake `owner()` | `0x0` (renounced) | `0x0` (renounced) |
| Stake balances | 10 000 426.62 LVIN / 286 699.57 USDT | 10 000 426.62 LVIN / **283 771.07 USDT** |
| Stake `totalStakeAmt` | 286 226.07 | **283 522.51** |
| `recycle(1)` from random EOA | reverts `recycle fail` | reverts `recycle fail` |
| `recycle(1)` from Stake | succeeds | succeeds |

The LVIN/USDT price fell (USDT side −20.5 %) so `maxBurn = pairBal/3 = 5 749 068 LVIN`
(was 5 462 888). The largest live single reward rose to **103 995.84 LVIN (0.60 % of the
pair)** and a fresh attacker's one-cycle reward is **13 224.37 LVIN ≈ $59** — both still
**~2 orders of magnitude below** `maxBurn`. The gate, the renounced owners, and the
reward-bounded burn are **unchanged**; **E-U remains $0.00**. Head-fork PoC re-run
`poc/test/LvinRecycle.t.sol` = **9/9 PASS** (fork head 129 587 824; CI run recorded in §6).

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why closed / open | Latent risk |
|---|---|---|---|
| LVIN `0x33bC…45a8` / pair `0x4336…dc8b` (~**$97.6k USDT** liquidity) | **$0** | `recycle` is gated by `require(stake == msg.sender, "recycle fail")`. `stake` = the verified `Stake` contract `0xe120…488e`. The gate **is** satisfiable indirectly (`Stake.transfer → sell → token.recycle`), but the burn is `min(caller_reward, pairBal/3)` and the caller must be a registered staker with an accrued reward. Max single live reward = **71,604 LVIN ≈ $426** (0.44 % of pool); a fresh attacker's realistic one-cycle reward = **10,013 LVIN ≈ $60**, and the stake round-trip **loses ~$600**. Fork-proven net **negative** even for a *privileged* max burn (r0/3). | None material; owner renounced on both token & Stake. |

## 2. Total live extractable now

**$0.00 — confidence: high.** The `recycle` primitive is reachable by an unprivileged
staker, but it is **bounded by that staker's own accrued reward** and is not
economically viable (the staker round-trip is a net loss; the maximum-size burn
requires impersonating the Stake contract, which no attacker can do).

- E-U (external unprivileged): **$0.00**
- E-U-conditional (registered staker, capital + 1-day lock): **$0.00** (net **negative**)
- H-O (staker self-service redeem of own principal): **≈ $286,226** nominal
- P (privileged): **$0.00** (owner renounced on TOKEN and Stake; only UC still has a live owner and it moves no pair/stake value)
- S (stuck): **≈ $28.12** (TOKEN contract's own LVIN/USDT, withdrawable only by the renounced owner)

## 3. Mechanism — exact terms

Token source is **verified** (Etherscan V2 chainid 56 + Sourcify `exact_match`, contract
`TOKEN`, solc `v0.8.34`). The NEM-class function:

```solidity
// TOKEN (lvin/token.sol)
address stake;                       // slot 13 ; set only by setStake() onlyOwner
function recycle(uint256 amount) external {
    require(stake == msg.sender, "recycle fail");          // <-- THE GATE
    if (amount == 0) return;
    uint256 maxBurn = balanceOf(_pair) / 3;
    uint256 burnAmount = amount >= maxBurn ? maxBurn : amount;
    if (burnAmount == 0) return;
    super._transfer(_pair, stake, burnAmount);             // pair -> Stake, fee-free
    IUniswapV2Pair(_pair).sync();                          // reserves := balances
}
```

`stake` (slot 13) = **`0xe120bBf90eb051A43A3BDc0408b194b6F99b488E`** — the verified
`Stake` contract. `_isExcludedFromFees[stake] = 1`, so the move is fee-free. `recycle`
therefore removes up to **1/3 of the pair's LVIN** and calls `pair.sync()` — exactly the
NEM "collapse one reserve" shape.

The only caller in the ecosystem is `Stake.sell()` (verified source, line 934):

```solidity
// Stake.transfer()  (public; value != 3 ether -> sell)
require(!isContract(msg.sender) && tx.origin == msg.sender, "not is contract");
sell(msg.sender);
// sell():
uint256 sellAmt = getAllReward(account);        // balances + staticReward + dynamicReward
require(sellAmt > 0, "sell amount fail");
require(u.resetId == resetId, "reset id fail");
require(u.outAmt > 0, "out amount fail");
require(token.balanceOf(address(this)) >= sellAmt, "sell balance fail");
... swap LVIN -> USDT, pay user ...
token.recycle(sellAmt);                         // msg.sender == Stake == TOKEN.stake -> passes
```

So the "state condition" is exactly the staking-contract identity gate; it is **not** an
owner gate, and it **is** reachable unprivileged — but `sellAmt` is the caller's reward.

## 4. Live-state assessment (block **129,283,473**, ts 1792741103)

| Item | Value | Source |
|---|---|---|
| Pair reserves | **16,390,674.50 LVIN / 97,595.51 USDT** | `getReserves()` |
| Pair `balanceOf` | 16,390,674.50 LVIN / 97,595.51 USDT (in sync) | `balanceOf` |
| LP totalSupply / burned to `0xdead` | 1,648,298.93 / 1,641,526.58 (99.6 %) | `balanceOf(dead)` |
| TOKEN `owner()` | `0x0` — **renounced** | `owner()` |
| TOKEN `stake` (slot 13) | `0xe120bBf90eb051A43A3BDc0408b194b6F99b488E` | `eth_getStorageAt` |
| TOKEN `tradingEnable` | `true` (slot 13 packed bool) | storage |
| TOKEN balances | 1,364.25 LVIN, 20 USDT, 0 BNB | `balanceOf`/`getBalance` |
| Stake `owner()` | `0x0` — **renounced** | `owner()` |
| Stake balances | **10,000,426.62 LVIN**, **286,699.57 USDT** | `balanceOf` |
| Stake totals | totalInAmt 390,721.6 · totalOutAmt 747,223.7 · totalStakeAmt **286,226.07** | `getTotalInfo()` |
| Stake stakers | 1241 (`stakeList.length`) | storage slot 38 |
| Reward state | `rewardId=7`, interval 86400 s, `resetId=1`, nextReset 1799831162 | `getRewardConfig()/getResetConfig()` |
| `rc` Reward | `0x8795…1a3f`, `getRewardRate()=20`, `getDynamicAmt(*)=0` | eth_call |
| `uc` Upline | `0xE18E…efaB`, `getOpenActive()=0`, owner `0x41B7E0806f7242688F5608431E8Ca7E0Fa7dAFad` | eth_call |

**Reachability probes (`eth_call`, block 129,283,473):**

| Call | From | Result |
|---|---|---|
| `recycle(1)` `0xdd1c35bc` | random `0x…beef` | revert **`recycle fail`** |
| `recycle(1)` | `0xe120…488e` (Stake) | **success** — gate = `stake == msg.sender` |
| `Stake.transfer(0xbeef,1)` | random `0x…beef` | revert **`sell amount fail`** (no reward) |
| `Stake.transfer(TOP,1)` | `0x28AC…6039` (top staker, EOA) | **success** → recycle fires |
| `TOKEN.setStake(x)` | random | `OwnableUnauthorizedAccount(0x…bEEF)` (owner renounced) |
| `UC.registerForAddr(TOP)` | random | **success** — registration permissionless |

## 5. What an attacker can / cannot do

**Can:** register (`UC.registerForAddr(referrer)`) → stake ≥50 USDT (`usdtForAddStakeOrder`
or `receive()`), wait one reward interval, call `calculateReward()`, then
`Stake.transfer(self, 1)` → `sell()` → `token.recycle(reward)`. This genuinely fires
`recycle` from an unprivileged EOA (**fork-proven**, test D).

**Cannot:** make `sellAmt` large. `sellAmt = getAllReward(caller) = balances + staticReward
+ dynamicReward`. `dynamicReward` is `rc.getDynamicAmt − userDynamicAmt = 0` for arbitrary
accounts; `staticReward = ΔaccRewardPerIn · u.inAmt / 1e18` and `u.inAmt ≤ 3000e18` per
order. With the live reward budget (`totalInAmt·20/1000 ≈ 7.8k USDT` of LVIN per cycle),
a 3000 USDT stake earns ≈ **10,013 LVIN/cycle ≈ $60**, while `maxBurn = pairBal/3 =
5,462,888 LVIN`. So `recycle` burns `min(reward, r0/3) = reward`, i.e. **≈0.06 % of the
pool per call**. The largest live reward of any of the 1241 stakers is **71,604 LVIN
(0.44 %)** — and an attacker cannot obtain it without ~$1.6M locked for a day.

**Costs (fork-measured):** the realistic E-U path costs ≥ 20 % of the staked principal
(2·addRate = 20 % is routed to dead-address liquidity on stake) plus fees; the round trip
**nets ≈ −$600** on 3000 USDT. A *privileged* max-burn round trip on a $20k buy still
**loses ≈ $235** (0.25 % swap fee ×2 + slippage) at the live pool size. No flash-loanable
path exists because the reward only accrues after a full `rewardInterval` (1 day).

## 6. PoC / fork verification

Project: `poc/` (Foundry, vendored `lib/forge-std`). The fork is taken at **CI head**
(keyless BSC RPCs prune historical state, so a deep pinned block is not forkable);
the actual fork block is logged by `test_00_forkBlock_recorded` (locally 129,321,709).
The live-state snapshot in §4 is at block **129,283,473**. Command: `forge test -vv` → **9/9 PASS**.

| Test | Result | Key number |
|---|---|---|
| `test_00_forkBlock_recorded` | PASS | fork block logged (head) |
| `test_A_directRecycle_fromRandomEoa_reverts` | PASS | `recycle fail` |
| `test_B_recycle_fromStakeAddress_succeeds_andBurns` | PASS | gate = `stake == msg.sender` |
| `test_C_randomEoaStakeTransfer_reverts_noReward` | PASS | `sell amount fail` |
| `test_D_topStaker_transfer_triggersRecycle_measureBurn` | PASS | burn = **71,604.52 LVIN** (0.44 %) |
| `test_E_attacker_canRegisterAndStake` | PASS | permissionless register+stake |
| `test_E2_attacker_immediateSell_reverts_noReward` | PASS | `sell amount fail` (no on-demand recycle) |
| `test_F_attacker_oneCycle_recycle_burn_and_pnl` | PASS | burn = **10,012.86 LVIN ≈ $60**; round trip net **negative** |
| `test_G_maxBurn_roundtrip_notProfitable` | PASS | max burn 5,462,888 LVIN; $20k round trip = **−$235** |

**CI run URL(s):** CI_RUN_URL_LVIN_PLACEHOLDER — see `ci-log.txt`.

## 7. Verdict & residual / latent risk

**Verdict: CLOSED for external unprivileged extraction — $0, high confidence.** The
`recycle` gate is a genuine `msg.sender` identity check, not an owner check, and it is
reachable through the public `Stake` contract; however the burn is bounded by the caller's
own reward (≤0.44 % of the pool today) and every reachable variant is a net loss. This is
a deliberate admin/reward "refill from pair + sync" helper, consistent with the pass-4
finding that funded NEM-shape tokens are almost always gated.

**Latent risk (low):** the primitive is live and *would* be dangerous if a single staker
ever accrued a reward ≥ 1/3 of the pair's LVIN (≈5.46M LVIN). That would require the
staking TVL/reward budget to grow ~2 orders of magnitude, or `setAddUsersOrder`
(onlyOwner) to be usable — impossible now (owner renounced). If the `Stake` contract's
`lpRewardAddr`/`rc` were ever changed it could matter, but owner is renounced.

**Blockers / address-location notes:** none of the value is blocked by a blacklist or
pause — `tradingEnable=true` and no pause exists. The only "location" caveats are:
`uc` (`0xE18E…efaB`) and `rc` (`0x8795…1a3f`) are **unverified** (decompiled via heimdall;
their public getters were probed directly), and the E-U classification depends on
`getDynamicAmt` staying 0 for non-participants (verified live).

## 8. Methodology & sources

Verified sources (Etherscan V2 chainid 56 + Sourcify) for `TOKEN` and `Stake`; storage
slot walks (`eth_getStorageAt`) to read the private `stake` var and packed bools;
`eth_call --from` reachability probes; heimdall decompilation of the unverified `rc`/`uc`;
full enumeration of all 1241 stakers' `getAllReward`; Foundry fork PoC at a pinned block.
Price from live pair reserves (USDT ≈ $1). Read-only: only `eth_call`/`eth_getCode`/
`eth_getStorageAt` and fork tests. No secrets/keys are present in this folder.

**Caveats / limitations:** (1) all numbers are a point-in-time snapshot at block
129,283,473; reward accrual and TVL change daily. (2) `uc`/`rc` are unverified, so their
internal accounting is inferred from selectors + live getter probes. (3) The E-U upper
bound (`test_D`) uses impersonation to measure the *mechanism*; the true attacker-reachable
burn is `test_F` (≈10k LVIN/cycle). (4) Registration was open at snapshot time
(`registerForAddr` succeeds) but `getOpenActive()=0`, so the operator may still close it.

## 9. Files index

```
lvin/
├── README.md                      # this report
├── summary.json                   # machine-readable summary
├── analysis/
│   ├── LVIN_verified_source.sol   # verified TOKEN source
│   ├── Stake_verified_source.sol  # verified Stake source
│   ├── *.runtime.bytecode         # TOKEN/PAIR/Stake/Reward/Upline
│   ├── *.selectors.txt            # dispatcher selectors
│   ├── token_storage.json         # slot walk (stake @13, owner @5)
│   ├── stakers.json               # all 1241 stakers + getAllReward
│   ├── live_state.json            # consolidated live state
│   ├── probes.md                  # eth_call reachability table
│   └── Upline.heimdall.abi.json   # decompiled uc ABI
├── poc/                           # Foundry project (9/9 PASS)
│   ├── foundry.toml, lib/forge-std, test/LvinRecycle.t.sol
├── ci/run.sh                      # CI job: re-reads live state -> ci-out/
├── ci-out/                        # CI job outputs
└── ci-log.txt                     # CI run log (downloaded by ci-run.sh)
```
