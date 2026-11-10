# L2 lane — Zenji sibling hunt (Optimism / Base / Arbitrum)

**Date:** 2026-11-10 · **Mode:** read-only. No transactions signed or broadcast. Every value below is a
point-in-time read at the stated block. **Chains:** Optimism 10, Base 8453, Arbitrum 42161.
**Scope:** leveraged-yield / leveraged-farming / ERC-4626 leveraged vault protocols.

**Status: clean negative.** 15 candidate rows across 6 protocols; **0 pass all three tests.**
The only permissionless keeper path verified in this lane is Beefy's `harvest()`, and it
has no debt, no LTV and no liquidation — it is the control, not a sibling.

---

## 1. TL;DR

| # | Protocol | Chain | Address | Keeper path | (a) permissionless? | (b) pool-priced LTV? | (c) vault-derived minOut? | Verdict |
|---:|---|---|---|---|---|---|---|---|
| 1 | Extra Finance — VeloVaultPositionManager | OP | `0xf9cF…7055` | `liquidateVaultPositionPartially` | **NO** — flag false, `"20"` whitelist revert | per-vault flag; 34/54 live = spot | caller-supplied | not-zenji |
| 2 | Extra Finance — VeloVaultPositionManager | Base | `0xf9cF…7055` | `liquidateVaultPositionPartially` | **NO** — flag false, `"20"` | 75/87 live = spot | caller-supplied | not-zenji |
| 3 | Extra Finance — VeloVaultPositionManager | OP | `0xf9cF…7055` | `closeOutOfRangePosition` | **NO** — range-stop flag false, `"20"` | range-stop vs pool | caller-supplied | not-zenji |
| 4 | Extra Finance — VeloVaultPositionManager | Base | `0xf9cF…7055` | `closeOutOfRangePosition` | **NO** | range-stop vs pool | caller-supplied | not-zenji |
| 5 | Extra Finance — VeloVaultPositionManager | OP | `0xf9cF…7055` | `investEarnedFeeToLiquidity` | **NO** — compound flag false, `"20"` | n/a (fees only) | caller routes | not-zenji |
| 6 | Extra Finance — VeloVaultPositionManager | Base | `0xf9cF…7055` | `investEarnedFeeToLiquidity` | **NO** | n/a | caller routes | not-zenji |
| 7 | Extra Finance — VeloVaultPositionManager | OP | `0xf9cF…7055` | `newOrInvestToVaultPosition` | yes (own funds) | n/a | caller `amount0Min/1Min` | not-zenji |
| 8 | Contango V2 | Arb | `0x6Cae…C24E` | `trade` (= delever/close) | **NO** — owner/approved, `Unauthorised` | underlying money market | caller `swapBytes`/`limitPrice` | not-zenji |
| 9 | Contango V2 | Base | `0x6Cae…C24E` | `trade` | **NO** — `Unauthorised` (behavioural) | money market | caller | not-zenji |
| 10 | Contango V2 | OP | `0x6Cae…C24E` | `trade` | **NO** — `Unauthorised` (behavioural) | money market | caller | not-zenji |
| 11 | Morpho MetaMorpho "Extrafi XLend WETH" | Base | `0x5A32…7a8C` | `allocate` / `reallocate` | **NO** — allocator-only | Morpho oracle | n/a | not-zenji |
| 12 | Morpho MetaMorpho "Extrafi XLend USDC" | Base | `0x2347…3B5e` | `allocate` / `reallocate` | **NO** — allocator-only | Morpho oracle | n/a | not-zenji |
| 13 | YieldFi yUSD / vyUSD | Base | `0x4772…8121` | (none exposed) | **NO** | off-chain basis | n/a | out-of-class |
| 14 | Gloop | Arb | `0x9BE2…33EB` | unresolved | not probed | oracle field in vault struct | unknown | sub-threshold ($26.4k) |
| 15 | **Beefy (CONTROL)** | Base | `0xDc97…65d0` (strategy) | `harvest()` | **YES — proven, returns 0x from 0x1111…** | **no debt, no LTV** | n/a | control |

**Live USD at risk behind a Zenji-shaped path: $0.**

