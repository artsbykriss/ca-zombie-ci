# Analysis artifacts — Geist Finance (Fantom)

All reads are read-only against public Fantom RPC (`https://rpcapi.fantom.network`, keyless).
No keys or keyed URLs are stored in this folder.

| File | What it is |
|---|---|
| `read_state.py` | Reads the 9 reserves (config, indexes, aToken/debt addresses), pool/provider/oracle roles, cash, oracle prices. Output: `live-state.json` |
| `live-state.json` | Raw reserve state at block ~123,677,183 |
| `scan_borrowers.py` | Enumerates every address that ever received a debt token (Transfer logs over [17.5M, 65,236,380] — the last `Borrow` event is block 65,236,379, 2023-07-06), checks live debt balances via Multicall3, then reads `getUserAccountData` (health factor) for each live debtor. Writes `ci-out/borrowers.json` + `ci-out/borrowers.txt` |
| `scan_prefix.py` | Optional merge-scan for the early window (kept for completeness) |
| `screen_full.py` | Full liquidation screen over all 881 HF<1-with-collateral borrowers; output `ci-out/liq_screen.json` |
| `screen_liq.py` | Earlier screening pass on the recent-borrower probe |
| `locked_split.py` | Splits each aToken's supply into HF<1 (locked) / HF>=1 / other holders and reports cash coverage |
| `liq_matrix.py` | Liquidation profitability matrix: frozen oracle price vs live local DEX price for every (debt, collateral) pair |
| `summarize_borrowers.py` | HF distribution + debt totals from `ci-out/borrowers.json` |
| `code-admin-0xC03253FF.hex` | Bytecode of the pool-admin contract (Gnosis Safe proxy) |
| `code-0x4CF8.hex` | Bytecode of the address that Phase-1 triage called "registry" (it is the `LendingPoolAddressesProviderRegistry`, not the provider) |
| `child-research-multichain.md` | Web research on the Multichain collapse and the Fantom bridged assets |

Key constants (see README for the full table):

* Pool `0x9FAD24f572045c7869117160A571B2e50b10d068` (impl `0x3104ad2aadb6fe9df166948a5e3a547004862f90`)
* Provider `0x6c793c628Fe2b480c5e6FB7957dDa4b9291F9c9b`; Oracle `0xC466e3FeE82C6bdc2E17f2eaF2c6F1E91AD10FD3`
* Configurator `0xb7C10e5089d3fd281F51998543510675A52B6aa8`; CollateralManager `0x0713b9c9872442954ea50a862376ed3a93f66b08`
* Pool admin (3-of-5 Gnosis Safe) `0xC03253FFc57bC863c6F593bDCe394B533DF6a182`; owner/timelock `0x7FB9a7cBc6689C1C79e37BF8f852adA44b10EfFC`
* Staking `0x49c93a95dbcc9A6A4D8f77E59c038ce5020e82f8`; MasterChef `0xE40b7FA6F5F7FB0Dc7d56f433814227AAaE020B5`;
  ChefIncentivesController `0x297FddC5c33Ef988dd03bd13e162aE084ea1fE57`; GEIST `0xd8321AA83Fb0a4ECd6348D4577431310A6E0814d`
* Treasuries: `0x49c93a95…` (DAI/ETH/CRV/MIM/LINK), `0x0F595677AfC5F4A99Cfa1dDB4a00B8f54Cfda506` (WFTM), `0xfB6485AE36b3027eF109f271aD4C3ECFD651cF30` (BTC/fUSDT/USDC)
