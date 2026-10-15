# ZilSwap v1.1 — token custody check (top 12 pools by ZIL reserve)

Read at ~block 38,176,500 (Z2), via `scilla_read(token, "balances", [ZilSwap, ZilSwap])` — the token's
recorded balance of the ZilSwap contract — compared with the pool's `token_reserve` in ZilSwap state.

| # | token | symbol | token_reserve (raw) | balances[ZilSwap] | match |
|---|---|---|---|---|---|
| 1 | 0x173ca6770aa56eb00511dac8e6e13b3d7f16a5a5 | XSGD | 34,487,399,314 | 34,487,974,241 | **NO (+574,927 excess)** |
| 2 | 0xa845c1034cd077bd8d32be0447239c7e4be6cb21 | gZIL (legacy) | 17,769,439,155,865,398,016 | 17,769,439,155,865,398,016 | YES |
| 3 | 0x0d21c1901a06abee40d8177f95171c8c63abdc31 | ZWAP | 134,864,185,097,460,915 | 134,864,185,097,460,915 | YES |
| 4 | 0x07da3d45b0f1390083097a95a8915fc2f6b06c6f | ZPAINT | 260,675,322,263 | 260,675,322,263 | YES |
| 5 | 0x818ca2e217e060ad17b7bd0124a483a1f66930a9 | zUSDT | 1,447,955,272 | 1,447,955,272 | YES |
| 6 | 0x75fa7d8ba6bed4a68774c758a5e43cfb6633d9d6 | (unidentified) | 2,177,024 | 2,177,024 | YES |
| 7 | 0x2ca315f4329654614d1e8321f9c252921192c5f2 | zETH (legacy) | 117,568,947,997,019,560,656 | 117,568,947,997,019,560,656 | YES |
| 8 | 0xdc77490018ee76bca67fb78b4005d42b7bcb0fa7 | (unidentified) | 23,352,492,312,413,827,400 | 23,352,492,312,413,827,400 | YES |
| 9 | 0x31bfa2054b7199f936733f9054dbce259a3c335a | (unidentified) | 183,214,724 | 183,214,724 | YES |
| 10 | 0xa3eafd5021f6b9c36fd02ed58aa1d015f2238791 | (unidentified) | 72,209,870,655,940 | 72,209,870,655,940 | YES |
| 11 | 0xbfad9ad21c5373ba8861993d0917f03be5389d4a | (unidentified) | 1,687,024,544,365 | 1,687,024,544,365 | YES |
| 12 | 0x327082dd216ff625748b13e156b9d1a5d3dd41f2 | (unidentified) | 10,891,960,183,281,108,329,177 | 10,891,960,183,281,108,329,177 | YES |

**Interpretation:** 11/12 pools are exactly backed by tokens held at the ZilSwap contract. The XSGD pool
holds 574,927 XSGD more than its reserve — an excess that ZilSwap v1.1 has **no transition to skim**
(there is no `skim`; `RemoveLiquidity` pays per reserves, not balances). ~$428 at XSGD≈$0.745 → stuck (S).

The custody check rules out the "pool credits a token it does not hold" class; the separate
`TransferFrom` scan (`transferfrom_scan_full.json`) rules out the "token silently succeeds without
balance" class.
