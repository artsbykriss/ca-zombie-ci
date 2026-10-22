# Kuru (Monad) — analysis notes

## Addresses (Monad mainnet, chain 143)

| Name | Proxy | Impl | Impl size | Verified? |
|---|---|---|---|---|
| AccountCore | `0x264123a9B96Cc1193944cC25C188f1bD3dFa670e` | `0xb52debad718730ee0a4c12c28e70d346dbcc9e5b` | 33,512 B | **no** |
| MarginAccount | `0x2A68ba1833cDf93fa9Da1EEbd7F46242aD8E90c5` | `0x351525073afa933720329756716fcf7d741e7ff0` | 5,174 B | **no** |
| KuruForwarder | `0x974E61BBa9C4704E8Bcc1923fdC3527B41323FAA` | `0xbf6cc109c6ebca4b28e3e51fd8798294599cfe2a` | 5,7xx B | **yes** (`KuruForwarder`) |
| Router | `0xd651346d7c789536ebf06dc72aE3C8502cd695CC` | `0xf1635175914acf4db170395d524323225e1f1a04` | 10,874 B | no |

All three proxies are the same 141-byte EIP-1967 minimal proxy:
`0x60806040525f8073ffff...360894a1...5af43d5f803e156053573d5ff35b3d5ffdfea264697066735822...0033`
→ reads slot `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`, `delegatecall`s.

(The pass-4 lead called these "ERC-1167 clones"; they are EIP-1967 minimal proxies — 0x60 bytes of logic + 45 bytes CBOR metadata = 141 bytes. Same conclusion: unverified implementation.)

## Snapshot (block 115,617,713 = 0x6e42fb1)

| Contract | MON | USDC (6dp) | USD |
|---|---:|---:|---:|
| AccountCore | 966,366.2188 | 136,809.390411 | $157,297.76 |
| MarginAccount | 4,195,855.9678 | 133,466.203201 | $222,426.63 |
| **Total** | **5,162,222.1866** | **270,275.5936** | **$379,724.90** |

MON $0.021201974484101976 (DefiLlama `coingecko:monad`, ts 1792673817); USDC $1.00.
USDC `0x754704Bc059F8C67012fEd69BC8A327a5aafb603` (`symbol()`="USDC", `decimals()`=6).

## Config
- `owner()` (both) = `0x8b736dce2071783fd9db0a423dad17cc8ed5788b`
- AccountCore `authority()` = `0x15db88bac73d856b3ca53683f82058826a3b6e8f`
- AccountCore `withdrawalAuthority()` = `0x81f6f37d079b88fdd6c5f674b3f328eee028fe56`
- AccountCore `feeCollector()` = `0x62ee1b8d1efdf8f73c78db87b888406b194e266a`
- `withdrawalsFrozen()` = false, `protocolPaused()` = false
- MarginAccount `isTrustedForwarder(0x974E61BB…)` = **true**

## Selector map
- AccountCore: **105** dispatcher selectors (scanned `63<sel>14` / `8063<sel>14`), listed in `accountcore_4byte.txt`.
  Matches Kuru's official SDK `accountCoreAbi` (github.com/Kuru-Labs/ts-sdk, `src/generated/abis.ts`, 104 fns).
  Key value-moving entry points:
  - `0x67f3e6c3 withdraw(uint40 rootAccountId,address token,uint256 amount,address recipient)` — owner / authorised-signer (`ACCOUNT_PERMISSION_WITHDRAW`) only
  - `0x0a3c83c3 fulfillApprovedWithdrawal((address,address,address,uint256,uint256,uint256,uint64),bytes)` — `msg.sender == withdrawalAuthority` **and** owner EIP-712 sig
  - `0x8340f549 / 0x99b82ced deposit(...)` — permissionless, credits a named account, pulls from `msg.sender`
  - `0xfd8e8fb2 createSubaccount(address rootOwner,uint40)` — only for the caller's own root account
  - `0x7a9e5e4b setAuthority`, `0x0cd09628 setWithdrawalAuthority`, `0xe004f924 toggleProtocolState`, `0x4f1ef286 upgradeToAndCall` — `onlyOwner`
- MarginAccount: **23** selectors; ABI == SDK `MarginAccount.json` (24 fns; `withdraw 0x00f714ce`, `batchWithdrawMaxTokens 0x0f163fa8`, `deposit 0x8340f549`, `debitUser 0x6c139252`, `creditUser 0x75eab98e`, `creditFee 0x49f59b62`, `verifiedMarket 0x5f71a07c`, `updateMarkets 0x01aef349`, `toggleProtocolState 0xe004f924`, `setFeeCollector 0xa42dce80`, …). Source = `Kuru-Labs/Kuru-contracts-dex-public/contracts/MarginAccount.sol`.
- KuruForwarder: 24 selectors (`execute 0x6e084905`, `executeMarginAccountRequest 0x…`, `verify* 0x10012a15/0x16912671/…`).

