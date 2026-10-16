# Z3-H17 · NaraUSD (Ethereum mainnet) — multi-collateral mint/redeem at par + Blackopal BoringVault strategy

**Date:** 2026-10-16 · **Chain:** Ethereum (1) · **Status:** read-only; PoC fork-verified only; no mainnet transactions
**Scope:** MCT `0x4eD90999f558Fdc28606b7F7f9AFc7044befb803` (impl `0xD8E8C72AFEC564ee5BC88A6A713C54449Fc56469`) ·
NaraUSD `0x5C6263904CCFD3Bcf1aAa6e7063dDd29743b3Bb7` (impl `0x87cF5006E1Cbf0D35C622C5f1BE891B2f71878ea`) ·
NaraUSD+ `0x1aa23CDFC941f6b54251C72012A9Bfa4bF5394D6` (impl `0x9e1d521894C45FA26E0f06809674037c78E3c1b3`) ·
redeem silo `0x69e0e02b31B5623c6db029b531d4D55837098326` · plus silo `0x12E4915C52E2d02e1c5477582577727E6fA35d13` ·
Blackopal LiquidStone II BoringVault `0x15e2579B1F0cBe973889a76826D3a2313b6509c6` + accountant `0xda594876BA13BCC22065E03fFcFB24A22E5c6724` ·
protocol Safe `0xaB05c0DB9D26e96A9dcEDCAFCA23341316F6fe6F` · Keyring `0xb0B5E2176E10B12d70e60E3a68738298A7DFe666`
**Method:** full verified-source review (Sourcify exact matches; Etherscan V2 key expired 2026-10-16), live-state reads at
blocks 26,202,400–26,202,548 (public RPC), full event-history reconstruction (Tenderly/mevblocker public gateways), and an
adversarial Foundry fork suite (`poc/test/NaraUSD.t.sol`, **9/9 PASS**).

---

## 1. TL;DR

| target | live extractable (unprivileged) | why closed / open | latent risk |
|---|---|---|---|
| `NaraUSD.mintWithCollateral` USDC/USDT | **$0** | Keyring-gated: `hasValidCredentials(fresh) == false`; fork-proven revert `KeyringCredentialInvalid` (T3). Parity is exact 1:1 decimals-normalised, **no oracle, no fees** (mintFeeBps=redeemFeeBps=0, min fees 0) | if Keyring is ever disabled/opened: see conditional below |
| `NaraUSD.redeem(collateral, amt, allowQueue)` | **$0** | Keyring-gated (T3, even for holders of NaraUSD). Instant path capped by MCT `collateralBalance[asset]` = **$1,959.00 USDC + $999.50 USDT**; beyond that it queues | queued redemptions are solver-discretionary (COLLATERAL_MANAGER = Safe) |
| MCT `mint` / `redeem` / `mintWithoutCollateral` / `withdrawCollateral` | **$0** | `onlyRole(MINTER_ROLE \| COLLATERAL_MANAGER_ROLE)`; MINTER = NaraUSD only, COLLATERAL_MANAGER = Safe; fork-proven reverts (T2). Deployer renounced everything (blocks 24,983,961–24,984,037) | Safe holds every role (P) |
| Accountant `updateExchangeRate` / `setRateProviderData` | **$0** | `requiresAuth` (owner Safe or Blackopal RolesAuthority `0xD1283b722c…`); fork-proven revert (T7). Rate is **not used anywhere in the NaraUSD mint/redeem path** | Blackopal vault's own authority is the rate-push actor |
| BoringVault `enter`/`exit`/`manage` (share round-trip hypothesis) | **$0** | BV share is **not** an MCT collateral (`isSupportedAsset(BV) == false`, fork-proven T1); `enter/exit/manage` all `requiresAuth`, fork-proven reverts (T7) | BV is the protocol's *investment*; its rate only affects the Safe's assets |
| NaraUSD+ staking vault | **$0** | Deposit is public (no Keyring), withdrawal locked 7 days (`cooldownDuration=604800`); fork round-trip pays only the protocol's vesting-reward stream: measured **+2.2437 NaraUSD per 1,000 staked per 7d (0.224%)** = yield for staked capital, bounded <1%/7d (T5) | REWARDER EOA can `transferInRewards`/`burnAssets` (deflation + auto-pause) |
| Silos (`withdraw`) | **$0** | `onlyVault` / `onlyStakingVault`; fork-proven reverts (T6). Redeem-silo escrow balance is 0 today | — |
| **Hypothetical Keyring bypass** | **≤ ~$270** | *Conditional*: mint at par (1 USDC → 1 NaraUSD, 0 fees) and sell into the imbalanced Curve pool `0xf05F1b7b…` (NaraUSD 15,031 / USDC 19,332.79, A=100): single-shot arb optimum ≈ `y − 2√(xy) + x` ≈ **$270**; par-par round-trips are exactly 0 (fork-proven, T8/T9) | only meaningful if the Keyring stops gating |

