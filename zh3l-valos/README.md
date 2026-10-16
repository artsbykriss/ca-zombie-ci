# zh3l-valos — L6 live-extractability re-probe of Valos "AccountableAsyncRedeemVault" (Monad, 143)

Re-run of the Z3-H14 conclusion against **today's** chain state, with fresh fork evidence.
Read-only; public RPCs only; no keys.

- Target vault `0x8d3F9f9E…Bc365` (`permissionLevel = Whitelist(2)`, set at construction, no setter),
  strategy (UUPS proxy) `0x8dce15fc…54af` = `AccountableOpenTerm`, asset aUSD `0x00000000eFE3…012a`.
- Tests (`poc/test/L6Valos.t.sol`): V1 gate reads (permissionLevel=2, fresh not allowed, strategy pinned,
  dvnPublisher=0), V2 deposit/mint/requestRedeem/redeem/withdraw/cancel all revert `Unauthorized` for a
  fresh address, V3 strategy hooks are `onlyVault`, V4 permissionless cranks pay $0, V5 donations cannot
  inflate `totalAssets`/`sharePrice`.
- Run: `cd poc && forge test -vvv` (`eth_rpc_url` pinned in `foundry.toml`; keyless public RPC).

Result: 5/5 PASS at fork of live state. Fresh-address net: **$0 — blocked at entry (whitelist)**.

Full analysis: `../zombie-hunt-iii/work/L6-fables-valos.md`.