## Auth probes (eth_call, `from` = fresh `0x1111…1111`, block 115,617,713)
Raw in `probe_results.json`; error selectors resolved via `4byte.directory`:
`0x82b42900 = Unauthorized()`, `0xfaba8ebe = AccountNotFound()`, `0xf4d678b8 = InsufficientBalance()`, `0xcd41a9e3 = NativeAssetMismatch()`.

| Call | Result |
|---|---|
| `AC.withdraw(1,0,1e18,fresh)` | `Unauthorized()` |
| `AC.withdraw(0,…)` | `AccountNotFound()` |
| `AC.withdraw(26,0,1e18,fresh)` | `Unauthorized()` |
| `AC.withdraw(26,0,1,fresh)` **as owner 0x9DabA3…** | **success (0x)** |
| `AC.setAuthority/setWithdrawalAuthority/toggleProtocolState/upgradeToAndCall` | `Unauthorized()` |
| `AC.createSubaccount(victim,0)` | `Unauthorized()` |
| `AC.createSubaccount(fresh,0)` | success → id 0x89, 0 value |
| `AC.fulfillApprovedWithdrawal(…,0x)` | revert |
| `AC.f4838452(0/1)` | `Unauthorized()` |
| `MA.withdraw(1e18,0)` | `InsufficientBalance()` |
| `MA.batchWithdrawMaxTokens([0])` | success, no-op |
| `MA.toggleProtocolState(false)` | `Unauthorized()` |
| `AC.transferBetweenAccounts(26,94,native,1e18)` | revert `0x28cddf05` (Kuru custom error, unlisted; gated) |
| `AC.authorizeAccountSigner(26,fresh,…)` | revert (gated) |
| `AC.approveBuilder(26,fresh,…)` | revert (gated) |
| `AC.rootAccountIdOf(feeCollector)` | 3; `rootAccountIdOf(owner multisig)` = 0 |

Account id 26: owner `0x9DabA38229F593d90f99062bb18ed41f57b16CE8`; `getBalance(26,native)` = 73,613.82 MON; `getSpotReservedBalance(26,native)` = 706,519.58 MON. Id 94 = 50,000 MON; ids 2,4,5,7,11,36,45,57,67,74 smaller.

## Formal verification (independent)
`github.com/lfglabs-dev/ethereum-verification-benchmark`, case `kuru/withdrawal_limit`:
- source revision `62c478b05dfe936c87fa95f35d89307d4a2d303c`, `src/account/AccountCore.sol` (original Solidity not distributed)
- 8 spec groups, combined `PolicyBundle`, `proof_status: complete`, "no custom axioms or admitted reference proofs"
- `withdrawAuthorized`: caller == account owner, or a grant with permission bit 3/4 (WITHDRAW / INTERNAL_TRANSFER) and unexpired
- `fulfillApprovedWithdrawal`: `caller = authority` ∧ owner-signed `ApprovedWithdrawal` ∧ nonce == approvedNonces[account] ∧ epoch match ∧ `now ≤ deadline`; nonce consumed before transfer; persistent reentrancy guard

## Public sources
- `github.com/Kuru-Labs/Kuru-contracts-dex-public` — MarginAccount / KuruForwarder / Router / OrderBook
- `github.com/Kuru-Labs/ts-sdk` — `accountCoreAbi`, `src/account/withdrawals.ts` (`ApprovedWithdrawal` EIP-712 type, `fulfillApprovedWithdrawal`)
- `github.com/Kuru-Labs/Kuru-contracts-flow-public`, `github.com/Kuru-Labs/kuru-sdk-py` (orderbook/margin ABIs + deployedBytecode)
- `docs.kuru.io/contracts/Contract-addresses`

## Dead ends / negatives
- heimdall produced ABIs but not Solidity for the two impls (`--skip-resolving`); the ABI shape was enough.
- The deployed impls are **newer revisions** than the SDK's snapshots (MarginAccount 5,174 B on-chain vs 2,781 B in the SDK; OrderBook 33,512 B vs 32,446 B) — exact source not public, so no byte-exact recompile was possible for these two.
- `supportedSpotTokens()` reverted / returned empty via raw eth_call.