**Total live extractable now: $0.00 — confidence high** (every path reduced to a call sequence, live-read, and
fork-falsified). Conditional ceiling **≤ ~$270** (Keyring-off + pool-imbalance arb). ETH-side value controlled by the
protocol Safe: **$9,139,735** (live backing incl. mGLO — DefiLlama under-reports by ~$2.32M, see §3), of which only
**$2,958.50** is instantly redeemable at par.

## 2. The mechanism, in exact terms

Architecture (all verified source; Sourcify exact/partial matches):

- **MCT** (`MultiCollateralToken`, UUPS, solc 0.8.22) is a 1:1 multi-collateral ledger: `mint(asset, amount, beneficiary)`
  mints `amount × 10^(18−decimals)` MCT against a whitelisted asset; `redeem(asset, mctAmount, beneficiary)` burns and pays
  `mctAmount / 10^(18−decimals)` back; `collateralBalance[asset]` is the per-asset book (checked on redeem and decremented).
  Every entry point is role-gated: `mint`/`mintWithoutCollateral`/`redeem` = `MINTER_ROLE` (held only by the NaraUSD proxy),
  `withdrawCollateral`/`depositCollateral` = `COLLATERAL_MANAGER_ROLE` (Safe), asset registry = `DEFAULT_ADMIN_ROLE` (Safe).
  Upgrades: UUPS `_authorizeUpgrade` = `DEFAULT_ADMIN_ROLE`.
- **NaraUSD** (ERC4626-shaped token over MCT, UUPS) is the user front-end: `mintWithCollateral(asset, amount)` is public but
  calls `_checkKeyringCredential(msg.sender)` — a live external `Keyring.checkCredential(15_713_807, account)` call (Keyring
  Core proxy `0xb0B5E217…`). Conversion is a pure decimals normalisation (**no price feed anywhere**): 1.000000 USDC (=1e6)
  → 1e18 MCT → 1 NaraUSD. `redeem(asset, amount, allowQueue)`: identical Keyring gate; executes instantly only while
  `mct.collateralBalance[asset] ≥ amount` (per-block caps 5,000,000e18), else escrows NaraUSD in the redeem silo for a
  discretionary solver (COLLATERAL_MANAGER = Safe; users may `cancelRedeem`/`tryCompleteRedeem`).
  Fees today: `mintFeeBps = redeemFeeBps = 0`, `minMintFeeAmount = minRedeemFeeAmount = 0`; `feeTreasury = 0xc5841Ce3…`.
  ERC4626 `deposit/mint/withdraw/redeem` are deliberately reverted (`UseMintWithCollateral`/`UseRedeemWithTargetCollateral`).
- **NaraUSD+** is the staking vault (asset = NaraUSD, 7-day cooldown, `MIN_SHARES = 1e18` inflation guard, silo escrow).
  Deposit/redeem mechanics are stock ERC4626 with a vesting-reward stream.
