# Legacy Rabby Swap router — address & bytecode reference

Source: `RevokeCash/approval-exploit-list/exploits/rabby.json` (the registry behind https://revoke.cash/exploits/rabby).

## 19 deployments

| Chain | chainId | Router | Runtime size | Runtime keccak | paused() | owner() |
|---|---:|---|---:|---|---|---|
| Ethereum | 1 | `0x6eb211CAF6d304A76efE37D9AbDFAdDC2d4363d1` | 10,402 | `0xc721ffeb…3895` | false | `0x2Cc26F59…6194` |
| BNB Chain | 56 | `0xf756a77E74954C89351c12da24C84d3c206E5355` | 10,402 | `0xc721ffeb…3895` | false | `0x2Cc26F59…6194` |
| Polygon | 137 | `0xf23B0F5CC2e533283Ea97f7B9245242b8D65b26b` | 10,402 | `0xc721ffeb…3895` | false | `0x2Cc26F59…6194` |
| Avalanche | 43114 | `0x509f49aD29d52bfAacAC73245Ee72c59171346A8` | 10,402 | `0xc721ffeb…3895` | false | `0x2Cc26F59…6194` |
| Fantom | 250 | `0x3422656fB4BB0C6b43b4BF65Ea174D5b5EBc4A39` | 10,402 | `0xc721ffeb…3895` | false | `0x2Cc26F59…6194` |
| Optimism | 10 | `0xD1a57cb694CF4941360a937d5F5633B363204E18` | 10,402 | `0xc721ffeb…3895` | false | `0x2Cc26F59…6194` |
| Arbitrum | 42161 | `0xf401C6373A63c7A2ddF88D704650773232cea391` | 10,402 | `0xc721ffeb…3895` | false | `0x2Cc26F59…6194` |
| Gnosis | 100 | `0x5a0aB5d78C4d40E3a467a8BC52cE16Cce88c999D` | 10,402 | `0xc721ffeb…3895` | false | `0x2Cc26F59…6194` |
| Cronos | 25 | `0xa1B61f32A7C11e64df6b11d420D2BB7656F4b6AB` | 10,402 | `0xc721ffeb…3895` | false | `0x2Cc26F59…6194` |
| Aurora | 1313161554 | `0x67832c40Daf905Ea5dDe3fCa036219E861a6bb8A` | 10,402 | `0x4eab96dd…bd2f` | false | `0x2Cc26F59…6194` |
| Harmony | 1666600000 | `0x563B6C3646E587cAAd54D57b5C0E98d7E99Aeb4f` | 10,402 | `0x4eab96dd…bd2f` | false | `0x2Cc26F59…6194` |
| Metis | 1088 | `0xb490F6A28eB43709410737dbdC1Ffb4D3a5c4989` | 10,402 | `0x4eab96dd…bd2f` | false | `0x2Cc26F59…6194` |
| Moonbeam | 1284 | `0xA166A168463c44c6C973C4F8adF97031D7B25499` | 10,402 | `0x4eab96dd…bd2f` | false | `0x2Cc26F59…6194` |
| Arbitrum Nova | 42170 | `0xE02504dCBc0721e7a4861c56b842c53E28DEc84d` | 10,402 | `0x4eab96dd…bd2f` | false | `0x2Cc26F59…6194` |
| Klaytn/Kaia | 8217 | `0xFCDa4bd27E841dEc3D8A49a3187f44757C8B9EAC` | 10,402 | `0x4eab96dd…bd2f` | false | `0x2Cc26F59…6194` |
| Astar | 592 | `0x563B6C3646E587cAAd54D57b5C0E98d7E99Aeb4f` | 10,402 | `0xcce19a0c…cbf4` | false | `0x2Cc26F59…6194` |
| Boba | 288 | `0x328fD59A417463AF4b0a465794AD627d5fc90d7B` | 10,402 | `0xcce19a0c…cbf4` | false | `0x5853ed4f…eb85` |
| HECO | 128 | `0x275aD6133d7662E6feB70365c93d78363286DFcC` | — | — | — | — (no reachable RPC) |
| Celo | 42220 | `0xC9F8a7d8Cabb46135a90b9fa0CE58B75E8d15Cc5` | 10,402 | `0xcce19a0c…cbf4` | false | `0x2Cc26F59…6194` |

The three hashes differ only in the trailing 43-byte Solidity metadata; the functional code (first 10,359 bytes)
is identical. See `analysis/code/{eth,harmony,astar}_router.hex`.

## Key selectors (Ethereum runtime)

| Selector | Signature |
|---|---|
| `0x32854cc2` | `swap(address,uint256,address,uint256,address,address,bytes,uint256)` — the vulnerable entry point |
| `0x19f4ff2f` | `setFeeRatio(uint256)` |
| `0x41744dd4` | `feeRatio()` |
| `0x5c975abb` | `paused()` |

## 2022 incident

- Attacker: `0xb687550842a24D7FBC6Aad238fd7E0687eD59d55`
- Attack contract: `0x9682f31b3f572988f93c2b8382586ca26a866475`
- Example attack tx: `0x914c1ae4f03657064f0b1d5ddc6e06f39e82bce6fb2f726efdca52c092fbfc26` (block 15,724,452)
- Loss: ~$200k (114 ETH + 179 BNB), 2022-10-11; funds to Tornado Cash; Rabby reimbursed affected users.
