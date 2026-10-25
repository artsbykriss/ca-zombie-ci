# Hive Protocol (BSquared 223) — live-state evidence

Read-only. All reads via keyless `https://rpc.bsquared.network` (chainId 223 / 0xdf).
Reference block **39,897,334** unless stated. No transaction signed or sent.

## 1. Address map (verified on-chain)

| Role | Address | Code bytes | Native BTC | USD @ $80,499.98 |
|---|---|---|---|---|
| Staking proxy (Solady ERC-1967) | `0xd5B5f1CA0fa5636ac54b0a0007BA374A1513346e` | 170 | **2,918.949047718480553371** | $234,975,340.22 |
| └ impl (UUPS) | `0x41b3C11d65bA8B625d0116E6f512C5e605f946f7` | 23,572 | 0 | — |
| Vault proxy | `0xe677F4B6104726D76DeBc681d7a862CE269aA8F3` | 170 | **418.289511807089039265** | $33,672,297.37 |
| └ impl (UUPS) | `0x59b1cDe6D056d8B8E36Ac6055a9d46d071a6C036` | 6,293 | 0 | — |
| B2-staking proxy | `0x796e4D53067FF374B89b2Ac101ce0c1f72ccaAc2` | 224 | **139.474180565218215250** | $11,227,668.76 |
| └ impl (UUPS, Ownable) | `0x0619E2276F1eb22205544d0F315533f5E3EeaBdb` | 19,873 | 0 | — |
| Strategy manager proxy | `0xcf38C660e0E99BED4c4aC8817922A0a3A996700B` | 169 | 0 | — |
| └ impl (UUPS) | `0x7b40779fb681054df2b2F29b527CEB5eeca9d3fd` | 9,067 | 0 | — |
| B2 reward token | `0x783c3f003f172c6Ac5AC700218a357d2D66Ee2a2` | 10,457 | 0 (holds 120,035.29 B2 = $50,410) | — |
| Aux proxy 1 | `0xA3eb53ddA8181Ae48FDfE16Ed3d7F37859F7f97b` | 224 | 0 | — |
| Aux proxy 2 | `0x8208bd314b6d730845E0F1427bC5a150EdE9baE7` | 224 | 0 | — |
| **Total custodied native BTC** | | | **3,476.712740090787807886** | **$279,875,306.35** |

ERC-1967 impl slots read at block 39,897,334:
- `0xd5B5…46e` slot `0x3608…2bbc` = `0x41b3C11d65bA8B625d0116E6f512C5e605f946f7`; admin slot `0xb531…6103` = 0 (Solady proxy, no admin slot).
- `0xe677…a8F3` slot `0x3608…2bbc` = `0x59b1cDe6D056d8B8E36Ac6055a9d46d071a6C036`.
- `0xcf38…700B` slot `0x3608…2bbc` = `0x7b40779fb681054df2b2F29b527CEB5eeca9d3fd`.
- `0x796e…cAc2` slot `0x3608…2bbc` = `0x0619E2276F1eb22205544d0F315533f5E3EeaBdb`.

## 2. Storage (staking proxy 0xd5B5…46e)

| Slot | Value | Meaning |
|---|---|---|
| 0 | `0xbc994` = 772,500 | `startBlock()` |
| 1 | `0x7763994` = 125,188,500 | `endBlock()` |
| 2 | `0x04af0a763bb1c000` = 3.375e17 | `b2PerBlock()` |
| 3 | `…783c3f003f172c6ac5ac700218a357d2d66ee2a2` | `B2()` = `0x783c…e2a2` |
| 4 | 10,000 | `totalPoolWeight()` |
| 5 | 5 | `poolLength()` |
| 7 | `0xe677f4b6104726d76debc681d7a862ce269aa8f3` | `vault()` |
| 8 | `0xcf38c660e0e99bed4c4ac8817922a0a3a996700b` | strategy manager |
| 11 | `0xa3eb53dda8181ae48fdfe16ed3d7f37859f7f97b` | aux proxy 1 |
| 12 | 39,482,000 | `rewardBlockNumber()` |
| 13 | `0x796e4d53067ff374b89b2ac101ce0c1f72ccaac2` | B2-staking |
| 14 | `0x8208bd314b6d730845e0f1427bc5a150ede9bae7` | aux proxy 2 |

Live getters (block 39,897,334): `paused()=false`, `withdrawPaused()=false`, `claimPaused()=false`,
`poolLength()=5`, `vault()=0xe677…a8F3`.
`vault.strategies(0..4)` **all** = `0xd5B5…46e` (the staking contract is the only registered strategy).
`strategyManager.getStrategyCount()=5`.

## 3. Governance / privilege

- `ADMIN_ROLE` = `0x589d473ba17c0f47d494622893831497bad25919b9afb8e33e9521b8963fccde`
- `UPGRADE_ROLE` = `0xcab03bc4dbcc648cd59d6bbe9f848d1e9092f914016aa290ee92e18700d1e6f9`
- `DEFAULT_ADMIN_ROLE` = `0x00…00`

