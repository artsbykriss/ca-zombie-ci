# Infrared iBERA — raw analysis notes

Target: `0x9b6761bf2397Bb5a6624a856cC84A3A14Dcd3fe5` (Berachain 80094)
Date: 2026-10-22 · **READ-ONLY** (no tx signed/sent; `eth_call`/`eth_getCode`/`eth_getBalance`/`eth_getStorageAt` only)

---

## 0. What the target actually is (correction of the pass-4 lead)

The pass-4 `gap-chains.md` lead called this an *"Infrared deposit vault … unverified implementation"*.
Both halves are wrong:

| Claim in the lead | Reality (verified on-chain) |
|---|---|
| "deposits vault" | It is the **iBERA liquid-staking token** (`name()` = `"Infrared BERA"`, `symbol()` = `"iBERA"`, 18 dec). The LST *front-end* contract. |
| "unverified implementation" | Impl `0xC0654903c7d76F7FE63f9AD2F01618c3B55D9DcF` **is Etherscan-verified** (`getsourcecode` chain 80094, `status=1`, `ContractName=InfraredBERAV2_1`, `SimilarMatch=""` ⇒ *exact* match). |
| "the $19M sits in this contract" | Native balance of the token contract = **0**. The BERA backing is staked on the Berachain CL via the Depositor/Withdrawor; `deposits()`/`totalAssets()` track it. |

The implementation source is **byte-identical** to the public repo
`github.com/infrared-dao/contracts@38140b72` `src/staking/InfraredBERAV2_1.sol`
(`diff` = empty; repo HEAD 2026-05-20).

---

## 1. Source-identity proof (decisive)

`analysis/bytecode_identity.py` (see `ci-out/bytecode_identity.json` in CI) does:

1. read the Etherscan standard-JSON bundle for the impl (73 sources, solc `v0.8.26+commit.8a97fa7a`, optimizer runs 50, evmVersion cancun);
2. recompile it **with the exact compiler** and the **same settings**;
3. substitute the `BeaconRootsVerify` linker placeholder with the library address recorded in the
   verification record (`0x49b696528cf0979ed8b13c1e32a9e54f09285416`) — the on-chain metadata
   fingerprint corresponds to a build where linking happened *after* compilation, so `libraries`
   must be omitted from the compiler `settings` (this is what Etherscan's reconstructed JSON
   differs on);
4. fill the 3 constructor-set `immutable __self` slots (UUPS) with the implementation's own address
   — exactly what `address(this)` yields at deploy time;
5. require **byte-for-byte equality** with `eth_getCode(impl)`.

Result: `byte_exact_match = true`, 14 082 bytes, metadata hash `c031d2f45be36020e3cec9d2d8e46dc215d787607908dfd0c0b0dd211fe8d2bc`
identical on both sides. ⇒ **the deployed logic *is* this source.** The auth model below is therefore
not an inference from a decompile; it is read from the exact deployed code.

> Note on the pass-4 remark *"`proxiableUUID()` reverts"*: correct, and it is the OZ v5 `notDelegated`
> guard (`0xe07c8dba = UUPSUnauthorizedCallContext()`); `UPGRADE_INTERFACE_VERSION() == "5.0.0"`.

---

## 2. Live state (primary snapshot block **27 827 865**, `0x1a89e99**)

