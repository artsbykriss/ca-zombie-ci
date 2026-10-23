# Evidence log — Rabby Swap legacy router (read-only)

All reads are `eth_call`/`eth_getLogs` at the stated block. No transaction was signed or sent.

## 1. Address list source

- Registry: `https://raw.githubusercontent.com/RevokeCash/approval-exploit-list/main/exploits/rabby.json`
  (repo `RevokeCash/approval-exploit-list`, the data source behind https://revoke.cash/exploits/rabby).
- 19 `{chainId, address}` entries — see `analysis/addresses.json`.
- Corroborating lists (2022): Beosin alert and 零时科技/learnblockchain post-mortem (ETH `0x6eb211…`,
  BSC `0xf756a7…`, Polygon `0xf23b0f…`, Avalanche `0x509f49…`, Fantom `0x342265…`, Arbitrum `0xf401c6…`).
  Etherscan examples named in the pass-2 lane (`0x275aD613…`, `0x328fD59A…`, `0x3422656f…`) match the
  HECO (`128`), Boba (`288`) and Fantom (`250`) entries of the registry.

## 2. Deployed code is the 2022 bytecode — never patched

| Chain | Router | code@2022 block 15,724,451 | code@latest |
|---|---|---|---|
| Ethereum | `0x6eb211CAF6d304A76efE37D9AbDFAdDC2d4363d1` | 10,402 bytes, keccak `0xc721ffeb1e240f323bf491ac19ef3a6d5797d3e606fe1df8e7a0ee05453e3895` | 10,402 bytes, keccak `0xc721ffeb…3895` (identical) |

- Runtime code size 10,402 bytes; `eth_getCode` non-empty on Ethereum at block 26,253,934.
- `eth_getTransactionCount(router)` = **1** (deployment only — no direct calls ever sent to it).
- Unverified on Etherscan (no source, no ABI).

## 3. Live router getters (Ethereum, block 26,253,934)

| Getter | Value |
|---|---|
| `paused()` (`0x5c975abb`) | `false` — **not paused** |
| `owner()` (`0x8da5cb5b`) | `0x2Cc26F59379832fDe97a6c35Abcd80D672846194` |
| `feeRatio()` (`0x41744dd4`) | `875` (8.75%) |
| native balance | `0` |

## 4. Bytecode dispatch (from `analysis/code/eth_router.asm`)

- `PUSH4 0x32854cc2` at pc `0x7c` → jump target `0x00fe` = the `swap` entry point.
- `0x32854cc2` = `swap(address,uint256,address,uint256,address,address,bytes,uint256)` (4byte + DeFiHackLabs interface).
- Other selectors: `0x19f4ff2f setFeeRatio(uint256)`, `0x41744dd4 feeRatio()`, `0x5c975abb paused()`.
- Inline arbitrary call: at pc `0x02f5..0x0302` the contract builds `(success, ret) = target.CALL{gas}(value, data)`
  with **target and data both taken from calldata** (the OpenZeppelin `Address.functionCallWithValue` helper,
  inlined). No allow-list / selector check is performed.

## 5. Fork PoC (`poc/`)

- `test_live_router_state`: code present, selector present, `paused()==false`, owner/feeRatio read.
- `test_fresh_caller_drains_standing_allowance`: fresh caller `0x1111…1111` moves a third party's
  USDC by calling `swap(USDT, 0, fake, 4660, USDC, USDC, transferFrom(victim,attacker,amt), now)` —
  gas **123,328**.
- `test_no_allowance_cannot_drain`: same call reverts with no standing allowance (negative control).
- `test_historical_replay_2022`: fork at block 15,724,451; 6 of the 29 known victims drain
  **5,204.918440 USDC** through the deployed bytecode (proves the mechanism on the real contract).
- `test_router_holds_no_tokens`: router holds 0 USDC/USDT/ETH → nothing "stuck" in it.

## 6. Census (see `analysis/raw/` and `ci-out/`)

Method: for each chain, `eth_getLogs(Approval, topic1=any, topic2=router)`, dedupe to the latest
approval per `(token, owner)`, then read **current** `allowance(owner, router)` and `balanceOf(owner)`.
Extractable = `min(allowance, balance)`. A separate pass checks ERC-721/1155 `ApprovalForAll(operator=router)`.

Results (latest blocks in `ci-out/census_summary.json`): Ethereum **0** live positions / 498 candidate
`(token,owner)` pairs; BNB Chain **1** live position (`10 WEAR` = `0x9d39ef3b…`, no DEX pair, no price →
$0). Full 19-chain table in the README.