| Contract | ADMIN_ROLE | UPGRADE_ROLE | holder | kind |
|---|---|---|---|---|
| staking `0xd5B5…46e` | true | true | `0x8Da30b68b1E11761e1307EB10564a39E01ae4480` | **EOA** (nonce 226) |
| vault `0xe677…a8F3` | true | true | `0x8f3c6735152074e4ce2b31bba8b48f128998d76d` | **EOA** (nonce 537) |
| B2-staking `0x796e…cAc2` | owner() | — | `0x8Da30b68b1E11761e1307EB10564a39E01ae4480` | **EOA** |

`RoleGranted` at staking deployment block **747,123** (tx `0x7a0443e4…`) granted
`DEFAULT_ADMIN_ROLE`, `UPGRADE_ROLE`, `ADMIN_ROLE` to `0x8f3c67…d76d`. Today the staking
roles sit with `0x8Da30b…4480`; no `RoleGranted`/`RoleRevoked` occurred in blocks
39,000,000–39,895,000 (so the transfer happened earlier).

Both upgrade authorities are **single EOAs** — a compromised key can `upgradeToAndCall` a
drainer. That is privileged (P), not external-unprivileged (E-U).

## 4. Upgrade history

| Block | Contract | Tx | Caller | New impl |
|---|---|---|---|---|
| 39,700,059 | vault `0xe677` | `0x46e6115d…` | `0x8f3c67…d76d` | `0x59b1cDe6…6C036` |
| 39,700,812 | staking `0xd5B5` | `0xe6f12697…` | `0x8Da30b…4480` | `0x41b3C11d…946f7` (was `0x6a7C2f12…D1D06`) |

Balances either side of the migration: at block 39,121,414 staking held 118.949 BTC and the
vault held 3,218.313 BTC; at head the staking holds 2,918.949 BTC and the vault 418.290 BTC.
Total is conserved (3,337.26 → 3,337.24 BTC); the protocol moved ~2,800 BTC vault→staking via the
role-gated `vault.transferToStaking()`.

## 5. Real withdrawal (historical evidence, pre-upgrade)

- Block **39,121,414**, tx `0xa7238f8dd9ca…`, `from 0xe1fde9ab0c643778eb27a1cf821dabd23bdfb70e`,
  calldata `0x2e1a7d4d…` = `withdraw(0)`. Balances in that block: vault −0.02 BTC, staking ±0,
  user +0.02 BTC → old impl paid from the **vault**.
- Block **39,131,992**, tx `0xfa470835a2a2…`, `from 0xa29e637cec32de087f186516dac5ea24ae8bcafe`,
  `withdraw(0)` → vault −0.002 BTC.
- Block **39,122,871**, tx `0xdc3c04e4a8d5…`, `claim(0)` (0x379607f5) → B2 reward 10.5e18.

## 6. Fork-verified behaviour (new impl, block ≈39,897,000)

See `poc/test/*.sol` (17/17 PASS, CI run 40231111043). Highlights:

- `withdraw(0)` from a 0-balance address: **succeeds but pays 0** (no revert, no value).
- Cross-user: A deposits 0.01 BTC; B (no stake) `withdraw(0)` → B gains **0**.
- Deposit → `withdraw(0)` without `unstake`: pays **0** (payout requires a matured request).
- Deposit → `unstake(0,0.01)` → warp +1,000,000 blocks → `withdraw(0)`: pays exactly **0.01 BTC**,
  **staking contract balance −0.01** (vault unchanged) ⇒ the staking contract's BTC is the
  holder-withdrawal reserve.
- `unstake(0, 100 ether)` with only 0.001 BTC staked → reverts `Not enough staking token balance`.
- 34 unprivileged probes on the staking contract (incl. `fe92e060`, `75c717ef`, `fb2d64b1`,
  `514c25c3`, `eb24f085`, `setVault`, `setB2`, `pauseWithdraw`, `grantRole`, `upgradeToAndCall`, …):
  none moved native BTC (aggregate staking/vault delta = 0).
- `vault.withdraw(...)` and `vault.transferToStaking(...)` from an EOA → revert `no permission`
  (gated on `msg.sender == strategies[pid]`).
- B2-staking `0x796e…`: `withdraw()` w/o request → revert; `requestWithdrawals(100e18)` w/o balance →
  revert; `poolClaim()` → no BTC leaves; `uploadMerkleRoot` / `upgradeToAndCall` /
  `transferOwnership` → revert (owner-only).

## 7. Files

- `heimdall_impl_full.txt` — decompiled staking impl (0x41b3…) + ABI
- `abi_impl.json` — recovered ABI
- `heimdall_vault_impl.txt` — decompiled vault impl (0x59b1…)
- `heimdall_stratmgr.txt` — decompiled strategy-manager impl (0x7b40…)
- `heimdall_0x796e_impl.txt` — decompiled B2-staking impl (0x0619e227…)
- `impl_0x41b3_code.txt` — raw staking impl bytecode
- `unresolved_selectors.txt` — 4byte/openchain resolutions
