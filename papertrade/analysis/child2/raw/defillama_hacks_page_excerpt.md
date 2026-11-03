# DefiLlama hacks DB — Papertrade row (fetched 2026-10-16)

## API: https://api.llama.fi/hacks  (whole DB: 1,303 rows)
Exact row (verbatim JSON):
```json
{
 "date": 1791590400,
 "name": "Papertrade",
 "classification": "Oracle Manipulation",
 "technique": "Spot Price Manipulation",
 "amount": 1280000,
 "chain": ["Hyperliquid L1"],
 "bridgeHack": false,
 "targetType": "DeFi Protocol",
 "source": "",
 "returnedFunds": null,
 "defillamaId": "9065",
 "language": "Solidity"
}
```
- `1791590400` = Sat Oct 10 2026 00:00:00 UTC
- amount $1,280,000
- `source`: EMPTY STRING — no reference URL in the API record.

## Hacks page: https://defillama.com/hacks (JS-rendered; fetched 2026-10-16)
Row as displayed in the table:
> | Papertrade | Oct 10, 2026 | $1.28m | Hyperliquid L1 | Oracle Manipulation | Spot Price Manipulation | Solidity |

Page context (same page): "Total Value Hacked (USD) $21.068b", "Total Value Hacked in DeFi (USD) $9.278b", "Total Value Hacked in Bridges (USD) $3.69b". No links/references shown for the Papertrade row.

Local copy of full JSON row: ./defillama_hacks_papertrade_row.json
