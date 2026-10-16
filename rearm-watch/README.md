# rearm-watch — Z3-H6/H7/H9/H10 "re-arm-on-deposit" cluster (BitBay · X7 Finance · Unistreet · DAOstack)

**Date:** 2026-10-16 · **Chains:** Polygon (BitBay), Ethereum (X7, Unistreet, DAOstack) · **Tier:** HIGH
**Status:** read-only research; all PoCs fork-verified only; **no mainnet transactions signed or sent**.
**Live reads:** Ethereum block **26,201,7xx**, Polygon block **95,605,4xx** (2026-10-16 ~01:30 UTC) unless stated.

---

## 1. TL;DR

| # | Target | Live extractable today (E-U) | Why closed/open today | Re-arm trigger | Capture per re-arm | Confidence |
|---|--------|------------------------------|------------------------|----------------|--------------------|------------|
| H6 | **BitBay `UsdcDaiV4Vault`** `0x048E8831…e5A0` (Polygon) | **$0** | Vault empty **and** the minter flipped `mintThis=true` at 2026-10-16 01:07:39 UTC (block 95,605,021) → `reposition()` is minter-gated | (a) `mintThis`→false + any deposit; **or** (b) minter-mode race: attacker parks the pool price at the exact range-top boundary and the **minter's own** recentering reposition zeroes `liquidity` | **100 % of the vault's DAI+USDC balance** (fork: 5,000.34 DAI swept by a 1-wei share; net 4,969.39 DAI after swap cost) | high |
| H7 | **X7 Finance `X7Pioneer`** `0x70000299…e4f7` (Ethereum) | **$0** (pool holds **0.021581 ETH = $52.72**) | Mechanism live and fork-proven, but the drain requires owning a never-claimed tokenId and **there are zero listings / no public mint** — a fresh attacker cannot acquire a usable NFT at any price today | Any ETH inflow into the contract (fee routing/donations; ~0.0027 ETH/day accrued since the Oct-8 drain) **plus** a token becoming acquirable for < balance | **100 % of the contract's ETH balance B** (fork: B=0.021581 ETH captured net; a +0.5 ETH deposit was captured 100 % in cycle 2) | high (mechanism/state); acquisition blocker certain |
| H9 | **Unistreet `LaunchpadFactoryAuto`** `0xFB60CD0B…D825` (Ethereum) | **$0** | Factory custody = 0 positions; launchpad dormant since 2026-08-05 | **Every new launch** through the factory (seed liquidity) recreates a factory-custodied LP position | **100 % of every new launch's LP position** (fork: fresh 0.025 ETH-seed launch → attacker swept 60.95 USDC + 988,428 PIGCON) | high |
| H10 | **DAOstack Genesis Alpha** Avatar `0x7b11dFb2…6DB0` (Ethereum) | **$0** | Avatar empty (drained 4.025 ETH 2026-09-26) | **Any ETH (or token) inflow** to the Genesis Alpha avatar | **100 % of the inflow** (fork: re-funded 4.025 ETH → captured 4.0256 ETH by a fresh attacker; cost = gas only) | high |

**Total live extractable now: $0.00 (high confidence).** All four are re-armable; the next deposit/launch/funding re-opens each pot in full. Capture-per-event figures above are fork-measured, not estimated.

---

## 2. Mechanisms (exact)

### H6 — BitBay `UsdcDaiV4Vault` (Polygon)
Source: verified `StableVault.sol` (solc 0.8.x), **not a proxy** (no EIP-1967 slots) → immutable.

