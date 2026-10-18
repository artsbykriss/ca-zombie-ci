# ZH4-06 — BeraFarm (Berachain): patched overnight after a RewardVault delegated-stake NAV-inflation exploit

**Date:** 2026-10-18 · **Chain:** Berachain (chainId 80094) · **Status:** read-only;
fork-verified only; no mainnet transactions; no secrets in this folder.

**One line:** the Oct-9 attacker was stopped by Kodiak's automated island pause; BeraFarm
then paused, replaced the three gauge-staking strategy implementations and the Kodiak swap
controller. The replacement bytecode (unverified on the explorer) **subtracts the
permissionlessly-delegated RewardVault stake from strategy NAV**; a full fork replay of the
Oct-9 recipe against the current build is a net loss. **Live external-unprivileged
extraction today: $0.** The pre-patch exposure was **≈$243k** of the **$257.9k** TVL.

---

## 1. TL;DR

| Target | Live unprivileged extraction | Why closed | Latent risk |
|---|---|---|---|
| BeraFarm vault0 / Kodiak strategy (`0x4a3c8Fdd…`, `0x1Ce23321…`) | **$0** | current impl `0xc6865dc8` computes `getTokenBalance() = gauge.balanceOf − gauge.getTotalDelegateStaked`; a real `delegateStake` of 1.2m island LP leaves NAV unchanged (fork test) | unverified source; future upgrade to a `balanceOf`-only impl |
| HubBend-1 / HubBend-2 (`0xC8f67DD8…`, `0xa13e0a5f…`) | **$0** | current impl `0xee965e0a` uses the same subtraction (storage-level fork test) | same |
| Dolomite strategy (`0x7F41C51A…`) | **$0** | no RewardVault gauge; `getTokenBalance` is the Dolomite balance (unchanged impl) | none found |
| KodiakSwapController (`0x1cAc0625…`) | **$0** | new impl `0x2be0125f` adds balance-delta accounting; both versions are pull-only (`safeTransferFrom(msg.sender)`) and hold no funds | unverified source |
| Vault TVL (all vaults) | **$0 E-U** | attack vector patched; ordinary TVL remains user-withdrawable | **P: $257.9k** owner-upgradeable |

**Pre-patch (block 27,270,000) gauge-staked exposure:** Bend-1 76,818.8 + Bend-2 90,067.1
+ Kodiak 76,542.2 = **243,428 HONEY** (~95% of the 256,187 HONEY vault NAV) — the
"at least $250K" estimate in Kodiak's/Hypernative's Oct-12 posts.

---

## 2. Total live extractable now

**$0 (E-U), high confidence.** The vault holds **257,798.70 HONEY + 1,607.81 WBERA**
(block 27,634,505) ≈ **$253.7k** at 2026-10-18 DefiLlama prices (HONEY $0.9831, BERA
$0.1799); the campaign's **$257.9k** figure values HONEY at par. Nothing is extractable by
an unprivileged attacker through the Oct-9 vector; the vault is solvent and withdrawals
are open. The $257.9k is **P** (owner-upgradeable proxy family), not E-U.

---

## 3. The bug, in exact terms

### 3.1 The primitive

Berachain's `RewardVault` (`0x75Da1D58…`, verified) lets **anyone** stake tokens on behalf
of **any account**:

```solidity
// RewardVault.sol (verified)
function delegateStake(address account, uint256 amount) external nonReentrant whenNotPaused {
    if (msg.sender == account) revert NotDelegate();
    _stake(account, amount);                                     // _accountInfo[account].balance += amount
    _delegateStake[account].delegateTotalStaked += amount;
    _delegateStake[account].stakedByDelegate[msg.sender] += amount;
}
function delegateWithdraw(address account, uint256 amount) external ... { /* delegate pulls it back */ }
function getTotalDelegateStaked(address account) external view returns (uint256);
```

`balanceOf(account)` therefore includes stake that the account **does not own and cannot
withdraw** (`withdraw()` enforces `amount <= balance − delegateTotalStaked`).

### 3.2 The old strategies counted it as NAV

