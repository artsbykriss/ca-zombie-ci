# USX.Capital (Scroll) — live state and path enumeration

**Read-only. No transactions signed or broadcast. All values are `eth_call` / `eth_getCode`
at Scroll mainnet block 35,666,678 unless stated otherwise.**

## 1. Contracts and roles

| Item | Address | Code / role |
|---|---|---|
| Treasury proxy (ERC-1967) | `0x9F3d4b0C9E930Ca3957eCD3DEdb7417f8e0e4c35` | impl `0x0956dc7E032e77A7b207EB3076B1A47c54627dBd` (`TreasuryDiamond`) |
| USDC (Scroll) | `0x06eFdBFf2a14a7c8E15944D1F4A48F9F95F663A4` | 6 decimals |
| USX | `0x3b005fefC63Ca7c8d25eE21FbA3787229ba4CF03` | impl `0xf5C3Ebd1f58199A7d2e564ACB30cD1174bD7a5b2` |
| sUSX | `0xcB14BcdF6cD483665D10dfD6f87d908996C7F922` | impl `0x72d3adE7359a0B2A6EAb18b94797CBcD2B873719` |
| AssetManager proxy | `0xd16909Ecc9c71d481ee3b2Cb1968C0dAdCf0d300` | impl `0x09F816134C974e8B22300071E7a203eBF4A369F2` |
| Strategy custody Safe | `0x340F07c2736f5022EA5e1afa8d09B04CEB7378EA` | Gnosis Safe, 3-of-4 |
| Insurance vault | `0xD09e956353Fc641792a0F1a7d748773358848F65` | Safe, 0 USDC |
| Governance warchest | `0x91fEb6ca137178C667c54BD788b2F282c858953C` | Safe, 0 USDC |
| PrivateGatewayScroll (live) | `0x6272597fc1Cc23c9E932E670156866FdD4782A30` | impl `0x1CDd6d14E222acB4B5f7C063EEfBfdCBe67317B8` |
| PrivateGatewayScroll (older) | `0x54A56a45D74f748fe5CDe96a3D17843568e287E5` | impl `0x902DD3a47B4473917607C8B10250703b7F35FdD0` (pre-fix, no expected receiver) |

Roles:

| Role | Holder | Type |
|---|---|---|
| `admin()` / `governance()` (Treasury) | `0xE0B408663eA235c11e528a2C3f004946AFE5A7da` | Safe **3-of-4** (owners `0x8A49…`, `0x2Af0…`, `0xEbbe…`, `0x7FdB…`) |
| `allocator()` / `reporter()` | `0xFF8c212885Fe7137edDCFEfdFA8aF55369Efa106` | Safe **2-of-3** |
| USX `admin()` / `governance()` | same `0xE0B4…` Safe | 3-of-4 |
| Gateway `DEFAULT_ADMIN_ROLE` | **0 members** | no admin exists |
| Gateway `KEY_MANAGER_ROLE` | 1 member | key rotation only |

## 2. Live balances at block 35,666,678

| Item | Raw (6d) | USD |
|---|---:|---:|
| Treasury USDC | `104,887,480,603` | $104,887.48 |
| `assetManagerUSDC()` accounting | `463,769,234,076` | $463,769.23 |
| `netDeposits()` | `568,656,714,679` | $568,656.71 |
| AssetManager USDC | `50,630,629,910` | $50,630.63 |
| Strategy Safe USDC | `383,892,260,000` | $383,892.26 |
| USX contract USDC (withdrawal escrow) | `300,000,000,000` | $300,000.00 |
| Live gateway USDC / USX | `0` / `0` | $0 |
| Older gateway USDC | `0` | $0 |
| USX total supply | `569,021,190,723,139,904,297,036` (18d) | 569,021.19 USX |

**Accounting gap.** `netDeposits()` = treasury + `assetManagerUSDC` = 568,656.71, but the
identifiable USDC in treasury + AssetManager + strategy Safe = 539,410.37. The difference is
**29,246.34 USDC**. The strategy Safe holds only USDC (no other token), and the USX contract's
300,000 USDC is fully offset by `totalOutstandingWithdrawalAmount()` = 300,000 (a liability to
whitelisted redeemers). This is an accounting/backing discrepancy, not an attacker path; it is
flagged for reconciliation. It reduces the realisable backing, not the attack surface.

## 3. Zellic findings and live fix status

Audit: *Private Transfer With USX*, Zellic, 18 Mar 2026
(`github.com/Zellic/publications`), repo `scroll-tech/usx-contracts` @ `d69433e7`.

| Finding | Severity | Live status |
|---|---|---|
| 3.1 `usxReceiver` / `usdcReceiver` both user-controlled | Critical | **Fixed**: live gateway checks `keccak256(usdcReceiver) == keccak256(expectedUSDCReceiver)` (source line 520; `expectedUSDCReceiver` is non-empty, 117 bytes + keyId 0). |
| 3.2 `rebalanceBySwapping` unpermissioned / no router allowlist | High | **Fixed in source**: router allowlist, 1:1 USX check, and `expectedUSXReceiver` binding. No live `USXRebalancer` was found among the 95 contracts created by the USX deployer; the audited rebalancer is not part of the Scroll treasury deployment. |
| 3.3 `mintUSX` misuse in `rebalanceByMinting` | Medium | Fixed in source. |
| 3.4 Stale allowance | Medium | **Fixed**: `forceApprove(spenders[swapRouter], 0)` after the swap (source line 357). |
| 3.5 `encryptedReceiver` / `actualReceiver` desync | Critical (acknowledged) | **Not a permissionless path.** `withdrawUSX` is `onlyRole(WITHDRAW_USX_ROLE)` on `PrivateGatewayCloak`; `actualReceiver` is a privileged-call input. No Scroll-side user function takes or sets `actualReceiver`. Team response: role sits behind a multisig. |
| 3.6 Insufficient tests | Medium | Acknowledged; not a fund path. |