- **Blackopal LiquidStone II** is a *strategy*, not collateral: a BoringVault (solc 0.8.22, `enter/exit/manage` behind
  solmate `Auth` with owner = Safe and Authority = RolesAuthority `0xD1283b722cB86a978a4F3ACDc134cAF06Ec10Da0`) whose
  shares sit in the protocol Safe. The accountant's `getRate()` (1.1534e18 today) prices those shares for DefiLlama only —
  it cannot move a single NaraUSD.

## 3. Live-state assessment (blocks 26,202,400–26,202,548 · 2026-10-16)

- **MCT**: `getSupportedAssets() = [USDC, USDT]` (only these two; `AssetAdded` × 2, `AssetRemoved` × 0). totalSupply
  `9,839,512.462174e18`; `collateralBalance[USDC] = 1,959,000,000` (=$1,959.00) and `[USDT] = 999,500,000` (=$999.50) —
  **exactly equal to the MCT's actual token balances** (bookkeeping parity, fork-asserted). MINTER = NaraUSD proxy only;
  COLLATERAL_MANAGER = Safe; ADMIN = Safe; deployer `0xfd8b2fc9…` renounced all roles at deployment tail.
- **NaraUSD**: not paused; `mct = MCT`; `redeemSilo = 0x69e0e02b…` (owner Safe; escrow balance 0); supply = MCT supply.
  `keyringAddress = 0xb0B5E2176E10B12d70e60E3a68738298A7DFe666`, `keyringPolicyId = 15,713,807`;
  `hasValidCredentials(fresh) = false` (so do all sampled addresses, incl. well-known EOAs). Roles: ADMIN/COLLATERAL_MANAGER/MINTER/
  BLACKLIST_MANAGER = Safe; GATEKEEPER = Safe + EOAs `0x02670d44…`, `0x087e45aa…`.
- **NaraUSD+**: `totalAssets = 2,696,071.65 NaraUSD` (balance 2,702,145.20 − unvested 6,073.55), supply `2,568,630.10` shares
  (share price 1.0496); `cooldownDuration = 604800`; `vestingAmount = 7,953.95 NaraUSD`, vestingPeriod 561,600 s; silo2
  `0x12E4915C…` (owner Safe, `stakingVault()` bound). REWARDER = EOA `0x2c4c371e…`; GATEKEEPERS = the two EOAs above.
- **BoringVault "Blackopal LiquidStone II"**: 6 dp, totalSupply `1,709,371.77` shares, 99.99995% held by the Safe;
  owner = Safe, authority = RolesAuthority `0xD1283b72…` (contract, 2,615 B; `canCall(Safe, accountant, updateExchangeRate)`
  = **false** → rate updates are pushed by a separate authority member). Accountant: base=USDC, vault=BV, `getRate() =
  1.1534e18` (upper/lower bounds 100.30%/99.70%, min update delay 3,600 s, not paused, managementFee 0, lendingRate 0).
- **Value at stake — backing of NaraUSD** (all reads at 26,202,41x; USD at live marks):
  - Safe: USDC **29,923.06** · USDT **4,696,207.50** · sUSDS **110,406.20** (×1.11264 = $122,842.56) ·
    BoringVault shares **1,709,370.869198** (×1.1534 = $1,971,588.36) · **mGLO 2,302,935.4559** (×$1.00576635 =
    $2,316,214.99, received 2026-09-15 in the Midas mGLOBAL→mGLO migration from `0x70b5698a…`); plus 3 spam tokens.
  - MCT: USDC 1,959.00 + USDT 999.50. **Total backing ≈ $9,139,735** — while DefiLlama shows only $6,817,905: its
    adapter still counts the **deprecated** `mGLOBAL 0x74338069…` (Safe balance now **0**) and misses `mGLO 0x1dd91a11…`,
    so DL under-reports by ~$2.32M.
- **History reconciliation (exact, from events):** collateral in = USDC 4,463,611.75 + USDT 5,257,535.80 = **$9,721,147.55**
  (45 `Minted`); out via `CollateralWithdrawn` = USDC 4,461,636.65 + USDT 5,256,515.30 = **$9,718,151.95** — **all 22
  withdrawals went to the Safe**; users redeemed only $37.10 (6 `Redeemed`). MCT ever-minted = 9,721,147.55 (collateral) +
  **118,402.01 unbacked** (19 `UnbackedMint` events, all `NaraUSD.mintWithoutCollateral` via the Safe) − 37.10 = **exactly
  current supply** `9,839,512.46`.
