# Child C — Nuri CL (Scroll) deep-dive: **V2 / cAMM factory value + extraction audit**

Date: 2026-10-13 · Chain: Scroll (534) · **Read-only; no transactions sent; eth_call simulation only.**
Blocks: pairs/pricing **35,364,606**; factory guard probes **35,364,623**; NURI liquidity **35,364,648** (latest ~35,364,6xx).
Deliverable of the parent Nuri-CL investigation (target: `0xAAA16c016BF556fcD620328f0759252E29b1AB57`).

## TL;DR

| Target | Live value (block 35,364,606) | Unprivileged-extractable (E-U) | Why |
|---|---|---|---|
| V2 factory + 74 pairs | **$4,576.26** priced; **$5,237.15** incl. NURI at DEX-implied price | **$0.00** | All 35 factory selectors are views/permissionless pair-creation or owner/feeManager/treasury-gated; every pair-level "anyone-can-call" path (skim/burn/claimFees/setFeeSplit) has **zero** extractable excess today |
| Voter `0xAAAf3D9C…` | 411.78 NURI (~$0.33) + 1 ERC-1155 dust | $0 | balances are protocol-owned; no withdrawal fn |
| Minter `0xAAA823aa…` | 0 tokens, 0 ETH | $0 | mint path `!MINTER`; updatePeriod pays protocol, not caller |
| Treasury/owner Safe `0xC9d2867…` | ~$4 of tokens (99% scam-airdrop dust) + 44.19 NURI; 0 ETH | $0 | Safe-controlled |
| NURI exit liquidity | deepest venue **WETH/NURI V2 pair: 0.2609 WETH (~$654) + 809,757 NURI** | $0 | no mint path; selling 1M NURI yields only ~0.14 WETH ($357) |

**Total live extractable by an external unprivileged attacker: $0.00 (confidence: high).**

## 1. Addresses / architecture (all read at block 35,364,606 unless noted)

| Item | Address | Notes |
|---|---|---|
| Factory proxy (TransparentUpgradeableProxy) | `0xAAA16c016BF556fcD620328f0759252E29b1AB57` | runtime 2,420 B; `allPairsLength()=74`, `isPaused()=false` |
| Factory logic (EIP-1967 slot `0x360894…382bbc`) | `0xa7d39aff8f4bd058f48e59f10820d0bf3243a872` | runtime 7,114 B; **scrollscan `is_verified: false`**; selector set = Ramses V2 PairFactory + `owner/setOwner` + `implementation()` + 5-arg `initialize` |
| ProxyAdmin (EIP-1967 admin slot) | `0x8e01fc0d89b93a6447d6c6eca6fbd30e6e4a1ce3` | `owner() = 0xAAA13cbe7a8cf93cf3505d00fe254fdcce14ef4e` (can upgrade factory/CommandCenter/Minter proxies) |
| Pair implementation (beacon) | `0xf5d139c3f51967505c532c42898ba47b15da4b9f` | **verified** `Pair` (Ramses V2 lineage, 27,715 B source); `factory.implementation()` returns it |
| Pairs | `PairBeaconProxy` (`BeaconProxy(msg.sender,"")`) | beacon slot = factory (`0xAAA16c…`) on every pair |
| owner / pauser / treasury | **Safe `0xC9d28676b7d470210a3C490B60729660eE5a7257`** | all three point to the same Safe |
| feeManager | `0xAAA11500dddb2b67a90d1a154dfb7eabb518eae6` (**CommandCenter proxy**, logic `0x6ed9d8b1…`, verified; all mutating fns role-gated; holds 0 tokens) |
| voter / minter | `0xAAAf3D9CDD3602d117c67D80eEC37a160C8d9869` / `0xAAA823aa799BDa3193D46476539bcb1da5B71330` (Minter proxy → logic `0xe32cf10047ea2dcd632112e407f378c3147e3d78`, verified) |
| NURI token | `0xaaae8378809bb8815c08d3c59eb0c7d1529ad769` (`EmissionsToken`, solmate ERC20, `minter()=Minter proxy`) |

Live parameters: `stableFee=1` (0.01%), `volatileFee=30` (0.30%), `MAX_FEE=1000` (10%), default `feeSplit=42`
→ 50% of swap fee to `PairFees`, 10% to treasury, rest to LPs; overrides: zHAWK/USDT `19`, ETHFI/WETH `80`.
74 pairs = 66 volatile (`vAMM-*`) + 8 stable (`cAMM-*`); 5 pairs have an active gauge; 34/74 PairFees have a feeDistributor set.

## 2. V2 pairs' live value (block 35,364,606; balances == reserves for all 148 token sides)

