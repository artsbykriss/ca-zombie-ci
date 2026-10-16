# Z3-H17 · Fang (Robinhood Chain, chain id 4663) — Tomb-lineage genesis farm + Masonry/convert surface

**Date:** 2026-10-16 · **Chain:** Robinhood Chain (4663) · **Status:** read-only; PoC fork-verified only; no mainnet transactions
**Scope:** GenesisFarm `0xC01B68919Cd0297B1bf43E4942880E98682D3bbF` (16 pools, all live, all started) · Masonry `0x33Be17082Bd477dC804EdabBa1A8D777Da3F668d` · gFANG `0x6376010d9D1F64de70D9e83c4093c8294515aC28` · xGFANG `0x6D60D2B9973Da40B5124358550d213BA8f266dF7` · FANG `0x9E7739480b45602e1706cE7369e06698F20052e1` · FangRedeem `0x6EF1e61E39195fA53189A9A880A89eF1D06E6F47` · Treasury `0x7399ef6694b6357Ee4BF3C51C83aa4450958851e` · Convertible (referenced by farm, unset) + ZapperGFang `0x430A4a289f4c374FB8EA9e935e7A39c46942E77F`
**Method:** full review of every verified source in the Fang bundle (GenesisFarm/Convertible/xGFANG/GFANG/FANG/Masonry/Treasury/FangRedeem/Zappers/reward-pool, ~7.2k LOC), diff-style screen against canonical Tomb GenesisPool/Masonry, live RPC state reads at `eth_blockNumber` block space, and a 7-test adversarial Foundry fork suite executed against live state.

---

## 1. TL;DR

| target | live extractable (unprivileged) | why closed / open | latent risk |
|---|---|---|---|
| GenesisFarm deposit/withdraw accounting (all 16 pools, $2.86 M) | **$0** | canonical Tomb GenesisPool math; only modification = SpiritSwap 2 % deposit fee. Fork-proven: 1,000.000000 USDG round trip returns 980.000000 — attacker net **−20.00 USDG**, owner +20.00 (T2) | owner `setConvertible` + `governanceRecoverUnsupported` after poolEnd+90 d (P) |
| fee-on-transfer / rebasing token mismatch | **$0** | empirical probe of **all 16 pool tokens**: every transfer delivered 1:1 (0 FoT tokens detected, block-level fork); direct transfers to the farm create **no** stake credit (T3) | an FoT token could later strand value for *other* users (shortfall ≤ fee−2 %), never attacker-positive |
| `convert()` window (principal → xGFANG/MCD at launch price) | **$0 today** | `convertible == 0x0` live → any `convert()` reverts `"GenesisFarm: convertible not set"` (T1); window opens only after `poolEndTime` (2026-10-21 17:00 UTC) and only if owner arms it | **E-U-conditional on owner mispricing**: conversion prices are owner-set in `Convertible`; FCFS + doubling per-user caps; mispricing = arbitrage at protocol expense (post-Oct-21) |
| reward-debt accounting / emission math | **$0** | `updatePool` on every deposit/withdraw/harvest; `rewardDebt` reset each touch; fork-proven reward paid == `pendingReward` at claim block (T2) | none found (dust < 1 wei) |
| Masonry staking share price / donation | **$0** | no share-price math: 1:1 staking of gFANG; a 50 gFANG donation left `totalSupply` at the real stake and `earned()` unchanged — donation **stranded** (T4) | donations are unrecoverable by design (`governanceRecoverUnsupported` blocks `fang`/`share`) |
| xGFANG redeem ratio gaming | **$0** | live `redeemingEnabled == false` → redeem reverts (owner-gated); with it enabled the math is honest: 0-duration forfeits 90 %, 3-day = exactly 1:1, net **−0.9 xGFANG** per round trip (T5) | owner toggle (P) |
| **`FangRedeem.redeemFang` — fixed $1.00 for ANY caller** | **$0 today (pot = 0 USDC)** | permissionless, no allowlist, fixed 1.000000 USDG per FANG — but the contract holds **0 USDG** live → `"Insufficient USDC"` (T6) | **E-U-conditional**: the moment the owner funds the pot (`supplyUSDC`) and FANG trades < $1, any holder drains it at $1/FANG. Fork-demonstrated: funded pot of 1,000.00 USDG drained to 0 in one call |
| Treasury / seigniorage | **$0** | `epoch == 0`, `startTime` 2026-10-21 19:00 UTC; permissionless `allocateSeigniorage()` reverts `"Treasury: not started yet"` (T7) | post-TGE crank mints FANG **to Masonry stakers** (bootstrap 1.5 %/epoch × 12) — protocol emission, not attacker extraction (competition for emissions = yield race) |
| GFANG `claimRewards()` | **$0** | permissionless but mints only the time-accrued dev-fund rate to `devFund` (owner EOA); no attacker receivable | none |