| Read | Value |
|---|---|
| `name()` / `symbol()` / `decimals()` | `Infrared BERA` / `iBERA` / 18 |
| `totalSupply()` | 79 515 424.296432355153529597 iBERA |
| `totalAssets()` == `deposits()` | 84 122 523.818056978854247603 BERA |
| implied share price | 1.057939696 BERA / iBERA |
| `asset()` | `0x000…0` (native BERA) |
| `withdrawalsEnabled()` / `paused()` | `true` / `false` |
| `burnFee()` | 0.01 iBERA (`1e16`) |
| `feeDivisorShareholders()` | `4` (25 % of EL yield to protocol) |
| `proofTimestampBuffer()` | 600 s |
| `infrared()` | `0xb71b3DaEA39012Fb0f2B14D2a9C86da9292fC126` |
| `depositor()` | `0x04CddC538ea65908106416986aDaeCeFD4CAB7D7` |
| `withdrawor()` | `0x8c0E122960dc2E97dc0059c07d6901Dce72818E1` |
| `receivor()` | `0xf6a4A6aCECd5311327AE3866624486b6179fEF97` |
| `rateProvider()` | `0x776fD57Bbeb752BDeEB200310faFAe9A155C50a0` |
| `currentImplementation()` | `0xC0654903c7d76F7FE63f9AD2F01618c3B55D9DcF` (14 082 B) |
| EIP-1967 impl slot | `0x…c0654903…` ✅ |
| EIP-1967 **admin** slot | `0x00…00` ⇒ **no ProxyAdmin**, pure UUPS |
| EIP-1967 beacon slot | `0x00…00` |
| native balance of the token contract | **0 wei** |
| proxy's own iBERA balance (accrued exit fees) | 63.50983597134332 iBERA |

Balances elsewhere (block 27 828 198): Depositor 5 203.510681436065834288 BERA,
Withdrawor 0.986762306 BERA (`reserves()`), Receivor 0.066886552347151180 BERA
(`distribution()` = 0.006943675010847447; `shareholderFees` = 0.042026290476175885),
Infrared core 0.0099 BERA. Withdrawor `requestLength` 5140, `requestsFinalisedUntil` 5138,
`totalClaimable` 0, `pendingWithdrawalsLength` 4, `minActivationBalance` 250 000 BERA.

**Price / USD** (DefiLlama `coins.llama.fi`, timestamp 1792670220): BERA **$0.16880983**.
TVL = 84 122 523.818 BERA = **$14 200 709.25**. (DefiLlama `infrared-finance` reports ≈$19.0M at
BERA ≈$0.226; the on-chain figure is the authoritative one.)

---

## 3. Role holders (from `RoleGranted`/`RoleRevoked` logs + live `hasRole`)

topic0 `RoleGranted = 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d`
topic0 `RoleRevoked = 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b`

| Role | Holder | Live? | Kind |
|---|---|---|---|
| `DEFAULT_ADMIN_ROLE` (`0x00…00`) | `0x182a31A27A0D39d735b31e80534CFE1fCd92c38f` | yes | **Gnosis Safe v1.3.0, 3-of-6** |
| `GOVERNANCE_ROLE` `0x71840dc4…` | `0x182a31A27A0D39d735b31e80534CFE1fCd92c38f` | yes | same Safe |
| `KEEPER_ROLE` `0xfc8737ab…` | `0x242D55c9404E0Ed1fD37dB1f00D60437820fe4f0` | yes | 171-byte contract (Safe-style proxy) |
| `KEEPER_ROLE` | `0x0C224f0F468675aD6299f7A93D23a829964a2369` | yes | EOA |
| `KEEPER_ROLE` | `0x3e08c3728a69ab3804af74f55f500ceedb342ac7` | **revoked** @ block 20 186 293 | — |
| `PAUSER_ROLE` `0x65d7a28e…` | *nobody* | — | `pause()` therefore needs `GOVERNANCE_ROLE` |

Safe owners (from `getOwners()`): `0x438bffBD…`, `0xe5A0Fab1…`, `0xa0AFda6b…`, `0xF3E3f0Dd…`,
`0xb56D8669…`, `0xd35E2E0A…`; `getThreshold()` = **3**; `VERSION()` = `1.3.0`.

---

## 4. Every externally reachable function on the impl, and its gate

70 functions in the verified ABI. Grouped by *who can make it do anything*:

**Permissionless (callable by a fresh address)**
| fn | what it does | can it pay the caller? |
|---|---|---|
| ERC20 `transfer/approve/transferFrom/allowance/balanceOf` | standard | no — self-scoped (spends your own tokens / your own allowances) |
| `mint(address) payable` (6a627842) | `compound()` then `_deposit(msg.value)` then `shares = ts*amount/d` to `receiver` | **no** — every share is paid for with `msg.value`; shares are floored and ≤ the pre-existing rate |
| `burn(address,uint256)` (9dc29fac) | `_burn(msg.sender, shares-fee)` then `withdrawor.queue(receiver, amount)` | no — burns the **caller's own** iBERA; `receiver` may not be the depositor |
| `compound()` (f69e2046) | `receivor.distribution()`; if >0 `receivor.sweep()` | no — increases `deposits` pro-rata to **all** holders, mints nothing |
| `renounceRole(role, self)` | OZ: `account == msg.sender` only | no-op for a role you don't hold |
| views | — | — |

**Governance-gated (`onlyGovernor` = `GOVERNANCE_ROLE`)**
`setWithdrawalsEnabled`, `updateBurnFee`, `updateRateProvider`, `setFeeDivisorShareholders`,
`updateProofTimestampBuffer`, `setDepositSignature`, `claimExitFees`, `unpause`,
`_authorizeUpgrade` (→ `upgradeToAndCall`).

**Keeper-gated (`onlyKeeper`)**: `registerViaProofs`.

**Fixed-caller-gated**: `collect()` (`msg.sender == infrared`), `sweep()` (`msg.sender == receivor`),
`register()` (`msg.sender ∈ {depositor, withdrawor}`).

**Pauser/Governor**: `pause()` (`PAUSER_ROLE || GOVERNANCE_ROLE`).

**Absent**: there is **no** `initialize()` / `initializeV2()` / `owner()` on this revision, and **no**
`fafe94a8` function (a spurious selector in the pass-4 lead — the verified ABI has no such entry and
the proxy reverts with empty data on it).

### On-chain proof of the gate (fresh caller `0x…DeaDBeef`, eth_call, block 27 827 880)

| selector | revert data | decoded |
|---|---|---|
| `setWithdrawalsEnabled/updateBurnFee/updateRateProvider/setFeeDivisorShareholders/updateProofTimestampBuffer/setDepositSignature/claimExitFees/unpause` | `0xe2517d3f` ++ `…deadbeef` ++ `71840dc4…` | `AccessControlUnauthorizedAccount(fresh, GOVERNANCE_ROLE)` |
| `grantRole(ANY_ROLE, fresh)` / `revokeRole(GOV, gov)` | `0xe2517d3f` ++ `…deadbeef` ++ role | `AccessControlUnauthorizedAccount(fresh, roleAdmin)` |
| `upgradeToAndCall(fresh,"")` | `0xe2517d3f` ++ `…deadbeef` ++ `71840dc4…` | `AccessControlUnauthorizedAccount(fresh, GOVERNANCE_ROLE)` |
| `pause()` | `0x492f6781` | `NotPauser()` |
| `collect()` / `sweep()` / `register(…)` | `0x8e4a23d6` ++ `…deadbeef` | `Unauthorized(fresh)` |
| `mint(fresh)` with 0 value | `0x6edcc523` | `InvalidShares()` (0 shares ⇒ cannot mint for free) |
| `burn(fresh, 1e18)` | `0xe450d38c` ++ `(fresh, 0, 0.99e18)` | `ERC20InsufficientBalance` ⇒ burns the **caller's** balance |
| `burn(fresh, 1e16)` | `0x6edcc523` | `InvalidShares()` (`netShares == 0`) |
| `transferFrom(proxy\|keeper, fresh, 1e18)` | `0xfb8f41b2` | `ERC20InsufficientAllowance` |
| `initialize()` / `initialize(address,address)` / `fafe94a8` | empty | selector does not exist |
| `proxiableUUID()` | `0xe07c8dba` | `UUPSUnauthorizedCallContext()` (OZ v5 `notDelegated`) |

