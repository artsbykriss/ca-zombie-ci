# Hylo router — analysis index

| File | What |
|---|---|
| `hylo_router_program.so` | ELF dumped from the ProgramData account `GCsBXReXttZUUfG1JVxiXMvWPHbWikS3FVdZPy1hjXjM` (240 376 B) |
| `SHA256SUMS` | `25f88987c8223775fd4e0fd8e7a2a3bf85503f7b5b3112fe801d30cfac80d415` |
| `source_paths.txt` | ELF source-map strings (`programs/hylo-router/src/lib.rs`, `src/util.rs`) — confirms the program's crate path |
| `live_state.md` | Decoded `Hylo` PDA, router PDAs, measured custody |
| `hylo_tvl.json` | Per-vault balances/price (slot 461 381 199) |
| `hylo_router_results.json` | Control + 12 substitutions (slot 461 384 770) |
| `hylo_router_results2.json` | Earlier battery (superseded) |

## The proxy design (upstream, verbatim from `github.com/hylo-so/sdk`)

`hylo-idl/src/instruction_builders/router.rs`:

```rust
/// Routes through the proxy program, forwarding the given accounts
/// to the target program via CPI. Exo pairs resolve from the pair table
/// compiled into the router.
pub fn route<A: ToAccountMetas>(args: &args::Route, inner_accounts: &A) -> Instruction {
  Instruction {
    program_id: router::ID,
    accounts: inner_accounts.to_account_metas(None),   // <- the target program's accounts
    data: args.data(),
  }
}
```

`hylo-clients/src/router_client/instructions.rs` builds every user operation as
`route_instruction(...)` → `route_v2(&args, inner_accounts)` where `inner_accounts` is exactly the
exchange instruction's account struct from `hylo-idl/src/account_builders/exchange.rs`.

`hylo-idl/src/pda.rs` — every PDA used by the exchange instructions is derived under `exchange::ID`
(`pda!(exchange::ID, …)`); the only `router::ID` PDAs are `EXO_REGISTRY` and `ROUTER_EVENT_AUTHORITY`.

## Discriminators

| instruction | sha256("global:<name>")[:8] |
|---|---|
| `route` | `e517cb977ae3ad2a` ← the live instruction |
| `route_v2` | `bb64facc31c4af14` |

## Live route CPI replayed as the control

tx `5nSxg7ucq5YzAdYwujCt5AssYMqiWmWrLPxQwPoks4pzi9ivj972CuZuz36y5KMC6WjFnxT6rmzm1URLQjEdcgfY`

```
hyRouTR… invoke [1]  → "Instruction: Route"
  HYEXCHtH… invoke [2] → "Instruction: ConvertStableToLeverExo"
    Tokenkeg… transfer
```
args: `token_a = 5YMkXAYcc… (hyUSD)`, `token_b = 7ga6rtE9… (xHYPE levercoin)`, `amount = 789366268`.
The router's 18 accounts are byte-identical to the exchange `ConvertStableToLeverExo` layout.

Route resolution cross-checked by re-deriving the exchange PDAs:

```
exo_levercoin_mint(HYPE=98sMhvDw…) = 7ga6rtE9qSb3wdEiDCpTu2kHqoGVfT52jD8ign1rYTvx  == args.token_b
exo_pair(HYPE)                     = 42GzNWvZ1H1hwXaBZ8mbeVZaSEgh6zMm8BABdS3v1BEB  == forwarded account #2
```

so `route(hyUSD, xHYPE)` resolves to `convert_stable_to_lever_exo` on the HYPE pair, and the
forwarded account list is the exchange's own layout — the router performs no transformation.