## 4. Every user-callable path on the live Scroll gateway

`PrivateGatewayScroll` (impl `0x1CDd…`) exposes exactly two unprivileged mutators:

1. `transferUSDC(uint256 amount, EncryptedReceiver usxReceiver, EncryptedReceiver usdcReceiver)`
   - Pulls `amount` USDC from `msg.sender`; requires `usxReceiver.keyId == latest keyId`; requires
     `usdcReceiver` to equal the admin-set `expectedUSDCReceiver`; charges a fee (live 0); approves
     the L1 gateway; calls `depositERC20(USDC, usdcReceiver.receiver, amount, 1e6, keyId)`; sends a
     `confirmDeposit(nonce, usxReceiver.receiver, keyId, amount)` message to the Cloak gateway.
   - **One-way deposit.** No branch transfers USDC/USX back to the caller. The gateway holds 0.
2. `transferToken(address token, uint256 swapAmount, address swapRouter, bytes swapData, …)`
   - Pulls a supported token (or ETH), approves the allowlisted router spender for exactly
     `swapAmount`, executes the caller-supplied `swapData`, measures the USDC delta, then calls
     `_transferUSDC`. Approval is zeroed afterwards. The USDC delta is fully deposited; no skim.
   - The only supported router is `0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE` (LI.FI). An attacker
     can choose a bad route, but cannot make the gateway pay USDC to themselves; the received USDC
     goes to the L1 gateway, not to the caller.

Everything else is gated:

- `withdrawTokens` — `DEFAULT_ADMIN_ROLE`; **0 members** live.
- `update*`, `registerNewEncryptionKey`, `updateSupportedTokens/SwapRouter` — admin/key-manager.
- `receive()` — ETH only; no sweep by users.

## 5. Cloak-side (chain 5343523304) — why the desync is P-class, not E-U

`PrivateGatewayCloak` source (repo @ `d69433e7`, live counterpart `0xad33D6Cd27db4D9f3e3B73a0e073909E3d890f93`
from the Scroll gateway's `counterpart()`):

- `confirmDeposit(nonce, encryptedReceiver, keyId, amountUSDC)` — `onlyMessenger` and
  `xDomainMessageSender() == counterpart`; stores `confirmedDeposits[hash]`. A user can create a
  confirmed deposit only by making a real USDC deposit on Scroll; the hash is unique by nonce.
- `withdrawUSX(nonce, encryptedReceiver, keyId, amountUSDC, actualReceiver)` —
  `onlyRole(WITHDRAW_USX_ROLE)` and `nonReentrant`; recomputes the hash, checks it is confirmed and
  not withdrawn, then bridges USX to `actualReceiver`. **The only function with `actualReceiver` is
  role-gated.** There is no unprivileged caller that can set it.
- `rebalance()` — `onlyRole(REBALANCE_ROLE)`.
- `withdrawTokens()` — `DEFAULT_ADMIN_ROLE`.

The Cloak validium RPC is bearer-token gated (Scroll Cloak docs, "Authentication": all JSON-RPC
methods require a scoped token; an unauthenticated `eth_getBalance` returns `unauthorized`). The
production Cloak state is therefore **not publicly readable**; we could not independently read the
live `WITHDRAW_USX_ROLE` members or the Cloak gateway balance. This is the one residual blocker.
The gate itself is explicit in the verified source and in the audit: a compromised backend can
redirect a *confirmed* deposit to an attacker-chosen `actualReceiver` **only if it also controls
the `WITHDRAW_USX_ROLE` multisig**. That is a trusted-role / key-compromise scenario, not an
external unprivileged path.

## 6. USX mint / redemption

- `USX.deposit(uint256)` and `USX.requestUSDC(uint256)` are `onlyWhitelisted`; a fresh EOA is not
  whitelisted (`whitelistedUsers(attacker) == false`) and `whitelistUser` is `onlyAdmin` (3-of-4 Safe).
- `USX.claimUSDC()` is public but pays only `outstandingWithdrawalRequests[msg.sender]`; a fresh EOA
  has 0. The 300,000 USDC in the USX contract is a liability to already-whitelisted redeemers
  (H-O), not free inventory.
- `USX.mintUSX` / `burnUSX` are `onlyTreasury`; the treasury's `mintUSX` callers are the reporter
  (2-of-3 Safe) and the allocator (2-of-3 Safe).

## 7. USXRebalancer

The audited `USXRebalancer` is not in the USX deployer's 95 Scroll contract creations (enumerated
via Blockscout `transactions?filter=from`, blocks 24,251,407–32,962,251). The current repo source
has the router allowlist, the `usxAmount >= amountUSDC * 1e12` check, and `_transferUSX` bound to
`expectedUSXReceiver`; even if deployed unpermissioned, the output cannot be redirected to an
attacker-chosen receiver. No live USDC/USX balance attributable to it was found.

## 8. Conclusion

At block 35,666,678 the live Scroll gateway and the older pre-fix gateway both hold **0 USDC**.
The treasury/AssetManager/strategy Safe hold **$539,410.37** behind 3-of-4 / 2-of-3 Safes and
`onlyTreasury` / `onlyAllocator` functions. The USX escrow holds **$300,000** for whitelisted
redeemers. The Zellic 3.5 desync requires the `WITHDRAW_USX_ROLE` (a privileged multisig) to
redirect a confirmed deposit; an external unprivileged attacker cannot reach it. **E-U = $0.**