Selector decoding: `AccessControlUnauthorizedAccount(address,bytes32)`=`0xe2517d3f`,
`Unauthorized(address)`=`0x8e4a23d6`, `NotPauser()`=`0x492f6781`, `InvalidShares()`=`0x6edcc523`,
`ERC20InsufficientBalance(address,uint256,uint256)`=`0xe450d38c`,
`ERC20InsufficientAllowance(address,uint256,uint256)`=`0xfb8f41b2`.

---

## 5. Why the LST accounting cannot be gamed by an unprivileged actor

* `deposits` is only ever increased by `_deposit()` — reachable from `mint{value:}` (caller's own
  BERA) and `sweep{value:}` (`msg.sender == receivor`), and by `register`/`process` rebalances
  (`depositor`/`withdrawor` only). **A plain BERA transfer to the token contract cannot inflate
  `deposits`** — the contract has no `receive()`/`fallback`, so unsolicited BERA reverts.
* `mint()` calls `compound()` **before** reading `d = deposits`, so a minter can never buy shares at
  the pre-yield price. Yield that lands in the Receivor is always recognised first.
* `shares = (ts * amount) / d` floors; `amount = (deposits * netShares) / ts` floors. Both round in
  the protocol's favour. A round-trip `mint`→`burn` is strictly loss-making (plus the 0.01 iBERA
  burn fee).
* `burn()` has no re-entrancy hole: the only external call (`withdrawor.queue`) does not call back
  into iBERA, and `_burn` happens before it.
* The `previewBurn` `msg.sender == rateProvider ⇒ fee = 0` special case is **preview-only** —
  `burn()` itself always charges `burnFee`. (Cosmetic inconsistency, not exploitable.)

---

## 6. Residual / latent risk (not extractable today)

1. **`InfraredBERAFeeReceivor.sweep()` has no auth check** (verified source, identical to deployed).
   Anyone can push the receivor's BERA into `deposits`. It pays the caller **nothing** (shares go to
   `infrared` via `collect()`, which *is* gated) and only accelerates pro-rata yield compounding.
   At most a gas-griefing/ordering nuisance. Same for the permissionless `compound()`.
2. **`mint()` is not `whenNotPaused`** — deposits keep working while the system is paused. No value
   loss (the BERA is escrowed in the Depositor and forwarded by keepers), but a hardening item.
3. **Governance is a 3-of-6 Safe** holding both `DEFAULT_ADMIN_ROLE` and `GOVERNANCE_ROLE`, and it
   controls `upgradeToAndCall`. That is the whole trust assumption: the $14.2M is **P**-class, not
   attacker-reachable.
4. `redeemIbgtForBera`/`claimProtocolFees`/`recoverERC20*` on the *core* `InfraredV2`
   (`0xb71b3DaE…` → `0xd9ce49e4…`) were re-probed from a fresh address: `onlyKeeper`
   (`AccessControlUnauthorizedAccount(fresh, KEEPER_ROLE)`), `Unauthorized(fresh)` or
   `onlyGovernor`. The core holds only 0.0099 BERA.

---

## 7. Files

| file | content |
|---|---|
| `analysis/probe.py` | live-state snapshot (views, storage slots, balances, code sizes) |
| `analysis/probe_selectors.py` | per-selector unprivileged eth_call probe with revert data |
| `analysis/bytecode_identity.py` | byte-exact source↔bytecode proof |
| `analysis/find_metadata_variant.py` | how the metadata fingerprint was reproduced |
| `analysis/materialize_verified.py` | Etherscan standard-JSON → Foundry project |
| `analysis/live_state_raw.json` | raw probe output |
| `analysis/selector_probe_raw.json` | raw selector probe output |
| `analysis/rolegranted.json`, `analysis/rolerevoked.json` | raw `getLogs` |
| `analysis/verified/*.json` | raw `getsourcecode` records (impl, proxies, core, withdrawor, receivor, depositor) |
| `analysis/verified/src/**` | extracted verified sources |
| `analysis/notes.md` | this file |