The largest concentration is Extra Finance: **$8.21M TVL on Base + $0.50M on Optimism** (DefiLlama,
2026-11-10) — but every keeper entry point is switched off *and* whitelisted, and the product is in
wind-down (no funded vault allows borrowing).

---

## 2. The recipe and the three tests

From `ca3/README.md` §5.1, a Zenji sibling needs:

- **(a)** an unprivileged EOA can call the keeper/rebalance path;
- **(b)** the vault values its LP/strategy position **and** its LTV from a DEX/Curve/Velodrome pool
  that the same caller can trade (spot, not oracle/TWAP);
- **(c)** the vault computes its slippage floor (`minOut`) from **that same** manipulable pool, or
  applies none.

A *caller-supplied* `minOut` does **not** satisfy (c): in that case the caller is the party exposed to
slippage, which is the opposite of the Zenji failure (the victim vault under-protecting itself).

---

## 3. Extra Finance (ExtraFi) — the only real leveraged-farming vault system on these chains

### 3.1 Architecture (verified on-chain, not from docs)

Extra's leveraged vaults are **one contract family** controlled by a single
`VeloVaultPositionManager` (VPM). Three vault code generations are deployed (OP early ids
`0x957d5a09…` "IVeloVaultPositionManager"; OP later ids `0xc97e0e91…` "IVeloVaultV2"; Base
`0x92940449…` "IVeloVaultV2"), and **every sampled vault of every generation stores the same
`vaultPositionManager`** (`0xf9cFB8a6…7055`) and exposes `onlyVeloPositionManagerContract` on its
position-mutating functions. Vaults 2, 13, 41, 44, 128 (OP) and 2, 4, 53, 116 (Base) were hashed;
storage slot 8 is `vaultPositionManager = 0xf9cf…7055` on every one.

| Item | Value | Where |
|---|---|---|
| AddressRegistry | `0x85603119C938750Dfb5904f8a501b64F3F3A01D2` | OP + Base |
| VPM = `ADDRESS_ID_VAULT_POSITION_MANAGER` (7) | **`0xf9cFB8a62f50e10AdDE5Aa888B44cF01C5957055`** | `getAddress(7)` |
| LendingPool (9) | `0xBB505c54D71E9e599cB8435b4F0cEEc05fC71cbD` | OP + Base |
| VaultFactory (10) | `0x155620A2E6A9392c754B73296d9655061525729B` | OP + Base |
| Vault code hashes | OP `0x957d5a09…afa480` (early ids) / `0xc97e0e91…` (later ids); Base `0x92940449…` | `eth_getCode` |

> Note: the address labelled `positionViewer` in DefiLlama's adapter (`0xf9cfb8a6…`) **is** the
> VaultPositionManager — the same contract that executes liquidations and compounding.

The VPM's public dispatch table contains 38 selectors, including the three keeper switches and their
whitelists. Two of them are not in the public interface docs but are on chain:
`permissionLessRangeStopEnabled()` (`0x2fa51210`) and `rangeStopCallerWhitelist(address)` (`0x7249152c`).

### 3.2 The three keeper paths are all closed

Read at **OP block 159,337,708** and **Base block 55,418,325** (`evidence/l2_reads.json`):

| Switch | OP | Base |
|---|---|---|
| `permissionLessLiquidationEnabled()` | **false** | **false** |
| `permissionLessCompoundEnabled()` | **false** | **false** |
| `permissionLessRangeStopEnabled()` | **false** | **false** |
| `liquidatorWhitelist(0x1111…)` | false | false |
| `compounderWhitelist(0x1111…)` | false | false |
| `rangeStopCallerWhitelist(0x1111…)` | false | false |

Behavioural confirmation (`evidence/extra_permission_probes.json`, OP block 159,337,856 / Base block
55,420,602): every one of `liquidateVaultPositionPartially` (`0x7b032c6b`),
`closeOutOfRangePosition` (`0x507a6cc6`) and `investEarnedFeeToLiquidity` (`0x5c20f68c`) reverts with
`Error(string) "20"` — and so does the same call from the protocol owner. Error codes are from Extra's
own `Errors.sol`:

```
VL_LIQUIDATOR_NOT_IN_WHITELIST   = "20";
VL_COMPOUNDER_NOT_IN_WHITELIST   = "21";
```

So the revert is an explicit whitelist rejection, not a parameter error.

**Direct-to-vault bypass does not work either.** The vault-level mutators are
`onlyVeloPositionManagerContract`. A direct `claimRewardsAndReInvestToLiquidity(...)` call
(`0x76f7903a`) from `0x1111…` reverts `onlyVeloPositionManagerContract` on the newer vaults
(`0xBD58Fb45…`, `0xF65563C6…`, `0x01b10f92…` at OP block 159,338,098) and `vault paused` on the older
paused vault `0xbBEc5E45…`. Every vault generation routes position actions through the VPM.

### 3.3 Test-by-test

- **(a) Permissionless? No.** Three independent switches are false and every whitelist is empty.
- **(b) Pool-priced LTV? Partly, but irrelevant.** The vault struct carries `liquidateWithTWAP`.
  Of the 54 live OP vaults **34 are spot-priced** (`false`); of the 87 live Base vaults **75 are
  spot-priced**. So the *latent* valuation leg is often a manipulable Velodrome pool. Implementation
  is unverified; this is inferred from the on-chain flag plus the interface field
  `bool liquidateWithTWAP`.
- **(c) Vault-derived minOut? No.** The liquidation/close structs carry
  `minAmount0WhenRemoveLiquidity` / `minAmount1WhenRemoveLiquidity` and an arbitrary `swapPath` — all
  supplied by the caller. The vault never derives a floor from the pool.

### 3.4 Why the leverage surface is also decaying

| Metric | OP | Base |
|---|---:|---:|
| Vault ids in factory | 129 (124 readable; 109–113 uninitialized) | 122 |
| Live vaults (`totalLp > 0`) | 54 | 87 |
| Live vaults still carrying debt shares | 24 | 31 |
| Live vaults with `borrowEnabled = true` | **0** | **0** (one empty, paused vault, id 53) |
| Paused / frozen (live) | 15 / 44 | 2 / 87 |

Every funded Base vault (87/87) is `frozen` for new positions. No funded vault can open new leverage.
DefiLlama TVL for the product: **Base $8,214,591 / OP $499,435** (this includes the lending pool, not
only the leveraged vaults).

### 3.5 Verdict

**Not a Zenji sibling.** Latent risk worth monitoring: if the owner flips
`permissionLessLiquidationEnabled` **and** `permissionLessRangeStopEnabled`, the 34 OP / 75 Base
spot-priced vaults become exposed to a *forced-liquidation* attack (skew the pool → push a healthy
position under `liquidateDebtRatio` → liquidate). That is a **different** recipe from Zenji: the
liquidator supplies their own minOut, so the profit comes from the liquidation bonus
(`liquidateFeeRate` 5–8%), not from the vault's slippage floor. It is not counted here.

---

## 4. Contango V2 — position-level leverage, no on-chain liquidation, owner-only close

**Address (same proxy on all three chains):** `0x6Cae28b3D09D8f8Fc74ccD496AC986FC84C0C24E`
EIP-1967 implementations: Arb `0x555d00bbb3c8c4dadd698aed2e5cfdc1d37d7b29` (source verified),
Base `0x2475b89a193c2c4eced142134a8612d9a28890a7`, OP `0x76c48d0927dcceee555053acace51d102c6abfca`.
`paused() = false` on all three.

**Verified source (Arb, `evidence/contango_impl_source.json` → `contango/src_core_Contango.sol`):**

```solidity
// src/libraries/Validations.sol:11-13
function validateModifyPositionPermissions(PositionNFT positionNFT, PositionId positionId)
    view returns (address positionOwner) {
    positionOwner = positionNFT.positionOwner(positionId);
    if (positionOwner != msg.sender && !positionNFT.isApprovedForAll(positionOwner, msg.sender))
        revert Unauthorised(msg.sender);
}
```

