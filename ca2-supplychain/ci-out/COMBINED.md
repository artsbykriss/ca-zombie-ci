# ca2-supplychain — CI verification output

Generated: 2026-11-03T13:28:32Z

Read-only: no keys, no signed transactions, no state changes.

## BTCPay incident addresses

Prices: BTC $77,257.00, LTC $54.44

| chain | address | first seen | last seen | txs | received | current balance | received USD | balance USD |
|---|---|---|---|---:|---:|---:|---:|---:|
| btc | `bc1p0f7wmcnesrapznymf9ljdn04pudgmh96sqtrm9vmgqxdh666fh8qvn63r7` | 2026-10-30T13:35:33Z | 2026-11-03T13:03:48Z | 776 | 20.32362374 | 0.03746442 | $1,570,142.20 | $2,894.39 |
| ltc | `ltc1qp49tmfdueyaqrmgrx0uyx4uegyygt8yt02whee` | 2026-11-01T13:17:46Z | 2026-11-03T12:48:00Z | 218 | 4267.69930552 | 3507.18171257 | $232,333.55 | $190,930.97 |

Combined gross received at the two named addresses: **$1,802,475.75**  
Combined current balance at the two named addresses: **$193,825.36**

## Fearless Wallet reported victim transactions

Heads: Polkadot 33715603, AssetHub 22657099

Extrinsics found by hash: **10/10**  
Signer matches the reported victim account: **10/10**  
Amount decoded from the call tail: **6/10** (transfer_all calls carry no amount)

Itemized: **15,567.99 DOT** + **54,450.36 DED**

| case | block | found | signer match | amount in call |
|---|---:|---|---|---|
| case1_260.05 | 27993791 | True | True | True |
| case2_2157.42 | 28422052 | True | True | False |
| case3_490.10 | 28868238 | True | True | True |
| case4_221.70 | 20486587 | True | True | True |
| case5_1918.73 | 20562201 | True | True | False |
| case5_ded_54450.36 | 20562208 | True | True | True |
| case6_374.00 | 20562396 | True | True | True |
| case7_1150.43 | 20675491 | True | True | False |
| case8_8994.00 | 20989739 | True | True | True |
| case8_extra_1.56 | 20989744 | True | True | False |

Destination balances (current):

| account | chain | DOT | DED |
|---|---|---:|---:|
| `12rxLrVVu4mECtPQeiAXrywo7RHHNwKDi4P6Q3V5Xo71bVqc` | relay | 0.000000 |  |
| `136LEd5L2QRR9XHduhnTrp5ttTwFcR24f4iDsRdzqxaVYzVj` | asset | 0.555033 | 0.0 |
| `13sRFz7mpKMTKyZsFmHnyzG2uifESCp9F62HxYt5PR6v8EDT` | asset | 0.010000 |  |
| `142nzKir8dsPESkJ7Unk35GTjmw6x2VMbEUA4z315rAVYJFU` | asset | 0.116825 |  |
| `148fzdn5DeFW4JcrATqDuXkxcVKh8mSfN4tar3ctS7Ev5K74` | asset | 0.699104 |  |
| `14ffkf25QZ4wqjFgSvhz6tQbK4sNXfqvzdGah4FoVTkxzEPD` | relay | 0.000000 |  |
| `14m95TLZNzb5X7BF7En7vbFCApZE5G6dbpa7ajPC57eBXP6n` | asset | 0.010000 |  |
| `15V28W6hcMmYNkXqf8W9mSipK1EuUPDLFwEYuVL7aHBVW4GK` | asset | 0.428987 | 54450.3582093799 |
| `16DBDAH1xPREi63NcxpKnAfDVmdDoZMbuvi2MepPtwdtZZZK` | relay | 0.000000 |  |
| `16PbnF9XUvw6sATsBpHd2JCe6XNwgkpco5RXEMknoupiCjJs` | asset | 0.210418 |  |
| `16PkJ21BDkv63RnkHEJER9FKyUbnBQmQWjQprtmnQfGk2sJj` | relay | 0.000000 |  |
| `16V7caN9HBBq5RHmozXqVKyRQbNwNNtV779AdsquUP3fp98D` | asset | 0.010000 |  |
| `1UTyHdLnXSLWbewZCyifu26Lcc7g29xUMmrST5WaqqkrVGR` | asset | 0.999104 |  |
| `1du2ZBnyWhqUj8ov2mE6FME1DMBdF7GaehXfvDGQsa8JJw6` | relay | 4.000000 |  |
| `1dwJuADqY9rNcZA5PDdDqRMbXQhxLA49jCFy7hwW7wGsn6Z` | relay | 2.041113 |  |
| `1eHXNhMEop6pW444Q6Fe7RnBxrb2UaH8FbjzhaMX4EgGAQY` | asset | 0.433754 |  |
| `1udhVckiUreaw49zN8wmneWPZBCGtaquQz35w7RfZZ9wmRa` | relay | 1.060000 |  |

## Fearless Wallet store / switch

Current CRX manifest version: **4.2.4** (sourceCommit `8151ebd8a43dd3d6af93638c8654860cb1ba0ac5`)  
`tonscanner` / `whitelist?address` hits in current CRX: **[]**  
Remote switch file `ton` present: **False** (switch_on=False)  
3.0.5 source contains `tonscanner.org`: **True**  
`tonscanner.org` A records: **['31.129.104.153']**  
TCP 443: **[{'connected': False, 'error': 'TimeoutError: timed out', 'ip': '31.129.104.153'}]**  
Firefox AMO: HTTP 401 (Authentication credentials were not provided.)

[done] results in ci-out/
