# Prosper Alpha — evidence notes (Pharos 1672)

All reads keyless via `https://rpc.pharos.xyz`. Pinned state block **21240221** (2026-10-25).

## 1. What pass-7 left open, and how it was closed

pass7/fresh-deep.md §3.12: *"the market impl 0xb057…D672 (14.8 KB) did not decompile"* — a **tooling** failure.
Closed here: `heimdall decompile 0xb05749a8Cc5Dd1205Bc36326Cf94A2cA83f7D672 --rpc-url https://rpc.pharos.xyz --include-sol -o print`
→ `market_impl_decompiled.sol` (29-fn ABI + Solidity) and `market_impl_yul.txt` (`--include-yul`). heimdall v0.9.2 works; lutetia does not.

## 2. Full contract set decompiled

| file | contract |
|---|---|
| `factory_impl.sol` | ProsperFactoryUpgradeable (UUPS) |
| `market_impl_decompiled.sol`, `market_impl_yul.txt` | BondingCurveMarketUpgradeable (beacon impl) |
| `buyback_impl.sol` | BuybackUpgradeable (beacon impl) |
| `accessController_yul.txt` | ProsperAccessControllerUpgradeable (UUPS, 9,927 B) |
| `globalConfig_impl.sol` | ProsperGlobalConfigUpgradeable (UUPS) |
| `migrationEscrow_impl.sol`, `migrationEscrow_yul.txt` | MigrationEscrowUpgradeable (UUPS) |
| `ptokenClaim_impl.sol`, `ptokenClaim_yul.txt` | PTokenClaimUpgradeable (UUPS) |
| `feeFallback_impl.sol`, `feeFallback_yul.txt` | FeeFallbackDistributorUpgradeable (UUPS) |
| `tradeRouter_impl.sol` | ProsperTradeRouterUpgradeable (UUPS) |
| `depositRouter_impl.sol` | ProsperDepositRouterUpgradeable (UUPS) |
| `lptimelock.sol` | LpTimeLock (plain) |

## 3. Role / module constants (computed)

```
MODULE_INNER_TRADING  0x7278436687db4d6a9d96e663f29f4a7562c14264ad01e44e6ae0d615d855f0a4   (market buy/sell pause)
MODULE_VAULT_CREATION 0xab232b2ca4f599c5abfb5a2844aea5b86f076588db4588a26d1e6ad71dce95ed   (factory create)
MODULE_MIGRATION      0x187c1b08a13e3aad12049e9586ff23f36919747ee528e3872a0410d2ece22ee9   (escrow)
MODULE_BUYBACK        0xfe9eba393561cd966ef1406ff517925f744350c4cc85154ab4667aaf90c2c723   (buyback)
claim module          0x05ae97465e6d70a8b81c5ca0fc9af2f681a256bb499d6fd4580d51801679e1bd   (ptokenClaim + feeFallback)
upgradeMarketImpl role 0xb7db2dd08fcb62d0c9e08c51941cae53c267786a0b75803fb7960902fc8ef97d
CREATOR_ROLE          0x8aeda25a  FEE_OPERATOR_ROLE 0x50010f4e  MIGRATOR_ROLE 0x6fae2e15
ROOT_SETTER_ROLE      0xc97180c5  OWNER_ROLE 0xe58378bb  DEFAULT_ADMIN_ROLE 0xa217fddf
```

## 4. Selector map (market impl 0xb057…)

```
0x4beb394c quoteBuy(uint256)            -> (usedGross, fee, netAmountIn, pTokenOut)
0xa64190c4 quoteSell(uint256)           -> (grossOut, fee, netOut)
0x383f5607 buy        (native in)        gate: nonReentrant + !modulePaused(MODULE_INNER_TRADING)
0x1c31c595 / 0x4e6243fe / 0xf5271f57 sell paths (router sellInner / sellInnerWithPermit)
0x8900fc63 setExternalPair/completeMig  gate: msg.sender == migrationEscrow
0xa7519ca6 releaseReserve (WPROS out)   gate: msg.sender == migrationEscrow
0x64470615 reserve/migration helper     gate: msg.sender == migrationEscrow
0x9ff1103f refreshPhase()               permissionless; returns Phase; moves no value
0x1c5eac33 externalPair()  0x58a06f07 pToken()  0x19b80ee7 curveK()  0xb1c9fe6e phase()
0x54e9d781 migrationEscrow()  0xeb6d3a11 wrappedNative()  0xbc43cbaf accessController()
0xa7c1abe0 globalConfig()  0x0172d417 realReserve  0x36010120 / 0x4bc55300 curve state
```