Total = **$4,576.26** (DefiLlama-priced tokens; unpriced tokens recorded as $0) = **$5,237.15** if the 817,727 NURI
held by pairs is valued at the on-chain WETH/NURI implied price $0.0008082. No pair holds any native ETH.

| # | Pair | Type | Token0 amount | Token1 amount | USD |
|---|---|---|---|---|---|
| 1 | `0x9b6b3a61…9b501c8d` vAMM-WETH/STONE | vol | 0.352981617895487167 WETH | 0.330381514779851477 STONE | $1,771.75 |
| 2 | `0x8ae1c699…b69a7ffe` vAMM-WETH/NURI | vol | 0.260898914736861987 WETH | 809,757.238708542836252943 NURI | $654.45 / $1,308.90* |
| 3 | `0x24b8a8cf…596b8e1e57` vAMM-Sinu/WETH | vol | 286,420,674,097,946,126,762,510,023,240,948 Sinu ($0) | 0.493284177972293184 WETH | $1,237.37 |
| 4 | `0x8c2b2e5d…f468ae3119` vAMM-weETH/wstETH | vol | 0.076401762005083064 weETH | 0.067760250024753465 wstETH | $423.98 |
| 5 | `0x93495be9…b8d7a31d7a` cAMM-WETH/STONE | stable | 0.043662116565067075 WETH | 0.022444889792951263 STONE | $169.74 |
| 6 | `0x1e7f72a9…5fc689b2c` vAMM-USDC/WETH | vol | 80.506394 USDC | 0.032193544690926255 WETH | $161.25 |
| 7 | `0x4775dffd…1f0d8f1698` cAMM-USDC/loreUSD | stable | 97.024361 USDC | 121.2146…15 loreUSD ($0) | $97.01 |
| 8 | `0x172da8b4…a7b81aa4` vAMM-WETH/KOMO | vol | 0.007772032079940351 WETH | 2.06545…18 KOMO ($0) | $19.50 |
| 9 | `0xe1bf63d5…7153825c` vAMM-WETH/wrsETH | vol | 0.002678390565155033 WETH | 0.002579871773579195 wrsETH | $13.64 |
| 10 | `0x5652beb9…fc5207de` vAMM-WETH/USDT | vol | 0.001234796260196408 WETH | 3.082825 USDT | $6.18 |

\* NURI side valued at DEX-implied price. Remaining 64 pairs ≈ $22–$28 combined (mostly WETH dust + rd/SCROLLY/BASED junk).
Unpriced non-zero holdings (worth $0 per DefiLlama, kept in raw JSON): Sinu, fake-DAI `0x8844…`, SCEPE, 007, BASED, BALD, MATRENDLARGENT, KOMO, LORE, CHESS, zHAWK, abcNURI, SCROLLY, etc.

## 3. Unprivileged extraction audit — every state-changing path

Factory (35 dispatch selectors recovered from bytecode; all probed via `eth_call` from `0x…dEaD`):

| Function | Guard (measured) | Probe from unprivileged | Passes only from |
|---|---|---|---|
| `setOwner`, `setPauser`, `setPause(bool)` | `msg.sender == owner` (`"AUTH"` / bare revert) | REVERT | Safe `0xC9d2867…` |
| `setFee(bool,uint256)`, `setFeeManager`, `setPairFee`, `setFeeSplit(u8,u8)`, `setPoolFeeSplit` | `msg.sender == feeManager` (`"not fee manager"` / `"!AUTH"`) | REVERT | CommandCenter `0xAAA11500…` |
| `setTreasury(address)` | `msg.sender == treasury` (`"!AUTH"`) | REVERT | Safe (treasury) |
| `setImplementation(address)` | `msg.sender == owner` (`"AUTH"`) | REVERT | Safe (owner) |
| `acceptPauser()` / `acceptFeeManager()` | `msg.sender == pendingPauser/Manager`; live pending = **0** | REVERT (`"not pending…"`), OK only from address(0) — unreachable in a real tx | nobody |
| `initialize(5 args)` | `initializer` | REVERT `"already initialized"` | nobody |
| `createPair` | **ungated** (reached `"IA"` arg check); standard permissionless pair creation, creates only the caller's own pair | permissionless | — (no value at stake) |
| all views (`owner`,`pauser`,`feeManager`,`treasury`,`getFee`,`getPoolFeeSplit`,`implementation`,…) | — | OK | — |

