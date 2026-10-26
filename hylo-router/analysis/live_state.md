# Hylo — live state read (read-only, 2026-10-25)

Programs
- exchange `HYEXCHtHkBagdStcJCp3xbbb9B7sdMdWXFNj6mdsG4hn` (upgrade auth `GzyhwK4y7EKPEevAMc2TEpgi1Y3znwj14FUzkHmCMiNP`)
- router   `hyRouTRDAgn65xyyJ3L5c4k5SFmSdr3NxDV8Euzjy3f` (upgrade auth `GzyhwK4y7EKPEevAMc2TEpgi1Y3znwj14FUzkHmCMiNP`; deployed slot 439863765)
- earn pool `HysTabVUfmQBFcmzu1ctRd1Y1fxd66RBpboy1bmtDSQQ`

`Hylo` PDA `9cd2sAfbBvKs4SX9YKo4dcjwP3TgTVQ8dT5koshGcDND` (decoded, discriminator 72a1a9d2ccaf95ae)
- admin            12DAP8y5XemtK1pJFNMVVnQugt3PUAbZZr9SmyVvy4Ce
- treasury         mAQQ9BphDL82kcA5unrA5PJ6ekYh5PxKVh7UBwtgVyV
- lst_registry     9Mb2Mt76AN7eNY3BBA4LgfTicARXhcEEokTBfsN47noK
- stablecoin_mint  5YMkXAYccHSGnHn9nob9xEvv6Pvka9DZWH7nTbotTu9E   (hyUSD)
- levercoin_mint   4sWNB8zGWHkh6UnmwiEtzNxL4XrN7uK9tosbESbJFfVs   (xSOL)
- pause_authority  H6qRPNvLnuQSZHAWzKDwv2bokBBupC99aJMV4u5FpCC5
- protocol_paused  false ; lst_pair_paused false
- oracle_interval_secs 10 ; sol_usd_oracle 7AviUf9nL62mcxNbQGKm4nKDQnPjswo6c5MX4D57HmyE

Router PDAs
- EXO_REGISTRY  F7BfTbic9AyaNKT7e4eoSbgZC7yxJvutA6S4VzosASg9   -> DOES NOT EXIST (never initialised)
- EVENT_AUTH    DsRFnNGgyQCpSH7dDHi6ZC2YnYGnG1J2cEPSyeomDwyj   -> DOES NOT EXIST
- token accounts owned by router program / either router PDA: 0

Live custody measured (keyless reads, slot 461381199, DefiLlama prices)
| account | amount | USD |
|---|---|---|
| lst_vault(JITOSOL)   | 227,143.5921 jitoSOL | $30,195,423.76 |
| hyUSD earn-pool ATA  | 20,595,974.6470 hyUSD | $20,556,389.87 |
| exo_vault(CBBTC)     | 41.7589 cbBTC | $3,361,870.68 |
| lst_vault(HYLOSOL)   | 21,708.1133 hySOL | $2,388,710.11 |
| exo_vault(HYPE)      | 26,380.5135 HYPE | $2,035,577.12 |
| usdc_vault           | 47.1193 USDC | $47.10 |
| xsol_pool            | 0 xSOL | $0.00 |
| **total measured** | | **$58,538,018.64** |

exo_vault(ONYC/PST/WETH/ZEC) do not exist. DefiLlama `hylo-protocol` TVL is $37.6M.
None of this custody is reachable by the router program (it holds no token accounts and
signs nothing); it is reachable only through the exchange program.
