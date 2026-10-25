# Prodigy.Fi V2 (Base) — analysis notes

Read-only. All reads at Base block **53,044,841** (or stated otherwise). Keyless endpoints only.

## 1. What the target is

`PositionManager 0x50aB3FE7d089c4F0dD8096aAeA9578f8E7B18AF7` is a **verified-as-proxy**
(Etherscan flags `Proxy=1`) contract on Base; the *implementation*
`0xb1522e3514adfa6cbacd6675378fce03e1b97dd8` is **unverified** (~14.6 KB).

It is **not** a zombie: it is the factory of **Prodigy.Fi V2**, a live, audited
(2 audits: Halborn 2024-10-30 + a 2025-12-09 collaborative report, both at
`github.com/prodigyfi/audits`), multi-chain **options vault** protocol tracked by
DefiLlama (`prodigy-fi-v2`, category *Options*).

- DefiLlama TVL (2026-10-24): protocol **$67,961.68**; **Base $18,807.42**;
  Ethereum $44,912.86; Hyperliquid $3,231.73; Berachain $1,009.68.
- The same `PositionManager` address exists on Ethereum/Base/Hyperliquid/Berachain
  (DefiLlama adapter `projects/prodigy-fi-v2/index.js`), with the same owner EOA.

## 2. Decompilation

Tools: `heimdall decompile --include-sol`, `evmole.contract_info`, `heimdall disassemble`,
`openchain.xyz` selector DB. Raw artefacts in this folder (`*.heimdall-decompiled.sol`,
`*.asm-disassembled.asm`, `*_selectors.json`).

### PositionManager impl `0xb1522e35…` — 48 selectors
Resolved names (openchain + heimdall ABI):
`owner()`, `proxiableUUID()`, `UPGRADE_INTERFACE_VERSION()`, `upgradeToAndCall(address,bytes)`,
`initialize(address)`, `initializeUpgrade()`, `pause()`, `unpause()`, `paused()`,
`transferOwnership(address)`, `setCollateralPool(address)`, `setCollateralPoolV2(address)`,
`setVaultImplementation(address,uint8)`, `changeFeeReceiver(address)`,
`setMinDepositAmount(address,uint256)`, `changeDepositDeadlineOffset(uint256)`, `setWETH(address)`,
`collateralPool()`, `weth()`, `vaultImplementation()`, `getDeployedVaultCount()`,
`getDeployedVaults(uint256,uint256)`, `deployedVaults(uint256)`, `depositDeadlineOffset()`,
`minDepositAmount(address)`, `factoryVersion()`, `vaultVersion()`, `0x03ce4248` (returns the
current V2 vault implementation `0x42c3fc87…`), plus 10 unresolved view selectors and 10
unresolved non-view selectors (vault-deploy / settlement entrypoints).

### Collateral pool `0xe1303B25…` (impl `0x50c0be4490fa490e01029fdfb03df206189f0d3f`, unverified) — 29 selectors
`deposit(address,uint256)`, `withdraw(address,uint256)`, `processUserDeposit(address,uint256)`,
`registerVault(address,address)`, `approveVault(address,bool)`, `setWhitelistedToken(address,bool)`,
`setWhitelistedLP(address,bool)`, `setFactory(address)`, `owner()`, `transferOwnership(address)`,
`upgradeToAndCall(address,bytes)`, `initialize(address)`, plus vault-registry views and
`0x1749aa26(address,uint256)`, `0xd5735e7d(address)`, `0xa4bc9c2d(bool)`.

The other pool `0x864cd493…` (impl `0x863af80b…`, v1) holds **0**.

### Vaults
1714 vaults, all **EIP-1167 minimal clones** (45-byte code
`0x363d3d373d3d3d363d73<impl>5af43d82803e903d91602b57fd5bf3`). Three implementations in use:
- `0x72615c2175f8b838139f9c43830d16372b2a6177` (v1, 14961 B)
- `0xBeD271eA97905eD771e291a9D2924c06c4eb0987` (v2a, 12664 B) — current `vaultImplementation()`
- `0x42c3fc87e3b65bc75b94c4177af376cf231518a2` (v2b, 11648 B) — returned by `0x03ce4248`, used by the newest vaults

Vault interface: `investmentToken()`, `linkedToken()`, `collateralPool()`, `aggregator()`,
`priceFeed()`, `expiry()`, `depositDeadline()`, `withdrawalUnlockTime()`, `quantity()`, `state()`,
`isInitialized()`, `lpWithdrawn()`, `depositTotal()`, `balances(address)`, `vaultCreator()`,
`feeReceiver()`, `minDepositAmount()`, `minConfidenceRatio()`, `tradingFeeRate()`, `owner()`,
`version()`, `deposit(address,uint256,uint256,bytes[])`, and V2 extras
`signer()`, `setSigner(address)`, `signatureRequired()`, `setSignatureRequired(bool)`,
`consumeNonce(address,uint256)`, `deposited(bytes32)`.

## 3. Live-state facts