`_close()` calls this on every close, and `tradeOnBehalfOf` additionally requires
`owner == onBehalfOf` (Contango.sol:108-109). **There is no `liquidate` function anywhere in the
Contango core** — the only external state-changers are `trade`, `tradeOnBehalfOf`, `multicall` and
admin functions. Liquidations are performed by the underlying money market (Aave / Morpho / Euler),
which prices collateral with its own oracle, not with a DEX pool Contango lets you trade.

**Behavioural proof** (live positions from Contango's public Goldsky subgraph):

| Chain | Position id | Block | `trade` from `0x1111…` |
|---|---|---|---|
| Arbitrum | `0x444149555344432e6e…005cfb` (DAI/USDC) | 522,842,578 | revert `0xae10e1de` = `Unauthorised(address)` |
| Base | `0x776545544857455448…0035b6` (WETH/USDC) | 55,420,602 | revert `0xae10e1de` |
| Optimism | `0x77737445544857455448…003ed3` (wstETH/WETH) | 159,337,856 | revert `0xae10e1de` |

`0xae10e1de` = `cast sig "Unauthorised(address)"` — confirmed locally.

**Verdict: not-zenji.** No permissionless path exists at all, and the swap is caller-supplied calldata
to a caller-chosen router. TVL (DefiLlama 2026-11-10): Arb $9.32M, Base $0.76M, OP $0.36M — all of it
behind an owner/approved gate.

---

## 5. Morpho/Aave-style looping, Silo/Euler wrappers, and the "absent" list

### 5.1 Morpho MetaMorpho (the only Morpho vaults branded as Extra)

| Vault | Assets at block 55,417,027 | USD @ ETH $2,126.16 / USDC $0.99973 |
|---|---:|---:|
| `0x5A32099837D89E3a794a44fb131CBbAD41f87a8C` "Extrafi XLend WETH" | 65.15732532492541 WETH | $138,534.70 |
| `0x23479229e52Ab6aaD312D0B03DF9F33B46753B5e` "Extrafi XLend USDC" | 433,208.022341 USDC | $433,092.67 |

`curator()` = `0x9E33faAE38ff641094fa68c65c2cE600b3410585`; `isAllocator(0x1111…) = false`;
`allocate((address,uint256,uint256)[],uint256)` (`0x47e0790f`) reverts from a random EOA (empty revert data on the
public RPC; selector present). Standard MetaMorpho's `allocate`/`reallocate` are `onlyAllocator`
(morpho-org/metamorpho), and allocation moves funds between
Morpho markets at **Morpho oracle** prices — no DEX swap, no LP valuation, no leverage at vault level.

### 5.2 YieldFi — out of class

`yUSD 0x4772D2e014F9fC3a820C444e3313968e9a5C8121` (113,882.87 USDC) and
`vyUSD 0xF4F447E6AFa04c9D11Ef0e2fC0d7f19C24Ee55de` (91,128.85 USDC) on Base at block 55,417,934.
`harvest()`, `rebalance()`, `keeper()` all revert — the only live surface is ERC-4626. Single-asset
delta-neutral basis strategy; no LP position, no LTV, no keeper.

### 5.3 Silo / Euler / the named examples

- **Silo V3** on Arbitrum carries **$488** (DefiLlama). Silo is an isolated lending market; it has no
  leveraged vault with a strategy rebalance.
- **Euler V2** (Base/Arb, $259M protocol-wide) is an EVK lending market: `borrow`/`repay`/`liquidate`
  against oracle-priced collateral. Liquidations are permissionless but use Euler's own oracle and
  go through the EVK's `liquidate`, not a DEX swap with a vault-derived minOut — different mechanism,
  excluded by test (b).
- **Hydra / Loop / Ouroboros / Curvance** are **not deployed on OP, Base or Arbitrum** per DefiLlama's
  chain lists (`Hydration` is Polkadot; `Loop` is Ethereum/XDC/BNB/Scroll; `Ouroboros Capital` is
  Monad/Ethereum; `Curvance` is Monad). `LoopFi` (Arb) is $165 and `TownSquare Loop Vaults` on Base is
  $0.20 — dust.
- **Gloop** (Arb, $26,427) is a GMX-GM index plus a GM lending pool. Its `vaults(bytes32)` struct
  carries an **oracle** address (DefiLlama adapter), so its valuation is oracle-based; not probed
  further because it is economically irrelevant and does not fit (b).

### 5.4 Structural note (why the L2 surface is thin)

A DefiLlama category sweep (2026-11-10) for `Leveraged Farming` on OP/Base/Arb returns **exactly one
protocol with meaningful TVL: Extra Finance** ($8.71M). Everything else on these chains is either a
lending market (Morpho/Euler/Silo/Aave), a curator/allocator vault (MetaMorpho, Lagoon, Veda, Upshift),
or an autocompounder (Beefy, Harvest, Pickle, Vesper). The Zenji primitive needs a *leveraged LP vault
with an on-chain keeper*, and that product barely exists on L2s — and where it does, it is switched off.
Note the exclusion is structural, not exhaustive: the large curator/allocator vaults (CIAN, Veda,
Lagoon, Upshift, Aera, Yearn, Spark) move single-sided assets between venues with no LP position and no
LTV, so they cannot satisfy (b) even if their keeper calls are permissionless. I did not audit each
allocator's keeper permissions because the valuation leg already fails.

---

## 6. Beefy — the control that proves the tests discriminate

| Item | Value |
|---|---|
| Moo vault | `0x005b8Aa7aB7bB665902d4E9509B9D4e9fB87BC2b` (`mooBeefyAerodromeBaseMSTRc-USDC`) |
| Strategy | `0xDc975A6fBC3BA63592C9d296a8cfeD92dEBE65d0` |
| `want()` | `0xd145b66F74B73a441ec15Eff80EeB653D8E45dFf` (Aerodrome MSTRc-USDC LP) |
| Holdings | only `want` LP (`balanceOfWant() = 0`, `balanceOfPool() = 2.94e9` raw units, 18 dp); no debt asset |
| `harvest()` from `0x1111…` | **succeeds, returns `0x`** (eth_call, Base block 55,416,937) |
| Debt / LTV | **none** — the strategy holds only `want`; there is no borrow, no debt asset, no liquidation |

**One line:** Beefy passes (a) — `harvest()` is permissionless — but fails (b)/(c) because an
autocompounder has no debt, no LTV and no liquidation, so a pool skew cannot reprice anything the
vault owes; the only thing at risk is the reward-swap output, which is fee-sized, is not vault
principal, and does not feed any LTV.

---

## 7. What would change the verdict (monitors)

1. **Extra Finance** — `enablePermissionLessLiquidation()` (`0x51e69245`) or
   `enablePermissonLessRangeStop()` (`0xc91bb1cd`) on the VPM, or a non-empty
   `liquidatorWhitelist`/`rangeStopCallerWhitelist`. Then re-check the 34 OP / 75 Base
   `liquidateWithTWAP = false` vaults (spot-priced) for a forced-liquidation path — still a *different*
   recipe, but the closest thing to a sibling on these chains.
2. **Extra Finance** — any vault flipping `borrowEnabled` back to true (would restore real LTV).
3. **Contango** — a new implementation that adds an on-chain liquidation function or relaxes
   `validateModifyPositionPermissions`. Current impls: Arb `0x555d00bb…`, Base `0x2475b89a…`,
   OP `0x76c48d09…` (EIP-1967 slot `0x3608…2bbc`).
4. **New deployments** — a leveraged LP vault on OP/Base/Arb with a `rebalance()`/`harvest()` that is
   *not* behind a whitelist. Nothing in the current DefiLlama `Leveraged Farming` set qualifies.

---

## 8. Method, and what limited it

**Read-only tooling actually used**

- `eth_call`, `eth_getCode`, `eth_getStorageAt`, `eth_getLogs`, `debug_traceCall` (callTracer) over
  keyless public RPCs (`mainnet.optimism.io`, `mainnet.base.org`, `arb1.arbitrum.io`,
  `*.drpc.org`). `debug_traceCall` was used to obtain revert data and internal call trees; no
  transaction was ever sent.
- `explorer.optimism.io` Blockscout v2 API (keyless) for OP logs and transaction lists — used to
  enumerate the 129 `NewVault` events and their vault addresses.
- Etherscan V2 `chainid=42161` for Contango's verified source and implementation ABI (full
  multi-file source saved to `evidence/contango_impl_source.json`).