## 5. Curve identity

`curveK = 7588465646137415450338065843360626557493770024920 = x0 * y0`,
`x0 = initialVirtualNativeReserve = 7547169811320754716981` (≈7547.17 WPROS),
`y0 = initialVirtualTokenReserve = 1005471698113207547169811320` (≈1.00547e27 pToken).
Constant-product; `tradingFeeBps = 100`. `targetRaiseNative = 2e22` (20,000 WPROS).

Measured round-trips on live market pPika `0x39630b3c…` (quoteBuy → quoteSell):

```
in 1e12  pOut 98708918108208381        netBack 980099999778        -1.9900%
in 1e15  pOut 98708906917936511606     netBack 980099777556821     -1.9900%
in 1e17  pOut 9870779798465962488785   netBack 98007775618188144   -1.9922%
in 1e18  pOut 98697717915792394609167  netBack 979877607244562775  -2.0122%
in 1e19  pOut 985970303433556275880486 netBack 9778806048368649808 -2.2119%
```

## 6. Live totals (block 21240221, WPROS price $0.6279)

```
phase 0 (ActiveInner)      15 markets   16,567.19 WPROS
phase 3 (FailedInnerOnly)  14 markets    5,063.29 WPROS
phase 2 (OuterActive)      10 markets   WPROS side of V2 pools, LP in LpTimeLock = 807,226.03 WPROS
TOTAL                                 828,856.51 WPROS = $520,421   (DefiLlama: $517,577)
```

## 7. Access control (all reverted in the fork PoC)

* `MigrationEscrow.migrateToExternal` (0x5b905883) — `MIGRATOR_ROLE` (0x6fae2e15) + `!modulePaused(MODULE_MIGRATION)`
* `MigrationEscrow.finalizeFailure` (0x108ffd37) — **permissionless** (audit §2.2.5) but only burns reserved pTokens + reward pool; no value out
* `Buyback.fund`/`withdrawUsdc`/`0x7b1a3baf` — `FEE_OPERATOR_ROLE` + `!modulePaused(MODULE_BUYBACK)`
* `LpTimeLock.claim` — `msg.sender == owner == AccessController proxy`
* `LpTimeLock.register` — `msg.sender == migrationEscrow`
* `Factory`/`AccessController`/`GlobalConfig` `upgradeToAndCall` — UUPS owner
* `AccessController.upgradeMarketImplementation` (0x7ba73267) — role 0xb7db2dd0…
* `AccessController.defaultAdmin()` = `0x760caE380fDfbce6D810E6874F666234dFA0558A` (EOA)

## 8. Merkle claims bind the allocation

Both `PTokenClaimUpgradeable.claim` and `FeeFallbackDistributorUpgradeable.claim`
(selector `0xfabed412`) build the leaf preimage as **7 words**:
`chainid, address(this), campaign.slot0, r25Vault, campaign.slot1, account, totalAllocation`
(read from `ptokenClaim_yul.txt` / `feeFallback_yul.txt`). `totalAllocation` is part of the leaf ⇒
allocations cannot be inflated; empty/forged proofs revert.

## 9. Tooling notes

* `eth_getLogs` on `rpc.pharos.xyz` caps ranges at 1000 blocks ("block range is too large").
* `debug_traceTransaction` supports `{"tracer":"callTracer"}` and `{"tracer":"prestateTracer"}`; the struct-log tracer is rejected.
* No verified source on Pharos: `pharosscan.xyz` is a Next.js app without `/api/v2`; Etherscan V2 "unsupported chainid"; Sourcify v2 `/v2/contract/1672/<addr>` → `match:null`; Blockscout 404.
* A working third-party reference exists: the BlockSec audit PDF (`blocksec_prosper_audit.pdf`) with the real source of factory/escrow/router/claim/buyback.
