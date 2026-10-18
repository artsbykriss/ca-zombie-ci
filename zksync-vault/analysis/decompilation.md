# Decompilation / code-identity — SyncSwap Vault (V1)

## Result

The deployed EraVM runtime at `0x621425a1Ef6abE91058E9712575dcc4258F8d091` (zkSync Era) is
**byte-identical** to the published `SyncSwapVault.sol` compiled with the project's own toolchain.

| Item | Value |
|---|---|
| Runtime size | **30,944 bytes** (967 × 32) |
| Runtime sha256 | `92c3ce7b1e7f9b9259536dfb273c86ef1208a0dfaa893c928d07f5d92fb730a5` |
| zkSync bytecode hash | `010003c71e7f9b9259536dfb273c86ef1208a0dfaa893c928d07f5d92fb730a5` (version 1, 967 words) |
| Compiler | zksolc **1.3.5** (repo binary) + solc **0.8.15+commit.e14f2714** |
| Settings | optimizer **enabled**, runs **200**, standard-JSON path (same as hardhat-zksync-solc) |
| Source | `syncswap/core-contracts` commit `5285a3a7b2b00ca8b7ffc5ae5ce6f6c6195e4aa7`; vault files last changed 2023-03-16 |
| Recompiled runtime | 30,944 bytes, sha256 `92c3ce7b…730a5` — **0 differing bytes** |
| Creation tx | `0xecd787b7351ef02b52a6adcbfd015907b83e74c5e4e015510657084c3d84d82b`, block **9,764**, 2023-03-24, status success |
| Deployer | `0x000002c34bAE6DD7BeC72AcbA6aAAC1e01A359De` (EOA, nonce 13 at deploy) via ContractDeployer `0x…8006` |
| Constructor arg | `wETH = 0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91` |
| Proxy | none: `implementations: []`, EIP-1967 impl/admin/beacon slots = 0, no `delegatecall` in source |

> Note: Blockscout's address page reports the creation tx as `0x72316d49…`; that tx **failed**
> (status 0) and attempted a different bytecode hash. The correct deployment is the
> `ContractDeployed` event at block 9,764 (`0xecd787b7…`), whose indexed bytecode hash is the vault's.

## Dispatch table (completeness proof)

The runtime contains a sorted 25-slot selector table at bytes **28,576–29,343** (32-byte slots,
4-byte selector right-aligned). Entries: the 24 public functions in `selector-map.md` plus the
`0xffffffff` sentinel. The table offset is identical in the recompiled artifact. Every selector maps
to a function in the published source; no extra selector exists.

## Storage layout (verified live, block 72,542,827)

| Slot | Declaration | Live value |
|---|---|---|
| 0 | `ReentrancyGuard._status` | `1` (`_NOT_ENTERED`) |
| 1 | `Ownable._owner` (+ packed `Pausable._paused` = false) | `0x000002c34bAE6DD7BeC72AcbA6aAAC1e01A359De` |
| 2 | `VaultFlashLoans.flashLoanFeePercentage` | `500000000000000` (0.05%) |
| 3 | `VaultFlashLoans.flashLoanFeeRecipient` | `0x4444f80DfB8a8a29E79087f066eaC306784699Ce` |
| 4 | `balances` mapping (token → account → uint) | base; `balances[USDC][0x80115c70…]` = `2116219546435` = `balanceOf(USDC,pool)` |
| 5 | `reserves` mapping (token → uint) | base; `reserves[USDC]` = `2190557651671` = `reserves(USDC)` |

The two mapping reads reproduce the public getters exactly, confirming the deployed layout is the
published one (not a look-alike).

## Verification commands (reproducible in CI)

`ci/verify.py`:
1. `eth_getCode(vault)` → sha256 `92c3ce7b…` (pinned).
2. Build a standard-JSON input from the vendored 15-file import closure (`analysis/src/`).
3. Download solc 0.8.15 + zksolc 1.3.5 from public URLs, compile with `--standard-json`.
4. Compare the compiled `evm.bytecode.object` to `eth_getCode`; assert 0 differing bytes.
5. Assert the zkSync hash prefix `010003c7` = version 1 + 967 words + `sha256[8:]`.

CI output: `ci-out/compile.json` (byte_identical: true).
