# up v3 — bytecode identity checks (read-only, keyless public RPC)

All comparisons use `eth_getCode` at `latest` on `https://robinhood-rpc.publicnode.com`, stripping the
solc metadata trailer (last-2-bytes length scheme). Compiled artifacts: `forge build`, solc 0.7.6,
optimizer 200.

| deployed | compared against | result |
|---|---|---|
| CLPool impl `0x11725976BF1F38c4aB78d1F480bc5883d70D9dc3` | `aerodrome-finance/slipstream` main `contracts/core/CLPool.sol` (compiled) | **byte-identical after metadata strip** (24226 = 24226 bytes, equal). Etherscan's "verified" source for this address is only a *SimilarMatch* (`M_320060a5…`) — the repo source is the true one. |
| CLGaugeFactory `0x6Bdf3B9A782c28D6259356d0Cb7Ae22Ab1368863` | slipstream commit `f6a694b6d9` (2024-04-30) `CLGaugeFactory.sol` (compiled) | identical except the embedded immutable `voter` address (0x000… → on-chain `0x7F749fDD…`). |
| CLGauge impl `0xb6eEC6dCeEFA7063b130211e1d5e7E15ADCfcCad` | slipstream commit `f6a694b6d9` `CLGauge.sol` (compiled) | 12580 vs 12572 bytes (~8-byte delta, dependency-level); **same 34-selector dispatch set** (missing only `depositTimestamp/minter/rewardsByEpoch`, i.e. the pre-penalty generation), same revert strings (`NA NV GK PM AI SA`, `ReentrancyGuard: reentrant call`). Unverified on-explorer; auth reviewed from that generation + fork-tested. |
| DynamicSwapFeeModule `0xa8Bdc945bE050E451C97f935d7c0D6B0087cF94c` | slipstream main `contracts/core/fees/DynamicSwapFeeModule.sol` (compiled) | identical except embedded immutable `factory` (→ up v3 factory). All setters `onlySwapFeeManager` (Safe). |
| CustomUnstakedFeeModule `0xbb7A7015fD9744dF83d688D5C71C9efE613b976d` | slipstream main `CustomUnstakedFeeModule.sol` | Etherscan-verified (exact). |
| NonfungiblePositionManager `0x07F44c47743A2f36414A82b9F558ECFCf0EEdCEf` | slipstream main `contracts/periphery/NonfungiblePositionManager.sol` | deployed-source == repo source (diff empty); deployment immutables (factory/WETH9/descriptor) differ as expected. |

Factory `0x1ac9dB4a…` is a SimilarMatch too; its on-chain getters (`voter`, `poolImplementation`,
`factoryRegistry`, fee managers/modules, `tickSpacingToFee`) were read live and match the repo ABI
(excluding `legacyCLFactory`, which upstream has and up v3 removed).
