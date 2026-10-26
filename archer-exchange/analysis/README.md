# Archer Exchange — analysis index

| File | What |
|---|---|
| `archer_program.so` | ELF dumped from ProgramData `6iDEEhGGMoj9J2h6re66g14T3fvAKRT7tm4VXGPP9HKY` (379 304 B) |
| `SHA256SUMS` | `5c5ff975a6f24bdffa5d54a82242e937e9710680219bc4e0f6dd9a0694b0a1d5` |
| `source_paths.txt` | ELF source-map strings (`program/src/processor/maker/*.rs`, `matching_engine/swap.rs`, …) |
| `error_strings.txt` | Custom error strings (`Invalid Archer treasury`, `Owner not Archer program`, `Incorrect token account mint`, …) |
| `arch_state.json` | Raw `getProgramAccounts` for all 102 markets + 292 maker books |
| `arch_free_rank.json` | Maker books ranked by free (withdrawable) balance in USD |
| `arch_vault_bal.json` / `arch_meta.json` | Vault token accounts + mint decimals + DefiLlama prices |
| `arch_battery*_results.json` | The 17-case substitution battery (three rounds) |

## Instruction surface (1-byte tag; from `ballista-tech/archer-sdk`)

```
0  InitializeMarket      11 MakerDepositFunds     28 RegisterMaker       34 ArcherAccountWithdraw
1  ChangeMarketStatus    12 MakerWithdrawFunds    29 DeregisterMaker     35 SwapFromArcherAccount
3  UpdateMakerFee        13 ToggleBookSuspension  30 UpdateExpiryInSlots 36 UpdateBookLimit
4  UpdateTakerFee        14 CollectProtocolFee    31 CloseMakerBook      37 UpdateBookRescale
5  TransferAdmin         15 Swap                  32 InitializeArcherAccount 38 UpdateRegistry
6  InitializeMakerBook   27 InitializeMakerRegistry 33 SetArcherAccountDelegate
7  UpdateBook
8  UpdateMidPrice
9  ClearBook
10 SetBookDelegate
```

Account discriminators: `ACHRMKT1` (Market, 272 B), `ACHRMKR1` (MakerBook, 776 B).
`MarketStatus`: Active=0, Paused=1, Closed=2, Frozen=3. `MakerBookStatus`: Active=1, Suspended=2.

PDAs: `market = ["market", market_id]`, `maker_book = ["maker", market, maker]`,
`maker_registry = ["maker_registry", market]`, `archer_account = ["archer-account", owner, platform]`.

Hard-coded constants: treasury `Hfj4HDxLqdj4k9FB3eZeURf4sZtu3w9aJMRfctmXR66P`,
global authority `AuthYRbdcyksthcB1AM8ZKB3CidzChURkLzsGN8pYUmw`, `ARCHER_PROTOCOL_FEE_PPM = 200_000`.

## Error-code map used in the battery

| code | name |
|---|---|
| 200 | InvalidAccount |
| 206 | Unauthorized |
| 300 | InvalidMint |
| 303 | InvalidTokenAccount |
| 500 | InvalidMakerBook |
| 502 | UnauthorizedMaker |
| 507 | NoMatchingLiquidity |
| 526 | PostOnlyRequiresLimitOrderBook |
| 529 | InvalidMakerVault |
| 1000 | InvalidArcherAccount |
| 1002 | InvalidArcherAccountTokenAccount |
| 2003 | Anchor ConstraintRaw |
| 2006 | Anchor ConstraintSeeds |
| 2014 | Anchor ConstraintTokenMint |
| 2015 | Anchor ConstraintTokenOwner |
| 3010 | Anchor AccountNotSigner |
| 3012 | Anchor AccountNotInitialized |

(Anchor's `repr(u32)` built-in codes are used even though the program is not Anchor-framework —
the SDK mirrors them.)