**Total live extractable now: $0.00 — confidence high** (fork-proven negatives on every candidate path; live state at `eth_blockNumber = 89,767,423` for the value snapshot; test forks ran at 89,765,718–89,767,423 block space). The only genuine defect found is **conditional**: a permissionlessly-drainable, fixed-$1 redemption contract that is currently **unfunded**.

## 2. The mechanism, in exact terms

### 2.1 GenesisFarm — Tomb GenesisPool + SpiritSwap deposit fee (verified fork)

`GenesisFarm.sol` (solc 0.8.19, `Proxy: 0`) is `TombGenesisRewardPool` with exactly the deviations its own comments advertise: OZ Ownable/ReentrancyGuard, per-pool `depositFeeBP` (SpiritSwap block), deposits close at `poolEndTime`, owner-reschedulable start (pre-start only), and an add-on `convert()` window. The value paths:

```solidity
// deposit (line ~267): fee is taken from the credit, paid to owner() in the deposit token
pool.token.safeTransferFrom(_sender, address(this), _amount);
if (pool.depositFeeBP > 0) {
    uint256 depositFee = _amount * pool.depositFeeBP / 10000;
    pool.token.safeTransfer(owner(), depositFee);
    user.amount = user.amount + _amount - depositFee;
}
user.rewardDebt = user.amount * pool.accRewardPerShare / 1e18;
```

```solidity
// convert (line ~389) — unreachable today (convertible unset); window = [poolEndTime, +24h)
require(convertible != address(0), "GenesisFarm: convertible not set");
...
_withdraw(_pid, _amount, false);              // debit principal, keep tokens in farm
token.forceApprove(convertible, _amount);
pegTokenOut = IConvertible(convertible).convert(address(token), _amount, msg.sender);
// Convertible (onlyFarm) pulls _amount to its treasury, pays gmcd at owner-set USD prices/caps
```

Everything else matches upstream Tomb line-for-line: `updatePool` uses `pool.token.balanceOf(address(this))` as the share denominator, reward slices are `generated * allocPoint / totalAllocPoint`, `getGeneratedReward` hard-stops at `poolEndTime`, and each user path (`deposit`, `withdraw`, `harvest`) updates the pool **before** touching user state. Live: 16 pools, alloc points sum 10,000, **every pool charges 2 % `depositFeeBP`**, `rewardPerSecond = 9.920634920634920e15` xGFANG/s over a 7-day genesis.

### 2.2 xGFANG (escrowed reward token, verified)

Non-transferable except whitelisted (`xGFANG` itself + the farm are the only 2 whitelist entries). `convert()` pulls GFANG 1:1 to mint xGFANG. `redeem()` is behind `redeemingEnabled`, which is **false live** (owner toggle). The ratio curve (`getGfangByVestingDuration`) is `10 %..100 %` linear over `0..3 days` — honest in both directions (T5).

### 2.3 Masonry (Tomb Masonry, verified)

1:1 staking of gFANG with RPS snapshots; `totalSupply() == 0` live (nothing staked); FANG rewards arrive only via `allocateSeigniorage` (operator = Treasury, and only after TGE). No share-price mechanism → donations cannot inflate anyone's claim; a donation raises `gFANG.balanceOf(Masonry)` but nothing else (fork-proven stranded, T4). Withdraw/claim are additionally epoch-locked (4/2/8 epochs; `treasury.epoch() == 0` today).

### 2.4 FangRedeem — the one real defect (conditional)

