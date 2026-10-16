# Aero Lite — bytecode identity checks (read-only, keyless public RPC)

Compiled the Etherscan-verified multi-file bundle (== `dromos-labs/metadex-slipstream-public` main,
confirmed source-identical for CLFactory/CLPool/CLPoolNonSwapPath/SwapHookLib) with forge,
solc 0.7.6, optimizer 200, `bytecode_hash: none`; compared to `eth_getCode` on `https://rpc.mainnet.arc.io`.

| deployed | compared against | result |
|---|---|---|
| CLFactory `0xb89Df768aF2CFE637ceB352c587Fe8edAf491d03` | compiled `CLFactory.sol` | code identical except embedded immutable `poolImplementation` (0x000… → `0x0Df9fc8730eeC048e9832B31B4bFf4351158e19B`). |
| CLPool impl `0x0Df9fc8730eeC048e9832B31B4bFf4351158e19B` | compiled `CLPool.sol` | identical except linked library placeholder → `0x22557c01cf181b14b925d83008ed1d19150cd50b` (CLPoolNonSwapPath). |
| CLPoolNonSwapPath library `0x22557c01cf181b14b925d83008ed1d19150cd50b` | compiled library | identical except the library self-address constant. |

Live reads: `defaultSwapHook() = 0xaAf164008441F112e2858d9F7A2dB1B84b1E415`,
`clPoolTape() = 0x967f5352A6448e22D7361E149103350c49345Ee9`,
`voter() = 0x0`, `discountRegistry() = 0x0`, `allPoolsLength() = 35`, tickSpacings `[1,50,100,200,2000,10]`.
Registry `0xCe44907DC45D3BFa3f5f6035B0e6E8B22D780A42`: `targetFactoryToGaugeFactory(factory) = 0x0`.
