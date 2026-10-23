# P5-01 — Sodium smart-account ERC-1271 signer bypass (Arbitrum One): live re-verification

**Date:** 2026-10-23 · **Chain:** Arbitrum One (42161) · **Status:** read-only research.
No transaction was signed or sent to any live network. The exploit is demonstrated only on a
local/CI **Arbitrum fork**; the live-state proof uses `eth_call` + state override (no state change).

**Targets**

| Role | Address |
|---|---|
| Vulnerable implementation | `0xb5BC46dF04dEe31D219E7664122e29EEd9506b8b` (Arbitrum only; `eth_getCode` = `0x` on Ethereum/Base/Optimism/Polygon/BSC) |
| Account factory (CREATE2) | `0x5Eb4bcAEB78a7a765FA3F7285eE6B3E08CCB2c09` |
| EntryPoint v0.6 | `0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789` |
| Example victim proxy | `0x0209d8fcB0C36399EB49E018a245C55fd37D16BD` |
| Second (patched) Sodium impl | `0x46516e846ccba95fefc8da6a3cbab875367e5c46` — bypass **not** reproducible |
| Real 2026-07 attacker (prefund) | EOA `0x7bd736631afbe1d3795a94f60574f7fa0ae89347` / contract `0xfC99FA4b30bDB2E3da90706882A24759307b0343` |
| Real 2026-07 attacker (tokens) | EOA `0xCe1a3BB0b98D0D90C7Dd0620Ab86C9A771888d88` / contract `0x56362412AE17cac443AAFBAb4289946Ad958E8a1` |

---

## 1. TL;DR

| Target | Live extractable (external, unprivileged) | Why open / closed | Latent risk |
|---|---|---|---|
| 8,302 Sodium accounts pointing at impl `0xb5BC46dF…` | **$0.00 net today** — gross residual dust ≈ **$13.79** spread over 8,302 accounts (median ≪ $0.01; largest single account $0.25) | **OPEN, fork-proven** auth bypass; value is $0 because every account was drained in 2026-07 and none refunded. Per-account dust is at/below the gas cost to lift it, so the *net* is zero. | **E-U-conditional**: any inbound ETH or ERC-20 to *any* of the 8,302 accounts is drainable **by anyone, with zero capital**, the moment it arrives |
| EntryPoint prefund / deposit path | **$0.00 net today** (2,561 accounts hold a v0.6 deposit, total 0.001524 ETH ≈ $3.65, max $0.026) | same | re-arms on any inbound native ETH or deposit |
| 207 accounts on the second impl `0x46516e84…` | **$0** | bypass **not** reproducible there (patched/other build) | none for this primitive |

**Total live extractable now: $0.00 net** (gross dust ≈ $13.79; net of per-account gas ≈ $0).
**Confidence: HIGH.** Mechanism confidence: HIGH (both primitives reproduced on the live proxy / a fork).

The finding is a genuine, unpatched, permissionless authentication bypass. Its *current* extractable
value is zero because the vulnerable accounts are empty dust; the risk is a **zero-capital instant
re-arm** on any future funding.

---

## 2. The bug, in exact terms

The deployed implementation is byte-identical to the Sourcify **exact_match** source
(`compiler 0.8.17+commit.8df45f5f`, contract `Sodium`):

```
on-chain  eth_getCode(0xb5BC46dF…) keccak256 = 0xdb623ea308ecc67d39239d5c89b2e529c5969161863b7521fa8a675e3ddf8994
Sourcify  runtimeBytecode         keccak256 = 0xdb623ea308ecc67d39239d5c89b2e529c5969161863b7521fa8a675e3ddf8994   (12,737 bytes)
```

Two independent primitives share one root cause — validation authenticates the operation against
**attacker-supplied fields** before any owner authorisation exists.

**(A) ERC-1271 signer self-selection.** `Sodium.checkValidSodiumSignature` (source `contracts/Sodium.sol`)
takes the signer address *from the signature itself*:

```solidity
if (sigType == 0x01) {                       // 0x01 ‖ 20-byte signer ‖ signature bytes
    signer = <_signature[1:21]>;
    valid  = SignatureChecker.isValidSignatureNow(signer, _hash, _signature[21:]);
}
```

`_validateSignature` then accepts the op when `sessionKey == signer && isSafe`, where `sessionKey` is
read from the same attacker `callData[16:36]` and `isSafe = (_safeSession.owner == address(0))`. A
one-function attacker contract returning the ERC-1271 magic value `0x1626ba7e` for *any* input
therefore yields `validationData = 0` with no owner signature, no role, no capital.

**(B) Validation-phase token approval.** `validateUserOp` runs `_approvePaymasterToken(userOp)`
unconditionally after the signature check. It parses `paymasterAndData` as
`paymaster(20) ‖ 0x095ea7b3 ‖ token(20)` and trusts the attacker paymaster for both threshold and
amount:

```solidity
if (payToken.allowance(address(this), address(paymaster)) < miniAllowance)
    payToken.approve(address(paymaster), suggestApproveValue);   // (1, type(uint256).max)
```

Because validation returned `0`, EntryPoint **keeps the validation-phase state**. The account's
execution is given `callGasLimit = 0`, fails (`opReverted`), and does not revert the outer `handleOps`,
so the unlimited allowance survives and the attacker later calls
`token.transferFrom(victim, attacker, balance)`.
(If validation had returned `1`, EntryPoint would revert `AA24` and roll the allowance back — which is
exactly why primitive A is required.)

**(C) Gas-prefund drain (no paymaster).** `BaseAccount._payPrefund(missingAccountFunds)` sends native
ETH from the account to EntryPoint during validation. With no paymaster, `missingAccountFunds` is
`(callGasLimit + verificationGasLimit + preVerificationGas) * maxFeePerGas`. The attacker (as bundler)
sets an inflated `maxFeePerGas` and `beneficiary = attacker`; EntryPoint pays the beneficiary
`actualGasUsed * min(maxFeePerGas, maxPriorityFeePerGas + basefee)` — i.e. the victim's ETH is converted
to gas at the attacker's chosen price, while the attacker pays only the real Arbitrum gas cost. The
same path drains an account's EntryPoint **deposit** (the deposit covers `missingAccountFunds`).

---

## 3. Live-state assessment (census block 517,549,529; bypass re-proof block 517,458,210)

| Check | Result |
|---|---|
| Impl code present / size / hash | yes · 12,737 B · `0xdb623ea3…` (unpatched) |
| Cross-chain | `eth_getCode` = `0x` on Ethereum/Base/Optimism/Polygon/BSC — Arbitrum only |
| Factory-created candidate accounts | **8,645** (Etherscan V2 `txlistinternal`, CREATE2 by `0x5Eb4bcAE…`) |
| Accounts still pointing at `0xb5BC46dF…` | **8,302** |
| Accounts pointing at the second impl `0x46516e84…` | **207** (larger build, 25,449 B; bypass returns `valid=0` — **not** vulnerable) |
| Accounts with native ETH > 0 | **2,450**, total **0.00247846 ETH** ≈ **$5.94** (max single `0x4652ae23…` = 0.00010636 ETH ≈ $0.255) |
| Accounts with any of 12 major ERC-20s > 0 | **1,021**; USDT0 3.829086 (≈$3.82) + USDC 0.071867 + USDC.e 0.304477 → ≈ **$4.20**; WETH/ARB/DAI/WBTC/LINK/wstETH/USDe/weETH/FRAX = 0 |
| Accounts with EntryPoint deposit > 0 (v0.6) | **2,561**, total **0.00152372 ETH** ≈ **$3.65** (max single 0.00001081 ETH ≈ $0.026) |
| Gross residual dust | ≈ **0.004002 ETH ($9.59) + $4.20 tokens = $13.79** |
| Latest account creation by factory | 2026-01-25 (block 425,162,618) — the account set is static; no new accounts |

**Live bypass re-proof (`eth_call` + state override, block 5,174,58,210; no state change):**
`checkValidSodiumSignature(hash, 0x01‖attacker‖0x00)` on the live proxy `0x0209d8fc…` returns
`valid = true, signer = attacker` for both the real 2026-07 signer and a freshly invented attacker
contract; an EOA signer returns `valid = false`. See `analysis/bypass_reverify.json`.

The accounts are empty for the same reason the bug is famous: they were drained in 2026-07
(see §5). The residual balances are dust and the *net* extractable value is zero: the single largest
account is worth $0.25 gross, and every other account is worth ≤ $0.05 — at or below the cost of one
`handleOps` on Arbitrum, and far below it for the ~6,000 sub-$0.01 accounts.

---

## 4. What an attacker can / cannot do

**Can (permissionless, no capital beyond ~$0.01–0.05 of gas per batch):**
1. For any account holding ERC-20 tokens: deploy a 1-function ERC-1271 contract, submit one
   `handleOps` with `paymasterAndData = attacker‖0x095ea7b3‖token`, `callGasLimit = 0`, signature
   `0x01‖attacker‖0x00`; the account approves the attacker for `type(uint256).max`; then
   `transferFrom` the balance. **Proven on a fork** (`test_tokenApprovalBypass`).
2. For any account holding native ETH (or an EntryPoint deposit): submit one `handleOps` with no
   paymaster, inflated `maxFeePerGas`, `beneficiary = attacker`; EntryPoint pays the attacker from the
   victim's prefund/deposit. **Proven on a fork** (`test_prefundDrain`): a 10-ETH victim pays the
   attacker **0.269 ETH in a single op** at `maxFeePerGas = 4000 gwei`; repeatable with the nonce, and
   larger with a higher declared fee.
