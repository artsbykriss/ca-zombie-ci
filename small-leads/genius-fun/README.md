# Genius.fun — “graduation race” is owner-only (E-U $0)

**Status:** read-only assessment, BSC block 128,636,158 (2026-10-19). No transactions signed/sent.

## TL;DR

| Item | Value |
|---|---|
| Active factory (v4.2) | `0x37eE8AeE29C5efd3C1A7edA6dF3F510779928a37` |
| Legacy factory (v4.1) | `0x78EAE9537C0ef90DFe9B7ae964682Fe8138afe31` |
| Owner (both) | `0xE7C7B7EE71db0f1B4F0Ff25D7cEc191268e7FD98` — **Gnosis Safe 2-of-3** (not an EOA) |
| `GRADUATION_RESCUE_DELAY` | **604,800 s = 7 days** |
| `forceSweptGraduation(address)` | **`onlyOwner`** — random caller reverts `OwnableUnauthorizedAccount` |
| `rescueSweptGraduation(address,address)` | **`onlyOwner`** + 7-day delay after `sweptAt` |
| Factory balances | **0 BNB**, 0 USDT, 0 USDC |
| Permissionless functions | `graduate(token)`, `createGraduatedPool(token)` — both pro-holder, pay the caller nothing |
| **E-U now** | **$0 (HIGH confidence)** |
| Conditional E-U if funded | **$0** — only the owner can move swept reserves (P) |
| Latent risk | **P**: owner can force-sweep an unseedable launch and, after 7 days, rescue the reserves to any address |

## 1. What the code actually does

Verified source: `src/GeniusLaunchFactory.sol` (Sourcify full match; compiler 0.8.26, viaIR),
fork of Pons v2. Key excerpts:

```solidity
uint256 public constant GRADUATION_RESCUE_DELAY = 7 days;          // L107

function forceSweptGraduation(address token) external onlyOwner nonReentrant {  // L1153
    ...
    if (launch.phase != GraduationPhase.NotGraduated) revert WrongGraduationPhase();
    if (!curve.readyToGraduate()) revert GeniusBondingCurve.NotReadyToGraduate();
    if (_graduationSeedable(token, launch, curve.realQuoteReserve(), curve.tokenReserve()))
        revert GraduationStillViable();
    _sweepCurve(token, launch, curve);
}

function rescueSweptGraduation(address token, address recipient) external onlyOwner nonReentrant { // L1380
    ...
    uint256 availableAt = launch.sweptAt + GRADUATION_RESCUE_DELAY;
    if (block.timestamp < availableAt) revert GraduationRescueTooEarly(availableAt);
    ... // pays the whole sweptQuote/sweptTokens to `recipient`
}

function createGraduatedPool(address token) external nonReentrant returns (uint256 positionId) { // L1266
    ... // permissionless; seeds the Infinity pool and locks the LP NFT
}
```

The “race” in the pass-2 lead is real only as a **defensive** race: while a swept launch sits in
phase `Swept`, anyone may call `createGraduatedPool`; if the seed succeeds, the phase becomes
`PoolCreated` and the owner’s 7-day rescue path is closed. That protects the launch’s holders and
pays the caller nothing (LP is minted to the permanent locker). It is **not** an attacker-profit
race.

`forceSweptGraduation` is additionally constrained: it only works when the immutable
`graduationGuard` refuses the seed (`GraduationStillViable` otherwise), so the owner cannot use it
to take a healthy launch.

## 2. Live-state proof (BSC block 128,636,158)

```
owner()                          = 0xE7C7B7EE71db0f1B4F0Ff25D7cEc191268e7FD98
GRADUATION_RESCUE_DELAY()        = 604800
graduationGuard()                = 0xc41Be12E827D38223e1dc95093a9159a3E0b1A92
graduationExecutor()             = 0x0048079cde5a0670502600dC7270952687f5F037
locker()                         = 0x9109522FF8125394EDB44B8Eeb87AD946D893194
launchDeployer()                 = 0xdbcfbEB2849c0A7dFAc8B302FF9cF1471F7859A3
launchEnabled()                  = true
balance(factory)                 = 0 BNB
balanceOf(factory, USDT/USDC)    = 0 / 0
```

`eth_call` from a random EOA:

| Call | Result |
|---|---|
| `forceSweptGraduation(0x1111…)` | revert `OwnableUnauthorizedAccount(0x2222…)` |
| `rescueSweptGraduation(0x1111…, 0x2222…)` | revert `OwnableUnauthorizedAccount(0x2222…)` |
| `createGraduatedPool(0x1111…)` | revert `TokenNotFound` (no auth gate — reaches the token check) |
| `graduate(0x1111…)` | revert `TokenNotFound` (permissionless) |
| `forceSweptGraduation` sent by the owner | revert `TokenNotFound` (passes auth — confirms the gate) |

