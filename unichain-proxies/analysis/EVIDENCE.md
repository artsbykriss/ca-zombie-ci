# Evidence log — Unichain ImmutableProxy family (O8)

All reads are read-only, no transaction signed. Chain id 130. "block" = Unichain block.

## A. Family identity
- Blockscout verified-name search `ImmutableProxy`: **299** contracts
  (`children/enum/ci-out/search_ImmutableProxy.json`, `clones_raw.json`).
- Runtime of every clone is the 75-byte minimal proxy
  `60806040523615604957366000803760008036817f<impl>5af43d6000803e156044573d6000f35b3d6000fd5b00`
  (impl at byte offset 33). `analysis/immutableproxy_clone.json`.
- impl distribution (from `constructor_args`): `0x3fd339…` ×295, `0x204d732e…` ×2, `0x9f70b0c8…` ×2.
- `verified_at` histogram: 2026-10-16 ×141 (the recon's "~130"), 2026-09-24 ×102, others ≤23.

## B. Impls + embedded portals (static, from runtime bytecode `analysis/impls/*.hex`)
| impl | name | deployer/portal | verified |
|---|---|---|---|
| `0x3fd339E58769a56D08dcd2683F9012E881287476` | `Vault` | `0x399Dbd5DF04f83103F77A58cBa2B7c4d3cdede97` | yes (v0.8.27) |
| `0x9f70b0c839fe2D7190a09AE87ED658B6d1Cba4F9` | — | `0xEC000064576f9C95a8623Bc0eff3db6d296ea6df` | no |
| `0x204D732E8d2f71D756eF5De79Dc6589721b53420` | — | `0xEC000769A73b70e16f361a442292500b3BCf4A85` | no |

`grep` for the portal bytes inside each impl's runtime code confirmed the immutable; it equals the
impl's deployer. Both unverified impls expose the same 4 selectors as `Vault`
(`0x012c41ca` withdraw, `0x76a66d1b` fundFor, `0xaadee52c` refund, `0x648bf774` recover) — heimdall ABI.

## C. Gating (live `eth_call`, from a random EOA)
- `recover(address,address)` and `withdraw((uint64,address,address,uint256,(address,uint256)[]),address)`
  revert `NotPortalCaller(0x…dEaD)` (`0x407c71ac`) on:
  `0x86dd8FE8…` (impl 0x9f70b0c8), `0xdF99821D…` (0x9f70b0c8), `0x03f3D736…` (0x204d732e),
  `0x59B630E4…` (0x204d732e), `0x966107c4…` (0x3fd339), `0xed9956e3…` (0x3fd339).

## D. Live balances (authoritative RPC, not Blockscout)
- `analysis/live_rescan.json` — all 299 clones at block **62190582**: USDC 0, native 0.
- `ci-out/immutableproxy_scan.json` — all 299 clones at block **62191907**: `total_usdc = 0.0`,
  `total_native_wei = 0`, `funded = {}`.
- `analysis/token_balances_now.json` — Blockscout `/token-balances` claims 166 clones hold tokens,
  sum ≈ **$271,684.77** (stale). Direct `balanceOf` on the same addresses = 0 (checked on 4 RPCs).

## E. Staleness proof (one clone, `0x08A4955Fd5c06956B2D03A713627a2040d1c199a`)
- creation tx `0xfe8b53d3…` at block **42,591,324** (2026-03-12 18:21:23 UTC).
- USDC in: 4,961.10 at block 42,591,188; USDC out: 4,961.10 at block 42,591,324 (same block as creation).
- live `balanceOf` = 0 on `mainnet.unichain.org`, `unichain-rpc.publicnode.com`, `unichain.drpc.org`.
- Blockscout `/token-balances` still returns `4961103879`.

## F. Settled-everything check (from downloaded event logs)
- Portal `0x399Dbd5D`: IntentFunded 7622, IntentWithdrawn 7325, IntentRefunded 523 →
  **funded ∖ (withdrawn ∪ refunded) = 0**.
- Portal `0xEC000064`: IntentFunded 3731, IntentWithdrawn 3669, IntentRefunded 63 → **0**.

## G. Portal code paths (`analysis/prover_src/contracts__IntentSource.sol`)
- `withdraw` (line 417): `claimant = IProver(reward.prover).provenIntents(intentHash).claimant`;
  `_validateWithdraw` (line 811) allows only Initial/Funded and non-zero claimant; status set to
  `Withdrawn` **before** the vault call.
- `refund` (482) pays `reward.creator`; `refundTo` (503) `require(msg.sender == reward.creator)`;
  `recoverToken` (530) pays `reward.creator`.
- `intentHash = keccak(abi.encodePacked(destination, routeHash, keccak(abi.encode(reward))))` (148).
- `Vault.sol`: `onlyPortal` on fundFor/withdraw/refund/recover; `portal` immutable; no init.

## H. Portals' activity
- `0x399Dbd5D` last log block 52,898,784 (2026-07-10) — inactive.
- `0xEC000064` last log block 60,029,342 (2026-09-30) — inactive.
- `0xEC000769` active (last block 62,185,442) but its current vaults are **not** `ImmutableProxy`
  (e.g. `0x50cFe7c193…` has a 5-selector dispatcher, not the minimal-proxy runtime).

## I. Fork PoC
`poc/test/UnichainVaultPoC.t.sol` → 7/7 PASS; CI run 40204644262.
