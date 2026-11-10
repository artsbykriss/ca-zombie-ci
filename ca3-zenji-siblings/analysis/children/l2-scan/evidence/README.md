# Evidence index — L2 lane (Extra / Contango / Morpho / Beefy)

All files here are raw, read-only outputs. No keys, no keyed URLs, no transactions.

| File | How it was produced | What it proves |
|---|---|---|
| `l2_reads.json` | `ev/collect.py` — `eth_call`/`eth_getStorageAt` at `latest`, with the block number recorded per chain | Extra VPM switches + whitelists on OP and Base; Contango `paused`/`positionNFT`/impl slot; Beefy `strategy`/`want`/`balanceOfPool` + `harvest()` from a random EOA; Morpho `curator`/`isAllocator`/`totalAssets`; YieldFi `totalAssets` + absent keeper functions |
| `extra_permission_probes.json` | `ev/probes_final.py` — `eth_call` with `from` = `0x1111…1111` and `from` = protocol owner | `liquidateVaultPositionPartially`, `closeOutOfRangePosition`, `investEarnedFeeToLiquidity` all revert `Error(string) "20"` on both chains, for both callers; includes raw revert data and block numbers |
| `extra_op_vaults.json` | `ev/extra_vaults.py` — `getVault(i)` for i=1..129 on OP | 124 readable ids, 54 with `totalLp > 0`, per-vault `liquidateWithTWAP`, `liquidateDebtRatio`, `borrowEnabled`, fees, LP |
| `extra_base_vaults.json` | `ev/extra_vaults_base.py` — `getVault(i)` for i=1..139 on Base | 122 readable ids, 87 with `totalLp > 0`, same fields |
| `contango_impl_source.json` | Etherscan V2, `chainid=42161`, `module=contract&action=getsourcecode`, impl `0x555d00bb…` | Full multi-file verified Contango source + ABI (contains `Validations.sol`, `Contango.sol`, `PositionNFT.sol`) |
| `contango_arb_source.json` | Etherscan V2 proxy record | Proxy → implementation mapping |
| `beefy_base_strategies.json` | `ev/beefy.py` | Beefy vault→strategy candidates used for the control |
| `src/IVeloVaultPositionManager.sol`, `src/AddressRegistry.sol`, `src/Errors.sol`, `src/LendingPool.sol` | public GitHub repo `rohallah12/ExtraFinance-LendingPool-Invariant-Testing` | Interface/tuple layouts and the error-code table (`"20"` = `VL_LIQUIDATOR_NOT_IN_WHITELIST`, `"21"` = `VL_COMPOUNDER_NOT_IN_WHITELIST`) used to decode the live reverts |

## Exact reproduction (read-only)

```bash
# Extra VPM switches (OP shown; same on Base)
cast call 0xf9cFB8a62f50e10AdDE5Aa888B44cF01C5957055 "permissionLessLiquidationEnabled()(bool)" \
  --rpc-url https://mainnet.optimism.io
cast call 0xf9cFB8a62f50e10AdDE5Aa888B44cF01C5957055 "permissionLessRangeStopEnabled()(bool)" \
  --rpc-url https://mainnet.optimism.io

# Extra liquidation probe (reverts with string "20")
cast call 0xf9cFB8a62f50e10AdDE5Aa888B44cF01C5957055 \
  "liquidateVaultPositionPartially((uint256,uint256,uint16,address,bool,uint8,uint256,uint256,uint256,uint256,uint256,uint256,bytes))" \
  "(41,1,100,0x1111111111111111111111111111111111111111,false,2,0,0,99999999999,0,0,0,0x)" \
  --from 0x1111111111111111111111111111111111111111 --rpc-url https://mainnet.optimism.io

# Beefy control: permissionless harvest succeeds
cast call 0xDc975A6fBC3BA63592C9d296a8cfeD92dEBE65d0 "harvest()" \
  --from 0x1111111111111111111111111111111111111111 --rpc-url https://mainnet.base.org
```

`debug_traceCall` (callTracer) was used through keyless `https://optimism.drpc.org`,
`https://base.drpc.org`, `https://arbitrum.drpc.org` to capture revert data where the plain
`eth_call` response dropped it.
