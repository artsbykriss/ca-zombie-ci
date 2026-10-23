# ApeX Omni custody — deployed code & access-control audit

All addresses/state read live 2026-10-23 (keyless public RPCs). Block numbers in
`live-state-2026-10-23.json`.

## What the custody actually is

DefiLlama's `apex-omni` TVL comes from the `registries/sumTokens.js` entry `"apex-omni"`,
which sums a fixed token list held by **one owner address per chain**. Those owner addresses are
the zkLink contracts that ApeX Omni deploys on each L1 ("the zkLink contract deployed by ApeX Omni
on your respective chain" — ApeX force-withdrawal docs). ApeX Omni runs on **zkLink X**
(application-specific zk-rollup), order matching off-chain, settlement/proofs on-chain.

| L1 | custody proxy (zkLink) | zkLink chainId | impl (`getTarget()`) | periphery (delegatecall target) |
|---|---|---|---|---|
| Ethereum | `0x35D173cdfE4d484BC5985fDa55FABad5892c7B82` | 4 | `0xa9b4ab2e78f93b340bbd6541b713b29b6b3bee3c` (`ZkLink`) | `0x070fc04f6ce2cd1ffbc2ae1d6a381e46f467284f` (`ZkLinkPeriphery`) |
| BNB Chain | `0xb8d9f005654b7b127b34dae8f973ba729ca3a2d9` | 3 | `0x3ec0ad3000b13188c235e23d549f1a1bbd25b028` (`ZkLink`) | `0x04bf7cf48a68dfc744fc22662b90e2ecaf14d716` |
| Arbitrum | `0x3169844a120c0f517b4eb4a750c08d8518c8466a` | 9 (master) | `0x23871561330080828507ded34d23fef5ede7053c` (`ZkLink`) | `0x3203e813930bd710043c1d899fe38dd359307352` |
| Base | `0xee7981c4642de8d19aed11da3bac59277dfd59d7` | 11 | `0xd923b6479006623303f180fa149a3b5c3bf5ff66` (`ZkLink`) | `0x502c848e6f88cd018153712a68ee518c7f34af12` |
| Mantle | `0x3c7c0ebfcd5786ef48df5ed127cddeb806db976c` | 12 | `0x067c7126a83560ed2fc345d25799f696b7ea47ca` (`ZkLink`) | `0xf04af2e7abcd011459a01a4a250ece46969c84f2` |

Proxy pattern = Matter Labs `Proxy` (`getMaster`/`getTarget`/`upgradeTarget`/`transferMastership`);
`initialize(bytes)` is intercepted and reverts `ini11`. The **master** of every proxy is an
`UpgradeGatekeeper` contract (2,925 B). `networkGovernor` is a `GnosisSafeProxy` (172 B,
threshold **4** on Ethereum). Arbitrum is the **master chain** (`totalBlocksProven ==
totalBlocksExecuted == totalBlocksSynchronized == 211,104`); the others are slaver chains that
receive sync hashes via a governor-set SyncService.

Two deployed code versions exist:
* **ETH/BSC/Base/Mantle (slaver, "compressed")**: `commitCompressedBlocks` / `executeCompressedBlocks`
  — both `onlyValidator`; withdrawal processing is inside `executeCompressedBlocks`.
* **Arbitrum (master)**: `commitBlocks` / `executeBlocks` — both `onlyValidator`;
  `proveBlocks` is **permissionless** but is bound to `verifier.verifyAggregatedBlockProof(...)`
  (a SNARK check), and executing a proven block still requires a validator.

## External surface — every value-moving entry point and its gate

| Function | Where | Gate | Attacker profit? |
|---|---|---|---|
| `depositETH` / `depositERC20` | ZkLink | none (pulls from msg.sender) | no (funds in) |
| `commitCompressedBlocks` / `commitBlocks` | ZkLink | `onlyValidator` (`require(validators[msg.sender],"4")`) | no |
| `executeCompressedBlocks` / `executeBlocks` | ZkLink | `onlyValidator` | no |
| `proveBlocks` | Periphery (Arbitrum only) | none, but requires valid SNARK proof | no |
| `revertBlocks` | Periphery | `onlyValidator` | no |
| `receiveBlockConfirmation` / `receiveSyncHash` | Periphery | `onlySyncService` | no |
| `changeGovernor` / `addToken` / `setTokenPaused` / `setValidator` / `setSyncService` / `setGateway` | Periphery | `onlyGovernor` | no |
| `withdrawPendingBalance(_owner,tokenId,amount)` | Periphery | none — but pays `_owner`, debits `pendingBalances[_owner]` | no (cannot redirect) |
| `withdrawPendingBalanceWithCall(...)` | Periphery | none — hash-bound to an L2-registered withdrawal (`pendingWithdrawWithCalls`) | no |
| `withdrawToL1(...)` | Periphery | none — requires `pendingL1Withdraws[hash]` set by L2 | no |
| `acceptETH` / `acceptERC20` | ZkLink (Acceptor) | none — acceptor must pay the receiver first | no (pays out first) |
| `setAuthPubkeyHash` | Periphery | none — writes msg.sender's own auth fact | no |
| `activateExodusMode` | Periphery | none — only flips when a priority request is >14d expired | no |
| `cancelOutstandingDepositsForExodusMode` / `performExodus` | Periphery | exodus-mode only; credit `op.owner` / merkle-proof verified | no |
| `upgradeTarget` / `transferMastership` | Proxy | `requireMaster` (UpgradeGatekeeper) | P (privileged) |
| `upgrade` flow | UpgradeGatekeeper | `requireMaster` (networkGovernor Safe) | P (privileged) |

## Privileged / centralization risk (P, not E-U)

* `UPGRADE_NOTICE_PERIOD == 0` on all five chains (`getNoticePeriod()` = 0). The UpgradeGatekeeper
  therefore allows `startUpgrade` → (0 s) → `finishUpgrade` → `proxy.upgradeTarget` in a single
  transaction, driven by the networkGovernor Safe (threshold 4). A compromised/malicious Safe can
  replace the implementation and move the whole ~$30.28M. This is the L2BEAT "CRITICAL" upgrade
  risk (L2BEAT text says EOA; on-chain the governor is a Gnosis Safe, threshold 4).
* Validators are governor-set; a validator can commit blocks but still needs a valid proof on the
  master chain, and execution is validator-gated too.

## Negative results (dead ends, with evidence)

* Non-validator `executeCompressedBlocks` / `commitCompressedBlocks` → revert `"4"`.
* Non-master `upgradeTarget` / `transferMastership` → revert `"1c"`.
* `initialize(bytes)` on the proxy → revert `"ini11"` (cannot re-initialize).
* Non-governor `changeGovernor` / `setValidator` / `setGateway` / `addToken` → revert `"3"`.
* `withdrawPendingBalance(attacker, tokenId=140(USDC), 1)` with zero pending balance → arithmetic
  underflow revert (Panic 0x11). No way to mint a pending balance without an L2 settlement.
* `withdrawPendingBalance(victim, tokenId, amount)` succeeds but sends funds to **victim**; the
  caller's balance is unchanged → forced-withdrawal griefing only, no theft.
* `acceptERC20` without first transferring tokens → `safeTransferFrom` revert.
* `activateExodusMode` called by an attacker does **not** enter exodus mode (oldest priority
  request not expired) — `exodusMode` stays false.

See `../poc/test/ApexOmniZkLink.t.sol` (14/14 PASS on an Ethereum fork).