- **Collateralisation (corrected):** supply 9,839,512.46 NaraUSD vs live backing **$9,139,735 → 92.89% covered; gap
  ≈ $699,777**. The Safe's USDC/USDT flows reconcile to the cent (USDC in 4,462,662.27 = out 4,432,739.21 + held 29,923.06;
  USDT in 5,256,515.30 = out 560,307.80 + held 4,696,207.50). The gap is dominated by two strands: **500,009.30 USDT →
  EOA `0xb0971be3…` (holds $0 today)** and the Midas migration where **2,435,957.20 mGLOBAL out bought 2,302,935.46 mGLO
  in (−133,021.75 mGLO ≈ −$133.8K)**; plus 49,800 USDT via CoW (`0x9008d19f…`), ~$75K to small contracts
  (`0xa188eec8…`, `0x0c56a547…`), net of a +$64.6K BoringVault gain. The `2,450,000 USDC → EOA 0xb38c7119…` outflow is
  fully explained as the OTC payment for the mGLOBAL position (2,435,957.21 × 1.00577 = 2,450,000.0). **Not determinable
  from public state alone:** whether the $500K USDT and the migration shortfall are recoverable or spent.

## 4. What an attacker can / cannot do (exact paths)

Can (all verified, none profitable):
- Call `mintWithCollateral`/`redeem` — **reverts** `KeyringCredentialInvalid` (0x…, `hasValidCredentials=false`). Fork: T3.
- Hold NaraUSD (bought anywhere) and redeem — same Keyring revert. Fork: T3.
- Stake NaraUSD into NaraUSD+ (`deposit`, public), cooldown 7 days, `unstake` — nets only the vesting yield (fork T5:
  1,000 → 1,002.2437 NaraUSD after ≥7 days warp).
- `NaraUSD.burn(amount)` (public) — burns the caller's NaraUSD + matching MCT held by the vault; purely self-harm (supply
  reduction), no recipient and no gain.
- Deposit into the Blackopal BoringVault or push the accountant rate — **reverts UNAUTHORIZED** (fork T7).

Cannot:
- Mint/redeem NaraUSD (Keyring), mint/redeem MCT (roles), move MCT collateral (roles), touch the silos (onlyVault), upgrade
  any UUPS proxy (DEFAULT_ADMIN = Safe), withdrawFees/redistribute/blacklist/pause (roles), or trigger the accountant/BV.
- Extract anything via a `mint→redeem` round trip **even with a total Keyring bypass**: parity is exact, 0 fees (fork T8:
  1,000 USDC → 1,000.000000e18 NaraUSD → 1,000.000000 USDC, delta 0). Redeeming more than the booked collateral **queues**
  (fork T9: mint 5,000 via USDT, redeem USDC → `InsufficientCollateral`/queued, escrow returned by `cancelRedeem`).

**The only value an unprivileged actor could ever realise** is the E-U-conditional in the TL;DR (~$270 pool-imbalance arb
with a Keyring bypass; the par-redeem ceiling of $2,958.50 is *not* extractable because acquiring NaraUSD costs ≥ par, and
the $6.83 M backing is unreachable without the Safe/solver). Gas ignored everywhere; note also that all fork figures are
exact-state and the par paths have no fee component to erode a delta.

## 5. PoC / fork verification

- Project `poc/` (foundry.toml pinned by parent: solc 0.8.26, cancun; forge-std 1.9.6 vendored). Fork via keyless public
  RPCs (`FORK_RPC` override, else publicnode/drpc/1rpc). File: `poc/test/NaraUSD.t.sol` — contract `NaraUsdH17Test`.
- **Local run: 9/9 PASS** (`forge test --match-path 'test/NaraUSD.t.sol'`, fork block 26,202,536). CI run URL: parent's run
  (this suite is in the cluster CI path; local pre-verification only).