| Fact | Value |
|---|---|
| EIP-1967 impl slot of PM | `0xb1522e3514adfa6cbacd6675378fce03e1b97dd8` |
| EIP-1967 **admin** slot of PM | `0x0` (no transparent-proxy admin) |
| `owner()` of PM / pool / vaults | `0xB17A226B38A576738C1ad5E6ACC273a1A3A99A9F` (**EOA**, nonce 234, 0.0297 ETH) |
| `getDeployedVaultCount()` | 1714 (Base) |
| Vaults with `collateralPool()` | 1714/1714 → `0xe1303B2514755A72da4AcA9B917d96F16c842c80` |
| Vaults holding tokens/native directly | **0** |
| Vaults `isInitialized()` | 1714/1714 |
| Vaults with `depositTotal > 0` | 16 |
| Pool 0xe1303B25 balances | 4,147.915743 USDC + 4.065428875384615385 WETH + 0.06555499 cbBTC |
| Pool 0xe1303B25 USD | ≈ **$18,927** (DefiLlama Base TVL $18,807.42) |
| Pool 0x864cd493 balances | 0 |
| PM native balance | 0 |

Prices (DefiLlama, 2026-10-24): WETH $2,340.38, USDC $0.99953, cbBTC $80,342.43.

## 4. Auth probe (fresh EOA `0x…dEaD`), `eth_call` at 53,044,841

Full results: `probe_results.json`. Summary — **every value-moving selector reverts**, except
two provably inert no-ops:

| Selector | Target | Result |
|---|---|---|
| `withdraw(address,uint256)` 0xf3fef3a3 | pool | revert `CollateralPoolV2: insufficient withdrawable balance` → **msg.sender-keyed** (H-O) |
| `processUserDeposit(address,uint256)` 0x1ea734b6 | pool | revert `CollateralPoolV2: not registered vault` |
| `d5735e7d(address)` | pool | revert `CollateralPoolV2: not registered vault` |
| `registerVault(address,address)` 0x05c4fdf9 | pool | revert `CollateralPool: Caller is not factory` |
| `approveVault(address,bool)` 0x3e99414e | pool | revert `CollateralPoolV2: approve with not vault owner` |
| `setFactory` / `setWhitelistedToken` / `setWhitelistedLP` / `transferOwnership` / `upgradeToAndCall` / `initialize` | pool | revert (onlyOwner / already-init) |
| `0x1749aa26(address,uint256)` | pool | **succeeds but early-returns** (reads `mapping[msg.sender]`, `if 0 → STOP`); moves nothing |
| `0x715018a6` | pool + PM | **succeeds but body is `STOP`** (disabled renounceOwnership stub); owner unchanged, no transfer |
| `deposit(...)` 0x781229fc | vault v1 | revert `Vault: deposit period has ended` |
| `deposit(...)` 0x781229fc | vault v2 | revert `VaultV2: Signature required for deposit` |
| `8caad7b5(uint256)`, `65de4b2a(uint64)` | vault | revert `Vault: not creator` |
| `eaa46ccf()`, `08031eba()`, `b392c530(uint256)`, `upgradeToAndCall`, `initialize` | vault | revert (owner/creator-gated) |
| all 22 PM admin/deploy selectors tested | PM | revert (onlyOwner / already-init) |

## 5. Why it is closed (E-U)

1. **All collateral is in one escrow contract** (`0xe1303B25`), and that contract's only
   outbound transfer, `withdraw(token,amount)`, is indexed by `msg.sender` — a stranger's
   balance is 0, so it reverts. Every other outbound path requires `msg.sender` to be a
   factory-registered vault or the owner.
2. **Vaults are 1167 clones** that hold nothing; the only way they move pool funds is
   `processUserDeposit`/`d5735e7d`, both `msg.sender == registered vault` gated.
3. **Deposits** are gated by a deposit window (`block.timestamp <= depositDeadline`) and, on V2,
   by an off-chain EIP-712 signature (`VaultV2: Signature required for deposit`).
4. **Upgradeability is UUPS** with `owner == 0xB17A226B…` (single EOA). That is a *privileged*
   (P) risk — a key compromise drains the protocol — **not** an external-unprivileged path.
5. Two selectors that *appear* callable (`0x715018a6`, `0x1749aa26`) are provably inert:
   disassembly shows a bare `STOP` body and an early-return on a zero mapping read.

## 6. Files

- `impl.hex`, `proxy.hex`, `vaultimpl*.hex`, `collpool*_impl.hex` — raw bytecode
- `selectors.json`, `vault_selectors.json`, `vault_v2_selectors.json`, `collpool2_selectors.json` — evmole
- `openchain.json`, `vault_openchain.json` — selector→signature
- `impl.heimdall-decompiled.sol`, `vaultimpl.heimdall-decompiled.sol`,
  `collpool2.heimdall-decompiled.sol`, `collpool.heimdall-decompiled.sol`
- `*.asm-disassembled.asm` — heimdall disassembly (used to prove the no-op stubs)
- `vaults.json` — all 1714 vaults with pool/token/state (keyless enumeration)
- `probe_auth.py`, `probe_results.json` — fresh-EOA auth probe
- `enumerate_vaults.py` — keyless vault enumerator
- `live_state.json` — pinned-block snapshot (also emitted by `ci/run.sh`)
