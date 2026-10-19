# Genius.fun (BSC) — `forceSweptGraduation` / `GRADUATION_RESCUE_DELAY` race

**Date:** 2026-10-20 · **Chain:** BNB Smart Chain (chainId 56) · **Mode:** read-only; no transaction was signed, broadcast or sent. All state-changing calls below are `eth_call` simulations (archive block included).
**Primary block:** 128,633,968 (2026-10-19T22:26:34Z) · **Token-balance block:** 128,636,514 · **Head at read:** 128,638,486.
**Verdict:** **E-U = $0.00 live, confidence HIGH.** The pass2 lead is real as a *privileged* fund-custody path, but it is not callable by an unprivileged attacker: `forceSweptGraduation` and `rescueSweptGraduation` are both `onlyOwner`, the owner is a 2-of-3 Safe, the factory and every curve hold no pending graduation reserves, and the only permissionless mover of swept reserves (`createGraduatedPool`) pays the caller nothing.

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why | Latent / privileged risk |
|---|---|---|---|
| Factory 4.2 `0x37eE…8a37` | **$0.00** | 0 BNB; all 18 checked ERC-20 pair tokens 0; 0 launches in `Swept` phase; `forceSweptGraduation` is `onlyOwner`; `rescueSweptGraduation` is `onlyOwner` + 7-day delay | Owner can rescue a stuck swept launch to any recipient after 7 days (**P**, up to ~15 BNB ≈ $10.95k per native launch); owner can replace the graduation executor/deployer (**P**) |
| Factory 4.1 `0x78EA…fe31` | **$0.00** | Same; 0 BNB; 0 token balances; 0 pending sweeps | Same owner powers |
| Any graduated / swept token | **$0.00** | 160 historical sweeps, all 160 now `PoolCreated` with `sweptQuote=0` / `sweptTokens=0`; every one was seeded permissionlessly | None for an unprivileged caller |
| Any bonding curve | **$0.00** | 20,742/20,742 curves scanned: **0** `readyToGraduate()==true`; no curve is sitting at the threshold with unswept reserves | `graduate(token)` is permissionless but pays nothing; `forceSweptGraduation` is owner-only |

**Total live extractable by an external unprivileged attacker: $0.00** (no protocol funds reachable; the largest protocol-custodied value in the stack is fee-escrow credit owned by fee recipients, H-O — see §7.3).

---

## 2. Addresses, versions and code identity

The two factories are the only Genius stacks in the project manifest; the 4.1 integration guide tells indexers to start at block 122,266,383 ("nothing older exists for this stack"), and the manifest lists only 4.1 and 4.2. 4.1 is still `launchEnabled=true` on-chain, but the frontend uses 4.2.

| Role | 4.2 (active) | 4.1 (legacy) |
|---|---|---|
| Factory | `0x37eE8AeE29C5efd3C1A7edA6dF3F510779928a37` | `0x78EAE9537C0ef90DFe9B7ae964682Fe8138afe31` |
| Start block | 122,874,828 | 122,266,383 |
| Deployed code size | 23,772 B | 23,346 B |
| On-chain bytecode keccak | `0x5ce4bf76…fa4321` | `0x416f19c3…4eef6` |
| Manifest bytecode hash | `0x5ce4bf76fdf0bf3af9273ca5f7e8be0dda483ddff7c230040edded61e9fa4321` ✓ | `0x416f19c32fbf75ea1a0cd2f51d05f0722f1f4cb0dbaf8f00cb22832345d4eef6` ✓ |
| Owner | `0xE7C7B7EE71db0f1B4F0Ff25D7cEc191268e7FD98` | same |
| Pending owner | `0x0` | `0x0` |
| Graduation guard (immutable) | `0xc41Be12E827D38223e1dc95093a9159a3E0b1A92` | `0xeE466C74Ecb94133365C4020efe0898AC31Aa73E` |
| Guard bytecode keccak | `0x55ab5e7b…00fff` | `0x55ab5e7b…00fff` (identical) |
| Graduation executor | `0x0048079cde5a0670502600dC7270952687f5F037` | `0xc0690f5EA0c0E0218650Af10f7D37780468E09f3` |
| Launch deployer | `0xdbcfbEB2849c0A7dFAc8B302FF9cF1471F7859A3` | `0xaB3eAD42ec2587D16BAE8f2c9Fb133c533C7fAAf` |
| Fee escrow | `0xc2F95799285109d076275A1ee298849A6fbd611a` | `0xFf8A2ae655E5851CB414Ac5aB41B311dA4287281` |
| Locker | `0x9109522FF8125394EDB44B8Eeb87AD946D893194` | `0x60c68B2C6Ce7D2268F25a816f326843017d00384` |
| Hook | `0x8E6f8eBbD62B60085B703C40B460daE802eDC51b` | `0xFf17F41c5Efd6CCe944Af0912F300097D62df5c9` |
| Buyback vault | `0xd275E7eEBEF0a6946130A535a106b2ca8CB922Ca` | `0x6EcBe74E6CF896c610C34A3BE59Bd54c5A5B784E` |
| Alpha registry | `0x9d60A14653b266F9D09E2137a5236F0C112eD42b` | — |

