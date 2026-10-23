# LiquidLoans — live-state capture (PulseChain, read-only)

**Block:** 27,868,978 (2026-10-23) · **RPC:** `https://<rpc>/…` (public, keyless) · **No tx signed/sent.**

## Correction to the pass-2 brief

The address in the pass-2 OPEN #7 row — `0x9159f1d2a9f51998fc9ab03fbd8f265ab14a1b3b` — is **not the CDP**.
It is the **LOAN governance token** (`LOANToken`, solc 0.6.11). The CDP core is a Liquity-v1 fork
("LiquidLoans", contracts renamed: Vault = Trove, VaultManager = TroveManager, USDL = LUSD, PLS = ETH).

## Deployed system (all verified source on PulseChain Blockscout unless noted)

| Role | Address |
|---|---|
| LOAN token (gov) | `0x9159f1D2a9f51998Fc9Ab03fbd8f265ab14A1b3B` |
| USDL stablecoin | `0x0dEEd1486bc52aA0d3E6f8849cEC5adD6598A162` |
| BorrowerOperations | `0xa09bB56B39D652988C7E7d3665aA7EC7308BbF09` |
| VaultManager | `0xD79bfb86fA06e8782b401bC0197d92563602D2Ab` |
| StabilityPool | `0x7bFD406632483ad00c6EdF655E04De91A96f84bc` |
| ActivePool | `0x3983f040916681085D7949F7ee78BfA12c5CB119` |
| DefaultPool | `0x717A736b34308d97EeFb5bd91539E0D3B9142dBE` |
| CollSurplusPool | `0x88742a6Fd16A00Fc671fff371E4CC8ff58378596` |
| GasPool | `0xdec755e596c43439d039e48bf145dfb4e45fee3d` |
| SortedVaults | `0xE1246517c3eCa1e2a198fc927296d8ff87BaBD3c` |
| PriceFeed | `0xc65Abc8B9B4B3cEE03430f6fc3d8A4760221A113` |
| PriceFeed.fetchCaller (primary "Fetch" oracle) | `0xb3E153ab13043AC0Aa933daCEbB6F26F9ed1801B` (unverified) |
| PriceFeed.secondaryOracle (UUPS proxy) | `0x6039D143299166Fb733Ef4e45d748FBDF509B0aC` → impl `0x72992fcb616fb99b150edda114210100acbd382b`; owner = Gnosis Safe `0xF796661E25ee682Fc090C9dB1BdB981b3b252999` |
| CommunityIssuance | `0x421510521a1f9B0aDba3ba9EDbc5915206220895` |
| LOANStaking | `0x853F0CD4B0083eDf7cFf5Ad9A296f02Ffb71C995` |
| LockupContractFactory | `0x5652d2B6F84BC1A3Dd5c857b423a13DF80762dD1` |

**Admin keys: none.** `owner()` = `0x0` on VaultManager, BorrowerOperations, StabilityPool, ActivePool,
DefaultPool, CollSurplusPool, PriceFeed (renounced in `setAddresses`), LOANStaking, CommunityIssuance.
Only the **secondary oracle** (a UUPS proxy) still has an owner (a Gnosis Safe) — see residual P risk.

## Balances at block 27,868,978

| Contract | Holding | USD (marks below) |
|---|---:|---:|
| ActivePool (system collateral) | 348,005,202,970.03 PLS | $1.97M |
| StabilityPool | 66,650,227,927.06 PLS + 605,042.75 USDL | $378k + $599k |
| CollSurplusPool | 7,327,483,804.37 PLS | $41.6k |
| LOANStaking | 2,614,069,234,881.94 LOAN + 50,528.77 USDL + 1,315,560,632.88 PLS | $1.081M + $50k + $7.5k |
| CommunityIssuance | 446,403,004,644.45 LOAN (future SP rewards) | $184.6k |
| GasPool | 0 | $0 |

Marks: PLS $5.6768e-6 (DefiLlama WPLS; GeckoTerminal $5.636e-6), USDL $0.98947, LOAN $4.1366e-7
(`coins.llama.fi/prices/current`, 2026-10-23).

## System health

- `getEntireSystemColl()` = 348,005,202,970.03 PLS; `getEntireSystemDebt()` = 955,590.92 USDL.
- Oracle price 5.6558e-6 → **TCR = 206%** (MCR 110%, CCR 150%). Not in Recovery Mode.
- 96 vaults; **minimum ICR = 1.516**, median 1.989, max 7.249. **Zero vaults below MCR → nothing is liquidatable.**
- Primary Fetch oracle live & fresh (value 5.6558e-6, timestamp within minutes of head).
- Secondary (PulseX V2 TWAP) live (5.5918e-6), within 1.1% of primary → `status = 0 (fetchWorking)`.
- `baseRate()` = 5.1864e15 (0.52%) → redemption fee ≈ 0.5–1.0%.

## Files

- `liquidloans-state.json` — machine-readable capture (written by CI).
- `vaults.txt` — all 96 vaults (address, debt, coll, ICR).
- `tvl-drop.md` — the $4.28M → $1.63M reconciliation.