```solidity
function _withdraw(uint256 shareAmount, address recipient, bool addDust) internal {
    if (liquidity == 0) {                       // <-- branch pays the WHOLE balance
        uint256 daiBal  = DAI.balanceOf(address(this));
        uint256 usdcBal = USDC.balanceOf(address(this));
        if (daiBal  > 0) DAI.transfer(recipient, daiBal);   // no share weighting
        if (usdcBal > 0) USDC.transfer(recipient, usdcBal);
        emit Withdrawn(recipient, shareAmount, daiBal, usdcBal);
        return;
    }
    ...
}
function reposition(uint256 deadline) external nonReentrant {
    if (mintThis) { require(msg.sender == minter, OnlyMinter()); }   // gated since 2026-10-16 01:07
    if (msg.sender != minter) {
        int24 ct = _getCurrentTick();
        if (ct >= tickLower && ct < tickUpper) revert PositionInRange(); // permissionless when out of range
    }
    require(block.timestamp > lastReposition + POSITION_TIMELOCK, Expired()); // 129,600 s (1.5 d)
    ...
}
```
Attack (proven 2026-10-09, 14,838 DAI; and re-proven on a fork today):
1. `deposit(1 wei)` → 1-wei share (permissionless, no gate).
2. Public V4 swap pushes the pool tick to the **top of the vault's range** — the swap price limit must be `sqrtPriceAtTick(tickUpper+1) − 1` so the price lands in the last wei of tick `tickUpper`; then `_getRequiredRatio` integer-rounds to 0, `_reposition` performs no rebalancing swap and `newLiquidity` truncates to **0**, leaving the whole position value as raw token balance.
3. `reposition()` (permissionless when `mintThis=false`).
4. `withdraw(1)` → entire balance to the caller.

### H7 — X7 Finance `X7Pioneer` (Ethereum)
Verified source, immutable.
```solidity
function claimRewards(uint256[] memory tokenIds) public nonReentrant {
    if (lastETHBalance < address(this).balance) {
        totalRewards += (address(this).balance - lastETHBalance);   // runs on EVERY call
    }
    for (...) {
        require(ownerOf(tokenIds[i]) == msg.sender);                // payout needs an owned token
        uint256 tokenTotalRewards = totalRewards / totalSupply();
        if (rewardsClaimed[id] < tokenTotalRewards) claimable += tokenTotalRewards - rewardsClaimed[id];
    }
    if (claimable > 0) {
        lastETHBalance = address(this).balance - claimable;         // refreshed ONLY when claimable > 0
        (bool ok,) = msg.sender.call{value: claimable}("");         // claim <= balance (else underflow revert)
    }
}
```
The accumulator is bumped on every call but the balance baseline only moves on a payout → any ETH that lands in the contract can be re-counted. An owner of a **never-claimed** token can claim up to the entire balance; the single optimal call is: donate `L ≈ (totalRewards/totalSupply − B) / (1 − 1/totalSupply)`, then `claimRewards([id])` (the claim's own bump adds `L`). `L ≈ 33.80 ETH` today because the October exploit left `totalRewards` inflated at 21,580 ETH.

### H9 — Unistreet `LaunchpadFactoryAuto` (Ethereum)
Verified source; **not a proxy** (EIP-1967 slots zero, 9,323-byte runtime — Etherscan's "proxy" flag is a false positive from the `implementation()` getter used by the token clones).
```solidity
function launch(Params calldata p, bytes calldata initCalldata, bytes calldata modifyCalldata, SeedBuys calldata sb)
    external payable returns (address token) {
    token = Clones.cloneDeterministic(implementation, p.salt);
    ...
    bytes[] memory calls = new bytes[](2);
    calls[0] = initCalldata;      // caller-supplied, unvalidated
    calls[1] = modifyCalldata;    // caller-supplied, unvalidated
    IPositionManager(POSITION_MANAGER).multicall(calls);   // executes AS THE FACTORY
    ...
}
```
The factory is the ERC721 owner of every launch's LP position. `modifyCalldata = setApprovalForAll(attacker, true)` (injected through the attacker's own throwaway launch) makes the attacker an operator over **all** factory-custodied positions; `POSM.modifyLiquidities(BURN_POSITION + TAKE_PAIR)` then sweeps them. The 4 operator approvals injected during the August incident are **still live on the PositionManager today** (verified), so any *new* position would be instantly sweepable by those old operators too; a fresh attacker needs their own cheap injection launch.

### H10 — DAOstack Genesis Alpha (Ethereum)
`UController` `0xD5bEe5D9…7305` is permissionless and unverified (not a proxy). `newOrganization(avatar)` trusts the caller-supplied avatar's `nativeReputation()`/`nativeToken()`; a shape-shifting fake avatar (decoy on the first getter read, the victim's real Reputation afterwards) registers the caller as a full-permission (0x1F) scheme against the **victim's** Reputation. The UController owns that Reputation, so the scheme can `mintReputation` itself a majority, pass any `SchemeRegistrar` proposal on the real avatar (self-vote) and `sendEther` the treasury out. Cost = gas only.

---

## 3. Live-state assessment (all read on-chain)