**Source identity.** Verified source was pulled from BscScan through Etherscan V2 (`chainid=56`), contract `GeniusLaunchFactory`, compiler `v0.8.26+commit.8a97fa7a`, optimizer 200 runs, viaIR, `cancun`. The deployed bytecode keccak matches the hash published in `genius.fun/contracts/manifest.json` for both stacks. The 4.2 and 4.1 factory sources are identical for every graduation/rescue function; the only diff is the 4.2 launch overloads (`toFoundation` variants). Full source saved in `analysis/source/`.

**Owner.** `0xE7C7…FD98` is a Gnosis Safe proxy (171-byte code), threshold **2 of 3**, owners are three EOAs (code size 0), `getModulesPaginated` returns `[]`, Safe nonce 36, Safe balance 50.854 BNB (owner's own funds, not protocol custody). There is no pending ownership transfer. The Safe holds the only key that can call `forceSweptGraduation` / `rescueSweptGraduation`.

---

## 3. The code — exact functions and selectors

Selectors (verified against the deployed ABI):

| Function | Selector |
|---|---|
| `forceSweptGraduation(address)` | `0x7aed273e` |
| `graduate(address)` | `0xff6d8d05` |
| `createGraduatedPool(address)` | `0x2f53ef2f` |
| `rescueSweptGraduation(address,address)` | `0xdbcb9c76` |
| `sweepCurveForRescue(address)` | `0x35e6ffaf` |
| `getLaunchedToken(address)` | `0x3cf28b5a` |

### 3.1 `forceSweptGraduation` — owner-only contingency sweep

`analysis/source/GeniusLaunchFactory_4.2.sol` lines 1140–1167:

```solidity
/**
 * @notice Sweeps a curve whose seed the preflight refuses, moving its
 * reserves into this factory so the delayed rescue path can return them.
 * ...
 * Restricted to launches the preflight genuinely refuses: while a seed is
 * still viable anyone can call `graduate` and this reverts ...
 */
function forceSweptGraduation(address token) external onlyOwner nonReentrant {
    LaunchedToken storage launch = _launchedTokens[token];
    if (!launch.exists) revert TokenNotFound();
    if (launch.phase != GraduationPhase.NotGraduated) revert WrongGraduationPhase();
    GeniusBondingCurve curve = GeniusBondingCurve(launch.curve);
    if (!curve.readyToGraduate()) {
        revert GeniusBondingCurve.NotReadyToGraduate();
    }
    if (_graduationSeedable(token, launch, curve.realQuoteReserve(), curve.tokenReserve())) {
        revert GraduationStillViable();
    }

    _sweepCurve(token, launch, curve);
    emit LaunchForceSwept(token);
}
```

There is **no recipient parameter and no transfer to `msg.sender`**. `_sweepCurve` (lines 1203–1220) calls `curve.graduate(address(this))`, measures the factory's balance delta, and records:

```solidity
uint256 quoteBefore = _quoteBalance(launch.pairToken);
(, uint256 tokenOut) = curve.graduate(address(this));
uint256 quoteOut = _quoteBalance(launch.pairToken) - quoteBefore;
if (quoteOut == 0) revert NothingToGraduate();

launch.sweptQuote = quoteOut;
launch.sweptTokens = tokenOut;
launch.sweptAt = block.timestamp;
launch.phase = GraduationPhase.Swept;

emit LaunchSwept(token, quoteOut, tokenOut);
```

### 3.2 `graduate` — permissionless only when the seed is viable

Lines 1128–1138:

```solidity
function graduate(address token) external nonReentrant {
    ...
    if (launch.phase != GraduationPhase.NotGraduated) revert WrongGraduationPhase();
    ...
    if (!curve.readyToGraduate()) revert GeniusBondingCurve.NotReadyToGraduate();
    _assertGraduationSeedable(token, launch, curve.realQuoteReserve(), curve.tokenReserve());
    _sweepCurve(token, launch, curve);
}
```

`graduate` is permissionless, but it **reverts if the guard rejects the seed**; it also pays the caller nothing. It is the healthy twin of `forceSweptGraduation`: the two use the same guard inputs, so they are mutually exclusive.

### 3.3 `createGraduatedPool` — permissionless seed, no caller payout

Lines 1266–1284:

```solidity
function createGraduatedPool(address token) external nonReentrant returns (uint256 positionId) {
    ...
    if (launch.phase != GraduationPhase.Swept) revert WrongGraduationPhase();

    uint256 sweptQuote = launch.sweptQuote;
    _assertGraduationSeedable(token, launch, sweptQuote, launch.sweptTokens);
    uint256 tokenAmount = _lockExcessGraduationTokens(token, launch, sweptQuote, launch.sweptTokens);

    launch.sweptQuote = 0;
    launch.sweptTokens = 0;
    launch.sweptAt = 0;
    launch.phase = GraduationPhase.PoolCreated;

    positionId = _createPoolAndMintPosition(token, launch, tokenAmount, sweptQuote);
    emit PoolGraduated(token, positionId, tokenAmount, sweptQuote);
}
```

`_createPoolAndMintPosition` initializes the V4 pool, registers the hook, mints the full-range position **to `address(locker)`**, and transfers no value to the caller. This is the only permissionless function that can move swept reserves, and it moves them into a permanently locked LP position.

### 3.4 `rescueSweptGraduation` — owner-only, 7-day delay, arbitrary recipient

Lines 1380–1438 (abridged; full text in source):

```solidity
function rescueSweptGraduation(address token, address recipient) external onlyOwner nonReentrant {
    ...
    if (launch.phase == GraduationPhase.NotGraduated) {
        try this.sweepCurveForRescue(token) { return; } catch {}
        ...
        launch.phase = GraduationPhase.Rescued;
        (quoteAmount, tokenAmount) = curve.rescueGraduation(recipient);
    } else {
        if (launch.phase != GraduationPhase.Swept) revert WrongGraduationPhase();

        uint256 availableAt = launch.sweptAt + GRADUATION_RESCUE_DELAY;
        if (block.timestamp < availableAt) revert GraduationRescueTooEarly(availableAt);

        quoteAmount = launch.sweptQuote;
        tokenAmount = launch.sweptTokens;
        ...
        if (quoteAmount != 0) {
            if (pairToken == address(0)) {
                (bool sent,) = payable(recipient).call{value: quoteAmount}("");
                ...
            } else { _transferWithExactDebit(pairToken, recipient, quoteAmount); }
        }
        if (tokenAmount != 0) { _transferWithExactDebit(token, recipient, tokenAmount); }
    }
    emit LaunchGraduationRescued(token, recipient, quoteAmount, tokenAmount);
}
```

`GRADUATION_RESCUE_DELAY` is `public constant uint256 = 7 days` (line 107; on-chain 604,800 s on both factories). `sweepCurveForRescue` is `external` but lines 1192–1196 require `msg.sender == address(this)`; the only caller is `rescueSweptGraduation` (owner-only).

### 3.5 The guard — immutable, stateless, deterministic

`GeniusGraduationGuard` is deployed by the factory constructor (`graduationGuard = new GeniusGraduationGuard()`) and declared `immutable` (line 319). It has no owner, no storage, and no setter. Its `assertSeedable` (lines 78–95) is `external pure` and checks only:

- `token != 0`, both amounts `<= int128.max`;
- `sqrtPriceX96` in `(MIN_SQRT_RATIO, MAX_SQRT_RATIO)`;
- full-range liquidity `!= 0` and `<= tickSpacingToMaxLiquidityPerTick(tickSpacing)`.

`_graduationSeedable` (factory lines 1229–1244) calls it in a `try/catch`; a revert (including the zero-liquidity / out-of-range cases) means "not seedable" and permits the owner's force sweep. The same guard call is used by `graduate` as `_assertGraduationSeedable`, so **force and graduate can never both succeed on the same state**. Both stacks run the same guard bytecode (`0x55ab5e7b…`).

### 3.6 Curve-side rescue

`GeniusBondingCurve.rescueGraduation(address recipient)` (lines 711–717) is `onlyFactory`, checks `anchor = readyAt != 0` and `block.timestamp >= readyAt + factory.GRADUATION_RESCUE_DELAY()`, then calls `_graduate(recipient, true)`. It is reached only from the owner-only factory rescue path (NotGraduated branch). The curve's `graduate(address)` is `onlyFactory`; `rescueFees` is `onlyFactory`; `rescueFeesTo` requires `msg.sender == Ownable(factory).owner()`. No unprivileged entry.

---

## 4. Exact race mechanics and the re-arm condition

### 4.1 State machine

```
NotGraduated --graduate() [permissionless, seedable]--> Swept
NotGraduated --forceSweptGraduation() [onlyOwner, !seedable, ready]--> Swept
Swept --createGraduatedPool() [permissionless, retryable]--> PoolCreated (terminal)
Swept --rescueSweptGraduation() [onlyOwner, >= sweptAt+7d]--> Rescued (terminal)
NotGraduated --rescueSweptGraduation() [onlyOwner, >= readyAt+7d, sweep must fail]--> Rescued (terminal)
```

### 4.2 Who can call what

| Call | Caller | Preconditions | What it pays / moves |
|---|---|---|---|
| `forceSweptGraduation(token)` | **factory owner only** (Safe 2-of-3) | `phase == NotGraduated`, `curve.readyToGraduate()`, `!_graduationSeedable(...)` | Calls `curve.graduate(address(this))`; quote + launch tokens move **to the factory**; no caller payment, no recipient arg |
| `graduate(token)` | anyone | `phase == NotGraduated`, ready, seedable | Same sweep to factory; no caller payment |
| `createGraduatedPool(token)` | anyone | `phase == Swept`, seedable | Seeds V4, mints LP NFT to locker, zeroes `sweptQuote/sweptTokens`, phase `PoolCreated`; no caller payment |
| `rescueSweptGraduation(token, recipient)` | **factory owner only** | `phase == Swept` and `now >= sweptAt + 604800` (or the NotGraduated branch with curve `readyAt` delay and a failed self-sweep) | Sends the whole recorded `sweptQuote` (native or ERC-20) and `sweptTokens` to **owner-chosen `recipient`** |
| `sweepCurveForRescue(token)` | `address(this)` only | self-call from the owner rescue | Same sweep |
| `graduate` on curve / `rescueGraduation` on curve | factory only | factory gating above | curve reserves to factory/recipient |

### 4.3 What the "race" actually is

The race is **owner rescue vs. permissionless seeding**, not attacker vs. protocol:

1. A launch becomes ready; the crossing buy calls `graduate` atomically, sweeping ~15 BNB (or the ERC-20 equivalent) into the factory and setting `sweptAt`.
2. For the next **7 days** the owner cannot rescue (`GraduationRescueTooEarly`). During that window **anyone** can call `createGraduatedPool`, which zeroes the swept fields and seeds the pool; this is irreversible and permanently closes the rescue route.
3. The owner can only rescue if the launch is genuinely unseedable (fee-on-transfer/rebasing pair asset, frozen asset, etc.) and nobody could seed it for 7 days. The guard is immutable and deterministic; `forceSweptGraduation` reverts `GraduationStillViable` whenever the seed is healthy.

So the delay is a **user protection**, not an attacker window. The only way to reach the rescue path is for the seed to be impossible, in which case there is no permissionless value-extraction path anyway (the reserves can only go to the owner's chosen recipient, after 7 days).

### 4.4 Re-arm condition (exact)

- `forceSweptGraduation` is armed only while **all** of these hold: `launch.exists`, `phase == NotGraduated` (enum 0), `curve.readyToGraduate() == true` (sellableTokens == 0), and `_graduationSeedable(...) == false`.
- It is **disarmed** by a successful `graduate` (phase→Swept), by the curve not being ready, or by the seed becoming viable. There is no time component and no re-arm after a successful sweep: `phase` only moves forward.
- A **failed** `forceSweptGraduation` is atomic: the whole tx reverts, `phase` stays `NotGraduated`, `sweptAt`/`sweptQuote` remain unchanged, and the owner can retry. This is the only "re-arm" (a revert, not a state change).
- After a successful sweep, the rescue clock is `sweptAt + 604800`. `_sweepCurve` sets `sweptAt` once, on the `NotGraduated → Swept` transition; after that, `phase` never returns to `NotGraduated`, so the clock cannot be reset by a second sweep. The NotGraduated rescue branch deliberately does a self-call sweep first (`try this.sweepCurveForRescue(token) { return; }`); if the launch is still `NotGraduated` and the quote asset can deliver, that self-call performs the first sweep, the rescue **returns without paying**, and the 7-day clock starts at the new `sweptAt` — the owner must wait 7 days from there. If the self-call reverts (asset refuses the factory), the curve-side payout runs with the curve's own `readyAt + delay` check. This is the only "re-arm" of the delay, and it is owner-initiated; an unprivileged caller cannot invoke it.
- `createGraduatedPool` zeroes `sweptQuote`, `sweptTokens` and `sweptAt` and sets `PoolCreated`; no later function can re-sweep or rescue. `Rescued` is likewise terminal.

---

## 5. Live state at block 128,633,968

All reads are `eth_call` / `eth_getBalance` / `eth_getCode` at the pinned block (token balances at 128,636,514), except the all-curve readiness scan, which used `latest` (head 128,638,486) and is cross-checked against zero graduation events in the gap. Raw values are in `analysis/live_state.json`; call proofs are in `analysis/call_proofs.json`.

| Read | Factory 4.2 | Factory 4.1 |
|---|---|---|
| Native BNB balance | **0 wei** | **0 wei** |
| ERC-20 pair-token balances (18 checked: USDT, USDC, WBNB + 15 distinct pair tokens used by historical sweeps) | **all 0** | **all 0** |
| `owner()` | `0xE7C7…FD98` (Safe 2-of-3) | same |
| `pendingOwner()` | `0x0` | `0x0` |
| `launchEnabled()` | `true` | `true` |
| `launchFee()` | 0.002 BNB | 0.002 BNB |
| `GRADUATION_RESCUE_DELAY()` | 604,800 s | 604,800 s |
| `graduationGuard()` | `0xc41B…1A92` | `0xeE46…a73E` |
| `graduationExecutor()` | `0x0048…F037` | `0xc069…09f3` |
| `launchDeployer()` | `0xdbcf…59A3` | `0xaB3e…fAAf` |
| `launchConfigCount()` | 1 | 1 |
| `maxCreatorTaxBps()` | 0 | 0 |
| `snipeTaxStartBps()` / `snipeTaxSeconds()` | 9,900 / 15 | 0 / 0 |
| `TokenLaunched` events | 3,465 | 17,277 |
| `LaunchSwept` events | 28 | 132 |
| `PoolGraduated` events | 28 | 132 |
| `LaunchForceSwept` events | **0** | **0** |
| `LaunchGraduationRescued` events | **0** | **0** |

**Launch/sweep totals:** 20,742 launches (all unique tokens), 160 sweeps, 160 seeds. The last sweep on 4.2 was block 125,467,258 (2026-10-03T10:20:01Z); the last on 4.1 was block 124,931,352 (2026-09-30T15:19:19Z). No graduation has happened since 2026-10-03, while new launches continue (last launch block 128,582,654, 2026-10-19T16:01:38Z).

**All 160 swept tokens today:** `getLaunchedToken` returns `phase = 2 (PoolCreated)`, `sweptQuote = 0`, `sweptTokens = 0`, `sweptAt = 0` for every one. There is **no pending swept reserve anywhere**.

**Last six sweeps (all already seeded):**

| Block | Factory | Token | Pair token | `quoteOut` | Seed block |
|---|---|---|---|---|---|
| 124,931,352 | 4.1 | `0xf2653ccc86a209f450e3d8de60d9c5c559ddc983` | GENIUS `0x1f12…e9a6` | 30,000.000000000000000016 | 124,931,396 |
| 125,073,910 | 4.2 | `0xd18cc65e23b4c21c1a9492705679508b2ce06666` | BNB | 15.000000000000000036 | 125,073,953 |
| 125,232,067 | 4.2 | `0x6b06c6400630fefa862bf449f473cd49ba458d60` | GENIUS | 30,000.000000000000000151 | 125,232,100 |
| 125,285,935 | 4.2 | `0x81ee27dade0a9b8da3ccf91dd88dcb8371e1cfe8` | BNB | 15.000000000000000078 | 125,285,977 |
| 125,301,179 | 4.2 | `0x349c65da52c00cca6b7709d758db24cbc6187ca0` | `0x000ae3…` | 13,000.000000000000000441 | 125,301,208 |
| 125,467,258 | 4.2 | `0x2670b2798ca7665afff8068cb6dbcae8070fc838` | BNB | 15.000000000000000251 | 125,467,311 |

The last sweep is the one tested in §6. Every one of the 160 sweeps has a matching `PoolGraduated`; none is pending.

**Curve readiness:** a Multicall3 `aggregate3` scan called `readyToGraduate()` on **all 20,742** launch curves at latest (head 128,638,486): **0** returned true, 0 calls failed. A follow-up `eth_getLogs` over blocks 128,633,969–128,638,486 found **no** `LaunchSwept` / `PoolGraduated` / `LaunchForceSwept` / `LaunchGraduationRescued` events in the gap, so no curve became ready-and-graduated between the pinned block and the scan head. No curve is sitting at the graduation threshold with unswept reserves. `AutoGraduationFailed` logs across the entire history: **0** — every crossing buy auto-graduated in the same transaction.

**Owner Safe:** threshold 2, owners `0x087E…8166`, `0x28cA…d54a`, `0x9019…f8e6` (all EOAs), modules `[]`, Safe nonce 36, balance 50.854 BNB. There is no pending owner and no module that could execute calls outside the 2-of-3 signature path.

**Pause / liveness:** neither factory nor any curve has a pause function; `launchEnabled` only gates new launches (existing curves and pools keep trading). PancakeSwap can pause Infinity (third-party), which would temporarily block `createGraduatedPool` and therefore delay a seed, but it does not create an unprivileged value path — the reserves would still be owner-only after 7 days.

**Curve balances:** the 20,742 curves hold ordinary trading reserves (user funds), but `forceSweptGraduation` requires `readyToGraduate()`; with 0/20,742 ready, no curve balance is reachable through the force path. The factory's own `receive()` accepts BNB but has no sweep of unaccounted balances, so any stray BNB sent there is stuck (S), not extractable.

**Adjacent observation (not counted in E-U):** the 4.1 launch-and-buy router `0x2EF00378984e84f2DAa08DfB5Fb03bBDE2038ae6` holds exactly 1.000000000000000000 BNB; the 4.1/4.2 hooks hold ~0.072 BNB and ~0.030 BNB of dust, and the foundation vaults hold ~0.337 BNB / ~4.04 BNB. These were not investigated as extraction paths for this lead and are excluded from the $0.00 E-U figure; they are not factory graduation reserves.

**Price:** Chainlink BNB/USD `0x0567…2aeE`, answer `73,018,684,230` / 1e8 = **$730.18684230**, updatedAt 1792449473 (2026-10-19T22:37:53Z). All USD figures below use this price.

---

## 6. Historical state that the pass2 lead was worried about — and why it is still $0

At archive block **125,467,270** (2026-10-03T10:20:13Z), 12 blocks after the last 4.2 sweep and 41 blocks before the pool was seeded, the factory really did hold:

- native balance **15.000000000000000251 BNB**;
- launch `0x2670b2798ca7665afff8068cb6dbcae8070fc838`, phase **1 (Swept)**, `sweptQuote = 15000000000000000251`, `sweptTokens = 285714285714285714285714285`, `sweptAt = 1791022801` (rescue available 1791627601 = 2026-10-10T10:20:01Z).

Read-only archive `eth_call` simulations at that exact block:

| Call | From | Result |
|---|---|---|
| `createGraduatedPool(token)` | random `0x1111…1111` | **SUCCESS**, returns `positionId = 1479147` |
| `createGraduatedPool(token)` | owner Safe | SUCCESS, same position id |
| `forceSweptGraduation(token)` | random `0x1111…1111` | revert `OwnableUnauthorizedAccount(0x1111…1111)` |
| `forceSweptGraduation(token)` | owner Safe | revert `WrongGraduationPhase` (already swept) |
| `rescueSweptGraduation(token, 0x1111…)` | random `0x1111…1111` | revert `OwnableUnauthorizedAccount(0x1111…1111)` |
| `rescueSweptGraduation(token, 0x1111…)` | owner Safe | revert `GraduationRescueTooEarly(1791627601)` |
| `graduate(token)` | random `0x1111…1111` | revert `WrongGraduationPhase` |

This is the strongest possible refutation of the "race" hypothesis: at the exact moment the factory held 15 BNB, an unprivileged caller could **only help seed the pool** (for no payment), while both value-moving functions were owner-gated, and the owner's rescue was still 7 days away. The public seed path (`createGraduatedPool`) is the actual winner: 134 of 160 sweeps were seeded within 100 blocks (median 44 blocks; p90 203; max 5,050), so the factory's pot is normally transient.

**How big can the pot get?** Across all 160 swept launches, the maximum **concurrent** pending sweep count was 5 and the maximum concurrent native pending amount was **75 BNB** (block 122,415,298, 2026-09-17T12:42:07Z; ~$54,764 at today's price). Even at that peak, the only unprivileged mover was `createGraduatedPool`, which seeds the pool and pays the caller nothing. The value at stake is real, but it is never attacker-extractable.

---

## 7. Quantification

### 7.1 Current extractable E-U

**$0.00.** Both factories hold 0 BNB and 0 of all 18 checked pair tokens; all 160 swept launches are already seeded with `sweptQuote=0`; all 20,742 curves are non-ready at the scan head; there is no permissionless function on either factory or on any curve that pays the caller from protocol reserves.

### 7.2 Conditional E-U if the next sweep funds the factory

**Still $0.00.** Trigger: the next launch crosses its threshold; the crossing buy (or any caller of `graduate`) sweeps the curve's reserves into the factory. Expected size: **~15 BNB ≈ $10,952.80** for a native launch (observed sweep amounts 15.0000000000000000–15.0000000000000006 BNB), or ~10,000 USDT/USDC / the bStock-equivalent threshold for an ERC-20 launch. Historical concurrency peak: 75 BNB ≈ $54,764.01.

After the sweep, an unprivileged attacker can:
- call `createGraduatedPool(token)` → seeds the V4 pool, mints the LP NFT to the locker, zeroes the factory's recorded reserve; **no payout to caller**;
- call `graduate(token)` → reverts `WrongGraduationPhase` once swept;
- call `forceSweptGraduation` / `rescueSweptGraduation` → reverts `OwnableUnauthorizedAccount`.

There is no `sweep()`/`rescue()` with a caller-chosen recipient. The only recipient choice is the owner's `rescueSweptGraduation(token, recipient)`, after 7 days, and only if the launch is still `Swept` (i.e., no one could seed it). That is **P**, not E-U.

### 7.3 Categories

| Category | USD | Notes |
|---|---|---|
| **E-U** | **$0.00** | No unprivileged path to factory/curve principal |
| **H-O** | ~**$200,768.95** | Fee-escrow credits: 39.4276 BNB (4.2) + 235.5280 BNB (4.1) at $730.19; `claim()`/`claimToken()` pay `msg.sender`'s own ledger only (verified in `GeniusFeeEscrow.sol` lines 79–138). Owners of those credits can withdraw; an attacker cannot claim another recipient's balance. |
| **P** | up to ~15 BNB per stuck launch (~$10,952.80) | Owner-only `rescueSweptGraduation(token, recipient)` after 7 days; owner can also replace the graduation executor/deployer and propose creator-fee-recipient changes (3-day timelock) |
| **S** | 0 today | Any BNB sent to the factory's bare `receive()` is stuck (no sweep of unaccounted balances); no such balance exists now |

### 7.4 Confidence

**High.** The decisive facts are (i) `forceSweptGraduation` and `rescueSweptGraduation` carry `onlyOwner`, proven by live `eth_call` reverts from a random EOA and by the verified source; (ii) both factories and all 160 swept tokens are empty of pending reserves at the pinned block; (iii) all 20,742 curves are non-ready at the scan head (and no graduation events occurred between the pinned block and that head); (iv) the only permissionless mover of swept reserves is `createGraduatedPool`, whose code transfers no value to the caller. A fork PoC is not needed to establish $0; the archive-block simulation reproduces the exact historical pot and gate.

**What would change the verdict:** a new factory deployment with a changed `forceSweptGraduation`/`rescueSweptGraduation` signature or modifier; a permissionless function added to the factory/curve that transfers balances to `msg.sender`; or compromise of the 2-of-3 Safe (that would be key compromise, not external-unprivileged E-U). None is present today.

---

## 8. Fork PoC — feasibility / necessity

**Not needed for this verdict.** The archive `eth_call` at block 125,467,270 is stronger than a fork for the specific claim: it reads the exact historical state (15 BNB in the factory, phase `Swept`) and executes the four relevant calls with the real deployed code. A Foundry fork would be feasible (`anvil --fork-url <BSC RPC> --fork-block-number 125467270`; `vm.createSelectFork(url, 125467270)`), and the test would be:

1. assert `factory.balance == 15.000000000000000251e18`;
2. `vm.prank(random); factory.forceSweptGraduation(token)` → expect `OwnableUnauthorizedAccount`;
3. `vm.prank(owner); factory.rescueSweptGraduation(token, random)` → expect `GraduationRescueTooEarly`;
4. `vm.prank(random); factory.createGraduatedPool(token)` → succeeds, position minted to locker, factory balance goes to 0, caller balance unchanged.

Constructing a *NotGraduated + ready + unseedable* launch to exercise step 1 of the force path would require the owner to approve a fee-on-transfer/rebasing pair token and a user to buy it to threshold; that cannot be built from live state without owner privileges, which is itself the point. The source-level condition is unambiguous and the guard is pure.

---

## 9. Negative results / blockers (so this is not re-investigated)

- **No successful `forceSweptGraduation` ever:** 0 `LaunchForceSwept` events across both factories, all blocks.
- **No successful rescue ever:** 0 `LaunchGraduationRescued` events.
- **No auto-graduation failures:** 0 `AutoGraduationFailed` events; for the last launch, block 125,467,257 is `NotGraduated` with `readyToGraduate=false` and block 125,467,258 is `Swept`, i.e. the crossing buy, sweep and phase change are atomic in one tx. Across all history there is no event showing a readiness transition left unswept.
- **No pending curve:** all 20,742 curves non-ready at the scan head (128,638,486); no graduation events in the 128,633,969–128,638,486 gap.
- **No pending factory reserve:** all 160 swept tokens `PoolCreated`, `sweptQuote=0`, `sweptTokens=0`.
- **No factory token balance:** 18 pair tokens + native checked on both factories, all zero.
- **No pool-initialization griefing:** `GeniusMemeHook.beforeInitialize` requires `sender == factory` (line 406–414), so an attacker cannot initialize the V4 pool key first to force a launch into the rescue path.
- **No self-call reachability:** `sweepCurveForRescue` requires `msg.sender == address(this)`; the only caller is the owner-only rescue.
- **No ownership shortcut:** `renounceOwnership()` is overridden to revert; `pendingOwner()==0`; Safe has no modules and is 2-of-3.

---

## 10. Methodology & sources

- **Verified source:** BscScan via Etherscan V2 `module=contract&action=getsourcecode&chainid=56` for both factories and the guard; compiler 0.8.26, optimizer 200, viaIR, cancun. On-chain bytecode keccak matches `genius.fun/contracts/manifest.json`. Full source in `analysis/source/`.
- **Logs:** `eth_getLogs` over the full range from each factory's start block to 128,633,968 for `TokenLaunched`, `LaunchSwept`, `LaunchForceSwept`, `PoolGraduated`, `LaunchGraduationRescued`, `AutoGraduationFailed`. Counts: 20,742 launches, 160 sweeps, 160 seeds, 0 force, 0 rescue, 0 auto-graduation failures.
- **Curve readiness:** Multicall3 `aggregate3` on `0xcA11bde05977b3631167028862bE2a173976CA11`, calling `readyToGraduate()` on all 20,742 curves at latest.
- **State reads:** `eth_call` at block 128,633,968 (and 128,636,514 for token balances) against both factories, owner Safe, guard, executor, curve of the last swept launch.
- **Archive proof:** `eth_call` at block 125,467,270 via an archive-capable BSC RPC; exact results in `analysis/call_proofs.json`.
- **Price:** Chainlink BNB/USD `0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE`, answer 73,018,684,230 / 1e8 = $730.18684230, updated 2026-10-19T22:37:53Z.
- **Docs cross-check:** `genius.fun/docs/contracts`, `genius.fun/contracts/manifest.json`, `genius.fun/docs/integrate`, and the Hackerbane Pons Family audit (the code is a Pons v2 derivative; HACK-02 describes the same owner rescue design). The manifest lists only stacks 4.1 and 4.2, and the 4.1 integration guide tells indexers to start at block 122,266,383 ("nothing older exists for this stack"), consistent with 4.1 being the first deployment.

### Files

| File | Contents |
|---|---|
| `analysis/child-findings.md` | This report |
| `analysis/live_state.json` | All pinned-block state reads, counts, price, USD conversions |
| `analysis/call_proofs.json` | Exact `eth_call` proofs (latest + archive block 125,467,270) |
| `analysis/graduation_events.json` | 320 decoded launch/graduation events |
| `analysis/graduation_logs_raw.json` | Raw `eth_getLogs` output for the 4 graduation topics |
| `analysis/swept_token_states.json` | `getLaunchedToken` for all 160 swept tokens (all phase 2, zero swept fields) |
| `analysis/ready_scan_curves.json` | `readyToGraduate()` result for all 20,742 curves (0 ready) |
| `analysis/source/GeniusLaunchFactory_4.2.sol` | Verified factory source (active) |
| `analysis/source/GeniusLaunchFactory_4.1.sol` | Verified factory source (legacy) |
| `analysis/source/GeniusGraduationGuard.sol` | Verified guard source |
| `analysis/source/GeniusLaunchFactory_abi_4.2.json` | Deployed ABI |

**Caveats:** (i) The 20,742-launch count is the number of `TokenLaunched` events; each event is a unique token address (duplicate check: 0). (ii) USD values use the stated Chainlink price; the historical pot was 75 BNB, but its USD value at the time differs. (iii) The verified-source-to-bytecode match is established by the manifest hash + on-chain keccak, not by a fresh viaIR recompile. (iv) The owner Safe key-holder identities are unknown; the audit treats 2-of-3 key compromise as a privileged/key-custody risk, not E-U.

---

**Bottom line:** The `forceSweptGraduation` "race" is not an external attack surface. Both value-moving functions are owner-gated, the guard is immutable and deterministic, the 7-day delay protects users by letting anyone seed a viable launch first, and the factories/curves hold no extractable reserve today. **E-U = $0.00 (HIGH confidence); latent P risk = owner rescue of a genuinely unseedable launch after 7 days (~15 BNB / ~$10.95k per native launch).**
