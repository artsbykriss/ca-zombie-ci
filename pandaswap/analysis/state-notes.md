# PandaSwap — raw state evidence notes (local reads)

All reads are `eth_call` (read-only) against public BSC endpoints. No transactions.

## Block 127,518,422 — enumeration checkpoint (`all-pairs.json`, `priced.json`)
- factory `0x9ad32bf5dafe152cbe027398219611db4e8753b3`: allPairsLength = 129; feeTo = `0xe1a2cd535c4e7d9c2c187e529f9f491ccea41e07`; feeToSetter = `0x3bc3c8af8cfe3dfc9ba1a57c7c3b653e3f6d6951`; pairCodeHash = `0xb785cebe4aa62be64e9e412e79c479c58578c1c3d0ffbb4602a9217d8b289559`; runtime 10,941 bytes.
- 129 pairs enumerated; priced reserve value $83,531.70 (56/96 tokens DefiLlama-priced).
- Top pairs: ATOM/WBNB `0x37550aac…` $14,381.71; Cake/WBNB `0x835faac7…` $9,814.12; MATTER/WBNB `0xb4dc9b10…` $8,750.82; DOGE/WBNB `0xff1e8a21…` $8,051.90; XTZ/WBNB `0x3c439733…` $4,768.46; BAO/WBNB `0x8da93ddb…` $4,710.64; POLS/WBNB `0xdb8ad7e2…` $3,262.38; BSCX/WBNB `0x216ee05e…` $3,261.27; WBNB/SPARTA `0xc20bed20…` $2,597.84; WBNB/LINK `0x854ea3e7…` $2,320.49; PNDA/WBNB `0x97f6665a…` $2,244.23; ETH/PNDA `0x059fc922…` $1,420.92; WBNB/BUSD `0xacaeb685…` $1,072.77.

## Block 127,522,019 — graph / roles
- feeTo `0xe1a2cd535c4e7d9c2c187e529f9f491ccea41e07`: code 5,192 B; `factory()` = PandaSwap factory; `bar()` = `0xef88e0d265ddc8f5e725a4fda1871f9fe21b11e2`; `owner()` = `0x3bc3c8af8cfe3dfc9ba1a57c7c3b653e3f6d6951`. ⇒ BambooMaker.
- bar `0xef88e0d265ddc8f5e725a4fda1871f9fe21b11e2` (BambooBar / xBAMBOO): `sushi()` = PNDA `0x47dcc83a…`; totalSupply = 804,704,779.513705843162608376; PNDA balance = 1,553,814,826.764387660297758234 → 1.931 PNDA per xBAMBOO.
- PNDA `0x47dcc83a14ad53ed1f13d3cae8aa4115f07557c0`: owner = `0x9942cb4c6180820e6211183ab29831641f58577a`; cap = 100,000,000,000e18; totalSupply = 74,952,744,075.778591907702862261e18; manualMintLimit = 100,000e18; manualMinted = 250,000,000e18 (limit bricked: manualMinted > limit); circulatingSupply = totalSupply; lockedSupply = 67,805,983,599.071408176224680538e18; lockFromBlock = 78,253,277; lockToBlock = 773,253,277; `authorized(0x3bc3c8af8cfe3dfc9ba1a57c7c3b653e3f6d6951)` = 1; `authorized(farm/bar/maker)` = 0.
- PNDA owner `0x9942cb4c6180820e6211183ab29831641f58577a`: `eth_getCode` = 0x; `eth_getTransactionCount` = 1; `eth_getBalance` = 0. (EOA with 1 sent tx, or self-destructed contract — not resolvable without archive state.)
- MasterChef probe on `0x9942cb4c…`: all getters (bambooPerBlock, poolLength, totalAllocPoint, startBlock, devaddrN) returned no data (no code). PNDA balance at that address = 143,329.347822216972583382e18.

## Block 127,538,669 — fork PoC measurements (`poc/test/PandaSwap.t.sol`)
- skim on 8 funded pairs (ATOM/WBNB, Cake/WBNB, PNDA/WBNB, WBNB/BUSD, ETH/PNDA, PNDA/USDC, POLS/WBNB, WBNB/LINK): token0/token1 gains = 0 on every leg.
- WBNB→PNDA→WBNB round trip on PNDA/WBNB: 0.5 WBNB → 0.497428243267733453 WBNB.
- POLS/WBNB arb vs live PancakeSwap (router `0x10ed43c718714eb63d5aa57b78b54704e256024e`), net P&L by input: 0.2 → −0.036340809023239856; 0.4 → −0.121827386616610865; 0.6 → −0.237212429431393648; 0.8 → −0.372138685534863571; 1.0 → −0.520537551827660310; 1.5 → −0.928664997640437105; 2.0 → −1.368126546371477744; 3.0 → −2.293238334618743706 WBNB.
- vBTC/WBNB pair `0x2058d400…`: reserves (12,489,554; 286,672,744,339,861,479); skim gains 0; no-input swap reverts `UniswapV2: INSUFFICIENT_INPUT_AMOUNT`.
- PNDA gates: `mint` reverts `Ownable: caller is not the owner`; `manualMint`/`capUpdate` revert (no data, Authorizable).

## PancakeSwap market cross-check (block ~127,538,4xx)
- Pancake POLS/WBNB pair `0xa11265a58d9f5a2991fe8476a9afea07031ac5bf`: 667,038.919 POLS + 15.855 WBNB → 2.377e-5 WBNB/POLS — identical to PandaSwap's POLS pool (0.98689/41,493.15 = 2.378e-5). ⇒ no arb; DefiLlama POLS USD price ($0.0609) is stale vs the on-chain venue ($0.0177).
- Pancake UNFI/WBNB `0x44ea47f2…`: 15,982.17 UNFI + 1.383 WBNB. Pancake MIR/WBNB `0x70d19b51…`: 8,207.83 MIR + 0.0336 WBNB.

## Proof artifacts
- `pair_initcode.hex` — to be written by CI (`ci-out/`): the pair creation code extracted from the factory runtime; keccak == pairCodeHash.
- Local manual verification: `keccak256(factory_code[1674:10889]) == 0xb785cebe…`; `factory_code[1937:10807] == deployed pair runtime` (8,870 B); compiled (solc 0.5.16, opt 200) runtime == deployed runtime except the 53-byte metadata (verified byte-identical otherwise).