- Extra Finance's published `IVeloVaultPositionManager` / `AddressRegistry` interfaces and `Errors.sol`
  from the public `rohallah12/ExtraFinance-LendingPool-Invariant-Testing` repository (`evidence/src/`),
  cross-checked against live selectors and storage.
- DefiLlama `api.llama.fi/protocols`, `/protocol/{slug}`, `coins.llama.fi/prices/current` for TVL and
  prices at 2026-11-10.

**Limits / honesty**

- Extra Finance's contracts are **unverified** on OP/Base Blockscout. Function identity for
  `investEarnedFeeToLiquidity` (`0x5c20f68c`) is inferred from the published tuple layout plus the
  dispatch table, not from source. The three *switches* and whitelists are read directly and are
  unambiguous.
- `liquidateWithTWAP` semantics are inferred from the field name and the interface; the
  implementation was not decompiled. This only affects the *latent* note in §3.5, not the verdict.
- Etherscan V2's free tier rejected `chainid=10` and `chainid=8453`
  ("Free API access is not supported for this chain"), and the Blockscout MCP server returned HTTP 402
  (credits exhausted). Base/OP source therefore came from the projects' public repositories and live
  selectors; every Base/OP claim above is backed by a direct `eth_call`/trace, not by source alone.
- Gloop was not reverse-engineered (sub-threshold). Its row is marked accordingly rather than guessed.
- No fork simulation was run (the brief forbids Foundry/forks for this lane). All conclusions rest on
  live reads, revert data and verified source. A fork PoC would only be needed if a candidate had
  passed (a)–(c); none did.