| Contract | Address | Code | Key live state (block) |
|---|---|---|---|
| BitBay vault | `0x048E88311ca84876aeA086125825492e2AF2e5A0` | verified, immutable | DAI 0, USDC 0, `liquidity()` 0, `totalShares` 14,837.6448e18, `mintThis` **true** (since block 95,605,021, tx by minter `0xC70F0Ec9…F29c` calling `minterOnly(true)`), tick `[276324,276327)`, `lastReposition` 2026-10-09 02:23:42 UTC (Polygon 95,605,382) |
| X7Pioneer | `0x70000299Ee8910cCaCD97B1bB560E34F49c9e4f7` | verified, immutable | balance = `lastETHBalance` = 21,581,365,277,773,518 wei (0.021581 ETH, **$52.72** @ $2,443.04); `totalRewards` 21,580.12e18; `totalSupply` 639; `rewardsClaimed(300)` 33.7717e18; `unclaimedRewards(300)` **0**; `unclaimedRewards(0)` 33.7717 ETH (> balance → claim reverts) (ETH 26,201,7xx) |
| Unistreet factory | `0xFB60CD0B36aD4bD839b91767a6Ad9055AB6aD825` | verified, immutable | factory ETH 0; `POSM.balanceOf(factory)` **0**; `launchesCount` 19; last real launch 2026-08-05; 4 incident operator approvals still `true` on POSM `0xbD216513…ee9e` (ETH 26,201,7xx) |
| DAOstack avatar | `0x7b11dFb29504abc8C0DFa60DC7E0aa2AAe836DB0` | unverified (framework) | ETH **0**; Reputation `0x62562941…5BF9` supply 20,121,971.0358e18; attacker-#2 holds 20,092,432.41e18 (99.85 %); original attacker scheme `0x304a8e57…` still registered with perms 0x1F and still passes `sendEther` (eth_call) today; only 3 orgs ever on this UController, the other two are attacker fakes with no funds; avatar token dust ≈ $0.03 (ETH 26,201,7xx) |

**Incident references (verified in DeFiHackLabs + on-chain):**
- BitBay: tx `0x5b795dc5…a7ff2` block 95,204,942 (Polygon), 14,838 DAI, attacker `0x59Ae3c8d…884B`.
- X7: tx `0xc98056d6…766d` block 26,146,922, 6.78 ETH net, attacker `0xC7935211…aCf2` (who bought token 300 via Blur for 0.15 ETH 44 min earlier).
- Unistreet: tx `0x9583e95d…6d14` block 25,692,311, ~$17.75k across 7 positions (a second sweeper took the remaining 8 positions 5 min later; all 15/15 drained incl. a second factory `0xd5799fd8…`).
- DAOstack: tx `0xcfff7b06…7cc1` block 26,059,090, 4.025 ETH (plus GEN/WETH by a second attacker 84 s later).

---

## 4. What an attacker can / cannot do

**BitBay (H6) — E-U-conditional, two triggers.**
- Cannot today: vault is empty; `mintThis=true` makes `reposition()` revert `OnlyMinter()` for non-minters (fork-verified).
- Trigger (a): `mintThis` returns to `false` (minter-only setter `minterOnly(bool)`; the value was `false` at least from the Oct-9 incident until 2026-10-16 01:07 UTC, then flipped to `true`) **and** any deposit lands → the full October sequence is live again.
- Trigger (b) — works *even in minter mode*: the attacker (any address) deposits 1 wei and pushes the price to the exact range-top boundary (permissionless swaps), then simply **waits for the minter's routine recentering** `reposition()`; that call zeroes `liquidity` via the same rounding bug, and the attacker's 1-wei `withdraw(1)` sweeps the entire balance. Fork-verified with the minter impersonated at the moment of a real recentering.
- Costs: the manipulation swap is a round-trip (DAI→USDC at the boundary); measured loss **~31 DAI ($31) at current pool depth** (~233k DAI swap, 0.013 %) + gas; profitable for any pot ≳ $40. Capital is flash-loanable (the original attack used nested Balancer loans).

