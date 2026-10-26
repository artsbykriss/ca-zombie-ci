# wildcat/analysis — index

| File | What it is |
|---|---|
| `markets_state.json` | Live state of all **93** registered markets (89 Ethereum + 4 Plasma): asset, borrower, `totalAssets`, `totalSupply`, `isClosed`, `reserveRatioBips`, `annualInterestBips`, borrower code size. Produced by `ci/live_state.py`. |
| `src/plasma_market_9A0B.json` | Raw Etherscan-V2 `getsourcecode` response for the Rhinofi market (chainid 9745) — the **verified deployed source**. |
| `src/plasma_market_bundle/` | The verified deployed source unpacked: `src/market/*` (WildcatMarket/Base/Config/Token/Withdrawals), `src/WildcatSanctionsSentinel.sol`, `src/WildcatSanctionsEscrow.sol`, `src/libraries/*` (FeeMath, MarketState, MathUtils, LibERC20, FIFOQueue, Withdrawal…), `src/types/HooksConfig.sol`, `src/access/IHooks.sol`, `src/spherex/*`. This is the exact code that is live. |
| `src/plasma_arch.json`, `src/eth_arch.json` | ArchController sources (Plasma + Ethereum). |
| `src/hooksfactory.json`, `src/openaccess_roleprovider.json`, `src/eth_fee_recipient.json` | HooksFactory / OpenAccessRoleProvider / WildcatFeeRecipient sources. |
| `v2-protocol-src/` | Snapshot of the audited `wildcat-finance/v2-protocol` repo source (for cross-reference; CI compiles it and compares bytecode). |
| `docs/` | Project documentation snapshots (Known Issues, Core Behaviour, Scale Factor, Hooks, Access Control Hooks, Fixed-Term Hooks, Sentinel, Delinquency, Security reviews, deployments). |

No secrets or keyed RPC URLs are stored here — all endpoints used are public.