**Blocks used for citations**

| Chain | Block | Used for |
|---|---:|---|
| Optimism | 159,337,708 | VPM switches / whitelists |
| Optimism | 159,337,856 | permission probes; Contango `trade` probe |
| Optimism | ≤ 159,337,629 | 129-vault `getVault` enumeration stream (reads span ~159,336,9xx–159,337,6xx) |
| Base | 55,418,325 | VPM switches / whitelists |
| Base | 55,420,602 | permission probes |
| Base | 55,416,937 | Beefy `harvest()` (control) |
| Base | 55,417,027 | Morpho MetaMorpho reads |
| Base | 55,417,934 | YieldFi reads |
| Base | ≤ 55,418,325 | 122-vault `getVault` enumeration stream (ids 1–122) |
| Arbitrum | 522,842,578 | Contango `trade` probe; EIP-1967 impl slots |

---

## 9. Files

| File | Contents |
|---|---|
| `l2-candidates.json` | 15 machine-readable candidate rows (schema in the brief) |
| `evidence/l2_reads.json` | All cited reads with block numbers (Extra switches, Contango, Morpho, YieldFi, Beefy) |
| `evidence/extra_permission_probes.json` | Raw revert data for the three Extra keeper paths, from random EOA and owner |
| `evidence/extra_op_vaults.json` / `extra_base_vaults.json` | Full `getVault(id)` scan (129 OP ids, 122 Base ids) |
| `evidence/contango_impl_source.json` | Etherscan V2 verified source + ABI (Arbitrum implementation) |
| `evidence/contango_arb_source.json` | Proxy record (impl address) |
| `evidence/beefy_base_strategies.json` | Beefy vault→strategy mapping used for the control |
| `evidence/src/` | Extra interface sources used (`IVeloVaultPositionManager.sol`, `AddressRegistry.sol`, `Errors.sol`, `LendingPool.sol`) |
| `ev/` | The exact read-only scripts (`rpc.py`, `es.py`, `collect.py`, `probes_final.py`, `extra_vaults.py`, …) |

**Bottom line:** on Optimism, Base and Arbitrum, the Zenji primitive is **not live**. Extra Finance is
the only meaningful leveraged-farming vault system, its three keeper entry points are disabled and
whitelisted on both chains, its funded vaults cannot borrow, and its slippage floors are caller-supplied.
Contango's close path is owner-only. Morpho/YieldFi are oracle- or off-chain-valued. Beefy proves the
tests work: permissionless harvest, but no debt and no LTV. Live extractable via this recipe: **$0**.