No `TokenLaunched` logs in the last 5,000 blocks; the active factory is effectively idle. Even if a
launch is swept, the reserves sit in the factory and only the owner can move them.

## 3. Both stacks are real factories; both are empty

The pass-2 `0x78EA…fe31` truncation is the **4.1 factory**
`0x78EAE9537C0ef90DFe9B7ae964682Fe8138afe31` (23,346 bytes; bytecode hash matches the manifest).
The active 4.2 factory is `0x37eE…8a37` (23,772 bytes; hash matches). Both have the same owner
(Safe 2-of-3), the same 7-day rescue constant and the same owner-only graduation/rescue functions;
4.1 is still `launchEnabled=true`.

Live enumeration (child, block 128,633,968 / token balances 128,636,514):

| | 4.2 | 4.1 |
|---|---:|---:|
| `TokenLaunched` events | 3,465 | 17,277 |
| `LaunchSwept` / `PoolGraduated` | 28 / 28 | 132 / 132 |
| `LaunchForceSwept` / `LaunchGraduationRescued` | 0 / 0 | 0 / 0 |
| BNB / 18 pair-token balances | **0 / 0** | **0 / 0** |

All **160** historical sweeps are now `PoolCreated` with `sweptQuote = 0`, `sweptTokens = 0`,
`sweptAt = 0`; a Multicall3 scan of all **20,742** launch curves returned
`readyToGraduate() == false` for every one. There is no pending swept reserve anywhere today.
Historical peak: 75 BNB concurrently pending (block 122,415,298, 2026-09-17) — still only
`createGraduatedPool` (no caller payout) could move it. The last 4.2 sweep was 2026-10-03; no
graduation in ~16 days.

(Do not confuse `0x78eA5FEaa4B90a31DA35163471219ce91094E099` — a 698-byte non-factory contract
ending in `…E099` — with the 4.1 factory `0x78EAE953…8afe31`.)

## 4. Verdict and categories

* **E-U now: $0.00** (high). `forceSweptGraduation` and `rescueSweptGraduation` are both
  `onlyOwner`; no permissionless call pays the caller. Both factories hold 0 BNB and 0 of 18
  pair tokens; all 160 swept launches are seeded; all 20,742 curves are non-ready.
* **E-U conditional on the next graduation sweep: $0.00** — a funded factory does not create an
  attacker path; the next native sweep is ~15 BNB (~$10,953 at $730/BNB) sitting in the factory
  for <1 day, but the only permissionless action (`createGraduatedPool`) seeds the V4 pool, mints
  the LP NFT to the permanent locker and pays the caller nothing. Historical peak 75 BNB
  (~$54,764) was likewise not attacker-extractable.
* **P:** owner-only `rescueSweptGraduation(token, recipient)` after 7 days, up to ~15 BNB per stuck
  launch (~$10,953); owner can also rotate the executor/deployer and propose creator-fee changes.
* **H-O:** Genius FeeEscrow credits **~$200,768.95** (39.4276 BNB on 4.2 + 235.5280 BNB on 4.1 at
  $730.19); `claim()`/`claimToken()` pay the caller's own ledger only — an attacker cannot claim
  another recipient's balance.
* **S:** 0 today; any BNB sent to a factory's bare `receive()` would be stuck (no unaccounted-balance
  sweep), but no such balance exists.

**Re-arm condition to watch:** a launch in phase `Swept` with non-zero `sweptQuote`/`sweptTokens`
that the immutable guard refuses to seed. That is a P-risk (owner rescue), not E-U. The public can
close it by calling `createGraduatedPool(token)` as soon as the guard allows.

## 5. Evidence

* `analysis/child-findings.md` — independent live enumeration (launch/sweep/balance reads).
* Source: `src/GeniusLaunchFactory.sol` from Sourcify full match for `0x37eE…8a37`;
  `GRADUATION_RESCUE_DELAY` L107, `forceSweptGraduation` L1153, `rescueSweptGraduation` L1380,
  `createGraduatedPool` L1266.
* `https://genius.fun/docs/integrate` (phase model), `https://genius.fun/docs/contracts`
  (v4.2 stack), `https://genius.fun/contracts/manifest.json` (owner/roles/addresses).
* Hackerbane Pons v2 audit HACK-02 (same `onlyOwner` + 7-day rescue pattern).
* On-chain reads at block 128,636,158 via `https://bsc-rpc.publicnode.com` (keyless).