**X7 (H7) — E-U-conditional on NFT acquisition.**
- Cannot today: 639 NFTs, 223 permanently transfer-unlocked, **zero listings on any marketplace** (OpenSea/Blur/CoinGecko floor $0, 0 listed), no public mint (`airdropTokens` onlyOwner, `airdropActive=false`). Only price precedent: 0.15 ETH ($384.63, Blur, 2026-10-08). A fresh attacker without a token cannot extract (fork-tested: claim reverts on the ownership require).
- With a token: donate ~33.8 ETH (Balancer flash loan = 0 fee; Aave = 0.05 % = 0.0169 ETH), one `claimRewards([id])` call pays out balance+donation; **net = the entire pool balance B**. Fork-measured: today net = 0.021581 ETH; after a simulated +0.5 ETH deposit, net = 0.5 ETH.
- Monitor: X7Pioneer balance growth (fee inflows ≈ 0.0027 ETH/day since the drain) and any new marketplace listing of an unlocked token; the original attacker still owns unlocked token 300.

**Unistreet (H9) — E-U-conditional per launch.**
- Cannot today: `POSM.balanceOf(factory) = 0`.
- On the next launch by anyone: a fresh attacker calls `launch()` once (throwaway token, no seed, ~3.5 M gas) with `modifyCalldata = setApprovalForAll(attacker,true)`, then `POSM.modifyLiquidities(0x0311 …)` per custodied position (~250 k gas each) → takes 100 % of every launch's LP value. Fork-verified end-to-end with a byte-exact re-encoded Pigcon launch (0.025 ETH seed → 60.95 USDC + 988,428 PIGCON captured).
- Note: the 4 approvals from the August incident are still live on POSM — those operators can sweep any future position without any new call; the fresh attacker needs their own injection (one launch).

**DAOstack (H10) — E-U-conditional on any inflow.**
- Cannot today: avatar ETH 0.
- On any inflow: a fresh attacker repeats the shape-shifter capture (fork-verified: `newOrganization` still permissionless at the latest block; re-funded avatar of 4.025 ETH fully captured; mint 2× supply to hold ~66 % of the new supply, so the proposal passes even if every incumbent rep holder votes NO). Gas ≈ 1.7 M, no capital. The incumbent attacker schemes (perms 0x1F) can also sweep an inflow with a single `sendEther` call.

---

## 5. PoC / fork verification

Foundry project `poc/` (solc 0.8.24, cancun, via_ir), vendored `forge-std` + Uniswap `TickMath`. **12/12 tests pass** (local run 2026-10-16 ~01:35 UTC; CI run below).

| Test file | Tests | What it proves |
|---|---|---|
| `BitBayRearm.t.sol` | 3 PASS | today's state + live minter gate (non-minter `reposition` reverts); re-arm (a): `mintThis→false` + 5,000 DAI deposit → **5,000.34 DAI swept by a 1-wei share**, net 4,969.39 DAI; re-arm (b): minter-mode race → **5,000.34 DAI swept after the minter's own reposition** |
| `X7Rearm.t.sol` | 3 PASS | today: donated 33.803 ETH → claim paid 33.8246 ETH → **net = the whole pool balance 0.021581 ETH**; re-arm: +0.5 ETH deposit → **net 0.5 ETH**; no-token path reverts |
| `UnistreetRearm.t.sol` | 1 PASS | fresh Pigcon-style launch (0.025 ETH seed) → factory-owned position 463548 → fresh-attacker injection launch → **swept 60.95 USDC + 988,428 PIGCON**, custody back to 0; 4 legacy approvals asserted live |
| `DAOstackRearm.t.sol` | 2 PASS | `newOrganization` still permissionless from a stranger; re-funded avatar (4.025 ETH) → **fresh attacker captured 4.0256 ETH** |
| `BitBayIncident_ref.sol` / `_dbg.sol` | 2 PASS | exact 2026-10-09 incident replay at archive block 95,204,941 (14,838.466608989135865711 DAI swept; `Repositioned` newLiquidity = 0) |
| `SqrtCheck.t.sol` | 1 PASS | tick→sqrt-price mapping used to construct the boundary push |

CI (GitHub Actions, `artsbykriss/ca-zombie-ci`): see `ci-log.txt` / `ci-artifacts/`; run URLs:
- **run 2 (final, PASS):** https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38835297257 — custom job `ci/run.sh` (live-state snapshot + USD pricing → `ci-out/live_state.{txt,json}`, Ethereum block 26,201,780 / Polygon 95,605,652) + `forge test -vvv` → **12 tests passed, 0 failed** (CI log confirms every suite).
- run 1 (failed, fixed): https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38834801702 — the CI secret `POLYGON_RPC_URL` is set-but-empty and `vm.envOr` returned the empty string; fixed with an empty-aware `_rpc()` helper (`poc/src/ForkEnv.sol`) and re-run (run 2 above). The run-1 artifact already captured the CI live-state snapshot.