Pre-incident Kodiak strategy `0x36bfa55a5cbe2c382f02f551db1e8acbcc929137` (verified source,
byte-exact recompile in `analysis/compile/`) and HubBend `0x6481216093a69f5701e42b7a8b4d1a5765489322`
(both verified):

```solidity
function getTokenBalance() public view returns (uint256) {
    return IBGTGauge(hubVault).balanceOf(address(this));   // includes delegated stake
}
function getUnderlyingBalance() public view returns (uint256) {
    return _getUnderlyingBalance(getTokenBalance());       // oracle-priced
}
```

### 3.3 The extraction

1. Deposit into the **junior** tranche (entry fee 0; exit 1% within 7 days; whitelist off,
   deposits/withdrawals unpaused).
2. Mint island LP via `islandRouter.addLiquidity` (or a Bend receipt token for the Bend
   strategies) and call `gauge.delegateStake(strategy, amount)`. The attacker keeps the
   right to `delegateWithdraw`.
3. The next `TrancheVault._updateInvestment()` (inside `deposit`/`withdraw`) sees
   `currentStrategyBalance > previousCurrentStrategyBalance` and books the difference as
   **profit** — senior takes its block-rate claim, the rest is credited to **junior**.
4. Withdraw the junior shares at the inflated rate. The payout is real currency pulled from
   all strategies; the strategy's own `hubVault.withdraw` is limited to its **self-staked**
   balance, which bounds the per-strategy extraction to roughly that self-stake.
5. `delegateWithdraw` returns the LP; the fake profit remains in the vault's books until the
   next loss sync, which hits the (now under-funded) junior tranche first.

Fork-measured NAV deltas for a +10,000 delegated stake:

| Strategy | old NAV (HONEY) | after delegated +10k | delta |
|---|---|---|---|
| Kodiak `0x36bfa55a` | 76,542.18 | 77,927.19 | +1,385.01 |
| HubBend-1 `0x64812160` | 76,818.81 | 86,903.33 | +10,084.51 |
| HubBend-2 `0x64812160` | 90,067.14 | 100,204.26 | +10,137.12 |

### 3.4 The patch

The current Kodiak `0xc6865dc8` and Bend `0xee965e0a` impls call
`getTotalDelegateStaked(strategy)` (`0xa4dbda3c`) and **subtract** it:

```
getTokenBalance()  = hubVault.balanceOf(this) − hubVault.getTotalDelegateStaked(this)
getUnderlyingBalance() = oracleValue(getTokenBalance())
```

Verified on mainnet forks (see §6): a real `delegateStake` of 1.2m island LP leaves the
strategy NAV exactly unchanged, and the full Oct-9 recipe loses 264 HONEY. The previously
unexplained wave-2 selector `0x2936f68f` is not a selector: it is the compiler's shifted
encoding of `0xa4dbda3c` (`PUSH4 0x2936f68f; PUSH1 0xe2; SHL`).

The new swap controller `0x2be0125f` adds `balanceOf`-delta accounting around
`exactInputSingle`/`exactInput`; both old and new controllers are public but pull-only
(`safeTransferFrom(msg.sender, …)`) and hold no funds. No unprivileged path was found in
either version.

---

## 4. Live state (all reads at block 27,634,505 unless stated)

EIP-1967 implementation slots (`0x3608…3bbc`) and balances:

| Contract | Address | Current impl | Notes |
|---|---|---|---|
| TrancheVault0 | `0x4a3c8Fdd55017773fEe33dE4aa7e12dD60B0A054` | `0x50d0d654…` | NAV **257,798.70 HONEY**; senior book 248,127.42 / supply 246,887.49; junior book 9,670.62 / supply 9,029.01 |
| TrancheVault1 (WBERA) | `0xeb9ce8E12898bEb918a7e36A1c30eE094EbcBa0A` | `0x50d0d654…` | 1,607.81 WBERA |
| TrancheVault3 (dust) | `0xEA20a9d1B464FFf7C8A6a9039C3CF94f0a09471D` | `0x50d0d654…` | 0.297 HONEY |
| StrategyManager0 | `0x9546b34291393fb247db7d4C677f1394D4BbE0DD` | `0xd3ec0a3a…` | 4 strategies, ratios 3000/1000/500/5500 |
| Kodiak strategy | `0x1Ce23321A72F2dae96809cC6192f053A7aD5D8e4` | **`0xc6865dc8…`** | `getTokenBalance` 556,214.99 LP; `getUnderlyingBalance` **77,010.17 HONEY**; gauge delegate 0 |
| HubBend-1 | `0xC8f67DD8C2909750705E0533f8CA71dCdf380CC9` | **`0xee965e0a…`** | NAV 77,293.21 HONEY; gauge delegate 0 |
| HubBend-2 | `0xa13e0a5fE378E89cC72730F8Df2e140Ebc6F1E84` | **`0xee965e0a…`** | NAV 90,669.30 HONEY; gauge delegate 0 |
| Dolomite | `0x7F41C51A50AA3591f16fFDc37A5b8A79305f5DC7` | `0xaf4f95f0…` (unchanged) | NAV 12,826.01 HONEY; no gauge |
| KodiakSwapController | `0x1cAc0625ee3A4679dCE7f9dC921ECFDD5c378987` | **`0x2be0125f…`** | public pull-only swaps |
| ProtocolRegistry | `0x0c5ab414845386758c50e7a5e08b59964a02f2bd` | `0xc7698654…` | `getProtocolState() = false` |
| PriceOracle | `0xeb2CC2dF8698250FB7fb6F310CBca6B3266E3b80` | `0x94547301…` | Pyth/Chronicle/Chainlink |

Vault config (`0x636D34dd…`): `isWhitelistedVault=false`, deposits **not** paused,
withdrawals **not** paused, TVL limit 325,000 HONEY, junior tranche limit 25,000 HONEY,
vault swap slippage 200 bps, LP slippage 500 bps. Fees (`0xe5061B0d…`): senior entry 100 bps,
senior exit 0; junior entry 0, junior exit 100 bps (<7 days).

Kodiak island `0xE5A2ab5D…`: `paused=false`, 13,740,152.34 shares, underlying
649,109.41 USDe + 1,253,491.38 HONEY, pool `0x9E4C4606…`, tick 4, range [-200, 110].
Gauge `0x75Da1D58…`: `paused=false`, `balanceOf(strategy)=556,214.99`,
`getTotalDelegateStaked(strategy)=0`.

Pause-state citations: island `paused()` = false @27,281,529 / **true @27,281,530** /
true @27,303,989 / **false @27,303,990**; registry `getProtocolState()` =
**true @27,301,950** / false @27,349,367 (both re-read on 2026-10-18).

**Pre-patch snapshot (block 27,270,000):** vault NAV 256,187.30 HONEY; junior book 8,421.84 /
supply 8,038.67; strategy NAVs 76,818.81 / 90,067.14 / 12,759.17 / 76,542.18; Kodiak impl
`0x36bfa55a…`, Bend impls `0x64812160…`, swap controller `0x1d5642c1…`; island unpaused;
gauge unpaused.

**Other vaults (factory `0xfD2A077Fa8E81A258f85e21365EeaC5e6e92f109`, 4 vaults):** vault1
(WBERA, manager `0x550670e4…`) holds 1,607.81 WBERA in a single Dolomite strategy
(`0xf0054Ab5…`, no gauge); vault2 (manager `0xcC081E30…`) has four strategies with zero NAV
and deposits paused; vault3 (manager `0x560972C7…`) holds 0.297 HONEY. Only vault0 uses the
gauge-staking Kodiak/Bend strategies, so the material target set is complete.

---

## 5. What an attacker can / cannot do

**Can (today, unprivileged):**
- deposit/withdraw senior or junior (no whitelist); senior entry 1%, junior exit 1%
  (<7 days);
- mint/burn island LP and swap on the open Kodiak route (island unpaused);
- call `RewardVault.delegateStake(strategy, amount)` / `delegateWithdraw`; this now moves
  `balanceOf` and `delegateTotalStaked` **together**, so the strategy NAV is unchanged;
- donate tokens with `stakeOnBehalf` / ERC-20 transfer — this increases NAV by real assets
  the strategy owns; donating is not profitable (fork test: −79,900 HONEY).