- Key results: T1 structural parity (MCT supply == NaraUSD supply; booked == actual; BV not collateral); T2/T4/T6/T7 role
  gates all revert; T3 Keyring blocks fresh minters *and* fresh holders; **T8 keyring-bypass round trip delta exactly 0**;
  **T9 queue cap engages beyond $1,959 booked** and `cancelRedeem` returns the escrow; T5 stake round-trip = +0.224% (yield).

## 6. Verdict and residual risk

- **E-U: $0.00 — high confidence.** Two independent reasons: (1) both mint and redeem are Keyring-credential-gated and the
  Keyring rejects arbitrary addresses; (2) even if that gate failed, parity is exact 1:1 with zero fees and no oracle, and
  the only instantly-redeemable collateral is $2,958.50 — no positive-delta round trip exists.
- **E-U-conditional:** Keyring-open (policy disabled / gate removed by upgrade) + the live Curve pool imbalance → a
  mint-at-par-and-sell arb capped at ≈ **$270** single-shot (pool would rebalance; repeatable only if re-imbalanced).
- **H-O:** $2,958.50 instantly redeemable at par by *credentialed* holders; the remaining ~$9.84 M of claims are queue/
  solver-discretionary and marked at **92.89% coverage** (gap ≈ $699.8 K; §3) — the single most important finding for
  users, though not an attack path.
- **P:** the Safe (3-of-5, owners `0xEa2ea7BD…`, `0x3bEAAb5E…`, `0x087e45aa…`, `0x3E31A6B4…`, `0x5c1c4A72…`) controls
  **$9,139,735** via COLLATERAL_MANAGER/ADMIN/UUPS plus the Keyring config and NaraUSD+ REWARDER (EOA `0x2c4c371e…`) /
  GATEKEEPERs (EOAs) — role-key compromise is the main privileged risk.
- **S:** none identified (all paths terminate in a privileged action or a user action).
- **Monitors:** `Keyring.checkCredential(policy, <random>)` flipping true; `mct.collateralBalance` vs actual balances;
  Safe transfers to non-tracked addresses; `UnbackedMint` events; NaraUSD+ `vestingAmount`/REWARDER activity; pool balance
  ratio on `0xf05F1b7b…`.

## 7. Methodology & sources

Read-only throughout; no keys or keyed URLs in any artifact (Etherscan V2 and Dune keys were **expired** — Sourcify v2 +
Blockscout API + public RPC (publicnode/drpc/Tenderly/mevblocker) were used instead). Sources: Sourcify exact matches for
NaraUSD/MCT/NaraUSD+/Safe/mGLOBAL/Keyring (saved under `sources/…_src`), Blockscout `api/v2` for BoringVault +
AccountantWithRateProviders. Event history via `eth_getLogs` on public gateways (Tenderly, mevblocker; block ranges
24,983,700→latest; mGLO/mGLOBAL transfer history separately scanned). DefiLlama adapter `nara-usd.js` cross-checked —
**it under-counts ~$2.32M** because it still lists the deprecated mGLOBAL wrapper `0x74338069…` (Safe balance 0) instead
of the protocol's mGLO `0x1dd91a11…`. Prior-corpus check: no NaraUSD entry outside this cluster.

**Files:** `README.md` · `summary.json` · `live_state_2026-10-16.json` · `state_reads_1.txt` · `live2_out.txt` ·
`roles_scan_out.txt` + `roles_scan.py` · `mint_history*.py`/`getlogs*.py` + `hist_summary.json` · `getlogs_bs_out.txt` ·
`safe_outflows_out.txt` (script `safe_outflows.py`) · `safe_inflows_out.txt` · `hist_fix2_out.txt` · `extras_out.txt` ·
`bs_search_narausd.json` · `FORKHELPER-BLOCKER.md` (cluster-wide compile blocker + 1-line fix for the parent) ·
`sources/**` (verified sources) · `poc/test/NaraUSD.t.sol`.