3. **Re-arm on funding:** any ETH or ERC-20 that arrives at any of the 8,302 accounts is drainable by
   the same zero-capital path within the same block.

**Cannot:** touch accounts on the patched impl `0x46516e84…`; move funds the account does not hold;
act without paying the real (small) Arbitrum gas for `handleOps`.

**Cost:** one `handleOps` on Arbitrum costs the attacker ~$0.01–0.05 of L1/L2 gas — effectively zero
capital. No flash loan, no collateral, no role.

---

## 5. PoC / fork-verification

Foundry project in `poc/` (fork of Arbitrum at latest via `ARB_RPC_URL` / public fallback):

| Test | Result |
|---|---|
| `test_tokenApprovalBypass` | PASS — allowance granted = `2^256-1`; attacker drains the victim's full USDT0 |
| `test_prefundDrain` | PASS — attacker gains 0.269068 ETH; victim's prefund debited 3.284 ETH (remainder refunded) |
| `test_negative_control_reverts` | PASS — an EOA signer fails and EntryPoint reverts (AA24) |

CI runs (GitHub Actions, `artsbykriss/ca-zombie-ci`):

* PoC (3/3 PASS) — https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39956233457
* Full 8,645-account census artifact (4.4 MB) — https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39963115529

Historical incidents (on-chain, verified):

| Incident | Tx | Block | Loss |
|---|---|---|---|
| Prefund drain | `0x738995176c…5e6d7bc1` | 483,046,805 (2026-07-12) | 11.761122 ETH (~$21,165 @ $1,799.59; ≈$28.2k @ $2,397.73) |
| Token approval | `0x630654fb1c…c6604` | 483,389,834 (2026-07-13) | allowance = `2^256-1` |
| Token drain | `0x1cdba4c3f9…b9f0` | 483,390,113 (2026-07-13) | ~$270,000 |

---

## 6. Verdict, classification, residual risk

**Classification (per SUBAGENT-BRIEF §5.6):**

| Category | USD now | Notes |
|---|---|---|
| **E-U** | **$0.00** (net) | gross residual dust $13.79 over 8,302 accounts; net of per-account gas ≈ $0; best single account ≈ $0.20 |
| **E-U-conditional** | **$0.00 now → unbounded on funding** | any inbound ETH/ERC-20 to any of the 8,302 accounts is instantly drainable by anyone, zero capital |
| H-O | $0 | n/a |
| P | $0 | n/a |
| S | $0 | n/a |

**Verdict:** HIGH-severity unpatched vulnerability, **$0 live** — a re-arm, not a live capture.
Confidence **HIGH** (bug) / **HIGH** ($0 net today).

**Re-arm trigger (monitor):** any native-ETH or ERC-20 balance appearing on any account whose
`slot[address(this)]` equals `0xb5BC46dF04dEe31D219E7664122e29EEd9506b8b`. Concretely: watch the
8,302 factory accounts (list in `analysis/sodium_factory_accounts.json` / `ci-out/census.json`) for
`eth_getBalance > 0` or any ERC-20 `Transfer` into them, and watch EntryPoint
`balanceOf(account)`. A ready-to-run check is `analysis/monitor.py` (exits non-zero and prints the
account if any balance above dust appears).

**Blockers (why it is $0):** the accounts are drained to dust; there is no material deposit; the impl
has not been upgraded; no user has refunded any account since 2026-07.

---

## 7. Methodology, caveats, files

**Method:** source from Sourcify (`exact_match`) + runtime-hash comparison; live `eth_call` with state
override for the auth bypass; full account enumeration from the factory's CREATE2 internal-tx history
(Etherscan V2) with `eth_getCode` + `eth_getStorageAt(address)` classification; balances via
`eth_getBalance` + Multicall3 over a 12-token basket; EntryPoint deposits via `balanceOf` on v0.6/v0.7/
v0.8; Foundry fork PoC in CI. Read-only throughout.

**Caveats:** the token census covers a 12-token basket (the primitive works for *any* ERC-20, so a
token outside the basket could be present, but the observed dust is sub-cent per account); the factory
account list is derived from Etherscan's internal-tx index (a node-level scan could in principle find
an account created by a different path, but all sampled accounts are factory children); prices from
DefiLlama at 2026-10-23 (ETH $2,397.73, USDT0 $0.9986, USDC/USDC.e ≈ $1.00); the net-of-gas figure
assumes a batch `handleOps` costs ~$0.01–0.05 per account on Arbitrum.

**Files:** `analysis/source/` (verified source), `analysis/MECHANISM.md`,
`analysis/bypass_reverify.json`, `analysis/sodium_factory_accounts.json`, `analysis/census_accounts.json`,
`analysis/fetch_*.py`, `analysis/monitor.py`, `ci/census.py`, `ci/run.sh`, `poc/` (Foundry),
`ci-out/` (CI artifacts), `summary.json`.