Pair implementation `0xf5d139…` (verified source, audited line-by-line):
- `swap` — `lock` + `require(!isPaused())` (false) + standard x*y / x³y+y³x math with fee `amountIn*getFee/10000` moved out to `PairFees`/treasury; no attacker gain beyond fair trade.
- `skim(to)` — permissionless; sends `balanceOf(this) − reserve` to `to`. **Measured excess = 0 wei on all 74×2 sides** (balances == reserves) → $0 extractable.
- `sync()` — permissionless; only writes reserves := balances. No transfer out.
- `mint`/`burn` — standard; `burn(to)` pays the pair's own LP balance pro-rata. **`balanceOf(pair) == 0` on all 74 pairs** → $0; `balanceOf(0x0)=1000` MINIMUM_LIQUIDITY locked forever.
- `claimFees()` — permissionless (deviation from older Ramses, which gated it to the gauge); calls `PairFees.claimFeesFor()` which **only** `notifyRewardAmount`s the feeDistributor (or no-ops if unset). Funds cannot reach the caller. PairFees priced balances total **$0.07**.
- `setActiveGauge(bool)` — `msg.sender == voter` only. `setFeeSplit()` — permissionless but only syncs the factory's per-pool split; factory setter is feeManager-gated.
- `initialize(...)` — `initializer` (already used on all pairs). `permit`/`transferFrom` — standard.
- Canonical diff (Ramses V2 `Pair` @ Arbitrum `0xF5B610…`): `_update0/_update1/skim/sync/burn/setFeeSplit/_k/_d/_safeTransfer/permit/transferFrom` **identical**; differences are version-level (5-arg `initialize` w/ voter, permissionless `claimFees`→feeDistributor, newer `_f`/`_get_y` rounding/loop variant in the stable curve). No additional privileged/ungated path found.

NURI mint path (zombie-mint check): `NURI.mint` → `"!MINTER"`, `setMinter` → `"!MINTER"`; minter = Minter proxy.
Minter: `updatePeriod()` permissionless but mints to voter/rewardsDistributor (not caller); `activePeriod=1790812800` is in the future → no-op today; `reinitializeWeekly()`/CC `initializeNewVars()` → `"already initialized"`; `initiateEpochZero()` → `NotMultisig`.

## 4. Negatives with evidence (do not re-investigate)

1. No skim excess, no self-LP (`burn`), no ETH, no stuck tokens in pairs: `childC-v2-pairs.json`, `childC-v2-selflp.json` (0/74 pairs, 0/148 sides).
2. All factory admin functions revert for unprivileged callers with the greppable strings above: `childC-v2-factory-probe.json`, `childC-v2-role-matrix.json`.
3. `pendingPauser/pendingFeeManager == 0` → accept functions unreachable in real txs.
4. Minter holds 0; `reinitialize*` used; `updatePeriod` inert until 2026-09-29-ish; no caller payout even then.
5. CommandCenter (`feeManager`): every setter role-gated; `multisigWithdraw` sends to Safe (`multisig()`); dead address has no roles; 0 token balances.
6. Treasury Safe value ≈ $4 (STONE/WETH dust + 44 NURI); remaining 40+ entries are scam airdrops ($0).
7. Voter holds 411.78 NURI (~$0.33); Minter 0; PairFees $0.07 priced.

## 5. Verdict

- **E-U (external unprivileged): $0.00 — confidence high.** Blockers: every admin path is owner/feeManager/treasury-gated
  (Safe / role-gated CommandCenter); pair impl is verified and its only public-withdraw surfaces (skim, burn) measure exactly zero;
  NURI cannot be minted by outsiders; exit liquidity would cap any theoretical dump at ≤$654 anyway.
- **P (privileged)**: Safe can pause swaps, change fees (≤10%)/splits, set treasury/owner; ProxyAdmin owner can upgrade
  factory/pair-impl (affects all pairs); CommandCenter roles set fees/fee-protocol. No privileged path benefits an outsider.
- **Latent**: factory logic is unverified on Scrollscan (behavioral/selector match to verified Ramses PairFactory + full guard
  probing; residual risk low since it holds no tokens and cannot be upgraded by anyone but the ProxyAdmin owner). Pairs hold LP-owned value;
  LP exits are normal `burn` flows (not extraction). NURI has near-zero exit liquidity (~$654 WETH) — holders cannot exit, but nobody can steal it either.

## 6. Method & files

`eth_call`/`eth_getStorageAt`/`eth_getCode` on `https://rpc.scroll.io` at pinned blocks; DefiLlama `coins.llama.fi/prices/current`;
scrollscan v2 API for sources; guard matrix = state simulation from 7 caller identities. No txs, no keys, no CI needed (all reads small).
Files: `childC-v2-pairs.json` (raw state), `childC-v2-pairs-priced.json`, `childC-v2-factory-probe.json`, `childC-v2-role-matrix.json`,
`childC-v2-pair-details.json`, `childC-v2-selflp.json`, `childC-nuri-liquidity.json`, `childC-v2-other-value.json`,
`childC-v2-summary.json`, scripts in `childC-scripts/`, sources in `sources/v2pair/`, `sources/v2pairbeaconproxy/`, `sc/*.json`.