```solidity
// FangRedeem.sol — PUBLIC, no access control, fixed 1.00 rate
function redeemFang(uint256 fangAmount) external nonReentrant returns (uint256 usdcAmount) {
    require(fangAmount % 1e12 == 0);
    usdcAmount = fangAmount / 1e12;                     // 1e18 FANG -> 1e6 USDG, hard-coded $1.00
    require(USDC.balanceOf(address(this)) >= usdcAmount, "Insufficient USDC");
    FANG.safeTransferFrom(msg.sender, owner(), fangAmount);
    USDC.safeTransfer(msg.sender, usdcAmount);
}
```

Any external caller can buy FANG anywhere and force the contract to pay **$1.00** per FANG. There is no admin switch, no pause, no per-user limit. The only reason this is not a live drain is that the contract's USDG balance is **0** — the pot is funded exclusively by `supplyUSDC` (`onlyOwner`). The pool it converts against (`GFANG/USDC` 0x28eAc301… used by the Zapper) is also **empty** (reserves 0), and the gFANG/FANG markets do not exist yet (gFANG: 2 lifetime transfers; FANG: 2 lifetime transfers, none since block 85,234,475) — so there is no venue to obtain FANG below $1 *today* even if the pot were funded.

## 3. Live-state assessment (2026-10-16 · `eth_blockNumber` 89,767,423 for values; state reads at 89,757,709–89,767,423)

- **GenesisFarm** `0xC01B68…3bbF` — verified (solc 0.8.19), `Proxy: 0`. `poolLength = 16`; `poolStartTime = 1,791,997,200` (2026-10-14 17:00 UTC); `poolEndTime = 1,792,602,000` (2026-10-21 17:00 UTC, ~5 days ahead); `runningTime = 604,800`; `totalRewards = 6,000e18`; `rewardPerSecond = 9.9206e15`; `totalAllocPoint = 10,000`; `owner = 0x608730AabB55eE45Af29dADCC93bdB63470f0420` (**EOA, code = 0x**); `convertible = 0x0`; xGFANG reward pot = **5,802.7669 xGFANG**.
- **Pool balances (the $2.86 M at risk)** — priced with DefiLlama (2026-10-16, chain `robinhood`); full table in `live_snapshot.json`:

| pid | token | amount | price | USD |
|---|---|---|---|---|
| 1 | USDG (6dp) | 1,036,883.458847 | $0.99989 | $1,036,769.88 |
| 0 | WETH | 366.811263 | $2,427.63 | $890,482.43 |
| 14 | USDe | 301,071.359671 | $0.99916 | $300,819.40 |
| 10 | r33 | 4,016,827.457842 | $0.06611 | $265,535.32 |
| 4 | SPY | 107.105453 | $771.78 | $82,661.31 |
| 3 | NVDA | 335.934549 | $217.88 | $73,191.74 |
| 9 | RVH | 8,718,376.777146 | $0.005795 | $50,523.32 |
| 2 | wsNET | 48.181103 | $834.65 | $40,214.31 |
| 6 | PONS | 107,119.175112 | $0.33311 | $35,681.98 |
| 7 | CASHCAT | 241,180.274881 | $0.11819 | $28,505.75 |
| 15 | SHROOM | 2,791,613.560047 | $0.007348 | $20,513.02 |
| 11 | GIGA | 3,240,894.011844 | $0.005890 | $19,088.33 |
| 5 | AI | 168,165.486742 | $0.10745 | $18,070.19 |
| 8,12,13 | fBOMB / MCD / s33 | 2,008,963.97 / 738,791.12 / 4,144.76 | unpriced | — |
| | **total priced** | | | **$2,862,056.97** (DL TVL $2,874,309 on 2026-10-16 — matches) |