---

## 6. Verdict & residual risk

- **Headline E-U now: $0.00** across all four (BitBay empty+gated; X7 blocked by NFT acquisition at a $53 pot; Unistreet custody 0; DAOstack empty). Confidence **high** — every claim is fork-verified or read directly on-chain at a pinned block.
- **All four are re-armable in full**; the class name holds literally: the next deposit (or launch, or funding) is captured 100 % by an unprivileged attacker. Capture-per-re-arm: BitBay = vault balance (≥ ~$40 profitable), X7 = contract balance once a token is acquirable, Unistreet = each new launch's seed, DAOstack = any inflow (gas-only cost).
- **BitBay carries an extra live twist**: the operator's own hardening (`minterOnly(true)`, 2026-10-16 01:07 UTC) does **not** close the vulnerability — the minter-mode boundary race (trigger b) is fork-proven; and the same `_withdraw` landmine detonates on any future `liquidity==0` state.
- **X7 nuance**: the current 0.0216 ETH is *not* even holder-recoverable (`unclaimedRewards(300)=0`; unclaimed tokens' claims revert because claimable 33.77 ETH > balance) — it is only reachable through the donation-based re-arm mechanism.
- **Monitors:**
  - BitBay: `mintThis()` flips (topic = `minterOnly` tx from minter `0xC70F0Ec9…F29c`), any `Deposited` event, `liquidity()` becoming 0 while balances > 0.
  - X7: X7Pioneer ETH balance growth; `RewardsClaimed` events; any `TransferUnlocked` + marketplace listing of an unlocked token (223 known ids, list in `analysis/x7_unlocked_tokens.csv`).
  - Unistreet: `Launched` events on the factory (any new launch = fresh pot), `POSM.balanceOf(factory) > 0`, `isApprovedForAll(factory, ·)` new grants.
  - DAOstack: any ETH transfer to the Genesis Alpha avatar; `mintReputation`/`newOrganization`/`sendEther` events from the UController.

**Blockers/uncertainty:**
- X7's acquisition blocker could vanish if the original attacker (or any of the 113 unlocked-token owners) lists a token at a price < the pool balance; the pool balance also grows over time.
- BitBay trigger (b) requires the attacker to *hold* the exact boundary price until the minter repositions (arbitrage pressure pulls it back; the attacker can re-push at gas cost). Not fork-tested against real arbitrage bots, but the code path is proven.
- DAOstack: fresh-attacker capture assumes the dormant incumbent rep holders do not vote NO *en masse*; minting 2× supply keeps YES > all incumbent NO votes in the current distribution (verified arithmetic; incumbent EOAs hold ~0 ETH and have been dormant since Sept).

---

## 7. Methodology, sources, caveats

- Sources of truth: verified sources from Etherscan V2 (`analysis/sources/`), DeFiHackLabs PoCs (BitBay/X7/Unistreet/DAOstack `*_exp.sol`), on-chain reads via public RPCs (blocks recorded), DefiLlama prices (ETH $2,443.04, DAI $1.0001, USDC $0.9996 at 2026-10-16 ~01:35 UTC).
- The corpus notes were treated as leads only; every address/role/balance/state used in the verdict was re-read on-chain (see `analysis/*.md`).
- Fork tests are read-only simulations; no mainnet transaction was signed or sent. No keyed RPC URLs or secrets appear in any file (scripts use public endpoints or CI-injected env vars; scan clean).
- Caveats: X7 token-value/marketplace data comes from public marketplace pages (the provided OpenSea key is invalid/401); the Unistreet victim-launch calldata is a byte-exact re-encoding of the incident's own Pigcon launch with a fresh salt (verified `eth_call` + fork e2e); DAOstack's UController is unverified — behavior was established empirically (fork) rather than from source.

**Files index:** `README.md` (this) · `summary.json` · `analysis/` (state dumps, verified sources, child reports: `daostack_orgs.md`, `x7_nft_market.md`, `unistreet_launch_decode.md`, `unistreet_launch_calldata.json`) · `poc/` (Foundry project, 12 tests) · `ci/run.sh` (live-state snapshot job) · `ci-out/` (CI artifacts) · `ci-log.txt` · `ci-artifacts/`.