**Cannot (today):**
- inflate the strategy's reported NAV with delegated stake (subtraction verified);
- make the vault pay more than the realized strategy withdrawal (payout is the actual
  `balanceWithdrawn`, not the book `withdrawAmount`);
- withdraw the strategy's LP via the controller/gauge (pull-only; per-strategy approvals
  reset; `RewardVault.withdraw` only self-staked).

**Pre-patch (for the record):** the full recipe on block 27,270,000 extracts
**+77,558 HONEY** with 220,000 HONEY of transient LP capital and a 15,000 HONEY junior
deposit (fork-proven, gas 11.1M). The gain ≈ the Kodiak self-staked position. The same
NAV-inflation was measured on both Bend strategies; their self-staked NAV adds ≈166,886
HONEY of pre-patch exposure.

---

## 6. Fork verification (PoC)

`poc/` — Foundry, forks `https://rpc.berachain.com` at fixed blocks; no mainnet writes.

| # | Test | Block | Result |
|---|---|---|---|
| 1 | `test_old_impl_full_attack_profitable` | 27,270,000 | **PASS** — NAV 81,032.76 → 234,860.67; **P&L +77,558.25 HONEY**; gas 11.1M |
| 2 | `test_current_impl_full_attack_not_profitable` | 27,633,715 | **PASS** — NAV unchanged (81,488.32); **P&L −264.20 HONEY**; gas 11.98M; HubBend-1/2 subtraction checks also pass in this test |

`forge test -vvv` → **2 passed / 0 failed**. CI run: see `ci-log.txt` / `ci-artifacts/`
(URL recorded in `summary.json`).

Auxiliary probes run during the analysis (not part of the CI suite, results in
`analysis/`): standalone NAV delta for +10,000 delegated stake — old Kodiak 76,542.18 →
77,927.19, old Bend-1 76,818.81 → 86,903.33, old Bend-2 90,067.14 → 100,204.26; current
Kodiak 77,010.17 unchanged; `stakeOnBehalf` donation variant −79,899.84 HONEY.

PoC mechanics: mint LP by swapping half the HONEY to USDe through the Kodiak router and
calling `islandRouter.addLiquidity`; `delegateStake`; withdraw junior (the withdraw path's
`_updateInvestment` books the profit; a deposit cannot be used to sync because the
post-delegation NAV exceeds the 325k vault TVL limit and `VaultMaxTvlLimit` reverts);
`delegateWithdraw`; burn LP; value USDe 1:1 (pool ≈1.000). Gas is reported by Foundry; the
attacker needs transient HONEY/USDe liquidity (flash-loanable in Berachain's deep HONEY
pools; modelled with `deal` in the PoC).

---

## 7. Verdict and residual risk

- **E-U today: $0 (high confidence).** The delegated-stake NAV inflation is closed in all
  three gauge-staking strategies; the full Oct-9 recipe on the current bytecode loses money.
- **E-U during the Oct-9 window: ~$243k gauge-staked NAV** (Kodiak leg fork-proven at
  +77.6k HONEY; Bend legs measured at +10.1k/+10.1k HONEY NAV per +10k delegated stake).
  The attack never landed; Kodiak's pause + BeraFarm's own pause/upgrades closed it.
- **H-O: $0 trapped.** Withdrawals are unpaused and the vault is solvent; the $257.9k is
  ordinary TVL, not stuck funds.
- **P: $257.9k.** The owner Safe `0x0E222512c4CCb7FB7773017b82981be14baFeEeA` controls
  upgradeable proxies (vaults, manager, strategies, registry, oracle) and can pause; the
  manager's `inCaseTokensGetStuck` moves only idle currency. This is privileged, not E-U.
- **S: $0.**

**Latent risks / what would change the verdict:**
1. The post-incident impls are **unverified**; the verdict is behavioural (fork + storage
   probes), not a source audit. Watch for verification, then re-audit.
2. Any upgrade/re-deployment that restores a `balanceOf`-only NAV (old `0x36bfa55a` /
   `0x64812160` class) re-arms the attack. Monitor every impl slot.
3. A new strategy family that stakes in a RewardVault (or any stake-on-behalf/delegate
   primitive) without subtracting the delegated amount.
