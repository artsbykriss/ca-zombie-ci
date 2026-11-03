# Evidence index — Wanchain Cardano TreasuryCheck

All reads are read-only against public APIs. Tip at time of capture: **Cardano block 14,152,985** (2026-11-03).

## Fixtures

| File | What it is |
|---|---|
| `script_info_all.json` | Koios `script_info` for treasury `1cfb41dc…`, replacement `8c02…`, exploited `485aa1…` |
| `other_check_scripts.json` | The four other superseded check scripts (`cfd786f4…`, `8d4c43c5…`, `41b2a43a…`, `4efc0be6…`) |
| `treasury_utxos.json` | 306 treasury UTxOs with assets (address `addr1xyw0ksw…`) |
| `treasury_totals.json` | Aggregated treasury balance: 218,156.077399 ADA, 11,837,345.212388 NIGHT, 30 CNTs |
| `treasury_recent_txs.json` | 34 treasury txs, blocks 14,044,163 → 14,048,512 |
| `groupinfo_utxos.json` | Current GroupInfo UTxO `2211c2a0…#0`, inline datum (19 params) |
| `groupinfo_tx.json` | Creation tx of the current GroupInfo (block 14,044,468) |
| `attack_tx_full.json` | Exploit tx `0a4861be…2ea1` with full redeemers, scripts, reference inputs |
| `last_treasury_tx.json` | Latest treasury spend `64a9859d…dc87` (block 14,048,512), V3 redeemer |
| `tcheck_holders.json`, `tcheck_info.json` | TCheckCoin supply 63 / 6 script holders |
| `TreasuryCheck_485a.hs`, `Types_485a.hs` | Recovered V2 Haskell source (DarkNavy artifact) — `treasurySpendCheck`, `packInteger`, `getGroupInfo` |
| `Treasury_1cfb.hs` | Recovered treasury value-validator source — only check is `valueOf totalInputValue checkTokenSymbol checkTokenName == 1` |
| `sdk_contracts.js`, `sdk_msg_contract.js`, `sdk_contracts_mgr.js` | `fridayback/contracts-sdk` (pre-exploit, last commit 2026-05-28): legacy `caculateRedeemDataHash` raw concat + `GroupNFT` param layout (GPK=2, TreasuryCheckVH=4) |
| `485aa1…uplc`, `8c02…uplc`, `1cfb41dc…uplc` | Local `uplc dump` output (the V2 dump was also produced in CI) |
| `bech32.py`, `addrgen.py` | Address decoding/encoding used to derive the script addresses |
| `pd.py` | Plutus `Data` → canonical CBOR encoder used by the PoC |
| `verify_msg.py` | Standalone ECDSA verification of the exploit redeemer |

## Key on-chain constants

- Treasury value validator: `1cfb41dc0b8d13fe53600e17059dcbcda2d8647347ec25288b4f5234` (PlutusV2, 1,343 B)
- Exploited check script: `485aa10343f63bcc2a43f1625dc841093488e4685ba607cc187ba495` (PlutusV2, 15,989 B)
- Replacement check script: `8c027908260ebc29410ce4fffe788da510e4d7fd67f4b39d3c77db5e` (PlutusV3, 6,501 B)
- TCheckCoin policy: `526d246045bf4a66ae86fd7a9985a91ef3752113f9daa9060bb54be6` (PlutusV2, 3,862 B)
- GroupInfo NFT policy: `1ddf09a9ffeca57a7ba08e1d92e1cff6ae3f6940ce8b5e7c9f9aa541`
- Admin NFT policy: `53cc8f42ca118ffa3fe0f66cf82d973b73913e0ff25edb2e5e1371af`
- Treasury stake script: `259b187aa287258c0b95e636a472391282dedb2eb17b8bf321bb14f1`
- Treasury address: `addr1xyw0kswupwx38ljnvq8pwpvae0x69krywdr7cffg3d84ydp9nvv84g58ykxqh90xx6j8ywgjst0dkt430w9lxgdmzncsw5rzpd`

## Reproduce

```bash
python3 poc/live_state.py      # treasury + GroupInfo + TCheckCoin + prices
python3 poc/poc_encoding.py    # collision + real ECDSA verification
python3 poc/scan_scripts.py    # UPLC disassembly + builtin inventory (heavy; CI)
```

## Notes / limits

- The V3 digest for the 2026-10-10 withdrawals was not reproduced byte-for-byte; the verdict uses the builtin inventory (no `AppendByteString`), the parameter block (NFT policies + treasury hash) and the verified V2 signature.
- The V2 Haskell source is a recovered candidate; it matches the deployed bytecode's trace/builtin inventory and its digest verifies the real on-chain exploit signature, so the match is high-confidence.