- **All 16 pool tokens verified on Etherscan V2 (chain 4663)** except USDE `0x5d3a1Ff2…` (no verified source; standard ERC-20 behavior confirmed empirically). fBOMB/NVDA/SPY/WETH/USDG are proxies (fBOMB impl `0xcd4f9a34…` is unverified) — behavior probed empirically rather than assumed.
- **Masonry** `0x33Be17…668d` — verified (solc 0.8.26), `initialized = true`; `share = gFANG`, `fang = FANG`, `treasury = 0x7399…851e`, `operator = treasury`; **`totalSupply = 0`**, FANG balance 0; `claimRewardOtherEnabled = true`; `buybackWalletAddress = 0xc12e8269…`; lockups 4/2/8 epochs.
- **gFANG** `0x6376…5aC28` — verified; `totalSupply = 60,000e18`; owner EOA holds 54,000e18; xGFANG holds 6,000e18 (1:1 backing); operator = Treasury. Only 2 lifetime transfers (mint + the 6,000 → xGFANG).
- **xGFANG** `0x6D60D2B9…` — verified; `totalSupply = 6,000e18` **fully backed** (`gFANG.balanceOf(xGFANG) = 6,000e18`); `gfangToken = gFANG` (mint disabled); `redeemingEnabled = false`; ratios 10→100 over 0→259,200 s; whitelist length 2 (self + farm).
- **FANG** `0x9E77…52e1` — verified; `totalSupply = 252,000e18`; owner EOA 2,000e18; **250,000e18 at `0x145814600c843f7652318583282fb425a7bb6c21`** since block 85,234,475; `operator = Treasury` (mint gated); no transfers since. No DEX pool for FANG exists.
- **FangRedeem** `0x6EF1e6…6F47` — verified; `FANG`/`USDC` immutable (USDG `0x5fc5…d168`); **USDC balance = 0**; `quoteRedeem(1e18) = 1e6`.
- **Treasury** `0x7399ef…851e` — verified; `initialized = true`; `epoch = 0`; `startTime = 1,792,609,200` (2026-10-21 19:00 UTC); fang/gfang/masonry/oracle `0x430991995F7e849b03e3E895f02bEb2791d39026` wired; `operator = owner EOA`; dao/dev/team funds configured; bonds are permanently disabled (`buyBonds`/`redeemBonds` revert).
- **DEX surface:** the protocol's own GFANG/USDC Shadow LP `0x28eAc301FF97864f7F887A4fE4529f401A398045` has **0 reserves / 0 LP supply**; no other gFANG/xGFANG/FANG venue found. Everything is closed-loop until TGE.

## 4. What an attacker can / cannot do (exact paths)

Can (all fork-verified, none profitable):

- Deposit any of the 16 tokens and withdraw the credited amount + accrued xGFANG (`deposit`/`withdraw`/`harvest`). Round trip costs the 2 % deposit fee — measured exactly: **−20.00 USDG on a 1,000.00 USDG round trip** (T2), rewards paid == pending reward at claim (T2).
- Transfer tokens directly to the farm (no credit, no reward — T3), to Masonry (stranded donation, no effect on `earned()` — T4), or hold xGFANG (no transfers to third parties unless whitelisted).
- Call `convert()` — **reverts** (`convertible` unset) — T1. Call `redeem` on xGFANG — **reverts** (`redeemingEnabled=false`) — T5. Call `Treasury.allocateSeigniorage()` — reverts pre-start — T7. Call `redeemFang` — reverts while the pot is unfunded — T6.
- Call `GFANG.claimRewards()` any time — mints the time-accrued amount **to devFund**, never to the caller.

Cannot:

- Extract another user's principal or the xGFANG reward pot: `user.amount`/`rewardDebt` are per-user, withdrawals are bounded by the user's own credit (`require(user.amount >= _amount)`) — T2/T3.
- Profit from any FoT/mint-on-transfer discrepancy: 0 of 16 tokens charge transfer fees; and even a hypothetically FoT token cannot make a single attacker round trip positive (credit = nominal − 2 % ≤ nominal, while any fee reduces what the farm receives — the attacker's **own** loss is ≥ 2 % either way).
- Inflate Masonry `earned()` by donation or share inflation: there is no price-per-share; donations are inert (T4).
- Reach any operator/owner function as a fresh caller: `setConvertible`/`set`/`add`/`governanceRecoverUnsupported` (farm), `setOperator`/`setLockUp`/`allocateSeigniorage`/`governanceRecoverUnsupported` (Masonry), `mint`/`setRedeemingEnabled`/`update*` (xGFANG/GFANG), `supplyUSDC`/`retrieveUSDC` (FangRedeem), `masonrySetOperator`/`setExtraFunds` (Treasury) — all `onlyOwner`/`onlyOperator` (T4 proves the revert for `allocateSeigniorage`).

## 5. PoC / fork verification

- File: `poc/test/Fang.t.sol` — `contract FangH17Test is Test` (unique name), self-contained, forks Robinhood Chain via keyless public RPC (`RHO_RPC` env override honored, else `rpc.mainnet.chain.robinhood.com` → `robinhood-rpc.publicnode.com` → `robinhood.drpc.org`). No keys, no mainnet txs.
- **Local run: 7/7 PASS** (log: `analysis/fang/poc-run-local.log`; fork block space 89,765,718–89,767,423). Final CI run is executed by the parent (Z3-H17) per the cluster protocol.

| test | result | key numbers |
|---|---|---|
| T1 live state / convert closed | PASS | 16 pools, alloc 10000, fee 200 bp; `convert` reverts `"GenesisFarm: convertible not set"` |
| T2 USDG round trip + reward debt | PASS | in 1,000.000000 USDG → out 980.000000; attacker **−20.00**, owner **+20.00**; reward paid == pending |
| T3 FoT probe (16 tokens) + no-credit | PASS | **0 FoT tokens**; all 1:1; raw transfer → `userInfo.amount = 0`, `pendingReward = 0` |
| T4 Masonry donation/lockup/operator | PASS | 50 gFANG donation stranded; `earned` unchanged; withdraw reverts lockup; `allocateSeigniorage` operator-only |
| T5 xGFANG redeem | PASS | live revert (`redeemingEnabled=false`); after owner-enable: 0-duration → 0.1e18 (90 % forfeit), 3-day → 1:1; net −0.9e18 per 2e18 |
| T6 FangRedeem fixed $1 | PASS | live: `"Insufficient USDC"` (pot=0); funded demo: 1,000.00 USDG drained by one call at $1/FANG |
| T7 Treasury pre-start | PASS | epoch 0; `allocateSeigniorage` reverts `"Treasury: not started yet"` |

- **Known repo blocker (parent owns the fix):** `poc/src/ForkHelper.sol` does **not compile** against the vendored `lib/forge-std` 1.9.6 — its `VM_ADDRESS` constant redeclares `Base.VM_ADDRESS` (solc error 9097, "Identifier already declared"), and because the file fails standalone, every `forge test` in `poc/` fails to build until it is fixed (drop the constant and use `vm` from `Test`). My test therefore does not import it and implements the identical env-override/fallback logic locally. My local runs used a minimal out-of-tree project (`/tmp/opencode/fang-poc`, symlinked forge-std, same `flock` lock) since compiling inside `poc/` is impossible until `ForkHelper.sol` is repaired. Once fixed, `poc/test/Fang.t.sol` compiles and runs unmodified.

## 6. Verdict and residual/latent risk

- **E-U (external unprivileged, live): $0.00 — high confidence.** Every candidate path was reduced to a concrete call sequence and fork-falsified or code-gated: farm round trips lose the 2 % deposit fee; no FoT token; reward-debt math canonical and fork-verified; `convert()` unreachable; xGFANG redeem owner-disabled with honest math; Masonry has no share-price mechanism and is empty; Treasury not started; FangRedeem pot empty.
- **E-U-conditional (the one real defect)** — `FangRedeem.redeemFang`: permissionless fixed **$1.00/**FANG payout. Trigger: `USDG.balanceOf(0x6EF1e61E39195fA53189A9A880A89eF1D06E6F47) > 0` (owner calls `supplyUSDC`, or any future integration pre-funds it) **while FANG is obtainable below $1.00** (post-TGE market, or the genesis `convert()` window). Value = the pot balance, drained to zero; no caps. Measured demo: $1,000 pot → $0 in one call.
- **E-U-conditional (secondary)** — `GenesisFarm.convert()` window (auto-opens 2026-10-21 17:00 UTC, only usable if the owner arms `setConvertible`): owner-set `tokenPriceUsd`/`mcdPriceUsd` + per-user doubling caps make it a launch-price mechanism; **any mispricing is FCFS arbitrage against protocol funds**. Review `Convertible` state before/at TGE.
- **H-O:** $2.86 M genesis principal is self-service withdrawable by its ~depositors (plus 5,802.77 xGFANG reward pot claimable by stakers; no market price yet). The farm's `withdraw` has no pause and no fee.
- **P:** the entire TVL + protocol flow is owner-controlled over time: `setConvertible`/`set`/`add` on the farm; after `poolEndTime + 90 days`, `governanceRecoverUnsupported` can sweep **pool tokens and the reward token** (before that, both are protected — the guard is real); xGFANG `setRedeemingEnabled`, `mint` (disabled while GFANG set); FANG/GFANG operator mints (Treasury); FangRedeem `retrieveUSDC`/owner. Owner and deployer are the **same EOA** `0x608730…` (no multisig, no timelock seen on these contracts).
- **S:** dormant/unpriced value only — donation-style transfers to Masonry or the farm (fork-proven unrecoverable by the sender: Masonry's guard blocks `fang`/`share`; the farm guard blocks pool tokens for 90 days then goes P).
- **Monitors:** (1) `USDG.balanceOf(FangRedeem) > 0` → re-arms E-U-conditional #1; (2) `GenesisFarm.convertible() != 0` or block time ≥ 1,792,602,000 → window arms (check `Convertible` prices/caps/balance); (3) any FANG/gFANG DEX pool appearing with price < $1.00; (4) `xGFANG.redeemingEnabled == true`; (5) `Masonry.totalSupply > 0` (staking live) and Treasury `epoch` advancing; (6) owner transfers of farm ownership or unexpected `governanceRecoverUnsupported`.

## 7. Methodology & sources

Read-only throughout. Verified sources pulled via Etherscan V2 (chain 4663) for every contract cited and saved under `analysis/fang/sources/` (GenesisFarm bundle, xGFANG, FANG, Treasury, FangRedeem, ZapperGFang, 13 of 16 pool tokens + fBOMB impl probe). Tomb-lineage screen: line-by-line comparison of GenesisFarm/Masonry against canonical Tomb GenesisPool/Masonry semantics (the code comments' "MODIFIED" claims were re-verified — they hold; deviations are exactly the fee block, deposit cutoff, rescheduling, and the additive `convert`). Live state via keyless public RPC (`cast call`/`storage`/`code`), values priced with `coins.llama.fi` (chain `robinhood`) at block 89,767,423. Event/holder history via Etherscan V2 `tokentx` (the Robinhood public RPC refuses `eth_getLogs`). Adversarial 7-test fork suite with fresh attacker, exact expected values under 3 decimals, and revert-string assertions (`poc/test/Fang.t.sol`, 7/7 PASS locally; parent runs final CI).

**Caveats:** (a) `poc/src/ForkHelper.sol` compile blocker — see §5, must be fixed by the parent or CI fails before any test runs; (b) fBOMB/MCD/s33 are unpriced → ~$12 k of TVL unvalued (DL total still matches within 0.4 %); (c) `Convertible` is not deployed-or-unset at the farm, so its eventual `gmcd` token and prices are unknown — post-TGE re-screen recommended; (d) the FANG/USDG "USDC" in this ecosystem is USDG `0x5fc5…` (6dp) — name/symbol mismatch is intentional protocol-wide; (e) block-number citations use `eth_blockNumber` space (Robinhood header numbering differs, see cluster facts); (f) screenshots of share/earned flows use fork state; nothing was signed or sent.

**Files:** `README.md` · `summary.json` · `analysis/fang/sources/**` (verified sources per contract) · `analysis/fang/live_state_block89757709.txt` · `analysis/fang/live_snapshot.json` (balances + prices + block) · `analysis/fang/farm_balances.txt` · `analysis/fang/token_decimals.txt` · `analysis/fang/fang_tokentx.json`, `gFANG_tokentx.json`, `xGFANG_tokentx.json`, `USDGfarm_tokentx.json` · `analysis/fang/poc-run-local.log` · `poc/test/Fang.t.sol`.