4. The Kodiak **spot** is still used for deposit split / LP min amounts
   (`island.getUnderlyingBalances()`), and the swap controller uses oracle bounds; a
   sandwich/exit-value variant was not proven profitable and is bounded by the $77k Kodiak
   position, but it is a generic MEV surface, not the incident vector.
5. The attacker's precise Oct-9 contract/tx never appeared on-chain; the reconstruction is
   code-derived and fork-proven, not an on-chain replay.

**Monitors (cheap, high-signal):**
- EIP-1967 slot changes on `0x1Ce23321…`, `0x1cAc0625…`, `0xC8f67DD8…`, `0xa13e0a5f…`, the
  vaults, manager, registry, oracle.
- `DelegateStaked` / `DelegateWithdrawn` on the three gauges with `account = strategy`
  (currently zero events ever; `getTotalDelegateStaked = 0`).
- Divergence between `strategy.getUnderlyingBalance()` and the value of
  `gauge.balanceOf − gauge.getTotalDelegateStaked` (a reverted/old-class impl signal).
- Kodiak island `pause()/unpause()` on `0xE5A2ab5D…` and the island set; vault TVL-limit
  headroom and NAV jumps; new strategies (`updateStrategy`) / new vaults.
- Source verification of `0xc6865dc8`, `0x2be0125f`, `0xee965e0a`.

---

## 8. Methodology & sources

- **On-chain (read-only):** public keyless `https://rpc.berachain.com`, `eth_call`/
  `eth_getStorageAt`/`eth_getCode` at pinned blocks 27,270,000, 27,320,000, 27,633,715,
  27,634,505; EIP-1967 slot reads; event logs.
- **Source:** Etherscan V2 (chainid 80094) for `0x36bfa55a` (HubStrategyKodiakIsland),
  `0x64812160` (HubStrategyBend), `0x1d5642c1` (KodiakSwapController), RewardVault,
  vault/manager/config/oracle/fee module.
- **Exact recompile:** solc 0.8.30, optimizer runs=1, viaIR, evmVersion=paris,
  `metadata.bytecodeHash=none` → byte-identical to the deployed old Kodiak impl modulo the
  self-address placeholder (`analysis/compile/`).
- **Decompilation:** heimdall-rs 0.9.2 (`analysis/decomp/new_strat`, `new_swap`); selector
  analysis with `cast disassemble`, including the shifted-constant encoding of
  `getTotalDelegateStaked`.
- **Fork probes:** anvil at 27,270,000 / 27,320,000 / latest, storage overrides to simulate
  `delegateStake` (balance + delegate slots), then `getTokenBalance`/`getUnderlyingBalance`.
- **PoC:** Foundry 1.8.5, two end-to-end fork tests (`poc/`), 2/2 pass (plus auxiliary
  NAV/donation probes in `analysis/`).
- **Evidence:** `zombie-hunt-iv/wave2/v2-berafarm.md`, `wave1/r2-x-radar.md` row 1;
  Kodiak/Hypernative posts (Oct 12); DefiLlama protocol + `coins.llama.fi` prices;
  BeraFarm docs/audit page. Web content treated as untrusted data.

**Caveats:**
- USD at 2026-10-18 00:xx UTC DefiLlama prices: HONEY $0.9831, BERA $0.1799; the campaign's
  $257.9k uses par HONEY.
- The new impls' source is unpublished; behaviour was verified at specific blocks and with
  a real `delegateStake`.
- The Bend full-drain leg was not built (receipt-token sourcing); the NAV inflation on both
  Bend strategies is measured on-chain at the pre-patch block.
- The PoC abstracts flash liquidity with `deal`; the LP is recoverable and the net at-risk
  capital is the junior deposit + fees.
- No mainnet transactions were sent; no secrets are stored in this folder.

**Files:** `README.md`, `summary.json`, `analysis/` (`live_state.json`, `final_state.py`,
`rpc.py`, `patch_analysis.md`, `incident_reconstruction.md`, `src/`, `compile/`, `decomp/`,
`trace_realtx_harvest.json`), `poc/` (`foundry.toml`, `src/Interfaces.sol`,
`test/VaultInflation.t.sol`, vendored `lib/forge-std`), `ci-out/`, `ci-log.txt`.
