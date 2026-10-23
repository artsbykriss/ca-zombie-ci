# P5-01 Sodium smart-account — mechanism notes (read-only)

Impl `0xb5BC46dF04dEe31D219E7664122e29EEd9506b8b` (Arbitrum One).
Deployed code hash `0xdb623ea308ecc67d39239d5c89b2e529c5969161863b7521fa8a675e3ddf8994`
(12,737 bytes) — byte-identical to the Sourcify **exact_match** runtime bytecode
(compiler `0.8.17+commit.8df45f5f`, contract `Sodium`). So the live code *is* the vulnerable source.

## Two independent primitives from one root cause

### A. ERC-1271 signer self-selection (`checkValidSodiumSignature`)

`contracts/Sodium.sol`:

```solidity
function checkValidSodiumSignature(bytes32 _hash, bytes calldata _signature)
    public view returns (bool valid, address signer, address trustee)
{
    bytes1 sigType = bytes1(_signature[:1]);
    if (sigType == 0x01) {                       // {0x01}{20-byte signer}{signature bytes}
        bytes memory addressBytes = _signature[1:21];
        bytes memory signatureBytes = _signature[21:];
        assembly { signer := mload(add(addressBytes, 20)) }
        valid = SignatureChecker.isValidSignatureNow(signer, _hash, signatureBytes);
    }
    ...
}
```

`_validateSignature` (Sodium.sol) then accepts the UserOperation when

```solidity
if (methodId == this.executeWithSodiumAuthSession.selector) {
    address sessionKey;                          // read from attacker callData[16:36]
    ...
    bool isSafe = _safeSession.owner == address(0);
    ...
    return sessionKey == signer && isSafe ? 0 : 1;   // both attacker-controlled -> 0
}
```

A `0x01` signature whose "signer" is an attacker contract that returns the ERC-1271 magic value
`0x1626ba7e` for any input makes `valid = true` and `signer = attacker`. Because `sessionKey` is read
from the *same* attacker-supplied `callData`, `sessionKey == signer` holds; and for an account with no
configured safe session, `_safeSession.owner == address(0)` ⇒ `isSafe = true`. Net: `validationData = 0`
without any owner authorisation.

**Live proof (eth_call + state override, block 5,174,58,210):**
`checkValidSodiumSignature(hash, 0x01‖attacker‖0x00)` on proxy `0x0209d8fc…` returns
`valid=1, signer=attacker` for both the real 2026-07 signer and a fresh contract; an EOA signer returns `0`.

### B. Validation-phase token approval (`_approvePaymasterToken`)

`validateUserOp` runs `_approvePaymasterToken(userOp)` unconditionally after the signature check
(and after `_payPrefund`). It parses `paymasterAndData` as an exact 44-byte blob:

```
paymaster address (20)  ‖  0x095ea7b3 (4)  ‖  token address (20)
```

and then:

```solidity
(uint256 miniAllowance, uint256 suggestApproveValue) =
    paymaster.getTokenAllowanceCast(payToken);          // attacker contract returns (1, type(uint256).max)
if (payToken.allowance(address(this), address(paymaster)) < miniAllowance) {
    payToken.approve(address(paymaster), suggestApproveValue);   // persistent allowance to attacker
}
```

Because validation returned `0`, EntryPoint keeps the validation-phase state. The account's later
execution is given `callGasLimit = 0` and fails (`opReverted`) — but `innerHandleOp` does not revert the
outer `handleOps`, so the unlimited allowance survives. The attacker then calls
`token.transferFrom(victim, attacker, balance)`.

(If validation returned `1`, EntryPoint would revert with `AA24` and the allowance would be rolled back —
this is why primitive A is required.)

### C. Gas-prefund drain (no paymaster)

`BaseAccount._payPrefund(missingAccountFunds)` sends `missingAccountFunds` native ETH from the account
to the EntryPoint during validation. When no paymaster is present, `missingAccountFunds` is computed from
`(callGasLimit + verificationGasLimit + preVerificationGas) * maxFeePerGas`. The attacker (as bundler)
sets `maxFeePerGas` as high as the victim's balance allows and `beneficiary = attacker`. EntryPoint pays
the beneficiary `actualGasUsed * min(maxFeePerGas, maxPriorityFeePerGas + basefee)` — i.e. the victim's
ETH is converted to gas at an **inflated declared price** and paid to the attacker, while the attacker
only pays the real (tiny) Arbitrum gas cost.

## Historical incidents (on-chain, verified)

| Incident | Tx | Block | Attacker | Amount |
|---|---|---|---|---|
| Prefund drain (anomly.rs) | `0x738995176c…5e6d7bc1` | 483,046,805 (2026-07-12) | EOA `0x7bd736631afbe1d3795a94f60574f7fa0ae89347`, contract `0xfC99FA4b30bDB2E3da90706882A24759307b0343` | 11.761122 ETH (~$21,165 @ $1,799.59) |
| Token approval (Lumi) | `0x630654fb1c…c6604` | 483,389,834 (2026-07-13) | EOA `0xCe1a3BB0b98D0D90C7Dd0620Ab86C9A771888d88`, contract `0x56362412AE17cac443AAFBAb4289946Ad958E8a1` | allowance = 2^256-1 |
| Token drain (Lumi) | `0x1cdba4c3f9…b9f0` | 483,390,113 (2026-07-13) | same | ~$270,000 |

## Why E-U / why $0 today

* The path is **permissionless** — no owner, role, whitelist, capital or signature is required.
* All 8,645 factory-created proxies still point at the unpatched impl (see census), but every account
  currently holds only dust: **E-U-conditional**, re-armed instantly by any inbound ETH or ERC-20.

## Cross-chain

`eth_getCode` for `0xb5BC46dF…` on Ethereum, Base, Optimism, Polygon and BSC returns `0x` (not deployed).
Arbitrum only.
