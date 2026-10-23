# Kipseli Base reserve — live probe evidence (read-only)

**Date:** 2026-10-23 · **Chain:** Base (8453) · **Mode:** `eth_call` / `eth_getStorageAt` only; no tx signed/sent.

## Addresses

| Role | Address | Notes |
|---|---|---|
| Reserve (target) | `0xBEE3211ab312a8D065c4FeF0247448e17A8da000` | ERC1967 proxy (2,009 bytes runtime); unverified |
| Implementation | `0x45A507EB92dDF5ab6F10e0a0d124B247e75992a8` | 16,412 bytes; unverified |
| Proxy admin (custom) | `0x8Bb03250fD720A6f2Dc043616532c92bd2D42f6E` | 1,935 bytes; `owner()` = operator EOA |
| Owner (impl `owner()`) | `0xbBaE617C0b16639896156B5bD7E33cCE492F958a` | Gnosis Safe `VERSION()=1.4.1`, threshold **2** of 3 |
| Operator (only) | `0x97F7d4093e5Bdd0776e2Ca90C90124c5e16Ca569` | EOA (code length 0); also Safe signer + proxy-admin owner |
| USDC | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` | |
| WETH | `0x4200000000000000000000000000000000000006` | |

Safe owners: `0x97F7d409…`, `0x8999c5554a983e9b9679ccfab3709830dce75a0b`, `0x8a80ee3234ff0ba250b67398b994cd6c08da9c0e` (threshold 2).

## EIP-1967 slots

- implementation slot `0x360894…2bbc` = `0x45A507EB…92a8`
- admin slot `0xb53127…6103` = `0x8Bb03250…2f6E`
- beacon slot `0xa3f0ad…3d50` = `0x0`

## Live balances (two independent reads)

| Block | USDC raw | WETH raw | USDC USD | WETH USD | Total USD |
|---|---|---|---|---|---|
| 52,975,121 (`0x3285611`) | 440,787,511,981 | 36,186,163,902,047,726,266 | 440,554.11 | 86,985.71 | **527,539.82** |
| 52,975,943 (latest @ probe) | 432,429,024,960 | 41,408,174,638,709,672,865 | 432,200.05 | 99,538.58 | **531,738.63** |

Prices (DefiLlama, 2026-10-23): USDC $0.9994704934726131 · WETH $2403.8388939539973. Native ETH = 0.

## Full dispatcher selector sweep — called from a fresh EOA (`0x…deadbeef`)

33 dispatcher selectors extracted from the impl bytecode. Result of `eth_call` with zeroed args:

| Selector | Result for unprivileged caller | Gate |
|---|---|---|
| `0x69328dec` withdraw(address,uint256,address) | REVERT `caller is not operator` | operator |
| `0xf00baf3e` convertETH(uint256) | REVERT `caller is not operator` | operator |
| `0x95ccea67` emergencyWithdraw(address,uint256) | REVERT `Ownable: caller is not the owner` | owner |
| `0x34efb1e9` setAllowance(address[],address,uint256) | REVERT `Ownable: caller is not the owner` | owner |
| `0xa07aea1c` addOperators(address[]) | REVERT `Ownable: caller is not the owner` | owner |
| `0xd365a377` removeOperators(address[]) | REVERT `Ownable: caller is not the owner` | owner |
| `0xf2fde38b` transferOwnership(address) | REVERT `Ownable: caller is not the owner` | owner |
| `0x715018a6` renounceOwnership() | REVERT `Ownable: caller is not the owner` | owner |
| `0x0eb9142f`, `0x388bb62c`, `0x61bb41a7`, `0x7dadbe8c`, `0x9f273fbc`, `0xa908183d`, `0xab06e403`, `0xaf38bf11`, `0xb9f9fc41` | REVERT `Ownable: caller is not the owner` | owner |
| `0x4cf3fe9c`, `0x8594ac40` | REVERT `Only forwarder allow` | trusted-forwarder + owner |
| `0x567aa1ba` initialize(address) | REVERT `Initializable: contract is already initialized` | — |
| Views: `0x14b7c124`, `0x1626ba7e`, `0x26142335`, `0x3fc8cef3` (weth), `0x61acbdcb`, `0x6d70f7ae` (isOperator), `0x7d6a4568`, `0x8da5cb5b` (owner), `0x9e165a78`, `0xd49d5181`, `0xd911c632` (getAllOperators), `0xe3fa62d6`, `0xecb9e11a` (numberOperators) | OK (no state change) | — |

**20 of 33 selectors are state-changing and all revert for an unprivileged caller; 13 are views.**

## Secondary gate on `withdraw`

Even the **real operator** cannot freely withdraw: `withdraw(USDC, 1, <any address>)` pranked as the operator EOA reverts `destination is not approved` for destinations {operator, owner, 0x…dead}. There is a destination allowlist that is currently empty.

## Proxy-admin upgrade

`upgradeAndCall(address,address,bytes)` on the admin contract (`0x9623609d`) reverts for an outsider with custom error `OwnableUnauthorizedAccount(address)` (`0x118cdaa7`); its `owner()` is the operator EOA.

## Verdict

No unprivileged value-moving path. Every value path requires the operator EOA, the 2-of-3 Safe owner, or the proxy-admin owner (same operator EOA). **E-U = $0 (high confidence).** The ~$527–532k is P-class (privileged custody).
